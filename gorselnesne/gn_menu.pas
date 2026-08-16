{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_menu.pas
  Dosya İşlevi: menü yönetim işlevlerini içerir

  Güncelleme Tarihi: 16/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_menu;

interface

uses gorselnesne, paylasim, gn_panel, n_yazilistesi, n_sayilistesi;

type
  PMenu = ^TMenu;
  TMenu = class(TPanel)
  public
    // menünün olay işlemesinden sonra olay değerlerini almak isteyen
    // nesne varsa bu değişkene atamasını gerçekleştirmesi gerekmeketdir.
    FMenuOlayGeriDonusAdresi: TOlaylariIsle;
    FMenuBaslikListesi: TYaziListesi;
    FMenuResimListesi: TSayiListesi;
    constructor Create; override;
    destructor Destroy; override;
    function Ozellestir(AAtaNesne: TGorselNesne; AGNTip: TGNTip; ASol, AUst,
      AGenislik, AYukseklik, AElemanYukseklik: TISayi4; AKenarlikRengi, AGovdeRengi: TRenk): TISayi4;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Boyutlandir;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
    // her bir elemanın yüksekliği
    property ElemanYukseklik: TISayi4 read FIDeger1 write FIDeger1;
    // seçili sıra no
    property SeciliSiraNo: TISayi4 read FIDeger2 write FIDeger2;
    // ilk görünen elemanın sıra numarası
    property IlkSiraNo: TISayi4 read FIDeger3 write FIDeger3;

    property SecimRenk: TRenk read FDeger1 write FDeger1;
    property NormalYaziRenk: TRenk read FDeger2 write FDeger2;
    property SeciliYaziRenk: TRenk read FDeger3 write FDeger3;
  end;

function MenuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function MenuGNOlustur(ASol, AUst, AGenislik, AYukseklik, AElemanYukseklik: TISayi4): TKimlik;

implementation

uses temelgorselnesne, gn_islevler, gorev, gn_masaustu, src_ps2;

{==============================================================================
  menü kesme çağrılarını yönetir
 ==============================================================================}
function MenuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  Menu: TMenu;
  AElemanAdi: string;
  AResimSiraNo: TISayi4;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    // nesne oluştur
    ISLEV_OLUSTUR:

      Result := MenuGNOlustur(PISayi4(ADegiskenler + 00)^, PISayi4(ADegiskenler + 04)^,
        PISayi4(ADegiskenler + 08)^, PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^);

    // menüyü görüntüle
    ISLEV_GOSTER:
    begin

      Menu := TMenu(GGNesneler.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntMenu));
      if(Menu <> nil) then Menu.Goster;
    end;

    // menüyü gizle
    ISLEV_GIZLE:
    begin

      Menu := TMenu(GGNesneler.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntMenu));
      if(Menu <> nil) then Menu.Gizle;
    end;

    // eleman ekle
    $010F:
    begin

      Menu := TMenu(GGNesneler.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntMenu));

      AElemanAdi := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr)^;
      AResimSiraNo := PISayi4(ADegiskenler + 08)^;

      if(Menu <> nil) then
      begin

        Menu.FMenuBaslikListesi.Ekle(AElemanAdi);
        Menu.FMenuResimListesi.Ekle(AResimSiraNo);
        Result := 1;
      end else Result := 0;
    end;

    // seçilen elemanın sıra değerini al
    $020E:
    begin

      Menu := TMenu(GGNesneler.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^, gntMenu));
      if(Menu <> nil) then Result := Menu.SeciliSiraNo
    end;
  end;
end;

{==============================================================================
  uygulama için menü nesnesi oluşturur - api
 ==============================================================================}
function MenuGNOlustur(ASol, AUst, AGenislik, AYukseklik, AElemanYukseklik: TISayi4): TKimlik;
var
  Masaustu: TMasaustu;
  Menu: TMenu;
