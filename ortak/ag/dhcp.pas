{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: dhcp.pas
  Dosya Ýþlevi: DHCP protokol iþlevlerini yönetir

  Güncelleme Tarihi: 20/04/2025

  Bilgi: sadece kullanýlan sabit, deðiþken ve iþlevler türkçeye çevrilmiþtir

 ==============================================================================}
{$mode objfpc}
unit dhcp;

interface

uses paylasim;

type
  PDHCPYapi = ^TDHCPYapi;
  TDHCPYapi = packed record
  	Islem, DonanimTip, DonanimUz,
    RelayIcin: TSayi1;
  	GonderenKimlik: TSayi4;
  	Sure, Bayraklar: TSayi2;
  	IstemciIPAdres, IstemciyeAtanacakIPAdresi, SunucuIPAdres,
    AgGecidiIPAdres: TIPAdres;
  	IstemciMACAdres: TMACAdres;
  	AYRLDI1: TSayi4;
  	AYRLDI2: TSayi4;
  	AYRLDI3: TSayi2;
  	SunucuEvSahibiAdi: array[0..63] of Char;
  	AcilisDosyaAdi: array[0..127] of Char;
  	SihirliCerez: TSayi4;
  	DigerSecenekler: Isaretci;
  end;

const
  DHCP_SUNUCU_PORT                        = TSayi1(67);
  DHCP_ISTEMCI_PORT                       = TSayi1(68);

  // boot mesaj tipleri
	DHCP_BOOT_MTIP_ISTEK                    = TSayi1(1);
	DHCP_BOOT_MTIP_YANIT                    = TSayi1(2);

  // mesaj tipleri
  DHCP_UNKNOWN                            = TSayi1(0);
  DHCP_MTIP_KESIF                         = TSayi1(1);
  DHCP_MTIP_TEKLIF                        = TSayi1(2);
  DHCP_MTIP_ISTEK                         = TSayi1(3);
  DHCP_DECLINE                            = TSayi1(4);
  DHCP_MTIP_ONAY                          = TSayi1(5);
  DHCP_MTIP_RET                           = TSayi1(6);
  DHCP_RELEASE                            = TSayi1(7);
  DHCP_BILGILENDIRME                      = TSayi1(8);
  DHCP_LEASE_QUERY                        = TSayi1(10);
  DHCP_LEASE_UNASSIGNED                   = TSayi1(11);
  DHCP_LEASE_UNKNOWN                      = TSayi1(12);
  DHCP_LEASE_ACTIVE                       = TSayi1(13);

  // seçenek tipleri
  DHCP_OPTION_PAD                         = TSayi1(0);
  DHCP_SECIM_ALTAG_MASKESI                = TSayi1(1);
  DHCP_SECIM_ZAMAN_OFFSET                 = TSayi1(2);      // kullanýlmýyor
  DHCP_SECIM_YONLENDIRICI                 = TSayi1(3);
  DHCP_OPTION_TIME_SERVER                 = TSayi1(4);
  DHCP_OPTION_NAME_SERVER                 = TSayi1(5);
  DHCP_SECIM_DNS                          = TSayi1(6);
  DHCP_OPTION_LOG_SERVER                  = TSayi1(7);
  DHCP_OPTION_QUOTE_SERVER                = TSayi1(8);
  DHCP_OPTION_LPR_SERVER                  = TSayi1(9);
  DHCP_OPTION_IMPRESS_SERVER              = TSayi1(10);
  DHCP_OPTION_RESOURCE_LOCATION_SERVER    = TSayi1(11);
  DHCP_SECIM_YEREL_AD                     = TSayi1(12);
  DHCP_OPTION_BOOT_FILE_SIZE              = TSayi1(13);
  DHCP_OPTION_MERIT_DUMP_FILE             = TSayi1(14);
  DHCP_SECIM_ALAN_ADI                     = TSayi1(15);
  DHCP_OPTION_SWAP_SERVER                 = TSayi1(16);
  DHCP_SECIM_KOK_YOL                      = TSayi1(17);
  DHCP_OPTION_EXTENSION_PATH              = TSayi1(18);
  DHCP_OPTION_IP_FWD_CONTROL              = TSayi1(19);
  DHCP_OPTION_NL_SRC_ROUTING              = TSayi1(20);
  DHCP_OPTION_POLICY_FILTER               = TSayi1(21);
  DHCP_OPTION_MAX_DG_REASSEMBLY_SIZE      = TSayi1(22);
  DHCP_OPTION_DEFAULT_IP_TTL              = TSayi1(23);
  DHCP_OPTION_PATH_MTU_AGING_TIMEOUT      = TSayi1(24);
  DHCP_OPTION_PATH_MTU_PLATEAU_TABLE      = TSayi1(25);
  DHCP_SECIM_ARABIRIM_MTU                 = TSayi1(26);
  DHCP_OPTION_ALL_SUBNETS_LOCAL           = TSayi1(27);
  DHCP_SECIM_YAYIN_ADRESI                 = TSayi1(28);
  DHCP_OPTION_PERFORM_MASK_DISCOVERY      = TSayi1(29);
  DHCP_OPTION_MASK_SUPPLIER               = TSayi1(30);
  DHCP_SECIM_YONLENDIRICI_KESIF_UYGULA    = TSayi1(31);
  DHCP_OPTION_ROUTER_SOLICIT_ADDRESS      = TSayi1(32);
  DHCP_SECIM_SABIT_YONLENDIRME_TABLOSU    = TSayi1(33);
  DHCP_OPTION_TRAILER_ENCAP               = TSayi1(34);
  DHCP_OPTION_ARP_CACHE_TIMEOUT           = TSayi1(35);
  DHCP_OPTION_ETHERNET_ENCAP              = TSayi1(36);
  DHCP_OPTION_DEFAULT_TCP_TTL             = TSayi1(37);
  DHCP_OPTION_TCP_KEEPALIVE_INTERVAL      = TSayi1(38);
  DHCP_OPTION_TCP_KEEPALIVE_GARBAGE       = TSayi1(39);
  DHCP_SECIM_NIS_ALANADI                  = TSayi1(40);
  DHCP_SECIM_NIS_SUNUCULAR                = TSayi1(41);
  DHCP_SECIM_NTP_SUNUCULAR                = TSayi1(42);
  DHCP_SECIM_SATICI_OZEL_BILGI            = TSayi1(43);
  DHCP_SECIM_NETBIOS_TCP_NS_ILE           = TSayi1(44);
  DHCP_OPTION_NETBIOS_OVER_TCP_DG_DS      = TSayi1(45);
  DHCP_SECIM_NETBIOS_TCP_DUGUM_TIP_ILE    = TSayi1(46);
  DHCP_SECIM_NETBIOS_TCP_KAPSAM_ILE       = TSayi1(47);
  DHCP_OPTION_XWINDOW_FONT_SERVER         = TSayi1(48);
  DHCP_OPTION_XWINDOW_SYSTEM_DISP_MGR     = TSayi1(49);
  DHCP_SECIM_ISTEK_IP_ADRES               = TSayi1(50);
  DHCP_SECIM_IP_KIRALAMA_SURESI           = TSayi1(51);
  DHCP_OPTION_OVERLOAD                    = TSayi1(52);
  DHCP_SECIM_MESAJ_TIP                    = TSayi1(53);
  DHCP_SECIM_SUNUCU_TANIMLAYICI           = TSayi1(54);
  DHCP_SECIM_DEGISKEN_ISTEK_LISTESI       = TSayi1(55);
  DHCP_OPTION_MESSAGE                     = TSayi1(56);
  DHCP_SECIM_AZAMI_DHCP_MESAJ_UZUNLUK     = TSayi1(57);
  DHCP_SECIM_YENILEME_SURESI              = TSayi1(58);
  DHCP_SECIM_YENIDEN_BAGLAMA_SURESI       = TSayi1(59);
  DHCP_SECIM_SATICI_SINIF_TANITICISI      = TSayi1(60);
  DHCP_SECIM_ISTEMCI_KIMLIK               = TSayi1(61);
  DHCP_OPTION_NETWARE_IP_DOMAIN_NAME      = TSayi1(62);
  DHCP_OPTION_NETWARE_IP_INFO             = TSayi1(63);
  DHCP_OPTION_NIS_PLUS_DOMAIN             = TSayi1(64);
  DHCP_OPTION_NIS_PLUS_SERVERS            = TSayi1(65);
  DHCP_OPTION_TFTP_SERVER_NAME            = TSayi1(66);
  DHCP_OPTION_BOOTFILE_NAME               = TSayi1(67);
  DHCP_OPTION_MOBILE_IP_HA                = TSayi1(68);
  DHCP_OPTION_SMTP_SERVER                 = TSayi1(69);
  DHCP_OPTION_POP_SERVER                  = TSayi1(70);
  DHCP_OPTION_NNTP_SERVER                 = TSayi1(71);
  DHCP_OPTION_DEFAULT_WWW_SERVER          = TSayi1(72);
  DHCP_OPTION_DEFAULT_FINGER_SERVER       = TSayi1(73);
  DHCP_OPTION_DEFAULT_IRC_SERVER          = TSayi1(74);
  DHCP_OPTION_STREETTALK_SERVER           = TSayi1(75);
  DHCP_OPTION_STREETTALK_DA_SERVER        = TSayi1(76);
  DHCP_OPTION_USER_CLASS_INFO             = TSayi1(77);
  DHCP_OPTION_SLP_DIRECTORY_AGENT         = TSayi1(78);
  DHCP_OPTION_SLP_SERVICE_SCOPE           = TSayi1(79);
  DHCP_OPTION_RAPID_COMMIT                = TSayi1(80);
  DHCP_SECIM_TAM_ISTEMCI_ADI              = TSayi1(81);
  DHCP_OPTION_82                          = TSayi1(82);
  DHCP_OPTION_STORAGE_NS                  = TSayi1(83);
  // ignoring option 84 (removed / unassigned)
  DHCP_OPTION_NDS_SERVERS                 = TSayi1(85);
  DHCP_OPTION_NDS_TREE_NAME               = TSayi1(86);
  DHCP_OPTION_NDS_CONTEXT                 = TSayi1(87);
  DHCP_OPTION_BCMCS_DN_LIST               = TSayi1(88);
  DHCP_OPTION_BCMCS_ADDR_LIST             = TSayi1(89);
  DHCP_OPTION_AUTH                        = TSayi1(90);
  DHCP_OPTION_CLIENT_LAST_XTIME           = TSayi1(91);
  DHCP_OPTION_ASSOCIATE_IP                = TSayi1(92);
  DHCP_OPTION_CLIENT_SYSARCH_TYPE         = TSayi1(93);
  DHCP_OPTION_CLIENT_NW_INTERFACE_ID      = TSayi1(94);
  DHCP_OPTION_LDAP                        = TSayi1(95);
  // ignoring 96 (removed / unassigned)
  DHCP_OPTION_CLIENT_MACHINE_ID           = TSayi1(97);
  DHCP_OPTION_OPENGROUP_USER_AUTH         = TSayi1(98);
  DHCP_OPTION_GEOCONF_CIVIC               = TSayi1(99);
  DHCP_OPTION_IEEE_1003_1_TZ              = TSayi1(100);
  DHCP_OPTION_REF_TZ_DB                   = TSayi1(101);
  // ignoring 102 to 111 & 115 (removed / unassigned)
  DHCP_OPTION_NETINFO_PARENT_SERVER_ADDR  = TSayi1(112);
  DHCP_OPTION_NETINFO_PARENT_SERVER_TAG   = TSayi1(113);
  DHCP_OPTION_URL                         = TSayi1(114);
  DHCP_SECIM_OTO_AYAR                     = TSayi1(116);
  DHCP_OPTION_NAME_SERVICE_SEARCH         = TSayi1(117);
  DHCP_OPTION_SUBNET_SELECTION            = TSayi1(118);
  DHCP_SECIM_DNS_ALANADI_ARAMA_LISTESI    = TSayi1(119);
  DHCP_OPTION_SIP_SERVERS                 = TSayi1(120);
  DHCP_SECIM_SINIFDISI_YONLENDIRME        = TSayi1(121);
  DHCP_OPTION_CCC                         = TSayi1(122);
  DHCP_OPTION_GEOCONF                     = TSayi1(123);
  DHCP_OPTION_VENDOR_ID_VENDOR_CLASS      = TSayi1(124);
  DHCP_OPTION_VENDOR_ID_VENDOR_SPECIFIC   = TSayi1(125);
  // ignoring 126, 127 (removed / unassigned)
  // options 128 - 135 arent officially assigned to PXE
  DHCP_OPTION_TFTP_SERVER                 = TSayi1(128);
  DHCP_OPTION_PXE_VENDOR_SPECIFIC_129     = TSayi1(129);
  DHCP_OPTION_PXE_VENDOR_SPECIFIC_130     = TSayi1(130);
  DHCP_OPTION_PXE_VENDOR_SPECIFIC_131     = TSayi1(131);
  DHCP_OPTION_PXE_VENDOR_SPECIFIC_132     = TSayi1(132);
  DHCP_OPTION_PXE_VENDOR_SPECIFIC_133     = TSayi1(133);
  DHCP_OPTION_PXE_VENDOR_SPECIFIC_134     = TSayi1(134);
  DHCP_OPTION_PXE_VENDOR_SPECIFIC_135     = TSayi1(135);
  DHCP_OPTION_PANA_AUTH_AGENT             = TSayi1(136);
  DHCP_OPTION_LOST_SERVER                 = TSayi1(137);
  DHCP_OPTION_CAPWAP_AC_ADDRESS           = TSayi1(138);
  DHCP_OPTION_IPV4_ADDRESS_MOS            = TSayi1(139);
  DHCP_OPTION_IPV4_FQDN_MOS               = TSayi1(140);
  DHCP_OPTION_SIP_UA_CONFIG_DOMAIN        = TSayi1(141);
  DHCP_OPTION_IPV4_ADDRESS_ANDSF          = TSayi1(142);
  DHCP_OPTION_GEOLOC                      = TSayi1(144);
  DHCP_OPTION_FORCERENEW_NONCE_CAP        = TSayi1(145);
  DHCP_OPTION_RDNSS_SELECTION             = TSayi1(146);
  // ignoring options 143, 147 - 149 (removed / unassigned)
  // option 150 is also assigned as Etherboot, GRUB configuration path name
  DHCP_OPTION_TFTP_SERVER_ADDRESS         = TSayi1(150);
  DHCP_OPTION_STATUS_CODE                 = TSayi1(151);
  DHCP_OPTION_BASE_TIME                   = TSayi1(152);
  DHCP_OPTION_START_TIME_OF_STATE         = TSayi1(153);
  DHCP_OPTION_QUERY_START_TIME            = TSayi1(154);
  DHCP_OPTION_QUERY_END_TIME              = TSayi1(155);
  DHCP_OPTION_DHCP_STATE                  = TSayi1(156);
  DHCP_OPTION_DATA_SOURCE                 = TSayi1(157);
  DHCP_OPTION_PCP_SERVER                  = TSayi1(158);
  // ignoring options 159 - 174 (removed / unassigned)
  // ignoring options 175 - 177 (tentatively assigned)
  // ignoring options 178 - 207 (removed / unassigned)
  DHCP_OPTION_PXELINUX_MAGIC              = TSayi1(208);  // deprecated
  DHCP_OPTION_CONFIG_FILE                 = TSayi1(209);
  DHCP_OPTION_PATH_PREFIX                 = TSayi1(210);
  DHCP_OPTION_REBOOT_TIME                 = TSayi1(211);
  DHCP_OPTION_6RD                         = TSayi1(212);
  DHCP_OPTION_V4_ACCESS_DOMAIN            = TSayi1(213);
  // ignoring options 214 - 219 (removed / unassigned)
  DHCP_OPTION_SUBNET_ALLOCATION           = TSayi1(220);
  DHCP_OPTION_VSS                         = TSayi1(221);
  // ignoring options 222 - 254 (removed / unassigned) ???
  DHCP_SECIM_OZEL_SINIFSIZ_YONLENDIRME    = TSayi1(249);
  DHCP_SECIM_OZEL_PROXY_OTOKESIF          = TSayi1(252);
  DHCP_SECIM_SON                          = TSayi1(255);

  DHCP_SIHIRLI_CEREZ                      = TSayi4($63825363);    // network byte sýralý kodlama
  DHCP_GONDEREN_KIMLIK                    = TSayi4($3903F328);

