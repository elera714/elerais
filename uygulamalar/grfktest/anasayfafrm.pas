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
    procedure NoktalariCiz;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Grafik Test - 200x200';

  RenkListesi: array[0..7] of TRenk = (
    $00FF8080, $00FF6060, $00FF4040, $00FF2020,
    $00FF2020, $00FF4040, $00FF6060, $00FF8080);

var
  RenkSiraDegeri: TSayi4 = 0;
  FPSDegeri: TSayi4 = 0;
  FPSSayaci: TSayi4 = 0;

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 100, 100, 200, 200, ptIletisim, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;

  FZamanlayici.Olustur(100);
  FZamanlayici.Baslat;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

{  if(FGorev.OlayAl(AOlay) = 0) then

    NoktalariCiz

  else} if(AOlay.Olay = CO_CIZIM) then

    NoktalariCiz

  // her bir saniyede FPS deðerini kaydet ve yeniden FPS sayacýný baþlat
  else if(AOlay.Olay = CO_ZAMANLAYICI) then
  begin

    FPSDegeri := FPSSayaci;
    FPSSayaci := 0;
  end;

  Result := 1;
end;

procedure TfrmAnaSayfa.NoktalariCiz;
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

      FPencere.Tuval.PixelYaz(Sol, Ust, Renk);
    end;
  end;

  FPencere.Tuval.KalemRengi := RENK_SIYAH;
  FPencere.Tuval.Dikdortgen(0, 0, 10 * 8, 1 * 16, RENK_SIYAH, True);
  FPencere.Tuval.KalemRengi := RENK_BEYAZ;
  FPencere.Tuval.SayiYaz16(0, 0, True, 8, FPSDegeri);
  Inc(FPSSayaci);
end;

end.
