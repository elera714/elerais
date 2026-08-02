{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gorselnesne.pas
  Dosya İşlevi: tüm görsel nesnelerin türediği temel görsel ana yapı

  Güncelleme Tarihi: 22/07/2026

  Bilgi: bu görsel yapı, tüm nesnelerin ihtiyaç duyabileceği ana yapıları içerir

 ==============================================================================}
{$mode objfpc}
unit gorselnesne;

interface

uses paylasim, temelgorselnesne;

const
  NOKTA_BOSLUKSAYISI = 3;

type
  PGorselNesne = ^TGorselNesne;
  PPGorselNesne = ^PGorselNesne;

  TOlaylariIsle = procedure(AGonderici: PGorselNesne; AOlay: TOlay) of object;

  TGorselNesne = object(TTemelGorselNesne)
  public


    // FCizimModel
    //   0: dolgu ve yazı yok
    //   1: arka plan rengi yok, yazı var
    //   2: arka plan rengi var, yazı yok
    //   3: FGovdeRenk1 = kenarlık rengi, FGovdeRenk2 = dolgu rengi
    //   4: FGovdeRenk1'den FGovdeRenk2'ye doğru eğimli dolgu
    FCizimModel: TSayi4;
    FGovdeRenk1, FGovdeRenk2,
    FYaziRenk: TRenk;

    FTuvalNesne: PGorselNesne;                  // nesnenin çizim yapılacağı en üst çizim nesnesi
    FAtaNesne: PGorselNesne;                    // nesnenin atası
    FCizimBellekAdresi: Isaretci;               // pencere ve alt görsel nesnelerin çizileceği bellek adresi
    FCizimBellekUzunlugu: TSayi4;               // FCizimBellekAdresi değişkeninin işaret ettiği belleğin uzunluğu

    OlayCagriAdresi: TOlaylariIsle;             // olayların yönlendirildiği nesne olay çağrı adresi
    OlayYonlendirmeAdresi: TOlaylariIsle;       // görsel nesneler tarafından bileşenlerin olaylarının yönlendirileceği olay adresi

    FEtiket: TSayi4;                            // nesneyi kullanacak programın kullanımı için

    function Olustur(AKullanimTipi: TKullanimTipi; AGNTip: TGNTip; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4; ACizimModel: TSayi4;
      AGovdeRenk1, AGovdeRenk2, AYaziRenk: TRenk; ABaslik: string): PGorselNesne;

    procedure Goster;
    procedure Gizle;
    procedure Ciz;

    procedure BoyutlariYenidenHesapla;
    procedure HizaAlaniniSifirla;
    procedure Hizala;

    function CizimAlaniniAl(AKimlik: TKimlik): TAlan;
    function CizimAlaniniAl2(AKimlik: TKimlik): TAlan;
    function AtaNesneGorunurMu: Boolean;
    function FareNesneOlayAlanindaMi(AGorselNesne: PGorselNesne): Boolean;
    function NoktaAlanIcerisindeMi(NoktaA1, NoktaB1: TISayi4;
      AAlan: TAlan): Boolean;
    property AtaNesne: PGorselNesne read FAtaNesne write FAtaNesne;

    // kernel için çağrılar (for kernel)
    procedure PixelYaz(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4; ARenk: TRenk);
    procedure YaziYaz(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4; AYazi: string; ARenk: TRenk);
    procedure YaziYaz(AGorselNesne: PGorselNesne; AYaziHiza: TYaziHiza;
      AAlan: TAlan; AYazi: string; ARenk: TRenk);
    procedure AlanaYaziYaz(AGorselNesne: PGorselNesne; AAlan: TAlan;
      ASol, AUst: TISayi4; AKarakterDizi: string; ARenk: TRenk);
    procedure SayiYaz16(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4; AOnEkYaz:
      LongBool; AHaneSayisi, ADeger: TISayi4; ARenk: TRenk);
    procedure SaatYaz(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4; ASaat: TSaat; ARenk: TRenk);
    procedure HarfYaz(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4;
      AKarakter: Char; AZeminRengi, AYaziRengi: TRenk);
    procedure SayiYaz10(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4;
      ASayi: TISayi4; ARenk: TRenk);
    procedure MACAdresiYaz(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4;
      AMACAdres: TMACAdres; ARenk: TRenk);
    procedure IPAdresiYaz(AGorselNesne: PGorselNesne; ASol, AUst: TSayi4; AIPAdres: TIP4Adres;
      ARenk: TRenk);
    procedure Dikdortgen(AGorselNesne: PGorselNesne; ACizgiTipi: TCizgiTipi;
      AAlan: TAlan; ACizgiRengi: TRenk);
    procedure DikdortgenDoldur(AGorselNesne: PGorselNesne; ASol, AUst,
      ASag, AAlt: TISayi4; ACizgiRengi, ADolguRengi: TRenk);
    procedure DikdortgenDoldur(AGorselNesne: PGorselNesne; AAlan: TAlan;
      ACizgiRengi, ADolguRengi: TRenk);
    procedure Doldur4(AGorselNesne: PGorselNesne; AAlan: TAlan; ASol, AUst,
      ASag, AAlt: TISayi4; ACizgiRengi, ADolguRengi: TRenk);
    procedure BMPGoruntusuCiz(AGNTip: TGNTip; AGorselNesne: PGorselNesne;
      AGoruntuYapi: TGoruntuYapi);
    procedure Cizgi(AGorselNesne: PGorselNesne; ACizgiTipi: TCizgiTipi;
      ASol, AUst, ASag, AAlt: TISayi4; ACizgiRengi: TRenk);
    procedure Daire(ASol, AUst, AYariCap: TISayi4; ARenk: TRenk);
    procedure DaireDoldur(AGorselNesne: PGorselNesne; ASol, AUst,
      AYariCap: TISayi4; ARenk: TRenk);
    procedure YatayCizgi(AGorselNesne: PGorselNesne; ACizgiTipi: TCizgiTipi;
      ASol, AUst, ASag: TISayi4; ARenk: TRenk);
    procedure DikeyCizgi(AGorselNesne: PGorselNesne; ACizgiTipi: TCizgiTipi;
      ASol, AUst, AAlt: TISayi4; ARenk: TRenk);
    procedure EgimliDoldur(AGorselNesne: PGorselNesne; AAlan: TAlan;
      ARenk1, ARenk2: TRenk);
    procedure EgimliDoldur2(AGorselNesne: PGorselNesne; AAlan: TAlan;
      ARenk1, ARenk2: TRenk);
    procedure EgimliDoldur3(AGorselNesne: PGorselNesne; AAlan: TAlan; ARenk1, ARenk2: TRenk);
    procedure KenarlikCiz(AGorselNesne: PGorselNesne; AAlan: TAlan;
      AKalinlik: TSayi4);
    procedure HamResimCiz(AGorselNesne: PGorselNesne; ASol, AUst: TSayi4;
      AHamResimBellekAdresi: Isaretci);
    procedure KaynaktanResimCiz(AGorselNesne: PGorselNesne; AAlan: TAlan; AResimSiraNo: TISayi4);
    procedure KaynaktanResimCiz2(AGorselNesne: PGorselNesne; ASol, AUst: TSayi4;
      AResimSiraNo: TISayi4);
    procedure KaynaktanResimCiz21(AGorselNesne: PGorselNesne; ASol, AUst: TSayi4;
      AResimSiraNo: TISayi4);

    // program için çağrılar (for program)
    procedure Kesme_YaziYaz(ASol, AUst: TISayi4; AKarakterDizi: string; ARenk: TRenk);
    procedure Kesme_SayiYaz16(ASol, AUst: TISayi4; AOnEkYaz: LongBool;
      AHaneSayisi, ADeger: TISayi4; ARenk: TRenk);
    procedure Kesme_SaatYaz(ASol, AUst: TISayi4; ASaat: TSaat; ARenk: TRenk);
  end;

type
  PGorselNesneler = ^TGorselNesneler;
  TGorselNesneler = class
  private
    FGorselNesneListesi: array[0..USTSINIR_GORSELNESNE - 1] of PGorselNesne;
    FToplamGN,
    FToplamMasaustu: TSayi4;
    function GorselNesneAl(ASiraNo: TISayi4): PGorselNesne;
    procedure GorselNesneYaz(ASiraNo: TISayi4; AGorselNesne: PGorselNesne);
  public
    constructor Create;
    function Olustur(AGNTip: TGNTip): PGorselNesne;
    procedure YokEt(AKimlik: TKimlik);
    function AtaNesneyeEkle(AGorselNesne, AAtaNesne: PGorselNesne): Boolean;
    function AtaNesnedenCikar(AGorselNesne: PGorselNesne): Boolean;
    function NesneAl(AKimlik: TKimlik): PGorselNesne;
    function NesneTipiniKontrolEt(AKimlik: TKimlik; AGNTip: TGNTip): PGorselNesne;
    procedure PencereyiYokEt(AGorevKimlik: TKimlik);
    property GorselNesne[ASiraNo: TISayi4]: PGorselNesne read GorselNesneAl write GorselNesneYaz;
  published
    property ToplamGN: TSayi4 read FToplamGN;
    property ToplamMasaustu: TSayi4 read FToplamMasaustu write FToplamMasaustu;
  end;


var
  GGorselNesneler: TGorselNesneler;
  GorselNesnelerKilit: TSayi4 = 0;

implementation

uses genel, src_ps2, genel8x16, donusum, bmp, gn_islevler, sistemmesaj, gn_pencere,
  hamresim, giysi_normal, giysi_mac, gorev, src_vesa20, gn_masaustu, gn_araccubugu,
  gn_baglanti, gn_defter, gn_degerdugmesi, gn_degerlistesi, gn_dugme, gn_durumcubugu,
  gn_etiket, gn_giriskutusu, gn_gucdugmesi, gn_islemgostergesi, gn_izgara,
  gn_karmaliste, gn_kaydirmacubugu, gn_listegorunum, gn_listekutusu, gn_onaykutusu,
  gn_panel, gn_renksecici, gn_resim, gn_resimdugmesi, gn_sayfakontrol, gn_secimdugmesi;

{==============================================================================
  görsel nesne yükleme işlevlerini gerçekleştirir
 ==============================================================================}
constructor TGorselNesneler.Create;
var
  i: TSayi4;
  j: TKimlik;
