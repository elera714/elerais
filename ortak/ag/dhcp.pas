{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: dhcp.pas
  Dosya Ýþlevi: DHCP protokol istemci iþlevlerini yönetir

  Güncelleme Tarihi: 25/12/2024

  Bilgi: sadece kullanýlan sabit, deðiþken ve iþlevler türkçeye çevrilmiþtir

 ==============================================================================}
{$mode objfpc}
unit dhcp;

interface

uses paylasim;

const
  DHCP_SUNUCU_PORT                        = Byte(67);
  DHCP_ISTEMCI_PORT                       = Byte(68);

  // boot mesaj tipleri
	DHCP_BOOT_MTIP_ISTEK                    = Byte(1);
	DHCP_BOOT_MTIP_YANIT                    = Byte(2);

  // mesaj tipleri
  DHCP_UNKNOWN                            = Byte(0);
  DHCP_MTIP_KESIF                         = Byte(1);
  DHCP_MTIP_TEKLIF                        = Byte(2);
  DHCP_MTIP_ISTEK                         = Byte(3);
  DHCP_DECLINE                            = Byte(4);
  DHCP_MTIP_ONAY                          = Byte(5);
  DHCP_NAK                                = Byte(6);
  DHCP_RELEASE                            = Byte(7);
  DHCP_INFORM                             = Byte(8);
  DHCP_LEASE_QUERY                        = Byte(10);
  DHCP_LEASE_UNASSIGNED                   = Byte(11);
  DHCP_LEASE_UNKNOWN                      = Byte(12);
  DHCP_LEASE_ACTIVE                       = Byte(13);

  // seçenek tipleri
  DHCP_OPTION_PAD                         = Byte(0);
  DHCP_SECIM_ALTAG_MASKESI                = Byte(1);
  DHCP_SECIM_ZAMAN_OFFSET                 = Byte(2);      // kullanýlmýyor
  DHCP_SECIM_YONLENDIRICI                 = Byte(3);
  DHCP_OPTION_TIME_SERVER                 = Byte(4);
  DHCP_OPTION_NAME_SERVER                 = Byte(5);
  DHCP_SECIM_DNS                          = Byte(6);
  DHCP_OPTION_LOG_SERVER                  = Byte(7);
  DHCP_OPTION_QUOTE_SERVER                = Byte(8);
  DHCP_OPTION_LPR_SERVER                  = Byte(9);
  DHCP_OPTION_IMPRESS_SERVER              = Byte(10);
  DHCP_OPTION_RESOURCE_LOCATION_SERVER    = Byte(11);
  DHCP_SECIM_YEREL_AD                     = Byte(12);
  DHCP_OPTION_BOOT_FILE_SIZE              = Byte(13);
  DHCP_OPTION_MERIT_DUMP_FILE             = Byte(14);
  DHCP_SECIM_ALAN_ADI                     = Byte(15);
  DHCP_OPTION_SWAP_SERVER                 = Byte(16);
  DHCP_SECIM_KOK_YOL                      = Byte(17);
  DHCP_OPTION_EXTENSION_PATH              = Byte(18);
  DHCP_OPTION_IP_FWD_CONTROL              = Byte(19);
  DHCP_OPTION_NL_SRC_ROUTING              = Byte(20);
  DHCP_OPTION_POLICY_FILTER               = Byte(21);
  DHCP_OPTION_MAX_DG_REASSEMBLY_SIZE      = Byte(22);
  DHCP_OPTION_DEFAULT_IP_TTL              = Byte(23);
  DHCP_OPTION_PATH_MTU_AGING_TIMEOUT      = Byte(24);
  DHCP_OPTION_PATH_MTU_PLATEAU_TABLE      = Byte(25);
  DHCP_SECIM_ARABIRIM_MTU                 = Byte(26);
  DHCP_OPTION_ALL_SUBNETS_LOCAL           = Byte(27);
  DHCP_SECIM_YAYIN_ADRESI                 = Byte(28);
  DHCP_OPTION_PERFORM_MASK_DISCOVERY      = Byte(29);
  DHCP_OPTION_MASK_SUPPLIER               = Byte(30);
  DHCP_SECIM_YONLENDIRICI_KESIF_UYGULA    = Byte(31);
  DHCP_OPTION_ROUTER_SOLICIT_ADDRESS      = Byte(32);
  DHCP_SECIM_SABIT_YONLENDIRME_TABLOSU    = Byte(33);
  DHCP_OPTION_TRAILER_ENCAP               = Byte(34);
  DHCP_OPTION_ARP_CACHE_TIMEOUT           = Byte(35);
  DHCP_OPTION_ETHERNET_ENCAP              = Byte(36);
  DHCP_OPTION_DEFAULT_TCP_TTL             = Byte(37);
  DHCP_OPTION_TCP_KEEPALIVE_INTERVAL      = Byte(38);
  DHCP_OPTION_TCP_KEEPALIVE_GARBAGE       = Byte(39);
  DHCP_SECIM_NIS_ALANADI                  = Byte(40);
  DHCP_SECIM_NIS_SUNUCULAR                = Byte(41);
  DHCP_SECIM_NTP_SUNUCULAR                = Byte(42);
  DHCP_SECIM_SATICI_OZEL_BILGI            = Byte(43);
  DHCP_SECIM_NETBIOS_TCP_NS_ILE           = Byte(44);
  DHCP_OPTION_NETBIOS_OVER_TCP_DG_DS      = Byte(45);
  DHCP_SECIM_NETBIOS_TCP_DUGUM_TIP_ILE    = Byte(46);
  DHCP_SECIM_NETBIOS_TCP_KAPSAM_ILE       = Byte(47);
  DHCP_OPTION_XWINDOW_FONT_SERVER         = Byte(48);
  DHCP_OPTION_XWINDOW_SYSTEM_DISP_MGR     = Byte(49);
  DHCP_SECIM_ISTEK_IP_ADRES               = Byte(50);
  DHCP_SECIM_IP_KIRALAMA_SURESI           = Byte(51);
  DHCP_OPTION_OVERLOAD                    = Byte(52);
  DHCP_SECIM_MESAJ_TIP                    = Byte(53);
  DHCP_SECIM_SUNUCU_TANIMLAYICI           = Byte(54);
  DHCP_SECIM_DEGISKEN_ISTEK_LISTESI       = Byte(55);
  DHCP_OPTION_MESSAGE                     = Byte(56);
  DHCP_SECIM_AZAMI_DHCP_MESAJ_UZUNLUK     = Byte(57);
  DHCP_OPTION_RENEW_TIME_VALUE            = Byte(58);
  DHCP_OPTION_REBIND_TIME_VALUE           = Byte(59);
  DHCP_OPTION_CLASS_ID                    = Byte(60);
  DHCP_SECIM_ISTEMCI_KIMLIK               = Byte(61);
  DHCP_OPTION_NETWARE_IP_DOMAIN_NAME      = Byte(62);
  DHCP_OPTION_NETWARE_IP_INFO             = Byte(63);
  DHCP_OPTION_NIS_PLUS_DOMAIN             = Byte(64);
  DHCP_OPTION_NIS_PLUS_SERVERS            = Byte(65);
  DHCP_OPTION_TFTP_SERVER_NAME            = Byte(66);
  DHCP_OPTION_BOOTFILE_NAME               = Byte(67);
  DHCP_OPTION_MOBILE_IP_HA                = Byte(68);
  DHCP_OPTION_SMTP_SERVER                 = Byte(69);
  DHCP_OPTION_POP_SERVER                  = Byte(70);
  DHCP_OPTION_NNTP_SERVER                 = Byte(71);
  DHCP_OPTION_DEFAULT_WWW_SERVER          = Byte(72);
  DHCP_OPTION_DEFAULT_FINGER_SERVER       = Byte(73);
  DHCP_OPTION_DEFAULT_IRC_SERVER          = Byte(74);
  DHCP_OPTION_STREETTALK_SERVER           = Byte(75);
  DHCP_OPTION_STREETTALK_DA_SERVER        = Byte(76);
  DHCP_OPTION_USER_CLASS_INFO             = Byte(77);
  DHCP_OPTION_SLP_DIRECTORY_AGENT         = Byte(78);
  DHCP_OPTION_SLP_SERVICE_SCOPE           = Byte(79);
  DHCP_OPTION_RAPID_COMMIT                = Byte(80);
  DHCP_OPTION_CLIENT_FQDN                 = Byte(81);
  DHCP_OPTION_82                          = Byte(82);
  DHCP_OPTION_STORAGE_NS                  = Byte(83);
  // ignoring option 84 (removed / unassigned)
  DHCP_OPTION_NDS_SERVERS                 = Byte(85);
  DHCP_OPTION_NDS_TREE_NAME               = Byte(86);
  DHCP_OPTION_NDS_CONTEXT                 = Byte(87);
  DHCP_OPTION_BCMCS_DN_LIST               = Byte(88);
  DHCP_OPTION_BCMCS_ADDR_LIST             = Byte(89);
  DHCP_OPTION_AUTH                        = Byte(90);
  DHCP_OPTION_CLIENT_LAST_XTIME           = Byte(91);
  DHCP_OPTION_ASSOCIATE_IP                = Byte(92);
  DHCP_OPTION_CLIENT_SYSARCH_TYPE         = Byte(93);
  DHCP_OPTION_CLIENT_NW_INTERFACE_ID      = Byte(94);
  DHCP_OPTION_LDAP                        = Byte(95);
  // ignoring 96 (removed / unassigned)
  DHCP_OPTION_CLIENT_MACHINE_ID           = Byte(97);
  DHCP_OPTION_OPENGROUP_USER_AUTH         = Byte(98);
  DHCP_OPTION_GEOCONF_CIVIC               = Byte(99);
  DHCP_OPTION_IEEE_1003_1_TZ              = Byte(100);
  DHCP_OPTION_REF_TZ_DB                   = Byte(101);
  // ignoring 102 to 111 & 115 (removed / unassigned)
  DHCP_OPTION_NETINFO_PARENT_SERVER_ADDR  = Byte(112);
  DHCP_OPTION_NETINFO_PARENT_SERVER_TAG   = Byte(113);
  DHCP_OPTION_URL                         = Byte(114);
  DHCP_SECIM_OTO_AYAR                     = Byte(116);
  DHCP_OPTION_NAME_SERVICE_SEARCH         = Byte(117);
  DHCP_OPTION_SUBNET_SELECTION            = Byte(118);
  DHCP_SECIM_DNS_ALANADI_ARAMA_LISTESI    = Byte(119);
  DHCP_OPTION_SIP_SERVERS                 = Byte(120);
  DHCP_SECIM_SINIFDISI_YONLENDIRME        = Byte(121);
  DHCP_OPTION_CCC                         = Byte(122);
  DHCP_OPTION_GEOCONF                     = Byte(123);
  DHCP_OPTION_VENDOR_ID_VENDOR_CLASS      = Byte(124);
  DHCP_OPTION_VENDOR_ID_VENDOR_SPECIFIC   = Byte(125);
  // ignoring 126, 127 (removed / unassigned)
  // options 128 - 135 arent officially assigned to PXE
  DHCP_OPTION_TFTP_SERVER                 = Byte(128);
  DHCP_OPTION_PXE_VENDOR_SPECIFIC_129     = Byte(129);
  DHCP_OPTION_PXE_VENDOR_SPECIFIC_130     = Byte(130);
  DHCP_OPTION_PXE_VENDOR_SPECIFIC_131     = Byte(131);
  DHCP_OPTION_PXE_VENDOR_SPECIFIC_132     = Byte(132);
  DHCP_OPTION_PXE_VENDOR_SPECIFIC_133     = Byte(133);
  DHCP_OPTION_PXE_VENDOR_SPECIFIC_134     = Byte(134);
  DHCP_OPTION_PXE_VENDOR_SPECIFIC_135     = Byte(135);
  DHCP_OPTION_PANA_AUTH_AGENT             = Byte(136);
  DHCP_OPTION_LOST_SERVER                 = Byte(137);
  DHCP_OPTION_CAPWAP_AC_ADDRESS           = Byte(138);
  DHCP_OPTION_IPV4_ADDRESS_MOS            = Byte(139);
  DHCP_OPTION_IPV4_FQDN_MOS               = Byte(140);
  DHCP_OPTION_SIP_UA_CONFIG_DOMAIN        = Byte(141);
  DHCP_OPTION_IPV4_ADDRESS_ANDSF          = Byte(142);
  DHCP_OPTION_GEOLOC                      = Byte(144);
  DHCP_OPTION_FORCERENEW_NONCE_CAP        = Byte(145);
  DHCP_OPTION_RDNSS_SELECTION             = Byte(146);
  // ignoring options 143, 147 - 149 (removed / unassigned)
  // option 150 is also assigned as Etherboot, GRUB configuration path name
  DHCP_OPTION_TFTP_SERVER_ADDRESS         = Byte(150);
  DHCP_OPTION_STATUS_CODE                 = Byte(151);
  DHCP_OPTION_BASE_TIME                   = Byte(152);
  DHCP_OPTION_START_TIME_OF_STATE         = Byte(153);
  DHCP_OPTION_QUERY_START_TIME            = Byte(154);
  DHCP_OPTION_QUERY_END_TIME              = Byte(155);
  DHCP_OPTION_DHCP_STATE                  = Byte(156);
  DHCP_OPTION_DATA_SOURCE                 = Byte(157);
  DHCP_OPTION_PCP_SERVER                  = Byte(158);
  // ignoring options 159 - 174 (removed / unassigned)
  // ignoring options 175 - 177 (tentatively assigned)
  // ignoring options 178 - 207 (removed / unassigned)
  DHCP_OPTION_PXELINUX_MAGIC              = Byte(208);  // deprecated
  DHCP_OPTION_CONFIG_FILE                 = Byte(209);
  DHCP_OPTION_PATH_PREFIX                 = Byte(210);
  DHCP_OPTION_REBOOT_TIME                 = Byte(211);
  DHCP_OPTION_6RD                         = Byte(212);
  DHCP_OPTION_V4_ACCESS_DOMAIN            = Byte(213);
  // ignoring options 214 - 219 (removed / unassigned)
  DHCP_OPTION_SUBNET_ALLOCATION           = Byte(220);
  DHCP_OPTION_VSS                         = Byte(221);
  // ignoring options 222 - 254 (removed / unassigned) ???
  DHCP_SECIM_OZEL_SINIFSIZ_YONLENDIRME    = Byte(249);
  DHCP_SECIM_OZEL_PROXY_OTOKESIF          = Byte(252);
  DHCP_SECIM_SON                          = Byte(255);

  DHCP_SIHIRLI_CEREZ    = TSayi4($63538263);
  DHCP_GONDEREN_KIMLIK  = TSayi4($3903F328);

