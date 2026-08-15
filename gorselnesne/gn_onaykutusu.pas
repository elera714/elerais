{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_onaykutusu.pas
  Dosya İşlevi: onay kutusu (TCheckBox) yönetim işlevlerini içerir

  Güncelleme Tarihi: 15/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_onaykutusu;

interface

uses gorselnesne, paylasim, gn_panel;

const
  ResimOnay: array[1..10, 1..10] of TSayi1 = (
    (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0, 1, 0),
    (0, 0, 0, 0, 0, 0, 0, 1, 1, 1),
    (0, 0, 0, 0, 0, 0, 1, 1, 1, 0),
    (0, 1, 0, 0, 0, 1, 1, 1, 0, 0),
    (1, 1, 1, 0, 1, 1, 1, 0, 0, 0),
    (0, 1, 1, 1, 1, 1, 0, 0, 0, 0),
    (0, 0, 1, 1, 1, 0, 0, 0, 0, 0),
    (0, 0, 0, 1, 0, 0, 0, 0, 0, 0));

type
  POnayKutusu = ^TOnayKutusu;
  TOnayKutusu = class(TPanel)
  private
    FOncekiSecimDurumu,
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

function IsaretKutusuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function OnayKutusuGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst: TISayi4; ABaslik: string): TKimlik;

implementation

uses gn_pencere, gn_islevler, temelgorselnesne, gorev, src_ps2;

{==============================================================================
  onay kutusu çağrılarını yönetir
 ==============================================================================}
function IsaretKutusuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  OnayKutusu: TOnayKutusu;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := OnayKutusuGNOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PKarakterKatari(PSayi4(ADegiskenler + 12)^ + GGorevler.FAktifGrvBelAdr)^);
    end;

    ISLEV_GOSTER:
    begin

      OnayKutusu := TOnayKutusu(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      OnayKutusu.Goster;
    end;
  end;
end;

{==============================================================================
  uygulama için onay kutusu nesnesi oluşturur - api
 ==============================================================================}
function OnayKutusuGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst: TISayi4; ABaslik: string): TKimlik;
var
  OnayKutusu: TOnayKutusu;
begin

  OnayKutusu := TOnayKutusu.Create;

  if(OnayKutusu = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    OnayKutusu.Ozellestir(ktNesne, AAtaNesne, ASol, AUst, ABaslik);

    Result := OnayKutusu.Kimlik;
  end;
end;

{==============================================================================
  onay kutusu nesnesi oluşturur
 ==============================================================================}
constructor TOnayKutusu.Create;
begin

  inherited Create;

  NesneTipi := gntOnayKutusu;

  GGNesneler.GorselNesne[FSiraNo] := Self;
end;

{==============================================================================
  onay kutusu nesnesini yok eder
 ==============================================================================}
destructor TOnayKutusu.Destroy;
begin

  GGNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  onay kutusu nesnesini özelleştirir
 ==============================================================================}
function TOnayKutusu.Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
  ASol, AUst: TISayi4; ABaslik: string): TISayi4;
var
  G: TSayi4;
begin

  G := 16 + 3 + (Length(ABaslik) * 8);

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
  onay kutusu nesnesini görüntüler
 ==============================================================================}
procedure TOnayKutusu.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  onay kutusu nesnesini gizler
 ==============================================================================}
procedure TOnayKutusu.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  onay kutusu nesnesini hizalandırır
 ==============================================================================}
procedure TOnayKutusu.Hizala;
begin

  inherited Hizala;
end;

{==============================================================================
  onay kutusu nesnesini çizer
 ==============================================================================}
procedure TOnayKutusu.Ciz;
var
  CizimAlani: TAlan;
  Y, D: TISayi4;      // Yatay / Dikey
  p1: PSayi1;
