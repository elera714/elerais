{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_defter.pas
  Dosya İşlevi: defter nesnesi (TMemo) yönetim işlevlerini içerir

  Güncelleme Tarihi: 17/08/2026

  Bilgi: bu görsel nesne 13.05.2020 tarih itibariyle nesnenin program bölümüne eklenen
    10K ve çekirdek bölümüne eklenen 10K bellek kullanmaktadır.
    bu bellek miktarı şu an için gereklidir. ileride yapısallık bağlamında değiştirilebilir.

 ==============================================================================}
{$mode objfpc}
unit gn_defter;

interface

uses gorselnesne, paylasim, gn_panel, gn_kaydirmacubugu;

type
  PDefter = ^TDefter;
  TDefter = class(TPanel)
  private
    FYatayKCubugu, FDikeyKCubugu: TKaydirmaCubugu;
    FYaziBellekAdresi: Isaretci;
    procedure YatayDikeyKarakterSayisiniAl;
    procedure KaydirmaCubuguOlaylariniIsle(AGonderici: TGorselNesne; AOlay: TOlay);
    procedure KodlamaYaz(AKodlama: TISayi4);
  public
    constructor Create; override;
    destructor Destroy; override;
    function Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4; ADefterRenk, AYaziRenk: TRenk;
      AMetinSarmala: Boolean): TISayi4;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure Temizle;
    procedure YaziEkle(AYaziBellekAdresi: Isaretci);
    procedure YaziEkle(ADeger: string);
    procedure OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
    property YaziUzunlugu: TSayi4 read FDeger1 write FDeger1;
    // yatay & dikey karakter sayısı
    property YatayKarSay: TSayi4 read FDeger2 write FDeger2;
    property DikeyKarSay: TSayi4 read FDeger3 write FDeger3;
    // yazılacak metni görünür ortamda görüntülenecek (sınır içine alacak) şekilde sarmala
    property FMetinSarmala: Boolean read FDurum1 write FDurum1;
    property ImlecX: TISayi4 read FIDeger1 write FIDeger1;
    property ImlecY: TISayi4 read FIDeger2 write FIDeger2;
    // kodlama şu anda: 0 = UTF-8, 1 = CP1254
    property Kodlama: TISayi4 read FIDeger3 write FIDeger3;
  end;

function DefterCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function DefterGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ADefterRenk, AYaziRenk: TRenk; AMetinSarmala: Boolean): TKimlik;

implementation

uses gn_pencere, gn_islevler, islevler, gorev, donusum, src_klavye, src_ps2;

{==============================================================================
  defter kesme çağrılarını yönetir
 ==============================================================================}
function DefterCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  Pencere: TPencere;
  Defter: TDefter;
  Hiza: THiza;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := DefterGNOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^, PRenk(ADegiskenler + 20)^,
        PRenk(ADegiskenler + 24)^, PBoolean(ADegiskenler + 28)^);
    end;

    ISLEV_GOSTER:
    begin

      Defter := TDefter(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Defter.Goster;
    end;

    ISLEV_HIZALA:
    begin

      Defter := TDefter(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      Defter.FHiza := Hiza;

      Pencere := TPencere(Defter.FAtaNesne);
      Pencere.Guncelle;
    end;

    // defter nesnesine veri ekle - pchar
    $010F:
    begin

      // nesnenin handle, tip değerlerini denetle.
      Defter := TDefter(GGNesneler.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntDefter));
      if(Defter <> nil) then
      begin

        Defter.YaziEkle(Isaretci(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr));
        Result := 1;
      end;
    end;

    // defter nesnesine veri ekle - string
    $020F:
    begin

      // nesnenin handle, tip değerlerini denetle.
      Defter := TDefter(GGNesneler.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntDefter));
      if(Defter <> nil) then
      begin

        Defter.YaziEkle(PKarakterKatari(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr)^);
        Result := 1;
      end;
    end;

    // defter nesnesinin içerisindeki verileri temizle
    $030F:
    begin

      // nesnenin kimlik, tip değerlerini denetle.
      Defter := TDefter(GGNesneler.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntDefter));
      if(Defter <> nil) then
      begin

        Defter.Temizle;
      end;
    end;

    // metni sarmalama işlevi
    $040F:
    begin

      // nesnenin handle, tip değerlerini denetle.
      Defter := TDefter(GGNesneler.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntDefter));
      if(Defter <> nil) then
      begin

        Defter.FMetinSarmala := PBoolean(ADegiskenler + 04)^;
        Defter.Ciz;
      end;
    end;

    // metin kodlamasını değiştir
    $050F:
    begin

      // nesnenin handle, tip değerlerini denetle.
      Defter := TDefter(GGNesneler.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntDefter));
      if(Defter <> nil) then Defter.KodlamaYaz(PISayi4(ADegiskenler + 04)^);
    end;
  end;
