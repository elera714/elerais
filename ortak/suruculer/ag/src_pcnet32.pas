{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: src_pcnet32.pas
  Dosya Ýþlevi : PCNET32 að (network) sürücüsü

  Güncelleme Tarihi: 16/09/2024

  Bilgi: sadece kullanýlan sabit, deðiþken ve iþlevler türkçeye çevrilmiþtir

 ==============================================================================}
{$mode objfpc}
//{$DEFINE PCNET32_BILGI}
unit src_pcnet32;
 
interface

uses paylasim, port;

type
  TAygit = packed record
    Yol, Aygit,
    Islev: TSayi1;
    TemelAdres: TSayi2;
    IRQNo: TSayi1;
    CipSurum: TSayi4;
    CipAdi: PChar;
    MACAdres: TMACAdres;
  end;

var
  AygitPCNET32: TAygit;

function Yukle(APCI: PPCI): TISayi4;
procedure VeriAl(ABellek: Isaretci; var AVeriUzunlugu: TSayi2);
procedure VeriGonder(AEthernetPaket: PEthernetPaket; AVeriUzunlugu: TSayi2);
procedure PCNET32YukleniciIslev;
function IlkIOPortNumarasiniAl(APCI: PPCI): TSayi2;
function IRQNoAl(APCI: PPCI): TSayi1;
procedure DMAErisiminiAktiflestir(APCI: PPCI);

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

uses pci, gercekbellek, irq, genel, sistemmesaj;

const
  PCNET32_WIO_RDP = $10;
  PCNET32_WIO_RAP = $12;
  PCNET32_WIO_RESET = $14;
  PCNET32_WIO_BDP = $16;

  PCNET32_DWIO_RDP = $10;
  PCNET32_DWIO_RAP = $14;
  PCNET32_DWIO_RESET = $18;
  PCNET32_DWIO_BDP = $1C;

  CSR_ERR = $8000;
  CSR_BABL = $4000;
  CSR_CERR = $2000;
  CSR_MISS = $1000;
  CSR_MERR = $0800;
  CSR_RINT = $0400;
  CSR_TINT = $0200;
  CSR_IDON = $0100;
  CSR_INTR = $0080;
  CSR_IENA = $0040;
  CSR_RXON = $0020;
  CSR_TXON = $0010;
  CSR_TDMD = $0008;
  CSR_STOP = $0004;
  CSR_STRT = $0002;
  CSR_INIT = $0001;

  CSR = 0;
  INIT_BLOCK_ADDRESS_LOW = 1;
  INIT_BLOCK_ADDRESS_HIGH = 2;
  INTERRUPT_MASK = 3;
  FEATURE_CONTROL = 4;
  CIP_KIMLIK_ALT = 88;
  CIP_KIMLIK_UST = 89;

  PCNET32_GIDIS_BELLEK = 4;
  PCNET32_DONUS_BELLEK = 5;

  GIDIS_HALKA_U         = (1 shl PCNET32_GIDIS_BELLEK);
  GIDIS_HALKA_MOD_MASKE = (GIDIS_HALKA_U - 1);
  GIDIS_HALKA_UZ_BIT    = (PCNET32_GIDIS_BELLEK shl 12);

  DONUS_HALKA_U         = (1 shl PCNET32_DONUS_BELLEK);
  DONUS_HALKA_MOD_MASKE = (DONUS_HALKA_U - 1);
  DONUS_HALKA_UZ_BIT    = (PCNET32_DONUS_BELLEK shl 4);

  ETH_CERCEVE_U = 1544;
  TX_TIMEOUT = 5000;

  RMD_OWN = $8000;
  RMD_ERR = $4000;
  RMD_FRAM = $2000;
  RMD_OFLO = $1000;
  RMD_CRC = $0800;
  RMD_BUFF = $0400;
  RMD_STP = $0200;
  RMD_ENP = $0100;
  RMD_BPE = $0080;
  RMD_PAM = $0040;
  RMD_LAFM = $0020;
  RMD_BAM = $0010;

  TMD_OWN = $8000;
  TMD_ERR = $4000;
  TMD_ADD_FCS = $2000;    //ADD_FCS and NO_FCS is controlled through the same bit
  TMD_NO_FCS = $2000;
  TMD_MORE = $1000;       //MORE and LTINT is controlled through the same bit
  TMD_LTINT = $1000;
  TMD_ONE = $0800;
  TMD_DEF = $0400;
  TMD_STP = $0200;
  TMD_ENP = $0100;
  TMD_BPE = $0080;
  TMD_RES = $007F;

