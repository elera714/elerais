{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_durumcubugu.pas
  Dosya İşlevi: durum çubuğu (TStatusBar) yönetim işlevlerini içerir

  Güncelleme Tarihi: 11/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_durumcubugu;

interface

uses gorselnesne, paylasim, gn_panel;

type
  PDurumCubugu = ^TDurumCubugu;
  TDurumCubugu = class(TPanel)
  public
    constructor Create; override;
    destructor Destroy; override;
    function Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4; ADurumYazi: string): TISayi4;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
  end;

function DurumCubuguCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function DurumCubuguGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ADurumYazi: string): TKimlik;

implementation

uses genel, gn_pencere, gn_islevler, temelgorselnesne, hamresim, gorev;

{==============================================================================
  durum çubuğu kesme çağrılarını yönetir
 ==============================================================================}
function DurumCubuguCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  DurumCubugu: TDurumCubugu;
  p1: PKarakterKatari;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GGorselNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := DurumCubuguGNOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^,
        PKarakterKatari(PSayi4(ADegiskenler + 20)^ + FAktifGorevBellekAdresi)^);
    end;

    ISLEV_GOSTER:
    begin

      DurumCubugu := TDurumCubugu(GGorselNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      DurumCubugu.Goster;
    end;

    // durum çubuğundaki veriyi değiştir
    $010F:
    begin

      DurumCubugu := TDurumCubugu(GGorselNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      p1 := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
      DurumCubugu.Baslik := p1^;
      DurumCubugu.Ciz;
    end;
  end;
end;

{==============================================================================
  uygulama için durum çubuğu nesnesi oluşturur - api
 ==============================================================================}
function DurumCubuguGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ADurumYazi: string): TKimlik;
var
  DurumCubugu: TDurumCubugu;
begin

  DurumCubugu := TDurumCubugu.Create;

  if(DurumCubugu = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    DurumCubugu.Ozellestir(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik, ADurumYazi);

    Result := DurumCubugu.Kimlik;
  end;
end;

{==============================================================================
  durum çubuğu nesnesi oluşturur
 ==============================================================================}
constructor TDurumCubugu.Create;
begin

  inherited Create;

  NesneTipi := gntDurumCubugu;

  GGorselNesneler.GorselNesne[FSiraNo] := Self;
end;

{==============================================================================
  durum çubuğu nesnesini yok eder
 ==============================================================================}
destructor TDurumCubugu.Destroy;
begin

  GGorselNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  durum çubuğu nesnesini özelleştirir
 ==============================================================================}
function TDurumCubugu.Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4; ADurumYazi: string): TISayi4;
begin

  // nesne yüksekliği 20px olarak sabitlendi
  AYukseklik := 20;

  Yapilandir2(AKullanimTipi, Self, AAtaNesne, ASol, AUst, AGenislik, AYukseklik,
    2, $D4D0C8, $D4D0C8, 0, '');

  OlayCagriAdresi := @OlaylariIsle;

  Baslik := ADurumYazi;

  Odaklanilabilir := False;
  Odaklanildi := False;

  FHiza := hzAlt;                        // alta hizala

  // geri dönüş değeri
  Result := HATA_YOK;
end;

{==============================================================================
  durum çubuğu nesnesini görüntüler
 ==============================================================================}
procedure TDurumCubugu.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  durum çubuğu nesnesini gizler
 ==============================================================================}
procedure TDurumCubugu.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  durum çubuğu nesnesini hizalandırır
 ==============================================================================}
procedure TDurumCubugu.Hizala;
begin

  inherited Hizala;
end;

{==============================================================================
  durum çubuğu nesnesini çizer
 ==============================================================================}
procedure TDurumCubugu.Ciz;
var
  CizimAlani: TAlan;
  Renk: PRenk;
  Sol, Ust, Yatay,
  Dikey: TISayi4;
begin

  inherited Ciz;

  // durum çubuğunun çizim alan koordinatlarını al
  CizimAlani := FCizimAlani;

  Yatay := CizimAlani.Sag - 12 - 1;
  Dikey := CizimAlani.Alt - 12 - 1;

  Renk := PRenk(@DurumCubuguResim);
  for Ust := 1 to 12 do
  begin

    for Sol := 1 to 12 do
    begin

      if not(Renk^ = $FFFFFFFF) then
        PixelYaz(Self, Yatay + Sol, Dikey + Ust, Renk^);
      Inc(Renk);
    end;
  end;

  // durum çubuğu başlığı
  YaziYaz(Self, CizimAlani.Sol + 3, CizimAlani.Ust + 2, Baslik, RENK_SIYAH);
end;

{==============================================================================
  durum çubuğu olaylarını işler
 ==============================================================================}
procedure TDurumCubugu.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Pencere: TPencere;
  DurumCubugu: TDurumCubugu;
begin

  DurumCubugu := TDurumCubugu(AGonderici);

  // farenin sol tuşuna basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // durum çubuğunun sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(DurumCubugu);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere.EnUsteGetir(Pencere);

    if(FareNesneOlayAlanindaMi(DurumCubugu)) then
    begin

      // fare olaylarını yakala
      OlayYakalamayaBasla(DurumCubugu);
    end;
  end
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // farenin tuş bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(DurumCubugu.FareNesneOlayAlanindaMi(DurumCubugu)) then
    begin

      // uygulamaya veya efendi nesneye mesaj gönder
      AOlay.Olay := FO_TIKLAMA;
      if not(DurumCubugu.OlayYonlendirmeAdresi = nil) then
        DurumCubugu.OlayYonlendirmeAdresi(DurumCubugu, AOlay)
      else GGorevler.OlayEkle(DurumCubugu.GorevKimlik, AOlay);
    end;

    // fare olaylarını almayı bırak
    OlayYakalamayiBirak(DurumCubugu);
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := DurumCubugu.FareImlecTipi;
end;

end.