end;

{==============================================================================
  uygulama için defter nesnesi oluşturur - api
 ==============================================================================}
function DefterGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ADefterRenk, AYaziRenk: TRenk; AMetinSarmala: Boolean): TKimlik;
var
  Defter: TDefter;
begin

  Defter := TDefter.Create;

  if(Defter = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    Defter.Ozellestir(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik,
      ADefterRenk, AYaziRenk, AMetinSarmala);

    Result := Defter.Kimlik;
  end;
end;

{==============================================================================
  defter nesnesi oluşturur
 ==============================================================================}
constructor TDefter.Create;
begin

  inherited Create;

  NesneTipi := gntDefter;

  GGNesneler.GorselNesne[FSiraNo] := Self;
end;

{==============================================================================
  defter nesnesini yok eder
 ==============================================================================}
destructor TDefter.Destroy;
begin

  FYatayKCubugu.Destroy;
  FDikeyKCubugu.Destroy;

  if(FYaziBellekAdresi <> nil) then FreeMem(FYaziBellekAdresi, 10 * 4096);

  GGNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  defter nesnesini özelleştirir
 ==============================================================================}
function TDefter.Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4; ADefterRenk, AYaziRenk: TRenk;
  AMetinSarmala: Boolean): TISayi4;
begin

  Yapilandir2(AKullanimTipi, Self, AAtaNesne, ASol, AUst, AGenislik, AYukseklik,
    2, ADefterRenk, ADefterRenk, 0, '');

  OlayCagriAdr := @OlaylariIsle;

  { TODO - kaydırma çubuklarına sabit değer olarak 50 değeri verilmiştir. Bu değer
    nesne içeriğindeki metine göre dinamik olarak oluşturulacaktır }

  // yatay kaydırma çubuğu
  FYatayKCubugu := TKaydirmaCubugu.Create;
  FYatayKCubugu.Ozellestir(ktBilesen, Self, 0, AYukseklik - 20, AGenislik - 20, 20, yYatay);
  FYatayKCubugu.DegerleriBelirle(0, 50);
  FYatayKCubugu.OlayYonlAdr := @KaydirmaCubuguOlaylariniIsle;

  // dikey kaydırma çubuğu
  FDikeyKCubugu := TKaydirmaCubugu.Create;
  FDikeyKCubugu.Ozellestir(ktBilesen, Self, AGenislik - 20, 0, 20, AYukseklik - 20, yDikey);
  FDikeyKCubugu.DegerleriBelirle(0, 50);
  FDikeyKCubugu.OlayYonlAdr := @KaydirmaCubuguOlaylariniIsle;

  // defter nesnesinin içeriği için bellek ayır
  FYaziBellekAdresi := GetMem(10 * 4096);

  YaziUzunlugu := 0;
  YatayKarSay := 0;
  DikeyKarSay := 0;

  FMetinSarmala := AMetinSarmala;
  FYaziRenk := AYaziRenk;

  ImlecX := 0;
  ImlecY := 0;

  // kodlama = utf-8
  Kodlama := 0;

  FareImlec := fitGiris;

  // kimlik adresini geri döndür
  Result := HATA_YOK;
end;

{==============================================================================
  defter nesnesini görüntüler
 ==============================================================================}
procedure TDefter.Goster;
begin

  FYatayKCubugu.Goster;
  FDikeyKCubugu.Goster;

  inherited Goster;
end;

{==============================================================================
  defter nesnesini gizler
 ==============================================================================}
procedure TDefter.Gizle;
begin

  FYatayKCubugu.Gizle;
  FDikeyKCubugu.Gizle;

  inherited Gizle;
end;

{==============================================================================
  defter nesnesini hizalandırır
 ==============================================================================}
