{$mode objfpc}
unit anasayfafrm;

interface

uses gn_pencere, _forms, gn_etiket, gn_giriskutusu, gn_dugme, gn_defter,
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
  DNSAdresSorgu: string;

procedure TfrmAnaSayfa.Olustur;
begin

  DNSAdresSorgu := 'lazarus-ide.org';

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
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = CO_TUSBASILDI) then
  begin

    if(AOlay.Deger1 = 10) then Sorgula;
  end
  else if(AOlay.Olay = FO_TIKLAMA) then
  begin

    if(AOlay.Kimlik = FSorgula.Kimlik) then Sorgula;
  end;

  Result := 1;
end;

procedure TfrmAnaSayfa.Sorgula;
begin

  DNSAdresSorgu := FgkDNSAdi.IcerikAl;

  FSonuc.Temizle;
  FgkDNSAdi.IcerikYaz('');

  if(Length(DNSAdresSorgu) = 0) then
  begin

    FSonuc.Temizle;
    FSonuc.YaziEkle('Hata: DNS adres alaný boþ...');
    Exit;
  end
  else
  begin

    DNS.Olustur;

    if not(DNS.Kimlik = -1) then
    begin

      FSonuc.Temizle;
      FSonuc.YaziEkle('Sorgulanan Adres: ' + DNSAdresSorgu + #13#10#13#10);

      FDurumCubugu.DurumYazisiDegistir('Adres sorgulanýyor...');

      if(DNS.Sorgula(DNSAdresSorgu)) then
      begin

        DNS.IcerikAl;

        // tek bir sorgudan farklý veya yanýtýn olmamasý durumunda çýkýþ yap
        if(DNS.QDCount <> 1) or (DNS.ANCount = 0) then
        begin

          FSonuc.YaziEkle('Hata: adres çözümlenemiyor!');
          FDurumCubugu.DurumYazisiDegistir('Beklemede.');
          DNS.YokEt;
          Exit;
        end;

        FSonuc.YaziEkle('Yanýt Bilgileri:' + #13#10);
        FSonuc.YaziEkle('DNS Adý: ' + DNS.Name + #13#10);

        FSonuc.YaziEkle('Tip: ' + IntToStr(DNS.RecType) + #13#10);
        FSonuc.YaziEkle('Sýnýf: ' + IntToStr(DNS.RecClass) + #13#10);
        FSonuc.YaziEkle('Yaþam Ömrü: ' + IntToStr(DNS.TTL) + #13#10);
        FSonuc.YaziEkle('IP Adresi: ' + IP_KarakterKatari(DNS.RData));

        FDurumCubugu.DurumYazisiDegistir('Beklemede.');
        DNS.YokEt;
      end
      else
      begin

        FSonuc.YaziEkle('Hata: adres çözümlenemiyor!');
        FDurumCubugu.DurumYazisiDegistir('Beklemede.');
        DNS.YokEt;
      end;
    end
    else
    begin

      FSonuc.YaziEkle('Hata: DNS için sorgulama yapýlamýyor!');
      FDurumCubugu.DurumYazisiDegistir('Beklemede.');
      DNS.YokEt;
    end;
  end;
end;

end.
