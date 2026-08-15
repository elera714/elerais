{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_kaydirmacubugu.pas
  Dosya İşlevi: kaydırma çubuğu (TScrollBar) yönetim işlevlerini içerir

  Güncelleme Tarihi: 15/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_kaydirmacubugu;

interface

uses gorev, gorselnesne, paylasim, gn_pencere, gn_panel, gn_resimdugmesi;

type
  PKaydirmaCubugu = ^TKaydirmaCubugu;
  TKaydirmaCubugu = class(TPanel)
  private
    procedure ResimDugmesiOlaylariniIsle(AGonderici: TGorselNesne; AOlay: TOlay);
  public
    FEksiltmeDugmesi,
    FArtirmaDugmesi: TResimDugmesi;
    FYon: TYon;
    constructor Create; override;
    destructor Destroy; override;
    function Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne; ASol, AUst,
      AGenislik, AYukseklik: TISayi4; AYon: TYon): TISayi4;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
    procedure DegerleriBelirle(AAltDeger, AUstDeger: TISayi4);
    property MevcutDeger: TISayi4 read FIDeger1 write FIDeger1;
    property AltDeger: TISayi4 read FIDeger2 write FIDeger2;
    property UstDeger: TISayi4 read FIDeger3 write FIDeger3;
  end;

function KaydirmaCubuguCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function KaydirmaCubuguGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  AYon: TYon): TKimlik;

implementation

uses gn_islevler, temelgorselnesne, src_ps2;

{==============================================================================
  kaydırma çubuğu kesme çağrılarını yönetir
 ==============================================================================}
function KaydirmaCubuguCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  Pencere: TPencere;
  KaydirmaCubugu: TKaydirmaCubugu;
  Hiza: THiza;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := KaydirmaCubuguGNOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^, PYon(ADegiskenler + 20)^);
    end;

    ISLEV_GOSTER:
    begin

      KaydirmaCubugu := TKaydirmaCubugu(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      KaydirmaCubugu.Goster;
    end;

    ISLEV_HIZALA:
    begin

      KaydirmaCubugu := TKaydirmaCubugu(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      KaydirmaCubugu.FHiza := Hiza;

      Pencere := TPencere(KaydirmaCubugu.FAtaNesne);
      Pencere.Guncelle;
    end;

    // alt, üst değerlerini belirle
    $010F:
    begin

      KaydirmaCubugu := TKaydirmaCubugu(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntKaydirmaCubugu));
      if(KaydirmaCubugu <> nil) then KaydirmaCubugu.DegerleriBelirle(
        PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^);
    end;
  end;
end;

{==============================================================================
  uygulama için kaydırma çubuğu nesnesi oluşturur - api
 ==============================================================================}
function KaydirmaCubuguGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  AYon: TYon): TKimlik;
var
  KaydirmaCubugu: TKaydirmaCubugu;
begin

  KaydirmaCubugu := TKaydirmaCubugu.Create;

  if(KaydirmaCubugu = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    KaydirmaCubugu.Ozellestir(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik, AYon);

    Result := KaydirmaCubugu.Kimlik;
  end;
end;

{==============================================================================
  kaydırma çubuğu nesnesi oluşturur
 ==============================================================================}
constructor TKaydirmaCubugu.Create;
begin

  inherited Create;

  NesneTipi := gntKaydirmaCubugu;

  GGNesneler.GorselNesne[FSiraNo] := Self;
end;

{==============================================================================
  kaydırma çubuğu nesnesini yok eder
 ==============================================================================}
destructor TKaydirmaCubugu.Destroy;
begin

  FArtirmaDugmesi.Destroy;
  FEksiltmeDugmesi.Destroy;

  GGNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  kaydırma çubuğu nesnesini özelleştirir
 ==============================================================================}
function TKaydirmaCubugu.Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4; AYon: TYon): TISayi4;
var
  Genislik, Yukseklik: TISayi4;
