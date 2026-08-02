{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: ag.pas
  Dosya Ýþlevi: að (network) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 22/06/2026

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
  ETHERNET_BASLIKU      = TSayi1(14);

  // yerel olarak kabul edilebilir mac adres sayýsý
  // bilgi: ethernet mac adresi bu listeye direkt dahil olmayýp, dolaylý olarak dahildir
  YEREL_MAC_ADRESSAYISI = 2;

const

  // 0800ABCDEF01 MAC adresi Modified EUI-64'e göre kodlanarak ipv6 adresi elde edilmiþtir
  // bilgi: MAC adresinin ilk byte'ýnýn (08) saðdan 2. biti standarta göre xor'lanmýþtýr
  // http://[fe80::a00:abff:fecd:ef01]/
  IP6Adresi: TIP6Adres = ($FE, $80, $00, $00, $00, $00, $00, $00,
    $0A, $00, $AB, $FF, $FE, $CD, $EF, $01);

  // (S)unucu sabit ip4 adres deðerleri
  SIP4Adresi: TIP4Adres = (10, 0, 1, 1);
  SAltAgMaskesi: TIP4Adres = (255, 255, 255, 0);
  SAgGecidi: TIP4Adres = (10, 0, 1, 1);
  SDHCPSunucusu: TIP4Adres = (10, 0, 1, 1);
  SDNSSunucusu: TIP4Adres = (10, 0, 1, 1);

  // (I)stemci sabit ip4 adres deðerleri
  IIP4Adresi: TIP4Adres = (192, 168, 1, 111);
  IAltAgMaskesi: TIP4Adres = (255, 255, 255, 0);
  IAgGecidi: TIP4Adres = (192, 168, 1, 1);
  IDHCPSunucusu: TIP4Adres = (192, 168, 1, 1);
  IDNSSunucusu: TIP4Adres = (192, 168, 1, 1);

const
  YerelMACAdresListesi: array[0..YEREL_MAC_ADRESSAYISI - 1] of TMACAdres = (
    ($FF, $FF, $FF, $FF, $FF, $FF),
    ($33, $33, $00, $01, $00, $02));

type
  PAg = ^TAg;
  TAg = class
  private
    FAgKartiYuklendi: Boolean;
    FAktif: Boolean;

    { TODO - bu deðer kullanýcý ayar seçimine baðlanacak }
    IPAdresiniOtomatikAl: Boolean;

    FOtomatikIP: Boolean;
    FIPAdresiAlindi: Boolean;

    FMACAdres: TMACAdres;
    FIP6Adres: TIP6Adres;
    FIP4Adres, FAltAgMaskesi, FAgGecitAdresi,
    FDHCPSunucusu, FDNSSunucusu: TIP4Adres;
    FIPKiraSuresi: TSayi4;     // saniye cinsinden
    // paket baþlýklarý da dahil olmak üzere tüm veri toplamlarýný içerir.
    FGelenByte, FGidenByte: TSayi4;
  public
    constructor Create;
    function AgKartindanVeriAl(AHedefBellekAdresi: Isaretci): TISayi4;
    procedure AgKartiVeriAlmaIslevi;
    procedure AgKartinaVeriGonder(AHedefMAC: TMACAdres; AProtokolTipi: TProtokolTipi;
      AVeri: Isaretci; AVeriUzunlugu: TSayi2);
    function MACAdresiKabulEdilsinMi(AHedefMACAdres: TMACAdres): Boolean;
    property AgKartiYuklendi: Boolean read FAgKartiYuklendi write FAgKartiYuklendi;
    property Aktif: Boolean read FAktif;
    property OtomatikIP: Boolean read FOtomatikIP write FOtomatikIP;
    property IPAdresiAlindi: Boolean read FIPAdresiAlindi write FIPAdresiAlindi;
    property MACAdres: TMACAdres read FMACAdres write FMACAdres;
    property IP6Adres: TIP6Adres read FIP6Adres write FIP6Adres;
    property IP4Adres: TIP4Adres read FIP4Adres write FIP4Adres;
    property AltAgMaskesi: TIP4Adres read FAltAgMaskesi write FAltAgMaskesi;
    property AgGecitAdresi: TIP4Adres read FAgGecitAdresi write FAgGecitAdresi;
    property DHCPSunucusu: TIP4Adres read FDHCPSunucusu write FDHCPSunucusu;
    property DNSSunucusu: TIP4Adres read FDNSSunucusu write FDNSSunucusu;

    property IPKiraSuresi: TSayi4 read FIPKiraSuresi write FIPKiraSuresi;
    property GelenByte: TSayi4 read FGelenByte write FGelenByte;
    property GidenByte: TSayi4 read FGidenByte write FGidenByte;
  end;

function GenelAgCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

var
  GAg0: TAg;

implementation

uses src_pcnet32, arp, dns, ip4, ip6, sistemmesaj, donusum, islevler, dhcp4_i, dhcp4_s,
  gorev, http, ftp, lldp_i, udp, icmp4;

{==============================================================================
  að ilk deðer yüklemelerini gerçekleþtirir
 ==============================================================================}
constructor TAg.Create;
begin

  FAgKartiYuklendi := False;

  FAktif := False;

  IPAdresiAlindi := False;

  { TODO - bu deðer kullanýcý ayar seçimine baðlanacak }
  IPAdresiniOtomatikAl := False;

  IP6Adres := IP6Adresi;

  IPKiraSuresi := 0;

  GelenByte := 0;
  GidenByte := 0;

  // sistemin çalýþtýðý bilgisayarýn alan adý - (domain name)
  {$IFDEF SISTEM_SUNUCU}
  GTamBilgisayarAdi := GBilgisayarAdi + '.' + GAlanAdi;
  OtomatikIP := False;
  {$ELSE}
  GTamBilgisayarAdi := GBilgisayarAdi;
  { TODO - True olduðunda að baðlantýsý yoksa hata veriyor }
  OtomatikIP := IPAdresiniOtomatikAl;
  {$ENDIF}

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ Ethernet aygýtlarý yükleniyor...', []);
  AgAygitlariniYukle;

  if(SistemdekiAgKartiSayisi > 0) then FAgKartiYuklendi := True;

  // en az 1 að aygýtý yüklendi ise
  if(AgKartiYuklendi) then
  begin

    MACAdres := GMacAdres;
    {$IFDEF SISTEM_SUNUCU}
    IP4Adres := SIP4Adresi;
    AltAgMaskesi := SAltAgMaskesi;
    AgGecitAdresi := SAgGecidi;
    DHCPSunucusu := SDHCPSunucusu;
    DNSSunucusu := SDNSSunucusu;
    {$ELSE}
    if(OtomatikIP) then
    begin

      IP4Adres := IP4Adres0;
      AltAgMaskesi := IP4Adres0;
      AgGecitAdresi := IP4Adres0;
      DHCPSunucusu := IP4Adres0;
      DNSSunucusu := IP4Adres0;
    end
    else
    begin

      IP4Adres := IIP4Adresi;
      AltAgMaskesi := IAltAgMaskesi;
      AgGecitAdresi := IAgGecidi;
      DHCPSunucusu := IDHCPSunucusu;
      DNSSunucusu := IDNSSunucusu;
    end;
    {$ENDIF}

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ Baðlantý yapýlarý ilk deðerlerle yükleniyor...', []);
    GBaglantilar := TBaglantilar.Create;

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ UDP protokolü yükleniyor...', []);
    GUDP0 := TUDP.Create;

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ ARP protokolü yükleniyor...', []);
    GARPKayitlar0 := TARPKayitlar.Create;

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ DNS protokolü yükleniyor...', []);
    GDNS0 := TDNS.Create;

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ DHCP protokolü yükleniyor...', []);
    DHCPSunucu0 := TDHCPSunucu.Create;

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ ICMP4 protokolü yükleniyor...', []);
    GICMP4 := TICMP4.Create;

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ HTTP sunucusu yükleniyor...', []);
    HTTPSunucu0 := THTTPSunucu.Create;

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ FTP sunucusu yükleniyor...', []);
    FTPSunucu0 := TFTPSunucu.Create;

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ LLDP protokolü yükleniyor...', []);
    GLLDP := TLLDP.Create;

    FAktif := True;

    // sistem için ip adresini yapýlandýr
    if(OtomatikIP) then
    begin

      IPAdresiAlindi := False;
      DHCPIpAdresiAl;
    end else IPAdresiAlindi := True;
  end;
end;

{==============================================================================
  að kartýna (ethernet) gelen verileri alýr
 ==============================================================================}
function TAg.AgKartindanVeriAl(AHedefBellekAdresi: Isaretci): TISayi4;
var
  Bellek: array[0..$FFF] of TSayi1;
  i: TSayi2;
begin

  i := 0;

  // að kartýna (ethernet) gelen ham bilgiyi al
  { TODO : VeriAl iþlevi katý (hard code) olarak kodlanmýþtýr. yapýsallaþtýrýlacak }
  VeriAl(@Bellek, i);
  if(i > 0) then
  begin

    Tasi2(@Bellek[0], AHedefBellekAdresi, i);
    Inc(FGelenByte, i);
  end;

  Result := i;
end;

{==============================================================================
  að kartýna (ethernet) gelen verilerin protokollere yönlendirilme iþlevi
  bilgi: bu iþlev iþletim sistemi döngüsü içinde sürekli çaðrýlýr
 ==============================================================================}
procedure TAg.AgKartiVeriAlmaIslevi;
var
  EthPaket: PEthernetPaket;
  ARPPaket: PARPPaket;
  Bellek: array[0..$FFF] of TSayi1;
  i, Protokol: TSayi2;
begin

  // að yüklendi ise ...
  if(AgKartiYuklendi) then
  begin

    // að kartýna gelen ham bilgiyi al
    i := AgKartindanVeriAl(@Bellek);
    if(i > 0) then
    begin

      EthPaket := @Bellek[0];

      Protokol := htons(EthPaket^.PaketTipi);

      // yönlendirici talebi - router solicitation
      if(MACKarsilastir(EthPaket^.HedefMACAdres, MAC333300000002)) then
      begin

        if(Protokol = PROTOKOL_IP6) then IP6PaketleriniIsle(EthPaket, i - ETHERNET_BASLIKU)
      end
      //
      else if(MACKarsilastir(EthPaket^.HedefMACAdres, MAC333300000102)) then
      begin

        if(Protokol = PROTOKOL_IP6) then IP6PaketleriniIsle(EthPaket, i - ETHERNET_BASLIKU)
      end
      else if(MACKarsilastir(EthPaket^.HedefMACAdres, YayinMAC6)) then
      begin

        { TODO - çalýþmýyor }
        IP6PaketleriniIsle(EthPaket, i - ETHERNET_BASLIKU);
        SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Son asama1', []);
      end
      else if(MACAdresiKabulEdilsinMi(EthPaket^.HedefMACAdres)) then
      begin

        {SISTEM_MESAJ_MAC(mtBilgi, RENK_MAVI, 'EthernetPaket^.KaynakMACAdres: ', EthPaket^.KaynakMACAdres);
        SISTEM_MESAJ_MAC(mtBilgi, RENK_MAVI, 'EthernetPaket^.HedefMACAdres: ', EthPaket^.HedefMACAdres);
        SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'EthernetPaket^.PaketTipi: $%.4x', [EthPaket^.PaketTipi]);}

        // ******* protokollerin iþlenmesi *******

        // ARP protokolü
        if(Protokol = PROTOKOL_ARP) then
        begin

          ARPPaket := @EthPaket^.Veri;
          if(IP4Karsilastir(ARPPaket^.HedefIPAdres, IP4Adres)) then
            GARPKayitlar0.ARPPaketleriniIsle(EthPaket)
        end

        // IP V4 protokolü
        else if(Protokol = PROTOKOL_IP4) then

          IP4PaketleriniIsle(EthPaket, i - ETHERNET_BASLIKU)

        // IP V6 protokolü
        else if(Protokol = PROTOKOL_IP6) then

          IP6PaketleriniIsle(EthPaket, i - ETHERNET_BASLIKU)

        else if(Protokol = PROTOKOL_LLDP) then

          GLLDP.PaketleriIsle(EthPaket)

        else
        begin

          // bilinmeyen protokol
          SISTEM_MESAJ(mtUyari, RENK_MAVI, 'AG.PAS: bilinmeyen protokol: $%.4x', [Protokol]);
          SISTEM_MESAJ_MAC(mtUyari, RENK_SIYAH, '  -> Kaynak MAC Adresi: ', EthPaket^.KaynakMACAdres);
          SISTEM_MESAJ_MAC(mtUyari, RENK_SIYAH, '  -> Hedef MAC Adresi: ', EthPaket^.HedefMACAdres);
        end;
      end
      else
      begin

        SISTEM_MESAJ_MAC(mtBilgi, RENK_GRI, 'AG.PAS->Hedef MAC Adres Farklý: ', EthPaket^.HedefMACAdres);
      end;
    end;
  end;
