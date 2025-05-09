{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: irq.pas
  Dosya İşlevi: donanım (irq) kesme işlevlerini içerir

  Güncelleme Tarihi: 05/05/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit irq;
 
interface

uses paylasim, port;

const
  IRQBASINA_ISLEVSAYISI = 4;

var
  // her bir irq için toplam 8 işlev girişi
  IRQIslevListesi: array[0..15, 0..IRQBASINA_ISLEVSAYISI - 1] of TIslev;

procedure Yukle;
procedure IRQIsleviAta(AIRQNo: TSayi4; AIslevAdres: TIslev);
procedure IRQIsleviIptal(AIRQNo, AIRQSiraNo: TSayi4);
function IRQIslevBoSiraNoBul(AIRQNo: TSayi4): TISayi4;
function IRQDoluKanalSayisiniAl(AIRQNo: TSayi4): TISayi4;
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
var
  IRQNo, SiraNo: TSayi4;
begin

  // çoklu irq işlevlerini ilk değerlerle yükle
  for IRQNo := 0 to 15 do
  begin

    for SiraNo := 0 to IRQBASINA_ISLEVSAYISI - 1 do
    begin

      IRQIslevListesi[IRQNo, SiraNo] := nil;
    end;
  end;

  // kesme işlevlerini sistem işlevleriyle eşleştir
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
procedure IRQIsleviAta(AIRQNo: TSayi4; AIslevAdres: TIslev);
var
  IRQSiraNo: TISayi4;
begin

  cli;

  IRQSiraNo := IRQIslevBoSiraNoBul(AIRQNo);
  if(IRQSiraNo > -1) then
  begin

    IRQIslevListesi[AIRQNo, IRQSiraNo] := AIslevAdres;
    IRQEtkinlestir(AIRQNo);
  end;

  sti;
end;

{==============================================================================
  donanım kesmesinin çağrı adresini iptal eder ve kesmeyi pasifleştirir
 ==============================================================================}
procedure IRQIsleviIptal(AIRQNo, AIRQSiraNo: TSayi4);
begin

  cli;

  IRQIslevListesi[AIRQNo, AIRQSiraNo] := nil;

  // irq işlevine atanmış hiçbir işlev yoksa kesme tetiklemesini pasifleştir
  if(IRQDoluKanalSayisiniAl(AIRQNo) = 0) then IRQPasiflestir(AIRQNo);

  sti;
end;

{==============================================================================
  irq işlevi atamak için boş sıra numarası bulur (sıra numarasının tahsisini yapmaz)
 ==============================================================================}
function IRQIslevBoSiraNoBul(AIRQNo: TSayi4): TISayi4;
var
  i: TSayi4;
begin

  for i := 0 to IRQBASINA_ISLEVSAYISI - 1 do
  begin

    if(IRQIslevListesi[AIRQNo, i] = nil) then Exit(i);
  end;

  Result := -1;
end;

{==============================================================================
  irq işlevine tahsis edilmiş toplam irq işlev sayısını alır
 ==============================================================================}
function IRQDoluKanalSayisiniAl(AIRQNo: TSayi4): TISayi4;
var
  i: TSayi4;
begin

  Result := 0;

  for i := 0 to IRQBASINA_ISLEVSAYISI - 1 do
  begin

    if(IRQIslevListesi[AIRQNo, i] <> nil) then Inc(Result);
  end;
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

  // toplam işlev giriş sayısı + her biri 4 byte uzunluğunda
  mov   ebx,0 * (IRQBASINA_ISLEVSAYISI * 4)
  mov   ecx,0

@@islev_calistir:
  mov   eax,IRQIslevListesi[ebx + ecx * 4]
  cmp   eax,0
  jz    @@bir_sonraki

  call  eax

@@bir_sonraki:
  inc   ecx
  cmp   ecx,7
  jbe   @@islev_calistir

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

// toplam işlev giriş sayısı + her biri 4 byte uzunluğunda
  mov   ebx,1 * (IRQBASINA_ISLEVSAYISI * 4)
  mov   ecx,0

@@islev_calistir:
  mov   eax,IRQIslevListesi[ebx + ecx * 4]
  cmp   eax,0
  jz    @@bir_sonraki

  call  eax

@@bir_sonraki:
  inc   ecx
  cmp   ecx,7
  jbe   @@islev_calistir

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

// toplam işlev giriş sayısı + her biri 4 byte uzunluğunda
  mov   ebx,2 * (IRQBASINA_ISLEVSAYISI * 4)
  mov   ecx,0

@@islev_calistir:
  mov   eax,IRQIslevListesi[ebx + ecx * 4]
  cmp   eax,0
  jz    @@bir_sonraki

  call  eax

@@bir_sonraki:
  inc   ecx
  cmp   ecx,7
  jbe   @@islev_calistir

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

// toplam işlev giriş sayısı + her biri 4 byte uzunluğunda
  mov   ebx,3 * (IRQBASINA_ISLEVSAYISI * 4)
  mov   ecx,0

@@islev_calistir:
  mov   eax,IRQIslevListesi[ebx + ecx * 4]
  cmp   eax,0
  jz    @@bir_sonraki

  call  eax

@@bir_sonraki:
  inc   ecx
  cmp   ecx,7
  jbe   @@islev_calistir

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

// toplam işlev giriş sayısı + her biri 4 byte uzunluğunda
  mov   ebx,4 * (IRQBASINA_ISLEVSAYISI * 4)
  mov   ecx,0

@@islev_calistir:
  mov   eax,IRQIslevListesi[ebx + ecx * 4]
  cmp   eax,0
  jz    @@bir_sonraki

  call  eax

@@bir_sonraki:
  inc   ecx
  cmp   ecx,7
  jbe   @@islev_calistir

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

// toplam işlev giriş sayısı + her biri 4 byte uzunluğunda
  mov   ebx,5 * (IRQBASINA_ISLEVSAYISI * 4)
  mov   ecx,0

@@islev_calistir:
  mov   eax,IRQIslevListesi[ebx + ecx * 4]
  cmp   eax,0
  jz    @@bir_sonraki

  call  eax

@@bir_sonraki:
  inc   ecx
  cmp   ecx,7
  jbe   @@islev_calistir

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

// toplam işlev giriş sayısı + her biri 4 byte uzunluğunda
  mov   ebx,6 * (IRQBASINA_ISLEVSAYISI * 4)
  mov   ecx,0

@@islev_calistir:
  mov   eax,IRQIslevListesi[ebx + ecx * 4]
  cmp   eax,0
  jz    @@bir_sonraki

  call  eax

@@bir_sonraki:
  inc   ecx
  cmp   ecx,7
  jbe   @@islev_calistir

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

// toplam işlev giriş sayısı + her biri 4 byte uzunluğunda
  mov   ebx,7 * (IRQBASINA_ISLEVSAYISI * 4)
  mov   ecx,0

@@islev_calistir:
  mov   eax,IRQIslevListesi[ebx + ecx * 4]
  cmp   eax,0
  jz    @@bir_sonraki

  call  eax

@@bir_sonraki:
  inc   ecx
  cmp   ecx,7
  jbe   @@islev_calistir

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

// toplam işlev giriş sayısı + her biri 4 byte uzunluğunda
  mov   ebx,8 * (IRQBASINA_ISLEVSAYISI * 4)
  mov   ecx,0

@@islev_calistir:
  mov   eax,IRQIslevListesi[ebx + ecx * 4]
  cmp   eax,0
  jz    @@bir_sonraki

  call  eax

@@bir_sonraki:
  inc   ecx
  cmp   ecx,7
  jbe   @@islev_calistir

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

// toplam işlev giriş sayısı + her biri 4 byte uzunluğunda
  mov   ebx,9 * (IRQBASINA_ISLEVSAYISI * 4)
  mov   ecx,0

@@islev_calistir:
  mov   eax,IRQIslevListesi[ebx + ecx * 4]
  cmp   eax,0
  jz    @@bir_sonraki

  call  eax

@@bir_sonraki:
  inc   ecx
  cmp   ecx,7
  jbe   @@islev_calistir

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

// toplam işlev giriş sayısı + her biri 4 byte uzunluğunda
  mov   ebx,10 * (IRQBASINA_ISLEVSAYISI * 4)
  mov   ecx,0

@@islev_calistir:
  mov   eax,IRQIslevListesi[ebx + ecx * 4]
  cmp   eax,0
  jz    @@bir_sonraki

  call  eax

@@bir_sonraki:
  inc   ecx
  cmp   ecx,7
  jbe   @@islev_calistir

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

// toplam işlev giriş sayısı + her biri 4 byte uzunluğunda
  mov   ebx,11 * (IRQBASINA_ISLEVSAYISI * 4)
  mov   ecx,0

@@islev_calistir:
  mov   eax,IRQIslevListesi[ebx + ecx * 4]
  cmp   eax,0
  jz    @@bir_sonraki

  call  eax

@@bir_sonraki:
  inc   ecx
  cmp   ecx,7
  jbe   @@islev_calistir

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

// toplam işlev giriş sayısı + her biri 4 byte uzunluğunda
  mov   ebx,12 * (IRQBASINA_ISLEVSAYISI * 4)
  mov   ecx,0

@@islev_calistir:
  mov   eax,IRQIslevListesi[ebx + ecx * 4]
  cmp   eax,0
  jz    @@bir_sonraki

  call  eax

@@bir_sonraki:
  inc   ecx
  cmp   ecx,7
  jbe   @@islev_calistir

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

// toplam işlev giriş sayısı + her biri 4 byte uzunluğunda
  mov   ebx,13 * (IRQBASINA_ISLEVSAYISI * 4)
  mov   ecx,0

@@islev_calistir:
  mov   eax,IRQIslevListesi[ebx + ecx * 4]
  cmp   eax,0
  jz    @@bir_sonraki

  call  eax

@@bir_sonraki:
  inc   ecx
  cmp   ecx,7
  jbe   @@islev_calistir

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

// toplam işlev giriş sayısı + her biri 4 byte uzunluğunda
  mov   ebx,14 * (IRQBASINA_ISLEVSAYISI * 4)
  mov   ecx,0

@@islev_calistir:
  mov   eax,IRQIslevListesi[ebx + ecx * 4]
  cmp   eax,0
  jz    @@bir_sonraki

  call  eax

@@bir_sonraki:
  inc   ecx
  cmp   ecx,7
  jbe   @@islev_calistir

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

// toplam işlev giriş sayısı + her biri 4 byte uzunluğunda
  mov   ebx,15 * (IRQBASINA_ISLEVSAYISI * 4)
  mov   ecx,0

@@islev_calistir:
  mov   eax,IRQIslevListesi[ebx + ecx * 4]
  cmp   eax,0
  jz    @@bir_sonraki

  call  eax

@@bir_sonraki:
  inc   ecx
  cmp   ecx,7
  jbe   @@islev_calistir

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
