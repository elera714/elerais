{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_etiket.pas
  Dosya İşlevi: etiket (TLabel) nesne yönetim işlevlerini içerir

  Güncelleme Tarihi: 26/02/2025

 ==============================================================================}
{$mode objfpc}
unit gn_etiket;

interface

uses gorselnesne, paylasim, gn_panel;

type
  PEtiket = ^TEtiket;
  TEtiket = object(TPanel)
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TSayi4; AYaziRenk: TRenk; ABaslik: string): PEtiket;
    procedure YokEt(AKimlik: TKimlik);
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
  end;

function EtiketCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TSayi4;
  AYaziRenk: TRenk; ABaslik: string): TKimlik;

implementation

uses gn_pencere, gn_islevler, temelgorselnesne, gorev;

{==============================================================================
  etiket nesne kesme çağrılarını yönetir
 ==============================================================================}
function EtiketCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne;
  Pencere: PPencere;
  Etiket: PEtiket;
  p: PKarakterKatari;
begin

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^, PRenk(ADegiskenler + 20)^,
        PKarakterKatari(PSayi4(ADegiskenler + 24)^ + FAktifGorevBellekAdresi)^);
    end;

    ISLEV_GOSTER:
    begin

      Etiket := PEtiket(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      Etiket^.Goster;
    end;

    // etiket başlığını değiştir
    $010F:
    begin

      Etiket := PEtiket(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      p := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
      Etiket^.Baslik := p^;

      // etiketin bağlı olduğu pencere nesnesini güncelle
      Pencere := EnUstPencereNesnesiniAl(Etiket);
      if not(Pencere = nil) then Pencere^.Guncelle;
    end;

    // etiket rengini değiştir
    $020F:
    begin

      Etiket := PEtiket(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      Etiket^.FYaziRenk := PRenk(ADegiskenler + 04)^;

      // etiketin bağlı olduğu pencere nesnesini güncelle
      Pencere := EnUstPencereNesnesiniAl(Etiket);
      if not(Pencere = nil) then Pencere^.Guncelle;
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  etiket nesnesini oluşturur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TSayi4;
  AYaziRenk: TRenk; ABaslik: string): TKimlik;
var
  Etiket: PEtiket;
begin

  Etiket := Etiket^.Olustur(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik, AYaziRenk, ABaslik);

  if(Etiket = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := Etiket^.Kimlik;
end;

{==============================================================================
  etiket nesnesini oluşturur
 ==============================================================================}
function TEtiket.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TSayi4; AYaziRenk: TRenk; ABaslik: string): PEtiket;
var
  Etiket: PEtiket;
begin

  Etiket := PEtiket(inherited Olustur(AKullanimTipi, AAtaNesne, ASol, AUst, AGenislik,
    AYukseklik, 1, RENK_BEYAZ, RENK_BEYAZ, AYaziRenk, ABaslik));

  // nesnenin ad değeri
  Etiket^.NesneTipi := gntEtiket;

  Etiket^.Baslik := ABaslik;

  Etiket^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  Etiket^.Odaklanilabilir := False;
  Etiket^.Odaklanildi := False;

  Etiket^.OlayCagriAdresi := @OlaylariIsle;

  // FCizimModel = arka plan boyama yok, yazı var
  Etiket^.FCizimModel := 1;

  Etiket^.FYaziHiza.Yatay := yhSol;
  Etiket^.FYaziHiza.Dikey := dhUst;

  // nesne adresini geri döndür
  Result := Etiket;
end;

{==============================================================================
  etiket nesnesini yok eder
 ==============================================================================}
procedure TEtiket.YokEt(AKimlik: TKimlik);
begin

  GorselNesneler0.YokEt(AKimlik);
end;

{==============================================================================
  etiket nesnesini görüntüler
 ==============================================================================}
procedure TEtiket.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  etiket nesnesini gizler
 ==============================================================================}
procedure TEtiket.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  etiket nesnesini hizalandırır
 ==============================================================================}
procedure TEtiket.Hizala;
var
  Etiket: PEtiket = nil;
begin

  Etiket := PEtiket(GorselNesneler0.NesneAl(Kimlik));
  if(Etiket = nil) then Exit;

  inherited Hizala;
end;

{==============================================================================
  etiket nesnesini çizer
 ==============================================================================}
procedure TEtiket.Ciz;
var
  Etiket: PEtiket;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  Etiket := PEtiket(GorselNesneler0.NesneAl(Kimlik));
  if(Etiket = nil) then Exit;

  inherited Ciz;
end;

{==============================================================================
  etiket nesne olaylarını işler
 ==============================================================================}
procedure TEtiket.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere;
  Etiket: PEtiket;
begin

  Etiket := PEtiket(AGonderici);

  // farenin sol tuşuna basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // etiketin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(Etiket);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // fare olaylarını yakala
    OlayYakalamayaBasla(Etiket);

    // etiket nesnesini yeniden çiz
    Etiket^.Ciz;

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(Etiket^.OlayYonlendirmeAdresi = nil) then
      Etiket^.OlayYonlendirmeAdresi(Etiket, AOlay)
    else Gorevler0.OlayEkle(Etiket^.GorevKimlik, AOlay);
  end
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    OlayYakalamayiBirak(Etiket);

    // etiket nesnesini yeniden çiz
    Etiket^.Ciz;

    // farenin tuş bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(Etiket^.FareNesneOlayAlanindaMi(Etiket)) then
    begin

      // yakalama & bırakma işlemi bu nesnede olduğu için
      // uygulamaya veya efendi nesneye FO_TIKLAMA mesajı gönder
      AOlay.Olay := FO_TIKLAMA;
      if not(Etiket^.OlayYonlendirmeAdresi = nil) then
        Etiket^.OlayYonlendirmeAdresi(Etiket, AOlay)
      else Gorevler0.OlayEkle(Etiket^.GorevKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    if not(Etiket^.OlayYonlendirmeAdresi = nil) then
      Etiket^.OlayYonlendirmeAdresi(Etiket, AOlay)
    else Gorevler0.OlayEkle(Etiket^.GorevKimlik, AOlay);
  end
  else if(AOlay.Olay = FO_HAREKET) then
  begin

    // etiket nesnesini yeniden çiz
    Etiket^.Ciz;

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(Etiket^.OlayYonlendirmeAdresi = nil) then
      Etiket^.OlayYonlendirmeAdresi(Etiket, AOlay)
    else Gorevler0.OlayEkle(Etiket^.GorevKimlik, AOlay);
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := Etiket^.FareImlecTipi;
end;

end.
