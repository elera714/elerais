{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: ohci.pas
  Dosya ��levi: usb ohci y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 30/01/2025

 ==============================================================================}
{$mode objfpc}
unit ohci;

interface

uses pci, paylasim;

procedure Yukle(APCI: PPCI);
procedure Kontrol1;
procedure KesmeIslevi;

implementation

uses sistemmesaj, zamanlayici, irq;

type
  POHCIYazmac = ^TOHCIYazmac;
  TOHCIYazmac = packed record
    D1, D2, D3, D4,
    D5, D6, D7, D8,
    D9, D10, D11, D12,
    D13, D14, D15, D16,
    D17, D18, D19, D20,
    D21,

    D22: TSayi4;
  end;

var
  OHCIAygit: PPCI = nil;
  TemelAdres: TSayi4;
  IRQNo: TSayi1;

procedure Yukle(APCI: PPCI);
begin

  OHCIAygit := APCI;

  if not(OHCIAygit = nil) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '  -> USB:OHCI kontrol ayg�t� bulundu...', []);

    // ayg�t bellek de�erini al
    TemelAdres := PCIAygiti0.IlkBellekDegeriniAl(OHCIAygit);
    if(TemelAdres = 0) then
    begin

      SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'USB-OHCI bellek de�eri al�nam�yor!', []);
      Exit;
    end;

    // IRQ numaras�n� al
    IRQNo := PCIAygiti0.IRQNoAl(APCI);

    //IRQIsleviAta(IRQNo, @KesmeIslevi);

    SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'USB-OHCI Genel Bilgiler:', []);
    SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'USB-OHCI Bellek Adresi: $%.8x', [TemelAdres]);
    SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'USB-OHCI IRQ: %d', [IRQNo]);
  end;
end;

procedure Kontrol1;
var
  OHCIYazmac: POHCIYazmac;
  Deger: TSayi4;
begin

  while True do
  begin

    BekleMS(100);

    if not(OHCIAygit = nil) then
    begin

      OHCIYazmac := Isaretci(TemelAdres);
      Deger := OHCIYazmac^.D22;

      SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'De�er: %d', [Deger]);
    end;
  end;
end;

procedure KesmeIslevi;
begin

  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'USB-OHCI kesme i�levi tetiklendi', []);
end;

end.
