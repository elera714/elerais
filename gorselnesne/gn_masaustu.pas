{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: gn_masaustu.pas
  Dosya ��levi: masa�st� y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 26/02/2025

 ==============================================================================}
{$mode objfpc}
unit gn_masaustu;

interface

uses gorselnesne, gn_panel, paylasim;

type
  PMasaustu = ^TMasaustu;
  TMasaustu = object(TPanel)
  public
    FMasaustuArkaPlan: TISayi4;       // 1 = renk de�eri, 2 = resim
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
  masa�st� kesme �a�r�lar�n� y�netir
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

    // olu�turulmu� toplam masa�st� say�s�
    $010E:
    begin

      Result := GorselNesneler0.ToplamMasaustu;
    end;

    // aktif masa�st� kimli�i
    $020E:
    begin

      Result := GAktifMasaustu^.Kimlik;
    end;

    // masa�st�n� aktifle�tir
    $020F:
    begin

      // aktifle�tirilecek masa�st� s�ra numaras�n� al
      i := PISayi4(ADegiskenler + 00)^;

      // e�er belirtilen aral�ktaysa ...
      if(i > -1) and (i < USTSINIR_MASAUSTU) then
      begin

        // belirlenen s�radaki mas�st� mevcut ise
        if(GMasaustuListesi[i] <> nil) then
        begin

          // masa�st�n� aktif olarak i�aretle
          GAktifMasaustu := GMasaustuListesi[i];

          GAktifMasaustu^.Aktiflestir;

          // masa�st�n� �iz
          GAktifMasaustu^.Ciz;

          // i�lemin ba�ar�l� oldu�una dair mesaj� geri d�nd�r
          Result := TISayi4(True);

        end else Result := TISayi4(False);
      end else Result := TISayi4(False);
    end;

    // masa�st�n� g�ncelle�tir (yeniden �iz)
    $030F:
    begin

      Masaustu := PMasaustu(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntMasaustu));
      if(Masaustu <> nil) then Masaustu^.Ciz;
    end;

    // masa�st� rengini de�i�tir
    $040F:
    begin

      Masaustu := PMasaustu(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntMasaustu));
      if(Masaustu <> nil) then Masaustu^.MasaustuRenginiDegistir(
        PRenk(ADegiskenler + 04)^);
    end;

    // masa�st� resmini de�i�tir
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
  masa�st� nesnesini olu�turur
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
  masa�st� nesnesini olu�turur
 ==============================================================================}
function TMasaustu.Olustur(AMasaustuAdi: string): PMasaustu;
var
  Masaustu: PMasaustu = nil;
begin

  // masa�st� nesnesi olu�tur
  Masaustu := Olustur2(AMasaustuAdi);
  if(Masaustu = nil) then
  begin

    Result := nil;
    Exit;
  end;

  Masaustu^.FMasaustuArkaPlan := 1;        // masa�st� arkaplan renk de�eri kullan�lacak
  Masaustu^.FMasaustuRenk := RENK_ZEYTINYESILI;

  // masa�st�n�n �izilece�i bellek adresi
  Masaustu^.FCizimBellekAdresi := GetMem(Masaustu^.FBoyut.Genislik * Masaustu^.FBoyut.Yukseklik * 4);

  // masa�st�ne �izilecek resmin bellek bilgileri
  Masaustu^.FGoruntuYapi.BellekAdresi := nil;

  // nesne adresini geri d�nd�r
  Result := Masaustu;
end;

{==============================================================================
  masa�st� nesnesi i�in yer tahsis eder
 ==============================================================================}
function TMasaustu.Olustur2(AMasaustuAdi: string): PMasaustu;
var
  Masaustu: PMasaustu = nil;
  Genislik, Yukseklik,
  i, j: TISayi4;
begin

  Result := nil;

  // t�m masa�st� nesneleri olu�turulduysa ��k
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

  // masa�st� nesnesi i�in bellekte bo� yer bul
  for i := 0 to USTSINIR_MASAUSTU - 1 do
  begin

    if(GMasaustuListesi[i] = nil) then
    begin

      // 1. masa�st� kimli�ini bo� olarak bulunan yere kaydet
      // 2. olu�turulan masa�st� nesne say�s�n� art�r
      // 3. geriye nesneyi d�nd�r
      GMasaustuListesi[i] := Masaustu;

      j := GorselNesneler0.ToplamMasaustu;
      Inc(j);
      GorselNesneler0.ToplamMasaustu := j;

      // nesne adresini geri d�nd�r
      Exit(Masaustu);
    end;
  end;