type
  TBlokYukle = packed record
    _Mod: TSayi2;
    GDUzunluk: TSayi2;          // gidiþ (tx) / dönüþ (rx) uzunluk
    MACAdres: TMACAdres;
    AYRLDI: TSayi2;
    Suzgec1: TSayi4;
    Suzgec2: TSayi4;
    DonusHalka: Isaretci;       // halka = ring
    GidisHalka: Isaretci;
  end;

type
  TDonusHalka = packed record
    Bellek: Isaretci;
    Uzunluk: TISayi2;
    Durum: TSayi2;
    MesajUz: TSayi4;
    AYRLDI: TSayi4;
  end;

type
  TGidisHalka = record
    Bellek: Isaretci;
    Uzunluk: TSayi2;
    Durum: TSayi2;
    Degisik: TSayi4;
    AYRLDI: TSayi4;
  end;

var
  PCNET32Yuklendi: Boolean = False;
  BlokYukle: TBlokYukle;
  DonusHalka: array[1..DONUS_HALKA_U] of TDonusHalka;
  GidisHalka: array[1..GIDIS_HALKA_U] of TGidisHalka;
  DonusHalkaBellekAdresi: Isaretci;
  GidisHalkaBellekAdresi: Isaretci;
  BirSonrakiDonusSiraNo: TSayi4;
  BirSonrakiGidisSiraNo: TSayi4;

const
  CipAdi2420        = 'AMD PCI 79C970';
  CipAdi2430        = 'AMD PCI 79C970';
  CipAdi2621        = 'AMD PCI II 79C970A';
  CipAdi2623        = 'AMD FAST 79C971';
  CipAdi2624        = 'AMD FAST+ 79C972';
  CipAdi2625        = 'AMD FAST III 79C973';
  CipAdi2626        = 'AMD Home 79C978';
  CipAdi2627        = 'AMD FAST III 79C975';
  CipAdiBilinmiyor  = 'Bilinmeyen Çip';

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
  _i, _j: TSayi4;
  _p: Isaretci;