begin

  Yukseklik := AYukseklik;
  Genislik := AGenislik;

  // dikey kaydırma çubuğunun genişliği 20px (0..19) olarak sabitleniyor
  if(AYon = yDikey) then
    Genislik := 20
  else Genislik := AGenislik;

  // yatay kaydırma çubuğunun yüksekliği 20px (0..19) olarak sabitleniyor
  if(AYon = yYatay) then
    Yukseklik := 20
  else Yukseklik := AYukseklik;

  Yapilandir2(AKullanimTipi, Self, AAtaNesne, ASol, AUst, Genislik, Yukseklik,
    3, RENK_GUMUS, RENK_BEYAZ, 0, '');

  OlayCagriAdr := @OlaylariIsle;

  // şu aşamada bu nesne odaklanılabilir bir nesne değil
  Odaklanilabilir := False;
  Odaklanildi := False;

  FYon := AYon;

  // kaydırma çubuğu kontrol düğmelerinin oluşturulması
  if(AYon = yYatay) then
  begin

    // $10000000 + 4 = sol ok resmi
    FEksiltmeDugmesi := TResimDugmesi.Create;
    FEksiltmeDugmesi.Ozellestir(ktBilesen, Self, 0, 0, 19, Yukseklik, $10000000 + 4, True);
    FEksiltmeDugmesi.OlayYonlAdr := @ResimDugmesiOlaylariniIsle;

    // $10000000 + 3 = sağ ok resmi
    FArtirmaDugmesi := TResimDugmesi.Create;
    FArtirmaDugmesi.Ozellestir(ktBilesen, Self, Genislik - 19, 0, 19, Yukseklik, $10000000 + 3, True);
    FArtirmaDugmesi.OlayYonlAdr := @ResimDugmesiOlaylariniIsle;
  end
  else
  begin

    // $10000000 + 1 = yukarı ok resmi
    FEksiltmeDugmesi := TResimDugmesi.Create;
    FEksiltmeDugmesi.Ozellestir(ktBilesen, Self, 0, 0, 19, 19, $10000000 + 1, True);
    FEksiltmeDugmesi.OlayYonlAdr := @ResimDugmesiOlaylariniIsle;

    // $10000000 + 2 = aşağı ok resmi
    FArtirmaDugmesi := TResimDugmesi.Create;
    FArtirmaDugmesi.Ozellestir(ktBilesen, Self, 0, Yukseklik - 19, 19, 19, $10000000 + 2, True);
    FArtirmaDugmesi.OlayYonlAdr := @ResimDugmesiOlaylariniIsle;
  end;

  MevcutDeger := 0;
  AltDeger := 0;
  UstDeger := 100;

  // geri dönüş değeri
  Result := HATA_YOK;
end;

{==============================================================================
  kaydırma çubuğu nesnesini görüntüler
 ==============================================================================}
procedure TKaydirmaCubugu.Goster;
begin

  FArtirmaDugmesi.Goster;
  FEksiltmeDugmesi.Goster;

  inherited Goster;
end;

{==============================================================================
  kaydırma çubuğu nesnesini gizler
 ==============================================================================}
procedure TKaydirmaCubugu.Gizle;
begin

  FArtirmaDugmesi.Gizle;
  FEksiltmeDugmesi.Gizle;

  inherited Gizle;
end;

{==============================================================================
  kaydırma çubuğu nesnesini hizalandırır
 ==============================================================================}
procedure TKaydirmaCubugu.Hizala;
begin

  if(FYon = yYatay) then
  begin

    FEksiltmeDugmesi.FAtananAlan.Sol := 0;
    FEksiltmeDugmesi.FAtananAlan.Ust := 0;
    FEksiltmeDugmesi.FAtananAlan.Genislik := 20;
    FEksiltmeDugmesi.FAtananAlan.Yukseklik := 20;
    FEksiltmeDugmesi.BoyutlariYenidenHesapla;

    FArtirmaDugmesi.FAtananAlan.Sol := FAtananAlan.Genislik - 20;
    FArtirmaDugmesi.FAtananAlan.Ust := 0;
    FArtirmaDugmesi.FAtananAlan.Genislik := 20;
    FArtirmaDugmesi.FAtananAlan.Yukseklik := 20;
    FArtirmaDugmesi.BoyutlariYenidenHesapla;
  end
  else if(FYon = yDikey) then
  begin

    FEksiltmeDugmesi.FAtananAlan.Sol := 0;
    FEksiltmeDugmesi.FAtananAlan.Ust := 0;
    FEksiltmeDugmesi.FAtananAlan.Genislik := 20;
    FEksiltmeDugmesi.FAtananAlan.Yukseklik := 20;
    FEksiltmeDugmesi.BoyutlariYenidenHesapla;

    FArtirmaDugmesi.FAtananAlan.Sol := 0;
    FArtirmaDugmesi.FAtananAlan.Ust := FAtananAlan.Yukseklik - 20;
    FArtirmaDugmesi.FAtananAlan.Genislik := 20;
    FArtirmaDugmesi.FAtananAlan.Yukseklik := 20;
    FArtirmaDugmesi.BoyutlariYenidenHesapla;
  end;
end;