procedure TDefter.Hizala;
begin

  inherited Hizala;

  // yatay kaydırma çubuğunu elle yeniden konumlandır
  FYatayKCubugu.FAtananAlan.Sol := 0;
  FYatayKCubugu.FAtananAlan.Ust := FAtananAlan.Yukseklik - 20;
  FYatayKCubugu.FAtananAlan.Genislik := FAtananAlan.Genislik - 20;
  FYatayKCubugu.FAtananAlan.Yukseklik := 20;

  FYatayKCubugu.FCizimAlani.Sol := 0;
  FYatayKCubugu.FCizimAlani.Ust := 0;
  FYatayKCubugu.FCizimAlani.Sag := FYatayKCubugu.FAtananAlan.Genislik - 1;
  FYatayKCubugu.FCizimAlani.Alt := FYatayKCubugu.FAtananAlan.Yukseklik - 1;

  FYatayKCubugu.FCizimBaslangic.Sol := FCizimBaslangic.Sol + FYatayKCubugu.FAtananAlan.Sol;
  FYatayKCubugu.FCizimBaslangic.Ust := FCizimBaslangic.Ust + FYatayKCubugu.FAtananAlan.Ust;
  FYatayKCubugu.Hizala;

  // dikey kaydırma çubuğunu elle yeniden konumlandır
  FDikeyKCubugu.FAtananAlan.Sol := FAtananAlan.Genislik - 20;
  FDikeyKCubugu.FAtananAlan.Ust := 0;
  FDikeyKCubugu.FAtananAlan.Genislik := 20;
  FDikeyKCubugu.FAtananAlan.Yukseklik := FAtananAlan.Yukseklik - 20;

  FDikeyKCubugu.FCizimAlani.Sol := 0;
  FDikeyKCubugu.FCizimAlani.Ust := 0;
  FDikeyKCubugu.FCizimAlani.Sag := FDikeyKCubugu.FAtananAlan.Genislik - 1;
  FDikeyKCubugu.FCizimAlani.Alt := FDikeyKCubugu.FAtananAlan.Yukseklik - 1;

  FDikeyKCubugu.FCizimBaslangic.Sol := FCizimBaslangic.Sol + FDikeyKCubugu.FAtananAlan.Sol;
  FDikeyKCubugu.FCizimBaslangic.Ust := FCizimBaslangic.Ust + FDikeyKCubugu.FAtananAlan.Ust;
  FDikeyKCubugu.Hizala;
end;

{==============================================================================
  defter nesnesini çizer
 ==============================================================================}
procedure TDefter.Ciz;
var
  CizimAlani: TAlan;
  // defter nesnesine yazılacak karakterin pixel olarak sol / üst değerleri
  pxSol, pxUst: TISayi4;
  YaziBellekAdresi: PChar;
  SinirSutunIlk, SinirSutunSon,
  SinirSatirIlk, SinirSatirSon,
  AktifSutunNo, AktifSatirNo: TISayi4;
  Deger: TSayi4;
