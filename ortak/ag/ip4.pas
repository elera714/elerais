{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: ip4.pas
  Dosya İşlevi: ip tutanak (protokol) v4 yönetim işlevlerini içerir

  Güncelleme Tarihi: 06/11/2026

 ==============================================================================}
{$mode objfpc}
unit ip4;

interface

uses paylasim, ip, ethernet;

const
  IP4_BASLIK_U = 20;

type
  TIP4 = class(TIP)
  private
    FIP4Tanimlayici: TSayi2;
  public
    FKaynakIPAdres, FHedefIPAdres: TIP4Adres;
    // ABagNesne nesnesi icmpv4, icmpv6 ve arp tutanağı için TAgBaglantisi nesnesini
    // diğer tutanaklar için TBaglanti nesnesini temsil eder
    constructor Create(ABagNesne: TObject; AHedefMACAdres: TMACAdres); override;
    procedure PaketleVeGonder(ATutanakTipi: TTutanakTipi; AParcaSiraNo: TSayi2;
      AVeri: Isaretci; AVeriUzunlugu: TSayi2);
    procedure Gonder(AVeri: Isaretci; AVeriU: TSayi4); override;
  end;

procedure IP4VerileriniIsle(AEthernetPaket: PEthernetPaket);

implementation

uses donusum, icmp4, udp, tcp, islevler, baglantilar, sistemmesaj;

{==============================================================================
  tcp/ip tutanağının ip v4 katmanına gelen verileri işler
 ==============================================================================}
procedure IP4VerileriniIsle(AEthernetPaket: PEthernetPaket);
var
  IPPaket: PIP4Paket;
begin

  IPPaket := @AEthernetPaket^.Veri;

  // 1. sistemin ip adresi yok ise...
  // sistemin udp tutanağından ip adresi talebi olasılığına karşı udp verilerini işle
  if(GAgBaglantilari.AB.IP4AdresiAlindi = False) then
  begin

    // udp tutanağı
    if(IPPaket^.Tutanak = TUTANAK_UDP) then
    begin

      UDPVerileriniIsle(AEthernetPaket);
      Inc(GAgBaglantilari.AB.FUDP4PaketSayisi);
    end;
  end
  // 2. sistemin ip adresi var ise...
  // sadece aygıta gelen ve yayın olarak gelen ip adreslerini işle
  else if(GAgBaglantilari.AB.IP4AdresiAlindi) then
  begin

    if((IP4Karsilastir(IPPaket^.HedefIPAdres, GAgBaglantilari.AB.IP4Adresim)) or
      (IP4Karsilastir2(IPPaket^.HedefIPAdres, GAgBaglantilari.AB.IP4Adresim)) or
      (IP4Karsilastir(IPPaket^.HedefIPAdres, IP4Adres255))) then
    begin

      // icmp tutanağı
      if(IPPaket^.Tutanak = TUTANAK_ICMP4) then
      begin

        GAgBaglantilari.AB.FICMP4.VerileriIsle(AEthernetPaket);
        Inc(GAgBaglantilari.AB.FICMPv4PaketSayisi);
      end

      // tcp tutanağı
      else if(IPPaket^.Tutanak = TUTANAK_TCP) then
      begin

        TCPVerileriniIsle(AEthernetPaket);
        Inc(GAgBaglantilari.AB.FTCP4PaketSayisi);
      end

      // udp tutanağı
      else if(IPPaket^.Tutanak = TUTANAK_UDP) then
      begin

        UDPVerileriniIsle(AEthernetPaket);
        Inc(GAgBaglantilari.AB.FUDP4PaketSayisi);
      end
      else
      begin

        Inc(GAgBaglantilari.AB.FGAEPaketSayisi);
        SISTEM_MESAJ(mtUyari, RENK_PEMBE, 'IP4.PAS: bilinmeyen tutanak:', []);
        SISTEM_MESAJ(mtUyari, RENK_TURKUAZ, '  - Hedef tutanak: %d', [IPPaket^.Tutanak]);
      end;
    end
    else
    begin

      Inc(GAgBaglantilari.AB.FGAEPaketSayisi);
      SISTEM_MESAJ(mtUyari, RENK_PEMBE, 'IP4.PAS: bilinmeyen hedef IP paketi:', []);
      SISTEM_MESAJ_IP4(mtUyari, RENK_TURKUAZ, '  - Hedef IP4 adresi: ', IPPaket^.HedefIPAdres);
      SISTEM_MESAJ(mtUyari, RENK_TURKUAZ, '  - Hedef tutanak: %d', [IPPaket^.Tutanak]);
    end;
  end;
