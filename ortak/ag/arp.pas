{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: arp.pas
  Dosya ��levi: ARP protokol y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 13/07/2025

 ==============================================================================}
{$mode objfpc}
unit arp;
 
interface

uses paylasim;

const
  USTSINIR_KAYITSAYISI    = 64;
  ARPDONANIMTIP_ETHERNET  = TSayi2($0001);        // network byte s�ral�
  ARPPROTOKOLTIP_IPV4     = TSayi2($0800);        // network byte s�ral�
  YASAM_SURESI            = TISayi2(60 * 60);     // her bir kayd�n ya�am s�resi: 60 dakika

const
  // dikkat: de�erler network byte s�ral�d�r
  ARPISLEM_ISTEK = TSayi2($0001);
  ARPISLEM_YANIT = TSayi2($0002);

type
  TARPIslem = (arpIstek, arpYanit);

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

type
  PARPKayit = ^TARPKayit;
  TARPKayit = packed record
    IPAdres: TIPAdres;
    MACAdres: TMACAdres;
    YasamSuresi: TISayi2;
  end;

type
  PARPKayitlar = ^TARPKayitlar;
  TARPKayitlar = object
  private
    FARPKayitListesi: array[0..USTSINIR_KAYITSAYISI - 1] of PARPKayit;
    FToplamKayit: TSayi4;
    function ARPKayitAl(ASiraNo: TSayi4): PARPKayit;
    procedure ARPKayitYaz(ASiraNo: TSayi4; AARPKayit: PARPKayit);
  public
    procedure Yukle;
    procedure ARPPaketleriniIsle(AEthernetPaket: PEthernetPaket);
    procedure ARPKaydiEkle(AARPKayit: TARPKayit);
    procedure ARPIstegiGonder(AARPIslem: TARPIslem; AHedefMACAdres: PMACAdres;
      AHedefIPAdres: PIPAdres);
    function MACAdresiAl(AIPAdres: TIPAdres): TMACAdres;
    property ARPKayit[ASiraNo: TSayi4]: PARPKayit read ARPKayitAl write ARPKayitYaz;
    function ARPKaydiAl(ASiraNo: TISayi4; AHedefBellek: PARPKayit): TISayi4;
    property ToplamKayit: TSayi4 read FToplamKayit;
  end;

function ArpCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
procedure ARPTablosunuGuncelle;
procedure CihazlaraARPMesajiGonder;

var
  ARPKayitlar0: TARPKayitlar;
  ARPTabloKilit: TSayi4 = 0;

implementation

uses ag, islevler, zamanlayici, sistemmesaj, donusum, gorev;

{==============================================================================
  ARP protokol�n� ilk de�erlerle y�kler
 ==============================================================================}
procedure TARPKayitlar.Yukle;
var
  i: TISayi4;
begin

  // arp kay�t yap�lar�n� ilk de�erlerle y�kle
  for i := 0 to USTSINIR_KAYITSAYISI - 1 do ARPKayit[i] := nil;

  // ARP kay�t say�s�n� s�f�rla
  FToplamKayit := 0;
end;

function TARPKayitlar.ARPKayitAl(ASiraNo: TSayi4): PARPKayit;
begin

  // istenen verinin belirtilen aral�kta olup olmad���n� kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_KAYITSAYISI) then
    Result := FARPKayitListesi[ASiraNo]
  else Result := nil;
end;

procedure TARPKayitlar.ARPKayitYaz(ASiraNo: TSayi4; AARPKayit: PARPKayit);
begin

  // istenen verinin belirtilen aral�kta olup olmad���n� kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_KAYITSAYISI) then
    FARPKayitListesi[ASiraNo] := AARPKayit;
end;

{==============================================================================
  ARP kesme �a�r�lar�n� y�netir
 ==============================================================================}
function ArpCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  ARP0: PARPKayit;
  IslevNo,
  SiraNo: TSayi4;
