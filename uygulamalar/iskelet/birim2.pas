{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: birim2.pas
  Program Ýþlevi: 2. birim

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
unit birim2;

interface

uses gn_pencere, n_gorev, gn_dugme;

type
  TPencere2 = object
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
  Pencere2: TPencere2;

implementation

uses birim3;

const
  PencereAdi: string = 'Ýþlemler';

procedure TPencere2.Olustur;
begin

  Pencere.Olustur(-1, 120, 120, 300, 300, ptBoyutlanabilir, PencereAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Dugme1.Olustur(Pencere.Kimlik, 50, 135, 200, 22, 'Ýþlemleri Gerçekleþtir');

//  SistemMesaj.YaziEkle('iskelet -> Pencere2 oluþturuldu...');
end;

procedure TPencere2.Goster;
begin

  Dugme1.Goster;
  Pencere.Gorunum := True;
end;

function TPencere2.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = FO_TIKLAMA) and (AOlay.Kimlik = Dugme1.Kimlik) then
  begin

    Pencere3.Goster;
    Result := 0;
  end else Result := -1;
end;

end.
