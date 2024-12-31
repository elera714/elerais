program iletisim;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: iletisim.lpr
  Program Ýþlevi: tcp / udp test programý

  Güncelleme Tarihi: 31/12/2024

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, gn_panel, gn_etiket, gn_dugme, gn_onaykutusu, gn_giriskutusu,
  gn_durumcubugu, gn_karmaliste, n_zamanlayici, n_iletisim, gn_defter;

const
  ProgramAdi: string = 'Ýletiþim - TCP/UDP';

var
  Gorev: TGorev;
  Pencere: TPencere;
  UstMesajPaneli,
  AltMesajPaneli: TPanel;
  etIPAdresi, etPort, etBagTip,
  etMesaj: TEtiket;
  Defter: TDefter;
  DurumCubugu: TDurumCubugu;
  Zamanlayici: TZamanlayici;
  gkIPAdresi, gkPort,
  gkMesaj: TGirisKutusu;
  klBaglanti: TKarmaListe;
  dugGonder: TDugme;
  okBaglanti: TOnayKutusu;
  Olay: TOlay;
  Iletisim0: TIletisim;
  IPAdresi, s: string;
  PortNo, Sonuc: TSayi4;
  VeriUzunlugu: TISayi4;

procedure MesajGonder;
var
  s2: string;
begin

  s2 := gkMesaj.IcerikAl;
  if(Length(s2) > 0) then
  begin

    Iletisim0.VeriYaz(@s2[1], Length(s2));

    Defter.YaziEkle('Bu Bilgisayar: ' + s2 + #13#10);

    gkMesaj.IcerikYaz('');
  end;
end;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 50, 50, 570, 400, ptBoyutlanabilir, ProgramAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  // üst panel
  UstMesajPaneli.Olustur(Pencere.Kimlik, 10, 10, 250, 40, 2, RENK_SIYAH, $E6E6E6, RENK_SIYAH, '');
  UstMesajPaneli.Hizala(hzUst);

  etIPAdresi.Olustur(UstMesajPaneli.Kimlik, 10, 12, RENK_SIYAH, 'IP Adresi');
  etIPAdresi.Goster;

  gkIPAdresi.Olustur(UstMesajPaneli.Kimlik, 88, 10, 140, 22, '');
  gkIPAdresi.Goster;

  etPort.Olustur(UstMesajPaneli.Kimlik, 244, 12, RENK_SIYAH, 'Port');
  etPort.Goster;

  gkPort.Olustur(UstMesajPaneli.Kimlik, 280, 10, 60, 22, '0');
  gkPort.Goster;

  etBagTip.Olustur(UstMesajPaneli.Kimlik, 356, 12, RENK_SIYAH, 'Bað.Tip');
  etBagTip.Goster;

  klBaglanti.Olustur(UstMesajPaneli.Kimlik, 418, 8, 70, 22);
  klBaglanti.ElemanEkle('TCP');
  klBaglanti.ElemanEkle('UDP');
  klBaglanti.BaslikSiraNo := 1;
  klBaglanti.Goster;

  okBaglanti.Olustur(UstMesajPaneli.Kimlik, 500, 11, 'Aktif');
  okBaglanti.Goster;

  UstMesajPaneli.Goster;

  // durum göstergesi
  DurumCubugu.Olustur(Pencere.Kimlik, 0, 0, 100, 20, 'Baðlantý yok!');
  DurumCubugu.Goster;

  // alt panel
  AltMesajPaneli.Olustur(Pencere.Kimlik, 10, 10, 250, 40, 2, RENK_SIYAH, $E6E6E6, RENK_SIYAH, '');
  AltMesajPaneli.Hizala(hzAlt);

  etMesaj.Olustur(AltMesajPaneli.Kimlik, 10, 12, RENK_SIYAH, 'Mesaj');
  etMesaj.Goster;

  gkMesaj.Olustur(AltMesajPaneli.Kimlik, 56, 10, 435, 22, 'Mesaj');
  gkMesaj.Goster;

  dugGonder.Olustur(AltMesajPaneli.Kimlik, 495, 10, 60, 22, 'Gönder');
  dugGonder.Goster;

  AltMesajPaneli.Goster;

  Defter.Olustur(Pencere.Kimlik, 10, 250 + 85, 410, 150, RENK_BEYAZ, RENK_SIYAH, False);
  Defter.Hizala(hzTum);
  Defter.Goster;

  Iletisim0.Constructor0;

  Pencere.Gorunum := True;

  Zamanlayici.Olustur(100);
  Zamanlayici.Baslat;

  while True do
  begin

    Gorev.OlayBekle(Olay);

    if(Olay.Olay = CO_ZAMANLAYICI) then
    begin

      if(Iletisim0.Kimlik <> HATA_KIMLIK) then
      begin

        if(Iletisim0.BagliMi) then
        begin

          DurumCubugu.DurumYazisiDegistir('Baðlantý kuruldu.');

          VeriUzunlugu := Iletisim0.VeriUzunluguAl;
          if(VeriUzunlugu > 0) then
          begin

            VeriUzunlugu := Iletisim0.VeriOku(@s[1]);
            SetLength(s, VeriUzunlugu);

            Defter.YaziEkle('Diðer Bilgisayar: ' + s + #13#10);
          end;
        end else DurumCubugu.DurumYazisiDegistir('Baðlantý yok!');
      end else DurumCubugu.DurumYazisiDegistir('Baðlantý yok!');
    end
    else if(Olay.Kimlik = okBaglanti.Kimlik) and (Olay.Olay = CO_DURUMDEGISTI) then
    begin

      // aktif seçeneði seçildi, öyleyse baðlantý kur
      if(Olay.Deger1 = 1) then
      begin

        IPAdresi := gkIPAdresi.IcerikAl;
        s := gkPort.IcerikAl;

        Val(s, PortNo, Sonuc);
        if(Sonuc <> 0) then PortNo := 0;

        if(Length(IPAdresi) > 0) and (PortNo > 0) then
        begin

          s := klBaglanti.SeciliYaziAl;
          if(s = 'TCP') then
            Iletisim0.Olustur(ptTCP, IPAdresi, PortNo)
          else Iletisim0.Olustur(ptUDP, IPAdresi, PortNo);

          Iletisim0.Baglan;

          Defter.Temizle;
        end;
      end
      // aktif seçeneði pasifleþtirildiyse, öyleyse baðlantý kes
      else if(Olay.Deger1 = 0) then Iletisim0.BaglantiyiKes;
    end
    else if((Olay.Olay = FO_TIKLAMA) and (Olay.Kimlik = dugGonder.Kimlik)) or
      ((Olay.Olay = CO_TUSBASILDI) and (Olay.Deger1 = 10)) then
    begin

      if(Iletisim0.Kimlik <> HATA_KIMLIK) then MesajGonder;
    end;
  end;

  Iletisim0.Destructor0;
end.
