{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_masaustu.pas
  Dosya İşlevi: masaüstü yönetim işlevlerini içerir

  Güncelleme Tarihi: 16/07/2026

 ==============================================================================}
{$mode objfpc}
unit gn_masaustu;

interface

uses gorselnesne, gn_panel, paylasim;

type
  PMasaustu = ^TMasaustu;
  TMasaustu = object(TPanel)
  public
    FGoruntuYapi: TGoruntuYapi;
    function Olustur(AMasaustuAdi: string): PMasaustu;
    function Olustur2(AMasaustuAdi: string): PMasaustu;
    procedure YokEt(AKimlik: TKimlik);
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Boyutlandir;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    procedure Aktiflestir;
    procedure MasaustunuRenkIleDoldur;
    procedure MasaustuRenginiDegistir(ARenk: TRenk);
    procedure MasaustuResminiDegistir(ADosyaYolu: string);
    // MasaustuArkaPlan: 1 = renk değeri, 2 = resim
    property MasaustuArkaPlan: TISayi4 read FIDeger1 write FIDeger1;
    property MasaustuRenk: TRenk read FDeger1 write FDeger1;
  end;

function MasaustuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AMasaustuAdi: string): TKimlik;

implementation

uses gn_islevler, genel, bmp, temelgorselnesne, gn_pencere, gorev, src_vesa20;

{==============================================================================
  masaüstü kesme çağrılarını yönetir
 ==============================================================================}
function MasaustuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  Masaustu: PMasaustu = nil;
  i: TISayi4;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    ISLEV_OLUSTUR:

      Result := NesneOlustur(PKarakterKatari(PSayi4(ADegiskenler + 04)^ +
        FAktifGorevBellekAdresi)^);

    ISLEV_GOSTER:
    begin

      Masaustu := PMasaustu(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      Masaustu^.Goster;
    end;

    // oluşturulmuş toplam masaüstü sayısı
    $010E:
    begin

      Result := GorselNesneler0.ToplamMasaustu;
    end;

    // aktif masaüstü kimliği
    $020E:
    begin

      Result := GAktifMasaustu^.Kimlik;
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
        if(GMasaustuListesi[i] <> nil) then
        begin

          // masaüstünü aktif olarak işaretle
          GAktifMasaustu := GMasaustuListesi[i];

          GAktifMasaustu^.Aktiflestir;

          // masaüstünü çiz
          GAktifMasaustu^.Ciz;

          // işlemin başarılı olduğuna dair mesajı geri döndür
          Result := TISayi4(True);

        end else Result := TISayi4(False);
      end else Result := TISayi4(False);
    end;

    // masaüstünü güncelleştir (yeniden çiz)
    $030F:
    begin

      Masaustu := PMasaustu(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntMasaustu));
      if(Masaustu <> nil) then Masaustu^.Ciz;
    end;

    // masaüstü rengini değiştir
    $040F:
    begin

      Masaustu := PMasaustu(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntMasaustu));
      if(Masaustu <> nil) then Masaustu^.MasaustuRenginiDegistir(
        PRenk(ADegiskenler + 04)^);
    end;

    // masaüstü resmini değiştir
    $050F:
    begin

      Masaustu := PMasaustu(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntMasaustu));
      if(Masaustu <> nil) then Masaustu^.MasaustuResminiDegistir(
        PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi)^);
    end;
  end;
end;

{==============================================================================
  masaüstü nesnesini oluşturur
 ==============================================================================}
function NesneOlustur(AMasaustuAdi: string): TKimlik;
var
  Masaustu: PMasaustu = nil;
