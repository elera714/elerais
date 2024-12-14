{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: genel.pas
  Dosya İşlevi: sistem genelinde kullanılan sabit, değişken ve yapıları içerir

  Güncelleme Tarihi: 10/06/2020

 ==============================================================================}
{$mode objfpc}
unit genel;

interface

uses gercekbellek, src_vesa20, src_ps2, gorev, zamanlayici, paylasim, olayyonetim, gorselnesne,
  sistemmesaj, gn_masaustu, iletisim, n_yazilistesi, n_sayilistesi, dns;

const
  USTSINIR_YAZILISTESI = 128;    // 4096 byte / 32 byte = 128 adet liste
  USTSINIR_SAYILISTESI = 128;    // 4096 byte / 32 byte = 128 adet liste

var
  GGercekBellek: TGercekBellek;
  GEkranKartSurucusu: TEkranKartSurucusu;
  GFareSurucusu: TFareSurucusu;
  GZamanlayici: TZamanlayici;
  GSistemMesaj: TSistemMesaj;
  GOlayYonetim: TOlayYonetim;
  GIslemciBilgisi: TIslemciBilgisi;
  GAktifMasaustu: PMasaustu;
  GAktifMenu: PGorselNesne;             // PMenu veya PAcilirMenu
  GBaglanti: PBaglanti;                 // dhcp.pas dosyası tarafından kullanılmaktadır. (iptal edilecek)

  // 24 x 24 sistemler. yukleyici.pas dosyasından yükleme işlemi yapılır
  GSistemResimler: TGoruntuYapi;

  // fare ile sağ veya sol tuş ile basılan son görsel nesne
  // TGucDugme ve benzeri görsel nesnelerin normal duruma (basılı olmayan) gelmesi için
  GFareIleBasilanSonGN: PGorselNesne = nil;

  GorevListesi: array[1..USTSINIR_GOREVSAYISI] of PGorev;
  GorselNesneListesi: array[1..USTSINIR_GORSELNESNE] of PGorselNesne;
  AgIletisimListesi: array[1..USTSINIR_AGILETISIM] of PBaglanti;
  DNSListesi: array[1..USTSINIR_DNSBAGLANTI] of PDNS;
  MasaustuListesi: array[1..USTSINIR_MASAUSTU] of PMasaustu = (nil, nil, nil, nil);

  // sistem içerisinde kullanılacak görsel olmayan listeler
  GYaziListesi: array[1..USTSINIR_YAZILISTESI] of PYaziListesi;
  GSayiListesi: array[1..USTSINIR_SAYILISTESI] of PSayiListesi;

procedure ListeleriIlkDegerlerleYukle;

implementation

{==============================================================================
  çalıştırılacak işlemlerin ana yükleme işlevlerini içerir
 ==============================================================================}
procedure ListeleriIlkDegerlerleYukle;
var
  YL: PYaziListesi;
  SL: PSayiListesi;
  i: TISayi4;
begin

  // 1. görsel olmayan yazı listesi için bellekte yer ayır
  YL := GGercekBellek.Ayir(Align(SizeOf(TYaziListesi), 16) * USTSINIR_YAZILISTESI);

  // bellek girişlerini nesne yapı girişleriyle eşleştir
  for i := 1 to USTSINIR_YAZILISTESI do
  begin

    GYaziListesi[i] := YL;

    // nesneyi kullanılabilir olarak işaretle
    YL^.NesneKullanilabilir := True;
    YL^.Tanimlayici := i;

    Inc(YL);
  end;

  // 2. görsel olmayan sayı listesi için bellekte yer ayır
  SL := GGercekBellek.Ayir(Align(SizeOf(TSayiListesi), 16) * USTSINIR_SAYILISTESI);

  // bellek girişlerini nesne yapı girişleriyle eşleştir
  for i := 1 to USTSINIR_SAYILISTESI do
  begin

    GSayiListesi[i] := SL;

    // nesneyi kullanılabilir olarak işaretle
    SL^.NesneKullanilabilir := True;
    SL^.Tanimlayici := i;

    Inc(SL);
  end;
end;

end.
