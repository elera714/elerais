{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: arp.pas
  Dosya Ýþlevi: ARP protokol yönetim iþlevlerini içerir

  Güncelleme Tarihi: 23/12/2024

 ==============================================================================}
{$mode objfpc}
unit arp;
 
interface

uses paylasim;

const
  // dikkat: deðerler network byte sýralýdýr
  ARPISLEM_ISTEK = TSayi2($0001);
  ARPISLEM_YANIT = TSayi2($0002);

const
  USTLIMIT_KAYITSAYISI    = 10;
  ARPDONANIMTIP_ETHERNET  = TSayi2($0001);        // network byte sýralý
  ARPPROTOKOLTIP_IPV4     = TSayi2($0800);        // network byte sýralý

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

uses genel, ag, islevler, zamanlayici, sistemmesaj, donusum;

var
  ARPKayitSayisi: TISayi4;
  ARPKayitBellekAdresi: Isaretci;
  ARPKayitListesi: array[1..USTLIMIT_KAYITSAYISI] of PARPKayit;

{==============================================================================
  ARP protokolünü ilk deðerlerle yükler
 ==============================================================================}
procedure Yukle;
var
  ARPKayitBellekAdresi: Isaretci;
  i: TISayi4;
begin

  // ARP giriþleri için bellekte yer tahsis et
  ARPKayitBellekAdresi := GGercekBellek.Ayir(USTLIMIT_KAYITSAYISI * SizeOf(TARPKayit));

  // giriþlere ait iþaretçileri bellek bölgeleriyle eþleþtir
  ARPKayitBellekAdresi := ARPKayitBellekAdresi;

  for i := 1 to USTLIMIT_KAYITSAYISI do
  begin

    ARPKayitListesi[i] := ARPKayitBellekAdresi;
    ARPKayitListesi[i]^.YasamSuresi := -1;       // -1 = girdi yok

    ARPKayitBellekAdresi += SizeOf(TARPKayit);
  end;

  // ARP kayýt sayýsýný sýfýrla
  ARPKayitSayisi := 0;
end;

{==============================================================================
  ARP kesme çaðrýlarýný yönetir
 ==============================================================================}
function ArpCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  ARPKayit: PARPKayit;
  IslevNo: TSayi4;
  GirdiSiraNo: TISayi4;
begin

  // iþlev no
  IslevNo := (AIslevNo and $FF);

  // toplam ARP girdi sayýsýný ver
  if(IslevNo = 1) then
  begin

    Result := ARPKayitSayisi;
  end

  // ARP girdi içeriðini ver
  else if(IslevNo = 2) then
  begin

    GirdiSiraNo := PISayi4(ADegiskenler + 00)^;
    if(GirdiSiraNo >= 0) and (GirdiSiraNo < ARPKayitSayisi) then
    begin

      ARPKayit := PARPKayit(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi);
      Result := ARPKaydiAl(GirdiSiraNo, ARPKayit);

    end else Result := HATA_DEGERARALIKDISI;
  end

  else Result := HATA_ISLEV;
end;

