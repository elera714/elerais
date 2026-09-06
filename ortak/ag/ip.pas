{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: ip.pas
  Dosya İşlevi: ip tutanak (protokol) yönetim işlevlerini içerir

  Güncelleme Tarihi: 05/09/2026

 ==============================================================================}
{$mode objfpc}
unit ip;

interface

uses paylasim;

type
  TIP = class
  public
    FBaglanti: TObject;
    constructor Create(ABaglanti: TObject); virtual;
    procedure Gonder(AHedefMACAdres: TMACAdres; AVeri: Isaretci; AVeriU: TSayi4); virtual; abstract;
  end;

implementation

{==============================================================================
  ip tutanak (protokol) ana yükleme işlevlerini içerir
 ==============================================================================}
constructor TIP.Create(ABaglanti: TObject);
begin

  FBaglanti := ABaglanti;
end;

end.
