{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_pencere.pas
  Dosya İşlevi: pencere (TForm) yönetim işlevlerini içerir

  Güncelleme Tarihi: 30/08/2026

  Önemli Bilgiler:

    TPencere'nin alt nesnelerinden biri yeniden kısmi olarak (TEtiket nesnesi gibi)
      çizilmek istendiğinde mutlaka üst nesne olan TPencere.Guncelle işlevini çağırmalıdır.
      Böylece pencere çizim tasarım gereği pencere öncelikle kendini çizecek daha
      sonra ise alt nesnelerinin çizilmesi için alt nesnenin Ciz işlevini çağıracaktır.
      Bu durum en son geliştirilen, pencerelerin bellekten belleğe aktarılması ve
      eğimli dolgu (gradient) çizim işlevleri için gereklidir

 ==============================================================================}
{$mode objfpc}
unit gn_pencere;

interface

uses gorselnesne, paylasim, gn_panel, gn_dugme, gn_resimdugmesi;

type
  PPencere = ^TPencere;
  TPencere = class(TPanel)
  private
    procedure BasliksizPencereOlaylariniIsle(APencere: TPencere; AOlay: TOlay);
    procedure IletisimPencereOlaylariniIsle(APencere: TPencere; AOlay: TOlay);
    procedure BoyutlanabilirPencereOlaylariniIsle(APencere: TPencere; AOlay: TOlay);
    function FarePencereCizimAlanindaMi(APencere: TPencere): Boolean;
    procedure IcBilesenleriKonumlandir(var APencere: TPencere);
    procedure KontrolDugmesiOlaylariniIsle(AGonderici: TGorselNesne; AOlay: TOlay);
  public
    FAtaPencere: TPencere;          // pencerenin (varsa) bir üst penceresi
    FPencereDurum: TPencereDurum;
    FPencereTipi: TPencereTipi;
    FAktifNesne: TGorselNesne;
    FKucultmeDugmesi, FBuyutmeDugmesi,
    FKapatmaDugmesi: TResimDugmesi;
    constructor Create; override;
    destructor Destroy; override;
    function Ozellestir(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
      APencereTipi: TPencereTipi; ABaslik: string; AGovdeRenk: TRenk): TISayi4;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Boyutlandir;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
    procedure Guncelle;
    procedure EnUsteGetir(APencere: TPencere);
  end;

function PencereCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function PencereGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  APencereTipi: TPencereTipi; ABaslik: string; AGovdeRenk: TRenk): TKimlik;

implementation

uses gorev, gn_islevler, gn_masaustu, gn_gucdugmesi, gn_listekutusu, gn_defter,
  gn_islemgostergesi, gn_onaykutusu, gn_giriskutusu, gn_degerdugmesi, gn_renksecici,
  gn_etiket, gn_durumcubugu, gn_secimdugmesi, gn_baglanti, gn_resim, gn_listegorunum,
  gn_kaydirmacubugu, gn_karmaliste, gn_degerlistesi, gn_izgara, gn_araccubugu,
  gn_sayfakontrol, giysi, src_ps2;

const
  PENCERE_ALTLIMIT_GENISLIK = 110;
  PENCERE_ALTLIMIT_YUKSEKLIK = 26;

type
  TFareKonumu = (fkSolAlt, fkSol, fkSolUst, fkUst, fkSagUst, fkSag, fkSagAlt, fkAlt,
    fkGovde, fkKontrolCubugu);

var
  FareKonumu: TFareKonumu = fkGovde;
  SonFareYatayKoordinat, SonFareDikeyKoordinat: TISayi4;

  // görevin ana penceresinin ortalanmasını sağlar
  AnaPencereyiOrtala: Boolean = False;

{==============================================================================
    pencere kesme çağrılarını yönetir
 ==============================================================================}
function PencereCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  Pencere: TPencere;
  AtaNesneKimlik: TISayi4;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      AtaNesneKimlik := PKimlik(ADegiskenler + 00)^;
      if(AtaNesneKimlik = -1) then
        GN := nil
      else GN := GGNesneler.NesneAl(AtaNesneKimlik);

      Result := PencereGNOlustur(GN, PISayi4(ADegiskenler + 04)^,
      PISayi4(ADegiskenler + 08)^, PISayi4(ADegiskenler + 12)^,
      PISayi4(ADegiskenler + 16)^, PPencereTipi(ADegiskenler + 20)^,
      PKarakterKatari(PSayi4(ADegiskenler + 24)^ + GGorevler.FAktifGrvBelAdr)^,
      PRenk(ADegiskenler + 28)^);
    end;

    ISLEV_GOSTER:
    begin

      Pencere := TPencere(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Pencere.Goster;

      if(Pencere <> nil) then Pencere.EnUsteGetir(Pencere);
    end;

    ISLEV_GIZLE:
    begin

      Pencere := TPencere(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Pencere.Gizle;
    end;

    ISLEV_CIZ:
    begin

      // nesnenin kimlik, tip değerlerini denetle.
      Pencere := TPencere(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Pencere <> nil) then Pencere.Guncelle;
    end;

    // pencere durumunu değiştir
    $010F:
    begin

      // nesnenin kimlik, tip değerlerini denetle.
      Pencere := TPencere(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Pencere <> nil) then
      begin

        Pencere.FPencereDurum := PPencereDurum(ADegiskenler + 04)^;
        Pencere.Guncelle;
      end;
    end;

    // aktif pencereyi al
    $020E:
    begin

      Result := GGNesneler.AktifPencere.Kimlik;
    end;

    // aktif pencereyi yaz
    $020F:
    begin

      Pencere := TPencere(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Pencere <> nil) then Pencere.EnUsteGetir(Pencere);
    end;
  end;
end;

{==============================================================================
  uygulama için pencere nesnesi oluşturur - api
 ==============================================================================}
function PencereGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  APencereTipi: TPencereTipi; ABaslik: string; AGovdeRenk: TRenk): TKimlik;
var
  Pencere: TPencere;
begin

  Pencere := TPencere.Create;

  if(Pencere = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    Pencere.Ozellestir(AAtaNesne, ASol, AUst, AGenislik, AYukseklik, APencereTipi,
      ABaslik, AGovdeRenk);

    Result := Pencere.Kimlik;
  end;
end;

{==============================================================================
  pencere nesnesi oluşturur
 ==============================================================================}
constructor TPencere.Create;
begin

  inherited Create;

  NesneTipi := gntPencere;

  GGNesneler.GorselNesne[FSiraNo] := Self;
end;

{==============================================================================
  pencere nesnesini yok eder
 ==============================================================================}
destructor TPencere.Destroy;
begin

  // pencere kontrol düğmelerini yok et
  if not(FKapatmaDugmesi = nil) then FKapatmaDugmesi.Destroy;
  if not(FBuyutmeDugmesi = nil) then FBuyutmeDugmesi.Destroy;
  if not(FKucultmeDugmesi = nil) then FKucultmeDugmesi.Destroy;

  // pencere ve alt görsel nesneler için ayrılan çizim bellek alanını yok et
  FreeMem(FCizimBellekAdresi, FCizimBellekUzunlugu);
  FCizimBellekAdresi := nil;

  GGNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  pencere nesnesini özelleştirir
 ==============================================================================}
function TPencere.Ozellestir(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  APencereTipi: TPencereTipi; ABaslik: string; AGovdeRenk: TRenk): TISayi4;
var
  Gorev: PGorev;
  MasaUstu: TMasaustu;
  AktifGiysi: TGiysi;
  Genislik, Yukseklik,
  ABSayisi: TISayi4;      // alt bileşen sayısı
  Sol, Ust: TISayi4;
  i: TISayi4;
  AnaPencere: Boolean;
begin

  // ata nesne nil ise üst nesne geçerli masaüstüdür
  if(AAtaNesne = nil) then
    MasaUstu := GGNesneler.AktifMasaustu
  else MasaUstu := TMasaustu(GGNesneler.NesneTipiniKontrolEt(AAtaNesne.Kimlik, gntMasaustu));

  // geçerli masaüstü yok ise hata kodunu ver ve çık
  if(MasaUstu = nil) then Exit(-1);

  AtaNesne := MasaUstu;

  // pencerenin ana pencere olup olmadığını tespit et
  Gorev := GGorevler.GorevBul(GGorevler.FAktifGrv);
  if not(Gorev = nil) and (Gorev^.AktifPencere = nil) then
    AnaPencere := True
  else AnaPencere := False;

  AktifGiysi := GGiysiler.AktifGiysi;

  // pencere limit kontrolleri - başlıksız pencere hariç
  if not(APencereTipi = ptBasliksiz) then
  begin

    // pencere genişliğinin en alt sınır değerinin altında olup olmadığını kontrol et
    if(AGenislik < PENCERE_ALTLIMIT_GENISLIK) then
      Genislik := PENCERE_ALTLIMIT_GENISLIK
    else Genislik := AGenislik + (AktifGiysi.ResimSolGenislik + AktifGiysi.ResimSagGenislik);

    // pencere yüksekliğinin en alt sınır değerinin altında olup olmadığını kontrol et
    if(AYukseklik < PENCERE_ALTLIMIT_YUKSEKLIK) then
      Yukseklik := PENCERE_ALTLIMIT_YUKSEKLIK
    else Yukseklik := AYukseklik + (AktifGiysi.BaslikYukseklik + AktifGiysi.ResimAltYukseklik);
  end
  else
  begin

    Genislik := AGenislik;
    Yukseklik := AYukseklik;
  end;

  Sol := ASol;
  Ust := AUst;
  if not(APencereTipi = ptBasliksiz) then
  begin

    if AnaPencereyiOrtala and AnaPencere then
    begin

      Sol := (MasaUstu.FAtananAlan.Genislik div 2) - (AGenislik div 2);
      Ust := (MasaUstu.FAtananAlan.Yukseklik div 2) - (AYukseklik div 2);
    end;
  end;

  // pencere nesnesi oluştur
  Yapilandir2(ktTuvalNesne, Self, MasaUstu, Sol, Ust, Genislik, Yukseklik, 0,
    AGovdeRenk, AGovdeRenk, 0, ABaslik);

  OlayCagriAdr := @OlaylariIsle;

  Baslik := ABaslik;

  // ana pencerenin aktif penceresini belirle (alt penceresi olan ana pencere için)
  FAtaPencere := TPencere(Gorev^.AktifPencere);

  // görevin aktif masaüstü ve penceresini belirle
  Gorev^.AktifMasaustu := MasaUstu;
  Gorev^.AktifPencere := Self;

  Odaklanilabilir := False;
  Odaklanildi := False;

  FPencereTipi := APencereTipi;
  FPencereDurum := pdNormal;

  FKucultmeDugmesi := nil;
  FBuyutmeDugmesi := nil;
  FKapatmaDugmesi := nil;

  // alt bileşen sayısı
  ABSayisi := 0;

  if(APencereTipi = ptBasliksiz) then
  begin

    // pencere kalınlıkları
    FKalinlik.Sol := 0;
    FKalinlik.Ust := 0;
    FKalinlik.Sag := 0;
    FKalinlik.Alt := 0;

    // pencere çizim alanı
    FCizimAlani.Sol := 0;
    FCizimAlani.Ust := 0;
    FCizimAlani.Sag := FAtananAlan.Genislik - 1;
    FCizimAlani.Alt := FAtananAlan.Yukseklik - 1;
  end
  else
  begin

    // pencere kalınlıkları
    FKalinlik.Sol := AktifGiysi.ResimSolGenislik;
    FKalinlik.Ust := AktifGiysi.BaslikYukseklik;
    FKalinlik.Sag := AktifGiysi.ResimSagGenislik;
    FKalinlik.Alt := AktifGiysi.ResimAltYukseklik;

    // pencere çizim alanı
    FCizimAlani.Sol := 0;
    FCizimAlani.Ust := 0;
    FCizimAlani.Sag := FAtananAlan.Genislik -
      (FKalinlik.Sol + FKalinlik.Sag) - 1;
    FCizimAlani.Alt := FAtananAlan.Yukseklik -
      (FKalinlik.Ust + FKalinlik.Alt) - 1;

    // pencere kontrol düğmeleri
    if(FPencereTipi = ptBoyutlanabilir) then
    begin

      // küçültme düğmesi
      i := AktifGiysi.KucultmeDugmesiSol;
      if(i < 0) then
        i := AGenislik - AktifGiysi.KucultmeDugmesiSol
      else i := ASol + i;

      FKucultmeDugmesi := TResimDugmesi.Create;
      FKucultmeDugmesi.Ozellestir(ktBilesen, Self, i, AktifGiysi.KucultmeDugmesiUst,
        AktifGiysi.KucultmeDugmesiGenislik, AktifGiysi.KucultmeDugmesiYukseklik,
        $10000000 + 13, False);
      FKucultmeDugmesi.OlayYonlAdr := @KontrolDugmesiOlaylariniIsle;
      FKucultmeDugmesi.Goster;

      // büyütme düğmesi
      i := AktifGiysi.BuyutmeDugmesiSol;
      if(i < 0) then
        i := AGenislik - AktifGiysi.BuyutmeDugmesiSol
      else i := ASol + i;

      FBuyutmeDugmesi := TResimDugmesi.Create;
      FBuyutmeDugmesi.Ozellestir(ktBilesen, Self, i, AktifGiysi.BuyutmeDugmesiUst,
        AktifGiysi.BuyutmeDugmesiGenislik, AktifGiysi.BuyutmeDugmesiYukseklik,
        $10000000 + 11, False);
      FBuyutmeDugmesi.OlayYonlAdr := @KontrolDugmesiOlaylariniIsle;
      FBuyutmeDugmesi.Goster;

      // alt bileşen sayısı
      ABSayisi := 2;
    end;

    // kapatma düğmesi
    i := AktifGiysi.KapatmaDugmesiSol;
    if(i < 0) then
      i := AGenislik - AktifGiysi.KapatmaDugmesiSol
    else i := ASol + i;

    FKapatmaDugmesi := TResimDugmesi.Create;
    FKapatmaDugmesi.Ozellestir(ktBilesen, Self, i, AktifGiysi.KapatmaDugmesiUst,
      AktifGiysi.KapatmaDugmesiGenislik, AktifGiysi.KapatmaDugmesiYukseklik,
      $10000000 + 09, False);
    FKapatmaDugmesi.OlayYonlAdr := @KontrolDugmesiOlaylariniIsle;
    FKapatmaDugmesi.Goster;

    // alt bileşen sayısı
    Inc(ABSayisi);
  end;

  // nesne alt bileşen sayısı
  FAltBilesenSayisi := ABSayisi;

  // pencere'ye ait özel çizim alanı mevcut olduğundan dolayı çizim başlangıç
  // sol ve üst değerlerini sıfır olarak ayarla
  FCizimBaslangic.Sol := 0;
  FCizimBaslangic.Ust := 0;

  // penceenin içerisindeki aktif nesne
  FAktifNesne := nil;

  // pencere çizimi için gereken bellek uzunluğu
  FCizimBellekUzunlugu := (FAtananAlan.Genislik * FAtananAlan.Yukseklik * 4);

  // pencere çizimi için bellekte yer ayır
  FCizimBellekAdresi := GetMem(FCizimBellekUzunlugu);

  // geri dönüş değeri
  Result := HATA_YOK;
end;

{==============================================================================
  pencere nesnesini görüntüler
 ==============================================================================}
procedure TPencere.Goster;
begin

  FYenidenCiz := True;

  inherited Goster;
end;

{==============================================================================
  pencere nesnesini gizler
 ==============================================================================}
procedure TPencere.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  pencere nesnesini hizalandırır
 ==============================================================================}
