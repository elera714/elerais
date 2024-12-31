{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: n_iletisim.pas
  Dosya İşlevi: ağ iletişim (soket) yönetim işlevlerini içerir
  İşlev No: 0x12 (SAC_ILETISIM)

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit n_iletisim;

interface

type
  PIletisim = ^TIletisim;
  TIletisim = object
  private
    FKimlik: TKimlik;
  public
    { TODO - ileride "constructor Create; / "Destructor Destroy;" olacak }
    procedure Constructor0;
    procedure Destructor0;
    function Olustur(AProtokolTipi: TProtokolTipi; AHedefIPAdres: string;
      AHedefPort: TSayi4): TISayi4;
    function Baglan: TISayi4;
    function BagliMi: Boolean;
    function VeriUzunluguAl: TISayi4;
    function VeriOku(ABellek: Isaretci): TISayi4;
    procedure VeriYaz(ABellek: Isaretci; AUzunluk: TISayi4);
    function BaglantiyiKes: Boolean;
    property Kimlik: TKimlik read FKimlik;
  end;

function _Olustur(AProtokolTipi: TProtokolTipi; AHedefIPAdres: string;
  AHedefPort: TSayi4): TISayi4;
function _Baglan(AKimlik: TKimlik): TISayi4;
function _BagliMi(AKimlik: TKimlik): Boolean;
function _VeriUzunluguAl(AKimlik: TKimlik): TISayi4;
function _VeriOku(AKimlik: TKimlik; ABellek: Isaretci): TISayi4;
procedure _VeriYaz(AKimlik: TKimlik; ABellek: Isaretci; AUzunluk: TISayi4);
function _BaglantiyiKes(AKimlik: TKimlik): Boolean;

implementation

procedure TIletisim.Constructor0;
begin

  FKimlik := HATA_KIMLIK;
end;

procedure TIletisim.Destructor0;
begin

  FKimlik := HATA_KIMLIK;
end;

function TIletisim.Olustur(AProtokolTipi: TProtokolTipi; AHedefIPAdres: string;
  AHedefPort: TSayi4): TISayi4;
begin

  FKimlik := _Olustur(AProtokolTipi, AHedefIPAdres, AHedefPort);

  Result := FKimlik;
end;

function TIletisim.Baglan: TISayi4;
begin

  Result := _Baglan(FKimlik);
end;

function TIletisim.BagliMi: Boolean;
begin

  Result := _BagliMi(FKimlik);
end;

function TIletisim.VeriUzunluguAl: TISayi4;
begin

  Result := _VeriUzunluguAl(FKimlik);
end;

function TIletisim.VeriOku(ABellek: Isaretci): TISayi4;
begin

  Result := _VeriOku(FKimlik, ABellek);
end;

procedure TIletisim.VeriYaz(ABellek: Isaretci; AUzunluk: TISayi4);
begin

  _VeriYaz(FKimlik, ABellek, AUzunluk);
end;

function TIletisim.BaglantiyiKes: Boolean;
begin

  Result := _BaglantiyiKes(FKimlik);

  FKimlik := -1;
end;

function _Olustur(AProtokolTipi: TProtokolTipi; AHedefIPAdres: string;
  AHedefPort: TSayi4): TISayi4; assembler;
asm
  push  DWORD AHedefPort
  push  DWORD AHedefIPAdres
  push  DWORD AProtokolTipi
  mov   eax,ILETISIM_OLUSTUR
  int   $34
  add   esp,12
end;

function _Baglan(AKimlik: TKimlik): TISayi4; assembler;
asm
  push  DWORD AKimlik
  mov   eax,ILETISIM_BAGLAN
  int   $34
  add   esp,4
end;

function _BagliMi(AKimlik: TKimlik): Boolean; assembler;
asm
  push  DWORD AKimlik
  mov   eax,ILETISIM_BAGLIMI
  int   $34
  add   esp,4
end;

function _VeriUzunluguAl(AKimlik: TKimlik): TISayi4; assembler;
asm
  push  DWORD AKimlik
  mov   eax,ILETISIM_VERIUZUNLUGU
  int   $34
  add   esp,4
end;

function _VeriOku(AKimlik: TKimlik; ABellek: Isaretci): TISayi4; assembler;
asm
  push  DWORD ABellek
  push  DWORD AKimlik
  mov   eax,ILETISIM_VERIOKU
  int   $34
  add   esp,8
end;

procedure _VeriYaz(AKimlik: TKimlik; ABellek: Isaretci; AUzunluk: TISayi4); assembler;
asm
  push  DWORD AUzunluk
  push  DWORD ABellek
  push  DWORD AKimlik
  mov   eax,ILETISIM_VERIYAZ
  int   $34
  add   esp,12
end;

function _BaglantiyiKes(AKimlik: TKimlik): Boolean; assembler;
asm
  push  DWORD AKimlik
  mov   eax,ILETISIM_BAGKES
  int   $34
  add   esp,4
end;

end.
