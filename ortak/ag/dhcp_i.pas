{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: dhcp_i.pas
  Dosya İşlevi: DHCP protokol işlevlerini yönetir

  Güncelleme Tarihi: 18/06/2026

 ==============================================================================}
{$mode objfpc}
unit dhcp_i;

interface

uses paylasim, dhcp4_i;

procedure DHCPIstemciPaketleriniIsle(ADHCPYapi: PDHCP4Yapi);

implementation

uses donusum, sistemmesaj, ag;

var
  // bilgi (inform) mesajının gönderilip gönderilmediği
  BilgiMesajiGonderildi: Boolean = False;

// DHCP istemci paketlerini işler
procedure DHCPIstemciPaketleriniIsle(ADHCPYapi: PDHCP4Yapi);
var
  YanitIP4Adres, YanitAltAgMaskesi,
  YanitAgGecitAdresi, YanitDNSSunucusu,
  YanitDHCPSunucusu, TeklifEdilenIPAdresi: TIP4Adres;
  YanitIPKiraSuresi: TSayi4;
  DHCPMesaj: PDHCPMesaj;
  AnaMT, MT, i: TSayi1;
  p1: PByte;
begin

  // gelen mesajın DHCP_SECIM_MESAJ_TIP değeri
  AnaMT := 0;

  // alınan SihirliCerez değeri gönderdiğimiz değer mi?
  if(htons(ADHCPYapi^.SihirliCerez) = DHCP_SIHIRLI_CEREZ) then
  begin

    // alınan GonderenKimlik değeri gönderdiğimiz değer mi?
    if(ntohs(ADHCPYapi^.GonderenKimlik) = DHCP_GONDEREN_KIMLIK) then
    begin

      // alınan mesaj bir yanıt mesajı mı?
      if(ADHCPYapi^.Islem = DHCP_BOOT_MTIP_YANIT) then
      begin

        // seçenek olarak alınan yapıyı döngü içerisinde irdele
        DHCPMesaj := @ADHCPYapi^.DigerSecenekler;
        MT := DHCPMesaj^.Tip;
        i := DHCPMesaj^.Uzunluk;

        // seçeneğin sonuna gelinceye kadar tüm değerleri oku
        while MT <> DHCP_SECIM_SON do
        begin

          if(MT = DHCP_SECIM_ALTAG_MASKESI) and (i = 4) then

            YanitAltAgMaskesi := PIP4Adres(@DHCPMesaj^.Mesaj)^

          else if(MT = DHCP_SECIM_YONLENDIRICI) and (i = 4) then

            YanitAgGecitAdresi := PIP4Adres(@DHCPMesaj^.Mesaj)^

          else if(MT = DHCP_SECIM_DNS) and (i = 4) then

            YanitDNSSunucusu := PIP4Adres(@DHCPMesaj^.Mesaj)^

          else if(MT = DHCP_SECIM_SUNUCU_TANIMLAYICI) then

            YanitDHCPSunucusu := PIP4Adres(@DHCPMesaj^.Mesaj)^

          else if(MT = DHCP_SECIM_IP_KIRALAMA_SURESI) then

            YanitIPKiraSuresi := ntohs(PLongWord(@DHCPMesaj^.Mesaj)^)

          else if(MT = DHCP_SECIM_MESAJ_TIP) then
          begin

            AnaMT := PByte(@DHCPMesaj^.Mesaj)^;
            if(AnaMT = DHCP_MTIP_ONAY) then
            begin

              YanitIP4Adres := ADHCPYapi^.IstemciyeAtanacakIPAdresi;
            end
            else if(AnaMT = DHCP_MTIP_TEKLIF) then
            begin

              TeklifEdilenIPAdresi := ADHCPYapi^.IstemciyeAtanacakIPAdresi;
            end;
          end;

          // bir sonraki seçeneğe konumlan
          p1 := Isaretci(DHCPMesaj);
          Inc(p1, i + 2);
          DHCPMesaj := Isaretci(p1);
          MT := DHCPMesaj^.Tip;
          i := DHCPMesaj^.Uzunluk;
        end;

        // dhcp sunucusu tarafından teklif edilen ip adresini kabul et
        if(AnaMT = DHCP_MTIP_TEKLIF) then

          DHCPIstekMesajiGonder(YanitDHCPSunucusu, TeklifEdilenIPAdresi)

        // onay mesajının gelmesi durumunda toplanan tüm verileri ana değişkenlere ata
        else if(AnaMT = DHCP_MTIP_ONAY) then
        begin

          if(BilgiMesajiGonderildi = False) then
          begin

            GAg0.IP4Adres := YanitIP4Adres;
            GAg0.AltAgMaskesi := YanitAltAgMaskesi;
            GAg0.AgGecitAdresi := YanitAgGecitAdresi;
            GAg0.DNSSunucusu := YanitDNSSunucusu;
            GAg0.DHCPSunucusu := YanitDHCPSunucusu;
            GAg0.IPKiraSuresi := YanitIPKiraSuresi;
            GAg0.IPAdresiAlindi := True;

            DHCPBilgilendirmeMesajiGonder(YanitIP4Adres);
            BilgiMesajiGonderildi := True;
          end;
        end;
      end;
    end;
  end;
end;

end.
