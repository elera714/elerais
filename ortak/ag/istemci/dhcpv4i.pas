{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: dhcpv4i.pas
  Dosya Ýþlevi: DHCP v4 istemci tutanak iþlevlerini yönetir

  Güncelleme Tarihi: 27/10/2026

 ==============================================================================}
{$mode objfpc}
unit dhcpv4i;

interface

uses paylasim, dhcpv4, sunucular, udp;

type
  TDHCPv4i = class(TUDPIstemci)
  private
    FBaglanti: TObject;
    FUDP: TUDP;
    // bilgi (inform) mesajýnýn sunucuya gönderilip gönderilmediði
    FBilgiMesajiGonderildi: Boolean;
    // sunucudan gelen deðerlerin yerleþtirileceði deðiþkenler
    FYanitIP4Adres, FYanitAltAgMaskesi,
    FYanitAgGecitAdresi, FYanitDNSSunucusu,
    FYanitDHCPSunucusu, FTeklifEdilenIP4Adresi: TIP4Adres;
    FYanitIP4KiraSuresi: TSayi4;
  public
    constructor Create(ABaglanti: TObject);
    destructor Destroy; override;
    procedure OVeriGeldi(AEthernetPaket: PEthernetPaket); override;
    procedure OtomatikIpAdresiAl;
    { Discover }
    procedure DHCPKesifMesajiGonder;
    { Request }
    procedure DHCPIstekMesajiGonder(ADHCPSunucuIP4Adres, AIstenenIP4Adres: TIP4Adres);
    { Inform }
    procedure DHCPBilgilendirmeMesajiGonder(AIstemciIP4Adres: TIP4Adres);
  end;

implementation

uses donusum, aygityonetimi, islevler, baglantilar;

{==============================================================================
  dhcp istemci nesnesi ana yükleme iþlevlerini içerir
 ==============================================================================}
constructor TDHCPv4i.Create(ABaglanti: TObject);
begin

  FBaglanti := ABaglanti;

  // iletiþim udp tutanaðý üzerinden gerçekleþeceði için 1 adet udp
  // nesnesi oluþturuluyor
  FUDP := TUDP.Create(nil, FBaglanti, itIP4, MACAdres0);

  // öndeðerler
  FBilgiMesajiGonderildi := False;
  FYanitIP4Adres := IP4Adres0;
  FYanitAltAgMaskesi := IP4Adres0;
  FYanitAgGecitAdresi := IP4Adres0;
  FYanitDNSSunucusu := IP4Adres0;
  FYanitDHCPSunucusu := IP4Adres0;
  FTeklifEdilenIP4Adresi := IP4Adres0;
  FYanitIP4KiraSuresi := 0;
end;

{==============================================================================
  dhcp istemci nesnesi ana yok etme iþlevlerini içerir
 ==============================================================================}
destructor TDHCPv4i.Destroy;
begin

  FUDP.Destroy;

  inherited Destroy;
end;

{==============================================================================
  dhcp istemcisine gelen paketleri iþler
 ==============================================================================}
procedure TDHCPv4i.OVeriGeldi(AEthernetPaket: PEthernetPaket);
var
  IP4Paket: PIP4Paket;
  UDPPaket: PUDPPaket;
  DHCP4Yapi: PDHCP4Yapi;
  DHCPMesaj: PDHCPMesaj;
  AnaMT, MT, i: TSayi1;
  p1: PByte;
