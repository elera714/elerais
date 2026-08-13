{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_dugme.pas
  Dosya İşlevi: düğme (TButton) yönetim işlevlerini içerir

  Güncelleme Tarihi: 11/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_dugme;

interface

uses gorselnesne, paylasim, gn_panel;

type
  PDugme = ^TDugme;
  TDugme = class(TPanel)
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
    // dolgulu çizim mi, normal çizim mi?
    property DolguluCizim: Boolean read FDurum1 write FDurum1;
    property YaziRenkNormal: TRenk read FDeger1 write FDeger1;
    property YaziRenkBasili: TRenk read FDeger2 write FDeger2;
  end;

function DugmeCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function DugmeGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik;

implementation

uses gn_pencere, gn_islevler, temelgorselnesne, sistemmesaj, gorev, src_ps2;

{==============================================================================
  düğme kesme çağrılarını yönetir
 ==============================================================================}
function DugmeCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  Pencere: TPencere;
  Dugme: TDugme;
  Hiza: THiza;
  Konum: PKonum;
  Boyut: PBoyut;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := DugmeGNOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^,
        PKarakterKatari(PSayi4(ADegiskenler + 20)^ + GGorevler.FAktifGrvBelAdr)^);
    end;

    ISLEV_GOSTER:
    begin

      Dugme := TDugme(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Dugme.Goster;
    end;

    ISLEV_GIZLE:
    begin

      Dugme := TDugme(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Pencere := TPencere(Dugme.AtaNesne);

      Dugme.Gizle;
      Pencere.Ciz;
    end;

    // yeniden boyutlandır
    ISLEV_BOYUTLANDIR:
    begin

      Dugme := TDugme(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Dugme <> nil) then
      begin

        Konum := PKonum(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr);
        Boyut := PBoyut(PSayi4(ADegiskenler + 08)^ + GGorevler.FAktifGrvBelAdr);
        Dugme.FIlkAtananAlan.Sol := Konum^.Sol;
        Dugme.FIlkAtananAlan.Ust := Konum^.Ust;
        Dugme.FIlkAtananAlan.Genislik := Boyut^.Genislik;
        Dugme.FIlkAtananAlan.Yukseklik := Boyut^.Yukseklik;

        Pencere := TPencere(Dugme.AtaNesne);
        Pencere.Ciz;
      end;
    end;

    ISLEV_YOKET:
    begin

      Dugme := TDugme(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Pencere := TPencere(Dugme.AtaNesne);

      Dugme.Destroy;
      Pencere.Ciz;
    end;

    ISLEV_HIZALA:
    begin

      Dugme := TDugme(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      Dugme.FHiza := Hiza;

      Pencere := TPencere(Dugme.FAtaNesne);

      Pencere.Guncelle;
    end;

    $010F:
    begin

      Dugme := TDugme(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      if not(Dugme = nil) then
        Dugme.Baslik := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr)^;

      Dugme.Ciz;
    end;

    // düğme nesnesine odaklan. (klavye girişlerini almasını sağla)
    $020F:
    begin

      Dugme := TDugme(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));

      if(Dugme <> nil) and (Dugme.NesneTipi = gntDugme) then
      begin

        // bir önceki odak alan nesneyi odaktan çıkar
        GN := TPencere(Dugme.AtaNesne).FAktifNesne;
        if(GN <> nil) and (GN.Odaklanilabilir) then GN.Odaklanildi := False;

        // nelirtilen nesneyi odaklanılan nesne olarak belirle
        TPencere(Dugme.AtaNesne).FAktifNesne := Dugme;
        Dugme.Odaklanildi := True;
      end;
    end;
  end;
end;

{==============================================================================
  uygulama için düğme nesnesi oluşturur - api
 ==============================================================================}
function DugmeGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik;
var
  Dugme: TDugme;
begin

  Dugme := TDugme.Create;

  if(Dugme = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    Dugme.Ozellestir(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik, ABaslik);

    Result := Dugme.Kimlik;
  end;
end;

{==============================================================================
  düğme nesnesi oluşturur
 ==============================================================================}
constructor TDugme.Create;
begin

  inherited Create;

  NesneTipi := gntDugme;

  GGNesneler.GorselNesne[FSiraNo] := Self;
end;

{==============================================================================
  düğme nesnesini yok eder
 ==============================================================================}
destructor TDugme.Destroy;
begin

  GGNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  düğme nesnesini özelleştirir
 ==============================================================================}
function TDugme.Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
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
  düğme nesnesini görüntüler
 ==============================================================================}
procedure TDugme.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  düğme nesnesini gizler
 ==============================================================================}
procedure TDugme.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  düğme nesnesini hizalandırır
 ==============================================================================}
