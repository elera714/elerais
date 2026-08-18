{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_islevler.pas
  Dosya İşlevi: görsel nesne (visual object) işlevlerini içerir

  Güncelleme Tarihi: 18/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_islevler;

interface

uses gorselnesne, paylasim, gn_masaustu, gn_pencere, gn_menu;

type
  PGorselNesneler = ^TGorselNesneler;
  TGorselNesneler = class
  private
    FGorselNesneListesi: array[0..USTSINIR_GORSELNESNE - 1] of TGorselNesne;
    FMasaustuListesi: array[0..USTSINIR_MASAUSTU - 1] of TMasaustu;
    function GNAl(ASiraNo: TISayi4): TGorselNesne;
    procedure GNYaz(ASiraNo: TISayi4; AGorselNesne: TGorselNesne);
    function MUAl(ASiraNo: TISayi4): TMasaustu;
    procedure MUYaz(ASiraNo: TISayi4; AMasaustu: TMasaustu);
  public
    FToplamGorselNesne,
    FToplamMasaustu: TSayi4;
    FAktifMasaustu: TMasaustu;
    FAktifPencere: TPencere;
    // TMenu veya TAcilirMenu
    FAktifMenu: TMenu;
    // farenin, üzerine sol tuş ile basılıp seçildiği nesne
    FYakalananGorselNesne: TGorselNesne;
    constructor Create;
    procedure YokEt(AGorselNesne: TGorselNesne; AAtaNesnedenCikar: Boolean = True);
    function KimlikNoAl: TISayi4;
    function GorselNesneBul(var AKonum: TKonum): TGorselNesne;
    function AtaNesneyeEkle(AGorselNesne, AAtaNesne: TGorselNesne): Boolean;
    function AtaNesnedenCikar(AGorselNesne: TGorselNesne): Boolean;
    function NesneAl(AKimlik: TKimlik): TGorselNesne;
    function NesneTipiniKontrolEt(AKimlik: TKimlik; AGNTip: TGNTip): TGorselNesne;
    procedure PencereyiYokEt(AGorevKimlik: TKimlik);
    procedure PencereleriYenidenCiz;
    function EnUstNesneyiAl(AGorselNesne: TGorselNesne): TGorselNesne;
    function EnUstPencereNesnesiniAl(AGorselNesne: TGorselNesne): TPencere;
    procedure OlayYakalamayaBasla(AGorselNesne: TGorselNesne);
    procedure OlayYakalamayiBirak(AGorselNesne: TGorselNesne);
    property GorselNesne[ASiraNo: TISayi4]: TGorselNesne read GNAl write GNYaz;
    property Masaustleri[ASiraNo: TISayi4]: TMasaustu read MUAl write MUYaz;
  published
    property ToplamGorselNesne: TSayi4 read FToplamGorselNesne write FToplamGorselNesne;
    property ToplamMasaustu: TSayi4 read FToplamMasaustu write FToplamMasaustu;
    property AktifMasaustu: TMasaustu read FAktifMasaustu write FAktifMasaustu;
    property AktifPencere: TPencere read FAktifPencere write FAktifPencere;
    property AktifMenu: TMenu read FAktifMenu write FAktifMenu;
    property YakalananGorselNesne: TGorselNesne read FYakalananGorselNesne;
  end;

var
  GGNesneler: TGorselNesneler;
  GorselNesnelerKilit: TSayi4 = 0;

function GorselNesneIslevCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses islevler, sistemmesaj, gorev, gn_araccubugu, gn_baglanti, gn_degerlistesi, gn_dugme,
  gn_defter, gn_degerdugmesi, gn_durumcubugu, gn_resimdugmesi, gn_sayfakontrol, gn_secimdugmesi,
  gn_etiket, gn_giriskutusu, gn_gucdugmesi, gn_islemgostergesi, gn_izgara, gn_onaykutusu,
  gn_karmaliste, gn_kaydirmacubugu, gn_listegorunum, gn_listekutusu, gn_renksecici, gn_resim,
  gn_panel;

{==============================================================================
  genel nesne çağrılarını yönetir
 ==============================================================================}
function GorselNesneIslevCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  Kimlik: TKimlik;
  BellekAdresi: Isaretci;
  Konum: TKonum;
begin

  Result := HATA_ISLEV;

  // yatay & dikey koordinattaki nesneyi al
  if(AIslevNo = 1) then
  begin

    Konum.Sol := PISayi4(ADegiskenler + 00)^;
    Konum.Ust := PISayi4(ADegiskenler + 04)^;
    GN := GGNesneler.GorselNesneBul(Konum);
    Result := GN.Kimlik;
  end

  // görsel nesne bilgilerini hedef bellek bölgesine kopyala
  // bilgi: bu işlevin alt yapı çalışması yapılacak
  else if(AIslevNo = 2) then
  begin

    Kimlik := PISayi4(ADegiskenler + 00)^;
    if(Kimlik >= 0) and (Kimlik < USTSINIR_GORSELNESNE) then
    begin

      { TODO - önceden object yapısı class yapısına dönüştürüldüğünden dolayı işlev
        iptal edilmiştir. gerekliliği kontrol edilsin }
      {GN := GGorselNesneler.GorselNesne[Kimlik];
      BellekAdresi := Isaretci(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
      Tasi2(GN, BellekAdresi, GN_UZUNLUK);}

      Result := 1;
    end else Result := 0;
  end

  // yatay & dikey koordinattaki nesnenin adını al
  else if(AIslevNo = 3) then
  begin

    Konum.Sol := PISayi4(ADegiskenler + 00)^;
    Konum.Ust := PISayi4(ADegiskenler + 04)^;

    GN := GGNesneler.GorselNesneBul(Konum);
    BellekAdresi := Isaretci(PSayi4(ADegiskenler + 08)^ + GGorevler.FAktifGrvBelAdr);
    Tasi2(@GN.NesneAdi[0], BellekAdresi, Length(GN.NesneAdi) + 1);
  end;
end;

{==============================================================================
  görsel nesne yönetim ostamının yükleme işlevlerini gerçekleştirir
 ==============================================================================}
constructor TGorselNesneler.Create;
var
  i: TSayi4;
begin

  // görsel nesne depolama alanlarını sıfırla
  for i := 0 to USTSINIR_GORSELNESNE - 1 do GorselNesne[i] := nil;

  // masaüstü görsel nesne depolama alanlarını sıfırla
  for i := 0 to USTSINIR_MASAUSTU - 1 do FMasaustuListesi[i] := nil;

  // görsel nesne değişkenlerini ilk değerlerle yükle
  FToplamMasaustu := 0;
  FToplamGorselNesne := 0;
  FAktifMasaustu := nil;
  FAktifPencere := nil;
  FAktifPencere := nil;
  FAktifMenu := nil;
  FYakalananGorselNesne := nil;
end;

{==============================================================================
  görsel nesneyi yok eder
 ==============================================================================}
procedure TGorselNesneler.YokEt(AGorselNesne: TGorselNesne; AAtaNesnedenCikar: Boolean = True);
begin

//  while KritikBolgeyeGir(GorselNesnelerKilit) = False do;

  // eğer nesne istenen aralıkta ise yok et
  if not(AGorselNesne = nil) then
  begin

    if(AAtaNesnedenCikar) then AtaNesnedenCikar(AGorselNesne);

    GorselNesne[AGorselNesne.Kimlik shr 10] := nil;

    Dec(FToplamGorselNesne);
  end;

//  KritikBolgedenCik(GorselNesnelerKilit);
end;

function TGorselNesneler.GNAl(ASiraNo: TISayi4): TGorselNesne;
begin

  // belirtilen nesne yapısını veri aralığını kontrol ederek al
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_GORSELNESNE) then
    Result := FGorselNesneListesi[ASiraNo]
  else Result := nil;
end;

procedure TGorselNesneler.GNYaz(ASiraNo: TISayi4; AGorselNesne: TGorselNesne);
begin

  // belirtilen nesne yapısını veri aralığını kontrol ederek yaz
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_GORSELNESNE) then
    FGorselNesneListesi[ASiraNo] := AGorselNesne;
