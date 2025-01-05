{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: dns.pas
  Dosya İşlevi: dns protokol istemci işlevlerini yönetir

  Güncelleme Tarihi: 02/01/2025

 ==============================================================================}
{$mode objfpc}
unit dns;

interface

uses paylasim, iletisim, udp;

const
  USTSINIR_DNSBAGLANTI  = 16;
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
  PDNS = ^TDNS;
  TDNS = object
  public
    FBaglanti: PBaglanti;
    FKimlik: TKimlik;
    FYerelPort: TSayi4;
    FYanitUzunluk: TSayi4;
    FBaglantiDurum: TDNSDurum;
    FBellekAdresi: Pointer;
    function Olustur: PDNS;
    procedure Sorgula(ADNSKimlik: TKimlik; ADNSAdresi: string);
    function DNSBaglantiAl(AYerelPort: TSayi2): PDNS;
    function YeniBaglantiOlustur: PDNS;
    procedure Kapat(ADNSKimlik: TKimlik);
    procedure YokEt(ADNSKimlik: TKimlik);
  end;

procedure Yukle;
function DNSIletisimCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
procedure DNSPaketleriniIsle(AUDPPaket: PUDPPaket);

implementation

uses genel, donusum, sistemmesaj;

{==============================================================================
  dns protokol değişken / yapı ilk yükleme işlevlerini içerir
 ==============================================================================}
procedure Yukle;
var
  DNS: PDNS;
  i: TSayi4;
begin

  // dns bilgilerinin yerleştirilmesi için bellek ayır
  DNS := GGercekBellek.Ayir(SizeOf(TDNS) * USTSINIR_DNSBAGLANTI);

  // bellek girişlerini dizi girişleriyle eşleştir
  for i := 0 to USTSINIR_DNSBAGLANTI - 1 do
  begin

    GDNSBaglantilari[i] := DNS;

    // işlemi boş olarak belirle
    DNS^.FBaglantiDurum := ddOlusturuldu;
    DNS^.FKimlik := i;

    Inc(DNS);
  end;
end;

{==============================================================================
  dns yönetim işlevlerini içerir
 ==============================================================================}
function DNSIletisimCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  DNS: PDNS;
  Hedef, i: TSayi4;
begin

  // dns bağlantısı oluştur
  if(AIslevNo = 1) then
  begin

    DNS := DNS^.Olustur;
    if(DNS = nil) then
      Result := HATA_KIMLIK
    else Result := DNS^.FKimlik;
  end
  // dns adı sorgula
  else if(AIslevNo = 2) then
  begin

    i := PISayi4(ADegiskenler + 00)^;
    DNS := GDNSBaglantilari[i];
    DNS^.Sorgula(i, PKarakterKatari(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi)^);
  end
  // dns sorgu durumunu al
  else if(AIslevNo = 3) then
  begin

    DNS := GDNSBaglantilari[PISayi4(ADegiskenler + 00)^];
    Result := TSayi4(DNS^.FBaglantiDurum);
  end
  // dns sorgu içeriğini al
  else if(AIslevNo = 4) then
  begin

    DNS := GDNSBaglantilari[PISayi4(ADegiskenler + 00)^];

    Hedef := PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi;

    // dns yanıtını ve uzunluğunu (4 byte) hedef alana kopyala
    Tasi2(Isaretci(DNS^.FBellekAdresi + 2048), Isaretci(Hedef), DNS^.FYanitUzunluk + 4);
  end
  // bağlantıyı kapat
  else if(AIslevNo = 5) then
  begin

    DNS := GDNSBaglantilari[PISayi4(ADegiskenler + 00)^];
    DNS^.Kapat(DNS^.FKimlik);
  end
  // bağlantıyı yok et
  else if(AIslevNo = 6) then
  begin

    DNS := GDNSBaglantilari[PISayi4(ADegiskenler + 00)^];
    DNS^.YokEt(DNS^.FKimlik);
  end

  else Result := HATA_ISLEV;
end;

{==============================================================================
  sisteme gelen tüm DNS yanıtlarını işle ve ilgili girişlere yönlendir
 ==============================================================================}
procedure DNSPaketleriniIsle(AUDPPaket: PUDPPaket);
var
  DNS: PDNS;
  HedefPort, Uzunluk: TSayi2;
  B4: PSayi4;
begin

  HedefPort := ntohs(AUDPPaket^.HedefPort);
  Uzunluk := ntohs(AUDPPaket^.Uzunluk) - 8;

  DNS := DNS^.DNSBaglantiAl(HedefPort);
  if not(DNS = nil) then
  begin

    B4 := PSayi4(DNS^.FBellekAdresi + 2048);
    B4^ := Uzunluk;

    Tasi2(@AUDPPaket^.Veri, PSayi4(DNS^.FBellekAdresi + 2048 + 4), Uzunluk);

    DNS^.FYanitUzunluk := Uzunluk;
    DNS^.FBaglantiDurum := ddSorgulandi;
  end;
