{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: pit.pas
  Dosya İşlevi: programlanabilir zamanlayıcı (programmable interval timer) işlevlerini içerir

  Güncelleme Tarihi: 21/09/2019

 ==============================================================================}
{$mode objfpc}
unit pit;

interface

uses paylasim, port;

procedure ZamanlayiciFrekansiniDegistir(AFrekans: TSayi4);

implementation

{==============================================================================
  zamanlayıcının saniyedeki vuruş sayısını değiştirir
 ==============================================================================}
procedure ZamanlayiciFrekansiniDegistir(AFrekans: TSayi4);
var
  i: TSayi4;
begin

  i := (1193180 div AFrekans);

  PortYaz1($43, $34);
  PortYaz1($40, (i and $FF));         // LSB
  PortYaz1($40, (i shr 8) and $FF);   // MSB
end;

end.
