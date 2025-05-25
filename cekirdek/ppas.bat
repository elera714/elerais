@echo off
SET THEFILE=D:\calismalar\elerais\kodlar\cekirdek\cekirdek.bin
echo Linking %THEFILE%
C:\lazarus\fpc\3.0.4\bin\x86_64-win64\i386-linux-ld.exe -b elf32-i386 -m elf_i386  -Tcekirdek.ld    -s -L. -o D:\calismalar\elerais\kodlar\cekirdek\cekirdek.bin D:\calismalar\elerais\kodlar\cekirdek\link.res
if errorlevel 1 goto linkend
goto end
:asmend
echo An error occurred while assembling %THEFILE%
goto end
:linkend
echo An error occurred while linking %THEFILE%
:end
