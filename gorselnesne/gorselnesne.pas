{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: gorselnesne.pas
  Dosya Ýþlevi: tüm görsel nesnelerin türediði temel görsel ana yapý

  Güncelleme Tarihi: 07/07/2025

  Bilgi: bu görsel yapý, tüm nesnelerin ihtiyaç duyabileceði ana yapýlarý içerir

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
    //   0: dolgu ve yazý yok
    //   1: arka plan rengi yok, yazý var
    //   2: arka plan rengi var, yazý yok
    //   3: FGovdeRenk1 = kenarlýk rengi, FGovdeRenk2 = dolgu rengi
    //   4: FGovdeRenk1'den FGovdeRenk2'ye doðru eðimli dolgu
    FCizimModel: TSayi4;
    FGovdeRenk1, FGovdeRenk2,
    FYaziRenk: TRenk;

    FTuvalNesne: PGorselNesne;                  // nesnenin çizim yapýlacaðý en üst çizim nesnesi
    FAtaNesne: PGorselNesne;                    // nesnenin atasý
    FAltNesneBellekAdresi: PPGorselNesne;       // ata nesnenin alt nesneleri yerleþtireceði bellek adresi
    FCizimBellekAdresi: Isaretci;               // pencere ve alt görsel nesnelerin çizileceði bellek adresi
    FCizimBellekUzunlugu: TSayi4;               // FCizimBellekAdresi deðiþkeninin iþaret ettiði belleðin uzunluðu

    OlayCagriAdresi: TOlaylariIsle;             // olaylarýn yönlendirildiði nesne olay çaðrý adresi
    OlayYonlendirmeAdresi: TOlaylariIsle;       // görsel nesneler tarafýndan bileþenlerin olaylarýnýn yönlendirileceði olay adresi

    FEtiket: TSayi4;                            // nesneyi kullanacak programýn kullanýmý için

    function Olustur(AKullanimTipi: TKullanimTipi; AGNTip: TGNTip; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4; ACizimModel: TSayi4;
      AGovdeRenk1, AGovdeRenk2, AYaziRenk: TRenk; ABaslik: string): PGorselNesne;

    function Olustur0(AGNTip: TGNTip): PGorselNesne;
    procedure YokEt;
    procedure Goster;
    procedure Gizle;
    procedure Ciz;

    procedure BoyutlariYenidenHesapla;
    procedure HizaAlaniniSifirla;
    procedure Hizala;

    function NesneTipiniKontrolEt(AKimlik: TKimlik; AGNTip: TGNTip): PGorselNesne;
    function NesneyiAl(AKimlik: TKimlik): PGorselNesne;
    function AtaNesneyeEkle(AAtaNesne: PGorselNesne): Boolean;
    function AtaNesnedenCikar: Boolean;
    function CizimAlaniniAl(AKimlik: TKimlik): TAlan;
    function CizimAlaniniAl2(AKimlik: TKimlik): TAlan;
    function AtaNesneGorunurMu: Boolean;
    function NesneAl(AKimlik: TKimlik): PGorselNesne;
    function FareNesneOlayAlanindaMi(AGorselNesne: PGorselNesne): Boolean;
    function NoktaAlanIcerisindeMi(NoktaA1, NoktaB1: TISayi4;
      AAlan: TAlan): Boolean;
    property AtaNesne: PGorselNesne read FAtaNesne write FAtaNesne;

    // kernel için çaðrýlar (for kernel)
    procedure PixelYaz(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4; ARenk: TRenk);
    procedure YaziYaz(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4; AYazi: string; ARenk: TRenk);
    procedure YaziYaz(AGorselNesne: PGorselNesne; AYaziHiza: TYaziHiza;
      AAlan: TAlan; AYazi: string; ARenk: TRenk);
    procedure AlanaYaziYaz(AGorselNesne: PGorselNesne; AAlan: TAlan;
      ASol, AUst: TISayi4; AKarakterDizi: string; ARenk: TRenk);
    procedure SayiYaz16(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4; AOnEkYaz:
      LongBool; AHaneSayisi, ADeger: TISayi4; ARenk: TRenk);
    procedure SaatYaz(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4; ASaat: TSaat; ARenk: TRenk);
    procedure HarfYaz(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4; AKarakter: Char; ARenk: TRenk);
    procedure SayiYaz10(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4;
      ASayi: TISayi4; ARenk: TRenk);
    procedure MACAdresiYaz(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4;
      AMACAdres: TMACAdres; ARenk: TRenk);
    procedure IPAdresiYaz(AGorselNesne: PGorselNesne; ASol, AUst: TSayi4; AIPAdres: TIPAdres;
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
    procedure KaynaktanResimCiz(AKaynak: TSayi4; AGorselNesne: PGorselNesne;
      AAlan: TAlan; AResimSiraNo: TISayi4);
    procedure KaynaktanResimCiz2(AGorselNesne: PGorselNesne; ASol, AUst: TSayi4;
      AResimSiraNo: TISayi4);
    procedure KaynaktanResimCiz21(AGorselNesne: PGorselNesne; ASol, AUst: TSayi4;
      AResimSiraNo: TISayi4);

    // program için çaðrýlar (for program)
    procedure Kesme_YaziYaz(ASol, AUst: TISayi4; AKarakterDizi: string; ARenk: TRenk);
    procedure Kesme_SayiYaz16(ASol, AUst: TISayi4; AOnEkYaz: LongBool;
      AHaneSayisi, ADeger: TISayi4; ARenk: TRenk);
    procedure Kesme_SaatYaz(ASol, AUst: TISayi4; ASaat: TSaat; ARenk: TRenk);
  end;

implementation

uses genel, genel8x16, donusum, bmp, gn_islevler, sistemmesaj, gn_pencere,
  hamresim, giysi_normal, giysi_mac, gorev;

var
  GiysiResimler: array[0..11] of THamResim = (
    (Genislik: 14;  Yukseklik: 14;  BellekAdresi: @giysi_mac.KapatmaDugmesiA),
    (Genislik: 14;  Yukseklik: 14;  BellekAdresi: @giysi_mac.KapatmaDugmesiP),
    (Genislik: 14;  Yukseklik: 14;  BellekAdresi: @giysi_mac.BuyutmeDugmesiA),
    (Genislik: 14;  Yukseklik: 14;  BellekAdresi: @giysi_mac.BuyutmeDugmesiP),
    (Genislik: 14;  Yukseklik: 14;  BellekAdresi: @giysi_mac.KucultmeDugmesiA),
    (Genislik: 14;  Yukseklik: 14;  BellekAdresi: @giysi_mac.KucultmeDugmesiP),
    (Genislik: 12;  Yukseklik: 12;  BellekAdresi: @giysi_normal.KapatmaDugmesiA),
    (Genislik: 12;  Yukseklik: 12;  BellekAdresi: @giysi_normal.KapatmaDugmesiP),
    (Genislik: 12;  Yukseklik: 12;  BellekAdresi: @giysi_normal.BuyutmeDugmesiA),
    (Genislik: 12;  Yukseklik: 12;  BellekAdresi: @giysi_normal.BuyutmeDugmesiP),
    (Genislik: 12;  Yukseklik: 12;  BellekAdresi: @giysi_normal.KucultmeDugmesiA),
    (Genislik: 12;  Yukseklik: 12;  BellekAdresi: @giysi_normal.KucultmeDugmesiP));

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
  else AtaGorselNesne := AtaGorselNesne^.NesneyiAl(AAtaNesne^.FTGN.Kimlik);

  // görsel ana yapý nesnesini oluþtur
  GN := PGorselNesne(Olustur0(AGNTip));
  if(GN = nil) then Exit(nil);

  // görsel nesneyi ata nesneye ekle
  if not(AtaGorselNesne = nil) then
  begin

    if(GN^.AtaNesneyeEkle(AtaGorselNesne) = False) then
    begin

      // hata olmasý durumunda nesneyi yok et ve iþlevden çýk
      GN^.YokEt;
      Exit(nil);
    end;
  end;

  // temel nesne deðerlerini ata
  GN^.GorevKimlik := FAktifGorev;
  GN^.AtaNesne := AtaGorselNesne;

  // nesne olaylarý öndeðer olarak nesneyi oluþturan programa yönlendirilecek
  // aksi durumda belirtilen çaðrý adresine yönlendirilecek
  GN^.OlayCagriAdresi := nil;
  GN^.OlayYonlendirmeAdresi := nil;

  GN^.FHiza := hzYok;

  GN^.FKalinlik.Sol := 0;
  GN^.FKalinlik.Ust := 0;
  GN^.FKalinlik.Sag := 0;
  GN^.FKalinlik.Alt := 0;

  GN^.FKonum.Sol := ASol;
  GN^.FKonum.Ust := AUst;
  GN^.FBoyut.Genislik := AGenislik;
  GN^.FBoyut.Yukseklik := AYukseklik;

  GN^.FIlkKonum := GN^.FKonum;
  GN^.FIlkBoyut := GN^.FBoyut;

  GN^.FKullanimTipi := AKullanimTipi;

  // öndeðer olarak çizim alaný ve alt çizim alaný eþit olarak deðerlendiriliyor
  // nesnenin kendisi bu deðeri deðiþtirebilir
  GN^.FCizimAlan.Sol := 0;
  GN^.FCizimAlan.Ust := 0;
  GN^.FCizimAlan.Sag := GN^.FBoyut.Genislik - 1;
  GN^.FCizimAlan.Alt := GN^.FBoyut.Yukseklik - 1;


  if(GN^.FKullanimTipi = ktNesne) then
  begin

    if(AtaGorselNesne = nil) then
    begin

      GN^.FCizimBaslangic.Sol := 0;
      GN^.FCizimBaslangic.Ust := 0;
    end
    else
    begin

      GN^.FCizimBaslangic.Sol := AtaGorselNesne^.FCizimBaslangic.Sol +
        AtaGorselNesne^.FKalinlik.Sol + ASol;
      GN^.FCizimBaslangic.Ust := AtaGorselNesne^.FCizimBaslangic.Ust +
        AtaGorselNesne^.FKalinlik.Ust + AUst;
    end;
  end
  else
  // bileþen
  begin

    GN^.FCizimBaslangic.Sol := AtaGorselNesne^.FCizimBaslangic.Sol + ASol;
    GN^.FCizimBaslangic.Ust := AtaGorselNesne^.FCizimBaslangic.Ust + AUst;
  end;

  GN^.FHiza := hzYok;
  GN^.FHizaAlani := GN^.FCizimAlan;

  // alt nesnelerin bellek adresi (nil = bellek oluþturulmadý)
  GN^.FAltNesneBellekAdresi := nil;

  // nesnenin alt nesne sayýsý
  GN^.FTGN.AltNesneSayisi := 0;

  // nesnenin üzerine gelindiðinde görüntülenecek fare göstergesi
  GN^.FTGN.FareImlecTipi := fitOK;

  // nesnenin görünüm durumu
  GN^.Gorunum := False;

  // nesnenin baþlýk deðeri
  GN^.FYaziHiza.Yatay := yhOrta;
  GN^.FYaziHiza.Dikey := dhOrta;
  GN^.Baslik := ABaslik;

  // nesnenin renk deðerleri
  GN^.FCizimModel := ACizimModel;
  GN^.FGovdeRenk1 := AGovdeRenk1;
  GN^.FGovdeRenk2 := AGovdeRenk2;
  GN^.FYaziRenk := AYaziRenk;

  GN^.FCiziliyor := False;

  GN^.FEtiket := 0;

  // nesne adresini geri döndür
  Result := GN;
end;

{==============================================================================
  görsel nesne nesnesini oluþturur
 ==============================================================================}
function TGorselNesne.Olustur0(AGNTip: TGNTip): PGorselNesne;
var
  TemelGorselNesne: PTemelGorselNesne;
  i, j: TISayi4;
begin

  // tüm nesneleri ara
  for i := 0 to USTSINIR_GORSELNESNE - 1 do
  begin

    TemelGorselNesne := GGorselNesneListesi[i];

    // eðer nesne kullanýlmamýþ ise ... (0. bit 0 ise)
    if((TemelGorselNesne^.FTGN.Kimlik and 1) = 0) then
    begin

      // nesne içeriðini sýfýrla
      //FillByte(TemelGorselNesne^, GN_UZUNLUK, 0);

      //TemelGorselNesne^.FTGN.Kimlik := 11223344;

      // nesne kimliðini Kullanýldý olarak iþaretle
      j := TemelGorselNesne^.FTGN.Kimlik or 1;

      // nesne kimliðini güncelle
      TemelGorselNesne^.FTGN.Kimlik := j;

      TemelGorselNesne^.NesneTipi := AGNTip;

      //SISTEM_MESAJ_S10(RENK_KIRMIZI, 'TTemelGorselNesne yapý uzunluðu: ', SizeOf(TTemelGorselNesne));
      //SISTEM_MESAJ_S10(RENK_KIRMIZI, 'TGorselNesne yapý uzunluðu: ', SizeOf(TGorselNesne));

      // geri dönecek deðer
      Result := PGorselNesne(TemelGorselNesne);

      // oluþturulmuþ nesne sayýsýný 1 artýr ve çýk
      Inc(ToplamGNSayisi);

      Exit;
    end;
  end;

  Result := nil;
end;

{==============================================================================
  görsel nesneyi yok eder
 ==============================================================================}
procedure TGorselNesne.YokEt;
var
  i: TKimlik;
begin

  i := FTGN.Kimlik shr 10;

  // eðer nesne istenen aralýkta ise yok et
  if(i >= 0) and (i < USTSINIR_GORSELNESNE) then
  begin

    // nesne kimliðini Kullanýldý bitini sýfýrla
    i := GGorselNesneListesi[i]^.FTGN.Kimlik;
    i := i and $FFFFFFFE;
    GGorselNesneListesi[i]^.FTGN.Kimlik := i;
    //Kimlik := HATA_KIMLIK;
    Dec(ToplamGNSayisi);
    //Result := True;
  end //else Result := False;
end;

procedure TGorselNesne.Goster;
var
  Pencere: PPencere;
  GorselAnaYapi: PGorselNesne;
begin

  // nesnenin kimlik, tip deðerlerini denetle.
  GorselAnaYapi := PGorselNesne(GorselAnaYapi^.NesneTipiniKontrolEt(FTGN.Kimlik, NesneTipi));
  if(GorselAnaYapi = nil) then Exit;

  // nesne görünür durumda mý ?
  if(GorselAnaYapi^.Gorunum = False) then
  begin

    // görsel ana yapý nesnesinin görünürlüðünü aktifleþtir
    GorselAnaYapi^.Gorunum := True;

    // ata nesne görünür durumda mý?
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

  // nesnenin kimlik, tip deðerlerini denetle.
  GorselAnaYapi := PGorselNesne(GorselAnaYapi^.NesneTipiniKontrolEt(FTGN.Kimlik, NesneTipi));
  if(GorselAnaYapi = nil) then Exit;

  // nesne görünür durumda mý ?
  if(GorselAnaYapi^.Gorunum = True) then
  begin

    // görsel ana yapý nesnesinin görünürlüðünü aktifleþtir
    GorselAnaYapi^.Gorunum := False;

    // ata nesne görünür durumda mý?
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
  CizimAlan: TAlan;
begin

  GN := GN^.NesneAl(FTGN.Kimlik);
  if(GN = nil) then Exit;

  CizimAlan := GN^.FCizimAlan;

  // FCizimModel = 0 = hiçbir çizim yapma
  if(GN^.FCizimModel > 0) then
  begin

    // FCizimModel = 3 = kenarlýðý çiz ve içeriði doldur
    if(GN^.FCizimModel = 2) then

      GN^.DikdortgenDoldur(GN, CizimAlan, FGovdeRenk1, FGovdeRenk2)

    // FCizimModel = 3 = kenarlýðý çiz ve içeriði doldur
    else if(GN^.FCizimModel = 3) then

      GN^.DikdortgenDoldur(GN, CizimAlan.Sol, CizimAlan.Ust, CizimAlan.Sag,
        CizimAlan.Alt, FGovdeRenk1, FGovdeRenk2)

    // FCizimModel = 4 = artan renk ile (eðimli) doldur
    else if(GN^.FCizimModel = 4) then
      GN^.EgimliDoldur3(GN, CizimAlan, FGovdeRenk1, FGovdeRenk2);

    // görsel ana yapý baþlýðýný yaz
    if not(GN^.FCizimModel = 2) then
      if(Length(GN^.Baslik) > 0) then YaziYaz(GN, GN^.FYaziHiza, CizimAlan,
        Baslik, FYaziRenk);
  end;
end;

procedure TGorselNesne.BoyutlariYenidenHesapla;
var
  GorselAtaNesne, GN: PGorselNesne;
begin

  GN := GN^.NesneAl(FTGN.Kimlik);
  if(GN = nil) then Exit;

  GN^.FCizimAlan.Sol := 0;
  GN^.FCizimAlan.Ust := 0;
  GN^.FCizimAlan.Sag := GN^.FBoyut.Genislik - 1;
  GN^.FCizimAlan.Alt := GN^.FBoyut.Yukseklik - 1;

  GorselAtaNesne := GN^.AtaNesne;

  if(GorselAtaNesne^.NesneTipi = gntPencere) then
  begin

    GN^.FCizimBaslangic.Sol := GN^.AtaNesne^.FKalinlik.Sol + GN^.FKonum.Sol;
    GN^.FCizimBaslangic.Ust := GN^.AtaNesne^.FKalinlik.Ust + GN^.FKonum.Ust;
  end
  else
  begin

    GN^.FCizimBaslangic.Sol := GN^.AtaNesne^.FCizimBaslangic.Sol +
      GN^.AtaNesne^.FKalinlik.Sol + GN^.FKonum.Sol;
    GN^.FCizimBaslangic.Ust := GN^.AtaNesne^.FCizimBaslangic.Ust +
      GN^.AtaNesne^.FKalinlik.Ust + GN^.FKonum.Ust;
  end;
end;

procedure TGorselNesne.HizaAlaniniSifirla;
var
  GN: PGorselNesne;
begin

  GN := GN^.NesneAl(FTGN.Kimlik);
  if(GN = nil) then Exit;

  GN^.FHizaAlani.Sol := GN^.FCizimAlan.Sol;
  GN^.FHizaAlani.Ust := GN^.FCizimAlan.Ust;
  GN^.FHizaAlani.Sag := GN^.FCizimAlan.Sag;
  GN^.FHizaAlani.Alt := GN^.FCizimAlan.Alt;
end;

procedure TGorselNesne.Hizala;
var
  GorselAtaNesne, GN: PGorselNesne;
begin

  GN := PGorselNesne(@Self); // GorselNesne^.NesneAl(Kimlik);
  if(GN = nil) then Exit;

  GorselAtaNesne := GN^.AtaNesne;

  GN^.FBoyut := GN^.FIlkBoyut;
  GN^.FKonum := GN^.FIlkKonum;

  if(GN^.FHiza = hzSol) then
  begin

    //SISTEM_MESAJ(RENK_KIRMIZI, 'Boyut: %d', [GorselAtaNesne^.FBoyut.Yukseklik]);

    // nesnenin hesaplanmasý
    GN^.FKonum.Sol := GorselAtaNesne^.FHizaAlani.Sol;
    GN^.FKonum.Ust := GorselAtaNesne^.FHizaAlani.Ust;
    // nesnenin kendi geniþliði kullanýlacak
    GN^.FBoyut.Yukseklik := (GorselAtaNesne^.FHizaAlani.Alt - GorselAtaNesne^.FHizaAlani.Ust) + 1;
    GN^.BoyutlariYenidenHesapla;

    // üst nesnenin yeniden boyutlandýrýlmasý
    GorselAtaNesne^.FHizaAlani.Sol += GN^.FBoyut.Genislik;
  end
  else if(GN^.FHiza = hzUst) then
  begin

    GN^.FKonum.Sol := GorselAtaNesne^.FHizaAlani.Sol;
    GN^.FKonum.Ust := GorselAtaNesne^.FHizaAlani.Ust;
    GN^.FBoyut.Genislik := (GorselAtaNesne^.FHizaAlani.Sag - GorselAtaNesne^.FHizaAlani.Sol) + 1;
    // nesnenin kendi yüksekliði kullanýlacak
    GN^.BoyutlariYenidenHesapla;

    GorselAtaNesne^.FHizaAlani.Ust += GN^.FBoyut.Yukseklik;
  end
  else if(GN^.FHiza = hzSag) then
  begin

    // nesnenin hesaplanmasý
    GN^.FKonum.Sol := (GorselAtaNesne^.FHizaAlani.Sag - GN^.FBoyut.Genislik) + 1;
    GN^.FKonum.Ust := GorselAtaNesne^.FHizaAlani.Ust;
    // nesnenin kendi geniþliði kullanýlacak
    GN^.FBoyut.Yukseklik := (GorselAtaNesne^.FHizaAlani.Alt - GorselAtaNesne^.FHizaAlani.Ust) + 1;
    GN^.BoyutlariYenidenHesapla;

    // üst nesnenin yeniden boyutlandýrýlmasý
    GorselAtaNesne^.FHizaAlani.Sag -= GN^.FBoyut.Genislik;
  end
  else if(GN^.FHiza = hzAlt) then
  begin

    GN^.FKonum.Sol := GorselAtaNesne^.FHizaAlani.Sol;
    GN^.FKonum.Ust := (GorselAtaNesne^.FHizaAlani.Alt - GN^.FBoyut.Yukseklik) + 1;
    GN^.FBoyut.Genislik := (GorselAtaNesne^.FHizaAlani.Sag - GorselAtaNesne^.FHizaAlani.Sol) + 1;
    // nesnenin kendi yüksekliði kullanýlacak
    GN^.BoyutlariYenidenHesapla;

    GorselAtaNesne^.FHizaAlani.Alt -= GN^.FBoyut.Yukseklik;
  end
  else if(GN^.FHiza = hzTum) then
  begin

    GN^.FKonum.Sol := GorselAtaNesne^.FHizaAlani.Sol;
    GN^.FKonum.Ust := GorselAtaNesne^.FHizaAlani.Ust;
    GN^.FBoyut.Genislik := (GorselAtaNesne^.FHizaAlani.Sag - GorselAtaNesne^.FHizaAlani.Sol) + 1;
    GN^.FBoyut.Yukseklik := (GorselAtaNesne^.FHizaAlani.Alt - GorselAtaNesne^.FHizaAlani.Ust) + 1;
    GN^.BoyutlariYenidenHesapla;

//    GorselAtaNesne^.FHizaAlani.Alt -= GorselNesne^.FBoyut.Yukseklik;
  end else GN^.BoyutlariYenidenHesapla;
end;

{==============================================================================
  nesnenin nesne tipini kontrol eder
 ==============================================================================}
function TGorselNesne.NesneTipiniKontrolEt(AKimlik: TKimlik; AGNTip: TGNTip): PGorselNesne;
var
  GN: PGorselNesne;
  i: TKimlik;
begin

  i := AKimlik shr 10;

  // nesne istenen sayý aralýðýnda ise
  if(i >= 0) and (i < USTSINIR_GORSELNESNE) then
  begin

    GN := GGorselNesneListesi[i];

    // nesne oluþturulmuþ mu ?
    if(GN^.FTGN.Kimlik = AKimlik) then
    begin

      // nesne tipini kontrol et
      if(GN^.NesneTipi = AGNTip) then Exit(GN);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  nesneyi kimliðinden nesneyi al
 ==============================================================================}
function TGorselNesne.NesneyiAl(AKimlik: TKimlik): PGorselNesne;
var
  i: TKimlik;
begin

  i := AKimlik shr 10;

  // nesne istenen sayý aralýðýnda ise
  if(i >= 0) and (i < USTSINIR_GORSELNESNE) then

    Result := PGorselNesne(GGorselNesneListesi[i])

  else Result := nil;
end;

{==============================================================================
  nesneyi ata nesnesine alt nesne olarak ekler
 ==============================================================================}
function TGorselNesne.AtaNesneyeEkle(AAtaNesne: PGorselNesne): Boolean;
var
  AltNesneBellekAdresi: PPGorselNesne;
  i: TISayi4;
begin

  // ata nesnenin alt nesneleri için bellek oluþturulmuþ mu ?
  if(AAtaNesne^.FAltNesneBellekAdresi = nil) then
  begin

    // ata nesne için bellek oluþtur
    AltNesneBellekAdresi := GGercekBellek.Ayir(4096);
    AAtaNesne^.FAltNesneBellekAdresi := AltNesneBellekAdresi;
  end;

  // alt nesne toplam nesne sayýsý aþýlmamýþsa ...
  if(AAtaNesne^.FTGN.AltNesneSayisi < 1024) then
  begin

    // üst nesnenin bellek adresini al
    AltNesneBellekAdresi := AAtaNesne^.FAltNesneBellekAdresi;

    // nesneyi üst nesneye kaydet
    AltNesneBellekAdresi[AAtaNesne^.FTGN.AltNesneSayisi] := @Self;

    // üst nesnenin nesne saysýný 1 artýr
    i := AAtaNesne^.FTGN.AltNesneSayisi;
    Inc(i);
    AAtaNesne^.FTGN.AltNesneSayisi := i;
    Result := True;
  end else Result := False;
end;

function TGorselNesne.AtaNesnedenCikar: Boolean;
begin

  { TODO - gerektiðinde kodlar yazýlabilir }
end;

{==============================================================================
  nesnenin pencereye (0, 0 koordinatý) baðlý gerçek koordinatlarýný alýr
 ==============================================================================}
function TGorselNesne.CizimAlaniniAl(AKimlik: TKimlik): TAlan;
var
  Pencere: PPencere;
  GN: PGorselNesne;
begin

  // talepte bulunan nesnenin kimlik deðerini kontrol et
  GN := NesneAl(AKimlik);

  if((Self.NesneTipi = gntMasaustu) or (Self.NesneTipi = gntPencere) or
    (Self.NesneTipi = gntMenu) or (Self.NesneTipi = gntAcilirMenu)) then
  begin

    // geniþlik ve yükseklik deðerleri alýnýyor
    Result.Sol := GN^.FKalinlik.Sol;
    Result.Ust := GN^.FKalinlik.Ust;
    Result.Sag := Result.Sol + GN^.FBoyut.Genislik;
    Result.Alt := Result.Ust + GN^.FBoyut.Yukseklik;
  end
  else
  begin

    {GorselNesne2 := GorselNesne;
    Result.Sol := 0;
    Result.Ust := 0;
    Result.Sag := 0;
    Result.Alt := 0;
    repeat

      Result.Sol += GorselNesne2^.FKonum.Sol;
      Result.Ust += GorselNesne2^.FBoyutlar.Ust2;

      GorselNesne2 := GorselNesne2^.AtaNesne;
      NTip := GorselNesne2^.NesneTipi;
    until (NTip = gntMasaustu) or (NTip = gntPencere) or (NTip = gntMenu) or (NTip = gntAcilirMenu);

    Result.Sol += GorselNesne2^.FAltNesneCizimAlan.Sol;
    Result.Ust += GorselNesne2^.FAltNesneCizimAlan.Ust;
    Result.Sag := Result.Sol + GorselNesne^.FBoyutlar.Genislik2;
    Result.Alt := Result.Ust + GorselNesne^.FBoyut.Yukseklik;}

    Pencere := EnUstPencereNesnesiniAl(GN);

    Result.Sol := GN^.FCizimAlan.Sol - Pencere^.FCizimAlan.Sol;
    Result.Ust := GN^.FCizimAlan.Ust - Pencere^.FCizimAlan.Ust;
    Result.Sag := GN^.FCizimAlan.Sag - Pencere^.FCizimAlan.Sol;
    Result.Alt := GN^.FCizimAlan.Alt - Pencere^.FCizimAlan.Ust;
  end;
end;

{==============================================================================
  nesnenin çizilebilir alanýnýn koordinatlarýný alýr
 ==============================================================================}
function TGorselNesne.CizimAlaniniAl2(AKimlik: TKimlik): TAlan;
var
  GN: PGorselNesne;
begin

  GN := NesneAl(AKimlik);

  // nesnenin üst nesneye baðlý koordinatlarýný al
  Result := CizimAlaniniAl(AKimlik);
end;

{==============================================================================
  belirtilen nesneden itibaren masaüstüne kadar tüm nesnelerin görünürlüðünü
  kontrol eder. (nesnenin kendisi de dahil)
 ==============================================================================}
function TGorselNesne.AtaNesneGorunurMu: Boolean;
var
  GN: PGorselNesne;
begin

  GN := @Self;

  repeat

    // nesne görünür durumdaysa AtaNesne nesnesini al
    if(GN^.Gorunum) then

      GN := GN^.AtaNesne
    else
    begin

      // aksi durumda çýk
      Result := False;
      Exit;
    end;

    // tüm nesneler test edildiyse olumlu yanýt ile geri dön
    if(GN = nil) then Exit(True);

  until (True = False);
end;

{==============================================================================
  nesne kimlik deðerinden nesnenin bellek bölgesini geri döndürür
 ==============================================================================}
function TGorselNesne.NesneAl(AKimlik: TKimlik): PGorselNesne;
var
  i: TKimlik;
begin

  i := AKimlik shr 10;
  Result := GGorselNesneListesi[i];
end;

{==============================================================================
  fare göstergesinin nesnenin olay alanýnýn içerisinde olup
  olmadýðýný kontrol eder
 ==============================================================================}
function TGorselNesne.FareNesneOlayAlanindaMi(AGorselNesne: PGorselNesne): Boolean;
var
  GN: PGorselNesne;
  Alan: TAlan;
begin

  GN := AGorselNesne;

  Alan.Sol := GN^.FCizimBaslangic.Sol;
  Alan.Ust := GN^.FCizimBaslangic.Ust;

  if(GN^.FTuvalNesne^.NesneTipi = gntPencere) or
    (GN^.FTuvalNesne^.NesneTipi = gntMenu) or
    (GN^.FTuvalNesne^.NesneTipi = gntAcilirMenu) then
  begin

    Alan.Sol += GN^.FTuvalNesne^.FKonum.Sol;
    Alan.Ust += GN^.FTuvalNesne^.FKonum.Ust;
  end;

  Alan.Sag := Alan.Sol + GN^.FCizimAlan.Sag;
  Alan.Alt := Alan.Ust + GN^.FCizimAlan.Alt;

  //SISTEM_MESAJ(RENK_KIRMIZI, 'Sol %d', [Alan.Sol]);
  //SISTEM_MESAJ(RENK_KIRMIZI, 'Ust %d', [Alan.Ust]);

  // öndeðer dönüþ deðeri
  Result := False;

  // fare belirtilen koordinatlar içerisinde mi ?
  if(GFareSurucusu.YatayKonum < Alan.Sol) then Exit;
  if(GFareSurucusu.YatayKonum > Alan.Sag) then Exit;
  if(GFareSurucusu.DikeyKonum < Alan.Ust) then Exit;
  if(GFareSurucusu.DikeyKonum > Alan.Alt) then Exit;

  //SISTEM_MESAJ(RENK_KIRMIZI, 'Ýçeride Tamam', []);

  Result := True;
end;

{==============================================================================
  X, Y koordinatýnýn Rect alaný içerisinde olup olmadýðýný test eder
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
  grafiksel koordinattaki pixeli iþaretler (boyar)
 ==============================================================================}
procedure TGorselNesne.PixelYaz(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4; ARenk: TRenk);
begin

  GEkranKartSurucusu.NoktaYaz(AGorselNesne, ASol, AUst, ARenk, True);
end;

{==============================================================================
  grafiksel ekrana karakter yazar
 ==============================================================================}
procedure TGorselNesne.HarfYaz(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4;
  AKarakter: Char; ARenk: TRenk);
var
  Karakter: TKarakter;
  Genislik, Yukseklik: TISayi4;
  KarakterAdres: PByte;
  i, j: TISayi4;
begin

  // karakterler 0..255 aralýðýndadýr.
	Karakter := KarakterListesi[TSayi1(AKarakter)];

  // eðer karakter boþluk veya çizim gerektirmeyen karakter ise çýk
  if(Karakter.Yukseklik = 0) or (Karakter.Genislik = 0) then Exit;

  // karakterin ASol deðerine yatay tolerans koordinatýný ekle
  ASol += Karakter.YT;

  // karakterin AUst deðerine dikey tolerans koordinatýný ekle
  AUst += Karakter.DT;

  // karakterin geniþlik ve yükseklik deðerlerini hesapla
  Genislik := ASol + Karakter.Genislik;
  Yukseklik := AUst + Karakter.Yukseklik;

  // karakterin pixel haritasýnýn bellek adresine konumlan
  KarakterAdres := Karakter.Adres;

  for j := AUst to Yukseklik - 1 do
  begin

		for i := ASol to Genislik - 1 do
    begin

      // ilgili pixeli belirtilen renkle iþaretle (boya)
			if(KarakterAdres^ = 1) then GEkranKartSurucusu.NoktaYaz(AGorselNesne, i, j,
        ARenk, True);

      // bir sonraki pixele konumlan
      Inc(KarakterAdres)
    end;
  end;
end;

{==============================================================================
  grafiksel ekrana karakter katarý yazar
 ==============================================================================}
procedure TGorselNesne.Kesme_YaziYaz(ASol, AUst: TISayi4; AKarakterDizi: string;
  ARenk: TRenk);
var
  Alan: TAlan;
begin

  Alan := CizimAlaniniAl2(FTGN.Kimlik);
  YaziYaz(FAtaNesne, Alan.Sol + ASol, Alan.Ust + AUst, AKarakterDizi, ARenk);
end;

{==============================================================================
  grafiksel ekrana yazý yazar
 ==============================================================================}
procedure TGorselNesne.YaziYaz(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4; AYazi: string;
  ARenk: TRenk);
var
  Sol, Ust, YaziU: TISayi4;
begin

  // karakter katarýnýn uzunluðunu al
  YaziU := Length(AYazi);
  if(YaziU = 0) then Exit;

  Ust := ASol;
  for Sol := 1 to YaziU do
  begin

    // karakteri yaz
    HarfYaz(AGorselNesne, Ust, AUst, AYazi[Sol], ARenk);

    // karakter geniþliðini geniþlik deðerine ekle
    Ust += 8;
  end;
end;

{==============================================================================
  grafiksel ekrana hizalayarak yazý yazar
 ==============================================================================}
procedure TGorselNesne.YaziYaz(AGorselNesne: PGorselNesne; AYaziHiza: TYaziHiza;
  AAlan: TAlan; AYazi: string; ARenk: TRenk);
var
  i, j, Sol, Ust: TISayi4;
begin

  // karakter katarýnýn uzunluðunu al
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
    HarfYaz(AGorselNesne, Sol, Ust, AYazi[i], ARenk);

    // karakter geniþliðini geniþlik deðerine ekle
    Sol += 8;
  end;
end;

{==============================================================================
  dikdörtgensel (4 nokta) grafiksel ekrana karakter katarý yazar
 ==============================================================================}
// Önemli bilgi: þu aþamada çoklu satýr iþlevi olmadýðý için Y1 -> Y2 kontrolü YAPILMAMAKTADIR
procedure TGorselNesne.AlanaYaziYaz(AGorselNesne: PGorselNesne; AAlan: TAlan;
  ASol, AUst: TISayi4; AKarakterDizi: string; ARenk: TRenk);
var
  KarakterDiziUz, i,
  Sol, Ust: TISayi4;
begin

  {
      AAlan.Sol:AAlan.Ust = sol üst köþe (örn: 100, 100)
      AAlan.Sag:AAlan.Alt = sað alt köþe (örn: 200, 200)
      ASol = çizim AAlan.Sol'den kaç pixel uzaklýktan baþlayacak (örn: 10 = 110)
      AUst = çizim AAlan.Ust'den kaç pixel uzaklýktan baþlayacak (örn: 12 = 112)
  }

  // karakter katarýnýn uzunluðunu al
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
    HarfYaz(AGorselNesne, Sol, Ust, AKarakterDizi[i], ARenk);

    // karakter geniþliðini x deðerine ekle
    Sol += 8;
  end;
end;

{==============================================================================
  grafiksel ekrana integer sayý yazar
 ==============================================================================}
procedure TGorselNesne.SayiYaz10(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4;
  ASayi: TISayi4; ARenk: TRenk);
var
  Deger: array[0..11] of Char;
begin

  // desimal deðeri string deðere çevir
  Deger := IntToStr(ASayi);

  // sayýsal deðeri ekrana yaz
  YaziYaz(AGorselNesne, ASol, AUst, Deger, ARenk);
end;

{==============================================================================
  grafiksel ekrana 16lý tabanda sayý yazar
 ==============================================================================}
procedure TGorselNesne.Kesme_SayiYaz16(ASol, AUst: TISayi4; AOnEkYaz: LongBool;
  AHaneSayisi, ADeger: TISayi4; ARenk: TRenk);
var
  Deger: string[10];
  Alan: TAlan;
begin

  // hexadesimal deðeri string deðere çevir
  if(AOnEkYaz) then
    Deger := '0x' + hexStr(ADeger, AHaneSayisi)
  else Deger := hexStr(ADeger, AHaneSayisi);

  Alan := CizimAlaniniAl2(FTGN.Kimlik);

  // sayýsal deðeri ekrana yaz
  YaziYaz(FAtaNesne, Alan.Sol + ASol, Alan.Ust + AUst, Deger, ARenk);
end;

{==============================================================================
  grafiksel ekrana hexadesimal sayý yazar
 ==============================================================================}
procedure TGorselNesne.SayiYaz16(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4;
  AOnEkYaz: LongBool; AHaneSayisi, ADeger: TISayi4; ARenk: TRenk);
var
  Deger: string[10];
begin

  // hexadesimal deðeri string deðere çevir
  if(AOnEkYaz) then
    Deger := '0x' + hexStr(ADeger, AHaneSayisi)
  else Deger := hexStr(ADeger, AHaneSayisi);

  // sayýsal deðeri ekrana yaz
  YaziYaz(AGorselNesne, ASol, AUst, Deger, ARenk);
end;

{==============================================================================
  grafiksel ekrana belirtilen saat deðerini yazar
 ==============================================================================}
procedure TGorselNesne.Kesme_SaatYaz(ASol, AUst: TISayi4; ASaat: TSaat; ARenk: TRenk);
var
  Saat: string[8];
  Alan: TAlan;
begin

  // saat deðerini karakter katarýna çevir
  Saat := TimeToStr(ASaat);

  Alan := CizimAlaniniAl2(FTGN.Kimlik);

  // saat deðerini belirtilen koordinatlara yaz
  YaziYaz(FAtaNesne, Alan.Sol + ASol, Alan.Ust + AUst, Saat, ARenk);
end;

{==============================================================================
  grafiksel ekrana belirtilen saat deðerini yazar
 ==============================================================================}
procedure TGorselNesne.SaatYaz(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4;
  ASaat: TSaat; ARenk: TRenk);
var
  Saat: string[8];
begin

  // saat deðerini karakter katarýna çevir
  Saat := TimeToStr(ASaat);

  // saat deðerini belirtilen koordinatlara yaz
  YaziYaz(AGorselNesne, ASol, AUst, Saat, ARenk);
end;

{==============================================================================
  grafiksel ekrana mac adres deðerini yazar
 ==============================================================================}
procedure TGorselNesne.MACAdresiYaz(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4;
  AMACAdres: TMACAdres; ARenk: TRenk);
var
  MACAdres: string[17];
begin

  // MAC adres deðerini karakter katarýna çevir
  MACAdres := MAC_KarakterKatari(AMACAdres);

  // MAC adres deðerini belirtilen koordinatlara yaz
  YaziYaz(AGorselNesne, ASol, AUst, MACAdres, ARenk);
end;

{==============================================================================
  grafiksel ekrana ip adres deðerini yazar
 ==============================================================================}
procedure TGorselNesne.IPAdresiYaz(AGorselNesne: PGorselNesne; ASol, AUst: TSayi4;
  AIPAdres: TIPAdres; ARenk: TRenk);
var
  IPAdres: string[15];
begin

  // IP adres deðerini karakter katarýna çevir
  IPAdres := IP_KarakterKatari(AIPAdres);

  // ip adres deðerini belirtilen koordinatlara yaz
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

  // sað dikey çizgiyi çiz
  DikeyCizgi(AGorselNesne, ACizgiTipi, AAlan.Sag, AAlan.Alt, AAlan.Ust, ACizgiRengi);
end;

{==============================================================================
  nesnenin dikdörtgensel olarak sýnýrlandýrýlmýþ alanýna belirtilen renkte içi
  doldurulmuþ dikdörtgen çizer. (not: test edilecek)
 ==============================================================================}
procedure TGorselNesne.Doldur4(AGorselNesne: PGorselNesne; AAlan: TAlan; ASol, AUst,
  ASag, AAlt: TISayi4; ACizgiRengi, ADolguRengi: TRenk);
var
  Alan: TAlan;
  i, j, Sol, Ust, Sag, Alt: TISayi4;
begin

  // çizim koordinatlarýnýnýn sýnýrlarýn içerisinde olup olmadýðýný kontrol et
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

  // dýþ kenarlýk
  Alan.Sol := Sol;
  Alan.Ust := Ust;
  Alan.Sag := Sag;
  Alan.Alt := Alt;
  Dikdortgen(AGorselNesne, ctDuz, Alan, ACizgiRengi);

  // iç kenarlýk
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
  nesneye belirtilen renkte içi doldurulmuþ dikdörtgen çizer
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
  nesneye belirtilen renkte içi doldurulmuþ dikdörtgen çizer
 ==============================================================================}
