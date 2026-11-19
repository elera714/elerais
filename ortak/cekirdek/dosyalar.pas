{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: dosyalar.pas
  Dosya Ýþlevi: dosya (file) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 19/11/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit dosyalar;

interface

uses paylasim, gorev, mdepolama, dosya;

const
  USTSINIR_DOSYAISLEM = 64;

type
  // dosya yükleme iþlem bilgileri
  TDosyaYukleme = record
    Durum: TISayi4;
    Uzunluk: TSayi4;
  end;

type
  TDosyalar = class
  private
    FDosyaIslemSayisi: TSayi4;
    FDosyaIslemleri: array[0..USTSINIR_DOSYAISLEM - 1] of TDosya;
    function Al(ASiraNo: TISayi4): TDosya;
    procedure Yaz(ASiraNo: TISayi4; ADosya: TDosya);
  public
    constructor Create;
    function KimlikNoAl: TISayi4;
    function Yeni(AMDNesne: TMDNesne): TDosya;
    procedure DosyaIsleminiSonlandir(ADosyaKimlik: TKimlik);
    property DosyaListesi[ASiraNo: TISayi4]: TDosya read Al write Yaz;
    property DosyaIslemSayisi: TSayi4 read FDosyaIslemSayisi;
  end;

procedure Append(ADosyaKimlik: TKimlik);
procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
procedure CloseFile(ADosyaKimlik: TKimlik);
function CreateDir(AKlasorAdi: string): Boolean;
function DeleteFile(const ADosyaAdi: string): Boolean;
function EOF(ADosyaKimlik: TKimlik): Boolean;
function FileSize(ADosyaKimlik: TKimlik): TISayi4;

function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
  var ADosyaArama: TDosyaArama): TISayi4;
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;

function IOResult: TISayi4;
procedure Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci);
function RemoveDir(const AKlasorAdi: string): Boolean;
procedure Reset(ADosyaKimlik: TKimlik);
procedure ReWrite(ADosyaKimlik: TKimlik);
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
procedure Write(ADosyaKimlik: TKimlik; ABellekAdresi: Isaretci; AUzunluk: TSayi4);
procedure WriteLn(ADosyaKimlik: TKimlik; AVeri: string);

procedure IzKaydiOlustur(ADosyaAdi, AKayit: string; AYeniDosyaOlustur: Boolean = True);
procedure DosyalariKopyala;
function DosyaKopyala(AKaynakDosya, AHedefDosya: string): TISayi4;
function DosyaOku(ADosyaTamYol: string; var ABellekAdresi: Isaretci): TDosyaYukleme;

var
  GDosyalar: TDosyalar;
  // dosya çalýþtýrma iþlevi için gerekli yapý
  DosyaCalistir: TDosyaYukleme;
  // dosya çalýþtýrma aþamasýnda oluþan hatalarý göstermek için oluþturulan program yönetimi
  DosyaUyari: TDosyaYukleme;

implementation

uses elr1, fat12, fat16, fat32, sistemmesaj;

{==============================================================================
  dosya iþlem nesnelerinin ilk yükleme iþlevlerini gerçekleþtirir
 ==============================================================================}
constructor TDosyalar.Create;
var
  i: TSayi4;
begin

  FDosyaIslemSayisi := 0;

  // dosya iþlev nesne dizisini sýfýrla
  for i := 0 to USTSINIR_DOSYAISLEM - 1 do DosyaListesi[i] := nil;
end;

function TDosyalar.Al(ASiraNo: TISayi4): TDosya;
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_DOSYAISLEM) then
    Result := FDosyaIslemleri[ASiraNo]
  else Result := nil;
end;

procedure TDosyalar.Yaz(ASiraNo: TISayi4; ADosya: TDosya);
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_DOSYAISLEM) then
    FDosyaIslemleri[ASiraNo] := ADosya;
end;

{==============================================================================
  dosya iþlemleri için kimlik numarasý oluþturur
 ==============================================================================}
function TDosyalar.KimlikNoAl: TISayi4;
var
  i: TISayi4;
begin

  Result := -1;

  for i := 0 to USTSINIR_DOSYAISLEM - 1 do
  begin

    // eðer nesne oluþturulmamýþ ise
    if(DosyaListesi[i] = nil) then Exit(i);
  end;
end;

{==============================================================================
  yeni dosya iþlemi oluþturur
 ==============================================================================}
