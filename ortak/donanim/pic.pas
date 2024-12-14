{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: pic.pas
  Dosya İşlevi: pic yönetim işlevlerini içerir

  Güncelleme Tarihi: 06/10/2024

 ==============================================================================}
{$mode objfpc}{$H+}
{$asmmode intel}
unit pic;

interface

uses paylasim;

const
  // PIC sabitleri
  PIC1_KOMUT  = $20;
  PIC2_KOMUT  = $A0;
  PIC1_VERI   = PIC1_KOMUT + 1;
  PIC2_VERI   = PIC2_KOMUT + 1;

  ICW1_ICW4	  = $01;
  ICW1_YUKLE  = $10;

  ICW4_8086   = $01;

  PIC_IRROKU  = $0A;      // Kesme Talebi Kaydı (Interrupt Request Register) değerini oku
  PIC_ISROKU  = $0B;      // Hizmet İçi Kayıt (In-Service Register) değerini oku

procedure Yukle;
procedure TumKanallariAktiflestir;
procedure TumKanallariPasiflestir;
procedure Maskele(AIRQNo: TSayi1);
procedure MaskeKaldir(AIRQNo: TSayi1);
function IRRDegeriniOku: TSayi2;
function ISRDegeriniOku: TSayi2;

implementation

uses port;

{==============================================================================
  donanım kesme (irq) giriş noktalarını ön değerlerle yükler
 ==============================================================================}
procedure Yukle;
begin

  // ICW1 - her iki pic kontrolcüsüne ilk yükleme mesajı gönder
  // Bilgi: bu komuttan sonra pic 3 komut bekleyecektir
  PortYaz1(PIC1_KOMUT, ICW1_YUKLE + ICW1_ICW4);
  PortYaz1(PIC2_KOMUT, ICW1_YUKLE + ICW1_ICW4);

  // 1. ve 2. pic korumalı modda kesmeleri hangi sıra (offset) numarasından çağıracak
  // ICW2 - pic1 : irq0-irq7 -> int 0x20-0x27, pic2 : irq8-irq15 -> int 0x28-0x30
  PortYaz1(PIC1_VERI, $20);     // pic1 ilk sıra (offset) numarası, $20 numaralı kesme
  PortYaz1(PIC2_VERI, $28);     // pic2 ilk sıra (offset) numarası, $28 numaralı kesme

  // 1. ve 2. pic iletişim olarak ilişkisi
  // ICW3 - irq2 (bit 2=1) slave, slave id is 2. bit 1=1
  PortYaz1(PIC1_VERI, 4);   // 2. pic, 1. pic'in irq2'sine bağlı (0000 0100b)
  PortYaz1(PIC2_VERI, 2);   // 2. pic, 1. pic'e bağlı çalışacaktır (cascade)

  // ICW4 - her iki pic kontrolcüsü 8086/8088 modunda
  PortYaz1(PIC1_VERI, ICW4_8086);
  PortYaz1(PIC2_VERI, ICW4_8086);
end;

{==============================================================================
  pic'in tüm donanım kesmelerini aktifleştirir
 ==============================================================================}
procedure TumKanallariAktiflestir; nostackframe; assembler;
asm

  mov al,0
  out PIC1_VERI,al
  out PIC2_VERI,al
  sti
end;

{==============================================================================
  pic'in tüm kanallarını pasifleştir
 ==============================================================================}
procedure TumKanallariPasiflestir; nostackframe; assembler;
asm

  cli
  mov al,$FF
  out PIC1_VERI,al
  out PIC2_VERI,al
end;

{==============================================================================
  pic'in kesme kanalını pasifleştir
 ==============================================================================}
procedure Maskele(AIRQNo: TSayi1);
var
  Port: TSayi2;
  IRQNo, Deger: TSayi1;
begin

  IRQNo := AIRQNo;

  if(AIRQNo < 8) then
    Port := PIC1_VERI
  else
  begin
    Port := PIC2_VERI;
    IRQNo := AIRQNo - 8;
  end;

  asm
    pushad
    mov dx,Port
    in al,dx
    mov cl,IRQNo
    mov bl,1
    shl bl,cl
    or al,bl
    out dx,al
    popad
  end;
end;

{==============================================================================
  pic'in kesme kanalını aktifleştirir
 ==============================================================================}
procedure MaskeKaldir(AIRQNo: TSayi1);
var
  Port: TSayi2;
  IRQNo, Deger: TSayi1;
begin

  IRQNo := AIRQNo;

  if(AIRQNo < 8) then
    Port := PIC1_VERI
  else
  begin
    Port := PIC2_VERI;
    IRQNo := AIRQNo - 8;
  end;

  asm
    pushad
    mov dx,Port
    in al,dx
    mov cl,IRQNo
    mov bl,1
    shl bl,cl
    not bl
    and al,bl
    out dx,al
    popad
  end;
end;

// Kesme Talebi Kaydı (Interrupt Request Register) değerini oku
function IRRDegeriniOku: TSayi2;
begin

  PortYaz1(PIC1_KOMUT, PIC_IRROKU);
  PortYaz1(PIC2_KOMUT, PIC_IRROKU);

  Result := (PortAl1(PIC2_KOMUT) shl 8) or (PortAl1(PIC1_KOMUT));
end;

// Hizmet İçi Kayıt (In-Service Register) değerini oku
function ISRDegeriniOku: TSayi2;
begin

  PortYaz1(PIC1_KOMUT, PIC_ISROKU);
  PortYaz1(PIC2_KOMUT, PIC_ISROKU);

  ISRDegeriniOku := (PortAl1(PIC2_KOMUT) shl 8) or (PortAl1(PIC1_KOMUT));
end;

end.
