{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: ehci.pas
  Dosya Ýþlevi: usb ehci yönetim iþlevlerini içerir

  Güncelleme Tarihi: 06/09/2026

 ==============================================================================}
{$mode objfpc}
unit ehci;

interface

uses pci, paylasim;

type
  TEHCI = class
  public
    constructor Create(APCI: TPCI);
    procedure EHCIAygitBilgileriniGoster;
  end;

var
  GEHCI: TEHCI;

implementation

uses sistemmesaj;

var
  EHCIAygit: TPCI;

constructor TEHCI.Create(APCI: TPCI);
begin

  EHCIAygit := APCI;
  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '  -> USB:EHCI kontrol aygýtý bulundu...', []);
end;

procedure TEHCI.EHCIAygitBilgileriniGoster;
var
  TemelAdres, StructuralParams,
  CapabilityParams, OperationalReg,
  Deger4: TSayi4;
  CapLength: TSayi1;
begin

  if not(EHCIAygit = nil) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'USB-EHCI Genel Bilgiler:', []);

    TemelAdres := (GPCIAygitlar.Oku4(EHCIAygit.FYol, EHCIAygit.FAygit, EHCIAygit.FIslev, $10)
      and $FFFFFF00);
    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'USB Ana Adres: $%.8x', [TemelAdres]);

    // _CapLength - Capability Registers Length
    CapLength := PByte(TemelAdres + 00)^;
    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'CAPLENGTH - Capability Registers Length: $%.8x', [CapLength]);

    // HCSPARAMS - Structural Parameters
    StructuralParams := PSayi4(TemelAdres + 04)^;
    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'HCSPARAMS - Structural Parameters: $%.8x', [StructuralParams]);

    // HCCPARAMS - Capability Parameters
    CapabilityParams := PSayi4(TemelAdres + 08)^;
    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'HCCPARAMS - Capability Parameters: $%.8x', [CapabilityParams]);

    OperationalReg := TemelAdres + CapLength;

    // USBCMD - USB Command Register
    Deger4 := PSayi4(OperationalReg + 00)^;
    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'USBCMD - USB Command Register: $%.8x', [Deger4]);

    // USBSTS - USB Status Register
    Deger4 := PSayi4(OperationalReg + 04)^;
    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'USBSTS - USB Status Register: $%.8x', [Deger4]);

    // USBINTR - USB Interrupt Enable Register
    Deger4 := PSayi4(OperationalReg + 08)^;
    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'USBINTR - USB Interrupt Enable Register: $%.8x', [Deger4]);
  end;
end;

end.
