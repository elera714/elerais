{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: irq.pas
  Dosya İşlevi: donanım (irq) kesme işlevlerini içerir

  Güncelleme Tarihi: 26/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit irq;
 
interface

uses paylasim, port;

var
  IRQIslevListesi: array[0..15] of TIRQIslevi = (
    nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil);

procedure Yukle;
procedure IRQIsleviAta(AIRQNo: TSayi4; AIslevAdres: TIRQIslevi);
procedure IRQIsleviIptal(AIRQNo: TSayi4);
procedure IRQEtkinlestir(AIRQNo: TSayi4);
procedure IRQPasiflestir(AIRQNo: TSayi4);
procedure IRQ00Islevi;
procedure IRQ01Islevi;
procedure IRQ02Islevi;
procedure IRQ03Islevi;
procedure IRQ04Islevi;
procedure IRQ05Islevi;
procedure IRQ06Islevi;
procedure IRQ07Islevi;
procedure IRQ08Islevi;
procedure IRQ09Islevi;
procedure IRQ10Islevi;
procedure IRQ11Islevi;
procedure IRQ12Islevi;
procedure IRQ13Islevi;
procedure IRQ14Islevi;
procedure IRQ15Islevi;

implementation

uses idt, pic;

{==============================================================================
  sistem tarafından çalıştırılacak irq işlev girişlerini belirler
 ==============================================================================}
procedure Yukle;
begin

  KesmeGirisiBelirle($20, @IRQ00Islevi, SECICI_SISTEM_KOD * 8, $8E);    // irq00
  KesmeGirisiBelirle($21, @IRQ01Islevi, SECICI_SISTEM_KOD * 8, $8E);    // irq01
  KesmeGirisiBelirle($22, @IRQ02Islevi, SECICI_SISTEM_KOD * 8, $8E);    // irq02
  KesmeGirisiBelirle($23, @IRQ03Islevi, SECICI_SISTEM_KOD * 8, $8E);    // irq03
  KesmeGirisiBelirle($24, @IRQ04Islevi, SECICI_SISTEM_KOD * 8, $8E);    // irq04
  KesmeGirisiBelirle($25, @IRQ05Islevi, SECICI_SISTEM_KOD * 8, $8E);    // irq05
  KesmeGirisiBelirle($26, @IRQ06Islevi, SECICI_SISTEM_KOD * 8, $8E);    // irq06
  KesmeGirisiBelirle($27, @IRQ07Islevi, SECICI_SISTEM_KOD * 8, $8E);    // irq07
  KesmeGirisiBelirle($28, @IRQ08Islevi, SECICI_SISTEM_KOD * 8, $8E);    // irq08
  KesmeGirisiBelirle($29, @IRQ09Islevi, SECICI_SISTEM_KOD * 8, $8E);    // irq09
  KesmeGirisiBelirle($2A, @IRQ10Islevi, SECICI_SISTEM_KOD * 8, $8E);    // irq10
  KesmeGirisiBelirle($2B, @IRQ11Islevi, SECICI_SISTEM_KOD * 8, $8E);    // irq11
  KesmeGirisiBelirle($2C, @IRQ12Islevi, SECICI_SISTEM_KOD * 8, $8E);    // irq12
  KesmeGirisiBelirle($2D, @IRQ13Islevi, SECICI_SISTEM_KOD * 8, $8E);    // irq13
  KesmeGirisiBelirle($2E, @IRQ14Islevi, SECICI_SISTEM_KOD * 8, $8E);    // irq14
  KesmeGirisiBelirle($2F, @IRQ15Islevi, SECICI_SISTEM_KOD * 8, $8E);    // irq15
end;

{==============================================================================
  belirtilen donanım kesmesini aktifleştirir
 ==============================================================================}
procedure IRQEtkinlestir(AIRQNo: TSayi4);
var
  EskiDeger, YeniDeger: TSayi1;
  PICNo: TSayi2;
begin

  cli;

  if(AIRQNo <= 7) then

    PICNo := PIC1_VERI
  else
  begin

    PICNo := PIC2_VERI;
    AIRQNo := AIRQNo - 8;
  end;

  // örnek: 11111111b -> 11111110b = IRQ0 aktifleştirildi
  EskiDeger := PortAl1(PICNo);
  YeniDeger := (1 shl AIRQNo);
  YeniDeger := not YeniDeger;
  YeniDeger := (EskiDeger and YeniDeger);

  if(EskiDeger = YeniDeger) then Exit;

  PortYaz1(PICNo, YeniDeger);

  sti;
end;

{==============================================================================
  belirtilen donanım kesmesini pasifleştirir
 ==============================================================================}
procedure IRQPasiflestir(AIRQNo: TSayi4);
var
  EskiDeger, YeniDeger: TSayi1;
  PICNo: TSayi2;
begin

  cli;

  if(AIRQNo <= 7) then

    PICNo := PIC1_VERI
  else
  begin

    PICNo := PIC2_VERI;
    AIRQNo := AIRQNo - 8;
  end;

  // örnek: 00000000b -> 00000010b = IRQ1 pasifleştirildi
  EskiDeger := PortAl1(PICNo);
  YeniDeger := (1 shl AIRQNo);
  YeniDeger := (EskiDeger or YeniDeger);

  if(EskiDeger = YeniDeger) then Exit;

  PortYaz1(PICNo, YeniDeger);

  sti;
end;

{==============================================================================
  donanım kesmesinin çağrı adresini belirler ve kesmeyi aktifleştirir
 ==============================================================================}
procedure IRQIsleviAta(AIRQNo: TSayi4; AIslevAdres: TIRQIslevi);
begin

  cli;
  IRQIslevListesi[AIRQNo] := AIslevAdres;
  IRQEtkinlestir(AIRQNo);
  sti;
end;

{==============================================================================
  donanım kesmesinin çağrı adresini iptal eder ve kesmeyi pasifleştirir
 ==============================================================================}
procedure IRQIsleviIptal(AIRQNo: TSayi4);
begin

  cli;
  IRQPasiflestir(AIRQNo);
  IRQIslevListesi[AIRQNo] := nil;
  sti;
end;

{==============================================================================
  IRQ00
 ==============================================================================}
procedure IRQ00Islevi; nostackframe; assembler;
asm

  cli
  pushad
  pushfd
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,IRQIslevListesi[0 * 4]
  cmp eax,0
  jz  @@islev_tamam

  call  IRQIslevListesi[0 * 4]

@@islev_tamam:
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
  IRQ01
 ==============================================================================}
