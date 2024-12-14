@ECHO OFF

REM PATH=C:\lazarus\fpc\3.0.2\bin\i386-win32
PATH=C:\lazarus\fpc\3.0.4\bin\x86_64-win64

objdump -M intel -D test3.o > test3.txt

pause