{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_panel.pas
  Dosya İşlevi: panel (TPanel) yönetim işlevlerini içerir

  Güncelleme Tarihi: 16/07/2026

 ==============================================================================}
{$mode objfpc}
unit gn_panel;

interface

uses gorselnesne, paylasim;

type
  PPanel = ^TPanel;
  TPanel = object(TGorselNesne)
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne; ASol, AUst,
      AGenislik, AYukseklik: TISayi4; ACizimModel: TSayi4; AGovdeRenk1, AGovdeRenk2,
      AYaziRenk: TRenk; ABaslik: string): PPanel;
    procedure YokEt(AKimlik: TKimlik);
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
  end;

function PanelCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ACizimModel: TSayi4; AGovdeRenk1, AGovdeRenk2, AYaziRenk: TRenk; ABaslik: string): TKimlik;

implementation

uses gorev, gn_islevler, temelgorselnesne, gn_pencere, gn_resimdugmesi,
  gn_kaydirmacubugu, gn_dugme, gn_gucdugmesi, gn_defter, gn_baglanti, gn_degerdugmesi,
  gn_durumcubugu, gn_etiket, gn_giriskutusu, gn_islemgostergesi, gn_karmaliste,
  gn_listegorunum, gn_listekutusu, gn_onaykutusu, gn_resim, gn_secimdugmesi,
  gn_araccubugu, gn_degerlistesi, gn_izgara, gn_renksecici, gn_sayfakontrol, sistemmesaj;

{==============================================================================
    panel kesme çağrılarını yönetir
 ==============================================================================}
function PanelCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne = nil;
  Pencere: PPencere = nil;
  Panel: PPanel = nil;
  Hiza: THiza;
  Konum: PKonum;
  Boyut: PBoyut;
begin

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GGorselNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^, PSayi4(ADegiskenler + 20)^,
        PRenk(ADegiskenler + 24)^, PRenk(ADegiskenler + 28)^, PRenk(ADegiskenler + 32)^,
        PKarakterKatari(PSayi4(ADegiskenler + 36)^ + FAktifGorevBellekAdresi)^);
    end;

    ISLEV_GOSTER:
    begin

      Panel := PPanel(GGorselNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Panel^.Goster;
    end;

    ISLEV_HIZALA:
    begin

      Panel := PPanel(GGorselNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      Panel^.F0.FHiza := Hiza;

      Pencere := PPencere(Panel^.FAtaNesne);
      Pencere^.Guncelle;
    end;

    // panel konum ve boyut değerlerini geri döndür
    $010E:
    begin

      Panel := PPanel(GGorselNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Panel <> nil) then
      begin

        Konum := PKonum(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
        Boyut := PBoyut(PSayi4(ADegiskenler + 08)^ + FAktifGorevBellekAdresi);
        Konum^.Sol := Panel^.F0.FAtananAlan.Sol;
        Konum^.Ust := Panel^.F0.FAtananAlan.Ust;
        Boyut^.Genislik := Panel^.F0.FAtananAlan.Genislik;
        Boyut^.Yukseklik := Panel^.F0.FAtananAlan.Yukseklik;
      end;
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  panel nesnesini oluşturur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ACizimModel: TSayi4; AGovdeRenk1, AGovdeRenk2, AYaziRenk: TRenk; ABaslik: string): TKimlik;
var
  Panel: PPanel = nil;
begin

  Panel := Panel^.Olustur(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik,
    ACizimModel, AGovdeRenk1, AGovdeRenk2, AYaziRenk, ABaslik);

  if(Panel = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := Panel^.F0.Kimlik;
end;

{==============================================================================
  panel nesnesini oluşturur
 ==============================================================================}
function TPanel.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne; ASol, AUst,
  AGenislik, AYukseklik: TISayi4; ACizimModel: TSayi4; AGovdeRenk1, AGovdeRenk2,
  AYaziRenk: TRenk; ABaslik: string): PPanel;
var
  Panel: PPanel = nil;
begin

  Panel := PPanel(inherited Olustur(AKullanimTipi, gntPanel, AAtaNesne, ASol, AUst, AGenislik,
    AYukseklik, ACizimModel, AGovdeRenk1, AGovdeRenk2, AYaziRenk, ABaslik));

  if(AKullanimTipi = ktTuvalNesne) then
    Panel^.FTuvalNesne := Panel
  else Panel^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  Panel^.F0.Odaklanilabilir := False;
  Panel^.F0.Odaklanildi := False;

  Panel^.OlayCagriAdresi := @OlaylariIsle;

  // nesne adresini geri döndür
  Result := Panel;
end;

{==============================================================================
  panel nesnesini yok eder
 ==============================================================================}
procedure TPanel.YokEt(AKimlik: TKimlik);
begin

  GGorselNesneler.YokEt(AKimlik);
end;

{==============================================================================
  panel nesnesini görüntüler
 ==============================================================================}
procedure TPanel.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  panel nesnesini gizler
 ==============================================================================}
procedure TPanel.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  panel nesnesini hizalandırır
 ==============================================================================}
