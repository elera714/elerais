{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_sayfakontrol
  Dosya İşlevi: sayfa kontrol (TPageControl) yönetim işlevlerini içerir

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gn_sayfakontrol;

interface

type
  PSayfaKontrol = ^TSayfaKontrol;
  TSayfaKontrol = object
  private
    FKimlik: TKimlik;
  public
    function Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
    procedure Goster;
    procedure Gizle;
    procedure SayfaEkle(ABaslik: string);
    procedure EtiketEkle(ASayfaNo, ASol, AUst: TISayi4; ABaslik: string);
    property Kimlik: TKimlik read FKimlik;
  end;

function _SayfaKontrolOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik; assembler;
procedure _SayfaKontrolGoster(AKimlik: TKimlik); assembler;
procedure _SayfaKontrolGizle(AKimlik: TKimlik); assembler;
procedure _SayfaKontrolBaslikEkle(AKimlik: TKimlik; ABaslik: string); assembler;
procedure _SayfaKontrolEtiketEkle(AKimlik: TKimlik; ASayfaNo, ASol, AUst: TISayi4; ABaslik: string); assembler;

implementation

function TSayfaKontrol.Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
begin

  FKimlik := _SayfaKontrolOlustur(AAtaKimlik, ASol, AUst, AGenislik, AYukseklik);
  Result := FKimlik;
end;

procedure TSayfaKontrol.Goster;
begin

  _SayfaKontrolGoster(FKimlik);
end;

procedure TSayfaKontrol.Gizle;
begin

  _SayfaKontrolGizle(FKimlik);
end;

procedure TSayfaKontrol.SayfaEkle(ABaslik: string);
begin

  _SayfaKontrolBaslikEkle(FKimlik, ABaslik);
end;

procedure TSayfaKontrol.EtiketEkle(ASayfaNo, ASol, AUst: TISayi4; ABaslik: string);
begin

  _SayfaKontrolEtiketEkle(FKimlik, ASayfaNo, ASol, AUst, ABaslik);
end;

function _SayfaKontrolOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
asm
  push  DWORD AYukseklik
  push  DWORD AGenislik
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AAtaKimlik
  mov   eax,SAYFAKONTROL_OLUSTUR
  int   $34
  add   esp,20
end;

procedure _SayfaKontrolGoster(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,SAYFAKONTROL_GOSTER
  int   $34
  add   esp,4
end;

procedure _SayfaKontrolGizle(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,SAYFAKONTROL_GIZLE
  int   $34
  add   esp,4
end;

procedure _SayfaKontrolBaslikEkle(AKimlik: TKimlik; ABaslik: string);
asm
  push  DWORD ABaslik
  push  DWORD AKimlik
  mov   eax,SAYFAKONTROL_YAZ_SAYFAEKLE
  int   $34
  add   esp,8
end;

procedure _SayfaKontrolEtiketEkle(AKimlik: TKimlik; ASayfaNo, ASol, AUst: TISayi4; ABaslik: string);
asm
  push  DWORD ABaslik
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD ASayfaNo
  push  DWORD AKimlik
  mov   eax,SAYFAKONTROL_YAZ_ETIKETEKLE
  int   $34
  add   esp,20
end;

end.
