{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_islemgostergesi.pas
  Dosya İşlevi: işlem göstergesi (TProgressBar) yönetim işlevlerini içerir

  Güncelleme Tarihi: 10/07/2026

 ==============================================================================}
{$mode objfpc}
unit gn_islemgostergesi;

interface

uses gorselnesne, paylasim, gn_panel;

type
  PIslemGostergesi = ^TIslemGostergesi;
  TIslemGostergesi = object(TPanel)
  public
    FAltDeger, FUstDeger, FMevcutDeger: TISayi8;
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4): PIslemGostergesi;
    procedure YokEt(AKimlik: TKimlik);
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    procedure DegerleriBelirle(AAltDeger, AUstDeger: TISayi8);
    procedure MevcutDegerYaz(AMevcutDeger: TISayi8);
  end;

function IslemGostergesiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;

implementation

uses temelgorselnesne, donusum, giysi_mac;

{==============================================================================
  işlem göstergesi kesme çağrılarını yönetir
 ==============================================================================}
function IslemGostergesiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne;
  IG: PIslemGostergesi;
begin

  // $DDCCBBAA
  //      BBAA  -> kesme tarafından değerlendirildi
  // DDCC       -> AIslevNo değeri
  case AIslevNo of

    // nesneyi oluştur
    ISLEV_OLUSTUR:
    begin

      GN := GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^);
    end;

    ISLEV_GOSTER:
    begin

      IG := PIslemGostergesi(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      IG^.Goster;
    end;

    // alt, üst değerlerini belirle
    $010F:
    begin

      IG := PIslemGostergesi(GorselNesneler0.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^,
        gntIslemGostergesi));
      if(IG <> nil) then IG^.DegerleriBelirle(PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^);
    end;

    // nesne gösterge pozisyonunu belirle
    $020F:
    begin

      IG := PIslemGostergesi(GorselNesneler0.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^,
        gntIslemGostergesi));
      if(IG <> nil) then IG^.MevcutDegerYaz(PISayi4(ADegiskenler + 04)^);
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  işlem göstergesi nesnesini oluşturur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
var
  IG: PIslemGostergesi;
begin

  IG := IG^.Olustur(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik);

  if(IG = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := IG^.Kimlik;
end;

{==============================================================================
  işlem göstergesi nesnesini oluşturur
 ==============================================================================}
function TIslemGostergesi.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4): PIslemGostergesi;
var
  IG: PIslemGostergesi;
begin

  IG := PIslemGostergesi(inherited Olustur(AKullanimTipi, AAtaNesne, ASol, AUst,
    AGenislik, AYukseklik, 0, 0, 0, 0, ''));

  // görsel nesne tipi
  IG^.NesneTipi := gntIslemGostergesi;

  IG^.Baslik := '';

  IG^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  IG^.OlayCagriAdresi := @OlaylariIsle;

  // diğer değer atamaları
  IG^.FAltDeger := 1;
  IG^.FUstDeger := 100;
  IG^.FMevcutDeger := 0;

  // nesne adresini geri döndür
  Result := IG;
end;

{==============================================================================
  işlem göstergesi nesnesini yok eder
 ==============================================================================}
procedure TIslemGostergesi.YokEt(AKimlik: TKimlik);
begin

  inherited YokEt(AKimlik);
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
var
  IG: PIslemGostergesi;
begin

  IG := PIslemGostergesi(GorselNesneler0.NesneAl(Kimlik));
  if(IG = nil) then Exit;

  inherited Hizala;
end;

{==============================================================================
  işlem göstergesi nesnesini çizer
 ==============================================================================}
procedure TIslemGostergesi.Ciz;
var
  IG: PIslemGostergesi;
  CizimAlani, CizimAlani2: TAlan;
  i1: TISayi8;
  s: string;
  i, j: TISayi4;
  d1, d2: Double;
begin

  IG := PIslemGostergesi(GorselNesneler0.NesneAl(Kimlik));
  if(IG = nil) then Exit;

  // giriş kutusunun çizim alan koordinatlarını al
  CizimAlani := IG^.FCizimAlani;

  i1 := (IG^.FUstDeger - IG^.FAltDeger) + 1;
  d1 := (IG^.FMevcutDeger * 100) div i1;
  d2 := (CizimAlani.Sag / 100);
  d2 := d1 * d2;

  // ön renk doldurma işlemi. dolgu öncesi çizim
  IG^.DikdortgenDoldur(IG, CizimAlani.Sol, CizimAlani.Ust, CizimAlani.Sag, CizimAlani.Alt,
    $F1F1F1, RENK_BEYAZ);

  // artan renk ile (eğimli) doldur
  CizimAlani2 := CizimAlani;
  CizimAlani2.Sag := CizimAlani2.Sol + Round(d2);
  IG^.EgimliDoldur(IG, CizimAlani2, DUGME_NORMAL_ILKRENK, DUGME_NORMAL_SONRENK);

  // gösterge nesnesinin yüksekliğinin 14px ve üzerinde olması durumunda gösterge değerini yaz
  if(CizimAlani.Alt >= 14) then
  begin

    CizimAlani2 := CizimAlani;
    s := IntToStr(IG^.FMevcutDeger);
    i := (CizimAlani2.Sag - (Length(s) * 8)) div 2;
    j := ((CizimAlani2.Alt - 16) div 2) + 1;
    IG^.YaziYaz(IG, CizimAlani2.Sol + i, CizimAlani2.Ust + j, s, RENK_LACIVERT);
  end;
end;

{==============================================================================
  işlem göstergesi olaylarını işler
 ==============================================================================}
procedure TIslemGostergesi.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
begin

  // işlenecek hiçbir olay yok
end;

{==============================================================================
  işlem göstergesi en alt, en üst değerlerini belirler
 ==============================================================================}
procedure TIslemGostergesi.DegerleriBelirle(AAltDeger, AUstDeger: TISayi8);
var
  IG: PIslemGostergesi;
begin

  IG := PIslemGostergesi(GorselNesneler0.NesneAl(Kimlik));

  IG^.FAltDeger := AAltDeger;
  IG^.FUstDeger := AUstDeger;
  IG^.FMevcutDeger := 0;

  Ciz;
end;

{==============================================================================
  işlem göstergesi mevcut konum değerini belirler
 ==============================================================================}
procedure TIslemGostergesi.MevcutDegerYaz(AMevcutDeger: TISayi8);
var
  IG: PIslemGostergesi;
begin

  IG := PIslemGostergesi(GorselNesneler0.NesneAl(Kimlik));

  IG^.FMevcutDeger := AMevcutDeger;

  Ciz;
end;

end.
