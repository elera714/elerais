{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: dosya.pas
  Dosya Ýþlevi: dosya (file) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 30/01/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit dosya;

interface

uses paylasim;

procedure Yukle;
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
  var ADosyaArama: TDosyaArama): TISayi4;
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
procedure ReWrite(ADosyaKimlik: TKimlik);
procedure Append(ADosyaKimlik: TKimlik);
procedure Reset(ADosyaKimlik: TKimlik);
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
procedure WriteLn(ADosyaKimlik: TKimlik; AVeri: string);
procedure Write(ADosyaKimlik: TKimlik; ABellekAdresi: Isaretci; AUzunluk: TSayi4);
function Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci): TISayi4;
function IOResult: TISayi4;
function FileSize(ADosyaKimlik: TKimlik): TISayi4;
function EOF(ADosyaKimlik: TKimlik): Boolean;
procedure CloseFile(ADosyaKimlik: TKimlik);
procedure CreateDir(ADosyaKimlik: TKimlik);
procedure RemoveDir(const AKlasorAdi: string);
function DeleteFile(const ADosyaAdi: string): TISayi4;
procedure AramaKaydiniYokEt(ADosyaKimlik: TKimlik);
function DosyaKaydiOlustur: TKimlik;
procedure DosyaKaydiniYokEt(ADosyaKimlik: TKimlik);

function HamDosyaAdiniDosyaAdinaCevir2(ADizinGirdisi: PDizinGirdisi): string;
procedure IzKaydiOlustur(ADosyaAdi, AKayit: string);
procedure ELR1DiskBicimle(AMD: PMantiksalDepolama);

implementation

uses bolumleme, elr1, fat12, fat16, fat32, sistemmesaj, islevler, donusum;

{==============================================================================
  dosya sistem iþlevlerinin kullanacaðý deðiþkenleri ilk deðerlerle yükle
 ==============================================================================}
procedure Yukle;
var
  i: TISayi4;
begin

  // öndeðer dosya iþlem dönüþ deðeri. IOResult için
  FileResult := 0;

  // dosya iþlev deðiþkenlerini sýfýrla
  for i := 0 to USTSINIR_DOSYAISLEM - 1 do
  begin

    GDosyaIslemleri[i].Kullanilabilir := True;
  end;
end;

{==============================================================================
  dosya arama iþlevini baþlatýr
 ==============================================================================}
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
  var ADosyaArama: TDosyaArama): TISayi4;
var
  MD: PMantiksalDepolama;
  AramaKimlik: TKimlik;
  DST: TSayi4;
  AramaSuzgeci, AranacakKlasor, Surucu, s: string;
  UTamAramaYolu,
  AramaSonuc: TISayi4;
  i, SektorNo,
  AyrilmisSektor: TSayi4;
begin

  // AAramaSuzgec
  // örnek: disk1:\klasör1\dizin1\*.*

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'AAramaSuzgec: %s', [AAramaSuzgec]);

  // arama için arama bilgilerinin saklanacaðý bellek bölgesi tahsis et
  AramaKimlik := DosyaKaydiOlustur;
  if(AramaKimlik = -1) then
  begin

    Result := 1;
    Exit;
  end;

  // arama kaydýný, çaðýran iþlevin deðiþkenine sakla
  ADosyaArama.Kimlik := AramaKimlik;

  // arama iþlevinin yapýlacaðý sürücüyü al
  MD := SurucuAl(AAramaSuzgec);
  if(MD = nil) then
  begin

    // arama için kullanýlan bellek bölgesini serbest býrak
    AramaKaydiniYokEt(AramaKimlik);
    Result := 1;
    Exit;
  end;

  s := AAramaSuzgec;

  i := Pos(':', s);
  if(i > 0) then
  begin

    Surucu := Copy(s, 1, i - 1);
    s := Copy(s, i + 1, Length(s) - i);
  end;
  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Sürücü: ''%s''', [Surucu]);

  if not(s[1] = '\') then
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'DOSYA.PAS: Arama süzgeç söz dizilimi hatalý!', []);
    Result := 1;
    Exit;
  end;
  s := Copy(s, 2, Length(s) - 1);

  // sürücüyü arama bellek bölgesine ekle
  GDosyaIslemleri[AramaKimlik].MantiksalDepolama := MD;

  SektorNo := MD^.Acilis.DizinGirisi.IlkSektor;

  // AyrilmisSektor = zincir deðerine eklenecek deðer
  AyrilmisSektor := MD^.Acilis.DizinGirisi.IlkSektor + MD^.Acilis.DizinGirisi.ToplamSektor;

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'SektorNo: ''%d''', [SektorNo]);
  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'AyrilmisSektor: ''%d''', [AyrilmisSektor]);

  repeat

    i := Pos('\', s);
    if(i > 0) then
    begin

      AranacakKlasor := Copy(s, 1, i - 1);
      AramaSuzgeci := '';
      s := Copy(s, i + 1, Length(s) - i);
    end
    else
    begin

      AranacakKlasor := '';
      AramaSuzgeci := s;
    end;

    if(Length(AranacakKlasor) > 0) then
    begin

      //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'AranacakDizin: ''%s''', [AranacakKlasor]);
      //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'AramaSuzgeci: ''%s''', [AramaSuzgeci]);

      GDosyaIslemleri[AramaKimlik].DizinGirisi.IlkSektor := SektorNo;
      GDosyaIslemleri[AramaKimlik].DizinGirisi.DizinTablosuKayitNo := 0;
      GDosyaIslemleri[AramaKimlik].DizinGirisi.OkunanSektor := 0;

      SektorNo := DizinGirisindeAra(GDosyaIslemleri[AramaKimlik], AranacakKlasor);
      if(SektorNo = 0) then
      begin

        SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'DOSYA.PAS: %s dizini dosya tablosunda mevcut deðil!', [AranacakKlasor]);
        Exit(1);
      end
      else
      begin

        SektorNo := ((SektorNo - 2) * MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor) + AyrilmisSektor;
      end;
    end;
  until Length(AranacakKlasor) = 0;

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'AramaSuzgeci: ''%s''', [AramaSuzgeci]);
  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Ýlk Dizin Küme No: %d', [SektorNo]);
  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'XXYYTT: %d', [MD^.Acilis.DizinGirisi.IlkSektor + MD^.Acilis.DizinGirisi.ToplamSektor]);

  if(AramaSuzgeci = '*.*') then
  begin

    // arama iþlevinin aktif olarak kullanacaðý deðiþkenleri ata
    GDosyaIslemleri[AramaKimlik].DizinGirisi.IlkSektor := SektorNo;
    GDosyaIslemleri[AramaKimlik].DizinGirisi.ToplamSektor := MD^.Acilis.DizinGirisi.ToplamSektor;
    GDosyaIslemleri[AramaKimlik].DizinGirisi.DizinTablosuKayitNo := 0;
    GDosyaIslemleri[AramaKimlik].DizinGirisi.OkunanSektor := 0;

    // dosya sistem tipine göre iþlevi yönlendir
    DST := GDosyaIslemleri[AramaKimlik].MantiksalDepolama^.MD3.DST;

    // geçici
    if(DST = DST_ELR1) then
    begin

      GDosyaIslemleri[AramaKimlik].DizinGirisi.IlkSektor := $600; //SektorNo;    // $600 = 1536
      GDosyaIslemleri[AramaKimlik].DizinGirisi.ToplamSektor := 4; //MD^.Acilis.DizinGirisi.ToplamSektor;
      GDosyaIslemleri[AramaKimlik].DizinGirisi.DizinTablosuKayitNo := 0;
      GDosyaIslemleri[AramaKimlik].DizinGirisi.OkunanSektor := 0;
    end;

    case DST of
      DST_ELR1      : Result := elr1.FindFirst(AramaSuzgeci, ADosyaOzellik, ADosyaArama);
      DST_FAT12     : Result := fat12.FindFirst(AramaSuzgeci, ADosyaOzellik, ADosyaArama);
      DST_FAT16     : Result := fat16.FindFirst(AramaSuzgeci, ADosyaOzellik, ADosyaArama);
      DST_FAT32,
      DST_FAT32LBA  : Result := fat32.FindFirst(AramaSuzgeci, ADosyaOzellik, ADosyaArama);
      else Result := 1;
    end;
  end;
