{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: fat16.pas
  Dosya İşlevi: fat16 dosya sistem yönetim işlevlerini yönetir

  Güncelleme Tarihi: 12/10/2026

  Bilgi: TFAT16 nesne içeriğindeki işlevler dosyalar.pas dosyasının içeriğindeki
    işlevler ile kullanılmalıdır

 ==============================================================================}
{$mode objfpc}
unit fat16;

interface

uses paylasim, gorev, mdepolama, dosya;

type
  TFAT16 = class(TDosya)
  public
    constructor Create(AKimlik: TKimlik; AMDNesne: TMDNesne); override;
    destructor Destroy; override;

    procedure Append; override;
    procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string); override;
    procedure CloseFile; override;
    function CreateDir: Boolean; override;
    function DeleteFile: Boolean; override;
    function EOF: Boolean; override;
    function FileSize: TSayi4; override;

    function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
      var ADosyaArama: TDosyaArama): TSayi4; override;
    function FindNext(var ADosyaArama: TDosyaArama): TSayi4; override;
    function FindClose(var ADosyaArama: TDosyaArama): TSayi4; override;

    function IOResult: TSayi4; override;
    procedure Read(AHedefBellek: Isaretci); override;
    function RemoveDir: Boolean; override;
    procedure Reset; override;
    procedure ReWrite; override;
    procedure Write(AVeri: string); override;
    procedure WriteLn(AVeri: string); override;

    function KokGirdisindeAra16(AAranacakDeger: string): TSayi4;
    function KokGirdisiListele16(var ADosyaArama: TDosyaArama): TSayi4;
    function DizinGirdisindeAra16(AAranacakDeger: string): TSayi4;
    function DizinGirdisiListele16(var ADosyaArama: TDosyaArama): TSayi4;
    function BirSonrakiKumeyiAl(var AKumeNo: TSayi4): Boolean;
  end;

implementation

uses sistemmesaj, islevler, donusum;

{==============================================================================
  dosya sistemi nesne ilk yükleme işlevlerini içerir
 ==============================================================================}
constructor TFAT16.Create(AKimlik: TKimlik; AMDNesne: TMDNesne);
begin

  inherited Create(AKimlik, AMDNesne);
end;

{==============================================================================
  dosya sistemi nesne yok etme işlevlerini içerir
 ==============================================================================}
destructor TFAT16.Destroy;
begin

  inherited Destroy;
end;

{==============================================================================
  dosyaya veri eklemek için dosya açma işlevlerini gerçekleştirir
 ==============================================================================}
procedure TFAT16.Append;
begin

  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat16.Append işlevi yazılacak!', []);
end;

{==============================================================================
  dosya ile ilgili işlem yapmadan önce tanım işlevlerini gerçekleştirir
  bilgi: işlev ana birim olan dosyalar birimi tarafından gerçekleştirilmekte
 ==============================================================================}
procedure TFAT16.AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
begin
end;

{==============================================================================
  dosya üzerinde yapılan işlemi sonlandırır
 ==============================================================================}
procedure TFAT16.CloseFile;
begin
end;

{==============================================================================
  klasör oluşturma işlevini gerçekleştirir
 ==============================================================================}
function TFAT16.CreateDir: Boolean;
begin

  Result := False;
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat16.CreateDir işlevi yazılacak!', []);
end;

{==============================================================================
  dosya silme işlevini gerçekleştirir
 ==============================================================================}
function TFAT16.DeleteFile: Boolean;
begin

  Result := False;
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat16.DeleteFile işlevi yazılacak!', []);
end;

{==============================================================================
  dosya okuma işleminde dosyanın sonuna gelinip gelinmediğini belirtir
 ==============================================================================}
function TFAT16.EOF: Boolean;
begin

  Result := True;
end;

{==============================================================================
  dosya uzunluğunu geri döndürür
 ==============================================================================}
