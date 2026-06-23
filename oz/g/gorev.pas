{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: gorev.pas
  Dosya Ýþlevi: görev (program) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 22/06/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gorev;

interface

uses paylasim, gn_masaustu;

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
  PROGRAM_YIGIN_BELLEK  = TSayi4(5 * 4096);       // program yýðýný (stack) için ayrýlacak bellek (*4K)
  DEFTER_BELLEK_U       = TSayi4(10 * 4096);      // defter programý için program belleðinde ayrýlacak alan (*4K)

var
  { TODO - object yapýsýnýn içerisine dahil edilecek }
  FCalisanGorevSayisi: TSayi4;            // oluþturulan / çalýþan program sayýsý
  FAktifGorev: TISayi4;                   // o an çalýþan program
  FAktifGorevBellekAdresi: TSayi4;        // o an çalýþan programýn yüklendiði bellek adresi
  GorevDegisimSayisi: TSayi4 = 0;         // çekirdek baþladýðý andan itibaren gerçekleþtirilen görev deðiþim sayýsý
  GorevBayrakDegeri: TSayi4 = 0;          // her görev çalýþtýrma / sonlandýrma / aktifleþtirme durumunda 1 artýrýlýr

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
  TGorev = record
    Kimlik: TKimlik;                      // görev kimlik numarasý
    SeviyeNo: TSayi4;                     // görevin çalýþma seviye numarasý (0..3)
    Durum: TGorevDurum;                   // görev çalýþma durumu

    BellekBaslangicAdresi: TSayi4;        // görevin yüklendiði bellek baþlangýç adresi
    BellekUzunlugu: TSayi4;               // görevin kullandýðý bellek uzunluðu (*4K)
    YiginBellekUzunlugu: TSayi4;          // görev yýðýnýnýn bellek uzunluðu (*4K)
    KodBaslangicAdresi: TSayi4;           // görev kodlarýnýn ilk çalýþmaya baþlayacaðý bellek adresi
    YiginBaslangicAdresi: TSayi4;         // iþlemin yýðýn baþlangýç adresi

    AktifMasaustu: PMasaustu;             // görevin çalýþtýðý aktif masaüstü
    AktifPencere: PObject;                // görevin sahip olduðu pencere

    GorevSayaci: TSayi4;                  // zamanlayýcý her tetiklendiðinde artan görev deðiþim sayacý

    CalismaSuresiMS,                      // görevin çalýþacaðý süre (irq0 tick sayýsý)
    CalismaSuresiSayacMS: TSayi4;         // görevin çalýþacaðý sürenin sayaç deðeri

    OlayBellekAdresi: POlay;              // göreve ait olaylarýn yerleþtirileceði bellek bölgesi
    OlaySayisi: TSayi4;                   // görev olay sayýsý

    DosyaSonIslemDurum: TISayi4;          // göreve ait son dosya iþlem sonuç deðeri

    // hata ile ilgili deðerlerin yerleþtirileceði deðiþkenler
    HataKodu,                             // hata kodu
    HataCS, HataEIP,                      // cs:eip
    HataESP,                              // esp
    HataBayrak: TISayi4;                  // flags

//    KullanilanBellek: TSayi4;             // görevin byte olarak kullandýðý tüm kaynaklar toplamý (TODO - kodlanacak }

    DosyaAdi,                             // görev dosya adý
    ProgramAdi: string;                   // program adý
  end;

type
  TGorevler = object
  private
    FGorevListesi: array[0..USTSINIR_GOREVSAYISI - 1] of PGorev;
    function GorevAl(ASiraNo: TISayi4): PGorev;
    procedure GorevYaz(ASiraNo: TISayi4; AGorev: PGorev);
  public
    procedure Yukle;
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
    property Gorev[ASiraNo: TISayi4]: PGorev read GorevAl write GorevYaz;
  end;

var
  Gorevler0: TGorevler;
  GorevKilit: TSayi4 = 0;

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

uses gdt, dosya, sistemmesaj, donusum, zamanlayici, gn_islevler, gn_pencere, islevler,
  gorselnesne;

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

{==============================================================================
  çalýþtýrýlacak görevlerin ana yükleme iþlevlerini içerir
 ==============================================================================}
procedure TGorevler.Yukle;
var
  i: TISayi4;
begin

  // bellek giriþlerini görev yapýlarýyla eþleþtir
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do Gorev[i] := nil;
end;

function TGorevler.GorevAl(ASiraNo: TISayi4): PGorev;
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_GOREVSAYISI) then
    Result := FGorevListesi[ASiraNo]
  else Result := nil;
