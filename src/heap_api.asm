[bits 32]

global _main
extern _HeapDestroy@4
extern _MessageBoxA@16
extern _GetLastError@0

section .data

paramTextDEBUG   DB  "You are using debugger", 0
paramTitleDEBUG  DB  "Anti-Debug info", 0
paramText        DB  "Good ! No debugger detected", 0
paramTitle       DB  "Anti-Debug info", 0, 0 ; SECOND ZERO TO MAKE IT %4

l2:
times 0xc db 0
dd 0x40000000 ; HEAP_VALIDATE_PARAMETERS_ENABLE
times 0x30 db 0
dd 0x40000000 ; HEAP_VALIDATE_PARAMETERS_ENABLE
times 0x24 db 0

section .text

_main:
xor eax, eax
push l1

push dword [fs:eax]
mov [fs:eax], esp ; setting SEH addr at l1
mov eax, [fs:0x30]

inc byte [eax+2] ; set BeingDebugged
push l2
call _HeapDestroy@4
pop dword [fs:0]
add esp, 4
jmp being_debugged

l1:
nop ; execution resumes here due to exception
mov esp, [esp+8]
mov eax, [fs:0]
mov eax, [eax]
mov eax, [eax]
mov [fs:0], eax
add esp, 8
push 0x40
push paramTitle
push paramText
push 0
call _MessageBoxA@16
ret

being_debugged:
push 0x40
push paramTitleDEBUG
push paramTextDEBUG
push 0
call _MessageBoxA@16

ret
