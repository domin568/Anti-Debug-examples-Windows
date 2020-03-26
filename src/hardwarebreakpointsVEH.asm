[bits 32]

global _main
extern _MessageBoxA@16
extern _AddVectoredExceptionHandler@8
extern _ExitProcess@4
section .data

paramTextDEBUG   DB  "Close it right nao b4 its 2 late m8", 0
paramTitleDEBUG  DB  "Anti-Debug info", 0
paramText   DB  "You are not using debugger, good job", 0
paramTitle  DB  "Anti-Debug info", 0
debug DB "SeDebugPrivilege", 0

section .text

_main:

push exception_handler
push 0
call _AddVectoredExceptionHandler@8
xor eax, eax
div eax
jmp not_debugged

exception_handler:

mov ecx, [esp + 4] ; get ExceptionInfo argument
mov ecx, [ecx + 4] ; get ContextRecord
cmp dword [ecx+4], 0
jne debugged
cmp dword [ecx+8], 0
jne debugged
cmp dword [ecx + 12], 0
jne debugged
cmp dword [ecx + 16], 0
jne debugged
add dword [ecx+0xb8], 2 ; go after exception instruction
mov eax, 0xffffffff ; EXCEPTION_CONTINUE_EXECUTION
ret

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
push 0xbeef
call _ExitProcess@4

