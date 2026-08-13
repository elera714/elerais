{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_renksecici.pas
  Dosya İşlevi: renk seçim yönetim işlevlerini içerir

  Güncelleme Tarihi: 12/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_renksecici;

interface

uses gorev, gorselnesne, paylasim, gn_panel;

const
  SecimRenkleri: array[0..15] of TRenk = (
    RENK_BEYAZ, RENK_GUMUS, RENK_GRI, RENK_SIYAH,
    RENK_KIRMIZI, RENK_BORDO, RENK_SARI, RENK_ZEYTINYESILI,
    RENK_ACIKYESIL, RENK_YESIL, RENK_ACIKMAVI, RENK_TURKUAZ,
    RENK_MAVI, RENK_LACIVERT, RENK_PEMBE, RENK_MOR);

  KenarRenkleri: array[0..15] of TRenk = (
    RENK_SIYAH, RENK_SIYAH, RENK_BEYAZ, RENK_BEYAZ,
    RENK_BEYAZ, RENK_BEYAZ, RENK_SIYAH, RENK_BEYAZ,
    RENK_SIYAH, RENK_BEYAZ, RENK_SIYAH, RENK_BEYAZ,
    RENK_BEYAZ, RENK_BEYAZ, RENK_BEYAZ, RENK_BEYAZ);

type
  PRenkSecici = ^TRenkSecici;
  TRenkSecici = class(TPanel)
  public
    constructor Create; override;
    destructor Destroy; override;
    function Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TSayi4): TISayi4;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
    property FRenkKutuG: TISayi4 read FIDeger1 write FIDeger1;
    property FRenkKutuY: TISayi4 read FIDeger2 write FIDeger2;
    property FSeciliRenkSiraNo: TISayi4 read FIDeger3 write FIDeger3;
  end;

function RenkSeciciCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function RenkSeciciGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TSayi4): TKimlik;

implementation

uses gn_pencere, gn_islevler, temelgorselnesne, src_ps2;

{==============================================================================
  renk seçici kesme çağrılarını yönetir
 ==============================================================================}
function RenkSeciciCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  RenkSecici: TRenkSecici;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := RenkSeciciGNOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PRenk(ADegiskenler + 12)^, PRenk(ADegiskenler + 16)^);
    end;

    ISLEV_GOSTER:
    begin

      RenkSecici := TRenkSecici(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      RenkSecici.Goster;
    end;
  end;
end;

{==============================================================================
  uygulama için renk seçici nesnesi oluşturur - api
 ==============================================================================}
function RenkSeciciGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TSayi4): TKimlik;
var
  RenkSecici: TRenkSecici;
begin

  RenkSecici := TRenkSecici.Create;

  if(RenkSecici = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    RenkSecici.Ozellestir(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik);

    Result := RenkSecici.Kimlik;
  end;
end;

{==============================================================================
  renk seçici nesnesi oluşturur
 ==============================================================================}
constructor TRenkSecici.Create;
begin

  inherited Create;

  NesneTipi := gntRenkSecici;

  GGNesneler.GorselNesne[FSiraNo] := Self;
end;

{==============================================================================
  renk seçici nesnesini yok eder
 ==============================================================================}
destructor TRenkSecici.Destroy;
begin

  GGNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  renk seçici nesnesini özelleştirir
 ==============================================================================}
function TRenkSecici.Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TSayi4): TISayi4;
begin

  Yapilandir2(AKullanimTipi, Self, AAtaNesne, ASol, AUst, AGenislik, AYukseklik,
    0, 0, 0, 0, '');

  OlayCagriAdr := @OlaylariIsle;

  Odaklanilabilir := True;
  Odaklanildi := False;

  // renk kutu genişlik & yükseklik değerlerini belirle
  FRenkKutuG := AGenislik div 8;
  FRenkKutuY := AYukseklik div 2;

  // seçili renk = -1 = seçili renk yok
  FSeciliRenkSiraNo := -1;

  // geri dönüş değeri
  Result := HATA_YOK;
end;

{==============================================================================
  renk seçici nesnesini görüntüler
 ==============================================================================}
procedure TRenkSecici.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  renk seçici nesnesini gizler
 ==============================================================================}
procedure TRenkSecici.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  renk seçici nesnesini hizalandırır
 ==============================================================================}
procedure TRenkSecici.Hizala;
begin

  inherited Hizala;
end;

{==============================================================================
  renk seçici nesnesini çizer
 ==============================================================================}
procedure TRenkSecici.Ciz;
var
  CizimAlani: TAlan;
  i, j,
  k: TISayi4;
begin

  // 16 rengi 8 sütün, 2 satır olarak çiz. (8 x 2)
  k := 0;
  for i := 0 to 1 do
  begin

    for j := 0 to 7 do
    begin

      CizimAlani.Sol := j * FRenkKutuG;
      CizimAlani.Ust := i * FRenkKutuY;
      CizimAlani.Sag := CizimAlani.Sol + FRenkKutuG - 1;
      CizimAlani.Alt := CizimAlani.Ust + FRenkKutuY - 1;
      DikdortgenDoldur(Self, CizimAlani, SecimRenkleri[(i * 8) + j],
        SecimRenkleri[(i * 8) + j]);

      if(k = FSeciliRenkSiraNo) then
        Dikdortgen(Self, ctDuz, CizimAlani, KenarRenkleri[FSeciliRenkSiraNo]);

      Inc(k);
    end;
  end;

  // nesne odaklanılmış ise nesnenin kenarlarını işaretle
  if(Odaklanildi) then
  begin

    CizimAlani := FCizimAlani;
    Dikdortgen(Self, ctNokta, CizimAlani, RENK_SIYAH);
  end;
end;

{==============================================================================
  renk seçici nesne olaylarını işler
 ==============================================================================}
procedure TRenkSecici.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Pencere: TPencere;
  RenkSecici: TRenkSecici;
begin

  RenkSecici := TRenkSecici(AGonderici);

  // farenin sol tuşuna basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // renk seçicinin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(RenkSecici);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere.FAktifNesne := RenkSecici;
    RenkSecici.Odaklanildi := True;

    // fare olaylarını yakala
    OlayYakalamayaBasla(RenkSecici);

    RenkSecici.FSeciliRenkSiraNo := ((AOlay.Deger2 div RenkSecici.FRenkKutuY) * 8) +
      (AOlay.Deger1 div RenkSecici.FRenkKutuG);

    // renk seçici nesnesini yeniden çiz
    RenkSecici.Ciz;
  end
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    OlayYakalamayiBirak(RenkSecici);

    // renk seçici nesnesini yeniden çiz
    RenkSecici.Ciz;

    // farenin tuş bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(RenkSecici.FareNesneOlayAlanindaMi(RenkSecici)) then
    begin

      if(RenkSecici.FSeciliRenkSiraNo > -1) then
      begin

        // yakalama & bırakma işlemi bu nesnede olduğu için
        // uygulamaya veya efendi nesneye FO_TIKLAMA mesajı gönder
        AOlay.Olay := FO_TIKLAMA;
        AOlay.Deger1 := SecimRenkleri[RenkSecici.FSeciliRenkSiraNo];
        AOlay.Deger2 := 0;
        if not(RenkSecici.OlayYonlAdr = nil) then
          RenkSecici.OlayYonlAdr(RenkSecici, AOlay)
        else GGorevler.OlayEkle(RenkSecici.GrvKimlik, AOlay);
      end;
    end;
  end;

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := RenkSecici.FareImlec;
end;

end.
