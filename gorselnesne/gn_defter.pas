{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: gn_defter.pas
  Dosya Ýþlevi: defter nesnesi (TMemo) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 27/04/2025

  Bilgi: bu görsel nesne 13.05.2020 tarih itibariyle nesnenin program bölümüne eklenen
    40K ve çekirdek bölümüne eklenen 40K bellek kullanmaktadýr.
    bu bellek miktarý þu an için gereklidir. ileride yapýsallýk baðlamýnda deðiþtirilebilir.

 ==============================================================================}
{$mode objfpc}
unit gn_defter;

interface

uses gorselnesne, paylasim, gn_panel, gn_kaydirmacubugu;

type
  PDefter = ^TDefter;
  TDefter = object(TPanel)
  private
    FYatayKCubugu, FDikeyKCubugu: PKaydirmaCubugu;
    // yazýlacak metni görünür ortamda görüntülenecek þekilde sarmala
    FMetinSarmala: Boolean;
    FYaziBellekAdresi: Isaretci;
    procedure YatayDikeyKarakterSayisiniAl;
    procedure KaydirmaCubuguOlaylariniIsle(AGonderici: PGorselNesne; AOlay: TOlay);
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4; ADefterRenk, AYaziRenk: TRenk;
      AMetinSarmala: Boolean): PDefter;
    procedure YokEt(AKimlik: TKimlik);
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure Temizle;
    procedure YaziEkle(AYaziBellekAdresi: Isaretci);
    procedure YaziEkle(ADeger: string);
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    property YaziUzunlugu: TSayi4 read FDeger1 write FDeger1;
    // yatay & dikey karakter sayýsý
    property YatayKarSay: TSayi4 read FDeger2 write FDeger2;
    property DikeyKarSay: TSayi4 read FDeger3 write FDeger3;
  end;

function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ADefterRenk, AYaziRenk: TRenk; AMetinSarmala: Boolean): TKimlik;
function DefterCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses gn_pencere, gn_islevler, genel, temelgorselnesne, islevler, sistemmesaj, gorev;

{==============================================================================
  defter kesme çaðrýlarýný yönetir
 ==============================================================================}
function DefterCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne;
  Pencere: PPencere;
  Defter: PDefter;
  Hiza: THiza;
begin

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^, PRenk(ADegiskenler + 20)^,
        PRenk(ADegiskenler + 24)^, PBoolean(ADegiskenler + 28)^);
    end;

    ISLEV_GOSTER:
    begin

      Defter := PDefter(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      Defter^.Goster;
    end;

    ISLEV_HIZALA:
    begin

      Defter := PDefter(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      Defter^.FHiza := Hiza;

      Pencere := PPencere(Defter^.FAtaNesne);
      Pencere^.Guncelle;
    end;

    // defter nesnesine veri ekle - pchar
    $010F:
    begin

      // nesnenin handle, tip deðerlerini denetle.
      Defter := PDefter(GorselNesneler0.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntDefter));
      if(Defter <> nil) then
      begin

        Defter^.YaziEkle(Isaretci(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi));
        Result := 1;
      end;
    end;

    // defter nesnesine veri ekle - string
    $020F:
    begin

      // nesnenin handle, tip deðerlerini denetle.
      Defter := PDefter(GorselNesneler0.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntDefter));
      if(Defter <> nil) then
      begin

        Defter^.YaziEkle(PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi)^);
        Result := 1;
      end;
    end;

    // defter nesnesinin içerisindeki verileri temizle
    $030F:
    begin

      // nesnenin kimlik, tip deðerlerini denetle.
      Defter := PDefter(GorselNesneler0.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntDefter));
      if(Defter <> nil) then
      begin

        Defter^.Temizle;
      end;
    end;

    // metni sarmalama iþlevi
    $040F:
    begin

      // nesnenin handle, tip deðerlerini denetle.
      Defter := PDefter(GorselNesneler0.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntDefter));
      if(Defter <> nil) then
      begin

        Defter^.FMetinSarmala := PBoolean(ADegiskenler + 04)^;
        Defter^.Ciz;
      end;
    end;

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  defter nesnesini oluþturur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ADefterRenk, AYaziRenk: TRenk; AMetinSarmala: Boolean): TKimlik;
var
  Defter: PDefter;
