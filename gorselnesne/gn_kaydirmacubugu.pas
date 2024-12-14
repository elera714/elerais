{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: gn_kaydirmacubugu.pp
  Dosya Ýþlevi: kaydýrma çubuðu (TScrollBar) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
unit gn_kaydirmacubugu;

interface

uses gorselnesne, paylasim, gn_pencere, gn_panel, gn_resimdugmesi;

type
  PKaydirmaCubugu = ^TKaydirmaCubugu;
  TKaydirmaCubugu = object(TPanel)
  private
    procedure ResimDugmesiOlaylariniIsle(AGonderici: PGorselNesne; AOlay: TOlay);
  public
    FYon: TYon;
    FMevcutDeger, FAltDeger, FUstDeger: TISayi4;
    FEksiltmeDugmesi, FArtirmaDugmesi: PResimDugmesi;
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne; ASol, AUst,
      AGenislik, AYukseklik: TISayi4; AYon: TYon): PKaydirmaCubugu;
    procedure YokEt;
    procedure Goster;
    procedure Gizle;
    procedure Boyutlandir;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    procedure DegerleriBelirle(AAltDeger, AUstDeger: TISayi4);
  end;

function KaydirmaCubuguCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  AYon: TYon): TKimlik;

implementation

uses genel, gn_islevler, temelgorselnesne;

{==============================================================================
  kaydýrma çubuðu kesme çaðrýlarýný yönetir
 ==============================================================================}
function KaydirmaCubuguCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GorselNesne: PGorselNesne = nil;
  Pencere: PPencere = nil;
  KaydirmaCubugu: PKaydirmaCubugu = nil;
  Hiza: THiza;
begin

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GorselNesne := GorselNesne^.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GorselNesne, PISayi4(ADegiskenler + 04)^,
        PISayi4(ADegiskenler + 08)^, PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^,
        PYon(ADegiskenler + 20)^);
    end;

    ISLEV_GOSTER:
    begin

      KaydirmaCubugu := PKaydirmaCubugu(KaydirmaCubugu^.NesneAl(PKimlik(ADegiskenler + 00)^));
      KaydirmaCubugu^.Goster;
    end;

    ISLEV_HIZALA:
    begin

      KaydirmaCubugu := PKaydirmaCubugu(KaydirmaCubugu^.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      KaydirmaCubugu^.FHiza := Hiza;

      Pencere := PPencere(KaydirmaCubugu^.FAtaNesne);
      Pencere^.Guncelle;
    end;

    // alt, üst deðerlerini belirle
    $010F:
    begin

      KaydirmaCubugu := PKaydirmaCubugu(KaydirmaCubugu^.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntKaydirmaCubugu));
      if(KaydirmaCubugu <> nil) then KaydirmaCubugu^.DegerleriBelirle(
        PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^);
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  kaydýrma çubuðu nesnesini oluþturur
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
  kaydýrma çubuðu nesnesini oluþturur
 ==============================================================================}
function TKaydirmaCubugu.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4; AYon: TYon): PKaydirmaCubugu;
var
  KaydirmaCubugu: PKaydirmaCubugu = nil;
  Genislik, Yukseklik: TISayi4;
begin

  Yukseklik := AYukseklik;
  Genislik := AGenislik;

  // dikey kaydýrma çubuðunun geniþliði 15px (0..15 = 16px) olarak sabitleniyor
  if(AYon = yDikey) then
    Genislik := 16
  else Genislik := AGenislik;

  // yatay kaydýrma çubuðunun yüksekliði 15px (0..15 = 16px) olarak sabitleniyor
  if(AYon = yYatay) then
    Yukseklik := 16
  else Yukseklik := AYukseklik;

  KaydirmaCubugu := PKaydirmaCubugu(inherited Olustur(AKullanimTipi, AAtaNesne,
    ASol, AUst, Genislik, Yukseklik, 3, RENK_GUMUS, RENK_BEYAZ, 0, ''));

  // görsel nesne tipi
  KaydirmaCubugu^.NesneTipi := gntKaydirmaCubugu;

  KaydirmaCubugu^.Baslik := '';

  KaydirmaCubugu^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  KaydirmaCubugu^.OlayCagriAdresi := @OlaylariIsle;

  KaydirmaCubugu^.FYon := AYon;

  if(AYon = yYatay) then
  begin

    // $10000000 + 4 = sol ok resmi
    KaydirmaCubugu^.FEksiltmeDugmesi := FEksiltmeDugmesi^.Olustur(ktBilesen, KaydirmaCubugu,
      0, 0, 15, Yukseklik, $10000000 + 4, True);
    KaydirmaCubugu^.FEksiltmeDugmesi^.OlayYonlendirmeAdresi := @ResimDugmesiOlaylariniIsle;

    // $10000000 + 3 = sað ok resmi
    KaydirmaCubugu^.FArtirmaDugmesi := FArtirmaDugmesi^.Olustur(ktBilesen, KaydirmaCubugu,
      Genislik - 15, 0, 15, Yukseklik, $10000000 + 3, True);
    KaydirmaCubugu^.FArtirmaDugmesi^.OlayYonlendirmeAdresi := @ResimDugmesiOlaylariniIsle;
  end
  else
  begin

    // $10000000 + 4 = yukarý ok resmi
    KaydirmaCubugu^.FEksiltmeDugmesi := FEksiltmeDugmesi^.Olustur(ktBilesen, KaydirmaCubugu,
      0, 0, 15, 15, $10000000 + 1, True);
    KaydirmaCubugu^.FEksiltmeDugmesi^.OlayYonlendirmeAdresi := @ResimDugmesiOlaylariniIsle;

    // $10000000 + 3 = aþaðý ok resmi
    KaydirmaCubugu^.FArtirmaDugmesi := FArtirmaDugmesi^.Olustur(ktBilesen, KaydirmaCubugu,
      0, Yukseklik - 15, 15, 15, $10000000 + 2, True);
    KaydirmaCubugu^.FArtirmaDugmesi^.OlayYonlendirmeAdresi := @ResimDugmesiOlaylariniIsle;
  end;

  KaydirmaCubugu^.FMevcutDeger := 0;
  KaydirmaCubugu^.FAltDeger := 0;
  KaydirmaCubugu^.FUstDeger := 100;

  // nesne adresini geri döndür
  Result := KaydirmaCubugu;
