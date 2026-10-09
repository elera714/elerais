{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: dosya.pas
  Dosya İşlevi: dosya sistemleri ana yapısını içerir

  Güncelleme Tarihi: 09/10/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit dosya;

interface

uses paylasim, gorev, mdepolama;

type
  // dosya durumları
  TDosyaDurumu = (ddKapali, ddOkumaIcinAcik, ddYazmaIcinAcik);

type
  // Dosya Sistemi İşlem değişkenleri
  TDSIslem = record
    FSektorKumeNo,               // işlem yapılan Sektör / Küme numarası
    FZincirNo,                   // işlem yapılan zincir no
    FSIKonum,                    // işlem yapılan sektörün iç konum değeri
    FSonrakiSIKonum: TSayi4;     // işlem yapılan sektörün bir sonraki iç konum değeri
  end;


type
  PDosya = ^TDosya;
  TDosya = class
  public
    FKimlik: TKimlik;               // dosya işlemi kimliği
    FMD: TMDNesne;

    FDosyaDurumu: TDosyaDurumu;     // dosyanın durumu

    FKlasorDerinlik: TISayi4;       // 0 = kök dizin, 1 = alt dizin, 2 = alt dizinin alt dizini ...

    FUzunluk: TSayi4;               // işlem yapılan dosyanın uzunluğu

    // arama değişkenleri
    FArama: TDSIslem;
    FIslem: TDSIslem;
    FSilinen: TDSIslem;

    FBellekSHT: Isaretci;           // sektör harita tablosunu (fat) yüklemek için kullanılacak

    FGorev: PGorev;                 // dosya işlemini gerçekleştiren görev

    // dizin / dosya girişinin Tek Sektörlük Içeriği. (işlevler arası veri alışverişi için)
    FTSI: Isaretci;

    FAramaSuzgec,                   // arama yapılan süzgeç değeri: disket1:\klasör1\*.* gibi
    FKlasor, FDosyaAdi: string;     // arama yapılan klasör ve dosya adı

    constructor Create(AKimlik: TKimlik; AMDNesne: TMDNesne); virtual;
    destructor Destroy; override;

    procedure Append; virtual; abstract;
    procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string); virtual; abstract;
    procedure CloseFile; virtual; abstract;
    function CreateDir: Boolean; virtual; abstract;
    function DeleteFile: Boolean; virtual; abstract;
    function EOF: Boolean; virtual; abstract;
    function FileSize: TSayi4; virtual; abstract;

    function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
      var ADosyaArama: TDosyaArama): TSayi4; virtual; abstract;
    function FindNext(var ADosyaArama: TDosyaArama): TSayi4; virtual; abstract;
    function FindClose(var ADosyaArama: TDosyaArama): TSayi4; virtual; abstract;

    function IOResult: TSayi4; virtual; abstract;
    procedure Read(AHedefBellek: Isaretci); virtual; abstract;
    function RemoveDir: Boolean; virtual; abstract;
    procedure Reset; virtual; abstract;
    procedure ReWrite; virtual; abstract;
    procedure Write(AVeri: string); virtual; abstract;
    procedure WriteLn(AVeri: string); virtual; abstract;

    procedure DosyaDegerleriniBelirle(ADosyaTamYol: string);
  end;

implementation

uses islevler;

{==============================================================================
  dosya sistemi nesne ön değer yükleme işlevi
 ==============================================================================}
constructor TDosya.Create(AKimlik: TISayi4; AMDNesne: TMDNesne);
begin

  // ilk değer atamaları
  FKimlik := AKimlik;

  FMD := AMDNesne;

  FDosyaDurumu := ddKapali;
  FKlasorDerinlik := 0;
  FUzunluk := 0;

  FArama.FSektorKumeNo := 0;
  FArama.FZincirNo := 0;
  FArama.FSIKonum := 0;
  FArama.FSonrakiSIKonum := 0;

  FIslem.FSektorKumeNo := $FFFFFFFF;
  FIslem.FZincirNo := $FFFFFFFF;
  FIslem.FSIKonum := $FFFFFFFF;
  FIslem.FSonrakiSIKonum := $FFFFFFFF;

  FSilinen.FSektorKumeNo := $FFFFFFFF;
  FSilinen.FZincirNo := $FFFFFFFF;
  FSilinen.FSIKonum := $FFFFFFFF;
  FSilinen.FSonrakiSIKonum := $FFFFFFFF;

  FBellekSHT := nil;
  FGorev := nil;

  FTSI := GetMem(512);
end;

{==============================================================================
  dosya sistemi nesne yok etme işlevi
 ==============================================================================}
destructor TDosya.Destroy;
begin

  FreeMem(FTSI, 512);

  if not(FBellekSHT = nil) then FreeMem(FBellekSHT, 512);

  inherited Destroy;
end;

{==============================================================================
  dosya tam yolunu parçalar ayırır
 ==============================================================================}
procedure TDosya.DosyaDegerleriniBelirle(ADosyaTamYol: string);
var
  S, K, D: string;
begin

  // dosya yolunu ayrıştır
  DosyaYolunuParcala2(ADosyaTamYol, S, K, D);

  // klasör ve dosya adı
  FKlasor := K;
  FDosyaAdi := D;
end;

end.
