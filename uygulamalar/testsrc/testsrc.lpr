program testsrc;
{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: testsrc.lpr
  Program ��levi: temel ayg�t s�r�c� (device driver) kod dosyas�

  G�ncelleme Tarihi: 20/09/2024

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
    (AygitAdi: 'Test S�r�c�s�';
     AygitTanim: 'ELERA ��letim Sistemi i�in Test S�r�c�s�';
     Deger1: 1; Deger2: 2; Deger3: 3);

begin

  asm
    dd  AygitSurucusu
  end;
end.
