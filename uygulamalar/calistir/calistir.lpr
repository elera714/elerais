program calistir;
{==============================================================================

  Kodlayan:
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: calistir.lpr
  Program Ýþlevi: komut satýrýndan çalýþtýrýlabilir programlarý çalýþtýrýr

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, gn_etiket, gn_giriskutusu, gn_dugme;

const
  ProgramAdi: string = 'Program Çalýþtýr';

var
  Gorev: TGorev;
  Pencere: TPencere;
  Etiket: TEtiket;
  GirisKutusu: TGirisKutusu;
  gkCalistir: TDugme;
  Olay: TOlay;

procedure ProgramCalistir;
var
  s: string;
begin

  s := GirisKutusu.IcerikAl;
  Gorev.Calistir(s);
  Gorev.Sonlandir(-1);
end;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 100, 100, 365, 30, ptIletisim, ProgramAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Etiket.Olustur(Pencere.Kimlik, 4, 7, RENK_SIYAH, 'Dosya Adý:');
  Etiket.Goster;

  GirisKutusu.Olustur(Pencere.Kimlik, 85, 5, 200, 20, 'disk1:\');
  GirisKutusu.Goster;

  gkCalistir.Olustur(Pencere.Kimlik, 290, 5, 70, 20, 'Çalýþtýr');
  gkCalistir.Goster;

  Pencere.Gorunum := True;

  while True do
  begin

    Gorev.OlayBekle(Olay);

    if(Olay.Olay = FO_TIKLAMA) then

      ProgramCalistir

    else if(Olay.Olay = CO_TUSBASILDI) then

      if(Olay.Deger1 = 10) then ProgramCalistir;
  end;
end.