procedure TGorselNesne.DikdortgenDoldur(AGorselNesne: PGorselNesne; AAlan: TAlan;
  ACizgiRengi, ADolguRengi: TRenk);
var
  i, j: TISayi4;
begin

  // dýþ kenarlýk
  Dikdortgen(AGorselNesne, ctDuz, AAlan, ACizgiRengi);

  // iç kenarlýk
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
begin

  ResimCiz(AGNTip, AGorselNesne, AGoruntuYapi);
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
  nesneye daire þekli çizer
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
  nesneye içi boyalý daire þekli çizer
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

  // eðer ASol > ASag ise ASag ile ASol deðerlerini yer deðiþtir.
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

  // çizgi tipine göre ilgili konumu iþaretle
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

  // eðer AUst > AAlt ise AAlt ile AUst deðerlerini yer deðiþtir.
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

  // çizgi tipine göre ilgili konumu iþaretle
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

// yukarýdan aþaðýya eðimli doldurma iþlemi
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

// soldan saða eðimli doldurma iþlemi
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

    // ilk alt ve sað çizgiyi çiz
    YatayCizgi(AGorselNesne, ctDuz, AAlan.Sag, AAlan.Alt, AAlan.Sol, $EFEFEF);
    DikeyCizgi(AGorselNesne, ctDuz, AAlan.Sag, AAlan.Alt, AAlan.Ust, $EFEFEF);

    if(AKalinlik > 1) then
    begin

      for i := 1 to AKalinlik - 1 do
      begin

        // içe doðru diðer üst ve sol çizgiyi çiz
        YatayCizgi(AGorselNesne, ctDuz, AAlan.Sol + i, AAlan.Ust + i, AAlan.Sag - i - 1, $404040);
        DikeyCizgi(AGorselNesne, ctDuz, AAlan.Sol + i, AAlan.Ust + i, AAlan.Alt - i - 1, $404040);

        // içe doðru diðer alt ve sað çizgiyi çiz
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
// bilgi: hamresim.pas dosyasýndaki resimleri çizer
procedure TGorselNesne.KaynaktanResimCiz(AKaynak: TSayi4; AGorselNesne: PGorselNesne;
  AAlan: TAlan; AResimSiraNo: TISayi4);
