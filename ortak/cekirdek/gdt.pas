{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gdt.pas
  Dosya İşlevi: genel (global) tanımlayıcı tablo (GDTR) işlevlerini yönetir

  Güncelleme Tarihi: 04/04/2020

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gdt;

interface

uses paylasim;

const
  GDTR_USTSINIR = 8192;

{
      +-------------------------------------------------------------+
      |31                         16|15                           00|  bit değerleri 00-31
      +-----------------------------+-------------------------------+
      |   BaslangicAdresi 15..00    |      Uzunluk 15..00           |
      +-------------------------------------------------------------+

      +-------------------------------------------------------------+
      |63  56|55           52|51  48|47                  40 |39   32|  bit değerleri 32-63
      +------+---------------+------+-----------------------+-------+
      | B.A. | G | D | 0 |AVL| Uzun.| P | DPL | S | TYPE| A | B.A.  |
      |31..24|   |   |   |   |19..16|   |  |  |   | | | |   |23..16 |
      +-------------------------------------------------------------+
             |-> esneklik  <-|      |->    e r i ş i m    <-|
}

type
  PGDTRGirdisi = ^TGDTRGirdisi;
  TGDTRGirdisi = packed record      // bit alanı - açıklama
    Uzunluk00_15: TSayi2;           // 15..00      (Uzun.)
    BaslangicAdresi00_15: TSayi2;   // 31..16      (B.A.)
    BaslangicAdresi16_23: TSayi1;   // 39..32
    Erisim: TSayi1;                 // 47..40
    //Uzunluk16_19: TSayi1;         // 51..48      Esneklik değerinin düşük 4 bitidir
    Esneklik: TSayi1;               // 55..52      granularity, esneklik olarak çevrilmiştir
    BaslangicAdresi24_31: TSayi1;   // 63..56
  end;

type
  PGDTRYazmac = ^TGDTRYazmac;
  TGDTRYazmac = packed record
    Uzunluk: TSayi2;
    BaslangicAdresi: Isaretci;
  end;

var
  GDTRYazmac: TGDTRYazmac;
  GDTRGirdiListesi: array[0..GDTR_USTSINIR - 1] of PGDTRGirdisi;

procedure Yukle;
procedure GDTRGirdisiEkle(AGirdiNo, ABaslangicAdresi, AUzunluk: TSayi4;
  AErisim, AEsneklik: TSayi1);

implementation

{==============================================================================
  daha önce oluşturulmuş GDTRYazmac girişlerini bellek işaretçileriyle eşleştirir
 ==============================================================================}
procedure Yukle;
var
  p: PGDTRGirdisi;
  i: TSayi4;
begin

  // GDTR yazmaç bilgilerinin bulunduğu bellek adresini al
  asm

    sgdt  GDTRYazmac;
  end;

  // GDTRYazmac girişlerini bellek işaretçileriyle eşleştir
  p := PGDTRGirdisi(GDTRYazmac.BaslangicAdresi);
  for i := 0 to GDTR_USTSINIR - 1 do
  begin

    GDTRGirdiListesi[i] := p;
    Inc(p);
  end;
end;

{==============================================================================
  GDT yazmacına girdi ekler
 ==============================================================================}
procedure GDTRGirdisiEkle(AGirdiNo, ABaslangicAdresi, AUzunluk: TSayi4;
  AErisim, AEsneklik: TSayi1);
var
  p: PGDTRGirdisi;
  i: TSayi1;
begin

  p := GDTRGirdiListesi[AGirdiNo];

  // temel bellek adresi (ABaslangicAdresi) - GDT: 31..16
  p^.BaslangicAdresi00_15 := (ABaslangicAdresi and $FFFF);

  // temel bellek adresi (ABaslangicAdresi) - GDT: 39..32
  p^.BaslangicAdresi16_23 := (ABaslangicAdresi shr 16) and $FF;

  // temel bellek adresi (ABaslangicAdresi) - GDT: 63..56
  p^.BaslangicAdresi24_31 := (ABaslangicAdresi shr 24) and $FF;

  // limit - GDT: 15..00
  p^.Uzunluk00_15 := (AUzunluk and $FFFF);

  // erişim - GDT: 47..40
  p^.Erisim := AErisim;

  // limit - GDT: 51..48
  i := (AUzunluk shr 16) and $F;

  // esneklik - GDT: 55..52
  i := (AEsneklik and $F0) or i;
  p^.Esneklik := i;
end;

end.
