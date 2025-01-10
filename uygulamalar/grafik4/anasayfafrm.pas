{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_zamanlayici, _forms;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGorev: TGorev;
    FPencere: TPencere;
    FZamanlayici: TZamanlayici;
    procedure NoktalariCiz(AIlk, ASon: TSayi4; ARenk: TRenk);
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

type
  TNoktaKayit = record
    Sol, Ust,
    YatayDeger, DikeyDeger: TISayi4;
  end;

const
  PencereAdi: string = 'Grafik-4';

  USTDEGER_NOKTASAYISI = 28;

var
  Noktalar: array[0..USTDEGER_NOKTASAYISI - 1] of TNoktaKayit;
  Sol, Ust, i, j: TISayi4;

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 50, 50, 500, 400, ptIletisim, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;

  // ilk deðer atamalarý
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

  FZamanlayici.Olustur(30);
  FZamanlayici.Baslat;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = CO_ZAMANLAYICI) then
  begin

    for i := 0 to USTDEGER_NOKTASAYISI - 1 do
    begin

      // noktanýn yatay sýnýr kontrolü
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

      // noktanýn dikey sýnýr kontrolü
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

    FPencere.Ciz;
  end
  else if(AOlay.Olay = CO_CIZIM) then
  begin

    // yeni nokta koordinatlarýný çiz
    NoktalariCiz(00, 04, RENK_KIRMIZI);
    NoktalariCiz(04, 08, RENK_YESIL);
    NoktalariCiz(08, 12, RENK_SIYAH);
    NoktalariCiz(12, 16, RENK_MAVI);
    NoktalariCiz(16, 20, RENK_PEMBE);
    NoktalariCiz(20, 24, RENK_LACIVERT);
    NoktalariCiz(24, 28, RENK_BORDO);
  end;

  Result := 1;
end;

procedure TfrmAnaSayfa.NoktalariCiz(AIlk, ASon: TSayi4; ARenk: TRenk);
var
  i: TISayi4;
begin

  for i := AIlk to ASon - 1 do
  begin

    if(i = ASon - 1) then
      FPencere.Tuval.Cizgi(Noktalar[i].Sol, Noktalar[i].Ust,
        Noktalar[AIlk].Sol, Noktalar[AIlk].Ust, ctNokta, ARenk)
    else FPencere.Tuval.Cizgi(Noktalar[i].Sol, Noktalar[i].Ust,
      Noktalar[i + 1].Sol, Noktalar[i + 1].Ust, ctNokta, ARenk);
  end;
end;

end.
