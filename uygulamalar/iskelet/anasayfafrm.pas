{$mode objfpc}
unit anasayfafrm;

interface

uses gn_pencere, n_gorev, gn_dugme, islemfrm, onayfrm, _forms;

type
  TfrmAnaSayfa = object(TForm)
  public
    FGorev: TGorev;
    FPencere: TPencere;
    FDugme2: TDugme;
    //FSistemMesaj: TSistemMesaj;
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;
  TiklamaSayisi: TSayi4;

implementation

const
  PencereAdi: string = 'Tüm Ýþlemler';

procedure TfrmAnaSayfa.Olustur;
begin

  TiklamaSayisi := 0;

  FPencere.Olustur(-1, 100, 100, 400, 400, ptBoyutlanabilir, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FDugme2.Olustur(FPencere.Kimlik, 50, 10, 300, 100, 'Sistem Ýþlemleri');

//  FSistemMesaj.YaziEkle('iskelet -> frmAnaSayfa oluþturuldu...');
end;

procedure TfrmAnaSayfa.Goster;
begin

  FDugme2.Goster;

  FPencere.Gorunum := True;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = FO_TIKLAMA) then
  begin

    if(AOlay.Kimlik = FDugme2.Kimlik) then
      frmIslem.Goster
    else
    begin

      Inc(TiklamaSayisi);
      FPencere.Ciz;

      if(frmIslem.OlaylariIsle(AOlay) = -1) then
        frmOnay.OlaylariIsle(AOlay);
    end;
  end

  else if(AOlay.Olay = CO_CIZIM) then
  begin

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(50, 20, '');
//      FPencere.Tuval.SayiYaz10(17 * 8, 10, TiklamaSayisi);
  end;

  Result := 1;
end;

end.
