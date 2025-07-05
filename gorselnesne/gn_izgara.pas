{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: gn_izgara.pas
  Dosya ��levi: �zgara nesnesi (TStringGrid) y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 26/02/2025

 ==============================================================================}
{$mode objfpc}
unit gn_izgara;

interface

uses gorselnesne, paylasim, n_yazilistesi, gn_panel, gn_kaydirmacubugu;

type
  PIzgara = ^TIzgara;
  TIzgara = object(TPanel)
  private
    FYatayKCubugu, FDikeyKCubugu: PKaydirmaCubugu;
    FYatayKCGoster, FDikeyKCGoster: LongBool;
    FSabitSutunSayisi, FSabitSatirSayisi: TISayi4;
    FSutunSayisi, FSatirSayisi,
    FSutunGenislik, FSatirYukseklik: TISayi4;
    FSeciliSatir, FSeciliSutun: TISayi4;  // se�ili sat�r ve s�tun
    FGorunenIlkSiraNo: TISayi4;           // �zgara nesnesinde en �stte g�r�nt�lenen eleman�n s�ra de�eri
    FGorunenElemanSayisi: TISayi4;        // kullan�c�ya nesne i�erisinde g�sterilen eleman say�s�
    FDegerler: PYaziListesi;              // kolon de�erleri
    procedure KaydirmaCubuguOlaylariniIsle(AGonderici: PGorselNesne; AOlay: TOlay);
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4): PIzgara;
    procedure YokEt;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
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
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;

implementation

uses genel, gn_islevler, gn_pencere, temelgorselnesne, sistemmesaj, gorev;

{==============================================================================
  �zgara nesnesi kesme �a�r�lar�n� y�netir
 ==============================================================================}
function IzgaraCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne = nil;
  Pencere: PPencere = nil;
  Izgara: PIzgara = nil;
  Hiza: THiza;
begin

  case AIslevNo of

    // nesne olu�tur
    ISLEV_OLUSTUR:
    begin

      GN := GN^.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^);
    end;

    ISLEV_GOSTER:
    begin

      Izgara := PIzgara(Izgara^.NesneAl(PKimlik(ADegiskenler + 00)^));
      Izgara^.Goster;
    end;

    ISLEV_GIZLE:
    begin

      Izgara := PIzgara(Izgara^.NesneAl(PKimlik(ADegiskenler + 00)^));
      Izgara^.Gizle;
    end;

    ISLEV_CIZ:
    begin

      Izgara := PIzgara(Izgara^.NesneAl(PKimlik(ADegiskenler + 00)^));
      Izgara^.Ciz;
    end;

    // g�rsel nesneyi hizala
    ISLEV_HIZALA:
    begin

      Izgara := PIzgara(Izgara^.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      Izgara^.FHiza := Hiza;

      Pencere := PPencere(Izgara^.FAtaNesne);
      Pencere^.Guncelle;
    end;

    // de�er i�eriklerini temizle
    $010F:
    begin

      Izgara := PIzgara(Izgara^.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Izgara <> nil) then Izgara^.DegerIceriginiTemizle;
    end;

    // de�er listesine de�er ekle
    $020F:
    begin

      Izgara := PIzgara(Izgara^.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntIzgara));
      if(Izgara <> nil) then Result := TISayi4(Izgara^.DegerEkle(
        PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi)^));
    end;

    // sabit sat�r ve sutun h�cre say�s�n� belirle
    $030F:
    begin

      Izgara := PIzgara(Izgara^.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Izgara <> nil) then Izgara^.SabitHucreSayisiYaz(
        PSayi4(ADegiskenler + 04)^, PSayi4(ADegiskenler + 08)^);
    end;

    // h�cre say�s�n� belirle
    $040F:
    begin

      Izgara := PIzgara(Izgara^.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Izgara <> nil) then Izgara^.HucreSayisiYaz(
        PSayi4(ADegiskenler + 04)^, PSayi4(ADegiskenler + 08)^);
    end;

    // h�cre boyutu belirle
    $050F:
    begin

      Izgara := PIzgara(Izgara^.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Izgara <> nil) then Izgara^.HucreBoyutuYaz(
        PSayi4(ADegiskenler + 04)^, PSayi4(ADegiskenler + 08)^);
    end;

    // kayd�rma �ubu�u g�r�n�m belirle
    $060F:
    begin

      Izgara := PIzgara(Izgara^.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Izgara <> nil) then Izgara^.KaydirmaCubuguGorunumYaz(
        PLongBool(ADegiskenler + 04)^, PLongBool(ADegiskenler + 08)^);
    end;

    // se�ili h�creyi belirle
    $070F:
    begin

      Izgara := PIzgara(Izgara^.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Izgara <> nil) then Izgara^.SeciliHucreyiYaz(
        PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^);
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  �zgara nesnesi olu�turur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
var
  Izgara: PIzgara = nil;
