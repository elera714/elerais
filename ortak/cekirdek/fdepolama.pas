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

uses paylasim, aygit;

const
  USTSINIR_FD = 6;              // desteklenen fiziksel depolama aygýt sayýsý
  ILKDEGER_FDKIMLIK = $1000;    // fiziksel depolama kimlik sayacý

type
  TFizikselDepolama = class
  private
    // fiziksel sürücü listesi. en fazla 2 disket sürücüsü + 4 disk sürücüsü
    FAygitSayisi: TSayi4;
    FAygitListesi: array[0..USTSINIR_FD - 1] of TFDAygiti;
    function Al(ASiraNo: TISayi4): TFDAygiti;
    procedure Yaz(ASiraNo: TISayi4; AFDAygiti: TFDAygiti);
  public
    procedure Create;
    function AygitOlustur(AAygitTipi: TSayi4): TFDAygiti;
    function SurucuAl(ASiraNo: TISayi4): TFDAygiti;
    function SurucuAl2(AKimlik: TKimlik): TFDAygiti;
    function VeriOku(AFDAygiti: TFDAygiti; ASektorNo, ASektorSayisi: TSayi4;
      ABellek: Isaretci): TISayi4;
    function VeriYaz(AFDAygiti: TFDAygiti; ASektorNo, ASektorSayisi: TSayi4;
      ABellek: Isaretci): TISayi4;
    property AygitSayisi: TSayi4 read FAygitSayisi;
    property Aygit[ASiraNo: TISayi4]: TFDAygiti read Al write Yaz;
  end;

var
  GFizikselDepolama: TFizikselDepolama;
  PDisket1: TFDAygiti;
  PDisket2: TFDAygiti;

implementation

uses donusum, src_disket, src_ide;

{==============================================================================
  sistemdeki fiziksel depolama aygýtlarýný yükler
 ==============================================================================}
procedure TFizikselDepolama.Create;
var
  i: TSayi4;
begin

  PDisket1 := nil;
  PDisket2 := nil;

  // fiziksel sürücü deðiþkenlerini sýfýrla
  FAygitSayisi := 0;

  for i := 0 to USTSINIR_FD - 1 do Aygit[i] := nil;

  // floppy aygýtlarýný yükle
  GDisketAygitlari := GDisketAygitlari.Create;
  GDisketAygitlari.VeritabaniOlustur;

  // ide disk aygýtlarýný yükle
  GDiskAygitlari := TDiskAygitlari.Create;
  GDiskAygitlari.VeritabaniOlustur;
end;

function TFizikselDepolama.Al(ASiraNo: TISayi4): TFDAygiti;
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_FD) then
    Result := FAygitListesi[ASiraNo]
  else Result := nil;
end;

procedure TFizikselDepolama.Yaz(ASiraNo: TISayi4; AFDAygiti: TFDAygiti);
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_FD) then
    FAygitListesi[ASiraNo] := AFDAygiti;
end;

{==============================================================================
  fiziksel depolama aygýtý için sistemde sürücü oluþturma iþlevi
 ==============================================================================}
function TFizikselDepolama.AygitOlustur(AAygitTipi: TSayi4): TFDAygiti;
var
  FD: TFDAygiti;
  Disk: TIDEDisk;
  Disket: TDisket;
  i: TSayi4;
begin

  // fiziksel sürücü için yeni bellek yapýsý oluþtur
  for i := 0 to USTSINIR_FD - 1 do
  begin

    if(Aygit[i] = nil) then
    begin

      if(AAygitTipi = SURUCUTIP_DISK) then
      begin

        Disk := TIDEDisk.Create;
        Aygit[i] := Disk;
        FD := Disk;
      end
      else
      begin

        Disket := TDisket.Create;
        Aygit[i] := Disket;
        FD := Disket;
      end;

      FD.Kimlik := ILKDEGER_FDKIMLIK + i;

      FD.SurucuTipi := AAygitTipi;

      // fda = fiziksel depolama aygýtý
      FD.FAygitAdi := 'fda' + IntToStr(i + 1);

      // fiziksel sürücü sayýsýný artýr
      Inc(FAygitSayisi);

      Exit(FD);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  sýra numarasýna göre fiziksel depolama aygýtýnýn veri yapýsýný geri döndürür
 ==============================================================================}
function TFizikselDepolama.SurucuAl(ASiraNo: TISayi4): TFDAygiti;
var
  FD: TFDAygiti;
  SiraNo: TISayi4;
  i: TSayi4;
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_FD) then
  begin

    SiraNo := -1;
    for i := 0 to USTSINIR_FD - 1 do
    begin

      FD := Aygit[i];
      if not(FD = nil) then Inc(SiraNo);

      if(SiraNo = ASiraNo) then Exit(FD);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  kimlik deðerine göre fiziksel depolama aygýtýnýn veri yapýsýný geri döndürür
 ==============================================================================}
function TFizikselDepolama.SurucuAl2(AKimlik: TKimlik): TFDAygiti;
var
  FD: TFDAygiti;
  i: TSayi4;
begin

  for i := 0 to USTSINIR_FD - 1 do
  begin

    FD := Aygit[i];
    if not(FD = nil) and (FD.Kimlik = AKimlik) then Exit(FD);
  end;

  Result := nil;
end;

{==============================================================================
  fiziksel depolama aygýtýndan veri oku
 ==============================================================================}
function TFizikselDepolama.VeriOku(AFDAygiti: TFDAygiti; ASektorNo, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4;
begin

{  SISTEM_MESAJ(RENK_MAVI, 'Depolama Kimlik: %d', [AFizikselDepolama^.FD3.Kimlik]);
  SISTEM_MESAJ(RENK_MAVI, 'Depolama Sürücü Tipi: %d', [AFizikselDepolama^.FD3.SurucuTipi]);
  SISTEM_MESAJ(RENK_MAVI, 'Depolama Adý: %s', [AFizikselDepolama^.FD3.AygitAdi]);
  SISTEM_MESAJ(RENK_MAVI, 'Okunacak Ýlk Sektör: %d', [ASektorNo]);
  SISTEM_MESAJ(RENK_MAVI, 'Okunacak Sektör Sayýsý: %d', [ASektorSayisi]); }

  Result := AFDAygiti.FOku(ASektorNo, ASektorSayisi, ABellek);
end;

{==============================================================================
  fiziksel depolama aygýtýna veri yaz
 ==============================================================================}
function TFizikselDepolama.VeriYaz(AFDAygiti: TFDAygiti; ASektorNo, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4;
begin

  Result := AFDAygiti.FYaz(ASektorNo, ASektorSayisi, ABellek);
end;

end.
