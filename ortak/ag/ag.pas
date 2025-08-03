{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: ag.pas
  Dosya Ýþlevi: að (network) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 10/05/2025

 ==============================================================================}
{$mode objfpc}
unit ag;

interface
{==============================================================================
  big endian > little endian çevrimi

  Bellek Yerleþimleri: (Örnek Sayý: $12345678)
    Big Endian:   78 56 34 12
    Litle Endian: 12 34 56 78
 ==============================================================================}
uses paylasim, aygityonetimi, baglanti;

const
  ETHERNET_BASLIKU = TSayi1(14);

var
  // paket baþlýklarý da dahil olmak üzere tüm veri toplamlarýný içerir.
  AlinanByte, GonderilenByte: TSayi4;

procedure Yukle;
procedure IlkAdresDegerleriniYukle;
function GenelAgCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
procedure AgKartiVeriAlmaIslevi;
function AgKartindanVeriAl(AHedefBellekAdresi: Isaretci): Integer;
procedure AgKartinaVeriGonder(AHedefMAC: TMACAdres; AProtokolTipi: TProtokolTipi;
  AVeri: Isaretci; AVeriUzunlugu: TSayi2);

implementation

uses src_pcnet32, arp, udp, dns, icmp, ip, sistemmesaj, donusum, islevler, genel,
  dhcp, dhcp_s, gorev, gercekbellek;

{==============================================================================
  að ilk deðer yüklemelerini gerçekleþtirir
 ==============================================================================}
procedure Yukle;
var
  Baglanti: PBaglantilar;
begin

  // sistemin çalýþtýðý bilgisayarýn alan adý - (domain name)
  {$IFDEF SISTEM_SUNUCU}
  GTamBilgisayarAdi := GBilgisayarAdi + '.' + GAlanAdi;
  IPAdresiniOtomatikAl := False;
  {$ELSE}
  GTamBilgisayarAdi := GBilgisayarAdi;
  { TOOD - True olduðunda að baðlantýsý yoksa hata veriyor }
  IPAdresiniOtomatikAl := True;
  {$ENDIF}

  // að bilgileri öndeðerlerle yükleniyor
  IlkAdresDegerleriniYukle;

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ Ethernet aygýtlarý yükleniyor...', []);
  AgAygitlariniYukle;

  // en az 1 að aygýtý yüklendi ise
  if(AgYuklendi) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ Baðlantý yapýlarý ilk deðerlerle yükleniyor...', []);
    Baglantilar0.Yukle;

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ ARP protokolü yükleniyor...', []);
    ARPKayitlar0.Yukle;

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ DNS protokolü yükleniyor...', []);
    dns.Yukle;

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ DHCP protokolü yükleniyor...', []);
    DHCPSunucu0.Yukle;

    // sistem için ip adresini yapýlandýr
    if(GAgBilgisi.IPAdresiAlindi = False) then
    begin

      if(GAgBilgisi.OtomatikIP) then

        DHCPIpAdresiAl
      else
      begin

        GAgBilgisi.IP4Adres := OnDegerIPAdresi;
        GAgBilgisi.AltAgMaskesi := OnDegerAltAgMaskesi;
        GAgBilgisi.AgGecitAdresi := IPAdres0;
        GAgBilgisi.DHCPSunucusu := IPAdres0;
        GAgBilgisi.DNSSunucusu := OnDegerIPAdresi;
        GAgBilgisi.IPKiraSuresi := 0;
        GAgBilgisi.IPAdresiAlindi := True;
      end;
    end;
  end;

  AlinanByte := 0;
  GonderilenByte := 0;
end;

{==============================================================================
  að iletiþim alanlarýný ilk deðerlerle yükler
 ==============================================================================}
procedure IlkAdresDegerleriniYukle;
begin

  GAgBilgisi.OtomatikIP := IPAdresiniOtomatikAl;
  GAgBilgisi.MACAdres := MACAdres0;
  GAgBilgisi.IP4Adres := IPAdres0;
  GAgBilgisi.AltAgMaskesi := IPAdres0;
  GAgBilgisi.AgGecitAdresi := IPAdres0;
  GAgBilgisi.DHCPSunucusu := IPAdres0;
  GAgBilgisi.DNSSunucusu := IPAdres0;
  GAgBilgisi.IPKiraSuresi := 0;
  GAgBilgisi.IPAdresiAlindi := False;
end;

{==============================================================================
  að kesme çaðrýlarýný yönetir
 ==============================================================================}
function GenelAgCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  IslevNo: TSayi4;
  AgBilgisi: PAgBilgisi;
begin

  // iþlev no
  IslevNo := (AIslevNo and $FF);

  // að ayarlarýný geri döndür
  if(IslevNo = 1) then
  begin

    AgBilgisi := Isaretci(PSayi4(ADegiskenler + 00)^ + FAktifGorevBellekAdresi);
    AgBilgisi^.MACAdres := GAgBilgisi.MACAdres;
    AgBilgisi^.IP4Adres := GAgBilgisi.IP4Adres;
    AgBilgisi^.AltAgMaskesi := GAgBilgisi.AltAgMaskesi;
    AgBilgisi^.AgGecitAdresi := GAgBilgisi.AgGecitAdresi;
    AgBilgisi^.DHCPSunucusu := GAgBilgisi.DHCPSunucusu;
    AgBilgisi^.DNSSunucusu := GAgBilgisi.DNSSunucusu;
    AgBilgisi^.IPKiraSuresi := GAgBilgisi.IPKiraSuresi;

    Result := 1;

  end else Result := HATA_ISLEV;
