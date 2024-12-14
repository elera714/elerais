{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: arp.pas
  Dosya ��levi: ARP protokol y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 16/09/2024

 ==============================================================================}
{$mode objfpc}
unit arp;
 
interface

uses paylasim;

const
  ARPISLEM_ISTEK = $0100;
  ARPISLEM_YANIT = $0200;

const
  USTLIMIT_KAYITSAYISI    = 10;
  ARPDONANIMTIP_ETHERNET  = $0100;    // $0100 (ters s�rada)
  ARPPROTOKOLTIP_IPV4     = $0008;    // $0800 (ters s�rada)

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
function ArpCagriIslevleri(IslevNo: TSayi4; Degiskenler: Isaretci): TISayi4;
procedure ARPPaketleriniIsle(AEthernetPaket: PEthernetPaket);
procedure ARPIstegiGonder(AARPIslem: TARPIslem; AHedefMACAdres: PMACAdres;
  AHedefIPAdres: PIPAdres);
procedure ARPTablosunuGuncelle;
function ARPKaydiAl(AARPSiraNo: TISayi4; AHedefBellek: PARPKayit): TISayi4;
procedure ARPKaydiEkle(AARPKayit: TARPKayit);
function MACAdresiAl(AIPAdres: TIPAdres): TMACAdres;

implementation

uses genel, ag, islevler, zamanlayici, sistemmesaj;

var
  ARPKayitSayisi: TISayi4;
  ARPKayitBellekAdresi: Isaretci;
  ARPKayitListesi: array[1..USTLIMIT_KAYITSAYISI] of PARPKayit;

{==============================================================================
  ARP protokol�n� ilk de�erlerle y�kler
 ==============================================================================}
procedure Yukle;
var
  _ARPKayitBellekAdresi: Isaretci;
  i: TISayi4;
begin

  // ARP giri�leri i�in bellekte yer tahsis et
  ARPKayitBellekAdresi := GGercekBellek.Ayir(USTLIMIT_KAYITSAYISI * SizeOf(TARPKayit));

  // giri�lere ait i�aret�ileri bellek b�lgeleriyle e�le�tir
  _ARPKayitBellekAdresi := ARPKayitBellekAdresi;

  for i := 1 to USTLIMIT_KAYITSAYISI do
  begin

    ARPKayitListesi[i] := _ARPKayitBellekAdresi;
    ARPKayitListesi[i]^.YasamSuresi := -1;       // -1 = girdi yok

    _ARPKayitBellekAdresi += SizeOf(TARPKayit);
  end;

  // ARP kay�t say�s�n� s�f�rla
  ARPKayitSayisi := 0;
end;

{==============================================================================
  ARP kesme �a�r�lar�n� y�netir
 ==============================================================================}
function ArpCagriIslevleri(IslevNo: TSayi4; Degiskenler: Isaretci): TISayi4;
var
  _ARPKayit: PARPKayit;
  _Islev: TSayi4;
  _GirdiSiraNo: TISayi4;
begin

  // i�lev no
  _Islev := (IslevNo and $FF);

  // toplam ARP girdi say�s�n� ver
  if(_Islev = 1) then
  begin

    Result := ARPKayitSayisi;
  end

  // ARP girdi i�eri�ini ver
  else if(_Islev = 2) then
  begin

    _GirdiSiraNo := PISayi4(Degiskenler + 00)^;
    if(_GirdiSiraNo >= 0) and (_GirdiSiraNo < ARPKayitSayisi) then
    begin

      _ARPKayit := PARPKayit(PSayi4(Degiskenler + 04)^ + CalisanGorevBellekAdresi);
      Result := ARPKaydiAl(_GirdiSiraNo, _ARPKayit);

    end else Result := HATA_DEGERARALIKDISI;
  end

  else Result := HATA_ISLEV;
end;

{==============================================================================
  a� ayg�t�ndan gelen mesajlar� i�ler
 ==============================================================================}
procedure ARPPaketleriniIsle(AEthernetPaket: PEthernetPaket);
var
  _EthernetPaket: PEthernetPaket;
  _ARPPaket: PARPPaket;
  _ARPKayit: TARPKayit;
