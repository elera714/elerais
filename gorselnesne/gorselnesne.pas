{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: gorselnesne.pas
  Dosya ��levi: t�m g�rsel nesnelerin t�redi�i temel g�rsel ana yap�

  G�ncelleme Tarihi: 16/09/2024

  Bilgi: bu g�rsel yap�, t�m nesnelerin ihtiya� duyabilece�i ana yap�lar� i�erir

 ==============================================================================}
{$mode objfpc}
unit gorselnesne;

interface

uses paylasim, temelgorselnesne;

type
  PGorselNesne = ^TGorselNesne;
  PPGorselNesne = ^PGorselNesne;

  TOlaylariIsle = procedure(AGonderici: PGorselNesne; AOlay: TOlay) of object;

  TGorselNesne = object(TTemelGorselNesne)
  public
    // FCizimModel
    //   0: dolgu ve yaz� yok
    //   1: arka plan rengi yok, yaz� var
    //   2: arka plan rengi var, yaz� yok
    //   3: FGovdeRenk1 = kenarl�k rengi, FGovdeRenk2 = dolgu rengi
    //   4: FGovdeRenk1'den FGovdeRenk2'ye do�ru e�imli dolgu
    FCizimModel: TSayi4;
    FGovdeRenk1, FGovdeRenk2,
    FYaziRenk: TRenk;

    FTuvalNesne: PGorselNesne;                  // nesnenin �izim yap�laca�� en �st �izim nesnesi
    FAtaNesne: PGorselNesne;                    // nesnenin atas�
    FAltNesneBellekAdresi: PPGorselNesne;       // ata nesnenin alt nesneleri yerle�tirece�i bellek adresi
    FCizimBellekAdresi: Isaretci;
    FCizimBellekUzunlugu: TSayi4;

    OlayCagriAdresi: TOlaylariIsle;             // olaylar�n y�nlendirildi�i nesne olay �a�r� adresi
    OlayYonlendirmeAdresi: TOlaylariIsle;       // g�rsel nesneler taraf�ndan bile�enlerin olaylar�n�n y�nlendirilece�i olay adresi

    FEtiket: TSayi4;                            // nesneyi kullanacak program�n kullan�m� i�in

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
    function NesneTipiniAl(AKimlik: TKimlik): TGNTip;
    function NesneyiAl(AKimlik: TKimlik): PGorselNesne;
    function AtaNesneyiAl(AKimlik: TKimlik): PGorselNesne;
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

    // kernel i�in �a�r�lar (for kernel)
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
    procedure Dikdortgen(AGorselNesne: PGorselNesne; AAlan: TAlan; ACizgiRengi: TRenk);
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
    procedure YatayCizgi(AGorselNesne: PGorselNesne; ASol, AUst, ASag: TISayi4;
      ARenk: TRenk);
    procedure DikeyCizgi(AGorselNesne: PGorselNesne; ASol, AUst, AAlt: TISayi4;
      ARenk: TRenk);
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

    // program i�in �a�r�lar (for program)
    procedure Kesme_YaziYaz(ASol, AUst: TISayi4; AKarakterDizi: string; ARenk: TRenk);
    procedure Kesme_SayiYaz16(ASol, AUst: TISayi4; AOnEkYaz: LongBool;
      AHaneSayisi, ADeger: TISayi4; ARenk: TRenk);
    procedure Kesme_SaatYaz(ASol, AUst: TISayi4; ASaat: TSaat; ARenk: TRenk);
  end;

implementation

uses genel, genel8x16, donusum, bmp, gn_islevler, sistemmesaj, gn_pencere,
  hamresim, giysi_normal, giysi_mac;

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
  GorselNesne: PGorselNesne;
  //GorselNesneTipi: TGNTip;
