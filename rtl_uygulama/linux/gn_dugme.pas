{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_dugme.pas
  Dosya İşlevi: düğme (TButton) yönetim işlevlerini içerir

  Güncelleme Tarihi: 20/09/2024

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
    procedure BaslikDegistir(ABaslik: string);
    procedure Hizala(AHiza: THiza);
    property Kimlik: TKimlik read FKimlik;
    property Etiket: TISayi4 read FEtiket write FEtiket;
  end;

function _DugmeOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik; assembler;
procedure _DugmeYokEt(AKimlik: TKimlik); assembler;
procedure _DugmeGoster(AKimlik: TKimlik); assembler;
procedure _DugmeGizle(AKimlik: TKimlik); assembler;
procedure _DugmeBaslikDegistir(AKimlik: TKimlik; ABaslik: string); assembler;
procedure _DugmeHizala(AKimlik: TKimlik; AHiza: THiza); assembler;

implementation

function TDugme.Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik;
begin

  FBaslik := ABaslik;

  FKimlik := _DugmeOlustur(AAtaKimlik, ASol, AUst, AGenislik, AYukseklik, ABaslik);

  Result := FKimlik;
end;

procedure TDugme.YokEt;
begin

  _DugmeYokEt(FKimlik);
end;

procedure TDugme.Goster;
begin

  _DugmeGoster(FKimlik);
end;

procedure TDugme.Gizle;
begin

  _DugmeGizle(FKimlik);
end;

procedure TDugme.BaslikDegistir(ABaslik: string);
begin

  if(FBaslik = ABaslik) then Exit;

  FBaslik := ABaslik;

  _DugmeBaslikDegistir(FKimlik, FBaslik);
end;

procedure TDugme.Hizala(AHiza: THiza);
begin

  _DugmeHizala(FKimlik, AHiza);
end;

function _DugmeOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik;
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

procedure _DugmeYokEt(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,DUGME_YOKET
  int   $34
  add   esp,4
end;

procedure _DugmeGoster(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,DUGME_GOSTER
  int   $34
  add   esp,4
end;

procedure _DugmeGizle(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,DUGME_GIZLE
  int   $34
  add   esp,4
end;

procedure _DugmeBaslikDegistir(AKimlik: TKimlik; ABaslik: string);
asm
  push  DWORD ABaslik
  push  DWORD AKimlik
  mov   eax,DUGME_YAZ_BASLIK
  int   $34
  add   esp,8
end;

procedure _DugmeHizala(AKimlik: TKimlik; AHiza: THiza);
asm
  push  DWORD AHiza
  push  DWORD AKimlik
  mov   eax,DUGME_HIZALA
  int   $34
  add   esp,8
end;

end.