begin

  Izgara := Izgara^.Olustur(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik);
  if(Izgara = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := Izgara^.Kimlik;
end;

{==============================================================================
  �zgara nesnesi olu�turur
 ==============================================================================}
function TIzgara.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4): PIzgara;
var
  Izgara: PIzgara = nil;
begin

  Izgara := PIzgara(inherited Olustur(AKullanimTipi, AAtaNesne, ASol, AUst,
    AGenislik, AYukseklik, 2, RENK_GRI, RENK_GRI, 0, ''));

  Izgara^.NesneTipi := gntIzgara;

  Izgara^.Baslik := '';

  Izgara^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  Izgara^.Odaklanilabilir := True;
  Izgara^.Odaklanildi := False;

  Izgara^.OlayCagriAdresi := @OlaylariIsle;

  Izgara^.FYatayKCGoster := False;
  Izgara^.FDikeyKCGoster := False;

  // yatay kayd�rma �ubu�u
  Izgara^.FYatayKCubugu := Izgara^.FYatayKCubugu^.Olustur(ktBilesen, Izgara,
    0, AYukseklik - 16, AGenislik - 16, 16, yYatay);
  Izgara^.FYatayKCubugu^.DegerleriBelirle(0, 10);
  Izgara^.FYatayKCubugu^.OlayYonlendirmeAdresi := @KaydirmaCubuguOlaylariniIsle;

  // dikey kayd�rma �ubu�u
  Izgara^.FDikeyKCubugu := Izgara^.FDikeyKCubugu^.Olustur(ktBilesen, Izgara,
    AGenislik - 16, 0, 16, AYukseklik - 16, yDikey);
  Izgara^.FDikeyKCubugu^.DegerleriBelirle(0, 10);
  Izgara^.FDikeyKCubugu^.OlayYonlendirmeAdresi := @KaydirmaCubuguOlaylariniIsle;

  Izgara^.FDegerler := Izgara^.FDegerler^.Olustur;

  // nesnenin kullanaca�� di�er de�erler
  Izgara^.FGorunenIlkSiraNo := 0;
  Izgara^.FSeciliSatir := -1;
  Izgara^.FSeciliSutun := -1;

  // �zgara nesnesinde g�r�nt�lenecek eleman say�s�
  Izgara^.FGorunenElemanSayisi := (AYukseklik - 24) div 21;

  Izgara^.FSabitSatirSayisi := 1;
  Izgara^.FSabitSutunSayisi := 0;
  Izgara^.FSatirSayisi := 7;
  Izgara^.FSutunSayisi := 7;
  Izgara^.FSatirYukseklik := 18;
  Izgara^.FSutunGenislik := 40;

  // nesne adresini geri d�nd�r
  Result := Izgara;
end;

{==============================================================================
  �zgara nesnesini yok eder
 ==============================================================================}
procedure TIzgara.YokEt;
var
  Izgara: PIzgara = nil;