end;

procedure TGorevler.GorevYaz(ASiraNo: TISayi4; AGorev: PGorev);
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_GOREVSAYISI) then
    FGorevListesi[ASiraNo] := AGorev;
end;

{==============================================================================
  görev (program) dosyalarýný çalýþtýrýr
 ==============================================================================}
function TGorevler.Calistir(ATamDosyaYolu: string; ASeviyeNo: TSayi4): PGorev;
var
  G: PGorev;
  GeciciDosyaBellek,
  DosyaBellek: Isaretci;
  Olay: POlay;
  i, j, ProgramBellekU: TSayi4;
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

  { TODO - sistemin kilitlenmesine sebebiyet veriyor }
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
  if(DosyaUyari.Durum = False) or (GeciciDosyaBellek = nil) then
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'GOREV.PAS: ' + ATamDosyaYolu + ' için yeterli bellek yok!', []);
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
  // defter.c programýna verileri iþlemesi için fazladan 40K yer tahsis et
  if(DosyaAdi = 'defter.c') then ProgramBellekU := ProgramBellekU + DEFTER_BELLEK_U;

  GetMem(DosyaBellek, ProgramBellekU + PROGRAM_YIGIN_BELLEK);
  if(DosyaBellek = nil) then
  begin

    if not(GeciciDosyaBellek = nil) then FreeMem(GeciciDosyaBellek, DosyaUyari.Uzunluk);

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'GOREV.PAS: ' + ATamDosyaYolu + ' için yeterli bellek yok!', []);
    KritikBolgedenCik(GorevKilit);
    Exit(nil);
  end;

  // program dosyasýný çalýþacaðý hedef belleðe kopyala
  Tasi2(GeciciDosyaBellek, DosyaBellek, DosyaUyari.Uzunluk);

  // programýn kopyalandýðý önceki belleði serbest býrak
  if not(GeciciDosyaBellek = nil) then FreeMem(GeciciDosyaBellek, DosyaUyari.Uzunluk);

  // boþ iþlem giriþi bul
  G := Gorevler0.Olustur;
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
  G^.OlayBellekAdresi := Olay;

  // görev olay sayacýný sýfýrla
  G^.OlaySayisi := 0;

  // görev çalýþma seviye numarasý - öncelik derecesi
  G^.SeviyeNo := ASeviyeNo;

  // görev deðiþim sayacýný sýfýrla
  G^.GorevSayaci := 0;

  // bellek baþlangýç adresi
  G^.BellekBaslangicAdresi := TSayi4(DosyaBellek);

  // görev çalýþma süreleri
  G^.CalismaSuresiMS := 2;
  G^.CalismaSuresiSayacMS := 2;

  // bellek miktarý
  G^.BellekUzunlugu := ProgramBellekU;
  G^.YiginBellekUzunlugu := PROGRAM_YIGIN_BELLEK;

  // iþlem baþlangýç adresi
  G^.KodBaslangicAdresi := ELFBaslik^.KodBaslangicAdresi;

  //SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'A: %x', [G^.KodBaslangicAdresi]);

  // iþlemin yýðýn adresi
  G^.YiginBaslangicAdresi := (G^.BellekUzunlugu + G^.YiginBellekUzunlugu) - 64;

  // dosyanýn çalýþtýrýlmasý için seçicileri oluþtur
  Gorevler0.SecicileriOlustur(G^.Kimlik, G^.BellekUzunlugu + G^.YiginBellekUzunlugu,
    G^.BellekBaslangicAdresi, G^.KodBaslangicAdresi, G^.YiginBaslangicAdresi);

  // iþlemin adý
  G^.DosyaAdi := DosyaAdi;

  // program öndeðer adý
  G^.ProgramAdi := '';

  // deðiþken gönderimi
  // ilk deðiþken - çalýþan iþlemin adý

  // program bellek baþlangýcýnýn ilk 32 byte'ý çekirdeðin programa
  // bilgi vermesi amacýyla ayrýlmýþtýr.
  PSayi4(DosyaBellek + 00)^ := TSayi4(DosyaBellek);
  PSayi4(DosyaBellek + 04)^ := G^.BellekUzunlugu - DEFTER_BELLEK_U;

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
  G^.Durum := gdCalisiyor;

  // görev iþlem sayýsýný bir artýr
  Inc(FCalisanGorevSayisi);

  // görev bayrak deðerini artýr
  Inc(GorevBayrakDegeri);

  // programýn iz kayýt dosyasýný oluþtur
  {IzKayitDosyaAdi := DosyaAdiniAl(DosyaAdi);
  IzKayitDosyaAdi := IzKayitDosyaAdi + '.log'; //izkayit';
  IzKaydiOlustur(IzKayitDosyaAdi, IzKayitDosyaAdi + ' uygulamasý çalýþtýrýldý');}

  // görev bellek adresini geri döndür
  Result := G;

  KritikBolgedenCik(GorevKilit);
