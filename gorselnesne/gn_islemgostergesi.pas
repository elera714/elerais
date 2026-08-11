{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_islemgostergesi.pas
  Dosya İşlevi: işlem göstergesi (TProgressBar) yönetim işlevlerini içerir

  Güncelleme Tarihi: 11/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_islemgostergesi;

interface

uses gorselnesne, paylasim, gn_panel;

type
  PIslemGostergesi = ^TIslemGostergesi;
  TIslemGostergesi = class(TPanel)
  public
    FAltDeger, FUstDeger, FMevcutDeger: TISayi8;
    constructor Create; override;
     destructor Destroy; override;
    function Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4): TISayi4;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
    procedure DegerleriBelirle(AAltDeger, AUstDeger: TISayi8);
    procedure MevcutDegerYaz(AMevcutDeger: TISayi8);
  end;

function IslemGostergesiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function IslemGostergesiGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst,
  AGenislik, AYukseklik: TISayi4): TKimlik;

implementation

uses temelgorselnesne, donusum, gn_islevler;

{==============================================================================
  işlem göstergesi kesme çağrılarını yönetir
 ==============================================================================}
function IslemGostergesiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  IslemGostergesi: TIslemGostergesi;
begin

  Result := HATA_ISLEV;

  // $DDCCBBAA
  //      BBAA  -> kesme tarafından değerlendirildi
  // DDCC       -> AIslevNo değeri
  case AIslevNo of

    // nesneyi oluştur
    ISLEV_OLUSTUR:
    begin

      GN := GGorselNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := IslemGostergesiGNOlustur(GN, PISayi4(ADegiskenler + 04)^,
      PISayi4(ADegiskenler + 08)^, PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^);
    end;

    ISLEV_GOSTER:
    begin

      IslemGostergesi := TIslemGostergesi(GGorselNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      IslemGostergesi.Goster;
    end;

    // alt, üst değerlerini belirle
    $010F:
    begin

      IslemGostergesi := TIslemGostergesi(GGorselNesneler.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^,
        gntIslemGostergesi));
      if(IslemGostergesi <> nil) then IslemGostergesi.DegerleriBelirle(PISayi4(ADegiskenler + 04)^,
        PISayi4(ADegiskenler + 08)^);
    end;

    // nesne gösterge pozisyonunu belirle
    $020F:
    begin

      IslemGostergesi := TIslemGostergesi(GGorselNesneler.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^,
        gntIslemGostergesi));
      if(IslemGostergesi <> nil) then IslemGostergesi.MevcutDegerYaz(PISayi4(ADegiskenler + 04)^);
    end;
  end;
end;

{==============================================================================
  uygulama için işlem göstergesi nesnesi oluşturur - api
 ==============================================================================}
function IslemGostergesiGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst,
  AGenislik, AYukseklik: TISayi4): TKimlik;
var
  IslemGostergesi: TIslemGostergesi;
begin

  IslemGostergesi := TIslemGostergesi.Create;

  if(IslemGostergesi = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    IslemGostergesi.Ozellestir(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik);

    Result := IslemGostergesi.Kimlik;
  end;
end;

{==============================================================================
  işlem göstergesi nesnesi oluşturur
 ==============================================================================}
constructor TIslemGostergesi.Create;
begin

  inherited Create;

  NesneTipi := gntIslemGostergesi;

  GGorselNesneler.GorselNesne[FSiraNo] := Self;
end;

{==============================================================================
  işlem göstergesi nesnesini yok eder
 ==============================================================================}
destructor TIslemGostergesi.Destroy;
begin

  GGorselNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  işlem göstergesi nesnesini özelleştirir
 ==============================================================================}
function TIslemGostergesi.Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4): TISayi4;
begin

  Yapilandir2(AKullanimTipi, Self, AAtaNesne, ASol, AUst, AGenislik, AYukseklik,
    0, 0, 0, 0, '');

  OlayCagriAdresi := @OlaylariIsle;

  // diğer değer atamaları
  FAltDeger := 1;
  FUstDeger := 100;
  FMevcutDeger := 0;

  // geri dönüş değeri
  Result := HATA_YOK;
