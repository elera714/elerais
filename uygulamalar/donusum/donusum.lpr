program donusum;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: donusum.lpr
  Program Ýþlevi: sayýsal deðer çevrim / dönüþüm programý

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, gn_dugme, gn_giriskutusu, gn_etiket, gn_durumcubugu;

const
  ProgramAdi: string = 'Sayýsal Deðer Çevrimi';

var
  Gorev: TGorev;
  Pencere: TPencere;
  Olay: TOlay;
  gkAdres: TGirisKutusu;
  Sayi, Sonuc: TISayi4;
  Hata: Boolean;
  s: string;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 15, 15, 285, 140, ptIletisim, ProgramAdi, $CDF0DB);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Hata := True;

  gkAdres.Olustur(Pencere.Kimlik, 80, 22, 120, 22, '');
  gkAdres.SadeceRakam := True;
  gkAdres.Goster;

  Pencere.Gorunum := True;

  while True do
  begin

    Gorev.OlayBekle(Olay);
    if(Olay.Olay = CO_TUSBASILDI) then
    begin

      s := gkAdres.IcerikAl;
      if(Length(s) > 0) then
      begin

        Val(s, Sayi, Sonuc);
        Hata := Sonuc <> 0;
      end else Hata := True;

      Pencere.Ciz;
    end
    else if(Olay.Olay = CO_CIZIM) then
    begin

      Pencere.Tuval.KalemRengi := RENK_SIYAH;
      Pencere.Tuval.YaziYaz(62, 04, 'Deðer - 10lu Sistem');
      Pencere.Tuval.YaziYaz(62, 50, 'Deðer - 16lý Sistem');
      Pencere.Tuval.YaziYaz(62, 90, 'Deðer - 2li Sistem');

      Pencere.Tuval.KalemRengi := RENK_KIRMIZI;
      if not(Hata) then
      begin

        Pencere.Tuval.YaziYaz(100, 70, HexStr(Sayi, 8));
        Pencere.Tuval.YaziYaz(10, 110, BinStr(Sayi, 32));
      end
      else
      begin

        Pencere.Tuval.YaziYaz(130, 070, '-');
        Pencere.Tuval.YaziYaz(130, 110, '-');
      end;
    end;
  end;
end.
