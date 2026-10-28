{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: ip.pas
  Dosya İşlevi: ip tutanak (protokol) yönetim işlevlerini içerir

  Güncelleme Tarihi: 28/10/2026

 ==============================================================================}
{$mode objfpc}
unit ip;

interface

uses paylasim;

type
  TIP = class
  public
    FBagNesne: TObject;
    FHedefMACAdres: TMACAdres;
    // ABagNesne nesnesi ICMPv4 tutanağı için TAgBaglantisi nesnesini
    // diğer tutanaklar için TBaglanti nesnesini temsil eder
    constructor Create(ABagNesne: TObject; AHedefMACAdres: TMACAdres); virtual;
    procedure Gonder(AVeri: Isaretci; AVeriU: TSayi4); virtual; abstract;
  end;

implementation

{==============================================================================
  ip tutanak (protokol) ana yükleme işlevlerini içerir
 ==============================================================================}
constructor TIP.Create(ABagNesne: TObject; AHedefMACAdres: TMACAdres);
begin

  FBagNesne := ABagNesne;
  FHedefMACAdres := AHedefMACAdres;
end;

end.
