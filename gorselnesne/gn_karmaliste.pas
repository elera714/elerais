{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_karmaliste.pas
  Dosya İşlevi: karma liste (açılır / kapanır liste kutusu (TComboBox)) yönetim işlevlerini içerir

  Güncelleme Tarihi: 17/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_karmaliste;

interface

uses gorselnesne, paylasim, gn_pencere, n_yazilistesi, gn_panel, gn_acilirmenu;

type
  PKarmaListe = ^TKarmaListe;
  TKarmaListe = class(TPanel)
  private
    FAcilirMenu: TAcilirMenu;
    procedure OkResminiCiz(AGorselNesne: TGorselNesne; AAlan: TAlan);
  public
    constructor Create; override;
    destructor Destroy; override;
    function Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4): TISayi4;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
    procedure AcilirMenuOlaylariniIsle(AGonderici: TGorselNesne; AOlay: TOlay);
    procedure ListeyeEkle(ADeger: string);
    procedure ListeyiTemizle;
    procedure BaslikSiraNoYaz(ASiraNo: TISayi4);
  end;

function KarmaListeCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function KarmaListeGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik,
  AYukseklik: TISayi4): TKimlik;

implementation

uses gn_islevler, hamresim, gorev, src_ps2;

{==============================================================================
  karma liste kesme çağrılarını yönetir
 ==============================================================================}
function KarmaListeCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  Pencere: TPencere;
  KarmaListe: TKarmaListe;
  Hiza: THiza;
  p: PKarakterKatari;
  i: TISayi4;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    // nesne oluştur
    ISLEV_OLUSTUR:
    begin

      GN := GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := KarmaListeGNOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^);
    end;

    ISLEV_GOSTER:
    begin

      KarmaListe := TKarmaListe(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      KarmaListe.Goster;
    end;

    ISLEV_HIZALA:
    begin

      KarmaListe := TKarmaListe(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      KarmaListe.FHiza := Hiza;

      Pencere := TPencere(KarmaListe.FAtaNesne);
      Pencere.Guncelle;
    end;

    // eleman ekle
    $010F:
    begin

      { TODO : nesneye her eleman eklendikçe nesnenin yüksekliği otomatik artırılacak }
      KarmaListe := TKarmaListe(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntKarmaListe));
      if(KarmaListe <> nil) then
        KarmaListe.ListeyeEkle(PKarakterKatari(PSayi4(ADegiskenler + 04)^ +
          GGorevler.FAktifGrvBelAdr)^);

      Result := 1;
    end;

    // liste içeriğini temizle
    $020F:
    begin

      KarmaListe := TKarmaListe(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntKarmaListe));
      if(KarmaListe <> nil) then
      begin

        // eğer daha önce bellek ayrıldıysa
        KarmaListe.Baslik := '';

        KarmaListe.FAcilirMenu.FMenuBaslikListesi.Temizle;
        KarmaListe.Ciz;
      end;
    end;

    // karma listedeki seçilen yazı (text) değerini geri döndür
    $030E:
    begin

      KarmaListe := TKarmaListe(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntKarmaListe));
      if(KarmaListe <> nil) then
      begin

        p := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr);
        p^ := KarmaListe.Baslik;
      end;
    end;

    // toplam kayıt sayısını al
    $040E:
    begin

      KarmaListe := TKarmaListe(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      if not(KarmaListe = nil) then
        Result := KarmaListe.FAcilirMenu.FMenuBaslikListesi.ElemanSayisi;
    end;

    // seçili sıra numarasını al
    $050E:
    begin

      KarmaListe := TKarmaListe(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      if not(KarmaListe = nil) then
        Result := KarmaListe.FAcilirMenu.SeciliSiraNo
      else Result := -1;
    end;

    // seçili sıra numarasını yaz
    $050F:
    begin

      KarmaListe := TKarmaListe(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      if not(KarmaListe = nil) then
      begin

        i := PISayi4(ADegiskenler + 04)^;
        KarmaListe.BaslikSiraNoYaz(i);
      end;
    end;
  end;
end;

{==============================================================================
  uygulama için karma liste nesnesi oluşturur - api
 ==============================================================================}
function KarmaListeGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik,
  AYukseklik: TISayi4): TKimlik;
var
  KarmaListe: TKarmaListe;
begin

  KarmaListe := TKarmaListe.Create;

  if(KarmaListe = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    KarmaListe.Ozellestir(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik);

    Result := KarmaListe.Kimlik;
  end;
end;

{==============================================================================
  karma liste nesnesi oluşturur
 ==============================================================================}
constructor TKarmaListe.Create;
begin

  inherited Create;

  NesneTipi := gntKarmaListe;

  GGNesneler.GorselNesne[FSiraNo] := Self;
end;

{==============================================================================
  karma liste nesnesini yok eder
 ==============================================================================}
destructor TKarmaListe.Destroy;
begin

  FAcilirMenu.Destroy;

  GGNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  karma liste nesnesini özelleştirir
 ==============================================================================}
function TKarmaListe.Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4): TISayi4;
begin

  Yapilandir2(AKullanimTipi, Self, AAtaNesne, ASol, AUst, AGenislik, 22 {AYukseklik},
    2, RENK_GRI, RENK_BEYAZ, 0, '');

  OlayCagriAdr := @OlaylariIsle;

  FAcilirMenu := TAcilirMenu.Create;
  FAcilirMenu.Ozellestir(Self, 0, 0, AGenislik, (24 * 1) + 2, 24, RENK_GRI, RENK_BEYAZ,
    RENK_SARI, RENK_SIYAH, RENK_LACIVERT);
  FAcilirMenu.FYardimciNesne := True;
  FAcilirMenu.FAcilirMenuOlayGeriDonusAdresi := @AcilirMenuOlaylariniIsle;

  // geri dönüş değeri
  Result := HATA_YOK;
end;

{==============================================================================
  karma liste nesnesini görüntüler
 ==============================================================================}
procedure TKarmaListe.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  karma liste nesnesini gizler
 ==============================================================================}
