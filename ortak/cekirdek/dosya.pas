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

uses paylasim, gorev;

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
function FileSize(ADosyaKimlik: TKimlik): TISayi8;
function EOF(ADosyaKimlik: TKimlik): Boolean;
procedure CloseFile(ADosyaKimlik: TKimlik);
function CreateDir(AKlasorAdi: string): Boolean;
function RemoveDir(const AKlasorAdi: string): Boolean;
function DeleteFile(const ADosyaAdi: string): Boolean;
function DosyaIslemiOlustur: TKimlik;
procedure DosyaIsleminiSonlandir(ADosyaKimlik: TKimlik);

function DosyaOrtaminiHazirla(const ADosyaAdi: string): TKimlik;
function HamDosyaAdiniDosyaAdinaCevir2(ADizinGirdisi: PDizinGirdisi): string;
procedure IzKaydiOlustur(ADosyaAdi, AKayit: string);
procedure ELR1DiskBicimle(AMD: PMantiksalDepolama);
procedure DosyalariKopyala;
function DosyaKopyala(AKaynakDosya, AHedefDosya: string): TISayi4;

implementation

uses bolumleme, elr1, fat12, fat16, fat32, sistemmesaj, islevler, donusum, genel;

{==============================================================================
  dosya sistem iþlevlerinin kullanacaðý deðiþkenleri ilk deðerlerle yükle
 ==============================================================================}
procedure Yukle;
var
  i: TISayi4;
begin

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
  DosyaKimlik: TKimlik;
  DST: TSayi4;
  AramaSuzgeci, AranacakKlasor, Surucu, s: string;
  i, SektorNo,
  AyrilmisSektor: TSayi4;
begin

  // AAramaSuzgec
  // örnek: disk1:\klasör1\dizin1\*.*

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'AAramaSuzgec: %s', [AAramaSuzgec]);

  // arama için arama bilgilerinin saklanacaðý bellek bölgesi tahsis et
  DosyaKimlik := DosyaIslemiOlustur;
  if(DosyaKimlik = HATA_KIMLIK) then
  begin

    Result := 1;
    Exit;
  end;

  // arama kaydýný, çaðýran iþlevin deðiþkenine sakla
  ADosyaArama.Kimlik := DosyaKimlik;

  // arama iþlevinin yapýlacaðý sürücüyü al
  MD := SurucuAl(AAramaSuzgec);
  if(MD = nil) then
  begin

    // arama için kullanýlan bellek bölgesini serbest býrak
    DosyaIsleminiSonlandir(DosyaKimlik);
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
  GDosyaIslemleri[DosyaKimlik].MantiksalDepolama := MD;

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

    DST := GDosyaIslemleri[DosyaKimlik].MantiksalDepolama^.MD3.DST;

    if(Length(AranacakKlasor) > 0) then
    begin

      //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'AranacakDizin: ''%s''', [AranacakKlasor]);
      //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'AramaSuzgeci: ''%s''', [AramaSuzgeci]);

      if(DST <> DST_ELR1) then
      begin

        GDosyaIslemleri[DosyaKimlik].DizinGirisi.IlkSektor := SektorNo;
        GDosyaIslemleri[DosyaKimlik].SektorNo := -1;
        GDosyaIslemleri[DosyaKimlik].ZincirNo := 0;
        GDosyaIslemleri[DosyaKimlik].KayitSN := -1;

        SektorNo := DizinGirisindeAra(GDosyaIslemleri[DosyaKimlik], AranacakKlasor);
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
    end;
  until Length(AranacakKlasor) = 0;

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'AramaSuzgeci: ''%s''', [AramaSuzgeci]);
  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Ýlk Dizin Küme No: %d', [SektorNo]);
  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'XXYYTT: %d', [MD^.Acilis.DizinGirisi.IlkSektor + MD^.Acilis.DizinGirisi.ToplamSektor]);

  if(AramaSuzgeci = '*.*') then
  begin

    // dosya sistem tipine göre iþlevi yönlendir
    DST := GDosyaIslemleri[DosyaKimlik].MantiksalDepolama^.MD3.DST;

    GDosyaIslemleri[DosyaKimlik].SektorNo := -1;
    GDosyaIslemleri[DosyaKimlik].ZincirNo := 0;
    GDosyaIslemleri[DosyaKimlik].KayitSN := -1;

    // geçici
    if(DST = DST_ELR1) then
    begin

      GDosyaIslemleri[DosyaKimlik].DizinGirisi.IlkSektor := $600; //SektorNo;    // $600 = 1536
      GDosyaIslemleri[DosyaKimlik].DizinGirisi.ToplamSektor := 4; //MD^.Acilis.DizinGirisi.ToplamSektor;
    end
    else
    begin

      // arama iþlevinin aktif olarak kullanacaðý deðiþkenleri ata
      GDosyaIslemleri[DosyaKimlik].DizinGirisi.IlkSektor := SektorNo;
      GDosyaIslemleri[DosyaKimlik].DizinGirisi.ToplamSektor := MD^.Acilis.DizinGirisi.ToplamSektor;
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

  DosyaIsleminiSonlandir(ADosyaArama.Kimlik);
