{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_secimdugmesi.pas
  Dosya İşlevi: seçim düğmesi (TRadioButton) yönetim işlevlerini içerir

  Güncelleme Tarihi: 15/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_secimdugmesi;

interface

uses gorselnesne, paylasim, gn_panel;

const
  SecimDugmeNormal: array[1..12, 1..12] of TSayi1 = (
    (0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0),
    (0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0),
    (0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0),
    (0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0),
    (1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1),
    (1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1),
    (1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1),
    (1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1),
    (0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0),
    (0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0),
    (0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0),
    (0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0));

  SecimDugmeSecili: array[1..12, 1..12] of TSayi1 = (
    (0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0),
    (0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0),
    (0, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 0),
    (0, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 0),
    (1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1),
    (1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1),
    (1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1),
    (1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1),
    (0, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 0),
    (0, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 0),
    (0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0),
    (0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0));

type
  PSecimDugmesi = ^TSecimDugmesi;
  TSecimDugmesi = class(TPanel)
  private
    FSecimDurumu: TSecimDurumu;
  public
    constructor Create; override;
    destructor Destroy; override;
    function Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
      ASol, AUst: TISayi4; ABaslik: string): TISayi4;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
  end;

function SecimDugmeCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function SecimDugmesiGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst: TISayi4; ABaslik: string): TKimlik;

implementation

uses gn_pencere, gn_islevler, gorev, src_ps2;

{==============================================================================
  seçim düğmesi çağrılarını yönetir
 ==============================================================================}
function SecimDugmeCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  Pencere: TPencere;
  SecimDugmesi: TSecimDugmesi;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := SecimDugmesiGNOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PKarakterKatari(PSayi4(ADegiskenler + 12)^ + GGorevler.FAktifGrvBelAdr)^);
    end;

    ISLEV_GOSTER:
    begin

      SecimDugmesi := TSecimDugmesi(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      SecimDugmesi.Goster;
    end;

    $010F:
    begin

      SecimDugmesi := TSecimDugmesi(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      SecimDugmesi.FSecimDurumu := PSecimDurumu(ADegiskenler + 04)^;

      Pencere := TPencere(SecimDugmesi.AtaNesne);
      if not(Pencere = nil) then Pencere.Guncelle;
    end;
  end;
end;

{==============================================================================
  uygulama için seçim düğmesi nesnesi oluşturur - api
 ==============================================================================}
function SecimDugmesiGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst: TISayi4; ABaslik: string): TKimlik;
var
  SecimDugmesi: TSecimDugmesi;
begin

  SecimDugmesi := TSecimDugmesi.Create;

  if(SecimDugmesi = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    SecimDugmesi.Ozellestir(ktNesne, AAtaNesne, ASol, AUst, ABaslik);

    Result := SecimDugmesi.Kimlik;
  end;
end;

{==============================================================================
  seçim düğmesi nesnesi oluşturur
 ==============================================================================}
constructor TSecimDugmesi.Create;
begin

  inherited Create;

  NesneTipi := gntSecimDugmesi;

  GGNesneler.GorselNesne[FSiraNo] := Self;
end;

{==============================================================================
  seçim düğmesi nesnesini yok eder
 ==============================================================================}
destructor TSecimDugmesi.Destroy;
begin

  GGNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  seçim düğmesi nesnesini özelleştirir
 ==============================================================================}
function TSecimDugmesi.Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
  ASol, AUst: TISayi4; ABaslik: string): TISayi4;
var
  G: TSayi4;
begin

  G := 16 + 4 + (Length(ABaslik) * 8);

  Yapilandir2(AKullanimTipi, Self, AAtaNesne, ASol, AUst, G,
    16, 0, 0, 0, 0, ABaslik);

  OlayCagriAdr := @OlaylariIsle;

  Baslik := ABaslik;

  Odaklanilabilir := True;
  Odaklanildi := False;

  FSecimDurumu := sdNormal;

  // geri dönüş değeri
  Result := HATA_YOK;
