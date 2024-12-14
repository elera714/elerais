{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: ohci.pas
  Dosya Ýþlevi: usb ohci yönetim iþlevlerini içerir

  Güncelleme Tarihi: 03/09/2024

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
  SISTEM_MESAJ(RENK_ZEYTINYESILI, '  -> USB:OHCI kontrol aygýtý bulundu...', []);
end;

procedure Kontrol1;
begin

  SISTEM_MESAJ(RENK_ZEYTINYESILI, 'Deðer: %d', [Yuklendi]);
end;

end.
