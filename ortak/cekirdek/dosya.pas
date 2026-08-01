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

type
  // dosya yükleme iþlem bilgileri
  TDosyaYukleme = record
    Durum: TISayi4;
    Uzunluk: TSayi4;
  end;

// tüm dosya iþlevleri için gereken yapý
type
  TDosyaDurumu = (ddKapali, ddOkumaIcinAcik, ddYazmaIcinAcik);

type
  PDosya = ^TDosya;
  TDosya = class
    MD: TMDNesne;
    Klasor, DosyaAdi: string;

    // dizin / dosya giriþinin Tek Sektörlük Içeriði. (iþlevler arasý veri alýþveriþi için)
    TSI: Isaretci;

    KlasorDerinlik: TISayi4;          // 0 = kök dizin, 1 = alt dizin, 2 = alt dizinin alt dizini ...

    // iþlevler için kullanýlacak genel bellek iþaretçileri
    BellekSHT,                        // sektör harita tablosunu (fat) yüklemek için kullanýlacak
    Bellek2: Isaretci;
    BellekSHTDurum,
    Durum2: Boolean;                  // bellek durumlarýný tutan deðiþkenler (genel kullaným için)

    Kimlik: TKimlik;
    Gorev: PGorev;            // dosya iþlemini gerçekleþtiren görev

    { SektorIcýKonum deðeri 512 byte'lýk sektörün içerisinde 0,32,64 olarak artýþ gösteren imleç deðeridir.
      512 olduðunda bir sonraki sektör yüklenir.
      KayitSN deðeri yok edilerek SektorIcýKonum deðeri ikame edilecek }
    SektorIciKonum,

    SektorKumeNo: TISayi4;            // fat12 / fat16 kök dizin için sektör no, diðer durumlarda küme no
    ZincirNo: TSayi4;
    DosyaDurumu: TDosyaDurumu;

    // silinmiþ ilk girdi deðiþkenleri
    SilinenKumeNo,
    SilinenZincirNo,
    SilinenKayitSN: TISayi4;

    Aranan: string;
  end;

function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
  var ADosyaArama: TDosyaArama; AYDAKOlustur: Boolean = True): TISayi4;
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
procedure ReWrite(ADosyaKimlik: TKimlik);
procedure Append(ADosyaKimlik: TKimlik);
procedure Reset(ADosyaKimlik: TKimlik);
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
procedure WriteLn(ADosyaKimlik: TKimlik; AVeri: string);
procedure Write(ADosyaKimlik: TKimlik; ABellekAdresi: Isaretci; AUzunluk: TSayi4);
procedure Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci);
function IOResult: TISayi4;
function FileSize(ADosyaKimlik: TKimlik): TISayi8;
function EOF(ADosyaKimlik: TKimlik): Boolean;
procedure CloseFile(ADosyaKimlik: TKimlik);
function CreateDir(AKlasorAdi: string): Boolean;
function RemoveDir(const AKlasorAdi: string): Boolean;
function DeleteFile(const ADosyaAdi: string): Boolean;

function DosyaOrtaminiHazirla(const ADosyaAdi: string): TKimlik;
function HamDosyaAdiniDosyaAdinaCevir2(ADizinGirdisi: PDizinGirdisi): string;
procedure IzKaydiOlustur(ADosyaAdi, AKayit: string; AYeniDosyaOlustur: Boolean = True);
procedure ELR1DiskBicimle(AMDNesne: PMDNesne);
procedure DosyalariKopyala;
function DosyaKopyala(AKaynakDosya, AHedefDosya: string): TISayi4;
function DosyaOku(ADosyaTamYol: string; var ABellekAdresi: Isaretci): TDosyaYukleme;