begin

  { TODO : 64 Byte = fazladan ayrılan ve şu an hesaplanamadığı için en üst değer
    olarak ayrılan temkin değeri. gereken değer teyit edilip otomatikleştirilecek }
  // üstteki açıklama durumu değişkenin 1024 olarak değiştirilmesiyle pasifleştirilmiştir
  GN_UZUNLUK := 4096; //Align(SizeOf(TPencere) + 64, 16);

  // nesneye ait işaretçileri bellek bölgeleriyle eşleştir
  for i := 0 to USTSINIR_GORSELNESNE - 1 do GGorselNesneler.GorselNesne[i] := nil;

  // görsel nesne değişkenlerini ilk değerlerle yükle
  ToplamMasaustu := 0;
  FToplamGN := 0;
  GAktifMasaustu := nil;
  GAktifPencere := nil;
  GAktifMenu := nil;
  YakalananGorselNesne := nil;
end;

{==============================================================================
  görsel nesne nesnesini oluşturur
 ==============================================================================}
function TGorselNesneler.Olustur(AGNTip: TGNTip): PGorselNesne;
var
  GN: PGorselNesne;
  i: TSayi4;
begin

//  while KritikBolgeyeGir(GorselNesnelerKilit) = False do;

  // tüm nesneleri ara
  for i := 0 to USTSINIR_GORSELNESNE - 1 do
  begin

    GN := GorselNesne[i];

    // eğer nesne kullanılmamış ise ... (0. bit 0 ise)
    if(GN = nil) then
    begin

      GN := GetMem(4096); //GN_UZUNLUK);
      GorselNesne[i] := GN;

      // nesne içeriğini sıfırla
      //FillByte(GN^, GN_UZUNLUK, 0);

      GN^.F0 := TTemelGorselNesne0.Create;

      GN^.F0.FSiraNo := i;
      GN^.F0.Kimlik := (i shl 10) or %1010101011;
      GN^.F0.NesneTipi := AGNTip;

      // oluşturulmuş nesne sayısını 1 artır
      Inc(FToplamGN);

//      KritikBolgedenCik(GorselNesnelerKilit);

      // geri dönecek değer
      Result := GN;

      Exit;
    end;
  end;

//  KritikBolgedenCik(GorselNesnelerKilit);

  Result := nil;
end;

{==============================================================================
  görsel nesneyi yok eder
 ==============================================================================}
procedure TGorselNesneler.YokEt(AKimlik: TKimlik);
var
  i: TKimlik;
  GN: PGorselNesne;
begin

//  while KritikBolgeyeGir(GorselNesnelerKilit) = False do;

  i := AKimlik shr 10;

  // eğer nesne istenen aralıkta ise yok et
  GN := GorselNesne[i];
  if not(GN = nil) then
  begin

    //Mesaj(GN^.Kimlik);

    //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Nesne: %s', [GN^.NesneAdi]);

    if(AtaNesnedenCikar(GN)) then
    begin

      GorselNesne[i] := nil;
      FreeMem(GN, GN_UZUNLUK);
      //GN := nil;

      Dec(FToplamGN);
    end;
    //Result := True;
  end; //else Result := False;

//  KritikBolgedenCik(GorselNesnelerKilit);
end;

{==============================================================================
  nesneyi ata nesnesine alt nesne olarak ekler
 ==============================================================================}
function TGorselNesneler.AtaNesneyeEkle(AGorselNesne, AAtaNesne: PGorselNesne): Boolean;
begin

  Result := False;

  // ata nesnenin alt nesneleri için bellek oluşturulmuş mu ?
  if(AAtaNesne^.F0.AltNesneBellekAdresi = nil) then
  begin

    // ata nesne için bellek oluştur
    AAtaNesne^.F0.AltNesneBellekAdresi := GetMem(4096);
  end;

  if(AAtaNesne^.F0.AltNesneBellekAdresi = nil) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'GORSELNESNE.PAS: Hata: Nesne için ata nesnede bellek alanı ayrılamıyor!', []);
    Exit;
  end;

  // alt nesne toplam nesne sayısı aşılmamışsa ...
  if(AAtaNesne^.F0.AltNesneSayisi < 1024) then
  begin

    // nesneyi üst nesneye kaydet
    PPGorselNesne(AAtaNesne^.F0.AltNesneBellekAdresi)[AAtaNesne^.F0.AltNesneSayisi] := AGorselNesne;

    // üst nesnenin nesne saysını 1 artır
    AAtaNesne^.F0.FAltNesneSayisi := AAtaNesne^.F0.FAltNesneSayisi + 1;

    Result := True;
  end;
end;

{==============================================================================
  gorsel nesneyi ata nesne dizisinden çıkarır
  işlev aşağıdaki alt işlevleri yerine getirir
  1. gorsel nesneyi ata nesne dizisinden çıkarır
  2. diziyi sola dayalı olarak yeniden sıralar
  3. ata nesnenin alt nesne sayısını 1 azaltır
  4. ata nesne alt nesne sayısının 0 olması durumunda alt nesne için ayrılan bellek
     bölgesini serbest bırakarak değişken bölgesine nil değeri ataması gerçekleştirir
 ==============================================================================}
function TGorselNesneler.AtaNesnedenCikar(AGorselNesne: PGorselNesne): Boolean;
var
  AGN, GN: PGorselNesne;
  GNBellekAdresi: PPGorselNesne;
  i, j: TSayi4;
begin

  Result := False;

  AGN := GGorselNesneler.GorselNesne[AGorselNesne^.AtaNesne^.F0.FSiraNo];
  if(AGN = nil) then Exit;

  GNBellekAdresi := AGN^.F0.AltNesneBellekAdresi;
  if(AGN^.F0.AltNesneSayisi = 1) then
  begin

    GN := GNBellekAdresi[0];
    if not(GN = nil) and (GN = AGorselNesne) then
    begin

      GNBellekAdresi[0] := nil;
      AGN^.F0.AltNesneSayisi := 0;

      // alt nesne bellek adresini serbest bırak
      FreeMem(AGN^.F0.AltNesneBellekAdresi, 4096);
      AGN^.F0.AltNesneBellekAdresi := nil;

      Exit(True);
    end;
  end
  else
  begin

    for i := 0 to AGN^.F0.AltNesneSayisi - 1 do
    begin

      GN := GNBellekAdresi[i];
      if not(GN = nil) and (GN = AGorselNesne) then
      begin

        // 1.1 dizinin son nesnesi çıkarılacaksa
        if((i + 1) = AGN^.F0.AltNesneSayisi) then
        begin

          GNBellekAdresi[i] := nil;
        end
        else
        // 1.2 dizinin diğer nesneleri çıkarılacaksa
        begin

          // çıkarılacak nesnenin sağındaki tüm nesneleri sola kaydır
          for j := i + 1 to AGN^.F0.AltNesneSayisi - 1 do
          begin

            GNBellekAdresi[j - 1] := GNBellekAdresi[j];
          end;

          // son nesneyi nil olarak işaretle
          GNBellekAdresi[j] := nil;
        end;

        // alt nesne sayısını bir azalt
        j := AGN^.F0.FAltNesneSayisi;
        Dec(j);
        AGN^.F0.FAltNesneSayisi := j;

        // alt nesne sayısının 0 olması durumunda bellek adresini serbest bırak
        if(AGN^.F0.AltNesneSayisi = 0) then
        begin

          FreeMem(AGN^.F0.AltNesneBellekAdresi, 4096);
          AGN^.F0.AltNesneBellekAdresi := nil;
        end;

        Exit(True);
      end;
    end;
  end;
end;

function TGorselNesneler.GorselNesneAl(ASiraNo: TISayi4): PGorselNesne;
begin

  // istenen verinin belirtilen aralıkta olup olmadığını kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_GORSELNESNE) then
    Result := FGorselNesneListesi[ASiraNo]
  else Result := nil;
end;

procedure TGorselNesneler.GorselNesneYaz(ASiraNo: TISayi4; AGorselNesne: PGorselNesne);
begin

  // istenen verinin belirtilen aralıkta olup olmadığını kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_GORSELNESNE) then
    FGorselNesneListesi[ASiraNo] := AGorselNesne;
end;

{==============================================================================
  nesne kimliğinden nesneyi alır
 ==============================================================================}
function TGorselNesneler.NesneAl(AKimlik: TKimlik): PGorselNesne;
var
  i: TKimlik;
begin

  i := AKimlik shr 10;

  if(i >= 0) and (i < USTSINIR_GORSELNESNE) then
    Result := GorselNesne[i]
  else Result := nil;
end;

{==============================================================================
  nesnenin nesne tipini kontrol eder
 ==============================================================================}
function TGorselNesneler.NesneTipiniKontrolEt(AKimlik: TKimlik; AGNTip: TGNTip): PGorselNesne;
var
  GN: PGorselNesne;
  i: TKimlik;
begin

  Result := nil;

  i := AKimlik shr 10;

  // nesne istenen sayı aralığında ise
  GN := GorselNesne[i];
  if(GN = nil) then Exit;

  // nesne kimlik, tipini kontrol et
  if(GN^.F0.Kimlik = AKimlik) and (GN^.F0.NesneTipi = AGNTip) then Exit(GN);
end;

{==============================================================================
  görevin ana penceresi ve pencereye ait tüm alt nesneleri yok eder
 ==============================================================================}
