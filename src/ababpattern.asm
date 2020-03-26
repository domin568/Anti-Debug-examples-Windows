[bits 32]

global _main
extern _MessageBoxA@16
extern _IsDebuggerPresent@0
extern _CheckRemoteDebuggerPresent@8
extern _NtQueryInformationProcess@20
extern _GetCurrentProcess@0
extern _SetLastError@4
extern _GetLastError@0
extern _RaiseException@16
extern _CloseHandle@4
section .data

paramTextDEBUG   DB  "Close it right nao b4 its 2 late m8", 0
paramTitleDEBUG  DB  "Anti-Debug info", 0
paramText   DB  "You are not using debugger, good job", 0
paramTitle  DB  "Anti-Debug info", 0

section .text

_main:

mov eax, [fs:0x30]
mov eax, [eax+0x18]
mov ecx, 0x1000
loop:
cmp dword [eax+ecx], 0xabababab
je debugged
sub ecx, 4
jne loop

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

