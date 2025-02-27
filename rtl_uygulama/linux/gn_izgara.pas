{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_izgara.pas
  Dosya İşlevi: ızgara nesnesi (TStringGrid) yönetim işlevlerini içerir

  Güncelleme Tarihi: 27/02/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gn_izgara;

interface

type
  PIzgara = ^TIzgara;
  TIzgara = object
  private
    FKimlik: TKimlik;
  public
    function Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
    procedure Goster;
    procedure Gizle;
    procedure Ciz;
    procedure Hizala(AHiza: THiza);
    procedure Temizle;
    procedure ElemanEkle(AElemanAdi: string);
    procedure SabitHucreSayisiYaz(ASabitSatirSayisi, ASabitSutunSayisi: TSayi4);
    procedure HucreSayisiYaz(ASatirSayisi, ASutunSayisi: TSayi4);
    procedure HucreBoyutuYaz(ASatirYukseklik, ASutunGenislik: TSayi4);
    procedure KaydirmaCubuguGorunumYaz(AYatayKCGoster, ADikeyKCGoster: LongBool);
    procedure SeciliHucreyiYaz(ASatir, ASutun: TISayi4);
    property Kimlik: TKimlik read FKimlik;
  end;

function IzgaraOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik; assembler;
procedure IzgaraGoster(AKimlik: TKimlik); assembler;
procedure IzgaraGizle(AKimlik: TKimlik); assembler;
procedure IzgaraCiz(AKimlik: TKimlik); assembler;
procedure IzgaraHizala(AKimlik: TKimlik; AHiza: THiza); assembler;
procedure IzgaraTemizle(AKimlik: TKimlik); assembler;
procedure IzgaraElemanEkle(AKimlik: TKimlik; AElemanAdi: string); assembler;
procedure IzgaraSabitHucreSayisiYaz(AKimlik: TKimlik; ASabitSatirSayisi, ASabitSutunSayisi: TSayi4); assembler;
procedure IzgaraHucreSayisiYaz(AKimlik: TKimlik; ASatirSayisi, ASutunSayisi: TSayi4); assembler;
procedure IzgaraHucreBoyutuYaz(AKimlik: TKimlik; ASatirYukseklik, ASutunGenislik: TSayi4); assembler;
procedure IzgaraKaydirmaCubuguGorunumYaz(AKimlik: TKimlik; AYatayKCGoster, ADikeyKCGoster: LongBool); assembler;
procedure IzgaraSeciliHucreyiYaz(AKimlik: TKimlik; ASatir, ASutun: TISayi4); assembler;

implementation

function TIzgara.Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik,
  AYukseklik: TISayi4): TKimlik;
begin

  FKimlik := IzgaraOlustur(AAtaKimlik, ASol, AUst, AGenislik, AYukseklik);
  Result := FKimlik;
end;

procedure TIzgara.Goster;
begin

  IzgaraGoster(FKimlik);
end;

procedure TIzgara.Gizle;
begin

  IzgaraGizle(FKimlik);
end;

procedure TIzgara.Ciz;
begin

  IzgaraCiz(FKimlik);
end;

procedure TIzgara.Hizala(AHiza: THiza);
begin

  IzgaraHizala(FKimlik, AHiza);
end;

procedure TIzgara.Temizle;
begin

  IzgaraTemizle(FKimlik);
end;

procedure TIzgara.ElemanEkle(AElemanAdi: string);
begin

  IzgaraElemanEkle(FKimlik, AElemanAdi);
end;

procedure TIzgara.SabitHucreSayisiYaz(ASabitSatirSayisi, ASabitSutunSayisi: TSayi4);
begin

  IzgaraSabitHucreSayisiYaz(FKimlik, ASabitSatirSayisi, ASabitSutunSayisi);
end;

procedure TIzgara.HucreSayisiYaz(ASatirSayisi, ASutunSayisi: TSayi4);
begin

  IzgaraHucreSayisiYaz(FKimlik, ASatirSayisi, ASutunSayisi);
end;

procedure TIzgara.HucreBoyutuYaz(ASatirYukseklik, ASutunGenislik: TSayi4);
begin

  IzgaraHucreBoyutuYaz(FKimlik, ASatirYukseklik, ASutunGenislik);
