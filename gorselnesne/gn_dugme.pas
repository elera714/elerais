{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: gn_dugme.pas
  Dosya ��levi: d��me (TButton) y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 20/06/2020

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
    FDolguluCizim: Boolean;         // dolgulu �izim mi, normal �izim mi?
    FYaziRenkNormal, FYaziRenkBasili: TRenk;
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4; ABaslik: string): PDugme;
    procedure YokEt;
    procedure Goster;
    procedure Gizle;
    procedure Boyutlandir;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    procedure CizimModelDegistir(ADolguluCizim: Boolean; AGovdeRenk1, AGovdeRenk2,
      AYaziRenkNormal, AYaziRenkBasili: TRenk);
  end;

function DugmeCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik;

implementation

uses genel, gn_pencere, gn_islevler, temelgorselnesne, giysi_mac;

{==============================================================================
  d��me kesme �a�r�lar�n� y�netir
 ==============================================================================}
function DugmeCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GorselNesne: PGorselNesne = nil;
  Pencere: PPencere = nil;
  Dugme: PDugme = nil;
  Hiza: THiza;
begin

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GorselNesne := GorselNesne^.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GorselNesne, PISayi4(ADegiskenler + 04)^,
        PISayi4(ADegiskenler + 08)^, PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^,
        PKarakterKatari(PSayi4(ADegiskenler + 20)^ + CalisanGorevBellekAdresi)^);
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
        Dugme^.Baslik := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi)^;

      Dugme^.Ciz;
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  d��me nesnesini olu�turur
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
  d��me nesnesini olu�turur
 ==============================================================================}
function TDugme.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4; ABaslik: string): PDugme;
var
  Dugme: PDugme = nil;
begin

  Dugme := PDugme(inherited Olustur(AKullanimTipi, AAtaNesne, ASol, AUst, AGenislik,
    AYukseklik, 4, DUGME_NORMAL_ILKRENK, DUGME_NORMAL_SONRENK, DUGME_NORMAL_YAZIRENK,
    ABaslik));

  // g�rsel nesne tipi
  Dugme^.NesneTipi := gntDugme;

  Dugme^.Baslik := ABaslik;

  Dugme^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  Dugme^.OlayCagriAdresi := @OlaylariIsle;

  Dugme^.FDurum := ddNormal;

  // �izim �nde�erleri
  Dugme^.FDolguluCizim := True;
  Dugme^.FGovdeRenk1 := DUGME_NORMAL_ILKRENK;
  Dugme^.FGovdeRenk2 := DUGME_NORMAL_SONRENK;
  Dugme^.FYaziRenkNormal := DUGME_NORMAL_YAZIRENK;
  Dugme^.FYaziRenkBasili := DUGME_BASILI_YAZIRENK;

  // nesne adresini geri d�nd�r
  Result := Dugme;
end;

{==============================================================================
  d��me nesnesini yok eder
 ==============================================================================}
procedure TDugme.YokEt;
begin

  inherited YokEt;
end;

{==============================================================================
  d��me nesnesini g�r�nt�ler
 ==============================================================================}
procedure TDugme.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  d��me nesnesini gizler
 ==============================================================================}
procedure TDugme.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  d��me nesnesini boyutland�r�r
 ==============================================================================}
procedure TDugme.Boyutlandir;
var
  Dugme: PDugme = nil;
begin

  Dugme := PDugme(Dugme^.NesneAl(Kimlik));
  if(Dugme = nil) then Exit;

  Dugme^.Hizala;
end;

{==============================================================================
  d��me nesnesini �izer
 ==============================================================================}
procedure TDugme.Ciz;
var
  Dugme: PDugme = nil;
begin

  Dugme := PDugme(Dugme^.NesneAl(Kimlik));
  if(Dugme = nil) then Exit;

  // d��me ba�l���
  if(Dugme^.FDurum = ddNormal) then
    Dugme^.FYaziRenk := FYaziRenkNormal
  else Dugme^.FYaziRenk := FYaziRenkBasili;

  inherited Ciz;
end;

{==============================================================================
  d��me nesne olaylar�n� i�ler
 ==============================================================================}
