{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: n_genel.pas
  Dosya İşlevi: genel program yönetim işlevlerini içerir
  İşlev No:

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit n_genel;

interface

type
  PGenel = ^TGenel;
  TGenel = object
  private
    FBaglanti: TKimlik;
  public
    // bellek işlevleri
    procedure CekirdekBellekBilgisiAl(ACekirdekBaslangicAdresi, ACekirdekBitisAdresi,
      ACekirdekUzunlugu: Isaretci); assembler;
    procedure GenelBellekBilgisiAl(AToplamRAMBlok, AAyrilmisRAMBlok, AKullanilanRAMBlok,
      ABosRAMBlok, ARAMBlokUzunlugu: Isaretci); assembler;
    procedure BellekIcerikOku(AKaynakBellek, AHedefBellek: Isaretci; AMiktar: TSayi4); assembler;

    // ağ işlevleri
    procedure AgBilgisiAl(AAgBilgisi: PAgBilgisi); assembler;

    // arp işlevleri
    function ARPKayitSayisiAl: TSayi4; assembler;
    function ARPKayitBilgisiAl(ASiraNo: TSayi4; AARPKayit: TARPKayit): TISayi4; assembler;

    // fare işlevleri
    procedure FarePozisyonunuAl(ANokta: PNokta); assembler;

    // dosya işlevleri
    function _FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
      var ADosyaArama: TDosyaArama): TISayi4; assembler;
    function _FindNext(var ADosyaArama: TDosyaArama): TISayi4; assembler;
    function _FindClose(var ADosyaArama: TDosyaArama): TISayi4; assembler;
    procedure _Assign(out ADosyaKimlik: TKimlik; const ADosyaAdi: string); assembler;
    procedure _Reset(ADosyaKimlik: TKimlik); assembler;
    function _IOResult: TISayi4; assembler;
    function _EOF(ADosyaKimlik: TKimlik): Boolean; assembler;
    function _FileSize(ADosyaKimlik: TKimlik): TISayi4; assembler;
    procedure _FileRead(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci); assembler;
    procedure _Close(ADosyaKimlik: TKimlik); assembler;
    procedure _ReWrite(ADosyaKimlik: TKimlik); assembler;
    procedure _Write(ADosyaKimlik: TKimlik; const AVeri: string); assembler;
    procedure _DeleteFile(ADosyaAdi: string); assembler;
    procedure _RemoveDir(AKlasorAdi: string); assembler;

    // görsel nesne işlevleri
    function GorselNesneKimlikAl(KonumA1, KonumB1: TISayi4): TISayi4; assembler;
    function GorselNesneAdiAl(KonumA1, KonumB1: TISayi4; ANesneAdi: Isaretci): TISayi4; assembler;

    // bu işlevin alt yapı çalışması yapılacak
    function GorselNesneBilgisiAl(AKimlik: TKimlik; AHedefBellek: Isaretci): TISayi4; assembler;

    // pci işlevleri
    function ToplamPCIAygitSayisiAl: TISayi4; assembler;
    procedure PCIAygitBilgisiAl(AAygitSiraNo: TSayi4; ABellek: Isaretci); assembler;
    function PCIOku1(AYol, AAygit, AIslev, ASiraNo: TSayi4): TSayi1; assembler;
    function PCIOku2(AYol, AAygit, AIslev, ASiraNo: TSayi4): TSayi2; assembler;
    function PCIOku4(AYol, AAygit, AIslev, ASiraNo: TSayi4): TSayi4; assembler;
    procedure PCIYaz1(AYol, AAygit, AIslev, ASiraNo: TSayi4; ADeger: TSayi1); assembler;
    procedure PCIYaz2(AYol, AAygit, AIslev, ASiraNo: TSayi4; ADeger: TSayi2); assembler;
    procedure PCIYaz4(AYol, AAygit, AIslev, ASiraNo, ADeger: TSayi4); assembler;

    // olay işlevleri
    function OlayAl(var AOlay: TOlay): TISayi4; assembler;
    function OlayBekle(var AOlay: TOlay): TISayi4; assembler;

    // sayaç işlevleri
    procedure SaatAl(ABellek: Isaretci); assembler;
    procedure TarihAl(ABellek: Isaretci); assembler;
    procedure Bekle(AMiliSaniye: TSayi4); assembler;

    // sistem işlevleri
    procedure SistemBilgisiAl(ABellekAdresi: Isaretci); assembler;
    procedure IslemciBilgisiAl(ABellekAdresi: Isaretci); assembler;

    // sistem sürücü / klasör / dosya bilgi işlevleri
    procedure SistemYapiBilgisiAl(ABilgiSN: TSayi4; var ABellek: string); assembler;
    procedure YenidenBaslat; assembler;
    procedure BilgisayariKapat; assembler;
  end;

