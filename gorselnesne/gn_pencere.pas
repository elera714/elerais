{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: gn_pencere.pas
  Dosya Ýþlevi: pencere (TForm) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 10/06/2025

  Önemli Bilgiler:

    TPencere'nin alt nesnelerinden biri yeniden kýsmi olarak (TEtiket nesnesi gibi)
      çizilmek istendiðinde mutlaka üst nesne olan TPencere.Guncelle iþlevini çaðýrmalýdýr.
      Böylece pencere çizim tasarým gereði pencere öncelikle kendini çizecek daha
      sonra ise alt nesnelerinin çizilmesi için alt nesnenin Ciz iþlevini çaðýracaktýr.
      Bu durum en son geliþtirilen, pencerelerin bellekten belleðe aktarýlmasý ve
      eðimli dolgu (gradient) çizim iþlevleri için gereklidir

 ==============================================================================}
{$mode objfpc}
unit gn_pencere;

interface

uses gorselnesne, paylasim, gn_panel, gn_dugme, gn_resimdugmesi;

type
  PPencere = ^TPencere;
  TPencere = object(TPanel)
  private
    procedure BasliksizPencereOlaylariniIsle(APencere: PPencere; AOlay: TOlay);
    procedure IletisimPencereOlaylariniIsle(APencere: PPencere; AOlay: TOlay);
    procedure BoyutlanabilirPencereOlaylariniIsle(APencere: PPencere; AOlay: TOlay);
    function FarePencereCizimAlanindaMi(APencere: PPencere): Boolean;
    procedure IcBilesenleriKonumlandir(var APencere: PPencere);
    procedure KontrolDugmesiOlaylariniIsle(AGonderici: PGorselNesne; AOlay: TOlay);
  public
    FAtaPencere: PPencere;          // pencerenin (varsa) bir üst penceresi
    FPencereDurum: TPencereDurum;
    FPencereTipi: TPencereTipi;
    FAktifNesne: PGorselNesne;
    FKucultmeDugmesi, FBuyutmeDugmesi, FKapatmaDugmesi: PResimDugmesi;
    function Olustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
      APencereTipi: TPencereTipi; ABaslik: string; AGovdeRenk: TRenk): PPencere;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Boyutlandir;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    procedure Guncelle;
    procedure EnUsteGetir(APencere: PPencere);
  end;

function PencereCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  APencereTipi: TPencereTipi; ABaslik: string; AGovdeRenk: TRenk): TKimlik;

var
  GAktifPencere: PPencere = nil;        // aktif olan pencere

implementation

uses genel, gorev, gn_islevler, gn_masaustu, gn_gucdugmesi, gn_listekutusu,
  gn_defter, gn_islemgostergesi, gn_onaykutusu, gn_giriskutusu, gn_degerdugmesi,
  gn_etiket, gn_durumcubugu, gn_secimdugmesi, gn_baglanti, gn_resim, gn_listegorunum,
  gn_kaydirmacubugu, gn_karmaliste, gn_degerlistesi, gn_izgara, gn_araccubugu,
  gn_renksecici, gn_sayfakontrol, temelgorselnesne, sistemmesaj;

const
  PENCERE_ALTLIMIT_GENISLIK = 110;
  PENCERE_ALTLIMIT_YUKSEKLIK = 26;

type
  TFareKonumu = (fkSolAlt, fkSol, fkSolUst, fkUst, fkSagUst, fkSag, fkSagAlt, fkAlt,
    fkGovde, fkKontrolCubugu);

var
  FareKonumu: TFareKonumu = fkGovde;
  SonFareYatayKoordinat, SonFareDikeyKoordinat: TISayi4;

{==============================================================================
    pencere kesme çaðrýlarýný yönetir
 ==============================================================================}
function PencereCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne;
  Pencere: PPencere;
  AtaNesneKimlik: TISayi4;
