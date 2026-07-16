{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_kaydirmacubugu.pp
  Dosya İşlevi: kaydırma çubuğu (TScrollBar) yönetim işlevlerini içerir

  Güncelleme Tarihi: 16/07/2026

 ==============================================================================}
{$mode objfpc}
unit gn_kaydirmacubugu;

interface

uses gorev, gorselnesne, paylasim, gn_pencere, gn_panel, gn_resimdugmesi;

type
  PKaydirmaCubugu = ^TKaydirmaCubugu;
  TKaydirmaCubugu = object(TPanel)
  private
    procedure ResimDugmesiOlaylariniIsle(AGonderici: PGorselNesne; AOlay: TOlay);
  public
    FYon: TYon;
    FEksiltmeDugmesi, FArtirmaDugmesi: PResimDugmesi;
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne; ASol, AUst,
      AGenislik, AYukseklik: TISayi4; AYon: TYon): PKaydirmaCubugu;
    procedure YokEt(AKimlik: TKimlik);
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    procedure DegerleriBelirle(AAltDeger, AUstDeger: TISayi4);
    property MevcutDeger: TISayi4 read FIDeger1 write FIDeger1;
    property AltDeger: TISayi4 read FIDeger2 write FIDeger2;
    property UstDeger: TISayi4 read FIDeger3 write FIDeger3;
  end;

function KaydirmaCubuguCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  AYon: TYon): TKimlik;

implementation

uses genel, gn_islevler, temelgorselnesne, sistemmesaj;

{==============================================================================
  kaydırma çubuğu kesme çağrılarını yönetir
 ==============================================================================}
function KaydirmaCubuguCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne = nil;
  Pencere: PPencere = nil;
  KaydirmaCubugu: PKaydirmaCubugu = nil;
  Hiza: THiza;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^, PYon(ADegiskenler + 20)^);
    end;

    ISLEV_GOSTER:
    begin

      KaydirmaCubugu := PKaydirmaCubugu(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      KaydirmaCubugu^.Goster;
    end;

    ISLEV_HIZALA:
    begin

      KaydirmaCubugu := PKaydirmaCubugu(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      KaydirmaCubugu^.FHiza := Hiza;

      Pencere := PPencere(KaydirmaCubugu^.FAtaNesne);
      Pencere^.Guncelle;
    end;

    // alt, üst değerlerini belirle
    $010F:
    begin

      KaydirmaCubugu := PKaydirmaCubugu(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntKaydirmaCubugu));
      if(KaydirmaCubugu <> nil) then KaydirmaCubugu^.DegerleriBelirle(
        PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^);
    end;
  end;
end;

{==============================================================================
  kaydırma çubuğu nesnesini oluşturur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  AYon: TYon): TKimlik;
var
  KaydirmaCubugu: PKaydirmaCubugu = nil;
begin

  KaydirmaCubugu := KaydirmaCubugu^.Olustur(ktNesne, AAtaNesne, ASol, AUst,
    AGenislik, AYukseklik, AYon);

  if(KaydirmaCubugu = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := KaydirmaCubugu^.Kimlik;
end;

{==============================================================================
  kaydırma çubuğu nesnesini oluşturur
 ==============================================================================}
function TKaydirmaCubugu.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4; AYon: TYon): PKaydirmaCubugu;
var
  KaydirmaCubugu: PKaydirmaCubugu = nil;
  Genislik, Yukseklik: TISayi4;
begin

  Yukseklik := AYukseklik;
  Genislik := AGenislik;

  // dikey kaydırma çubuğunun genişliği 20px (0..19) olarak sabitleniyor
  if(AYon = yDikey) then
    Genislik := 20
  else Genislik := AGenislik;

  // yatay kaydırma çubuğunun yüksekliği 20px (0..19) olarak sabitleniyor
  if(AYon = yYatay) then
    Yukseklik := 20
  else Yukseklik := AYukseklik;

  KaydirmaCubugu := PKaydirmaCubugu(inherited Olustur(AKullanimTipi, AAtaNesne,
    ASol, AUst, Genislik, Yukseklik, 3, RENK_GUMUS, RENK_BEYAZ, 0, ''));

  // görsel nesne tipi
  KaydirmaCubugu^.NesneTipi := gntKaydirmaCubugu;

  KaydirmaCubugu^.Baslik := '';

  KaydirmaCubugu^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  // şu aşamada bu nesne odaklanılabilir bir nesne değil
  KaydirmaCubugu^.Odaklanilabilir := False;
  KaydirmaCubugu^.Odaklanildi := False;

  KaydirmaCubugu^.OlayCagriAdresi := @OlaylariIsle;

  KaydirmaCubugu^.FYon := AYon;

  if(AYon = yYatay) then
  begin

    // $10000000 + 4 = sol ok resmi
    KaydirmaCubugu^.FEksiltmeDugmesi := FEksiltmeDugmesi^.Olustur(ktBilesen, KaydirmaCubugu,
      0, 0, 19, Yukseklik, $10000000 + 4, True);
    KaydirmaCubugu^.FEksiltmeDugmesi^.OlayYonlendirmeAdresi := @ResimDugmesiOlaylariniIsle;

    // $10000000 + 3 = sağ ok resmi
    KaydirmaCubugu^.FArtirmaDugmesi := FArtirmaDugmesi^.Olustur(ktBilesen, KaydirmaCubugu,
      Genislik - 19, 0, 19, Yukseklik, $10000000 + 3, True);
    KaydirmaCubugu^.FArtirmaDugmesi^.OlayYonlendirmeAdresi := @ResimDugmesiOlaylariniIsle;
  end
  else
  begin

    // $10000000 + 4 = yukarı ok resmi
    KaydirmaCubugu^.FEksiltmeDugmesi := FEksiltmeDugmesi^.Olustur(ktBilesen, KaydirmaCubugu,
      0, 0, 19, 19, $10000000 + 1, True);
    KaydirmaCubugu^.FEksiltmeDugmesi^.OlayYonlendirmeAdresi := @ResimDugmesiOlaylariniIsle;

    // $10000000 + 3 = aşağı ok resmi
    KaydirmaCubugu^.FArtirmaDugmesi := FArtirmaDugmesi^.Olustur(ktBilesen, KaydirmaCubugu,
      0, Yukseklik - 19, 19, 19, $10000000 + 2, True);
    KaydirmaCubugu^.FArtirmaDugmesi^.OlayYonlendirmeAdresi := @ResimDugmesiOlaylariniIsle;
  end;

  KaydirmaCubugu^.MevcutDeger := 0;
  KaydirmaCubugu^.AltDeger := 0;
  KaydirmaCubugu^.UstDeger := 100;

  // nesne adresini geri döndür
  Result := KaydirmaCubugu;
end;

{==============================================================================
  kaydırma çubuğu nesnesini yok eder
 ==============================================================================}
procedure TKaydirmaCubugu.YokEt(AKimlik: TKimlik);
var
  KaydirmaCubugu: PKaydirmaCubugu;
begin

  KaydirmaCubugu := PKaydirmaCubugu(GorselNesneler0.NesneAl(AKimlik));
  if(KaydirmaCubugu = nil) then Exit;

  KaydirmaCubugu^.FArtirmaDugmesi^.YokEt(KaydirmaCubugu^.FArtirmaDugmesi^.Kimlik);
  KaydirmaCubugu^.FEksiltmeDugmesi^.YokEt(KaydirmaCubugu^.FEksiltmeDugmesi^.Kimlik);

  inherited YokEt(AKimlik);
end;

{==============================================================================
  kaydırma çubuğu nesnesini görüntüler
 ==============================================================================}
procedure TKaydirmaCubugu.Goster;
var
  KaydirmaCubugu: PKaydirmaCubugu = nil;
begin

  KaydirmaCubugu := PKaydirmaCubugu(GorselNesneler0.NesneAl(Kimlik));
  if(KaydirmaCubugu = nil) then Exit;

  KaydirmaCubugu^.FArtirmaDugmesi^.Goster;
  KaydirmaCubugu^.FEksiltmeDugmesi^.Goster;

  inherited Goster;
end;

{==============================================================================
  kaydırma çubuğu nesnesini gizler
 ==============================================================================}
procedure TKaydirmaCubugu.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  kaydırma çubuğu nesnesini hizalandırır
 ==============================================================================}
