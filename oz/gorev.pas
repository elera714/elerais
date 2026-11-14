{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: gorev.pas
  Dosya Ýþlevi: görev (program) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 14/11/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gorev;

interface

uses paylasim, gn_masaustu, gorselnesne;

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
  // program yýðýný (stack) için ayrýlacak bellek (*4K)
  PROGRAM_YIGIN_BELLEK  = TSayi4(5 * 4096);
  // defter programý için program belleðinde ayrýlacak alan (*4K)
  DEFTER_BELLEK_U       = TSayi4(10 * 4096);

type
  TDosyaTip = (dtDiger, dtCalistirilabilir, dtSurucu, dtResim, dtBelge);

type
  TDosyaIliskisi = record
    Uzanti: string[5];            // iliþki kurulacak dosya uzantýsý
    Uygulama: string[30];         // uzantýnýn iliþkili olduðu program adý
    DosyaTip: TDosyaTip;          // uzantýnýn iliþkili olduðu dosya tipi
  end;

type
  TGorev = class
    FKimlik: TKimlik;                   // görev kimlik numarasý
    FSeviyeNo: TSayi4;                  // görevin çalýþma seviye numarasý (0..3)
    FDurum: TGorevDurum;                // görev çalýþma durumu

    FBellekBaslAdr: TSayi4;             // görevin yüklendiði bellek baþlangýç adresi
    FBellekUz: TSayi4;                  // görevin kullandýðý bellek uzunluðu (*4K)
    FYiginBellekUz: TSayi4;             // görev yýðýnýnýn bellek uzunluðu (*4K)
    FKodBasAdresi: TSayi4;              // görev kodlarýnýn ilk çalýþmaya baþlayacaðý bellek adresi
    FYiginBasAdresi: TSayi4;            // iþlemin yýðýn baþlangýç adresi

    FAktifMasaustu: TMasaustu;          // görevin çalýþtýðý aktif masaüstü
    FAktifPencere: TGorselNesne;        // görevin sahip olduðu pencere

    FGrvSayac: TSayi4;                  // zamanlayýcý her tetiklendiðinde artan görev deðiþim sayacý

    FCalismaSureMS,                     // görevin çalýþacaðý süre (irq0 tick sayýsý)
    FCalismaSureSayac: TSayi4;          // görevin çalýþacaðý sürenin sayaç deðeri

    FOlayBellekAdresi: POlay;           // göreve ait olaylarýn yerleþtirileceði bellek bölgesi
    FOlaySayisi: TSayi4;                // görev olay sayýsý

    FDosyaSonIslemDurum: TISayi4;       // göreve ait son dosya iþlem sonuç deðeri

    // hata ile ilgili deðerlerin yerleþtirileceði deðiþkenler
    FHataKodu,                          // hata kodu
    FHataCS, FHataEIP,                  // cs:eip
    FHataESP,                           // esp
    FHataBayrak: TISayi4;               // flags

//  FKullanilanBellek: TSayi4;          // görevin byte olarak kullandýðý tüm kaynaklar toplamý (TODO - kodlanacak }

    FDosyaAdi,                          // görev dosya adý
    FProgramAdi: string;                // program adý
    constructor Create(AKimlik: TKimlik);
  end;

type
  TGorevler = class
  private
    FGorevListesi: array[0..USTSINIR_GOREVSAYISI - 1] of TGorev;
    function Al(ASiraNo: TISayi4): TGorev;
    procedure Yaz(ASiraNo: TISayi4; AGorev: TGorev);
  public
    FAktifGrv: TISayi4;                 // o an çalýþan program
    FCalisanGorevSayisi: TSayi4;        // oluþturulan / çalýþan program sayýsý
    FAktifGrvBelAdr: TSayi4;            // o an çalýþan programýn belleðe yüklendiði adres
    FGorevDegisimSayisi: TSayi4;        // çekirdek baþladýðý andan itibaren gerçekleþtirilen görev deðiþim sayýsý
    FGorevBayrakDegeri: TSayi4;         // her görev çalýþtýrma / sonlandýrma / aktifleþtirme durumunda 1 artýrýlýr
    FGorevDegisimBayragi: TSayi4;       // görev deðiþim bayraðý: 0 = görev deðiþtirme, 1 = görev deðiþtir
    constructor Create;
    property Gorev[ASiraNo: TISayi4]: TGorev read Al write Yaz;
    function GorevOlustur: TGorev;
    function GorevKimligiAl(AGorevAdi: string): TKimlik;
    procedure SecicileriOlustur(AKimlik, AUzunluk, ABellekBas,
      AKodBas, AYiginBas: TSayi4);
    function Calistir(ATamDosyaYolu: string; ASeviyeNo: TSayi4): TGorev;
    procedure OlayEkle(AGorevKimlik: TKimlik; AOlay: TOlay);
    procedure OlaySayisiYaz(AGorevKimlik: TKimlik; AOlaySayisi: TSayi4);
    function OlayAl(AKimlik: TSayi4; var AOlay: TOlay): Boolean;
    function GorevBul(AGorevKimlik: TKimlik): TGorev;
    function GorevAl(AGorevKimlik: TKimlik = -1): TGorev;
    procedure DurumDegistir(AGorevKimlik: TKimlik; AGorevDurum: TGorevDurum);
    procedure GorevSayaciYaz(AGorevKimlik: TKimlik; ASayacDegeri: TSayi4);
    procedure Isaretle(AGorevKimlik: TKimlik; const ASonlanmaSebebi: TISayi4 = -1);
    function Sonlandir(AGorevKimlik: TKimlik; const ASonlanmaSebebi: TISayi4 = -1): TISayi4;
    function CalisacakYeniGoreviBul: TKimlik;
    function PencereSahipGorevSayisiniAl(AMasaustuKimlik: TKimlik = -1): TSayi4;
    function PencereSahipGorevBilgisiAl(AGorevSiraNo: TISayi4;
      AMasaustuKimlik: TKimlik = -1): TProgramKayit;
    function GorevSiraNumarasiniAl(AGorevSiraNo: TISayi4): TKimlik;
    function GorevBilgisiAl(AGorevSiraNo: TISayi4): TGorev;
    procedure IsaretlenenGorevleriSonlandir;
    function GorevBayrakDegeriniAl: TSayi4;
    function IliskiliProgramAl(ADosyaUzanti: string): TDosyaIliskisi;
  end;

var
  GGorevler: TGorevler;
  GorevKilit: TSayi4 = 0;
  OlayKilit: TSayi4 = 0;

implementation

uses gdt, dosyalar, sistemmesaj, donusum, zamanlayici, gn_islevler,
  gn_pencere, islevler;

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

{==============================================================================
  görev nesnesi ana yükleme iþlevlerini içerir
 ==============================================================================}
constructor TGorev.Create(AKimlik: TKimlik);
begin

  FKimlik := AKimlik;

  FSeviyeNo := 0;
  FDurum := gdIptal;

  FBellekBaslAdr := 0;
  FBellekUz := 0;
  FYiginBellekUz := 0;
  FKodBasAdresi := 0;
  FYiginBasAdresi := 0;

  FAktifMasaustu := nil;
  FAktifPencere := nil;

  FGrvSayac := 0;

  FCalismaSureMS := 0;
  FCalismaSureSayac := 0;

  FOlayBellekAdresi := nil;
  FOlaySayisi := 0;

  FDosyaSonIslemDurum := HATA_YOK;

  FHataKodu := 0;
  FHataCS := 0;
  FHataEIP := 0;
  FHataESP := 0;
  FHataBayrak := 0;

  FDosyaAdi := '';
  FProgramAdi := '';
end;

{==============================================================================
  görevler nesnesi ana yükleme iþlevlerini içerir
 ==============================================================================}
constructor TGorevler.Create;
var
  i: TISayi4;
begin

  // ilk deðer atamalarý
  FAktifGrv := 0;
  FCalisanGorevSayisi := 0;
  FAktifGrvBelAdr := 0;
  FGorevDegisimSayisi := 0;
  FGorevBayrakDegeri := 0;
  FGorevDegisimBayragi := 1;

  // görev nesnelerini sýfýrla
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do Gorev[i] := nil;
end;

function TGorevler.Al(ASiraNo: TISayi4): TGorev;
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_GOREVSAYISI) then
    Result := FGorevListesi[ASiraNo]
  else Result := nil;
