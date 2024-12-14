program saat;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: saat.lpr
  Program Ýþlevi: dijital tarih / saat programý

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, n_zamanlayici, n_genel;

const
  ProgramAdi: string = 'Dijital Saat';

var
  Genel: TGenel;
  Gorev: TGorev;
  Pencere: TPencere;
  Zamanlayici: TZamanlayici;
  Olay: TOlay;
  SaatDizi: array[0..2] of TSayi1;      // saat / dakika / saniye
  TarihDizi: array[0..3] of TSayi2;     // gün / ay / yýl / haftanýn günü
  s: string;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 200, 200, 160, 52, ptIletisim, 'Tarih / Saat', $E3F5AB);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Pencere.Gorunum := True;

  Zamanlayici.Olustur(100);
  Zamanlayici.Baslat;

  while True do
  begin

    Gorev.OlayBekle(Olay);
    if(Olay.Olay = CO_ZAMANLAYICI) then
    begin

      Pencere.Ciz;
    end
    else if(Olay.Olay = CO_CIZIM) then
    begin

      Pencere.Tuval.KalemRengi := $041F2F;

      Genel.SaatAl(@SaatDizi);
      s := TimeToStr(SaatDizi);
      Pencere.Tuval.YaziYaz(46, 8, s);

      Genel.TarihAl(@TarihDizi);
      s := DateToStr(TarihDizi, True);
      Pencere.Tuval.YaziYaz(22, 28, s);
    end;
  end;
end.
