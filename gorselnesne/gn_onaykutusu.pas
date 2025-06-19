{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_onaykutusu.pas
  Dosya İşlevi: onay kutusu (TCheckBox) yönetim işlevlerini içerir

  Güncelleme Tarihi: 26/02/2025

 ==============================================================================}
{$mode objfpc}
unit gn_onaykutusu;

interface

uses gorselnesne, paylasim, gn_panel;

const
  ResimOnay: array[1..10, 1..10] of TSayi1 = (
    (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0, 1, 0),
    (0, 0, 0, 0, 0, 0, 0, 1, 1, 1),
    (0, 0, 0, 0, 0, 0, 1, 1, 1, 0),
    (0, 1, 0, 0, 0, 1, 1, 1, 0, 0),
    (1, 1, 1, 0, 1, 1, 1, 0, 0, 0),
    (0, 1, 1, 1, 1, 1, 0, 0, 0, 0),
    (0, 0, 1, 1, 1, 0, 0, 0, 0, 0),
    (0, 0, 0, 1, 0, 0, 0, 0, 0, 0));

type
  POnayKutusu = ^TOnayKutusu;
  TOnayKutusu = object(TPanel)
  private
    FOncekiSecimDurumu,
    FSecimDurumu: TSecimDurumu;
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst: TISayi4; ABaslik: string): POnayKutusu;
    procedure YokEt;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
  end;

function IsaretKutusuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst: TISayi4; ABaslik: string): TKimlik;

implementation

uses genel, gn_pencere, gn_islevler, temelgorselnesne, gorev;

{==============================================================================
  onay kutusu çağrılarını yönetir
 ==============================================================================}
function IsaretKutusuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne;
  OnayKutusu: POnayKutusu;
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

      OnayKutusu := POnayKutusu(OnayKutusu^.NesneAl(PKimlik(ADegiskenler + 00)^));
      OnayKutusu^.Goster;
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  onay kutusu nesnesini oluşturur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst: TISayi4; ABaslik: string): TKimlik;
var
  OnayKutusu: POnayKutusu;
begin

  OnayKutusu := OnayKutusu^.Olustur(ktNesne, AAtaNesne, ASol, AUst, ABaslik);

  if(OnayKutusu = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := OnayKutusu^.Kimlik;
end;

{==============================================================================
  onay kutusu nesnesini oluşturur
 ==============================================================================}
function TOnayKutusu.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst: TISayi4; ABaslik: string): POnayKutusu;
var
  OnayKutusu: POnayKutusu;
  Genislik: TSayi4;
begin

  Genislik := 16 + 3 + (Length(ABaslik) * 8);

  OnayKutusu := POnayKutusu(inherited Olustur(AKullanimTipi, AAtaNesne, ASol, AUst,
    Genislik, 16, 0, 0, 0, 0, ABaslik));

  OnayKutusu^.NesneTipi := gntOnayKutusu;

  OnayKutusu^.Baslik := ABaslik;

  OnayKutusu^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  OnayKutusu^.Odaklanilabilir := True;
  OnayKutusu^.Odaklanildi := False;

  OnayKutusu^.OlayCagriAdresi := @OlaylariIsle;

  OnayKutusu^.FSecimDurumu := sdNormal;

  // nesne adresini geri döndür
  Result := OnayKutusu;
end;

{==============================================================================
  onay kutusu nesnesini yok eder
 ==============================================================================}
procedure TOnayKutusu.YokEt;
begin

  inherited YokEt;
end;

{==============================================================================
  onay kutusu nesnesini görüntüler
 ==============================================================================}
procedure TOnayKutusu.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  onay kutusu nesnesini gizler
 ==============================================================================}
procedure TOnayKutusu.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  onay kutusu nesnesini hizalandırır
 ==============================================================================}
procedure TOnayKutusu.Hizala;
var
  OnayKutusu: POnayKutusu = nil;
begin

  OnayKutusu := POnayKutusu(OnayKutusu^.NesneAl(Kimlik));
  if(OnayKutusu = nil) then Exit;

  inherited Hizala;
end;

{==============================================================================
  onay kutusu nesnesini çizer
 ==============================================================================}
procedure TOnayKutusu.Ciz;
var
  OnayKutusu: POnayKutusu;
  Alan: TAlan;
  Y, D: TISayi4;      // Yatay / Dikey
  p1: PSayi1;