begin

  if(AAtaNesne = nil) then
    AtaGorselNesne := nil
  else AtaGorselNesne := AtaGorselNesne^.NesneyiAl(AAtaNesne^.Kimlik);

  // g�rsel ana yap� nesnesini olu�tur
  GorselNesne := PGorselNesne(Olustur0(AGNTip));
  if(GorselNesne = nil) then Exit(nil);

  // g�rsel nesneyi ata nesneye ekle
  if not(AtaGorselNesne = nil) then
  begin

    if(GorselNesne^.AtaNesneyeEkle(AtaGorselNesne) = False) then
    begin

      // hata olmas� durumunda nesneyi yok et ve i�levden ��k
      GorselNesne^.YokEt;
      Exit(nil);
    end;
  end;

  // temel nesne de�erlerini ata
  GorselNesne^.GorevKimlik := CalisanGorev;
  GorselNesne^.AtaNesne := AtaGorselNesne;

  // nesne olaylar� �nde�er olarak nesneyi olu�turan programa y�nlendirilecek
  // aksi durumda belirtilen �a�r� adresine y�nlendirilecek
  GorselNesne^.OlayCagriAdresi := nil;
  GorselNesne^.OlayYonlendirmeAdresi := nil;

  GorselNesne^.FHiza := hzYok;

  GorselNesne^.FKalinlik.Sol := 0;
  GorselNesne^.FKalinlik.Ust := 0;
  GorselNesne^.FKalinlik.Sag := 0;
  GorselNesne^.FKalinlik.Alt := 0;

  GorselNesne^.FKonum.Sol := ASol;
  GorselNesne^.FKonum.Ust := AUst;
  GorselNesne^.FBoyut.Genislik := AGenislik;
  GorselNesne^.FBoyut.Yukseklik := AYukseklik;

  GorselNesne^.FIlkKonum := GorselNesne^.FKonum;
  GorselNesne^.FIlkBoyut := GorselNesne^.FBoyut;

  GorselNesne^.FKullanimTipi := AKullanimTipi;

  // �nde�er olarak �izim alan� ve alt �izim alan� e�it olarak de�erlendiriliyor
  // nesnenin kendisi bu de�eri de�i�tirebilir
  GorselNesne^.FCizimAlan.Sol := 0;
  GorselNesne^.FCizimAlan.Ust := 0;
  GorselNesne^.FCizimAlan.Sag := GorselNesne^.FBoyut.Genislik - 1;
  GorselNesne^.FCizimAlan.Alt := GorselNesne^.FBoyut.Yukseklik - 1;


  if(GorselNesne^.FKullanimTipi = ktNesne) then
  begin

    if(AtaGorselNesne = nil) then
    begin

      GorselNesne^.FCizimBaslangic.Sol := 0;
      GorselNesne^.FCizimBaslangic.Ust := 0;
    end
    else
    begin

      GorselNesne^.FCizimBaslangic.Sol := AtaGorselNesne^.FCizimBaslangic.Sol +
        AtaGorselNesne^.FKalinlik.Sol + ASol;
      GorselNesne^.FCizimBaslangic.Ust := AtaGorselNesne^.FCizimBaslangic.Ust +
        AtaGorselNesne^.FKalinlik.Ust + AUst;
    end;
  end
  else
  // bile�en
  begin

    GorselNesne^.FCizimBaslangic.Sol := AtaGorselNesne^.FCizimBaslangic.Sol + ASol;
    GorselNesne^.FCizimBaslangic.Ust := AtaGorselNesne^.FCizimBaslangic.Ust + AUst;
  end;

  GorselNesne^.FHiza := hzYok;
  GorselNesne^.FHizaAlani := GorselNesne^.FCizimAlan;

  // alt nesnelerin bellek adresi (nil = bellek olu�turulmad�)
  GorselNesne^.FAltNesneBellekAdresi := nil;

  // nesnenin alt nesne say�s�
  GorselNesne^.FAltNesneSayisi := 0;

  // nesnenin �zerine gelindi�inde g�r�nt�lenecek fare g�stergesi
  GorselNesne^.FFareImlecTipi := fitOK;

  // nesnenin g�r�n�m durumu
  GorselNesne^.Gorunum := False;

  // nesnenin ba�l�k de�eri
  GorselNesne^.FYaziHiza.Yatay := yhOrta;
  GorselNesne^.FYaziHiza.Dikey := dhOrta;
  GorselNesne^.Baslik := ABaslik;

  // nesnenin renk de�erleri
  GorselNesne^.FCizimModel := ACizimModel;
  GorselNesne^.FGovdeRenk1 := AGovdeRenk1;
  GorselNesne^.FGovdeRenk2 := AGovdeRenk2;
  GorselNesne^.FYaziRenk := AYaziRenk;

  GorselNesne^.FCiziliyor := False;

  GorselNesne^.FEtiket := 0;

  // nesne adresini geri d�nd�r
  Result := GorselNesne;
end;

{==============================================================================
  g�rsel nesne nesnesini olu�turur
 ==============================================================================}
function TGorselNesne.Olustur0(AGNTip: TGNTip): PGorselNesne;
var
  TemelGorselNesne: PTemelGorselNesne;
  i: TISayi4;
begin

  // t�m nesneleri ara
  for i := 1 to USTSINIR_GORSELNESNE do
  begin

    TemelGorselNesne := GorselNesneListesi[i];

    // e�er nesne kullan�lmam�� ise ...
    if(TemelGorselNesne^.Kimlik = HATA_KIMLIK) then
    begin

      // nesne i�eri�ini s�f�rla
      FillByte(TemelGorselNesne^, GN_UZUNLUK, 0);

      // kimlik de�erine s�ra no de�erini ver
      TemelGorselNesne^.Kimlik := i;
      TemelGorselNesne^.NesneTipi := AGNTip;

      //SISTEM_MESAJ_S10(RENK_KIRMIZI, 'TTemelGorselNesne yap� uzunlu�u: ', SizeOf(TTemelGorselNesne));
      //SISTEM_MESAJ_S10(RENK_KIRMIZI, 'TGorselNesne yap� uzunlu�u: ', SizeOf(TGorselNesne));

      // geri d�necek de�er
      Result := PGorselNesne(TemelGorselNesne);

      // olu�turulmu� nesne say�s�n� 1 art�r ve ��k
      Inc(ToplamGNSayisi);

      Exit;
    end;
  end;

  Result := nil;
end;

{==============================================================================
  g�rsel nesneyi yok eder
 ==============================================================================}
procedure TGorselNesne.YokEt;
begin

  // e�er nesne istenen aral�kta ise yok et
  if(Kimlik > 0) and (Kimlik <= USTSINIR_GORSELNESNE) then
  begin

    Kimlik := HATA_KIMLIK;
    Dec(ToplamGNSayisi);
    //Result := True;
  end //else Result := False;
end;

procedure TGorselNesne.Goster;
var
  Pencere: PPencere;
  GorselAnaYapi: PGorselNesne;
begin

  // nesnenin kimlik, tip de�erlerini denetle.
  GorselAnaYapi := PGorselNesne(GorselAnaYapi^.NesneTipiniKontrolEt(Kimlik, NesneTipi));
  if(GorselAnaYapi = nil) then Exit;

  // nesne g�r�n�r durumda m� ?
  if(GorselAnaYapi^.Gorunum = False) then
  begin

    // g�rsel ana yap� nesnesinin g�r�n�rl���n� aktifle�tir
    GorselAnaYapi^.Gorunum := True;

    // ata nesne g�r�n�r durumda m�?
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

  // nesnenin kimlik, tip de�erlerini denetle.
  GorselAnaYapi := PGorselNesne(GorselAnaYapi^.NesneTipiniKontrolEt(Kimlik, NesneTipi));
  if(GorselAnaYapi = nil) then Exit;

  // nesne g�r�n�r durumda m� ?
  if(GorselAnaYapi^.Gorunum = True) then
  begin

    // g�rsel ana yap� nesnesinin g�r�n�rl���n� aktifle�tir
    GorselAnaYapi^.Gorunum := False;

    // ata nesne g�r�n�r durumda m�?
    if(GorselAnaYapi^.AtaNesneGorunurMu) then
    begin

      // nesnenin sahibi olan pencere nesnesini al
      Pencere := EnUstPencereNesnesiniAl(GorselAnaYapi);
      if not(Pencere = nil) then Pencere^.Guncelle;
    end;
  end;

