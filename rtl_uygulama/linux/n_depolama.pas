{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: n_depolama.pas
  Dosya İşlevi: depolama aygıtlarını yönetir
  İşlev No: 0x0F

  Güncelleme Tarihi: 08/11/2024

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
    function MantiksalDepolamaAygitBilgisiAl(AAygitKimlik: TSayi4;
      AMantiksalSurucu3: PMantiksalSurucu3): Boolean;
    function FizikselDepolamaAygitSayisiAl: TSayi4;
    function FizikselDepolamaAygitBilgisiAl(AAygitKimlik: TSayi4;
      AFizikselSurucu3: PFizikselSurucu3): Boolean;
    function FizikselDepolamaVeriOku(AAygitKimlik, ASektorNo, ASektorSayisi: TSayi4;
      ABellek: Isaretci): TISayi4;
    function FizikselDepolamaVeriYaz(AAygitKimlik, ASektorNo, ASektorSayisi: TSayi4;
      ABellek: Isaretci): TISayi4;
  end;

function _MantiksalDepolamaAygitSayisiAl: TSayi4; assembler;
function _MantiksalDepolamaAygitBilgisiAl(AAygitKimlik: TSayi4;
  AMantiksalSurucu3: PMantiksalSurucu3): Boolean; assembler;
function _FizikselDepolamaAygitSayisiAl: TSayi4; assembler;
function _FizikselDepolamaAygitBilgisiAl(AAygitKimlik: TSayi4;
  AFizikselSurucu3: PFizikselSurucu3): Boolean; assembler;
function _FizikselDepolamaVeriOku(AAygitKimlik, ASektorNo, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4; assembler;
function _FizikselDepolamaVeriYaz(AAygitKimlik, ASektorNo, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4; assembler;

implementation

function TDepolama.MantiksalDepolamaAygitSayisiAl: TSayi4;
begin

  Result := _MantiksalDepolamaAygitSayisiAl;
end;

function TDepolama.MantiksalDepolamaAygitBilgisiAl(AAygitKimlik: TSayi4;
  AMantiksalSurucu3: PMantiksalSurucu3): Boolean;
begin

  Result := _MantiksalDepolamaAygitBilgisiAl(AAygitKimlik, AMantiksalSurucu3);
end;

function TDepolama.FizikselDepolamaAygitSayisiAl: TSayi4;
begin

  Result := _FizikselDepolamaAygitSayisiAl;
end;

function TDepolama.FizikselDepolamaAygitBilgisiAl(AAygitKimlik: TSayi4;
  AFizikselSurucu3: PFizikselSurucu3): Boolean;
begin

  Result := _FizikselDepolamaAygitBilgisiAl(AAygitKimlik, AFizikselSurucu3);
end;

function TDepolama.FizikselDepolamaVeriOku(AAygitKimlik, ASektorNo, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4;
begin

  Result := _FizikselDepolamaVeriOku(AAygitKimlik, ASektorNo, ASektorSayisi, ABellek);
end;

function TDepolama.FizikselDepolamaVeriYaz(AAygitKimlik, ASektorNo, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4;
begin

  Result := _FizikselDepolamaVeriYaz(AAygitKimlik, ASektorNo, ASektorSayisi, ABellek);
end;

function _MantiksalDepolamaAygitSayisiAl: TSayi4;
asm
  mov	  eax,DEPOLAMA_MDEPO_AYG_SAYISIAL
  int	  $34
end;

function _MantiksalDepolamaAygitBilgisiAl(AAygitKimlik: TSayi4;
  AMantiksalSurucu3: PMantiksalSurucu3): Boolean;
asm
  push  AMantiksalSurucu3
  push  AAygitKimlik
  mov   eax,DEPOLAMA_MDEPO_AYG_BILGIAL
  int   $34
  add   esp,8
end;

function _FizikselDepolamaAygitSayisiAl: TSayi4;
asm
  mov	  eax,DEPOLAMA_FDEPO_AYG_SAYISIAL
  int	  $34
end;

function _FizikselDepolamaAygitBilgisiAl(AAygitKimlik: TSayi4;
  AFizikselSurucu3: PFizikselSurucu3): Boolean;
asm
  push  AFizikselSurucu3
  push  AAygitKimlik
  mov   eax,DEPOLAMA_FDEPO_AYG_BILGIAL
  int   $34
  add   esp,8
end;

function _FizikselDepolamaVeriOku(AAygitKimlik, ASektorNo, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4;
asm
  push  ABellek
  push  ASektorSayisi
  push  ASektorNo
  push  AAygitKimlik
  mov   eax,DEPOLAMA_FDEPO_VERIOKU
  int   $34
  add   esp,16
end;

function _FizikselDepolamaVeriYaz(AAygitKimlik, ASektorNo, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4;
asm
  push  ABellek
  push  ASektorSayisi
  push  ASektorNo
  push  AAygitKimlik
  mov   eax,DEPOLAMA_FDEPO_VERIYAZ
  int   $34
  add   esp,16
end;

end.
