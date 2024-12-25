{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_masaustu.pas
  Dosya İşlevi: masaüstü nesne işlevlerini içerir

  Güncelleme Tarihi: 24/12/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gn_masaustu;

interface

type
  PMasaustu = ^TMasaustu;
  TMasaustu = object
  private
    FKimlik: TKimlik;
    function ToplamMasaustuSayisiniAl: TISayi4;
    function AktifMasaustunuAl: TKimlik;
    procedure MasaustunuAktiflestir(AKimlik: TKimlik);
  public
    function Olustur(AMasaustuAdi: string): TKimlik;
    function Goster: TKimlik;
    procedure Guncelle;
    procedure MasaustuRenginiDegistir(ARenk: TRenk);
    procedure MasaustuResminiDegistir(ADosyaTamYol: string);
    property Kimlik: TKimlik read FKimlik;
  published
    property AktifMasaustu: TKimlik read AktifMasaustunuAl write MasaustunuAktiflestir;
    property ToplamMasaustuSayisi: TISayi4 read ToplamMasaustuSayisiniAl;
  end;

function _MasaustuOlustur(AMasaustuAdi: string): TKimlik; assembler;
function _MasaustunuGoster(AKimlik: TKimlik): TKimlik; assembler;
function _ToplamMasaustuSayisiniAl: TISayi4; assembler;
function _AktifMasaustunuAl: TKimlik; assembler;
function _MasaustunuAktiflestir(AKimlik: TKimlik): Boolean; assembler;
procedure _MasaustunuGuncelle(AKimlik: TKimlik); assembler;
procedure _MasaustuRenginiDegistir(AKimlik: TKimlik; ARenk: TRenk); assembler;
procedure _MasaustuResminiDegistir(AKimlik: TKimlik; ADosyaTamYol: string); assembler;

implementation

function TMasaustu.Olustur(AMasaustuAdi: string): TKimlik;
begin

  FKimlik := _MasaustuOlustur(AMasaustuAdi);
  Result := FKimlik;
end;

function TMasaustu.Goster: TKimlik;
begin

  Result := _MasaustunuGoster(FKimlik);
end;

function TMasaustu.ToplamMasaustuSayisiniAl: TISayi4;
begin

  Result := _ToplamMasaustuSayisiniAl;
end;

function TMasaustu.AktifMasaustunuAl: TKimlik;
begin

  FKimlik := _AktifMasaustunuAl;
  Result := FKimlik;
end;

procedure TMasaustu.MasaustunuAktiflestir(AKimlik: TKimlik);
begin

  _MasaustunuAktiflestir(AKimlik);
end;

procedure TMasaustu.Guncelle;
begin

  _MasaustunuGuncelle(FKimlik);
end;

procedure TMasaustu.MasaustuRenginiDegistir(ARenk: TRenk);
begin

  _MasaustuRenginiDegistir(FKimlik, ARenk);
end;

procedure TMasaustu.MasaustuResminiDegistir(ADosyaTamYol: string);
begin

  _MasaustuResminiDegistir(FKimlik, ADosyaTamYol);
end;

function _MasaustuOlustur(AMasaustuAdi: string): TKimlik;
asm
  push  DWORD AMasaustuAdi
  mov	  eax,MASAUSTU_OLUSTUR
  int	  $34
  add	  esp,4
end;

function _MasaustunuGoster(AKimlik: TKimlik): TKimlik;
asm
  push	DWORD AKimlik
  mov	  eax,MASAUSTU_GOSTER
  int	  $34
  add	  esp,4
end;

function _ToplamMasaustuSayisiniAl: TISayi4;
asm
  mov	  eax,MASAUSTU_AL_TOPLAM
  int	  $34
end;

function _AktifMasaustunuAl: TKimlik;
asm
  mov	  eax,MASAUSTU_AL_AKTIF
  int	  $34
end;

function _MasaustunuAktiflestir(AKimlik: TKimlik): Boolean;
asm
  push	DWORD AKimlik
  mov	  eax,MASAUSTU_YAZ_AKTIF
  int	  $34
  add	  esp,4
end;

procedure _MasaustunuGuncelle(AKimlik: TKimlik);
asm
  push	DWORD AKimlik
  mov	  eax,MASAUSTU_YAZ_GUNCEL
  int	  $34
  add	  esp,4
end;

procedure _MasaustuRenginiDegistir(AKimlik: TKimlik; ARenk: TRenk);
asm
  push	DWORD ARenk
  push  DWORD AKimlik
  mov	  eax,MASAUSTU_YAZ_RENK
  int	  $34
  add	  esp,8
end;

procedure _MasaustuResminiDegistir(AKimlik: TKimlik; ADosyaTamYol: string);
asm
  push	DWORD ADosyaTamYol
  push  DWORD AKimlik
  mov	  eax,MASAUSTU_YAZ_RESIM
  int	  $34
  add	  esp,8
end;

end.