end;

{==============================================================================
  að kartýna (ethernet) veri gönderir
 ==============================================================================}
procedure TAg.AgKartinaVeriGonder(AHedefMAC: TMACAdres; AProtokolTipi: TProtokolTipi;
  AVeri: Isaretci; AVeriUzunlugu: TSayi2);
var
  EthernetPaket: PEthernetPaket;
  Bellek: Isaretci;
begin

  if(AgKartiYuklendi) then
  begin

    // veri paketi için bellekte yer ayýr
    EthernetPaket := GetMem(AVeriUzunlugu + ETHERNET_BASLIKU);

    EthernetPaket^.HedefMACAdres := AHedefMAC;
    EthernetPaket^.KaynakMACAdres := MACAdres;

    // paketin protokol tipi
    case AProtokolTipi of
      ptIP4   : EthernetPaket^.PaketTipi := ntohs(PROTOKOL_IP4);
      ptIP6   : EthernetPaket^.PaketTipi := ntohs(PROTOKOL_IP6);
      ptTCP   : EthernetPaket^.PaketTipi := PROTOKOL_TCP;
      ptUDP   : EthernetPaket^.PaketTipi := PROTOKOL_UDP;
      ptARP   : EthernetPaket^.PaketTipi := ntohs(PROTOKOL_ARP);
      ptICMP4 : EthernetPaket^.PaketTipi := PROTOKOL_ICMP4;
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

    Inc(FGidenByte, AVeriUzunlugu + ETHERNET_BASLIKU);

    // ayrýlan belleði serbest býrak
    FreeMem(EthernetPaket, AVeriUzunlugu + ETHERNET_BASLIKU);
  end;
