{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: gn_defter.pas
  Dosya ��levi: defter nesnesi (TMemo) y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 16/01/2025

  Bilgi: bu g�rsel nesne 13.05.2020 tarih itibariyle nesnenin program b�l�m�ne eklenen
    40K ve �ekirdek b�l�m�ne eklenen 40K bellek kullanmaktad�r.
    bu bellek miktar� �u an i�in gereklidir. ileride yap�sall�k ba�lam�nda de�i�tirilebilir.

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
    // yatay & dikey karakter say�s�
    FYatayKarSay, FDikeyKarSay: TSayi4;
    // yaz�lacak metni g�r�n�r ortamda g�r�nt�lenecek �ekilde sarmala
    FMetinSarmala: Boolean;
    FYaziBellekAdresi: Isaretci;
    FYaziUzunlugu: TSayi4;
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
  end;

function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ADefterRenk, AYaziRenk: TRenk; AMetinSarmala: Boolean): TKimlik;
function DefterCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses gn_pencere, genel, temelgorselnesne, islevler, sistemmesaj;

{==============================================================================
  defter kesme �a�r�lar�n� y�netir
 ==============================================================================}
function DefterCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GorselNesne: PGorselNesne;
  Pencere: PPencere;
  Defter: PDefter;
  Hiza: THiza;
begin

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GorselNesne := GorselNesne^.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GorselNesne, PISayi4(ADegiskenler + 04)^,
        PISayi4(ADegiskenler + 08)^, PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^,
        PRenk(ADegiskenler + 20)^, PRenk(ADegiskenler + 24)^, PBoolean(ADegiskenler + 28)^);
    end;

    ISLEV_GOSTER:
    begin

      Defter := PDefter(Defter^.NesneAl(PKimlik(ADegiskenler + 00)^));
      Defter^.Goster;
    end;

    ISLEV_HIZALA:
    begin

      Defter := PDefter(Defter^.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      Defter^.FHiza := Hiza;

      Pencere := PPencere(Defter^.FAtaNesne);
      Pencere^.Guncelle;
    end;

    // defter nesnesine veri ekle - pchar
    $010F:
    begin

      // nesnenin handle, tip de�erlerini denetle.
      Defter := PDefter(Defter^.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntDefter));
      if(Defter <> nil) then
      begin

        Defter^.YaziEkle(Isaretci(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi));
        Result := 1;
      end;
    end;

    // defter nesnesine veri ekle - string
    $020F:
    begin

      // nesnenin handle, tip de�erlerini denetle.
      Defter := PDefter(Defter^.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntDefter));
      if(Defter <> nil) then
      begin

        Defter^.YaziEkle(PKarakterKatari(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi)^);
        Result := 1;
      end;
    end;

    // defter nesnesinin i�erisindeki verileri temizle
    $030F:
    begin

      // nesnenin kimlik, tip de�erlerini denetle.
      Defter := PDefter(Defter^.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntDefter));
      if(Defter <> nil) then
      begin

        Defter^.Temizle;
      end;
    end;

    // metni sarmalama i�levi
    $040F:
    begin

      // nesnenin handle, tip de�erlerini denetle.
      Defter := PDefter(Defter^.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntDefter));
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
  defter nesnesini olu�turur
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
  defter nesnesini olu�turur
 ==============================================================================}
function TDefter.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4; ADefterRenk, AYaziRenk: TRenk;
  AMetinSarmala: Boolean): PDefter;
var
  Defter: PDefter;
  YaziBellekAdresi: Isaretci;
begin

  Defter := PDefter(inherited Olustur(AKullanimTipi, AAtaNesne, ASol, AUst,
    AGenislik, AYukseklik, 2, ADefterRenk, ADefterRenk, 0, ''));

  Defter^.NesneTipi := gntDefter;

  Defter^.Baslik := '';

  Defter^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  Defter^.OlayCagriAdresi := @OlaylariIsle;

  Defter^.FFareImlecTipi := fitGiris;

  { TODO - kayd�rma �ubuklar�na sabit de�er olarak 50 de�eri verilmi�tir. Bu de�er
    nesne i�eri�indeki metine g�re dinamik olarak olu�turulacakt�r }

  // yatay kayd�rma �ubu�u
  Defter^.FYatayKCubugu := Defter^.FYatayKCubugu^.Olustur(ktBilesen, Defter,
    0, AYukseklik - 16, AGenislik - 16, 16, yYatay);
  Defter^.FYatayKCubugu^.DegerleriBelirle(0, 50);
  Defter^.FYatayKCubugu^.OlayYonlendirmeAdresi := @KaydirmaCubuguOlaylariniIsle;

  // dikey kayd�rma �ubu�u
  Defter^.FDikeyKCubugu := Defter^.FDikeyKCubugu^.Olustur(ktBilesen, Defter,
    AGenislik - 16, 0, 16, AYukseklik - 16, yDikey);
  Defter^.FDikeyKCubugu^.DegerleriBelirle(0, 50);
  Defter^.FDikeyKCubugu^.OlayYonlendirmeAdresi := @KaydirmaCubuguOlaylariniIsle;

  // defter nesnesinin i�eri�i i�in bellek ay�r
  YaziBellekAdresi := GGercekBellek.Ayir((4096 * 10) - 1);
  Defter^.FYaziBellekAdresi := YaziBellekAdresi;

  Defter^.FYaziUzunlugu := 0;
  Defter^.FYatayKarSay := 0;
  Defter^.FDikeyKarSay := 0;

  Defter^.FMetinSarmala := AMetinSarmala;
  Defter^.FYaziRenk := AYaziRenk;

  // kimlik adresini geri d�nd�r
  Result := Defter;
