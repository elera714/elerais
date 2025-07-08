{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: gorev.pas
  Dosya Ýþlevi: görev (program) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 07/07/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gorev;

interface

uses paylasim, gn_masaustu, gn_pencere;

const
  // çalýþma seviye numaralarý (0..3)
  CALISMA_SEVIYE0 = 0;
  CALISMA_SEVIYE1 = 1;
  CALISMA_SEVIYE2 = 2;
  CALISMA_SEVIYE3 = 3;

const
  // bir görev için tanýmlanan üst sýnýr olay sayýsý
  // olay belleði 4K olarak tanýmlanmýþtýr. 4096 / SizeOf(TOlay)
  USTSINIR_OLAY         = 64;
  PROGRAM_YIGIN_BELLEK  = (4096 * 5) - 1;             // program yýðýný (stack) için ayrýlacak bellek
  DEFTER_BELLEK_U       = TSayi4((4096 * 10) - 1);    // defter programý için program belleðinde ayrýlacak alan

var
  { TODO - object yapýsýnýn içerisine dahil edilecek }
  CalisanGorevSayisi,                     // oluþturulan / çalýþan program sayýsý
  FAktifGorev: TISayi4;                   // o an çalýþan program
  FAktifGorevBellekAdresi: TSayi4;        // o an çalýþan programýn yüklendiði bellek adresi
  GorevDegisimSayisi: TSayi4 = 0;         // çekirdek baþladýðý andan itibaren gerçekleþtirilen görev deðiþim sayýsý
  GorevBayrakDegeri: TSayi4 = 0;          // her görev çalýþtýrma / sonlandýrma / aktifleþtirme durumunda 1 artýrýlýr
  GorevKilit: TSayi4 = 0;

type
  TDosyaTip = (dtDiger, dtCalistirilabilir, dtSurucu, dtResim, dtBelge);

type
  TDosyaIliskisi = record
    Uzanti: string[5];            // iliþki kurulacak dosya uzantýsý
    Uygulama: string[30];         // uzantýnýn iliþkili olduðu program adý
    DosyaTip: TDosyaTip;          // uzantýnýn iliþkili olduðu dosya tipi
  end;

type

  PGorev = ^TGorev;

  TGorevler = class
  private
    procedure Yukle;
  public
    constructor Create;
    function Olustur: PGorev;
    procedure DurumDegistir(AGorevKimlik: TKimlik; AGorevDurum: TGorevDurum);
    function BosGorevBul: PGorev;
    function Calistir(ATamDosyaYolu: string; ASeviyeNo: TSayi4): PGorev;
    procedure OlayEkle(AGorevKimlik: TKimlik; AOlay: TOlay);
    function GorevBul(AGorevKimlik: TKimlik): PGorev;
    procedure Isaretle(AGorevKimlik: TKimlik; const ASonlanmaSebebi: TISayi4 = -1);
    function Sonlandir(AGorevKimlik: TKimlik; const ASonlanmaSebebi: TISayi4 = -1): TISayi4;
    function GorevKimligiAl(AGorevAdi: string): TKimlik;
    procedure SecicileriOlustur(AKimlik, AUzunluk, ABellekBas,
      AKodBas, AYiginBas: TSayi4);
    procedure GorevSayaciYaz(AGorevKimlik: TKimlik; ASayacDegeri: TSayi4);
    procedure OlaySayisiYaz(AGorevKimlik: TKimlik; AOlaySayisi: TSayi4);
    function OlayAl(AKimlik: TSayi4; var AOlay: TOlay): Boolean;
  end;

  TGorev0 = class
  public
    FGorevSayaci: TSayi4;                 // görev deðiþim sayacý
    FBellekBaslangicAdresi: TSayi4;       // iþlemin yüklendiði bellek adresi
    FSeviyeNo: TSayi4;                    // görevin çalýþma seviye numarasý (0..3)
  end;

  { TODO - nesne class yapýsýna çevrilecek }
  TGorev = object
  private
    FBellekUzunlugu: TSayi4;              // iþlemin kullandýðý bellek uzunluðu
    FKodBaslangicAdres: TSayi4;           // iþlemin bellek baþlangýç adresi
    FYiginBaslangicAdres: TSayi4;         // iþlemin yýðýn adresi
    FAktifMasaustu: PMasaustu;            // görevin aktif masaüstü
    FAktifPencere: PPencere;              // görevin aktif penceresi
  public
    G0: TGorev0;

    FCalismaSuresiMS,                     // görevin çalýþacaðý süre (irq0 tick sayýsý)
    FCalismaSuresiSayacMS: TSayi4;        // görevin çalýþacaðý sürenin sayaç deðeri

    FOlayBellekAdresi: POlay;             // olaylarýn yerleþtirileceði bellek bölgesi
    FOlaySayisi: TSayi4;                  // olay sayacý

    FGorevKimlik: TKimlik;                // görev kimlik numarasý
    FGorevDurum: TGorevDurum;             // iþlem durumu
    FDosyaSonIslemDurum: TISayi4;         // görevin son dosya iþlem sonuç deðeri

    // hata ile ilgili deðiþkenler
    FHataKodu,
    FHataCS, FHataEIP,                    // cs:eip
    FHataESP,                             // esp
    FHataBayrak: TISayi4;                 // flags

    FDosyaAdi,                            // görevin yüklendiði dosya adý
    FProgramAdi: string;                  // program adý
    property OlayBellekAdresi: POlay read FOlayBellekAdresi write FOlayBellekAdresi;
    property AktifMasaustu: PMasaustu read FAktifMasaustu write FAktifMasaustu;
    property AktifPencere: PPencere read FAktifPencere write FAktifPencere;
  published
    property GorevKimlik: TKimlik read FGorevKimlik;
    //property BellekBaslangicAdresi: TSayi4 read FBellekBaslangicAdresi write FBellekBaslangicAdresi;
    property BellekUzunlugu: TSayi4 read FBellekUzunlugu write FBellekUzunlugu;
    property KodBaslangicAdres: TSayi4 read FKodBaslangicAdres write FKodBaslangicAdres;
    property YiginBaslangicAdres: TSayi4 read FYiginBaslangicAdres write FYiginBaslangicAdres;
    //property GorevSayaci: TSayi4 read FGorevSayaci write GorevSayaciYaz;
    //property OlaySayisi: TSayi4 read FOlaySayisi write OlaySayisiYaz;
  end;

var
  GorevListesi: array[0..USTSINIR_GOREVSAYISI - 1] of PGorev;

function GorevBilgisiAl(AGorevSiraNo: TISayi4): PGorev;
function CalisanProgramSayisiniAl(AMasaustuKimlik: TKimlik = -1): TSayi4;
function GorevBayrakDegeriniAl: TSayi4;
function CalisanProgramBilgisiAl(AGorevSiraNo: TISayi4; AMasaustuKimlik: TKimlik = -1): TProgramKayit;
function GorevSiraNumarasiniAl(AGorevSiraNo: TISayi4): TKimlik;
function CalistirilacakBirSonrakiGoreviBul: TKimlik;
function IliskiliProgramAl(ADosyaUzanti: string): TDosyaIliskisi;
procedure IsaretlenenGorevleriSonlandir;
function Memur(AGorevAdi: string; AIslev: TIslev; AYiginDegeri: TSayi4; ASeviyeNo: TSayi4): TSayi4;
function GorevAl(AGorevKimlik: TKimlik = -1): PGorev;

implementation

uses genel, gdt, dosya, sistemmesaj, donusum, zamanlayici, gn_islevler, islevler;

const
  IstisnaAciklamaListesi: array[0..15] of string = (
    ('Sýfýra Bölme Hatasý'),
    ('Hata Ayýklama'),
    ('Engellenemeyen Kesme'),
    ('Durma Noktasý'),
    ('Taþma Hatasý'),
    ('Dizi Aralýðý Aþma Hatasý'),
    ('Hatalý Ýþlemci Kodu'),
    ('Matematik Ýþlemci Mevcut Deðil'),
    ('Çifte Hata'),
    ('Matematik Ýþlemci Yazmaç Hatasý'),
    ('Hatalý TSS Giriþi'),
    ('Yazmaç Mevcut Deðil'),
    ('Yýðýn Hatasý'),
    ('Genel Koruma Hatasý'),
    ('Sayfa Hatasý'),
    ('Hata No: 15 - Tanýmlanmamýþ'));

const
  ILISKILI_UYGULAMA_SAYISI = 14;
  IliskiliUygulamaListesi: array[0..ILISKILI_UYGULAMA_SAYISI - 1] of TDosyaIliskisi = (
    (Uzanti: 'c';    Uygulama: '';             DosyaTip: dtCalistirilabilir),

    (Uzanti: 's';    Uygulama: '';             DosyaTip: dtSurucu),

    (Uzanti: 'asm';  Uygulama: 'defter.c';     DosyaTip: dtBelge),
    (Uzanti: 'bat';  Uygulama: 'defter.c';     DosyaTip: dtBelge),
    (Uzanti: 'inc';  Uygulama: 'defter.c';     DosyaTip: dtBelge),
    (Uzanti: 'ini';  Uygulama: 'defter.c';     DosyaTip: dtBelge),
    (Uzanti: 'log';  Uygulama: 'defter.c';     DosyaTip: dtBelge),
    (Uzanti: 'lpr';  Uygulama: 'defter.c';     DosyaTip: dtBelge),
    (Uzanti: 'md';   Uygulama: 'defter.c';     DosyaTip: dtBelge),
    (Uzanti: 'pas';  Uygulama: 'defter.c';     DosyaTip: dtBelge),
    (Uzanti: 'sh';   Uygulama: 'defter.c';     DosyaTip: dtBelge),
    (Uzanti: 'txt';  Uygulama: 'defter.c';     DosyaTip: dtBelge),
    (Uzanti: 'bmp';  Uygulama: 'resimgor.c';   DosyaTip: dtResim),

    (Uzanti: '';     Uygulama: 'dsybil.c';     DosyaTip: dtDiger));

var
  OlayKilit: TSayi4 = 0;

constructor TGorevler.Create;
begin

  Yukle;
end;

{==============================================================================
  çalýþtýrýlacak görevlerin ana yükleme iþlevlerini içerir
 ==============================================================================}
procedure TGorevler.Yukle;
var
  G: PGorev;
  i: TISayi4;
begin

  // görev bilgilerinin yerleþtirilmesi için bellek ayýr
  G := GetMem(SizeOf(TGorev) * USTSINIR_GOREVSAYISI);

  // bellek giriþlerini görev yapýlarýyla eþleþtir
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    GorevListesi[i] := G;

    // görevi boþ olarak belirle
    G^.FGorevDurum := gdBos;
    G^.FDosyaSonIslemDurum := HATA_DOSYA_ISLEM_BASARILI;
    G^.FGorevKimlik := i;
    G^.FAktifMasaustu := nil;
    G^.FAktifPencere := nil;

    G^.G0 := TGorev0.Create;
    //Gorev^.G0.FDeger0 := 0;

    Inc(G);
  end;
end;

{==============================================================================
  görev (program) dosyalarýný çalýþtýrýr
 ==============================================================================}
function TGorevler.Calistir(ATamDosyaYolu: string; ASeviyeNo: TSayi4): PGorev;
var
  Gorev: PGorev;
  DosyaBellek: Isaretci;
  Olay: POlay;
  DosyaU, i, ProgramBellekU: TSayi4;
  Surucu, Klasor,
  DosyaAdi, IzKayitDosyaAdi: string;
  DosyaKimlik: TKimlik;
  ELFBaslik: PELFBaslik;
  TamDosyaYolu, Degiskenler,
  DosyaUzanti: string;
  p1: PChar;
  IliskiliProgram: TDosyaIliskisi;
  AygitSurucusu: PAygitSurucusu;
begin

  while KritikBolgeyeGir(GorevKilit) = False do;

  // dosyayý, sürücü + Klasor + dosya adý parçalarýna ayýr
  DosyaYolunuParcala2(ATamDosyaYolu, Surucu, Klasor, DosyaAdi);

  // dosya adýnýn uzunluðunu al
  DosyaU := Length(DosyaAdi);

  { TODO : .c dosyalarý ileride .ç (çalýþtýrýlabilir) olarak deðiþtirilecek. }

  // dosya uzantýsýný al
  i := Pos('.', DosyaAdi);
  if(i > 0) then

    DosyaUzanti := Copy(DosyaAdi, i + 1, DosyaU - i)
  else DosyaUzanti := '';

  IliskiliProgram := IliskiliProgramAl(DosyaUzanti);

  Degiskenler := '';
  TamDosyaYolu := Surucu + ':' + Klasor + DosyaAdi;

  {SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'TamDosyaYolu: %s', [TamDosyaYolu]);
  SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Surucu: %s', [Surucu]);
  SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Klasor: %s', [Klasor]);
  SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'DosyaAdi: %s', [DosyaAdi]);}

  // dosya çalýþtýrýlabilir bir dosya deðil ise dosyanýn birlikte açýlacaðý
  // öndeðer olarak tanýmlanan programý bul
  if((IliskiliProgram.DosyaTip = dtResim) or (IliskiliProgram.DosyaTip = dtBelge)
    or (IliskiliProgram.DosyaTip = dtDiger)) then
  begin

    // eðer dosya çalýþtýrýlabilir deðil ise dosyayý, öndeðer olarak tanýmlanan
    // program ile çalýþtýr
    Degiskenler := Surucu + ':' + Klasor + DosyaAdi;      // çalýþtýrýlacak dosya
    DosyaAdi := IliskiliProgram.Uygulama;                 // çalýþtýrýlacak dosyayý çalýþtýracak program
    TamDosyaYolu := AcilisSurucuAygiti + ':\' + KLASOR_PROGRAM + '\' + DosyaAdi;
  end;

  // çalýþtýrýlacak dosyayý tanýmla ve aç
  AssignFile(DosyaKimlik, TamDosyaYolu);
  Reset(DosyaKimlik);
  if(IOResult = HATA_DOSYA_ISLEM_BASARILI) then
  begin

    // dosya uzunluðunu al
    DosyaU := FileSize(DosyaKimlik);

    // dosyanýn çalýþtýrýlmasý için bellekte yer rezerv et
    // defter.c programýna verileri iþlemesi için fazladan 40K yer tahsis et
    if(DosyaAdi = 'defter.c') then
      ProgramBellekU := DosyaU + PROGRAM_YIGIN_BELLEK + DEFTER_BELLEK_U
    else ProgramBellekU := DosyaU + PROGRAM_YIGIN_BELLEK;

    //ProgramBellekU := ((ProgramBellekU shr 12) + 1) shl 12;

    GetMem(DosyaBellek, ProgramBellekU);
    if(DosyaBellek = nil) then
    begin

      SISTEM_MESAJ(mtHata, RENK_SIYAH, 'GOREV.PAS: ' + ATamDosyaYolu + ' için yeterli bellek yok!', []);
      Result := nil;
      KritikBolgedenCik(GorevKilit);
      asm sti end;
      Exit;
    end;

    // dosyayý hedef adrese kopyala
    if(Read(DosyaKimlik, DosyaBellek) = 0) then
    begin

      // dosyayý kapat
      CloseFile(DosyaKimlik);
      SISTEM_MESAJ(mtHata, RENK_SIYAH, 'GOREV.PAS: ' + TamDosyaYolu + ' dosyasý okunamýyor!', []);
      Result := nil;
      KritikBolgedenCik(GorevKilit);
      asm sti end;
      Exit;
    end;

    // dosyayý kapat
    CloseFile(DosyaKimlik);

    // boþ iþlem giriþi bul
    Gorev := GGorevler.Olustur;
    if(Gorev = nil) then
    begin

      SISTEM_MESAJ(mtHata, RENK_SIYAH, 'GOREV.PAS: ' + ATamDosyaYolu + ' için görev oluþturulamýyor!', []);
      Result := nil;
      KritikBolgedenCik(GorevKilit);
      asm sti end;
      Exit;
    end;

    // ELF biçimindeki dosyanýn baþ tarafýna konumlan
    ELFBaslik := DosyaBellek;

    // aygýt sürücüsü çalýþmalarý - test - 31012019
    // testsrc.s çalýþtýrýlabilir aygýt sürücüsü dosyasý çalýþmalar devam etmektedir
    if(IliskiliProgram.DosyaTip = dtSurucu) then
    begin

      AygitSurucusu := PAygitSurucusu(DosyaBellek + PSayi4(DosyaBellek + $100 + 8)^);
      SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'Aygýt sürücüsü / açýklama', []);
      SISTEM_MESAJ(mtBilgi, RENK_SIYAH, AygitSurucusu^.AygitAdi, []);
      SISTEM_MESAJ(mtBilgi, RENK_SIYAH, AygitSurucusu^.Aciklama, []);
      SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'Deðer-1: $%.8x', [AygitSurucusu^.Deger1]);
      SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'Deðer-2: $%.8x', [AygitSurucusu^.Deger2]);
      SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'Deðer-3: $%.8x', [AygitSurucusu^.Deger3]);
      KritikBolgedenCik(GorevKilit);
      asm sti end;
      Exit;
    end;

    // olay iþlemleri için bellekte yer ayýr
    //Olay := GetMem(4096);
    Olay := GetMem(4096);
    if(Olay = nil) then
    begin

      SISTEM_MESAJ(mtHata, RENK_SIYAH, 'GOREV.PAS: olay bilgisi için bellek ayrýlamýyor!', []);
      Result := nil;
      KritikBolgedenCik(GorevKilit);
      asm sti end;
      Exit;
    end;

    // görev çalýþma seviye numarasý - öncelik derecesi
    Gorev^.G0.FSeviyeNo := ASeviyeNo;

    // görev deðiþim sayacýný sýfýrla
    Gorev^.G0.FGorevSayaci := 0;

    // bellek baþlangýç adresi
    Gorev^.G0.FBellekBaslangicAdresi := TSayi4(DosyaBellek);

    // görev çalýþma süreleri
    Gorev^.FCalismaSuresiMS := 2;
    Gorev^.FCalismaSuresiSayacMS := 2;

    // bellek miktarý
    Gorev^.FBellekUzunlugu := ProgramBellekU;

    // iþlem baþlangýç adresi
    Gorev^.FKodBaslangicAdres := ELFBaslik^.KodBaslangicAdresi;

    // iþlemin yýðýn adresi
    if(DosyaAdi = 'defter.c') then
      Gorev^.FYiginBaslangicAdres := (ProgramBellekU - DEFTER_BELLEK_U) - 512
    else Gorev^.FYiginBaslangicAdres := ProgramBellekU - 512;

    // dosyanýn çalýþtýrýlmasý için seçicileri oluþtur
    GGorevler.SecicileriOlustur(Gorev^.FGorevKimlik, Gorev^.FBellekUzunlugu,
      Gorev^.G0.FBellekBaslangicAdresi, Gorev^.FKodBaslangicAdres, Gorev^.FYiginBaslangicAdres);

    // görev olay sayacýný sýfýrla
    Gorev^.FOlaySayisi := 0;

    // iþlemin olay bellek bölgesini ata
    Gorev^.FOlayBellekAdresi := Olay;

    // iþlemin adý
    Gorev^.FDosyaAdi := DosyaAdi;

    // program öndeðer adý
    Gorev^.FProgramAdi := '';

    // deðiþken gönderimi
    // ilk deðiþken - çalýþan iþlemin adý

    // program bellek baþlangýcýnýn ilk 32 byte'ý çekirdeðin programa
    // bilgi vermesi amacýyla ayrýlmýþtýr.
    PSayi4(DosyaBellek + 00)^ := TSayi4(DosyaBellek);
    if(DosyaAdi = 'defter.c') then
      PSayi4(DosyaBellek + 04)^ := ProgramBellekU - DEFTER_BELLEK_U
    else PSayi4(DosyaBellek + 04)^ := ProgramBellekU;

    PSayi4(DosyaBellek + 32)^ := 0;
    p1 := PChar(DosyaBellek + 32 + 4);
    Tasi2(@TamDosyaYolu[1], p1, Length(TamDosyaYolu));
    p1 += Length(TamDosyaYolu);
    p1^ := #0;

    // eðer varsa ikinci deðiþken - çalýþan programýn kullanacaðý deðer
    if(Degiskenler <> '') then
    begin

      PSayi4(DosyaBellek + 32)^ := 1;
      Inc(p1);
      Tasi2(@Degiskenler[1], p1, Length(Degiskenler));
      p1 += Length(Degiskenler);
      p1^ := #0;
    end;

    // görevin durumunu çalýþýyor olarak belirle
    Gorev^.FGorevDurum := gdCalisiyor;

    // görev iþlem sayýsýný bir artýr
    Inc(CalisanGorevSayisi);

    // görev bayrak deðerini artýr
    Inc(GorevBayrakDegeri);

    // programýn iz kayýt dosyasýný oluþtur
    {IzKayitDosyaAdi := DosyaAdiniAl(DosyaAdi);
    IzKayitDosyaAdi += '.log'; //izkayit';
    IzKaydiOlustur(IzKayitDosyaAdi, IzKayitDosyaAdi + ' uygulamasý çalýþtýrýldý');}

    // görev bellek adresini geri döndür
    Result := Gorev;

    KritikBolgedenCik(GorevKilit);
  end
  else
  begin

    CloseFile(DosyaKimlik);
    SISTEM_MESAJ(mtHata, RENK_SIYAH, 'GOREV.PAS: ' + TamDosyaYolu + ' dosya okuma hatasý!', []);
  end;

  KritikBolgedenCik(GorevKilit);
