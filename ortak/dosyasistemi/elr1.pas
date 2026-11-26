{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: elr1.pas
  Dosya Ýþlevi: ELERA Ýþletim Sistemi'nin dosya sistemi

  Güncelleme Tarihi: 26/11/2026

  Kaynaklar: https://wiki.freepascal.org/File_Handling_In_Pascal

  Disk Kapasitesi: 320MB -> 320 * 1024 * 1024 = 335.544.320 byte
                                                335.544.320 / 512 = 655.360 = 0..655.359 sektör
                                                655.360 / 4 = 163.840 küme / zincir

  ELR-1 dosya sistem sektör daðýlýmý
    0000..0255  : 256 sektör - boþ sektör
    0256..1535  : 1280 sektör - sektör harita tablosu (fat) (1280 * 128) = 163.840 kümeyi adresleyebilir
    1536..655360: 653825 sektör - her türlü veri (dosya adlarý ve içeriði)

    Bilgi: TELR1 nesne içeriðindeki iþlevler dosyalar.pas dosyasýnýn içeriðindeki
      iþlevler ile kullanýlmalýdýr

 ==============================================================================}
{$mode objfpc}
unit elr1;

interface

uses paylasim, islevler, gorev, mdepolama, dosyalar, dosya;

const
  ELR_DG_U        = 64;       // her bir dosya / klasörün dizin girdisindeki uzunluðu
  ELR_DOSYA_U     = 38;

  // girdi tipleri
  ELR_GT_DOSYA    = 1;
  ELR_GT_KLASOR   = 2;

  // girdi özellikleri
  ELR_O_SILINMIS  = 1;
  ELR_O_NORMAL    = 2;
  ELR_O_GIZLI     = 3;

  // dosya giriþi zincir (küme) durumlarý
  ELR_ZD_SON      = TSayi4($FFFFFFFF);    // zincir sonu - baþka veri yok

type
  PDizinGirdisiELR = ^TDizinGirdisiELR;
  TDizinGirdisiELR = packed record
    DosyaAdi: array[0..ELR_DOSYA_U - 1] of Char;
    GirdiTipi: TSayi1;      // dosya / klasör vb
    Ozellikler: TSayi1;     // silinmiþ, gizli vb

    OlusturmaTarihi,
    OlusturmaSaati,
    DegisimTarihi,
    DegisimSaati,

    BaslangicKumeNo,
    DosyaUzunlugu: TSayi4;
  end;

