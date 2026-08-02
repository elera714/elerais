{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_giriskutusu.pas
  Dosya İşlevi: giriş kutusu (TEdit) yönetim işlevlerini içerir

  Güncelleme Tarihi: 21/07/2026

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
    property ImlecX: TISayi4 read FIDeger1 write FIDeger1;
  end;

function GirisKutusuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik;

implementation

uses gn_islevler, gn_pencere, genel, temelgorselnesne, gorev, sistemmesaj, src_klavye;

{==============================================================================
  giriş kutusu kesme çağrılarını yönetir
 ==============================================================================}
function GirisKutusuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne;
  GirisKutusu: PGirisKutusu;
  p1: PKarakterKatari;
  p2: PLongBool;
begin

  Result := HATA_ISLEV;

  case AIslevNo of
    ISLEV_OLUSTUR:
    begin

      GN := GGorselNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GN, PISayi4(ADegiskenler + 04)^,
        PISayi4(ADegiskenler + 08)^, PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^,
        PKarakterKatari(PSayi4(ADegiskenler + 20)^ + FAktifGorevBellekAdresi)^);
    end;

    ISLEV_GOSTER:
    begin

      GirisKutusu := PGirisKutusu(GGorselNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      GirisKutusu^.Goster;
    end;

    // giriş kutusundaki veriyi al
    $010E:
    begin

      GirisKutusu := PGirisKutusu(GGorselNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      p1 := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
      p1^ := GirisKutusu^.F0.Baslik;
    end;

    // giriş kutusundaki veriyi değiştir
    $010F:
    begin

      GirisKutusu := PGirisKutusu(GGorselNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      p1 := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
      GirisKutusu^.F0.Baslik := p1^;
      GirisKutusu^.Ciz;
    end;

    // giriş kutusunun salt okunur özelliğini değiştir
    $020F:
    begin

      GirisKutusu := PGirisKutusu(GGorselNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      p2 := PLongBool(ADegiskenler + 04);
      GirisKutusu^.Yazilamaz := p2^;
      GirisKutusu^.Ciz;
    end;

    // giriş kutusunun sayısal (numeric) değer özelliğini değiştir
    $030F:
    begin

      GirisKutusu := PGirisKutusu(GGorselNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      p2 := PLongBool(ADegiskenler + 04);
      GirisKutusu^.SadeceRakam := p2^;
    end;

    // giriş kutusuna odaklan. (klavye girişlerini almasını sağla)
    $040F:
    begin

      GirisKutusu := PGirisKutusu(GGorselNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));

      if(GirisKutusu <> nil) and (GirisKutusu^.F0.NesneTipi = gntGirisKutusu) then
      begin

        // bir önceki odak alan nesneyi odaktan çıkar
        GN := PPencere(GirisKutusu^.AtaNesne)^.FAktifNesne;
        if(GN <> nil) and (GN^.F0.Odaklanilabilir) then GN^.F0.Odaklanildi := False;

        // nelirtilen nesneyi odaklanılan nesne olarak belirle
        PPencere(GirisKutusu^.AtaNesne)^.FAktifNesne := GirisKutusu;
        GirisKutusu^.F0.Odaklanildi := True;
      end;
    end;
  end;
end;

{==============================================================================
  giriş kutusu nesnesini oluşturur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik;
var
  GirisKutusu: PGirisKutusu;
begin

  GirisKutusu := GirisKutusu^.Olustur(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik, ABaslik);

  if(GirisKutusu = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := GirisKutusu^.F0.Kimlik;
end;

{==============================================================================
  giriş kutusu nesnesini oluşturur
 ==============================================================================}
function TGirisKutusu.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4; ABaslik: string): PGirisKutusu;
var
  GirisKutusu: PGirisKutusu;
  i: TSayi4;
begin

  AYukseklik := 20;

  GirisKutusu := PGirisKutusu(inherited Olustur(AKullanimTipi, AAtaNesne, ASol, AUst,
    AGenislik, AYukseklik, 2, RENK_GUMUS, RENK_BEYAZ, RENK_SIYAH, ABaslik));

  // görsel nesne tipi
  GirisKutusu^.F0.NesneTipi := gntGirisKutusu;

  GirisKutusu^.F0.Baslik := ABaslik;

  GirisKutusu^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  GirisKutusu^.F0.Odaklanilabilir := True;
  GirisKutusu^.F0.Odaklanildi := False;

  GirisKutusu^.OlayCagriAdresi := @OlaylariIsle;

  GirisKutusu^.F0.FareImlecTipi := fitGiris;

  GirisKutusu^.Yazilamaz := False;
  GirisKutusu^.SadeceRakam := False;

  i := Length(GirisKutusu^.F0.Baslik);
  GirisKutusu^.ImlecX := i;

  GirisKutusu^.FSilmeDugmesi := GirisKutusu^.FSilmeDugmesi^.Olustur(ktBilesen, GirisKutusu,
    AGenislik - 12, 2, 10, 16, 'X');
  GirisKutusu^.FSilmeDugmesi^.CizimModelDegistir(False, RENK_BEYAZ, RENK_BEYAZ, RENK_SIYAH, RENK_KIRMIZI);
  GirisKutusu^.FSilmeDugmesi^.OlayYonlendirmeAdresi := @SilmeDugmeOlaylariniIsle;

  // nesne bellek adresini geri döndür
  Result := GirisKutusu;
end;

{==============================================================================
  giriş kutusu nesnesini yok eder
 ==============================================================================}
procedure TGirisKutusu.YokEt(AKimlik: TKimlik);
var
  GirisKutusu: PGirisKutusu;
begin

  GirisKutusu := PGirisKutusu(GGorselNesneler.NesneAl(AKimlik));
  if(GirisKutusu = nil) then Exit;

  GirisKutusu^.FSilmeDugmesi^.YokEt(GirisKutusu^.FSilmeDugmesi^.F0.Kimlik);

  inherited YokEt(AKimlik);
end;

{==============================================================================
  giriş kutusu nesnesini görüntüler
 ==============================================================================}
procedure TGirisKutusu.Goster;
var
  GirisKutusu: PGirisKutusu;
begin

  GirisKutusu := PGirisKutusu(GGorselNesneler.NesneAl(F0.Kimlik));
  if(GirisKutusu = nil) then Exit;

  GirisKutusu^.FSilmeDugmesi^.F0.Gorunum := True;

  inherited Goster;
end;

{==============================================================================
  giriş kutusu nesnesini gizler
 ==============================================================================}
procedure TGirisKutusu.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  giriş kutusu nesnesini hizalandırır
 ==============================================================================}
procedure TGirisKutusu.Hizala;
var
  GirisKutusu: PGirisKutusu;
begin

  GirisKutusu := PGirisKutusu(GGorselNesneler.NesneAl(F0.Kimlik));
  if(GirisKutusu = nil) then Exit;

  GirisKutusu^.FSilmeDugmesi^.F0.FAtananAlan.Sol := GirisKutusu^.F0.FAtananAlan.Genislik - 13;
  GirisKutusu^.FSilmeDugmesi^.F0.FAtananAlan.Ust := 3;
  GirisKutusu^.FSilmeDugmesi^.F0.FAtananAlan.Genislik := 10;
  GirisKutusu^.FSilmeDugmesi^.F0.FAtananAlan.Yukseklik := 16;
  GirisKutusu^.FSilmeDugmesi^.BoyutlariYenidenHesapla;

  inherited Hizala;
end;

{==============================================================================
  giriş kutusu nesnesini çizer
 ==============================================================================}
procedure TGirisKutusu.Ciz;
var
  GirisKutusu: PGirisKutusu;
  CizimAlani: TAlan;
  i: TSayi4;
begin

  GirisKutusu := PGirisKutusu(GGorselNesneler.NesneAl(F0.Kimlik));
  if(GirisKutusu = nil) then Exit;

  inherited Ciz;

  // giriş kutusunun çizim alan koordinatlarını al
  CizimAlani := GirisKutusu^.F0.FCizimAlani;

  // nesne odaklanılmış ise nesnenin kenarlarını işaretle
  if(GirisKutusu^.F0.Odaklanildi) then GirisKutusu^.Dikdortgen(GirisKutusu, ctNokta, CizimAlani, RENK_SIYAH);

  GirisKutusu^.HarfYaz(GirisKutusu, 3 + (GirisKutusu^.ImlecX * 8), 2, #255, RENK_ACIKYESIL, RENK_ACIKYESIL);

  // nesnenin içerik değeri.
  if(GirisKutusu^.Yazilamaz) then

    GirisKutusu^.YaziYaz(GirisKutusu, CizimAlani.Sol + 2, CizimAlani.Ust + 3,
      GirisKutusu^.F0.Baslik, RENK_SIYAH)
  else
  begin

    // nesne odak kazanmışsa sonuna #255 = klavye kursörü ekle
    if(GirisKutusu^.F0.Odaklanildi) then
      GirisKutusu^.YaziYaz(GirisKutusu, CizimAlani.Sol + 2, CizimAlani.Ust + 3,
        GirisKutusu^.F0.Baslik, RENK_SIYAH)
    else GirisKutusu^.YaziYaz(GirisKutusu, CizimAlani.Sol + 2, CizimAlani.Ust + 3,
      GirisKutusu^.F0.Baslik, RENK_SIYAH)
  end;

  GirisKutusu^.FSilmeDugmesi^.Ciz;
end;

{==============================================================================
  giriş kutusu nesne olaylarını işler
 ==============================================================================}
procedure TGirisKutusu.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere;
  GirisKutusu: PGirisKutusu;
  C: Char;
  s: string;
  Tus: TISayi4;
  i, j: TISayi4;
begin

  GirisKutusu := PGirisKutusu(AGonderici);
  if(GirisKutusu = nil) then Exit;

  // fare sol tuş basımı
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // giriş kutusunun sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(GirisKutusu);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere^.FAktifNesne := GirisKutusu;
    GirisKutusu^.F0.Odaklanildi := True;

    i := (AOlay.Deger1 div 8);
    j := Length(GirisKutusu^.F0.Baslik);
    if(i > j) then
      GirisKutusu^.ImlecX := j
    else GirisKutusu^.ImlecX := i;

    GirisKutusu^.Ciz;

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(GirisKutusu^.OlayYonlendirmeAdresi = nil) then
      GirisKutusu^.OlayYonlendirmeAdresi(GirisKutusu, AOlay)
    else Gorevler0.OlayEkle(GirisKutusu^.F0.GorevKimlik, AOlay);
  end
  // klavye tuş basımı
  else if(AOlay.Olay = CO_TUSBASILDI) then
  begin

    if(AOlay.Deger1 = TUS_SAG) then
    begin

      i := GirisKutusu^.ImlecX;
      j := Length(GirisKutusu^.F0.Baslik);
      Inc(i);
      if(i <= j) then GirisKutusu^.ImlecX := i;
    end
    else if(AOlay.Deger1 = TUS_SOL) then
    begin

      i := GirisKutusu^.ImlecX;
      Dec(i);
      if(i < 0) then i := 0;
      GirisKutusu^.ImlecX := i;
    end
    else if(AOlay.Deger1 = TUS_GIT_BASA) then
    begin

      GirisKutusu^.ImlecX := 0;
    end
    else if(AOlay.Deger1 = TUS_GIT_SONA) then
    begin

      i := Length(GirisKutusu^.F0.Baslik);
      GirisKutusu^.ImlecX := i;
    end
    else if(AOlay.Deger1 = TUS_SIL) then
    begin

      // imleç satırın sonunda ise veya nesne içeriği yoksa çık
      i := Length(GirisKutusu^.F0.Baslik);
      if(i = GirisKutusu^.ImlecX) or (i = 0) then Exit;

      s := GirisKutusu^.F0.Baslik;
      Delete(s, GirisKutusu^.ImlecX + 1, 1);
      GirisKutusu^.F0.Baslik := s;
    end
    else
    begin

      // tuş herhangi bir kontrol tuşu değilse
      if((AOlay.Deger1 and $FF00) = 0) then
      begin

        Tus := (AOlay.Deger1 and $FF);

        if not(GirisKutusu^.Yazilamaz) then
        begin

          C := Char(Tus);

          // enter tuşu
          if(C = #10) then
          begin

            // uygulamaya veya efendi nesneye mesaj gönder
            AOlay.Deger1 := Tus;
            if not(GirisKutusu^.OlayYonlendirmeAdresi = nil) then
              GirisKutusu^.OlayYonlendirmeAdresi(GirisKutusu, AOlay)
            else Gorevler0.OlayEkle(GirisKutusu^.F0.GorevKimlik, AOlay);
          end
          // geri silme tuşu
          else if(C = #8) then
          begin

            // imlecin satırın başında olma durumu
            if(GirisKutusu^.ImlecX = 0) then Exit;

            i := Length(GirisKutusu^.F0.Baslik);

            // imlecin satırın sonunda olma durumu
            if(i = GirisKutusu^.ImlecX) then
            begin

              if(i = 1) then
                s := ''
              else s := Copy(GirisKutusu^.F0.Baslik, 1, i - 1);
            end
            // imlecin satırın orta kısmında olma durumu
            else
            begin

              s := GirisKutusu^.F0.Baslik;
              Delete(s, GirisKutusu^.ImlecX, 1);
              i := GirisKutusu^.ImlecX;
            end;

            GirisKutusu^.ImlecX := i - 1;
            GirisKutusu^.F0.Baslik := s;

            AOlay.Deger1 := Tus;
            if not(GirisKutusu^.OlayYonlendirmeAdresi = nil) then
              GirisKutusu^.OlayYonlendirmeAdresi(GirisKutusu, AOlay)
            else Gorevler0.OlayEkle(GirisKutusu^.F0.GorevKimlik, AOlay);
          end
          else
          begin

            if(GirisKutusu^.SadeceRakam) then
            begin

              if(C in ['0'..'9', 'A'..'F', 'a'..'f']) then
              begin

                s := GirisKutusu^.F0.Baslik;
                Insert(C, s, GirisKutusu^.ImlecX + 1);
                GirisKutusu^.F0.Baslik := s;

                // uygulamaya veya efendi nesneye mesaj gönder
                AOlay.Deger1 := Tus;
                if not(GirisKutusu^.OlayYonlendirmeAdresi = nil) then
                  GirisKutusu^.OlayYonlendirmeAdresi(GirisKutusu, AOlay)
                else Gorevler0.OlayEkle(GirisKutusu^.F0.GorevKimlik, AOlay);
              end;
            end
            else
            begin

              s := GirisKutusu^.F0.Baslik;
              Insert(C, s, GirisKutusu^.ImlecX + 1);
              GirisKutusu^.F0.Baslik := s;

              AOlay.Deger1 := Tus;
              if not(GirisKutusu^.OlayYonlendirmeAdresi = nil) then
                GirisKutusu^.OlayYonlendirmeAdresi(GirisKutusu, AOlay)
              else Gorevler0.OlayEkle(GirisKutusu^.F0.GorevKimlik, AOlay);
            end;

            i := GirisKutusu^.ImlecX;
            Inc(i);
            GirisKutusu^.ImlecX := i;
          end;
        end;
      end;

      GirisKutusu^.Ciz;
    end;
  end
  // nesnenin odağı kaybetmesi durumu
  else if(AOlay.Olay = CO_ODAKKAYBEDILDI) then
  begin

    // giriş kutusu nesnesinin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(GirisKutusu);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere^.FAktifNesne := nil;
    GirisKutusu^.F0.Odaklanildi := False;

    // giriş kutusu nesnesini yeniden çiz
    GirisKutusu^.Ciz;
  end
  // nesnenin odağı yeniden kazanması durumu
  else if(AOlay.Olay = CO_ODAKKAZANILDI) then
  begin

    // giriş kutusu nesnesinin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(GirisKutusu);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere^.FAktifNesne := GirisKutusu;
    GirisKutusu^.F0.Odaklanildi := True;

    // giriş kutusu nesnesini yeniden çiz
    GirisKutusu^.Ciz;
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := GirisKutusu^.F0.FareImlecTipi;
end;

{==============================================================================
  giriş kutusuna bağlı silme düğmesi nesne olaylarını işler
 ==============================================================================}
procedure TGirisKutusu.SilmeDugmeOlaylariniIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  GirisKutusu: PGirisKutusu;
  Dugme: PDugme;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  Dugme := PDugme(AGonderici);
  if(Dugme = nil) then Exit;

  // silme düğmesine tıklama gerçekleştirildiğinde
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    GirisKutusu := PGirisKutusu(Dugme^.AtaNesne);

    GirisKutusu^.F0.Baslik := '';
    GirisKutusu^.ImlecX := 0;

    GirisKutusu^.Ciz;

    // nesneyi aktif nesne olarak işaretle
    PPencere(GirisKutusu^.AtaNesne)^.FAktifNesne := GirisKutusu;
    GirisKutusu^.F0.Odaklanildi := True;
  end
end;

end.
