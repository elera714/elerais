{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: n_zamanlayici.pas
  Dosya İşlevi: zamanlayıcı nesne işlevlerini içerir

  Güncelleme Tarihi: 19/10/2019

 ==============================================================================}
{$mode objfpc}
unit n_zamanlayici;

interface

type
  PZamanlayici = ^TZamanlayici;
  TZamanlayici = object
  private
  public
    FKimlik: TKimlik;
    function Olustur(AMilisaniye: TSayi4): TKimlik;
    procedure Baslat;
    procedure Durdur;
    property Kimlik: TKimlik read FKimlik;
  end;

function _ZamanlayiciOlustur(AMilisaniye: TSayi4): TKimlik; assembler;
procedure _ZamanlayiciBaslat(AKimlik: TKimlik); assembler;
procedure _ZamanlayiciDurdur(AKimlik: TKimlik); assembler;

implementation

function TZamanlayici.Olustur(AMilisaniye: TSayi4): TKimlik;
begin

  FKimlik := _ZamanlayiciOlustur(AMilisaniye);
  Result := FKimlik;
end;

procedure TZamanlayici.Baslat;
begin

  _ZamanlayiciBaslat(FKimlik);
end;

procedure TZamanlayici.Durdur;
begin

  _ZamanlayiciDurdur(FKimlik);
end;

{$asmmode intel}
function _ZamanlayiciOlustur(AMilisaniye: TSayi4): TKimlik;
asm
  push	DWORD AMilisaniye
  mov	  eax,ZAMANLAYICI_OLUSTUR
  int	  $34
  add	  esp,4
end;

procedure _ZamanlayiciBaslat(AKimlik: TKimlik);
asm
  push	DWORD AKimlik
  mov	  eax,ZAMANLAYICI_BASLAT
  int	  $34
  add	  esp,4
end;

procedure _ZamanlayiciDurdur(AKimlik: TKimlik);
asm
  push	DWORD AKimlik
  mov	  eax,ZAMANLAYICI_DURDUR
  int	  $34
  add	  esp,4
end;

end.
