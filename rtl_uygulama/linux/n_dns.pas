{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: n_dns.pas
  Dosya İşlevi: dns yönetim işlevlerini içerir
  İşlev No: 0x12 / 2

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit n_dns;

interface

type
  PDNS = ^TDNS;
  TDNS = object
  public
    FKimlik: TKimlik;
    procedure Olustur;
    procedure Sorgula(ADNSAdres: string);
    function DurumAl: TDNSDurum;
    procedure IcerikAl(AHedefBellek: Isaretci);
    procedure Kapat;
    procedure YokEt;
    property Kimlik: TKimlik read FKimlik;
  end;

function _Olustur: TISayi4;
procedure _Sorgula(AKimlik: TKimlik; ADNSAdres: string);
function _DurumAl(AKimlik: TKimlik): TDNSDurum;
procedure _IcerikAl(AKimlik: TKimlik; AHedefBellek: Isaretci);
procedure _Kapat(AKimlik: TKimlik);
procedure _YokEt(AKimlik: TKimlik);

implementation

procedure TDNS.Olustur;
begin

  FKimlik := _Olustur;
end;

procedure TDNS.Sorgula(ADNSAdres: string);
begin

  _Sorgula(FKimlik, ADNSAdres);
end;

function TDNS.DurumAl: TDNSDurum;
begin

  Result := _DurumAl(FKimlik);
end;

procedure TDNS.IcerikAl(AHedefBellek: Isaretci);
begin

  _IcerikAl(FKimlik, AHedefBellek);
end;

procedure TDNS.Kapat;
begin

  _Kapat(FKimlik);
end;

procedure TDNS.YokEt;
begin

  _YokEt(FKimlik);

  FKimlik := -1;
end;

function _Olustur: TISayi4; assembler;
asm
  mov   eax,ILETISIM_DNS_OLUSTUR
  int   $34
end;

procedure _Sorgula(AKimlik: TKimlik; ADNSAdres: string); assembler;
asm
  push  DWORD ADNSAdres
  push  DWORD AKimlik
  mov   eax,ILETISIM_DNS_SORGULA
  int   $34
  add   esp,8
end;

function _DurumAl(AKimlik: TKimlik): TDNSDurum; assembler;
asm
  push  DWORD AKimlik
  mov   eax,ILETISIM_DNS_DURUMAL
  int   $34
  add   esp,4
end;

procedure _IcerikAl(AKimlik: TKimlik; AHedefBellek: Isaretci); assembler;
asm
  push  DWORD AHedefBellek
  push  DWORD AKimlik
  mov   eax,ILETISIM_DNS_ICERIKAL
  int   $34
  add   esp,8
end;

procedure _Kapat(AKimlik: TKimlik); assembler;
asm
  push  DWORD AKimlik
  mov   eax,ILETISIM_DNS_KAPAT
  int   $34
  add   esp,4
end;

procedure _YokEt(AKimlik: TKimlik); assembler;
asm
  push  DWORD AKimlik
  mov   eax,ILETISIM_DNS_YOKET
  int   $34
  add   esp,4
end;

end.
