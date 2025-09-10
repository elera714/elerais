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

uses paylasim, gorev, mdepolama;

const
  USTSINIR_DOSYAISLEM = 10;

// tüm dosya iþlevleri için gereken yapý
type
  TDosyaDurumu = (ddKapali, ddOkumaIcinAcik, ddYazmaIcinAcik);

  PDosyaIslem = ^TDosyaIslem;
  TDosyaIslem = record
    MantiksalDepolama: PMDNesne;
    Klasor, DosyaAdi: string;
    DATBellekAdresi: Isaretci;    // Dosya Ayýrma Tablosu bellek adresi
    IlkZincirSektor: Word;
    Uzunluk: TISayi4;
    Konum: TSayi4;

    // dizin giriþinin tek sektörlük içeriði, iþlevler arasý veri alýþveriþi için
    TekSektorIcerik: Isaretci;

    Kimlik: TKimlik;
    Gorev: PGorev;            // dosya iþlemini gerçekleþtiren görev

    // üzerinde iþlem yapýlan aktif dosya / klasör için dizin giriþi
    // tüm dosya iþlemleri bu yapý üzerinde olacak, daha sonra sektörün ilgili sýrasýna aktarýlacak
    // tüm iþlevler dosya açýk olduðu müddetçe tekrar tekrar dizin giriþini okumadan bu yapýya bakarak
    // karar mekanizmalarýný oluþturacak
    { TODO - iptal edilecek }
    AktifDG: array[0..63] of TSayi1;


    // iþlem yapýlan sektör numarasý (-1 = sektör henüz okunmadý)
    SektorNo,       { TODO - bu deðiþken iptal edilecek, KumeNo deðiþkeniyle devam edilecek }


    // dosya / klasörün okunan dizin sektöründeki (SektorNo) kayýt sýra numarasý
    // -1 sektör okunacak (kayýt sýra numarasý yok)
    KayitSN,
    KumeNo: TISayi4;
    ZincirNo: TSayi4;
    DosyaDurumu: TDosyaDurumu;

    // dosya arama iþlemleri için - yukarýdaki yapýlarla birliktelik saðlanacak
    DizinGirisi: TDizinGirisi;
    Aranan: string;
  end;

type
  TDosya = object

  end;

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
procedure DosyaIsleminiSonlandir(ADosyaKimlik: TKimlik);

function DosyaOrtaminiHazirla(const ADosyaAdi: string): TKimlik;
function HamDosyaAdiniDosyaAdinaCevir2(ADizinGirdisi: PDizinGirdisi): string;
procedure IzKaydiOlustur(ADosyaAdi, AKayit: string);
procedure ELR1DiskBicimle(AMDNesne: PMDNesne);
procedure DosyalariKopyala;
function DosyaKopyala(AKaynakDosya, AHedefDosya: string): TISayi4;

type
  TDosyalar = object
  private
    FDosyaIslemleri: array[0..USTSINIR_DOSYAISLEM - 1] of PDosyaIslem;
    function DosyaIslemAl(ASiraNo: TSayi4): PDosyaIslem;
    procedure DosyaIslemYaz(ASiraNo: TSayi4; ADosyaIslem: PDosyaIslem);
  public
    procedure Yukle;
    function Yeni: PDosyaIslem;
    property DosyaIslem[ASiraNo: TSayi4]: PDosyaIslem read DosyaIslemAl write DosyaIslemYaz;
  end;

var
  Dosyalar0: TDosyalar;

implementation

uses elr1, fat12, fat16, fat32, sistemmesaj, islevler, donusum, genel;

{==============================================================================
  dosya sistem iþlevlerinin kullanacaðý deðiþkenleri ilk deðerlerle yükle
 ==============================================================================}
procedure TDosyalar.Yukle;
var
  i: TSayi4;
begin

  // dosya iþlev deðiþkenlerini sýfýrla
  for i := 0 to USTSINIR_DOSYAISLEM - 1 do Dosyalar0.DosyaIslem[i] := nil;
end;

{==============================================================================
  dosya arama iþlevini baþlatýr
 ==============================================================================}
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
  var ADosyaArama: TDosyaArama): TISayi4;
var
  MD: PMDNesne;
  DST: TSayi4;
  AramaSuzgeci, AranacakKlasor, Surucu, s: string;
  i, SektorNo,
  AyrilmisSektor: TSayi4;
  DI: PDosyaIslem;