implementation

var
  FDeger: TSayi4;

procedure TGenel.CekirdekBellekBilgisiAl(ACekirdekBaslangicAdresi,
  ACekirdekBitisAdresi, ACekirdekUzunlugu: Isaretci); assembler;
asm
  push  DWORD ACekirdekUzunlugu
  push  DWORD ACekirdekBitisAdresi
  push  DWORD ACekirdekBaslangicAdresi
  mov   eax,BELLEK_CEKIRDEKBILGISI
  int   $34
  add   esp,12
end;

procedure TGenel.GenelBellekBilgisiAl(AToplamRAMBlok, AAyrilmisRAMBlok,
  AKullanilanRAMBlok, ABosRAMBlok, ARAMBlokUzunlugu: Isaretci); assembler;
asm
  push  DWORD ARAMBlokUzunlugu
  push  DWORD ABosRAMBlok
  push  DWORD AKullanilanRAMBlok
  push  DWORD AAyrilmisRAMBlok
  push  DWORD AToplamRAMBlok
  mov   eax,BELLEK_GENELBILGI
  int   $34
  add   esp,20
end;

procedure TGenel.BellekIcerikOku(AKaynakBellek, AHedefBellek: Isaretci;
  AMiktar: TSayi4); assembler;
asm
  push  DWORD AMiktar
  push  DWORD AHedefBellek
  push  DWORD AKaynakBellek
  mov   eax,BELLEK_ICERIKOKU
  int   $34
  add   esp,12
end;

procedure TGenel.AgBilgisiAl(AAgBilgisi: PAgBilgisi); assembler;
asm
  push  DWORD AAgBilgisi
  mov   eax,AG_BILGISIAL
  int   $34
  add   esp,4
end;

function TGenel.ARPKayitSayisiAl: TSayi4; assembler;
asm
  mov   eax,ARP_KAYITSAYISIAL
  int   $34
end;

function TGenel.ARPKayitBilgisiAl(ASiraNo: TSayi4; AARPKayit: TARPKayit): TISayi4; assembler;
asm
  push  DWORD AARPKayit
  push  DWORD ASiraNo
  mov   eax,ARP_KAYITBILGISIAL
  int   $34
  add   esp,8
end;

procedure TGenel.FarePozisyonunuAl(ANokta: PNokta); assembler;
asm
  push  ANokta
  mov   eax,FARE_KONUMAL
  int   $34
  add   esp,4
end;

function TGenel._FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
  var ADosyaArama: TDosyaArama): TISayi4; assembler;
asm
  push	DWORD ADosyaArama
  push	DWORD ADosyaOzellik
  push	DWORD AAramaSuzgec
  mov   eax,DOSYA_ARAMAYABASLA
  int	  $34
  add	  esp,12
end;

function TGenel._FindNext(var ADosyaArama: TDosyaArama): TISayi4; assembler;
asm
  push  DWORD ADosyaArama
  mov	  eax,DOSYA_SONRAKINIARA
  int	  $34
  add	  esp,4
end;

function TGenel._FindClose(var ADosyaArama: TDosyaArama): TISayi4; assembler;
asm
  push	DWORD ADosyaArama
  mov	  eax,DOSYA_ARAMASONLANDIR
  int	  $34
  add	  esp,4
end;

procedure TGenel._Assign(out ADosyaKimlik: TKimlik; const ADosyaAdi: string); assembler;
asm
  push  DWORD ADosyaAdi
  push	DWORD ADosyaKimlik
  mov	  eax,DOSYA_TANIMLA
  int	  $34
  add	  esp,8
end;

procedure TGenel._Reset(ADosyaKimlik: TKimlik); assembler;
asm
  push	DWORD ADosyaKimlik
  mov	  eax,DOSYA_AC
  int	  $34
  add	  esp,4
