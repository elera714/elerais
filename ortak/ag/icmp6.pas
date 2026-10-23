{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: icmp6.pas
  Dosya Ýþlevi: ICMP v6 tutanak (protokol) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 23/10/2026

 ==============================================================================}
{$mode objfpc}
//{$DEFINE ICMP6_HATAAYIKLA}
unit icmp6;

interface

uses paylasim;

const
  ICMP6_BASLIK_UZUNLUGU   = 32;
  ICMP6_EKBASLIK_UZUNLUGU = 40;

const
  // ff02::1:ffxx:xxxx
  TalepDugumIP6Adresi: TIP6Adres = ($FF,$02, $00,$00, $00,$00, $00,$00,
    $00,$00, $00,$01, $FF,$00, $00,$00);

const
  // çoklu yayýn için kullanýlacak mac adres
  COKLUYAYIN_MACADRES: TMACAdres = ($33, $33, $00, $00, $00, $00);

const
  ICMP6_PING_ISTEK          = 128;      // $80 - ping istek mesajý
  ICMP6_PING_YANIT          = 129;      // $81 - ping yanýt mesajý
  ICMP6_YONLENDIRICI_ISTEK  = 133;      // $85 (RS) - istemcinin yönlendirici isteði
  ICMP6_YONLENDIRICI_ILAN   = 134;      // $86 (RA) - yönlendirinin kendisini ilaný
  ICMP6_KOMSU_ISTEK         = 135;      // $87 (NS) - komþudan istekte bulunma
  ICMP6_KOMSU_ILAN          = 136;      // $88 (NA) - komþunun ICMP6_KOMSU_ISTEK'ine cevabý

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
    HedefIP6Adres: TIP6Adres;
    Secenekler: TICMP6Secenekler;
  end;

type
  PPingPaket = ^TPingPaket;
  TPingPaket = packed record
    MesajTipi,
    Kod: TSayi1;
    SaglamaToplami,
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
    KaynakIP6: TIP6Adres;
    HedefIP6: TIP6Adres;
    Uzunluk: TSayi4;                // icmp v6 paket ve içeriði
    Sifir: array[0..2] of TSayi1;
    Protokol: TSayi1;               // PROTOKOL_ICMP6 deðeri ($3A)
  end;

type
  TICMP6 = class
  private
    FBaglanti: TObject;
    FICMP6GelenPaketSayisi: TSayi4;
  public
    constructor Create(ABaglanti: TObject);
    procedure KomsuIstegiGonder(AIP6Adres: TIP6Adres);
    procedure PingMesajiGonder(AMesajTipi: TSayi4; AHedefIP6Adres: TIP6Adres;
      AHedefMACAdres: TMACAdres; ASiraNo: TSayi4; AVeri: Isaretci; AVeriU: TSayi4);
    procedure PaketleVeGonder(AMesajTipi: TSayi4; AHedefIP6Adres: TIP6Adres;
      AHedefMACAdres: TMACAdres; ASorguYanitIP6Adres: TIP6Adres);
    procedure VerileriIsle(AEthernetPaket: PEthernetPaket);
  end;

implementation

uses ip6, sistemmesaj, donusum, islevler, ethernet, aygityonetimi, ag, baglantilar;

constructor TICMP6.Create(ABaglanti: TObject);
begin

  FBaglanti := ABaglanti;

  FICMP6GelenPaketSayisi := 0;
end;

// icmp protokolü üzerinden gelen paketleri iþler
procedure TICMP6.VerileriIsle(AEthernetPaket: PEthernetPaket);
const
  PingHedefIP6Adres: TIP6Adres = (
    $FF, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01);
var
  B: TBaglanti;
  IP6Paket: PIP6Paket;
  ICMPPaket: PICMP6Paket;
  PingPaket: PPingPaket;
  i: TSayi4;
