{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: src_ps2.pas
  Dosya İşlevi: ps/2 fare sürücüsü

  Güncelleme Tarihi: 16/07/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit src_ps2;

interface

uses paylasim, sistemmesaj;

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
  TFareSurucusu = object
  private
    // -> yazılımsal hızlandırma amaçlı değişkenler
    FYatayKonum, FDikeyKonum: TISayi4;
    FHiz: Double;
    FFareDugmeleri: TSayi1;
    FKaydirmaDegeri: TISayi4;
    FAygitPaketUzunlugu: TSayi4;
    procedure KlavyeKontrolcuyeYaz(AKomut: Byte);
    function AygitCikisiDoluMu: Boolean;
    function AygitGirisiBosMu: Boolean;
    function ACKVerisiGeldiMi: boolean;
    function VeriAl(var AVeri: TSayi1): Boolean;
    function KomutGonder(AKomut: TSayi1): Boolean;
  public
    procedure Yukle;
    function OlaylariAl(AFareOlay: PFareOlay): Boolean;
  published
    property YatayKonum: Integer read FYatayKonum;
    property DikeyKonum: Integer read FDikeyKonum;
    property FareDugmeleri: Byte read FFareDugmeleri;
    property KaydirmaDegeri: TISayi4 read FKaydirmaDegeri;
  end;

procedure FareKesmeCagrisi;

implementation

uses genel, irq, port, src_vesa20, src_klavye;

const
  KLAVYE_VERI_PORT    = $60;        // okunabilir / yazılabilir
  KLAVYE_DURUM_PORT   = $64;        // okunabilir
  KLAVYE_KOMUT_PORT   = $64;        // yazılabilir

  FARE_BELLEK_UZUNLUGU = 128;

var
  // aygıttan alınarak belleğe aktarılan veri uzunluğu
  ToplamVeriUzunlugu: TSayi4;
  FareVeriBellegi: array[0..FARE_BELLEK_UZUNLUGU - 1] of TISayi1;

{==============================================================================
  ps / 2 fare sürücü yükleme işlevlerini içerir
 ==============================================================================}
procedure TFareSurucusu.Yukle;
var
  Komut: TSayi1;
begin

  // kesmeleri durdur
  cli;

  FAygitPaketUzunlugu := 3;

  // fare kursor pozisyonu
  FYatayKonum := EkranKartSurucusu0.KartBilgisi.YatayCozunurluk div 2;
  FDikeyKonum := EkranKartSurucusu0.KartBilgisi.DikeyCozunurluk div 2;
  FHiz := 1.5;
  FFareDugmeleri := 0;
  FKaydirmaDegeri := 0;

  // klavye kontrolcüsüne "fare port'unu aktifleştir" komutu gönder
  KlavyeKontrolcuyeYaz($A8);

  // klavye kontrolcüsüne "kontrolcü komut byte'ını oku" komutu gönder
  KlavyeKontrolcuyeYaz($20);

  // komut byte içeriğini al
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

          if(Komut = 4) then FAygitPaketUzunlugu := 4;
        end;
      end;

      // fareyi aktifleştir
      KomutGonder($F4);
    end;
  end;

  ToplamVeriUzunlugu := 0;

  // kesme çağrı işlevini ata ve kesmeyi (irq) aktifleştir
  IRQIsleviAta(12, @FareKesmeCagrisi);
end;

{==============================================================================
  fare aygıtından gelen verileri işler ve geri dönüş değişkenlerini günceller
 ==============================================================================}
function TFareSurucusu.OlaylariAl(AFareOlay: PFareOlay): Boolean;
var
  i1: TSayi1;
  CarpanDegeri,
  i4, i: TISayi4;
begin

  // kesmeleri durdur
  cli;

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

  if(ToplamVeriUzunlugu >= FAygitPaketUzunlugu) then
  begin

    FKaydirmaDegeri := 0;
    FFareDugmeleri := 0;

    i1 := FareVeriBellegi[0];

    FFareDugmeleri := i1 and (4 + 2 + 1);

    // bilgi: fare x hareketi. X SGN + 8 bit = toplam 9 bit
    // eğer hareket sağ tarafa ise gelen değer pozitif
    // eğer hareket sol tarafa ise gelen değer negatif

    // fare x değeri
    i1 := FareVeriBellegi[0];
    if((i1 and 16) = 16) then
      i4 := $FFFFFF00 or FareVeriBellegi[1]
    else i4 := FareVeriBellegi[1];

    // özelleştirilebilir yazılımsal hızlandırma
    FYatayKonum := FYatayKonum + Round(i4 * FHiz);

    // x limit denetimi
    if(FYatayKonum < 0) then
      FYatayKonum := 0
    else if(FYatayKonum > EkranKartSurucusu0.KartBilgisi.YatayCozunurluk - 1) then
      FYatayKonum := EkranKartSurucusu0.KartBilgisi.YatayCozunurluk - 1;

    // bilgi: fare y hareketi. Y SGN + 8 bit = toplam 9 bit
    // eğer hareket aşağıya doğru ise gelen değer negatif
    // eğer hareket yukarıya doğru ise gelen değer pozitif

    // fare y değeri
    // fare değerinin işareti ters yönde değiştiriliyor (üst satırdaki bilgiye bak)
    i1 := FareVeriBellegi[0];
    if((i1 and 32) = 32) then
    begin

      i4 := $FFFFFF00 or FareVeriBellegi[2];
      i4 := Abs(i4);
    end
    else
    begin

      i4 := FareVeriBellegi[2];
      i4 := -i4;
    end;

    // özelleştirilebilir yazılımsal hızlandırma
    FDikeyKonum := FDikeyKonum + Round(i4 * (FHiz));

    // x limit denetimi
    if(FDikeyKonum < 0) then
      FDikeyKonum := 0
    else if(FDikeyKonum > EkranKartSurucusu0.KartBilgisi.DikeyCozunurluk - 1) then
      FDikeyKonum := EkranKartSurucusu0.KartBilgisi.DikeyCozunurluk - 1;

    // paket sayısı 3'ten fazla ise diğer değerleri de işle
    if(FAygitPaketUzunlugu > 3) then
    begin

      FFareDugmeleri := FFareDugmeleri + (FareVeriBellegi[3] and 16);
      FFareDugmeleri := FFareDugmeleri + (FareVeriBellegi[3] and 32);

      // tekerlek çevirme çarpan değeri
      CarpanDegeri := 1;
      if(TusDurumSolDegisim = tdBasildi) then CarpanDegeri := TEKERLEK_CARPAN_DEGERI;

      if((FareVeriBellegi[3] and 8) = 8) then
        // 4 bitlik işaretli değeri 32 bitlik değere genişletilmesi
        FKaydirmaDegeri := ($FFFFFFF0 or (FareVeriBellegi[3] and $0F))
      else FKaydirmaDegeri := FareVeriBellegi[3];

      FKaydirmaDegeri := FKaydirmaDegeri * CarpanDegeri;
    end;

    // işlenen verileri fare belleğinden sil
    if(ToplamVeriUzunlugu > FAygitPaketUzunlugu) then
    begin

      for i := FAygitPaketUzunlugu to ToplamVeriUzunlugu - 1 do
      begin

        FareVeriBellegi[i - FAygitPaketUzunlugu] := FareVeriBellegi[i];
      end;
    end;

    // sayacı güncelle
    Dec(ToplamVeriUzunlugu, FAygitPaketUzunlugu);

    AFareOlay^.Yatay := FYatayKonum;
    AFareOlay^.Dikey := FDikeyKonum;
    AFareOlay^.Dugme := FFareDugmeleri;
    AFareOlay^.Tekerlek := FKaydirmaDegeri;

    Result := True;
  end else Result := False;

  // kesmeleri aktifleştir & çık
  sti;
end;

{==============================================================================
  klavye kontrolcüsüne komut gönderir
 ==============================================================================}
procedure TFareSurucusu.KlavyeKontrolcuyeYaz(AKomut: Byte);
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
  ps / 2 fare irq kesme modülü
 ==============================================================================}
procedure FareKesmeCagrisi;
var
  B1: TSayi1;
begin

  // durum port içeriğini oku. veri mevcut mu ?
  if((PortAl1(KLAVYE_DURUM_PORT) and 1) = 1) then
  begin

    // veriyi port'tan oku
    B1 := PortAl1(KLAVYE_VERI_PORT);

    // veriyi belleğe kaydet
    FareVeriBellegi[ToplamVeriUzunlugu] := B1;

    // sayacı güncelleştir.
    Inc(ToplamVeriUzunlugu);
    ToplamVeriUzunlugu := (ToplamVeriUzunlugu and (FARE_BELLEK_UZUNLUGU - 1));
  end;
end;

end.
