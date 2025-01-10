{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: anasayfafrm.pas
  Program Ýþlevi: program ana sayfasý

  Güncelleme Tarihi: 10/01/2025

 ==============================================================================}
{$mode objfpc}
unit anasayfafrm;

interface

uses gn_pencere, n_gorev, gn_dugme, islemfrm, onayfrm, _forms;

type
  TfrmAnaSayfa = object(TForm)
  public
    Gorev: TGorev;
    Pencere: TPencere;
    Dugme2: TDugme;
//    SistemMesaj: TSistemMesaj;
    TiklamaSayisi: TSayi4;
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Tüm Ýþlemler';

procedure TfrmAnaSayfa.Olustur;
begin

  TiklamaSayisi := 0;

  Pencere.Olustur(-1, 100, 100, 400, 400, ptBoyutlanabilir, PencereAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Dugme2.Olustur(Pencere.Kimlik, 50, 10, 300, 100, 'Sistem Ýþlemleri');

//  SistemMesaj.YaziEkle('iskelet -> frmAnaSayfa oluþturuldu...');
end;

procedure TfrmAnaSayfa.Goster;
begin

  Dugme2.Goster;

  Pencere.Gorunum := True;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = FO_TIKLAMA) then
  begin

    if(AOlay.Kimlik = Dugme2.Kimlik) then
      frmIslem.Goster
    else
    begin

      Inc(TiklamaSayisi);
      Pencere.Ciz;

      if(frmIslem.OlaylariIsle(AOlay) = -1) then
        frmOnay.OlaylariIsle(AOlay);
    end;
  end

  else if(AOlay.Olay = CO_CIZIM) then
  begin

    Pencere.Tuval.KalemRengi := RENK_SIYAH;
    Pencere.Tuval.YaziYaz(50, 20, '');
//      Pencere.Tuval.SayiYaz10(17 * 8, 10, TiklamaSayisi);
  end;

  Result := 1;
end;

end.
