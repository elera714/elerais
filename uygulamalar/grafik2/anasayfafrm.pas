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
  PencereAdi: string = 'Grafik-2';

var
  Renkler: array[0..7] of TRenk = (
    $000000, $4D001F, $99003D, $E6005C,
    $FF1A75, $FF66A3, $FFB3D1, $FFE6f0);
  Renk: TRenk;
  RenkSiraNo, i: TSayi4;

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 100, 100, 200, 200, ptIletisim, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;

  FZamanlayici.Olustur(20);
  FZamanlayici.Baslat;

  i := 20;
  RenkSiraNo := 0;
  Renk := Renkler[RenkSiraNo];
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

    Inc(i);
    if(i > 99) then
    begin

      i := 20;
      Inc(RenkSiraNo);
      if(RenkSiraNo > 7) then RenkSiraNo := 0;
      Renk := Renkler[RenkSiraNo];
    end;

    FPencere.Tuval.Daire(100, 100, i, Renk, False);
  end;

  Result := 1;
end;

end.
