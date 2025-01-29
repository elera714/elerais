{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_resim.pas
  Dosya İşlevi: resim (TImage) nesne yönetim işlevlerini içerir

  Güncelleme Tarihi: 27/01/2025

 ==============================================================================}
{$mode objfpc}
unit gn_resim;

interface

uses gorselnesne, paylasim, temelgorselnesne, gn_panel;

type
  PResim = ^TResim;
  TResim = object(TPanel)
  public
    FTuvaleSigdir: LongBool;
    FGoruntuYapi: TGoruntuYapi;
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4; ADosyaYolu: string): PResim;
    procedure YokEt;
    procedure Goster;
    procedure Gizle;
    procedure Boyutlandir;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    procedure ResimYaz(ADosyaYolu: string);
  end;

function ResimCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ADosyaYolu: string): TKimlik;

implementation

uses genel, gn_pencere, gn_islevler, bmp;

{==============================================================================
  resim nesnesi kesme çağrılarını yönetir
 ==============================================================================}
function ResimCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GorselNesne: PGorselNesne;
  Pencere: PPencere;
  Resim: PResim;
  Hiza: THiza;
  p: PKarakterKatari;
  TuvaleSigdir: Boolean;
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

      Resim := PResim(Resim^.NesneAl(PKimlik(ADegiskenler + 00)^));
      Resim^.Goster;
    end;

    ISLEV_HIZALA:
    begin

      Resim := PResim(Resim^.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      Resim^.FHiza := Hiza;

      Pencere := PPencere(Resim^.FAtaNesne);
      Pencere^.Guncelle;
    end;

    // resmi değiştir
    $010F:
    begin

      Resim := PResim(Resim^.NesneAl(PKimlik(ADegiskenler + 00)^));
      p := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi);
      Resim^.ResimYaz(p^);
    end;

    $020F:
    begin

      Resim := PResim(Resim^.NesneAl(PKimlik(ADegiskenler + 00)^));
      TuvaleSigdir := PLongBool(ADegiskenler + 04)^;
      Resim^.FTuvaleSigdir := TuvaleSigdir;

      Pencere := PPencere(Resim^.FAtaNesne);
      Pencere^.Guncelle;
    end;

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  resim nesnesini oluşturur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ADosyaYolu: string): TKimlik;
var
  Resim: PResim;
begin

  Resim := Resim^.Olustur(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik, ADosyaYolu);

  if(Resim = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := Resim^.Kimlik;
end;

{==============================================================================
  resim nesnesini oluşturur
 ==============================================================================}
function TResim.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4; ADosyaYolu: string): PResim;
var
  Resim: PResim;
begin

  Resim := PResim(inherited Olustur(AKullanimTipi, AAtaNesne, ASol, AUst, AGenislik,
    AYukseklik, 2, RENK_BEYAZ, RENK_BEYAZ, 0, ''));

  // görsel nesne tipi
  Resim^.NesneTipi := gntResim;

  Resim^.Baslik := '';

  Resim^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  Resim^.OlayCagriAdresi := @OlaylariIsle;

  Resim^.FTuvaleSigdir := False;

  Resim^.FCizimBaslangic.Sol := Resim^.AtaNesne^.FCizimBaslangic.Sol +
    Resim^.AtaNesne^.FKalinlik.Sol + ASol;
  Resim^.FCizimBaslangic.Ust := Resim^.AtaNesne^.FCizimBaslangic.Ust +
    Resim^.AtaNesne^.FKalinlik.Ust + AUst;

  Resim^.FGoruntuYapi.BellekAdresi := nil;

  // eğer dosya adı belirtilmişse, dosyayı yükle
  if(Length(ADosyaYolu) > 0) then ResimYaz(ADosyaYolu);

  // nesne adresini geri döndür
  Result := Resim;
end;

{==============================================================================
  resim nesnesini yok eder
 ==============================================================================}
procedure TResim.YokEt;
begin

  inherited YokEt;
end;

