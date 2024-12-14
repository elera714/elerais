{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_araccubugu.pas
  Dosya İşlevi: araç çubuğu (TToolBar) nesne yönetim işlevlerini içerir

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gn_araccubugu;

interface

type
  PAracCubugu = ^TAracCubugu;
  TAracCubugu = object
  private
    FKimlik: TKimlik;
  public
    function Olustur(AAtaKimlik: TKimlik): TKimlik;
    procedure Goster;
    function DugmeEkle(AResimSiraNo: TISayi4): TKimlik;
    property Kimlik: TKimlik read FKimlik;
  end;

function _AracCubuguOlustur(AAtaKimlik: TKimlik): TKimlik; assembler;
procedure _AracCubuguGoster(AKimlik: TKimlik); assembler;
function _AracCubuguDugmeEkle(AKimlik: TKimlik; AResimSiraNo: TISayi4): TKimlik; assembler;

implementation

function TAracCubugu.Olustur(AAtaKimlik: TKimlik): TKimlik;
begin

  FKimlik := _AracCubuguOlustur(AAtaKimlik);
  Result := FKimlik;
end;

procedure TAracCubugu.Goster;
begin

  _AracCubuguGoster(FKimlik);
end;

function TAracCubugu.DugmeEkle(AResimSiraNo: TISayi4): TKimlik;
begin

  Result := _AracCubuguDugmeEkle(FKimlik, AResimSiraNo);
end;

function _AracCubuguOlustur(AAtaKimlik: TKimlik): TKimlik; assembler;
asm
  push  DWORD AAtaKimlik
  mov   eax,ARACCUBUGU_OLUSTUR
  int   $34
  add   esp,4
end;

procedure _AracCubuguGoster(AKimlik: TKimlik); assembler;
asm
  push  DWORD AKimlik
  mov   eax,ARACCUBUGU_GOSTER
  int   $34
  add   esp,4
end;

function _AracCubuguDugmeEkle(AKimlik: TKimlik; AResimSiraNo: TISayi4): TKimlik; assembler;
asm
  push  DWORD AResimSiraNo
  push  DWORD AKimlik
  mov   eax,ARACCUBUGU_YAZ_DUGMEEKLE
  int   $34
  add   esp,8
end;

end.
