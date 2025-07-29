{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: fdepolama.pas
  Dosya ��levi: fiziksel depolama ayg�t i�levlerini y�netir

  G�ncelleme Tarihi: 29/07/2025

 ==============================================================================}
{$mode objfpc}
unit fdepolama;

interface

uses paylasim;

const
  USTSINIR_FIZIKSELDEPOLAMA       = 6;
  ILKDEGER_FDKIMLIK               = $1000;    // fiziksel depolama

// fiziksel depolama ayg�t yap�s� - program i�in
type
  { TODO - TFizikselDepolama3 -> TFDNesne3 olarak de�i�tirildi, programlar g�ncellenecek }
  PFDNesne3 = ^TFDNesne3;
  TFDNesne3 = packed record
    Kimlik: TKimlik;
    SurucuTipi: TSayi4;
    AygitAdi: string[16];
    KafaSayisi: TSayi4;
    SilindirSayisi: TSayi4;
    IzBasinaSektorSayisi: TSayi4;
    ToplamSektorSayisi: TSayi4;
  end;

// fiziksel depolama ayg�t yap�s� - sistem i�in
type
  PFDNesne = ^TFDNesne;
  TFDNesne = record
    FD3: TFDNesne3;
    Ozellikler: TSayi1;
    SonIzKonumu: TISayi1;           // floppy s�r�c�s�n�n kafas�n�n bulundu�u son iz (track) no
    IslemYapiliyor: Boolean;        // True = s�r�c� i�lem yapmakta, False = s�r�c� bo�ta
    MotorSayac: TSayi4;             // motor kapatma geri say�m sayac� (�u an sadece floppy s�r�c�s� i�in)
    Aygit: TIDEDisk;                // depolama ayg�t�
    SektorOku: TSektorIslev;        // sekt�r okuma i�levi
    SektorYaz: TSektorIslev;        // sekt�r yazma i�levi
  end;

type
  TFizikselDepolama = object
  private
    // fiziksel s�r�c� listesi. en fazla 2 floppy s�r�c�s� + 4 disk s�r�c�s�
    FFDAygitSayisi: TSayi4;
    FFDAygitListesi: array[0..USTSINIR_FIZIKSELDEPOLAMA - 1] of PFDNesne;
    function FDAygitiAl(ASiraNo: TSayi4): PFDNesne;
    procedure FDAygitiYaz(ASiraNo: TSayi4; AFDNesne: PFDNesne);
  public
    procedure Yukle;
    function FDAygitiOlustur(AAygitTipi: TSayi4): PFDNesne;
    function FizikselSurucuAl(ASiraNo: TISayi4): PFDNesne;
    function FizikselSurucuAl2(AKimlik: TKimlik): PFDNesne;
    function FizikselDepolamaVeriOku(AFDNesne: PFDNesne; ASektorNo,
      ASektorSayisi: TSayi4; ABellek: Isaretci): TISayi4;
    function FizikselDepolamaVeriYaz(AFDNesne: PFDNesne; ASektorNo,
      ASektorSayisi: TSayi4; ABellek: Isaretci): TISayi4;
    property FDAygitSayisi: TSayi4 read FFDAygitSayisi write FFDAygitSayisi;
    property FDAygiti[ASiraNo: TSayi4]: PFDNesne read FDAygitiAl write FDAygitiYaz;
  end;

var
  FizikselDepolama0: TFizikselDepolama;
  PDisket1: PFDNesne;
  PDisket2: PFDNesne;

implementation

uses sistemmesaj, donusum, src_disket, src_ide;

{==============================================================================
  sistemdeki fiziksel depolama ayg�tlar�n� y�kler
 ==============================================================================}
procedure TFizikselDepolama.Yukle;
var
  i: TSayi4;
begin

  // fiziksel s�r�c� de�i�kenlerini s�f�rla
  FizikselDepolama0.FDAygitSayisi := 0;

  for i := 0 to USTSINIR_FIZIKSELDEPOLAMA - 1 do FDAygiti[i] := nil;

  // floppy ayg�tlar�n� y�kle
  src_disket.Yukle;

  // ide disk ayg�tlar�n� y�kle
  src_ide.Yukle;
end;

function TFizikselDepolama.FDAygitiAl(ASiraNo: TSayi4): PFDNesne;
begin

  // istenen verinin belirtilen aral�kta olup olmad���n� kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_FIZIKSELDEPOLAMA) then
    Result := FFDAygitListesi[ASiraNo]
  else Result := nil;
