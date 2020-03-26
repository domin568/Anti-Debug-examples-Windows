[bits 32]

global _main
extern _MessageBoxA@16

section .data

paramText   DB  "You are not using debugger, good job", 0
paramTitle  DB  "Anti-Debug info", 0
paramTextDEBUG   DB  "Close it right nao b4 its 2 late m8", 0
paramTitleDEBUG  DB  "Anti-Debug info", 0, 0, 0, 0 ; %4

section .text

_main:

push ss
pop ss
pushfd
pop ecx
and ecx, 0x100
jnz debugging

push 0x40
push paramTitle
push paramText
push 0
call _MessageBoxA@16
ret

debugging:

push 0x40
push paramTitleDEBUG
push paramTextDEBUG
push 0
call _MessageBoxA@16
ret