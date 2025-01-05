{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: idt.pas
  Dosya ��levi: kesme servis rutinlerini (isr) i�erir

  G�ncelleme Tarihi: 05/01/2025

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
  s�f�ra b�lme hatas� - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi00; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$00
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi01 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi01; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$01
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi02 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi02; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$02
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi03 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi03; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$03
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi04 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi04; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$04
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi05 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi05; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$05
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi06 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi06; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$06
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
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

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$08
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi09 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi09; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$09
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi0A - Invalid TSS - hata kodu d�nd�r�r
 ==============================================================================}
procedure KesmeIslevi0A; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$0A
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi0B - hata kodu d�nd�r�r
 ==============================================================================}
procedure KesmeIslevi0B; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$0B
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi0C - Stack Exception - hata kodu d�nd�r�r
 ==============================================================================}
procedure KesmeIslevi0C; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$0C
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  genel koruma hatas� - hata kodu d�nd�r�r
 ==============================================================================}
procedure KesmeIslevi0D; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$0D
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi0E - hata kodu d�nd�r�r
 ==============================================================================}
procedure KesmeIslevi0E; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$0E
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi0F - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi0F; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$0F
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi10 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi10; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$10
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi11 - hata kodu d�nd�r�r
 ==============================================================================}
procedure KesmeIslevi11; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$11
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi12 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi12; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$12
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi13 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi13; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$13
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi14 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi14; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$14
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi15 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi15; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$15
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi16 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi16; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$16
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi17 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi17; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$17
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi18 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi18; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$18
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi19 - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi19; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$19
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi1A - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi1A; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$1A
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi1B - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi1B; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$1B
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi1C - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi1C; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$1C
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi1D - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi1D; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$1D
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi1E - hata kodu d�nd�r�r
 ==============================================================================}
procedure KesmeIslevi1E; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$1E
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi1F - hata kodu d�nd�rmez
 ==============================================================================}
procedure KesmeIslevi1F; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$1F
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  yaz�l�m kesmeleri - int30..int34
 ==============================================================================}

{==============================================================================
  KesmeIslevi30
 ==============================================================================}
procedure KesmeIslevi30; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$30
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi31
 ==============================================================================}
procedure KesmeIslevi31; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$31
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi32
 ==============================================================================}
procedure KesmeIslevi32; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$32
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
end;

{==============================================================================
  KesmeIslevi33
 ==============================================================================}
procedure KesmeIslevi33; nostackframe; assembler;
asm

  // t�m kesmeleri durdur
  cli

  // ds ve es yazma�lar�n� sistem yazma�lar�na ayarla
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax

  // program� ilgili de�erlerle i�aretle
  mov eax,CalisanGorev
  shl eax,2
  mov esi,GorevListesi[eax]
  mov eax,4                             // gdSonlandiriliyor
  mov [esi + TGorev.FGorevDurum],eax
  mov eax,$33
  mov [esi + TGorev.FHataKodu],eax
  mov [esi + TGorev.FHataESP],esp

  add   esp,4

  mov   al,$20
  out   PIC1_KOMUT,al

  int $20

@@son: jmp @@son
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