const
  DIZIN_GIRDI_SAYISI        = TSayi4(8);
  ZINCIRDEKI_SEKTOR_SAYISI  = TSayi4(4);

  { bilgi-1: aþaðýdaki aralýklarýn sýnýrlarý, bir önceki deðerin bir sonrakine kadar olanýný içerir }
  { bilgi-2: veriler boot sektörlerden alýndýðý için sabit deðerler iptal edilmiþtir
  {SEKTORNO_BOOT             = TSayi4(0);
  SEKTORNO_SHT_BAS          = TSayi4(256);      // sektör harita tablosu (fat) baþlangýcý
  SEKTORNO_SHT_SON          = TSayi4(1535);     // sektör harita tablosu (fat) sonu
  SEKTORNO_VERI             = TSayi4(1536);     // dosya adlarý ve verilerini içerir}}

type
  TELR1 = class(TDosya)
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
    procedure Write(ABellekAdresi: Isaretci; AUzunluk: TSayi4);
    procedure WriteLn(AVeri: string); override;
    procedure Write0(ABellek: Isaretci; AUzunluk: TSayi4);

    function DizinGirisindeAraELR1(AAranacakDeger: string): TSayi4;
    function DizinGirdisiListeleELR1(var ADosyaArama: TDosyaArama): TSayi4;

    procedure DosyaAdiniKopyala(ADosyaAdi: string; AHedef: PChar);

    function BosKumeTahsisEt: TSayi4;
    function KumeSerbestBirak(AKumeNo: TSayi4): TISayi4;
    function KumeyiBirOncekiKumeyeBagla(ABirOncekiKumeNo, AKumeNo: TSayi4): TSayi4;
    function BirSonrakiKumeyiAl(var AKumeNo: TSayi4): Boolean;
    function KumeZinciriniSerbestBirak(AIlkKumeNo: TSayi4): TSayi4;

    function SistemKlasorleriniOlustur: Boolean;
    function SistemKlasorleriniSil: Boolean;
    function DosyaAdiniAl(ADizinGirdisi: PDizinGirdisiELR): string;

    procedure DiskiBicimle;
    function VeriAlaniniSil: TISayi4;
    function SHTOlustur(AIlkSektor, ASonSektor, AAyrilanSektor: TSayi4): TISayi4;
    function ToplamKullanim(var AKullanilanSektorSayisi: TSayi4): TSayi4;
  end;

implementation

uses cmos, sistemmesaj, aygit;

{==============================================================================
  dosya sistemi ilk yükleme iþlevlerini içerir
 ==============================================================================}
constructor TELR1.Create(AKimlik: TKimlik; AMDNesne: TMDNesne);
begin

  inherited Create(AKimlik, AMDNesne);
end;

{==============================================================================
  dosya sistemi nesne yok etme iþlevlerini içerir
 ==============================================================================}
destructor TELR1.Destroy;
begin

  inherited Destroy;
end;

{==============================================================================
  dosyaya veri eklemek için dosya açma iþlevini gerçekleþtirir
 ==============================================================================}
procedure TELR1.Append;
var
  AramaKaydi: TDosyaArama;
  DosyaBulundu: Boolean;
  i: TSayi4;
begin

  // ilk deðer atamalarý
  DosyaBulundu := False;

  AramaKaydi.Kimlik := FKimlik;

  i := FindFirst(FMD.FAygitAdi + ':\*.*', 0, AramaKaydi);
  while (i = HATA_YOK) do
  begin

    if(AramaKaydi.DosyaAdi = FDosyaAdi) and (AramaKaydi.Ozellikler = 0) then
    begin

      FUzunluk := AramaKaydi.DosyaUzunlugu;

      // arama kayýtlarýný islem deðikenlerine al
      FIslem.FSektorKumeNo := FArama.FSektorKumeNo;
      FIslem.FZincirNo := FArama.FZincirNo;
      FIslem.FSIKonum := FArama.FSIKonum;

      DosyaBulundu := True;
      Break;
    end;

    i := FindNext(AramaKaydi);
  end;

  // dosyanýn bulunmasý halinde dosyanýn durumunu yazma için açýk olarak iþaretle
  if(DosyaBulundu) then

    FDosyaDurumu := ddYazmaIcinAcik

  // aksi halde ilgili hata kodunu deðiþkene ata
  else FGorev.FDosyaSonIslemDurum := HATA_DOSYA_MEVCUTDEGIL;
end;

{==============================================================================
  dosya ile ilgili iþlem yapmadan önce taným iþlevlerini gerçekleþtirir
  bilgi: iþlev ana birim olan dosyalar birimi tarafýndan gerçekleþtirilmekte
 ==============================================================================}
procedure TELR1.AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
begin
end;

{==============================================================================
  dosya üzerinde yapýlan iþlemi sonlandýrýr
  bilgi: iþlev ana birim olan dosyalar birimi tarafýndan gerçekleþtirilmekte
 ==============================================================================}
procedure TELR1.CloseFile;
begin
end;

{==============================================================================
  klasör oluþturma iþlevini gerçekleþtirir
 ==============================================================================}
function TELR1.CreateDir: Boolean;
var
  DG: PDizinGirdisiELR;
  AramaKaydi: TDosyaArama;
  BosKume, Sonuc, KBS,
  SektorNo, i: TSayi4;
  Gun, Ay, Yil, HG: TSayi2;
  Saat, Dakika, Saniye: TSayi1;
begin

  // ilk deðer atamalarý
  Result := False;

  AramaKaydi.Kimlik := FKimlik;

  i := FindFirst(FMD.FAygitAdi + ':\*.*', 0, AramaKaydi);
  while (i = HATA_YOK) do
  begin

    if(AramaKaydi.DosyaAdi = FDosyaAdi) and (AramaKaydi.Ozellikler = $10) then
    begin

      FGorev.FDosyaSonIslemDurum := HATA_KLASORZATENMEVCUT;
      Exit;
    end;

    i := FindNext(AramaKaydi);
  end;

  KBS := FMD.Acilis.DosyaAyirmaTablosu.KBS;

  // silinen kayýt varsa silinen kaydýn yerine yeni klasör kaydý oluþtur
  // aksi durumda bulunan boþ alana yeni klasör kaydý oluþtur
  // bilgi: bulunan boþ alan, arama aþamasýnda FIslem. alanýna atanan deðerlerdir
  if(FSilinen.FSektorKumeNo <> $FFFFFFFF) then
  begin

    FIslem.FSektorKumeNo := FSilinen.FSektorKumeNo;
    FIslem.FZincirNo := FSilinen.FZincirNo;
    FIslem.FSIKonum := FSilinen.FSIKonum;
  end;

  SektorNo := (FIslem.FSektorKumeNo * KBS) + FIslem.FZincirNo;

  // dizin giriþ sektörünü oku
  Sonuc := FMD.FD.FOku(SektorNo, 1, FTSI);
  if(Sonuc > HATA_YOK) then
  begin

    FGorev.FDosyaSonIslemDurum := Sonuc;
    Exit;
  end;

  // dizin giriþ tablosuna konumlan
  DG := PDizinGirdisiELR(FTSI + FIslem.FSIKonum);

  if(FIslem.FSIKonum < 512) then
  begin

    BosKume := BosKumeTahsisEt;
    if(BosKume = $FFFFFFFF) then
    begin

      FGorev.FDosyaSonIslemDurum := HATA_TUMSEKTORLERDOLU;
      Exit;
    end;
    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Küme1: %d', [BosKume]);

    // aktif tarih / saat bilgilerini al
    TarihAl(Gun, Ay, Yil, HG);
    SaatAl(Saat, Dakika, Saniye);

    // dosya adýný hedef bölgeye kopyala
    DosyaAdiniKopyala(FDosyaAdi, PChar(DG));

    DG^.GirdiTipi := ELR_GT_KLASOR;
    DG^.Ozellikler := ELR_O_NORMAL;
    DG^.OlusturmaTarihi := ELRTarih(Gun, Ay, Yil);
    DG^.OlusturmaSaati := ELRSaat(Saat, Dakika, Saniye);
    DG^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
    DG^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);
    DG^.BaslangicKumeNo := BosKume;
    DG^.DosyaUzunlugu := 0;

    SektorNo := (FIslem.FSektorKumeNo * KBS) + FIslem.FZincirNo;

    // aktif dizin giriþinin bulunduðu sektörü güncelle (üzerine yaz)
    Sonuc := FMD.FD.FYaz(SektorNo, 1, FTSI);
    if(Sonuc > HATA_YOK) then
    begin

      FGorev.FDosyaSonIslemDurum := Sonuc;
      Exit;
    end;

    Result := True;
  end;
end;

{==============================================================================
  dosya silme iþlevini gerçekleþtirir
 ==============================================================================}
function TELR1.DeleteFile: Boolean;
var
  DG: PDizinGirdisiELR;
  AramaKaydi: TDosyaArama;
  SektorNo, Sonuc,
  KBS, i: TSayi4;
begin

  // ilk deðer atamalarý
  Result := False;

  AramaKaydi.Kimlik := FKimlik;

  i := FindFirst(FMD.FAygitAdi + ':\*.*', 0, AramaKaydi);
  while (i = HATA_YOK) do
  begin

    // dosya bulundu
    if(AramaKaydi.DosyaAdi = FDosyaAdi) and (AramaKaydi.Ozellikler = 0) then
    begin

      // bulunan kaydýn arama deðerlerini iþlem deðiþkenlerine aktar
      FIslem.FSektorKumeNo := FArama.FSektorKumeNo;
      FIslem.FZincirNo := FArama.FZincirNo;
      FIslem.FSIKonum := FArama.FSIKonum;

      // dizin giriþ tablosuna konumlan
      DG := PDizinGirdisiELR(FTSI + FIslem.FSIKonum);

      // dosyaya ait tüm küme tahsislerini serbest býrak
      Sonuc := KumeZinciriniSerbestBirak(DG^.BaslangicKumeNo);
      if(Sonuc = $FFFFFFFF) then
      begin

        SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'ELR1.DeleteFile->Hata Kodu1: %d', [Sonuc]);
        FGorev.FDosyaSonIslemDurum := HATA_AYGITAYAZMA;
        Exit;
      end;

      // dosyayý silindi olarak iþaretle
      DG^.Ozellikler := ELR_O_SILINMIS;

      KBS := FMD.Acilis.DosyaAyirmaTablosu.KBS;

      SektorNo := (FIslem.FSektorKumeNo * KBS) + FIslem.FZincirNo;

      // dosya giriþinin bulunduðu sektörü güncelle (üzerine yaz)
      Sonuc := FMD.FD.FYaz(SektorNo, 1, FTSI);
      if(Sonuc > HATA_YOK) then
      begin

        SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'ELR1.DeleteFile->Hata Kodu2: %d', [Sonuc]);
        FGorev.FDosyaSonIslemDurum := HATA_AYGITAYAZMA;
        Exit;
      end;

      Exit(True);
    end;

    i := FindNext(AramaKaydi);
  end;
end;

{==============================================================================
  dosya okuma iþleminde dosyanýn sonuna gelinip gelinmediðini belirtir
 ==============================================================================}
function TELR1.EOF: Boolean;
begin

  Result := True;
end;

{==============================================================================
  dosya uzunluðunu geri döndürür
 ==============================================================================}
function TELR1.FileSize: TSayi4;
begin

  // en son iþlem hatalý ise çýk
  if(FGorev.FDosyaSonIslemDurum <> HATA_YOK) then Exit(0);

  Result := FUzunluk;
end;

{==============================================================================
  dosya arama iþlevini baþlatýr
  dönüþ deðeri:  = 0 dosya - dizin girdisi okundu,
                <> 0 dosya - dizin girdisi okunamadý, mevcut deðil, tamamlandý
 ==============================================================================}
