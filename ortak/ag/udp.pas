{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: udp.pas
  Dosya Ýþlevi: udp protokol yönetim iþlevlerini içerir

  Güncelleme Tarihi: 06/06/2026

 ==============================================================================}
{$mode objfpc}
//{$DEFINE UDP_BILGI}
unit udp;

interface

uses ip4, paylasim;

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

procedure UDPPaketleriniIsle(AIPPaket: PIP4Paket);
procedure UDPPaketGonder(AMACAdres: TMACAdres; AKaynakIPAdres, AHedefIPAdres: TIP4Adres;
  AKaynakPort, AHedefPort: TSayi2; AVeri: Isaretci; AVeriUzunlugu: TISayi4);
procedure UDPBaslikBilgileriniGoruntule(AUDPBaslik: PUDPPaket);

implementation

uses dhcp_s, dhcp_i, donusum, sistemmesaj, dhcp, baglanti, dns, netbios,
  genel, islevler, gercekbellek;

{==============================================================================
  udp protokolüne gelen verileri ilgili kaynaklara yönlendirir
 ==============================================================================}
procedure UDPPaketleriniIsle(AIPPaket: PIP4Paket);
var
  B: PBaglanti;
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

    DNSSorgulariniYanitla(AIPPaket, UDPPaket)

  else
  begin

    B := Baglantilar0.UDPBaglantiAl(HedefPort);
    if(B = nil) then
    begin

      SISTEM_MESAJ(mtUyari, RENK_MAVI, 'UDP.PAS: eþleþen UDP portu bulunamadý: %d', [HedefPort]);
      SISTEM_MESAJ_IP4(mtUyari, RENK_SIYAH, '  -> Kaynak IP: ', AIPPaket^.KaynakIP);
      SISTEM_MESAJ_IP4(mtUyari, RENK_SIYAH, '  -> Hedef IP: ', AIPPaket^.HedefIP);
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
procedure UDPPaketGonder(AMACAdres: TMACAdres; AKaynakIPAdres, AHedefIPAdres: TIP4Adres;
  AKaynakPort, AHedefPort: TSayi2; AVeri: Isaretci; AVeriUzunlugu: TISayi4);
var
  UDPPaket: PUDPPaket;
  EkBaslik: TEkBaslik;
  SaglamaToplami: TSayi2;
  B1: PSayi1;
  i: TSayi4;
begin

  UDPPaket := GercekBellek0.Ayir(AVeriUzunlugu + UDP_BASLIK_U);

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

  IP4PaketGonder(AMACAdres, AKaynakIPAdres, AHedefIPAdres, ptUDP, 0, UDPPaket,
    AVeriUzunlugu + UDP_BASLIK_U);

  GercekBellek0.YokEt(UDPPaket, AVeriUzunlugu + UDP_BASLIK_U);
end;

{==============================================================================
  udp baþlýk verilerini görüntüler
 ==============================================================================}
procedure UDPBaslikBilgileriniGoruntule(AUDPBaslik: PUDPPaket);
begin

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '-------------------------', []);
  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'UDP Kaynak Port: %d', [ntohs(AUDPBaslik^.KaynakPort)]);
  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'UDP Hedef Port: %d', [ntohs(AUDPBaslik^.HedefPort)]);
  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'UDP Veri Uzunluðu: %d', [ntohs(AUDPBaslik^.Uzunluk)]);
  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'UDP Saðlama Toplamý: %x', [ntohs(AUDPBaslik^.SaglamaToplami)]);
  //SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'UDP Veri: ' + s, []);
end;

end.
