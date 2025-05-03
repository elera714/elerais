{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, _forms, gn_panel;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGorev: TGorev;
    FPencere: TPencere;
    FPanelListesi: array[0..8] of TPanel;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Paneller';

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 10, 10, 700, 450, ptBoyutlanabilir, PencereAdi, $EBEBE0);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FPanelListesi[0].Olustur(FPencere.Kimlik, 10, 10, 50, 50, 4, RENK_KIRMIZI,
    RENK_BEYAZ, RENK_SIYAH, 'Panel1');
  FPanelListesi[0].Hizala(hzUst);
  FPanelListesi[0].Goster;

  FPanelListesi[1].Olustur(FPencere.Kimlik, 150, 10, 50, 50, 4, RENK_KIRMIZI,
    RENK_BEYAZ, RENK_SIYAH, 'Panel2');
  FPanelListesi[1].Hizala(hzAlt);
  FPanelListesi[1].Goster;

  FPanelListesi[2].Olustur(FPencere.Kimlik, 290, 10, 50, 50, 4, RENK_MAVI,
    RENK_BEYAZ, RENK_SIYAH, 'Panel3');
  FPanelListesi[2].Hizala(hzSol);
  FPanelListesi[2].Goster;

  FPanelListesi[3].Olustur(FPencere.Kimlik, 10, 150, 50, 50, 4, RENK_MAVI,
    RENK_BEYAZ, RENK_SIYAH, 'Panel4');
  FPanelListesi[3].Hizala(hzSag);
  FPanelListesi[3].Goster;

  FPanelListesi[4].Olustur(FPencere.Kimlik, 150, 150, 50, 50, 4, RENK_YESIL,
    RENK_BEYAZ, RENK_SIYAH, 'Panel5');
  FPanelListesi[4].Hizala(hzSol);
  FPanelListesi[4].Goster;

  FPanelListesi[5].Olustur(FPencere.Kimlik, 290, 150, 50, 50, 4, RENK_YESIL,
    RENK_BEYAZ, RENK_SIYAH, 'Panel6');
  FPanelListesi[5].Hizala(hzSag);
  FPanelListesi[5].Goster;

  FPanelListesi[6].Olustur(FPencere.Kimlik, 10, 290, 50, 50, 4, RENK_BORDO,
    RENK_BEYAZ, RENK_SIYAH, 'Panel7');
  FPanelListesi[6].Hizala(hzUst);
  FPanelListesi[6].Goster;

  FPanelListesi[7].Olustur(FPencere.Kimlik, 150, 290, 50, 50, 4, RENK_BORDO,
    RENK_BEYAZ, RENK_SIYAH, 'Panel8');
  FPanelListesi[7].Hizala(hzAlt);
  FPanelListesi[7].Goster;

  FPanelListesi[8].Olustur(FPencere.Kimlik, 290, 290, 50, 50, 4, RENK_PEMBE,
    RENK_SARI, RENK_SIYAH, 'Panel9');
  FPanelListesi[8].Hizala(hzTum);
  FPanelListesi[8].Goster;
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;
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
  else if(AOlay.Olay = CO_CIZIM) then
  begin

  end;

  Result := 1;
end;

end.
