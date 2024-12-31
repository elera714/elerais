{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: gn_giriskutusu.pas
  Dosya ��levi: giri� kutusu (TEdit) y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 30/12/2024

 ==============================================================================}
{$mode objfpc}
unit gn_giriskutusu;

interface

uses gorselnesne, paylasim, gn_panel, gn_dugme;

type
  PGirisKutusu = ^TGirisKutusu;
  TGirisKutusu = object(TPanel)
  private
    FSilmeDugmesi: PDugme;
    FYazilamaz: Boolean;
    FSadeceRakam: Boolean;
    procedure SilmeDugmeOlaylariniIsle(AGonderici: PGorselNesne; AOlay: TOlay);
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4; ABaslik: string): PGirisKutusu;
    procedure YokEt;
    procedure Goster;
    procedure Gizle;
    procedure Boyutlandir;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
  end;

function GirisKutusuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik;

implementation

uses gn_islevler, gn_pencere, genel, temelgorselnesne;

{==============================================================================
  giri� kutusu kesme �a�r�lar�n� y�netir
 ==============================================================================}
function GirisKutusuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GorselNesne: PGorselNesne;
  GirisKutusu: PGirisKutusu;
  p1: PKarakterKatari;
  p2: PLongBool;
begin

  case AIslevNo of
    ISLEV_OLUSTUR:
    begin

      GorselNesne := GorselNesne^.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GorselNesne, PISayi4(ADegiskenler + 04)^,
        PISayi4(ADegiskenler + 08)^, PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^,
        PKarakterKatari(PSayi4(ADegiskenler + 20)^ + CalisanGorevBellekAdresi)^);
    end;

    ISLEV_GOSTER:
    begin

      GirisKutusu := PGirisKutusu(GirisKutusu^.NesneAl(PKimlik(ADegiskenler + 00)^));
      GirisKutusu^.Goster;
    end;

    // giri� kutusundaki veriyi al
    $010E:
    begin

      GirisKutusu := PGirisKutusu(GirisKutusu^.NesneAl(PKimlik(ADegiskenler + 00)^));
      p1 := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi);
      p1^ := GirisKutusu^.Baslik;
    end;

    // giri� kutusundaki veriyi de�i�tir
    $010F:
    begin

      GirisKutusu := PGirisKutusu(GirisKutusu^.NesneAl(PKimlik(ADegiskenler + 00)^));
      p1 := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi);
      GirisKutusu^.Baslik := p1^;
      GirisKutusu^.Ciz;
    end;

    // giri� kutusunun salt okunur �zelli�ini de�i�tir
    $020F:
    begin

      GirisKutusu := PGirisKutusu(GirisKutusu^.NesneAl(PKimlik(ADegiskenler + 00)^));
      p2 := PLongBool(ADegiskenler + 04);
      GirisKutusu^.FYazilamaz := p2^;
      GirisKutusu^.Ciz;
    end;

    // giri� kutusunun say�sal (numeric) de�er �zelli�ini de�i�tir
    $030F:
    begin

      GirisKutusu := PGirisKutusu(GirisKutusu^.NesneAl(PKimlik(ADegiskenler + 00)^));
      p2 := PLongBool(ADegiskenler + 04);
      GirisKutusu^.FSadeceRakam := p2^;
    end;

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  giri� kutusu nesnesini olu�turur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik;
var
  GirisKutusu: PGirisKutusu;
begin

  GirisKutusu := GirisKutusu^.Olustur(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik, ABaslik);

  if(GirisKutusu = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := GirisKutusu^.Kimlik;
end;

{==============================================================================
  giri� kutusu nesnesini olu�turur
 ==============================================================================}
function TGirisKutusu.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4; ABaslik: string): PGirisKutusu;
var
  GirisKutusu: PGirisKutusu;
