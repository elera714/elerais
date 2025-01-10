{$mode objfpc}
unit onayfrm;

interface

uses gn_pencere, n_gorev, gn_dugme, gn_etiket, _forms;

type
  TfrmOnay = object(TForm)
  public
    FGorev: TGorev;
    FPencere: TPencere;
    FDugme1: TDugme;
    FEtiket1: TEtiket;
    procedure Olustur;
    procedure Goster;
    procedure Gizle;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmOnay: TfrmOnay;

implementation

const
  PencereAdi: string = 'Ýþlem Durumu';

procedure TfrmOnay.Olustur;
begin

  FPencere.Olustur(-1, 150, 150, 250, 65, ptIletisim, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FEtiket1.Olustur(FPencere.Kimlik, 4, 4, RENK_SIYAH, 'Tüm iþlemler tamamlandý...');

  FDugme1.Olustur(FPencere.Kimlik, 100, 30, 50, 22, 'Tamam');
end;

procedure TfrmOnay.Goster;
begin

  FEtiket1.Goster;
  FDugme1.Goster;
  FPencere.Gorunum := True;
end;

procedure TfrmOnay.Gizle;
begin

  //FEtiket1.Gizle;
  FDugme1.Gizle;
  FPencere.Gorunum := False;
end;

function TfrmOnay.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = FO_TIKLAMA) and (AOlay.Kimlik = FDugme1.Kimlik) then
  begin

    FPencere.Gorunum := False;
    Result := 0;
  end else Result := -1;
end;

end.
