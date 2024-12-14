program testsrc;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: testsrc.lpr
  Program Ýþlevi: temel aygýt sürücü (device driver) kod dosyasý

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
type
  TAygitSurucusu = record
    AygitAdi: string[30];
    AygitTanim: string[50];
    Deger1, Deger2, Deger3: TSayi4;
  end;

const
  AygitSurucusu: TAygitSurucusu =
    (AygitAdi: 'Test Sürücüsü';
     AygitTanim: 'ELERA Ýþletim Sistemi için Test Sürücüsü';
     Deger1: 1; Deger2: 2; Deger3: 3);

begin

  asm
    dd  AygitSurucusu
  end;
end.
