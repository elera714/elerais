{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, _forms, gn_resimdugmesi;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGorev: TGorev;
    FPencere: TPencere;
    FrdDugmeler: array[0..15] of TResimDugmesi;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Düðmeler';

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
  Sol, Ust, i: TISayi4;

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 200, 200, 128, 128, ptIletisim, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  Sol := 4;
  Ust := 4;
  for i := 1 to 16 do
  begin

    //rdDugmeler[i - 1].Olustur(Pencere.Kimlik, Sol, Ust, 26, 26, RenkListesi[i - 1]);
    FrdDugmeler[i - 1].Olustur(FPencere.Kimlik, Sol, Ust, 26, 26, ResimListesi[i - 1]);
    FrdDugmeler[i - 1].Goster;

    Sol += 30;
    if((i mod 4) = 0) then
    begin

      Sol := 8;
      Ust += 30;
    end;
  end;
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = FO_TIKLAMA) then
  begin

  end
  else if(AOlay.Olay = CO_CIZIM) then
  begin

  end;

  Result := 1;
end;

end.
