{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: n_yazilistesi.pas
  Dosya İşlevi: yazı liste nesne işlevlerini gerçekleştirir.

  Güncelleme Tarihi: 13/08/2026

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
  USTSINIR_YAZILISTESI  = 128;                // 4096 byte / 32 byte = 128 adet liste
  YAZILISTESI_KAPASITE  = TSayi4(4096 * 2);   // her bir yazı listesinin kapasitesi

type
  TRenkYazi = record
    Renk: TRenk;
    Yazi: string;
  end;

type
  PYaziListesi = ^TYaziListesi;
  TYaziListesi = class
  private
    FBellekBaslangicAdresi,
    FMevcutBellekAdresi: Isaretci;
    FBellekUzunlugu,
    FElemanSayisi: TISayi4;
    function YaziAl(ASiraNo: TISayi4): string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Temizle;
    function Ekle(ADeger: string; AYaziRengi: TRenk = RENK_SIYAH): TISayi4;
    function RenkYaziAl(ASiraNo: TISayi4): TRenkYazi;
    property Yazi[SiraNo: TISayi4]: string read YaziAl;
    property ElemanSayisi: TISayi4 read FElemanSayisi write FElemanSayisi;
    property BellekBaslangicAdresi: Isaretci read FBellekBaslangicAdresi write FBellekBaslangicAdresi;
    property MevcutBellekAdresi: Isaretci read FMevcutBellekAdresi write FMevcutBellekAdresi;
    property BellekUzunlugu: TISayi4 read FBellekUzunlugu write FBellekUzunlugu;
  end;

implementation

uses islevler;

{==============================================================================
  yazı liste nesnesini oluştur
 ==============================================================================}
constructor TYaziListesi.Create;
var
  p: Isaretci;
begin

  // nesne ve nesnenin işleyeceği veriler için bellekte yer ayır
  p := GetMem(YAZILISTESI_KAPASITE);
  if not(p = nil) then
  begin

    // nesne değişkenlerini ilk değerlerle yükle.
    BellekBaslangicAdresi := p;
    MevcutBellekAdresi := p;
    BellekUzunlugu := YAZILISTESI_KAPASITE;
  end;

  ElemanSayisi := 0;
end;

{==============================================================================
  yazı liste nesnesini yok et
 ==============================================================================}
destructor TYaziListesi.Destroy;
begin

  // bellek tahsis edilmişse belleği bırak
  if not(BellekBaslangicAdresi = nil) then
    FreeMem(FBellekBaslangicAdresi, YAZILISTESI_KAPASITE);

  inherited Destroy;
end;

{==============================================================================
  yazı liste elemanlarını temizler
 ==============================================================================}
procedure TYaziListesi.Temizle;
begin

  FillByte(BellekBaslangicAdresi^, YAZILISTESI_KAPASITE, 0);
  MevcutBellekAdresi := BellekBaslangicAdresi;
  BellekUzunlugu := YAZILISTESI_KAPASITE;
  FElemanSayisi := 0;
end;

{==============================================================================
  yazı liste nesnesine eleman ekler
 ==============================================================================}
function TYaziListesi.Ekle(ADeger: string; AYaziRengi: TRenk = RENK_SIYAH): TISayi4;
var
  Uzunluk: TSayi4;
  p: PKarakterKatari;
begin

  // verinin uzunluğunu al
  Uzunluk := Length(ADeger);

  // 4 byte yazı rengi + 1 byte yazı uzunluk değeri
  if(Uzunluk = 0) or (TISayi4(Uzunluk + (4 + 1)) > BellekUzunlugu) then Exit(-1);

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
  BellekUzunlugu := BellekUzunlugu - TISayi4((Uzunluk + (4 + 1)));

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
