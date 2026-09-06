{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_masaustu.pas
  Dosya İşlevi: masaüstü yönetim işlevlerini içerir

  Güncelleme Tarihi: 30/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_masaustu;

interface

uses gorselnesne, gn_panel, paylasim;

type
  PMasaustu = ^TMasaustu;
  TMasaustu = class(TPanel)
  public
    FGoruntuYapi: TGoruntuYapi;
    constructor Create; override;
    destructor Destroy; override;
    function Ozellestir(AMasaustuAdi: string): TISayi4;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Boyutlandir;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
    procedure Aktiflestir;
    procedure MasaustunuRenkIleDoldur;
    procedure MasaustuRenginiDegistir(ARenk: TRenk);
    procedure MasaustuResminiDegistir(ADosyaYolu: string);
    // MasaustuArkaPlan: 1 = renk değeri, 2 = resim
    property MasaustuArkaPlan: TISayi4 read FIDeger1 write FIDeger1;
    property MasaustuRenk: TRenk read FDeger1 write FDeger1;
  end;

function MasaustuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function MasaustuGNOlustur(AMasaustuAdi: string): TKimlik;

implementation

uses gn_islevler, bmp, gn_pencere, gorev, src_vesa20, src_ps2;

{==============================================================================
  masaüstü kesme çağrılarını yönetir
 ==============================================================================}
function MasaustuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  Masaustu: TMasaustu;
  i: TISayi4;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    ISLEV_OLUSTUR:

      Result := MasaustuGNOlustur(PKarakterKatari(PSayi4(ADegiskenler + 04)^ +
        GGorevler.FAktifGrvBelAdr)^);

    ISLEV_GOSTER:
    begin

      Masaustu := TMasaustu(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Masaustu.Goster;
    end;

    // oluşturulmuş toplam masaüstü sayısı
    $010E:
    begin

      Result := GGNesneler.ToplamMasaustu;
    end;

    // aktif masaüstü kimliği
    $020E:
    begin

      Result := GGNesneler.AktifMasaustu.Kimlik;
    end;

    // masaüstünü aktifleştir
    $020F:
    begin

      // aktifleştirilecek masaüstü sıra numarasını al
      i := PISayi4(ADegiskenler + 00)^;

      // eğer belirtilen aralıktaysa ...
      if(i > -1) and (i < USTSINIR_MASAUSTU) then
      begin

        // belirlenen sıradaki masüstü mevcut ise
        if(GGNesneler.Masaustleri[i] <> nil) then
        begin

          // masaüstünü aktif olarak işaretle
          GGNesneler.AktifMasaustu := GGNesneler.Masaustleri[i];

          GGNesneler.AktifMasaustu.Aktiflestir;

          // masaüstünü çiz
          GGNesneler.AktifMasaustu.Ciz;

          // işlemin başarılı olduğuna dair mesajı geri döndür
          Result := TISayi4(True);

        end else Result := TISayi4(False);
      end else Result := TISayi4(False);
    end;

    // masaüstünü güncelleştir (yeniden çiz)
    $030F:
    begin

      Masaustu := TMasaustu(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntMasaustu));
      if(Masaustu <> nil) then Masaustu.Ciz;
    end;

    // masaüstü rengini değiştir
    $040F:
    begin

      Masaustu := TMasaustu(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntMasaustu));
      if(Masaustu <> nil) then Masaustu.MasaustuRenginiDegistir(PRenk(ADegiskenler + 04)^);
    end;

    // masaüstü resmini değiştir
    $050F:
    begin

      Masaustu := TMasaustu(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntMasaustu));
      if(Masaustu <> nil) then Masaustu.MasaustuResminiDegistir(
        PKarakterKatari(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr)^);
    end;
  end;
end;

{==============================================================================
  uygulama için masaüstü nesnesi oluşturur - api
 ==============================================================================}
function MasaustuGNOlustur(AMasaustuAdi: string): TKimlik;
var
  Masaustu: TMasaustu;