end;

{==============================================================================
  çalýþacak görev için boþ görev bul
 ==============================================================================}
function TGorevler.Olustur: PGorev;
var
  Gorev: PGorev;
begin

  // boþ iþlem giriþi bul
  Gorev := GGorevler.BosGorevBul;

  Result := Gorev;
end;

{==============================================================================
  çalýþacak görev için boþ görev bul
 ==============================================================================}
function TGorevler.BosGorevBul: PGorev;
var
  Gorev: PGorev;
  i: TSayi4;
begin

  // tüm iþlem giriþlerini incele
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    Gorev := GorevListesi[i];

    // eðer görev giriþi boþ ise
    if(Gorev^.FGorevDurum = gdBos) then
    begin

      // görev giriþini ayrýlmýþ olarak iþaretle ve çaðýran iþleve geri dön
      GGorevler.DurumDegistir(i, gdOlusturuldu);
      Exit(Gorev);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  görev için TSS seçicilerini (selektör) oluþturur
 ==============================================================================}
procedure TGorevler.SecicileriOlustur(AKimlik, AUzunluk, ABellekBas,
  AKodBas, AYiginBas: TSayi4);
var
  SeciciCSSiraNo, SeciciDSSiraNo,
  SeciciTSSSiraNo: TKimlik;
  Uzunluk, i: TSayi4;