end;

{==============================================================================
  seçim düğmesi nesnesini görüntüler
 ==============================================================================}
procedure TSecimDugmesi.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  seçim düğmesi nesnesini gizler
 ==============================================================================}
procedure TSecimDugmesi.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  seçim düğmesi nesnesini hizalandırır
 ==============================================================================}
procedure TSecimDugmesi.Hizala;
begin

end;

{==============================================================================
  seçim düğmesi nesnesini çizer
 ==============================================================================}
procedure TSecimDugmesi.Ciz;
var
  CizimAlani: TAlan;
  Y, D: TISayi4;      // Yatay / Dikey
  p1: PSayi1;
begin

  // seçim düğmesi üst nesneye bağlı olarak koordinatlarını al
  CizimAlani := FCizimAlani;

  // seçim düğmesi çizim
  if(FSecimDurumu = sdNormal) then
  begin

    p1 := PByte(@SecimDugmeNormal);
    for D := 1 to 12 do
    begin

      for Y := 1 to 12 do
      begin

        if(p1^ = 1) then PixelYaz(Self, CizimAlani.Sol + 1 + Y, CizimAlani.Ust + 1 + D, $6485B5);
        Inc(p1);
      end;
    end;
  end
  else if(FSecimDurumu = sdSecili) then
  begin

    p1 := PByte(@SecimDugmeSecili);
    for D := 1 to 12 do
    begin

      for Y := 1 to 12 do
      begin

        if(p1^ = 1) then PixelYaz(Self, CizimAlani.Sol + 1 + Y, CizimAlani.Ust + 1 + D, $6485B5);
        Inc(p1);
      end;
    end;
  end;

  // seçim düğmesi başlığı
  if(Length(Baslik) > 0) then YaziYaz(Self, CizimAlani.Sol + 20,
    CizimAlani.Ust + 2, Baslik, RENK_SIYAH);
end;

{==============================================================================
  seçim düğmesi nesne olaylarını işler
 ==============================================================================}
procedure TSecimDugmesi.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Pencere: TPencere;
  SecimDugmesi: TSecimDugmesi;
begin

  SecimDugmesi := TSecimDugmesi(AGonderici);
  if(SecimDugmesi = nil) then Exit;

  // farenin sol tuşuna basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // seçim düğmesinin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := GGNesneler.EnUstPencereNesnesiniAl(SecimDugmesi);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GGNesneler.AktifPencere) then
      Pencere.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere.FAktifNesne := SecimDugmesi;
    SecimDugmesi.Odaklanildi := True;

    // sol tuşa basım işlemi nesnenin olay alanında mı gerçekleşti ?
    if(SecimDugmesi.FareNesneOlayAlanindaMi(SecimDugmesi)) then
      GGNesneler.OlayYakalamayaBasla(SecimDugmesi);
  end
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    GGNesneler.OlayYakalamayiBirak(SecimDugmesi);

    // farenin tuş bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(SecimDugmesi.FareNesneOlayAlanindaMi(SecimDugmesi)) then
    begin

      // sadece seçim durumu normal (seçili değil) olduğunda işlem yap
      if(SecimDugmesi.FSecimDurumu = sdNormal) then
      begin

        SecimDugmesi.FSecimDurumu := sdSecili;

        SecimDugmesi.Ciz;

        AOlay.Olay := CO_DURUMDEGISTI;
        AOlay.Deger1 := TISayi4(sdSecili);

        // nesnenin olay çağrı adresini çağır veya uygulamaya mesaj gönder
        if not(SecimDugmesi.OlayYonlAdr = nil) then
          SecimDugmesi.OlayYonlAdr(SecimDugmesi, AOlay)
        else GGorevler.OlayEkle(SecimDugmesi.GrvKimlik, AOlay);
      end;
    end;
  end;

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := SecimDugmesi.FareImlec;
end;

end.
