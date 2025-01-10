{$mode objfpc}
unit islemfrm;

interface

uses gn_pencere, n_gorev, gn_dugme, _forms;

type
  TfrmIslem = object(TForm)
  public
    FGorev: TGorev;
    FPencere: TPencere;
    FDugme1: TDugme;
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmIslem: TfrmIslem;

implementation

uses onayfrm;

const
  PencereAdi: string = 'Ýþlemler';

procedure TfrmIslem.Olustur;
begin

  FPencere.Olustur(-1, 120, 120, 300, 300, ptBoyutlanabilir, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FDugme1.Olustur(FPencere.Kimlik, 50, 135, 200, 22, 'Ýþlemleri Gerçekleþtir');

//  FSistemMesaj.YaziEkle('iskelet -> frmIslem oluþturuldu...');
end;

procedure TfrmIslem.Goster;
begin

  FDugme1.Goster;
  FPencere.Gorunum := True;
end;

function TfrmIslem.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = FO_TIKLAMA) and (AOlay.Kimlik = FDugme1.Kimlik) then
  begin

    frmOnay.Goster;
    Result := 0;
  end else Result := -1;
end;

end.
