{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: udp.pas
  Dosya Ýþlevi: udp protokol yönetim iþlevlerini içerir

  Güncelleme Tarihi: 31/12/2024

 ==============================================================================}
{$mode objfpc}
//{$DEFINE UDP_BILGI}
unit udp;

interface

uses paylasim;

const
  UDP_BASLIK_U    = 8;
  UDP_EKBASLIK_U  = 12;

type
  PUDPPaket = ^TUDPPaket;
  TUDPPaket = packed record
    KaynakPort,
    HedefPort,
    Uzunluk,                  // UDP baþlýk + veri uzunluðu
    SaglamaToplami: TSayi2;
    Veri: Isaretci;
  end;

procedure UDPPaketleriniIsle(AIPPaket: PIPPaket);
procedure UDPPaketGonder(AMACAdres: TMACAdres; AKaynakIPAdres, AHedefIPAdres: TIPAdres;
  AKaynakPort, AHedefPort: TSayi2; AVeri: Isaretci; AVeriUzunlugu: TISayi4);
procedure UDPBaslikBilgileriniGoruntule(AUDPBaslik: PUDPPaket);

implementation

uses genel, ip, donusum, sistemmesaj, dhcp, iletisim, dns, netbios;

{==============================================================================
  udp protokolüne gelen verileri ilgili kaynaklara yönlendirir
 ==============================================================================}
procedure UDPPaketleriniIsle(AIPPaket: PIPPaket);
var
  Baglanti: PBaglanti;
  UDPPaket: PUDPPaket;
  KaynakPort, HedefPort: TSayi2;
  U2: TSayi2;
begin

  UDPPaket := PUDPPaket(@AIPPaket^.Veri);

  {$IFDEF UDP_BILGI}
  //UDPBaslikBilgileriniGoruntule(AUDPBaslik);
  {$ENDIF}

  KaynakPort := ntohs(UDPPaket^.KaynakPort);
  HedefPort := ntohs(UDPPaket^.HedefPort);

  // dns protokol
  if(KaynakPort = 53) then

    DNSPaketleriniIsle(UDPPaket)

  // dhcp protokol
  else if(HedefPort = 68) then

    DHCPPaketleriniIsle(@UDPPaket^.Veri)

  // netbios api
  else if(HedefPort = 137) then

    DNSSorgulariniYanitla(UDPPaket)

  else
  begin

    Baglanti := Baglanti^.UDPBaglantiAl(HedefPort);
    if(Baglanti = nil) then
    begin

      SISTEM_MESAJ(RENK_KIRMIZI, 'UDP.PAS: eþleþen UDP portu bulunamadý: %d', [HedefPort]);
      SISTEM_MESAJ_IP(RENK_MOR, '  -> Kaynak IP: ', AIPPaket^.KaynakIP);
      SISTEM_MESAJ_IP(RENK_MOR, '  -> Hedef IP: ', AIPPaket^.HedefIP);
    end
    else
    begin

      U2 := ntohs(UDPPaket^.Uzunluk);

      //SISTEM_MESAJ(RENK_MOR, 'UDP Veri Uzunluðu: %d', [U2]);

      // 8 byte = udp paket baþlýk uzunluðu
      if(U2 > 8) then Baglanti^.BellegeEkle(@UDPPaket^.Veri, U2 - 8);
    end;
  end;
end;

{==============================================================================
  udp protokolü üzerinden veri gönderir
 ==============================================================================}
procedure UDPPaketGonder(AMACAdres: TMACAdres; AKaynakIPAdres, AHedefIPAdres: TIPAdres;
  AKaynakPort, AHedefPort: TSayi2; AVeri: Isaretci; AVeriUzunlugu: TISayi4);
var
  UDPPaket: PUDPPaket;
  EkBaslik: TEkBaslik;
  SaglamaToplami: TSayi2;
  B1: PSayi1;
begin

  UDPPaket := GGercekBellek.Ayir(AVeriUzunlugu + UDP_BASLIK_U);

  // udp için ek baþlýk hesaplanýyor
  EkBaslik.KaynakIP := AKaynakIPAdres;
  EkBaslik.HedefIP := AHedefIPAdres;
  EkBaslik.Sifir := 0;
  EkBaslik.Protokol := PROTOKOL_UDP;
  EkBaslik.Uzunluk := ntohs(TSayi2(AVeriUzunlugu + UDP_BASLIK_U));

  // udp paketi hazýrlanýyor
  UDPPaket^.KaynakPort := htons(AKaynakPort);
  UDPPaket^.HedefPort := htons(AHedefPort);
  UDPPaket^.Uzunluk := htons(TSayi2(AVeriUzunlugu + UDP_BASLIK_U));
  UDPPaket^.SaglamaToplami := 0;
  B1 := @UDPPaket^.Veri;
  Tasi2(PSayi1(AVeri), B1, AVeriUzunlugu);
  SaglamaToplami := SaglamaToplamiOlustur(UDPPaket, AVeriUzunlugu + UDP_BASLIK_U,
    @EkBaslik, UDP_EKBASLIK_U);
  UDPPaket^.SaglamaToplami := SaglamaToplami;

  IPPaketGonder(AMACAdres, AKaynakIPAdres, AHedefIPAdres, ptUDP, 0, UDPPaket,
    AVeriUzunlugu + UDP_BASLIK_U);

  GGercekBellek.YokEt(UDPPaket, AVeriUzunlugu + UDP_BASLIK_U);
end;

{==============================================================================
  udp baþlýk verilerini görüntüler
 ==============================================================================}
procedure UDPBaslikBilgileriniGoruntule(AUDPBaslik: PUDPPaket);
begin

  SISTEM_MESAJ(RENK_MOR, '-------------------------', []);
  SISTEM_MESAJ(RENK_LACIVERT, 'UDP Kaynak Port: %d', [ntohs(AUDPBaslik^.KaynakPort)]);
  SISTEM_MESAJ(RENK_LACIVERT, 'UDP Hedef Port: %d', [ntohs(AUDPBaslik^.HedefPort)]);
  SISTEM_MESAJ(RENK_LACIVERT, 'UDP Veri Uzunluðu: %d', [ntohs(AUDPBaslik^.Uzunluk)]);
  SISTEM_MESAJ(RENK_LACIVERT, 'UDP Saðlama Toplamý: %x', [ntohs(AUDPBaslik^.SaglamaToplami)]);
  //SISTEM_MESAJ(RENK_LACIVERT, 'UDP Veri: ' + s, []);
end;

end.