end;

procedure TMasaustu.YokEt(AKimlik: TKimlik);
begin

  { TODO : �ncelikle ayr�lan bellek serbest b�rak�lacak }

  GorselNesneler0.YokEt(AKimlik);
end;

{==============================================================================
  masa�st�n� aktifle�tirir / g�r�nt�ler
 ==============================================================================}
procedure TMasaustu.Goster;
var
  Masaustu: PMasaustu = nil;
  AltNesneler: PPGorselNesne;
  Pencere: PGorselNesne = nil;
  i: Integer;
begin

  inherited Goster;

  // nesnenin kimlik, tip de�erlerini denetle.
  Masaustu := PMasaustu(GorselNesneler0.NesneTipiniKontrolEt(Kimlik, gntMasaustu));
  if(Masaustu = nil) then Exit;

  // masa�st�n� aktifle�tir
  Masaustu^.Aktiflestir;

  Masaustu^.Ciz;

  // masa�st� alt nesnesi olan pencereleri �iz
  if(Masaustu^.AltNesneSayisi > 0) then
  begin

    AltNesneler := Masaustu^.FAltNesneBellekAdresi;

    // ilk olu�turulan pencereden son olu�turulan pencereye do�ru nesneleri �iz
    for i := 0 to Masaustu^.AltNesneSayisi - 1 do
    begin

      Pencere := AltNesneler[i];
      if(Pencere^.Gorunum) and (Pencere^.NesneTipi = gntPencere) then
        PPencere(Pencere)^.Ciz;
    end;
  end;
end;

{==============================================================================
  masa�st�n� gizler
 ==============================================================================}
procedure TMasaustu.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  masa�st�n� hizaland�r�r
 ==============================================================================}
procedure TMasaustu.Hizala;
begin

end;

{==============================================================================
  masa�st�n� boyutland�r�r
 ==============================================================================}
procedure TMasaustu.Boyutlandir;
begin

end;

{==============================================================================
  masa�st�n� �izer
 ==============================================================================}
procedure TMasaustu.Ciz;
var
  Masaustu: PMasaustu = nil;
begin

  // nesnenin kimlik, tip de�erlerini denetle.
  Masaustu := PMasaustu(GorselNesneler0.NesneTipiniKontrolEt(Kimlik, gntMasaustu));
  if(Masaustu = nil) then Exit;

  // masa�st� arka plan resmini �iz
  if(Masaustu^.Gorunum) then
  begin

    if(Masaustu^.FMasaustuArkaPlan = 1) then
      MasaustunuRenkIleDoldur
    else BMPGoruntusuCiz(gntMasaustu, Masaustu, Masaustu^.FGoruntuYapi);
  end;

  // t�m pencereleri yeniden �iz
  PencereleriYenidenCiz;
end;

{==============================================================================
  masa�st� olaylar�n� i�ler
 ==============================================================================}
procedure TMasaustu.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Masaustu: PMasaustu = nil;
  BirOncekiOlay: TISayi4;
