{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: arp.pas
  Dosya ��levi: ARP protokol y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 01/07/2025

 ==============================================================================}
{$mode objfpc}
unit arp;
 
interface

uses paylasim;

type
  PARPPaket = ^TARPPaket;
  TARPPaket = packed record
    DonanimTip: TSayi2;           // donan�m tipi
    ProtokolTip: TSayi2;          // protokol tipi
    DonanimAdresU: TSayi1;        // donan�m adres uzunlu�u
    ProtokolAdresU: TSayi1;       // protokol adres uzunlu�u
    Islem: TSayi2;                // i�lem
    GonderenMACAdres: TMACAdres;  // paketi g�nderen donan�m adresi
    GonderenIPAdres: TIPAdres;    // paketi g�nderen ip adresi
    HedefMACAdres: TMACAdres;     // paketin g�nderildi�i donan�m adresi
    HedefIPAdres: TIPAdres;       // paketin g�nderildi�i ip adresi
  end;

const
  // dikkat: de�erler network byte s�ral�d�r
  ARPISLEM_ISTEK = TSayi2($0001);
  ARPISLEM_YANIT = TSayi2($0002);

const
  USTLIMIT_KAYITSAYISI    = 32;
  ARPDONANIMTIP_ETHERNET  = TSayi2($0001);        // network byte s�ral�
  ARPPROTOKOLTIP_IPV4     = TSayi2($0800);        // network byte s�ral�

type
  PARPKayit = ^TARPKayit;
  TARPKayit = packed record
    IPAdres: TIPAdres;
    MACAdres: TMACAdres;
    YasamSuresi: TISayi2;
  end;

type
  TARPIslem = (arpIstek, arpYanit);

procedure Yukle;
function ArpCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
procedure ARPPaketleriniIsle(AEthernetPaket: PEthernetPaket);
procedure ARPIstegiGonder(AARPIslem: TARPIslem; AHedefMACAdres: PMACAdres;
  AHedefIPAdres: PIPAdres);
procedure ARPTablosunuGuncelle;
function ARPKaydiAl(AARPSiraNo: TISayi4; AHedefBellek: PARPKayit): TISayi4;
procedure ARPKaydiEkle(AARPKayit: TARPKayit);
function MACAdresiAl(AIPAdres: TIPAdres): TMACAdres;

implementation

uses genel, ag, islevler, zamanlayici, sistemmesaj, donusum, gorev;

var
  ARPTabloKilit: TSayi4 = 0;
  ARPKayitSayisi: TISayi4;
  ARPKayitListesi: array[0..USTLIMIT_KAYITSAYISI - 1] of PARPKayit;

{==============================================================================
  ARP protokol�n� ilk de�erlerle y�kler
 ==============================================================================}
procedure Yukle;
var
  ARPKayitBellekAdresi,
  Bellek: Isaretci;
  i: TISayi4;
begin

  // ARP giri�leri i�in bellekte yer tahsis et
  ARPKayitBellekAdresi := GetMem(USTLIMIT_KAYITSAYISI * SizeOf(TARPKayit));

  // giri�lere ait i�aret�ileri bellek b�lgeleriyle e�le�tir
  Bellek := ARPKayitBellekAdresi;

  for i := 0 to USTLIMIT_KAYITSAYISI - 1 do
  begin

    ARPKayitListesi[i] := Bellek;
    ARPKayitListesi[i]^.YasamSuresi := -1;       // -1 = girdi yok

    Bellek += SizeOf(TARPKayit);
  end;

  // ARP kay�t say�s�n� s�f�rla
  ARPKayitSayisi := 0;
end;

{==============================================================================
  ARP kesme �a�r�lar�n� y�netir
 ==============================================================================}
function ArpCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  ARPKayit: PARPKayit;
  IslevNo: TSayi4;
  GirdiSiraNo: TISayi4;
