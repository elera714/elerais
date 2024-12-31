{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: ip.pas
  Dosya İşlevi: ip paket yönetim işlevlerini içerir

  Güncelleme Tarihi: 31/12/2024

 ==============================================================================}
{$mode objfpc}
unit ip;

interface

uses paylasim, genel, ag, sistemmesaj;

const
  IP_BASLIK_U = 20;

procedure IPPaketleriniIsle(AIPPaket: PIPPaket; AIPPaketUzunluk: TISayi4);
procedure IPPaketGonder(AHedefMACAdres: TMACAdres; AKaynakIP, AHedefIP: TIPAdres;
  AProtokolTipi: TProtokolTipi; AParcaSiraNo: TSayi2; AVeri: Isaretci; AVeriUzunlugu: TSayi2);

implementation

uses donusum, icmp, udp, tcp;

var
  GIPTanimlayici: TSayi2 = $BABA;

// sisteme gelen tüm ip paketlerini işler
procedure IPPaketleriniIsle(AIPPaket: PIPPaket; AIPPaketUzunluk: TISayi4);
begin

//  SISTEM_MESAJ_IP(RENK_KIRMIZI, 'IP1: ', AIPPaket^.HedefIP);
//  SISTEM_MESAJ_IP(RENK_KIRMIZI, 'IP2: ', GAgBilgisi.IP4Adres);

  // 1. sistemin ip adresi yok ise...
  // ve udp protokolünden ip adresi talebi mevcut ise
  if(GAgBilgisi.IPAdresiAlindi = False) then
  begin

    // udp protokolü
    if(AIPPaket^.Protokol = PROTOKOL_UDP) then
    begin

      Inc(UDPPaketSayisi);
      UDPPaketleriniIsle(AIPPaket);
    end;
  end
  // 2. sistemin ip adresi var ise...
  // sadece aygıta gelen ve yayın olarak gelen ip adreslerini işle
  else if(GAgBilgisi.IPAdresiAlindi) then
  begin

    if((IPKarsilastir(AIPPaket^.HedefIP, GAgBilgisi.IP4Adres)) or
      (IPKarsilastir2(AIPPaket^.HedefIP, GAgBilgisi.IP4Adres)) or
      (IPKarsilastir(AIPPaket^.HedefIP, IPAdres255))) then
    begin

      // icmp protokolü
      if(AIPPaket^.Protokol = PROTOKOL_ICMP) then
      begin

        Inc(ICMPPaketSayisi);
        ICMPPaketleriniIsle(@AIPPaket^.Veri, AIPPaketUzunluk - IP_BASLIK_U, AIPPaket^.KaynakIP)
      end
      // tcp protokolü
      else if(AIPPaket^.Protokol = PROTOKOL_TCP) then
      begin

        Inc(TCPPaketSayisi);
        TCPPaketleriniIsle(AIPPaket)
      end
      // udp protokolü
      else if(AIPPaket^.Protokol = PROTOKOL_UDP) then
      begin

        Inc(UDPPaketSayisi);
        UDPPaketleriniIsle(AIPPaket);
      end;
    end
    else
    begin

      Inc(GAEPaketSayisi);
      SISTEM_MESAJ(RENK_KIRMIZI, 'IP.PAS: bilinmeyen IP paketi:', []);
      SISTEM_MESAJ_IP(RENK_MOR, '  -> Hedef IP adresi: ', AIPPaket^.HedefIP);
      SISTEM_MESAJ(RENK_MOR, '  -> Hedef protokol: %d', [AIPPaket^.Protokol]);
    end;
  end;
end;

// ip protokolü üzerinden paket gönderim işlevlerini gerçekleştirir
procedure IPPaketGonder(AHedefMACAdres: TMACAdres; AKaynakIP, AHedefIP: TIPAdres;
  AProtokolTipi: TProtokolTipi; AParcaSiraNo: TSayi2; AVeri: Isaretci; AVeriUzunlugu: TSayi2);
var
  IPPaket: PIPPaket;
  SaglamaToplami: TSayi2;
  v: PByte;
begin

  // paket için bellek bölgesi oluştur
  IPPaket := GGercekBellek.Ayir(AVeriUzunlugu + IP_BASLIK_U);

  // ip paketi hazırlanıyor
  IPPaket^.SurumVeBaslikUzunlugu := $45;      // 4 = ip4; 5 * 4 = 20 = ip başlık uzunluğu
  IPPaket^.ServisTipi := $00;
  IPPaket^.ToplamUzunluk := htons(AVeriUzunlugu + IP_BASLIK_U);
  IPPaket^.Tanimlayici := htons(GIPTanimlayici);
  // ParcaSiraNo: $4000 = 16 bit -> 010 0000000000000
  // ilk 3 bit = 2 = parçalanma yok, diğer bitler parça no = 0
  IPPaket^.ParcaSiraNo := htons(AParcaSiraNo);
  IPPaket^.YasamSuresi := $40;
  case AProtokolTipi of
    ptICMP: IPPaket^.Protokol := PROTOKOL_ICMP;
    ptTCP : IPPaket^.Protokol := PROTOKOL_TCP;
    ptUDP : IPPaket^.Protokol := PROTOKOL_UDP;
  end;
  IPPaket^.KaynakIP := AKaynakIP;
  IPPaket^.HedefIP := AHedefIP;

  // sağlama öncesi SaglamaToplami değeri sıfırlanıyor
  IPPaket^.SaglamaToplami := 0;
  SaglamaToplami := SaglamaToplamiOlustur(IPPaket, IP_BASLIK_U, nil, 0);
  IPPaket^.SaglamaToplami := SaglamaToplami;

  Inc(GIPTanimlayici);

  v := @IPPaket^.Veri;
  Tasi2(AVeri, v, AVeriUzunlugu);

  // paketi donanıma (ethernet) gönder
  AgKartinaVeriGonder(AHedefMACAdres, ptIP, IPPaket, AVeriUzunlugu + IP_BASLIK_U);

  GGercekBellek.YokEt(IPPaket, AVeriUzunlugu + IP_BASLIK_U);
end;

end.
