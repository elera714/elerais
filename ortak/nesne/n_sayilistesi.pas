{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: n_sayilistesi.pas
  Dosya İşlevi: sayı liste nesne işlevlerini gerçekleştirir.

  Güncelleme Tarihi: 31/07/2025

  Bilgi: sistem tasarlama yönünden FPC'nin sağladığı imkanlarından yararlanamama
  konusunda kısıtlamaları aşmak amacıyla (dinamik bellek yönetiminin kullanılamamasına
  bağlı olarak) tasarlanan bu nesnenin yapısı sayı amaçlı kodlanmıştır.

 ==============================================================================}
{$mode objfpc}
unit n_sayilistesi;

interface

uses paylasim;

const
  USTSINIR_SAYILISTESI = 128;    // 4096 byte / 32 byte = 128 adet liste

type
  PSayiListesi = ^TSayiListesi;
  TSayiListesi = object
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
  TSayiListeleri = object
  private
    FSayiListesi: array[0..USTSINIR_SAYILISTESI - 1] of PSayiListesi;
    function SayiListesiAl(ASiraNo: TSayi4): PSayiListesi;
    procedure SayiListesiYaz(ASiraNo: TSayi4; ASayiListesi: PSayiListesi);
  public
    procedure Yukle;
    function Olustur: PSayiListesi;
    procedure YokEt(AKimlik: TKimlik);
    function BosNesneBul: PSayiListesi;
    property SayiListesi[ASiraNo: TSayi4]: PSayiListesi read SayiListesiAl write SayiListesiYaz;
  end;

var
  SayiListesi0: TSayiListeleri;

implementation

{==============================================================================
  sayı nesne listesini ilk değerlerle yükler
 ==============================================================================}
procedure TSayiListeleri.Yukle;
var
  i: TSayi4;
begin

  // bellek girişlerini nesne yapı girişleriyle eşleştir
  for i := 0 to USTSINIR_SAYILISTESI - 1 do SayiListesi[i] := nil;
end;

function TSayiListeleri.SayiListesiAl(ASiraNo: TSayi4): PSayiListesi;
begin

  // istenen verinin belirtilen aralıkta olup olmadığını kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_SAYILISTESI) then
    Result := FSayiListesi[ASiraNo]
  else Result := nil;
end;

procedure TSayiListeleri.SayiListesiYaz(ASiraNo: TSayi4; ASayiListesi: PSayiListesi);
begin

  // istenen verinin belirtilen aralıkta olup olmadığını kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_SAYILISTESI) then
    FSayiListesi[ASiraNo] := ASayiListesi;
end;

{==============================================================================
  sayı liste nesnesini oluşturur
 ==============================================================================}
function TSayiListeleri.Olustur: PSayiListesi;
var
  SL: PSayiListesi;
  p: Isaretci;
begin

  // kullanılabilir nesne bul
  SL := BosNesneBul;
  if not(SL = nil) then
  begin

    // nesne ve nesnenin işleyeceği veriler için 4K bellek bölgesi ayır
    p := GetMem(4096);
    if not(p = nil) then
    begin

      // nesne değişkenlerini ilk değerlerle yükle.
      SL^.BellekBaslangicAdresi := p;
      SL^.MevcutBellekAdresi := p;
      SL^.BellekUzunlugu := 4096;

      Exit(SL);
    end
    else
    begin

      YokEt(SL^.Kimlik);
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
  SL: PSayiListesi;
begin

  if(AKimlik >= 0) and (AKimlik < USTSINIR_SAYILISTESI) then
  begin

    SL := SayiListesi[AKimlik];

    // bellek tahsis edilmişse belleği bırak
    if not(SL^.BellekBaslangicAdresi = nil) then
      FreeMem(SL^.FBellekBaslangicAdresi, 4096);

    FreeMem(SL, SizeOf(TSayiListesi));

    // nesne dizi sırasını nil olarak ata
    SayiListesi[AKimlik] := nil;
  end;
end;

{==============================================================================
  kullanılabilir (boşta) sayı nesnesi bulur
 ==============================================================================}
function TSayiListeleri.BosNesneBul: PSayiListesi;
var
  SL: PSayiListesi;
  i: TSayi4;
begin

  // tüm girişleri incele
  for i := 0 to USTSINIR_SAYILISTESI - 1 do
  begin

    SL := SayiListesi[i];

    // nesne kullanılabilir ise, nesneyi tahsis et
    if(SL = nil) then
    begin

      SL := GetMem(SizeOf(TSayiListesi));
      SayiListesi[i] := SL;

      SL^.Kimlik := i;
      SL^.ElemanSayisi := 0;

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

  FillByte(BellekBaslangicAdresi^, 4096, 0);
  MevcutBellekAdresi := BellekBaslangicAdresi;
  BellekUzunlugu := 4096;
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
