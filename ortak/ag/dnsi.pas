{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: dnsi.pas
  Dosya İşlevi: dns istemci tutanak işlevlerini yönetir

  Güncelleme Tarihi: 31/10/2026

 ==============================================================================}
{$mode objfpc}
unit dnsi;

interface

uses paylasim, udp, sunucular;

const
  DNS_PORTNO            = 53;

  // indy bileşeninden alınan sabitler
  // bilgi: ileride bu sabit / işlevler indy bileşenine adapte edilecek
  TypeCode_A            = 1;

  Class_IN              = 1;

type
  TDNSDurum = (ddOlusturuldu, ddHazir, ddSorgulaniyor, ddSorgulandi);

type
  PDNSPaket = ^TDNSPaket;
  TDNSPaket = packed record
  	Tanimlayici,
    Bayrak,
    SorguSayisi,
    YanitSayisi,
    YetkiSayisi,
    DigerSayisi: TSayi2;
    Veriler: Isaretci;
  end;

type
  PDNSi = ^TDNSi;
  TDNSi = class(TUDPIstemci)
  private
    FBaglanti: TObject;
    FUDP: TUDP;
    FDurum: TDNSDurum;      // dns sorgu durumu
    FVeriU: TSayi4;         // yanıt olarak dönen dns veri uzunluğu
  public
    constructor Create(ABaglanti: TObject);
    destructor Destroy; override;
    procedure OVeriGeldi(AEthernetPaket: PEthernetPaket); override;
    procedure AdSorgula(ADNSAdresi: string);
    procedure Kapat;
    procedure YokEt;
    procedure IcerikGoruntule(ADNSPaket: PDNSPaket);
  end;

function DNSIletisimCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function DNSBaglantisiOlustur: TObject;

implementation

uses donusum, islevler, sistemmesaj, baglantilar, gorev;

{==============================================================================
  dns yönetim işlevlerini içerir
 ==============================================================================}
function DNSIletisimCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  B: TBaglanti;
  Hedef,
  i: TSayi4;
begin

  Result := HATA_ISLEV;

  // dns bağlantısı oluştur
  if(AIslevNo = 1) then
  begin

    B := TBaglanti(DNSBaglantisiOlustur);
    if(B = nil) then
      Result := HATA_KIMLIK
    else Result := B.FKimlik;
  end

  // dns adı sorgula
  else if(AIslevNo = 2) then
  begin

    i := PSayi4(ADegiskenler + 00)^;
    B := GAgBaglantilari.AB.Baglanti[i];
    if not(B = nil) then B.FDNSi.AdSorgula(PKarakterKatari(PSayi4(ADegiskenler + 04)^ +
      GGorevler.FAktifGrvBelAdr)^);
  end

  // dns sorgu durumunu al
  else if(AIslevNo = 3) then
  begin

    i := PSayi4(ADegiskenler + 00)^;
    B := GAgBaglantilari.AB.Baglanti[i];
    if not(B = nil) then Result := Ord(B.FDNSi.FDurum);
  end

  // dns sorgu içeriğini al
  else if(AIslevNo = 4) then
  begin

    i := PSayi4(ADegiskenler + 00)^;
    B := GAgBaglantilari.AB.Baglanti[i];
    if not(B = nil) then
    begin

      // dns yanıtını hedef alana kopyala
      Hedef := PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr;
      Tasi2(@B.FBellek, Isaretci(Hedef), B.FDNSi.FVeriU);
    end;
  end

  // bağlantıyı kapat
  else if(AIslevNo = 5) then
  begin

    i := PSayi4(ADegiskenler + 00)^;
    B := GAgBaglantilari.AB.Baglanti[i];
    if not(B = nil) then B.FDNSi.Kapat;
  end

  // bağlantıyı yok et
  else if(AIslevNo = 6) then
  begin

    i := PSayi4(ADegiskenler + 00)^;
    B := GAgBaglantilari.AB.Baglanti[i];
    if not(B = nil) then B.FDNSi.YokEt;
  end;
end;

{==============================================================================
  yeni dns bağlantısı oluştur
 ==============================================================================}
function DNSBaglantisiOlustur: TObject;
var
  PortNo: TSayi4;
begin

  PortNo := GAgBaglantilari.YerelPortOlustur;

  Result := GAgBaglantilari.AB.BaglantiOlustur(bnDNSi, itIP4, btAktif, ttUDP,
    '', PortNo, DNS_PORTNO);

  if not(Result = nil) then TBaglanti(Result).FDNSi.FDurum := ddHazir;
