{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_durumcubugu.pas
  Dosya İşlevi: durum çubuğu (TStatusBar) yönetim işlevlerini içerir

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gn_durumcubugu;

interface

type
  PDurumCubugu = ^TDurumCubugu;
  TDurumCubugu = object
  private
    FKimlik: TKimlik;
  public
    function Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
      ADurumYazisi: string): TKimlik;
    procedure DurumYazisiDegistir(ADurumYazisi: string);
    procedure Goster;
    property Kimlik: TKimlik read FKimlik;
  end;

function _DurumCubuguOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ADurumYazisi: string): TKimlik; assembler;
procedure _DurumCubuguYazisiDegistir(AKimlik: TKimlik; ADurumYazisi: string); assembler;
procedure _DurumCubuguGoster(AKimlik: TKimlik); assembler;

implementation

function TDurumCubugu.Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ADurumYazisi: string): TKimlik;
begin

  FKimlik := _DurumCubuguOlustur(AAtaKimlik, ASol, AUst, AGenislik, AYukseklik, ADurumYazisi);
  Result := FKimlik;
end;

procedure TDurumCubugu.DurumYazisiDegistir(ADurumYazisi: string);
begin

  _DurumCubuguYazisiDegistir(FKimlik, ADurumYazisi);
end;

function _DurumCubuguOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ADurumYazisi: string): TKimlik;
asm
  push  DWORD ADurumYazisi
  push  DWORD AYukseklik
  push  DWORD AGenislik
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AAtaKimlik
  mov   eax,DURUMCUBUGU_OLUSTUR
  int   $34
  add   esp,24
end;

procedure TDurumCubugu.Goster;
begin

  _DurumCubuguGoster(FKimlik);
end;

procedure _DurumCubuguGoster(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,DURUMCUBUGU_GOSTER
  int   $34
  add   esp,4
end;

procedure _DurumCubuguYazisiDegistir(AKimlik: TKimlik; ADurumYazisi: string);
asm
  push  DWORD ADurumYazisi
  push  DWORD AKimlik
  mov   eax,DURUMCUBUGU_YAZ_YAZI
  int   $34
  add   esp,8
end;

end.