begin

  // nesnenin kimlik, tip de�erlerini denetle.
  Masaustu := PMasaustu(AGonderici);

  // sa� / sol fare tu� bas�m�
  if(AOlay.Olay = FO_SAGTUS_BASILDI) or (AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // olaylar� bu nesneye y�nlendir
    OlayYakalamayaBasla(Masaustu);

    // uygulamaya veya efendi nesneye mesaj g�nder
    if not(Masaustu^.OlayYonlendirmeAdresi = nil) then
      Masaustu^.OlayYonlendirmeAdresi(Masaustu, AOlay)
    else Gorevler0.OlayEkle(Masaustu^.GorevKimlik, AOlay);
  end

  // sa� / sol fare tu� b�rak�m�
  else if(AOlay.Olay = FO_SAGTUS_BIRAKILDI) or (AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // olaylar� bu nesneye y�nlendirmeyi iptal et
    OlayYakalamayiBirak(Masaustu);

    BirOncekiOlay := AOlay.Olay;

    // uygulamaya mesaj g�nder
    if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
    begin

      // uygulamaya veya efendi nesneye mesaj g�nder
      AOlay.Olay := FO_TIKLAMA;
      if not(Masaustu^.OlayYonlendirmeAdresi = nil) then
        Masaustu^.OlayYonlendirmeAdresi(Masaustu, AOlay)
      else Gorevler0.OlayEkle(Masaustu^.GorevKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj g�nder
    AOlay.Olay := BirOncekiOlay;
    if not(Masaustu^.OlayYonlendirmeAdresi = nil) then
      Masaustu^.OlayYonlendirmeAdresi(Masaustu, AOlay)
    else Gorevler0.OlayEkle(Masaustu^.GorevKimlik, AOlay);
  end;

  // ge�erli fare g�stergesini g�ncelle
  GecerliFareGostegeTipi := Masaustu^.FareImlecTipi;
end;

{==============================================================================
  masa�st�n� aktifle�tirir
 ==============================================================================}
procedure TMasaustu.Aktiflestir;
begin

  // e�er masa�st� nesnesi aktif de�il ise
  if(@Self <> GAktifMasaustu) then
  begin

    // aktif masa�st� olarak belirle
    GAktifMasaustu := @Self;
  end;
end;

{==============================================================================
  masa�st�n� belirtilen renk de�eri ile boyar
 ==============================================================================}
procedure TMasaustu.MasaustunuRenkIleDoldur;
var
  Masaustu: PMasaustu = nil;
  Sol, Ust: TISayi4;
  Renk: TRenk;
begin

  // nesnenin kimlik, tip de�erlerini denetle.
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
  masa�st� renk de�erini de�i�tirir
 ==============================================================================}
procedure TMasaustu.MasaustuRenginiDegistir(ARenk: TRenk);
var
  Masaustu: PMasaustu = nil;
begin

  Masaustu := PMasaustu(GorselNesneler0.NesneTipiniKontrolEt(Kimlik, gntMasaustu));
  if(Masaustu = nil) then Exit;

  // masa�st�n�n renk de�erini de�i�tir
  Masaustu^.FMasaustuArkaPlan := 1;
  Masaustu^.FMasaustuRenk := ARenk;

  if(Masaustu^.Gorunum) then Masaustu^.Ciz;
end;

{==============================================================================
  masa�st� resmini de�i�tirir - kesme i�levi
 ==============================================================================}
procedure TMasaustu.MasaustuResminiDegistir(ADosyaYolu: string);
var
  Masaustu: PMasaustu = nil;
begin

  Masaustu := PMasaustu(GorselNesneler0.NesneTipiniKontrolEt(Kimlik, gntMasaustu));
  if(Masaustu = nil) then Exit;

  GorevDegistirme := 1;

  // masa�st� resmini de�i�tir
  Masaustu^.FMasaustuArkaPlan := 2;

  // daha �nce masa�st� resmi i�in bellek ayr�ld�ysa belle�i iptal et
  if not(Masaustu^.FGoruntuYapi.BellekAdresi = nil) then
  begin

    FreeMem(Masaustu^.FGoruntuYapi.BellekAdresi, Masaustu^.FGoruntuYapi.Genislik *
      Masaustu^.FGoruntuYapi.Yukseklik * 4);

    Masaustu^.FGoruntuYapi.BellekAdresi := nil;
  end;

  // resim dosyas�n� masa�st� yap�s�na y�kle
  Masaustu^.FGoruntuYapi := BMPDosyasiYukle(ADosyaYolu);

  // arka plan resminin y�klenememesi durumunda arka plan rengini siyah yap
  if(Masaustu^.FGoruntuYapi.BellekAdresi = nil) then
  begin

    Masaustu^.FMasaustuArkaPlan := 1;
    Masaustu^.FMasaustuRenk := RENK_SIYAH;
  end;

  if(Masaustu^.Gorunum) then Masaustu^.Ciz;

  GorevDegistirme := 0;
end;

end.