end;

{==============================================================================
  g�rsel ana nesnesini �izer
 ==============================================================================}
procedure TGorselNesne.Ciz;
var
  GorselNesne: PGorselNesne;
  CizimAlan: TAlan;
begin

  GorselNesne := GorselNesne^.NesneAl(Kimlik);
  if(GorselNesne = nil) then Exit;

  CizimAlan := GorselNesne^.FCizimAlan;

  // FCizimModel = 0 = hi�bir �izim yapma
  if(GorselNesne^.FCizimModel > 0) then
  begin

    // FCizimModel = 3 = kenarl��� �iz ve i�eri�i doldur
    if(GorselNesne^.FCizimModel = 2) then

      GorselNesne^.DikdortgenDoldur(GorselNesne, CizimAlan, FGovdeRenk1, FGovdeRenk2)

    // FCizimModel = 3 = kenarl��� �iz ve i�eri�i doldur
    else if(GorselNesne^.FCizimModel = 3) then

      GorselNesne^.DikdortgenDoldur(GorselNesne, CizimAlan.Sol, CizimAlan.Ust, CizimAlan.Sag, CizimAlan.Alt,
        FGovdeRenk1, FGovdeRenk2)

    // FCizimModel = 4 = artan renk ile (e�imli) doldur
    else if(GorselNesne^.FCizimModel = 4) then
      GorselNesne^.EgimliDoldur3(GorselNesne, CizimAlan, FGovdeRenk1, FGovdeRenk2);

    // g�rsel ana yap� ba�l���n� yaz
    if not(GorselNesne^.FCizimModel = 2) then
      if(Length(GorselNesne^.Baslik) > 0) then YaziYaz(GorselNesne, GorselNesne^.FYaziHiza,
        CizimAlan, Baslik, FYaziRenk);
  end;
end;

procedure TGorselNesne.BoyutlariYenidenHesapla;
var
  GorselAtaNesne, GorselNesne: PGorselNesne;
begin

  GorselNesne := GorselNesne^.NesneAl(Kimlik);
  if(GorselNesne = nil) then Exit;

  GorselNesne^.FCizimAlan.Sol := 0;
  GorselNesne^.FCizimAlan.Ust := 0;
  GorselNesne^.FCizimAlan.Sag := GorselNesne^.FBoyut.Genislik - 1;
  GorselNesne^.FCizimAlan.Alt := GorselNesne^.FBoyut.Yukseklik - 1;

  GorselAtaNesne := GorselNesne^.AtaNesne;

  if(GorselAtaNesne^.NesneTipi = gntPencere) then
  begin

    GorselNesne^.FCizimBaslangic.Sol := GorselNesne^.AtaNesne^.FKalinlik.Sol + GorselNesne^.FKonum.Sol;
    GorselNesne^.FCizimBaslangic.Ust := GorselNesne^.AtaNesne^.FKalinlik.Ust + GorselNesne^.FKonum.Ust;
  end
  else
  begin

    GorselNesne^.FCizimBaslangic.Sol := GorselNesne^.AtaNesne^.FCizimBaslangic.Sol + GorselNesne^.AtaNesne^.FKalinlik.Sol + GorselNesne^.FKonum.Sol;
    GorselNesne^.FCizimBaslangic.Ust := GorselNesne^.AtaNesne^.FCizimBaslangic.Ust + GorselNesne^.AtaNesne^.FKalinlik.Ust + GorselNesne^.FKonum.Ust;
  end;
end;

procedure TGorselNesne.HizaAlaniniSifirla;
var
  GorselNesne: PGorselNesne;
begin

  GorselNesne := GorselNesne^.NesneAl(Kimlik);
  if(GorselNesne = nil) then Exit;

  GorselNesne^.FHizaAlani.Sol := GorselNesne^.FCizimAlan.Sol;
  GorselNesne^.FHizaAlani.Ust := GorselNesne^.FCizimAlan.Ust;
  GorselNesne^.FHizaAlani.Sag := GorselNesne^.FCizimAlan.Sag;
  GorselNesne^.FHizaAlani.Alt := GorselNesne^.FCizimAlan.Alt;
end;

procedure TGorselNesne.Hizala;
var
  GorselAtaNesne, GorselNesne: PGorselNesne;