procedure TGorselNesneler.PencereyiYokEt(AGorevKimlik: TKimlik);
var
  Masaustu: PMasaustu;
  Pencere,
  GN, GN2: PGorselNesne;
  i, j, k,
  ANSayisi: TSayi4;

  procedure NesneyiYokEt(ANesne: PGorselNesne);
  begin

    case ANesne^.F0.NesneTipi of
      //gntAcilirMenu     :
      gntAracCubugu     : PAracCubugu(ANesne)^.YokEt(ANesne^.F0.Kimlik);
      gntBaglanti       : PBaglanti(ANesne)^.YokEt(ANesne^.F0.Kimlik);
      gntDefter         : PDefter(ANesne)^.YokEt(ANesne^.F0.Kimlik);
      gntDegerDugmesi   : PDegerDugmesi(ANesne)^.YokEt(ANesne^.F0.Kimlik);
      gntDegerListesi   : PDegerListesi(ANesne)^.YokEt(ANesne^.F0.Kimlik);
      gntDugme          : PDugme(ANesne)^.YokEt(ANesne^.F0.Kimlik);
      gntDurumCubugu    : PDurumCubugu(ANesne)^.YokEt(ANesne^.F0.Kimlik);
      gntEtiket         : PEtiket(ANesne)^.YokEt(ANesne^.F0.Kimlik);
      gntGirisKutusu    : PGirisKutusu(ANesne)^.YokEt(ANesne^.F0.Kimlik);
      gntGucDugmesi     : PGucDugmesi(ANesne)^.YokEt(ANesne^.F0.Kimlik);
      gntIslemGostergesi: PIslemGostergesi(ANesne)^.YokEt(ANesne^.F0.Kimlik);
      gntIzgara         : PIzgara(ANesne)^.YokEt(ANesne^.F0.Kimlik);
      gntKarmaListe     : PKarmaListe(ANesne)^.YokEt(ANesne^.F0.Kimlik);
      gntKaydirmaCubugu : PKaydirmaCubugu(ANesne)^.YokEt(ANesne^.F0.Kimlik);
      gntListeGorunum   : PListeGorunum(ANesne)^.YokEt(ANesne^.F0.Kimlik);
      gntListeKutusu    : PListeKutusu(ANesne)^.YokEt(ANesne^.F0.Kimlik);
      //gntMasaustu;
      //gntMenu;
      gntOnayKutusu     : POnayKutusu(ANesne)^.YokEt(ANesne^.F0.Kimlik);
      gntPanel          : PPanel(ANesne)^.YokEt(ANesne^.F0.Kimlik);
      gntPencere        : PPencere(ANesne)^.YokEt(ANesne^.F0.Kimlik);
      gntRenkSecici     : PRenkSecici(ANesne)^.YokEt(ANesne^.F0.Kimlik);
      gntResim          : PResim(ANesne)^.YokEt(ANesne^.F0.Kimlik);
      gntResimDugmesi   : PResimDugmesi(ANesne)^.YokEt(ANesne^.F0.Kimlik);
      gntSayfaKontrol   : PSayfaKontrol(ANesne)^.YokEt(ANesne^.F0.Kimlik);
      gntSecimDugmesi   : PSecimDugmesi(ANesne)^.YokEt(ANesne^.F0.Kimlik);
    end;
  end;
begin

  // geçerli bir masaüstü var mı ?
  Masaustu := GAktifMasaustu;
  if not(Masaustu = nil) then
  begin

    // masaüstü nesnesinin alt nesnesi var ise
    if(Masaustu^.F0.AltNesneSayisi > 0) then
    begin

      // masaüstü alt nesnelerini teker teker ara
      for i := 0 to Masaustu^.F0.AltNesneSayisi - 1 do
      begin

        Pencere := PPGorselNesne(Masaustu^.F0.AltNesneBellekAdresi)[i];

        // aranan pencerenin sahibi olan görev ile araştırılan görev kimliği eşit mi?
        // öyle ise pencere ve alt nesnelerini yok et
        if(Pencere^.F0.GorevKimlik = AGorevKimlik) then
        begin

          // pencere nesnesinin SADECE alt nesnelerini yok et
          ANSayisi := Pencere^.F0.AltNesneSayisi;
          ANSayisi := ANSayisi - Pencere^.F0.AltBilesenSayisi;

          // pencere nesnesinin alt nesnesi var mı?
          if(ANSayisi > 0) then
          begin

            // pencere nesnesinin alt nesnelerini ata nesneden çıkar (yok et)
            for j := Pencere^.F0.AltNesneSayisi - 1 downto Pencere^.F0.AltBilesenSayisi do
            begin

              GN := PPGorselNesne(Pencere^.F0.AltNesneBellekAdresi)[j];

              // nesnenin panel olması durumunda panele ait alt nesneleri yok et
              if(GN^.F0.NesneTipi = gntPanel) and (GN^.F0.AltNesneSayisi > 0) then
              begin

                for k := GN^.F0.AltNesneSayisi - 1 downto 0 do
                begin

                  GN2 := PPGorselNesne(GN^.F0.AltNesneBellekAdresi)[k];
                  NesneyiYokEt(GN2);
                end;
              end;

              // panel nesnesini yok et
              NesneyiYokEt(GN);
            end;
          end;

          // pencereyi nesnesini yok et
          NesneyiYokEt(Pencere);

          // bir sonraki döngüye devam etmeden çık
          Exit;
        end;
      end;
    end;
  end;
end;

function TGorselNesne.Olustur(AKullanimTipi: TKullanimTipi; AGNTip: TGNTip;
  AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ACizimModel: TSayi4; AGovdeRenk1, AGovdeRenk2, AYaziRenk: TRenk;
  ABaslik: string): PGorselNesne;
var
  AtaGorselNesne: PGorselNesne;
  GN: PGorselNesne;
  //GorselNesneTipi: TGNTip;
begin

  if(AAtaNesne = nil) then
    AtaGorselNesne := nil
  else AtaGorselNesne := GGorselNesneler.NesneAl(AAtaNesne^.F0.Kimlik);

  // görsel ana yapı nesnesini oluştur
  GN := PGorselNesne(GGorselNesneler.Olustur(AGNTip));
  if(GN = nil) then Exit(nil);

  // görsel nesneyi ata nesneye ekle
  if not(AtaGorselNesne = nil) then
  begin

    if(GGorselNesneler.AtaNesneyeEkle(GN, AtaGorselNesne) = False) then
    begin

      // hata olması durumunda nesneyi yok et ve işlevden çık
      GGorselNesneler.YokEt(GN^.F0.Kimlik);
      Exit(nil);
    end;
  end;

  // temel nesne değerlerini ata
  GN^.F0.GorevKimlik := FAktifGorev;
  GN^.AtaNesne := AtaGorselNesne;

  // nesne olayları öndeğer olarak nesneyi oluşturan programa yönlendirilecek
  // aksi durumda belirtilen çağrı adresine yönlendirilecek
  GN^.OlayCagriAdresi := nil;
  GN^.OlayYonlendirmeAdresi := nil;

  GN^.F0.FHiza := hzYok;

  GN^.F0.FKalinlik.Sol := 0;
  GN^.F0.FKalinlik.Ust := 0;
  GN^.F0.FKalinlik.Sag := 0;
  GN^.F0.FKalinlik.Alt := 0;

  GN^.F0.FAtananAlan.Sol := ASol;
  GN^.F0.FAtananAlan.Ust := AUst;
  GN^.F0.FAtananAlan.Genislik := AGenislik;
  GN^.F0.FAtananAlan.Yukseklik := AYukseklik;

  GN^.F0.FIlkAtananAlan := GN^.F0.FAtananAlan;

  GN^.F0.FKullanimTipi := AKullanimTipi;

  // öndeğer olarak çizim alanı ve alt çizim alanı eşit olarak değerlendiriliyor
  // nesnenin kendisi bu değeri değiştirebilir
  GN^.F0.FCizimAlani.Sol := 0;
  GN^.F0.FCizimAlani.Ust := 0;
  GN^.F0.FCizimAlani.Sag := GN^.F0.FAtananAlan.Genislik - 1;
  GN^.F0.FCizimAlani.Alt := GN^.F0.FAtananAlan.Yukseklik - 1;


  if(GN^.F0.FKullanimTipi = ktNesne) then
  begin

    if(AtaGorselNesne = nil) then
    begin

      GN^.F0.FCizimBaslangic.Sol := 0;
      GN^.F0.FCizimBaslangic.Ust := 0;
    end
    else
    begin

      GN^.F0.FCizimBaslangic.Sol := AtaGorselNesne^.F0.FCizimBaslangic.Sol +
        AtaGorselNesne^.F0.FKalinlik.Sol + ASol;
      GN^.F0.FCizimBaslangic.Ust := AtaGorselNesne^.F0.FCizimBaslangic.Ust +
        AtaGorselNesne^.F0.FKalinlik.Ust + AUst;
    end;
  end
  else
  // bileşen
  begin

    GN^.F0.FCizimBaslangic.Sol := AtaGorselNesne^.F0.FCizimBaslangic.Sol + ASol;
    GN^.F0.FCizimBaslangic.Ust := AtaGorselNesne^.F0.FCizimBaslangic.Ust + AUst;
  end;

  GN^.F0.FHiza := hzYok;
  GN^.F0.FHizaAlani := GN^.F0.FCizimAlani;

  // nesnenin alt bileşen sayısı
  GN^.F0.AltBilesenSayisi := 0;

  // alt nesnelerin bellek adresi (nil = bellek oluşturulmadı)
  GN^.F0.AltNesneBellekAdresi := nil;

  // nesnenin alt nesne sayısı
  GN^.F0.AltNesneSayisi := 0;

  // nesnenin üzerine gelindiğinde görüntülenecek fare göstergesi
  GN^.F0.FareImlecTipi := fitOK;

  // nesnenin görünüm durumu
  GN^.F0.Gorunum := False;

  // nesnenin başlık değeri
  GN^.F0.FYaziHiza.Yatay := yhOrta;
  GN^.F0.FYaziHiza.Dikey := dhOrta;
  GN^.F0.Baslik := ABaslik;

  // nesnenin renk değerleri
  GN^.FCizimModel := ACizimModel;
  GN^.FGovdeRenk1 := AGovdeRenk1;
  GN^.FGovdeRenk2 := AGovdeRenk2;
  GN^.FYaziRenk := AYaziRenk;

  GN^.F0.FCiziliyor := False;

  GN^.FEtiket := 0;

  // nesne adresini geri döndür
  Result := GN;
end;

procedure TGorselNesne.Goster;
var
  Pencere: PPencere;
  GorselAnaYapi: PGorselNesne;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  GorselAnaYapi := PGorselNesne(GGorselNesneler.NesneTipiniKontrolEt(F0.Kimlik, F0.NesneTipi));
  if(GorselAnaYapi = nil) then Exit;

  // nesne görünür durumda mı ?
  if(GorselAnaYapi^.F0.Gorunum = False) then
  begin

    // görsel ana yapı nesnesinin görünürlüğünü aktifleştir
    GorselAnaYapi^.F0.Gorunum := True;

    // ata nesne görünür durumda mı?
    if(GorselAnaYapi^.AtaNesneGorunurMu) then
    begin

      // nesnenin sahibi olan pencere nesnesini al
      Pencere := EnUstPencereNesnesiniAl(GorselAnaYapi);
      if not(Pencere = nil) then Pencere^.Guncelle;
    end;
  end;
end;

