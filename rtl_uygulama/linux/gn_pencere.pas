{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_pencere.pas
  Dosya İşlevi: pencere (TPencere) yönetim işlevlerini içerir

  Güncelleme Tarihi: 17/02/2025

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
    procedure DurumuDegistir(AKimlik: TKimlik; APencereDurum: TPencereDurum);
    function AktifPencereyiAl: TSayi4;
    procedure AktifPencereyiYaz(AKimlik: TKimlik);
    property Kimlik: TKimlik read FKimlik;
    property Tuval: TTuval read FTuval;
    property Gorunum: Boolean write GorunumDegistir;
  end;

function PencereOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  APencereTipi: TPencereTipi; ABaslik: string; AGovdeRenk: TRenk): TKimlik; assembler;
procedure PencereGoster(AKimlik: TKimlik); assembler;
procedure PencereGizle(AKimlik: TKimlik); assembler;
procedure PencereCiz(AKimlik: TKimlik); assembler;
procedure PencereDurumuDegistir(AKimlik: TKimlik; APencereDurum: TPencereDurum); assembler;
function PencereAktifAl: TSayi4; assembler;
procedure PencereAktifYaz(AKimlik: TKimlik); assembler;

implementation

procedure TPencere.Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  APencereTipi: TPencereTipi; ABaslik: string; AGovdeRenk: TRenk);
begin

  FKimlik := PencereOlustur(AAtaKimlik, ASol, AUst, AGenislik, AYukseklik,
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

  PencereGoster(FKimlik);
end;

procedure TPencere.Gizle;
begin

  PencereGizle(FKimlik);
end;

procedure TPencere.Ciz;
begin

  PencereCiz(FKimlik);
end;

procedure TPencere.DurumuDegistir(AKimlik: TKimlik; APencereDurum: TPencereDurum);
begin

  PencereDurumuDegistir(AKimlik, APencereDurum);
end;

function TPencere.AktifPencereyiAl: TSayi4;
begin

  Result := PencereAktifAl;
end;

procedure TPencere.AktifPencereyiYaz(AKimlik: TKimlik);
begin

  PencereAktifYaz(AKimlik);
end;

function PencereOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  APencereTipi: TPencereTipi; ABaslik: string; AGovdeRenk: TRenk): TKimlik; assembler;
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

procedure PencereGoster(AKimlik: TKimlik); assembler;
asm
  push  DWORD AKimlik
  mov   eax,PENCERE_GOSTER
  int   $34
  add   esp,4
end;

procedure PencereGizle(AKimlik: TKimlik); assembler; assembler;
asm
  push  DWORD AKimlik
  mov   eax,PENCERE_GIZLE
  int   $34
  add   esp,4
end;

procedure PencereCiz(AKimlik: TKimlik); assembler;
asm
  push  DWORD AKimlik
  mov   eax,PENCERE_CIZ
  int   $34
  add   esp,4
end;

procedure PencereDurumuDegistir(AKimlik: TKimlik; APencereDurum: TPencereDurum); assembler;
asm
  push  DWORD APencereDurum
  push  DWORD AKimlik
  mov   eax,PENCERE_YAZ_PENCEREDURUMU
  int   $34
  add   esp,8
end;

function PencereAktifAl: TSayi4; assembler;
asm
  mov	  eax,PENCERE_AKTIFAL
  int	  $34
end;

procedure PencereAktifYaz(AKimlik: TKimlik); assembler;
asm
  push  DWORD AKimlik
  mov	  eax,PENCERE_AKTIFYAZ
  int	  $34
  add   esp,4
end;

end.
