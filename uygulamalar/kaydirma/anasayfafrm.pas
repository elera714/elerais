{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, _forms, gn_kaydirmacubugu;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGorev: TGorev;
    FPencere: TPencere;
    FdugKaydirmaCubugu1,
    FdugKaydirmaCubugu2,
    FdugKaydirmaCubugu3,
    FdugKaydirmaCubugu4: TKaydirmaCubugu;
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

  FdugKaydirmaCubugu1.Olustur(FPencere.Kimlik, 30, 10, 200, 15, yYatay);
  FdugKaydirmaCubugu1.DegerleriBelirle(0, 5);
  FdugKaydirmaCubugu1.Goster;

  FdugKaydirmaCubugu2.Olustur(FPencere.Kimlik, 30, 195, 200, 15, yYatay);
  FdugKaydirmaCubugu2.DegerleriBelirle(0, 10);
  FdugKaydirmaCubugu2.Goster;

  FdugKaydirmaCubugu3.Olustur(FPencere.Kimlik, 10, 10, 15, 200, yDikey);
  FdugKaydirmaCubugu3.DegerleriBelirle(0, 15);
  FdugKaydirmaCubugu3.Goster;

  FdugKaydirmaCubugu4.Olustur(FPencere.Kimlik, 235, 10, 15, 200, yDikey);
  FdugKaydirmaCubugu4.DegerleriBelirle(0, 20);
  FdugKaydirmaCubugu4.Goster;
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
