{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: dhcp_s.pas
  Dosya İşlevi: DHCP sunucu protokol işlevlerini yönetir

  Güncelleme Tarihi: 20/04/2025

 ==============================================================================}
{$mode objfpc}
unit dhcp_s;

interface

uses paylasim, dhcp;

const
  DHCP_KAYITSAYISI        = 256;
  ARPDONANIMTIP_ETHERNET  = TSayi2($0001);        // network byte sıralı
  ARPPROTOKOLTIP_IPV4     = TSayi2($0800);        // network byte sıralı

type
  // dhcp kayıt durumu
  TKayitDurumu = (kdBos, kdAtanacak, kdAtandi);

type
  PDHCPKayit = ^TDHCPKayit;
  TDHCPKayit = packed record
    Durum: TKayitDurumu;      // ip adres durumu
    MACAdres: TMACAdres;
  end;

procedure Yukle;
procedure DHCPSunucuPaketleriniIsle(ADHCPYapi: PDHCPYapi);
function HavuzdanKullanilabilirIPAdresiAl(AMACAdres: TMACAdres): TIPAdres;
function IPAdres0Mi(AIPAdres: TIPAdres): Boolean;
function IPAdres255Mi(AIPAdres: TIPAdres): Boolean;
function MACAdres0Mi(AMACAdres: TMACAdres): Boolean;
function MACAdres255Mi(AMACAdres: TMACAdres): Boolean;
function MACAdresEsitMi(AMACAdresA, AMACAdresB: TMACAdres): Boolean;
function IPAdresiAgAraligiIcindeMi(AIPAdres: TIPAdres): Boolean;

implementation

uses genel, donusum, sistemmesaj;

var
  DHCPKayitListesi: array[0..DHCP_KAYITSAYISI - 1] of PDHCPKayit;

{==============================================================================
  DHCP istemci girdilerini ilk değerlerle yükler
 ==============================================================================}
procedure Yukle;
var
  DHCPKayitBellekAdresi,
  Bellek: Isaretci;
  i: TISayi4;
begin

  // DHCP girişleri için bellekte yer tahsis et
  DHCPKayitBellekAdresi := GGercekBellek.Ayir(DHCP_KAYITSAYISI * SizeOf(TDHCPKayit));

  // girişlere ait işaretçileri bellek bölgeleriyle eşleştir
  Bellek := DHCPKayitBellekAdresi;

  for i := 0 to DHCP_KAYITSAYISI - 1 do
  begin

    DHCPKayitListesi[i] := Bellek;
    DHCPKayitListesi[i]^.MACAdres := MACAdres0;     // $00 = boş = kullanılabilir
    DHCPKayitListesi[i]^.Durum := kdBos;

    Bellek += SizeOf(TDHCPKayit);
  end;

  // ilk 20 girişi sisteme ayır
  { TODO - bu durum deneme amaçlıdır fakat dhcp sunucusunun rezerv planı oluşturularak
    bu plan dahilinde işleyecek }
  for i := 0 to 19 do
  begin

    DHCPKayitListesi[i]^.MACAdres := MACAdres255;   // $FF = dolu = kullanılmakta
    DHCPKayitListesi[i]^.Durum := kdAtandi;
  end;
end;

{==============================================================================
  havuzdan kullanılabilir ip adresi alır
 ==============================================================================}
function HavuzdanKullanilabilirIPAdresiAl(AMACAdres: TMACAdres): TIPAdres;
var
  KullanilabilirIP: TIPAdres;
  i: TISayi4;
begin

  KullanilabilirIP := GAgBilgisi.IP4Adres;

  for i := 0 to DHCP_KAYITSAYISI - 1 do
  begin

    if(DHCPKayitListesi[i]^.Durum = kdBos) then
    begin

      if(MACAdres0Mi(DHCPKayitListesi[i]^.MACAdres)) then
      begin

        KullanilabilirIP[3] := i;
        DHCPKayitListesi[i]^.Durum := kdAtanacak;
        DHCPKayitListesi[i]^.MACAdres := AMACAdres;
        Exit(KullanilabilirIP);
      end;
    end;
  end;

  Result := IPAdres0;
end;

{==============================================================================
  istenen ip adresinin istemciye verilip verilmeyeceğine karar verir
 ==============================================================================}
function IPAdresiIstemciyeVerilsinMi(AIstenenIPAdres: TIPAdres; AMACAdres: TMACAdres): Boolean;
var
  IPAdres: TIPAdres;
  i: TISayi4;
  AyniAgda: Boolean;