begin

  // uygulamanýn ilk görev kimliði 3 (olan muyntcs.c)'tür
  i := AKimlik;

  Uzunluk := AUzunluk shr 12;

  // uygulamanýn TSS, CS, DS seçicilerini belirle, her bir program 3 seçici içerir
  SeciciCSSiraNo := (i * 3) + 1;
  SeciciDSSiraNo := SeciciCSSiraNo + 1;
  SeciciTSSSiraNo := SeciciDSSiraNo + 1;

  // uygulama için CS selektörünü oluþtur
  // kod seçicisi (CS)
  // Eriþim  : 1 = mevcut, 11 = DPL3, 11 = kod segment, 0 = dallanýlamaz, 1 = okunabilir, 0 = eriþilmedi
  // Esneklik: 1 = gran = 4K çözünürlük, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SeciciCSSiraNo, ABellekBas, Uzunluk, %11111010, %11010000);
  // uygulama için DS selektörünü oluþtur
  // veri seçicisi (DS)
  // Eriþim  : 1 = mevcut, 11 = DPL3, 10 = veri yazmaç, 0 = artarak büyüyen, 1 = yazýlabilir, 0 = eriþilmedi
  // Esneklik: 1 = gran = 4K çözünürlük, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SeciciDSSiraNo, ABellekBas, Uzunluk, %11110010, %11010000);
  // uygulama için TSS selektörünü oluþtur
  // görev seçicisi (TSS)
  // Eriþim  : 1 = mevcut, 11 = DPL0, 010 = 32 bit kullanýlabilir TSS, 0 = meþgul biti (meþgul deðil), 1
  // Esneklik: 1 = gran = 1Byte çözünürlük, 00, 1 = bana tahsis edildi, 0000 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SeciciTSSSiraNo, TSayi4(GorevTSSListesi[i]), TSS_UZUNLUK - 1,
    %11101001, %00010000);

  // TSS'nin içeriðini sýfýrla
  FillByte(GorevTSSListesi[i]^, 104, $00);

  // giriþ / çýkýþ haritasýný doldur
  if(TSS_UZUNLUK > 104) then
  begin

    // her bit 1 porta karþýlýk gelir. deðerin 1 olmasý DPL3 görevi için port kullanýmýný yasaklar
    FillByte(Isaretci(@GorevTSSListesi[i]^.IOHarita)^, TSS_UZUNLUK - 104, $FF);
    GorevTSSListesi[i]^.IOHaritaGAdres := TSS_UZUNLUK;
  end;

  // TSS içeriðini doldur
  //GorevTSSListesi[i].CR3 := GERCEKBELLEK_DIZINADRESI;
  GorevTSSListesi[i]^.EIP := AKodBas;
  GorevTSSListesi[i]^.EFLAGS := $202;
  GorevTSSListesi[i]^.ESP := AYiginBas;
  GorevTSSListesi[i]^.CS := (SeciciCSSiraNo * 8) + 3;
  GorevTSSListesi[i]^.DS := (SeciciDSSiraNo * 8) + 3;
  GorevTSSListesi[i]^.ES := (SeciciDSSiraNo * 8) + 3;
  GorevTSSListesi[i]^.SS := (SeciciDSSiraNo * 8) + 3;
  GorevTSSListesi[i]^.FS := (SeciciDSSiraNo * 8) + 3;
  GorevTSSListesi[i]^.GS := (SeciciDSSiraNo * 8) + 3;
  GorevTSSListesi[i]^.SS0 := SECICI_SISTEM_VERI * 8;
  GorevTSSListesi[i]^.ESP0 := (i * GOREV3_ESP_U) + GOREV3_ESP;
