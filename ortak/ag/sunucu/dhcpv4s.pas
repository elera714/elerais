{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: dhcpv4s.pas
  Dosya Ýþlevi: DHCP v4 sunucu tutanak iþlevlerini yönetir

  Güncelleme Tarihi: 27/10/2026

 ==============================================================================}
{$mode objfpc}
unit dhcpv4s;

interface

uses paylasim, dhcpv4, sunucular, udp;

const
  USTSINIR_DHCPKAYIT      = 256;
  AYRILMIS_IPSAYISI       = 20;                   // 0..AYRILMIS_IPSAYISI - 1 aralýðý ayrýlacak
  ARPDONANIMTIP_ETHERNET  = TSayi2($0001);        // network byte sýralý
  ARPPROTOKOLTIP_IPV4     = TSayi2($0800);        // network byte sýralý

type
  // istemci kayýt durumu
  TKayitDurumu = (kdAyrildi, kdAtanacak, kdAtandi);

type
  PIstemciKayit = ^TIstemciKayit;
  TIstemciKayit = record
    Durum: TKayitDurumu;      // ip adres kayýt durumu
    MACAdres: TMACAdresIslev;
  end;

type
  TDHCPv4s = class(TUDPSunucu)
  private
    FBaglanti: TObject;
    FUDP: TUDP;
    FIstemciListesi: array[0..USTSINIR_DHCPKAYIT - 1] of PIstemciKayit;
    function Al(ASiraNo: TISayi4): PIstemciKayit;
    procedure Yaz(ASiraNo: TISayi4; AIstemciKayit: PIstemciKayit);
  public
    constructor Create(ABaglanti: TObject);
    destructor Destroy; override;
    procedure OVeriGeldi(AEthernetPaket: PEthernetPaket); override;
    property IstemciListesi[ASiraNo: TISayi4]: PIstemciKayit read Al write Yaz;
    function HavuzdanIPAdresiAl(AMACAdres: TMACAdresIslev): TIP4AdresIslev;
    function IPAdresiVerilsinMi(AIstenenIP4Adres: TIP4AdresIslev;
      AMACAdres: TMACAdresIslev): Boolean;
    { Offer }
    procedure DHCPTeklifMesajiGonder(AEthernetPaket: PEthernetPaket;
      AGonderenKimlik: TSayi4; ATeklifEdilenIP4Adres: TIP4AdresIslev; AMACAdres: TMACAdres);
    { Request -> Ack }
    procedure DHCPIstegeOnayMesajiGonder(AEthernetPaket: PEthernetPaket;
      AGonderenKimlik: TSayi4; AIstenenIP4Adres: TIP4AdresIslev; AMACAdres: TMACAdresIslev);
    { NAck }
    procedure DHCPIstegeRetMesajiGonder(AEthernetPaket: PEthernetPaket;
        AGonderenKimlik: TSayi4; AMACAdres: TMACAdresIslev);
    { Inform -> Ack }
    procedure DHCPBilgilendirmeyeOnayMesajiGonder(AEthernetPaket: PEthernetPaket;
        AGonderenKimlik: TSayi4; AIP4Adres: TIP4AdresIslev; AMACAdres: TMACAdresIslev);
  end;

implementation

uses sistemmesaj, baglantilar, donusum, islevler;

{==============================================================================
  dhcp sunucu nesnesi ana yükleme iþlevlerini içerir
 ==============================================================================}
constructor TDHCPv4s.Create(ABaglanti: TObject);
var
  i: TSayi4;
begin

  FBaglanti := ABaglanti;

  for i := 0 to USTSINIR_DHCPKAYIT - 1 do IstemciListesi[i] := nil;

  // AYRILMIS_IPSAYISI kadar giriþi farklý amaçlar için ayýr
  { TODO - bu durum deneme amaçlýdýr fakat dhcp sunucusunun rezerv planý oluþturularak
    bu plan dahilinde iþleyecek }
  for i := 0 to AYRILMIS_IPSAYISI - 1 do
  begin

    IstemciListesi[i] := GetMem(SizeOf(TIstemciKayit));
    IstemciListesi[i]^.Durum := kdAyrildi;
  end;

  // iletiþim udp tutanaðý üzerinden gerçekleþeceði için 1 adet udp
  // nesnesi oluþturuluyor
  FUDP := TUDP.Create(nil, FBaglanti, itIP4, MACAdres0);
end;

