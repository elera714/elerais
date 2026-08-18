{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gorselnesne.pas
  Dosya İşlevi: tüm görsel nesnelerin türediği temel görsel ana yapı

  Güncelleme Tarihi: 18/08/2026

  Bilgi: bu görsel yapı, tüm nesnelerin ihtiyaç duyabileceği ana yapıları içerir

 ==============================================================================}
{$mode objfpc}
unit gorselnesne;

interface

uses paylasim, anagorselnesne;

const
  USTSINIR_GORSELNESNE  = 256;
  USTSINIR_MASAUSTU     = 4;

  NOKTA_BOSLUKSAYISI = 3;

type
  TGorselNesne = class;

  TOlaylariIsle = procedure(AGonderici: TGorselNesne; AOlay: TOlay) of object;

  PGorselNesne = ^TGorselNesne;
  TGorselNesne = class(TAnaGorselNesne)
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

    FTuvalNesne: TGorselNesne;                  // nesnenin çizim yapılacağı en üst çizim nesnesi
    FAtaNesne: TGorselNesne;                    // nesnenin atası
    FCizimBellekAdresi: Isaretci;               // pencere ve alt görsel nesnelerin çizileceği bellek adresi
    FCizimBellekUzunlugu: TSayi4;               // FCizimBellekAdresi değişkeninin işaret ettiği belleğin uzunluğu

    OlayCagriAdr: TOlaylariIsle;                // olayların yönlendirildiği nesne olay çağrı adresi
    OlayYonlAdr: TOlaylariIsle;                 // görsel nesneler tarafından bileşenlerin olaylarının yönlendirileceği olay adresi

    FEtiket: TSayi4;                            // nesneyi kullanacak programın kullanımı için
    constructor Create; override;
    destructor Destroy; override;
    function Yapilandir1(AKullanimTipi: TKullanimTipi; AGNTip: TGNTip; ANesne,
      AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
      ACizimModel: TSayi4; AGovdeRenk1, AGovdeRenk2, AYaziRenk: TRenk; ABaslik: string): TISayi4;

    procedure Goster;
    procedure Gizle;
    procedure Ciz;

    procedure BoyutlariYenidenHesapla;
    procedure HizaAlaniniSifirla;
    procedure Hizala;

    function CizimAlaniniAl: TAlan;
    function CizimAlaniniAl2: TAlan;
    function AtaNesneGorunurMu: Boolean;
    function FareNesneOlayAlanindaMi(AGorselNesne: TGorselNesne): Boolean;
    function NoktaAlanIcerisindeMi(NoktaA1, NoktaB1: TISayi4;
      AAlan: TAlan): Boolean;
    property AtaNesne: TGorselNesne read FAtaNesne write FAtaNesne;

    // kernel için çağrılar (for kernel)
    procedure PixelYaz(AGorselNesne: TGorselNesne; ASol, AUst: TISayi4; ARenk: TRenk);
    procedure YaziYaz(AGorselNesne: TGorselNesne; ASol, AUst: TISayi4; AYazi: string;
      ARenk: TRenk);
    procedure YaziYaz(AGorselNesne: TGorselNesne; AYaziHiza: TYaziHiza;
      AAlan: TAlan; AYazi: string; ARenk: TRenk);
    procedure AlanaYaziYaz(AGorselNesne: TGorselNesne; AAlan: TAlan;
      ASol, AUst: TISayi4; AKarakterDizi: string; ARenk: TRenk);
    procedure SayiYaz16(AGorselNesne: TGorselNesne; ASol, AUst: TISayi4; AOnEkYaz:
      LongBool; AHaneSayisi, ADeger: TISayi4; ARenk: TRenk);
    procedure SaatYaz(AGorselNesne: TGorselNesne; ASol, AUst: TISayi4; ASaat: TSaat;
      ARenk: TRenk);
    procedure HarfYaz(AGorselNesne: TGorselNesne; ASol, AUst: TISayi4;
      AKarakter: Char; AZeminRengi, AYaziRengi: TRenk);
    procedure SayiYaz10(AGorselNesne: TGorselNesne; ASol, AUst: TISayi4;
      ASayi: TISayi4; ARenk: TRenk);
    procedure MACAdresiYaz(AGorselNesne: TGorselNesne; ASol, AUst: TISayi4;
      AMACAdres: TMACAdres; ARenk: TRenk);
    procedure IPAdresiYaz(AGorselNesne: TGorselNesne; ASol, AUst: TSayi4;
      AIPAdres: TIP4Adres; ARenk: TRenk);
    procedure Dikdortgen(AGorselNesne: TGorselNesne; ACizgiTipi: TCizgiTipi;
      AAlan: TAlan; ACizgiRengi: TRenk);
    procedure DikdortgenDoldur(AGorselNesne: TGorselNesne; ASol, AUst,
      ASag, AAlt: TISayi4; ACizgiRengi, ADolguRengi: TRenk);
    procedure DikdortgenDoldur(AGorselNesne: TGorselNesne; AAlan: TAlan;
      ACizgiRengi, ADolguRengi: TRenk);
    procedure Doldur4(AGorselNesne: PGorselNesne; AAlan: TAlan; ASol, AUst,
      ASag, AAlt: TISayi4; ACizgiRengi, ADolguRengi: TRenk);
    procedure BMPGoruntusuCiz(AGNTip: TGNTip; AGorselNesne: TGorselNesne;
      AGoruntuYapi: TGoruntuYapi);
    procedure Cizgi(AGorselNesne: TGorselNesne; ACizgiTipi: TCizgiTipi;
      ASol, AUst, ASag, AAlt: TISayi4; ACizgiRengi: TRenk);
    procedure Daire(ASol, AUst, AYariCap: TISayi4; ARenk: TRenk);
    procedure DaireDoldur(AGorselNesne: TGorselNesne; ASol, AUst,
      AYariCap: TISayi4; ARenk: TRenk);
    procedure YatayCizgi(AGorselNesne: TGorselNesne; ACizgiTipi: TCizgiTipi;
      ASol, AUst, ASag: TISayi4; ARenk: TRenk);
    procedure DikeyCizgi(AGorselNesne: TGorselNesne; ACizgiTipi: TCizgiTipi;
      ASol, AUst, AAlt: TISayi4; ARenk: TRenk);
    procedure EgimliDoldur(AGorselNesne: TGorselNesne; AAlan: TAlan;
      ARenk1, ARenk2: TRenk);
    procedure EgimliDoldur2(AGorselNesne: TGorselNesne; AAlan: TAlan;
      ARenk1, ARenk2: TRenk);
    procedure EgimliDoldur3(AGorselNesne: TGorselNesne; AAlan: TAlan; ARenk1, ARenk2: TRenk);
    procedure KenarlikCiz(AGorselNesne: TGorselNesne; AAlan: TAlan;
      AKalinlik: TSayi4);
    procedure HamResimCiz(AGorselNesne: TGorselNesne; ASol, AUst: TSayi4;
      AHamResimBellekAdresi: Isaretci);
    procedure KaynaktanResimCiz(AGorselNesne: TGorselNesne; AAlan: TAlan; AResimSiraNo: TISayi4);
    procedure KaynaktanResimCiz2(AGorselNesne: TGorselNesne; ASol, AUst: TSayi4;
      AResimSiraNo: TISayi4);
    procedure KaynaktanResimCiz21(AGorselNesne: TGorselNesne; ASol, AUst: TSayi4;
      AResimSiraNo: TISayi4);

    // program için çağrılar (for program)
    procedure Kesme_YaziYaz(ASol, AUst: TISayi4; AKarakterDizi: string; ARenk: TRenk);
    procedure Kesme_SayiYaz16(ASol, AUst: TISayi4; AOnEkYaz: LongBool;
      AHaneSayisi, ADeger: TISayi4; ARenk: TRenk);
    procedure Kesme_SaatYaz(ASol, AUst: TISayi4; ASaat: TSaat; ARenk: TRenk);
  end;

