{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_degerdugmesi.pp
  Dosya İşlevi: artırma / eksiltme (TUpDown) düğme yönetim işlevlerini içerir

  Güncelleme Tarihi: 16/07/2024

 ==============================================================================}
{$mode objfpc}
unit gn_degerdugmesi;

interface

uses gorev, gorselnesne, paylasim, gn_resimdugmesi, gn_panel;

type
  PDegerDugmesi = ^TDegerDugmesi;
  TDegerDugmesi = object(TPanel)
  private
    FArtirmaDugmesi,
    FEksiltmeDugmesi: PResimDugmesi;
    procedure ResimDugmeOlaylariniIsle(AGonderici: PGorselNesne; AOlay: TOlay);
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4): PDegerDugmesi;
    procedure YokEt(AKimlik: TKimlik);
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
  end;

function DegerDugmesiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;

implementation

uses genel, temelgorselnesne;

{==============================================================================
  artırma / eksiltme düğme kesme çağrılarını yönetir
 ==============================================================================}
function DegerDugmesiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne;
  DegerDugmesi: PDegerDugmesi;
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

      DegerDugmesi := PDegerDugmesi(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      DegerDugmesi^.Goster;
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  artırma / eksiltme düğme nesnesini oluşturur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
var
  DegerDugmesi: PDegerDugmesi;
begin

  DegerDugmesi := DegerDugmesi^.Olustur(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik);

  if(DegerDugmesi = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := DegerDugmesi^.Kimlik;
end;

{==============================================================================
  artırma / eksiltme düğme nesnesini oluşturur
 ==============================================================================}
function TDegerDugmesi.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4): PDegerDugmesi;
var
  DegerDugmesi: PDegerDugmesi;
begin

  DegerDugmesi := PDegerDugmesi(inherited Olustur(AKullanimTipi, AAtaNesne,
    ASol, AUst, 18, 21, 0, 0, 0, 0, ''));

  DegerDugmesi^.NesneTipi := gntDegerDugmesi;

  DegerDugmesi^.Baslik := '';

  DegerDugmesi^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  DegerDugmesi^.OlayCagriAdresi := @OlaylariIsle;

  // $10000000 + 1 = yukarı ok resmi
  DegerDugmesi^.FArtirmaDugmesi := DegerDugmesi^.FArtirmaDugmesi^.Olustur(ktBilesen,
    DegerDugmesi, 0, 0, 18, 10, $10000000 + 1, True);
  DegerDugmesi^.FArtirmaDugmesi^.OlayYonlendirmeAdresi := @ResimDugmeOlaylariniIsle;

  // $10000000 + 2 = aşağı ok resmi
  DegerDugmesi^.FEksiltmeDugmesi := DegerDugmesi^.FEksiltmeDugmesi^.Olustur(ktBilesen,
    DegerDugmesi, 0, 11, 18, 10, $10000000 + 2, True);
  DegerDugmesi^.FEksiltmeDugmesi^.OlayYonlendirmeAdresi := @ResimDugmeOlaylariniIsle;

  // kimlik adresini geri döndür
  Result := DegerDugmesi;
end;

{==============================================================================
  artırma / eksiltme düğme nesnesini yok eder
 ==============================================================================}
procedure TDegerDugmesi.YokEt(AKimlik: TKimlik);
var
  DegerDugmesi: PDegerDugmesi;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  DegerDugmesi := PDegerDugmesi(GorselNesneler0.NesneAl(AKimlik));
  if(DegerDugmesi = nil) then Exit;

  DegerDugmesi^.FArtirmaDugmesi^.YokEt(DegerDugmesi^.FArtirmaDugmesi^.Kimlik);
  DegerDugmesi^.FEksiltmeDugmesi^.YokEt(DegerDugmesi^.FEksiltmeDugmesi^.Kimlik);

  inherited YokEt(AKimlik);
end;

{==============================================================================
  artırma / eksiltme düğme nesnesini görüntüler
 ==============================================================================}
procedure TDegerDugmesi.Goster;
var
  DegerDugmesi: PDegerDugmesi;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  DegerDugmesi := PDegerDugmesi(GorselNesneler0.NesneAl(Kimlik));
  if(DegerDugmesi = nil) then Exit;

  DegerDugmesi^.FArtirmaDugmesi^.Goster;
  DegerDugmesi^.FEksiltmeDugmesi^.Goster;

  inherited Goster;
end;

{==============================================================================
  artırma / eksiltme düğme nesnesini gizler
 ==============================================================================}
procedure TDegerDugmesi.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  artırma / eksiltme düğme nesnesini hizalandırır
 ==============================================================================}
