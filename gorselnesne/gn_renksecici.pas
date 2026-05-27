{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: gn_renksecici.pas
  Dosya Ýþlevi: renk seçim yönetim iþlevlerini içerir

  Güncelleme Tarihi: 26/05/2026

 ==============================================================================}
{$mode objfpc}
unit gn_renksecici;

interface

uses gorev, gorselnesne, paylasim, gn_panel;

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
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TSayi4): PRenkSecici;
    procedure YokEt(AKimlik: TKimlik);
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    property FRenkKutuG: TISayi4 read FIDeger1 write FIDeger1;
    property FRenkKutuY: TISayi4 read FIDeger2 write FIDeger2;
    property FSeciliRenkSiraNo: TISayi4 read FIDeger3 write FIDeger3;
  end;

function RenkSeciciCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TSayi4): TKimlik;

implementation

uses gn_pencere, gn_islevler, temelgorselnesne, sistemmesaj;

{==============================================================================
  renk seçici nesne kesme çaðrýlarýný yönetir
 ==============================================================================}
function RenkSeciciCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne;
  RenkSecici: PRenkSecici;
begin

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PRenk(ADegiskenler + 12)^, PRenk(ADegiskenler + 16)^);
    end;

    ISLEV_GOSTER:
    begin

      RenkSecici := PRenkSecici(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      RenkSecici^.Goster;
    end;

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  renk seçici nesnesini oluþturur
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
  renk seçici nesnesini oluþturur
 ==============================================================================}
function TRenkSecici.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TSayi4): PRenkSecici;
var
  RenkSecici: PRenkSecici;
begin

  RenkSecici := PRenkSecici(inherited Olustur(AKullanimTipi, AAtaNesne, ASol, AUst, AGenislik,
    AYukseklik, 0, 0, 0, 0, ''));

  // nesnenin ad deðeri
  RenkSecici^.NesneTipi := gntRenkSecici;

  RenkSecici^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  RenkSecici^.Odaklanilabilir := True;
  RenkSecici^.Odaklanildi := False;

  RenkSecici^.OlayCagriAdresi := @OlaylariIsle;

  // renk kutu geniþlik & yükseklik deðerlerini belirle
  RenkSecici^.FRenkKutuG := AGenislik div 8;
  RenkSecici^.FRenkKutuY := AYukseklik div 2;

  // seçili renk = -1 = seçili renk yok
  RenkSecici^.FSeciliRenkSiraNo := -1;

  // nesne adresini geri döndür
  Result := RenkSecici;
end;

{==============================================================================
  renk seçici nesnesini yok eder
 ==============================================================================}
procedure TRenkSecici.YokEt(AKimlik: TKimlik);
begin

  inherited YokEt(AKimlik);
end;

{==============================================================================
  renk seçici nesnesini görüntüler
 ==============================================================================}
procedure TRenkSecici.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  renk seçici nesnesini gizler
 ==============================================================================}
procedure TRenkSecici.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  renk seçici nesnesini hizalandýrýr
 ==============================================================================}
procedure TRenkSecici.Hizala;
var
  RenkSecici: PRenkSecici = nil;
begin

  RenkSecici := PRenkSecici(GorselNesneler0.NesneAl(Kimlik));
  if(RenkSecici = nil) then Exit;

  inherited Hizala;
end;

{==============================================================================
  renk seçici nesnesini çizer
 ==============================================================================}
procedure TRenkSecici.Ciz;
var
  RenkSecici: PRenkSecici;
  CizimAlani: TAlan;
  i, j, k: TISayi4;
begin

  // nesnenin kimlik, tip deðerlerini denetle.
  RenkSecici := PRenkSecici(GorselNesneler0.NesneAl(Kimlik));
  if(RenkSecici = nil) then Exit;

  // 16 rengi 8 sütün, 2 satýr olarak çiz. (8 x 2)
  k := 0;
  for i := 0 to 1 do
  begin

    for j := 0 to 7 do
    begin

      CizimAlani.Sol := j * FRenkKutuG;
      CizimAlani.Ust := i * FRenkKutuY;
      CizimAlani.Sag := CizimAlani.Sol + FRenkKutuG - 1;
      CizimAlani.Alt := CizimAlani.Ust + FRenkKutuY - 1;
      RenkSecici^.DikdortgenDoldur(RenkSecici, CizimAlani, SecimRenkleri[(i * 8) + j],
        SecimRenkleri[(i * 8) + j]);

      if(k = FSeciliRenkSiraNo) then
        RenkSecici^.Dikdortgen(RenkSecici, ctDuz, CizimAlani, KenarRenkleri[FSeciliRenkSiraNo]);

      Inc(k);
    end;
  end;

  // nesne odaklanýlmýþ ise nesnenin kenarlarýný iþaretle
  if(RenkSecici^.Odaklanildi) then
  begin

    CizimAlani := RenkSecici^.FCizimAlani;
    RenkSecici^.Dikdortgen(RenkSecici, ctNokta, CizimAlani, RENK_SIYAH);
  end;
end;

{==============================================================================
  renk seçici nesne olaylarýný iþler
 ==============================================================================}
procedure TRenkSecici.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere;
  RenkSecici: PRenkSecici;
begin

  RenkSecici := PRenkSecici(AGonderici);

  // farenin sol tuþuna basým iþlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // renk seçicinin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(RenkSecici);

    // en üstte olmamasý durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak iþaretle
    Pencere^.FAktifNesne := RenkSecici;
    RenkSecici^.Odaklanildi := True;

    // fare olaylarýný yakala
    OlayYakalamayaBasla(RenkSecici);

    RenkSecici^.FSeciliRenkSiraNo := ((AOlay.Deger2 div RenkSecici^.FRenkKutuY) * 8) +
      (AOlay.Deger1 div RenkSecici^.FRenkKutuG);

    // renk seçici nesnesini yeniden çiz
    RenkSecici^.Ciz;
  end
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarýný almayý býrak
    OlayYakalamayiBirak(RenkSecici);

    // renk seçici nesnesini yeniden çiz
    RenkSecici^.Ciz;

    // farenin tuþ býrakma iþlemi nesnenin olay alanýnda mý gerçekleþti ?
    if(RenkSecici^.FareNesneOlayAlanindaMi(RenkSecici)) then
    begin

      if(RenkSecici^.FSeciliRenkSiraNo > -1) then
      begin

        // yakalama & býrakma iþlemi bu nesnede olduðu için
        // uygulamaya veya efendi nesneye FO_TIKLAMA mesajý gönder
        AOlay.Olay := FO_TIKLAMA;
        AOlay.Deger1 := SecimRenkleri[RenkSecici^.FSeciliRenkSiraNo];
        AOlay.Deger2 := 0;
        if not(RenkSecici^.OlayYonlendirmeAdresi = nil) then
          RenkSecici^.OlayYonlendirmeAdresi(RenkSecici, AOlay)
        else Gorevler0.OlayEkle(RenkSecici^.GorevKimlik, AOlay);
      end;
    end;
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := RenkSecici^.FareImlecTipi;
end;

end.
