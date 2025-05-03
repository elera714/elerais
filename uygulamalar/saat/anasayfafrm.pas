{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_zamanlayici, n_genel, _forms;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGenel: TGenel;
    FGorev: TGorev;
    FPencere: TPencere;
    FZamanlayici: TZamanlayici;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;
  SaatDizi: array[0..2] of TSayi1;      // saat / dakika / saniye
  TarihDizi: array[0..3] of TSayi2;     // gün / ay / yýl / haftanýn günü
  s: string;

implementation

const
  PencereAdi: string = 'Tarih / Saat';

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 200, 200, 160, 52, ptIletisim, PencereAdi, $E3F5AB);
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

  // çekirdek tarafýndan gönderilen programýn kendisini sonlandýrma talimatý
  if(AOlay.Olay = CO_SONLANDIR) then
  begin

    FGorev.Sonlandir(-1);
  end
  else if(AOlay.Olay = CO_ZAMANLAYICI) then
  begin

    FPencere.Ciz;
  end
  else if(AOlay.Olay = CO_CIZIM) then
  begin

    FPencere.Tuval.KalemRengi := $041F2F;

    FGenel.SaatAl(@SaatDizi);
    s := TimeToStr(SaatDizi);
    FPencere.Tuval.YaziYaz(46, 8, s);

    FGenel.TarihAl(@TarihDizi);
    s := DateToStr(TarihDizi, True);
    FPencere.Tuval.YaziYaz(22, 28, s);
  end;

  Result := 1;
end;

end.
