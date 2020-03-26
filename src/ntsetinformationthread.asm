[bits 32]

global _main
extern _MessageBoxA@16
extern _GetCurrentThread@0
extern _NtSetInformationThread@16
section .data

paramText   DB  "You lost control over your debugger", 0
paramTitle  DB  "Anti-Debug info", 0

section .text

_main:

call _GetCurrentThread@0

push 0
push 0
push 0x11 ; hide from debugger
push eax ; 0xfffffffe is current thread
call _NtSetInformationThread@16

push 0x40
push paramTitle
push paramText
push 0
call _MessageBoxA@16
ret


