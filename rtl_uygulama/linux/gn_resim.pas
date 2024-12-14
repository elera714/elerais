{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_resim.pas
  Dosya İşlevi: resim (TImage) nesne yönetim işlevlerini içerir

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gn_resim;

interface

type
  PResim = ^TResim;
  TResim = object
  private
    FKimlik: TKimlik;
  public
    function Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
      ADosyaYolu: string): TKimlik;
    procedure Goster;
    procedure Hizala(AHiza: THiza);
    procedure Degistir(ADosyaYolu: string);
    procedure TuvaleSigdir(ATuvaleSigdir: LongBool);
    property Kimlik: TKimlik read FKimlik;
  end;

function _ResimOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ADosyaYolu: string): TKimlik; assembler;
procedure _ResimGoster(AKimlik: TKimlik); assembler;
procedure _ResimHizala(AKimlik: TKimlik; AHiza: THiza); assembler;
procedure _ResimDegistir(AKimlik: TKimlik; ADosyaYolu: string); assembler;
procedure _ResimTuvaleSigdir(AKimlik: TKimlik; ATuvaleSigdir: LongBool); assembler;

implementation

function TResim.Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ADosyaYolu: string): TKimlik;
begin

  FKimlik := _ResimOlustur(AAtaKimlik, ASol, AUst, AGenislik, AYukseklik, ADosyaYolu);
  Result := FKimlik;
end;

procedure TResim.Goster;
begin

  _ResimGoster(FKimlik);
end;

procedure TResim.Hizala(AHiza: THiza);
begin

  _ResimHizala(FKimlik, AHiza);
end;

procedure TResim.Degistir(ADosyaYolu: string);
begin

  _ResimDegistir(FKimlik, ADosyaYolu);
end;

procedure TResim.TuvaleSigdir(ATuvaleSigdir: LongBool);
begin

  _ResimTuvaleSigdir(FKimlik, ATuvaleSigdir);
end;

function _ResimOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ADosyaYolu: string): TKimlik;
asm
  push  DWORD ADosyaYolu
  push  DWORD AYukseklik
  push  DWORD AGenislik
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AAtaKimlik
  mov   eax,RESIM_OLUSTUR
  int   $34
  add   esp,24
end;

procedure _ResimGoster(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,RESIM_GOSTER
  int   $34
  add   esp,4
end;

procedure _ResimHizala(AKimlik: TKimlik; AHiza: THiza);
asm
  push  DWORD AHiza
  push  DWORD AKimlik
  mov   eax,RESIM_HIZALA
  int   $34
  add   esp,8
end;

procedure _ResimDegistir(AKimlik: TKimlik; ADosyaYolu: string);
asm
  push  DWORD ADosyaYolu
  push  DWORD AKimlik
  mov   eax,RESIM_YAZ_RESIM
  int   $34
  add   esp,8
end;

procedure _ResimTuvaleSigdir(AKimlik: TKimlik; ATuvaleSigdir: LongBool);
asm
  push  DWORD ATuvaleSigdir
  push  DWORD AKimlik
  mov   eax,RESIM_YAZ_TUVALESIGDIR
  int   $34
  add   esp,8
end;

end.