function TDosyalar.Yeni(AMDNesne: TMDNesne): TDosya;
var
  D: TDosya;
  Kimlik: TISayi4;
  i: TSayi4;
begin

  // tüm dosya iþlem dizilerini irdele
  for i := 0 to USTSINIR_DOSYAISLEM - 1 do
  begin

    // boþ nesne mevcut mu, mevcut ise oluþtur ve nesne atamalarýný gerçekleþtir
    D := DosyaListesi[i];
    if(D = nil) then
    begin

      Kimlik := GDosyalar.KimlikNoAl;

      case AMDNesne.FDST of
        DST_ELR1    : D := TELR1.Create(Kimlik, AMDNesne);
        DST_FAT12   : D := TFAT12.Create(Kimlik, AMDNesne);
        DST_FAT16_1,
        DST_FAT16_2 : D := TFAT16.Create(Kimlik, AMDNesne);
        DST_FAT32,
        DST_FAT32LBA: D := TFAT32.Create(Kimlik, AMDNesne);
      end;

      // dosya iþlemini kullanacak görevi ata
      D.FGorev := GGorevler.GorevAl(-1);

      // nesneyi diziye kaydet
      DosyaListesi[i] := D;

      // dosya iþlem sayýsýný artýr ve nesneyi geri döndür
      Inc(FDosyaIslemSayisi);

      Exit(D);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  dosya iþlem nesnesini yok eder
 ==============================================================================}
procedure TDosyalar.DosyaIsleminiSonlandir(ADosyaKimlik: TKimlik);
var
  D: TDosya;
begin

  D := DosyaListesi[ADosyaKimlik];

  if not(D = nil) then
  begin

    D.Destroy;
    DosyaListesi[ADosyaKimlik] := nil;
    Dec(FDosyaIslemSayisi);
  end;
end;

{==============================================================================
  dosyaya veri eklemek için dosya açma iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure Append(ADosyaKimlik: TKimlik);
var
  D: TDosya;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaKimlik];
  if(D = nil) then
  begin

    D.FGorev.FDosyaSonIslemDurum := HATA_KIMLIK;
    Exit;
  end;

  // dosya açýk mý? (kapalý olmalý)
  if(D.FDosyaDurumu <> ddKapali) then
  begin

    D.FGorev.FDosyaSonIslemDurum := HATA_DOSYA_KULLANIMDA;
    Exit;
  end;

  // en son iþlem hatalý ise çýk
  if(D.FGorev.FDosyaSonIslemDurum <> HATA_YOK) then Exit;

  // iþlevi ilgili dosya sistemine yönlendir
  D.Append;
end;

