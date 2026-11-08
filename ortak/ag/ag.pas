{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: ag.pas
  Dosya Ýþlevi: að (network) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 08/11/2026

 ==============================================================================}
{$mode objfpc}
unit ag;

interface

uses paylasim, aygityonetimi, baglantilar, ethernet;

const
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
  public
    FOtomatikIPAdresiAl: Boolean;
    constructor Create;
    destructor Destroy; override;
    property OtomatikIPAdresiAl: Boolean read FOtomatikIPAdresiAl write FOtomatikIPAdresiAl;
  end;

function GenelAgCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses sistemmesaj, dhcpv4i, gorev, dhcpv4;

{==============================================================================
  að kesme çaðrýlarýný yönetir
 ==============================================================================}
function GenelAgCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  IslevNo: TSayi4;
  AgBilgisi: PAgBilgisi3;
begin

  Result := HATA_ISLEV;

  // iþlev no
  IslevNo := (AIslevNo and $FF);

  // að ayarlarýný geri döndür
  if(IslevNo = 1) then
  begin

    AgBilgisi := Isaretci(PSayi4(ADegiskenler + 00)^ + GGorevler.FAktifGrvBelAdr);
    AgBilgisi^.MACAdres := GAygitlar.AktifEthernet.MACAdresim;
    AgBilgisi^.IP6Adres := GAgBaglantilari.AB.IP6Adresim;
    AgBilgisi^.IP4Adres := GAgBaglantilari.AB.IP4Adresim;
    AgBilgisi^.AltAgMaskesi := GAgBaglantilari.AB.AltAgMaskesi;
    AgBilgisi^.AgGecitAdresi := GAgBaglantilari.AB.AgGecitAdresi;
    AgBilgisi^.DHCPSunucusu := GAgBaglantilari.AB.DHCPSunucusu;
    AgBilgisi^.DNSSunucusu := GAgBaglantilari.AB.DNSSunucusu;
    AgBilgisi^.IPKiraSuresi := GAgBaglantilari.AB.IPKiraSuresi;
    AgBilgisi^.GelenByte := GAygitlar.AktifEthernet.GelenByte;
    AgBilgisi^.GidenByte := GAygitlar.AktifEthernet.GidenByte;

    Result := 1;
  end;
end;

{==============================================================================
  að nesnesi ilk deðer yüklemelerini gerçekleþtirir
 ==============================================================================}
constructor TAg.Create;
var
  B: TBaglanti;
begin

  // sunucu veya istemci durumuna göre bilgisayar ad atamasý - (domain name)
  {$IFDEF SISTEM_SUNUCU}
  GTamBilgisayarAdi := GBilgisayarAdi + '.' + GAlanAdi;
  FOtomatikIPAdresiAl := False;
  {$ELSE}
  GTamBilgisayarAdi := GBilgisayarAdi;
  FOtomatikIPAdresiAl := False;
  {$ENDIF}

  // sistemde mevcut her bir að aygýtý için yazýlýmsal baðlantý oluþturma iþlemi
  GAgBaglantilari.AgBaglantilariniOlustur;

  // en az 1 að aygýtý yüklendi ise
  if not(GAygitlar.AktifEthernet = nil) then
  begin

    {$IFDEF SISTEM_SUNUCU}
    GAgBaglantilari.AB.IP4Adresim := SIP4Adres;
    GAgBaglantilari.AB.AltAgMaskesi := SAltAgMaskesi;
    GAgBaglantilari.AB.AgGecitAdresi := SAgGecidi;
    GAgBaglantilari.AB.DHCPSunucusu := SDHCPSunucusu;
    GAgBaglantilari.AB.DNSSunucusu := SDNSSunucusu;
    {$ELSE}
    // otomatik ip adresi almadan önce deðiþken içerikleri sýfýrlanýyor
    if(FOtomatikIPAdresiAl) then
    begin

      GAgBaglantilari.AB.IP4Adresim := IP4Adres0;
      GAgBaglantilari.AB.AltAgMaskesi := IP4Adres0;
      GAgBaglantilari.AB.AgGecitAdresi := IP4Adres0;
      GAgBaglantilari.AB.DHCPSunucusu := IP4Adres0;
      GAgBaglantilari.AB.DNSSunucusu := IP4Adres0;
    end
    else
    begin

      GAgBaglantilari.AB.IP4Adresim := IIP4Adres;
      GAgBaglantilari.AB.AltAgMaskesi := IAltAgMaskesi;
      GAgBaglantilari.AB.AgGecitAdresi := IAgGecidi;
      GAgBaglantilari.AB.DHCPSunucusu := IDHCPSunucusu;
      GAgBaglantilari.AB.DNSSunucusu := IDNSSunucusu;
    end;
    {$ENDIF}

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ NetBios tutanaðý yükleniyor...', []);
    B := GAgBaglantilari.AB.BaglantiOlustur(bnNetBios, itIP4, btPasif,
      ttUDP, NETBIOS_PORTNO, NETBIOS_PORTNO);

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ HTTP sunucusu yükleniyor...', []);
    B := GAgBaglantilari.AB.BaglantiOlustur(bnHTTPs, itIP4, btPasif,
      ttTCP, HTTP_PORTNO, 0);

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ FTP sunucusu yükleniyor...', []);
    B := GAgBaglantilari.AB.BaglantiOlustur(bnFTPs, itIP4, btPasif,
      ttTCP, FTP_PORTNO, 0);

    {$IFDEF SISTEM_SUNUCU}
    // dhcp v6 suunucusu
    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ DHCPv6 sunucusu yükleniyor...', []);
    B := GAgBaglantilari.AB.BaglantiOlustur(bnDHCPv6s, itIP6, btPasif, ttUDP, '',
      DHCPv6_SUNUCU_PORT, DHCPv6_ISTEMCI_PORT);

    // dhcp v4 suunucusu
    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ DHCPv4 sunucusu yükleniyor...', []);
    B := GAgBaglantilari.AB.BaglantiOlustur(bnDHCPv4s, itIP4, btPasif, ttUDP, '',
      DHCPv4_SUNUCU_PORT, DHCPv4_ISTEMCI_PORT);
    {$ELSE}
    // otomatik ip adresi alýnmasý için gerekli baðlantý oluþturularak
    // baðlantý üzerinden ip alma mesajý sunuculara gönderiliyor
    if(FOtomatikIPAdresiAl) then
    begin

      GAgBaglantilari.AB.IP4AdresiAlindi := False;
      B := GAgBaglantilari.AB.BaglantiOlustur(bnDHCPv4i, itIP4, btYAktif,
        ttUDP, DHCPv4_ISTEMCI_PORT, DHCPv4_SUNUCU_PORT);
      B.FDHCPv4i.OtomatikIpAdresiAl;
    end else GAgBaglantilari.AB.IP4AdresiAlindi := True;
    {$ENDIF}
  end;
end;

{==============================================================================
  að nesnesi yok etme iþlemlerini gerçekleþtirir
 ==============================================================================}
destructor TAg.Destroy;
begin

  { TODO - þu aþamada sistem baþlangýcýndan sonuna kadar að nesneleri var
    olacaðý için ilgili nesneleri yok etme iþlemi gerçekleþtirilmemiþtir }

  inherited Destroy;
end;

end.
