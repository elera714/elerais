{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: gorev.pas
  Dosya Ýþlevi: görev (program) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 29/05/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gorev;

interface

uses paylasim, gn_masaustu, gn_pencere;

const
  // bir görev için tanýmlanan üst sýnýr olay sayýsý
  // olay belleði 4K olarak tanýmlanmýþtýr. 4096 / SizeOf(TOlay)
  USTSINIR_OLAY         = 64;
  PROGRAM_YIGIN_BELLEK  = (4096 * 5) - 1;             // program yýðýný (stack) için ayrýlacak bellek
  DEFTER_BELLEK_U       = TSayi4((4096 * 10) - 1);    // defter programý için program belleðinde ayrýlacak alan

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
  TGorev = object
  private
    FBellekUzunlugu: TSayi4;              // iþlemin kullandýðý bellek uzunluðu
    FKodBaslangicAdres: TSayi4;           // iþlemin bellek baþlangýç adresi
    FYiginBaslangicAdres: TSayi4;         // iþlemin yýðýn adresi
    FAktifMasaustu: PMasaustu;            // görevin aktif masaüstü
    FAktifPencere: PPencere;              // görevin aktif penceresi
    procedure GorevSayaciYaz(ASayacDegeri: TSayi4);
    procedure OlaySayisiYaz(AOlaySayisi: TSayi4);
  protected
    function Olustur: PGorev;
    function BosGorevBul: PGorev;
    procedure SecicileriOlustur;
  public
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

    FGorevSayaci: TSayi4;                 // görev deðiþim sayacý
    FBellekBaslangicAdresi: TSayi4;       // iþlemin yüklendiði bellek adresi
    FDosyaAdi,                            // görevin yüklendiði dosya adý
    FProgramAdi: string;                  // program adý
    procedure Yukle;
    function Calistir(ATamDosyaYolu: string): PGorev;
    procedure DurumDegistir(AGorevKimlik: TKimlik; AGorevDurum: TGorevDurum);
    procedure OlayEkle(AGorevKimlik: TKimlik; AOlay: TOlay);
    function OlayAl(var AOlay: TOlay): Boolean;
    procedure Isaretle(AGorevKimlik: TKimlik; const ASonlanmaSebebi: TISayi4 = -1);
    function Sonlandir(AGorevKimlik: TKimlik; const ASonlanmaSebebi: TISayi4 = -1): TISayi4;
    function GorevBul(AGorevKimlik: TKimlik): PGorev;
    function GorevKimligiAl(AGorevAdi: string): TKimlik;
    property OlayBellekAdresi: POlay read FOlayBellekAdresi write FOlayBellekAdresi;
    property AktifMasaustu: PMasaustu read FAktifMasaustu write FAktifMasaustu;
    property AktifPencere: PPencere read FAktifPencere write FAktifPencere;
  published
    property GorevKimlik: TKimlik read FGorevKimlik;
    property BellekBaslangicAdresi: TSayi4 read FBellekBaslangicAdresi write FBellekBaslangicAdresi;
    property BellekUzunlugu: TSayi4 read FBellekUzunlugu write FBellekUzunlugu;
    property KodBaslangicAdres: TSayi4 read FKodBaslangicAdres write FKodBaslangicAdres;
    property YiginBaslangicAdres: TSayi4 read FYiginBaslangicAdres write FYiginBaslangicAdres;
    property GorevSayaci: TSayi4 read FGorevSayaci write GorevSayaciYaz;
    property OlaySayisi: TSayi4 read FOlaySayisi write OlaySayisiYaz;
  end;

function GorevBilgisiAl(AGorevSiraNo: TISayi4): PGorev;
function CalisanProgramSayisiniAl(AMasaustuKimlik: TKimlik = -1): TSayi4;
function GorevBayrakDegeriniAl: TSayi4;
function CalisanProgramBilgisiAl(AGorevSiraNo: TISayi4; AMasaustuKimlik: TKimlik = -1): TProgramKayit;
function GorevSiraNumarasiniAl(AGorevSiraNo: TISayi4): TKimlik;
function CalistirilacakBirSonrakiGoreviBul: TKimlik;
function IliskiliProgramAl(ADosyaUzanti: string): TDosyaIliskisi;
procedure IsaretlenenGorevleriSonlandir;

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

{==============================================================================
  çalýþtýrýlacak görevlerin ana yükleme iþlevlerini içerir
 ==============================================================================}
procedure TGorev.Yukle;
var
  Gorev: PGorev;
  i: TISayi4;
begin

  // görev bilgilerinin yerleþtirilmesi için bellek ayýr
  Gorev := GGercekBellek.Ayir(SizeOf(TGorev) * USTSINIR_GOREVSAYISI);

  // bellek giriþlerini görev yapýlarýyla eþleþtir
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    GorevListesi[i] := Gorev;

    // görevi boþ olarak belirle
    Gorev^.FGorevDurum := gdBos;
    Gorev^.FDosyaSonIslemDurum := HATA_DOSYA_ISLEM_BASARILI;
    Gorev^.FGorevKimlik := i;
    Gorev^.FAktifMasaustu := nil;
    Gorev^.FAktifPencere := nil;

    Inc(Gorev);
  end;
end;

{==============================================================================
  görev (program) dosyalarýný çalýþtýrýr
 ==============================================================================}
var
  CalistirGorevNo: TSayi4 = 0;

function TGorev.Calistir(ATamDosyaYolu: string): PGorev;
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

  asm cli end;

  if(CalistirGorevNo <> 0) then while CalistirGorevNo <> 0 do;

  CalistirGorevNo := CalisanGorev;

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
      CalistirGorevNo := 0;
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
      CalistirGorevNo := 0;
      asm sti end;
      Exit;
    end;

    // dosyayý kapat
    CloseFile(DosyaKimlik);

    // boþ iþlem giriþi bul
    Gorev := Gorev^.Olustur;
    if(Gorev = nil) then
    begin

      SISTEM_MESAJ(mtHata, RENK_SIYAH, 'GOREV.PAS: ' + ATamDosyaYolu + ' için görev oluþturulamýyor!', []);
      Result := nil;
      CalistirGorevNo := 0;
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
      CalistirGorevNo := 0;
      asm sti end;
      Exit;
    end;

    // olay iþlemleri için bellekte yer ayýr
    Olay := GetMem(4096);
    if(Olay = nil) then
    begin

      SISTEM_MESAJ(mtHata, RENK_SIYAH, 'GOREV.PAS: olay bilgisi için bellek ayrýlamýyor!', []);
      Result := nil;
      CalistirGorevNo := 0;
      asm sti end;
      Exit;
    end;

    // bellek baþlangýç adresi
    Gorev^.FBellekBaslangicAdresi := TSayi4(DosyaBellek);

    // bellek miktarý
    Gorev^.FBellekUzunlugu := ProgramBellekU;

    // iþlem baþlangýç adresi
    Gorev^.FKodBaslangicAdres := ELFBaslik^.KodBaslangicAdresi;

    // iþlemin yýðýn adresi
    if(DosyaAdi = 'defter.c') then
      Gorev^.FYiginBaslangicAdres := (ProgramBellekU - DEFTER_BELLEK_U) - 512
    else Gorev^.FYiginBaslangicAdres := ProgramBellekU - 512;

    // dosyanýn çalýþtýrýlmasý için seçicileri oluþtur
    Gorev^.SecicileriOlustur;

    // görev deðiþim sayacýný sýfýrla
    Gorev^.FGorevSayaci := 0;

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

    CalistirGorevNo := 0;
  end
  else
  begin

    CloseFile(DosyaKimlik);
    SISTEM_MESAJ(mtHata, RENK_SIYAH, 'GOREV.PAS: ' + TamDosyaYolu + ' dosya okuma hatasý!', []);
  end;

  CalistirGorevNo := 0;

  asm sti end;
end;

{==============================================================================
  çalýþacak görev için boþ görev bul
 ==============================================================================}
function TGorev.Olustur: PGorev;
var
  Gorev: PGorev;
begin

  // boþ iþlem giriþi bul
  Gorev := Gorev^.BosGorevBul;

  Result := Gorev;
end;

{==============================================================================
  çalýþacak görev için boþ görev bul
 ==============================================================================}
function TGorev.BosGorevBul: PGorev;
var
  Gorev: PGorev;
  i: TSayi4;
begin

  // tüm iþlem giriþlerini incele - ilk 3 görev (0, 1, 2) giriþi sisteme ayrýldý
  for i := AYRILMIS_GOREV_SAYISI to USTSINIR_GOREVSAYISI - 1 do
  begin

    Gorev := GorevListesi[i];

    // eðer görev giriþi boþ ise
    if(Gorev^.FGorevDurum = gdBos) then
    begin

      // görev giriþini ayrýlmýþ olarak iþaretle ve çaðýran iþleve geri dön
      Gorev^.DurumDegistir(i, gdOlusturuldu);
      Exit(Gorev);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  görev için TSS seçicilerini (selektör) oluþturur
 ==============================================================================}