begin

  _EthernetPaket := AEthernetPaket;
  _ARPPaket := @_EthernetPaket^.Veri;

  _ARPKayit.IPAdres := _ARPPaket^.GonderenIPAdres;
  _ARPKayit.MACAdres := _ARPPaket^.GonderenMACAdres;
  _ARPKayit.YasamSuresi := 60 * 60;    // 60 dakika ya�am �mr�

  // ARP paketi ip adresime g�nderilmi� ise
  if(IPAdresleriniKarsilastir(_ARPPaket^.HedefIPAdres, AgBilgisi.IP4Adres)) then
  begin

    // 1. g�nderilen paket benim mesaj�ma yan�t ise, tabloya ekle
    if(_ARPPaket^.Islem = ARPISLEM_YANIT) then

      ARPKaydiEkle(_ARPKayit)

    // 2. g�nderilen mesaj yan�t istiyorsa;
    // 2.1 talep eden makinenin bilgilerini listeye ekle
    // 2.2 makineye ARP yan�t mesaj�n� mesaj�n� g�nder
    else if(_ARPPaket^.Islem = ARPISLEM_ISTEK) then
    begin

      ARPKaydiEkle(_ARPKayit);
      ARPIstegiGonder(arpYanit, @_ARPPaket^.GonderenMACAdres, @_ARPPaket^.GonderenIPAdres);
    end;
  end;
end;

{==============================================================================
  ARP iste�i g�nderir
 ==============================================================================}
procedure ARPIstegiGonder(AARPIslem: TARPIslem; AHedefMACAdres: PMACAdres;
  AHedefIPAdres: PIPAdres);
var
  _ARPPaket: TARPPaket;
begin

  _ARPPaket.DonanimTip := ARPDONANIMTIP_ETHERNET;
  _ARPPaket.ProtokolTip := ARPPROTOKOLTIP_IPV4;
  _ARPPaket.DonanimAdresU := 6;
  _ARPPaket.ProtokolAdresU := 4;
  if(AARPIslem = arpIstek) then
    _ARPPaket.Islem := ARPISLEM_ISTEK
  else _ARPPaket.Islem := ARPISLEM_YANIT;
  _ARPPaket.GonderenMACAdres := AgBilgisi.MACAdres;
  _ARPPaket.GonderenIPAdres := AgBilgisi.IP4Adres;

  if(AARPIslem = arpIstek) then
    _ARPPaket.HedefMACAdres := MACAdres0
  else if(AARPIslem = arpYanit) then
    _ARPPaket.HedefMACAdres := AHedefMACAdres^;

  _ARPPaket.HedefIPAdres := AHedefIPAdres^;

  if(AARPIslem = arpIstek) then
    AgKartinaVeriGonder(MACAdres255, ptARP, @_ARPPaket, 28)
  else AgKartinaVeriGonder(AHedefMACAdres^, ptARP, @_ARPPaket, 28)
end;

{==============================================================================
  ARP tablosunu g�nceller
 ==============================================================================}
procedure ARPTablosunuGuncelle;
var
  i, _YasamSuresi: TISayi4;
begin

  for i := 1 to USTLIMIT_KAYITSAYISI do
  begin

    if(ARPKayitListesi[i]^.YasamSuresi > 0) then
    begin

      _YasamSuresi := ARPKayitListesi[i]^.YasamSuresi;
      Dec(_YasamSuresi);
      ARPKayitListesi[i]^.YasamSuresi := _YasamSuresi;

      // ya�am s�resi 0 oldu�unda girdi -1 yap�larak ba�ka kay�tlar�n eklenmesi sa�lan�yor
      if(_YasamSuresi = 0) then
      begin

        ARPKayitListesi[i]^.YasamSuresi := -1;
        Dec(ARPKayitSayisi);      // girdi say�s�n� azalt
      end;
    end;
  end;
end;

{==============================================================================
  ARP tablosuna ARP girdisi ekler
 ==============================================================================}
procedure ARPKaydiEkle(AARPKayit: TARPKayit);
var
  i: TISayi4;