begin

  // i�lev no
  IslevNo := (AIslevNo and $FF);

  // toplam ARP girdi say�s�n� ver
  if(IslevNo = 1) then
  begin

    Result := ARPKayitSayisi;
  end

  // ARP girdi i�eri�ini ver
  else if(IslevNo = 2) then
  begin

    GirdiSiraNo := PISayi4(ADegiskenler + 00)^;
    if(GirdiSiraNo >= 0) and (GirdiSiraNo < ARPKayitSayisi) then
    begin

      ARPKayit := PARPKayit(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
      Result := ARPKaydiAl(GirdiSiraNo, ARPKayit);

    end else Result := HATA_DEGERARALIKDISI;
  end

  else Result := HATA_ISLEV;
end;

{==============================================================================
  a� ayg�t�ndan gelen mesajlar� i�ler
 ==============================================================================}
procedure ARPPaketleriniIsle(AEthernetPaket: PEthernetPaket);
var
  EthernetPaket: PEthernetPaket;
  ARPPaket: PARPPaket;
  ARPKayit: TARPKayit;
begin

  EthernetPaket := AEthernetPaket;
  ARPPaket := @EthernetPaket^.Veri;

  ARPKayit.IPAdres := ARPPaket^.GonderenIPAdres;
  ARPKayit.MACAdres := ARPPaket^.GonderenMACAdres;
  ARPKayit.YasamSuresi := 60 * 60;    // 60 dakika ya�am �mr�

  // ARP paketi ip adresime g�nderilmi� ise
  if(IPAdresleriniKarsilastir(ARPPaket^.HedefIPAdres, GAgBilgisi.IP4Adres)) then
  begin

    // 1. g�nderilen paket benim mesaj�ma yan�t ise, tabloya ekle
    if(htons(ARPPaket^.Islem) = ARPISLEM_YANIT) then

      ARPKaydiEkle(ARPKayit)

    // 2. g�nderilen mesaj yan�t istiyorsa;
    // 2.1 talep eden makinenin bilgilerini listeye ekle
    // 2.2 makineye ARP yan�t mesaj�n� mesaj�n� g�nder
    else if(htons(ARPPaket^.Islem) = ARPISLEM_ISTEK) then
    begin

      ARPKaydiEkle(ARPKayit);
      ARPIstegiGonder(arpYanit, @ARPPaket^.GonderenMACAdres, @ARPPaket^.GonderenIPAdres);
    end;
  end;
end;

{==============================================================================
  ARP iste�i g�nderir
 ==============================================================================}
procedure ARPIstegiGonder(AARPIslem: TARPIslem; AHedefMACAdres: PMACAdres;
  AHedefIPAdres: PIPAdres);
var
  ARPPaket: TARPPaket;
begin

  ARPPaket.DonanimTip := ntohs(ARPDONANIMTIP_ETHERNET);
  ARPPaket.ProtokolTip := ntohs(ARPPROTOKOLTIP_IPV4);
  ARPPaket.DonanimAdresU := 6;
  ARPPaket.ProtokolAdresU := 4;
  if(AARPIslem = arpIstek) then
    ARPPaket.Islem := ntohs(ARPISLEM_ISTEK)
  else ARPPaket.Islem := ntohs(ARPISLEM_YANIT);
  ARPPaket.GonderenMACAdres := GAgBilgisi.MACAdres;
  ARPPaket.GonderenIPAdres := GAgBilgisi.IP4Adres;

  if(AARPIslem = arpIstek) then
    ARPPaket.HedefMACAdres := MACAdres0
  else if(AARPIslem = arpYanit) then
    ARPPaket.HedefMACAdres := AHedefMACAdres^;

  ARPPaket.HedefIPAdres := AHedefIPAdres^;

  if(AARPIslem = arpIstek) then
    AgKartinaVeriGonder(MACAdres255, ptARP, @ARPPaket, 28)
  else AgKartinaVeriGonder(AHedefMACAdres^, ptARP, @ARPPaket, 28);
end;

{==============================================================================
  ARP tablosunu her 1 saniyede bir g�nceller
  bilgi: i�lev, �ekirde�e ba�l� ayr� bir g�rev olarak �al��maktad�r
 ==============================================================================}
procedure ARPTablosunuGuncelle;
var
  YasamSuresi,
  i: TISayi4;
begin

  while True do
  begin

    BekleMS(100);

    while KritikBolgeyeGir(ARPTabloKilit) = False do;

    for i := 0 to USTLIMIT_KAYITSAYISI - 1 do
    begin

      if(ARPKayitListesi[i]^.YasamSuresi > 0) then
      begin

        YasamSuresi := ARPKayitListesi[i]^.YasamSuresi;
        Dec(YasamSuresi);
        ARPKayitListesi[i]^.YasamSuresi := YasamSuresi;

        // ya�am s�resi 0 oldu�unda girdi -1 yap�larak ba�ka kay�tlar�n eklenmesi sa�lan�yor
        if(YasamSuresi = 0) then
        begin

          ARPKayitListesi[i]^.YasamSuresi := -1;
          Dec(ARPKayitSayisi);      // girdi say�s�n� azalt
        end;
      end;
    end;

    KritikBolgedenCik(ARPTabloKilit);
  end;
end;

{==============================================================================
  ARP tablosuna ARP girdisi ekler
 ==============================================================================}
procedure ARPKaydiEkle(AARPKayit: TARPKayit);
var
  i: TISayi4;
begin

  while KritikBolgeyeGir(ARPTabloKilit) = False do;

  {SISTEM_MESAJ(RENK_MOR, 'Eklenecek ARP Kay�t Bilgileri:', []);
  SISTEM_MESAJ_IP(RENK_LACIVERT, 'ARP - IP: ', AARPKayit.IPAdres);
  SISTEM_MESAJ_MAC(RENK_LACIVERT, 'ARP - MAC: ', AARPKayit.MACAdres);
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'ARP - Ya�.S�re: ', AARPKayit.YasamSuresi, 4);}

  // yan�t� g�nderen bilgisayar�n ip adresi listede var m� ?
  for i := 0 to USTLIMIT_KAYITSAYISI - 1 do
  begin

    // varsa g�ncelle ve ��k
    if(IPAdresleriniKarsilastir(ARPKayitListesi[i]^.IPAdres, AARPKayit.IPAdres)) then
    begin

      ARPKayitListesi[i]^.MACAdres := AARPKayit.MACAdres;
      ARPKayitListesi[i]^.YasamSuresi := AARPKayit.YasamSuresi;
      Exit;
    end;
  end;

  // ARP girdisi bulunamad�ysa girdiyi tabloya ekle

  if(ARPKayitSayisi >= USTLIMIT_KAYITSAYISI) then
  begin

    KritikBolgedenCik(ARPTabloKilit);
    Exit;
  end;

  // bo� ARP giri�i ara
  for i := 0 to USTLIMIT_KAYITSAYISI - 1 do
  begin

    // YasamSuresi = -1 = bo� demektir
    if(ARPKayitListesi[i]^.YasamSuresi = -1) then
    begin

      ARPKayitListesi[i]^.IPAdres := AARPKayit.IPAdres;
      ARPKayitListesi[i]^.MACAdres := AARPKayit.MACAdres;
      ARPKayitListesi[i]^.YasamSuresi := AARPKayit.YasamSuresi;
      Inc(ARPKayitSayisi);

      KritikBolgedenCik(ARPTabloKilit);
      Exit;
    end;
  end;
