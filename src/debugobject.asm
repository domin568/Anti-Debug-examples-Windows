[bits 32]

global _main
extern _MessageBoxA@16
extern _NtCreateDebugObject@16
extern _NtQueryObject@20
section .data

paramText   DB  "You are not using debugger, good job", 0
paramTitle  DB  "Anti-Debug info", 0
paramTextDEBUG   DB  "Close it right nao b4 its 2 late m8", 0
paramTitleDEBUG  DB  "Anti-Debug info", 0, 0, 0, 0 ; %4
memory times 0x1000 db 0

section .text

_main:

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

error:
ret