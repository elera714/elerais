PATH=C:\lazarus\fpc\3.0.4\bin\x86_64-win64
fpc -Tlinux -Pi386 -FUoutput -Fu..\..\..\rtl_uygulama\linux\units\i386-linux -Sc -Sg -Si -Sh -CX -Os -Xs -XX -k-Ttest.ld -otest.c test.lpr

pause