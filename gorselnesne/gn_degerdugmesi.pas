{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_degerdugmesi.pas
  Dosya İşlevi: artırma / eksiltme (TUpDown) düğme yönetim işlevlerini içerir

  Güncelleme Tarihi: 12/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_degerdugmesi;

interface

uses gorev, gorselnesne, paylasim, gn_resimdugmesi, gn_panel;

type
  PDegerDugmesi = ^TDegerDugmesi;
  TDegerDugmesi = class(TPanel)
  private
    FArtirmaDugmesi,
    FEksiltmeDugmesi: TResimDugmesi;
    procedure ResimDugmeOlaylariniIsle(AGonderici: TGorselNesne; AOlay: TOlay);
  public
    constructor Create; override;
    destructor Destroy; override;
    function Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4): TISayi4;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
  end;

function DegerDugmesiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function DegerDugmesiGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;

implementation

uses temelgorselnesne, gn_islevler, src_ps2;

{==============================================================================
  artırma / eksiltme düğme kesme çağrılarını yönetir
 ==============================================================================}
function DegerDugmesiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  DegerDugmesi: TDegerDugmesi;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := DegerDugmesiGNOlustur(GN, PISayi4(ADegiskenler + 04)^,
        PISayi4(ADegiskenler + 08)^, PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^);
    end;

    ISLEV_GOSTER:
    begin

      DegerDugmesi := TDegerDugmesi(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      DegerDugmesi.Goster;
    end;
  end;
end;

{==============================================================================
  uygulama için artırma / eksiltme düğme nesnesi oluşturur - api
 ==============================================================================}
function DegerDugmesiGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
var
  DegerDugmesi: TDegerDugmesi;
begin

  DegerDugmesi := TDegerDugmesi.Create;

  if(DegerDugmesi = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    DegerDugmesi.Ozellestir(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik);

    Result := DegerDugmesi.Kimlik;
  end;
end;

{==============================================================================
  artırma / eksiltme düğme nesnesi oluşturur
 ==============================================================================}
constructor TDegerDugmesi.Create;
begin

  inherited Create;

  NesneTipi := gntDegerDugmesi;

  GGNesneler.GorselNesne[FSiraNo] := Self;
end;

{==============================================================================
  artırma / eksiltme düğme nesnesini yok eder
 ==============================================================================}
destructor TDegerDugmesi.Destroy;
begin

  FArtirmaDugmesi.Destroy;
  FEksiltmeDugmesi.Destroy;

  GGNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  artırma / eksiltme düğme nesnesini özelleştirir
 ==============================================================================}
function TDegerDugmesi.Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4): TISayi4;
begin

  Yapilandir2(AKullanimTipi, Self, AAtaNesne, ASol, AUst, 18, 21, 0, 0, 0, 0, '');

  OlayCagriAdr := @OlaylariIsle;

  // $10000000 + 1 = yukarı ok resmi
  FArtirmaDugmesi := TResimDugmesi.Create;
  FArtirmaDugmesi.Ozellestir(ktBilesen, Self, 0, 0, 18, 10, $10000000 + 1, True);
  FArtirmaDugmesi.OlayYonlAdr := @ResimDugmeOlaylariniIsle;

  // $10000000 + 2 = aşağı ok resmi
  FEksiltmeDugmesi := TResimDugmesi.Create;
  FEksiltmeDugmesi.Ozellestir(ktBilesen, Self, 0, 11, 18, 10, $10000000 + 2, True);
  FEksiltmeDugmesi.OlayYonlAdr := @ResimDugmeOlaylariniIsle;

  // geri dönüş değeri
  Result := HATA_YOK;
end;

{==============================================================================
  artırma / eksiltme düğme nesnesini görüntüler
 ==============================================================================}
procedure TDegerDugmesi.Goster;
begin

  FArtirmaDugmesi.Goster;
  FEksiltmeDugmesi.Goster;

  inherited Goster;
end;

{==============================================================================
  artırma / eksiltme düğme nesnesini gizler
 ==============================================================================}
procedure TDegerDugmesi.Gizle;
begin

  FArtirmaDugmesi.Gizle;
  FEksiltmeDugmesi.Gizle;

  inherited Gizle;
end;

{==============================================================================
  artırma / eksiltme düğme nesnesini hizalandırır
 ==============================================================================}
procedure TDegerDugmesi.Hizala;
begin

  inherited Hizala;
end;

{==============================================================================
  artırma / eksiltme düğme nesnesini çizer
 ==============================================================================}
procedure TDegerDugmesi.Ciz;
begin

  inherited Ciz;

  FEksiltmeDugmesi.Ciz;
  FArtirmaDugmesi.Ciz;
end;

{==============================================================================
  artırma / eksiltme düğme nesne olaylarını işler
 ==============================================================================}
procedure TDegerDugmesi.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  DegerDugmesi: TDegerDugmesi;
begin

  DegerDugmesi := TDegerDugmesi(AGonderici);
  if(DegerDugmesi = nil) then Exit;

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := DegerDugmesi.FareImlec;
end;

{==============================================================================
  artırma / eksiltme düğmesinin sahip olduğu resim düğmesi olaylarını işler
 ==============================================================================}
procedure TDegerDugmesi.ResimDugmeOlaylariniIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  DegerDugmesi: TDegerDugmesi;
  ResimDugmesi: TResimDugmesi;
begin

  ResimDugmesi := TResimDugmesi(AGonderici);
  if(ResimDugmesi = nil) then Exit;

  DegerDugmesi := TDegerDugmesi(ResimDugmesi.AtaNesne);

  if(AOlay.Olay = FO_TIKLAMA) then
  begin

    if(AOlay.Kimlik = DegerDugmesi.FArtirmaDugmesi.Kimlik) then
    begin

      // nesnenin olay çağrı adresini çağır veya uygulamaya mesaj gönder
      AOlay.Kimlik := DegerDugmesi.Kimlik;
      AOlay.Deger1 := 0;
      if not(DegerDugmesi.OlayYonlAdr = nil) then
        DegerDugmesi.OlayYonlAdr(DegerDugmesi, AOlay)
      else GGorevler.OlayEkle(DegerDugmesi.GrvKimlik, AOlay);
    end
    else if(AOlay.Kimlik = DegerDugmesi.FEksiltmeDugmesi.Kimlik) then
    begin

      // nesnenin olay çağrı adresini çağır veya uygulamaya mesaj gönder
      AOlay.Kimlik := DegerDugmesi.Kimlik;
      AOlay.Deger1 := 1;
      if not(DegerDugmesi.OlayYonlAdr = nil) then
        DegerDugmesi.OlayYonlAdr(DegerDugmesi, AOlay)
      else GGorevler.OlayEkle(DegerDugmesi.GrvKimlik, AOlay);
    end;
  end;
end;

end.
