{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: cmos.pas
  Dosya İşlevi: CMOS yönetim işlevlerini içerir

  Güncelleme Tarihi: 15/09/2019

 ==============================================================================}
{$mode objfpc}
unit cmos;
 
interface

uses paylasim;

procedure SaatAl(out Saat, Dakika, Saniye: TSayi1);
procedure TarihAl(out Gun, Ay, Yil, HaftaninGunu: TSayi2);

implementation

uses port, donusum;

{==============================================================================
  CMOS'tan saat bilgisini alır
 ==============================================================================}
procedure SaatAl(out Saat, Dakika, Saniye: TSayi1);
var
  i: TSayi1;
begin

  // kesmeleri durdur
  cli;

  // saat değerini al
  PortYaz1($70, 4);
  i := PortAl1($71);
  Saat := BCDyiSayi10aCevir(i);

  // dakika değerini al
  PortYaz1($70, 2);
  i := PortAl1($71);
  Dakika := BCDyiSayi10aCevir(i);

  // saniye değerini al
  PortYaz1($70, 0);
  i := PortAl1($71);
  Saniye := BCDyiSayi10aCevir(i);

  // kesmeleri aktifleştir & çık
  sti;
end;

{==============================================================================
  CMOS'tan tarih bilgisini alır
 ==============================================================================}
procedure TarihAl(out Gun, Ay, Yil, HaftaninGunu: TSayi2);
var
  i: TSayi1;
begin

  // kesmeleri durdur
  cli;

  // gün değerini al
  PortYaz1($70, 7);
  i := PortAl1($71);
  Gun := BCDyiSayi10aCevir(i);

  // ay değerini al
  PortYaz1($70, 8);
  i := PortAl1($71);
  Ay := BCDyiSayi10aCevir(i);

  // yüzyıl değerini al
  PortYaz1($70, $32);
  i := PortAl1($71);
  Yil := BCDyiSayi10aCevir(i) * 100;

  // yıl değerini al
  PortYaz1($70, 9);
  i := PortAl1($71);
  Yil += BCDyiSayi10aCevir(i);

  // haftanın günü değerini al
  PortYaz1($70, 6);
  i := PortAl1($71);
  HaftaninGunu := i;

  // kesmeleri aktifleştir & çık
  sti;
end;

end.