type
  TDosyalar = class
  private
    FDosyaIslemSayisi: TSayi4;
    FDosyaIslemleri: array[0..USTSINIR_DOSYAISLEM - 1] of TDosya;
    function Al(ASiraNo: TISayi4): TDosya;
    procedure Yaz(ASiraNo: TISayi4; ADosya: TDosya);
  public
    constructor Create;
    function Yeni: TDosya;
    procedure DosyaIsleminiSonlandir(ADosyaKimlik: TKimlik);
    property DosyaListesi[ASiraNo: TISayi4]: TDosya read Al write Yaz;
    property DosyaIslemSayisi: TSayi4 read FDosyaIslemSayisi;
  end;

var
  GDosyalar: TDosyalar;

  // dosya çalýþtýrma iþlevi için gerekli yapý
  DosyaCalistir: TDosyaYukleme;
  // dosya çalýþtýrma aþamasýnda oluþan hatalarý göstermek için oluþturulan program yönetimi
  DosyaUyari: TDosyaYukleme;

implementation

uses elr1, fat12, fat16, fat32, sistemmesaj, islevler, donusum, genel, gercekbellek;

{==============================================================================
  dosya sistem iþlevlerinin kullanacaðý deðiþkenleri ilk deðerlerle yükle
 ==============================================================================}
constructor TDosyalar.Create;
var
  i: TSayi4;
begin

  FDosyaIslemSayisi := 0;

  // dosya iþlev deðiþkenlerini sýfýrla
  for i := 0 to USTSINIR_DOSYAISLEM - 1 do DosyaListesi[i] := nil;
end;

{==============================================================================
  dosya arama iþlevini baþlatýr
 ==============================================================================}
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
  var ADosyaArama: TDosyaArama; AYDAKOlustur: Boolean = True): TISayi4;
var
  MD: PMDNesne;
  D: TDosya;
  DST: TSayi4;
  AramaSuzgeci, AranacakKlasor,
  Surucu, s: string;
  i, SektorNo, KumeNo,
  AyrilmisSektor: TSayi4;
