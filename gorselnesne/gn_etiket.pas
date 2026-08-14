{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_etiket.pas
  Dosya İşlevi: etiket (TLabel) nesne yönetim işlevlerini içerir

  Güncelleme Tarihi: 14/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_etiket;

interface

uses gorselnesne, paylasim, gn_panel;

type
  PEtiket = ^TEtiket;
  TEtiket = class(TPanel)
  public
    constructor Create; override;
    destructor Destroy; override;
    function Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TSayi4; AYaziRenk: TRenk; ABaslik: string): TISayi4;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
  end;

function EtiketCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function EtiketGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TSayi4;
  AYaziRenk: TRenk; ABaslik: string): TKimlik;

implementation

uses gn_pencere, gn_islevler, temelgorselnesne, gorev, src_ps2;

{==============================================================================
  etiket nesne kesme çağrılarını yönetir
 ==============================================================================}
function EtiketCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  Pencere: TPencere;
  Etiket: TEtiket;
  p: PKarakterKatari;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := EtiketGNOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^, PRenk(ADegiskenler + 20)^,
        PKarakterKatari(PSayi4(ADegiskenler + 24)^ + GGorevler.FAktifGrvBelAdr)^);
    end;

    ISLEV_GOSTER:
    begin

      Etiket := TEtiket(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Etiket.Goster;
    end;

    // etiket başlığını değiştir
    $010F:
    begin

      Etiket := TEtiket(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      p := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr);
      Etiket.Baslik := p^;

      // etiketin bağlı olduğu pencere nesnesini güncelle
      Pencere := GGNesneler.EnUstPencereNesnesiniAl(Etiket);
      if not(Pencere = nil) then Pencere.Guncelle;
    end;

    // etiket rengini değiştir
    $020F:
    begin

      Etiket := TEtiket(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Etiket.FYaziRenk := PRenk(ADegiskenler + 04)^;

      // etiketin bağlı olduğu pencere nesnesini güncelle
      Pencere := GGNesneler.EnUstPencereNesnesiniAl(Etiket);
      if not(Pencere = nil) then Pencere.Guncelle;
    end;
  end;
end;

{==============================================================================
  uygulama için etiket nesnesi oluşturur - api
 ==============================================================================}
function EtiketGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TSayi4;
  AYaziRenk: TRenk; ABaslik: string): TKimlik;
var
  Etiket: TEtiket;
begin

  Etiket := TEtiket.Create;

  if(Etiket = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    Etiket.Ozellestir(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik, AYaziRenk, ABaslik);

    Result := Etiket.Kimlik;
  end;
end;

{==============================================================================
  etiket nesnesi oluşturur
 ==============================================================================}
constructor TEtiket.Create;
begin

  inherited Create;

  NesneTipi := gntEtiket;

  GGNesneler.GorselNesne[FSiraNo] := Self;
end;

{==============================================================================
  etiket nesnesini yok eder
 ==============================================================================}
destructor TEtiket.Destroy;
begin

  GGNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  etiket nesnesini özelleştirir
 ==============================================================================}
function TEtiket.Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TSayi4; AYaziRenk: TRenk; ABaslik: string): TISayi4;
begin

  Yapilandir2(AKullanimTipi, Self, AAtaNesne, ASol, AUst, AGenislik, AYukseklik,
    1, RENK_BEYAZ, RENK_BEYAZ, AYaziRenk, ABaslik);

  OlayCagriAdr := @OlaylariIsle;

  Baslik := ABaslik;

  Odaklanilabilir := False;
  Odaklanildi := False;

  // FCizimModel = arka plan boyama yok, yazı var
  FCizimModel := 1;

  FYaziHiza.Yatay := yhSol;
  FYaziHiza.Dikey := dhUst;

  // geri dönüş değeri
  Result := HATA_YOK;
end;

{==============================================================================
  etiket nesnesini görüntüler
 ==============================================================================}
procedure TEtiket.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  etiket nesnesini gizler
 ==============================================================================}
procedure TEtiket.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  etiket nesnesini hizalandırır
 ==============================================================================}
procedure TEtiket.Hizala;
begin

  inherited Hizala;
end;

{==============================================================================
  etiket nesnesini çizer
 ==============================================================================}
procedure TEtiket.Ciz;
begin

  inherited Ciz;
end;

{==============================================================================
  etiket nesne olaylarını işler
 ==============================================================================}
procedure TEtiket.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Pencere: TPencere;
  Etiket: TEtiket;
begin

  Etiket := TEtiket(AGonderici);

  // farenin sol tuşuna basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // etiketin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := GGNesneler.EnUstPencereNesnesiniAl(Etiket);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere.EnUsteGetir(Pencere);

    // fare olaylarını yakala
    GGNesneler.OlayYakalamayaBasla(Etiket);

    // etiket nesnesini yeniden çiz
    Etiket.Ciz;

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(Etiket.OlayYonlAdr = nil) then
      Etiket.OlayYonlAdr(Etiket, AOlay)
    else GGorevler.OlayEkle(Etiket.GrvKimlik, AOlay);
  end
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    GGNesneler.OlayYakalamayiBirak(Etiket);

    // etiket nesnesini yeniden çiz
    Etiket.Ciz;

    // farenin tuş bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(Etiket.FareNesneOlayAlanindaMi(Etiket)) then
    begin

      // yakalama & bırakma işlemi bu nesnede olduğu için
      // uygulamaya veya efendi nesneye FO_TIKLAMA mesajı gönder
      AOlay.Olay := FO_TIKLAMA;
      if not(Etiket.OlayYonlAdr = nil) then
        Etiket.OlayYonlAdr(Etiket, AOlay)
      else GGorevler.OlayEkle(Etiket.GrvKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    if not(Etiket.OlayYonlAdr = nil) then
      Etiket.OlayYonlAdr(Etiket, AOlay)
    else GGorevler.OlayEkle(Etiket.GrvKimlik, AOlay);
  end
  else if(AOlay.Olay = FO_HAREKET) then
  begin

    // etiket nesnesini yeniden çiz
    Etiket.Ciz;

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(Etiket.OlayYonlAdr = nil) then
      Etiket.OlayYonlAdr(Etiket, AOlay)
    else GGorevler.OlayEkle(Etiket.GrvKimlik, AOlay);
  end;

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := Etiket.FareImlec;
end;

end.
