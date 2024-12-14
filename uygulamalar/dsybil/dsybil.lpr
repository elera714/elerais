program dsybil;
{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: dsybil.lpr
  Program ��levi: dosyalar hakk�nda bilgi verir

  G�ncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, gn_dugme;

const
  ProgramAdi: string = 'Dosya Bilgisi';

var
  Gorev: TGorev;
  Pencere: TPencere;
  dugKapat: TDugme;
  Olay: TOlay;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 100, 100, 300, 150, ptIletisim, ProgramAdi, $EADEA5);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  dugKapat.Olustur(Pencere.Kimlik, 110, 100, 80, 22, 'Kapat');
  dugKapat.Goster;

  Pencere.Gorunum := True;

  while True do
  begin

    Gorev.OlayBekle(Olay);
    if(Olay.Olay = FO_TIKLAMA) then
    begin

      if(Olay.Kimlik = dugKapat.Kimlik) then Gorev.Sonlandir(-1);
    end

    else if(Olay.Olay = CO_CIZIM) then
    begin

      Pencere.Tuval.KalemRengi := RENK_SIYAH;
      Pencere.Tuval.YaziYaz(8, 16, 'Dosya Yolu (Path):');
      Pencere.Tuval.YaziYaz(8, 32, '------------------');
      Pencere.Tuval.YaziYaz(8, 48, ParamStr1(1));
    end;
  end;
end.