begin

  IP6Paket := @AEthernetPaket^.Veri;
  ICMPPaket := PICMP6Paket(@IP6Paket^.Veri);
  PingPaket := PPingPaket(@IP6Paket^.Veri);

  B := TBaglanti(FBaglanti);

  // ip6 katman bilgileri
  B.FIP6.FKaynakIPAdres := IP6Paket^.KaynakIP;
  B.FIP6.FHedefIPAdres := IP6Paket^.HedefIP;

  // icmp yönlendirici talebine yanýt veriliyor
  if(ICMPPaket^.MesajTipi = ICMP6_YONLENDIRICI_ISTEK) then
  begin

    // yönlendirici talebi - router solicitation
    if(MACKarsilastir(AEthernetPaket^.HedefMACAdres, MAC333300000002)) then
    begin

      B.FIP6.FKaynakIPAdres := IP6AdresFF02_0001;

      PaketleVeGonder(ICMP6_YONLENDIRICI_ILAN, PingHedefIP6Adres,
        MAC333300000001, IP6AdresFF02_0001);
    end
  end
  // icmp komþu isteðine yanýt veriliyor
  else if(ICMPPaket^.MesajTipi = ICMP6_KOMSU_ISTEK) then
  begin

    // mesaj, yayýn adresine mi gönderildi? (neighbor solicitation)
    if(IP6Karsilastir(IP6Paket^.HedefIP, YayinIP6Adres)) then
    begin

      PaketleVeGonder(ICMP6_KOMSU_ILAN, IP6Paket^.KaynakIP,
        PKomsuPaket(@ICMPPaket^.Veri)^.Secenekler.Adres, GAgBaglantilari.AB.IP6Adresim);
    end
  end
  // bana gelen pimg isteðine yanýt veriliyor
  else if(ICMPPaket^.MesajTipi = ICMP6_PING_ISTEK) then
  begin

    i := ntohs(TSayi2(PingPaket^.SiraNo));
    PingMesajiGonder(ICMP6_PING_YANIT, IP6Paket^.KaynakIP,
      AEthernetPaket^.KaynakMACAdres, i, @PingPaket^.Veri, 32);
  end
  // benim gönderdiðim pimg isteðime yanýt veriliyor
  else if(ICMPPaket^.MesajTipi = ICMP6_PING_YANIT) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'ICMPv6 ping yanýtý geldi.', []);
  end
  // komþu bilgisayar benim isteðime icmp yanýtý veriyor
  else if(ICMPPaket^.MesajTipi = ICMP6_KOMSU_ILAN) then
  begin

    { TODO - buraya gelen ip / mac adres vb. veriler ilgili tablolara iþlenecek }
    SISTEM_MESAJ(mtBilgi, RENK_MOR, 'IP6 Komþu Ýlaný.................:', []);
    SISTEM_MESAJ_IP6(mtBilgi, RENK_MAVI, ' -> IP6 Adres: ', PKomsuPaket(@ICMPPaket^.Veri)^.HedefIP6Adres);
    SISTEM_MESAJ_MAC(mtBilgi, RENK_MAVI, ' -> MAC Adres: ', PKomsuPaket(@ICMPPaket^.Veri)^.Secenekler.Adres);
  end
  else SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'ICMP6.PAS: bilinmeyen mesaj tipi: $%.2x',
    [ICMPPaket^.MesajTipi]);
end;

{==============================================================================
  belirtilen ip v6 adresine komþu isteði gönderir
 ==============================================================================}
procedure TICMP6.KomsuIstegiGonder(AIP6Adres: TIP6Adres);
var
  HedefIP6Adres: TIP6Adres;
  HedefMACAdres: TMACAdres;
begin

  // ip katmaný - ip adresini hazýrla
  HedefIP6Adres := TalepDugumIP6Adresi;
  HedefIP6Adres[13] := AIP6Adres[13];
  HedefIP6Adres[14] := AIP6Adres[14];
  HedefIP6Adres[15] := AIP6Adres[15];

  // ethernet katmaný - mac adresini hazýrla
  HedefMACAdres := COKLUYAYIN_MACADRES;
  HedefMACAdres[2] := HedefIP6Adres[12];
  HedefMACAdres[3] := HedefIP6Adres[13];
  HedefMACAdres[4] := HedefIP6Adres[14];
  HedefMACAdres[5] := HedefIP6Adres[15];

  // ip6 katman bilgileri
  TBaglanti(FBaglanti).FIP6.FKaynakIPAdres := HedefIP6Adres;
  TBaglanti(FBaglanti).FIP6.FHedefIPAdres := GAgBaglantilari.AB.IP6Adresim;

  PaketleVeGonder(ICMP6_KOMSU_ISTEK, HedefIP6Adres, HedefMACAdres, AIP6Adres);