end;

{==============================================================================
  ip tutanak (protokol) ana yükleme işlevlerini içerir
 ==============================================================================}
constructor TIP4.Create(ABagNesne: TObject; AHedefMACAdres: TMACAdres);
begin

  inherited Create(ABagNesne, AHedefMACAdres);

  FIP4Tanimlayici := $BABA;
end;

{==============================================================================
  ip paket hazırlama ve gönderme işlevlerini gerçekleştirir
 ==============================================================================}
procedure TIP4.PaketleVeGonder(ATutanakTipi: TTutanakTipi; AParcaSiraNo: TSayi2;
  AVeri: Isaretci; AVeriUzunlugu: TSayi2);
var
  IPPaket: PIP4Paket;
  SaglamaToplami: TSayi2;
  p: PByte;
begin

  // paket için bellek bölgesi oluştur
  IPPaket := GetMem(AVeriUzunlugu + IP4_BASLIK_U);

  // ip paketi hazırlanıyor

  // $45 -> 4 = ip4; 5 * 4 = 20 = ip başlık uzunluğu
  IPPaket^.SurumVeBaslikUzunlugu := $45;
  IPPaket^.ServisTipi := $00;
  IPPaket^.ToplamUzunluk := htons(TSayi2(AVeriUzunlugu + IP4_BASLIK_U));
  IPPaket^.Tanimlayici := htons(FIP4Tanimlayici);
  // ParcaSiraNo: $4000 = 16 bit -> 010 0000000000000
  // ilk 3 bit = 2 = parçalanma yok, diğer bitler parça no = 0
  IPPaket^.ParcaSiraNo := htons(AParcaSiraNo);
  IPPaket^.YasamSuresi := $80;    // $80 = 128;
  case ATutanakTipi of
    ttICMP4 : IPPaket^.Tutanak := TUTANAK_ICMP4;
    ttTCP   : IPPaket^.Tutanak := TUTANAK_TCP;
    ttUDP   : IPPaket^.Tutanak := TUTANAK_UDP;
  end;

  IPPaket^.KaynakIPAdres := FKaynakIPAdres;
  IPPaket^.HedefIPAdres := FHedefIPAdres;

  // sağlama öncesi SaglamaToplami değeri sıfırlanıyor
  IPPaket^.SaglamaToplami := 0;
  SaglamaToplami := SaglamaToplamiOlustur(IPPaket, IP4_BASLIK_U, nil, 0);
  IPPaket^.SaglamaToplami := SaglamaToplami;

  Inc(FIP4Tanimlayici);

  p := @IPPaket^.Veri;
  Tasi2(AVeri, p, AVeriUzunlugu);

  // paketi ip katmanına gönder
  Gonder(IPPaket, AVeriUzunlugu + IP4_BASLIK_U);

  FreeMem(IPPaket, AVeriUzunlugu + IP4_BASLIK_U);
end;

{==============================================================================
  ip paket veri gönderme işlevi
 ==============================================================================}
procedure TIP4.Gonder(AVeri: Isaretci; AVeriU: TSayi4);
begin

  if(FBagNesne is TAgBaglantisi) then

    TAgBaglantisi(FBagNesne).FEthernet.Gonder(ttIP4, FHedefMACAdres, AVeri, AVeriU)

  else TBaglanti(FBagNesne).FAB.FEthernet.Gonder(ttIP4, FHedefMACAdres, AVeri, AVeriU);
end;

end.
