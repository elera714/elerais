{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: n_sayilistesi.pas
  Dosya İşlevi: sayı liste nesne işlevlerini gerçekleştirir.

  Güncelleme Tarihi: 01/07/2026

  Bilgi: sistem tasarlama yönünden FPC'nin sağladığı imkanlarından yararlanamama
  konusunda kısıtlamaları aşmak amacıyla (dinamik bellek yönetiminin kullanılamamasına
  bağlı olarak) tasarlanan bu nesnenin yapısı sayı amaçlı kodlanmıştır.

 ==============================================================================}
{$mode objfpc}
unit n_sayilistesi;

interface

uses paylasim;

const
  USTSINIR_SAYILISTESI  = 128;                // 4096 byte / 32 byte = 128 adet liste
  SAYILISTESI_KAPASITE  = TSayi4(4096 * 2);   // her bir sayı listesinin kapasitesi

type
  PSayiListesi = ^TSayiListesi;
  TSayiListesi = class
  private
    FKimlik: TKimlik;
    FElemanSayisi: TISayi4;
    FBellekBaslangicAdresi,
    FMevcutBellekAdresi: PISayi4;
    FBellekUzunlugu: TISayi4;
    function SayiAl(ASiraNo: TISayi4): TISayi4;
  public
    procedure Temizle;
    function Ekle(ADeger: TISayi4): TISayi4;
    property Sayi[SiraNo: TISayi4]: TISayi4 read SayiAl;
    property Kimlik: TKimlik read FKimlik write FKimlik;
    property ElemanSayisi: TISayi4 read FElemanSayisi write FElemanSayisi;
    property BellekBaslangicAdresi: PISayi4 read FBellekBaslangicAdresi write FBellekBaslangicAdresi;
    property MevcutBellekAdresi: PISayi4 read FMevcutBellekAdresi write FMevcutBellekAdresi;
    property BellekUzunlugu: TISayi4 read FBellekUzunlugu write FBellekUzunlugu;
  end;

type
  PSayiListeleri = ^TSayiListeleri;
  TSayiListeleri = class
  private
    FSayiListesi: array[0..USTSINIR_SAYILISTESI - 1] of TSayiListesi;
    function Al(ASiraNo: TISayi4): TSayiListesi;
    procedure Yaz(ASiraNo: TISayi4; ASayiListesi: TSayiListesi);
  public
    constructor Create;
    function Olustur: TSayiListesi;
    procedure YokEt(AKimlik: TKimlik);
    function BosNesneBul: TSayiListesi;
    property SayiListesi[ASiraNo: TISayi4]: TSayiListesi read Al write Yaz;
  end;

var
  GSayiListeleri: TSayiListeleri;

implementation

{==============================================================================
  sayı nesne listesini ilk değerlerle yükler
 ==============================================================================}
constructor TSayiListeleri.Create;
var
  i: TSayi4;
begin

  // bellek girişlerini nesne yapı girişleriyle eşleştir
  for i := 0 to USTSINIR_SAYILISTESI - 1 do SayiListesi[i] := nil;
end;

function TSayiListeleri.Al(ASiraNo: TISayi4): TSayiListesi;
begin

  // istenen verinin belirtilen aralıkta olup olmadığını kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_SAYILISTESI) then
    Result := FSayiListesi[ASiraNo]
  else Result := nil;
end;

procedure TSayiListeleri.Yaz(ASiraNo: TISayi4; ASayiListesi: TSayiListesi);
begin

  // istenen verinin belirtilen aralıkta olup olmadığını kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_SAYILISTESI) then
    FSayiListesi[ASiraNo] := ASayiListesi;
end;

{==============================================================================
  sayı liste nesnesini oluşturur
 ==============================================================================}
function TSayiListeleri.Olustur: TSayiListesi;
var
  SL: TSayiListesi;
  p: Isaretci;