function TELR1.FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
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

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'ELR1.PAS: ' + Mesajlar[HATA_DK_ADRES_YOLU].Deger, []);
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

      FArama.FSektorKumeNo := DizinGirisindeAraELR1(AranacakKlasor);

      if(FArama.FSektorKumeNo = 0) then
      begin

        SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'DOSYA.PAS: %s dizini dosya tablosunda mevcut deðil!', [AranacakKlasor]);
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
    Result := DizinGirdisiListeleELR1(ADosyaArama);
  end;
end;

{==============================================================================
  dosya arama iþlemine devam eder
  dönüþ deðeri:  = 0 dosya - dizin girdisi okundu,
                <> 0 dosya - dizin girdisi okunamadý, mevcut deðil, tamamlandý
 ==============================================================================}
function TELR1.FindNext(var ADosyaArama: TDosyaArama): TSayi4;
begin

  Result := DizinGirdisiListeleELR1(ADosyaArama);
end;

{==============================================================================
  dosya arama iþlemini sonlandýrýr
  bilgi: iþlev ana birim olan dosyalar birimi tarafýndan gerçekleþtirilmekte
 ==============================================================================}
function TELR1.FindClose(var ADosyaArama: TDosyaArama): TSayi4;
begin

  Result := HATA_YOK;
end;

{==============================================================================
  dosya ile yapýlmýþ en son iþlemin sonucunu döndürür
  bilgi: iþlev ana birim olan dosyalar birimi tarafýndan gerçekleþtirilmekte
 ==============================================================================}
function TELR1.IOResult: TSayi4;
begin

  Result := HATA_YOK;
end;

{==============================================================================
  dosya okuma iþlemini gerçekleþtirir
==============================================================================}
procedure TELR1.Read(AHedefBellek: Isaretci);
var
  Bellek: Isaretci;
  KopyalanacakVeriU,
  KBS, OkunacakVeriU,
  Sonuc, i: TSayi4;
begin

  // en son iþlem hatalý deðil ise
  if(FGorev.FDosyaSonIslemDurum = HATA_YOK) then
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

      // sektörü belleðe oku
      Sonuc := FMD.FD.FOku(FIslem.FSektorKumeNo * KBS, KBS, Bellek);
      if(Sonuc > HATA_YOK) then
      begin

        FGorev.FDosyaSonIslemDurum := Sonuc;
        FreeMem(Bellek, KBS * 512);
        Exit;
      end;

      Move(Bellek^, AHedefBellek^, KopyalanacakVeriU);
      AHedefBellek := AHedefBellek + KopyalanacakVeriU;

      if(OkunacakVeriU > 0) then
      begin

        i := FIslem.FSektorKumeNo;
        if not(BirSonrakiKumeyiAl(i)) then
        begin

          SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'ELR1.Read: bir sonraki küme alýnamýyor!', []);
          FGorev.FDosyaSonIslemDurum := HATA_AYGITSEKTOROKUMA;
          Exit;
        end;

        FIslem.FSektorKumeNo := i;
      end;

    // küme deðerinin 0xFFFFFFFF olmasý durumunda tüm veri okunmuþ demektir
    until (FIslem.FSektorKumeNo = ELR_ZD_SON) or (OkunacakVeriU = 0);

    FreeMem(Bellek, KBS * 512);
  end;
end;

{==============================================================================
  klasör silme iþlevini gerçekleþtirir
 ==============================================================================}
function TELR1.RemoveDir: Boolean;
var
  DG: PDizinGirdisiELR;
  AramaKaydi: TDosyaArama;
  Sonuc, i, KBS: TSayi4;
  SektorNo: TISayi4;
begin

  // ilk deðer atamalarý
  Result := False;

  AramaKaydi.Kimlik := FKimlik;

  i := FindFirst(FMD.FAygitAdi + ':\*.*', 0, AramaKaydi);
  while (i = HATA_YOK) do
  begin

    if(AramaKaydi.DosyaAdi = FDosyaAdi) and (AramaKaydi.Ozellikler = $10) then
    begin

      // bulunan kaydýn arama deðerlerini iþlem deðiþkenlerine aktar
      FIslem.FSektorKumeNo := FArama.FSektorKumeNo;
      FIslem.FZincirNo := FArama.FZincirNo;
      FIslem.FSIKonum := FArama.FSIKonum;

      // dizin giriþ tablosuna konumlan
      DG := PDizinGirdisiELR(FTSI + FIslem.FSIKonum);

      // klasörü silindi olarak iþaretle
      DG^.Ozellikler := ELR_O_SILINMIS;

      // klasöre tahsis edilen kümeyi serbest býrak
      { TODO - þu aþamada tek bir küme yok edilmektedir, tüm zincirler yok edilecek }
      SektorNo := KumeSerbestBirak(DG^.BaslangicKumeNo);
      if(SektorNo < HATA_YOK) then
      begin

        FGorev.FDosyaSonIslemDurum := SektorNo;
        Exit;
      end;

      KBS := FMD.Acilis.DosyaAyirmaTablosu.KBS;

      SektorNo := (FIslem.FSektorKumeNo * KBS) + FIslem.FZincirNo;

      // aktif dizin giriþinin bulunduðu sektörü güncelle (üzerine yaz)
      Sonuc := FMD.FD.FYaz(SektorNo, 1, FTSI);
      if(Sonuc > HATA_YOK) then
      begin

        FGorev.FDosyaSonIslemDurum := Sonuc;
        Exit;
      end;

      Exit(True);
    end;

    i := FindNext(AramaKaydi);
  end;

  FGorev.FDosyaSonIslemDurum := HATA_KLASOR_MEVCUTDEGIL;

  Result := False;
end;

