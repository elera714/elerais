{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: dhcp_s.pas
  Dosya İşlevi: DHCP sunucu protokol işlevlerini yönetir

  Güncelleme Tarihi: 22/07/2025

 ==============================================================================}
{$mode objfpc}
unit dhcp_s;

interface

uses paylasim, dhcp;

const
  USTSINIR_DHCPKAYIT      = 256;
  AYRILMIS_IPSAYISI       = 20;                   // 0..AYRILMIS_IPSAYISI - 1 aralığı ayrılacak
  ARPDONANIMTIP_ETHERNET  = TSayi2($0001);        // network byte sıralı
  ARPPROTOKOLTIP_IPV4     = TSayi2($0800);        // network byte sıralı

type
  // dhcp kayıt durumu
  TKayitDurumu = (kdAyrildi, kdAtanacak, kdAtandi);

type
  PDHCPKayit = ^TDHCPKayit;
  TDHCPKayit = record
    Durum: TKayitDurumu;      // ip adres kayıt durumu
    MACAdres: TMACAdresIslev;
  end;

type
  TDHCPSunucu = object
  private
    FDHCPKayitListesi: array[0..USTSINIR_DHCPKAYIT - 1] of PDHCPKayit;
    function DHCPKayitAl(ASiraNo: TSayi4): PDHCPKayit;
    procedure DHCPKayitYaz(ASiraNo: TSayi4; ADHCPKayit: PDHCPKayit);
  public
    procedure Yukle;
    function HavuzdanIPAdresiAl(AMACAdres: TMACAdresIslev): TIPAdresIslev;
    function IPAdresiVerilsinMi(AIstenenIPAdres: TIPAdresIslev; AMACAdres: TMACAdresIslev): Boolean;
    property DHCPKayit[ASiraNo: TSayi4]: PDHCPKayit read DHCPKayitAl write DHCPKayitYaz;
    procedure DHCPSunucuPaketleriniIsle(ADHCPYapi: PDHCPYapi);
  end;

var
  DHCPSunucu0: TDHCPSunucu;
  DHCPSunucuKilit: TSayi4 = 0;

implementation

uses donusum, sistemmesaj;

{==============================================================================
  dhcp sunucusu ana yükleme işlevlerini içerir
 ==============================================================================}
procedure TDHCPSunucu.Yukle;
var
  i: TSayi4;
begin

  for i := 0 to USTSINIR_DHCPKAYIT - 1 do DHCPKayit[i] := nil;

  // AYRILMIS_IPSAYISI kadar girişi farklı amaçlar için ayır
  { TODO - bu durum deneme amaçlıdır fakat dhcp sunucusunun rezerv planı oluşturularak
    bu plan dahilinde işleyecek }
  for i := 0 to AYRILMIS_IPSAYISI - 1 do
  begin

    DHCPKayit[i] := GetMem(SizeOf(TDHCPKayit));
    DHCPKayit[i]^.Durum := kdAyrildi;
  end;
end;

function TDHCPSunucu.DHCPKayitAl(ASiraNo: TSayi4): PDHCPKayit;
begin

  // istenen verinin belirtilen aralıkta olup olmadığını kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_DHCPKAYIT) then
    Result := FDHCPKayitListesi[ASiraNo]
  else Result := nil;
end;

procedure TDHCPSunucu.DHCPKayitYaz(ASiraNo: TSayi4; ADHCPKayit: PDHCPKayit);
begin

  // istenen verinin belirtilen aralıkta olup olmadığını kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_DHCPKAYIT) then
    FDHCPKayitListesi[ASiraNo] := ADHCPKayit;
end;

{==============================================================================
  istemci için havuzdan kullanılabilir ip adresi alır
 ==============================================================================}
function TDHCPSunucu.HavuzdanIPAdresiAl(AMACAdres: TMACAdresIslev): TIPAdresIslev;
var
  D: PDHCPKayit;
  KullanilabilirIP: TIPAdresIslev;
  i: TSayi4;
begin

  KullanilabilirIP.IPAdres := GAgBilgisi.IP4Adres;

  for i := AYRILMIS_IPSAYISI to USTSINIR_DHCPKAYIT - 1 do
  begin

    if(DHCPKayit[i] = nil) then
    begin

      // yeni ip kaydı için bellekte yer ayır
      D := PDHCPKayit(GetMem(SizeOf(TDHCPKayit)));

      // ip kaydını listeye kaydet
      DHCPKayit[i] := D;

      D^.Durum := kdAtanacak;
      D^.MACAdres := AMACAdres;

      KullanilabilirIP.IPAdres[3] := i;
      Exit(KullanilabilirIP);
    end;
  end;

  KullanilabilirIP.Sifirla;

  Result := KullanilabilirIP;
end;

{==============================================================================
  istenen ip adresinin istemciye verilip verilmeyeceğine karar verir
 ==============================================================================}
function TDHCPSunucu.IPAdresiVerilsinMi(AIstenenIPAdres: TIPAdresIslev; AMACAdres: TMACAdresIslev): Boolean;
var
  D: PDHCPKayit;
  IPAdres: TIPAdresIslev;
  i: TSayi4;
  AyniAgda: Boolean;
