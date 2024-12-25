{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: dosya.pas
  Dosya Ýþlevi: dosya (file) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 25/12/2024

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
  _i: TISayi4;
begin

  // öndeðer dosya iþlem dönüþ deðeri. IOResult için
  FileResult := 0;

  // arama deðiþkenlerini sýfýrla
  for _i := 0 to USTSINIR_ARAMAKAYIT - 1 do
  begin

    GAramaKayitListesi[_i].Kullanilabilir := True;
  end;

  // dosya iþlev deðiþkenlerini sýfýrla
  for _i := 0 to USTSINIR_DOSYAKAYIT - 1 do
  begin

    GDosyaKayitListesi[_i].Kullanilabilir := True;
  end;
end;

{==============================================================================
  dosya arama iþlevini baþlatýr
 ==============================================================================}
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi2;
  var ADosyaArama: TDosyaArama): TISayi4;
var
  _MantiksalSurucu: PMantiksalSurucu;
  AramaKimlik: TKimlik;
  _BolumTipi: Byte;
  _AranacakDeger: string;
  _KalinanSira, UTamAramaYolu, AramaSonuc: TISayi4;
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
  _MantiksalSurucu := SurucuAl(AAramaSuzgec, _KalinanSira);
  if(_MantiksalSurucu = nil) then
  begin

    // arama için kullanýlan bellek bölgesini serbest býrak
    AramaKaydiniYokEt(AramaKimlik);
    Result := 1;
    Exit;
  end;

  if not(AAramaSuzgec[_KalinanSira] = '\') then
  begin

    SISTEM_MESAJ(RENK_KIRMIZI, 'DOSYA.PAS: AranacakDeger hatalý!', []);
    Result := 1;
    Exit;
  end;

  _AranacakDeger := '';
  Inc(_KalinanSira);
  UTamAramaYolu := Length(AAramaSuzgec);
  while (AAramaSuzgec[_KalinanSira] <> '\') and (_KalinanSira <= UTamAramaYolu) do
  begin

    _AranacakDeger += AAramaSuzgec[_KalinanSira];
    Inc(_KalinanSira);
  end;

  if(_AranacakDeger = '*.*') then
  begin

    // sürücüyü arama bellek bölgesine ekle
    GAramaKayitListesi[AramaKimlik].MantiksalSurucu := _MantiksalSurucu;

    // arama iþlevinin aktif olarak kullanacaðý deðiþkenleri ata
    GAramaKayitListesi[AramaKimlik].DizinGirisi.IlkSektor :=
      _MantiksalSurucu^.Acilis.DizinGirisi.IlkSektor;
    GAramaKayitListesi[AramaKimlik].DizinGirisi.ToplamSektor :=
      _MantiksalSurucu^.Acilis.DizinGirisi.ToplamSektor;
    GAramaKayitListesi[AramaKimlik].DizinGirisi.GirdiSayisi :=
      _MantiksalSurucu^.Acilis.DizinGirisi.GirdiSayisi;
    GAramaKayitListesi[AramaKimlik].DizinGirisi.DizinTablosuKayitNo := -1;

    // dosya sistem tipine göre iþlevi yönlendir
    _BolumTipi := GAramaKayitListesi[AramaKimlik].MantiksalSurucu^.BolumTipi;
    case _BolumTipi of
      DATTIP_FAT12    : Result := fat12.FindFirst(_AranacakDeger, ADosyaOzellik, ADosyaArama);
      DATTIP_FAT16    : Result := fat16.FindFirst(_AranacakDeger, ADosyaOzellik, ADosyaArama);
      DATTIP_FAT32,
      DATTIP_FAT32LBA : Result := fat32.FindFirst(_AranacakDeger, ADosyaOzellik, ADosyaArama);
      else Result := 1;
    end;
  end
  else
  begin

    // -> yukarýdaki yapý ile ayný
    // sürücüyü arama bellek bölgesine ekle
    GAramaKayitListesi[AramaKimlik].MantiksalSurucu := _MantiksalSurucu;

    // arama iþlevinin aktif olarak kullanacaðý deðiþkenleri ata
    GAramaKayitListesi[AramaKimlik].DizinGirisi.IlkSektor :=
      _MantiksalSurucu^.Acilis.DizinGirisi.IlkSektor;
    GAramaKayitListesi[AramaKimlik].DizinGirisi.ToplamSektor :=
      _MantiksalSurucu^.Acilis.DizinGirisi.ToplamSektor;
    GAramaKayitListesi[AramaKimlik].DizinGirisi.GirdiSayisi :=
      _MantiksalSurucu^.Acilis.DizinGirisi.GirdiSayisi;
    GAramaKayitListesi[AramaKimlik].DizinGirisi.DizinTablosuKayitNo := -1;

    // dosya sistem tipine göre iþlevi yönlendir
    _BolumTipi := GAramaKayitListesi[AramaKimlik].MantiksalSurucu^.BolumTipi;
    case _BolumTipi of
      DATTIP_FAT12    : AramaSonuc := fat12.FindFirst(_AranacakDeger, ADosyaOzellik, ADosyaArama);
      DATTIP_FAT16    : AramaSonuc := fat16.FindFirst(_AranacakDeger, ADosyaOzellik, ADosyaArama);
      DATTIP_FAT32,
      DATTIP_FAT32LBA : AramaSonuc := fat32.FindFirst(_AranacakDeger, ADosyaOzellik, ADosyaArama);
      else AramaSonuc := 1;
    end;
    // <- yukarýdaki yapý ile ayný

    if not(_AranacakDeger = '*.*') and (AramaSonuc = 0) then
    begin

      {SISTEM_MESAJ(RENK_SIYAH, 'Aranacak Deðer: ', _AranacakDeger, []);
      SISTEM_MESAJ_S16(RENK_SIYAH, 'BaslangicKumeNo: ', ADosyaArama.BaslangicKumeNo, 8);
      SISTEM_MESAJ(RENK_SIYAH, 'Dosya Adý: ', ADosyaArama.DosyaAdi, []);
      SISTEM_MESAJ_S16(RENK_SIYAH, 'DosyaUzunlugu: ', ADosyaArama.DosyaUzunlugu, 8);
      SISTEM_MESAJ_S16(RENK_SIYAH, 'IlkSektor: ', AramaKayitListesi[AramaKimlik].DizinGirisi.IlkSektor, 8);}

      //AramaSonuc := 1;

      // -> yukarýdaki yapý ile ayný
      // sürücüyü arama bellek bölgesine ekle
      GAramaKayitListesi[AramaKimlik].MantiksalSurucu := _MantiksalSurucu;

      // arama iþlevinin aktif olarak kullanacaðý deðiþkenleri ata
      GAramaKayitListesi[AramaKimlik].DizinGirisi.IlkSektor :=
        ADosyaArama.BaslangicKumeNo + 622;
      GAramaKayitListesi[AramaKimlik].DizinGirisi.ToplamSektor := 1;
      GAramaKayitListesi[AramaKimlik].DizinGirisi.GirdiSayisi := 16;
      GAramaKayitListesi[AramaKimlik].DizinGirisi.DizinTablosuKayitNo := -1;

      _AranacakDeger := '*.*';
      GAramaKayitListesi[AramaKimlik].Aranan := '*.*';

      // dosya sistem tipine göre iþlevi yönlendir
      _BolumTipi := GAramaKayitListesi[AramaKimlik].MantiksalSurucu^.BolumTipi;
      case _BolumTipi of
        DATTIP_FAT12    : AramaSonuc := fat12.FindFirst(_AranacakDeger, ADosyaOzellik, ADosyaArama);
        DATTIP_FAT16    : AramaSonuc := fat16.FindFirst(_AranacakDeger, ADosyaOzellik, ADosyaArama);
        DATTIP_FAT32,
        DATTIP_FAT32LBA : AramaSonuc := fat32.FindFirst(_AranacakDeger, ADosyaOzellik, ADosyaArama);
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
  _BolumTipi: TSayi1;
begin

  _BolumTipi := GAramaKayitListesi[ADosyaArama.Kimlik].MantiksalSurucu^.BolumTipi;
  if(_BolumTipi = DATTIP_FAT12) then

    Result := fat12.FindNext(ADosyaArama)
  else if(_BolumTipi = DATTIP_FAT16) then

    Result := fat16.FindNext(ADosyaArama)
  else if(_BolumTipi = DATTIP_FAT32) or (_BolumTipi = DATTIP_FAT32LBA) then

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
  _MantiksalSurucu: PMantiksalSurucu;
  _DosyaKayit: PDosyaKayit;
  _DosyaKimlik: TKimlik;
  _Surucu, _Dizin, _DosyaAdi: string;
  _KalinanSira: TISayi4;
begin

  // öndeðer dosya iþlem dönüþ deðeri
  FileResult := 1;

  // öndeðer geri dönüþ deðeri
  ADosyaKimlik := 0;

  // dosya iþlemi için bellek bölgesi ayýr
  _DosyaKimlik := DosyaKaydiOlustur;
  if(_DosyaKimlik = -1) then Exit;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  _DosyaKayit := @GDosyaKayitListesi[_DosyaKimlik];

  // sürücünün iþaret ettiði bellek bölgesine konumlan
  _MantiksalSurucu := SurucuAl(ADosyaAdi, _KalinanSira);
  if(_MantiksalSurucu = nil) then
  begin

    DosyaKaydiniYokEt(_DosyaKimlik);
    Exit;
  end;

  FileResult := 0;

  // dosya tanýmlayýcýyý kaydet
  ADosyaKimlik := _DosyaKimlik;

  // iþlem yapýlacak sürücü
  _DosyaKayit^.MantiksalSurucu := _MantiksalSurucu;

  // dosya yolunu ayrýþtýr
  DosyaYolunuParcala(ADosyaAdi, _Surucu, _Dizin, _DosyaAdi);

  // dosya adý
  _DosyaKayit^.DosyaAdi := _DosyaAdi;

  // diðer deðerleri sýfýrla
  _DosyaKayit^.DATBellekAdresi := nil;
  _DosyaKayit^.IlkZincirSektor := 0;
  _DosyaKayit^.Uzunluk := 0;
  _DosyaKayit^.Konum := 0;
  _DosyaKayit^.VeriBellekAdresi := nil;
end;

{==============================================================================
  dosyayý okumadan önce ön hazýrlýk iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure Reset(ADosyaKimlik: TKimlik);
var
  _DosyaKayit: PDosyaKayit;
  _DosyaArama: TDosyaArama;
  _TamAramaYolu: string;
  _Bulundu: Boolean;
begin

  // en son iþlem hatalý ise çýk
  if(FileResult > 0) then Exit;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  _DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

  // tam dosya adýný al
  _TamAramaYolu := _DosyaKayit^.MantiksalSurucu^.AygitAdi + ':\*.*';

  // dosyayý dosya tablosunda bul
  _Bulundu := False;
  if(FindFirst(_TamAramaYolu, 0, _DosyaArama) = 0) then
  begin

    repeat

      if(_DosyaArama.DosyaAdi = _DosyaKayit^.DosyaAdi) then _Bulundu := True;
    until (_Bulundu) or (FindNext(_DosyaArama) <> 0);

    FindClose(_DosyaArama);
  end;

  // dosyanýn tabloda bulunmasý halinde
  // dosyanýn ilk dizi ve uzunluðunu al
  if(_Bulundu) then
  begin

    _DosyaKayit^.IlkZincirSektor := _DosyaArama.BaslangicKumeNo;
    _DosyaKayit^.Uzunluk := _DosyaArama.DosyaUzunlugu;
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
  _DosyaKayit: PDosyaKayit;
  _BolumTipi: TSayi1;
begin

  Result := 0;

  // en son iþlem hatalý ise çýk
  if(FileResult > 0) then Exit;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  _DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

  _BolumTipi := _DosyaKayit^.MantiksalSurucu^.BolumTipi;
  if(_BolumTipi = DATTIP_FAT12) then

    fat12.Read(ADosyaKimlik, AHedefBellek)

  else if(_BolumTipi = DATTIP_FAT16) then

    fat16.Read(ADosyaKimlik, AHedefBellek)
  else if(_BolumTipi = DATTIP_FAT32) or (_BolumTipi = DATTIP_FAT32LBA) then

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
