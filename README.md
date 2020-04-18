## Anti debugging techniques on Windows (32 bit subsystem)

Whole content comes from my blog [Dominik Tamiołło blog](http://dominiktamiollo.pl)

## How to compile

You gonna need nasm and golink in your PATH variable available. Then you can run batch script. 

``` 
compile.bat
```

I will cover only the most crucial code that is needed to understand example. 
I made it that way in order to not paste here too much redundant code. All names of functions from API are in particular form: _func@(number of arguments * 4) because name mangling for stdcall functions.

# isDebuggerPresent ()
------

The easiest to bypass and detect is isDebuggerPresent () check. This function internally locate PEB (Process Environment Block) and checks its second variable BeingDebugged. Simple as that.  

[](img/peb.png)

```

call _isDebuggerPresent@0
cmp eax, 1
je debugged

```


If we want to implement such function by ourselves it would be something like that. 

```

mov eax, [fs:0x30] ; pointer to PEB
cmp dword [eax+2], 1
je debugged
; continue normally program
debugged:
ret

```

At fs:0x30 there is always located pointer to PEB.

<div id="checkremote"> </div>

# checkRemoteDebuggerPresent ()
------



[](img/checkremotedebuggerpresent.png)

Another simple example of using windows API. In this function we need to supply handle to process which we want to check. We can obtain it by GetCurrentProc or pass -1 (which is pseudohandle for current process).

```

call _GetCurrentProcess@0
sub esp, 4 ; variable on stack that gets return value
push esp 
push eax ; or just pass 0xffffffff instead
call _CheckRemoteDebuggerPresent@8
mov ecx, [esp]
add esp, 4 
cmp ecx, 1
je debugged

```

This function internally calls NtQueryInformationProcess to get debug port, nonzero value inditcates debugger which is going to be explained [later](#nt).

# checking for int3 instructions (are there any software breakpoints set in debugger ?)
------

When we set a breakpoint in our code what does debugger do is placing int3 at address of our choice (removing original byte and restoring it after execution). int3 generates exception and debugger intercept it. Scaning code memory for 0xcc can result in debugger detection. 

```

call $+5 
pop edi ; get adress of this instruction
add edi, 15 ; avoid 0xcc which is in mov eax, 0xcc instruction
mov ecx, 0x400 ; how many bytes compared 
mov eax, 0xcc ; what we are comparing to
repne scasb ; compare further 0x400 bytes until found or ecx == 0
je debugged 

```

# NtGlobalFlags checking
------

Let's check PEB structure again.

[](img/pebfull.png)

A lot of members are reserved and not documented. Hapilly it has been documented by third parties. At offset 0x68 we have NtGlobalFlags. So do not be discouraged when you see "Reserved" in documentation. Usually when process is handled by debugger these flags are set. 
>FLG_HEAP_ENABLE_TAIL_CHECK (0x10)  
 FLG_HEAP_ENABLE_FREE_CHECK (0x20)  
 FLG_HEAP_VALIDATE_PARAMETERS (0x40)

Combination of these gives us 0x70. These flags can enable specific advanced debugging, diagnostic, and troubleshooting features. In this example connected with heap. As we can see by default when debugger is connected to process it has additional features enabled. If process is ran normally NtGlobalFlags should be equal to 0.  
```

mov eax, [fs:0x30]
cmp dword [eax+0x68], 0x70
je debugged

```

# OpenProcess csrss.exe
------
 By this technique we do not have feedback whether someone is debugging our application explicit. Some debuggers (like OllyDbg) when ran by administrator set to debugged process specific permission "SeDebugPrivilege" (but x64dbg by default not). To check presence of this permission we can try to open critical Windows process csrss.exe because only users that are members of the administrators group with debug privilege can open this process. Csrss.exe is always running and we can get its pid by CsrGetProcessId function. If our program normally does not need this privilege to run then someone is doing something nasty with it.   
 
```

call _CsrGetProcessId@0 ; get pid of csrss.exe in system
push eax
push 0
push 0x1f0fff ;  ALL_ACCESS
call _OpenProcess@12
test eax, eax
jne admin_with_debug_priv

```

# Hide thread from debugger with NtSetInformationThread
------

Efficient technique to prevent debugging may be hide thread from debugger. When we set breakpoint somewhere in code and in the meantime debugger is detached from process then program will crash with unhandled exception. The reason for that is int3 instruction inserted by debugger in our code. Now when thread is hided and do not send notifications to debugger there is no handler to catch breakpoint exception. By setting HideThreadFromDebugger debugger is not going to get any notifications making it useless. 

[](img/ntsetinformationthread.png)

As second arguement we set constant ThreadHideFromDebugger, third and fourth can be null, we do not need to provide any additional info. -2 is pseudohandle for current thread. After this operation debugger program can become unresponsive.

[](img/hidethread.png)

```

call _GetCurrentThread@0

push 0
push 0
push 0x11 ; hide from debugger
push eax ; 0xfffffffe is current thread
call _NtSetInformationThread@16

```

<div id="nt"> </div>

# check debug port using NtQueryInformationProcess
------

[](img/ntqueryinformationprocess.png)

Following code is used internally in function checkRemoteDebuggerPresent mentioned [before](#checkremote). Function is used to retrieve various information about process like name suggests. We want to retrieve debug port for current process. We have to supply memory location for number of debug port to be returned. We can allocate it on stack like in this example. When the process is being debugged, the return value is 0xffffffff (-1).

[](img/debugport.png)

```

call _GetCurrentProcess@0
mov ecx, eax

sub esp, 4 ; allocating memory on stack for return value
mov edx, esp
push 0
push 4
push edx
push 7 ; ProcessDebugPorts
push ecx
call _NtQueryInformationProcess@20
mov ecx, [esp]
add esp, 4
cmp ecx, 0
jne debugged

```

# checks heap flags
------

First we are obtaining PEB adress, then at offset 0x18 within it there is first heap area for process. It has header with fields (ForceFlags and Flags) that are used by kernel to get to know whether process was created within a debugger. These fields offsets are 0x40 and 0x44 accordingly (quickly checking for Windows 10 also). In Windows 7 64 bit build 7601 it is as in following image.

[](img/heapflags.png)

When not started by debugger it should be equal to 0.

```

mov eax, [fs:0x30]
mov eax, [eax+0x18]
cmp dword [eax+0x44], 0 ; offset for windows 7 x86-32
jne debugged

```


# checking for presence of hardware breakpoints using SEH
------

We are registering new exception handler, then raise an exception. As mentioned [here](#sehcontext). SEH handler gets [CONTEXT](#context) struct. Dr0 to Dr7 are debug resgitsers. First four of these contain adress of hardware breakpoint (meaning we can set only 4 hardware breakpoints). This code checks for hardware breakpoints using SEH exception. 
```

push exception_handler
push dword [fs:0]
mov [fs:0], esp ; register SEH exception handler

xor eax, eax
div eax ; exception 
pop dword [fs:0]
add esp, 4
ret

exception_handler:
mov ecx, [esp + 0x0c] ; CONTEXT struct

lea esi, [ecx + 4]
mov ecx, [esi]
cmp ecx, 0
jnz debugged
add esi, 4
mov ecx, [esi]
cmp ecx, 0
jnz debugged
add esi, 4
mov ecx, [esi]
cmp ecx, 0
jnz debugged
add esi, 4
mov ecx, [esi]
cmp ecx, 0
jnz debugged

```

# checking for presence of hardware breakpoints using VEH
------

Like in previous example we are going to check hardware breakpoint. In this example we are going to raise exception but by using VEH (Vectored Exception Handling). VEH is used simultaneously with SEH but dispatched always before SEH. To add such exception handler we have to do it through API with AddVectoredExceptionHandler. Simple as that. Declaration of exception handler is as shown below. This technique can also be reproduced at 64 bit Windows due to usage of VEH at these systems (offsets to particular fields are different). SEH at 64 bit systems is not present. 

[](img/vehhandler.png)

The only argument is pointer to the structure below.

[](img/exception_handler_declaration.png)

Then we get CONTEXT and check debug registers as before and tell the OS to continue execution.

```

push exception_handler
push 0
call _AddVectoredExceptionHandler@8
xor eax, eax
div eax
jmp not_debugged

exception_handler:

mov ecx, [esp + 4] ; get pointer to exception_pointers
mov ecx, [ecx + 4] ; get ContextRecord from it
cmp dword [ecx+4], 0
jne debugged
cmp dword [ecx+8], 0
jne debugged
cmp dword [ecx + 12], 0
jne debugged
cmp dword [ecx + 16], 0
jne debugged
add dword [ecx+0xb8], 2 ; pass through exception instruction
mov eax, 0xffffffff ; EXCEPTION_CONTINUE_EXECUTION, meaning exception was well handled, execution goes on.
ret

```

# CloseHandle that raise exception only when debugging 
------

CloseHandle when supplied with wrong handle raises EXCEPTION_INVALID_HANDLE (0xC0000008) exception, but only when process is debugged. We can use this information to check whether debugged is present. First argument to exception handler is pointer to exception type.

```

push interrupt_handler
mov eax, [fs:0]
push eax
mov [fs:0], esp ; register new SEH exception handler

push 0xbaad
call _CloseHandle@4 ; try to close nonexistent handle
add esp, 8
jmp not_debugged

interrupt_handler: ; if debugger is present then 
mov ecx, [esp+4] 
mov ecx ,[ecx] ; get exception type
mov esp, [esp+8] ; cleaning
mov edx, [fs:0]
mov edx, [edx]
mov edx, [edx]
mov [fs:0], edx
add esp, 8 
cmp ecx, 0xc0000008 ; invalid handle
je debugged

```

# check whether debug message exception is handled
------

This technique does not work in x64dbg. We raise DBG_PRINT_EXCEPTION_C (ascii version) exception to send message to debugger. If it is handled then we assume that probably by debugger.

[](img/raiseexception.png)

```

mov ecx, [fs:0]
push not_debugged_exception
push ecx
mov [fs:0], esp

sub esp, 4
mov dword [esp], 0x00414141 ; AAA string
sub esp, 16 ; allocate memory for arguments to exception
mov dword [esp], 0 
mov dword [esp+4], 0 
mov dword [esp+8], 4 ; ascii version arguments as 2nd and 3rd
mov dword [esp+12], ecx

push esp
push 4
push 0
push 0x40010006 ; DBG_PRINT_EXCEPTION_C 
call _RaiseException@16
add esp, 28
jmp debugged

not_debugged_exception:
; clean up SEH and continue execution

```

# Check number of debug objects present with NtQueryObject
------

We can use NtQueryObject to enumerate objects of specific type. We provide as second argument ObjectTypeInformation (value 2). ObjectTypeInformation will only return the information of the supplied handle. Every debugger needs debug object to work, so we can count how many debug objects are in our system. We need to supply valid handle to debug object to get informations about this type of objects so we will create one by NtCreateDebugObject. This protection checks whether any binary is debugged, not this particular one, so if we debug other binary and in the same time execute binary normally with this protection then we will get information about process being debugged.

[](img/ntqueryobject.png)

[](img/ntcreatedebugobject.png)

```

section .data

memory times 0x1000 db 0

section .text

sub esp, 4 ; handle to debug object
mov ecx, esp
sub esp, 24 ; OBJECT_ATTRIBUTES
mov dword [esp], 24
mov dword [esp+4], 0
mov dword [esp+8], 0
mov dword [esp+12], 0
mov dword [esp+16], 0
mov dword [esp+20], 0
mov edx, esp

push 0
push edx
push 0x1f000f ; DEBUG_ALL_ACCESS
push ecx
call _NtCreateDebugObject@16
;add esp, 24
mov ecx, [esp+24] ; get handle to debug object
cmp eax, 0
jb error

push 0
push 0x1000
push memory
push 2 ; ObjectTypeInformation
push ecx ; Handle
call _NtQueryObject@20
mov eax, [memory+8]
add esp, 28
cmp eax, 1
jne debugging

```
