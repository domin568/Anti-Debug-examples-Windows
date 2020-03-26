[bits 32]

global _main
extern _MessageBoxA@16
extern _IsDebuggerPresent@0
extern _CheckRemoteDebuggerPresent@8
extern _NtQueryInformationProcess@20
extern _GetCurrentProcess@0
extern _SetLastError@4
extern _GetLastError@0
extern _RaiseException@16
extern _CloseHandle@4
section .data

paramTextDEBUG   DB  "Close it right nao b4 its 2 late m8", 0
paramTitleDEBUG  DB  "Anti-Debug info", 0
paramText   DB  "You are not using debugger, good job", 0
paramTitle  DB  "Anti-Debug info", 0

section .text

_main:

push interrupt_handler
mov eax, [fs:0]
push eax
mov [fs:0], esp

push 0xbaad
call _CloseHandle@4
add esp, 8
jmp not_debugged

interrupt_handler:
mov ecx, [esp+4] 
mov ecx ,[ecx]
mov esp, [esp+8]
mov edx, [fs:0]
mov edx, [edx]
mov edx, [edx]
mov [fs:0], edx
add esp, 8
cmp ecx, 0xc0000008
je debugged

not_debugged:

push 0x40
push paramTitle
push paramText
push 0
call _MessageBoxA@16
ret

debugged:
push 0x40
push paramTitleDEBUG
push paramTextDEBUG
push 0
call _MessageBoxA@16
ret