begin

  // çýkýþ öndeðeri
  Result := -1;

  {$IFDEF PCNET32_BILGI}
  SISTEM_MESAJ(RENK_LACIVERT, 'PCNET32: að kartý sürücüsü yükleniyor...', []);
  {$ENDIF}

  // sistemde birden fazla pcnet aygýtý varsa, aygýtýn çoklu
  // yüklemesine þu anda izin verme
  if(PCNET32Yuklendi) then
  begin

    {$IFDEF PCNET32_BILGI}
    SISTEM_MESAJ(RENK_KIRMIZI, 'PCNET32: aygýt yalnýzca bir kez yüklenebilir!', []);
    {$ENDIF}
    Exit;
  end;

  // çekirdeðin gönderdiði pci aygýt bilgilerini hedef bölgeye kopyala
  AygitPCNET32.Yol := APCI^.Yol;
  AygitPCNET32.Aygit := APCI^.Aygit;
  AygitPCNET32.Islev := APCI^.Islev;

  // aygýt temel port numarasýný al
  AygitPCNET32.TemelAdres := IlkIOPortNumarasiniAl(APCI);
  if(AygitPCNET32.TemelAdres = 0) then
  begin

    {$IFDEF PCNET32_BILGI}
    SISTEM_MESAJ(RENK_KIRMIZI, 'PCNET32: giriþ / çýkýþ adresi alýnamýyor!', []);
    {$ENDIF}
    Exit;
  end;

  // IRQ numarasýný al
  AygitPCNET32.IRQNo := IRQNoAl(APCI);

  {$IFDEF PCNET32_BILGI}
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'PCNET32 Yol: ', APCI^.Yol, 2);
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'PCNET32 Aygýt: ', APCI^.Aygit, 2);
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'PCNET32 Ýþlev: ', APCI^.Islev, 2);
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'PCNET32 Satýcý Kimlik: ', APCI^.SaticiKimlik, 4);
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'PCNET32 Aygýt Kimlik: ', APCI^.AygitKimlik, 4);
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'PCNET32 Port: ', AygitPCNET32.TemelAdres, 4);
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'PCNET32 IRQ: ', AygitPCNET32.IRQNo, 2);
  {$ENDIF}

  // DMA eriþimini aktifleþtir
  DMAErisiminiAktiflestir(APCI);

  // çipi resetle (16 bit)
  WIOSifirla;

  // eðer 16 bit ise iþlevleri belirle
  if(WIOCSROku(0) = 4) and (WIOKontrol) then
  begin

    {$IFDEF PCNET32_BILGI}
    SISTEM_MESAJ(RENK_LACIVERT, 'PCNET32 Mod: WIO 16 bit', []);
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
      SISTEM_MESAJ(RENK_LACIVERT, 'PCNET32 Mod: DWIO 32 bit', []);
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
      SISTEM_MESAJ(RENK_KIRMIZI, 'PCNET32: aygýt mevcut deðil(1)!', []);
      {$ENDIF}
      Exit;
    end;
  end;

  // çip sürüm bilgisini al
  AygitPCNET32.CipSurum := (CSROku(CIP_KIMLIK_UST) shl 16);
  AygitPCNET32.CipSurum += CSROku(CIP_KIMLIK_ALT);

  if((AygitPCNET32.CipSurum and $3) = 0) then
  begin

    {$IFDEF PCNET32_BILGI}
    SISTEM_MESAJ(RENK_KIRMIZI, 'PCNET32: aygýt mevcut deðil(2)!', []);
    {$ENDIF}
    Exit;
  end;

  AygitPCNET32.CipSurum := (AygitPCNET32.CipSurum shr 12) and $FFFF;

  case AygitPCNET32.CipSurum of

    $2420:  AygitPCNET32.CipAdi := CipAdi2420;
    $2430:  AygitPCNET32.CipAdi := CipAdi2430;
    $2621:  AygitPCNET32.CipAdi := CipAdi2621;
    $2623:  AygitPCNET32.CipAdi := CipAdi2623;
    $2624:  AygitPCNET32.CipAdi := CipAdi2624;
    $2625:  AygitPCNET32.CipAdi := CipAdi2625;
    $2626:  AygitPCNET32.CipAdi := CipAdi2626;
    $2627:  AygitPCNET32.CipAdi := CipAdi2627;
    else    AygitPCNET32.CipAdi := CipAdiBilinmiyor;
  end;

  {$IFDEF PCNET32_BILGI}
  SISTEM_MESAJ(RENK_MAVI, 'PCNET32 çip adý: ' + AygitPCNET32.CipAdi, []);
  {$ENDIF}

  for _i := 0 to 5 do
  begin

    AygitPCNET32.MACAdres[_i] := PortAl1(AygitPCNET32.TemelAdres + _i);
  end;
  AgBilgisi.MACAdres := AygitPCNET32.MACAdres;

  {$IFDEF PCNET32_BILGI}
  SISTEM_MESAJ_MAC(RENK_MAVI, 'PCNET32 MAC Adres: ', AygitPCNET32.MACAdres);
  {$ENDIF}

  // init_block içeriðini doldur
  BlokYukle._Mod := $80;
  BlokYukle.GDUzunluk := (GIDIS_HALKA_UZ_BIT or DONUS_HALKA_UZ_BIT);

  BlokYukle.MACAdres := AygitPCNET32.MACAdres;

  BlokYukle.Suzgec1 := 0;
  BlokYukle.Suzgec2 := 0;

  BlokYukle.DonusHalka := @DonusHalka[1];
  BlokYukle.GidisHalka := @GidisHalka[1];

  DonusHalkaBellekAdresi := GGercekBellek.Ayir(ETH_CERCEVE_U * DONUS_HALKA_U);
  _p := DonusHalkaBellekAdresi;
  for _i := 1 to DONUS_HALKA_U do
  begin

    DonusHalka[_i].Bellek := _p;
    DonusHalka[_i].Uzunluk := -(ETH_CERCEVE_U);
    DonusHalka[_i].Durum := RMD_OWN;
    _p += ETH_CERCEVE_U;
  end;
  BirSonrakiDonusSiraNo := 1;

  GidisHalkaBellekAdresi := GGercekBellek.Ayir(ETH_CERCEVE_U * GIDIS_HALKA_U);
  _p := GidisHalkaBellekAdresi;
  for _i := 1 to GIDIS_HALKA_U do
  begin

    GidisHalka[_i].Bellek := _p;
    GidisHalka[_i].Uzunluk := 0;
    GidisHalka[_i].Durum := 0;
    _p += ETH_CERCEVE_U;
  end;
  BirSonrakiGidisSiraNo := 1;

  // IRQ kanalýný aktifleþtir
  IRQIsleviAta(AygitPCNET32.IRQNo, @PCNET32YukleniciIslev);

  // aygýtý sýfýrla
  Sifirla;

  // 32 bit mod'a geç
  BCRYaz(20, 2);

  // full duplex
  _j := BCROku(9);
  _j := (_j and (not 3)) or 1;
  BCRYaz(9, _j);

  CSRYaz(INIT_BLOCK_ADDRESS_LOW, TSayi4(@BlokYukle) and $FFFF);
  CSRYaz(INIT_BLOCK_ADDRESS_HIGH, (TSayi4(@BlokYukle) shr 16) and $FFFF);

  CSRYaz(4, $915);
  CSRYaz(0, CSR_INIT);

  for _i := 0 to 100 do
  begin

    _j := CSROku(0);
    if((_j and CSR_IDON) <> 0) then Break;
  end;

  CSRYaz(0, CSR_IENA or CSR_STRT);

  // aygýtý yüklendi olarak iþaretle
  PCNET32Yuklendi := True;

  // aygýt yüklendi çýkýþ deðeri
  Result := 0;