end;

{==============================================================================
  çalýþacak görev için boþ görev bul
 ==============================================================================}
function TGorevler.Olustur: PGorev;
var
  G: PGorev;
begin

  // boþ iþlem giriþi bul
  G := Gorevler0.BosGorevBul;

  Result := G;
end;

{==============================================================================
  çalýþacak görev için boþ görev bul
 ==============================================================================}
function TGorevler.BosGorevBul: PGorev;
var
  G: PGorev;
  i: TSayi4;
begin

  // tüm iþlem giriþlerini incele
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    G := Gorev[i];

    // eðer görev giriþi boþ ise
    if(G = nil) then
    begin

      G := GetMem(SizeOf(TGorev));
      Gorev[i] := G;

      // görevi boþ olarak belirle
      G^.Kimlik := i;
      G^.DosyaSonIslemDurum := HATA_DOSYA_ISLEM_BASARILI;
      G^.AktifMasaustu := nil;
      G^.AktifPencere := nil;

      // görev giriþini ayrýlmýþ olarak iþaretle ve çaðýran iþleve geri dön
      //Gorevler0.DurumDegistir(i, gdOlusturuldu);
      G^.Durum := gdOlusturuldu;
      Exit(G);
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
  G: PGorev;
begin

  G := Gorev[AGorevKimlik];
  if(G = nil) then Exit;

  if(G^.Durum <> AGorevDurum) then G^.Durum := AGorevDurum;
end;

{==============================================================================
  görev sayacýný belirler
 ==============================================================================}
procedure TGorevler.GorevSayaciYaz(AGorevKimlik: TKimlik; ASayacDegeri: TSayi4);
var
  G: PGorev;
begin

  G := Gorev[AGorevKimlik];
  if(G = nil) then Exit;

  if(G^.GorevSayaci <> ASayacDegeri) then G^.GorevSayaci := ASayacDegeri;
end;

{==============================================================================
  görevin olay sayýsýný belirler
 ==============================================================================}
procedure TGorevler.OlaySayisiYaz(AGorevKimlik: TKimlik; AOlaySayisi: TSayi4);
var
  G: PGorev;
begin

  G := Gorev[AGorevKimlik];
  if(G = nil) then Exit;

  if(G^.OlaySayisi <> AOlaySayisi) then G^.OlaySayisi := AOlaySayisi;
end;

{==============================================================================
  çekirdek tarafýndan görev için oluþturulan olayý kaydeder
 ==============================================================================}
procedure TGorevler.OlayEkle(AGorevKimlik: TKimlik; AOlay: TOlay);
var
  G: PGorev;
  Olay: POlay;
