{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: dosya.pas
  Dosya Ýþlevi: dosya (file) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 09/01/2025

 ==============================================================================}
{$mode objfpc}
unit dosya;

interface

uses paylasim;

procedure Yukle;
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi2;
  var ADosyaArama: TDosyaArama): TISayi4;
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
procedure Reset(ADosyaKimlik: TKimlik);
function IOResult: TISayi4;
function EOF(ADosyaKimlik: TKimlik): Boolean;
function FileSize(ADosyaKimlik: TKimlik): TISayi4;
function Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci): TISayi4;
procedure CloseFile(ADosyaKimlik: TKimlik);
function AramaKaydiOlustur: TKimlik;
procedure AramaKaydiniYokEt(ADosyaKimlik: TKimlik);
function DosyaKaydiOlustur: TKimlik;
procedure DosyaKaydiniYokEt(ADosyaKimlik: TKimlik);

implementation

uses bolumleme, fat12, fat16, fat32, sistemmesaj, islevler;

{==============================================================================
  dosya sistem iþlevlerinin kullanacaðý deðiþkenleri ilk deðerlerle yükle
 ==============================================================================}
procedure Yukle;
var
  i: TISayi4;
begin

  // öndeðer dosya iþlem dönüþ deðeri. IOResult için
  FileResult := 0;

  // arama deðiþkenlerini sýfýrla
  for i := 0 to USTSINIR_ARAMAKAYIT - 1 do
  begin

    GAramaKayitListesi[i].Kullanilabilir := True;
  end;

  // dosya iþlev deðiþkenlerini sýfýrla
  for i := 0 to USTSINIR_DOSYAKAYIT - 1 do
  begin

    GDosyaKayitListesi[i].Kullanilabilir := True;
  end;
end;

{==============================================================================
  dosya arama iþlevini baþlatýr
 ==============================================================================}
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi2;
  var ADosyaArama: TDosyaArama): TISayi4;
var
  MD: PMantiksalDepolama;
  AramaKimlik: TKimlik;
  DST: TSayi4;
  AranacakDeger: string;
  KalinanSira, UTamAramaYolu,
  AramaSonuc: TISayi4;
