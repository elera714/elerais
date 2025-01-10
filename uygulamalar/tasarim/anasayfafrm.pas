{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, _forms, gn_dugme;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGorev: TGorev;
    FPencere: TPencere;
    FdugSol, FdugSag, FdugUst, FdugAlt,
    FdugIlkDurum, FdugTestDugmesi: TDugme;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Nesne Tasarým - Test';

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 100, 100, 400, 400, ptBoyutlanabilir, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FdugSol.Olustur(FPencere.Kimlik, 100, 150, 45, 45, 'Sol');
  FdugSol.Goster;

  FdugUst.Olustur(FPencere.Kimlik, 150, 100, 45, 45, 'Üst');
  FdugUst.Goster;

  FdugSag.Olustur(FPencere.Kimlik, 200, 150, 45, 45, 'Sað');
  FdugSag.Goster;

  FdugAlt.Olustur(FPencere.Kimlik, 150, 200, 45, 45, 'Alt');
  FdugAlt.Goster;

  FdugIlkDurum.Olustur(FPencere.Kimlik, 150, 150, 45, 45, '');
  FdugIlkDurum.Goster;

  FdugTestDugmesi.Olustur(FPencere.Kimlik, 5, 5, 45, 45, 'Test');
  FdugTestDugmesi.Goster;
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = FO_TIKLAMA) then
  begin

    if(AOlay.Kimlik = FdugSol.Kimlik) then
    begin

      FdugTestDugmesi.Hizala(hzSol);
    end
    else if(AOlay.Kimlik = FdugUst.Kimlik) then
    begin

      FdugTestDugmesi.Hizala(hzUst);
    end
    else if(AOlay.Kimlik = FdugSag.Kimlik) then
    begin

      FdugTestDugmesi.Hizala(hzSag);
    end
    else if(AOlay.Kimlik = FdugAlt.Kimlik) then
    begin

      FdugTestDugmesi.Hizala(hzAlt);
    end
    else if(AOlay.Kimlik = FdugIlkDurum.Kimlik) then
    begin

      FdugTestDugmesi.Hizala(hzYok);
    end;
  end;

  Result := 1;
end;

end.