begin

  Izgara := PIzgara(Izgara^.NesneAl(Kimlik));
  if(Izgara = nil) then Exit;

  if(Izgara^.FDegerler <> nil) then Izgara^.FDegerler^.YokEt;

  inherited YokEt;
end;

{==============================================================================
  �zgara nesnesini g�r�nt�ler
 ==============================================================================}
procedure TIzgara.Goster;
var
  Izgara: PIzgara = nil;
begin

  Izgara := PIzgara(Izgara^.NesneAl(Kimlik));
  if(Izgara = nil) then Exit;

  if(Izgara^.FYatayKCGoster) then Izgara^.FYatayKCubugu^.Goster;
  if(Izgara^.FDikeyKCGoster) then Izgara^.FDikeyKCubugu^.Goster;

  inherited Goster;
end;

{==============================================================================
  �zgara nesnesini gizler
 ==============================================================================}
procedure TIzgara.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  �zgara nesnesini hizaland�r�r
 ==============================================================================}
procedure TIzgara.Hizala;
var
  Izgara: PIzgara = nil;
begin

  Izgara := PIzgara(Izgara^.NesneAl(Kimlik));
  if(Izgara = nil) then Exit;

  inherited Hizala;

  if(Izgara^.FYatayKCGoster) then
  begin

    // yatay kayd�rma �ubu�unu elle yeniden konumland�r
    Izgara^.FYatayKCubugu^.FKonum.Sol := 0;
    Izgara^.FYatayKCubugu^.FKonum.Ust := Izgara^.FBoyut.Yukseklik - 16;
    Izgara^.FYatayKCubugu^.FBoyut.Genislik := Izgara^.FBoyut.Genislik - 16;
    Izgara^.FYatayKCubugu^.FBoyut.Yukseklik := 16;

    Izgara^.FYatayKCubugu^.FCizimAlan.Sol := 0;
    Izgara^.FYatayKCubugu^.FCizimAlan.Ust := 0;
    Izgara^.FYatayKCubugu^.FCizimAlan.Sag := Izgara^.FYatayKCubugu^.FBoyut.Genislik - 1;
    Izgara^.FYatayKCubugu^.FCizimAlan.Alt := Izgara^.FYatayKCubugu^.FBoyut.Yukseklik - 1;

    Izgara^.FYatayKCubugu^.FCizimBaslangic.Sol := Izgara^.FCizimBaslangic.Sol + Izgara^.FYatayKCubugu^.FKonum.Sol;
    Izgara^.FYatayKCubugu^.FCizimBaslangic.Ust := Izgara^.FCizimBaslangic.Ust + Izgara^.FYatayKCubugu^.FKonum.Ust;
    Izgara^.FYatayKCubugu^.Hizala;
  end;

  if(Izgara^.FDikeyKCGoster) then
  begin

    // dikey kayd�rma �ubu�unu elle yeniden konumland�r
    Izgara^.FDikeyKCubugu^.FKonum.Sol := Izgara^.FBoyut.Genislik - 16;
    Izgara^.FDikeyKCubugu^.FKonum.Ust := 0;
    Izgara^.FDikeyKCubugu^.FBoyut.Genislik := 16;
    Izgara^.FDikeyKCubugu^.FBoyut.Yukseklik := Izgara^.FBoyut.Yukseklik - 16;

    Izgara^.FDikeyKCubugu^.FCizimAlan.Sol := 0;
    Izgara^.FDikeyKCubugu^.FCizimAlan.Ust := 0;
    Izgara^.FDikeyKCubugu^.FCizimAlan.Sag := Izgara^.FDikeyKCubugu^.FBoyut.Genislik - 1;
    Izgara^.FDikeyKCubugu^.FCizimAlan.Alt := Izgara^.FDikeyKCubugu^.FBoyut.Yukseklik - 1;

    Izgara^.FDikeyKCubugu^.FCizimBaslangic.Sol := Izgara^.FCizimBaslangic.Sol + Izgara^.FDikeyKCubugu^.FKonum.Sol;
    Izgara^.FDikeyKCubugu^.FCizimBaslangic.Ust := Izgara^.FCizimBaslangic.Ust + Izgara^.FDikeyKCubugu^.FKonum.Ust;
    Izgara^.FDikeyKCubugu^.Hizala;
  end;