end;

procedure TGorevler.Yaz(ASiraNo: TISayi4; AGorev: TGorev);
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_GOREVSAYISI) then
    FGorevListesi[ASiraNo] := AGorev;
end;

{==============================================================================
  çalýþacak uygulama için görev oluþturur
 ==============================================================================}
function TGorevler.GorevOlustur: TGorev;
var
  G: TGorev;
  i: TSayi4;
begin

  // tüm iþlem giriþlerini incele
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    G := Gorev[i];

    // eðer görev giriþi boþ ise
    if(G = nil) then
    begin

      // görev nesnesini diziye ata
      G := TGorev.Create(i);
      Gorev[i] := G;

      // görevi giriþini ayrýlmýþ olarak iþaretle ve çaðýran iþleve geri dön
      G.FDurum := gdOlusturuldu;
      Exit(G);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  görev adýndan görev kimlik numarasýný alýr
 ==============================================================================}
function TGorevler.GorevKimligiAl(AGorevAdi: string): TKimlik;
var
  G: TGorev;
  i: TSayi4;
begin

  // tüm iþlem bellek bölgelerini araþtýr
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    G := Gorev[i];

    // görev boþ deðil ise görev sýra numarasýný bir artýr
    if not(G = nil) and (G.FDosyaAdi = AGorevAdi) then Exit(G.FKimlik);
  end;

  Result := -1;
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
  görev program dosyalasýný çalýþtýrýr
 ==============================================================================}