function TFAT16.FileSize: TSayi4;
begin

  // en son işlem hatalı ise çık
  if(FGorev^.DosyaSonIslemDurum <> HATA_YOK) then Exit(0);

  Result := FUzunluk;
end;

{==============================================================================
  dosya arama işlevini başlatır
  dönüş değeri:  = 0 dosya - dizin girdisi okundu,
                <> 0 dosya - dizin girdisi okunamadı, mevcut değil, tamamlandı
 ==============================================================================}
function TFAT16.FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
 var ADosyaArama: TDosyaArama): TSayi4;
var
  AranacakKlasor, s,
  AramaSuzgeci: string;
  i: TSayi4;
begin

  Result := HATA_YOK;

  // AAramaSuzgec -> örnek: disk2:\klasör1\*.*

  s := '';
  i := Pos(':', AAramaSuzgec);
  if(i > 0) then s := Copy(AAramaSuzgec, i + 1, Length(AAramaSuzgec) - i);

  // s = \klasör1\*.*

  if not(s[1] = '\') then
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'FAT16.PAS: ' + Mesajlar[HATA_DK_ADRES_YOLU].Deger, []);
    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, '->AAramaSuzgec: %s', [AAramaSuzgec]);
    Exit(HATA_DK_ADRES_YOLU);
  end;
  s := Copy(s, 2, Length(s) - 1);           // s = klasör1\*.*

  // bu aşamada s = klasör1\*.*

  FArama.FSektorKumeNo := FMD.Acilis.DizinGirisi.IlkSektor;

  // önce kök dizini ara
  FKlasorDerinlik := 0;

  // arama yolundaki tüm klasörlerin varlığını doğrula (dizin tablosunda ara)
  repeat

    // arama süzgecinden sıradaki klasörün alınması
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

    // her bir alt klasör aranmadan bu değişkenler sıfırlanmalıdır
    FArama.FZincirNo := 0;
    FArama.FSIKonum := 0;
    FArama.FSonrakiSIKonum := 0;

    // klasörün dizin girişinde aranması
    if(Length(AranacakKlasor) > 0) then
    begin

      //SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'AranacakKlasor: ''%s''', [AranacakKlasor]);

      if(FKlasorDerinlik = 0) then
        FArama.FSektorKumeNo := KokGirdisindeAra16(AranacakKlasor)
      else FArama.FSektorKumeNo := DizinGirdisindeAra16(AranacakKlasor);

      if(FArama.FSektorKumeNo = 0) then
      begin

        SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'FAT16.PAS: (%s) dizini dosya tablosunda mevcut değil!', [AranacakKlasor]);
        Exit(HATA_KLASOR_MEVCUTDEGIL);
      end else Inc(FKlasorDerinlik);
    end;
  until Length(AranacakKlasor) = 0;

  // belirtilen klasörün altındaki ilk dosyayı geri döndür
  // bilgi: bu aşamada arama yolundaki tüm klasörlerin varlığı teyit edilmiştir
  FArama.FZincirNo := 0;
  FArama.FSIKonum := 0;
  FArama.FSonrakiSIKonum := 0;

  if(AramaSuzgeci = '*.*') then
  begin

    FAramaSuzgec := AAramaSuzgec;

    case FKlasorDerinlik of
      0: Result := KokGirdisiListele16(ADosyaArama);
      else Result := DizinGirdisiListele16(ADosyaArama);
    end;
  end;
end;

{==============================================================================
  dosya arama işlemine devam eder
  dönüş değeri:  = 0 dosya - dizin girdisi okundu,
                <> 0 dosya - dizin girdisi okunamadı, mevcut değil, tamamlandı
 ==============================================================================}
function TFAT16.FindNext(var ADosyaArama: TDosyaArama): TSayi4;
begin

  case FKlasorDerinlik of
    0: Result := KokGirdisiListele16(ADosyaArama);
    else Result := DizinGirdisiListele16(ADosyaArama);
  end;
end;