begin

  Menu := TMenu.Create;

  if(Menu = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    { TODO : GAktifMasaustu nesnesi ileride değiştirilerek nesnenin sahibi ata nesne olarak atanabilir }
    Masaustu := GGNesneler.AktifMasaustu;

    Menu.Ozellestir(Masaustu, gntMenu, ASol, AUst, AGenislik, AYukseklik,
      AElemanYukseklik, RENK_GRI, RENK_BEYAZ);

    Result := Menu.Kimlik;
  end;
end;

{==============================================================================
  menü nesnesi oluşturur
 ==============================================================================}
constructor TMenu.Create;
begin

  inherited Create;

  { bilgi: nesne tipi Ozellestir ileviyle gerçekleşmekte }
  //NesneTipi := gntMenu;

  GGNesneler.GorselNesne[FSiraNo] := Self;

  FMenuBaslikListesi := TYaziListesi.Create;
  FMenuResimListesi := TSayiListesi.Create;
end;

{==============================================================================
  menü nesnesini yok eder
 ==============================================================================}
destructor TMenu.Destroy;
begin

  if(FMenuResimListesi <> nil) then FMenuResimListesi.Destroy;
  if(FMenuBaslikListesi <> nil) then FMenuBaslikListesi.Destroy;

  if(FCizimBellekAdresi <> nil) then FreeMem(FCizimBellekAdresi, FCizimBellekUzunlugu);

  GGNesneler.YokEt(Self, False);

  inherited Destroy;
end;

{==============================================================================
  menü nesnesini özelleştirir
 ==============================================================================}
function TMenu.Ozellestir(AAtaNesne: TGorselNesne; AGNTip: TGNTip; ASol, AUst,
  AGenislik, AYukseklik, AElemanYukseklik: TISayi4; AKenarlikRengi, AGovdeRengi: TRenk): TISayi4;
begin

  Yapilandir2(ktTuvalNesne, Self, AAtaNesne, ASol, AUst, AGenislik, AYukseklik,
    2, AKenarlikRengi, AGovdeRengi, 0, '');

  NesneTipi := AGNTip;

  OlayCagriAdr := @OlaylariIsle;

  FMenuOlayGeriDonusAdresi := nil;

  SecimRenk := $7FB3D5;
  NormalYaziRenk := RENK_SIYAH;
  SeciliYaziRenk := RENK_BEYAZ;

  ElemanYukseklik := AElemanYukseklik;

  FCizimBaslangic.Sol := 0;
  FCizimBaslangic.Ust := 0;

  // menü çizimi için bellekte yer ayır
  FCizimBellekAdresi := nil;

  FCizimBellekUzunlugu := (FAtananAlan.Genislik * FAtananAlan.Yukseklik) * 4;
  FCizimBellekAdresi := GetMem(FCizimBellekUzunlugu);

  // nesnenin kullanacağı diğer değerler
  IlkSiraNo := 0;
  SeciliSiraNo := -1;     // seçili sıra yok

  // geri dönüş değeri
  Result := HATA_YOK;
end;

{==============================================================================
  menü nesnesini görüntüler
 ==============================================================================}
procedure TMenu.Goster;
var
  Olay: TOlay;
begin

  inherited Goster;

  GGNesneler.AktifMenu := Self;

  // daha önceden seçilmiş index değerini kaldır
  SeciliSiraNo := -1;

  // menünün açıldığına dair nesne sahibine mesaj gönder
  Olay.Kimlik := Kimlik;
  Olay.Olay := CO_MENUACILDI;
  Olay.Deger1 := 0;
  Olay.Deger2 := 0;
  if not(FMenuOlayGeriDonusAdresi = nil) then
    FMenuOlayGeriDonusAdresi(Self, Olay)
  else GGorevler.OlayEkle(GrvKimlik, Olay);
end;

{==============================================================================
  menü nesnesini gizler
 ==============================================================================}
procedure TMenu.Gizle;
var
  Olay: TOlay;
begin

  inherited Gizle;

  GGNesneler.AktifMenu := nil;

  // menünün açıldığına dair nesne sahibine mesaj gönder
  Olay.Kimlik := Kimlik;
  Olay.Olay := CO_MENUKAPATILDI;
  Olay.Deger1 := 0;
  Olay.Deger2 := 0;
  if not(FMenuOlayGeriDonusAdresi = nil) then
    FMenuOlayGeriDonusAdresi(Self, Olay)
  else GGorevler.OlayEkle(GrvKimlik, Olay);
end;

{==============================================================================
  menü nesnesini hizalandırır
 ==============================================================================}
procedure TMenu.Hizala;
begin

  //inherited Hizala;
end;

{==============================================================================
  menü nesnesini boyutlandırır
 ==============================================================================}
procedure TMenu.Boyutlandir;
begin

  FCizimAlani.Sol := 0;
  FCizimAlani.Ust := 0;
  FCizimAlani.Sag := FAtananAlan.Genislik - 1;
  FCizimAlani.Alt := FAtananAlan.Yukseklik - 1;

  // önceki ayrılan bellek bölgesini serbest bırak
  if(FCizimBellekAdresi <> nil) then
  begin

    FreeMem(FCizimBellekAdresi, FCizimBellekUzunlugu);
    FCizimBellekAdresi := nil;
  end;

  // menü çizimi için bellekte yer ayır
  FCizimBellekUzunlugu := (FAtananAlan.Genislik * FAtananAlan.Yukseklik) * 4;
  FCizimBellekAdresi := GetMem(FCizimBellekUzunlugu);
  if(FCizimBellekAdresi = nil) then
  begin

    // hata olması durumunda nesneyi yok et ve işlevden çık
    Destroy;
    Exit;
  end;
end;

{==============================================================================
  menü nesnesini çizer
 ==============================================================================}
procedure TMenu.Ciz;
var
  CizimAlani: TAlan;
  SiraNo, Sol, Ust, Genislik,
  MenudekiElemanSayisi: TISayi4;
  ResimCiz: Boolean;
  s: string;
begin

  inherited Ciz;

  // menü nesnesinin çizim alan koordinatlarını al
  CizimAlani := FCizimAlani;

  // nesnenin elemanı var mı ?
  if(FMenuBaslikListesi.ElemanSayisi > 0) then
  begin

    // ElemanSayisi değerinin 0 olması resim kullanılmayacağını belirtir
    if(FMenuResimListesi.ElemanSayisi = 0) then
      ResimCiz := False
    else ResimCiz := True;

    // çizim / yazım için kullanılacak Sol & Ust koordinatları
    if(ResimCiz) then
    begin

      Sol := CizimAlani.Sol + 30;         // 30 pixel soldan sağa doğru. menü resimleri için
      Genislik := CizimAlani.Sag - 3;
    end
    else
    begin

      Sol := 3;
      Genislik := CizimAlani.Sag - 3;
    end;

    Ust := CizimAlani.Ust + 08;           // 08 = dikey ortalama için

    // menü kutusunda görüntülenecek eleman sayısı
    if(FMenuBaslikListesi.ElemanSayisi > FMenuBaslikListesi.ElemanSayisi) then
      MenudekiElemanSayisi := FMenuBaslikListesi.ElemanSayisi + IlkSiraNo
    else MenudekiElemanSayisi := FMenuBaslikListesi.ElemanSayisi + IlkSiraNo;

    // menü içerisini elemanlarla doldurma işlemi
    for SiraNo := IlkSiraNo to MenudekiElemanSayisi - 1 do
    begin

      // belirtilen elemanın karakter katar değerini al
      s := FMenuBaslikListesi.Yazi[SiraNo];

      // elemanın seçili olması durumunda seçili olduğunu belirt
      // belirtilen sıra seçili değilse sadece eleman değerini yaz
      if(SiraNo = SeciliSiraNo) then
      begin

        DikdortgenDoldur(Self, Sol, Ust - 4, Genislik, Ust + 20, $60A3AE, $60A3AE);

        YaziYaz(Self, Sol + 5, Ust, s, RENK_BEYAZ);
      end else YaziYaz(Self, Sol + 5, Ust, s, RENK_SIYAH);

      if(ResimCiz) then
      begin

        // menü resmini çiz
        if(SiraNo >= 0) and (SiraNo <= 15) then KaynaktanResimCiz2(Self, 4, Ust - 4,
          FMenuResimListesi.Sayi[SiraNo]);
      end;

      // bir sonraki eleman...
      Ust := Ust + ElemanYukseklik;
    end;
  end;
end;

{==============================================================================
  menü nesne olaylarını işler
 ==============================================================================}
procedure TMenu.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Menu: TMenu;
begin

  Menu := TMenu(AGonderici);
  if(Menu = nil) then Exit;

  // sol fare tuş basımı
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // sol tuşa basım işlemi nesnenin olay alanında mı gerçekleşti ?
    if(Menu.FareNesneOlayAlanindaMi(Menu)) then
    begin

      // fare olaylarını yakala
      GGNesneler.OlayYakalamayaBasla(Menu);

      // fare basım işleminin gerçekleştiği menü sıra numarası
      if(Menu.FMenuBaslikListesi.ElemanSayisi > 0) then
        Menu.SeciliSiraNo := (AOlay.Deger2 - 4) div Menu.ElemanYukseklik
      else Menu.SeciliSiraNo := -1;

      // menüyü gizle
      Menu.Gorunum := False;

      // uygulamaya veya efendi nesneye mesaj gönder
      AOlay.Olay := FO_TIKLAMA;
      if not(Menu.FMenuOlayGeriDonusAdresi = nil) then
        Menu.FMenuOlayGeriDonusAdresi(Menu, AOlay)
      else GGorevler.OlayEkle(Menu.GrvKimlik, AOlay);
    end;
  end
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    GGNesneler.OlayYakalamayiBirak(Menu);
  end
  else if(AOlay.Olay = FO_HAREKET) then
  begin

    // seçilen elemanın index numarasını belirle
    if(Menu.FMenuBaslikListesi.ElemanSayisi > 0) then
      Menu.SeciliSiraNo := (AOlay.Deger2 - 4) div Menu.ElemanYukseklik
    else Menu.SeciliSiraNo := -1;
  end;

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := Menu.FareImlec;
end;

end.
