{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, gn_etiket, gn_giriskutusu, gn_dugme, n_ekran, _forms;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGorev: TGorev;
    FPencere: TPencere;
    FEtiket: TEtiket;
    FGirisKutusu: TGirisKutusu;
    FCalistir: TDugme;
    FEkran: TEkran;
    procedure ProgramCalistir;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Program �al��t�r';

procedure TfrmAnaSayfa.Olustur;
begin

  // ekran ��z�n�rl���n� al
  FEkran.CozunurlukAl;

  // (G�rev �ubu�u Y�ksekli�i = 40, Pencere Y�ksekli�i = 30, Pencere Ba�l�k / Alt Y�ksekli�i = 32)
  FPencere.Olustur(-1, 0, FEkran.Yukseklik - (40 + 30 + 32), 365, 30, ptIletisim, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FEtiket.Olustur(FPencere.Kimlik, 4, 7, 80, 16, RENK_SIYAH, 'Dosya Ad�:');
  FEtiket.Goster;

  FGirisKutusu.Olustur(FPencere.Kimlik, 85, 5, 200, 20, '');
  FGirisKutusu.Goster;

  FCalistir.Olustur(FPencere.Kimlik, 290, 5, 70, 20, '�al��t�r');
  FCalistir.Goster;
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = FO_TIKLAMA) then

    ProgramCalistir

  else if(AOlay.Olay = CO_TUSBASILDI) then

    if(AOlay.Deger1 = 10) then ProgramCalistir;

  Result := 1;
end;

procedure TfrmAnaSayfa.ProgramCalistir;
var
  s: string;
begin

  s := FGirisKutusu.IcerikAl;
  FGorev.Calistir(s);
  FGorev.Sonlandir(-1);
end;

end.