begin

  GorselNesne := PGorselNesne(@Self); // GorselNesne^.NesneAl(Kimlik);
  if(GorselNesne = nil) then Exit;

  GorselAtaNesne := GorselNesne^.AtaNesne;

  GorselNesne^.FBoyut := GorselNesne^.FIlkBoyut;
  GorselNesne^.FKonum := GorselNesne^.FIlkKonum;

  if(GorselNesne^.FHiza = hzSol) then
  begin

    //SISTEM_MESAJ(RENK_KIRMIZI, 'Boyut: %d', [GorselAtaNesne^.FBoyut.Yukseklik]);

    // nesnenin hesaplanmas�
    GorselNesne^.FKonum.Sol := GorselAtaNesne^.FHizaAlani.Sol;
    GorselNesne^.FKonum.Ust := GorselAtaNesne^.FHizaAlani.Ust;
    // nesnenin kendi geni�li�i kullan�lacak
    GorselNesne^.FBoyut.Yukseklik := (GorselAtaNesne^.FHizaAlani.Alt - GorselAtaNesne^.FHizaAlani.Ust) + 1;
    GorselNesne^.BoyutlariYenidenHesapla;

    // �st nesnenin yeniden boyutland�r�lmas�
    GorselAtaNesne^.FHizaAlani.Sol += GorselNesne^.FBoyut.Genislik;
  end
  else if(GorselNesne^.FHiza = hzUst) then
  begin

    GorselNesne^.FKonum.Sol := GorselAtaNesne^.FHizaAlani.Sol;
    GorselNesne^.FKonum.Ust := GorselAtaNesne^.FHizaAlani.Ust;
    GorselNesne^.FBoyut.Genislik := (GorselAtaNesne^.FHizaAlani.Sag - GorselAtaNesne^.FHizaAlani.Sol) + 1;
    // nesnenin kendi y�ksekli�i kullan�lacak
    GorselNesne^.BoyutlariYenidenHesapla;

    GorselAtaNesne^.FHizaAlani.Ust += GorselNesne^.FBoyut.Yukseklik;
  end
  else if(GorselNesne^.FHiza = hzSag) then
  begin

    // nesnenin hesaplanmas�
    GorselNesne^.FKonum.Sol := (GorselAtaNesne^.FHizaAlani.Sag - GorselNesne^.FBoyut.Genislik) + 1;
    GorselNesne^.FKonum.Ust := GorselAtaNesne^.FHizaAlani.Ust;
    // nesnenin kendi geni�li�i kullan�lacak
    GorselNesne^.FBoyut.Yukseklik := (GorselAtaNesne^.FHizaAlani.Alt - GorselAtaNesne^.FHizaAlani.Ust) + 1;
    GorselNesne^.BoyutlariYenidenHesapla;

    // �st nesnenin yeniden boyutland�r�lmas�
    GorselAtaNesne^.FHizaAlani.Sag -= GorselNesne^.FBoyut.Genislik;
  end
  else if(GorselNesne^.FHiza = hzAlt) then
  begin

    GorselNesne^.FKonum.Sol := GorselAtaNesne^.FHizaAlani.Sol;
    GorselNesne^.FKonum.Ust := (GorselAtaNesne^.FHizaAlani.Alt - GorselNesne^.FBoyut.Yukseklik) + 1;
    GorselNesne^.FBoyut.Genislik := (GorselAtaNesne^.FHizaAlani.Sag - GorselAtaNesne^.FHizaAlani.Sol) + 1;
    // nesnenin kendi y�ksekli�i kullan�lacak
    GorselNesne^.BoyutlariYenidenHesapla;

    GorselAtaNesne^.FHizaAlani.Alt -= GorselNesne^.FBoyut.Yukseklik;
  end
  else if(GorselNesne^.FHiza = hzTum) then
  begin

    GorselNesne^.FKonum.Sol := GorselAtaNesne^.FHizaAlani.Sol;
    GorselNesne^.FKonum.Ust := GorselAtaNesne^.FHizaAlani.Ust;
    GorselNesne^.FBoyut.Genislik := (GorselAtaNesne^.FHizaAlani.Sag - GorselAtaNesne^.FHizaAlani.Sol) + 1;
    GorselNesne^.FBoyut.Yukseklik := (GorselAtaNesne^.FHizaAlani.Alt - GorselAtaNesne^.FHizaAlani.Ust) + 1;
    GorselNesne^.BoyutlariYenidenHesapla;

//    GorselAtaNesne^.FHizaAlani.Alt -= GorselNesne^.FBoyut.Yukseklik;
  end else GorselNesne^.BoyutlariYenidenHesapla;
end;

{==============================================================================
  nesnenin nesne tipini kontrol eder
 ==============================================================================}
function TGorselNesne.NesneTipiniKontrolEt(AKimlik: TKimlik; AGNTip: TGNTip): PGorselNesne;
var
  GorselNesne: PGorselNesne;
begin

  // nesne istenen say� aral���nda ise
  if(AKimlik > 0) and (AKimlik <= USTSINIR_GORSELNESNE) then
  begin

    GorselNesne := GorselNesneListesi[AKimlik];

    // nesne olu�turulmu� mu ?
    if(GorselNesne^.Kimlik <> 0) then
    begin

      // nesne tipini kontrol et
      if(GorselNesne^.NesneTipi = AGNTip) then
        Exit(GorselNesne);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  nesnenin tipini al
 ==============================================================================}
function TGorselNesne.NesneTipiniAl(AKimlik: TKimlik): TGNTip;
var
  GorselNesne: PGorselNesne;
begin

  // nesne istenen say� aral���nda ise
  if(AKimlik > 0) and (AKimlik <= USTSINIR_GORSELNESNE) then
  begin

    GorselNesne := GorselNesneListesi[AKimlik];

    // nesne olu�turulmu� mu ?
    if(GorselNesne^.Kimlik <> 0) then
    begin

      // nesne tipini kontrol et
      Exit(GorselNesne^.NesneTipi);
    end;
  end;

  Result := gntTanimsiz;
end;

{==============================================================================
  nesneyi kimli�inden nesneyi al
 ==============================================================================}
function TGorselNesne.NesneyiAl(AKimlik: TKimlik): PGorselNesne;
begin

  // nesne istenen say� aral���nda ise
  if(AKimlik > 0) and (AKimlik <= USTSINIR_GORSELNESNE) then

    Result := PGorselNesne(GorselNesneListesi[AKimlik])

  else Result := nil;
end;

{==============================================================================
  nesnenin ba�l� oldu�u ata nesneyi al�r
 ==============================================================================}
function TGorselNesne.AtaNesneyiAl(AKimlik: TKimlik): PGorselNesne;
var
  GorselNesne: PGorselNesne;
begin

  // nesne istenen say� aral���nda ise
  if(AKimlik > 0) and (AKimlik <= USTSINIR_GORSELNESNE) then
  begin

    GorselNesne := GorselNesneListesi[AKimlik];

    while (GorselNesne <> nil) do
    begin

      if(GorselNesne^.FAltNesneSayisi > 0) then Exit(GorselNesne);
      GorselNesne := GorselNesne^.AtaNesne;
    end;
  end;

  Result := nil;
