program sisbilgi;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: sisbilgi.lpr
  Program Ýþlevi: sistem hakkýnda bilgi verir

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, gn_sayfakontrol, gn_dugme;

const
  ProgramAdi: string = 'Sistem Bilgisi';

var
  Gorev: TGorev;
  Pencere: TPencere;
  SayfaKontrol: TSayfaKontrol;
  dugKapat: TDugme;
  Olay: TOlay;
  SistemBilgisi: TSistemBilgisi;
  IslemciBilgisi: TIslemciBilgisi;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 100, 100, 375, 160, ptIletisim, ProgramAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  SayfaKontrol.Olustur(Pencere.Kimlik, 5, 5, 365, 120);
  SayfaKontrol.SayfaEkle('Sistem');
  SayfaKontrol.SayfaEkle('Ýþlemci');
  SayfaKontrol.SayfaEkle('Ekran');

  SayfaKontrol.Goster;

  dugKapat.Olustur(Pencere.Kimlik, 300, 130, 70, 22, 'Kapat');
  dugKapat.Goster;

  Pencere.Gorunum := True;

  // sistem bilgilerini al
  Gorev.SistemBilgisiAl(@SistemBilgisi);
  Gorev.IslemciBilgisiAl(@IslemciBilgisi);

  // 1. sayfa
  SayfaKontrol.EtiketEkle(0, 8, 8, 'Sistem: ' + SistemBilgisi.SistemAdi);
  SayfaKontrol.EtiketEkle(0, 8, 24, 'Mimari: ' + SistemBilgisi.FPCMimari);
  SayfaKontrol.EtiketEkle(0, 8, 40, 'FPC Sürüm: ' + SistemBilgisi.FPCSurum);
  SayfaKontrol.EtiketEkle(0, 8, 56, 'Derleme Tarihi: ' + SistemBilgisi.DerlemeBilgisi);

  // 2. sayfa
  SayfaKontrol.EtiketEkle(1, 8, 8, 'Ýþlemci: ' + IslemciBilgisi.Satici);
  SayfaKontrol.EtiketEkle(1, 8, 40, 'CPUID = 1 [EAX]: ' + HexToStr(IslemciBilgisi.Ozellik1_EAX, True, 8));
  SayfaKontrol.EtiketEkle(1, 8, 56, 'CPUID = 1 [EDX]: ' + HexToStr(IslemciBilgisi.Ozellik1_EDX, True, 8));
  SayfaKontrol.EtiketEkle(1, 8, 72, 'CPUID = 1 [ECX]: ' + HexToStr(IslemciBilgisi.Ozellik1_ECX, True, 8));

  // 3. sayfa
  SayfaKontrol.EtiketEkle(2, 8, 8,  'Yatay Çözünürlük: ' + IntToStr(SistemBilgisi.YatayCozunurluk));
  SayfaKontrol.EtiketEkle(2, 8, 24, 'Dikey Çözünürlük: ' + IntToStr(SistemBilgisi.DikeyCozunurluk));

  while True do
  begin

    Gorev.OlayBekle(Olay);

    if(Olay.Olay = FO_TIKLAMA) and (Olay.Kimlik = dugKapat.Kimlik) then
      Gorev.Sonlandir(-1);
  end;
end.