begin

  {SISTEM_MESAJ(RENK_MOR, 'Eklenecek ARP Kay�t Bilgileri:', []);
  SISTEM_MESAJ_IP(RENK_LACIVERT, 'ARP - IP: ', AARPKayit.IPAdres);
  SISTEM_MESAJ_MAC(RENK_LACIVERT, 'ARP - MAC: ', AARPKayit.MACAdres);
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'ARP - Ya�.S�re: ', AARPKayit.YasamSuresi, 4);}

  // yan�t� g�nderen bilgisayar�n ip adresi listede var m� ?
  for i := 1 to USTLIMIT_KAYITSAYISI do
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

  if(ARPKayitSayisi >= USTLIMIT_KAYITSAYISI) then Exit;

  // bo� ARP giri�i ara
  for i := 1 to USTLIMIT_KAYITSAYISI do
  begin

    // YasamSuresi = -1 = bo� demektir
    if(ARPKayitListesi[i]^.YasamSuresi = -1) then
    begin

      ARPKayitListesi[i]^.IPAdres := AARPKayit.IPAdres;
      ARPKayitListesi[i]^.MACAdres := AARPKayit.MACAdres;
      ARPKayitListesi[i]^.YasamSuresi := AARPKayit.YasamSuresi;
      Inc(ARPKayitSayisi);
      Exit;
    end;
  end;
end;

{==============================================================================
  arp tablosundan ip adresinin kar��l��� olam mac adresini al�r
 ==============================================================================}
function MACAdresiAl(AIPAdres: TIPAdres): TMACAdres;
var
  i: TSayi4;
begin

  // arp tabolsunda ip kar��l��� olan mac adresleri var ise kontrol et
  if(ARPKayitSayisi > 0) then
  begin

    for i := 1 to USTLIMIT_KAYITSAYISI do
    begin

      // ARP girdisi mevcut ise ( > -1)
      if(ARPKayitListesi[i]^.YasamSuresi > -1) then
        if(IPAdresleriniKarsilastir(ARPKayitListesi[i]^.IPAdres, AIPAdres)) then
          Exit(ARPKayitListesi[i]^.MACAdres);
    end;
  end;

  // ip adresinin mac adresi tabloda bulunamad��� i�in istek g�nder
  ARPIstegiGonder(arpIstek, @MACAdres0, @AIPAdres);

  BekleMS(200);

  // yeniden tabloyu kontrol et
  if(ARPKayitSayisi > 0) then
  begin

    for i := 1 to USTLIMIT_KAYITSAYISI do
    begin

      // ARP girdisi mevcut ise ( > -1)
      if(ARPKayitListesi[i]^.YasamSuresi > -1) then
        if(IPAdresleriniKarsilastir(ARPKayitListesi[i]^.IPAdres, AIPAdres)) then
          Exit(ARPKayitListesi[i]^.MACAdres);
    end;
  end;

  Result := MACAdres0;
end;

{==============================================================================
  istenen s�radaki ARP girdisini geri d�nd�r�r
 ==============================================================================}
function ARPKaydiAl(AARPSiraNo: TISayi4; AHedefBellek: PARPKayit): TISayi4;
var
  _SiraNo, i: TISayi4;
begin

  // ARP tablosunda silinen kay�tlar da olaca��ndan dolay� _SiraNo de�i�keni
  // ger�ek s�ra no'ya sahip kayd� almak i�in tan�mlanm� ve kullan�lm��t�r

  if(AARPSiraNo >= 0) and (AARPSiraNo < ARPKayitSayisi) then
  begin

    _SiraNo := -1;

    for i := 1 to USTLIMIT_KAYITSAYISI do
    begin

      // ARP girdisi mevcut ise ( > -1)
      if(ARPKayitListesi[i]^.YasamSuresi > -1) then Inc(_SiraNo);

      if(_SiraNo = AARPSiraNo) then
      begin

        AHedefBellek^.IPAdres := ARPKayitListesi[i]^.IPAdres;
        AHedefBellek^.MACAdres := ARPKayitListesi[i]^.MACAdres;
        AHedefBellek^.YasamSuresi := ARPKayitListesi[i]^.YasamSuresi;
        Result := HATA_YOK;
        Exit;
      end;
    end;

    Result := HATA_DEGERARALIKDISI;

  end else Result := HATA_DEGERARALIKDISI;
end;

end.
