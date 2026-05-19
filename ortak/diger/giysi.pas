{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: giysi.pas
  Dosya İşlevi: giysi (skin) işlevlerini yönetir

  Güncelleme Tarihi: 14/05/2026

 ==============================================================================}
{$mode objfpc}
unit giysi;

interface

uses paylasim;

const
  USTSINIR_GIYSI = 3;

type
  THamResim = record
    Genislik, Yukseklik: TSayi4;
    BellekAdresi: Isaretci;
  end;

type
  PGiysi = ^TGiysi;
  TGiysi = record
    Ad: string;

    BaslikYukseklik,

    ResimSolUstGenislik,
    ResimUstGenislik,
    ResimSagUstGenislik,

    ResimSolGenislik,
    ResimSolYukseklik,
    ResimSagGenislik,
    ResimSagYukseklik,

    ResimSolAltGenislik,
    ResimSolAltYukseklik,
    ResimAltGenislik,
    ResimAltYukseklik,
    ResimSagAltGenislik,
    ResimSagAltYukseklik,

    AktifBaslikYaziRengi,
    PasifBaslikYaziRengi,
    IcDolguRengi,
    BaslikYaziSol,
    BaslikYaziUst,

    KapatmaDugmesiSol,
    KapatmaDugmesiUst,
    KapatmaDugmesiGenislik,
    KapatmaDugmesiYukseklik,
    BuyutmeDugmesiSol,
    BuyutmeDugmesiUst,
    BuyutmeDugmesiGenislik,
    BuyutmeDugmesiYukseklik,
    KucultmeDugmesiSol,
    KucultmeDugmesiUst,
    KucultmeDugmesiGenislik,
    KucultmeDugmesiYukseklik: TISayi4;

    ResimSolUstA, ResimSolUstP,
    ResimUstA, ResimUstP,
    ResimSagUstA, ResimSagUstP,
    ResimSolA, ResimSolP,
    ResimSagA, ResimSagP,
    ResimSolAltA, ResimSolAltP,
    ResimAltA, ResimAltP,
    ResimSagAltA, ResimSagAltP: THamResim;

    // A(ktif), (P)asif kontrol düğme (R)esim (S)ıra numaraları
    AKapatmaDugmesiRSNo, ABuyutmeDugmesiRSNo, AKucultmeDugmesiRSNo,
    PKapatmaDugmesiRSNo, PBuyutmeDugmesiRSNo, PKucultmeDugmesiRSNo: TSayi4;
  end;

type
  PGiysiler = ^TGiysiler;
  TGiysiler = object
  private
    FToplamGiysi: TSayi4;
    FAktifGiysiSN: TISayi4;
    FAktifGiysi: PGiysi;
    FGiysiListesi: array[0..USTSINIR_GIYSI - 1] of PGiysi;
    function GiysiAl(ASiraNo: TISayi4): PGiysi;
    procedure GiysiYaz(ASiraNo: TISayi4; AGiysi: PGiysi);
  public
    procedure Yukle;
    property ToplamGiysi: TSayi4 read FToplamGiysi;
    property Giysi[ASiraNo: TISayi4]: PGiysi read GiysiAl write GiysiYaz;
    property AktifGiysiSN: TISayi4 read FAktifGiysiSN write FAktifGiysiSN;
    property AktifGiysi: PGiysi read FAktifGiysi write FAktifGiysi;
  end;

var
  Giysiler0: TGiysiler;

implementation

uses giysi_elera, giysi_mac, giysi_normal;

procedure TGiysiler.Yukle;
begin

  FToplamGiysi := USTSINIR_GIYSI;

  AktifGiysiSN := 0;

  Giysi[0] := @GiysiELERA;
  Giysi[1] := @GiysiNormal;
  Giysi[2] := @GiysiMac;

  AktifGiysi := Giysi[AktifGiysiSN];
end;

function TGiysiler.GiysiAl(ASiraNo: TISayi4): PGiysi;
begin

  // istenen verinin belirtilen aralıkta olup olmadığını kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_GIYSI) then
    Result := FGiysiListesi[ASiraNo]
  else Result := nil;
end;

procedure TGiysiler.GiysiYaz(ASiraNo: TISayi4; AGiysi: PGiysi);
begin

  // istenen verinin belirtilen aralıkta olup olmadığını kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_GIYSI) then
    FGiysiListesi[ASiraNo] := AGiysi;
end;

end.
