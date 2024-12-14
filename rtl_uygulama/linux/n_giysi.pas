{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: n_giysi.pas
  Dosya İşlevi: giysi (skin) yönetim işlevlerini içerir
  İşlev No: 0x11

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit n_giysi;

interface

type
  PGiysi = ^TGiysi;
  TGiysi = object
  public
    function Toplam: TISayi4;
    procedure AdAl(ASiraNo: TSayi4; ABellek: Isaretci);
    function AktifSiraNoAl: TISayi4;
    procedure Aktiflestir(ASiraNo: TSayi4);
  end;

function _ToplamAl: TSayi4; assembler;
procedure _AdAl(ASiraNo: TSayi4; ABellek: Isaretci); assembler;
function _AktifSiraNoAl: TISayi4; assembler;
procedure _Aktiflestir(ASiraNo: TSayi4); assembler;

implementation

function TGiysi.Toplam: TISayi4;
begin

  Result := _ToplamAl;
end;

procedure TGiysi.AdAl(ASiraNo: TSayi4; ABellek: Isaretci);
begin

  _AdAl(ASiraNo, ABellek);
end;

function TGiysi.AktifSiraNoAl: TISayi4;
begin

  Result := _AktifSiraNoAl;
end;

procedure TGiysi.Aktiflestir(ASiraNo: TSayi4);
begin

  _Aktiflestir(ASiraNo);
end;

function _ToplamAl: TSayi4; assembler;
asm
  mov   eax,GIYSI_TOPLAMAL
  int   $34
end;

procedure _AdAl(ASiraNo: TSayi4; ABellek: Isaretci); assembler;
asm
  push  DWORD ABellek
  push  DWORD ASiraNo
  mov   eax,GIYSI_ADAL
  int   $34
  add   esp,8
end;

function _AktifSiraNoAl: TISayi4; assembler;
asm
  mov   eax,GIYSI_AKTIFSIRANOAL
  int   $34
end;

procedure _Aktiflestir(ASiraNo: TSayi4); assembler;
asm
  push  DWORD ASiraNo
  mov   eax,GIYSI_AKTIFLESTIR
  int   $34
  add   esp,4
end;

end.
