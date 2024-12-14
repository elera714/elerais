program grafik1;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Program Adı: grafik1.lpr
  Program İşlevi: grafik test programı

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, gn_dugme, n_zamanlayici;

const
  ProgramAdi: string = 'Grafik-1';

var
  Gorev: TGorev;
  Pencere: TPencere;
  Zamanlayici: TZamanlayici;

var
  Olay: TOlay;
  Dizi: array[0..149] of TISayi4;
  i: TSayi4;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 100, 100, 150, 50, ptIletisim, ProgramAdi, RENK_SIYAH);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Pencere.Gorunum := True;

  for i := 0 to 149 do
  begin

    Dizi[i] := 0;
  end;

  Zamanlayici.Olustur(30);
  Zamanlayici.Baslat;

  while True do
  begin

    Gorev.OlayBekle(Olay);
    if(Olay.Olay = CO_ZAMANLAYICI) then
    begin

      for i := 2 to 149 do
      begin

        Dizi[i - 1] := Dizi[i];
      end;

      Randomize;
      Dizi[149] := Random(50);

      Pencere.Ciz;
    end
    else if(Olay.Olay = CO_CIZIM) then
    begin

      for i := 1 to 149 do
      begin

        Pencere.Tuval.Cizgi(i - 1, 50 - Dizi[i - 1], i, 50 - Dizi[i],
          ctDuz, RENK_BEYAZ);
      end;
    end;
  end;
end.
