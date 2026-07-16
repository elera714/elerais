{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_dugme.pas
  Dosya İşlevi: düğme (TButton) yönetim işlevlerini içerir

  Güncelleme Tarihi: 16/07/2026

 ==============================================================================}
{$mode objfpc}
unit gn_dugme;

interface

uses gorselnesne, paylasim, gn_panel;

type
  PDugme = ^TDugme;
  TDugme = object(TPanel)
  private
    FDurum: TDugmeDurumu;
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4; ABaslik: string): PDugme;
    procedure YokEt(AKimlik: TKimlik);
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    procedure CizimModelDegistir(ADolguluCizim: Boolean; AGovdeRenk1, AGovdeRenk2,
      AYaziRenkNormal, AYaziRenkBasili: TRenk);
    // dolgulu çizim mi, normal çizim mi?
    property DolguluCizim: Boolean read FDurum1 write FDurum1;
    property YaziRenkNormal: TRenk read FDeger1 write FDeger1;
    property YaziRenkBasili: TRenk read FDeger2 write FDeger2;
  end;

function DugmeCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik;

implementation

uses gn_pencere, gn_islevler, temelgorselnesne, sistemmesaj, gorev;

{==============================================================================
  düğme kesme çağrılarını yönetir
 ==============================================================================}
function DugmeCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne = nil;
  Pencere: PPencere = nil;
  Dugme: PDugme = nil;
  Hiza: THiza;
  Konum: PKonum;
  Boyut: PBoyut;
