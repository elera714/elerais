{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: islemfrm.pas
  Program ��levi: i�lem sayfas�

  G�ncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
unit islemfrm;

interface

uses gn_pencere, n_gorev, gn_dugme, _forms;

type
  TfrmIslem = object(TForm)
  public
    Gorev: TGorev;
    Pencere: TPencere;
    Dugme1: TDugme;
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmIslem: TfrmIslem;

implementation

uses onayfrm;

const
  PencereAdi: string = '��lemler';

procedure TfrmIslem.Olustur;
begin

  Pencere.Olustur(-1, 120, 120, 300, 300, ptBoyutlanabilir, PencereAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Dugme1.Olustur(Pencere.Kimlik, 50, 135, 200, 22, '��lemleri Ger�ekle�tir');

//  SistemMesaj.YaziEkle('iskelet -> frmIslem olu�turuldu...');
end;

procedure TfrmIslem.Goster;
begin

  Dugme1.Goster;
  Pencere.Gorunum := True;
end;

function TfrmIslem.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = FO_TIKLAMA) and (AOlay.Kimlik = Dugme1.Kimlik) then
  begin

    frmOnay.Goster;
    Result := 0;
  end else Result := -1;
end;

end.
