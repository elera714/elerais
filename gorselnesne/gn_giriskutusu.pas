{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_giriskutusu.pas
  Dosya İşlevi: giriş kutusu (TEdit) yönetim işlevlerini içerir

  Güncelleme Tarihi: 11/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_giriskutusu;

interface

uses gorselnesne, paylasim, gn_panel, gn_dugme;

type
  PGirisKutusu = ^TGirisKutusu;
  TGirisKutusu = class(TPanel)
  private
    FSilmeDugmesi: TDugme;
    procedure SilmeDugmeOlaylariniIsle(AGonderici: TGorselNesne; AOlay: TOlay);
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
    property Yazilamaz: Boolean read FDurum1 write FDurum1;
    property SadeceRakam: Boolean read FDurum2 write FDurum2;
    property ImlecX: TISayi4 read FIDeger1 write FIDeger1;
  end;

function GirisKutusuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function GirisKutusuGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik,
  AYukseklik: TISayi4; ABaslik: string): TKimlik;

implementation

uses gn_islevler, gn_pencere, temelgorselnesne, gorev, src_klavye, src_ps2;

{==============================================================================
  giriş kutusu kesme çağrılarını yönetir
 ==============================================================================}
function GirisKutusuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  GirisKutusu: TGirisKutusu;
  p1: PKarakterKatari;
  p2: PLongBool;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := GirisKutusuGNOlustur(GN, PISayi4(ADegiskenler + 04)^,
      PISayi4(ADegiskenler + 08)^, PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^,
      PKarakterKatari(PSayi4(ADegiskenler + 20)^ + GGorevler.FAktifGrvBelAdr)^);
    end;

    ISLEV_GOSTER:
    begin

      GirisKutusu := TGirisKutusu(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      GirisKutusu.Goster;
    end;

    // giriş kutusundaki veriyi al
    $010E:
    begin

      GirisKutusu := TGirisKutusu(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      p1 := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr);
      p1^ := GirisKutusu.Baslik;
    end;

    // giriş kutusundaki veriyi değiştir
    $010F:
    begin

      GirisKutusu := TGirisKutusu(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      p1 := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr);
      GirisKutusu.Baslik := p1^;
      GirisKutusu.Ciz;
    end;

    // giriş kutusunun salt okunur özelliğini değiştir
    $020F:
    begin

      GirisKutusu := TGirisKutusu(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      p2 := PLongBool(ADegiskenler + 04);
      GirisKutusu.Yazilamaz := p2^;
      GirisKutusu.Ciz;
    end;

    // giriş kutusunun sayısal (numeric) değer özelliğini değiştir
    $030F:
    begin

      GirisKutusu := TGirisKutusu(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      p2 := PLongBool(ADegiskenler + 04);
      GirisKutusu.SadeceRakam := p2^;
    end;

    // giriş kutusuna odaklan. (klavye girişlerini almasını sağla)
    $040F:
    begin

      GirisKutusu := TGirisKutusu(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));

      if(GirisKutusu <> nil) and (GirisKutusu.NesneTipi = gntGirisKutusu) then
      begin

        // bir önceki odak alan nesneyi odaktan çıkar
        GN := TPencere(GirisKutusu.AtaNesne).FAktifNesne;
        if(GN <> nil) and (GN.Odaklanilabilir) then GN.Odaklanildi := False;

        // nelirtilen nesneyi pencerenin odaklanılan nesnesi olarak belirle
        TPencere(GirisKutusu.AtaNesne).FAktifNesne := GirisKutusu;
        GirisKutusu.Odaklanildi := True;
      end;
    end;
  end;
end;

{==============================================================================
  uygulama için giriş kutusu nesnesi oluşturur - api
 ==============================================================================}
function GirisKutusuGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik,
  AYukseklik: TISayi4; ABaslik: string): TKimlik;
var
  GirisKutusu: TGirisKutusu;
begin

  GirisKutusu := TGirisKutusu.Create;

  if(GirisKutusu = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    GirisKutusu.Ozellestir(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik, ABaslik);

    Result := GirisKutusu.Kimlik;
  end;
end;

{==============================================================================
  giriş kutusu nesnesi oluşturur
 ==============================================================================}
constructor TGirisKutusu.Create;
begin

  inherited Create;

  NesneTipi := gntGirisKutusu;

  GGNesneler.GorselNesne[FSiraNo] := Self;
end;

{==============================================================================
  giriş kutusu nesnesini yok eder
 ==============================================================================}
destructor TGirisKutusu.Destroy;
begin

  // nesne içerisindeki silme düğmesini yok et
  FSilmeDugmesi.Destroy;

  GGNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  giriş kutusu nesnesini özelleştirir
 ==============================================================================}
function TGirisKutusu.Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4; ABaslik: string): TISayi4;
var
  i: TSayi4;
