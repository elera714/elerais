@ECHO OFF
PATH=C:\lazarus\fpc\3.0.4\bin\x86_64-win64
objdump -D test.c > test.asm
pause