begin

  IPAdres := AIstenenIPAdres;

  AyniAgda := IPAdresiAgAraligiIcindeMi(IPAdres);
  if not(AyniAgda) then Exit(False);

  for i := 0 to DHCP_KAYITSAYISI - 1 do
  begin

    if(DHCPKayitListesi[i]^.Durum = kdAtanacak) or (DHCPKayitListesi[i]^.Durum = kdAtandi) then
    begin

      if(MACAdresEsitMi(DHCPKayitListesi[i]^.MACAdres, AMACAdres)) then
      begin

        DHCPKayitListesi[i]^.Durum := kdAtandi;
        DHCPKayitListesi[i]^.MACAdres := AMACAdres;
        Exit(True);
      end;
    end;
  end;

  Result := False;
end;

// DHCP sunucu paketlerini işler
procedure DHCPSunucuPaketleriniIsle(ADHCPYapi: PDHCPYapi);
var
  DHCPMesaj: PDHCPMesaj;
  AnaMT, MT, DonanimTipi, i: TSayi1;
  IstemciIP, IstenenIPAdres,
  DHCPSunucuIPAdresi, IPAdres: TIPAdres;
  MACAdres, IstemciMACAdres: TMACAdres;
  p1: PByte;
  IstemciAdi, SaticiSTanitici: string;
begin

  // gelen mesajın DHCP_SECIM_MESAJ_TIP değeri
  AnaMT := 0;

  IstemciIP := ADHCPYapi^.IstemciIPAdres;
  IstemciMACAdres := ADHCPYapi^.IstemciMACAdres;

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
      MACAdres := PMACAdres(@DHCPMesaj^.Mesaj + 1)^;
    end
    else if(MT = DHCP_SECIM_YEREL_AD) then

      IstemciAdi := PKarakterKatari(@DHCPMesaj^.Mesaj - 1)^

    else if(MT = DHCP_SECIM_ISTEK_IP_ADRES) then

      IstenenIPAdres := PIPAdres(@DHCPMesaj^.Mesaj)^

    else if(MT = DHCP_SECIM_SUNUCU_TANIMLAYICI) then

      DHCPSunucuIPAdresi := PIPAdres(@DHCPMesaj^.Mesaj)^

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

      IPAdres := HavuzdanKullanilabilirIPAdresiAl(IstemciMACAdres);
      if(IPAdres0Mi(IPAdres) = False) then
        DHCPTeklifMesajiGonder(htons(ADHCPYapi^.GonderenKimlik), IPAdres,
        IstemciMACAdres)
    end

    else if(AnaMT = DHCP_MTIP_ISTEK) then
    begin

      if(IPAdresiIstemciyeVerilsinMi(IstenenIPAdres, IstemciMACAdres)) then

        DHCPIstegeOnayMesajiGonder(htons(ADHCPYapi^.GonderenKimlik), IstenenIPAdres, MACAdres)
      else DHCPRetMesajiGonder(htons(ADHCPYapi^.GonderenKimlik), MACAdres);
    end
    else if(AnaMT = DHCP_BILGILENDIRME) then
    begin

        DHCPBilgilendirmeyeOnayMesajiGonder(htons(ADHCPYapi^.GonderenKimlik), IstemciIP, MACAdres);
    end;
  end;
end;

function IPAdres0Mi(AIPAdres: TIPAdres): Boolean;
var
  i: TSayi4;
begin

  for i := 0 to 3 do
  begin

    if(AIPAdres[i] <> 0) then Exit(False);
  end;

  Result := True;
end;

function IPAdres255Mi(AIPAdres: TIPAdres): Boolean;
var
  i: TSayi4;
begin

  for i := 0 to 3 do
  begin

    if(AIPAdres[i] <> 255) then Exit(False);
  end;

  Result := True;
end;

function MACAdres0Mi(AMACAdres: TMACAdres): Boolean;
var
  i: TSayi4;
begin

  for i := 0 to 5 do
  begin

    if(AMACAdres[i] <> 0) then Exit(False);
  end;

  Result := True;
end;

function MACAdres255Mi(AMACAdres: TMACAdres): Boolean;
var
  i: TSayi4;
begin

  for i := 0 to 5 do
  begin

    if(AMACAdres[i] <> 255) then Exit(False);
  end;

  Result := True;
end;

function MACAdresEsitMi(AMACAdresA, AMACAdresB: TMACAdres): Boolean;
var
  i: TSayi4;
begin

  for i := 0 to 5 do
  begin

    if(AMACAdresA[i] <> AMACAdresB[i]) then Exit(False);
  end;

  Result := True;
end;

// ip adresinin ağ adres aralığında olup olmadığını kontrol eder
// örnek:
// istenen ip adresi: 192.168.1.110
// dhcp ip adresi   : 192.168.1.1
// ilk 3 byte değerinin aynı olması ip adresinin aynı ağda olduğunu gösterir
function IPAdresiAgAraligiIcindeMi(AIPAdres: TIPAdres): Boolean;
var
  i: TSayi4;
begin

  for i := 0 to 2 do
  begin

    if(AIPAdres[i] <> GAgBilgisi.IP4Adres[i]) then Exit(False);
  end;

  Result := True;
end;

end.