procedure TDugme.Hizala;
begin

  inherited Hizala;
end;

{==============================================================================
  düğme nesnesini çizer
 ==============================================================================}
procedure TDugme.Ciz;
var
  CizimAlani: TAlan;
begin

  // düğme başlık rengi
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
  düğme nesne olaylarını işler
 ==============================================================================}
procedure TDugme.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Pencere: TPencere;
  Dugme: TDugme;
begin

  Dugme := TDugme(AGonderici);
  if(Dugme = nil) then Exit;

  // farenin sol tuşuna basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // düğme'nin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(Dugme);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere.FAktifNesne := Dugme;
    Dugme.Odaklanildi := True;

    // sol tuşa basım işlemi nesnenin olay alanında mı gerçekleşti ?
    if(Dugme.FareNesneOlayAlanindaMi(Dugme)) then
    begin

      // fare olaylarını yakala
      OlayYakalamayaBasla(Dugme);

      // düğme'nin durumunu BASILI olarak belirle
      Dugme.FDurum := ddBasili;

      // düğme nesnesini yeniden çiz
      Dugme.Ciz;

      // uygulamaya veya efendi nesneye mesaj gönder
      if not(Dugme.OlayYonlAdr = nil) then
        Dugme.OlayYonlAdr(Dugme, AOlay)
      else GGorevler.OlayEkle(Dugme.GrvKimlik, AOlay);
    end;
  end
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    OlayYakalamayiBirak(Dugme);

    //  basılan düğmeyi eski konumuna geri getir
    Dugme.FDurum := ddNormal;

    // düğme nesnesini yeniden çiz
    Dugme.Ciz;

    // farenin tuş bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(Dugme.FareNesneOlayAlanindaMi(Dugme)) then
    begin

      // yakalama & bırakma işlemi bu nesnede olduğu için
      // uygulamaya veya efendi nesneye FO_TIKLAMA mesajı gönder
      AOlay.Olay := FO_TIKLAMA;
      if not(Dugme.OlayYonlAdr = nil) then
        Dugme.OlayYonlAdr(Dugme, AOlay)
      else GGorevler.OlayEkle(Dugme.GrvKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    if not(Dugme.OlayYonlAdr = nil) then
      Dugme.OlayYonlAdr(Dugme, AOlay)
    else GGorevler.OlayEkle(Dugme.GrvKimlik, AOlay);
  end
  else if(AOlay.Olay = FO_HAREKET) then
  begin

    // eğer nesne yakalanmış ve
    // 1 - fare göstergesi düğmenin içerisindeyse
    // 2 - fare göstergesi düğmenin dışarısındaysa
    // koşula göre düğmenin durumunu yeniden çiz ...
    if(YakalananGorselNesne <> nil) then
    begin

      if(Dugme.FareNesneOlayAlanindaMi(Dugme)) then

        Dugme.FDurum := ddBasili
      else Dugme.FDurum := ddNormal;
    end;

    // düğme nesnesini yeniden çiz
    Dugme.Ciz;

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(Dugme.OlayYonlAdr = nil) then
      Dugme.OlayYonlAdr(Dugme, AOlay)
    else GGorevler.OlayEkle(Dugme.GrvKimlik, AOlay);
  end
  // nesnenin odağı kaybetmesi durumu
  else if(AOlay.Olay = CO_ODAKKAYBEDILDI) then
  begin

    // düğme'nin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(Dugme);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere.FAktifNesne := nil;
    Dugme.Odaklanildi := False;

    // düğme'nin durumunu NORMAL olarak belirle
    Dugme.FDurum := ddNormal;

    // düğme nesnesini yeniden çiz
    Dugme.Ciz;
  end
  // nesnenin odağı yeniden kazanması durumu
  else if(AOlay.Olay = CO_ODAKKAZANILDI) then
  begin

    // düğme'nin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(Dugme);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere.FAktifNesne := Dugme;
    Dugme.Odaklanildi := True;

    // düğme'nin durumunu BASILI olarak belirle
    Dugme.FDurum := ddBasili;

    // düğme nesnesini yeniden çiz
    Dugme.Ciz;
  end;

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := Dugme.FareImlec;
end;

{==============================================================================
  düğmenin çizim modelini değiştirir ve renk değerlerini belirler
 ==============================================================================}
procedure TDugme.CizimModelDegistir(ADolguluCizim: Boolean; AGovdeRenk1, AGovdeRenk2,
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

end.