type
  PDHCPMesaj = ^TDHCPMesaj;
  TDHCPMesaj = packed record
    MesajTip: Byte;
    Uzunluk: Byte;
    Mesaj: Pointer;
  end;

procedure DHCPIpAdresiAl;
procedure DHCPMesajGonder(AMesajTipi: LongWord);
procedure DHCPPaketleriniIsle(ADHCPKayit: PDHCPKayit);

implementation

uses genel, iletisim, donusum, islevler;

var
  DHCPYanit: TAgBilgisi;
  TeklifEdilenIPAdresi: TIPAdres;

procedure DHCPIpAdresiAl;
begin

  DHCPMesajGonder(DHCP_MTIP_KESIF);
end;

// DHCP mesajý gönderir
// AMesajTipi
// 1 = DHCP_MTIP_KESIF
// 2 = DHCP_MTIP_TEKLIF
// 3 = DHCP_MTIP_ISTEK
procedure DHCPMesajGonder(AMesajTipi: LongWord);
var
  Baglanti: PBaglanti;
  DHCPKayit: PDHCPKayit;
  IPAdres: PIPAdres;
  MACAdres: PMACAdres;
  i: Byte;
  p1: PByte;
  pc: PChar;
  DHCPKayitUzunlugu: LongWord;
  IPAdresi: string;