{==============================================================================
  að aygýtýndan gelen mesajlarý iþler
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
  ARPKayit.YasamSuresi := 60 * 60;    // 60 dakika yaþam ömrü

  // ARP paketi ip adresime gönderilmiþ ise
  if(IPAdresleriniKarsilastir(ARPPaket^.HedefIPAdres, GAgBilgisi.IP4Adres)) then
  begin

    // 1. gönderilen paket benim mesajýma yanýt ise, tabloya ekle
    if(htons(ARPPaket^.Islem) = ARPISLEM_YANIT) then

      ARPKaydiEkle(ARPKayit)

    // 2. gönderilen mesaj yanýt istiyorsa;
    // 2.1 talep eden makinenin bilgilerini listeye ekle
    // 2.2 makineye ARP yanýt mesajýný mesajýný gönder
    else if(htons(ARPPaket^.Islem) = ARPISLEM_ISTEK) then
    begin

      ARPKaydiEkle(ARPKayit);
      ARPIstegiGonder(arpYanit, @ARPPaket^.GonderenMACAdres, @ARPPaket^.GonderenIPAdres);
    end;
  end;
end;

{==============================================================================
  ARP isteði gönderir
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
  ARP tablosunu günceller
 ==============================================================================}
procedure ARPTablosunuGuncelle;
var
  i, YasamSuresi: TISayi4;
begin

  for i := 1 to USTLIMIT_KAYITSAYISI do
  begin

    if(ARPKayitListesi[i]^.YasamSuresi > 0) then
    begin

      YasamSuresi := ARPKayitListesi[i]^.YasamSuresi;
      Dec(YasamSuresi);
      ARPKayitListesi[i]^.YasamSuresi := YasamSuresi;

      // yaþam süresi 0 olduðunda girdi -1 yapýlarak baþka kayýtlarýn eklenmesi saðlanýyor
      if(YasamSuresi = 0) then
      begin

        ARPKayitListesi[i]^.YasamSuresi := -1;
        Dec(ARPKayitSayisi);      // girdi sayýsýný azalt
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

  {SISTEM_MESAJ(RENK_MOR, 'Eklenecek ARP Kayýt Bilgileri:', []);
  SISTEM_MESAJ_IP(RENK_LACIVERT, 'ARP - IP: ', AARPKayit.IPAdres);
  SISTEM_MESAJ_MAC(RENK_LACIVERT, 'ARP - MAC: ', AARPKayit.MACAdres);
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'ARP - Yaþ.Süre: ', AARPKayit.YasamSuresi, 4);}

  // yanýtý gönderen bilgisayarýn ip adresi listede var mý ?
  for i := 1 to USTLIMIT_KAYITSAYISI do
  begin

    // varsa güncelle ve çýk
    if(IPAdresleriniKarsilastir(ARPKayitListesi[i]^.IPAdres, AARPKayit.IPAdres)) then
    begin

      ARPKayitListesi[i]^.MACAdres := AARPKayit.MACAdres;
      ARPKayitListesi[i]^.YasamSuresi := AARPKayit.YasamSuresi;
      Exit;
    end;
  end;

  // ARP girdisi bulunamadýysa girdiyi tabloya ekle

  if(ARPKayitSayisi >= USTLIMIT_KAYITSAYISI) then Exit;

  // boþ ARP giriþi ara
  for i := 1 to USTLIMIT_KAYITSAYISI do
  begin

    // YasamSuresi = -1 = boþ demektir
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
  arp tablosundan ip adresinin karþýlýðý olam mac adresini alýr
 ==============================================================================}
function MACAdresiAl(AIPAdres: TIPAdres): TMACAdres;
var
  i: TISayi4;
begin

  // arp tabolsunda ip karþýlýðý olan mac adresleri var ise kontrol et
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

  // ip adresinin mac adresi tabloda bulunamadýðý için istek gönder
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
  istenen sýradaki ARP girdisini geri döndürür
 ==============================================================================}
function ARPKaydiAl(AARPSiraNo: TISayi4; AHedefBellek: PARPKayit): TISayi4;
var
  SiraNo, i: TISayi4;
begin

  // ARP tablosunda silinen kayýtlar da olacaðýndan dolayý SiraNo deðiþkeni
  // gerçek sýra no'ya sahip kaydý almak için tanýmlanmý ve kullanýlmýþtýr

  if(AARPSiraNo >= 0) and (AARPSiraNo < ARPKayitSayisi) then
  begin

    SiraNo := -1;

    for i := 1 to USTLIMIT_KAYITSAYISI do
    begin

      // ARP girdisi mevcut ise ( > -1)
      if(ARPKayitListesi[i]^.YasamSuresi > -1) then Inc(SiraNo);

      if(SiraNo = AARPSiraNo) then
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
