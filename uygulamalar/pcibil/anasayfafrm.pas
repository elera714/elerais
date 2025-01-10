{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_genel, _forms, gn_degerdugmesi;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGenel: TGenel;
    FGorev: TGorev;
    FPencere: TPencere;
    FDegerDugmesi: TDegerDugmesi;
    function PCISinifAdiAl(ASinifKodu: TSayi4): string;
    function PCISaticiAdiAl(ASaticiKimlik: TSayi2): string;
    function PCIAygitAdiAl(ASaticiKimlik, AAygitKimlik: TSayi2): string;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'PCI Aygýt Bilgileri';

type
  TPCISinif = record
    Kod: TSayi4;
    Ad: string;
  end;

const
  PCISinifListesi: array[0..139] of TPCISinif = (
    (Kod: $000000; Ad: 'Old No-VGA combatible device'),
    (Kod: $000100; Ad: 'Old VGA combatible device'),
    (Kod: $010000; Ad: 'SCSI bus controller'),
    (Kod: $01018a; Ad: 'IDE controller'),
    (Kod: $010185; Ad: 'IDE Mass Storage'),
    (Kod: $010200; Ad: 'Floppy disk controller'),
    (Kod: $010300; Ad: 'IPI bus controller'),
    (Kod: $010400; Ad: 'RAID controller'),
    (Kod: $010520; Ad: 'ATA controller with single DMA'),
    (Kod: $010530; Ad: 'ATA controller with chained DMA'),
    (Kod: $010600; Ad: 'Serial ATA Direct Port Access (DPA)'),
    (Kod: $010601; Ad: 'SATA Mass Storage'),
    (Kod: $018000; Ad: 'Other mass storage controller'),
    (Kod: $020000; Ad: 'Ethernet controller'),
    (Kod: $020100; Ad: 'Token Ring controller'),
    (Kod: $020200; Ad: 'FDDI controller'),
    (Kod: $020300; Ad: 'ATM controller'),
    (Kod: $020400; Ad: 'ISDN controller'),
    (Kod: $020500; Ad: 'WorldFip controller'),
    (Kod: $020600; Ad: 'PICMG 2.14 Multi Computing'),
    (Kod: $028000; Ad: 'Other network controller'),
    (Kod: $030000; Ad: 'VGA-compatible controller'),
    (Kod: $030001; Ad: '8514-compatible controller'),
    (Kod: $030100; Ad: 'XGA controller'),
    (Kod: $030200; Ad: '3D controller'),
    (Kod: $038000; Ad: 'Other display controller'),
    (Kod: $040000; Ad: 'Video device'),
    (Kod: $040100; Ad: 'Audio device'),
    (Kod: $040200; Ad: 'Computer telephony device'),
    (Kod: $040300; Ad: 'Multimedia'),
    (Kod: $048000; Ad: 'Other multimedia device'),
    (Kod: $050000; Ad: 'RAM'),
    (Kod: $050100; Ad: 'Flash'),
    (Kod: $058000; Ad: 'Other memory controller'),
    (Kod: $060000; Ad: 'Host bridge'),
    (Kod: $060100; Ad: 'ISA bridge'),
    (Kod: $060200; Ad: 'EISA bridge'),
    (Kod: $060300; Ad: 'MCA bridge'),
    (Kod: $060400; Ad: 'PCI-to-PCI bridge'),
    (Kod: $060401; Ad: 'Subtractive Decode PCI-to-PCI bridge'),
    (Kod: $060500; Ad: 'PCMCIA bridge'),
    (Kod: $060600; Ad: 'NuBus bridge'),
    (Kod: $060700; Ad: 'CardBus bridge'),
    (Kod: $060800; Ad: 'RACEway bridge'),
    (Kod: $060940; Ad: 'Semi-transparent PCI-to-PCI bridge (pri)'),
    (Kod: $060980; Ad: 'Semi-transparent PCI-to-PCI bridge (sec)'),
    (Kod: $060a00; Ad: 'InfiniBand-to-PCI host bridge'),
    (Kod: $068000; Ad: 'Other bridge device'),
    (Kod: $070000; Ad: 'Generic XT-compatible serial controller'),
    (Kod: $070001; Ad: '16450-compatible serial controller'),
    (Kod: $070002; Ad: '16550-compatible serial controller'),
    (Kod: $070003; Ad: '16650-compatible serial controller'),
    (Kod: $070004; Ad: '16750-compatible serial controller'),
    (Kod: $070005; Ad: '16850-compatible serial controller'),
    (Kod: $070006; Ad: '16950-compatible serial controller'),
    (Kod: $070100; Ad: 'Parallel port'),
    (Kod: $070101; Ad: 'Bidirectional parallel port'),
    (Kod: $070102; Ad: 'ECP 1.X compliant parallel port'),
    (Kod: $070103; Ad: 'IEEE1284 controller'),
    (Kod: $0701fe; Ad: 'IEEE1284 target device (not a controller)'),
    (Kod: $070200; Ad: 'Multiport serial controller'),
    (Kod: $070300; Ad: 'Generic modem'),
    (Kod: $070301; Ad: 'Hayes compatible modem (16450)'),
    (Kod: $070302; Ad: 'GPIB (IEEE 488.1/2) controller'),
    (Kod: $070303; Ad: 'Smart Card'),
    (Kod: $070304; Ad: 'Hayes compatible modem (16550)'),
    (Kod: $070400; Ad: 'Hayes compatible modem (16650)'),
    (Kod: $070500; Ad: 'Hayes compatible modem (16750)'),
    (Kod: $078000; Ad: 'Other communications device'),
    (Kod: $080000; Ad: 'Generic 8259 PIC'),
    (Kod: $080001; Ad: 'ISA PIC'),
    (Kod: $080002; Ad: 'EISA PIC'),
    (Kod: $080010; Ad: 'I/O APIC interrupt controller'),
    (Kod: $080020; Ad: 'I/O(x) APIC interrupt controller'),
    (Kod: $080100; Ad: 'Generic 8237 DMA controller'),
    (Kod: $080101; Ad: 'ISA DMA controller'),
    (Kod: $080102; Ad: 'EISA DMA controller'),
    (Kod: $080200; Ad: 'Generic 8254 system timer'),
    (Kod: $080201; Ad: 'ISA system timer'),
    (Kod: $080202; Ad: 'EISA system timers'),
    (Kod: $080300; Ad: 'Generic RTC controller'),
    (Kod: $080301; Ad: 'ISA RTC controller'),
    (Kod: $080400; Ad: 'Generic PCI Hot-Plug controller'),
    (Kod: $080501; Ad: 'Base Peripheral'),
    (Kod: $088000; Ad: 'Other system peripheral'),
    (Kod: $090000; Ad: 'Keyboard controller'),
    (Kod: $090100; Ad: 'Digitizer (pen)'),
    (Kod: $090200; Ad: 'Mouse controller'),
    (Kod: $090300; Ad: 'Scanner controller'),
    (Kod: $090400; Ad: 'Gameport controller (generic)'),
    (Kod: $090410; Ad: 'Gameport controller (legacy)'),
    (Kod: $098000; Ad: 'Other input controller'),
    (Kod: $0a0000; Ad: 'Generic docking station'),
    (Kod: $0a8000; Ad: 'Other type of docking station'),
    (Kod: $0b0000; Ad: '386'),
    (Kod: $0b0100; Ad: '486'),
    (Kod: $0b0200; Ad: 'Pentium'),
    (Kod: $0b1000; Ad: 'Alpha'),
    (Kod: $0b2000; Ad: 'PowerPC'),
    (Kod: $0b3000; Ad: 'MIPS'),
    (Kod: $0b4000; Ad: 'Co-processor'),
    (Kod: $0c0000; Ad: 'IEEE 1394 (FireWire)'),
    (Kod: $0c0010; Ad: 'IEEE 1394 (FireWire) OHCI'),
    (Kod: $0c0100; Ad: 'ACCESS.bus'),
    (Kod: $0c0200; Ad: 'SSA'),
    (Kod: $0c0300; Ad: 'USB Controller (UHCI)'),
    (Kod: $0c0310; Ad: 'USB Controller (OHCI)'),
    (Kod: $0c0320; Ad: 'USB Controller (EHCI)'),
    (Kod: $0c0380; Ad: 'USB Controller'),
    (Kod: $0c03fe; Ad: 'USB Device'),
    (Kod: $0c0400; Ad: 'Fibre Channel'),
    (Kod: $0c0500; Ad: 'SMBus'),
    (Kod: $0c0600; Ad: 'InfiniBand'),
    (Kod: $0c0700; Ad: 'IPMI SMIC Interface'),
    (Kod: $0c0701; Ad: 'IPMI Kybd Controller Style Interface'),
    (Kod: $0c0702; Ad: 'IPMI Block Transfer Interfac'),
    (Kod: $0c0800; Ad: 'SERCOS Interface Standard (IEC 61491)'),
    (Kod: $0c0900; Ad: 'CANbus'),
    (Kod: $0d0000; Ad: 'iRDA compatible controller'),
    (Kod: $0d0100; Ad: 'Consumer IR controller'),
    (Kod: $0d1000; Ad: 'RF controller'),
    (Kod: $0d1100; Ad: 'Bluetooth'),
    (Kod: $0d1200; Ad: 'Broadband'),
    (Kod: $0d2000; Ad: 'Ethernet (802.11a - 5 GHz)'),
    (Kod: $0d2100; Ad: 'Ethernet (802.11b - 2.4 GHz)'),
    (Kod: $0d8000; Ad: 'Other type of wireless controller'),
    (Kod: $0e0000; Ad: 'Intelligent I/O (I2O) Architecture Spec 1.0'),
    (Kod: $0e0000; Ad: 'Message FIFO at offset $40'),
    (Kod: $0f0100; Ad: 'Satellite TV'),
    (Kod: $0f0200; Ad: 'Satellite Audio'),
    (Kod: $0f0300; Ad: 'Satellite Voice'),
    (Kod: $0f0400; Ad: 'Satellite Data'),
    (Kod: $100000; Ad: 'Network and computing en/decryption'),
    (Kod: $101000; Ad: 'Entertainment en/decryption'),
    (Kod: $108000; Ad: 'Other en/decryption'),
    (Kod: $110000; Ad: 'DPIO modules'),
    (Kod: $110100; Ad: 'Performance counters'),
    (Kod: $111000; Ad: 'Communications synchronization plus time and frequency test/measurement'),
    (Kod: $112000; Ad: 'Management card'),
    (Kod: $118000; Ad: 'Other data acquisition/signal processing controllers'));

type
  TSatici = record
    Kimlik: TSayi2;
    Ad: string;
  end;

const
  PCISaticiListesi: array[0..12] of TSatici = (
    (Kimlik: $1000; Ad: 'LSI Logic / Symbios Logic'),
    (Kimlik: $1022; Ad: 'Advanced Micro Devices'),
    (Kimlik: $104c; Ad: 'Texas Instruments'),
    (Kimlik: $106b; Ad: 'Apple Inc'),
    (Kimlik: $109e; Ad: 'Brooktree Corporation'),
    (Kimlik: $10de; Ad: 'nVidia Corporation'),
    (Kimlik: $10ec; Ad: 'Realtek Semiconductor Co.Ltd'),
    (Kimlik: $1217; Ad: 'O2 Micro, Inc'),
    (Kimlik: $1274; Ad: 'Ensoniq'),
    (Kimlik: $15ad; Ad: 'VMware'),
    (Kimlik: $168c; Ad: 'Atheros Communications Inc'),
    (Kimlik: $8086; Ad: 'Intel Corporation'),
    (Kimlik: $80ee; Ad: 'InnoTek Systemberatung GmbH'));

type
  TPCIAygit = record
    SaticiKimlik,
    AygitKimlik: TSayi2;
    AygitAdi: string;
  end;

const
  PCIAygitListesi: array[0..65] of TPCIAygit = (
    (SaticiKimlik: $1000; AygitKimlik: $0030; AygitAdi: '53c1030 PCI-X Fusion-MPT Dual Ultra320 SCSI'),
    (SaticiKimlik: $1022; AygitKimlik: $1100; AygitAdi: 'K8 [Athlon64/Opteron] HyperTransport Technology Configuration'),
    (SaticiKimlik: $1022; AygitKimlik: $1101; AygitAdi: 'K8 [Athlon64/Opteron] Address Map'),
    (SaticiKimlik: $1022; AygitKimlik: $1102; AygitAdi: 'K8 [Athlon64/Opteron] DRAM Controller'),
    (SaticiKimlik: $1022; AygitKimlik: $1103; AygitAdi: 'K8 [Athlon64/Opteron] Miscellaneous Control'),
    (SaticiKimlik: $1022; AygitKimlik: $2000; AygitAdi: 'Am79C970/1/2/3/5/6 PCnet LANCE PCI Ethernet Controller'),
    (SaticiKimlik: $104c; AygitKimlik: $8024; AygitAdi: 'TSB43AB23 IEEE-1394a-2000 Controller (PHY/Link)'),
    (SaticiKimlik: $106b; AygitKimlik: $003f; AygitAdi: 'KeyLargo/Intrepid USB'),
    (SaticiKimlik: $109e; AygitKimlik: $036e; AygitAdi: 'Bt878 Video Capture'),
    (SaticiKimlik: $109e; AygitKimlik: $0878; AygitAdi: 'Bt878 Audio Capture'),
    (SaticiKimlik: $10de; AygitKimlik: $01d3; AygitAdi: 'G72 [GeForce 7300 SE/7200 GS]'),
    (SaticiKimlik: $10de; AygitKimlik: $0441; AygitAdi: 'MCP65 LPC Bridge'),
    (SaticiKimlik: $10de; AygitKimlik: $0444; AygitAdi: 'MCP65 Memory Controller'),
    (SaticiKimlik: $10de; AygitKimlik: $0445; AygitAdi: 'MCP65 Memory Controller'),
    (SaticiKimlik: $10de; AygitKimlik: $0446; AygitAdi: 'MCP65 SMBus'),
    (SaticiKimlik: $10de; AygitKimlik: $0448; AygitAdi: 'MCP65 IDE'),
    (SaticiKimlik: $10de; AygitKimlik: $0449; AygitAdi: 'MCP65 PCI bridge'),
    (SaticiKimlik: $10de; AygitKimlik: $044a; AygitAdi: 'MCP65 High Definition Audio'),
    (SaticiKimlik: $10de; AygitKimlik: $0450; AygitAdi: 'MCP65 Ethernet'),
    (SaticiKimlik: $10de; AygitKimlik: $0454; AygitAdi: 'MCP65 USB Controller'),
    (SaticiKimlik: $10de; AygitKimlik: $0455; AygitAdi: 'MCP65 USB Controller'),
    (SaticiKimlik: $10de; AygitKimlik: $0458; AygitAdi: 'MCP65 PCI Express bridge'),
    (SaticiKimlik: $10de; AygitKimlik: $045d; AygitAdi: 'MCP65 SATA Controller'),
    (SaticiKimlik: $10ec; AygitKimlik: $8139; AygitAdi: 'RTL-8139/8139C/8139C+'),
    (SaticiKimlik: $10ec; AygitKimlik: $8168; AygitAdi: 'RTL8111/8168B PCI Express Gigabit Ethernet controller'),
    (SaticiKimlik: $1217; AygitKimlik: $00f7; AygitAdi: '1394 Open Host Controller Interface'),
    (SaticiKimlik: $1217; AygitKimlik: $7120; AygitAdi: 'Integrated MMC/SD Controller'),
    (SaticiKimlik: $1217; AygitKimlik: $7130; AygitAdi: 'Integrated MS/xD Controller'),
    (SaticiKimlik: $1217; AygitKimlik: $7136; AygitAdi: 'OZ711SP1 Memory CardBus Controller'),
    (SaticiKimlik: $1274; AygitKimlik: $1371; AygitAdi: 'ES1371 [AudioPCI-97]'),
    (SaticiKimlik: $15ad; AygitKimlik: $0405; AygitAdi: 'SVGA II Adapter'),
    (SaticiKimlik: $15ad; AygitKimlik: $0740; AygitAdi: 'Virtual Machine Communication Interface'),
    (SaticiKimlik: $15ad; AygitKimlik: $0770; AygitAdi: 'USB2 EHCI Controller'),
    (SaticiKimlik: $15ad; AygitKimlik: $0790; AygitAdi: 'PCI bridge'),
    (SaticiKimlik: $15ad; AygitKimlik: $07a0; AygitAdi: 'PCI Express Root Port'),
    (SaticiKimlik: $168c; AygitKimlik: $011c; AygitAdi: 'AR5001 Wireless Network Adapter'),
    (SaticiKimlik: $8086; AygitKimlik: $100f; AygitAdi: '82545EM Gigabit Ethernet Controller (Copper)'),
    (SaticiKimlik: $8086; AygitKimlik: $1237; AygitAdi: '82441FX PCI & Memory Controller (PMC)'),
    (SaticiKimlik: $8086; AygitKimlik: $2415; AygitAdi: '82801AA AC97 Audio Controller'),
    (SaticiKimlik: $8086; AygitKimlik: $2448; AygitAdi: '82801 Mobile PCI Bridge'),
    (SaticiKimlik: $8086; AygitKimlik: $265c; AygitAdi: '82801FB/FBM/FR/FW/FRW (ICH6 Family) USB2 EHCI Controller'),
    (SaticiKimlik: $8086; AygitKimlik: $2815; AygitAdi: '82801HEM (ICH8M) LPC Interface Controller'),
    (SaticiKimlik: $8086; AygitKimlik: $2829; AygitAdi: '82801HBM/HEM (ICH8M/ICH8M-E) SATA AHCI Controller'),
    (SaticiKimlik: $8086; AygitKimlik: $2830; AygitAdi: '82801H (ICH8 Family) USB UHCI Controller #1'),
    (SaticiKimlik: $8086; AygitKimlik: $2831; AygitAdi: '82801H (ICH8 Family) USB UHCI Controller #2'),
    (SaticiKimlik: $8086; AygitKimlik: $2832; AygitAdi: '82801H (ICH8 Family) USB UHCI Controller #3'),
    (SaticiKimlik: $8086; AygitKimlik: $2834; AygitAdi: '82801H (ICH8 Family) USB UHCI Controller #4'),
    (SaticiKimlik: $8086; AygitKimlik: $2835; AygitAdi: '82801H (ICH8 Family) USB UHCI Controller #5'),
    (SaticiKimlik: $8086; AygitKimlik: $2836; AygitAdi: '82801H (ICH8 Family) USB2 EHCI Controller #1'),
    (SaticiKimlik: $8086; AygitKimlik: $283a; AygitAdi: '82801H (ICH8 Family) USB2 EHCI Controller #2'),
    (SaticiKimlik: $8086; AygitKimlik: $283e; AygitAdi: '82801H (ICH8 Family) SMBus Controller'),
    (SaticiKimlik: $8086; AygitKimlik: $283f; AygitAdi: '82801H (ICH8 Family) PCI Express Port 1'),
    (SaticiKimlik: $8086; AygitKimlik: $2843; AygitAdi: '82801H (ICH8 Family) PCI Express Port 3'),
    (SaticiKimlik: $8086; AygitKimlik: $284b; AygitAdi: '82801H (ICH8 Family) HD Audio Controller'),
    (SaticiKimlik: $8086; AygitKimlik: $2850; AygitAdi: '82801HBM/HEM (ICH8M/ICH8M-E) IDE Controller'),
    (SaticiKimlik: $8086; AygitKimlik: $2a00; AygitAdi: 'Mobile PM965/GM965/GL960 Memory Controller Hub'),
    (SaticiKimlik: $8086; AygitKimlik: $2a03; AygitAdi: 'Mobile GM965/GL960 Integrated Graphics Controller'),
    (SaticiKimlik: $8086; AygitKimlik: $7000; AygitAdi: '82371SB PIIX3 PCI-to-ISA Bridge (Triton II)'),
    (SaticiKimlik: $8086; AygitKimlik: $7110; AygitAdi: '82371AB/EB/MB PIIX4 ISA'),
    (SaticiKimlik: $8086; AygitKimlik: $7111; AygitAdi: '82371AB/EB/MB PIIX4/4E/4M IDE Controller'),
    (SaticiKimlik: $8086; AygitKimlik: $7112; AygitAdi: '82371AB/EB/MB PIIX4 USB'),
    (SaticiKimlik: $8086; AygitKimlik: $7113; AygitAdi: '82371AB/EB/MB PIIX4/4E/4M Power Management Controller'),
    (SaticiKimlik: $8086; AygitKimlik: $7190; AygitAdi: '440BX/ZX/DX - 82443BX/ZX/DX Host bridge'),
    (SaticiKimlik: $8086; AygitKimlik: $7191; AygitAdi: '440BX/ZX/DX - 82443BX/ZX/DX AGP bridge'),
    (SaticiKimlik: $80ee; AygitKimlik: $cafe; AygitAdi: 'VirtualBox Guest Service'),
    (SaticiKimlik: $80ee; AygitKimlik: $beef; AygitAdi: 'VirtualBox Graphics Adapter'));

var
  ToplamPCIAygitSayisi, AygitSiraNo,
  TemelAdres, Deger32, i, k: TSayi4;
  PCIAygitBilgisi: TPCIAygitBilgisi;
  Deger8: TSayi1;
  SinifKod, SaticiKimlik, AygitAdi: string;

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 50, 10, 500, 450, ptBoyutlanabilir, PencereAdi, $FFE0CC);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  AygitSiraNo := 0;

  ToplamPCIAygitSayisi := FGenel.ToplamPCIAygitSayisiAl;
  if(ToplamPCIAygitSayisi > 0) then FGenel.PCIAygitBilgisiAl(AygitSiraNo, @PCIAygitBilgisi);

  FPencere.Tuval.KalemRengi := RENK_SIYAH;
  FPencere.Tuval.YaziYaz(8 * 8, 5, 'Toplam Aygýt:');
  FPencere.Tuval.KalemRengi := RENK_MAVI;
  FPencere.Tuval.SayiYaz10(22 * 8, 5, ToplamPCIAygitSayisi);

  FPencere.Tuval.KalemRengi := RENK_SIYAH;
  FPencere.Tuval.YaziYaz(25 * 8, 5, 'Mevcut Aygýt:');
  FPencere.Tuval.KalemRengi := RENK_MAVI;
  fPencere.Tuval.SayiYaz10(39 * 8, 5, AygitSiraNo + 1);

  FDegerDugmesi.Olustur(FPencere.Kimlik, 335, 0, 17, 22);
  FDegerDugmesi.Goster;
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = FO_TIKLAMA) then
  begin

    if(AOlay.Kimlik = FDegerDugmesi.Kimlik) then
    begin

      if(AOlay.Deger1 = 0) then
      begin

        if(AygitSiraNo + 1 < ToplamPCIAygitSayisi) then
        begin

          Inc(AygitSiraNo);
          FGenel.PCIAygitBilgisiAl(AygitSiraNo, @PCIAygitBilgisi);
          FPencere.Ciz;
        end;
      end
      else if(AOlay.Deger1 = 1) then
      begin

        if(AygitSiraNo - 1 >= 0) then
        begin

          Dec(AygitSiraNo);
          FGenel.PCIAygitBilgisiAl(AygitSiraNo, @PCIAygitBilgisi);
          FPencere.Ciz;
        end;
      end;
    end;
  end

  else if(AOlay.Olay = CO_CIZIM) then
  begin

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(8 * 8, 5, 'Toplam Aygýt:');
    FPencere.Tuval.KalemRengi := RENK_MAVI;
    FPencere.Tuval.SayiYaz10(22 * 8, 5, ToplamPCIAygitSayisi);

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(25 * 8, 5, 'Mevcut Aygýt:');
    FPencere.Tuval.KalemRengi := RENK_MAVI;
    FPencere.Tuval.SayiYaz10(39 * 8, 5, AygitSiraNo + 1);

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(0, 2 * 16, 'Yol  :');
    FPencere.Tuval.KalemRengi := RENK_MAVI;
    FPencere.Tuval.SayiYaz16(7 * 8, 2 * 16, True, 2, PCIAygitBilgisi.Yol);

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(19 * 8, 2 * 16, 'Aygýt:');
    FPencere.Tuval.KalemRengi := RENK_MAVI;
    FPencere.Tuval.SayiYaz16(26 * 8, 2 * 16, True, 2, PCIAygitBilgisi.Aygit);

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(38 * 8, 2 * 16, 'Ýþlev :');
    FPencere.Tuval.KalemRengi := RENK_MAVI;
    FPencere.Tuval.SayiYaz16(46 * 8, 2 * 16, True, 2, PCIAygitBilgisi.Islev);

    Deger32 := FGenel.PCIOku4(PCIAygitBilgisi.Yol, PCIAygitBilgisi.Aygit, PCIAygitBilgisi.Islev, 4);
    PCIAygitBilgisi.Komut := (Deger32 and $FFFF);
    PCIAygitBilgisi.Durum := ((Deger32 shr 16) and $FFFF);

    Deger8 := FGenel.PCIOku1(PCIAygitBilgisi.Yol, PCIAygitBilgisi.Aygit, PCIAygitBilgisi.Islev, 8);
    PCIAygitBilgisi.RevizyonKimlik := Deger8;

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(0, 3 * 16, 'Komut:');
    FPencere.Tuval.KalemRengi := RENK_MAVI;
    FPencere.Tuval.SayiYaz16(7 * 8, 3 * 16, True, 4, PCIAygitBilgisi.Komut);

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(19 * 8, 3 * 16, 'Durum:');
    FPencere.Tuval.KalemRengi := RENK_MAVI;
    FPencere.Tuval.SayiYaz16(26 * 8, 3 * 16, True, 4, PCIAygitBilgisi.Durum);

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(38 * 8, 3 * 16, 'Reviz.:');
    FPencere.Tuval.KalemRengi := RENK_MAVI;
    FPencere.Tuval.SayiYaz16(46 * 8, 3 * 16, True, 2, PCIAygitBilgisi.RevizyonKimlik);

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(0, 5 * 16, 'Sýnýf :');
    FPencere.Tuval.KalemRengi := RENK_MAVI;
    FPencere.Tuval.SayiYaz16(8 * 8, 5 * 16, True, 6, (PCIAygitBilgisi.SinifKod shr 8) and $FFFFFF);
    FPencere.Tuval.HarfYaz(16 * 8, 5 * 16, '-');
    SinifKod := PCISinifAdiAl(PCIAygitBilgisi.SinifKod);
    FPencere.Tuval.YaziYaz(18 * 8, 5 * 16, SinifKod);

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(0, 6 * 16, 'Satýcý:');
    FPencere.Tuval.KalemRengi := RENK_KIRMIZI;
    FPencere.Tuval.SayiYaz16(8 * 8, 6 * 16, True, 4, PCIAygitBilgisi.SaticiKimlik);
    FPencere.Tuval.HarfYaz(15 * 8, 6 * 16, '-');
    SaticiKimlik := PCISaticiAdiAl(PCIAygitBilgisi.SaticiKimlik);
    FPencere.Tuval.YaziYaz(17 * 8, 6 * 16, SaticiKimlik);

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(0, 7 * 16, 'Aygýt :');
    FPencere.Tuval.KalemRengi := RENK_KIRMIZI;
    FPencere.Tuval.SayiYaz16(8 * 8, 7 * 16, True, 4, PCIAygitBilgisi.AygitKimlik);
    FPencere.Tuval.HarfYaz(15 * 8, 7 * 16, '-');
    AygitAdi := PCIAygitAdiAl(PCIAygitBilgisi.SaticiKimlik, PCIAygitBilgisi.AygitKimlik);
    FPencere.Tuval.YaziYaz(17 * 8, 7 * 16, AygitAdi);

    Deger32 := FGenel.PCIOku4(PCIAygitBilgisi.Yol, PCIAygitBilgisi.Aygit, PCIAygitBilgisi.Islev, $C);
    PCIAygitBilgisi.OnbellekHatUzunluk := (Deger32 and $FF);
    PCIAygitBilgisi.GecikmeSuresi := ((Deger32 shr 8) and $FF);
    PCIAygitBilgisi.BaslikTip := ((Deger32 shr 16) and $FF);
    PCIAygitBilgisi.Bist := ((Deger32 shr 24) and $FF);

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(0, 9 * 16, 'Önbellek Hat Uz:');
    FPencere.Tuval.KalemRengi := RENK_MAVI;
    FPencere.Tuval.SayiYaz16(17 * 8, 9 * 16, True, 2, PCIAygitBilgisi.OnbellekHatUzunluk);
    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(28 * 8, 9 * 16, 'Gecikme Süre.:');
    FPencere.Tuval.KalemRengi := RENK_MAVI;
    FPencere.Tuval.SayiYaz16(43 * 8, 9 * 16, True, 2, PCIAygitBilgisi.GecikmeSuresi);
    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(0, 10 * 16, 'Baþlýk Tipi    :');
    FPencere.Tuval.KalemRengi := RENK_MAVI;
    FPencere.Tuval.SayiYaz16(17 * 8, 10 * 16, True, 2, PCIAygitBilgisi.BaslikTip);
    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(28 * 8, 10 * 16, 'BIST         :');
    FPencere.Tuval.KalemRengi := RENK_MAVI;
    FPencere.Tuval.SayiYaz16(43 * 8, 10 * 16, True, 2, PCIAygitBilgisi.Bist);

    Deger32 := FGenel.PCIOku4(PCIAygitBilgisi.Yol, PCIAygitBilgisi.Aygit, PCIAygitBilgisi.Islev, $2C);
    PCIAygitBilgisi.AltSistemSaticiKimlik := (Deger32 and $FFFF);
    PCIAygitBilgisi.AltSistemKimlik := ((Deger32 shr 16) and $FFFF);

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(0, 11 * 16, 'AltSis.Sat.Kim.:');
    FPencere.Tuval.KalemRengi := RENK_MAVI;
    FPencere.Tuval.SayiYaz16(17 * 8, 11 * 16, True, 4, PCIAygitBilgisi.AltSistemSaticiKimlik);
    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(28 * 8, 11 * 16, 'Alt.Sis.Kiml.:');
    FPencere.Tuval.KalemRengi := RENK_MAVI;
    FPencere.Tuval.SayiYaz16(43 * 8, 11 * 16, True, 4, PCIAygitBilgisi.AltSistemKimlik);

    Deger32 := FGenel.PCIOku4(PCIAygitBilgisi.Yol, PCIAygitBilgisi.Aygit, PCIAygitBilgisi.Islev, $3C);
    PCIAygitBilgisi.KesmeNo := (Deger32 and $FF);
    PCIAygitBilgisi.KesmePin := ((Deger32 shr 8) and $FF);
    PCIAygitBilgisi.EnDusukImtiyaz := ((Deger32 shr 16) and $FF);
    PCIAygitBilgisi.AzamiGecikme := ((Deger32 shr 24) and $FF);

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(0, 13 * 16, 'Kesme No:');
    FPencere.Tuval.KalemRengi := RENK_MAVI;
    FPencere.Tuval.SayiYaz16(10 * 8, 13 * 16, True, 2, PCIAygitBilgisi.KesmeNo);
    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(28 * 8, 13 * 16, 'Kesm.Pin');
    FPencere.Tuval.KalemRengi := RENK_MAVI;
    FPencere.Tuval.SayiYaz16(37 * 8, 13 * 16, True, 2, PCIAygitBilgisi.KesmePin);
    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(0, 14 * 16, 'EnDüþ.Ýmt');
    FPencere.Tuval.KalemRengi := RENK_MAVI;
    FPencere.Tuval.SayiYaz16(10 * 8, 14 * 16, True, 2, PCIAygitBilgisi.EnDusukImtiyaz);
    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(28 * 8, 14 * 16, 'Azam.Gec');
    FPencere.Tuval.KalemRengi := RENK_MAVI;
    FPencere.Tuval.SayiYaz16(37 * 8, 14 * 16, True, 2, PCIAygitBilgisi.AzamiGecikme);

    Deger32 := FGenel.PCIOku4(PCIAygitBilgisi.Yol, PCIAygitBilgisi.Aygit, PCIAygitBilgisi.Islev, $28);
    PCIAygitBilgisi.KartYolCISIsaretci := Deger32;
    Deger32 := FGenel.PCIOku4(PCIAygitBilgisi.Yol, PCIAygitBilgisi.Aygit, PCIAygitBilgisi.Islev, $30);
    PCIAygitBilgisi.GenisletilmisROMTemelAdres := Deger32;

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(0, 16 * 16, 'KartYol CIS Ýþaretçi:');
    FPencere.Tuval.KalemRengi := RENK_MAVI;
    FPencere.Tuval.SayiYaz16(22 * 8, 16 * 16, True, 8, PCIAygitBilgisi.KartYolCISIsaretci);
    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(0, 17 * 16, 'Genþl.ROM Tml.Adres:');
    FPencere.Tuval.KalemRengi := RENK_MAVI;
    FPencere.Tuval.SayiYaz16(21 * 8, 17 * 16, True, 8, PCIAygitBilgisi.GenisletilmisROMTemelAdres);

    Deger32 := FGenel.PCIOku4(PCIAygitBilgisi.Yol, PCIAygitBilgisi.Aygit, PCIAygitBilgisi.Islev, $10);
    PCIAygitBilgisi.TemelAdres[0] := Deger32;
    Deger32 := FGenel.PCIOku4(PCIAygitBilgisi.Yol, PCIAygitBilgisi.Aygit, PCIAygitBilgisi.Islev, $14);
    PCIAygitBilgisi.TemelAdres[1] := Deger32;
    Deger32 := FGenel.PCIOku4(PCIAygitBilgisi.Yol, PCIAygitBilgisi.Aygit, PCIAygitBilgisi.Islev, $18);
    PCIAygitBilgisi.TemelAdres[2] := Deger32;
    Deger32 := FGenel.PCIOku4(PCIAygitBilgisi.Yol, PCIAygitBilgisi.Aygit, PCIAygitBilgisi.Islev, $1C);
    PCIAygitBilgisi.TemelAdres[3] := Deger32;
    Deger32 := FGenel.PCIOku4(PCIAygitBilgisi.Yol, PCIAygitBilgisi.Aygit, PCIAygitBilgisi.Islev, $20);
    PCIAygitBilgisi.TemelAdres[4] := Deger32;
    Deger32 := FGenel.PCIOku4(PCIAygitBilgisi.Yol, PCIAygitBilgisi.Aygit, PCIAygitBilgisi.Islev, $24);
    PCIAygitBilgisi.TemelAdres[5] := Deger32;

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(0, 19 * 16, 'Kaynaklar:');

    k := 20;
    for i := 0 to 5 do
    begin

      FPencere.Tuval.KalemRengi := RENK_MAVI;
      if((PCIAygitBilgisi.TemelAdres[i] and 1) = 1) then
      begin

        TemelAdres := (PCIAygitBilgisi.TemelAdres[i] and (not 3));
        if(TemelAdres > 0) then
        begin

          FPencere.Tuval.SayiYaz16(5 * 8, k * 16, True, 8, TemelAdres);
          FPencere.Tuval.YaziYaz(16 * 8, k * 16, '- IO');
          Inc(k);
        end;
      end
      else
      begin

        TemelAdres := (PCIAygitBilgisi.TemelAdres[i] and (not 15));
        if(TemelAdres > 0) then
        begin

          FPencere.Tuval.SayiYaz16(5 * 8, k * 16, True, 8, TemelAdres);
          FPencere.Tuval.YaziYaz(16 * 8, k * 16, '- MEM');
          Inc(k);
        end;
      end;
    end;
  end;

  Result := 1;