begin

  inherited Ciz;

  // defter nesnesinin çizim alan koordinatlarını al
  CizimAlani := FCizimAlani;

  // eğer defter nesnesi için bellek ayrıldıysa defter içeriğini nesne içeriğine
  // eklenen bilgilerle doldur
  if(FYaziBellekAdresi <> nil) and (YaziUzunlugu > 0) then
  begin

    // sütun / satır ilk değerler
    AktifSutunNo := -FYatayKCubugu.MevcutDeger;
    AktifSatirNo := -FDikeyKCubugu.MevcutDeger;

    // sınır değerleri
    SinirSutunIlk := CizimAlani.Sol;
    SinirSutunSon := (CizimAlani.Sag div 8) - 3;      // 2 boşluk yatay kaydırma çubuğu + 1 boşluk = 3 boşluk karakteri
    SinirSatirIlk := CizimAlani.Ust;
    SinirSatirSon := (CizimAlani.Alt div 20) - 2;     // 1 boşluk dikey kaydırma çubuğu + 1 boşluk = 2 boşluk karakteri

    // defter içerik bellek bölgesine konumlan
    YaziBellekAdresi := PChar(FYaziBellekAdresi);

    // imleç konumlandırma
    if(ImlecX >= SinirSutunIlk) and (ImlecX <= SinirSutunSon) and
      (ImlecY >= SinirSatirIlk) and (ImlecY <= SinirSatirSon) then
    begin

      HarfYaz(Self, 3 + (ImlecX * 8), 3 + (ImlecY * 16), #255,
        RENK_ACIKYESIL, RENK_ACIKYESIL);
    end;

    // bellek içeriği sıfır oluncaya kadar devam et
    while (YaziBellekAdresi^ <> #0) do
    begin

      Deger := 0;
      case Kodlama of
        0: Deger := UTF8Byte(YaziBellekAdresi);
        1: begin Deger := PByte(YaziBellekAdresi)^; Inc(YaziBellekAdresi); end;
      end;

      // giriş (enter) karakteri olması durumunda herhangi birşey yapma
      if(Deger = 13) then begin end

      // satır başı + bir alt satıra geç
      else if(Deger = 10) then
      begin

        AktifSutunNo := -FYatayKCubugu.MevcutDeger;
        Inc(AktifSatirNo);
      end
      else
      begin

        { TODO - metin sarmalandığında SADECE dikey kaydırma gerçekleştirilecek,
          yatay kaydırma çubuğu pasifleştirilecek }
        if(AktifSutunNo >= SinirSutunIlk) and (AktifSutunNo <= SinirSutunSon) and
          (AktifSatirNo >= SinirSatirIlk) and (AktifSatirNo <= SinirSatirSon) then
        begin

          pxSol := AktifSutunNo * 8;
          pxSol := pxSol + CizimAlani.Sol + 4;

          pxUst := AktifSatirNo * 20;
          pxUst := pxUst + CizimAlani.Ust + 4;

          HarfYaz(Self, pxSol, pxUst, Char(Deger), RENK_YOK, FYaziRenk);
        end;

        Inc(AktifSutunNo);
        if(AktifSutunNo > SinirSutunSon) and (FMetinSarmala) then
        begin

          AktifSutunNo := -FYatayKCubugu.MevcutDeger;
          Inc(AktifSatirNo);

          // yazma işlemi alt sınırı aşması durumunda zaten yazım yapılamayacağından
          // gereksiz işlem yapılmaması için işlevden çık
          if(AktifSatirNo > SinirSatirSon) then Exit;
        end;
      end;
    end;
  end;

  // kaydırma çubuklarını en son çiz
  FYatayKCubugu.Ciz;
  FDikeyKCubugu.Ciz;
end;

{==============================================================================
  defter nesne olaylarını işler
 ==============================================================================}
procedure TDefter.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Pencere: TPencere;
  Defter: TDefter;
  i: TISayi4;
begin

  Defter := TDefter(AGonderici);
  if(Defter = nil) then Exit;

  // farenin sol tuşuna basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // defter'in sahibi olan pencere en üstte mi ? kontrol et
    Pencere := GGNesneler.EnUstPencereNesnesiniAl(Defter);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GGNesneler.AktifPencere) then
      Pencere.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere.FAktifNesne := Defter;
    Defter.Odaklanildi := True;

    Defter.ImlecX := (AOlay.Deger1 div 8) + Defter.FYatayKCubugu.MevcutDeger;
    Defter.ImlecY := (AOlay.Deger2 div 16) + Defter.FDikeyKCubugu.MevcutDeger;

    Defter.Ciz;
    //SISTEM_MESAJ(mtBilgi, RENK_YESIL, 'X: %d', [Defter^.ImlecX]);
    //SISTEM_MESAJ(mtBilgi, RENK_YESIL, 'Y: %d', [Defter^.ImlecY]);
  end
  else if(AOlay.Olay = FO_KAYDIRMA) then
  begin

    i := Defter.FDikeyKCubugu.MevcutDeger;
    Inc(i, AOlay.Deger1);

    // metni yukarı kaydırma işlevi
    if(AOlay.Deger1 < 0) then
    begin

      if(i < 0) then i := 0;
      Defter.FDikeyKCubugu.MevcutDeger := i;
    end

    // metni aşağıya kaydırma işlevi
    else if(AOlay.Deger1 > 0) then
    begin

      if(i < Defter.FDikeyKCubugu.UstDeger) then
        Defter.FDikeyKCubugu.MevcutDeger := i;
    end;

    Defter.Ciz;
  end
  // klavye tuş basımı
  else if(AOlay.Olay = CO_TUSBASILDI) then
  begin

    //SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'AOlay.Deger1: %d', [AOlay.Deger1]);
    //Tus := (AOlay.Deger1 and $FF);

    { TODO - test edilecek }
    if(AOlay.Deger1 = TUS_SAG) then
    begin

      i := Defter.ImlecX;
      Inc(i);
      Defter.ImlecX := i;
    end
    else if(AOlay.Deger1 = TUS_SOL) then
    begin

      i := Defter.ImlecX;
      Dec(i);
      if(i < 0) then i := 0;
      Defter.ImlecX := i;
    end
    else if(AOlay.Deger1 = TUS_ASAGI) then
    begin

      i := Defter.ImlecY;
      Inc(i);
      Defter.ImlecY := i;
    end
    else if(AOlay.Deger1 = TUS_YUKARI) then
    begin

      i := Defter.ImlecY;
      Dec(i);
      if(i < 0) then i := 0;
      Defter.ImlecY := i;
    end
    else if(AOlay.Deger1 = TUS_GIT_BASA) then
    begin

      Defter.ImlecX := 0;
    end
    else if(AOlay.Deger1 = TUS_GIT_SONA) then
    begin

      Defter.ImlecX := FCizimAlani.Sag div 8;
    end;
  end;

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := Defter.FareImlec;
end;

