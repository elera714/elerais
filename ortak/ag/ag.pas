{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: ag.pas
  Dosya Ýþlevi: að (network) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 16/09/2024

 ==============================================================================}
{$mode objfpc}
unit ag;

interface
{==============================================================================
  big endian > little endian çevrimi

  Bellek Yerleþimleri: (Örnek Sayý: $12345678)
    Big Endian:   78 56 34 12
    Litle Endian: 12 34 56 78
 ==============================================================================}
uses paylasim, aygityonetimi, iletisim, genel;

const
  ETHERNET_BASLIKU = TSayi1(14);

var
  // paket baþlýklarý da dahil olmak üzere tüm veri sayýlarýný içerir.
  AlinanByte, GonderilenByte: TSayi4;

procedure Yukle;
procedure IlkAdresDegerleriniYukle;
function GenelAgCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
procedure AgKartiVeriAlmaIslevi;
function AgKartindanVeriAl(AHedefBellekAdresi: Isaretci): Integer;
procedure AgKartinaVeriGonder(AHedefMAC: TMACAdres; AProtokolTip: TProtokolTip;
  AVeri: Isaretci; AVeriUzunlugu: TSayi2);

implementation

uses src_pcnet32, arp, udp, dns, icmp, ip, sistemmesaj, donusum;

{==============================================================================
  að ilk deðer yüklemelerini gerçekleþtirir
 ==============================================================================}
procedure Yukle;
begin

  // að bilgileri öndeðerlerle yükleniyor
  IlkAdresDegerleriniYukle;

  SISTEM_MESAJ(RENK_LACIVERT, '+ Ethernet aygýtlarý yükleniyor...', []);
  AgAygitlariniYukle;

  // en az 1 að aygýtý yüklendi ise
  if(AgYuklendi) then
  begin

    SISTEM_MESAJ(RENK_LACIVERT, '+ Baðlantý yapýlarý ilk deðerlerle yükleniyor...', []);
    iletisim.Yukle;

    SISTEM_MESAJ(RENK_LACIVERT, '+ ARP protokolü yükleniyor...', []);
    arp.Yukle;

    SISTEM_MESAJ(RENK_LACIVERT, '+ DNS protokolü yükleniyor...', []);
    dns.Yukle;
  end;

  AlinanByte := 0;
  GonderilenByte := 0;
end;

{==============================================================================
  að iletiþim alanlarýný ilk deðerlerle yükler
 ==============================================================================}
procedure IlkAdresDegerleriniYukle;
begin

  GAgBilgisi.IPAdresiAlindi := False;
  GAgBilgisi.MACAdres := MACAdres0;
  GAgBilgisi.IP4Adres := IPAdres0;
  GAgBilgisi.AltAgMaskesi := IPAdres0;
  GAgBilgisi.AgGecitAdresi := IPAdres0;
  GAgBilgisi.DHCPSunucusu := IPAdres0;
  GAgBilgisi.DNSSunucusu := IPAdres0;
  GAgBilgisi.IPKiraSuresi := 0;
end;

{==============================================================================
  að kesme çaðrýlarýný yönetir
 ==============================================================================}
function GenelAgCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  IslevNo: TSayi4;
  AgBilgisi: PAgBilgisi;
begin

  // iþlev no
  IslevNo := (AIslevNo and $FF);

  // að ayarlarýný geri döndür
  if(IslevNo = 1) then
  begin

    AgBilgisi := Isaretci(PSayi4(ADegiskenler + 00)^ + CalisanGorevBellekAdresi);
    AgBilgisi^.MACAdres := GAgBilgisi.MACAdres;
    AgBilgisi^.IP4Adres := GAgBilgisi.IP4Adres;
    AgBilgisi^.AltAgMaskesi := GAgBilgisi.AltAgMaskesi;
    AgBilgisi^.AgGecitAdresi := GAgBilgisi.AgGecitAdresi;
    AgBilgisi^.DHCPSunucusu := GAgBilgisi.DHCPSunucusu;
    AgBilgisi^.DNSSunucusu := GAgBilgisi.DNSSunucusu;
    AgBilgisi^.IPKiraSuresi := GAgBilgisi.IPKiraSuresi;

    Result := 1;
  end

  else Result := HATA_ISLEV;
end;

{==============================================================================
  að kartýna (ethernet) gelen verilerin protokollere yönlendirilme iþlevi
  bilgi: bu iþlev iþletim sistemi döngüsü içinde sürekli çaðrýlýr
 ==============================================================================}
procedure AgKartiVeriAlmaIslevi;
var
  _EthernetPaket: PEthernetPaket;
  _Bellek: array[0..$FFF] of TSayi1;
  _VeriUzunluk, _Protokol: TSayi2;
  _ARPPaket: PARPPaket;