implementation

uses src_ps2, genel8x16, donusum, bmp, gn_islevler, gn_pencere, hamresim, gorev,
  src_vesa20, sistem;

{==============================================================================
  görsel ana nesneyi oluşturur
 ==============================================================================}
constructor TGorselNesne.Create;
var
  i: TSayi4;
begin

  inherited Create;

  i := GGNesneler.KimlikNoAl;
  FSiraNo := i;
  Kimlik := (i shl 10) or %1010101011;

  GGNesneler.ToplamGorselNesne := GGNesneler.ToplamGorselNesne + 1;
end;

{==============================================================================
  görsel ana nesneyi yok eder
 ==============================================================================}
destructor TGorselNesne.Destroy;
begin

  inherited Destroy;
end;

{==============================================================================
  görsel nesnenin değişkenlerini özelleştirir
 ==============================================================================}
function TGorselNesne.Yapilandir1(AKullanimTipi: TKullanimTipi; AGNTip: TGNTip; ANesne,
  AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ACizimModel: TSayi4; AGovdeRenk1, AGovdeRenk2, AYaziRenk: TRenk; ABaslik: string): TISayi4;
var
  AtaGN: TGorselNesne;
begin

  if(AAtaNesne = nil) then
    AtaGN := nil
  else AtaGN := GGNesneler.NesneAl(AAtaNesne.Kimlik);

  // görsel nesneyi ata nesneye ekle
  if not(AtaGN = nil) then
  begin

    if(GGNesneler.AtaNesneyeEkle(ANesne, AtaGN) = False) then
    begin

      // hata olması durumunda nesneyi yok et ve işlevden çık
      { TODO - gerekli kodlar yazılacak }
      Exit(-1);
    end;
  end;

  // temel nesne değerlerini ata
  GrvKimlik := GGorevler.FAktifGrv;
  AtaNesne := AtaGN;

  // nesne olayları öndeğer olarak nesneyi oluşturan programa yönlendirilecek
  // aksi durumda belirtilen çağrı adresine yönlendirilecek
  OlayCagriAdr := nil;
  OlayYonlAdr := nil;

  FHiza := hzYok;

  FKalinlik.Sol := 0;
  FKalinlik.Ust := 0;
  FKalinlik.Sag := 0;
  FKalinlik.Alt := 0;

  FAtananAlan.Sol := ASol;
  FAtananAlan.Ust := AUst;
  FAtananAlan.Genislik := AGenislik;
  FAtananAlan.Yukseklik := AYukseklik;

  FIlkAtananAlan := FAtananAlan;

  FKullanimTipi := AKullanimTipi;

  // öndeğer olarak çizim alanı ve alt çizim alanı eşit olarak değerlendiriliyor
  // nesnenin kendisi bu değeri değiştirebilir
  FCizimAlani.Sol := 0;
  FCizimAlani.Ust := 0;
  FCizimAlani.Sag := FAtananAlan.Genislik - 1;
  FCizimAlani.Alt := FAtananAlan.Yukseklik - 1;

  if(FKullanimTipi = ktNesne) then
  begin

    if(AtaGN = nil) then
    begin

      FCizimBaslangic.Sol := 0;
      FCizimBaslangic.Ust := 0;
    end
    else
    begin

      FCizimBaslangic.Sol := AtaGN.FCizimBaslangic.Sol + AtaGN.FKalinlik.Sol + ASol;
      FCizimBaslangic.Ust := AtaGN.FCizimBaslangic.Ust + AtaGN.FKalinlik.Ust + AUst;
    end;
  end
  else
  // bileşen
  begin

    FCizimBaslangic.Sol := AtaGN.FCizimBaslangic.Sol + ASol;
    FCizimBaslangic.Ust := AtaGN.FCizimBaslangic.Ust + AUst;
  end;

  FHiza := hzYok;
  FHizaAlani := FCizimAlani;

  // nesnenin alt bileşen sayısı
  AltBilesenSayisi := 0;

  // alt nesnelerin bellek adresi (nil = bellek oluşturulmadı)
  AltNesneBellekAdresi := nil;

  // nesnenin alt nesne sayısı
  AltNesneSayisi := 0;

  // nesnenin üzerine gelindiğinde görüntülenecek fare göstergesi
  FareImlec := fitOK;

  // nesnenin görünüm durumu
  Gorunum := False;

  // nesnenin başlık değeri
  FYaziHiza.Yatay := yhOrta;
  FYaziHiza.Dikey := dhOrta;
  Baslik := ABaslik;

  // nesnenin renk değerleri
  FCizimModel := ACizimModel;
  FGovdeRenk1 := AGovdeRenk1;
  FGovdeRenk2 := AGovdeRenk2;
  FYaziRenk := AYaziRenk;

  FCiziliyor := False;

  FEtiket := 0;

  // nesne adresini geri döndür
  Result := HATA_YOK;
