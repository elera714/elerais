{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_secimdugmesi.pas
  Dosya İşlevi: seçim düğmesi (TRadioButton) yönetim işlevlerini içerir

  Güncelleme Tarihi: 26/02/2025

 ==============================================================================}
{$mode objfpc}
unit gn_secimdugmesi;

interface

uses gorselnesne, paylasim, gn_panel;

const
  SecimDugmeNormal: array[1..12, 1..12] of TSayi1 = (
    (0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0),
    (0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0),
    (0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0),
    (0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0),
    (1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1),
    (1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1),
    (1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1),
    (1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1),
    (0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0),
    (0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0),
    (0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0),
    (0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0));

  SecimDugmeSecili: array[1..12, 1..12] of TSayi1 = (
    (0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0),
    (0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0),
    (0, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 0),
    (0, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 0),
    (1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1),
    (1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1),
    (1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1),
    (1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1),
    (0, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 0),
    (0, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 0),
    (0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0),
    (0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0));

type
  PSecimDugmesi = ^TSecimDugmesi;
  TSecimDugmesi = object(TPanel)
  private
    FSecimDurumu: TSecimDurumu;
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst: TISayi4; ABaslik: string): PSecimDugmesi;
    procedure YokEt;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
  end;

function SecimDugmeCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst: TISayi4; ABaslik: string): TKimlik;

implementation

uses genel, gn_pencere, gn_islevler, temelgorselnesne, gorev;

{==============================================================================
  seçim düğmesi çağrılarını yönetir
 ==============================================================================}
function SecimDugmeCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne;
  Pencere: PPencere;
  SecimDugmesi: PSecimDugmesi;
begin

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GN^.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PKarakterKatari(PSayi4(ADegiskenler + 12)^ + FAktifGorevBellekAdresi)^);
    end;

    ISLEV_GOSTER:
    begin

      SecimDugmesi := PSecimDugmesi(SecimDugmesi^.NesneAl(PKimlik(ADegiskenler + 00)^));
      SecimDugmesi^.Goster;
    end;

    $010F:
    begin

      SecimDugmesi := PSecimDugmesi(SecimDugmesi^.NesneAl(PKimlik(ADegiskenler + 00)^));
      SecimDugmesi^.FSecimDurumu := PSecimDurumu(ADegiskenler + 04)^;

      Pencere := PPencere(SecimDugmesi^.AtaNesne);
      if not(Pencere = nil) then Pencere^.Guncelle;
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  seçim düğmesi nesnesini oluşturur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst: TISayi4; ABaslik: string): TKimlik;
var
  SecimDugmesi: PSecimDugmesi;
begin

  SecimDugmesi := SecimDugmesi^.Olustur(ktNesne, AAtaNesne, ASol, AUst, ABaslik);

  if(SecimDugmesi = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := SecimDugmesi^.Kimlik;
end;

{==============================================================================
  seçim düğmesi nesnesini oluşturur
 ==============================================================================}
function TSecimDugmesi.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst: TISayi4; ABaslik: string): PSecimDugmesi;
var
  SecimDugmesi: PSecimDugmesi;
  Genislik: TSayi4;
begin

  Genislik := 16 + 4 + (Length(ABaslik) * 8);

  SecimDugmesi := PSecimDugmesi(inherited Olustur(AKullanimTipi, AAtaNesne, ASol, AUst,
    Genislik, 16, 0, 0, 0, 0, ABaslik));

  SecimDugmesi^.NesneTipi := gntSecimDugmesi;

  SecimDugmesi^.Baslik := ABaslik;

  SecimDugmesi^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  SecimDugmesi^.Odaklanilabilir := True;
  SecimDugmesi^.Odaklanildi := False;

  SecimDugmesi^.OlayCagriAdresi := @OlaylariIsle;

  SecimDugmesi^.FSecimDurumu := sdNormal;

  // nesne adresini geri döndür
  Result := SecimDugmesi;
end;

{==============================================================================
  seçim düğmesi nesnesini yok eder
 ==============================================================================}
procedure TSecimDugmesi.YokEt;
begin

  inherited YokEt;
end;