begin

  IP4Paket := PIP4Paket(@AEthernetPaket^.Veri);
  UDPPaket := PUDPPaket(@IP4Paket^.Veri);
  DHCP4Yapi := PDHCP4Yapi(@UDPPaket^.Veri);

  // gelen mesajýn DHCP_SECIM_MESAJ_TIP deðeri
  AnaMT := 0;

  // alýnan SihirliCerez deðeri gönderdiðimiz deðer mi?
  if(htons(DHCP4Yapi^.SihirliCerez) = DHCP_SIHIRLI_CEREZ) then
  begin

    // alýnan GonderenKimlik deðeri gönderdiðimiz deðer mi?
    if(ntohs(DHCP4Yapi^.GonderenKimlik) = DHCP_GONDEREN_KIMLIK) then
    begin

      // alýnan mesaj bir yanýt mesajý mý?
      if(DHCP4Yapi^.Islem = DHCP_BOOT_MTIP_YANIT) then
      begin

        // seçenek olarak alýnan yapýyý döngü içerisinde irdele
        DHCPMesaj := @DHCP4Yapi^.DigerSecenekler;
        MT := DHCPMesaj^.Tip;
        i := DHCPMesaj^.Uzunluk;

        // seçeneðin sonuna gelinceye kadar tüm deðerleri oku
        while MT <> DHCP_SECIM_SON do
        begin

          if(MT = DHCP_SECIM_ALTAG_MASKESI) and (i = 4) then

            FYanitAltAgMaskesi := PIP4Adres(@DHCPMesaj^.Mesaj)^

          else if(MT = DHCP_SECIM_YONLENDIRICI) and (i = 4) then

            FYanitAgGecitAdresi := PIP4Adres(@DHCPMesaj^.Mesaj)^

          else if(MT = DHCP_SECIM_DNS) and (i = 4) then

            FYanitDNSSunucusu := PIP4Adres(@DHCPMesaj^.Mesaj)^

          else if(MT = DHCP_SECIM_SUNUCU_TANIMLAYICI) then

            FYanitDHCPSunucusu := PIP4Adres(@DHCPMesaj^.Mesaj)^

          else if(MT = DHCP_SECIM_IP_KIRALAMA_SURESI) then

            FYanitIP4KiraSuresi := ntohs(PLongWord(@DHCPMesaj^.Mesaj)^)

          else if(MT = DHCP_SECIM_MESAJ_TIP) then
          begin

            AnaMT := PByte(@DHCPMesaj^.Mesaj)^;
            if(AnaMT = DHCP_MTIP_ONAY) then
            begin

              FYanitIP4Adres := DHCP4Yapi^.IstemciyeAtanacakIP4Adres;
            end
            else if(AnaMT = DHCP_MTIP_TEKLIF) then
            begin

              FTeklifEdilenIP4Adresi := DHCP4Yapi^.IstemciyeAtanacakIP4Adres;
            end;
          end;

          // bir sonraki seçeneðe konumlan
          p1 := Isaretci(DHCPMesaj);
          Inc(p1, i + 2);
          DHCPMesaj := Isaretci(p1);
          MT := DHCPMesaj^.Tip;
          i := DHCPMesaj^.Uzunluk;
        end;

        // dhcp sunucusu tarafýndan teklif edilen ip adresini kabul et
        if(AnaMT = DHCP_MTIP_TEKLIF) then

          DHCPIstekMesajiGonder(FYanitDHCPSunucusu, FTeklifEdilenIP4Adresi)

        // onay mesajýnýn gelmesi durumunda toplanan tüm verileri ana deðiþkenlere ata
        else if(AnaMT = DHCP_MTIP_ONAY) then
        begin

          if(FBilgiMesajiGonderildi = False) then
          begin

            GAgBaglantilari.AB.IP4Adresim := FYanitIP4Adres;
            GAgBaglantilari.AB.AltAgMaskesi := FYanitAltAgMaskesi;
            GAgBaglantilari.AB.AgGecitAdresi := FYanitAgGecitAdresi;
            GAgBaglantilari.AB.DNSSunucusu := FYanitDNSSunucusu;
            GAgBaglantilari.AB.DHCPSunucusu := FYanitDHCPSunucusu;
            GAgBaglantilari.AB.IPKiraSuresi := FYanitIP4KiraSuresi;
            GAgBaglantilari.AB.IP4AdresiAlindi := True;

            DHCPBilgilendirmeMesajiGonder(FYanitIP4Adres);
            FBilgiMesajiGonderildi := True;

            // bu nesneyi oluþturulan baðlantýyý tüm bileþenleriyle (bu nesne de dahil) yok et
            TBaglanti(FBaglanti).FAB.BaglantiyiYoket(TBaglanti(FBaglanti));
          end;
        end;
      end;
    end;
  end;
end;

{==============================================================================
  DHCP sunucusundan otomatik ip adresi alýr
 ==============================================================================}
procedure TDHCPv4i.OtomatikIpAdresiAl;
begin

  DHCPKesifMesajiGonder;
end;

{==============================================================================
  DHCP sunucusuna keþif mesajý gönderir
 ==============================================================================}
procedure TDHCPv4i.DHCPKesifMesajiGonder;
var
  B: TBaglanti;
  DHCPYapi: PDHCP4Yapi;
  MACAdres: PMACAdres;
  i: TSayi1;
  p1: PSayi1;
  pc: PChar;
  DHCPYapiUzunlugu: TSayi4;
