{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: udp.pas
  Dosya Ýþlevi: udp protokol yönetim iþlevlerini içerir

  Güncelleme Tarihi: 06/11/2026

 ==============================================================================}
{$mode objfpc}
//{$DEFINE UDP_BILGI}
unit udp;

interface

uses paylasim, ip6, ip4;

const
  USTSINIR_UDPBAGLANTI_SAYISI = 128;

const
  UDP_BASLIK_U    = 8;
  UDP4_EKBASLIK_U = 12;
  UDP6_EKBASLIK_U = 40;

type
  PUDPPaket = ^TUDPPaket;
  TUDPPaket = packed record
    YerelPort,
    UzakPort,
    Uzunluk,                  // UDP baþlýk + veri uzunluðu
    SaglamaToplami: TSayi2;
    Veri: Isaretci;
  end;

type
  TUDP = class
  public
    FBaglanti: TObject;
    FIP6: TIP6;
    FIP4: TIP4;
    FIletisimTipi: TIletisimTipi;
    constructor Create(ABaglanti: TObject; AIletisimTipi: TIletisimTipi;
      AHedefMACAdres: TMACAdres);
    procedure PaketleVeGonder(AVeri: Isaretci; AVeriUzunlugu: TISayi4);
    procedure BaslikBilgileriniGoruntule(AUDPBaslik: PUDPPaket);
  end;

procedure UDPVerileriniIsle(AEthernetPaket: PEthernetPaket);

implementation

uses donusum, sistemmesaj, netbios, islevler, dhcpv6s, baglantilar;

{==============================================================================
  udp tutanaðý katmanýna gelen verileri iþler
 ==============================================================================}
procedure UDPVerileriniIsle(AEthernetPaket: PEthernetPaket);
var
  B: TBaglanti;
  IP6Paket: PIP6Paket;
  IP4Paket: PIP4Paket;
  UDPPaket: PUDPPaket;
  YerelPort, UzakPort,
  PaketTipi, U: TSayi2;
begin

  IP6Paket := PIP6Paket(@AEthernetPaket^.Veri);
  IP4Paket := PIP4Paket(@AEthernetPaket^.Veri);

  PaketTipi := htons(AEthernetPaket^.PaketTipi);
  if(PaketTipi = TUTANAK_IP6) then
    UDPPaket := PUDPPaket(@IP6Paket^.Veri)
  else UDPPaket := PUDPPaket(@IP4Paket^.Veri);

  {$IFDEF UDP_BILGI}
  BaslikBilgileriniGoruntule(UDPPaket);
  {$ENDIF}

  YerelPort := ntohs(UDPPaket^.YerelPort);
  UzakPort := ntohs(UDPPaket^.UzakPort);

  //SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Y2: %d', [YerelPort]);
  //SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'U2: %d', [UzakPort]);

  U := ntohs(UDPPaket^.Uzunluk) - 8;

  B := TBaglanti(GAgBaglantilari.AB.BaglantiBul(ttUDP, YerelPort, UzakPort));
  if not(B = nil) then
  begin

    case B.FBaglantiNesnesi of
      bnDHCPv6s : B.FDHCPv6s.OVeriGeldi(AEthernetPaket);
      bnDHCPv4s : B.FDHCPv4s.OVeriGeldi(AEthernetPaket);
      bnDHCPv4i : B.FDHCPv4i.OVeriGeldi(AEthernetPaket);
      bnDNSi    : B.FDNSi.OVeriGeldi(AEthernetPaket);
      bnNetBios : B.FNetBios.OVeriGeldi(AEthernetPaket);
      bnUDP     : begin if(U > 0) then B.BellegeEkle(@UDPPaket^.Veri, U); end;
      else SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Bilinmeyen baðlantý nesnesi: %d', [Ord(B.FBaglantiNesnesi)]);
    end;
  end
  else
  begin

    SISTEM_MESAJ(mtUyari, RENK_PEMBE, 'UDP.PAS: eþleþen UDP portu bulunamadý!', []);

    if(PaketTipi = TUTANAK_IP6) then
    begin

      SISTEM_MESAJ_IP6(mtUyari, RENK_TURKUAZ, '  - Kaynak IP6: ', IP6Paket^.KaynakIPAdres);
      SISTEM_MESAJ_IP6(mtUyari, RENK_TURKUAZ, '  - Hedef IP6: ', IP6Paket^.HedefIPAdres);
    end
    else
    begin

      SISTEM_MESAJ_IP4(mtUyari, RENK_TURKUAZ, '  - Kaynak IP4: ', IP4Paket^.KaynakIPAdres);
      SISTEM_MESAJ_IP4(mtUyari, RENK_TURKUAZ, '  - Hedef IP4: ', IP4Paket^.HedefIPAdres);
    end;

    SISTEM_MESAJ(mtUyari, RENK_TURKUAZ, '  - Kaynak Port: %d', [YerelPort]);
    SISTEM_MESAJ(mtUyari, RENK_TURKUAZ, '  - Hedef Port: %d', [UzakPort]);
  end;
