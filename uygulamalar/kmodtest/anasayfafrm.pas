{$mode objfpc}
{$asmmode intel}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, _forms, gn_baglanti;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGorev: TGorev;
    FPencere: TPencere;
    FbagKomutIN, FbagKomutCLI,
    FbagKomutJMP, FbagKomutMOV: TBaglanti;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Korumalý Mod Test (Ring3)';

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 200, 200, 250, 130, ptIletisim, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FbagKomutIN.Olustur(FPencere.Kimlik, 18, 10, $000000, $FF0000, 'in al,$1F0');
  FbagKomutIN.Goster;
  FbagKomutCLI.Olustur(FPencere.Kimlik, 18, 30, $000000, $FF0000, 'cli');
  FbagKomutCLI.Goster;
  FbagKomutJMP.Olustur(FPencere.Kimlik, 18, 50, $000000, $FF0000, 'jmp 0x8:0');
  FbagKomutJMP.Goster;
  FbagKomutMOV.Olustur(FPencere.Kimlik, 18, 70, $000000, $FF0000, 'mov esi,[$FFFFFFFF]');
  FbagKomutMOV.Goster;
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

    if(AOlay.Kimlik = FbagKomutIN.Kimlik) then
    begin
    asm
      mov   dx,$1F0
      in    al,dx
    end;
    end
    else if(AOlay.Kimlik = FbagKomutCLI.Kimlik) then
    begin
    asm
      cli
    end;
    end
    else if(AOlay.Kimlik = FbagKomutJMP.Kimlik) then
    begin
    asm
      db  $EA
      dd  0
      dw  8
    end;
    end
    else if(AOlay.Kimlik = FbagKomutMOV.Kimlik) then
    begin
    asm
      mov   esi,[$FFFFFFFF]
    end;
    end;
  end;

  Result := 1;
end;

end.
