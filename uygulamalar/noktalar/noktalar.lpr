{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Program Adı: noktalar.lpr
  Program İşlevi: nokta işaretleme test programı

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
program noktalar;

uses n_gorev, gn_pencere, gn_dugme, n_zamanlayici, gn_islemgostergesi, gn_onaykutusu;

const
  ProgramAdi: string = 'Noktalar (300 x 300) - 0.5 saniye';

  Renkler: array[0..7] of TRenk = (
      $D2691E, $7FFF00, $00008B, $008B8B,
      $9932CC, $8FBC8F, $9400D3, $FFD700);

var
  Gorev: TGorev;
  Pencere: TPencere;
  OnayKutusu: TOnayKutusu;
  Zamanlayici: TZamanlayici;
  Olay: TOlay;

procedure NoktalariCiz;
var
  i, j, Yatay, Dikey: TSayi4;
begin

  for i := 0 to 89999 do
  begin

    Randomize;
    Yatay := Random(300);
    Dikey := Random(300);
    j := Random(7);
    Pencere.Tuval.PixelYaz(Yatay, Dikey + 20, Renkler[j]);
  end;
end;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 100, 100, 300, 300 + 20, ptIletisim, ProgramAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  OnayKutusu.Olustur(Pencere.Kimlik, 2, 2, 'Devam Et');
  OnayKutusu.Goster;

  Pencere.Gorunum := True;

  Zamanlayici.Olustur(50);

  while True do
  begin

    Gorev.OlayBekle(Olay);

    if(Olay.Olay = CO_ZAMANLAYICI) then

      NoktalariCiz

    else if(Olay.Olay = CO_DURUMDEGISTI) then
    begin

      if(Olay.Deger1 = 1) then Zamanlayici.Baslat
      else if(Olay.Deger1 = 0) then Zamanlayici.Durdur;
    end;
  end;
end.