begin

  DHCPYapi := GetMem(4096);

	DHCPYapi^.Islem := DHCP_BOOT_MTIP_ISTEK;
	DHCPYapi^.DonanimTip := 1;		      // ethernet
	DHCPYapi^.DonanimUz := 6;		        // mac uzunluðu
	DHCPYapi^.RelayIcin := 0;
	DHCPYapi^.GonderenKimlik := ntohs(DHCP_GONDEREN_KIMLIK);
	DHCPYapi^.Sure := 0;
	DHCPYapi^.Bayraklar := 0;
	DHCPYapi^.IstemciIP4Adres := IP4Adres0;
	DHCPYapi^.IstemciyeAtanacakIP4Adres := IP4Adres0;
	DHCPYapi^.SunucuIP4Adres := IP4Adres0;
	DHCPYapi^.AgGecidiIP4Adres := IP4Adres0;

  // IstemciMACAdres 6 + 10 = 16 byte
  DHCPYapi^.IstemciMACAdres := GAygitlar.AktifEthernet.MACAdresim;
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
  p1^ := DHCP_MTIP_KESIF;
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 1;

  Inc(p1);

  p1^ := DHCP_SECIM_ISTEMCI_KIMLIK;
  Inc(p1);
  p1^ := 7;                               // uzunluk
  Inc(p1);
  p1^ := 1;
  Inc(p1);                                // donaným tipi = 1 (ethernet)
  MACAdres := PMACAdres(p1);
  MACAdres^ := GAygitlar.AktifEthernet.MACAdresim;
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 1 + 6;

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
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + i;

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
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 12;

  Inc(p1);

  p1^ := DHCP_SECIM_SON;
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 1;

  B := TBaglanti(FBaglanti);
  B.FDHCPv4i.FUDP.FIP4.FHedefMACAdres := MACAdres255;
  B.FDHCPv4i.FUDP.FIP4.FKaynakIPAdres := IP4Adres0;
  B.FDHCPv4i.FUDP.FIP4.FHedefIPAdres := IP4Adres255;
  B.FDHCPv4i.FUDP.PaketleVeGonder(@DHCPYapi[0], DHCPYapiUzunlugu);

  FreeMem(DHCPYapi, 4096);
end;

{==============================================================================
  DHCP sunucusuna istek mesajý gönderir
 ==============================================================================}
procedure TDHCPv4i.DHCPIstekMesajiGonder(ADHCPSunucuIP4Adres, AIstenenIP4Adres: TIP4Adres);
var
  B: TBaglanti;
  DHCPYapi: PDHCP4Yapi;
  IP4Adres: PIP4Adres;
  MACAdres: PMACAdres;
  i: TSayi1;
  p1: PSayi1;
  pc: PChar;
  DHCPYapiUzunlugu: TSayi4;
