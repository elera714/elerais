{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: icmp6.pas
  Dosya Ýþlevi: ICMP v6 protokol iþlevlerini yönetir

  Güncelleme Tarihi: 09/06/2026

 ==============================================================================}
{$mode objfpc}
//{$DEFINE ICMP6_HATAAYIKLA}
unit icmp6;

interface

uses paylasim, ag;

const
  ICMP6_BASLIK_UZUNLUGU   = 32;
  ICMP6_EKBASLIK_UZUNLUGU = 40;

const
  // ff02::1:ffxx:xxxx
  TalepDugumAdresi: TIP6Adres = ($FF,$02, $00,$00, $00,$00, $00,$00,
    $00,$00, $00,$01, $FF,$00, $00,$00);

const
  // çoklu yayýn için kullanýlacak mac adres
  COKLUYAYIN_MACADRES: TMACAdres = ($33, $33, $00, $00, $00, $00);

const
  ICMP6_PING_ISTEK  = $80;      // ping istek mesajý
  ICMP6_PING_YANIT  = $81;      // ping yanýt mesajý
  ICMP6_KOMSU_ISTEK = $87;      // 135 (NS) - komþudan istekte bulunma
  ICMP6_KOMSU_ILAN  = $88;      // 136 (NA) - komþunun ICMP6_KOMSU_ISTEK'ine cevabý

type
  PICMP6Secenekler = ^TICMP6Secenekler;
  TICMP6Secenekler = packed record
    Tip: TSayi1;
    Uzunluk: TSayi1;
    Adres: TMACAdres;
  end;

type
  PICMP6Paket = ^TICMP6Paket;
  TICMP6Paket = packed record
    MesajTipi,
    Kod: TSayi1;
    SaglamaToplami: TSayi2;
    Bayraklar: TSayi4;
    HedefAdres: TIP6Adres;
    Secenekler: TICMP6Secenekler;
  end;

type
  PPingPaket = ^TPingPaket;
  TPingPaket = packed record
    MesajTipi,
    Kod: TSayi1;
    SaglamaToplami: TSayi2;
    Tanimlayici,
    SiraNo: TSayi2;
    Veri: Isaretci;
  end;

type
  // TICMP6Paket yapýsýnýn hesaplanmasý için gerekli ek baþlýk
  PEkBaslik = ^TEkBaslik;
  TEkBaslik = packed record         // pseudo header
    KaynakIP: TIP6Adres;
    HedefIP: TIP6Adres;
    Uzunluk: TSayi4;                // icmp v6 paket ve içeriði
    Sifir: array[0..2] of TSayi1;
    Protokol: TSayi1;               // PROTOKOL_ICMP6 deðeri ($3A)
  end;

procedure KomsuIstegiGonder(AIP6Adres: TIP6Adres);
procedure PingMesajiGonder(AMesajTipi: TSayi4; AHedefIPAdres: TIP6Adres;
  AHedefMACAdres: TMACAdres; ASiraNo: TSayi4; AVeri: Isaretci; AVeriU: TSayi4);
procedure ICMPIstegiGonder(AMesajTipi: TSayi4; AHedefIPAdres: TIP6Adres;
  AHedefMACAdres: TMACAdres; ASorguYanitAdres: TIP6Adres);
procedure ICMPPaketleriniIsle(AEthernetPaket: PEthernetPaket);

implementation

uses ip6, sistemmesaj, donusum, islevler;

{==============================================================================
  belirtilen ip v6 adresine komþu isteði gönderir
 ==============================================================================}
procedure KomsuIstegiGonder(AIP6Adres: TIP6Adres);
var
  HedefIPAdres: TIP6Adres;
  HedefMACAdres: TMACAdres;