{==============================================================================
  resim nesnesini görüntüler
 ==============================================================================}
procedure TResim.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  resim nesnesini gizler
 ==============================================================================}
procedure TResim.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  resim nesnesini boyutlandırır
 ==============================================================================}
procedure TResim.Boyutlandir;
var
  Resim: PResim;
begin

  Resim := PResim(Resim^.NesneAl(Kimlik));
  if(Resim = nil) then Exit;

  Resim^.Hizala;
end;

{==============================================================================
  resim nesnesini çizer
 ==============================================================================}
procedure TResim.Ciz;
var
  Resim: PResim;
begin

  Resim := PResim(Resim^.NesneAl(Kimlik));
  if(Resim = nil) then Exit;

  inherited Ciz;

  if(Resim^.Gorunum) then
  begin

    if not(Resim^.FGoruntuYapi.BellekAdresi = nil) then
      ResimCiz(gntResim, Resim, Resim^.FGoruntuYapi);
  end;
end;

{==============================================================================
  resim nesne olaylarını işler
 ==============================================================================}
procedure TResim.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere;
  Resim: PResim;
begin

  Resim := PResim(AGonderici);
  if(Resim = nil) then Exit;

  // farenin sol tuşuna basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // resim nesnesinin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(Resim);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve pencerenin aktif nesnesini nil olarak işaretle
    GAktifNesne := nil;

    // fare olaylarını yakala
    OlayYakalamayaBasla(Resim);

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(Resim^.OlayYonlendirmeAdresi = nil) then
      Resim^.OlayYonlendirmeAdresi(Resim, AOlay)
    else GorevListesi[Resim^.GorevKimlik]^.OlayEkle(Resim^.GorevKimlik, AOlay);
  end
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    OlayYakalamayiBirak(Resim);

    // farenin tuş bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(Resim^.FareNesneOlayAlanindaMi(Resim)) then
    begin

      // yakalama & bırakma işlemi bu nesnede olduğu için
      // nesneye FO_TIKLAMA mesajı gönder
      AOlay.Olay := FO_TIKLAMA;
      if not(Resim^.OlayYonlendirmeAdresi = nil) then
        Resim^.OlayYonlendirmeAdresi(Resim, AOlay)
      else GorevListesi[Resim^.GorevKimlik]^.OlayEkle(Resim^.GorevKimlik, AOlay);
    end;

    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    if not(Resim^.OlayYonlendirmeAdresi = nil) then
      Resim^.OlayYonlendirmeAdresi(Resim, AOlay)
    else GorevListesi[Resim^.GorevKimlik]^.OlayEkle(Resim^.GorevKimlik, AOlay);
  end
  else if(AOlay.Olay = FO_HAREKET) then
  begin

    if not(Resim^.OlayYonlendirmeAdresi = nil) then
      Resim^.OlayYonlendirmeAdresi(Resim, AOlay)
    else GorevListesi[Resim^.GorevKimlik]^.OlayEkle(Resim^.GorevKimlik, AOlay);
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := Resim^.FFareImlecTipi;
end;

{==============================================================================
  resim değerini belirler
 ==============================================================================}
procedure TResim.ResimYaz(ADosyaYolu: string);
var
  Resim: PResim;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  Resim := PResim(Resim^.NesneAl(Kimlik));
  if(Resim = nil) then Exit;

  // daha önce resim için bellek rezerv edildiyse belleği iptal et
  if not(Resim^.FGoruntuYapi.BellekAdresi = nil) then
  begin

    GGercekBellek.YokEt(Resim^.FGoruntuYapi.BellekAdresi, Resim^.FGoruntuYapi.Genislik *
      Resim^.FGoruntuYapi.Yukseklik * 4);
    Resim^.FGoruntuYapi.BellekAdresi := nil;
  end;

  if(Length(ADosyaYolu) > 0) then Resim^.FGoruntuYapi := BMPDosyasiYukle(ADosyaYolu);

  Ciz;
end;

end.
