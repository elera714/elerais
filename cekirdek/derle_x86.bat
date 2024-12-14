SET DERLEYICI_YOL=C:\lazarus\fpc\3.0.4\bin\i386-win32

%DERLEYICI_YOL%\fpc.exe -Fu..\rtl_cekirdek\linux\units\i386-linux;..\ortak;..\ortak\cekirdek;..\ortak\donanim;..\ortak\suruculer\ag;..\ortak\kesme;..\ortak\ag;..\ortak\karakter;..\ortak\suruculer\grafik;..\ortak\diger;..\ortak\suruculer\fare;..\ortak\suruculer;..\ortak\dosyabicim;..\ortak\nesne;..\ortak\dosyasistemi;..\ortak\usb;..\diger -FUdosyalar -ocekirdek.bin -Mobjfpc -Sc -Sg -Si -Sh -Rintel -Tlinux -Pi386 -CX -XX -k-Tcekirdek.ld cekirdek.lpr

@pause