procedure TKaydirmaCubugu.Hizala;
var
  KaydirmaCubugu: PKaydirmaCubugu = nil;
begin

  KaydirmaCubugu := PKaydirmaCubugu(GorselNesneler0.NesneAl(Kimlik));
  if(KaydirmaCubugu = nil) then Exit;

  if(KaydirmaCubugu^.FYon = yYatay) then
  begin

    KaydirmaCubugu^.FEksiltmeDugmesi^.FAtananAlan.Sol := 0;
    KaydirmaCubugu^.FEksiltmeDugmesi^.FAtananAlan.Ust := 0;
    KaydirmaCubugu^.FEksiltmeDugmesi^.FAtananAlan.Genislik := 20;
    KaydirmaCubugu^.FEksiltmeDugmesi^.FAtananAlan.Yukseklik := 20;
    KaydirmaCubugu^.FEksiltmeDugmesi^.BoyutlariYenidenHesapla;

    KaydirmaCubugu^.FArtirmaDugmesi^.FAtananAlan.Sol := KaydirmaCubugu^.FAtananAlan.Genislik - 20;
    KaydirmaCubugu^.FArtirmaDugmesi^.FAtananAlan.Ust := 0;
    KaydirmaCubugu^.FArtirmaDugmesi^.FAtananAlan.Genislik := 20;
    KaydirmaCubugu^.FArtirmaDugmesi^.FAtananAlan.Yukseklik := 20;
    KaydirmaCubugu^.FArtirmaDugmesi^.BoyutlariYenidenHesapla;
  end
  else if(KaydirmaCubugu^.FYon = yDikey) then
  begin

    KaydirmaCubugu^.FEksiltmeDugmesi^.FAtananAlan.Sol := 0;
    KaydirmaCubugu^.FEksiltmeDugmesi^.FAtananAlan.Ust := 0;
    KaydirmaCubugu^.FEksiltmeDugmesi^.FAtananAlan.Genislik := 20;
    KaydirmaCubugu^.FEksiltmeDugmesi^.FAtananAlan.Yukseklik := 20;
    KaydirmaCubugu^.FEksiltmeDugmesi^.BoyutlariYenidenHesapla;

    KaydirmaCubugu^.FArtirmaDugmesi^.FAtananAlan.Sol := 0;
    KaydirmaCubugu^.FArtirmaDugmesi^.FAtananAlan.Ust := KaydirmaCubugu^.FAtananAlan.Yukseklik - 20;
    KaydirmaCubugu^.FArtirmaDugmesi^.FAtananAlan.Genislik := 20;
    KaydirmaCubugu^.FArtirmaDugmesi^.FAtananAlan.Yukseklik := 20;
    KaydirmaCubugu^.FArtirmaDugmesi^.BoyutlariYenidenHesapla;
  end;
end;

{==============================================================================
  kaydırma çubuğu nesnesini çizer
 ==============================================================================}
procedure TKaydirmaCubugu.Ciz;
var
  KaydirmaCubugu: PKaydirmaCubugu = nil;
  CizimAlani: TAlan;
  Frekans: Double;
  AraBoslukU, i: TISayi4;
begin

  inherited Ciz;

  KaydirmaCubugu := PKaydirmaCubugu(GorselNesneler0.NesneAl(Kimlik));
  if(KaydirmaCubugu = nil) then Exit;

  // kaydırma çubuğunun çizim alan koordinatlarını al
  CizimAlani := KaydirmaCubugu^.FCizimAlani;

  if(KaydirmaCubugu^.FYon = yDikey) then
  begin

    AraBoslukU := KaydirmaCubugu^.FAtananAlan.Yukseklik - (20 * 3);
    Frekans := AraBoslukU / KaydirmaCubugu^.UstDeger;

    i := Round(KaydirmaCubugu^.MevcutDeger * Frekans);

    DikdortgenDoldur(KaydirmaCubugu, CizimAlani.Sol + 2, CizimAlani.Ust + 20 + i,
      CizimAlani.Sag - 2, CizimAlani.Ust + 20 + i + 20, $7F7F7F, $7F7F7F);
  end
  else
  begin

    AraBoslukU := KaydirmaCubugu^.FAtananAlan.Genislik - (20 * 3);
    Frekans := AraBoslukU / KaydirmaCubugu^.UstDeger;

    i := Round(KaydirmaCubugu^.MevcutDeger * Frekans);

    DikdortgenDoldur(KaydirmaCubugu, CizimAlani.Sol + 20 + i, CizimAlani.Ust + 2,
      CizimAlani.Sol + 20 + i + 20, CizimAlani.Alt - 2, $7F7F7F, $7F7F7F);
  end;