end;

{==============================================================================
  dns tutanak nesne ilk yükleme işlevlerini içerir
 ==============================================================================}
constructor TDNSi.Create(ABaglanti: TObject);
begin

  FBaglanti := ABaglanti;

  // iletişim udp tutanağı üzerinden gerçekleşeceği için 1 adet udp
  // nesnesi oluşturuluyor
  FUDP := TUDP.Create(nil, FBaglanti, itIP4, MACAdres0);

  FDurum := ddOlusturuldu;
end;

{==============================================================================
  dns tutanak nesne yok etme işlevlerini içerir
 ==============================================================================}
destructor TDNSi.Destroy;
begin

  FUDP.Destroy;

  inherited Destroy;
end;

{==============================================================================
  dns istemcisine gelen paketleri işler
 ==============================================================================}
procedure TDNSi.OVeriGeldi(AEthernetPaket: PEthernetPaket);
var
  B: TBaglanti;
  IP4Paket: PIP4Paket;
  UDPPaket: PUDPPaket;
begin

  B := TBaglanti(FBaglanti);
  IP4Paket := PIP4Paket(@AEthernetPaket^.Veri);
  UDPPaket := PUDPPaket(@IP4Paket^.Veri);

  // dns verisinin uzunluğu
  FVeriU := ntohs(UDPPaket^.Uzunluk) - 8;

  // gelen veriyi nesne belleğine taşı
  Tasi2(@UDPPaket^.Veri, @B.FBellek, FVeriU);

  // dns sorgusuna yanıtın geldiğini bildir
  B.FDNSi.FDurum := ddSorgulandi;

  // paket verilerinin içeriğini görüntülemek için etkinleştir
  //IcerikGoruntule(@UDPPaket^.Veri);
end;

{==============================================================================
  dns sunucusuna sorgulanacak adı gönderir
 ==============================================================================}
procedure TDNSi.AdSorgula(ADNSAdresi: string);
var
  B: TBaglanti;
  DNSPaket: PDNSPaket;
  MACAdres: TMACAdres;
  B1, ParcaUzunlukBellek: PSayi1;
  B2: PSayi2;
  K: Char;
  i, DNSAdresUzunluk,
  ToplamUzunluk: TSayi4;
  ParcaUzunluk: TSayi1;
begin

  B := TBaglanti(FBaglanti);

  if(FDurum = ddHazir) then
  begin

    DNSPaket := PDNSPaket(B.FBellek);

    // 12 bytelık veri
	  DNSPaket^.Tanimlayici := ntohs(TSayi2($1234 + B.FKimlik));
    DNSPaket^.Bayrak := ntohs(TSayi2($0100));       // standard sorgu, recursion
    DNSPaket^.SorguSayisi := ntohs(TSayi2(1));      // sorgu sayısı = 1
    DNSPaket^.YanitSayisi := ntohs(TSayi2(0));
    DNSPaket^.YetkiSayisi := ntohs(TSayi2(0));
    DNSPaket^.DigerSayisi := ntohs(TSayi2(0));

    B1 := @DNSPaket^.Veriler;
    ParcaUzunlukBellek := B1;     // 1 bytelık verinin uzunluğunun adresi
    Inc(B1);
    ParcaUzunluk := 0;
    ToplamUzunluk := 0;

    DNSAdresUzunluk := Length(ADNSAdresi);
    for i := 1 to DNSAdresUzunluk do
    begin

      K := ADNSAdresi[i];

      if(K = '.') then
      begin

        ParcaUzunlukBellek^ := ParcaUzunluk;
        ParcaUzunlukBellek := B1;
        ToplamUzunluk := ToplamUzunluk + ParcaUzunluk + 1;
        Inc(B1);
        ParcaUzunluk := 0;
      end
      else
      begin

        PChar(B1)^ := K;
        Inc(B1);
        Inc(ParcaUzunluk);
      end;
    end;
    ParcaUzunlukBellek^ := ParcaUzunluk;
    ToplamUzunluk := ToplamUzunluk + ParcaUzunluk + 1;

    B1^ := 0;        // sıfır sonlandırma
    Inc(ToplamUzunluk);

    Inc(B1);
    B2 := Isaretci(B1);
    B2^ := ntohs(TSayi2(TypeCode_A));
    Inc(B2);
    B2^ := ntohs(TSayi2(Class_IN));

    // ağ geçidinin mac adresini al
    MACAdres := GAgBaglantilari.AB.FARP.MACAdresAl(GAgBaglantilari.AB.AgGecitAdresi);

    // dns adresi tanımlandıysa, sorguyu dns sunucusuna gönder
    if not(IPKarsilastir(GAgBaglantilari.AB.DNSSunucusu, IP4Adres0)) then
    begin

      FUDP.FIP4.FHedefMACAdres := MACAdres;
      FUDP.FIP4.FKaynakIPAdres := B.FAB.IP4Adresim;
      FUDP.FIP4.FHedefIPAdres := GAgBaglantilari.AB.DNSSunucusu;
      FUDP.PaketleVeGonder(DNSPaket, 12 + ToplamUzunluk + 4);

      FDurum := ddSorgulaniyor;
    end;
  end;