{==============================================================================
  dosyalar ile ilgili iþlem yapmadan önce taným iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
var
  MD: TMDNesne;
  D: TDosya;
begin

  // dosya iþleminin yapýlacaðý sürücüyü al
  MD := GMantiksalDepolama.SurucuBul(ADosyaAdi);
  if(MD = nil) then
  begin

    GGorevler.Gorev[GGorevler.FAktifGrv].FDosyaSonIslemDurum := HATA_SURUCU_YOK;
    Exit;
  end;

  // yeni dosya nesnesi oluþtur
  D := GDosyalar.Yeni(MD);
  if(D = nil) then
  begin

    GGorevler.Gorev[GGorevler.FAktifGrv].FDosyaSonIslemDurum := HATA_NESNE_OLUSTURMA;
    Exit;
  end;

  // dosya tanýmlayýcýyý kaydet
  ADosyaKimlik := D.FKimlik;

  D.DosyaDegerleriniBelirle(ADosyaAdi);
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
  MD: TMDNesne;
  D: TDosya;
begin

  Result := False;

  // dosya iþleminin yapýlacaðý sürücüyü al
  MD := GMantiksalDepolama.SurucuBul(AKlasorAdi);
  if(MD = nil) then
  begin

    GGorevler.Gorev[GGorevler.FAktifGrv].FDosyaSonIslemDurum := HATA_SURUCU_YOK;
    Exit(False);
  end;

  // yeni dosya nesnesi oluþtur
  D := GDosyalar.Yeni(MD);
  if(D = nil) then
  begin

    GGorevler.Gorev[GGorevler.FAktifGrv].FDosyaSonIslemDurum := HATA_NESNE_OLUSTURMA;
    Exit(False);
  end;

  // klasörün deðerlerini ilgili deðiþkenlere ata
  D.DosyaDegerleriniBelirle(AKlasorAdi);

  // iþlevi ilgili dosya sistemine yönlendir
  Result := D.CreateDir;

  // iþlev sonunda oluþturulan dosya nesnesini yok et
  GDosyalar.DosyaIsleminiSonlandir(D.FKimlik);
end;

{==============================================================================
  dosya silme iþlevini gerçekleþtirir
 ==============================================================================}
function DeleteFile(const ADosyaAdi: string): Boolean;
var
  MD: TMDNesne;
  D: TDosya;
begin

  Result := False;

  // dosya iþleminin yapýlacaðý sürücüyü al
  MD := GMantiksalDepolama.SurucuBul(ADosyaAdi);
  if(MD = nil) then
  begin

    GGorevler.Gorev[GGorevler.FAktifGrv].FDosyaSonIslemDurum := HATA_SURUCU_YOK;
    Exit(False);
  end;

  // yeni dosya nesnesi oluþtur
  D := GDosyalar.Yeni(MD);
  if(D = nil) then
  begin

    GGorevler.Gorev[GGorevler.FAktifGrv].FDosyaSonIslemDurum := HATA_NESNE_OLUSTURMA;
    Exit(False);
  end;

  // klasörün deðerlerini ilgili deðiþkenlere ata
  D.DosyaDegerleriniBelirle(ADosyaAdi);

  // iþlevi ilgili dosya sistemine yönlendir
  Result := D.DeleteFile;

  // iþlev sonunda oluþturulan dosya nesnesini yok et
  GDosyalar.DosyaIsleminiSonlandir(D.FKimlik);
end;

{==============================================================================
  dosya okuma iþleminde dosyanýn sonuna gelinip gelinmediðini belirtir
 ==============================================================================}
function EOF(ADosyaKimlik: TKimlik): Boolean;
begin

  { TODO - henüz yazýlmadý }
  Result := True;
end;

{==============================================================================
  dosya uzunluðunu geri döndürür
 ==============================================================================}
{ TODO - pascal ile uyum çerçevesinde iþlev yeniden kontrol edilebilir }
function FileSize(ADosyaKimlik: TKimlik): TISayi4;
var
  D: TDosya;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaKimlik];
  if(D = nil) then
  begin

    D.FGorev.FDosyaSonIslemDurum := HATA_KIMLIK;
    Exit(HATA_KIMLIK);
  end;

  // dosya açýk mý? (açýk olmalý)
  if(D.FDosyaDurumu = ddKapali) then
  begin

    D.FGorev.FDosyaSonIslemDurum := HATA_DOSYA_ACIKDEGIL;
    Exit;
  end;

  // en son iþlem hatalý ise çýk
  if(D.FGorev.FDosyaSonIslemDurum <> HATA_YOK) then Exit(HATA_KIMLIK);

  // iþlevi ilgili dosya sistemine yönlendir
  Result := D.FileSize;
end;

{==============================================================================
  dosya arama iþlevini baþlatýr
  dönüþ deðeri:  = 0 dosya - dizin girdisi okundu,
                <> 0 dosya - dizin girdisi okunamadý, mevcut deðil, tamamlandý
 ==============================================================================}
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
  var ADosyaArama: TDosyaArama): TISayi4;
var
  MD: TMDNesne;
  DSELR: TELR1;
  DS32: TFAT32;
  DS16: TFAT16;
  DS12: TFAT12;
