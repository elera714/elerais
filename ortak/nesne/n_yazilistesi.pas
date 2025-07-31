{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: n_yazilistesi.pas
  Dosya İşlevi: yazı liste nesne işlevlerini gerçekleştirir.

  Güncelleme Tarihi: 31/07/2025

  Bilgi: sistem tasarlama yönünden FPC'nin sağladığı imkanlarından yararlanamama
  konusunda kısıtlamaları aşmak amacıyla (dinamik bellek yönetiminin kullanılamamasına
  bağlı olarak) tasarlanan bu nesnenin yapısı yazı amaçlı (karakter katarı olarak,
  1 byte veri uzunluğu + veri) kodlanmıştır.

 ==============================================================================}
{$mode objfpc}
unit n_yazilistesi;

interface

uses paylasim;

const
  USTSINIR_YAZILISTESI = 128;    // 4096 byte / 32 byte = 128 adet liste

type
  TRenkYazi = record
    Renk: TRenk;
    Yazi: string;
  end;

type
  PYaziListesi = ^TYaziListesi;
  TYaziListesi = object
  private
    FKimlik: TKimlik;
    FElemanSayisi: TISayi4;
    FBellekBaslangicAdresi,
    FMevcutBellekAdresi: Isaretci;
    FBellekUzunlugu: TISayi4;
    function YaziAl(ASiraNo: TISayi4): string;
  public
    procedure Temizle;
    function Ekle(ADeger: string; AYaziRengi: TRenk = RENK_SIYAH): TISayi4;
    function RenkYaziAl(ASiraNo: TISayi4): TRenkYazi;
    property Yazi[SiraNo: TISayi4]: string read YaziAl;
    property Kimlik: TKimlik read FKimlik write FKimlik;
    property ElemanSayisi: TISayi4 read FElemanSayisi write FElemanSayisi;
    property BellekBaslangicAdresi: Isaretci read FBellekBaslangicAdresi write FBellekBaslangicAdresi;
    property MevcutBellekAdresi: Isaretci read FMevcutBellekAdresi write FMevcutBellekAdresi;
    property BellekUzunlugu: TISayi4 read FBellekUzunlugu write FBellekUzunlugu;
  end;

type
  PYaziListeleri = ^TYaziListeleri;
  TYaziListeleri = object
  private
    FYaziListeleri: array[0..USTSINIR_YAZILISTESI - 1] of PYaziListesi;
    function YaziListesiAl(ASiraNo: TSayi4): PYaziListesi;
    procedure YaziListesiYaz(ASiraNo: TSayi4; AYaziListesi: PYaziListesi);
  public
    procedure Yukle;
    function Olustur: PYaziListesi;
    procedure YokEt(AKimlik: TKimlik);
    function BosNesneBul: PYaziListesi;
    property YaziListesi[ASiraNo: TSayi4]: PYaziListesi read YaziListesiAl write YaziListesiYaz;
  end;

var
  YaziListesi0: TYaziListeleri;

implementation

uses islevler;

{==============================================================================
  yazı nesne listesini ilk değerlerle yükler
 ==============================================================================}
procedure TYaziListeleri.Yukle;
var
  i: TSayi4;
begin

  // dizi nesne girişlerini ilk değerlerle yükle
  for i := 0 to USTSINIR_YAZILISTESI - 1 do YaziListesi[i] := nil;
end;

function TYaziListeleri.YaziListesiAl(ASiraNo: TSayi4): PYaziListesi;
begin

  // istenen verinin belirtilen aralıkta olup olmadığını kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_YAZILISTESI) then
    Result := FYaziListeleri[ASiraNo]
  else Result := nil;
end;

procedure TYaziListeleri.YaziListesiYaz(ASiraNo: TSayi4; AYaziListesi: PYaziListesi);
begin

  // istenen verinin belirtilen aralıkta olup olmadığını kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_YAZILISTESI) then
    FYaziListeleri[ASiraNo] := AYaziListesi;
end;

{==============================================================================
  yazı liste nesnesini oluşturur
 ==============================================================================}
function TYaziListeleri.Olustur: PYaziListesi;
var
  YL: PYaziListesi;
  p: Isaretci;
begin

  // kullanılabilir nesne bul
  YL := BosNesneBul;
  if not(YL = nil) then
  begin

    // nesne ve nesnenin işleyeceği veriler için 4K bellek bölgesi ayır
    p := GetMem(4096);
    if not(p = nil) then
    begin

      // nesne değişkenlerini ilk değerlerle yükle.
      YL^.BellekBaslangicAdresi := p;
      YL^.MevcutBellekAdresi := p;
      YL^.BellekUzunlugu := 4096;

      Exit(YL);
    end
    else
    begin

      YokEt(YL^.Kimlik);
      Exit(nil);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  yazı liste nesnesini yok eder.
 ==============================================================================}