begin

  IPAdres := AIstenenIPAdres;

  AyniAgda := IPAdres.IPAgAraligiIcinde(GAgBilgisi.IP4Adres);
  if not(AyniAgda) then Exit(False);

  for i := AYRILMIS_IPSAYISI to USTSINIR_DHCPKAYIT - 1 do
  begin

    D := DHCPKayit[i];
    if not(D = nil) and ((D^.Durum = kdAtanacak) or (D^.Durum = kdAtandi)) then
    begin

      if(AMACAdres = D^.MACAdres) then
      begin

        D^.Durum := kdAtandi;
        D^.MACAdres := AMACAdres;
        Exit(True);
      end;
    end;
  end;

  Result := False;
end;

{==============================================================================
  DHCP sunucu paketlerini işler
 ==============================================================================}
procedure TDHCPSunucu.DHCPSunucuPaketleriniIsle(ADHCPYapi: PDHCPYapi);
var
  DHCPMesaj: PDHCPMesaj;
  AnaMT, MT, DonanimTipi, i: TSayi1;
  IstemciIP, DHCPSunucuIPAdresi,
  IstenenIPAdres, IPAdres: TIPAdresIslev;
  MACAdres, IstemciMACAdres: TMACAdresIslev;
  p1: PByte;
  IstemciAdi, SaticiSTanitici: string;
begin

  while KritikBolgeyeGir(DHCPSunucuKilit) = False do;

  IstenenIPAdres.Sifirla;
  MACAdres.Sifirla;

  // gelen mesajın DHCP_SECIM_MESAJ_TIP değeri
  AnaMT := 0;

  IstemciIP.IPAdres := ADHCPYapi^.IstemciIPAdres;
  IstemciMACAdres.MACAdres := ADHCPYapi^.IstemciMACAdres;

  // seçenek olarak alınan yapıyı döngü içerisinde irdele
  DHCPMesaj := @ADHCPYapi^.DigerSecenekler;
  MT := DHCPMesaj^.Tip;
  i := DHCPMesaj^.Uzunluk;

  // seçeneğin sonuna gelinceye kadar tü_IPAdres seçenekleri işleme al
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

      IstenenIPAdres.IPAdres := PIPAdres(@DHCPMesaj^.Mesaj)^

    else if(MT = DHCP_SECIM_SUNUCU_TANIMLAYICI) then

      DHCPSunucuIPAdresi.IPAdres := PIPAdres(@DHCPMesaj^.Mesaj)^

    else if(MT = DHCP_SECIM_SATICI_SINIF_TANITICISI) then

      SaticiSTanitici := PKarakterKatari(@DHCPMesaj^.Mesaj - 1)^

    else
    begin

      //SISTEM_MESAJ(mtBilgi, RENK_MOR, 'DHCP-S-Bilinmeyen Mesaj Tipi: %d', [MT]);
    end;

    // bir sonraki seçeneğe konumlan
    p1 := Isaretci(DHCPMesaj);
    Inc(p1, i + 2);
    DHCPMesaj := Isaretci(p1);
    MT := DHCPMesaj^.Tip;
    i := DHCPMesaj^.Uzunluk;
  end;

{    SISTEM_MESAJ(mtBilgi, RENK_MOR, 'DHCP-ADHCPKayit^.GonderenKimlik: %x', [ADHCPYapi^.GonderenKimlik]);
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'DHCP-Mesaj Tipi: %d', [MT]);
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'DHCP-Donanım Tipi: %d', [DonanimTipi]);
  SISTEM_MESAJ_MAC(mtBilgi, RENK_MOR, 'DHCP-MAC Adres: ', MACAdres);
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'DHCP-İstemci Adı: %s', [IstemciAdi]);
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'DHCP-SaticiSTanitici: %s', [SaticiSTanitici]);}

  // alınan mesaj bir yanıt _IPAdresı?
  if(ADHCPYapi^.Islem = DHCP_BOOT_MTIP_ISTEK) then
  begin


    if(AnaMT = DHCP_MTIP_KESIF) then
    begin

      IPAdres := DHCPSunucu0.HavuzdanIPAdresiAl(IstemciMACAdres);
      if(IPAdres.IPAdres0Mi = False) then
        DHCPTeklifMesajiGonder(htons(ADHCPYapi^.GonderenKimlik), IPAdres, IstemciMACAdres.MACAdres)
    end

    else if(AnaMT = DHCP_MTIP_ISTEK) then
    begin

      if(DHCPSunucu0.IPAdresiVerilsinMi(IstenenIPAdres, IstemciMACAdres)) then

        DHCPIstegeOnayMesajiGonder(htons(ADHCPYapi^.GonderenKimlik), IstenenIPAdres, MACAdres)
      else DHCPRetMesajiGonder(htons(ADHCPYapi^.GonderenKimlik), MACAdres);
    end
    else if(AnaMT = DHCP_BILGILENDIRME) then
    begin

      DHCPBilgilendirmeyeOnayMesajiGonder(htons(ADHCPYapi^.GonderenKimlik), IstemciIP, MACAdres);
    end;
  end;

  KritikBolgedenCik(DHCPSunucuKilit);
end;

end.