begin

  // að yüklendi ise ...
  if(AgYuklendi) then
  begin

    FillByte(_Bellek, $1000, 0);

    // að kartýna gelen ham bilgiyi al
    _VeriUzunluk := AgKartindanVeriAl(@_Bellek);
    if(_VeriUzunluk > 0) then
    begin

      _EthernetPaket := @_Bellek[0];

      { TODO - _Protokol deðeri ntohs ile çevrilerek deðer network sýralý sorgulanacak }
      _Protokol := _EthernetPaket^.PaketTipi;
      SISTEM_MESAJ2_S16(RENK_YESIL, 'Protokol: $', _Protokol, 4);

      // ******* protokollerin iþlenmesi *******

      // ARP protokolü
      if(htons(_Protokol) = PROTOKOL_ARP) then
      begin

        _ARPPaket := @_EthernetPaket^.Veri;
        if(IPKarsilastir(_ARPPaket^.HedefIPAdres, GAgBilgisi.IP4Adres)) then
          ARPPaketleriniIsle(_EthernetPaket)
      end

      // IP protokolü
      else if(_Protokol = PROTOKOL_IP) then
      begin

        SISTEM_MESAJ2_S16(RENK_YESIL, 'Protokol: $', _Protokol, 4);
        IPPaketleriniIsle(@_EthernetPaket^.Veri, _VeriUzunluk - ETHERNET_BASLIKU)
      end
      else

      // bilinmeyen protokol
      begin

        SISTEM_MESAJ_S16(RENK_KIRMIZI, 'AG.PP: Bilinmeyen Protokol: ', _Protokol, 4);
      end;
    end;

    //SISTEM_MESAJ_S16(RENK_YESIL, 'VUzunluk: ', _VeriUzunluk, 8);
  end;
end;

{==============================================================================
  að kartýna (ethernet) gelen verileri alýr
 ==============================================================================}
function AgKartindanVeriAl(AHedefBellekAdresi: Isaretci): TISayi4;
var
  _Bellek: array[0..$FFF] of TSayi1;
  _VeriUzunluk: TSayi2;
begin

  if(AgYuklendi) then
  begin

    FillByte(_Bellek, $1000, 0);

    // að kartýna (ethernet) gelen ham bilgiyi al
    { TODO : VeriAl iþlevi katý (hard code) olarak kodlanmýþtýr. yapýsallaþtýrýlacak }
    VeriAl(@_Bellek, _VeriUzunluk);
    if(_VeriUzunluk > 0) then
    begin

      Tasi2(@_Bellek[0], AHedefBellekAdresi, _VeriUzunluk);
      AlinanByte += _VeriUzunluk;
    end;

    Result := _VeriUzunluk;
  end else Result := 0;
end;

{==============================================================================
  að kartýna (ethernet) veri gönderir
 ==============================================================================}
procedure AgKartinaVeriGonder(AHedefMAC: TMACAdres; AProtokolTip: TProtokolTip;
  AVeri: Isaretci; AVeriUzunlugu: TSayi2);
var
  _EthernetPaket: PEthernetPaket;
  _VeriBellekAdresi: Isaretci;
  _IPPaket: PIPPaket;
begin

  if(AgYuklendi) then
  begin

    // veri paketi için bellekte yer ayýr
    _EthernetPaket := GGercekBellek.Ayir(AVeriUzunlugu + ETHERNET_BASLIKU);

    _EthernetPaket^.HedefMACAdres := AHedefMAC;
    _EthernetPaket^.KaynakMACAdres := GAgBilgisi.MACAdres;

    // paketin protokol tipi
    case AProtokolTip of
      ptIP  : _EthernetPaket^.PaketTipi := PROTOKOL_IP;
      ptTCP : _EthernetPaket^.PaketTipi := PROTOKOL_TCP;
      ptUDP : _EthernetPaket^.PaketTipi := PROTOKOL_UDP;
      ptARP : _EthernetPaket^.PaketTipi := ntohs(PROTOKOL_ARP);
      ptICMP: _EthernetPaket^.PaketTipi := PROTOKOL_ICMP;
    end;

    _IPPaket := _EthernetPaket^.Veri;

    {SISTEM_MESAJ(RENK_MOR, 'ETH', []);
    SISTEM_MESAJ_MAC(RENK_LACIVERT, 'ETH: Kaynak MAC: ', _EthernetPaket^.KaynakMACAdres);
    SISTEM_MESAJ_MAC(RENK_LACIVERT, 'ETH: Hedef MAC: ', _EthernetPaket^.HedefMACAdres);
    SISTEM_MESAJ_S16(RENK_LACIVERT, 'ETH: PaketTip: ', _EthernetPaket^.PaketTipi, 4);}

    _VeriBellekAdresi := @_EthernetPaket^.Veri;
    Tasi2(AVeri, _VeriBellekAdresi, AVeriUzunlugu);

    VeriGonder(_EthernetPaket, AVeriUzunlugu + ETHERNET_BASLIKU);

    GonderilenByte += AVeriUzunlugu + ETHERNET_BASLIKU;

    // ayrýlan belleði serbest býrak
    GGercekBellek.YokEt(_EthernetPaket, AVeriUzunlugu + ETHERNET_BASLIKU);
  end;
end;

end.
