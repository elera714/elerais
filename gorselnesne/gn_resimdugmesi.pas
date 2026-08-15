{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_resimdugmesi.pas
  Dosya İşlevi: resim düğmesi yönetim işlevlerini içerir

  Güncelleme Tarihi: 15/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_resimdugmesi;

interface

uses gorev, gorselnesne, paylasim, gn_panel;

type
  PResimDugmesi = ^TResimDugmesi;
  TResimDugmesi = class(TPanel)
  private
    FDurum: TDugmeDurumu;
    // Deger: $00ABCDEF - ABCDEF renk değeri ile içeriği boya
    // Deger: $10ABCDEF - ABCDEF sıra numaralı çekirdekteki ham resmi çiz
    // Deger: $20ABCDEF - ABCDEF sıra numaralı çekirdekteki giysi ham resmini çiz
    // Deger: $80ABCDEF - ABCDEF sıra numaralı çekirdekteki bitmap resmi çiz
    FKenarlikCiz: Boolean;
  public
    constructor Create; override;
    destructor Destroy; override;
    function Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
      ASol, AUst, AGenislik, AYukseklik, AResimSiraNo: TSayi4; AKenarlikCiz: Boolean): TISayi4;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
  published
    property Deger: TSayi4 read FDeger1 write FDeger1;
  end;

function ResimDugmeCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function ResimDugmesiGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik,
  AResimSiraNo: TSayi4): TKimlik;

implementation

uses gn_pencere, gn_islevler, temelgorselnesne, src_ps2;

{==============================================================================
  resim düğmesi kesme çağrılarını yönetir
 ==============================================================================}
function ResimDugmeCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  Pencere: TPencere;
  ResimDugmesi: TResimDugmesi;
  Hiza: THiza;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := ResimDugmesiGNOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^, PISayi4(ADegiskenler + 20)^);
    end;

    ISLEV_GOSTER:
    begin

      ResimDugmesi := TResimDugmesi(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      ResimDugmesi.Goster;
    end;

    ISLEV_HIZALA:
    begin

      ResimDugmesi := TResimDugmesi(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      ResimDugmesi.FHiza := Hiza;

      Pencere := TPencere(ResimDugmesi.FAtaNesne);
      Pencere.Guncelle;
    end;
  end;
end;

{==============================================================================
  uygulama için resim düğmesi nesnesi oluşturur - api
 ==============================================================================}
function ResimDugmesiGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik,
  AResimSiraNo: TSayi4): TKimlik;
var
  ResimDugmesi: TResimDugmesi;
begin

  ResimDugmesi := TResimDugmesi.Create;

  if(ResimDugmesi = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    ResimDugmesi.Ozellestir(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik,
      AResimSiraNo, True);

    Result := ResimDugmesi.Kimlik;
  end;
end;

{==============================================================================
  resim düğmesi nesnesi oluşturur
 ==============================================================================}
constructor TResimDugmesi.Create;
begin

  inherited Create;

  NesneTipi := gntResimDugmesi;

  GGNesneler.GorselNesne[FSiraNo] := Self;
end;

{==============================================================================
  resim düğmesi nesnesini yok eder
 ==============================================================================}
destructor TResimDugmesi.Destroy;
begin

  GGNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  resim düğmesi nesnesini özelleştirir
 ==============================================================================}
function TResimDugmesi.Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
  ASol, AUst, AGenislik, AYukseklik, AResimSiraNo: TSayi4; AKenarlikCiz: Boolean): TISayi4;
begin

  Yapilandir2(AKullanimTipi, Self, AAtaNesne, ASol, AUst, AGenislik, AYukseklik,
    0, 0, 0, 0, '');

  OlayCagriAdr := @OlaylariIsle;

  Odaklanilabilir := False;
  Odaklanildi := False;

  Deger := AResimSiraNo;

  FDurum := ddNormal;

  FKenarlikCiz := AKenarlikCiz;

  // nesne bellek adresini geri döndür
  Result := HATA_YOK;
end;

{==============================================================================
  resim düğmesi nesnesini görüntüler
 ==============================================================================}
procedure TResimDugmesi.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  resim düğmesi nesnesini gizler
 ==============================================================================}
procedure TResimDugmesi.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  resim düğmesi nesnesini hizalandırır
 ==============================================================================}
procedure TResimDugmesi.Hizala;
begin

  { TODO - aşağıdaki satırın aktifleştirilmesi için nesnenin pencere kontrol düğmelerinin
    (büyütme, küçültme, kapatma) hesaplanması gerekiyor }
  //inherited Hizala;
end;

{==============================================================================
  resim düğmesi nesnesini çizer
 ==============================================================================}
procedure TResimDugmesi.Ciz;
var
  CizimAlani: TAlan;
  ResimSiraNo, CizimTipi: TSayi4;
