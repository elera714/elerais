{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: iletisim.pas
  Dosya İşlevi: bağlantı (soket) iletişim yönetim işlevlerini içerir

  Güncelleme Tarihi: 16/09/2024

 ==============================================================================}
{$mode objfpc}
unit iletisim;

interface

uses paylasim, sistemmesaj;

const
  USTSINIR_AGILETISIM = 64;
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
  //  bdKapaniyor1 = istemcinin sunucuya gönderdiği FIN + ACK durumu
  //  bdKapaniyor2 = sunucunun istemciye gönderdiği FIN + ACK durumu
  TBaglantiDurum = (bdYok, bdKapali, bdBaglaniyor, bdBaglandi, bdKapaniyor1,
    bdKapaniyor2);

type
  PBaglanti = ^TBaglanti;
  TBaglanti = object
  public
    FKimlik: TKimlik;
    FBaglantiDurum: TBaglantiDurum;
    FProtokol: TProtokolTip;
    FPencereU: TSayi2;
    FSiraNo,                      // TCP sıra no (sequence number)
    FOnayNo: TSayi4;              // TCP onay no (acknowledgment number)
    FHedefMACAdres: TMACAdres;
    FHedefIPAdres: TIPAdres;
    FYerelPort, FUzakPort: TSayi2;
    FBagli: Boolean;
    FBellek: Pointer;
    FBellekUzunlugu: Integer;
    function Olustur(AProtokolTip: TProtokolTip; AUzakIPAdres: TIPAdres; AYerelPort,
      AUzakPort: TSayi2): PBaglanti;
    function YeniBaglantiOlustur: PBaglanti;
    function Baglan(ABaglantiTipi: TBaglantiTipi): TISayi4;
    function BagliMi: Boolean;
    function BaglantiyiKes: TISayi4;
    function TCPIlkSiraNoAl: TSayi4;
    function TCPBaglantiAl(AYerelPort, AUzakPort: TSayi2): PBaglanti;
    function UDPBaglantiAl(AYerelPort: TSayi2): PBaglanti;
    procedure BellegeEkle(AKaynakBellek: Isaretci; ABellekUzunlugu: TSayi4);
    function VeriUzunlugu: TISayi4;
    function Oku(ABellek: Isaretci): TISayi4;
    procedure Yaz(ABellek: Isaretci; AUzunluk: TISayi4);
  end;

procedure Yukle;
function YerelPortAl: TSayi2;

implementation

uses gercekbellek, genel, tcp, udp, arp, zamanlayici;

{==============================================================================
  bağlantı ana yükleme işlevlerini içerir
 ==============================================================================}
procedure Yukle;
var
  _Baglanti: PBaglanti;
  i: TSayi4;
begin

  // bağlantı bilgilerinin yerleştirilmesi için bellek ayır
  _Baglanti := GGercekBellek.Ayir(SizeOf(TBaglanti) * USTSINIR_AGILETISIM);

  // bellek girişlerini dizi girişleriyle eşleştir
  for i := 1 to USTSINIR_AGILETISIM do
  begin

    AgIletisimListesi[i] := _Baglanti;

    // işlemi boş olarak belirle
    _Baglanti^.FBaglantiDurum := bdYok;
    _Baglanti^.FKimlik := i;

    Inc(_Baglanti);
  end;

  TCPIlkSiraNo := $10001000;
  YerelPortNo := ILK_YERELPORTNO;
end;

{==============================================================================
  ağ bağlantısı için bağlantı oluşturur
 ==============================================================================}
function TBaglanti.Olustur(AProtokolTip: TProtokolTip; AUzakIPAdres: TIPAdres;
  AYerelPort, AUzakPort: TSayi2): PBaglanti;
var
  _Baglanti: PBaglanti;
begin

  _Baglanti := nil;

  if(AProtokolTip = ptTCP) then
  begin

    _Baglanti := YeniBaglantiOlustur;
    if(_Baglanti <> nil) then
    begin

      _Baglanti^.FBagli := False;
      _Baglanti^.FProtokol := AProtokolTip;
      _Baglanti^.FHedefMACAdres := MACAdres0;
      _Baglanti^.FHedefIPAdres := AUzakIPAdres;
      _Baglanti^.FYerelPort := AYerelPort;
      _Baglanti^.FUzakPort := AUzakPort;
      _Baglanti^.FPencereU := TCP_PENCERE_UZUNLUK;
      _Baglanti^.FSiraNo := TCPIlkSiraNoAl;
      _Baglanti^.FOnayNo := 0;

      FBellekUzunlugu := 0;
      FBellek := GGercekBellek.Ayir(_Baglanti^.FPencereU);
    end;
  end
  else if(AProtokolTip = ptUDP) then
  begin

    _Baglanti := YeniBaglantiOlustur;
    if(_Baglanti <> nil) then
    begin

      _Baglanti^.FBaglantiDurum := bdBaglandi;
      _Baglanti^.FProtokol := AProtokolTip;
      _Baglanti^.FHedefIPAdres := AUzakIPAdres;
      _Baglanti^.FYerelPort := AYerelPort;
      _Baglanti^.FUzakPort := AUzakPort;
      _Baglanti^.FBagli := False;

      FBellekUzunlugu := 0;
      FBellek := GGercekBellek.Ayir(4095);

      {SISTEM_MESAJ(RENK_MOR, 'BAGLANTI.PP: Protokol -> UDP', []);
      SISTEM_MESAJ_IP(RENK_LACIVERT, 'Hedef IP: ', AUzakIPAdres);
      SISTEM_MESAJ(RENK_LACIVERT, 'Kaynak Port: %d', [AYerelPort]);
      SISTEM_MESAJ(RENK_LACIVERT, 'Hedef Port: %d', [AUzakPort]);}
    end;
  end
  else
  begin

    _Baglanti := YeniBaglantiOlustur;
    if(_Baglanti <> nil) then
    begin

      SISTEM_MESAJ(RENK_MAVI, 'BAGLANTI.PP: Protokol -> ?', []);
      SISTEM_MESAJ_IP(RENK_ACIKMAVI, '  -> Hedef IP: ', AUzakIPAdres);
      SISTEM_MESAJ_S16(RENK_ACIKMAVI, '  -> Hedef Port: ', AUzakPort, 4);
    end;
  end;

  Result := _Baglanti;
