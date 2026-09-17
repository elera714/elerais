{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: arp.pas
  Dosya Ýþlevi: ARP protokol yönetim iþlevlerini içerir

  Güncelleme Tarihi: 17/09/2026

 ==============================================================================}
{$mode objfpc}
unit arp;
 
interface

uses paylasim, ethernet;

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
  GARPTablosu: TARPTablosu;
  ARPTabloKilit: TSayi4;

implementation

uses islevler, zamanlayici, donusum, gorev, baglantilar, sistemmesaj;

{==============================================================================
  arp kesme çaðrýlarýný yönetir
 ==============================================================================}
function ArpCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  AK: PARPKayit3;
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

    AK := PARPKayit3(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr);
    Result := GARPTablosu.ARPKaydiAl(SiraNo, AK);
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
  if(IPKarsilastir(APaket^.HedefIP4Adres, TBaglanti(FBaglanti).IP4Adresim)) then
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
  APaket.GonderenMACAdres := TBaglanti(FBaglanti).FEthernet.MACAdresim;
  APaket.GonderenIP4Adres := TBaglanti(FBaglanti).IP4Adresim;

  if(AARPIslem = arpIstek) then
    APaket.HedefMACAdres := MACAdres0
  else if(AARPIslem = arpYanit) then
    APaket.HedefMACAdres := AHedefMACAdres^;

  APaket.HedefIP4Adres := AHedefIP4Adres^;

  if(AARPIslem = arpIstek) then
  begin

    TBaglanti(FBaglanti).FEthernet.FHedefMACAdres := MACAdres255;
    TBaglanti(FBaglanti).FEthernet.Gonder(ptARP, @APaket, 28)
  end
  else
  begin

    TBaglanti(FBaglanti).FEthernet.FHedefMACAdres := AHedefMACAdres^;
    TBaglanti(FBaglanti).FEthernet.Gonder(ptARP, @APaket, 28);
  end;
end;

{==============================================================================
  ARP tablosunu her 1 saniyede bir kez günceller
  bilgi: iþlev, çekirdeðe baðlý ayrý bir görev olarak çalýþmaktadýr
 ==============================================================================}
procedure TARPTablosu.ARPTablosunuGuncelle;
var
  AK1, AK2: TARPKayit;
  YasamSuresi: TSayi4;
  i, j: TSayi4;
  KayitSilindi: Boolean;
begin

  while True do
  begin

    GZamanlayicilar.BekleMS(1 * CALISMA_FREKANSI);

//    while KritikBolgeyeGir(ARPTabloKilit) = False do;

    KayitSilindi := False;

    // kayýtlarý güncelle
    if(GARPTablosu.ToplamKayit > 0) then
    begin

      for i := 0 to GARPTablosu.ToplamKayit - 1 do
      begin

        AK1 := GARPTablosu.ARPKayit[i];
        if not(AK1 = nil) then
        begin

          YasamSuresi := AK1.YasamSuresi;
          Dec(YasamSuresi);
          AK1.YasamSuresi := YasamSuresi;

          // yaþam süresi 0 olduðunda kaydý sil ve listeden çýkar
          if(YasamSuresi = 0) then
          begin

            AK1.Destroy;
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

        AK1 := GARPTablosu.ARPKayit[i];
        if not(AK1 = nil) then
        begin

          for j := 0 to i - 1 do
          begin

            AK2 := GARPTablosu.ARPKayit[j];
            if(AK2 = nil) then
            begin

              GARPTablosu.ARPKayit[j] := AK1;
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
  ayný að kýsmýnda bulunan bilgisayarlara arp sorgusu gönderir
  bilgi: iþlev, çekirdeðe baðlý ayrý bir görev olarak çalýþmaktadýr
 ==============================================================================}
procedure TARPTablosu.CihazlaraARPMesajiGonder;
var
  A: TARP;
  IP4Adres: TIP4Adres;
  i: TSayi4;
begin

  // ip alýmýnýn gerçekleþmesi için 5 saniye bekle
  GZamanlayicilar.BekleMS(5 * CALISMA_FREKANSI);

  // bilgisayarýn ip adresi
  IP4Adres := GAgBaglantilari.AktifBaglanti.IP4Adresim;

  A := TARP.Create(FBaglanti);

  i := 0;

  while True do
  begin

    GZamanlayicilar.BekleMS(1 * CALISMA_FREKANSI);

    if(GAgBaglantilari.AktifBaglanti.IP4AdresiAlindi) then
    begin

      if(i = 0) then
        SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Aðdaki cihazlara ARP mesajý gönderiliyor...', []);

      IP4Adres[3] := i;

      // kendi ip adresimin haricinde tüm cihazlara arp istek mesajý gönder
      if not(IPKarsilastir(GAgBaglantilari.AktifBaglanti.IP4Adresim, IP4Adres)) then
        A.IstekGonder(arpIstek, nil, @IP4Adres);

      Inc(i);

      if(i > 255) then i := 0;
    end;
  end;

  A.Destroy;
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
  AK: TARPKayit;
  i, j: TSayi4;
begin

  // arp tabolsunda ip karþýlýðý olan mac adresleri var ise kontrol et
  if(ToplamKayit > 0) then
  begin

    for i := 0 to AZAMI_ARPKAYITSAYISI - 1 do
    begin

      AK := ARPKayit[i];

      // ARP kaydý mevcut ise çaðýran iþleve geri döndür
      if not(AK = nil) then
        if(IPKarsilastir(AK.IP4Adres, AIP4Adres)) then Exit(AK.MACAdres);
    end;
  end;

  // istenen ip adresinin mac adresini sorgula
  for i := 1 to 10 do
  begin

    // ip adresinin mac adresi tabloda bulunamadýðý için istek gönder
    A := TARP.Create(FBaglanti);
    A.IstekGonder(arpIstek, nil, @AIP4Adres);
    A.Destroy;

    // 1 saniye bekle
    GZamanlayicilar.BekleMS(1 * CALISMA_FREKANSI);

    ElleGorevDegistir;

    // yeniden tabloyu kontrol et
    if(ToplamKayit > 0) then
    begin

      for j := 0 to AZAMI_ARPKAYITSAYISI - 1 do
      begin

        AK := ARPKayit[j];

        // ARP kaydý mevcut ise çaðýran iþleve geri döndür
        if not(AK = nil) then if(IPKarsilastir(AK.IP4Adres, AIP4Adres)) then
          Exit(AK.MACAdres);
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
  AK: TARPKayit;
begin

//  while KritikBolgeyeGir(ARPTabloKilit) = False do;

  // ARP tablosunda silinen kayýtlar da olacaðýndan dolayý SiraNo deðiþkeni
  // gerçek sýra no'ya sahip kaydý almak için tanýmlanmý ve kullanýlmýþtýr

  if(ASiraNo >= 0) and (ASiraNo < ToplamKayit) then
  begin

    AK := ARPKayit[ASiraNo];
    if not(AK = nil) then
    begin

      AHedefBellek^.IP4Adres := AK.IP4Adres;
      AHedefBellek^.MACAdres := AK.MACAdres;
      AHedefBellek^.YasamSuresi := AK.YasamSuresi;

      Result := HATA_YOK;

//      KritikBolgedenCik(ARPTabloKilit);
      Exit;
    end else Result := HATA_DEGERARALIKDISI;

  end else Result := HATA_DEGERARALIKDISI;

//  KritikBolgedenCik(ARPTabloKilit);
end;

end.
