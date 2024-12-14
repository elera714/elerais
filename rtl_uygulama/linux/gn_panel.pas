{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_panel.pas
  Dosya İşlevi: panel (TPanel) yönetim işlevlerini içerir

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gn_panel;

interface

type
  PPanel = ^TPanel;
  TPanel = object
  private
    FKimlik: TKimlik;
  public
    procedure Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
      ACizimModel: TSayi4; AGovdeRenk1, AGovdeRenk2, AYaziRenk: TRenk; ABaslik: string);
    procedure Goster;
    procedure Hizala(AHiza: THiza);
    procedure BoyutAl(var AKonum: TKonum; var ABoyut: TBoyut);
    property Kimlik: TKimlik read FKimlik;
  end;

function _PanelOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  AGovdeRenkSecim: TSayi4; AGovdeRenk1, AGovdeRenk2, AYaziRenk: TRenk; ABaslik: string): TKimlik; assembler;
procedure _PanelGoster(AKimlik: TKimlik); assembler;
procedure _PanelHizala(AKimlik: TKimlik; AHiza: THiza); assembler;
procedure _PanelBoyutAl(AKimlik: TKimlik; var AKonum: TKonum; var ABoyut: TBoyut); assembler;

implementation

procedure TPanel.Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  ACizimModel: TSayi4; AGovdeRenk1, AGovdeRenk2, AYaziRenk: TRenk; ABaslik: string);
begin

  FKimlik := _PanelOlustur(AAtaKimlik, ASol, AUst, AGenislik, AYukseklik, ACizimModel,
    AGovdeRenk1, AGovdeRenk2, AYaziRenk, ABaslik);
end;

procedure TPanel.Goster;
begin

  _PanelGoster(FKimlik);
end;

procedure TPanel.Hizala(AHiza: THiza);
begin

  _PanelHizala(FKimlik, AHiza);
end;

procedure TPanel.BoyutAl(var AKonum: TKonum; var ABoyut: TBoyut);
begin

  _PanelBoyutAl(FKimlik, AKonum, ABoyut);
end;

function _PanelOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4;
  AGovdeRenkSecim: TSayi4; AGovdeRenk1, AGovdeRenk2, AYaziRenk: TRenk; ABaslik: string): TKimlik;
asm
  push  DWORD ABaslik
  push  DWORD AYaziRenk
  push  DWORD AGovdeRenk2
  push  DWORD AGovdeRenk1
  push  DWORD AGovdeRenkSecim
  push  DWORD AYukseklik
  push  DWORD AGenislik
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AAtaKimlik
  mov   eax,PANEL_OLUSTUR
  int   $34
  add   esp,40
end;

procedure _PanelGoster(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,PANEL_GOSTER
  int   $34
  add   esp,4
end;

procedure _PanelHizala(AKimlik: TKimlik; AHiza: THiza);
asm
  push  DWORD AHiza
  push  DWORD AKimlik
  mov   eax,PANEL_HIZALA
  int   $34
  add   esp,8
end;

procedure _PanelBoyutAl(AKimlik: TKimlik; var AKonum: TKonum; var ABoyut: TBoyut);
asm
  push  DWORD ABoyut
  push  DWORD AKonum
  push  DWORD AKimlik
  mov   eax,PANEL_AL_BOYUT
  int   $34
  add   esp,12
end;

end.