{==============================================================================
  dosya arama işlemini sonlandırır
  bilgi: işlev ana birim olan dosyalar birimi tarafından gerçekleştirilmekte
 ==============================================================================}
function TFAT16.FindClose(var ADosyaArama: TDosyaArama): TSayi4;
begin

  Result := HATA_YOK;
end;

{==============================================================================
  dosya ile yapılmış en son işlemin sonucunu döndürür
  bilgi: işlev ana birim olan dosyalar birimi tarafından gerçekleştirilmekte
 ==============================================================================}
function TFAT16.IOResult: TSayi4;
begin

  Result := HATA_YOK;
end;

{==============================================================================
  dosya okuma işlemini gerçekleştirir
 ==============================================================================}
procedure TFAT16.Read(AHedefBellek: Isaretci);
var
  KopyalanacakVeriU,
  KBS, OkunacakVeriU,
  Sonuc, i: TSayi4;
  Bellek: Isaretci;
begin

  // en son işlem hatalı değil ise
  if(FGorev^.DosyaSonIslemDurum = HATA_YOK) then
  begin

    OkunacakVeriU := FUzunluk;
    if(OkunacakVeriU = 0) then Exit;

    KBS := FMD.Acilis.DosyaAyirmaTablosu.KBS;

    // okunacak sektör için bellek ayır
    GetMem(Bellek, KBS * 512);

    repeat

      // okunacak veri miktarı
      if(OkunacakVeriU >= (KBS * 512)) then
      begin

        KopyalanacakVeriU := KBS * 512;
        OkunacakVeriU := OkunacakVeriU - KopyalanacakVeriU;
      end
      else
      begin

        KopyalanacakVeriU := OkunacakVeriU;
        OkunacakVeriU := 0;
      end;

      // okunacak küme numarası
      i := (FIslem.FSektorKumeNo - 2) * KBS;
      i := i + FMD.Acilis.IlkVeriSektorNo;

      Sonuc := FMD.FD.FOku(i, KBS, Bellek);
      if(Sonuc = HATA_YOK) then
      begin

        Tasi2(Bellek, AHedefBellek, KopyalanacakVeriU);

        // okunacak bilginin yerleştirileceği bir sonraki adresi belirle
        AHedefBellek := AHedefBellek + KopyalanacakVeriU;

        if not(BirSonrakiKumeyiAl(FIslem.FSektorKumeNo)) then Exit;
      end;

    // eğer 0xFFF8..0xFFFF aralığındaysa bu dosyanın en son zinciridir
    until (FIslem.FSektorKumeNo >= $FFF8) or (Sonuc <> HATA_YOK) or (OkunacakVeriU = 0);

    if(Sonuc <> HATA_YOK) then FGorev^.DosyaSonIslemDurum := HATA_AYGITOKUMA;

    // kullanılan bellekleri serbest bırak
    FreeMem(Bellek, KBS * 512);
  end;
end;

{==============================================================================
  klasör silme işlevini gerçekleştirir
 ==============================================================================}
function TFAT16.RemoveDir: Boolean;
begin

  Result := False;
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat16.RemoveDir işlevi yazılacak!', []);
end;

{==============================================================================
  dosyayı okumadan önce ön hazırlık işlevlerini gerçekleştirir
 ==============================================================================}
procedure TFAT16.Reset;
var
  DosyaArama: TDosyaArama;
  TamAramaYolu: string;
  i: TSayi4;
begin

  // en son işlem hatalı değil ise
  if(FGorev^.DosyaSonIslemDurum = HATA_YOK) then
  begin

    // tam dosya arama yolunu oluştur
    TamAramaYolu := FMD.FAygitAdi + ':' + FKlasor + '*.*';

    i := FindFirst(TamAramaYolu, 0, DosyaArama);
    while i = HATA_YOK do
    begin

      if(DosyaArama.DosyaAdi = FDosyaAdi) then
      begin

        FIslem.FSektorKumeNo := DosyaArama.BaslangicKumeNo;
        FUzunluk := DosyaArama.DosyaUzunlugu;

        // dosya durumunu güncelle
        FDosyaDurumu := ddOkumaIcinAcik;

        Exit;
      end;

      i := FindNext(DosyaArama);
    end;

    // dosyanın BULUNAMAMASI durumunda hata kodu atamasını gerçekleştir
    FGorev^.DosyaSonIslemDurum := HATA_DOSYA_MEVCUTDEGIL;
  end;