{==============================================================================
  seçim düğmesi nesnesini görüntüler
 ==============================================================================}
procedure TSecimDugmesi.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  seçim düğmesi nesnesini gizler
 ==============================================================================}
procedure TSecimDugmesi.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  seçim düğmesi nesnesini hizalandırır
 ==============================================================================}
procedure TSecimDugmesi.Hizala;
begin

end;

{==============================================================================
  seçim düğmesi nesnesini çizer
 ==============================================================================}
procedure TSecimDugmesi.Ciz;
var
  SecimDugmesi: PSecimDugmesi;
  Alan: TAlan;
  Y, D: TISayi4;      // Yatay / Dikey
  p1: PSayi1;
begin

  SecimDugmesi := PSecimDugmesi(SecimDugmesi^.NesneAl(Kimlik));
  if(SecimDugmesi = nil) then Exit;

  // seçim düğmesi üst nesneye bağlı olarak koordinatlarını al
  Alan := SecimDugmesi^.FCizimAlan;

  // seçim düğmesi çizim
  if(SecimDugmesi^.FSecimDurumu = sdNormal) then
  begin

    p1 := PByte(@SecimDugmeNormal);
    for D := 1 to 12 do
    begin

      for Y := 1 to 12 do
      begin

        if(p1^ = 1) then PixelYaz(SecimDugmesi, Alan.Sol + 1 + Y, Alan.Ust + 1 + D, $6485B5);
        Inc(p1);
      end;
    end;
  end
  else if(SecimDugmesi^.FSecimDurumu = sdSecili) then
  begin

    p1 := PByte(@SecimDugmeSecili);
    for D := 1 to 12 do
    begin

      for Y := 1 to 12 do
      begin

        if(p1^ = 1) then PixelYaz(SecimDugmesi, Alan.Sol + 1 + Y, Alan.Ust + 1 + D, $6485B5);
        Inc(p1);
      end;
    end;
  end;

  // seçim düğmesi başlığı
  if(Length(SecimDugmesi^.Baslik) > 0) then YaziYaz(SecimDugmesi, Alan.Sol + 20,
    Alan.Ust + 2, SecimDugmesi^.Baslik, RENK_SIYAH);
end;

{==============================================================================
  seçim düğmesi nesne olaylarını işler
 ==============================================================================}
procedure TSecimDugmesi.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere;
  SecimDugmesi: PSecimDugmesi;
begin

  SecimDugmesi := PSecimDugmesi(AGonderici);
  if(SecimDugmesi = nil) then Exit;

  // farenin sol tuşuna basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // seçim düğmesinin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(SecimDugmesi);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere^.FAktifNesne := SecimDugmesi;
    SecimDugmesi^.Odaklanildi := True;

    // sol tuşa basım işlemi nesnenin olay alanında mı gerçekleşti ?
    if(SecimDugmesi^.FareNesneOlayAlanindaMi(SecimDugmesi)) then
      OlayYakalamayaBasla(SecimDugmesi);
  end
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    OlayYakalamayiBirak(SecimDugmesi);

    // farenin tuş bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(SecimDugmesi^.FareNesneOlayAlanindaMi(SecimDugmesi)) then
    begin

      // sadece seçim durumu normal (seçili değil) olduğunda işlem yap
      if(SecimDugmesi^.FSecimDurumu = sdNormal) then
      begin

        SecimDugmesi^.FSecimDurumu := sdSecili;

        SecimDugmesi^.Ciz;

        AOlay.Olay := CO_DURUMDEGISTI;
        AOlay.Deger1 := TISayi4(sdSecili);

        // nesnenin olay çağrı adresini çağır veya uygulamaya mesaj gönder
        if not(SecimDugmesi^.OlayYonlendirmeAdresi = nil) then
          SecimDugmesi^.OlayYonlendirmeAdresi(SecimDugmesi, AOlay)
        else GorevListesi[SecimDugmesi^.GorevKimlik]^.OlayEkle(SecimDugmesi^.GorevKimlik, AOlay);
      end;
    end;
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := SecimDugmesi^.FFareImlecTipi;
end;

end.
