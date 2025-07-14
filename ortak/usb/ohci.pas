{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: ohci.pas
  Dosya Ýþlevi: usb ohci yönetim iþlevlerini içerir

  Güncelleme Tarihi: 30/01/2025

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

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '  -> USB:OHCI kontrol aygýtý bulundu...', []);

    // aygýt bellek deðerini al
    TemelAdres := PCIAygiti0.IlkBellekDegeriniAl(OHCIAygit);
    if(TemelAdres = 0) then
    begin

      SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'USB-OHCI bellek deðeri alýnamýyor!', []);
      Exit;
    end;

    // IRQ numarasýný al
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

      SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Deðer: %d', [Deger]);
    end;
  end;
end;

procedure KesmeIslevi;
begin

  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'USB-OHCI kesme iþlevi tetiklendi', []);
end;

end.