{==============================================================================
  dosyayý okumadan önce ön hazýrlýk iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure TELR1.Reset;
var
  DosyaArama: TDosyaArama;
  TamAramaYolu: string;
  i: TISayi4;
begin

  // en son iþlem hatalý deðil ise
  if(FGorev.FDosyaSonIslemDurum = HATA_YOK) then
  begin

    // tam dosya arama yolunu oluþtur
    TamAramaYolu := FMD.FAygitAdi + ':' + FKlasor + '*.*';

    i := FindFirst(TamAramaYolu, 0, DosyaArama);
    while (i = HATA_YOK) do
    begin

      if(DosyaArama.DosyaAdi = FDosyaAdi) and (DosyaArama.Ozellikler = 0) then
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
    FGorev.FDosyaSonIslemDurum := HATA_DOSYA_MEVCUTDEGIL;
  end;
end;

{==============================================================================
  dosya oluþturma iþlevini gerçekleþtirir
 ==============================================================================}
procedure TELR1.ReWrite;
var
  DG: PDizinGirdisiELR;
  AramaKaydi: TDosyaArama;
  Sonuc, SektorNo,
  KBS: TSayi4;
  i: TISayi4;
  Gun, Ay, Yil, HG: TSayi2;
  Saat, Dakika, Saniye: TSayi1;
  DosyaBulundu: Boolean;
begin

  // ilk deðer atamalarý
  DosyaBulundu := False;

  AramaKaydi.Kimlik := FKimlik;

  i := FindFirst(FMD.FAygitAdi + ':\*.*', 0, AramaKaydi);
  while (i = HATA_YOK) do
  begin

    if(AramaKaydi.DosyaAdi = FDosyaAdi) and (AramaKaydi.Ozellikler = 0) then
    begin

      FUzunluk := AramaKaydi.DosyaUzunlugu;

      // arama kayýtlarýný islem deðikenlerine al
      FIslem.FSektorKumeNo := FArama.FSektorKumeNo;
      FIslem.FZincirNo := FArama.FZincirNo;
      FIslem.FSIKonum := FArama.FSIKonum;

      DosyaBulundu := True;
      Break;
    end;

    i := FindNext(AramaKaydi);
  end;

  KBS := FMD.Acilis.DosyaAyirmaTablosu.KBS;

  SektorNo := (FIslem.FSektorKumeNo * KBS) + FIslem.FZincirNo;

  // kayýt alanýna konumlan
  DG := PDizinGirdisiELR(FTSI + FIslem.FSIKonum);

  // dosya oluþturma iþlemi

  // 1. dosyanýn mevcut olmasý durumunda
  if(DosyaBulundu) then
  begin

    // dosyaya tahsis edilmiþ küme varsa tüm kümeleri serbest býrak
    if not(DG^.BaslangicKumeNo = ELR_ZD_SON) then
    begin

      Sonuc := KumeZinciriniSerbestBirak(DG^.BaslangicKumeNo);
      if(Sonuc = $FFFFFFFF) then
      begin

        SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'ELR1.SHTKumeZinciriniSerbestBirak->Hata Kodu: %d', [Sonuc]);
        Exit;
      end;
    end;

    // aktif tarih / saat bilgilerini al
    TarihAl(Gun, Ay, Yil, HG);
    SaatAl(Saat, Dakika, Saniye);

    // güncel veriler aktif dizin / dosya giriþine aktarýlýyor
    DG^.GirdiTipi := ELR_GT_DOSYA;
    DG^.Ozellikler := ELR_O_NORMAL;
    DG^.OlusturmaTarihi := ELRTarih(Gun, Ay, Yil);
    DG^.OlusturmaSaati := ELRSaat(Saat, Dakika, Saniye);
    DG^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
    DG^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);
    DG^.BaslangicKumeNo := ELR_ZD_SON;
    DG^.DosyaUzunlugu := 0;

    // aktif dizin giriþinin bulunduðu sektörü güncelle (üzerine yaz)
    Sonuc := FMD.FD.FYaz(SektorNo, 1, FTSI);
    if(Sonuc > HATA_YOK) then
    begin

      SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'ELR1.ReWrite->Hata Kodu: %d', [Sonuc]);
      Exit;
    end;

    // dosya durumunu, "dosya yazým için açýldý" olarak güncelle
    FDosyaDurumu := ddYazmaIcinAcik;
  end
  else
  // 2. dosyanýn mevcut OLMAMASI durumunda
  begin

    if(FIslem.FSIKonum < 512) then
    begin

      // dosya adýný hedef bölgeye kopyala
      DosyaAdiniKopyala(FDosyaAdi, PChar(DG));

      // aktif tarih / saat bilgilerini al
      TarihAl(Gun, Ay, Yil, HG);
      SaatAl(Saat, Dakika, Saniye);

      // güncel veriler aktif dizin / dosya giriþine aktarýlýyor
      DG^.GirdiTipi := ELR_GT_DOSYA;
      DG^.Ozellikler := ELR_O_NORMAL;
      DG^.OlusturmaTarihi := ELRTarih(Gun, Ay, Yil);
      DG^.OlusturmaSaati := ELRSaat(Saat, Dakika, Saniye);
      DG^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
      DG^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);
      DG^.BaslangicKumeNo := ELR_ZD_SON;
      DG^.DosyaUzunlugu := 0;

      // aktif dizin giriþinin bulunduðu sektörü güncelle (üzerine yaz)
      Sonuc := FMD.FD.FYaz(SektorNo, 1, FTSI);
      if(Sonuc > HATA_YOK) then
      begin

        SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'ELR1.ReWrite->Hata Kodu: %d', [Sonuc]);
        Exit;
      end;

      // dosya durumunu, "dosya yazým için açýldý" olarak güncelle
      FDosyaDurumu := ddYazmaIcinAcik;
    end;
  end;
end;

{==============================================================================
  dosyaya veri yazma iþlemini gerçekleþtirir
 ==============================================================================}
procedure TELR1.Write(AVeri: string);
var
  VeriU: TSayi4;
begin

  VeriU := Length(AVeri);
  Write0(@AVeri[1], VeriU);
end;

{==============================================================================
  dosyaya veri yazma iþlemini gerçekleþtirir
 ==============================================================================}
procedure TELR1.Write(ABellekAdresi: Isaretci; AUzunluk: TSayi4);
begin

  Write0(ABellekAdresi, AUzunluk);
end;

{==============================================================================
  verinin sonuna #13#10 ekleyerek dosyaya veri yazma iþlemini gerçekleþtirir
 ==============================================================================}
