{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_acilirmenu.pas
  Dosya İşlevi: açılır menü (TPopupMenu) yönetim işlevlerini içerir

  Güncelleme Tarihi: 16/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_acilirmenu;

interface

uses gorselnesne, paylasim, n_yazilistesi, n_sayilistesi, gn_menu;

type
  PAcilirMenu = ^TAcilirMenu;
  TAcilirMenu = class(TMenu)
  public
    // nesne, karma liste gibi bir nesnenin yardımcı nesnesi mi?
    FYardimciNesne: Boolean;
    FAcilirMenuOlayGeriDonusAdresi: TOlaylariIsle;
    constructor Create; override;
    destructor Destroy; override;
    function Ozellestir(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik,
      AElemanYukseklik: TISayi4; AKenarlikRengi, AGovdeRengi, ASecimRengi, ANormalYaziRengi,
      ASeciliYaziRengi: TRenk): TISayi4;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Boyutlandir;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
    function MenuEkle(ADeger: string; AResimSiraNo: TISayi4 = -1;
      AMenuBoyutDegistir: Boolean = False): Boolean;
    procedure Temizle;
  end;

function AcilirMenuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function AcilirMenuGNOlustur(AKenarlikRengi, AGovdeRengi, ASecimRengi, ANormalYaziRengi,
  ASeciliYaziRengi: TRenk): TKimlik;

implementation

uses temelgorselnesne, gorev, src_ps2, gn_masaustu, gn_islevler;

{==============================================================================
  açılır menü kesme çağrılarını yönetir
 ==============================================================================}
function AcilirMenuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  AcilirMenu: TAcilirMenu;
  AElemanAdi: string;
  AResimSiraNo: TISayi4;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    // nesne oluştur
    ISLEV_OLUSTUR:

      Result := AcilirMenuGNOlustur(PISayi4(ADegiskenler + 00)^, PISayi4(ADegiskenler + 04)^,
        PISayi4(ADegiskenler + 08)^, PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^);

    // açılır menüyü görüntüle
    ISLEV_GOSTER:
    begin

      AcilirMenu := TAcilirMenu(GGNesneler.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^,
        gntAcilirMenu));
      if(AcilirMenu <> nil) then AcilirMenu.Goster;
    end;

    // açılır menüyü gizle
    ISLEV_GIZLE:
    begin

      AcilirMenu := TAcilirMenu(GGNesneler.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^,
        gntAcilirMenu));
      if(AcilirMenu <> nil) then AcilirMenu.Gizle;
    end;

    // eleman ekle
    $010F:
    begin

      AcilirMenu := TAcilirMenu(GGNesneler.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^,
        gntAcilirMenu));

      AElemanAdi := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr)^;
      AResimSiraNo := PISayi4(ADegiskenler + 08)^;

      if(AcilirMenu <> nil) then

        Result := TISayi4(AcilirMenu.MenuEkle(AElemanAdi, AResimSiraNo))
      else Result := 0;
    end;

    // seçilen elemanın sıra değerini al
    $020E:
    begin

      AcilirMenu := TAcilirMenu(GGNesneler.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^,
        gntAcilirMenu));
      if(AcilirMenu <> nil) then Result := AcilirMenu.SeciliSiraNo
    end;
  end;
end;

{==============================================================================
  uygulama için açılır menü nesnesi oluşturur - api
 ==============================================================================}
function AcilirMenuGNOlustur(AKenarlikRengi, AGovdeRengi, ASecimRengi, ANormalYaziRengi,
  ASeciliYaziRengi: TRenk): TKimlik;
var
  Masaustu: TMasaustu;
  AcilirMenu: TAcilirMenu;
