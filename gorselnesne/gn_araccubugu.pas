{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_araccubugu.pas
  Dosya İşlevi: araç çubuğu (TToolBar) nesne yönetim işlevlerini içerir

  Güncelleme Tarihi: 14/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_araccubugu;

interface

uses gorev, gorselnesne, paylasim, gn_panel, gn_resimdugmesi;

const
  AZAMI_DUGME_SAYISI = 50;

type
  PAracCubugu = ^TAracCubugu;
  TAracCubugu = class(TPanel)
  private
    // araç çubuğunda yer alacak düğme listesi
    FDugmeSayisi: TSayi4;
    FDugmeler: array[0..AZAMI_DUGME_SAYISI - 1] of TResimDugmesi;
  public
    constructor Create; override;
    destructor Destroy; override;
    function Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne): TISayi4;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
    procedure ResimDugmeOlaylariniIsle(AGonderici: TGorselNesne; AOlay: TOlay);
    function DugmeEkle(AResimSiraNo: TSayi4): TKimlik;
    function DugmeEkle2(AResimSiraNo: TSayi4): TKimlik;
  end;

function AracCubuguCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function AracCubuguGNOlustur(AAtaNesne: TGorselNesne): TKimlik;

implementation

uses gn_islevler, src_ps2;

{==============================================================================
  araç çubuğu nesne kesme çağrılarını yönetir
 ==============================================================================}
function AracCubuguCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  AracCubugu: TAracCubugu;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := AracCubuguGNOlustur(GN);
    end;

    ISLEV_GOSTER:
    begin

      AracCubugu := TAracCubugu(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      AracCubugu.Goster;
    end;

    // araç çubuğuna düğme ekle
    $010F:
    begin

      AracCubugu := TAracCubugu(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      if not(AracCubugu = nil) then
        Result := AracCubugu.DugmeEkle(PISayi4(ADegiskenler + 04)^);
    end;
  end;
end;

{==============================================================================
  uygulama için araç çubuğu nesnesi oluşturur - api
 ==============================================================================}
function AracCubuguGNOlustur(AAtaNesne: TGorselNesne): TKimlik;
var
  AracCubugu: TAracCubugu;
begin

  AracCubugu := TAracCubugu.Create;

  if(AracCubugu = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    AracCubugu.Ozellestir(ktNesne, AAtaNesne);

    Result := AracCubugu.Kimlik;
  end;
end;

{==============================================================================
  araç çubuğu nesnesi oluşturur
 ==============================================================================}
constructor TAracCubugu.Create;
begin

  inherited Create;

  NesneTipi := gntAracCubugu;

  GGNesneler.GorselNesne[FSiraNo] := Self;
end;

{==============================================================================
  araç çubuğu nesnesini yok eder
 ==============================================================================}
destructor TAracCubugu.Destroy;
var
  i: TSayi4;
begin

  for i := 0 to AZAMI_DUGME_SAYISI - 1 do
  begin

    if not(FDugmeler[i] = nil) then FDugmeler[i].Destroy;
  end;

  GGNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  araç çubuğu nesnesini özelleştirir
 ==============================================================================}
function TAracCubugu.Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne): TISayi4;
var
  i: TSayi4;
begin

  Yapilandir2(AKullanimTipi, Self, AAtaNesne, 0, 0, 10, 28,
    2, RENK_GUMUS, RENK_BEYAZ, 0, '');

  OlayCagriAdr := @OlaylariIsle;

  FHiza := hzUst;

  // düğme değerlerinin ilk değerlerle yüklenmesi
  FDugmeSayisi := 0;

  for i := 0 to AZAMI_DUGME_SAYISI - 1 do FDugmeler[i] := nil;

  // geri dönüş değeri
  Result := HATA_YOK;
end;

{==============================================================================
  araç çubuğu nesnesini görüntüler
 ==============================================================================}
procedure TAracCubugu.Goster;
var
  i: TSayi4;
begin

  if(FDugmeSayisi > 0) then
  begin

    for i := 0 to FDugmeSayisi - 1 do
    begin

      if not(FDugmeler[i] = nil) then FDugmeler[i].Goster;
    end;
  end;

  inherited Goster;
end;

{==============================================================================
  araç çubuğu nesnesini gizler
 ==============================================================================}
procedure TAracCubugu.Gizle;
var
  i: TSayi4;
begin

  if(FDugmeSayisi > 0) then
  begin

    for i := 0 to FDugmeSayisi - 1 do
    begin

      if not(FDugmeler[i] = nil) then FDugmeler[i].Gizle;
    end;
  end;

  inherited Gizle;
end;

{==============================================================================
  araç çubuğu nesnesini hizalandırır
 ==============================================================================}
procedure TAracCubugu.Hizala;
begin

  inherited Hizala;
end;

{==============================================================================
  araç çubuğu nesnesini çizer
 ==============================================================================}
procedure TAracCubugu.Ciz;
var
  i: TSayi4;
begin

  // öncelikle kendini çiz
  inherited Ciz;

  // daha sonra alt nesne düğmeleri
  if(FDugmeSayisi > 0) then
  begin

    for i := 0 to FDugmeSayisi - 1 do
    begin

      if not(FDugmeler[i] = nil) then FDugmeler[i].Ciz;
    end;
  end;
end;

{==============================================================================
  araç çubuğu nesne olaylarını işler
 ==============================================================================}
procedure TAracCubugu.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  AracCubugu: TAracCubugu;
begin

  AracCubugu := TAracCubugu(AGonderici);

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := AracCubugu.FareImlec;
end;

{==============================================================================
  araç çubuğundaki mevcut resim düğmesi nesne olaylarını işler
 ==============================================================================}
procedure TAracCubugu.ResimDugmeOlaylariniIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  AracCubugu: TAracCubugu;
  ResimDugmesi: TResimDugmesi;
begin

  ResimDugmesi := TResimDugmesi(AGonderici);
  if(ResimDugmesi = nil) then Exit;

  AracCubugu := TAracCubugu(ResimDugmesi.AtaNesne);

  if(AOlay.Olay = FO_TIKLAMA) then
  begin

    AOlay.Kimlik := ResimDugmesi.Kimlik;

    if not(AracCubugu.OlayYonlAdr = nil) then
      AracCubugu.OlayYonlAdr(ResimDugmesi, AOlay)
    else GGorevler.OlayEkle(ResimDugmesi.GrvKimlik, AOlay);
  end;
end;


{==============================================================================
  araç çubuğu nesnesine resim düğmesi ekler - programlar için
 ==============================================================================}
function TAracCubugu.DugmeEkle(AResimSiraNo: TSayi4): TKimlik;
var
  ResimDugmesi: TResimDugmesi;
begin

  if(FDugmeSayisi >= AZAMI_DUGME_SAYISI) then Exit(-1);

  ResimDugmesi := TResimDugmesi.Create;
  ResimDugmesi.Ozellestir(ktBilesen, Self, (FDugmeSayisi * 30) + 4, 1, 24, 24,
    $10000000 + AResimSiraNo, False);
  ResimDugmesi.OlayYonlAdr := @ResimDugmeOlaylariniIsle;
  ResimDugmesi.Gorunum := True;

  FDugmeler[FDugmeSayisi] := ResimDugmesi;

  Inc(FDugmeSayisi);

  Result := ResimDugmesi.Kimlik;
end;

{==============================================================================
  araç çubuğu nesnesine resim düğmesi ekler - çekirdek grafiksel programlama çalışması için
 ==============================================================================}
function TAracCubugu.DugmeEkle2(AResimSiraNo: TSayi4): TKimlik;
var
  ResimDugmesi: TResimDugmesi;
begin

  if(FDugmeSayisi >= AZAMI_DUGME_SAYISI) then Exit(-1);

  ResimDugmesi := TResimDugmesi.Create;
  ResimDugmesi.Ozellestir(ktNesne, Self, (FDugmeSayisi * 30) + 4, 1, 24, 24,
    $30000000 + AResimSiraNo, False);
  ResimDugmesi.OlayYonlAdr := @ResimDugmeOlaylariniIsle;
  ResimDugmesi.Gorunum := True;

  FDugmeler[FDugmeSayisi] := ResimDugmesi;

  Inc(FDugmeSayisi);

  Result := ResimDugmesi.Kimlik;
end;

end.