{==============================================================================
  dhcp sunucu nesnesi ana yok etme iþlevlerini içerir
 ==============================================================================}
destructor TDHCPv4s.Destroy;
var
  IK: PIstemciKayit;
  i: TSayi4;
begin

  // ayrýlan bellek bölgesini serbest býrak
  for i := 0 to USTSINIR_DHCPKAYIT - 1 do
  begin

    IK := IstemciListesi[i];
    if not(IK = nil) then
    begin

      FreeMem(IK, SizeOf(TIstemciKayit));
      IstemciListesi[i] := nil
    end;
  end;

  FUDP.Destroy;

  inherited Destroy;
end;

{==============================================================================
  dhcp sunucusuna gelen paketleri iþler
 ==============================================================================}
procedure TDHCPv4s.OVeriGeldi(AEthernetPaket: PEthernetPaket);
var
  IP4Paket: PIP4Paket;
  UDPPaket: PUDPPaket;
  DHCP4Yapi: PDHCP4Yapi;
  DHCPMesaj: PDHCPMesaj;
  AnaMT, MT, DonanimTipi, i: TSayi1;
  IstemciIP4, DHCPSunucuIP4Adresi,
  IstenenIP4Adres, IP4Adres: TIP4AdresIslev;
  MACAdres, IstemciMACAdres: TMACAdresIslev;
  p1: PByte;
  IstemciAdi, SaticiSTanitici: string;
begin

  IP4Paket := PIP4Paket(@AEthernetPaket^.Veri);
  UDPPaket := PUDPPaket(@IP4Paket^.Veri);
  DHCP4Yapi := PDHCP4Yapi(@UDPPaket^.Veri);

  IstenenIP4Adres.Sifirla;
  MACAdres.Sifirla;

  // gelen mesajýn DHCP_SECIM_MESAJ_TIP deðeri
  AnaMT := 0;

  IstemciIP4.IP4Adres := DHCP4Yapi^.IstemciIP4Adres;
  IstemciMACAdres.MACAdres := DHCP4Yapi^.IstemciMACAdres;

  // seçenek olarak alýnan yapýyý döngü içerisinde irdele
  DHCPMesaj := @DHCP4Yapi^.DigerSecenekler;
  MT := DHCPMesaj^.Tip;
  i := DHCPMesaj^.Uzunluk;

  // seçeneðin sonuna gelinceye kadar tüm seçenekleri iþleme al
  while MT <> DHCP_SECIM_SON do
  begin

    if(MT = DHCP_SECIM_MESAJ_TIP) then

      AnaMT := PSayi1(@DHCPMesaj^.Mesaj)^

    else if(MT = DHCP_SECIM_ISTEMCI_KIMLIK) then
    begin

      DonanimTipi := PSayi1(@DHCPMesaj^.Mesaj)^;
      MACAdres.MACAdres := PMACAdres(@DHCPMesaj^.Mesaj + 1)^;
    end
    else if(MT = DHCP_SECIM_YEREL_AD) then

      IstemciAdi := PKarakterKatari(@DHCPMesaj^.Mesaj - 1)^

    else if(MT = DHCP_SECIM_ISTEK_IP_ADRES) then

      IstenenIP4Adres.IP4Adres := PIP4Adres(@DHCPMesaj^.Mesaj)^

    else if(MT = DHCP_SECIM_SUNUCU_TANIMLAYICI) then

      DHCPSunucuIP4Adresi.IP4Adres := PIP4Adres(@DHCPMesaj^.Mesaj)^

    else if(MT = DHCP_SECIM_SATICI_SINIF_TANITICISI) then

      SaticiSTanitici := PKarakterKatari(@DHCPMesaj^.Mesaj - 1)^

    else
    begin

      //SISTEM_MESAJ(mtBilgi, RENK_MOR, 'DHCP-S-Bilinmeyen Mesaj Tipi: %d', [MT]);
    end;

    // bir sonraki seçeneðe konumlan
    p1 := Isaretci(DHCPMesaj);
    Inc(p1, i + 2);
    DHCPMesaj := Isaretci(p1);
    MT := DHCPMesaj^.Tip;
    i := DHCPMesaj^.Uzunluk;
  end;

  {SISTEM_MESAJ(mtBilgi, RENK_MOR, 'DHCPv4-GonderenKimlik: $%x', [ADHCPYapi^.GonderenKimlik]);
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'DHCPv4-Donaným Tipi: %d', [DonanimTipi]);
  SISTEM_MESAJ_MAC(mtBilgi, RENK_MOR, 'DHCPv4-MAC Adres: ', MACAdres.MACAdres);
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'DHCPv4-Ýstemci Adý: %s', [IstemciAdi]);
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'DHCPv4-SaticiSTanitici: %s', [SaticiSTanitici]);}

  // alýnan mesaj bir yanýt mesajý mý?
  if(DHCP4Yapi^.Islem = DHCP_BOOT_MTIP_ISTEK) then
  begin

    if(AnaMT = DHCP_MTIP_KESIF) then
    begin

      IP4Adres := HavuzdanIPAdresiAl(IstemciMACAdres);
      if(IP4Adres.IPAdres0Mi = False) then
        DHCPTeklifMesajiGonder(AEthernetPaket, htons(DHCP4Yapi^.GonderenKimlik), IP4Adres, IstemciMACAdres.MACAdres)
    end
    else if(AnaMT = DHCP_MTIP_ISTEK) then
    begin

      if(IPAdresiVerilsinMi(IstenenIP4Adres, IstemciMACAdres)) then

        DHCPIstegeOnayMesajiGonder(AEthernetPaket, htons(DHCP4Yapi^.GonderenKimlik),
          IstenenIP4Adres, MACAdres)
      else DHCPIstegeRetMesajiGonder(AEthernetPaket, htons(DHCP4Yapi^.GonderenKimlik), MACAdres);
    end
    else if(AnaMT = DHCP_BILGILENDIRME) then
    begin

      DHCPBilgilendirmeyeOnayMesajiGonder(AEthernetPaket, htons(DHCP4Yapi^.GonderenKimlik), IstemciIP4, MACAdres);
    end;
  end;