end;

function TGorselNesneler.MUAl(ASiraNo: TISayi4): TMasaustu;
begin

  // belirtilen nesne yapısını veri aralığını kontrol ederek al
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_MASAUSTU) then
    Result := FMasaustuListesi[ASiraNo]
  else Result := nil;
end;

procedure TGorselNesneler.MUYaz(ASiraNo: TISayi4; AMasaustu: TMasaustu);
begin

  // belirtilen nesne yapısını veri aralığını kontrol ederek yaz
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_MASAUSTU) then
    FMasaustuListesi[ASiraNo] := AMasaustu;
end;

{==============================================================================
  görsel nesne için kimlik numarası oluşturur
 ==============================================================================}
function TGorselNesneler.KimlikNoAl: TISayi4;
var
  GN: TGorselNesne;
  i: TISayi4;
begin

  Result := -1;

  for i := 0 to USTSINIR_GORSELNESNE - 1 do
  begin

    GN := GorselNesne[i];

    // eğer nesne oluşturulmamış ise
    if(GN = nil) then Exit(i);
  end;
end;

{==============================================================================
  belirtilen koordinattaki nesneyi bulur
 ==============================================================================}
function TGorselNesneler.GorselNesneBul(var AKonum: TKonum): TGorselNesne;
var
  PencereGN, SonBulunanGN, SorgulananGN,
  GenelGN: TGorselNesne;
  i, j: TSayi4;
  SonNesneA, NesneA: TAlan;
  PencereTipi: TPencereTipi;

  function AlanIcindeMi(AAlan: TAlan): Boolean;
  begin

    // farenin nesne koordinatları içerisinde olup olmadığını kontrol et
    Result := False;
    if(AKonum.Sol < AAlan.Sol) then Exit;
    if(AKonum.Sol > AAlan.Sag) then Exit;
    if(AKonum.Ust < AAlan.Ust) then Exit;
    if(AKonum.Ust > AAlan.Alt) then Exit;

    // tüm koşullar sağlanmışsa fare belirtilen nesnenin alanı içerisindedir
    Result := True;
  end;
