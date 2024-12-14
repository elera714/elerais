{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: n_iletisim.pas
  Dosya İşlevi: ağ iletişim (soket) yönetim işlevlerini içerir
  İşlev No: 0x12 / 1

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit n_iletisim;

interface

type
  PIletisim = ^TIletisim;
  TIletisim = object
  private
    FBaglanti: TKimlik;
  public
    function Baglan(AProtokolTip: TProtokolTip; AHedefIPAdres: string;
      AHedefPort: TSayi4): TISayi4;
    function BagliMi: Boolean;
    function VeriUzunluguAl: TISayi4;
    function VeriOku(ABellek: Isaretci): TISayi4;
    procedure VeriYaz(ABellek: Isaretci; AUzunluk: TISayi4);
    function BaglantiyiKes: Boolean;
    property Baglanti: TKimlik read FBaglanti;
  end;

function _Baglan(AProtokolTip: TProtokolTip; AHedefIPAdres: string;
  AHedefPort: TSayi4): TISayi4;
function _BagliMi(ABaglanti: TKimlik): Boolean;
function _VeriUzunluguAl(ABaglanti: TKimlik): TISayi4;
function _VeriOku(ABaglanti: TKimlik; ABellek: Isaretci): TISayi4;
procedure _VeriYaz(ABaglanti: TKimlik; ABellek: Isaretci; AUzunluk: TISayi4);
function _BaglantiyiKes(ABaglanti: TKimlik): Boolean;

implementation

function TIletisim.Baglan(AProtokolTip: TProtokolTip; AHedefIPAdres: string;
  AHedefPort: TSayi4): TISayi4;
begin

  FBaglanti := _Baglan(AProtokolTip, AHedefIPAdres, AHedefPort);

  Result := FBaglanti;
end;

function TIletisim.BagliMi: Boolean;
begin

  Result := _BagliMi(FBaglanti);
end;

function TIletisim.VeriUzunluguAl: TISayi4;
begin

  Result := _VeriUzunluguAl(FBaglanti);
end;

function TIletisim.VeriOku(ABellek: Isaretci): TISayi4;
begin

  Result := _VeriOku(FBaglanti, ABellek);
end;

procedure TIletisim.VeriYaz(ABellek: Isaretci; AUzunluk: TISayi4);
begin

  _VeriYaz(FBaglanti, ABellek, AUzunluk);
end;

function TIletisim.BaglantiyiKes: Boolean;
begin

  Result := _BaglantiyiKes(FBaglanti);
  FBaglanti := -1;
end;

function _Baglan(AProtokolTip: TProtokolTip; AHedefIPAdres: string;
  AHedefPort: TSayi4): TISayi4; assembler;
asm
  push  DWORD AHedefPort
  push  DWORD AHedefIPAdres
  push  DWORD AProtokolTip
  mov   eax,ILETISIM_BAGLAN
  int   $34
  add   esp,12
end;

function _BagliMi(ABaglanti: TKimlik): Boolean; assembler;
asm
  push  DWORD ABaglanti
  mov   eax,ILETISIM_BAGLIMI
  int   $34
  add   esp,4
end;

function _VeriUzunluguAl(ABaglanti: TKimlik): TISayi4; assembler;
asm
  push  DWORD ABaglanti
  mov   eax,ILETISIM_VERIUZUNLUGU
  int   $34
  add   esp,4
end;

function _VeriOku(ABaglanti: TKimlik; ABellek: Isaretci): TISayi4; assembler;
asm
  push  DWORD ABellek
  push  DWORD ABaglanti
  mov   eax,ILETISIM_VERIOKU
  int   $34
  add   esp,8
end;

procedure _VeriYaz(ABaglanti: TKimlik; ABellek: Isaretci; AUzunluk: TISayi4); assembler;
asm
  push  DWORD AUzunluk
  push  DWORD ABellek
  push  DWORD ABaglanti
  mov   eax,ILETISIM_VERIYAZ
  int   $34
  add   esp,12
end;

function _BaglantiyiKes(ABaglanti: TKimlik): Boolean; assembler;
asm
  push  DWORD ABaglanti
  mov   eax,ILETISIM_BAGKES
  int   $34
  add   esp,4
end;

end.