end;

{==============================================================================
  iþlemin yeni çalýþma durumunu belirler
 ==============================================================================}
procedure TGorevler.DurumDegistir(AGorevKimlik: TKimlik; AGorevDurum: TGorevDurum);
var
  Gorev: PGorev;
begin

  Gorev := GorevListesi[AGorevKimlik];
  if(AGorevDurum <> Gorev^.FGorevDurum) then Gorev^.FGorevDurum := AGorevDurum;
end;

{==============================================================================
  görev sayacýný belirler
 ==============================================================================}
procedure TGorevler.GorevSayaciYaz(AGorevKimlik: TKimlik; ASayacDegeri: TSayi4);
var
  G: PGorev;
begin

  G := GorevListesi[AGorevKimlik];

  if(ASayacDegeri <> G^.G0.FGorevSayaci) then G^.G0.FGorevSayaci := ASayacDegeri;
end;

{==============================================================================
  görevin olay sayýsýný belirler
 ==============================================================================}
procedure TGorevler.OlaySayisiYaz(AGorevKimlik: TKimlik; AOlaySayisi: TSayi4);
var
  G: PGorev;
begin

  G := GorevListesi[AGorevKimlik];

  if(AOlaySayisi <> G^.FOlaySayisi) then G^.FOlaySayisi := AOlaySayisi;
