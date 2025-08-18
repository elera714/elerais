{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: gn_kaydirmacubugu.pp
  Dosya ��levi: kayd�rma �ubu�u (TScrollBar) y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 26/02/2025

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

uses genel, gn_islevler, temelgorselnesne;

{==============================================================================
  kayd�rma �ubu�u kesme �a�r�lar�n� y�netir
 ==============================================================================}
function KaydirmaCubuguCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne = nil;
  Pencere: PPencere = nil;
  KaydirmaCubugu: PKaydirmaCubugu = nil;
  Hiza: THiza;
begin

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

    // alt, �st de�erlerini belirle
    $010F:
    begin

      KaydirmaCubugu := PKaydirmaCubugu(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntKaydirmaCubugu));
      if(KaydirmaCubugu <> nil) then KaydirmaCubugu^.DegerleriBelirle(
        PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^);
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  kayd�rma �ubu�u nesnesini olu�turur
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
  kayd�rma �ubu�u nesnesini olu�turur
 ==============================================================================}
function TKaydirmaCubugu.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4; AYon: TYon): PKaydirmaCubugu;
var
  KaydirmaCubugu: PKaydirmaCubugu = nil;
  Genislik, Yukseklik: TISayi4;
begin

  Yukseklik := AYukseklik;
  Genislik := AGenislik;

  // dikey kayd�rma �ubu�unun geni�li�i 15px (0..15 = 16px) olarak sabitleniyor
  if(AYon = yDikey) then
    Genislik := 16
  else Genislik := AGenislik;

  // yatay kayd�rma �ubu�unun y�ksekli�i 15px (0..15 = 16px) olarak sabitleniyor
  if(AYon = yYatay) then
    Yukseklik := 16
  else Yukseklik := AYukseklik;

  KaydirmaCubugu := PKaydirmaCubugu(inherited Olustur(AKullanimTipi, AAtaNesne,
    ASol, AUst, Genislik, Yukseklik, 3, RENK_GUMUS, RENK_BEYAZ, 0, ''));

  // g�rsel nesne tipi
  KaydirmaCubugu^.NesneTipi := gntKaydirmaCubugu;

  KaydirmaCubugu^.Baslik := '';

  KaydirmaCubugu^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  // �u a�amada bu nesne odaklan�labilir bir nesne de�il
  KaydirmaCubugu^.Odaklanilabilir := False;
  KaydirmaCubugu^.Odaklanildi := False;

  KaydirmaCubugu^.OlayCagriAdresi := @OlaylariIsle;

  KaydirmaCubugu^.FYon := AYon;

  if(AYon = yYatay) then
  begin

    // $10000000 + 4 = sol ok resmi
    KaydirmaCubugu^.FEksiltmeDugmesi := FEksiltmeDugmesi^.Olustur(ktBilesen, KaydirmaCubugu,
      0, 0, 15, Yukseklik, $10000000 + 4, True);
    KaydirmaCubugu^.FEksiltmeDugmesi^.OlayYonlendirmeAdresi := @ResimDugmesiOlaylariniIsle;

    // $10000000 + 3 = sa� ok resmi
    KaydirmaCubugu^.FArtirmaDugmesi := FArtirmaDugmesi^.Olustur(ktBilesen, KaydirmaCubugu,
      Genislik - 15, 0, 15, Yukseklik, $10000000 + 3, True);
    KaydirmaCubugu^.FArtirmaDugmesi^.OlayYonlendirmeAdresi := @ResimDugmesiOlaylariniIsle;
  end
  else
  begin

    // $10000000 + 4 = yukar� ok resmi
    KaydirmaCubugu^.FEksiltmeDugmesi := FEksiltmeDugmesi^.Olustur(ktBilesen, KaydirmaCubugu,
      0, 0, 15, 15, $10000000 + 1, True);
    KaydirmaCubugu^.FEksiltmeDugmesi^.OlayYonlendirmeAdresi := @ResimDugmesiOlaylariniIsle;

    // $10000000 + 3 = a�a�� ok resmi
    KaydirmaCubugu^.FArtirmaDugmesi := FArtirmaDugmesi^.Olustur(ktBilesen, KaydirmaCubugu,
      0, Yukseklik - 15, 15, 15, $10000000 + 2, True);
    KaydirmaCubugu^.FArtirmaDugmesi^.OlayYonlendirmeAdresi := @ResimDugmesiOlaylariniIsle;
  end;

  KaydirmaCubugu^.MevcutDeger := 0;
  KaydirmaCubugu^.AltDeger := 0;
  KaydirmaCubugu^.UstDeger := 100;

  // nesne adresini geri d�nd�r
  Result := KaydirmaCubugu;
end;

{==============================================================================
  kayd�rma �ubu�u nesnesini yok eder
 ==============================================================================}
procedure TKaydirmaCubugu.YokEt(AKimlik: TKimlik);
begin

  GorselNesneler0.YokEt(AKimlik);
end;

{==============================================================================
  kayd�rma �ubu�u nesnesini g�r�nt�ler
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
  kayd�rma �ubu�u nesnesini gizler
 ==============================================================================}