begin

  CizimAlani := FCizimAlani;

  CizimTipi := Deger shr 24;

  // resim düğmesi içeriğinin ham resim ile çizilmesi
  if(CizimTipi = $10) then
  begin

    ResimSiraNo := Deger and $FFFFFF;

    KaynaktanResimCiz(Self, CizimAlani, ResimSiraNo);
  end
  // resim düğmesi içeriğinin çizilmesi - çekirdek içi çalışma için
  else if(CizimTipi = $30) then
  begin

    ResimSiraNo := Deger and $FFFFFF;

    KaynaktanResimCiz21(Self, CizimAlani.Sol, CizimAlani.Ust, ResimSiraNo);
  end
  // resim düğmesi içeriğinin bitmap resim ile çizilmesi
  else if(CizimTipi = $80) then
  begin

    ResimSiraNo := Deger and $FFFFFF;

    KaynaktanResimCiz2(Self, CizimAlani.Sol + 1, CizimAlani.Ust + 1, ResimSiraNo);
  end
  // resim düğmesi içeriğinin renk ile doldurulması
  else DikdortgenDoldur(Self, CizimAlani.Sol + 1, CizimAlani.Ust + 1,

    CizimAlani.Sag - 1, CizimAlani.Alt - 1, Deger, Deger);

  // kenarlık çizimi
  if(FKenarlikCiz) then
  begin

    if(FDurum = ddNormal) then
      Dikdortgen(Self, ctDuz, CizimAlani, RENK_GUMUS)
    else Dikdortgen(Self, ctDuz, CizimAlani, RENK_SIYAH);
  end;
end;

{==============================================================================
  resim düğmesi nesne olaylarını işler
 ==============================================================================}
procedure TResimDugmesi.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Pencere: TPencere;
  ResimDugmesi: TResimDugmesi;
begin

  ResimDugmesi := TResimDugmesi(AGonderici);
  if(ResimDugmesi = nil) then Exit;

  // farenin sol tuşuna basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // resim düğmesinin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := GGNesneler.EnUstPencereNesnesiniAl(ResimDugmesi);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GGNesneler.AktifPencere) then
      Pencere.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    // bilgi: şu aşamada bu nesne odaklanılabilir bir nesne değil
    //Pencere^.FAktifNesne := ResimDugmesi;
    //ResimDugmesi^.Odaklanildi := False;

    // sol tuşa basım işlemi nesnenin olay alanında mı gerçekleşti ?
    if(ResimDugmesi.FareNesneOlayAlanindaMi(ResimDugmesi)) then
    begin

      // fare olaylarını yakala
      GGNesneler.OlayYakalamayaBasla(ResimDugmesi);

      // resim düğmesinin durumunu BASILI olarak belirle
      ResimDugmesi.FDurum := ddBasili;

      // resim düğmesi nesnesini yeniden çiz
      ResimDugmesi.Ciz;

      // uygulamaya veya efendi nesneye mesaj gönder
      if not(ResimDugmesi.OlayYonlAdr = nil) then
        ResimDugmesi.OlayYonlAdr(ResimDugmesi, AOlay)
      else GGorevler.OlayEkle(ResimDugmesi.GrvKimlik, AOlay);
    end;
  end
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    GGNesneler.OlayYakalamayiBirak(ResimDugmesi);

    //  basılan resim düğmesini NORMAL olarak belirle
    ResimDugmesi.FDurum := ddNormal;

    // resim düğmesi nesnesini yeniden çiz
    ResimDugmesi.Ciz;

    // farenin tuş bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(ResimDugmesi.FareNesneOlayAlanindaMi(ResimDugmesi)) then
    begin

      // yakalama & bırakma işlemi bu nesnede olduğu için
      // uygulamaya veya efendi nesneye FO_TIKLAMA mesajı gönder
      AOlay.Olay := FO_TIKLAMA;
      if not(ResimDugmesi.OlayYonlAdr = nil) then
        ResimDugmesi.OlayYonlAdr(ResimDugmesi, AOlay)
      else GGorevler.OlayEkle(ResimDugmesi.GrvKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    if not(ResimDugmesi.OlayYonlAdr = nil) then
      ResimDugmesi.OlayYonlAdr(ResimDugmesi, AOlay)
    else GGorevler.OlayEkle(ResimDugmesi.GrvKimlik, AOlay);
  end
  else if(AOlay.Olay = FO_HAREKET) then
  begin

    // eğer nesne yakalanmış ve
    // 1 - fare göstergesi resim düğmesinin içerisindeyse
    // 2 - fare göstergesi resim düğmesinin dışarısındaysa
    // koşula göre resim düğmesinin durumunu yeniden çiz ...
    if(GGNesneler.YakalananGorselNesne <> nil) then
    begin

      if(ResimDugmesi.FareNesneOlayAlanindaMi(ResimDugmesi)) then
        ResimDugmesi.FDurum := ddBasili
      else ResimDugmesi.FDurum := ddNormal;
    end;

    // resim düğmesi nesnesini yeniden çiz
    ResimDugmesi.Ciz;

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(ResimDugmesi.OlayYonlAdr = nil) then
      ResimDugmesi.OlayYonlAdr(ResimDugmesi, AOlay)
    else GGorevler.OlayEkle(ResimDugmesi.GrvKimlik, AOlay);
  end;

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := ResimDugmesi.FareImlec;
end;

end.
