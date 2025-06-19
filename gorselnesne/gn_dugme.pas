{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: gn_dugme.pas
  Dosya Ýþlevi: düðme (TButton) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 26/02/2025

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
    FDolguluCizim: Boolean;         // dolgulu çizim mi, normal çizim mi?
    FYaziRenkNormal, FYaziRenkBasili: TRenk;
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4; ABaslik: string): PDugme;
    procedure YokEt;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    procedure CizimModelDegistir(ADolguluCizim: Boolean; AGovdeRenk1, AGovdeRenk2,
      AYaziRenkNormal, AYaziRenkBasili: TRenk);
  end;

function DugmeCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik;

implementation

uses genel, gn_pencere, gn_islevler, temelgorselnesne, giysi_mac, sistemmesaj, gorev;

{==============================================================================
  düðme kesme çaðrýlarýný yönetir
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

      GN := GN^.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^,
        PKarakterKatari(PSayi4(ADegiskenler + 20)^ + FAktifGorevBellekAdresi)^);
    end;

    ISLEV_GOSTER:
    begin

      Dugme := PDugme(Dugme^.NesneAl(PKimlik(ADegiskenler + 00)^));
      Dugme^.Goster;
    end;

    ISLEV_GIZLE:
    begin

      Dugme := PDugme(Dugme^.NesneAl(PKimlik(ADegiskenler + 00)^));
      Pencere := PPencere(Dugme^.AtaNesne);

      Dugme^.Gizle;
      Pencere^.Ciz;
    end;

    // yeniden boyutlandýr
    ISLEV_BOYUTLANDIR:
    begin

      Dugme := PDugme(Dugme^.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Dugme <> nil) then
      begin

        Konum := PKonum(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
        Boyut := PBoyut(PSayi4(ADegiskenler + 08)^ + FAktifGorevBellekAdresi);
        Dugme^.FIlkKonum.Sol := Konum^.Sol;
        Dugme^.FIlkKonum.Ust := Konum^.Ust;
        Dugme^.FIlkBoyut.Genislik := Boyut^.Genislik;
        Dugme^.FIlkBoyut.Yukseklik := Boyut^.Yukseklik;

        Pencere := PPencere(Dugme^.AtaNesne);
        Pencere^.Ciz;
      end;
    end;

    ISLEV_YOKET:
    begin

      Dugme := PDugme(Dugme^.NesneAl(PKimlik(ADegiskenler + 00)^));
      Pencere := PPencere(Dugme^.AtaNesne);

      Dugme^.YokEt;
      Pencere^.Ciz;
    end;

    ISLEV_HIZALA:
    begin

      Dugme := PDugme(Dugme^.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      Dugme^.FHiza := Hiza;

      Pencere := PPencere(Dugme^.FAtaNesne);

      Pencere^.Guncelle;
    end;

    $010F:
    begin

      Dugme := PDugme(Dugme^.NesneAl(PKimlik(ADegiskenler + 00)^));
      if not(Dugme = nil) then
        Dugme^.Baslik := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi)^;

      Dugme^.Ciz;
    end;

    // düðme nesnesine odaklan. (klavye giriþlerini almasýný saðla)
    $020F:
    begin

      Dugme := PDugme(Dugme^.NesneAl(PKimlik(ADegiskenler + 00)^));

      if(Dugme <> nil) and (Dugme^.NesneTipi = gntDugme) then
      begin

        // bir önceki odak alan nesneyi odaktan çýkar
        GN := PPencere(Dugme^.AtaNesne)^.FAktifNesne;
        if(GN <> nil) and (GN^.Odaklanilabilir) then GN^.Odaklanildi := False;

        // nelirtilen nesneyi odaklanýlan nesne olarak belirle
        PPencere(Dugme^.AtaNesne)^.FAktifNesne := Dugme;
        Dugme^.Odaklanildi := True;
      end;
    end;

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  düðme nesnesini oluþturur
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
  düðme nesnesini oluþturur
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

  // çizim öndeðerleri
  Dugme^.FDolguluCizim := True;
  Dugme^.FGovdeRenk1 := DUGME_NORMAL_ILKRENK;
  Dugme^.FGovdeRenk2 := DUGME_NORMAL_SONRENK;
  Dugme^.FYaziRenkNormal := DUGME_NORMAL_YAZIRENK;
  Dugme^.FYaziRenkBasili := DUGME_BASILI_YAZIRENK;

  // nesne adresini geri döndür
  Result := Dugme;
end;

{==============================================================================
  düðme nesnesini yok eder
 ==============================================================================}
procedure TDugme.YokEt;
begin

  inherited YokEt;
end;

{==============================================================================
  düðme nesnesini görüntüler
 ==============================================================================}
procedure TDugme.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  düðme nesnesini gizler
 ==============================================================================}
procedure TDugme.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  düðme nesnesini boyutlandýrýr
 ==============================================================================}
procedure TDugme.Hizala;
var
  Dugme: PDugme = nil;
begin

  Dugme := PDugme(Dugme^.NesneAl(Kimlik));
  if(Dugme = nil) then Exit;

  inherited Hizala;
end;

{==============================================================================
  düðme nesnesini çizer
 ==============================================================================}
procedure TDugme.Ciz;
var
  Dugme: PDugme = nil;
  CizimAlan: TAlan;