begin

  AYukseklik := 20;

  GirisKutusu := PGirisKutusu(inherited Olustur(AKullanimTipi, AAtaNesne, ASol, AUst,
    AGenislik, AYukseklik, 2, RENK_GUMUS, RENK_BEYAZ, RENK_SIYAH, ABaslik));

  // g�rsel nesne tipi
  GirisKutusu^.NesneTipi := gntGirisKutusu;

  GirisKutusu^.Baslik := ABaslik;

  GirisKutusu^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  GirisKutusu^.OlayCagriAdresi := @OlaylariIsle;

  GirisKutusu^.FFareImlecTipi := fitGiris;

  GirisKutusu^.FYazilamaz := False;
  GirisKutusu^.FSadeceRakam := False;

  GirisKutusu^.FSilmeDugmesi := GirisKutusu^.FSilmeDugmesi^.Olustur(ktBilesen, GirisKutusu,
    AGenislik - 13, 3, 10, 16, 'x');
  GirisKutusu^.FSilmeDugmesi^.CizimModelDegistir(False, RENK_BEYAZ, RENK_BEYAZ, RENK_SIYAH, RENK_KIRMIZI);
  GirisKutusu^.FSilmeDugmesi^.OlayYonlendirmeAdresi := @SilmeDugmeOlaylariniIsle;

  // nesne bellek adresini geri d�nd�r
  Result := GirisKutusu;
end;

{==============================================================================
  giri� kutusu nesnesini yok eder
 ==============================================================================}
procedure TGirisKutusu.YokEt;
var
  GirisKutusu: PGirisKutusu;
begin

  GirisKutusu := PGirisKutusu(GirisKutusu^.NesneAl(Kimlik));
  if(GirisKutusu = nil) then Exit;

  GirisKutusu^.FSilmeDugmesi^.YokEt;

  inherited YokEt;
end;

{==============================================================================
  giri� kutusu nesnesini g�r�nt�ler
 ==============================================================================}
procedure TGirisKutusu.Goster;
var
  GirisKutusu: PGirisKutusu;
begin

  GirisKutusu := PGirisKutusu(GirisKutusu^.NesneAl(Kimlik));
  if(GirisKutusu = nil) then Exit;

  GirisKutusu^.FSilmeDugmesi^.Gorunum := True;

  inherited Goster;
end;

{==============================================================================
  giri� kutusu nesnesini gizler
 ==============================================================================}
procedure TGirisKutusu.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  giri� kutusu nesnesini boyutland�r�r
 ==============================================================================}
procedure TGirisKutusu.Boyutlandir;
var
  GirisKutusu: PGirisKutusu;
begin

  GirisKutusu := PGirisKutusu(GirisKutusu^.NesneAl(Kimlik));
  if(GirisKutusu = nil) then Exit;

  GirisKutusu^.FSilmeDugmesi^.FKonum.Sol := GirisKutusu^.FBoyut.Genislik - 13;
  GirisKutusu^.FSilmeDugmesi^.FKonum.Ust := 3;
  GirisKutusu^.FSilmeDugmesi^.FBoyut.Genislik := 10;
  GirisKutusu^.FSilmeDugmesi^.FBoyut.Yukseklik := 16;
  GirisKutusu^.FSilmeDugmesi^.BoyutlariYenidenHesapla;

  GirisKutusu^.Hizala;
end;

{==============================================================================
  giri� kutusu nesnesini �izer
 ==============================================================================}
procedure TGirisKutusu.Ciz;
var
  GirisKutusu: PGirisKutusu;
  Alan: TAlan;
