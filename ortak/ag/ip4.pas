{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: ip4.pas
  Dosya İşlevi: ip tutanak (protokol) v4 yönetim işlevlerini içerir

  Güncelleme Tarihi: 05/09/2026

 ==============================================================================}
{$mode objfpc}
unit ip4;

interface

uses paylasim, sistemmesaj, ip, ethernet;

const
  IP4_BASLIK_U = 20;

type
  TIP4 = class(TIP)
  private
    FIP4Tanimlayici: TSayi4;
    FKaynakIP4Adres, FHedefIP4Adres: TIP4Adres;
  public
    constructor Create(ABaglanti: TObject); override;
    procedure Ozellestir(AKaynakIP4Adres, AHedefIP4Adres: TIP4Adres);
    procedure Gonder(AHedefMACAdres: TMACAdres; AVeri: Isaretci; AVeriU: TSayi4); override;
    procedure PaketleVeGonder(AHedefMACAdres: TMACAdres; AProtokolTipi: TProtokolTipi;
      AParcaSiraNo: TSayi4; AVeri: Isaretci; AVeriUzunlugu: TSayi4);
    procedure VerileriIsle(AEthernetPaket: PEthernetPaket);
  end;

implementation

uses donusum, icmp4, udp, tcp, islevler, baglantilar, ag;

{==============================================================================
  ip tutanak (protokol) ana yükleme işlevlerini içerir
 ==============================================================================}
constructor TIP4.Create(ABaglanti: TObject);
begin

  inherited Create(ABaglanti);

  FIP4Tanimlayici := $BABA;
end;

{==============================================================================
  sınıf bilgilerini özelleştirir
 ==============================================================================}
procedure TIP4.Ozellestir(AKaynakIP4Adres, AHedefIP4Adres: TIP4Adres);
begin

  FKaynakIP4Adres := AKaynakIP4Adres;
  FHedefIP4Adres := AHedefIP4Adres;
end;

{==============================================================================
  ip paket veri gönderme işlevi
 ==============================================================================}
procedure TIP4.Gonder(AHedefMACAdres: TMACAdres; AVeri: Isaretci; AVeriU: TSayi4);
begin

  TAgBaglantisi(FBaglanti).FEthernet.Gonder(AHedefMACAdres, ptIP4, AVeri, AVeriU);
end;

{==============================================================================
  ip paket hazırlama ve gönderme işlevlerini gerçekleştirir
 ==============================================================================}
procedure TIP4.PaketleVeGonder(AHedefMACAdres: TMACAdres; AProtokolTipi: TProtokolTipi;
  AParcaSiraNo: TSayi4; AVeri: Isaretci; AVeriUzunlugu: TSayi4);
var
  IPPaket: PIP4Paket;
  SaglamaToplami: TSayi2;
  p: PByte;
begin

  // paket için bellek bölgesi oluştur
  IPPaket := GetMem(AVeriUzunlugu + IP4_BASLIK_U);

  // ip paketi hazırlanıyor
  IPPaket^.SurumVeBaslikUzunlugu := $45;      // 4 = ip4; 5 * 4 = 20 = ip başlık uzunluğu
  IPPaket^.ServisTipi := $00;
  IPPaket^.ToplamUzunluk := htons(TSayi2(AVeriUzunlugu + IP4_BASLIK_U));
  IPPaket^.Tanimlayici := htons(TSayi2(FIP4Tanimlayici));
  // ParcaSiraNo: $4000 = 16 bit -> 010 0000000000000
  // ilk 3 bit = 2 = parçalanma yok, diğer bitler parça no = 0
  IPPaket^.ParcaSiraNo := htons(TSayi2(AParcaSiraNo));
  IPPaket^.YasamSuresi := $40;
  case AProtokolTipi of
    ptICMP4 : IPPaket^.Protokol := PROTOKOL_ICMP4;
    ptTCP   : IPPaket^.Protokol := PROTOKOL_TCP;
    ptUDP   : IPPaket^.Protokol := PROTOKOL_UDP;
  end;
  IPPaket^.KaynakIP4Adres := FKaynakIP4Adres;
  IPPaket^.HedefIP4Adres := FHedefIP4Adres;

  // sağlama öncesi SaglamaToplami değeri sıfırlanıyor
  IPPaket^.SaglamaToplami := 0;
  SaglamaToplami := SaglamaToplamiOlustur(IPPaket, IP4_BASLIK_U, nil, 0);
  IPPaket^.SaglamaToplami := SaglamaToplami;

  Inc(FIP4Tanimlayici);

  p := @IPPaket^.Veri;
  Tasi2(AVeri, p, AVeriUzunlugu);

  // paketi ip katmanına gönder
  Gonder(AHedefMACAdres, IPPaket, AVeriUzunlugu + IP4_BASLIK_U);

  FreeMem(IPPaket, AVeriUzunlugu + IP4_BASLIK_U);