begin

  // i�lev no
  IslevNo := (AIslevNo and $FF);

  // toplam ARP girdi say�s�n� ver
  if(IslevNo = 1) then
  begin

    Result := ARPKayitlar0.ToplamKayit;
  end

  // ARP girdi i�eri�ini ver
  else if(IslevNo = 2) then
  begin

    SiraNo := PSayi4(ADegiskenler + 00)^;

    ARP0 := PARPKayit(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
    Result := ARPKayitlar0.ARPKaydiAl(SiraNo, ARP0);
  end

  else Result := HATA_ISLEV;
end;

{==============================================================================
  a� ayg�t�ndan gelen mesajlar� i�ler
 ==============================================================================}
procedure TARPKayitlar.ARPPaketleriniIsle(AEthernetPaket: PEthernetPaket);
var
  EthernetPaket: PEthernetPaket;
  ARPPaket: PARPPaket;
  ARP0: TARPKayit;
begin

  EthernetPaket := AEthernetPaket;
  ARPPaket := @EthernetPaket^.Veri;

  ARP0.IPAdres := ARPPaket^.GonderenIPAdres;
  ARP0.MACAdres := ARPPaket^.GonderenMACAdres;

  // ARP paketi ip adresime g�nderilmi� ise
  if(IPAdresleriniKarsilastir(ARPPaket^.HedefIPAdres, GAgBilgisi.IP4Adres)) then
  begin

    // 1. g�nderilen paket benim mesaj�ma yan�t ise, tabloya ekle
    if(htons(ARPPaket^.Islem) = ARPISLEM_YANIT) then

      ARPKaydiEkle(ARP0)

    // 2. g�nderilen mesaj yan�t istiyorsa;
    // 2.1 talep eden makinenin bilgilerini listeye ekle
    // 2.2 makineye ARP yan�t mesaj�n� mesaj�n� g�nder
    else if(htons(ARPPaket^.Islem) = ARPISLEM_ISTEK) then
    begin

      ARPKaydiEkle(ARP0);
      ARPIstegiGonder(arpYanit, @ARPPaket^.GonderenMACAdres, @ARPPaket^.GonderenIPAdres);
    end;
  end;
end;

{==============================================================================
  ARP iste�i g�nderir
 ==============================================================================}
procedure TARPKayitlar.ARPIstegiGonder(AARPIslem: TARPIslem; AHedefMACAdres: PMACAdres;
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
  ARP tablosunu her 1 saniyede bir kez g�nceller
  bilgi: i�lev, �ekirde�e ba�l� ayr� bir g�rev olarak �al��maktad�r
 ==============================================================================}
procedure ARPTablosunuGuncelle;
var
  YasamSuresi: TISayi2;
  i, j: TSayi4;
  ARP0, ARP1: PARPKayit;
  KayitSilindi: Boolean;
begin

  while True do
  begin

    BekleMS(100);

    while KritikBolgeyeGir(ARPTabloKilit) = False do;

    KayitSilindi := False;

    // kay�tlar� g�ncelle
    if(ARPKayitlar0.ToplamKayit > 0) then
    begin

      for i := 0 to ARPKayitlar0.ToplamKayit - 1 do
      begin

        ARP0 := ARPKayitlar0.ARPKayit[i];
        if not(ARP0 = nil) then
        begin

          YasamSuresi := ARP0^.YasamSuresi;
          Dec(YasamSuresi);
          ARP0^.YasamSuresi := YasamSuresi;

          // ya�am s�resi 0 oldu�unda kayd� sil ve listeden ��kar
          if(YasamSuresi = 0) then
          begin

            FreeMem(ARP0, SizeOf(TARPKayit));
            ARPKayitlar0.ARPKayit[i] := nil;

            KayitSilindi := True;

            j := ARPKayitlar0.FToplamKayit;
            Dec(j);
            ARPKayitlar0.FToplamKayit := j;
          end;
        end;
      end;
    end;

    // arp tablosunu g�ncelle
    // bilgi: kay�t g�ncellemesi, 0. kay�ttan son kayda do�ru hi� bo�luk
    // olmayacak �ekilde yeniden s�ralanma i�lemidir
    if(KayitSilindi) and (ARPKayitlar0.ToplamKayit > 0) then
    begin

      for i := 1 to USTSINIR_KAYITSAYISI - 1 do
      begin

        ARP0 := ARPKayitlar0.ARPKayit[i];
        if not(ARP0 = nil) then
        begin

          for j := 0 to i - 1 do
          begin

            ARP1 := ARPKayitlar0.ARPKayit[j];
            if(ARP1 = nil) then
            begin

              ARPKayitlar0.ARPKayit[j] := ARP0;
              Break;
            end;
          end;
        end;
      end;
    end;

    KritikBolgedenCik(ARPTabloKilit);
  end;
end;

{==============================================================================
  ARP tablosunu her 1 saniyede bir g�nceller
  bilgi: i�lev, �ekirde�e ba�l� ayr� bir g�rev olarak �al��maktad�r
 ==============================================================================}
procedure CihazlaraARPMesajiGonder;
var
  IPAdres: TIPAdres;
  i: TSayi4;
begin

  // ip al�m�n�n ger�ekle�mesi i�in 5 saniye bekle
  BekleMS(500);

  // bilgisayar�n ip adresi
  IPAdres := GAgBilgisi.IP4Adres;

  i := 0;

  while True do
  begin

    BekleMS(100);

    if(AgYuklendi) and (GAgBilgisi.IPAdresiAlindi) then
    begin

      if(i = 0) then
        SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'A�daki cihazlara ARP mesaj� g�nderiliyor...', []);

      IPAdres[3] := i;

      // kendi ip adresimin haricinde t�m cihazlara arp istek mesaj� g�nder
      if not(IPKarsilastir(GAgBilgisi.IP4Adres, IPAdres)) then
        ARPKayitlar0.ARPIstegiGonder(arpIstek, nil, @IPAdres);

      Inc(i);

      if(i > 255) then i := 0;
    end;
  end;