begin

  Defter := Defter^.Olustur(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik,
    ADefterRenk, AYaziRenk, AMetinSarmala);

  if(Defter = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := Defter^.Kimlik;
end;

{==============================================================================
  defter nesnesini oluþturur
 ==============================================================================}
function TDefter.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4; ADefterRenk, AYaziRenk: TRenk;
  AMetinSarmala: Boolean): PDefter;
var
  Defter: PDefter;
begin

  Defter := PDefter(inherited Olustur(AKullanimTipi, AAtaNesne, ASol, AUst,
    AGenislik, AYukseklik, 2, ADefterRenk, ADefterRenk, 0, ''));

  Defter^.NesneTipi := gntDefter;

  Defter^.Baslik := '';

  Defter^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  Defter^.OlayCagriAdresi := @OlaylariIsle;

  Defter^.FareImlecTipi := fitGiris;

  { TODO - kaydýrma çubuklarýna sabit deðer olarak 50 deðeri verilmiþtir. Bu deðer
    nesne içeriðindeki metine göre dinamik olarak oluþturulacaktýr }

  // yatay kaydýrma çubuðu
  Defter^.FYatayKCubugu := Defter^.FYatayKCubugu^.Olustur(ktBilesen, Defter,
    0, AYukseklik - 16, AGenislik - 16, 16, yYatay);
  Defter^.FYatayKCubugu^.DegerleriBelirle(0, 50);
  Defter^.FYatayKCubugu^.OlayYonlendirmeAdresi := @KaydirmaCubuguOlaylariniIsle;

  // dikey kaydýrma çubuðu
  Defter^.FDikeyKCubugu := Defter^.FDikeyKCubugu^.Olustur(ktBilesen, Defter,
    AGenislik - 16, 0, 16, AYukseklik - 16, yDikey);
  Defter^.FDikeyKCubugu^.DegerleriBelirle(0, 50);
  Defter^.FDikeyKCubugu^.OlayYonlendirmeAdresi := @KaydirmaCubuguOlaylariniIsle;

  // defter nesnesinin içeriði için bellek ayýr
  Defter^.FYaziBellekAdresi := GetMem(4096 * 10);

  Defter^.YaziUzunlugu := 0;
  Defter^.YatayKarSay := 0;
  Defter^.DikeyKarSay := 0;

  Defter^.FMetinSarmala := AMetinSarmala;
  Defter^.FYaziRenk := AYaziRenk;

  // kimlik adresini geri döndür
  Result := Defter;
end;

{==============================================================================
  defter nesnesini yok eder
 ==============================================================================}
procedure TDefter.YokEt(AKimlik: TKimlik);
var
  Defter: PDefter;
begin

  // AtaNesne nesnesinin doðruluðunu kontrol et
  Defter := PDefter(GorselNesneler0.NesneAl(AKimlik));
  if(Defter = nil) then Exit;

  if(Defter^.FYaziBellekAdresi <> nil) then FreeMem(Defter^.FYaziBellekAdresi, 4096 * 10);

  GorselNesneler0.YokEt(AKimlik);
end;

{==============================================================================
  defter nesnesini görüntüler
 ==============================================================================}
procedure TDefter.Goster;
var
  Defter: PDefter;
begin

  Defter := PDefter(GorselNesneler0.NesneAl(Kimlik));
  if(Defter = nil) then Exit;

  Defter^.FYatayKCubugu^.Goster;
  Defter^.FDikeyKCubugu^.Goster;

  inherited Goster;
end;

{==============================================================================
  defter nesnesini gizler
 ==============================================================================}
procedure TDefter.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  defter nesnesini hizalandýrýr
 ==============================================================================}
procedure TDefter.Hizala;
var
  Defter: PDefter;
