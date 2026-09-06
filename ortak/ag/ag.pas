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
uses paylasim, aygityonetimi, baglantilar, ethernet;

const

  // 0800ABCDEF01 MAC adresi Modified EUI-64'e göre kodlanarak ipv6 adresi elde edilmiþtir
  // bilgi: MAC adresinin ilk byte'ýnýn (08) saðdan 2. biti standarta göre xor'lanmýþtýr
  // http://[fe80::a00:abff:fecd:ef01]/
  IP6Adresi: TIP6Adres = ($FE, $80, $00, $00, $00, $00, $00, $00,
    $0A, $00, $AB, $FF, $FE, $CD, $EF, $01);

  // (S)unucu sabit ip4 adres deðerleri
  SIP4Adres: TIP4Adres = (10, 0, 1, 1);
  SAltAgMaskesi: TIP4Adres = (255, 255, 255, 0);
  SAgGecidi: TIP4Adres = (10, 0, 1, 1);
  SDHCPSunucusu: TIP4Adres = (10, 0, 1, 1);
  SDNSSunucusu: TIP4Adres = (10, 0, 1, 1);

  // (I)stemci sabit ip4 adres deðerleri
  IIP4Adres: TIP4Adres = (192, 168, 1, 111);
  IAltAgMaskesi: TIP4Adres = (255, 255, 255, 0);
  IAgGecidi: TIP4Adres = (192, 168, 1, 1);
  IDHCPSunucusu: TIP4Adres = (192, 168, 1, 1);
  IDNSSunucusu: TIP4Adres = (192, 168, 1, 1);

type
  PAg = ^TAg;
  TAg = class
  private
    { TODO - bu deðer kullanýcý ayar seçimine baðlanacak }
    IP4AdresiniOtomatikAl: Boolean;

    FOtomatikIP4: Boolean;
  public
    // að - gelen paket sayýlarý
    FICMP6PaketSayisi,
    FTCP4PaketSayisi,
    FTCP6PaketSayisi,
    FUDPPaketSayisi,
    FGAEPaketSayisi: TSayi4;     // GözArdýEdilen paket sayýsý
    constructor Create;
    destructor Destroy; override;
    property OtomatikIP4: Boolean read FOtomatikIP4 write FOtomatikIP4;
  end;

function GenelAgCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

var
  GAg: TAg;

implementation

uses dns, sistemmesaj, dhcpv4i, dhcpv4s, gorev, http, ftp, udp, netbios, sunucular,
  arp, tcp, icmp6, istemciler, dhcpv4;

{==============================================================================
  að ilk deðer yüklemelerini gerçekleþtirir
 ==============================================================================}
