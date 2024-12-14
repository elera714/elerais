{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: dugmeler.lpr
  Program Ýþlevi: resim düðme test programý

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
program dugmeler;

uses n_gorev, gn_pencere, gn_resimdugmesi;

const
  ProgramAdi: string = 'Düðmeler';

  RenkListesi: array[0..15] of TRenk = (
    $FFFFFF, $C0C0C0, $808080, $000000,
    $FF0000, $800000, $FFFF00, $808000,
    $00FF00, $008000, $00FFFF, $008080,
    $0000FF, $000080, $FF00FF, $800080);

  ResimListesi: array[0..15] of TRenk = (
    $80000000, $80000001, $80000002, $80000003,
    $80000004, $80000005, $80000006, $80000007,
    $80000008, $80000009, $8000000A, $8000000B,
    $8000000C, $8000000D, $8000000E, $8000000F);

var
  Gorev: TGorev;
  Pencere: TPencere;
  rdDugmeler: array[0..15] of TResimDugmesi;
  Olay: TOlay;
  Sol, Ust, i: TISayi4;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 200, 200, 128, 128, ptIletisim, ProgramAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Sol := 4;
  Ust := 4;
  for i := 1 to 16 do
  begin

    //rdDugmeler[i - 1].Olustur(Pencere.Kimlik, Sol, Ust, 26, 26, RenkListesi[i - 1]);
    rdDugmeler[i - 1].Olustur(Pencere.Kimlik, Sol, Ust, 26, 26, ResimListesi[i - 1]);
    rdDugmeler[i - 1].Goster;

    Sol += 30;
    if((i mod 4) = 0) then
    begin

      Sol := 8;
      Ust += 30;
    end;
  end;

  Pencere.Gorunum := True;

  while True do
  begin

    Gorev.OlayBekle(Olay);
    if(Olay.Olay = FO_TIKLAMA) then
    begin

    end
    else if(Olay.Olay = CO_CIZIM) then
    begin

    end;
  end;
end.
