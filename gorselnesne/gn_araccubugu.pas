{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_araccubugu.pas
  Dosya İşlevi: araç çubuğu (TToolBar) nesne yönetim işlevlerini içerir

  Güncelleme Tarihi: 16/07/2026

 ==============================================================================}
{$mode objfpc}
unit gn_araccubugu;

interface

uses gorev, gorselnesne, paylasim, gn_panel, gn_resimdugmesi;

const
  AZAMI_DUGME_SAYISI = 50;

type
  PAracCubugu = ^TAracCubugu;
  TAracCubugu = object(TPanel)
  private
    // araç çubuğunda yer alacak düğme listesi
    FDugmeSayisi: TSayi4;
    FDugmeler: array[0..AZAMI_DUGME_SAYISI - 1] of PResimDugmesi;
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne): PAracCubugu;
    procedure YokEt(AKimlik: TKimlik);
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    procedure ResimDugmeOlaylariniIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    function DugmeEkle(AResimSiraNo: TSayi4): TKimlik;
    function DugmeEkle2(AResimSiraNo: TSayi4): TKimlik;
  end;

function AracCubuguCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne): TKimlik;

implementation

uses genel, temelgorselnesne;

{==============================================================================
  araç çubuğu nesne kesme çağrılarını yönetir
 ==============================================================================}
function AracCubuguCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne = nil;
  AracCubugu: PAracCubugu = nil;
