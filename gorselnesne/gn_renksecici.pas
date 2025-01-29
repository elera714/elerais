{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: gn_renksecici.pas
  Dosya ��levi: renk se�im y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 27/01/2025

 ==============================================================================}
{$mode objfpc}
unit gn_renksecici;

interface

uses gorselnesne, paylasim, gn_panel;

const
  SecimRenkleri: array[0..15] of TRenk = (
    RENK_BEYAZ, RENK_GUMUS, RENK_GRI, RENK_SIYAH,
    RENK_KIRMIZI, RENK_BORDO, RENK_SARI, RENK_ZEYTINYESILI,
    RENK_ACIKYESIL, RENK_YESIL, RENK_ACIKMAVI, RENK_TURKUAZ,
    RENK_MAVI, RENK_LACIVERT, RENK_PEMBE, RENK_MOR);
  KenarRenkleri: array[0..15] of TRenk = (
    RENK_SIYAH, RENK_SIYAH, RENK_BEYAZ, RENK_BEYAZ,
    RENK_BEYAZ, RENK_BEYAZ, RENK_SIYAH, RENK_BEYAZ,
    RENK_SIYAH, RENK_BEYAZ, RENK_SIYAH, RENK_BEYAZ,
    RENK_BEYAZ, RENK_BEYAZ, RENK_BEYAZ, RENK_BEYAZ);

type
  PRenkSecici = ^TRenkSecici;
  TRenkSecici = object(TPanel)
  private
    FRenkKutuG, FRenkKutuY,
    FSeciliRenkSiraNo: TISayi4;
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TSayi4): PRenkSecici;
    procedure YokEt;
    procedure Goster;
    procedure Gizle;
    procedure Boyutlandir;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
  end;

function RenkSeciciCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TSayi4): TKimlik;

implementation

uses genel, gn_pencere, gn_islevler, temelgorselnesne, sistemmesaj;

{==============================================================================
  renk se�ici nesne kesme �a�r�lar�n� y�netir
 ==============================================================================}
function RenkSeciciCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GorselNesne: PGorselNesne;
  RenkSecici: PRenkSecici;
begin

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GorselNesne := GorselNesne^.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GorselNesne, PISayi4(ADegiskenler + 04)^,
        PISayi4(ADegiskenler + 08)^, PRenk(ADegiskenler + 12)^, PRenk(ADegiskenler + 16)^);
    end;

    ISLEV_GOSTER:
    begin

      RenkSecici := PRenkSecici(RenkSecici^.NesneAl(PKimlik(ADegiskenler + 00)^));
      RenkSecici^.Goster;
    end;

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  renk se�ici nesnesini olu�turur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TSayi4): TKimlik;
var
  RenkSecici: PRenkSecici;
begin

  RenkSecici := RenkSecici^.Olustur(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik);

  if(RenkSecici = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := RenkSecici^.Kimlik;
end;

{==============================================================================
  renk se�ici nesnesini olu�turur
 ==============================================================================}
function TRenkSecici.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TSayi4): PRenkSecici;
var
  RenkSecici: PRenkSecici;
begin

  RenkSecici := PRenkSecici(inherited Olustur(AKullanimTipi, AAtaNesne, ASol, AUst, AGenislik,
    AYukseklik, 0, 0, 0, 0, ''));

  // nesnenin ad de�eri
  RenkSecici^.NesneTipi := gntRenkSecici;

  RenkSecici^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  RenkSecici^.OlayCagriAdresi := @OlaylariIsle;

  // renk kutu geni�lik & y�kseklik de�erlerini belirle
  RenkSecici^.FRenkKutuG := AGenislik div 8;
  RenkSecici^.FRenkKutuY := AYukseklik div 2;

  // se�ili renk = -1 = se�ili renk yok
  RenkSecici^.FSeciliRenkSiraNo := -1;

  // nesne adresini geri d�nd�r
  Result := RenkSecici;
end;

{==============================================================================
  renk se�ici nesnesini yok eder
 ==============================================================================}
procedure TRenkSecici.YokEt;
begin

  inherited YokEt;
end;

{==============================================================================
  renk se�ici nesnesini g�r�nt�ler
 ==============================================================================}