begin

  Result := HATA_KIMLIK;

  // AAramaSuzgec
  // örnek: disk1:\klasör1\dizin1\*.*

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'AAramaSuzgec: %s', [AAramaSuzgec]);

  // AYDAKOlustur deðiþkeninin True olmasý durumunda, arama için yeni dosya iþlem kaydý oluþturulur.
  // False olmasý durumunda daha önce oluþturulmuþ kayýt kullanýlýr
  // (Bu deðiþken uyum amaçlý olup, geçicidir ve iptal edilecektir)
  if(AYDAKOlustur) then
  begin

    D := GDosyalar.Yeni;
    if(D = nil) then Exit;

    // arama kaydýný, çaðýran iþlevin deðiþkenine sakla
    ADosyaArama.Kimlik := D.Kimlik;

  end else D := GDosyalar.DosyaListesi[ADosyaArama.Kimlik];

  // arama iþlevinin yapýlacaðý sürücüyü al
  MD := MantiksalDepolama0.SurucuAl(AAramaSuzgec);
  if(MD = nil) then
  begin

    // arama için kullanýlan bellek bölgesini serbest býrak
    GDosyalar.DosyaIsleminiSonlandir(D.Kimlik);
    Exit(1);
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

    //SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'DOSYA.PAS: Arama süzgeç söz dizilimi hatalý!', []);
    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, '->AAramaSuzgec: %s', [AAramaSuzgec]);
    Exit(1);
  end;
  s := Copy(s, 2, Length(s) - 1);           // s = klasör1\*.*

  // sürücüyü arama bellek bölgesine ekle
  D.MD := MD^;

  // önce kök dizin aranacak
  D.KlasorDerinlik := 0;

  SektorNo := MD^.Acilis.DizinGirisi.IlkSektor;

  // AyrilmisSektor = zincir deðerine eklenecek deðer
  AyrilmisSektor := SektorNo + MD^.Acilis.DizinGirisi.ToplamSektor;

  // bu aþamada s = klasör1\*.*

  // dosya sistem tipine göre iþlevi yönlendir
  DST := D.MD.MD3.DST;

  if(DST = DST_ELR1) then
    KumeNo := MD^.Acilis.DizinGirisi.IlkSektor
  else if(DST = DST_FAT12) then
    KumeNo := MD^.Acilis.DizinGirisi.IlkSektor
  else KumeNo := MD^.Acilis.DizinGirisi.IlkKumeNo;


  // istenen (alt) klasörün dizin tablosunda aranmasý
  repeat

    // arama süzgecinden sýradaki klasörün alýnmasý
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

    D.ZincirNo := 0;
    D.SektorIciKonum := -MD^.Acilis.DizinGirisi.GirdiUzunlugu;

    // klasörün dizin giriþinde aranmasý
    if(Length(AranacakKlasor) > 0) then
    begin

      //SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'AranacakKlasor: ''%s''', [AranacakKlasor]);
      //SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'AramaSuzgeci: ''%s''', [AramaSuzgeci]);

      case DST of
        DST_ELR1    : D.SektorKumeNo := KumeNo;
        DST_FAT12   : D.SektorKumeNo := KumeNo;
        DST_FAT32,
        DST_FAT32LBA: D.SektorKumeNo := KumeNo;
      end;

      if(D.KlasorDerinlik = 0) then
      begin

        case DST of
          DST_ELR1: KumeNo := DizinGirisindeAraELR1(D.Kimlik, AranacakKlasor);
          DST_FAT12: KumeNo := KokGirdisindeAra12(D.Kimlik, AranacakKlasor);
          else KumeNo := KokGirdisindeAra32(@D, AranacakKlasor);
        end;
      end
      else
      begin

        case DST of
          DST_ELR1: KumeNo := DizinGirisindeAraELR1(D.Kimlik, AranacakKlasor);
          DST_FAT12: KumeNo := KokGirdisindeAra12(D.Kimlik, AranacakKlasor);
          else KumeNo := DizinGirisindeAra32(@D, AranacakKlasor);
        end;
      end;

      if(KumeNo = 0) then
      begin

        SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'DOSYA.PAS: %s dizini dosya tablosunda mevcut deðil!', [AranacakKlasor]);
        Exit(1);
      end;

      D.KlasorDerinlik := 1;

      if(DST = DST_FAT12) or (DST = DST_FAT16) or (DST = DST_FAT32) or (DST = DST_FAT32LBA) then
      begin

        SektorNo := ((KumeNo - 2) * MD^.Acilis.DosyaAyirmaTablosu.KBS) + AyrilmisSektor;
        //SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'S: %d', [SektorNo]);
      end;
    end;
  until Length(AranacakKlasor) = 0;

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'AramaSuzgeci: ''%s''', [AramaSuzgeci]);
  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Ýlk Dizin Küme No: $%x', [SektorNo]);
  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'XXYYTT: %d', [MD^.Acilis.DizinGirisi.IlkSektor + MD^.Acilis.DizinGirisi.ToplamSektor]);

  D.SektorKumeNo := KumeNo;
  D.ZincirNo := 0;
  D.SektorIciKonum := -MD^.Acilis.DizinGirisi.GirdiUzunlugu;

  if(DST = DST_FAT12) then
  begin

    if(D.KlasorDerinlik = 0) then
      D.SektorKumeNo := MD^.Acilis.DizinGirisi.IlkSektor
    else
      D.SektorKumeNo := KumeNo;
  end;

  if(AramaSuzgeci = '*.*') then
  begin

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
  D: TDosya;
  DST: TSayi4;