end;

{==============================================================================
  defter nesnesini yok eder
 ==============================================================================}
procedure TDefter.YokEt(AKimlik: TKimlik);
var
  Defter: PDefter;
begin

  // AtaNesne nesnesinin do�rulu�unu kontrol et
  Defter := PDefter(Defter^.NesneAl(AKimlik));
  if(Defter = nil) then Exit;

  if(Defter^.FYaziBellekAdresi <> nil) then
    GGercekBellek.YokEt(Defter^.FYaziBellekAdresi, (4096 * 10) - 1);

  inherited YokEt;
end;

{==============================================================================
  defter nesnesini g�r�nt�ler
 ==============================================================================}
procedure TDefter.Goster;
var
  Defter: PDefter;
begin

  Defter := PDefter(Defter^.NesneAl(Kimlik));
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
  defter nesnesini hizaland�r�r
 ==============================================================================}
procedure TDefter.Hizala;
var
  Defter: PDefter;
begin

  Defter := PDefter(Defter^.NesneAl(Kimlik));
  if(Defter = nil) then Exit;

  inherited Hizala;

  // yatay kayd�rma �ubu�unu elle yeniden konumland�r
  Defter^.FYatayKCubugu^.FKonum.Sol := 0;
  Defter^.FYatayKCubugu^.FKonum.Ust := Defter^.FBoyut.Yukseklik - 16;
  Defter^.FYatayKCubugu^.FBoyut.Genislik := Defter^.FBoyut.Genislik - 16;
  Defter^.FYatayKCubugu^.FBoyut.Yukseklik := 16;

  Defter^.FYatayKCubugu^.FCizimAlan.Sol := 0;
  Defter^.FYatayKCubugu^.FCizimAlan.Ust := 0;
  Defter^.FYatayKCubugu^.FCizimAlan.Sag := Defter^.FYatayKCubugu^.FBoyut.Genislik - 1;
  Defter^.FYatayKCubugu^.FCizimAlan.Alt := Defter^.FYatayKCubugu^.FBoyut.Yukseklik - 1;

  Defter^.FYatayKCubugu^.FCizimBaslangic.Sol := Defter^.FCizimBaslangic.Sol + Defter^.FYatayKCubugu^.FKonum.Sol;
  Defter^.FYatayKCubugu^.FCizimBaslangic.Ust := Defter^.FCizimBaslangic.Ust + Defter^.FYatayKCubugu^.FKonum.Ust;
  Defter^.FYatayKCubugu^.Hizala;

  // dikey kayd�rma �ubu�unu elle yeniden konumland�r
  Defter^.FDikeyKCubugu^.FKonum.Sol := Defter^.FBoyut.Genislik - 16;
  Defter^.FDikeyKCubugu^.FKonum.Ust := 0;
  Defter^.FDikeyKCubugu^.FBoyut.Genislik := 16;
  Defter^.FDikeyKCubugu^.FBoyut.Yukseklik := Defter^.FBoyut.Yukseklik - 16;

  Defter^.FDikeyKCubugu^.FCizimAlan.Sol := 0;
  Defter^.FDikeyKCubugu^.FCizimAlan.Ust := 0;
  Defter^.FDikeyKCubugu^.FCizimAlan.Sag := Defter^.FDikeyKCubugu^.FBoyut.Genislik - 1;
  Defter^.FDikeyKCubugu^.FCizimAlan.Alt := Defter^.FDikeyKCubugu^.FBoyut.Yukseklik - 1;

  Defter^.FDikeyKCubugu^.FCizimBaslangic.Sol := Defter^.FCizimBaslangic.Sol + Defter^.FDikeyKCubugu^.FKonum.Sol;
  Defter^.FDikeyKCubugu^.FCizimBaslangic.Ust := Defter^.FCizimBaslangic.Ust + Defter^.FDikeyKCubugu^.FKonum.Ust;
  Defter^.FDikeyKCubugu^.Hizala;