begin

  Defter := PDefter(GorselNesneler0.NesneAl(Kimlik));
  if(Defter = nil) then Exit;

  inherited Hizala;

  // yatay kaydýrma çubuðunu elle yeniden konumlandýr
  Defter^.FYatayKCubugu^.FAtananAlan.Sol := 0;
  Defter^.FYatayKCubugu^.FAtananAlan.Ust := Defter^.FAtananAlan.Yukseklik - 16;
  Defter^.FYatayKCubugu^.FAtananAlan.Genislik := Defter^.FAtananAlan.Genislik - 16;
  Defter^.FYatayKCubugu^.FAtananAlan.Yukseklik := 16;

  Defter^.FYatayKCubugu^.FCizimAlani.Sol := 0;
  Defter^.FYatayKCubugu^.FCizimAlani.Ust := 0;
  Defter^.FYatayKCubugu^.FCizimAlani.Sag := Defter^.FYatayKCubugu^.FAtananAlan.Genislik - 1;
  Defter^.FYatayKCubugu^.FCizimAlani.Alt := Defter^.FYatayKCubugu^.FAtananAlan.Yukseklik - 1;

  Defter^.FYatayKCubugu^.FCizimBaslangic.Sol := Defter^.FCizimBaslangic.Sol + Defter^.FYatayKCubugu^.FAtananAlan.Sol;
  Defter^.FYatayKCubugu^.FCizimBaslangic.Ust := Defter^.FCizimBaslangic.Ust + Defter^.FYatayKCubugu^.FAtananAlan.Ust;
  Defter^.FYatayKCubugu^.Hizala;

  // dikey kaydýrma çubuðunu elle yeniden konumlandýr
  Defter^.FDikeyKCubugu^.FAtananAlan.Sol := Defter^.FAtananAlan.Genislik - 16;
  Defter^.FDikeyKCubugu^.FAtananAlan.Ust := 0;
  Defter^.FDikeyKCubugu^.FAtananAlan.Genislik := 16;
  Defter^.FDikeyKCubugu^.FAtananAlan.Yukseklik := Defter^.FAtananAlan.Yukseklik - 16;

  Defter^.FDikeyKCubugu^.FCizimAlani.Sol := 0;
  Defter^.FDikeyKCubugu^.FCizimAlani.Ust := 0;
  Defter^.FDikeyKCubugu^.FCizimAlani.Sag := Defter^.FDikeyKCubugu^.FAtananAlan.Genislik - 1;
  Defter^.FDikeyKCubugu^.FCizimAlani.Alt := Defter^.FDikeyKCubugu^.FAtananAlan.Yukseklik - 1;

  Defter^.FDikeyKCubugu^.FCizimBaslangic.Sol := Defter^.FCizimBaslangic.Sol + Defter^.FDikeyKCubugu^.FAtananAlan.Sol;
  Defter^.FDikeyKCubugu^.FCizimBaslangic.Ust := Defter^.FCizimBaslangic.Ust + Defter^.FDikeyKCubugu^.FAtananAlan.Ust;
  Defter^.FDikeyKCubugu^.Hizala;
end;

{==============================================================================
  defter nesnesini çizer
 ==============================================================================}
procedure TDefter.Ciz;
var
  Defter: PDefter = nil;
  CizimAlani: TAlan;
  pxSol, pxUst: TISayi4;      // defter nesnesine yazýlacak karakterin pixel olarak sol / üst deðerleri
  YaziBellekAdresi: PChar;
  SinirSutunIlk, SinirSutunSon,
  SinirSatirIlk, SinirSatirSon,
  AktifSutunNo, AktifSatirNo: TISayi4;
