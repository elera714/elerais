{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: idt.pas
  Dosya ��levi: kesme servis rutinlerini (isr) i�erir

  G�ncelleme Tarihi: 01/01/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit idt;
 
interface

uses paylasim;

const
  USTSINIR_IDT = $35;

type
  PYazmaclar0 = ^TYazmaclar0;
  TYazmaclar0 = packed record
    DS, ES, SS, FS, GS,
    EDI, ESI, EBP, ESP, EBX, EDX, ECX, EAX: TSayi4;
    ISRNo, EIP, CS, EFLAGS, OrjESP: TSayi4;
  end;

type
  PYazmaclar1 = ^TYazmaclar1;
  TYazmaclar1 = packed record
    DS, ES, SS, FS, GS,
    EDI, ESI, EBP, ESP, EBX, EDX, ECX, EAX: TSayi4;
    ISRNo, HataKodu, EIP, CS, EFLAGS, OrjESP: TSayi4;
  end;

type
  PIDTGirdisi = ^TIDTGirdisi;
  TIDTGirdisi = packed record
    BaslangicAdresi00_15: TSayi2;
    Secici: TSayi2;
    Sifir: TSayi1;
    Bayrak: TSayi1;
    BaslangicAdresi16_31: TSayi2;
  end;

var
  IDTYazmac: TIDTYazmac;
  IDTGirdiListesi: array[0..$34] of TIDTGirdisi;

procedure Yukle;
procedure KesmeGirisiBelirle(AGirdiNo: TSayi4; ABaslangicAdresi: Isaretci;
  ASecici: TSayi2; ABayrak: TSayi1);
procedure KesmeIslevi00;
procedure KesmeIslevi01;
procedure KesmeIslevi02;
procedure KesmeIslevi03;
procedure KesmeIslevi04;
procedure KesmeIslevi05;
procedure KesmeIslevi06;
procedure KesmeIslevi07;
procedure KesmeIslevi08;
procedure KesmeIslevi09;
procedure KesmeIslevi0A;
procedure KesmeIslevi0B;
procedure KesmeIslevi0C;
procedure KesmeIslevi0D;
procedure KesmeIslevi0E;
procedure KesmeIslevi0F;
procedure KesmeIslevi10;
procedure KesmeIslevi11;
procedure KesmeIslevi12;
procedure KesmeIslevi13;
procedure KesmeIslevi14;
procedure KesmeIslevi15;
procedure KesmeIslevi16;
procedure KesmeIslevi17;
procedure KesmeIslevi18;
procedure KesmeIslevi19;
procedure KesmeIslevi1A;
procedure KesmeIslevi1B;
procedure KesmeIslevi1C;
procedure KesmeIslevi1D;
procedure KesmeIslevi1E;
procedure KesmeIslevi1F;
procedure KesmeIslevi30;
procedure KesmeIslevi31;
procedure KesmeIslevi32;
procedure KesmeIslevi33;
procedure YazmacGoruntuleHY(AYazmaclar0: PYazmaclar0);
procedure YazmacGoruntuleHV(AYazmaclar1: PYazmaclar1);

implementation

uses genel, pic, kesme34, gorev, yonetim, zamanlayici, sistemmesaj;

{==============================================================================
  kesme giri�lerini belirler ve IDTYazmac'� y�kler
 ==============================================================================}
procedure Yukle;
begin

  // IDTYazmac yazmac�n�n limit ve ilk giri� noktas�n� belirle
  IDTYazmac.Uzunluk := (SizeOf(TIDTGirdisi) * USTSINIR_IDT) - 1;    // uzunluk = uzunluk - 1
  IDTYazmac.Baslangic := TSayi4(@IDTGirdiListesi);                  // ba�lang�� adresi (32 bit)

  // istisnalar - exceptions
  // %10001110 = 1 = mevcut, 00 = DPL0, 0, 1 = 32 bit kod, 110 - kesme kap�s�
  KesmeGirisiBelirle($00, @KesmeIslevi00, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($01, @KesmeIslevi01, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($02, @KesmeIslevi02, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($03, @KesmeIslevi03, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($04, @KesmeIslevi04, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($05, @KesmeIslevi05, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($06, @KesmeIslevi06, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($07, @KesmeIslevi07, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($08, @KesmeIslevi08, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($09, @KesmeIslevi09, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($0A, @KesmeIslevi0A, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($0B, @KesmeIslevi0B, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($0C, @KesmeIslevi0C, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($0D, @KesmeIslevi0D, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($0E, @KesmeIslevi0E, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($0F, @KesmeIslevi0F, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($10, @KesmeIslevi10, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($11, @KesmeIslevi11, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($12, @KesmeIslevi12, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($13, @KesmeIslevi13, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($14, @KesmeIslevi14, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($15, @KesmeIslevi15, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($16, @KesmeIslevi16, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($17, @KesmeIslevi17, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($18, @KesmeIslevi18, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($19, @KesmeIslevi19, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($1A, @KesmeIslevi1A, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($1B, @KesmeIslevi1B, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($1C, @KesmeIslevi1C, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($1D, @KesmeIslevi1D, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($1E, @KesmeIslevi1E, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($1F, @KesmeIslevi1F, SECICI_SISTEM_KOD * 8, %10001110);

  // yaz�l�m kesmeleri
  KesmeGirisiBelirle($30, @KesmeIslevi30, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($31, @KesmeIslevi31, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($32, @KesmeIslevi32, SECICI_SISTEM_KOD * 8, %10001110);
  KesmeGirisiBelirle($33, @KesmeIslevi33, SECICI_SISTEM_KOD * 8, %10001110);

  // sistem ana kesmesi
  // %11101110 = 1 = mevcut, 11 = DPL3, 0, 1 = 32 bit kod, 110 - kesme kap�s�
  KesmeGirisiBelirle($34, @Kesme34CagriIslevleri, SECICI_CAGRI_KOD * 8, %11101110);

  // IDTYazmac'� y�kle
  asm
    lidt  [IDTYazmac]
  end;
end;

{==============================================================================
  IDT giri� noktalar�n� belirler
 ==============================================================================}
procedure KesmeGirisiBelirle(AGirdiNo: TSayi4; ABaslangicAdresi: Isaretci;
  ASecici: TSayi2; ABayrak: TSayi1);
var
  BaslangicAdresi: TSayi4;
begin
{
      +-----------------------------------------------------+
      |31                    16|15                        00|  bit de�erleri 00-31
      +------------------------+----------------------------+
      |   Se�ici (selector)    | BaslangicAdresi 15..00     |
      +------------------------+----------------------------+

      +------------------------------+---------+------+-----+
      |63                          48|47     43|    37|   32|
      +------------------------------+-+-+-+-+-+------+-----+
      |       Ba�lang��: 31-16       |P|DPL|0|D|110000|     |  bit de�erleri 32-63
      +------------------------------+-+-+-+-+|+------+--|--+
                        D = 1 = 32 bit kod  <-+          +-> kullan�lm�yor
}

  BaslangicAdresi := TSayi4(ABaslangicAdresi);

  // temel bellek adresi (ABaslangicAdresi) - IDT: 15..00
  IDTGirdiListesi[AGirdiNo].BaslangicAdresi00_15 := (BaslangicAdresi and $FFFF);

  // temel bellek adresi (ABaslangicAdresi) - IDT: 63..48
  IDTGirdiListesi[AGirdiNo].BaslangicAdresi16_31 := (BaslangicAdresi shr 16) and $FFFF;

  // se�ici - IDT: 31..16
  IDTGirdiListesi[AGirdiNo].Secici := ASecici;

  // 000 kullan�lm�yor - IDT: 39..32
  IDTGirdiListesi[AGirdiNo].Sifir := 0;

  // P, DPL, S, TYPE - IDT: 47..40
  IDTGirdiListesi[AGirdiNo].Bayrak := ABayrak;
end;

{==============================================================================
  i�sel kesmeler (exceptions) - int00..int1F
 ==============================================================================}

{==============================================================================
  KesmeIslevi00 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi00; nostackframe; assembler;

  // not : sistemin stabilizasyonu i�in ileride yeniden yaz�lacak
asm

  // t�m kesmeleri durdur
  cli

  // hata kodunu y���na at
  push  dword $00

  // t�m genel yazma�lar� y���na at
  pushad

  // segment yazma�lar�n� y���na at
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  // t�m bilgileri ekrana d�k
  mov eax,esp
  call  YazmacGoruntuleHY

// program� sonland�r
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov edx,$00
  mov eax,[esi+TGorev.FGorevKimlik]
  call TGorev.Sonlandir

  // EOI - kesme sonu, bir sonraki kesmeden devam et mesaj�
  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

  sti
  iretd

  mov eax,OtomatikGorevDegistir //SistemAnaKontrol
  jmp eax

  // saklanan ds yazmac�n� y���ndan al ve eski konumuna geri getir
  pop   eax
  mov   ds,ax
  mov   es,ax

  // es, ss, fs, gs yazmac� y���ndan al�n�yor
  add   esp,2 * 4

  // genel yazma�lar y���ndan al�n�yor
  popad

  // hata kodu y���ndan al�n�yor
  add   esp,4

  // kesmeleri aktifle�tir ve ��k
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi01 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi01; nostackframe; assembler;
asm
  cli
  push  dword $01
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi02 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi02; nostackframe; assembler;
asm
  cli
  push  dword $02
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi03 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi03; nostackframe; assembler;
asm
  cli
  push  dword $03
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi04 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi04; nostackframe; assembler;
asm
  cli
  push  dword $04
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi05 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi05; nostackframe; assembler;
asm
  cli
  push  dword $05
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi06 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi06; nostackframe; assembler;
asm
  cli
  push  dword $06
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

// program� sonland�r
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov edx,$06
  mov eax,[esi+TGorev.FGorevKimlik]
  call TGorev.Sonlandir

  // EOI - kesme sonu, bir sonraki kesmeden devam et mesaj�
  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

  sti
  iretd

@@loop:
  jmp @@loop

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi07 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi07; nostackframe; assembler;
asm

  cli
  pushad
  pushfd
  xor   eax,eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  //mov eax,esp
  //call  YazmacGoruntuleHY

  { TODO : yap�land�r�lacak }
  clts

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  popfd
  popad
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi08 - hata kodu d�nd�r�r (0)
 ==============================================================================}
procedure KesmeIslevi08; nostackframe; assembler;
asm
  cli
  push  dword $08
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHV

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,2 * 4     //IsrNum + ErrCode
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi09 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi09; nostackframe; assembler;
asm
  cli
  push  dword $09
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi0A - Invalid TSS - hata kodu d�nd�r�r
 ==============================================================================}
procedure KesmeIslevi0A; nostackframe; assembler;
asm
  cli
  push  dword $0A
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHV

// program� sonland�r
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov ecx,$0A
  mov edx,[esi+TGorev.FGorevKimlik]
  //mov edx,CalisanGorev
  mov eax,TGorev.Sonlandir
  call eax

  mov eax,SistemAnaKontrol
  jmp eax

  mov eax,esp
  call  YazmacGoruntuleHV

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,2 * 4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi0B - hata kodu d�nd�r�r
 ==============================================================================}
procedure KesmeIslevi0B; nostackframe; assembler;
asm
  cli
  push  dword $0B
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHV

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,2 * 4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi0C - Stack Exception - hata kodu d�nd�r�r
 ==============================================================================}
procedure KesmeIslevi0C; nostackframe; assembler;
asm
  cli
  push  dword $0C
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHV

// program� sonland�r
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov edx,$0C
  mov eax,[esi+TGorev.FGorevKimlik]
  call TGorev.Sonlandir

  // EOI - kesme sonu, bir sonraki kesmeden devam et mesaj�
  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

  sti
  iretd

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,2 * 4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi0D - genel koruma hatas� (General Protection Exception) - hata kodu d�nd�r�r
 ==============================================================================}
procedure KesmeIslevi0D; nostackframe; assembler;
asm
  cli

  push  dword $0D
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHV

// program� sonland�r
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov edx,$0D
  mov eax,[esi+TGorev.FGorevKimlik]
  call TGorev.Sonlandir

  // EOI - kesme sonu, bir sonraki kesmeden devam et mesaj�
  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

  sti
  iretd

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,2 * 4
  sti
  iretd
//end;
end;

{==============================================================================
  KesmeIslevi0E - hata kodu d�nd�r�r
 ==============================================================================}
procedure KesmeIslevi0E; nostackframe; assembler;
asm
  cli
  push  dword $0E
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHV

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,2 * 4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi0F - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi0F; nostackframe; assembler;
asm
  cli
  push  dword $0F
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi10 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi10; nostackframe; assembler;
asm
  cli
  push  dword $10
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi11 - hata kodu d�nd�r�r
 ==============================================================================}
procedure KesmeIslevi11; nostackframe; assembler;
asm
  cli
  push  dword $11
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHV

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,2 * 4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi12 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi12; nostackframe; assembler;
asm
  cli
  push  dword $12
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi13 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi13; nostackframe; assembler;
asm
  cli
  push  dword $13
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi14 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi14; nostackframe; assembler;
asm
  cli
  push  dword $14
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi15 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi15; nostackframe; assembler;
asm
  cli
  push  dword $15
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi16 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi16; nostackframe; assembler;
asm
  cli
  push  dword $16
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi17 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi17; nostackframe; assembler;
asm
  cli
  push  dword $17
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi18 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi18; nostackframe; assembler;
asm
  cli
  push  dword $18
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi19 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi19; nostackframe; assembler;
asm
  cli
  push  dword $19
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi1A - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi1A; nostackframe; assembler;
asm
  cli
  push  dword $1A
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi1B - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi1B; nostackframe; assembler;
asm
  cli
  push  dword $1B
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi1C - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi1C; nostackframe; assembler;
asm
  cli
  push  dword $1C
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi1D - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi1D; nostackframe; assembler;
asm
  cli
  push  dword $1D
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi1E - hata kodu d�nd�r�r
 ==============================================================================}
procedure KesmeIslevi1E; nostackframe; assembler;
asm
  cli
  push  dword $1E
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHV

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi1F - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi1F; nostackframe; assembler;
asm
  cli
  push  dword $1F
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  mov   al,$20
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  yaz�l�m kesmeleri - int30..int34
 ==============================================================================}

{==============================================================================
  KesmeIslevi30
 ==============================================================================}
procedure KesmeIslevi30; nostackframe; assembler;
asm
  cli
  push  dword $30
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi31
 ==============================================================================}
procedure KesmeIslevi31; nostackframe; assembler;
asm
  cli
  push  dword $31
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi32
 ==============================================================================}
procedure KesmeIslevi32; nostackframe; assembler;
asm
  cli
  push  dword $32
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  KesmeIslevi33
 ==============================================================================}
procedure KesmeIslevi33; nostackframe; assembler;
asm
  cli
  push  dword $33
  pushad
  xor   eax,eax
//  mov   ax,gs
//  push  eax
//  mov   ax,fs
//  push  eax
  mov   ax,ss
  push  eax
  mov   ax,es
  push  eax
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,esp
  call  YazmacGoruntuleHY

  pop   eax
  mov   ds,ax
  mov   es,ax
  add   esp,2 * 4
  popad
  add   esp,4
  sti
  iretd
end;

{==============================================================================
  yazma� i�eriklerini g�r�nt�le
 ==============================================================================}
procedure YazmacGoruntuleHY(AYazmaclar0: PYazmaclar0);
begin

  SISTEM_MESAJ(RENK_KIRMIZI, 'G�rev: %d, Kesme: %d', [CalisanGorev, AYazmaclar0^.ISRNo]);
  SISTEM_MESAJ(RENK_BORDO, '  EIP: %x, ESP: %x', [AYazmaclar0^.EIP, AYazmaclar0^.ESP]);
  SISTEM_MESAJ(RENK_BORDO, '   CS: %x,  DS: %x', [AYazmaclar0^.CS, AYazmaclar0^.DS]);
  SISTEM_MESAJ(RENK_BORDO, '   ES: %x,  SS: %x', [AYazmaclar0^.ES, AYazmaclar0^.SS]);
  SISTEM_MESAJ(RENK_BORDO, '   FS: %x,  GS: %x', [AYazmaclar0^.FS, AYazmaclar0^.GS]);
  SISTEM_MESAJ(RENK_BORDO, '  EAX: %x, EBX: %x', [AYazmaclar0^.EAX, AYazmaclar0^.EBX]);
  SISTEM_MESAJ(RENK_BORDO, '  ECX: %x, EDX: %x', [AYazmaclar0^.ECX, AYazmaclar0^.EDX]);
  SISTEM_MESAJ(RENK_BORDO, '  ESI: %x, EDI: %x', [AYazmaclar0^.ESI, AYazmaclar0^.EDI]);
  SISTEM_MESAJ(RENK_BORDO, '  EBP: %x, FLG: %x', [AYazmaclar0^.EBP, AYazmaclar0^.EFLAGS]);
//  asm @@abc: jmp @@abc end;
end;

{==============================================================================
  hata kodu da dahil yazma� i�eriklerini g�r�nt�le
 ==============================================================================}
procedure YazmacGoruntuleHV(AYazmaclar1: PYazmaclar1);
begin

  SISTEM_MESAJ(RENK_KIRMIZI, 'G�rev: %d, Kesme: %d, Hata Kodu: %d', [CalisanGorev,
    AYazmaclar1^.ISRNo, AYazmaclar1^.HataKodu]);
  SISTEM_MESAJ(RENK_BORDO, '  EIP: %x, ESP: %x', [AYazmaclar1^.EIP, AYazmaclar1^.ESP]);
  SISTEM_MESAJ(RENK_BORDO, '   CS: %x,  DS: %x', [AYazmaclar1^.CS, AYazmaclar1^.DS]);
  SISTEM_MESAJ(RENK_BORDO, '   ES: %x,  SS: %x', [AYazmaclar1^.ES, AYazmaclar1^.SS]);
  SISTEM_MESAJ(RENK_BORDO, '   FS: %x,  GS: %x', [AYazmaclar1^.FS, AYazmaclar1^.GS]);
  SISTEM_MESAJ(RENK_BORDO, '  EAX: %x, EBX: %x', [AYazmaclar1^.EAX, AYazmaclar1^.EBX]);
  SISTEM_MESAJ(RENK_BORDO, '  ECX: %x, EDX: %x', [AYazmaclar1^.ECX, AYazmaclar1^.EDX]);
  SISTEM_MESAJ(RENK_BORDO, '  ESI: %x, EDI: %x', [AYazmaclar1^.ESI, AYazmaclar1^.EDI]);
  SISTEM_MESAJ(RENK_BORDO, '  EBP: %x, FLG: %x', [AYazmaclar1^.EBP, AYazmaclar1^.EFLAGS]);
  //asm @@abc: jmp @@abc end;
end;

end.