begin

  // ip katmaný - ip adresini hazýrla
  HedefIPAdres := TalepDugumAdresi;
  HedefIPAdres[13] := AIP6Adres[13];
  HedefIPAdres[14] := AIP6Adres[14];
  HedefIPAdres[15] := AIP6Adres[15];

  // ethernet katmaný - mac adresini hazýrla
  HedefMACAdres := COKLUYAYIN_MACADRES;
  HedefMACAdres[2] := HedefIPAdres[12];
  HedefMACAdres[3] := HedefIPAdres[13];
  HedefMACAdres[4] := HedefIPAdres[14];
  HedefMACAdres[5] := HedefIPAdres[15];

  ICMPIstegiGonder(ICMP6_KOMSU_ISTEK, HedefIPAdres, HedefMACAdres, AIP6Adres);
end;

{==============================================================================
  ping mesajý (istek / yanýt) gönderir
 ==============================================================================}
procedure PingMesajiGonder(AMesajTipi: TSayi4; AHedefIPAdres: TIP6Adres;
  AHedefMACAdres: TMACAdres; ASiraNo: TSayi4; AVeri: Isaretci; AVeriU: TSayi4);
var
  PingPaket: PPingPaket;
  EKBaslik: TEkBaslik;
  SaglamaToplami: TSayi2;
begin

  // protokol verisi için bellekte yer ayýr
  PingPaket := GetMem(4096);

  // icmp v6 veri içeriðini hazýrla
  PingPaket^.MesajTipi := AMesajTipi;
  PingPaket^.Kod := $00;
  PingPaket^.SaglamaToplami := $0000;
  PingPaket^.Tanimlayici := htons(TSayi2(1));
  PingPaket^.SiraNo := htons(TSayi2(ASiraNo));
  Tasi2(AVeri, @PingPaket^.Veri, AVeriU);

  // saðlama toplamý için ek baþlýðý hazýrla
  EKBaslik.KaynakIP := OnDegerIPV6Adresi;
  EKBaslik.HedefIP := AHedefIPAdres;
  EKBaslik.Uzunluk := htons(TSayi4(40));
  EKBaslik.Sifir[0] := 0;
  EKBaslik.Sifir[1] := 0;
  EKBaslik.Sifir[2] := 0;
  EKBaslik.Protokol := PROTOKOL_ICMP6;

  // saðlama toplamý hesaplama
  PingPaket^.SaglamaToplami := 0;
  SaglamaToplami := SaglamaToplamiOlustur(PingPaket, 8 + 32, @EKBaslik, ICMP6_EKBASLIK_UZUNLUGU);
  PingPaket^.SaglamaToplami := SaglamaToplami;

  // paketi ip katmanýna gönder
  IP6PaketGonder(AHedefMACAdres, OnDegerIPV6Adresi, AHedefIPAdres, ptICMP6, $80,
    PingPaket, 8 + 32);

  // ayrýlan belleði serbest býrak
  FreeMem(PingPaket, 4096);
end;

{==============================================================================
  icmp v6 istek / yanýt verilerini paketleyerek ip katmanýna gönderir
 ==============================================================================}
procedure ICMPIstegiGonder(AMesajTipi: TSayi4; AHedefIPAdres: TIP6Adres;
  AHedefMACAdres: TMACAdres; ASorguYanitAdres: TIP6Adres);
var
  ICMPPaket: PICMP6Paket;
  EKBaslik: TEkBaslik;
  SaglamaToplami: TSayi2;
