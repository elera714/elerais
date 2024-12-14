@ECHO OFF
PATH=C:\lazarus\fpc\2.6.2\bin\i386-win32
objdump -D test.c > test.asm
pause