end;

{==============================================================================
  görsel nesnenin görünüm özelliğini aktifleştirir
 ==============================================================================}
procedure TGorselNesne.Goster;
var
  Pencere: TPencere;
begin

  // nesne görünür durumda mı ?
  if(Gorunum = False) then
  begin

    // görsel ana yapı nesnesinin görünürlüğünü aktifleştir
    Gorunum := True;

    // ata nesne görünür durumda mı?
    if(AtaNesneGorunurMu) then
    begin

      // nesnenin sahibi olan pencere nesnesini al
      Pencere := GGNesneler.EnUstPencereNesnesiniAl(Self);
      if not(Pencere = nil) then Pencere.Guncelle;
    end;
  end;
end;

{==============================================================================
  görsel nesnenin görünüm özelliğini pasifleştirir
 ==============================================================================}
procedure TGorselNesne.Gizle;
var
  Pencere: TPencere;
begin

  // nesne görünür durumda mı ?
  if(Gorunum = True) then
  begin

    // görsel ana yapı nesnesinin görünürlüğünü aktifleştir
    Gorunum := False;

    // ata nesne görünür durumda mı?
    if(AtaNesneGorunurMu) then
    begin

      // nesnenin sahibi olan pencere nesnesini al
      Pencere := GGNesneler.EnUstPencereNesnesiniAl(Self);
      if not(Pencere = nil) then Pencere.Guncelle;
    end;
  end;