{==============================================================================
  kaydırma çubuğu nesnesini çizer
 ==============================================================================}
procedure TKaydirmaCubugu.Ciz;
var
  CizimAlani: TAlan;
  Frekans: Double;
  AraBoslukU, i: TISayi4;
begin

  inherited Ciz;

  // kaydırma çubuğunun çizim alan koordinatlarını al
  CizimAlani := FCizimAlani;

  if(FYon = yDikey) then
  begin

    AraBoslukU := FAtananAlan.Yukseklik - (20 * 3);
    Frekans := AraBoslukU / UstDeger;

    i := Round(MevcutDeger * Frekans);

    DikdortgenDoldur(Self, CizimAlani.Sol + 2, CizimAlani.Ust + 20 + i,
      CizimAlani.Sag - 2, CizimAlani.Ust + 20 + i + 20, $7F7F7F, $7F7F7F);
  end
  else
  begin

    AraBoslukU := FAtananAlan.Genislik - (20 * 3);
    Frekans := AraBoslukU / UstDeger;

    i := Round(MevcutDeger * Frekans);

    DikdortgenDoldur(Self, CizimAlani.Sol + 20 + i, CizimAlani.Ust + 2,
      CizimAlani.Sol + 20 + i + 20, CizimAlani.Alt - 2, $7F7F7F, $7F7F7F);
  end;
end;

{==============================================================================
  kaydırma çubuğu nesne olaylarını işler
 ==============================================================================}
procedure TKaydirmaCubugu.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Pencere: TPencere;
  KaydirmaCubugu: TKaydirmaCubugu;
begin

  KaydirmaCubugu := TKaydirmaCubugu(AGonderici);
  if(KaydirmaCubugu = nil) then Exit;

  // farenin sol tuşuna basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // kaydırma çubuğunun sahibi olan pencere en üstte mi ? kontrol et
    Pencere := GGNesneler.EnUstPencereNesnesiniAl(KaydirmaCubugu);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GGNesneler.AktifPencere) then
      Pencere.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    // bilgi: şu aşamada bu nesne odaklanılabilir bir nesne değil
    //Pencere^.FAktifNesne := KaydirmaCubugu;
    //KaydirmaCubugu^.Odaklanildi := False;
  end;

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := KaydirmaCubugu.FareImlec;
end;

{==============================================================================
  kaydırma çubuğunun sahip olduğu artırma / eksiltme nesne olaylarını işler
 ==============================================================================}
procedure TKaydirmaCubugu.ResimDugmesiOlaylariniIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  KaydirmaCubugu: TKaydirmaCubugu;
  ResimDugmesi: TResimDugmesi;
  i: TISayi4;
begin

  ResimDugmesi := TResimDugmesi(AGonderici);
  if(ResimDugmesi = nil) then Exit;

  KaydirmaCubugu := TKaydirmaCubugu(ResimDugmesi.AtaNesne);

  if(AOlay.Olay = FO_TIKLAMA) then
  begin

    // eksiltme düğmesi işlevi
    if(AOlay.Kimlik = KaydirmaCubugu.FEksiltmeDugmesi.Kimlik) then
    begin

      i := KaydirmaCubugu.MevcutDeger;
      Dec(i);
      if(i < KaydirmaCubugu.AltDeger) then i := KaydirmaCubugu.AltDeger;
    end
    else
    // artırma düğmesi işlevi
    begin

      i := KaydirmaCubugu.MevcutDeger;
      Inc(i);
      if(i > KaydirmaCubugu.UstDeger) then i := KaydirmaCubugu.UstDeger;
    end;

    KaydirmaCubugu.MevcutDeger := i;

    KaydirmaCubugu.Ciz;

    AOlay.Kimlik := KaydirmaCubugu.Kimlik;
    AOlay.Deger1 := KaydirmaCubugu.MevcutDeger;

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(KaydirmaCubugu.OlayYonlAdr = nil) then
      KaydirmaCubugu.OlayYonlAdr(KaydirmaCubugu, AOlay)
    else GGorevler.OlayEkle(KaydirmaCubugu.GrvKimlik, AOlay);
  end;

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := KaydirmaCubugu.FareImlec;
end;

{==============================================================================
  kaydırma çubuğu alt, üst, mevcut değerlerini belirler
 ==============================================================================}
procedure TKaydirmaCubugu.DegerleriBelirle(AAltDeger, AUstDeger: TISayi4);
begin

  AltDeger := AAltDeger;
  UstDeger := AUstDeger;
  MevcutDeger := AAltDeger;
end;

end.
