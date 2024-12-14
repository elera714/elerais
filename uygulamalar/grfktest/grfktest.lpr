program grfktest;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: grfktest.lpr
  Program Ýþlevi: grafik test programý (fps deðerini ölçer)

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, n_zamanlayici;

const
  ProgramAdi: string = 'Grafik Test - 200x200';

  RenkListesi: array[0..7] of TRenk = (
    $00FF8080, $00FF6060, $00FF4040, $00FF2020,
    $00FF2020, $00FF4040, $00FF6060, $00FF8080);

var
  Gorev: TGorev;
  Pencere: TPencere;
  Zamanlayici: TZamanlayici;
  Olay: TOlay;
  RenkSiraDegeri: TSayi4 = 0;
  FPSDegeri: TSayi4 = 0;
  FPSSayaci: TSayi4 = 0;

procedure NoktalariCiz;
var
  Renk: TRenk;
  Sol, Ust: TSayi4;
begin

  Inc(RenkSiraDegeri);
  RenkSiraDegeri := RenkSiraDegeri and 7;
  Renk := RenkListesi[RenkSiraDegeri];

  for Ust := 0 to 200 - 1 do
  begin

    for Sol := 0 to 200 - 1 do
    begin

      Pencere.Tuval.PixelYaz(Sol, Ust, Renk);
    end;
  end;

  Pencere.Tuval.KalemRengi := RENK_SIYAH;
  Pencere.Tuval.Dikdortgen(0, 0, 10 * 8, 1 * 16, RENK_SIYAH, True);
  Pencere.Tuval.KalemRengi := RENK_BEYAZ;
  Pencere.Tuval.SayiYaz16(0, 0, True, 8, FPSDegeri);
  Inc(FPSSayaci);
end;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 100, 100, 200, 200, ptIletisim, ProgramAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Pencere.Gorunum := True;

  Zamanlayici.Olustur(100);
  Zamanlayici.Baslat;

  while True do
  begin

    if(Gorev.OlayAl(Olay) = 0) then

      NoktalariCiz

    else if(Olay.Olay = CO_CIZIM) then

      NoktalariCiz

    // her bir saniyede FPS deðerini kaydet ve yeniden FPS sayacýný baþlat
    else if(Olay.Olay = CO_ZAMANLAYICI) then
    begin

      FPSDegeri := FPSSayaci;
      FPSSayaci := 0;
    end;
  end;
end.