procedure TGorev.SecicileriOlustur;
var
  SeciciCSSiraNo, SeciciDSSiraNo,
  SeciciTSSSiraNo: TKimlik;
  Uzunluk, i: TSayi4;
begin

  // uygulamanýn ilk görev kimliði 3 (olan muyntcs.c)'tür
  i := GorevKimlik;

  Uzunluk := FBellekUzunlugu shr 12;

  // uygulamanýn TSS, CS, DS seçicilerini belirle, her bir program 3 seçici içerir
  SeciciCSSiraNo := ((i - (AYRILMIS_GOREV_SAYISI)) * 3) + AYRILMIS_SECICISAYISI;
  SeciciDSSiraNo := SeciciCSSiraNo + 1;
  SeciciTSSSiraNo := SeciciDSSiraNo + 1;

  // uygulama için CS selektörünü oluþtur
  // kod seçicisi (CS)
  // Eriþim  : 1 = mevcut, 11 = DPL3, 11 = kod segment, 0 = dallanýlamaz, 1 = okunabilir, 0 = eriþilmedi
  // Esneklik: 1 = gran = 4K çözünürlük, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SeciciCSSiraNo, FBellekBaslangicAdresi, Uzunluk, %11111010, %11010000);
  // uygulama için DS selektörünü oluþtur
  // veri seçicisi (DS)
  // Eriþim  : 1 = mevcut, 11 = DPL3, 10 = veri yazmaç, 0 = artarak büyüyen, 1 = yazýlabilir, 0 = eriþilmedi
  // Esneklik: 1 = gran = 4K çözünürlük, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SeciciDSSiraNo, FBellekBaslangicAdresi, Uzunluk, %11110010, %11010000);
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
  GorevTSSListesi[i]^.EIP := FKodBaslangicAdres;
  GorevTSSListesi[i]^.EFLAGS := $202;
  GorevTSSListesi[i]^.ESP := FYiginBaslangicAdres;
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
procedure TGorev.DurumDegistir(AGorevKimlik: TKimlik; AGorevDurum: TGorevDurum);
var
  Gorev: PGorev;
