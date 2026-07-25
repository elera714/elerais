{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: baglanti.pas
  Dosya Ýþlevi: baðlantý (soket) iletiþim yönetim iþlevlerini içerir

  Güncelleme Tarihi: 24/06/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit baglanti;

interface

uses paylasim, sistemmesaj;

const
  USTSINIR_BAGLANTI   = 64;

  TCP_PENCERE_UZUNLUK = 8192;
  ILK_YERELPORTNO     = $A00E;

  TCP_BAYRAK_SON      = $01;    // FIN
  TCP_BAYRAK_ARZ      = $02;    // SYN
  TCP_BAYRAK_SIFIRLA  = $04;    // RST
  TCP_BAYRAK_GONDER   = $08;    // PSH
  TCP_BAYRAK_KABUL    = $10;    // ACK

var
  YerelPortNo: TSayi2;
  TCPIlkSiraNo: TSayi4;

type
{
    bdYok = tcp/udp veri alanlarýnýn ilk yükleme ve tcp/bdKapaniyor2 (? teyit et) sonrasý aþamasý
    bdKapali = tcp/udp yeni baðlantý oluþturma ve udp/baðlantý kapatma sonrasý aþamasý
}

  { TODO - açýklama yapýlmayan durumlar yeniden gözden geçirilecek }
  TBaglantiDurum = (
    bdYok,
    bdKapali,
    bdBaglaniyor,


    // bdBaglantiBekleniyor (sunucu durumu - SYN-RECEIVED):
    // istemciden SYN mesajý alýnmýþ, istemciye SYN + ACK mesajý gönderilmiþtir
    bdBaglantiBekleniyor,
    // bdBaglantiKuruldu (sunucu / istemci durumu - ESTABLISHED)
    // sunucu istemci arasýndaki 3 yollu (SYN -> SYN + ACK -> ACK) anlaþma saðlanmýþtýr
    bdBaglantiKuruldu,
    // bdKapanmayiBekliyor (sunucu / istemci durumu - CLOSE-WAIT)
    // baðlantýnýn 1. ucundaki istemci / sunucudan kapatma isteðinin gelmesi durumu (FIN + ACK)
    bdKapanmayiBekliyor,
    // bdSonOnay (sunucu / istemci durumu - LAST-ACK)
    // baðlantýnýn 2. ucundaki istemci / sunucunun kapatma isteðine (FIN + ACK) onay bekleme durumu
    bdSonOnay,
    // bdKapanisBekleniyor1 (sunucu / istemci durumu - FIN-WAIT-1)
    // baðlantýnýn 1. ucundaki istemci / sunucunun kapatma isteði (FIN + ACK) gönderme durumu
    bdKapanisBekleniyor1);

  // aktif baðlantý: istemcinin sunucuya baðlantýsý
  // pasif baðlantý: sunucunun kendisine gelen istekleri kabul etmek için oluþturduðu baðlantý
  // btBelirsiz: tcp baðlantýlarýn haricindeki baðlantýlar (udp gibi)
  TBaglantiTuru = (btBelirsiz, btAktif, btPasif);

type
  PBaglanti = ^TBaglanti;
  TBaglanti = class
    Kimlik: TKimlik;
    IletisimTipi: TIletisimTipi;  // ana protokol iletiþim tipleri (þu aþamada ipv4, ipv6)
    ProtokolTipi: TProtokolTipi;
    BaglantiTuru: TBaglantiTuru;
    BaglantiDurum: TBaglantiDurum;
    PencereU: TSayi2;
    SiraNo,                       // TCP sýra no (sequence number)
    OnayNo: TSayi4;               // TCP onay no (acknowledgment number)
    HedefMACAdres: TMACAdres;

    HedefIP6Adres: TIP6Adres;     // verinin gönderileceði ip6 adresi
    HedefIP4Adres: TIP4Adres;     // verinin gönderileceði ip4 adresi

    { TODO - önemli: baðlantý her 2 taraf için de oluþturulabilir, yerel / uzak karýþabilir
      özellikle TCPBaglantiAl ve benzeri iþlevler hatalý davranabilir. tedbir alýnacak }
    YerelPort, UzakPort: TSayi2;  // baðlantý kuran cihazým yerel / uzak portu


    Bagli: Boolean;
    FBellek: Isaretci;
    FVeriUzunlugu: TSayi4;        // Bellek'te mevcut veri uzunluðu
  public
    function Baglan(AIletisimTipi: TIletisimTipi; ABaglantiTipi: TBaglantiTipi): TISayi4;
    function BagliMi: Boolean;
    procedure BellegeEkle(AKaynakBellek: Isaretci; AVeriUzunlugu: TSayi4);
    function VeriUzunlugu: TSayi4;
    function Oku(ABellek: Isaretci): TSayi4;
    procedure Yaz(APaketTipi: TSayi4; ABellek: Isaretci; AUzunluk: TISayi4);
    function BaglantiyiKes: TISayi4;
  end;

type
  PBaglantilar = ^TBaglantilar;
  TBaglantilar = class
  private
    FBaglantiListesi: array[0..USTSINIR_BAGLANTI - 1] of TBaglanti;
    function Al(ASiraNo: TISayi4): TBaglanti;
    procedure Yaz(ASiraNo: TISayi4; ABaglanti: TBaglanti);
  public
    constructor Create;
    function BaglantiOlustur(AIletisimTipi: TIletisimTipi; ABaglantiTuru: TBaglantiTuru;
      AProtokolTipi: TProtokolTipi; ABaglantiAdresi: string; AYerelPort, AUzakPort: TSayi2): TBaglanti;
    function BaglantiYapisiOlustur(ABaglantiTuru: TBaglantiTuru): TBaglanti;
    function TCPIlkSiraNoAl: TSayi4;
    function TCPBaglantiAl(AKaynakPort, AHedefPort: TSayi2): TBaglanti;
    procedure Listele;
    function UDPBaglantiAl(AYerelPort: TSayi2): TBaglanti;
    property Baglanti[ASiraNo: TISayi4]: TBaglanti read Al write Yaz;
    function YerelPortAl: TSayi2;
  end;

var
  GBaglantilar: TBaglantilar;
  BaglantilarKilit: TSayi4 = 0;

implementation

uses tcp, udp, arp, islevler, donusum;

{==============================================================================
  baðlantý nesnelerinin ana yükleme iþlevlerini içerir
 ==============================================================================}
constructor TBaglantilar.Create;
var
  i: TSayi4;
begin

  // baðlantý yapýlarýný ilk deðerlerle yükle
  for i := 0 to USTSINIR_BAGLANTI - 1 do Baglanti[i] := nil;

  TCPIlkSiraNo := $10001000;
  YerelPortNo := ILK_YERELPORTNO;
end;

function TBaglantilar.Al(ASiraNo: TISayi4): TBaglanti;
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_BAGLANTI) then
    Result := FBaglantiListesi[ASiraNo]
  else Result := nil;
