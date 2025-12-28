{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: n_depolama.pas
  Dosya İşlevi: depolama aygıtlarını yönetir
  İşlev No: 0x0F

  Güncelleme Tarihi: 09/01/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit n_depolama;

interface

uses n_genel;

type
  PDepolama = ^TDepolama;
  TDepolama = object
  private
    FAd: string;
    FGenel: TGenel;
  public
    function MantiksalDepolamaAygitSayisiAl: TSayi4;
    function MantiksalDepolamaAygitBilgisiAl(ASiraNo: TSayi4;
      AMantiksalDepolama: PMantiksalDepolama3): Boolean;
    function FizikselDepolamaAygitSayisiAl: TSayi4;
    function FizikselDepolamaAygitBilgisiAl(ASiraNo: TSayi4;
      AFizikselDepolama: PFizikselDepolama3): TSayi4;
    function FizikselDepolamaVeriOku(AKimlik, ASektorNo, ASektorSayisi: TSayi4;
      ABellek: Isaretci): TISayi4;
    function FizikselDepolamaVeriYaz(AKimlik, ASektorNo, ASektorSayisi: TSayi4;
      ABellek: Isaretci): TISayi4;
  end;

function _MantiksalDepolamaAygitSayisiAl: TSayi4; assembler;
function _MantiksalDepolamaAygitBilgisiAl(ASiraNo: TSayi4;
  AMantiksalDepolama: PMantiksalDepolama3): Boolean; assembler;
function _FizikselDepolamaAygitSayisiAl: TSayi4; assembler;
function _FizikselDepolamaAygitBilgisiAl(ASiraNo: TSayi4;
  AFizikselDepolama: PFizikselDepolama3): TSayi4; assembler;
function _FizikselDepolamaVeriOku(AKimlik, ASektorNo, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4; assembler;
function _FizikselDepolamaVeriYaz(AKimlik, ASektorNo, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4; assembler;

implementation

function TDepolama.MantiksalDepolamaAygitSayisiAl: TSayi4;
begin

  Result := _MantiksalDepolamaAygitSayisiAl;
end;

function TDepolama.MantiksalDepolamaAygitBilgisiAl(ASiraNo: TSayi4;
  AMantiksalDepolama: PMantiksalDepolama3): Boolean;
begin

  Result := _MantiksalDepolamaAygitBilgisiAl(ASiraNo, AMantiksalDepolama);
end;

function TDepolama.FizikselDepolamaAygitSayisiAl: TSayi4;
begin

  Result := _FizikselDepolamaAygitSayisiAl;
end;

function TDepolama.FizikselDepolamaAygitBilgisiAl(ASiraNo: TSayi4;
  AFizikselDepolama: PFizikselDepolama3): TSayi4;
begin

  Result := _FizikselDepolamaAygitBilgisiAl(ASiraNo, AFizikselDepolama);
end;

function TDepolama.FizikselDepolamaVeriOku(AKimlik, ASektorNo, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4;
begin

  Result := _FizikselDepolamaVeriOku(AKimlik, ASektorNo, ASektorSayisi, ABellek);
end;

function TDepolama.FizikselDepolamaVeriYaz(AKimlik, ASektorNo, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4;
begin

  Result := _FizikselDepolamaVeriYaz(AKimlik, ASektorNo, ASektorSayisi, ABellek);
end;

function _MantiksalDepolamaAygitSayisiAl: TSayi4;
asm
  mov	  eax,DEPOLAMA_MDEPO_AYG_SAYISIAL
  int	  $34
end;

function _MantiksalDepolamaAygitBilgisiAl(ASiraNo: TSayi4;
  AMantiksalDepolama: PMantiksalDepolama3): Boolean;
asm
  push  DWORD AMantiksalDepolama
  push  DWORD ASiraNo
  mov   eax,DEPOLAMA_MDEPO_AYG_BILGIAL
  int   $34
  add   esp,8
end;

function _FizikselDepolamaAygitSayisiAl: TSayi4;
asm
  mov	  eax,DEPOLAMA_FDEPO_AYG_SAYISIAL
  int	  $34
end;

function _FizikselDepolamaAygitBilgisiAl(ASiraNo: TSayi4;
  AFizikselDepolama: PFizikselDepolama3): TSayi4;
asm
  push  DWORD AFizikselDepolama
  push  DWORD ASiraNo
  mov   eax,DEPOLAMA_FDEPO_AYG_BILGIAL
  int   $34
  add   esp,8
end;

function _FizikselDepolamaVeriOku(AKimlik, ASektorNo, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4;
asm
  push  DWORD ABellek
  push  DWORD ASektorSayisi
  push  DWORD ASektorNo
  push  DWORD AKimlik
  mov   eax,DEPOLAMA_FDEPO_VERIOKU
  int   $34
  add   esp,16
end;

function _FizikselDepolamaVeriYaz(AKimlik, ASektorNo, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4;
asm
  push  DWORD ABellek
  push  DWORD ASektorSayisi
  push  DWORD ASektorNo
  push  DWORD AKimlik
  mov   eax,DEPOLAMA_FDEPO_VERIYAZ
  int   $34
  add   esp,16
end;

end.
