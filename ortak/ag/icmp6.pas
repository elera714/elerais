{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: icmp6.pas
  Dosya İşlevi: ICMP v6 protokol işlevlerini yönetir

  Güncelleme Tarihi: 16/08/2026

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
  TalepDugumIP6Adresi: TIP6Adres = ($FF,$02, $00,$00, $00,$00, $00,$00,
    $00,$00, $00,$01, $FF,$00, $00,$00);

const
  // çoklu yayın için kullanılacak mac adres
  COKLUYAYIN_MACADRES: TMACAdres = ($33, $33, $00, $00, $00, $00);

const
  ICMP6_PING_ISTEK          = $80;      // ping istek mesajı
  ICMP6_PING_YANIT          = $81;      // ping yanıt mesajı
  ICMP6_YONLENDIRICI_ISTEK  = $85;      // 133 (RS) - istemcinin yönlendirici isteği
  ICMP6_YONLENDIRICI_ILAN   = $86;      // 134 (RA) - yönlendirinin kendisini ilanı
  ICMP6_KOMSU_ISTEK         = $87;      // 135 (NS) - komşudan istekte bulunma
  ICMP6_KOMSU_ILAN          = $88;      // 136 (NA) - komşunun ICMP6_KOMSU_ISTEK'ine cevabı

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
  // TICMP6Paket yapısının hesaplanması için gerekli ek başlık
  PEkBaslik = ^TEkBaslik;
  TEkBaslik = packed record         // pseudo header
    KaynakIP6: TIP6Adres;
    HedefIP6: TIP6Adres;
    Uzunluk: TSayi4;                // icmp v6 paket ve içeriği
    Sifir: array[0..2] of TSayi1;
    Protokol: TSayi1;               // PROTOKOL_ICMP6 değeri ($3A)
  end;

type
  TICMP6 = class
  private
    FBaglanti: TObject;
  public
    constructor Create(ABaglanti: TObject);
    procedure KomsuIstegiGonder(AIP6Adres: TIP6Adres);
    procedure PingMesajiGonder(AMesajTipi: TSayi4; AHedefIP6Adres: TIP6Adres;
      AHedefMACAdres: TMACAdres; ASiraNo: TSayi4; AVeri: Isaretci; AVeriU: TSayi4);
    procedure ICMPMesajiGonder(AMesajTipi: TSayi4; AHedefIP6Adres: TIP6Adres;
      AHedefMACAdres: TMACAdres; ASorguYanitIP6Adres: TIP6Adres);
    procedure VerileriIsle(AEthernetPaket: PEthernetPaket);
  end;

var
  GICMP6: TICMP6;

implementation

uses ip6, sistemmesaj, donusum, islevler, ethernet, aygityonetimi, baglantilar;

constructor TICMP6.Create(ABaglanti: TObject);
begin

  FBaglanti := ABaglanti;
end;

{==============================================================================
  belirtilen ip v6 adresine komşu isteği gönderir
 ==============================================================================}
procedure TICMP6.KomsuIstegiGonder(AIP6Adres: TIP6Adres);
var
  HedefIP6Adres: TIP6Adres;
  HedefMACAdres: TMACAdres;
begin

  // ip katmanı - ip adresini hazırla
  HedefIP6Adres := TalepDugumIP6Adresi;
  HedefIP6Adres[13] := AIP6Adres[13];
  HedefIP6Adres[14] := AIP6Adres[14];
  HedefIP6Adres[15] := AIP6Adres[15];

  // ethernet katmanı - mac adresini hazırla
  HedefMACAdres := COKLUYAYIN_MACADRES;
  HedefMACAdres[2] := HedefIP6Adres[12];
  HedefMACAdres[3] := HedefIP6Adres[13];
  HedefMACAdres[4] := HedefIP6Adres[14];
  HedefMACAdres[5] := HedefIP6Adres[15];

  ICMPMesajiGonder(ICMP6_KOMSU_ISTEK, HedefIP6Adres, HedefMACAdres, AIP6Adres);
end;

{==============================================================================
  ping mesajı (istek / yanıt) gönderir
 ==============================================================================}
procedure TICMP6.PingMesajiGonder(AMesajTipi: TSayi4; AHedefIP6Adres: TIP6Adres;
  AHedefMACAdres: TMACAdres; ASiraNo: TSayi4; AVeri: Isaretci; AVeriU: TSayi4);
var
  IP6Paket: TIP6;
  ICMPPaket: PICMP6Paket;
  PingPaket: PPingPaket;
  EKBaslik: TEkBaslik;
  SaglamaToplami: TSayi2;
begin

  // protokol verisi için bellekte yer ayır
  ICMPPaket := GetMem(4096);

  // icmp v6 veri içeriğini hazırla
  ICMPPaket^.MesajTipi := AMesajTipi;
  ICMPPaket^.Kod := $00;
  ICMPPaket^.SaglamaToplami := $0000;

  PingPaket := @ICMPPaket^.Veri;
  PingPaket^.Tanimlayici := htons(TSayi2(1));
  PingPaket^.SiraNo := htons(TSayi2(ASiraNo));
  Tasi2(AVeri, @PingPaket^.Veri, AVeriU);

  // sağlama toplamı için ek başlığı hazırla
  EKBaslik.KaynakIP6 := GAgBaglantilari.AktifBaglanti.IP6Adres;
  EKBaslik.HedefIP6 := AHedefIP6Adres;
  EKBaslik.Uzunluk := htons(TSayi4(40));
  EKBaslik.Sifir[0] := 0;
  EKBaslik.Sifir[1] := 0;
  EKBaslik.Sifir[2] := 0;
  EKBaslik.Protokol := PROTOKOL_ICMP6;

  // sağlama toplamı hesaplama
  ICMPPaket^.SaglamaToplami := 0;
  SaglamaToplami := SaglamaToplamiOlustur(ICMPPaket, 8 + 32, @EKBaslik, ICMP6_EKBASLIK_UZUNLUGU);
  ICMPPaket^.SaglamaToplami := SaglamaToplami;

  // paketi ip katmanına gönder
  //IP6Paket := TIP6.Create;
  {IP6Paket.Ozellestir(GBaglantilar.AktifBaglanti.IP6Adres, AHedefIPAdres);
  IP6Paket.IP6PaketGonder(AHedefMACAdres, ptICMP6, $80, ICMPPaket, 8 + 32);
  IP6Paket.Destroy;}

  // ayrılan belleği serbest bırak
  FreeMem(ICMPPaket, 4096);
end;

{==============================================================================
  icmp v6 mesajlarını paketleyerek ip katmanına gönderir
 ==============================================================================}
procedure TICMP6.ICMPMesajiGonder(AMesajTipi: TSayi4; AHedefIP6Adres: TIP6Adres;
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

  // protokol verisi için bellekte yer ayır
  ICMPPaket := GetMem(4096);

  // icmp v6 veri içeriğini hazırla
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
    Secenekler^.Adres := GAygitlar.AktifEthernet.MACAdres;

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
    KomsuPaket^.Secenekler.Adres := GAygitlar.AktifEthernet.MACAdres;

    PaketU := ICMP6_BASLIK_UZUNLUGU;
  end;

  // sağlama toplamı için ek başlığı hazırla
  EKBaslik.KaynakIP6 := GAgBaglantilari.AktifBaglanti.IP6Adres;
  EKBaslik.HedefIP6 := AHedefIP6Adres;
  EKBaslik.Uzunluk := htons(TSayi4(PaketU));
  EKBaslik.Sifir[0] := 0;
  EKBaslik.Sifir[1] := 0;
  EKBaslik.Sifir[2] := 0;
  EKBaslik.Protokol := PROTOKOL_ICMP6;

  // sağlama toplamı hesaplama
  ICMPPaket^.SaglamaToplami := 0;
  SaglamaToplami := SaglamaToplamiOlustur(ICMPPaket, PaketU,
    @EKBaslik, ICMP6_EKBASLIK_UZUNLUGU);
  ICMPPaket^.SaglamaToplami := SaglamaToplami;

  // paketi ip katmanına gönder
  TBaglanti(FBaglanti).FIP6.Ozellestir(TBaglanti(FBaglanti).IP6Adres, AHedefIP6Adres);
  TBaglanti(FBaglanti).FIP6.PaketleVeGonder(AHedefMACAdres, ptICMP6, $FF, ICMPPaket, PaketU);

  // ayrılan belleği serbest bırak
  FreeMem(ICMPPaket, 4096);
end;

// icmp protokolü üzerinden gelen paketleri işler
procedure TICMP6.VerileriIsle(AEthernetPaket: PEthernetPaket);
const
  PingHedefIP6Adres: TIP6Adres = (
    $ff, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01);
var
  IPPaket: PIP6Paket;
  ICMPPaket: PICMP6Paket;
  PingPaket: PPingPaket;
  i: TSayi4;
begin
                               exit;
  IPPaket := @AEthernetPaket^.Veri;
  ICMPPaket := PICMP6Paket(@IPPaket^.Veri);
  PingPaket := PPingPaket(@IPPaket^.Veri);

  if(IP6Karsilastir(IPPaket^.HedefIP6, YayinIP6Adres)) then
  begin

    ICMPMesajiGonder(ICMP6_KOMSU_ILAN, IPPaket^.KaynakIP,
      PKomsuPaket(@ICMPPaket^.Veri)^.Secenekler.Adres, GAgBaglantilari.AktifBaglanti.IP6Adres);
  end
  // yönlendirici talebi - router solicitation
  else if(MACKarsilastir(AEthernetPaket^.HedefMACAdres, MAC333300000002)) then
  begin

    // icmp yönlendirici talebine yanıt veriliyor
    if(ICMPPaket^.MesajTipi = ICMP6_YONLENDIRICI_ISTEK) then
    begin

      ICMPMesajiGonder(ICMP6_YONLENDIRICI_ILAN, PingHedefIP6Adres,
        MAC333300000001, GAgBaglantilari.AktifBaglanti.IP6Adres);
    end
  end
  else
  begin

    // bana gelen pimg isteğine yanıt veriliyor
    if(ICMPPaket^.MesajTipi = ICMP6_PING_ISTEK) then
    begin

      i := ntohs(TSayi2(PPingPaket(@ICMPPaket^.Veri)^.SiraNo));
      PingMesajiGonder(ICMP6_PING_YANIT, IPPaket^.KaynakIP,
        AEthernetPaket^.KaynakMACAdres, i, @ICMPPaket^.Veri, 32);
    end
    // benim gönderdiğim pimg isteğime yanıt veriliyor
    else if(ICMPPaket^.MesajTipi = ICMP6_PING_YANIT) then
    begin

      SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'ICMPv6 ping yanıtı geldi.', []);
    end
    // icmp komşu isteğine yanıt veriliyor
    else if(ICMPPaket^.MesajTipi = ICMP6_KOMSU_ISTEK) then
    begin

      ICMPMesajiGonder(ICMP6_KOMSU_ILAN, IPPaket^.KaynakIP,
        PKomsuPaket(@ICMPPaket^.Veri)^.Secenekler.Adres, GAgBaglantilari.AktifBaglanti.IP6Adres);
    end
    // komşu bilgisayar benim isteğime icmp yanıtı veriyor
    else if(ICMPPaket^.MesajTipi = ICMP6_KOMSU_ILAN) then
    begin

      { TODO - buraya gelen ip / mac adres vb. veriler ilgili tablolara işlenecek }
      SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'IP6 Komşu İlanı.................:', []);
      SISTEM_MESAJ_IP6(mtBilgi, RENK_MAVI, 'IP6 Adres: ', PKomsuPaket(@ICMPPaket^.Veri)^.HedefIP6Adres);
      SISTEM_MESAJ_MAC(mtBilgi, RENK_MAVI, 'MAC Adres: ', PKomsuPaket(@ICMPPaket^.Veri)^.Secenekler.Adres);
    end
    else SISTEM_MESAJ(mtUyari, RENK_SIYAH, 'ICMP6.PAS: bilinmeyen mesaj tipi: $%.2x',
      [ICMPPaket^.MesajTipi]);
  end;
end;

end.