begin

  // AAramaSuzgec
  // örnek: disk1:\klasör1\dizin1\*.*

  // arama iþleminin yapýlacaðý sürücüyü al
  MD := GMantiksalDepolama.SurucuBul(AAramaSuzgec);
  if(MD = nil) then Exit(HATA_SURUCU_YOK);

  Result := HATA_KIMLIK;

  // sürücü tipine göre arama iþlemini baþlat
  // iþlevi ilgili dosya sistemine yönlendir
  case MD.FDST of
    DST_ELR1:
    begin

      DSELR := TELR1(GDosyalar.Yeni(MD));

      // arama kimlik deðerini iþleve aktar
      // bilgi: bu deðer, bu iþlevi ve ilgili iþlevi çaðýran harici programlar için gereklidir
      ADosyaArama.Kimlik := DSELR.FKimlik;
      Result := DSELR.FindFirst(AAramaSuzgec, ADosyaOzellik, ADosyaArama);
    end;
    DST_FAT32, DST_FAT32LBA:
    begin

      DS32 := TFAT32(GDosyalar.Yeni(MD));
      ADosyaArama.Kimlik := DS32.FKimlik;
      Result := DS32.FindFirst(AAramaSuzgec, ADosyaOzellik, ADosyaArama);
    end;
    DST_FAT16_1, DST_FAT16_2:
    begin

      DS16 := TFAT16(GDosyalar.Yeni(MD));
      ADosyaArama.Kimlik := DS16.FKimlik;
      Result := DS16.FindFirst(AAramaSuzgec, ADosyaOzellik, ADosyaArama);
    end;
    DST_FAT12:
    begin

      DS12 := TFAT12(GDosyalar.Yeni(MD));
      ADosyaArama.Kimlik := DS12.FKimlik;
      Result := DS12.FindFirst(AAramaSuzgec, ADosyaOzellik, ADosyaArama);
    end;
  end;
end;

{==============================================================================
  dosya arama iþlemine devam eder
  dönüþ deðeri:  = 0 dosya - dizin girdisi okundu,
                <> 0 dosya - dizin girdisi okunamadý, mevcut deðil, tamamlandý
 ==============================================================================}
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
var
  D: TDosya;
begin

  D := GDosyalar.DosyaListesi[ADosyaArama.Kimlik];
  if(D = nil) then Exit(HATA_ARAMA_KIMLIK);

  // iþlevi ilgili dosya sistemine yönlendir
  Result := D.FindNext(ADosyaArama);
end;

{==============================================================================
  dosya arama iþlemini sonlandýrýr
 ==============================================================================}
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
begin

  GDosyalar.DosyaIsleminiSonlandir(ADosyaArama.Kimlik);

  Result := 1;
end;

{==============================================================================
  görev içerisinde, dosya ile yapýlmýþ en son iþlemin sonucunu döndürür
 ==============================================================================}
function IOResult: TISayi4;
var
  G: TGorev;
begin

  // aktif görevi al
  G := GGorevler.GorevAl(-1);
  if(G = nil) then Exit(HATA_KIMLIK);

  // aktif görevin son dosya iþlem durumunu al
  Result := G.FDosyaSonIslemDurum;

  // son iþlem durumu geri döndürüldükten sonra deðiþkeni hata yok olarak iþaretle
  G.FDosyaSonIslemDurum := HATA_YOK;
end;

{==============================================================================
  dosya okuma iþlemini gerçekleþtirir
 ==============================================================================}
procedure Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci);
var
  D: TDosya;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaKimlik];
  if(D = nil) then
  begin

    D.FGorev.FDosyaSonIslemDurum := HATA_KIMLIK;
    Exit;
  end;

  // dosya açýk mý? (açýk olmalý)
  if(D.FDosyaDurumu = ddKapali) then
  begin

    D.FGorev.FDosyaSonIslemDurum := HATA_DOSYA_ACIKDEGIL;
    Exit;
  end;

  // en son iþlem hatalý ise çýk
  if(D.FGorev.FDosyaSonIslemDurum <> HATA_YOK) then Exit;

  // iþlevi ilgili dosya sistemine yönlendir
  D.Read(AHedefBellek);
end;

{==============================================================================
  klasör silme iþlevini gerçekleþtirir
 ==============================================================================}
function RemoveDir(const AKlasorAdi: string): Boolean;
var
  MD: TMDNesne;
  D: TDosya;
begin

  Result := False;

  // dosya iþleminin yapýlacaðý sürücüyü al
  MD := GMantiksalDepolama.SurucuBul(AKlasorAdi);
  if(MD = nil) then
  begin

    GGorevler.Gorev[GGorevler.FAktifGrv].FDosyaSonIslemDurum := HATA_SURUCU_YOK;
    Exit(False);
  end;

  // yeni dosya nesnesi oluþtur
  D := GDosyalar.Yeni(MD);
  if(D = nil) then
  begin

    GGorevler.Gorev[GGorevler.FAktifGrv].FDosyaSonIslemDurum := HATA_NESNE_OLUSTURMA;
    Exit(False);
  end;

  // klasörün deðerlerini ilgili deðiþkenlere ata
  D.DosyaDegerleriniBelirle(AKlasorAdi);

  // iþlevi ilgili dosya sistemine yönlendir
  Result := D.RemoveDir;

  // iþlev sonunda oluþturulan dosya nesnesini yok et
  GDosyalar.DosyaIsleminiSonlandir(D.FKimlik);
