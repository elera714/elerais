{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: ag.pas
  Dosya ��levi: a� (network) y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 27/12/2024

 ==============================================================================}
{$mode objfpc}
unit ag;

interface
{==============================================================================
  big endian > little endian �evrimi

  Bellek Yerle�imleri: (�rnek Say�: $12345678)
    Big Endian:   78 56 34 12
    Litle Endian: 12 34 56 78
 ==============================================================================}
uses paylasim, aygityonetimi, iletisim, genel;

const
  ETHERNET_BASLIKU = TSayi1(14);

var
  // paket ba�l�klar� da dahil olmak �zere t�m veri toplamlar�n� i�erir.
  AlinanByte, GonderilenByte: TSayi4;

procedure Yukle;
procedure IlkAdresDegerleriniYukle;
function GenelAgCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
procedure AgKartiVeriAlmaIslevi;
function AgKartindanVeriAl(AHedefBellekAdresi: Isaretci): Integer;
procedure AgKartinaVeriGonder(AHedefMAC: TMACAdres; AProtokolTipi: TProtokolTipi;
  AVeri: Isaretci; AVeriUzunlugu: TSayi2);

implementation

uses src_pcnet32, arp, udp, dns, icmp, ip, sistemmesaj, donusum;

{==============================================================================
  a� ilk de�er y�klemelerini ger�ekle�tirir
 ==============================================================================}
procedure Yukle;
begin

  // a� bilgileri �nde�erlerle y�kleniyor
  IlkAdresDegerleriniYukle;

  SISTEM_MESAJ(RENK_LACIVERT, '+ Ethernet ayg�tlar� y�kleniyor...', []);
  AgAygitlariniYukle;

  // en az 1 a� ayg�t� y�klendi ise
  if(AgYuklendi) then
  begin

    SISTEM_MESAJ(RENK_LACIVERT, '+ Ba�lant� yap�lar� ilk de�erlerle y�kleniyor...', []);
    iletisim.Yukle;

    SISTEM_MESAJ(RENK_LACIVERT, '+ ARP protokol� y�kleniyor...', []);
    arp.Yukle;

    SISTEM_MESAJ(RENK_LACIVERT, '+ DNS protokol� y�kleniyor...', []);
    dns.Yukle;
  end;

  AlinanByte := 0;
  GonderilenByte := 0;
end;

{==============================================================================
  a� ileti�im alanlar�n� ilk de�erlerle y�kler
 ==============================================================================}
procedure IlkAdresDegerleriniYukle;
begin

  GAgBilgisi.MACAdres := MACAdres0;
  GAgBilgisi.IP4Adres := IPAdres0;
  GAgBilgisi.AltAgMaskesi := IPAdres0;
  GAgBilgisi.AgGecitAdresi := IPAdres0;
  GAgBilgisi.DHCPSunucusu := IPAdres0;
  GAgBilgisi.DNSSunucusu := IPAdres0;
  GAgBilgisi.IPKiraSuresi := 0;
  GAgBilgisi.IPAdresiAlindi := False;
end;

{==============================================================================
  a� kesme �a�r�lar�n� y�netir
 ==============================================================================}
function GenelAgCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  IslevNo: TSayi4;
  AgBilgisi: PAgBilgisi;
begin

  // i�lev no
  IslevNo := (AIslevNo and $FF);

  // a� ayarlar�n� geri d�nd�r
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

  end else Result := HATA_ISLEV;
end;

{==============================================================================
  a� kart�na (ethernet) gelen verilerin protokollere y�nlendirilme i�levi
  bilgi: bu i�lev i�letim sistemi d�ng�s� i�inde s�rekli �a�r�l�r
 ==============================================================================}
procedure AgKartiVeriAlmaIslevi;
var
  EthernetPaket: PEthernetPaket;
  ARPPaket: PARPPaket;
  Bellek: array[0..$FFF] of TSayi1;
  i, Protokol: TSayi2;
