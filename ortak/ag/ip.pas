{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: ip.pas
  Dosya İşlevi: ip paket yönetim işlevlerini içerir

  Güncelleme Tarihi: 05/09/2024

 ==============================================================================}
{$mode objfpc}
unit ip;

interface

uses paylasim, genel, saglama, ag, sistemmesaj;

const
  IP_BASLIK_U = 20;

procedure IPPaketleriniIsle(AIPPaket: PIPPaket; AIPPaketUzunluk: TISayi4);
procedure IPPaketGonder(AHedefMACAdres: TMACAdres; AKaynakAdres, AHedefAdres: TIPAdres;
  AProtokolTip: TProtokolTip; ABayrakVeParcaSiraNo: TSayi2; AVeri: Isaretci;
  AVeriUzunlugu: TSayi2);

implementation

uses donusum, icmp, udp, tcp;

var
  GIPTanimlayici: TSayi2 = $BABA;

// sisteme gelen tüm ip paketlerini işler
procedure IPPaketleriniIsle(AIPPaket: PIPPaket; AIPPaketUzunluk: TISayi4);
begin

  // sistemin ip adresi yok ve ip adres talebinde bulunulmuş ise
  if(IPKarsilastir(AgBilgisi.IP4Adres, IPAdres0)) and IPAdresTalebiBekleniyor then
  begin

    // udp protokolü
    if(AIPPaket^.Protokol = PROTOKOL_UDP) then
    begin

      Inc(UDPPaketSayisi);
      UDPPaketleriniIsle(PUDPPaket(@AIPPaket^.Veri));
    end;
  end
  // sadece aygıta gelen ve yayın olarak gelen ip adreslerini işle
  else if((IPKarsilastir(AIPPaket^.HedefIP, AgBilgisi.IP4Adres)) or
    (IPKarsilastir2(AIPPaket^.HedefIP, AgBilgisi.IP4Adres)) or
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
      UDPPaketleriniIsle(PUDPPaket(@AIPPaket^.Veri));
    end;
  end
  else
  begin

    Inc(GAEPaketSayisi);
    SISTEM_MESAJ(RENK_KIRMIZI, 'IP.PAS: bilinmeyen IP paketi:', []);
    SISTEM_MESAJ_IP(RENK_BORDO, '  -> Hedef IP adresi: ', AIPPaket^.HedefIP);
    SISTEM_MESAJ(RENK_BORDO, '  -> Hedef protokol: %d', [AIPPaket^.Protokol]);
  end;
end;

// ip protokolü üzerinden paket gönderim işlevlerini gerçekleştirir
procedure IPPaketGonder(AHedefMACAdres: TMACAdres; AKaynakAdres, AHedefAdres: TIPAdres;
  AProtokolTip: TProtokolTip; ABayrakVeParcaSiraNo: TSayi2; AVeri: Isaretci;
  AVeriUzunlugu: TSayi2);
var
  IPPaket: PIPPaket;
  Veri: PByte;
  SaglamaToplam: TSayi2;
begin

  // paket için bellek bölgesi oluştur
  IPPaket := GGercekBellek.Ayir(AVeriUzunlugu + IP_BASLIK_U);

  // ip paketi hazırlanıyor
  IPPaket^.SurumVeBaslikUzunlugu := $45;     // 4 = ip4; 5 * 4 = ip başlık uzunluğu
  IPPaket^.ServisTipi := $00;
  IPPaket^.ToplamUzunluk := Takas2(AVeriUzunlugu + IP_BASLIK_U);
  IPPaket^.Tanimlayici := Takas2(GIPTanimlayici);
  // BayrakVeParcaSiraNo: $4000 = tcp / http, $0000 = dns
  IPPaket^.BayrakVeParcaSiraNo := Takas2(ABayrakVeParcaSiraNo);
  IPPaket^.YasamSuresi := $80;
  case AProtokolTip of
    ptICMP: IPPaket^.Protokol := PROTOKOL_ICMP;
    ptTCP : IPPaket^.Protokol := PROTOKOL_TCP;
    ptUDP : IPPaket^.Protokol := PROTOKOL_UDP;
  end;
  IPPaket^.KaynakIP := AKaynakAdres;
  IPPaket^.HedefIP := AHedefAdres;

  // sağlama öncesi BaslikSaglamaToplami değeri sıfırlanıyor
  IPPaket^.BaslikSaglamaToplami := $0000;
  SaglamaToplam := SaglamasiniYap(IPPaket, IP_BASLIK_U, nil, 0);
  IPPaket^.BaslikSaglamaToplami := Takas2(SaglamaToplam);

  Inc(GIPTanimlayici);

  Veri := @IPPaket^.Veri;
  Tasi2(AVeri, Veri, AVeriUzunlugu);

  // paketi donanıma (ethernet) gönder
  AgKartinaVeriGonder(AHedefMACAdres, ptIP, IPPaket, AVeriUzunlugu + IP_BASLIK_U);

  GGercekBellek.YokEt(IPPaket, AVeriUzunlugu + IP_BASLIK_U);
end;

end.