begin

  DHCPYapi := GetMem(4096);

	DHCPYapi^.Islem := DHCP_BOOT_MTIP_ISTEK;
	DHCPYapi^.DonanimTip := 1;		      // ethernet
	DHCPYapi^.DonanimUz := 6;		        // mac uzunluðu
	DHCPYapi^.RelayIcin := 0;
	DHCPYapi^.GonderenKimlik := ntohs(DHCP_GONDEREN_KIMLIK);
	DHCPYapi^.Sure := 0;
	DHCPYapi^.Bayraklar := 0;
	DHCPYapi^.IstemciIP4Adres := IP4Adres0;
	DHCPYapi^.IstemciyeAtanacakIP4Adres := IP4Adres0;
	DHCPYapi^.SunucuIP4Adres := IP4Adres0;
	DHCPYapi^.AgGecidiIP4Adres := IP4Adres0;

  // IstemciMACAdres 6 + 10 = 16 byte
  DHCPYapi^.IstemciMACAdres := GAygitlar.AktifEthernet.MACAdresim;
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
  p1^ := DHCP_MTIP_ISTEK;
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 1;

  Inc(p1);

  p1^ := DHCP_SECIM_ISTEMCI_KIMLIK;
  Inc(p1);
  p1^ := 7;                               // uzunluk
  Inc(p1);
  p1^ := 1;
  Inc(p1);                                // donaným tipi = 1 (ethernet)
  MACAdres := PMACAdres(p1);
  MACAdres^ := GAygitlar.AktifEthernet.MACAdresim;
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 1 + 6;

  Inc(p1, 6);

  // istenen ip adresi - 2 + 4 byte
  p1^ := DHCP_SECIM_ISTEK_IP_ADRES;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IP4Adres := Isaretci(p1);
  IP4Adres^ := AIstenenIP4Adres;
  Inc(IP4Adres);
  p1 := Isaretci(IP4Adres);
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 4;

  // istenen ip adresi - 2 + 4 byte
  p1^ := DHCP_SECIM_SUNUCU_TANIMLAYICI;
  Inc(p1);
  p1^ := 4;
  Inc(p1);
  IP4Adres := Isaretci(p1);
  IP4Adres^ := ADHCPSunucuIP4Adres;
  Inc(IP4Adres);
  p1 := Isaretci(IP4Adres);
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 4;

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
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + i;

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
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 3 + i;

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
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 12;

  Inc(p1);

  p1^ := DHCP_SECIM_SON;
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 1;

  B := TBaglanti(FBaglanti);
  B.FDHCPv4i.FUDP.FIP4.FHedefMACAdres := MACAdres255;
  B.FDHCPv4i.FUDP.FIP4.FKaynakIPAdres := IP4Adres0;
  B.FDHCPv4i.FUDP.FIP4.FHedefIPAdres := IP4Adres255;
  B.FDHCPv4i.FUDP.PaketleVeGonder(@DHCPYapi[0], DHCPYapiUzunlugu);

  FreeMem(DHCPYapi, 4096);
end;

{==============================================================================
  DHCP sunucusuna bilgilendirme mesajý gönderir
 ==============================================================================}
procedure TDHCPv4i.DHCPBilgilendirmeMesajiGonder(AIstemciIP4Adres: TIP4Adres);
var
  B: TBaglanti;
  DHCPYapi: PDHCP4Yapi;
  MACAdres: PMACAdres;
  i: TSayi1;
  p1: PSayi1;
  pc: PChar;
  DHCPYapiUzunlugu: TSayi4;
begin

  DHCPYapi := GetMem(4096);

	DHCPYapi^.Islem := DHCP_BOOT_MTIP_ISTEK;
	DHCPYapi^.DonanimTip := 1;		      // ethernet
	DHCPYapi^.DonanimUz := 6;		        // mac uzunluðu
	DHCPYapi^.RelayIcin := 0;
	DHCPYapi^.GonderenKimlik := ntohs(DHCP_GONDEREN_KIMLIK);
	DHCPYapi^.Sure := 0;
	DHCPYapi^.Bayraklar := 0;
	DHCPYapi^.IstemciIP4Adres := AIstemciIP4Adres;
	DHCPYapi^.IstemciyeAtanacakIP4Adres := IP4Adres0;
	DHCPYapi^.SunucuIP4Adres := IP4Adres0;
	DHCPYapi^.AgGecidiIP4Adres := IP4Adres0;

  // IstemciMACAdres 6 + 10 = 16 byte
  DHCPYapi^.IstemciMACAdres := GAygitlar.AktifEthernet.MACAdresim;
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
  p1^ := DHCP_BILGILENDIRME;
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 1;

  Inc(p1);

  p1^ := DHCP_SECIM_ISTEMCI_KIMLIK;
  Inc(p1);
  p1^ := 7;                               // uzunluk
  Inc(p1);
  p1^ := 1;
  Inc(p1);                                // donaným tipi = 1 (ethernet)
  MACAdres := PMACAdres(p1);
  MACAdres^ := GAygitlar.AktifEthernet.MACAdresim;
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 1 + 6;

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
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + i;

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
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 2 + 12;

  Inc(p1);

  p1^ := DHCP_SECIM_SON;
  DHCPYapiUzunlugu := DHCPYapiUzunlugu + 1;

  B := TBaglanti(FBaglanti);
  B.FDHCPv4i.FUDP.FIP4.FHedefMACAdres := MACAdres255;
  B.FDHCPv4i.FUDP.FIP4.FKaynakIPAdres := IP4Adres0;
  B.FDHCPv4i.FUDP.FIP4.FHedefIPAdres := IP4Adres255;
  B.FDHCPv4i.FUDP.PaketleVeGonder(@DHCPYapi[0], DHCPYapiUzunlugu);

  FreeMem(DHCPYapi, 4096);
end;

end.