begin

  Masaustu := Masaustu^.Olustur(AMasaustuAdi);
  if(Masaustu = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := Masaustu^.Kimlik;
end;

{==============================================================================
  masaüstü nesnesini oluşturur
 ==============================================================================}
function TMasaustu.Olustur(AMasaustuAdi: string): PMasaustu;
var
  Masaustu: PMasaustu = nil;
begin

  // masaüstü nesnesi oluştur
  Masaustu := Olustur2(AMasaustuAdi);
  if(Masaustu = nil) then
  begin

    Result := nil;
    Exit;
  end;

  Masaustu^.MasaustuArkaPlan := 1;        // masaüstü arkaplan renk değeri kullanılacak
  Masaustu^.MasaustuRenk := RENK_ZEYTINYESILI;

  // masaüstünün çizileceği bellek adresi
  Masaustu^.FCizimBellekAdresi := GetMem(Masaustu^.FAtananAlan.Genislik * Masaustu^.FAtananAlan.Yukseklik * 4);

  // masaüstüne çizilecek resmin bellek bilgileri
  Masaustu^.FGoruntuYapi.BellekAdresi := nil;

  // nesne adresini geri döndür
  Result := Masaustu;
end;

{==============================================================================
  masaüstü nesnesi için yer tahsis eder
 ==============================================================================}
function TMasaustu.Olustur2(AMasaustuAdi: string): PMasaustu;
var
  Masaustu: PMasaustu = nil;
  Genislik, Yukseklik,
  i, j: TISayi4;
begin

  Result := nil;

  // tüm masaüstü nesneleri oluşturulduysa çık
  if(GorselNesneler0.ToplamMasaustu >= USTSINIR_MASAUSTU) then Exit;

  Genislik := EkranKartSurucusu0.KartBilgisi.YatayCozunurluk;
  Yukseklik := EkranKartSurucusu0.KartBilgisi.DikeyCozunurluk;

  Masaustu := PMasaustu(inherited Olustur(ktTuvalNesne, nil, 0, 0,
    Genislik, Yukseklik, 0, 0, 0, 0, ''));

  Masaustu^.NesneTipi := gntMasaustu;

  Masaustu^.Baslik := AMasaustuAdi;

  Masaustu^.FTuvalNesne := Masaustu;

  Masaustu^.OlayCagriAdresi := @OlaylariIsle;

  Masaustu^.FCizimBaslangic.Sol := 0;
  Masaustu^.FCizimBaslangic.Ust := 0;

  // masaüstü nesnesi için bellekte boş yer bul
  for i := 0 to USTSINIR_MASAUSTU - 1 do
  begin

    if(GMasaustuListesi[i] = nil) then
    begin

      // 1. masaüstü kimliğini boş olarak bulunan yere kaydet
      // 2. oluşturulan masaüstü nesne sayısını artır
      // 3. geriye nesneyi döndür
      GMasaustuListesi[i] := Masaustu;

      j := GorselNesneler0.ToplamMasaustu;
      Inc(j);
      GorselNesneler0.ToplamMasaustu := j;

      // nesne adresini geri döndür
      Exit(Masaustu);
    end;
  end;
end;

procedure TMasaustu.YokEt(AKimlik: TKimlik);
begin

  { TODO : yok edilme aşamasında bellek durumu kontrol edilecek }

  inherited YokEt(AKimlik);
end;

{==============================================================================
  masaüstünü aktifleştirir / görüntüler
 ==============================================================================}
procedure TMasaustu.Goster;
var
  Masaustu: PMasaustu = nil;
  GNBellekAdresi: PPGorselNesne;
  Pencere: PGorselNesne = nil;
  i: Integer;
begin

  inherited Goster;

  // nesnenin kimlik, tip değerlerini denetle.
  Masaustu := PMasaustu(GorselNesneler0.NesneTipiniKontrolEt(Kimlik, gntMasaustu));
  if(Masaustu = nil) then Exit;

  // masaüstünü aktifleştir
  Masaustu^.Aktiflestir;

  Masaustu^.Ciz;

  // masaüstü alt nesnesi olan pencereleri çiz
  if(Masaustu^.AltNesneSayisi > 0) then
  begin

    GNBellekAdresi := Masaustu^.AltNesneBellekAdresi;

    // ilk oluşturulan pencereden son oluşturulan pencereye doğru nesneleri çiz
    for i := 0 to Masaustu^.AltNesneSayisi - 1 do
    begin

      Pencere := GNBellekAdresi[i];
      if(Pencere^.Gorunum) and (Pencere^.NesneTipi = gntPencere) then
        PPencere(Pencere)^.Ciz;
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
  Masaustu: PMasaustu = nil;
  i: TSayi4;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  Masaustu := PMasaustu(GorselNesneler0.NesneTipiniKontrolEt(Kimlik, gntMasaustu));
  if(Masaustu = nil) then Exit;

  // masaüstü arka plan resmini çiz
  if(Masaustu^.Gorunum) then
  begin

    if(Masaustu^.MasaustuArkaPlan = 1) then
      MasaustunuRenkIleDoldur
    else BMPGoruntusuCiz(gntMasaustu, Masaustu, Masaustu^.FGoruntuYapi);
  end;

  i := Length(SistemAdi) * 8;
  Masaustu^.YaziYaz(Masaustu, Masaustu^.FCizimAlani.Genislik - i, 0,
    SistemAdi, RENK_BEYAZ);

  // tüm pencereleri yeniden çiz
  PencereleriYenidenCiz;
end;

{==============================================================================
  masaüstü olaylarını işler
 ==============================================================================}
procedure TMasaustu.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Masaustu: PMasaustu = nil;
  BirOncekiOlay: TISayi4;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  Masaustu := PMasaustu(AGonderici);

  // sağ / sol fare tuş basımı
  if(AOlay.Olay = FO_SAGTUS_BASILDI) or (AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // olayları bu nesneye yönlendir
    OlayYakalamayaBasla(Masaustu);

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(Masaustu^.OlayYonlendirmeAdresi = nil) then
      Masaustu^.OlayYonlendirmeAdresi(Masaustu, AOlay)
    else Gorevler0.OlayEkle(Masaustu^.GorevKimlik, AOlay);
  end

  // sağ / sol fare tuş bırakımı
  else if(AOlay.Olay = FO_SAGTUS_BIRAKILDI) or (AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // olayları bu nesneye yönlendirmeyi iptal et
    OlayYakalamayiBirak(Masaustu);

    BirOncekiOlay := AOlay.Olay;

    // uygulamaya mesaj gönder
    if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
    begin

      // uygulamaya veya efendi nesneye mesaj gönder
      AOlay.Olay := FO_TIKLAMA;
      if not(Masaustu^.OlayYonlendirmeAdresi = nil) then
        Masaustu^.OlayYonlendirmeAdresi(Masaustu, AOlay)
      else Gorevler0.OlayEkle(Masaustu^.GorevKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := BirOncekiOlay;
    if not(Masaustu^.OlayYonlendirmeAdresi = nil) then
      Masaustu^.OlayYonlendirmeAdresi(Masaustu, AOlay)
    else Gorevler0.OlayEkle(Masaustu^.GorevKimlik, AOlay);
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := Masaustu^.FareImlecTipi;
end;

{==============================================================================
  masaüstünü aktifleştirir
 ==============================================================================}
procedure TMasaustu.Aktiflestir;
begin

  // eğer masaüstü nesnesi aktif değil ise
  if(@Self <> GAktifMasaustu) then
  begin

    // aktif masaüstü olarak belirle
    GAktifMasaustu := @Self;
  end;
end;

{==============================================================================
  masaüstünü belirtilen renk değeri ile boyar
 ==============================================================================}
procedure TMasaustu.MasaustunuRenkIleDoldur;
var
  Masaustu: PMasaustu = nil;
  Sol, Ust: TISayi4;
  Renk: TRenk;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  Masaustu := PMasaustu(GorselNesneler0.NesneTipiniKontrolEt(Kimlik, gntMasaustu));
  if(Masaustu = nil) then Exit;

  Masaustu^.MasaustuArkaPlan := 1;

  Renk := Masaustu^.MasaustuRenk;

  for Ust := Masaustu^.FCizimAlani.Ust to Masaustu^.FCizimAlani.Alt do
  begin

    for Sol := Masaustu^.FCizimAlani.Sol to Masaustu^.FCizimAlani.Sag do
    begin

      EkranKartSurucusu0.NoktaYaz(Masaustu, Sol, Ust, Renk, False);
    end;
  end;
end;

{==============================================================================
  masaüstü renk değerini değiştirir
 ==============================================================================}
procedure TMasaustu.MasaustuRenginiDegistir(ARenk: TRenk);
var
  Masaustu: PMasaustu = nil;
begin

  Masaustu := PMasaustu(GorselNesneler0.NesneTipiniKontrolEt(Kimlik, gntMasaustu));
  if(Masaustu = nil) then Exit;

  // masaüstünün renk değerini değiştir
  Masaustu^.MasaustuArkaPlan := 1;
  Masaustu^.MasaustuRenk := ARenk;

  if(Masaustu^.Gorunum) then Masaustu^.Ciz;
end;

{==============================================================================
  masaüstü resmini değiştirir - kesme işlevi
 ==============================================================================}
procedure TMasaustu.MasaustuResminiDegistir(ADosyaYolu: string);
var
  Masaustu: PMasaustu = nil;
begin

  Masaustu := PMasaustu(GorselNesneler0.NesneTipiniKontrolEt(Kimlik, gntMasaustu));
  if(Masaustu = nil) then Exit;

  GorevDegistirme := 1;

  // masaüstü resmini değiştir
  Masaustu^.MasaustuArkaPlan := 2;

  // daha önce masaüstü resmi için bellek ayrıldıysa belleği iptal et
  if not(Masaustu^.FGoruntuYapi.BellekAdresi = nil) then
  begin

    FreeMem(Masaustu^.FGoruntuYapi.BellekAdresi, Masaustu^.FGoruntuYapi.Genislik *
      Masaustu^.FGoruntuYapi.Yukseklik * 4);

    Masaustu^.FGoruntuYapi.BellekAdresi := nil;
  end;

  // resim dosyasını masaüstü yapısına yükle
  Masaustu^.FGoruntuYapi := BMPDosyasiYukle(ADosyaYolu);

  // arka plan resminin yüklenememesi durumunda arka plan rengini siyah yap
  if(Masaustu^.FGoruntuYapi.BellekAdresi = nil) then
  begin

    Masaustu^.MasaustuArkaPlan := 1;
    Masaustu^.MasaustuRenk := RENK_SIYAH;
  end;

  if(Masaustu^.Gorunum) then Masaustu^.Ciz;

  GorevDegistirme := 0;
end;

end.