end;

{==============================================================================
  kaydırma çubuğu nesne olaylarını işler
 ==============================================================================}
procedure TKaydirmaCubugu.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere = nil;
  KaydirmaCubugu: PKaydirmaCubugu = nil;
begin

  KaydirmaCubugu := PKaydirmaCubugu(AGonderici);
  if(KaydirmaCubugu = nil) then Exit;

  // farenin sol tuşuna basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // kaydırma çubuğunun sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(KaydirmaCubugu);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    // bilgi: şu aşamada bu nesne odaklanılabilir bir nesne değil
    //Pencere^.FAktifNesne := KaydirmaCubugu;
    //KaydirmaCubugu^.Odaklanildi := False;
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := KaydirmaCubugu^.FareImlecTipi;
end;

{==============================================================================
  kaydırma çubuğunun sahip olduğu artırma / eksiltme nesne olaylarını işler
 ==============================================================================}
procedure TKaydirmaCubugu.ResimDugmesiOlaylariniIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  KaydirmaCubugu: PKaydirmaCubugu = nil;
  ResimDugmesi: PResimDugmesi = nil;
  i: TISayi4;
begin

  ResimDugmesi := PResimDugmesi(AGonderici);
  if(ResimDugmesi = nil) then Exit;

  KaydirmaCubugu := PKaydirmaCubugu(ResimDugmesi^.AtaNesne);

  if(AOlay.Olay = FO_TIKLAMA) then
  begin

    if(AOlay.Kimlik = KaydirmaCubugu^.FEksiltmeDugmesi^.Kimlik) then
    begin

      i := KaydirmaCubugu^.MevcutDeger;
      Dec(i);
      if(i < KaydirmaCubugu^.AltDeger) then i := KaydirmaCubugu^.AltDeger;
    end
    else
    begin

      i := KaydirmaCubugu^.MevcutDeger;
      Inc(i);
      if(i > KaydirmaCubugu^.UstDeger) then i := KaydirmaCubugu^.UstDeger;
    end;

    KaydirmaCubugu^.MevcutDeger := i;

    KaydirmaCubugu^.Ciz;

    AOlay.Kimlik := KaydirmaCubugu^.Kimlik;
    AOlay.Deger1 := KaydirmaCubugu^.MevcutDeger;

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(KaydirmaCubugu^.OlayYonlendirmeAdresi = nil) then
      KaydirmaCubugu^.OlayYonlendirmeAdresi(KaydirmaCubugu, AOlay)
    else Gorevler0.OlayEkle(KaydirmaCubugu^.GorevKimlik, AOlay);
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := KaydirmaCubugu^.FareImlecTipi;
end;

{==============================================================================
  işlem göstergesi en alt, en üst değerlerini belirler
 ==============================================================================}
procedure TKaydirmaCubugu.DegerleriBelirle(AAltDeger, AUstDeger: TISayi4);
var
  KaydirmaCubugu: PKaydirmaCubugu = nil;
begin

  KaydirmaCubugu := PKaydirmaCubugu(GorselNesneler0.NesneAl(Kimlik));
  if(KaydirmaCubugu = nil) then Exit;

  KaydirmaCubugu^.AltDeger := AAltDeger;
  KaydirmaCubugu^.UstDeger := AUstDeger;
  KaydirmaCubugu^.MevcutDeger := AAltDeger;
end;

end.
