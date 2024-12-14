{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: dns.pas
  Dosya İşlevi: dns protokol istemci işlevlerini yönetir

  Güncelleme Tarihi: 16/09/2024

 ==============================================================================}
{$mode objfpc}
unit dns;

interface

uses paylasim, iletisim;

const
  USTSINIR_DNSBAGLANTI = 16;
  DNS_PORTNO  = 53;

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

function DNSIletisimCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
procedure Yukle;
procedure DNSPaketleriniIsle(AUDPPaket: PUDPPaket);

implementation

uses genel, donusum, sistemmesaj;

{==============================================================================
  dns yönetim işlevlerini içerir
 ==============================================================================}
function DNSIletisimCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  _DNS: PDNS;
  Hedef, i: TSayi4;
begin

  // dns bağlantısı oluştur
  if(AIslevNo = 1) then
  begin

    _DNS := _DNS^.Olustur;
    if(_DNS = nil) then
      Result := HATA_KIMLIK
    else Result := _DNS^.FKimlik;
  end
  // dns adı sorgula
  else if(AIslevNo = 2) then
  begin

    i := PISayi4(ADegiskenler + 00)^;
    _DNS := DNSListesi[i];
    _DNS^.Sorgula(i, PKarakterKatari(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi)^);
  end
  // dns sorgu durumunu al
  else if(AIslevNo = 3) then
  begin

    _DNS := DNSListesi[PISayi4(ADegiskenler + 00)^];
    Result := TSayi4(_DNS^.FBaglantiDurum);
  end
  // dns sorgu içeriğini al
  else if(AIslevNo = 4) then
  begin

    _DNS := DNSListesi[PISayi4(ADegiskenler + 00)^];

    Hedef := PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi;

    // dns yanıtını ve uzunluğunu (4 byte) hedef alana kopyala
    Tasi2(Isaretci(_DNS^.FBellekAdresi + 2048), Isaretci(Hedef), _DNS^.FYanitUzunluk + 4);
  end
  // bağlantıyı kapat
  else if(AIslevNo = 5) then
  begin

    _DNS := DNSListesi[PISayi4(ADegiskenler + 00)^];
    _DNS^.Kapat(_DNS^.FKimlik);
  end
  // bağlantıyı yok et
  else if(AIslevNo = 6) then
  begin

    _DNS := DNSListesi[PISayi4(ADegiskenler + 00)^];
    _DNS^.YokEt(_DNS^.FKimlik);
  end

  else Result := HATA_ISLEV;
end;

{==============================================================================
  dns protokol değişken / yapı ilk yükleme işlevlerini içerir
 ==============================================================================}
procedure Yukle;
var
  _DNS: PDNS;
  i: TSayi4;
begin

  // dns bilgilerinin yerleştirilmesi için bellek ayır
  _DNS := GGercekBellek.Ayir(SizeOf(TDNS) * USTSINIR_DNSBAGLANTI);

  // bellek girişlerini dizi girişleriyle eşleştir
  for i := 1 to USTSINIR_DNSBAGLANTI do
  begin

    DNSListesi[i] := _DNS;

    // işlemi boş olarak belirle
    _DNS^.FBaglantiDurum := ddOlusturuldu;
    _DNS^.FKimlik := i;

    Inc(_DNS);
  end;
end;

{==============================================================================
  dns bağlantısı oluştur
 ==============================================================================}
function TDNS.Olustur: PDNS;
var
  _DNS: PDNS;
begin

  _DNS := nil;

  _DNS := YeniBaglantiOlustur;
  if(_DNS <> nil) then
  begin


    _DNS^.FYerelPort := YerelPortAl;
    _DNS^.FBellekAdresi := GGercekBellek.Ayir(4095);
    _DNS^.FYanitUzunluk := 0;

    //SISTEM_MESAJ(RENK_KIRMIZI, 'DNS.PP: Yerel Port: %d', [_DNS^.FYerelPort]);
    //SISTEM_MESAJ(RENK_KIRMIZI, 'DNS.PP: Bellek Adresi: %x', [TSayi4(_DNS^.FBellekAdresi)]);
    //SISTEM_MESAJ(RENK_KIRMIZI, 'DNS.PP: DNS Kimlik: %d', [_DNS^.FKimlik]);
  end;

  Result := _DNS;
end;

{==============================================================================
  DNS sunucusuna sorgu gönder
 ==============================================================================}
procedure TDNS.Sorgula(ADNSKimlik: TKimlik; ADNSAdresi: string);
var
  _DNSPaket: PDNSPaket;
  _B1, _ParcaUzunlukBellek: PSayi1;
  _B2: PSayi2;
  _K: Char;
  i, DNSAdresUzunluk, _ToplamUzunluk: TSayi4;
  _ParcaUzunluk: TSayi1;
  _DNS: PDNS;
