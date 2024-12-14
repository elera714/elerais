{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: saglama.pas
  Dosya İşlevi: verilerin toplam sağlama işlemini gerçekleştirir

  Güncelleme Tarihi: 30/09/2019

 ==============================================================================}
{$mode objfpc}
unit saglama;

{
  kontrol toplamı örneği:
  08 00 00 00 00 01 00 a7 61 62 63 64 65 66 67 68
  69 6a 6b

  önemli: kontrol toplamı yapılırken, değerlerin içerisinde sağlama (checksum) değeri
  var ise sağlama değeri işlem öncesi mutlaka sıfırlanmalıdır.

  0800
  0000
  0001
  0047
  6162
  6364
  6566
  6768        1. toplama işleminden sonra, yüksek 16 bitlik değer ($2) alçak 16
  696a        bitlik değere ($03B1) eklenir. $03B1 + $2 = $03B3
    6b
+-------      2. $03B3 değeri mantıksal NOT işlemine tabi tutulur. $03B3 -> $FC4C
 203B1

}
interface

uses paylasim;

function SaglamasiniYap(AVeriAdresi: Isaretci; AVeriUzunlugu: TSayi2;
  ASahteBaslikAdresi: Isaretci; ASahteBaslikUzunlugu: TSayi2): TSayi2;

implementation

uses donusum;

{==============================================================================
  verilerin toplam sağlama işlemini gerçekleştirir
 ==============================================================================}
function SaglamasiniYap(AVeriAdresi: Isaretci; AVeriUzunlugu: TSayi2;
  ASahteBaslikAdresi: Isaretci; ASahteBaslikUzunlugu: TSayi2): TSayi2;
var
  WordVeriAdresi: PSayi2;
  i, WordVeriUzunlugu: TSayi2;
  _SaglamaToplami: TSayi4;
begin

  // eğer veri bellek adresi verilmemiş veya uzunluk 0 ise çık
  if(AVeriAdresi = nil) or (AVeriUzunlugu = 0) then Exit(0);

  // sağlama toplamı ilk değer ataması
  _SaglamaToplami := 0;

  // 1. önce veri değerlerini topla
  //----------------------------------------------------------------------------

  // toplanacak word sayısı
  WordVeriUzunlugu := (AVeriUzunlugu shr 1);

  // word değerleri topla
  WordVeriAdresi := AVeriAdresi;
  if(WordVeriUzunlugu > 1) then
  begin

    for i := 0 to WordVeriUzunlugu - 1 do
    begin

      _SaglamaToplami := _SaglamaToplami + WordVeriAdresi^;
      Inc(WordVeriAdresi);
    end;
  end;

  // eğer geriye tek değer (byte) kaldıysa onu da toplama ekle
  if((AVeriUzunlugu mod 2) = 1) then
  begin

    _SaglamaToplami := _SaglamaToplami + PByte(WordVeriAdresi)^;
  end;

  // 2. daha sonra (var) ise sahte başlık değerlerini topla
  //----------------------------------------------------------------------------
  if(ASahteBaslikAdresi <> nil) and (ASahteBaslikUzunlugu > 0) then
  begin

    // toplanacak word sayısı
    WordVeriUzunlugu := (ASahteBaslikUzunlugu shr 1);

    // word değerleri topla
    WordVeriAdresi := ASahteBaslikAdresi;
    if(WordVeriUzunlugu > 1) then
    begin

      for i := 0 to WordVeriUzunlugu - 1 do
      begin

        _SaglamaToplami := _SaglamaToplami + WordVeriAdresi^;
        Inc(WordVeriAdresi);
      end;
    end;

    // eğer geriye tek değer (byte) kaldıysa onu da toplama ekle
    if((ASahteBaslikUzunlugu mod 2) = 1) then
    begin

      _SaglamaToplami := _SaglamaToplami + PByte(WordVeriAdresi)^;
    end;
  end;

  // word değeri aşan (17 ve sonraki bitler) kısmı ilk 16 bit değere ekle
  _SaglamaToplami := (_SaglamaToplami mod $10000) + (_SaglamaToplami div $10000);

  // toplam değerin ilk 8 bit'i ile diğer 8 bit'i yer değiştir
  _SaglamaToplami := Takas2(Word(_SaglamaToplami));

  // son olarak değeri ters çevir
  Result := not _SaglamaToplami;
end;

end.