begin

  // kullanılabilir nesne bul
  SL := BosNesneBul;
  if not(SL = nil) then
  begin

    // nesne ve nesnenin işleyeceği veriler için 4K bellek bölgesi ayır
    p := GetMem(SAYILISTESI_KAPASITE);
    if not(p = nil) then
    begin

      // nesne değişkenlerini ilk değerlerle yükle.
      SL.BellekBaslangicAdresi := p;
      SL.MevcutBellekAdresi := p;
      SL.BellekUzunlugu := SAYILISTESI_KAPASITE;

      Exit(SL);
    end
    else
    begin

      YokEt(SL.Kimlik);
      Exit(nil);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  sayı liste nesnesini yok eder.
 ==============================================================================}
procedure TSayiListeleri.YokEt(AKimlik: TKimlik);
var
  SL: TSayiListesi;
begin

  if(AKimlik >= 0) and (AKimlik < USTSINIR_SAYILISTESI) then
  begin

    SL := SayiListesi[AKimlik];

    // bellek tahsis edilmişse belleği bırak
    if not(SL.BellekBaslangicAdresi = nil) then
      FreeMem(SL.FBellekBaslangicAdresi, SAYILISTESI_KAPASITE);

    FreeMem(SL, SizeOf(TSayiListesi));

    // nesne dizi sırasını nil olarak ata
    SayiListesi[AKimlik] := nil;
  end;
end;

{==============================================================================
  kullanılabilir (boşta) sayı nesnesi bulur
 ==============================================================================}
function TSayiListeleri.BosNesneBul: TSayiListesi;
var
  SL: TSayiListesi;
  i: TSayi4;
begin

  // tüm girişleri incele
  for i := 0 to USTSINIR_SAYILISTESI - 1 do
  begin

    SL := SayiListesi[i];

    // nesne kullanılabilir ise, nesneyi tahsis et
    if(SL = nil) then
    begin

      SL := TSayiListesi.Create; // GetMem(SizeOf(TSayiListesi));
      SayiListesi[i] := SL;

      SL.Kimlik := i;
      SL.ElemanSayisi := 0;

      Exit(SL);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  yazı liste elemanlarını temizler
 ==============================================================================}
procedure TSayiListesi.Temizle;
begin

  FillByte(BellekBaslangicAdresi^, SAYILISTESI_KAPASITE, 0);
  MevcutBellekAdresi := BellekBaslangicAdresi;
  BellekUzunlugu := SAYILISTESI_KAPASITE;
  FElemanSayisi := 0;
end;

{==============================================================================
  liste nesnesine eleman ekler
 ==============================================================================}
function TSayiListesi.Ekle(ADeger: TISayi4): TISayi4;
var
  p: PISayi4;
begin

  if(BellekUzunlugu > 0) then
  begin

    // yazı uzunluğu & değeri kaydet
    p := MevcutBellekAdresi;
    p^ := ADeger;

    // bir sonraki kaydın yapılacağı bellek adresini belirle
    Inc(FMevcutBellekAdresi);

    // bellek kapasitesini azalt
    BellekUzunlugu := BellekUzunlugu - 4;

    // eleman sayısını 1 artır
    Inc(FElemanSayisi);

    Result := FElemanSayisi - 1;
  end else Result := -1;
end;

{==============================================================================
  listenin belirtilen elemanını geriye döndürür
 ==============================================================================}
function TSayiListesi.SayiAl(ASiraNo: TISayi4): TISayi4;
var
  p: PISayi4;
begin

  // 1. eğer eleman yok ise
  // 2. istenen sıra, eleman sayısına eşit veya büyükse ...
  if(ElemanSayisi = 0) or (ASiraNo >= ElemanSayisi) then
  begin

    Result := -1;
    Exit;
  end;

  // ilk elemana konumlan
  p := BellekBaslangicAdresi;
  Inc(p, ASiraNo);

  // geri dönüş değeri
  Result := p^;
end;

end.