end;

{==============================================================================
  defter nesnesini �izer
 ==============================================================================}
procedure TDefter.Ciz;
var
  Defter: PDefter = nil;
  Alan: TAlan;
  pxSol, pxUst: TISayi4;      // defter nesnesine yaz�lacak karakterin pixel olarak sol / �st de�erleri
  YaziBellekAdresi: PChar;
  SinirSutunIlk, SinirSutunSon,
  SinirSatirIlk, SinirSatirSon,
  AktifSutunNo, AktifSatirNo: TISayi4;
begin

  Defter := PDefter(Defter^.NesneAl(Kimlik));
  if(Defter = nil) then Exit;

  inherited Ciz;

  // defter nesnesinin �izim alan koordinatlar�n� al
  Alan := Defter^.FCizimAlan;

  // e�er defter nesnesi i�in bellek ayr�ld�ysa defter i�eri�ini nesne i�eri�ine
  // eklenen bilgilerle doldur
  if(Defter^.FYaziBellekAdresi <> nil) and (Defter^.FYaziUzunlugu > 0) then
  begin

    // s�tun / sat�r ilk de�erler
    AktifSutunNo := -Defter^.FYatayKCubugu^.FMevcutDeger;
    AktifSatirNo := -Defter^.FDikeyKCubugu^.FMevcutDeger;

    // s�n�r de�erleri
    SinirSutunIlk := Alan.Sol;
    SinirSutunSon := (Alan.Sag div 8) - 3;      // 2 bo�luk yatay kayd�rma �ubu�u + 1 bo�luk = 3 bo�luk karakteri
    SinirSatirIlk := Alan.Ust;
    SinirSatirSon := (Alan.Alt div 16) - 2;     // 1 bo�luk dikey kayd�rma �ubu�u + 1 bo�luk = 2 bo�luk karakteri

    // defter i�erik bellek b�lgesine konumlan
    YaziBellekAdresi := PChar(Defter^.FYaziBellekAdresi);

    // bellek i�eri�i s�f�r oluncaya kadar devam et
    while (YaziBellekAdresi^ <> #0) do
    begin

      // giri� (enter) karakteri olmas� durumunda herhangi bir�ey yapma
      if(YaziBellekAdresi^ = #13) then begin end

      // sat�r ba�� + bir alt sat�ra ge�
      else if(YaziBellekAdresi^ = #10) then
      begin

        AktifSutunNo := -Defter^.FYatayKCubugu^.FMevcutDeger;
        Inc(AktifSatirNo);
      end
      else
      begin

        { TODO - metin sarmaland���nda SADECE dikey kayd�rma ger�ekle�tirilecek,
          yatay kayd�rma �ubu�u pasifle�tirilecek }
        if(AktifSutunNo >= SinirSutunIlk) and (AktifSutunNo <= SinirSutunSon) and
          (AktifSatirNo >= SinirSatirIlk) and (AktifSatirNo <= SinirSatirSon) then
        begin

          pxSol := AktifSutunNo * 8;
          pxSol += Alan.Sol + 4;

          pxUst := AktifSatirNo * 16;
          pxUst += Alan.Ust + 4;

          HarfYaz(Defter, pxSol, pxUst, YaziBellekAdresi^, Defter^.FYaziRenk);
        end;

        Inc(AktifSutunNo);
        if(AktifSutunNo > SinirSutunSon) and (Defter^.FMetinSarmala) then
        begin

          AktifSutunNo := -Defter^.FYatayKCubugu^.FMevcutDeger;
          Inc(AktifSatirNo);

          // yazma i�lemi alt s�n�r� a�mas� durumunda zaten yaz�m yap�lamayaca��ndan
          // gereksiz i�lem yap�lmamas� i�in i�levden ��k
          if(AktifSatirNo > SinirSatirSon) then Exit;
        end;
      end;

      Inc(YaziBellekAdresi);
    end;
  end;

  // kayd�rma �ubuklar�n� en son �iz
  //Defter^.FYatayKCubugu^.Ciz;
  //Defter^.FDikeyKCubugu^.Ciz;
end;

{==============================================================================
  defter nesnesinin i�eri�indeki verileri siler
 ==============================================================================}
procedure TDefter.Temizle;
begin

  Self.FYaziUzunlugu := 0;

  Self.FDikeyKCubugu^.FMevcutDeger := 0;
  Self.FYatayKCubugu^.FMevcutDeger := 0;

  BellekDoldur(Self.FYaziBellekAdresi, 4096 * 10, 0);

  YatayDikeyKarakterSayisiniAl;

  Ciz;
end;

{==============================================================================
  defter nesnesine karakter katar� ekler - pchar
 ==============================================================================}
procedure TDefter.YaziEkle(AYaziBellekAdresi: Isaretci);
var
  p: PSayi1;
  i: TSayi4;
  function StrLen2: TSayi4;
  var
    p: PChar;
  begin

    Result := 0;

    p := AYaziBellekAdresi;

    while (p^ <> #0) do begin Inc(p); Inc(Result); end;
  end;
begin

  // karakter katar� i�in bellek ayr�lm�� m� ?
  if(Self.FYaziBellekAdresi = nil) then Exit;

  // verinin uzunlu�unu al
  i := StrLen2; //(AYaziBellekAdresi);
  if(i = 0) or (i > (4096 * 10)) then Exit;

  // karakter katar�n� hedef b�lgeye kopyala
  p := PByte(Self.FYaziBellekAdresi + FYaziUzunlugu);
  Tasi2(AYaziBellekAdresi, p, i);

  // s�f�r sonland�rma i�aretini ekle
  FYaziUzunlugu += i;
  p := PByte(Self.FYaziBellekAdresi + FYaziUzunlugu);
  p^ := 0;

  YatayDikeyKarakterSayisiniAl;

  Ciz;
end;

{==============================================================================
  defter nesnesine karakter katar� ekler - string
 ==============================================================================}
procedure TDefter.YaziEkle(ADeger: string);
var
  p: PSayi1;
  i: TSayi4;
begin

  // karakter katar� i�in bellek ayr�lm�� m� ?
  if(Self.FYaziBellekAdresi = nil) then Exit;

  // verinin uzunlu�unu al
  i := Length(ADeger);
  if(i = 0) or (i > (4096 * 10)) then Exit;

  // karakter katar�n� hedef b�lgeye kopyala
  p := PByte(TSayi4(Self.FYaziBellekAdresi) + Self.FYaziUzunlugu);
  Tasi2(@ADeger[1], p, i);

  // s�f�r sonland�rma i�aretini ekle
  Self.FYaziUzunlugu += i;
  p := PByte(TSayi4(Self.FYaziBellekAdresi) + Self.FYaziUzunlugu);
  p^ := 0;

  YatayDikeyKarakterSayisiniAl;

  Ciz;
end;

procedure TDefter.YatayDikeyKarakterSayisiniAl;
var
  p: PChar;
  i: TSayi4;
begin

  FYatayKarSay := 0;
  FDikeyKarSay := 0;

  if(FYaziUzunlugu = 0) then Exit;

  p := PChar(FYaziBellekAdresi);
  i := 0;
  while p^ <> #0 do
  begin

    if(p^ = #10) then
    begin

      Inc(FDikeyKarSay);
      if(i > FYatayKarSay) then FYatayKarSay := i;
      i := 0;
    end else Inc(i);

    Inc(p);
  end;

  FYatayKCubugu^.FUstDeger := FYatayKarSay;
  FDikeyKCubugu^.FUstDeger := FDikeyKarSay;
end;

{==============================================================================
  defter nesne olaylar�n� i�ler
 ==============================================================================}
procedure TDefter.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Defter: PDefter;
  i: TISayi4;
begin

  Defter := PDefter(AGonderici);
  if(Defter = nil) then Exit;

  if(AOlay.Olay = FO_KAYDIRMA) then
  begin

    // metni yukar� kayd�rma i�levi
    if(AOlay.Deger1 < 0) then
    begin

      i := Defter^.FDikeyKCubugu^.FMevcutDeger;
      Dec(i);
      if(i >= 0) then Defter^.FDikeyKCubugu^.FMevcutDeger := i;

      Defter^.Ciz;
    end

    // metni a�a��ya kayd�rma i�levi
    else if(AOlay.Deger1 > 0) then
    begin

      i := Defter^.FDikeyKCubugu^.FMevcutDeger;
      Inc(i);
      if(i < Defter^.FDikeyKCubugu^.FUstDeger) then
      begin

        Defter^.FDikeyKCubugu^.FMevcutDeger := i;
        Defter^.Ciz;
      end;
    end;
  end;

  // ge�erli fare g�stergesini g�ncelle
  GecerliFareGostegeTipi := Defter^.FFareImlecTipi;
end;

{==============================================================================
  defter nesnesine ba�l� kayd�rma �ubu�u olaylar�n� i�ler
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

  // ge�erli fare g�stergesini g�ncelle
  GecerliFareGostegeTipi := Defter^.FFareImlecTipi;
end;

end.