end;

{==============================================================================
  görsel nesnenin ana çizimlerinin gerçekleştirir
  bilgi: ana çizimden sonra gerekirse diğer çizimler alt nesneler tarafından gerçekleştirilir
 ==============================================================================}
procedure TGorselNesne.Ciz;
var
  CizimAlani: TAlan;
begin

  CizimAlani := FCizimAlani;

  // FCizimModel = 0 = hiçbir çizim yapma
  if(FCizimModel > 0) then
  begin

    // FCizimModel = 2 = kenarlığı çiz ve içeriği doldur
    if(FCizimModel = 2) then

      DikdortgenDoldur(Self, CizimAlani, FGovdeRenk1, FGovdeRenk2)

    // FCizimModel = 3 = kenarlığı çiz ve içeriği doldur
    else if(FCizimModel = 3) then

      DikdortgenDoldur(Self, CizimAlani.Sol, CizimAlani.Ust, CizimAlani.Sag,
        CizimAlani.Alt, FGovdeRenk1, FGovdeRenk2)

    // FCizimModel = 4 = artan renk ile (eğimli) doldur
    else if(FCizimModel = 4) then
      EgimliDoldur3(Self, CizimAlani, FGovdeRenk1, FGovdeRenk2);

    // görsel ana yapı başlığını yaz
    if not(FCizimModel = 2) then
      if(Length(Baslik) > 0) then YaziYaz(Self, FYaziHiza, CizimAlani,
        Baslik, FYaziRenk);
  end;
end;

{==============================================================================
  görsel nesnenin boyutlarını üst nesneye göre yeniden hesaplar
 ==============================================================================}
procedure TGorselNesne.BoyutlariYenidenHesapla;
var
  GorselAtaNesne, GN: TGorselNesne;
begin

  GN := GGNesneler.NesneAl(Kimlik);
  if(GN = nil) then Exit;

  GN.FCizimAlani.Sol := 0;
  GN.FCizimAlani.Ust := 0;
  GN.FCizimAlani.Sag := GN.FAtananAlan.Genislik - 1;
  GN.FCizimAlani.Alt := GN.FAtananAlan.Yukseklik - 1;

  GorselAtaNesne := GN.AtaNesne;

  if(GorselAtaNesne.NesneTipi = gntPencere) then
  begin

    GN.FCizimBaslangic.Sol := GN.AtaNesne.FKalinlik.Sol + GN.FAtananAlan.Sol;
    GN.FCizimBaslangic.Ust := GN.AtaNesne.FKalinlik.Ust + GN.FAtananAlan.Ust;
  end
  else
  begin

    GN.FCizimBaslangic.Sol := GN.AtaNesne.FCizimBaslangic.Sol +
      GN.AtaNesne.FKalinlik.Sol + GN.FAtananAlan.Sol;
    GN.FCizimBaslangic.Ust := GN.AtaNesne.FCizimBaslangic.Ust +
      GN.AtaNesne.FKalinlik.Ust + GN.FAtananAlan.Ust;
  end;
end;

