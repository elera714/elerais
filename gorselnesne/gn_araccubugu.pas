{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: gn_araccubugu.pas
  Dosya Ýþlevi: araç çubuðu (TToolBar) nesne yönetim iþlevlerini içerir

  Güncelleme Tarihi: 26/02/2025

 ==============================================================================}
{$mode objfpc}
unit gn_araccubugu;

interface

uses gorselnesne, paylasim, gn_panel, gn_resimdugmesi;

const
  AZAMI_DUGME_SAYISI = 50;

type
  PAracCubugu = ^TAracCubugu;
  TAracCubugu = object(TPanel)
  private
    // araç çubuðunda yer alacak düðme listesi
    FDugmeSayisi: TSayi4;
    FDugmeler: array[0..AZAMI_DUGME_SAYISI - 1] of PResimDugmesi;
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne): PAracCubugu;
    procedure YokEt;
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
  araç çubuðu nesne kesme çaðrýlarýný yönetir
 ==============================================================================}
function AracCubuguCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne = nil;
  AracCubugu: PAracCubugu = nil;
begin

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GN := GN^.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GN);
    end;

    ISLEV_GOSTER:
    begin

      AracCubugu := PAracCubugu(AracCubugu^.NesneAl(PKimlik(ADegiskenler + 00)^));
      AracCubugu^.Goster;
    end;

    // araç çubuðuna düðme ekle
    $010F:
    begin

      AracCubugu := PAracCubugu(AracCubugu^.NesneAl(PKimlik(ADegiskenler + 00)^));
      if not(AracCubugu = nil) then
        Result := AracCubugu^.DugmeEkle(PISayi4(ADegiskenler + 04)^);
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  araç çubuðu nesnesini oluþturur
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
  araç çubuðu nesnesini oluþturur
 ==============================================================================}
function TAracCubugu.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne): PAracCubugu;
var
  AracCubugu: PAracCubugu = nil;
  i: TSayi4;
begin

  AracCubugu := PAracCubugu(inherited Olustur(AKullanimTipi, AAtaNesne, 0, 0, 10,
    28, 2, RENK_GUMUS, RENK_BEYAZ, 0, ''));

  // nesnenin ad deðeri
  AracCubugu^.NesneTipi := gntAracCubugu;

  AracCubugu^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  AracCubugu^.OlayCagriAdresi := @OlaylariIsle;

  AracCubugu^.FHiza := hzUst;

  // düðme deðerlerinin ilk deðerlerle yüklenmesi
  FDugmeSayisi := 0;
  for i := 0 to AZAMI_DUGME_SAYISI - 1 do FDugmeler[i] := nil;

  // nesne adresini geri döndür
  Result := AracCubugu;
end;

{==============================================================================
  araç çubuðu nesnesini yok eder
 ==============================================================================}
procedure TAracCubugu.YokEt;
begin

  inherited YokEt;
end;

{==============================================================================
  araç çubuðu nesnesini görüntüler
 ==============================================================================}
procedure TAracCubugu.Goster;
var
  AracCubugu: PAracCubugu = nil;
//  i: TSayi4;
begin

  // nesnenin kimlik, tip deðerlerini denetle.
  AracCubugu := PAracCubugu(AracCubugu^.NesneAl(Kimlik));
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
  araç çubuðu nesnesini gizler
 ==============================================================================}
procedure TAracCubugu.Gizle;
var
  AracCubugu: PAracCubugu = nil;
//  i: TSayi4;
begin

  // nesnenin kimlik, tip deðerlerini denetle.
  AracCubugu := PAracCubugu(AracCubugu^.NesneAl(Kimlik));
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
  araç çubuðu nesnesini hizalandýrýr
 ==============================================================================}
procedure TAracCubugu.Hizala;
begin

  inherited Hizala;
end;

{==============================================================================
  araç çubuðu nesnesini çizer
 ==============================================================================}
procedure TAracCubugu.Ciz;
var
  AracCubugu: PAracCubugu = nil;
//  i: Integer;
begin

  AracCubugu := PAracCubugu(AracCubugu^.NesneAl(Kimlik));
  if(AracCubugu = nil) then Exit;

  // öncelikle kendini çiz
  inherited Ciz;
{
  // daha sonra alt nesne düðmeleri
  if(AracCubugu^.FDugmeSayisi > 0) then
  begin

    for i := 0 to AracCubugu^.FDugmeSayisi - 1 do
    begin

      if not(AracCubugu^.FDugmeler[i] = nil) then AracCubugu^.FDugmeler[i]^.Ciz;
    end;
  end; }
end;

{==============================================================================
  araç çubuðu nesne olaylarýný iþler
 ==============================================================================}
procedure TAracCubugu.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  AracCubugu: PAracCubugu = nil;
begin

  AracCubugu := PAracCubugu(AGonderici);
  if(AracCubugu = nil) then Exit;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := AracCubugu^.FFareImlecTipi;
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
    else GGorevler.OlayEkle(ResimDugmesi^.GorevKimlik, AOlay);
  end;
end;

// araç çubuðuna düðme ekler - programlar için
function TAracCubugu.DugmeEkle(AResimSiraNo: TSayi4): TKimlik;
var
  AracCubugu: PAracCubugu = nil;
  ResimDugmesi: PResimDugmesi = nil;
begin

  // nesnenin kimlik, tip deðerlerini denetle.
  AracCubugu := PAracCubugu(AracCubugu^.NesneAl(Kimlik));
  if(AracCubugu = nil) then Exit;

  if(AracCubugu^.FDugmeSayisi > AZAMI_DUGME_SAYISI) then Exit;

  ResimDugmesi := ResimDugmesi^.Olustur(ktBilesen, AracCubugu,
    (FDugmeSayisi * 30) + 4, 1, 24, 24, $10000000 + AResimSiraNo, False);
  ResimDugmesi^.OlayYonlendirmeAdresi := @ResimDugmeOlaylariniIsle;
  ResimDugmesi^.Gorunum := True;

  FDugmeler[FDugmeSayisi] := ResimDugmesi;

  Inc(FDugmeSayisi);

  Result := ResimDugmesi^.Kimlik;
end;

// araç çubuðuna düðme ekler - çekirdek grafiksel programlama çalýþmasý için
function TAracCubugu.DugmeEkle2(AResimSiraNo: TSayi4): TKimlik;
var
  AracCubugu: PAracCubugu = nil;
  ResimDugmesi: PResimDugmesi = nil;
begin

  // nesnenin kimlik, tip deðerlerini denetle.
  AracCubugu := PAracCubugu(AracCubugu^.NesneAl(Kimlik));
  if(AracCubugu = nil) then Exit;

  if(AracCubugu^.FDugmeSayisi > AZAMI_DUGME_SAYISI) then Exit;

  ResimDugmesi := ResimDugmesi^.Olustur(ktBilesen, AracCubugu,
    (FDugmeSayisi * 30) + 4, 1, 24, 24, $30000000 + AResimSiraNo, False);
  ResimDugmesi^.OlayYonlendirmeAdresi := @ResimDugmeOlaylariniIsle;
  ResimDugmesi^.Gorunum := True;

  FDugmeler[FDugmeSayisi] := ResimDugmesi;

  Inc(FDugmeSayisi);

  Result := ResimDugmesi^.Kimlik;
end;

end.
