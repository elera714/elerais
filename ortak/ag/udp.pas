{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: udp.pas
  Dosya Ýþlevi: udp protokol yönetim iþlevlerini içerir

  Güncelleme Tarihi: 22/06/2026

 ==============================================================================}
{$mode objfpc}
//{$DEFINE UDP_BILGI}
unit udp;

interface

uses paylasim;

const
  UDP_BASLIK_U    = 8;
  UDP4_EKBASLIK_U = 12;
  UDP6_EKBASLIK_U = 40;

type
  PUDPPaket = ^TUDPPaket;
  TUDPPaket = packed record
    KaynakPort,
    HedefPort,
    Uzunluk,                  // UDP baþlýk + veri uzunluðu
    SaglamaToplami: TSayi2;
    Veri: Isaretci;
  end;

procedure UDPPaketleriniIsle(AEthernetPaket: PEthernetPaket);
procedure UDPPaketGonder(APaketTipi: TSayi4; AHedefMACAdres: TMACAdres; AKaynakIPAdres,
  AHedefIPAdres: Isaretci; AKaynakPort, AHedefPort: TSayi2; AVeri: Isaretci; AVeriUzunlugu: TISayi4);
procedure UDPBaslikBilgileriniGoruntule(AUDPBaslik: PUDPPaket);

implementation

uses ip4, ip6, dhcp4_s, dhcp_i, donusum, sistemmesaj, baglanti, dns, netbios, genel,
  islevler, gercekbellek, dhcp6;

{==============================================================================
  udp protokolüne gelen verileri ilgili kaynaklara yönlendirir
 ==============================================================================}
procedure UDPPaketleriniIsle(AEthernetPaket: PEthernetPaket);
var
  B: PBaglanti;
  UDPPaket: PUDPPaket;
  KaynakPort, HedefPort: TSayi2;
  U2, PaketTipi: TSayi2;
  IP6Paket: PIP6Paket;
  IP4Paket: PIP4Paket;
begin

  IP6Paket := PIP6Paket(@AEthernetPaket^.Veri);
  IP4Paket := PIP4Paket(@AEthernetPaket^.Veri);

  PaketTipi := htons(AEthernetPaket^.PaketTipi);
  if(PaketTipi = PROTOKOL_IP6) then
    UDPPaket := PUDPPaket(@IP6Paket^.Veri)
  else UDPPaket := PUDPPaket(@IP4Paket^.Veri);

  {$IFDEF UDP_BILGI}
  //UDPBaslikBilgileriniGoruntule(AUDPBaslik);
  {$ENDIF}

  KaynakPort := ntohs(UDPPaket^.KaynakPort);
  HedefPort := ntohs(UDPPaket^.HedefPort);

  // dns protokol
  if(KaynakPort = 53) then

    DNSPaketleriniIsle(UDPPaket)

  // verileri dhcp sunucu protokolüne yönlendir
//  {$IFDEF SISTEM_SUNUCU}
  else if(HedefPort = 67) then

    DHCPSunucu0.DHCPSunucuPaketleriniIsle(@UDPPaket^.Veri)
//  {$ENDIF}
  // verileri dhcp istemci protokolüne yönlendir
  else if(HedefPort = 68) then

    DHCPIstemciPaketleriniIsle(@UDPPaket^.Veri)

  // netbios api
  else if(HedefPort = 137) then

    DNSSorgulariniYanitla(IP4Paket, UDPPaket)

  // dhcp v6
  else if(HedefPort = 547) then

    DHCPv6SorgulariniYanitla(AEthernetPaket)

  else
  begin

    B := Baglantilar0.UDPBaglantiAl(HedefPort);
    if(B = nil) then
    begin

      SISTEM_MESAJ(mtUyari, RENK_PEMBE, 'UDP.PAS: eþleþen UDP portu bulunamadý!', []);

      if(PaketTipi = PROTOKOL_IP6) then
      begin

        SISTEM_MESAJ_IP6(mtUyari, RENK_TURKUAZ, '  - Kaynak IP: ', IP6Paket^.KaynakIP);
        SISTEM_MESAJ_IP6(mtUyari, RENK_TURKUAZ, '  - Hedef IP: ', IP6Paket^.HedefIP);
      end
      else
      begin

        SISTEM_MESAJ_IP4(mtUyari, RENK_TURKUAZ, '  - Kaynak IP: ', IP4Paket^.KaynakIP);
        SISTEM_MESAJ_IP4(mtUyari, RENK_TURKUAZ, '  - Hedef IP: ', IP4Paket^.HedefIP);
      end;

      SISTEM_MESAJ(mtUyari, RENK_TURKUAZ, '  - Kaynak Port: %d', [KaynakPort]);
      SISTEM_MESAJ(mtUyari, RENK_TURKUAZ, '  - Hedef Port: %d', [HedefPort]);
    end
    else
    begin

      U2 := ntohs(UDPPaket^.Uzunluk);

      //SISTEM_MESAJ(RENK_MOR, 'UDP Veri Uzunluðu: %d', [U2]);

      // 8 byte = udp paket baþlýk uzunluðu
      if(U2 > 8) then Baglantilar0.BellegeEkle(B, @UDPPaket^.Veri, U2 - 8);
    end;
  end;