end;

{==============================================================================
  dosyalar ile ilgili iþlem yapmadan önce taným iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
begin

  ADosyaKimlik := DosyaOrtaminiHazirla(ADosyaAdi);
end;

{==============================================================================
  dosya oluþturma iþlevini gerçekleþtirir

  iþlev: dosya yoksa oluþturur, dosyanýn var olmasý durumunda tüm içeriði sýfýrlar
    (dosyayý yeniden oluturma durumuna getirir)
 ==============================================================================}
{ TODO - iþlev rtl'ye uyumlu hale getirilecek }
procedure ReWrite(ADosyaKimlik: TKimlik);
var
  AktifGorev: PGorev;
  DosyaIslem: PDosyaIslem;
  DST: TSayi4;
begin

  AktifGorev := GorevListesi[FAktifGorev];

  // en son iþlem hatalý ise çýk
  if(AktifGorev^.FDosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

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
end;

{==============================================================================
  dosyaya veri eklemek için dosya açma iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure Append(ADosyaKimlik: TKimlik);
var
  AktifGorev: PGorev;
  DosyaIslem: PDosyaIslem;
  DST: TSayi4;
begin

  AktifGorev := GorevListesi[FAktifGorev];

  // en son iþlem hatalý ise çýk
  if(AktifGorev^.FDosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

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
end;

{==============================================================================
  dosyayý okumadan önce ön hazýrlýk iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure Reset(ADosyaKimlik: TKimlik);
var
  AktifGorev: PGorev;
  DosyaIslem: PDosyaIslem;
  DST: TSayi4;
  DosyaArama: TDosyaArama;
  TamAramaYolu: string;
  Bulundu: Boolean;
begin

  AktifGorev := GorevListesi[FAktifGorev];

  // en son iþlem hatalý ise çýk
{  if(FileResult > 0) then Exit;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  DST := DosyaIslem^.MantiksalDepolama^.MD3.DST;

  if(DST = DST_ELR1) then

    elr1.Reset(ADosyaKimlik)

  else}
  begin

    // en son iþlem hatalý ise çýk
    if(AktifGorev^.FDosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

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

      DosyaIslem^.IlkZincirSektor := DosyaArama.BaslangicKumeNo;
      DosyaIslem^.Uzunluk := DosyaArama.DosyaUzunlugu;

      // dosya durumunu, "dosya okuma için açýldý" olarak güncelle
      DosyaIslem^.DosyaDurumu := ddOkumaIcinAcik;

    end else AktifGorev^.FDosyaSonIslemDurum := HATA_DOSYA_MEVCUTDEGIL;
  end;
end;

{==============================================================================
  dosyaya veri yazma iþlemini gerçekleþtirir
 ==============================================================================}
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
var
  AktifGorev: PGorev;
  DosyaIslem: PDosyaIslem;
  DST: TSayi4;
begin

  AktifGorev := GorevListesi[FAktifGorev];

  // en son iþlem hatalý ise çýk
  if(AktifGorev^.FDosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

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
  AktifGorev: PGorev;
  DosyaIslem: PDosyaIslem;
  DST: TSayi4;
begin

  AktifGorev := GorevListesi[FAktifGorev];

  // en son iþlem hatalý ise çýk
  if(AktifGorev^.FDosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

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
  AktifGorev: PGorev;
  DosyaIslem: PDosyaIslem;
  DST: TSayi4;
begin

  Result := 0;

  AktifGorev := GorevListesi[FAktifGorev];

  // en son iþlem hatalý ise çýk
  if(AktifGorev^.FDosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

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
  görev içerisinde, dosya ile yapýlmýþ en son iþlemin sonucunu döndürür
 ==============================================================================}
function IOResult: TISayi4;
var
  AktifGorev: PGorev;
begin

  AktifGorev := GorevListesi[FAktifGorev];

  Result := AktifGorev^.FDosyaSonIslemDurum;

  // son iþlem durumu geri döndürüldükten sonra deðiþkeni hata yok olarak iþaretle
  AktifGorev^.FDosyaSonIslemDurum := HATA_DOSYA_ISLEM_BASARILI;
end;

{==============================================================================
  dosya uzunluðunu geri döndürür
 ==============================================================================}
{ TODO - pascal ile uyum çerçevesinde iþlev yeniden kontrol edilebilir }
function FileSize(ADosyaKimlik: TKimlik): TISayi8;
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

  DosyaIsleminiSonlandir(ADosyaKimlik);
end;

{==============================================================================
  klasör oluþturma iþlevini gerçekleþtirir
 ==============================================================================}
function CreateDir(AKlasorAdi: string): Boolean;
var
  DosyaIslem: PDosyaIslem;
  DST: TSayi4;
  DosyaKimlik: TKimlik;
begin

  Result := False;

  DosyaKimlik := DosyaOrtaminiHazirla(AKlasorAdi);

  if(DosyaKimlik = HATA_KIMLIK) then Exit;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DosyaIslem := @GDosyaIslemleri[DosyaKimlik];

  DST := DosyaIslem^.MantiksalDepolama^.MD3.DST;

  if(DST = DST_ELR1) then

    Result := elr1.CreateDir(DosyaKimlik)

  else if(DST = DST_FAT12) then

    Result := fat12.CreateDir(DosyaKimlik)

  else if(DST = DST_FAT16) then

    Result := fat16.CreateDir(DosyaKimlik)

  else if(DST = DST_FAT32) or (DST = DST_FAT32LBA) then

    Result := fat32.CreateDir(DosyaKimlik);

  DosyaIsleminiSonlandir(DosyaKimlik);
end;

{==============================================================================
  klasör silme iþlevini gerçekleþtirir
 ==============================================================================}
function RemoveDir(const AKlasorAdi: string): Boolean;
var
  DosyaIslem: PDosyaIslem;
  DST: TSayi4;
  DosyaKimlik: TKimlik;
begin

  Result := False;

  DosyaKimlik := DosyaOrtaminiHazirla(AKlasorAdi);

  if(DosyaKimlik = HATA_KIMLIK) then Exit;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DosyaIslem := @GDosyaIslemleri[DosyaKimlik];

  DST := DosyaIslem^.MantiksalDepolama^.MD3.DST;

  if(DST = DST_ELR1) then

    Result := elr1.RemoveDir(DosyaKimlik)

  else if(DST = DST_FAT12) then

    Result := fat12.RemoveDir(DosyaKimlik)

  else if(DST = DST_FAT16) then

    Result := fat16.RemoveDir(DosyaKimlik)

  else if(DST = DST_FAT32) or (DST = DST_FAT32LBA) then

    Result := fat32.RemoveDir(DosyaKimlik);

  DosyaIsleminiSonlandir(DosyaKimlik);
end;

{==============================================================================
  dosya silme iþlevini gerçekleþtirir
 ==============================================================================}
function DeleteFile(const ADosyaAdi: string): Boolean;
var
  DosyaIslem: PDosyaIslem;
  DST: TSayi4;
  DosyaKimlik: TKimlik;
begin

  Result := False;

  DosyaKimlik := DosyaOrtaminiHazirla(ADosyaAdi);

  if(DosyaKimlik = HATA_KIMLIK) then Exit;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DosyaIslem := @GDosyaIslemleri[DosyaKimlik];

  DST := DosyaIslem^.MantiksalDepolama^.MD3.DST;

  if(DST = DST_ELR1) then

    Result := elr1.DeleteFile(DosyaKimlik)

  else if(DST = DST_FAT12) then

    Result := fat12.DeleteFile(DosyaKimlik)

  else if(DST = DST_FAT16) then

    Result := fat16.DeleteFile(DosyaKimlik)

  else if(DST = DST_FAT32) or (DST = DST_FAT32LBA) then

    Result := fat32.DeleteFile(DosyaKimlik);

  DosyaIsleminiSonlandir(DosyaKimlik);
end;

{==============================================================================
  dosya iþlemleri için kaynak ayýrýr
 ==============================================================================}
function DosyaIslemiOlustur: TKimlik;
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

      GDosyaIslemleri[i].TekSektorIcerik := GetMem(512);

      Result := i;
      Exit;
    end;
  end;

  Result := HATA_KIMLIK;
end;

{==============================================================================
  dosya iþlemi için ayrýlan kaynaðý iptal eder.
 ==============================================================================}
procedure DosyaIsleminiSonlandir(ADosyaKimlik: TKimlik);
begin

  if(GDosyaIslemleri[ADosyaKimlik].Kullanilabilir = False) then
  begin

    FreeMem(GDosyaIslemleri[ADosyaKimlik].TekSektorIcerik, 512);
    GDosyaIslemleri[ADosyaKimlik].Kullanilabilir := True;
  end;
end;

function DosyaOrtaminiHazirla(const ADosyaAdi: string): TKimlik;
var
  MD: PMantiksalDepolama;
  DosyaIslem: PDosyaIslem;
  DosyaKimlik: TKimlik;
  Surucu, Klasor, DosyaAdi: string;
  i: TSayi4;
begin

  // öndeðer geri dönüþ deðeri
  Result := HATA_KIMLIK;

  // dosya iþlemi için bellek bölgesi ayýr
  DosyaKimlik := DosyaIslemiOlustur;
  if(DosyaKimlik = HATA_KIMLIK) then Exit;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DosyaIslem := @GDosyaIslemleri[DosyaKimlik];

  // sürücünün iþaret ettiði bellek bölgesine konumlan
  MD := SurucuAl(ADosyaAdi);
  if(MD = nil) then
  begin

    DosyaIsleminiSonlandir(DosyaKimlik);
    Exit;
  end;

  // dosya tanýmlayýcýyý kaydet
  Result := DosyaKimlik;

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

  FillChar(DosyaIslem^.AktifDG[0], ELR_DOSYA_U, #0);

  DosyaIslem^.AktifDG[0] := Length(DosyaIslem^.DosyaAdi);

  for i := 1 to Length(DosyaIslem^.DosyaAdi) do
    DosyaIslem^.AktifDG[i] := Ord(DosyaIslem^.DosyaAdi[i]);

  // diðer deðerleri sýfýrla
  DosyaIslem^.DosyaDurumu := ddKapali;
  DosyaIslem^.DATBellekAdresi := nil;
  DosyaIslem^.IlkZincirSektor := 0;
  DosyaIslem^.Uzunluk := 0;
  DosyaIslem^.Konum := 0;
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
  if(IOResult = 0) then
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

procedure DosyalariKopyala;
var
  AramaKaydi: TDosyaArama;
  DosyaSayisi: TSayi4;
  i, Sonuc: TISayi4;
begin

  DosyaSayisi := 0;

  i := FindFirst('disk1:\progrmlr\*.*', 0, AramaKaydi);
  while i = 0 do
  begin

    if not(AramaKaydi.DosyaAdi = '..') then
    begin


      Sonuc := DosyaKopyala('disk1:\progrmlr\' + AramaKaydi.DosyaAdi, 'disk2:\' + AramaKaydi.DosyaAdi);
      if(Sonuc <> HATA_YOK) then
      begin

        SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Dosya Adý: %s', [AramaKaydi.DosyaAdi]);
        SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Hata Kodu: %d', [Sonuc]);
        FindClose(AramaKaydi);
        Exit;
      end;

    Inc(DosyaSayisi);
    //if(DosyaSayisi = 2) then Break;   // -1 dosya kopyalanacak
    if(DosyaSayisi = 14) then Break;   // -1 dosya kopyalanacak
    end;

    i := FindNext(AramaKaydi);
  end;

  FindClose(AramaKaydi);
end;

function DosyaKopyala(AKaynakDosya, AHedefDosya: string): TISayi4;
var
  DosyaKimlik: TKimlik;
  Bellek: Isaretci;
  U: TISayi8;
  Sonuc: TSayi2;
  s: String;
  i: Integer;
begin

{  s := 'Merhaba0' + #13#10;
  AssignFile(DosyaKimlik, AHedefDosya);
  //ReWrite(DosyaKimlik);
  Append(DosyaKimlik);
  Sonuc := IOResult;
  if(Sonuc = 0) then
  begin

    //Write(DosyaKimlik, Isaretci(0), 300);
    for i := 1 to 500 do
      Write(DosyaKimlik, s);
  end else SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Hedef Dosya Hatasý: %d', [Sonuc]);

  CloseFile(DosyaKimlik);

  Exit;
}

  Result := HATA_YOK;

  AssignFile(DosyaKimlik, AKaynakDosya);
  Reset(DosyaKimlik);
  Sonuc := IOResult;
  if(Sonuc = HATA_DOSYA_ISLEM_BASARILI) then
  begin

    U := FileSize(DosyaKimlik);

    Bellek := GetMem(U);

    Read(DosyaKimlik, Bellek);
    CloseFile(DosyaKimlik);

    AssignFile(DosyaKimlik, AHedefDosya);
    ReWrite(DosyaKimlik);
    Sonuc := IOResult;
    if(Sonuc = 0) then
    begin

      Write(DosyaKimlik, Bellek, U);
    end
    else
    begin

      Result := Sonuc;
      //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Hedef Dosya Hatasý: %d', [Sonuc]);
    end;

    CloseFile(DosyaKimlik);

    FreeMem(Bellek, U);

    //if(Result <> HATA_YOK) then Exit;
  end
  else
  begin

    Result := Sonuc;
    //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Kaynak Dosya Hatasý: %d', [Sonuc]);
  end;
end;

end.
