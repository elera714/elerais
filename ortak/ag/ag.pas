{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: ag.pas
  Dosya ��levi: a� (network) y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 10/05/2025

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
uses paylasim, aygityonetimi, baglanti;

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

uses src_pcnet32, arp, udp, dns, icmp, ip, sistemmesaj, donusum, islevler, genel,
  dhcp, dhcp_s, gorev, gercekbellek;

{==============================================================================
  a� ilk de�er y�klemelerini ger�ekle�tirir
 ==============================================================================}
procedure Yukle;
var
  Baglanti: PBaglantilar;
begin

  // sistemin �al��t��� bilgisayar�n alan ad� - (domain name)
  {$IFDEF SISTEM_SUNUCU}
  GTamBilgisayarAdi := GBilgisayarAdi + '.' + GAlanAdi;
  IPAdresiniOtomatikAl := False;
  {$ELSE}
  GTamBilgisayarAdi := GBilgisayarAdi;
  { TOOD - True oldu�unda a� ba�lant�s� yoksa hata veriyor }
  IPAdresiniOtomatikAl := True;
  {$ENDIF}

  // a� bilgileri �nde�erlerle y�kleniyor
  IlkAdresDegerleriniYukle;

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ Ethernet ayg�tlar� y�kleniyor...', []);
  AgAygitlariniYukle;

  // en az 1 a� ayg�t� y�klendi ise
  if(AgYuklendi) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ Ba�lant� yap�lar� ilk de�erlerle y�kleniyor...', []);
    Baglantilar0.Yukle;

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ ARP protokol� y�kleniyor...', []);
    ARPKayitlar0.Yukle;

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ DNS protokol� y�kleniyor...', []);
    dns.Yukle;

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ DHCP protokol� y�kleniyor...', []);
    DHCPSunucu0.Yukle;

    // sistem i�in ip adresini yap�land�r
    if(GAgBilgisi.IPAdresiAlindi = False) then
    begin

      if(GAgBilgisi.OtomatikIP) then

        DHCPIpAdresiAl
      else
      begin

        GAgBilgisi.IP4Adres := OnDegerIPAdresi;
        GAgBilgisi.AltAgMaskesi := OnDegerAltAgMaskesi;
        GAgBilgisi.AgGecitAdresi := IPAdres0;
        GAgBilgisi.DHCPSunucusu := IPAdres0;
        GAgBilgisi.DNSSunucusu := OnDegerIPAdresi;
        GAgBilgisi.IPKiraSuresi := 0;
        GAgBilgisi.IPAdresiAlindi := True;
      end;
    end;
  end;

  AlinanByte := 0;
  GonderilenByte := 0;
end;

{==============================================================================
  a� ileti�im alanlar�n� ilk de�erlerle y�kler
 ==============================================================================}
procedure IlkAdresDegerleriniYukle;
begin

  GAgBilgisi.OtomatikIP := IPAdresiniOtomatikAl;
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

    AgBilgisi := Isaretci(PSayi4(ADegiskenler + 00)^ + FAktifGorevBellekAdresi);
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

      {SISTEM_MESAJ_MAC(mtBilgi, RENK_MAVI, 'EthernetPaket^.KaynakMACAdres: ', EthernetPaket^.KaynakMACAdres);
      SISTEM_MESAJ_MAC(mtBilgi, RENK_MAVI, 'EthernetPaket^.HedefMACAdres: ', EthernetPaket^.HedefMACAdres);
      SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'EthernetPaket^.PaketTipi: %.4x', [EthernetPaket^.PaketTipi]);}

      // ******* protokollerin i�lenmesi *******

      // ARP protokol�
      if(Protokol = PROTOKOL_ARP) then
      begin

        ARPPaket := @EthernetPaket^.Veri;
        if(IPKarsilastir(ARPPaket^.HedefIPAdres, GAgBilgisi.IP4Adres)) then
          ARPKayitlar0.ARPPaketleriniIsle(EthernetPaket)
      end

      // IP protokol�
      else if(Protokol = PROTOKOL_IP) then

        IPPaketleriniIsle(@EthernetPaket^.Veri, i - ETHERNET_BASLIKU)
      else
      begin

        // bilinmeyen protokol
        SISTEM_MESAJ(mtUyari, RENK_MAVI, 'AG.PAS: bilinmeyen protokol: $%.4x', [Protokol]);
        SISTEM_MESAJ_MAC(mtUyari, RENK_SIYAH, '  -> Kaynak MAC Adresi: ', EthernetPaket^.KaynakMACAdres);
        SISTEM_MESAJ_MAC(mtUyari, RENK_SIYAH, '  -> Hedef MAC Adresi: ', EthernetPaket^.HedefMACAdres);
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
    EthernetPaket := GercekBellek0.Ayir(AVeriUzunlugu + ETHERNET_BASLIKU);

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
    GercekBellek0.YokEt(EthernetPaket, AVeriUzunlugu + ETHERNET_BASLIKU);
  end;
end;

end.