end;

{==============================================================================
  kaydýrma çubuðu nesnesini yok eder
 ==============================================================================}
procedure TKaydirmaCubugu.YokEt;
begin

  inherited YokEt;
end;

{==============================================================================
  kaydýrma çubuðu nesnesini görüntüler
 ==============================================================================}
procedure TKaydirmaCubugu.Goster;
var
  KaydirmaCubugu: PKaydirmaCubugu = nil;
begin

  KaydirmaCubugu := PKaydirmaCubugu(KaydirmaCubugu^.NesneAl(Kimlik));
  if(KaydirmaCubugu = nil) then Exit;

  KaydirmaCubugu^.FArtirmaDugmesi^.Goster;
  KaydirmaCubugu^.FEksiltmeDugmesi^.Goster;

  inherited Goster;
end;

{==============================================================================
  kaydýrma çubuðu nesnesini gizler
 ==============================================================================}
procedure TKaydirmaCubugu.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  kaydýrma çubuðu nesnesini boyutlandýrýr
 ==============================================================================}
procedure TKaydirmaCubugu.Boyutlandir;
var
  KaydirmaCubugu: PKaydirmaCubugu = nil;
begin

  KaydirmaCubugu := PKaydirmaCubugu(KaydirmaCubugu^.NesneAl(Kimlik));
  if(KaydirmaCubugu = nil) then Exit;

  if(KaydirmaCubugu^.FYon = yYatay) then
  begin

    KaydirmaCubugu^.FEksiltmeDugmesi^.FKonum.Sol := 0;
    KaydirmaCubugu^.FEksiltmeDugmesi^.FKonum.Ust := 0;
    KaydirmaCubugu^.FEksiltmeDugmesi^.FBoyut.Genislik := 16;
    KaydirmaCubugu^.FEksiltmeDugmesi^.FBoyut.Yukseklik := 16;
    KaydirmaCubugu^.FEksiltmeDugmesi^.BoyutlariYenidenHesapla;

    KaydirmaCubugu^.FArtirmaDugmesi^.FKonum.Sol := KaydirmaCubugu^.FBoyut.Genislik - 16;
    KaydirmaCubugu^.FArtirmaDugmesi^.FKonum.Ust := 0;
    KaydirmaCubugu^.FArtirmaDugmesi^.FBoyut.Genislik := 16;
    KaydirmaCubugu^.FArtirmaDugmesi^.FBoyut.Yukseklik := 16;
    KaydirmaCubugu^.FArtirmaDugmesi^.BoyutlariYenidenHesapla;
  end
  else if(KaydirmaCubugu^.FYon = yDikey) then
  begin

    KaydirmaCubugu^.FEksiltmeDugmesi^.FKonum.Sol := 0;
    KaydirmaCubugu^.FEksiltmeDugmesi^.FKonum.Ust := 0;
    KaydirmaCubugu^.FEksiltmeDugmesi^.FBoyut.Genislik := 16;
    KaydirmaCubugu^.FEksiltmeDugmesi^.FBoyut.Yukseklik := 16;
    KaydirmaCubugu^.FEksiltmeDugmesi^.BoyutlariYenidenHesapla;

    KaydirmaCubugu^.FArtirmaDugmesi^.FKonum.Sol := 0;
    KaydirmaCubugu^.FArtirmaDugmesi^.FKonum.Ust := KaydirmaCubugu^.FBoyut.Yukseklik - 16;
    KaydirmaCubugu^.FArtirmaDugmesi^.FBoyut.Genislik := 16;
    KaydirmaCubugu^.FArtirmaDugmesi^.FBoyut.Yukseklik := 16;
    KaydirmaCubugu^.FArtirmaDugmesi^.BoyutlariYenidenHesapla;
  end;
