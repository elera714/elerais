program iletisim;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: iletisim.lpr
  Program Ýþlevi: tcp / udp test programý

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, gn_dugme, gn_giriskutusu, gn_durumcubugu, gn_karmaliste,
  n_zamanlayici, n_iletisim, gn_defter;

const
  ProgramAdi: string = 'Ýletiþim - TCP/UDP';

var
  Gorev: TGorev;
  Pencere: TPencere;
  Defter: TDefter;
  DurumCubugu: TDurumCubugu;
  Zamanlayici: TZamanlayici;
  gkMesaj: TGirisKutusu;
  klBaglanti: TKarmaListe;
  dugBaglan, dugGonder, dugBKes: TDugme;
  Olay: TOlay;
  Iletisim0: TIletisim;
  IPAdres, s: string;
  VeriUzunlugu: TISayi4;
begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 50, 50, 434, 260, ptIletisim, ProgramAdi, $D9F2E6);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Pencere.Tuval.KalemRengi := $000000;
  Pencere.Tuval.YaziYaz(342, 10, 'Baðlantý');

  klBaglanti.Olustur(Pencere.Kimlik, 338, 30, 84, 22);
  klBaglanti.ElemanEkle('TCP');
  klBaglanti.ElemanEkle('UDP');
  klBaglanti.Goster;

  Pencere.Tuval.YaziYaz(10, 10, 'IP Adres: 193.1.1.11, Port: 365');

  dugBaglan.Olustur(Pencere.Kimlik, 268, 6, 55, 22, 'Baðlan');
  dugBaglan.Goster;

  Pencere.Tuval.YaziYaz(10, 34, 'Mesaj:');

  gkMesaj.Olustur(Pencere.Kimlik, 66, 30, 180, 22, 'Mesaj');
  gkMesaj.Goster;

  dugGonder.Olustur(Pencere.Kimlik, 268, 30, 55, 22, 'Gönder');
  dugGonder.Goster;

  dugBKes.Olustur(Pencere.Kimlik, 268, 54, 55, 22, 'B.Kes');
  dugBKes.Goster;

  Pencere.Tuval.YaziYaz(10, 66, 'Haberleþme:');

  DurumCubugu.Olustur(Pencere.Kimlik, 0, 0, 100, 20, 'Baðlantý yok!');
  DurumCubugu.Goster;

  Defter.Olustur(Pencere.Kimlik, 10, 85, 410, 150, RENK_BEYAZ, RENK_SIYAH, False);
  //Defter.Hizala(hzTum);
  Defter.Goster;

  Pencere.Gorunum := True;

  Zamanlayici.Olustur(100);
  Zamanlayici.Baslat;

  IPAdres := '193.1.1.11';

  while True do
  begin

    Gorev.OlayBekle(Olay);

    if(Olay.Olay = CO_ZAMANLAYICI) then
    begin

      if(Iletisim0.BagliMi) then
      begin

        DurumCubugu.DurumYazisiDegistir('Baðlantý kuruldu.');

        VeriUzunlugu := Iletisim0.VeriUzunluguAl;
        if(VeriUzunlugu > 0) then
        begin

          VeriUzunlugu := Iletisim0.VeriOku(@s[1]);
          SetLength(s, VeriUzunlugu);

          Defter.YaziEkle('O: ' + s + #13#10);

          //Pencere.Ciz;
        end;
      end else DurumCubugu.DurumYazisiDegistir('Baðlantý yok!');
    end
    else if(Olay.Olay = FO_TIKLAMA) then
    begin

      if(Olay.Kimlik = dugBaglan.Kimlik) then
      begin

        s := klBaglanti.SeciliYaziAl;
        if(s = 'TCP') then
          Iletisim0.Baglan(ptTCP, IPAdres, 365)
        else Iletisim0.Baglan(ptUDP, IPAdres, 365)
      end
      else if(Olay.Kimlik = dugBKes.Kimlik) then
      begin

        Iletisim0.BaglantiyiKes;
        Defter.Temizle;
        Pencere.Ciz;
      end
      else if(Olay.Kimlik = dugGonder.Kimlik) then
      begin

        s := gkMesaj.IcerikAl + #13#10;
        Iletisim0.VeriYaz(@s[1], Length(s));

        Defter.YaziEkle('Ben: ' + s);

        gkMesaj.IcerikYaz('');
      end;
    end
    else if(Olay.Olay = CO_TUSBASILDI) then
    begin

      if(Olay.Deger1 = 10) then
      begin

        s := gkMesaj.IcerikAl + #13#10;;
        Iletisim0.VeriYaz(@s[1], Length(s));

        Defter.YaziEkle('Ben: ' + s);

        gkMesaj.IcerikYaz('');
      end;
    end
    else if(Olay.Olay = CO_CIZIM) then
    begin

      Pencere.Tuval.KalemRengi := $000000;
      Pencere.Tuval.YaziYaz(342, 10, 'Baðlantý');
      Pencere.Tuval.YaziYaz(10, 10, 'IP Adres: 193.1.1.11, Port: 365');
      Pencere.Tuval.YaziYaz(10, 34, 'Mesaj:');

      Pencere.Tuval.YaziYaz(10, 66, 'Haberleþme:');
    end;
  end;

  //Iletisim0.Close;
end.