end;

procedure TBaglantilar.Yaz(ASiraNo: TISayi4; ABaglanti: TBaglanti);
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_BAGLANTI) then
    FBaglantiListesi[ASiraNo] := ABaglanti;
end;

{==============================================================================
  að baðlantýsý için baðlantý oluþturur
 ==============================================================================}
function TBaglantilar.BaglantiOlustur(AIletisimTipi: TIletisimTipi; ABaglantiTuru: TBaglantiTuru;
  AProtokolTipi: TProtokolTipi; ABaglantiAdresi: string; AYerelPort, AUzakPort: TSayi2): TBaglanti;
var
  B: TBaglanti;
  s, SunucuAdi,
  Sayfa: string;
  i: TSayi4;
  IP6Adresi: TIP6Adres;
  IP4Adresi: TIP4Adres;
begin

//  while KritikBolgeyeGir(BaglantilarKilit) = False do;

  B := BaglantiYapisiOlustur(ABaglantiTuru);
  if(B = nil) then Exit(nil);

  // ABaglantiAdresi içeriði aþaðýdaki biçimde gelmekte olup bu yapýnýn "/" sonrasý
  // ne burada ne de çekirdeðin hiçbir yerinde kullanýlmamaktadýr.
  { TODO - ileride http(s) protokolünde kullanýlma ihtimali mevcuttur }
  // 192.168.1.1/search?q=elerais
  i := Pos('/', ABaglantiAdresi);
  if(i > 0) then
  begin

    SunucuAdi := Copy(ABaglantiAdresi, 1, i - 1);
    Sayfa := Copy(ABaglantiAdresi, i, Length(ABaglantiAdresi) - i + 1);
  end
  else
  begin

    SunucuAdi := ABaglantiAdresi;
    Sayfa := '/';
  end;

  B.Bagli := False;
  B.IletisimTipi := AIletisimTipi;

  if(AIletisimTipi = itIP6) then
  begin

    IP6Adresi := StrToIP6(SunucuAdi);
    B.HedefIP6Adres := IP6Adresi;
  end
  else
  begin

    IP4Adresi := StrToIP4(SunucuAdi);
    B.HedefIP4Adres := IP4Adresi;
  end;

  B.ProtokolTipi := AProtokolTipi;
  B.YerelPort := AYerelPort;
  B.UzakPort := AUzakPort;

  if(AProtokolTipi = ptTCP) then
  begin

    B.PencereU := TCP_PENCERE_UZUNLUK;
    B.SiraNo := TCPIlkSiraNoAl;
    B.OnayNo := 0;

    B.FVeriUzunlugu := 0;
    B.FBellek := GetMem(4 * 4096); //Bag^.FPencereU);
    if(B.FBellek = nil) then SISTEM_MESAJ(mtHata, RENK_SIYAH, 'BAGLANTI.PAS: Bellek yok', []);
  end
  else if(AProtokolTipi = ptUDP) then
  begin

    B.FVeriUzunlugu := 0;
    B.FBellek := GetMem(4 * 4096);

    {SISTEM_MESAJ(mtBilgi, RENK_MOR, 'BAGLANTI.PAS: Protokol -> UDP', []);
    SISTEM_MESAJ(mtBilgi, RENK_MOR, 'BAGLANTI.PAS: Kimlik %d', [B^.Kimlik]);
    SISTEM_MESAJ_IP4(mtBilgi, RENK_LACIVERT, 'Hedef IP: ', IPAdresi);
    SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Kaynak Port: %d', [AYerelPort]);
    SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Hedef Port: %d', [AUzakPort]);}
  end
  else
  begin

    s := ProtokolTipAdi(AProtokolTipi);
    SISTEM_MESAJ(mtHata, RENK_PEMBE, 'BAGLANTI.PAS: TBaglantilar.BaglantiOlustur', []);
    SISTEM_MESAJ(mtHata, RENK_TURKUAZ, '  - Bilinmeyen Protokol: %s ', [s]);
    if(AIletisimTipi = itIP6) then
      SISTEM_MESAJ_IP6(mtHata, RENK_TURKUAZ, '  - Hedef IP: ', IP6Adresi)
    else SISTEM_MESAJ_IP4(mtHata, RENK_TURKUAZ, '  - Hedef IP: ', IP4Adresi);
    SISTEM_MESAJ(mtHata, RENK_TURKUAZ, '  - Hedef Port: %d', [AUzakPort]);
  end;

  Result := B;

//  KritikBolgedenCik(BaglantilarKilit);
end;

{==============================================================================
  yeni baðlantý için gerekli yapýlarý oluþturur
 ==============================================================================}
function TBaglantilar.BaglantiYapisiOlustur(ABaglantiTuru: TBaglantiTuru): TBaglanti;
var
  B: TBaglanti;
  i: TSayi4;
begin

  // kullanýlmayan baðlantý varsa tespit et ve
  // gerekli bellek ve atama iþlemlerini gerçekleþtir
  for i := 0 to USTSINIR_BAGLANTI - 1 do
  begin

    if(Baglanti[i] = nil) then
    begin

      B := TBaglanti.Create;

      Baglanti[i] := B;

      B.BaglantiTuru := ABaglantiTuru;
      B.BaglantiDurum := bdYok;
      B.Kimlik := i;
      B.BaglantiDurum := bdKapali;

      B.FBellek := nil;

      Exit(B);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  TCP veri alýþveriþinin gerçekleþmesi için gereken ilk sýra numarasýný alýr
 ==============================================================================}
