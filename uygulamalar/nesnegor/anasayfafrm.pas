{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_zamanlayici, _forms;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGorev: TGorev;
    FPencere: TPencere;
    FZamanlayici: TZamanlayici;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Nesne Görüntüleyici';

var
  FarePozisyonu: TNokta;
  GorselNesneKimlik: TKimlik;
  NesneAdi: string[40];

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 110, 110, 250, 130, ptBoyutlanabilir, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;

  FZamanlayici.Olustur(50);
  FZamanlayici.Baslat;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  // çekirdek tarafýndan gönderilen programýn kendisini sonlandýrma talimatý
  if(AOlay.Olay = CO_SONLANDIR) then
  begin

    FGorev.Sonlandir(-1);
  end
  else if(AOlay.Olay = FO_TIKLAMA) then
  begin

  end
  else if(AOlay.Olay = CO_ZAMANLAYICI) then
  begin

    FPencere.Ciz;
  end
  else if(AOlay.Olay = CO_CIZIM) then
  begin

    FZamanlayici.Durdur;

    FarePozisyonu := FGorev.FarePozisyonunuAl;

    GorselNesneKimlik := FGorev.GorselNesneKimlikAl(FarePozisyonu);
    FGorev.GorselNesneAdiAl(FarePozisyonu, @NesneAdi[0]);

    FPencere.Tuval.KalemRengi := RENK_KIRMIZI;
    FPencere.Tuval.FircaRengi := RENK_KIRMIZI;
    FPencere.Tuval.YaziYaz(18, 20, 'Nesne Adý: ');
    FPencere.Tuval.YaziYaz(106, 20, NesneAdi);
    FPencere.Tuval.YaziYaz(18, 36, 'Kimlik   : ');
    FPencere.Tuval.SayiYaz10(106, 36, GorselNesneKimlik);

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.FircaRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(18, 52, 'Yatay    : ');
    FPencere.Tuval.SayiYaz10(106, 52, FarePozisyonu.A1);
    FPencere.Tuval.YaziYaz(18, 68, 'Dikey    : ');
    FPencere.Tuval.SayiYaz10(106, 68, FarePozisyonu.B1);

    FZamanlayici.Baslat;
  end;

  Result := 1;
end;

end.
