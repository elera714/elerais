{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: genel.pas
  Dosya İşlevi: sistem genelinde kullanılan sabit, değişken ve yapıları içerir

  Güncelleme Tarihi: 26/02/2025

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
  GSistemResimler,
  GSistemResimler2: TGoruntuYapi;

  // fare ile sağ veya sol tuş ile basılan son görsel nesne
  // TGucDugme ve benzeri görsel nesnelerin normal duruma (basılı olmayan) gelmesi için
  GFareIleBasilanSonGN: PGorselNesne = nil;

  GGorevler: TGorevler;

  GGorselNesneListesi: array[0..USTSINIR_GORSELNESNE - 1] of PGorselNesne;
  GAgIletisimListesi: array[0..USTSINIR_AGILETISIM - 1] of PBaglanti;
  GDNSBaglantilari: array[0..USTSINIR_DNSBAGLANTI - 1] of PDNS;
  GMasaustuListesi: array[0..USTSINIR_MASAUSTU - 1] of PMasaustu = (nil, nil, nil, nil);

  // sistem içerisinde kullanılacak görsel olmayan listeler
  GYaziListesi: array[0..USTSINIR_YAZILISTESI - 1] of PYaziListesi;
  GSayiListesi: array[0..USTSINIR_SAYILISTESI - 1] of PSayiListesi;

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
  YL := GetMem(Align(SizeOf(TYaziListesi), 16) * USTSINIR_YAZILISTESI);

  // bellek girişlerini nesne yapı girişleriyle eşleştir
  for i := 0 to USTSINIR_YAZILISTESI - 1 do
  begin

    GYaziListesi[i] := YL;

    // nesneyi kullanılabilir olarak işaretle
    YL^.NesneKullanilabilir := True;
    YL^.Tanimlayici := i;

    Inc(YL);
  end;

  // 2. görsel olmayan sayı listesi için bellekte yer ayır
  SL := GetMem(Align(SizeOf(TSayiListesi), 16) * USTSINIR_SAYILISTESI);

  // bellek girişlerini nesne yapı girişleriyle eşleştir
  for i := 0 to USTSINIR_SAYILISTESI - 1 do
  begin

    GSayiListesi[i] := SL;

    // nesneyi kullanılabilir olarak işaretle
    SL^.NesneKullanilabilir := True;
    SL^.Tanimlayici := i;

    Inc(SL);
  end;
end;

end.