begin

  D := GDosyalar.DosyaListesi[ADosyaArama.Kimlik];
  DST := D.MD.MD3.DST;

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

  GDosyalar.DosyaIsleminiSonlandir(ADosyaArama.Kimlik);
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
  D: TDosya;
  DST: TSayi4;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaKimlik];
  if(D = nil) then
  begin

    D.Gorev^.DosyaSonIslemDurum := HATA_KIMLIK;
    Exit;
  end;

  // en son iþlem hatalý ise çýk
  if(D.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  DST := D.MD.MD3.DST;

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
  D: TDosya;
  DST: TSayi4;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaKimlik];
  if(D = nil) then
  begin

    D.Gorev^.DosyaSonIslemDurum := HATA_KIMLIK;
    Exit;
  end;

  // en son iþlem hatalý ise çýk
  if(D.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  DST := D.MD.MD3.DST;

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
  D: TDosya;
  DST: TSayi4;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaKimlik];
  if(D = nil) then Exit;

  // en son iþlem hatalý ise çýk
  if(D.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  // en son iþlem hatalý ise çýk

  DST := D.MD.MD3.DST;

  if(DST = DST_ELR1) then

    elr1.Reset(ADosyaKimlik)

  else fat32.Reset(ADosyaKimlik);
end;

{==============================================================================
  dosyaya veri yazma iþlemini gerçekleþtirir
 ==============================================================================}
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
var
  D: TDosya;
  DST: TSayi4;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaKimlik];
  if(D = nil) then
  begin

    D.Gorev^.DosyaSonIslemDurum := HATA_KIMLIK;
    Exit;
  end;

  // en son iþlem hatalý ise çýk
  if(D.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  DST := D.MD.MD3.DST;

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
  D: TDosya;
  DST: TSayi4;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaKimlik];
  if(D = nil) then Exit;

  // en son iþlem hatalý ise çýk
  if(D.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  DST := D.MD.MD3.DST;

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
procedure Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci);
var
  D: TDosya;
  DST: TSayi4;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaKimlik];
  if(D = nil) then
  begin

    D.Gorev^.DosyaSonIslemDurum := HATA_KIMLIK;
    Exit;
  end;

  // en son iþlem hatalý ise çýk
  if(D.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  DST := D.MD.MD3.DST;

  if(DST = DST_ELR1) then

    elr1.Read(ADosyaKimlik, AHedefBellek)

  else if(DST = DST_FAT12) then

    fat12.Read(ADosyaKimlik, AHedefBellek)

  else if(DST = DST_FAT16) then

    fat16.Read(ADosyaKimlik, AHedefBellek)

  else if(DST = DST_FAT32) or (DST = DST_FAT32LBA) then

    fat32.Read(ADosyaKimlik, AHedefBellek);
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
  D: TDosya;
  DST: TSayi4;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaKimlik];
  if(D = nil) then
  begin

    D.Gorev^.DosyaSonIslemDurum := HATA_KIMLIK;
    Exit(-1);
  end;

  // en son iþlem hatalý ise çýk
  if(D.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit(-1);

  DST := D.MD.MD3.DST;

  if(DST = DST_ELR1) then

    Result := elr1.FileSize(ADosyaKimlik)

  else if(DST = DST_FAT12) then

    Result := fat12.FileSize(ADosyaKimlik)

  else if(DST = DST_FAT16) then

    Result := fat16.FileSize(ADosyaKimlik)

  else if(DST = DST_FAT32) or (DST = DST_FAT32LBA) then

    Result := fat32.FileSize(ADosyaKimlik);
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

  GDosyalar.DosyaIsleminiSonlandir(ADosyaKimlik);
end;

{==============================================================================
  klasör oluþturma iþlevini gerçekleþtirir
 ==============================================================================}
function CreateDir(AKlasorAdi: string): Boolean;
var
  D: TDosya;
  DST: TSayi4;
  DosyaKimlik: TKimlik;
begin

  Result := False;

  DosyaKimlik := DosyaOrtaminiHazirla(AKlasorAdi);

  if(DosyaKimlik = HATA_KIMLIK) then Exit;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[DosyaKimlik];

  DST := D.MD.MD3.DST;

  if(DST = DST_ELR1) then

    Result := elr1.CreateDir(DosyaKimlik)

  else if(DST = DST_FAT12) then

    Result := fat12.CreateDir(DosyaKimlik)

  else if(DST = DST_FAT16) then

    Result := fat16.CreateDir(DosyaKimlik)

  else if(DST = DST_FAT32) or (DST = DST_FAT32LBA) then

    Result := fat32.CreateDir(DosyaKimlik);

  GDosyalar.DosyaIsleminiSonlandir(DosyaKimlik);
end;

{==============================================================================
  klasör silme iþlevini gerçekleþtirir
 ==============================================================================}
function RemoveDir(const AKlasorAdi: string): Boolean;
var
  D: TDosya;
  DST: TSayi4;
  DosyaKimlik: TKimlik;
begin

  Result := False;

  DosyaKimlik := DosyaOrtaminiHazirla(AKlasorAdi);

  if(DosyaKimlik = HATA_KIMLIK) then Exit;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[DosyaKimlik];

  DST := D.MD.MD3.DST;

  if(DST = DST_ELR1) then

    Result := elr1.RemoveDir(DosyaKimlik)

  else if(DST = DST_FAT12) then

    Result := fat12.RemoveDir(DosyaKimlik)

  else if(DST = DST_FAT16) then

    Result := fat16.RemoveDir(DosyaKimlik)

  else if(DST = DST_FAT32) or (DST = DST_FAT32LBA) then

    Result := fat32.RemoveDir(DosyaKimlik);

  GDosyalar.DosyaIsleminiSonlandir(DosyaKimlik);
end;

{==============================================================================
  dosya silme iþlevini gerçekleþtirir
 ==============================================================================}
function DeleteFile(const ADosyaAdi: string): Boolean;
var
  D: TDosya;
  DST: TSayi4;
  DosyaKimlik: TKimlik;
begin

  Result := False;

  DosyaKimlik := DosyaOrtaminiHazirla(ADosyaAdi);

  if(DosyaKimlik = HATA_KIMLIK) then Exit;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[DosyaKimlik];

  DST := D.MD.MD3.DST;

  if(DST = DST_ELR1) then

    Result := elr1.DeleteFile(DosyaKimlik)

  else if(DST = DST_FAT12) then

    Result := fat12.DeleteFile(DosyaKimlik)

  else if(DST = DST_FAT16) then

    Result := fat16.DeleteFile(DosyaKimlik)

  else if(DST = DST_FAT32) or (DST = DST_FAT32LBA) then

    Result := fat32.DeleteFile(DosyaKimlik);

  GDosyalar.DosyaIsleminiSonlandir(DosyaKimlik);
end;

{==============================================================================
  yeni dosya iþlemleri için kaynak ayýrýr
 ==============================================================================}
function TDosyalar.Yeni: TDosya;
var
  D: TDosya;
  i: TSayi4;
begin

  // boþ bellek bölgesi ara
  for i := 0 to USTSINIR_DOSYAISLEM - 1 do
  begin

    D := DosyaListesi[i];

    if(D = nil) then
    begin

      D := TDosya.Create;
      DosyaListesi[i] := D;

      // ilk deðer atamalarýný gerçekleþtir
      D.DosyaDurumu := ddKapali;
      D.Kimlik := i;
      D.TSI := GetMem(512);

      Inc(FDosyaIslemSayisi);

      Exit(D);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  dosya iþlemi için ayrýlan kaynaðý iptal eder.
 ==============================================================================}