type
  PDHCPMesaj = ^TDHCPMesaj;
  TDHCPMesaj = packed record
    Tip: TSayi1;
    Uzunluk: TSayi1;
    Mesaj: Isaretci;
  end;

procedure DHCPIpAdresiAl;
{ Discover }
procedure DHCPKesifMesajiGonder;
{ Offer }
procedure DHCPTeklifMesajiGonder(AGonderenKimlik: TSayi4; ATeklifEdilenIPAdresi: TIPAdres;
  AMACAdres: TMACAdres);
{ Request }
procedure DHCPIstekMesajiGonder(ADHCPSunucuIPAdresi, AIstenenIPAdresi: TIPAdres);
{ Request -> Ack }
procedure DHCPIstegeOnayMesajiGonder(AGonderenKimlik: TSayi4; AIstenenIPAdresi: TIPAdres;
  AMACAdres: TMACAdres);
{ Inform }
procedure DHCPBilgilendirmeMesajiGonder(AIstemciIPAdres: TIPAdres);
{ Inform -> Ack }
procedure DHCPBilgilendirmeyeOnayMesajiGonder(AGonderenKimlik: TSayi4; AIPAdres: TIPAdres;
  AMACAdres: TMACAdres);
{ NAck }
procedure DHCPRetMesajiGonder(AGonderenKimlik: TSayi4; AMACAdres: TMACAdres);

