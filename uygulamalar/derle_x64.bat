PATH=C:\lazarus\fpc\3.0.4\bin\x86_64-win64

cd agbilgi
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd arpbilgi
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd bellkbil
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd bellkgor
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd bharita
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd calistir
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd defter
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd dnssorgu
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd donusum
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd dskbolum
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd dskgor
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd dsybil
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd dsyyntcs
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd dugmeler
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd grafik1
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd grafik2
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd grafik3
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd grafik4
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd grafik5
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd grfktest
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd grvyntcs
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd hafiza
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd iletisim
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd iskelet
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd kaydirma
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd kmodtest
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd kopyala
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd mustudk
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd muyntcs
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd nesnegor
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd noktalar
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd paneller
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd pcibil
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd resimgor
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd saat
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd sisbilgi
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd smsjgor
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd takvim
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd tarayici
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd tasarim
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd testsrc
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd yzmcgor
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..

cd yzmcgor2
call derle.bat
IF %ERRORLEVEL% NEQ 0 GOTO CIK
cd..
CLS
ECHO "Tum projeler basariyla derlendi..."
PAUSE
EXIT

:CIK
ECHO "Proje derlenirken hata ile karsilasildi!"
pause
EXIT