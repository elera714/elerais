{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_durumcubugu.pas
  Dosya İşlevi: durum çubuğu (TStatusBar) yönetim işlevlerini içerir

  Güncelleme Tarihi: 26/02/2025

 ==============================================================================}
{$mode objfpc}
unit gn_durumcubugu;

interface

uses gorselnesne, paylasim, gn_panel;

type
  PDurumCubugu = ^TDurumCubugu;
  TDurumCubugu = object(TPanel)
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4; ADurumYazi: string): PDurumCubugu;
    procedure YokEt;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
  end;

function DurumCubuguCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ADurumYazi: string): TKimlik;

implementation

uses genel, gn_pencere, gn_islevler, temelgorselnesne, hamresim;

{==============================================================================
  durum çubuğu kesme çağrılarını yönetir
 ==============================================================================}
function DurumCubuguCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne;
  DurumCubugu: PDurumCubugu;
  p1: PKarakterKatari;
begin

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GN^.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^,
        PKarakterKatari(PSayi4(ADegiskenler + 20)^ + CalisanGorevBellekAdresi)^);
    end;

    ISLEV_GOSTER:
    begin

      DurumCubugu := PDurumCubugu(DurumCubugu^.NesneAl(PKimlik(ADegiskenler + 00)^));
      DurumCubugu^.Goster;
    end;

    // durum çubuğundaki veriyi değiştir
    $010F:
    begin

      DurumCubugu := PDurumCubugu(DurumCubugu^.NesneAl(PKimlik(ADegiskenler + 00)^));
      p1 := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi);
      DurumCubugu^.Baslik := p1^;
      DurumCubugu^.Ciz;
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  durum çubuğu nesnesini oluşturur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ADurumYazi: string): TKimlik;
var
  DurumCubugu: PDurumCubugu;
begin

  DurumCubugu := DurumCubugu^.Olustur(ktNesne, AAtaNesne, ASol, AUst,
    AGenislik, AYukseklik, ADurumYazi);

  if(DurumCubugu = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := DurumCubugu^.Kimlik;
end;

{==============================================================================
  durum çubuğu nesnesini oluşturur
 ==============================================================================}
function TDurumCubugu.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4; ADurumYazi: string): PDurumCubugu;
var
  DurumCubugu: PDurumCubugu;
begin

  // nesne yüksekliği 2px olarak sabitlendi
  AYukseklik := 20;

  DurumCubugu := PDurumCubugu(inherited Olustur(AKullanimTipi, AAtaNesne, ASol, AUst,
    AGenislik, AYukseklik, 2, $D4D0C8, $D4D0C8, 0, ''));

  DurumCubugu^.NesneTipi := gntDurumCubugu;

  DurumCubugu^.Baslik := ADurumYazi;

  DurumCubugu^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  DurumCubugu^.Odaklanilabilir := False;
  DurumCubugu^.Odaklanildi := False;

  DurumCubugu^.OlayCagriAdresi := @OlaylariIsle;

  DurumCubugu^.FHiza := hzAlt;                        // alta hizala

  // nesne adresini geri döndür
  Result := DurumCubugu;
end;

{==============================================================================
  durum çubuğu nesnesini yok eder
 ==============================================================================}
procedure TDurumCubugu.YokEt;
begin

  inherited YokEt;
end;

{==============================================================================
  durum çubuğu nesnesini görüntüler
 ==============================================================================}
procedure TDurumCubugu.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  durum çubuğu nesnesini gizler
 ==============================================================================}
procedure TDurumCubugu.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  durum çubuğu nesnesini hizalandırır
 ==============================================================================}
procedure TDurumCubugu.Hizala;
var
  DurumCubugu: PDurumCubugu;
begin

  DurumCubugu := PDurumCubugu(DurumCubugu^.NesneAl(Kimlik));
  if(DurumCubugu = nil) then Exit;

  inherited Hizala;
end;

{==============================================================================
  durum çubuğu nesnesini çizer
 ==============================================================================}
procedure TDurumCubugu.Ciz;
var
  DurumCubugu: PDurumCubugu;
  Alan: TAlan;
  Renk: PRenk;
  Sol, Ust, Yatay, Dikey: TISayi4;
begin

  DurumCubugu := PDurumCubugu(DurumCubugu^.NesneAl(Kimlik));
  if(DurumCubugu = nil) then Exit;

  inherited Ciz;

  // durum çubuğunun çizim alan koordinatlarını al
  Alan := DurumCubugu^.FCizimAlan;

  Yatay := Alan.Sag - 12 - 1;
  Dikey := Alan.Alt - 12 - 1;

  Renk := PRenk(@DurumCubuguResim);
  for Ust := 1 to 12 do
  begin

    for Sol := 1 to 12 do
    begin

      if not(Renk^ = $FFFFFFFF) then PixelYaz(DurumCubugu, Yatay + Sol, Dikey + Ust, Renk^);
      Inc(Renk);
    end;
  end;

  // durum çubuğu başlığı
  YaziYaz(DurumCubugu, Alan.Sol + 3, Alan.Ust + 2, DurumCubugu^.Baslik, RENK_SIYAH);
end;

{==============================================================================
  durum çubuğu olaylarını işler
 ==============================================================================}
procedure TDurumCubugu.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere;
  DurumCubugu: PDurumCubugu;
begin

  DurumCubugu := PDurumCubugu(AGonderici);

  // farenin sol tuşuna basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // durum çubuğunun sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(DurumCubugu);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    if(FareNesneOlayAlanindaMi(DurumCubugu)) then
    begin

      // fare olaylarını yakala
      OlayYakalamayaBasla(DurumCubugu);
    end;
  end
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // farenin tuş bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(DurumCubugu^.FareNesneOlayAlanindaMi(DurumCubugu)) then
    begin

      // uygulamaya veya efendi nesneye mesaj gönder
      AOlay.Olay := FO_TIKLAMA;
      if not(DurumCubugu^.OlayYonlendirmeAdresi = nil) then
        DurumCubugu^.OlayYonlendirmeAdresi(DurumCubugu, AOlay)
      else GorevListesi[DurumCubugu^.GorevKimlik]^.OlayEkle(DurumCubugu^.GorevKimlik, AOlay);
    end;

    // fare olaylarını almayı bırak
    OlayYakalamayiBirak(DurumCubugu);
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := DurumCubugu^.FFareImlecTipi;
end;

end.