begin

  // protokol verisi için bellekte yer ayýr
  ICMPPaket := GetMem(4096);

  // icmp v6 veri içeriðini hazýrla
  ICMPPaket^.MesajTipi := AMesajTipi;
  ICMPPaket^.Kod := $00;
  ICMPPaket^.SaglamaToplami := $0000;

  if(AMesajTipi = ICMP6_KOMSU_ISTEK) then
    ICMPPaket^.Bayraklar := $00000000
  else ICMPPaket^.Bayraklar := $00000060;

  ICMPPaket^.HedefAdres := ASorguYanitAdres;

  if(AMesajTipi = ICMP6_KOMSU_ISTEK) then
    ICMPPaket^.Secenekler.Tip := 1
  else ICMPPaket^.Secenekler.Tip := 2;
  ICMPPaket^.Secenekler.Uzunluk := 1;
  ICMPPaket^.Secenekler.Adres := GAgBilgisi.MACAdres;

  // saðlama toplamý için ek baþlýðý hazýrla
  EKBaslik.KaynakIP := OnDegerIPV6Adresi;
  EKBaslik.HedefIP := AHedefIPAdres;
  EKBaslik.Uzunluk := htons(TSayi4(SizeOf(TICMP6Paket)));
  EKBaslik.Sifir[0] := 0;
  EKBaslik.Sifir[1] := 0;
  EKBaslik.Sifir[2] := 0;
  EKBaslik.Protokol := PROTOKOL_ICMP6;

  // saðlama toplamý hesaplama
  ICMPPaket^.SaglamaToplami := 0;
  SaglamaToplami := SaglamaToplamiOlustur(ICMPPaket, ICMP6_BASLIK_UZUNLUGU,
    @EKBaslik, ICMP6_EKBASLIK_UZUNLUGU);
  ICMPPaket^.SaglamaToplami := SaglamaToplami;

  // paketi ip katmanýna gönder
  IP6PaketGonder(AHedefMACAdres, OnDegerIPV6Adresi, AHedefIPAdres, ptICMP6, $FF,
    ICMPPaket, ICMP6_BASLIK_UZUNLUGU);

  // ayrýlan belleði serbest býrak
  FreeMem(ICMPPaket, 4096);
end;

// icmp protokolü üzerinden gelen paketleri iþler
procedure ICMPPaketleriniIsle(AEthernetPaket: PEthernetPaket);
var
  IPPaket: PIP6Paket;
  ICMPPaket: PICMP6Paket;
  PingPaket: PPingPaket;
  i: TSayi4;
begin

  IPPaket := @AEthernetPaket^.Veri;
  ICMPPaket := PICMP6Paket(@IPPaket^.Veri);
  PingPaket := PPingPaket(@IPPaket^.Veri);

  // bana gelen pimg isteðine yanýt veriliyor
  if(ICMPPaket^.MesajTipi = ICMP6_PING_ISTEK) then
  begin

    i := ntohs(TSayi2(PingPaket^.SiraNo));
    PingMesajiGonder(ICMP6_PING_YANIT, IPPaket^.KaynakIP, AEthernetPaket^.KaynakMACAdres,
      i, @PingPaket^.Veri, 32);
  end
  // benim gönderdiðim pimg isteðime yanýt veriliyor
  else if(ICMPPaket^.MesajTipi = ICMP6_PING_YANIT) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'ICMPv6 ping yanýtý geldi.', []);
  end
  // icmp komþu isteðine yanýt veriliyor
  else if(ICMPPaket^.MesajTipi = ICMP6_KOMSU_ISTEK) then
  begin

    ICMPIstegiGonder(ICMP6_KOMSU_ILAN, IPPaket^.KaynakIP, ICMPPaket^.Secenekler.Adres,
      OnDegerIPV6Adresi);
  end
  // komþu bilgisayar benim isteðime icmp yanýtý veriyor
  else if(ICMPPaket^.MesajTipi = ICMP6_KOMSU_ILAN) then
  begin

    { TODO - buraya gelen ip / mac adres vb. veriler ilgili tablolara iþlenecek }
    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'IP6 Komþu Ýlaný.................:', []);
    SISTEM_MESAJ_IP6(mtBilgi, RENK_MAVI, 'IP6 Adres: ', ICMPPaket^.HedefAdres);
    SISTEM_MESAJ_MAC(mtBilgi, RENK_MAVI, 'MAC Adres: ', ICMPPaket^.Secenekler.Adres);
  end
  else SISTEM_MESAJ(mtUyari, RENK_SIYAH, 'ICMP6.PAS: bilinmeyen mesaj tipi: $%.2x',
    [ICMPPaket^.MesajTipi]);
end;

end.