function TGorevler.Calistir(ATamDosyaYolu: string; ASeviyeNo: TSayi4): TGorev;
var
  G: TGorev;
  ELFBaslik: PELFBaslik;
  AygitSurucusu: PAygitSurucusu;
  IliskiliProgram: TDosyaIliskisi;
  GeciciDosyaBellek,
  DosyaBellek: Isaretci;
  Olay: POlay;
  i, j, ProgramBellekU: TSayi4;
  Surucu, Klasor,
  DosyaAdi, IzKayitDosyaAdi,
  TamDosyaYolu, Degiskenler,
  DosyaUzanti, TS: string;
  p1: PChar;
begin

  //while KritikBolgeyeGir(GorevKilit) = False do;

  // dosyayý, sürücü + Klasor + dosya adý parçalarýna ayýr
  DosyaYolunuParcala2(ATamDosyaYolu, Surucu, Klasor, DosyaAdi);

  // dosya adýnýn uzunluðunu al
  j := Length(DosyaAdi);

  { TODO : .c dosyalarý ileride .ç (çalýþtýrýlabilir) olarak deðiþtirilecek. }

  // dosya uzantýsýný al
  i := Pos('.', DosyaAdi);
  if(i > 0) then

    DosyaUzanti := Copy(DosyaAdi, i + 1, j - i)
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

  // program dosyasýný belleðe oku
  GeciciDosyaBellek := nil;
  DosyaUyari := DosyaOku(TamDosyaYolu, GeciciDosyaBellek);
  if not(DosyaUyari.Durum = HATA_YOK) then
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'GOREV.PAS: ' + ATamDosyaYolu + ' dosyasý belleðe yüklenemiyor: (%d)', [DosyaUyari.Durum]);
    KritikBolgedenCik(GorevKilit);
    Exit(nil);

    //GeciciDosyaBellek := SistemUyariBellekAdresi;
  end;

  // program için gereken bellek miktarýnýn *4K olarak hesaplanmasý
  ProgramBellekU := DosyaUyari.Uzunluk;
  ProgramBellekU := ProgramBellekU - 1;
  ProgramBellekU := ((ProgramBellekU shr 12) + 1) shl 12;

  { TODO - fazladan 2K bellek ekleniyor. eklenmediðinde SADECE defter.c yazýlýmý hata veriyor }
  ProgramBellekU := ProgramBellekU + (2 * 4096);

  // dosyanýn çalýþtýrýlmasý için bellekte yer rezerv et
  // defter.c programýna verileri iþlemesi için fazladan 10K yer tahsis et
  if(DosyaAdi = 'defter.c') then ProgramBellekU := ProgramBellekU + DEFTER_BELLEK_U;

  GetMem(DosyaBellek, ProgramBellekU + PROGRAM_YIGIN_BELLEK);
  if(DosyaBellek = nil) then
  begin

    if not(GeciciDosyaBellek = nil) then FreeMem(GeciciDosyaBellek, DosyaUyari.Uzunluk);

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'GOREV.PAS: ' + ATamDosyaYolu + ' için yeterli bellek yok2!', []);
    KritikBolgedenCik(GorevKilit);
    Exit(nil);
  end;

  // program dosyasýný çalýþacaðý hedef belleðe kopyala
  Tasi2(GeciciDosyaBellek, DosyaBellek, DosyaUyari.Uzunluk);

  // programýn kopyalandýðý önceki belleði serbest býrak
  if not(GeciciDosyaBellek = nil) then FreeMem(GeciciDosyaBellek, DosyaUyari.Uzunluk);

  // yeni görev yapýsý oluþtur
  G := GorevOlustur;
  if(G = nil) then
  begin

    FreeMem(DosyaBellek, ProgramBellekU + PROGRAM_YIGIN_BELLEK);
    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'GOREV.PAS: ' + ATamDosyaYolu + ' için görev oluþturulamýyor!', []);
    KritikBolgedenCik(GorevKilit);
    Exit(nil);
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
    Exit(nil);
  end;

  // olay iþlemleri için bellekte yer ayýr
  Olay := GetMem(4096);
  if(Olay = nil) then
  begin

    FreeMem(DosyaBellek, ProgramBellekU + PROGRAM_YIGIN_BELLEK);
    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'GOREV.PAS: olay bilgisi için bellek ayrýlamýyor!', []);
    KritikBolgedenCik(GorevKilit);
    Exit(nil);
  end;

  // iþlemin olay bellek bölgesini ata
  G.FOlayBellekAdresi := Olay;

  // görev olay sayacýný sýfýrla
  G.FOlaySayisi := 0;

  // görev çalýþma seviye numarasý - öncelik derecesi
  G.FSeviyeNo := ASeviyeNo;

  // görev deðiþim sayacýný sýfýrla
  G.FGrvSayac := 0;

  // bellek baþlangýç adresi
  G.FBellekBaslAdr := TSayi4(DosyaBellek);

  // görev çalýþma süreleri
  G.FCalismaSureMS := DPL3_SUREMS;
  G.FCalismaSureSayac := DPL3_SUREMS;

  // bellek miktarý
  G.FBellekUz := ProgramBellekU;
  G.FYiginBellekUz := PROGRAM_YIGIN_BELLEK;

  // iþlem baþlangýç adresi
  G.FKodBasAdresi := ELFBaslik^.KodBaslangicAdresi;

  //SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'A: %x', [G^.KodBaslangicAdresi]);

  // iþlemin yýðýn adresi
  G.FYiginBasAdresi := (G.FBellekUz + G.FYiginBellekUz) - 64;

  // dosyanýn çalýþtýrýlmasý için seçicileri oluþtur
  SecicileriOlustur(G.FKimlik, G.FBellekUz + G.FYiginBellekUz, G.FBellekBaslAdr,
    G.FKodBasAdresi, G.FYiginBasAdresi);

  // iþlemin adý
  G.FDosyaAdi := DosyaAdi;

  // program öndeðer adý
  G.FProgramAdi := '';

  // deðiþken gönderimi
  // ilk deðiþken - çalýþan iþlemin adý

  // program bellek baþlangýcýnýn ilk 32 byte'ý çekirdeðin programa
  // bilgi vermesi amacýyla ayrýlmýþtýr.
  PSayi4(DosyaBellek + 00)^ := TSayi4(DosyaBellek);
  PSayi4(DosyaBellek + 04)^ := G.FBellekUz - DEFTER_BELLEK_U;

  PSayi4(DosyaBellek + 32)^ := 0;
  p1 := PChar(DosyaBellek + 32 + 4);
  Tasi2(@TamDosyaYolu[1], p1, Length(TamDosyaYolu));
  p1 := p1 + Length(TamDosyaYolu);
  p1^ := #0;

  // eðer varsa ikinci deðiþken - çalýþan programýn kullanacaðý deðer
  if(Degiskenler <> '') then
  begin

    PSayi4(DosyaBellek + 32)^ := 1;
    Inc(p1);
    Tasi2(@Degiskenler[1], p1, Length(Degiskenler));
    p1 := p1 + Length(Degiskenler);
    p1^ := #0;
  end;

  // görevin durumunu çalýþýyor olarak belirle
  G.FDurum := gdCalisiyor;

  // görev iþlem sayýsýný bir artýr
  Inc(FCalisanGorevSayisi);

  // görev bayrak deðerini artýr
  Inc(FGorevBayrakDegeri);

  // programýn iz kayýt dosyasýný oluþtur
  TS := TarihSaatBilgisiAl;

  IzKayitDosyaAdi := DosyaAdiniAl(DosyaAdi);
  IzKayitDosyaAdi := IzKayitDosyaAdi + '.log'; //izkayit';
  IzKaydiOlustur(IzKayitDosyaAdi, IzKayitDosyaAdi + ' uygulamasý ' + TS +
    ' itibariyle çalýþtýrýldý...');

  // görev bellek adresini geri döndür
  Result := G;

  KritikBolgedenCik(GorevKilit);