var
  Renk: TSayi4;
  ResimAdresi: PSayi4;
  Sol, Ust, Sol2, Ust2,
  RGenislik, RYukseklik,              // resim
  TGenislik, TYukseklik: TISayi4;     // tuval
begin

  if(AResimSiraNo >= 0) and (AResimSiraNo < HAMRESIM_SAYISI) then
  begin

    // HamResimler - AKaynak = 1 ve iliþkili herþey iptal edilerek
    if(AKaynak = 1) then
    begin

      RGenislik := HamResimler[AResimSiraNo].Genislik;
      RYukseklik := HamResimler[AResimSiraNo].Yukseklik;
      ResimAdresi := HamResimler[AResimSiraNo].BellekAdresi;
    end
    else
    begin

      RGenislik := GiysiResimler[AResimSiraNo].Genislik;
      RYukseklik := GiysiResimler[AResimSiraNo].Yukseklik;
      ResimAdresi := GiysiResimler[AResimSiraNo].BellekAdresi;
    end;

    TGenislik := AAlan.Sag; // - AAlan.Sol;
    TYukseklik := AAlan.Alt; // - AAlan.Ust;

    if(TGenislik >= RGenislik) then
      Sol := (TGenislik div 2) - (RGenislik div 2)
    else Sol := 0;
    Sol += AAlan.Sol;

    if(TYukseklik >= RYukseklik) then
      Ust := (TYukseklik div 2) - (RYukseklik div 2)
    else Ust := 0;
    Ust += AAlan.Ust;

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
// bilgi: sistem.bmp dosyasýndaki resimleri çizer
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
// bilgi: sistem.bmp dosyasýndaki resimleri çizer
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