{==============================================================================
  defter nesnesine bağlı kaydırma çubuğu olaylarını işler
 ==============================================================================}
procedure TDefter.KaydirmaCubuguOlaylariniIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Defter: TDefter;
  KaydirmaCubugu: TKaydirmaCubugu;
begin

  KaydirmaCubugu := TKaydirmaCubugu(AGonderici);
  if(KaydirmaCubugu = nil) then Exit;

  Defter := TDefter(KaydirmaCubugu.AtaNesne);

  if(AOlay.Olay = FO_TIKLAMA) then Defter.Ciz;

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := Defter.FareImlec;
end;

{==============================================================================
  defter nesnesinin içeriğindeki verileri siler
 ==============================================================================}
procedure TDefter.Temizle;
begin

  YaziUzunlugu := 0;

  FDikeyKCubugu.MevcutDeger := 0;
  FYatayKCubugu.MevcutDeger := 0;

  BellekDoldur(FYaziBellekAdresi, 10 * 4096, 0);

  YatayDikeyKarakterSayisiniAl;

  Ciz;
end;

{==============================================================================
  defter nesnesine karakter katarı ekler - pchar
 ==============================================================================}
procedure TDefter.YaziEkle(AYaziBellekAdresi: Isaretci);
var
  p: PSayi1;
  i, j: TSayi4;
  function StrLen2: TSayi4;
  var
    p: PChar;
  begin

    Result := 0;

    p := AYaziBellekAdresi;

    while (p^ <> #0) do begin Inc(p); Inc(Result); end;
  end;
begin

  // karakter katarı için bellek ayrılmış mı ?
  if(FYaziBellekAdresi = nil) then Exit;

  // verinin uzunluğunu al
  i := StrLen2; //(AYaziBellekAdresi);
  if(i = 0) or (i > (10 * 4096)) then Exit;

  // karakter katarını hedef bölgeye kopyala
  p := PByte(FYaziBellekAdresi + YaziUzunlugu);
  Tasi2(AYaziBellekAdresi, p, i);

  // sıfır sonlandırma işaretini ekle
  j := YaziUzunlugu;
  j := j + i;
  YaziUzunlugu := j;
  p := PByte(FYaziBellekAdresi + YaziUzunlugu);
  p^ := 0;

  YatayDikeyKarakterSayisiniAl;

  Ciz;
end;

{==============================================================================
  defter nesnesine karakter katarı ekler - string
 ==============================================================================}
procedure TDefter.YaziEkle(ADeger: string);
var
  p: PSayi1;
  i, j: TSayi4;
begin

  // karakter katarı için bellek ayrılmış mı ?
  if(FYaziBellekAdresi = nil) then Exit;

  // verinin uzunluğunu al
  i := Length(ADeger);
  if(i = 0) or (i > (10 * 4096)) then Exit;

  // karakter katarını hedef bölgeye kopyala
  p := PByte(TSayi4(FYaziBellekAdresi) + YaziUzunlugu);
  Tasi2(@ADeger[1], p, i);

  // sıfır sonlandırma işaretini ekle
  j := YaziUzunlugu;
  j := j + i;
  YaziUzunlugu := j;
  p := PByte(TSayi4(FYaziBellekAdresi) + YaziUzunlugu);
  p^ := 0;

  YatayDikeyKarakterSayisiniAl;

  Ciz;
end;

procedure TDefter.YatayDikeyKarakterSayisiniAl;
var
  p: PChar;
  i, j: TSayi4;
begin

  YatayKarSay := 0;
  DikeyKarSay := 0;

  if(YaziUzunlugu = 0) then Exit;

  p := PChar(FYaziBellekAdresi);
  i := 0;
  while p^ <> #0 do
  begin

    if(p^ = #10) then
    begin

      if(i > YatayKarSay) then YatayKarSay := i;
      i := 0;
      j := DikeyKarSay;
      Inc(j);
      DikeyKarSay := j;
    end
    else
    begin

      Inc(i);
      if(i > YatayKarSay) then YatayKarSay := i;
    end;

    Inc(p);
  end;

  // en düşük değer 1 olmalı - en azından şu anda
  if(YatayKarSay = 0) then YatayKarSay := 1;
  if(DikeyKarSay = 0) then DikeyKarSay := 1;

  FYatayKCubugu.UstDeger := YatayKarSay;
  FDikeyKCubugu.UstDeger := DikeyKarSay;
end;

procedure TDefter.KodlamaYaz(AKodlama: TISayi4);
begin

  Kodlama := AKodlama;
  Ciz;
end;

end.