end;

{==============================================================================
  çekirdek tarafýndan görev için oluþturulan olayý kaydeder
 ==============================================================================}
procedure TGorevler.OlayEkle(AGorevKimlik: TKimlik; AOlay: TOlay);
var
  G: TGorev;
  Olay: POlay;
begin

  //while KritikBolgeyeGir(OlayKilit) = False do;

  G := Gorev[AGorevKimlik];
  if(G = nil) then
  begin

//    KritikBolgedenCik(OlayKilit);
    Exit;
  end;

  // görev çalýþýyor ve olay bellek adresi tanýmlandýysa
  if(G.FDurum = gdCalisiyor) and not(G.FOlayBellekAdresi = nil) then
  begin

    // olay belleði dolu deðilse olayý kaydet
    if(G.FOlaySayisi < USTSINIR_OLAY) then
    begin

      // iþlemin olay belleðine konumlan
      Olay := G.FOlayBellekAdresi;
      Inc(Olay, G.FOlaySayisi);

      // olayý iþlem belleðine kaydet
      Olay^.Kimlik := AOlay.Kimlik;
      Olay^.Olay := AOlay.Olay;
      Olay^.Deger1 := AOlay.Deger1;
      Olay^.Deger2 := AOlay.Deger2;

      // görevin olay sayacýný artýr
      G.FOlaySayisi := G.FOlaySayisi + 1;
    end;
  end;

  //KritikBolgedenCik(OlayKilit);
