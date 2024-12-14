{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: n_yazilistesi.pas
  Dosya İşlevi: yazı liste nesne işlevlerini gerçekleştirir.

  Güncelleme Tarihi: 29/09/2019

  Bilgi: sistem tasarlama yönünden FPC'nin sağladığı imkanlarından yararlanamama
  konusunda kısıtlamaları aşmak amacıyla (dinamik bellek yönetiminin kullanılamamasına
  bağlı olarak) tasarlanan bu nesnenin yapısı yazı amaçlı (karakter katarı olarak,
  1 byte veri uzunluğu + veri) kodlanmıştır.

 ==============================================================================}
{$mode objfpc}
unit n_yazilistesi;

interface

uses paylasim;

type
  PYaziListesi = ^TYaziListesi;
  TYaziListesi = object
  private
    FTanimlayici: Integer;
    FNesneKullanilabilir: Boolean;    // kullanılabilir = boşta = kullanıma hazır
    FBellekBaslangicAdresi,
    FMevcutBellekAdresi: Pointer;
    FBellekUzunlugu: Integer;
    FElemanSayisi: Integer;
    function ElemanAl(ASiraNo: TISayi4): string;
  public
    function Olustur: PYaziListesi;
    procedure YokEt;
    function KullanilmayanNesneBul: PYaziListesi;
    procedure Temizle;
    function Ekle(ADeger: string): Integer;
    property Eleman[SiraNo: Integer]: string read ElemanAl;
    property BellekBaslangicAdresi: Pointer read FBellekBaslangicAdresi write FBellekBaslangicAdresi;
    property MevcutBellekAdresi: Pointer read FMevcutBellekAdresi write FMevcutBellekAdresi;
    property BellekUzunlugu: Integer read FBellekUzunlugu write FBellekUzunlugu;
  published
    property Tanimlayici: Integer read FTanimlayici write FTanimlayici;
    property NesneKullanilabilir: Boolean read FNesneKullanilabilir write FNesneKullanilabilir;
    property ElemanSayisi: Integer read FElemanSayisi write FElemanSayisi;
  end;

implementation

uses genel;

{==============================================================================
  yazı liste nesnesini oluşturur
 ==============================================================================}
function TYaziListesi.Olustur: PYaziListesi;
var
  p: PYaziListesi;
  p2: Isaretci;
begin

  // kullanılabilir nesne bul
  p := KullanilmayanNesneBul;
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
  yazı liste nesnesini yok eder.
 ==============================================================================}
procedure TYaziListesi.YokEt;
begin

  // bellek tahsis edilmişse öncelikle belleği bırak
  if not(BellekBaslangicAdresi = nil) then
    GGercekBellek.YokEt(FBellekBaslangicAdresi, 4096);

  // nesnenin kullanılabilir özelliğini aktifleştir
  GYaziListesi[Tanimlayici]^.NesneKullanilabilir := True;
end;

{==============================================================================
  kullanılabilir (boşta) sayı nesnesi bulur
 ==============================================================================}
function TYaziListesi.KullanilmayanNesneBul: PYaziListesi;
var
  p: PYaziListesi;
  i: TSayi4;
begin

  // tüm girişleri incele
  for i := 1 to USTSINIR_YAZILISTESI do
  begin

    p := GYaziListesi[i];

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
function TYaziListesi.Ekle(ADeger: string): Integer;
var
  Uzunluk: TSayi1;
  p: PKarakterKatari;
begin

  // verinin uzunluğunu al
  Uzunluk := Length(ADeger);

  if(Uzunluk = 0) or (Uzunluk + 1 > BellekUzunlugu) then Exit;

  // yazı uzunluğu & değeri kaydet
  p := MevcutBellekAdresi;
  p^ := Copy(ADeger, 1, Uzunluk);

  // bir sonraki kaydın yapılacağı bellek adresini belirle
  MevcutBellekAdresi := MevcutBellekAdresi + Uzunluk + 1;

  // bellek kapasitesini azalt
  BellekUzunlugu := BellekUzunlugu - (Uzunluk + 1);

  // eleman sayısını 1 artır
  Inc(FElemanSayisi);

  Result := FElemanSayisi - 1;
end;

{==============================================================================
  listenin belirtilen elemanını geriye döndürür
 ==============================================================================}
function TYaziListesi.ElemanAl(ASiraNo: TISayi4): string;
var
  p: PSayi1;
  i: TSayi2;
  Uzunluk: TSayi1;
begin

  // 1. eğer eleman yok ise
  // 2. istenen index eleman sayısına eşit veya büyükse ...
  if(ElemanSayisi = 0) or (ASiraNo >= ElemanSayisi) then
  begin

    Result := '';
    Exit;
  end;

  // ilk elemana konumlan
  p := PByte(BellekBaslangicAdresi);

  // istenen eleman 0'dan büyükse belirtilen elemana konumlan
  if(ASiraNo > 0) then
  begin

    for i := 0 to ASiraNo - 1 do
    begin

      Uzunluk := p^;
      Inc(p, Uzunluk + 1);
    end;
  end;

  // geri dönüş değeri
  Result := PKarakterKatari(p)^;
end;

end.
