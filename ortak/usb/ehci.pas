{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: ehci.pas
  Dosya ��levi: usb ehci y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 30/01/2025

 ==============================================================================}
{$mode objfpc}
unit ehci;

interface

uses paylasim;

procedure Yukle(APCI: PPCI);
procedure EHCIAygitBilgileriniGoster;

implementation

uses sistemmesaj, pci;

var
  EHCIAygit: PPCI = nil;

procedure Yukle(APCI: PPCI);
begin

  EHCIAygit := APCI;
  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '  -> USB:EHCI kontrol ayg�t� bulundu...', []);
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

    _TemelAdres := (PCIOku4(EHCIAygit^.Yol, EHCIAygit^.Aygit, EHCIAygit^.Islev, $10)
      and $FFFFFF00);
    SISTEM_MESAJ_S16(mtBilgi, RENK_SIYAH, 'USB Ana Adres: ', _TemelAdres, 8);

    // _CapLength - Capability Registers Length
    _CapLength := PByte(_TemelAdres + 00)^;
    SISTEM_MESAJ_S16(mtBilgi, RENK_SIYAH, 'CAPLENGTH - Capability Registers Length: ', _CapLength, 8);

    // HCSPARAMS - Structural Parameters
    _StructuralParams := PSayi4(_TemelAdres + 04)^;
    SISTEM_MESAJ_S16(mtBilgi, RENK_SIYAH, 'HCSPARAMS - Structural Parameters: ', _StructuralParams, 8);

    // HCCPARAMS - Capability Parameters
    _CapabilityParams := PSayi4(_TemelAdres + 08)^;
    SISTEM_MESAJ_S16(mtBilgi, RENK_SIYAH, 'HCCPARAMS - Capability Parameters: ', _CapabilityParams, 8);

    _OperationalReg := _TemelAdres + _CapLength;

    // USBCMD - USB Command Register
    _Deger4 := PSayi4(_OperationalReg + 00)^;
    SISTEM_MESAJ_S16(mtBilgi, RENK_SIYAH, 'USBCMD - USB Command Register: ', _Deger4, 8);

    // USBSTS - USB Status Register
    _Deger4 := PSayi4(_OperationalReg + 04)^;
    SISTEM_MESAJ_S16(mtBilgi, RENK_SIYAH, 'USBSTS - USB Status Register: ', _Deger4, 8);

    // USBINTR - USB Interrupt Enable Register
    _Deger4 := PSayi4(_OperationalReg + 08)^;
    SISTEM_MESAJ_S16(mtBilgi, RENK_SIYAH, 'USBINTR - USB Interrupt Enable Register: ', _Deger4, 8);
  end;
end;

end.