end;

{==============================================================================
  çekirdek tarafýndan görev için oluþturulan olayý kaydeder
 ==============================================================================}
procedure TGorevler.OlayEkle(AGorevKimlik: TKimlik; AOlay: TOlay);
var
  Gorev: PGorev;
  Olay: POlay;
begin

  while KritikBolgeyeGir(OlayKilit) = False do;

  Gorev := GorevListesi[AGorevKimlik];

  if(Gorev^.FGorevDurum = gdCalisiyor) then
  begin

    // olay belleði dolu deðilse olayý kaydet
    if(Gorev^.FOlaySayisi < USTSINIR_OLAY) then
    begin

      // iþlemin olay belleðine konumlan
      Olay := Gorev^.OlayBellekAdresi;
      Inc(Olay, Gorev^.FOlaySayisi);

      // olayý iþlem belleðine kaydet
      Olay^.Kimlik := AOlay.Kimlik;
      Olay^.Olay := AOlay.Olay;
      Olay^.Deger1 := AOlay.Deger1;
      Olay^.Deger2 := AOlay.Deger2;

      // görevin olay sayacýný artýr
      Gorev^.FOlaySayisi := Gorev^.FOlaySayisi + 1;
    end;
  end;

  KritikBolgedenCik(OlayKilit);
end;

{==============================================================================
  görev için (çekirdek tarafýndan) oluþturulan olayý alýr
 ==============================================================================}
function TGorevler.OlayAl(AKimlik: TSayi4; var AOlay: TOlay): Boolean;
var
  Olay1, Olay2: POlay;
  i: TSayi4;
  G: PGorev;
