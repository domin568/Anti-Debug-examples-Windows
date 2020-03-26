[bits 32]

global _main
extern _MessageBoxA@16
extern _GetCurrentProcess@0
extern _NtQueryInformationProcess@20
section .data

paramTextDEBUG   DB  "Close it right nao b4 its 2 late m8", 0
paramTitleDEBUG  DB  "Anti-Debug info", 0
paramText   DB  "You are not using debugger, good job", 0
paramTitle  DB  "Anti-Debug info", 0

section .text

_main:

; NtQueryInformationProcess

call _GetCurrentProcess@0
mov ecx, eax

sub esp, 4
mov edx, esp
push 0
push 4
push edx
push 7
push ecx
call _NtQueryInformationProcess@20
mov ecx, [esp]
add esp, 4
cmp ecx, 0
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