end;

function TDHCPv4s.Al(ASiraNo: TISayi4): PIstemciKayit;
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_DHCPKAYIT) then
    Result := FIstemciListesi[ASiraNo]
  else Result := nil;
end;

procedure TDHCPv4s.Yaz(ASiraNo: TISayi4; AIstemciKayit: PIstemciKayit);
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_DHCPKAYIT) then
    FIstemciListesi[ASiraNo] := AIstemciKayit;
end;

{==============================================================================
  istemci için havuzdan kullanýlabilir ip adresi alýr
 ==============================================================================}
function TDHCPv4s.HavuzdanIPAdresiAl(AMACAdres: TMACAdresIslev): TIP4AdresIslev;
var
  IK: PIstemciKayit;
  KullanilabilirIP: TIP4AdresIslev;
  i: TSayi4;
begin

  KullanilabilirIP.IP4Adres := GAgBaglantilari.AB.IP4Adresim;

  for i := AYRILMIS_IPSAYISI to USTSINIR_DHCPKAYIT - 1 do
  begin

    if(IstemciListesi[i] = nil) then
    begin

      // yeni ip kaydý için bellekte yer ayýr
      IK := GetMem(SizeOf(TIstemciKayit));

      // ip kaydýný listeye kaydet
      IstemciListesi[i] := IK;

      IK^.Durum := kdAtanacak;
      IK^.MACAdres := AMACAdres;

      KullanilabilirIP.IP4Adres[3] := i;
      Exit(KullanilabilirIP);
    end;
  end;

  KullanilabilirIP.Sifirla;

  Result := KullanilabilirIP;
end;

{==============================================================================
  istenen ip adresinin istemciye verilip verilmeyeceðine karar verir
 ==============================================================================}
function TDHCPv4s.IPAdresiVerilsinMi(AIstenenIP4Adres: TIP4AdresIslev;
  AMACAdres: TMACAdresIslev): Boolean;
var
  IK: PIstemciKayit;
  IP4Adres: TIP4AdresIslev;
  i: TSayi4;
  AyniAgda: Boolean;
begin

  IP4Adres := AIstenenIP4Adres;

  AyniAgda := IP4Adres.IPAgAraligiIcinde(GAgBaglantilari.AB.IP4Adresim);
  if not(AyniAgda) then Exit(False);

  for i := AYRILMIS_IPSAYISI to USTSINIR_DHCPKAYIT - 1 do
  begin

    IK := IstemciListesi[i];
    if not(IK = nil) and ((IK^.Durum = kdAtanacak) or (IK^.Durum = kdAtandi)) then
    begin

      if(AMACAdres = IK^.MACAdres) then
      begin

        IK^.Durum := kdAtandi;
        IK^.MACAdres := AMACAdres;
        Exit(True);
      end;
    end;
  end;

  Result := False;
