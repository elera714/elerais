{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: ip.pas
  Dosya İşlevi: ip tutanak (protokol) yönetim işlevlerini içerir

  Güncelleme Tarihi: 24/09/2026

 ==============================================================================}
{$mode objfpc}
unit ip;

interface

uses paylasim;

type
  TIP = class
  public
    FBaglanti: TObject;
    FHedefMACAdres: TMACAdres;
    constructor Create(ABaglanti: TObject; AHedefMACAdres: TMACAdres); virtual;
    procedure Gonder(AVeri: Isaretci; AVeriU: TSayi4); virtual; abstract;
  end;

implementation

{==============================================================================
  ip tutanak (protokol) ana yükleme işlevlerini içerir
 ==============================================================================}
constructor TIP.Create(ABaglanti: TObject; AHedefMACAdres: TMACAdres);
begin

  FBaglanti := ABaglanti;
  FHedefMACAdres := AHedefMACAdres;
end;

end.