end;

{==============================================================================
  ARP tablosuna ARP kayd� ekler
 ==============================================================================}
procedure TARPKayitlar.ARPKaydiEkle(AARPKayit: TARPKayit);
var
  i, j: TSayi4;
  ARP0: PARPKayit;
begin

  while KritikBolgeyeGir(ARPTabloKilit) = False do;

  // yan�t� g�nderen bilgisayar�n ip adresi listede var m� ?
  for i := 0 to USTSINIR_KAYITSAYISI - 1 do
  begin

    ARP0 := ARPKayit[i];
    if not(ARP0 = nil) then
    begin

      // varsa g�ncelle ve ��k
      if(IPAdresleriniKarsilastir(ARP0^.IPAdres, AARPKayit.IPAdres)) then
      begin

        ARP0^.MACAdres := AARPKayit.MACAdres;
        ARP0^.YasamSuresi := YASAM_SURESI;
        KritikBolgedenCik(ARPTabloKilit);
        Exit;
      end;
    end;
  end;

  // tablo dolu ise mevcut kayd� tabloya eklemeden i�levden ��k
  if(ToplamKayit >= USTSINIR_KAYITSAYISI) then
  begin

    KritikBolgedenCik(ARPTabloKilit);
    Exit;
  end;

  // ARP girdisini tabloya ekle
  ARP0 := GetMem(SizeOf(TARPKayit));
  if not(ARP0 = nil) then
  begin

    ARPKayit[ToplamKayit] := ARP0;

    ARP0^.IPAdres := AARPKayit.IPAdres;
    ARP0^.MACAdres := AARPKayit.MACAdres;
    ARP0^.YasamSuresi := YASAM_SURESI;

    j := FToplamKayit;
    Inc(j);
    FToplamKayit := j;

    KritikBolgedenCik(ARPTabloKilit);
    Exit;
  end;
end;

{==============================================================================
  arp tablosundan ip adresinin kar��l��� olam mac adresini al�r
 ==============================================================================}
function TARPKayitlar.MACAdresiAl(AIPAdres: TIPAdres): TMACAdres;
var
  ARP0: PARPKayit;
  i, j: TSayi4;
begin

  // arp tabolsunda ip kar��l��� olan mac adresleri var ise kontrol et
  if(ToplamKayit > 0) then
  begin

    for i := 0 to USTSINIR_KAYITSAYISI - 1 do
    begin

      ARP0 := ARPKayit[i];

      // ARP kayd� mevcut ise �a��ran i�leve geri d�nd�r
      if not(ARP0 = nil) then
        if(IPAdresleriniKarsilastir(ARP0^.IPAdres, AIPAdres)) then Exit(ARP0^.MACAdres);
    end;
  end;

  // istenen ip adresinin mac adresini sorgula
  for i := 1 to 10 do
  begin

    // ip adresinin mac adresi tabloda bulunamad��� i�in istek g�nder
    ARPIstegiGonder(arpIstek, nil, @AIPAdres);

    // 0.5 saniye bekle
    BekleMS(50);

    // yeniden tabloyu kontrol et
    if(ToplamKayit > 0) then
    begin

      for j := 0 to USTSINIR_KAYITSAYISI - 1 do
      begin

        ARP0 := ARPKayit[j];

        // ARP kayd� mevcut ise �a��ran i�leve geri d�nd�r
        if not(ARP0 = nil) then
          if(IPAdresleriniKarsilastir(ARP0^.IPAdres, AIPAdres)) then Exit(ARP0^.MACAdres);
      end;
    end;
  end;

  Result := MACAdres0;
end;

{==============================================================================
  istenen s�radaki ARP girdisini geri d�nd�r�r
 ==============================================================================}
function TARPKayitlar.ARPKaydiAl(ASiraNo: TISayi4; AHedefBellek: PARPKayit): TISayi4;
var
  ARP0: PARPKayit;
begin

  while KritikBolgeyeGir(ARPTabloKilit) = False do;

  // ARP tablosunda silinen kay�tlar da olaca��ndan dolay� SiraNo de�i�keni
  // ger�ek s�ra no'ya sahip kayd� almak i�in tan�mlanm� ve kullan�lm��t�r

  if(ASiraNo >= 0) and (ASiraNo < ToplamKayit) then
  begin

    ARP0 := ARPKayit[ASiraNo];
    if not(ARP0 = nil) then
    begin

      AHedefBellek^.IPAdres := ARP0^.IPAdres;
      AHedefBellek^.MACAdres := ARP0^.MACAdres;
      AHedefBellek^.YasamSuresi := ARP0^.YasamSuresi;

      Result := HATA_YOK;

      KritikBolgedenCik(ARPTabloKilit);
      Exit;
    end else Result := HATA_DEGERARALIKDISI;

  end else Result := HATA_DEGERARALIKDISI;

  KritikBolgedenCik(ARPTabloKilit);
end;

end.