procedure TYaziListeleri.YokEt(AKimlik: TKimlik);
var
  YL: PYaziListesi;
begin

  if(AKimlik >= 0) and (AKimlik < USTSINIR_YAZILISTESI) then
  begin

    YL := YaziListesi[AKimlik];

    // bellek tahsis edilmişse belleği bırak
    if not(YL^.BellekBaslangicAdresi = nil) then
      FreeMem(YL^.FBellekBaslangicAdresi, 4096);

    FreeMem(YL, SizeOf(TYaziListesi));

    // nesne dizi sırasını nil olarak ata
    YaziListesi[AKimlik] := nil;
  end;
end;

{==============================================================================
  kullanılabilir (boşta) yazı nesnesi bulur
 ==============================================================================}
function TYaziListeleri.BosNesneBul: PYaziListesi;
var
  YL: PYaziListesi;
  i: TSayi4;
begin

  // tüm girişleri incele
  for i := 0 to USTSINIR_YAZILISTESI - 1 do
  begin

    YL := YaziListesi[i];

    // nesne kullanılabilir ise, nesneyi tahsis et
    if(YL = nil) then
    begin

      YL := GetMem(SizeOf(TYaziListesi));
      YaziListesi[i] := YL;

      YL^.Kimlik := i;
      YL^.ElemanSayisi := 0;

      Exit(YL);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  yazı liste elemanlarını temizler
 ==============================================================================}
procedure TYaziListesi.Temizle;
begin

  FillByte(BellekBaslangicAdresi^, 4096, 0);
  MevcutBellekAdresi := BellekBaslangicAdresi;
  BellekUzunlugu := 4096;
  FElemanSayisi := 0;
end;

{==============================================================================
  liste nesnesine eleman ekler
 ==============================================================================}
function TYaziListesi.Ekle(ADeger: string; AYaziRengi: TRenk = RENK_SIYAH): TISayi4;
var
  Uzunluk: TSayi4;
  p: PKarakterKatari;
begin

  // verinin uzunluğunu al
  Uzunluk := Length(ADeger);

  // 4 byte yazı rengi + 1 byte yazı uzunluk değeri
  if(Uzunluk = 0) or (Uzunluk + (4 + 1) > BellekUzunlugu) then Exit(-1);

  // yazı uzunluğunu kaydet
  p := MevcutBellekAdresi;
  PRenk(p)^ := AYaziRengi;

  p := MevcutBellekAdresi + 4;
  PByte(p)^ := Uzunluk;

  // yazının kendisini kaydet
  p := MevcutBellekAdresi + (4 + 1);
  Tasi2(@ADeger[1], p, Uzunluk);

  // bir sonraki kaydın yapılacağı bellek adresini belirle
  MevcutBellekAdresi := MevcutBellekAdresi + Uzunluk + (4 + 1);

  // bellek kapasitesini azalt
  BellekUzunlugu := BellekUzunlugu - (Uzunluk + (4 + 1));

  // eleman sayısını 1 artır
  Inc(FElemanSayisi);

  Result := FElemanSayisi - 1;
end;

{==============================================================================
  listenin belirtilen yazı elemanını ve rengini geriye döndürür
 ==============================================================================}
function TYaziListesi.RenkYaziAl(ASiraNo: TISayi4): TRenkYazi;
var
  p: PSayi1;
  i: TSayi2;
  Uzunluk: TSayi4;
begin

  // 1. eğer eleman yok ise
  // 2. istenen index eleman sayısına eşit veya büyükse ...
  if(ElemanSayisi = 0) or (ASiraNo >= ElemanSayisi) then
  begin

    Result.Renk := RENK_SIYAH;
    Result.Yazi := '';
    Exit;
  end;

  // ilk elemana konumlan
  p := PByte(BellekBaslangicAdresi);

  // istenen eleman 0'dan büyükse belirtilen elemana konumlan
  if(ASiraNo > 0) then
  begin

    for i := 0 to ASiraNo - 1 do
    begin

      Uzunluk := (p + 4)^;
      Inc(p, Uzunluk + (4 + 1));
    end;
  end;

  // geri dönüş değeri
  Result.Renk := PRenk(p)^;
  Result.Yazi := PKarakterKatari(p + 4)^;
end;

{==============================================================================
  listenin belirtilen yazı elemanını geriye döndürür
 ==============================================================================}
function TYaziListesi.YaziAl(ASiraNo: TISayi4): string;
var
  RY: TRenkYazi;
begin

  RY := RenkYaziAl(ASiraNo);
  Result := RY.Yazi;
end;

end.
