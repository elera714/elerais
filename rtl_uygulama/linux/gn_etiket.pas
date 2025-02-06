{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_etiket.pas
  Dosya İşlevi: etiket (TLabel) nesne yönetim işlevlerini içerir

  Güncelleme Tarihi: 04/02/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gn_etiket;

interface

type
  PEtiket = ^TEtiket;
  TEtiket = object
  private
    FKimlik: TKimlik;
  public
    function Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
      ARenk: TRenk; ABaslik: string): TKimlik;
    procedure Goster;
    procedure BaslikDegistir(ABaslik: string);
    procedure RenkDegistir(ARenk: TRenk);
  published
    property Kimlik: TKimlik read FKimlik;
  end;

function _EtiketOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ARenk: TRenk; ABaslik: string): TKimlik; assembler;
procedure _EtiketGoster(AKimlik: TKimlik); assembler;
procedure _BaslikDegistir(AKimlik: TKimlik; ABaslik: string); assembler;
procedure _RenkDegistir(AKimlik: TKimlik; ARenk: TRenk); assembler;

implementation

function TEtiket.Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ARenk: TRenk; ABaslik: string): TKimlik;
begin

  FKimlik := _EtiketOlustur(AAtaKimlik, ASol, AUst, AGenislik, AYukseklik, ARenk, ABaslik);
  Result := FKimlik;
end;

procedure TEtiket.Goster;
begin

  _EtiketGoster(FKimlik);
end;

procedure TEtiket.BaslikDegistir(ABaslik: string);
begin

  _BaslikDegistir(FKimlik, ABaslik);
end;

procedure TEtiket.RenkDegistir(ARenk: TRenk);
begin

  _RenkDegistir(FKimlik, ARenk);
end;

function _EtiketOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ARenk: TRenk; ABaslik: string): TKimlik;
asm
  push  DWORD ABaslik
  push  DWORD ARenk
  push  DWORD AYukseklik
  push  DWORD AGenislik
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AAtaKimlik
  mov   eax,ETIKET_OLUSTUR
  int   $34
  add   esp,28
end;

procedure _EtiketGoster(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,ETIKET_GOSTER
  int   $34
  add   esp,4
end;

procedure _BaslikDegistir(AKimlik: TKimlik; ABaslik: string);
asm
  push  DWORD ABaslik
  push  DWORD AKimlik
  mov   eax,ETIKET_YAZ_BASLIK
  int   $34
  add   esp,8
end;

procedure _RenkDegistir(AKimlik: TKimlik; ARenk: TRenk);
asm
  push  DWORD ARenk
  push  DWORD AKimlik
  mov   eax,ETIKET_YAZ_RENK
  int   $34
  add   esp,8
end;

end.