end;

function TGenel._IOResult: TISayi4; assembler;
asm
  mov	  eax,DOSYA_ISLEMKONTROL
  int	  $34
end;

function TGenel._EOF(ADosyaKimlik: TKimlik): Boolean; assembler;
asm
  push	DWORD ADosyaKimlik
  mov	  eax,DOSYA_DOSYASONU
  int	  $34
  add	  esp,4
end;

function TGenel._FileSize(ADosyaKimlik: TKimlik): TISayi4; assembler;
asm
  push	DWORD ADosyaKimlik
  mov	  eax,DOSYA_DOSYAUZUNLUGU
  int	  $34
  add	  esp,4
end;

// Read olarak değiştirilecek. Aşağıdaki hatayı veriyor
// fileh.inc(7,15) Error: overloaded identifier "Read" isn't a function
procedure TGenel._FileRead(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci); assembler;
asm
  push	DWORD AHedefBellek
  push  DWORD ADosyaKimlik
  mov	  eax,DOSYA_OKU
  int	  $34
  add	  esp,8
end;

procedure TGenel._Close(ADosyaKimlik: TKimlik); assembler;
asm
  push	DWORD ADosyaKimlik
  mov	  eax,DOSYA_KAPAT
  int	  $34
  add	  esp,4
end;

procedure TGenel._ReWrite(ADosyaKimlik: TKimlik); assembler;
asm
  push	DWORD ADosyaKimlik
  mov	  eax,DOSYA_OLUSTUR
  int	  $34
  add	  esp,4
end;

procedure TGenel._Write(ADosyaKimlik: TKimlik; const AVeri: string); assembler;
asm
  push  DWORD AVeri
  push	DWORD ADosyaKimlik
  mov	  eax,DOSYA_VERIYAZ
  int	  $34
  add	  esp,8
end;

procedure TGenel._DeleteFile(ADosyaAdi: string); assembler;
asm
  push  DWORD ADosyaAdi
  mov   eax,DOSYA_DOSYASIL
  int   $34
  add   esp,4
end;

procedure TGenel._RemoveDir(AKlasorAdi: string); assembler;
asm
  push  DWORD AKlasorAdi
  mov   eax,DOSYA_KLASORSIL
  int   $34
  add   esp,4
end;

function TGenel.GorselNesneKimlikAl(KonumA1, KonumB1: TISayi4): TISayi4; assembler;
asm
  push  DWORD KonumB1
  push  DWORD KonumA1
  mov   eax,GORSELNESNE_KIMLIKAL
  int   $34
  add   esp,8
end;

function TGenel.GorselNesneAdiAl(KonumA1, KonumB1: TISayi4; ANesneAdi: Isaretci): TISayi4; assembler;
asm
  push  DWORD ANesneAdi
  push  DWORD KonumB1
  push  DWORD KonumA1
  mov   eax,GORSELNESNE_NESNEADIAL
  int   $34
  add   esp,12
end;

function TGenel.GorselNesneBilgisiAl(AKimlik: TKimlik; AHedefBellek: Isaretci): TISayi4; assembler;
asm
  push  DWORD AHedefBellek
  push  DWORD AKimlik
  mov   eax,GORSELNESNE_BILGIAL
  int   $34
  add   esp,8
end;

function TGenel.ToplamPCIAygitSayisiAl: TISayi4; assembler;
asm
  mov   eax,PCI_TOPLAMAYGITSAYISI
  int   $34
end;

procedure TGenel.PCIAygitBilgisiAl(AAygitSiraNo: TSayi4; ABellek: Isaretci); assembler;
asm
  push  DWORD ABellek
  push  DWORD AAygitSiraNo
  mov   eax,PCI_AYGITBILGISIAL
  int   $34
  add   esp,8
end;

function TGenel.PCIOku1(AYol, AAygit, AIslev, ASiraNo: TSayi4): TSayi1; assembler;
asm
  push  DWORD ASiraNo
  push  DWORD AIslev
  push  DWORD AAygit
  push  DWORD AYol
  mov   eax,PCI_OKU1
  int   $34
  add   esp,16
  and   eax,$FF
end;

