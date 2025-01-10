{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_zamanlayici, _forms, gn_onaykutusu;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGorev: TGorev;
    FPencere: TPencere;
    FOnayKutusu: TOnayKutusu;
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
  PencereAdi: string = 'Noktalar (300 x 300) - 0.5 saniye';

  Renkler: array[0..7] of TRenk = (
      $D2691E, $7FFF00, $00008B, $008B8B,
      $9932CC, $8FBC8F, $9400D3, $FFD700);

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 100, 100, 300, 300 + 20, ptIletisim, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FOnayKutusu.Olustur(FPencere.Kimlik, 2, 2, 'Devam Et');
  FOnayKutusu.Goster;
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;

  FZamanlayici.Olustur(50);
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = CO_ZAMANLAYICI) then

    NoktalariCiz

  else if(AOlay.Olay = CO_DURUMDEGISTI) then
  begin

    if(AOlay.Deger1 = 1) then FZamanlayici.Baslat
    else if(AOlay.Deger1 = 0) then FZamanlayici.Durdur;
  end;

  Result := 1;
end;

procedure TfrmAnaSayfa.NoktalariCiz;
var
  i, j, Yatay, Dikey: TSayi4;
begin

  for i := 0 to 89999 do
  begin

    Randomize;
    Yatay := Random(300);
    Dikey := Random(300);
    j := Random(7);
    FPencere.Tuval.PixelYaz(Yatay, Dikey + 20, Renkler[j]);
  end;
end;

end.
