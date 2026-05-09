{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: src_pcnet32.pas
  Dosya Ýþlevi: PCNET32 að (network) sürücüsü

  Güncelleme Tarihi: 09/05/2026

 ==============================================================================}
{$mode objfpc}
//{$DEFINE PCNET32_BILGI}
unit src_pcnet32;
 
interface

uses paylasim, pci, port;

type
  TAygit = packed record
    Yol, Aygit,
    Islev: TSayi1;
    PortDegeri: TSayi2;
    BellekDegeri: TSayi4;
    IRQNo: TSayi1;
    CipSurum: TSayi4;
    CipAdi: string;
    Secenekler: TSayi4;
    FullDuplex: TSayi4;
    FDX: TSayi4;
    MII: TSayi4;
    FSET: TSayi4;
    MACAdres: TMACAdres;
  end;

var
  AygitPCNet32: TAygit;

function Yukle(APCI: PPCI): TISayi4;
procedure VeriAl(ABellek: Isaretci; var AVeriUzunlugu: TSayi2);
procedure VeriGonder(AEthernetPaket: PEthernetPaket; AVeriUzunlugu: TSayi2);
procedure PCNET32YukleniciIslev;
procedure IOVeriYoluYonetiminiEtkinlestir(APCI: PPCI);
procedure MACAdresiAl;

function WIOCSROku(ASiraNo: TSayi4): TSayi4;
procedure WIOCSRYaz(ASiraNo, AVeri: TSayi4);
function WIOBCROku(ASiraNo: TSayi4): TSayi4;
procedure WIOBCRYaz(ASiraNo, AVeri: TSayi4);
function WIORAPOku: TSayi4;
procedure WIORAPYaz(AVeri: TSayi4);
procedure WIOSifirla;
function WIOKontrol: Boolean;

function DWIOCSROku(ASiraNo: TSayi4): TSayi4;
procedure DWIOCSRYaz(ASiraNo, AVeri: TSayi4);
function DWIOBCROku(ASiraNo: TSayi4): TSayi4;
procedure DWIOBCRYaz(ASiraNo, AVeri: TSayi4);
function DWIORAPOku: TSayi4;
procedure DWIORAPYaz(AVeri: TSayi4);
procedure DWIOSifirla;
function DWIOKontrol: Boolean;

implementation

uses gercekbellek, irq, genel, islevler, sistemmesaj;

