[bits 32]

global _main
extern _MessageBoxA@16
extern _RaiseException@16
section .data

paramTextDEBUG   DB  "Close it right nao b4 its 2 late m8", 0
paramTitleDEBUG  DB  "Anti-Debug info", 0
paramText   DB  "You are not using debugger, good job", 0
paramTitle  DB  "Anti-Debug info", 0

section .text

_main:

; DebugMessage exception checking (Works for OllyDbg, ImmunityDebugger, not on x64dbg)

mov ecx, [fs:0]
push not_debugged_exception
push ecx
mov [fs:0], esp

sub esp, 4
mov dword [esp], 0x00414141
sub esp, 16
mov dword [esp], 0
mov dword [esp+4], 0 
mov dword [esp+8], 4
mov dword [esp+12], ecx

push esp
push 4
push 0
push 0x40010006 ; DBG_PRINT_EXCEPTION_C 
call _RaiseException@16
add esp, 28
jmp debugged

not_debugged_exception:
;pushfd
;pop ecx
mov esp, [esp+8] ; cleaning up
mov eax, [fs:0]
mov eax, [eax] ; traversing the list
mov eax, [eax]
mov [fs:0], eax
add esp, 8

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

