{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: fat12.pas
  Dosya Ýþlevi: fat12 dosya sistem yönetim iþlevlerini yönetir

  Güncelleme Tarihi: 09/10/2026

  Bilgi: TFAT12 nesne içeriðindeki iþlevler dosyalar.pas dosyasýnýn içeriðindeki
    iþlevler ile kullanýlmalýdýr

 ==============================================================================}
{$mode objfpc}
unit fat12;

interface

uses paylasim, gorev, mdepolama, dosya;

type
  TFAT12 = class(TDosya)
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

    function KokGirdisindeAra12(AAranacakDeger: string): TSayi4;
    function KokGirdisiListele12(var ADosyaArama: TDosyaArama): TSayi4;
    function DizinGirdisindeAra12(AAranacakDeger: string): TSayi4;
    function DizinGirdisiListele12(var ADosyaArama: TDosyaArama): TSayi4;

    function BirSonrakiKumeyiAl(var AKumeNo: TSayi4): Boolean;
  end;

implementation

uses sistemmesaj, islevler, donusum;

{==============================================================================
  dosya sistemi nesne ilk yükleme iþlevlerini içerir
 ==============================================================================}
constructor TFAT12.Create(AKimlik: TKimlik; AMDNesne: TMDNesne);
begin

  inherited Create(AKimlik, AMDNesne);
end;

{==============================================================================
  dosya sistemi nesne yok etme iþlevlerini içerir
 ==============================================================================}
destructor TFAT12.Destroy;
begin

  inherited Destroy;
end;

{==============================================================================
  dosyaya veri eklemek için dosya açma iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure TFAT12.Append;
begin

  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat12.Append iþlevi yazýlacak!', []);
end;

{==============================================================================
  dosya ile ilgili iþlem yapmadan önce taným iþlevlerini gerçekleþtirir
  bilgi: iþlev ana birim olan dosyalar birimi tarafýndan gerçekleþtirilmekte
 ==============================================================================}
procedure TFAT12.AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
begin
end;

{==============================================================================
  dosya üzerinde yapýlan iþlemi sonlandýrýr
 ==============================================================================}
procedure TFAT12.CloseFile;
begin
end;

{==============================================================================
  klasör oluþturma iþlevini gerçekleþtirir
 ==============================================================================}
function TFAT12.CreateDir: Boolean;
begin

  Result := False;
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat12.CreateDir iþlevi yazýlacak!', []);
end;

{==============================================================================
  dosya silme iþlevini gerçekleþtirir
 ==============================================================================}
function TFAT12.DeleteFile: Boolean;
begin

  Result := False;
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat12.DeleteFile iþlevi yazýlacak!', []);
end;

{==============================================================================
  dosya okuma iþleminde dosyanýn sonuna gelinip gelinmediðini belirtir
 ==============================================================================}
function TFAT12.EOF: Boolean;
begin

  Result := True;
end;

{==============================================================================
  dosya uzunluðunu geri döndürür
 ==============================================================================}
function TFAT12.FileSize: TSayi4;
begin

  // en son iþlem hatalý ise çýk
  if(FGorev^.DosyaSonIslemDurum <> HATA_YOK) then Exit(0);

  Result := FUzunluk;
end;

{==============================================================================
  dosya arama iþlevini baþlatýr
  dönüþ deðeri:  = 0 dosya - dizin girdisi okundu,
                <> 0 dosya - dizin girdisi okunamadý, mevcut deðil, tamamlandý
 ==============================================================================}
function TFAT12.FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
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

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'FAT12.PAS: ' + Mesajlar[HATA_DK_ADRES_YOLU].Deger, []);
    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, '->AAramaSuzgec: %s', [AAramaSuzgec]);
    Exit(HATA_DK_ADRES_YOLU);
  end;
  s := Copy(s, 2, Length(s) - 1);           // s = klasör1\*.*

  // bu aþamada s = klasör1\*.*

  FArama.FSektorKumeNo := FMD.Acilis.DizinGirisi.IlkSektor;

  // önce kök dizini ara
  FKlasorDerinlik := 0;

  // arama yolundaki tüm klasörlerin varlýðýný doðrula (dizin tablosunda ara)
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

    // her bir alt klasör aranmadan bu deðiþkenler sýfýrlanmalýdýr
    FArama.FZincirNo := 0;
    FArama.FSIKonum := 0;
    FArama.FSonrakiSIKonum := 0;

    // klasörün dizin giriþinde aranmasý
    if(Length(AranacakKlasor) > 0) then
    begin

      //SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'AranacakKlasor: ''%s''', [AranacakKlasor]);

      if(FKlasorDerinlik = 0) then
        FArama.FSektorKumeNo := KokGirdisindeAra12(AranacakKlasor)
      else FArama.FSektorKumeNo := DizinGirdisindeAra12(AranacakKlasor);

      if(FArama.FSektorKumeNo = 0) then
      begin

        SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'FAT12.PAS: (%s) dizini dosya tablosunda mevcut deðil!', [AranacakKlasor]);
        Exit(HATA_KLASOR_MEVCUTDEGIL);
      end else Inc(FKlasorDerinlik);
    end;
  until Length(AranacakKlasor) = 0;

  // belirtilen klasörün altýndaki ilk dosyayý geri döndür
  // bilgi: bu aþamada arama yolundaki tüm klasörlerin varlýðý teyit edilmiþtir
  FArama.FZincirNo := 0;
  FArama.FSIKonum := 0;
  FArama.FSonrakiSIKonum := 0;

  if(AramaSuzgeci = '*.*') then
  begin

    FAramaSuzgec := AAramaSuzgec;

    case FKlasorDerinlik of
      0: Result := KokGirdisiListele12(ADosyaArama);
      else Result := DizinGirdisiListele12(ADosyaArama);
    end;
  end;