end;

{==============================================================================
  udp protokolü üzerinden veri gönderir
 ==============================================================================}
procedure UDPPaketGonder(APaketTipi: TSayi4; AHedefMACAdres: TMACAdres; AKaynakIPAdres,
  AHedefIPAdres: Isaretci; AKaynakPort, AHedefPort: TSayi2; AVeri: Isaretci; AVeriUzunlugu: TISayi4);
var
  UDPPaket: PUDPPaket;
  Ek6Baslik: TEk6Baslik;
  Ek4Baslik: TEk4Baslik;
  SaglamaToplami: TSayi2;
  B1: PSayi1;
begin

  UDPPaket := GercekBellek0.Ayir(AVeriUzunlugu + UDP_BASLIK_U);

  if(APaketTipi = PROTOKOL_IP6) then
  begin

    // udp v6 için ek baþlýk hesaplanýyor
    Ek6Baslik.KaynakIP := PIP6Adres(AKaynakIPAdres)^;
    Ek6Baslik.HedefIP := PIP6Adres(AHedefIPAdres)^;
    Ek6Baslik.Sifir[0] := 0;
    Ek6Baslik.Sifir[1] := 0;
    Ek6Baslik.Sifir[2] := 0;
    Ek6Baslik.Protokol := PROTOKOL_UDP;
    Ek6Baslik.Uzunluk := htons(TSayi4(AVeriUzunlugu + UDP_BASLIK_U));
  end
  else
  begin

    // udp v4 için ek baþlýk hesaplanýyor
    Ek4Baslik.KaynakIP := PIP4Adres(AKaynakIPAdres)^;
    Ek4Baslik.HedefIP := PIP4Adres(AHedefIPAdres)^;
    Ek4Baslik.Sifir := 0;
    Ek4Baslik.Protokol := PROTOKOL_UDP;
    Ek4Baslik.Uzunluk := ntohs(TSayi2(AVeriUzunlugu + UDP_BASLIK_U));
  end;

  // udp paketi hazýrlanýyor
  UDPPaket^.KaynakPort := htons(AKaynakPort);
  UDPPaket^.HedefPort := htons(AHedefPort);
  UDPPaket^.Uzunluk := htons(TSayi2(AVeriUzunlugu + UDP_BASLIK_U));
  UDPPaket^.SaglamaToplami := 0;
  B1 := @UDPPaket^.Veri;
  Tasi2(PSayi1(AVeri), B1, AVeriUzunlugu);

  if(APaketTipi = PROTOKOL_IP6) then
    SaglamaToplami := SaglamaToplamiOlustur(UDPPaket, AVeriUzunlugu + UDP_BASLIK_U,
      @Ek6Baslik, UDP6_EKBASLIK_U)
  else
    SaglamaToplami := SaglamaToplamiOlustur(UDPPaket, AVeriUzunlugu + UDP_BASLIK_U,
      @Ek4Baslik, UDP4_EKBASLIK_U);

  UDPPaket^.SaglamaToplami := SaglamaToplami;

  if(APaketTipi = PROTOKOL_IP6) then
    IP6PaketGonder(AHedefMACAdres, PIP6Adres(AKaynakIPAdres)^, PIP6Adres(AHedefIPAdres)^,
      ptUDP, $80, UDPPaket, AVeriUzunlugu + UDP_BASLIK_U)
  else
    IP4PaketGonder(AHedefMACAdres, PIP4Adres(AKaynakIPAdres)^, PIP4Adres(AHedefIPAdres)^,
      ptUDP, 0, UDPPaket, AVeriUzunlugu + UDP_BASLIK_U);

  GercekBellek0.YokEt(UDPPaket, AVeriUzunlugu + UDP_BASLIK_U);
end;

{==============================================================================
  udp baþlýk verilerini görüntüler
 ==============================================================================}
procedure UDPBaslikBilgileriniGoruntule(AUDPBaslik: PUDPPaket);
begin

  SISTEM_MESAJ(mtBilgi, RENK_PEMBE, 'UDP Baþlýk Bilgileri.............:', []);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - Kaynak Port: %d', [ntohs(AUDPBaslik^.KaynakPort)]);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - Hedef Port: %d', [ntohs(AUDPBaslik^.HedefPort)]);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - Veri Uzunluðu: %d', [ntohs(AUDPBaslik^.Uzunluk)]);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - Saðlama Toplamý: %x', [ntohs(AUDPBaslik^.SaglamaToplami)]);
  //SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'UDP Veri: ' + s, []);
end;

end.