procedure TPencere.Hizala;
begin

end;

{==============================================================================
  pencere nesnesini boyutlandırır
 ==============================================================================}
procedure TPencere.Boyutlandir;
var
  GN: TGorselNesne;
  GNBellekAdresi: PGorselNesne;
  i: TSayi4;
begin

  // kontrol düğmesine sahip olan pencerelerin iç bileşenlerini konumlandır
  if not(FPencereTipi = ptBasliksiz) then

    IcBilesenleriKonumlandir(Self)
  else
  // aksi durumda SADECE hiza alanını belirle
  begin

    FCizimAlani.Sag := FAtananAlan.Genislik - (FKalinlik.Sol + FKalinlik.Sag) - 1;
    FCizimAlani.Alt := FAtananAlan.Yukseklik - (FKalinlik.Ust + FKalinlik.Alt) - 1;

    // alt nesnelerin sınırlanacağı hiza alanını sıfırla
    HizaAlaniniSifirla;
  end;

  // pencere alt nesnelerini yeniden boyutlandır
  if(AltNesneSayisi > 0) then
  begin

    GNBellekAdresi := AltNesneBellekAdresi;

    // ilk oluşturulan alt nesneden son oluşturulan alt nesneye doğru
    // pencerenin alt nesnelerini yeniden boyutlandır
    for i := 0 to AltNesneSayisi - 1 do
    begin

      GN := GNBellekAdresi[i];
      if not(GN = nil) and (GN.Gorunum) then
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
  pencere nesnesini çizer

  önemli: pencere nesnesi çizilmeden önce içsel bileşenler (kapatma, büyütme düğmesi)
    ve diğer alt görsel bileşenler yeniden boyutlandırılmalıdır. Bu sebepten dolayı
    boyutlandırmalara bağlı çizim istekleri için TPencere.Guncelle işlevi çağrılmalıdır
 ==============================================================================}
procedure TPencere.Ciz;
var
  GN: TGorselNesne;
  Olay: TOlay;
  GNBellekAdresi: PGorselNesne;
  AktifGiysi: TGiysi;
  GRSolUst, GRUst, GRSagUst,
  GRSol, GRSag,
  GRSolAlt, GRAlt, GRSagAlt: THamResim;
  CizimAlani: TAlan;
  Sol, Sag, Ust, Alt, i, j: TISayi4;
  Renk, BaslikRengi: TRenk;
  PencereAktif: Boolean;
  RenkBellek: PRenk;
