{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_defter.pas
  Dosya İşlevi: defter nesnesi (TMemo) yönetim işlevlerini içerir

  Güncelleme Tarihi: 16/07/2026

  Bilgi: bu görsel nesne 13.05.2020 tarih itibariyle nesnenin program bölümüne eklenen
    40K ve çekirdek bölümüne eklenen 40K bellek kullanmaktadır.
    bu bellek miktarı şu an için gereklidir. ileride yapısallık bağlamında değiştirilebilir.

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
    // yatay & dikey karakter sayısı
    property YatayKarSay: TSayi4 read FDeger2 write FDeger2;
    property DikeyKarSay: TSayi4 read FDeger3 write FDeger3;
    // yazılacak metni görünür ortamda görüntülenecek (sınır içine alacak) şekilde sarmala
    property FMetinSarmala: Boolean read FDurum1 write FDurum1;
  end;

function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ADefterRenk, AYaziRenk: TRenk; AMetinSarmala: Boolean): TKimlik;
function DefterCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses gn_pencere, gn_islevler, genel, temelgorselnesne, islevler, sistemmesaj,
  gorev, donusum;

{==============================================================================
  defter kesme çağrılarını yönetir
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

      // nesnenin handle, tip değerlerini denetle.
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

      // nesnenin handle, tip değerlerini denetle.
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

      // nesnenin kimlik, tip değerlerini denetle.
      Defter := PDefter(GorselNesneler0.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntDefter));
      if(Defter <> nil) then
      begin

        Defter^.Temizle;
      end;
    end;

    // metni sarmalama işlevi
    $040F:
    begin

      // nesnenin handle, tip değerlerini denetle.
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
  defter nesnesini oluşturur
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
  defter nesnesini oluşturur
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

  { TODO - kaydırma çubuklarına sabit değer olarak 50 değeri verilmiştir. Bu değer
    nesne içeriğindeki metine göre dinamik olarak oluşturulacaktır }

  // yatay kaydırma çubuğu
  Defter^.FYatayKCubugu := Defter^.FYatayKCubugu^.Olustur(ktBilesen, Defter,
    0, AYukseklik - 20, AGenislik - 20, 20, yYatay);
  Defter^.FYatayKCubugu^.DegerleriBelirle(0, 50);
  Defter^.FYatayKCubugu^.OlayYonlendirmeAdresi := @KaydirmaCubuguOlaylariniIsle;

  // dikey kaydırma çubuğu
  Defter^.FDikeyKCubugu := Defter^.FDikeyKCubugu^.Olustur(ktBilesen, Defter,
    AGenislik - 20, 0, 20, AYukseklik - 20, yDikey);
  Defter^.FDikeyKCubugu^.DegerleriBelirle(0, 50);
  Defter^.FDikeyKCubugu^.OlayYonlendirmeAdresi := @KaydirmaCubuguOlaylariniIsle;

  // defter nesnesinin içeriği için bellek ayır
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

  // AtaNesne nesnesinin doğruluğunu kontrol et
  Defter := PDefter(GorselNesneler0.NesneAl(AKimlik));
  if(Defter = nil) then Exit;

  Defter^.FYatayKCubugu^.YokEt(Defter^.FYatayKCubugu^.Kimlik);
  Defter^.FDikeyKCubugu^.YokEt(Defter^.FDikeyKCubugu^.Kimlik);

  if(Defter^.FYaziBellekAdresi <> nil) then FreeMem(Defter^.FYaziBellekAdresi, 4096 * 10);

  inherited YokEt(AKimlik);
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
  defter nesnesini hizalandırır
 ==============================================================================}
procedure TDefter.Hizala;
var
  Defter: PDefter;