const
  PCNET32_PORT_AUI        = $00;
  PCNET32_PORT_10BT       = $01;
  PCNET32_PORT_GPSI       = $02;
  PCNET32_PORT_MII        = $03;
  PCNET32_PORT_PORTSEL    = $03;
  PCNET32_PORT_ASEL       = $04;
  PCNET32_PORT_100        = $40;
  PCNET32_PORT_FD         = $80;
  PCNET32_DMA_MASK        = $FFFFFFFF;


  PCNET32_WIO_RDP         = $10;
  PCNET32_WIO_RAP         = $12;
  PCNET32_WIO_RESET       = $14;
  PCNET32_WIO_BDP         = $16;

  PCNET32_DWIO_RDP        = $10;
  PCNET32_DWIO_RAP        = $14;
  PCNET32_DWIO_RESET      = $18;
  PCNET32_DWIO_BDP        = $1C;

  CSR_ERR                 = $8000;
  CSR_BABL                = $4000;
  CSR_CERR                = $2000;
  CSR_MISS                = $1000;
  CSR_MERR                = $0800;
  CSR_RINT                = $0400;
  CSR_TINT                = $0200;
  CSR_IDON                = $0100;
  CSR_INTR                = $0080;
  CSR_IENA                = $0040;
  CSR_RXON                = $0020;
  CSR_TXON                = $0010;
  CSR_TDMD                = $0008;
  CSR_STOP                = $0004;
  CSR_STRT                = $0002;
  CSR_INIT                = $0001;

  CSR                     = 0;
  INIT_BLOCK_ADDRESS_LOW  = 1;
  INIT_BLOCK_ADDRESS_HIGH = 2;
  INTERRUPT_MASK          = 3;
  FEATURE_CONTROL         = 4;
  CIP_KIMLIK_ALT          = 88;
  CIP_KIMLIK_UST          = 89;

  PCNET32_GIDIS_BELLEK    = 4;
  PCNET32_GELIS_BELLEK    = 5;

  GIDIS_HALKA_U           = (1 shl PCNET32_GIDIS_BELLEK);
  GIDIS_HALKA_MOD_MASKE   = (GIDIS_HALKA_U - 1);
  GIDIS_HALKA_UZ_BIT      = (PCNET32_GIDIS_BELLEK shl 12);

  GELIS_HALKA_U           = (1 shl PCNET32_GELIS_BELLEK);
  GELIS_HALKA_MOD_MASKE   = (GELIS_HALKA_U - 1);
  GELIS_HALKA_UZ_BIT      = (PCNET32_GELIS_BELLEK shl 4);

  ETH_CERCEVE_U           = 1544;
  TX_TIMEOUT              = 5000;

  RMD_OWN                 = $8000;
  RMD_ERR                 = $4000;
  RMD_FRAM                = $2000;
  RMD_OFLO                = $1000;
  RMD_CRC                 = $0800;
  RMD_BUFF                = $0400;
  RMD_STP                 = $0200;
  RMD_ENP                 = $0100;
  RMD_BPE                 = $0080;
  RMD_PAM                 = $0040;
  RMD_LAFM                = $0020;
  RMD_BAM                 = $0010;

  TMD_OWN                 = $8000;
  TMD_ERR                 = $4000;
  TMD_ADD_FCS             = $2000;        // ADD_FCS and NO_FCS is controlled through the same bit
  TMD_NO_FCS              = $2000;
  TMD_MORE                = $1000;        // MORE and LTINT is controlled through the same bit
  TMD_LTINT               = $1000;
  TMD_ONE                 = $0800;
  TMD_DEF                 = $0400;
  TMD_STP                 = $0200;
  TMD_ENP                 = $0100;
  TMD_BPE                 = $0080;
  TMD_RES                 = $007F;

type
  TBlokYukle = packed record
    _Mod: TSayi2;
    GDUzunluk: TSayi2;          // gidiþ (tx) / dönüþ (rx) uzunluk
    MACAdres: TMACAdres;
    AYRLDI: TSayi2;
    Suzgec1: TSayi4;
    Suzgec2: TSayi4;
    GelisHalka: Isaretci;       // halka = ring
    GidisHalka: Isaretci;
  end;

type
  TGidisHalka = record
    Bellek: Isaretci;
    Uzunluk: TSayi2;
    Durum: TSayi2;
    Degisik: TSayi4;
    AYRLDI: TSayi4;
  end;

type
  TGelisHalka = packed record
    Bellek: Isaretci;
    Uzunluk: TISayi2;
    Durum: TSayi2;
    MesajUz: TSayi4;
    AYRLDI: TSayi4;
  end;

var
  PCNET32Yuklendi: Boolean = False;
  BlokYukle: TBlokYukle;
  GidisHalka: array[0..GIDIS_HALKA_U - 1] of TGidisHalka;
  GelisHalka: array[0..GELIS_HALKA_U - 1] of TGelisHalka;
  GidisHalkaBellekAdresi,
  GelisHalkaBellekAdresi: Isaretci;
  BirSonrakiGidisSiraNo,
  BirSonrakiGelisSiraNo: TSayi4;

const
  CipAdi2420        : string = 'AMD PCI 79C970';
  CipAdi2430        : string = 'AMD PCI 79C970';
  CipAdi2621        : string = 'AMD PCI II 79C970A';
  CipAdi2623        : string = 'AMD FAST 79C971';
  CipAdi2624        : string = 'AMD FAST+ 79C972';
  CipAdi2625        : string = 'AMD FAST III 79C973';    // !
  CipAdi2626        : string = 'AMD Home 79C978';
  CipAdi2627        : string = 'AMD FAST III 79C975';
  CipAdiBilinmiyor  : string = 'Bilinmeyen Çip';

