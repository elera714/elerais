{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: gn_izgara.pas
  Dosya Ýþlevi: ýzgara nesnesi (TStringGrid) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 26/02/2025

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
    FSeciliSatir, FSeciliSutun: TISayi4;  // seçili satýr ve sütun
    FGorunenIlkSiraNo: TISayi4;           // ýzgara nesnesinde en üstte görüntülenen elemanýn sýra deðeri
    FGorunenElemanSayisi: TISayi4;        // kullanýcýya nesne içerisinde gösterilen eleman sayýsý
    FDegerler: PYaziListesi;              // kolon deðerleri
    procedure KaydirmaCubuguOlaylariniIsle(AGonderici: PGorselNesne; AOlay: TOlay);
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4): PIzgara;
    procedure YokEt(AKimlik: TKimlik);
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
  ýzgara nesnesi kesme çaðrýlarýný yönetir
 ==============================================================================}
function IzgaraCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne = nil;
  Pencere: PPencere = nil;
  Izgara: PIzgara = nil;
  Hiza: THiza;
begin

  case AIslevNo of

    // nesne oluþtur
    ISLEV_OLUSTUR:
    begin

      GN := GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^);
    end;

    ISLEV_GOSTER:
    begin

      Izgara := PIzgara(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      Izgara^.Goster;
    end;

    ISLEV_GIZLE:
    begin

      Izgara := PIzgara(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      Izgara^.Gizle;
    end;

    ISLEV_CIZ:
    begin

      Izgara := PIzgara(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      Izgara^.Ciz;
    end;

    // görsel nesneyi hizala
    ISLEV_HIZALA:
    begin

      Izgara := PIzgara(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      Izgara^.FHiza := Hiza;

      Pencere := PPencere(Izgara^.FAtaNesne);
      Pencere^.Guncelle;
    end;

    // deðer içeriklerini temizle
    $010F:
    begin

      Izgara := PIzgara(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Izgara <> nil) then Izgara^.DegerIceriginiTemizle;
    end;

    // deðer listesine deðer ekle
    $020F:
    begin

      Izgara := PIzgara(GorselNesneler0.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntIzgara));
      if(Izgara <> nil) then Result := TISayi4(Izgara^.DegerEkle(
        PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi)^));
    end;

    // sabit satýr ve sutun hücre sayýsýný belirle
    $030F:
    begin

      Izgara := PIzgara(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Izgara <> nil) then Izgara^.SabitHucreSayisiYaz(
        PSayi4(ADegiskenler + 04)^, PSayi4(ADegiskenler + 08)^);
    end;

    // hücre sayýsýný belirle
    $040F:
    begin

      Izgara := PIzgara(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Izgara <> nil) then Izgara^.HucreSayisiYaz(
        PSayi4(ADegiskenler + 04)^, PSayi4(ADegiskenler + 08)^);
    end;

    // hücre boyutu belirle
    $050F:
    begin

      Izgara := PIzgara(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Izgara <> nil) then Izgara^.HucreBoyutuYaz(
        PSayi4(ADegiskenler + 04)^, PSayi4(ADegiskenler + 08)^);
    end;

    // kaydýrma çubuðu görünüm belirle
    $060F:
    begin

      Izgara := PIzgara(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Izgara <> nil) then Izgara^.KaydirmaCubuguGorunumYaz(
        PLongBool(ADegiskenler + 04)^, PLongBool(ADegiskenler + 08)^);
    end;

    // seçili hücreyi belirle
    $070F:
    begin

      Izgara := PIzgara(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Izgara <> nil) then Izgara^.SeciliHucreyiYaz(
        PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^);
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  ýzgara nesnesi oluþturur
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
  ýzgara nesnesi oluþturur
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

  // yatay kaydýrma çubuðu
  Izgara^.FYatayKCubugu := Izgara^.FYatayKCubugu^.Olustur(ktBilesen, Izgara,
    0, AYukseklik - 16, AGenislik - 16, 16, yYatay);
  Izgara^.FYatayKCubugu^.DegerleriBelirle(0, 10);
  Izgara^.FYatayKCubugu^.OlayYonlendirmeAdresi := @KaydirmaCubuguOlaylariniIsle;

  // dikey kaydýrma çubuðu
  Izgara^.FDikeyKCubugu := Izgara^.FDikeyKCubugu^.Olustur(ktBilesen, Izgara,
    AGenislik - 16, 0, 16, AYukseklik - 16, yDikey);
  Izgara^.FDikeyKCubugu^.DegerleriBelirle(0, 10);
  Izgara^.FDikeyKCubugu^.OlayYonlendirmeAdresi := @KaydirmaCubuguOlaylariniIsle;

  Izgara^.FDegerler := YaziListesi0.Olustur;

  // nesnenin kullanacaðý diðer deðerler
  Izgara^.FGorunenIlkSiraNo := 0;
  Izgara^.FSeciliSatir := -1;
  Izgara^.FSeciliSutun := -1;

  // ýzgara nesnesinde görüntülenecek eleman sayýsý
  Izgara^.FGorunenElemanSayisi := (AYukseklik - 24) div 21;

  Izgara^.FSabitSatirSayisi := 1;
  Izgara^.FSabitSutunSayisi := 0;
  Izgara^.FSatirSayisi := 7;
  Izgara^.FSutunSayisi := 7;
  Izgara^.FSatirYukseklik := 18;
  Izgara^.FSutunGenislik := 40;

  // nesne adresini geri döndür
  Result := Izgara;
end;

{==============================================================================
  ýzgara nesnesini yok eder
 ==============================================================================}
procedure TIzgara.YokEt(AKimlik: TKimlik);
var
  Izgara: PIzgara = nil;
begin

  Izgara := PIzgara(GorselNesneler0.NesneAl(AKimlik));
  if(Izgara = nil) then Exit;

  Izgara^.FYatayKCubugu^.YokEt(Izgara^.FYatayKCubugu^.Kimlik);
  Izgara^.FDikeyKCubugu^.YokEt(Izgara^.FDikeyKCubugu^.Kimlik);

  if(Izgara^.FDegerler <> nil) then YaziListesi0.YokEt(Izgara^.FDegerler^.Kimlik);

  inherited YokEt(AKimlik);
end;

{==============================================================================
  ýzgara nesnesini görüntüler
 ==============================================================================}
procedure TIzgara.Goster;
var
  Izgara: PIzgara = nil;
begin

  Izgara := PIzgara(GorselNesneler0.NesneAl(Kimlik));
  if(Izgara = nil) then Exit;

  if(Izgara^.FYatayKCGoster) then Izgara^.FYatayKCubugu^.Goster;
  if(Izgara^.FDikeyKCGoster) then Izgara^.FDikeyKCubugu^.Goster;

  inherited Goster;
end;

{==============================================================================
  ýzgara nesnesini gizler
 ==============================================================================}
procedure TIzgara.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  ýzgara nesnesini hizalandýrýr
 ==============================================================================}
procedure TIzgara.Hizala;
var
  Izgara: PIzgara = nil;
begin

  Izgara := PIzgara(GorselNesneler0.NesneAl(Kimlik));
  if(Izgara = nil) then Exit;

  inherited Hizala;

  if(Izgara^.FYatayKCGoster) then
  begin

    // yatay kaydýrma çubuðunu elle yeniden konumlandýr
    Izgara^.FYatayKCubugu^.FAtananAlan.Sol := 0;
    Izgara^.FYatayKCubugu^.FAtananAlan.Ust := Izgara^.FAtananAlan.Yukseklik - 16;
    Izgara^.FYatayKCubugu^.FAtananAlan.Genislik := Izgara^.FAtananAlan.Genislik - 16;
    Izgara^.FYatayKCubugu^.FAtananAlan.Yukseklik := 16;

    Izgara^.FYatayKCubugu^.FCizimAlani.Sol := 0;
    Izgara^.FYatayKCubugu^.FCizimAlani.Ust := 0;
    Izgara^.FYatayKCubugu^.FCizimAlani.Sag := Izgara^.FYatayKCubugu^.FAtananAlan.Genislik - 1;
    Izgara^.FYatayKCubugu^.FCizimAlani.Alt := Izgara^.FYatayKCubugu^.FAtananAlan.Yukseklik - 1;

    Izgara^.FYatayKCubugu^.FCizimBaslangic.Sol := Izgara^.FCizimBaslangic.Sol + Izgara^.FYatayKCubugu^.FAtananAlan.Sol;
    Izgara^.FYatayKCubugu^.FCizimBaslangic.Ust := Izgara^.FCizimBaslangic.Ust + Izgara^.FYatayKCubugu^.FAtananAlan.Ust;
    Izgara^.FYatayKCubugu^.Hizala;
  end;

  if(Izgara^.FDikeyKCGoster) then
  begin

    // dikey kaydýrma çubuðunu elle yeniden konumlandýr
    Izgara^.FDikeyKCubugu^.FAtananAlan.Sol := Izgara^.FAtananAlan.Genislik - 16;
    Izgara^.FDikeyKCubugu^.FAtananAlan.Ust := 0;
    Izgara^.FDikeyKCubugu^.FAtananAlan.Genislik := 16;
    Izgara^.FDikeyKCubugu^.FAtananAlan.Yukseklik := Izgara^.FAtananAlan.Yukseklik - 16;

    Izgara^.FDikeyKCubugu^.FCizimAlani.Sol := 0;
    Izgara^.FDikeyKCubugu^.FCizimAlani.Ust := 0;
    Izgara^.FDikeyKCubugu^.FCizimAlani.Sag := Izgara^.FDikeyKCubugu^.FAtananAlan.Genislik - 1;
    Izgara^.FDikeyKCubugu^.FCizimAlani.Alt := Izgara^.FDikeyKCubugu^.FAtananAlan.Yukseklik - 1;

    Izgara^.FDikeyKCubugu^.FCizimBaslangic.Sol := Izgara^.FCizimBaslangic.Sol + Izgara^.FDikeyKCubugu^.FAtananAlan.Sol;
    Izgara^.FDikeyKCubugu^.FCizimBaslangic.Ust := Izgara^.FCizimBaslangic.Ust + Izgara^.FDikeyKCubugu^.FAtananAlan.Ust;
    Izgara^.FDikeyKCubugu^.Hizala;
  end;
end;

{==============================================================================
  ýzgara nesnesini çizer
 ==============================================================================}
procedure TIzgara.Ciz;
var
  Pencere: PPencere = nil;
  Izgara: PIzgara = nil;
  CizimAlani: TAlan;
  i, j, SolIlk, UstIlk: TISayi4;
begin

  Izgara := PIzgara(GorselNesneler0.NesneAl(Kimlik));
  if(Izgara = nil) then Exit;

  inherited Ciz;

  // kaydýrma çubuðunun çizim alan koordinatlarýný al
  CizimAlani := Izgara^.FCizimAlani;

  // ata nesne bir pencere mi?
  Pencere := EnUstPencereNesnesiniAl(Izgara);
  if(Pencere = nil) then Exit;

  // tanýmlanmýþ hiçbir kolon yok ise, çýk
  if(FDegerler^.ElemanSayisi = 0) then Exit;

  if(Izgara^.FYatayKCGoster) then
    SolIlk := Izgara^.FYatayKCubugu^.MevcutDeger
  else SolIlk := 0;

  if(Izgara^.FDikeyKCGoster) then
    UstIlk := Izgara^.FDikeyKCubugu^.MevcutDeger
  else UstIlk := 0;

  CizimAlani.Sol := 1;
  CizimAlani.Ust := 1;

  // veriye göre yapýlan döngü
  for i := UstIlk to FSatirSayisi - 1 do
  begin

    for j := SolIlk to FSutunSayisi - 1 do
    begin

      CizimAlani.Sag := CizimAlani.Sol + Izgara^.FSutunGenislik - 1;
      CizimAlani.Alt := CizimAlani.Ust + Izgara^.FSatirYukseklik - 1;

      if(i < Izgara^.FSabitSatirSayisi) then
        Izgara^.EgimliDoldur3(Izgara, CizimAlani, $EAECEE, $ABB2B9)
      else if(j < Izgara^.FSabitSutunSayisi) then
        Izgara^.EgimliDoldur3(Izgara, CizimAlani, $EAECEE, $ABB2B9)

      else if(Izgara^.FSeciliSatir = i) and (Izgara^.FSeciliSutun = j) then
        Izgara^.DikdortgenDoldur(Izgara, CizimAlani, RENK_KIRMIZI, RENK_BEYAZ)
      else Izgara^.DikdortgenDoldur(Izgara, CizimAlani, RENK_BEYAZ, RENK_BEYAZ);

      // baþlýk
      Izgara^.AlanaYaziYaz(Izgara, CizimAlani, 4, 3, FDegerler^.Yazi[(i * (Izgara^.FSutunSayisi)) + j],
        RENK_LACIVERT);

      CizimAlani.Sol += Izgara^.FSutunGenislik + 1;
    end;

    CizimAlani.Sol := 1;
    CizimAlani.Ust += Izgara^.FSatirYukseklik + 1;
  end;

  // kaydýrma çubuklarýný en son çiz
  if(Izgara^.FYatayKCGoster) then Izgara^.FYatayKCubugu^.Ciz;
  if(Izgara^.FDikeyKCGoster) then Izgara^.FDikeyKCubugu^.Ciz;
end;

{==============================================================================
  ýzgara nesnesi olaylarýný iþler
 ==============================================================================}
procedure TIzgara.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere = nil;
  Izgara: PIzgara = nil;
  i, j: TISayi4;
begin

  Izgara := PIzgara(AGonderici);

  // sol fare tuþ basýmý
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // ýzgara nesnesinin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(Izgara);

    // en üstte olmamasý durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak iþaretle
    Pencere^.FAktifNesne := Izgara;
    Izgara^.Odaklanildi := True;

    // sol tuþa basým iþlemi nesnenin olay alanýnda mý gerçekleþti ?
    if(Izgara^.FareNesneOlayAlanindaMi(Izgara)) then
    begin

      // fare olaylarýný yakala
      OlayYakalamayaBasla(Izgara);

      // seçili sütün ve satýr deðerini yeniden belirle
      i := (AOlay.Deger1 + (Izgara^.FYatayKCubugu^.MevcutDeger * Izgara^.FSutunGenislik)) div Izgara^.FSutunGenislik;
      j := (AOlay.Deger2 + (Izgara^.FDikeyKCubugu^.MevcutDeger * Izgara^.FSatirYukseklik)) div Izgara^.FSatirYukseklik;
      if(i >= Izgara^.FSabitSutunSayisi) and (j >= Izgara^.FSabitSatirSayisi) then
      begin

        Izgara^.FSeciliSutun := i;
        Izgara^.FSeciliSatir := j;
      end;

      // ýzgara nesnesini yeniden çiz
      Izgara^.Ciz;

      // uygulamaya veya efendi nesneye mesaj gönder
      if not(Izgara^.OlayYonlendirmeAdresi = nil) then
        Izgara^.OlayYonlendirmeAdresi(Izgara, AOlay)
      else Gorevler0.OlayEkle(Izgara^.GorevKimlik, AOlay);
    end;
  end

  // sol fare tuþ býrakým iþlemi
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarýný almayý býrak
    OlayYakalamayiBirak(Izgara);

    // fare býrakma iþlemi nesnenin olay alanýnda mý gerçekleþti ?
    if(Izgara^.FareNesneOlayAlanindaMi(Izgara)) then
    begin

      // yakalama & býrakma iþlemi bu nesnede olduðu için
      // nesneye FO_TIKLAMA mesajý gönder
      AOlay.Olay := FO_TIKLAMA;
      if not(Izgara^.OlayYonlendirmeAdresi = nil) then
        Izgara^.OlayYonlendirmeAdresi(Izgara, AOlay)
      else Gorevler0.OlayEkle(Izgara^.GorevKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    if not(Izgara^.OlayYonlendirmeAdresi = nil) then
      Izgara^.OlayYonlendirmeAdresi(Izgara, AOlay)
    else Gorevler0.OlayEkle(Izgara^.GorevKimlik, AOlay);
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := Izgara^.FareImlecTipi;
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

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := Izgara^.FareImlecTipi;
end;

procedure TIzgara.HucreSayisiYaz(ASatirSayisi, ASutunSayisi: TSayi4);
var
  Izgara: PIzgara = nil;
begin

  Izgara := PIzgara(GorselNesneler0.NesneAl(Kimlik));
  if(Izgara = nil) then Exit;

  Izgara^.FSatirSayisi := ASatirSayisi;
  Izgara^.FSutunSayisi := ASutunSayisi;
end;

procedure TIzgara.HucreBoyutuYaz(ASatirYukseklik, ASutunGenislik: TSayi4);
var
  Izgara: PIzgara = nil;
begin

  Izgara := PIzgara(GorselNesneler0.NesneAl(Kimlik));
  if(Izgara = nil) then Exit;

  Izgara^.FSatirYukseklik := ASatirYukseklik;
  Izgara^.FSutunGenislik := ASutunGenislik;
end;

procedure TIzgara.SabitHucreSayisiYaz(ASabitSatirSayisi, ASabitSutunSayisi: TSayi4);
var
  Izgara: PIzgara = nil;
begin

  Izgara := PIzgara(GorselNesneler0.NesneAl(Kimlik));
  if(Izgara = nil) then Exit;

  Izgara^.FSabitSatirSayisi := ASabitSatirSayisi;
  Izgara^.FSabitSutunSayisi := ASabitSutunSayisi;
end;

procedure TIzgara.KaydirmaCubuguGorunumYaz(AYatayKCGoster, ADikeyKCGoster: Boolean);
var
  Izgara: PIzgara = nil;
begin

  Izgara := PIzgara(GorselNesneler0.NesneAl(Kimlik));
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

  Izgara := PIzgara(GorselNesneler0.NesneAl(Kimlik));
  if(Izgara = nil) then Exit;

  Izgara^.FSeciliSatir := ASatir;
  Izgara^.FSeciliSutun := ASutun;

  Izgara^.Ciz;
end;

{==============================================================================
  seçili elemanýn yazý (text) deðerini geri döndürür
 ==============================================================================}
function TIzgara.SeciliSatirDegeriniAl: string;
var
  Izgara: PIzgara = nil;
begin

  // nesnenin kimlik, tip deðerlerini denetle.
  Izgara := PIzgara(GorselNesneler0.NesneTipiniKontrolEt(Kimlik, gntIzgara));
  if(Izgara = nil) then Exit;

  if(FSeciliSutun = -1) or (FSeciliSutun > FDegerler^.ElemanSayisi) then Exit('');

  Result := Izgara^.FDegerler^.Yazi[FSeciliSutun];
end;

{==============================================================================
  | ayýracýyla gelen karakter katarýný bölümler
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

  // nesnenin kimlik, tip deðerlerini denetle.
  Izgara := PIzgara(GorselNesneler0.NesneAl(Kimlik));
  if(Izgara = nil) then Exit;

  Izgara^.FDegerler^.Ekle(ADeger);

  Result := True;
end;

procedure TIzgara.DegerIceriginiTemizle;
var
  Izgara: PIzgara = nil;
begin

  // nesnenin kimlik, tip deðerlerini denetle.
  Izgara := PIzgara(GorselNesneler0.NesneAl(Kimlik));
  if(Izgara = nil) then Exit;

  Izgara^.FDegerler^.Temizle;
  Izgara^.FGorunenIlkSiraNo := 0;
  Izgara^.FSeciliSatir := -1;
  Izgara^.FSeciliSutun := -1;

  Izgara^.Ciz;
end;

end.