end;

{==============================================================================
  DHCP istemcisine teklif mesajý gönderir
 ==============================================================================}
procedure TDHCPv4s.DHCPTeklifMesajiGonder(AEthernetPaket: PEthernetPaket;
  AGonderenKimlik: TSayi4; ATeklifEdilenIP4Adres: TIP4AdresIslev; AMACAdres: TMACAdres);
var
  B: TBaglanti;
  DHCPYapi: PDHCP4Yapi;
  IP4Adres: PIP4Adres;
  p1: PSayi1;
  p4: PSayi4;
  DHCPYapiUzunlugu: TSayi4;
begin

  DHCPYapi := GetMem(4096);

	DHCPYapi^.Islem := DHCP_BOOT_MTIP_YANIT;
	DHCPYapi^.DonanimTip := 1;		      // ethernet
	DHCPYapi^.DonanimUz := 6;		        // mac uzunluðu
	DHCPYapi^.RelayIcin := 0;
	DHCPYapi^.GonderenKimlik := ntohs(AGonderenKimlik);
	DHCPYapi^.Sure := 0;
	DHCPYapi^.Bayraklar := 0;
	DHCPYapi^.IstemciIP4Adres := IP4Adres0;
	DHCPYapi^.IstemciyeAtanacakIP4Adres := ATeklifEdilenIP4Adres.IP4Adres;
	DHCPYapi^.SunucuIP4Adres := IP4Adres0;
	DHCPYapi^.AgGecidiIP4Adres := IP4Adres0;

  // IstemciMACAdres 6 + 10 = 16 byte
  DHCPYapi^.IstemciMACAdres := AMACAdres;
	DHCPYapi^.AYRLDI1 := 0;
	DHCPYapi^.AYRLDI2 := 0;
	DHCPYapi^.AYRLDI3 := 0;

  FillChar(DHCPYapi^.SunucuEvSahibiAdi, 64, #0);
  FillChar(DHCPYapi^.AcilisDosyaAdi, 128, #0);
	DHCPYapi^.SihirliCerez := ntohs(DHCP_SIHIRLI_CEREZ);

  // en sondaki iþaretçi hariç (DigerSecenekler) yapý uzunluðu
  DHCPYapiUzunlugu := SizeOf(TDHCP4Yapi) - 4;

  // diðer seçenekler
  p1 := @DHCPYapi^.DigerSecenekler;

  // dhcp mesaj kodlamasý
  // 1. byte = mesaj tip, 2. byte = mesajýn uzunluðu, 3. byte = mesajýn kendisi

  // dhcp mesaj tipi
  p1^ := DHCP_SECIM_MESAJ_TIP;
  Inc(p1);
  p1^ := 1;
  Inc(p1);
  p1^ := DHCP_MTIP_TEKLIF;
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 1;

  Inc(p1);

  // sunucu ip adresi - 2 + 4 byte
  p1^ := DHCP_SECIM_SUNUCU_TANIMLAYICI;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IP4Adres := Isaretci(p1);
  IP4Adres^ := GAgBaglantilari.AB.IP4Adresim;
  Inc(IP4Adres);
  p1 := Isaretci(IP4Adres);
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 4;

  p1^ := DHCP_SECIM_IP_KIRALAMA_SURESI;
  Inc(p1);
  p1^ := 4;                               // uzunluk
  Inc(p1);
  p4 := Isaretci(p1);
  p4^ := htons(TSayi4(8 * 60 * 60));      // saniye cinsinden
  Inc(p4);
  p1 := Isaretci(p4);
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 4;

  p1^ := DHCP_SECIM_YENILEME_SURESI;
  Inc(p1);
  p1^ := 4;                               // uzunluk
  Inc(p1);
  p4 := Isaretci(p1);
  p4^ := htons(TSayi4(4 * 60 * 60));      // saniye cinsinden
  Inc(p4);
  p1 := Isaretci(p4);
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 4;

  p1^ := DHCP_SECIM_YENIDEN_BAGLAMA_SURESI;
  Inc(p1);
  p1^ := 4;                               // uzunluk
  Inc(p1);
  p4 := Isaretci(p1);
  p4^ := htons(TSayi4(4 * 60 * 60));      // saniye cinsinden
  Inc(p4);
  p1 := Isaretci(p4);
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 4;

  // alt að maskesi - 2 + 4 byte
  p1^ := DHCP_SECIM_ALTAG_MASKESI;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IP4Adres := Isaretci(p1);
  IP4Adres^ := GAgBaglantilari.AB.AltAgMaskesi;
  Inc(IP4Adres);
  p1 := Isaretci(IP4Adres);
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 4;

  // alt að maskesi - 2 + 4 byte
  p1^ := DHCP_SECIM_YONLENDIRICI;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IP4Adres := Isaretci(p1);
  IP4Adres^ := AgGecidi;
  Inc(IP4Adres);
  p1 := Isaretci(IP4Adres);
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 4;

  // dns sunucusu - 2 + 4 byte
  p1^ := DHCP_SECIM_DNS;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IP4Adres := Isaretci(p1);
  IP4Adres^ := DNSIP4Adres;
  Inc(IP4Adres);
  p1 := Isaretci(IP4Adres);
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 4;

  p1^ := DHCP_SECIM_SON;
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 1;

  B := TBaglanti(FBaglanti);
  B.FDHCPv4s.FUDP.FIP4.FHedefMACAdres := AEthernetPaket^.KaynakMACAdres;
  B.FDHCPv4s.FUDP.FIP4.FKaynakIPAdres := ATeklifEdilenIP4Adres.IP4Adres;
  B.FDHCPv4s.FUDP.FIP4.FHedefIPAdres := TBaglanti(FBaglanti).FAB.IP4Adresim;
  B.FDHCPv4s.FUDP.PaketleVeGonder(@DHCPYapi[0], DHCPYapiUzunlugu);

  FreeMem(DHCPYapi, 4096);
end;

{==============================================================================
  DHCP istemcisinin istek mesajýna onay yanýtý gönderir
 ==============================================================================}
procedure TDHCPv4s.DHCPIstegeOnayMesajiGonder(AEthernetPaket: PEthernetPaket;
  AGonderenKimlik: TSayi4; AIstenenIP4Adres: TIP4AdresIslev; AMACAdres: TMACAdresIslev);
var
  B: TBaglanti;
  DHCPYapi: PDHCP4Yapi;
  IP4Adres: PIP4Adres;
  i: TSayi1;
  p1: PSayi1;
  p4: PSayi4;
  pc: PChar;
  DHCPYapiUzunlugu: TSayi4;
begin

  DHCPYapi := GetMem(4096);

	DHCPYapi^.Islem := DHCP_BOOT_MTIP_YANIT;
	DHCPYapi^.DonanimTip := 1;		      // ethernet
	DHCPYapi^.DonanimUz := 6;		        // mac uzunluðu
	DHCPYapi^.RelayIcin := 0;
	DHCPYapi^.GonderenKimlik := ntohs(AGonderenKimlik);
	DHCPYapi^.Sure := 0;
	DHCPYapi^.Bayraklar := 0;
	DHCPYapi^.IstemciIP4Adres := IP4Adres0;
	DHCPYapi^.IstemciyeAtanacakIP4Adres := AIstenenIP4Adres.IP4Adres;
	DHCPYapi^.SunucuIP4Adres := IP4Adres0;
	DHCPYapi^.AgGecidiIP4Adres := IP4Adres0;

  // IstemciMACAdres 6 + 10 = 16 byte
  DHCPYapi^.IstemciMACAdres := AMACAdres.MACAdres;
	DHCPYapi^.AYRLDI1 := 0;
	DHCPYapi^.AYRLDI2 := 0;
	DHCPYapi^.AYRLDI3 := 0;

  FillChar(DHCPYapi^.SunucuEvSahibiAdi, 64, #0);
  FillChar(DHCPYapi^.AcilisDosyaAdi, 128, #0);
	DHCPYapi^.SihirliCerez := ntohs(DHCP_SIHIRLI_CEREZ);

  // en sondaki iþaretçi hariç (DigerSecenekler) yapý uzunluðu
  DHCPYapiUzunlugu := SizeOf(TDHCP4Yapi) - 4;

  // diðer seçenekler
  p1 := @DHCPYapi^.DigerSecenekler;

  // dhcp mesaj kodlamasý
  // 1. byte = mesaj tip, 2. byte = mesajýn uzunluðu, 3. byte = mesajýn kendisi

  // dhcp mesaj tipi
  p1^ := DHCP_SECIM_MESAJ_TIP;
  Inc(p1);
  p1^ := 1;
  Inc(p1);
  p1^ := DHCP_MTIP_ONAY;
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 1;

  Inc(p1);

  // sunucu ip adresi - 2 + 4 byte
  p1^ := DHCP_SECIM_SUNUCU_TANIMLAYICI;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IP4Adres := Isaretci(p1);
  IP4Adres^ := GAgBaglantilari.AB.IP4Adresim;
  Inc(IP4Adres);
  p1 := Isaretci(IP4Adres);
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 4;

  p1^ := DHCP_SECIM_IP_KIRALAMA_SURESI;
  Inc(p1);
  p1^ := 4;                               // uzunluk
  Inc(p1);
  p4 := Isaretci(p1);
  p4^ := htons(TSayi4(8 * 60 * 60));      // saniye cinsinden
  Inc(p4);
  p1 := Isaretci(p4);
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 4;

  p1^ := DHCP_SECIM_YENILEME_SURESI;
  Inc(p1);
  p1^ := 4;                               // uzunluk
  Inc(p1);
  p4 := Isaretci(p1);
  p4^ := htons(TSayi4(4 * 60 * 60));      // saniye cinsinden
  Inc(p4);
  p1 := Isaretci(p4);
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 4;

  p1^ := DHCP_SECIM_YENIDEN_BAGLAMA_SURESI;
  Inc(p1);
  p1^ := 4;                               // uzunluk
  Inc(p1);
  p4 := Isaretci(p1);
  p4^ := htons(TSayi4(4 * 60 * 60));      // saniye cinsinden
  Inc(p4);
  p1 := Isaretci(p4);
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 4;

  // alt að maskesi - 2 + 4 byte
  p1^ := DHCP_SECIM_ALTAG_MASKESI;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IP4Adres := Isaretci(p1);
  IP4Adres^ := GAgBaglantilari.AB.AltAgMaskesi;
  Inc(IP4Adres);
  p1 := Isaretci(IP4Adres);
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 4;

  // alt að maskesi - 2 + 4 byte
  p1^ := DHCP_SECIM_YONLENDIRICI;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IP4Adres := Isaretci(p1);
  IP4Adres^ := AgGecidi;
  Inc(IP4Adres);
  p1 := Isaretci(IP4Adres);
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 4;

  // dns sunucusu - 2 + 4 byte
  p1^ := DHCP_SECIM_DNS;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IP4Adres := Isaretci(p1);
  IP4Adres^ := DNSIP4Adres;
  Inc(IP4Adres);
  p1 := Isaretci(IP4Adres);
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 4;

  // alan adý - 2 byte + ad uzunluðu + 1 byte
  i := Length(GAlanAdi);
  p1^ := DHCP_SECIM_ALAN_ADI;
  Inc(p1);
  PByte(p1)^ := i + 1;
  Inc(p1);
  pc := Isaretci(p1);
  Tasi2(@GAlanAdi[1], pc, i);
  Inc(pc, i);
  p1 := Isaretci(pc);
  p1^ := 0;
  Inc(p1);
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + i + 1;

  p1^ := DHCP_SECIM_SON;
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 1;

  B := TBaglanti(FBaglanti);
  B.FDHCPv4s.FUDP.FIP4.FHedefMACAdres := AEthernetPaket^.KaynakMACAdres;
  B.FDHCPv4s.FUDP.FIP4.FKaynakIPAdres := AIstenenIP4Adres.IP4Adres;
  B.FDHCPv4s.FUDP.FIP4.FHedefIPAdres := TBaglanti(FBaglanti).FAB.IP4Adresim;
  B.FDHCPv4s.FUDP.PaketleVeGonder(@DHCPYapi[0], DHCPYapiUzunlugu);

  SISTEM_MESAJ_IP4(mtUyari, RENK_PEMBE, 'DHCPv4-Sunucu: Tahsis edilen IP: ', AIstenenIP4Adres.IP4Adres);

  FreeMem(DHCPYapi, 4096);
end;

{==============================================================================
  DHCP istemcisine ret mesajý gönderir
 ==============================================================================}
procedure TDHCPv4s.DHCPIstegeRetMesajiGonder(AEthernetPaket: PEthernetPaket;
  AGonderenKimlik: TSayi4; AMACAdres: TMACAdresIslev);
var
  B: TBaglanti;
  IP4Paket: PIP4Paket;
  DHCPYapi: PDHCP4Yapi;
  IP4Adres: PIP4Adres;
  p1: PSayi1;
  DHCPYapiUzunlugu: TSayi4;
begin

  IP4Paket := PIP4Paket(@AEthernetPaket^.Veri);

  DHCPYapi := GetMem(4096);

	DHCPYapi^.Islem := DHCP_BOOT_MTIP_YANIT;
	DHCPYapi^.DonanimTip := 1;		      // ethernet
	DHCPYapi^.DonanimUz := 6;		        // mac uzunluðu
	DHCPYapi^.RelayIcin := 0;
	DHCPYapi^.GonderenKimlik := ntohs(AGonderenKimlik);
	DHCPYapi^.Sure := 0;
	DHCPYapi^.Bayraklar := 0;
	DHCPYapi^.IstemciIP4Adres := IP4Adres0;
	DHCPYapi^.IstemciyeAtanacakIP4Adres := IP4Adres0;
	DHCPYapi^.SunucuIP4Adres := IP4Adres0;
	DHCPYapi^.AgGecidiIP4Adres := IP4Adres0;

  // IstemciMACAdres 6 + 10 = 16 byte
  DHCPYapi^.IstemciMACAdres := AMACAdres.MACAdres;
	DHCPYapi^.AYRLDI1 := 0;
	DHCPYapi^.AYRLDI2 := 0;
	DHCPYapi^.AYRLDI3 := 0;

  FillChar(DHCPYapi^.SunucuEvSahibiAdi, 64, #0);
  FillChar(DHCPYapi^.AcilisDosyaAdi, 128, #0);
	DHCPYapi^.SihirliCerez := ntohs(DHCP_SIHIRLI_CEREZ);

  // en sondaki iþaretçi hariç (DigerSecenekler) yapý uzunluðu
  DHCPYapiUzunlugu := SizeOf(TDHCP4Yapi) - 4;

  // diðer seçenekler
  p1 := @DHCPYapi^.DigerSecenekler;

  // dhcp mesaj kodlamasý
  // 1. byte = mesaj tip, 2. byte = mesajýn uzunluðu, 3. byte = mesajýn kendisi

  // dhcp mesaj tipi
  p1^ := DHCP_SECIM_MESAJ_TIP;
  Inc(p1);
  p1^ := 1;
  Inc(p1);
  p1^ := DHCP_MTIP_RET;
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 3;

  Inc(p1);

  // sunucu ip adresi - 2 + 4 byte
  p1^ := DHCP_SECIM_SUNUCU_TANIMLAYICI;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IP4Adres := Isaretci(p1);
  IP4Adres^ := GAgBaglantilari.AB.IP4Adresim;
  Inc(IP4Adres);
  p1 := Isaretci(IP4Adres);
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 4;

  p1^ := DHCP_SECIM_SON;
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 1;

  B := TBaglanti(FBaglanti);
  B.FDHCPv4s.FUDP.FIP4.FHedefMACAdres := AEthernetPaket^.KaynakMACAdres;

  // gönderen ip adresi 0.0.0.0 ise hedef adresi 255.255.255.255 olarak belirle
  if(IP4Karsilastir(IP4Paket^.KaynakIPAdres, IP4Adres0)) then
    B.FDHCPv4s.FUDP.FIP4.FKaynakIPAdres := IP4Adres255
  else B.FDHCPv4s.FUDP.FIP4.FKaynakIPAdres := IP4Paket^.KaynakIPAdres;
  B.FDHCPv4s.FUDP.FIP4.FHedefIPAdres := TBaglanti(FBaglanti).FAB.IP4Adresim;

  B.FDHCPv4s.FUDP.PaketleVeGonder(@DHCPYapi[0], DHCPYapiUzunlugu);

  FreeMem(DHCPYapi, 4096);
end;

{==============================================================================
  DHCP istemcisinin bilgilendirme mesajýna onay yanýtý gönderir
 ==============================================================================}
procedure TDHCPv4s.DHCPBilgilendirmeyeOnayMesajiGonder(AEthernetPaket: PEthernetPaket;
  AGonderenKimlik: TSayi4; AIP4Adres: TIP4AdresIslev; AMACAdres: TMACAdresIslev);
var
  B: TBaglanti;
  DHCPYapi: PDHCP4Yapi;
  IP4Adres: PIP4Adres;
  p1: PSayi1;
  DHCPYapiUzunlugu: TSayi4;
begin

  DHCPYapi := GetMem(4096);

	DHCPYapi^.Islem := DHCP_BOOT_MTIP_YANIT;
	DHCPYapi^.DonanimTip := 1;		      // ethernet
	DHCPYapi^.DonanimUz := 6;		        // mac uzunluðu
	DHCPYapi^.RelayIcin := 0;
	DHCPYapi^.GonderenKimlik := ntohs(AGonderenKimlik);
	DHCPYapi^.Sure := 0;
	DHCPYapi^.Bayraklar := 0;
	DHCPYapi^.IstemciIP4Adres := IP4Adres0;
	DHCPYapi^.IstemciyeAtanacakIP4Adres := IP4Adres0;
	DHCPYapi^.SunucuIP4Adres := IP4Adres0;
	DHCPYapi^.AgGecidiIP4Adres := IP4Adres0;

  // IstemciMACAdres 6 + 10 = 16 byte
  DHCPYapi^.IstemciMACAdres := AMACAdres.MACAdres;
	DHCPYapi^.AYRLDI1 := 0;
	DHCPYapi^.AYRLDI2 := 0;
	DHCPYapi^.AYRLDI3 := 0;

  FillChar(DHCPYapi^.SunucuEvSahibiAdi, 64, #0);
  FillChar(DHCPYapi^.AcilisDosyaAdi, 128, #0);
	DHCPYapi^.SihirliCerez := ntohs(DHCP_SIHIRLI_CEREZ);

  // en sondaki iþaretçi hariç (DigerSecenekler) yapý uzunluðu
  DHCPYapiUzunlugu := SizeOf(TDHCP4Yapi) - 4;

  // diðer seçenekler
  p1 := @DHCPYapi^.DigerSecenekler;

  // dhcp mesaj kodlamasý
  // 1. byte = mesaj tip, 2. byte = mesajýn uzunluðu, 3. byte = mesajýn kendisi

  // dhcp mesaj tipi
  p1^ := DHCP_SECIM_MESAJ_TIP;
  Inc(p1);
  p1^ := 1;
  Inc(p1);
  p1^ := DHCP_MTIP_ONAY;
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 3;

  Inc(p1);

  // sunucu ip adresi - 2 + 4 byte
  p1^ := DHCP_SECIM_SUNUCU_TANIMLAYICI;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IP4Adres := Isaretci(p1);
  IP4Adres^ := GAgBaglantilari.AB.IP4Adresim;
  Inc(IP4Adres);
  p1 := Isaretci(IP4Adres);
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 4;

  // alt að maskesi - 2 + 4 byte
  p1^ := DHCP_SECIM_ALTAG_MASKESI;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IP4Adres := Isaretci(p1);
  IP4Adres^ := GAgBaglantilari.AB.AltAgMaskesi;
  Inc(IP4Adres);
  p1 := Isaretci(IP4Adres);
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 4;

  // alt að maskesi - 2 + 4 byte
  p1^ := DHCP_SECIM_YONLENDIRICI;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IP4Adres := Isaretci(p1);
  IP4Adres^ := AgGecidi;
  Inc(IP4Adres);
  p1 := Isaretci(IP4Adres);
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 4;

  // dns sunucusu - 2 + 4 byte
  p1^ := DHCP_SECIM_DNS;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IP4Adres := Isaretci(p1);
  IP4Adres^ := DNSIP4Adres;
  Inc(IP4Adres);
  p1 := Isaretci(IP4Adres);
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 4;

  p1^ := DHCP_SECIM_OZEL_PROXY_OTOKESIF;
  Inc(p1);
  p1^ := 1;                               // uzunluk
  Inc(p1);
  p1^ := $A;
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 1;

  Inc(p1);

  p1^ := DHCP_SECIM_SON;
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 1;

  B := TBaglanti(FBaglanti);
  B.FDHCPv4s.FUDP.FIP4.FHedefMACAdres := AEthernetPaket^.KaynakMACAdres;
  B.FDHCPv4s.FUDP.FIP4.FKaynakIPAdres := AIP4Adres.IP4Adres;
  B.FDHCPv4s.FUDP.FIP4.FHedefIPAdres := TBaglanti(FBaglanti).FAB.IP4Adresim;
  B.FDHCPv4s.FUDP.PaketleVeGonder(@DHCPYapi[0], DHCPYapiUzunlugu);

  FreeMem(DHCPYapi, 4096);
end;

end.
