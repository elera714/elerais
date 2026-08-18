{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_panel.pas
  Dosya İşlevi: panel (TPanel) yönetim işlevlerini içerir

  Güncelleme Tarihi: 18/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_panel;

interface

uses gorselnesne, paylasim;

type
  PPanel = ^TPanel;
  TPanel = class(TGorselNesne)
  public
    constructor Create; override;
    destructor Destroy; override;
    function Yapilandir2(AKullanimTipi: TKullanimTipi; ANesne, AAtaNesne: TGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4; ACizimModel: TSayi4; AGovdeRenk1, AGovdeRenk2,
      AYaziRenk: TRenk; ABaslik: string): TISayi4;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
  end;

function PanelCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function PanelGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ACizimModel: TSayi4; AGovdeRenk1, AGovdeRenk2, AYaziRenk: TRenk; ABaslik: string): TKimlik;

implementation

uses gorev, gn_islevler, gn_pencere, gn_resimdugmesi, gn_kaydirmacubugu, gn_dugme,
  gn_gucdugmesi, gn_defter, gn_baglanti, gn_degerdugmesi, gn_izgara, gn_renksecici,
  gn_durumcubugu, gn_etiket, gn_giriskutusu, gn_islemgostergesi, gn_karmaliste,
  gn_listegorunum, gn_listekutusu, gn_onaykutusu, gn_resim, gn_secimdugmesi, src_ps2,
  gn_araccubugu, gn_degerlistesi, gn_sayfakontrol;

{==============================================================================
    panel kesme çağrılarını yönetir
 ==============================================================================}
function PanelCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  Pencere: TPencere;
  Panel: TPanel;
  Hiza: THiza;
  Konum: PKonum;
  Boyut: PBoyut;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := PanelGNOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^, PSayi4(ADegiskenler + 20)^,
        PRenk(ADegiskenler + 24)^, PRenk(ADegiskenler + 28)^, PRenk(ADegiskenler + 32)^,
        PKarakterKatari(PSayi4(ADegiskenler + 36)^ + GGorevler.FAktifGrvBelAdr)^);
    end;

    ISLEV_GOSTER:
    begin

      Panel := TPanel(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Panel.Goster;
    end;

    ISLEV_HIZALA:
    begin

      Panel := TPanel(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      Panel.FHiza := Hiza;

      Pencere := TPencere(Panel.FAtaNesne);
      Pencere.Guncelle;
    end;

    // panel konum ve boyut değerlerini geri döndür
    $010E:
    begin

      Panel := TPanel(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Panel <> nil) then
      begin

        Konum := PKonum(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr);
        Boyut := PBoyut(PSayi4(ADegiskenler + 08)^ + GGorevler.FAktifGrvBelAdr);
        Konum^.Sol := Panel.FAtananAlan.Sol;
        Konum^.Ust := Panel.FAtananAlan.Ust;
        Boyut^.Genislik := Panel.FAtananAlan.Genislik;
        Boyut^.Yukseklik := Panel.FAtananAlan.Yukseklik;
      end;
    end;
  end;
end;

{==============================================================================
  uygulama için panel nesnesi oluşturur - api
 ==============================================================================}
function PanelGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ACizimModel: TSayi4; AGovdeRenk1, AGovdeRenk2, AYaziRenk: TRenk; ABaslik: string): TKimlik;
var
  Panel: TPanel;
begin

  Panel := TPanel.Create;

  if(Panel = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    Panel.Yapilandir2(ktNesne, Panel, AAtaNesne, ASol, AUst, AGenislik, AYukseklik,
      ACizimModel, AGovdeRenk1, AGovdeRenk2, AYaziRenk, ABaslik);

    Result := Panel.Kimlik;
  end;
end;

{==============================================================================
  panel nesnesi oluşturur
 ==============================================================================}
constructor TPanel.Create;
begin

  inherited Create;

  NesneTipi := gntPanel;

  { bilgi: görsel nesneyi listeye ekleme işlevi bu nesneden (TPanel) türeyen her bir
    nesne tarafından gerçekleşmektedir. bu nesne için listeye ekleme işlevi nesne kontrolü
    yapılarak Yapilandir2 işleviyle gerçekleşmektedir }
  //GGNesneler.GorselNesne[FSiraNo] := Self;
end;

{==============================================================================
  panel nesnesini yok eder
 ==============================================================================}
destructor TPanel.Destroy;
begin

  if(NesneTipi = gntPanel) then GGNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  panel nesnesini özelleştirir
 ==============================================================================}
function TPanel.Yapilandir2(AKullanimTipi: TKullanimTipi; ANesne, AAtaNesne: TGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4; ACizimModel: TSayi4; AGovdeRenk1, AGovdeRenk2,
  AYaziRenk: TRenk; ABaslik: string): TISayi4;
begin

  Yapilandir1(AKullanimTipi, gntPanel, ANesne, AAtaNesne, ASol, AUst,
    AGenislik, AYukseklik, ACizimModel, AGovdeRenk1, AGovdeRenk2, AYaziRenk, ABaslik);

  if(AKullanimTipi = ktTuvalNesne) then
    FTuvalNesne := ANesne
  else FTuvalNesne := AAtaNesne.FTuvalNesne;

  if(NesneTipi = gntPanel) then GGNesneler.GorselNesne[FSiraNo] := Self;

  OlayCagriAdr := @OlaylariIsle;

  Odaklanilabilir := False;
  Odaklanildi := False;

  // geri dönüş değeri
  Result := HATA_YOK;
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
  GN: TGorselNesne;
  GNBellekAdresi: PGorselNesne;
  i: TSayi4;
begin

  inherited Hizala;

  // panel alt nesnelerini hizala
  if(AltNesneSayisi > 0) then
  begin

    GNBellekAdresi := AltNesneBellekAdresi;

    // ilk oluşturulan alt nesneden son oluşturulan alt nesneye doğru
    // panelin alt nesnelerini yeniden hizala
    for i := 0 to AltNesneSayisi - 1 do
    begin

      GN := GNBellekAdresi[i];
      if(GN.Gorunum) then
      begin

        // yeni eklenecek görsel nesne - görsel nesneyi buraya ekle...
        case GN.NesneTipi of
          //gntAcilirMenu     :
          gntAracCubugu     : TAracCubugu(GN).Hizala;
          gntBaglanti       : TBaglanti(GN).Hizala;
          gntDefter         : TDefter(GN).Hizala;
          gntDegerDugmesi   : TDegerDugmesi(GN).Hizala;
          gntDegerListesi   : TDegerListesi(GN).Hizala;
          gntDugme          : TDugme(GN).Hizala;
          gntDurumCubugu    : TDurumCubugu(GN).Hizala;
          gntEtiket         : TEtiket(GN).Hizala;
          gntGirisKutusu    : TGirisKutusu(GN).Hizala;
          gntGucDugmesi     : TGucDugmesi(GN).Hizala;
          gntIslemGostergesi: TIslemGostergesi(GN).Hizala;
          gntIzgara         : TIzgara(GN).Hizala;
          gntKarmaListe     : TKarmaListe(GN).Hizala;
          gntKaydirmaCubugu : TKaydirmaCubugu(GN).Hizala;
          gntListeGorunum   : TListeGorunum(GN).Hizala;
          gntListeKutusu    : TListeKutusu(GN).Hizala;
          //gntMasaustu;
          //gntMenu;
          gntOnayKutusu     : TOnayKutusu(GN).Hizala;
          gntPanel          : TPanel(GN).Hizala;
          //gntPencere;
          gntRenkSecici     : TRenkSecici(GN).Hizala;
          gntResim          : TResim(GN).Hizala;
          gntResimDugmesi   : TResimDugmesi(GN).Hizala;
          gntSayfaKontrol   : TSayfaKontrol(GN).Hizala;
          gntSecimDugmesi   : TSecimDugmesi(GN).Hizala;
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
  GN: TGorselNesne;
  GNBellekAdresi: PGorselNesne;
  i: TSayi4;
begin

  inherited Ciz;

  if(AltNesneSayisi = 0) or (Gorunum = False) then Exit;

  GNBellekAdresi := AltNesneBellekAdresi;

  // alt nesneleri yeniden çiz
  for i := 0 to AltNesneSayisi - 1 do
  begin

    GN := GNBellekAdresi[i];

    if(GN.Gorunum) then
    begin

      // yeni eklenecek görsel nesne - görsel nesneyi buraya ekle...
      // panelin altında olabilecek tüm nesneler
      case GN.NesneTipi of
        //gntAcilirMenu     :
        gntAracCubugu     : TAracCubugu(GN).Ciz;
        gntBaglanti       : TBaglanti(GN).Ciz;
        gntDefter         : TDefter(GN).Ciz;
        gntDegerDugmesi   : TDegerDugmesi(GN).Ciz;
        gntDegerListesi   : TDegerListesi(GN).Ciz;
        gntDugme          : TDugme(GN).Ciz;
        gntDurumCubugu    : TDurumCubugu(GN).Ciz;
        gntEtiket         : TEtiket(GN).Ciz;
        gntGirisKutusu    : TGirisKutusu(GN).Ciz;
        gntGucDugmesi     : TGucDugmesi(GN).Ciz;
        gntIslemGostergesi: TIslemGostergesi(GN).Ciz;
        gntIzgara         : TIzgara(GN).Ciz;
        gntKarmaListe     : TKarmaListe(GN).Ciz;
        gntKaydirmaCubugu : TKaydirmaCubugu(GN).Ciz;
        gntListeGorunum   : TListeGorunum(GN).Ciz;
        gntListeKutusu    : TListeKutusu(GN).Ciz;
        //gntMasaustu;
        //gntMenu;
        gntOnayKutusu     : TOnayKutusu(GN).Ciz;
        gntPanel          : TPanel(GN).Ciz;
        //gntPencere;
        gntRenkSecici     : TRenkSecici(GN).Ciz;
        gntResim          : TResim(GN).Ciz;
        gntResimDugmesi   : TResimDugmesi(GN).Ciz;
        gntSayfaKontrol   : TSayfaKontrol(GN).Ciz;
        gntSecimDugmesi   : TSecimDugmesi(GN).Ciz;
      end;
    end;
  end;
end;

{==============================================================================
  panel nesne olaylarını işler
 ==============================================================================}
procedure TPanel.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Pencere: TPencere;
  Panel: TPanel;
begin

  // nesnenin olay çağrı adresi türemiş başka bir nesne tarafından belirlenmişse,
  // olayları koşulsuz olarak ilgili nesneye yönlendir
  if not(AGonderici.OlayYonlAdr = nil) then
  begin

    AGonderici.OlayYonlAdr(AGonderici, AOlay);
    Exit;
  end;

  Panel := TPanel(AGonderici);
  if(Panel = nil) then Exit;

  // sol tuşa basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // panelin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := GGNesneler.EnUstPencereNesnesiniAl(Panel);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GGNesneler.AktifPencere) then
      Pencere.EnUsteGetir(Pencere);

    // sol tuş basım işlemi olay alanında gerçekleştiyse
    if(Panel.FareNesneOlayAlanindaMi(Panel)) then
    begin

      // fare mesajlarını panel nesnesine yönlendir
      GGNesneler.OlayYakalamayaBasla(Panel);

      GGorevler.OlayEkle(Panel.GrvKimlik, AOlay);
    end;
  end

  // sol tuş bırakım işlemi
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare mesajlarını yakalamayı bırak
    GGNesneler.OlayYakalamayiBirak(Panel);

    // fare bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(Panel.FareNesneOlayAlanindaMi(Panel)) then
    begin

      // uygulamaya veya efendi nesneye mesaj gönder
      AOlay.Olay := FO_TIKLAMA;
      GGorevler.OlayEkle(Panel.GrvKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    GGorevler.OlayEkle(Panel.GrvKimlik, AOlay);
  end
  else
  begin

    //GorevListesi[Panel^.GrvKimlik]^.OlayEkle(Panel^.GrvKimlik, AOlay);
  end;

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := Panel.FareImlec;
end;

end.
