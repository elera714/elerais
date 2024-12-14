{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_kaydirmacubugu.pas
  Dosya İşlevi: kaydırma çubuğu (TScrollBar) yönetim işlevlerini içerir

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gn_kaydirmacubugu;

interface

type
  PKaydirmaCubugu = ^TKaydirmaCubugu;
  TKaydirmaCubugu = object
  private
    FKimlik: TKimlik;
  public
    function Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
      AYon: TYon): TKimlik;
    procedure DegerleriBelirle(AAltDeger, AUstDeger: TSayi4);
    procedure Goster;
    procedure Hizala(AHiza: THiza);
    property Kimlik: TKimlik read FKimlik;
  end;

function _KaydirmaCubuguOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  AYon: TYon): TKimlik; assembler;
procedure _KaydirmaCubuguDegerleriBelirle(AKimlik: TKimlik; AAltDeger, AUstDeger: TSayi4); assembler;
procedure _KaydirmaCubuguGoster(AKimlik: TKimlik); assembler;
procedure _KaydirmaCubuguHizala(AKimlik: TKimlik; AHiza: THiza); assembler;

implementation

function TKaydirmaCubugu.Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  AYon: TYon): TKimlik;
begin

  FKimlik := _KaydirmaCubuguOlustur(AAtaKimlik, ASol, AUst, AGenislik, AYukseklik, AYon);
  Result := FKimlik;
end;

procedure TKaydirmaCubugu.DegerleriBelirle(AAltDeger, AUstDeger: TSayi4);
begin

  _KaydirmaCubuguDegerleriBelirle(FKimlik, AAltDeger, AUstDeger);
end;

procedure TKaydirmaCubugu.Goster;
begin

  _KaydirmaCubuguGoster(FKimlik);
end;

procedure TKaydirmaCubugu.Hizala(AHiza: THiza);
begin

  _KaydirmaCubuguHizala(FKimlik, AHiza);
end;

function _KaydirmaCubuguOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  AYon: TYon): TKimlik;
asm
  push  DWORD AYon
  push  DWORD AYukseklik
  push  DWORD AGenislik
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AAtaKimlik
  mov   eax,KAYDIRMACUBUGU_OLUSTUR
  int   $34
  add   esp,24
end;

procedure _KaydirmaCubuguGoster(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,KAYDIRMACUBUGU_GOSTER
  int   $34
  add   esp,4
end;

procedure _KaydirmaCubuguHizala(AKimlik: TKimlik; AHiza: THiza);
asm
  push  DWORD AHiza
  push  DWORD AKimlik
  mov   eax,KAYDIRMACUBUGU_HIZALA
  int   $34
  add   esp,8
end;

procedure _KaydirmaCubuguDegerleriBelirle(AKimlik: TKimlik; AAltDeger, AUstDeger: TSayi4);
asm
  push  DWORD AUstDeger
  push  DWORD AAltDeger
  push  DWORD AKimlik
  mov   eax,KAYDIRMACUBUGU_YAZ_ARALIK
  int   $34
  add   esp,12
end;

end.
