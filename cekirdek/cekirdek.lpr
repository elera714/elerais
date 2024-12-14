{==============================================================================

                    ELERA Ýþletim Sistemi

   Genel Bilgiler:
   ----------------------------------------------------------------------------
   Sistem Adý : ELERA Ýþletim Sistemi (elerais)
   Kodlayan   : Fatih KILIÇ

   Teknik Bilgiler
   ----------------------------------------------------------------------------
   + Zaman Paylaþýmlý Çokgörevlilik (Pre-emptive multitasking)
   + Statik / Dinamik Bellek Yönetimi
   + 1024 x 768'a kadar 16 / 24 / 32 bit Vesa 2.0+ Grafik Desteði

   Sistem Gereklilikleri
   ----------------------------------------------------------------------------
   Ýþlemci: 386+
   RAM    : 64 MB+
   Video  : Vesa 2.0+

   Sürüm Bilgileri
   ----------------------------------------------------------------------------
   Telif Bilgisi: haklar.txt dosyasýna bakýnýz
   Güncelleme Tarihi: (21.06.2020 - pazar)

==============================================================================}
program cekirdek;
{$mode objfpc}
{$asmmode intel}
{$WARNINGS ON}

uses paylasim, yukleyici, gorev, yonetim, genel, sistemmesaj, bmp, sanalbellek;

var
  _Gorev: PGorev = nil;

begin

  // belleði sayfalama iþlevine hazýrla
  // vmm.Init;

  asm
    cli

    mov eax,SISTEM_ESP
    mov esp,eax

    fninit

  // sayfalamayý aktifleþtir

    {mov eax,GERCEKBELLEK_DIZINADRESI;
    mov cr3,eax

    mov eax,cr0
    and eax,$1FFFFFFF     // enable caching
    and eax,not $10000    // disable write-protection
    or  eax,$80000000    // enable paging
    mov cr0,eax}
  end;

  GorevDegisimBayragi := 1;

  // ServisCalisiyor = False olmasý durumunda sistem mesajlarý ekrana yansýtýlýr
  // ServisCalisiyor = True olmasý durumunda sistem mesajlarý dahili olarak
  //  iþlenerek daha sonra sistem mesaj görüntüleme programlarý tarafýndan görüntülenir
  // NOT: bu deðiþkeni aktifleþtiren GSistemMesaj.pas Yukle iþlevidir
  GSistemMesaj.ServisCalisiyor := False;

  // çekirdek çevre donaným yükleme iþlevlerini gerçekleþtir
  yukleyici.Yukle;

//  _Gorev^.Calistir(AcilisSurucuAygiti + ':\dsyyntcs.c');
//  _Gorev^.DurumDegistir(2, gdDurduruldu);

  SISTEM_MESAJ(RENK_LACIVERT, '+ Masaüstü yönetim programý yükleniyor...', []);
  _Gorev^.Calistir(AcilisSurucuAygiti + ':\' + OnDegerMasaustuProgram);

  // sistem ana kontrol kýsmýna geçiþ yap
  SistemAnaKontrol;
  while True do begin end;
end.