end;

{==============================================================================
  tcp/ip tutanağının ip katmanına gelen verileri işler
 ==============================================================================}
procedure TIP4.VerileriIsle(AEthernetPaket: PEthernetPaket);
var
  IP4Paket: PIP4Paket;
begin

  IP4Paket := @AEthernetPaket^.Veri;

//  SISTEM_MESAJ_IP(RENK_KIRMIZI, 'IP1: ', AIPPaket^.HedefIP);
//  SISTEM_MESAJ_IP(RENK_KIRMIZI, 'IP2: ', GAgBilgisi.IP4Adres);

  // 1. sistemin ip adresi yok ise...
  // ve udp protokolünden ip adresi talebi mevcut ise
  if(GAgBaglantilari.AktifBaglanti.IP4AdresiAlindi = False) then
  begin

    // udp protokolü
    if(IP4Paket^.Protokol = PROTOKOL_UDP) then
    begin

      GUDP.VerileriIsle(AEthernetPaket);
      Inc(GAg.FUDPPaketSayisi);
    end;
  end
  // 2. sistemin ip adresi var ise...
  // sadece aygıta gelen ve yayın olarak gelen ip adreslerini işle
  else if(GAgBaglantilari.AktifBaglanti.IP4AdresiAlindi) then
  begin

    if((IP4Karsilastir(IP4Paket^.HedefIP4Adres, GAgBaglantilari.AktifBaglanti.IP4Adres)) or
      (IP4Karsilastir2(IP4Paket^.HedefIP4Adres, GAgBaglantilari.AktifBaglanti.IP4Adres)) or
      (IP4Karsilastir(IP4Paket^.HedefIP4Adres, IPAdres255))) then
    begin

      // icmp protokolü
      if(IP4Paket^.Protokol = PROTOKOL_ICMP4) then
      begin

        GAgBaglantilari.AktifBaglanti.FICMP4.VerileriIsle(AEthernetPaket);
      end
      // tcp protokolü
      else if(IP4Paket^.Protokol = PROTOKOL_TCP) then
      begin

        GTCP.VerileriIsle(AEthernetPaket);
        Inc(GAg.FTCP4PaketSayisi);
      end
      // udp protokolü
      else if(IP4Paket^.Protokol = PROTOKOL_UDP) then
      begin

        GUDP.VerileriIsle(AEthernetPaket);
        Inc(GAg.FUDPPaketSayisi);
      end;
    end
    else
    begin

      Inc(GAg.FGAEPaketSayisi);
      SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'IP4.PAS: bilinmeyen IP paketi:', []);
      SISTEM_MESAJ_IP4(mtUyari, RENK_SIYAH, '  -> Hedef IP4 adresi: ', IP4Paket^.HedefIP4Adres);
      SISTEM_MESAJ(mtUyari, RENK_SIYAH, '  -> Hedef protokol: %d', [IP4Paket^.Protokol]);
    end;
  end;
end;

end.