begin

  Result := nil;

  // aktif masaüstü yok ise nil değeri ile çık
  if(GGNesneler.AktifMasaustu = nil) then Exit;

  // 1. aktif menü mevcut mu? kontrol et
  SonBulunanGN := GGNesneler.AktifMenu;
  if(SonBulunanGN <> nil) then
  begin

    if(SonBulunanGN.Gorunum) then
    begin

      SonNesneA.Sol := SonBulunanGN.FAtananAlan.Sol;
      SonNesneA.Ust := SonBulunanGN.FAtananAlan.Ust;
      SonNesneA.Sag := SonNesneA.Sol + SonBulunanGN.FAtananAlan.Genislik;
      SonNesneA.Alt := SonNesneA.Ust + SonBulunanGN.FAtananAlan.Yukseklik;

      if(AlanIcindeMi(SonNesneA)) then
      begin

        AKonum.Sol := AKonum.Sol - SonBulunanGN.FAtananAlan.Sol;
        AKonum.Ust := AKonum.Ust - SonBulunanGN.FAtananAlan.Ust;
        Exit(SonBulunanGN);
      end;
    end;
  end;

  // 2. aktif masaüstünün sorgulanması
  SonBulunanGN := GGNesneler.AktifMasaustu;

  SonNesneA.Sol := SonBulunanGN.FAtananAlan.Sol + SonBulunanGN.FKalinlik.Sol;
  SonNesneA.Ust := SonBulunanGN.FAtananAlan.Ust + SonBulunanGN.FKalinlik.Ust;
  SonNesneA.Sag := SonNesneA.Sol + SonBulunanGN.FAtananAlan.Genislik;
  SonNesneA.Alt := SonNesneA.Ust + SonBulunanGN.FAtananAlan.Yukseklik;

  if(SonBulunanGN.AltNesneSayisi = 0) then
  begin

    AKonum.Sol := AKonum.Sol - SonBulunanGN.FAtananAlan.Sol;
    AKonum.Ust := AKonum.Ust - SonBulunanGN.FAtananAlan.Ust;
    Exit(SonBulunanGN);
  end;

  // 3. pencerelerin sorgulanması
  if(SonBulunanGN.AltNesneSayisi > 0) then
  begin

    // alt nesnesi olan nesnenin alt nesnelerini ara. sondan başa doğru (3..0 gibi)
    for i := SonBulunanGN.AltNesneSayisi - 1 downto 0 do
    begin

      // görsel nesneyi al
      PencereGN := PGorselNesne(SonBulunanGN.AltNesneBellekAdresi)[i];

      if(PencereGN.NesneTipi = gntPencere) then
      begin

        // görsel nesne görünür durumda mı ?
        if(PencereGN.Gorunum) then
        begin

          NesneA.Sol := SonNesneA.Sol + PencereGN.FAtananAlan.Sol;
          NesneA.Ust := SonNesneA.Ust + PencereGN.FAtananAlan.Ust;
          NesneA.Sag := NesneA.Sol + PencereGN.FAtananAlan.Genislik;
          NesneA.Alt := NesneA.Ust + PencereGN.FAtananAlan.Yukseklik;

          // fare görsel nesne alan içerisinde mi ?
          if(AlanIcindeMi(NesneA)) then
          begin

            SonNesneA.Sol := NesneA.Sol;
            SonNesneA.Ust := NesneA.Ust;

            // 3.1 kontrol düğmelerinin sorgulanması
            PencereTipi := TPencere(PencereGN).FPencereTipi;
            if(PencereTipi = ptBoyutlanabilir) or (PencereTipi = ptIletisim) then
            begin

              // kapatma düğmesinin sorgulanması
              SorgulananGN := TPencere(PencereGN).FKapatmaDugmesi;
              NesneA.Sol := SonNesneA.Sol + SorgulananGN.FAtananAlan.Sol;
              NesneA.Ust := SonNesneA.Ust + SorgulananGN.FAtananAlan.Ust;
              NesneA.Sag := NesneA.Sol + SorgulananGN.FAtananAlan.Genislik;
              NesneA.Alt := NesneA.Ust + SorgulananGN.FAtananAlan.Yukseklik;

              if(AlanIcindeMi(NesneA)) then
              begin

                AKonum.Sol := (AKonum.Sol - NesneA.Sol);
                AKonum.Ust := (AKonum.Ust - NesneA.Ust);
                Exit(SorgulananGN);
              end;

              if(PencereTipi = ptBoyutlanabilir) then
              begin

                // küçültme düğmesinin sorgulanması
                SorgulananGN := TPencere(PencereGN).FKucultmeDugmesi;
                NesneA.Sol := SonNesneA.Sol + SorgulananGN.FAtananAlan.Sol;
                NesneA.Ust := SonNesneA.Ust + SorgulananGN.FAtananAlan.Ust;
                NesneA.Sag := NesneA.Sol + SorgulananGN.FAtananAlan.Genislik;
                NesneA.Alt := NesneA.Ust + SorgulananGN.FAtananAlan.Yukseklik;

                if(AlanIcindeMi(NesneA)) then
                begin

                  AKonum.Sol := (AKonum.Sol - NesneA.Sol);
                  AKonum.Ust := (AKonum.Ust - NesneA.Ust);
                  Exit(SorgulananGN);
                end;

                // büyütme düğmesinin sorgulanması
                SorgulananGN := TPencere(PencereGN).FBuyutmeDugmesi;
                NesneA.Sol := SonNesneA.Sol + SorgulananGN.FAtananAlan.Sol;
                NesneA.Ust := SonNesneA.Ust + SorgulananGN.FAtananAlan.Ust;
                NesneA.Sag := NesneA.Sol + SorgulananGN.FAtananAlan.Genislik;
                NesneA.Alt := NesneA.Ust + SorgulananGN.FAtananAlan.Yukseklik;

                if(AlanIcindeMi(NesneA)) then
                begin

                  AKonum.Sol := (AKonum.Sol - NesneA.Sol);
                  AKonum.Ust := (AKonum.Ust - NesneA.Ust);
                  Exit(SorgulananGN);
                end;
              end;
            end;

            // pencere nesnesinin kalınlığını da son koordinata ekle
            SonNesneA.Sol := SonNesneA.Sol + PencereGN.FKalinlik.Sol;
            SonNesneA.Ust := SonNesneA.Ust + PencereGN.FKalinlik.Ust;
            SonBulunanGN := PencereGN;

            // 4 - alt nesnelerin sorgulanması
            while True do
            begin

              GenelGN := nil;

              if(SonBulunanGN.AltNesneSayisi > 0) then
              begin

                // alt nesnesi olan nesnenin alt nesnelerini ara. sondan başa doğru (3..0 gibi)
                for j := SonBulunanGN.AltNesneSayisi - 1 downto 0 do
                begin

                  // görsel nesneyi al
                  SorgulananGN := PGorselNesne(SonBulunanGN.AltNesneBellekAdresi)[j];

                  // görsel nesne görünür durumda mı ?
                  if(SorgulananGN.Gorunum) then
                  begin

                    NesneA.Sol := SonNesneA.Sol + SorgulananGN.FAtananAlan.Sol;
                    NesneA.Ust := SonNesneA.Ust + SorgulananGN.FAtananAlan.Ust;
                    NesneA.Sag := NesneA.Sol + SorgulananGN.FAtananAlan.Genislik;
                    NesneA.Alt := NesneA.Ust + SorgulananGN.FAtananAlan.Yukseklik;

                    // fare görsel nesne alan içerisinde mi ?
                    if(AlanIcindeMi(NesneA)) then
                    begin

                      SonNesneA.Sol := NesneA.Sol;
                      SonNesneA.Ust := NesneA.Ust;
                      GenelGN := SorgulananGN;
                      SonBulunanGN := GenelGN;
                      Break;
                    end;
                  end;
                end;

                if(GenelGN = nil) then
                begin

                  if(SonBulunanGN.NesneTipi = gntPencere) then
                  begin

                    SonNesneA.Sol := SonNesneA.Sol - SonBulunanGN.FKalinlik.Sol;
                    SonNesneA.Ust := SonNesneA.Ust - SonBulunanGN.FKalinlik.Ust;

                    AKonum.Sol := (AKonum.Sol - SonNesneA.Sol);
                    AKonum.Ust := (AKonum.Ust - SonNesneA.Ust);
                    Exit(SonBulunanGN);
                  end
                  else
                  begin

                    AKonum.Sol := (AKonum.Sol - SonNesneA.Sol);
                    AKonum.Ust := (AKonum.Ust - SonNesneA.Ust);
                    Exit(SonBulunanGN);
                  end;
                end else SonBulunanGN := GenelGN;
              end
              else
              begin

                if(SonBulunanGN.NesneTipi = gntPencere) then
                begin

                  SonNesneA.Sol := SonNesneA.Sol - SonBulunanGN.FKalinlik.Sol;
                  SonNesneA.Ust := SonNesneA.Ust - SonBulunanGN.FKalinlik.Ust;

                  AKonum.Sol := (AKonum.Sol - SonNesneA.Sol);
                  AKonum.Ust := (AKonum.Ust - SonNesneA.Ust);
                  Exit(SonBulunanGN);
                end
                else
                begin

                  AKonum.Sol := (AKonum.Sol - SonNesneA.Sol);
                  AKonum.Ust := (AKonum.Ust - SonNesneA.Ust);
                  Exit(SonBulunanGN);
                end;
              end;
            end;
          end;
        end;
      end;
    end;

    AKonum.Sol := AKonum.Sol - SonBulunanGN.FAtananAlan.Sol;
    AKonum.Ust := AKonum.Ust - SonBulunanGN.FAtananAlan.Ust;
    Exit(SonBulunanGN);
  end;