begin

  while KritikBolgeyeGir(OlayKilit) = False do;

  G := GorevListesi[AKimlik];

  // öndeðer çýkýþ deðeri
  Result := False;

  i := G^.FOlaySayisi;

  // görev için oluþturulan olay yoksa çýk
  if(i = 0) then
  begin

    KritikBolgedenCik(OlayKilit);
    Exit;
  end;

  // öndeðer çýkýþ deðeri
  Result := True;

  // görevin olay belleðine konumlan
  Olay1 := G^.OlayBellekAdresi;

  // olaylarý hedef alana kopyala
  AOlay.Olay := Olay1^.Olay;
  AOlay.Kimlik := Olay1^.Kimlik;
  AOlay.Deger1 := Olay1^.Deger1;
  AOlay.Deger2 := Olay1^.Deger2;

  Dec(i);

  // tek bir olay var ise olay belleðini güncellemeye gerek yok
  if(i = 0) then
  begin

    // olay sayacýný azalt
    G^.FOlaySayisi := i;

    KritikBolgedenCik(OlayKilit);
    Exit;
  end;

  // olayý görevin olay belleðinden sil
  Olay2 := Olay1;
  Inc(Olay2);

  Tasi2(Olay2, Olay1, SizeOf(TOlay) * i);

  // olay sayacýný azalt
  G^.FOlaySayisi := i;

  KritikBolgedenCik(OlayKilit);
end;

{==============================================================================
  çalýþan görevi sonlandýrýr
 ==============================================================================}
function TGorevler.Sonlandir(AGorevKimlik: TKimlik; const ASonlanmaSebebi: TISayi4 = -1): TISayi4;
var
  Gorev: PGorev = nil;
begin

  while KritikBolgeyeGir(GorevKilit) = False do;

  Gorev := GorevListesi[AGorevKimlik];

  // görevin sonlandýrýlma bilgisini ver
  if(ASonlanmaSebebi = -1) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'GOREV.PAS: ' + Gorev^.FDosyaAdi + ' normal bir þekilde sonlandýrýldý.', []);
  end
  else
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'GOREV.PAS: ' + Gorev^.FDosyaAdi +
      ' programý istenmeyen bir iþlem yaptýðýndan dolayý sonlandýrýldý', []);
    SISTEM_MESAJ(mtHata, RENK_MAVI, '  -> Hata Kodu: ' + IntToStr(ASonlanmaSebebi) + ' - ' +
      IstisnaAciklamaListesi[ASonlanmaSebebi], []);
    SISTEM_MESAJ(mtHata, RENK_SIYAH, '  -> CS: $%.8x', [Gorev^.FHataCS]);
    SISTEM_MESAJ(mtHata, RENK_SIYAH, '  -> EIP: $%.8x', [Gorev^.FHataEIP]);
    SISTEM_MESAJ(mtHata, RENK_SIYAH, '  -> ESP: $%.8x', [Gorev^.FHataESP]);
    SISTEM_MESAJ(mtHata, RENK_SIYAH, '  -> EFLAGS: $%.8x', [Gorev^.FHataBayrak]);
  end;

  { TODO : aþaðýdaki iþlevlerin çalýþmasýnýn doðruluðu test edilecek }

  // göreve ait zamanlayýcýlarý yok et
  ZamanlayicilariYokEt(AGorevKimlik);

  { TODO : Görsel olmayan nesnelerin bellekten atýlmasýnda (TGorev.Sonlandir)
    görsel iþlevlerin çalýþmamasý saðlanacak }

  // göreve ait görsel nesneleri yok et
  GorevGorselNesneleriniYokEt(AGorevKimlik);

  // göreve ait olay bellek bölgesini iptal et
  { TODO : 1. bu iþlev olay yönetim sistem nesnesinin içerisine dahil edilecek
           2. olay bellek bölgesi iptal edilmeden önce önceden oluþturulan olaylar da kayýtlardan çýkarýlacak }
  //FreeMem(Gorev^.OlayBellekAdresi, 4096);
  FreeMem(Gorev^.OlayBellekAdresi, 4096);

  // görev için ayrýlan bellek bölgesini serbest býrak
  FreeMem(Isaretci(Gorev^.G0.FBellekBaslangicAdresi), Gorev^.BellekUzunlugu);

  // görevi iþlem listesinden çýkart
  GGorevler.DurumDegistir(AGorevKimlik, gdBos);

  // görev sayýsýný bir azalt
  Dec(CalisanGorevSayisi);

  // görev bayrak deðerini artýr
  Inc(GorevBayrakDegeri);

  Result := 0;

  KritikBolgedenCik(GorevKilit);
end;

procedure TGorevler.Isaretle(AGorevKimlik: TKimlik; const ASonlanmaSebebi: TISayi4 = -1);
var
  Gorev: PGorev;
begin

  if(AGorevKimlik >= 0) and (AGorevKimlik < USTSINIR_GOREVSAYISI) then
  begin

    Gorev := GorevListesi[AGorevKimlik];
    Gorev^.FHataKodu := -1;
    Gorev^.FHataESP := -1;
    Gorev^.FGorevDurum := gdSonlandiriliyor;
  end;
end;

{==============================================================================
  görev ile ilgili bellek bölgesini geri döndürür
 ==============================================================================}
function GorevBilgisiAl(AGorevSiraNo: TISayi4): PGorev;
var
  i, j: TISayi4;
begin

  // aranacak görev sýra numarasý
  j := -1;

  // tüm iþlem bellek bölgelerini araþtýr
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    // görev boþ deðil ise görev sýra numarasýný bir artýr
    if not(GorevListesi[i]^.FGorevDurum = gdBos) then Inc(j);

    // görev sýra no aranan görev ise iþlem bellek bölgesini geri döndür
    if(AGorevSiraNo = j) then Exit(GorevListesi[i]);
  end;

  Result := nil;
end;

{==============================================================================
  pencereye sahip görev sayýsýný alýr
 ==============================================================================}
function CalisanProgramSayisiniAl(AMasaustuKimlik: TKimlik = -1): TSayi4;
var
  i: TISayi4;
