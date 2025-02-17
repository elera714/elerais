{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_islemgostergesi.pas
  Dosya İşlevi: işlem göstergesi (TProgressBar) yönetim işlevlerini içerir

  Güncelleme Tarihi: 30/12/2024

 ==============================================================================}
{$mode objfpc}
unit gn_islemgostergesi;

interface

uses gorselnesne, paylasim, gn_panel;

type
  PIslemGostergesi = ^TIslemGostergesi;
  TIslemGostergesi = object(TPanel)
  public
    FAltDeger, FUstDeger, FMevcutDeger: TISayi4;
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4): PIslemGostergesi;
    procedure YokEt;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    procedure DegerleriBelirle(AAltDeger, AUstDeger: TISayi4);
    procedure MevcutDegerYaz(AMevcutDeger: TISayi4);
  end;

function IslemGostergesiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;

implementation

uses temelgorselnesne, giysi_mac;

{==============================================================================
  işlem göstergesi kesme çağrılarını yönetir
 ==============================================================================}
function IslemGostergesiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GorselNesne: PGorselNesne;
  IslemGostergesi: PIslemGostergesi;
begin

  // $DDCCBBAA
  //      BBAA  -> kesme tarafından değerlendirildi
  // DDCC       -> AIslevNo değeri
  case AIslevNo of

    // nesneyi oluştur
    ISLEV_OLUSTUR:
    begin

      GorselNesne := GorselNesne^.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GorselNesne, PISayi4(ADegiskenler + 04)^,
        PISayi4(ADegiskenler + 08)^, PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^);
    end;

    ISLEV_GOSTER:
    begin

      IslemGostergesi := PIslemGostergesi(IslemGostergesi^.NesneAl(PKimlik(ADegiskenler + 00)^));
      IslemGostergesi^.Goster;
    end;

    // alt, üst değerlerini belirle
    $010F:
    begin

      IslemGostergesi := PIslemGostergesi(IslemGostergesi^.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntIslemGostergesi));
      if(IslemGostergesi <> nil) then IslemGostergesi^.DegerleriBelirle(
        PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^);
    end;

    // nesne gösterge pozisyonunu belirle
    $020F:
    begin

      IslemGostergesi := PIslemGostergesi(IslemGostergesi^.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntIslemGostergesi));
      if(IslemGostergesi <> nil) then IslemGostergesi^.MevcutDegerYaz(PISayi4(ADegiskenler + 04)^);
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  işlem göstergesi nesnesini oluşturur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
var
  IslemGostergesi: PIslemGostergesi;
begin

  IslemGostergesi := IslemGostergesi^.Olustur(ktNesne, AAtaNesne, ASol, AUst,
    AGenislik, AYukseklik);

  if(IslemGostergesi = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := IslemGostergesi^.Kimlik;
end;

{==============================================================================
  işlem göstergesi nesnesini oluşturur
 ==============================================================================}
function TIslemGostergesi.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4): PIslemGostergesi;
var
  IslemGostergesi: PIslemGostergesi;
begin

  IslemGostergesi := PIslemGostergesi(inherited Olustur(AKullanimTipi, AAtaNesne,
    ASol, AUst, AGenislik, AYukseklik, 0, 0, 0, 0, ''));

  // görsel nesne tipi
  IslemGostergesi^.NesneTipi := gntIslemGostergesi;

  IslemGostergesi^.Baslik := '';

  IslemGostergesi^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  IslemGostergesi^.OlayCagriAdresi := @OlaylariIsle;

  // diğer değer atamaları
  IslemGostergesi^.FAltDeger := 1;
  IslemGostergesi^.FUstDeger := 100;
  IslemGostergesi^.FMevcutDeger := 0;

  // nesne adresini geri döndür
  Result := IslemGostergesi;
end;

{==============================================================================
  işlem göstergesi nesnesini yok eder
 ==============================================================================}
procedure TIslemGostergesi.YokEt;
begin

  inherited YokEt;
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
  IslemGostergesi: PIslemGostergesi;
begin

  IslemGostergesi := PIslemGostergesi(IslemGostergesi^.NesneAl(Kimlik));
  if(IslemGostergesi = nil) then Exit;

  inherited Hizala;
end;

{==============================================================================
  işlem göstergesi nesnesini çizer
 ==============================================================================}
procedure TIslemGostergesi.Ciz;
var
  IslemGostergesi: PIslemGostergesi;
  Alan: TAlan;
  i1, i2, Aralik, Deger: TISayi4;
begin

  IslemGostergesi := PIslemGostergesi(IslemGostergesi^.NesneAl(Kimlik));
  if(IslemGostergesi = nil) then Exit;

  // giriş kutusunun çizim alan koordinatlarını al
  Alan := IslemGostergesi^.FCizimAlan;

  i1 := (FUstDeger - FAltDeger) + 1;
  i2 := Alan.Sag;
  if(i1 > i2) then
  begin

    Aralik := i1 div i2;
    Deger := FMevcutDeger div Aralik;
  end
  else
  begin

    Aralik := i2 div i1;
    Deger := FMevcutDeger * Aralik;
  end;

  // ön renk doldurma işlemi. dolgu öncesi çizim
  IslemGostergesi^.DikdortgenDoldur(IslemGostergesi, Alan.Sol, Alan.Ust,
    Alan.Sag, Alan.Alt, $F1F1F1, RENK_BEYAZ);

  // artan renk ile (eğimli) doldur
  Alan.Sag := Alan.Sol + Deger;
  IslemGostergesi^.EgimliDoldur(IslemGostergesi, Alan, DUGME_NORMAL_ILKRENK,
    DUGME_NORMAL_SONRENK);
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
procedure TIslemGostergesi.DegerleriBelirle(AAltDeger, AUstDeger: TISayi4);
begin

  FAltDeger := AAltDeger;
  FUstDeger := AUstDeger;

  Ciz;
end;

{==============================================================================
  işlem göstergesi mevcut konum değerini belirler
 ==============================================================================}
procedure TIslemGostergesi.MevcutDegerYaz(AMevcutDeger: TISayi4);
begin

  FMevcutDeger := AMevcutDeger;

  Ciz;
end;

end.