end;

{==============================================================================
  PCNET32 að kartýna gelen bilgileri alýr
 ==============================================================================}
procedure VeriAl(ABellek: Isaretci; var AVeriUzunlugu: TSayi2);
var
  _Durum: TSayi2;
  _Uzunluk: TSayi4;
begin

  // belirtilen halkaya veri gelip gelmediðini kontrol et
  _Durum := DonusHalka[BirSonrakiDonusSiraNo].Durum;

  if((_Durum and RMD_OWN) = 0) then
  begin

    if(((_Durum shr 8) and $FF) = 3) then
    begin

      _Uzunluk := DonusHalka[BirSonrakiDonusSiraNo].MesajUz;
      _Uzunluk := _Uzunluk and $FFF;
      _Uzunluk -= 4;

      Tasi2(DonusHalka[BirSonrakiDonusSiraNo].Bellek, ABellek, _Uzunluk);
      AVeriUzunlugu := _Uzunluk;

      // halkayý veri alacak þekilde yeniden ayarla
      DonusHalka[BirSonrakiDonusSiraNo].Uzunluk := -(ETH_CERCEVE_U);
      DonusHalka[BirSonrakiDonusSiraNo].Durum := RMD_OWN;
      BirSonrakiDonusSiraNo := (BirSonrakiDonusSiraNo + 1) and DONUS_HALKA_MOD_MASKE;
    end else AVeriUzunlugu := 0;
  end else AVeriUzunlugu := 0;
end;

{==============================================================================
  PCNET32 IRQ iþlevi
 ==============================================================================}
procedure PCNET32YukleniciIslev;
var
  _Deger: TSayi4;
