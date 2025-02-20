{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: sistem.pas
  Dosya İşlevi: sistem yönetim işlevlerini içerir

  Güncelleme Tarihi: 19/02/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit sistem;

interface

uses paylasim;

procedure YenidenBaslat;
procedure BilgisayariKapat;

implementation

uses port;

procedure YenidenBaslat;
var
  B1: TSayi1;
begin

  repeat

    B1 := PortAl1($64);
    if((B1 and 1) = 0) then PortAl1($60);     // = 1 = veri mevcut olduğu müddetçe porttan veriyi al
  until ((B1 and 2) = 0);                     // = 0 = veri yazılabilir olmadığı müddetçe tekrarla

  // porta veriyi yaz - yeniden başlat
  PortYaz1($64, $FE);

  asm @@1: hlt; jmp @@1; end;
end;

procedure BilgisayariKapat;
begin

  asm cli; hlt; end;
end;

end.