end;

{==============================================================================
  ping mesajý (istek / yanýt) gönderir
 ==============================================================================}
procedure TICMP6.PingMesajiGonder(AMesajTipi: TSayi4; AHedefIP6Adres: TIP6Adres;
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
  EKBaslik.KaynakIP6 := GAgBaglantilari.AB.IP6Adresim;
  EKBaslik.HedefIP6 := AHedefIP6Adres;
  EKBaslik.Uzunluk := htons(TSayi4(40));
  EKBaslik.Sifir[0] := 0;
  EKBaslik.Sifir[1] := 0;
  EKBaslik.Sifir[2] := 0;
  EKBaslik.Protokol := PROTOKOL_ICMP6;

  // saðlama toplamý hesaplama
  PingPaket^.SaglamaToplami := 0;
  SaglamaToplami := SaglamaToplamiOlustur(PingPaket, 8 + 32, @EKBaslik, ICMP6_EKBASLIK_UZUNLUGU);
  PingPaket^.SaglamaToplami := SaglamaToplami;

  // verinin gönderileceði ethernet adresi
  TBaglanti(FBaglanti).FIP6.FHedefMACAdres := AHedefMACAdres;

  // paketi ip katmanýna gönder
  TBaglanti(FBaglanti).FIP6.PaketleVeGonder(ptICMP6, $80, PingPaket, 8 + 32);

  // ayrýlan belleði serbest býrak
  FreeMem(PingPaket, 4096);
end;

{==============================================================================
  icmp v6 mesajlarýný paketleyerek ip katmanýna gönderir
 ==============================================================================}
procedure TICMP6.PaketleVeGonder(AMesajTipi: TSayi4; AHedefIP6Adres: TIP6Adres;
  AHedefMACAdres: TMACAdres; ASorguYanitIP6Adres: TIP6Adres);
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
    Secenekler^.Adres := GAygitlar.AktifEthernet.MACAdresim;

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

    KomsuPaket^.HedefIP6Adres := ASorguYanitIP6Adres;

    if(AMesajTipi = ICMP6_KOMSU_ISTEK) then
      KomsuPaket^.Secenekler.Tip := 1
    else KomsuPaket^.Secenekler.Tip := 2;
    KomsuPaket^.Secenekler.Uzunluk := 1;
    KomsuPaket^.Secenekler.Adres := GAygitlar.AktifEthernet.MACAdresim;

    PaketU := ICMP6_BASLIK_UZUNLUGU;
  end;

  // saðlama toplamý için ek baþlýðý hazýrla
  EKBaslik.KaynakIP6 := GAgBaglantilari.AB.IP6Adresim;
  EKBaslik.HedefIP6 := AHedefIP6Adres;
  EKBaslik.Uzunluk := htons(TSayi4(PaketU));
  EKBaslik.Sifir[0] := 0;
  EKBaslik.Sifir[1] := 0;
  EKBaslik.Sifir[2] := 0;
  EKBaslik.Protokol := PROTOKOL_ICMP6;

  // saðlama toplamý hesaplama
  ICMPPaket^.SaglamaToplami := 0;
  SaglamaToplami := SaglamaToplamiOlustur(ICMPPaket, TSayi2(PaketU),
    @EKBaslik, TSayi2(ICMP6_EKBASLIK_UZUNLUGU));
  ICMPPaket^.SaglamaToplami := SaglamaToplami;

  TBaglanti(FBaglanti).FIP6.FHedefMACAdres := AHedefMACAdres;

  // paketi ip katmanýna gönder
  TBaglanti(FBaglanti).FIP6.PaketleVeGonder(ptICMP6, $FF, ICMPPaket, PaketU);

  // ayrýlan belleði serbest býrak
  FreeMem(ICMPPaket, 4096);
end;

end.
