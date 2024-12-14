PATH=C:\lazarus\fpc\3.0.4\bin\i386-win32
fpc -Tlinux -Pi386 -FUoutput -Fu../rtl/units/i386-linux -Sc -Sg -Si -Sh -CX -Os -Xs -XX -k-Ttest.ld -otest.c test.lpr