begin

  Gorev := GorevListesi[AGorevKimlik];
  if(AGorevDurum <> Gorev^.FGorevDurum) then Gorev^.FGorevDurum := AGorevDurum;
end;

{==============================================================================
  görev sayacýný belirler
 ==============================================================================}
procedure TGorev.GorevSayaciYaz(ASayacDegeri: TSayi4);
begin

  if(ASayacDegeri <> FGorevSayaci) then FGorevSayaci := ASayacDegeri;
end;

{==============================================================================
  görevin olay sayýsýný belirler
 ==============================================================================}
procedure TGorev.OlaySayisiYaz(AOlaySayisi: TSayi4);
begin

  if(AOlaySayisi <> FOlaySayisi) then FOlaySayisi := AOlaySayisi;
end;

{==============================================================================
  çekirdek tarafýndan görev için oluþturulan olayý kaydeder
 ==============================================================================}
procedure TGorev.OlayEkle(AGorevKimlik: TKimlik; AOlay: TOlay);
var
  Gorev: PGorev;
  Olay: POlay;
begin

  Gorev := GorevListesi[AGorevKimlik];

  if(Gorev^.FGorevDurum = gdCalisiyor) then
  begin

    // olay belleði dolu deðilse olayý kaydet
    if(Gorev^.OlaySayisi < USTSINIR_OLAY) then
    begin

      // iþlemin olay belleðine konumlan
      Olay := Gorev^.OlayBellekAdresi;
      Inc(Olay, Gorev^.OlaySayisi);

      // olayý iþlem belleðine kaydet
      Olay^.Kimlik := AOlay.Kimlik;
      Olay^.Olay := AOlay.Olay;
      Olay^.Deger1 := AOlay.Deger1;
      Olay^.Deger2 := AOlay.Deger2;

      // görevin olay sayacýný artýr
      Gorev^.OlaySayisi := Gorev^.OlaySayisi + 1;
    end;
  end;
