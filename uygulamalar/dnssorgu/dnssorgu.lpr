program dnssorgu;
{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: dnssorgu.lpr
  Program ��levi: dns adres sorgulama program�

  G�ncelleme Tarihi: 20/09/2024

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
      defSonuc.YaziEkle('Hata: DNS adres alan� bo�...')
    end
    else
    begin

      defSonuc.Temizle;
      defSonuc.YaziEkle('Sorgulanan Adres: ' + DNSAdresSorgu + #13#10#13#10);

      DurumCubugu.DurumYazisiDegistir('Adres sorgulan�yor...');
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

          // ilk 4 byte dns yan�t verisinin uzunlu�unu i�erir
          DNSPaket := PDNSPaket(@Veriler[4]);

          // sorgu say�s� ve yan�t say�s� kontrol�
          SorguSayisi := Takas2(DNSPaket^.SorguSayisi);
          YanitSayisi := Takas2(DNSPaket^.YanitSayisi);
          //SISTEM_MESAJ_S16('SorguSayisi: ', TSayi4(SorguSayisi), 4);
          //SISTEM_MESAJ_S16('YanitSayisi: ', TSayi4(YanitSayisi), 4);

          // tek bir sorgudan farkl� veya yan�t�n olmamas� durumunda ��k�� yap
          if(SorguSayisi <> 1) or (YanitSayisi = 0) then
          begin

            DNS.Kapat;

            defSonuc.YaziEkle('Hata: adres ��z�mlenemiyor!');

            DurumCubugu.DurumYazisiDegistir('Beklemede.');

            Exit;
          end;

          // �rnek dns adres verisi: [6]google[3]com[0]
          // bilgi: [] aras�ndaki veri say�sal byte t�r�nde veridir.

          // dns sorgu adresinin al�nmas�
          DNSBolum := 0;        // dns adresindeki her bir b�l�m
          DNSAdresYanit := '';

          Veri1 := @DNSPaket^.Veriler;
          while Veri1^ <> 0 do
          begin

            if(DNSBolum > 0) then DNSAdresYanit := DNSAdresYanit + '.';

            Veri1U := Veri1^;     // kayd�n uzunlu�u
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

          defSonuc.YaziEkle('Yan�t Bilgileri:' + #13#10);
          defSonuc.YaziEkle('DNS Ad�: ' + DNSAdresYanit + #13#10);

          Veri2 := PSayi2(Veri1);
          Inc(Veri2);
          Inc(Veri2);
          Inc(Veri2);

          defSonuc.YaziEkle('Tip: ' + IntToStr(Takas2(Veri2^)) + #13#10);
          Inc(Veri2);
          defSonuc.YaziEkle('S�n�f: ' + IntToStr(Takas2(Veri2^)) + #13#10);
          Inc(Veri2);

          Veri4 := PSayi4(Veri2);
          defSonuc.YaziEkle('Ya�am �mr�: ' + IntToStr(Takas4(Veri4^)) + #13#10);
          Inc(Veri4);

          Veri2 := PSayi2(Veri4);
          //SISTEM_MESAJ_S16('Veri Uzunlu�u: ', Takas2(Veri2^), 4);
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

  // program kapan�rken bu i�lev �al��t�r�lacak. (daha zaman var, �u an de�il :D)
  DNS.YokEt;
end.