procedure TKarmaListe.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  karma liste nesnesini hizalandırır
 ==============================================================================}
procedure TKarmaListe.Hizala;
begin

  inherited Hizala;
end;

{==============================================================================
  karma liste nesnesini çizer
 ==============================================================================}
procedure TKarmaListe.Ciz;
var
  CizimAlani: TAlan;
begin

  inherited Ciz;

  // karma listenin çizim alan koordinatlarını al
  CizimAlani := FCizimAlani;

  OkResminiCiz(Self, CizimAlani);

  YaziYaz(Self, CizimAlani.Sol + 4, CizimAlani.Ust + 4, Baslik, RENK_SIYAH);
end;

{==============================================================================
  karma liste nesne olaylarını işler
 ==============================================================================}
procedure TKarmaListe.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Pencere: TPencere;
  KarmaListe: TKarmaListe;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  KarmaListe := TKarmaListe(AGonderici);
  if(KarmaListe = nil) then Exit;

  // sol fare tuş basımı
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // hiç bir şey yapma
  end

  // sol fare tuş bırakım işlemi
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // bilgi: olay yönetimindeki tuş basım işlemindeki bir tasarımdan dolayı
    // basım olay sonrasında menü hemen kapatılmaktadır. bu sebepten dolayı
    // menünün açılması bırakılma işlemine alınmıştır
    Pencere := GGNesneler.EnUstPencereNesnesiniAl(KarmaListe);
    if not(Pencere = nil) then
    begin

      // menüyü farenin bulunduğu konumda görüntüle
      KarmaListe.FAcilirMenu.FAtananAlan.Sol := Pencere.FAtananAlan.Sol + KarmaListe.FCizimBaslangic.Sol;
      KarmaListe.FAcilirMenu.FAtananAlan.Ust := Pencere.FAtananAlan.Ust + KarmaListe.FCizimBaslangic.Ust + 21;

      // açılır menünün görünürlüğünü aktifleştir
      KarmaListe.FAcilirMenu.Goster;

      // aktif menüyü belirle
      GGNesneler.AktifMenu := KarmaListe.FAcilirMenu;
    end;
  end;

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := KarmaListe.FareImlec;
end;