begin

  Result := 0;

  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    // 1. görev boþ deðilse
    // 2. pencereye sahip ise
    // 3. pencere tipi baþlýksýz deðilse
    if not(GorevListesi[i]^.FGorevDurum = gdBos) and
      not(GorevListesi[i]^.FAktifPencere = nil) and
      not(GorevListesi[i]^.FAktifPencere^.FPencereTipi = ptBasliksiz) then
    begin

      if(AMasaustuKimlik = -1) then
        Inc(Result)
      else if(GorevListesi[i]^.AktifMasaustu^.FTGN.Kimlik = AMasaustuKimlik) then
        Inc(Result);
    end;
  end;
end;

{==============================================================================
  görev bayrak deðerini al
  bilgi: bu deðer, her program çalýþtýrma ve sonlandýrmada deðiþen bayrak deðeridir
    t deðerinden t + 1 deðerine kadar "çalýþan program sayýsýnda" deðiþiklik olmasa bile
    baþlama ve sonlandýrma bazlý deðiþimleri yakalamak amaçlýdýr
 ==============================================================================}
function GorevBayrakDegeriniAl: TSayi4;
begin

  Result := GorevBayrakDegeri;
end;

{==============================================================================
  pencereye sahip görev ile ilgili bilgi alýr
 ==============================================================================}
function CalisanProgramBilgisiAl(AGorevSiraNo: TISayi4; AMasaustuKimlik: TKimlik = -1): TProgramKayit;
var
  i, ArananGorev: TISayi4;
begin

  ArananGorev := -1;

  Result.PencereKimlik := HATA_KIMLIK;

  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    // 1. görev boþ deðilse
    // 2. pencereye sahip ise
    // 3. pencere tipi baþlýksýz deðilse
    if not(GorevListesi[i]^.FGorevDurum = gdBos) and
      not(GorevListesi[i]^.FAktifPencere = nil) and
      not(GorevListesi[i]^.FAktifPencere^.FPencereTipi = ptBasliksiz) then
    begin

      if(AMasaustuKimlik = -1) then
        Inc(ArananGorev)
      else if(GorevListesi[i]^.AktifMasaustu^.FTGN.Kimlik = AMasaustuKimlik) then
        Inc(ArananGorev);
    end;

    // görev sýra no aranan görev ise iþlem bellek bölgesini geri döndür
    if(AGorevSiraNo = ArananGorev) then
    begin

      Result.PencereKimlik := GorevListesi[i]^.FAktifPencere^.FTGN.Kimlik;
      Result.GorevKimlik := GorevListesi[i]^.GorevKimlik;
      Result.PencereTipi := GorevListesi[i]^.FAktifPencere^.FPencereTipi;
      Result.PencereDurum := GorevListesi[i]^.FAktifPencere^.FPencereDurum;
      Result.DosyaAdi := GorevListesi[i]^.FDosyaAdi;
      Exit;
    end;
  end;
end;

{==============================================================================
  görev kimlik numarasýna göre görev aramasý yapar
 ==============================================================================}
function TGorevler.GorevBul(AGorevKimlik: TKimlik): PGorev;
var
  Gorev: PGorev;
  i: TSayi4;
begin

  // tüm görev giriþlerini incele
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    Gorev := GorevListesi[i];

    // eðer görev giriþi boþ ise
    if(Gorev^.FGorevDurum = gdCalisiyor) and (Gorev^.GorevKimlik = AGorevKimlik) then
      Exit(Gorev);
  end;

  Result := nil;
end;

{==============================================================================
  görev adýndan görev kimlik numarasýný alýr
 ==============================================================================}
function TGorevler.GorevKimligiAl(AGorevAdi: string): TKimlik;
var
  i: TISayi4;
begin

  // tüm iþlem bellek bölgelerini araþtýr
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    // görev boþ deðil ise görev sýra numarasýný bir artýr
    if not(GorevListesi[i]^.FGorevDurum = gdBos) and
      (GorevListesi[i]^.FDosyaAdi = AGorevAdi) then Exit(GorevListesi[i]^.GorevKimlik);
  end;

  Result := -1;
end;

{==============================================================================
  görev bellek sýra numarasýný geri döndürür
 ==============================================================================}
function GorevSiraNumarasiniAl(AGorevSiraNo: TISayi4): TKimlik;
var
  i, j: TISayi4;
begin

  // aranacak görev sýra numarasý
  j := -1;

  // tüm iþlem bellek bölgelerini araþtýr
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    // görev çalýþýyor ise görev sýra numarasýný bir artýr
    if(GorevListesi[i]^.FGorevDurum = gdCalisiyor) then Inc(j);

    // görev sýra no aranan görev ise iþlem bellek bölgesini geri döndür
    if(AGorevSiraNo = j) then Exit(i);
  end;

  Result := -1;
end;

{==============================================================================
  çalýþtýrýlacak bir sonraki görevi bulur
 ==============================================================================}
function CalistirilacakBirSonrakiGoreviBul: TKimlik;
var
  GorevKimlik: TKimlik;
  i: TISayi4;
begin

  // çalýþan göreve konumlan
  GorevKimlik := FAktifGorev;

  // bir sonraki görevden itibaren tüm görevleri incele
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    Inc(GorevKimlik);
    if(GorevKimlik > USTSINIR_GOREVSAYISI) then GorevKimlik := 0;

    // çalýþan görev aranan görev ise çaðýran iþleve geri dön
    if(GorevListesi[GorevKimlik]^.FGorevDurum = gdCalisiyor) then Break;
  end;

  Result := GorevKimlik;
end;

{==============================================================================
  dosya uzantýsý ile iliþkili program adýný geri döndürür
 ==============================================================================}
function IliskiliProgramAl(ADosyaUzanti: string): TDosyaIliskisi;
var
  i: TSayi4;
