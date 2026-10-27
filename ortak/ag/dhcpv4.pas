{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: dhcpv4.pas
  Dosya İşlevi: DHCP v4 tutanak genel sabit / yapı ve işlevlerini içerir

  Güncelleme Tarihi: 27/10/2026

  Bilgi: sadece kullanılan sabit, değişken ve işlevler türkçeye çevrilmiştir

 ==============================================================================}
{$mode objfpc}
unit dhcpv4;

interface

uses paylasim;

const
  { TODO - dns sunucusu tarafından yapılandırılacak, şu aşamada dhcp sunucu tarafından
    gönderilecek değer olarak belirlenmiştir }
  // aşağıdaki 2 değer şu aşamada dhcp sunucusu tarafından kullanılmaktadır
  DNSIP4Adres: TIP4Adres  = (127, 0, 0, 1);
  AgGecidi: TIP4Adres     = (127, 0, 0, 1);

type
  PDHCP4Yapi = ^TDHCP4Yapi;
  TDHCP4Yapi = packed record
  	Islem, DonanimTip, DonanimUz,
    RelayIcin: TSayi1;
  	GonderenKimlik: TSayi4;
  	Sure, Bayraklar: TSayi2;
  	IstemciIP4Adres, IstemciyeAtanacakIP4Adres, SunucuIP4Adres,
    AgGecidiIP4Adres: TIP4Adres;
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
  DHCP_SECIM_ZAMAN_OFFSET                 = TSayi1(2);      // kullanılmıyor
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

  DHCP_SIHIRLI_CEREZ                      = TSayi4($63825363);    // network byte sıralı kodlama
  DHCP_GONDEREN_KIMLIK                    = TSayi4($3903F328);

type
  PDHCPMesaj = ^TDHCPMesaj;
  TDHCPMesaj = packed record
    Tip: TSayi1;
    Uzunluk: TSayi1;
    Mesaj: Isaretci;
  end;

implementation

end.
