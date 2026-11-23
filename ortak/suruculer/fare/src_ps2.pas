{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: src_ps2.pas
  Dosya İşlevi: ps/2 fare sürücüsü

  Güncelleme Tarihi: 23/11/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit src_ps2;

interface

uses paylasim;

const
  TEKERLEK_CARPAN_DEGERI = TSayi4(10);

type
  PFareOlay = ^TFareOlay;
  TFareOlay = record
    Yatay, Dikey: TISayi4;
    Dugme: TSayi1;
    Tekerlek: TISayi4;
  end;

type
  TFareSurucusu = class
  private
    // FCihazKimlik değerleri ve paket uzunlukları
    // $00: FAygitPaketUzunlugu := 3;        // standart ps2
    // $03: FAygitPaketUzunlugu := 4;        // akıllı (intelli) fare (tekerlek)
    // $04: FAygitPaketUzunlugu := 4;        // akıllı (intelli) fare expplorer (5. düğme)
    FCihazKimlik: TSayi4;
    // -> yazılımsal hızlandırma amaçlı değişkenler
    FYatayKonum, FDikeyKonum: TISayi4;
    FHiz: Double;
    FFareDugmeleri: TSayi1;
    FKaydirmaDegeri: TISayi4;
    FAygitPaketUzunlugu: TSayi4;
    FAktifFareImlec: TFareImlecTipi;
    FKonumDegisti: Boolean;
    procedure KlavyeKontrolcuyeYaz(AKomut: TSayi1);
    function AygitCikisiDoluMu: Boolean;
    function AygitGirisiBosMu: Boolean;
    function ACKVerisiGeldiMi: boolean;
    function VeriAl(var AVeri: TSayi1): Boolean;
    function KomutGonder(AKomut: TSayi1): Boolean;
  public
    constructor Create;
    function OlaylariAl(var AFareOlay: TFareOlay): Boolean;
    procedure KonumDegistir(AYatayKonum, ADikeyKonum: TISayi4);
  published
    property YatayKonum: TISayi4 read FYatayKonum;
    property DikeyKonum: TISayi4 read FDikeyKonum;
    property FareDugmeleri: TSayi1 read FFareDugmeleri;
    property KaydirmaDegeri: TISayi4 read FKaydirmaDegeri;
    property AktifFareImlec: TFareImlecTipi read FAktifFareImlec write FAktifFareImlec;
  end;

var
  GFareSurucusu: TFareSurucusu;

procedure FareKesmeCagrisi;

implementation

uses irq, port, src_vesa20, src_klavye;

const
  KLAVYE_VERI_PORT      = $60;        // okunabilir / yazılabilir
  KLAVYE_DURUM_PORT     = $64;        // okunabilir
  KLAVYE_KOMUT_PORT     = $64;        // yazılabilir

  FARE_BELLEK_UZUNLUGU  = 128;

var
  // aygıttan alınarak belleğe aktarılan veri uzunluğu
  FareVeriBellegi: array[0..FARE_BELLEK_UZUNLUGU - 1] of TISayi1;
  FareOkumaImleci,
  FareYazmaImleci: TSayi4;

{==============================================================================
  ps2 fare sürücü yükleme işlevlerini içerir
 ==============================================================================}
constructor TFareSurucusu.Create;
var
  Komut: TSayi1;
begin

  // kesmeleri durdur
  cli;

  FCihazKimlik := $00;

  FAygitPaketUzunlugu := 3;

  FareOkumaImleci := 0;
  FareYazmaImleci := 0;

  FKonumDegisti := False;

  // fare kursor pozisyonu
  FYatayKonum := GEkranKartSurucusu.KartBilgisi.YatayCozunurluk div 2;
  FDikeyKonum := GEkranKartSurucusu.KartBilgisi.DikeyCozunurluk div 2;
  FHiz := 1.5;
  FFareDugmeleri := 0;
  FKaydirmaDegeri := 0;

  // klavye kontrolcüsüne "fare port'unu aktifleştir" komutu gönder
  KlavyeKontrolcuyeYaz($A8);

  // klavye kontrolcüsüne "kontrolcü komut byte'ını oku" komutu gönder
  KlavyeKontrolcuyeYaz($20);

  // komut byte içeriğini al
  Komut := 0;
  if(VeriAl(Komut)) then
  begin

    // klavye kontrolcüsüne "kontrolcü komut byte'ını yaz" komutu gönder
    KlavyeKontrolcuyeYaz($60);
    begin

      // alınan verinin fare kesmesini aktifleştir bitini (1. bit)
      // aktifleştir ve veriyi port'a gönder
      PortYaz1(KLAVYE_VERI_PORT, Komut or 2);

      // fare öndeğerlerini yükle
      // Sampling rate = 100, resolution = 4 counts/mm,
      // Scaling = 1:1, data reporting = disabled
      KomutGonder($F6);

      if(KomutGonder($F3)) then
      if(KomutGonder(200)) then
      if(KomutGonder($F3)) then
      if(KomutGonder(200)) then
      if(KomutGonder($F3)) then
      if(KomutGonder(80)) then
      if(KomutGonder($F2)) then
      begin

        if(VeriAl(Komut)) then
        begin

          case Komut of
            $00: FAygitPaketUzunlugu := 3;        // standart ps2
            $03: FAygitPaketUzunlugu := 4;        // akıllı (intelli) fare (tekerlek)
            $04: FAygitPaketUzunlugu := 4;        // akıllı (intelli) fare expplorer (5. düğme)
            else FAygitPaketUzunlugu := 3;
          end;
        end;
      end;

      // fareyi aktifleştir
      KomutGonder($F4);
    end;
  end;

  // kesme çağrı işlevini ata ve kesmeyi (irq) aktifleştir
  IRQIsleviAta(12, @FareKesmeCagrisi);
end;

{==============================================================================
  fare aygıtından gelen verileri işler ve geri dönüş değişkenlerini günceller
 ==============================================================================}
function TFareSurucusu.OlaylariAl(var AFareOlay: TFareOlay): Boolean;
var
  B1, B2, B3, B4: TSayi1;
  CarpanDegeri,
  PU, i4: TISayi4;
begin

{
                         fare bilgi kayıt yapısı
  +------+-------+-------+-------+-------+-------+-------+-------+-------+
  |      | bit7  |  bit6 |  bit5 |  bit4 |  bit3 |  bit2 |  bit1 |  bit0 |
  +------+-------+-------+-------+-------+-------+-------+-------+-------+
  |  B1  |Y OVF  | X OVF | Y SGN | X SGN |   1   | M Btn | R Btn | L Btn |
  +------+-------+-------+-------+-------+-------+-------+-------+-------+
  |  B2  |                  X Kaydırma Değeri                            |
  +------+-------+-------+-------+-------+-------+-------+-------+-------+
  |  B3  |                  Y Kaydırma Değeri                            |
  +------+-------+-------+-------+-------+-------+-------+-------+-------+
  |  B4  |   0   |   0   | 5.Btn | 4.Btn |       Z Kaydırma Değeri       |
  +------+-------+-------+-------+-------+-------+-------+-------+-------+
}

  PU := (FareYazmaImleci - FareOkumaImleci) and (FARE_BELLEK_UZUNLUGU - 1);
  if(PU >= FAygitPaketUzunlugu) then
  begin

    FKaydirmaDegeri := 0;
    FFareDugmeleri := 0;

    B1 := FareVeriBellegi[FareOkumaImleci + 0];
    B2 := FareVeriBellegi[FareOkumaImleci + 1];
    B3 := FareVeriBellegi[FareOkumaImleci + 2];
    if(FAygitPaketUzunlugu = 4) then B4 := FareVeriBellegi[FareOkumaImleci + 3];

    FareOkumaImleci := (FareOkumaImleci + FAygitPaketUzunlugu) and (FARE_BELLEK_UZUNLUGU - 1);

    FFareDugmeleri := B1 and (4 + 2 + 1);

    // bilgi: fare x hareketi. X SGN + 8 bit = toplam 9 bit
    // eğer hareket sağ tarafa ise gelen değer pozitif
    // eğer hareket sol tarafa ise gelen değer negatif

    // fare x değeri
    if((B1 and 16) = 16) then
      i4 := $FFFFFF00 or B2
    else i4 := B2;

    // özelleştirilebilir yazılımsal hızlandırma
    FYatayKonum := FYatayKonum + Round(i4 * FHiz);

    // x limit denetimi
    if(FYatayKonum < 0) then
      FYatayKonum := 0
    else if(FYatayKonum > GEkranKartSurucusu.KartBilgisi.YatayCozunurluk - 1) then
      FYatayKonum := GEkranKartSurucusu.KartBilgisi.YatayCozunurluk - 1;

    // bilgi: fare y hareketi. Y SGN + 8 bit = toplam 9 bit
    // eğer hareket aşağıya doğru ise gelen değer negatif
    // eğer hareket yukarıya doğru ise gelen değer pozitif

    // fare y değeri
    // fare değerinin işareti ters yönde değiştiriliyor (üst satırdaki bilgiye bak)
    if((B1 and 32) = 32) then
    begin

      i4 := $FFFFFF00 or B3;
      i4 := Abs(i4);
    end
    else
    begin

      i4 := B3;
      i4 := -i4;
    end;

    // özelleştirilebilir yazılımsal hızlandırma
    FDikeyKonum := FDikeyKonum + Round(i4 * (FHiz));

    // x limit denetimi
    if(FDikeyKonum < 0) then
      FDikeyKonum := 0
    else if(FDikeyKonum > GEkranKartSurucusu.KartBilgisi.DikeyCozunurluk - 1) then
      FDikeyKonum := GEkranKartSurucusu.KartBilgisi.DikeyCozunurluk - 1;

    // paket sayısı 3'ten fazla ise diğer değerleri de işle
    if(PU > 3) then
    begin

      FFareDugmeleri := FFareDugmeleri + (B4 and 16);
      FFareDugmeleri := FFareDugmeleri + (B4 and 32);

      // tekerlek çevirme çarpan değeri
      CarpanDegeri := 1;
      if(TusDurumSolDegisim = tdBasildi) then CarpanDegeri := TEKERLEK_CARPAN_DEGERI;

      if((B4 and 8) = 8) then
        // 4 bitlik işaretli değeri 32 bitlik değere genişletilmesi
        FKaydirmaDegeri := ($FFFFFFF0 or (B4 and $0F))
      else FKaydirmaDegeri := B4;

      FKaydirmaDegeri := FKaydirmaDegeri * CarpanDegeri;
    end;

    AFareOlay.Yatay := FYatayKonum;
    AFareOlay.Dikey := FDikeyKonum;
    AFareOlay.Dugme := FFareDugmeleri;
    AFareOlay.Tekerlek := FKaydirmaDegeri;

    Result := True;
  end
  else
  begin

    if(FKonumDegisti) then
    begin

      AFareOlay.Yatay := FYatayKonum;
      AFareOlay.Dikey := FDikeyKonum;
      AFareOlay.Dugme := 0;
      AFareOlay.Tekerlek := 0;

      FKonumDegisti := False;

      Result := True;

    end else Result := False;
  end;
end;

{==============================================================================
  fare konumunu değiştirir ve durum değişikliğini tetikler
 ==============================================================================}
procedure TFareSurucusu.KonumDegistir(AYatayKonum, ADikeyKonum: TISayi4);
begin

  FYatayKonum := AYatayKonum;
  FDikeyKonum := ADikeyKonum;
  FKonumDegisti := True;
end;

{==============================================================================
  klavye kontrolcüsüne komut gönderir
 ==============================================================================}
procedure TFareSurucusu.KlavyeKontrolcuyeYaz(AKomut: TSayi1);
begin

  AygitGirisiBosMu;
  PortYaz1(KLAVYE_KOMUT_PORT, AKomut);
  //ACKVerisiGeldiMi;
end;

{==============================================================================
  aygıt çıkışının dolu olup olmadığını test eder.
  bilgi: aygıt çıkışının dolu olması, aygıtın veri gönderdiğinin işaretidir
 ==============================================================================}
function TFareSurucusu.AygitCikisiDoluMu: Boolean;
var
  i: TSayi2;
begin

  Result := True;

  for i := 0 to $FFFF do
  begin

    // 0. bit - OBF (Output Buffer Full)
    // veri mevcut biti
    if((PortAl1(KLAVYE_DURUM_PORT) and 1) = 1) then Exit;
  end;

  Result := False;
end;

{==============================================================================
  aygıt girişinin boş olup olmadığını test eder.
  bilgi: aygıt girişinin boş olması, aygıtın veri alabileceğinin işaretidir
 ==============================================================================}
function TFareSurucusu.AygitGirisiBosMu: Boolean;
var
  i: TSayi2;
begin

  Result := True;

  for i := 0 to $FFFF do
  begin

    // 1. bit - IBF (Input Buffer Full)
    // giriş dolu, veri gönderilemez.
    if((PortAl1(KLAVYE_DURUM_PORT) and 2) = 0) then Exit;
  end;

  Result := False;
end;

{==============================================================================
  aygıtın olumlu yanıt verip vermediğini (ACK) kontrol eder
 ==============================================================================}
function TFareSurucusu.ACKVerisiGeldiMi: Boolean;
begin

  if(AygitCikisiDoluMu) then
  begin

    if(PortAl1(KLAVYE_VERI_PORT) = $FA) then

      Result := True
    else Result := False;
  end else Result := False;
end;

{==============================================================================
  fare aygıtındaki bilgiyi okur
 ==============================================================================}
function TFareSurucusu.VeriAl(var AVeri: TSayi1): Boolean;
begin

  if(AygitCikisiDoluMu) then
  begin

    AVeri := PortAl1(KLAVYE_VERI_PORT);
    Result := True;
  end else Result := False;
end;

{==============================================================================
  fare aygıtına komut gönderir
 ==============================================================================}
function TFareSurucusu.KomutGonder(AKomut: TSayi1): Boolean;
begin

  Result := True;

  if(AygitGirisiBosMu) then
  begin

    PortYaz1(KLAVYE_KOMUT_PORT, $D4);
    if(AygitGirisiBosMu) then
    begin

      PortYaz1(KLAVYE_VERI_PORT, AKomut);
      if(ACKVerisiGeldiMi) then Exit;
    end else Result := False;
  end else Result := False;
end;

{==============================================================================
  ps2 fare irq kesme modülü
 ==============================================================================}
procedure FareKesmeCagrisi;
var
  YeniFYI: TSayi4;  // yeni fare yazma imleci
  B1: TSayi1;
begin

  // durum port içeriğini oku. veri mevcut mu ?
  if((PortAl1(KLAVYE_DURUM_PORT) and 1) = 1) then
  begin

    // veriyi port'tan oku
    B1 := PortAl1(KLAVYE_VERI_PORT);

    YeniFYI := (FareYazmaImleci + 1) and (FARE_BELLEK_UZUNLUGU - 1);

    // veri belleği dolu değilse veriyi belleğe kaydet
    if(YeniFYI <> FareOkumaImleci) then
    begin

      FareVeriBellegi[FareYazmaImleci] := B1;
      FareYazmaImleci := YeniFYI;
    end;
  end;
end;

end.
