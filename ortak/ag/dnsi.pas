{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: dnsi.pas
  Dosya İşlevi: dns istemci tutanak işlevlerini yönetir

  Güncelleme Tarihi: 22/06/2026

 ==============================================================================}
{$mode objfpc}
unit dnsi;

interface

uses paylasim, baglantilar, udp;

const
  DNS_PORTNO            = 53;

  // indy bileşeninden alınan sabitler
  // bilgi: ileride bu sabit / işlevler indy bileşenine adapte edilecek
  TypeCode_A            = 1;

  Class_IN              = 1;

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
  PDNSIServis = ^TDNSIServis;
  TDNSIServis = class
  public
    FKimlik: TKimlik;
    FYerelPort: TSayi4;
    FYanitUzunluk: TSayi4;
    FBellekAdresi: Isaretci;
    constructor Create;
    function YeniBaglantiOlustur: TBaglanti;
    procedure Sorgula(ABKimlik: TKimlik; ADNSAdresi: string);
    function DNSBaglantiAl(AYerelPort: TSayi2): PDNSIServis;
    procedure Kapat(ADNSKimlik: TKimlik);
    procedure YokEt(ADNSKimlik: TKimlik);

    procedure VerileriIsle(AUDPPaket: PUDPPaket);
    procedure VerileriIsle0(AUDPPaket: PUDPPaket);
  end;

function DNSIletisimCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

var
  GDNSIServis: TDNSIServis;

implementation

uses donusum, islevler, sistemmesaj, gorev;

{==============================================================================
  dns protokol değişken / yapı ilk yükleme işlevlerini içerir
 ==============================================================================}
constructor TDNSIServis.Create;
begin
end;

{==============================================================================
  dns yönetim işlevlerini içerir
 ==============================================================================}
function DNSIletisimCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  B: TBaglanti;
  DNS: PDNSIServis;
  Hedef, i: TSayi4;
begin

  // dns bağlantısı oluştur
  if(AIslevNo = 1) then
  begin

    B := GDNSIServis.YeniBaglantiOlustur;
    if(B = nil) then
      Result := HATA_KIMLIK
    else Result := B.FKimlik;
  end
  // dns adı sorgula
  else if(AIslevNo = 2) then
  begin

    i := PISayi4(ADegiskenler + 00)^;
    GDNSIServis.Sorgula(i, PKarakterKatari(PSayi4(ADegiskenler + 04)^ +
      GGorevler.FAktifGrvBelAdr)^);
  end
  // dns sorgu durumunu al
  else if(AIslevNo = 3) then
  begin

    //DNS := FDNSBaglantilari[PISayi4(ADegiskenler + 00)^];
    Result := 0; // TSayi4(DNS^.FBaglantiDurum);
  end
  // dns sorgu içeriğini al
  else if(AIslevNo = 4) then
  begin

    //DNS := FDNSBaglantilari[PISayi4(ADegiskenler + 00)^];

    //Hedef := PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr;

    // dns yanıtını ve uzunluğunu (4 byte) hedef alana kopyala
    //Tasi2(Isaretci(DNS^.FBellekAdresi + 2048), Isaretci(Hedef), DNS^.FYanitUzunluk + 4);
  end
  // bağlantıyı kapat
  else if(AIslevNo = 5) then
  begin

    //DNS := FDNSBaglantilari[PISayi4(ADegiskenler + 00)^];
    //DNS^.Kapat(DNS^.FKimlik);
  end
  // bağlantıyı yok et
  else if(AIslevNo = 6) then
  begin

    //DNS := FDNSBaglantilari[PISayi4(ADegiskenler + 00)^];
    //DNS^.YokEt(DNS^.FKimlik);
  end

  else Result := HATA_ISLEV;
end;

{==============================================================================
  sisteme gelen tüm DNS yanıtlarını işle ve ilgili girişlere yönlendir
 ==============================================================================}
procedure TDNSIServis.VerileriIsle(AUDPPaket: PUDPPaket);
var
  DNS: PDNSIServis;
  HedefPort, Uzunluk: TSayi2;
  B4: PSayi4;
begin

  HedefPort := ntohs(AUDPPaket^.UzakPort);
  Uzunluk := ntohs(AUDPPaket^.Uzunluk) - 8;

  DNS := DNS^.DNSBaglantiAl(HedefPort);
  if not(DNS = nil) then
  begin

    B4 := PSayi4(DNS^.FBellekAdresi + 2048);
    B4^ := Uzunluk;

    Tasi2(@AUDPPaket^.Veri, PSayi4(DNS^.FBellekAdresi + 2048 + 4), Uzunluk);

    DNS^.FYanitUzunluk := Uzunluk;
    //DNS^.FBaglantiDurum := ddSorgulandi;
    //B.FGDeger1
  end;
end;

{==============================================================================
  sisteme gelen tüm DNS yanıtlarını işle ve ilgili girişlere yönlendir
 ==============================================================================}
procedure TDNSIServis.VerileriIsle0(AUDPPaket: PUDPPaket);
var
  DNS: PDNSIServis;
  HedefPort, Uzunluk: TSayi2;
  B4: PSayi4;