end;

{==============================================================================
  görevin olay sayýsýný belirler
 ==============================================================================}
procedure TGorevler.OlaySayisiYaz(AGorevKimlik: TKimlik; AOlaySayisi: TSayi4);
var
  G: TGorev;
begin

  G := Gorev[AGorevKimlik];
  if(G = nil) then Exit;

  if(G.FOlaySayisi <> AOlaySayisi) then G.FOlaySayisi := AOlaySayisi;
end;

{==============================================================================
  görev için (çekirdek tarafýndan) oluþturulan olayý alýr
 ==============================================================================}
function TGorevler.OlayAl(AKimlik: TSayi4; var AOlay: TOlay): Boolean;
var
  G: TGorev;
  Olay1, Olay2: POlay;
  i: TSayi4;
begin

//  while KritikBolgeyeGir(OlayKilit) = False do;

  // öndeðer çýkýþ deðeri
  Result := False;

  G := Gorev[AKimlik];
  if(G = nil) then
  begin

//    KritikBolgedenCik(OlayKilit);
    Exit;
  end;

  i := G.FOlaySayisi;

  // görev için oluþturulan olay yoksa çýk
  if(i = 0) then
  begin

//    KritikBolgedenCik(OlayKilit);
    Exit;
  end;

  // öndeðer çýkýþ deðeri
  Result := True;

  // görevin olay belleðine konumlan
  Olay1 := G.FOlayBellekAdresi;

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
    G.FOlaySayisi := i;