end;

{==============================================================================
  nesneyi ata nesnesine alt nesne olarak ekler
 ==============================================================================}
function TGorselNesne.AtaNesneyeEkle(AAtaNesne: PGorselNesne): Boolean;
var
  AltNesneBellekAdresi: PPGorselNesne;
  i: TISayi4;
begin

  // ata nesnenin alt nesneleri i�in bellek olu�turulmu� mu ?
  if(AAtaNesne^.FAltNesneBellekAdresi = nil) then
  begin

    // ata nesne i�in bellek olu�tur
    AltNesneBellekAdresi := GGercekBellek.Ayir(4096);
    AAtaNesne^.FAltNesneBellekAdresi := AltNesneBellekAdresi;
  end;

  // alt nesne toplam nesne say�s� a��lmam��sa ...
  if(AAtaNesne^.FAltNesneSayisi < 1024) then
  begin

    // �st nesnenin bellek adresini al
    AltNesneBellekAdresi := AAtaNesne^.FAltNesneBellekAdresi;

    // nesneyi �st nesneye kaydet
    AltNesneBellekAdresi[AAtaNesne^.FAltNesneSayisi] := @Self;

    // �st nesnenin nesne says�n� 1 art�r
    i := AAtaNesne^.FAltNesneSayisi;
    Inc(i);
    AAtaNesne^.FAltNesneSayisi := i;
    Result := True;
  end else Result := False;
end;

function TGorselNesne.AtaNesnedenCikar: Boolean;
begin

  { TODO - gerekti�inde kodlar yaz�labilir }
end;

{==============================================================================
  nesnenin pencereye (0, 0 koordinat�) ba�l� ger�ek koordinatlar�n� al�r
 ==============================================================================}
function TGorselNesne.CizimAlaniniAl(AKimlik: TKimlik): TAlan;
var
  Pencere: PPencere;
  GorselNesne: PGorselNesne;
begin

  // talepte bulunan nesnenin kimlik de�erini kontrol et
  GorselNesne := GorselNesneListesi[AKimlik];

  if((Self.NesneTipi = gntMasaustu) or (Self.NesneTipi = gntPencere) or
    (Self.NesneTipi = gntMenu) or (Self.NesneTipi = gntAcilirMenu)) then
  begin

    // geni�lik ve y�kseklik de�erleri al�n�yor
    Result.Sol := GorselNesne^.FKalinlik.Sol;
    Result.Ust := GorselNesne^.FKalinlik.Ust;
    Result.Sag := Result.Sol + GorselNesne^.FBoyut.Genislik;
    Result.Alt := Result.Ust + GorselNesne^.FBoyut.Yukseklik;
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

    Pencere := EnUstPencereNesnesiniAl(GorselNesne);

    Result.Sol := GorselNesne^.FCizimAlan.Sol - Pencere^.FCizimAlan.Sol;
    Result.Ust := GorselNesne^.FCizimAlan.Ust - Pencere^.FCizimAlan.Ust;
    Result.Sag := GorselNesne^.FCizimAlan.Sag - Pencere^.FCizimAlan.Sol;
    Result.Alt := GorselNesne^.FCizimAlan.Alt - Pencere^.FCizimAlan.Ust;
  end;
end;

{==============================================================================
  nesnenin �izilebilir alan�n�n koordinatlar�n� al�r
 ==============================================================================}
function TGorselNesne.CizimAlaniniAl2(AKimlik: TKimlik): TAlan;
var
  GorselNesne: PGorselNesne;
begin

  GorselNesne := GorselNesneListesi[AKimlik];

  // nesnenin �st nesneye ba�l� koordinatlar�n� al
  Result := CizimAlaniniAl(AKimlik);
end;

{==============================================================================
  belirtilen nesneden itibaren masa�st�ne kadar t�m nesnelerin g�r�n�rl���n�
  kontrol eder. (nesnenin kendisi de dahil)
 ==============================================================================}
function TGorselNesne.AtaNesneGorunurMu: Boolean;
var
  GorselNesne: PGorselNesne;
begin

  GorselNesne := @Self;

  repeat

    // nesne g�r�n�r durumdaysa AtaNesne nesnesini al
    if(GorselNesne^.Gorunum) then

      GorselNesne := GorselNesne^.AtaNesne
    else
    begin

      // aksi durumda ��k
      Result := False;
      Exit;
    end;

    // t�m nesneler test edildiyse olumlu yan�t ile geri d�n
    if(GorselNesne = nil) then Exit(True);

  until (True = False);
end;

{==============================================================================
  nesne kimlik de�erinden nesnenin bellek b�lgesini geri d�nd�r�r
 ==============================================================================}
function TGorselNesne.NesneAl(AKimlik: TKimlik): PGorselNesne;
begin

  Result := GorselNesneListesi[AKimlik];
end;

{==============================================================================
  fare g�stergesinin nesnenin olay alan�n�n i�erisinde olup
  olmad���n� kontrol eder
 ==============================================================================}
function TGorselNesne.FareNesneOlayAlanindaMi(AGorselNesne: PGorselNesne): Boolean;
var
  GorselNesne: PGorselNesne;
  Alan: TAlan;