procedure TGorselNesne.HizaAlaniniSifirla;
begin

  FHizaAlani.Sol := FCizimAlani.Sol;
  FHizaAlani.Ust := FCizimAlani.Ust;
  FHizaAlani.Sag := FCizimAlani.Sag;
  FHizaAlani.Alt := FCizimAlani.Alt;
end;

{==============================================================================
  görsel nesneyi hizalandırır
 ==============================================================================}
procedure TGorselNesne.Hizala;
var
  AtaGN, GN: TGorselNesne;
begin

  GN := GGNesneler.NesneAl(Kimlik);
  if(GN = nil) then Exit;

  AtaGN := GN.AtaNesne;

  GN.FAtananAlan := GN.FIlkAtananAlan;

  if(GN.FHiza = hzSol) then
  begin

    //SISTEM_MESAJ(RENK_KIRMIZI, 'Boyut: %d', [GorselAtaNesne^.FBoyut.Yukseklik]);

    // nesnenin hesaplanması
    GN.FAtananAlan.Sol := AtaGN.FHizaAlani.Sol;
    GN.FAtananAlan.Ust := AtaGN.FHizaAlani.Ust;
    // nesnenin kendi genişliği kullanılacak
    GN.FAtananAlan.Yukseklik := (AtaGN.FHizaAlani.Alt - AtaGN.FHizaAlani.Ust) + 1;
    GN.BoyutlariYenidenHesapla;

    // üst nesnenin yeniden boyutlandırılması
    AtaGN.FHizaAlani.Sol := AtaGN.FHizaAlani.Sol + GN.FAtananAlan.Genislik;
  end
  else if(GN.FHiza = hzUst) then
  begin

    GN.FAtananAlan.Sol := AtaGN.FHizaAlani.Sol;
    GN.FAtananAlan.Ust := AtaGN.FHizaAlani.Ust;
    GN.FAtananAlan.Genislik := (AtaGN.FHizaAlani.Sag - AtaGN.FHizaAlani.Sol) + 1;
    // nesnenin kendi yüksekliği kullanılacak
    GN.BoyutlariYenidenHesapla;

    AtaGN.FHizaAlani.Ust := AtaGN.FHizaAlani.Ust + GN.FAtananAlan.Yukseklik;
  end
  else if(GN.FHiza = hzSag) then
  begin

    // nesnenin hesaplanması
    GN.FAtananAlan.Sol := (AtaGN.FHizaAlani.Sag - GN.FAtananAlan.Genislik) + 1;
    GN.FAtananAlan.Ust := AtaGN.FHizaAlani.Ust;
    // nesnenin kendi genişliği kullanılacak
    GN.FAtananAlan.Yukseklik := (AtaGN.FHizaAlani.Alt - AtaGN.FHizaAlani.Ust) + 1;
    GN.BoyutlariYenidenHesapla;

    // üst nesnenin yeniden boyutlandırılması
    AtaGN.FHizaAlani.Sag := AtaGN.FHizaAlani.Sag - GN.FAtananAlan.Genislik;
  end
  else if(GN.FHiza = hzAlt) then
  begin

    GN.FAtananAlan.Sol := AtaGN.FHizaAlani.Sol;
    GN.FAtananAlan.Ust := (AtaGN.FHizaAlani.Alt - GN.FAtananAlan.Yukseklik) + 1;
    GN.FAtananAlan.Genislik := (AtaGN.FHizaAlani.Sag - AtaGN.FHizaAlani.Sol) + 1;
    // nesnenin kendi yüksekliği kullanılacak
    GN.BoyutlariYenidenHesapla;

    AtaGN.FHizaAlani.Alt := AtaGN.FHizaAlani.Alt - GN.FAtananAlan.Yukseklik;
  end
  else if(GN.FHiza = hzTum) then
  begin

    GN.FAtananAlan.Sol := AtaGN.FHizaAlani.Sol;
    GN.FAtananAlan.Ust := AtaGN.FHizaAlani.Ust;
    GN.FAtananAlan.Genislik := (AtaGN.FHizaAlani.Sag - AtaGN.FHizaAlani.Sol) + 1;
    GN.FAtananAlan.Yukseklik := (AtaGN.FHizaAlani.Alt - AtaGN.FHizaAlani.Ust) + 1;
    GN.BoyutlariYenidenHesapla;

//    GorselAtaNesne^.FHizaAlani.Alt := GorselAtaNesne^.FHizaAlani.Alt - GorselNesne^.FBoyut.Yukseklik;
  end else GN.BoyutlariYenidenHesapla;