end;

{==============================================================================
  dns bağlantısını kapatır
 ==============================================================================}
procedure TDNSi.Kapat;
begin

  FDurum := ddHazir;
end;

{==============================================================================
  dns bağlantısını yok eder
 ==============================================================================}
procedure TDNSi.YokEt;
begin

  GAgBaglantilari.AB.BaglantiyiYoket(TBaglanti(FBaglanti));
end;

procedure TDNSi.IcerikGoruntule(ADNSPaket: PDNSPaket);
var
  FQDCount,                 // sorgu sayısı
  FANCount,                 // yanıt sayısı
  FNSCount,                 // yetki sayısı - authority
  FARCount: TSayi2;         // diğer sayısı - additional
  FName: string;            // dns adı
  FRecType,                 // kayıt tipi
  FRecClass: TSayi2;        // kayıt sınıfı
  FTTL: TSayi4;             // yaşam ömrü
  FRData: TIP4Adres;        // ip adres

  DNSBolum: TSayi4;
  Veri1: PByte;
  Veri1U, i: TSayi1;
  Veri2: PSayi2;
  Veri4: PSayi4;
begin

  FQDCount := ntohs(ADNSPaket^.SorguSayisi);
  FANCount := ntohs(ADNSPaket^.YanitSayisi);
  FNSCount := ntohs(ADNSPaket^.YetkiSayisi);
  FARCount := ntohs(ADNSPaket^.DigerSayisi);

  DNSBolum := 0;        // dns adresindeki her bir bölüm
  FName := '';

  // örnek dns adres verisi: [6]google[3]com[0]
  // bilgi: [] arasındaki veri sayısal byte türünde veridir.

  Veri1 := @ADNSPaket^.Veriler;
  while Veri1^ <> 0 do
  begin

    if(DNSBolum > 0) then FName := FName + '.';

    Veri1U := Veri1^;     // kaydın uzunluğu
    Inc(Veri1);
    i := 0;
    while i < Veri1U do
    begin

      FName := FName + Char(Veri1^);
      Inc(Veri1);
      Inc(i);
      Inc(DNSBolum);
    end;
  end;
  Inc(Veri1);

  Veri2 := PSayi2(Veri1);
  Inc(Veri2);
  Inc(Veri2);
  Inc(Veri2);

  FRecType := ntohs(Veri2^);
  Inc(Veri2);
  FRecClass := ntohs(Veri2^);
  Inc(Veri2);

  Veri4 := PSayi4(Veri2);
  FTTL := ntohs(PSayi4(Veri4)^);
  Inc(Veri4);

  Veri2 := PSayi2(Veri4);
  // uzunluk verisi - gözardı ediliyor
  Inc(Veri2);

  Veri1 := PSayi1(Veri2);

  FRData[0] := Veri1^;
  Inc(Veri1);
  FRData[1] := Veri1^;
  Inc(Veri1);
  FRData[2] := Veri1^;
  Inc(Veri1);
  FRData[3] := Veri1^;

  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'FQDCount: %d', [FQDCount]);
  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'FANCount: %d', [FANCount]);
  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'FNSCount: %d', [FNSCount]);
  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'FARCount: %d', [FARCount]);

  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'FRecType: %d', [FRecType]);
  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'FRecClass: %d', [FRecClass]);
  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'FTTL: %d', [FTTL]);

  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'FName: %s', [FName]);
  SISTEM_MESAJ_IP4(mtBilgi, RENK_KIRMIZI, 'IP: ', FRData);
end;

end.