procedure TGorselNesne.Gizle;
var
  Pencere: PPencere;
  GorselAnaYapi: PGorselNesne;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  GorselAnaYapi := PGorselNesne(GGorselNesneler.NesneTipiniKontrolEt(F0.Kimlik, F0.NesneTipi));
  if(GorselAnaYapi = nil) then Exit;

  // nesne görünür durumda mı ?
  if(GorselAnaYapi^.F0.Gorunum = True) then
  begin

    // görsel ana yapı nesnesinin görünürlüğünü aktifleştir
    GorselAnaYapi^.F0.Gorunum := False;

    // ata nesne görünür durumda mı?
    if(GorselAnaYapi^.AtaNesneGorunurMu) then
    begin

      // nesnenin sahibi olan pencere nesnesini al
      Pencere := EnUstPencereNesnesiniAl(GorselAnaYapi);
      if not(Pencere = nil) then Pencere^.Guncelle;
    end;
  end;
end;

{==============================================================================
  görsel ana nesnesini çizer
 ==============================================================================}
procedure TGorselNesne.Ciz;
var
  GN: PGorselNesne;
  CizimAlani: TAlan;
begin

  GN := GGorselNesneler.NesneAl(F0.Kimlik);
  if(GN = nil) then Exit;

  CizimAlani := GN^.F0.FCizimAlani;

  // FCizimModel = 0 = hiçbir çizim yapma
  if(GN^.FCizimModel > 0) then
  begin

    // FCizimModel = 2 = kenarlığı çiz ve içeriği doldur
    if(GN^.FCizimModel = 2) then

      GN^.DikdortgenDoldur(GN, CizimAlani, FGovdeRenk1, FGovdeRenk2)

    // FCizimModel = 3 = kenarlığı çiz ve içeriği doldur
    else if(GN^.FCizimModel = 3) then

      GN^.DikdortgenDoldur(GN, CizimAlani.Sol, CizimAlani.Ust, CizimAlani.Sag,
        CizimAlani.Alt, FGovdeRenk1, FGovdeRenk2)

    // FCizimModel = 4 = artan renk ile (eğimli) doldur
    else if(GN^.FCizimModel = 4) then
      GN^.EgimliDoldur3(GN, CizimAlani, FGovdeRenk1, FGovdeRenk2);

    // görsel ana yapı başlığını yaz
    if not(GN^.FCizimModel = 2) then
      if(Length(GN^.F0.Baslik) > 0) then YaziYaz(GN, GN^.F0.FYaziHiza, CizimAlani,
        F0.Baslik, FYaziRenk);
  end;
end;

procedure TGorselNesne.BoyutlariYenidenHesapla;
var
  GorselAtaNesne, GN: PGorselNesne;
begin

  GN := GGorselNesneler.NesneAl(F0.Kimlik);
  if(GN = nil) then Exit;

  GN^.F0.FCizimAlani.Sol := 0;
  GN^.F0.FCizimAlani.Ust := 0;
  GN^.F0.FCizimAlani.Sag := GN^.F0.FAtananAlan.Genislik - 1;
  GN^.F0.FCizimAlani.Alt := GN^.F0.FAtananAlan.Yukseklik - 1;

  GorselAtaNesne := GN^.AtaNesne;

  if(GorselAtaNesne^.F0.NesneTipi = gntPencere) then
  begin

    GN^.F0.FCizimBaslangic.Sol := GN^.AtaNesne^.F0.FKalinlik.Sol + GN^.F0.FAtananAlan.Sol;
    GN^.F0.FCizimBaslangic.Ust := GN^.AtaNesne^.F0.FKalinlik.Ust + GN^.F0.FAtananAlan.Ust;
  end
  else
  begin

    GN^.F0.FCizimBaslangic.Sol := GN^.AtaNesne^.F0.FCizimBaslangic.Sol +
      GN^.AtaNesne^.F0.FKalinlik.Sol + GN^.F0.FAtananAlan.Sol;
    GN^.F0.FCizimBaslangic.Ust := GN^.AtaNesne^.F0.FCizimBaslangic.Ust +
      GN^.AtaNesne^.F0.FKalinlik.Ust + GN^.F0.FAtananAlan.Ust;
  end;
end;

procedure TGorselNesne.HizaAlaniniSifirla;
var
  GN: PGorselNesne;
begin

  GN := GGorselNesneler.NesneAl(F0.Kimlik);
  if(GN = nil) then Exit;

  GN^.F0.FHizaAlani.Sol := GN^.F0.FCizimAlani.Sol;
  GN^.F0.FHizaAlani.Ust := GN^.F0.FCizimAlani.Ust;
  GN^.F0.FHizaAlani.Sag := GN^.F0.FCizimAlani.Sag;
  GN^.F0.FHizaAlani.Alt := GN^.F0.FCizimAlani.Alt;
end;

procedure TGorselNesne.Hizala;
var
  GorselAtaNesne, GN: PGorselNesne;
begin

  GN := GGorselNesneler.NesneAl(F0.Kimlik);
  if(GN = nil) then Exit;

  GorselAtaNesne := GN^.AtaNesne;

  GN^.F0.FAtananAlan := GN^.F0.FIlkAtananAlan;

  if(GN^.F0.FHiza = hzSol) then
  begin

    //SISTEM_MESAJ(RENK_KIRMIZI, 'Boyut: %d', [GorselAtaNesne^.FBoyut.Yukseklik]);

    // nesnenin hesaplanması
    GN^.F0.FAtananAlan.Sol := GorselAtaNesne^.F0.FHizaAlani.Sol;
    GN^.F0.FAtananAlan.Ust := GorselAtaNesne^.F0.FHizaAlani.Ust;
    // nesnenin kendi genişliği kullanılacak
    GN^.F0.FAtananAlan.Yukseklik := (GorselAtaNesne^.F0.FHizaAlani.Alt - GorselAtaNesne^.F0.FHizaAlani.Ust) + 1;
    GN^.BoyutlariYenidenHesapla;

    // üst nesnenin yeniden boyutlandırılması
    GorselAtaNesne^.F0.FHizaAlani.Sol := GorselAtaNesne^.F0.FHizaAlani.Sol + GN^.F0.FAtananAlan.Genislik;
  end
  else if(GN^.F0.FHiza = hzUst) then
  begin

    GN^.F0.FAtananAlan.Sol := GorselAtaNesne^.F0.FHizaAlani.Sol;
    GN^.F0.FAtananAlan.Ust := GorselAtaNesne^.F0.FHizaAlani.Ust;
    GN^.F0.FAtananAlan.Genislik := (GorselAtaNesne^.F0.FHizaAlani.Sag - GorselAtaNesne^.F0.FHizaAlani.Sol) + 1;
    // nesnenin kendi yüksekliği kullanılacak
    GN^.BoyutlariYenidenHesapla;

    GorselAtaNesne^.F0.FHizaAlani.Ust := GorselAtaNesne^.F0.FHizaAlani.Ust + GN^.F0.FAtananAlan.Yukseklik;
  end
  else if(GN^.F0.FHiza = hzSag) then
  begin

    // nesnenin hesaplanması
    GN^.F0.FAtananAlan.Sol := (GorselAtaNesne^.F0.FHizaAlani.Sag - GN^.F0.FAtananAlan.Genislik) + 1;
    GN^.F0.FAtananAlan.Ust := GorselAtaNesne^.F0.FHizaAlani.Ust;
    // nesnenin kendi genişliği kullanılacak
    GN^.F0.FAtananAlan.Yukseklik := (GorselAtaNesne^.F0.FHizaAlani.Alt - GorselAtaNesne^.F0.FHizaAlani.Ust) + 1;
    GN^.BoyutlariYenidenHesapla;

    // üst nesnenin yeniden boyutlandırılması
    GorselAtaNesne^.F0.FHizaAlani.Sag := GorselAtaNesne^.F0.FHizaAlani.Sag - GN^.F0.FAtananAlan.Genislik;
  end
  else if(GN^.F0.FHiza = hzAlt) then
  begin

    GN^.F0.FAtananAlan.Sol := GorselAtaNesne^.F0.FHizaAlani.Sol;
    GN^.F0.FAtananAlan.Ust := (GorselAtaNesne^.F0.FHizaAlani.Alt - GN^.F0.FAtananAlan.Yukseklik) + 1;
    GN^.F0.FAtananAlan.Genislik := (GorselAtaNesne^.F0.FHizaAlani.Sag - GorselAtaNesne^.F0.FHizaAlani.Sol) + 1;
    // nesnenin kendi yüksekliği kullanılacak
    GN^.BoyutlariYenidenHesapla;

    GorselAtaNesne^.F0.FHizaAlani.Alt := GorselAtaNesne^.F0.FHizaAlani.Alt - GN^.F0.FAtananAlan.Yukseklik;
  end
  else if(GN^.F0.FHiza = hzTum) then
  begin

    GN^.F0.FAtananAlan.Sol := GorselAtaNesne^.F0.FHizaAlani.Sol;
    GN^.F0.FAtananAlan.Ust := GorselAtaNesne^.F0.FHizaAlani.Ust;
    GN^.F0.FAtananAlan.Genislik := (GorselAtaNesne^.F0.FHizaAlani.Sag - GorselAtaNesne^.F0.FHizaAlani.Sol) + 1;
    GN^.F0.FAtananAlan.Yukseklik := (GorselAtaNesne^.F0.FHizaAlani.Alt - GorselAtaNesne^.F0.FHizaAlani.Ust) + 1;
    GN^.BoyutlariYenidenHesapla;

//    GorselAtaNesne^.FHizaAlani.Alt := GorselAtaNesne^.FHizaAlani.Alt - GorselNesne^.FBoyut.Yukseklik;
  end else GN^.BoyutlariYenidenHesapla;
end;

{==============================================================================
  nesnenin pencereye (0, 0 koordinatı) bağlı gerçek koordinatlarını alır
 ==============================================================================}
function TGorselNesne.CizimAlaniniAl(AKimlik: TKimlik): TAlan;
var
  Pencere: PPencere;
  GN: PGorselNesne;