begin

  Defter := PDefter(GorselNesneler0.NesneAl(Kimlik));
  if(Defter = nil) then Exit;

  inherited Hizala;

  // yatay kaydırma çubuğunu elle yeniden konumlandır
  Defter^.FYatayKCubugu^.FAtananAlan.Sol := 0;
  Defter^.FYatayKCubugu^.FAtananAlan.Ust := Defter^.FAtananAlan.Yukseklik - 20;
  Defter^.FYatayKCubugu^.FAtananAlan.Genislik := Defter^.FAtananAlan.Genislik - 20;
  Defter^.FYatayKCubugu^.FAtananAlan.Yukseklik := 20;

  Defter^.FYatayKCubugu^.FCizimAlani.Sol := 0;
  Defter^.FYatayKCubugu^.FCizimAlani.Ust := 0;
  Defter^.FYatayKCubugu^.FCizimAlani.Sag := Defter^.FYatayKCubugu^.FAtananAlan.Genislik - 1;
  Defter^.FYatayKCubugu^.FCizimAlani.Alt := Defter^.FYatayKCubugu^.FAtananAlan.Yukseklik - 1;

  Defter^.FYatayKCubugu^.FCizimBaslangic.Sol := Defter^.FCizimBaslangic.Sol + Defter^.FYatayKCubugu^.FAtananAlan.Sol;
  Defter^.FYatayKCubugu^.FCizimBaslangic.Ust := Defter^.FCizimBaslangic.Ust + Defter^.FYatayKCubugu^.FAtananAlan.Ust;
  Defter^.FYatayKCubugu^.Hizala;

  // dikey kaydırma çubuğunu elle yeniden konumlandır
  Defter^.FDikeyKCubugu^.FAtananAlan.Sol := Defter^.FAtananAlan.Genislik - 20;
  Defter^.FDikeyKCubugu^.FAtananAlan.Ust := 0;
  Defter^.FDikeyKCubugu^.FAtananAlan.Genislik := 20;
  Defter^.FDikeyKCubugu^.FAtananAlan.Yukseklik := Defter^.FAtananAlan.Yukseklik - 20;

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
  pxSol, pxUst: TISayi4;      // defter nesnesine yazılacak karakterin pixel olarak sol / üst değerleri
  YaziBellekAdresi: PChar;
  SinirSutunIlk, SinirSutunSon,
  SinirSatirIlk, SinirSatirSon,
  AktifSutunNo, AktifSatirNo: TISayi4;
  Deger: TSayi4;