procedure TELR1.WriteLn(AVeri: string);
begin

  Write(AVeri + #13#10);
end;

{==============================================================================
  dosyaya veri yazma iþlemini gerçekleþtirir
  uyarý: iþlev SADECE elr1.pas.Write iþlevi tarafýndan çaðrýlmalýdýr!
 ==============================================================================}
procedure TELR1.Write0(ABellek: Isaretci; AUzunluk: TSayi4);
var
  DG: PDizinGirdisiELR;
  Bellek: Isaretci;
  YazilacakKumeNo, YeniKumeNo,
  OkumaKonum, YazilacakVeriU,
  Sonuc, SektorNo, i, j,
  SektorVeriU, KBS: TSayi4;
  Gun, Ay, Yil, HG: TSayi2;
  Saat, Dakika, Saniye: TSayi1;
begin

  DG := PDizinGirdisiELR(FTSI + FIslem.FSIKonum);

  KBS := FMD.Acilis.DosyaAyirmaTablosu.KBS;

  // dosyanýn baþlangýç küme numarasýný var mý?
  // olmamasý durumunda yeni bir tane oluþtur
  if(DG^.BaslangicKumeNo = ELR_ZD_SON) then
  begin

    YazilacakKumeNo := BosKumeTahsisEt;
    if(YazilacakKumeNo = $FFFFFFFF) then
    begin

      SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ELR1.BosKumeTahsisEt.Hata: %d', [YazilacakKumeNo]);
      FGorev.FDosyaSonIslemDurum := HATA_TUMSEKTORLERDOLU;
      Exit;
    end;

    // baþlangýç küme numarasýný kaydet
    DG^.BaslangicKumeNo := YazilacakKumeNo;

  end else YazilacakKumeNo := DG^.BaslangicKumeNo;

  // dosyaya yazýlacak veri uzunluðu
  YazilacakVeriU := AUzunluk;

  // yazýlacak küme boyutu kadar bellekte yer ayýr
  GetMem(Bellek, 512 * KBS);
  FillByte(Bellek^, 512 * KBS, 0);

  // okunarak dosyaya yazýlacak verinin pozisyonu
  OkumaKonum := 0;

  // dosya verisi tek bir kümeden fazla ise en son kümeye konumlan
  j := (512 * KBS);
  if(DG^.DosyaUzunlugu > j) then
  begin

    // toplam küme sayýsý - 1
    j := (DG^.DosyaUzunlugu div (512 * KBS));

    for i := 1 to j do
    begin

      if not(BirSonrakiKumeyiAl(YazilacakKumeNo)) then
      begin

        SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'ELR1.BirSonrakiKumeyiAl hatasý', []);
        FGorev.FDosyaSonIslemDurum := HATA_AYGITOKUMA;
        FreeMem(Bellek, 512 * KBS);
        Exit;
      end;
    end;
  end;

  // öncelikle (varsa) yarým kalan kümeye veri yaz
  SektorVeriU := (DG^.DosyaUzunlugu mod (512 * KBS));
  if(SektorVeriU > 0) then
  begin

    FillChar(Bellek^, (512 * KBS), 0);
    if(FMD.FD.FOku(YazilacakKumeNo * KBS, KBS, Bellek) = HATA_YOK) then
    begin

      j := (512 * KBS) - SektorVeriU;
      if(j > YazilacakVeriU) then j := YazilacakVeriU;
      Tasi2(ABellek + OkumaKonum, Bellek + SektorVeriU, j);
      Sonuc := FMD.FD.FYaz(YazilacakKumeNo * KBS, KBS, Bellek);
      if(Sonuc > HATA_YOK) then
      begin

        SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ELR1.Yazma.Hatasý1: %d', [Sonuc]);
        FGorev.FDosyaSonIslemDurum := HATA_AYGITAYAZMA;
        FreeMem(Bellek, 512 * KBS);
        Exit;
      end;

      // sayaçlarý güncelle
      OkumaKonum := OkumaKonum + j;
      YazilacakVeriU := YazilacakVeriU - j;
      DG^.DosyaUzunlugu := DG^.DosyaUzunlugu + j;
    end;
  end;

  // bu aþamada kümenin yarý dolu olmasý mevzu bahis deðildir (tam doludur)
  // kümeler baþtan sona doðru yazýlacaktýr
  repeat

    if(YazilacakVeriU > 0) then
    begin

      FillChar(Bellek^, (512 * KBS), 0);

      // hedef bölgeye kaç byte kopyalanacak
      j := (512 * KBS);
      if(j > YazilacakVeriU) then j := YazilacakVeriU;
      Tasi2(ABellek + OkumaKonum, Bellek, j);
      Sonuc := FMD.FD.FYaz(YazilacakKumeNo * KBS, KBS, Bellek);
      if(Sonuc > HATA_YOK) then
      begin

        SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ELR1.Yazma.Hatasý2: %d', [Sonuc]);
        FGorev.FDosyaSonIslemDurum := HATA_AYGITAYAZMA;
        FreeMem(Bellek, 512 * KBS);
        Exit;
      end;

      // sayaçlarý güncelle
      OkumaKonum := OkumaKonum + j;
      YazilacakVeriU := YazilacakVeriU - j;
      DG^.DosyaUzunlugu := DG^.DosyaUzunlugu + j;

      // yazýlacak veri kaldýysa yeni bir küme oluþtur
      if(YazilacakVeriU > 0) then
      begin

        YeniKumeNo := BosKumeTahsisEt;
        if(YeniKumeNo = $FFFFFFFF) then
        begin

          SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ELR1.BosKumeTahsisEt.HataKodu: %d', [YeniKumeNo]);
          FGorev.FDosyaSonIslemDurum := HATA_TUMSEKTORLERDOLU;
          FreeMem(Bellek, 512 * KBS);
          Exit;
        end;

        // oluþturulan kümeyi bir önceki kümeye baðla
        Sonuc := KumeyiBirOncekiKumeyeBagla(YazilacakKumeNo, YeniKumeNo);
        if(Sonuc = $FFFFFFFF) then
        begin

          SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ELR1.KumeyiBirOncekiKumeyeBagla.HataKodu: %d', [Sonuc]);
          FGorev.FDosyaSonIslemDurum := HATA_TUMSEKTORLERDOLU;
          FreeMem(Bellek, 512 * KBS);
          Exit;
        end;

        YazilacakKumeNo := YeniKumeNo;
      end;
    end;

  until YazilacakVeriU = 0;

  // kullanýlan belleði serbest býrak
  FreeMem(Bellek, 512 * KBS);

  // aktif tarih / saat bilgilerini al
  TarihAl(Gun, Ay, Yil, HG);
  SaatAl(Saat, Dakika, Saniye);

  DG^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
  DG^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);

  // dosyanýn güncel deðerlerini ilgili sektöre yaz
  SektorNo := (FIslem.FSektorKumeNo * KBS) + FIslem.FZincirNo;

  Sonuc := FMD.FD.FYaz(SektorNo, 1, FTSI);
  if(Sonuc > HATA_YOK) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ELR1.Yazma.Hatasý3: %d', [Sonuc]);
    FGorev.FDosyaSonIslemDurum := HATA_AYGITAYAZMA;
  end;
end;

{==============================================================================
  dizin giriþinde dosya / klasör arar, bulunmasý durumunda geriye
  ilgili giriþin küme numarasýný döndürür
 ==============================================================================}
function TELR1.DizinGirisindeAraELR1(AAranacakDeger: string): TSayi4;
var
  DA: TDosyaArama;
  Sonuc: TSayi4;
begin

  // aramaya baþla
  repeat

    Sonuc := DizinGirdisiListeleELR1(DA);
    if(Sonuc = HATA_YOK) then
    begin

      // dosya / klasör bulunduysa küme baþlangýç deðerini geri döndür
      if(DA.DosyaAdi = AAranacakDeger) then Exit(DA.BaslangicKumeNo);

    end else Exit(0);

  until True = False;
end;

{==============================================================================
  dizin giriþinden ilgili bilgileri alýr
 ==============================================================================}
function TELR1.DizinGirdisiListeleELR1(var ADosyaArama: TDosyaArama): TSayi4;
var
  DG: PDizinGirdisiELR;
  TumGirislerOkundu: Boolean;
  Sonuc, i, KBS: TSayi4;
