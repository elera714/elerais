{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_islemgostergesi.pas
  Dosya İşlevi: işlem göstergesi (TProgressBar) yönetim işlevlerini içerir

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gn_islemgostergesi;

interface

type
  PIslemGostergesi = ^TIslemGostergesi;
  TIslemGostergesi = object
  private
    FKimlik: TKimlik;
  public
    function Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
    procedure Goster;
    procedure DegerleriBelirle(AAltDeger, AUstDeger: TSayi4);
    procedure KonumBelirle(AKonum: TSayi4);
  end;

function _IslemGostergesiOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik,
  AYukseklik: TISayi4): TKimlik; assembler;
procedure _IslemGostergesiGoster(AKimlik: TKimlik); assembler;
procedure _IslemGostergesiDegerleriBelirle(AKimlik: TKimlik; AAltDeger, AUstDeger: TSayi4); assembler;
procedure _IslemGostergesiKonumBelirle(AKimlik: TKimlik; AKonum: TSayi4); assembler;

implementation

function TIslemGostergesi.Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
begin

  FKimlik := _IslemGostergesiOlustur(AAtaKimlik, ASol, AUst, AGenislik, AYukseklik);
  Result := FKimlik;
end;

procedure TIslemGostergesi.Goster;
begin

  _IslemGostergesiGoster(FKimlik);
end;

procedure TIslemGostergesi.DegerleriBelirle(AAltDeger, AUstDeger: TSayi4);
begin

  _IslemGostergesiDegerleriBelirle(FKimlik, AAltDeger, AUstDeger);
end;

procedure TIslemGostergesi.KonumBelirle(AKonum: TSayi4);
begin

  _IslemGostergesiKonumBelirle(FKimlik, AKonum);
end;

function _IslemGostergesiOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik,
  AYukseklik: TISayi4): TKimlik;
asm
  push  DWORD AYukseklik
  push  DWORD AGenislik
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AAtaKimlik
  mov   eax,ISLEMGOSTERGESI_OLUSTUR
  int   $34
  add   esp,20
end;

procedure _IslemGostergesiGoster(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,ISLEMGOSTERGESI_GOSTER
  int   $34
  add   esp,4
end;

procedure _IslemGostergesiDegerleriBelirle(AKimlik: TKimlik; AAltDeger, AUstDeger: TSayi4);
asm
  push  DWORD AUstDeger
  push  DWORD AAltDeger
  push  DWORD AKimlik
  mov   eax,ISLEMGOSTERGESI_YAZ_ARALIK
  int   $34
  add   esp,12
end;

procedure _IslemGostergesiKonumBelirle(AKimlik: TKimlik; AKonum: TSayi4);
asm
  push  DWORD AKonum
  push  DWORD AKimlik
  mov   eax,ISLEMGOSTERGESI_YAZ_KONUM
  int   $34
  add   esp,8
end;

end.
