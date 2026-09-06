{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: ip6.pas
  Dosya Ýþlevi: ip tutanak (protokol) v6 yönetim iþlevlerini içerir

  Güncelleme Tarihi: 10/06/2026

 ==============================================================================}
{$mode objfpc}
unit ip6;

interface

uses paylasim, sistemmesaj, ip;

const
  IP6_BASLIK_U = 40;

type
  TIP6 = class(TIP)
  private
    FKaynakIP6Adres, FHedefIP6Adres: TIP6Adres;
  public
    constructor Create(ABaglanti: TObject); override;
    procedure Ozellestir(AKaynakIP6Adres, AHedefIP6Adres: TIP6Adres);
    procedure Gonder(AHedefMACAdres: TMACAdres; AVeri: Isaretci; AVeriU: TSayi4); override;
    procedure PaketleVeGonder(AHedefMACAdres: TMACAdres; AProtokolTipi: TProtokolTipi;
      AHopSiniri: TSayi4; AVeri: Isaretci; AVeriUzunlugu: TSayi4);
    procedure VerileriIsle(AEthernetPaket: PEthernetPaket; AIPPaketUzunluk: TISayi4);
  end;

implementation

uses donusum, icmp6, udp, tcp, islevler, ag, baglantilar;

var
  GIPTanimlayici: TSayi2 = $BABA;

{==============================================================================
  ip tutanak (protokol) ana yükleme iþlevlerini içerir
 ==============================================================================}
constructor TIP6.Create(ABaglanti: TObject);
begin

  inherited Create(ABaglanti);
end;

{==============================================================================
  sýnýf bilgilerini özelleþtirir
 ==============================================================================}
procedure TIP6.Ozellestir(AKaynakIP6Adres, AHedefIP6Adres: TIP6Adres);
begin

  FKaynakIP6Adres := AKaynakIP6Adres;
  FHedefIP6Adres := AHedefIP6Adres;
end;

procedure TIP6.Gonder(AHedefMACAdres: TMACAdres; AVeri: Isaretci; AVeriU: TSayi4);
begin

  TBaglanti(FBaglanti).FEthernet.Gonder(AHedefMACAdres, ptIP6, AVeri, AVeriU);
end;

// sisteme gelen tüm ip paketlerini iþler
procedure TIP6.VerileriIsle(AEthernetPaket: PEthernetPaket; AIPPaketUzunluk: TISayi4);
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
  if(IP6Karsilastir(IPPaket^.HedefIP6, IP6AdresFF02_0002)) then
  begin

    GICMP6.VerileriIsle(AEthernetPaket);
    Inc(GAg.FICMP6PaketSayisi);
  end
  else if(IP6Karsilastir(IPPaket^.HedefIP6, IP6AdresFF02_0102)) then
  begin

    GUDP.VerileriIsle(AEthernetPaket);
    Inc(GAg.FUDPPaketSayisi);
  end
  else if(IP6Karsilastir(IPPaket^.HedefIP6, YayinIP6Adres)) then
  begin

    { TODO - çalýþmýyor }
    //SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Son asama2', []);
    GICMP6.VerileriIsle(AEthernetPaket);
    Inc(GAg.FICMP6PaketSayisi);
  end
  else
  begin

    // icmp protokolü
    if(IPPaket^.TasinanVeriP = PROTOKOL_ICMP6) then
    begin

      GICMP6.VerileriIsle(AEthernetPaket);
      Inc(GAg.FICMP6PaketSayisi);
    end
    // tcp protokolü
    else if(IPPaket^.TasinanVeriP = PROTOKOL_TCP) then
    begin

      GTCP.VerileriIsle(AEthernetPaket);
      Inc(GAg.FTCP6PaketSayisi);
    end
    // udp protokolü
    else if(IPPaket^.TasinanVeriP = PROTOKOL_UDP) then
    begin

      GUDP.VerileriIsle(AEthernetPaket);
      Inc(GAg.FUDPPaketSayisi);
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
procedure TIP6.PaketleVeGonder(AHedefMACAdres: TMACAdres; AProtokolTipi: TProtokolTipi;
  AHopSiniri: TSayi4; AVeri: Isaretci; AVeriUzunlugu: TSayi4);
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
  IPPaket^.KaynakIP := FKaynakIP6Adres;
  IPPaket^.HedefIP6 := FHedefIP6Adres;

  //Inc(GIPTanimlayici);

  v := @IPPaket^.Veri;
  Tasi2(AVeri, v, AVeriUzunlugu);

  // paketi ip katmanýna gönder
  Gonder(AHedefMACAdres, IPPaket, AVeriUzunlugu + IP6_BASLIK_U);

  FreeMem(IPPaket, AVeriUzunlugu + IP6_BASLIK_U);
end;

end.