begin

  //while KritikBolgeyeGir(OlayKilit) = False do;

  G := Gorev[AGorevKimlik];
  if(G = nil) then
  begin

    KritikBolgedenCik(OlayKilit);
    Exit;
  end;

  // görev çalýþýyor ve olay bellek adresi tanýmlandýysa
  if(G^.Durum = gdCalisiyor) and not(G^.OlayBellekAdresi = nil) then
  begin

    // olay belleði dolu deðilse olayý kaydet
    if(G^.OlaySayisi < USTSINIR_OLAY) then
    begin

      // iþlemin olay belleðine konumlan
      Olay := G^.OlayBellekAdresi;
      Inc(Olay, G^.OlaySayisi);

      // olayý iþlem belleðine kaydet
      Olay^.Kimlik := AOlay.Kimlik;
      Olay^.Olay := AOlay.Olay;
      Olay^.Deger1 := AOlay.Deger1;
      Olay^.Deger2 := AOlay.Deger2;

      // görevin olay sayacýný artýr
      G^.OlaySayisi := G^.OlaySayisi + 1;
    end;
  end;

  //KritikBolgedenCik(OlayKilit);
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

  // öndeðer çýkýþ deðeri
  Result := False;

  G := Gorev[AKimlik];
  if(G = nil) then
  begin

    KritikBolgedenCik(OlayKilit);
    Exit;
  end;

  i := G^.OlaySayisi;

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
    G^.OlaySayisi := i;

    KritikBolgedenCik(OlayKilit);
    Exit;
  end;

  // olayý görevin olay belleðinden sil
  Olay2 := Olay1;
  Inc(Olay2);

  Tasi2(Olay2, Olay1, SizeOf(TOlay) * i);

  // olay sayacýný azalt
  G^.OlaySayisi := i;

  KritikBolgedenCik(OlayKilit);
end;

{==============================================================================
  çalýþan görevi sonlandýrýr
 ==============================================================================}
function TGorevler.Sonlandir(AGorevKimlik: TKimlik; const ASonlanmaSebebi: TISayi4 = -1): TISayi4;
var
  G: PGorev = nil;
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

    SISTEM_MESAJ(mtBilgi, RENK_PEMBE, 'GOREV.PAS: ' + G^.DosyaAdi + ' normal bir þekilde sonlandýrýldý...', []);
  end
  else
  begin

    SISTEM_MESAJ(mtHata, RENK_PEMBE, 'GOREV.PAS: ' + G^.DosyaAdi +
      ' programý istenmeyen bir iþlem yaptýðýndan dolayý sonlandýrýldý', []);
    SISTEM_MESAJ(mtHata, RENK_TURKUAZ, '  - Hata Kodu: ' + IntToStr(ASonlanmaSebebi) + ' - ' +
      IstisnaAciklamaListesi[ASonlanmaSebebi], []);
    SISTEM_MESAJ(mtHata, RENK_TURKUAZ, '  - CS: $%.8x', [G^.HataCS]);
    SISTEM_MESAJ(mtHata, RENK_TURKUAZ, '  - EIP: $%.8x', [G^.HataEIP]);
    SISTEM_MESAJ(mtHata, RENK_TURKUAZ, '  - ESP: $%.8x', [G^.HataESP]);
    SISTEM_MESAJ(mtHata, RENK_TURKUAZ, '  - EFLAGS: $%.8x', [G^.HataBayrak]);
  end;

  // göreve ait zamanlayýcýlarý durdur
  ZamanlayicilariDurdur(AGorevKimlik);

  // göreve ait pencere ve alt görsel nesneleri yok et
  GorselNesneler0.PencereyiYokEt(AGorevKimlik);

  // göreve ait zamanlayýcýlarý yok et
  ZamanlayicilariYokEt(AGorevKimlik);

  // göreve ait olay bellek bölgesini iptal et
  { TODO : 1. bu iþlev olay yönetim sistem nesnesinin içerisine dahil edilecek
           2. olay bellek bölgesi iptal edilmeden önce önceden oluþturulan olaylar da kayýtlardan çýkarýlacak }
  FreeMem(G^.OlayBellekAdresi, 4096);

  // görev için ayrýlan bellek bölgesini serbest býrak
  FreeMem(Isaretci(G^.BellekBaslangicAdresi), G^.BellekUzunlugu + G^.YiginBellekUzunlugu);

  // görevi iþlem listesinden çýkart
  Gorev[G^.Kimlik] := nil;
  FreeMem(G, SizeOf(TGorev));

  // görev sayýsýný bir azalt
  Dec(FCalisanGorevSayisi);

  // görev bayrak deðerini artýr
  Inc(GorevBayrakDegeri);

  Result := 0;