begin

  // AAramaSuzgec
  // örnek: disk1:\klasör1\dizin1\*.*

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'AAramaSuzgec: %s', [AAramaSuzgec]);

  // arama için arama bilgilerinin saklanacaðý bellek bölgesi tahsis et
  DI := Dosyalar0.Yeni;
  if(DI = nil) then
  begin

    Result := HATA_KIMLIK;
    Exit;
  end;

  // arama kaydýný, çaðýran iþlevin deðiþkenine sakla
  ADosyaArama.Kimlik := DI^.Kimlik;

  // arama iþlevinin yapýlacaðý sürücüyü al
  MD := MantiksalDepolama0.SurucuAl(AAramaSuzgec);
  if(MD = nil) then
  begin

    // arama için kullanýlan bellek bölgesini serbest býrak
    DosyaIsleminiSonlandir(DI^.Kimlik);
    Result := 1;
    Exit;
  end;

  s := AAramaSuzgec;

  // AAramaSuzgec -> örnek: disk2:\klasör1\*.*
  i := Pos(':', s);
  if(i > 0) then
  begin

    Surucu := Copy(s, 1, i - 1);            // disk2
    s := Copy(s, i + 1, Length(s) - i);     // s = \klasör1\*.*
  end;
  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Sürücü: ''%s''', [Surucu]);

  if not(s[1] = '\') then
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'DOSYA.PAS: Arama süzgeç söz dizilimi hatalý!', []);
    Result := 1;
    Exit;
  end;
  s := Copy(s, 2, Length(s) - 1);           // s = klasör1\*.*

  // sürücüyü arama bellek bölgesine ekle
  //DI := Dosyalar0.DosyaIslem[DosyaKimlik];
  DI^.MantiksalDepolama := MD;

  SektorNo := MD^.Acilis.DizinGirisi.IlkSektor;

  // AyrilmisSektor = zincir deðerine eklenecek deðer
  AyrilmisSektor := MD^.Acilis.DizinGirisi.IlkSektor + MD^.Acilis.DizinGirisi.ToplamSektor;

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'SektorNo: ''%d''', [SektorNo]);
  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'AyrilmisSektor: ''%d''', [AyrilmisSektor]);

  // bu aþamada s = klasör1\*.*
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

    DST := DI^.MantiksalDepolama^.MD3.DST;

    if(Length(AranacakKlasor) > 0) then
    begin

      //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'AranacakDizin: ''%s''', [AranacakKlasor]);
      //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'AramaSuzgeci: ''%s''', [AramaSuzgeci]);

      if(DST <> DST_ELR1) then
      begin

        DI^.DizinGirisi.IlkSektor := SektorNo;
        DI^.SektorNo := -1;
        DI^.ZincirNo := 0;
        DI^.KayitSN := -1;

        SektorNo := DizinGirisindeAra(DI, AranacakKlasor);
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
  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Ýlk Dizin Küme No: $%x', [SektorNo]);
  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'XXYYTT: %d', [MD^.Acilis.DizinGirisi.IlkSektor + MD^.Acilis.DizinGirisi.ToplamSektor]);

  if(AramaSuzgeci = '*.*') then
  begin

    // dosya sistem tipine göre iþlevi yönlendir
    DST := DI^.MantiksalDepolama^.MD3.DST;

    DI^.KumeNo := -1;
    DI^.SektorNo := -1;
    DI^.ZincirNo := 0;
    DI^.KayitSN := -1;

    // geçici
    if(DST = DST_ELR1) then
    begin

      DI^.DizinGirisi.IlkSektor := $600; //SektorNo;    // $600 = 1536
      DI^.DizinGirisi.ToplamSektor := 4; //MD^.Acilis.DizinGirisi.ToplamSektor;
    end
    else
    begin

      // arama iþlevinin aktif olarak kullanacaðý deðiþkenleri ata
      DI^.DizinGirisi.IlkSektor := SektorNo;
      DI^.DizinGirisi.ToplamSektor := MD^.Acilis.DizinGirisi.ToplamSektor;
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
  DI: PDosyaIslem;