procedure TRenkSecici.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  renk se�ici nesnesini gizler
 ==============================================================================}
procedure TRenkSecici.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  renk se�ici nesnesini boyutland�r�r
 ==============================================================================}
procedure TRenkSecici.Boyutlandir;
var
  RenkSecici: PRenkSecici = nil;
begin

  RenkSecici := PRenkSecici(RenkSecici^.NesneAl(Kimlik));
  if(RenkSecici = nil) then Exit;

  RenkSecici^.Hizala;
end;

{==============================================================================
  renk se�ici nesnesini �izer
 ==============================================================================}
procedure TRenkSecici.Ciz;
var
  RenkSecici: PRenkSecici;
  Alan: TAlan;
  i, j, k: TISayi4;
begin

  // nesnenin kimlik, tip de�erlerini denetle.
  RenkSecici := PRenkSecici(RenkSecici^.NesneAl(Kimlik));
  if(RenkSecici = nil) then Exit;

  // 16 rengi 8 s�t�n, 2 sat�r olarak �iz. (8 x 2)
  k := 0;
  for i := 0 to 1 do
  begin

    for j := 0 to 7 do
    begin

      Alan.Sol := j * FRenkKutuG;
      Alan.Ust := i * FRenkKutuY;
      Alan.Sag := Alan.Sol + FRenkKutuG - 1;
      Alan.Alt := Alan.Ust + FRenkKutuY - 1;
      RenkSecici^.DikdortgenDoldur(RenkSecici, Alan, SecimRenkleri[(i * 8) + j],
        SecimRenkleri[(i * 8) + j]);

      if(k = FSeciliRenkSiraNo) then
        RenkSecici^.Dikdortgen(RenkSecici, Alan, KenarRenkleri[FSeciliRenkSiraNo]);

      Inc(k);
    end;
  end;
end;

{==============================================================================
  renk se�ici nesne olaylar�n� i�ler
 ==============================================================================}
procedure TRenkSecici.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere;
  RenkSecici: PRenkSecici;
begin

  RenkSecici := PRenkSecici(AGonderici);

  // farenin sol tu�una bas�m i�lemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // renk se�icinin sahibi olan pencere en �stte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(RenkSecici);

    // en �stte olmamas� durumunda en �ste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak i�aretle
    GAktifNesne := RenkSecici;

    // fare olaylar�n� yakala
    OlayYakalamayaBasla(RenkSecici);

    RenkSecici^.FSeciliRenkSiraNo := ((AOlay.Deger2 div RenkSecici^.FRenkKutuY) * 8) +
      (AOlay.Deger1 div RenkSecici^.FRenkKutuG);

    // renk se�ici nesnesini yeniden �iz
    RenkSecici^.Ciz;
  end
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylar�n� almay� b�rak
    OlayYakalamayiBirak(RenkSecici);

    // renk se�ici nesnesini yeniden �iz
    RenkSecici^.Ciz;

    // farenin tu� b�rakma i�lemi nesnenin olay alan�nda m� ger�ekle�ti ?
    if(RenkSecici^.FareNesneOlayAlanindaMi(RenkSecici)) then
    begin

      if(RenkSecici^.FSeciliRenkSiraNo > -1) then
      begin

        // yakalama & b�rakma i�lemi bu nesnede oldu�u i�in
        // uygulamaya veya efendi nesneye FO_TIKLAMA mesaj� g�nder
        AOlay.Olay := FO_TIKLAMA;
        AOlay.Deger1 := SecimRenkleri[RenkSecici^.FSeciliRenkSiraNo];
        AOlay.Deger2 := 0;
        if not(RenkSecici^.OlayYonlendirmeAdresi = nil) then
          RenkSecici^.OlayYonlendirmeAdresi(RenkSecici, AOlay)
        else GorevListesi[RenkSecici^.GorevKimlik]^.OlayEkle(RenkSecici^.GorevKimlik, AOlay);
      end;
    end;
  end;

  // ge�erli fare g�stergesini g�ncelle
  GecerliFareGostegeTipi := RenkSecici^.FFareImlecTipi;
end;

end.