begin

  // talepte bulunan nesnenin kimlik değerini kontrol et
  GN := GGorselNesneler.NesneAl(AKimlik);

  if((GN^.F0.NesneTipi = gntMasaustu) or (GN^.F0.NesneTipi = gntPencere) or
    (GN^.F0.NesneTipi = gntMenu) or (GN^.F0.NesneTipi = gntAcilirMenu)) then
  begin

    // genişlik ve yükseklik değerleri alınıyor
    Result.Sol := GN^.F0.FKalinlik.Sol;
    Result.Ust := GN^.F0.FKalinlik.Ust;
    Result.Sag := Result.Sol + GN^.F0.FAtananAlan.Genislik;
    Result.Alt := Result.Ust + GN^.F0.FAtananAlan.Yukseklik;
  end
  else
  begin

    {GorselNesne2 := GorselNesne;
    Result.Sol := 0;
    Result.Ust := 0;
    Result.Sag := 0;
    Result.Alt := 0;
    repeat

      Result.Sol := Result.Sol + GorselNesne2^.FKonum.Sol;
      Result.Ust := Result.Ust + GorselNesne2^.FBoyutlar.Ust2;

      GorselNesne2 := GorselNesne2^.AtaNesne;
      NTip := GorselNesne2^.F0.NesneTipi;
    until (NTip = gntMasaustu) or (NTip = gntPencere) or (NTip = gntMenu) or (NTip = gntAcilirMenu);

    Result.Sol := Result.Sol + GorselNesne2^.FAltNesneCizimAlan.Sol;
    Result.Ust := Result.Ust + GorselNesne2^.FAltNesneCizimAlan.Ust;
    Result.Sag := Result.Sol + GorselNesne^.FBoyutlar.Genislik2;
    Result.Alt := Result.Ust + GorselNesne^.FBoyut.Yukseklik;}

    Pencere := EnUstPencereNesnesiniAl(GN);

    Result.Sol := GN^.F0.FCizimAlani.Sol - Pencere^.F0.FCizimAlani.Sol;
    Result.Ust := GN^.F0.FCizimAlani.Ust - Pencere^.F0.FCizimAlani.Ust;
    Result.Sag := GN^.F0.FCizimAlani.Sag - Pencere^.F0.FCizimAlani.Sol;
    Result.Alt := GN^.F0.FCizimAlani.Alt - Pencere^.F0.FCizimAlani.Ust;
  end;
end;

{==============================================================================
  nesnenin çizilebilir alanının koordinatlarını alır
 ==============================================================================}
function TGorselNesne.CizimAlaniniAl2(AKimlik: TKimlik): TAlan;
//var
//  GN: PGorselNesne;
begin

  //GN := GGorselNesneler.NesneAl(AKimlik);

  // nesnenin üst nesneye bağlı koordinatlarını al
  Result := CizimAlaniniAl(AKimlik);
end;

{==============================================================================
  belirtilen nesneden itibaren masaüstüne kadar tüm nesnelerin görünürlüğünü
  kontrol eder. (nesnenin kendisi de dahil)
 ==============================================================================}
function TGorselNesne.AtaNesneGorunurMu: Boolean;
var
  GN: PGorselNesne;
begin

  GN := @Self;

  repeat

    // nesne görünür durumdaysa AtaNesne nesnesini al
    if(GN^.F0.Gorunum) then

      GN := GN^.AtaNesne
    else
    begin

      // aksi durumda çık
      Result := False;
      Exit;
    end;

    // tüm nesneler test edildiyse olumlu yanıt ile geri dön
    if(GN = nil) then Exit(True);

  until (True = False);
end;

{==============================================================================
  fare göstergesinin nesnenin olay alanının içerisinde olup
  olmadığını kontrol eder
 ==============================================================================}
function TGorselNesne.FareNesneOlayAlanindaMi(AGorselNesne: PGorselNesne): Boolean;
var
  GN: PGorselNesne;
  Alan: TAlan;
begin

  GN := AGorselNesne;

  Alan.Sol := GN^.F0.FCizimBaslangic.Sol;
  Alan.Ust := GN^.F0.FCizimBaslangic.Ust;

  if(GN^.FTuvalNesne^.F0.NesneTipi = gntPencere) or
    (GN^.FTuvalNesne^.F0.NesneTipi = gntMenu) or
    (GN^.FTuvalNesne^.F0.NesneTipi = gntAcilirMenu) then
  begin

    Alan.Sol := Alan.Sol + GN^.FTuvalNesne^.F0.FAtananAlan.Sol;
    Alan.Ust := Alan.Ust + GN^.FTuvalNesne^.F0.FAtananAlan.Ust;
  end;

  Alan.Sag := Alan.Sol + GN^.F0.FCizimAlani.Sag;
  Alan.Alt := Alan.Ust + GN^.F0.FCizimAlani.Alt;

  //SISTEM_MESAJ(RENK_KIRMIZI, 'Sol %d', [Alan.Sol]);
  //SISTEM_MESAJ(RENK_KIRMIZI, 'Ust %d', [Alan.Ust]);

  // öndeğer dönüş değeri
  Result := False;

  // fare belirtilen koordinatlar içerisinde mi ?
  if(GFareSurucusu.YatayKonum < Alan.Sol) then Exit;
  if(GFareSurucusu.YatayKonum > Alan.Sag) then Exit;
  if(GFareSurucusu.DikeyKonum < Alan.Ust) then Exit;
  if(GFareSurucusu.DikeyKonum > Alan.Alt) then Exit;

  //SISTEM_MESAJ(RENK_KIRMIZI, 'İçeride Tamam', []);

  Result := True;
end;

{==============================================================================
  X, Y koordinatının Rect alanı içerisinde olup olmadığını test eder
 ==============================================================================}
function TGorselNesne.NoktaAlanIcerisindeMi(NoktaA1, NoktaB1: TISayi4;
  AAlan: TAlan): Boolean;
begin

  Result := False;

  // fare belirtilen koordinatlar içerisinde mi ?
  if(NoktaA1 < AAlan.Sol) then Exit;
  if(NoktaA1 > AAlan.Sag) then Exit;
  if(NoktaB1 < AAlan.Ust) then Exit;
  if(NoktaB1 > AAlan.Alt) then Exit;

  Result := True;
end;

{==============================================================================
  grafiksel koordinattaki pixeli işaretler (boyar)
 ==============================================================================}
procedure TGorselNesne.PixelYaz(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4; ARenk: TRenk);
begin

  GEkranKartSurucusu.NoktaYaz(AGorselNesne, ASol, AUst, ARenk, True);
end;

{==============================================================================
  grafiksel ekrana karakter yazar
 ==============================================================================}
procedure TGorselNesne.HarfYaz(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4;
  AKarakter: Char; AZeminRengi, AYaziRengi: TRenk);
var
  Karakter: TKarakter;
  KarakterAdres: PByte;
  X, Y,
  XB, YB,
  XS, YS: TISayi4;
begin

  // karakterler 0..255 aralığındadır.
	Karakter := KarakterListesi[TSayi1(AKarakter)];

  // eğer karakter boşluk veya çizim gerektirmeyen karakter ise çık
  if(Karakter.Yukseklik = 0) or (Karakter.Genislik = 0) then Exit;

  // (varsa) zemini belirtilen renk ile boya
  { TODO - aktifleştirildiğinde kilitlenmeler oluyor }
  if(AZeminRengi <> RENK_YOK) then
  begin

    XB := ASol;
    XS := XB + 8;
    YB := AUst;
    YS := YB + 16;

    for Y := YB to YS - 1 do
    begin

		  for X := XB to XS - 1 do
      begin

        // ilgili pixeli belirtilen renkle işaretle (boya)
			  GEkranKartSurucusu.NoktaYaz(AGorselNesne, X, Y, AZeminRengi, True);
      end;
    end;
  end;

  // karakterin yatay başlangıç / bitiş koordinatlarını hesapla
  XB := ASol + Karakter.YT;
  XS := XB + Karakter.Genislik;

  // karakterin dikey başlangıç / bitiş koordinatlarını hesapla
  YB := AUst + Karakter.DT;
  YS := YB + Karakter.Yukseklik;

  // karakterin pixel haritasının bellek adresine konumlan
  KarakterAdres := Karakter.Adres;

  for Y := YB to YS - 1 do
  begin

		for X := XB to XS - 1 do
    begin

      // ilgili pixeli belirtilen renkle işaretle (boya)
			if(KarakterAdres^ = 1) then GEkranKartSurucusu.NoktaYaz(AGorselNesne, X, Y,
        AYaziRengi, True);

      // bir sonraki pixele konumlan
      Inc(KarakterAdres)
    end;
  end;
end;

{==============================================================================
  grafiksel ekrana karakter katarı yazar
 ==============================================================================}
procedure TGorselNesne.Kesme_YaziYaz(ASol, AUst: TISayi4; AKarakterDizi: string;
  ARenk: TRenk);
var
  Alan: TAlan;
begin

  Alan := CizimAlaniniAl2(F0.Kimlik);
  YaziYaz(FAtaNesne, Alan.Sol + ASol, Alan.Ust + AUst, AKarakterDizi, ARenk);
end;

{==============================================================================
  grafiksel ekrana yazı yazar
 ==============================================================================}
procedure TGorselNesne.YaziYaz(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4; AYazi: string;
  ARenk: TRenk);
var
  Sol, Ust, YaziU: TISayi4;
begin

  // karakter katarının uzunluğunu al
  YaziU := Length(AYazi);
  if(YaziU = 0) then Exit;

  Ust := ASol;
  for Sol := 1 to YaziU do
  begin

    // karakteri yaz
    HarfYaz(AGorselNesne, Ust, AUst, AYazi[Sol], RENK_YOK, ARenk);

    // karakter genişliğini genişlik değerine ekle
    Ust := Ust + 8;
  end;
end;

{==============================================================================
  grafiksel ekrana hizalayarak yazı yazar
 ==============================================================================}
procedure TGorselNesne.YaziYaz(AGorselNesne: PGorselNesne; AYaziHiza: TYaziHiza;
  AAlan: TAlan; AYazi: string; ARenk: TRenk);
var
  i, j, Sol, Ust: TISayi4;
begin

  // karakter katarının uzunluğunu al
  j := Length(AYazi);
  if(j = 0) then Exit;

  if(AYaziHiza.Yatay = yhSag) then
    Sol := AAlan.Sag - (j * 8)
  else if(AYaziHiza.Yatay = yhOrta) then
    Sol := AAlan.Sol + (((AAlan.Sag - AAlan.Sol) + 1) div 2) - ((j * 8) div 2)
  else //if(AYaziHiza.Yatay = yhSol) then
    Sol := AAlan.Sol;

  if(AYaziHiza.Dikey = dhAlt) then
    Ust := AAlan.Alt - 16
  else if(AYaziHiza.Dikey = dhOrta) then
    Ust := AAlan.Ust + (((AAlan.Alt - AAlan.Ust) + 1) div 2) - (16 div 2)
  else //if(AYaziHiza.Dikey = dhUst) then
    Ust := AAlan.Ust;

  for i := 1 to j do
  begin

    // karakteri yaz
    HarfYaz(AGorselNesne, Sol, Ust, AYazi[i], RENK_YOK, ARenk);

    // karakter genişliğini genişlik değerine ekle
    Sol := Sol + 8;
  end;