begin

  //SISTEM_MESAJ(RENK_KIRMIZI, 'DNS.PP: ADNSKimlik: %d', [ADNSKimlik]);
  //SISTEM_MESAJ_YAZI(RENK_KIRMIZI, 'DNS.PP: DNS Adres: ', ADNSAdresi);

  _DNS := DNSListesi[ADNSKimlik];

  if(_DNS^.FBaglantiDurum = ddHazir) then
  begin

    _DNSPaket := PDNSPaket(_DNS^.FBellekAdresi);

    // 12 bytelık veri
	  _DNSPaket^.Tanimlayici := Takas2(TSayi2($1000 + _DNS^.FKimlik));
    _DNSPaket^.Bayrak := Takas2(TSayi2($0100));        // standard sorgu, recursion
    _DNSPaket^.SorguSayisi := Takas2(TSayi2(1));       // 1 sorgu
    _DNSPaket^.YanitSayisi := Takas2(TSayi2(0));
    _DNSPaket^.YetkiSayisi := Takas2(TSayi2(0));
    _DNSPaket^.DigerSayisi := Takas2(TSayi2(0));

    _B1 := @_DNSPaket^.Veriler;
    _ParcaUzunlukBellek := _B1;     // 1 bytelık verinin uzunluğunun adresi
    Inc(_B1);
    _ParcaUzunluk := 0;
    _ToplamUzunluk := 0;

    DNSAdresUzunluk := Length(ADNSAdresi);
    for i := 1 to DNSAdresUzunluk do
    begin

      _K := ADNSAdresi[i];

      if(_K = '.') then
      begin

        _ParcaUzunlukBellek^ := _ParcaUzunluk;
        _ParcaUzunlukBellek := _B1;
        _ToplamUzunluk += _ParcaUzunluk + 1;
        Inc(_B1);
        _ParcaUzunluk := 0;
      end
      else
      begin

        PChar(_B1)^ := _K;
        Inc(_B1);
        Inc(_ParcaUzunluk);
      end;
    end;
    _ParcaUzunlukBellek^ := _ParcaUzunluk;
    _ToplamUzunluk += _ParcaUzunluk + 1;

    _B1^ := 0;        // sıfır sonlandırma
    Inc(_ToplamUzunluk);

    Inc(_B1);
    _B2 := Isaretci(_B1);
    _B2^ := Takas2(TSayi2($0001));
    Inc(_B2);
    _B2^ := Takas2(TSayi2($0001));

    _DNS^.FBaglanti := _DNS^.FBaglanti^.Olustur(ptUDP, AgBilgisi.DNSSunucusu, _DNS^.FYerelPort,
      DNS_PORTNO);

    _DNS^.FBaglanti^.Baglan(btYayin);

    _DNS^.FBaglanti^.Yaz(@_DNSPaket[0], 12 + _ToplamUzunluk + 4);

    _DNS^.FBaglantiDurum := ddSorgulaniyor;
  end;
end;

{==============================================================================
  yeni dns bağlantısı oluştur
 ==============================================================================}
function TDNS.YeniBaglantiOlustur: PDNS;
var
  _DNS: PDNS;
  i: TSayi4;
begin

  // tüm işlem girişlerini incele
  for i := 1 to USTSINIR_DNSBAGLANTI do
  begin

    _DNS := DNSListesi[i];

    // bağlantı durumu boş ise
    if(_DNS^.FBaglantiDurum = ddOlusturuldu) then
    begin

      // bağlantıyı ayır ve çağıran işleve geri dön
      _DNS^.FBaglantiDurum := ddHazir;
      Exit(_DNS);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  DNS bağlantısını kapat
 ==============================================================================}
procedure TDNS.Kapat(ADNSKimlik: TKimlik);
var
  _DNS: PDNS;
begin

  _DNS := DNSListesi[ADNSKimlik];

  _DNS^.FBaglantiDurum := ddHazir;
end;

{==============================================================================
  DNS bağlantısını yok et
 ==============================================================================}
procedure TDNS.YokEt(ADNSKimlik: TKimlik);
var
  _DNS: PDNS;
begin

  _DNS := DNSListesi[ADNSKimlik];

  _DNS^.FBaglantiDurum := ddOlusturuldu;
  _DNS^.FBaglanti^.BaglantiyiKes;

  GGercekBellek.YokEt(_DNS^.FBellekAdresi, 4095);
end;

{==============================================================================
  sisteme gelen tüm DNS yanıtlarını işle ve ilgili girişlere yönlendir
 ==============================================================================}
procedure DNSPaketleriniIsle(AUDPPaket: PUDPPaket);
var
  _KaynakPort, _HedefPort, _Uzunluk: TSayi2;
  _B4: PSayi4;
  _DNS: PDNS;
begin

  _KaynakPort := Takas2(TSayi2(AUDPPaket^.KaynakPort));
  _HedefPort := Takas2(TSayi2(AUDPPaket^.HedefPort));
  _Uzunluk := Takas2(AUDPPaket^.Uzunluk) - 8;

{  SISTEM_MESAJ(RENK_KIRMIZI, '-------------------------', []);
  SISTEM_MESAJ(RENK_MAVI, 'UDP Kaynak Port: %d', [_KaynakPort]);
  SISTEM_MESAJ(RENK_MAVI, 'UDP Hedef Port: %d', [_HedefPort]);
  SISTEM_MESAJ(RENK_MAVI, 'UDP Veri Uzunluğu: %d', [_Uzunluk]);
  SISTEM_MESAJ(RENK_MAVI, 'UDP Sağlama Toplamı: %x', [AUDPPaket^.SaglamaToplam]); }

  _DNS := _DNS^.DNSBaglantiAl(_HedefPort);
  if not(_DNS = nil) then
  begin

    _B4 := PSayi4(_DNS^.FBellekAdresi + 2048);
    _B4^ := _Uzunluk;

    Tasi2(@AUDPPaket^.Veri, PSayi4(_DNS^.FBellekAdresi + 2048 + 4), _Uzunluk);

    _DNS^.FYanitUzunluk := _Uzunluk;
    _DNS^.FBaglantiDurum := ddSorgulandi;
  end;
end;

{==============================================================================
  yerel portun sahibi olan DNS bağlantısını alır
 ==============================================================================}
function TDNS.DNSBaglantiAl(AYerelPort: TSayi2): PDNS;
var
  _DNS: PDNS;
  i: TSayi4;
begin

  // tüm işlem girişlerini incele
  for i := 1 to USTSINIR_DNSBAGLANTI do
  begin

    _DNS := DNSListesi[i];
    if(_DNS^.FYerelPort = AYerelPort) then Exit(_DNS);
  end;

  Result := nil;
end;

end.
