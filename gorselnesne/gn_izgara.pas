{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_izgara.pas
  Dosya İşlevi: ızgara nesnesi (TStringGrid) yönetim işlevlerini içerir

  Güncelleme Tarihi: 16/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_izgara;

interface

uses gorselnesne, paylasim, n_yazilistesi, gn_panel, gn_kaydirmacubugu;

type
  PIzgara = ^TIzgara;
  TIzgara = class(TPanel)
  private
    FYatayKCubugu, FDikeyKCubugu: TKaydirmaCubugu;
    FYatayKCGoster, FDikeyKCGoster: LongBool;
    FSabitSutunSayisi, FSabitSatirSayisi: TISayi4;
    FSutunSayisi, FSatirSayisi,
    FSutunGenislik, FSatirYukseklik: TISayi4;
    FSeciliSatir, FSeciliSutun: TISayi4;  // seçili satır ve sütun
    FGorunenIlkSiraNo: TISayi4;           // ızgara nesnesinde en üstte görüntülenen elemanın sıra değeri
    FGorunenElemanSayisi: TISayi4;        // kullanıcıya nesne içerisinde gösterilen eleman sayısı
    FDegerler: TYaziListesi;              // kolon değerleri
    procedure KaydirmaCubuguOlaylariniIsle(AGonderici: TGorselNesne; AOlay: TOlay);
  public
    constructor Create; override;
    destructor Destroy; override;
    function Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4): TISayi4;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
    function SeciliSatirDegeriniAl: string;
    procedure Bolumle(ABicimlenmisDeger: string; AAyiracDeger: Char;
      ADegerDizisi: PYaziListesi);
    function DegerEkle(ADeger: string): Boolean;
    procedure DegerIceriginiTemizle;
    procedure HucreBoyutuYaz(ASatirYukseklik, ASutunGenislik: TSayi4);
    procedure SabitHucreSayisiYaz(ASabitSatirSayisi, ASabitSutunSayisi: TSayi4);
    procedure HucreSayisiYaz(ASatirSayisi, ASutunSayisi: TSayi4);
    procedure KaydirmaCubuguGorunumYaz(AYatayKCGoster, ADikeyKCGoster: Boolean);
    procedure SeciliHucreyiYaz(ASatir, ASutun: TISayi4);
  end;

function IzgaraCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function IzgaraGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;

implementation

uses gn_islevler, gn_pencere, temelgorselnesne, sistemmesaj, gorev, src_ps2;

{==============================================================================
  ızgara nesnesi kesme çağrılarını yönetir
 ==============================================================================}
function IzgaraCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  Pencere: TPencere;
  Izgara: TIzgara;
  Hiza: THiza;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    // nesne oluştur
    ISLEV_OLUSTUR:
    begin

      GN := GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := IzgaraGNOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^);
    end;

    ISLEV_GOSTER:
    begin

      Izgara := TIzgara(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Izgara.Goster;
    end;

    ISLEV_GIZLE:
    begin

      Izgara := TIzgara(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Izgara.Gizle;
    end;

    ISLEV_CIZ:
    begin

      Izgara := TIzgara(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Izgara.Ciz;
    end;

    // görsel nesneyi hizala
    ISLEV_HIZALA:
    begin

      Izgara := TIzgara(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      Izgara.FHiza := Hiza;

      Pencere := TPencere(Izgara.FAtaNesne);
      Pencere.Guncelle;
    end;

    // değer içeriklerini temizle
    $010F:
    begin

      Izgara := TIzgara(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Izgara <> nil) then Izgara.DegerIceriginiTemizle;
    end;

    // değer listesine değer ekle
    $020F:
    begin

      Izgara := TIzgara(GGNesneler.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntIzgara));
      if(Izgara <> nil) then Result := TISayi4(Izgara.DegerEkle(
        PKarakterKatari(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr)^));
    end;

    // sabit satır ve sutun hücre sayısını belirle
    $030F:
    begin

      Izgara := TIzgara(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Izgara <> nil) then Izgara.SabitHucreSayisiYaz(
        PSayi4(ADegiskenler + 04)^, PSayi4(ADegiskenler + 08)^);
    end;

    // hücre sayısını belirle
    $040F:
    begin

      Izgara := TIzgara(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Izgara <> nil) then Izgara.HucreSayisiYaz(
        PSayi4(ADegiskenler + 04)^, PSayi4(ADegiskenler + 08)^);
    end;

    // hücre boyutu belirle
    $050F:
    begin

      Izgara := TIzgara(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Izgara <> nil) then Izgara.HucreBoyutuYaz(
        PSayi4(ADegiskenler + 04)^, PSayi4(ADegiskenler + 08)^);
    end;

    // kaydırma çubuğu görünüm belirle
    $060F:
    begin

      Izgara := TIzgara(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Izgara <> nil) then Izgara.KaydirmaCubuguGorunumYaz(
        PLongBool(ADegiskenler + 04)^, PLongBool(ADegiskenler + 08)^);
    end;

    // seçili hücreyi belirle
    $070F:
    begin

      Izgara := TIzgara(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Izgara <> nil) then Izgara.SeciliHucreyiYaz(
        PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^);
    end;
  end;
end;

{==============================================================================
  uygulama için ızgara nesnesi oluşturur - api
 ==============================================================================}
function IzgaraGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
var
  Izgara: TIzgara;
begin

  Izgara := TIzgara.Create;

  if(Izgara = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    Izgara.Ozellestir(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik);

    Result := Izgara.Kimlik;
  end;
end;

{==============================================================================
  ızgara nesnesi oluşturur
 ==============================================================================}
constructor TIzgara.Create;
begin

  inherited Create;

  NesneTipi := gntIzgara;

  GGNesneler.GorselNesne[FSiraNo] := Self;

  FDegerler := TYaziListesi.Create;
end;

{==============================================================================
  ızgara nesnesini yok eder
 ==============================================================================}
destructor TIzgara.Destroy;
begin

  FYatayKCubugu.Destroy;
  FDikeyKCubugu.Destroy;

  if(FDegerler <> nil) then FDegerler.Destroy;

  GGNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  ızgara nesnesini özelleştirir
 ==============================================================================}
function TIzgara.Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4): TISayi4;
begin

  Yapilandir2(AKullanimTipi, Self, AAtaNesne, ASol, AUst, AGenislik, AYukseklik,
    2, RENK_GRI, RENK_GRI, 0, '');

  OlayCagriAdr := @OlaylariIsle;

  FYatayKCGoster := False;
  FDikeyKCGoster := False;

  // yatay kaydırma çubuğu
  FYatayKCubugu := TKaydirmaCubugu.Create;
  FYatayKCubugu.Ozellestir(ktBilesen, Self, 0, AYukseklik - 16, AGenislik - 16, 16, yYatay);
  FYatayKCubugu.DegerleriBelirle(0, 10);
  FYatayKCubugu.OlayYonlAdr := @KaydirmaCubuguOlaylariniIsle;

  // dikey kaydırma çubuğu
  FDikeyKCubugu := TKaydirmaCubugu.Create;
  FDikeyKCubugu.Ozellestir(ktBilesen, Self, AGenislik - 16, 0, 16, AYukseklik - 16, yDikey);
  FDikeyKCubugu.DegerleriBelirle(0, 10);
  FDikeyKCubugu.OlayYonlAdr := @KaydirmaCubuguOlaylariniIsle;

  Odaklanilabilir := True;
  Odaklanildi := False;

  // nesnenin kullanacağı diğer değerler
  FGorunenIlkSiraNo := 0;
  FSeciliSatir := -1;
  FSeciliSutun := -1;

  // ızgara nesnesinde görüntülenecek eleman sayısı
  FGorunenElemanSayisi := (AYukseklik - 24) div 21;

  FSabitSatirSayisi := 1;
  FSabitSutunSayisi := 0;
  FSatirSayisi := 7;
  FSutunSayisi := 7;
  FSatirYukseklik := 18;
  FSutunGenislik := 40;

  // geri dönüş değeri
  Result := HATA_YOK;
end;

{==============================================================================
  ızgara nesnesini görüntüler
 ==============================================================================}
procedure TIzgara.Goster;
begin

  if(FYatayKCGoster) then FYatayKCubugu.Goster;
  if(FDikeyKCGoster) then FDikeyKCubugu.Goster;

  inherited Goster;
end;

{==============================================================================
  ızgara nesnesini gizler
 ==============================================================================}
procedure TIzgara.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  ızgara nesnesini hizalandırır
 ==============================================================================}
procedure TIzgara.Hizala;
begin

  inherited Hizala;

  if(FYatayKCGoster) then
  begin

    // yatay kaydırma çubuğunu elle yeniden konumlandır
    FYatayKCubugu.FAtananAlan.Sol := 0;
    FYatayKCubugu.FAtananAlan.Ust := FAtananAlan.Yukseklik - 16;
    FYatayKCubugu.FAtananAlan.Genislik := FAtananAlan.Genislik - 16;
    FYatayKCubugu.FAtananAlan.Yukseklik := 16;

    FYatayKCubugu.FCizimAlani.Sol := 0;
    FYatayKCubugu.FCizimAlani.Ust := 0;
    FYatayKCubugu.FCizimAlani.Sag := FYatayKCubugu.FAtananAlan.Genislik - 1;
    FYatayKCubugu.FCizimAlani.Alt := FYatayKCubugu.FAtananAlan.Yukseklik - 1;

    FYatayKCubugu.FCizimBaslangic.Sol := FCizimBaslangic.Sol + FYatayKCubugu.FAtananAlan.Sol;
    FYatayKCubugu.FCizimBaslangic.Ust := FCizimBaslangic.Ust + FYatayKCubugu.FAtananAlan.Ust;
    FYatayKCubugu.Hizala;
  end;

  if(FDikeyKCGoster) then
  begin

    // dikey kaydırma çubuğunu elle yeniden konumlandır
    FDikeyKCubugu.FAtananAlan.Sol := FAtananAlan.Genislik - 16;
    FDikeyKCubugu.FAtananAlan.Ust := 0;
    FDikeyKCubugu.FAtananAlan.Genislik := 16;
    FDikeyKCubugu.FAtananAlan.Yukseklik := FAtananAlan.Yukseklik - 16;

    FDikeyKCubugu.FCizimAlani.Sol := 0;
    FDikeyKCubugu.FCizimAlani.Ust := 0;
    FDikeyKCubugu.FCizimAlani.Sag := FDikeyKCubugu.FAtananAlan.Genislik - 1;
    FDikeyKCubugu.FCizimAlani.Alt := FDikeyKCubugu.FAtananAlan.Yukseklik - 1;

    FDikeyKCubugu.FCizimBaslangic.Sol := FCizimBaslangic.Sol + FDikeyKCubugu.FAtananAlan.Sol;
    FDikeyKCubugu.FCizimBaslangic.Ust := FCizimBaslangic.Ust + FDikeyKCubugu.FAtananAlan.Ust;
    FDikeyKCubugu.Hizala;
  end;
end;

{==============================================================================
  ızgara nesnesini çizer
 ==============================================================================}
procedure TIzgara.Ciz;
var
  Pencere: TPencere;
  CizimAlani: TAlan;
  i, j, SolIlk, UstIlk: TISayi4;
begin

  inherited Ciz;

  // kaydırma çubuğunun çizim alan koordinatlarını al
  CizimAlani := FCizimAlani;

  // ata nesne bir pencere mi?
  Pencere := GGNesneler.EnUstPencereNesnesiniAl(Self);
  if(Pencere = nil) then Exit;

  // tanımlanmış hiçbir kolon yok ise, çık
  if(FDegerler.ElemanSayisi = 0) then Exit;

  if(FYatayKCGoster) then
    SolIlk := FYatayKCubugu.MevcutDeger
  else SolIlk := 0;

  if(FDikeyKCGoster) then
    UstIlk := FDikeyKCubugu.MevcutDeger
  else UstIlk := 0;

  CizimAlani.Sol := 1;
  CizimAlani.Ust := 1;

  // veriye göre yapılan döngü
  for i := UstIlk to FSatirSayisi - 1 do
  begin

    for j := SolIlk to FSutunSayisi - 1 do
    begin

      CizimAlani.Sag := CizimAlani.Sol + FSutunGenislik - 1;
      CizimAlani.Alt := CizimAlani.Ust + FSatirYukseklik - 1;

      if(i < FSabitSatirSayisi) then
        EgimliDoldur3(Self, CizimAlani, $EAECEE, $ABB2B9)
      else if(j < FSabitSutunSayisi) then
        EgimliDoldur3(Self, CizimAlani, $EAECEE, $ABB2B9)

      else if(FSeciliSatir = i) and (FSeciliSutun = j) then
        DikdortgenDoldur(Self, CizimAlani, RENK_KIRMIZI, RENK_BEYAZ)
      else DikdortgenDoldur(Self, CizimAlani, RENK_BEYAZ, RENK_BEYAZ);

      // başlık
      AlanaYaziYaz(Self, CizimAlani, 4, 3, FDegerler.Yazi[(i * (FSutunSayisi)) + j],
        RENK_LACIVERT);

      CizimAlani.Sol := CizimAlani.Sol + FSutunGenislik + 1;
    end;

    CizimAlani.Sol := 1;
    CizimAlani.Ust := CizimAlani.Ust + FSatirYukseklik + 1;
  end;

  // kaydırma çubuklarını en son çiz
  if(FYatayKCGoster) then FYatayKCubugu.Ciz;
  if(FDikeyKCGoster) then FDikeyKCubugu.Ciz;
end;

{==============================================================================
  ızgara nesnesi olaylarını işler
 ==============================================================================}
procedure TIzgara.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Pencere: TPencere;
  Izgara: TIzgara;
  i, j: TISayi4;
begin

  Izgara := TIzgara(AGonderici);

  // sol fare tuş basımı
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // ızgara nesnesinin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := GGNesneler.EnUstPencereNesnesiniAl(Izgara);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GGNesneler.AktifPencere) then
      Pencere.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere.FAktifNesne := Izgara;
    Izgara.Odaklanildi := True;

    // sol tuşa basım işlemi nesnenin olay alanında mı gerçekleşti ?
    if(Izgara.FareNesneOlayAlanindaMi(Izgara)) then
    begin

      // fare olaylarını yakala
      GGNesneler.OlayYakalamayaBasla(Izgara);

      // seçili sütün ve satır değerini yeniden belirle
      i := (AOlay.Deger1 + (Izgara.FYatayKCubugu.MevcutDeger * Izgara.FSutunGenislik)) div Izgara.FSutunGenislik;
      j := (AOlay.Deger2 + (Izgara.FDikeyKCubugu.MevcutDeger * Izgara.FSatirYukseklik)) div Izgara.FSatirYukseklik;
      if(i >= Izgara.FSabitSutunSayisi) and (j >= Izgara.FSabitSatirSayisi) then
      begin

        Izgara.FSeciliSutun := i;
        Izgara.FSeciliSatir := j;
      end;

      // ızgara nesnesini yeniden çiz
      Izgara.Ciz;

      // uygulamaya veya efendi nesneye mesaj gönder
      if not(Izgara.OlayYonlAdr = nil) then
        Izgara.OlayYonlAdr(Izgara, AOlay)
      else GGorevler.OlayEkle(Izgara.GrvKimlik, AOlay);
    end;
  end

  // sol fare tuş bırakım işlemi
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    GGNesneler.OlayYakalamayiBirak(Izgara);

    // fare bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(Izgara.FareNesneOlayAlanindaMi(Izgara)) then
    begin

      // yakalama & bırakma işlemi bu nesnede olduğu için
      // nesneye FO_TIKLAMA mesajı gönder
      AOlay.Olay := FO_TIKLAMA;
      if not(Izgara.OlayYonlAdr = nil) then
        Izgara.OlayYonlAdr(Izgara, AOlay)
      else GGorevler.OlayEkle(Izgara.GrvKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    if not(Izgara.OlayYonlAdr = nil) then
      Izgara.OlayYonlAdr(Izgara, AOlay)
    else GGorevler.OlayEkle(Izgara.GrvKimlik, AOlay);
  end;

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := Izgara.FareImlec;
end;

{==============================================================================
  ızgara nesnesi kaydırma çubuğu olaylarını işler
 ==============================================================================}
procedure TIzgara.KaydirmaCubuguOlaylariniIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Izgara: TIzgara;
  KaydirmaCubugu: TKaydirmaCubugu;
begin

  KaydirmaCubugu := TKaydirmaCubugu(AGonderici);
  if(KaydirmaCubugu = nil) then Exit;

  Izgara := TIzgara(KaydirmaCubugu.AtaNesne);

  if(AOlay.Olay = FO_TIKLAMA) then Izgara.Ciz;

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := Izgara.FareImlec;
end;

procedure TIzgara.HucreSayisiYaz(ASatirSayisi, ASutunSayisi: TSayi4);
begin

  FSatirSayisi := ASatirSayisi;
  FSutunSayisi := ASutunSayisi;
end;

procedure TIzgara.HucreBoyutuYaz(ASatirYukseklik, ASutunGenislik: TSayi4);
begin

  FSatirYukseklik := ASatirYukseklik;
  FSutunGenislik := ASutunGenislik;
end;

procedure TIzgara.SabitHucreSayisiYaz(ASabitSatirSayisi, ASabitSutunSayisi: TSayi4);
begin

  FSabitSatirSayisi := ASabitSatirSayisi;
  FSabitSutunSayisi := ASabitSutunSayisi;
end;

procedure TIzgara.KaydirmaCubuguGorunumYaz(AYatayKCGoster, ADikeyKCGoster: Boolean);
begin

  FYatayKCGoster := AYatayKCGoster;
  FDikeyKCGoster := ADikeyKCGoster;

  if(FYatayKCGoster) then
    FYatayKCubugu.Goster
  else FYatayKCubugu.Gizle;

  if(FDikeyKCGoster) then
    FDikeyKCubugu.Goster
  else FDikeyKCubugu.Gizle;

  Ciz;
end;

procedure TIzgara.SeciliHucreyiYaz(ASatir, ASutun: TISayi4);
begin

  FSeciliSatir := ASatir;
  FSeciliSutun := ASutun;

  Ciz;
end;

{==============================================================================
  seçili elemanın yazı (text) değerini geri döndürür
 ==============================================================================}
function TIzgara.SeciliSatirDegeriniAl: string;
begin

  if(FSeciliSutun = -1) or (FSeciliSutun > FDegerler.ElemanSayisi) then Exit('');

  Result := FDegerler.Yazi[FSeciliSutun];
end;

{==============================================================================
  | ayıracıyla gelen karakter katarını bölümler
 ==============================================================================}
procedure TIzgara.Bolumle(ABicimlenmisDeger: string; AAyiracDeger: Char;
  ADegerDizisi: PYaziListesi);
var
  Uzunluk, i: TISayi4;
  s: string;
begin

  ADegerDizisi^.Temizle;

  Uzunluk := Length(ABicimlenmisDeger);
  if(Uzunluk > 0) then
  begin

    i := 1;
    s := '';
    while i <= Uzunluk do
    begin

      if(ABicimlenmisDeger[i] = AAyiracDeger) or (i = Uzunluk) then
      begin

        if(i = Uzunluk) then s := s + ABicimlenmisDeger[i];

        if(Length(s) > 0) then
        begin

          ADegerDizisi^.Ekle(s);
          s := '';
        end;
      end else s := s + ABicimlenmisDeger[i];

      Inc(i);
    end;
  end;
end;

function TIzgara.DegerEkle(ADeger: string): Boolean;
begin

  FDegerler.Ekle(ADeger);

  Result := True;
end;

procedure TIzgara.DegerIceriginiTemizle;
begin

  FDegerler.Temizle;
  FGorunenIlkSiraNo := 0;
  FSeciliSatir := -1;
  FSeciliSutun := -1;

  Ciz;
end;

end.
