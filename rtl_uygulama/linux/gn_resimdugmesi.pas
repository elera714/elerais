{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_resimdugmesi.pas
  Dosya İşlevi: resim düğmesi yönetim işlevlerini içerir

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gn_resimdugmesi;

interface

type
  PResimDugmesi = ^TResimDugmesi;
  TResimDugmesi = object
  private
    FKimlik: TKimlik;
    FEtiket: TSayi4;
  public
    function Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik,
      ADeger: TISayi4): TKimlik;
    procedure Goster;
    procedure Hizala(AHiza: THiza);
    property Kimlik: TKimlik read FKimlik;
    property Etiket: TSayi4 read FEtiket write FEtiket;
  end;

function _ResimDugmesiOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik,
  ADeger: TISayi4): TKimlik; assembler;
procedure _ResimDugmesiGoster(AKimlik: TKimlik); assembler;
procedure _ResimDugmesiHizala(AKimlik: TKimlik; AHiza: THiza); assembler;

implementation

function TResimDugmesi.Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik,
  ADeger: TISayi4): TKimlik;
begin

  FKimlik := _ResimDugmesiOlustur(AAtaKimlik, ASol, AUst, AGenislik, AYukseklik, ADeger);
  Result := FKimlik;
end;

procedure TResimDugmesi.Goster;
begin

  _ResimDugmesiGoster(FKimlik);
end;

procedure TResimDugmesi.Hizala(AHiza: THiza);
begin

  _ResimDugmesiHizala(FKimlik, AHiza);
end;

function _ResimDugmesiOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik,
  ADeger: TISayi4): TKimlik;
asm
  push  DWORD ADeger
  push  DWORD AYukseklik
  push  DWORD AGenislik
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AAtaKimlik
  mov   eax,RESIMDUGMESI_OLUSTUR
  int   $34
  add   esp,24
end;

procedure _ResimDugmesiGoster(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,RESIMDUGMESI_GOSTER
  int   $34
  add   esp,4
end;

procedure _ResimDugmesiHizala(AKimlik: TKimlik; AHiza: THiza);
asm
  push  DWORD AHiza
  push  DWORD AKimlik
  mov   eax,RESIMDUGMESI_HIZALA
  int   $34
  add   esp,8
end;

end.