end;

{==============================================================================
  yeni bağlantı için boş bağlantı noktası bulur
 ==============================================================================}
function TBaglanti.YeniBaglantiOlustur: PBaglanti;
var
  _Baglanti: PBaglanti;
  i: TSayi4;
begin

  // tüm işlem girişlerini incele
  for i := 1 to USTSINIR_AGILETISIM do
  begin

    _Baglanti := AgIletisimListesi[i];

    // bağlantı durumu boş ise
    if(_Baglanti^.FBaglantiDurum = bdYok) then
    begin

      // bağlantıyı ayır ve çağıran işleve geri dön
      _Baglanti^.FBaglantiDurum := bdKapali;
      Exit(_Baglanti);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  oluşturulan bağlantı üzerinden uzaktaki sisteme bağlantı kurar
 ==============================================================================}
function TBaglanti.Baglan(ABaglantiTipi: TBaglantiTipi): TISayi4;
const
  // tcp bağlantısının ilk SYN, SYN + ACK paketi için gerekli ek veri değerleri
  TCPSYNSonEk: array[0..11] of TSayi1 = (
    $02, $04, $05, $B4, $01, $03, $03, $08, $01, $01, $04, $02);
begin

  // bağlantı kimliği tanımlanan aralıkta ise...
  if(FKimlik > 0) and (FKimlik <= USTSINIR_AGILETISIM) then
  begin

    if(FProtokol = ptUDP) then
    begin

      if(ABaglantiTipi = btYayin) then
      begin

        FHedefMACAdres := MACAdres255;
        FBagli := True;
        Exit(FKimlik);
      end
      else
      begin

        FHedefMACAdres := MACAdresiAl(FHedefIPAdres);
        FBagli := True;
        Exit(FKimlik);
      end;
    end
    else if(FProtokol = ptTCP) then
    begin

      if(FBaglantiDurum = bdKapali) then
      begin

        FHedefMACAdres := MACAdresiAl(FHedefIPAdres);

        // ilk paket olan SYN (ARZ) paketi gönderiliyor
        TCPPaketGonder(GAgBilgisi.IP4Adres, @Self, TCP_BAYRAK_ARZ, @TCPSYNSonEk, 12, True);
        FBaglantiDurum := bdBaglaniyor;
        Exit(FKimlik);
      end;
    end;
  end;

  Result := 0;
end;

{==============================================================================
  bağlantının var olup olmadığını kontrol eder
 ==============================================================================}
function TBaglanti.BagliMi: Boolean;
begin

  // bağlantı kimliği tanımlanan aralıkta ise...
  if(FKimlik > 0) and (FKimlik <= USTSINIR_AGILETISIM) then
  begin

    if(FProtokol = ptUDP) then

      Result := FBagli
    else if(FProtokol = ptTCP) then
    begin

      if(FBaglantiDurum = bdBaglandi) then
        Result := True
      else Result := False;

    end else Result := False;
  end else Result := False;
end;

{==============================================================================
  bağlantıyı kapatır
 ==============================================================================}
function TBaglanti.BaglantiyiKes: TISayi4;
begin

  // bağlantı kimliği tanımlanan aralıkta ise...
  if(FKimlik > 0) and (FKimlik <= USTSINIR_AGILETISIM) then
  begin

    if(FProtokol = ptUDP) then
    begin

      FBaglantiDurum := bdKapali;
      FProtokol := ptBilinmiyor;
      FHedefIPAdres := IPAdres0;
      FYerelPort := 0;
      FUzakPort := 0;
      GGercekBellek.YokEt(FBellek, FBellekUzunlugu);
      FBagli := False;

      Result := 0;
    end
    else if(FProtokol = ptTCP) then
    begin

      if(FBaglantiDurum = bdBaglandi) then
      begin

        TCPPaketGonder(GAgBilgisi.IP4Adres, @Self, TCP_BAYRAK_SON + TCP_BAYRAK_KABUL,
          nil, 0);

        FBaglantiDurum := bdKapaniyor1;

        // bağlantıyı kapatmanın diğer aşamaları sunucu + istemci olarak tcp.pas dosyasındadır

        //SISTEM_MESAJ(RENK_KIRMIZI, 'TCP Durum: bdKapaniyor1', []);

        Result := 0;
      end;
    end;
  end;
