program kaydirma;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: kaydirma.lpr
  Program Ýþlevi: kaydýrma çubuðu tasarým çalýþmasý

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}

uses n_gorev, gn_pencere, gn_kaydirmacubugu;

const
  ProgramAdi: string = 'Kaydýrma Çubuðu - Tasarým';

var
  Gorev: TGorev;
  Pencere: TPencere;
  dugKaydirmaCubugu: TKaydirmaCubugu;
  Olay: TOlay;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 100, 100, 270, 260, ptBoyutlanabilir, ProgramAdi,
    RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  dugKaydirmaCubugu.Olustur(Pencere.Kimlik, 30, 10, 200, 15, yYatay);
  dugKaydirmaCubugu.DegerleriBelirle(0, 5);
  dugKaydirmaCubugu.Goster;

  dugKaydirmaCubugu.Olustur(Pencere.Kimlik, 30, 195, 200, 15, yYatay);
  dugKaydirmaCubugu.DegerleriBelirle(0, 10);
  dugKaydirmaCubugu.Goster;

  dugKaydirmaCubugu.Olustur(Pencere.Kimlik, 10, 10, 15, 200, yDikey);
  dugKaydirmaCubugu.DegerleriBelirle(0, 15);
  dugKaydirmaCubugu.Goster;

  dugKaydirmaCubugu.Olustur(Pencere.Kimlik, 235, 10, 15, 200, yDikey);
  dugKaydirmaCubugu.DegerleriBelirle(0, 20);
  dugKaydirmaCubugu.Goster;

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
