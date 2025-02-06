{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: ohci.pas
  Dosya ��levi: usb ohci y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 30/01/2025

 ==============================================================================}
{$mode objfpc}
unit ohci;

interface

uses paylasim;

procedure Yukle(APCI: PPCI);
procedure Kontrol1;

implementation

uses sistemmesaj;

var
  Yuklendi: TSayi4 = 0;

procedure Yukle(APCI: PPCI);
begin

  Yuklendi := 1;
  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '  -> USB:OHCI kontrol ayg�t� bulundu...', []);
end;

procedure Kontrol1;
begin

  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'De�er: %d', [Yuklendi]);
end;

end.