begin

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      AtaNesneKimlik := PKimlik(ADegiskenler + 00)^;
      if(AtaNesneKimlik = -1) then
        GN := nil
      else GN := GorselNesneler0.NesneAl(AtaNesneKimlik);

      Result := NesneOlustur(GN, PISayi4(ADegiskenler + 04)^,
      PISayi4(ADegiskenler + 08)^, PISayi4(ADegiskenler + 12)^,
      PISayi4(ADegiskenler + 16)^, PPencereTipi(ADegiskenler + 20)^,
      PKarakterKatari(PSayi4(ADegiskenler + 24)^ + FAktifGorevBellekAdresi)^,
      PRenk(ADegiskenler + 28)^);
    end;

    ISLEV_GOSTER:
    begin

      Pencere := PPencere(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      Pencere^.Goster;
    end;

    ISLEV_GIZLE:
    begin

      Pencere := PPencere(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      Pencere^.Gizle;
    end;

    ISLEV_CIZ:
    begin

      // nesnenin kimlik, tip deðerlerini denetle.
      Pencere := PPencere(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Pencere <> nil) then Pencere^.Guncelle;
    end;

    // pencere durumunu deðiþtir
    $010F:
    begin

      // nesnenin kimlik, tip deðerlerini denetle.
      Pencere := PPencere(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Pencere <> nil) then
      begin

        Pencere^.FPencereDurum := TPencereDurum(PKimlik(ADegiskenler + 04)^);
        Pencere^.Guncelle;

        //PencereleriYenidenCiz;

        //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Pencere: %d', [Pencere^.Kimlik]);
        //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Durum: %d', [Ord(Pencere^.FPencereDurum)]);
      end;
    end;

    // aktif pencereyi al
    $020E:
    begin

      Result := GAktifPencere^.Kimlik;
    end;

    // aktif pencereyi yaz
    $020F:
    begin

      Pencere := PPencere(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      if(Pencere <> nil) then Pencere^.EnUsteGetir(Pencere);
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  pencere nesnesini oluþturur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  APencereTipi: TPencereTipi; ABaslik: string; AGovdeRenk: TRenk): TKimlik;
var
  Pencere: PPencere;
begin

  Pencere := Pencere^.Olustur(AAtaNesne, ASol, AUst, AGenislik, AYukseklik,
    APencereTipi, ABaslik, AGovdeRenk);

  if(Pencere = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := Pencere^.Kimlik;
end;

{==============================================================================
  pencere nesnesini oluþturur
 ==============================================================================}
function TPencere.Olustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  APencereTipi: TPencereTipi; ABaslik: string; AGovdeRenk: TRenk): PPencere;
var
  Gorev: PGorev = nil;
  Masaustu: PMasaustu = nil;
  Pencere: PPencere = nil;
  Genislik, Yukseklik: TSayi4;
  Sol, Ust: TISayi4;
  i: TISayi4;
  AnaPencere: Boolean;
begin

  // ata nesne nil ise üst nesne geçerli masaüstüdür
  if(AAtaNesne = nil) then

    Masaustu := GAktifMasaustu
  else Masaustu := PMasaustu(GorselNesneler0.NesneTipiniKontrolEt(AAtaNesne^.Kimlik, gntMasaustu));

  // geçerli masaüstü yok ise hata kodunu ver ve çýk
  if(Masaustu = nil) then Exit(nil);

  // pencerenin ana pencere olup olmadýðýný tespit et
  Gorev := Gorevler0.GorevBul(FAktifGorev);
  if not(Gorev = nil) and (Gorev^.AktifPencere = nil) then
    AnaPencere := True
  else AnaPencere := False;

  // pencere limit kontrolleri - baþlýksýz pencere hariç
  if not(APencereTipi = ptBasliksiz) then
  begin

    // pencere geniþliðinin en alt sýnýr deðerinin altýnda olup olmadýðýný kontrol et
    if(AGenislik < PENCERE_ALTLIMIT_GENISLIK) then
      Genislik := PENCERE_ALTLIMIT_GENISLIK
    else Genislik := AGenislik + (AktifGiysi.ResimSolGenislik + AktifGiysi.ResimSagGenislik);

    // pencere yüksekliðinin en alt sýnýr deðerinin altýnda olup olmadýðýný kontrol et
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

      Sol := (Masaustu^.FBoyut.Genislik div 2) - (AGenislik div 2);
      Ust := (Masaustu^.FBoyut.Yukseklik div 2) - (AYukseklik div 2);
    end;
  end;

  // pencere nesnesi oluþtur
  Pencere := PPencere(inherited Olustur(ktTuvalNesne, Masaustu, Sol, Ust, Genislik,
    Yukseklik, 0, AGovdeRenk, AGovdeRenk, 0, ABaslik));

  Pencere^.NesneTipi := gntPencere;

  Pencere^.Baslik := ABaslik;

  Pencere^.FTuvalNesne := Pencere;

  // ana pencerenin aktif penceresini belirle (alt penceresi olan ana pencere için)
  Pencere^.FAtaPencere := PPencere(Gorev^.AktifPencere);

  // görevin aktif masaüstü ve penceresini belirle
  Gorev^.AktifMasaustu := Masaustu;
  Gorev^.AktifPencere := PObject(Pencere);

  Pencere^.Odaklanilabilir := False;
  Pencere^.Odaklanildi := False;

  Pencere^.OlayCagriAdresi := @OlaylariIsle;

  Pencere^.FPencereTipi := APencereTipi;
  Pencere^.FPencereDurum := pdNormal;

  Pencere^.FKucultmeDugmesi := nil;
  Pencere^.FBuyutmeDugmesi := nil;
  Pencere^.FKapatmaDugmesi := nil;

  if(APencereTipi = ptBasliksiz) then
  begin

    // pencere kalýnlýklarý
    Pencere^.FKalinlik.Sol := 0;
    Pencere^.FKalinlik.Ust := 0;
    Pencere^.FKalinlik.Sag := 0;
    Pencere^.FKalinlik.Alt := 0;

    // pencere çizim alaný
    Pencere^.FCizimAlan.Sol := 0;
    Pencere^.FCizimAlan.Ust := 0;
    Pencere^.FCizimAlan.Sag := Pencere^.FBoyut.Genislik - 1;
    Pencere^.FCizimAlan.Alt := Pencere^.FBoyut.Yukseklik - 1;
  end
  else
  begin

    // pencere kalýnlýklarý
    Pencere^.FKalinlik.Sol := AktifGiysi.ResimSolGenislik;
    Pencere^.FKalinlik.Ust := AktifGiysi.BaslikYukseklik;
    Pencere^.FKalinlik.Sag := AktifGiysi.ResimSagGenislik;
    Pencere^.FKalinlik.Alt := AktifGiysi.ResimAltYukseklik;

    // pencere çizim alaný
    Pencere^.FCizimAlan.Sol := 0;
    Pencere^.FCizimAlan.Ust := 0;
    Pencere^.FCizimAlan.Sag := Pencere^.FBoyut.Genislik -
      (Pencere^.FKalinlik.Sol + Pencere^.FKalinlik.Sag) - 1;
    Pencere^.FCizimAlan.Alt := Pencere^.FBoyut.Yukseklik -
      (Pencere^.FKalinlik.Ust + Pencere^.FKalinlik.Alt) - 1;

    // pencere kontrol düðmeleri
    if(Pencere^.FPencereTipi = ptBoyutlanabilir) then
    begin

      // küçültme düðmesi
      i := AktifGiysi.KucultmeDugmesiSol;
      if(i < 0) then
        i := AGenislik - AktifGiysi.KucultmeDugmesiSol
      else i := ASol + i;
      Pencere^.FKucultmeDugmesi := FKucultmeDugmesi^.Olustur(ktBilesen, Pencere,
        i, AktifGiysi.KucultmeDugmesiUst, AktifGiysi.KucultmeDugmesiGenislik,
        AktifGiysi.KucultmeDugmesiYukseklik, $20000000 + 4, False);
      Pencere^.FKucultmeDugmesi^.OlayYonlendirmeAdresi := @KontrolDugmesiOlaylariniIsle;
      Pencere^.FKucultmeDugmesi^.Goster;

      // büyütme düðmesi
      i := AktifGiysi.BuyutmeDugmesiSol;
      if(i < 0) then
        i := AGenislik - AktifGiysi.BuyutmeDugmesiSol
      else i := ASol + i;
      Pencere^.FBuyutmeDugmesi := FBuyutmeDugmesi^.Olustur(ktBilesen, Pencere,
        i, AktifGiysi.BuyutmeDugmesiUst, AktifGiysi.BuyutmeDugmesiGenislik,
        AktifGiysi.BuyutmeDugmesiYukseklik, $20000000 + 2, False);
      Pencere^.FBuyutmeDugmesi^.OlayYonlendirmeAdresi := @KontrolDugmesiOlaylariniIsle;
      Pencere^.FBuyutmeDugmesi^.Goster;
    end;

    // kapatma düðmesi
    i := AktifGiysi.KapatmaDugmesiSol;
    if(i < 0) then
      i := AGenislik - AktifGiysi.KapatmaDugmesiSol
    else i := ASol + i;
    Pencere^.FKapatmaDugmesi := FKapatmaDugmesi^.Olustur(ktBilesen, Pencere,
      i, AktifGiysi.KapatmaDugmesiUst, AktifGiysi.KapatmaDugmesiGenislik,
      AktifGiysi.KapatmaDugmesiYukseklik, $20000000 + 0, False);
    Pencere^.FKapatmaDugmesi^.OlayYonlendirmeAdresi := @KontrolDugmesiOlaylariniIsle;
    Pencere^.FKapatmaDugmesi^.Goster;
  end;

  // pencere'ye ait özel çizim alaný mevcut olduðundan dolayý çizim baþlangýç
  // sol ve üst deðerlerini sýfýr olarak ayarla
  Pencere^.FCizimBaslangic.Sol := 0;
  Pencere^.FCizimBaslangic.Ust := 0;

  // penceenin içerisindeki aktif nesne
  Pencere^.FAktifNesne := nil;

  // pencere çizimi için gereken bellek uzunluðu
  Pencere^.FCizimBellekUzunlugu := (Pencere^.FBoyut.Genislik *
    Pencere^.FBoyut.Yukseklik * 4);

  // pencere çizimi için bellekte yer ayýr
  Pencere^.FCizimBellekAdresi := GetMem(Pencere^.FCizimBellekUzunlugu);
  if(Pencere^.FCizimBellekAdresi = nil) then
  begin

    // hata olmasý durumunda nesneyi yok et ve iþlevden çýk
    GorselNesneler0.YokEt(Pencere^.Kimlik);
    Result := nil;
    Exit;
  end;

  // nesne adresini geri döndür
  Result := Pencere;
end;

{==============================================================================
  pencere nesnesini görüntüler
 ==============================================================================}
procedure TPencere.Goster;
var
  Pencere: PPencere;
begin

  Pencere := PPencere(GorselNesneler0.NesneAl(Kimlik));
  if(Pencere = nil) then Exit;

  inherited Goster;

  // pencere nesnesinin üst nesnesi olan masaüstü görünür ise masaüstü nesnesini
  // en üste getir ve yeniden çiz
  if(Pencere^.AtaNesne^.Gorunum) then Pencere^.EnUsteGetir(Pencere);
end;

{==============================================================================
  pencere nesnesini gizler
 ==============================================================================}
procedure TPencere.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  pencere nesnesini hizalandýrýr
 ==============================================================================}
procedure TPencere.Hizala;
begin

end;

{==============================================================================
  pencere nesnesini boyutlandýrýr
 ==============================================================================}
procedure TPencere.Boyutlandir;
var
  Pencere: PPencere;
  GorunurNesne: PGorselNesne;
  AltNesneler: PPGorselNesne;
  i: TSayi4;
begin

  Pencere := PPencere(GorselNesneler0.NesneAl(Kimlik));
  if(Pencere = nil) then Exit;

  // kontrol düðmesine sahip olan pencerelerin iç bileþenlerini konumlandýr
  if not(Pencere^.FPencereTipi = ptBasliksiz) then

    IcBilesenleriKonumlandir(Pencere)
  else
  // aksi durumda SADECE hiza alanýný belirle
  begin

    Pencere^.FCizimAlan.Sag := Pencere^.FBoyut.Genislik -
      (Pencere^.FKalinlik.Sol + Pencere^.FKalinlik.Sag) - 1;
    Pencere^.FCizimAlan.Alt := Pencere^.FBoyut.Yukseklik -
      (Pencere^.FKalinlik.Ust + Pencere^.FKalinlik.Alt) - 1;

    // alt nesnelerin sýnýrlanacaðý hiza alanýný sýfýrla
    Pencere^.HizaAlaniniSifirla;
  end;

  // pencere alt nesnelerini yeniden boyutlandýr
  if(Pencere^.AltNesneSayisi > 0) then
  begin

    AltNesneler := Pencere^.FAltNesneBellekAdresi;

    // ilk oluþturulan alt nesneden son oluþturulan alt nesneye doðru
    // pencerenin alt nesnelerini yeniden boyutlandýr
    for i := 0 to Pencere^.AltNesneSayisi - 1 do
    begin

      GorunurNesne := AltNesneler[i];
      if(GorunurNesne^.Gorunum) then
      begin

        // yeni eklenecek görsel nesne - görsel nesneyi buraya ekle...
        case GorunurNesne^.NesneTipi of
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
  pencere nesnesini çizer

  önemli: pencere nesnesi çizilmeden önce içsel bileþenler (kapatma, büyütme düðmesi)
    ve diðer alt görsel bileþenler yeniden boyutlandýrýlmalýdýr. Bu sebepten dolayý
    boyutlandýrmalara baðlý çizim istekleri için TPencere.Guncelle iþlevi çaðrýlmalýdýr
 ==============================================================================}