begin

  // dosyalarla iliþkilendirilen öndeðer program
  Result.Uzanti := ADosyaUzanti;
  Result.Uygulama := IliskiliUygulamaListesi[0].Uygulama;
  Result.DosyaTip := IliskiliUygulamaListesi[0].DosyaTip;

  for i := 1 to ILISKILI_UYGULAMA_SAYISI - 1 do
  begin

    if(IliskiliUygulamaListesi[i].Uzanti = ADosyaUzanti) then
    begin

      Result.Uzanti := IliskiliUygulamaListesi[i].Uzanti;
      Result.Uygulama := IliskiliUygulamaListesi[i].Uygulama;
      Result.DosyaTip := IliskiliUygulamaListesi[i].DosyaTip;
      Exit;
    end;
  end;
end;

{==============================================================================
  sonlandýrma amaçlý iþaretlenen görevlerin sonlandýrýr
  bilgi: uygulama öncelikle sonladýrmak için iþaretlenir daha sonlandýrýlýr
 ==============================================================================}
procedure IsaretlenenGorevleriSonlandir;
var
  Gorev: PGorev;
  i: TISayi4;
begin

  // bellek giriþlerini görev yapýlarýyla eþleþtir
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    Gorev := GorevListesi[i];

    if(Gorev^.FGorevDurum = gdSonlandiriliyor) then
      GGorevler.Sonlandir(Gorev^.FGorevKimlik, Gorev^.FHataKodu);
  end;
end;

{==============================================================================
  görev için belli bir görevi yerine getiren iþlev oluþturur - (thread)
  bilgi: saçma sapan kelime olan thread kelimesini kullanmayý uygun bulmuyorum
 ==============================================================================}
function Memur(AGorevAdi: string; AIslev: TIslev; AYiginDegeri: TSayi4; ASeviyeNo: TSayi4): TSayi4;
var
  Gorev: PGorev;
  // yazmaçlarýn girdi içerisindeki sýra numaralarý
  SNYazmacCS, SNYazmacDS, SNYazmacTSS,
  i: TSayi4;
begin

  Gorev := GGorevler.BosGorevBul;
  if not(Gorev = nil) then
  begin

    i := Gorev^.FGorevKimlik;

    // uygulamanýn TSS, CS, DS seçicilerini belirle, her bir program 3 seçici içerir
    SNYazmacCS := (i * 3) + 1;
    SNYazmacDS := SNYazmacCS + 1;
    SNYazmacTSS := SNYazmacDS + 1;

    // kod seçicisi (CS)
    // Eriþim  : 1 = mevcut, 00 = DPL0, 11 = kod yazmaç, 0 = dallanýlamaz, 1 = okunabilir, 0 = eriþilmedi
    // Esneklik: 1 = gran = 4K çözünürlük, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
    GDTRGirdisiEkle(SNYazmacCS, 0, $FFFFFFFF, %10011010, %11011111);
    // veri seçicisi (DS)
    // Eriþim  : 1 = mevcut, 00 = DPL0, 10 = veri yazmaç, 0 = artarak büyüyen, 1 = yazýlabilir, 0 = eriþilmedi
    // Esneklik: 1 = gran = 4K çözünürlük, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
    GDTRGirdisiEkle(SNYazmacDS, 0, $FFFFFFFF, %10010010, %11011111);
    // görev seçicisi (TSS)
    // Eriþim  : 1 = mevcut, 00 = DPL0, 010 = 32 bit kullanýlabilir TSS, 0 = meþgul biti (meþgul deðil), 1
    // Esneklik: 1 = gran = 1Byte çözünürlük, 00, 1 = bana tahsis edildi, 0000 = uzunluk 16..19 bit
    GDTRGirdisiEkle(SNYazmacTSS, TSayi4(GorevTSSListesi[i]), 104,
      %10001001, %00010000);

    // denetçinin kullanacaðý TSS'nin içeriðini sýfýrla
    FillByte(GorevTSSListesi[i]^, 104, $00);

    GorevTSSListesi[i]^.EIP := TSayi4(AIslev);    // DPL 0
    GorevTSSListesi[i]^.EFLAGS := $202;
    GorevTSSListesi[i]^.ESP := AYiginDegeri - 1000;
    GorevTSSListesi[i]^.CS := SNYazmacCS * 8;
    GorevTSSListesi[i]^.DS := SNYazmacDS * 8;
    GorevTSSListesi[i]^.ES := SNYazmacDS * 8;
    GorevTSSListesi[i]^.SS := SNYazmacDS * 8;
    GorevTSSListesi[i]^.FS := SNYazmacDS * 8;
    GorevTSSListesi[i]^.GS := SNYazmacDS * 8;
    GorevTSSListesi[i]^.SS0 := SNYazmacDS * 8;
    GorevTSSListesi[i]^.ESP0 := AYiginDegeri - 1000;

    // sistem görev deðerlerini belirle
    GorevListesi[i]^.G0.FSeviyeNo := ASeviyeNo;
    GorevListesi[i]^.G0.FGorevSayaci := 0;
    GorevListesi[i]^.G0.FBellekBaslangicAdresi := TSayi4(@AIslev);
    GorevListesi[i]^.FCalismaSuresiMS := 20;
    GorevListesi[i]^.FCalismaSuresiSayacMS := 20;
    GorevListesi[i]^.BellekUzunlugu := $FFFFFFFF;
    GorevListesi[i]^.FOlaySayisi := 0;
    GorevListesi[i]^.OlayBellekAdresi := nil;
    GorevListesi[i]^.AktifMasaustu := nil;
    GorevListesi[i]^.AktifPencere := nil;

    // sistem görev adý (dosya adý)
    GorevListesi[i]^.FDosyaAdi := 'cekirdek.bin';
    GorevListesi[i]^.FProgramAdi := AGorevAdi;

    // sistem görevini çalýþýyor olarak iþaretle
    Gorev := GorevListesi[i];
    GGorevler.DurumDegistir(i, gdCalisiyor);

    // çalýþan ve oluþturulan görev deðerlerini belirle
    Inc(CalisanGorevSayisi);

    Result := SNYazmacCS;
  end;
end;

function GorevAl(AGorevKimlik: TKimlik = -1): PGorev;
begin

  if(AGorevKimlik = -1) then
    Result := GorevListesi[FAktifGorev]
  else Result := GorevListesi[AGorevKimlik];
end;

end.