procedure TKaydirmaCubugu.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  kayd�rma �ubu�u nesnesini hizaland�r�r
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
    KaydirmaCubugu^.FEksiltmeDugmesi^.FAtananAlan.Genislik := 16;
    KaydirmaCubugu^.FEksiltmeDugmesi^.FAtananAlan.Yukseklik := 16;
    KaydirmaCubugu^.FEksiltmeDugmesi^.BoyutlariYenidenHesapla;

    KaydirmaCubugu^.FArtirmaDugmesi^.FAtananAlan.Sol := KaydirmaCubugu^.FAtananAlan.Genislik - 16;
    KaydirmaCubugu^.FArtirmaDugmesi^.FAtananAlan.Ust := 0;
    KaydirmaCubugu^.FArtirmaDugmesi^.FAtananAlan.Genislik := 16;
    KaydirmaCubugu^.FArtirmaDugmesi^.FAtananAlan.Yukseklik := 16;
    KaydirmaCubugu^.FArtirmaDugmesi^.BoyutlariYenidenHesapla;
  end
  else if(KaydirmaCubugu^.FYon = yDikey) then
  begin

    KaydirmaCubugu^.FEksiltmeDugmesi^.FAtananAlan.Sol := 0;
    KaydirmaCubugu^.FEksiltmeDugmesi^.FAtananAlan.Ust := 0;
    KaydirmaCubugu^.FEksiltmeDugmesi^.FAtananAlan.Genislik := 16;
    KaydirmaCubugu^.FEksiltmeDugmesi^.FAtananAlan.Yukseklik := 16;
    KaydirmaCubugu^.FEksiltmeDugmesi^.BoyutlariYenidenHesapla;

    KaydirmaCubugu^.FArtirmaDugmesi^.FAtananAlan.Sol := 0;
    KaydirmaCubugu^.FArtirmaDugmesi^.FAtananAlan.Ust := KaydirmaCubugu^.FAtananAlan.Yukseklik - 16;
    KaydirmaCubugu^.FArtirmaDugmesi^.FAtananAlan.Genislik := 16;
    KaydirmaCubugu^.FArtirmaDugmesi^.FAtananAlan.Yukseklik := 16;
    KaydirmaCubugu^.FArtirmaDugmesi^.BoyutlariYenidenHesapla;
  end;
end;

{==============================================================================
  kayd�rma �ubu�u nesnesini �izer
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

  // kayd�rma �ubu�unun �izim alan koordinatlar�n� al
  CizimAlani := KaydirmaCubugu^.FCizimAlani;

  if(KaydirmaCubugu^.FYon = yDikey) then
  begin

    AraBoslukU := KaydirmaCubugu^.FAtananAlan.Yukseklik - (16 * 3);
    Frekans := AraBoslukU / KaydirmaCubugu^.UstDeger;

    i := Round(KaydirmaCubugu^.MevcutDeger * Frekans);

    DikdortgenDoldur(KaydirmaCubugu, CizimAlani.Sol + 2, CizimAlani.Ust + 16 + i,
      CizimAlani.Sag - 2, CizimAlani.Ust + 16 + i + 16, $7F7F7F, $7F7F7F);
  end
  else
  begin

    AraBoslukU := KaydirmaCubugu^.FAtananAlan.Genislik - (16 * 3);
    Frekans := AraBoslukU / KaydirmaCubugu^.UstDeger;

    i := Round(KaydirmaCubugu^.MevcutDeger * Frekans);

    DikdortgenDoldur(KaydirmaCubugu, CizimAlani.Sol + 16 + i, CizimAlani.Ust + 2,
      CizimAlani.Sol + 16 + i + 16, CizimAlani.Alt - 2, $7F7F7F, $7F7F7F);
  end;
end;

{==============================================================================
  kayd�rma �ubu�u nesne olaylar�n� i�ler
 ==============================================================================}
procedure TKaydirmaCubugu.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere = nil;
  KaydirmaCubugu: PKaydirmaCubugu = nil;
begin

  KaydirmaCubugu := PKaydirmaCubugu(AGonderici);
  if(KaydirmaCubugu = nil) then Exit;

  // farenin sol tu�una bas�m i�lemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // kayd�rma �ubu�unun sahibi olan pencere en �stte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(KaydirmaCubugu);

    // en �stte olmamas� durumunda en �ste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak i�aretle
    // bilgi: �u a�amada bu nesne odaklan�labilir bir nesne de�il
    //Pencere^.FAktifNesne := KaydirmaCubugu;
    //KaydirmaCubugu^.Odaklanildi := False;
  end;

  // ge�erli fare g�stergesini g�ncelle
  GecerliFareGostegeTipi := KaydirmaCubugu^.FareImlecTipi;
end;

{==============================================================================
  kayd�rma �ubu�unun sahip oldu�u art�rma / eksiltme nesne olaylar�n� i�ler
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

    // uygulamaya veya efendi nesneye mesaj g�nder
    if not(KaydirmaCubugu^.OlayYonlendirmeAdresi = nil) then
      KaydirmaCubugu^.OlayYonlendirmeAdresi(KaydirmaCubugu, AOlay)
    else Gorevler0.OlayEkle(KaydirmaCubugu^.GorevKimlik, AOlay);
  end;

  // ge�erli fare g�stergesini g�ncelle
  GecerliFareGostegeTipi := KaydirmaCubugu^.FareImlecTipi;
end;

{==============================================================================
  i�lem g�stergesi en alt, en �st de�erlerini belirler
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