procedure TPencere.Ciz;
var
  Pencere: PPencere = nil;
  GRSolUst, GRUst, GRSagUst,
  GRSol, GRSag,
  GRSolAlt, GRAlt, GRSagAlt: TGiysiResim;
  Olay: TOlay;
  Alan: TAlan;
  Sol, Sag, Genislik, Ust, Alt, i, j: TISayi4;
  Renk, BaslikRengi: TRenk;
  PencereAktif: Boolean;
  AltNesneler: PPGorselNesne;
  GorunurNesne: PGorselNesne;
  RenkBellek: PRenk;
begin

  Pencere := PPencere(GorselNesneler0.NesneAl(Kimlik));
  if(Pencere = nil) then Exit;

  Pencere^.FCiziliyor := True;

  Pencere^.Boyutlandir;

  // pencerenin kendi deðerlerine baðlý (0, 0) koordinatlarýný al
  Alan := Pencere^.FCizimAlan;

  Alan.Sag += (Pencere^.FKalinlik.Sol + Pencere^.FKalinlik.Sag);
  Alan.Alt += (Pencere^.FKalinlik.Ust + Pencere^.FKalinlik.Alt);

  // pencere tipi baþlýksýz ise, artan renk ile (eðimli) doldur
  if(Pencere^.FPencereTipi = ptBasliksiz) then

    EgimliDoldur3(Pencere, Alan, $D0DBFB, $B9C9F9)
  else
  // baþlýklý pencere nesnesinin çizimi
  begin

    // aktif veya pasif çizimin belirlenmesi
    PencereAktif := (Pencere = GAktifPencere);

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

      // kontrol düðmelerini aktifleþtir
      if not(Pencere^.FKucultmeDugmesi = nil) then
        Pencere^.FKucultmeDugmesi^.Deger := $20000000 + AktifGiysi.AKucultmeDugmesiRSNo;
      if not(Pencere^.FBuyutmeDugmesi = nil) then
        Pencere^.FBuyutmeDugmesi^.Deger := $20000000 + AktifGiysi.ABuyutmeDugmesiRSNo;
      if not(Pencere^.FKapatmaDugmesi = nil) then
        Pencere^.FKapatmaDugmesi^.Deger := $20000000 + AktifGiysi.AKapatmaDugmesiRSNo;
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

      // kontrol düðmelerini pasifleþtir
      if not(Pencere^.FKucultmeDugmesi = nil) then
        Pencere^.FKucultmeDugmesi^.Deger := $20000000 + AktifGiysi.PKucultmeDugmesiRSNo;
      if not(Pencere^.FBuyutmeDugmesi = nil) then
        Pencere^.FBuyutmeDugmesi^.Deger := $20000000 + AktifGiysi.PBuyutmeDugmesiRSNo;
      if not(Pencere^.FKapatmaDugmesi = nil) then
        Pencere^.FKapatmaDugmesi^.Deger := $20000000 + AktifGiysi.PKapatmaDugmesiRSNo;
    end;

    // pencerenin giydirilmesi

    // 1. sol üst köþenin giydirilmesi
    RenkBellek := GRSolUst.BellekAdresi;
    for Ust := 0 to GRSolUst.Yukseklik - 1 do
    begin

      for Sol := 0 to GRSolUst.Genislik - 1 do
      begin

        Renk := RenkBellek^;
        if not(Renk = $FFFFFFFF) then PixelYaz(Pencere, Sol, Ust, Renk);
        Inc(RenkBellek);
      end;
    end;

    // 2. üst yatay bölümün giydirilmesi
    Sol := AktifGiysi.ResimSolUstGenislik;
    Sag := Alan.Sag - AktifGiysi.ResimSagUstGenislik + 1;
    while True do
    begin

      RenkBellek := GRUst.BellekAdresi;

      for i := 0 to GRUst.Yukseklik - 1 do
      begin

        for j := 0 to GRUst.Genislik - 1 do
        begin

          Renk := RenkBellek^;
          if not(Renk = $FFFFFFFF) then PixelYaz(Pencere, Sol + j, i, Renk);
          Inc(RenkBellek);
        end;
      end;

      Sol += GRUst.Genislik;
      if(Sol >= Sag) then Break;

      if(Sol + GRUst.Genislik > Sag) then Sol := Sag - GRUst.Genislik;
    end;

    // 3. sað üst köþenin giydirilmesi
    RenkBellek := GRSagUst.BellekAdresi;
    i := Alan.Sag - GRSagUst.Genislik + 1;
    for Ust := 0 to GRSagUst.Yukseklik - 1 do
    begin

      for Sol := 0 to GRSagUst.Genislik - 1 do
      begin

        Renk := RenkBellek^;
        if not(Renk = $FFFFFFFF) then PixelYaz(Pencere, i + Sol, Ust, Renk);
        Inc(RenkBellek);
      end;
    end;

    // 4. sol köþenin giydirilmesi
    Ust := AktifGiysi.BaslikYukseklik;
    Alt := Alan.Alt - AktifGiysi.ResimSolAltYukseklik + 1;
    while True do
    begin

      RenkBellek := GRSol.BellekAdresi;

      for i := 0 to GRSol.Yukseklik - 1 do
      begin

        for j := 0 to GRSol.Genislik - 1 do
        begin

          Renk := RenkBellek^;
          if not(Renk = $FFFFFFFF) then PixelYaz(Pencere, j, Ust + i, Renk);
          Inc(RenkBellek);
        end;
      end;

      Ust += GRSol.Yukseklik;
      if(Ust >= Alt) then Break;

      if(Ust + GRSol.Yukseklik > Alt) then Ust := (Alt - GRSol.Yukseklik)
    end;

    // 5. sað köþenin giydirilmesi
    Ust := AktifGiysi.BaslikYukseklik;
    Alt := Alan.Alt - AktifGiysi.ResimSagAltYukseklik + 1;
    Sol := Alan.Sag - AktifGiysi.ResimSagGenislik + 1;
    while True do
    begin

      RenkBellek := GRSag.BellekAdresi;

      for i := 0 to GRSag.Yukseklik - 1 do
      begin

        for j := 0 to GRSag.Genislik - 1 do
        begin

          Renk := RenkBellek^;
          if not(Renk = $FFFFFFFF) then PixelYaz(Pencere, Sol + j, Ust + i, Renk);
          Inc(RenkBellek);
        end;
      end;

      Ust += GRSag.Yukseklik;
      if(Ust >= Alt) then Break;

      if(Ust + GRSag.Yukseklik > Alt) then Ust := (Alt - GRSag.Yukseklik);
    end;

    // 6. sol alt köþenin giydirilmesi
    RenkBellek := GRSolAlt.BellekAdresi;
    Ust := Alan.Alt - GRSolAlt.Yukseklik + 1;
    for i := 0 to GRSolAlt.Yukseklik - 1 do
    begin

      for j := 0 to GRSolAlt.Genislik - 1 do
      begin

        Renk := RenkBellek^;
        if not(Renk = $FFFFFFFF) then PixelYaz(Pencere, j, Ust + i, Renk);
        Inc(RenkBellek);
      end;
    end;

    // 7. alt köþenin giydirilmesi
    Sol := AktifGiysi.ResimSolAltGenislik;
    Ust := Alan.Alt - GRAlt.Yukseklik + 1;
    Sag := Alan.Sag - AktifGiysi.ResimSagAltGenislik + 1;
    while True do
    begin

      RenkBellek := GRAlt.BellekAdresi;

      for i := 0 to GRAlt.Yukseklik - 1 do
      begin

        for j := 0 to GRAlt.Genislik - 1 do
        begin

          Renk := RenkBellek^;
          if not(Renk = $FFFFFFFF) then PixelYaz(Pencere, Sol + j, Ust + i, Renk);
          Inc(RenkBellek);
        end;
      end;

      Sol += GRAlt.Genislik;
      if(Sol >= Sag) then Break;

      if(Sol + GRAlt.Genislik > Sag) then Sol := Sag - GRAlt.Genislik;
    end;

    // 8. sað alt köþenin giydirilmesi
    RenkBellek := GRSagAlt.BellekAdresi;
    Sol := Alan.Sag - GRSagAlt.Genislik + 1;
    Ust := Alan.Alt - GRSagAlt.Yukseklik + 1;
    for i := 0 to GRSagAlt.Yukseklik - 1 do
    begin

      for j := 0 to GRSagAlt.Genislik - 1 do
      begin

        Renk := RenkBellek^;
        if not(Renk = $FFFFFFFF) then PixelYaz(Pencere, Sol + j, Ust + i, Renk);
        Inc(RenkBellek);
      end;
    end;

    // pencere iç bölüm boyama
    Renk := AktifGiysi.IcDolguRengi;
    if(Renk = $FFFFFFFF) then Renk := Pencere^.FGovdeRenk1;

    DikdortgenDoldur(Pencere, AktifGiysi.ResimSolGenislik, AktifGiysi.BaslikYukseklik,
      Alan.Sag - AktifGiysi.ResimSagGenislik, Alan.Alt - AktifGiysi.ResimAltYukseklik, Renk, Renk);

    // pencere baþlýðýný yaz
    i := AktifGiysi.BaslikYaziSol;
    if(i = -1) then
      i := (Pencere^.FBoyut.Genislik div 2) - ((Length(Pencere^.Baslik) * 8) div 2);

    j := AktifGiysi.BaslikYaziUst;
    if(j = -1) then
      j := (AktifGiysi.BaslikYukseklik div 2) - (16 div 2);

    YaziYaz(Pencere, i, j, Pencere^.Baslik, BaslikRengi);

    if not(Pencere^.FPencereTipi = ptBasliksiz) then
    begin

      if(Pencere^.FPencereTipi = ptBoyutlanabilir) then
      begin

        Pencere^.FKucultmeDugmesi^.Ciz;
        Pencere^.FBuyutmeDugmesi^.Ciz;
      end;

      Pencere^.FKapatmaDugmesi^.Ciz;
    end;
  end;

  AltNesneler := Pencere^.FAltNesneBellekAdresi;
  if(Pencere^.AltNesneSayisi > 0) then
  begin

    // ilk oluþturulan alt nesneden son oluþturulan alt nesneye doðru
    // pencerenin alt nesnelerini çiz
    for i := 0 to Pencere^.AltNesneSayisi - 1 do
    begin

      GorunurNesne := AltNesneler[i];
      if(GorunurNesne^.Gorunum) and ((GorunurNesne^.Kimlik and 1) = 1) then
      begin

        // yeni eklenecek görsel nesne - görsel nesneyi buraya ekle...
        case GorunurNesne^.NesneTipi of
          //gntAcilirMenu     :
          gntAracCubugu     : PAracCubugu(GorunurNesne)^.Ciz;
          gntBaglanti       : PBaglanti(GorunurNesne)^.Ciz;
          gntDefter         : PDefter(GorunurNesne)^.Ciz;
          gntDegerDugmesi   : PDegerDugmesi(GorunurNesne)^.Ciz;
          gntDegerListesi   : PDegerListesi(GorunurNesne)^.Ciz;
          gntDugme          : PDugme(GorunurNesne)^.Ciz;
          gntDurumCubugu    : PDurumCubugu(GorunurNesne)^.Ciz;
          gntEtiket         : PEtiket(GorunurNesne)^.Ciz;
          gntGirisKutusu    : PGirisKutusu(GorunurNesne)^.Ciz;
          gntGucDugmesi     : PGucDugmesi(GorunurNesne)^.Ciz;
          gntIslemGostergesi: PIslemGostergesi(GorunurNesne)^.Ciz;
          gntIzgara         : PIzgara(GorunurNesne)^.Ciz;
          gntKarmaListe     : PKarmaListe(GorunurNesne)^.Ciz;
          gntKaydirmaCubugu : PKaydirmaCubugu(GorunurNesne)^.Ciz;
          gntListeGorunum   : PListeGorunum(GorunurNesne)^.Ciz;
          gntListeKutusu    : PListeKutusu(GorunurNesne)^.Ciz;
          //gntMasaustu;
          //gntMenu;
          gntOnayKutusu     : POnayKutusu(GorunurNesne)^.Ciz;
          gntPanel          : PPanel(GorunurNesne)^.Ciz;
          //gntPencere;
          gntRenkSecici     : PRenkSecici(GorunurNesne)^.Ciz;
          gntResim          : PResim(GorunurNesne)^.Ciz;
          gntResimDugmesi   : PResimDugmesi(GorunurNesne)^.Ciz;
          gntSayfaKontrol   : PSayfaKontrol(GorunurNesne)^.Ciz;
          gntSecimDugmesi   : PSecimDugmesi(GorunurNesne)^.Ciz;
        end;
      end;
    end;
  end;

  // uygulamaya veya efendi nesneye mesaj gönder
  Olay.Kimlik := Pencere^.Kimlik;
  Olay.Olay := CO_CIZIM;
  Olay.Deger1 := 0;
  Olay.Deger2 := 0;
  if not(Pencere^.OlayYonlendirmeAdresi = nil) then
    Pencere^.OlayYonlendirmeAdresi(Pencere, Olay)
  else Gorevler0.OlayEkle(Pencere^.GorevKimlik, Olay);

  Pencere^.FCiziliyor := False;