begin

  GorselNesne := AGorselNesne;

  Alan.Sol := GorselNesne^.FCizimBaslangic.Sol;
  Alan.Ust := GorselNesne^.FCizimBaslangic.Ust;

  if(GorselNesne^.FTuvalNesne^.NesneTipi = gntPencere) or
    (GorselNesne^.FTuvalNesne^.NesneTipi = gntMenu) or
    (GorselNesne^.FTuvalNesne^.NesneTipi = gntAcilirMenu) then
  begin

    Alan.Sol += GorselNesne^.FTuvalNesne^.FKonum.Sol;
    Alan.Ust += GorselNesne^.FTuvalNesne^.FKonum.Ust;
  end;

  Alan.Sag := Alan.Sol + GorselNesne^.FCizimAlan.Sag;
  Alan.Alt := Alan.Ust + GorselNesne^.FCizimAlan.Alt;

  //SISTEM_MESAJ(RENK_KIRMIZI, 'Sol %d', [Alan.Sol]);
  //SISTEM_MESAJ(RENK_KIRMIZI, 'Ust %d', [Alan.Ust]);

  // �nde�er d�n�� de�eri
  Result := False;

  // fare belirtilen koordinatlar i�erisinde mi ?
  if(GFareSurucusu.YatayKonum < Alan.Sol) then Exit;
  if(GFareSurucusu.YatayKonum > Alan.Sag) then Exit;
  if(GFareSurucusu.DikeyKonum < Alan.Ust) then Exit;
  if(GFareSurucusu.DikeyKonum > Alan.Alt) then Exit;

  //SISTEM_MESAJ(RENK_KIRMIZI, '��eride Tamam', []);

  Result := True;
end;

{==============================================================================
  X, Y koordinat�n�n Rect alan� i�erisinde olup olmad���n� test eder
 ==============================================================================}
function TGorselNesne.NoktaAlanIcerisindeMi(NoktaA1, NoktaB1: TISayi4;
  AAlan: TAlan): Boolean;
begin

  Result := False;

  // fare belirtilen koordinatlar i�erisinde mi ?
  if(NoktaA1 < AAlan.Sol) then Exit;
  if(NoktaA1 > AAlan.Sag) then Exit;
  if(NoktaB1 < AAlan.Ust) then Exit;
  if(NoktaB1 > AAlan.Alt) then Exit;

  Result := True;
end;