begin

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GN);
    end;

    ISLEV_GOSTER:
    begin

      AracCubugu := PAracCubugu(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      AracCubugu^.Goster;
    end;

    // araç çubuğuna düğme ekle
    $010F:
    begin

      AracCubugu := PAracCubugu(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      if not(AracCubugu = nil) then
        Result := AracCubugu^.DugmeEkle(PISayi4(ADegiskenler + 04)^);
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  araç çubuğu nesnesini oluşturur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne): TKimlik;
var
  AracCubugu: PAracCubugu = nil;
begin

  AracCubugu := AracCubugu^.Olustur(ktNesne, AAtaNesne);

  if(AracCubugu = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := AracCubugu^.Kimlik;
end;

{==============================================================================
  araç çubuğu nesnesini oluşturur
 ==============================================================================}
function TAracCubugu.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne): PAracCubugu;
var
  AracCubugu: PAracCubugu = nil;
  i: TSayi4;
begin

  AracCubugu := PAracCubugu(inherited Olustur(AKullanimTipi, AAtaNesne, 0, 0, 10,
    28, 2, RENK_GUMUS, RENK_BEYAZ, 0, ''));

  // nesnenin ad değeri
  AracCubugu^.NesneTipi := gntAracCubugu;

  AracCubugu^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  AracCubugu^.OlayCagriAdresi := @OlaylariIsle;

  AracCubugu^.FHiza := hzUst;

  // düğme değerlerinin ilk değerlerle yüklenmesi
  AracCubugu^.FDugmeSayisi := 0;

  for i := 0 to AZAMI_DUGME_SAYISI - 1 do AracCubugu^.FDugmeler[i] := nil;

  // nesne adresini geri döndür
  Result := AracCubugu;
end;

{==============================================================================
  araç çubuğu nesnesini yok eder
 ==============================================================================}
procedure TAracCubugu.YokEt(AKimlik: TKimlik);
var
  AracCubugu: PAracCubugu;
  i: TSayi4;
begin

  AracCubugu := PAracCubugu(GorselNesneler0.NesneAl(AKimlik));
  if(AracCubugu = nil) then Exit;

  for i := 0 to AZAMI_DUGME_SAYISI - 1 do
  begin

    if not(AracCubugu^.FDugmeler[i] = nil) then
      AracCubugu^.FDugmeler[i]^.YokEt(AracCubugu^.FDugmeler[i]^.Kimlik);
  end;

  inherited YokEt(AKimlik);
end;

{==============================================================================
  araç çubuğu nesnesini görüntüler
 ==============================================================================}
procedure TAracCubugu.Goster;
var
  AracCubugu: PAracCubugu = nil;
//  i: TSayi4;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  AracCubugu := PAracCubugu(GorselNesneler0.NesneAl(Kimlik));
  if(AracCubugu = nil) then Exit;

{  if(AracCubugu^.FDugmeSayisi > 0) then
  begin

    for i := 0 to AracCubugu^.FDugmeSayisi - 1 do
    begin

      if not(AracCubugu^.FDugmeler[i] = nil) then AracCubugu^.FDugmeler[i]^.Goster;
    end;
  end;
}
  inherited Goster;
end;

{==============================================================================
  araç çubuğu nesnesini gizler
 ==============================================================================}
procedure TAracCubugu.Gizle;
var
  AracCubugu: PAracCubugu = nil;
//  i: TSayi4;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  AracCubugu := PAracCubugu(GorselNesneler0.NesneAl(Kimlik));
  if(AracCubugu = nil) then Exit;
{
  if(AracCubugu^.FDugmeSayisi > 0) then
  begin

    for i := 0 to AracCubugu^.FDugmeSayisi - 1 do
    begin

      if not(AracCubugu^.FDugmeler[i] = nil) then AracCubugu^.FDugmeler[i]^.Gizle;
    end;
  end;
}
  inherited Gizle;
end;

{==============================================================================
  araç çubuğu nesnesini hizalandırır
 ==============================================================================}
procedure TAracCubugu.Hizala;
begin

  inherited Hizala;
end;

{==============================================================================
  araç çubuğu nesnesini çizer
 ==============================================================================}
procedure TAracCubugu.Ciz;
var
  AracCubugu: PAracCubugu = nil;
//  i: Integer;
begin

  AracCubugu := PAracCubugu(GorselNesneler0.NesneAl(Kimlik));
  if(AracCubugu = nil) then Exit;

  // öncelikle kendini çiz
  inherited Ciz;
{
  // daha sonra alt nesne düğmeleri
  if(AracCubugu^.FDugmeSayisi > 0) then
  begin

    for i := 0 to AracCubugu^.FDugmeSayisi - 1 do
    begin

      if not(AracCubugu^.FDugmeler[i] = nil) then AracCubugu^.FDugmeler[i]^.Ciz;
    end;
  end; }
end;

{==============================================================================
  araç çubuğu nesne olaylarını işler
 ==============================================================================}
procedure TAracCubugu.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  AracCubugu: PAracCubugu = nil;
begin

  AracCubugu := PAracCubugu(AGonderici);
  if(AracCubugu = nil) then Exit;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := AracCubugu^.FareImlecTipi;
end;

procedure TAracCubugu.ResimDugmeOlaylariniIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  AracCubugu: PAracCubugu = nil;
  ResimDugmesi: PResimDugmesi = nil;
begin

  ResimDugmesi := PResimDugmesi(AGonderici);
  if(ResimDugmesi = nil) then Exit;

  AracCubugu := PAracCubugu(ResimDugmesi^.AtaNesne);

  if(AOlay.Olay = FO_TIKLAMA) then
  begin

    AOlay.Kimlik := ResimDugmesi^.Kimlik;

    if not(AracCubugu^.OlayYonlendirmeAdresi = nil) then
      AracCubugu^.OlayYonlendirmeAdresi(ResimDugmesi, AOlay)
    else Gorevler0.OlayEkle(ResimDugmesi^.GorevKimlik, AOlay);
  end;
end;

// araç çubuğuna düğme ekler - programlar için
function TAracCubugu.DugmeEkle(AResimSiraNo: TSayi4): TKimlik;
var
  AracCubugu: PAracCubugu = nil;
  ResimDugmesi: PResimDugmesi = nil;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  AracCubugu := PAracCubugu(GorselNesneler0.NesneAl(Kimlik));
  if(AracCubugu = nil) then Exit(HATA_KIMLIK);

  if(AracCubugu^.FDugmeSayisi >= AZAMI_DUGME_SAYISI) then Exit(-1);

  ResimDugmesi := ResimDugmesi^.Olustur(ktBilesen, AracCubugu,
    (FDugmeSayisi * 30) + 4, 1, 24, 24, $10000000 + AResimSiraNo, False);
  ResimDugmesi^.OlayYonlendirmeAdresi := @ResimDugmeOlaylariniIsle;
  ResimDugmesi^.Gorunum := True;

  AracCubugu^.FDugmeler[AracCubugu^.FDugmeSayisi] := ResimDugmesi;

  Inc(AracCubugu^.FDugmeSayisi);

  Result := ResimDugmesi^.Kimlik;
end;

// araç çubuğuna düğme ekler - çekirdek grafiksel programlama çalışması için
function TAracCubugu.DugmeEkle2(AResimSiraNo: TSayi4): TKimlik;
var
  AracCubugu: PAracCubugu = nil;
  ResimDugmesi: PResimDugmesi = nil;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  AracCubugu := PAracCubugu(GorselNesneler0.NesneAl(Kimlik));
  if(AracCubugu = nil) then Exit(HATA_KIMLIK);

  if(AracCubugu^.FDugmeSayisi >= AZAMI_DUGME_SAYISI) then Exit(-1);

  ResimDugmesi := ResimDugmesi^.Olustur(ktNesne, AracCubugu,
    (FDugmeSayisi * 30) + 4, 1, 24, 24, $30000000 + AResimSiraNo, False);
  ResimDugmesi^.OlayYonlendirmeAdresi := @ResimDugmeOlaylariniIsle;
  ResimDugmesi^.Gorunum := True;

  AracCubugu^.FDugmeler[AracCubugu^.FDugmeSayisi] := ResimDugmesi;

  Inc(AracCubugu^.FDugmeSayisi);

  Result := ResimDugmesi^.Kimlik;
end;

end.