end;

function TAg.MACAdresiKabulEdilsinMi(AHedefMACAdres: TMACAdres): Boolean;
var
  i: TSayi4;
begin

  Result := False;

  // 1. ethernet aygýtý mac adresi kontrolü
  if(MACKarsilastir(AHedefMACAdres, MACAdres)) then Exit(True);

  // 2. yerel mac adres kayýt kontrolü
  if(YEREL_MAC_ADRESSAYISI > 0) then
  begin

    for i := 0 to YEREL_MAC_ADRESSAYISI - 1 do
    begin

      if(MACKarsilastir(AHedefMACAdres, YerelMACAdresListesi[i])) then Exit(True);
    end;
  end;
end;

{==============================================================================
  að kesme çaðrýlarýný yönetir
 ==============================================================================}
function GenelAgCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  IslevNo: TSayi4;
  AgBilgisi: PAgBilgisi3;
begin

  // iþlev no
  IslevNo := (AIslevNo and $FF);

  // að ayarlarýný geri döndür
  if(IslevNo = 1) then
  begin

    AgBilgisi := Isaretci(PSayi4(ADegiskenler + 00)^ + FAktifGorevBellekAdresi);
    AgBilgisi^.MACAdres := GAg0.MACAdres;
    AgBilgisi^.IP6Adres := GAg0.IP6Adres;
    AgBilgisi^.IP4Adres := GAg0.IP4Adres;
    AgBilgisi^.AltAgMaskesi := GAg0.AltAgMaskesi;
    AgBilgisi^.AgGecitAdresi := GAg0.AgGecitAdresi;
    AgBilgisi^.DHCPSunucusu := GAg0.DHCPSunucusu;
    AgBilgisi^.DNSSunucusu := GAg0.DNSSunucusu;
    AgBilgisi^.IPKiraSuresi := GAg0.IPKiraSuresi;
    AgBilgisi^.GelenByte := GAg0.GelenByte;
    AgBilgisi^.GidenByte := GAg0.GidenByte;

    Result := 1;

  end else Result := HATA_ISLEV;
end;

end.
