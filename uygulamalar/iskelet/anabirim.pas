{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: anabirim.pas
  Program Ýþlevi: ana programýn ana birimi

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
unit anabirim;

interface

uses gn_pencere, n_gorev, gn_dugme, birim2, birim3;

type
  TPencere1 = object
  public
    Gorev: TGorev;
    Pencere: TPencere;
    Dugme2: TDugme;
//    SistemMesaj: TSistemMesaj;
    Olay: TOlay;
    TiklamaSayisi: TSayi4;
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle: TISayi4;
  end;

var
  Pencere1: TPencere1;

implementation

const
  PencereAdi: string = 'Tüm Ýþlemler';

procedure TPencere1.Olustur;
begin

  TiklamaSayisi := 0;

  Pencere.Olustur(-1, 100, 100, 400, 400, ptBoyutlanabilir, PencereAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Dugme2.Olustur(Pencere.Kimlik, 50, 10, 300, 100, 'Sistem Ýþlemleri');

//  SistemMesaj.YaziEkle('iskelet -> Pencere1 oluþturuldu...');
end;

procedure TPencere1.Goster;
begin

  Dugme2.Goster;

  Pencere.Gorunum := True;
end;

function TPencere1.OlaylariIsle: TISayi4;
begin

  while True do
  begin

    Gorev.OlayBekle(Olay);
    if(Olay.Olay = FO_TIKLAMA) then
    begin

      if(Olay.Kimlik = Dugme2.Kimlik) then
        Pencere2.Goster
      else
      begin

        Inc(TiklamaSayisi);
        Pencere.Ciz;

        if(Pencere2.OlaylariIsle(Olay) = -1) then
          Pencere3.OlaylariIsle(Olay);
      end;
    end

    else if(Olay.Olay = CO_CIZIM) then
    begin

      Pencere.Tuval.KalemRengi := RENK_SIYAH;
      Pencere.Tuval.YaziYaz(50, 20, '');
//      Pencere.Tuval.SayiYaz10(17 * 8, 10, TiklamaSayisi);
    end;
  end;

  Result := -1;
end;

end.
