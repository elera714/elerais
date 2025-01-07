program tarayici;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: tarayici.lpr
  Program Ýþlevi: internet tarayýcý programý

  Güncelleme Tarihi: 02/01/2025

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, gn_panel, gn_dugme, gn_giriskutusu, gn_durumcubugu,
  gn_karmaliste, n_zamanlayici, n_iletisim, gn_defter, gn_etiket;

const
  ProgramAdi: string = 'Ýnternet Tarayýcýsý';

var
  Gorev: TGorev;
  Pencere: TPencere;
  UstMesajPaneli: TPanel;
  Defter: TDefter;
  DurumCubugu: TDurumCubugu;
  etAdres: TEtiket;
  gkIPAdresi: TGirisKutusu;
  Zamanlayici: TZamanlayici;
  dugYukle: TDugme;
  Olay: TOlay;
  Iletisim0: TIletisim;
  IPAdresi, SonDurum, s: string;
  VeriUzunlugu: TSayi4;
  SayfaIstendi: Boolean;
  Veriler: array[0..4095] of TSayi1;
begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  IPAdresi := '192.168.1.1';
  SonDurum := 'Baðlantý yok!';

  Pencere.Olustur(-1, 50, 50, 600, 480, ptBoyutlanabilir, ProgramAdi, $FAF1E3);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  // üst panel
  UstMesajPaneli.Olustur(Pencere.Kimlik, 10, 10, 250, 40, 2, RENK_SIYAH, $FAF1E3, RENK_SIYAH, '');
  UstMesajPaneli.Hizala(hzUst);

  etAdres.Olustur(UstMesajPaneli.Kimlik, 4, 12, RENK_SIYAH, 'Adres');
  etAdres.Goster;

  gkIPAdresi.Olustur(UstMesajPaneli.Kimlik, 50, 9, 456, 22, IPAdresi);
  gkIPAdresi.Goster;

  dugYukle.Olustur(UstMesajPaneli.Kimlik, 520, 7, 55, 22, 'Yükle');
  dugYukle.Goster;

  UstMesajPaneli.Goster;

  DurumCubugu.Olustur(Pencere.Kimlik, 0, 0, 100, 20, SonDurum);
  DurumCubugu.Goster;

  Defter.Olustur(Pencere.Kimlik, 5, 34, 583, 421, RENK_BEYAZ, RENK_SIYAH, True);
  Defter.Hizala(hzTum);
  Defter.Goster;

  Pencere.Gorunum := True;

  Zamanlayici.Olustur(100);
  Zamanlayici.Baslat;

  SayfaIstendi := False;

  Iletisim0.Constructor0;

  while True do
  begin

    Gorev.OlayBekle(Olay);

    if(Olay.Olay = CO_ZAMANLAYICI) then
    begin

      SonDurum := 'Baðlantý yok!';

      if(Iletisim0.Kimlik <> HATA_KIMLIK) then
      begin

        if(Iletisim0.BagliMi) then
        begin

          SonDurum := 'Baðlantý kuruldu.';

          if not(SayfaIstendi) then
          begin

            SonDurum := 'Sayfa bekleniyor...';

            s := 'GET / HTTP/1.1' + #13#10;
            s += 'Host: ' + IPAdresi + #13#10#13#10;

            Iletisim0.VeriYaz(@s[1], Length(s));

            SayfaIstendi := True;
          end
          else if(SayfaIstendi) then
          begin

            VeriUzunlugu := Iletisim0.VeriUzunluguAl;
            if(VeriUzunlugu > 0) then
            begin

              VeriUzunlugu := Iletisim0.VeriOku(@Veriler[0]);
              Veriler[VeriUzunlugu] := 0;

              Defter.YaziEkle(PChar(@Veriler[0]));

              Iletisim0.BaglantiyiKes;
            end;
          end;
        end;
      end;

      DurumCubugu.DurumYazisiDegistir(SonDurum);
    end
    else if(Olay.Olay = FO_TIKLAMA) then
    begin

      if(Olay.Kimlik = dugYukle.Kimlik) then
      begin

        IPAdresi := gkIPAdresi.IcerikAl;

        if(Length(IPAdresi) > 0) then
        begin

          SayfaIstendi := False;

          Defter.Temizle;

          Iletisim0.Olustur(ptTCP, IPAdresi, 80);
          Iletisim0.Baglan;
        end;
      end;
    end;
  end;

  Iletisim0.Destructor0;
end.
