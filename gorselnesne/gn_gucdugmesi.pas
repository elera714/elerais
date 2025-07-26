{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_gucdugmesi.pas
  Dosya İşlevi: güç düğmesi yönetim işlevlerini içerir

  Güncelleme Tarihi: 26/02/2025

 ==============================================================================}
{$mode objfpc}
unit gn_gucdugmesi;

interface

uses gorselnesne, paylasim, gn_panel;

type
  PGucDugmesi = ^TGucDugmesi;
  TGucDugmesi = object(TPanel)
  private
    FDurum: TDugmeDurumu;
    FDolguluCizim: Boolean;         // dolgulu çizim mi, normal çizim mi?
    FYaziRenkNormal, FYaziRenkBasili: TRenk;
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4; ABaslik: string): PGucDugmesi;
    procedure YokEt(AKimlik: TKimlik);
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    procedure CizimModelDegistir(ADolguluCizim: Boolean; AGovdeRenk1, AGovdeRenk2,
      AYaziRenkNormal, AYaziRenkBasili: TRenk);
    procedure DurumYaz(AKimlik: TKimlik; ADurum: TSayi4);
  end;

function GucDugmeCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik;

implementation

uses genel, gn_islevler, temelgorselnesne, giysi_mac, gn_pencere, sistemmesaj, gorev;

{==============================================================================
  güç düğme kesme çağrılarını yönetir
 ==============================================================================}
function GucDugmeCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne;
  Pencere: PPencere;
  GucDugmesi: PGucDugmesi;
  Konum: PKonum;
  Boyut: PBoyut;