//  KritikBolgedenCik(GorevKilit);
end;

procedure TGorevler.Isaretle(AGorevKimlik: TKimlik; const ASonlanmaSebebi: TISayi4 = -1);
var
  G: PGorev;
begin

  G := Gorev[AGorevKimlik];
  if(G = nil) then Exit;

  G^.Durum := gdSonlandiriliyor;
  G^.HataKodu := -1;
  G^.HataESP := -1;
end;

{==============================================================================
  görev ile ilgili bellek bölgesini geri döndürür
 ==============================================================================}
function GorevBilgisiAl(AGorevSiraNo: TISayi4): PGorev;
var
  G: PGorev;
  i, j: TISayi4;
begin

  // aranacak görev sýra numarasý
  j := -1;

  // tüm iþlem bellek bölgelerini araþtýr
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    G := Gorevler0.Gorev[i];

    // listenin ilgili sýrasýnda görev mevcut ise görev sýra numarasýný bir artýr
    if not(G = nil) then Inc(j);

    // görev sýra no aranan görev ise iþlem bellek bölgesini geri döndür
    if(AGorevSiraNo = j) then Exit(G);
  end;

  Result := nil;
end;

{==============================================================================
  pencereye sahip görev sayýsýný alýr
 ==============================================================================}
function CalisanProgramSayisiniAl(AMasaustuKimlik: TKimlik = -1): TSayi4;
var
  G: PGorev;
  i: TISayi4;
begin

  Result := 0;

  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    G := Gorevler0.Gorev[i];

    // 1. görev boþ deðilse
    // 2. pencereye sahip ise
    // 3. pencere tipi baþlýksýz deðilse
    if not(G = nil) and not(G^.AktifPencere = nil) and
      not(PPencere(G^.AktifPencere)^.FPencereTipi = ptBasliksiz) then
    begin

      if(AMasaustuKimlik = -1) then
        Inc(Result)
      else if(G^.AktifMasaustu^.Kimlik = AMasaustuKimlik) then
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
  G: PGorev;
  i, ArananGorev: TISayi4;
begin

  ArananGorev := -1;

  Result.PencereKimlik := HATA_KIMLIK;

  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    G := Gorevler0.Gorev[i];

    // 1. görev boþ deðilse
    // 2. pencereye sahip ise
    // 3. pencere tipi baþlýksýz deðilse
    if not(G = nil) and not(G^.AktifPencere = nil) and
      not(PPencere(G^.AktifPencere)^.FPencereTipi = ptBasliksiz) then
    begin

      if(AMasaustuKimlik = -1) then
        Inc(ArananGorev)
      else if(G^.AktifMasaustu^.Kimlik = AMasaustuKimlik) then
        Inc(ArananGorev);
    end;

    // görev sýra no aranan görev ise iþlem bellek bölgesini geri döndür
    if(AGorevSiraNo = ArananGorev) then
    begin

      Result.PencereKimlik := PPencere(G^.AktifPencere)^.Kimlik;
      Result.GorevKimlik := G^.Kimlik;
      Result.PencereTipi := PPencere(G^.AktifPencere)^.FPencereTipi;
      Result.PencereDurum := PPencere(G^.AktifPencere)^.FPencereDurum;
      Result.DosyaAdi := G^.DosyaAdi;
      Exit;
    end;
  end;
end;

{==============================================================================
  görev kimlik numarasýna göre görev aramasý yapar
 ==============================================================================}
function TGorevler.GorevBul(AGorevKimlik: TKimlik): PGorev;
var
  G: PGorev;
  i: TSayi4;