{==============================================================================
  grafiksel koordinattaki pixeli i�aretler (boyar)
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

  // karakterler 0..255 aral���ndad�r.
	Karakter := KarakterListesi[Byte(AKarakter)];

  // e�er karakter bo�luk veya �izim gerektirmeyen karakter ise ��k
  if(Karakter.Yukseklik = 0) or (Karakter.Genislik = 0) then Exit;

  // karakterin ASol de�erine yatay tolerans koordinat�n� ekle
  ASol += Karakter.YT;

  // karakterin AUst de�erine dikey tolerans koordinat�n� ekle
  AUst += Karakter.DT;

  // karakterin geni�lik ve y�kseklik de�erlerini hesapla
  Genislik := ASol + Karakter.Genislik;
  Yukseklik := AUst + Karakter.Yukseklik;

  // karakterin pixel haritas�n�n bellek adresine konumlan
  KarakterAdres := Karakter.Adres;

  for j := AUst to Yukseklik - 1 do
  begin

		for i := ASol to Genislik - 1 do
    begin

      // ilgili pixeli belirtilen renkle i�aretle (boya)
			if(KarakterAdres^ = 1) then GEkranKartSurucusu.NoktaYaz(AGorselNesne, i, j,
        ARenk, True);

      // bir sonraki pixele konumlan
      Inc(KarakterAdres)
    end;
  end;
end;

{==============================================================================
  grafiksel ekrana karakter katar� yazar
 ==============================================================================}
procedure TGorselNesne.Kesme_YaziYaz(ASol, AUst: TISayi4; AKarakterDizi: string;
  ARenk: TRenk);
var
  Alan: TAlan;
begin

  Alan := CizimAlaniniAl2(Kimlik);
  YaziYaz(FAtaNesne, Alan.Sol + ASol, Alan.Ust + AUst, AKarakterDizi, ARenk);
end;

{==============================================================================
  grafiksel ekrana yaz� yazar
 ==============================================================================}
procedure TGorselNesne.YaziYaz(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4; AYazi: string;
  ARenk: TRenk);
var
  Sol, Ust, YaziU: TISayi4;
begin

  // karakter katar�n�n uzunlu�unu al
  YaziU := Length(AYazi);
  if(YaziU = 0) then Exit;

  Ust := ASol;
  for Sol := 1 to YaziU do
  begin

    // karakteri yaz
    HarfYaz(AGorselNesne, Ust, AUst, AYazi[Sol], ARenk);

    // karakter geni�li�ini geni�lik de�erine ekle
    Ust += 8;
  end;
end;

{==============================================================================
  grafiksel ekrana hizalayarak yaz� yazar
 ==============================================================================}
procedure TGorselNesne.YaziYaz(AGorselNesne: PGorselNesne; AYaziHiza: TYaziHiza;
  AAlan: TAlan; AYazi: string; ARenk: TRenk);
var
  i, j, Sol, Ust: TISayi4;
begin

  // karakter katar�n�n uzunlu�unu al
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

    // karakter geni�li�ini geni�lik de�erine ekle
    Sol += 8;
  end;
end;

{==============================================================================
  dikd�rtgensel (4 nokta) grafiksel ekrana karakter katar� yazar
 ==============================================================================}
// �nemli bilgi: �u a�amada �oklu sat�r i�levi olmad��� i�in Y1 -> Y2 kontrol� YAPILMAMAKTADIR
procedure TGorselNesne.AlanaYaziYaz(AGorselNesne: PGorselNesne; AAlan: TAlan;
  ASol, AUst: TISayi4; AKarakterDizi: string; ARenk: TRenk);
var
  KarakterDiziUz, i,
  Sol, Ust: TISayi4;
begin

  {
      AAlan.Sol:AAlan.Ust = sol �st k��e (�rn: 100, 100)
      AAlan.Sag:AAlan.Alt = sa� alt k��e (�rn: 200, 200)
      ASol = �izim AAlan.Sol'den ka� pixel uzakl�ktan ba�layacak (�rn: 10 = 110)
      AUst = �izim AAlan.Ust'den ka� pixel uzakl�ktan ba�layacak (�rn: 12 = 112)
  }

  // karakter katar�n�n uzunlu�unu al
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

    // karakter geni�li�ini x de�erine ekle
    Sol += 8;
  end;
end;

{==============================================================================
  grafiksel ekrana integer say� yazar
 ==============================================================================}
procedure TGorselNesne.SayiYaz10(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4;
  ASayi: TISayi4; ARenk: TRenk);
var
  Deger: array[0..11] of Char;
begin

  // desimal de�eri string de�ere �evir
  Deger := IntToStr(ASayi);

  // say�sal de�eri ekrana yaz
  YaziYaz(AGorselNesne, ASol, AUst, Deger, ARenk);
end;

{==============================================================================
  grafiksel ekrana 16l� tabanda say� yazar
 ==============================================================================}
procedure TGorselNesne.Kesme_SayiYaz16(ASol, AUst: TISayi4; AOnEkYaz: LongBool;
  AHaneSayisi, ADeger: TISayi4; ARenk: TRenk);
var
  Deger: string[10];
  Alan: TAlan;
begin

  // hexadesimal de�eri string de�ere �evir
  if(AOnEkYaz) then
    Deger := '0x' + hexStr(ADeger, AHaneSayisi)
  else Deger := hexStr(ADeger, AHaneSayisi);

  Alan := CizimAlaniniAl2(Kimlik);

  // say�sal de�eri ekrana yaz
  YaziYaz(FAtaNesne, Alan.Sol + ASol, Alan.Ust + AUst, Deger, ARenk);
end;

{==============================================================================
  grafiksel ekrana hexadesimal say� yazar
 ==============================================================================}
procedure TGorselNesne.SayiYaz16(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4;
  AOnEkYaz: LongBool; AHaneSayisi, ADeger: TISayi4; ARenk: TRenk);
var
  Deger: string[10];
begin

  // hexadesimal de�eri string de�ere �evir
  if(AOnEkYaz) then
    Deger := '0x' + hexStr(ADeger, AHaneSayisi)
  else Deger := hexStr(ADeger, AHaneSayisi);

  // say�sal de�eri ekrana yaz
  YaziYaz(AGorselNesne, ASol, AUst, Deger, ARenk);
end;

{==============================================================================
  grafiksel ekrana belirtilen saat de�erini yazar
 ==============================================================================}
procedure TGorselNesne.Kesme_SaatYaz(ASol, AUst: TISayi4; ASaat: TSaat; ARenk: TRenk);
var
  Saat: string[8];
  Alan: TAlan;
begin

  // saat de�erini karakter katar�na �evir
  Saat := TimeToStr(ASaat);

  Alan := CizimAlaniniAl2(Kimlik);

  // saat de�erini belirtilen koordinatlara yaz
  YaziYaz(FAtaNesne, Alan.Sol + ASol, Alan.Ust + AUst, Saat, ARenk);
end;

{==============================================================================
  grafiksel ekrana belirtilen saat de�erini yazar
 ==============================================================================}
procedure TGorselNesne.SaatYaz(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4;
  ASaat: TSaat; ARenk: TRenk);
var
  Saat: string[8];
begin

  // saat de�erini karakter katar�na �evir
  Saat := TimeToStr(ASaat);

  // saat de�erini belirtilen koordinatlara yaz
  YaziYaz(AGorselNesne, ASol, AUst, Saat, ARenk);
end;

{==============================================================================
  grafiksel ekrana mac adres de�erini yazar
 ==============================================================================}
procedure TGorselNesne.MACAdresiYaz(AGorselNesne: PGorselNesne; ASol, AUst: TISayi4;
  AMACAdres: TMACAdres; ARenk: TRenk);
var
  MACAdres: string[17];
begin

  // MAC adres de�erini karakter katar�na �evir
  MACAdres := MAC_KarakterKatari(AMACAdres);

  // MAC adres de�erini belirtilen koordinatlara yaz
  YaziYaz(AGorselNesne, ASol, AUst, MACAdres, ARenk);
end;

{==============================================================================
  grafiksel ekrana ip adres de�erini yazar
 ==============================================================================}
procedure TGorselNesne.IPAdresiYaz(AGorselNesne: PGorselNesne; ASol, AUst: TSayi4;
  AIPAdres: TIPAdres; ARenk: TRenk);
var
  IPAdres: string[15];
begin

  // IP adres de�erini karakter katar�na �evir
  IPAdres := IP_KarakterKatari(AIPAdres);

  // ip adres de�erini belirtilen koordinatlara yaz
  YaziYaz(AGorselNesne, ASol, AUst, IPAdres, ARenk);
end;

{==============================================================================
  nesneye belirtilen renkte dikd�rtgen �izer
 ==============================================================================}
procedure TGorselNesne.Dikdortgen(AGorselNesne: PGorselNesne; AAlan: TAlan; ACizgiRengi: TRenk);
begin

  // �st yatay �izgiyi �iz
  YatayCizgi(AGorselNesne, AAlan.Sol, AAlan.Ust, AAlan.Sag, ACizgiRengi);

  // sol dikey �izgiyi �iz
  DikeyCizgi(AGorselNesne, AAlan.Sol, AAlan.Ust, AAlan.Alt, ACizgiRengi);

  // alt yatay �izgiyi �iz
  YatayCizgi(AGorselNesne, AAlan.Sag, AAlan.Alt, AAlan.Sol, ACizgiRengi);

  // sa� dikey �izgiyi �iz
  DikeyCizgi(AGorselNesne, AAlan.Sag, AAlan.Alt, AAlan.Ust, ACizgiRengi);
end;

{==============================================================================
  nesnenin dikd�rtgensel olarak s�n�rland�r�lm�� alan�na belirtilen renkte i�i
  doldurulmu� dikd�rtgen �izer. (not: test edilecek)
 ==============================================================================}
procedure TGorselNesne.Doldur4(AGorselNesne: PGorselNesne; AAlan: TAlan; ASol, AUst,
  ASag, AAlt: TISayi4; ACizgiRengi, ADolguRengi: TRenk);
var
  Alan: TAlan;
  i, j, Sol, Ust, Sag, Alt: TISayi4;
begin

  // �izim koordinatlar�n�n�n s�n�rlar�n i�erisinde olup olmad���n� kontrol et
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

  // d�� kenarl�k
  Alan.Sol := Sol;
  Alan.Ust := Ust;
  Alan.Sag := Sag;
  Alan.Alt := Alt;
  Dikdortgen(AGorselNesne, Alan, ACizgiRengi);

  // i� kenarl�k
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
  nesneye belirtilen renkte i�i doldurulmu� dikd�rtgen �izer
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
  nesneye belirtilen renkte i�i doldurulmu� dikd�rtgen �izer
 ==============================================================================}
