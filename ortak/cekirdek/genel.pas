{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: genel.pas
  Dosya İşlevi: sistem genelinde kullanılan sabit, değişken ve yapıları içerir

  Güncelleme Tarihi: 23/05/2025

 ==============================================================================}
{$mode objfpc}
unit genel;

interface

uses gercekbellek, src_vesa20, src_ps2, paylasim, olayyonetim, gorselnesne, gn_masaustu, dns;

var
  GFareSurucusu: TFareSurucusu;
  GOlayYonetim: TOlayYonetim;
  GIslemciBilgisi: TIslemciBilgisi;
  GAktifMasaustu: PMasaustu;
  GAktifMenu: PGorselNesne;             // PMenu veya PAcilirMenu

  // 24 x 24 sistemler. yukleyici.pas dosyasından yükleme işlemi yapılır
  GSistemResimler,
  GSistemResimler2: TGoruntuYapi;

  // fare ile sağ veya sol tuş ile basılan son görsel nesne
  // TGucDugme ve benzeri görsel nesnelerin normal duruma (basılı olmayan) gelmesi için
  GFareIleBasilanSonGN: PGorselNesne = nil;

  GDNSBaglantilari: array[0..USTSINIR_DNSBAGLANTI - 1] of PDNS;
  GMasaustuListesi: array[0..USTSINIR_MASAUSTU - 1] of PMasaustu = (nil, nil, nil, nil);

implementation

end.