begin

  Boyutlandir;

  // pencerenin kendi değerlerine bağlı (0, 0) koordinatlarını al
  CizimAlani := FCizimAlani;

  CizimAlani.Sag := CizimAlani.Sag + (FKalinlik.Sol + FKalinlik.Sag);
  CizimAlani.Alt := CizimAlani.Alt + (FKalinlik.Ust + FKalinlik.Alt);

  AktifGiysi := GGiysiler.AktifGiysi;

  // pencere tipi başlıksız ise, artan renk ile (eğimli) doldur
  if(FPencereTipi = ptBasliksiz) then

    EgimliDoldur3(Self, CizimAlani, $D0DBFB, $B9C9F9)
  else
  // başlıklı pencere nesnesinin çizimi
  begin

    // aktif veya pasif çizimin belirlenmesi
    PencereAktif := (Self = GGNesneler.AktifPencere);

    if(PencereAktif) then
    begin

      GRSolUst := AktifGiysi.ResimSolUstA;
      GRUst := AktifGiysi.ResimUstA;
      GRSagUst := AktifGiysi.ResimSagUstA;
      GRSol := AktifGiysi.ResimSolA;
      GRSag := AktifGiysi.ResimSagA;
      GRSolAlt := AktifGiysi.ResimSolAltA;
      GRAlt := AktifGiysi.ResimAltA;
      GRSagAlt := AktifGiysi.ResimSagAltA;
      BaslikRengi := AktifGiysi.AktifBaslikYaziRengi;

      // kontrol düğmelerini aktifleştir
      if not(FKucultmeDugmesi = nil) then
        FKucultmeDugmesi.Deger := $10000000 + AktifGiysi.AKucultmeDugmesiRSNo;
      if not(FBuyutmeDugmesi = nil) then
        FBuyutmeDugmesi.Deger := $10000000 + AktifGiysi.ABuyutmeDugmesiRSNo;
      if not(FKapatmaDugmesi = nil) then
        FKapatmaDugmesi.Deger := $10000000 + AktifGiysi.AKapatmaDugmesiRSNo;
    end
    else
    begin

      GRSolUst := AktifGiysi.ResimSolUstP;
      GRUst := AktifGiysi.ResimUstP;
      GRSagUst := AktifGiysi.ResimSagUstP;
      GRSol := AktifGiysi.ResimSolP;
      GRSag := AktifGiysi.ResimSagP;
      GRSolAlt := AktifGiysi.ResimSolAltP;
      GRAlt := AktifGiysi.ResimAltP;
      GRSagAlt := AktifGiysi.ResimSagAltP;
      BaslikRengi := AktifGiysi.PasifBaslikYaziRengi;

      // kontrol düğmelerini pasifleştir
      if not(FKucultmeDugmesi = nil) then
        FKucultmeDugmesi.Deger := $10000000 + AktifGiysi.PKucultmeDugmesiRSNo;
      if not(FBuyutmeDugmesi = nil) then
        FBuyutmeDugmesi.Deger := $10000000 + AktifGiysi.PBuyutmeDugmesiRSNo;
      if not(FKapatmaDugmesi = nil) then
        FKapatmaDugmesi.Deger := $10000000 + AktifGiysi.PKapatmaDugmesiRSNo;
    end;

    // pencerenin giydirilmesi

    // 1. sol üst köşenin giydirilmesi
    RenkBellek := GRSolUst.BellekAdresi;
    for Ust := 0 to GRSolUst.Yukseklik - 1 do
    begin

      for Sol := 0 to GRSolUst.Genislik - 1 do
      begin

        Renk := RenkBellek^;
        if not(Renk = $FFFFFFFF) then PixelYaz(Self, Sol, Ust, Renk);
        Inc(RenkBellek);
      end;
    end;

    // 2. üst yatay bölümün giydirilmesi
    Sol := AktifGiysi.ResimSolUstGenislik;
    Sag := CizimAlani.Sag - AktifGiysi.ResimSagUstGenislik + 1;
    while True do
    begin

      RenkBellek := GRUst.BellekAdresi;

      for i := 0 to GRUst.Yukseklik - 1 do
      begin

        for j := 0 to GRUst.Genislik - 1 do
        begin

          Renk := RenkBellek^;
          if not(Renk = $FFFFFFFF) then PixelYaz(Self, Sol + j, i, Renk);
          Inc(RenkBellek);
        end;
      end;

      Sol := Sol + GRUst.Genislik;
      if(Sol >= Sag) then Break;

      if(Sol + GRUst.Genislik > Sag) then Sol := Sag - GRUst.Genislik;
    end;

    // 3. sağ üst köşenin giydirilmesi
    RenkBellek := GRSagUst.BellekAdresi;
    i := CizimAlani.Sag - GRSagUst.Genislik + 1;
    for Ust := 0 to GRSagUst.Yukseklik - 1 do
    begin

      for Sol := 0 to GRSagUst.Genislik - 1 do
      begin

        Renk := RenkBellek^;
        if not(Renk = $FFFFFFFF) then PixelYaz(Self, i + Sol, Ust, Renk);
        Inc(RenkBellek);
      end;
    end;

    // 4. sol köşenin giydirilmesi
    Ust := AktifGiysi.BaslikYukseklik;
    Alt := CizimAlani.Alt - AktifGiysi.ResimSolAltYukseklik + 1;
    while True do
    begin

      RenkBellek := GRSol.BellekAdresi;

      for i := 0 to GRSol.Yukseklik - 1 do
      begin

        for j := 0 to GRSol.Genislik - 1 do
        begin

          Renk := RenkBellek^;
          if not(Renk = $FFFFFFFF) then PixelYaz(Self, j, Ust + i, Renk);
          Inc(RenkBellek);
        end;
      end;

      Ust := Ust + GRSol.Yukseklik;
      if(Ust >= Alt) then Break;

      if(Ust + GRSol.Yukseklik > Alt) then Ust := (Alt - GRSol.Yukseklik)
    end;

    // 5. sağ köşenin giydirilmesi
    Ust := AktifGiysi.BaslikYukseklik;
    Alt := CizimAlani.Alt - AktifGiysi.ResimSagAltYukseklik + 1;
    Sol := CizimAlani.Sag - AktifGiysi.ResimSagGenislik + 1;
    while True do
    begin

      RenkBellek := GRSag.BellekAdresi;

      for i := 0 to GRSag.Yukseklik - 1 do
      begin

        for j := 0 to GRSag.Genislik - 1 do
        begin

          Renk := RenkBellek^;
          if not(Renk = $FFFFFFFF) then PixelYaz(Self, Sol + j, Ust + i, Renk);
          Inc(RenkBellek);
        end;
      end;

      Ust := Ust + GRSag.Yukseklik;
      if(Ust >= Alt) then Break;

      if(Ust + GRSag.Yukseklik > Alt) then Ust := (Alt - GRSag.Yukseklik);
    end;

    // 6. sol alt köşenin giydirilmesi
    RenkBellek := GRSolAlt.BellekAdresi;
    Ust := CizimAlani.Alt - GRSolAlt.Yukseklik + 1;
    for i := 0 to GRSolAlt.Yukseklik - 1 do
    begin

      for j := 0 to GRSolAlt.Genislik - 1 do
      begin

        Renk := RenkBellek^;
        if not(Renk = $FFFFFFFF) then PixelYaz(Self, j, Ust + i, Renk);
        Inc(RenkBellek);
      end;
    end;

    // 7. alt köşenin giydirilmesi
    Sol := AktifGiysi.ResimSolAltGenislik;
    Ust := CizimAlani.Alt - GRAlt.Yukseklik + 1;
    Sag := CizimAlani.Sag - AktifGiysi.ResimSagAltGenislik + 1;
    while True do
    begin

      RenkBellek := GRAlt.BellekAdresi;

      for i := 0 to GRAlt.Yukseklik - 1 do
      begin

        for j := 0 to GRAlt.Genislik - 1 do
        begin

          Renk := RenkBellek^;
          if not(Renk = $FFFFFFFF) then PixelYaz(Self, Sol + j, Ust + i, Renk);
          Inc(RenkBellek);
        end;
      end;

      Sol := Sol + GRAlt.Genislik;
      if(Sol >= Sag) then Break;

      if(Sol + GRAlt.Genislik > Sag) then Sol := Sag - GRAlt.Genislik;
    end;

    // 8. sağ alt köşenin giydirilmesi
    RenkBellek := GRSagAlt.BellekAdresi;
    Sol := CizimAlani.Sag - GRSagAlt.Genislik + 1;
    Ust := CizimAlani.Alt - GRSagAlt.Yukseklik + 1;
    for i := 0 to GRSagAlt.Yukseklik - 1 do
    begin

      for j := 0 to GRSagAlt.Genislik - 1 do
      begin

        Renk := RenkBellek^;
        if not(Renk = $FFFFFFFF) then PixelYaz(Self, Sol + j, Ust + i, Renk);
        Inc(RenkBellek);
      end;
    end;

    // pencere iç bölüm boyama
    Renk := AktifGiysi.IcDolguRengi;
    if(Renk = $FFFFFFFF) then Renk := FGovdeRenk1;

    DikdortgenDoldur(Self, AktifGiysi.ResimSolGenislik,
      AktifGiysi.BaslikYukseklik, CizimAlani.Sag - AktifGiysi.ResimSagGenislik,
      CizimAlani.Alt - AktifGiysi.ResimAltYukseklik, Renk, Renk);

    // pencere başlığını yaz
    i := AktifGiysi.BaslikYaziSol;
    if(i = -1) then
      i := (FAtananAlan.Genislik div 2) - ((Length(Self.Baslik) * 8) div 2);

    j := AktifGiysi.BaslikYaziUst;
    if(j = -1) then
      j := (AktifGiysi.BaslikYukseklik div 2) - (16 div 2);

    YaziYaz(Self, i, j, Baslik, BaslikRengi);

    if not(FPencereTipi = ptBasliksiz) then
    begin

      if(FPencereTipi = ptBoyutlanabilir) then
      begin

        FKucultmeDugmesi.Ciz;
        FBuyutmeDugmesi.Ciz;
      end;

      FKapatmaDugmesi.Ciz;
    end;
  end;

  GNBellekAdresi := AltNesneBellekAdresi;
  if(AltNesneSayisi > 0) then
  begin

    // ilk oluşturulan alt nesneden son oluşturulan alt nesneye doğru
    // pencerenin alt nesnelerini çiz
    for i := 0 to AltNesneSayisi - 1 do
    begin

      GN := GNBellekAdresi[i];

      if not(GN = nil) and (GN.Gorunum) and ((GN.Kimlik and 1) = 1) then
      begin

        // yeni eklenecek görsel nesne - görsel nesneyi buraya ekle...
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

  FYenidenCiz := True;

  // uygulamaya veya efendi nesneye mesaj gönder
  Olay.Kimlik := Self.Kimlik;
  Olay.Olay := CO_CIZIM;
  Olay.Deger1 := 0;
  Olay.Deger2 := 0;
  if not(OlayYonlAdr = nil) then
    OlayYonlAdr(Self, Olay)
  else GGorevler.OlayEkle(GrvKimlik, Olay);
end;

{==============================================================================
  pencere nesne olaylarını işler
 ==============================================================================}
procedure TPencere.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Pencere: TPencere;
begin

  Pencere := TPencere(AGonderici);
  if(Pencere = nil) then Exit;

  // olayları ilgili işlevlere yönlendir
  case Pencere.FPencereTipi of
    ptBasliksiz       : BasliksizPencereOlaylariniIsle(Pencere, AOlay);
    ptIletisim        : IletisimPencereOlaylariniIsle(Pencere, AOlay);
    ptBoyutlanabilir  : BoyutlanabilirPencereOlaylariniIsle(Pencere, AOlay);
  end;
end;

{==============================================================================
  başlıksız pencere nesne olaylarını işler
 ==============================================================================}
