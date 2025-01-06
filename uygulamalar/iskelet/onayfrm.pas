{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: onayfrm.pas
  Program ��levi: onay sayfas�

  G�ncelleme Tarihi: 06/01/2025

 ==============================================================================}
{$mode objfpc}
unit onayfrm;

interface

uses gn_pencere, n_gorev, gn_dugme, gn_etiket;

type
  TForm = object
  public
    Gorev: TGorev;
    Pencere: TPencere;
    Dugme1: TDugme;
    Etiket1: TEtiket;
    Olay: TOlay;
    procedure Olustur;
    procedure Goster;
    procedure Gizle;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmOnay: TForm;

implementation

const
  PencereAdi: string = '��lem Durumu';

procedure TForm.Olustur;
begin

  Pencere.Olustur(-1, 150, 150, 250, 65, ptIletisim, PencereAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Etiket1.Olustur(Pencere.Kimlik, 4, 4, RENK_SIYAH, 'T�m i�lemler tamamland�...');

  Dugme1.Olustur(Pencere.Kimlik, 100, 30, 50, 22, 'Tamam');
end;

procedure TForm.Goster;
begin

  Etiket1.Goster;
  Dugme1.Goster;
  Pencere.Gorunum := True;
end;

procedure TForm.Gizle;
begin

  //Etiket1.Gizle;
  Dugme1.Gizle;
  Pencere.Gorunum := False;
end;

function TForm.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = FO_TIKLAMA) and (AOlay.Kimlik = Dugme1.Kimlik) then
  begin

    Pencere.Gorunum := False;
    Result := 0;
  end else Result := -1;
end;

end.
