{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: dhcpv4s.pas
  Dosya Ýþlevi: DHCP v4 sunucu tutanak iþlevlerini yönetir

  Güncelleme Tarihi: 21/10/2026

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
  TDHCPv4Sunucu = class(TUDPSunucu)
  private
    FIstemciListesi: array[0..USTSINIR_DHCPKAYIT - 1] of PIstemciKayit;
    function Al(ASiraNo: TISayi4): PIstemciKayit;
    procedure Yaz(ASiraNo: TISayi4; AIstemciKayit: PIstemciKayit);
  public
    constructor Create;
    procedure OVeriGeldi(AUDP: TUDP); override;
    property IstemciListesi[ASiraNo: TISayi4]: PIstemciKayit read Al write Yaz;

    procedure VerileriIsle(AUDP: TUDP; ADHCPYapi: PDHCP4Yapi);
    function HavuzdanIPAdresiAl(AMACAdres: TMACAdresIslev): TIP4AdresIslev;
    function IPAdresiVerilsinMi(AIstenenIP4Adres: TIP4AdresIslev;
      AMACAdres: TMACAdresIslev): Boolean;

    { Offer }
    procedure DHCPTeklifMesajiGonder(AUDP: TUDP; AGonderenKimlik: TSayi4;
      ATeklifEdilenIP4Adres: TIP4AdresIslev; AMACAdres: TMACAdres);
    { Request -> Ack }
    procedure DHCPIstegeOnayMesajiGonder(AUDP: TUDP; AGonderenKimlik: TSayi4;
      AIstenenIP4Adres: TIP4AdresIslev; AMACAdres: TMACAdresIslev);
    { NAck }
    procedure DHCPIstegeRetMesajiGonder(AUDP: TUDP; AGonderenKimlik: TSayi4; AMACAdres: TMACAdresIslev);
    { Inform -> Ack }
    procedure DHCPBilgilendirmeyeOnayMesajiGonder(AUDP: TUDP;
      AGonderenKimlik: TSayi4; AIP4Adres: TIP4AdresIslev; AMACAdres: TMACAdresIslev);
  end;

var
  GDHCPv4Sunucu: TDHCPv4Sunucu;

implementation

uses sistemmesaj, baglantilar, donusum, islevler;

{==============================================================================
  dhcp sunucusu ana yükleme iþlevlerini içerir
 ==============================================================================}
constructor TDHCPv4Sunucu.Create;
var
  i: TSayi4;
begin

  for i := 0 to USTSINIR_DHCPKAYIT - 1 do IstemciListesi[i] := nil;

  // AYRILMIS_IPSAYISI kadar giriþi farklý amaçlar için ayýr
  { TODO - bu durum deneme amaçlýdýr fakat dhcp sunucusunun rezerv planý oluþturularak
    bu plan dahilinde iþleyecek }
  for i := 0 to AYRILMIS_IPSAYISI - 1 do
  begin

    IstemciListesi[i] := GetMem(SizeOf(TIstemciKayit));
    IstemciListesi[i]^.Durum := kdAyrildi;
  end;
end;

{==============================================================================
  istemcilerden veri geldiðinde tetiklenen olay
 ==============================================================================}
procedure TDHCPv4Sunucu.OVeriGeldi(AUDP: TUDP);
var
  Veri: Isaretci;
  VeriU: TSayi4;
begin

  Veri := GetMem(4 * 4096);

  VeriU := AUDP.GelenVeriyiAl(Veri);
  if(VeriU = 0) then Exit;

  VerileriIsle(AUDP, Veri);

  FreeMem(Veri, 4 * 4096);
end;

function TDHCPv4Sunucu.Al(ASiraNo: TISayi4): PIstemciKayit;
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_DHCPKAYIT) then
    Result := FIstemciListesi[ASiraNo]
  else Result := nil;
end;

procedure TDHCPv4Sunucu.Yaz(ASiraNo: TISayi4; AIstemciKayit: PIstemciKayit);
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_DHCPKAYIT) then
    FIstemciListesi[ASiraNo] := AIstemciKayit;
end;

{==============================================================================
  DHCP v4 sunucusuna gelen paketlerini iþler
 ==============================================================================}
