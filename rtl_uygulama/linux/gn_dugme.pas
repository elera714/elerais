{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_dugme.pas
  Dosya İşlevi: düğme (TButton) yönetim işlevlerini içerir

  Güncelleme Tarihi: 11/02/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gn_dugme;

interface

type
  PDugme = ^TDugme;
  TDugme = object
  private
    FKimlik: TKimlik;
    FEtiket: TISayi4;
    FBaslik: string;
  public
    function Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
      ABaslik: string): TKimlik;
    procedure YokEt;
    procedure Goster;
    procedure Gizle;
    procedure Odaklan;
    procedure BaslikDegistir(ABaslik: string);
    procedure Hizala(AHiza: THiza);
    property Kimlik: TKimlik read FKimlik;
    property Etiket: TISayi4 read FEtiket write FEtiket;
  end;

function DugmeOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik; assembler;
procedure DugmeYokEt(AKimlik: TKimlik); assembler;
procedure DugmeGoster(AKimlik: TKimlik); assembler;
procedure DugmeGizle(AKimlik: TKimlik); assembler;
procedure DugmeBaslikDegistir(AKimlik: TKimlik; ABaslik: string); assembler;
procedure DugmeHizala(AKimlik: TKimlik; AHiza: THiza); assembler;
procedure DugmeOdaklan(AKimlik: TKimlik); assembler;

implementation

function TDugme.Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik;
begin

  FBaslik := ABaslik;

  FKimlik := DugmeOlustur(AAtaKimlik, ASol, AUst, AGenislik, AYukseklik, ABaslik);

  Result := FKimlik;
end;

procedure TDugme.YokEt;
begin

  DugmeYokEt(FKimlik);
end;

procedure TDugme.Goster;
begin

  DugmeGoster(FKimlik);
end;

procedure TDugme.Gizle;
begin

  DugmeGizle(FKimlik);
end;

procedure TDugme.Odaklan;
begin

  DugmeOdaklan(FKimlik);
end;

procedure TDugme.BaslikDegistir(ABaslik: string);
begin

  if(FBaslik = ABaslik) then Exit;

  FBaslik := ABaslik;

  DugmeBaslikDegistir(FKimlik, FBaslik);
end;

procedure TDugme.Hizala(AHiza: THiza);
begin

  DugmeHizala(FKimlik, AHiza);
end;

function DugmeOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik; assembler;
asm
  push  DWORD ABaslik
  push  DWORD AYukseklik
  push  DWORD AGenislik
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AAtaKimlik
  mov   eax,DUGME_OLUSTUR
  int   $34
  add   esp,24
end;

procedure DugmeYokEt(AKimlik: TKimlik); assembler;
asm
  push  DWORD AKimlik
  mov   eax,DUGME_YOKET
  int   $34
  add   esp,4
end;

procedure DugmeGoster(AKimlik: TKimlik); assembler;
asm
  push  DWORD AKimlik
  mov   eax,DUGME_GOSTER
  int   $34
  add   esp,4
end;

procedure DugmeGizle(AKimlik: TKimlik); assembler;
asm
  push  DWORD AKimlik
  mov   eax,DUGME_GIZLE
  int   $34
  add   esp,4
end;

procedure DugmeBaslikDegistir(AKimlik: TKimlik; ABaslik: string); assembler;
asm
  push  DWORD ABaslik
  push  DWORD AKimlik
  mov   eax,DUGME_YAZ_BASLIK
  int   $34
  add   esp,8
end;

procedure DugmeHizala(AKimlik: TKimlik; AHiza: THiza); assembler;
asm
  push  DWORD AHiza
  push  DWORD AKimlik
  mov   eax,DUGME_HIZALA
  int   $34
  add   esp,8
end;

procedure DugmeOdaklan(AKimlik: TKimlik); assembler;
asm
  push  DWORD AKimlik
  mov   eax,DUGME_YAZ_ODAK
  int   $34
  add   esp,4
end;

end.
