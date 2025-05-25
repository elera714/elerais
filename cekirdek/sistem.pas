{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: sistem.pas
  Dosya ��levi: sistem y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 25/05/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit sistem;

interface

uses paylasim;

procedure YenidenBaslat;
procedure BilgisayariKapat;
procedure SistemAyarlariniKaydet;

implementation

uses port, dosya;

procedure YenidenBaslat;
var
  B1: TSayi1;
begin

  // �ncelikle sistem ayarlar�n� kaydet
  SistemAyarlariniKaydet;

  repeat

    B1 := PortAl1($64);
    if((B1 and 1) = 0) then PortAl1($60);     // = 1 = veri mevcut oldu�u m�ddet�e porttan veriyi al
  until ((B1 and 2) = 0);                     // = 0 = veri yaz�labilir olmad��� m�ddet�e tekrarla

  // porta veriyi yaz - yeniden ba�lat
  PortYaz1($64, $FE);

  asm @@1: hlt; jmp @@1; end;
end;

procedure BilgisayariKapat;
begin

  // �ncelikle sistem ayarlar�n� kaydet
  SistemAyarlariniKaydet;

  asm cli; hlt; end;
end;

procedure SistemAyarlariniKaydet;
var
  DosyaAdi: string;
begin

  DosyaAdi := 'elera.ini';
  IzKaydiOlustur(DosyaAdi, 'sistem-ad�=' + SistemAdi);
end;

end.