end;

{==============================================================================
  nesneyi ata nesnesine alt nesne olarak ekler
 ==============================================================================}
function TGorselNesneler.AtaNesneyeEkle(AGorselNesne, AAtaNesne: TGorselNesne): Boolean;
begin

  Result := False;

  // ata nesnenin alt nesneleri için bellek oluşturulmuş mu ?
  if(AAtaNesne.AltNesneBellekAdresi = nil) then
  begin

    // ata nesne için bellek oluştur
    AAtaNesne.AltNesneBellekAdresi := GetMem(4096);
  end;

  if(AAtaNesne.AltNesneBellekAdresi = nil) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'GORSELNESNE.PAS: Hata: Nesne için ata nesnede bellek alanı ayrılamıyor!', []);
    Exit;
  end;

  // alt nesne toplam nesne sayısı aşılmamışsa ...
  if(AAtaNesne.AltNesneSayisi < 1024) then
  begin

    // nesneyi üst nesneye kaydet
    PGorselNesne(AAtaNesne.AltNesneBellekAdresi)[AAtaNesne.AltNesneSayisi] := AGorselNesne;

    // üst nesnenin nesne saysını 1 artır
    AAtaNesne.FAltNesneSayisi := AAtaNesne.FAltNesneSayisi + 1;

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
function TGorselNesneler.AtaNesnedenCikar(AGorselNesne: TGorselNesne): Boolean;
var
  AGN, GN: TGorselNesne;
  GNBellekAdresi: PGorselNesne;
  i, j: TSayi4;