end;

{==============================================================================
  TCP veri alışverişinin gerçekleşmesi için gereken ilk sıra numarasını alır
 ==============================================================================}
function TBaglanti.TCPIlkSiraNoAl: TSayi4;
begin

  Result := TCPIlkSiraNo;
end;

{==============================================================================
  tcp yerel / uzak portun sahibi olan bağlantıyı alır
 ==============================================================================}
function TBaglanti.TCPBaglantiAl(AYerelPort, AUzakPort: TSayi2): PBaglanti;
var
  _Baglanti: PBaglanti;
  i: TSayi4;
begin

  // tüm işlem girişlerini incele
  for i := 1 to USTSINIR_AGILETISIM do
  begin

    _Baglanti := AgIletisimListesi[i];
    if not(_Baglanti^.FBaglantiDurum = bdYok) and (_Baglanti^.FYerelPort = AYerelPort) and
      (_Baglanti^.FUzakPort = AUzakPort) then Exit(_Baglanti);
  end;

  Result := nil;
end;

{==============================================================================
  udp yerel portun sahibi olan bağlantıyı alır
 ==============================================================================}
function TBaglanti.UDPBaglantiAl(AYerelPort: TSayi2): PBaglanti;
var
  _Baglanti: PBaglanti;
  i: TSayi4;
begin

  // tüm işlem girişlerini incele
  for i := 1 to USTSINIR_AGILETISIM do
  begin

    _Baglanti := AgIletisimListesi[i];
    if not(_Baglanti^.FBaglantiDurum = bdYok) and (_Baglanti^.FYerelPort = AYerelPort) then
      Exit(_Baglanti);
  end;

  Result := nil;
end;

{==============================================================================
  bağlantı kurulan bilgisayardan gelen verileri programın kullanması için belleğe kaydeder
 ==============================================================================}
procedure TBaglanti.BellegeEkle(AKaynakBellek: Isaretci; ABellekUzunlugu: TSayi4);
var
  p: PChar;
begin

  p := Self.FBellek + Self.FBellekUzunlugu;
  Tasi2(AKaynakBellek, p, ABellekUzunlugu);
  Inc(Self.FBellekUzunlugu, ABellekUzunlugu);
end;

{==============================================================================
  bağlantı kurulan cihazdan gelip işlenmeyi bekleyen veri miktarını alır
 ==============================================================================}
function TBaglanti.VeriUzunlugu: TISayi4;
begin

  if(FKimlik > 0) and (FKimlik <= USTSINIR_AGILETISIM) then
    Exit(Self.FBellekUzunlugu);

  Result := 0;
end;

{==============================================================================
  bağlantı üzerinden gelen veriyi okuyarak ilgili programa yönlendirir
 ==============================================================================}
function TBaglanti.Oku(ABellek: Isaretci): TISayi4;
var
  i: TSayi4;
begin

  if(FKimlik > 0) and (FKimlik <= USTSINIR_AGILETISIM) then
  begin

    i := Self.FBellekUzunlugu;
    if(i > 0) then
    begin

      Tasi2(Self.FBellek, ABellek, i);
      Result := Self.FBellekUzunlugu;
      Self.FBellekUzunlugu := 0;
      Exit;
    end;
  end;

  Result := 0;
end;

{==============================================================================
  bağlantı kurulan bilgisayara veri gönderir
 ==============================================================================}
procedure TBaglanti.Yaz(ABellek: Isaretci; AUzunluk: TISayi4);
begin

  if(FKimlik > 0) and (FKimlik <= USTSINIR_AGILETISIM) then
  begin

    if(FProtokol = ptTCP) then
    begin

      if(FBaglantiDurum = bdBaglandi) then
      begin

        FPencereU := $100;
        TCPPaketGonder(GAgBilgisi.IP4Adres, @Self, TCP_BAYRAK_KABUL or TCP_BAYRAK_GONDER,
          ABellek, AUzunluk);
      end;
    end
    else if(FProtokol = ptUDP) then
    begin

      UDPPaketGonder(FHedefMACAdres, GAgBilgisi.IP4Adres, FHedefIPAdres,
        FYerelPort, FUzakPort, ABellek, AUzunluk);
    end
  end;
end;

{==============================================================================
  yerel port numarası üretir
 ==============================================================================}
function YerelPortAl: TSayi2;
begin

  Inc(YerelPortNo);
  if(YerelPortNo > $FDE8 {65000}) then YerelPortNo := ILK_YERELPORTNO;
  Result := YerelPortNo;
end;

end.