begin

  AcilirMenu := TAcilirMenu.Create;

  if(AcilirMenu = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    Masaustu := GGNesneler.AktifMasaustu;

    AcilirMenu.Ozellestir(Masaustu, 0, 0, 300, (24 * 5) + 6, 24,
      AKenarlikRengi, AGovdeRengi, ASecimRengi, ANormalYaziRengi, ASeciliYaziRengi);

    Result := AcilirMenu.Kimlik;
  end;
end;

{==============================================================================
  açılır menü nesnesi oluşturur
 ==============================================================================}
constructor TAcilirMenu.Create;
begin

  inherited Create;

  { bilgi:
    1. nesne tipi Ozellestir işleviyle gerçekleşmekte
    2. görsel nesne listesine ekleme işlevi ana sınıf (TMenu) tarafından gerçekleşmekte }
end;

{==============================================================================
  açılır menü nesnesini yok eder
 ==============================================================================}
destructor TAcilirMenu.Destroy;
begin

  { bilgi: nesneyi görsel nesne listesinden çıkarma işlevi ana sınıf (TMenu)
    tarafından gerçekleşmekte }

  inherited Destroy;
end;

{==============================================================================
  açılır menü nesnesini özelleştirir
 ==============================================================================}
function TAcilirMenu.Ozellestir(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik,
  AElemanYukseklik: TISayi4; AKenarlikRengi, AGovdeRengi, ASecimRengi, ANormalYaziRengi,
  ASeciliYaziRengi: TRenk): TISayi4;
begin

  inherited Ozellestir(AAtaNesne, gntAcilirMenu, ASol, AUst,
    AGenislik, AYukseklik, AElemanYukseklik, AKenarlikRengi, AGovdeRengi);

  FMenuOlayGeriDonusAdresi := @OlaylariIsle;

  FAcilirMenuOlayGeriDonusAdresi := nil;

  FYardimciNesne := False;

  SecimRenk := ASecimRengi;
  NormalYaziRenk := ANormalYaziRengi;
  SeciliYaziRenk := ASeciliYaziRengi;

  // geri dönüş değeri
  Result := HATA_YOK;
end;

{==============================================================================
  açılır menü nesnesini görüntüler
 ==============================================================================}
procedure TAcilirMenu.Goster;
var
  Olay: TOlay;
begin

  inherited Goster;

  if(FYardimciNesne) then
  begin

  end
  else
  begin

    // menüyü farenin bulunduğu konumda görüntüle
    FAtananAlan.Sol := GFareSurucusu.YatayKonum;
    FAtananAlan.Ust := GFareSurucusu.DikeyKonum;
  end;

  // menünün açıldığına dair nesne sahibine mesaj gönder
  Olay.Kimlik := Kimlik;
  Olay.Olay := CO_MENUACILDI;
  Olay.Deger1 := 0;
  Olay.Deger2 := 0;
  if not(FMenuOlayGeriDonusAdresi = nil) then
    FMenuOlayGeriDonusAdresi(Self, Olay)
  else GGorevler.OlayEkle(GrvKimlik, Olay);
end;

{==============================================================================
  açılır menü nesnesini gizler
 ==============================================================================}
procedure TAcilirMenu.Gizle;
var
  Olay: TOlay;
begin

  inherited Gizle;

  // menünün açıldığına dair nesne sahibine mesaj gönder
  Olay.Kimlik := Kimlik;
  Olay.Olay := CO_MENUKAPATILDI;
  Olay.Deger1 := 0;
  Olay.Deger2 := 0;
  if not(FMenuOlayGeriDonusAdresi = nil) then
    FMenuOlayGeriDonusAdresi(Self, Olay)
  else GGorevler.OlayEkle(GrvKimlik, Olay);
end;

{==============================================================================
  açılır menü nesnesini hizalandırır
 ==============================================================================}
procedure TAcilirMenu.Hizala;
begin

  //inherited Hizala;
end;

{==============================================================================
  açılır menü nesnesini boyutlandırır
 ==============================================================================}
procedure TAcilirMenu.Boyutlandir;
begin

  inherited Boyutlandir;
end;

{==============================================================================
  açılır menü nesnesini çizer
 ==============================================================================}
procedure TAcilirMenu.Ciz;
begin

  inherited Ciz;
end;

{==============================================================================
  açılır menü nesne olaylarını işler
 ==============================================================================}
procedure TAcilirMenu.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  AcilirMenu: TAcilirMenu;
begin

  AcilirMenu := TAcilirMenu(AGonderici);
  if(AcilirMenu = nil) then Exit;

  if not(AcilirMenu.FAcilirMenuOlayGeriDonusAdresi = nil) then
    AcilirMenu.FAcilirMenuOlayGeriDonusAdresi(AcilirMenu, AOlay)
  else GGorevler.OlayEkle(AcilirMenu.GrvKimlik, AOlay);
end;

{==============================================================================
  açılır menü nesnesine eleman ekler
 ==============================================================================}
function TAcilirMenu.MenuEkle(ADeger: string; AResimSiraNo: TISayi4 = -1;
  AMenuBoyutDegistir: Boolean = False): Boolean;
var
  i: TISayi4;
begin

  FMenuBaslikListesi.Ekle(ADeger);

  // AResimSiraNo = -1 = menünün resmi yok
  if(AResimSiraNo > -1) then FMenuResimListesi.Ekle(AResimSiraNo);

  // menü genişliğini ve yüksekliğini değiştir
  if(AMenuBoyutDegistir) then
  begin

    // genişliğin yeniden belirlenmesi
    i := Length(ADeger) * 8;
    if(i > 100) then i := 100;
    if(i > FAtananAlan.Genislik) then FAtananAlan.Genislik := i;

    // yüksekliğin yeniden belirlenmesi. en fazla 5 eleman görüntülenebilir
    i := FMenuBaslikListesi.ElemanSayisi;
    if(i > 5) then i := 5;
    i := i * 24;
    if(i > FAtananAlan.Yukseklik) then FAtananAlan.Yukseklik := i;
  end;

  Boyutlandir;

  Result := Boolean(TISayi4(True));
end;

{==============================================================================
  açılır menü nesnesinin elemanlarını temizler
 ==============================================================================}
procedure TAcilirMenu.Temizle;
begin

  FMenuBaslikListesi.Temizle;
  FMenuResimListesi.Temizle;
end;

end.
