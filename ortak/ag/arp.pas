{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: arp.pas
  Dosya Ýþlevi: ARP protokol yönetim iþlevlerini içerir

  Güncelleme Tarihi: 28/07/2026

 ==============================================================================}
{$mode objfpc}
unit arp;
 
interface

uses paylasim;

const
  AZAMI_ARPKAYITSAYISI    = 64;
  ARPDONANIMTIP_ETHERNET  = TSayi2($0001);        // network byte sýralý
  ARPPROTOKOLTIP_IP4      = TSayi2($0800);        // network byte sýralý
  YASAM_SURESI            = TISayi2(60 * 60);     // her bir kaydýn yaþam süresi: 60 dakika

const
  // dikkat: deðerler network byte sýralýdýr
  ARPISLEM_ISTEK = TSayi2($0001);
  ARPISLEM_YANIT = TSayi2($0002);

type
  TARPIslem = (arpIstek, arpYanit);

type
  PARPPaket = ^TARPPaket;
  TARPPaket = packed record
    DonanimTip: TSayi2;           // donaným tipi
    ProtokolTip: TSayi2;          // protokol tipi
    DonanimAdresU: TSayi1;        // donaným adres uzunluðu
    ProtokolAdresU: TSayi1;       // protokol adres uzunluðu
    Islem: TSayi2;                // iþlem
    GonderenMACAdres: TMACAdres;  // paketi gönderen donaným adresi
    GonderenIP4Adres: TIP4Adres;  // paketi gönderen ip adresi
    HedefMACAdres: TMACAdres;     // paketin gönderildiði donaným adresi
    HedefIP4Adres: TIP4Adres;     // paketin gönderildiði ip adresi
  end;

type
  // programlar için
  PARPKayit3 = ^TARPKayit3;
  TARPKayit3 = packed record
    IP4Adres: TIP4Adres;
    MACAdres: TMACAdres;
    YasamSuresi: TISayi2;
  end;

type
  PARP = ^TARP;
  TARP = class
  private
    FBaglanti: TObject;
  public
    constructor Create(ABaglanti: TObject);
    procedure VerileriIsle(AEthernetPaket: PEthernetPaket);
    procedure IstekGonder(AARPIslem: TARPIslem; AHedefMACAdres: PMACAdres;
      AHedefIP4Adres: PIP4Adres);
  end;

type
  PARPKayit = ^TARPKayit;
  TARPKayit = class
    IP4Adres: TIP4Adres;
    MACAdres: TMACAdres;
    YasamSuresi: TSayi4;
  end;

type
  PARPTablosu = ^TARPTablosu;
  TARPTablosu = class
  private
    FBaglanti: TObject;
    FToplamKayit: TISayi4;
    FARPKayitListesi: array[0..AZAMI_ARPKAYITSAYISI - 1] of TARPKayit;
    function Al(ASiraNo: TISayi4): TARPKayit;
    procedure Yaz(ASiraNo: TISayi4; AARPKayit: TARPKayit);
  public
    constructor Create(ABaglanti: TObject);
    property ARPKayit[ASiraNo: TISayi4]: TARPKayit read Al write Yaz;
    procedure ARPKaydiEkle(AIP4Adres: TIP4Adres; AMACAdres: TMACAdres);
    function MACAdresAl(AIP4Adres: TIP4Adres): TMACAdres;
    function ARPKaydiAl(ASiraNo: TISayi4; AHedefBellek: PARPKayit3): TISayi4;

    property ToplamKayit: TISayi4 read FToplamKayit;
    procedure ARPTablosunuGuncelle;
    procedure CihazlaraARPMesajiGonder;
  end;

function ArpCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

var
  GARPTablosu: TARPTablosu = nil;
  ARPTabloKilit: TSayi4 = 0;

implementation

uses islevler, zamanlayici, donusum, gorev, ethernet, baglantilar;

{==============================================================================
  arp kesme çaðrýlarýný yönetir
 ==============================================================================}
function ArpCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  A: PARPKayit3;
  IslevNo,
  SiraNo: TISayi4;
begin

  Result := HATA_ISLEV;

  // iþlev no
  IslevNo := (AIslevNo and $FF);

  // toplam ARP girdi sayýsýný ver
  if(IslevNo = 1) then
  begin

    Result := GARPTablosu.ToplamKayit;
  end

  // ARP girdi içeriðini ver
  else if(IslevNo = 2) then
  begin

    SiraNo := PISayi4(ADegiskenler + 00)^;

    A := PARPKayit3(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr);
    Result := GARPTablosu.ARPKaydiAl(SiraNo, A);
  end;
