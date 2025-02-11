{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_giriskutusu.pas
  Dosya İşlevi: giriş kutusu (TEdit) yönetim işlevlerini içerir

  Güncelleme Tarihi: 11/02/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gn_giriskutusu;

interface

type
  PGirisKutusu = ^TGirisKutusu;
  TGirisKutusu = object
  private
    FKimlik: TKimlik;
    FYazilamaz: LongBool;
    FSadeceRakam: LongBool;
    procedure SadeceRakam0(ADeger: LongBool);
    procedure Yazilamaz0(ADeger: LongBool);
  public
    function Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
      AIcerikDeger: string): TKimlik;
    procedure Goster;
    procedure Odaklan;
    function IcerikAl: string;
    procedure IcerikYaz(AIcerikDeger: string);
    property Kimlik: TKimlik read FKimlik;
    property Yazilamaz: LongBool read FYazilamaz write Yazilamaz0;
    property SadeceRakam: LongBool read FSadeceRakam write SadeceRakam0;
  end;

function GirisKutusuOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik,
  AYukseklik: TISayi4; AIcerikDeger: string): TKimlik; assembler;
procedure GirisKutusuGoster(AKimlik: TKimlik); assembler;
procedure GirisKutusuIcerikAl(AKimlik: TKimlik; AHedefBellek: Isaretci); assembler;
procedure GirisKutusuIcerikYaz(AKimlik: TKimlik; AIcerikDeger: string); assembler;
procedure GirisKutusuYazilamaz0(AKimlik: TKimlik; AYazilamaz: LongBool); assembler;
procedure GirisKutusuSadeceRakam0(AKimlik: TKimlik; ASadeceSayi: LongBool); assembler;
procedure GirisKutusuOdaklan(AKimlik: TKimlik); assembler;

implementation

function TGirisKutusu.Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  AIcerikDeger: string): TKimlik;
begin

  FKimlik := GirisKutusuOlustur(AAtaKimlik, ASol, AUst, AGenislik, AYukseklik, AIcerikDeger);

  FYazilamaz := False;
  FSadeceRakam := False;

  Result := FKimlik;
end;

procedure TGirisKutusu.Goster;
begin

  GirisKutusuGoster(FKimlik);
end;

procedure TGirisKutusu.Odaklan;
begin

  GirisKutusuOdaklan(FKimlik);
end;

function TGirisKutusu.IcerikAl: string;
var
  s: string;
begin

  GirisKutusuIcerikAl(FKimlik, Isaretci(@s[0]));
  Result := s;
end;

procedure TGirisKutusu.IcerikYaz(AIcerikDeger: string);
begin

  GirisKutusuIcerikYaz(FKimlik, AIcerikDeger);
end;

procedure TGirisKutusu.Yazilamaz0(ADeger: LongBool);
begin

  if(FYazilamaz = ADeger) then Exit;

  FYazilamaz := ADeger;
  GirisKutusuYazilamaz0(FKimlik, FYazilamaz);
end;

procedure TGirisKutusu.SadeceRakam0(ADeger: LongBool);
begin

  if(FSadeceRakam = ADeger) then Exit;

  FSadeceRakam := ADeger;
  GirisKutusuSadeceRakam0(FKimlik, FSadeceRakam);
end;

function GirisKutusuOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik,
  AYukseklik: TISayi4; AIcerikDeger: string): TKimlik; assembler;
asm
  push  DWORD AIcerikDeger
  push  DWORD AYukseklik
  push  DWORD AGenislik
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AAtaKimlik
  mov   eax,GIRISKUTUSU_OLUSTUR
  int   $34
  add   esp,24
end;

procedure GirisKutusuGoster(AKimlik: TKimlik); assembler;
asm
  push  DWORD AKimlik
  mov   eax,GIRISKUTUSU_GOSTER
  int   $34
  add   esp,4
end;

procedure GirisKutusuIcerikAl(AKimlik: TKimlik; AHedefBellek: Isaretci); assembler;
asm
  push  DWORD AHedefBellek
  push  DWORD AKimlik
  mov   eax,GIRISKUTUSU_AL_ICERIK
  int   $34
  add   esp,8
end;

procedure GirisKutusuIcerikYaz(AKimlik: TKimlik; AIcerikDeger: string); assembler;
asm
  push  DWORD AIcerikDeger
  push  DWORD AKimlik
  mov   eax,GIRISKUTUSU_YAZ_ICERIK
  int   $34
  add   esp,8
end;

procedure GirisKutusuYazilamaz0(AKimlik: TKimlik; AYazilamaz: LongBool); assembler;
asm
  push  DWORD AYazilamaz
  push  DWORD AKimlik
  mov   eax,GIRISKUTUSU_YAZ_SALTOKUNUR
  int   $34
  add   esp,8
end;

procedure GirisKutusuSadeceRakam0(AKimlik: TKimlik; ASadeceSayi: LongBool); assembler;
asm
  push  DWORD ASadeceSayi
  push  DWORD AKimlik
  mov   eax,GIRISKUTUSU_YAZ_SADECESAYI
  int   $34
  add   esp,8
end;

procedure GirisKutusuOdaklan(AKimlik: TKimlik); assembler;
asm
  push  DWORD AKimlik
  mov   eax,GIRISKUTUSU_YAZ_ODAK
  int   $34
  add   esp,4
end;

end.