procedure TDHCPv4Sunucu.VerileriIsle(AUDP: TUDP; ADHCPYapi: PDHCP4Yapi);
var
  DHCPMesaj: PDHCPMesaj;
  AnaMT, MT, DonanimTipi, i: TSayi1;
  IstemciIP4, DHCPSunucuIP4Adresi,
  IstenenIP4Adres, IP4Adres: TIP4AdresIslev;
  MACAdres, IstemciMACAdres: TMACAdresIslev;
  p1: PByte;
  IstemciAdi, SaticiSTanitici: string;
begin

  IstenenIP4Adres.Sifirla;
  MACAdres.Sifirla;

  // gelen mesajýn DHCP_SECIM_MESAJ_TIP deðeri
  AnaMT := 0;

  IstemciIP4.IP4Adres := ADHCPYapi^.IstemciIP4Adres;
  IstemciMACAdres.MACAdres := ADHCPYapi^.IstemciMACAdres;

  // seçenek olarak alýnan yapýyý döngü içerisinde irdele
  DHCPMesaj := @ADHCPYapi^.DigerSecenekler;
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
  if(ADHCPYapi^.Islem = DHCP_BOOT_MTIP_ISTEK) then
  begin

    if(AnaMT = DHCP_MTIP_KESIF) then
    begin

      IP4Adres := HavuzdanIPAdresiAl(IstemciMACAdres);
      if(IP4Adres.IPAdres0Mi = False) then
        DHCPTeklifMesajiGonder(AUDP, htons(ADHCPYapi^.GonderenKimlik), IP4Adres, IstemciMACAdres.MACAdres)
    end
    else if(AnaMT = DHCP_MTIP_ISTEK) then
    begin

      if(IPAdresiVerilsinMi(IstenenIP4Adres, IstemciMACAdres)) then

        DHCPIstegeOnayMesajiGonder(AUDP, htons(ADHCPYapi^.GonderenKimlik), IstenenIP4Adres, MACAdres)
      else DHCPIstegeRetMesajiGonder(AUDP, htons(ADHCPYapi^.GonderenKimlik), MACAdres);
    end
    else if(AnaMT = DHCP_BILGILENDIRME) then
    begin

      DHCPBilgilendirmeyeOnayMesajiGonder(AUDP, htons(ADHCPYapi^.GonderenKimlik), IstemciIP4, MACAdres);
    end;
  end;
end;

{==============================================================================
  istemci için havuzdan kullanýlabilir ip adresi alýr
 ==============================================================================}
function TDHCPv4Sunucu.HavuzdanIPAdresiAl(AMACAdres: TMACAdresIslev): TIP4AdresIslev;
var
  IK: PIstemciKayit;
  KullanilabilirIP: TIP4AdresIslev;
  i: TSayi4;
begin

  KullanilabilirIP.IP4Adres := GAgBaglantilari.AktifBaglanti.IP4Adresim;

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
function TDHCPv4Sunucu.IPAdresiVerilsinMi(AIstenenIP4Adres: TIP4AdresIslev;
  AMACAdres: TMACAdresIslev): Boolean;
var
  IK: PIstemciKayit;
  IP4Adres: TIP4AdresIslev;
  i: TSayi4;
  AyniAgda: Boolean;
begin

  IP4Adres := AIstenenIP4Adres;

  AyniAgda := IP4Adres.IPAgAraligiIcinde(GAgBaglantilari.AktifBaglanti.IP4Adresim);
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
procedure TDHCPv4Sunucu.DHCPTeklifMesajiGonder(AUDP: TUDP; AGonderenKimlik: TSayi4;
  ATeklifEdilenIP4Adres: TIP4AdresIslev; AMACAdres: TMACAdres);
var
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
  IP4Adres^ := GAgBaglantilari.AktifBaglanti.IP4Adresim;
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
  IP4Adres^ := GAgBaglantilari.AktifBaglanti.AltAgMaskesi;
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

  AUDP.FIP4.FHedefMACAdres := AUDP.FKaynakMACAdres;
  AUDP.FIP4.FKaynakIPAdres := ATeklifEdilenIP4Adres.IP4Adres;
  AUDP.FIP4.FHedefIPAdres := GAgBaglantilari.AktifBaglanti.IP4Adresim;

  AUDP.PaketleVeGonder(@DHCPYapi[0], DHCPYapiUzunlugu);

  FreeMem(DHCPYapi, 4096);
