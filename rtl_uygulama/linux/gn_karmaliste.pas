{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_karmaliste.pas
  Dosya İşlevi: karma liste (açılır / kapanır liste kutusu (TComboBox)) yönetim işlevlerini içerir

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gn_karmaliste;

interface

type
  PKarmaListe = ^TKarmaListe;
  TKarmaListe = object
  private
    FKimlik: TKimlik;
    function BaslikSiraNoAl: TISayi4;
    procedure BaslikSiraNoYaz(ASiraNo: TISayi4);
  public
    function Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
    procedure Goster;
    procedure Hizala(AHiza: THiza);
    procedure ElemanEkle(AElemanAdi: string);
    procedure Temizle;
    function SeciliYaziAl: string;
    function ElemanSayisi: TSayi4;

    property Kimlik: TKimlik read FKimlik;
    property BaslikSiraNo: TISayi4 read BaslikSiraNoAl write BaslikSiraNoYaz;
  end;

function _KarmaListeOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik; assembler;
procedure _KarmaListeGoster(AKimlik: TKimlik); assembler;
procedure _KarmaListeHizala(AKimlik: TKimlik; AHiza: THiza); assembler;
procedure _KarmaListeElemanEkle(AKimlik: TKimlik; AElemanAdi: string); assembler;
procedure _KarmaListeTemizle(AKimlik: TKimlik); assembler;
procedure _KarmaListeSeciliYaziAl(AKimlik: TKimlik; AHedefBellek: Isaretci); assembler;
function _KarmaListeElemanSayisi(AKimlik: TKimlik): TSayi4; assembler;
function _KarmaListeBaslikSiraNoAl(AKimlik: TKimlik): TISayi4; assembler;
procedure _KarmaListeBaslikSiraNoYaz(AKimlik: TKimlik; ASiraNo: TISayi4); assembler;

implementation

function TKarmaListe.Olustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
begin

  FKimlik := _KarmaListeOlustur(AAtaKimlik, ASol, AUst, AGenislik, AYukseklik);
  Result := FKimlik;
end;

procedure TKarmaListe.Goster;
begin

  _KarmaListeGoster(FKimlik);
end;

procedure TKarmaListe.Hizala(AHiza: THiza);
begin

  _KarmaListeHizala(FKimlik, AHiza);
end;

procedure TKarmaListe.ElemanEkle(AElemanAdi: string);
begin

  _KarmaListeElemanEkle(FKimlik, AElemanAdi);
end;

procedure TKarmaListe.Temizle;
begin

  _KarmaListeTemizle(FKimlik);
end;

function TKarmaListe.SeciliYaziAl: string;
var
  s: string;
begin

  _KarmaListeSeciliYaziAl(FKimlik, Isaretci(@s[0]));
  Result := s;
end;

function TKarmaListe.ElemanSayisi: TSayi4;
begin

  Result := _KarmaListeElemanSayisi(FKimlik);
end;

function TKarmaListe.BaslikSiraNoAl: TISayi4;
begin

  Result := _KarmaListeBaslikSiraNoAl(FKimlik);
end;

procedure TKarmaListe.BaslikSiraNoYaz(ASiraNo: TISayi4);
begin

  _KarmaListeBaslikSiraNoYaz(FKimlik, ASiraNo);
end;

function _KarmaListeOlustur(AAtaKimlik: TKimlik; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
asm
  push  DWORD AYukseklik
  push  DWORD AGenislik
  push  DWORD AUst
  push  DWORD ASol
  push  DWORD AAtaKimlik
  mov   eax,KARMALISTE_OLUSTUR
  int   $34
  add   esp,20
end;

procedure _KarmaListeGoster(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,KARMALISTE_GOSTER
  int   $34
  add   esp,4
end;

procedure _KarmaListeHizala(AKimlik: TKimlik; AHiza: THiza);
asm
  push  DWORD AHiza
  push  DWORD AKimlik
  mov   eax,KARMALISTE_HIZALA
  int   $34
  add   esp,8
end;

procedure _KarmaListeElemanEkle(AKimlik: TKimlik; AElemanAdi: string);
asm
  push  DWORD AElemanAdi
  push  DWORD AKimlik
  mov   eax,KARMALISTE_YAZ_ELEMANEKLE
  int   $34
  add   esp,8
end;

procedure _KarmaListeTemizle(AKimlik: TKimlik);
asm
  push  DWORD AKimlik
  mov   eax,KARMALISTE_YAZ_TEMIZLE
  int   $34
  add   esp,4
end;

procedure _KarmaListeSeciliYaziAl(AKimlik: TKimlik; AHedefBellek: Isaretci);
asm
  push  DWORD AHedefBellek
  push  DWORD AKimlik
  mov   eax,KARMALISTE_AL_SECILIYAZI
  int   $34
  add   esp,8
end;

function _KarmaListeElemanSayisi(AKimlik: TKimlik): TSayi4;
asm
  push  DWORD AKimlik
  mov   eax,KARMALISTE_AL_TOPLAMKAYIT
  int   $34
  add   esp,4
end;

function _KarmaListeBaslikSiraNoAl(AKimlik: TKimlik): TISayi4;
asm
  push  DWORD AKimlik
  mov   eax,KARMALISTE_AL_BASLIKSN
  int   $34
  add   esp,4
end;

procedure _KarmaListeBaslikSiraNoYaz(AKimlik: TKimlik; ASiraNo: TISayi4);
asm
  push  DWORD ASiraNo
  push  DWORD AKimlik
  mov   eax,KARMALISTE_YAZ_BASLIKSN
  int   $34
  add   esp,8
end;

end.
