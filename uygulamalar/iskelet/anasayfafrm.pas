{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: anasayfafrm.pas
  Program Ýþlevi: program ana sayfasý

  Güncelleme Tarihi: 06/01/2025

 ==============================================================================}
{$mode objfpc}
unit anasayfafrm;

interface

uses gn_pencere, n_gorev, gn_dugme, islemfrm, onayfrm;

type
  TForm = object
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
  frmAnaSayfa: TForm;

implementation

const
  PencereAdi: string = 'Tüm Ýþlemler';

procedure TForm.Olustur;
begin

  TiklamaSayisi := 0;

  Pencere.Olustur(-1, 100, 100, 400, 400, ptBoyutlanabilir, PencereAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Dugme2.Olustur(Pencere.Kimlik, 50, 10, 300, 100, 'Sistem Ýþlemleri');

//  SistemMesaj.YaziEkle('iskelet -> frmAnaSayfa oluþturuldu...');
end;

procedure TForm.Goster;
begin

  Dugme2.Goster;

  Pencere.Gorunum := True;
end;

function TForm.OlaylariIsle: TISayi4;
begin

  while True do
  begin

    Gorev.OlayBekle(Olay);
    if(Olay.Olay = FO_TIKLAMA) then
    begin

      if(Olay.Kimlik = Dugme2.Kimlik) then
        frmIslem.Goster
      else
      begin

        Inc(TiklamaSayisi);
        Pencere.Ciz;

        if(frmIslem.OlaylariIsle(Olay) = -1) then
          frmOnay.OlaylariIsle(Olay);
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