type
  TCSROku = function(ASiraNo: TSayi4): TSayi4;
  TCSRYaz = procedure(ASiraNo, AVeri: TSayi4);
  TBCROku = function(ASiraNo: TSayi4): TSayi4;
  TBCRYaz = procedure(ASiraNo, AVeri: TSayi4);
  TRAPOku = function: TSayi4;
  TRAPYaz = procedure(AVeri: TSayi4);
  TSifirla = procedure;

var
  CSROku: TCSROku;
  CSRYaz: TCSRYaz;
  BCROku: TBCROku;
  BCRYaz: TBCRYaz;
  RAPOku: TRAPOku;
  RAPYaz: TRAPYaz;
  Sifirla: TSifirla;

{==============================================================================
  pcnet32 að sürücü yükleme iþlevlerini içerir
 ==============================================================================}
function Yukle(APCI: PPCI): TISayi4;
var
  i, j: TSayi4;
  p: Isaretci;
begin

  // çýkýþ öndeðeri
  Result := -1;

  {$IFDEF PCNET32_BILGI}
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'PCNET32: að kartý sürücüsü yükleniyor...', []);
  {$ENDIF}

  // sistemde birden fazla pcnet aygýtý varsa, aygýtýn çoklu
  // yüklemesine þu anda izin verme
  if(PCNET32Yuklendi) then
  begin

    {$IFDEF PCNET32_BILGI}
    SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'PCNET32: aygýt yalnýzca bir kez yüklenebilir!', []);
    {$ENDIF}
    Exit;
  end;

  // çekirdeðin gönderdiði pci aygýt bilgilerini hedef bölgeye kopyala
  AygitPCNet32.Yol := APCI^.Yol;
  AygitPCNet32.Aygit := APCI^.Aygit;
  AygitPCNet32.Islev := APCI^.Islev;

  // aygýt port deðerini al
  AygitPCNet32.PortDegeri := PCIAygiti0.IlkPortDegeriniAl(APCI);
  if(AygitPCNet32.PortDegeri = 0) then
  begin

    {$IFDEF PCNET32_BILGI}
    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'PCNET32: giriþ / çýkýþ adresi alýnamýyor!', []);
    {$ENDIF}
    Exit;
  end;

  // IRQ numarasýný al
  AygitPCNet32.IRQNo := PCIAygiti0.IRQNoAl(APCI);

  {$IFDEF PCNET32_BILGI}
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'PCNET32 Yol: %d', [APCI^.Yol]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'PCNET32 Aygýt: %d', [APCI^.Aygit]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'PCNET32 Ýþlev: %d', [APCI^.Islev]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'PCNET32 Satýcý Kimlik: $%x', [APCI^.SaticiKimlik]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'PCNET32 Aygýt Kimlik: $%x', [APCI^.AygitKimlik]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'PCNET32 Port: $%x', [AygitPCNET32.PortDegeri]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'PCNET32 IRQ: $%x', [AygitPCNET32.IRQNo]);
  {$ENDIF}

  // çipi resetle (16 bit)
  WIOSifirla;

  // eðer 16 bit ise iþlevleri belirle
  if(WIOCSROku(0) = 4) and (WIOKontrol) then
  begin

    {$IFDEF PCNET32_BILGI}
    SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'PCNET32 Mod: WIO 16 bit', []);
    {$ENDIF}
    CSROku  := @WIOCSROku;
    CSRYaz  := @WIOCSRYaz;
    BCROku  := @WIOBCROku;
    BCRYaz  := @WIOBCRYaz;
    RAPOku  := @WIORAPOku;
    RAPYaz  := @WIORAPYaz;
    Sifirla := @WIOSifirla;
  end
  // eðer 32 bit ise iþlevleri belirle
  else
  begin

    // çip'i resetle (32 bit)
    DWIOSifirla;

    if(DWIOCSROku(0) = 4) and (DWIOKontrol) then
    begin

      {$IFDEF PCNET32_BILGI}
      SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'PCNET32 Mod: DWIO 32 bit', []);
      {$ENDIF}
      CSROku  := @DWIOCSROku;
      CSRYaz  := @DWIOCSRYaz;
      BCROku  := @DWIOBCROku;
      BCRYaz  := @DWIOBCRYaz;
      RAPOku  := @DWIORAPOku;
      RAPYaz  := @DWIORAPYaz;
      Sifirla := @DWIOSifirla;
    end
    else
    begin

      {$IFDEF PCNET32_BILGI}
      SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'PCNET32: aygýt mevcut deðil(1)!', []);
      {$ENDIF}
      Exit;
    end;
  end;

  // çip sürüm bilgisini al
  i := CSROku(CIP_KIMLIK_ALT);
  j := CSROku(CIP_KIMLIK_UST) shl 16;
  i := i or j;

  if((i and 3) <> 3) then
  begin

    {$IFDEF PCNET32_BILGI}
    SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'PCNET32: aygýt mevcut deðil(2)!', []);
    {$ENDIF}
    Exit;
  end;

  AygitPCNet32.CipSurum := (i shr 12) and $FFFF;

  case AygitPCNet32.CipSurum of
    $2420:  AygitPCNet32.CipAdi := CipAdi2420;
    $2430:  AygitPCNet32.CipAdi := CipAdi2430;
    $2621:  AygitPCNet32.CipAdi := CipAdi2621;
    $2623:  AygitPCNet32.CipAdi := CipAdi2623;
    $2624:  AygitPCNet32.CipAdi := CipAdi2624;
    $2625:  AygitPCNet32.CipAdi := CipAdi2625;
    $2626:  AygitPCNet32.CipAdi := CipAdi2626;
    $2627:  AygitPCNet32.CipAdi := CipAdi2627;
    else    AygitPCNet32.CipAdi := CipAdiBilinmiyor;
  end;

  {$IFDEF PCNET32_BILGI}
  SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'PCNET32 çip sürüm: $%.4x', [AygitPCNET32.CipSurum]);
  SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'PCNET32 çip adý: %s', [AygitPCNET32.CipAdi]);
  {$ENDIF}

  AygitPCNet32.FDX := 0;
  AygitPCNet32.MII := 0;
  AygitPCNet32.FSET := 0;

  if(AygitPCNet32.CipSurum = $2621) then
  begin

    AygitPCNet32.FDX := 1;
  end
  else if(AygitPCNet32.CipSurum = $2625) then
  begin

    AygitPCNet32.FDX := 1;
    AygitPCNet32.MII := 1;
  end;

  // pci i/o space ve bus master bayraklarýný etkinleþtir
  IOVeriYoluYonetiminiEtkinlestir(APCI);

  // aygýtýn mac adresini al
  MACAdresiAl;

  AygitPCNet32.Secenekler := PCNET32_PORT_ASEL;
  AygitPCNet32.FullDuplex := 1;

  // init_block içeriðini doldur
  BlokYukle._Mod := $80;
  BlokYukle.GDUzunluk := (GIDIS_HALKA_UZ_BIT or GELIS_HALKA_UZ_BIT);

  BlokYukle.MACAdres := AygitPCNet32.MACAdres;

  BlokYukle.Suzgec1 := 0;
  BlokYukle.Suzgec2 := 0;

  BlokYukle.GidisHalka := @GidisHalka[0];
  BlokYukle.GelisHalka := @GelisHalka[0];

  GidisHalkaBellekAdresi := GetMem(ETH_CERCEVE_U * GIDIS_HALKA_U);
  p := GidisHalkaBellekAdresi;
  for i := 0 to GIDIS_HALKA_U - 1 do
  begin

    GidisHalka[i].Bellek := p;
    GidisHalka[i].Uzunluk := 0;
    GidisHalka[i].Durum := 0;
    p += ETH_CERCEVE_U;
  end;
  BirSonrakiGidisSiraNo := 0;

  GelisHalkaBellekAdresi := GetMem(ETH_CERCEVE_U * GELIS_HALKA_U);
  p := GelisHalkaBellekAdresi;
  for i := 0 to GELIS_HALKA_U - 1 do
  begin

    GelisHalka[i].Bellek := p;
    GelisHalka[i].Uzunluk := -(ETH_CERCEVE_U);
    GelisHalka[i].Durum := RMD_OWN;
    p += ETH_CERCEVE_U;
  end;
  BirSonrakiGelisSiraNo := 0;

  // IRQ kanalýný aktifleþtir
  IRQIsleviAta(AygitPCNet32.IRQNo, @PCNET32YukleniciIslev);

  // aygýt sýfýrlama iþlemleri

  // aygýtý sýfýrla
  Sifirla;

  // 32 bit mod'a geç
  BCRYaz(20, 2);

  // otomatik seçim bitinin deðer almasý
  j := BCROku(2);
  j := (j and (not 2));
  if(AygitPCNet32.Secenekler <> PCNET32_PORT_ASEL) then j := j or 2;
  BCRYaz(2, j);

  if(AygitPCNet32.FullDuplex = 1) then
  begin

    j := BCROku(9);
    j := (j and (not 3));
    j := j or 1;
    BCRYaz(9, j);
  end;

  j := CSROku(124);
  CSRYaz(124, j);

  CSRYaz(INIT_BLOCK_ADDRESS_LOW, TSayi4(@BlokYukle) and $FFFF);
  CSRYaz(INIT_BLOCK_ADDRESS_HIGH, (TSayi4(@BlokYukle) shr 16) and $FFFF);

  CSRYaz(4, $915);
  CSRYaz(0, CSR_INIT);

  for i := 0 to 100 do
  begin

    j := CSROku(0);
    if((j and CSR_IDON) <> 0) then Break;
  end;

  CSRYaz(0, {CSR_IENA or} CSR_STRT);

  j := CSROku(0);

  // aygýtý yüklendi olarak iþaretle
  PCNET32Yuklendi := True;

  // aygýt yüklendi çýkýþ deðeri
  Result := 0;