begin

  Result := False;

  AGN := GGNesneler.GorselNesne[AGorselNesne.AtaNesne.FSiraNo];
  if(AGN = nil) then Exit;

  GNBellekAdresi := AGN.AltNesneBellekAdresi;
  if(AGN.AltNesneSayisi = 1) then
  begin

    GN := GNBellekAdresi[0];
    if not(GN = nil) and (GN = AGorselNesne) then
    begin

      GNBellekAdresi[0] := nil;
      AGN.AltNesneSayisi := 0;

      // alt nesne bellek adresini serbest bırak
      FreeMem(AGN.AltNesneBellekAdresi, 4096);
      AGN.AltNesneBellekAdresi := nil;

      Exit(True);
    end;
  end
  else
  begin

    for i := 0 to AGN.AltNesneSayisi - 1 do
    begin

      GN := GNBellekAdresi[i];
      if not(GN = nil) and (GN = AGorselNesne) then
      begin

        // 1.1 dizinin son nesnesi çıkarılacaksa
        if((i + 1) = AGN.AltNesneSayisi) then
        begin

          GNBellekAdresi[i] := nil;
        end
        else
        // 1.2 dizinin diğer nesneleri çıkarılacaksa
        begin

          // çıkarılacak nesnenin sağındaki tüm nesneleri sola kaydır
          for j := i + 1 to AGN.AltNesneSayisi - 1 do
          begin

            GNBellekAdresi[j - 1] := GNBellekAdresi[j];
          end;

          // son nesneyi nil olarak işaretle
          GNBellekAdresi[j] := nil;
        end;

        // alt nesne sayısını bir azalt
        j := AGN.FAltNesneSayisi;
        Dec(j);
        AGN.FAltNesneSayisi := j;

        // alt nesne sayısının 0 olması durumunda bellek adresini serbest bırak
        if(AGN.AltNesneSayisi = 0) then
        begin

          FreeMem(AGN.AltNesneBellekAdresi, 4096);
          AGN.AltNesneBellekAdresi := nil;
        end;

        Exit(True);
      end;
    end;
  end;
