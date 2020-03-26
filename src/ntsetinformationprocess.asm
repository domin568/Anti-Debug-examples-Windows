[bits 32]

global _main
extern _MessageBoxA@16
extern _NtSetInformationProcess@16
extern _OpenProcessToken@16
extern _AdjustTokenPrivileges@24
extern _LookupPrivilegeValueA@12
extern _ExitProcess@4
section .data

paramTextDEBUG   DB  "Close it right nao b4 its 2 late m8", 0
paramTitleDEBUG  DB  "Anti-Debug info", 0
paramText   DB  "You are not using debugger, good job", 0
paramTitle  DB  "Anti-Debug info", 0
debug DB "SeDebugPrivilege", 0

section .text

_main:


sub esp, 4
mov dword [esp], 0 ; handle to token
push esp
push 0x20 ; TOKEN_ADJUST_PRIVILEGE
push 0xffffffff ; current process handle
call _OpenProcessToken@16
mov edi, [esp] ; take our token handle to safe place

sub esp, 8 ; LUID structure

push esp
push debug
push 0
call _LookupPrivilegeValueA@12
mov edx, esp ; move pointer to LUID object to ecx

sub esp, 16
mov esi, [edx] ; get LUID value
mov dword [esp], 1 ; privilege count
mov dword [esp + 4], esi ; LUID
mov dword [esp + 8], 0 ; HIGH of LUID
mov dword [esp + 12], 2; SE_PRIVILEGE_ENABLED
mov edx, esp

push 0
push 0
push 0
push edx ; new state
push 0
push edi ; token
call _AdjustTokenPrivileges@24
add esp, 28


; set process critical 
sub esp, 4
mov dword [esp] , 1
push 4
push esp
push 0x1d
push 0xffffffff ; current process
call _NtSetInformationProcess@16
add esp, 4
cmp eax, 0 
jz debugged

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
push 0xbeefc0de
call _ExitProcess@4
ret

