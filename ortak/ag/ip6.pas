{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: ip6.pas
  Dosya Ýþlevi: ip tutanak (protokol) v6 yönetim iþlevlerini içerir

  Güncelleme Tarihi: 12/11/2026

 ==============================================================================}
{$mode objfpc}
unit ip6;

interface

uses paylasim, sistemmesaj, ip;

const
  IP6_BASLIK_U = 40;

type
  TIP6 = class(TIP)
  public
    FKaynakIPAdres, FHedefIPAdres: TIP6Adres;
    // ABagNesne nesnesi icmpv4, icmpv6 ve arp tutanaðý için TAgBaglantisi nesnesini
    // diðer tutanaklar için TBaglanti nesnesini temsil eder
    constructor Create(ABagNesne: TObject; AHedefMACAdres: TMACAdres); override;
    procedure PaketleVeGonder(ATutanakTipi: TTutanakTipi; AHopSiniri: TSayi4;
      AVeri: Isaretci; AVeriUzunlugu: TSayi2);
    procedure Gonder(AVeri: Isaretci; AVeriU: TSayi4); override;
  end;

procedure IP6VerileriniIsle(AEthernetPaket: PEthernetPaket);
function IP6AdresiKabulEdilsinMi(AIPAdres: TIP6Adres): Boolean;

implementation

uses donusum, icmp6, udp, tcp, islevler, ag, baglantilar;

{==============================================================================
  tcp/ip tutanaðýnýn ip v6 katmanýna gelen verileri iþler
 ==============================================================================}
procedure IP6VerileriniIsle(AEthernetPaket: PEthernetPaket);
var
  IPPaket: PIP6Paket;
begin

  IPPaket := @AEthernetPaket^.Veri;

  // 1. sistemin ip adresi yok ise...
  // sistemin udp tutanaðýndan ip adresi talebi olasýlýðýna karþý udp verilerini iþle
  if(GAgBaglantilari.AB.IP6AdresiAlindi = False) then
  begin

    // udp tutanaðý
    if(IPPaket^.TasinanVeriP = TUTANAK_UDP) then
    begin

      UDPVerileriniIsle(AEthernetPaket);
      Inc(GAgBaglantilari.AB.FUDP6PaketSayisi);
    end;
  end
  // 2. sistemin ip adresi var ise...
  // sadece aygýta gelen ve yayýn olarak gelen ip adreslerini iþle
  else if(GAgBaglantilari.AB.IP6AdresiAlindi) then
  begin

    {$IFDEF SISTEM_SUNUCU}
    if(1 = 1) then
    {$ELSE}
    if(IP6AdresiKabulEdilsinMi(IPPaket^.HedefIPAdres)) then
    {$ENDIF}
    begin

      // icmp tutanaðý
      if(IPPaket^.TasinanVeriP = TUTANAK_ICMP6) then
      begin

        GAgBaglantilari.AB.FICMP6.VerileriIsle(AEthernetPaket);
        Inc(GAgBaglantilari.AB.FICMPv6PaketSayisi);
      end

      // tcp tutanaðý
      else if(IPPaket^.TasinanVeriP = TUTANAK_TCP) then
      begin

        TCPVerileriniIsle(AEthernetPaket);
        Inc(GAgBaglantilari.AB.FTCP6PaketSayisi);
      end

      // udp tutanaðý
      else if(IPPaket^.TasinanVeriP = TUTANAK_UDP) then
      begin

        UDPVerileriniIsle(AEthernetPaket);
        Inc(GAgBaglantilari.AB.FUDP6PaketSayisi);
      end
      else
      begin

        Inc(GAgBaglantilari.AB.FGAEPaketSayisi);
        SISTEM_MESAJ(mtUyari, RENK_PEMBE, 'IP6.PAS: bilinmeyen tutanak:', []);
        SISTEM_MESAJ(mtUyari, RENK_TURKUAZ, '  - Hedef tutanak: %d', [IPPaket^.TasinanVeriP]);
      end;
    end
    else
    begin

      Inc(GAgBaglantilari.AB.FGAEPaketSayisi);
      SISTEM_MESAJ(mtUyari, RENK_PEMBE, 'IP6.PAS: bilinmeyen hedef IP paketi:', []);
      SISTEM_MESAJ_IP6(mtUyari, RENK_TURKUAZ, '  - Hedef IP6 adresi: ', IPPaket^.HedefIPAdres);
      SISTEM_MESAJ(mtUyari, RENK_TURKUAZ, '  - Hedef tutanak: %d', [IPPaket^.TasinanVeriP]);
    end;
  end;
end;

{==============================================================================
  belirtilen ip6 adresinin kabul edilip edilmeyeceðine karar verir
 ==============================================================================}
function IP6AdresiKabulEdilsinMi(AIPAdres: TIP6Adres): Boolean;
begin

  // gelen veri benim ip6 adresime ise, kabul et
  if(IP6Karsilastir(AIPAdres, GAgBaglantilari.AB.IP6Adresim)) then Exit(True);

  // gelen veri benim yayýn adresime ise, kabul et
  if(IP6Karsilastir(AIPAdres, YayinIP6Adres)) then Exit(True);

  // aksi durumda kabul etme
  Result := False;
end;

{==============================================================================
  ip tutanak (protokol) ana yükleme iþlevlerini içerir
 ==============================================================================}
constructor TIP6.Create(ABagNesne: TObject; AHedefMACAdres: TMACAdres);
begin

  inherited Create(ABagNesne, AHedefMACAdres);
end;

{==============================================================================
  ip paket hazýrlama ve gönderme iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure TIP6.PaketleVeGonder(ATutanakTipi: TTutanakTipi; AHopSiniri: TSayi4;
  AVeri: Isaretci; AVeriUzunlugu: TSayi2);
var
  IPPaket: PIP6Paket;
  v: PByte;
begin

  // paket için bellek bölgesi oluþtur
  IPPaket := GetMem(AVeriUzunlugu + IP6_BASLIK_U);

  // ip paketi hazýrlanýyor

  IPPaket^.Baslik := $00000060;
  IPPaket^.TasinanVeriU := htons(AVeriUzunlugu);
  case ATutanakTipi of
    ttICMP6 : IPPaket^.TasinanVeriP := TUTANAK_ICMP6;
    ttTCP   : IPPaket^.TasinanVeriP := TUTANAK_TCP;
    ttUDP   : IPPaket^.TasinanVeriP := TUTANAK_UDP;
  end;
  IPPaket^.HopLimit := AHopSiniri;

  IPPaket^.KaynakIPAdres := FKaynakIPAdres;
  IPPaket^.HedefIPAdres := FHedefIPAdres;

  v := @IPPaket^.Veri;
  Tasi2(AVeri, v, AVeriUzunlugu);

  // paketi ip katmanýna gönder
  Gonder(IPPaket, AVeriUzunlugu + IP6_BASLIK_U);

  FreeMem(IPPaket, AVeriUzunlugu + IP6_BASLIK_U);
end;

{==============================================================================
  ip paket veri gönderme iþlevi
 ==============================================================================}
procedure TIP6.Gonder(AVeri: Isaretci; AVeriU: TSayi4);
begin

  if(FBagNesne is TAgBaglantisi) then

    TAgBaglantisi(FBagNesne).FEthernet.Gonder(ttIP6, FHedefMACAdres, AVeri, AVeriU)

  else TBaglanti(FBagNesne).FAB.FEthernet.Gonder(ttIP6, FHedefMACAdres, AVeri, AVeriU);
end;

end.
