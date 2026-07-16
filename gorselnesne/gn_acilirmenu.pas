{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_acilirmenu.pas
  Dosya İşlevi: açılır menü (TPopupMenu) yönetim işlevlerini içerir

  Güncelleme Tarihi: 16/07/2026

 ==============================================================================}
{$mode objfpc}
unit gn_acilirmenu;

interface

uses gorselnesne, paylasim, n_yazilistesi, n_sayilistesi, gn_menu;

type
  PAcilirMenu = ^TAcilirMenu;
  TAcilirMenu = object(TMenu)
  public
    // nesne, karma liste gibi bir nesnenin yardımcı nesnesi mi?
    FYardimciNesne: Boolean;
    FAcilirMenuOlayGeriDonusAdresi: TOlaylariIsle;
    function Olustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik,
      AElemanYukseklik: TISayi4; AKenarlikRengi, AGovdeRengi, ASecimRengi, ANormalYaziRengi,
      ASeciliYaziRengi: TRenk): PAcilirMenu;
    procedure YokEt(AKimlik: TKimlik);
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Boyutlandir;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    function MenuEkle(ADeger: string; AResimSiraNo: TISayi4 = -1;
      AMenuBoyutDegistir: Boolean = False): Boolean;
    procedure Temizle;
  end;

function AcilirMenuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AKenarlikRengi, AGovdeRengi, ASecimRengi, ANormalYaziRengi,
  ASeciliYaziRengi: TRenk): TKimlik;

implementation

uses genel, temelgorselnesne, gorev, sistemmesaj;

{==============================================================================
  açılır menü kesme çağrılarını yönetir
 ==============================================================================}
function AcilirMenuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  AcilirMenu: PAcilirMenu = nil;
  AElemanAdi: string;
  AResimSiraNo: TISayi4;
begin

  case AIslevNo of

    // nesne oluştur
    ISLEV_OLUSTUR:

      Result := NesneOlustur(PISayi4(ADegiskenler + 00)^, PISayi4(ADegiskenler + 04)^,
        PISayi4(ADegiskenler + 08)^, PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^);

    // açılır menüyü görüntüle
    ISLEV_GOSTER:
    begin

      AcilirMenu := PAcilirMenu(GorselNesneler0.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^,
        gntAcilirMenu));
      if(AcilirMenu <> nil) then AcilirMenu^.Goster;
    end;

    // açılır menüyü gizle
    ISLEV_GIZLE:
    begin

      AcilirMenu := PAcilirMenu(GorselNesneler0.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^,
        gntAcilirMenu));
      if(AcilirMenu <> nil) then AcilirMenu^.Gizle;
    end;

    // eleman ekle
    $010F:
    begin

      AcilirMenu := PAcilirMenu(GorselNesneler0.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^,
        gntAcilirMenu));

      AElemanAdi := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi)^;
      AResimSiraNo := PISayi4(ADegiskenler + 08)^;

      if(AcilirMenu <> nil) then
        Result := TISayi4(AcilirMenu^.MenuEkle(AElemanAdi, AResimSiraNo))
      else Result := 0;
    end;

    // seçilen elemanın sıra değerini al
    $020E:
    begin

      AcilirMenu := PAcilirMenu(GorselNesneler0.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^,
        gntAcilirMenu));
      if(AcilirMenu <> nil) then Result := AcilirMenu^.SeciliSiraNo
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  açılır menü nesnesini oluşturur
 ==============================================================================}
function NesneOlustur(AKenarlikRengi, AGovdeRengi, ASecimRengi, ANormalYaziRengi,
  ASeciliYaziRengi: TRenk): TKimlik;
var
  AcilirMenu: PAcilirMenu = nil;
begin

  { TODO : GAktifMasaustu değeri API işlevlerinde değiştirilerek nesnenin sahibi olan nesne atanacak }
  AcilirMenu := AcilirMenu^.Olustur(GAktifMasaustu, 0, 0, 300, (24 * 5) + 6, 24,
    AKenarlikRengi, AGovdeRengi, ASecimRengi, ANormalYaziRengi, ASeciliYaziRengi);

  if(AcilirMenu = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := AcilirMenu^.Kimlik;
end;

{==============================================================================
  açılır menü nesnesini oluşturur
 ==============================================================================}
function TAcilirMenu.Olustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik,
  AElemanYukseklik: TISayi4; AKenarlikRengi, AGovdeRengi, ASecimRengi, ANormalYaziRengi,
  ASeciliYaziRengi: TRenk): PAcilirMenu;
var
  AcilirMenu: PAcilirMenu = nil;
begin

  AcilirMenu := PAcilirMenu(inherited Olustur(AAtaNesne, gntAcilirMenu, ASol, AUst,
    AGenislik, AYukseklik, AElemanYukseklik, AKenarlikRengi, AGovdeRengi));

  AcilirMenu^.FMenuOlayGeriDonusAdresi := @OlaylariIsle;
  AcilirMenu^.FAcilirMenuOlayGeriDonusAdresi := nil;

  AcilirMenu^.FYardimciNesne := False;

  AcilirMenu^.SecimRenk := ASecimRengi;
  AcilirMenu^.NormalYaziRenk := ANormalYaziRengi;
  AcilirMenu^.SeciliYaziRenk := ASeciliYaziRengi;

  // nesne adresini geri döndür
  Result := AcilirMenu;
end;

{==============================================================================
  açılır menü nesnesini yok eder
 ==============================================================================}
procedure TAcilirMenu.YokEt(AKimlik: TKimlik);
begin

  inherited YokEt(AKimlik);
end;