begin

  Masaustu := TMasaustu.Create;

  if(Masaustu = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    Masaustu.Ozellestir(AMasaustuAdi);

    Result := Masaustu.Kimlik;
  end;
end;

{==============================================================================
  masaüstü nesnesi oluşturur
 ==============================================================================}
constructor TMasaustu.Create;
var
  Genislik, Yukseklik,
  i, j: TISayi4;
begin

  // tüm masaüstü nesneleri oluşturulduysa çık
  if(GGNesneler.ToplamMasaustu >= USTSINIR_MASAUSTU) then Exit;

  inherited Create;

  NesneTipi := gntMasaustu;

  GGNesneler.GorselNesne[FSiraNo] := Self;

  Genislik := GEkranKartSurucusu.KartBilgisi.YatayCozunurluk;
  Yukseklik := GEkranKartSurucusu.KartBilgisi.DikeyCozunurluk;

  Yapilandir2(ktTuvalNesne, Self, nil, 0, 0, Genislik, Yukseklik, 0, 0, 0, 0, '');

  // oluşturulan masaüstü nesnesini masaüstü listesine kaydet
  for i := 0 to USTSINIR_MASAUSTU - 1 do
  begin

    if(GGNesneler.Masaustleri[i] = nil) then
    begin

      // 1. masaüstü nesne işaretçisini boş bellek alanına kaydet
      // 2. oluşturulan masaüstü nesne sayısını artır
      GGNesneler.Masaustleri[i] := Self;

      j := GGNesneler.ToplamMasaustu;
      Inc(j);
      GGNesneler.ToplamMasaustu := j;
      Break;
    end;
  end;
end;

{==============================================================================
  masaüstü nesnesini yok eder
 ==============================================================================}
destructor TMasaustu.Destroy;
begin

  { TODO : yok edilme aşamasında bellek durumu kontrol edilecek }

  GGNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  masaüstü nesnesini özelleştirir
 ==============================================================================}
function TMasaustu.Ozellestir(AMasaustuAdi: string): TISayi4;
begin

  OlayCagriAdr := @OlaylariIsle;

  Baslik := AMasaustuAdi;

  // masaüstü arkaplan öndeğerleri
  MasaustuArkaPlan := 1;
  MasaustuRenk := RENK_ZEYTINYESILI;

  // masaüstünün çizileceği bellek adresi
  FCizimBellekAdresi := GetMem(FAtananAlan.Genislik * FAtananAlan.Yukseklik * 4);

  // masaüstüne çizilecek resmin bellek bilgileri
  FGoruntuYapi.BellekAdresi := nil;

  Result := HATA_YOK;
end;

{==============================================================================
  masaüstünü aktifleştirir / görüntüler
 ==============================================================================}
procedure TMasaustu.Goster;
var
  Pencere: TPencere;
  GNBellekAdresi: PGorselNesne;
  i: TSayi4;
begin

  inherited Goster;

  FYenidenCiz := True;

  // masaüstünü aktifleştir
  Aktiflestir;

  Ciz;

  // masaüstü alt nesnesi olan pencereleri çiz
  if(AltNesneSayisi > 0) then
  begin

    GNBellekAdresi := AltNesneBellekAdresi;

    // ilk oluşturulan pencereden son oluşturulan pencereye doğru nesneleri çiz
    for i := 0 to AltNesneSayisi - 1 do
    begin

      Pencere := TPencere(GNBellekAdresi[i]);
      if(Pencere.Gorunum) and (Pencere.NesneTipi = gntPencere) then Pencere.Ciz;
    end;
  end;
end;

{==============================================================================
  masaüstünü gizler
 ==============================================================================}
procedure TMasaustu.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  masaüstünü hizalandırır
 ==============================================================================}
procedure TMasaustu.Hizala;
begin

end;

{==============================================================================
  masaüstünü boyutlandırır
 ==============================================================================}
procedure TMasaustu.Boyutlandir;
begin

end;

{==============================================================================
  masaüstünü çizer
 ==============================================================================}
procedure TMasaustu.Ciz;
var
  i: TSayi4;
begin

  // masaüstü arka plan resmini çiz
  if(Gorunum) and (FYenidenCiz) then
  begin

    if(MasaustuArkaPlan = 1) then
      MasaustunuRenkIleDoldur
    else BMPGoruntusuCiz(gntMasaustu, Self, FGoruntuYapi);

    i := Length(SistemAdi) * 8;
    YaziYaz(Self, FCizimAlani.Genislik - i, 0, SistemAdi, RENK_BEYAZ);

    FYenidenCiz := False;
  end;

  // tüm pencereleri yeniden çiz
  GGNesneler.PencereleriYenidenCiz;
end;

{==============================================================================
  masaüstü olaylarını işler
 ==============================================================================}
