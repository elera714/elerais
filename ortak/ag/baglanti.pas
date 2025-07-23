{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: baglanti.pas
  Dosya Ýþlevi: baðlantý (soket) iletiþim yönetim iþlevlerini içerir

  Güncelleme Tarihi: 13/07/2025

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

  TCP_BAYRAK_SON      = $01;
  TCP_BAYRAK_ARZ      = $02;    // SYN
  TCP_BAYRAK_GONDER   = $08;
  TCP_BAYRAK_KABUL    = $10;    // ACK

var
  YerelPortNo: TSayi2;
  TCPIlkSiraNo: TSayi4;

type
{
    bdYok = tcp/udp veri alanlarýnýn ilk yükleme ve tcp/bdKapaniyor2 (? teyit et) sonrasý aþamasý
    bdKapali = tcp/udp yeni baðlantý oluþturma ve udp/baðlantý kapatma sonrasý aþamasý
    bdKapaniyor1 = istemcinin sunucuya gönderdiði FIN + ACK durumu
    bdKapaniyor2 = sunucunun istemciye gönderdiði FIN + ACK durumu
}
  TBaglantiDurum = (bdYok, bdKapali, bdBaglaniyor, bdBaglandi, bdKapaniyor1);

type
  PBaglanti = ^TBaglanti;
  TBaglanti = record
    Kimlik: TKimlik;
    BaglantiDurum: TBaglantiDurum;
    ProtokolTipi: TProtokolTipi;
    PencereU: TSayi2;
    SiraNo,                      // TCP sýra no (sequence number)
    OnayNo: TSayi4;              // TCP onay no (acknowledgment number)
    HedefMACAdres: TMACAdres;
    HedefIPAdres: TIPAdres;
    YerelPort, UzakPort: TSayi2;
    Bagli: Boolean;
    Bellek: Isaretci;
    BellekUzunlugu: TSayi4;
  end;

type
  PBaglantilar = ^TBaglantilar;
  TBaglantilar = object
  private
    FBaglantiListesi: array[0..USTSINIR_BAGLANTI - 1] of PBaglanti;
    function BaglantiAl(ASiraNo: TSayi4): PBaglanti;
    procedure BaglantiYaz(ASiraNo: TSayi4; ABaglanti: PBaglanti);
  public
    procedure Yukle;
    function BaglantiOlustur(AProtokolTipi: TProtokolTipi; ABaglantiAdresi: string;
      AYerelPort, AUzakPort: TSayi2): PBaglanti;
    function BaglantiYapisiOlustur: PBaglanti;
    function Baglan(AKimlik: TKimlik; ABaglantiTipi: TBaglantiTipi): TISayi4;
    function BagliMi(AKimlik: TKimlik): Boolean;
    function BaglantiyiKes(AKimlik : TKimlik): TISayi4;
    function TCPIlkSiraNoAl: TSayi4;
    function TCPBaglantiAl(AYerelPort, AUzakPort: TSayi2): PBaglanti;
    function UDPBaglantiAl(AYerelPort: TSayi2): PBaglanti;
    procedure BellegeEkle(ABaglanti: PBaglanti; AKaynakBellek: Isaretci;
      ABellekUzunlugu: TSayi4);
    function VeriUzunlugu(AKimlik: TKimlik): TSayi4;
    function Oku(AKimlik: TKimlik; ABellek: Isaretci): TSayi4;
    procedure Yaz(AKimlik: TKimlik; ABellek: Isaretci; AUzunluk: TISayi4);
    property Baglanti[ASiraNo: TSayi4]: PBaglanti read BaglantiAl write BaglantiYaz;
    function YerelPortAl: TSayi2;
  end;

var
  Baglantilar0: TBaglantilar;
  BaglantilarKilit: TSayi4 = 0;

implementation

uses tcp, udp, arp, islevler, donusum;

{==============================================================================
  baðlantý nesnelerinin ana yükleme iþlevlerini içerir
 ==============================================================================}
procedure TBaglantilar.Yukle;
var
  i: TSayi4;
begin

  // baðlantý yapýlarýný ilk deðerlerle yükle
  for i := 0 to USTSINIR_BAGLANTI - 1 do Baglanti[i] := nil;

  TCPIlkSiraNo := $10001000;
  YerelPortNo := ILK_YERELPORTNO;
end;

function TBaglantilar.BaglantiAl(ASiraNo: TSayi4): PBaglanti;
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo <= USTSINIR_BAGLANTI) then
    Result := FBaglantiListesi[ASiraNo]
  else Result := nil;
