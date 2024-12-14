{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_renksecici.pas
  Dosya İşlevi: renk seçim yönetim işlevlerini içerir

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gn_renksecici;

interface

type
  PRenkSecici = ^TRenkSecici;
  TRenkSecici = object
  private
    FKimlik: TKimlik;
  public
    function Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
    procedure Goster;
    property Kimlik: TKimlik read FKimlik;
  end;

function _RenkSeciciOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik; assembler;
procedure _ResimSeciciGoster(AKimlik: TKimlik); assembler;

implementation

function TRenkSecici.Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
begin

  FKimlik := _RenkSeciciOlustur(AAtaKimlik, ASol, AUst, AGenislik, AYukseklik);
  Result := FKimlik;
end;

procedure TRenkSecici.Goster;
begin

  _ResimSeciciGoster(FKimlik);
end;

function _RenkSeciciOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
asm
  push  DWORD AYukseklik
  push  DWORD AGenislik
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AAtaKimlik
  mov   eax,RENKSECICI_OLUSTUR
  int   $34
  add   esp,20
end;

procedure _ResimSeciciGoster(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,RENKSECICI_GOSTER
  int   $34
  add   esp,4
end;

end.
