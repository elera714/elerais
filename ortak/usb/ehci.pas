{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: ehci.pas
  Dosya Ýþlevi: usb ehci yönetim iþlevlerini içerir

  Güncelleme Tarihi: 10/05/2025

 ==============================================================================}
{$mode objfpc}
unit ehci;

interface

uses pci, paylasim;

procedure Yukle(APCI: PPCI);
procedure EHCIAygitBilgileriniGoster;

implementation

uses sistemmesaj;

var
  EHCIAygit: PPCI = nil;

procedure Yukle(APCI: PPCI);
begin

  EHCIAygit := APCI;
  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '  -> USB:EHCI kontrol aygýtý bulundu...', []);
end;

procedure EHCIAygitBilgileriniGoster;
var
  _TemelAdres, _StructuralParams, _CapabilityParams,
  _OperationalReg, _Deger4: TSayi4;
  _CapLength: TSayi1;
begin

  if not(EHCIAygit = nil) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'USB-EHCI Genel Bilgiler:', []);

    _TemelAdres := (PCIAygiti0.Oku4(EHCIAygit^.Yol, EHCIAygit^.Aygit, EHCIAygit^.Islev, $10)
      and $FFFFFF00);
    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'USB Ana Adres: $%.8x', [_TemelAdres]);

    // _CapLength - Capability Registers Length
    _CapLength := PByte(_TemelAdres + 00)^;
    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'CAPLENGTH - Capability Registers Length: $%.8x', [_CapLength]);

    // HCSPARAMS - Structural Parameters
    _StructuralParams := PSayi4(_TemelAdres + 04)^;
    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'HCSPARAMS - Structural Parameters: $%.8x', [_StructuralParams]);

    // HCCPARAMS - Capability Parameters
    _CapabilityParams := PSayi4(_TemelAdres + 08)^;
    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'HCCPARAMS - Capability Parameters: $%.8x', [_CapabilityParams]);

    _OperationalReg := _TemelAdres + _CapLength;

    // USBCMD - USB Command Register
    _Deger4 := PSayi4(_OperationalReg + 00)^;
    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'USBCMD - USB Command Register: $%.8x', [_Deger4]);

    // USBSTS - USB Status Register
    _Deger4 := PSayi4(_OperationalReg + 04)^;
    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'USBSTS - USB Status Register: $%.8x', [_Deger4]);

    // USBINTR - USB Interrupt Enable Register
    _Deger4 := PSayi4(_OperationalReg + 08)^;
    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'USBINTR - USB Interrupt Enable Register: $%.8x', [_Deger4]);
  end;
end;

end.