begin

  // yükseklik değerini sabitle
  AYukseklik := 20;

  Yapilandir2(AKullanimTipi, Self, AAtaNesne, ASol, AUst, AGenislik, AYukseklik,
    2, RENK_GUMUS, RENK_BEYAZ, RENK_SIYAH, ABaslik);

  OlayCagriAdr := @OlaylariIsle;

  Baslik := ABaslik;

  Odaklanilabilir := True;
  Odaklanildi := False;

  Yazilamaz := False;
  SadeceRakam := False;

  FareImlec := fitGiris;

  i := Length(Baslik);
  ImlecX := i;

  // nesne içerisindeki veriyi silmek için düğme oluştur
  FSilmeDugmesi := TDugme.Create;
  FSilmeDugmesi.Ozellestir(ktBilesen, Self, AGenislik - 12, 2, 10, 16, 'X');
  FSilmeDugmesi.CizimModelDegistir(False, RENK_BEYAZ, RENK_BEYAZ, RENK_SIYAH, RENK_KIRMIZI);
  FSilmeDugmesi.OlayYonlAdr := @SilmeDugmeOlaylariniIsle;

  // geri dönüş değeri
  Result := HATA_YOK;
end;

{==============================================================================
  giriş kutusu nesnesini görüntüler
 ==============================================================================}
procedure TGirisKutusu.Goster;
begin

  FSilmeDugmesi.Gorunum := True;

  inherited Goster;
end;

{==============================================================================
  giriş kutusu nesnesini gizler
 ==============================================================================}
procedure TGirisKutusu.Gizle;
begin

  FSilmeDugmesi.Gorunum := False;

  inherited Gizle;
end;

{==============================================================================
  giriş kutusu nesnesini hizalandırır
 ==============================================================================}
procedure TGirisKutusu.Hizala;
begin

  FAtananAlan.Sol := FAtananAlan.Genislik - 13;
  FAtananAlan.Ust := 3;
  FAtananAlan.Genislik := 10;
  FAtananAlan.Yukseklik := 16;
  BoyutlariYenidenHesapla;

  inherited Hizala;
end;

{==============================================================================
  giriş kutusu nesnesini çizer
 ==============================================================================}
procedure TGirisKutusu.Ciz;
var
  CizimAlani: TAlan;
