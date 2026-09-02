{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: ohci.pas
  Dosya Ýþlevi: usb ohci yönetim iþlevlerini içerir

  Güncelleme Tarihi: 02/09/2026

  bilgi: https://wiki.osdev.org/Open_Host_Controller_Interface

 ==============================================================================}
{$mode objfpc}
unit ohci;

interface

uses pci, paylasim;

type
  TUSBOHCI = class
  private
    // usb:ohci aygýtýnýn pci tanýmlayýcý bilgisi
    FPCI: TPCI;
    // usb:ohci aygýtýnýn ayarlarýnýn bulunduðu fiziksel adres
    FTemelAdres: TSayi4;
    // usb:ohci aygýtýna ait kesme numarasý
    FIRQNo: TSayi1;
  public
    constructor Create(APCI: TPCI);
    function Oku(AYazmac: TSayi4): TSayi4;
    procedure Yaz(AYazmac, ADeger: TSayi4);
    procedure KesmeIslevi;
  end;

implementation

uses sistemmesaj;

type
  // ohci aygýtýnýn yazmaç deðerleri
  POHCIYazmac = ^TOHCIYazmac;
  TOHCIYazmac = record
    GozdenGecirme,              // 00 - HcRevision
    Kontrol,                    // 04 - HcControl
    KomutDurumu,                // 08 - HcCommandStatus
    KesmeDurumu,                // 0c - HcInterruptStatus
    KesmeAktif,                 // 10 - HcInterruptEnable
    KesmePasif,                 // 14 - HcInterruptDisable
    FizikselAdres,              // 18 - HcHCCA
    AktifED,                    // 1c - HcPeriodCurrentED
    AnaKontrolED,               // 20 - HcControlHeadED
    AktifKontrolED,             // 24 - HcControlCurrentED
    TopluAnaED,                 // 28 - HcBulkHeadED
    TopluAktifED,               // 2c - HcBulkCurrentED
    TamamlananBas,              // 30 - HcDoneHead
    CerceveAralik,              // 34 - HcFmInterval
    CerceveKalan,               // 38 - HcFmRemaining
    CerceveNo,                  // 3c - HcFmNumber
    DevirBaslangic,             // 40 - HcPeriodicStart
    DusukHizEsik,               // 44 - HcLSThreshold
    KokMerkezA,                 // 48 - HcRhDescriptorA
    KokMerkezB,                 // 4c - HcRhDescriptorB
    KokMerkezDurum: TSayi4;     // 50 - HcRhStatus
  end;

{==============================================================================
  ohci ana yükleme iþlevlerini içerir
 ==============================================================================}
constructor TUSBOHCI.Create(APCI: TPCI);
var
  i, j: TSayi4;
begin

  FPCI := APCI;

  if not(FPCI = nil) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, '  -> USB:OHCI kontrol aygýtý bulundu...', []);

    // aygýt bellek deðerini al
    FTemelAdres := GPCIAygitlar.IlkBellekDegeriniAl(FPCI);
    if(FTemelAdres = 0) then
    begin

      SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'USB-OHCI bellek deðeri alýnamýyor!', []);
      Exit;
    end;

    // IRQ numarasýný al
    FIRQNo := GPCIAygitlar.IRQNoAl(APCI);

    //IRQIsleviAta(IRQNo, @KesmeIslevi);

    SISTEM_MESAJ(mtBilgi, RENK_PEMBE, 'USB-OHCI Genel Bilgiler:', []);
    SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'USB-OHCI Bellek Adresi: $%.8x', [FTemelAdres]);
    SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'USB-OHCI IRQ: %d', [FIRQNo]);
{
    // fiziksel adres
    Yaz(6 * 4, $12345678);

    // tüm yazmaç deðerlerini görüntüle
    for i := 0 to 21 do
    begin

      j := Oku(i * 4);
      SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Yazmaç-%d: 0x%.8x', [i, j]);
    end;}
  end;
end;

{==============================================================================
  belirtilen yazmaçtan veri oku
 ==============================================================================}
function TUSBOHCI.Oku(AYazmac: TSayi4): TSayi4;
begin

  Result := PSayi4(FTemelAdres + AYazmac)^;
end;

{==============================================================================
  belirtilen yazmaca veri yaz
 ==============================================================================}
procedure TUSBOHCI.Yaz(AYazmac, ADeger: TSayi4);
begin

  PSayi4(FTemelAdres + AYazmac)^ := ADeger;
end;

{==============================================================================
  kesme geldiðinde çalýþacak iþlev
 ==============================================================================}
procedure TUSBOHCI.KesmeIslevi;
begin

  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'USB-OHCI kesme iþlevi tetiklendi', []);
end;

end.