end;

{==============================================================================
  dosya arama iþlemine devam eder
  dönüþ deðeri:  = 0 dosya - dizin girdisi okundu,
                <> 0 dosya - dizin girdisi okunamadý, mevcut deðil, tamamlandý
 ==============================================================================}
function TFAT12.FindNext(var ADosyaArama: TDosyaArama): TSayi4;
begin

  case FKlasorDerinlik of
    0: Result := KokGirdisiListele12(ADosyaArama);
    else Result := DizinGirdisiListele12(ADosyaArama);
  end;
end;

{==============================================================================
  dosya arama iþlemini sonlandýrýr
  bilgi: iþlev ana birim olan dosyalar birimi tarafýndan gerçekleþtirilmekte
 ==============================================================================}
function TFAT12.FindClose(var ADosyaArama: TDosyaArama): TSayi4;
begin

  Result := HATA_YOK;
end;

{==============================================================================
  dosya ile yapýlmýþ en son iþlemin sonucunu döndürür
  bilgi: iþlev ana birim olan dosyalar birimi tarafýndan gerçekleþtirilmekte
 ==============================================================================}
function TFAT12.IOResult: TSayi4;
begin

  Result := HATA_YOK;
end;

{==============================================================================
  dosya okuma iþlemini gerçekleþtirir
 ==============================================================================}
procedure TFAT12.Read(AHedefBellek: Isaretci);
var
  KopyalanacakVeriU,
  KBS, OkunacakVeriU,
  Sonuc, i: TSayi4;
  Bellek: Isaretci;
begin

  // en son iþlem hatalý ise çýk
  if(FGorev^.DosyaSonIslemDurum = HATA_YOK) then
  begin

    OkunacakVeriU := FUzunluk;
    if(OkunacakVeriU = 0) then Exit;

    KBS := FMD.Acilis.DosyaAyirmaTablosu.KBS;

    // okunacak sektör için bellek ayýr
    GetMem(Bellek, KBS * 512);

    repeat

      // okunacak veri miktarý
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

      // okunacak küme numarasý
      i := (FIslem.FSektorKumeNo - 2) * KBS;
      i := i + FMD.Acilis.IlkVeriSektorNo;

      Sonuc := FMD.FD.FOku(i, KBS, Bellek);
      if(Sonuc = HATA_YOK) then
      begin

        Tasi2(Bellek, AHedefBellek, KopyalanacakVeriU);

        // okunacak bilginin yerleþtirileceði bir sonraki adresi belirle
        AHedefBellek := AHedefBellek + KopyalanacakVeriU;

        if not(BirSonrakiKumeyiAl(FIslem.FSektorKumeNo)) then Exit;
      end;

    // eðer 0x0FF8..0x0FFF aralýðýndaysa bu dosyanýn en son zinciridir
    until (FIslem.FSektorKumeNo >= $0FF8) or (Sonuc <> HATA_YOK) or (OkunacakVeriU = 0);

    // kullanýlan bellekleri serbest býrak
    FreeMem(Bellek, KBS * 512);
  end;
end;

{==============================================================================
  klasör silme iþlevini gerçekleþtirir
 ==============================================================================}
function TFAT12.RemoveDir: Boolean;
begin

  Result := False;
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat12.RemoveDir iþlevi yazýlacak!', []);
end;

