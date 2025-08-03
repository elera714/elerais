{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: gn_masaustu.pas
  Dosya Ýþlevi: masaüstü yönetim iþlevlerini içerir

  Güncelleme Tarihi: 26/02/2025

 ==============================================================================}
{$mode objfpc}
unit gn_masaustu;

interface

uses gorselnesne, gn_panel, paylasim;

type
  PMasaustu = ^TMasaustu;
  TMasaustu = object(TPanel)
  public
    FMasaustuArkaPlan: TISayi4;       // 1 = renk deðeri, 2 = resim
    FMasaustuRenk: TRenk;
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
  end;

function MasaustuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AMasaustuAdi: string): TKimlik;

implementation

uses gn_islevler, genel, bmp, temelgorselnesne, gn_pencere, gorev, src_vesa20;

{==============================================================================
  masaüstü kesme çaðrýlarýný yönetir
 ==============================================================================}
function MasaustuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  Masaustu: PMasaustu = nil;
  i: TISayi4;
begin

  case AIslevNo of

    ISLEV_OLUSTUR:

      Result := NesneOlustur(PKarakterKatari(PSayi4(ADegiskenler + 04)^ +
        FAktifGorevBellekAdresi)^);

    ISLEV_GOSTER:
    begin

      Masaustu := PMasaustu(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      Masaustu^.Goster;
    end;

    // oluþturulmuþ toplam masaüstü sayýsý
    $010E:
    begin

      Result := GorselNesneler0.ToplamMasaustu;
    end;

    // aktif masaüstü kimliði
    $020E:
    begin

      Result := GAktifMasaustu^.Kimlik;
    end;

    // masaüstünü aktifleþtir
    $020F:
    begin

      // aktifleþtirilecek masaüstü sýra numarasýný al
      i := PISayi4(ADegiskenler + 00)^;

      // eðer belirtilen aralýktaysa ...
      if(i > -1) and (i < USTSINIR_MASAUSTU) then
      begin

        // belirlenen sýradaki masüstü mevcut ise
        if(GMasaustuListesi[i] <> nil) then
        begin

          // masaüstünü aktif olarak iþaretle
          GAktifMasaustu := GMasaustuListesi[i];

          GAktifMasaustu^.Aktiflestir;

          // masaüstünü çiz
          GAktifMasaustu^.Ciz;

          // iþlemin baþarýlý olduðuna dair mesajý geri döndür
          Result := TISayi4(True);

        end else Result := TISayi4(False);
      end else Result := TISayi4(False);
    end;

    // masaüstünü güncelleþtir (yeniden çiz)
    $030F:
    begin

      Masaustu := PMasaustu(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntMasaustu));
      if(Masaustu <> nil) then Masaustu^.Ciz;
    end;

    // masaüstü rengini deðiþtir
    $040F:
    begin

      Masaustu := PMasaustu(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntMasaustu));
      if(Masaustu <> nil) then Masaustu^.MasaustuRenginiDegistir(
        PRenk(ADegiskenler + 04)^);
    end;

    // masaüstü resmini deðiþtir
    $050F:
    begin

      Masaustu := PMasaustu(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntMasaustu));
      if(Masaustu <> nil) then Masaustu^.MasaustuResminiDegistir(
        PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi)^);
    end;

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  masaüstü nesnesini oluþturur
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
  masaüstü nesnesini oluþturur
 ==============================================================================}
function TMasaustu.Olustur(AMasaustuAdi: string): PMasaustu;
var
  Masaustu: PMasaustu = nil;
begin

  // masaüstü nesnesi oluþtur
  Masaustu := Olustur2(AMasaustuAdi);
  if(Masaustu = nil) then
  begin

    Result := nil;
    Exit;
  end;

  Masaustu^.FMasaustuArkaPlan := 1;        // masaüstü arkaplan renk deðeri kullanýlacak
  Masaustu^.FMasaustuRenk := RENK_ZEYTINYESILI;

  // masaüstünün çizileceði bellek adresi
  Masaustu^.FCizimBellekAdresi := GetMem(Masaustu^.FBoyut.Genislik * Masaustu^.FBoyut.Yukseklik * 4);

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

  // tüm masaüstü nesneleri oluþturulduysa çýk
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

  // masaüstü nesnesi için bellekte boþ yer bul
  for i := 0 to USTSINIR_MASAUSTU - 1 do
  begin

    if(GMasaustuListesi[i] = nil) then
    begin

      // 1. masaüstü kimliðini boþ olarak bulunan yere kaydet
      // 2. oluþturulan masaüstü nesne sayýsýný artýr
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

  { TODO : öncelikle ayrýlan bellek serbest býrakýlacak }

  GorselNesneler0.YokEt(AKimlik);
end;

{==============================================================================
  masaüstünü aktifleþtirir / görüntüler
 ==============================================================================}
procedure TMasaustu.Goster;
var
  Masaustu: PMasaustu = nil;
  AltNesneler: PPGorselNesne;
  Pencere: PGorselNesne = nil;
  i: Integer;
begin

  inherited Goster;

  // nesnenin kimlik, tip deðerlerini denetle.
  Masaustu := PMasaustu(GorselNesneler0.NesneTipiniKontrolEt(Kimlik, gntMasaustu));
  if(Masaustu = nil) then Exit;

  // masaüstünü aktifleþtir
  Masaustu^.Aktiflestir;

  Masaustu^.Ciz;

  // masaüstü alt nesnesi olan pencereleri çiz
  if(Masaustu^.AltNesneSayisi > 0) then
  begin

    AltNesneler := Masaustu^.FAltNesneBellekAdresi;

    // ilk oluþturulan pencereden son oluþturulan pencereye doðru nesneleri çiz
    for i := 0 to Masaustu^.AltNesneSayisi - 1 do
    begin

      Pencere := AltNesneler[i];
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
  masaüstünü hizalandýrýr
 ==============================================================================}
