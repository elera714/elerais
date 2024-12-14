{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_baglanti.pas
  Dosya İşlevi: bağlantı nesne yönetim işlevlerini içerir

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gn_baglanti;

interface

type
  PBaglanti = ^TBaglanti;
  TBaglanti = object
  private
    FKimlik: TKimlik;
  public
    function Olustur(AAtaKimlik: TKimlik; ASol, AUst: TISayi4; ANormalRenk,
      AOdakRenk: TRenk; ABaslik: string): TKimlik;
    procedure Goster;
  published
    property Kimlik: TKimlik read FKimlik;
  end;

function _BaglantiOlustur(AAtaKimlik: TKimlik; ASol, AUst: TISayi4; ANormalRenk,
  AOdakRenk: TRenk; ABaslik: string): TKimlik; assembler;
procedure _BaglantiGoster(AKimlik: TKimlik); assembler;

implementation

function TBaglanti.Olustur(AAtaKimlik: TKimlik; ASol, AUst: TISayi4; ANormalRenk,
  AOdakRenk: TRenk; ABaslik: string): TKimlik;
begin

  FKimlik := _BaglantiOlustur(AAtaKimlik, ASol, AUst, ANormalRenk, AOdakRenk, ABaslik);
  Result := FKimlik;
end;

procedure TBaglanti.Goster;
begin

  _BaglantiGoster(FKimlik);
end;

function _BaglantiOlustur(AAtaKimlik: TKimlik; ASol, AUst: TISayi4; ANormalRenk,
  AOdakRenk: TRenk; ABaslik: string): TKimlik;
asm
  push  DWORD ABaslik
  push  DWORD AOdakRenk
  push  DWORD ANormalRenk
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AAtaKimlik
  mov   eax,BAGLANTI_OLUSTUR
  int   $34
  add   esp,24
end;

procedure _BaglantiGoster(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,BAGLANTI_GOSTER
  int   $34
  add   esp,4
end;

end.