begin

  DI := Dosyalar0.DosyaIslem[ADosyaArama.Kimlik];
  DST := DI^.MantiksalDepolama^.MD3.DST;

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
  DI: PDosyaIslem;
  DST: TSayi4;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];
  if(DI = nil) then
  begin

    DI^.Gorev^.DosyaSonIslemDurum := HATA_KIMLIK;
    Exit;
  end;

  // en son iþlem hatalý ise çýk
  if(DI^.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  DST := DI^.MantiksalDepolama^.MD3.DST;

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
  DI: PDosyaIslem;
  DST: TSayi4;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];
  if(DI = nil) then Exit;

  // en son iþlem hatalý ise çýk
  if(DI^.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  DST := DI^.MantiksalDepolama^.MD3.DST;

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
  DI: PDosyaIslem;
  DST: TSayi4;
  DosyaArama: TDosyaArama;
  TamAramaYolu: string;
  Bulundu: Boolean;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];
  if(DI = nil) then Exit;

  // en son iþlem hatalý ise çýk
  if(DI^.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  // en son iþlem hatalý ise çýk
{

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  DST := DosyaIslem^.MantiksalDepolama^.MD3.DST;

  if(DST = DST_ELR1) then

    elr1.Reset(ADosyaKimlik)

  else}
  begin

    // en son iþlem hatalý ise çýk
    if(DI^.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

    // tam dosya adýný al
    TamAramaYolu := DI^.MantiksalDepolama^.MD3.AygitAdi + ':' + DI^.Klasor + '*.*';

    // dosyayý dosya tablosunda bul
    Bulundu := False;
    if(FindFirst(TamAramaYolu, 0, DosyaArama) = 0) then
    begin

      repeat

        if(DosyaArama.DosyaAdi = DI^.DosyaAdi) then Bulundu := True;
      until (Bulundu) or (FindNext(DosyaArama) <> 0);

      FindClose(DosyaArama);
    end;

    // dosyanýn tabloda bulunmasý halinde
    // dosyanýn ilk dizi ve uzunluðunu al
    if(Bulundu) then
    begin

      DI^.IlkZincirSektor := DosyaArama.BaslangicKumeNo;
      DI^.Uzunluk := DosyaArama.DosyaUzunlugu;

      // dosya durumunu, "dosya okuma için açýldý" olarak güncelle
      DI^.DosyaDurumu := ddOkumaIcinAcik;

    end else DI^.Gorev^.DosyaSonIslemDurum := HATA_DOSYA_MEVCUTDEGIL;
  end;
end;

{==============================================================================
  dosyaya veri yazma iþlemini gerçekleþtirir
 ==============================================================================}
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
var
  DI: PDosyaIslem;
  DST: TSayi4;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];
  if(DI = nil) then Exit;

  // en son iþlem hatalý ise çýk
  if(DI^.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  DST := DI^.MantiksalDepolama^.MD3.DST;

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
  DI: PDosyaIslem;
  DST: TSayi4;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];
  if(DI = nil) then Exit;

  // en son iþlem hatalý ise çýk
  if(DI^.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  DST := DI^.MantiksalDepolama^.MD3.DST;

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
  DI: PDosyaIslem;
  DST: TSayi4;
begin

  Result := 0;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];
  if(DI = nil) then Exit;

  // en son iþlem hatalý ise çýk
  if(DI^.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  DST := DI^.MantiksalDepolama^.MD3.DST;

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

  AktifGorev := GorevAl(-1);
  if(AktifGorev = nil) then Exit(HATA_KIMLIK);

  Result := AktifGorev^.DosyaSonIslemDurum;

  // son iþlem durumu geri döndürüldükten sonra deðiþkeni hata yok olarak iþaretle
  AktifGorev^.DosyaSonIslemDurum := HATA_DOSYA_ISLEM_BASARILI;
end;

{==============================================================================
  dosya uzunluðunu geri döndürür
 ==============================================================================}
{ TODO - pascal ile uyum çerçevesinde iþlev yeniden kontrol edilebilir }
function FileSize(ADosyaKimlik: TKimlik): TISayi8;
var
  DI: PDosyaIslem;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];
  if(DI = nil) then Exit(0);

  Result := DI^.Uzunluk;
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
  DosyaIslem := Dosyalar0.DosyaIslem[DosyaKimlik];

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
  DosyaIslem := Dosyalar0.DosyaIslem[DosyaKimlik];

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
  DosyaIslem := Dosyalar0.DosyaIslem[DosyaKimlik];

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
  yeni dosya iþlemleri için kaynak ayýrýr
 ==============================================================================}