end;

{==============================================================================
  nesne kimliğinden nesneyi alır
 ==============================================================================}
function TGorselNesneler.NesneAl(AKimlik: TKimlik): TGorselNesne;
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
function TGorselNesneler.NesneTipiniKontrolEt(AKimlik: TKimlik; AGNTip: TGNTip): TGorselNesne;
var
  GN: TGorselNesne;
  i: TKimlik;
begin

  Result := nil;

  i := AKimlik shr 10;

  // nesne istenen sayı aralığında ise
  GN := GorselNesne[i];
  if(GN = nil) then Exit;

  // nesne kimlik, tipini kontrol et
  if(GN.Kimlik = AKimlik) and (GN.NesneTipi = AGNTip) then Exit(GN);
end;

{==============================================================================
  görevin ana penceresi ve pencereye ait tüm alt nesneleri yok eder
 ==============================================================================}
procedure TGorselNesneler.PencereyiYokEt(AGorevKimlik: TKimlik);
var
  Masaustu: TMasaustu;
  Pencere,
  GN, GN2: TGorselNesne;
  i, j, k,
  ANSayisi: TSayi4;

  procedure NesneyiYokEt(ANesne: TGorselNesne);
  begin

    case ANesne.NesneTipi of
      //gntAcilirMenu     :
      gntAracCubugu     : TAracCubugu(ANesne).Destroy;
      gntBaglanti       : TBaglanti(ANesne).Destroy;
      gntDefter         : TDefter(ANesne).Destroy;
      gntDegerDugmesi   : TDegerDugmesi(ANesne).Destroy;
      gntDegerListesi   : TDegerListesi(ANesne).Destroy;
      gntDugme          : TDugme(ANesne).Destroy;
      gntDurumCubugu    : TDurumCubugu(ANesne).Destroy;
      gntEtiket         : TEtiket(ANesne).Destroy;
      gntGirisKutusu    : TGirisKutusu(ANesne).Destroy;
      gntGucDugmesi     : TGucDugmesi(ANesne).Destroy;
      gntIslemGostergesi: TIslemGostergesi(ANesne).Free;
      gntIzgara         : TIzgara(ANesne).Destroy;
      gntKarmaListe     : TKarmaListe(ANesne).Destroy;
      gntKaydirmaCubugu : TKaydirmaCubugu(ANesne).Destroy;
      gntListeGorunum   : TListeGorunum(ANesne).Destroy;
      gntListeKutusu    : TListeKutusu(ANesne).Destroy;
      //gntMasaustu;
      //gntMenu;
      gntOnayKutusu     : TOnayKutusu(ANesne).Destroy;
      gntPanel          : TPanel(ANesne).Destroy;
      gntPencere        : TPencere(ANesne).Free;
      gntRenkSecici     : TRenkSecici(ANesne).Destroy;
      gntResim          : TResim(ANesne).Destroy;
      gntResimDugmesi   : TResimDugmesi(ANesne).Destroy;
      gntSayfaKontrol   : TSayfaKontrol(ANesne).Destroy;
      gntSecimDugmesi   : TSecimDugmesi(ANesne).Destroy;
    end;
  end;