procedure TPanel.Hizala;
var
  Panel: PPanel = nil;
  GorunurNesne: PGorselNesne = nil;
  GNBellekAdresi: PPGorselNesne;
  i: TSayi4;
begin

  Panel := PPanel(GGorselNesneler.NesneAl(F0.Kimlik));
  if(Panel = nil) then Exit;

  inherited Hizala;

  // panel alt nesnelerini yeniden boyutlandır
  if(Panel^.F0.AltNesneSayisi > 0) then
  begin

    GNBellekAdresi := Panel^.F0.AltNesneBellekAdresi;

    // ilk oluşturulan alt nesneden son oluşturulan alt nesneye doğru
    // panelin alt nesnelerini yeniden boyutlandır
    for i := 0 to Panel^.F0.AltNesneSayisi - 1 do
    begin

      GorunurNesne := GNBellekAdresi[i];
      if(GorunurNesne^.F0.Gorunum) then
      begin

        // yeni eklenecek görsel nesne - görsel nesneyi buraya ekle...
        case GorunurNesne^.F0.NesneTipi of
          //gntAcilirMenu     :
          gntAracCubugu     : PAracCubugu(GorunurNesne)^.Hizala;
          gntBaglanti       : PBaglanti(GorunurNesne)^.Hizala;
          gntDefter         : PDefter(GorunurNesne)^.Hizala;
          gntDegerDugmesi   : PDegerDugmesi(GorunurNesne)^.Hizala;
          gntDegerListesi   : PDegerListesi(GorunurNesne)^.Hizala;
          gntDugme          : PDugme(GorunurNesne)^.Hizala;
          gntDurumCubugu    : PDurumCubugu(GorunurNesne)^.Hizala;
          gntEtiket         : PEtiket(GorunurNesne)^.Hizala;
          gntGirisKutusu    : PGirisKutusu(GorunurNesne)^.Hizala;
          gntGucDugmesi     : PGucDugmesi(GorunurNesne)^.Hizala;
          gntIslemGostergesi: PIslemGostergesi(GorunurNesne)^.Hizala;
          gntIzgara         : PIzgara(GorunurNesne)^.Hizala;
          gntKarmaListe     : PKarmaListe(GorunurNesne)^.Hizala;
          gntKaydirmaCubugu : PKaydirmaCubugu(GorunurNesne)^.Hizala;
          gntListeGorunum   : PListeGorunum(GorunurNesne)^.Hizala;
          gntListeKutusu    : PListeKutusu(GorunurNesne)^.Hizala;
          //gntMasaustu;
          //gntMenu;
          gntOnayKutusu     : POnayKutusu(GorunurNesne)^.Hizala;
          gntPanel          : PPanel(GorunurNesne)^.Hizala;
          //gntPencere;
          gntRenkSecici     : PRenkSecici(GorunurNesne)^.Hizala;
          gntResim          : PResim(GorunurNesne)^.Hizala;
          gntResimDugmesi   : PResimDugmesi(GorunurNesne)^.Hizala;
          gntSayfaKontrol   : PSayfaKontrol(GorunurNesne)^.Hizala;
          gntSecimDugmesi   : PSecimDugmesi(GorunurNesne)^.Hizala;
        end;
      end;
    end;
  end;
end;

{==============================================================================
  panel nesnesini çizer
 ==============================================================================}
procedure TPanel.Ciz;
var
  GN: PGorselNesne = nil;
  AltGorselNesne: PGorselNesne;
  GNBellekAdresi: PPGorselNesne;
  i: TSayi4;
