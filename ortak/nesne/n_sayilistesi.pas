{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: n_sayilistesi.pas
  Dosya İşlevi: sayı liste nesne işlevlerini gerçekleştirir.

  Güncelleme Tarihi: 13/08/2026

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
    FBellekBaslangicAdresi,
    FMevcutBellekAdresi: PISayi4;
    FBellekUzunlugu: TISayi4;
    FElemanSayisi: TISayi4;
    function SayiAl(ASiraNo: TISayi4): TISayi4;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Temizle;
    function Ekle(ADeger: TISayi4): TISayi4;
    property Sayi[SiraNo: TISayi4]: TISayi4 read SayiAl;
    property BellekBaslangicAdresi: PISayi4 read FBellekBaslangicAdresi write FBellekBaslangicAdresi;
    property MevcutBellekAdresi: PISayi4 read FMevcutBellekAdresi write FMevcutBellekAdresi;
    property BellekUzunlugu: TISayi4 read FBellekUzunlugu write FBellekUzunlugu;
    property ElemanSayisi: TISayi4 read FElemanSayisi write FElemanSayisi;
  end;

implementation

{==============================================================================
  sayı liste nesnesini oluştur
 ==============================================================================}
constructor TSayiListesi.Create;
var
  p: Pointer;
begin

  // nesne ve nesnenin işleyeceği veriler için bellekte yer ayır
  p := GetMem(SAYILISTESI_KAPASITE);
  if not(p = nil) then
  begin

    // nesne değişkenlerini ilk değerlerle yükle.
    BellekBaslangicAdresi := p;
    MevcutBellekAdresi := p;
    BellekUzunlugu := SAYILISTESI_KAPASITE;
  end;

  ElemanSayisi := 0;
end;

{==============================================================================
  sayı liste nesnesini yok et
 ==============================================================================}
destructor TSayiListesi.Destroy;
begin

  // bellek tahsis edilmişse belleği bırak
  if not(BellekBaslangicAdresi = nil) then
    FreeMem(FBellekBaslangicAdresi, SAYILISTESI_KAPASITE);

  inherited Destroy;
end;

{==============================================================================
  sayı liste elemanlarını temizler
 ==============================================================================}
procedure TSayiListesi.Temizle;
begin

  FillByte(BellekBaslangicAdresi^, SAYILISTESI_KAPASITE, 0);
  MevcutBellekAdresi := BellekBaslangicAdresi;
  BellekUzunlugu := SAYILISTESI_KAPASITE;
  FElemanSayisi := 0;
end;

{==============================================================================
  sayı liste nesnesine eleman ekler
 ==============================================================================}
function TSayiListesi.Ekle(ADeger: TISayi4): TISayi4;
var
  p: PISayi4;
begin

  if(BellekUzunlugu > 0) then
  begin

    // sayı uzunluğu & değeri kaydet
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