end;

{==============================================================================
  PCNET32 að kartýna gelen bilgileri alýr
 ==============================================================================}
{$CODEALIGN PROC=4}
procedure VeriAl(ABellek: Isaretci; var AVeriUzunlugu: TSayi2);
var
  Durum: TSayi2;
  i: TSayi4;
begin

  // belirtilen halkaya veri gelip gelmediðini kontrol et
  Durum := GelisHalka[BirSonrakiGelisSiraNo].Durum;

  if((Durum and RMD_OWN) = 0) then
  begin

    if(((Durum shr 8) and $FF) = 3) then
    begin

      i := GelisHalka[BirSonrakiGelisSiraNo].MesajUz;
      i := i and $FFF;
      i -= 4;

      Tasi2(GelisHalka[BirSonrakiGelisSiraNo].Bellek, ABellek, i);
      AVeriUzunlugu := i;

      // halkayý veri alacak þekilde yeniden ayarla
      GelisHalka[BirSonrakiGelisSiraNo].Uzunluk := -(ETH_CERCEVE_U);
      GelisHalka[BirSonrakiGelisSiraNo].Durum := RMD_OWN;

      BirSonrakiGelisSiraNo := (BirSonrakiGelisSiraNo + 1) and GELIS_HALKA_MOD_MASKE;

    end else AVeriUzunlugu := 0;
  end else AVeriUzunlugu := 0;