end;

{==============================================================================
  DHCP istemcisinin istek mesajýna onay yanýtý gönderir
 ==============================================================================}
procedure TDHCPv4Sunucu.DHCPIstegeOnayMesajiGonder(AUDP: TUDP; AGonderenKimlik: TSayi4;
  AIstenenIP4Adres: TIP4AdresIslev; AMACAdres: TMACAdresIslev);
var
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
  IP4Adres^ := GAgBaglantilari.AktifBaglanti.IP4Adresim;
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
  IP4Adres^ := GAgBaglantilari.AktifBaglanti.AltAgMaskesi;
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

  AUDP.FIP4.FHedefMACAdres := AUDP.FKaynakMACAdres;
  AUDP.FIP4.FKaynakIPAdres := AIstenenIP4Adres.IP4Adres;
  AUDP.FIP4.FHedefIPAdres := GAgBaglantilari.AktifBaglanti.IP4Adresim;

  SISTEM_MESAJ_IP4(mtUyari, RENK_PEMBE, 'DHCPv4-Sunucu: Tahsis edilen IP: ', AIstenenIP4Adres.IP4Adres);

  AUDP.PaketleVeGonder(@DHCPYapi[0], DHCPYapiUzunlugu);

  FreeMem(DHCPYapi, 4096);
end;

{==============================================================================
  DHCP istemcisine ret mesajý gönderir
 ==============================================================================}
procedure TDHCPv4Sunucu.DHCPIstegeRetMesajiGonder(AUDP: TUDP; AGonderenKimlik: TSayi4;
  AMACAdres: TMACAdresIslev);
var
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
  p1^ := DHCP_MTIP_RET;
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 3;

  Inc(p1);

  // sunucu ip adresi - 2 + 4 byte
  p1^ := DHCP_SECIM_SUNUCU_TANIMLAYICI;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IP4Adres := Isaretci(p1);
  IP4Adres^ := GAgBaglantilari.AktifBaglanti.IP4Adresim;
  Inc(IP4Adres);
  p1 := Isaretci(IP4Adres);
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 4;

  p1^ := DHCP_SECIM_SON;
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 1;

  AUDP.FIP4.FHedefMACAdres := AUDP.FKaynakMACAdres;

  // gönderen ip adresi 0.0.0.0 ise hedef adresi 255.255.255.255 olarak belirle
  if(IP4Karsilastir(AUDP.FKaynakIPAdres, IP4Adres0)) then
    AUDP.FIP4.FKaynakIPAdres := IPAdres255
  else AUDP.FIP4.FKaynakIPAdres := AUDP.FKaynakIPAdres;
  AUDP.FIP4.FHedefIPAdres := GAgBaglantilari.AktifBaglanti.IP4Adresim;

  AUDP.PaketleVeGonder(@DHCPYapi[0], DHCPYapiUzunlugu);

  FreeMem(DHCPYapi, 4096);
end;

{==============================================================================
  DHCP istemcisinin bilgilendirme mesajýna onay yanýtý gönderir
 ==============================================================================}
procedure TDHCPv4Sunucu.DHCPBilgilendirmeyeOnayMesajiGonder(AUDP: TUDP;
  AGonderenKimlik: TSayi4; AIP4Adres: TIP4AdresIslev; AMACAdres: TMACAdresIslev);
var
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
  IP4Adres^ := GAgBaglantilari.AktifBaglanti.IP4Adresim;
  Inc(IP4Adres);
  p1 := Isaretci(IP4Adres);
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 4;

  // alt að maskesi - 2 + 4 byte
  p1^ := DHCP_SECIM_ALTAG_MASKESI;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IP4Adres := Isaretci(p1);
  IP4Adres^ := GAgBaglantilari.AktifBaglanti.AltAgMaskesi;
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

  AUDP.FIP4.FHedefMACAdres := AUDP.FKaynakMACAdres;
  AUDP.FIP4.FKaynakIPAdres := AIP4Adres.IP4Adres;
  AUDP.FIP4.FHedefIPAdres := GAgBaglantilari.AktifBaglanti.IP4Adresim;

  AUDP.PaketleVeGonder(@DHCPYapi[0], DHCPYapiUzunlugu);

  FreeMem(DHCPYapi, 4096);
end;

end.
