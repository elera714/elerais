{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, _forms, gn_giriskutusu;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGorev: TGorev;
    FPencere: TPencere;
    FgkAdres: TGirisKutusu;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Sayýsal Deðer Çevrimi';

var
  Sayi, Sonuc: TISayi4;
  Hata: Boolean;
  s: string;

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 15, 15, 285, 140, ptIletisim, PencereAdi, $CDF0DB);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  Hata := True;

  FgkAdres.Olustur(FPencere.Kimlik, 80, 22, 120, 22, '');
  FgkAdres.SadeceRakam := True;
  FgkAdres.Goster;
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = CO_TUSBASILDI) then
  begin

    s := FgkAdres.IcerikAl;
    if(Length(s) > 0) then
    begin

      Val(s, Sayi, Sonuc);
      Hata := Sonuc <> 0;
    end else Hata := True;

    FPencere.Ciz;
  end
  else if(AOlay.Olay = CO_CIZIM) then
  begin

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(62, 04, 'Deðer - 10lu Sistem');
    FPencere.Tuval.YaziYaz(62, 50, 'Deðer - 16lý Sistem');
    FPencere.Tuval.YaziYaz(62, 90, 'Deðer - 2li Sistem');

    FPencere.Tuval.KalemRengi := RENK_KIRMIZI;
    if not(Hata) then
    begin

      FPencere.Tuval.YaziYaz(100, 70, HexStr(Sayi, 8));
      FPencere.Tuval.YaziYaz(10, 110, BinStr(Sayi, 32));
    end
    else
    begin

      FPencere.Tuval.YaziYaz(130, 070, '-');
      FPencere.Tuval.YaziYaz(130, 110, '-');
    end;
  end;

  Result := 1;
end;

end.