end;

{==============================================================================
  dikdörtgensel (4 nokta) grafiksel ekrana karakter katarı yazar
 ==============================================================================}
// Önemli bilgi: şu aşamada çoklu satır işlevi olmadığı için Y1 -> Y2 kontrolü YAPILMAMAKTADIR
procedure TGorselNesne.AlanaYaziYaz(AGorselNesne: PGorselNesne; AAlan: TAlan;
  ASol, AUst: TISayi4; AKarakterDizi: string; ARenk: TRenk);
var
  KarakterDiziUz, i,
  Sol, Ust: TISayi4;
begin

  {
      AAlan.Sol:AAlan.Ust = sol üst köşe (örn: 100, 100)
      AAlan.Sag:AAlan.Alt = sağ alt köşe (örn: 200, 200)
      ASol = çizim AAlan.Sol'den kaç pixel uzaklıktan başlayacak (örn: 10 = 110)
      AUst = çizim AAlan.Ust'den kaç pixel uzaklıktan başlayacak (örn: 12 = 112)
  }

  // karakter katarının uzunluğunu al
  KarakterDiziUz := Length(AKarakterDizi);
  if(KarakterDiziUz = 0) then Exit;

  Sol := AAlan.Sol + ASol;
  Ust := AAlan.Ust + AUst;

  if(Sol >= AAlan.Sag) then Exit;
  if(Ust >= AAlan.Alt) then Exit;

  for i := 1 to KarakterDiziUz do
  begin

    if((Sol + 8) >= AAlan.Sag) then Break;

    // karakteri yaz
    HarfYaz(AGorselNesne, Sol, Ust, AKarakterDizi[i], RENK_YOK, ARenk);

    // karakter genişliğini x değerine ekle
    Sol := Sol + 8;
  end;
end;

{==============================================================================
  grafiksel ekrana integer sayı yazar
 ==============================================================================}
procedure TGorselNesne.SayiYaz10(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4;
  ASayi: TISayi4; ARenk: TRenk);
var
  Deger: array[0..11] of Char;
begin

  // desimal değeri string değere çevir
  Deger := IntToStr(ASayi);

  // sayısal değeri ekrana yaz
  YaziYaz(AGorselNesne, ASol, AUst, Deger, ARenk);
end;

{==============================================================================
  grafiksel ekrana 16lı tabanda sayı yazar
 ==============================================================================}
procedure TGorselNesne.Kesme_SayiYaz16(ASol, AUst: TISayi4; AOnEkYaz: LongBool;
  AHaneSayisi, ADeger: TISayi4; ARenk: TRenk);
var
  Deger: string[10];
  Alan: TAlan;
begin

  // hexadesimal değeri string değere çevir
  if(AOnEkYaz) then
    Deger := '0x' + hexStr(ADeger, AHaneSayisi)
  else Deger := hexStr(ADeger, AHaneSayisi);

  Alan := CizimAlaniniAl2(F0.Kimlik);

  // sayısal değeri ekrana yaz
  YaziYaz(FAtaNesne, Alan.Sol + ASol, Alan.Ust + AUst, Deger, ARenk);
end;

{==============================================================================
  grafiksel ekrana hexadesimal sayı yazar
 ==============================================================================}
procedure TGorselNesne.SayiYaz16(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4;
  AOnEkYaz: LongBool; AHaneSayisi, ADeger: TISayi4; ARenk: TRenk);
var
  Deger: string[10];
begin

  // hexadesimal değeri string değere çevir
  if(AOnEkYaz) then
    Deger := '0x' + hexStr(ADeger, AHaneSayisi)
  else Deger := hexStr(ADeger, AHaneSayisi);

  // sayısal değeri ekrana yaz
  YaziYaz(AGorselNesne, ASol, AUst, Deger, ARenk);
end;

{==============================================================================
  grafiksel ekrana belirtilen saat değerini yazar
 ==============================================================================}
procedure TGorselNesne.Kesme_SaatYaz(ASol, AUst: TISayi4; ASaat: TSaat; ARenk: TRenk);
var
  Saat: string[8];
  Alan: TAlan;
begin

  // saat değerini karakter katarına çevir
  Saat := TimeToStr(ASaat);

  Alan := CizimAlaniniAl2(F0.Kimlik);

  // saat değerini belirtilen koordinatlara yaz
  YaziYaz(FAtaNesne, Alan.Sol + ASol, Alan.Ust + AUst, Saat, ARenk);
end;

{==============================================================================
  grafiksel ekrana belirtilen saat değerini yazar
 ==============================================================================}
procedure TGorselNesne.SaatYaz(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4;
  ASaat: TSaat; ARenk: TRenk);
var
  Saat: string[8];
begin

  // saat değerini karakter katarına çevir
  Saat := TimeToStr(ASaat);

  // saat değerini belirtilen koordinatlara yaz
  YaziYaz(AGorselNesne, ASol, AUst, Saat, ARenk);
end;

{==============================================================================
  grafiksel ekrana mac adres değerini yazar
 ==============================================================================}
procedure TGorselNesne.MACAdresiYaz(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4;
  AMACAdres: TMACAdres; ARenk: TRenk);
var
  MACAdres: string[17];
begin

  // MAC adres değerini karakter katarına çevir
  MACAdres := MAC_KarakterKatari(AMACAdres);

  // MAC adres değerini belirtilen koordinatlara yaz
  YaziYaz(AGorselNesne, ASol, AUst, MACAdres, ARenk);
end;

{==============================================================================
  grafiksel ekrana ip adres değerini yazar
 ==============================================================================}
procedure TGorselNesne.IPAdresiYaz(AGorselNesne: PGorselNesne; ASol, AUst: TSayi4;
  AIPAdres: TIP4Adres; ARenk: TRenk);
var
  IPAdres: string[15];
begin

  // IP adres değerini karakter katarına çevir
  IPAdres := IP_KarakterKatari4(AIPAdres);

  // ip adres değerini belirtilen koordinatlara yaz
  YaziYaz(AGorselNesne, ASol, AUst, IPAdres, ARenk);
end;

{==============================================================================
  nesneye belirtilen renkte dikdörtgen çizer
 ==============================================================================}
procedure TGorselNesne.Dikdortgen(AGorselNesne: PGorselNesne; ACizgiTipi: TCizgiTipi;
  AAlan: TAlan; ACizgiRengi: TRenk);
begin

  // üst yatay çizgiyi çiz
  YatayCizgi(AGorselNesne, ACizgiTipi, AAlan.Sol, AAlan.Ust, AAlan.Sag, ACizgiRengi);

  // sol dikey çizgiyi çiz
  DikeyCizgi(AGorselNesne, ACizgiTipi, AAlan.Sol, AAlan.Ust, AAlan.Alt, ACizgiRengi);

  // alt yatay çizgiyi çiz
  YatayCizgi(AGorselNesne, ACizgiTipi, AAlan.Sag, AAlan.Alt, AAlan.Sol, ACizgiRengi);

  // sağ dikey çizgiyi çiz
  DikeyCizgi(AGorselNesne, ACizgiTipi, AAlan.Sag, AAlan.Alt, AAlan.Ust, ACizgiRengi);
end;

{==============================================================================
  nesnenin dikdörtgensel olarak sınırlandırılmış alanına belirtilen renkte içi
  doldurulmuş dikdörtgen çizer. (not: test edilecek)
 ==============================================================================}
procedure TGorselNesne.Doldur4(AGorselNesne: PGorselNesne; AAlan: TAlan; ASol, AUst,
  ASag, AAlt: TISayi4; ACizgiRengi, ADolguRengi: TRenk);
var
  Alan: TAlan;
  i, j, Sol, Ust, Sag, Alt: TISayi4;
begin

  // çizim koordinatlarınının sınırların içerisinde olup olmadığını kontrol et
  if(ASol < AAlan.Sol) then
    Sol := AAlan.Sol
  else Sol := ASol;

  if(AUst < AAlan.Ust) then
    Ust := AAlan.Ust
  else Ust := AUst;

  if(ASag > AAlan.Sag) then
    Sag := AAlan.Sag
  else Sag := ASag;

  if(AAlt > AAlan.Alt) then
    Alt := AAlan.Alt
  else Alt := AAlt;

  // dış kenarlık
  Alan.Sol := Sol;
  Alan.Ust := Ust;
  Alan.Sag := Sag;
  Alan.Alt := Alt;
  Dikdortgen(AGorselNesne, ctDuz, Alan, ACizgiRengi);

  // iç kenarlık
  Inc(Sol);
  Inc(Ust);
  Dec(Sag);
  Dec(Alt);

  for j := Ust to Alt do
  begin

    for i := Sol to Sag do
    begin

      GEkranKartSurucusu.NoktaYaz(@Self, i, j, ADolguRengi, True);
    end;
  end;
end;

{==============================================================================
  nesneye belirtilen renkte içi doldurulmuş dikdörtgen çizer
 ==============================================================================}
procedure TGorselNesne.DikdortgenDoldur(AGorselNesne: PGorselNesne; ASol, AUst,
  ASag, AAlt: TISayi4; ACizgiRengi, ADolguRengi: TRenk);
var
  Alan: TAlan;
begin

  Alan.Sol := ASol;
  Alan.Ust := AUst;
  Alan.Sag := ASag;
  Alan.Alt := AAlt;
  DikdortgenDoldur(AGorselNesne, Alan, ACizgiRengi, ADolguRengi);
end;

{==============================================================================
  nesneye belirtilen renkte içi doldurulmuş dikdörtgen çizer
 ==============================================================================}
procedure TGorselNesne.DikdortgenDoldur(AGorselNesne: PGorselNesne; AAlan: TAlan;
  ACizgiRengi, ADolguRengi: TRenk);
var
  i, j: TISayi4;
begin

  // dış kenarlık
  Dikdortgen(AGorselNesne, ctDuz, AAlan, ACizgiRengi);

  // iç kenarlık
  Inc(AAlan.Sol);
  Inc(AAlan.Ust);
  Dec(AAlan.Sag);
  Dec(AAlan.Alt);

  for j := AAlan.Ust to AAlan.Alt do
  begin

    for i := AAlan.Sol to AAlan.Sag do
    begin

      GEkranKartSurucusu.NoktaYaz(AGorselNesne, i, j, ADolguRengi, True);
    end;
  end;
