{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_gucdugmesi.pas
  Dosya İşlevi: güç düğmesi yönetim işlevlerini içerir

  Güncelleme Tarihi: 20/09/2024

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
    procedure BaslikDegistir(ABaslik: string);
    procedure DurumDegistir(ADurum: TSayi4);
    procedure Boyutlandir(AKonum: TKonum; ABoyut: TBoyut);
    property Kimlik: TKimlik read FKimlik;
    property Etiket: TSayi4 read FEtiket write FEtiket;
  end;

function _GucDugmesiOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik; assembler;
procedure _GucDugmesiYokEt(AKimlik: TKimlik); assembler;
procedure _GucDugmesiGoster(AKimlik: TKimlik); assembler;
procedure _GucDugmesiGizle(AKimlik: TKimlik); assembler;
procedure _GucDugmesiBaslikDegistir(AKimlik: TKimlik; ABaslik: string); assembler;
procedure _GucDugmesiDurumDegistir(AKimlik: TKimlik; ADurum: TSayi4); assembler;
procedure _GucDugmesiBoyutlandir(AKimlik: TKimlik; AKonum: TKonum; ABoyut: TBoyut); assembler;

implementation

function TGucDugmesi.Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik;
begin

  FBaslik := ABaslik;

  FKimlik := _GucDugmesiOlustur(AAtaKimlik, ASol, AUst, AGenislik, AYukseklik, ABaslik);
  Result := FKimlik;
end;

procedure TGucDugmesi.YokEt;
begin

  _GucDugmesiYokEt(FKimlik);
end;

procedure TGucDugmesi.Goster;
begin

  _GucDugmesiGoster(FKimlik);
end;

procedure TGucDugmesi.Gizle;
begin

  _GucDugmesiGizle(FKimlik);
end;

procedure TGucDugmesi.BaslikDegistir(ABaslik: string);
begin

  if(FBaslik = ABaslik) then Exit;

  FBaslik := ABaslik;

  _GucDugmesiBaslikDegistir(FKimlik, FBaslik);
end;

procedure TGucDugmesi.DurumDegistir(ADurum: TSayi4);
begin

  _GucDugmesiDurumDegistir(FKimlik, ADurum);
end;

procedure TGucDugmesi.Boyutlandir(AKonum: TKonum; ABoyut: TBoyut);
begin

  _GucDugmesiBoyutlandir(FKimlik, AKonum, ABoyut);
end;

function _GucDugmesiOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ABaslik: string): TKimlik;
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

procedure _GucDugmesiYokEt(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,GUCDUGMESI_YOKET
  int   $34
  add   esp,4
end;

procedure _GucDugmesiGoster(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,GUCDUGMESI_GOSTER
  int   $34
  add   esp,4
end;

procedure _GucDugmesiGizle(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,GUCDUGMESI_GIZLE
  int   $34
  add   esp,4
end;

procedure _GucDugmesiBaslikDegistir(AKimlik: TKimlik; ABaslik: string);
asm
  push  DWORD ABaslik
  push  DWORD AKimlik
  mov   eax,GUCDUGMESI_YAZ_BASLIK
  int   $34
  add   esp,8
end;

procedure _GucDugmesiDurumDegistir(AKimlik: TKimlik; ADurum: TSayi4);
asm
  push  DWORD ADurum
  push  DWORD AKimlik
  mov   eax,GUCDUGMESI_YAZ_DURUM
  int   $34
  add   esp,8
end;

procedure _GucDugmesiBoyutlandir(AKimlik: TKimlik; AKonum: TKonum; ABoyut: TBoyut);
asm
  push  DWORD ABoyut
  push  DWORD AKonum
  push  DWORD AKimlik
  mov   eax,GUCDUGMESI_BOYUTLANDIR
  int   $34
  add   esp,12
end;

end.
