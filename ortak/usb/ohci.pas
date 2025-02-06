{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: ohci.pas
  Dosya Ýþlevi: usb ohci yönetim iþlevlerini içerir

  Güncelleme Tarihi: 30/01/2025

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
  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '  -> USB:OHCI kontrol aygýtý bulundu...', []);
end;

procedure Kontrol1;
begin

  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'Deðer: %d', [Yuklendi]);
end;

end.