end;

procedure TBaglantilar.BaglantiYaz(ASiraNo: TSayi4; ABaglanti: PBaglanti);
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo <= USTSINIR_BAGLANTI) then
    FBaglantiListesi[ASiraNo] := ABaglanti;
end;

{==============================================================================
  að baðlantýsý için baðlantý oluþturur
 ==============================================================================}
function TBaglantilar.BaglantiOlustur(AProtokolTipi: TProtokolTipi; ABaglantiAdresi: string;
  AYerelPort, AUzakPort: TSayi2): PBaglanti;
var
  B: PBaglanti;
  s, SunucuAdi,
  Sayfa: string;
  i: TSayi4;
  IPAdresi: TIPAdres;
begin

  while KritikBolgeyeGir(BaglantilarKilit) = False do;

  B := BaglantiYapisiOlustur;
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

  IPAdresi := StrToIP(SunucuAdi);

  B^.Bagli := False;
  B^.ProtokolTipi := AProtokolTipi;
  B^.HedefIPAdres := IPAdresi;
  B^.YerelPort := AYerelPort;
  B^.UzakPort := AUzakPort;

  if(AProtokolTipi = ptTCP) then
  begin

    B^.PencereU := TCP_PENCERE_UZUNLUK;
    B^.SiraNo := TCPIlkSiraNoAl;
    B^.OnayNo := 0;

    B^.BellekUzunlugu := 0;
    B^.Bellek := GetMem(4096); //Bag^.FPencereU);
    if(B^.Bellek = nil) then SISTEM_MESAJ(mtHata, RENK_SIYAH, 'BAGLANTI.PAS: Bellek yok', []);
  end
  else if(AProtokolTipi = ptUDP) then
  begin

    B^.BellekUzunlugu := 0;
    B^.Bellek := GetMem(4096);

    {SISTEM_MESAJ(RENK_MOR, 'BAGLANTI.PAS: Protokol -> UDP', []);
    SISTEM_MESAJ(RENK_MOR, 'BAGLANTI.PAS: Kimlik %d', [Bag^.FKimlik]);
    SISTEM_MESAJ_IP(RENK_LACIVERT, 'Hedef IP: ', AHedefIPAdres);
    SISTEM_MESAJ(RENK_LACIVERT, 'Kaynak Port: %d', [AYerelPort]);
    SISTEM_MESAJ(RENK_LACIVERT, 'Hedef Port: %d', [AUzakPort]); }
  end
  else
  begin

    s := ProtokolTipAdi(AProtokolTipi);
    SISTEM_MESAJ(mtHata, RENK_SIYAH, 'BAGLANTI.PAS: TBaglantilar.Olustur2', []);
    SISTEM_MESAJ(mtHata, RENK_SIYAH, '  -> Bilinmeyen Protokol: %s ', [s]);
    SISTEM_MESAJ_IP(mtHata, RENK_SIYAH, '  -> Hedef IP: ', IPAdresi);
    SISTEM_MESAJ(mtHata, RENK_SIYAH, '  -> Hedef Port: %d', [AUzakPort]);
  end;

  Result := B;

  KritikBolgedenCik(BaglantilarKilit);
end;

{==============================================================================
  yeni baðlantý için gerekli yapýlarý oluþturur
 ==============================================================================}
function TBaglantilar.BaglantiYapisiOlustur: PBaglanti;
var
  B: PBaglanti;
  i: TSayi4;
begin

  // kullanýlmayan baðlantý varsa tespit et ve
  // gerekli bellek ve atama iþlemlerini gerçekleþtir
  for i := 0 to USTSINIR_BAGLANTI - 1 do
  begin

    B := Baglanti[i];
    if(B = nil) then
    begin

      B := PBaglanti(GetMem(SizeOf(TBaglanti)));
      Baglanti[i] := B;

      B^.BaglantiDurum := bdYok;
      B^.Kimlik := i;
      B^.BaglantiDurum := bdKapali;

      Exit(B);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  oluþturulan baðlantý üzerinden uzaktaki sisteme baðlantý kurar
 ==============================================================================}
function TBaglantilar.Baglan(AKimlik: TKimlik; ABaglantiTipi: TBaglantiTipi): TISayi4;
const
  // tcp baðlantýsýnýn ilk SYN, SYN + ACK paketi için gerekli ek veri deðerleri
  TCPSYNSonEk: array[0..11] of TSayi1 = (
    $02, $04, $05, $B4, $01, $03, $03, $08, $01, $01, $04, $02);