end;

{==============================================================================
  pencere nesne olaylarýný iþler
 ==============================================================================}
procedure TPencere.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere;
begin

  Pencere := PPencere(AGonderici);
  if(Pencere = nil) then Exit;

  // olaylarý ilgili iþlevlere yönlendir
  case Pencere^.FPencereTipi of
    ptBasliksiz       : BasliksizPencereOlaylariniIsle(Pencere, AOlay);
    ptIletisim        : IletisimPencereOlaylariniIsle(Pencere, AOlay);
    ptBoyutlanabilir  : BoyutlanabilirPencereOlaylariniIsle(Pencere, AOlay);
  end;
end;

{==============================================================================
  baþlýksýz pencere nesne olaylarýný iþler
 ==============================================================================}
procedure TPencere.BasliksizPencereOlaylariniIsle(APencere: PPencere; AOlay: TOlay);
begin

  // sol tuþa basým iþlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // APencere nesnesi aktif deðilse aktifleþtir
    if(APencere <> GAktifPencere) then EnUsteGetir(APencere);

    // sol tuþ basým iþlemi olay alanýnda gerçekleþtiyse
    if(APencere^.FareNesneOlayAlanindaMi(APencere)) then
    begin

      // fare mesajlarýný APencere nesnesine yönlendir
      OlayYakalamayaBasla(APencere);

      // uygulamaya veya efendi nesneye mesaj gönder
      if not(APencere^.OlayYonlendirmeAdresi = nil) then
        APencere^.OlayYonlendirmeAdresi(APencere, AOlay)
      else Gorevler0.OlayEkle(APencere^.GorevKimlik, AOlay);
    end;
  end

  // sol tuþ býrakým iþlemi
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare mesajlarýný yakalamayý býrak
    OlayYakalamayiBirak(APencere);

    // sol tuþ býrakým iþlemi olay alanýnda gerçekleþtiyse
    if(APencere^.FarePencereCizimAlanindaMi(APencere)) then
    begin

      // uygulamaya veya efendi nesneye mesaj gönder
      AOlay.Olay := FO_TIKLAMA;
      if not(APencere^.OlayYonlendirmeAdresi = nil) then
        APencere^.OlayYonlendirmeAdresi(APencere, AOlay)
      else Gorevler0.OlayEkle(APencere^.GorevKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    if not(APencere^.OlayYonlendirmeAdresi = nil) then
      APencere^.OlayYonlendirmeAdresi(APencere, AOlay)
    else Gorevler0.OlayEkle(APencere^.GorevKimlik, AOlay);
  end
  else if(AOlay.Olay = FO_HAREKET) then
  begin

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(APencere^.OlayYonlendirmeAdresi = nil) then
      APencere^.OlayYonlendirmeAdresi(APencere, AOlay)
    else Gorevler0.OlayEkle(APencere^.GorevKimlik, AOlay);
  end
  // diðer olaylar
  else
  begin

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(APencere^.OlayYonlendirmeAdresi = nil) then
      APencere^.OlayYonlendirmeAdresi(APencere, AOlay)
    else Gorevler0.OlayEkle(APencere^.GorevKimlik, AOlay);
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := APencere^.FareImlecTipi;
end;

{==============================================================================
  iletiþim pencere nesne olaylarýný iþler
 ==============================================================================}
procedure TPencere.IletisimPencereOlaylariniIsle(APencere: PPencere; AOlay: TOlay);
var
  Alan: TAlan;
begin

  // sol tuþa basým iþlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // APencere nesnesi aktif deðilse aktifleþtir
    if(APencere <> GAktifPencere) then EnUsteGetir(APencere);

    // sol tuþ basým iþlemi olay alanýnda gerçekleþtiyse
    if(APencere^.FareNesneOlayAlanindaMi(APencere)) then
    begin

      // fare mesajlarýný APencere nesnesine yönlendir
      OlayYakalamayaBasla(APencere);

      // eðer týklama pencerenin gövdesinde gerçekleþmiþse
      if(FareKonumu = fkGovde) then
      begin

        GecerliFareGostegeTipi := APencere^.FareImlecTipi;

        // uygulamaya veya efendi nesneye mesaj gönder
        if not(APencere^.OlayYonlendirmeAdresi = nil) then
          APencere^.OlayYonlendirmeAdresi(APencere, AOlay)
        else Gorevler0.OlayEkle(APencere^.GorevKimlik, AOlay);
      end
      else

      // aksi durumda týklama iþlemi yakalama çubuðunda gerçekleþmiþtir
      // o zaman pencerenin kenarlýklarýný sakla
      begin

        GecerliFareGostegeTipi := fitBoyutTum;
        SonFareYatayKoordinat := GFareSurucusu.YatayKonum;
        SonFareDikeyKoordinat := GFareSurucusu.DikeyKonum;
      end;
    end else GecerliFareGostegeTipi := APencere^.FareImlecTipi;
  end

  // sol tuþ býrakým iþlemi
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarýný almayý býrak
    OlayYakalamayiBirak(APencere);

    // taþýma iþlemi pencere çizim alanýnda gerçekleþmiþse
    if not(FareKonumu = fkKontrolCubugu) then
    begin

      // býrakma iþlemi APencere içerinde gerçekleþtiyse
      if(APencere^.FarePencereCizimAlanindaMi(APencere)) then
      begin

        GecerliFareGostegeTipi := APencere^.FareImlecTipi;

        // uygulamaya veya efendi nesneye mesaj gönder
        AOlay.Olay := FO_TIKLAMA;
        if not(APencere^.OlayYonlendirmeAdresi = nil) then
          APencere^.OlayYonlendirmeAdresi(APencere, AOlay)
        else Gorevler0.OlayEkle(APencere^.GorevKimlik, AOlay);

        // uygulamaya veya efendi nesneye mesaj gönder
        AOlay.Olay := FO_SOLTUS_BIRAKILDI;
        if not(APencere^.OlayYonlendirmeAdresi = nil) then
          APencere^.OlayYonlendirmeAdresi(APencere, AOlay)
        else Gorevler0.OlayEkle(APencere^.GorevKimlik, AOlay);
      end
      else

      // býrakma iþlemi APencere dýþýnda gerçekleþtiyse
      begin

        { TODO : býrakma iþlemi APencere dýþýnda olursa normalde kursor de ilgili
          nesnenin kursörü olur }
        GecerliFareGostegeTipi := APencere^.FareImlecTipi;

        // uygulamaya veya efendi nesneye mesaj gönder
        if not(APencere^.OlayYonlendirmeAdresi = nil) then
          APencere^.OlayYonlendirmeAdresi(APencere, AOlay)
        else Gorevler0.OlayEkle(APencere^.GorevKimlik, AOlay);
      end;
    end;
  end

  else if(AOlay.Olay = FO_HAREKET) then
  begin

    // fare yakalanmamýþsa sadece fare göstergesini güncelle
    if(YakalananGorselNesne = nil) then
    begin

      if(APencere^.FarePencereCizimAlanindaMi(APencere)) then
      begin

        FareKonumu := fkGovde;
        GecerliFareGostegeTipi := APencere^.FareImlecTipi;

        // uygulamaya veya efendi nesneye mesaj gönder
        if not(APencere^.OlayYonlendirmeAdresi = nil) then
          APencere^.OlayYonlendirmeAdresi(APencere, AOlay)
        else Gorevler0.OlayEkle(APencere^.GorevKimlik, AOlay);
      end
      else
      begin

        FareKonumu := fkKontrolCubugu;
        GecerliFareGostegeTipi := fitBoyutTum;

        // uygulamaya veya efendi nesneye mesaj gönder
        if not(APencere^.OlayYonlendirmeAdresi = nil) then
          APencere^.OlayYonlendirmeAdresi(APencere, AOlay)
        else Gorevler0.OlayEkle(APencere^.GorevKimlik, AOlay);
      end;
    end
    else

    // fare yakalanmýþ olduðu için taþýma iþlemlerini gerçekleþtir
    begin

      if(FareKonumu = fkKontrolCubugu) then
      begin

        Alan.Sol := GFareSurucusu.YatayKonum - SonFareYatayKoordinat;
        Alan.Ust := GFareSurucusu.DikeyKonum - SonFareDikeyKoordinat;
        Alan.Sag := 0;
        Alan.Alt := 0;

        SonFareYatayKoordinat := GFareSurucusu.YatayKonum;
        SonFareDikeyKoordinat := GFareSurucusu.DikeyKonum;

        APencere^.FKonum.Sol += Alan.Sol;
        APencere^.FBoyut.Genislik += Alan.Sag;
        APencere^.FKonum.Ust += Alan.Ust;
        APencere^.FBoyut.Yukseklik += Alan.Alt;

        GecerliFareGostegeTipi := fitBoyutTum;

        APencere^.Guncelle;
      end
      else
      begin

        // uygulamaya veya efendi nesneye mesaj gönder
        if not(APencere^.OlayYonlendirmeAdresi = nil) then
          APencere^.OlayYonlendirmeAdresi(APencere, AOlay)
        else Gorevler0.OlayEkle(APencere^.GorevKimlik, AOlay);

        GecerliFareGostegeTipi := APencere^.FareImlecTipi;
      end;
    end;
  end
  // diðer olaylar
  else
  begin

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(APencere^.OlayYonlendirmeAdresi = nil) then
      APencere^.OlayYonlendirmeAdresi(APencere, AOlay)
    else Gorevler0.OlayEkle(APencere^.GorevKimlik, AOlay);
  end;
end;

{==============================================================================
  boyutlandýrýlabilir pencere nesne olaylarýný iþler
 ==============================================================================}
procedure TPencere.BoyutlanabilirPencereOlaylariniIsle(APencere: PPencere; AOlay: TOlay);
var
  Alan: TAlan;
begin

  // sol tuþa basým iþlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // APencere nesnesi aktif deðilse aktifleþtir
    if(APencere <> GAktifPencere) then EnUsteGetir(APencere);

    // fare olaylarýný APencere nesnesine yönlendir
    OlayYakalamayaBasla(APencere);

    // eðer farenin sol tuþu APencere nesnesinin gövdesine týklanmýþsa ...
    if(FareKonumu = fkGovde) then
    begin

      if not(APencere^.OlayYonlendirmeAdresi = nil) then
        APencere^.OlayYonlendirmeAdresi(APencere, AOlay)
      else Gorevler0.OlayEkle(APencere^.GorevKimlik, AOlay);
    end
    else
    begin

      // aksi durumda taþýma / boyutlandýrma iþlemi gerçekleþtirilecektir.
      // deðiþken içeriklerini güncelle
      SonFareYatayKoordinat := GFareSurucusu.YatayKonum;
      SonFareDikeyKoordinat := GFareSurucusu.DikeyKonum;
    end;
  end

  // sol tuþ býrakma iþlemi
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare mesajlarýný yakalamayý býrak
    OlayYakalamayiBirak(APencere);

    // fare býrakma iþlemi nesnenin içerisinde mi gerçekleþti ?
    if(FareKonumu = fkGovde) then
    begin

      if(APencere^.FarePencereCizimAlanindaMi(APencere)) then
      begin
        // yakalama & býrakma iþlemi bu nesnede olduðu için
        // nesneye FO_TIKLAMA mesajý gönder
        AOlay.Olay := FO_TIKLAMA;
        if not(APencere^.OlayYonlendirmeAdresi = nil) then
          APencere^.OlayYonlendirmeAdresi(APencere, AOlay)
        else Gorevler0.OlayEkle(APencere^.GorevKimlik, AOlay);
      end;

      // nesneye sadece FO_SOLTUS_BIRAKILDI mesajý gönder
      AOlay.Olay := FO_SOLTUS_BIRAKILDI;
      if not(APencere^.OlayYonlendirmeAdresi = nil) then
        APencere^.OlayYonlendirmeAdresi(APencere, AOlay)
      else Gorevler0.OlayEkle(APencere^.GorevKimlik, AOlay);
    end;
  end

  // fare hareket iþlemleri
  else if(AOlay.Olay = FO_HAREKET) then
  begin

    // FO_HAREKET - nesne yakalanmamýþ
    if(YakalananGorselNesne = nil) then
    begin

      // fare > sol çizgi kalýnlýk
      if(AOlay.Deger1 > APencere^.FKalinlik.Sol) then
      begin

        // fare < sað çizgi kalýnlýk
        if(AOlay.Deger1 < (APencere^.FBoyut.Genislik - APencere^.FKalinlik.Sag)) then
        begin

          // fare < alt çizgi kalýnlýk
          if(AOlay.Deger2 < (APencere^.FBoyut.Yukseklik - APencere^.FKalinlik.Alt)) then
          begin

            // fare > alt çizgi kalýnlýk
            // bilgi: üst çizgi kalýnlýk deðeri baþlýk çubuðu deðeri olduðundan dolayý
            // üst çizgi kalýnlýk deðeri olarak alt çizgi kalýnlýk deðeri kullanýlmaktadýr
            if(AOlay.Deger2 > APencere^.FKalinlik.Alt) then
            begin

              // fare > yakalama çubuðu
              // bu deðer yakalama çubuðu için kullanýlýyor. hata yok
              if(AOlay.Deger2 > APencere^.FKalinlik.Ust) then
              begin

                // fare göstergesi APencere gövdesinde
                FareKonumu := fkGovde;
                GecerliFareGostegeTipi := APencere^.FareImlecTipi;

                if not(APencere^.OlayYonlendirmeAdresi = nil) then
                  APencere^.OlayYonlendirmeAdresi(APencere, AOlay)
                else Gorevler0.OlayEkle(APencere^.GorevKimlik, AOlay);
              end
              else
              begin

                // fare göstergesi yakalama çubuðunda
                FareKonumu := fkKontrolCubugu;
                GecerliFareGostegeTipi := fitBoyutTum;
              end;
            end
            else
            begin

              // fare göstergesi üst boyutlandýrmada
              FareKonumu := fkUst;
              GecerliFareGostegeTipi := fitBoyutKG;
            end;
          end
          else
          begin

            // fare göstergesi alt boyutlandýrmada
            FareKonumu := fkAlt;
            GecerliFareGostegeTipi := fitBoyutKG;
          end;
        end
        else
        // sað - alt / üst / orta (sað) kontrolü
        begin

          // bilgi: APencere^.FKalinlik.Alt deðeri aslýnda APencere^.FKalinlik.Ust deðeri olmalýdýr
          // fakat APencere^.FKalinlik.Ust deðeri baþlýk kalýnlýðý olarak kullanýlmaktadýr
          if(AOlay.Deger2 < APencere^.FKalinlik.Alt) then
          begin

            // fare göstergesi sað & üst boyutlandýrmada
            FareKonumu := fkSagUst;
            GecerliFareGostegeTipi := fitBoyutKDGB;
          end
          else if(AOlay.Deger2 > (APencere^.FBoyut.Yukseklik - APencere^.FKalinlik.Alt)) then
          begin

            // fare göstergesi sað & alt boyutlandýrmada
            FareKonumu := fkSagAlt;
            GecerliFareGostegeTipi := fitBoyutKBGD;
          end
          else
          begin

            // fare göstergesi sað kýsým boyutlandýrmada
            FareKonumu := fkSag;
            GecerliFareGostegeTipi := fitBoyutBD;
          end;
        end;
      end
      else
      // sol - alt / üst / orta (sol) kontrolü
      begin

        if(AOlay.Deger2 < APencere^.FKalinlik.Alt) then
        begin

          // fare göstergesi üst & sol kýsým boyutlandýrmada
          FareKonumu := fkSolUst;
          GecerliFareGostegeTipi := fitBoyutKBGD;
        end
        else if(AOlay.Deger2 > (APencere^.FBoyut.Yukseklik - APencere^.FKalinlik.Alt)) then
        begin

          // fare göstergesi alt & sol kýsým boyutlandýrmada
          FareKonumu := fkSolAlt;
          GecerliFareGostegeTipi := fitBoyutKDGB;
        end
        else
        begin

          // fare göstergesi sol kýsým boyutlandýrmada
          FareKonumu := fkSol;
          GecerliFareGostegeTipi := fitBoyutBD;
        end;
      end;
    end
    else

    // FO_HAREKET - nesne yakalanmýþ - taþýma, boyutlandýrma
    begin

      if(FareKonumu = fkGovde) then
      begin

        if not(APencere^.OlayYonlendirmeAdresi = nil) then
          APencere^.OlayYonlendirmeAdresi(APencere, AOlay)
        else Gorevler0.OlayEkle(APencere^.GorevKimlik, AOlay);
      end
      else
      begin

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
        end;

        SonFareYatayKoordinat := GFareSurucusu.YatayKonum;
        SonFareDikeyKoordinat := GFareSurucusu.DikeyKonum;

        APencere^.FKonum.Sol += Alan.Sol;
        APencere^.FBoyut.Genislik += Alan.Sag;
        APencere^.FKonum.Ust += Alan.Ust;
        APencere^.FBoyut.Yukseklik += Alan.Alt;

        APencere^.FCizimAlan.Sol := 0;
        APencere^.FCizimAlan.Ust := 0;
        APencere^.FCizimAlan.Sag := APencere^.FBoyut.Genislik - 1;
        APencere^.FCizimAlan.Alt := APencere^.FBoyut.Yukseklik - 1;

        //if(APencere^.FCiziliyor) then Exit;

        APencere^.Boyutlandir;

        // çizim için ayrýlan belleði yok et ve yeni bellek ayýr
        { TODO : ileride çizimlerin daha hýzlý olmasý için APencere küçülmesi için bellek ayrýlmayabilir }
        FreeMem(APencere^.FCizimBellekAdresi, APencere^.FCizimBellekUzunlugu);

        APencere^.FCizimBellekUzunlugu := (APencere^.FBoyut.Genislik * APencere^.FBoyut.Yukseklik * 4);
        APencere^.FCizimBellekAdresi := GetMem(APencere^.FCizimBellekUzunlugu);

        APencere^.Ciz;
      end;
    end;
  end
  // diðer olaylar
  else
  begin

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(APencere^.OlayYonlendirmeAdresi = nil) then
      APencere^.OlayYonlendirmeAdresi(APencere, AOlay)
    else Gorevler0.OlayEkle(APencere^.GorevKimlik, AOlay);
  end;
end;

{==============================================================================
  pencere nesnesi ve alt nesnelerini günceller
  önemli: tüm alt nesneler çizim istekleri için bu iþlevi (TPencere.Guncelle) çaðýrmalýdýr
 ==============================================================================}
procedure TPencere.Guncelle;
var
  Pencere: PPencere;
begin

  // nesnenin kimlik, tip deðerlerini denetle.
  Pencere := PPencere(GorselNesneler0.NesneAl(Kimlik));
  if(Pencere = nil) then Exit;

  Pencere^.Boyutlandir;

  Pencere^.Ciz;
end;

{==============================================================================
  belirtilen pencere nesnesini en üste getirir ve yeniden çizer
 ==============================================================================}
procedure TPencere.EnUsteGetir(APencere: PPencere);
var
  Masaustu: PMasaustu;
  BirOncekiPencere: PPencere;
  AltNesneBellekAdresi: PPGorselNesne;
  GN: PGorselNesne;
  i, j: TISayi4;
begin

{------------------------------------------------------------------------------
  Sýralama            0   1   2
                    +---+---+---+
  Nesne Kimlikleri  | 1 | 2 | 3 |
                    +-+-+---+-+-+
                      |       +----- en üst nesne
                      +------------- en alt nesne
-------------------------------------------------------------------------------}

  // aktif masaüstünü al
  Masaustu := GAktifMasaustu;

  // masaüstünün alt nesne bellek deðerini al
  AltNesneBellekAdresi := Masaustu^.FAltNesneBellekAdresi;

  // nesnenin alt nesne sayýsý var ise
  if(Masaustu^.AltNesneSayisi > 1) then
  begin

    BirOncekiPencere := PPencere(AltNesneBellekAdresi[Masaustu^.AltNesneSayisi - 1]);

    // alt nesneler içerisinde pencere nesnesini ara
    for i := (Masaustu^.AltNesneSayisi - 1) downto 0 do
    begin

      if(PPencere(AltNesneBellekAdresi[i]) = APencere) then Break;
    end;

    // eðer pencere nesnesi en üstte deðil ise
    if(i <> Masaustu^.AltNesneSayisi - 1) then
    begin

      // pencere nesnesini masaüstü nesne belleðinde en üste getir
      for j := i to Masaustu^.AltNesneSayisi - 2 do
      begin

        GN := AltNesneBellekAdresi[j + 0];
        AltNesneBellekAdresi[j + 0] := AltNesneBellekAdresi[j + 1];
        AltNesneBellekAdresi[j + 1] := GN;
      end;
    end;

    // pencere en üstte olsa da olmasa da aktif pencere olarak tanýmla
    // not: pencere en üstte olup görüntülenmiþ olmayabilir
    GAktifPencere := APencere;

    // bir önceki pencere pasif olacaðý için yeniden çiz
    if(BirOncekiPencere^.Gorunum) then BirOncekiPencere^.Guncelle;

    // aktif pencereyi yeniden çiz
    GAktifPencere^.Guncelle;

    // görev bayrak deðerini artýr
    Inc(GorevBayrakDegeri);
  end;
end;

{==============================================================================
  fare göstergesinin pencere nesnesinin gövde (çizim alaný) içerisinde
  olup olmadýðýný kontrol eder
 ==============================================================================}
function TPencere.FarePencereCizimAlanindaMi(APencere: PPencere): Boolean;
var
  Alan: TAlan;
begin

  Alan.Sol := APencere^.FKonum.Sol + APencere^.FKalinlik.Sol;
  Alan.Ust := APencere^.FKonum.Ust + APencere^.FKalinlik.Ust;
  Alan.Sag := Alan.Sol + (APencere^.FBoyut.Genislik + APencere^.FKalinlik.Sag);
  Alan.Alt := Alan.Ust + (APencere^.FBoyut.Yukseklik + APencere^.FKalinlik.Alt);

  // öndeðer dönüþ deðeri
  Result := False;

  // fare belirtilen koordinatlar içerisinde mi ?
  if(GFareSurucusu.YatayKonum < Alan.Sol) then Exit;
  if(GFareSurucusu.YatayKonum > Alan.Sag) then Exit;
  if(GFareSurucusu.DikeyKonum < Alan.Ust) then Exit;
  if(GFareSurucusu.DikeyKonum > Alan.Alt) then Exit;

  Result := True;
end;

{==============================================================================
  pencere nesnesini yeniden boyutlandýrýr iç bileþenlerini konumlandýrýr
 ==============================================================================}
procedure TPencere.IcBilesenleriKonumlandir(var APencere: PPencere);
var
  i: TISayi4;
begin

  APencere^.FCizimAlan.Sag := APencere^.FBoyut.Genislik -
    (APencere^.FKalinlik.Sol + APencere^.FKalinlik.Sag) - 1;
  APencere^.FCizimAlan.Alt := APencere^.FBoyut.Yukseklik -
    (APencere^.FKalinlik.Ust + APencere^.FKalinlik.Alt) - 1;

  // alt nesnelerin sýnýrlanacaðý hiza alanýný sýfýrla
  APencere^.HizaAlaniniSifirla;

  if(APencere^.FPencereTipi = ptBoyutlanabilir) then
  begin

    i := AktifGiysi.KucultmeDugmesiSol;
    if(i < 0) then
      i := APencere^.FBoyut.Genislik + AktifGiysi.KucultmeDugmesiSol;
    APencere^.FKucultmeDugmesi^.FKonum.Sol := i;
    APencere^.FKucultmeDugmesi^.FKonum.Ust := AktifGiysi.KucultmeDugmesiUst;

    i := AktifGiysi.BuyutmeDugmesiSol;
    if(i < 0) then
      i := APencere^.FBoyut.Genislik + AktifGiysi.BuyutmeDugmesiSol;
    APencere^.FBuyutmeDugmesi^.FKonum.Sol := i;
    APencere^.FKucultmeDugmesi^.FKonum.Ust := AktifGiysi.BuyutmeDugmesiUst;

    i := AktifGiysi.KapatmaDugmesiSol;
    if(i < 0) then
      i := APencere^.FBoyut.Genislik + AktifGiysi.KapatmaDugmesiSol;
    APencere^.FKapatmaDugmesi^.FKonum.Sol := i;
    APencere^.FKapatmaDugmesi^.FKonum.Ust := AktifGiysi.KapatmaDugmesiUst;

    APencere^.FKucultmeDugmesi^.FCizimBaslangic.Sol := APencere^.FCizimBaslangic.Sol + APencere^.FKucultmeDugmesi^.FKonum.Sol;
    APencere^.FKucultmeDugmesi^.FCizimBaslangic.Ust := APencere^.FCizimBaslangic.Ust + APencere^.FKucultmeDugmesi^.FKonum.Ust;
    APencere^.FBuyutmeDugmesi^.FCizimBaslangic.Sol := APencere^.FCizimBaslangic.Sol + APencere^.FBuyutmeDugmesi^.FKonum.Sol;
    APencere^.FBuyutmeDugmesi^.FCizimBaslangic.Ust := APencere^.FCizimBaslangic.Ust + APencere^.FBuyutmeDugmesi^.FKonum.Ust;
    APencere^.FKapatmaDugmesi^.FCizimBaslangic.Sol := APencere^.FCizimBaslangic.Sol + APencere^.FKapatmaDugmesi^.FKonum.Sol;
    APencere^.FKapatmaDugmesi^.FCizimBaslangic.Ust := APencere^.FCizimBaslangic.Ust + APencere^.FKapatmaDugmesi^.FKonum.Ust;
  end
  else if(APencere^.FPencereTipi = ptIletisim) then
  begin

    i := AktifGiysi.KapatmaDugmesiSol;
    if(i < 0) then
      i := APencere^.FBoyut.Genislik + AktifGiysi.KapatmaDugmesiSol;
    APencere^.FKapatmaDugmesi^.FKonum.Sol := i;
    APencere^.FKapatmaDugmesi^.FKonum.Ust := AktifGiysi.KapatmaDugmesiUst;

    APencere^.FKapatmaDugmesi^.FCizimBaslangic.Sol := APencere^.FCizimBaslangic.Sol + APencere^.FKapatmaDugmesi^.FKonum.Sol;
    APencere^.FKapatmaDugmesi^.FCizimBaslangic.Ust := APencere^.FCizimBaslangic.Ust + APencere^.FKapatmaDugmesi^.FKonum.Ust;
  end;
end;

procedure TPencere.KontrolDugmesiOlaylariniIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  ResimDugmesi: PResimDugmesi;
  Pencere: PPencere;
  Olay: TOlay;
begin

  if(AOlay.Olay = FO_TIKLAMA) then
  begin

    ResimDugmesi := PResimDugmesi(AGonderici);
    if(ResimDugmesi = nil) then Exit;

    Pencere := PPencere(ResimDugmesi^.AtaNesne);

    if(ResimDugmesi^.Kimlik = Pencere^.FKucultmeDugmesi^.Kimlik) then
      Pencere^.FPencereDurum := pdKucultuldu
    else if(ResimDugmesi^.Kimlik = Pencere^.FBuyutmeDugmesi^.Kimlik) then
      SISTEM_MESAJ(mtUyari, RENK_SIYAH, 'Bilgi: büyütme düðmesi iþlevi yapýlandýrýlacak', [])
    else if(ResimDugmesi^.Kimlik = Pencere^.FKapatmaDugmesi^.Kimlik) then
    begin

      // uygulamaya veya efendi nesneye mesaj gönder
      Olay.Kimlik := Pencere^.Kimlik;
      Olay.Olay := CO_SONLANDIR;
      Olay.Deger1 := 0;
      Olay.Deger2 := 0;
      if not(Pencere^.OlayYonlendirmeAdresi = nil) then
        Pencere^.OlayYonlendirmeAdresi(Pencere, Olay)
      else Gorevler0.OlayEkle(Pencere^.GorevKimlik, Olay);
    end;
  end;
end;

end.