end;

{==============================================================================
  að kartýna (ethernet) gelen verilerin protokollere yönlendirilme iþlevi
  bilgi: bu iþlev iþletim sistemi döngüsü içinde sürekli çaðrýlýr
 ==============================================================================}
procedure AgKartiVeriAlmaIslevi;
var
  EthernetPaket: PEthernetPaket;
  ARPPaket: PARPPaket;
  Bellek: array[0..$FFF] of TSayi1;
  i, Protokol: TSayi2;
begin

  // að yüklendi ise ...
  if(AgYuklendi) then
  begin

    // að kartýna gelen ham bilgiyi al
    i := AgKartindanVeriAl(@Bellek);
    if(i > 0) then
    begin

      EthernetPaket := @Bellek[0];

      Protokol := htons(EthernetPaket^.PaketTipi);

      {SISTEM_MESAJ_MAC(mtBilgi, RENK_MAVI, 'EthernetPaket^.KaynakMACAdres: ', EthernetPaket^.KaynakMACAdres);
      SISTEM_MESAJ_MAC(mtBilgi, RENK_MAVI, 'EthernetPaket^.HedefMACAdres: ', EthernetPaket^.HedefMACAdres);
      SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'EthernetPaket^.PaketTipi: %.4x', [EthernetPaket^.PaketTipi]);}

      // ******* protokollerin iþlenmesi *******

      // ARP protokolü
      if(Protokol = PROTOKOL_ARP) then
      begin

        ARPPaket := @EthernetPaket^.Veri;
        if(IPKarsilastir(ARPPaket^.HedefIPAdres, GAgBilgisi.IP4Adres)) then
          ARPKayitlar0.ARPPaketleriniIsle(EthernetPaket)
      end

      // IP protokolü
      else if(Protokol = PROTOKOL_IP) then

        IPPaketleriniIsle(@EthernetPaket^.Veri, i - ETHERNET_BASLIKU)
      else
      begin

        // bilinmeyen protokol
        SISTEM_MESAJ(mtUyari, RENK_MAVI, 'AG.PAS: bilinmeyen protokol: $%.4x', [Protokol]);
        SISTEM_MESAJ_MAC(mtUyari, RENK_SIYAH, '  -> Kaynak MAC Adresi: ', EthernetPaket^.KaynakMACAdres);
        SISTEM_MESAJ_MAC(mtUyari, RENK_SIYAH, '  -> Hedef MAC Adresi: ', EthernetPaket^.HedefMACAdres);
      end;
    end;
  end;
end;

{==============================================================================
  að kartýna (ethernet) gelen verileri alýr
 ==============================================================================}
function AgKartindanVeriAl(AHedefBellekAdresi: Isaretci): TISayi4;
var
  Bellek: array[0..$FFF] of TSayi1;
  i: TSayi2;
begin

  // að kartýna (ethernet) gelen ham bilgiyi al
  { TODO : VeriAl iþlevi katý (hard code) olarak kodlanmýþtýr. yapýsallaþtýrýlacak }
  VeriAl(@Bellek, i);
  if(i > 0) then
  begin

    Tasi2(@Bellek[0], AHedefBellekAdresi, i);
    AlinanByte += i;
  end;

  Result := i;
end;

{==============================================================================
  að kartýna (ethernet) veri gönderir
 ==============================================================================}
procedure AgKartinaVeriGonder(AHedefMAC: TMACAdres; AProtokolTipi: TProtokolTipi;
  AVeri: Isaretci; AVeriUzunlugu: TSayi2);
var
  EthernetPaket: PEthernetPaket;
  Bellek: Isaretci;
begin

  if(AgYuklendi) then
  begin

    // veri paketi için bellekte yer ayýr
    EthernetPaket := GercekBellek0.Ayir(AVeriUzunlugu + ETHERNET_BASLIKU);

    EthernetPaket^.HedefMACAdres := AHedefMAC;
    EthernetPaket^.KaynakMACAdres := GAgBilgisi.MACAdres;

    // paketin protokol tipi
    case AProtokolTipi of
      ptIP  : EthernetPaket^.PaketTipi := ntohs(PROTOKOL_IP);
      ptTCP : EthernetPaket^.PaketTipi := PROTOKOL_TCP;
      ptUDP : EthernetPaket^.PaketTipi := PROTOKOL_UDP;
      ptARP : EthernetPaket^.PaketTipi := ntohs(PROTOKOL_ARP);
      ptICMP: EthernetPaket^.PaketTipi := PROTOKOL_ICMP;
    end;
{
    SISTEM_MESAJ(RENK_MOR, 'ETH', []);
    SISTEM_MESAJ_MAC(RENK_LACIVERT, 'ETH: Kaynak MAC: ', EthernetPaket^.KaynakMACAdres);
    SISTEM_MESAJ_MAC(RENK_LACIVERT, 'ETH: Hedef MAC: ', EthernetPaket^.HedefMACAdres);
    SISTEM_MESAJ_S16(RENK_LACIVERT, 'ETH: PaketTip: ', EthernetPaket^.PaketTipi, 4);
}
    Bellek := @EthernetPaket^.Veri;
    Tasi2(AVeri, Bellek, AVeriUzunlugu);

    VeriGonder(EthernetPaket, AVeriUzunlugu + ETHERNET_BASLIKU);

    GonderilenByte += AVeriUzunlugu + ETHERNET_BASLIKU;

    // ayrýlan belleði serbest býrak
    GercekBellek0.YokEt(EthernetPaket, AVeriUzunlugu + ETHERNET_BASLIKU);
  end;
end;

end.