begin

  Dugme := PDugme(Dugme^.NesneAl(Kimlik));
  if(Dugme = nil) then Exit;

  // düðme baþlýðý
  if(Dugme^.FDurum = ddNormal) then
    Dugme^.FYaziRenk := FYaziRenkNormal
  else Dugme^.FYaziRenk := FYaziRenkBasili;

  inherited Ciz;

  // nesne odaklanýlmýþ ise nesnenin kenarlarýný iþaretle
  if(Dugme^.Odaklanildi) then
  begin

    CizimAlan := Dugme^.FCizimAlan;
    Dugme^.Dikdortgen(Dugme, ctNokta, CizimAlan, RENK_SIYAH);
  end;
end;

{==============================================================================
  düðme nesne olaylarýný iþler
 ==============================================================================}
procedure TDugme.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere = nil;
  Dugme: PDugme = nil;
begin

  Dugme := PDugme(AGonderici);
  if(Dugme = nil) then Exit;

  // farenin sol tuþuna basým iþlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // düðme'nin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(Dugme);

    // en üstte olmamasý durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak iþaretle
    Pencere^.FAktifNesne := Dugme;
    Dugme^.Odaklanildi := True;

    // sol tuþa basým iþlemi nesnenin olay alanýnda mý gerçekleþti ?
    if(Dugme^.FareNesneOlayAlanindaMi(Dugme)) then
    begin

      // fare olaylarýný yakala
      OlayYakalamayaBasla(Dugme);

      // düðme'nin durumunu BASILI olarak belirle
      Dugme^.FDurum := ddBasili;

      // düðme nesnesini yeniden çiz
      Dugme^.Ciz;

      // uygulamaya veya efendi nesneye mesaj gönder
      if not(Dugme^.OlayYonlendirmeAdresi = nil) then
        Dugme^.OlayYonlendirmeAdresi(Dugme, AOlay)
      else GorevListesi[Dugme^.GorevKimlik]^.OlayEkle(Dugme^.GorevKimlik, AOlay);
    end;
  end
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarýný almayý býrak
    OlayYakalamayiBirak(Dugme);

    //  basýlan düðmeyi eski konumuna geri getir
    Dugme^.FDurum := ddNormal;

    // düðme nesnesini yeniden çiz
    Dugme^.Ciz;

    // farenin tuþ býrakma iþlemi nesnenin olay alanýnda mý gerçekleþti ?
    if(Dugme^.FareNesneOlayAlanindaMi(Dugme)) then
    begin

      // yakalama & býrakma iþlemi bu nesnede olduðu için
      // uygulamaya veya efendi nesneye FO_TIKLAMA mesajý gönder
      AOlay.Olay := FO_TIKLAMA;
      if not(Dugme^.OlayYonlendirmeAdresi = nil) then
        Dugme^.OlayYonlendirmeAdresi(Dugme, AOlay)
      else GorevListesi[Dugme^.GorevKimlik]^.OlayEkle(Dugme^.GorevKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    if not(Dugme^.OlayYonlendirmeAdresi = nil) then
      Dugme^.OlayYonlendirmeAdresi(Dugme, AOlay)
    else GorevListesi[Dugme^.GorevKimlik]^.OlayEkle(Dugme^.GorevKimlik, AOlay);
  end
  else if(AOlay.Olay = FO_HAREKET) then
  begin

    // eðer nesne yakalanmýþ ve
    // 1 - fare göstergesi düðmenin içerisindeyse
    // 2 - fare göstergesi düðmenin dýþarýsýndaysa
    // koþula göre düðmenin durumunu yeniden çiz ...
    if(YakalananGorselNesne <> nil) then
    begin

      if(Dugme^.FareNesneOlayAlanindaMi(Dugme)) then

        Dugme^.FDurum := ddBasili
      else Dugme^.FDurum := ddNormal;
    end;

    // düðme nesnesini yeniden çiz
    Dugme^.Ciz;

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(Dugme^.OlayYonlendirmeAdresi = nil) then
      Dugme^.OlayYonlendirmeAdresi(Dugme, AOlay)
    else GorevListesi[Dugme^.GorevKimlik]^.OlayEkle(Dugme^.GorevKimlik, AOlay);
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := Dugme^.FFareImlecTipi;
end;

{==============================================================================
  düðmenin çizim modelini deðiþtirir ve renk deðerlerini belirler
 ==============================================================================}
procedure TDugme.CizimModelDegistir(ADolguluCizim: Boolean; AGovdeRenk1, AGovdeRenk2,
  AYaziRenkNormal, AYaziRenkBasili: TRenk);
var
  Dugme: PDugme = nil;
begin

  // kimlik deðerinden nesneyi al
  Dugme := PDugme(Dugme^.NesneAl(Kimlik));
  if(Dugme = nil) then Exit;

  Dugme^.FDolguluCizim := ADolguluCizim;
  if(ADolguluCizim) then
    Dugme^.FCizimModel := 4
  else Dugme^.FCizimModel := 3;

  Dugme^.FGovdeRenk1 := AGovdeRenk1;
  Dugme^.FGovdeRenk2 := AGovdeRenk2;
  Dugme^.FYaziRenkNormal := AYaziRenkNormal;
  Dugme^.FYaziRenkBasili := AYaziRenkBasili;
end;

end.