procedure TDosyalar.DosyaIsleminiSonlandir(ADosyaKimlik: TKimlik);
var
  D: TDosya;
begin

  D := DosyaListesi[ADosyaKimlik];

  if not(D = nil) then
  begin

    Dec(FDosyaIslemSayisi);

    //SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'DI YokEt Kimlik: %d', [DI^.Kimlik]);

    FreeMem(D.TSI, 512);
    FreeMem(D, SizeOf(TDosya));
    DosyaListesi[ADosyaKimlik] := nil;
  end;
end;

function DosyaOrtaminiHazirla(const ADosyaAdi: string): TKimlik;
var
  D: TDosya;
  MD: PMDNesne;
  Surucu, Klasor, DosyaAdi: string;
  i: TSayi4;
begin

  // öndeðer geri dönüþ deðeri
  Result := HATA_KIMLIK;

  // dosya iþlemi için bellek bölgesi ayýr
  D := GDosyalar.Yeni;
  if(D = nil) then Exit;

  // sürücünün iþaret ettiði bellek bölgesine konumlan
  MD := MantiksalDepolama0.SurucuAl(ADosyaAdi);
  if(MD = nil) then
  begin

    GDosyalar.DosyaIsleminiSonlandir(D.Kimlik);
    Exit;
  end;

  // dosya tanýmlayýcýyý kaydet
  Result := D.Kimlik;

  //SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'DI Oluþtur Kimlik: %d', [DI^.Kimlik]);

  D.Gorev := GorevAl(-1);
  if(D = nil) then
  begin

    GDosyalar.DosyaIsleminiSonlandir(D.Kimlik);
    Exit;
  end;

  // iþlem yapýlacak sürücü
  D.MD := MD^;

  // dosya yolunu ayrýþtýr
  DosyaYolunuParcala2(ADosyaAdi, Surucu, Klasor, DosyaAdi);

  {SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Sürücü: %s', [Surucu]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Klasör: %s', [Klasor]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Dosya Adý: %s', [DosyaAdi]);}

  // klasör ve dosya adý
  D.Klasor := Klasor;
  D.DosyaAdi := DosyaAdi;

  D.BellekSHTDurum := False;
  D.Durum2 := False;

  // diðer deðerleri sýfýrla
  D.DosyaDurumu := ddKapali;

  // oluþturulacak ilk klasör için listeleme aþamasýnda kaydedilen bilgiler
  D.SilinenKumeNo := -1;
  D.SilinenZincirNo := -1;
  D.SilinenKayitSN := -1;
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

procedure IzKaydiOlustur(ADosyaAdi, AKayit: string; AYeniDosyaOlustur: Boolean = True);
var
  DosyaKimlik: TKimlik;
  DosyaAdi: string;
  HataKodu: TISayi4;
begin
  exit;
  DosyaAdi := 'disk2:\klasor\' + ADosyaAdi;

  AssignFile(DosyaKimlik, DosyaAdi);

  if(AYeniDosyaOlustur) then

    ReWrite(DosyaKimlik)
  else
  begin

    // dosya daha önce oluþturulmamýþsa ilk kez oluþtur
    Append(DosyaKimlik);
    if(IOResult <> HATA_YOK) then ReWrite(DosyaKimlik)
  end;

  HataKodu := IOResult;
  if(HataKodu = HATA_YOK) then
  begin

    Write(DosyaKimlik, AKayit);
    CloseFile(DosyaKimlik);
  end
  else
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, '%s dosyasý oluþturma / yazma hatasý. Hata Kodu: %d', [DosyaAdi, HataKodu]);
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
                        exit;
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
  s: string;
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

