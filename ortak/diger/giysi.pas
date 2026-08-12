{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: giysi.pas
  Dosya İşlevi: giysi (skin) işlevlerini yönetir

  Güncelleme Tarihi: 12/08/2026

 ==============================================================================}
{$mode objfpc}
unit giysi;

interface

uses paylasim;

const
  USTSINIR_GIYSI = 3;

type
  THamResim = record
    Genislik, Yukseklik: TISayi4;
    BellekAdresi: Isaretci;
  end;

type
  PGiysi = ^TGiysi;
  TGiysi = class
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
    ResimSagAltYukseklik: TISayi4;

    AktifBaslikYaziRengi,
    PasifBaslikYaziRengi,
    IcDolguRengi,
    BaslikYaziSol,
    BaslikYaziUst: TSayi4;

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
  TGiysiler = class
  private
    FToplamGiysi: TSayi4;
    FAktifGiysiSN: TISayi4;
    FAktifGiysi: TGiysi;
    FGiysiListesi: array[0..USTSINIR_GIYSI - 1] of TGiysi;
    function Al(ASiraNo: TISayi4): TGiysi;
    procedure Yaz(ASiraNo: TISayi4; AGiysi: TGiysi);
  public
    constructor Create;
    property ToplamGiysi: TSayi4 read FToplamGiysi;
    property Giysi[ASiraNo: TISayi4]: TGiysi read Al write Yaz;
    property AktifGiysiSN: TISayi4 read FAktifGiysiSN write FAktifGiysiSN;
    property AktifGiysi: TGiysi read FAktifGiysi write FAktifGiysi;
  end;

var
  GGiysiler: TGiysiler;

implementation

uses giysi_elera, giysi_mac, giysi_normal;

constructor TGiysiler.Create;
begin

  FToplamGiysi := USTSINIR_GIYSI;

  FGiysiListesi[0] := TGiysiELERA.Create;
  FGiysiListesi[1] := TGiysiNormal.Create;
  FGiysiListesi[2] := TGiysiMAC.Create;

  AktifGiysiSN := 0;

  AktifGiysi := Giysi[AktifGiysiSN];
end;

function TGiysiler.Al(ASiraNo: TISayi4): TGiysi;
begin

  // aralık kontrol sorgusu
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_GIYSI) then
    Result := FGiysiListesi[ASiraNo]
  else Result := nil;
end;

procedure TGiysiler.Yaz(ASiraNo: TISayi4; AGiysi: TGiysi);
begin

  // aralık kontrol sorgusu
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_GIYSI) then
    FGiysiListesi[ASiraNo] := AGiysi;
end;

end.
