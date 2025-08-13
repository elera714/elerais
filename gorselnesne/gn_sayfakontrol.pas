{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: gn_sayfakontrol.pas
  Dosya ��levi: sayfa kontrol (TPageControl) nesne y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 26/02/2025

 ==============================================================================}
{$mode objfpc}
unit gn_sayfakontrol;

interface

uses gorselnesne, paylasim, gn_panel, gn_dugme, gn_etiket;

const
  AZAMI_SEKMESAYISI = 4;

type
  PSayfaKontrol = ^TSayfaKontrol;
  TSayfaKontrol = object(TPanel)
  private
    FSayfaSayisi, FAktifSayfa: TISayi4;
    FPaneller: array[0..AZAMI_SEKMESAYISI - 1] of PPanel;   // nesnedeki paneller
    FDugmeler: array[0..AZAMI_SEKMESAYISI - 1] of PDugme;   // nesnedeki her bir paneli temsil eden d��meler
    FBaslikG: array[0..AZAMI_SEKMESAYISI - 1] of TSayi4;    // her bir d��menin ba�l�k geni�li�i
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4): PSayfaKontrol;
    procedure YokEt(AKimlik: TKimlik);
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    procedure SekmeOlaylariniIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    function SayfaEkle(ABaslik: string): TKimlik;
    procedure EtiketEkle(ASayfaNo, ASol, AUst: TISayi4; ABaslik: string);
  end;

function SayfaKontrolCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;

implementation

uses temelgorselnesne, gorev;

{==============================================================================
  sayfa kontrol nesne kesme �a�r�lar�n� y�netir
 ==============================================================================}
function SayfaKontrolCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne = nil;
  SayfaKontrol: PSayfaKontrol = nil;
  p: PKarakterKatari;