begin

  repeat

    _Deger := CSROku(0);
    _Deger := (_Deger and (CSR_ERR or CSR_RINT or CSR_TINT));
    if(_Deger = 0) then
    begin

      CSRYaz(0, (CSR_BABL or CSR_CERR or CSR_MISS or CSR_MERR or CSR_IDON or CSR_IENA));
      Exit;
    end;

    _Deger := _Deger and (not (CSR_IENA or CSR_TDMD or CSR_STOP or CSR_STRT or CSR_INIT));
    CSRYaz(0, _Deger);

    if((_Deger and CSR_RINT) = CSR_RINT) then
    begin

      {$IFDEF PCNET32_BILGI}
      SISTEM_MESAJ(RENK_KIRMIZI, 'PCNET32: veri alým tetiklendi.', []);
      {$ENDIF}
      //VeriAl;
    end
    else if((_Deger and CSR_TINT) = CSR_TINT) then
    begin

    {$IFDEF PCNET32_BILGI}
    SISTEM_MESAJ(RENK_KIRMIZI, 'PCNET32: veri gönderimi.', []);
    {$ENDIF}
    end;
  until 1 = 2;
end;

{==============================================================================
  PCNET32 að kartý üzerinden bilgi gönderimi yapar
 ==============================================================================}
procedure VeriGonder(AEthernetPaket: PEthernetPaket; AVeriUzunlugu: TSayi2);
var
  _Bellek: Isaretci;
begin

  // gönderilecek bilgi'nin yerleþtirileceði belleðe konumlan
  _Bellek := GidisHalka[BirSonrakiGidisSiraNo].Bellek;

  // ethernet paketini belleðe yerleþtir
  Tasi2(AEthernetPaket, _Bellek, AVeriUzunlugu);

  // gönderilecek bilgi'nin sahip olduðu ring deðerlerini belirle
  GidisHalka[BirSonrakiGidisSiraNo].Uzunluk := -(AVeriUzunlugu);
  GidisHalka[BirSonrakiGidisSiraNo].Degisik := 0;
  GidisHalka[BirSonrakiGidisSiraNo].Durum := (TMD_OWN or TMD_STP or TMD_ENP);

  // bir sonraki gönderim ringini belirle
  BirSonrakiGidisSiraNo := (BirSonrakiGidisSiraNo + 1) and GIDIS_HALKA_MOD_MASKE;
  if(BirSonrakiGidisSiraNo = 0) then Inc(BirSonrakiGidisSiraNo);

  CSRYaz(0, (CSR_IENA or CSR_TDMD));
end;

{==============================================================================
  pci aygýtýnýn ilk giriþ / çýkýþ (IO) deðerini alýr
 ==============================================================================}
function IlkIOPortNumarasiniAl(APCI: PPCI): TSayi2;
var
  _Adres, i: TSayi1;
  _Deger: TSayi4;
begin

  _Adres := $10;
  for i := 1 to 6 do
  begin

    _Deger := PCIOku4(APCI^.Yol, APCI^.Aygit, APCI^.Islev, _Adres);
    if((_Deger and 1) = 1) then Exit(_Deger and (not 3));

    _Adres += 4;
  end;

  Result := 0;
end;

{==============================================================================
  pci aygýtýný DMA'yý direkt eriþim saðlayýcý (bus master) olarak ayarlar
 ==============================================================================}
procedure DMAErisiminiAktiflestir(APCI: PPCI);
var
  _Deger: TSayi2;
begin

  _Deger := PCIOku2(APCI^.Yol, APCI^.Aygit, APCI^.Islev, 4);
  if((_Deger and 4) = 4) then Exit;
  PCIYaz2(APCI^.Yol, APCI^.Aygit, APCI^.Islev, 4, (_Deger and 4));
end;

{==============================================================================
  pci aygýtýnýn IRQ istek numarasýný alýr
 ==============================================================================}
function IRQNoAl(APCI: PPCI): TSayi1;
begin

  Result := PCIOku1(APCI^.Yol, APCI^.Aygit, APCI^.Islev, $3C) and $FF;
end;

function WIOCSROku(ASiraNo: TSayi4): TSayi4;
begin

  PortYaz2(AygitPCNET32.TemelAdres + PCNET32_WIO_RAP, ASiraNo);
  Result := PortAl2(AygitPCNET32.TemelAdres + PCNET32_WIO_RDP) and $FFFF;