begin

  // nesne çizim alanı
  CizimAlani := FCizimAlani;

  CizimAlani.Sag := CizimAlani.Sol + 15;
  CizimAlani.Alt := CizimAlani.Ust + 15;

  // onay kutusu normal durum çizimi
  if(FSecimDurumu = sdNormal) then

    DikdortgenDoldur(Self, CizimAlani, RENK_GUMUS, RENK_BEYAZ)

  // onay kutusu seçilmiş durum çizimi
  else if(FSecimDurumu = sdSecili) then
  begin

    DikdortgenDoldur(Self, CizimAlani, RENK_GUMUS, $6485B5);

    p1 := PByte(@ResimOnay);
    for D := 1 to 10 do
    begin

      for Y := 1 to 10 do
      begin

        if(p1^ = 1) then PixelYaz(Self, CizimAlani.Sol + 2 + Y, CizimAlani.Ust + 1 + D, RENK_BEYAZ);
        Inc(p1);
      end;
    end;
  end;

  // onay kutusu başlığı
  if(Length(Baslik) > 0) then
    YaziYaz(Self, CizimAlani.Sag + 3, CizimAlani.Ust + 1, Baslik, RENK_SIYAH);

  // nesne odaklanılmış ise nesnenin kenarlarını işaretle
  if(Odaklanildi) then
  begin

    CizimAlani := FCizimAlani;
    Dikdortgen(Self, ctNokta, CizimAlani, RENK_SIYAH);
  end;
end;

{==============================================================================
  onay kutusu nesne olaylarını işler
 ==============================================================================}
procedure TOnayKutusu.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Pencere: TPencere;
  OnayKutusu: TOnayKutusu;
begin

  OnayKutusu := TOnayKutusu(AGonderici);
  if(OnayKutusu = nil) then Exit;

  // farenin sol tuşuna basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // onay kutusu'nun sahibi olan pencere en üstte mi ? kontrol et
    Pencere := GGNesneler.EnUstPencereNesnesiniAl(OnayKutusu);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GGNesneler.AktifPencere) then
      Pencere.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere.FAktifNesne := OnayKutusu;
    OnayKutusu.Odaklanildi := True;

    // sol tuşa basım işlemi nesnenin olay alanında mı gerçekleşti ?
    if(OnayKutusu.FareNesneOlayAlanindaMi(OnayKutusu)) then
    begin

      // fare olaylarını yakala
      GGNesneler.OlayYakalamayaBasla(OnayKutusu);

      // mevcut durum değerini sakla
      FOncekiSecimDurumu := OnayKutusu.FSecimDurumu;

      if(OnayKutusu.FSecimDurumu = sdNormal) then
        OnayKutusu.FSecimDurumu := sdSecili
      else OnayKutusu.FSecimDurumu := sdNormal;

      // onay kutusu nesnesini yeniden çiz
      OnayKutusu.Ciz;
    end;
  end
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    GGNesneler.OlayYakalamayiBirak(OnayKutusu);

    // farenin tuş bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(OnayKutusu.FareNesneOlayAlanindaMi(OnayKutusu)) then
    begin

      // yakalama & bırakma işlemi bu nesnede olduğu için
      // nesneye durum değişiklik mesajı gönder
      AOlay.Olay := CO_DURUMDEGISTI;
      if(OnayKutusu.FSecimDurumu = sdNormal) then
        AOlay.Deger1 := 0
      else AOlay.Deger1 := 1;

      // nesnenin olay çağrı adresini çağır veya uygulamaya mesaj gönder
      if not(OnayKutusu.OlayYonlAdr = nil) then
        OnayKutusu.OlayYonlAdr(OnayKutusu, AOlay)
      else GGorevler.OlayEkle(OnayKutusu.GrvKimlik, AOlay);

    // aksi durumda onay kutusu durumunu bir önceki duruma getir
    end else OnayKutusu.FSecimDurumu := OnayKutusu.FOncekiSecimDurumu;

    // onay kutusu nesnesini yeniden çiz
    OnayKutusu.Ciz;
  end;

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := OnayKutusu.FareImlec;
end;

end.