end;

procedure TIzgara.KaydirmaCubuguGorunumYaz(AYatayKCGoster, ADikeyKCGoster: LongBool);
begin

  IzgaraKaydirmaCubuguGorunumYaz(FKimlik, AYatayKCGoster, ADikeyKCGoster);
end;

procedure TIzgara.SeciliHucreyiYaz(ASatir, ASutun: TISayi4);
begin

  IzgaraSeciliHucreyiYaz(FKimlik, ASatir, ASutun);
end;

function IzgaraOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik; assembler;
asm
  push  DWORD AYukseklik
  push  DWORD AGenislik
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AAtaKimlik
  mov   eax,IZGARA_OLUSTUR
  int   $34
  add   esp,20
end;

procedure IzgaraGoster(AKimlik: TKimlik); assembler;
asm
  push  DWORD AKimlik
  mov   eax,IZGARA_GOSTER
  int   $34
  add   esp,4
end;

procedure IzgaraGizle(AKimlik: TKimlik); assembler;
asm
  push  DWORD AKimlik
  mov   eax,IZGARA_GIZLE
  int   $34
  add   esp,4
end;

procedure IzgaraCiz(AKimlik: TKimlik); assembler;
asm
  push  DWORD AKimlik
  mov   eax,IZGARA_CIZ
  int   $34
  add   esp,4
end;

procedure IzgaraHizala(AKimlik: TKimlik; AHiza: THiza); assembler;
asm
  push  DWORD AHiza
  push  DWORD AKimlik
  mov   eax,IZGARA_HIZALA
  int   $34
  add   esp,8
end;

procedure IzgaraTemizle(AKimlik: TKimlik); assembler;
asm
  push  DWORD AKimlik
  mov   eax,IZGARA_YAZ_TEMIZLE
  int   $34
  add   esp,4
end;

procedure IzgaraElemanEkle(AKimlik: TKimlik; AElemanAdi: string); assembler;
asm
  push  DWORD AElemanAdi
  push  DWORD AKimlik
  mov   eax,IZGARA_YAZ_ELEMANEKLE
  int   $34
  add   esp,8
end;

procedure IzgaraSabitHucreSayisiYaz(AKimlik: TKimlik; ASabitSatirSayisi, ASabitSutunSayisi: TSayi4); assembler;
asm
  push  DWORD ASabitSutunSayisi
  push  DWORD ASabitSatirSayisi
  push  DWORD AKimlik
  mov   eax,IZGARA_YAZ_SABITHUCRESAYISI
  int   $34
  add   esp,12
end;

procedure IzgaraHucreSayisiYaz(AKimlik: TKimlik; ASatirSayisi, ASutunSayisi: TSayi4); assembler;
asm
  push  DWORD ASutunSayisi
  push  DWORD ASatirSayisi
  push  DWORD AKimlik
  mov   eax,IZGARA_YAZ_HUCRESAYISI
  int   $34
  add   esp,12
end;

procedure IzgaraHucreBoyutuYaz(AKimlik: TKimlik; ASatirYukseklik, ASutunGenislik: TSayi4); assembler;
asm
  push  DWORD ASutunGenislik
  push  DWORD ASatirYukseklik
  push  DWORD AKimlik
  mov   eax,IZGARA_YAZ_HUCREBOYUTU
  int   $34
  add   esp,12
end;

procedure IzgaraKaydirmaCubuguGorunumYaz(AKimlik: TKimlik; AYatayKCGoster, ADikeyKCGoster: LongBool); assembler;
asm
  push  DWORD ADikeyKCGoster
  push  DWORD AYatayKCGoster
  push  DWORD AKimlik
  mov   eax,IZGARA_YAZ_KCUBUGUGORUNUM
  int   $34
  add   esp,12
end;

procedure IzgaraSeciliHucreyiYaz(AKimlik: TKimlik; ASatir, ASutun: TISayi4); assembler;
asm
  push  DWORD ASutun
  push  DWORD ASatir
  push  DWORD AKimlik
  mov   eax,IZGARA_YAZ_SECILIHUCRE
  int   $34
  add   esp,12
end;

end.
