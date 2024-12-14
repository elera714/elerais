{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_onaykutusu.pas
  Dosya İşlevi: onay kutusu (TCheckBox) yönetim işlevlerini içerir

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gn_onaykutusu;

interface

type
  POnayKutusu = ^TOnayKutusu;
  TOnayKutusu = object
  private
    FKimlik: TKimlik;
  public
    function Olustur(AAtaKimlik: TKimlik; ASol, AUst: TISayi4; ABaslik: string): TKimlik;
    procedure Goster;
    property Kimlik: TKimlik read FKimlik;
  end;

function _OnayKutusuOlustur(AAtaKimlik: TKimlik; ASol, AUst: TISayi4; ABaslik: string): TKimlik; assembler;
procedure _OnayKutusuGoster(AKimlik: TKimlik); assembler;

implementation

function TOnayKutusu.Olustur(AAtaKimlik: TKimlik; ASol, AUst: TISayi4; ABaslik: string): TKimlik;
begin

  FKimlik := _OnayKutusuOlustur(AAtaKimlik, ASol, AUst, ABaslik);
  Result := FKimlik;
end;

procedure TOnayKutusu.Goster;
begin

  _OnayKutusuGoster(FKimlik);
end;

function _OnayKutusuOlustur(AAtaKimlik: TKimlik; ASol, AUst: TISayi4; ABaslik: string): TKimlik;
asm
  push  DWORD ABaslik
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AAtaKimlik
  mov   eax,ONAYKUTUSU_OLUSTUR
  int   $34
  add   esp,16
end;

procedure _OnayKutusuGoster(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,ONAYKUTUSU_GOSTER
  int   $34
  add   esp,4
end;

end.
