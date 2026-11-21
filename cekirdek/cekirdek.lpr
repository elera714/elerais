{==============================================================================

                    ELERA Ýþletim Sistemi

   Genel Bilgiler:
   ----------------------------------------------------------------------------
   Sistem Adý : ELERA Ýþletim Sistemi (elerais)
   Kodlayan   : Fatih KILIÇ

   Teknik Bilgiler
   ----------------------------------------------------------------------------
   + yazýlýmsal zaman paylaþýmlý çokgörevlilik (pre-emptive multitasking)
   + statik / dinamik bellek yönetimi
   + að yönetim arabirimleri (donaným / yazýlým)
   + 1024 x 768'a kadar 16 / 24 / 32 bit vesa 2.0+ grafik desteði
   + 1000mhz çalýþma frekansý
   + 256MB bellekte çalýþabilme yeteneði

   Sistem Gereklilikleri
   ----------------------------------------------------------------------------
   Ýþlemci: 386+
   RAM    : 256 MB+
   Video  : Vesa 2.0+

   Sürüm Bilgileri
   ----------------------------------------------------------------------------
   Telif Bilgisi: haklar.txt dosyasýna bakýnýz
   Güncelleme Tarihi: (21.11.2026 - cumartesi)

==============================================================================}
program cekirdek;
{$mode objfpc}
{$asmmode intel}
{$WARNINGS ON}

uses paylasim, yukleyici, gorev, yonetim, sistemmesaj, bmp, sanalbellek, gercekbellek;

type
  TCekirdek = object
  public
    procedure Yukle;
  end;

var
  GCekirdek: TCekirdek;

procedure TCekirdek.Yukle;
var
  Yukleyici: TYukleyici;
begin

  // belleði sayfalama iþlevine hazýrla
  // vmm.Init;

  asm
    //cli
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

  // belleði ilk kullaným için hazýrla
  // Önemli: GGercekBellek.Yukle iþlevinin diðer iþlevlere zemin hazýrlamasý için
  // öncelikle yüklenmesi gerekmektedir. (özellikle class yapýlarý için)
  GGercekBellek.Yukle;

  // çekirdeðin çalýþmasý için gerekli ihtiyaç duyulacak önyüklemeleri gerçekleþtir,
  // nesneleri / donanýmlarý yükle, ana iþlevleri çalýþtýr
  Yukleyici := TYukleyici.Create;

  // çekirdek yükleme sonrasýnda çalýþtýrýlacak masaüstü uygulamasý / servisler
  // dahili uygulamalarý yükle
  Yukleyici.UygulamalariYukle;

  // sistem ana kontrol kýsmýna geçiþ yap
  GYonetim.SistemAnaKontrol;
end;

begin

  GCekirdek.Yukle;
end.
