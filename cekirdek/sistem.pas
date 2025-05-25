{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: sistem.pas
  Dosya Ýþlevi: sistem yönetim iþlevlerini içerir

  Güncelleme Tarihi: 25/05/2025

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

  // öncelikle sistem ayarlarýný kaydet
  SistemAyarlariniKaydet;

  repeat

    B1 := PortAl1($64);
    if((B1 and 1) = 0) then PortAl1($60);     // = 1 = veri mevcut olduðu müddetçe porttan veriyi al
  until ((B1 and 2) = 0);                     // = 0 = veri yazýlabilir olmadýðý müddetçe tekrarla

  // porta veriyi yaz - yeniden baþlat
  PortYaz1($64, $FE);

  asm @@1: hlt; jmp @@1; end;
end;

procedure BilgisayariKapat;
begin

  // öncelikle sistem ayarlarýný kaydet
  SistemAyarlariniKaydet;

  asm cli; hlt; end;
end;

procedure SistemAyarlariniKaydet;
var
  DosyaAdi: string;
begin

  DosyaAdi := 'elera.ini';
  IzKaydiOlustur(DosyaAdi, 'sistem-adý=' + SistemAdi);
end;

end.