procedure IRQ01Islevi; nostackframe; assembler;
asm

  cli
  pushad
  pushfd
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,IRQIslevListesi[1 * 4]
  cmp eax,0
  jz  @@islev_tamam

  call  IRQIslevListesi[1 * 4]

@@islev_tamam:
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
  IRQ02
 ==============================================================================}
procedure IRQ02Islevi; nostackframe; assembler;
asm

  cli
  pushad
  pushfd
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,IRQIslevListesi[2 * 4]
  cmp eax,0
  jz  @@islev_tamam

  call  IRQIslevListesi[2 * 4]

@@islev_tamam:
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
  IRQ03
 ==============================================================================}
procedure IRQ03Islevi; nostackframe; assembler;
asm

  cli
  pushad
  pushfd
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,IRQIslevListesi[3 * 4]
  cmp eax,0
  jz  @@islev_tamam

  call  IRQIslevListesi[3 * 4]

@@islev_tamam:
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
  IRQ04
 ==============================================================================}
procedure IRQ04Islevi; nostackframe; assembler;
asm

  cli
  pushad
  pushfd
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,IRQIslevListesi[4 * 4]
  cmp eax,0
  jz  @@islev_tamam

  call  IRQIslevListesi[4 * 4]

@@islev_tamam:
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
  IRQ05
 ==============================================================================}
procedure IRQ05Islevi; nostackframe; assembler;
asm

  cli
  pushad
  pushfd
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,IRQIslevListesi[5 * 4]
  cmp eax,0
  jz  @@islev_tamam

  call  IRQIslevListesi[5 * 4]

@@islev_tamam:
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
  IRQ06
 ==============================================================================}