begin

  // arama için arama bilgilerinin saklanacaðý bellek bölgesi tahsis et
  AramaKimlik := AramaKaydiOlustur;
  if(AramaKimlik = -1) then
  begin

    Result := 1;
    Exit;
  end;

  // arama kaydýný, çaðýran iþlevin deðiþkenine sakla
  ADosyaArama.Kimlik := AramaKimlik;

  // arama iþlevinin yapýlacaðý sürücüyü al
  MD := SurucuAl(AAramaSuzgec, KalinanSira);
  if(MD = nil) then
  begin

    // arama için kullanýlan bellek bölgesini serbest býrak
    AramaKaydiniYokEt(AramaKimlik);
    Result := 1;
    Exit;
  end;

  if not(AAramaSuzgec[KalinanSira] = '\') then
  begin

    SISTEM_MESAJ(RENK_KIRMIZI, 'DOSYA.PAS: AranacakDeger hatalý!', []);
    Result := 1;
    Exit;
  end;

  AranacakDeger := '';
  Inc(KalinanSira);
  UTamAramaYolu := Length(AAramaSuzgec);
  while (AAramaSuzgec[KalinanSira] <> '\') and (KalinanSira <= UTamAramaYolu) do
  begin

    AranacakDeger += AAramaSuzgec[KalinanSira];
    Inc(KalinanSira);
  end;

  if(AranacakDeger = '*.*') then
  begin

    // sürücüyü arama bellek bölgesine ekle
    GAramaKayitListesi[AramaKimlik].MantiksalDepolama := MD;

    // arama iþlevinin aktif olarak kullanacaðý deðiþkenleri ata
    GAramaKayitListesi[AramaKimlik].DizinGirisi.IlkSektor := MD^.Acilis.DizinGirisi.IlkSektor;
    GAramaKayitListesi[AramaKimlik].DizinGirisi.ToplamSektor := MD^.Acilis.DizinGirisi.ToplamSektor;
    GAramaKayitListesi[AramaKimlik].DizinGirisi.GirdiSayisi := MD^.Acilis.DizinGirisi.GirdiSayisi;
    GAramaKayitListesi[AramaKimlik].DizinGirisi.DizinTablosuKayitNo := -1;

    // dosya sistem tipine göre iþlevi yönlendir
    DST := GAramaKayitListesi[AramaKimlik].MantiksalDepolama^.MD3.DST;
    case DST of
      DST_FAT12     : Result := fat12.FindFirst(AranacakDeger, ADosyaOzellik, ADosyaArama);
      DST_FAT16     : Result := fat16.FindFirst(AranacakDeger, ADosyaOzellik, ADosyaArama);
      DST_FAT32,
      DST_FAT32LBA  : Result := fat32.FindFirst(AranacakDeger, ADosyaOzellik, ADosyaArama);
      else Result := 1;
    end;
  end
  else
  begin

    // -> yukarýdaki yapý ile ayný
    // sürücüyü arama bellek bölgesine ekle
    GAramaKayitListesi[AramaKimlik].MantiksalDepolama := MD;

    // arama iþlevinin aktif olarak kullanacaðý deðiþkenleri ata
    GAramaKayitListesi[AramaKimlik].DizinGirisi.IlkSektor := MD^.Acilis.DizinGirisi.IlkSektor;
    GAramaKayitListesi[AramaKimlik].DizinGirisi.ToplamSektor := MD^.Acilis.DizinGirisi.ToplamSektor;
    GAramaKayitListesi[AramaKimlik].DizinGirisi.GirdiSayisi := MD^.Acilis.DizinGirisi.GirdiSayisi;
    GAramaKayitListesi[AramaKimlik].DizinGirisi.DizinTablosuKayitNo := -1;

    // dosya sistem tipine göre iþlevi yönlendir
    DST := GAramaKayitListesi[AramaKimlik].MantiksalDepolama^.MD3.DST;
    case DST of
      DST_FAT12     : AramaSonuc := fat12.FindFirst(AranacakDeger, ADosyaOzellik, ADosyaArama);
      DST_FAT16     : AramaSonuc := fat16.FindFirst(AranacakDeger, ADosyaOzellik, ADosyaArama);
      DST_FAT32,
      DST_FAT32LBA  : AramaSonuc := fat32.FindFirst(AranacakDeger, ADosyaOzellik, ADosyaArama);
      else AramaSonuc := 1;
    end;
    // <- yukarýdaki yapý ile ayný

    if not(AranacakDeger = '*.*') and (AramaSonuc = 0) then
    begin

      {SISTEM_MESAJ(RENK_SIYAH, 'Aranacak Deðer: ', AranacakDeger, []);
      SISTEM_MESAJ_S16(RENK_SIYAH, 'BaslangicKumeNo: ', ADosyaArama.BaslangicKumeNo, 8);
      SISTEM_MESAJ(RENK_SIYAH, 'Dosya Adý: ', ADosyaArama.DosyaAdi, []);
      SISTEM_MESAJ_S16(RENK_SIYAH, 'DosyaUzunlugu: ', ADosyaArama.DosyaUzunlugu, 8);
      SISTEM_MESAJ_S16(RENK_SIYAH, 'IlkSektor: ', AramaKayitListesi[AramaKimlik].DizinGirisi.IlkSektor, 8);}

      //AramaSonuc := 1;

      // -> yukarýdaki yapý ile ayný
      // sürücüyü arama bellek bölgesine ekle
      GAramaKayitListesi[AramaKimlik].MantiksalDepolama := MD;

      // arama iþlevinin aktif olarak kullanacaðý deðiþkenleri ata
      GAramaKayitListesi[AramaKimlik].DizinGirisi.IlkSektor :=
        ADosyaArama.BaslangicKumeNo + 622;
      GAramaKayitListesi[AramaKimlik].DizinGirisi.ToplamSektor := 1;
      GAramaKayitListesi[AramaKimlik].DizinGirisi.GirdiSayisi := 16;
      GAramaKayitListesi[AramaKimlik].DizinGirisi.DizinTablosuKayitNo := -1;

      AranacakDeger := '*.*';
      GAramaKayitListesi[AramaKimlik].Aranan := '*.*';

      // dosya sistem tipine göre iþlevi yönlendir
      DST := GAramaKayitListesi[AramaKimlik].MantiksalDepolama^.MD3.DST;
      case DST of
        DST_FAT12     : AramaSonuc := fat12.FindFirst(AranacakDeger, ADosyaOzellik, ADosyaArama);
        DST_FAT16     : AramaSonuc := fat16.FindFirst(AranacakDeger, ADosyaOzellik, ADosyaArama);
        DST_FAT32,
        DST_FAT32LBA  : AramaSonuc := fat32.FindFirst(AranacakDeger, ADosyaOzellik, ADosyaArama);
        else AramaSonuc := 1;
      end;
      // <- yukarýdaki yapý ile ayný
    end;

    Result := AramaSonuc;
  end;
end;

{==============================================================================
  dosya arama iþlemine devam eder
 ==============================================================================}
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
var
  DST: TSayi4;
begin

  DST := GAramaKayitListesi[ADosyaArama.Kimlik].MantiksalDepolama^.MD3.DST;
  if(DST = DST_FAT12) then

    Result := fat12.FindNext(ADosyaArama)
  else if(DST = DST_FAT16) then

    Result := fat16.FindNext(ADosyaArama)
  else if(DST = DST_FAT32) or (DST = DST_FAT32LBA) then

    Result := fat32.FindNext(ADosyaArama);
end;

{==============================================================================
  dosya arama iþlemini sonlandýrýr
 ==============================================================================}
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
begin

  AramaKaydiniYokEt(ADosyaArama.Kimlik);
end;

{==============================================================================
  dosyalar ile ilgili iþlem yapmadan önce taným iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
var
  MD: PMantiksalDepolama;
  DosyaKayit: PDosyaKayit;
  DosyaKimlik: TKimlik;
  Surucu, Dizin, DosyaAdi: string;
  KalinanSira: TISayi4;
begin

  // öndeðer dosya iþlem dönüþ deðeri
  FileResult := 1;

  // öndeðer geri dönüþ deðeri
  ADosyaKimlik := 0;

  // dosya iþlemi için bellek bölgesi ayýr
  DosyaKimlik := DosyaKaydiOlustur;
  if(DosyaKimlik = -1) then Exit;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DosyaKayit := @GDosyaKayitListesi[DosyaKimlik];

  // sürücünün iþaret ettiði bellek bölgesine konumlan
  MD := SurucuAl(ADosyaAdi, KalinanSira);
  if(MD = nil) then
  begin

    DosyaKaydiniYokEt(DosyaKimlik);
    Exit;
  end;

  FileResult := 0;

  // dosya tanýmlayýcýyý kaydet
  ADosyaKimlik := DosyaKimlik;

  // iþlem yapýlacak sürücü
  DosyaKayit^.MantiksalDepolama := MD;

  // dosya yolunu ayrýþtýr
  DosyaYolunuParcala(ADosyaAdi, Surucu, Dizin, DosyaAdi);

  // dosya adý
  DosyaKayit^.DosyaAdi := DosyaAdi;

  // diðer deðerleri sýfýrla
  DosyaKayit^.DATBellekAdresi := nil;
  DosyaKayit^.IlkZincirSektor := 0;
  DosyaKayit^.Uzunluk := 0;
  DosyaKayit^.Konum := 0;
  DosyaKayit^.VeriBellekAdresi := nil;
end;

{==============================================================================
  dosyayý okumadan önce ön hazýrlýk iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure Reset(ADosyaKimlik: TKimlik);
var
  DosyaKayit: PDosyaKayit;
  DosyaArama: TDosyaArama;
  TamAramaYolu: string;
  Bulundu: Boolean;
begin

  // en son iþlem hatalý ise çýk
  if(FileResult > 0) then Exit;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

  // tam dosya adýný al
  TamAramaYolu := DosyaKayit^.MantiksalDepolama^.MD3.AygitAdi + ':\*.*';

  // dosyayý dosya tablosunda bul
  Bulundu := False;
  if(FindFirst(TamAramaYolu, 0, DosyaArama) = 0) then
  begin

    repeat

      if(DosyaArama.DosyaAdi = DosyaKayit^.DosyaAdi) then Bulundu := True;
    until (Bulundu) or (FindNext(DosyaArama) <> 0);

    FindClose(DosyaArama);
  end;

  // dosyanýn tabloda bulunmasý halinde
  // dosyanýn ilk dizi ve uzunluðunu al
  if(Bulundu) then
  begin

    DosyaKayit^.IlkZincirSektor := DosyaArama.BaslangicKumeNo;
    DosyaKayit^.Uzunluk := DosyaArama.DosyaUzunlugu;
  end else FileResult := 1;
end;

{==============================================================================
  dosya ile yapýlmýþ en son iþlem sonucunu döndürür
 ==============================================================================}
function IOResult: TISayi4;
begin

  Result := FileResult;
end;

{==============================================================================
  dosya okuma iþleminde dosyanýn sonuna gelinip gelinmediðini belirtir
 ==============================================================================}
function EOF(ADosyaKimlik: TKimlik): Boolean;
begin

  Result := True;
end;

{==============================================================================
  dosya uzunluðunu geri döndürür
 ==============================================================================}
function FileSize(ADosyaKimlik: TKimlik): TISayi4;
begin

  Result := GDosyaKayitListesi[ADosyaKimlik].Uzunluk;
end;

{==============================================================================
  dosya okuma iþlemini gerçekleþtirir
 ==============================================================================}
function Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci): TISayi4;
var
  DosyaKayit: PDosyaKayit;
  DST: TSayi4;
begin

  Result := 0;

  // en son iþlem hatalý ise çýk
  if(FileResult > 0) then Exit;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

  DST := DosyaKayit^.MantiksalDepolama^.MD3.DST;
  if(DST = DST_FAT12) then

    fat12.Read(ADosyaKimlik, AHedefBellek)

  else if(DST = DST_FAT16) then

    fat16.Read(ADosyaKimlik, AHedefBellek)
  else if(DST = DST_FAT32) or (DST = DST_FAT32LBA) then

    fat32.Read(ADosyaKimlik, AHedefBellek);

  Result := 1;
end;

{==============================================================================
  dosya üzerinde yapýlan iþlemi sonlandýrýr
 ==============================================================================}
procedure CloseFile(ADosyaKimlik: TKimlik);
begin

  DosyaKaydiniYokEt(ADosyaKimlik);
end;

{==============================================================================
  arama iþlemi için kaynak ayýrýr
 ==============================================================================}
function AramaKaydiOlustur: TKimlik;
var
  i: TSayi4;
begin

  // boþ bellek bölgesi ara
  for i := 0 to USTSINIR_ARAMAKAYIT - 1 do
  begin

    if(GAramaKayitListesi[i].Kullanilabilir) then
    begin

      GAramaKayitListesi[i].Kullanilabilir := False;
      Result := i;
      Exit;
    end;
  end;

  Result := -1;
end;

{==============================================================================
  arama iþlemi için ayrýlan kaynaðý serbest býrakýr
 ==============================================================================}
procedure AramaKaydiniYokEt(ADosyaKimlik: TKimlik);
begin

  if(GAramaKayitListesi[ADosyaKimlik].Kullanilabilir = False) then
    GAramaKayitListesi[ADosyaKimlik].Kullanilabilir := True;
end;

{==============================================================================
  dosya iþlemleri için kaynak ayýrýr
 ==============================================================================}
function DosyaKaydiOlustur: TKimlik;
var
  i: TSayi4;
begin

  // boþ bellek bölgesi ara
  for i := 0 to USTSINIR_DOSYAKAYIT - 1 do
  begin

    if(GDosyaKayitListesi[i].Kullanilabilir) then
    begin

      GDosyaKayitListesi[i].Kullanilabilir := False;
      Result := i;
      Exit;
    end;
  end;

  Result := -1;
end;

{==============================================================================
  dosya iþlemi için ayrýlan kaynaðý iptal eder.
 ==============================================================================}
procedure DosyaKaydiniYokEt(ADosyaKimlik: TKimlik);
begin

  if(GDosyaKayitListesi[ADosyaKimlik].Kullanilabilir = False) then
    GDosyaKayitListesi[ADosyaKimlik].Kullanilabilir := True;
end;

end.