procedure TMasaustu.Hizala;
begin

end;

{==============================================================================
  masaüstünü boyutlandýrýr
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
begin

  // nesnenin kimlik, tip deðerlerini denetle.
  Masaustu := PMasaustu(GorselNesneler0.NesneTipiniKontrolEt(Kimlik, gntMasaustu));
  if(Masaustu = nil) then Exit;

  // masaüstü arka plan resmini çiz
  if(Masaustu^.Gorunum) then
  begin

    if(Masaustu^.FMasaustuArkaPlan = 1) then
      MasaustunuRenkIleDoldur
    else BMPGoruntusuCiz(gntMasaustu, Masaustu, Masaustu^.FGoruntuYapi);
  end;

  // tüm pencereleri yeniden çiz
  PencereleriYenidenCiz;
end;

{==============================================================================
  masaüstü olaylarýný iþler
 ==============================================================================}
procedure TMasaustu.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Masaustu: PMasaustu = nil;
  BirOncekiOlay: TISayi4;
begin

  // nesnenin kimlik, tip deðerlerini denetle.
  Masaustu := PMasaustu(AGonderici);

  // sað / sol fare tuþ basýmý
  if(AOlay.Olay = FO_SAGTUS_BASILDI) or (AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // olaylarý bu nesneye yönlendir
    OlayYakalamayaBasla(Masaustu);

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(Masaustu^.OlayYonlendirmeAdresi = nil) then
      Masaustu^.OlayYonlendirmeAdresi(Masaustu, AOlay)
    else Gorevler0.OlayEkle(Masaustu^.GorevKimlik, AOlay);
  end

  // sað / sol fare tuþ býrakýmý
  else if(AOlay.Olay = FO_SAGTUS_BIRAKILDI) or (AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // olaylarý bu nesneye yönlendirmeyi iptal et
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
  masaüstünü aktifleþtirir
 ==============================================================================}
procedure TMasaustu.Aktiflestir;
begin

  // eðer masaüstü nesnesi aktif deðil ise
  if(@Self <> GAktifMasaustu) then
  begin

    // aktif masaüstü olarak belirle
    GAktifMasaustu := @Self;
  end;
end;

{==============================================================================
  masaüstünü belirtilen renk deðeri ile boyar
 ==============================================================================}
procedure TMasaustu.MasaustunuRenkIleDoldur;
var
  Masaustu: PMasaustu = nil;
  Sol, Ust: TISayi4;
  Renk: TRenk;
begin

  // nesnenin kimlik, tip deðerlerini denetle.
  Masaustu := PMasaustu(GorselNesneler0.NesneTipiniKontrolEt(Kimlik, gntMasaustu));
  if(Masaustu = nil) then Exit;

  Masaustu^.FMasaustuArkaPlan := 1;

  Renk := Masaustu^.FMasaustuRenk;

  for Ust := Masaustu^.FCizimAlan.Ust to Masaustu^.FCizimAlan.Alt do
  begin

    for Sol := Masaustu^.FCizimAlan.Sol to Masaustu^.FCizimAlan.Sag do
    begin

      EkranKartSurucusu0.NoktaYaz(Masaustu, Sol, Ust, Renk, False);
    end;
  end;
end;

{==============================================================================
  masaüstü renk deðerini deðiþtirir
 ==============================================================================}
procedure TMasaustu.MasaustuRenginiDegistir(ARenk: TRenk);
var
  Masaustu: PMasaustu = nil;
begin

  Masaustu := PMasaustu(GorselNesneler0.NesneTipiniKontrolEt(Kimlik, gntMasaustu));
  if(Masaustu = nil) then Exit;

  // masaüstünün renk deðerini deðiþtir
  Masaustu^.FMasaustuArkaPlan := 1;
  Masaustu^.FMasaustuRenk := ARenk;

  if(Masaustu^.Gorunum) then Masaustu^.Ciz;
end;

{==============================================================================
  masaüstü resmini deðiþtirir - kesme iþlevi
 ==============================================================================}
procedure TMasaustu.MasaustuResminiDegistir(ADosyaYolu: string);
var
  Masaustu: PMasaustu = nil;
begin

  Masaustu := PMasaustu(GorselNesneler0.NesneTipiniKontrolEt(Kimlik, gntMasaustu));
  if(Masaustu = nil) then Exit;

  GorevDegistirme := 1;

  // masaüstü resmini deðiþtir
  Masaustu^.FMasaustuArkaPlan := 2;

  // daha önce masaüstü resmi için bellek ayrýldýysa belleði iptal et
  if not(Masaustu^.FGoruntuYapi.BellekAdresi = nil) then
  begin

    FreeMem(Masaustu^.FGoruntuYapi.BellekAdresi, Masaustu^.FGoruntuYapi.Genislik *
      Masaustu^.FGoruntuYapi.Yukseklik * 4);

    Masaustu^.FGoruntuYapi.BellekAdresi := nil;
  end;

  // resim dosyasýný masaüstü yapýsýna yükle
  Masaustu^.FGoruntuYapi := BMPDosyasiYukle(ADosyaYolu);

  // arka plan resminin yüklenememesi durumunda arka plan rengini siyah yap
  if(Masaustu^.FGoruntuYapi.BellekAdresi = nil) then
  begin

    Masaustu^.FMasaustuArkaPlan := 1;
    Masaustu^.FMasaustuRenk := RENK_SIYAH;
  end;

  if(Masaustu^.Gorunum) then Masaustu^.Ciz;

  GorevDegistirme := 0;
end;

end.
