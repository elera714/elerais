{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: birim2.pas
  Program Ýþlevi: 3. birim

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
unit birim3;

interface

uses gn_pencere, n_gorev, gn_dugme, gn_etiket;

type
  TPencere3 = object
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
  Pencere3: TPencere3;

implementation

const
  PencereAdi: string = 'Ýþlem Durumu';

procedure TPencere3.Olustur;
begin

  Pencere.Olustur(-1, 150, 150, 250, 65, ptIletisim, PencereAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Etiket1.Olustur(Pencere.Kimlik, 4, 4, RENK_SIYAH, 'Tüm iþlemler tamamlandý...');

  Dugme1.Olustur(Pencere.Kimlik, 100, 30, 50, 22, 'Tamam');
end;

procedure TPencere3.Goster;
begin

  Etiket1.Goster;
  Dugme1.Goster;
  Pencere.Gorunum := True;
end;

procedure TPencere3.Gizle;
begin

  //Etiket1.Gizle;
  Dugme1.Gizle;
  Pencere.Gorunum := False;
end;

function TPencere3.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = FO_TIKLAMA) and (AOlay.Kimlik = Dugme1.Kimlik) then
  begin

    Pencere.Gorunum := False;
    Result := 0;
  end else Result := -1;
end;

end.
