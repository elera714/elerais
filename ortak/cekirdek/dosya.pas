{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: dosya.pas
  Dosya İşlevi: dosya (file) yönetim işlevlerini içerir

  Güncelleme Tarihi: 30/01/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit dosya;

interface

uses paylasim, gorev, mdepolama;

// tüm dosya işlevleri için gereken yapı
type
  TDosyaDurumu = (ddKapali, ddOkumaIcinAcik, ddYazmaIcinAcik);

type
  PDosya = ^TDosya;
  TDosya = class
  public
    DST: TSayi4;                      // dosya sistem tipi
    Kimlik: TKimlik;                  // dosya işlemi kimliği
    DosyaDurumu: TDosyaDurumu;        // dosyanın durumu

    // dizin / dosya girişinin Tek Sektörlük Içeriği. (işlevler arası veri alışverişi için)
    TSI: Isaretci;

    MD: TMDNesne;
    Klasor, DosyaAdi: string;

    KlasorDerinlik: TISayi4;          // 0 = kök dizin, 1 = alt dizin, 2 = alt dizinin alt dizini ...

    // işlevler için kullanılacak genel bellek işaretçileri
    BellekSHT,                        // sektör harita tablosunu (fat) yüklemek için kullanılacak
    Bellek2: Isaretci;
    BellekSHTDurum,
    Durum2: Boolean;                  // bellek durumlarını tutan değişkenler (genel kullanım için)

    Gorev: PGorev;            // dosya işlemini gerçekleştiren görev

    { SektorIcıKonum değeri 512 byte'lık sektörün içerisinde 0,32,64 olarak artış gösteren imleç değeridir.
      512 olduğunda bir sonraki sektör yüklenir.
      KayitSN değeri yok edilerek SektorIcıKonum değeri ikame edilecek }
    SektorIciKonum,

    SektorKumeNo: TISayi4;            // fat12 / fat16 kök dizin için sektör no, diğer durumlarda küme no
    ZincirNo: TSayi4;

    // silinmiş ilk girdi değişkenleri
    SilinenKumeNo,
    SilinenZincirNo,
    SilinenKayitSN: TISayi4;

    Aranan: string;

    constructor Create(AKimlikNo: TISayi4; FDST: TSayi4); virtual;

    procedure Append; virtual; abstract;
    function CreateDir: Boolean; virtual; abstract;
    procedure Read(AHedefBellek: Isaretci); virtual; abstract;
    procedure ReWrite; virtual; abstract;
  end;

implementation

constructor TDosya.Create(AKimlikNo: TISayi4; FDST: TSayi4);
begin

  // ilk değer atamalarını gerçekleştir
  DST := FDST;
  Kimlik := AKimlikNo;
  DosyaDurumu := ddKapali;
  TSI := GetMem(512);
end;

end.