begin

  // geçerli bir masaüstü var mı ?
  Masaustu := GGNesneler.AktifMasaustu;
  if not(Masaustu = nil) then
  begin

    // masaüstü nesnesinin alt nesnesi var ise
    if(Masaustu.AltNesneSayisi > 0) then
    begin

      // masaüstü alt nesnelerini teker teker ara
      for i := 0 to Masaustu.AltNesneSayisi - 1 do
      begin

        Pencere := PGorselNesne(Masaustu.AltNesneBellekAdresi)[i];

        // aranan pencerenin sahibi olan görev ile araştırılan görev kimliği eşit mi?
        // öyle ise pencere ve alt nesnelerini yok et
        if(Pencere.GrvKimlik = AGorevKimlik) then
        begin

          // pencere nesnesinin SADECE alt nesnelerini yok et
          ANSayisi := Pencere.AltNesneSayisi;
          ANSayisi := ANSayisi - Pencere.AltBilesenSayisi;

          // pencere nesnesinin alt nesnesi var mı?
          if(ANSayisi > 0) then
          begin

            // pencere nesnesinin alt nesnelerini ata nesneden çıkar (yok et)
            for j := Pencere.AltNesneSayisi - 1 downto Pencere.AltBilesenSayisi do
            begin

              GN := PGorselNesne(Pencere.AltNesneBellekAdresi)[j];

              // nesnenin panel olması durumunda panele ait alt nesneleri yok et
              if(GN.NesneTipi = gntPanel) and (GN.AltNesneSayisi > 0) then
              begin

                for k := GN.AltNesneSayisi - 1 downto 0 do
                begin

                  GN2 := PGorselNesne(GN.AltNesneBellekAdresi)[k];
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