procedure TDugme.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere = nil;
  Dugme: PDugme = nil;
begin

  Dugme := PDugme(AGonderici);
  if(Dugme = nil) then Exit;

  // farenin sol tu�una bas�m i�lemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // d��me'nin sahibi olan pencere en �stte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(Dugme);

    // en �stte olmamas� durumunda en �ste getir
    if not(Pencere = nil) and (Pencere <> AktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // sol tu�a bas�m i�lemi nesnenin olay alan�nda m� ger�ekle�ti ?
    if(Dugme^.FareNesneOlayAlanindaMi(Dugme)) then
    begin

      // fare olaylar�n� yakala
      OlayYakalamayaBasla(Dugme);

      // d��me'nin durumunu BASILI olarak belirle
      Dugme^.FDurum := ddBasili;

      // d��me nesnesini yeniden �iz
      Dugme^.Ciz;

      // uygulamaya veya efendi nesneye mesaj g�nder
      if not(Dugme^.OlayYonlendirmeAdresi = nil) then
        Dugme^.OlayYonlendirmeAdresi(Dugme, AOlay)
      else GorevListesi[Dugme^.GorevKimlik]^.OlayEkle(Dugme^.GorevKimlik, AOlay);
    end;
  end
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylar�n� almay� b�rak
    OlayYakalamayiBirak(Dugme);

    //  bas�lan d��meyi eski konumuna geri getir
    Dugme^.FDurum := ddNormal;

    // d��me nesnesini yeniden �iz
    Dugme^.Ciz;

    // farenin tu� b�rakma i�lemi nesnenin olay alan�nda m� ger�ekle�ti ?
    if(Dugme^.FareNesneOlayAlanindaMi(Dugme)) then
    begin

      // yakalama & b�rakma i�lemi bu nesnede oldu�u i�in
      // uygulamaya veya efendi nesneye FO_TIKLAMA mesaj� g�nder
      AOlay.Olay := FO_TIKLAMA;
      if not(Dugme^.OlayYonlendirmeAdresi = nil) then
        Dugme^.OlayYonlendirmeAdresi(Dugme, AOlay)
      else GorevListesi[Dugme^.GorevKimlik]^.OlayEkle(Dugme^.GorevKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj g�nder
    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    if not(Dugme^.OlayYonlendirmeAdresi = nil) then
      Dugme^.OlayYonlendirmeAdresi(Dugme, AOlay)
    else GorevListesi[Dugme^.GorevKimlik]^.OlayEkle(Dugme^.GorevKimlik, AOlay);
  end
  else if(AOlay.Olay = FO_HAREKET) then
  begin

    // e�er nesne yakalanm�� ve
    // 1 - fare g�stergesi d��menin i�erisindeyse
    // 2 - fare g�stergesi d��menin d��ar�s�ndaysa
    // ko�ula g�re d��menin durumunu yeniden �iz ...
    if(YakalananGorselNesne <> nil) then
    begin

      if(Dugme^.FareNesneOlayAlanindaMi(Dugme)) then

        Dugme^.FDurum := ddBasili
      else Dugme^.FDurum := ddNormal;
    end;

    // d��me nesnesini yeniden �iz
    Dugme^.Ciz;

    // uygulamaya veya efendi nesneye mesaj g�nder
    if not(Dugme^.OlayYonlendirmeAdresi = nil) then
      Dugme^.OlayYonlendirmeAdresi(Dugme, AOlay)
    else GorevListesi[Dugme^.GorevKimlik]^.OlayEkle(Dugme^.GorevKimlik, AOlay);
  end;

  // ge�erli fare g�stergesini g�ncelle
  GecerliFareGostegeTipi := Dugme^.FFareImlecTipi;
end;

{==============================================================================
  d��menin �izim modelini de�i�tirir ve renk de�erlerini belirler
 ==============================================================================}
procedure TDugme.CizimModelDegistir(ADolguluCizim: Boolean; AGovdeRenk1, AGovdeRenk2,
  AYaziRenkNormal, AYaziRenkBasili: TRenk);
var
  Dugme: PDugme = nil;
begin

  // kimlik de�erinden nesneyi al
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
