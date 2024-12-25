{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: n_sayilistesi.pas
  Dosya İşlevi: sayı liste nesne işlevlerini gerçekleştirir.

  Güncelleme Tarihi: 24/12/2024

  Bilgi: sistem tasarlama yönünden FPC'nin sağladığı imkanlarından yararlanamama
  konusunda kısıtlamaları aşmak amacıyla (dinamik bellek yönetiminin kullanılamamasına
  bağlı olarak) tasarlanan bu nesnenin yapısı sayı amaçlı kodlanmıştır.

 ==============================================================================}
{$mode objfpc}
unit n_sayilistesi;

interface

uses paylasim;

type
  PSayiListesi = ^TSayiListesi;
  TSayiListesi = object
  private
    FTanimlayici: Integer;
    FNesneKullanilabilir: Boolean;    // kullanılabilir = boşta = kullanıma hazır
    FBellekBaslangicAdresi,
    FMevcutBellekAdresi: PInteger;
    FBellekUzunlugu: Integer;
    FElemanSayisi: Integer;
    function ElemanAl(ASiraNo: TISayi4): TISayi4;
  public
    function Olustur: PSayiListesi;
    procedure YokEt;
    function KullanilabilirNesneBul: PSayiListesi;
    procedure Temizle;
    function Ekle(ADeger: Integer): Integer;
    property Eleman[SiraNo: Integer]: Integer read ElemanAl;
    property BellekBaslangicAdresi: PInteger read FBellekBaslangicAdresi write FBellekBaslangicAdresi;
    property MevcutBellekAdresi: PInteger read FMevcutBellekAdresi write FMevcutBellekAdresi;
    property BellekUzunlugu: Integer read FBellekUzunlugu write FBellekUzunlugu;
  published
    property Tanimlayici: Integer read FTanimlayici write FTanimlayici;
    property NesneKullanilabilir: Boolean read FNesneKullanilabilir write FNesneKullanilabilir;
    property ElemanSayisi: Integer read FElemanSayisi write FElemanSayisi;
  end;

implementation

uses genel;

{==============================================================================
  sayı liste nesnesini oluşturur
 ==============================================================================}
function TSayiListesi.Olustur: PSayiListesi;
var
  p: PSayiListesi;
  p2: Isaretci;
begin

  // kullanılabilir nesne bul
  p := KullanilabilirNesneBul;
  if not(p = nil) then
  begin

    // nesne ve nesnenin işleyeceği veriler için 4K bellek bölgesi ayır
    p2 := GGercekBellek.Ayir(4096);
    if not(p2 = nil) then
    begin

      // nesne değişkenlerini ilk değerlerle yükle.
      p^.BellekBaslangicAdresi := p2;
      p^.MevcutBellekAdresi := p2;
      p^.BellekUzunlugu := 4096;
      p^.ElemanSayisi := 0;

      Result := p;
    end
    else
    begin

      YokEt;
      p := nil;
    end;
  end;

  Result := p;
end;

{==============================================================================
  sayı liste nesnesini yok eder.
 ==============================================================================}
procedure TSayiListesi.YokEt;
begin

  // bellek tahsis edilmişse öncelikle belleği serbest bırak
  if not(BellekBaslangicAdresi = nil) then
    GGercekBellek.YokEt(FBellekBaslangicAdresi, 4096);

  // nesnenin kullanılabilir özelliğini aktifleştir
  GSayiListesi[Tanimlayici]^.NesneKullanilabilir := True;
end;

{==============================================================================
  kullanılabilir (boşta) sayı nesnesi bulur
 ==============================================================================}
function TSayiListesi.KullanilabilirNesneBul: PSayiListesi;
var
  p: PSayiListesi;
  i: TSayi4;
begin

  // tüm girişleri incele
  for i := 0 to USTSINIR_SAYILISTESI - 1 do
  begin

    p := GSayiListesi[i];

    // nesne kullanılabilir ise, nesneyi tahsis et
    if(P^.NesneKullanilabilir) then
    begin

      P^.NesneKullanilabilir := False;
      Result := p;
      Exit;
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
function TSayiListesi.Ekle(ADeger: Integer): Integer;
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
function TSayiListesi.ElemanAl(ASiraNo: TISayi4): TISayi4;
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
