{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_giriskutusu.pas
  Dosya İşlevi: giriş kutusu (TEdit) yönetim işlevlerini içerir

  Güncelleme Tarihi: 20/09/2024

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
    function IcerikAl: string;
    procedure IcerikYaz(AIcerikDeger: string);
    property Kimlik: TKimlik read FKimlik;
    property Yazilamaz: LongBool read FYazilamaz write Yazilamaz0;
    property SadeceRakam: LongBool read FSadeceRakam write SadeceRakam0;
  end;

function _GirisKutusuOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik,
  AYukseklik: TISayi4; AIcerikDeger: string): TKimlik; assembler;
procedure _GirisKutusuGoster(AKimlik: TKimlik); assembler;
procedure _GirisKutusuIcerikAl(AKimlik: TKimlik; AHedefBellek: Isaretci); assembler;
procedure _GirisKutusuIcerikYaz(AKimlik: TKimlik; AIcerikDeger: string); assembler;
procedure _GirisKutusuYazilamaz0(AKimlik: TKimlik; AYazilamaz: LongBool); assembler;
procedure _GirisKutusuSadeceRakam0(AKimlik: TKimlik; ASadeceSayi: LongBool); assembler;

implementation

function TGirisKutusu.Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  AIcerikDeger: string): TKimlik;
begin

  FKimlik := _GirisKutusuOlustur(AAtaKimlik, ASol, AUst, AGenislik, AYukseklik, AIcerikDeger);

  FYazilamaz := False;
  FSadeceRakam := False;

  Result := FKimlik;
end;

procedure TGirisKutusu.Goster;
begin

  _GirisKutusuGoster(FKimlik);
end;

function TGirisKutusu.IcerikAl: string;
var
  s: string;
begin

  _GirisKutusuIcerikAl(FKimlik, Isaretci(@s[0]));
  Result := s;
end;

procedure TGirisKutusu.IcerikYaz(AIcerikDeger: string);
begin

  _GirisKutusuIcerikYaz(FKimlik, AIcerikDeger);
end;

procedure TGirisKutusu.Yazilamaz0(ADeger: LongBool);
begin

  if(FYazilamaz = ADeger) then Exit;

  FYazilamaz := ADeger;
  _GirisKutusuYazilamaz0(FKimlik, FYazilamaz);
end;

procedure TGirisKutusu.SadeceRakam0(ADeger: LongBool);
begin

  if(FSadeceRakam = ADeger) then Exit;

  FSadeceRakam := ADeger;
  _GirisKutusuSadeceRakam0(FKimlik, FSadeceRakam);
end;

function _GirisKutusuOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik,
  AYukseklik: TISayi4; AIcerikDeger: string): TKimlik;
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

procedure _GirisKutusuGoster(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,GIRISKUTUSU_GOSTER
  int   $34
  add   esp,4
end;

procedure _GirisKutusuIcerikAl(AKimlik: TKimlik; AHedefBellek: Isaretci);
asm
  push  DWORD AHedefBellek
  push  DWORD AKimlik
  mov   eax,GIRISKUTUSU_AL_ICERIK
  int   $34
  add   esp,8
end;

procedure _GirisKutusuIcerikYaz(AKimlik: TKimlik; AIcerikDeger: string);
asm
  push  DWORD AIcerikDeger
  push  DWORD AKimlik
  mov   eax,GIRISKUTUSU_YAZ_ICERIK
  int   $34
  add   esp,8
end;

procedure _GirisKutusuYazilamaz0(AKimlik: TKimlik; AYazilamaz: LongBool);
asm
  push  DWORD AYazilamaz
  push  DWORD AKimlik
  mov   eax,GIRISKUTUSU_YAZ_SALTOKUNUR
  int   $34
  add   esp,8
end;

procedure _GirisKutusuSadeceRakam0(AKimlik: TKimlik; ASadeceSayi: LongBool);
asm
  push  DWORD ASadeceSayi
  push  DWORD AKimlik
  mov   eax,GIRISKUTUSU_YAZ_SADECESAYI
  int   $34
  add   esp,8
end;

end.