end;

{==============================================================================
  arp tablosunu ilk deðerlerle yükler
 ==============================================================================}
constructor TARPTablosu.Create(ABaglanti: TObject);
var
  i: TSayi4;
begin

  FBaglanti := ABaglanti;

  // ARP kayýt sayýsýný sýfýrla
  FToplamKayit := 0;

  // arp kayýt yapýlarýný ilk deðerlerle yükle
  for i := 0 to AZAMI_ARPKAYITSAYISI - 1 do ARPKayit[i] := nil;
end;

function TARPTablosu.Al(ASiraNo: TISayi4): TARPKayit;
begin

  if(ASiraNo >= 0) and (ASiraNo < AZAMI_ARPKAYITSAYISI) then
    Result := FARPKayitListesi[ASiraNo]
  else Result := nil;
end;

procedure TARPTablosu.Yaz(ASiraNo: TISayi4; AARPKayit: TARPKayit);
begin

  if(ASiraNo >= 0) and (ASiraNo < AZAMI_ARPKAYITSAYISI) then
    FARPKayitListesi[ASiraNo] := AARPKayit;
end;

constructor TARP.Create(ABaglanti: TObject);
begin

  FBaglanti := ABaglanti;
end;

{==============================================================================
  að aygýtýndan gelen arp mesajlarýný iþler
 ==============================================================================}
procedure TARP.VerileriIsle(AEthernetPaket: PEthernetPaket);
var
  EPaket: PEthernetPaket;
  APaket: PARPPaket;
begin

  EPaket := AEthernetPaket;
  APaket := @EPaket^.Veri;

  // ARP paketi ip adresime gönderilmiþ ise
  if(IPKarsilastir(APaket^.HedefIP4Adres, TBaglanti(FBaglanti).IP4Adres)) then
  begin

    // 1. gönderilen paket benim mesajýma yanýt ise, tabloya ekle
    if(htons(APaket^.Islem) = ARPISLEM_YANIT) then

      GARPTablosu.ARPKaydiEkle(APaket^.GonderenIP4Adres, APaket^.GonderenMACAdres)

    // 2. gönderilen mesaj yanýt istiyorsa;
    // 2.1 talep eden makinenin bilgilerini listeye ekle
    // 2.2 makineye ARP yanýt mesajýný mesajýný gönder
    else if(htons(APaket^.Islem) = ARPISLEM_ISTEK) then
    begin

      GARPTablosu.ARPKaydiEkle(APaket^.GonderenIP4Adres, APaket^.GonderenMACAdres);
      IstekGonder(arpYanit, @APaket^.GonderenMACAdres, @APaket^.GonderenIP4Adres);
    end;
  end;
end;

{==============================================================================
  arp isteði gönderir
 ==============================================================================}
procedure TARP.IstekGonder(AARPIslem: TARPIslem; AHedefMACAdres: PMACAdres;
  AHedefIP4Adres: PIP4Adres);
var
  APaket: TARPPaket;
begin

  APaket.DonanimTip := ntohs(ARPDONANIMTIP_ETHERNET);
  APaket.ProtokolTip := ntohs(ARPPROTOKOLTIP_IP4);
  APaket.DonanimAdresU := 6;
  APaket.ProtokolAdresU := 4;
  if(AARPIslem = arpIstek) then
    APaket.Islem := ntohs(ARPISLEM_ISTEK)
  else APaket.Islem := ntohs(ARPISLEM_YANIT);
  APaket.GonderenMACAdres := TBaglanti(FBaglanti).FEthernet.MACAdres;
  APaket.GonderenIP4Adres := TBaglanti(FBaglanti).IP4Adres;

  if(AARPIslem = arpIstek) then
    APaket.HedefMACAdres := MACAdres0
  else if(AARPIslem = arpYanit) then
    APaket.HedefMACAdres := AHedefMACAdres^;

  APaket.HedefIP4Adres := AHedefIP4Adres^;

  if(AARPIslem = arpIstek) then
    TBaglanti(FBaglanti).FEthernet.Gonder(MACAdres255, ptARP, @APaket, 28)
  else TBaglanti(FBaglanti).FEthernet.Gonder(AHedefMACAdres^, ptARP, @APaket, 28);
