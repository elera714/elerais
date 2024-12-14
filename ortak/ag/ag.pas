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
function GenelAgCagriIslevleri(IslevNo: TSayi4; Degiskenler: Isaretci): TISayi4;
procedure AgKartiVeriAlmaIslevi;
function AgKartindanVeriAl(AHedefBellekAdresi: Isaretci): Integer;
procedure AgKartinaVeriGonder(AHedefMAC: TMACAdres; AProtokolTip: TProtokolTip;
  AVeri: Isaretci; AVeriUzunlugu: TSayi2);

implementation

uses src_pcnet32, arp, udp, dns, icmp, ip, sistemmesaj;

{==============================================================================
  að ilk deðer yüklemelerini gerçekleþtirir
 ==============================================================================}
procedure Yukle;
begin

  // að bilgileri öndeðerlerle yükleniyor
  AgBilgisi.MACAdres := MACAdres0;
  AgBilgisi.IP4Adres := IPAdres0;
  AgBilgisi.AltAgMaskesi := IPAdres0;
  AgBilgisi.AgGecitAdresi := IPAdres0;
  AgBilgisi.DHCPSunucusu := IPAdres0;
  AgBilgisi.DNSSunucusu := IPAdres0;
  AgBilgisi.IPKiraSuresi := 0;

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
  að kesme çaðrýlarýný yönetir
 ==============================================================================}
function GenelAgCagriIslevleri(IslevNo: TSayi4; Degiskenler: Isaretci): TISayi4;
var
  _Islev: TSayi4;
  _AgBilgisi: PAgBilgisi;
begin

  // iþlev no
  _Islev := (IslevNo and $FF);

  // að ayarlarýný geri döndür
  if(_Islev = 1) then
  begin

    _AgBilgisi := Isaretci(PSayi4(Degiskenler + 00)^ + CalisanGorevBellekAdresi);
    _AgBilgisi^.MACAdres := AgBilgisi.MACAdres;
    _AgBilgisi^.IP4Adres := AgBilgisi.IP4Adres;
    _AgBilgisi^.AltAgMaskesi := AgBilgisi.AltAgMaskesi;
    _AgBilgisi^.AgGecitAdresi := AgBilgisi.AgGecitAdresi;
    _AgBilgisi^.DHCPSunucusu := AgBilgisi.DHCPSunucusu;
    _AgBilgisi^.DNSSunucusu := AgBilgisi.DNSSunucusu;
    _AgBilgisi^.IPKiraSuresi := AgBilgisi.IPKiraSuresi;

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
begin

  // að yüklendi ise ...
  if(AgYuklendi) then
  begin

    // að kartýna gelen ham bilgiyi al
    _VeriUzunluk := AgKartindanVeriAl(@_Bellek);
    if(_VeriUzunluk > 0) then
    begin

      _EthernetPaket := @_Bellek[0];

      _Protokol := _EthernetPaket^.PaketTip;
      //MSG_SH('Protokol: ', _Protokol, 4);

      // ******* protokollerin iþlenmesi *******

      // ARP protokolü
      if(_Protokol = PROTOKOL_ARP) then

        ARPPaketleriniIsle(_EthernetPaket)

      // IP protokolü
      else if(_Protokol = PROTOKOL_IP) then

        IPPaketleriniIsle(@_EthernetPaket^.Veri, _VeriUzunluk - ETHERNET_BASLIKU)
      else

      // bilinmeyen protokol
      begin

        SISTEM_MESAJ_S16(RENK_KIRMIZI, 'AG.PP: Bilinmeyen Protokol: ', _Protokol, 4);
      end;
    end;
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

    // að kartýna (ethernet) gelen ham bilgiyi al
    { TODO : VeriAl iþlevi katý (hard code) olarak kodlanmýþtýr. yapýsallaþtýrýlacak }
    VeriAl(@_Bellek, _VeriUzunluk);
    if(_VeriUzunluk > 0) then
    begin

      Tasi2(@_Bellek[0], AHedefBellekAdresi, _VeriUzunluk);
      AlinanByte += _VeriUzunluk;
    end;
  end;

  Result := _VeriUzunluk;
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
    _EthernetPaket^.KaynakMACAdres := AgBilgisi.MACAdres;

    // paketin protokol tipi
    case AProtokolTip of
      ptIP  : _EthernetPaket^.PaketTip := PROTOKOL_IP;
      ptTCP : _EthernetPaket^.PaketTip := PROTOKOL_TCP;
      ptUDP : _EthernetPaket^.PaketTip := PROTOKOL_UDP;
      ptARP : _EthernetPaket^.PaketTip := PROTOKOL_ARP;
      ptICMP: _EthernetPaket^.PaketTip := PROTOKOL_ICMP;
    end;

    _IPPaket := _EthernetPaket^.Veri;

    {SISTEM_MESAJ(RENK_MOR, 'ETH', []);
    SISTEM_MESAJ_MAC(RENK_LACIVERT, 'ETH: Kaynak MAC: ', _EthernetPaket^.KaynakMACAdres);
    SISTEM_MESAJ_MAC(RENK_LACIVERT, 'ETH: Hedef MAC: ', _EthernetPaket^.HedefMACAdres);
    SISTEM_MESAJ_S16(RENK_LACIVERT, 'ETH: PaketTip: ', _EthernetPaket^.PaketTip, 4);}

    _VeriBellekAdresi := @_EthernetPaket^.Veri;
    Tasi2(AVeri, _VeriBellekAdresi, AVeriUzunlugu);

    VeriGonder(_EthernetPaket, AVeriUzunlugu + ETHERNET_BASLIKU);

    GonderilenByte += AVeriUzunlugu + ETHERNET_BASLIKU;

    // ayrýlan belleði serbest býrak
    GGercekBellek.YokEt(_EthernetPaket, AVeriUzunlugu + ETHERNET_BASLIKU);
  end;
end;

end.