begin

  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'DAAAAT', []);

  {HedefPort := ntohs(AUDPPaket^.HedefPort);
  Uzunluk := ntohs(AUDPPaket^.Uzunluk) - 8;

  DNS := DNS^.DNSBaglantiAl(HedefPort);
  if not(DNS = nil) then
  begin

    B4 := PSayi4(DNS^.FBellekAdresi + 2048);
    B4^ := Uzunluk;

    Tasi2(@AUDPPaket^.Veri, PSayi4(DNS^.FBellekAdresi + 2048 + 4), Uzunluk);

    DNS^.FYanitUzunluk := Uzunluk;
    DNS^.FBaglantiDurum := ddSorgulandi;
  end;}
end;

{==============================================================================
  dns bağlantısı oluştur
 ==============================================================================}
function TDNSIServis.YeniBaglantiOlustur: TBaglanti;
var
  i: TSayi4;
begin

  i := GAgBaglantilari.YerelPortOlustur;

  Result := GAgBaglantilari.AB.BaglantiOlustur(bnDNSi, itIP4, btAktif, ptUDP, '',
    i, DNS_PORTNO);
end;

{==============================================================================
  DNS sunucusuna sorgu gönder
 ==============================================================================}
procedure TDNSIServis.Sorgula(ABKimlik: TKimlik; ADNSAdresi: string);
const
  IP4Adres2: TIP4Adres = (8, 8, 8, 8);
  //IP4Adres2: TIP4Adres = (192, 168, 1, 1);
  P: TMACAdres = ($50, $ff, $20, $6c, $8f, $e1);
  //P: TMACAdres = ($08, $00, $ab, $cd, $ef, $02);
var
  DNSPaket: PDNSPaket;
  B1, ParcaUzunlukBellek: PSayi1;
  B2: PSayi2;
  K: Char;
  i, DNSAdresUzunluk, ToplamUzunluk: TSayi4;
  ParcaUzunluk: TSayi1;
  IP4Adres: string;
  B: TBaglanti;
begin

  B := GAgBaglantilari.AB.Baglanti[ABKimlik];

  if(B.FGDeger1 = 0) then
  begin

    DNSPaket := PDNSPaket(FBellekAdresi);

    // 12 bytelık veri
	  DNSPaket^.Tanimlayici := ntohs(TSayi2($1234 + FKimlik));
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

    //IP4Adres := IP_KarakterKatari4(GAgBaglantilari.AB.DNSSunucusu);

    {DNS^.FBaglanti := GAgBaglantilari.AB.BaglantiOlustur(itIP4, btAktif, ptUDP, IP4Adres,
      DNS^.FYerelPort, DNS_PORTNO);}

    //SISTEM_MESAJ(mtHata, RENK_SIYAH, 'B: %d', [DNS^.FKimlik]);

    //if not(DNS^.FBaglanti = nil) then
    begin

      //DNS^.FKimlik := DNS^.FBaglanti.Kimlik;

      { TODO - btYayin'dan btIP değerine çekilecek }
      //if(DNS^.FBaglanti.Baglan(btIP) <> -1) then
      //begin

      //SISTEM_MESAJ_IP4(mtBilgi, RENK_KIRMIZI, 'I: ', B.FAB.IP4Adresim);

      {B.FUDP.FIP4.FHedefMACAdres := P;
      B.FUDP.FIP4.FKaynakIPAdres := B.FAB.IP4Adresim;
      B.FUDP.FIP4.FHedefIPAdres := IP4Adres2;
      B.FUDP.PaketleVeGonder(DNSPaket, 12 + ToplamUzunluk + 4);}

        //FBaglantiDurum := ddSorgulaniyor;
      //end;
    end;
  end;
end;

{==============================================================================
  DNS bağlantısını kapat
 ==============================================================================}
procedure TDNSIServis.Kapat(ADNSKimlik: TKimlik);
var
  DNS: PDNSIServis;
begin

  //DNS := FDNSBaglantilari[ADNSKimlik];

  //DNS^.FBaglantiDurum := ddHazir;
end;

{==============================================================================
  DNS bağlantısını yok et
 ==============================================================================}
procedure TDNSIServis.YokEt(ADNSKimlik: TKimlik);
var
  DNS: PDNSIServis;
begin

  {DNS := FDNSBaglantilari[ADNSKimlik];

  DNS^.FBaglantiDurum := ddOlusturuldu;
  DNS^.FBaglanti.BaglantiyiKes;

  FreeMem(DNS^.FBellekAdresi, 4096);}
end;

{==============================================================================
  yerel portun sahibi olan DNS bağlantısını alır
 ==============================================================================}
function TDNSIServis.DNSBaglantiAl(AYerelPort: TSayi2): PDNSIServis;
var
  DNS: PDNSIServis;
  i: TSayi4;
begin

  // tüm işlem girişlerini incele
  {for i := 0 to USTSINIR_DNSBAGLANTI - 1 do
  begin

    DNS := FDNSBaglantilari[i];
    if(DNS^.FYerelPort = AYerelPort) then Exit(DNS);
  end;}

  Result := nil;
end;

end.