end;

{==============================================================================
  udp tutanak (protokol) ana yükleme iþlevlerini içerir
 ==============================================================================}
constructor TUDP.Create(ABaglanti: TObject; AIletisimTipi: TIletisimTipi;
  AHedefMACAdres: TMACAdres);
begin

  FBaglanti := ABaglanti;

  FIletisimTipi := AIletisimTipi;

  if(AIletisimTipi = itIP6) then
    FIP6 := TIP6.Create(ABaglanti, AHedefMACAdres)
  else if(AIletisimTipi = itIP4) then
    FIP4 := TIP4.Create(ABaglanti, AHedefMACAdres);
end;

{==============================================================================
  udp paket hazýrlama ve gönderme iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure TUDP.PaketleVeGonder(AVeri: Isaretci; AVeriUzunlugu: TISayi4);
var
  UDPPaket: PUDPPaket;
  Ek6Baslik: TEk6Baslik;
  Ek4Baslik: TEk4Baslik;
  SaglamaToplami: TSayi2;
  B1: PSayi1;
begin

  UDPPaket := GetMem(AVeriUzunlugu + UDP_BASLIK_U);

  // baþlýk verisi için ek baþlýk saðlama deðeri hesaplanýyor
  if(FIletisimTipi = itIP6) then
  begin

    // udp v6 için ek baþlýk hesaplanýyor
    Ek6Baslik.KaynakIP6 := FIP6.FKaynakIPAdres;
    Ek6Baslik.HedefIP6 := FIP6.FHedefIPAdres;
    Ek6Baslik.Sifir[0] := 0;
    Ek6Baslik.Sifir[1] := 0;
    Ek6Baslik.Sifir[2] := 0;
    Ek6Baslik.Protokol := TUTANAK_UDP;
    Ek6Baslik.Uzunluk := htons(TSayi4(AVeriUzunlugu + UDP_BASLIK_U));
  end
  else
  begin

    // udp v4 için ek baþlýk hesaplanýyor
    Ek4Baslik.KaynakIP4Adres := FIP4.FKaynakIPAdres;
    Ek4Baslik.HedefIP4Adres := FIP4.FHedefIPAdres;
    Ek4Baslik.Sifir := 0;
    Ek4Baslik.Protokol := TUTANAK_UDP;
    Ek4Baslik.Uzunluk := ntohs(TSayi2(AVeriUzunlugu + UDP_BASLIK_U));
  end;

  // udp paketi hazýrlanýyor
  UDPPaket^.YerelPort := htons(TBaglanti(FBaglanti).FYerelPort);
  UDPPaket^.UzakPort := htons(TBaglanti(FBaglanti).FUzakPort);
  UDPPaket^.Uzunluk := htons(TSayi2(AVeriUzunlugu + UDP_BASLIK_U));
  UDPPaket^.SaglamaToplami := 0;
  B1 := @UDPPaket^.Veri;
  Tasi2(PSayi1(AVeri), B1, AVeriUzunlugu);

  if(FIletisimTipi = itIP6) then
    SaglamaToplami := SaglamaToplamiOlustur(UDPPaket, AVeriUzunlugu + UDP_BASLIK_U,
      @Ek6Baslik, UDP6_EKBASLIK_U)
  else
    SaglamaToplami := SaglamaToplamiOlustur(UDPPaket, AVeriUzunlugu + UDP_BASLIK_U,
      @Ek4Baslik, UDP4_EKBASLIK_U);

  UDPPaket^.SaglamaToplami := SaglamaToplami;

  // hazýrlanan paketi ip katmanýna gönder
  if(FIletisimTipi = itIP6) then

    FIP6.PaketleVeGonder(ttUDP, $80, UDPPaket, UDP_BASLIK_U + AVeriUzunlugu)

  else FIP4.PaketleVeGonder(ttUDP, 0, UDPPaket, UDP_BASLIK_U + AVeriUzunlugu);

  FreeMem(UDPPaket, AVeriUzunlugu + UDP_BASLIK_U);
end;

{==============================================================================
  udp baþlýk verilerini görüntüler
 ==============================================================================}
procedure TUDP.BaslikBilgileriniGoruntule(AUDPBaslik: PUDPPaket);
begin

  SISTEM_MESAJ(mtBilgi, RENK_PEMBE, 'UDP Baþlýk Bilgileri.............:', []);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - Yerel Port: %d', [ntohs(AUDPBaslik^.YerelPort)]);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - Uzak Port: %d', [ntohs(AUDPBaslik^.UzakPort)]);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - Veri Uzunluðu: %d', [ntohs(AUDPBaslik^.Uzunluk)]);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - Saðlama Toplamý: %x', [ntohs(AUDPBaslik^.SaglamaToplami)]);
  //SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'UDP Veri: ' + s, []);
end;

end.
