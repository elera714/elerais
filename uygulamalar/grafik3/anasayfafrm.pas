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
  GorevSonlandir: Boolean;

implementation

const
  PencereAdi: string = 'Grafik-3';

  RenkListesi: array[0..15] of TRenk = (
      $FFFFFF, $C0C0C0, $808080, $000000,
      $FF0000, $800000, $FFFF00, $808000,
      $00FF00, $008000, $00FFFF, $008080,
      $0000FF, $000080, $FF00FF, $800080);

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 50, 50, 400, 300, ptIletisim, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  GorevSonlandir := False;
end;

procedure TfrmAnaSayfa.Goster;
var
  YatayDeger, DikeyDeger,
  Renk: TISayi4;
begin

  { TODO - Goster işlevinden çıkılmadığınca OlaylariIsle işlevi çalışmayacak,
    program kapanma isteklerine cevap vermeyecektir }

  FPencere.Gorunum := True;

  while GorevSonlandir = False do
  begin

    Randomize;

    YatayDeger := Random(400);
    if(YatayDeger > 400) then YatayDeger := 400;

    DikeyDeger := Random(300);
    if(DikeyDeger > 300) then DikeyDeger := 300;

    Renk := RenkListesi[Random(15)];

    FPencere.Tuval.PixelYaz(YatayDeger, DikeyDeger, Renk);
  end;

  FGorev.Sonlandir(-1);
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = CO_SONLANDIR) then GorevSonlandir := True;

  Result := 1;
end;

end.