{==============================================================================
  dosyayý okumadan önce ön hazýrlýk iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure TFAT12.Reset;
var
  DosyaArama: TDosyaArama;
  TamAramaYolu: string;
  i: TSayi4;
begin

  // en son iþlem hatalý deðil ise
  if(FGorev^.DosyaSonIslemDurum = HATA_YOK) then
  begin

    // tam dosya arama yolunu oluþtur
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

    // dosyanýn BULUNAMAMASI durumunda hata kodu atamasýný gerçekleþtir
    FGorev^.DosyaSonIslemDurum := HATA_DOSYA_MEVCUTDEGIL;
  end;
end;

{==============================================================================
  dosya oluþturma iþlevini gerçekleþtirir
 ==============================================================================}
procedure TFAT12.ReWrite;
begin

  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat12.ReWrite iþlevi yazýlacak!', []);
end;

{==============================================================================
  dosyaya veri yazma iþlemini gerçekleþtirir
 ==============================================================================}
procedure TFAT12.Write(AVeri: string);
begin

  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat12.Write iþlevi yazýlacak!', []);
end;

{==============================================================================
  verinin sonuna #13#10 ekleyerek dosyaya veri yazma iþlemini gerçekleþtirir
 ==============================================================================}
procedure TFAT12.WriteLn(AVeri: string);
begin

  Write(AVeri + #13#10);
end;

{==============================================================================
  kök dizin giriþinde dosya / klasör arar, bulunmasý durumunda geriye
  ilgili giriþin küme numarasýný döndürür
 ==============================================================================}
function TFAT12.KokGirdisindeAra12(AAranacakDeger: string): TSayi4;
var
  DA: TDosyaArama;
  Sonuc: TSayi4;
begin

  // aramaya baþla
  repeat

    Sonuc := KokGirdisiListele12(DA);
    if(Sonuc = HATA_YOK) then
    begin

      // dosya / klasör küme baþlangýç deðerini geri döndür
      if(DA.DosyaAdi = AAranacakDeger) then Exit(DA.BaslangicKumeNo);

    end else Exit(0);

  until True = False;
end;

{==============================================================================
  kök dizin giriþinden dosya / klasör bilgilerini alýr
  dönüþ deðeri:  = 0 dosya - dizin girdisi okundu,
                <> 0 dosya - dizin girdisi okunamadý, mevcut deðil, tamamlandý
 ==============================================================================}
function TFAT12.KokGirdisiListele12(var ADosyaArama: TDosyaArama): TSayi4;
var
  DizinGirdisi: PDizinGirdisi;
  TumGirislerOkundu,
  UzunDosyaAdiBulundu: Boolean;
  DizinToplamSektor,
  Sonuc, i: TSayi4;
begin

  Result := HATA_YOK;

  ADosyaArama.DosyaAdi := '';

  // ilk deðer atamalarý
  TumGirislerOkundu := False;

  UzunDosyaAdiBulundu := False;

  DizinToplamSektor := FMD.Acilis.DizinGirisi.ToplamSektor;

  // aramaya baþla
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

    // FArama.FSIKonum deðeri her 0 olduðunda bir sonraki sektörü oku
    if(FArama.FSIKonum = 0) then
    begin

      // bir sonraki dizin giriþ sektörünü oku
      i := FArama.FSektorKumeNo + FArama.FZincirNo;
      Sonuc := FMD.FD.FOku(i, 1, FTSI);
      if(Sonuc <> HATA_YOK) then Exit(Sonuc);
    end;

    // dosya giriþ tablosuna konumlan
    DizinGirdisi := PDizinGirdisi(FTSI + FArama.FSIKonum);

    // dosya giriþinin ilk karakteri #0 ise tüm giriþler okunmuþ demektir
    if(DizinGirdisi^.DosyaAdi[0] = #00) then
    begin

      Result := HATA_DK_MEVCUTDEGIL;
      TumGirislerOkundu := True;
    end
    // silinmiþ dosya / dizin
    else if(DizinGirdisi^.DosyaAdi[0] = Chr($E5)) then
    begin

      // bir sonraki giriþle devam et
      FArama.FSonrakiSIKonum := 32;
    end
    // mantýksal depolama aygýtý etiketi (volume label)
    else if(DizinGirdisi^.Ozellikler = $08) then
    begin

      // bir sonraki giriþle devam et
      FArama.FSonrakiSIKonum := 32;
    end
    // dizin girdisi uzun ada sahip bir ad ise, uzun dosya adýný al
    else if(DizinGirdisi^.Ozellikler = $0F) then
    begin

      UzunDosyaAdiBulundu := True;
      DosyaParcalariniBirlestir(Isaretci(DizinGirdisi));
      FArama.FSonrakiSIKonum := 32;
    end
    // dizin girdisinin uzun ad haricinde olmasý durumunda
    else
    begin

      // 1. bir önceki girdi uzun dosya adý ise, ad ve diðer özellikleri geri döndür
      if(UzunDosyaAdiBulundu) then
      begin

        ADosyaArama.DosyaAdi := WideChar2String(@UzunDosyaAdi);
        ADosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
        ADosyaArama.OlusturmaSaati := FatXSaat2ELRSaat(DizinGirdisi^.OlusturmaSaati);
        ADosyaArama.OlusturmaTarihi := FatXTarih2ELRTarih(DizinGirdisi^.OlusturmaTarihi);
        ADosyaArama.SonErisimTarihi := FatXTarih2ELRTarih(DizinGirdisi^.SonErisimTarihi);
        ADosyaArama.SonDegisimSaati := FatXSaat2ELRSaat(DizinGirdisi^.SonDegisimSaati);
        ADosyaArama.SonDegisimTarihi := FatXTarih2ELRTarih(DizinGirdisi^.SonDegisimTarihi);

        // deðiþken içeriklerini sýfýrla
        UzunDosyaAdi[0] := #0;
        UzunDosyaAdi[1] := #0;
        UzunDosyaAdiBulundu := False;
      end
      else
      // 2. bir önceki girdi uzun dosya adý deðilse, 8 + 3 dosya ad + uzantý ve
      // diðer özellikleri geri döndür
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

      // dosya uzunluðu ve küme baþlangýç deðerlerini geri dönüþ deðiþkenlerine yerleþtir
      ADosyaArama.DosyaUzunlugu := DizinGirdisi^.DosyaUzunlugu;
      ADosyaArama.BaslangicKumeNo := DizinGirdisi^.BaslangicKumeNo;

      TumGirislerOkundu := True;

      Result := HATA_YOK;
    end;

  until TumGirislerOkundu;
end;

{==============================================================================
  dizin giriþinde dosya / klasör arar, bulunmasý durumunda geriye
  ilgili giriþin küme numarasýný döndürür
 ==============================================================================}
function TFAT12.DizinGirdisindeAra12(AAranacakDeger: string): TSayi4;
var
  DA: TDosyaArama;
  Sonuc: TSayi4;
begin

  // aramaya baþla
  repeat

    Sonuc := DizinGirdisiListele12(DA);
    if(Sonuc = HATA_YOK) then
    begin

      // dosya / klasör küme baþlangýç deðerini geri döndür
      if(DA.DosyaAdi = AAranacakDeger) then Exit(DA.BaslangicKumeNo);

    end else Exit(0);

  until True = False;
end;

{==============================================================================
  dizin giriþinden dosya / klasör bilgilerini alýr
  dönüþ deðeri:  = 0 dosya - dizin girdisi okundu,
                <> 0 dosya - dizin girdisi okunamadý, mevcut deðil, tamamlandý
 ==============================================================================}
function TFAT12.DizinGirdisiListele12(var ADosyaArama: TDosyaArama): TSayi4;
var
  DizinGirdisi: PDizinGirdisi;
  TumGirislerOkundu,
  UzunDosyaAdiBulundu: Boolean;
  Sonuc, i,
  KBS: TSayi4;
begin

  Result := HATA_YOK;

  ADosyaArama.DosyaAdi := '';

  // ilk deðer atamalarý
  TumGirislerOkundu := False;

  UzunDosyaAdiBulundu := False;

  KBS := FMD.Acilis.DosyaAyirmaTablosu.KBS;

  // aramaya baþla
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

    if(FArama.FSIKonum = 0) then
    begin

      // bir sonraki dizin giriþ sektörünü oku
      i := (FArama.FSektorKumeNo - 2) * FMD.Acilis.DosyaAyirmaTablosu.KBS;
      i := i + FMD.Acilis.DizinGirisi.IlkSektor + FMD.Acilis.DizinGirisi.ToplamSektor +
        FArama.FZincirNo;
      Sonuc := FMD.FD.FOku(i, 1, FTSI);
      if(Sonuc <> HATA_YOK) then Exit(Sonuc);
    end;

    // dosya giriþ tablosuna konumlan
    DizinGirdisi := PDizinGirdisi(FTSI + FArama.FSIKonum);

    // dosya giriþinin ilk karakteri #0 ise tüm giriþler okunmuþ demektir
    if(DizinGirdisi^.DosyaAdi[0] = #00) then
    begin

      // Result = 1 = dosya - dizin girdisi okunamadý, mevcut deðil, tamamlandý
      Result := HATA_DK_MEVCUTDEGIL;
      TumGirislerOkundu := True;
    end
    // silinmiþ dosya / dizin
    else if(DizinGirdisi^.DosyaAdi[0] = Chr($E5)) then
    begin

      // bir sonraki giriþle devam et
      FArama.FSonrakiSIKonum := 32;
    end
    // mantýksal depolama aygýtý etiketi (volume label)
    else if(DizinGirdisi^.Ozellikler = $08) then
    begin

      // bir sonraki giriþle devam et
      FArama.FSonrakiSIKonum := 32;
    end
    // dizin girdisi uzun ada sahip bir ad ise, uzun dosya adýný al
    else if(DizinGirdisi^.Ozellikler = $0F) then
    begin

      UzunDosyaAdiBulundu := True;
      DosyaParcalariniBirlestir(Isaretci(DizinGirdisi));
      FArama.FSonrakiSIKonum := 32;
    end
    // dizin girdisinin uzun ad haricinde olmasý durumunda
    else
    begin

      // 1. bir önceki girdi uzun dosya adý ise, ad ve diðer özellikleri geri döndür
      if(UzunDosyaAdiBulundu) then
      begin

        ADosyaArama.DosyaAdi := WideChar2String(@UzunDosyaAdi);
        ADosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
        ADosyaArama.OlusturmaSaati := FatXSaat2ELRSaat(DizinGirdisi^.OlusturmaSaati);
        ADosyaArama.OlusturmaTarihi := FatXTarih2ELRTarih(DizinGirdisi^.OlusturmaTarihi);
        ADosyaArama.SonErisimTarihi := FatXTarih2ELRTarih(DizinGirdisi^.SonErisimTarihi);
        ADosyaArama.SonDegisimSaati := FatXSaat2ELRSaat(DizinGirdisi^.SonDegisimSaati);
        ADosyaArama.SonDegisimTarihi := FatXTarih2ELRTarih(DizinGirdisi^.SonDegisimTarihi);

        // deðiþken içeriklerini sýfýrla
        UzunDosyaAdi[0] := #0;
        UzunDosyaAdi[1] := #0;
        UzunDosyaAdiBulundu := False;
      end
      else
      // 2. bir önceki girdi uzun dosya adý deðilse, 8 + 3 dosya ad + uzantý ve
      // diðer özellikleri geri döndür
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

      // dosya uzunluðu ve küme baþlangýç deðerlerini geri dönüþ deðiþkenlerine yerleþtir
      ADosyaArama.DosyaUzunlugu := DizinGirdisi^.DosyaUzunlugu;
      ADosyaArama.BaslangicKumeNo := DizinGirdisi^.BaslangicKumeNo;

      TumGirislerOkundu := True;

      Result := HATA_YOK;
    end;

  until TumGirislerOkundu;
end;

{==============================================================================
  kümeye baðlý bir sonraki kümeyi alýr
  baþarý = Result = True, hata = Result = False
 ==============================================================================}
function TFAT12.BirSonrakiKumeyiAl(var AKumeNo: TSayi4): Boolean;
var
  BellekSN,
  Sonuc: TSayi4;
  i: TSayi2;
begin

  Result := False;

  // fat'in 1. kopyasý belleðe yüklenmemiþse ilk FAT kopyasýnýn tümünü belleðe yükle
  if(FBellekSHT = nil) then
  begin

    GetMem(FBellekSHT, FMD.Acilis.DosyaAyirmaTablosu.ToplamSektor * 512);

    Sonuc := FMD.FD.FOku(FMD.Acilis.DosyaAyirmaTablosu.IlkSektor,
      FMD.Acilis.DosyaAyirmaTablosu.ToplamSektor, FBellekSHT);

    if(Sonuc <> HATA_YOK) then
    begin

      FreeMem(FBellekSHT, FMD.Acilis.DosyaAyirmaTablosu.ToplamSektor * 512);
      FBellekSHT := nil;
      Exit;
    end;

    // zincir deðerini 1.5 ile çarp ve bir sonraki zincir deðerini al
    BellekSN := (AKumeNo shr 1) + AKumeNo + TSayi4(FBellekSHT);
    i := PSayi2(BellekSN)^;

    if((AKumeNo and 1) = 1) then
      i := i shr 4
    else i := i and $FFF;

    AKumeNo := i;

    FreeMem(FBellekSHT, FMD.Acilis.DosyaAyirmaTablosu.ToplamSektor * 512);
    FBellekSHT := nil;

    Result := True;
  end;
end;

end.
