{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: aygit.pas
  Dosya İşlevi: sistemde mevcut tüm aygıtların temel sınıflarını içerir

  Güncelleme Tarihi: 06/09/2026

 ==============================================================================}
{$mode objfpc}
unit aygit;

interface

uses pci, paylasim;

type
  { bilgi: sistemde mevcut tüm aygıtların türeyeceği temel sınıf }
  PTemelAygit = ^TTemelAygit;
  TTemelAygit = class
  private
    FKimlik: TKimlik;
    FSurucuTipi: TSayi4;
    FSiraNo: TISayi4;
  private
    // aygıtın yüklenip yüklenmediğini belirtir
    FYuklendi,
    // aygıtın aktif / çalışır olup olmadığını belirtir
    FAktif: Boolean;
  public
    FAygitAdi: string[16];
    constructor Create; virtual;
  published
    property Kimlik: TKimlik read FKimlik write FKimlik;
    property SurucuTipi: TSayi4 read FSurucuTipi write FSurucuTipi;

    property Yuklendi: Boolean read FYuklendi write FYuklendi;
    property Aktif: Boolean read FAktif write FAktif;
  end;

type
  TFDAOkuYaz = function(AIlkSektor, ASektorSayisi: TSayi4;
    ABellek: Isaretci): TISayi4 of object;

type
  // Fiziksel Depolama Aygıtı (disk, disket vb.)
  PFDAygiti = ^TFDAygiti;
  TFDAygiti = class(TTemelAygit)
  public
    FAnaPort: TSayi4;
    FKontrolPort: TSayi4;
    FKanal: TSayi4;

    FKafaSayisi: TSayi4;
    FSilindirSayisi: TSayi4;
    FIzBasinaSektorSayisi: TSayi4;
    FToplamSektorSayisi: TSayi4;

    FOzellikler: TSayi4;

    FOku: TFDAOkuYaz;
    FYaz: TFDAOkuYaz;

    constructor Create; override;
  end;

type
  TAgVeriGonder = procedure(AEthernetPaket: PEthernetPaket; AVeriUzunlugu: TSayi4);
  TAgVeriAl = function(ABellek: Isaretci): TSayi4;

type
  { ağ aygıtı }
  PAgAygiti = ^TAgAygiti;
  TAgAygiti = class(TTemelAygit)
  public
    FPCI: TPCI;
    FVeriGonder: TAgVeriGonder;
    FVeriAl: TAgVeriAl;
    constructor Create; override;
    destructor Destroy; override;
    property SiraNo: TISayi4 read FSiraNo write FSiraNo;
  end;

implementation

uses aygityonetimi;

{==============================================================================
  temel aygıt oluşturma işlevlerini gerçekleştirir
 ==============================================================================}
constructor TTemelAygit.Create;
begin

  FSiraNo := GAygitlar.SiraNoAl;
  FKimlik := FSiraNo;

  FYuklendi := False;
  FAktif := False;
end;

{==============================================================================
  Fiziksel Depolama Aygıtı oluşturma işlevlerini gerçekleştirir
 ==============================================================================}
constructor TFDAygiti.Create;
begin

  inherited Create;
end;

{==============================================================================
  ağ aygıtı oluşturma işlevlerini gerçekleştirir
 ==============================================================================}
constructor TAgAygiti.Create;
begin

  inherited Create;

  FPCI := nil;

  FVeriGonder := nil;
  FVeriAl := nil;
end;

{==============================================================================
  ağ aygıtı yok etme işlevlerini gerçekleştirir
 ==============================================================================}
destructor TAgAygiti.Destroy;
begin

  inherited Destroy;
end;

end.