end;

{==============================================================================
  dns bağlantısı oluştur
 ==============================================================================}
function TDNS.Olustur: PDNS;
var
  DNS: PDNS;
begin

  DNS := nil;

  DNS := YeniBaglantiOlustur;
  if(DNS <> nil) then
  begin


    DNS^.FYerelPort := YerelPortAl;
    DNS^.FBellekAdresi := GGercekBellek.Ayir(4095);
    DNS^.FYanitUzunluk := 0;
  end;

  Result := DNS;
end;

{==============================================================================
  DNS sunucusuna sorgu gönder
 ==============================================================================}
procedure TDNS.Sorgula(ADNSKimlik: TKimlik; ADNSAdresi: string);
var
  DNSPaket: PDNSPaket;
  DNS: PDNS;
  B1, ParcaUzunlukBellek: PSayi1;
  B2: PSayi2;
  K: Char;
  i, DNSAdresUzunluk, ToplamUzunluk: TSayi4;
  ParcaUzunluk: TSayi1;
begin

  DNS := GDNSBaglantilari[ADNSKimlik];

  if(DNS^.FBaglantiDurum = ddHazir) then
  begin

    DNSPaket := PDNSPaket(DNS^.FBellekAdresi);

    // 12 bytelık veri
	  DNSPaket^.Tanimlayici := ntohs(TSayi2($1234 + DNS^.FKimlik));
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
        ToplamUzunluk += ParcaUzunluk + 1;
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
    ToplamUzunluk += ParcaUzunluk + 1;

    B1^ := 0;        // sıfır sonlandırma
    Inc(ToplamUzunluk);

    Inc(B1);
    B2 := Isaretci(B1);
    B2^ := ntohs(TSayi2(TypeCode_A));
    Inc(B2);
    B2^ := ntohs(TSayi2(Class_IN));

    DNS^.FBaglanti := DNS^.FBaglanti^.Olustur(ptUDP, GAgBilgisi.DNSSunucusu,
      DNS^.FYerelPort, DNS_PORTNO);
    if not(DNS^.FBaglanti = nil) then
    begin

      if(DNS^.FBaglanti^.Baglan(btYayin) <> -1) then
      begin

        DNS^.FBaglanti^.Yaz(@DNSPaket[0], 12 + ToplamUzunluk + 4);

        DNS^.FBaglantiDurum := ddSorgulaniyor;
      end;
    end;
  end;
end;

{==============================================================================
  yeni dns bağlantısı oluştur
 ==============================================================================}
function TDNS.YeniBaglantiOlustur: PDNS;
var
  DNS: PDNS;
  i: TSayi4;
begin

  // tüm işlem girişlerini incele
  for i := 0 to USTSINIR_DNSBAGLANTI - 1 do
  begin

    DNS := GDNSBaglantilari[i];

    // bağlantı durumu boş ise
    if(DNS^.FBaglantiDurum = ddOlusturuldu) then
    begin

      // bağlantıyı ayır ve çağıran işleve geri dön
      DNS^.FBaglantiDurum := ddHazir;
      Exit(DNS);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  DNS bağlantısını kapat
 ==============================================================================}
procedure TDNS.Kapat(ADNSKimlik: TKimlik);
var
  DNS: PDNS;
begin

  DNS := GDNSBaglantilari[ADNSKimlik];

  DNS^.FBaglantiDurum := ddHazir;
end;

{==============================================================================
  DNS bağlantısını yok et
 ==============================================================================}
procedure TDNS.YokEt(ADNSKimlik: TKimlik);
var
  DNS: PDNS;
begin

  DNS := GDNSBaglantilari[ADNSKimlik];

  DNS^.FBaglantiDurum := ddOlusturuldu;
  DNS^.FBaglanti^.BaglantiyiKes;

  GGercekBellek.YokEt(DNS^.FBellekAdresi, 4095);
end;

{==============================================================================
  yerel portun sahibi olan DNS bağlantısını alır
 ==============================================================================}
function TDNS.DNSBaglantiAl(AYerelPort: TSayi2): PDNS;
var
  DNS: PDNS;
  i: TSayi4;
begin

  // tüm işlem girişlerini incele
  for i := 0 to USTSINIR_DNSBAGLANTI - 1 do
  begin

    DNS := GDNSBaglantilari[i];
    if(DNS^.FYerelPort = AYerelPort) then Exit(DNS);
  end;

  Result := nil;
end;

end.
