{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_gucdugmesi.pas
  Dosya İşlevi: güç düğmesi yönetim işlevlerini içerir

  Güncelleme Tarihi: 14/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_gucdugmesi;

interface

uses gorselnesne, paylasim, gn_panel;

type
  PGucDugmesi = ^TGucDugmesi;
  TGucDugmesi = class(TPanel)
  private
    FDurum: TDugmeDurumu;
  public
    constructor Create; override;
    destructor Destroy; override;
    function Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4; ABaslik: string): TISayi4;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
    procedure CizimModelDegistir(ADolguluCizim: Boolean; AGovdeRenk1, AGovdeRenk2,
      AYaziRenkNormal, AYaziRenkBasili: TRenk);
    procedure DurumYaz(AKimlik: TKimlik; ADurum: TSayi4);
    // dolgulu çizim mi, normal çizim mi?
    property DolguluCizim: Boolean read FDurum1 write FDurum1;
    property YaziRenkNormal: TRenk read FDeger1 write FDeger1;
    property YaziRenkBasili: TRenk read FDeger2 write FDeger2;
  end;

function GucDugmeCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function GucDugmesiGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik,
  AYukseklik: TISayi4; ABaslik: string): TKimlik;

implementation

uses gn_islevler, temelgorselnesne, gn_pencere, gorev, src_ps2;

{==============================================================================
  güç düğmesi kesme çağrılarını yönetir
 ==============================================================================}
function GucDugmeCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  Pencere: TPencere;
  GucDugmesi: TGucDugmesi;
  Konum: PKonum;
  Boyut: PBoyut;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := GucDugmesiGNOlustur(GN, PISayi4(ADegiskenler + 04)^,
        PISayi4(ADegiskenler + 08)^, PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^,
        PKarakterKatari(PSayi4(ADegiskenler + 20)^ + GGorevler.FAktifGrvBelAdr)^);
    end;

    ISLEV_GOSTER:
    begin

      GucDugmesi := TGucDugmesi(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      GucDugmesi.Goster;
    end;

    ISLEV_GIZLE:
    begin

      GucDugmesi := TGucDugmesi(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      GucDugmesi.Gizle;
    end;

    // yeniden boyutlandır
    ISLEV_BOYUTLANDIR:
    begin

      GucDugmesi := TGucDugmesi(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(GucDugmesi <> nil) then
      begin

        Konum := PKonum(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr);
        Boyut := PBoyut(PSayi4(ADegiskenler + 08)^ + GGorevler.FAktifGrvBelAdr);
        GucDugmesi.FIlkAtananAlan.Sol := Konum^.Sol;
        GucDugmesi.FIlkAtananAlan.Ust := Konum^.Ust;
        GucDugmesi.FIlkAtananAlan.Genislik := Boyut^.Genislik;
        GucDugmesi.FIlkAtananAlan.Yukseklik := Boyut^.Yukseklik;

        Pencere := TPencere(GucDugmesi.AtaNesne);
        Pencere.Ciz;
      end;
    end;

    ISLEV_YOKET:
    begin

      GucDugmesi := TGucDugmesi(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      GucDugmesi.Destroy;
    end;

    $010F:
    begin

      GucDugmesi := TGucDugmesi(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      if not(GucDugmesi = nil) then
      begin

        GucDugmesi.Baslik := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr)^;
      end;
    end;

    // güç düğme durumunu değiştir
    $020F:
    begin

      GucDugmesi := TGucDugmesi(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(GucDugmesi <> nil) then
        GucDugmesi.DurumYaz(PKimlik(ADegiskenler + 00)^, PISayi4(ADegiskenler + 04)^);
    end;

    // güç düğmesi nesnesine odaklan. (klavye girişlerini almasını sağla)
    $030F:
    begin

      GucDugmesi := TGucDugmesi(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));

      if(GucDugmesi <> nil) and (GucDugmesi.NesneTipi = gntGucDugmesi) then
      begin

        // bir önceki odak alan nesneyi odaktan çıkar
        GN := TPencere(GucDugmesi.AtaNesne).FAktifNesne;
        if(GN <> nil) and (GN.Odaklanilabilir) then GN.Odaklanildi := False;

        // nelirtilen nesneyi odaklanılan nesne olarak belirle
        TPencere(GucDugmesi.AtaNesne).FAktifNesne := GucDugmesi;
        GucDugmesi.Odaklanildi := True;
      end;
    end;
  end;
end;

{==============================================================================
  uygulama için güç düğmesi nesnesi oluşturur - api
 ==============================================================================}
function GucDugmesiGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik,
  AYukseklik: TISayi4; ABaslik: string): TKimlik;
var
  GucDugmesi: TGucDugmesi;
begin

  GucDugmesi := TGucDugmesi.Create;

  if(GucDugmesi = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    GucDugmesi.Ozellestir(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik, ABaslik);

    Result := GucDugmesi.Kimlik;
  end;
end;

{==============================================================================
  güç düğmesi nesnesi oluşturur
 ==============================================================================}
constructor TGucDugmesi.Create;
begin

  inherited Create;

  NesneTipi := gntGucDugmesi;

  GGNesneler.GorselNesne[FSiraNo] := Self;
end;

{==============================================================================
  güç düğmesi nesnesini yok eder
 ==============================================================================}
destructor TGucDugmesi.Destroy;
begin

  GGNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  güç düğmesi nesnesini özelleştirir
 ==============================================================================}
function TGucDugmesi.Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4; ABaslik: string): TISayi4;
begin

  Yapilandir2(AKullanimTipi, Self, AAtaNesne, ASol, AUst, AGenislik, AYukseklik,
    4, DUGME_NORMAL_ILKRENK, DUGME_NORMAL_SONRENK, DUGME_NORMAL_YAZIRENK, ABaslik);

  OlayCagriAdr := @OlaylariIsle;

  Baslik := ABaslik;

  Odaklanilabilir := True;
  Odaklanildi := False;

  FDurum := ddNormal;

  // çizim öndeğerleri
  DolguluCizim := True;
  FGovdeRenk1 := DUGME_NORMAL_ILKRENK;
  FGovdeRenk2 := DUGME_NORMAL_SONRENK;
  YaziRenkNormal := DUGME_NORMAL_YAZIRENK;
  YaziRenkBasili := DUGME_BASILI_YAZIRENK;

  // geri dönüş değeri
  Result := HATA_YOK;
end;

{==============================================================================
  güç düğmesi nesnesini görüntüler
 ==============================================================================}
procedure TGucDugmesi.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  güç düğmesi nesnesini gizler
 ==============================================================================}
procedure TGucDugmesi.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  güç düğmesi nesnesini hizalandırır
 ==============================================================================}