end;

procedure TFizikselDepolama.FDAygitiYaz(ASiraNo: TSayi4; AFDNesne: PFDNesne);
begin

  // istenen verinin belirtilen aral�kta olup olmad���n� kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_FIZIKSELDEPOLAMA) then
    FFDAygitListesi[ASiraNo] := AFDNesne;
end;

{==============================================================================
  fiziksel depolama ayg�t� i�in sistemde s�r�c� olu�turma i�levi
 ==============================================================================}
function TFizikselDepolama.FDAygitiOlustur(AAygitTipi: TSayi4): PFDNesne;
var
  FD: PFDNesne;
  i: TSayi4;
begin

  // fiziksel s�r�c� i�in yeni bellek yap�s� olu�tur
  for i := 0 to USTSINIR_FIZIKSELDEPOLAMA - 1 do
  begin

    FD := FDAygiti[i];

    if(FD = nil) then
    begin

      FD := GetMem(Sizeof(TFDNesne));
      FDAygiti[i] := FD;

      FD^.FD3.SurucuTipi := AAygitTipi;

      FD^.FD3.Kimlik := ILKDEGER_FDKIMLIK + i;

      // fda = fiziksel depolama ayg�t�
      FD^.FD3.AygitAdi := 'fda' + IntToStr(i + 1);

      // fiziksel s�r�c� say�s�n� art�r
      Inc(FizikselDepolama0.FFDAygitSayisi);

      Exit(FD);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  s�ra numaras�na g�re fiziksel depolama ayg�t�n�n veri yap�s�n� geri d�nd�r�r
 ==============================================================================}
function TFizikselDepolama.FizikselSurucuAl(ASiraNo: TISayi4): PFDNesne;
var
  FD: PFDNesne;
  SiraNo: TISayi4;
  i: TSayi4;
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_FIZIKSELDEPOLAMA) then
  begin

    SiraNo := -1;
    for i := 0 to USTSINIR_FIZIKSELDEPOLAMA - 1 do
    begin

      FD := FDAygiti[i];
      if not(FD = nil) then Inc(SiraNo);

      if(SiraNo = ASiraNo) then Exit(FD);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  kimlik de�erine g�re fiziksel depolama ayg�t�n�n veri yap�s�n� geri d�nd�r�r
 ==============================================================================}
function TFizikselDepolama.FizikselSurucuAl2(AKimlik: TKimlik): PFDNesne;
var
  FD: PFDNesne;
  i: TSayi4;
begin

  for i := 0 to USTSINIR_FIZIKSELDEPOLAMA - 1 do
  begin

    FD := FDAygiti[i];
    if not(FD = nil) and (FD^.FD3.Kimlik = AKimlik) then Exit(FD);
  end;

  Result := nil;
end;

{==============================================================================
  fiziksel depolama ayg�t�ndan veri oku
 ==============================================================================}
function TFizikselDepolama.FizikselDepolamaVeriOku(AFDNesne: PFDNesne; ASektorNo,
  ASektorSayisi: TSayi4; ABellek: Isaretci): TISayi4;
begin

{  SISTEM_MESAJ(RENK_MAVI, 'Depolama Kimlik: %d', [AFizikselDepolama^.FD3.Kimlik]);
  SISTEM_MESAJ(RENK_MAVI, 'Depolama S�r�c� Tipi: %d', [AFizikselDepolama^.FD3.SurucuTipi]);
  SISTEM_MESAJ(RENK_MAVI, 'Depolama Ad�: %s', [AFizikselDepolama^.FD3.AygitAdi]);
  SISTEM_MESAJ(RENK_MAVI, 'Okunacak �lk Sekt�r: %d', [ASektorNo]);
  SISTEM_MESAJ(RENK_MAVI, 'Okunacak Sekt�r Say�s�: %d', [ASektorSayisi]); }

  Result := AFDNesne^.SektorOku(AFDNesne, ASektorNo, ASektorSayisi, ABellek);
end;

{==============================================================================
  fiziksel depolama ayg�t�na veri yaz
 ==============================================================================}
function TFizikselDepolama.FizikselDepolamaVeriYaz(AFDNesne: PFDNesne; ASektorNo,
  ASektorSayisi: TSayi4; ABellek: Isaretci): TISayi4;
begin

  Result := AFDNesne^.SektorYaz(AFDNesne, ASektorNo, ASektorSayisi, ABellek);
end;

end.
