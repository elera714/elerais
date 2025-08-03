{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: src_ps2.pas
  Dosya İşlevi: ps / 2 fare sürücüsü

  Güncelleme Tarihi: 23/07/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit src_ps2;

interface

uses paylasim, sistemmesaj;

type
  PFareOlay = ^TFareOlay;
  TFareOlay = record
    Yatay, Dikey: TISayi4;
    Dugme: TSayi1;
    Tekerlek: TISayi1;
  end;

type
  TFareSurucusu = object
  private
    // -> yazılımsal hızlandırma amaçlı değişkenler
    FYatayDeger, FDikeyDeger, FHiz: Double;
    // yazılımsal hızlandırma amaçlı değişkenler <-
    FYatayKonum, FDikeyKonum: TISayi4;
    FFareDugmeleri: TSayi1;
    FKaydirmaDegeri: TISayi1;
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
    property KaydirmaDegeri: TISayi1 read FKaydirmaDegeri;
  end;

procedure FareKesmeCagrisi;

implementation

uses genel, irq, port, src_vesa20;

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
  FYatayDeger := EkranKartSurucusu0.KartBilgisi.YatayCozunurluk div 2;
  FYatayKonum := Round(FYatayDeger);
  FDikeyDeger := EkranKartSurucusu0.KartBilgisi.DikeyCozunurluk div 2;
  FDikeyKonum := Round(FDikeyDeger);
  FHiz := 1.8;
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
  B1: TISayi1;
  B2: TISayi2;
  i: TISayi4;
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

    B1 := FareVeriBellegi[0];

    // eğer değer taşması yoksa paketi işle
    if((B1 and $C0) = 0) then
    begin

      B1 := B1 and (4 + 2 + 1);
      FFareDugmeleri := B1;

      // NOT: fare x hareketi. X SGN + 8 bit = toplam 9 bit
      // eğer hareket sağ tarafa ise gelen değer pozitif
      // eğer hareket sol tarafa ise gelen değer negatif

      // fare x değeri
      B1 := FareVeriBellegi[0];
      B2 := (((B1 shr 4) and 1) shl 8) or FareVeriBellegi[1];

      // özelleştirilebilir yazılımsal hızlandırma
      FYatayDeger += (B2 * FHiz);

      // x limit denetimi
      if(FYatayDeger < 0) then
        FYatayDeger := 0
      else if(FYatayDeger > EkranKartSurucusu0.KartBilgisi.YatayCozunurluk - 1) then
        FYatayDeger := EkranKartSurucusu0.KartBilgisi.YatayCozunurluk - 1;

      FYatayKonum := Round(FYatayDeger);

      // NOT: fare y hareketi. Y SGN + 8 bit = toplam 9 bit
      // eğer hareket aşağıya doğru ise gelen değer negatif
      // eğer hareket yukarıya doğru ise gelen değer pozitif

      // fare y değeri
      B1 := FareVeriBellegi[0];

      B2 := (((B1 shr 5) and 1) shl 8) or FareVeriBellegi[2];
      if(B2 < 0) then
        B2 := Abs(B2)
      else B2 := -B2;

      // özelleştirilebilir yazılımsal hızlandırma
      FDikeyDeger += B2 * (FHiz);

      // x limit denetimi
      if(FDikeyDeger < 0) then
        FDikeyDeger := 0
      else if(FDikeyDeger > EkranKartSurucusu0.KartBilgisi.DikeyCozunurluk - 1) then
        FDikeyDeger := EkranKartSurucusu0.KartBilgisi.DikeyCozunurluk - 1;

      FDikeyKonum := Round(FDikeyDeger);

      // paket sayısı 3'ten fazla ise diğer değerleri de işle
      if(FAygitPaketUzunlugu > 3) then
      begin

        FFareDugmeleri += (FareVeriBellegi[3] and 16);
        FFareDugmeleri += (FareVeriBellegi[3] and 32);

        if((FareVeriBellegi[3] and 8) = 8) then
          FKaydirmaDegeri := $F0 or (FareVeriBellegi[3] and $F)
        else FKaydirmaDegeri := (FareVeriBellegi[3] and $F);

        // SISTEM_MESAJ_S16(RENK_LACIVERT, '-> Değer: ', B1, 2);
      end;
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
