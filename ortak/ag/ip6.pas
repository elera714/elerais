{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: ip6.pas
  Dosya Ýþlevi: ip v6 paket yönetim iþlevlerini içerir

  Güncelleme Tarihi: 10/06/2026

 ==============================================================================}
{$mode objfpc}
unit ip6;

interface

uses paylasim, ag, sistemmesaj;

const
  IP6_BASLIK_U = 40;

procedure IP6PaketleriniIsle(AEthernetPaket: PEthernetPaket; AIPPaketUzunluk: TISayi4);
procedure IP6PaketGonder(AHedefMACAdres: TMACAdres; AKaynakIP, AHedefIP: TIP6Adres;
  AProtokolTipi: TProtokolTipi; AHopSiniri: TSayi4; AVeri: Isaretci; AVeriUzunlugu: TSayi2);

implementation

uses donusum, icmp6, udp, tcp, islevler, genel;

var
  GIPTanimlayici: TSayi2 = $BABA;

// sisteme gelen tüm ip paketlerini iþler
procedure IP6PaketleriniIsle(AEthernetPaket: PEthernetPaket; AIPPaketUzunluk: TISayi4);
var
  IPPaket: PIP6Paket;
  i: TSayi2;
begin

  IPPaket := @AEthernetPaket^.Veri;

  i := ntohs(IPPaket^.TasinanVeriU);

  // 1. sistemin ip adresi yok ise...
  // ve udp protokolünden ip adresi talebi mevcut ise
{  if(GAgBilgisi.IPAdresiAlindi = False) then
  begin

    // udp protokolü
    if(IPPaket^.Protokol = PROTOKOL_UDP) then
    begin

      Inc(UDPPaketSayisi);
      UDPPaketleriniIsle(IPPaket);
    end;
  end
  // 2. sistemin ip adresi var ise...
  // sadece aygýta gelen ve yayýn olarak gelen ip adreslerini iþle
  else if(GAgBilgisi.IPAdresiAlindi) then
  begin

    if((IPKarsilastir(IPPaket^.HedefIP, GAgBilgisi.IP4Adres)) or
      (IPKarsilastir2(IPPaket^.HedefIP, GAgBilgisi.IP4Adres)) or
      (IPKarsilastir(IPPaket^.HedefIP, IPAdres255))) then
    begin   }

  // yönlendirici talebi - router solicitation
  if(IP6Karsilastir(IPPaket^.HedefIP, IP6AdresFF02_0002)) then
  begin

    ICMPPaketleriniIsle(AEthernetPaket);
    Inc(ICMP6PaketSayisi);
  end
  else if(IP6Karsilastir(IPPaket^.HedefIP, IP6AdresFF02_0102)) then
  begin

    UDPPaketleriniIsle(AEthernetPaket);
    Inc(UDPPaketSayisi);
  end
  else if(IP6Karsilastir(IPPaket^.HedefIP, YayinIP6Adresi)) then
  begin

    { TODO - çalýþmýyor }
    SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Son asama2', []);
    ICMPPaketleriniIsle(AEthernetPaket);
    Inc(ICMP6PaketSayisi);
  end
  else
  begin

    // icmp protokolü
    if(IPPaket^.TasinanVeriP = PROTOKOL_ICMP6) then
    begin

      ICMPPaketleriniIsle(AEthernetPaket);
      Inc(ICMP6PaketSayisi);
    end
    // tcp protokolü
    else if(IPPaket^.TasinanVeriP = PROTOKOL_TCP) then
    begin

      SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'DAT', []);
      TCPPaketleriniIsle(AEthernetPaket);
      Inc(TCP6PaketSayisi);
    end
    // udp protokolü
    else if(IPPaket^.TasinanVeriP = PROTOKOL_UDP) then
    begin

      UDPPaketleriniIsle(AEthernetPaket);
      Inc(UDPPaketSayisi);
    end
    else
    begin

      //Inc(GAEPaketSayisi);
      SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'IP6.PAS: bilinmeyen IP paketi:', []);
      //SISTEM_MESAJ_IP6(mtUyari, RENK_SIYAH, '  -> Hedef IP adresi: ', IPPaket^.HedefIP);
      SISTEM_MESAJ(mtUyari, RENK_SIYAH, '  -> Hedef protokol: %d', [IPPaket^.TasinanVeriP]);
    end;
  end;
end;

// ip v6 protokolü üzerinden paket gönderim iþlevlerini gerçekleþtirir
procedure IP6PaketGonder(AHedefMACAdres: TMACAdres; AKaynakIP, AHedefIP: TIP6Adres;
  AProtokolTipi: TProtokolTipi; AHopSiniri: TSayi4; AVeri: Isaretci; AVeriUzunlugu: TSayi2);
var
  IPPaket: PIP6Paket;
  SaglamaToplami: TSayi2;
  v: PByte;
begin

  // paket için bellek bölgesi oluþtur
  IPPaket := GetMem(AVeriUzunlugu + IP6_BASLIK_U);

  // ip paketi hazýrlanýyor
  IPPaket^.Baslik := $00000060;
  IPPaket^.TasinanVeriU := htons(TSayi2(AVeriUzunlugu));

  case AProtokolTipi of
    ptICMP6 : IPPaket^.TasinanVeriP := PROTOKOL_ICMP6;
    ptTCP   : IPPaket^.TasinanVeriP := PROTOKOL_TCP;
    ptUDP   : IPPaket^.TasinanVeriP := PROTOKOL_UDP;
  end;

  IPPaket^.HopLimit := AHopSiniri;
  IPPaket^.KaynakIP := AKaynakIP;
  IPPaket^.HedefIP := AHedefIP;

  //Inc(GIPTanimlayici);

  v := @IPPaket^.Veri;
  Tasi2(AVeri, v, AVeriUzunlugu);

  // paketi donanýma (ethernet) gönder
  GAg0.AgKartinaVeriGonder(AHedefMACAdres, ptIP6, IPPaket, AVeriUzunlugu + IP6_BASLIK_U);

  FreeMem(IPPaket, AVeriUzunlugu + IP6_BASLIK_U);
end;

end.