function TDosyalar.Al(ASiraNo: TISayi4): TDosya;
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_DOSYAISLEM) then
    Result := FDosyaIslemleri[ASiraNo]
  else Result := nil;
end;

procedure TDosyalar.Yaz(ASiraNo: TISayi4; ADosya: TDosya);
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_DOSYAISLEM) then
    FDosyaIslemleri[ASiraNo] := ADosya;
end;

// dosyayý belirtilen bellek bölgesine kopyalar
function DosyaOku(ADosyaTamYol: string; var ABellekAdresi: Isaretci): TDosyaYukleme;
var
  DosyaKimlik: TKimlik;
  Sonuc: TISayi4;
begin

  Result.Durum := HATA_YOK;

  AssignFile(DosyaKimlik, ADosyaTamYol);
  Reset(DosyaKimlik);
  Sonuc := IOResult;
  if(Sonuc = HATA_DOSYA_ISLEM_BASARILI) then
  begin

    // dosya uzunluðunu al
    Result.Uzunluk := FileSize(DosyaKimlik);

    if(ABellekAdresi = nil) then ABellekAdresi := GetMem(Result.Uzunluk);

    // dosyayý hedef adrese kopyala
    if not(ABellekAdresi = nil) then Read(DosyaKimlik, ABellekAdresi);

    // dosyayý kapat
    CloseFile(DosyaKimlik);

    if(ABellekAdresi = nil) then Result.Durum := HATA_BELLEKYOK;

  end else Result.Durum := Sonuc;
end;

end.