procedure IRQ06Islevi; nostackframe; assembler;
asm

  cli
  pushad
  pushfd
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,IRQIslevListesi[6 * 4]
  cmp eax,0
  jz  @@islev_tamam

  call  IRQIslevListesi[6 * 4]

@@islev_tamam:
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
  IRQ07
 ==============================================================================}
procedure IRQ07Islevi; nostackframe; assembler;
asm

  cli
  pushad
  pushfd
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,IRQIslevListesi[7 * 4]
  cmp eax,0
  jz  @@islev_tamam

  call  IRQIslevListesi[7 * 4]

@@islev_tamam:
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
  IRQ08
 ==============================================================================}
procedure IRQ08Islevi; nostackframe; assembler;
asm

  cli
  pushad
  pushfd
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,IRQIslevListesi[8 * 4]
  cmp eax,0
  jz  @@islev_tamam

  call  IRQIslevListesi[8 * 4]

@@islev_tamam:
  mov   al,$20
  out   PIC2_KOMUT,al
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
  IRQ09
 ==============================================================================}
procedure IRQ09Islevi; nostackframe; assembler;
asm

  cli
  pushad
  pushfd
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,IRQIslevListesi[9 * 4]
  cmp eax,0
  jz  @@islev_tamam

  call  IRQIslevListesi[9 * 4]

@@islev_tamam:
  mov   al,$20
  out   PIC2_KOMUT,al
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
  IRQ10
 ==============================================================================}
procedure IRQ10Islevi; nostackframe; assembler;
asm

  cli
  pushad
  pushfd
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,IRQIslevListesi[10 * 4]
  cmp eax,0
  jz  @@islev_tamam

  call  IRQIslevListesi[10 * 4]

@@islev_tamam:
  mov   al,$20
  out   PIC2_KOMUT,al
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
  IRQ11
 ==============================================================================}
procedure IRQ11Islevi; nostackframe; assembler;
asm

  cli
  pushad
  pushfd
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,IRQIslevListesi[11 * 4]
  cmp eax,0
  jz  @@islev_tamam

  call  IRQIslevListesi[11 * 4]

@@islev_tamam:
  mov   al,$20
  out   PIC2_KOMUT,al
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
  IRQ12
 ==============================================================================}
procedure IRQ12Islevi; nostackframe; assembler;
asm

  cli
  pushad
  pushfd
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,IRQIslevListesi[12 * 4]
  cmp eax,0
  jz  @@islev_tamam

  call  IRQIslevListesi[12 * 4]

@@islev_tamam:
  mov   al,$20
  out   PIC2_KOMUT,al
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
  IRQ13
 ==============================================================================}
procedure IRQ13Islevi; nostackframe; assembler;
asm

  cli
  pushad
  pushfd
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,IRQIslevListesi[13 * 4]
  cmp eax,0
  jz  @@islev_tamam

  call  IRQIslevListesi[13 * 4]

@@islev_tamam:
  mov   al,$20
  out   PIC2_KOMUT,al
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
  IRQ14
 ==============================================================================}
procedure IRQ14Islevi; nostackframe; assembler;
asm

  cli
  pushad
  pushfd
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,IRQIslevListesi[14 * 4]
  cmp eax,0
  jz  @@islev_tamam

  call  IRQIslevListesi[14 * 4]

@@islev_tamam:
  mov   al,$20
  out   PIC2_KOMUT,al
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
  IRQ15
 ==============================================================================}
procedure IRQ15Islevi; nostackframe; assembler;
asm

  cli
  pushad
  pushfd
  mov   ax,ds
  push  eax
  mov   ax,SECICI_SISTEM_VERI * 8
  mov   ds,ax
  mov   es,ax

  mov eax,IRQIslevListesi[15 * 4]
  cmp eax,0
  jz  @@islev_tamam

  call  IRQIslevListesi[15 * 4]

@@islev_tamam:
  mov   al,$20
  out   PIC2_KOMUT,al
  out   PIC1_KOMUT,al
  pop   eax
  mov   ds,ax
  mov   es,ax
  popfd
  popad
  sti
  iretd
end;

end.
