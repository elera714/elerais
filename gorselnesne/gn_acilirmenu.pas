{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: gn_acilirmenu.pas
  Dosya ��levi: a��l�r men� (TPopupMenu) y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 26/02/2025

 ==============================================================================}
{$mode objfpc}
unit gn_acilirmenu;

interface

uses gorselnesne, paylasim, n_yazilistesi, n_sayilistesi, gn_menu;

type
  PAcilirMenu = ^TAcilirMenu;
  TAcilirMenu = object(TMenu)
  public
    // nesne, karma liste gibi bir nesnenin yard�mc� nesnesi mi?
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
  a��l�r men� kesme �a�r�lar�n� y�netir
 ==============================================================================}
function AcilirMenuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  AcilirMenu: PAcilirMenu = nil;
  AElemanAdi: string;
  AResimSiraNo: TISayi4;
begin

  case AIslevNo of

    // nesne olu�tur
    ISLEV_OLUSTUR:

      Result := NesneOlustur(PISayi4(ADegiskenler + 00)^, PISayi4(ADegiskenler + 04)^,
        PISayi4(ADegiskenler + 08)^, PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^);

    // a��l�r men�y� g�r�nt�le
    ISLEV_GOSTER:
    begin

      AcilirMenu := PAcilirMenu(GorselNesneler0.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^,
        gntAcilirMenu));
      if(AcilirMenu <> nil) then AcilirMenu^.Goster;
    end;

    // a��l�r men�y� gizle
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

    // se�ilen eleman�n s�ra de�erini al
    $020E:
    begin

      AcilirMenu := PAcilirMenu(GorselNesneler0.NesneTipiniKontrolEt(PKimlik(ADegiskenler + 00)^,
        gntAcilirMenu));
      if(AcilirMenu <> nil) then Result := AcilirMenu^.FSeciliSiraNo
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  a��l�r men� nesnesini olu�turur
 ==============================================================================}
function NesneOlustur(AKenarlikRengi, AGovdeRengi, ASecimRengi, ANormalYaziRengi,
  ASeciliYaziRengi: TRenk): TKimlik;
var
  AcilirMenu: PAcilirMenu = nil;
begin

  { TODO : GAktifMasaustu de�eri API i�levlerinde de�i�tirilerek nesnenin sahibi olan nesne atanacak }
  AcilirMenu := AcilirMenu^.Olustur(GAktifMasaustu, 0, 0, 300, (24 * 5) + 6, 24,
    AKenarlikRengi, AGovdeRengi, ASecimRengi, ANormalYaziRengi, ASeciliYaziRengi);

  if(AcilirMenu = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := AcilirMenu^.Kimlik;
end;

{==============================================================================
  a��l�r men� nesnesini olu�turur
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

  AcilirMenu^.FSecimRenk := ASecimRengi;
  AcilirMenu^.FNormalYaziRenk := ANormalYaziRengi;
  AcilirMenu^.FSeciliYaziRenk := ASeciliYaziRengi;

  // nesne adresini geri d�nd�r
  Result := AcilirMenu;
end;

{==============================================================================
  a��l�r men� nesnesini yok eder
 ==============================================================================}
procedure TAcilirMenu.YokEt(AKimlik: TKimlik);
begin

  GorselNesneler0.YokEt(AKimlik);
end;

{==============================================================================
  a��l�r men� nesnesini g�r�nt�ler
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

    // men�y� farenin bulundu�u konumda g�r�nt�le
    AcilirMenu^.FKonum.Sol := GFareSurucusu.YatayKonum;
    AcilirMenu^.FKonum.Ust := GFareSurucusu.DikeyKonum;
  end;

  // men�n�n a��ld���na dair nesne sahibine mesaj g�nder
  Olay.Kimlik := AcilirMenu^.Kimlik;
  Olay.Olay := CO_MENUACILDI;
  Olay.Deger1 := 0;
  Olay.Deger2 := 0;
  if not(AcilirMenu^.FMenuOlayGeriDonusAdresi = nil) then
    AcilirMenu^.FMenuOlayGeriDonusAdresi(AcilirMenu, Olay)
  else Gorevler0.OlayEkle(AcilirMenu^.GorevKimlik, Olay);
end;

{==============================================================================
  a��l�r men� nesnesini gizler
 ==============================================================================}
procedure TAcilirMenu.Gizle;
var
  AcilirMenu: PAcilirMenu = nil;
  Olay: TOlay;
begin

  inherited Gizle;

  AcilirMenu := PAcilirMenu(GorselNesneler0.NesneAl(Kimlik));
  if(AcilirMenu = nil) then Exit;

  // men�n�n a��ld���na dair nesne sahibine mesaj g�nder
  Olay.Kimlik := AcilirMenu^.Kimlik;
  Olay.Olay := CO_MENUKAPATILDI;
  Olay.Deger1 := 0;
  Olay.Deger2 := 0;
  if not(AcilirMenu^.FMenuOlayGeriDonusAdresi = nil) then
    AcilirMenu^.FMenuOlayGeriDonusAdresi(AcilirMenu, Olay)
  else Gorevler0.OlayEkle(AcilirMenu^.GorevKimlik, Olay);
end;

{==============================================================================
  a��l�r men� nesnesini hizaland�r�r
 ==============================================================================}
procedure TAcilirMenu.Hizala;
begin

  //inherited Hizala;
end;

{==============================================================================
  a��l�r men� nesnesini boyutland�r�r
 ==============================================================================}
procedure TAcilirMenu.Boyutlandir;
begin

  inherited Boyutlandir;
end;

{==============================================================================
  a��l�r men� nesnesini �izer
 ==============================================================================}
procedure TAcilirMenu.Ciz;
begin

  inherited Ciz;
end;

{==============================================================================
  a��l�r men� nesne olaylar�n� i�ler
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
  men� nesnesine men� eleman� ekler
 ==============================================================================}
function TAcilirMenu.MenuEkle(ADeger: string; AResimSiraNo: TISayi4 = -1;
  AMenuBoyutDegistir: Boolean = False): Boolean;
var
  AcilirMenu: PAcilirMenu = nil;
  i: TISayi4;
begin

  AcilirMenu := PAcilirMenu(GorselNesneler0.NesneAl(Kimlik));
  if(AcilirMenu = nil) then Exit;

  AcilirMenu^.FMenuBaslikListesi^.Ekle(ADeger);

  // AResimSiraNo = -1 = men�n�n resmi yok
  if(AResimSiraNo > -1) then AcilirMenu^.FMenuResimListesi^.Ekle(AResimSiraNo);

  // men� geni�li�ini ve y�ksekli�ini de�i�tir
  if(AMenuBoyutDegistir) then
  begin

    // geni�li�in yeniden belirlenmesi
    i := Length(ADeger) * 8;
    if(i > 100) then i := 100;
    if(i > AcilirMenu^.FBoyut.Genislik) then AcilirMenu^.FBoyut.Genislik := i;

    // y�ksekli�in yeniden belirlenmesi. en fazla 5 eleman g�r�nt�lenebilir
    i := AcilirMenu^.FMenuBaslikListesi^.ElemanSayisi;
    if(i > 5) then i := 5;
    i := i * 24;
    if(i > AcilirMenu^.FBoyut.Yukseklik) then AcilirMenu^.FBoyut.Yukseklik := i;
  end;

  AcilirMenu^.Boyutlandir;

  Result := Boolean(TISayi4(True));
end;

{==============================================================================
  men� nesnesinin elemanlar�n� temizler
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
