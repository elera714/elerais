{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: icmp4.pas
  Dosya Ýþlevi: ICMP v4 tutanak (protokol) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 17/09/2026

 ==============================================================================}
{$mode objfpc}
//{$DEFINE ICMP4_HATAAYIKLA}
unit icmp4;

interface

uses paylasim, ethernet, ip4;

const
  ICMP4_BASLIK_UZUNLUGU = 8;
  ICMP4_YANKI_ISTEK     = 8;
  ICMP4_YANKI_YANIT     = 0;

type
  PICMP4Paket = ^TICMP4Paket;
  TICMP4Paket = packed record
    MesajTipi,
    Kod: TSayi1;
    SaglamaToplami,
    Tanimlayici,
    DiziSiraNo: TSayi2;
    Veri: Isaretci;
  end;

type
  TICMP4 = class
  private
    FBaglanti: TObject;
    FICMP4GelenPaketSayisi: TSayi4;
  public
    constructor Create(ABaglanti: TObject);
    procedure PaketleVeGonder(AICMPPaket: PICMP4Paket; APaketUzunlugu: TSayi4);
    procedure VerileriIsle(AEthernetPaket: PEthernetPaket);
    property ICMP4GelenPaketSayisi: TSayi4 read FICMP4GelenPaketSayisi write FICMP4GelenPaketSayisi;
  end;

implementation

uses islevler, sistemmesaj, donusum, baglantilar;

{==============================================================================
  icmp v4 tutanak (protokol) ana yükleme iþlevlerini içerir
 ==============================================================================}
constructor TICMP4.Create(ABaglanti: TObject);
begin

  FBaglanti := ABaglanti;

  FICMP4GelenPaketSayisi := 0;
end;

{==============================================================================
  icmp v4 tutanaðý üzerinden gelen paketleri iþler
 ==============================================================================}
procedure TICMP4.VerileriIsle(AEthernetPaket: PEthernetPaket);
var
  B: TBaglanti;
  IP4Paket: PIP4Paket;
  ICMP4Paket: PICMP4Paket;
  U: TSayi4;
begin

  IP4Paket := PIP4Paket(@AEthernetPaket^.Veri);
  ICMP4Paket := PICMP4Paket(@IP4Paket^.Veri);

  U := ntohs(IP4Paket^.ToplamUzunluk) - IP4_BASLIK_U;

  {$IFDEF ICMP4_HATAAYIKLA}
  SISTEM_MESAJ(mtBilgi, RENK_PEMBE, 'ICMP4 Baþlýk Bilgileri:', []);
  SISTEM_MESAJ_IP4(mtBilgi, RENK_LACIVERT, ' -> Kaynak IP: ', IP4Paket^.KaynakIP4Adres);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, ' -> Veri Uzunluðu: %d', [U]);
  {$ENDIF}

  // istek (request) mesajýna yanýt
  if(ICMP4Paket^.MesajTipi = ICMP4_YANKI_ISTEK) then
  begin

    B := TBaglanti(FBaglanti);

    // ip4 katman bilgileri
    B.FIP4.FKaynakIPAdres := IP4Paket^.KaynakIPAdres;
    B.FIP4.FHedefIPAdres := IP4Paket^.HedefIPAdres;

    // ethernet katman bilgileri
    B.FEthernet.FHedefMACAdres := AEthernetPaket^.KaynakMACAdres;

    // yanýt gönder
    PaketleVeGonder(ICMP4Paket, U);

    Inc(FICMP4GelenPaketSayisi);

  end else SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'ICMP4.PAS: bilinmeyen mesaj tipi: $%.2x',
    [ICMP4Paket^.MesajTipi]);
end;

{==============================================================================
  icmp v4 tutanak paketi hazýrlayýp gönderme iþlevini gerçekleþtirir
 ==============================================================================}
procedure TICMP4.PaketleVeGonder(AICMPPaket: PICMP4Paket; APaketUzunlugu: TSayi4);
var
  ICMP4Paket: PICMP4Paket;
  s: array[0..128] of TSayi1;
  p: PSayi1;
  i: TSayi4;
  SaglamaToplami: TSayi2;
begin

  // paketin veri kýsmýný kopyala
  i := APaketUzunlugu - ICMP4_BASLIK_UZUNLUGU;
  Tasi2(@AICMPPaket^.Veri, @s[0], i);

  // gönderilecek paket için bellek bölgesi oluþtur
  ICMP4Paket := GetMem(4096);

  // paket hazýrlama iþlemi
  ICMP4Paket^.MesajTipi := ICMP4_YANKI_YANIT;
  ICMP4Paket^.Kod := 0;
  ICMP4Paket^.Tanimlayici := AICMPPaket^.Tanimlayici;
  ICMP4Paket^.DiziSiraNo := AICMPPaket^.DiziSiraNo;
  p := @ICMP4Paket^.Veri;
  Tasi2(@s[0], p, i);

  // saðlama toplamý  oluþturma iþlemi
  ICMP4Paket^.SaglamaToplami := 0;
  SaglamaToplami := SaglamaToplamiOlustur(ICMP4Paket, ICMP4_BASLIK_UZUNLUGU + i, nil, 0);
  ICMP4Paket^.SaglamaToplami := SaglamaToplami;

  // sisteme gelen icmp isteðine icmp yanýtý (paket) gönder
  TBaglanti(FBaglanti).FIP4.PaketleVeGonder(ptICMP4, 0, ICMP4Paket, APaketUzunlugu);

  // belleði yok et
  FreeMem(ICMP4Paket, 4096);
end;

end.
