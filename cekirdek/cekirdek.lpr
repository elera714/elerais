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
   Güncelleme Tarihi: (26.11.2026 - perþembe)

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

  asm
    mov eax,SISTEM_ESP
    mov esp,eax

    // cr0 yazmacýnýn EM ve TS bitlerini temizle
    mov  eax,cr0
    and  eax,not(CR0_EM_BIT + CR0_TS_BIT)
    or   eax,CR0_MP_BIT
    mov  cr0,eax

    // sse / xmm desteði - maskelenmemis SSE istisnalari
    mov  eax,cr4
    or   eax,(CR4_OSFXSR_BIT + CR4_OSXMMEXCPT_BIT)
    mov  cr4,eax

    // x87 fpu / sse durumunu il durumuna getir
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