procedure TDegerDugmesi.Hizala;
var
  DegerDugmesi: PDegerDugmesi;
begin

  DegerDugmesi := PDegerDugmesi(GorselNesneler0.NesneAl(Kimlik));
  if(DegerDugmesi = nil) then Exit;

  inherited Hizala;
end;

{==============================================================================
  artırma / eksiltme düğme nesnesini çizer
 ==============================================================================}
procedure TDegerDugmesi.Ciz;
var
  DegerDugmesi: PDegerDugmesi;
begin

  DegerDugmesi := PDegerDugmesi(GorselNesneler0.NesneAl(Kimlik));
  if(DegerDugmesi = nil) then Exit;

  inherited Ciz;

  DegerDugmesi^.FEksiltmeDugmesi^.Ciz;
  DegerDugmesi^.FArtirmaDugmesi^.Ciz;
end;

{==============================================================================
  artırma / eksiltme düğme nesne olaylarını işler
 ==============================================================================}
procedure TDegerDugmesi.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  DegerDugmesi: PDegerDugmesi;
begin

  DegerDugmesi := PDegerDugmesi(AGonderici);
  if(DegerDugmesi = nil) then Exit;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := DegerDugmesi^.FareImlecTipi;
end;

{==============================================================================
  artırma / eksiltme düğmesinin sahip olduğu resim düğmesi olaylarını işler
 ==============================================================================}
procedure TDegerDugmesi.ResimDugmeOlaylariniIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  DegerDugmesi: PDegerDugmesi;
  ResimDugmesi: PResimDugmesi;
begin

  ResimDugmesi := PResimDugmesi(AGonderici);
  if(ResimDugmesi = nil) then Exit;

  DegerDugmesi := PDegerDugmesi(ResimDugmesi^.AtaNesne);

  if(AOlay.Olay = FO_TIKLAMA) then
  begin

    if(AOlay.Kimlik = DegerDugmesi^.FArtirmaDugmesi^.Kimlik) then
    begin

      // nesnenin olay çağrı adresini çağır veya uygulamaya mesaj gönder
      AOlay.Kimlik := DegerDugmesi^.Kimlik;
      AOlay.Deger1 := 0;
      if not(DegerDugmesi^.OlayYonlendirmeAdresi = nil) then
        DegerDugmesi^.OlayYonlendirmeAdresi(DegerDugmesi, AOlay)
      else Gorevler0.OlayEkle(DegerDugmesi^.GorevKimlik, AOlay);
    end
    else if(AOlay.Kimlik = DegerDugmesi^.FEksiltmeDugmesi^.Kimlik) then
    begin

      // nesnenin olay çağrı adresini çağır veya uygulamaya mesaj gönder
      AOlay.Kimlik := DegerDugmesi^.Kimlik;
      AOlay.Deger1 := 1;
      if not(DegerDugmesi^.OlayYonlendirmeAdresi = nil) then
        DegerDugmesi^.OlayYonlendirmeAdresi(DegerDugmesi, AOlay)
      else Gorevler0.OlayEkle(DegerDugmesi^.GorevKimlik, AOlay);
    end;
  end;
end;

end.
