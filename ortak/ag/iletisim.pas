{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: iletisim.pas
  Dosya Ýþlevi: baðlantý (soket) iletiþim yönetim iþlevlerini içerir

  Güncelleme Tarihi: 21/05/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit iletisim;

interface

uses paylasim, sistemmesaj;

const
  USTSINIR_AGILETISIM = 32; //64;
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
  TBaglanti = object
  public
    FKimlik: TKimlik;
    FBaglantiDurum: TBaglantiDurum;
    FProtokolTipi: TProtokolTipi;
    FPencereU: TSayi2;
    FSiraNo,                      // TCP sýra no (sequence number)
    FOnayNo: TSayi4;              // TCP onay no (acknowledgment number)
    FHedefMACAdres: TMACAdres;
    FHedefIPAdres: TIPAdres;
    FYerelPort, FUzakPort: TSayi2;
    FBagli: Boolean;
    FBellek: Isaretci;
    FBellekUzunlugu: TSayi4;
    function Olustur2(AProtokolTipi: TProtokolTipi; ABaglantiAdresi: string; AYerelPort,
      AUzakPort: TSayi2): PBaglanti;
    function BaglantiOlustur: PBaglanti;
    function Baglan(ABaglantiTipi: TBaglantiTipi): TISayi4;
    function BagliMi: Boolean;
    function BaglantiyiKes: TISayi4;
    function TCPIlkSiraNoAl: TSayi4;
    function TCPBaglantiAl(AYerelPort, AUzakPort: TSayi2): PBaglanti;
    function UDPBaglantiAl(AYerelPort: TSayi2): PBaglanti;
    procedure BellegeEkle(ABaglanti: PBaglanti; AKaynakBellek: Isaretci; ABellekUzunlugu: TSayi4);
    function VeriUzunlugu: TSayi4;
    function Oku(ABellek: Isaretci): TSayi4;
    procedure Yaz(ABellek: Isaretci; AUzunluk: TISayi4);
  end;

procedure Yukle;
function YerelPortAl: TSayi2;

implementation

uses gercekbellek, genel, tcp, udp, arp, zamanlayici, islevler, donusum;

{==============================================================================
  baðlantý ana yükleme iþlevlerini içerir
 ==============================================================================}
procedure Yukle;
var
  Bag: PBaglanti;
  i: TSayi4;
begin

  // baðlantý bilgilerinin yerleþtirilmesi için bellek ayýr
  Bag := GGercekBellek.Ayir(SizeOf(TBaglanti) * USTSINIR_AGILETISIM);

  // bellek giriþlerini dizi giriþleriyle eþleþtir
  for i := 0 to USTSINIR_AGILETISIM - 1 do
  begin

    GAgIletisimListesi[i] := Bag;

    // iþlemi boþ olarak belirle
    Bag^.FBaglantiDurum := bdYok;
    Bag^.FKimlik := i;

    Inc(Bag);
  end;

  TCPIlkSiraNo := $10001000;
  YerelPortNo := ILK_YERELPORTNO;
end;

{==============================================================================
  að baðlantýsý için baðlantý oluþturur
 ==============================================================================}
function TBaglanti.Olustur2(AProtokolTipi: TProtokolTipi; ABaglantiAdresi: string;
  AYerelPort, AUzakPort: TSayi2): PBaglanti;
var
  Bag: PBaglanti;
  s, SunucuAdi, Sayfa: string;
  i: TSayi4;
  IPAdresi: TIPAdres;
begin

  Bag := nil;

  Bag := BaglantiOlustur;
  if(Bag = nil) then Exit(Bag);

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

  Bag^.FBagli := False;
  Bag^.FProtokolTipi := AProtokolTipi;
  Bag^.FHedefIPAdres := IPAdresi;
  Bag^.FYerelPort := AYerelPort;
  Bag^.FUzakPort := AUzakPort;

  if(AProtokolTipi = ptTCP) then
  begin

    Bag^.FPencereU := TCP_PENCERE_UZUNLUK;
    Bag^.FSiraNo := TCPIlkSiraNoAl;
    Bag^.FOnayNo := 0;

    Bag^.FBellekUzunlugu := 0;
    Bag^.FBellek := GGercekBellek.Ayir(4096); //Bag^.FPencereU);
    if(Bag^.FBellek = nil) then SISTEM_MESAJ(mtHata, RENK_SIYAH, 'ILETISIM.PAS: Bellek yok', []);
  end
  else if(AProtokolTipi = ptUDP) then
  begin

    Bag^.FBellekUzunlugu := 0;
    Bag^.FBellek := GGercekBellek.Ayir(4096);

    {SISTEM_MESAJ(RENK_MOR, 'ILETISIM.PAS: Protokol -> UDP', []);
    SISTEM_MESAJ(RENK_MOR, 'ILETISIM.PAS: Kimlik %d', [Bag^.FKimlik]);
    SISTEM_MESAJ_IP(RENK_LACIVERT, 'Hedef IP: ', AHedefIPAdres);
    SISTEM_MESAJ(RENK_LACIVERT, 'Kaynak Port: %d', [AYerelPort]);
    SISTEM_MESAJ(RENK_LACIVERT, 'Hedef Port: %d', [AUzakPort]); }
  end
  else
  begin

    s := ProtokolTipAdi(AProtokolTipi);
    SISTEM_MESAJ(mtHata, RENK_SIYAH, 'ILETISIM.PAS: TBaglanti.Olustur', []);
    SISTEM_MESAJ(mtHata, RENK_SIYAH, '  -> Bilinmeyen Protokol: %s ', [s]);
    SISTEM_MESAJ_IP(mtHata, RENK_SIYAH, '  -> Hedef IP: ', IPAdresi);
    SISTEM_MESAJ(mtHata, RENK_SIYAH, '  -> Hedef Port: %d', [AUzakPort]);
  end;

  Result := Bag;
end;

{==============================================================================
  yeni baðlantý için boþ baðlantý noktasý bulur
 ==============================================================================}
function TBaglanti.BaglantiOlustur: PBaglanti;
var
  Bag: PBaglanti;
  i: TSayi4;
begin

  // tüm iþlem giriþlerini incele
  for i := 0 to USTSINIR_AGILETISIM - 1 do
  begin

    Bag := GAgIletisimListesi[i];

    // baðlantý durumu boþ ise
    if(Bag^.FBaglantiDurum = bdYok) then
    begin

      // baðlantýyý ayýr ve çaðýran iþleve geri dön
      Bag^.FBaglantiDurum := bdKapali;
      Exit(Bag);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  oluþturulan baðlantý üzerinden uzaktaki sisteme baðlantý kurar
 ==============================================================================}
