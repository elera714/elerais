program grafik3;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Program Adı: grafik3.lpr
  Program İşlevi: çoklu yönlendirilmiş nokta (pixel) işaretleme programı

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, n_zamanlayici;

const
  ProgramAdi: string = 'Grafik-3';

  RenkListesi: array[0..15] of TRenk = (
      $FFFFFF, $C0C0C0, $808080, $000000,
      $FF0000, $800000, $FFFF00, $808000,
      $00FF00, $008000, $00FFFF, $008080,
      $0000FF, $000080, $FF00FF, $800080);
  USTDEGER_NOKTASAYISI = 16;

type
  TNoktaKayit = record
    Sol, Ust,
    YatayDeger, DikeyDeger,
    Renk: TISayi4;
  end;

var
  Gorev: TGorev;
  Pencere: TPencere;
  Noktalar: array[0..USTDEGER_NOKTASAYISI - 1] of TNoktaKayit;
  YatayDeger, DikeyDeger, i, Renk: TISayi4;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 50, 50, 400, 300, ptIletisim, ProgramAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Pencere.Gorunum := True;

  for i := 0 to USTDEGER_NOKTASAYISI - 1 do
  begin

    Randomize;
    YatayDeger := Random(500);
    DikeyDeger := Random(500);
    Renk := RenkListesi[Random(15)];

    Noktalar[i].Sol := YatayDeger;
    if(YatayDeger > 255) then
      Noktalar[i].YatayDeger := 1
    else Noktalar[i].YatayDeger := -1;

    Noktalar[i].Ust := DikeyDeger;
    if(DikeyDeger > 255) then
      Noktalar[i].DikeyDeger := 1
    else Noktalar[i].DikeyDeger := -1;

    Noktalar[i].Renk := Renk;
  end;

  while True do
  begin

    for i := 0 to USTDEGER_NOKTASAYISI - 1 do
    begin

      YatayDeger := Noktalar[i].Sol;
      YatayDeger := YatayDeger + Noktalar[i].YatayDeger;
      if(YatayDeger < 0) then
      begin

        YatayDeger := 0;
        Noktalar[i].YatayDeger := 1;
      end
      else if(YatayDeger > 400) then
      begin

        YatayDeger := 400;
        Noktalar[i].YatayDeger := -1;
      end;
      Noktalar[i].Sol := YatayDeger;

      DikeyDeger := Noktalar[i].Ust;
      DikeyDeger := DikeyDeger + Noktalar[i].DikeyDeger;
      if(DikeyDeger < 0) then
      begin

        DikeyDeger := 0;
        Noktalar[i].DikeyDeger := 1;
      end
      else if(DikeyDeger > 300) then
      begin

        DikeyDeger := 300;
        Noktalar[i].DikeyDeger := -1;
      end;
      Noktalar[i].Ust := DikeyDeger;

      Renk := Noktalar[i].Renk;

      Pencere.Tuval.PixelYaz(YatayDeger, DikeyDeger, Renk);
    end;
  end;
end.
