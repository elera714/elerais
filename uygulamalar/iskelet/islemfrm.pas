{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: islemfrm.pas
  Program Ýþlevi: iþlem sayfasý

  Güncelleme Tarihi: 06/01/2025

 ==============================================================================}
{$mode objfpc}
unit islemfrm;

interface

uses gn_pencere, n_gorev, gn_dugme;

type
  TForm = object
  public
    Gorev: TGorev;
    Pencere: TPencere;
    Dugme1: TDugme;
    Olay: TOlay;
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmIslem: TForm;

implementation

uses onayfrm;

const
  PencereAdi: string = 'Ýþlemler';

procedure TForm.Olustur;
begin

  Pencere.Olustur(-1, 120, 120, 300, 300, ptBoyutlanabilir, PencereAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Dugme1.Olustur(Pencere.Kimlik, 50, 135, 200, 22, 'Ýþlemleri Gerçekleþtir');

//  SistemMesaj.YaziEkle('iskelet -> frmIslem oluþturuldu...');
end;

procedure TForm.Goster;
begin

  Dugme1.Goster;
  Pencere.Gorunum := True;
end;

function TForm.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = FO_TIKLAMA) and (AOlay.Kimlik = Dugme1.Kimlik) then
  begin

    frmOnay.Goster;
    Result := 0;
  end else Result := -1;
end;

end.
