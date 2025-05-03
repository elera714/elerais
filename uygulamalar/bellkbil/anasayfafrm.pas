{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_zamanlayici, n_genel, _forms, gn_islemgostergesi;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGenel: TGenel;
    FGorev: TGorev;
    FPencere: TPencere;
    FIslemGostergesi: TIslemGostergesi;
    FZamanlayici: TZamanlayici;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Bellek Kullaným Bilgisi';
  CekirdekBaslangicAdresiK: string = 'Çekirdek Baþ. Adresi  :';
  CekirdekBitisAdresiK: string = 'Çekirdek Bit. Adresi  :';
  CekirdekUzunluguK: string = 'Çekirdek Kod Uzunluðu :';
  BlokBilgisi: string = 'Blok Bilgileri (1 Blok = 4K)';
  BlokBaslik1: string =  'Toplam  Ayrýlmýþ  Kullanýlan  Boþ';
  BlokBaslik2: string = '------  --------  ----------  ----';

var
  CekirdekBaslangicAdresi: TSayi4 = 0;
  CekirdekBitisAdresi: TSayi4 = 0;
  CekirdekUzunlugu: TSayi4 = 0;
  ToplamRAMBlok: TSayi4 = 0;
  AyrilmisRAMBlok: TSayi4 = 0;
  KullanilmisRAMBlok: TSayi4 = 0;
  BosRAMBlok: TSayi4 = 0;
  BlokUzunlugu: TSayi4 = 0;

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 50, 50, 290, 172, ptIletisim, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FIslemGostergesi.Olustur(FPencere.Kimlik, 0, 86, 280, 22);
  FIslemGostergesi.DegerleriBelirle(1, 8095);
  FIslemGostergesi.Goster;
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;

  FZamanlayici.Olustur(100);
  FZamanlayici.Baslat;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  // çekirdek tarafýndan gönderilen programýn kendisini sonlandýrma talimatý
  if(AOlay.Olay = CO_SONLANDIR) then
  begin

    FGorev.Sonlandir(-1);
  end
  else if(AOlay.Olay = CO_CIZIM) then
  begin

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(0, 0 * 16, CekirdekBaslangicAdresiK);
    FPencere.Tuval.SayiYaz16(24 * 8, 0 * 16, True, 8, CekirdekBaslangicAdresi);

    FPencere.Tuval.YaziYaz(0, 1 * 16, CekirdekBitisAdresiK);
    FPencere.Tuval.SayiYaz16(24 * 8, 1 * 16, True, 8, CekirdekBitisAdresi);

    FPencere.Tuval.YaziYaz(0, 2 * 16, CekirdekUzunluguK);
    FPencere.Tuval.SayiYaz16(24 * 8, 2 * 16, True, 8, CekirdekUzunlugu);

    FPencere.Tuval.YaziYaz(0, 4 * 16, BlokBilgisi);
    FPencere.Tuval.YaziYaz(0, 7 * 16, BlokBaslik1);
    FPencere.Tuval.YaziYaz(0, 8 * 16, BlokBaslik2);

    FPencere.Tuval.SayiYaz10(1 * 8, 9 * 16, ToplamRAMBlok);
    FPencere.Tuval.SayiYaz10(10 * 8, 9 * 16, AyrilmisRAMBlok);
    FPencere.Tuval.SayiYaz10(20 * 8, 9 * 16, KullanilmisRAMBlok);
    FPencere.Tuval.SayiYaz10(30 * 8, 9 * 16, BosRAMBlok);

    FIslemGostergesi.KonumBelirle(KullanilmisRAMBlok);
  end
  else if(AOlay.Olay = CO_ZAMANLAYICI) then
  begin

    FGenel.CekirdekBellekBilgisiAl(@CekirdekBaslangicAdresi, @CekirdekBitisAdresi,
      @CekirdekUzunlugu);
    FGenel.GenelBellekBilgisiAl(@ToplamRAMBlok, @AyrilmisRAMBlok, @KullanilmisRAMBlok,
      @BosRAMBlok, @BlokUzunlugu);

    FPencere.Ciz;
  end;

  Result := 1;
end;

end.