//    KritikBolgedenCik(OlayKilit);
    Exit;
  end;

  // olayý görevin olay belleðinden sil
  Olay2 := Olay1;
  Inc(Olay2);

  Tasi2(Olay2, Olay1, SizeOf(TOlay) * i);

  // olay sayacýný azalt
  G.FOlaySayisi := i;

//  KritikBolgedenCik(OlayKilit);
end;

{==============================================================================
  görev kimlik numarasýný görev listesinden bulur ve geri döndürür
 ==============================================================================}
function TGorevler.GorevBul(AGorevKimlik: TKimlik): TGorev;
var
  G: TGorev;
  i: TSayi4;
begin

  // tüm görev giriþlerini incele
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    G := Gorev[i];

    // eðer görev giriþi boþ ise
    if not(G = nil) and (G.FDurum = gdCalisiyor) and (G.FKimlik = AGorevKimlik) then
      Exit(G);
  end;

  Result := nil;
end;

{==============================================================================
  görev sýra numarasýna sahip görevi alýr ve geri döndürür
 ==============================================================================}
function TGorevler.GorevAl(AGorevKimlik: TKimlik = -1): TGorev;
begin

  if(AGorevKimlik = -1) then
    Result := Gorev[FAktifGrv]
  else Result := Gorev[AGorevKimlik];
end;

{==============================================================================
  görevin yeni çalýþma durumunu belirler
 ==============================================================================}
procedure TGorevler.DurumDegistir(AGorevKimlik: TKimlik; AGorevDurum: TGorevDurum);
var
  G: TGorev;
begin

  G := Gorev[AGorevKimlik];
  if(G = nil) then Exit;

  if(G.FDurum <> AGorevDurum) then G.FDurum := AGorevDurum;
end;

{==============================================================================
  görev sayacýný belirler
 ==============================================================================}
procedure TGorevler.GorevSayaciYaz(AGorevKimlik: TKimlik; ASayacDegeri: TSayi4);
var
  G: TGorev;
begin

  G := Gorev[AGorevKimlik];
  if(G = nil) then Exit;

  G.FGrvSayac := ASayacDegeri;
end;

{==============================================================================
  görevi sonlandýrma amaçlý iþaretler
  bilgi: görev sonlandýrmasý hemen gerçekleþmez (çekirdek tarafýndan yapýlýr)
 ==============================================================================}
procedure TGorevler.Isaretle(AGorevKimlik: TKimlik; const ASonlanmaSebebi: TISayi4 = -1);
var
  G: TGorev;
begin

  G := Gorev[AGorevKimlik];
  if(G = nil) then Exit;

  G.FDurum := gdSonlandiriliyor;
  G.FHataKodu := -1;
  G.FHataESP := -1;
end;

{==============================================================================
  çalýþan görevi sonlandýrýr
  bilgi: iþlev çekirdek tarafýndan çaðrýlýr
 ==============================================================================}
function TGorevler.Sonlandir(AGorevKimlik: TKimlik; const ASonlanmaSebebi: TISayi4 = -1): TISayi4;
var
  G: TGorev;
begin

//  while KritikBolgeyeGir(GorevKilit) = False do;

  G := Gorev[AGorevKimlik];
  if(G = nil) then
  begin