var
  B: PBaglanti;
begin

  // baðlantýyý al
  B := Baglanti[AKimlik];
  if not(B = nil) then
  begin

    if(B^.ProtokolTipi = ptUDP) then
    begin

      if(ABaglantiTipi = btYayin) then
      begin

        B^.HedefMACAdres := MACAdres255;
        B^.Bagli := True;
        Exit(B^.Kimlik);
      end
      else
      begin

        if(IPAdresiAyniAgdaMi(B^.HedefIPAdres)) then
          B^.HedefMACAdres := ARPKayitlar0.MACAdresiAl(B^.HedefIPAdres)
        else B^.HedefMACAdres := ARPKayitlar0.MACAdresiAl(GAgBilgisi.DNSSunucusu);

        B^.Bagli := True;
        Exit(B^.Kimlik);
      end;
    end
    else if(B^.ProtokolTipi = ptTCP) then
    begin

      if(B^.BaglantiDurum = bdKapali) then
      begin

        if(IPAdresiAyniAgdaMi(B^.HedefIPAdres)) then
          B^.HedefMACAdres := ARPKayitlar0.MACAdresiAl(B^.HedefIPAdres)
        else B^.HedefMACAdres := ARPKayitlar0.MACAdresiAl(GAgBilgisi.DNSSunucusu);

        // ilk paket olan SYN (ARZ) paketi gönderiliyor
        TCPPaketGonder(B, GAgBilgisi.IP4Adres, TCP_BAYRAK_ARZ, @TCPSYNSonEk, 12, True);
        B^.BaglantiDurum := bdBaglaniyor;
        Exit(B^.Kimlik);
      end;
    end;
  end;

  Result := -1;
end;

{==============================================================================
  baðlantýnýn var olup olmadýðýný kontrol eder
 ==============================================================================}
function TBaglantilar.BagliMi(AKimlik: TKimlik): Boolean;
var
  B: PBaglanti;
begin

  // baðlantýyý al
  B := Baglanti[AKimlik];
  if not(B = nil) then
  begin

    if(B^.ProtokolTipi = ptUDP) then

      Result := B^.Bagli
    else if(B^.ProtokolTipi = ptTCP) then
    begin

      if(B^.BaglantiDurum = bdBaglandi) then
        Result := True
      else Result := False;

    end else Result := False;
  end else Result := False;
end;

{==============================================================================
  baðlantýyý kapatýr
 ==============================================================================}
function TBaglantilar.BaglantiyiKes(AKimlik : TKimlik): TISayi4;
var
  B: PBaglanti;
begin

  { TODO - baðlantýnýn yok edilmesi baðlantý kesilmesi (burada) aþamasýnda gerçekleþtirilebilir }

  // baðlantýyý al
  B := Baglanti[AKimlik];
  if not(B = nil) then
  begin

    if(B^.ProtokolTipi = ptUDP) then
    begin

      B^.BaglantiDurum := bdKapali;
      B^.ProtokolTipi := ptBilinmiyor;
      B^.HedefIPAdres := IPAdres0;
      B^.YerelPort := 0;
      B^.UzakPort := 0;

      FreeMem(B^.Bellek, B^.BellekUzunlugu);
      B^.Bagli := False;

      Result := 0;
    end
    else if(B^.ProtokolTipi = ptTCP) then
    begin

      if(B^.BaglantiDurum = bdBaglandi) then
      begin

        TCPPaketGonder(B, GAgBilgisi.IP4Adres, TCP_BAYRAK_SON + TCP_BAYRAK_KABUL,
          nil, 0);

        B^.BaglantiDurum := bdKapaniyor1;

        // baðlantýyý kapatmanýn diðer aþamalarý sunucu + istemci olarak tcp.pas dosyasýndadýr

        //SISTEM_MESAJ(RENK_KIRMIZI, 'TCP Durum: bdKapaniyor1', []);

        Result := 0;
      end;
    end;
  end;
end;

{==============================================================================
  TCP veri alýþveriþinin gerçekleþmesi için gereken ilk sýra numarasýný alýr
 ==============================================================================}
function TBaglantilar.TCPIlkSiraNoAl: TSayi4;
begin

  Result := TCPIlkSiraNo;
end;