{==============================================================================
  tüm pencere nesnelerini yeniden çizer
  bilgi: pencere giysi (skin) işlemleri için kodlanmıştır
 ==============================================================================}
procedure TGorselNesneler.PencereleriYenidenCiz;
var
  Masaustu: TMasaustu;
  Pencere: TGorselNesne;
  GNBellekAdresi: PGorselNesne;
  i: TISayi4;
begin

  // geçerli bir masaüstü var mı ?
  Masaustu := GGNesneler.AktifMasaustu;
  if not(Masaustu = nil) then
  begin

    // masaüstü nesnesinin alt nesnesi var ise
    if(Masaustu.AltNesneSayisi > 0) then
    begin

      // masaüstünün alt nesnelerinin bellek adresini al
      GNBellekAdresi := PGorselNesne(Masaustu.AltNesneBellekAdresi);

      // masaüstü alt nesnelerini teker teker ara
      for i := 0 to Masaustu.AltNesneSayisi - 1 do
      begin

        Pencere := GNBellekAdresi[i];

        if not(Pencere = nil) and (Pencere.NesneTipi = gntPencere) then TPencere(Pencere).Ciz;
      end;
    end;
  end;
end;

{==============================================================================
  nesnenin en üst atası olan masaüstü veya pencere nesnesini alır
 ==============================================================================}
function TGorselNesneler.EnUstNesneyiAl(AGorselNesne: TGorselNesne): TGorselNesne;
begin

  // nesnenin ata nesnesi masaüstü veya pencere olana kadar ara
  while (AGorselNesne.NesneTipi <> gntMasaustu) or (AGorselNesne.NesneTipi <> gntPencere) do
  begin

    AGorselNesne := AGorselNesne.AtaNesne;
    if(AGorselNesne = nil) then Exit(nil);
  end;

  Result := AGorselNesne;
end;

{==============================================================================
  nesnenin en üst atası olan pencere nesnesini alır
 ==============================================================================}
function TGorselNesneler.EnUstPencereNesnesiniAl(AGorselNesne: TGorselNesne): TPencere;
begin

  // nesnenin ata nesnesi pencere olana kadar ara
  while (AGorselNesne.NesneTipi <> gntPencere) do
  begin

    AGorselNesne := AGorselNesne.AtaNesne;
    if(AGorselNesne = nil) then Exit(nil);
  end;

  Result := TPencere(AGorselNesne);
end;

{==============================================================================
  nesnenin fare olaylarını yakalamasını sağlar
 ==============================================================================}
procedure TGorselNesneler.OlayYakalamayaBasla(AGorselNesne: TGorselNesne);
begin

  // olaylar başka nesne tarafından yakalanmıyorsa, olay nesnesini
  // yakalanan nesne olarak ata
  if(YakalananGorselNesne = nil) then FYakalananGorselNesne := AGorselNesne;
end;

{==============================================================================
  fare olayları yakalama işlevi nesne tarafından serbest bırakılır
 ==============================================================================}
procedure TGorselNesneler.OlayYakalamayiBirak(AGorselNesne: TGorselNesne);
begin

  // olay daha önce nesne tarafından yakalanmışsa, nesneyi yakalanan nesne
  // olmaktan çıkar
  if(YakalananGorselNesne = AGorselNesne) then FYakalananGorselNesne := nil;
end;

end.