end;

{==============================================================================
  PCNET32 IRQ iþlevi
 ==============================================================================}
procedure PCNET32YukleniciIslev;
var
  i: TSayi4;
begin

  repeat

    i := CSROku(0);
    i := (i and (CSR_ERR or CSR_RINT or CSR_TINT));
    if(i = 0) then
    begin

      CSRYaz(0, (CSR_BABL or CSR_CERR or CSR_MISS or CSR_MERR or CSR_IDON or CSR_IENA));
      Exit;
    end;

    i := i and (not (CSR_IENA or CSR_TDMD or CSR_STOP or CSR_STRT or CSR_INIT));
    CSRYaz(0, i);

    if((i and CSR_RINT) = CSR_RINT) then
    begin

      {$IFDEF PCNET32_BILGI}
      SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'PCNET32: veri alým tetiklendi.', []);
      {$ENDIF}
      //VeriAl;
    end
    else if((i and CSR_TINT) = CSR_TINT) then
    begin

    {$IFDEF PCNET32_BILGI}
    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'PCNET32: veri gönderimi.', []);
    {$ENDIF}
    end;
  until 1 = 2;
end;

{==============================================================================
  PCNET32 að kartý üzerinden bilgi gönderimi yapar
 ==============================================================================}
procedure VeriGonder(AEthernetPaket: PEthernetPaket; AVeriUzunlugu: TSayi2);
var
  p: Isaretci;