end;

{==============================================================================
  �zgara nesnesini �izer
 ==============================================================================}
procedure TIzgara.Ciz;
var
  Pencere: PPencere = nil;
  Izgara: PIzgara = nil;
  Alan: TAlan;
  i, j, SolIlk, UstIlk: TISayi4;
begin

  Izgara := PIzgara(Izgara^.NesneAl(Kimlik));
  if(Izgara = nil) then Exit;

  inherited Ciz;

  // kayd�rma �ubu�unun �izim alan koordinatlar�n� al
  Alan := Izgara^.FCizimAlan;

  // ata nesne bir pencere mi?
  Pencere := EnUstPencereNesnesiniAl(Izgara);
  if(Pencere = nil) then Exit;

  // tan�mlanm�� hi�bir kolon yok ise, ��k
  if(FDegerler^.ElemanSayisi = 0) then Exit;

  if(Izgara^.FYatayKCGoster) then
    SolIlk := Izgara^.FYatayKCubugu^.FMevcutDeger
  else SolIlk := 0;

  if(Izgara^.FDikeyKCGoster) then
    UstIlk := Izgara^.FDikeyKCubugu^.FMevcutDeger
  else UstIlk := 0;

  Alan.Sol := 1;
  Alan.Ust := 1;

  // veriye g�re yap�lan d�ng�
  for i := UstIlk to FSatirSayisi - 1 do
  begin

    for j := SolIlk to FSutunSayisi - 1 do
    begin

      Alan.Sag := Alan.Sol + Izgara^.FSutunGenislik - 1;
      Alan.Alt := Alan.Ust + Izgara^.FSatirYukseklik - 1;

      if(i < Izgara^.FSabitSatirSayisi) then
        Izgara^.EgimliDoldur3(Izgara, Alan, $EAECEE, $ABB2B9)
      else if(j < Izgara^.FSabitSutunSayisi) then
        Izgara^.EgimliDoldur3(Izgara, Alan, $EAECEE, $ABB2B9)

      else if(Izgara^.FSeciliSatir = i) and (Izgara^.FSeciliSutun = j) then
        Izgara^.DikdortgenDoldur(Izgara, Alan, RENK_KIRMIZI, RENK_BEYAZ)
      else Izgara^.DikdortgenDoldur(Izgara, Alan, RENK_BEYAZ, RENK_BEYAZ);

      // ba�l�k
      Izgara^.AlanaYaziYaz(Izgara, Alan, 4, 3, FDegerler^.Eleman[(i * (Izgara^.FSutunSayisi)) + j],
        RENK_LACIVERT);

      Alan.Sol += Izgara^.FSutunGenislik + 1;
    end;

    Alan.Sol := 1;
    Alan.Ust += Izgara^.FSatirYukseklik + 1;
  end;

  // kayd�rma �ubuklar�n� en son �iz
  if(Izgara^.FYatayKCGoster) then Izgara^.FYatayKCubugu^.Ciz;
  if(Izgara^.FDikeyKCGoster) then Izgara^.FDikeyKCubugu^.Ciz;
end;

{==============================================================================
  �zgara nesnesi olaylar�n� i�ler
 ==============================================================================}
procedure TIzgara.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere = nil;
  Izgara: PIzgara = nil;
  i, j: TISayi4;
