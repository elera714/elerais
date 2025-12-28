{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: n_tuval.pas
  Dosya İşlevi: pencere içeriğine yazım - çizim işlevlerini içerir

  Güncelleme Tarihi: 16/07/2020

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit n_tuval;

interface

type
  TFirca = object
  public
    Renk: TRenk;
  end;

  TKalem = object
  public
    Renk: TRenk;
  end;

  TTuval = object
  private
    FKimlik: TKimlik;
    FFirca: TFirca;
    FKalem: TKalem;
    function KalemRengiAl: TRenk;
    procedure KalemRengiYaz(ARenk: TRenk);
    function FircaRengiAl: TRenk;
    procedure FircaRengiYaz(ARenk: TRenk);
  public
    procedure Olustur(APencereKimlik: TKimlik);
    procedure HarfYaz(ASol, AUst: TISayi4; AKarakter: Char);
    procedure YaziYaz(ASol, AUst: TISayi4; ADeger: string);
    procedure SayiYaz10(ASol, AUst: TISayi4; ADeger: TISayi4);
    procedure SayiYaz16(ASol, AUst: TISayi4; AOnekYaz: LongBool; AHaneSayisi: TSayi4;
      ADeger: TISayi4);
    procedure SaatYaz(ASol, AUst: TISayi4; ASaat: TSaat);
    procedure IPAdresiYaz(ASol, AUst: TISayi4; AIPAdres: PIPAdres);
    procedure MACAdresiYaz(ASol, AUst: TISayi4; AMACAdres: PMACAdres);
    procedure PixelYaz(ASol, AUst: TISayi4; ARenk: TRenk);
    procedure Cizgi(ASol, AUst, ASag, AAlt: TISayi4; ACizgiTipi: TCizgiTipi; ARenk: TRenk);
    procedure Dikdortgen(ASol, AUst, ASag, AAlt: TISayi4; ARenk: TRenk; ADoldur: Boolean);
    procedure Daire(ASol, AUst, AYariCap: TISayi4; ARenk: TRenk; ADoldur: Boolean);
    property FircaRengi: TColor read FircaRengiAl write FircaRengiYaz;
    property KalemRengi: TColor read KalemRengiAl write KalemRengiYaz;
  published
  end;

procedure _HarfYaz(AKimlik: TKimlik; ASol, AUst: TISayi4; ARenk: TRenk; AKarakter: Char); assembler;
procedure _YaziYaz(AKimlik: TKimlik; ASol, AUst: TISayi4; ARenk: TRenk; ADeger: string); assembler;
procedure _SayiYaz10(AKimlik: TKimlik; ASol, AUst: TISayi4; ARenk: TRenk; ADeger: TISayi4); assembler;
procedure _SayiYaz16(AKimlik: TKimlik; ASol, AUst: TISayi4; ARenk: TRenk; AOnekYaz: LongBool;
  AHaneSayisi: TSayi4; ADeger: TISayi4); assembler;
procedure _SaatYaz(AKimlik: TKimlik; ASol, AUst: TISayi4; ARenk: TRenk; ASaat: TSaat); assembler;
procedure _MACAdresiYaz(AKimlik: TKimlik; ASol, AUst: TISayi4; ARenk: TRenk; AMACAdres: PMACAdres); assembler;
procedure _IPAdresiYaz(AKimlik: TKimlik; ASol, AUst: TISayi4; ARenk: TRenk; AIPAdres: PIPAdres); assembler;
procedure _PixelYaz(AKimlik: TKimlik; ASol, AUst: TISayi4; ARenk: TRenk); assembler;
procedure _Cizgi(AKimlik: TKimlik; ASol, AUst, ASag, AAlt: TISayi4;
  ACizgiTipi: TCizgiTipi; ARenk: TRenk); assembler;
procedure _Dikdortgen(AKimlik: TKimlik; ASol, AUst, ASag, AAlt: TISayi4; ARenk: TRenk; ADoldur: LongBool); assembler;
procedure _Daire(AKimlik: TKimlik; ASol, AUst, AYariCap: TISayi4; ARenk: TRenk; ADoldur: LongBool); assembler;

implementation

procedure TTuval.Olustur(APencereKimlik: TKimlik);
begin

  FKimlik := APencereKimlik;
  FFirca.Renk := RENK_KIRMIZI;
  FKalem.Renk := RENK_SIYAH;
end;

function TTuval.KalemRengiAl: TRenk;
begin

  Result := FKalem.Renk;
end;

procedure TTuval.KalemRengiYaz(ARenk: TRenk);
begin

  FKalem.Renk := ARenk;
end;

function TTuval.FircaRengiAl: TRenk;
begin

  Result := FFirca.Renk;
end;

procedure TTuval.FircaRengiYaz(ARenk: TRenk);
begin

  FFirca.Renk := ARenk;
end;

procedure TTuval.HarfYaz(ASol, AUst: TISayi4; AKarakter: Char);
begin

  _HarfYaz(FKimlik, ASol, AUst, FKalem.Renk, AKarakter);
end;

procedure TTuval.YaziYaz(ASol, AUst: TISayi4; ADeger: string);
begin

  _YaziYaz(FKimlik, ASol, AUst, FKalem.Renk, ADeger);
end;

procedure TTuval.SayiYaz10(ASol, AUst: TISayi4; ADeger: TISayi4);
begin

  _SayiYaz10(FKimlik, ASol, AUst, FKalem.Renk, ADeger);
end;

procedure TTuval.SayiYaz16(ASol, AUst: TISayi4; AOnekYaz: LongBool; AHaneSayisi: TSayi4;
  ADeger: TISayi4);
begin

  _SayiYaz16(FKimlik, ASol, AUst, FKalem.Renk, AOnekYaz, AHaneSayisi, ADeger);
end;

procedure TTuval.SaatYaz(ASol, AUst: TISayi4; ASaat: TSaat);
begin

  _SaatYaz(FKimlik, ASol, AUst, FKalem.Renk, ASaat);
end;

procedure TTuval.IPAdresiYaz(ASol, AUst: TISayi4; AIPAdres: PIPAdres);
begin

  _IPAdresiYaz(FKimlik, ASol, AUst, FKalem.Renk, AIPAdres);
end;

procedure TTuval.MACAdresiYaz(ASol, AUst: TISayi4; AMACAdres: PMACAdres);
begin

  _MACAdresiYaz(FKimlik, ASol, AUst, FKalem.Renk, AMACAdres);
end;

procedure TTuval.PixelYaz(ASol, AUst: TISayi4; ARenk: TRenk);
begin

  _PixelYaz(FKimlik, ASol, AUst, ARenk);
end;

procedure TTuval.Cizgi(ASol, AUst, ASag, AAlt: TISayi4; ACizgiTipi: TCizgiTipi; ARenk: TRenk);
begin

  _Cizgi(FKimlik, ASol, AUst, ASag, AAlt, ACizgiTipi, ARenk);
end;

procedure TTuval.Dikdortgen(ASol, AUst, ASag, AAlt: TISayi4; ARenk: TRenk; ADoldur: Boolean);
begin

  _Dikdortgen(FKimlik, ASol, AUst, ASag, AAlt, ARenk, ADoldur);
end;

procedure TTuval.Daire(ASol, AUst, AYariCap: TISayi4; ARenk: TRenk; ADoldur: Boolean);
begin

  _Daire(FKimlik, ASol, AUst, AYariCap, ARenk, ADoldur);
end;

procedure _HarfYaz(AKimlik: TKimlik; ASol, AUst: TISayi4; ARenk: TRenk; AKarakter: Char);
asm
  movzx eax,AKarakter
  push  eax
  push  DWORD ARenk
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AKimlik
  mov   eax,HARF_YAZ
  int   $34
  add   esp,20
end;

procedure _YaziYaz(AKimlik: TKimlik; ASol, AUst: TISayi4; ARenk: TRenk; ADeger: string);
asm
  push  DWORD ADeger
  push  DWORD ARenk
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AKimlik
  mov   eax,YAZI_YAZ
  int   $34
  add   esp,20
end;

procedure _SayiYaz10(AKimlik: TKimlik; ASol, AUst: TISayi4; ARenk: TRenk; ADeger: TISayi4);
asm
  push  DWORD ADeger
  push  DWORD ARenk
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AKimlik
  mov   eax,SAYI_YAZ10
  int   $34
  add   esp,20
end;

procedure _SayiYaz16(AKimlik: TKimlik; ASol, AUst: TISayi4; ARenk: TRenk; AOnekYaz: LongBool;
  AHaneSayisi: TSayi4; ADeger: TISayi4);
asm
  push  DWORD ADeger
  push  DWORD AHaneSayisi
  push  DWORD AOnekYaz
  push  DWORD ARenk
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AKimlik
  mov   eax,SAYI_YAZ16
  int   $34
  add   esp,28
end;

procedure _SaatYaz(AKimlik: TKimlik; ASol, AUst: TISayi4; ARenk: TRenk; ASaat: TSaat);
asm
  push  DWORD ASaat
  push  DWORD ARenk
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AKimlik
  mov   eax,SAAT_YAZ
  int   $34
  add   esp,20
end;

procedure _MACAdresiYaz(AKimlik: TKimlik; ASol, AUst: TISayi4; ARenk: TRenk; AMACAdres: PMACAdres);
asm
  push  DWORD AMACAdres
  push  DWORD ARenk
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AKimlik
  mov   eax,MACADRES_YAZ
  int   $34
  add   esp,20
end;

procedure _IPAdresiYaz(AKimlik: TKimlik; ASol, AUst: TISayi4; ARenk: TRenk; AIPAdres: PIPAdres);
asm
  push  DWORD AIPAdres
  push  DWORD ARenk
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AKimlik
  mov   eax,IPADRES_YAZ
  int   $34
  add   esp,20
end;

procedure _PixelYaz(AKimlik: TKimlik; ASol, AUst: TISayi4; ARenk: TRenk);
asm
  push  DWORD ARenk
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AKimlik
  mov   eax,PIXEL_YAZ
  int   $34
  add   esp,16
end;

procedure _Cizgi(AKimlik: TKimlik; ASol, AUst, ASag, AAlt: TISayi4;
  ACizgiTipi: TCizgiTipi; ARenk: TRenk);
asm
  push  DWORD ARenk
  push  DWORD ACizgiTipi
  push  DWORD AAlt
  push  DWORD ASag
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AKimlik
  mov   eax,CIZGI_CIZ
  int   $34
  add   esp,28
end;

procedure _Dikdortgen(AKimlik: TKimlik; ASol, AUst, ASag, AAlt: TISayi4; ARenk: TRenk; ADoldur: LongBool);
asm
  push  DWORD ADoldur
  push  DWORD ARenk
  push  DWORD AAlt
  push  DWORD ASag
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AKimlik
  mov   eax,DIKDORTGEN_CIZ
  int   $34
  add   esp,28
end;

procedure _Daire(AKimlik: TKimlik; ASol, AUst, AYariCap: TISayi4; ARenk: TRenk; ADoldur: LongBool);
asm
  push  DWORD ADoldur
  push  DWORD ARenk
  push  DWORD AYariCap
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AKimlik
  mov   eax,DAIRE_CIZ
  int   $34
  add   esp,24
end;

end.