end;

{==============================================================================
  ARP tablosunu her 1 saniyede bir kez günceller
  bilgi: iþlev, çekirdeðe baðlý ayrý bir görev olarak çalýþmaktadýr
 ==============================================================================}
procedure TARPTablosu.ARPTablosunuGuncelle;
var
  AKayit1, AKayit2: TARPKayit;
  YasamSuresi: TSayi4;
  i, j: TSayi4;
  KayitSilindi: Boolean;
begin

  while True do
  begin

    GZamanlayicilar.BekleMS(CALISMA_FREKANSI);

//    while KritikBolgeyeGir(ARPTabloKilit) = False do;

    KayitSilindi := False;

    // kayýtlarý güncelle
    if(GARPTablosu.ToplamKayit > 0) then
    begin

      for i := 0 to GARPTablosu.ToplamKayit - 1 do
      begin

        AKayit1 := GARPTablosu.ARPKayit[i];
        if not(AKayit1 = nil) then
        begin

          YasamSuresi := AKayit1.YasamSuresi;
          Dec(YasamSuresi);
          AKayit1.YasamSuresi := YasamSuresi;

          // yaþam süresi 0 olduðunda kaydý sil ve listeden çýkar
          if(YasamSuresi = 0) then
          begin

            AKayit1.Destroy;
            GARPTablosu.ARPKayit[i] := nil;

            KayitSilindi := True;

            Dec(GARPTablosu.FToplamKayit);
          end;
        end;
      end;
    end;

    // arp tablosunu güncelle
    // bilgi: kayýt güncellemesi, 0. kayýttan son kayda doðru hiç boþluk
    // olmayacak þekilde yeniden sýralanma iþlemidir
    { TODO - kontrol edilsin }
    if(KayitSilindi) and (GARPTablosu.ToplamKayit > 0) then
    begin

      for i := 1 to AZAMI_ARPKAYITSAYISI - 1 do
      begin

        AKayit1 := GARPTablosu.ARPKayit[i];
        if not(AKayit1 = nil) then
        begin

          for j := 0 to i - 1 do
          begin

            AKayit2 := GARPTablosu.ARPKayit[j];
            if(AKayit2 = nil) then
            begin

              GARPTablosu.ARPKayit[j] := AKayit1;
              Break;
            end;
          end;
        end;
      end;
    end;

//    KritikBolgedenCik(ARPTabloKilit);
  end;
end;

{==============================================================================
  ARP tablosunu her 1 saniyede bir günceller
  bilgi: iþlev, çekirdeðe baðlý ayrý bir görev olarak çalýþmaktadýr
 ==============================================================================}
procedure TARPTablosu.CihazlaraARPMesajiGonder;
var
  IP4Adres: TIP4Adres;
  i: TSayi4;
begin

  // ip alýmýnýn gerçekleþmesi için 5 saniye bekle
  GZamanlayicilar.BekleMS(5 * CALISMA_FREKANSI);

  // bilgisayarýn ip adresi
  IP4Adres := GAgBaglantilari.AktifBaglanti.IP4Adres;

  i := 0;

  while True do
  begin

    GZamanlayicilar.BekleMS(CALISMA_FREKANSI);

    { geçici olarak kapatýldý, aktifleþtirilebilir }
    {if(AgYuklendi) and (GAgBilgisi.IP4AdresiAlindi) then
    begin

      if(i = 0) then
        SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Aðdaki cihazlara ARP mesajý gönderiliyor...', []);

      IP4Adres[3] := i;

      // kendi ip adresimin haricinde tüm cihazlara arp istek mesajý gönder
      if not(IPKarsilastir(GAgBilgisi.IP4Adres, IP4Adres)) then
        ARPKayitlar0.ARPIstegiGonder(arpIstek, nil, @IP4Adres);

      Inc(i);

      if(i > 255) then i := 0;
    end;}
  end;
end;

{==============================================================================
  arp tablosuna arp kaydý ekler
 ==============================================================================}
procedure TARPTablosu.ARPKaydiEkle(AIP4Adres: TIP4Adres; AMACAdres: TMACAdres);
var
  AKayit: TARPKayit;
  i, j: TSayi4;
begin