begin

  Defter := PDefter(GorselNesneler0.NesneAl(Kimlik));
  if(Defter = nil) then Exit;

  inherited Ciz;

  // defter nesnesinin çizim alan koordinatlarını al
  CizimAlani := Defter^.FCizimAlani;

  // eğer defter nesnesi için bellek ayrıldıysa defter içeriğini nesne içeriğine
  // eklenen bilgilerle doldur
  if(Defter^.FYaziBellekAdresi <> nil) and (Defter^.YaziUzunlugu > 0) then
  begin

    // sütun / satır ilk değerler
    AktifSutunNo := -Defter^.FYatayKCubugu^.MevcutDeger;
    AktifSatirNo := -Defter^.FDikeyKCubugu^.MevcutDeger;

    // sınır değerleri
    SinirSutunIlk := CizimAlani.Sol;
    SinirSutunSon := (CizimAlani.Sag div 8) - 3;      // 2 boşluk yatay kaydırma çubuğu + 1 boşluk = 3 boşluk karakteri
    SinirSatirIlk := CizimAlani.Ust;
    SinirSatirSon := (CizimAlani.Alt div 20) - 2;     // 1 boşluk dikey kaydırma çubuğu + 1 boşluk = 2 boşluk karakteri

    // defter içerik bellek bölgesine konumlan
    YaziBellekAdresi := PChar(Defter^.FYaziBellekAdresi);

    // bellek içeriği sıfır oluncaya kadar devam et
    while (YaziBellekAdresi^ <> #0) do
    begin

      Deger := UTF8Byte(YaziBellekAdresi);

      // giriş (enter) karakteri olması durumunda herhangi birşey yapma
      if(Deger = 13) then begin end

      // satır başı + bir alt satıra geç
      else if(Deger = 10) then
      begin

        AktifSutunNo := -Defter^.FYatayKCubugu^.MevcutDeger;
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

          HarfYaz(Defter, pxSol, pxUst, Char(Deger), RENK_ACIKYESIL, Defter^.FYaziRenk);
        end;

        Inc(AktifSutunNo);
        if(AktifSutunNo > SinirSutunSon) and (Defter^.FMetinSarmala) then
        begin

          AktifSutunNo := -Defter^.FYatayKCubugu^.MevcutDeger;
          Inc(AktifSatirNo);

          // yazma işlemi alt sınırı aşması durumunda zaten yazım yapılamayacağından
          // gereksiz işlem yapılmaması için işlevden çık
          if(AktifSatirNo > SinirSatirSon) then Exit;
        end;
      end;
    end;
  end;

  // kaydırma çubuklarını en son çiz
  //Defter^.FYatayKCubugu^.Ciz;
  //Defter^.FDikeyKCubugu^.Ciz;
end;

{==============================================================================
  defter nesnesinin içeriğindeki verileri siler
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
  if(Self.FYaziBellekAdresi = nil) then Exit;

  // verinin uzunluğunu al
  i := StrLen2; //(AYaziBellekAdresi);
  if(i = 0) or (i > (4096 * 10)) then Exit;

  // karakter katarını hedef bölgeye kopyala
  p := PByte(Self.FYaziBellekAdresi + Self.YaziUzunlugu);
  Tasi2(AYaziBellekAdresi, p, i);

  // sıfır sonlandırma işaretini ekle
  j := Self.YaziUzunlugu;
  j := j + i;
  Self.YaziUzunlugu := j;
  p := PByte(Self.FYaziBellekAdresi + Self.YaziUzunlugu);
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
  if(Self.FYaziBellekAdresi = nil) then Exit;

  // verinin uzunluğunu al
  i := Length(ADeger);
  if(i = 0) or (i > (4096 * 10)) then Exit;

  // karakter katarını hedef bölgeye kopyala
  p := PByte(TSayi4(Self.FYaziBellekAdresi) + Self.YaziUzunlugu);
  Tasi2(@ADeger[1], p, i);

  // sıfır sonlandırma işaretini ekle
  j := Self.YaziUzunlugu;
  j := j + i;
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

  // en düşük değer 1 olmalı - en azından şu anda
  if(Self.YatayKarSay = 0) then Self.YatayKarSay := 1;
  if(Self.DikeyKarSay = 0) then Self.DikeyKarSay := 1;

  Self.FYatayKCubugu^.UstDeger := Self.YatayKarSay;
  Self.FDikeyKCubugu^.UstDeger := Self.DikeyKarSay;
end;

{==============================================================================
  defter nesne olaylarını işler
 ==============================================================================}
procedure TDefter.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere;
  Defter: PDefter;
  i: TISayi4;
begin

  Defter := PDefter(AGonderici);
  if(Defter = nil) then Exit;

  // farenin sol tuşuna basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // defter'in sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(Defter);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere^.FAktifNesne := Defter;
    Defter^.Odaklanildi := True;
  end
  else if(AOlay.Olay = FO_KAYDIRMA) then
  begin

    i := Defter^.FDikeyKCubugu^.MevcutDeger;
    Inc(i, AOlay.Deger1);

    // metni yukarı kaydırma işlevi
    if(AOlay.Deger1 < 0) then
    begin

      if(i < 0) then i := 0;
      Defter^.FDikeyKCubugu^.MevcutDeger := i;
    end

    // metni aşağıya kaydırma işlevi
    else if(AOlay.Deger1 > 0) then
    begin

      if(i < Defter^.FDikeyKCubugu^.UstDeger) then
        Defter^.FDikeyKCubugu^.MevcutDeger := i;
    end;

    Defter^.Ciz;
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := Defter^.FareImlecTipi;
end;

{==============================================================================
  defter nesnesine bağlı kaydırma çubuğu olaylarını işler
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
