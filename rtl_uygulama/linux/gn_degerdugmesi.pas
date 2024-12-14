{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_degerdugmesi.pas
  Dosya İşlevi: artırma / eksiltme (TUpDown) düğme yönetim işlevlerini içerir

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gn_degerdugmesi;

interface

type
  PDegerDugmesi = ^TDegerDugmesi;
  TDegerDugmesi = object
  private
    FKimlik: TKimlik;
  public
    function Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
    procedure Goster;
    property Kimlik: TKimlik read FKimlik;
  end;

function _DegerDugmesiOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik; assembler;
procedure _DegerDugmesiGoster(AKimlik: TKimlik); assembler;

implementation

function TDegerDugmesi.Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
begin

  FKimlik := _DegerDugmesiOlustur(AAtaKimlik, ASol, AUst, AGenislik, AYukseklik);
  Result := FKimlik;
end;

procedure TDegerDugmesi.Goster;
begin

  _DegerDugmesiGoster(FKimlik);
end;

function _DegerDugmesiOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
asm
  push  DWORD AYukseklik
  push  DWORD AGenislik
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AAtaKimlik
  mov   eax,DEGERDUGMESI_OLUSTUR
  int   $34
  add   esp,20
end;

procedure _DegerDugmesiGoster(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,DEGERDUGMESI_GOSTER
  int   $34
  add   esp,4
end;

end.