begin

  // gönderilecek bilgi'nin yerleþtirileceði belleðe konumlan
  p := GidisHalka[BirSonrakiGidisSiraNo].Bellek;

  // ethernet paketini belleðe yerleþtir
  Tasi2(AEthernetPaket, p, AVeriUzunlugu);

  // gönderilecek bilgi'nin sahip olduðu ring deðerlerini belirle
  GidisHalka[BirSonrakiGidisSiraNo].Uzunluk := -(AVeriUzunlugu);
  GidisHalka[BirSonrakiGidisSiraNo].Degisik := 0;
  GidisHalka[BirSonrakiGidisSiraNo].Durum := (TMD_OWN or TMD_STP or TMD_ENP);

  // bir sonraki gönderim ringini belirle
  BirSonrakiGidisSiraNo := (BirSonrakiGidisSiraNo + 1) and GIDIS_HALKA_MOD_MASKE;

  CSRYaz(0, (CSR_IENA or CSR_TDMD));
end;

{==============================================================================
  pci i/o space ve bus master bayraklarýný etkinleþtirir
 ==============================================================================}
procedure IOVeriYoluYonetiminiEtkinlestir(APCI: PPCI);
var
  Deger,
  i: TSayi2;
begin

  Deger := PCIAygiti0.Oku2(APCI^.Yol, APCI^.Aygit, APCI^.Islev, 4);

  i := 4 or 1;        // 4 = bus master, 1 = i/o space
  if((Deger and i) = i) then Exit;
  PCIAygiti0.Yaz2(APCI^.Yol, APCI^.Aygit, APCI^.Islev, 4, (Deger or i));
end;

{==============================================================================
  aygýtýn mac adresini alýr
 ==============================================================================}
procedure MACAdresiAl;
var
  i: TSayi4;
begin

  for i := 0 to 5 do
  begin

    AygitPCNet32.MACAdres[i] := PortAl1(AygitPCNet32.PortDegeri + i);
  end;
  GAgBilgisi.MACAdres := AygitPCNet32.MACAdres;

  {$IFDEF PCNET32_BILGI}
  SISTEM_MESAJ_MAC(mtBilgi, RENK_MAVI, 'PCNET32 MAC Adres: ', AygitPCNET32.MACAdres);
  {$ENDIF}
end;

function WIOCSROku(ASiraNo: TSayi4): TSayi4;
begin

  PortYaz2(AygitPCNet32.PortDegeri + PCNET32_WIO_RAP, ASiraNo);
  Result := PortAl2(AygitPCNet32.PortDegeri + PCNET32_WIO_RDP) and $FFFF;
end;