begin

  DHCPKayit := GGercekBellek.Ayir(4095);

	DHCPKayit^.Islem := DHCP_BOOT_MTIP_ISTEK;
	DHCPKayit^.DonanimTip := 1;		    // ethernet
	DHCPKayit^.DonanimUz := 6;		    // mac uzunluðu
	DHCPKayit^.RelayIcin := 0;
	DHCPKayit^.GonderenKimlik := DHCP_GONDEREN_KIMLIK;
	DHCPKayit^.Sure := 1;
	DHCPKayit^.Bayraklar := 0;
	DHCPKayit^.IstemciIPAdres := IPAdres0;
	DHCPKayit^.BenimIPAdresim := IPAdres0;
	DHCPKayit^.SunucuIPAdres := IPAdres0;
	DHCPKayit^.AgGecidiIPAdres := IPAdres0;

  // IstemciMACAdres 6 + 10 = 16 byte
  DHCPKayit^.IstemciMACAdres := GAgBilgisi.MACAdres;
	DHCPKayit^.AYRLDI1 := 0;
	DHCPKayit^.AYRLDI2 := 0;
	DHCPKayit^.AYRLDI3 := 0;

  FillChar(DHCPKayit^.SunucuEvSahibiAdi, 64, #0);
  FillChar(DHCPKayit^.AcilisDosyaAdi, 128, #0);
	DHCPKayit^.SihirliCerez := DHCP_SIHIRLI_CEREZ;

  // en sondaki iþaretçi hariç (DigerSecenekler) yapý uzunluðu
  DHCPKayitUzunlugu := SizeOf(TDHCPKayit) - 4;

  // diðer seçenekler
  p1 := @DHCPKayit^.DigerSecenekler;

  // mesaj kodlamalarý
  // kodlamalar: 1 = mesaj tip, 2 = mesajýn uzunluðu, 3 = mesaj olarak kodlanacaktýr

  // dhcp mesaj tipi
  p1^ := DHCP_SECIM_MESAJ_TIP;
  Inc(p1);
  p1^ := 1;
  Inc(p1);
  p1^ := AMesajTipi;
  DHCPKayitUzunlugu += 3;

  Inc(p1);

  p1^ := DHCP_SECIM_ISTEMCI_KIMLIK;
  Inc(p1);
  p1^ := 7;                               // uzunluk
  Inc(p1);
  p1^ := 1;
  Inc(p1);                                // donaným tipi = 1 (ethernet)
  MACAdres := PMACAdres(p1);
  MACAdres^ := GAgBilgisi.MACAdres;
  DHCPKayitUzunlugu += 3 + 6;

  Inc(p1, 6);

  // parametre istek listesi - 14 byte
  p1^ := DHCP_SECIM_DEGISKEN_ISTEK_LISTESI;
  Inc(p1);
  p1^ := 17;                              // uzunluk
  Inc(p1);
  p1^ := DHCP_SECIM_ALTAG_MASKESI;
  Inc(p1);
  p1^ := DHCP_SECIM_ZAMAN_OFFSET;
  Inc(p1);
  p1^ := DHCP_SECIM_DNS;
  Inc(p1);
  p1^ := DHCP_SECIM_YEREL_AD;
  Inc(p1);
  p1^ := DHCP_SECIM_ALAN_ADI;
  Inc(p1);
  p1^ := DHCP_SECIM_ARABIRIM_MTU;
  Inc(p1);
  p1^ := DHCP_SECIM_YAYIN_ADRESI;
  Inc(p1);
  p1^ := DHCP_SECIM_SINIFDISI_YONLENDIRME;
  Inc(p1);
  p1^ := DHCP_SECIM_YONLENDIRICI;
  Inc(p1);
  p1^ := DHCP_SECIM_SABIT_YONLENDIRME_TABLOSU;
  Inc(p1);
  p1^ := DHCP_SECIM_NIS_ALANADI;
  Inc(p1);
  p1^ := DHCP_SECIM_NIS_SUNUCULAR;
  Inc(p1);
  p1^ := DHCP_SECIM_NTP_SUNUCULAR;
  Inc(p1);
  p1^ := DHCP_SECIM_DNS_ALANADI_ARAMA_LISTESI;
  Inc(p1);
  p1^ := DHCP_SECIM_OZEL_SINIFSIZ_YONLENDIRME;
  Inc(p1);
  p1^ := DHCP_SECIM_OZEL_PROXY_OTOKESIF;
  Inc(p1);
  p1^ := DHCP_SECIM_KOK_YOL;
  DHCPKayitUzunlugu += 2 + 17;

  Inc(p1);

  // dhcp mesaj tipi
  p1^ := DHCP_SECIM_AZAMI_DHCP_MESAJ_UZUNLUK;
  Inc(p1);
  p1^ := 2;
  Inc(p1);
  p1^ := $02;
  Inc(p1);
  p1^ := $40;
  DHCPKayitUzunlugu += 4;

  Inc(p1);

  // mesajýn bir istek mesajý olmasý durumunda...
  if(AMesajTipi = DHCP_MTIP_ISTEK) then
  begin

    // istenen ip adresi - 6 byte
    p1^ := DHCP_SECIM_ISTEK_IP_ADRES;
    Inc(p1);
    p1^ := 4;
    Inc(p1);
    IPAdres := Pointer(p1);
    IPAdres^ := TeklifEdilenIPAdresi;
    Inc(IPAdres);
    p1 := Pointer(IPAdres);
    DHCPKayitUzunlugu += 2 + 4;

    // istenen ip adresi - 6 byte
    p1^ := DHCP_SECIM_SUNUCU_TANIMLAYICI;
    Inc(p1);
    p1^ := 4;
    Inc(p1);
    IPAdres := Pointer(p1);
    IPAdres^ := DHCPYanit.DHCPSunucusu;
    Inc(IPAdres);
    p1 := Pointer(IPAdres);
    DHCPKayitUzunlugu += 2 + 4;
  end;

  // bilgisayar adý tanýmý - 2 + MakineAdi byte
  i := Length(GMakineAdi);
  p1^ := DHCP_SECIM_YEREL_AD;
  Inc(p1);
  PByte(p1)^ := i;
  Inc(p1);
  pc := Pointer(p1);
  Tasi2(@GMakineAdi[1], pc, i);
  Inc(pc, i);
  p1 := Pointer(pc);
  DHCPKayitUzunlugu += 2 + i;

  Inc(p1);

  p1^ := DHCP_SECIM_SON;
  DHCPKayitUzunlugu += 1;

  IPAdresi := IP_KarakterKatari(IPAdres255);
  Baglanti := GBaglanti^.Olustur2(ptUDP, IPAdresi, DHCP_ISTEMCI_PORT, DHCP_SUNUCU_PORT);
  if not(Baglanti = nil) then
  begin

    if(Baglanti^.Baglan(btYayin) <> -1) then
    begin

      Baglanti^.Yaz(@DHCPKayit[0], DHCPKayitUzunlugu);

      Baglanti^.BaglantiyiKes;
    end;
  end;

  GGercekBellek.YokEt(DHCPKayit, 4095);
end;

// gelen DHCP paketlerini iþler
procedure DHCPPaketleriniIsle(ADHCPKayit: PDHCPKayit);
var
  DHCPMesaj: PDHCPMesaj;
  AnaMesajTipi,
  MesajTipi, i: Byte;
  p1: PByte;
begin

  // gelen mesajýn DHCP_SECIM_MESAJ_TIP deðeri
  AnaMesajTipi := 0;

  // alýnan SihirliCerez deðeri gönderdiðimiz deðer mi?
  if(ADHCPKayit^.SihirliCerez = DHCP_SIHIRLI_CEREZ) then
  begin

    // alýnan GonderenKimlik deðeri gönderdiðimiz deðer mi?
    if(ADHCPKayit^.GonderenKimlik = DHCP_GONDEREN_KIMLIK) then
    begin

      // alýnan mesaj bir yanýt _IPAdresý?
      if(ADHCPKayit^.Islem = DHCP_BOOT_MTIP_YANIT) then
      begin

        // seçenek olarak alýnan yapýyý döngü içerisinde irdele
        DHCPMesaj := @ADHCPKayit^.DigerSecenekler;
        MesajTipi := DHCPMesaj^.MesajTip;
        i := DHCPMesaj^.Uzunluk;

        // seçeneðin sonuna gelinceye kadar tü_IPAdres seçenekleri iþleme al
        while MesajTipi <> DHCP_SECIM_SON do
        begin

          if(MesajTipi = DHCP_SECIM_ALTAG_MASKESI) and (i = 4) then

            DHCPYanit.AltAgMaskesi := PIPAdres(@DHCPMesaj^.Mesaj)^
          else if(MesajTipi = DHCP_SECIM_YONLENDIRICI) and (i = 4) then

            DHCPYanit.AgGecitAdresi := PIPAdres(@DHCPMesaj^.Mesaj)^
          else if(MesajTipi = DHCP_SECIM_DNS) and (i = 4) then

            DHCPYanit.DNSSunucusu := PIPAdres(@DHCPMesaj^.Mesaj)^
          else if(MesajTipi = DHCP_SECIM_SUNUCU_TANIMLAYICI) then

            DHCPYanit.DHCPSunucusu := PIPAdres(@DHCPMesaj^.Mesaj)^
          else if(MesajTipi = DHCP_SECIM_IP_KIRALAMA_SURESI) then

            DHCPYanit.IPKiraSuresi := ntohs(PLongWord(@DHCPMesaj^.Mesaj)^)
          else if(MesajTipi = DHCP_SECIM_MESAJ_TIP) then
          begin

            AnaMesajTipi := PByte(@DHCPMesaj^.Mesaj)^;
            if(AnaMesajTipi = DHCP_MTIP_ONAY) then
            begin

              DHCPYanit.IP4Adres := ADHCPKayit^.BenimIPAdresim;
            end
            else if(AnaMesajTipi = DHCP_MTIP_TEKLIF) then
            begin

              TeklifEdilenIPAdresi := ADHCPKayit^.BenimIPAdresim;
            end;
          end;

          // bir sonraki seçeneðe konumlan
          p1 := Pointer(DHCPMesaj);
          Inc(p1, i + 2);
          DHCPMesaj := Pointer(p1);
          MesajTipi := DHCPMesaj^.MesajTip;
          i := DHCPMesaj^.Uzunluk;
        end;

        if(AnaMesajTipi = DHCP_MTIP_TEKLIF) then

          DHCPMesajGonder(DHCP_MTIP_ISTEK)

        // onay mesajýnýn gelmesi durumunda toplanan tüm verileri ana deðiþkenlere ata
        else if(AnaMesajTipi = DHCP_MTIP_ONAY) then
        begin

          GAgBilgisi.IP4Adres := DHCPYanit.IP4Adres;
          GAgBilgisi.AltAgMaskesi := DHCPYanit.AltAgMaskesi;
          GAgBilgisi.AgGecitAdresi := DHCPYanit.AgGecitAdresi;
          GAgBilgisi.DNSSunucusu := DHCPYanit.DNSSunucusu;
          GAgBilgisi.DHCPSunucusu := DHCPYanit.DHCPSunucusu;
          GAgBilgisi.IPKiraSuresi := DHCPYanit.IPKiraSuresi;
          GAgBilgisi.IPAdresiAlindi := True;
        end;
      end;
    end;
  end;
end;

end.