function TBaglanti.Baglan(ABaglantiTipi: TBaglantiTipi): TISayi4;
const
  // tcp baðlantýsýnýn ilk SYN, SYN + ACK paketi için gerekli ek veri deðerleri
  TCPSYNSonEk: array[0..11] of TSayi1 = (
    $02, $04, $05, $B4, $01, $03, $03, $08, $01, $01, $04, $02);
var
  Bag: PBaglanti;
begin

  // baðlantý kimliði tanýmlanan aralýkta ise...
  if(FKimlik >= 0) and (FKimlik < USTSINIR_AGILETISIM) then
  begin

    Bag := GAgIletisimListesi[FKimlik];

    if(Bag^.FProtokolTipi = ptUDP) then
    begin

      if(ABaglantiTipi = btYayin) then
      begin

        Bag^.FHedefMACAdres := MACAdres255;
        Bag^.FBagli := True;
        Exit(Bag^.FKimlik);
      end
      else
      begin

        if(IPAdresiAyniAgdaMi(FHedefIPAdres)) then
          Bag^.FHedefMACAdres := MACAdresiAl(FHedefIPAdres)
        else Bag^.FHedefMACAdres := MACAdresiAl(GAgBilgisi.DNSSunucusu);

        Bag^.FBagli := True;
        Exit(Bag^.FKimlik);
      end;
    end
    else if(FProtokolTipi = ptTCP) then
    begin

      if(Bag^.FBaglantiDurum = bdKapali) then
      begin

        if(IPAdresiAyniAgdaMi(FHedefIPAdres)) then
          Bag^.FHedefMACAdres := MACAdresiAl(FHedefIPAdres)
        else Bag^.FHedefMACAdres := MACAdresiAl(GAgBilgisi.DNSSunucusu);

        // ilk paket olan SYN (ARZ) paketi gönderiliyor
        TCPPaketGonder(Bag, GAgBilgisi.IP4Adres, TCP_BAYRAK_ARZ, @TCPSYNSonEk, 12, True);
        Bag^.FBaglantiDurum := bdBaglaniyor;
        Exit(Bag^.FKimlik);
      end;
    end;
  end;

  Result := -1;
end;

{==============================================================================
  baðlantýnýn var olup olmadýðýný kontrol eder
 ==============================================================================}
function TBaglanti.BagliMi: Boolean;
begin

  // baðlantý kimliði tanýmlanan aralýkta ise...
  if(FKimlik >= 0) and (FKimlik < USTSINIR_AGILETISIM) then
  begin

    if(FProtokolTipi = ptUDP) then

      Result := FBagli
    else if(FProtokolTipi = ptTCP) then
    begin

      if(FBaglantiDurum = bdBaglandi) then
        Result := True
      else Result := False;

    end else Result := False;
  end else Result := False;
end;

{==============================================================================
  baðlantýyý kapatýr
 ==============================================================================}
function TBaglanti.BaglantiyiKes: TISayi4;
begin

  // baðlantý kimliði tanýmlanan aralýkta ise...
  if(FKimlik >= 0) and (FKimlik < USTSINIR_AGILETISIM) then
  begin

    if(FProtokolTipi = ptUDP) then
    begin

      FBaglantiDurum := bdKapali;
      FProtokolTipi := ptBilinmiyor;
      FHedefIPAdres := IPAdres0;
      FYerelPort := 0;
      FUzakPort := 0;

      GGercekBellek.YokEt(FBellek, FBellekUzunlugu);
      FBagli := False;

      Result := 0;
    end
    else if(FProtokolTipi = ptTCP) then
    begin

      if(FBaglantiDurum = bdBaglandi) then
      begin

        TCPPaketGonder(@Self, GAgBilgisi.IP4Adres, TCP_BAYRAK_SON + TCP_BAYRAK_KABUL,
          nil, 0);

        FBaglantiDurum := bdKapaniyor1;

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
function TBaglanti.TCPIlkSiraNoAl: TSayi4;
begin

  Result := TCPIlkSiraNo;
