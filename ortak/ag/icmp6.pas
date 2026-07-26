{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: icmp6.pas
  Dosya Ýþlevi: ICMP v6 protokol iþlevlerini yönetir

  Güncelleme Tarihi: 18/06/2026

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
  ICMP6_PING_ISTEK          = $80;      // ping istek mesajý
  ICMP6_PING_YANIT          = $81;      // ping yanýt mesajý
  ICMP6_YONLENDIRICI_ISTEK  = $85;      // 133 (RS) - istemcinin yönlendirici isteði
  ICMP6_YONLENDIRICI_ILAN   = $86;      // 134 (RA) - yönlendirinin kendisini ilaný
  ICMP6_KOMSU_ISTEK         = $87;      // 135 (NS) - komþudan istekte bulunma
  ICMP6_KOMSU_ILAN          = $88;      // 136 (NA) - komþunun ICMP6_KOMSU_ISTEK'ine cevabý

type
  PICMP6Secenekler = ^TICMP6Secenekler;
  TICMP6Secenekler = packed record
    Tip: TSayi1;
    Uzunluk: TSayi1;
    Adres: TMACAdres;
  end;

type
  PRAPaket = ^TRAPaket;
  TRAPaket = packed record
    HopSinir,
    Bayraklar: TSayi1;
    YonlendiriciYasamSuresi: TSayi2;
    UlasilabilirSure,
    YenidenCevirmeZamanlayici: TSayi4;
    Secenekler: TICMP6Secenekler;
  end;

type
  PKomsuPaket = ^TKomsuPaket;
  TKomsuPaket = packed record
    Bayraklar: TSayi4;
    HedefAdres: TIP6Adres;
    Secenekler: TICMP6Secenekler;
  end;

type
  PPingPaket = ^TPingPaket;
  TPingPaket = packed record
    Tanimlayici,
    SiraNo: TSayi2;
    Veri: Isaretci;
  end;

type
  PICMP6Paket = ^TICMP6Paket;
  TICMP6Paket = packed record
    MesajTipi,
    Kod: TSayi1;
    SaglamaToplami: TSayi2;
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
procedure ICMPMesajiGonder(AMesajTipi: TSayi4; AHedefIPAdres: TIP6Adres;
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

  ICMPMesajiGonder(ICMP6_KOMSU_ISTEK, HedefIPAdres, HedefMACAdres, AIP6Adres);
end;

{==============================================================================
  ping mesajý (istek / yanýt) gönderir
 ==============================================================================}
procedure PingMesajiGonder(AMesajTipi: TSayi4; AHedefIPAdres: TIP6Adres;
  AHedefMACAdres: TMACAdres; ASiraNo: TSayi4; AVeri: Isaretci; AVeriU: TSayi4);
var
  ICMPPaket: PICMP6Paket;
  PingPaket: PPingPaket;
  EKBaslik: TEkBaslik;
  SaglamaToplami: TSayi2;
begin

  // protokol verisi için bellekte yer ayýr
  ICMPPaket := GetMem(4096);

  // icmp v6 veri içeriðini hazýrla
  ICMPPaket^.MesajTipi := AMesajTipi;
  ICMPPaket^.Kod := $00;
  ICMPPaket^.SaglamaToplami := $0000;

  PingPaket := @ICMPPaket^.Veri;
  PingPaket^.Tanimlayici := htons(TSayi2(1));
  PingPaket^.SiraNo := htons(TSayi2(ASiraNo));
  Tasi2(AVeri, @PingPaket^.Veri, AVeriU);

  // saðlama toplamý için ek baþlýðý hazýrla
  EKBaslik.KaynakIP := GAg0.IP6Adres;
  EKBaslik.HedefIP := AHedefIPAdres;
  EKBaslik.Uzunluk := htons(TSayi4(40));
  EKBaslik.Sifir[0] := 0;
  EKBaslik.Sifir[1] := 0;
  EKBaslik.Sifir[2] := 0;
  EKBaslik.Protokol := PROTOKOL_ICMP6;

  // saðlama toplamý hesaplama
  ICMPPaket^.SaglamaToplami := 0;
  SaglamaToplami := SaglamaToplamiOlustur(ICMPPaket, 8 + 32, @EKBaslik, ICMP6_EKBASLIK_UZUNLUGU);
  ICMPPaket^.SaglamaToplami := SaglamaToplami;

  // paketi ip katmanýna gönder
  IP6PaketGonder(AHedefMACAdres, GAg0.IP6Adres, AHedefIPAdres, ptICMP6, $80,
    ICMPPaket, 8 + 32);

  // ayrýlan belleði serbest býrak
  FreeMem(ICMPPaket, 4096);
end;

{==============================================================================
  icmp v6 mesajlarýný paketleyerek ip katmanýna gönderir
 ==============================================================================}
procedure ICMPMesajiGonder(AMesajTipi: TSayi4; AHedefIPAdres: TIP6Adres;
  AHedefMACAdres: TMACAdres; ASorguYanitAdres: TIP6Adres);
var
  ICMPPaket: PICMP6Paket;
  KomsuPaket: PKomsuPaket;
  RAPaket: PRAPaket;
  Secenekler: PICMP6Secenekler;
  EKBaslik: TEkBaslik;
  SaglamaToplami: TSayi2;
  PaketU: TSayi4;
begin

  // protokol verisi için bellekte yer ayýr
  ICMPPaket := GetMem(4096);

  // icmp v6 veri içeriðini hazýrla
  ICMPPaket^.MesajTipi := AMesajTipi;
  ICMPPaket^.Kod := $00;
  ICMPPaket^.SaglamaToplami := $0000;

  if(AMesajTipi = ICMP6_YONLENDIRICI_ILAN) then
  begin

    RAPaket := @ICMPPaket^.Veri;
    RAPaket^.HopSinir := $40;
    RAPaket^.Bayraklar := $80;
    RAPaket^.YonlendiriciYasamSuresi := htons(TSayi2($708));
    RAPaket^.UlasilabilirSure := htons(TSayi4($00000000));
    RAPaket^.YenidenCevirmeZamanlayici := htons(TSayi4($00000000));

    Secenekler := @RAPaket^.Secenekler;
    Secenekler^.Tip := 1;
    Secenekler^.Uzunluk := 1;
    Secenekler^.Adres := GAg0.MACAdres;

    PaketU := 24;
  end
  else
  begin

    KomsuPaket := @ICMPPaket^.Veri;

    if(AMesajTipi = ICMP6_KOMSU_ISTEK) then
      KomsuPaket^.Bayraklar := $00000000
    else if(AMesajTipi = ICMP6_KOMSU_ILAN) then
      //KomsuPaket^.Bayraklar := $00000060;
      KomsuPaket^.Bayraklar := $000000e0;

    KomsuPaket^.HedefAdres := ASorguYanitAdres;

    if(AMesajTipi = ICMP6_KOMSU_ISTEK) then
      KomsuPaket^.Secenekler.Tip := 1
    else KomsuPaket^.Secenekler.Tip := 2;
    KomsuPaket^.Secenekler.Uzunluk := 1;
    KomsuPaket^.Secenekler.Adres := GAg0.MACAdres;

    PaketU := ICMP6_BASLIK_UZUNLUGU;
  end;

  // saðlama toplamý için ek baþlýðý hazýrla
  EKBaslik.KaynakIP := GAg0.IP6Adres;
  EKBaslik.HedefIP := AHedefIPAdres;
  EKBaslik.Uzunluk := htons(TSayi4(PaketU));
  EKBaslik.Sifir[0] := 0;
  EKBaslik.Sifir[1] := 0;
  EKBaslik.Sifir[2] := 0;
  EKBaslik.Protokol := PROTOKOL_ICMP6;

  // saðlama toplamý hesaplama
  ICMPPaket^.SaglamaToplami := 0;
  SaglamaToplami := SaglamaToplamiOlustur(ICMPPaket, PaketU,
    @EKBaslik, ICMP6_EKBASLIK_UZUNLUGU);
  ICMPPaket^.SaglamaToplami := SaglamaToplami;

  // paketi ip katmanýna gönder
  IP6PaketGonder(AHedefMACAdres, GAg0.IP6Adres, AHedefIPAdres, ptICMP6, $FF,
    ICMPPaket, PaketU);

  // ayrýlan belleði serbest býrak
  FreeMem(ICMPPaket, 4096);
end;

// icmp protokolü üzerinden gelen paketleri iþler
procedure ICMPPaketleriniIsle(AEthernetPaket: PEthernetPaket);
const
  PingHedefIP6Adres: TIP6Adres = (
    $ff, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01);
var
  IPPaket: PIP6Paket;
  ICMPPaket: PICMP6Paket;
  PingPaket: PPingPaket;
  i: TSayi4;
begin

  IPPaket := @AEthernetPaket^.Veri;
  ICMPPaket := PICMP6Paket(@IPPaket^.Veri);
  PingPaket := PPingPaket(@IPPaket^.Veri);

  if(IP6Karsilastir(IPPaket^.HedefIP, YayinIP6Adresi)) then
  begin

    ICMPMesajiGonder(ICMP6_KOMSU_ILAN, IPPaket^.KaynakIP,
      PKomsuPaket(@ICMPPaket^.Veri)^.Secenekler.Adres, GAg0.IP6Adres);

    { TODO - çalýþmýyor }
    SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Son asama3', []);
  end
  // yönlendirici talebi - router solicitation
  else if(MACKarsilastir(AEthernetPaket^.HedefMACAdres, MAC333300000002)) then
  begin

    // icmp yönlendirici talebine yanýt veriliyor
    if(ICMPPaket^.MesajTipi = ICMP6_YONLENDIRICI_ISTEK) then
    begin

      ICMPMesajiGonder(ICMP6_YONLENDIRICI_ILAN, PingHedefIP6Adres, MAC333300000001, GAg0.IP6Adres);
    end
  end
  else
  begin

    // bana gelen pimg isteðine yanýt veriliyor
    if(ICMPPaket^.MesajTipi = ICMP6_PING_ISTEK) then
    begin

      i := ntohs(TSayi2(PPingPaket(@ICMPPaket^.Veri)^.SiraNo));
      PingMesajiGonder(ICMP6_PING_YANIT, IPPaket^.KaynakIP, AEthernetPaket^.KaynakMACAdres,
        i, @ICMPPaket^.Veri, 32);
    end
    // benim gönderdiðim pimg isteðime yanýt veriliyor
    else if(ICMPPaket^.MesajTipi = ICMP6_PING_YANIT) then
    begin

      SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'ICMPv6 ping yanýtý geldi.', []);
    end
    // icmp komþu isteðine yanýt veriliyor
    else if(ICMPPaket^.MesajTipi = ICMP6_KOMSU_ISTEK) then
    begin

      ICMPMesajiGonder(ICMP6_KOMSU_ILAN, IPPaket^.KaynakIP,
        PKomsuPaket(@ICMPPaket^.Veri)^.Secenekler.Adres, GAg0.IP6Adres);
    end
    // komþu bilgisayar benim isteðime icmp yanýtý veriyor
    else if(ICMPPaket^.MesajTipi = ICMP6_KOMSU_ILAN) then
    begin

      { TODO - buraya gelen ip / mac adres vb. veriler ilgili tablolara iþlenecek }
      SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'IP6 Komþu Ýlaný.................:', []);
      SISTEM_MESAJ_IP6(mtBilgi, RENK_MAVI, 'IP6 Adres: ', PKomsuPaket(@ICMPPaket^.Veri)^.HedefAdres);
      SISTEM_MESAJ_MAC(mtBilgi, RENK_MAVI, 'MAC Adres: ', PKomsuPaket(@ICMPPaket^.Veri)^.Secenekler.Adres);
    end
    else SISTEM_MESAJ(mtUyari, RENK_SIYAH, 'ICMP6.PAS: bilinmeyen mesaj tipi: $%.2x',
      [ICMPPaket^.MesajTipi]);
  end;
end;

end.
