program tarayici;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: tarayici.lpr
  Program Ýþlevi: internet tarayýcý programý

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, gn_dugme, gn_giriskutusu, gn_durumcubugu, gn_karmaliste,
  n_zamanlayici, n_iletisim, gn_defter, gn_etiket;

const
  ProgramAdi: string = 'Ýnternet Tarayýcý';

var
  Gorev: TGorev;
  Pencere: TPencere;
  Defter: TDefter;
  DurumCubugu: TDurumCubugu;
  etAdres: TEtiket;
  gkAdres: TGirisKutusu;
  Zamanlayici: TZamanlayici;
  dugBaglan, dugGonder, dugBKes: TDugme;
  Olay: TOlay;
  Iletisim: TIletisim;
  IPAdres, s: string;
  VeriUzunlugu: Integer;
begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  IPAdres := '192.168.1.51';

  Pencere.Olustur(-1, 50, 50, 600, 480, ptBoyutlanabilir, ProgramAdi, $FAF1E3);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  etAdres.Olustur(Pencere.Kimlik, 5, 10, RENK_SIYAH, 'Adres');
  etAdres.Goster;

  gkAdres.Olustur(Pencere.Kimlik, 50, 6, 205, 22, IPAdres);
  gkAdres.Goster;

  dugBaglan.Olustur(Pencere.Kimlik, 268, 5, 55, 22, 'Baðlan');
  dugBaglan.Goster;

  dugGonder.Olustur(Pencere.Kimlik, 325, 5, 55, 22, 'Gönder');
  dugGonder.Goster;

  dugBKes.Olustur(Pencere.Kimlik, 382, 5, 55, 22, 'B.Kes');
  dugBKes.Goster;

  DurumCubugu.Olustur(Pencere.Kimlik, 0, 0, 100, 20, 'Baðlantý yok!');
  DurumCubugu.Goster;

  Defter.Olustur(Pencere.Kimlik, 5, 34, 583, 421, RENK_BEYAZ, RENK_SIYAH, True);
  //Defter.Hizala(hzTum);
  Defter.Goster;

  Pencere.Gorunum := True;

  Zamanlayici.Olustur(100);
  Zamanlayici.Baslat;

  while True do
  begin

    Gorev.OlayBekle(Olay);

    if(Olay.Olay = CO_ZAMANLAYICI) then
    begin

      if(Iletisim.BagliMi) then
      begin

        DurumCubugu.DurumYazisiDegistir('Baðlantý kuruldu.');

        VeriUzunlugu := Iletisim.VeriUzunluguAl;
        if(VeriUzunlugu > 0) then
        begin

          VeriUzunlugu := Iletisim.VeriOku(@s[1]);
          SetLength(s, VeriUzunlugu);

          Defter.YaziEkle(s + #13#10);

          //Pencere.Ciz;
        end;
      end else DurumCubugu.DurumYazisiDegistir('Baðlantý yok!');
    end
    else if(Olay.Olay = FO_TIKLAMA) then
    begin

      if(Olay.Kimlik = dugBaglan.Kimlik) then
      begin

        Iletisim.Baglan(ptTCP, IPAdres, 80)
      end
      else if(Olay.Kimlik = dugGonder.Kimlik) then
      begin

        IPAdres := gkAdres.IcerikAl;

        s := 'GET / HTTP/1.1' + #13#10;
        s += 'Host: ' + IPAdres + #13#10#13#10;

        Iletisim.VeriYaz(@s[1], Length(s));
      end
      else if(Olay.Kimlik = dugBKes.Kimlik) then
      begin

        Iletisim.BaglantiyiKes;
        Defter.Temizle;
        Pencere.Ciz;
      end;
    end;
  end;

  //Iletisim.Close;
end.