function TBaglantilar.TCPIlkSiraNoAl: TSayi4;
begin

  Result := TCPIlkSiraNo;
  Inc(TCPIlkSiraNo, 10);
end;

{==============================================================================
  tcp kaynak / hedef portun sahibi olan baðlantýyý alýr
 ==============================================================================}
function TBaglantilar.TCPBaglantiAl(AKaynakPort, AHedefPort: TSayi2): TBaglanti;
var
  B: TBaglanti;
  i: TSayi4;
begin

  // tüm iþlem giriþlerini incele
  for i := 0 to USTSINIR_BAGLANTI - 1 do
  begin
    { TODO - aktif / pasif baðlantýya göre deðikenler yön deðiþtirecek }
    B := Baglanti[i];
    if not(B = nil) and {not(B.BaglantiDurum = bdYok) and} (B.YerelPort = AKaynakPort) and
      (B.UzakPort = AHedefPort) then Exit(B);
  end;

  Result := nil;
end;

procedure TBaglantilar.Listele;
var
  B: TBaglanti;
  i: TSayi4;
begin

  // tüm iþlem giriþlerini incele
  for i := 0 to USTSINIR_BAGLANTI - 1 do
  begin

    B := Baglanti[i];
    if not(B = nil) then
      SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'Kaynak: %d, Hedef: %d', [B.YerelPort, B.UzakPort]);
  end;
