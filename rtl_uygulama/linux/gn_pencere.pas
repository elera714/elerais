{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_pencere.pas
  Dosya İşlevi: pencere (TPencere) yönetim işlevlerini içerir

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gn_pencere;

interface

uses n_tuval;

type
  PPencere = ^TPencere;
  TPencere = object
  private
    FKimlik: TKimlik;
    FTuval: TTuval;
    procedure Goster;
    procedure Gizle;
    procedure GorunumDegistir(AGorunum: Boolean);
  public
    procedure Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
      APencereTipi: TPencereTipi; ABaslik: string; AGovdeRenk: TRenk);
    procedure Ciz;
    procedure PencereDurumuDegistir(AKimlik: TKimlik; APencereDurum: TPencereDurum);
    property Kimlik: TKimlik read FKimlik;
    property Tuval: TTuval read FTuval;
    property Gorunum: Boolean write GorunumDegistir;
  end;

function _PencereOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  APencereTipi: TPencereTipi; ABaslik: string; AGovdeRenk: TRenk): TKimlik; assembler;
procedure _PencereGoster(AKimlik: TKimlik); assembler;
procedure _PencereGizle(AKimlik: TKimlik); assembler;
procedure _PencereCiz(AKimlik: TKimlik); assembler;
procedure _PencereDurumuDegistir(AKimlik: TKimlik; APencereDurum: TPencereDurum); assembler;

implementation

procedure TPencere.Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  APencereTipi: TPencereTipi; ABaslik: string; AGovdeRenk: TRenk);
begin

  FKimlik := _PencereOlustur(AAtaKimlik, ASol, AUst, AGenislik, AYukseklik,
    APencereTipi, ABaslik, AGovdeRenk);

  FTuval.Olustur(FKimlik);
end;

procedure TPencere.GorunumDegistir(AGorunum: Boolean);
begin

  if(AGorunum) then
    Goster
  else Gizle;
end;

procedure TPencere.Goster;
begin

  _PencereGoster(FKimlik);
end;

procedure TPencere.Gizle;
begin

  _PencereGizle(FKimlik);
end;

procedure TPencere.Ciz;
begin

  _PencereCiz(FKimlik);
end;

procedure TPencere.PencereDurumuDegistir(AKimlik: TKimlik; APencereDurum: TPencereDurum);
begin

  _PencereDurumuDegistir(AKimlik, APencereDurum);
end;

function _PencereOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  APencereTipi: TPencereTipi; ABaslik: string; AGovdeRenk: TRenk): TKimlik;
asm
  push  DWORD AGovdeRenk
  push  DWORD ABaslik
  push  DWORD APencereTipi
  push  DWORD AYukseklik
  push  DWORD AGenislik
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AAtaKimlik
  mov   eax,PENCERE_OLUSTUR
  int   $34
  add   esp,32
end;

procedure _PencereGoster(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,PENCERE_GOSTER
  int   $34
  add   esp,4
end;

procedure _PencereGizle(AKimlik: TKimlik); assembler;
asm
  push  DWORD AKimlik
  mov   eax,PENCERE_GIZLE
  int   $34
  add   esp,4
end;

procedure _PencereCiz(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,PENCERE_CIZ
  int   $34
  add   esp,4
end;

procedure _PencereDurumuDegistir(AKimlik: TKimlik; APencereDurum: TPencereDurum);
asm
  push  DWORD APencereDurum
  push  DWORD AKimlik
  mov   eax,PENCERE_YAZ_PENCEREDURUMU
  int   $34
  add   esp,8
end;

end.
