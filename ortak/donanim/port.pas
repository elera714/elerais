{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: port.pas
  Dosya İşlevi: donanım port yazım / alım işlevlerini içerir

  Güncelleme Tarihi: 15/09/2019

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit port;

interface

uses paylasim;

procedure sti;
procedure cli;
function PortAl1(APort: TSayi2): TSayi1;
function PortAl2(APort: TSayi2): TSayi2;
function PortAl4(APort: TSayi2): TSayi4;
procedure PortYaz1(APort: TSayi2; ADeger: TSayi1);
procedure PortYaz2(APort: TSayi2; ADeger: TSayi2);
procedure PortYaz4(APort: Word; ADeger: TSayi4);

implementation

// donanım kesmelerini aktifleştirir ((s)et)
procedure sti; nostackframe; assembler;
asm
  sti
end;

// donanım kesmelerini pasifleştirir ((c)lear)
procedure cli; nostackframe; assembler;
asm
  cli
end;

function PortAl1(APort: TSayi2): TSayi1; nostackframe; assembler;
asm
  mov dx,APort
  in	al,dx
end;

function PortAl2(APort: TSayi2): TSayi2; nostackframe; assembler;
asm
  mov dx,APort
  in	ax,dx
end;

function PortAl4(APort: TSayi2): TSayi4; nostackframe; assembler;
asm
  mov dx,APort
  in	eax,dx
end;

// stdcall çağrısında: 1. değişken = ax, 2. değişken = dx
procedure PortYaz1(APort: TSayi2; ADeger: TSayi1); nostackframe; assembler;
asm
  xchg  ax,dx
  out   dx,al
end;

// stdcall çağrısında: 1. değişken = ax, 2. değişken = dx
procedure PortYaz2(APort: TSayi2; ADeger: TSayi2); nostackframe; assembler;
asm
  xchg  ax,dx
  out   dx,ax
end;

// stdcall çağrısında: 1. değişken = ax, 2. değişken = dx
procedure PortYaz4(APort: Word; ADeger: TSayi4); nostackframe; assembler;
asm
  xchg  eax,edx
  out   dx,eax
end;

end.