end;

{==============================================================================
  görev için (çekirdek tarafýndan) oluþturulan olayý alýr
 ==============================================================================}
function TGorev.OlayAl(var AOlay: TOlay): Boolean;
var
  Olay1, Olay2: POlay;
  i: TSayi4;
begin

  // öndeðer çýkýþ deðeri
  Result := False;

  i := OlaySayisi;

  // görev için oluþturulan olay yoksa çýk
  if(i = 0) then Exit;

  // öndeðer çýkýþ deðeri
  Result := True;

  // görevin olay belleðine konumlan
  Olay1 := OlayBellekAdresi;

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
    OlaySayisi := i;

    Exit;
  end;

  // olayý görevin olay belleðinden sil
  Olay2 := Olay1;
  Inc(Olay2);

  Tasi2(Olay2, Olay1, SizeOf(TOlay) * i);

  // olay sayacýný azalt
  OlaySayisi := i;
end;

{==============================================================================
  çalýþan görevi sonlandýrýr
 ==============================================================================}
function TGorev.Sonlandir(AGorevKimlik: TKimlik; const ASonlanmaSebebi: TISayi4 = -1): TISayi4;
var
  Gorev: PGorev = nil;
begin

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
  FreeMem(Gorev^.OlayBellekAdresi, 4096);

  // görev için ayrýlan bellek bölgesini serbest býrak
  FreeMem(Isaretci(Gorev^.BellekBaslangicAdresi), Gorev^.BellekUzunlugu);

  // görevi iþlem listesinden çýkart
  DurumDegistir(AGorevKimlik, gdBos);

  // görev sayýsýný bir azalt
  Dec(CalisanGorevSayisi);

  // görev bayrak deðerini artýr
  Inc(GorevBayrakDegeri);

  Result := 0;
end;

procedure TGorev.Isaretle(AGorevKimlik: TKimlik; const ASonlanmaSebebi: TISayi4 = -1);
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
      else if(GorevListesi[i]^.AktifMasaustu^.Kimlik = AMasaustuKimlik) then
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
      else if(GorevListesi[i]^.AktifMasaustu^.Kimlik = AMasaustuKimlik) then
        Inc(ArananGorev);
    end;

    // görev sýra no aranan görev ise iþlem bellek bölgesini geri döndür
    if(AGorevSiraNo = ArananGorev) then
    begin

      Result.PencereKimlik := GorevListesi[i]^.FAktifPencere^.Kimlik;
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
function TGorev.GorevBul(AGorevKimlik: TKimlik): PGorev;
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
function TGorev.GorevKimligiAl(AGorevAdi: string): TKimlik;
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
  GorevKimlik := CalisanGorev;

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
      Gorev^.Sonlandir(Gorev^.FGorevKimlik, Gorev^.FHataKodu);
  end;
end;

end.