procedure TGorselNesne.DikdortgenDoldur(AGorselNesne: PGorselNesne; AAlan: TAlan;
  ACizgiRengi, ADolguRengi: TRenk);
var
  i, j: TISayi4;
begin

  // d�� kenarl�k
  Dikdortgen(AGorselNesne, AAlan, ACizgiRengi);

  // i� kenarl�k
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
  nesneye belirtilen renkte �izgi �izer
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
      if(AdimSayisi = 3) then
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
  nesneye daire �ekli �izer
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
  nesneye i�i boyal� daire �ekli �izer
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
  nesneye belirtilen renkte yatay �izgi �izer
 ==============================================================================}
procedure TGorselNesne.YatayCizgi(AGorselNesne: PGorselNesne; ASol, AUst, ASag: TISayi4;
  ARenk: TRenk);
var
  i: TISayi4;
begin

  // e�er ASol > ASag ise ASag ile ASol de�erlerini yer de�i�tir.
  if(ASol > ASag) then
  begin

    i := ASag;
    ASag := ASol;
    ASol := i;
  end;

  // pixel'in nesneye ait olup olmad���n� kontrol ederek i�aretleme yap
  for i := ASol to ASag do GEkranKartSurucusu.NoktaYaz(AGorselNesne, i, AUst, ARenk, True);
end;

{==============================================================================
  nesneye belirtilen renkte dikey �izgi �izer
 ==============================================================================}
procedure TGorselNesne.DikeyCizgi(AGorselNesne: PGorselNesne; ASol, AUst, AAlt: TISayi4;
  ARenk: TRenk);
var
  i: TISayi4;
begin

  // e�er AUst > AAlt ise AAlt ile AUst de�erlerini yer de�i�tir.
  if(AUst > AAlt) then
  begin

    i := AAlt;
    AAlt := AUst;
    AUst := i;
  end;

  // pixel'in nesneye ait olup olmad���n� kontrol ederek i�aretleme yap
  for i := AUst to AAlt do GEkranKartSurucusu.NoktaYaz(AGorselNesne, ASol, i, ARenk, True);
end;

// yukar�dan a�a��ya e�imli doldurma i�lemi
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

// soldan sa�a e�imli doldurma i�lemi
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

// dikey olarak; 1. renkten 2. renge �stten ortaya kadar; 2. renkten 1. renge ortadan alta kadar
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

    // ilk �st ve sol �izgiyi �iz
    YatayCizgi(AGorselNesne, AAlan.Sol, AAlan.Ust, AAlan.Sag-1, $808080);
    DikeyCizgi(AGorselNesne, AAlan.Sol, AAlan.Ust, AAlan.Alt-1, $808080);

    // ilk alt ve sa� �izgiyi �iz
    YatayCizgi(AGorselNesne, AAlan.Sag, AAlan.Alt, AAlan.Sol, $EFEFEF);
    DikeyCizgi(AGorselNesne, AAlan.Sag, AAlan.Alt, AAlan.Ust, $EFEFEF);

    if(AKalinlik > 1) then
    begin

      for i := 1 to AKalinlik - 1 do
      begin

        // i�e do�ru di�er �st ve sol �izgiyi �iz
        YatayCizgi(AGorselNesne, AAlan.Sol + i, AAlan.Ust + i, AAlan.Sag - i - 1, $404040);
        DikeyCizgi(AGorselNesne, AAlan.Sol + i, AAlan.Ust + i, AAlan.Alt - i - 1, $404040);

        // i�e do�ru di�er alt ve sa� �izgiyi �iz
        YatayCizgi(AGorselNesne, AAlan.Sag - i, AAlan.Alt - i, AAlan.Sol + i, $D4D0C8);
        DikeyCizgi(AGorselNesne, AAlan.Sag - i, AAlan.Alt - i, AAlan.Ust + i, $D4D0C8);
      end;
    end;
  end;
end;

// g�rsel nesneye ham resim �izer
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

      // yeni �izilecek cursor'�n bitmap b�lgesine konumlan
      Renk := BaslatMenuResimAdresi^;

      PixelYaz(AGorselNesne, ASol + (Sol - 1), AUst + (Ust - 1), Renk);

      Inc(BaslatMenuResimAdresi);
    end;
  end;
end;

// g�rsel nesneye sistem kaynak resimlerinden resim �izer
// bilgi: hamresim.pas dosyas�ndaki resimleri �izer
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

// g�rsel nesneye sistem kaynak resimlerinden resim �izer
// bilgi: sistem.bmp dosyas�ndaki resimleri �izer
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

    for Ust := 1 to 24 do
    begin

      for Sol := 1 to 24 do
      begin

        // �izilecek resmin bitmap b�lgesine konumlan
        Renk := BaslatMenuResimAdresi^;

        PixelYaz(AGorselNesne, ASol + (Sol - 1), AUst + (Ust - 1), Renk);

        Inc(BaslatMenuResimAdresi);
      end;
    end;
  end;
end;

end.