end;

{==============================================================================
  dosya oluşturma işlevini gerçekleştirir
 ==============================================================================}
procedure TFAT16.ReWrite;
begin

  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat16.ReWrite işlevi yazılacak!', []);
end;

{==============================================================================
  dosyaya veri yazma işlemini gerçekleştirir
 ==============================================================================}
procedure TFAT16.Write(AVeri: string);
begin

  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat16.Write işlevi yazılacak!', []);
end;

{==============================================================================
  verinin sonuna #13#10 ekleyerek dosyaya veri yazma işlemini gerçekleştirir
 ==============================================================================}
procedure TFAT16.WriteLn(AVeri: string);
begin

  Write(AVeri + #13#10);
end;

{==============================================================================
  kök dizin girişinde dosya / klasör arar, bulunması durumunda geriye
  ilgili girişin küme numarasını döndürür
 ==============================================================================}
function TFAT16.KokGirdisindeAra16(AAranacakDeger: string): TSayi4;
var
  DA: TDosyaArama;
  Sonuc: TSayi4;
begin

  // aramaya başla
  repeat

    Sonuc := KokGirdisiListele16(DA);
    if(Sonuc = HATA_YOK) then
    begin

      // dosya / klasör küme başlangıç değerini geri döndür
      if(DA.DosyaAdi = AAranacakDeger) then Exit(DA.BaslangicKumeNo);

    end else Exit(0);

  until True = False;
end;

{==============================================================================
  kök dizin girişinden dosya / klasör bilgilerini alır
  dönüş değeri:  = 0 dosya - dizin girdisi okundu,
                <> 0 dosya - dizin girdisi okunamadı, mevcut değil, tamamlandı
 ==============================================================================}
function TFAT16.KokGirdisiListele16(var ADosyaArama: TDosyaArama): TSayi4;
var
  DizinGirdisi: PDizinGirdisi;
  TumGirislerOkundu,
  UzunDosyaAdiBulundu: Boolean;
  DizinToplamSektor,
  Sonuc, i: TSayi4;
begin

  Result := HATA_YOK;

  ADosyaArama.DosyaAdi := '';

  // ilk değer atamaları
  TumGirislerOkundu := False;

  UzunDosyaAdiBulundu := False;

  DizinToplamSektor := FMD.Acilis.DizinGirisi.ToplamSektor;

  // aramaya başla
  repeat

    // bir sonraki girdiye konumlan
    Inc(FArama.FSIKonum, FArama.FSonrakiSIKonum);

    if(FArama.FSIKonum >= 512) then
    begin

      Inc(FArama.FZincirNo);
      if(FArama.FZincirNo >= DizinToplamSektor) then Exit(HATA_DK_MEVCUTDEGIL);

      FArama.FSIKonum := 0;
      FArama.FSonrakiSIKonum := 0;
    end;

    // FArama.FSIKonum değeri her 0 olduğunda zincirin belirlenen sektörünü oku
    if(FArama.FSIKonum = 0) then
    begin

      // bir sonraki dizin giriş sektörünü oku
      i := FArama.FSektorKumeNo + FArama.FZincirNo;
      Sonuc := FMD.FD.FOku(i, 1, FTSI);
      if(Sonuc <> HATA_YOK) then Exit(Sonuc);
    end;

    // dosya giriş tablosuna konumlan
    DizinGirdisi := PDizinGirdisi(FTSI + FArama.FSIKonum);

    // dosya girişinin ilk karakteri #0 ise tüm girişler okunmuş demektir
    if(DizinGirdisi^.DosyaAdi[0] = #00) then
    begin

      Result := HATA_DK_MEVCUTDEGIL;
      TumGirislerOkundu := True;
    end
    // silinmiş dosya / dizin
    else if(DizinGirdisi^.DosyaAdi[0] = Chr($E5)) then
    begin

      // bir sonraki girişle devam et
      FArama.FSonrakiSIKonum := 32;
    end
    // mantıksal depolama aygıtı etiketi (volume label)
    else if(DizinGirdisi^.Ozellikler = $08) then
    begin

      // bir sonraki girişle devam et
      FArama.FSonrakiSIKonum := 32;
    end
    // dizin girdisi uzun ada sahip bir ad ise, uzun dosya adını al
    else if(DizinGirdisi^.Ozellikler = $0F) then
    begin

      UzunDosyaAdiBulundu := True;
      DosyaParcalariniBirlestir(Isaretci(DizinGirdisi));
      FArama.FSonrakiSIKonum := 32;
    end
    // dizin girdisinin uzun ad haricinde olması durumunda
    else
    begin

      // 1. bir önceki girdi uzun dosya adı ise, ad ve diğer özellikleri geri döndür
      if(UzunDosyaAdiBulundu) then
      begin

        ADosyaArama.DosyaAdi := WideChar2String(@UzunDosyaAdi);
        ADosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
        ADosyaArama.OlusturmaSaati := FatXSaat2ELRSaat(DizinGirdisi^.OlusturmaSaati);
        ADosyaArama.OlusturmaTarihi := FatXTarih2ELRTarih(DizinGirdisi^.OlusturmaTarihi);
        ADosyaArama.SonErisimTarihi := FatXTarih2ELRTarih(DizinGirdisi^.SonErisimTarihi);
        ADosyaArama.SonDegisimSaati := FatXSaat2ELRSaat(DizinGirdisi^.SonDegisimSaati);
        ADosyaArama.SonDegisimTarihi := FatXTarih2ELRTarih(DizinGirdisi^.SonDegisimTarihi);

        // değişken içeriklerini sıfırla
        UzunDosyaAdi[0] := #0;
        UzunDosyaAdi[1] := #0;
        UzunDosyaAdiBulundu := False;
      end
      else
      // 2. bir önceki girdi uzun dosya adı değilse, 8 + 3 dosya ad + uzantı ve
      // diğer özellikleri geri döndür
      begin

        ADosyaArama.DosyaAdi := HamDosyaAdiniDosyaAdinaCevir(DizinGirdisi);
        ADosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
        ADosyaArama.OlusturmaSaati := FatXSaat2ELRSaat(DizinGirdisi^.OlusturmaSaati);
        ADosyaArama.OlusturmaTarihi := FatXTarih2ELRTarih(DizinGirdisi^.OlusturmaTarihi);
        ADosyaArama.SonErisimTarihi := FatXTarih2ELRTarih(DizinGirdisi^.SonErisimTarihi);
        ADosyaArama.SonDegisimSaati := FatXSaat2ELRSaat(DizinGirdisi^.SonDegisimSaati);
        ADosyaArama.SonDegisimTarihi := FatXTarih2ELRTarih(DizinGirdisi^.SonDegisimTarihi);
      end;
      FArama.FSonrakiSIKonum := 32;

      // dosya uzunluğu ve küme başlangıç değerlerini geri dönüş değişkenlerine yerleştir
      ADosyaArama.DosyaUzunlugu := DizinGirdisi^.DosyaUzunlugu;
      ADosyaArama.BaslangicKumeNo := DizinGirdisi^.BaslangicKumeNo;

      TumGirislerOkundu := True;

      Result := HATA_YOK;
    end;

  until TumGirislerOkundu;
end;

{==============================================================================
  dizin girişinde dosya / klasör arar, bulunması durumunda geriye
  ilgili girişin küme numarasını döndürür
 ==============================================================================}
function TFAT16.DizinGirdisindeAra16(AAranacakDeger: string): TSayi4;
var
  DA: TDosyaArama;
  Sonuc: TSayi4;
begin

  // aramaya başla
  repeat

    Sonuc := DizinGirdisiListele16(DA);
    if(Sonuc = HATA_YOK) then
    begin

      // dosya / klasör küme başlangıç değerini geri döndür
      if(DA.DosyaAdi = AAranacakDeger) then Exit(DA.BaslangicKumeNo);

    end else Exit(0);

  until True = False;
end;

{==============================================================================
  dizin girişinden dosya / klasör bilgilerini alır
  dönüş değeri:  = 0 dosya - dizin girdisi okundu,
                <> 0 dosya - dizin girdisi okunamadı, mevcut değil, tamamlandı
 ==============================================================================}
function TFAT16.DizinGirdisiListele16(var ADosyaArama: TDosyaArama): TSayi4;
var
  DizinGirdisi: PDizinGirdisi;
  TumGirislerOkundu,
  UzunDosyaAdiBulundu: Boolean;
  Sonuc, i,
  KBS: TSayi4;
begin

  Result := HATA_YOK;

  ADosyaArama.DosyaAdi := '';

  // ilk değer atamaları
  TumGirislerOkundu := False;

  UzunDosyaAdiBulundu := False;

  KBS := FMD.Acilis.DosyaAyirmaTablosu.KBS;

  // aramaya başla
  repeat

    // bir sonraki girdiye konumlan
    Inc(FArama.FSIKonum, FArama.FSonrakiSIKonum);

    if(FArama.FSIKonum >= 512) then
    begin

      FArama.FSIKonum := 0;
      FArama.FSonrakiSIKonum := 0;

      Inc(FArama.FZincirNo);
      if(FArama.FZincirNo >= KBS) then
      begin

        FArama.FZincirNo := 0;

        if not(BirSonrakiKumeyiAl(FArama.FSektorKumeNo)) then Exit(HATA_DK_MEVCUTDEGIL);
      end;
    end;

    // FArama.FSIKonum değeri her 0 olduğunda zincirin belirlenen sektörünü oku
    if(FArama.FSIKonum = 0) then
    begin

      // bir sonraki dizin giriş sektörünü oku
      i := (FArama.FSektorKumeNo - 2) * FMD.Acilis.DosyaAyirmaTablosu.KBS;
      i := i + FMD.Acilis.DizinGirisi.IlkSektor + FMD.Acilis.DizinGirisi.ToplamSektor +
        FArama.FZincirNo;
      Sonuc := FMD.FD.FOku(i, 1, FTSI);
      if(Sonuc <> HATA_YOK) then Exit(Sonuc);
    end;

    // dosya giriş tablosuna konumlan
    DizinGirdisi := PDizinGirdisi(FTSI + FArama.FSIKonum);

    // dosya girişinin ilk karakteri #0 ise tüm girişler okunmuş demektir
    if(DizinGirdisi^.DosyaAdi[0] = #00) then
    begin

      Result := HATA_DK_MEVCUTDEGIL;
      TumGirislerOkundu := True;
    end
    // silinmiş dosya / dizin
    else if(DizinGirdisi^.DosyaAdi[0] = Chr($E5)) then
    begin

      // bir sonraki girişle devam et
      FArama.FSonrakiSIKonum := 32;
    end
    // mantıksal depolama aygıtı etiketi (volume label)
    else if(DizinGirdisi^.Ozellikler = $08) then
    begin

      // bir sonraki girişle devam et
      FArama.FSonrakiSIKonum := 32;
    end
    // dizin girdisi uzun ada sahip bir ad ise, uzun dosya adını al
    else if(DizinGirdisi^.Ozellikler = $0F) then
    begin

      UzunDosyaAdiBulundu := True;
      DosyaParcalariniBirlestir(Isaretci(DizinGirdisi));
      FArama.FSonrakiSIKonum := 32;
    end
    // dizin girdisinin uzun ad haricinde olması durumunda
    else
    begin

      // 1. bir önceki girdi uzun dosya adı ise, ad ve diğer özellikleri geri döndür
      if(UzunDosyaAdiBulundu) then
      begin

        ADosyaArama.DosyaAdi := WideChar2String(@UzunDosyaAdi);
        ADosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
        ADosyaArama.OlusturmaSaati := FatXSaat2ELRSaat(DizinGirdisi^.OlusturmaSaati);
        ADosyaArama.OlusturmaTarihi := FatXTarih2ELRTarih(DizinGirdisi^.OlusturmaTarihi);
        ADosyaArama.SonErisimTarihi := FatXTarih2ELRTarih(DizinGirdisi^.SonErisimTarihi);
        ADosyaArama.SonDegisimSaati := FatXSaat2ELRSaat(DizinGirdisi^.SonDegisimSaati);
        ADosyaArama.SonDegisimTarihi := FatXTarih2ELRTarih(DizinGirdisi^.SonDegisimTarihi);

        // değişken içeriklerini sıfırla
        UzunDosyaAdi[0] := #0;
        UzunDosyaAdi[1] := #0;
        UzunDosyaAdiBulundu := False;
      end
      else
      // 2. bir önceki girdi uzun dosya adı değilse, 8 + 3 dosya ad + uzantı ve
      // diğer özellikleri geri döndür
      begin

        ADosyaArama.DosyaAdi := HamDosyaAdiniDosyaAdinaCevir(DizinGirdisi);
        ADosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
        ADosyaArama.OlusturmaSaati := FatXSaat2ELRSaat(DizinGirdisi^.OlusturmaSaati);
        ADosyaArama.OlusturmaTarihi := FatXTarih2ELRTarih(DizinGirdisi^.OlusturmaTarihi);
        ADosyaArama.SonErisimTarihi := FatXTarih2ELRTarih(DizinGirdisi^.SonErisimTarihi);
        ADosyaArama.SonDegisimSaati := FatXSaat2ELRSaat(DizinGirdisi^.SonDegisimSaati);
        ADosyaArama.SonDegisimTarihi := FatXTarih2ELRTarih(DizinGirdisi^.SonDegisimTarihi);
      end;
      FArama.FSonrakiSIKonum := 32;

      // dosya uzunluğu ve küme başlangıç değerlerini geri dönüş değişkenlerine yerleştir
      ADosyaArama.DosyaUzunlugu := DizinGirdisi^.DosyaUzunlugu;
      ADosyaArama.BaslangicKumeNo := DizinGirdisi^.BaslangicKumeNo;

      TumGirislerOkundu := True;

      Result := HATA_YOK;
    end;

  until TumGirislerOkundu;
end;

{==============================================================================
  kümeye bağlı bir sonraki kümeyi alır
  başarı = Result = True, hata = Result = False
 ==============================================================================}
function TFAT16.BirSonrakiKumeyiAl(var AKumeNo: TSayi4): Boolean;
var
  Sonuc,
  i: TSayi4;
begin

  Result := False;

  // fat'in 1. kopyasının ilgili sektörünü belleğe yükle
  if(FBellekSHT = nil) then
  begin

    GetMem(FBellekSHT, 512);

    i := (AKumeNo * 2) div 512;
    i := i + FMD.Acilis.DosyaAyirmaTablosu.IlkSektor;

    Sonuc := FMD.FD.FOku(i, 1, FBellekSHT);
    if(Sonuc <> HATA_YOK) then
    begin

      FreeMem(FBellekSHT, 512);
      FBellekSHT := nil;
      Exit;
    end;

    // zincir değerini 2 ile çarp ve bir sonraki zincir değerini al
    i := (AKumeNo * 2) mod 512;
    AKumeNo := PSayi2(FBellekSHT + i)^;

    FreeMem(FBellekSHT, 512);
    FBellekSHT := nil;

    Result := True;
  end;
end;

end.