procedure WIOCSRYaz(ASiraNo, AVeri: TSayi4);
begin

  PortYaz2(AygitPCNet32.PortDegeri + PCNET32_WIO_RAP, ASiraNo);
  PortYaz2(AygitPCNet32.PortDegeri + PCNET32_WIO_RDP, AVeri);
end;

function WIOBCROku(ASiraNo: TSayi4): TSayi4;
begin

  PortYaz2(AygitPCNet32.PortDegeri + PCNET32_WIO_RAP, ASiraNo);
  Result := PortAl2(AygitPCNet32.PortDegeri + PCNET32_WIO_BDP) and $FFFF;
end;

procedure WIOBCRYaz(ASiraNo, AVeri: TSayi4);
begin

  PortYaz2(AygitPCNet32.PortDegeri + PCNET32_WIO_RAP, ASiraNo);
  PortYaz2(AygitPCNet32.PortDegeri + PCNET32_WIO_BDP, AVeri);
end;

function WIORAPOku: TSayi4;
begin

  Result := PortAl2(AygitPCNet32.PortDegeri + PCNET32_WIO_RAP) and $FFFF;
end;

procedure WIORAPYaz(AVeri: TSayi4);
begin

  PortYaz2(AygitPCNet32.PortDegeri + PCNET32_WIO_RAP, AVeri);
end;

procedure WIOSifirla;
begin

  PortAl2(AygitPCNet32.PortDegeri + PCNET32_WIO_RESET);
end;

function WIOKontrol: Boolean;
var
  Deger: TSayi2;
begin

  PortYaz2(AygitPCNet32.PortDegeri + PCNET32_WIO_RAP, 88);
  Deger := PortAl2(AygitPCNet32.PortDegeri + PCNET32_WIO_RAP);
  if(Deger = 88) then Result := True else Result := False;
end;

function DWIOCSROku(ASiraNo: TSayi4): TSayi4;
begin

  PortYaz4(AygitPCNet32.PortDegeri + PCNET32_DWIO_RAP, ASiraNo);
  Result := PortAl4(AygitPCNet32.PortDegeri + PCNET32_DWIO_RDP) and $FFFF;
end;

procedure DWIOCSRYaz(ASiraNo, AVeri: TSayi4);
begin

  PortYaz4(AygitPCNet32.PortDegeri + PCNET32_DWIO_RAP, ASiraNo);
  PortYaz4(AygitPCNet32.PortDegeri + PCNET32_DWIO_RDP, AVeri);
end;

function DWIOBCROku(ASiraNo: TSayi4): TSayi4;
begin

  PortYaz4(AygitPCNet32.PortDegeri + PCNET32_DWIO_RAP, ASiraNo);
  Result := PortAl4(AygitPCNet32.PortDegeri + PCNET32_DWIO_BDP) and $FFFF;
end;

procedure DWIOBCRYaz(ASiraNo, AVeri: TSayi4);
begin

  PortYaz4(AygitPCNet32.PortDegeri + PCNET32_DWIO_RAP, ASiraNo);
  PortYaz4(AygitPCNet32.PortDegeri + PCNET32_DWIO_BDP, AVeri);
end;

function DWIORAPOku: TSayi4;
begin

  Result := PortAl4(AygitPCNet32.PortDegeri + PCNET32_DWIO_RAP) and $FFFF;
end;

procedure DWIORAPYaz(AVeri: TSayi4);
begin

  PortYaz4(AygitPCNet32.PortDegeri + PCNET32_DWIO_RAP, AVeri);
end;

procedure DWIOSifirla;
begin

  PortAl4(AygitPCNet32.PortDegeri + PCNET32_DWIO_RESET);
end;

function DWIOKontrol: Boolean;
var
  Deger: TSayi4;
begin

  PortYaz4(AygitPCNet32.PortDegeri + PCNET32_DWIO_RAP, 88);
  Deger := PortAl4(AygitPCNet32.PortDegeri + PCNET32_DWIO_RAP) and $FFFF;
  if(Deger = 88) then Result := True else Result := False;
end;

end.
