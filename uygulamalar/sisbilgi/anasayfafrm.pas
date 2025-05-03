{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, _forms, gn_sayfakontrol, gn_dugme, n_genel;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGorev: TGorev;
    FPencere: TPencere;
    FSayfaKontrol: TSayfaKontrol;
    FdugKapat: TDugme;
    FGenel: TGenel;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Sistem Bilgisi';

var
  SistemBilgisi: TSistemBilgisi;
  IslemciBilgisi: TIslemciBilgisi;
  ToplamRAMBlok, AyrilmisRAMBlok,
  KullanilmisRAMBlok, BosRAMBlok,
  BlokUzunlugu: TSayi4;

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 100, 100, 375, 160, ptIletisim, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FSayfaKontrol.Olustur(FPencere.Kimlik, 5, 5, 365, 120);
  FSayfaKontrol.SayfaEkle('Sistem');
  FSayfaKontrol.SayfaEkle('Ýþlemci');
  FSayfaKontrol.SayfaEkle('Bellek');
  FSayfaKontrol.SayfaEkle('Ekran');

  FSayfaKontrol.Goster;

  FdugKapat.Olustur(FPencere.Kimlik, 300, 130, 70, 22, 'Kapat');
  FdugKapat.Goster;
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;

  // sistem bilgilerini al
  FGorev.SistemBilgisiAl(@SistemBilgisi);
  FGorev.IslemciBilgisiAl(@IslemciBilgisi);
  FGenel.GenelBellekBilgisiAl(@ToplamRAMBlok, @AyrilmisRAMBlok, @KullanilmisRAMBlok,
    @BosRAMBlok, @BlokUzunlugu);

  // 1. sayfa
  FSayfaKontrol.EtiketEkle(0, 8, 8, 'Sistem: ' + SistemBilgisi.SistemAdi);
  FSayfaKontrol.EtiketEkle(0, 8, 24, 'Mimari: ' + SistemBilgisi.FPCMimari);
  FSayfaKontrol.EtiketEkle(0, 8, 40, 'FPC Sürüm: ' + SistemBilgisi.FPCSurum);
  FSayfaKontrol.EtiketEkle(0, 8, 56, 'Derleme Tarihi: ' + SistemBilgisi.DerlemeBilgisi);

  // 2. sayfa
  FSayfaKontrol.EtiketEkle(1, 8, 8, 'Ýþlemci: ' + IslemciBilgisi.Satici);
  FSayfaKontrol.EtiketEkle(1, 8, 40, 'CPUID = 1 [EAX]: ' + HexToStr(IslemciBilgisi.Ozellik1_EAX, True, 8));
  FSayfaKontrol.EtiketEkle(1, 8, 56, 'CPUID = 1 [EDX]: ' + HexToStr(IslemciBilgisi.Ozellik1_EDX, True, 8));
  FSayfaKontrol.EtiketEkle(1, 8, 72, 'CPUID = 1 [ECX]: ' + HexToStr(IslemciBilgisi.Ozellik1_ECX, True, 8));

  // 3. sayfa
  FSayfaKontrol.EtiketEkle(2, 8, 8,  'Toplam RAM    : ' + IntToStr(ToplamRAMBlok * BlokUzunlugu));
  FSayfaKontrol.EtiketEkle(2, 8, 24, 'Ayrýlmýþ RAM  : ' + IntToStr(AyrilmisRAMBlok * BlokUzunlugu));
  FSayfaKontrol.EtiketEkle(2, 8, 40, 'Kullanýlan RAM: ' + IntToStr(KullanilmisRAMBlok * BlokUzunlugu));
  FSayfaKontrol.EtiketEkle(2, 8, 56, 'Boþ RAM       : ' + IntToStr(BosRAMBlok * BlokUzunlugu));

  // 4. sayfa
  FSayfaKontrol.EtiketEkle(3, 8, 8,  'Yatay Çözünürlük: ' + IntToStr(SistemBilgisi.YatayCozunurluk));
  FSayfaKontrol.EtiketEkle(3, 8, 24, 'Dikey Çözünürlük: ' + IntToStr(SistemBilgisi.DikeyCozunurluk));
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  // çekirdek tarafýndan gönderilen programýn kendisini sonlandýrma talimatý
  if(AOlay.Olay = CO_SONLANDIR) then
  begin

    FGorev.Sonlandir(-1);
  end
  else if(AOlay.Olay = FO_TIKLAMA) and (AOlay.Kimlik = FdugKapat.Kimlik) then
    FGorev.Sonlandir(-1);

  Result := 1;
end;

end.