begin

  Defter := PDefter(GorselNesneler0.NesneAl(Kimlik));
  if(Defter = nil) then Exit;

  inherited Ciz;

  // defter nesnesinin çizim alan koordinatlarýný al
  CizimAlani := Defter^.FCizimAlani;

  // eðer defter nesnesi için bellek ayrýldýysa defter içeriðini nesne içeriðine
  // eklenen bilgilerle doldur
  if(Defter^.FYaziBellekAdresi <> nil) and (Defter^.YaziUzunlugu > 0) then
  begin

    // sütun / satýr ilk deðerler
    AktifSutunNo := -Defter^.FYatayKCubugu^.MevcutDeger;
    AktifSatirNo := -Defter^.FDikeyKCubugu^.MevcutDeger;

    // sýnýr deðerleri
    SinirSutunIlk := CizimAlani.Sol;
    SinirSutunSon := (CizimAlani.Sag div 8) - 3;      // 2 boþluk yatay kaydýrma çubuðu + 1 boþluk = 3 boþluk karakteri
    SinirSatirIlk := CizimAlani.Ust;
    SinirSatirSon := (CizimAlani.Alt div 16) - 2;     // 1 boþluk dikey kaydýrma çubuðu + 1 boþluk = 2 boþluk karakteri

    // defter içerik bellek bölgesine konumlan
    YaziBellekAdresi := PChar(Defter^.FYaziBellekAdresi);

    // bellek içeriði sýfýr oluncaya kadar devam et
    while (YaziBellekAdresi^ <> #0) do
    begin

      // giriþ (enter) karakteri olmasý durumunda herhangi birþey yapma
      if(YaziBellekAdresi^ = #13) then begin end

      // satýr baþý + bir alt satýra geç
      else if(YaziBellekAdresi^ = #10) then
      begin

        AktifSutunNo := -Defter^.FYatayKCubugu^.MevcutDeger;
        Inc(AktifSatirNo);
      end
      else
      begin

        { TODO - metin sarmalandýðýnda SADECE dikey kaydýrma gerçekleþtirilecek,
          yatay kaydýrma çubuðu pasifleþtirilecek }
        if(AktifSutunNo >= SinirSutunIlk) and (AktifSutunNo <= SinirSutunSon) and
          (AktifSatirNo >= SinirSatirIlk) and (AktifSatirNo <= SinirSatirSon) then
        begin

          pxSol := AktifSutunNo * 8;
          pxSol += CizimAlani.Sol + 4;

          pxUst := AktifSatirNo * 16;
          pxUst += CizimAlani.Ust + 4;

          HarfYaz(Defter, pxSol, pxUst, YaziBellekAdresi^, Defter^.FYaziRenk);
        end;

        Inc(AktifSutunNo);
        if(AktifSutunNo > SinirSutunSon) and (Defter^.FMetinSarmala) then
        begin

          AktifSutunNo := -Defter^.FYatayKCubugu^.MevcutDeger;
          Inc(AktifSatirNo);

          // yazma iþlemi alt sýnýrý aþmasý durumunda zaten yazým yapýlamayacaðýndan
          // gereksiz iþlem yapýlmamasý için iþlevden çýk
          if(AktifSatirNo > SinirSatirSon) then Exit;
        end;
      end;

      Inc(YaziBellekAdresi);
    end;
  end;

  // kaydýrma çubuklarýný en son çiz
  //Defter^.FYatayKCubugu^.Ciz;
  //Defter^.FDikeyKCubugu^.Ciz;
end;

{==============================================================================
  defter nesnesinin içeriðindeki verileri siler
 ==============================================================================}
procedure TDefter.Temizle;
begin

  Self.YaziUzunlugu := 0;

  Self.FDikeyKCubugu^.MevcutDeger := 0;
  Self.FYatayKCubugu^.MevcutDeger := 0;

  BellekDoldur(Self.FYaziBellekAdresi, 4096 * 10, 0);

  YatayDikeyKarakterSayisiniAl;

  Ciz;
end;

{==============================================================================
  defter nesnesine karakter katarý ekler - pchar
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

  // karakter katarý için bellek ayrýlmýþ mý ?
  if(Self.FYaziBellekAdresi = nil) then Exit;

  // verinin uzunluðunu al
  i := StrLen2; //(AYaziBellekAdresi);
  if(i = 0) or (i > (4096 * 10)) then Exit;

  // karakter katarýný hedef bölgeye kopyala
  p := PByte(Self.FYaziBellekAdresi + Self.YaziUzunlugu);
  Tasi2(AYaziBellekAdresi, p, i);

  // sýfýr sonlandýrma iþaretini ekle
  j := Self.YaziUzunlugu;
  j += i;
  Self.YaziUzunlugu := j;
  p := PByte(Self.FYaziBellekAdresi + Self.YaziUzunlugu);
  p^ := 0;

  YatayDikeyKarakterSayisiniAl;

  Ciz;
end;

{==============================================================================
  defter nesnesine karakter katarý ekler - string
 ==============================================================================}
procedure TDefter.YaziEkle(ADeger: string);
var
  p: PSayi1;
  i, j: TSayi4;
begin

  // karakter katarý için bellek ayrýlmýþ mý ?
  if(Self.FYaziBellekAdresi = nil) then Exit;

  // verinin uzunluðunu al
  i := Length(ADeger);
  if(i = 0) or (i > (4096 * 10)) then Exit;

  // karakter katarýný hedef bölgeye kopyala
  p := PByte(TSayi4(Self.FYaziBellekAdresi) + Self.YaziUzunlugu);
  Tasi2(@ADeger[1], p, i);

  // sýfýr sonlandýrma iþaretini ekle
  j := Self.YaziUzunlugu;
  j += i;
  Self.YaziUzunlugu := j;
  p := PByte(TSayi4(Self.FYaziBellekAdresi) + Self.YaziUzunlugu);
  p^ := 0;

  YatayDikeyKarakterSayisiniAl;

  Ciz;
end;

procedure TDefter.YatayDikeyKarakterSayisiniAl;
var
  p: PChar;
  i, j: TSayi4;
begin

  Self.YatayKarSay := 0;
  Self.DikeyKarSay := 0;

  if(Self.YaziUzunlugu = 0) then Exit;

  p := PChar(Self.FYaziBellekAdresi);
  i := 0;
  while p^ <> #0 do
  begin

    if(p^ = #10) then
    begin

      if(i > Self.YatayKarSay) then Self.YatayKarSay := i;
      i := 0;
      j := Self.DikeyKarSay;
      Inc(j);
      Self.DikeyKarSay := j;
    end
    else
    begin

      Inc(i);
      if(i > Self.YatayKarSay) then Self.YatayKarSay := i;
    end;

    Inc(p);
  end;

  // en düþük deðer 1 olmalý - en azýndan þu anda
  if(Self.YatayKarSay = 0) then Self.YatayKarSay := 1;
  if(Self.DikeyKarSay = 0) then Self.DikeyKarSay := 1;

  Self.FYatayKCubugu^.UstDeger := Self.YatayKarSay;
  Self.FDikeyKCubugu^.UstDeger := Self.DikeyKarSay;
end;

{==============================================================================
  defter nesne olaylarýný iþler
 ==============================================================================}
procedure TDefter.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere;
  Defter: PDefter;
  i: TISayi4;
begin

  Defter := PDefter(AGonderici);
  if(Defter = nil) then Exit;

  // farenin sol tuþuna basým iþlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // defter'in sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(Defter);

    // en üstte olmamasý durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak iþaretle
    Pencere^.FAktifNesne := Defter;
    Defter^.Odaklanildi := True;
  end
  else if(AOlay.Olay = FO_KAYDIRMA) then
  begin

    // metni yukarý kaydýrma iþlevi
    if(AOlay.Deger1 < 0) then
    begin

      i := Defter^.FDikeyKCubugu^.MevcutDeger;
      Dec(i);
      if(i >= 0) then Defter^.FDikeyKCubugu^.MevcutDeger := i;

      Defter^.Ciz;
    end

    // metni aþaðýya kaydýrma iþlevi
    else if(AOlay.Deger1 > 0) then
    begin

      i := Defter^.FDikeyKCubugu^.MevcutDeger;
      Inc(i);
      if(i < Defter^.FDikeyKCubugu^.UstDeger) then
      begin

        Defter^.FDikeyKCubugu^.MevcutDeger := i;
        Defter^.Ciz;
      end;
    end;
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := Defter^.FareImlecTipi;
end;

{==============================================================================
  defter nesnesine baðlý kaydýrma çubuðu olaylarýný iþler
 ==============================================================================}
procedure TDefter.KaydirmaCubuguOlaylariniIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Defter: PDefter;
  KaydirmaCubugu: PKaydirmaCubugu;
begin

  KaydirmaCubugu := PKaydirmaCubugu(AGonderici);
  if(KaydirmaCubugu = nil) then Exit;

  Defter := PDefter(KaydirmaCubugu^.AtaNesne);

  if(AOlay.Olay = FO_TIKLAMA) then Defter^.Ciz;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := Defter^.FareImlecTipi;
end;

end.