implementation

uses genel, baglanti, donusum, islevler, sistemmesaj;

procedure DHCPIpAdresiAl;
begin

  DHCPKesifMesajiGonder;
end;

// DHCP sunucusuna keþif mesajý gönderir
procedure DHCPKesifMesajiGonder;
var
  B: PBaglanti;
  DHCPYapi: PDHCPYapi;
  MACAdres: PMACAdres;
  i: TSayi1;
  p1: PSayi1;
  pc: PChar;
  DHCPYapiUzunlugu: TSayi4;
  IPAdresi: string;
begin

  DHCPYapi := GetMem(4096);

	DHCPYapi^.Islem := DHCP_BOOT_MTIP_ISTEK;
	DHCPYapi^.DonanimTip := 1;		      // ethernet
	DHCPYapi^.DonanimUz := 6;		        // mac uzunluðu
	DHCPYapi^.RelayIcin := 0;
	DHCPYapi^.GonderenKimlik := ntohs(DHCP_GONDEREN_KIMLIK);
	DHCPYapi^.Sure := 0;
	DHCPYapi^.Bayraklar := 0;
	DHCPYapi^.IstemciIPAdres := IPAdres0;
	DHCPYapi^.IstemciyeAtanacakIPAdresi := IPAdres0;
	DHCPYapi^.SunucuIPAdres := IPAdres0;
	DHCPYapi^.AgGecidiIPAdres := IPAdres0;

  // IstemciMACAdres 6 + 10 = 16 byte
  DHCPYapi^.IstemciMACAdres := GAgBilgisi.MACAdres;
	DHCPYapi^.AYRLDI1 := 0;
	DHCPYapi^.AYRLDI2 := 0;
	DHCPYapi^.AYRLDI3 := 0;

  FillChar(DHCPYapi^.SunucuEvSahibiAdi, 64, #0);
  FillChar(DHCPYapi^.AcilisDosyaAdi, 128, #0);
	DHCPYapi^.SihirliCerez := ntohs(DHCP_SIHIRLI_CEREZ);

  // en sondaki iþaretçi hariç (DigerSecenekler) yapý uzunluðu
  DHCPYapiUzunlugu := SizeOf(TDHCPYapi) - 4;

  // diðer seçenekler
  p1 := @DHCPYapi^.DigerSecenekler;

  // dhcp mesaj kodlamasý
  // 1. byte = mesaj tip, 2. byte = mesajýn uzunluðu, 3. byte = mesajýn kendisi

  // dhcp mesaj tipi
  p1^ := DHCP_SECIM_MESAJ_TIP;
  Inc(p1);
  p1^ := 1;
  Inc(p1);
  p1^ := DHCP_MTIP_KESIF;
  DHCPYapiUzunlugu += 2 + 1;

  Inc(p1);

  p1^ := DHCP_SECIM_ISTEMCI_KIMLIK;
  Inc(p1);
  p1^ := 7;                               // uzunluk
  Inc(p1);
  p1^ := 1;
  Inc(p1);                                // donaným tipi = 1 (ethernet)
  MACAdres := PMACAdres(p1);
  MACAdres^ := GAgBilgisi.MACAdres;
  DHCPYapiUzunlugu += 2 + 1 + 6;

  Inc(p1, 6);

  // bilgisayar adý
  i := Length(GTamBilgisayarAdi);
  p1^ := DHCP_SECIM_YEREL_AD;
  Inc(p1);
  PByte(p1)^ := i;
  Inc(p1);
  pc := Isaretci(p1);
  Tasi2(@GTamBilgisayarAdi[1], pc, i);
  Inc(pc, i);
  p1 := Isaretci(pc);
  DHCPYapiUzunlugu += 2 + i;

  // parametre istek listesi - 2 + 12 byte
  p1^ := DHCP_SECIM_DEGISKEN_ISTEK_LISTESI;
  Inc(p1);
  p1^ := 12;                              // uzunluk
  Inc(p1);
  p1^ := DHCP_SECIM_ALTAG_MASKESI;
  Inc(p1);
  p1^ := DHCP_SECIM_YONLENDIRICI;
  Inc(p1);
  p1^ := DHCP_SECIM_DNS;
  Inc(p1);
  p1^ := DHCP_SECIM_YONLENDIRICI_KESIF_UYGULA;
  Inc(p1);
  p1^ := DHCP_SECIM_SABIT_YONLENDIRME_TABLOSU;
  Inc(p1);
  p1^ := DHCP_SECIM_ALAN_ADI;
  Inc(p1);
  p1^ := DHCP_SECIM_SATICI_OZEL_BILGI;
  Inc(p1);
  p1^ := DHCP_SECIM_NETBIOS_TCP_NS_ILE;
  Inc(p1);
  p1^ := DHCP_SECIM_NETBIOS_TCP_DUGUM_TIP_ILE;
  Inc(p1);
  p1^ := DHCP_SECIM_NETBIOS_TCP_KAPSAM_ILE;
  Inc(p1);
  p1^ := DHCP_SECIM_SINIFDISI_YONLENDIRME;
  Inc(p1);
  p1^ := DHCP_SECIM_OZEL_SINIFSIZ_YONLENDIRME;
  DHCPYapiUzunlugu += 2 + 12;

  Inc(p1);

  p1^ := DHCP_SECIM_SON;
  DHCPYapiUzunlugu += 1;

  IPAdresi := IP_KarakterKatari(IPAdres255);
  B := Baglantilar0.BaglantiOlustur(ptUDP, IPAdresi, DHCP_ISTEMCI_PORT, DHCP_SUNUCU_PORT);
  if not(B = nil) then
  begin

    if(Baglantilar0.Baglan(B^.Kimlik, btYayin) <> -1) then
    begin

      Baglantilar0.Yaz(B^.Kimlik, @DHCPYapi[0], DHCPYapiUzunlugu);

      Baglantilar0.BaglantiyiKes(B^.Kimlik);
    end;
  end;

  FreeMem(DHCPYapi, 4096);
end;

// DHCP istemcisine teklif mesajý gönderir
procedure DHCPTeklifMesajiGonder(AGonderenKimlik: TSayi4; ATeklifEdilenIPAdresi: TIPAdres;
  AMACAdres: TMACAdres);
var
  B: PBaglanti;
  DHCPYapi: PDHCPYapi;
  IPAdres: PIPAdres;
  p1: PSayi1;
  p4: PSayi4;
  DHCPYapiUzunlugu: TSayi4;
  IPAdresi: string;
begin

  DHCPYapi := GetMem(4096);

	DHCPYapi^.Islem := DHCP_BOOT_MTIP_YANIT;
	DHCPYapi^.DonanimTip := 1;		      // ethernet
	DHCPYapi^.DonanimUz := 6;		        // mac uzunluðu
	DHCPYapi^.RelayIcin := 0;
	DHCPYapi^.GonderenKimlik := ntohs(AGonderenKimlik);
	DHCPYapi^.Sure := 0;
	DHCPYapi^.Bayraklar := 0;
	DHCPYapi^.IstemciIPAdres := IPAdres0;
	DHCPYapi^.IstemciyeAtanacakIPAdresi := ATeklifEdilenIPAdresi;
	DHCPYapi^.SunucuIPAdres := IPAdres0;
	DHCPYapi^.AgGecidiIPAdres := IPAdres0;

  // IstemciMACAdres 6 + 10 = 16 byte
  DHCPYapi^.IstemciMACAdres := AMACAdres;
	DHCPYapi^.AYRLDI1 := 0;
	DHCPYapi^.AYRLDI2 := 0;
	DHCPYapi^.AYRLDI3 := 0;

  FillChar(DHCPYapi^.SunucuEvSahibiAdi, 64, #0);
  FillChar(DHCPYapi^.AcilisDosyaAdi, 128, #0);
	DHCPYapi^.SihirliCerez := ntohs(DHCP_SIHIRLI_CEREZ);

  // en sondaki iþaretçi hariç (DigerSecenekler) yapý uzunluðu
  DHCPYapiUzunlugu := SizeOf(TDHCPYapi) - 4;

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
  DHCPYapiUzunlugu += 2 + 1;

  Inc(p1);

  // sunucu ip adresi - 2 + 4 byte
  p1^ := DHCP_SECIM_SUNUCU_TANIMLAYICI;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IPAdres := Isaretci(p1);
  IPAdres^ := GAgBilgisi.IP4Adres;
  Inc(IPAdres);
  p1 := Isaretci(IPAdres);
  DHCPYapiUzunlugu += 2 + 4;

  p1^ := DHCP_SECIM_IP_KIRALAMA_SURESI;
  Inc(p1);
  p1^ := 4;                               // uzunluk
  Inc(p1);
  p4 := Isaretci(p1);
  p4^ := htons(TSayi4(8 * 60 * 60));      // saniye cinsinden
  Inc(p4);
  p1 := Isaretci(p4);
  DHCPYapiUzunlugu += 2 + 4;

  p1^ := DHCP_SECIM_YENILEME_SURESI;
  Inc(p1);
  p1^ := 4;                               // uzunluk
  Inc(p1);
  p4 := Isaretci(p1);
  p4^ := htons(TSayi4(4 * 60 * 60));      // saniye cinsinden
  Inc(p4);
  p1 := Isaretci(p4);
  DHCPYapiUzunlugu += 2 + 4;

  p1^ := DHCP_SECIM_YENIDEN_BAGLAMA_SURESI;
  Inc(p1);
  p1^ := 4;                               // uzunluk
  Inc(p1);
  p4 := Isaretci(p1);
  p4^ := htons(TSayi4(4 * 60 * 60));      // saniye cinsinden
  Inc(p4);
  p1 := Isaretci(p4);
  DHCPYapiUzunlugu += 2 + 4;

  // alt að maskesi - 2 + 4 byte
  p1^ := DHCP_SECIM_ALTAG_MASKESI;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IPAdres := Isaretci(p1);
  IPAdres^ := OnDegerAltAgMaskesi;
  Inc(IPAdres);
  p1 := Isaretci(IPAdres);
  DHCPYapiUzunlugu += 2 + 4;

  // alt að maskesi - 2 + 4 byte
  p1^ := DHCP_SECIM_YONLENDIRICI;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IPAdres := Isaretci(p1);
  IPAdres^ := GAgGecidi;
  Inc(IPAdres);
  p1 := Isaretci(IPAdres);
  DHCPYapiUzunlugu += 2 + 4;

  // dns sunucusu - 2 + 4 byte
  p1^ := DHCP_SECIM_DNS;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IPAdres := Isaretci(p1);
  IPAdres^ := GDNSIPAdresi;
  Inc(IPAdres);
  p1 := Isaretci(IPAdres);
  DHCPYapiUzunlugu += 2 + 4;

  p1^ := DHCP_SECIM_SON;
  DHCPYapiUzunlugu += 1;

  IPAdresi := IP_KarakterKatari(ATeklifEdilenIPAdresi);
  B := Baglantilar0.BaglantiOlustur(ptUDP, IPAdresi, DHCP_SUNUCU_PORT, DHCP_ISTEMCI_PORT);
  if not(B = nil) then
  begin

    if(Baglantilar0.Baglan(B^.Kimlik, btYayin) <> -1) then
    begin

      Baglantilar0.Yaz(B^.Kimlik, @DHCPYapi[0], DHCPYapiUzunlugu);

      Baglantilar0.BaglantiyiKes(B^.Kimlik);
    end;
  end;

  FreeMem(DHCPYapi, 4096);
end;

// DHCP sunucusuna istek mesajý gönderir
procedure DHCPIstekMesajiGonder(ADHCPSunucuIPAdresi, AIstenenIPAdresi: TIPAdres);
var
  B: PBaglanti;
  DHCPYapi: PDHCPYapi;
  IPAdres: PIPAdres;
  MACAdres: PMACAdres;
  i: TSayi1;
  p1: PSayi1;
  pc: PChar;
  DHCPYapiUzunlugu: TSayi4;
  IPAdresi: string;
begin

  DHCPYapi := GetMem(4096);

	DHCPYapi^.Islem := DHCP_BOOT_MTIP_ISTEK;
	DHCPYapi^.DonanimTip := 1;		      // ethernet
	DHCPYapi^.DonanimUz := 6;		        // mac uzunluðu
	DHCPYapi^.RelayIcin := 0;
	DHCPYapi^.GonderenKimlik := ntohs(DHCP_GONDEREN_KIMLIK);
	DHCPYapi^.Sure := 0;
	DHCPYapi^.Bayraklar := 0;
	DHCPYapi^.IstemciIPAdres := IPAdres0;
	DHCPYapi^.IstemciyeAtanacakIPAdresi := IPAdres0;
	DHCPYapi^.SunucuIPAdres := IPAdres0;
	DHCPYapi^.AgGecidiIPAdres := IPAdres0;

  // IstemciMACAdres 6 + 10 = 16 byte
  DHCPYapi^.IstemciMACAdres := GAgBilgisi.MACAdres;
	DHCPYapi^.AYRLDI1 := 0;
	DHCPYapi^.AYRLDI2 := 0;
	DHCPYapi^.AYRLDI3 := 0;

  FillChar(DHCPYapi^.SunucuEvSahibiAdi, 64, #0);
  FillChar(DHCPYapi^.AcilisDosyaAdi, 128, #0);
	DHCPYapi^.SihirliCerez := ntohs(DHCP_SIHIRLI_CEREZ);

  // en sondaki iþaretçi hariç (DigerSecenekler) yapý uzunluðu
  DHCPYapiUzunlugu := SizeOf(TDHCPYapi) - 4;

  // diðer seçenekler
  p1 := @DHCPYapi^.DigerSecenekler;

  // dhcp mesaj kodlamasý
  // 1. byte = mesaj tip, 2. byte = mesajýn uzunluðu, 3. byte = mesajýn kendisi

  // dhcp mesaj tipi
  p1^ := DHCP_SECIM_MESAJ_TIP;
  Inc(p1);
  p1^ := 1;
  Inc(p1);
  p1^ := DHCP_MTIP_ISTEK;
  DHCPYapiUzunlugu += 2 + 1;

  Inc(p1);

  p1^ := DHCP_SECIM_ISTEMCI_KIMLIK;
  Inc(p1);
  p1^ := 7;                               // uzunluk
  Inc(p1);
  p1^ := 1;
  Inc(p1);                                // donaným tipi = 1 (ethernet)
  MACAdres := PMACAdres(p1);
  MACAdres^ := GAgBilgisi.MACAdres;
  DHCPYapiUzunlugu += 2 + 1 + 6;

  Inc(p1, 6);

  // istenen ip adresi - 2 + 4 byte
  p1^ := DHCP_SECIM_ISTEK_IP_ADRES;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IPAdres := Isaretci(p1);
  IPAdres^ := AIstenenIPAdresi;
  Inc(IPAdres);
  p1 := Isaretci(IPAdres);
  DHCPYapiUzunlugu += 2 + 4;

  // istenen ip adresi - 2 + 4 byte
  p1^ := DHCP_SECIM_SUNUCU_TANIMLAYICI;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IPAdres := Isaretci(p1);
  IPAdres^ := ADHCPSunucuIPAdresi;
  Inc(IPAdres);
  p1 := Isaretci(IPAdres);
  DHCPYapiUzunlugu += 2 + 4;

  // bilgisayar adý
  i := Length(GTamBilgisayarAdi);
  p1^ := DHCP_SECIM_YEREL_AD;
  Inc(p1);
  PByte(p1)^ := i;
  Inc(p1);
  pc := Isaretci(p1);
  Tasi2(@GTamBilgisayarAdi[1], pc, i);
  Inc(pc, i);
  p1 := Isaretci(pc);
  DHCPYapiUzunlugu += 2 + i;

  // tam bilgisayar adý - (domain adý dahil)
  i := Length(GTamBilgisayarAdi);
  p1^ := DHCP_SECIM_TAM_ISTEMCI_ADI;
  Inc(p1);
  PByte(p1)^ := 3 + i;
  Inc(p1);
  PByte(p1)^ := 0;
  Inc(p1);
  PByte(p1)^ := 0;
  Inc(p1);
  PByte(p1)^ := 0;
  Inc(p1);
  pc := Isaretci(p1);
  Tasi2(@GTamBilgisayarAdi[1], pc, i);
  Inc(pc, i);
  p1 := Isaretci(pc);
  DHCPYapiUzunlugu += 2 + 3 + i;

  // parametre istek listesi - 2 + 12 byte
  p1^ := DHCP_SECIM_DEGISKEN_ISTEK_LISTESI;
  Inc(p1);
  p1^ := 12;                              // uzunluk
  Inc(p1);
  p1^ := DHCP_SECIM_ALTAG_MASKESI;
  Inc(p1);
  p1^ := DHCP_SECIM_YONLENDIRICI;
  Inc(p1);
  p1^ := DHCP_SECIM_DNS;
  Inc(p1);
  p1^ := DHCP_SECIM_ALAN_ADI;
  Inc(p1);
  p1^ := DHCP_SECIM_YONLENDIRICI_KESIF_UYGULA;
  Inc(p1);
  p1^ := DHCP_SECIM_SABIT_YONLENDIRME_TABLOSU;
  Inc(p1);
  p1^ := DHCP_SECIM_SATICI_OZEL_BILGI;
  Inc(p1);
  p1^ := DHCP_SECIM_NETBIOS_TCP_NS_ILE;
  Inc(p1);
  p1^ := DHCP_SECIM_NETBIOS_TCP_DUGUM_TIP_ILE;
  Inc(p1);
  p1^ := DHCP_SECIM_NETBIOS_TCP_KAPSAM_ILE;
  Inc(p1);
  p1^ := DHCP_SECIM_SINIFDISI_YONLENDIRME;
  Inc(p1);
  p1^ := DHCP_SECIM_OZEL_SINIFSIZ_YONLENDIRME;
  DHCPYapiUzunlugu += 2 + 12;

  Inc(p1);

  p1^ := DHCP_SECIM_SON;
  DHCPYapiUzunlugu += 1;

  IPAdresi := IP_KarakterKatari(IPAdres255);
  B := Baglantilar0.BaglantiOlustur(ptUDP, IPAdresi, DHCP_ISTEMCI_PORT, DHCP_SUNUCU_PORT);
  if not(B = nil) then
  begin

    if(Baglantilar0.Baglan(B^.Kimlik, btYayin) <> -1) then
    begin

      Baglantilar0.Yaz(B^.Kimlik, @DHCPYapi[0], DHCPYapiUzunlugu);

      Baglantilar0.BaglantiyiKes(B^.Kimlik);
    end;
  end;

  FreeMem(DHCPYapi, 4096);
end;

// DHCP istemcisinin istek mesajýna onay yanýtý gönderir
procedure DHCPIstegeOnayMesajiGonder(AGonderenKimlik: TSayi4; AIstenenIPAdresi: TIPAdres;
  AMACAdres: TMACAdres);
var
  B: PBaglanti;
  DHCPYapi: PDHCPYapi;
  IPAdres: PIPAdres;
  i: TSayi1;
  p1: PSayi1;
  p4: PSayi4;
  pc: PChar;
  DHCPYapiUzunlugu: TSayi4;
  IPAdresi: string;
begin

  DHCPYapi := GetMem(4096);

	DHCPYapi^.Islem := DHCP_BOOT_MTIP_YANIT;
	DHCPYapi^.DonanimTip := 1;		      // ethernet
	DHCPYapi^.DonanimUz := 6;		        // mac uzunluðu
	DHCPYapi^.RelayIcin := 0;
	DHCPYapi^.GonderenKimlik := ntohs(AGonderenKimlik);
	DHCPYapi^.Sure := 0;
	DHCPYapi^.Bayraklar := 0;
	DHCPYapi^.IstemciIPAdres := IPAdres0;
	DHCPYapi^.IstemciyeAtanacakIPAdresi := AIstenenIPAdresi;
	DHCPYapi^.SunucuIPAdres := IPAdres0;
	DHCPYapi^.AgGecidiIPAdres := IPAdres0;

  // IstemciMACAdres 6 + 10 = 16 byte
  DHCPYapi^.IstemciMACAdres := AMACAdres;
	DHCPYapi^.AYRLDI1 := 0;
	DHCPYapi^.AYRLDI2 := 0;
	DHCPYapi^.AYRLDI3 := 0;

  FillChar(DHCPYapi^.SunucuEvSahibiAdi, 64, #0);
  FillChar(DHCPYapi^.AcilisDosyaAdi, 128, #0);
	DHCPYapi^.SihirliCerez := ntohs(DHCP_SIHIRLI_CEREZ);

  // en sondaki iþaretçi hariç (DigerSecenekler) yapý uzunluðu
  DHCPYapiUzunlugu := SizeOf(TDHCPYapi) - 4;

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
  DHCPYapiUzunlugu += 2 + 1;

  Inc(p1);

  // sunucu ip adresi - 2 + 4 byte
  p1^ := DHCP_SECIM_SUNUCU_TANIMLAYICI;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IPAdres := Isaretci(p1);
  IPAdres^ := GAgBilgisi.IP4Adres;
  Inc(IPAdres);
  p1 := Isaretci(IPAdres);
  DHCPYapiUzunlugu += 2 + 4;

  p1^ := DHCP_SECIM_IP_KIRALAMA_SURESI;
  Inc(p1);
  p1^ := 4;                               // uzunluk
  Inc(p1);
  p4 := Isaretci(p1);
  p4^ := htons(TSayi4(8 * 60 * 60));      // saniye cinsinden
  Inc(p4);
  p1 := Isaretci(p4);
  DHCPYapiUzunlugu += 2 + 4;

  p1^ := DHCP_SECIM_YENILEME_SURESI;
  Inc(p1);
  p1^ := 4;                               // uzunluk
  Inc(p1);
  p4 := Isaretci(p1);
  p4^ := htons(TSayi4(4 * 60 * 60));      // saniye cinsinden
  Inc(p4);
  p1 := Isaretci(p4);
  DHCPYapiUzunlugu += 2 + 4;

  p1^ := DHCP_SECIM_YENIDEN_BAGLAMA_SURESI;
  Inc(p1);
  p1^ := 4;                               // uzunluk
  Inc(p1);
  p4 := Isaretci(p1);
  p4^ := htons(TSayi4(4 * 60 * 60));      // saniye cinsinden
  Inc(p4);
  p1 := Isaretci(p4);
  DHCPYapiUzunlugu += 2 + 4;

  // alt að maskesi - 2 + 4 byte
  p1^ := DHCP_SECIM_ALTAG_MASKESI;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IPAdres := Isaretci(p1);
  IPAdres^ := OnDegerAltAgMaskesi;
  Inc(IPAdres);
  p1 := Isaretci(IPAdres);
  DHCPYapiUzunlugu += 2 + 4;

  // alt að maskesi - 2 + 4 byte
  p1^ := DHCP_SECIM_YONLENDIRICI;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IPAdres := Isaretci(p1);
  IPAdres^ := GAgGecidi;
  Inc(IPAdres);
  p1 := Isaretci(IPAdres);
  DHCPYapiUzunlugu += 2 + 4;

  // dns sunucusu - 2 + 4 byte
  p1^ := DHCP_SECIM_DNS;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IPAdres := Isaretci(p1);
  IPAdres^ := GDNSIPAdresi;
  Inc(IPAdres);
  p1 := Isaretci(IPAdres);
  DHCPYapiUzunlugu += 2 + 4;

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
  DHCPYapiUzunlugu += 2 + i + 1;

  p1^ := DHCP_SECIM_SON;
  DHCPYapiUzunlugu += 1;

  IPAdresi := IP_KarakterKatari(AIstenenIPAdresi);
  B := Baglantilar0.BaglantiOlustur(ptUDP, IPAdresi, DHCP_SUNUCU_PORT, DHCP_ISTEMCI_PORT);
  if not(B = nil) then
  begin

    if(Baglantilar0.Baglan(B^.Kimlik, btYayin) <> -1) then
    begin

      Baglantilar0.Yaz(B^.Kimlik, @DHCPYapi[0], DHCPYapiUzunlugu);

      Baglantilar0.BaglantiyiKes(B^.Kimlik);
    end;
  end;

  FreeMem(DHCPYapi, 4096);
end;

// DHCP sunucusuna bilgilendirme mesajý gönderir
procedure DHCPBilgilendirmeMesajiGonder(AIstemciIPAdres: TIPAdres);
var
  B: PBaglanti;
  DHCPYapi: PDHCPYapi;
  MACAdres: PMACAdres;
  i: TSayi1;
  p1: PSayi1;
  pc: PChar;
  DHCPYapiUzunlugu: TSayi4;
  IPAdresi: string;
begin

  DHCPYapi := GetMem(4096);

	DHCPYapi^.Islem := DHCP_BOOT_MTIP_ISTEK;
	DHCPYapi^.DonanimTip := 1;		      // ethernet
	DHCPYapi^.DonanimUz := 6;		        // mac uzunluðu
	DHCPYapi^.RelayIcin := 0;
	DHCPYapi^.GonderenKimlik := ntohs(DHCP_GONDEREN_KIMLIK);
	DHCPYapi^.Sure := 0;
	DHCPYapi^.Bayraklar := 0;
	DHCPYapi^.IstemciIPAdres := AIstemciIPAdres;
	DHCPYapi^.IstemciyeAtanacakIPAdresi := IPAdres0;
	DHCPYapi^.SunucuIPAdres := IPAdres0;
	DHCPYapi^.AgGecidiIPAdres := IPAdres0;

  // IstemciMACAdres 6 + 10 = 16 byte
  DHCPYapi^.IstemciMACAdres := GAgBilgisi.MACAdres;
	DHCPYapi^.AYRLDI1 := 0;
	DHCPYapi^.AYRLDI2 := 0;
	DHCPYapi^.AYRLDI3 := 0;

  FillChar(DHCPYapi^.SunucuEvSahibiAdi, 64, #0);
  FillChar(DHCPYapi^.AcilisDosyaAdi, 128, #0);
	DHCPYapi^.SihirliCerez := ntohs(DHCP_SIHIRLI_CEREZ);

  // en sondaki iþaretçi hariç (DigerSecenekler) yapý uzunluðu
  DHCPYapiUzunlugu := SizeOf(TDHCPYapi) - 4;

  // diðer seçenekler
  p1 := @DHCPYapi^.DigerSecenekler;

  // dhcp mesaj kodlamasý
  // 1. byte = mesaj tip, 2. byte = mesajýn uzunluðu, 3. byte = mesajýn kendisi

  // dhcp mesaj tipi
  p1^ := DHCP_SECIM_MESAJ_TIP;
  Inc(p1);
  p1^ := 1;
  Inc(p1);
  p1^ := DHCP_BILGILENDIRME;
  DHCPYapiUzunlugu += 2 + 1;

  Inc(p1);

  p1^ := DHCP_SECIM_ISTEMCI_KIMLIK;
  Inc(p1);
  p1^ := 7;                               // uzunluk
  Inc(p1);
  p1^ := 1;
  Inc(p1);                                // donaným tipi = 1 (ethernet)
  MACAdres := PMACAdres(p1);
  MACAdres^ := GAgBilgisi.MACAdres;
  DHCPYapiUzunlugu += 2 + 1 + 6;

  Inc(p1, 6);

  // bilgisayar adý
  i := Length(GTamBilgisayarAdi);
  p1^ := DHCP_SECIM_YEREL_AD;
  Inc(p1);
  PByte(p1)^ := i;
  Inc(p1);
  pc := Isaretci(p1);
  Tasi2(@GTamBilgisayarAdi[1], pc, i);
  Inc(pc, i);
  p1 := Isaretci(pc);
  DHCPYapiUzunlugu += 2 + i;

  // parametre istek listesi - 2 + 12 byte
  p1^ := DHCP_SECIM_DEGISKEN_ISTEK_LISTESI;
  Inc(p1);
  p1^ := 12;                              // uzunluk
  Inc(p1);
  p1^ := DHCP_SECIM_ALTAG_MASKESI;
  Inc(p1);
  p1^ := DHCP_SECIM_YONLENDIRICI;
  Inc(p1);
  p1^ := DHCP_SECIM_DNS;
  Inc(p1);
  p1^ := DHCP_SECIM_ALAN_ADI;
  Inc(p1);
  p1^ := DHCP_SECIM_YONLENDIRICI_KESIF_UYGULA;
  Inc(p1);
  p1^ := DHCP_SECIM_SABIT_YONLENDIRME_TABLOSU;
  Inc(p1);
  p1^ := DHCP_SECIM_NETBIOS_TCP_NS_ILE;
  Inc(p1);
  p1^ := DHCP_SECIM_NETBIOS_TCP_DUGUM_TIP_ILE;
  Inc(p1);
  p1^ := DHCP_SECIM_NETBIOS_TCP_KAPSAM_ILE;
  Inc(p1);
  p1^ := DHCP_SECIM_SINIFDISI_YONLENDIRME;
  Inc(p1);
  p1^ := DHCP_SECIM_OZEL_SINIFSIZ_YONLENDIRME;
  Inc(p1);
  p1^ := DHCP_SECIM_OZEL_PROXY_OTOKESIF;
  DHCPYapiUzunlugu += 2 + 12;

  Inc(p1);

  p1^ := DHCP_SECIM_SON;
  DHCPYapiUzunlugu += 1;

  IPAdresi := IP_KarakterKatari(IPAdres255);
  B := Baglantilar0.BaglantiOlustur(ptUDP, IPAdresi, DHCP_ISTEMCI_PORT, DHCP_SUNUCU_PORT);
  if not(B = nil) then
  begin

    if(Baglantilar0.Baglan(B^.Kimlik, btYayin) <> -1) then
    begin

      Baglantilar0.Yaz(B^.Kimlik, @DHCPYapi[0], DHCPYapiUzunlugu);

      Baglantilar0.BaglantiyiKes(B^.Kimlik);
    end;
  end;

  FreeMem(DHCPYapi, 4096);
end;

// DHCP istemcisinin bilgilendirme mesajýna onay yanýtý gönderir
procedure DHCPBilgilendirmeyeOnayMesajiGonder(AGonderenKimlik: TSayi4; AIPAdres: TIPAdres;
  AMACAdres: TMACAdres);
var
  B: PBaglanti;
  DHCPYapi: PDHCPYapi;
  IPAdres: PIPAdres;
  p1: PSayi1;
  DHCPYapiUzunlugu: TSayi4;
  IPAdresi: string;
begin

  DHCPYapi := GetMem(4096);

	DHCPYapi^.Islem := DHCP_BOOT_MTIP_YANIT;
	DHCPYapi^.DonanimTip := 1;		      // ethernet
	DHCPYapi^.DonanimUz := 6;		        // mac uzunluðu
	DHCPYapi^.RelayIcin := 0;
	DHCPYapi^.GonderenKimlik := ntohs(AGonderenKimlik);
	DHCPYapi^.Sure := 0;
	DHCPYapi^.Bayraklar := 0;
	DHCPYapi^.IstemciIPAdres := IPAdres0;
	DHCPYapi^.IstemciyeAtanacakIPAdresi := IPAdres0;
	DHCPYapi^.SunucuIPAdres := IPAdres0;
	DHCPYapi^.AgGecidiIPAdres := IPAdres0;

  // IstemciMACAdres 6 + 10 = 16 byte
  DHCPYapi^.IstemciMACAdres := AMACAdres;
	DHCPYapi^.AYRLDI1 := 0;
	DHCPYapi^.AYRLDI2 := 0;
	DHCPYapi^.AYRLDI3 := 0;

  FillChar(DHCPYapi^.SunucuEvSahibiAdi, 64, #0);
  FillChar(DHCPYapi^.AcilisDosyaAdi, 128, #0);
	DHCPYapi^.SihirliCerez := ntohs(DHCP_SIHIRLI_CEREZ);

  // en sondaki iþaretçi hariç (DigerSecenekler) yapý uzunluðu
  DHCPYapiUzunlugu := SizeOf(TDHCPYapi) - 4;

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
  DHCPYapiUzunlugu += 3;

  Inc(p1);

  // sunucu ip adresi - 2 + 4 byte
  p1^ := DHCP_SECIM_SUNUCU_TANIMLAYICI;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IPAdres := Isaretci(p1);
  IPAdres^ := GAgBilgisi.IP4Adres;
  Inc(IPAdres);
  p1 := Isaretci(IPAdres);
  DHCPYapiUzunlugu += 2 + 4;

  // alt að maskesi - 2 + 4 byte
  p1^ := DHCP_SECIM_ALTAG_MASKESI;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IPAdres := Isaretci(p1);
  IPAdres^ := OnDegerAltAgMaskesi;
  Inc(IPAdres);
  p1 := Isaretci(IPAdres);
  DHCPYapiUzunlugu += 2 + 4;

  // alt að maskesi - 2 + 4 byte
  p1^ := DHCP_SECIM_YONLENDIRICI;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IPAdres := Isaretci(p1);
  IPAdres^ := GAgGecidi;
  Inc(IPAdres);
  p1 := Isaretci(IPAdres);
  DHCPYapiUzunlugu += 2 + 4;

  // dns sunucusu - 2 + 4 byte
  p1^ := DHCP_SECIM_DNS;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IPAdres := Isaretci(p1);
  IPAdres^ := GDNSIPAdresi;
  Inc(IPAdres);
  p1 := Isaretci(IPAdres);
  DHCPYapiUzunlugu += 2 + 4;

  p1^ := DHCP_SECIM_OZEL_PROXY_OTOKESIF;
  Inc(p1);
  p1^ := 1;                               // uzunluk
  Inc(p1);
  p1^ := $A;
  DHCPYapiUzunlugu += 2 + 1;

  Inc(p1);

  p1^ := DHCP_SECIM_SON;
  DHCPYapiUzunlugu += 1;

  IPAdresi := IP_KarakterKatari(AIPAdres);
  B := Baglantilar0.BaglantiOlustur(ptUDP, IPAdresi, DHCP_SUNUCU_PORT, DHCP_ISTEMCI_PORT);
  if not(B = nil) then
  begin

    if(Baglantilar0.Baglan(B^.Kimlik, btYayin) <> -1) then
    begin

      Baglantilar0.Yaz(B^.Kimlik, @DHCPYapi[0], DHCPYapiUzunlugu);

      Baglantilar0.BaglantiyiKes(B^.Kimlik);
    end;
  end;

  FreeMem(DHCPYapi, 4096);
end;

// DHCP istemcisine ret mesajý gönderir
procedure DHCPRetMesajiGonder(AGonderenKimlik: TSayi4; AMACAdres: TMACAdres);
var
  B: PBaglanti;
  DHCPYapi: PDHCPYapi;
  IPAdres: PIPAdres;
  p1: PSayi1;
  DHCPYapiUzunlugu: TSayi4;
  IPAdresi: string;
begin

  DHCPYapi := GetMem(4096);

	DHCPYapi^.Islem := DHCP_BOOT_MTIP_YANIT;
	DHCPYapi^.DonanimTip := 1;		      // ethernet
	DHCPYapi^.DonanimUz := 6;		        // mac uzunluðu
	DHCPYapi^.RelayIcin := 0;
	DHCPYapi^.GonderenKimlik := ntohs(AGonderenKimlik);
	DHCPYapi^.Sure := 0;
	DHCPYapi^.Bayraklar := 0;
	DHCPYapi^.IstemciIPAdres := IPAdres0;
	DHCPYapi^.IstemciyeAtanacakIPAdresi := IPAdres0;
	DHCPYapi^.SunucuIPAdres := IPAdres0;
	DHCPYapi^.AgGecidiIPAdres := IPAdres0;

  // IstemciMACAdres 6 + 10 = 16 byte
  DHCPYapi^.IstemciMACAdres := AMACAdres;
	DHCPYapi^.AYRLDI1 := 0;
	DHCPYapi^.AYRLDI2 := 0;
	DHCPYapi^.AYRLDI3 := 0;

  FillChar(DHCPYapi^.SunucuEvSahibiAdi, 64, #0);
  FillChar(DHCPYapi^.AcilisDosyaAdi, 128, #0);
	DHCPYapi^.SihirliCerez := ntohs(DHCP_SIHIRLI_CEREZ);

  // en sondaki iþaretçi hariç (DigerSecenekler) yapý uzunluðu
  DHCPYapiUzunlugu := SizeOf(TDHCPYapi) - 4;

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
  DHCPYapiUzunlugu += 3;

  Inc(p1);

  // sunucu ip adresi - 2 + 4 byte
  p1^ := DHCP_SECIM_SUNUCU_TANIMLAYICI;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IPAdres := Isaretci(p1);
  IPAdres^ := GAgBilgisi.IP4Adres;
  Inc(IPAdres);
  p1 := Isaretci(IPAdres);
  DHCPYapiUzunlugu += 2 + 4;

  p1^ := DHCP_SECIM_SON;
  DHCPYapiUzunlugu += 1;

  IPAdresi := IP_KarakterKatari(IPAdres255);
  B := Baglantilar0.BaglantiOlustur(ptUDP, IPAdresi, DHCP_SUNUCU_PORT, DHCP_ISTEMCI_PORT);
  if not(B = nil) then
  begin

    if(Baglantilar0.Baglan(B^.Kimlik, btYayin) <> -1) then
    begin

      Baglantilar0.Yaz(B^.Kimlik, @DHCPYapi[0], DHCPYapiUzunlugu);

      Baglantilar0.BaglantiyiKes(B^.Kimlik);
    end;
  end;

  FreeMem(DHCPYapi, 4096);
end;

end.