{==============================================================================
  açılır menü nesnesini görüntüler
 ==============================================================================}
procedure TAcilirMenu.Goster;
var
  AcilirMenu: PAcilirMenu = nil;
  Olay: TOlay;
begin

  inherited Goster;

  AcilirMenu := PAcilirMenu(GorselNesneler0.NesneAl(Kimlik));
  if(AcilirMenu = nil) then Exit;

  if(AcilirMenu^.FYardimciNesne) then
  begin

  end
  else
  begin

    // menüyü farenin bulunduğu konumda görüntüle
    AcilirMenu^.FAtananAlan.Sol := GFareSurucusu.YatayKonum;
    AcilirMenu^.FAtananAlan.Ust := GFareSurucusu.DikeyKonum;
  end;

  // menünün açıldığına dair nesne sahibine mesaj gönder
  Olay.Kimlik := AcilirMenu^.Kimlik;
  Olay.Olay := CO_MENUACILDI;
  Olay.Deger1 := 0;
  Olay.Deger2 := 0;
  if not(AcilirMenu^.FMenuOlayGeriDonusAdresi = nil) then
    AcilirMenu^.FMenuOlayGeriDonusAdresi(AcilirMenu, Olay)
  else Gorevler0.OlayEkle(AcilirMenu^.GorevKimlik, Olay);
end;

{==============================================================================
  açılır menü nesnesini gizler
 ==============================================================================}
procedure TAcilirMenu.Gizle;
var
  AcilirMenu: PAcilirMenu = nil;
  Olay: TOlay;
begin

  inherited Gizle;

  AcilirMenu := PAcilirMenu(GorselNesneler0.NesneAl(Kimlik));
  if(AcilirMenu = nil) then Exit;

  // menünün açıldığına dair nesne sahibine mesaj gönder
  Olay.Kimlik := AcilirMenu^.Kimlik;
  Olay.Olay := CO_MENUKAPATILDI;
  Olay.Deger1 := 0;
  Olay.Deger2 := 0;
  if not(AcilirMenu^.FMenuOlayGeriDonusAdresi = nil) then
    AcilirMenu^.FMenuOlayGeriDonusAdresi(AcilirMenu, Olay)
  else Gorevler0.OlayEkle(AcilirMenu^.GorevKimlik, Olay);
end;

{==============================================================================
  açılır menü nesnesini hizalandırır
 ==============================================================================}
procedure TAcilirMenu.Hizala;
begin

  //inherited Hizala;
end;

{==============================================================================
  açılır menü nesnesini boyutlandırır
 ==============================================================================}
procedure TAcilirMenu.Boyutlandir;
begin

  inherited Boyutlandir;
end;

{==============================================================================
  açılır menü nesnesini çizer
 ==============================================================================}
procedure TAcilirMenu.Ciz;
begin

  inherited Ciz;
end;

{==============================================================================
  açılır menü nesne olaylarını işler
 ==============================================================================}
procedure TAcilirMenu.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  AcilirMenu: PAcilirMenu = nil;
begin

  AcilirMenu := PAcilirMenu(AGonderici);
  if(AcilirMenu = nil) then Exit;

  if not(AcilirMenu^.FAcilirMenuOlayGeriDonusAdresi = nil) then
    AcilirMenu^.FAcilirMenuOlayGeriDonusAdresi(AcilirMenu, AOlay)
  else Gorevler0.OlayEkle(AcilirMenu^.GorevKimlik, AOlay);
end;

{==============================================================================
  menü nesnesine menü elemanı ekler
 ==============================================================================}
function TAcilirMenu.MenuEkle(ADeger: string; AResimSiraNo: TISayi4 = -1;
  AMenuBoyutDegistir: Boolean = False): Boolean;
var
  AcilirMenu: PAcilirMenu = nil;
  i: TISayi4;
begin

  AcilirMenu := PAcilirMenu(GorselNesneler0.NesneAl(Kimlik));
  if(AcilirMenu = nil) then Exit(False);

  AcilirMenu^.FMenuBaslikListesi^.Ekle(ADeger);

  // AResimSiraNo = -1 = menünün resmi yok
  if(AResimSiraNo > -1) then AcilirMenu^.FMenuResimListesi^.Ekle(AResimSiraNo);

  // menü genişliğini ve yüksekliğini değiştir
  if(AMenuBoyutDegistir) then
  begin

    // genişliğin yeniden belirlenmesi
    i := Length(ADeger) * 8;
    if(i > 100) then i := 100;
    if(i > AcilirMenu^.FAtananAlan.Genislik) then AcilirMenu^.FAtananAlan.Genislik := i;

    // yüksekliğin yeniden belirlenmesi. en fazla 5 eleman görüntülenebilir
    i := AcilirMenu^.FMenuBaslikListesi^.ElemanSayisi;
    if(i > 5) then i := 5;
    i := i * 24;
    if(i > AcilirMenu^.FAtananAlan.Yukseklik) then AcilirMenu^.FAtananAlan.Yukseklik := i;
  end;

  AcilirMenu^.Boyutlandir;

  Result := Boolean(TISayi4(True));
end;

{==============================================================================
  menü nesnesinin elemanlarını temizler
 ==============================================================================}
procedure TAcilirMenu.Temizle;
var
  AcilirMenu: PAcilirMenu = nil;
begin

  AcilirMenu := PAcilirMenu(GorselNesneler0.NesneAl(Kimlik));
  if(AcilirMenu = nil) then Exit;

  AcilirMenu^.FMenuBaslikListesi^.Temizle;
  AcilirMenu^.FMenuResimListesi^.Temizle;
end;

end.