begin

  // tüm görev giriþlerini incele
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    G := Gorev[i];

    // eðer görev giriþi boþ ise
    if not(G = nil) and (G^.Durum = gdCalisiyor) and (G^.Kimlik = AGorevKimlik) then
      Exit(G);
  end;

  Result := nil;
end;

{==============================================================================
  görev adýndan görev kimlik numarasýný alýr
 ==============================================================================}
function TGorevler.GorevKimligiAl(AGorevAdi: string): TKimlik;
var
  G: PGorev;
  i: TSayi4;
begin

  // tüm iþlem bellek bölgelerini araþtýr
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    G := Gorev[i];

    // görev boþ deðil ise görev sýra numarasýný bir artýr
    if not(G = nil) and (G^.DosyaAdi = AGorevAdi) then Exit(G^.Kimlik);
  end;

  Result := -1;
end;

{==============================================================================
  görev bellek sýra numarasýný geri döndürür
 ==============================================================================}
function GorevSiraNumarasiniAl(AGorevSiraNo: TISayi4): TKimlik;
var
  G: PGorev;
  i, j: TISayi4;
begin

  // aranacak görev sýra numarasý
  j := -1;

  // tüm iþlem bellek bölgelerini araþtýr
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    G := Gorevler0.Gorev[i];

    // görev çalýþýyor ise görev sýra numarasýný bir artýr
    if not(G = nil) and (G^.Durum = gdCalisiyor) then Inc(j);

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
  G: PGorev;
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

    G := Gorevler0.Gorev[GorevKimlik];

    // çalýþan görev aranan görev ise çaðýran iþleve geri dön
    if not(G = nil) and (G^.Durum = gdCalisiyor) then Break;
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
  G: PGorev;
  i: TISayi4;
begin

//  while KritikBolgeyeGir(GorevKilit) = False do;

  // bellek giriþlerini görev yapýlarýyla eþleþtir
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    G := Gorevler0.Gorev[i];
    if not(G = nil) and (G^.Durum = gdSonlandiriliyor) then
      Gorevler0.Sonlandir(G^.Kimlik, G^.HataKodu);
  end;

//  KritikBolgedenCik(GorevKilit);
end;

{==============================================================================
  görev için belli bir görevi yerine getiren iþlev oluþturur - (thread)
  bilgi: saçma sapan kelime olan thread kelimesini kullanmayý uygun bulmuyorum
 ==============================================================================}
function Memur(AGorevAdi: string; AIslev: TIslev; AYiginDegeri: TSayi4; ASeviyeNo: TSayi4): TSayi4;
var
  G: PGorev;
  // yazmaçlarýn girdi içerisindeki sýra numaralarý
  SNYazmacCS, SNYazmacDS, SNYazmacTSS,
  i: TSayi4;
begin

  while KritikBolgeyeGir(GorevKilit) = False do;

  G := Gorevler0.BosGorevBul;
  if not(G = nil) then
  begin

    i := G^.Kimlik;

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
    G^.SeviyeNo := ASeviyeNo;
    G^.GorevSayaci := 0;
    G^.BellekBaslangicAdresi := TSayi4(@AIslev);
    G^.CalismaSuresiMS := 20;
    G^.CalismaSuresiSayacMS := 20;
    G^.BellekUzunlugu := $FFFFFFFF;
    G^.OlaySayisi := 0;
    G^.OlayBellekAdresi := nil;
    G^.AktifMasaustu := nil;
    G^.AktifPencere := nil;

    // sistem görev adý (dosya adý)
    G^.DosyaAdi := 'cekirdek.bin';
    G^.ProgramAdi := AGorevAdi;

    // sistem görevini çalýþýyor olarak iþaretle
    Gorevler0.DurumDegistir(i, gdCalisiyor);

    // çalýþan ve oluþturulan görev deðerlerini belirle
    Inc(FCalisanGorevSayisi);

    Result := SNYazmacCS;
  end;

  KritikBolgedenCik(GorevKilit);
end;

function GorevAl(AGorevKimlik: TKimlik = -1): PGorev;
begin

  if(AGorevKimlik = -1) then
    Result := Gorevler0.Gorev[FAktifGorev]
  else Result := Gorevler0.Gorev[AGorevKimlik];
end;

end.
