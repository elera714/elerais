program grafik4;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Program Adı: grafik4.lpr
  Program İşlevi: çoklu poligon çizim programı

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, gn_dugme, n_zamanlayici, gn_islemgostergesi, gn_onaykutusu,
  gn_giriskutusu, gn_degerdugmesi;

const
  ProgramAdi: string = 'Grafik-4';

  USTDEGER_NOKTASAYISI = 28;

type
  TNoktaKayit = record
    Sol, Ust,
    YatayDeger, DikeyDeger: TISayi4;
  end;

var
  Gorev: TGorev;
  Pencere: TPencere;
  Zamanlayici: TZamanlayici;
  Olay: TOlay;
  Noktalar: array[0..USTDEGER_NOKTASAYISI - 1] of TNoktaKayit;
  Sol, Ust, i, j: TISayi4;

procedure NoktalariCiz(AIlk, ASon: TSayi4; ARenk: TRenk);
var
  i: TISayi4;
begin

  for i := AIlk to ASon - 1 do
  begin

    if(i = ASon - 1) then
      Pencere.Tuval.Cizgi(Noktalar[i].Sol, Noktalar[i].Ust,
        Noktalar[AIlk].Sol, Noktalar[AIlk].Ust, ctNokta, ARenk)
    else Pencere.Tuval.Cizgi(Noktalar[i].Sol, Noktalar[i].Ust,
      Noktalar[i + 1].Sol, Noktalar[i + 1].Ust, ctNokta, ARenk);
  end;
end;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 50, 50, 500, 400, ptIletisim, ProgramAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Pencere.Gorunum := True;

  // ilk değer atamaları
  for i := 0 to USTDEGER_NOKTASAYISI - 1 do
  begin

    Randomize;

    Sol := Random(500);
    Noktalar[i].Sol := Sol;
    if(Sol > 255) then
      Noktalar[i].YatayDeger := 1
    else Noktalar[i].YatayDeger := -1;

    Ust := Random(400);
    Noktalar[i].Ust := Ust;
    if(Ust > 200) then
      Noktalar[i].DikeyDeger := 1
    else Noktalar[i].DikeyDeger := -1;
  end;

  Zamanlayici.Olustur(30);
  Zamanlayici.Baslat;

  while True do
  begin

    Gorev.OlayAl(Olay);
    if(Olay.Olay = CO_ZAMANLAYICI) then
    begin

      for i := 0 to USTDEGER_NOKTASAYISI - 1 do
      begin

        // noktanın yatay sınır kontrolü
        j := Noktalar[i].Sol;
        if(Noktalar[i].YatayDeger = 1) then
          j += 10
        else j -= 10;

        if(j > 500 - 1) then
        begin
          j := 500 - 1;
          Noktalar[i].YatayDeger := -1;
        end
        else if(j < 0) then
        begin
          j := 0;
          Noktalar[i].YatayDeger := 1;
        end;
        Noktalar[i].Sol := j;

        // noktanın dikey sınır kontrolü
        j := Noktalar[i].Ust;
        if(Noktalar[i].DikeyDeger = 1) then
          j += 10
        else j -= 10;

        if(j > 400 - 1) then
        begin
          j := 400 - 1;
          Noktalar[i].DikeyDeger := -1
        end
        else if(j < 1) then
        begin
          j := 0;
          Noktalar[i].DikeyDeger := 1;
        end;
        Noktalar[i].Ust := j;
      end;

      Pencere.Ciz;
    end
    else if(Olay.Olay = CO_CIZIM) then
    begin

      // yeni nokta koordinatlarını çiz
      NoktalariCiz(00, 04, RENK_KIRMIZI);
      NoktalariCiz(04, 08, RENK_YESIL);
      NoktalariCiz(08, 12, RENK_SIYAH);
      NoktalariCiz(12, 16, RENK_MAVI);
      NoktalariCiz(16, 20, RENK_PEMBE);
      NoktalariCiz(20, 24, RENK_LACIVERT);
      NoktalariCiz(24, 28, RENK_BORDO);
    end;
  end;
end.