//  while KritikBolgeyeGir(ARPTabloKilit) = False do;

  // yanýtý gönderen bilgisayarýn ip adresi listede var mý ?
  for i := 0 to AZAMI_ARPKAYITSAYISI - 1 do
  begin

    AKayit := ARPKayit[i];
    if not(AKayit = nil) then
    begin

      // varsa güncelle ve çýk
      if(IPKarsilastir(AKayit.IP4Adres, AIP4Adres)) then
      begin

        AKayit.MACAdres := AMACAdres;
        AKayit.YasamSuresi := YASAM_SURESI;
//        KritikBolgedenCik(ARPTabloKilit);
        Exit;
      end;
    end;
  end;

  // tablo dolu ise mevcut kaydý tabloya eklemeden iþlevden çýk
  if(ToplamKayit >= AZAMI_ARPKAYITSAYISI) then
  begin

//    KritikBolgedenCik(ARPTabloKilit);
    Exit;
  end;

  // ARP girdisini tabloya ekle
  AKayit := TARPKayit.Create;
  if not(AKayit = nil) then
  begin

    ARPKayit[ToplamKayit] := AKayit;

    AKayit.IP4Adres := AIP4Adres;
    AKayit.MACAdres := AMACAdres;
    AKayit.YasamSuresi := YASAM_SURESI;

    j := FToplamKayit;
    Inc(j);
    FToplamKayit := j;

//    KritikBolgedenCik(ARPTabloKilit);
    Exit;
  end;
end;

{==============================================================================
  arp tablosundan ip adresinin karþýlýðý olam mac adresini alýr
 ==============================================================================}
function TARPTablosu.MACAdresAl(AIP4Adres: TIP4Adres): TMACAdres;
var
  A: TARP;
  ARP0: TARPKayit;
  i, j: TSayi4;
begin

  // arp tabolsunda ip karþýlýðý olan mac adresleri var ise kontrol et
  if(ToplamKayit > 0) then
  begin

    for i := 0 to AZAMI_ARPKAYITSAYISI - 1 do
    begin

      ARP0 := ARPKayit[i];

      // ARP kaydý mevcut ise çaðýran iþleve geri döndür
      if not(ARP0 = nil) then
        if(IPKarsilastir(ARP0.IP4Adres, AIP4Adres)) then Exit(ARP0.MACAdres);
    end;
  end;

  // istenen ip adresinin mac adresini sorgula
  for i := 1 to 10 do
  begin

    // ip adresinin mac adresi tabloda bulunamadýðý için istek gönder
    {A := TARP.Create(FBaglanti);
    A.ARPIstegiGonder(arpIstek, nil, @AIP4Adres);
    A.Destroy;}

    // 0.5 saniye bekle
    //BekleMS(50);
    ElleGorevDegistir;

    // yeniden tabloyu kontrol et
    if(ToplamKayit > 0) then
    begin

      for j := 0 to AZAMI_ARPKAYITSAYISI - 1 do
      begin

        ARP0 := ARPKayit[j];

        // ARP kaydý mevcut ise çaðýran iþleve geri döndür
        if not(ARP0 = nil) then if(IPKarsilastir(ARP0.IP4Adres, AIP4Adres)) then Exit(ARP0.MACAdres);
      end;
    end;
  end;

  Result := MACAdres0;
end;

{==============================================================================
  istenen sýradaki ARP girdisini geri döndürür
 ==============================================================================}
function TARPTablosu.ARPKaydiAl(ASiraNo: TISayi4; AHedefBellek: PARPKayit3): TISayi4;
var
  ARP0: TARPKayit;
begin

//  while KritikBolgeyeGir(ARPTabloKilit) = False do;

  // ARP tablosunda silinen kayýtlar da olacaðýndan dolayý SiraNo deðiþkeni
  // gerçek sýra no'ya sahip kaydý almak için tanýmlanmý ve kullanýlmýþtýr

  if(ASiraNo >= 0) and (ASiraNo < ToplamKayit) then
  begin

    ARP0 := ARPKayit[ASiraNo];
    if not(ARP0 = nil) then
    begin

      AHedefBellek^.IP4Adres := ARP0.IP4Adres;
      AHedefBellek^.MACAdres := ARP0.MACAdres;
      AHedefBellek^.YasamSuresi := ARP0.YasamSuresi;

      Result := HATA_YOK;

//      KritikBolgedenCik(ARPTabloKilit);
      Exit;
    end else Result := HATA_DEGERARALIKDISI;

  end else Result := HATA_DEGERARALIKDISI;

//  KritikBolgedenCik(ARPTabloKilit);
end;

end.
