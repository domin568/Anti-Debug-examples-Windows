[bits 32]

global _main
extern _CsrGetProcessId@0
extern _OpenProcess@12
extern _MessageBoxA@16

section .data

paramTextDEBUG   DB  "You are using debugger", 0
paramTitleDEBUG  DB  "Anti-Debug info", 0
paramText        DB  "Good ! No debugger detected", 0
paramTitle       DB  "Anti-Debug info", 0, 0 ; SECOND ZERO TO MAKE IT %4

section .text

_main:
call _CsrGetProcessId@0
push eax
push 0
push 0x1f0fff ;  ALL_ACCESS
call _OpenProcess@12
test eax, eax
jne admin_with_debug_priv

push 0x40
push paramTitle
push paramText
push 0
call _MessageBoxA@16
ret

admin_with_debug_priv:

push 0x40
push paramTitleDEBUG
push paramTextDEBUG
push 0
call _MessageBoxA@16
ret