end;

procedure TGorselNesne.BMPGoruntusuCiz(AGNTip: TGNTip; AGorselNesne: PGorselNesne;
  AGoruntuYapi: TGoruntuYapi);
var
  BMP: TBMP;
begin

  BMP := TBMP.Create;
  BMP.ResimCiz(AGNTip, AGorselNesne, AGoruntuYapi);
  BMP.Destroy;
end;

{==============================================================================
  nesneye belirtilen renkte çizgi çizer
 ==============================================================================}
// https://rosettacode.org/wiki/Bitmap/Bresenham%27s_line_algorithm
// procedure drawLine (bitmap : TBitmap; xStart, yStart, xEnd, yEnd : integer; color : TAlphaColor);
procedure TGorselNesne.Cizgi(AGorselNesne: PGorselNesne; ACizgiTipi: TCizgiTipi;
  ASol, AUst, ASag, AAlt: TISayi4; ACizgiRengi: TRenk);
// Bresenham's Line Algorithm.  Byte, March 1988, pp. 249-253.
// Modified from http://www.efg2.com/Lab/Library/Delphi/Graphics/Bresenham.txt and tested.
var
  a, b: TISayi4;          // displacements in x and y
  d: TISayi4;             // decision variable
  diag_inc: TISayi4;      // d's increment for diagonal steps
  dx_diag: TISayi4;       // diagonal x step for next pixel
  dx_nondiag: TISayi4;    // nondiagonal x step for next pixel
  dy_diag: TISayi4;       // diagonal y step for next pixel
  dy_nondiag: TISayi4;    // nondiagonal y step for next pixel
  i: TISayi4;             // loop index
  nondiag_inc: TISayi4;   // d's increment for nondiagonal steps
  swap: TISayi4;          // temporary variable for swap
  x,y,                    // current x and y coordinates
  AdimSayisi: TISayi4;
  Isaretle: Boolean;
begin

  Isaretle := True;
  AdimSayisi := 0;

  x := ASol;                // line starting point}
  y := AUst;

  // Determine drawing direction and step to the next pixel.
  a := ASag - ASol;           // difference in x dimension
  b := AAlt - AUst;           // difference in y dimension

  // Determine whether end point lies to right or left of start point.
  if a < 0 then           // drawing towards smaller x values?
  begin

    a := -a;              // make 'a' positive
    dx_diag := -1
  end else dx_diag := 1;

  // Determine whether end point lies above or below start point.
  if b < 0 then           // drawing towards smaller x values?
  begin

    b := -b;              // make 'a' positive
    dy_diag := -1
  end else dy_diag := 1;

  // Identify octant containing end point.
  if a < b then
  begin

    swap := a;
    a := b;
    b := swap;
    dx_nondiag := 0;
    dy_nondiag := dy_diag
  end
  else
  begin

    dx_nondiag := dx_diag;
    dy_nondiag := 0
  end;

  d := b + b - a;         // initial value for d is 2*b - a
  nondiag_inc := b + b;   // set initial d increment values
  diag_inc := b + b - a - a;

  for i := 0 to a do
  begin                   // draw the a+1 pixels

    if(Isaretle) then GEkranKartSurucusu.NoktaYaz(AGorselNesne, x, y,
      ACizgiRengi, True);

    if(ACizgiTipi = ctNokta) then
    begin

      Inc(AdimSayisi);
      if(AdimSayisi = NOKTA_BOSLUKSAYISI) then
      begin

        Isaretle := not Isaretle;
        AdimSayisi := 0;
      end;
    end;

    if d < 0 then         // is midpoint above the line?
    begin                 // step nondiagonally

      x := x + dx_nondiag;
      y := y + dy_nondiag;
      d := d + nondiag_inc// update decision variable
    end
    else
    begin                 // midpoint is above the line; step diagonally}

      x := x + dx_diag;
      y := y + dy_diag;
      d := d + diag_inc
    end;
  end;
end;

{==============================================================================
  nesneye daire şekli çizer
 ==============================================================================}
procedure TGorselNesne.Daire(ASol, AUst, AYariCap: TISayi4; ARenk: TRenk);
var
  Sol, Ust, YariCap: TISayi4;
begin

  Sol := 0;
  Ust := AYariCap;
  YariCap := 1 - AYariCap;

  while Sol < Ust do
  begin

    if YariCap < 0 then

      YariCap := YariCap + 2 * Sol + 3
    else
    begin

      YariCap :=YariCap + 2 * Sol - 2 *Ust + 5;
      Dec(Ust);
    end;

    GEkranKartSurucusu.NoktaYaz(@Self, ASol + Sol, AUst - Ust, ARenk, True); // Top
    GEkranKartSurucusu.NoktaYaz(@Self, ASol - Sol, AUst - Ust, ARenk, True);
    GEkranKartSurucusu.NoktaYaz(@Self, ASol + Ust, AUst - Sol, ARenk, True); // Upper middle
    GEkranKartSurucusu.NoktaYaz(@Self, ASol - Ust, AUst - Sol, ARenk, True);
    GEkranKartSurucusu.NoktaYaz(@Self, ASol + Ust, AUst + Sol, ARenk, True); // Lower middle
    GEkranKartSurucusu.NoktaYaz(@Self, ASol - Ust, AUst + Sol, ARenk, True);
    GEkranKartSurucusu.NoktaYaz(@Self, ASol + Sol, AUst + Ust, ARenk, True); // Bottom
    GEkranKartSurucusu.NoktaYaz(@Self, ASol - Sol, AUst + Ust, ARenk, True);
    Inc(Sol);
  end;
end;

{==============================================================================
  nesneye içi boyalı daire şekli çizer
 ==============================================================================}
procedure TGorselNesne.DaireDoldur(AGorselNesne: PGorselNesne; ASol, AUst,
  AYariCap: TISayi4; ARenk: TRenk);
var
  Sol, Ust, YariCap, DX: TISayi4;
begin

  if AYariCap = 0 then AYariCap := 1;

  YariCap := AYariCap * AYariCap;

  for Sol := AYariCap downto 0 do
  begin

    Ust := round(sqrt(YariCap - Sol * Sol));
    DX := ASol - Sol;
    Cizgi(AGorselNesne, ctDuz, DX - 1, AUst - Ust, DX - 1, AUst + Ust, ARenk);
    DX := ASol + Sol;
    Cizgi(AGorselNesne, ctDuz, DX, AUst - Ust, DX, AUst + Ust, ARenk);
  end;
end;

{==============================================================================
  nesneye belirtilen renkte yatay çizgi çizer
 ==============================================================================}
procedure TGorselNesne.YatayCizgi(AGorselNesne: PGorselNesne; ACizgiTipi: TCizgiTipi;
  ASol, AUst, ASag: TISayi4; ARenk: TRenk);
var
  AdimSayisi, i: TISayi4;
  Isaretle: Boolean;
begin

  // eğer ASol > ASag ise ASag ile ASol değerlerini yer değiştir.
  if(ASol > ASag) then
  begin

    i := ASag;
    ASag := ASol;
    ASol := i;
  end;

  AdimSayisi := 0;

  if(ACizgiTipi = ctDuz) then
    Isaretle := True
  else Isaretle := False;

  // çizgi tipine göre ilgili konumu işaretle
  for i := ASol to ASag do
  begin

    if(ACizgiTipi = ctNokta) then
    begin

      Inc(AdimSayisi);
      if(AdimSayisi = NOKTA_BOSLUKSAYISI) then
      begin

        Isaretle := not Isaretle;
        AdimSayisi := 0;
      end;
    end;

    if(Isaretle) then GEkranKartSurucusu.NoktaYaz(AGorselNesne, i, AUst, ARenk, True);
  end;
end;

{==============================================================================
  nesneye belirtilen renkte dikey çizgi çizer
 ==============================================================================}
procedure TGorselNesne.DikeyCizgi(AGorselNesne: PGorselNesne; ACizgiTipi: TCizgiTipi;
  ASol, AUst, AAlt: TISayi4; ARenk: TRenk);
var
  AdimSayisi, i: TISayi4;
  Isaretle: Boolean;
begin

  // eğer AUst > AAlt ise AAlt ile AUst değerlerini yer değiştir.
  if(AUst > AAlt) then
  begin

    i := AAlt;
    AAlt := AUst;
    AUst := i;
  end;

  AdimSayisi := 0;

  if(ACizgiTipi = ctDuz) then
    Isaretle := True
  else Isaretle := False;

  // çizgi tipine göre ilgili konumu işaretle
  for i := AUst to AAlt do
  begin

    if(ACizgiTipi = ctNokta) then
    begin

      Inc(AdimSayisi);
      if(AdimSayisi = NOKTA_BOSLUKSAYISI) then
      begin

        Isaretle := not Isaretle;
        AdimSayisi := 0;
      end;
    end;

    if(Isaretle) then GEkranKartSurucusu.NoktaYaz(AGorselNesne, ASol, i, ARenk, True);
  end;
end;

// yukarıdan aşağıya eğimli doldurma işlemi
procedure TGorselNesne.EgimliDoldur(AGorselNesne: PGorselNesne; AAlan: TAlan;
  ARenk1, ARenk2: TRenk);
var
  Renk: TRenk;
  Sol, Ust: TISayi4;

  function Gradient: TRenk;
  var
    D: Double;
    CAR, CAG, CAB, CBR, CBG, CBB: TSayi1;
  begin

    D := Ust / (AAlan.Alt - AAlan.Ust + 1);
    RedGreenBlue(ARenk1, CAR, CAG, CAB);
    RedGreenBlue(ARenk2, CBR, CBG, CBB);

    Result := RGBToColor(Round((CAR + D * (CBR - CAR))),
      Round((CAG + D * (CBG - CAG))),
      Round((CAB + D * (CBB - CAB))));
  end;
begin

  for Sol := 0 to AAlan.Sag - AAlan.Sol do
  begin

    for Ust := 0 to AAlan.Alt - AAlan.Ust do
    begin

      Renk := Gradient;
      //PixelYaz(AGorselNesne, AAlan.Sol + Sol, AAlan.Ust + Ust, Renk);
      PixelYaz(AGorselNesne, AAlan.Sol + Sol, AAlan.Ust + Ust, Renk);
    end;
  end;
end;

// soldan sağa eğimli doldurma işlemi
procedure TGorselNesne.EgimliDoldur2(AGorselNesne: PGorselNesne; AAlan: TAlan;
  ARenk1, ARenk2: TRenk);