constructor TAg.Create;
begin

  { TODO - bu deðer kullanýcý ayar seçimine baðlanacak }
  IP4AdresiniOtomatikAl := True;

  FICMP6PaketSayisi := 0;
  FTCP4PaketSayisi := 0;
  FTCP6PaketSayisi := 0;
  FUDPPaketSayisi := 0;
  FGAEPaketSayisi := 0;       // GözArdýEdilen paket sayýsý

  // sistemin çalýþtýðý bilgisayarýn alan adý - (domain name)
  {$IFDEF SISTEM_SUNUCU}
  GTamBilgisayarAdi := GBilgisayarAdi + '.' + GAlanAdi;
  OtomatikIP4 := False;
  {$ELSE}
  GTamBilgisayarAdi := GBilgisayarAdi;
  { TODO - True olduðunda að baðlantýsý yoksa hata veriyor }
  OtomatikIP4 := IP4AdresiniOtomatikAl;
  {$ENDIF}

  GAgBaglantilari.AgBaglantilariniOlustur;

  GARPTablosu := TARPTablosu.Create(GAgBaglantilari.AktifBaglanti);

  // en az 1 að aygýtý yüklendi ise
  if not(GAygitlar.AktifEthernet = nil) then
  begin

    {$IFDEF SISTEM_SUNUCU}
    GAgBaglantilari.AktifBaglanti.IP4Adres := SIP4Adres;
    GAgBaglantilari.AktifBaglanti.AltAgMaskesi := SAltAgMaskesi;
    GAgBaglantilari.AktifBaglanti.AgGecitAdresi := SAgGecidi;
    GAgBaglantilari.AktifBaglanti.DHCPSunucusu := SDHCPSunucusu;
    GAgBaglantilari.AktifBaglanti.DNSSunucusu := SDNSSunucusu;
    {$ELSE}
    if(OtomatikIP4) then
    begin

      GAgBaglantilari.AktifBaglanti.IP4Adres := IP4Adres0;
      GAgBaglantilari.AktifBaglanti.AltAgMaskesi := IP4Adres0;
      GAgBaglantilari.AktifBaglanti.AgGecitAdresi := IP4Adres0;
      GAgBaglantilari.AktifBaglanti.DHCPSunucusu := IP4Adres0;
      GAgBaglantilari.AktifBaglanti.DNSSunucusu := IP4Adres0;
    end
    else
    begin

      GAgBaglantilari.AktifBaglanti.IP4Adres := IIP4Adres;
      GAgBaglantilari.AktifBaglanti.AltAgMaskesi := IAltAgMaskesi;
      GAgBaglantilari.AktifBaglanti.AgGecitAdresi := IAgGecidi;
      GAgBaglantilari.AktifBaglanti.DHCPSunucusu := IDHCPSunucusu;
      GAgBaglantilari.AktifBaglanti.DNSSunucusu := IDNSSunucusu;
    end;
    {$ENDIF}

    GTCP := TTCP.Create(GAgBaglantilari.AktifBaglanti);
    GICMP6 := TICMP6.Create(GAgBaglantilari.AktifBaglanti);

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ UDP protokolü yükleniyor...', []);
    GUDP := TUDP.Create(GAgBaglantilari.AktifBaglanti);

    //SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ ARP protokolü yükleniyor...', []);
    //GARP := TARP.Create;

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ DNS protokolü yükleniyor...', []);
    GDNS := TDNS.Create;

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ DHCP protokolü yükleniyor...', []);
    GDHCPv4 := TDHCPv4s.Create;

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ NetBios protokolü yükleniyor...', []);
    GNetBios := TNetBios.Create(GAgBaglantilari.AktifBaglanti);

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ HTTP sunucusu yükleniyor...', []);
    GHTTPSunucu := THTTPSunucu.Create(GAgBaglantilari.AktifBaglanti);

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ FTP sunucusu yükleniyor...', []);
    GFTPSunucu := TFTPSunucu.Create;

    GSunucular := TSunucular.Create;
    GSunucular.Ekle(ptTCP, 80, @SunucuIslevHTTP);
    GSunucular.Ekle(ptTCP, 21, @SunucuIslevFTP);

    //GDHCPv4 := TDHCPv4.Create;
    GDHCPv4i := TDHCPv4i.Create;

    // sistem için ip adresini yapýlandýr
    if(OtomatikIP4) then
    begin

      GIstemciler := TIstemciler.Create;
      GIstemciler.Ekle(ptUDP, DHCP_ISTEMCI_PORT, DHCP_SUNUCU_PORT, @IslevDHCPv4i);

      GAgBaglantilari.AktifBaglanti.IP4AdresiAlindi := False;
      GDHCPv4i.IpAdresiAl;
    end else GAgBaglantilari.AktifBaglanti.IP4AdresiAlindi := True;
  end;
end;

destructor TAg.Destroy;
begin

  //FEthernet.Destroy;

  inherited Destroy;
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

    AgBilgisi := Isaretci(PSayi4(ADegiskenler + 00)^ + GGorevler.FAktifGrvBelAdr);
    AgBilgisi^.MACAdres := GAygitlar.AktifEthernet.MACAdres;
    AgBilgisi^.IP6Adres := GAgBaglantilari.AktifBaglanti.IP6Adres;
    AgBilgisi^.IP4Adres := GAgBaglantilari.AktifBaglanti.IP4Adres;
    AgBilgisi^.AltAgMaskesi := GAgBaglantilari.AktifBaglanti.AltAgMaskesi;
    AgBilgisi^.AgGecitAdresi := GAgBaglantilari.AktifBaglanti.AgGecitAdresi;
    AgBilgisi^.DHCPSunucusu := GAgBaglantilari.AktifBaglanti.DHCPSunucusu;
    AgBilgisi^.DNSSunucusu := GAgBaglantilari.AktifBaglanti.DNSSunucusu;
    AgBilgisi^.IPKiraSuresi := GAgBaglantilari.AktifBaglanti.IPKiraSuresi;
    AgBilgisi^.GelenByte := GAygitlar.AktifEthernet.GelenByte;
    AgBilgisi^.GidenByte := GAygitlar.AktifEthernet.GidenByte;

    Result := 1;

  end else Result := HATA_ISLEV;
end;

end.
