program dnssorgu;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: dnssorgu.lpr
  Program Ýþlevi: dns adres sorgulama programý

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}

uses n_gorev, gn_pencere, gn_etiket, gn_giriskutusu, gn_dugme, gn_defter, n_dns,
  n_zamanlayici, gn_durumcubugu;

const
  ProgramAdi: string = 'DNS Sorgu';

var
  Gorev: TGorev;
  Pencere: TPencere;
  etDNSAdi: TEtiket;
  gkDNSAdi: TGirisKutusu;
  dugSorgula: TDugme;
  defSonuc: TDefter;
  DurumCubugu: TDurumCubugu;
  Zamanlayici: TZamanlayici;
  Olay: TOlay;
  DNS: TDNS;
  DNSAdresSorgu, DNSAdresYanit: string;
  DNSDurum: TDNSDurum;
  DNSKimlik: TKimlik;
  DNSPaket: PDNSPaket;
  Veriler: array[0..1023] of TSayi1;
  SorguSayisi, YanitSayisi: TSayi2;
  DNSBolum: TSayi4;
  Veri1: PByte;
  Veri1U, i: TSayi1;
  Veri2: PSayi2;
  Veri4: PSayi4;
  IPAdres: TIPAdres;

procedure Sorgula;
begin

  DNSAdresSorgu := gkDNSAdi.IcerikAl;

  defSonuc.Temizle;
  gkDNSAdi.IcerikYaz('');

  if(DNSKimlik = -1) then DNS.Olustur;

  DNSKimlik := DNS.Kimlik;

  if not(DNSKimlik = -1) then
  begin

    if(Length(DNSAdresSorgu) = 0) then
    begin

      defSonuc.Temizle;
      defSonuc.YaziEkle('Hata: DNS adres alaný boþ...')
    end
    else
    begin

      defSonuc.Temizle;
      defSonuc.YaziEkle('Sorgulanan Adres: ' + DNSAdresSorgu + #13#10#13#10);

      DurumCubugu.DurumYazisiDegistir('Adres sorgulanýyor...');
      DNS.Sorgula(DNSAdresSorgu);
    end;
  end;
end;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  DNSAdresSorgu := 'lazarus-ide.org';

  DNSKimlik := -1;

  Pencere.Olustur(-1, 100, 100, 358, 250, ptIletisim, ProgramAdi, RENK_BEYAZ);

  DurumCubugu.Olustur(Pencere.Kimlik, 0, 0, 100, 18, 'Beklemede.');
  DurumCubugu.Goster;

  etDNSAdi.Olustur(Pencere.Kimlik, 10, 10, RENK_SIYAH, 'DNS Adres:');
  etDNSAdi.Goster;

  gkDNSAdi.Olustur(Pencere.Kimlik, 96, 7, 186, 22, DNSAdresSorgu);
  gkDNSAdi.Goster;

  dugSorgula.Olustur(Pencere.Kimlik, 286, 6, 62, 22, 'Sorgula');
  dugSorgula.Goster;

  defSonuc.Olustur(Pencere.Kimlik, 10, 32, 340, 194, $369090, RENK_BEYAZ, False);
  defSonuc.Goster;

  Pencere.Gorunum := True;

  Zamanlayici.Olustur(100);
  Zamanlayici.Baslat;

  while True do
  begin

    Gorev.OlayBekle(Olay);

    if(Olay.Olay = CO_ZAMANLAYICI) then
    begin

      if not(DNS.Kimlik = -1) then
      begin

        DNSDurum := DNS.DurumAl;
        if(DNSDurum = ddSorgulandi) then
        begin

          DNS.IcerikAl(@Veriler[0]);

          // ilk 4 byte dns yanýt verisinin uzunluðunu içerir
          DNSPaket := PDNSPaket(@Veriler[4]);

          // sorgu sayýsý ve yanýt sayýsý kontrolü
          SorguSayisi := Takas2(DNSPaket^.SorguSayisi);
          YanitSayisi := Takas2(DNSPaket^.YanitSayisi);
          //SISTEM_MESAJ_S16('SorguSayisi: ', TSayi4(SorguSayisi), 4);
          //SISTEM_MESAJ_S16('YanitSayisi: ', TSayi4(YanitSayisi), 4);

          // tek bir sorgudan farklý veya yanýtýn olmamasý durumunda çýkýþ yap
          if(SorguSayisi <> 1) or (YanitSayisi = 0) then
          begin

            DNS.Kapat;

            defSonuc.YaziEkle('Hata: adres çözümlenemiyor!');

            DurumCubugu.DurumYazisiDegistir('Beklemede.');

            Exit;
          end;

          // örnek dns adres verisi: [6]google[3]com[0]
          // bilgi: [] arasýndaki veri sayýsal byte türünde veridir.

          // dns sorgu adresinin alýnmasý
          DNSBolum := 0;        // dns adresindeki her bir bölüm
          DNSAdresYanit := '';

          Veri1 := @DNSPaket^.Veriler;
          while Veri1^ <> 0 do
          begin

            if(DNSBolum > 0) then DNSAdresYanit := DNSAdresYanit + '.';

            Veri1U := Veri1^;     // kaydýn uzunluðu
            Inc(Veri1);
            i := 0;
            while i < Veri1U do
            begin

              DNSAdresYanit := DNSAdresYanit + Char(Veri1^);
              Inc(Veri1);
              Inc(i);
              Inc(DNSBolum);
            end;
          end;
          Inc(Veri1);

          defSonuc.YaziEkle('Yanýt Bilgileri:' + #13#10);
          defSonuc.YaziEkle('DNS Adý: ' + DNSAdresYanit + #13#10);

          Veri2 := PSayi2(Veri1);
          Inc(Veri2);
          Inc(Veri2);
          Inc(Veri2);

          defSonuc.YaziEkle('Tip: ' + IntToStr(Takas2(Veri2^)) + #13#10);
          Inc(Veri2);
          defSonuc.YaziEkle('Sýnýf: ' + IntToStr(Takas2(Veri2^)) + #13#10);
          Inc(Veri2);

          Veri4 := PSayi4(Veri2);
          defSonuc.YaziEkle('Yaþam Ömrü: ' + IntToStr(Takas4(Veri4^)) + #13#10);
          Inc(Veri4);

          Veri2 := PSayi2(Veri4);
          //SISTEM_MESAJ_S16('Veri Uzunluðu: ', Takas2(Veri2^), 4);
          Inc(Veri2);

          Veri1 := PSayi1(Veri2);

          IPAdres[0] := Veri1^;
          Inc(Veri1);
          IPAdres[1] := Veri1^;
          Inc(Veri1);
          IPAdres[2] := Veri1^;
          Inc(Veri1);
          IPAdres[3] := Veri1^;

          defSonuc.YaziEkle('IP Adresi: ' + IP_KarakterKatari(IPAdres));

          DurumCubugu.DurumYazisiDegistir('Beklemede.');

          DNS.Kapat;
        end;
      end;
    end
    else if(Olay.Olay = CO_TUSBASILDI) then
    begin

      if(Olay.Deger1 = 10) then Sorgula;
    end
    else if(Olay.Olay = FO_TIKLAMA) then
    begin

      if(Olay.Kimlik = dugSorgula.Kimlik) then Sorgula;
    end;
  end;

  // program kapanýrken bu iþlev çalýþtýrýlacak. (daha zaman var, þu an deðil :D)
  DNS.YokEt;
end.