function TGenel.PCIOku2(AYol, AAygit, AIslev, ASiraNo: TSayi4): TSayi2; assembler;
asm
  push  DWORD ASiraNo
  push  DWORD AIslev
  push  DWORD AAygit
  push  DWORD AYol
  mov   eax,PCI_OKU2
  int   $34
  add   esp,16
  and   eax,$FFFF
end;

function TGenel.PCIOku4(AYol, AAygit, AIslev, ASiraNo: TSayi4): TSayi4; assembler;
asm
  push  DWORD ASiraNo
  push  DWORD AIslev
  push  DWORD AAygit
  push  DWORD AYol
  mov   eax,PCI_OKU4
  int   $34
  add   esp,16
end;

procedure TGenel.PCIYaz1(AYol, AAygit, AIslev, ASiraNo: TSayi4; ADeger: TSayi1); assembler;
asm
  push  eax
  xor eax,eax
  mov al,ADeger
  mov   FDeger,eax
  pop eax
  push  DWORD FDeger
  push  DWORD ASiraNo
  push  DWORD AIslev
  push  DWORD AAygit
  push  DWORD AYol
  mov   eax,PCI_YAZ1
  int   $34
  add   esp,20
end;

procedure TGenel.PCIYaz2(AYol, AAygit, AIslev, ASiraNo: TSayi4; ADeger: TSayi2); assembler;
asm
  push  eax
  xor eax,eax
  mov ax,ADeger
  mov   FDeger,eax
  pop eax
  push  DWORD FDeger
  push  DWORD ASiraNo
  push  DWORD AIslev
  push  DWORD AAygit
  push  DWORD AYol
  mov   eax,PCI_YAZ1
  int   $34
  add   esp,20
end;

procedure TGenel.PCIYaz4(AYol, AAygit, AIslev, ASiraNo, ADeger: TSayi4); assembler;
asm
  push  ADeger
  push  ASiraNo
  push  AIslev
  push  AAygit
  push  AYol
  mov   eax,PCI_YAZ4
  int   $34
  add   esp,20
end;

function TGenel.OlayAl(var AOlay: TOlay): TISayi4; assembler;
asm
  push  DWORD AOlay
  mov   eax,OLAY_AL
  int   $34
  add   esp,4
end;

function TGenel.OlayBekle(var AOlay: TOlay): TISayi4; assembler;
asm
  push  DWORD AOlay
  mov   eax,OLAY_BEKLE
  int   $34
  add   esp,4
end;

procedure TGenel.SaatAl(ABellek: Isaretci); assembler;
asm
  push  DWORD ABellek
  mov   eax,SAYAC_SAAT_AL
  int   $34
  add   esp,4
end;

procedure TGenel.TarihAl(ABellek: Isaretci); assembler;
asm
  push  DWORD ABellek
  mov   eax,SAYAC_TARIH_AL
  int   $34
  add   esp,4
end;

procedure TGenel.Bekle(AMiliSaniye: TSayi4); assembler;
asm
  push  DWORD AMiliSaniye
  mov   eax,SAYAC_BEKLE
  int   $34
  add   esp,4
end;

procedure TGenel.SistemBilgisiAl(ABellekAdresi: Isaretci); assembler;
asm
  push  DWORD ABellekAdresi
  mov	  eax,SISTEMBILGISI_AL
  int	  $34
  add	  esp,4
end;

procedure TGenel.IslemciBilgisiAl(ABellekAdresi: Isaretci); assembler;
asm
  push  DWORD ABellekAdresi
  mov	  eax,ISLEMCIBILGISI_AL
  int	  $34
  add	  esp,4
end;

procedure TGenel.SistemYapiBilgisiAl(ABilgiSN: TSayi4; var ABellek: string); assembler;
asm
  push  DWORD ABellek
  push  DWORD ABilgiSN
  mov	  eax,SISTEM_YAPIBILGISI_AL
  int	  $34
  add	  esp,4
end;

procedure TGenel.YenidenBaslat; assembler;
asm
  mov	  eax,SISTEM_YENIDENBASLAT
  int	  $34
end;

procedure TGenel.BilgisayariKapat; assembler;
asm
  mov	  eax,SISTEM_BILGISAYARIKAPAT
  int	  $34
end;

end.
