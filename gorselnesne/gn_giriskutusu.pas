{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: gn_giriskutusu.pas
  Dosya Ýþlevi: giriþ kutusu (TEdit) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 26/02/2025

 ==============================================================================}
{$mode objfpc}
unit gn_giriskutusu;

interface

uses gorselnesne, paylasim, gn_panel, gn_dugme;

type
  PGirisKutusu = ^TGirisKutusu;
  TGirisKutusu = object(TPanel)
  private
    FSilmeDugmesi: PDugme;
    procedure SilmeDugmeOlaylariniIsle(AGonderici: PGorselNesne; AOlay: TOlay);
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4; ABaslik: string): PGirisKutusu;
    procedure YokEt(AKimlik: TKimlik);
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    property Yazilamaz: Boolean read FDurum1 write FDurum1;
    property SadeceRakam: Boolean read FDurum2 write FDurum2;
  end;

function GirisKutusuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik;

implementation

uses gn_islevler, gn_pencere, genel, temelgorselnesne, gorev, sistemmesaj;

{==============================================================================
  giriþ kutusu kesme çaðrýlarýný yönetir
 ==============================================================================}
function GirisKutusuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne;
  GirisKutusu: PGirisKutusu;
  p1: PKarakterKatari;
  p2: PLongBool;
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

      GirisKutusu := PGirisKutusu(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      GirisKutusu^.Goster;
    end;

    // giriþ kutusundaki veriyi al
    $010E:
    begin

      GirisKutusu := PGirisKutusu(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      p1 := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
      p1^ := GirisKutusu^.Baslik;
    end;

    // giriþ kutusundaki veriyi deðiþtir
    $010F:
    begin

      GirisKutusu := PGirisKutusu(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      p1 := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
      GirisKutusu^.Baslik := p1^;
      GirisKutusu^.Ciz;
    end;

    // giriþ kutusunun salt okunur özelliðini deðiþtir
    $020F:
    begin

      GirisKutusu := PGirisKutusu(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      p2 := PLongBool(ADegiskenler + 04);
      GirisKutusu^.Yazilamaz := p2^;
      GirisKutusu^.Ciz;
    end;

    // giriþ kutusunun sayýsal (numeric) deðer özelliðini deðiþtir
    $030F:
    begin

      GirisKutusu := PGirisKutusu(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      p2 := PLongBool(ADegiskenler + 04);
      GirisKutusu^.SadeceRakam := p2^;
    end;

    // giriþ kutusuna odaklan. (klavye giriþlerini almasýný saðla)
    $040F:
    begin

      GirisKutusu := PGirisKutusu(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));

      if(GirisKutusu <> nil) and (GirisKutusu^.NesneTipi = gntGirisKutusu) then
      begin

        // bir önceki odak alan nesneyi odaktan çýkar
        GN := PPencere(GirisKutusu^.AtaNesne)^.FAktifNesne;
        if(GN <> nil) and (GN^.Odaklanilabilir) then GN^.Odaklanildi := False;

        // nelirtilen nesneyi odaklanýlan nesne olarak belirle
        PPencere(GirisKutusu^.AtaNesne)^.FAktifNesne := GirisKutusu;
        GirisKutusu^.Odaklanildi := True;
      end;
    end;

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  giriþ kutusu nesnesini oluþturur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik;
var
  GirisKutusu: PGirisKutusu;
begin

  GirisKutusu := GirisKutusu^.Olustur(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik, ABaslik);

  if(GirisKutusu = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := GirisKutusu^.Kimlik;
end;

{==============================================================================
  giriþ kutusu nesnesini oluþturur
 ==============================================================================}
function TGirisKutusu.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4; ABaslik: string): PGirisKutusu;
var
  GirisKutusu: PGirisKutusu;
begin

  AYukseklik := 20;

  GirisKutusu := PGirisKutusu(inherited Olustur(AKullanimTipi, AAtaNesne, ASol, AUst,
    AGenislik, AYukseklik, 2, RENK_GUMUS, RENK_BEYAZ, RENK_SIYAH, ABaslik));

  // görsel nesne tipi
  GirisKutusu^.NesneTipi := gntGirisKutusu;

  GirisKutusu^.Baslik := ABaslik;

  GirisKutusu^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  GirisKutusu^.Odaklanilabilir := True;
  GirisKutusu^.Odaklanildi := False;

  GirisKutusu^.OlayCagriAdresi := @OlaylariIsle;

  GirisKutusu^.FareImlecTipi := fitGiris;

  GirisKutusu^.Yazilamaz := False;
  GirisKutusu^.SadeceRakam := False;

  GirisKutusu^.FSilmeDugmesi := GirisKutusu^.FSilmeDugmesi^.Olustur(ktBilesen, GirisKutusu,
    AGenislik - 12, 2, 10, 16, 'X');
  GirisKutusu^.FSilmeDugmesi^.CizimModelDegistir(False, RENK_BEYAZ, RENK_BEYAZ, RENK_SIYAH, RENK_KIRMIZI);
  GirisKutusu^.FSilmeDugmesi^.OlayYonlendirmeAdresi := @SilmeDugmeOlaylariniIsle;

  // nesne bellek adresini geri döndür
  Result := GirisKutusu;
end;

{==============================================================================
  giriþ kutusu nesnesini yok eder
 ==============================================================================}
procedure TGirisKutusu.YokEt(AKimlik: TKimlik);
var
  GirisKutusu: PGirisKutusu;
begin

  GirisKutusu := PGirisKutusu(GorselNesneler0.NesneAl(AKimlik));
  if(GirisKutusu = nil) then Exit;

  GirisKutusu^.FSilmeDugmesi^.YokEt(GirisKutusu^.FSilmeDugmesi^.Kimlik);

  inherited YokEt(AKimlik);
end;

{==============================================================================
  giriþ kutusu nesnesini görüntüler
 ==============================================================================}
procedure TGirisKutusu.Goster;
var
  GirisKutusu: PGirisKutusu;
begin

  GirisKutusu := PGirisKutusu(GorselNesneler0.NesneAl(Kimlik));
  if(GirisKutusu = nil) then Exit;

  GirisKutusu^.FSilmeDugmesi^.Gorunum := True;

  inherited Goster;
end;

{==============================================================================
  giriþ kutusu nesnesini gizler
 ==============================================================================}
procedure TGirisKutusu.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  giriþ kutusu nesnesini hizalandýrýr
 ==============================================================================}
procedure TGirisKutusu.Hizala;
var
  GirisKutusu: PGirisKutusu;
begin

  GirisKutusu := PGirisKutusu(GorselNesneler0.NesneAl(Kimlik));
  if(GirisKutusu = nil) then Exit;

  GirisKutusu^.FSilmeDugmesi^.FAtananAlan.Sol := GirisKutusu^.FAtananAlan.Genislik - 13;
  GirisKutusu^.FSilmeDugmesi^.FAtananAlan.Ust := 3;
  GirisKutusu^.FSilmeDugmesi^.FAtananAlan.Genislik := 10;
  GirisKutusu^.FSilmeDugmesi^.FAtananAlan.Yukseklik := 16;
  GirisKutusu^.FSilmeDugmesi^.BoyutlariYenidenHesapla;

  inherited Hizala;
end;

{==============================================================================
  giriþ kutusu nesnesini çizer
 ==============================================================================}
procedure TGirisKutusu.Ciz;
var
  GirisKutusu: PGirisKutusu;
  CizimAlani: TAlan;
begin

  GirisKutusu := PGirisKutusu(GorselNesneler0.NesneAl(Kimlik));
  if(GirisKutusu = nil) then Exit;

  inherited Ciz;

  // giriþ kutusunun çizim alan koordinatlarýný al
  CizimAlani := GirisKutusu^.FCizimAlani;

  // nesnenin içerik deðeri.
  if(GirisKutusu^.Yazilamaz) then

    GirisKutusu^.YaziYaz(GirisKutusu, CizimAlani.Sol + 2, CizimAlani.Ust + 3, GirisKutusu^.Baslik, RENK_SIYAH)
  else
  begin

    // nesne odak kazanmýþsa sonuna #255 = klavye kursörü ekle
    if(GirisKutusu^.Odaklanildi) then
      GirisKutusu^.YaziYaz(GirisKutusu, CizimAlani.Sol + 2, CizimAlani.Ust + 3,
        GirisKutusu^.Baslik + #255, RENK_SIYAH)
    else GirisKutusu^.YaziYaz(GirisKutusu, CizimAlani.Sol + 2, CizimAlani.Ust + 3,
      GirisKutusu^.Baslik, RENK_SIYAH)
  end;

  GirisKutusu^.FSilmeDugmesi^.Ciz;
end;

{==============================================================================
  giriþ kutusu nesne olaylarýný iþler
 ==============================================================================}
procedure TGirisKutusu.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere;
  GirisKutusu: PGirisKutusu;
  C: Char;
  s: string;
  Tus: TISayi4;
begin

  GirisKutusu := PGirisKutusu(AGonderici);
  if(GirisKutusu = nil) then Exit;

  // fare sol tuþ basýmý
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // giriþ kutusunun sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(GirisKutusu);

    // en üstte olmamasý durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak iþaretle
    Pencere^.FAktifNesne := GirisKutusu;
    GirisKutusu^.Odaklanildi := True;

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(GirisKutusu^.OlayYonlendirmeAdresi = nil) then
      GirisKutusu^.OlayYonlendirmeAdresi(GirisKutusu, AOlay)
    else Gorevler0.OlayEkle(GirisKutusu^.GorevKimlik, AOlay);
  end
  // klavye tuþ basýmý
  else if(AOlay.Olay = CO_TUSBASILDI) then
  begin

    Tus := (AOlay.Deger1 and $FF);

    if not(GirisKutusu^.Yazilamaz) then
    begin

      C := Char(Tus);

      // enter tuþu
      if(C = #10) then
      begin

        // uygulamaya veya efendi nesneye mesaj gönder
        AOlay.Deger1 := Tus;
        if not(GirisKutusu^.OlayYonlendirmeAdresi = nil) then
          GirisKutusu^.OlayYonlendirmeAdresi(GirisKutusu, AOlay)
        else Gorevler0.OlayEkle(GirisKutusu^.GorevKimlik, AOlay);
      end
      // geri silme tuþu
      else if(C = #8) then
      begin

        s := GirisKutusu^.Baslik;
        if(Length(s) = 1) then

          s := ''
        else
        begin

          s := Copy(s, 1, Length(s) - 1);
        end;
        GirisKutusu^.Baslik := s;

        AOlay.Deger1 := Tus;
        if not(GirisKutusu^.OlayYonlendirmeAdresi = nil) then
          GirisKutusu^.OlayYonlendirmeAdresi(GirisKutusu, AOlay)
        else Gorevler0.OlayEkle(GirisKutusu^.GorevKimlik, AOlay);
      end
      else
      begin

        if(GirisKutusu^.SadeceRakam) then
        begin

          if(C in ['0'..'9', 'A'..'F', 'a'..'f']) then
          begin

            GirisKutusu^.Baslik := GirisKutusu^.Baslik + C;

            // uygulamaya veya efendi nesneye mesaj gönder
            AOlay.Deger1 := Tus;
            if not(GirisKutusu^.OlayYonlendirmeAdresi = nil) then
              GirisKutusu^.OlayYonlendirmeAdresi(GirisKutusu, AOlay)
            else Gorevler0.OlayEkle(GirisKutusu^.GorevKimlik, AOlay);
          end;
        end
        else
        begin

          GirisKutusu^.Baslik := GirisKutusu^.Baslik + C;

          AOlay.Deger1 := Tus;
          if not(GirisKutusu^.OlayYonlendirmeAdresi = nil) then
            GirisKutusu^.OlayYonlendirmeAdresi(GirisKutusu, AOlay)
          else Gorevler0.OlayEkle(GirisKutusu^.GorevKimlik, AOlay);
        end;
      end;

      GirisKutusu^.Ciz;
    end;
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := GirisKutusu^.FareImlecTipi;
end;

{==============================================================================
  giriþ kutusuna baðlý silme düðmesi nesne olaylarýný iþler
 ==============================================================================}
procedure TGirisKutusu.SilmeDugmeOlaylariniIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  GirisKutusu: PGirisKutusu;
  Dugme: PDugme;
begin

  // nesnenin kimlik, tip deðerlerini denetle.
  Dugme := PDugme(AGonderici);
  if(Dugme = nil) then Exit;

  // silme düðmesine týklama gerçekleþtirildiðinde
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    GirisKutusu := PGirisKutusu(Dugme^.AtaNesne);

    GirisKutusu^.Baslik := '';
    GirisKutusu^.Ciz;

    // nesneyi aktif nesne olarak iþaretle
    PPencere(GirisKutusu^.AtaNesne)^.FAktifNesne := GirisKutusu;
    GirisKutusu^.Odaklanildi := True;
  end
end;

end.