begin

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^,
        PKarakterKatari(PSayi4(ADegiskenler + 20)^ + FAktifGorevBellekAdresi)^);
    end;

    ISLEV_GOSTER:
    begin

      Dugme := PDugme(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      Dugme^.Goster;
    end;

    ISLEV_GIZLE:
    begin

      Dugme := PDugme(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      Pencere := PPencere(Dugme^.AtaNesne);

      Dugme^.Gizle;
      Pencere^.Ciz;
    end;

    // yeniden boyutlandır
    ISLEV_BOYUTLANDIR:
    begin

      Dugme := PDugme(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Dugme <> nil) then
      begin

        Konum := PKonum(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
        Boyut := PBoyut(PSayi4(ADegiskenler + 08)^ + FAktifGorevBellekAdresi);
        Dugme^.FIlkAtananAlan.Sol := Konum^.Sol;
        Dugme^.FIlkAtananAlan.Ust := Konum^.Ust;
        Dugme^.FIlkAtananAlan.Genislik := Boyut^.Genislik;
        Dugme^.FIlkAtananAlan.Yukseklik := Boyut^.Yukseklik;

        Pencere := PPencere(Dugme^.AtaNesne);
        Pencere^.Ciz;
      end;
    end;

    ISLEV_YOKET:
    begin

      Dugme := PDugme(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      Pencere := PPencere(Dugme^.AtaNesne);

      GorselNesneler0.YokEt(Dugme^.Kimlik);
      Pencere^.Ciz;
    end;

    ISLEV_HIZALA:
    begin

      Dugme := PDugme(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      Dugme^.FHiza := Hiza;

      Pencere := PPencere(Dugme^.FAtaNesne);

      Pencere^.Guncelle;
    end;

    $010F:
    begin

      Dugme := PDugme(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      if not(Dugme = nil) then
        Dugme^.Baslik := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi)^;

      Dugme^.Ciz;
    end;

    // düğme nesnesine odaklan. (klavye girişlerini almasını sağla)
    $020F:
    begin

      Dugme := PDugme(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));

      if(Dugme <> nil) and (Dugme^.NesneTipi = gntDugme) then
      begin

        // bir önceki odak alan nesneyi odaktan çıkar
        GN := PPencere(Dugme^.AtaNesne)^.FAktifNesne;
        if(GN <> nil) and (GN^.Odaklanilabilir) then GN^.Odaklanildi := False;

        // nelirtilen nesneyi odaklanılan nesne olarak belirle
        PPencere(Dugme^.AtaNesne)^.FAktifNesne := Dugme;
        Dugme^.Odaklanildi := True;
      end;
    end;

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  düğme nesnesini oluşturur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik;
var
  Dugme: PDugme = nil;
begin

  Dugme := Dugme^.Olustur(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik, ABaslik);

  if(Dugme = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := Dugme^.Kimlik;
end;

{==============================================================================
  düğme nesnesini oluşturur
 ==============================================================================}
function TDugme.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4; ABaslik: string): PDugme;
var
  Dugme: PDugme = nil;
begin

  Dugme := PDugme(inherited Olustur(AKullanimTipi, AAtaNesne, ASol, AUst, AGenislik,
    AYukseklik, 4, DUGME_NORMAL_ILKRENK, DUGME_NORMAL_SONRENK, DUGME_NORMAL_YAZIRENK,
    ABaslik));

  // görsel nesne tipi
  Dugme^.NesneTipi := gntDugme;

  Dugme^.Baslik := ABaslik;

  Dugme^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  Dugme^.Odaklanilabilir := True;
  Dugme^.Odaklanildi := False;

  Dugme^.OlayCagriAdresi := @OlaylariIsle;

  Dugme^.FDurum := ddNormal;

  // çizim öndeğerleri
  Dugme^.DolguluCizim := True;
  Dugme^.FGovdeRenk1 := DUGME_NORMAL_ILKRENK;
  Dugme^.FGovdeRenk2 := DUGME_NORMAL_SONRENK;
  Dugme^.YaziRenkNormal := DUGME_NORMAL_YAZIRENK;
  Dugme^.YaziRenkBasili := DUGME_BASILI_YAZIRENK;

  // nesne adresini geri döndür
  Result := Dugme;
end;

{==============================================================================
  düğme nesnesini yok eder
 ==============================================================================}
procedure TDugme.YokEt(AKimlik: TKimlik);
begin

  inherited YokEt(AKimlik);
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
  düğme nesnesini boyutlandırır
 ==============================================================================}
procedure TDugme.Hizala;
var
  Dugme: PDugme = nil;
begin

  Dugme := PDugme(GorselNesneler0.NesneAl(Kimlik));
  if(Dugme = nil) then Exit;

  inherited Hizala;
end;

{==============================================================================
  düğme nesnesini çizer
 ==============================================================================}
procedure TDugme.Ciz;
var
  Dugme: PDugme = nil;
  CizimAlani: TAlan;
begin

  Dugme := PDugme(GorselNesneler0.NesneAl(Kimlik));
  if(Dugme = nil) then Exit;

  // düğme başlığı
  if(Dugme^.FDurum = ddNormal) then
    Dugme^.FYaziRenk := Dugme^.YaziRenkNormal
  else Dugme^.FYaziRenk := Dugme^.YaziRenkBasili;

  inherited Ciz;

  // nesne odaklanılmış ise nesnenin kenarlarını işaretle
  if(Dugme^.Odaklanildi) then
  begin

    CizimAlani := Dugme^.FCizimAlani;
    Dugme^.Dikdortgen(Dugme, ctNokta, CizimAlani, RENK_SIYAH);
  end;
end;

{==============================================================================
  düğme nesne olaylarını işler
 ==============================================================================}
procedure TDugme.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere = nil;
  Dugme: PDugme = nil;
begin

  Dugme := PDugme(AGonderici);
  if(Dugme = nil) then Exit;

  // farenin sol tuşuna basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // düğme'nin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(Dugme);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere^.FAktifNesne := Dugme;
    Dugme^.Odaklanildi := True;

    // sol tuşa basım işlemi nesnenin olay alanında mı gerçekleşti ?
    if(Dugme^.FareNesneOlayAlanindaMi(Dugme)) then
    begin

      // fare olaylarını yakala
      OlayYakalamayaBasla(Dugme);

      // düğme'nin durumunu BASILI olarak belirle
      Dugme^.FDurum := ddBasili;

      // düğme nesnesini yeniden çiz
      Dugme^.Ciz;

      // uygulamaya veya efendi nesneye mesaj gönder
      if not(Dugme^.OlayYonlendirmeAdresi = nil) then
        Dugme^.OlayYonlendirmeAdresi(Dugme, AOlay)
      else Gorevler0.OlayEkle(Dugme^.GorevKimlik, AOlay);
    end;
  end
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    OlayYakalamayiBirak(Dugme);

    //  basılan düğmeyi eski konumuna geri getir
    Dugme^.FDurum := ddNormal;

    // düğme nesnesini yeniden çiz
    Dugme^.Ciz;

    // farenin tuş bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(Dugme^.FareNesneOlayAlanindaMi(Dugme)) then
    begin

      // yakalama & bırakma işlemi bu nesnede olduğu için
      // uygulamaya veya efendi nesneye FO_TIKLAMA mesajı gönder
      AOlay.Olay := FO_TIKLAMA;
      if not(Dugme^.OlayYonlendirmeAdresi = nil) then
        Dugme^.OlayYonlendirmeAdresi(Dugme, AOlay)
      else Gorevler0.OlayEkle(Dugme^.GorevKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    if not(Dugme^.OlayYonlendirmeAdresi = nil) then
      Dugme^.OlayYonlendirmeAdresi(Dugme, AOlay)
    else Gorevler0.OlayEkle(Dugme^.GorevKimlik, AOlay);
  end
  else if(AOlay.Olay = FO_HAREKET) then
  begin

    // eğer nesne yakalanmış ve
    // 1 - fare göstergesi düğmenin içerisindeyse
    // 2 - fare göstergesi düğmenin dışarısındaysa
    // koşula göre düğmenin durumunu yeniden çiz ...
    if(YakalananGorselNesne <> nil) then
    begin

      if(Dugme^.FareNesneOlayAlanindaMi(Dugme)) then

        Dugme^.FDurum := ddBasili
      else Dugme^.FDurum := ddNormal;
    end;

    // düğme nesnesini yeniden çiz
    Dugme^.Ciz;

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(Dugme^.OlayYonlendirmeAdresi = nil) then
      Dugme^.OlayYonlendirmeAdresi(Dugme, AOlay)
    else Gorevler0.OlayEkle(Dugme^.GorevKimlik, AOlay);
  end
  // nesnenin odağı kaybetmesi durumu
  else if(AOlay.Olay = CO_ODAKKAYBEDILDI) then
  begin

    // düğme'nin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(Dugme);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere^.FAktifNesne := nil;
    Dugme^.Odaklanildi := False;

    // düğme'nin durumunu BASILI olarak belirle
    Dugme^.FDurum := ddNormal;

    // düğme nesnesini yeniden çiz
    Dugme^.Ciz;
  end
  // nesnenin odağı yeniden kazanması durumu
  else if(AOlay.Olay = CO_ODAKKAZANILDI) then
  begin

    // düğme'nin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(Dugme);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere^.FAktifNesne := Dugme;
    Dugme^.Odaklanildi := True;

    // düğme'nin durumunu BASILI olarak belirle
    Dugme^.FDurum := ddBasili;

    // düğme nesnesini yeniden çiz
    Dugme^.Ciz;
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := Dugme^.FareImlecTipi;
end;

{==============================================================================
  düğmenin çizim modelini değiştirir ve renk değerlerini belirler
 ==============================================================================}
procedure TDugme.CizimModelDegistir(ADolguluCizim: Boolean; AGovdeRenk1, AGovdeRenk2,
  AYaziRenkNormal, AYaziRenkBasili: TRenk);
var
  Dugme: PDugme = nil;
begin

  // kimlik değerinden nesneyi al
  Dugme := PDugme(GorselNesneler0.NesneAl(Kimlik));
  if(Dugme = nil) then Exit;

  Dugme^.DolguluCizim := ADolguluCizim;
  if(ADolguluCizim) then
    Dugme^.FCizimModel := 4
  else Dugme^.FCizimModel := 3;

  Dugme^.FGovdeRenk1 := AGovdeRenk1;
  Dugme^.FGovdeRenk2 := AGovdeRenk2;
  Dugme^.YaziRenkNormal := AYaziRenkNormal;
  Dugme^.YaziRenkBasili := AYaziRenkBasili;
end;

end.
