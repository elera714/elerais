{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, _forms, gn_kaydirmacubugu;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGorev: TGorev;
    FPencere: TPencere;
    FdugKaydirmaCubugu: TKaydirmaCubugu;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Kaydýrma Çubuðu - Tasarým';

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 100, 100, 270, 260, ptBoyutlanabilir, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FdugKaydirmaCubugu.Olustur(FPencere.Kimlik, 30, 10, 200, 15, yYatay);
  FdugKaydirmaCubugu.DegerleriBelirle(0, 5);
  FdugKaydirmaCubugu.Goster;

  FdugKaydirmaCubugu.Olustur(FPencere.Kimlik, 30, 195, 200, 15, yYatay);
  FdugKaydirmaCubugu.DegerleriBelirle(0, 10);
  FdugKaydirmaCubugu.Goster;

  FdugKaydirmaCubugu.Olustur(FPencere.Kimlik, 10, 10, 15, 200, yDikey);
  FdugKaydirmaCubugu.DegerleriBelirle(0, 15);
  FdugKaydirmaCubugu.Goster;

  FdugKaydirmaCubugu.Olustur(FPencere.Kimlik, 235, 10, 15, 200, yDikey);
  FdugKaydirmaCubugu.DegerleriBelirle(0, 20);
  FdugKaydirmaCubugu.Goster;
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  // çekirdek tarafýndan gönderilen programýn kendisini sonlandýrma talimatý
  if(AOlay.Olay = CO_SONLANDIR) then
  begin

    FGorev.Sonlandir(-1);
  end
  else if(AOlay.Olay = FO_TIKLAMA) then
  begin

  end
  else if(AOlay.Olay = CO_CIZIM) then
  begin

  end;

  Result := 1;
end;

end.
