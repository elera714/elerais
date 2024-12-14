program tasarim;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: tasarim.lpr
  Program Ýþlevi: nesne tasarým - test programý

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, gn_dugme;

const
  ProgramAdi: string = 'Nesne Tasarým - Test';

var
  Gorev: TGorev;
  Pencere: TPencere;
  dugSol, dugSag, dugUst, dugAlt,
  dugIlkDurum, dugTestDugmesi: TDugme;
  Olay: TOlay;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 100, 100, 400, 400, ptBoyutlanabilir, ProgramAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  dugSol.Olustur(Pencere.Kimlik, 100, 150, 45, 45, 'Sol');
  dugSol.Goster;

  dugUst.Olustur(Pencere.Kimlik, 150, 100, 45, 45, 'Üst');
  dugUst.Goster;

  dugSag.Olustur(Pencere.Kimlik, 200, 150, 45, 45, 'Sað');
  dugSag.Goster;

  dugAlt.Olustur(Pencere.Kimlik, 150, 200, 45, 45, 'Alt');
  dugAlt.Goster;

  dugIlkDurum.Olustur(Pencere.Kimlik, 150, 150, 45, 45, '');
  dugIlkDurum.Goster;

  dugTestDugmesi.Olustur(Pencere.Kimlik, 5, 5, 45, 45, 'Test');
  dugTestDugmesi.Goster;

  Pencere.Gorunum := True;

  while True do
  begin

    Gorev.OlayBekle(Olay);
    if(Olay.Olay = FO_TIKLAMA) then
    begin

      if(Olay.Kimlik = dugSol.Kimlik) then
      begin

        dugTestDugmesi.Hizala(hzSol);
      end
      else if(Olay.Kimlik = dugUst.Kimlik) then
      begin

        dugTestDugmesi.Hizala(hzUst);
      end
      else if(Olay.Kimlik = dugSag.Kimlik) then
      begin

        dugTestDugmesi.Hizala(hzSag);
      end
      else if(Olay.Kimlik = dugAlt.Kimlik) then
      begin

        dugTestDugmesi.Hizala(hzAlt);
      end
      else if(Olay.Kimlik = dugIlkDurum.Kimlik) then
      begin

        dugTestDugmesi.Hizala(hzYok);
      end;
    end;
  end;
end.