begin

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GN, PISayi4(ADegiskenler + 04)^,
        PISayi4(ADegiskenler + 08)^, PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^,
        PKarakterKatari(PSayi4(ADegiskenler + 20)^ + FAktifGorevBellekAdresi)^);
    end;

    ISLEV_GOSTER:
    begin

      GucDugmesi := PGucDugmesi(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      GucDugmesi^.Goster;
    end;

    ISLEV_GIZLE:
    begin

      GucDugmesi := PGucDugmesi(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      GucDugmesi^.Gizle;
    end;

    // yeniden boyutlandır
    ISLEV_BOYUTLANDIR:
    begin

      GucDugmesi := PGucDugmesi(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(GucDugmesi <> nil) then
      begin

        Konum := PKonum(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
        Boyut := PBoyut(PSayi4(ADegiskenler + 08)^ + FAktifGorevBellekAdresi);
        GucDugmesi^.FIlkKonum.Sol := Konum^.Sol;
        GucDugmesi^.FIlkKonum.Ust := Konum^.Ust;
        GucDugmesi^.FIlkBoyut.Genislik := Boyut^.Genislik;
        GucDugmesi^.FIlkBoyut.Yukseklik := Boyut^.Yukseklik;

        Pencere := PPencere(GucDugmesi^.AtaNesne);
        Pencere^.Ciz;
      end;
    end;

    ISLEV_YOKET:
    begin

      GucDugmesi := PGucDugmesi(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      GucDugmesi^.YokEt(GucDugmesi^.Kimlik);
    end;

    $010F:
    begin

      GucDugmesi := PGucDugmesi(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      if not(GucDugmesi = nil) then
      begin

        GucDugmesi^.Baslik := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi)^;
      end;
    end;

    // güç düğme durumunu değiştir
    $020F:
    begin

      GucDugmesi := PGucDugmesi(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(GucDugmesi <> nil) then
        GucDugmesi^.DurumYaz(PKimlik(ADegiskenler + 00)^, PISayi4(ADegiskenler + 04)^);
    end;

    // güç düğmesi nesnesine odaklan. (klavye girişlerini almasını sağla)
    $030F:
    begin

      GucDugmesi := PGucDugmesi(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));

      if(GucDugmesi <> nil) and (GucDugmesi^.NesneTipi = gntGucDugmesi) then
      begin

        // bir önceki odak alan nesneyi odaktan çıkar
        GN := PPencere(GucDugmesi^.AtaNesne)^.FAktifNesne;
        if(GN <> nil) and (GN^.Odaklanilabilir) then GN^.Odaklanildi := False;

        // nelirtilen nesneyi odaklanılan nesne olarak belirle
        PPencere(GucDugmesi^.AtaNesne)^.FAktifNesne := GucDugmesi;
        GucDugmesi^.Odaklanildi := True;
      end;
    end;

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  güç düğme nesnesini oluşturur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik;
var
  GucDugmesi: PGucDugmesi;
begin

  GucDugmesi := GucDugmesi^.Olustur(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik, ABaslik);

  if(GucDugmesi = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := GucDugmesi^.Kimlik;
end;

{==============================================================================
  güç düğme nesnesini oluşturur
 ==============================================================================}
function TGucDugmesi.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4; ABaslik: string): PGucDugmesi;
var
  GucDugmesi: PGucDugmesi;
begin

  GucDugmesi := PGucDugmesi(inherited Olustur(AKullanimTipi, AAtaNesne, ASol, AUst, AGenislik,
    AYukseklik, 4, DUGME_NORMAL_ILKRENK, DUGME_NORMAL_SONRENK, DUGME_NORMAL_YAZIRENK, ABaslik));

  // görsel nesne tipi
  GucDugmesi^.NesneTipi := gntGucDugmesi;

  GucDugmesi^.Baslik := ABaslik;

  GucDugmesi^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  GucDugmesi^.Odaklanilabilir := True;
  GucDugmesi^.Odaklanildi := False;

  GucDugmesi^.OlayCagriAdresi := @OlaylariIsle;

  GucDugmesi^.FDurum := ddNormal;

  // çizim öndeğerleri
  GucDugmesi^.FDolguluCizim := True;
  GucDugmesi^.FGovdeRenk1 := DUGME_NORMAL_ILKRENK;
  GucDugmesi^.FGovdeRenk2 := DUGME_NORMAL_SONRENK;
  GucDugmesi^.FYaziRenkNormal := DUGME_NORMAL_YAZIRENK;
  GucDugmesi^.FYaziRenkBasili := DUGME_BASILI_YAZIRENK;

  // nesne adresini geri döndür
  Result := GucDugmesi;
end;

{==============================================================================
  güç düğme nesnesini yok eder
 ==============================================================================}
procedure TGucDugmesi.YokEt(AKimlik: TKimlik);
begin

  GorselNesneler0.YokEt(AKimlik);
end;

{==============================================================================
  güç düğme nesnesini görüntüler
 ==============================================================================}
procedure TGucDugmesi.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  güç düğme nesnesini gizler
 ==============================================================================}
procedure TGucDugmesi.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  güç düğme nesnesini hizalandırır
 ==============================================================================}
procedure TGucDugmesi.Hizala;
var
  GucDugmesi: PGucDugmesi;
begin

  GucDugmesi := PGucDugmesi(GorselNesneler0.NesneAl(Kimlik));
  if(GucDugmesi = nil) then Exit;

  inherited Hizala;
end;

{==============================================================================
  güç düğme nesnesini çizer
 ==============================================================================}
procedure TGucDugmesi.Ciz;
var
  GucDugmesi: PGucDugmesi;
  CizimAlan: TAlan;
begin

  GucDugmesi := PGucDugmesi(GorselNesneler0.NesneAl(Kimlik));
  if(GucDugmesi= nil) then Exit;

  // düğme başlığı
  if(GucDugmesi^.FDurum = ddNormal) then
    GucDugmesi^.FYaziRenk := FYaziRenkNormal
  else GucDugmesi^.FYaziRenk := FYaziRenkBasili;

  inherited Ciz;

  // nesne odaklanılmış ise nesnenin kenarlarını işaretle
  if(GucDugmesi^.Odaklanildi) then
  begin

    CizimAlan := GucDugmesi^.FCizimAlan;
    GucDugmesi^.Dikdortgen(GucDugmesi, ctNokta, CizimAlan, RENK_SIYAH);
  end;
end;

{==============================================================================
  güç düğme nesne olaylarını işler
 ==============================================================================}
procedure TGucDugmesi.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere;
  GucDugmesi: PGucDugmesi;
  i: TISayi4;
begin

  GucDugmesi := PGucDugmesi(AGonderici);

  // farenin sol tuşuna basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // güç düğmesinin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(GucDugmesi);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere^.FAktifNesne := GucDugmesi;
    GucDugmesi^.Odaklanildi := True;

    // fare olaylarını yakala
    OlayYakalamayaBasla(GucDugmesi);

    // güç düğmesinin durumunu NORMAL / BASILI olarak değiştir
    if(GucDugmesi^.FDurum = ddBasili) then
    begin

      i := 0;
      GucDugmesi^.FDurum := ddNormal;
    end
    else
    begin

      i := 1;
      GucDugmesi^.FDurum := ddBasili;
    end;

    // güç düğme nesnesini yeniden çiz
    GucDugmesi^.Ciz;

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := CO_DURUMDEGISTI;
    AOlay.Deger1 := i;
    if not(GucDugmesi^.OlayYonlendirmeAdresi = nil) then
      GucDugmesi^.OlayYonlendirmeAdresi(GucDugmesi, AOlay)
    else Gorevler0.OlayEkle(GucDugmesi^.GorevKimlik, AOlay);
  end
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    OlayYakalamayiBirak(GucDugmesi);
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := GucDugmesi^.FareImlecTipi;
end;

{==============================================================================
  güç düğmesinin çizim modelini değiştirir ve renk değerlerini belirler
 ==============================================================================}
procedure TGucDugmesi.CizimModelDegistir(ADolguluCizim: Boolean; AGovdeRenk1, AGovdeRenk2,
  AYaziRenkNormal, AYaziRenkBasili: TRenk);
var
  GucDugmesi: PGucDugmesi;
begin

  // kimlik değerinden nesneyi al
  GucDugmesi := PGucDugmesi(GorselNesneler0.NesneAl(Kimlik));
  if(GucDugmesi = nil) then Exit;

  GucDugmesi^.FDolguluCizim := ADolguluCizim;
  if(ADolguluCizim) then
    GucDugmesi^.FCizimModel := 4
  else GucDugmesi^.FCizimModel := 3;

  GucDugmesi^.FGovdeRenk1 := AGovdeRenk1;
  GucDugmesi^.FGovdeRenk2 := AGovdeRenk2;
  GucDugmesi^.FYaziRenkNormal := AYaziRenkNormal;
  GucDugmesi^.FYaziRenkBasili := AYaziRenkBasili;
end;

{==============================================================================
  güç düğme nesnesinin durumunu değiştirir
 ==============================================================================}
procedure TGucDugmesi.DurumYaz(AKimlik: TKimlik; ADurum: TSayi4);
var
  GucDugmesi: PGucDugmesi;
begin

  // kimlik değerinden nesneyi al
  GucDugmesi := PGucDugmesi(GorselNesneler0.NesneAl(AKimlik));
  if(GucDugmesi = nil) then Exit;

  if(ADurum = 1) then
    GucDugmesi^.FDurum := ddBasili
  else GucDugmesi^.FDurum := ddNormal;

  GucDugmesi^.Ciz;
end;

end.