begin

  GN := GGorselNesneler.NesneAl(F0.Kimlik);
  if(GN = nil) then Exit;

  inherited Ciz;

  if(GN^.F0.AltNesneSayisi = 0) then Exit;

  GNBellekAdresi := GN^.F0.AltNesneBellekAdresi;

  // mevcut görsel nesneyi kaydet
  for i := 0 to GN^.F0.AltNesneSayisi - 1 do
  begin

    AltGorselNesne := GNBellekAdresi[i];

    if(AltGorselNesne^.F0.Gorunum) then
    begin

      // yeni eklenecek görsel nesne - görsel nesneyi buraya ekle...
      // panelin altında olabilecek tüm nesneler
      case AltGorselNesne^.F0.NesneTipi of
        //gntAcilirMenu     :
        gntAracCubugu     : PAracCubugu(AltGorselNesne)^.Ciz;
        gntBaglanti       : PBaglanti(AltGorselNesne)^.Ciz;
        gntDefter         : PDefter(AltGorselNesne)^.Ciz;
        gntDegerDugmesi   : PDegerDugmesi(AltGorselNesne)^.Ciz;
        gntDegerListesi   : PDegerListesi(AltGorselNesne)^.Ciz;
        gntDugme          : PDugme(AltGorselNesne)^.Ciz;
        gntDurumCubugu    : PDurumCubugu(AltGorselNesne)^.Ciz;
        gntEtiket         : PEtiket(AltGorselNesne)^.Ciz;
        gntGirisKutusu    : PGirisKutusu(AltGorselNesne)^.Ciz;
        gntGucDugmesi     : PGucDugmesi(AltGorselNesne)^.Ciz;
        gntIslemGostergesi: PIslemGostergesi(AltGorselNesne)^.Ciz;
        gntIzgara         : PIzgara(AltGorselNesne)^.Ciz;
        gntKarmaListe     : PKarmaListe(AltGorselNesne)^.Ciz;
        gntKaydirmaCubugu : PKaydirmaCubugu(AltGorselNesne)^.Ciz;
        gntListeGorunum   : PListeGorunum(AltGorselNesne)^.Ciz;
        gntListeKutusu    : PListeKutusu(AltGorselNesne)^.Ciz;
        //gntMasaustu;
        //gntMenu;
        gntOnayKutusu     : POnayKutusu(AltGorselNesne)^.Ciz;
        gntPanel          : PPanel(AltGorselNesne)^.Ciz;
        //gntPencere;
        gntRenkSecici     : PRenkSecici(AltGorselNesne)^.Ciz;
        gntResim          : PResim(AltGorselNesne)^.Ciz;
        gntResimDugmesi   : PResimDugmesi(AltGorselNesne)^.Ciz;
        gntSayfaKontrol   : PSayfaKontrol(AltGorselNesne)^.Ciz;
        gntSecimDugmesi   : PSecimDugmesi(AltGorselNesne)^.Ciz;
      end;
    end;
  end;
end;

{==============================================================================
  panel nesne olaylarını işler
 ==============================================================================}
procedure TPanel.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere = nil;
  Panel: PPanel = nil;
begin

  // nesnenin olay çağrı adresi türemiş başka bir nesne tarafından belirlenmişse,
  // olayları koşulsuz olarak ilgili nesneye yönlendir
  if not(AGonderici^.OlayYonlendirmeAdresi = nil) then
  begin

    AGonderici^.OlayYonlendirmeAdresi(AGonderici, AOlay);
    Exit;
  end;

  Panel := PPanel(AGonderici);
  if(Panel = nil) then Exit;

  // sol tuşa basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // panelin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(Panel);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // sol tuş basım işlemi olay alanında gerçekleştiyse
    if(Panel^.FareNesneOlayAlanindaMi(Panel)) then
    begin

      // fare mesajlarını panel nesnesine yönlendir
      OlayYakalamayaBasla(Panel);

      Gorevler0.OlayEkle(Panel^.F0.GorevKimlik, AOlay);
    end;
  end

  // sol tuş bırakım işlemi
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare mesajlarını yakalamayı bırak
    OlayYakalamayiBirak(Panel);

    // fare bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(Panel^.FareNesneOlayAlanindaMi(Panel)) then
    begin

      // uygulamaya veya efendi nesneye mesaj gönder
      AOlay.Olay := FO_TIKLAMA;
      Gorevler0.OlayEkle(Panel^.F0.GorevKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    Gorevler0.OlayEkle(Panel^.F0.GorevKimlik, AOlay);
  end
  else
  begin

    //GorevListesi[Panel^.F0.GorevKimlik]^.OlayEkle(Panel^.F0.GorevKimlik, AOlay);
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := Panel^.F0.FareImlecTipi;
end;

end.