begin

  // a� y�klendi ise ...
  if(AgYuklendi) then
  begin

    // a� kart�na gelen ham bilgiyi al
    i := AgKartindanVeriAl(@Bellek);
    if(i > 0) then
    begin

      EthernetPaket := @Bellek[0];

      Protokol := htons(EthernetPaket^.PaketTipi);

      //SISTEM_MESAJ2_S16(RENK_YESIL, 'Protokol: $', Protokol, 4);

      // ******* protokollerin i�lenmesi *******

      // ARP protokol�
      if(Protokol = PROTOKOL_ARP) then
      begin

        ARPPaket := @EthernetPaket^.Veri;
        if(IPKarsilastir(ARPPaket^.HedefIPAdres, GAgBilgisi.IP4Adres)) then
          ARPPaketleriniIsle(EthernetPaket)
      end

      // IP protokol�
      else if(Protokol = PROTOKOL_IP) then

        IPPaketleriniIsle(@EthernetPaket^.Veri, i - ETHERNET_BASLIKU)
      else
      begin

        // bilinmeyen protokol
        SISTEM_MESAJ_S16(RENK_KIRMIZI, 'AG.PAS: bilinmeyen protokol: ', Protokol, 4);
        SISTEM_MESAJ_MAC(RENK_MOR, '  -> Kaynak MAC Adresi: ', EthernetPaket^.KaynakMACAdres);
        SISTEM_MESAJ_MAC(RENK_MOR, '  -> Hedef MAC Adresi: ', EthernetPaket^.HedefMACAdres);
      end;
    end;
  end;
end;

{==============================================================================
  a� kart�na (ethernet) gelen verileri al�r
 ==============================================================================}
function AgKartindanVeriAl(AHedefBellekAdresi: Isaretci): TISayi4;
var
  Bellek: array[0..$FFF] of TSayi1;
  i: TSayi2;
begin

  // a� kart�na (ethernet) gelen ham bilgiyi al
  { TODO : VeriAl i�levi kat� (hard code) olarak kodlanm��t�r. yap�salla�t�r�lacak }
  VeriAl(@Bellek, i);
  if(i > 0) then
  begin

    Tasi2(@Bellek[0], AHedefBellekAdresi, i);
    AlinanByte += i;
  end;

  Result := i;
end;

{==============================================================================
  a� kart�na (ethernet) veri g�nderir
 ==============================================================================}
procedure AgKartinaVeriGonder(AHedefMAC: TMACAdres; AProtokolTipi: TProtokolTipi;
  AVeri: Isaretci; AVeriUzunlugu: TSayi2);
var
  EthernetPaket: PEthernetPaket;
  Bellek: Isaretci;
begin

  if(AgYuklendi) then
  begin

    // veri paketi i�in bellekte yer ay�r
    EthernetPaket := GGercekBellek.Ayir(AVeriUzunlugu + ETHERNET_BASLIKU);

    EthernetPaket^.HedefMACAdres := AHedefMAC;
    EthernetPaket^.KaynakMACAdres := GAgBilgisi.MACAdres;

    // paketin protokol tipi
    case AProtokolTipi of
      ptIP  : EthernetPaket^.PaketTipi := ntohs(PROTOKOL_IP);
      ptTCP : EthernetPaket^.PaketTipi := PROTOKOL_TCP;
      ptUDP : EthernetPaket^.PaketTipi := PROTOKOL_UDP;
      ptARP : EthernetPaket^.PaketTipi := ntohs(PROTOKOL_ARP);
      ptICMP: EthernetPaket^.PaketTipi := PROTOKOL_ICMP;
    end;
{
    SISTEM_MESAJ(RENK_MOR, 'ETH', []);
    SISTEM_MESAJ_MAC(RENK_LACIVERT, 'ETH: Kaynak MAC: ', EthernetPaket^.KaynakMACAdres);
    SISTEM_MESAJ_MAC(RENK_LACIVERT, 'ETH: Hedef MAC: ', EthernetPaket^.HedefMACAdres);
    SISTEM_MESAJ_S16(RENK_LACIVERT, 'ETH: PaketTip: ', EthernetPaket^.PaketTipi, 4);
}
    Bellek := @EthernetPaket^.Veri;
    Tasi2(AVeri, Bellek, AVeriUzunlugu);

    VeriGonder(EthernetPaket, AVeriUzunlugu + ETHERNET_BASLIKU);

    GonderilenByte += AVeriUzunlugu + ETHERNET_BASLIKU;

    // ayr�lan belle�i serbest b�rak
    GGercekBellek.YokEt(EthernetPaket, AVeriUzunlugu + ETHERNET_BASLIKU);
  end;
end;

end.
