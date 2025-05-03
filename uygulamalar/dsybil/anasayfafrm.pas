{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, _forms, gn_dugme;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGorev: TGorev;
    FPencere: TPencere;
    FdugKapat: TDugme;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Dosya Bilgisi';

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 100, 100, 300, 150, ptIletisim, PencereAdi, $EADEA5);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FdugKapat.Olustur(FPencere.Kimlik, 110, 100, 80, 22, 'Kapat');
  FdugKapat.Goster;
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

    if(AOlay.Kimlik = FdugKapat.Kimlik) then FGorev.Sonlandir(-1);
  end

  else if(AOlay.Olay = CO_CIZIM) then
  begin

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(8, 16, 'Dosya Yolu (Path):');
    FPencere.Tuval.YaziYaz(8, 32, '------------------');
    FPencere.Tuval.YaziYaz(8, 48, ParamStr1(1));
  end;

  Result := 1;
end;

end.