var
  Renk: TRenk;
  Sol, Ust: TISayi4;

  function Gradient: TRenk;
  var
    D, DX, DY, P: Double;
    CAR, CAG, CAB, CBR, CBG, CBB: Byte;
  begin

    DX := ((AAlan.Sag - AAlan.Sol) / 2) - Sol;
    DY := ((AAlan.Alt - AAlan.Ust) / 2) - Ust;

    D := Sqrt(DX * DX + DY * DY);
    P := D / 255;

    //if(D < 128) then begin
    RedGreenBlue(ARenk1, CAR, CAG, CAB);
    RedGreenBlue(ARenk2, CBR, CBG, CBB);

    Result := RGBToColor(Round((CAR + P * (CBR - CAR))),
      Round((CAG + P * (CBG - CAG))),
      Round((CAB + P * (CBB - CAB))));

    //end else Result := clBlack;
  end;
begin

  for Sol := 0 to AAlan.Sag - AAlan.Sol do
  begin

    for Ust := 0 to AAlan.Alt - AAlan.Ust do
    begin

      Renk := Gradient;
      PixelYaz(AGorselNesne, AAlan.Sol + Sol, AAlan.Ust + Ust, Renk);
    end;
  end;
end;

// dikey olarak; 1. renkten 2. renge üstten ortaya kadar; 2. renkten 1. renge ortadan alta kadar
procedure TGorselNesne.EgimliDoldur3(AGorselNesne: PGorselNesne; AAlan: TAlan;
  ARenk1, ARenk2: TRenk);
var
  Alan: TAlan;
  Renk: TRenk;
  Sol, Ust: TISayi4;
  Renk1, Renk2: TRenk;

  function Gradient: TRenk;
  var
    D: Double;
    CAR, CAG, CAB, CBR, CBG, CBB: Byte;
  begin

    D := Ust / (Alan.Alt - Alan.Ust + 1);
    RedGreenBlue(Renk1, CAR, CAG, CAB);
    RedGreenBlue(Renk2, CBR, CBG, CBB);

    Result := RGBToColor(Round((CAR + D * (CBR - CAR))),
      Round((CAG + D * (CBG - CAG))),
      Round((CAB + D * (CBB - CAB))));
  end;
begin

  Renk1 := ARenk1;
  Renk2 := ARenk2;
  Alan.Sol := AAlan.Sol;
  Alan.Sag := AAlan.Sag;
  Alan.Ust := AAlan.Ust;
  Alan.Alt := AAlan.Ust + ((AAlan.Alt - AAlan.Ust) div 2);

  for Sol := 0 to Alan.Sag - Alan.Sol do
  begin

    for Ust := 0 to Alan.Alt - Alan.Ust do
    begin

      Renk := Gradient;
      //PixelYaz(AGorselNesne, AAlan.Sol + Sol, AAlan.Ust + Ust, Renk);
      PixelYaz(AGorselNesne, Alan.Sol + Sol, Alan.Ust + Ust, Renk);
    end;
  end;

  Renk1 := ARenk2;
  Renk2 := ARenk1;
  Alan.Sol := AAlan.Sol;
  Alan.Sag := AAlan.Sag;
  Alan.Ust := AAlan.Ust + ((AAlan.Alt - AAlan.Ust) div 2);
  Alan.Alt := AAlan.Alt;

  for Sol := 0 to Alan.Sag - Alan.Sol do
  begin

    for Ust := 0 to Alan.Alt - Alan.Ust do
    begin

      Renk := Gradient;
      //PixelYaz(AGorselNesne, AAlan.Sol + Sol, AAlan.Ust + Ust, Renk);
      PixelYaz(AGorselNesne, Alan.Sol + Sol, Alan.Ust + Ust, Renk);
    end;
  end;
end;

procedure TGorselNesne.KenarlikCiz(AGorselNesne: PGorselNesne; AAlan: TAlan;
  AKalinlik: TSayi4);
var
  i: TISayi4;
begin

  if(AKalinlik > 0) then
  begin

    // ilk üst ve sol çizgiyi çiz
    YatayCizgi(AGorselNesne, ctDuz, AAlan.Sol, AAlan.Ust, AAlan.Sag-1, $808080);
    DikeyCizgi(AGorselNesne, ctDuz, AAlan.Sol, AAlan.Ust, AAlan.Alt-1, $808080);

    // ilk alt ve sağ çizgiyi çiz
    YatayCizgi(AGorselNesne, ctDuz, AAlan.Sag, AAlan.Alt, AAlan.Sol, $EFEFEF);
    DikeyCizgi(AGorselNesne, ctDuz, AAlan.Sag, AAlan.Alt, AAlan.Ust, $EFEFEF);

    if(AKalinlik > 1) then
    begin

      for i := 1 to AKalinlik - 1 do
      begin

        // içe doğru diğer üst ve sol çizgiyi çiz
        YatayCizgi(AGorselNesne, ctDuz, AAlan.Sol + i, AAlan.Ust + i, AAlan.Sag - i - 1, $404040);
        DikeyCizgi(AGorselNesne, ctDuz, AAlan.Sol + i, AAlan.Ust + i, AAlan.Alt - i - 1, $404040);

        // içe doğru diğer alt ve sağ çizgiyi çiz
        YatayCizgi(AGorselNesne, ctDuz, AAlan.Sag - i, AAlan.Alt - i, AAlan.Sol + i, $D4D0C8);
        DikeyCizgi(AGorselNesne, ctDuz, AAlan.Sag - i, AAlan.Alt - i, AAlan.Ust + i, $D4D0C8);
      end;
    end;
  end;
end;

// görsel nesneye ham resim çizer
procedure TGorselNesne.HamResimCiz(AGorselNesne: PGorselNesne; ASol, AUst: TSayi4;
  AHamResimBellekAdresi: Isaretci);
var
  Sol, Ust, Renk: TSayi4;
  BaslatMenuResimAdresi: PSayi4;
begin

  BaslatMenuResimAdresi := AHamResimBellekAdresi;

  for Ust := 1 to 24 do
  begin

    for Sol := 1 to 24 do
    begin

      // yeni çizilecek cursor'ün bitmap bölgesine konumlan
      Renk := BaslatMenuResimAdresi^;

      PixelYaz(AGorselNesne, ASol + (Sol - 1), AUst + (Ust - 1), Renk);

      Inc(BaslatMenuResimAdresi);
    end;
  end;
end;

// görsel nesneye sistem kaynak resimlerinden resim çizer
// bilgi: hamresim.pas dosyasındaki resimleri çizer
procedure TGorselNesne.KaynaktanResimCiz(AGorselNesne: PGorselNesne; AAlan: TAlan; AResimSiraNo: TISayi4);
var
  Renk: TSayi4;
  ResimAdresi: PSayi4;
  Sol, Ust, Sol2, Ust2,
  RGenislik, RYukseklik,              // resim
  TGenislik, TYukseklik: TISayi4;     // tuval
begin

  if(AResimSiraNo >= 0) and (AResimSiraNo < HAMRESIM_SAYISI) then
  begin

    // HamResimler - AKaynak = 1 ve ilişkili herşey iptal edilerek
    RGenislik := HamResimler[AResimSiraNo].Genislik;
    RYukseklik := HamResimler[AResimSiraNo].Yukseklik;
    ResimAdresi := HamResimler[AResimSiraNo].BellekAdresi;

    TGenislik := AAlan.Sag; // - AAlan.Sol;
    TYukseklik := AAlan.Alt; // - AAlan.Ust;

    if(TGenislik >= RGenislik) then
      Sol := (TGenislik div 2) - (RGenislik div 2)
    else Sol := 0;
    Sol := Sol + AAlan.Sol;

    if(TYukseklik >= RYukseklik) then
      Ust := (TYukseklik div 2) - (RYukseklik div 2)
    else Ust := 0;
    Ust := Ust + AAlan.Ust;

    for Ust2 := 1 to RYukseklik do
    begin

      for Sol2 := 1 to RGenislik do
      begin

        Renk := ResimAdresi^;
        if not(Renk = $FFFFFFFF) then
          PixelYaz(AGorselNesne, Sol + Sol2, Ust + Ust2, Renk);

        Inc(ResimAdresi);
      end;
    end;
  end;
end;

// görsel nesneye sistem kaynak resimlerinden resim çizer
// bilgi: sistem.bmp dosyasındaki resimleri çizer
procedure TGorselNesne.KaynaktanResimCiz2(AGorselNesne: PGorselNesne; ASol, AUst: TSayi4;
  AResimSiraNo: TISayi4);
const
  RESIM_SAYISI = 17;
var
  Sol, Ust, Renk: TSayi4;
  BaslatMenuResimAdresi: PSayi4;
begin

  if(AResimSiraNo >= 0) and (AResimSiraNo < RESIM_SAYISI) then
  begin

    BaslatMenuResimAdresi := GSistemResimler.BellekAdresi + (AResimSiraNo * 24 * 24 * 4);

    for Ust := 0 to 23 do
    begin

      for Sol := 0 to 23 do
      begin

        // çizilecek resmin bitmap bölgesine konumlan
        Renk := BaslatMenuResimAdresi^;

        PixelYaz(AGorselNesne, ASol + Sol, AUst + Ust, Renk);

        Inc(BaslatMenuResimAdresi);
      end;
    end;
  end;
end;

// görsel nesneye sistem kaynak resimlerinden resim çizer
// bilgi: sistem.bmp dosyasındaki resimleri çizer
procedure TGorselNesne.KaynaktanResimCiz21(AGorselNesne: PGorselNesne; ASol, AUst: TSayi4;
  AResimSiraNo: TISayi4);
const
  RESIM_SAYISI = 12;
var
  Sol, Ust, Renk: TSayi4;
  BaslatMenuResimAdresi: PSayi4;
begin

  if(AResimSiraNo >= 0) and (AResimSiraNo < RESIM_SAYISI) then
  begin

    BaslatMenuResimAdresi := GSistemResimler2.BellekAdresi + (AResimSiraNo * 24 * 24 * 4);

    for Ust := 0 to 23 do
    begin

      for Sol := 0 to 23 do
      begin

        // çizilecek resmin bitmap bölgesine konumlan
        Renk := BaslatMenuResimAdresi^;

        PixelYaz(AGorselNesne, ASol + Sol, AUst + Ust, Renk);

        Inc(BaslatMenuResimAdresi);
      end;
    end;
  end;
end;

end.