end;

{==============================================================================
  tcp yerel / uzak portun sahibi olan baðlantýyý alýr
 ==============================================================================}
function TBaglanti.TCPBaglantiAl(AYerelPort, AUzakPort: TSayi2): PBaglanti;
var
  Bag: PBaglanti;
  i: TSayi4;
begin

  // tüm iþlem giriþlerini incele
  for i := 0 to USTSINIR_AGILETISIM - 1 do
  begin

    Bag := GAgIletisimListesi[i];
    if not(Bag^.FBaglantiDurum = bdYok) and (Bag^.FYerelPort = AYerelPort) and
      (Bag^.FUzakPort = AUzakPort) then Exit(Bag);
  end;

  Result := nil;
end;

{==============================================================================
  udp yerel portun sahibi olan baðlantýyý alýr
 ==============================================================================}
function TBaglanti.UDPBaglantiAl(AYerelPort: TSayi2): PBaglanti;
var
  Bag: PBaglanti;
  i: TSayi4;
begin

  // tüm iþlem giriþlerini incele
  for i := 0 to USTSINIR_AGILETISIM - 1 do
  begin

    Bag := GAgIletisimListesi[i];
    if not(Bag^.FBaglantiDurum = bdYok) and (Bag^.FYerelPort = AYerelPort) then
      Exit(Bag);
  end;

  Result := nil;
end;

{==============================================================================
  baðlantý kurulan bilgisayardan gelen verileri programýn kullanmasý için belleðe kaydeder
 ==============================================================================}
procedure TBaglanti.BellegeEkle(ABaglanti: PBaglanti; AKaynakBellek: Isaretci; ABellekUzunlugu: TSayi4);
var
  p: PChar;
  i: TSayi4;
begin

  if(ABellekUzunlugu = 0) then Exit;

  if(ABaglanti^.FBellekUzunlugu + ABellekUzunlugu < 4096) then
  begin

    p := ABaglanti^.FBellek + ABaglanti^.FBellekUzunlugu;

    Tasi2(AKaynakBellek, p, ABellekUzunlugu);
    i := ABaglanti^.FBellekUzunlugu;
    i += ABellekUzunlugu;
    ABaglanti^.FBellekUzunlugu := i;
  end;
end;

{==============================================================================
  baðlantý kurulan cihazdan gelip iþlenmeyi bekleyen veri miktarýný alýr
 ==============================================================================}
function TBaglanti.VeriUzunlugu: TSayi4;
begin

  if(FKimlik >= 0) and (FKimlik < USTSINIR_AGILETISIM) then
    Exit(Self.FBellekUzunlugu)
  else Result := 0;
end;

{==============================================================================
  baðlantý üzerinden gelen veriyi okuyarak ilgili programa yönlendirir
 ==============================================================================}
function TBaglanti.Oku(ABellek: Isaretci): TSayi4;
var
  i: TSayi4;
begin

  if(FKimlik >= 0) and (FKimlik < USTSINIR_AGILETISIM) then
  begin

    i := Self.FBellekUzunlugu;
    if(i > 0) then
    begin

      Tasi2(Self.FBellek, ABellek, i);
      Result := Self.FBellekUzunlugu;
      Self.FBellekUzunlugu := 0;
      Exit(i);
    end;
  end;

  Result := 0;
end;

{==============================================================================
  baðlantý kurulan bilgisayara veri gönderir
 ==============================================================================}
procedure TBaglanti.Yaz(ABellek: Isaretci; AUzunluk: TISayi4);
begin

  if(FKimlik >= 0) and (FKimlik < USTSINIR_AGILETISIM) then
  begin

    if(FProtokolTipi = ptTCP) then
    begin

      if(FBaglantiDurum = bdBaglandi) then
      begin

        // FPencereU := $100;
        TCPPaketGonder(@Self, GAgBilgisi.IP4Adres, TCP_BAYRAK_KABUL or TCP_BAYRAK_GONDER,
          ABellek, AUzunluk);
      end;
    end
    else if(FProtokolTipi = ptUDP) then
    begin

      UDPPaketGonder(FHedefMACAdres, GAgBilgisi.IP4Adres, FHedefIPAdres,
        FYerelPort, FUzakPort, ABellek, AUzunluk);
    end
  end;
end;

{==============================================================================
  yerel port numarasý üretir
 ==============================================================================}
function YerelPortAl: TSayi2;
begin

  Inc(YerelPortNo);
  if(YerelPortNo > $FDE8 {65000}) then YerelPortNo := ILK_YERELPORTNO;
  Result := YerelPortNo;
end;

end.
