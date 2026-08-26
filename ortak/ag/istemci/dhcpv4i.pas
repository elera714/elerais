{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: dhcpv4i.pas
  Dosya Ýþlevi: DHCP v4 istemci protokol iþlevlerini yönetir

  Güncelleme Tarihi: 26/08/20256

 ==============================================================================}
{$mode objfpc}
unit dhcpv4i;

interface

uses paylasim, baglantilar, dhcpv4;

type
  TDHCPv4i = class(TDHCPv4)
  public
    FYanitIP4Adres, FYanitAltAgMaskesi,
    FYanitAgGecitAdresi, FYanitDNSSunucusu,
    FYanitDHCPSunucusu, FTeklifEdilenIPAdresi: TIP4Adres;
    FYanitIPKiraSuresi: TSayi4;
    constructor Create;
    procedure DHCPIpAdresiAl;
  end;

var
  GDHCPv4i: TDHCPv4i;

procedure IslevDHCPv4i(AIletisimTipi: TIletisimTipi; ABaglanti: TBaglanti;
  ADHCP4Yapi: PDHCP4Yapi);

implementation

uses donusum, istemciler;

{==============================================================================
  dhcp istemcisi ana yükleme iþlevlerini içerir
 ==============================================================================}
constructor TDHCPv4i.Create;
begin

  inherited;

  FYanitIP4Adres := IP4Adres0;
  FYanitAltAgMaskesi := IP4Adres0;
  FYanitAgGecitAdresi := IP4Adres0;
  FYanitDNSSunucusu := IP4Adres0;
  FYanitDHCPSunucusu := IP4Adres0;
  FTeklifEdilenIPAdresi := IP4Adres0;
  FYanitIPKiraSuresi := 0;
end;

{==============================================================================
  DHCP sunucularýna keþif mesajý gönderir
 ==============================================================================}
procedure TDHCPv4i.DHCPIpAdresiAl;
begin

  DHCPKesifMesajiGonder;
end;

{==============================================================================
  dhcp istemcisine gelen paketleri iþler
 ==============================================================================}
procedure IslevDHCPv4i(AIletisimTipi: TIletisimTipi; ABaglanti: TBaglanti;
  ADHCP4Yapi: PDHCP4Yapi);
var
  DHCPMesaj: PDHCPMesaj;
  AnaMT, MT, i: TSayi1;
  p1: PByte;
begin

  // gelen mesajýn DHCP_SECIM_MESAJ_TIP deðeri
  AnaMT := 0;

  // alýnan SihirliCerez deðeri gönderdiðimiz deðer mi?
  if(htons(ADHCP4Yapi^.SihirliCerez) = DHCP_SIHIRLI_CEREZ) then
  begin

    // alýnan GonderenKimlik deðeri gönderdiðimiz deðer mi?
    if(ntohs(ADHCP4Yapi^.GonderenKimlik) = DHCP_GONDEREN_KIMLIK) then
    begin

      // alýnan mesaj bir yanýt mesajý mý?
      if(ADHCP4Yapi^.Islem = DHCP_BOOT_MTIP_YANIT) then
      begin

        // seçenek olarak alýnan yapýyý döngü içerisinde irdele
        DHCPMesaj := @ADHCP4Yapi^.DigerSecenekler;
        MT := DHCPMesaj^.Tip;
        i := DHCPMesaj^.Uzunluk;

        // seçeneðin sonuna gelinceye kadar tüm deðerleri oku
        while MT <> DHCP_SECIM_SON do
        begin

          if(MT = DHCP_SECIM_ALTAG_MASKESI) and (i = 4) then

            GDHCPv4i.FYanitAltAgMaskesi := PIP4Adres(@DHCPMesaj^.Mesaj)^

          else if(MT = DHCP_SECIM_YONLENDIRICI) and (i = 4) then

            GDHCPv4i.FYanitAgGecitAdresi := PIP4Adres(@DHCPMesaj^.Mesaj)^

          else if(MT = DHCP_SECIM_DNS) and (i = 4) then

            GDHCPv4i.FYanitDNSSunucusu := PIP4Adres(@DHCPMesaj^.Mesaj)^

          else if(MT = DHCP_SECIM_SUNUCU_TANIMLAYICI) then

            GDHCPv4i.FYanitDHCPSunucusu := PIP4Adres(@DHCPMesaj^.Mesaj)^

          else if(MT = DHCP_SECIM_IP_KIRALAMA_SURESI) then

            GDHCPv4i.FYanitIPKiraSuresi := ntohs(PLongWord(@DHCPMesaj^.Mesaj)^)

          else if(MT = DHCP_SECIM_MESAJ_TIP) then
          begin

            AnaMT := PByte(@DHCPMesaj^.Mesaj)^;
            if(AnaMT = DHCP_MTIP_ONAY) then
            begin

              GDHCPv4i.FYanitIP4Adres := ADHCP4Yapi^.IstemciyeAtanacakIPAdresi;
            end
            else if(AnaMT = DHCP_MTIP_TEKLIF) then
            begin

              GDHCPv4i.FTeklifEdilenIPAdresi := ADHCP4Yapi^.IstemciyeAtanacakIPAdresi;
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

          GDHCPv4i.DHCPIstekMesajiGonder(GDHCPv4i.FYanitDHCPSunucusu, GDHCPv4i.FTeklifEdilenIPAdresi)

        // onay mesajýnýn gelmesi durumunda toplanan tüm verileri ana deðiþkenlere ata
        else if(AnaMT = DHCP_MTIP_ONAY) then
        begin

          if(BilgiMesajiGonderildi = False) then
          begin

            ABaglanti.IP4Adres := GDHCPv4i.FYanitIP4Adres;
            ABaglanti.AltAgMaskesi := GDHCPv4i.FYanitAltAgMaskesi;
            ABaglanti.AgGecitAdresi := GDHCPv4i.FYanitAgGecitAdresi;
            ABaglanti.DNSSunucusu := GDHCPv4i.FYanitDNSSunucusu;
            ABaglanti.DHCPSunucusu := GDHCPv4i.FYanitDHCPSunucusu;
            ABaglanti.IPKiraSuresi := GDHCPv4i.FYanitIPKiraSuresi;
            ABaglanti.IPAdresiAlindi := True;

            GDHCPv4i.DHCPBilgilendirmeMesajiGonder(GDHCPv4i.FYanitIP4Adres);
            BilgiMesajiGonderildi := True;

            GIstemciler.Cikar(ptUDP, DHCP_ISTEMCI_PORT, DHCP_SUNUCU_PORT);
          end;
        end;
      end;
    end;
  end;
end;

end.