begin

  inherited Ciz;

  // giriş kutusunun çizim alan koordinatlarını al
  CizimAlani := FCizimAlani;

  // nesne odaklanılmış ise nesnenin kenarlarını işaretle
  if(Odaklanildi) then Dikdortgen(Self, ctNokta, CizimAlani, RENK_SIYAH);

  HarfYaz(Self, 3 + (ImlecX * 8), 2, #255, RENK_ACIKYESIL, RENK_ACIKYESIL);

  // nesnenin içerik değeri.
  if(Yazilamaz) then

    YaziYaz(Self, CizimAlani.Sol + 2, CizimAlani.Ust + 3, Baslik, RENK_SIYAH)
  else
  begin

    // nesne odak kazanmışsa sonuna #255 = klavye kursörü ekle
    if(Odaklanildi) then

      YaziYaz(Self, CizimAlani.Sol + 2, CizimAlani.Ust + 3, Baslik, RENK_SIYAH)

    else YaziYaz(Self, CizimAlani.Sol + 2, CizimAlani.Ust + 3, Baslik, RENK_SIYAH);
  end;

  FSilmeDugmesi.Ciz;
end;

{==============================================================================
  giriş kutusu nesne olaylarınını işler
 ==============================================================================}
procedure TGirisKutusu.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Pencere: TPencere;
  C: Char;
  s: string;
  Tus,
  i, j: TISayi4;
begin

  // fare sol tuş basımı
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // giriş kutusunun sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(Self);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere.FAktifNesne := Self;
    Odaklanildi := True;

    i := (AOlay.Deger1 div 8);
    j := Length(Baslik);
    if(i > j) then
      ImlecX := j
    else ImlecX := i;

    Ciz;

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(OlayYonlAdr = nil) then
      OlayYonlAdr(Self, AOlay)
    else GGorevler.OlayEkle(GrvKimlik, AOlay);
  end
  // klavye tuş basımı
  else if(AOlay.Olay = CO_TUSBASILDI) then
  begin

    if(AOlay.Deger1 = TUS_SAG) then
    begin

      i := ImlecX;
      j := Length(Baslik);
      Inc(i);
      if(i <= j) then ImlecX := i;
    end
    else if(AOlay.Deger1 = TUS_SOL) then
    begin

      i := ImlecX;
      Dec(i);
      if(i < 0) then i := 0;
      ImlecX := i;
    end
    else if(AOlay.Deger1 = TUS_GIT_BASA) then
    begin

      ImlecX := 0;
    end
    else if(AOlay.Deger1 = TUS_GIT_SONA) then
    begin

      i := Length(Baslik);
      ImlecX := i;
    end
    else if(AOlay.Deger1 = TUS_SIL) then
    begin

      // imleç satırın sonunda ise veya nesne içeriği yoksa çık
      i := Length(Baslik);
      if(i = ImlecX) or (i = 0) then Exit;

      s := Baslik;
      Delete(s, ImlecX + 1, 1);
      Baslik := s;
    end
    else
    begin

      // tuş herhangi bir kontrol tuşu değilse
      if((AOlay.Deger1 and $FF00) = 0) then
      begin

        Tus := (AOlay.Deger1 and $FF);

        if not(Yazilamaz) then
        begin

          C := Char(Tus);

          // enter tuşu
          if(C = #10) then
          begin

            // uygulamaya veya efendi nesneye mesaj gönder
            AOlay.Deger1 := Tus;
            if not(OlayYonlAdr = nil) then
              OlayYonlAdr(Self, AOlay)
            else GGorevler.OlayEkle(GrvKimlik, AOlay);
          end
          // geri silme tuşu
          else if(C = #8) then
          begin

            // imlecin satırın başında olma durumu
            if(ImlecX = 0) then Exit;

            i := Length(Baslik);

            // imlecin satırın sonunda olma durumu
            if(i = ImlecX) then
            begin

              if(i = 1) then
                s := ''
              else s := Copy(Baslik, 1, i - 1);
            end
            // imlecin satırın orta kısmında olma durumu
            else
            begin

              s := Baslik;
              Delete(s, ImlecX, 1);
              i := ImlecX;
            end;

            ImlecX := i - 1;
            Baslik := s;

            AOlay.Deger1 := Tus;
            if not(OlayYonlAdr = nil) then
              OlayYonlAdr(Self, AOlay)
            else GGorevler.OlayEkle(GrvKimlik, AOlay);
          end
          else
          begin

            if(SadeceRakam) then
            begin

              if(C in ['0'..'9', 'A'..'F', 'a'..'f']) then
              begin

                s := Baslik;
                Insert(C, s, ImlecX + 1);
                Baslik := s;

                // uygulamaya veya efendi nesneye mesaj gönder
                AOlay.Deger1 := Tus;
                if not(OlayYonlAdr = nil) then
                  OlayYonlAdr(Self, AOlay)
                else GGorevler.OlayEkle(GrvKimlik, AOlay);
              end;
            end
            else
            begin

              s := Baslik;
              Insert(C, s, ImlecX + 1);
              Baslik := s;

              AOlay.Deger1 := Tus;
              if not(OlayYonlAdr = nil) then
                OlayYonlAdr(Self, AOlay)
              else GGorevler.OlayEkle(GrvKimlik, AOlay);
            end;

            i := ImlecX;
            Inc(i);
            ImlecX := i;
          end;
        end;
      end;

      Ciz;
    end;
  end
  // nesnenin odağı kaybetmesi durumu
  else if(AOlay.Olay = CO_ODAKKAYBEDILDI) then
  begin

    // giriş kutusu nesnesinin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(Self);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere.FAktifNesne := nil;
    Odaklanildi := False;

    // giriş kutusu nesnesini yeniden çiz
    Ciz;
  end
  // nesnenin odağı yeniden kazanması durumu
  else if(AOlay.Olay = CO_ODAKKAZANILDI) then
  begin

    // giriş kutusu nesnesinin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(Self);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere.FAktifNesne := Self;
    Odaklanildi := True;

    // giriş kutusu nesnesini yeniden çiz
    Ciz;
  end;

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := Self.FareImlec;
end;

{==============================================================================
  giriş kutusuna bağlı silme düğmesi nesne olaylarını işler
 ==============================================================================}
procedure TGirisKutusu.SilmeDugmeOlaylariniIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  GirisKutusu: TGirisKutusu;
  Dugme: TDugme;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  Dugme := TDugme(AGonderici);
  if(Dugme = nil) then Exit;

  // silme düğmesine tıklama gerçekleştirildiğinde
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    GirisKutusu := TGirisKutusu(Dugme.AtaNesne);

    GirisKutusu.Baslik := '';
    GirisKutusu.ImlecX := 0;

    GirisKutusu.Ciz;

    // nesneyi aktif nesne olarak işaretle
    TPencere(GirisKutusu.AtaNesne).FAktifNesne := GirisKutusu;
    GirisKutusu.Odaklanildi := True;
  end
end;

end.
