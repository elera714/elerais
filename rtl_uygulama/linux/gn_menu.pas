{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_menu.pas
  Dosya İşlevi: menü nesne işlevlerini içerir

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gn_menu;

interface

type
  PMenu = ^TMenu;
  TMenu = object
  private
    FKimlik: TKimlik;
  public
    function Olustur(ASol, AUst, AGenislik, AYukseklik, AElemanYukseklik: TISayi4): TKimlik;
    procedure Goster;
    procedure Gizle;
    procedure ElemanEkle(AElemanAdi: string; AResimSiraNo: TISayi4);
    function SeciliSiraNoAl: TISayi4;
    property Kimlik: TKimlik read FKimlik;
  end;

function MenuOlustur(ASol, AUst, AGenislik, AYukseklik, AElemanYukseklik: TISayi4): TKimlik; assembler;
procedure MenuGoster(AKimlik: TKimlik); assembler;
procedure MenuGizle(AKimlik: TKimlik); assembler;
procedure MenuElemanEkle(AKimlik: TKimlik; AElemanAdi: string; AResimSiraNo: TISayi4); assembler;
function MenuSeciliSiraNoAl(AKimlik: TKimlik): TISayi4; assembler;

implementation

function TMenu.Olustur(ASol, AUst, AGenislik, AYukseklik, AElemanYukseklik: TISayi4): TKimlik;
begin

  FKimlik := MenuOlustur(ASol, AUst, AYukseklik, AYukseklik, AElemanYukseklik);
  Result := FKimlik;
end;

procedure TMenu.Goster;
begin

  MenuGoster(FKimlik);
end;

procedure TMenu.Gizle;
begin

  MenuGizle(FKimlik);
end;

procedure TMenu.ElemanEkle(AElemanAdi: string; AResimSiraNo: TISayi4);
begin

  MenuElemanEkle(FKimlik, AElemanAdi, AResimSiraNo);
end;

function TMenu.SeciliSiraNoAl: TISayi4;
begin

  Result := MenuSeciliSiraNoAl(FKimlik);
end;

function MenuOlustur(ASol, AUst, AGenislik, AYukseklik, AElemanYukseklik: TISayi4): TKimlik;
asm
  push  DWORD AElemanYukseklik
  push  DWORD AYukseklik
  push  DWORD AGenislik
  push  DWORD AUst
  push  DWORD ASol
  mov   eax,MENU_OLUSTUR
  int   $34
  add   esp,20
end;

procedure MenuGoster(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,MENU_GOSTER
  int   $34
  add   esp,4
end;

procedure MenuGizle(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,MENU_GIZLE
  int   $34
  add   esp,4
end;

procedure MenuElemanEkle(AKimlik: TKimlik; AElemanAdi: string; AResimSiraNo: TISayi4);
asm
  push  DWORD AResimSiraNo
  push  DWORD AElemanAdi
  push  DWORD AKimlik
  mov   eax,MENU_YAZ_ELEMANEKLE
  int   $34
  add   esp,12
end;

function MenuSeciliSiraNoAl(AKimlik: TKimlik): TISayi4;
asm
  push  DWORD AKimlik
  mov   eax,MENU_AL_SECILISN
  int   $34
  add   esp,4
end;

end.
