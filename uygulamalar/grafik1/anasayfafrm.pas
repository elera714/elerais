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
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Grafik-1';

var
  Dizi: array[0..149] of TISayi4;
  i: TSayi4;

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 100, 100, 150, 50, ptIletisim, PencereAdi, RENK_SIYAH);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;

  for i := 0 to 149 do
  begin

    Dizi[i] := 0;
  end;

  FZamanlayici.Olustur(30);
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

    for i := 2 to 149 do
    begin

      Dizi[i - 1] := Dizi[i];
    end;

    Randomize;
    Dizi[149] := Random(50);

    FPencere.Ciz;
  end
  else if(AOlay.Olay = CO_CIZIM) then
  begin

    for i := 1 to 149 do
    begin

      FPencere.Tuval.Cizgi(i - 1, 50 - Dizi[i - 1], i, 50 - Dizi[i],
        ctDuz, RENK_BEYAZ);
    end;
  end;

  Result := 1;
end;

end.