procedure TPencere.BasliksizPencereOlaylariniIsle(APencere: TPencere; AOlay: TOlay);
begin

  // sol tuşa basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // APencere nesnesi aktif değilse aktifleştir
    if(APencere <> GGNesneler.AktifPencere) then EnUsteGetir(APencere);

    // sol tuş basım işlemi olay alanında gerçekleştiyse
    if(APencere.FareNesneOlayAlanindaMi(APencere)) then
    begin

      // fare mesajlarını APencere nesnesine yönlendir
      GGNesneler.OlayYakalamayaBasla(APencere);

      // uygulamaya veya efendi nesneye mesaj gönder
      if not(APencere.OlayYonlAdr = nil) then
        APencere.OlayYonlAdr(APencere, AOlay)
      else GGorevler.OlayEkle(APencere.GrvKimlik, AOlay);
    end;
  end

  // sol tuş bırakım işlemi
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare mesajlarını yakalamayı bırak
    GGNesneler.OlayYakalamayiBirak(APencere);

    // sol tuş bırakım işlemi olay alanında gerçekleştiyse
    if(APencere.FarePencereCizimAlanindaMi(APencere)) then
    begin

      // uygulamaya veya efendi nesneye mesaj gönder
      AOlay.Olay := FO_TIKLAMA;
      if not(APencere.OlayYonlAdr = nil) then
        APencere.OlayYonlAdr(APencere, AOlay)
      else GGorevler.OlayEkle(APencere.GrvKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    if not(APencere.OlayYonlAdr = nil) then
      APencere.OlayYonlAdr(APencere, AOlay)
    else GGorevler.OlayEkle(APencere.GrvKimlik, AOlay);
  end
  else if(AOlay.Olay = FO_HAREKET) then
  begin

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(APencere.OlayYonlAdr = nil) then
      APencere.OlayYonlAdr(APencere, AOlay)
    else GGorevler.OlayEkle(APencere.GrvKimlik, AOlay);
  end
  // diğer olaylar
  else
  begin

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(APencere.OlayYonlAdr = nil) then
      APencere.OlayYonlAdr(APencere, AOlay)
    else GGorevler.OlayEkle(APencere.GrvKimlik, AOlay);
  end;

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := APencere.FareImlec;
end;

{==============================================================================
  iletişim pencere nesne olaylarını işler
 ==============================================================================}
procedure TPencere.IletisimPencereOlaylariniIsle(APencere: TPencere; AOlay: TOlay);
var
  Alan: TAlan;
begin

  // sol tuşa basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // APencere nesnesi aktif değilse aktifleştir
    if(APencere <> GGNesneler.AktifPencere) then EnUsteGetir(APencere);

    // sol tuş basım işlemi olay alanında gerçekleştiyse
    if(APencere.FareNesneOlayAlanindaMi(APencere)) then
    begin

      // fare mesajlarını APencere nesnesine yönlendir
      GGNesneler.OlayYakalamayaBasla(APencere);

      // eğer tıklama pencerenin gövdesinde gerçekleşmişse
      if(FareKonumu = fkGovde) then
      begin

        GFareSurucusu.AktifFareImlec := APencere.FareImlec;

        // uygulamaya veya efendi nesneye mesaj gönder
        if not(APencere.OlayYonlAdr = nil) then
          APencere.OlayYonlAdr(APencere, AOlay)
        else GGorevler.OlayEkle(APencere.GrvKimlik, AOlay);
      end
      else

      // aksi durumda tıklama işlemi yakalama çubuğunda gerçekleşmiştir
      // o zaman pencerenin kenarlıklarını sakla
      begin

        GFareSurucusu.AktifFareImlec := fitBoyutTum;
        SonFareYatayKoordinat := GFareSurucusu.YatayKonum;
        SonFareDikeyKoordinat := GFareSurucusu.DikeyKonum;
      end;
    end else GFareSurucusu.AktifFareImlec := APencere.FareImlec;
  end

  // sol tuş bırakım işlemi
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    GGNesneler.OlayYakalamayiBirak(APencere);

    // taşıma işlemi pencere çizim alanında gerçekleşmişse
    if not(FareKonumu = fkKontrolCubugu) then
    begin

      // bırakma işlemi APencere içerinde gerçekleştiyse
      if(APencere.FarePencereCizimAlanindaMi(APencere)) then
      begin

        GFareSurucusu.AktifFareImlec := APencere.FareImlec;

        // uygulamaya veya efendi nesneye mesaj gönder
        AOlay.Olay := FO_TIKLAMA;
        if not(APencere.OlayYonlAdr = nil) then
          APencere.OlayYonlAdr(APencere, AOlay)
        else GGorevler.OlayEkle(APencere.GrvKimlik, AOlay);

        // uygulamaya veya efendi nesneye mesaj gönder
        AOlay.Olay := FO_SOLTUS_BIRAKILDI;
        if not(APencere.OlayYonlAdr = nil) then
          APencere.OlayYonlAdr(APencere, AOlay)
        else GGorevler.OlayEkle(APencere.GrvKimlik, AOlay);
      end
      else

      // bırakma işlemi APencere dışında gerçekleştiyse
      begin

        { TODO : bırakma işlemi APencere dışında olursa normalde imleç de ilgili
          nesnenin imleçi olur }
        GFareSurucusu.AktifFareImlec := APencere.FareImlec;

        // uygulamaya veya efendi nesneye mesaj gönder
        if not(APencere.OlayYonlAdr = nil) then
          APencere.OlayYonlAdr(APencere, AOlay)
        else GGorevler.OlayEkle(APencere.GrvKimlik, AOlay);
      end;
    end;
  end

  else if(AOlay.Olay = FO_HAREKET) then
  begin

    // fare yakalanmamışsa sadece fare göstergesini güncelle
    if(GGNesneler.YakalananGorselNesne = nil) then
    begin

      if(APencere.FarePencereCizimAlanindaMi(APencere)) then
      begin

        FareKonumu := fkGovde;
        GFareSurucusu.AktifFareImlec := APencere.FareImlec;

        // uygulamaya veya efendi nesneye mesaj gönder
        if not(APencere.OlayYonlAdr = nil) then
          APencere.OlayYonlAdr(APencere, AOlay)
        else GGorevler.OlayEkle(APencere.GrvKimlik, AOlay);
      end
      else
      begin

        FareKonumu := fkKontrolCubugu;
        GFareSurucusu.AktifFareImlec := fitBoyutTum;

        // uygulamaya veya efendi nesneye mesaj gönder
        if not(APencere.OlayYonlAdr = nil) then
          APencere.OlayYonlAdr(APencere, AOlay)
        else GGorevler.OlayEkle(APencere.GrvKimlik, AOlay);
      end;
    end
    else

    // fare yakalanmış olduğu için taşıma işlemlerini gerçekleştir
    begin

      if(FareKonumu = fkKontrolCubugu) then
      begin

        Alan.Sol := GFareSurucusu.YatayKonum - SonFareYatayKoordinat;
        Alan.Ust := GFareSurucusu.DikeyKonum - SonFareDikeyKoordinat;
        Alan.Sag := 0;
        Alan.Alt := 0;

        SonFareYatayKoordinat := GFareSurucusu.YatayKonum;
        SonFareDikeyKoordinat := GFareSurucusu.DikeyKonum;

        APencere.FAtananAlan.Sol := APencere.FAtananAlan.Sol + Alan.Sol;
        APencere.FAtananAlan.Genislik := APencere.FAtananAlan.Genislik + Alan.Sag;
        APencere.FAtananAlan.Ust := APencere.FAtananAlan.Ust + Alan.Ust;
        APencere.FAtananAlan.Yukseklik := APencere.FAtananAlan.Yukseklik + Alan.Alt;

        GFareSurucusu.AktifFareImlec := fitBoyutTum;

        //APencere.Guncelle;
      end
      else
      begin

        // uygulamaya veya efendi nesneye mesaj gönder
        if not(APencere.OlayYonlAdr = nil) then
          APencere.OlayYonlAdr(APencere, AOlay)
        else GGorevler.OlayEkle(APencere.GrvKimlik, AOlay);

        GFareSurucusu.AktifFareImlec := APencere.FareImlec;
      end;
    end;
  end
  // diğer olaylar
  else
  begin

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(APencere.OlayYonlAdr = nil) then
      APencere.OlayYonlAdr(APencere, AOlay)
    else GGorevler.OlayEkle(APencere.GrvKimlik, AOlay);
  end;
end;

{==============================================================================
  boyutlandırılabilir pencere nesne olaylarını işler
 ==============================================================================}
procedure TPencere.BoyutlanabilirPencereOlaylariniIsle(APencere: TPencere; AOlay: TOlay);
var
  Alan: TAlan;
  YenidenCiz: Boolean;
begin

  // sol tuşa basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // APencere nesnesi aktif değilse aktifleştir
    if(APencere <> GGNesneler.AktifPencere) then EnUsteGetir(APencere);

    // fare olaylarını APencere nesnesine yönlendir
    GGNesneler.OlayYakalamayaBasla(APencere);

    // eğer farenin sol tuşu APencere nesnesinin gövdesine tıklanmışsa ...
    if(FareKonumu = fkGovde) then
    begin

      if not(APencere.OlayYonlAdr = nil) then
        APencere.OlayYonlAdr(APencere, AOlay)
      else GGorevler.OlayEkle(APencere.GrvKimlik, AOlay);
    end
    else
    begin

      // aksi durumda taşıma / boyutlandırma işlemi gerçekleştirilecektir.
      // değişken içeriklerini güncelle
      SonFareYatayKoordinat := GFareSurucusu.YatayKonum;
      SonFareDikeyKoordinat := GFareSurucusu.DikeyKonum;
    end;
  end

  // sol tuş bırakma işlemi
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare mesajlarını yakalamayı bırak
    GGNesneler.OlayYakalamayiBirak(APencere);

    // fare bırakma işlemi nesnenin içerisinde mi gerçekleşti ?
    if(FareKonumu = fkGovde) then
    begin

      if(APencere.FarePencereCizimAlanindaMi(APencere)) then
      begin
        // yakalama & bırakma işlemi bu nesnede olduğu için
        // nesneye FO_TIKLAMA mesajı gönder
        AOlay.Olay := FO_TIKLAMA;
        if not(APencere.OlayYonlAdr = nil) then
          APencere.OlayYonlAdr(APencere, AOlay)
        else GGorevler.OlayEkle(APencere.GrvKimlik, AOlay);
      end;

      // nesneye sadece FO_SOLTUS_BIRAKILDI mesajı gönder
      AOlay.Olay := FO_SOLTUS_BIRAKILDI;
      if not(APencere.OlayYonlAdr = nil) then
        APencere.OlayYonlAdr(APencere, AOlay)
      else GGorevler.OlayEkle(APencere.GrvKimlik, AOlay);
    end;
  end

  // fare hareket işlemleri
  else if(AOlay.Olay = FO_HAREKET) then
  begin

    // FO_HAREKET - nesne yakalanmamış
    if(GGNesneler.YakalananGorselNesne = nil) then
    begin

      // fare > sol çizgi kalınlık
      if(AOlay.Deger1 > APencere.FKalinlik.Sol) then
      begin

        // fare < sağ çizgi kalınlık
        if(AOlay.Deger1 < (APencere.FAtananAlan.Genislik - APencere.FKalinlik.Sag)) then
        begin

          // fare < alt çizgi kalınlık
          if(AOlay.Deger2 < (APencere.FAtananAlan.Yukseklik - APencere.FKalinlik.Alt)) then
          begin

            // fare > alt çizgi kalınlık
            // bilgi: üst çizgi kalınlık değeri başlık çubuğu değeri olduğundan dolayı
            // üst çizgi kalınlık değeri olarak alt çizgi kalınlık değeri kullanılmaktadır
            if(AOlay.Deger2 > APencere.FKalinlik.Alt) then
            begin

              // fare > yakalama çubuğu
              // bu değer yakalama çubuğu için kullanılıyor. hata yok
              if(AOlay.Deger2 > APencere.FKalinlik.Ust) then
              begin

                // fare göstergesi APencere gövdesinde
                FareKonumu := fkGovde;
                GFareSurucusu.AktifFareImlec := APencere.FareImlec;

                if not(APencere.OlayYonlAdr = nil) then
                  APencere.OlayYonlAdr(APencere, AOlay)
                else GGorevler.OlayEkle(APencere.GrvKimlik, AOlay);
              end
              else
              begin

                // fare göstergesi yakalama çubuğunda
                FareKonumu := fkKontrolCubugu;
                GFareSurucusu.AktifFareImlec := fitBoyutTum;
              end;
            end
            else
            begin

              // fare göstergesi üst boyutlandırmada
              FareKonumu := fkUst;
              GFareSurucusu.AktifFareImlec := fitBoyutKG;
            end;
          end
          else
          begin

            // fare göstergesi alt boyutlandırmada
            FareKonumu := fkAlt;
            GFareSurucusu.AktifFareImlec := fitBoyutKG;
          end;
        end
        else
        // sağ - alt / üst / orta (sağ) kontrolü
        begin

          // bilgi: APencere^.FKalinlik.Alt değeri aslında APencere^.FKalinlik.Ust değeri olmalıdır
          // fakat APencere^.FKalinlik.Ust değeri başlık kalınlığı olarak kullanılmaktadır
          if(AOlay.Deger2 < APencere.FKalinlik.Alt) then
          begin

            // fare göstergesi sağ & üst boyutlandırmada
            FareKonumu := fkSagUst;
            GFareSurucusu.AktifFareImlec := fitBoyutKDGB;
          end
          else if(AOlay.Deger2 > (APencere.FAtananAlan.Yukseklik - APencere.FKalinlik.Alt)) then
          begin

            // fare göstergesi sağ & alt boyutlandırmada
            FareKonumu := fkSagAlt;
            GFareSurucusu.AktifFareImlec := fitBoyutKBGD;
          end
          else
          begin

            // fare göstergesi sağ kısım boyutlandırmada
            FareKonumu := fkSag;
            GFareSurucusu.AktifFareImlec := fitBoyutBD;
          end;
        end;
      end
      else
      // sol - alt / üst / orta (sol) kontrolü
      begin

        if(AOlay.Deger2 < APencere.FKalinlik.Alt) then
        begin

          // fare göstergesi üst & sol kısım boyutlandırmada
          FareKonumu := fkSolUst;
          GFareSurucusu.AktifFareImlec := fitBoyutKBGD;
        end
        else if(AOlay.Deger2 > (APencere.FAtananAlan.Yukseklik - APencere.FKalinlik.Alt)) then
        begin

          // fare göstergesi alt & sol kısım boyutlandırmada
          FareKonumu := fkSolAlt;
          GFareSurucusu.AktifFareImlec := fitBoyutKDGB;
        end
        else
        begin

          // fare göstergesi sol kısım boyutlandırmada
          FareKonumu := fkSol;
          GFareSurucusu.AktifFareImlec := fitBoyutBD;
        end;
      end;
    end
    else
    // FO_HAREKET - nesne yakalanmış - taşıma, boyutlandırma
    begin

      YenidenCiz := True;

      if(FareKonumu = fkGovde) then
      begin

        if not(APencere.OlayYonlAdr = nil) then
          APencere.OlayYonlAdr(APencere, AOlay)
        else GGorevler.OlayEkle(APencere.GrvKimlik, AOlay);
      end
      else
      begin

        Alan.Sol := 0;
        Alan.Ust := 0;
        Alan.Sag := 0;
        Alan.Alt := 0;

        if(FareKonumu = fkSolUst) then
        begin

          Alan.Sol := GFareSurucusu.YatayKonum - SonFareYatayKoordinat;
          Alan.Ust := GFareSurucusu.DikeyKonum - SonFareDikeyKoordinat;
          Alan.Sag := -Alan.Sol;
          Alan.Alt := -Alan.Ust;
        end
        else if(FareKonumu = fkSol) then
        begin

          Alan.Sol := GFareSurucusu.YatayKonum - SonFareYatayKoordinat;
          Alan.Ust := 0;
          Alan.Sag := -GFareSurucusu.YatayKonum - SonFareYatayKoordinat;
          Alan.Alt := 0;
        end
        else if(FareKonumu = fkSolAlt) then
        begin

          Alan.Sol := GFareSurucusu.YatayKonum - SonFareYatayKoordinat;
          Alan.Ust := 0;
          Alan.Sag := -Alan.Sol;
          Alan.Alt := GFareSurucusu.DikeyKonum - SonFareDikeyKoordinat;
        end
        else if(FareKonumu = fkAlt) then
        begin

          Alan.Sol := 0;
          Alan.Ust := 0;
          Alan.Sag := 0;
          Alan.Alt := GFareSurucusu.DikeyKonum - SonFareDikeyKoordinat;
        end
        else if(FareKonumu = fkSagAlt) then
        begin

          Alan.Sol := 0;
          Alan.Ust := 0;
          Alan.Sag := GFareSurucusu.YatayKonum - SonFareYatayKoordinat;
          Alan.Alt := GFareSurucusu.DikeyKonum - SonFareDikeyKoordinat;
        end
        else if(FareKonumu = fkSag) then
        begin

          Alan.Sol := 0;
          Alan.Ust := 0;
          Alan.Sag := GFareSurucusu.YatayKonum - SonFareYatayKoordinat;
          Alan.Alt := 0;
        end
        else if(FareKonumu = fkSagUst) then
        begin

          Alan.Sol := 0;
          Alan.Ust := GFareSurucusu.DikeyKonum - SonFareDikeyKoordinat;
          Alan.Sag := GFareSurucusu.YatayKonum - SonFareYatayKoordinat;
          Alan.Alt := -Alan.Ust;
        end
        else if(FareKonumu = fkUst) then
        begin

          Alan.Sol := 0;
          Alan.Ust := GFareSurucusu.DikeyKonum - SonFareDikeyKoordinat;
          Alan.Sag := 0;
          Alan.Alt := -Alan.Ust;
        end
        else if(FareKonumu = fkKontrolCubugu) then
        begin

          Alan.Sol := GFareSurucusu.YatayKonum - SonFareYatayKoordinat;
          Alan.Ust := GFareSurucusu.DikeyKonum - SonFareDikeyKoordinat;
          Alan.Sag := 0;
          Alan.Alt := 0;
          YenidenCiz := False;
        end;

        SonFareYatayKoordinat := GFareSurucusu.YatayKonum;
        SonFareDikeyKoordinat := GFareSurucusu.DikeyKonum;

        APencere.FAtananAlan.Sol := APencere.FAtananAlan.Sol + Alan.Sol;
        APencere.FAtananAlan.Genislik := APencere.FAtananAlan.Genislik + Alan.Sag;
        APencere.FAtananAlan.Ust := APencere.FAtananAlan.Ust + Alan.Ust;
        APencere.FAtananAlan.Yukseklik := APencere.FAtananAlan.Yukseklik + Alan.Alt;

        APencere.FCizimAlani.Sol := 0;
        APencere.FCizimAlani.Ust := 0;
        APencere.FCizimAlani.Sag := APencere.FAtananAlan.Genislik - 1;
        APencere.FCizimAlani.Alt := APencere.FAtananAlan.Yukseklik - 1;

        if(YenidenCiz) then
        begin

          //if(APencere^.FCiziliyor) then Exit;

          APencere.Boyutlandir;

          // çizim için ayrılan belleği yok et ve yeni bellek ayır
          { TODO : ileride çizimlerin daha hızlı olması için APencere küçülmesi için bellek ayrılmayabilir }
          FreeMem(APencere.FCizimBellekAdresi, APencere.FCizimBellekUzunlugu);

          APencere.FCizimBellekUzunlugu := (APencere.FAtananAlan.Genislik * APencere.FAtananAlan.Yukseklik * 4);
          APencere.FCizimBellekAdresi := GetMem(APencere.FCizimBellekUzunlugu);

          APencere.Ciz;
        end;
      end;
    end;
  end
  // diğer olaylar
  else
  begin

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(APencere.OlayYonlAdr = nil) then
      APencere.OlayYonlAdr(APencere, AOlay)
    else GGorevler.OlayEkle(APencere.GrvKimlik, AOlay);
  end;
end;

{==============================================================================
  pencere nesnesi ve alt nesnelerini günceller
  önemli: tüm alt nesneler çizim istekleri için bu işlevi (TPencere.Guncelle) çağırmalıdır
 ==============================================================================}
procedure TPencere.Guncelle;
begin

  FYenidenCiz := True;

  Boyutlandir;

  Ciz;
end;

{==============================================================================
  belirtilen pencere nesnesini en üste getirir ve yeniden çizer
 ==============================================================================}
procedure TPencere.EnUsteGetir(APencere: TPencere);
var
  GN: TGorselNesne;
  Masaustu: TMasaustu;
  BirOncekiPencere: TPencere;
  GNBellekAdresi: PGorselNesne;
  i, j: TISayi4;
begin

{------------------------------------------------------------------------------
  Sıralama            0   1   2
                    +---+---+---+
  Nesne Kimlikleri  | 1 | 2 | 3 |
                    +-+-+---+-+-+
                      |       +----- en üst nesne
                      +------------- en alt nesne
-------------------------------------------------------------------------------}

  // aktif masaüstünü al
  Masaustu := GGNesneler.AktifMasaustu;

  // nesnenin alt nesne sayısı var ise
  if(Masaustu.AltNesneSayisi > 1) then
  begin

    // masaüstünün alt nesne bellek değerini al
    GNBellekAdresi := Masaustu.AltNesneBellekAdresi;

    BirOncekiPencere := TPencere(GNBellekAdresi[Masaustu.AltNesneSayisi - 1]);

    // alt nesneler içerisinde pencere nesnesini ara
    for i := (Masaustu.AltNesneSayisi - 1) downto 0 do
    begin

      if(TPencere(GNBellekAdresi[i]) = APencere) then Break;
    end;

    // eğer pencere nesnesi en üstte değil ise
    if(i <> Masaustu.AltNesneSayisi - 1) then
    begin

      // pencere nesnesini masaüstü nesne belleğinde en üste getir
      for j := i to Masaustu.AltNesneSayisi - 2 do
      begin

        GN := GNBellekAdresi[j + 0];
        GNBellekAdresi[j + 0] := GNBellekAdresi[j + 1];
        GNBellekAdresi[j + 1] := GN;
      end;
    end;

    // pencere en üstte olsa da olmasa da aktif pencere olarak tanımla
    // not: pencere en üstte olup görüntülenmiş olmayabilir
    GGNesneler.AktifPencere := APencere;

    // bir önceki pencere pasif olacağı için yeniden çiz
    if(BirOncekiPencere.Gorunum) then BirOncekiPencere.Guncelle;

    // aktif pencereyi yeniden çiz
    GGNesneler.AktifPencere.Guncelle;

    // görev bayrak değerini artır
    Inc(GGorevler.FGorevBayrakDegeri);
  end;
end;

{==============================================================================
  fare göstergesinin pencere nesnesinin gövde (çizim alanı) içerisinde
  olup olmadığını kontrol eder
 ==============================================================================}
function TPencere.FarePencereCizimAlanindaMi(APencere: TPencere): Boolean;
var
  Alan: TAlan;
begin

  Alan.Sol := APencere.FAtananAlan.Sol + APencere.FKalinlik.Sol;
  Alan.Ust := APencere.FAtananAlan.Ust + APencere.FKalinlik.Ust;
  Alan.Sag := Alan.Sol + (APencere.FAtananAlan.Genislik + APencere.FKalinlik.Sag);
  Alan.Alt := Alan.Ust + (APencere.FAtananAlan.Yukseklik + APencere.FKalinlik.Alt);

  // öndeğer dönüş değeri
  Result := False;

  // fare belirtilen koordinatlar içerisinde mi ?
  if(GFareSurucusu.YatayKonum < Alan.Sol) then Exit;
  if(GFareSurucusu.YatayKonum > Alan.Sag) then Exit;
  if(GFareSurucusu.DikeyKonum < Alan.Ust) then Exit;
  if(GFareSurucusu.DikeyKonum > Alan.Alt) then Exit;

  Result := True;
end;

{==============================================================================
  pencere nesnesini yeniden boyutlandırır iç bileşenlerini konumlandırır
 ==============================================================================}
procedure TPencere.IcBilesenleriKonumlandir(var APencere: TPencere);
var
  AktifGiysi: TGiysi;
  i: TISayi4;
begin

  APencere.FCizimAlani.Sag := APencere.FAtananAlan.Genislik -
    (APencere.FKalinlik.Sol + APencere.FKalinlik.Sag) - 1;
  APencere.FCizimAlani.Alt := APencere.FAtananAlan.Yukseklik -
    (APencere.FKalinlik.Ust + APencere.FKalinlik.Alt) - 1;

  // alt nesnelerin sınırlanacağı hiza alanını sıfırla
  APencere.HizaAlaniniSifirla;

  AktifGiysi := GGiysiler.AktifGiysi;

  if(APencere.FPencereTipi = ptBoyutlanabilir) then
  begin

    i := AktifGiysi.KucultmeDugmesiSol;
    if(i < 0) then
      i := APencere.FAtananAlan.Genislik + AktifGiysi.KucultmeDugmesiSol;
    APencere.FKucultmeDugmesi.FAtananAlan.Sol := i;
    APencere.FKucultmeDugmesi.FAtananAlan.Ust := AktifGiysi.KucultmeDugmesiUst;

    i := AktifGiysi.BuyutmeDugmesiSol;
    if(i < 0) then
      i := APencere.FAtananAlan.Genislik + AktifGiysi.BuyutmeDugmesiSol;
    APencere.FBuyutmeDugmesi.FAtananAlan.Sol := i;
    APencere.FBuyutmeDugmesi.FAtananAlan.Ust := AktifGiysi.BuyutmeDugmesiUst;

    i := AktifGiysi.KapatmaDugmesiSol;
    if(i < 0) then
      i := APencere.FAtananAlan.Genislik + AktifGiysi.KapatmaDugmesiSol;
    APencere.FKapatmaDugmesi.FAtananAlan.Sol := i;
    APencere.FKapatmaDugmesi.FAtananAlan.Ust := AktifGiysi.KapatmaDugmesiUst;

    APencere.FKucultmeDugmesi.FCizimBaslangic.Sol := APencere.FCizimBaslangic.Sol + APencere.FKucultmeDugmesi.FAtananAlan.Sol;
    APencere.FKucultmeDugmesi.FCizimBaslangic.Ust := APencere.FCizimBaslangic.Ust + APencere.FKucultmeDugmesi.FAtananAlan.Ust;
    APencere.FBuyutmeDugmesi.FCizimBaslangic.Sol := APencere.FCizimBaslangic.Sol + APencere.FBuyutmeDugmesi.FAtananAlan.Sol;
    APencere.FBuyutmeDugmesi.FCizimBaslangic.Ust := APencere.FCizimBaslangic.Ust + APencere.FBuyutmeDugmesi.FAtananAlan.Ust;
    APencere.FKapatmaDugmesi.FCizimBaslangic.Sol := APencere.FCizimBaslangic.Sol + APencere.FKapatmaDugmesi.FAtananAlan.Sol;
    APencere.FKapatmaDugmesi.FCizimBaslangic.Ust := APencere.FCizimBaslangic.Ust + APencere.FKapatmaDugmesi.FAtananAlan.Ust;
  end
  else if(APencere.FPencereTipi = ptIletisim) then
  begin

    i := AktifGiysi.KapatmaDugmesiSol;
    if(i < 0) then
      i := APencere.FAtananAlan.Genislik + AktifGiysi.KapatmaDugmesiSol;
    APencere.FKapatmaDugmesi.FAtananAlan.Sol := i;
    APencere.FKapatmaDugmesi.FAtananAlan.Ust := AktifGiysi.KapatmaDugmesiUst;

    APencere.FKapatmaDugmesi.FCizimBaslangic.Sol := APencere.FCizimBaslangic.Sol + APencere.FKapatmaDugmesi.FAtananAlan.Sol;
    APencere.FKapatmaDugmesi.FCizimBaslangic.Ust := APencere.FCizimBaslangic.Ust + APencere.FKapatmaDugmesi.FAtananAlan.Ust;
  end;
end;

procedure TPencere.KontrolDugmesiOlaylariniIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  ResimDugmesi: TResimDugmesi;
  Pencere: TPencere;
  Olay: TOlay;
begin

  if(AOlay.Olay = FO_TIKLAMA) then
  begin

    ResimDugmesi := TResimDugmesi(AGonderici);
    if(ResimDugmesi = nil) then Exit;

    Pencere := TPencere(ResimDugmesi.AtaNesne);

    if(ResimDugmesi.Kimlik = Pencere.FKucultmeDugmesi.Kimlik) then
      Pencere.FPencereDurum := pdKucultuldu
    else if(ResimDugmesi.Kimlik = Pencere.FBuyutmeDugmesi.Kimlik) then
    begin

      // pencereyi ekranı dolduracak şekilde yeniden boyutlandır
      Pencere.FAtananAlan.Sol := 0;
      Pencere.FAtananAlan.Ust := 0;
      Pencere.FAtananAlan.Genislik := GGNesneler.AktifMasaustu.FCizimAlani.Genislik;
      Pencere.FAtananAlan.Yukseklik := GGNesneler.AktifMasaustu.FCizimAlani.Yukseklik - 40;

      // yeni çizim bellek değerlerini güncelle
      FreeMem(Pencere.FCizimBellekAdresi, Pencere.FCizimBellekUzunlugu);

      Pencere.FCizimBellekUzunlugu := (Pencere.FAtananAlan.Genislik * Pencere.FAtananAlan.Yukseklik * 4);
      Pencere.FCizimBellekAdresi := GetMem(Pencere.FCizimBellekUzunlugu);

      Pencere.Guncelle;
    end
    else if(ResimDugmesi.Kimlik = Pencere.FKapatmaDugmesi.Kimlik) then
    begin

      // uygulamaya veya efendi nesneye mesaj gönder
      Olay.Kimlik := Pencere.Kimlik;
      Olay.Olay := CO_SONLANDIR;
      Olay.Deger1 := 0;
      Olay.Deger2 := 0;
      if not(Pencere.OlayYonlAdr = nil) then
        Pencere.OlayYonlAdr(Pencere, Olay)
      else GGorevler.OlayEkle(Pencere.GrvKimlik, Olay);
    end;
  end;
end;

end.