{==============================================================================
  tcp yerel / uzak portun sahibi olan baðlantýyý alýr
 ==============================================================================}
function TBaglantilar.TCPBaglantiAl(AYerelPort, AUzakPort: TSayi2): PBaglanti;
var
  B: PBaglanti;
  i: TSayi4;
begin

  // tüm iþlem giriþlerini incele
  for i := 0 to USTSINIR_BAGLANTI - 1 do
  begin

    B := Baglanti[i];
    if not(B^.BaglantiDurum = bdYok) and (B^.YerelPort = AYerelPort) and
      (B^.UzakPort = AUzakPort) then Exit(B);
  end;

  Result := nil;
end;

{==============================================================================
  udp yerel portun sahibi olan baðlantýyý alýr
 ==============================================================================}
function TBaglantilar.UDPBaglantiAl(AYerelPort: TSayi2): PBaglanti;
var
  B: PBaglanti;
  i: TSayi4;
begin

  // tüm iþlem giriþlerini incele
  for i := 0 to USTSINIR_BAGLANTI - 1 do
  begin

    B := Baglanti[i];
    if not(B^.BaglantiDurum = bdYok) and (B^.YerelPort = AYerelPort) then
      Exit(B);
  end;

  Result := nil;
end;

{==============================================================================
  baðlantý kurulan bilgisayardan gelen verileri programýn kullanmasý için belleðe kaydeder
 ==============================================================================}
procedure TBaglantilar.BellegeEkle(ABaglanti: PBaglanti; AKaynakBellek: Isaretci;
  ABellekUzunlugu: TSayi4);
var
  p: PChar;
  i: TSayi4;
begin

  if(ABellekUzunlugu = 0) then Exit;

  if(ABaglanti^.BellekUzunlugu + ABellekUzunlugu < 4096) then
  begin

    p := ABaglanti^.Bellek + ABaglanti^.BellekUzunlugu;

    Tasi2(AKaynakBellek, p, ABellekUzunlugu);
    i := ABaglanti^.BellekUzunlugu;
    i += ABellekUzunlugu;
    ABaglanti^.BellekUzunlugu := i;
  end;
end;

{==============================================================================
  baðlantý kurulan cihazdan gelip iþlenmeyi bekleyen veri miktarýný alýr
 ==============================================================================}
function TBaglantilar.VeriUzunlugu(AKimlik: TKimlik): TSayi4;
var
  B: PBaglanti;
begin

  B := Baglanti[AKimlik];

  if not(B = nil) and (B^.Kimlik >= 0) and (B^.Kimlik < USTSINIR_BAGLANTI) then
    Exit(B^.BellekUzunlugu)
  else Result := 0;
end;

{==============================================================================
  baðlantý üzerinden gelen veriyi ilgili programa yönlendirir
 ==============================================================================}
function TBaglantilar.Oku(AKimlik: TKimlik; ABellek: Isaretci): TSayi4;
var
  B: PBaglanti;
  i: TSayi4;
begin

  // baðlantýyý al
  B := Baglanti[AKimlik];
  if not(B = nil) then
  begin

    i := B^.BellekUzunlugu;
    if(i > 0) then
    begin

      Tasi2(B^.Bellek, ABellek, i);
      Result := B^.BellekUzunlugu;
      B^.BellekUzunlugu := 0;
      Exit(i);
    end;
  end;

  Result := 0;
end;

{==============================================================================
  baðlantý kurulan bilgisayara veri gönderir
 ==============================================================================}
procedure TBaglantilar.Yaz(AKimlik: TKimlik; ABellek: Isaretci; AUzunluk: TISayi4);
var
  B: PBaglanti;
begin

  // baðlantýyý al
  B := Baglanti[AKimlik];
  if not(B = nil) then
  begin

    if(B^.ProtokolTipi = ptTCP) then
    begin

      if(B^.BaglantiDurum = bdBaglandi) then
      begin

        // FPencereU := $100;
        TCPPaketGonder(B, GAgBilgisi.IP4Adres, TCP_BAYRAK_KABUL or TCP_BAYRAK_GONDER,
          ABellek, AUzunluk);
      end;
    end
    else if(B^.ProtokolTipi = ptUDP) then
    begin

      UDPPaketGonder(B^.HedefMACAdres, GAgBilgisi.IP4Adres, B^.HedefIPAdres,
        B^.YerelPort, B^.UzakPort, ABellek, AUzunluk);
    end
  end;
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

end.