begin

  GirisKutusu := PGirisKutusu(GirisKutusu^.NesneAl(Kimlik));
  if(GirisKutusu = nil) then Exit;

  inherited Ciz;

  // giri� kutusunun �izim alan koordinatlar�n� al
  Alan := GirisKutusu^.FCizimAlan;

  // nesnenin i�erik de�eri. #255 = klavye kurs�r�
  if(GirisKutusu^.FYazilamaz) then

    GirisKutusu^.YaziYaz(GirisKutusu, Alan.Sol + 2, Alan.Ust + 3, GirisKutusu^.Baslik, RENK_SIYAH)
  else GirisKutusu^.YaziYaz(GirisKutusu, Alan.Sol + 2, Alan.Ust + 3, GirisKutusu^.Baslik + #255, RENK_SIYAH);

  GirisKutusu^.FSilmeDugmesi^.Ciz;
end;

{==============================================================================
  giri� kutusu nesne olaylar�n� i�ler
 ==============================================================================}
procedure TGirisKutusu.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere;
  GirisKutusu: PGirisKutusu;
  C: Char;
  s: string;
  Tus: TISayi4;
begin

  GirisKutusu := PGirisKutusu(AGonderici);
  if(GirisKutusu = nil) then Exit;

  // fare sol tu� bas�m�
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // giri� kutusunun sahibi olan pencere en �stte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(GirisKutusu);

    // en �stte olmamas� durumunda en �ste getir
    if not(Pencere = nil) and (Pencere <> AktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // uygulamaya veya efendi nesneye mesaj g�nder
    if not(GirisKutusu^.OlayYonlendirmeAdresi = nil) then
      GirisKutusu^.OlayYonlendirmeAdresi(GirisKutusu, AOlay)
    else GorevListesi[GirisKutusu^.GorevKimlik]^.OlayEkle(GirisKutusu^.GorevKimlik, AOlay);
  end
  // klavye tu� bas�m�
  else if(AOlay.Olay = CO_TUSBASILDI) then
  begin

    Tus := (AOlay.Deger1 and $FF);

    if not(FYazilamaz) then
    begin

      C := Char(Tus);

      // enter tu�u
      if(C = #10) then
      begin

        // uygulamaya veya efendi nesneye mesaj g�nder
        AOlay.Deger1 := Tus;
        if not(GirisKutusu^.OlayYonlendirmeAdresi = nil) then
          GirisKutusu^.OlayYonlendirmeAdresi(GirisKutusu, AOlay)
        else GorevListesi[GirisKutusu^.GorevKimlik]^.OlayEkle(GirisKutusu^.GorevKimlik, AOlay);
      end
      // geri silme tu�u
      else if(C = #8) then
      begin

        s := GirisKutusu^.Baslik;
        if(Length(s) = 1) then

          s := ''
        else
        begin

          s := Copy(s, 1, Length(s) - 1);
        end;
        GirisKutusu^.Baslik := s;

        AOlay.Deger1 := Tus;
        if not(GirisKutusu^.OlayYonlendirmeAdresi = nil) then
          GirisKutusu^.OlayYonlendirmeAdresi(GirisKutusu, AOlay)
        else GorevListesi[GirisKutusu^.GorevKimlik]^.OlayEkle(GirisKutusu^.GorevKimlik, AOlay);
      end
      else
      begin

        if(FSadeceRakam) then
        begin

          if(C in ['0'..'9', 'A'..'F', 'a'..'f']) then
          begin

            GirisKutusu^.Baslik := GirisKutusu^.Baslik + C;

            // uygulamaya veya efendi nesneye mesaj g�nder
            AOlay.Deger1 := Tus;
            if not(GirisKutusu^.OlayYonlendirmeAdresi = nil) then
              GirisKutusu^.OlayYonlendirmeAdresi(GirisKutusu, AOlay)
            else GorevListesi[GirisKutusu^.GorevKimlik]^.OlayEkle(GirisKutusu^.GorevKimlik, AOlay);
          end;
        end
        else
        begin

          GirisKutusu^.Baslik := GirisKutusu^.Baslik + C;

          AOlay.Deger1 := Tus;
          if not(GirisKutusu^.OlayYonlendirmeAdresi = nil) then
            GirisKutusu^.OlayYonlendirmeAdresi(GirisKutusu, AOlay)
          else GorevListesi[GirisKutusu^.GorevKimlik]^.OlayEkle(GirisKutusu^.GorevKimlik, AOlay);
        end;
      end;

      GirisKutusu^.Ciz;
    end;
  end;

  // ge�erli fare g�stergesini g�ncelle
  GecerliFareGostegeTipi := GirisKutusu^.FFareImlecTipi;
end;

{==============================================================================
  giri� kutusuna ba�l� silme d��mesi nesne olaylar�n� i�ler
 ==============================================================================}
procedure TGirisKutusu.SilmeDugmeOlaylariniIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  GirisKutusu: PGirisKutusu;
  Dugme: PDugme;
begin

  // nesnenin kimlik, tip de�erlerini denetle.
  Dugme := PDugme(AGonderici);
  if(Dugme = nil) then Exit;

  // silme d��mesine t�klama ger�ekle�tirildi�inde
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    GirisKutusu := PGirisKutusu(Dugme^.AtaNesne);

    GirisKutusu^.Baslik := '';
    GirisKutusu^.Ciz;
  end
end;

end.