end;

{==============================================================================
  arp tablosundan ip adresinin kar��l��� olam mac adresini al�r
 ==============================================================================}
function MACAdresiAl(AIPAdres: TIPAdres): TMACAdres;
var
  i, j: TISayi4;
begin

  // arp tabolsunda ip kar��l��� olan mac adresleri var ise kontrol et
  if(ARPKayitSayisi > 0) then
  begin

    for i := 0 to USTLIMIT_KAYITSAYISI - 1 do
    begin

      // ARP girdisi mevcut ise ( > -1)
      if(ARPKayitListesi[i]^.YasamSuresi > -1) then
        if(IPAdresleriniKarsilastir(ARPKayitListesi[i]^.IPAdres, AIPAdres)) then
          Exit(ARPKayitListesi[i]^.MACAdres);
    end;
  end;

  // istenen ip adresinin amc adresini sorgula
  for i := 1 to 10 do
  begin

    // ip adresinin mac adresi tabloda bulunamad��� i�in istek g�nder
    ARPIstegiGonder(arpIstek, @MACAdres0, @AIPAdres);

    // 0.5 saniye bekle
    BekleMS(50);

    // yeniden tabloyu kontrol et
    if(ARPKayitSayisi > 0) then
    begin

      for j := 0 to USTLIMIT_KAYITSAYISI - 1 do
      begin

        // ARP girdisi mevcut ise ( > -1)
        if(ARPKayitListesi[j]^.YasamSuresi > -1) then
          if(IPAdresleriniKarsilastir(ARPKayitListesi[j]^.IPAdres, AIPAdres)) then
            Exit(ARPKayitListesi[j]^.MACAdres);
      end;
    end;
  end;

  Result := MACAdres0;
end;

{==============================================================================
  istenen s�radaki ARP girdisini geri d�nd�r�r
 ==============================================================================}
function ARPKaydiAl(AARPSiraNo: TISayi4; AHedefBellek: PARPKayit): TISayi4;
var
  SiraNo, i: TISayi4;
begin

  while KritikBolgeyeGir(ARPTabloKilit) = False do;

  // ARP tablosunda silinen kay�tlar da olaca��ndan dolay� SiraNo de�i�keni
  // ger�ek s�ra no'ya sahip kayd� almak i�in tan�mlanm� ve kullan�lm��t�r

  if(AARPSiraNo >= 0) and (AARPSiraNo < ARPKayitSayisi) then
  begin

    SiraNo := -1;

    for i := 0 to USTLIMIT_KAYITSAYISI - 1 do
    begin

      // ARP girdisi mevcut ise ( > -1)
      if(ARPKayitListesi[i]^.YasamSuresi > -1) then Inc(SiraNo);

      if(SiraNo = AARPSiraNo) then
      begin

        AHedefBellek^.IPAdres := ARPKayitListesi[i]^.IPAdres;
        AHedefBellek^.MACAdres := ARPKayitListesi[i]^.MACAdres;
        AHedefBellek^.YasamSuresi := ARPKayitListesi[i]^.YasamSuresi;
        Result := HATA_YOK;

        KritikBolgedenCik(ARPTabloKilit);
        Exit;
      end;
    end;

    Result := HATA_DEGERARALIKDISI;

  end else Result := HATA_DEGERARALIKDISI;

  KritikBolgedenCik(ARPTabloKilit);
end;

end.