end;

{==============================================================================
  işlem göstergesi nesnesini görüntüler
 ==============================================================================}
procedure TIslemGostergesi.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  işlem göstergesi nesnesini gizler
 ==============================================================================}
procedure TIslemGostergesi.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  işlem göstergesi nesnesini hizalandırır
 ==============================================================================}
procedure TIslemGostergesi.Hizala;
begin

  inherited Hizala;
end;

{==============================================================================
  işlem göstergesi nesnesini çizer
 ==============================================================================}
procedure TIslemGostergesi.Ciz;
var
  CizimAlani, CizimAlani2: TAlan;
  i1: TISayi8;
  s: string;
  i, j: TISayi4;
  d1, d2: Double;
  DegerGosterim: TSayi4;
begin

  // giriş kutusunun çizim alan koordinatlarını al
  CizimAlani := FCizimAlani;

  i1 := (FUstDeger - FAltDeger) + 1;
  d1 := (FMevcutDeger * 100) div i1;
  d2 := (CizimAlani.Sag / 100);
  d2 := d1 * d2;

  // ön renk doldurma işlemi. dolgu öncesi çizim
  DikdortgenDoldur(Self, CizimAlani.Sol, CizimAlani.Ust, CizimAlani.Sag,
    CizimAlani.Alt, $F1F1F1, RENK_BEYAZ);

  // artan renk ile (eğimli) doldur
  CizimAlani2 := CizimAlani;
  CizimAlani2.Sag := CizimAlani2.Sol + Round(d2);
  EgimliDoldur(Self, CizimAlani2, DUGME_NORMAL_ILKRENK, DUGME_NORMAL_SONRENK);

  // 1 = mevcut değer
  // 2 = kalan değer
  // 3 = toplam değer / mevcut değer
  // 4 = toplam değer / kalan değer
  // 5 = mevcut yüzdelik değer
  // 6 = kalan yüzdelik değer
  DegerGosterim := 3;

  s := '';

  // gösterge nesnesinin yüksekliğinin 14px ve üzerinde olması durumunda gösterge değerini yaz
  if(CizimAlani.Alt >= 14) then
  begin

    CizimAlani2 := CizimAlani;
    case DegerGosterim of
      1: s := IntToStr(FMevcutDeger);
      2: s := IntToStr(FUstDeger - FMevcutDeger);
      3: s := IntToStr(FUstDeger) + '/' + IntToStr(FMevcutDeger);
      4: s := IntToStr(FUstDeger) + '/' + IntToStr(FUstDeger - FMevcutDeger);
      5: s := '%' + IntToStr((FMevcutDeger * 100) div FUstDeger);
      6: s := '%' + IntToStr(((FUstDeger - FMevcutDeger) * 100) div FUstDeger);
    end;

    i := (CizimAlani2.Sag - (Length(s) * 8)) div 2;
    j := ((CizimAlani2.Alt - 16) div 2) + 1;
    YaziYaz(Self, CizimAlani2.Sol + i, CizimAlani2.Ust + j, s, RENK_LACIVERT);
  end;
end;

{==============================================================================
  işlem göstergesi nesne olaylarını işler
 ==============================================================================}
procedure TIslemGostergesi.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
begin

  // işlenecek hiçbir olay yok
end;

{==============================================================================
  işlem göstergesi en alt, en üst değerlerini belirler
 ==============================================================================}
procedure TIslemGostergesi.DegerleriBelirle(AAltDeger, AUstDeger: TISayi8);
begin

  FAltDeger := AAltDeger;
  FUstDeger := AUstDeger;
  FMevcutDeger := 0;

  Ciz;
end;

{==============================================================================
  işlem göstergesi mevcut konum değerini belirler
 ==============================================================================}
procedure TIslemGostergesi.MevcutDegerYaz(AMevcutDeger: TISayi8);
begin

  FMevcutDeger := AMevcutDeger;

  Ciz;
end;

end.