end;

{==============================================================================
  nesnenin pencereye (0, 0 koordinatı) bağlı gerçek koordinatlarını alır
 ==============================================================================}
function TGorselNesne.CizimAlaniniAl: TAlan;
var
  Pencere: TPencere;
  GN: TGorselNesne;
begin

  // talepte bulunan nesnenin kimlik değerini kontrol et
  GN := Self;

  if((GN.NesneTipi = gntMasaustu) or (GN.NesneTipi = gntPencere) or
    (GN.NesneTipi = gntMenu) or (GN.NesneTipi = gntAcilirMenu)) then
  begin

    // genişlik ve yükseklik değerleri alınıyor
    Result.Sol := GN.FKalinlik.Sol;
    Result.Ust := GN.FKalinlik.Ust;
    Result.Sag := Result.Sol + GN.FAtananAlan.Genislik;
    Result.Alt := Result.Ust + GN.FAtananAlan.Yukseklik;
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

    Pencere := GGNesneler.EnUstPencereNesnesiniAl(GN);

    Result.Sol := GN.FCizimAlani.Sol - Pencere.FCizimAlani.Sol;
    Result.Ust := GN.FCizimAlani.Ust - Pencere.FCizimAlani.Ust;
    Result.Sag := GN.FCizimAlani.Sag - Pencere.FCizimAlani.Sol;
    Result.Alt := GN.FCizimAlani.Alt - Pencere.FCizimAlani.Ust;
  end;
end;

{==============================================================================
  nesnenin çizilebilir alanının koordinatlarını alır
 ==============================================================================}
function TGorselNesne.CizimAlaniniAl2: TAlan;
//var
//  GN: PGorselNesne;
begin

  //GN := GGNesneler.NesneAl(AKimlik);

  // nesnenin üst nesneye bağlı koordinatlarını al
  Result := CizimAlaniniAl;
end;

{==============================================================================
  belirtilen nesneden itibaren masaüstüne kadar tüm nesnelerin görünürlüğünü
  kontrol eder. (nesnenin kendisi de dahil)
 ==============================================================================}
function TGorselNesne.AtaNesneGorunurMu: Boolean;
var
  GN: TGorselNesne;
begin

  GN := Self;

  repeat

    // nesne görünür durumdaysa AtaNesne nesnesini al
    if(GN.Gorunum) then

      GN := GN.AtaNesne
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
function TGorselNesne.FareNesneOlayAlanindaMi(AGorselNesne: TGorselNesne): Boolean;
var
  GN: TGorselNesne;
  Alan: TAlan;
begin

  GN := AGorselNesne;

  Alan.Sol := GN.FCizimBaslangic.Sol;
  Alan.Ust := GN.FCizimBaslangic.Ust;

  if(GN.FTuvalNesne.NesneTipi = gntPencere) or
    (GN.FTuvalNesne.NesneTipi = gntMenu) or
    (GN.FTuvalNesne.NesneTipi = gntAcilirMenu) then
  begin

    Alan.Sol := Alan.Sol + GN.FTuvalNesne.FAtananAlan.Sol;
    Alan.Ust := Alan.Ust + GN.FTuvalNesne.FAtananAlan.Ust;
  end;

  Alan.Sag := Alan.Sol + GN.FCizimAlani.Sag;
  Alan.Alt := Alan.Ust + GN.FCizimAlani.Alt;

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
  x, y koordinatının dikdörtgensel alan içerisinde olup olmadığını kontrol eder
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
procedure TGorselNesne.PixelYaz(AGorselNesne: TGorselNesne; ASol, AUst: TISayi4; ARenk: TRenk);
begin

  GEkranKartSurucusu.NoktaYaz(AGorselNesne, ASol, AUst, ARenk, True);
end;

{==============================================================================
  grafiksel ekrana karakter yazar
 ==============================================================================}