procedure TGucDugmesi.Hizala;
begin

  inherited Hizala;
end;

{==============================================================================
  güç düğmesi nesnesini çizer
 ==============================================================================}
procedure TGucDugmesi.Ciz;
var
  CizimAlani: TAlan;
begin

  // düğme başlığı
  if(FDurum = ddNormal) then
    FYaziRenk := YaziRenkNormal
  else FYaziRenk := YaziRenkBasili;

  inherited Ciz;

  // nesne odaklanılmış ise nesnenin kenarlarını işaretle
  if(Odaklanildi) then
  begin

    CizimAlani := FCizimAlani;
    Dikdortgen(Self, ctNokta, CizimAlani, RENK_SIYAH);
  end;
end;

{==============================================================================
  güç düğmesi nesne olaylarını işler
 ==============================================================================}
procedure TGucDugmesi.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Pencere: TPencere;
  GucDugmesi: TGucDugmesi;
  i: TISayi4;
begin

  GucDugmesi := TGucDugmesi(AGonderici);

  // farenin sol tuşuna basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // güç düğmesinin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := GGNesneler.EnUstPencereNesnesiniAl(GucDugmesi);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere.FAktifNesne := GucDugmesi;
    GucDugmesi.Odaklanildi := True;

    // fare olaylarını yakala
    GGNesneler.OlayYakalamayaBasla(GucDugmesi);

    // güç düğmesinin durumunu NORMAL / BASILI olarak değiştir
    if(GucDugmesi.FDurum = ddBasili) then
    begin

      i := 0;
      GucDugmesi.FDurum := ddNormal;
    end
    else
    begin

      i := 1;
      GucDugmesi.FDurum := ddBasili;
    end;

    // güç düğmesi nesnesini yeniden çiz
    GucDugmesi.Ciz;

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := CO_DURUMDEGISTI;
    AOlay.Deger1 := i;
    if not(GucDugmesi.OlayYonlAdr = nil) then
      GucDugmesi.OlayYonlAdr(GucDugmesi, AOlay)
    else GGorevler.OlayEkle(GucDugmesi.GrvKimlik, AOlay);
  end
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    GGNesneler.OlayYakalamayiBirak(GucDugmesi);
  end;

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := GucDugmesi.FareImlec;
end;

{==============================================================================
  güç düğmesinin çizim modelini değiştirir ve renk değerlerini belirler
 ==============================================================================}
procedure TGucDugmesi.CizimModelDegistir(ADolguluCizim: Boolean; AGovdeRenk1, AGovdeRenk2,
  AYaziRenkNormal, AYaziRenkBasili: TRenk);
begin

  DolguluCizim := ADolguluCizim;
  if(ADolguluCizim) then
    FCizimModel := 4
  else FCizimModel := 3;

  FGovdeRenk1 := AGovdeRenk1;
  FGovdeRenk2 := AGovdeRenk2;
  YaziRenkNormal := AYaziRenkNormal;
  YaziRenkBasili := AYaziRenkBasili;
end;

{==============================================================================
  güç düğmesi nesnesinin durumunu değiştirir
 ==============================================================================}
procedure TGucDugmesi.DurumYaz(AKimlik: TKimlik; ADurum: TSayi4);
begin

  if(ADurum = 1) then
    FDurum := ddBasili
  else FDurum := ddNormal;

  Ciz;
end;

end.