end;

{==============================================================================
  dosya arama iþlemine devam eder
 ==============================================================================}
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
var
  DST: TSayi4;
begin

  DST := GDosyaIslemleri[ADosyaArama.Kimlik].MantiksalDepolama^.MD3.DST;

  if(DST = DST_ELR1) then

    Result := elr1.FindNext(ADosyaArama)

  else if(DST = DST_FAT12) then

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
  DosyaIslem: PDosyaIslem;
  DosyaKimlik: TKimlik;
  Surucu, Klasor, DosyaAdi: string;
  i: TSayi4;
begin

  // öndeðer dosya iþlem dönüþ deðeri
  FileResult := 1;

  // öndeðer geri dönüþ deðeri
  ADosyaKimlik := 0;

  // dosya iþlemi için bellek bölgesi ayýr
  DosyaKimlik := DosyaKaydiOlustur;
  if(DosyaKimlik = -1) then Exit;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DosyaIslem := @GDosyaIslemleri[DosyaKimlik];

  // sürücünün iþaret ettiði bellek bölgesine konumlan
  MD := SurucuAl(ADosyaAdi);
  if(MD = nil) then
  begin

    DosyaKaydiniYokEt(DosyaKimlik);
    Exit;
  end;

  FileResult := 0;

  // dosya tanýmlayýcýyý kaydet
  ADosyaKimlik := DosyaKimlik;

  // iþlem yapýlacak sürücü
  DosyaIslem^.MantiksalDepolama := MD;

  // dosya yolunu ayrýþtýr
  DosyaYolunuParcala2(ADosyaAdi, Surucu, Klasor, DosyaAdi);

  {SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Sürücü: %s', [Surucu]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Klasör: %s', [Klasor]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Dosya Adý: %s', [DosyaAdi]);}

  // klasör ve dosya adý
  DosyaIslem^.Klasor := Klasor;
  DosyaIslem^.DosyaAdi := DosyaAdi;

  FillChar(DosyaIslem^.DGAktif[0], ELR_DOSYA_U, #0);
  DosyaIslem^.DGAktif[0] := Length(DosyaIslem^.DosyaAdi);

  for i := 1 to Length(DosyaIslem^.DosyaAdi) do
  begin

    DosyaIslem^.DGAktif[i] := Ord(DosyaIslem^.DosyaAdi[i]);
  end;

  // diðer deðerleri sýfýrla
  DosyaIslem^.DosyaDurumu := ddKapali;
  DosyaIslem^.DATBellekAdresi := nil;
  DosyaIslem^.IlkZincirSektor := 0;
  DosyaIslem^.Uzunluk := 0;
  DosyaIslem^.Konum := 0;
  DosyaIslem^.VeriBellekAdresi := nil;
end;

{==============================================================================
  dosya oluþturma iþlevini gerçekleþtirir

  iþlev: dosya yoksa oluþturur, dosyanýn var olmasý durumunda tüm içeriði sýfýrlar
    (dosyayý yeniden oluturma durumuna getirir)
 ==============================================================================}
procedure ReWrite(ADosyaKimlik: TKimlik);
var
  DosyaIslem: PDosyaIslem;
  DST: TSayi4;
begin

  //Result := 0;

  // en son iþlem hatalý ise çýk
  if(FileResult > 0) then Exit;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  DST := DosyaIslem^.MantiksalDepolama^.MD3.DST;

  if(DST = DST_ELR1) then

    elr1.ReWrite(ADosyaKimlik)

  else if(DST = DST_FAT12) then

    fat12.ReWrite(ADosyaKimlik)

  else if(DST = DST_FAT16) then

    fat16.ReWrite(ADosyaKimlik)

  else if(DST = DST_FAT32) or (DST = DST_FAT32LBA) then

    fat32.ReWrite(ADosyaKimlik);

  //Result := 1;
end;

{==============================================================================
  dosyaya veri eklemek için açma iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure Append(ADosyaKimlik: TKimlik);
var
  DosyaIslem: PDosyaIslem;
  DST: TSayi4;
begin

  //Result := 0;

  // en son iþlem hatalý ise çýk
  if(FileResult > 0) then Exit;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  DST := DosyaIslem^.MantiksalDepolama^.MD3.DST;

  if(DST = DST_ELR1) then

    elr1.Append(ADosyaKimlik)

  else if(DST = DST_FAT12) then

    fat12.Append(ADosyaKimlik)

  else if(DST = DST_FAT16) then

    fat16.Append(ADosyaKimlik)

  else if(DST = DST_FAT32) or (DST = DST_FAT32LBA) then

    fat32.Append(ADosyaKimlik);

  //Result := 1;
end;

{==============================================================================
  dosyayý okumadan önce ön hazýrlýk iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure Reset(ADosyaKimlik: TKimlik);
var
  DosyaIslem: PDosyaIslem;
  DosyaArama: TDosyaArama;
  TamAramaYolu: string;
  Bulundu: Boolean;
begin

  // en son iþlem hatalý ise çýk
  if(FileResult > 0) then Exit;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  // tam dosya adýný al
  TamAramaYolu := DosyaIslem^.MantiksalDepolama^.MD3.AygitAdi + ':' + DosyaIslem^.Klasor + '*.*';

  // dosyayý dosya tablosunda bul
  Bulundu := False;
  if(FindFirst(TamAramaYolu, 0, DosyaArama) = 0) then
  begin

    repeat

      if(DosyaArama.DosyaAdi = DosyaIslem^.DosyaAdi) then Bulundu := True;
    until (Bulundu) or (FindNext(DosyaArama) <> 0);

    FindClose(DosyaArama);
  end;

  // dosyanýn tabloda bulunmasý halinde
  // dosyanýn ilk dizi ve uzunluðunu al
  if(Bulundu) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Reset: %d', [DosyaArama.DosyaUzunlugu]);

    DosyaIslem^.IlkZincirSektor := DosyaArama.BaslangicKumeNo;
    DosyaIslem^.Uzunluk := DosyaArama.DosyaUzunlugu;
  end else FileResult := 1;
end;

{==============================================================================
  dosyaya veri yazma iþlemini gerçekleþtirir
 ==============================================================================}
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
var
  DosyaIslem: PDosyaIslem;
  DST: TSayi4;
begin

  //Result := 0;

  // en son iþlem hatalý ise çýk
  if(FileResult > 0) then Exit;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  DST := DosyaIslem^.MantiksalDepolama^.MD3.DST;

  if(DST = DST_ELR1) then

    elr1.Write(ADosyaKimlik, AVeri)

  else if(DST = DST_FAT12) then

    fat12.Write(ADosyaKimlik, AVeri)

  else if(DST = DST_FAT16) then

    fat16.Write(ADosyaKimlik, AVeri)

  else if(DST = DST_FAT32) or (DST = DST_FAT32LBA) then

    fat32.Write(ADosyaKimlik, AVeri);

  //Result := 1;
end;

{==============================================================================
  verinin sonuna #13#10 ekleyerek dosyaya veri yazma iþlemini gerçekleþtirir
 ==============================================================================}
procedure WriteLn(ADosyaKimlik: TKimlik; AVeri: string);
begin

  Write(ADosyaKimlik, AVeri + #13#10);
end;

{==============================================================================
  dosyaya veri yazma iþlemini gerçekleþtirir
 ==============================================================================}
procedure Write(ADosyaKimlik: TKimlik; ABellekAdresi: Isaretci; AUzunluk: TSayi4);
var
  DosyaIslem: PDosyaIslem;
  DST: TSayi4;
begin

  //Result := 0;

  // en son iþlem hatalý ise çýk
  if(FileResult > 0) then Exit;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  DST := DosyaIslem^.MantiksalDepolama^.MD3.DST;

  if(DST = DST_ELR1) then

    elr1.Write(ADosyaKimlik, ABellekAdresi, AUzunluk)

  else if(DST = DST_FAT12) then

    //fat12.Write(ADosyaKimlik, AVeri)

  else if(DST = DST_FAT16) then

    //fat16.Write(ADosyaKimlik, AVeri)

  else if(DST = DST_FAT32) or (DST = DST_FAT32LBA) then

    //fat32.Write(ADosyaKimlik, AVeri);

  //Result := 1;
end;

{==============================================================================
  dosya okuma iþlemini gerçekleþtirir
 ==============================================================================}
function Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci): TISayi4;
var
  DosyaIslem: PDosyaIslem;
  DST: TSayi4;
begin

  Result := 0;

  // en son iþlem hatalý ise çýk
  if(FileResult > 0) then Exit;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  DST := DosyaIslem^.MantiksalDepolama^.MD3.DST;

  if(DST = DST_ELR1) then

    elr1.Read(ADosyaKimlik, AHedefBellek)

  else if(DST = DST_FAT12) then

    fat12.Read(ADosyaKimlik, AHedefBellek)

  else if(DST = DST_FAT16) then

    fat16.Read(ADosyaKimlik, AHedefBellek)

  else if(DST = DST_FAT32) or (DST = DST_FAT32LBA) then

    fat32.Read(ADosyaKimlik, AHedefBellek);

  Result := 1;
end;

{==============================================================================
  dosya ile yapýlmýþ en son iþlem sonucunu döndürür
 ==============================================================================}
function IOResult: TISayi4;
begin

  Result := FileResult;

  // son iþlem durumu geri döndürüldükten sonra deðiþkeni hata yok olarak iþaretle
  FileResult := 0;
end;

{==============================================================================
  dosya uzunluðunu geri döndürür
 ==============================================================================}
function FileSize(ADosyaKimlik: TKimlik): TISayi4;
begin

  Result := GDosyaIslemleri[ADosyaKimlik].Uzunluk;
end;

{==============================================================================
  dosya okuma iþleminde dosyanýn sonuna gelinip gelinmediðini belirtir
 ==============================================================================}
function EOF(ADosyaKimlik: TKimlik): Boolean;
begin

  Result := True;
end;

{==============================================================================
  dosya üzerinde yapýlan iþlemi sonlandýrýr
 ==============================================================================}
procedure CloseFile(ADosyaKimlik: TKimlik);
begin

  DosyaKaydiniYokEt(ADosyaKimlik);
end;

{==============================================================================
  klasör oluþturma iþlevini gerçekleþtirir
 ==============================================================================}
procedure CreateDir(ADosyaKimlik: TKimlik);
var
  DosyaIslem: PDosyaIslem;
  DosyaArama: TDosyaArama;
  TamAramaYolu: string;
  Bulundu: Boolean;
  FD: TFizikselDepolama;
  Bellek: array[0..511] of TSayi1;
  Bellek2: array[0..31] of TSayi1 = (
    $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $10, $08, $2D, $31, $66,
    $46, $5A, $56, $5A, $00, $00, $60, $A1, $56, $5A, $E5, $12, $00, $00, $00, $00);
  SektorNo, i, ZincirNo, ZincirSektorSayisi: TSayi4;
  MD: PMantiksalDepolama;
  DizinGirdisi: PDizinGirdisi;
  TumGirislerOkundu,
  UzunDosyaAdiBulundu, DosyaBulundu: Boolean;
  DizinGirisi: TDizinGirisi;
begin

  DosyaBulundu := False;

  // her bir cluster'in 4 sektör olarak tasarlandýðý elr-1 dosya sistemi

  SektorNo := $600; //1536;

  // en son iþlem hatalý ise çýk
  if(FileResult > 0) then Exit;

  //ADosyaArama.DosyaAdi := '';

  // ilk deðer atamalarý
  TumGirislerOkundu := False;

  //UzunDosyaAdiBulundu := False;

  // aramanýn yapýlacaðý sürücü
  //MD := GAramaKayitListesi[ADosyaArama.Kimlik].MantiksalDepolama;
  //DizinGirisi := @GAramaKayitListesi[ADosyaKimlik].DizinGirisi;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  DizinGirisi.DizinTablosuKayitNo := 0;
  DizinGirisi.OkunanSektor := 0;
  ZincirSektorSayisi := 4;  // geçici deðer
  ZincirNo := 0;

  FD := FizikselDepolamaAygitListesi[3];  // fda4

  // aramaya baþla
  repeat

    if(DizinGirisi.DizinTablosuKayitNo = 0) then
    begin

      // bir sonraki dizin giriþini oku
      FD.SektorOku(@FD, SektorNo + ZincirNo, 1, Isaretci(@Bellek));

      // DizinGirisi.OkunanSektor deðiþkeni elr dosya sisteminde anlamsýz
      // Inc(DizinGirisi.OkunanSektor);
    end;

    // dosya giriþ tablosuna konumlan
    DizinGirdisi := PDizinGirdisi(@Bellek);
    Inc(DizinGirdisi, DizinGirisi.DizinTablosuKayitNo);

    // dosya giriþinin ilk karakteri #0 ise giriþler okunmuþ demektir
    if(DizinGirdisi^.DosyaAdi[0] = #00) then
    begin

      //Result := 1;
      TumGirislerOkundu := True;
      //Exit;
    end
    // silinmiþ dosya / dizin
    else if(DizinGirdisi^.DosyaAdi[0] = Chr($E5)) then
    begin

      // bir sonraki giriþle devam et
    end
    // mantýksal depolama aygýtý etiket (volume label)
    else if(DizinGirdisi^.Ozellikler = $08) then
    begin

      // bir sonraki giriþle devam et
    end
    // dizin girdisi uzun ada sahip bir ad ise, uzun dosya adýný al
    {else if(DizinGirdisi^.Ozellikler = $0F) then
    begin

      UzunDosyaAdiBulundu := True;
      DosyaParcalariniBirlestir(Isaretci(DizinGirdisi));
    end}
    // dizin girdisinin uzun ad haricinde olmasý durumunda
    else //if(DizinGirdisi^.Ozellikler <> $0F) then
    begin

      // girdinin uzun ad dosya adý OLMAMASI durumunda

      // 1. bir önceki girdi uzun dosya adý ise, ad ve diðer özellikleri geri döndür
      {if(UzunDosyaAdiBulundu) then
      begin

        DosyaArama.DosyaAdi := WideChar2String(@UzunDosyaAdi);
        DosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
        DosyaArama.OlusturmaSaati := DizinGirdisi^.OlusturmaSaati;
        DosyaArama.OlusturmaTarihi := DizinGirdisi^.OlusturmaTarihi;
        DosyaArama.SonErisimTarihi := DizinGirdisi^.SonErisimTarihi;
        DosyaArama.SonDegisimSaati := DizinGirdisi^.SonDegisimSaati;
        DosyaArama.SonDegisimTarihi := DizinGirdisi^.SonDegisimTarihi;

        // deðiþken içeriklerini sýfýrla
        UzunDosyaAdi[0] := #0;
        UzunDosyaAdi[1] := #0;
        UzunDosyaAdiBulundu := False;
      end
      else}
      // 2. bir önceki girdi uzun dosya adý deðilse, 8 + 3 dosya ad + uzantý ve
      // diðer özellikleri geri döndür
      begin

        DosyaArama.DosyaAdi := HamDosyaAdiniDosyaAdinaCevir2(DizinGirdisi);
        DosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
        DosyaArama.OlusturmaSaati := DizinGirdisi^.OlusturmaSaati;
        DosyaArama.OlusturmaTarihi := DizinGirdisi^.OlusturmaTarihi;
        DosyaArama.SonErisimTarihi := DizinGirdisi^.SonErisimTarihi;
        DosyaArama.SonDegisimSaati := DizinGirdisi^.SonDegisimSaati;
        DosyaArama.SonDegisimTarihi := DizinGirdisi^.SonDegisimTarihi;
      end;

      // dosya uzunluðu ve cluster baþlangýcýný geri dönüþ deðerine ekle
      DosyaArama.DosyaUzunlugu := DizinGirdisi^.DosyaUzunlugu;
      DosyaArama.BaslangicKumeNo := DizinGirdisi^.BaslangicKumeNo;

      // gözardý edilecek giriþler
      if(DosyaArama.DosyaAdi = '.') then
      begin

      end
      else
      begin

        //Result := 0;
        //TumGirislerOkundu := True;
      end;

      if(DosyaArama.DosyaAdi = DosyaIslem^.DosyaAdi) then
      begin

        DosyaBulundu := True;
        TumGirislerOkundu := True;
        SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Dosya Adý: %s, Sýra No: %d',
          [DosyaArama.DosyaAdi, DizinGirisi.DizinTablosuKayitNo]);
      end;
    end;

    if not(TumGirislerOkundu) then
    begin

      // bir sonraki girdiye konumlan
      Inc(DizinGirisi.DizinTablosuKayitNo);
      if(DizinGirisi.DizinTablosuKayitNo = 16) then
      begin

        Inc(ZincirNo);
        if(ZincirNo = ZincirSektorSayisi - 1) then
        begin

          TumGirislerOkundu := True;
          DosyaBulundu := True;     // çýkýþ için, aþaðýdaki kodlarýn devreye girmemesi için

          { TODO - fat tablosundan bir sonraki alýnan giriþle devaö edilecektir, kodlamayý yap }
        end else DizinGirisi.DizinTablosuKayitNo := 0
      end else Inc(DizinGirdisi);
    end;

  until TumGirislerOkundu;

  // dosya oluþturma iþlemi
  if not(DosyaBulundu) then
  begin

    if(DizinGirisi.DizinTablosuKayitNo >= 0) and (DizinGirisi.DizinTablosuKayitNo < 16) then
    begin

      FillChar(Bellek2, Length(DosyaIslem^.DosyaAdi), $20);

      for i := 1 to Length(DosyaIslem^.DosyaAdi) do
      begin

        Bellek2[i - 1] := Ord(DosyaIslem^.DosyaAdi[i]);
      end;

      Tasi2(@Bellek2, @Bellek[DizinGirisi.DizinTablosuKayitNo * 32], 32);

      //FillChar(Bellek, 512, $0);
      FD.SektorYaz(@FD, SektorNo + ZincirNo, 1, Isaretci(@Bellek));
    end;
  end;
end;

{==============================================================================
  klasör silme iþlevini gerçekleþtirir
 ==============================================================================}
procedure RemoveDir(const AKlasorAdi: string);
var
  //DosyaKayit: PDosyaKayit;
  DosyaArama: TDosyaArama;
  TamAramaYolu: string;
  Bulundu: Boolean;
  FD: TFizikselDepolama;
  Bellek: array[0..511] of TSayi1;
  Bellek2: array[0..31] of TSayi1 = (
    $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $08, $2D, $31, $66,
    $46, $5A, $56, $5A, $00, $00, $60, $A1, $56, $5A, $E5, $12, $00, $00, $00, $00);
  SektorNo, i, ZincirNo, ZincirSektorSayisi: TSayi4;
  MD: PMantiksalDepolama;
  DizinGirdisi: PDizinGirdisi;
  TumGirislerOkundu,
  UzunDosyaAdiBulundu, DosyaBulundu: Boolean;
  DizinGirisi: TDizinGirisi;
begin

  DosyaBulundu := False;

  // her bir cluster'in 4 sektör olarak tasarlandýðý elr-1 dosya sistemi

  SektorNo := $600; //1536;

  // en son iþlem hatalý ise çýk
  if(FileResult > 0) then Exit;

  //ADosyaArama.DosyaAdi := '';

  // ilk deðer atamalarý
  TumGirislerOkundu := False;

  //UzunDosyaAdiBulundu := False;

  // aramanýn yapýlacaðý sürücü
  //MD := GAramaKayitListesi[ADosyaArama.Kimlik].MantiksalDepolama;
  //DizinGirisi := @GAramaKayitListesi[ADosyaKimlik].DizinGirisi;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  //DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

  DizinGirisi.DizinTablosuKayitNo := 0;
  DizinGirisi.OkunanSektor := 0;
  ZincirSektorSayisi := 4;  // geçici deðer
  ZincirNo := 0;

  FD := FizikselDepolamaAygitListesi[3];  // fda4

  // aramaya baþla
  repeat

    if(DizinGirisi.DizinTablosuKayitNo = 0) then
    begin

      // bir sonraki dizin giriþini oku
      FD.SektorOku(@FD, SektorNo + ZincirNo, 1, Isaretci(@Bellek));

      // DizinGirisi.OkunanSektor deðiþkeni elr dosya sisteminde anlamsýz
      // Inc(DizinGirisi.OkunanSektor);
    end;

    // dosya giriþ tablosuna konumlan
    DizinGirdisi := PDizinGirdisi(@Bellek);
    Inc(DizinGirdisi, DizinGirisi.DizinTablosuKayitNo);

    // dosya giriþinin ilk karakteri #0 ise giriþler okunmuþ demektir
    if(DizinGirdisi^.DosyaAdi[0] = #00) then
    begin

      //Result := 1;
      TumGirislerOkundu := True;
      //Exit;
    end
    // silinmiþ dosya / dizin
    else if(DizinGirdisi^.DosyaAdi[0] = Chr($E5)) then
    begin

      // bir sonraki giriþle devam et
    end
    // mantýksal depolama aygýtý etiket (volume label)
    else if(DizinGirdisi^.Ozellikler = $08) then
    begin

      // bir sonraki giriþle devam et
    end
    // dizin girdisi uzun ada sahip bir ad ise, uzun dosya adýný al
    {else if(DizinGirdisi^.Ozellikler = $0F) then
    begin

      UzunDosyaAdiBulundu := True;
      DosyaParcalariniBirlestir(Isaretci(DizinGirdisi));
    end}
    // dizin girdisinin uzun ad haricinde olmasý durumunda
    else //if(DizinGirdisi^.Ozellikler <> $0F) then
    begin

      // girdinin uzun ad dosya adý OLMAMASI durumunda

      // 1. bir önceki girdi uzun dosya adý ise, ad ve diðer özellikleri geri döndür
      {if(UzunDosyaAdiBulundu) then
      begin

        DosyaArama.DosyaAdi := WideChar2String(@UzunDosyaAdi);
        DosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
        DosyaArama.OlusturmaSaati := DizinGirdisi^.OlusturmaSaati;
        DosyaArama.OlusturmaTarihi := DizinGirdisi^.OlusturmaTarihi;
        DosyaArama.SonErisimTarihi := DizinGirdisi^.SonErisimTarihi;
        DosyaArama.SonDegisimSaati := DizinGirdisi^.SonDegisimSaati;
        DosyaArama.SonDegisimTarihi := DizinGirdisi^.SonDegisimTarihi;

        // deðiþken içeriklerini sýfýrla
        UzunDosyaAdi[0] := #0;
        UzunDosyaAdi[1] := #0;
        UzunDosyaAdiBulundu := False;
      end
      else}
      // 2. bir önceki girdi uzun dosya adý deðilse, 8 + 3 dosya ad + uzantý ve
      // diðer özellikleri geri döndür
      begin

        DosyaArama.DosyaAdi := HamDosyaAdiniDosyaAdinaCevir2(DizinGirdisi);
        DosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
        DosyaArama.OlusturmaSaati := DizinGirdisi^.OlusturmaSaati;
        DosyaArama.OlusturmaTarihi := DizinGirdisi^.OlusturmaTarihi;
        DosyaArama.SonErisimTarihi := DizinGirdisi^.SonErisimTarihi;
        DosyaArama.SonDegisimSaati := DizinGirdisi^.SonDegisimSaati;
        DosyaArama.SonDegisimTarihi := DizinGirdisi^.SonDegisimTarihi;
      end;

      // dosya uzunluðu ve cluster baþlangýcýný geri dönüþ deðerine ekle
      DosyaArama.DosyaUzunlugu := DizinGirdisi^.DosyaUzunlugu;
      DosyaArama.BaslangicKumeNo := DizinGirdisi^.BaslangicKumeNo;

      // gözardý edilecek giriþler
      if(DosyaArama.DosyaAdi = '.') then
      begin

      end
      else
      begin

        //Result := 0;
        //TumGirislerOkundu := True;
      end;


      // klasör kontrolü yapýlacak!!!
      if(DosyaArama.DosyaAdi = AKlasorAdi) then
      begin

        DosyaBulundu := True;
        TumGirislerOkundu := True;
        SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Dosya Adý: %s, Sýra No: %d',
          [DosyaArama.DosyaAdi, DizinGirisi.DizinTablosuKayitNo]);
      end;
    end;

    if not(TumGirislerOkundu) then
    begin

      // bir sonraki girdiye konumlan
      Inc(DizinGirisi.DizinTablosuKayitNo);
      if(DizinGirisi.DizinTablosuKayitNo = 16) then
      begin

        Inc(ZincirNo);
        if(ZincirNo = ZincirSektorSayisi - 1) then
        begin

          TumGirislerOkundu := True;
          DosyaBulundu := True;     // çýkýþ için, aþaðýdaki kodlarýn devreye girmemesi için

          { TODO - fat tablosundan bir sonraki alýnan giriþle devaö edilecektir, kodlamayý yap }
        end else DizinGirisi.DizinTablosuKayitNo := 0
      end else Inc(DizinGirdisi);
    end;

  until TumGirislerOkundu;

  // dosya oluþturma iþlemi
  if(DosyaBulundu) then
  begin

    if(DizinGirisi.DizinTablosuKayitNo >= 0) and (DizinGirisi.DizinTablosuKayitNo < 16) then
    begin

      DizinGirdisi^.DosyaAdi[0] := Chr($E5);   // $01 olarak deðiþecek

      FD.SektorYaz(@FD, SektorNo + ZincirNo, 1, Isaretci(@Bellek));
    end;
  end;
end;

{==============================================================================
  dosya silme iþlevini gerçekleþtirir
 ==============================================================================}
function DeleteFile(const ADosyaAdi: string): TISayi4;
var
  //DosyaKayit: PDosyaKayit;
  DosyaArama: TDosyaArama;
  TamAramaYolu, Surucu, Klasor, DosyaAdi: string;
  Bulundu: Boolean;
  Bellek: array[0..511] of TSayi1;
  Bellek2: array[0..31] of TSayi1 = (
    $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $08, $2D, $31, $66,
    $46, $5A, $56, $5A, $00, $00, $60, $A1, $56, $5A, $E5, $12, $00, $00, $00, $00);
  SektorNo, i, ZincirNo, ZincirBasinaSektor: TSayi4;
  MD: PMantiksalDepolama;
  DizinGirdisi: PDizinGirdisiELR;
  TumGirislerOkundu,
  UzunDosyaAdiBulundu, DosyaBulundu: Boolean;
  DizinGirisi: TDizinGirisi;
begin

  // dosya silme iþlevinin yapýlacaðý sürücüyü al
  MD := SurucuAl(ADosyaAdi);
  if(MD = nil) then Exit(1);

  //SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Sürücü: %s', [MD^.MD3.AygitAdi]);
  //SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Dosya Adý: %s', [DosyaAdi]);
  //SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'DST: %d', [MD^.MD3.DST]);

  if(MD^.MD3.DST = DST_ELR1) then
  begin

    // dosya yolunu ayrýþtýr
    DosyaYolunuParcala2(ADosyaAdi, Surucu, Klasor, DosyaAdi);

    DosyaBulundu := False;

    // her bir cluster'in 4 sektör olarak tasarlandýðý elr-1 dosya sistemi

    SektorNo := MD^.Acilis.DizinGirisi.IlkSektor;

    //SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor: %d', [MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor]);

    // ilk deðer atamalarý
    TumGirislerOkundu := False;

    //UzunDosyaAdiBulundu := False;

    // aramanýn yapýlacaðý sürücü
    //MD := GAramaKayitListesi[ADosyaArama.Kimlik].MantiksalDepolama;
    //DizinGirisi := @GAramaKayitListesi[ADosyaKimlik].DizinGirisi;

    // dosya iþlem yapýsý bellek bölgesine konumlan
    //DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

    DizinGirisi.DizinTablosuKayitNo := 0;
    DizinGirisi.OkunanSektor := 0;
    ZincirBasinaSektor := MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;
    ZincirNo := 0;

    // aramaya baþla
    repeat

      if(DizinGirisi.DizinTablosuKayitNo = 0) then
      begin

        // bir sonraki dizin giriþini oku
        MD^.FD^.SektorOku(MD^.FD, SektorNo + ZincirNo, 1, Isaretci(@Bellek));

        // DizinGirisi.OkunanSektor deðiþkeni elr dosya sisteminde anlamsýz
        // Inc(DizinGirisi.OkunanSektor);
      end;

      // dosya giriþ tablosuna konumlan
      DizinGirdisi := PDizinGirdisiELR(@Bellek);
      Inc(DizinGirdisi, DizinGirisi.DizinTablosuKayitNo);

      // dosya giriþinin ilk karakteri #0 ise giriþler okunmuþ demektir
      if(DizinGirdisi^.DosyaAdi[0] = #00) then
      begin

        //Result := 1;
        TumGirislerOkundu := True;
        //Exit;
      end
      // silinmiþ dosya / dizin
      else if(DizinGirdisi^.DosyaAdi[0] = Chr($FF)) then
      begin

        // bir sonraki giriþle devam et
      end
      // mantýksal depolama aygýtý etiket (volume label)
      else if(DizinGirdisi^.Ozellikler = $08) then
      begin

        // bir sonraki giriþle devam et
      end
      // dizin girdisi uzun ada sahip bir ad ise, uzun dosya adýný al
      {else if(DizinGirdisi^.Ozellikler = $0F) then
      begin

        UzunDosyaAdiBulundu := True;
        DosyaParcalariniBirlestir(Isaretci(DizinGirdisi));
      end}
      // dizin girdisinin uzun ad haricinde olmasý durumunda
      else //if(DizinGirdisi^.Ozellikler <> $0F) then
      begin

        // girdinin uzun ad dosya adý OLMAMASI durumunda

        // 1. bir önceki girdi uzun dosya adý ise, ad ve diðer özellikleri geri döndür
        {if(UzunDosyaAdiBulundu) then
        begin

          DosyaArama.DosyaAdi := WideChar2String(@UzunDosyaAdi);
          DosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
          DosyaArama.OlusturmaSaati := DizinGirdisi^.OlusturmaSaati;
          DosyaArama.OlusturmaTarihi := DizinGirdisi^.OlusturmaTarihi;
          DosyaArama.SonErisimTarihi := DizinGirdisi^.SonErisimTarihi;
          DosyaArama.SonDegisimSaati := DizinGirdisi^.SonDegisimSaati;
          DosyaArama.SonDegisimTarihi := DizinGirdisi^.SonDegisimTarihi;

          // deðiþken içeriklerini sýfýrla
          UzunDosyaAdi[0] := #0;
          UzunDosyaAdi[1] := #0;
          UzunDosyaAdiBulundu := False;
        end
        else}
        // 2. bir önceki girdi uzun dosya adý deðilse, 8 + 3 dosya ad + uzantý ve
        // diðer özellikleri geri döndür
        begin

          {DosyaArama.DosyaAdi := HamDosyaAdiniDosyaAdinaCevir3(DizinGirdisi);
          DosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
          DosyaArama.OlusturmaSaati := DizinGirdisi^.OlusturmaSaati;
          DosyaArama.OlusturmaTarihi := DizinGirdisi^.OlusturmaTarihi;
          DosyaArama.SonErisimTarihi := DizinGirdisi^.SonErisimTarihi;
          DosyaArama.SonDegisimSaati := DizinGirdisi^.SonDegisimSaati;
          DosyaArama.SonDegisimTarihi := DizinGirdisi^.SonDegisimTarihi;}
        end;

        // dosya uzunluðu ve cluster baþlangýcýný geri dönüþ deðerine ekle
        DosyaArama.DosyaUzunlugu := DizinGirdisi^.DosyaUzunlugu;
        DosyaArama.BaslangicKumeNo := DizinGirdisi^.BaslangicKumeNo;

        // gözardý edilecek giriþler
        if(DosyaArama.DosyaAdi = '.') then
        begin

        end
        else
        begin

          //Result := 0;
          //TumGirislerOkundu := True;
        end;

        // dosya kontrolü yapýlacak!!!
        if(DosyaArama.DosyaAdi = DosyaAdi) then
        begin

          DosyaBulundu := True;
          TumGirislerOkundu := True;
        end;
      end;

      if not(TumGirislerOkundu) then
      begin

        // bir sonraki girdiye konumlan
        Inc(DizinGirisi.DizinTablosuKayitNo);
        if(DizinGirisi.DizinTablosuKayitNo = 8) then
        begin

          Inc(ZincirNo);
          if(ZincirNo = ZincirBasinaSektor - 1) then
          begin

            TumGirislerOkundu := True;
            DosyaBulundu := True;     // çýkýþ için, aþaðýdaki kodlarýn devreye girmemesi için

            { TODO - fat tablosundan bir sonraki alýnan giriþle devaö edilecektir, kodlamayý yap }
          end else DizinGirisi.DizinTablosuKayitNo := 0
        end else Inc(DizinGirdisi);
      end;

    until TumGirislerOkundu;

    // dosya oluþturma iþlemi
    if(DosyaBulundu) then
    begin

      if(DizinGirisi.DizinTablosuKayitNo >= 0) and (DizinGirisi.DizinTablosuKayitNo < 8) then
      begin

        DizinGirdisi^.DosyaAdi[0] := Chr($FF);   // $01 olarak deðiþecek

        MD^.FD^.SektorYaz(MD^.FD, SektorNo + ZincirNo, 1, Isaretci(@Bellek));
      end;

      SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Dosya silindi', []);
    end;
  end
  else
  begin

    SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Ýþlev henüz yazýlmadý: %d', [MD^.MD3.DST]);
  end;
end;

{==============================================================================
  arama iþlemi için ayrýlan kaynaðý serbest býrakýr
 ==============================================================================}
procedure AramaKaydiniYokEt(ADosyaKimlik: TKimlik);
begin

  if(GDosyaIslemleri[ADosyaKimlik].Kullanilabilir = False) then
    GDosyaIslemleri[ADosyaKimlik].Kullanilabilir := True;
end;

{==============================================================================
  dosya iþlemleri için kaynak ayýrýr
 ==============================================================================}
function DosyaKaydiOlustur: TKimlik;
var
  i: TSayi4;
begin

  // boþ bellek bölgesi ara
  for i := 0 to USTSINIR_DOSYAISLEM - 1 do
  begin

    if(GDosyaIslemleri[i].Kullanilabilir) then
    begin

      GDosyaIslemleri[i].Kullanilabilir := False;

      // ilk deðer atamalarýný gerçekleþtir
      GDosyaIslemleri[i].DosyaDurumu := ddKapali;
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

  if(GDosyaIslemleri[ADosyaKimlik].Kullanilabilir = False) then
    GDosyaIslemleri[ADosyaKimlik].Kullanilabilir := True;
end;

function HamDosyaAdiniDosyaAdinaCevir2(ADizinGirdisi: PDizinGirdisi): string;
var
  NoktaEklendi: Boolean;
  i: TSayi4;
begin

  // hedef bellek bölgesini sýfýrla
  // hedef bellek alaný þu an 8+1+3+1 (dosya+.+uz+null) olmalýdýr
  Result := '';

  // dosya adýný çevir
  i := 0;
  while (i < 8) and (ADizinGirdisi^.DosyaAdi[i] <> ' ') do
  begin

    Result := Result + LowerCase(ADizinGirdisi^.DosyaAdi[i]);
    Inc(i);
  end;
end;

procedure IzKaydiOlustur(ADosyaAdi, AKayit: string);
var
  DosyaAdi: string;
  DosyaKimlik: TKimlik;
begin

  DosyaAdi := 'disk2:\klasor\' + ADosyaAdi;

  AssignFile(DosyaKimlik, DosyaAdi);
  ReWrite(DosyaKimlik);
  if(dosya.IOResult = 0) then
  begin

    Write(DosyaKimlik, AKayit);
    CloseFile(DosyaKimlik);
  end
  else
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'Hata: %s dosyasý zaten mevcut!', [DosyaAdi]);
    CloseFile(DosyaKimlik);
  end;
end;

procedure ELR1DiskBicimle(AMD: PMantiksalDepolama);
begin

  elr1.ELR1DiskBicimle(AMD);
end;

end.
