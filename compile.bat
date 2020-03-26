echo off
@echo This script compiles using nasm and golink .asm files in src/ folder. 
@echo Make sure you have set nasm and golink to your PATH environment variable or copied them to this folder
pause 
where /q nasm
IF ERRORLEVEL 1 (
    ECHO NASM is missing. Ensure it is in your PATH or in this directory.
    pause
    EXIT /B
) ELSE (
    where /q golink
	IF ERRORLEVEL 1 (
    	ECHO GOLINK is missing. Ensure it is in your PATH or in this directory.
    	pause
    	EXIT /B
	) ELSE (
    	mkdir obj 2> NUL
		mkdir bin 2> NUL
		for /f %%i in ('FORFILES /S /M *.asm /C "cmd /c echo @fname"') do cmd /c "nasm -f win src/%%~i.asm -o obj/%%~i.obj && golink obj/%%~i.obj -entry=_main /fo bin/%%~i.exe C:\Windows\system32\kernel32.dll C:\Windows\system32\user32.dll C:\Windows\system32\ntdll.dll C:\Windows\system32\advapi32.dll"
		pause
	)
)