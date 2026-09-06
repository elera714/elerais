{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_sayfakontrol.pas
  Dosya İşlevi: sayfa kontrol (TPageControl) nesne yönetim işlevlerini içerir

  Güncelleme Tarihi: 17/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_sayfakontrol;

interface

uses gorselnesne, paylasim, gn_panel, gn_dugme, gn_etiket;

const
  AZAMI_SEKMESAYISI   = 4;    // sayfa kontrol nesnesinde kullanılacak azami sekme sayısı (panel)
  AZAMI_ETIKETSAYISI  = 4;    // (sekme) panel nesne içeriğindeki azami etiket sayısı

type
  PSayfaKontrol = ^TSayfaKontrol;
  TSayfaKontrol = class(TPanel)
  private
    FSayfaSayisi, FAktifSayfa: TISayi4;
    FDugmeler: array[0..AZAMI_SEKMESAYISI - 1] of TDugme;     // nesnedeki her bir paneli temsil eden düğmeler
    FPaneller: array[0..AZAMI_SEKMESAYISI - 1] of TPanel;     // nesnedeki paneller
    FEtiketler: array[0..(AZAMI_SEKMESAYISI * AZAMI_ETIKETSAYISI) - 1] of TEtiket;
    FBaslikG: array[0..AZAMI_SEKMESAYISI - 1] of TSayi4;      // her bir düğmenin başlık genişliği
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
    procedure SekmeOlaylariniIsle(AGonderici: TGorselNesne; AOlay: TOlay);
    function SayfaEkle(ABaslik: string): TKimlik;
    procedure EtiketEkle(ASayfaNo, ASol, AUst: TISayi4; ABaslik: string);
  end;

function SayfaKontrolCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function SayfaKontrolGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;

implementation

uses gorev, gn_islevler, src_ps2;

{==============================================================================
  sayfa kontrol kesme çağrılarını yönetir
 ==============================================================================}
function SayfaKontrolCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  SayfaKontrol: TSayfaKontrol;
  p: PKarakterKatari;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := SayfaKontrolGNOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^);
    end;

    ISLEV_GOSTER:
    begin

      SayfaKontrol := TSayfaKontrol(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      SayfaKontrol.Goster;
    end;

    ISLEV_GIZLE:
    begin

      SayfaKontrol := TSayfaKontrol(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      SayfaKontrol.Gizle;
    end;

    // sayfa kontrol nesnesine yeni sayfa ekle
    $010F:
    begin

      SayfaKontrol := TSayfaKontrol(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      p := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr);
      SayfaKontrol.SayfaEkle(p^);
    end;

    // panel sekme içeriğine etiket ekle
    $020F:
    begin

      SayfaKontrol := TSayfaKontrol(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      p := PKarakterKatari(PSayi4(ADegiskenler + 16)^ + GGorevler.FAktifGrvBelAdr);
      SayfaKontrol.EtiketEkle(PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, p^);
    end;
  end;
end;

{==============================================================================
  uygulama için sayfa kontrol nesnesi oluşturur - api
 ==============================================================================}
function SayfaKontrolGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
var
  SayfaKontrol: TSayfaKontrol;
begin

  SayfaKontrol := TSayfaKontrol.Create;

  if(SayfaKontrol = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    SayfaKontrol.Ozellestir(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik);

    Result := SayfaKontrol.Kimlik;
  end;
end;

{==============================================================================
  sayfa kontrol nesnesi oluşturur
 ==============================================================================}
constructor TSayfaKontrol.Create;
begin

  inherited Create;

  NesneTipi := gntSayfaKontrol;

  GGNesneler.GorselNesne[FSiraNo] := Self;
end;

{==============================================================================
  sayfa kontrol nesnesini yok eder
 ==============================================================================}
destructor TSayfaKontrol.Destroy;
var
  i: TSayi4;
begin

  // (sekme) panel içerisindeki etiket nesneleri yok ediliyor
  for i := 0 to (AZAMI_SEKMESAYISI * AZAMI_ETIKETSAYISI) - 1 do
  begin

    if not(FEtiketler[i] = nil) then FEtiketler[i].Destroy;
  end;

  // sekmeler yok ediliyor
  for i := 0 to AZAMI_SEKMESAYISI - 1 do
  begin

    if not(FPaneller[i] = nil) then FPaneller[i].Destroy;
    if not(FDugmeler[i] = nil) then FDugmeler[i].Destroy;
  end;

  GGNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  sayfa kontrol nesnesini özelleştirir
 ==============================================================================}
function TSayfaKontrol.Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4): TISayi4;
var
  i: TSayi4;
begin

  Yapilandir2(AKullanimTipi, Self, AAtaNesne, ASol, AUst, AGenislik, AYukseklik,
    2, RENK_BEYAZ, RENK_BEYAZ, 0, '');

  OlayCagriAdr := @OlaylariIsle;

  FSayfaSayisi := 0;
  FAktifSayfa := -1;

  for i := 0 to AZAMI_SEKMESAYISI - 1 do
  begin

    FPaneller[i] := nil;
    FDugmeler[i] := nil;
  end;

  for i := 0 to (AZAMI_SEKMESAYISI * AZAMI_ETIKETSAYISI) - 1 do FEtiketler[i] := nil;

  // geri dönüş değeri
  Result := HATA_YOK;
end;

{==============================================================================
  sayfa kontrol nesnesini görüntüler
 ==============================================================================}
procedure TSayfaKontrol.Goster;
begin

  if(FAktifSayfa = 0) then
  begin

    FPaneller[0].Goster;
    FPaneller[1].Gizle;
    FPaneller[2].Gizle;
    FPaneller[3].Gizle;
  end
  else if(FAktifSayfa = 1) then
  begin

    FPaneller[0].Gizle;
    FPaneller[1].Goster;
    FPaneller[2].Gizle;
    FPaneller[3].Gizle;
  end
  else if(FAktifSayfa = 2) then
  begin

    FPaneller[0].Gizle;
    FPaneller[1].Gizle;
    FPaneller[2].Goster;
    FPaneller[3].Gizle;
  end
  else if(FAktifSayfa = 3) then
  begin

    FPaneller[0].Gizle;
    FPaneller[1].Gizle;
    FPaneller[2].Gizle;
    FPaneller[3].Goster;
  end;

  inherited Goster;
end;

{==============================================================================
  sayfa kontrol nesnesini gizler
 ==============================================================================}
procedure TSayfaKontrol.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  sayfa kontrol nesnesini hizalandırır
 ==============================================================================}
procedure TSayfaKontrol.Hizala;
begin

  inherited Hizala;
end;

{==============================================================================
  sayfa kontrol nesnesini çizer
 ==============================================================================}
procedure TSayfaKontrol.Ciz;
begin

  if(FAktifSayfa = 0) then
  begin

    FPaneller[0].Goster;
    FPaneller[1].Gizle;
    FPaneller[2].Gizle;
    FPaneller[3].Gizle;
  end
  else if(FAktifSayfa = 1) then
  begin

    FPaneller[0].Gizle;
    FPaneller[1].Goster;
    FPaneller[2].Gizle;
    FPaneller[3].Gizle;
  end
  else if(FAktifSayfa = 2) then
  begin

    FPaneller[0].Gizle;
    FPaneller[1].Gizle;
    FPaneller[2].Goster;
    FPaneller[3].Gizle;
  end
  else if(FAktifSayfa = 3) then
  begin

    FPaneller[0].Gizle;
    FPaneller[1].Gizle;
    FPaneller[2].Gizle;
    FPaneller[3].Goster;
  end;

  // öncelikle kendini çiz
  inherited Ciz;
end;

{==============================================================================
  sayfa kontrol nesne olaylarını işler
 ==============================================================================}
procedure TSayfaKontrol.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  SayfaKontrol: TSayfaKontrol;
begin

  SayfaKontrol := TSayfaKontrol(AGonderici);

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := SayfaKontrol.FareImlec;
end;

{==============================================================================
  sekme olaylarını işler
 ==============================================================================}
procedure TSayfaKontrol.SekmeOlaylariniIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Dugme: TDugme;
  SayfaKontrol: TSayfaKontrol;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  Dugme := TDugme(AGonderici);
  if(Dugme = nil) then Exit;

  SayfaKontrol := TSayfaKontrol(Dugme.AtaNesne);

  // hangi sekmeye tıklandıysa o sekmenin panel görünürlüğünü aktifleştir
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    if(AOlay.Kimlik = SayfaKontrol.FDugmeler[0].Kimlik) then
      SayfaKontrol.FAktifSayfa := 0
    else if(AOlay.Kimlik = SayfaKontrol.FDugmeler[1].Kimlik) then
      SayfaKontrol.FAktifSayfa := 1
    else if(AOlay.Kimlik = SayfaKontrol.FDugmeler[2].Kimlik) then
      SayfaKontrol.FAktifSayfa := 2
    else if(AOlay.Kimlik = SayfaKontrol.FDugmeler[3].Kimlik) then
      SayfaKontrol.FAktifSayfa := 3;

    SayfaKontrol.Ciz;
  end
end;

function TSayfaKontrol.SayfaEkle(ABaslik: string): TKimlik;
var
  i: TSayi4;
begin

  i := FSayfaSayisi;
  if(i >= AZAMI_SEKMESAYISI) then Exit(HATA_ALTNESNEBELLEKDOLU);

  if(i = 0) then
  begin

    // sekme düğme başlık genişliği
    FBaslikG[0] := Length(ABaslik) * 8 + 10;

    // sekme düğmesi
    FDugmeler[0] := TDugme.Create;
    FDugmeler[0].Ozellestir(ktBilesen, Self, 0, 0, FBaslikG[0], 20, ABaslik);
    FDugmeler[0].CizimModelDegistir(False, RENK_GRI, RENK_GUMUS, RENK_SIYAH, RENK_KIRMIZI);
    FDugmeler[0].OlayYonlAdr := @SekmeOlaylariniIsle;
    FDugmeler[0].Goster;

    // sekme paneli
    FPaneller[0] := TPanel.Create;
    FPaneller[0].Yapilandir2(ktBilesen, FPaneller[0], Self, 0, 20,
      FAtananAlan.Genislik, FAtananAlan.Yukseklik - 20, 3, RENK_SIYAH, RENK_BEYAZ, 0, '');
    //FPaneller[i].FHiza := hzTum;
    FPaneller[0].FDeger1 := 0;
    FPaneller[0].Gorunum := True;

    FSayfaSayisi := 1;
    FAktifSayfa := 0;

    Result := FPaneller[0].Kimlik;
  end
  else if(i = 1) then
  begin

    // sekme düğme başlık genişliği
    FBaslikG[1] := Length(ABaslik) * 8 + 10;

    // sekme düğmesi
    FDugmeler[1] := TDugme.Create;
    FDugmeler[1].Ozellestir(ktBilesen, Self, FBaslikG[0], 0, FBaslikG[1], 20, ABaslik);
    FDugmeler[1].CizimModelDegistir(False, RENK_GRI, RENK_GUMUS, RENK_SIYAH, RENK_KIRMIZI);
    FDugmeler[1].OlayYonlAdr := @SekmeOlaylariniIsle;
    FDugmeler[1].Goster;

    // sekme paneli
    FPaneller[1] := TPanel.Create;
    FPaneller[1].Yapilandir2(ktBilesen, FPaneller[1], Self, 0, 20,
      FAtananAlan.Genislik, FAtananAlan.Yukseklik - 20, 3, RENK_SIYAH, RENK_BEYAZ, 0, '');
    //FPaneller[i].FHiza := hzTum;
    FPaneller[1].FDeger1 := 0;
    FPaneller[1].Gorunum := False;

    FSayfaSayisi := 2;
    FAktifSayfa := 0;

    Result := FPaneller[1].Kimlik;
  end
  else if(i = 2) then
  begin

    // sekme düğme başlık genişliği
    FBaslikG[2] := Length(ABaslik) * 8 + 10;

    // sekme düğmesi
    FDugmeler[2] := TDugme.Create;
    FDugmeler[2].Ozellestir(ktBilesen, Self, FBaslikG[0] + FBaslikG[1], 0, FBaslikG[2], 20, ABaslik);
    FDugmeler[2].CizimModelDegistir(False, RENK_GRI, RENK_GUMUS, RENK_SIYAH, RENK_KIRMIZI);
    FDugmeler[2].OlayYonlAdr := @SekmeOlaylariniIsle;
    FDugmeler[2].Goster;

    // sekme paneli
    FPaneller[2] := TPanel.Create;
    FPaneller[2].Yapilandir2(ktBilesen, FPaneller[2], Self, 0, 20,
      FAtananAlan.Genislik, FAtananAlan.Yukseklik - 20, 3, RENK_SIYAH, RENK_BEYAZ, 0, '');
    //FPaneller[i].FHiza := hzTum;
    FPaneller[2].FDeger1 := 0;
    FPaneller[2].Gorunum := False;

    FSayfaSayisi := 3;
    FAktifSayfa := 0;

    Result := FPaneller[2].Kimlik;
  end
  else //if(i = 3) then
  begin

    // sekme düğme başlık genişliği
    FBaslikG[3] := Length(ABaslik) * 8 + 10;

    // sekme düğmesi
    FDugmeler[3] := TDugme.Create;
    FDugmeler[3].Ozellestir(ktBilesen, Self, FBaslikG[0] + FBaslikG[1] + FBaslikG[2], 0, FBaslikG[3], 20, ABaslik);
    FDugmeler[3].CizimModelDegistir(False, RENK_GRI, RENK_GUMUS, RENK_SIYAH, RENK_KIRMIZI);
    FDugmeler[3].OlayYonlAdr := @SekmeOlaylariniIsle;
    FDugmeler[3].Goster;

    // sekme paneli
    FPaneller[3] := TPanel.Create;
    FPaneller[3].Yapilandir2(ktBilesen, FPaneller[3], Self, 0, 20,
      FAtananAlan.Genislik, FAtananAlan.Yukseklik - 20, 3, RENK_SIYAH, RENK_BEYAZ, 0, '');
    //FPaneller[i].FHiza := hzTum;
    FPaneller[3].FDeger1 := 0;
    FPaneller[3].Gorunum := False;

    FSayfaSayisi := 4;
    FAktifSayfa := 0;

    Result := FPaneller[3].Kimlik;
  end;
end;

{==============================================================================
  her bir sekmeyi temsil eden panelinin içerisine etiket (yazı) ekler
 ==============================================================================}
{ TODO : ileride tüm görsel nesnelerin bu panele eklenmesi sağlanacak }
procedure TSayfaKontrol.EtiketEkle(ASayfaNo, ASol, AUst: TISayi4; ABaslik: string);
var
  Panel: TPanel;
  Genislik, i,
  SiraNo: TSayi4;
begin

  if(ASayfaNo = 0) then
    Panel := FPaneller[0]
  else if(ASayfaNo = 1) then
    Panel := FPaneller[1]
  else if(ASayfaNo = 2) then
    Panel := FPaneller[2]
  else //if(ASayfaNo = 3) then
    Panel := FPaneller[3];

  Genislik := Length(ABaslik) * 8;

  // belirtilen etiket sayısı kadar panel nesnesine ekleme yapılabilir
  if(Panel.FDeger1 >= AZAMI_ETIKETSAYISI) then Exit;

  SiraNo := (ASayfaNo * 4) + Panel.FDeger1;
  FEtiketler[SiraNo] := TEtiket.Create;
  FEtiketler[SiraNo].Ozellestir(ktNesne, Panel, ASol, AUst, Genislik, 16, RENK_SIYAH, ABaslik);
  FEtiketler[SiraNo].Gorunum := True;

  i := Panel.FDeger1;
  Inc(i);
  Panel.FDeger1 := i;
end;

end.
