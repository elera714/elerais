{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: dhcp_i.pas
  Dosya İşlevi: DHCP istemci protokol işlevlerini yönetir

  Güncelleme Tarihi: 20/04/2025

 ==============================================================================}
{$mode objfpc}
unit dhcp_i;

interface

uses paylasim, dhcp;

procedure DHCPIstemciPaketleriniIsle(ADHCPYapi: PDHCPYapi);

implementation

uses donusum, sistemmesaj;

var
  // bilgi (inform) mesajının gönderilip gönderilmediği
  BilgiMesajiGonderildi: Boolean = False;

// DHCP istemci paketlerini işler
procedure DHCPIstemciPaketleriniIsle(ADHCPYapi: PDHCPYapi);
var
  YanitAgBilgisi: TAgBilgisi;
  TeklifEdilenIPAdresi: TIPAdres;
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

            YanitAgBilgisi.AltAgMaskesi := PIPAdres(@DHCPMesaj^.Mesaj)^

          else if(MT = DHCP_SECIM_YONLENDIRICI) and (i = 4) then

            YanitAgBilgisi.AgGecitAdresi := PIPAdres(@DHCPMesaj^.Mesaj)^

          else if(MT = DHCP_SECIM_DNS) and (i = 4) then

            YanitAgBilgisi.DNSSunucusu := PIPAdres(@DHCPMesaj^.Mesaj)^

          else if(MT = DHCP_SECIM_SUNUCU_TANIMLAYICI) then

            YanitAgBilgisi.DHCPSunucusu := PIPAdres(@DHCPMesaj^.Mesaj)^

          else if(MT = DHCP_SECIM_IP_KIRALAMA_SURESI) then

            YanitAgBilgisi.IPKiraSuresi := ntohs(PLongWord(@DHCPMesaj^.Mesaj)^)

          else if(MT = DHCP_SECIM_MESAJ_TIP) then
          begin

            AnaMT := PByte(@DHCPMesaj^.Mesaj)^;
            if(AnaMT = DHCP_MTIP_ONAY) then
            begin

              YanitAgBilgisi.IP4Adres := ADHCPYapi^.IstemciyeAtanacakIPAdresi;
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

          DHCPIstekMesajiGonder(YanitAgBilgisi.DHCPSunucusu, TeklifEdilenIPAdresi)

        // onay mesajının gelmesi durumunda toplanan tüm verileri ana değişkenlere ata
        else if(AnaMT = DHCP_MTIP_ONAY) then
        begin

          if(BilgiMesajiGonderildi = False) then
          begin

            GAgBilgisi.IP4Adres := YanitAgBilgisi.IP4Adres;
            GAgBilgisi.AltAgMaskesi := YanitAgBilgisi.AltAgMaskesi;
            GAgBilgisi.AgGecitAdresi := YanitAgBilgisi.AgGecitAdresi;
            GAgBilgisi.DNSSunucusu := YanitAgBilgisi.DNSSunucusu;
            GAgBilgisi.DHCPSunucusu := YanitAgBilgisi.DHCPSunucusu;
            GAgBilgisi.IPKiraSuresi := YanitAgBilgisi.IPKiraSuresi;
            GAgBilgisi.IPAdresiAlindi := True;

            DHCPBilgilendirmeMesajiGonder(YanitAgBilgisi.IP4Adres);
            BilgiMesajiGonderildi := True;
          end;
        end;
      end;
    end;
  end;
end;

end.