procedure TMasaustu.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Masaustu: TMasaustu;
  BirOncekiOlay: TISayi4;
begin

  Masaustu := TMasaustu(AGonderici);

  // sağ / sol fare tuş basımı
  if(AOlay.Olay = FO_SAGTUS_BASILDI) or (AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // olayları bu nesneye yönlendir
    GGNesneler.OlayYakalamayaBasla(Masaustu);

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(Masaustu.OlayYonlAdr = nil) then
      Masaustu.OlayYonlAdr(Masaustu, AOlay)
    else GGorevler.OlayEkle(Masaustu.GrvKimlik, AOlay);
  end

  // sağ / sol fare tuş bırakımı
  else if(AOlay.Olay = FO_SAGTUS_BIRAKILDI) or (AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // olayları bu nesneye yönlendirmeyi iptal et
    GGNesneler.OlayYakalamayiBirak(Masaustu);

    BirOncekiOlay := AOlay.Olay;

    // uygulamaya mesaj gönder
    if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
    begin

      // uygulamaya veya efendi nesneye mesaj gönder
      AOlay.Olay := FO_TIKLAMA;
      if not(Masaustu.OlayYonlAdr = nil) then
        Masaustu.OlayYonlAdr(Masaustu, AOlay)
      else GGorevler.OlayEkle(Masaustu.GrvKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := BirOncekiOlay;
    if not(Masaustu.OlayYonlAdr = nil) then
      Masaustu.OlayYonlAdr(Masaustu, AOlay)
    else GGorevler.OlayEkle(Masaustu.GrvKimlik, AOlay);
  end;

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := Masaustu.FareImlec;
end;

{==============================================================================
  masaüstünü aktifleştirir
 ==============================================================================}
procedure TMasaustu.Aktiflestir;
begin

  // eğer masaüstü nesnesi aktif değil ise
  if(Self <> GGNesneler.AktifMasaustu) then
  begin

    // aktif masaüstü olarak belirle
    GGNesneler.AktifMasaustu := Self;

    FYenidenCiz := True;
  end;
end;

{==============================================================================
  masaüstünü belirtilen renk değeri ile boyar
 ==============================================================================}
procedure TMasaustu.MasaustunuRenkIleDoldur;
var
  Sol, Ust: TISayi4;
begin

  MasaustuArkaPlan := 1;

  for Ust := FCizimAlani.Ust to FCizimAlani.Alt do
  begin

    for Sol := FCizimAlani.Sol to FCizimAlani.Sag do
    begin

      GEkranKartSurucusu.NoktaYaz(Self, Sol, Ust, MasaustuRenk, False);
    end;
  end;
end;

{==============================================================================
  masaüstü renk değerini değiştirir
 ==============================================================================}
procedure TMasaustu.MasaustuRenginiDegistir(ARenk: TRenk);
begin

  // masaüstünün renk değerini değiştir
  MasaustuArkaPlan := 1;
  MasaustuRenk := ARenk;

  FYenidenCiz := True;

  if(Gorunum) then Ciz;
end;

{==============================================================================
  masaüstü resmini değiştirir - kesme işlevi
 ==============================================================================}
procedure TMasaustu.MasaustuResminiDegistir(ADosyaYolu: string);
var
  BMP: TBMP;
begin

  GorevDegistirme := 1;

  // masaüstü resmini değiştir
  MasaustuArkaPlan := 2;

  // daha önce masaüstü resmi için bellek ayrıldıysa belleği iptal et
  if not(FGoruntuYapi.BellekAdresi = nil) then
  begin

    FreeMem(FGoruntuYapi.BellekAdresi, FGoruntuYapi.Genislik * FGoruntuYapi.Yukseklik * 4);

    FGoruntuYapi.BellekAdresi := nil;
  end;

  // resim dosyasını masaüstü yapısına yükle
  BMP := TBMP.Create;
  FGoruntuYapi := BMP.Yukle(ADosyaYolu);
  BMP.Destroy;

  // arka plan resminin yüklenememesi durumunda arka plan rengini siyah yap
  if(FGoruntuYapi.BellekAdresi = nil) then
  begin

    MasaustuArkaPlan := 1;
    MasaustuRenk := RENK_SIYAH;
  end;

  FYenidenCiz := True;

  if(Gorunum) then Ciz;

  GorevDegistirme := 0;
end;

end.
