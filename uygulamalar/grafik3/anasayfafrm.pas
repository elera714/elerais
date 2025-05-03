{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, _forms;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGorev: TGorev;
    FPencere: TPencere;
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
    YatayDeger, DikeyDeger,
    Renk: TISayi4;
  end;

const
  PencereAdi: string = 'Grafik-3';

  RenkListesi: array[0..15] of TRenk = (
      $FFFFFF, $C0C0C0, $808080, $000000,
      $FF0000, $800000, $FFFF00, $808000,
      $00FF00, $008000, $00FFFF, $008080,
      $0000FF, $000080, $FF00FF, $800080);
  USTDEGER_NOKTASAYISI = 16;

var
  Noktalar: array[0..USTDEGER_NOKTASAYISI - 1] of TNoktaKayit;
  YatayDeger, DikeyDeger, i, Renk: TISayi4;

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 50, 50, 400, 300, ptIletisim, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;

  while True do
  begin

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

      FPencere.Tuval.PixelYaz(YatayDeger, DikeyDeger, Renk);
    end;
  end;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  // çekirdek tarafýndan gönderilen programýn kendisini sonlandýrma talimatý
  if(AOlay.Olay = CO_SONLANDIR) then
  begin

    FGorev.Sonlandir(-1);
  end else Result := 1;
end;

end.