end;

{==============================================================================
  udp yerel portun sahibi olan baðlantýyý alýr
 ==============================================================================}
function TBaglantilar.UDPBaglantiAl(AYerelPort: TSayi2): TBaglanti;
var
  B: TBaglanti;
  i: TSayi4;
begin

  // tüm iþlem giriþlerini incele
  for i := 0 to USTSINIR_BAGLANTI - 1 do
  begin

    B := Baglanti[i];
    if not(B.BaglantiDurum = bdYok) and (B.YerelPort = AYerelPort) then
      Exit(B);
  end;

  Result := nil;
end;

{==============================================================================
  yerel port numarasý üretir
 ==============================================================================}
function TBaglantilar.YerelPortAl: TSayi2;
begin

  Inc(YerelPortNo);
  if(YerelPortNo > $FDE8 {65000}) then YerelPortNo := ILK_YERELPORTNO;
  Result := YerelPortNo;
end;

{==============================================================================
  oluþturulan baðlantý üzerinden uzaktaki sisteme baðlantý kurar
 ==============================================================================}
function TBaglanti.Baglan(AIletisimTipi: TIletisimTipi; ABaglantiTipi: TBaglantiTipi): TISayi4;
begin

  if(ProtokolTipi = ptUDP) then
  begin

    if(ABaglantiTipi = btYayin) then
    begin

      HedefMACAdres := MACAdres255;
      Bagli := True;
      Exit(Kimlik);
    end
    else
    begin

      { TODO - ip v6'ya göre düzenlenecek }
      if(IPAdresiAyniAgdaMi(HedefIP4Adres)) then
        HedefMACAdres := ARPKayitlar0.MACAdresiAl(HedefIP4Adres)
      else HedefMACAdres := ARPKayitlar0.MACAdresiAl(GAgBilgisi.DNSSunucusu);

      Bagli := True;
      Exit(Kimlik);
    end;
  end
  else if(ProtokolTipi = ptTCP) then
  begin

    if(BaglantiDurum = bdKapali) then
    begin

      { TODO - ip v6'ya göre düzenlenecek }
      if(IPAdresiAyniAgdaMi(HedefIP4Adres)) then
        HedefMACAdres := ARPKayitlar0.MACAdresiAl(HedefIP4Adres)
      else HedefMACAdres := ARPKayitlar0.MACAdresiAl(GAgBilgisi.DNSSunucusu);

      // ilk paket olan SYN (ARZ) paketi gönderiliyor
      if(AIletisimTipi = itIP6) then
      begin end
      else TCPPaketGonder(PROTOKOL_IP4, Self, TCP_BAYRAK_ARZ, @TCP4SYNSonEk, 12, True);
      BaglantiDurum := bdBaglaniyor;
      Exit(Kimlik);
    end;
  end;

  Result := -1;
end;

{==============================================================================
  baðlantýnýn var olup olmadýðýný kontrol eder
 ==============================================================================}
function TBaglanti.BagliMi: Boolean;
begin

  Result := False;

  // baðlantýyý al
  if(ProtokolTipi = ptUDP) then

    Result := Bagli

  else if(ProtokolTipi = ptTCP) then

    if(BaglantiDurum = bdBaglantiKuruldu) then Result := True
end;

{==============================================================================
  baðlantý kurulan bilgisayardan gelen verileri programýn kullanmasý için belleðe kaydeder
 ==============================================================================}
procedure TBaglanti.BellegeEkle(AKaynakBellek: Isaretci; AVeriUzunlugu: TSayi4);
var
  p: PChar;
  i: TSayi4;
begin

  if(AVeriUzunlugu = 0) then Exit;

  if(VeriUzunlugu + AVeriUzunlugu < (4 * 4096)) then
  begin

    p := FBellek + VeriUzunlugu;

    Tasi2(AKaynakBellek, p, AVeriUzunlugu);
    i := VeriUzunlugu;
    i := i + AVeriUzunlugu;
    FVeriUzunlugu := i;
  end;
end;

{==============================================================================
  baðlantý kurulan cihazdan gelip iþlenmeyi bekleyen veri miktarýný alýr
 ==============================================================================}
function TBaglanti.VeriUzunlugu: TSayi4;
begin

  Result := FVeriUzunlugu;
end;

{==============================================================================
  baðlantý üzerinden gelen veriyi ilgili programa yönlendirir
 ==============================================================================}
function TBaglanti.Oku(ABellek: Isaretci): TSayi4;
var
  i: TSayi4;
begin

  i := VeriUzunlugu;
  if(i > 0) then
  begin

    Tasi2(FBellek, ABellek, i);
    Result := VeriUzunlugu;
    FVeriUzunlugu := 0;
    Exit(i);
  end;

  Result := 0;
end;

{==============================================================================
  baðlantý kurulan bilgisayara veri gönderir
 ==============================================================================}
procedure TBaglanti.Yaz(APaketTipi: TSayi4; ABellek: Isaretci; AUzunluk: TISayi4);
begin

  if(ProtokolTipi = ptTCP) then
  begin

    if(BaglantiDurum = bdBaglantiKuruldu) then
    begin

      // FPencereU := $100;
      if(APaketTipi = PROTOKOL_IP6) then
        TCPPaketGonder(APaketTipi, Self, TCP_BAYRAK_KABUL or TCP_BAYRAK_GONDER, ABellek, AUzunluk)
      else
        TCPPaketGonder(APaketTipi, Self, TCP_BAYRAK_KABUL or TCP_BAYRAK_GONDER, ABellek, AUzunluk);
    end;
  end
  else if(ProtokolTipi = ptUDP) then
  begin
    { TODO - ip v6'ya göre düzenlenecek }
    UDPPaketGonder(APaketTipi, HedefMACAdres, @GAgBilgisi.IP4Adres, @HedefIP4Adres,
      YerelPort, UzakPort, ABellek, AUzunluk);
  end
end;

{==============================================================================
  baðlantýyý kapatýr
 ==============================================================================}
function TBaglanti.BaglantiyiKes: TISayi4;
begin

  Result := -1;

  { TODO - baðlantýnýn yok edilmesi baðlantý kesilmesi (burada) aþamasýnda gerçekleþtirilebilir }

  if(ProtokolTipi = ptUDP) then
  begin

    BaglantiDurum := bdKapali;
    ProtokolTipi := ptBilinmiyor;
    HedefIP6Adres := IP6Adres0;
    HedefIP4Adres := IP4Adres0;
    YerelPort := 0;
    UzakPort := 0;

    if not(FBellek = nil) then FreeMem(FBellek, 4 * 4096);
    Bagli := False;

    Result := 0;
  end
  else if(ProtokolTipi = ptTCP) then
  begin

    if(BaglantiDurum = bdBaglantiKuruldu) then
    begin

      { TODO - düzenle }
      TCPPaketGonder(PROTOKOL_IP4, Self, TCP_BAYRAK_SON + TCP_BAYRAK_KABUL, nil, 0);

      BaglantiDurum := bdKapanisBekleniyor1;

      Result := 0;
    end;
  end;
end;

end.
