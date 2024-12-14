{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: usb.pas
  Dosya Ýþlevi: usb yönetim iþlevlerini içerir

  Güncelleme Tarihi: 26/09/2019

 ==============================================================================}
{$mode objfpc}
unit usb;

interface

uses paylasim;

const
  USB_KONTROLCU_UHCI  = $0C0300;
  USB_KONTROLCU_OHCI  = $0C0310;
  USB_KONTROLCU_EHCI  = $0C0320;      // USB 2.0
  USB_KONTROLCU_XHCI  = $0C0330;      // USB 3.0
  USB_KONTROLCU       = $0C0380;
  USB_AYGIT           = $0C03FE;      // sadece aygýt. (kontrol edici deðil)

type
  PUSBAyar = ^TUSBAyar;
  TUSBAyar = packed record
    IstekTipi,
    Istek: TSayi1;
    Deger,
    SiraNo,
    Uzunluk: TSayi2;
  end;

type
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

procedure Yukle;
procedure USBTest1;

implementation

uses pci, ohci, uhci, ehci, sistemmesaj;

procedure Yukle;
var
  p: PPCI;
  _SinifKod, i: TSayi4;
begin

  for i := 0 to ToplamPCIAygitSayisi - 1 do
  begin

    p := PCIAygitBellekAdresi[i];
    _SinifKod := (p^.SinifKod shr 8);
    case _SinifKod of

      USB_KONTROLCU_UHCI: uhci.Yukle(p);
      USB_KONTROLCU_OHCI: ohci.Yukle(p);
      USB_KONTROLCU_EHCI: ehci.Yukle(p);
    end;
  end;
end;

procedure USBTest1;
var
  USBAygitTanim: PUSBAygitTanim;
  USBAyar: PUSBAyar;
begin

  USBAygitTanim := PUSBAygitTanim(62 * 1024 * 1024);
  FillByte(USBAygitTanim, 18, 0);

  USBAyar := PUSBAyar(63 * 1024 * 1024);
  FillByte(USBAyar, 18, 0);

  USBAyar^.IstekTipi := $80;
  USBAyar^.Istek := 6;
  USBAyar^.Deger := 1 shl 8;
  USBAyar^.SiraNo := 0;
  USBAyar^.Uzunluk := 18;
end;

end.