begin

  Izgara := PIzgara(AGonderici);

  // sol fare tu� bas�m�
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // �zgara nesnesinin sahibi olan pencere en �stte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(Izgara);

    // en �stte olmamas� durumunda en �ste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak i�aretle
    Pencere^.FAktifNesne := Izgara;
    Izgara^.Odaklanildi := True;

    // sol tu�a bas�m i�lemi nesnenin olay alan�nda m� ger�ekle�ti ?
    if(Izgara^.FareNesneOlayAlanindaMi(Izgara)) then
    begin

      // fare olaylar�n� yakala
      OlayYakalamayaBasla(Izgara);

      // se�ili s�t�n ve sat�r de�erini yeniden belirle
      i := (AOlay.Deger1 + (Izgara^.FYatayKCubugu^.FMevcutDeger * Izgara^.FSutunGenislik)) div Izgara^.FSutunGenislik;
      j := (AOlay.Deger2 + (Izgara^.FDikeyKCubugu^.FMevcutDeger * Izgara^.FSatirYukseklik)) div Izgara^.FSatirYukseklik;
      if(i >= Izgara^.FSabitSutunSayisi) and (j >= Izgara^.FSabitSatirSayisi) then
      begin

        Izgara^.FSeciliSutun := i;
        Izgara^.FSeciliSatir := j;
      end;

      // �zgara nesnesini yeniden �iz
      Izgara^.Ciz;

      // uygulamaya veya efendi nesneye mesaj g�nder
      if not(Izgara^.OlayYonlendirmeAdresi = nil) then
        Izgara^.OlayYonlendirmeAdresi(Izgara, AOlay)
      else GGorevler.OlayEkle(Izgara^.GorevKimlik, AOlay);
    end;
  end

  // sol fare tu� b�rak�m i�lemi
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylar�n� almay� b�rak
    OlayYakalamayiBirak(Izgara);

    // fare b�rakma i�lemi nesnenin olay alan�nda m� ger�ekle�ti ?
    if(Izgara^.FareNesneOlayAlanindaMi(Izgara)) then
    begin

      // yakalama & b�rakma i�lemi bu nesnede oldu�u i�in
      // nesneye FO_TIKLAMA mesaj� g�nder
      AOlay.Olay := FO_TIKLAMA;
      if not(Izgara^.OlayYonlendirmeAdresi = nil) then
        Izgara^.OlayYonlendirmeAdresi(Izgara, AOlay)
      else GGorevler.OlayEkle(Izgara^.GorevKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj g�nder
    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    if not(Izgara^.OlayYonlendirmeAdresi = nil) then
      Izgara^.OlayYonlendirmeAdresi(Izgara, AOlay)
    else GGorevler.OlayEkle(Izgara^.GorevKimlik, AOlay);
  end;

  // ge�erli fare g�stergesini g�ncelle
  GecerliFareGostegeTipi := Izgara^.FFareImlecTipi;
end;

procedure TIzgara.KaydirmaCubuguOlaylariniIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Izgara: PIzgara = nil;
  KaydirmaCubugu: PKaydirmaCubugu = nil;
begin

  KaydirmaCubugu := PKaydirmaCubugu(AGonderici);
  if(KaydirmaCubugu = nil) then Exit;

  Izgara := PIzgara(KaydirmaCubugu^.AtaNesne);

  if(AOlay.Olay = FO_TIKLAMA) then Izgara^.Ciz;

  // ge�erli fare g�stergesini g�ncelle
  GecerliFareGostegeTipi := Izgara^.FFareImlecTipi;
end;

procedure TIzgara.HucreSayisiYaz(ASatirSayisi, ASutunSayisi: TSayi4);
var
  Izgara: PIzgara = nil;
begin

  Izgara := PIzgara(Izgara^.NesneAl(Kimlik));
  if(Izgara = nil) then Exit;

  Izgara^.FSatirSayisi := ASatirSayisi;
  Izgara^.FSutunSayisi := ASutunSayisi;
end;

procedure TIzgara.HucreBoyutuYaz(ASatirYukseklik, ASutunGenislik: TSayi4);
var
  Izgara: PIzgara = nil;
begin

  Izgara := PIzgara(Izgara^.NesneAl(Kimlik));
  if(Izgara = nil) then Exit;

  Izgara^.FSatirYukseklik := ASatirYukseklik;
  Izgara^.FSutunGenislik := ASutunGenislik;
end;

procedure TIzgara.SabitHucreSayisiYaz(ASabitSatirSayisi, ASabitSutunSayisi: TSayi4);
var
  Izgara: PIzgara = nil;
begin

  Izgara := PIzgara(Izgara^.NesneAl(Kimlik));
  if(Izgara = nil) then Exit;

  Izgara^.FSabitSatirSayisi := ASabitSatirSayisi;
  Izgara^.FSabitSutunSayisi := ASabitSutunSayisi;
end;

procedure TIzgara.KaydirmaCubuguGorunumYaz(AYatayKCGoster, ADikeyKCGoster: Boolean);
var
  Izgara: PIzgara = nil;
begin

  Izgara := PIzgara(Izgara^.NesneAl(Kimlik));
  if(Izgara = nil) then Exit;

  Izgara^.FYatayKCGoster := AYatayKCGoster;
  Izgara^.FDikeyKCGoster := ADikeyKCGoster;

  if(Izgara^.FYatayKCGoster) then
    Izgara^.FYatayKCubugu^.Goster
  else Izgara^.FYatayKCubugu^.Gizle;

  if(Izgara^.FDikeyKCGoster) then
    Izgara^.FDikeyKCubugu^.Goster
  else Izgara^.FDikeyKCubugu^.Gizle;

  Izgara^.Ciz;
end;

procedure TIzgara.SeciliHucreyiYaz(ASatir, ASutun: TISayi4);
var
  Izgara: PIzgara = nil;
begin

  Izgara := PIzgara(Izgara^.NesneAl(Kimlik));
  if(Izgara = nil) then Exit;

  Izgara^.FSeciliSatir := ASatir;
  Izgara^.FSeciliSutun := ASutun;

  Izgara^.Ciz;
end;

{==============================================================================
  se�ili eleman�n yaz� (text) de�erini geri d�nd�r�r
 ==============================================================================}
function TIzgara.SeciliSatirDegeriniAl: string;
var
  Izgara: PIzgara = nil;
begin

  // nesnenin kimlik, tip de�erlerini denetle.
  Izgara := PIzgara(Izgara^.NesneTipiniKontrolEt(Kimlik, gntIzgara));
  if(Izgara = nil) then Exit;

  if(FSeciliSutun = -1) or (FSeciliSutun > FDegerler^.ElemanSayisi) then Exit('');

  Result := Izgara^.FDegerler^.Eleman[FSeciliSutun];
end;

{==============================================================================
  | ay�rac�yla gelen karakter katar�n� b�l�mler
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

        if(i = Uzunluk) then s += ABicimlenmisDeger[i];

        if(Length(s) > 0) then
        begin

          ADegerDizisi^.Ekle(s);
          s := '';
        end;
      end else s += ABicimlenmisDeger[i];

      Inc(i);
    end;
  end;
end;

function TIzgara.DegerEkle(ADeger: string): Boolean;
var
  Izgara: PIzgara = nil;
begin

  // nesnenin kimlik, tip de�erlerini denetle.
  Izgara := PIzgara(Izgara^.NesneAl(Kimlik));
  if(Izgara = nil) then Exit;

  Izgara^.FDegerler^.Ekle(ADeger);

  Result := True;
end;

procedure TIzgara.DegerIceriginiTemizle;
var
  Izgara: PIzgara = nil;
begin

  // nesnenin kimlik, tip de�erlerini denetle.
  Izgara := PIzgara(Izgara^.NesneAl(Kimlik));
  if(Izgara = nil) then Exit;

  Izgara^.FDegerler^.Temizle;
  Izgara^.FGorunenIlkSiraNo := 0;
  Izgara^.FSeciliSatir := -1;
  Izgara^.FSeciliSutun := -1;

  Izgara^.Ciz;
end;

end.