//    KritikBolgedenCik(GorevKilit);
    Result := 1;
    Exit;
  end;

  // görevin sonlandýrýlma bilgisini ver
  if(ASonlanmaSebebi = -1) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_PEMBE, 'GOREV.PAS: ' + G.FDosyaAdi + ' normal bir þekilde sonlandýrýldý...', []);
  end
  else
  begin

    SISTEM_MESAJ(mtHata, RENK_PEMBE, 'GOREV.PAS: ' + G.FDosyaAdi +
      ' programý istenmeyen bir iþlem yaptýðýndan dolayý sonlandýrýldý', []);
    SISTEM_MESAJ(mtHata, RENK_TURKUAZ, '  - Hata Kodu: ' + IntToStr(ASonlanmaSebebi) + ' - ' +
      IstisnaAciklamaListesi[ASonlanmaSebebi], []);
    SISTEM_MESAJ(mtHata, RENK_TURKUAZ, '  - CS: $%.8x', [G.FHataCS]);
    SISTEM_MESAJ(mtHata, RENK_TURKUAZ, '  - EIP: $%.8x', [G.FHataEIP]);
    SISTEM_MESAJ(mtHata, RENK_TURKUAZ, '  - ESP: $%.8x', [G.FHataESP]);
    SISTEM_MESAJ(mtHata, RENK_TURKUAZ, '  - EFLAGS: $%.8x', [G.FHataBayrak]);
  end;

  // göreve ait zamanlayýcýlarý durdur
  GZamanlayicilar.ZamanlayicilariDurdur(AGorevKimlik);

  // göreve ait pencere ve alt görsel nesneleri yok et
  GGNesneler.PencereyiYokEt(AGorevKimlik);

  // göreve ait zamanlayýcýlarý yok et
  GZamanlayicilar.ZamanlayicilariYokEt(AGorevKimlik);

  // göreve ait olay bellek bölgesini iptal et
  { TODO : 1. bu iþlev olay yönetim sistem nesnesinin içerisine dahil edilecek
           2. olay bellek bölgesi iptal edilmeden önce önceden oluþturulan olaylar da kayýtlardan çýkarýlacak }
  FreeMem(G.FOlayBellekAdresi, 4096);

  // görev için ayrýlan bellek bölgesini serbest býrak
  FreeMem(Isaretci(G.FBellekBaslAdr), G.FBellekUz + G.FYiginBellekUz);

  // görevi iþlem listesinden çýkart
  Gorev[G.FKimlik] := nil;

  // görev için oluþturulan yapýyý yok et
  G.Destroy;

  // görev sayýsýný bir azalt
  Dec(FCalisanGorevSayisi);

  // görev bayrak deðerini artýr
  Inc(FGorevBayrakDegeri);

  Result := 0;

//  KritikBolgedenCik(GorevKilit);
end;

{==============================================================================
  çalýþtýrýlacak bir sonraki görevi bulur
 ==============================================================================}
function TGorevler.CalisacakYeniGoreviBul: TKimlik;
var
  G: TGorev;
  GorevKimlik: TKimlik;
  i: TISayi4;
begin

  // çalýþan göreve konumlan
  GorevKimlik := FAktifGrv;

  // bir sonraki görevden itibaren tüm görevleri incele
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    Inc(GorevKimlik);
    if(GorevKimlik > USTSINIR_GOREVSAYISI) then GorevKimlik := 0;

    G := Gorev[GorevKimlik];

    // çalýþan görev aranan görev ise çaðýran iþleve geri dön
    if not(G = nil) and (G.FDurum = gdCalisiyor) then Break;
  end;

  Result := GorevKimlik;
end;

{==============================================================================
  pencereye sahip görev sayýsýný alýr
 ==============================================================================}
function TGorevler.PencereSahipGorevSayisiniAl(AMasaustuKimlik: TKimlik = -1): TSayi4;
var
  G: TGorev;
  i: TISayi4;
begin

  Result := 0;

  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    G := Gorev[i];

    // 1. görev boþ deðilse
    // 2. pencereye sahip ise
    // 3. pencere tipi baþlýksýz deðilse
    if not(G = nil) and not(G.FAktifPencere = nil) and
      not(TPencere(G.FAktifPencere).FPencereTipi = ptBasliksiz) then
    begin

      if(AMasaustuKimlik = -1) then
        Inc(Result)
      else if(G.FAktifMasaustu.Kimlik = AMasaustuKimlik) then
        Inc(Result);
    end;
  end;
end;

{==============================================================================
  pencereye sahip görev ile ilgili bilgi alýr
 ==============================================================================}
function TGorevler.PencereSahipGorevBilgisiAl(AGorevSiraNo: TISayi4;
  AMasaustuKimlik: TKimlik = -1): TProgramKayit;
var
  G: TGorev;
  i, ArananGorev: TISayi4;