begin

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^);
    end;

    ISLEV_GOSTER:
    begin

      SayfaKontrol := PSayfaKontrol(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      SayfaKontrol^.Goster;
    end;

    ISLEV_GIZLE:
    begin

      SayfaKontrol := PSayfaKontrol(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      SayfaKontrol^.Gizle;
    end;

    // sayfa kontrol nesnesine yeni sayfa ekle
    $010F:
    begin

      SayfaKontrol := PSayfaKontrol(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      p := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
      SayfaKontrol^.SayfaEkle(p^);
    end;

    // panel sekme i�eri�ine etiket ekle
    $020F:
    begin

      SayfaKontrol := PSayfaKontrol(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      p := PKarakterKatari(PSayi4(ADegiskenler + 16)^ + FAktifGorevBellekAdresi);
      SayfaKontrol^.EtiketEkle(PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, p^);
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  sayfa kontrol nesnesini olu�turur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
var
  SayfaKontrol: PSayfaKontrol = nil;
begin

  SayfaKontrol := SayfaKontrol^.Olustur(ktNesne, AAtaNesne, ASol, AUst,
    AGenislik, AYukseklik);

  if(SayfaKontrol = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := SayfaKontrol^.Kimlik;
end;

{==============================================================================
  sayfa kontrol nesnesini olu�turur
 ==============================================================================}
function TSayfaKontrol.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4): PSayfaKontrol;
var
  SayfaKontrol: PSayfaKontrol = nil;
begin

  SayfaKontrol := PSayfaKontrol(inherited Olustur(AKullanimTipi, AAtaNesne,
    ASol, AUst, AGenislik, AYukseklik, 2, RENK_BEYAZ, RENK_BEYAZ, 0, ''));

  // nesnenin ad de�eri
  SayfaKontrol^.NesneTipi := gntSayfaKontrol;

  SayfaKontrol^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  SayfaKontrol^.OlayCagriAdresi := @OlaylariIsle;

  SayfaKontrol^.FSayfaSayisi := 0;
  SayfaKontrol^.FAktifSayfa := -1;

  // nesne adresini geri d�nd�r
  Result := SayfaKontrol;
end;

{==============================================================================
  sayfa kontrol nesnesini yok eder
 ==============================================================================}
procedure TSayfaKontrol.YokEt(AKimlik: TKimlik);
begin

  GorselNesneler0.YokEt(AKimlik);
end;

{==============================================================================
  sayfa kontrol nesnesini g�r�nt�ler
 ==============================================================================}
procedure TSayfaKontrol.Goster;
var
  SayfaKontrol: PSayfaKontrol = nil;
begin

  // nesnenin kimlik, tip de�erlerini denetle.
  SayfaKontrol := PSayfaKontrol(GorselNesneler0.NesneAl(Kimlik));
  if(SayfaKontrol = nil) then Exit;

  if(SayfaKontrol^.FAktifSayfa = 0) then
  begin

    SayfaKontrol^.FPaneller[0]^.Goster;
    SayfaKontrol^.FPaneller[1]^.Gizle;
    SayfaKontrol^.FPaneller[2]^.Gizle;
    SayfaKontrol^.FPaneller[3]^.Gizle;
  end
  else if(SayfaKontrol^.FAktifSayfa = 1) then
  begin

    SayfaKontrol^.FPaneller[0]^.Gizle;
    SayfaKontrol^.FPaneller[1]^.Goster;
    SayfaKontrol^.FPaneller[2]^.Gizle;
    SayfaKontrol^.FPaneller[3]^.Gizle;
  end
  else if(SayfaKontrol^.FAktifSayfa = 2) then
  begin

    SayfaKontrol^.FPaneller[0]^.Gizle;
    SayfaKontrol^.FPaneller[1]^.Gizle;
    SayfaKontrol^.FPaneller[2]^.Goster;
    SayfaKontrol^.FPaneller[3]^.Gizle;
  end
  else if(SayfaKontrol^.FAktifSayfa = 3) then
  begin

    SayfaKontrol^.FPaneller[0]^.Gizle;
    SayfaKontrol^.FPaneller[1]^.Gizle;
    SayfaKontrol^.FPaneller[2]^.Gizle;
    SayfaKontrol^.FPaneller[3]^.Goster;
  end;

  inherited Goster;
end;

{==============================================================================
  sayfa kontrol nesnesini gizler
 ==============================================================================}
procedure TSayfaKontrol.Gizle;
var
  SayfaKontrol: PSayfaKontrol = nil;
begin

  // nesnenin kimlik, tip de�erlerini denetle.
  SayfaKontrol := PSayfaKontrol(GorselNesneler0.NesneAl(Kimlik));
  if(SayfaKontrol = nil) then Exit;

  inherited Gizle;
end;

{==============================================================================
  sayfa kontrol nesnesini hizaland�r�r
 ==============================================================================}
procedure TSayfaKontrol.Hizala;
begin

  inherited Hizala;
end;

{==============================================================================
  sayfa kontrol nesnesini �izer
 ==============================================================================}
procedure TSayfaKontrol.Ciz;
var
  SayfaKontrol: PSayfaKontrol = nil;
begin

  SayfaKontrol := PSayfaKontrol(GorselNesneler0.NesneAl(Kimlik));
  if(SayfaKontrol = nil) then Exit;

  if(SayfaKontrol^.FAktifSayfa = 0) then
  begin

    SayfaKontrol^.FPaneller[0]^.Goster;
    SayfaKontrol^.FPaneller[1]^.Gizle;
    SayfaKontrol^.FPaneller[2]^.Gizle;
    SayfaKontrol^.FPaneller[3]^.Gizle;
  end
  else if(SayfaKontrol^.FAktifSayfa = 1) then
  begin

    SayfaKontrol^.FPaneller[0]^.Gizle;
    SayfaKontrol^.FPaneller[1]^.Goster;
    SayfaKontrol^.FPaneller[2]^.Gizle;
    SayfaKontrol^.FPaneller[3]^.Gizle;
  end
  else if(SayfaKontrol^.FAktifSayfa = 2) then
  begin

    SayfaKontrol^.FPaneller[0]^.Gizle;
    SayfaKontrol^.FPaneller[1]^.Gizle;
    SayfaKontrol^.FPaneller[2]^.Goster;
    SayfaKontrol^.FPaneller[3]^.Gizle;
  end
  else if(SayfaKontrol^.FAktifSayfa = 3) then
  begin

    SayfaKontrol^.FPaneller[0]^.Gizle;
    SayfaKontrol^.FPaneller[1]^.Gizle;
    SayfaKontrol^.FPaneller[2]^.Gizle;
    SayfaKontrol^.FPaneller[3]^.Goster;
  end;

  // �ncelikle kendini �iz
  inherited Ciz;
end;

{==============================================================================
  sayfa kontrol nesne olaylar�n� i�ler
 ==============================================================================}
procedure TSayfaKontrol.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  SayfaKontrol: PSayfaKontrol = nil;
begin

  SayfaKontrol := PSayfaKontrol(AGonderici);

  // ge�erli fare g�stergesini g�ncelle
  GecerliFareGostegeTipi := SayfaKontrol^.FareImlecTipi;
end;

{==============================================================================
  sekme olaylar�n� i�ler
 ==============================================================================}
procedure TSayfaKontrol.SekmeOlaylariniIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Dugme: PDugme = nil;
  SayfaKontrol: PSayfaKontrol = nil;
begin

  // nesnenin kimlik, tip de�erlerini denetle.
  Dugme := PDugme(AGonderici);
  if(Dugme = nil) then Exit;

  SayfaKontrol := PSayfaKontrol(Dugme^.AtaNesne);

  // hangi sekmeye t�kland�ysa o sekmenin panel g�r�n�rl���n� aktifle�tir
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    if(AOlay.Kimlik = SayfaKontrol^.FDugmeler[0]^.Kimlik) then
      SayfaKontrol^.FAktifSayfa := 0
    else if(AOlay.Kimlik = SayfaKontrol^.FDugmeler[1]^.Kimlik) then
      SayfaKontrol^.FAktifSayfa := 1
    else if(AOlay.Kimlik = SayfaKontrol^.FDugmeler[2]^.Kimlik) then
      SayfaKontrol^.FAktifSayfa := 2
    else if(AOlay.Kimlik = SayfaKontrol^.FDugmeler[3]^.Kimlik) then
      SayfaKontrol^.FAktifSayfa := 3;

    SayfaKontrol^.Ciz;
  end
end;

function TSayfaKontrol.SayfaEkle(ABaslik: string): TKimlik;
var
  SayfaKontrol: PSayfaKontrol = nil;
  i: TSayi4;
begin

  // nesnenin kimlik, tip de�erlerini denetle.
  SayfaKontrol := PSayfaKontrol(GorselNesneler0.NesneAl(Kimlik));
  if(SayfaKontrol = nil) then Exit;

  i := SayfaKontrol^.FSayfaSayisi;
  if(i >= AZAMI_SEKMESAYISI) then Exit;

  if(i = 0) then
  begin

    // sekme d��me ba�l�k geni�li�i
    FBaslikG[0] := Length(ABaslik) * 8 + 10;

    // sekme d��mesi
    SayfaKontrol^.FDugmeler[0] := SayfaKontrol^.FDugmeler[0]^.Olustur(ktBilesen,
      SayfaKontrol, 0, 0, FBaslikG[0], 20, ABaslik);
    SayfaKontrol^.FDugmeler[0]^.CizimModelDegistir(False, RENK_GRI, RENK_GUMUS, RENK_SIYAH, RENK_KIRMIZI);
    SayfaKontrol^.FDugmeler[0]^.OlayYonlendirmeAdresi := @SekmeOlaylariniIsle;
    SayfaKontrol^.FDugmeler[0]^.Goster;

    // sekme paneli
    SayfaKontrol^.FPaneller[0] := SayfaKontrol^.FPaneller[0]^.Olustur(ktBilesen,
      SayfaKontrol, 0, 20, SayfaKontrol^.FAtananAlan.Genislik, SayfaKontrol^.FAtananAlan.Yukseklik - 20,
      3, RENK_SIYAH, RENK_BEYAZ, 0, '');
    //SayfaKontrol^.FPaneller[i]^.FHiza := hzTum;
    SayfaKontrol^.FPaneller[0]^.Gorunum := True;

    SayfaKontrol^.FSayfaSayisi := 1;
    SayfaKontrol^.FAktifSayfa := 0;

    Result := SayfaKontrol^.FPaneller[0]^.Kimlik;
  end
  else if(i = 1) then
  begin

    // sekme d��me ba�l�k geni�li�i
    FBaslikG[1] := Length(ABaslik) * 8 + 10;

    // sekme d��mesi
    SayfaKontrol^.FDugmeler[1] := SayfaKontrol^.FDugmeler[1]^.Olustur(ktBilesen,
      SayfaKontrol, FBaslikG[0], 0, FBaslikG[1], 20, ABaslik);
    SayfaKontrol^.FDugmeler[1]^.CizimModelDegistir(False, RENK_GRI, RENK_GUMUS, RENK_SIYAH, RENK_KIRMIZI);
    SayfaKontrol^.FDugmeler[1]^.OlayYonlendirmeAdresi := @SekmeOlaylariniIsle;
    SayfaKontrol^.FDugmeler[1]^.Goster;

    // sekme paneli
    SayfaKontrol^.FPaneller[1] := SayfaKontrol^.FPaneller[1]^.Olustur(ktBilesen,
      SayfaKontrol, 0, 20, SayfaKontrol^.FAtananAlan.Genislik, SayfaKontrol^.FAtananAlan.Yukseklik - 20,
      3, RENK_SIYAH, RENK_BEYAZ, 0, '');
    //SayfaKontrol^.FPaneller[i]^.FHiza := hzTum;
    SayfaKontrol^.FPaneller[1]^.Gorunum := True;

    SayfaKontrol^.FSayfaSayisi := 2;
    SayfaKontrol^.FAktifSayfa := 0;

    Result := SayfaKontrol^.FPaneller[1]^.Kimlik;
  end
  else if(i = 2) then
  begin

    // sekme d��me ba�l�k geni�li�i
    FBaslikG[2] := Length(ABaslik) * 8 + 10;

    // sekme d��mesi
    SayfaKontrol^.FDugmeler[2] := SayfaKontrol^.FDugmeler[2]^.Olustur(ktBilesen,
      SayfaKontrol, FBaslikG[0] + FBaslikG[1], 0, FBaslikG[2], 20, ABaslik);
    SayfaKontrol^.FDugmeler[2]^.CizimModelDegistir(False, RENK_GRI, RENK_GUMUS, RENK_SIYAH, RENK_KIRMIZI);
    SayfaKontrol^.FDugmeler[2]^.OlayYonlendirmeAdresi := @SekmeOlaylariniIsle;
    SayfaKontrol^.FDugmeler[2]^.Goster;

    // sekme paneli
    SayfaKontrol^.FPaneller[2] := SayfaKontrol^.FPaneller[2]^.Olustur(ktBilesen,
      SayfaKontrol, 0, 20, SayfaKontrol^.FAtananAlan.Genislik, SayfaKontrol^.FAtananAlan.Yukseklik - 20,
      3, RENK_SIYAH, RENK_BEYAZ, 0, '');
    //SayfaKontrol^.FPaneller[i]^.FHiza := hzTum;
    SayfaKontrol^.FPaneller[2]^.Gorunum := True;

    SayfaKontrol^.FSayfaSayisi := 3;
    SayfaKontrol^.FAktifSayfa := 0;

    Result := SayfaKontrol^.FPaneller[2]^.Kimlik;
  end
  else //if(i = 3) then
  begin

    // sekme d��me ba�l�k geni�li�i
    FBaslikG[3] := Length(ABaslik) * 8 + 10;

    // sekme d��mesi
    SayfaKontrol^.FDugmeler[3] := SayfaKontrol^.FDugmeler[3]^.Olustur(ktBilesen,
      SayfaKontrol, FBaslikG[0] + FBaslikG[1] + FBaslikG[2], 0, FBaslikG[3], 20, ABaslik);
    SayfaKontrol^.FDugmeler[3]^.CizimModelDegistir(False, RENK_GRI, RENK_GUMUS, RENK_SIYAH, RENK_KIRMIZI);
    SayfaKontrol^.FDugmeler[3]^.OlayYonlendirmeAdresi := @SekmeOlaylariniIsle;
    SayfaKontrol^.FDugmeler[3]^.Goster;

    // sekme paneli
    SayfaKontrol^.FPaneller[3] := SayfaKontrol^.FPaneller[3]^.Olustur(ktBilesen,
      SayfaKontrol, 0, 20, SayfaKontrol^.FAtananAlan.Genislik, SayfaKontrol^.FAtananAlan.Yukseklik - 20,
      3, RENK_SIYAH, RENK_BEYAZ, 0, '');
    //SayfaKontrol^.FPaneller[i]^.FHiza := hzTum;
    SayfaKontrol^.FPaneller[3]^.Gorunum := True;

    SayfaKontrol^.FSayfaSayisi := 4;
    SayfaKontrol^.FAktifSayfa := 0;

    Result := SayfaKontrol^.FPaneller[3]^.Kimlik;
  end;
end;

{==============================================================================
  her bir sekmeyi temsil eden panelinin i�erisine etiket (yaz�) ekler
  { TODO : ileride t�m g�rsel nesnelerin bu panele eklenmesi sa�lanacak }
 ==============================================================================}
procedure TSayfaKontrol.EtiketEkle(ASayfaNo, ASol, AUst: TISayi4; ABaslik: string);
var
  SayfaKontrol: PSayfaKontrol = nil;
  Panel: PPanel = nil;
  Etiket: PEtiket = nil;
  Genislik: TSayi4;
begin

  // nesnenin kimlik, tip de�erlerini denetle.
  SayfaKontrol := PSayfaKontrol(GorselNesneler0.NesneAl(Kimlik));
  if(SayfaKontrol = nil) then Exit;

  if(ASayfaNo = 0) then
    Panel := SayfaKontrol^.FPaneller[0]
  else if(ASayfaNo = 1) then
    Panel := SayfaKontrol^.FPaneller[1]
  else if(ASayfaNo = 2) then
    Panel := SayfaKontrol^.FPaneller[2]
  else //if(ASayfaNo = 3) then
    Panel := SayfaKontrol^.FPaneller[3];

  Genislik := Length(ABaslik) * 8;

  Etiket := Etiket^.Olustur(ktBilesen, Panel, ASol, AUst, Genislik, 16, RENK_SIYAH, ABaslik);
  Etiket^.Gorunum := True;
end;

end.