function TDosyalar.Yeni: PDosyaIslem;
var
  DI: PDosyaIslem;
  i: TSayi4;
begin

  // boþ bellek bölgesi ara
  for i := 0 to USTSINIR_DOSYAISLEM - 1 do
  begin

    DI := DosyaIslem[i];

    if(DI = nil) then
    begin

      DI := GetMem(SizeOf(TDosyaIslem));
      DosyaIslem[i] := DI;

      // ilk deðer atamalarýný gerçekleþtir
      DI^.DosyaDurumu := ddKapali;
      DI^.Kimlik := i;
      DI^.TekSektorIcerik := GetMem(512);

      Exit(DI);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  dosya iþlemi için ayrýlan kaynaðý iptal eder.
 ==============================================================================}
procedure DosyaIsleminiSonlandir(ADosyaKimlik: TKimlik);
var
  DI: PDosyaIslem;
begin

  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];

  if not(DI = nil) then
  begin

    FreeMem(DI^.TekSektorIcerik, 512);
    FreeMem(DI, SizeOf(TDosyaIslem));
    Dosyalar0.DosyaIslem[ADosyaKimlik] := nil;
  end;
end;

function DosyaOrtaminiHazirla(const ADosyaAdi: string): TKimlik;
var
  MD: PMDNesne;
  DI: PDosyaIslem;
  Surucu, Klasor, DosyaAdi: string;
  i: TSayi4;
begin

  // öndeðer geri dönüþ deðeri
  Result := HATA_KIMLIK;

  // dosya iþlemi için bellek bölgesi ayýr
  DI := Dosyalar0.Yeni;
  if(DI = nil) then Exit;

  // sürücünün iþaret ettiði bellek bölgesine konumlan
  MD := MantiksalDepolama0.SurucuAl(ADosyaAdi);
  if(MD = nil) then
  begin

    DosyaIsleminiSonlandir(DI^.Kimlik);
    Exit;
  end;

  // dosya tanýmlayýcýyý kaydet
  Result := DI^.Kimlik;

  DI^.Gorev := GorevAl(-1);
  if(DI = nil) then
  begin

    DosyaIsleminiSonlandir(DI^.Kimlik);
    Exit;
  end;

  // iþlem yapýlacak sürücü
  DI^.MantiksalDepolama := MD;

  // dosya yolunu ayrýþtýr
  DosyaYolunuParcala2(ADosyaAdi, Surucu, Klasor, DosyaAdi);

  {SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Sürücü: %s', [Surucu]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Klasör: %s', [Klasor]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Dosya Adý: %s', [DosyaAdi]);}

  // klasör ve dosya adý
  DI^.Klasor := Klasor;
  DI^.DosyaAdi := DosyaAdi;

  FillChar(DI^.AktifDG[0], ELR_DOSYA_U, #0);

  DI^.AktifDG[0] := Length(DI^.DosyaAdi);

  for i := 1 to Length(DI^.DosyaAdi) do
    DI^.AktifDG[i] := Ord(DI^.DosyaAdi[i]);

  // diðer deðerleri sýfýrla
  DI^.DosyaDurumu := ddKapali;
  DI^.DATBellekAdresi := nil;
  DI^.IlkZincirSektor := 0;
  DI^.Uzunluk := 0;
  DI^.Konum := 0;
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

procedure ELR1DiskBicimle(AMDNesne: PMDNesne);
begin

  elr1.ELR1DiskBicimle(AMDNesne);
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
    {Sonuc := IOResult;
    if(Sonuc = HATA_DOSYA_ISLEM_BASARILI) then
    begin

      Write(DosyaKimlik, Bellek, U);
    end
    else
    begin

      Result := Sonuc;
      //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Hedef Dosya Hatasý: %d', [Sonuc]);
    end;}

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

{ TDosyalar }

function TDosyalar.DosyaIslemAl(ASiraNo: TSayi4): PDosyaIslem;
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_DOSYAISLEM) then
    Result := FDosyaIslemleri[ASiraNo]
  else Result := nil;
end;

procedure TDosyalar.DosyaIslemYaz(ASiraNo: TSayi4; ADosyaIslem: PDosyaIslem);
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_DOSYAISLEM) then
    FDosyaIslemleri[ASiraNo] := ADosyaIslem;
end;

end.
