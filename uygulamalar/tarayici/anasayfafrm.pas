{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_zamanlayici, _forms, gn_panel, gn_dugme, gn_giriskutusu,
  gn_durumcubugu, n_iletisim, gn_defter, gn_etiket, n_dns;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGorev: TGorev;
    FPencere: TPencere;
    FUstMesajPaneli: TPanel;
    FDefter: TDefter;
    FDurumCubugu: TDurumCubugu;
    FetAdres: TEtiket;
    FgkBaglantiAdresi: TGirisKutusu;
    FZamanlayici: TZamanlayici;
    FdugYukle: TDugme;
    FIletisim0: TIletisim;
    DNS: TDNS;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
    procedure SayfayiYukle;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Ýnternet Tarayýcýsý';

var
  BaglantiAdresi, IPAdresi,
  SonDurum, s: string;
  VeriUzunlugu: TSayi4;
  SayfaIstendi: Boolean;
  Veriler: array[0..4095] of TSayi1;

procedure TfrmAnaSayfa.Olustur;
begin

  BaglantiAdresi := 'www.google.com';
  SonDurum := 'Baðlantý yok!';

  FPencere.Olustur(-1, 50, 50, 600, 480, ptBoyutlanabilir, PencereAdi, $FAF1E3);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  // üst panel
  FUstMesajPaneli.Olustur(FPencere.Kimlik, 10, 10, 250, 40, 2, RENK_SIYAH, $FAF1E3, RENK_SIYAH, '');
  FUstMesajPaneli.Hizala(hzUst);

  FetAdres.Olustur(FUstMesajPaneli.Kimlik, 4, 12, RENK_SIYAH, 'Adres');
  FetAdres.Goster;

  FgkBaglantiAdresi.Olustur(FUstMesajPaneli.Kimlik, 50, 9, 456, 22, BaglantiAdresi);
  FgkBaglantiAdresi.Goster;

  FdugYukle.Olustur(FUstMesajPaneli.Kimlik, 520, 7, 55, 22, 'Yükle');
  FdugYukle.Goster;

  FUstMesajPaneli.Goster;

  FDurumCubugu.Olustur(FPencere.Kimlik, 0, 0, 100, 20, SonDurum);
  FDurumCubugu.Goster;

  FDefter.Olustur(FPencere.Kimlik, 5, 34, 583, 421, RENK_BEYAZ, RENK_SIYAH, True);
  FDefter.Hizala(hzTum);
  FDefter.Goster;
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;

  FZamanlayici.Olustur(100);
  FZamanlayici.Baslat;

  SayfaIstendi := False;

  FIletisim0.Constructor0;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = CO_ZAMANLAYICI) then
  begin

    SonDurum := 'Baðlantý yok!';

    if(FIletisim0.Kimlik <> HATA_KIMLIK) then
    begin

      if(FIletisim0.BagliMi) then
      begin

        SonDurum := 'Baðlantý kuruldu.';

        if not(SayfaIstendi) then
        begin

          SonDurum := 'Sayfa bekleniyor...';

          s := 'GET / HTTP/1.1' + #13#10;
          s += 'Host: ' + IPAdresi + #13#10#13#10;

          FIletisim0.VeriYaz(@s[1], Length(s));

          SayfaIstendi := True;
        end
        else if(SayfaIstendi) then
        begin

          VeriUzunlugu := FIletisim0.VeriUzunluguAl;
          if(VeriUzunlugu > 0) then
          begin

            VeriUzunlugu := FIletisim0.VeriOku(@Veriler[0]);
            Veriler[VeriUzunlugu] := 0;

            FDefter.YaziEkle(PChar(@Veriler[0]));

            FIletisim0.BaglantiyiKes;
          end;
        end;
      end;
    end;

    FDurumCubugu.DurumYazisiDegistir(SonDurum);
  end
  else if(AOlay.Olay = FO_TIKLAMA) and (AOlay.Kimlik = FdugYukle.Kimlik) then

    SayfayiYukle

  else if(AOlay.Olay = CO_TUSBASILDI) and (AOlay.Deger1 = 10) then

    SayfayiYukle;

  Result := 1;
end;

procedure TfrmAnaSayfa.SayfayiYukle;
begin

  BaglantiAdresi := FgkBaglantiAdresi.IcerikAl;

  if(IPAdresiGecerliMi(BaglantiAdresi)) then

    IPAdresi := BaglantiAdresi
  else
  begin

    if(Length(BaglantiAdresi) > 0) then
    begin

      DNS.Olustur;

      if not(DNS.Kimlik = -1) then
      begin

        if(DNS.Sorgula(BaglantiAdresi)) then
        begin

          DNS.IcerikAl;

          // tek bir sorgudan farklý veya yanýtýn olmamasý durumunda çýkýþ yap
          if(DNS.QDCount <> 1) or (DNS.ANCount = 0) or (DNS.RecType <> 1) or (DNS.RecClass <> 1)  then
          begin

            //FSonuc.YaziEkle('Hata: adres çözümlenemiyor!');
            //FDurumCubugu.DurumYazisiDegistir('Beklemede.');
            DNS.YokEt;
            Exit;
          end;

          IPAdresi := IP_KarakterKatari(DNS.RData);

          DNS.YokEt;
        end;
      end else IPAdresi := '0.0.0.0';
    end else IPAdresi := '0.0.0.0';
  end;

  if(IPAdresi <> '0.0.0.0') then
  begin

    SayfaIstendi := False;

    FDefter.Temizle;

    FIletisim0.Olustur(ptTCP, IPAdresi, 80);
    FIletisim0.Baglan;
  end;
end;

{ TODO - çýkýþta / iþi bittiðinde nesne bellekten atýlacak }
// FIletisim0.Destructor0;

end.
