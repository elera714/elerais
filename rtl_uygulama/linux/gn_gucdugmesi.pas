{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_gucdugmesi.pas
  Dosya İşlevi: güç düğmesi yönetim işlevlerini içerir

  Güncelleme Tarihi: 11/02/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gn_gucdugmesi;

interface

type
  PGucDugmesi = ^TGucDugmesi;
  TGucDugmesi = object
  private
    FKimlik: TKimlik;
    FEtiket: TSayi4;
    FBaslik: string;
  public
    function Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
      ABaslik: string): TKimlik;
    procedure YokEt;
    procedure Goster;
    procedure Gizle;
    procedure Odaklan;
    procedure BaslikDegistir(ABaslik: string);
    procedure DurumDegistir(ADurum: TSayi4);
    procedure Boyutlandir(AKonum: TKonum; ABoyut: TBoyut);
    property Kimlik: TKimlik read FKimlik;
    property Etiket: TSayi4 read FEtiket write FEtiket;
  end;

function GucDugmesiOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik; assembler;
procedure GucDugmesiYokEt(AKimlik: TKimlik); assembler;
procedure GucDugmesiGoster(AKimlik: TKimlik); assembler;
procedure GucDugmesiGizle(AKimlik: TKimlik); assembler;
procedure GucDugmesiBaslikDegistir(AKimlik: TKimlik; ABaslik: string); assembler;
procedure GucDugmesiDurumDegistir(AKimlik: TKimlik; ADurum: TSayi4); assembler;
procedure GucDugmesiBoyutlandir(AKimlik: TKimlik; AKonum: TKonum; ABoyut: TBoyut); assembler;
procedure GucDugmesiOdaklan(AKimlik: TKimlik); assembler;

implementation

function TGucDugmesi.Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik;
begin

  FBaslik := ABaslik;

  FKimlik := GucDugmesiOlustur(AAtaKimlik, ASol, AUst, AGenislik, AYukseklik, ABaslik);
  Result := FKimlik;
end;

procedure TGucDugmesi.YokEt;
begin

  GucDugmesiYokEt(FKimlik);
end;

procedure TGucDugmesi.Goster;
begin

  GucDugmesiGoster(FKimlik);
end;

procedure TGucDugmesi.Gizle;
begin

  GucDugmesiGizle(FKimlik);
end;

procedure TGucDugmesi.Odaklan;
begin

  GucDugmesiOdaklan(FKimlik);
end;

procedure TGucDugmesi.BaslikDegistir(ABaslik: string);
begin

  if(FBaslik = ABaslik) then Exit;

  FBaslik := ABaslik;

  GucDugmesiBaslikDegistir(FKimlik, FBaslik);
end;

procedure TGucDugmesi.DurumDegistir(ADurum: TSayi4);
begin

  GucDugmesiDurumDegistir(FKimlik, ADurum);
end;

procedure TGucDugmesi.Boyutlandir(AKonum: TKonum; ABoyut: TBoyut);
begin

  GucDugmesiBoyutlandir(FKimlik, AKonum, ABoyut);
end;

function GucDugmesiOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik; assembler;
asm
  push  DWORD ABaslik
  push  DWORD AYukseklik
  push  DWORD AGenislik
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AAtaKimlik
  mov   eax,GUCDUGMESI_OLUSTUR
  int   $34
  add   esp,24
end;

procedure GucDugmesiYokEt(AKimlik: TKimlik); assembler;
asm
  push  DWORD AKimlik
  mov   eax,GUCDUGMESI_YOKET
  int   $34
  add   esp,4
end;

procedure GucDugmesiGoster(AKimlik: TKimlik); assembler;
asm
  push  DWORD AKimlik
  mov   eax,GUCDUGMESI_GOSTER
  int   $34
  add   esp,4
end;

procedure GucDugmesiGizle(AKimlik: TKimlik); assembler;
asm
  push  DWORD AKimlik
  mov   eax,GUCDUGMESI_GIZLE
  int   $34
  add   esp,4
end;

procedure GucDugmesiBaslikDegistir(AKimlik: TKimlik; ABaslik: string); assembler;
asm
  push  DWORD ABaslik
  push  DWORD AKimlik
  mov   eax,GUCDUGMESI_YAZ_BASLIK
  int   $34
  add   esp,8
end;

procedure GucDugmesiDurumDegistir(AKimlik: TKimlik; ADurum: TSayi4); assembler;
asm
  push  DWORD ADurum
  push  DWORD AKimlik
  mov   eax,GUCDUGMESI_YAZ_DURUM
  int   $34
  add   esp,8
end;

procedure GucDugmesiBoyutlandir(AKimlik: TKimlik; AKonum: TKonum; ABoyut: TBoyut); assembler;
asm
  push  DWORD ABoyut
  push  DWORD AKonum
  push  DWORD AKimlik
  mov   eax,GUCDUGMESI_BOYUTLANDIR
  int   $34
  add   esp,12
end;

procedure GucDugmesiOdaklan(AKimlik: TKimlik); assembler;
asm
  push  DWORD AKimlik
  mov   eax,GUCDUGMESI_YAZ_ODAK
  int   $34
  add   esp,4
end;

end.
