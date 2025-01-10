{$mode objfpc}
unit anasayfafrm;

interface

uses gn_pencere, n_zamanlayici, _forms, gn_etiket, gn_giriskutusu, gn_dugme, gn_defter,
  n_dns, gn_durumcubugu, n_gorev;

type
  TfrmAnaSayfa = object(TForm)
  private
    FPencere: TPencere;
    FGorev: TGorev;
    FetDNSAdi: TEtiket;
    FgkDNSAdi: TGirisKutusu;
    FSorgula: TDugme;
    FSonuc: TDefter;
    FDurumCubugu: TDurumCubugu;
    FZamanlayici: TZamanlayici;
    procedure Sorgula;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'DNS Sorgu';

var
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

procedure TfrmAnaSayfa.Olustur;
begin

  DNSAdresSorgu := 'lazarus-ide.org';

  DNSKimlik := -1;

  FPencere.Olustur(-1, 100, 100, 358, 250, ptIletisim, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FDurumCubugu.Olustur(FPencere.Kimlik, 0, 0, 100, 18, 'Beklemede.');
  FDurumCubugu.Goster;

  FetDNSAdi.Olustur(FPencere.Kimlik, 10, 10, RENK_SIYAH, 'DNS Adres:');
  FetDNSAdi.Goster;

  FgkDNSAdi.Olustur(FPencere.Kimlik, 96, 7, 186, 22, DNSAdresSorgu);
  FgkDNSAdi.Goster;

  FSorgula.Olustur(FPencere.Kimlik, 286, 6, 62, 22, 'Sorgula');
  FSorgula.Goster;

  FSonuc.Olustur(FPencere.Kimlik, 10, 32, 340, 194, $369090, RENK_BEYAZ, False);
  FSonuc.Goster;
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;

  FZamanlayici.Olustur(100);
  FZamanlayici.Baslat;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = CO_ZAMANLAYICI) then
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

          FSonuc.YaziEkle('Hata: adres çözümlenemiyor!');

          FDurumCubugu.DurumYazisiDegistir('Beklemede.');

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

        FSonuc.YaziEkle('Yanýt Bilgileri:' + #13#10);
        FSonuc.YaziEkle('DNS Adý: ' + DNSAdresYanit + #13#10);

        Veri2 := PSayi2(Veri1);
        Inc(Veri2);
        Inc(Veri2);
        Inc(Veri2);

        FSonuc.YaziEkle('Tip: ' + IntToStr(Takas2(Veri2^)) + #13#10);
        Inc(Veri2);
        FSonuc.YaziEkle('Sýnýf: ' + IntToStr(Takas2(Veri2^)) + #13#10);
        Inc(Veri2);

        Veri4 := PSayi4(Veri2);
        FSonuc.YaziEkle('Yaþam Ömrü: ' + IntToStr(Takas4(Veri4^)) + #13#10);
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

        FSonuc.YaziEkle('IP Adresi: ' + IP_KarakterKatari(IPAdres));

        FDurumCubugu.DurumYazisiDegistir('Beklemede.');

        DNS.Kapat;
      end;
    end;
  end
  else if(AOlay.Olay = CO_TUSBASILDI) then
  begin

    if(AOlay.Deger1 = 10) then Sorgula;
  end
  else if(AOlay.Olay = FO_TIKLAMA) then
  begin

    if(AOlay.Kimlik = FSorgula.Kimlik) then Sorgula;
  end;

  // program kapanýrken bu iþlev çalýþtýrýlacak. (daha zaman var, þu an deðil :D)
  //DNS.YokEt;

  Result := 1;
end;

procedure TfrmAnaSayfa.Sorgula;
begin

  DNSAdresSorgu := FgkDNSAdi.IcerikAl;

  FSonuc.Temizle;
  FgkDNSAdi.IcerikYaz('');

  if(DNSKimlik = -1) then DNS.Olustur;

  DNSKimlik := DNS.Kimlik;

  if not(DNSKimlik = -1) then
  begin

    if(Length(DNSAdresSorgu) = 0) then
    begin

      FSonuc.Temizle;
      FSonuc.YaziEkle('Hata: DNS adres alaný boþ...')
    end
    else
    begin

      FSonuc.Temizle;
      FSonuc.YaziEkle('Sorgulanan Adres: ' + DNSAdresSorgu + #13#10#13#10);

      FDurumCubugu.DurumYazisiDegistir('Adres sorgulanýyor...');
      DNS.Sorgula(DNSAdresSorgu);
    end;
  end;
end;

end.