end;

function TfrmAnaSayfa.PCISinifAdiAl(ASinifKodu: TSayi4): string;
var
  SinifKod, i: TSayi4;
begin

  SinifKod := (ASinifKodu shr 8) and $FFFFFF;

  for i := 0 to 139 do
  begin

    if(SinifKod = PCISinifListesi[i].Kod) then
      Exit(PCISinifListesi[i].Ad);
  end;

  Result := 'Bilinmeyen Aygýt Tipi';
end;

function TfrmAnaSayfa.PCISaticiAdiAl(ASaticiKimlik: TSayi2): string;
var
  i: TSayi4;
begin

  for i := 0 to 12 do
  begin

    if(PCISaticiListesi[i].Kimlik = ASaticiKimlik) then
      Exit(PCISaticiListesi[i].Ad);
  end;

  Result := 'Bilinmeyen Satýcý';
end;

function TfrmAnaSayfa.PCIAygitAdiAl(ASaticiKimlik, AAygitKimlik: TSayi2): string;
var
  i: TSayi4;
begin

  for i := 0 to 65 do
  begin

    if(PCIAygitListesi[i].SaticiKimlik = ASaticiKimlik) and
      (PCIAygitListesi[i].AygitKimlik = AAygitKimlik) then
        Exit(PCIAygitListesi[i].AygitAdi);
  end;

  Result := 'Bilinmeyen Aygýt';
end;

end.