begin

  OnayKutusu := POnayKutusu(OnayKutusu^.NesneAl(Kimlik));
  if(OnayKutusu = nil) then Exit;

  // nesne çizim alanı
  Alan := OnayKutusu^.FCizimAlan;

  Alan.Sag := Alan.Sol + 15;
  Alan.Alt := Alan.Ust + 15;

  // onay kutusu normal durum çizimi
  if(OnayKutusu^.FSecimDurumu = sdNormal) then

    DikdortgenDoldur(OnayKutusu, Alan, RENK_GUMUS, RENK_BEYAZ)

  else if(OnayKutusu^.FSecimDurumu = sdSecili) then
  // onay kutusu seçilmiş durum çizimi
  begin

    DikdortgenDoldur(OnayKutusu, Alan, RENK_GUMUS, $6485B5);

    p1 := PByte(@ResimOnay);
    for D := 1 to 10 do
    begin

      for Y := 1 to 10 do
      begin

        if(p1^ = 1) then PixelYaz(OnayKutusu, Alan.Sol + 2 + Y, Alan.Ust + 1 + D, RENK_BEYAZ);
        Inc(p1);
      end;
    end;
  end;

  // onay kutusu başlığı
  if(Length(OnayKutusu^.Baslik) > 0) then
    YaziYaz(OnayKutusu, Alan.Sag + 3, Alan.Ust + 1, OnayKutusu^.Baslik, RENK_SIYAH);

  // nesne odaklanılmış ise nesnenin kenarlarını işaretle
  if(OnayKutusu^.Odaklanildi) then
  begin

    Alan := OnayKutusu^.FCizimAlan;
    OnayKutusu^.Dikdortgen(OnayKutusu, ctNokta, Alan, RENK_SIYAH);
  end;
end;

{==============================================================================
  onay kutusu nesne olaylarını işler
 ==============================================================================}
procedure TOnayKutusu.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere;
  OnayKutusu: POnayKutusu;
begin

  OnayKutusu := POnayKutusu(AGonderici);
  if(OnayKutusu = nil) then Exit;

  // farenin sol tuşuna basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // onay kutusu'nun sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(OnayKutusu);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere^.FAktifNesne := OnayKutusu;
    OnayKutusu^.Odaklanildi := True;

    // sol tuşa basım işlemi nesnenin olay alanında mı gerçekleşti ?
    if(OnayKutusu^.FareNesneOlayAlanindaMi(OnayKutusu)) then
    begin

      // fare olaylarını yakala
      OlayYakalamayaBasla(OnayKutusu);

      // mevcut durum değerini sakla
      FOncekiSecimDurumu := OnayKutusu^.FSecimDurumu;

      if(OnayKutusu^.FSecimDurumu = sdNormal) then
        OnayKutusu^.FSecimDurumu := sdSecili
      else OnayKutusu^.FSecimDurumu := sdNormal;

      // onay kutusu nesnesini yeniden çiz
      OnayKutusu^.Ciz;
    end;
  end
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    OlayYakalamayiBirak(OnayKutusu);

    // farenin tuş bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(OnayKutusu^.FareNesneOlayAlanindaMi(OnayKutusu)) then
    begin

      // yakalama & bırakma işlemi bu nesnede olduğu için
      // nesneye durum değişiklik mesajı gönder
      AOlay.Olay := CO_DURUMDEGISTI;
      if(OnayKutusu^.FSecimDurumu = sdNormal) then
        AOlay.Deger1 := 0
      else AOlay.Deger1 := 1;

      // nesnenin olay çağrı adresini çağır veya uygulamaya mesaj gönder
      if not(OnayKutusu^.OlayYonlendirmeAdresi = nil) then
        OnayKutusu^.OlayYonlendirmeAdresi(OnayKutusu, AOlay)
      else GorevListesi[OnayKutusu^.GorevKimlik]^.OlayEkle(OnayKutusu^.GorevKimlik, AOlay);

    // aksi durumda onay kutusu durumunu bir önceki duruma getir
    end else OnayKutusu^.FSecimDurumu := OnayKutusu^.FOncekiSecimDurumu;

    // onay kutusu nesnesini yeniden çiz
    OnayKutusu^.Ciz;
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := OnayKutusu^.FFareImlecTipi;
end;

end.