{==============================================================================
  karma listeye bağlı açılır menü nesne olaylarını işler
 ==============================================================================}
procedure TKarmaListe.AcilirMenuOlaylariniIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  KarmaListe: TKarmaListe;
  AcilirMenu: TAcilirMenu;
  SeciliEleman: string;
  Olay: TOlay;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  AcilirMenu := TAcilirMenu(AGonderici);
  if(AcilirMenu = nil) then Exit;

  // menüye tıklanması durumunda başlık değerini değiştir
  if(AOlay.Olay = FO_TIKLAMA) then
  begin

    KarmaListe := TKarmaListe(AcilirMenu.AtaNesne);

    SeciliEleman := AcilirMenu.FMenuBaslikListesi.Yazi[AcilirMenu.SeciliSiraNo];
    KarmaListe.Baslik := SeciliEleman;
    KarmaListe.Ciz;

    // uygulamaya veya efendi nesneye mesaj gönder
    Olay.Kimlik := KarmaListe.Kimlik;
    Olay.Olay := CO_SECIMDEGISTI;
    Olay.Deger1 := AcilirMenu.SeciliSiraNo;
    Olay.Deger2 := 0;
    if not(KarmaListe.OlayYonlAdr = nil) then
      KarmaListe.OlayYonlAdr(KarmaListe, Olay)
    else GGorevler.OlayEkle(KarmaListe.GrvKimlik, Olay);
  end;
end;

procedure TKarmaListe.OkResminiCiz(AGorselNesne: TGorselNesne; AAlan: TAlan);
var
  Renk: PSayi4;
  Yatay, Dikey: TSayi4;
begin

  Renk := PSayi4(@ResimOKAlt);
  for Dikey := 1 to 4 do
  begin

    for Yatay := 1 to 7 do
    begin

      if(Renk^ = $00000000) then
        PixelYaz(AGorselNesne, (AAlan.Sag - 12) + Yatay, (AAlan.Ust + 9) + Dikey, RENK_SIYAH);

      Inc(Renk);
    end;
  end;
end;

procedure TKarmaListe.ListeyeEkle(ADeger: string);
var
  i: TISayi4;
begin

  FAcilirMenu.MenuEkle(ADeger, -1, True);

  i := FAcilirMenu.FMenuBaslikListesi.ElemanSayisi;

  if(i > 0) then FAcilirMenu.FAtananAlan.Yukseklik := (i * 24) + 2;
end;

procedure TKarmaListe.ListeyiTemizle;
begin

  Baslik := '';
  Ciz;

  FAcilirMenu.Temizle;
  FAcilirMenu.FAtananAlan.Yukseklik := (1 * 24) + 2;
end;

procedure TKarmaListe.BaslikSiraNoYaz(ASiraNo: TISayi4);
var
  Olay: TOlay;
begin

  FAcilirMenu.SeciliSiraNo := ASiraNo;
  Baslik := FAcilirMenu.FMenuBaslikListesi.Yazi[ASiraNo];
  Ciz;

  // uygulamaya veya efendi nesneye mesaj gönder
  Olay.Kimlik := Kimlik;
  Olay.Olay := CO_SECIMDEGISTI;
  Olay.Deger1 := ASiraNo;
  Olay.Deger2 := 0;
  if not(OlayYonlAdr = nil) then
    OlayYonlAdr(Self, Olay)
  else GGorevler.OlayEkle(GrvKimlik, Olay);
end;

end.