end;

procedure WIOCSRYaz(ASiraNo, AVeri: TSayi4);
begin

  PortYaz2(AygitPCNET32.TemelAdres + PCNET32_WIO_RAP, ASiraNo);
  PortYaz2(AygitPCNET32.TemelAdres + PCNET32_WIO_RDP, AVeri);
end;

function WIOBCROku(ASiraNo: TSayi4): TSayi4;
begin

  PortYaz2(AygitPCNET32.TemelAdres + PCNET32_WIO_RAP, ASiraNo);
  Result := PortAl2(AygitPCNET32.TemelAdres + PCNET32_WIO_BDP) and $FFFF;
end;

procedure WIOBCRYaz(ASiraNo, AVeri: TSayi4);
begin

  PortYaz2(AygitPCNET32.TemelAdres + PCNET32_WIO_RAP, ASiraNo);
  PortYaz2(AygitPCNET32.TemelAdres + PCNET32_WIO_BDP, AVeri);
end;

function WIORAPOku: TSayi4;
begin

  Result := PortAl2(AygitPCNET32.TemelAdres + PCNET32_WIO_RAP) and $FFFF;
end;

procedure WIORAPYaz(AVeri: TSayi4);
begin

  PortYaz2(AygitPCNET32.TemelAdres + PCNET32_WIO_RAP, AVeri);
end;

procedure WIOSifirla;
begin

  PortAl2(AygitPCNET32.TemelAdres + PCNET32_WIO_RESET);
end;

function WIOKontrol: Boolean;
var
  _Deger: TSayi2;
begin

  PortYaz2(AygitPCNET32.TemelAdres + PCNET32_WIO_RAP, 88);
  _Deger := PortAl2(AygitPCNET32.TemelAdres + PCNET32_WIO_RAP);
  if(_Deger = 88) then Result := True else Result := False;
end;

function DWIOCSROku(ASiraNo: TSayi4): TSayi4;
begin

  PortYaz4(AygitPCNET32.TemelAdres + PCNET32_DWIO_RAP, ASiraNo);
  Result := PortAl4(AygitPCNET32.TemelAdres + PCNET32_DWIO_RDP) and $FFFF;
end;

procedure DWIOCSRYaz(ASiraNo, AVeri: TSayi4);
begin

  PortYaz4(AygitPCNET32.TemelAdres + PCNET32_DWIO_RAP, ASiraNo);
  PortYaz4(AygitPCNET32.TemelAdres + PCNET32_DWIO_RDP, AVeri);
end;

function DWIOBCROku(ASiraNo: TSayi4): TSayi4;
begin

  PortYaz4(AygitPCNET32.TemelAdres + PCNET32_DWIO_RAP, ASiraNo);
  Result := PortAl4(AygitPCNET32.TemelAdres + PCNET32_DWIO_BDP) and $FFFF;
end;

procedure DWIOBCRYaz(ASiraNo, AVeri: TSayi4);
begin

  PortYaz4(AygitPCNET32.TemelAdres + PCNET32_DWIO_RAP, ASiraNo);
  PortYaz4(AygitPCNET32.TemelAdres + PCNET32_DWIO_BDP, AVeri);
end;

function DWIORAPOku: TSayi4;
begin

  Result := PortAl4(AygitPCNET32.TemelAdres + PCNET32_DWIO_RAP) and $FFFF;
end;

procedure DWIORAPYaz(AVeri: TSayi4);
begin

  PortYaz4(AygitPCNET32.TemelAdres + PCNET32_DWIO_RAP, AVeri);
end;

procedure DWIOSifirla;
begin

  PortAl4(AygitPCNET32.TemelAdres + PCNET32_DWIO_RESET);
end;

function DWIOKontrol: Boolean;
var
  Val: TSayi4;
begin

  PortYaz4(AygitPCNET32.TemelAdres + PCNET32_DWIO_RAP, 88);
  Val := PortAl4(AygitPCNET32.TemelAdres + PCNET32_DWIO_RAP) and $FFFF;
  if(Val = 88) then Result := True else Result := False;
end;

end.
