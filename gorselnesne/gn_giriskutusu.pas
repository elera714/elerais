{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: gn_giriskutusu.pas
  Dosya ��levi: giri� kutusu (TEdit) y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 26/02/2025

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
    procedure SilmeDugmeOlaylariniIsle(AGonderici: PGorselNesne; AOlay: TOlay);
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4; ABaslik: string): PGirisKutusu;
    procedure YokEt(AKimlik: TKimlik);
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    property Yazilamaz: Boolean read FDurum1 write FDurum1;
    property SadeceRakam: Boolean read FDurum2 write FDurum2;
  end;

function GirisKutusuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik;

implementation

uses gn_islevler, gn_pencere, genel, temelgorselnesne, gorev, sistemmesaj;

{==============================================================================
  giri� kutusu kesme �a�r�lar�n� y�netir
 ==============================================================================}
function GirisKutusuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne;
  GirisKutusu: PGirisKutusu;
  p1: PKarakterKatari;
  p2: PLongBool;
begin

  case AIslevNo of
    ISLEV_OLUSTUR:
    begin

      GN := GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GN, PISayi4(ADegiskenler + 04)^,
        PISayi4(ADegiskenler + 08)^, PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^,
        PKarakterKatari(PSayi4(ADegiskenler + 20)^ + FAktifGorevBellekAdresi)^);
    end;

    ISLEV_GOSTER:
    begin

      GirisKutusu := PGirisKutusu(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      GirisKutusu^.Goster;
    end;

    // giri� kutusundaki veriyi al
    $010E:
    begin

      GirisKutusu := PGirisKutusu(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      p1 := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
      p1^ := GirisKutusu^.Baslik;
    end;

    // giri� kutusundaki veriyi de�i�tir
    $010F:
    begin

      GirisKutusu := PGirisKutusu(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      p1 := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
      GirisKutusu^.Baslik := p1^;
      GirisKutusu^.Ciz;
    end;

    // giri� kutusunun salt okunur �zelli�ini de�i�tir
    $020F:
    begin

      GirisKutusu := PGirisKutusu(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      p2 := PLongBool(ADegiskenler + 04);
      GirisKutusu^.Yazilamaz := p2^;
      GirisKutusu^.Ciz;
    end;

    // giri� kutusunun say�sal (numeric) de�er �zelli�ini de�i�tir
    $030F:
    begin

      GirisKutusu := PGirisKutusu(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      p2 := PLongBool(ADegiskenler + 04);
      GirisKutusu^.SadeceRakam := p2^;
    end;

    // giri� kutusuna odaklan. (klavye giri�lerini almas�n� sa�la)
    $040F:
    begin

      GirisKutusu := PGirisKutusu(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));

      if(GirisKutusu <> nil) and (GirisKutusu^.NesneTipi = gntGirisKutusu) then
      begin

        // bir �nceki odak alan nesneyi odaktan ��kar
        GN := PPencere(GirisKutusu^.AtaNesne)^.FAktifNesne;
        if(GN <> nil) and (GN^.Odaklanilabilir) then GN^.Odaklanildi := False;

        // nelirtilen nesneyi odaklan�lan nesne olarak belirle
        PPencere(GirisKutusu^.AtaNesne)^.FAktifNesne := GirisKutusu;
        GirisKutusu^.Odaklanildi := True;
      end;
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

  GirisKutusu^.Odaklanilabilir := True;
  GirisKutusu^.Odaklanildi := False;

  GirisKutusu^.OlayCagriAdresi := @OlaylariIsle;

  GirisKutusu^.FareImlecTipi := fitGiris;

  GirisKutusu^.Yazilamaz := False;
  GirisKutusu^.SadeceRakam := False;

  GirisKutusu^.FSilmeDugmesi := GirisKutusu^.FSilmeDugmesi^.Olustur(ktBilesen, GirisKutusu,
    AGenislik - 12, 2, 10, 16, 'X');
  GirisKutusu^.FSilmeDugmesi^.CizimModelDegistir(False, RENK_BEYAZ, RENK_BEYAZ, RENK_SIYAH, RENK_KIRMIZI);
  GirisKutusu^.FSilmeDugmesi^.OlayYonlendirmeAdresi := @SilmeDugmeOlaylariniIsle;

  // nesne bellek adresini geri d�nd�r
  Result := GirisKutusu;
end;

{==============================================================================
  giri� kutusu nesnesini yok eder
 ==============================================================================}
procedure TGirisKutusu.YokEt(AKimlik: TKimlik);
var
  GirisKutusu: PGirisKutusu;
begin

  GirisKutusu := PGirisKutusu(GorselNesneler0.NesneAl(AKimlik));
  if(GirisKutusu = nil) then Exit;

  GirisKutusu^.FSilmeDugmesi^.YokEt(GirisKutusu^.FSilmeDugmesi^.Kimlik);

  inherited YokEt(AKimlik);
end;

{==============================================================================
  giri� kutusu nesnesini g�r�nt�ler
 ==============================================================================}
procedure TGirisKutusu.Goster;
var
  GirisKutusu: PGirisKutusu;
begin

  GirisKutusu := PGirisKutusu(GorselNesneler0.NesneAl(Kimlik));
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
  giri� kutusu nesnesini hizaland�r�r
 ==============================================================================}
procedure TGirisKutusu.Hizala;
var
  GirisKutusu: PGirisKutusu;
begin

  GirisKutusu := PGirisKutusu(GorselNesneler0.NesneAl(Kimlik));
  if(GirisKutusu = nil) then Exit;

  GirisKutusu^.FSilmeDugmesi^.FAtananAlan.Sol := GirisKutusu^.FAtananAlan.Genislik - 13;
  GirisKutusu^.FSilmeDugmesi^.FAtananAlan.Ust := 3;
  GirisKutusu^.FSilmeDugmesi^.FAtananAlan.Genislik := 10;
  GirisKutusu^.FSilmeDugmesi^.FAtananAlan.Yukseklik := 16;
  GirisKutusu^.FSilmeDugmesi^.BoyutlariYenidenHesapla;

  inherited Hizala;
end;

{==============================================================================
  giri� kutusu nesnesini �izer
 ==============================================================================}
procedure TGirisKutusu.Ciz;
var
  GirisKutusu: PGirisKutusu;
  CizimAlani: TAlan;
begin

  GirisKutusu := PGirisKutusu(GorselNesneler0.NesneAl(Kimlik));
  if(GirisKutusu = nil) then Exit;

  inherited Ciz;

  // giri� kutusunun �izim alan koordinatlar�n� al
  CizimAlani := GirisKutusu^.FCizimAlani;

  // nesnenin i�erik de�eri.
  if(GirisKutusu^.Yazilamaz) then

    GirisKutusu^.YaziYaz(GirisKutusu, CizimAlani.Sol + 2, CizimAlani.Ust + 3, GirisKutusu^.Baslik, RENK_SIYAH)
  else
  begin

    // nesne odak kazanm��sa sonuna #255 = klavye kurs�r� ekle
    if(GirisKutusu^.Odaklanildi) then
      GirisKutusu^.YaziYaz(GirisKutusu, CizimAlani.Sol + 2, CizimAlani.Ust + 3,
        GirisKutusu^.Baslik + #255, RENK_SIYAH)
    else GirisKutusu^.YaziYaz(GirisKutusu, CizimAlani.Sol + 2, CizimAlani.Ust + 3,
      GirisKutusu^.Baslik, RENK_SIYAH)
  end;

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
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak i�aretle
    Pencere^.FAktifNesne := GirisKutusu;
    GirisKutusu^.Odaklanildi := True;

    // uygulamaya veya efendi nesneye mesaj g�nder
    if not(GirisKutusu^.OlayYonlendirmeAdresi = nil) then
      GirisKutusu^.OlayYonlendirmeAdresi(GirisKutusu, AOlay)
    else Gorevler0.OlayEkle(GirisKutusu^.GorevKimlik, AOlay);
  end
  // klavye tu� bas�m�
  else if(AOlay.Olay = CO_TUSBASILDI) then
  begin

    Tus := (AOlay.Deger1 and $FF);

    if not(GirisKutusu^.Yazilamaz) then
    begin

      C := Char(Tus);

      // enter tu�u
      if(C = #10) then
      begin

        // uygulamaya veya efendi nesneye mesaj g�nder
        AOlay.Deger1 := Tus;
        if not(GirisKutusu^.OlayYonlendirmeAdresi = nil) then
          GirisKutusu^.OlayYonlendirmeAdresi(GirisKutusu, AOlay)
        else Gorevler0.OlayEkle(GirisKutusu^.GorevKimlik, AOlay);
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
        else Gorevler0.OlayEkle(GirisKutusu^.GorevKimlik, AOlay);
      end
      else
      begin

        if(GirisKutusu^.SadeceRakam) then
        begin

          if(C in ['0'..'9', 'A'..'F', 'a'..'f']) then
          begin

            GirisKutusu^.Baslik := GirisKutusu^.Baslik + C;

            // uygulamaya veya efendi nesneye mesaj g�nder
            AOlay.Deger1 := Tus;
            if not(GirisKutusu^.OlayYonlendirmeAdresi = nil) then
              GirisKutusu^.OlayYonlendirmeAdresi(GirisKutusu, AOlay)
            else Gorevler0.OlayEkle(GirisKutusu^.GorevKimlik, AOlay);
          end;
        end
        else
        begin

          GirisKutusu^.Baslik := GirisKutusu^.Baslik + C;

          AOlay.Deger1 := Tus;
          if not(GirisKutusu^.OlayYonlendirmeAdresi = nil) then
            GirisKutusu^.OlayYonlendirmeAdresi(GirisKutusu, AOlay)
          else Gorevler0.OlayEkle(GirisKutusu^.GorevKimlik, AOlay);
        end;
      end;

      GirisKutusu^.Ciz;
    end;
  end;

  // ge�erli fare g�stergesini g�ncelle
  GecerliFareGostegeTipi := GirisKutusu^.FareImlecTipi;
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

    // nesneyi aktif nesne olarak i�aretle
    PPencere(GirisKutusu^.AtaNesne)^.FAktifNesne := GirisKutusu;
    GirisKutusu^.Odaklanildi := True;
  end
end;

end.
