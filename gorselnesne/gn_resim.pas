{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_resim.pas
  Dosya İşlevi: resim (TImage) nesne yönetim işlevlerini içerir

  Güncelleme Tarihi: 15/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_resim;

interface

uses gorselnesne, paylasim, temelgorselnesne, gn_panel;

type
  PResim = ^TResim;
  TResim = class(TPanel)
  public
    FTuvaleSigdir: LongBool;
    FGoruntuYapi: TGoruntuYapi;
    constructor Create; override;
    destructor Destroy; override;
    function Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4; ADosyaYolu: string): TISayi4;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
    procedure ResimYaz(ADosyaYolu: string);
  end;

function ResimCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function ResimGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ADosyaYolu: string): TKimlik;

implementation

uses gn_pencere, gn_islevler, bmp, gorev, src_ps2;

{==============================================================================
  resim nesnesi kesme çağrılarını yönetir
 ==============================================================================}
function ResimCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  Pencere: TPencere;
  Resim: TResim;
  Hiza: THiza;
  p: PKarakterKatari;
  TuvaleSigdir: Boolean;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := ResimGNOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^,
        PKarakterKatari(PSayi4(ADegiskenler + 20)^ + GGorevler.FAktifGrvBelAdr)^);
    end;

    ISLEV_GOSTER:
    begin

      Resim := TResim(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Resim.Goster;
    end;

    ISLEV_HIZALA:
    begin

      Resim := TResim(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      Resim.FHiza := Hiza;

      Pencere := TPencere(Resim.FAtaNesne);
      Pencere.Guncelle;
    end;

    // resmi değiştir
    $010F:
    begin

      Resim := TResim(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      p := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr);
      Resim.ResimYaz(p^);
    end;

    $020F:
    begin

      Resim := TResim(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      TuvaleSigdir := PLongBool(ADegiskenler + 04)^;
      Resim.FTuvaleSigdir := TuvaleSigdir;

      Pencere := TPencere(Resim.FAtaNesne);
      Pencere.Guncelle;
    end;
  end;
end;

{==============================================================================
  uygulama için resim nesnesi oluşturur - api
 ==============================================================================}
function ResimGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ADosyaYolu: string): TKimlik;
var
  Resim: TResim;
begin

  Resim := TResim.Create;

  if(Resim = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    Resim.Ozellestir(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik, ADosyaYolu);

    Result := Resim.Kimlik;
  end;
end;

{==============================================================================
  resim nesnesi oluşturur
 ==============================================================================}
constructor TResim.Create;
begin

  inherited Create;

  NesneTipi := gntResim;

  GGNesneler.GorselNesne[FSiraNo] := Self;
end;

{==============================================================================
  resim nesnesini yok eder
 ==============================================================================}
destructor TResim.Destroy;
begin

  if not(FGoruntuYapi.BellekAdresi = nil) then
    FreeMem(FGoruntuYapi.BellekAdresi, FGoruntuYapi.Genislik * FGoruntuYapi.Yukseklik * 4);

  GGNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  resim nesnesini özelleştirir
 ==============================================================================}
function TResim.Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4; ADosyaYolu: string): TISayi4;
begin

  Yapilandir2(AKullanimTipi, Self, AAtaNesne, ASol, AUst, AGenislik, AYukseklik,
    2, RENK_BEYAZ, RENK_BEYAZ, 0, '');

  OlayCagriAdr := @OlaylariIsle;

  Odaklanilabilir := False;
  Odaklanildi := False;
  FTuvaleSigdir := False;

  FCizimBaslangic.Sol := AtaNesne.FCizimBaslangic.Sol + AtaNesne.FKalinlik.Sol + ASol;
  FCizimBaslangic.Ust := AtaNesne.FCizimBaslangic.Ust + AtaNesne.FKalinlik.Ust + AUst;

  FGoruntuYapi.BellekAdresi := nil;

  // eğer dosya adı belirtilmişse, dosyayı yükle
  if(Length(ADosyaYolu) > 0) then ResimYaz(ADosyaYolu);

  // geri dönüş değeri
  Result := HATA_YOK;
end;

{==============================================================================
  resim nesnesini görüntüler
 ==============================================================================}
procedure TResim.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  resim nesnesini gizler
 ==============================================================================}
procedure TResim.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  resim nesnesini hizalandırır
 ==============================================================================}
procedure TResim.Hizala;
begin

  inherited Hizala;
end;

{==============================================================================
  resim nesnesini çizer
 ==============================================================================}
procedure TResim.Ciz;
var
  BMP: TBMP;
begin

  inherited Ciz;

  if(Gorunum) then
  begin

    if not(FGoruntuYapi.BellekAdresi = nil) then
    begin

      BMP := TBMP.Create;
      BMP.Ciz(gntResim, Self, FGoruntuYapi);
      BMP.Destroy;
    end;
  end;
end;

{==============================================================================
  resim nesne olaylarını işler
 ==============================================================================}
procedure TResim.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Pencere: TPencere;
  Resim: TResim;
begin

  Resim := TResim(AGonderici);
  if(Resim = nil) then Exit;

  // farenin sol tuşuna basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // resim nesnesinin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := GGNesneler.EnUstPencereNesnesiniAl(Resim);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GGNesneler.AktifPencere) then
      Pencere.EnUsteGetir(Pencere);

    // fare olaylarını yakala
    GGNesneler.OlayYakalamayaBasla(Resim);

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(Resim.OlayYonlAdr = nil) then
      Resim.OlayYonlAdr(Resim, AOlay)
    else GGorevler.OlayEkle(Resim.GrvKimlik, AOlay);
  end
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    GGNesneler.OlayYakalamayiBirak(Resim);

    // farenin tuş bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(Resim.FareNesneOlayAlanindaMi(Resim)) then
    begin

      // yakalama & bırakma işlemi bu nesnede olduğu için
      // nesneye FO_TIKLAMA mesajı gönder
      AOlay.Olay := FO_TIKLAMA;
      if not(Resim.OlayYonlAdr = nil) then
        Resim.OlayYonlAdr(Resim, AOlay)
      else GGorevler.OlayEkle(Resim.GrvKimlik, AOlay);
    end;

    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    if not(Resim.OlayYonlAdr = nil) then
      Resim.OlayYonlAdr(Resim, AOlay)
    else GGorevler.OlayEkle(Resim.GrvKimlik, AOlay);
  end
  else if(AOlay.Olay = FO_HAREKET) then
  begin

    if not(Resim.OlayYonlAdr = nil) then
      Resim.OlayYonlAdr(Resim, AOlay)
    else GGorevler.OlayEkle(Resim.GrvKimlik, AOlay);
  end;

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := Resim.FareImlec;
end;

{==============================================================================
  resim nesnesinda görüntülenecek dosyanın içeriğini belleğe yükler
 ==============================================================================}
procedure TResim.ResimYaz(ADosyaYolu: string);
var
  BMP: TBMP;
begin

  // daha önce resim için bellek rezerv edildiyse belleği iptal et
  if not(FGoruntuYapi.BellekAdresi = nil) then
  begin

    FreeMem(FGoruntuYapi.BellekAdresi, FGoruntuYapi.Genislik * FGoruntuYapi.Yukseklik * 4);

    FGoruntuYapi.BellekAdresi := nil;
  end;

  if(Length(ADosyaYolu) > 0) then
  begin

    BMP := TBMP.Create;
    FGoruntuYapi := BMP.Yukle(ADosyaYolu);
    BMP.Destroy;
  end;

  Ciz;
end;

end.
