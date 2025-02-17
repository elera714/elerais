{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: n_yazilistesi.pas
  Dosya İşlevi: yazı liste nesne işlevlerini gerçekleştirir.

  Güncelleme Tarihi: 12/01/2025

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
  TRenkYazi = record
    Renk: TRenk;
    Yazi: string;
  end;

type
  PYaziListesi = ^TYaziListesi;
  TYaziListesi = object
  private
    FTanimlayici: TISayi4;
    FNesneKullanilabilir: Boolean;    // kullanılabilir = boşta = kullanıma hazır
    FBellekBaslangicAdresi,
    FMevcutBellekAdresi: Isaretci;
    FBellekUzunlugu: TISayi4;
    FElemanSayisi: TISayi4;
    function ElemanAl(ASiraNo: TISayi4): string;
  public
    function Olustur: PYaziListesi;
    procedure YokEt;
    function KullanilmayanNesneBul: PYaziListesi;
    procedure Temizle;
    function Ekle(ADeger: string; AYaziRengi: TRenk = RENK_SIYAH): TISayi4;
    function ElemanAl2(ASiraNo: TISayi4): TRenkYazi;
    property Eleman[SiraNo: TISayi4]: string read ElemanAl;
    property BellekBaslangicAdresi: Isaretci read FBellekBaslangicAdresi write FBellekBaslangicAdresi;
    property MevcutBellekAdresi: Isaretci read FMevcutBellekAdresi write FMevcutBellekAdresi;
    property BellekUzunlugu: TISayi4 read FBellekUzunlugu write FBellekUzunlugu;
  published
    property Tanimlayici: TISayi4 read FTanimlayici write FTanimlayici;
    property NesneKullanilabilir: Boolean read FNesneKullanilabilir write FNesneKullanilabilir;
    property ElemanSayisi: TISayi4 read FElemanSayisi write FElemanSayisi;
  end;

implementation

uses genel, islevler;

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
    p2 := GGercekBellek.Ayir(4095);
    if not(p2 = nil) then
    begin

      // nesne değişkenlerini ilk değerlerle yükle.
      p^.BellekBaslangicAdresi := p2;
      p^.MevcutBellekAdresi := p2;
      p^.BellekUzunlugu := 4095;
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
    GGercekBellek.YokEt(FBellekBaslangicAdresi, 4095);

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
  for i := 0 to USTSINIR_YAZILISTESI - 1 do
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
function TYaziListesi.Ekle(ADeger: string; AYaziRengi: TRenk = RENK_SIYAH): TISayi4;
var
  Uzunluk: TSayi1;
  p: PKarakterKatari;
begin

  // verinin uzunluğunu al
  Uzunluk := Length(ADeger);

  // 4 byte yazı rengi + 1 byte yazı uzunluk değeri
  if(Uzunluk = 0) or (Uzunluk + (4 + 1) > BellekUzunlugu) then Exit;

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
function TYaziListesi.ElemanAl2(ASiraNo: TISayi4): TRenkYazi;
var
  p: PSayi1;
  i: TSayi2;
  Uzunluk: TSayi1;
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
function TYaziListesi.ElemanAl(ASiraNo: TISayi4): string;
var
  RY: TRenkYazi;
begin

  RY := ElemanAl2(ASiraNo);
  Result := RY.Yazi;
end;

end.