end;

{==============================================================================
  kaydýrma çubuðu nesnesini çizer
 ==============================================================================}
procedure TKaydirmaCubugu.Ciz;
var
  KaydirmaCubugu: PKaydirmaCubugu = nil;
  Alan: TAlan;
  Frekans: Double;
  AraBoslukU, i: TISayi4;
begin

  inherited Ciz;

  KaydirmaCubugu := PKaydirmaCubugu(KaydirmaCubugu^.NesneAl(Kimlik));
  if(KaydirmaCubugu = nil) then Exit;

  // kaydýrma çubuðunun çizim alan koordinatlarýný al
  Alan := KaydirmaCubugu^.FCizimAlan;

  if(KaydirmaCubugu^.FYon = yDikey) then
  begin

    AraBoslukU := KaydirmaCubugu^.FBoyut.Yukseklik - (16 * 3);
    Frekans := AraBoslukU / KaydirmaCubugu^.FUstDeger;

    i := Round(KaydirmaCubugu^.FMevcutDeger * Frekans);

    DikdortgenDoldur(KaydirmaCubugu, Alan.Sol + 2, Alan.Ust + 16 + i,
      Alan.Sag - 2, Alan.Ust + 16 + i + 16, $7F7F7F, $7F7F7F);
  end
  else
  begin

    AraBoslukU := KaydirmaCubugu^.FBoyut.Genislik - (16 * 3);
    Frekans := AraBoslukU / KaydirmaCubugu^.FUstDeger;

    i := Round(KaydirmaCubugu^.FMevcutDeger * Frekans);

    DikdortgenDoldur(KaydirmaCubugu, Alan.Sol + 16 + i, Alan.Ust + 2,
      Alan.Sol + 16 + i + 16, Alan.Alt - 2, $7F7F7F, $7F7F7F);
  end;
end;

{==============================================================================
  kaydýrma çubuðu nesne olaylarýný iþler
 ==============================================================================}
procedure TKaydirmaCubugu.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere = nil;
  KaydirmaCubugu: PKaydirmaCubugu = nil;
begin

  KaydirmaCubugu := PKaydirmaCubugu(AGonderici);
  if(KaydirmaCubugu = nil) then Exit;

  // farenin sol tuþuna basým iþlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // kaydýrma çubuðunun sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(KaydirmaCubugu);

    // en üstte olmamasý durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> AktifPencere) then Pencere^.EnUsteGetir(Pencere);
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := KaydirmaCubugu^.FFareImlecTipi;
end;

{==============================================================================
  kaydýrma çubuðunun sahip olduðu artýrma / eksiltme nesne olaylarýný iþler
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

      i := KaydirmaCubugu^.FMevcutDeger;
      Dec(i);
      if(i < KaydirmaCubugu^.FAltDeger) then i := KaydirmaCubugu^.FAltDeger;
    end
    else
    begin

      i := KaydirmaCubugu^.FMevcutDeger;
      Inc(i);
      if(i > KaydirmaCubugu^.FUstDeger) then i := KaydirmaCubugu^.FUstDeger;
    end;

    KaydirmaCubugu^.FMevcutDeger := i;

    KaydirmaCubugu^.Ciz;

    AOlay.Kimlik := KaydirmaCubugu^.Kimlik;
    AOlay.Deger1 := KaydirmaCubugu^.FMevcutDeger;

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(KaydirmaCubugu^.OlayYonlendirmeAdresi = nil) then
      KaydirmaCubugu^.OlayYonlendirmeAdresi(KaydirmaCubugu, AOlay)
    else GorevListesi[KaydirmaCubugu^.GorevKimlik]^.OlayEkle(KaydirmaCubugu^.GorevKimlik, AOlay);
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := KaydirmaCubugu^.FFareImlecTipi;
end;

{==============================================================================
  iþlem göstergesi en alt, en üst deðerlerini belirler
 ==============================================================================}
procedure TKaydirmaCubugu.DegerleriBelirle(AAltDeger, AUstDeger: TISayi4);
var
  KaydirmaCubugu: PKaydirmaCubugu = nil;
begin

  KaydirmaCubugu := PKaydirmaCubugu(KaydirmaCubugu^.NesneAl(Kimlik));
  if(KaydirmaCubugu = nil) then Exit;

  KaydirmaCubugu^.FAltDeger := AAltDeger;
  KaydirmaCubugu^.FUstDeger := AUstDeger;
  KaydirmaCubugu^.FMevcutDeger := AAltDeger;
end;

end.
