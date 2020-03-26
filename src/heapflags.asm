[bits 32]

global _main
extern _MessageBoxA@16
section .data

paramTextDEBUG   DB  "Close it right nao b4 its 2 late m8", 0
paramTitleDEBUG  DB  "Anti-Debug info", 0
paramText   DB  "You are not using debugger, good job", 0
paramTitle  DB  "Anti-Debug info", 0

section .text

_main:

mov eax, [fs:0x30]
mov eax, [eax+0x18]
cmp dword [eax+0x44], 0 ; offset for windows 7 x86-32
jne debugged

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

