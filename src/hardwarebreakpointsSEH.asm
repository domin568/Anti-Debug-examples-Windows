[bits 32]

global _main
extern _MessageBoxA@16
section .data

paramTextDEBUG   DB  "Close it right nao b4 its 2 late m8", 0
paramTitleDEBUG  DB  "Anti-Debug info", 0
paramText   DB  "You are not using debugger, good job", 0
paramTitle  DB  "Anti-Debug info", 0
debug DB "SeDebugPrivilege", 0

section .text

_main:

push exception_handler
push dword [fs:0]
mov [fs:0], esp

xor eax, eax
div eax
pop dword [fs:0]
add esp, 4
ret

exception_handler:
mov ecx, [esp + 0x0c] ; CONTEXT struct ?
;lea edx, [ecx + 0xb8]
;mov edi, [edx]
;add edi, 0x47
;mov [edx], edi change execution by exception

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

push 0x40
push paramTitle
push paramText
push 0
call _MessageBoxA@16

mov esp, [esp + 8]
mov eax, [fs:0]
mov eax, [eax]
mov eax, [eax]
mov [fs:0], eax
add esp, 8
ret

debugged:
push 0x40
push paramTitleDEBUG
push paramTextDEBUG
push 0
call _MessageBoxA@16

mov esp, [esp + 8]
mov eax, [fs:0]
mov eax, [eax]
mov eax, [eax]
mov [fs:0], eax
add esp, 8

ret