begin

  ArananGorev := -1;

  Result.PencereKimlik := HATA_KIMLIK;

  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    G := Gorev[i];

    // 1. görev boþ deðilse
    // 2. pencereye sahip ise
    // 3. pencere tipi baþlýksýz deðilse
    if not(G = nil) and not(G.FAktifPencere = nil) and
      not(TPencere(G.FAktifPencere).FPencereTipi = ptBasliksiz) then
    begin

      if(AMasaustuKimlik = -1) then
        Inc(ArananGorev)
      else if(G.FAktifMasaustu.Kimlik = AMasaustuKimlik) then
        Inc(ArananGorev);
    end;

    // görev sýra no aranan görev ise iþlem bellek bölgesini geri döndür
    if(AGorevSiraNo = ArananGorev) then
    begin

      Result.PencereKimlik := TPencere(G.FAktifPencere).Kimlik;
      Result.GorevKimlik := G.FKimlik;
      Result.PencereTipi := TPencere(G.FAktifPencere).FPencereTipi;
      Result.PencereDurum := TPencere(G.FAktifPencere).FPencereDurum;
      Result.DosyaAdi := G.FDosyaAdi;
      Exit;
    end;
  end;
end;

{==============================================================================
  görev bellek sýra numarasýný geri döndürür
 ==============================================================================}
function TGorevler.GorevSiraNumarasiniAl(AGorevSiraNo: TISayi4): TKimlik;
var
  G: TGorev;
  i, j: TISayi4;
begin

  // aranacak görev sýra numarasý
  j := -1;

  // tüm iþlem bellek bölgelerini araþtýr
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    G := Gorev[i];

    // görev çalýþýyor ise görev sýra numarasýný bir artýr
    if not(G = nil) and (G.FDurum = gdCalisiyor) then Inc(j);

    // görev sýra no aranan görev ise iþlem bellek bölgesini geri döndür
    if(AGorevSiraNo = j) then Exit(i);
  end;

  Result := -1;
end;

{==============================================================================
  sýralý olarak belli sýradaki (silinmiþ görevler hariç) görevi geri döndürür
 ==============================================================================}
function TGorevler.GorevBilgisiAl(AGorevSiraNo: TISayi4): TGorev;
var
  G: TGorev;
  i, j: TISayi4;
begin

  // aranacak görev sýra numarasý
  j := -1;

  // tüm iþlem bellek bölgelerini araþtýr
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    G := Gorev[i];

    // listenin ilgili sýrasýnda görev mevcut ise görev sýra numarasýný bir artýr
    if not(G = nil) then Inc(j);

    // görev sýra no aranan görev ise iþlem bellek bölgesini geri döndür
    if(AGorevSiraNo = j) then Exit(G);
  end;

  Result := nil;
end;

{==============================================================================
  sonlandýrma amaçlý iþaretlenen görevleri sonlandýrýr
  bilgi: görev (uygulama) öncelikle sonlandýrýlmak için iþaretlenir daha sonra çekirdek
    tarafýndan sonlandýrýlýr
 ==============================================================================}
procedure TGorevler.IsaretlenenGorevleriSonlandir;
var
  G: TGorev;
  i: TISayi4;
begin

//  while KritikBolgeyeGir(GorevKilit) = False do;

  // bellek giriþlerini görev yapýlarýyla eþleþtir
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    G := Gorev[i];
    if not(G = nil) and (G.FDurum = gdSonlandiriliyor) then
      Sonlandir(G.FKimlik, G.FHataKodu);
  end;

//  KritikBolgedenCik(GorevKilit);
end;

{==============================================================================
  görev bayrak deðerini al
  bilgi: bu deðer, her program çalýþtýrma ve sonlandýrmada deðiþen bayrak deðeridir
    t deðerinden t + 1 deðerine kadar "çalýþan program sayýsýnda" deðiþiklik olmasa bile
    baþlama ve sonlandýrma bazlý deðiþimleri yakalamak amaçlýdýr
 ==============================================================================}
function TGorevler.GorevBayrakDegeriniAl: TSayi4;
begin

  Result := FGorevBayrakDegeri;
end;

{==============================================================================
  dosya uzantýsý ile iliþkili program tanýmlarýný geri döndürür
 ==============================================================================}
function TGorevler.IliskiliProgramAl(ADosyaUzanti: string): TDosyaIliskisi;
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

end.