end;

{==============================================================================
  dosyayý okumadan önce ön hazýrlýk iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure Reset(ADosyaKimlik: TKimlik);
var
  D: TDosya;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaKimlik];
  if(D = nil) then Exit;

  // en son iþlem hatalý ise çýk
  if(D.FGorev.FDosyaSonIslemDurum <> HATA_YOK) then Exit;

  // iþlevi ilgili dosya sistemine yönlendir
  D.Reset;
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
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaKimlik];
  if(D = nil) then
  begin

    D.FGorev.FDosyaSonIslemDurum := HATA_KIMLIK;
    Exit;
  end;

  // dosya açýk mý? (kapalý olmalý)
  if(D.FDosyaDurumu <> ddKapali) then
  begin

    D.FGorev.FDosyaSonIslemDurum := HATA_DOSYA_KULLANIMDA;
    Exit;
  end;

  // en son iþlem hatalý ise çýk
  if(D.FGorev.FDosyaSonIslemDurum <> HATA_YOK) then Exit;

  // iþlevi ilgili dosya sistemine yönlendir
  D.ReWrite;
end;

{==============================================================================
  dosyaya veri yazma iþlemini gerçekleþtirir
 ==============================================================================}
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
var
  D: TDosya;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaKimlik];
  if(D = nil) then
  begin

    D.FGorev.FDosyaSonIslemDurum := HATA_KIMLIK;
    Exit;
  end;

  // dosya yazma için açýk mý?
  if not(D.FDosyaDurumu = ddYazmaIcinAcik) then
  begin

    D.FGorev.FDosyaSonIslemDurum := HATA_DOSYA_YAZILAMIYOR;
    Exit;
  end;

  // en son iþlem hatalý ise çýk
  if(D.FGorev.FDosyaSonIslemDurum <> HATA_YOK) then Exit;

  // iþlevi ilgili dosya sistemine yönlendir
  D.Write(AVeri);
end;

{==============================================================================
  dosyaya veri yazma iþlemini gerçekleþtirir
  bilgi: bu iþlev þimdilik ELR-1 dosya sistemine özeldir
 ==============================================================================}
procedure Write(ADosyaKimlik: TKimlik; ABellekAdresi: Isaretci; AUzunluk: TSayi4);
var
  D: TDosya;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaKimlik];
  if(D = nil) then Exit;

  // en son iþlem hatalý ise çýk
  if(D.FGorev.FDosyaSonIslemDurum <> HATA_YOK) then Exit;

  // iþlevi ilgili dosya sistemine yönlendir
  if(D.FMD.FDST = DST_ELR1) then

    TELR1(D).Write(ABellekAdresi, AUzunluk)

  else if(D.FMD.FDST = DST_FAT32) or (D.FMD.FDST = DST_FAT32LBA) then

    SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat32.Write iþlevi yazýlacak!', [])
    //fat32.Write(ADosyaKimlik, AVeri);

  else if(D.FMD.FDST = DST_FAT16_1) or (D.FMD.FDST = DST_FAT16_2) then

    SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat16.Write iþlevi yazýlacak!', [])
    //fat16.Write(ADosyaKimlik, AVeri)

  else if(D.FMD.FDST = DST_FAT12) then

    SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat12.Write iþlevi yazýlacak!', []);
    //fat12.Write(ADosyaKimlik, AVeri)
end;

{==============================================================================
  verinin sonuna #13#10 ekleyerek dosyaya veri yazma iþlemini gerçekleþtirir
 ==============================================================================}
