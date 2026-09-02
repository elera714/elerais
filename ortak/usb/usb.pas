{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: usb.pas
  Dosya Ýþlevi: usb yönetim iþlevlerini içerir

  Güncelleme Tarihi: 02/09/2026

 ==============================================================================}
{$mode objfpc}
unit usb;

interface

uses paylasim;

const
  // usb aygýt taným kodlarý
  USB_KONTROLCU_UHCI  = $0C0300;
  USB_KONTROLCU_OHCI  = $0C0310;
  USB_KONTROLCU_EHCI  = $0C0320;      // USB 2.0
  USB_KONTROLCU_XHCI  = $0C0330;      // USB 3.0
  USB_KONTROLCU       = $0C0380;
  USB_AYGIT           = $0C03FE;      // sadece aygýt. (kontrol edici deðil)

type
  // istek - request
  PUSBAyar = ^TUSBAyar;
  TUSBAyar = packed record
    IstekTipi,
    Istek: TSayi1;
    Deger,
    SiraNo,
    Uzunluk: TSayi2;
  end;

type
  // tanýmlayýcý - deviceDescriptor
  PUSBAygitTanim = ^TUSBAygitTanim;
  TUSBAygitTanim = packed record
    Uzunluk,
    TanimTipi: TSayi1;
    USBSurum: TSayi2;
    AygitSinif,
    AygitAltSinif,
    AygitProtokol,
    AzamiPaketUzunlugu: Byte;
    SaticiKimlik,             // vendor
    UrunKimlik,               // product
    AygitSurum: TSayi2;
    Uretici,                  // manufacture
    UrunNumarasi,
    SeriNo,
    AyarSayisi: TSayi1;       // config num
  end;

type
  TUSB = class
  public
    constructor Create;
  end;

var
  GUSB: TUSB;

implementation

uses pci, ohci, uhci, ehci;

{==============================================================================
  tüm usb aygýtlarýnýn ana yüklme iþlevlerinin içerir
 ==============================================================================}
constructor TUSB.Create;
var
  USBOHCI: TUSBOHCI;
  PCIAygit: TPCI;
  SinifKod, i: TSayi4;
begin

  for i := 0 to GPCIAygitlar.ToplamAygit - 1 do
  begin

    PCIAygit := GPCIAygitlar.PCI[i];
    SinifKod := (PCIAygit.FSinifKod shr 8);
    case SinifKod of

      USB_KONTROLCU_UHCI: uhci.Yukle(PCIAygit);
      USB_KONTROLCU_OHCI: USBOHCI := TUSBOHCI.Create(PCIAygit);
      USB_KONTROLCU_EHCI: GEHCI := TEHCI.Create(PCIAygit);
    end;
  end;
end;

end.
