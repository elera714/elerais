{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_baglanti.pas
  Dosya İşlevi: bağlantı nesne yönetim işlevlerini içerir

  Güncelleme Tarihi: 14/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_baglanti;

interface

uses gorselnesne, paylasim, gn_panel;

type
  PBaglanti = ^TBaglanti;
  TBaglanti = class(TPanel)
  public
    constructor Create; override;
    destructor Destroy; override;
    function Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
      ASol, AUst: TISayi4; ANormalRenk, AOdakRenk: TRenk; ABaslik: string): TISayi4;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
    property OdakMevcut: Boolean read FDurum1 write FDurum1;
  end;

function BaglantiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function BaglantiGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst: TISayi4; ANormalRenk,
  AOdakRenk: TRenk; ABaslik: string): TKimlik;

implementation

uses gn_pencere, gn_islevler, gorev, src_ps2;

{==============================================================================
  bağlantı nesne kesme çağrılarını yönetir
 ==============================================================================}
function BaglantiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  Baglanti: TBaglanti;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := BaglantiGNOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PRenk(ADegiskenler + 12)^, PRenk(ADegiskenler + 16)^,
        PKarakterKatari(PSayi4(ADegiskenler + 20)^ + GGorevler.FAktifGrvBelAdr)^);
    end;

    ISLEV_GOSTER:
    begin

      Baglanti := TBaglanti(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Baglanti.Goster;
    end;
  end;
end;

{==============================================================================
  uygulama için bağlantı nesnesi oluşturur - api
 ==============================================================================}
function BaglantiGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst: TISayi4; ANormalRenk,
  AOdakRenk: TRenk; ABaslik: string): TKimlik;
var
  Baglanti: TBaglanti;
begin

  Baglanti := TBaglanti.Create;

  if(Baglanti = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    Baglanti.Ozellestir(ktNesne, AAtaNesne, ASol, AUst, ANormalRenk, AOdakRenk, ABaslik);

    Result := Baglanti.Kimlik;
  end;
end;

{==============================================================================
  bağlantı nesnesi oluşturur
 ==============================================================================}
constructor TBaglanti.Create;
begin

  inherited Create;

  NesneTipi := gntBaglanti;

  GGNesneler.GorselNesne[FSiraNo] := Self;
end;

{==============================================================================
  bağlantı nesnesini yok eder
 ==============================================================================}
destructor TBaglanti.Destroy;
begin

  GGNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  düğme nesnesini özelleştirir
 ==============================================================================}
function TBaglanti.Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
  ASol, AUst: TISayi4; ANormalRenk, AOdakRenk: TRenk; ABaslik: string): TISayi4;
var
  G, Y: TSayi4;
begin

  G := Length(ABaslik) * 8;
  Y := 16;

  Yapilandir2(AKullanimTipi, Self, AAtaNesne, ASol, AUst, G, Y,
    1, 0, 0, ANormalRenk, ABaslik);

  OlayCagriAdr := @OlaylariIsle;

  Baslik := ABaslik;

  OdakMevcut := False;
  Odaklanilabilir := False;
  Odaklanildi := False;

  FareImlec := fitEl;

  FYaziHiza.Yatay := yhSol;
  FYaziHiza.Dikey := dhUst;

  // bilgi: normal yazı rengi ve odak rengi için alt nesnenin FGovdeRenk1,
  // FGovdeRenk2 özellikleri kullanılmıştır
  FGovdeRenk1 := ANormalRenk;
  FGovdeRenk2 := AOdakRenk;
  FYaziRenk := ANormalRenk;
  OdakMevcut := False;

  // geri dönüş değeri
  Result := HATA_YOK;
end;

{==============================================================================
  bağlantı nesnesini görüntüler
 ==============================================================================}
procedure TBaglanti.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  bağlantı nesnesini gizler
 ==============================================================================}
procedure TBaglanti.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  bağlantı nesnesini hizalandırır
 ==============================================================================}
procedure TBaglanti.Hizala;
begin

  inherited Hizala;
end;

{==============================================================================
  bağlantı nesnesini çizer
 ==============================================================================}
procedure TBaglanti.Ciz;
begin

  // düğme başlığı
  if(OdakMevcut) then
    FYaziRenk := FGovdeRenk2
  else FYaziRenk := FGovdeRenk1;

  inherited Ciz;
end;

{==============================================================================
  bağlantı nesne olaylarını işler
 ==============================================================================}
procedure TBaglanti.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Pencere: TPencere;
  Baglanti: TBaglanti;
begin

  Baglanti := TBaglanti(AGonderici);

  // farenin sol tuşuna basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // bağlantı nesnesinin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := GGNesneler.EnUstPencereNesnesiniAl(Baglanti);

    // en üstte olmaması durumunda en üste getir
    if(Pencere <> GAktifPencere) then Pencere.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    // bilgi: şu aşamada bu nesne odaklanılabilir bir nesne değil
    //Pencere^.FAktifNesne := Baglanti;
    //Baglanti^.Odaklanildi := False;

    // fare olaylarını yakala
    GGNesneler.OlayYakalamayaBasla(Baglanti);

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(Baglanti.OlayYonlAdr = nil) then
      Baglanti.OlayYonlAdr(Baglanti, AOlay)
    else GGorevler.OlayEkle(Baglanti.GrvKimlik, AOlay);
  end
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    GGNesneler.OlayYakalamayiBirak(Baglanti);

    // farenin tuş bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(Baglanti.FareNesneOlayAlanindaMi(Baglanti)) then
    begin

      // yakalama & bırakma işlemi bu nesnede olduğu için
      // uygulamaya veya efendi nesneye FO_TIKLAMA mesajı gönder
      AOlay.Olay := FO_TIKLAMA;
      if not(Baglanti.OlayYonlAdr = nil) then
        Baglanti.OlayYonlAdr(Baglanti, AOlay)
      else GGorevler.OlayEkle(Baglanti.GrvKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    if not(Baglanti.OlayYonlAdr = nil) then
      Baglanti.OlayYonlAdr(Baglanti, AOlay)
    else GGorevler.OlayEkle(Baglanti.GrvKimlik, AOlay);
  end
  else if(AOlay.Olay = CO_ODAKKAZANILDI) then
  begin

    Baglanti.OdakMevcut := True;

    // bağlantı nesnesini yeniden çiz
    Baglanti.Ciz;
  end
  else if(AOlay.Olay = CO_ODAKKAYBEDILDI) then
  begin

    Baglanti.OdakMevcut := False;

    // bağlantı nesnesini yeniden çiz
    Baglanti.Ciz;
  end;

  // geçerli fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := Baglanti.FareImlec;
end;

end.