begin

  Result := HATA_YOK;

  ADosyaArama.DosyaAdi := '';

  // ilk deðer atamalarý
  TumGirislerOkundu := False;

  KBS := FMD.Acilis.DosyaAyirmaTablosu.KBS;

  // aramaya baþla
  repeat

    // bir sonraki girdiye konumlan
    Inc(FArama.FSIKonum, FArama.FSonrakiSIKonum);

    if(FArama.FSIKonum >= 512) then
    begin

      // yeni sektörün okunmasý için KayitSN deðiþkenini 0 olarak ayarla
      FArama.FSIKonum := 0;
      FArama.FSonrakiSIKonum := 0;

      Inc(FArama.FZincirNo);
      if(FArama.FZincirNo >= KBS) then
      begin

        FArama.FZincirNo := 0;

        if not(BirSonrakiKumeyiAl(FArama.FSektorKumeNo)) then Exit(HATA_DK_MEVCUTDEGIL);
      end;
    end;

    // FArama.FSIKonum deðeri her 0 olduðunda zincirin belirlenen sektörünü oku
    if(FArama.FSIKonum = 0) then
    begin

      i := (FArama.FSektorKumeNo * KBS) + FArama.FZincirNo;

      Sonuc := FMD.FD.FOku(i, 1, FTSI);
      if(Sonuc > HATA_YOK) then Exit(Sonuc);
    end;

    // dosya giriþ tablosuna konumlan
    DG := PDizinGirdisiELR(FTSI + FArama.FSIKonum);

    // dosya giriþinin ilk karakteri #0 ise tüm giriþler okunmuþ demektir
    if(DG^.DosyaAdi[0] = #00) then
    begin

      // diðer iþlevlerin kullanabilmesi için deðerleri sakla
      FIslem.FSektorKumeNo := FArama.FSektorKumeNo;
      FIslem.FZincirNo := FArama.FZincirNo;
      FIslem.FSIKonum := FArama.FSIKonum;

      Result := HATA_DK_MEVCUTDEGIL;;
      TumGirislerOkundu := True;
    end
    // silinmiþ dosya / klasör
    else if(DG^.Ozellikler = ELR_O_SILINMIS) then
    begin

      // listeleme aþamasýnda silinen ilk kayýt bilgileri klasör oluþturma
      // iþlemi için kaydediliyor
      if(FSilinen.FSektorKumeNo = $FFFFFFFF) then
      begin

        FSilinen.FSektorKumeNo := FArama.FSektorKumeNo;
        FSilinen.FZincirNo := FArama.FZincirNo;
        FSilinen.FSIKonum := FArama.FSIKonum;
      end;
      FArama.FSonrakiSIKonum := 64;

      // bir sonraki giriþle devam et
    end
    else if(DG^.GirdiTipi = ELR_GT_KLASOR) or (DG^.GirdiTipi = ELR_GT_DOSYA) then
    begin

      // diðer iþlevlerin kullanabilmesi için deðerleri sakla
      //FIslem.FSektorKumeNo := FArama.FSektorKumeNo;
      //FIslem.FSIKonum := FArama.FSIKonum;

      ADosyaArama.DosyaAdi := DosyaAdiniAl(DG);
      if(DG^.GirdiTipi = ELR_GT_KLASOR) then
        ADosyaArama.Ozellikler := $10     { TODO - çekirdek ve uygulama alanýnda yapýlandýr }
      else ADosyaArama.Ozellikler := 0;
      ADosyaArama.OlusturmaTarihi := DG^.OlusturmaTarihi;
      ADosyaArama.OlusturmaSaati := DG^.OlusturmaSaati;
      ADosyaArama.SonErisimTarihi := 0;
      ADosyaArama.SonDegisimTarihi := DG^.DegisimTarihi;
      ADosyaArama.SonDegisimSaati := DG^.DegisimSaati;

      // dosya uzunluðu ve cluster baþlangýcýný geri dönüþ deðerine ekle
      ADosyaArama.DosyaUzunlugu := DG^.DosyaUzunlugu;
      ADosyaArama.BaslangicKumeNo := DG^.BaslangicKumeNo;
      FArama.FSonrakiSIKonum := 64;

      TumGirislerOkundu := True;

      Result := HATA_YOK;
    end

  until TumGirislerOkundu;
end;

{==============================================================================
  dosya adýný sektör kayýt alanýna yazar
 ==============================================================================}
procedure TELR1.DosyaAdiniKopyala(ADosyaAdi: string; AHedef: PChar);
var
  i: TSayi4;
begin

  FillChar(AHedef^, ELR_DOSYA_U, #0);

  AHedef[0] := Char(Length(ADosyaAdi));

  for i := 1 to Length(ADosyaAdi) do AHedef[i] := ADosyaAdi[i];
end;

{==============================================================================
  sektör harita tablosundan boþ küme numarasý alýr
  baþarý = Result >= 0, hata = Result = $FFFFFFFF
 ==============================================================================}
function TELR1.BosKumeTahsisEt: TSayi4;
var
  Bellek: Isaretci;
  Deger: PSayi4;
  SHTIlkSektor, SHTSonSektor,
  KumeNo, i, j, Sonuc: TSayi4;
begin

  GetMem(Bellek, 512);

  KumeNo := 0;

  SHTIlkSektor := FMD.Acilis.DosyaAyirmaTablosu.IlkSektor;
  SHTSonSektor := FMD.Acilis.DosyaAyirmaTablosu.ToplamSektor + SHTIlkSektor;

  for i := SHTIlkSektor to SHTSonSektor - 1 do
  begin

    Sonuc := FMD.FD.FOku(i, 1, Bellek);
    if(Sonuc > HATA_YOK) then
    begin

      FreeMem(Bellek, 512);
      Exit($FFFFFFFF);
    end;

    Deger := Bellek;
    for j := 0 to 128 - 1 do
    begin

      if(Deger^ = $00000000) then
      begin

        // bir sonraki sektörü sonlanmýþ olarak iþaretle
        Deger^ := ELR_ZD_SON;
        Sonuc := FMD.FD.FYaz(i, 1, Bellek);
        if(Sonuc > HATA_YOK) then
        begin

          FreeMem(Bellek, 512);
          Exit($FFFFFFFF);
        end;

        FreeMem(Bellek, 512);
        Exit(KumeNo);
      end;

      Inc(KumeNo);
      Inc(Deger);
    end;
  end;

  FreeMem(Bellek, 512);
end;

{==============================================================================
  sektör harita tablosundan alýnan sektör kümesini serbest býrakýr
  baþarý = Result >= 0, hata = Result < 0
 ==============================================================================}
function TELR1.KumeSerbestBirak(AKumeNo: TSayi4): TISayi4;
var
  Bellek: Isaretci;
  SektorNo, SiraNo,
  Sonuc, SHTIlkSektor: TSayi4;
  Deger: PSayi4;
begin

  Result := AKumeNo;

  GetMem(Bellek, 512);

  // konumlanýlacak sektör ve sýra numarasý
  SektorNo := AKumeNo div 128;
  SiraNo := AKumeNo mod 128;

  SHTIlkSektor := FMD.Acilis.DosyaAyirmaTablosu.IlkSektor;

  Sonuc := FMD.FD.FOku(SHTIlkSektor + SektorNo, 1, Bellek);
  if(Sonuc > HATA_YOK) then
  begin

    FreeMem(Bellek, 512);
    Exit(-1);
  end;

  Deger := Bellek;
  Inc(Deger, SiraNo);
  //if(Deger^ = ELR_ZD_SON) then
  begin

    Deger^ := $00000000;
    Sonuc := FMD.FD.FYaz(SHTIlkSektor + SektorNo, 1, Bellek);
    if(Sonuc > HATA_YOK) then
    begin

      FreeMem(Bellek, 512);
      Exit(-1);
    end;

    FreeMem(Bellek, 512);
    Exit;
  end;

  FreeMem(Bellek, 512);
end;

{==============================================================================
  kümeyi bir önceki kümeye baðlar
  baþarý = Result = 0, hata = Result = $FFFFFFFF
 ==============================================================================}
function TELR1.KumeyiBirOncekiKumeyeBagla(ABirOncekiKumeNo, AKumeNo: TSayi4): TSayi4;
var
  Bellek: Isaretci;
  Deger: PSayi4;
  SektorNo, SiraNo,
  Sonuc, SHTIlkSektor: TSayi4;
begin

  Result := HATA_YOK;

  GetMem(Bellek, 512);

  // konumlanýlacak sektör ve sýra numarasý
  SektorNo := ABirOncekiKumeNo div 128;
  SiraNo := ABirOncekiKumeNo mod 128;

  SHTIlkSektor := FMD.Acilis.DosyaAyirmaTablosu.IlkSektor;

  Sonuc := FMD.FD.FOku(SHTIlkSektor + SektorNo, 1, Bellek);
  if(Sonuc > HATA_YOK) then
  begin

    FreeMem(Bellek, 512);
    Exit($FFFFFFFF);
  end;

  Deger := Bellek;
  Inc(Deger, SiraNo);
  Deger^ := AKumeNo;

  Sonuc := FMD.FD.FYaz(SHTIlkSektor + SektorNo, 1, Bellek);
  if(Sonuc > HATA_YOK) then
  begin

    FreeMem(Bellek, 512);
    Exit($FFFFFFFF);
  end;

  // sonlandýrma iþareti
  // konumlanýlacak sektör ve sýra numarasý
  SektorNo := AKumeNo div 128;
  SiraNo := AKumeNo mod 128;

  Sonuc := FMD.FD.FOku(SHTIlkSektor + SektorNo, 1, Bellek);
  if(Sonuc > HATA_YOK) then
  begin

    FreeMem(Bellek, 512);
    Exit($FFFFFFFF);
  end;

  Deger := Bellek;
  Inc(Deger, SiraNo);
  Deger^ := ELR_ZD_SON;

  Sonuc := FMD.FD.FYaz(SHTIlkSektor + SektorNo, 1, Bellek);
  if(Sonuc > HATA_YOK) then
  begin

    FreeMem(Bellek, 512);
    Exit($FFFFFFFF);
  end;

  FreeMem(Bellek, 512);
end;

{==============================================================================
  kümeye baðlý bir sonraki kümeyi alýr
  baþarý = Result = True, hata = Result = False
 ==============================================================================}
function TELR1.BirSonrakiKumeyiAl(var AKumeNo: TSayi4): Boolean;
var
  Bellek: Isaretci;
  Deger: PSayi4;
  SektorNo, SiraNo,
  Sonuc, SHTIlkSektor: TSayi4;
begin

  Result := False;

  Bellek := GetMem(512);

  // konumlanýlacak sektör ve sýra numarasý
  SektorNo := AKumeNo div 128;
  SiraNo := AKumeNo mod 128;

  SHTIlkSektor := FMD.Acilis.DosyaAyirmaTablosu.IlkSektor;

  Sonuc := FMD.FD.FOku(SHTIlkSektor + SektorNo, 1, Bellek);
  if(Sonuc = HATA_YOK) then
  begin

    Deger := Bellek;
    Inc(Deger, SiraNo);
    AKumeNo := Deger^;
    Result := True;
  end;

  FreeMem(Bellek, 512);
end;

{==============================================================================
  sektör harita tablosundan dosya için tahsis edilen küme numara zincirini serbest býrakýr
  baþarý = Result = 0, hata = Result = $FFFFFFFF
 ==============================================================================}
function TELR1.KumeZinciriniSerbestBirak(AIlkKumeNo: TSayi4): TSayi4;
var
  Bellek: Isaretci;
  Deger: PSayi4;
  SektorNo, SiraNo,
  KumeNo, Sonuc,
  SHTIlkSektor: TSayi4;
begin

  Result := HATA_YOK;

  KumeNo := AIlkKumeNo;

  GetMem(Bellek, 512);

  SHTIlkSektor := FMD.Acilis.DosyaAyirmaTablosu.IlkSektor;

  repeat

    //SISTEM_MESAJ(mtBilgi, RENK_MAVI, '  -> %.8x', [KumeNo]);

    // konumlanýlacak sektör ve sýra numarasý
    SektorNo := KumeNo div 128;
    SiraNo := KumeNo mod 128;

    Sonuc := FMD.FD.FOku(SHTIlkSektor + SektorNo, 1, Bellek);
    if(Sonuc > HATA_YOK) then
    begin

      FreeMem(Bellek, 512);
      Exit($FFFFFFFF);
    end;

    Deger := Bellek;
    Inc(Deger, SiraNo);

    KumeNo := Deger^;

    //if(Deger^ <> $00000000) then
    begin

      Deger^ := $00000000;
      Sonuc := FMD.FD.FYaz(SHTIlkSektor + SektorNo, 1, Bellek);
      if(Sonuc > HATA_YOK) then
      begin

        FreeMem(Bellek, 512);
        Exit($FFFFFFFF);
      end;
    end;

  until KumeNo = ELR_ZD_SON;

  FreeMem(Bellek, 512);
end;

{==============================================================================
  sistem klasörlerini oluþturur
 ==============================================================================}
function TELR1.SistemKlasorleriniOlustur: Boolean;
var
  KlasorAdi: string;

  function Olustur: Boolean;
  var
    G: TGorev;
  begin

    Result := dosyalar.CreateDir(KlasorAdi);
    if not(Result) then
    begin

      G := GGorevler.GorevAl;
      SISTEM_MESAJ(mtHata, RENK_KIRMIZI, '%s klasörü oluþturulamýyor: %d',
        [KlasorAdi, G.FDosyaSonIslemDurum]);
    end;
  end;
begin

  KlasorAdi := 'disk2:\progrmlr';
  Result := Olustur;
  if not(Result) then Exit;
  KlasorAdi := 'disk2:\resimler';
  Result := Olustur;
  if not(Result) then Exit;
  KlasorAdi := 'disk2:\belgeler';
  Result := Olustur;
  if not(Result) then Exit;
  KlasorAdi := 'disk2:\kisiler';
  Result := Olustur;
  if not(Result) then Exit;
  KlasorAdi := 'disk2:\suruculr';
  Result := Olustur;
  if not(Result) then Exit;
  KlasorAdi := 'disk2:\kodlar';
  Result := Olustur;
  if not(Result) then Exit;
  KlasorAdi := 'disk2:\kayitlar';
  Result := Olustur;
  if not(Result) then Exit;
  KlasorAdi := 'disk2:\gecici';
  Result := Olustur;
  if not(Result) then Exit;
end;

function TELR1.SistemKlasorleriniSil: Boolean;
begin

  Result := dosyalar.RemoveDir('disk2:\progrmlr');
  if not(Result) then Exit;
  Result := dosyalar.RemoveDir('disk2:\resimler');
  if not(Result) then Exit;
  Result := dosyalar.RemoveDir('disk2:\belgeler');
  if not(Result) then Exit;
  Result := dosyalar.RemoveDir('disk2:\kisiler');
  if not(Result) then Exit;
  Result := dosyalar.RemoveDir('disk2:\suruculr');
  if not(Result) then Exit;
  Result := dosyalar.RemoveDir('disk2:\kodlar');
  if not(Result) then Exit;
  Result := dosyalar.RemoveDir('disk2:\kayitlar');
  if not(Result) then Exit;
  Result := dosyalar.RemoveDir('disk2:\gecici');
end;

{==============================================================================
  dizin girdisinden dosya adýný alýr
 ==============================================================================}
function TELR1.DosyaAdiniAl(ADizinGirdisi: PDizinGirdisiELR): string;
var
  i: TSayi4;
begin

  Result := '';

  // dosya adýný çevir
  i := 1;
  while (i <= ELR_DOSYA_U) and (ADizinGirdisi^.DosyaAdi[i] <> #0) do
  begin

    Result := Result + ADizinGirdisi^.DosyaAdi[i];
    Inc(i);
  end;
end;

{==============================================================================
  diski elr-1 dosya sistemi için hazýrlar
 ==============================================================================}
procedure TELR1.DiskiBicimle;
var
  Sonuc: TISayi4;
  SHTIlkSektor, SHTSonSektor,
  KBS, IlkVeriSektor: TSayi4;
begin

  // dosya sisteminin veri alanýný sil
  Sonuc := VeriAlaniniSil;
  if(Sonuc <> HATA_YOK) then
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'VeriAlaniniSil hata kodu: %d', [Sonuc]);
    Exit;
  end;

  SHTIlkSektor := FMD.Acilis.DosyaAyirmaTablosu.IlkSektor;
  SHTSonSektor := FMD.Acilis.DosyaAyirmaTablosu.ToplamSektor + SHTIlkSektor;
  KBS := FMD.Acilis.DosyaAyirmaTablosu.KBS;
  IlkVeriSektor := FMD.Acilis.DizinGirisi.IlkSektor * KBS;

  // dosya içerik tablosunu oluþtur
  Sonuc := SHTOlustur(SHTIlkSektor, SHTSonSektor - 1, IlkVeriSektor);
  if(Sonuc <> HATA_YOK) then
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'SHTOlustur hata kodu: %d', [Sonuc]);
    Exit;
  end;
end;

{==============================================================================
  dosya sisteminin veri alanýndaki mevcut verilerini siler
  { TODO - þu aþamada sadece 10 küme silindi, diðer alanlar da silinecek }
 ==============================================================================}
function TELR1.VeriAlaniniSil: TISayi4;
var
  Bellek: Isaretci;
  KumeNo, i: TSayi4;
  Sonuc: TISayi4;
begin

  Result := HATA_YOK;

  GetMem(Bellek, 4 * 512);

  // bellek içeriðini sýfýrla
  FillChar(Bellek^, 4 * 512, $00);

  // sektör numarasý küme numarasýna çevriliyor
  // bilgi: þu aþamada her bir küme 4 sektörden oluþmakta
  KumeNo := FMD.Acilis.DizinGirisi.IlkSektor;

  // 10 küme * 4 sektör içeriðini sil
  for i := 0 to 9 do
  begin

    Sonuc := FMD.FD.FYaz((KumeNo + i) * 4, 4, Bellek);
    if(Sonuc <> HATA_YOK) then
    begin

      FreeMem(Bellek, 4 * 512);
      Exit(Sonuc);
    end;
  end;

  FreeMem(Bellek, 4 * 512);
end;

{==============================================================================
  dosya sistemi sektör harita tablosunu oluþturur
 ==============================================================================}
function TELR1.SHTOlustur(AIlkSektor, ASonSektor, AAyrilanSektor: TSayi4): TISayi4;
var
  Bellek: Isaretci;
  i, j: TSayi4;
  Sonuc: TISayi4;
begin

  Result := HATA_YOK;

  GetMem(Bellek, 512);

  // sht için ayrýlan sektörleri sýfýrla
  FillChar(Bellek^, 512, $00);

  for i := AIlkSektor to ASonSektor - 1 do
  begin

    Sonuc := FMD.FD.FYaz(i, 1, Bellek);
    if(Sonuc <> HATA_YOK) then
    begin

      FreeMem(Bellek, 512);
      Exit(Sonuc);
    end;
  end;

  // ayrýlan sektörleri ayrýlmýþ olarak iþaretle
  // her bir sektör 512 / 4 = 128 adet girdi içeriyor

  // ayrýlan sektör sayýsýný küme numarasýna çevir (her küme 4 sektör)
  j := AAyrilanSektor div 4;

  // ayrýlan sektörler için gerekli sektör sayýsý
  j := j div (512 div 4);

  FillChar(Bellek^, 512, $FF);

  // ilgili sektörleri kullanýlmýþ olarak iþaretle
  for i := AIlkSektor to (AIlkSektor + j) - 1 do
  begin

    Sonuc := FMD.FD.FYaz(i, 1, Bellek);
    if(Sonuc <> HATA_YOK) then
    begin

      FreeMem(Bellek, 512);
      Exit(Sonuc);
    end;
  end;

  // ayrýlan sektörlerden sonraki ilk sektörü ana kök dizin giriþine ayýr
  FillChar(Bellek^, 512, $00);
  PSayi4(Bellek)^ := $FFFFFFFF;

  Sonuc := FMD.FD.FYaz(AIlkSektor + j, 1, Bellek);
  if(Sonuc <> HATA_YOK) then
  begin

    FreeMem(Bellek, 512);
    Exit(Sonuc);
  end;

  FreeMem(Bellek, 512);
end;

{==============================================================================
  sektör olarak depolama aygýtý kullanýlan toplam kapasiteyi hesaplar
 ==============================================================================}
function TELR1.ToplamKullanim(var AKullanilanSektorSayisi: TSayi4): TSayi4;
var
  Bellek: Isaretci;
  Deger: PSayi4;
  SHTIlkSektor,
  SHTSonSektor,
  i, j: TSayi4;
begin                                     Exit(0);  {geçici iptal}

  Result := HATA_YOK;

  AKullanilanSektorSayisi := 0;

  Bellek := GetMem(512);
  if(Bellek = nil) then Exit(HATA_BELLEKYOK);

  SHTIlkSektor := FMD.Acilis.DosyaAyirmaTablosu.IlkSektor;
  SHTSonSektor := FMD.Acilis.DosyaAyirmaTablosu.ToplamSektor + SHTIlkSektor;

  for i := SHTIlkSektor to SHTSonSektor - 1 do
  begin

    Result := FMD.FD.FOku(i, 1, Bellek);
    if(Result <> HATA_YOK) then Break;

    Deger := Bellek;

    // bilgi: her bir girdi 4 byte
    for j := 0 to 128 - 1 do
    begin

      if(Deger^ <> 0) then Inc(AKullanilanSektorSayisi);
      Inc(Deger);
    end;
  end;

  FreeMem(Bellek, 512);

  if(Result = HATA_YOK) then
    AKullanilanSektorSayisi := AKullanilanSektorSayisi * ZINCIRDEKI_SEKTOR_SAYISI
  else AKullanilanSektorSayisi := 0;
end;

end.
