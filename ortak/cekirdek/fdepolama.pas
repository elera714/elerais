{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: fdepolama.pas
  Dosya Ýþlevi: fiziksel depolama aygýt iþlevlerini yönetir

  Güncelleme Tarihi: 29/07/2025

 ==============================================================================}
{$mode objfpc}
unit fdepolama;

interface

uses paylasim;

const
  USTSINIR_FIZIKSELDEPOLAMA       = 6;
  ILKDEGER_FDKIMLIK               = $1000;    // fiziksel depolama

// fiziksel depolama nesnesi - program için
type
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

// fiziksel depolama nesnesi - sistem için
type
  PFDNesne = ^TFDNesne;
  TFDNesne = record
    FD3: TFDNesne3;
    Ozellikler: TSayi1;
    SonIzKonumu: TISayi1;           // floppy sürücüsünün kafasýnýn bulunduðu son iz (track) no
    IslemYapiliyor: Boolean;        // True = sürücü iþlem yapmakta, False = sürücü boþta
    MotorSayac: TSayi4;             // motor kapatma geri sayým sayacý (þu an sadece floppy sürücüsü için)
    Aygit: TIDEDisk;                // depolama aygýtý
    SektorOku: TSektorIslev;        // sektör okuma iþlevi
    SektorYaz: TSektorIslev;        // sektör yazma iþlevi
  end;

type
  TFizikselDepolama = object
  private
    // fiziksel sürücü listesi. en fazla 2 floppy sürücüsü + 4 disk sürücüsü
    FFDAygitSayisi: TSayi4;
    FFDAygitListesi: array[0..USTSINIR_FIZIKSELDEPOLAMA - 1] of PFDNesne;
    function FDAygitiAl(ASiraNo: TISayi4): PFDNesne;
    procedure FDAygitiYaz(ASiraNo: TISayi4; AFDNesne: PFDNesne);
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
    property FDAygiti[ASiraNo: TISayi4]: PFDNesne read FDAygitiAl write FDAygitiYaz;
  end;

var
  FizikselDepolama0: TFizikselDepolama;
  PDisket1: PFDNesne;
  PDisket2: PFDNesne;

implementation

uses sistemmesaj, donusum, src_disket, src_ide;

{==============================================================================
  sistemdeki fiziksel depolama aygýtlarýný yükler
 ==============================================================================}
procedure TFizikselDepolama.Yukle;
var
  i: TSayi4;
begin

  // fiziksel sürücü deðiþkenlerini sýfýrla
  FizikselDepolama0.FDAygitSayisi := 0;

  for i := 0 to USTSINIR_FIZIKSELDEPOLAMA - 1 do FDAygiti[i] := nil;

  // floppy aygýtlarýný yükle
  src_disket.Yukle;

  // ide disk aygýtlarýný yükle
  src_ide.Yukle;
end;

function TFizikselDepolama.FDAygitiAl(ASiraNo: TISayi4): PFDNesne;
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_FIZIKSELDEPOLAMA) then
    Result := FFDAygitListesi[ASiraNo]
  else Result := nil;
end;

procedure TFizikselDepolama.FDAygitiYaz(ASiraNo: TISayi4; AFDNesne: PFDNesne);
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_FIZIKSELDEPOLAMA) then
    FFDAygitListesi[ASiraNo] := AFDNesne;
end;

{==============================================================================
  fiziksel depolama aygýtý için sistemde sürücü oluþturma iþlevi
 ==============================================================================}
function TFizikselDepolama.FDAygitiOlustur(AAygitTipi: TSayi4): PFDNesne;
var
  FD: PFDNesne;
  i: TSayi4;
begin

  // fiziksel sürücü için yeni bellek yapýsý oluþtur
  for i := 0 to USTSINIR_FIZIKSELDEPOLAMA - 1 do
  begin

    FD := FDAygiti[i];

    if(FD = nil) then
    begin

      FD := GetMem(Sizeof(TFDNesne));
      FDAygiti[i] := FD;

      FD^.FD3.SurucuTipi := AAygitTipi;

      FD^.FD3.Kimlik := ILKDEGER_FDKIMLIK + i;

      // fda = fiziksel depolama aygýtý
      FD^.FD3.AygitAdi := 'fda' + IntToStr(i + 1);

      // fiziksel sürücü sayýsýný artýr
      Inc(FizikselDepolama0.FFDAygitSayisi);

      Exit(FD);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  sýra numarasýna göre fiziksel depolama aygýtýnýn veri yapýsýný geri döndürür
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
  kimlik deðerine göre fiziksel depolama aygýtýnýn veri yapýsýný geri döndürür
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
  fiziksel depolama aygýtýndan veri oku
 ==============================================================================}
function TFizikselDepolama.FizikselDepolamaVeriOku(AFDNesne: PFDNesne; ASektorNo,
  ASektorSayisi: TSayi4; ABellek: Isaretci): TISayi4;
begin

{  SISTEM_MESAJ(RENK_MAVI, 'Depolama Kimlik: %d', [AFizikselDepolama^.FD3.Kimlik]);
  SISTEM_MESAJ(RENK_MAVI, 'Depolama Sürücü Tipi: %d', [AFizikselDepolama^.FD3.SurucuTipi]);
  SISTEM_MESAJ(RENK_MAVI, 'Depolama Adý: %s', [AFizikselDepolama^.FD3.AygitAdi]);
  SISTEM_MESAJ(RENK_MAVI, 'Okunacak Ýlk Sektör: %d', [ASektorNo]);
  SISTEM_MESAJ(RENK_MAVI, 'Okunacak Sektör Sayýsý: %d', [ASektorSayisi]); }

  Result := AFDNesne^.SektorOku(AFDNesne, ASektorNo, ASektorSayisi, ABellek);
end;

{==============================================================================
  fiziksel depolama aygýtýna veri yaz
 ==============================================================================}
function TFizikselDepolama.FizikselDepolamaVeriYaz(AFDNesne: PFDNesne; ASektorNo,
  ASektorSayisi: TSayi4; ABellek: Isaretci): TISayi4;
begin

  Result := AFDNesne^.SektorYaz(AFDNesne, ASektorNo, ASektorSayisi, ABellek);
end;

end.