procedure WriteLn(ADosyaKimlik: TKimlik; AVeri: string);
begin

  Write(ADosyaKimlik, AVeri + #13#10);
end;

{==============================================================================
  sistem için iz kaydý (log dosyasý) oluþturur
 ==============================================================================}
procedure IzKaydiOlustur(ADosyaAdi, AKayit: string; AYeniDosyaOlustur: Boolean = True);
var
  DosyaKimlik: TKimlik;
  DosyaAdi: string;
  HataKodu: TISayi4;
begin

  //DosyaAdi := 'disk2:\klasor\' + ADosyaAdi;
  DosyaAdi := 'disk2:\' + ADosyaAdi;

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

{==============================================================================
  fat32 dosya sisteminden elr dosya sistemine kopyalama iþlemi gerçekleþtirir
 ==============================================================================}
procedure DosyalariKopyala;
var
  AramaKaydi: TDosyaArama;
  DosyaSayisi: TSayi4;
  i, Sonuc: TISayi4;
begin

  DosyaSayisi := 0;

  i := FindFirst('disk1:\progrmlr\*.*', 0, AramaKaydi);
  while i = HATA_YOK do
  begin

    if not(AramaKaydi.DosyaAdi = '.') and not(AramaKaydi.DosyaAdi = '..') then
    begin

      Sonuc := DosyaKopyala('disk1:\progrmlr\' + AramaKaydi.DosyaAdi, 'disk2:\' + AramaKaydi.DosyaAdi);
      if(Sonuc <> HATA_YOK) then
      begin

        SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Dosya Adý: %s', [AramaKaydi.DosyaAdi]);
        SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Hata Kodu: %d', [Sonuc]);
        FindClose(AramaKaydi);
        Exit;
      end;

    //Inc(DosyaSayisi);
    //if(DosyaSayisi = 2) then Break;   // -1 dosya kopyalanacak
    //if(DosyaSayisi = 14) then Break;   // -1 dosya kopyalanacak
    end;

    i := FindNext(AramaKaydi);
  end;

  FindClose(AramaKaydi);
end;

{==============================================================================
  kaynak dosyayý hedef alana kopyalar
 ==============================================================================}
function DosyaKopyala(AKaynakDosya, AHedefDosya: string): TISayi4;
var
  DosyaKimlik: TKimlik;
  Bellek: Isaretci;
  U: TISayi8;
  Sonuc: TSayi2;
begin

  Result := HATA_YOK;

  AssignFile(DosyaKimlik, AKaynakDosya);
  Reset(DosyaKimlik);
  Sonuc := IOResult;
  if(Sonuc = HATA_YOK) then
  begin

    U := FileSize(DosyaKimlik);

    Bellek := GetMem(U);

    Read(DosyaKimlik, Bellek);
    CloseFile(DosyaKimlik);

    AssignFile(DosyaKimlik, AHedefDosya);
    ReWrite(DosyaKimlik);
    Sonuc := IOResult;
    if(Sonuc = HATA_YOK) then
    begin

      Write(DosyaKimlik, Bellek, U);
    end
    else
    begin

      Result := Sonuc;
      SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Hedef Dosya Hatasý: %d', [Sonuc]);
    end;

    CloseFile(DosyaKimlik);

    FreeMem(Bellek, U);

    //if(Result <> HATA_YOK) then Exit;
  end
  else
  begin

    Result := Sonuc;
    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Kaynak Dosya Hatasý: %d', [Sonuc]);
  end;
end;

{==============================================================================
  dosyayý hedef bellek bölgesine kopyalar
 ==============================================================================}
function DosyaOku(ADosyaTamYol: string; var ABellekAdresi: Isaretci): TDosyaYukleme;
var
  DosyaKimlik: TKimlik;
  Sonuc: TISayi4;
begin

  Result.Durum := HATA_YOK;

  AssignFile(DosyaKimlik, ADosyaTamYol);
  Reset(DosyaKimlik);
  Sonuc := IOResult;
  if(Sonuc = HATA_YOK) then
  begin

    // dosya uzunluðunu al
    Result.Uzunluk := FileSize(DosyaKimlik);

    if(ABellekAdresi = nil) then ABellekAdresi := GetMem(Result.Uzunluk);

    if(ABellekAdresi = nil) then
    begin

      CloseFile(DosyaKimlik);
      Result.Durum := HATA_BELLEKYOK;
      Exit;
    end;

    // dosyayý hedef adrese kopyala
    if not(ABellekAdresi = nil) then Read(DosyaKimlik, ABellekAdresi);

    Sonuc := IOResult;
    if(Sonuc <> HATA_YOK) then
    begin

      CloseFile(DosyaKimlik);
      Result.Durum := Sonuc;
      Exit;
    end;

    // dosyayý kapat
    CloseFile(DosyaKimlik);
  end
  else
  begin

    CloseFile(DosyaKimlik);
    Result.Durum := Sonuc;
  end;
end;

end.
