{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_secimdugmesi.pas
  Dosya İşlevi: seçim düğmesi (TRadioButton) yönetim işlevlerini içerir

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gn_secimdugmesi;

interface

type
  PSecimDugmesi = ^TSecimDugmesi;
  TSecimDugmesi = object
  private
    FKimlik: TKimlik;
  public
    function Olustur(AAtaKimlik: TKimlik; ASol, AUst: TISayi4; ABaslik: string): TISayi4;
    procedure DurumDegistir(ASecimDurumu: TSecimDurumu);
    procedure Goster;
    property Kimlik: TKimlik read FKimlik;
  end;

function _SecimDugmesiOlustur(AAtaKimlik: TKimlik; ASol, AUst: TISayi4; ABaslik: string): TKimlik; assembler;
procedure _SecimDugmesiDurumDegistir(AKimlik: TKimlik; ASecimDurumu: TSecimDurumu); assembler;
procedure _SecimDugmesiGoster(AKimlik: TKimlik); assembler;

implementation

function TSecimDugmesi.Olustur(AAtaKimlik: TKimlik; ASol, AUst: TISayi4; ABaslik: string): TISayi4;
begin

  FKimlik := _SecimDugmesiOlustur(AAtaKimlik, ASol, AUst, ABaslik);
  Result := FKimlik;
end;

procedure TSecimDugmesi.DurumDegistir(ASecimDurumu: TSecimDurumu);
begin

  _SecimDugmesiDurumDegistir(FKimlik, ASecimDurumu);
end;

procedure TSecimDugmesi.Goster;
begin

  _SecimDugmesiGoster(FKimlik);
end;

function _SecimDugmesiOlustur(AAtaKimlik: TKimlik; ASol, AUst: TISayi4; ABaslik: string): TKimlik;
asm
  push  DWORD ABaslik
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AAtaKimlik
  mov   eax,SECIMDUGMESI_OLUSTUR
  int   $34
  add   esp,16
end;

procedure _SecimDugmesiDurumDegistir(AKimlik: TKimlik; ASecimDurumu: TSecimDurumu);
asm
  push  DWORD ASecimDurumu
  push  DWORD AKimlik
  mov   eax,SECIMDUGMESI_YAZ_DURUM
  int   $34
  add   esp,8
end;

procedure _SecimDugmesiGoster(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,SECIMDUGMESI_GOSTER
  int   $34
  add   esp,4
end;

end.
