program paneller;
{==============================================================================

  Kodlayan:
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Program Adı: paneller.lpr
  Program İşlevi: panel test programı

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, gn_panel;

const
  ProgramAdi: string = 'Paneller';

var
  Gorev: TGorev;
  Pencere: TPencere;
  Olay: TOlay;
  PanelListesi: array[0..8] of TPanel;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 10, 10, 700, 450, ptBoyutlanabilir, ProgramAdi, $EBEBE0);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  PanelListesi[0].Olustur(Pencere.Kimlik, 10, 10, 50, 50, 4, RENK_KIRMIZI,
    RENK_BEYAZ, RENK_SIYAH, 'Panel1');
  PanelListesi[0].Hizala(hzUst);
  PanelListesi[0].Goster;

  PanelListesi[1].Olustur(Pencere.Kimlik, 150, 10, 50, 50, 4, RENK_KIRMIZI,
    RENK_BEYAZ, RENK_SIYAH, 'Panel2');
  PanelListesi[1].Hizala(hzAlt);
  PanelListesi[1].Goster;

  PanelListesi[2].Olustur(Pencere.Kimlik, 290, 10, 50, 50, 4, RENK_MAVI,
    RENK_BEYAZ, RENK_SIYAH, 'Panel3');
  PanelListesi[2].Hizala(hzSol);
  PanelListesi[2].Goster;

  PanelListesi[3].Olustur(Pencere.Kimlik, 10, 150, 50, 50, 4, RENK_MAVI,
    RENK_BEYAZ, RENK_SIYAH, 'Panel4');
  PanelListesi[3].Hizala(hzSag);
  PanelListesi[3].Goster;

  PanelListesi[4].Olustur(Pencere.Kimlik, 150, 150, 50, 50, 4, RENK_YESIL,
    RENK_BEYAZ, RENK_SIYAH, 'Panel5');
  PanelListesi[4].Hizala(hzSol);
  PanelListesi[4].Goster;

  PanelListesi[5].Olustur(Pencere.Kimlik, 290, 150, 50, 50, 4, RENK_YESIL,
    RENK_BEYAZ, RENK_SIYAH, 'Panel6');
  PanelListesi[5].Hizala(hzSag);
  PanelListesi[5].Goster;

  PanelListesi[6].Olustur(Pencere.Kimlik, 10, 290, 50, 50, 4, RENK_BORDO,
    RENK_BEYAZ, RENK_SIYAH, 'Panel7');
  PanelListesi[6].Hizala(hzUst);
  PanelListesi[6].Goster;

  PanelListesi[7].Olustur(Pencere.Kimlik, 150, 290, 50, 50, 4, RENK_BORDO,
    RENK_BEYAZ, RENK_SIYAH, 'Panel8');
  PanelListesi[7].Hizala(hzAlt);
  PanelListesi[7].Goster;

  PanelListesi[8].Olustur(Pencere.Kimlik, 290, 290, 50, 50, 4, RENK_PEMBE,
    RENK_SARI, RENK_SIYAH, 'Panel9');
  PanelListesi[8].Hizala(hzTum);
  PanelListesi[8].Goster;

  Pencere.Gorunum := True;

  while True do
  begin

    Gorev.OlayBekle(Olay);
    if(Olay.Olay = FO_TIKLAMA) then
    begin

    end
    else if(Olay.Olay = CO_CIZIM) then
    begin

    end;
  end;
end.
