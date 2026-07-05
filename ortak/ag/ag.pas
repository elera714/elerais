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

var
  // paket baþlýklarý da dahil olmak üzere tüm veri toplamlarýný içerir.
  AlinanByte, GonderilenByte: TSayi4;

const

  // 0800ABCDEF01 MAC adresi Modified EUI-64'e göre kodlanarak ipv6 adresi elde edilmiþtir
  // bilgi: MAC adresinin ilk byte'ýnýn (08) saðdan 2. biti standarta göre xor'lanmýþtýr
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
  TAg = object
  private
    FToplamAygit: TSayi4;
//    FPCIAygitListesi: array[0..USTSINIR_PCIAYGIT - 1] of PPCI;
//    function PCIBilgiAl(ASiraNo: TSayi4): PPCI;
//    procedure PCIBilgiYaz(ASiraNo: TSayi4; APCI: PPCI);
  public
    function MACAdresiKabulEdilsinMi(AHedefMACAdres: TMACAdres): Boolean;
//    procedure Yukle;
{    function Oku1(AYol, AAygit, AIslev, ASiraNo: TSayi1): TSayi1;
    function Oku2(AYol, AAygit, AIslev, ASiraNo: TSayi1): TSayi2;
    function Oku4(AYol, AAygit, AIslev, ASiraNo: TSayi1): TSayi4;
    procedure Yaz1(AYol, AAygit, AIslev, ASiraNo: TSayi1; ADeger: TSayi1);
    procedure Yaz2(AYol, AAygit, AIslev, ASiraNo: TSayi1; ADeger: TSayi2);
    procedure Yaz4(AYol, AAygit, AIslev, ASiraNo: TSayi1; ADeger: TSayi4);
    function IlkPortDegeriniAl(APCI: PPCI): TSayi2;
    function IlkBellekDegeriniAl(APCI: PPCI): TSayi4;
    function IRQNoAl(APCI: PPCI): TSayi1;
    property ToplamAygit: TSayi4 read FToplamAygit write FToplamAygit;
    property PCI[ASiraNo: TSayi4]: PPCI read PCIBilgiAl write PCIBilgiYaz;}
  end;

procedure Yukle;
procedure IlkAdresDegerleriniYukle;
function GenelAgCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
procedure AgKartiVeriAlmaIslevi;
function AgKartindanVeriAl(AHedefBellekAdresi: Isaretci): Integer;
procedure AgKartinaVeriGonder(AHedefMAC: TMACAdres; AProtokolTipi: TProtokolTipi;
  AVeri: Isaretci; AVeriUzunlugu: TSayi2);

var
  Ag0: TAg;

implementation

uses src_pcnet32, arp, udp, dns, icmp4, ip4, ip6, sistemmesaj, donusum, islevler,
  genel, dhcp4_i, dhcp4_s, dhcp6, gorev, http, ftp, lldp_i;

{==============================================================================
  að ilk deðer yüklemelerini gerçekleþtirir
 ==============================================================================}
procedure Yukle;
begin

  // sistemin çalýþtýðý bilgisayarýn alan adý - (domain name)
  {$IFDEF SISTEM_SUNUCU}
  GTamBilgisayarAdi := GBilgisayarAdi + '.' + GAlanAdi;
  IPAdresiniOtomatikAl := False;
  {$ELSE}
  GTamBilgisayarAdi := GBilgisayarAdi;
  { TODO - True olduðunda að baðlantýsý yoksa hata veriyor }
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

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ HTTP sunucusu yükleniyor...', []);
    HTTPSunucu0.Yukle;

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ FTP sunucusu yükleniyor...', []);
    FTPSunucu0.Yukle;

    // sistem için ip adresini yapýlandýr
    if(GAgBilgisi.OtomatikIP) then
    begin

      GAgBilgisi.YenidenIPAdresiAliniyor := True;
      DHCPIpAdresiAl;
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

  GAgBilgisi.YenidenIPAdresiAliniyor := False;

  GAgBilgisi.OtomatikIP := IPAdresiniOtomatikAl;
  GAgBilgisi.MACAdres := MACAdres0;

  GAgBilgisi.IP6Adres := IP6Adresi;

  {$IFDEF SISTEM_SUNUCU}
  GAgBilgisi.IP4Adres := SIP4Adresi;
  GAgBilgisi.AltAgMaskesi := SAltAgMaskesi;
  GAgBilgisi.AgGecitAdresi := SAgGecidi;
  GAgBilgisi.DHCPSunucusu := SDHCPSunucusu;
  GAgBilgisi.DNSSunucusu := SDNSSunucusu;
  {$ELSE}
  GAgBilgisi.IP4Adres := IIP4Adresi;
  GAgBilgisi.AltAgMaskesi := IAltAgMaskesi;
  GAgBilgisi.AgGecitAdresi := IAgGecidi;
  GAgBilgisi.DHCPSunucusu := IDHCPSunucusu;
  GAgBilgisi.DNSSunucusu := IDNSSunucusu;
  {$ENDIF}

  GAgBilgisi.IPKiraSuresi := 0;
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
  EthPaket: PEthernetPaket;
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
      else if(Ag0.MACAdresiKabulEdilsinMi(EthPaket^.HedefMACAdres)) then
      begin

        {SISTEM_MESAJ_MAC(mtBilgi, RENK_MAVI, 'EthernetPaket^.KaynakMACAdres: ', EthPaket^.KaynakMACAdres);
        SISTEM_MESAJ_MAC(mtBilgi, RENK_MAVI, 'EthernetPaket^.HedefMACAdres: ', EthPaket^.HedefMACAdres);
        SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'EthernetPaket^.PaketTipi: $%.4x', [EthPaket^.PaketTipi]);}

        // ******* protokollerin iþlenmesi *******

        // ARP protokolü
        if(Protokol = PROTOKOL_ARP) then
        begin

          ARPPaket := @EthPaket^.Veri;
          if(IP4Karsilastir(ARPPaket^.HedefIPAdres, GAgBilgisi.IP4Adres)) then
            ARPKayitlar0.ARPPaketleriniIsle(EthPaket)
        end

        // IP V4 protokolü
        else if(Protokol = PROTOKOL_IP4) then

          IP4PaketleriniIsle(EthPaket, i - ETHERNET_BASLIKU)

        // IP V6 protokolü
        else if(Protokol = PROTOKOL_IP6) then

          IP6PaketleriniIsle(EthPaket, i - ETHERNET_BASLIKU)

        else if(Protokol = PROTOKOL_LLDP) then

          LLDPPaketleriniIsle(EthPaket)

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
  að kartýna (ethernet) gelen verileri alýr
 ==============================================================================}
function AgKartindanVeriAl(AHedefBellekAdresi: Isaretci): TISayi4;
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
    AlinanByte := AlinanByte + i;
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
    EthernetPaket := GetMem(AVeriUzunlugu + ETHERNET_BASLIKU);

    EthernetPaket^.HedefMACAdres := AHedefMAC;
    EthernetPaket^.KaynakMACAdres := GAgBilgisi.MACAdres;

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

    GonderilenByte := GonderilenByte + AVeriUzunlugu + ETHERNET_BASLIKU;

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
  if(MACKarsilastir(AHedefMACAdres, GAgBilgisi.MACAdres)) then Exit(True);

  // 2. yerel mac adres kayýt kontrolü
  if(YEREL_MAC_ADRESSAYISI > 0) then
  begin

    for i := 0 to YEREL_MAC_ADRESSAYISI - 1 do
    begin

      if(MACKarsilastir(AHedefMACAdres, YerelMACAdresListesi[i])) then Exit(True);
    end;
  end;
end;

end.