procedure TGorselNesne.HarfYaz(AGorselNesne: TGorselNesne; ASol, AUst: TISayi4;
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
procedure TGorselNesne.Kesme_YaziYaz(ASol, AUst: TISayi4; AKarakterDizi: string; ARenk: TRenk);
var
  Alan: TAlan;
begin

  Alan := CizimAlaniniAl2;
  YaziYaz(FAtaNesne, Alan.Sol + ASol, Alan.Ust + AUst, AKarakterDizi, ARenk);
end;

{==============================================================================
  grafiksel ekrana yazı yazar
 ==============================================================================}
procedure TGorselNesne.YaziYaz(AGorselNesne: TGorselNesne; ASol, AUst: TISayi4; AYazi: string;
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
procedure TGorselNesne.YaziYaz(AGorselNesne: TGorselNesne; AYaziHiza: TYaziHiza;
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
procedure TGorselNesne.AlanaYaziYaz(AGorselNesne: TGorselNesne; AAlan: TAlan;
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
procedure TGorselNesne.SayiYaz10(AGorselNesne: TGorselNesne; ASol, AUst: TISayi4;
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

  Alan := CizimAlaniniAl2;

  // sayısal değeri ekrana yaz
  YaziYaz(FAtaNesne, Alan.Sol + ASol, Alan.Ust + AUst, Deger, ARenk);
end;

{==============================================================================
  grafiksel ekrana hexadesimal sayı yazar
 ==============================================================================}
procedure TGorselNesne.SayiYaz16(AGorselNesne: TGorselNesne; ASol, AUst: TISayi4;
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

  Alan := CizimAlaniniAl2;

  // saat değerini belirtilen koordinatlara yaz
  YaziYaz(FAtaNesne, Alan.Sol + ASol, Alan.Ust + AUst, Saat, ARenk);
end;

{==============================================================================
  grafiksel ekrana belirtilen saat değerini yazar
 ==============================================================================}
procedure TGorselNesne.SaatYaz(AGorselNesne: TGorselNesne; ASol, AUst: TISayi4; ASaat: TSaat;
  ARenk: TRenk);
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
procedure TGorselNesne.MACAdresiYaz(AGorselNesne: TGorselNesne; ASol, AUst: TISayi4;
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
procedure TGorselNesne.IPAdresiYaz(AGorselNesne: TGorselNesne; ASol, AUst: TSayi4;
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
procedure TGorselNesne.Dikdortgen(AGorselNesne: TGorselNesne; ACizgiTipi: TCizgiTipi;
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
  Dikdortgen(AGorselNesne^, ctDuz, Alan, ACizgiRengi);

  // iç kenarlık
  Inc(Sol);
  Inc(Ust);
  Dec(Sag);
  Dec(Alt);

  for j := Ust to Alt do
  begin

    for i := Sol to Sag do
    begin

      //GEkranKartSurucusu.NoktaYaz(@Self, i, j, ADolguRengi, True);
    end;
  end;
end;

{==============================================================================
  nesneye belirtilen renkte içi doldurulmuş dikdörtgen çizer
 ==============================================================================}
procedure TGorselNesne.DikdortgenDoldur(AGorselNesne: TGorselNesne; ASol, AUst,
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
  görsel nesneye belirtilen renkte içi doldurulmuş dikdörtgen çizer
 ==============================================================================}
procedure TGorselNesne.DikdortgenDoldur(AGorselNesne: TGorselNesne; AAlan: TAlan;
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

{==============================================================================
  görsel nesneye bmp resim içeriğini çizer
==============================================================================}
procedure TGorselNesne.BMPGoruntusuCiz(AGNTip: TGNTip; AGorselNesne: TGorselNesne;
  AGoruntuYapi: TGoruntuYapi);
var
  BMP: TBMP;
begin

  BMP := TBMP.Create;
  BMP.Ciz(AGNTip, AGorselNesne, AGoruntuYapi);
  BMP.Destroy;
end;

{==============================================================================
  görsel nesneye belirtilen renkte çizgi çizer
 ==============================================================================}
// https://rosettacode.org/wiki/Bitmap/Bresenham%27s_line_algorithm
// procedure drawLine (bitmap : TBitmap; xStart, yStart, xEnd, yEnd : integer; color : TAlphaColor);
procedure TGorselNesne.Cizgi(AGorselNesne: TGorselNesne; ACizgiTipi: TCizgiTipi;
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
  görsel nesneye daire şekli çizer
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

    GEkranKartSurucusu.NoktaYaz(Self, ASol + Sol, AUst - Ust, ARenk, True); // Top
    GEkranKartSurucusu.NoktaYaz(Self, ASol - Sol, AUst - Ust, ARenk, True);
    GEkranKartSurucusu.NoktaYaz(Self, ASol + Ust, AUst - Sol, ARenk, True); // Upper middle
    GEkranKartSurucusu.NoktaYaz(Self, ASol - Ust, AUst - Sol, ARenk, True);
    GEkranKartSurucusu.NoktaYaz(Self, ASol + Ust, AUst + Sol, ARenk, True); // Lower middle
    GEkranKartSurucusu.NoktaYaz(Self, ASol - Ust, AUst + Sol, ARenk, True);
    GEkranKartSurucusu.NoktaYaz(Self, ASol + Sol, AUst + Ust, ARenk, True); // Bottom
    GEkranKartSurucusu.NoktaYaz(Self, ASol - Sol, AUst + Ust, ARenk, True);
    Inc(Sol);
  end;
end;

{==============================================================================
  görsel nesneye içi boyalı daire şekli çizer
 ==============================================================================}
procedure TGorselNesne.DaireDoldur(AGorselNesne: TGorselNesne; ASol, AUst,
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
  görsel nesneye belirtilen renkte yatay çizgi çizer
 ==============================================================================}
procedure TGorselNesne.YatayCizgi(AGorselNesne: TGorselNesne; ACizgiTipi: TCizgiTipi;
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
  görsel nesneye belirtilen renkte dikey çizgi çizer
 ==============================================================================}
procedure TGorselNesne.DikeyCizgi(AGorselNesne: TGorselNesne; ACizgiTipi: TCizgiTipi;
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

{==============================================================================
  yukarıdan aşağıya eğimli doldurma işlemi
==============================================================================}
procedure TGorselNesne.EgimliDoldur(AGorselNesne: TGorselNesne; AAlan: TAlan;
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

{==============================================================================
  soldan sağa eğimli doldurma işlemi
==============================================================================}
procedure TGorselNesne.EgimliDoldur2(AGorselNesne: TGorselNesne; AAlan: TAlan;
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

{==============================================================================
  dikey olarak; 1. renkten 2. renge üstten ortaya kadar; 2. renkten 1. renge ortadan alta kadar
==============================================================================}
procedure TGorselNesne.EgimliDoldur3(AGorselNesne: TGorselNesne; AAlan: TAlan;
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

procedure TGorselNesne.KenarlikCiz(AGorselNesne: TGorselNesne; AAlan: TAlan;
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

{==============================================================================
  görsel nesneye ham resim çizer
==============================================================================}
procedure TGorselNesne.HamResimCiz(AGorselNesne: TGorselNesne; ASol, AUst: TSayi4;
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

{==============================================================================
  görsel nesneye sistem kaynak resimlerinden resim çizer
  bilgi: hamresim.pas dosyasındaki resimleri çizer
==============================================================================}
procedure TGorselNesne.KaynaktanResimCiz(AGorselNesne: TGorselNesne; AAlan: TAlan; AResimSiraNo: TISayi4);
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

{==============================================================================
  görsel nesneye sistem kaynak resimlerinden resim çizer
  bilgi: sistem.bmp dosyasındaki resimleri çizer
==============================================================================}
procedure TGorselNesne.KaynaktanResimCiz2(AGorselNesne: TGorselNesne; ASol, AUst: TSayi4;
  AResimSiraNo: TISayi4);
const
  RESIM_SAYISI = 17;
var
  Sol, Ust, Renk: TSayi4;
  BaslatMenuResimAdresi: PSayi4;
begin

  if(AResimSiraNo >= 0) and (AResimSiraNo < RESIM_SAYISI) then
  begin

    BaslatMenuResimAdresi := GSistem.FSistemResimler.BellekAdresi + (AResimSiraNo * 24 * 24 * 4);

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

{==============================================================================
  görsel nesneye sistem kaynak resimlerinden resim çizer
  bilgi: sistem.bmp dosyasındaki resimleri çizer
==============================================================================}
procedure TGorselNesne.KaynaktanResimCiz21(AGorselNesne: TGorselNesne; ASol, AUst: TSayi4;
  AResimSiraNo: TISayi4);
const
  RESIM_SAYISI = 12;
var
  Sol, Ust, Renk: TSayi4;
  BaslatMenuResimAdresi: PSayi4;
begin

  if(AResimSiraNo >= 0) and (AResimSiraNo < RESIM_SAYISI) then
  begin

    BaslatMenuResimAdresi := GSistem.FSistemResimler2.BellekAdresi + (AResimSiraNo * 24 * 24 * 4);

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
