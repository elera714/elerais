{==============================================================================

                    ELERA ��letim Sistemi

   Genel Bilgiler:
   ----------------------------------------------------------------------------
   Sistem Ad� : ELERA ��letim Sistemi (elerais)
   Kodlayan   : Fatih KILI�

   Teknik Bilgiler
   ----------------------------------------------------------------------------
   + Zaman Payla��ml� �okg�revlilik (Pre-emptive multitasking)
   + Statik / Dinamik Bellek Y�netimi
   + 1024 x 768'a kadar 16 / 24 / 32 bit Vesa 2.0+ Grafik Deste�i

   Sistem Gereklilikleri
   ----------------------------------------------------------------------------
   ��lemci: 386+
   RAM    : 64 MB+
   Video  : Vesa 2.0+

   S�r�m Bilgileri
   ----------------------------------------------------------------------------
   Telif Bilgisi: haklar.txt dosyas�na bak�n�z
   G�ncelleme Tarihi: (21.06.2020 - pazar)

==============================================================================}
program cekirdek;
{$mode objfpc}
{$asmmode intel}
{$WARNINGS ON}

uses paylasim, yukleyici, gorev, yonetim, genel, sistemmesaj, bmp, sanalbellek;

var
  _Gorev: PGorev = nil;

begin

  // belle�i sayfalama i�levine haz�rla
  // vmm.Init;

  asm
    cli

    mov eax,SISTEM_ESP
    mov esp,eax

    fninit

  // sayfalamay� aktifle�tir

    {mov eax,GERCEKBELLEK_DIZINADRESI;
    mov cr3,eax

    mov eax,cr0
    and eax,$1FFFFFFF     // enable caching
    and eax,not $10000    // disable write-protection
    or  eax,$80000000    // enable paging
    mov cr0,eax}
  end;

  GorevDegisimBayragi := 1;

  // ServisCalisiyor = False olmas� durumunda sistem mesajlar� ekrana yans�t�l�r
  // ServisCalisiyor = True olmas� durumunda sistem mesajlar� dahili olarak
  //  i�lenerek daha sonra sistem mesaj g�r�nt�leme programlar� taraf�ndan g�r�nt�lenir
  // NOT: bu de�i�keni aktifle�tiren GSistemMesaj.pas Yukle i�levidir
  GSistemMesaj.ServisCalisiyor := False;

  // �ekirdek �evre donan�m y�kleme i�levlerini ger�ekle�tir
  yukleyici.Yukle;

//  _Gorev^.Calistir(AcilisSurucuAygiti + ':\dsyyntcs.c');
//  _Gorev^.DurumDegistir(2, gdDurduruldu);

  SISTEM_MESAJ(RENK_LACIVERT, '+ Masa�st� y�netim program� y�kleniyor...', []);
  _Gorev^.Calistir(AcilisSurucuAygiti + ':\' + OnDegerMasaustuProgram);

  // sistem ana kontrol k�sm�na ge�i� yap
  SistemAnaKontrol;
  while True do begin end;
end.
