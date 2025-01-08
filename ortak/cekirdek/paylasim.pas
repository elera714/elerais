{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: paylasim.pas
  Dosya Ýþlevi: tüm birimler için ortak paylaþýlan iþlevleri içerir

  Güncelleme Tarihi: 05/01/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit paylasim;

interface

const
  ProjeBaslangicTarihi: string = '30.07.2005';
  SistemAdi: string = 'ELERA Ýþletim Sistemi - 0.3.6 - R32';
  DerlemeTarihi: string = {$i %DATE%};
  FPCMimari: string = {$i %FPCTARGET%};
  FPCSurum: string = {$i %FPCVERSION%};

var
  { TODO : öndeðer açýlýþ aygýtý. Otomatikleþtirilecek }
  AcilisSurucuAygiti: string = 'disk1';      // disk1:\dizin1
  OnDegerMasaustuProgram: string = 'muyntcs.c';

type
  PProtokolTipi = ^TProtokolTipi;
  TProtokolTipi = (ptBilinmiyor, ptIP, ptARP, ptTCP, ptUDP, ptICMP);

  // baðlantýyý IP'ýn tanýmlayýcýsý olan MAC veya yayin (broadcast) olarak gerçekleþtir
  PBaglantiTipi = ^TBaglantiTipi;
  TBaglantiTipi = (btIP, btYayin);

const
  // sistemde çalýþacak görev (program) sabitleri
  USTSINIR_GOREVSAYISI = 32;

  // bu deðer genel video belleði olacak
  VIDEO_BELLEK_ADRESI = $A0000000;

  // sayfalama sabitleri
  SAYFA_MEVCUT      = 1;
  SAYFA_YAZILABILIR = 2;

  GERCEKBELLEK_DIZINADRESI = $600000;
  GERCEKBELLEK_TABLOADRESI = $610000;

  // sistem için ayrýlmýþ görev sayýsý
  AYRILMIS_GOREV_SAYISI = 3;

  // seçici (selector) sabitleri
  // ayrýlmýþ seçici sayýsý
  // aþaðýdaki seçiciler (tss) sistem için ayrýlmýþtýr
  AYRILMIS_SECICISAYISI = 13;

  // boþ seçici
  SECICI_SISTEM_BOS     = 0;

  // sistem seçicileri
  SECICI_SISTEM_KOD     = 1;
  SECICI_SISTEM_VERI    = 2;
  SECICI_SISTEM_TSS     = 3;

  // çaðrý yanýtlayýcý seçicileri
  SECICI_CAGRI_KOD      = 4;
  SECICI_CAGRI_VERI     = 5;
  SECICI_CAGRI_TSS      = 6;

  SECICI_GRAFIK_KOD     = 7;
  SECICI_GRAFIK_VERI    = 8;
  SECICI_GRAFIK_TSS     = 9;

  SECICI_GRAFIK_LFB     = 10;
  SECICI_AYRILDI1       = 11;
  SECICI_AYRILDI2       = 12;

{==============================================================================
  Data Type     Bytes   Range
  Byte	        1       0..255
  ShortInt	    1       -128..127
  Word	        2       0..65535
  SmallInt	    2       -32767..32768
  LongWord	    4       0..4294967295
  LongInt	      4       -2147483648..2147483647
  Cardinal      4       LongWord
  Integer       4       SmallInt veya LongInt
  QWord	        8       0..18446744073709551615
  Int64	        8       -9223372036854775808 .. 9223372036854775807
 ==============================================================================}
type
  Sayi1 = Byte;
  ISayi1 = ShortInt;
  Sayi2 = Word;
  ISayi2 = SmallInt;
  Sayi4 = LongWord;
  ISayi4 = LongInt;
  Sayi8 = QWord;
  ISayi8 = Int64;
  Isaretci = Pointer;
  TSayi1 = Sayi1;               // 1 byte'lýk iþaretsiz sayý
  PSayi1 = ^Sayi1;              // 1 byte'lýk iþaretsiz sayýya iþaretçi
  TISayi1 = ISayi1;             // 1 byte'lýk iþaretli sayý
  PISayi1 = ^ISayi1;            // 1 byte'lýk iþaretli sayýya iþaretçi
  TSayi2 = Sayi2;               // 2 byte'lýk iþaretsiz sayý
  PSayi2 = ^Sayi2;              // 2 byte'lýk iþaretsiz sayýya iþaretçi
  TISayi2 = ISayi2;             // 2 byte'lýk iþaretli sayý
  PISayi2 = ^ISayi2;            // 2 byte'lýk iþaretli sayýya iþaretçi
  TSayi4 = Sayi4;               // 4 byte'lýk iþaretsiz sayý
  PSayi4 = ^Sayi4;              // 4 byte'lýk iþaretsiz sayýya iþaretçi
  TISayi4 = ISayi4;             // 4 byte'lýk iþaretli sayý
  PISayi4 = ^ISayi4;            // 4 byte'lýk iþaretli sayýya iþaretçi
  TSayi8 = Sayi8;               // 8 byte'lýk iþaretsiz sayý
  PSayi8 = ^Sayi8;              // 8 byte'lýk iþaretsiz sayýya iþaretçi
  TISayi8 = ISayi8;             // 8 byte'lýk iþaretli sayý
  PISayi8 = ^ISayi8;            // 8 byte'lýk iþaretli sayýya iþaretçi
  TKarakterKatari = shortstring;
  PKarakterKatari = ^shortstring;
  TRenk = Sayi4;
  PRenk = ^TRenk;
  TTarih = Sayi4;
  TSaat = Sayi4;
  PSaat = ^TSaat;

  HResult = ISayi4;
  PChar = ^Char;
  PByte = ^Byte;
  PShortInt = ^ShortInt;
  PWord = ^Word;
  TKimlik = TISayi4;
  PKimlik = ^TKimlik;
  PSmallInt = ^SmallInt;
  PBoolean = ^Boolean;

type
  PHiza = ^THiza;
  THiza = (hzYok, hzUst, hzSag, hzAlt, hzSol, hzTum);
  THizalar = set of THiza;

type
  TYatayHizalar = (yhSol, yhOrta, yhSag);
  TDikeyHizalar = (dhUst, dhOrta, dhAlt);
  TYaziHiza = record
    Yatay: TYatayHizalar;
    Dikey: TDikeyHizalar;
  end;

const
  SISTEME_AYRILMIS_RAM  = $0A00000;             // sistem için ayrýlmýþ RAM = 10MB

  BELLEK_HARITA_ADRESI: PByte = PByte($510000);

  SISTEM_ESP        = $300000 + $10000;
  CAGRI_ESP         = SISTEM_ESP + $10000;
  GRAFIK_ESP        = CAGRI_ESP + $10000;

  // program için ESP bellek adresi ve ESP uzunluðu
  // $2000 (GOREV3_ESP_U) * $20 (USTSINIR_GOREVSAYISI) = $40000
  // $400000..$440000 arasý program ESP belleði için ayrýlmýþtýr
  GOREV3_ESP_U      = $2000;                    // her bir ESP bellek uzunluðu (8192 byte)
  GOREV3_ESP        = $400000 + GOREV3_ESP_U;   // ilk program ESP bellek adresi

  BILDEN_VERIADRESI = $10008;

type
  TTusDurum = (tdYok, tdBasildi, tdBirakildi);

const
  TUS_KONTROL = Chr($C0);
  TUS_ALT     = Chr($C1);
  TUS_DEGISIM = Chr($C2);
  TUS_KBT     = Chr($3A);                           // karakter büyütme tuþu (capslock)
  TUS_SYT     = Chr($45);                           // sayý yazma tuþu (numlock)
  TUS_KT      = Chr($46);                           // kaydýrma tuþu (scrolllock)

var
  KONTROLTusDurumu: TTusDurum = tdYok;
  ALTTusDurumu    : TTusDurum = tdYok;
  DEGISIMTusDurumu: TTusDurum = tdYok;

  KBTDurum        : Boolean = False;                // karakter büyütme tuþu (capslock)
  SYTDurum        : Boolean = False;                // sayý yazma tuþu (numlock)
  KTDurum         : Boolean = False;                // kaydýrma tuþu (scrolllock)

const
  // að protokolleri - deðerler network sýralý
  PROTOKOL_ARP  = TSayi2($0806);
  PROTOKOL_IP   = TSayi2($0800);

  PROTOKOL_TCP  = TSayi1($06);
  PROTOKOL_UDP  = TSayi1($11);
  PROTOKOL_ICMP = TSayi1($01);

const
  HATA_YOK                    = TISayi4(0);
  HATA_KIMLIK                 = TISayi4(-1);
  HATA_NESNE                  = TISayi4(-2);
  HATA_ATANESNE               = TISayi4(-3);
  HATA_ALTNESNEBELLEKDOLU     = TISayi4(-4);
  HATA_TUMBELLEKKULLANIMDA    = TISayi4(-5);
  HATA_ISLEV                  = TISayi4(-6);
  HATA_DOSYABULUNAMADI        = TISayi4(-7);
  HATA_BOSGOREVYOK            = TISayi4(-8);
  HATA_BOSKIMLIKYOK           = TISayi4(-9);
  HATA_TUMZAMANLAYICILARDOLU  = TISayi4(-10);
  HATA_NESNEGORUNURDEGIL      = TISayi4(-11);
  HATA_BELLEKOKUMA            = TISayi4(-12);
  HATA_GOREVNO                = TISayi4(-13);
  HATA_ELEMANEKLEME           = TISayi4(-14);
  HATA_DEGERARALIKDISI        = TISayi4(-15);
  HATA_KAYNAKLARKULLANIMDA    = TISayi4(-16);
  HATA_BILINMEYENUZANTI       = TISayi4(-17);
  HATA_NESNEOLUSTURMA         = TISayi4(-18);

var
  // GN_UZUNLUK deðiþkeni, görsel nesne yapýlarý içerisinde en uzun yapýlý nesne olan
  // TPencere nesnesinin uzunluðu alýnarak;
  // gn_islevler.Yukle iþlevi tarafýndan 16'nýn katlarý olarak belirlenmiþtir
  GN_UZUNLUK: TISayi4;

const
  // GN_UZUNLUK uzunluðunda tanýmlanacak toplam görsel nesne sayýsý
  USTSINIR_GORSELNESNE  = 128; //255;
  USTSINIR_MASAUSTU     = 4;

var
  CekirdekBaslangicAdresi, CekirdekUzunlugu: TSayi4;

  // görevin ana penceresinin ortalanmasýný saðlar
  AnaPencereyiOrtala: Boolean = False;

type
  PAygitSurucusu = ^TAygitSurucusu;
  TAygitSurucusu = record
    AygitAdi: string[30];
    Aciklama: string[50];
    Deger1, Deger2, Deger3: TSayi4;
  end;

type
  PYon = ^TYon;
  TYon = (yYatay, yDikey);

type
  PIslemciBilgisi = ^TIslemciBilgisi;
  TIslemciBilgisi = record
    Satici: string;                   // cpu id = 0
    Ozellik1_EAX, Ozellik1_EDX,
    Ozellik1_ECX: TSayi4;             // cpu id = 1
  end;

type
  PPOlay = ^POlay;
  POlay = ^TOlay;
  TOlay = record
    Kimlik: TKimlik;
    Olay, Deger1, Deger2: TISayi4;
  end;

type
  PELFBaslik = ^TELFBaslik;
  TELFBaslik = packed record
    Tanim: array[0..15] of Char;
    Tip: TSayi2;
    Makine: TSayi2;
    Surum: TSayi4;
    KodBaslangicAdresi: TSayi4;
    BaslikTabloBaslangic: TSayi4;
    BolumTabloBaslangic: TSayi4;
    Mimari: TSayi4;
    BuraninBaslikUzunlugu: TSayi4;
    BaslikTabloUzunlugu: TSayi4;
    ProgramBaslikSayisi: TSayi4;
    BaslikTabloGirisUzunlugu: TSayi4;
    BaslikTabloGirisSayisi: TSayi4;
    UstBilgiTabloGirisiSayisi: TSayi4;
   end;

type
  PMACAdres = ^TMACAdres;
  TMACAdres = array[0..5] of TSayi1;
  PIPAdres = ^TIPAdres;
  TIPAdres = array[0..3] of TSayi1;

type
  PEthernetPaket = ^TEthernetPaket;
  TEthernetPaket = packed record
    HedefMACAdres,
    KaynakMACAdres: TMACAdres;
    PaketTipi: TSayi2;
    Veri: Isaretci;
  end;

type
  PARPPaket = ^TARPPaket;
  TARPPaket = packed record
    DonanimTip: Word;             // donaným tipi
    ProtokolTip: Word;            // protokol tipi
    DonanimAdresU: Byte;          // donaným adres uzunluðu
    ProtokolAdresU: Byte;         // protokol adres uzunluðu
    Islem: Word;                  // iþlem
    GonderenMACAdres: TMACAdres;  // paketi gönderen donaným adresi
    GonderenIPAdres: TIPAdres;    // paketi gönderen ip adresi
    HedefMACAdres: TMACAdres;     // paketin gönderildiði donaným adresi
    HedefIPAdres: TIPAdres;       // paketin gönderildiði ip adresi
  end;

{Not1: [0..3] bit = versiyon Ipv4 = 4
       [4..7] baþlýk uzunluðu = baþlýk uzunluðu * 4 (kaç tane 4 byte olduðu)

 Not2: Toplam Uzunluk: Ip uzunluðu + kendisine eklenen diðer data uzunluðu }
type
  PIPPaket = ^TIPPaket;
  TIPPaket = packed record
    SurumVeBaslikUzunlugu,            // Not1
    ServisTipi: TSayi1;
    ToplamUzunluk,                    // Not2
    Tanimlayici,                      // tanýmlayýcý
    ParcaSiraNo: TSayi2;              // üst 3 bit parçanýn olup olmadýðý, diðer bitler parça numarasý
    YasamSuresi,
    Protokol: TSayi1;
    SaglamaToplami: TSayi2;
    KaynakIP,
    HedefIP: TIPAdres;
    Veri: Isaretci;
  end;

type
  PDHCPKayit = ^TDHCPKayit;
  TDHCPKayit = packed record
  	Islem, DonanimTip, DonanimUz,
    RelayIcin: TSayi1;
  	GonderenKimlik: TSayi4;
  	Sure, Bayraklar: Word;
  	IstemciIPAdres, BenimIPAdresim, SunucuIPAdres,
    AgGecidiIPAdres: TIPAdres;
  	IstemciMACAdres: TMACAdres;
  	AYRLDI1: TSayi4;
  	AYRLDI2: TSayi4;
  	AYRLDI3: TSayi2;
  	SunucuEvSahibiAdi: array[0..63] of Char;
  	AcilisDosyaAdi: array[0..127] of Char;
  	SihirliCerez: TSayi4;
  	DigerSecenekler: Isaretci;
  end;

type
  // tcp ve udp kontrol toplamý için ek baþlýk yapýsý
  PEkBaslik = ^TEkBaslik;
  TEkBaslik = packed record         // pseudoheader
    KaynakIP: TIPAdres;
    HedefIP: TIPAdres;
    Sifir,
    Protokol: TSayi1;
    Uzunluk: TSayi2;                // udp veya tcp 'nin data ile beraber uzunluðu
  end;

const
  SURUCUTIP_DISKET  = Byte(1);
  SURUCUTIP_DISK    = Byte(2);

const   // DATTIP = dosya ayýrma tablosu (FAT)
  DATTIP_BELIRSIZ   = Byte($0);
  DATTIP_FAT12      = Byte($1);
  DATTIP_FAT16      = Byte($4);
  DATTIP_FAT32      = Byte($B);
  DATTIP_FAT32LBA   = Byte($C);

type
  // 12 & 16 bitlik boot kayýt yapýsý
  PAcilisKayit1x = ^TAcilisKayit1x;
  TAcilisKayit1x = packed record
    AYRLDI1: array[0..2] of Byte;             // 00..02
    OEMAdi: array[0..7] of Char;              // 03..10
    SektorBasinaByte: Word;                   // 11..12
    ZincirBasinaSektor: Byte;                 // 13..13
    AyrilmisSektor1: Word;                    // 14..15
    DATSayisi: Byte;                          // 16..16
    AzamiDizinGirisi: Word;                   // 17..18
    ToplamSektorSayisi1x: Word;               // 19..20
    MedyaTip: Byte;                           // 21..21
    DATBasinaSektor: Word;                    // 22..23   - SADECE FAT12 / FAT16 için
    IzBasinaSektor: Word;                     // 24..25
    KafaSayisi: Word;                         // 26..27
    BolumOncesiSektorSayisi: TSayi4;          // 28..31
    ToplamSektorSayisi32: TSayi4;             // 32..35

    AygitNo: Byte;                            // 36..36
    AYRLDI2: Byte;                            // 37..37
    GenisletilmisAcilisImzasi: Byte;          // 38..38
    SeriNo: TSayi4;                           // 39..42
    Etiket: array[0..10] of Char;             // 43..53
    DosyaSistemEtiket: array[0..7] of Char;   // 54..61
    // açýlýþ kodu ve $AA55
  end;

type
  // 32 bitlik boot kayýt yapýsý
  PAcilisKayit32 = ^TAcilisKayit32;
  TAcilisKayit32 = packed record
    AYRLDI1: array[0..2] of Byte;             // 00..02
    OEMAdi: array[0..7] of Char;              // 03..10
    SektorBasinaByte: Word;                   // 11..12
    ZincirBasinaSektor: Byte;                 // 13..13
    AyrilmisSektor1: Word;                    // 14..15
    DATSayisi: Byte;                          // 16..16
    AzamiDizinGirisi: Word;                   // 17..18
    ToplamSektorSayisi1x: Word;               // 19..20
    MedyaTip: Byte;                           // 21..21
    DAT1xBasinaSektor: Word;                  // 22..23   - SADECE FAT12 / FAT16 için
    IzBasinaSektor: Word;                     // 24..25
    KafaSayisi: Word;                         // 26..27
    BolumOncesiSektorSayisi: TSayi4;          // 28..31
    ToplamSektorSayisi32: TSayi4;             // 32..35

    DATBasinaSektor: TSayi4;                  // 36..39
    Bayraklar: Word;                          // 40..41
    DATSurum: Word;                           // 42..43
    DizinGirisindekiZincirSayisi: TSayi4;     // 44..47
    DosyaSistemSektorNoBilgi: Word;           // 48..49
    AcilisSektorNo: Word;                     // 50..51
    AyrilmisSektor2: array[0..11] of Byte;    // 52..63
    AygitNo: Byte;                            // 64..64
    Bayraklar2: Byte;                         // 65..65
    Imza: Byte;                               // 66..66
    EtiketKimlik: array[0..3] of Char;        // 67..70
    Etiket: array[0..10] of Char;             // 71..81
    DosyaSistemEtiket: array[0..7] of Char;   // 82..89
    // açýlýþ kodu ve $AA55
  end;

type
  PDiskBolum = ^TDiskBolum;
  TDiskBolum = packed record
    Ozellikler: Byte;                             // bit 7 = aktif veya boot edebilir
    CHSIlkSektor: array[0..2] of Byte;
    BolumTipi: Byte;
    CHSSonSektor: array[0..2] of Byte;
    LBAIlkSektor,
    BolumSektorSayisi: TSayi4;
  end;

type
  PGoruntuYapi = ^TGoruntuYapi;
  TGoruntuYapi = record
    Genislik, Yukseklik: TISayi4;
    BellekAdresi: Isaretci;
  end;

type
  PIDEDisk = ^TIDEDisk;
  TIDEDisk = record
    AnaPort, KontrolPort: Word;
    Kanal: Byte;
  end;

type
  TSektorIslev = function(AFizikselSurucu: Isaretci; AIlkSektor, ASektorSayisi: TSayi4;
    ABellek: Isaretci): TSayi4;

// fiziksel sürücü yapýsý
type
  PFizikselSurucu = ^TFizikselSurucu;
  TFizikselSurucu = record
    Mevcut: Boolean;
    Kimlik: TKimlik;
    AygitAdi: string[16];
    KafaSayisi: TSayi2;
    SilindirSayisi: TSayi2;
    IzBasinaSektorSayisi: TSayi2;
    ToplamSektorSayisi: TSayi4;
    SurucuTipi: TSayi1;
    Ozellikler: TSayi1;
    SonIzKonumu: TISayi1;           // floppy sürücüsünün kafasýnýn bulunduðu son iz (track) no
    IslemYapiliyor: Boolean;        // True = sürücü iþlem yapmakta, False = sürücü boþta
    MotorSayac: TSayi4;             // motor kapatma geri sayým sayacý (þu an sadece floppy sürücüsü için)
    Aygit: TIDEDisk;                // depolama aygýtý
    SektorOku: TSektorIslev;        // sektör okuma iþlevi
    SektorYaz: TSektorIslev;        // sektör yazma iþlevi
  end;

type
  PDizinGirisi = ^TDizinGirisi;
  TDizinGirisi = record
    IlkSektor: TSayi4;
    ToplamSektor: TSayi4;
    GirdiSayisi: TSayi2;

    // her bir dizin tablosu okunduðunda, o sektörde okunan kaydýn sýra numarasý
    // 0 = ilk kayýt numarasý, 1 = ikinci kayýt, 15 = sektördeki sonuncu kayýt
    DizinTablosuKayitNo: TISayi4;
  end;

type
  PDizinGirdisi = ^TDizinGirdisi;
  TDizinGirdisi = packed record
    DosyaAdi: array[0..7] of Char;
    Uzanti: array[0..2] of Char;
    Ozellikler: TSayi1;
    Kullanilmiyor1: TSayi2;
    OlusturmaSaati: TSayi2;
    OlusturmaTarihi: TSayi2;
    SonErisimTarihi: TSayi2;
    Kullanilmiyor2: TSayi2;
    SonDegisimSaati: TSayi2;
    SonDegisimTarihi: TSayi2;
    BaslangicKumeNo: TSayi2;
    DosyaUzunlugu: TSayi4;
  end;

type
  PDosyaAyirmaTablosu = ^TDosyaAyirmaTablosu;
  TDosyaAyirmaTablosu = record         // dosya ayýrma tablosu (file allocation table)
    IlkSektor: TSayi2;
    ToplamSektor: TSayi2;
    KumeBasinaSektor: TSayi1;
    IlkVeriSektoru: TSayi4;
  end;

type
  PAcilis = ^TAcilis;     // acilis = boot
  TAcilis = record
    DizinGirisi: TDizinGirisi;
    DosyaAyirmaTablosu: TDosyaAyirmaTablosu;
  end;

// mantýksal sürücü yapýsý - sistem için
type
  PMantiksalSurucu = ^TMantiksalSurucu;
  TMantiksalSurucu = packed record
    AygitMevcut: Boolean;
    FizikselSurucu: PFizikselSurucu;
    AygitAdi: string[16];
    BolumIlkSektor: TSayi4;
    BolumToplamSektor: TSayi4;
    BolumTipi: TSayi1;
    Acilis: TAcilis;
  end;

// mantýksal sürücü yapýsý - program için
type
  PMantiksalSurucu3 = ^TMantiksalSurucu3;
  TMantiksalSurucu3 = packed record
    AygitAdi: string[16];
    SurucuTipi: TSayi1;
    DosyaSistemTipi: TSayi1;
    BolumIlkSektor: TSayi4;
    BolumToplamSektor: TSayi4
  end;

// fiziksel sürücü yapýsý - program için
type
  PFizikselSurucu3 = ^TFizikselSurucu3;
  TFizikselSurucu3 = packed record
    AygitAdi: string[16];
    SurucuTipi: TSayi1;
    KafaSayisi: TSayi2;
    SilindirSayisi: TSayi2;
    IzBasinaSektorSayisi: TSayi2;
    ToplamSektorSayisi: TSayi4;
  end;

// sistem dosya arama yapýsý
type
  PDosyaArama = ^TDosyaArama;
  TDosyaArama = record
    DosyaAdi: string;                 // 8.3 dosya adý veya uzun dosya adý
    DosyaUzunlugu: TSayi4;
    Kimlik: TKimlik;                  // arama kimliði
    BaslangicKumeNo: TSayi2;          // geçici
    Ozellikler: TSayi1;
    OlusturmaSaati: TSayi2;
    OlusturmaTarihi: TSayi2;
    SonErisimTarihi: TSayi2;
    SonDegisimSaati: TSayi2;
    SonDegisimTarihi: TSayi2;
  end;

var
  // fiziksel sürücü listesi. en fazla 2 floppy sürücüsü + 4 disk sürücüsü
  FizikselDepolamaAygitSayisi: TSayi4;
  FizikselDepolamaAygitListesi: array[1..6] of TFizikselSurucu;

  // mantýksal sürücü listesi. en fazla 6 depolama sürücüsü
  MantiksalDepolamaAygitSayisi: TISayi4;
  MantiksalDepolamaAygitListesi: array[1..6] of TMantiksalSurucu;

  PDisket1: PFizikselSurucu;
  PDisket2: PFizikselSurucu;

const
  USTSINIR_ARAMAKAYIT = 5;
  USTSINIR_DOSYAKAYIT = 5;

// dosya arama iþlevleri için gereken yapý
type
  PAramaKayit = ^TAramaKayit;
  TAramaKayit = record
    Kullanilabilir: Boolean;
    MantiksalSurucu: PMantiksalSurucu;
    DizinGirisi: TDizinGirisi;
    Aranan: string;
  end;

// tüm dosya iþlevleri için gereken yapý
type
  PDosyaKayit = ^TDosyaKayit;
  TDosyaKayit = record
    Kullanilabilir: Boolean;
    MantiksalSurucu: PMantiksalSurucu;
    DosyaAdi: string;
    DATBellekAdresi: Isaretci;    // Dosya Ayýrma Tablosu bellek adresi
    IlkZincirSektor: Word;
    Uzunluk: TISayi4;
    Konum: TSayi4;
    VeriBellekAdresi: Isaretci;
  end;

var
  FileResult: TISayi4;
  // arama iþlem veri yapýlarý
  GAramaKayitListesi: array[0..USTSINIR_ARAMAKAYIT - 1] of TAramaKayit;
  // dosya iþlem veri yapýlarý
  GDosyaKayitListesi: array[0..USTSINIR_DOSYAKAYIT - 1] of TDosyaKayit;

var
  CalisanGorevSayisi,                     // oluþturulan / çalýþan program sayýsý
  CalisanGorev: TISayi4;                  // o an çalýþan program
  CalisanGorevBellekAdresi: TSayi4;       // o an çalýþan programýn yüklendiði bellek adresi
  GorevDegisimSayisi: TSayi4 = 0;         // çekirdek baþladýðý andan itibaren gerçekleþtirilen görev deðiþim sayýsý
  GorevBayrakDegeri: TSayi4 = 0;          // her görev çalýþtýrma / sonlandýrma / aktifleþtirme durumunda 1 artýrýlýr

type
  PAlan = ^TAlan;
  TAlan = record
    Sol, Ust, Sag, Alt: TISayi4;
  end;

type
  TKesmeCagrisi = function(IslevNo: TSayi4; Degiskenler: Isaretci): TISayi4;

type
  PCizgiTipi = ^TCizgiTipi;
  TCizgiTipi = (ctDuz, ctNokta);

type
  PEkranKartBilgisi = ^TEkranKartBilgisi;
  TEkranKartBilgisi = record
    BellekUzunlugu: TSayi2;
    EkranMod: TSayi2;
    YatayCozunurluk, DikeyCozunurluk: TISayi4;
    BellekAdresi: TSayi4;
    PixelBasinaBitSayisi: TSayi1;
    NoktaBasinaByteSayisi: TSayi1;
    SatirdakiByteSayisi: TSayi2;
  end;

type
  TIRQIslevi = procedure;

type
  PKonum = ^TKonum;
  TKonum = record
    Sol, Ust: TISayi4;
  end;

type
  PBoyut = ^TBoyut;
  TBoyut = record
    Genislik, Yukseklik: TISayi4;
  end;

type
  // görsel nesnelerin kullaným tipleri
  // ktTuvalNesne = kendisine ait çizim alaný mevcuttur
  // ktNesne      = tuval nesnenin altýndaki nesnedir
  // ktBilesen    = nesnenin alt nesnesi olan ktNesne özelliðindeki nesnedir
  TKullanimTipi = (ktTuvalNesne, ktNesne, ktBilesen);

type { Görsel Nesne Tipi }
  TGNTip = (gntTanimsiz, gntMasaustu, gntPencere, gntDugme, gntGucDugmesi, gntListeKutusu,
    gntMenu, gntDefter, gntIslemGostergesi, gntOnayKutusu, gntGirisKutusu, gntDegerDugmesi,
    gntEtiket, gntDurumCubugu, gntSecimDugmesi, gntBaglanti, gntResim, gntListeGorunum,
    gntPanel, gntResimDugmesi, gntKaydirmaCubugu, gntKarmaListe, gntAcilirMenu,
    gntDegerListesi, gntIzgara, gntAracCubugu, gntRenkSecici, gntSayfaKontrol);

type
  THamResim = record
    Genislik, Yukseklik: TSayi4;
    BellekAdresi: Isaretci;
  end;

const
  ISLEV_OLUSTUR     = $0001;
  ISLEV_GOSTER      = $0002;
  ISLEV_GIZLE       = $0003;
  ISLEV_CIZ         = $0004;
  ISLEV_BOYUTLANDIR = $0005;
  ISLEV_YOKET       = $0006;
  ISLEV_HIZALA      = $0007;
  // aþaðýdaki 2 deðer api iþlevlerine uygulanmadý, uygulanabilir
  ISLEV_AL          = $0E;
  ISLEV_YAZ         = $0F;

type
  PSecimDurumu = ^TSecimDurumu;
  TSecimDurumu = (sdNormal, sdSecili);
  TDugmeDurumu = (ddNormal, ddBasili);
  TFareImlecTipi = (fitOK, fitGiris, fitEl, fitBoyutKBGD, fitBoyutKG,
    fitIslem, fitBekle, fitYasak, fitBoyutBD, fitBoyutKDGB, fitBoyutTum);

const
  // çekirdeðin ürettiði genel olaylar - çekirdek olay (CO)
  CO_ILKDEGER             = $100;
  CO_CIZIM                = CO_ILKDEGER + 0;
  CO_ZAMANLAYICI          = CO_ILKDEGER + 1;
  CO_OLUSTUR              = CO_ILKDEGER + 2;
  CO_DURUMDEGISTI         = CO_ILKDEGER + 3;
  CO_ODAKKAZANILDI        = CO_ILKDEGER + 4;
  CO_ODAKKAYBEDILDI       = CO_ILKDEGER + 5;
  CO_TUSBASILDI           = CO_ILKDEGER + 6;
  CO_MENUACILDI           = CO_ILKDEGER + 7;        // menünün açýlmasý
  CO_MENUKAPATILDI        = CO_ILKDEGER + 8;        // menünün kapatýlmasý
  CO_SECIMDEGISTI         = CO_ILKDEGER + 9;        // karma liste nesnesinde seçimin deðiþmesi olayý

  // fare aygýtýnýn ürettiði olaylar - fare olaylarý (FO)
  FO_ILKDEGER             = $200;
  FO_BILINMIYOR           = FO_ILKDEGER;
  FO_SOLTUS_BASILDI       = FO_ILKDEGER + 2;
  FO_SOLTUS_BIRAKILDI     = FO_ILKDEGER + 2 + 1;
  FO_SAGTUS_BASILDI       = FO_ILKDEGER + 4;
  FO_SAGTUS_BIRAKILDI     = FO_ILKDEGER + 4 + 1;
  FO_ORTATUS_BASILDI      = FO_ILKDEGER + 6;
  FO_ORTATUS_BIRAKILDI    = FO_ILKDEGER + 6 + 1;
  FO_4NCUTUS_BASILDI      = FO_ILKDEGER + 8;
  FO_4NCUTUS_BIRAKILDI    = FO_ILKDEGER + 8 + 1;
  FO_5NCITUS_BASILDI      = FO_ILKDEGER + 10;
  FO_5NCITUS_BIRAKILDI    = FO_ILKDEGER + 10 + 1;
  FO_HAREKET              = FO_ILKDEGER + 122;
  FO_TIKLAMA              = FO_ILKDEGER + 124;
  //FO_CIFTTIKLAMA        = FO_ILKDEGER + 126;
  FO_KAYDIRMA             = FO_ILKDEGER + 128;

  RENK_BEYAZ		              = TRenk($FFFFFF);
  RENK_GUMUS		              = TRenk($C0C0C0);
  RENK_GRI		                = TRenk($808080);
  RENK_SIYAH		              = TRenk($000000);
  RENK_KIRMIZI                = TRenk($FF0000);
  RENK_BORDO		              = TRenk($800000);
  RENK_SARI		                = TRenk($FFFF00);
  RENK_ZEYTINYESILI		        = TRenk($808000);
  RENK_ACIKYESIL              = TRenk($00FF00);
  RENK_YESIL		              = TRenk($008000);
  RENK_ACIKMAVI		            = TRenk($00FFFF);
  RENK_TURKUAZ	              = TRenk($008080);
  RENK_MAVI		                = TRenk($0000FF);
  RENK_LACIVERT	              = TRenk($000080);
  RENK_PEMBE 	                = TRenk($FF00FF);
  RENK_MOR		                = TRenk($800080);

const
  // görev çubuðu iç dolgu rengi
  GOREVCUBUGU_ILKRENK       = $B9C9F9;
  GOREVCUBUGU_SONRENK       = $A1B7F7;

  // düðme dolgu renkleri
  DUGME_NORMAL_ILKRENK      = GOREVCUBUGU_ILKRENK;
  DUGME_NORMAL_SONRENK      = GOREVCUBUGU_SONRENK;
  DUGME_NORMAL_YAZIRENK     = RENK_SIYAH;

  DUGME_BASILI_ILKRENK      = $609FCC;
  DUGME_BASILI_SONRENK      = $2C6187;
  DUGME_BASILI_YAZIRENK     = RENK_BEYAZ;

type
  TGiysiResim = record
    Genislik, Yukseklik: TSayi4;
    BellekAdresi: Isaretci;
  end;

type
  PGiysi = ^TGiysi;
  TGiysi = record
    BaslikYukseklik,

    ResimSolUstGenislik,
    ResimUstGenislik,
    ResimSagUstGenislik,

    ResimSolGenislik,
    ResimSolYukseklik,
    ResimSagGenislik,
    ResimSagYukseklik,

    ResimSolAltGenislik,
    ResimSolAltYukseklik,
    ResimAltGenislik,
    ResimAltYukseklik,
    ResimSagAltGenislik,
    ResimSagAltYukseklik,

    AktifBaslikYaziRengi,
    PasifBaslikYaziRengi,
    IcDolguRengi,
    BaslikYaziSol,
    BaslikYaziUst,

    KapatmaDugmesiSol,
    KapatmaDugmesiUst,
    KapatmaDugmesiGenislik,
    KapatmaDugmesiYukseklik,
    BuyutmeDugmesiSol,
    BuyutmeDugmesiUst,
    BuyutmeDugmesiGenislik,
    BuyutmeDugmesiYukseklik,
    KucultmeDugmesiSol,
    KucultmeDugmesiUst,
    KucultmeDugmesiGenislik,
    KucultmeDugmesiYukseklik: TISayi4;

    ResimSolUstA, ResimSolUstP,
    ResimUstA, ResimUstP,
    ResimSagUstA, ResimSagUstP,
    ResimSolA, ResimSolP,
    ResimSagA, ResimSagP,
    ResimSolAltA, ResimSolAltP,
    ResimAltA, ResimAltP,
    ResimSagAltA, ResimSagAltP: TGiysiResim;

    // A(ktif), (P)asif kontrol düðme (R)esim (S)ýra numaralarý
    AKapatmaDugmesiRSNo, ABuyutmeDugmesiRSNo, AKucultmeDugmesiRSNo,
    PKapatmaDugmesiRSNo, PBuyutmeDugmesiRSNo, PKucultmeDugmesiRSNo: TSayi4;
  end;

var
  AktifGiysi: TGiysi;
  AktifGiysiSiraNo: TISayi4 = 0;

type
  PTSS = ^TTSS;
  TTSS = packed record
    OncekiTSS, A00: TSayi2;     // A(00)yrýldý
    ESP0: TSayi4;
    SS0, A01: TSayi2;
    ESP1: TSayi4;
    SS1, A02: TSayi2;
    ESP2: TSayi4;
    SS2, A03: TSayi2;
    CR3, EIP, EFLAGS: TSayi4;
    EAX, ECX, EDX, EBX, ESP, EBP, ESI, EDI: TSayi4;
    ES, A04: TSayi2;
    CS, A05: TSayi2;
    SS, A06: TSayi2;
    DS, A07: TSayi2;
    FS, A08: TSayi2;
    GS, A09: TSayi2;
    LDT, A10: TSayi2;
    TBit: TSayi2;               // yakalayýcý (trap) bit. hata ayýklama amaçlý
    IOHaritaGAdres: TSayi2;     // IOHarita yapý baþýndan uzaklýk bellek adresi
    // buraya kadar 104 byte.

    IOHarita: Isaretci;
    // IO port izin haritasý kulanýlacaksa her bir görev için
    // 65536 / 8 = 8192 byte alan gerekmektedir
  end;

var
  AgYuklendi: Boolean = False;

  SistemSayaci, CagriSayaci, GrafikSayaci: TSayi4;
  ZamanlayiciSayaci: TSayi4 = 0;
  // görev deðiþiminin yapýlýp yapýlmamasý deðiþkeni.
  // 0 = görev deðiþtirme, 1 = görev deðiþtir
  GorevDegisimBayragi: TSayi4 = 0;
  // çoklu görev iþleminin baþlayýp baþlamadýðýný gösteren deðiþken
  // 0 = baþlamadý, 1 = baþladý
  CokluGorevBasladi: TSayi4 = 0;

  GecerliFareGostegeTipi: TFareImlecTipi;

  ToplamGNSayisi, ToplamMasaustu: TSayi4;

  // að - gelen paket sayýlarý
  ICMPPaketSayisi: TSayi4 = 0;
  TCPPaketSayisi: TSayi4 = 0;
  UDPPaketSayisi: TSayi4 = 0;
  GAEPaketSayisi: TSayi4 = 0;     // GözArdýEdilen paket sayýsý

const
  TSS_UZUNLUK = 104 + 8192;   // 104 byte TSS, 8192 byte giriþ / çýkýþ port izin haritasý

var
  GorevTSSListesi: array[0..USTSINIR_GOREVSAYISI - 1] of PTSS;

type
  PIDTYazmac = ^TIDTYazmac;
  TIDTYazmac = packed record
    Uzunluk: TSayi2;
    Baslangic: TSayi4;
  end;

type
  TGorevDurum = (gdBos, gdOlusturuldu, gdCalisiyor, gdDurduruldu, gdSonlandiriliyor);

type
  PPencereTipi = ^TPencereTipi;
  TPencereTipi = (ptBasliksiz, ptIletisim, ptBoyutlanabilir);

  { TODO : sadece baþlýðýn görüntüleneceði bir durum eklenecek }
  PPencereDurum = ^TPencereDurum;
  TPencereDurum = (pdNormal, pdKucultuldu, pdBuyutuldu);

type
  // program için (API) görev yapýsý
  PGorevKayit = ^TGorevKayit;
  TGorevKayit = record
    GorevDurum: TGorevDurum;            // görev durumu
    GorevKimlik: TKimlik;               // görev kimliði - sýra numarasý
    GorevSayaci: TSayi4;                // görevin kaç kez çalýþtýðý
    BellekBaslangicAdresi: TSayi4;      // görevin yerleþtirildiði bellek adresi
    BellekUzunlugu: TSayi4;             // görev bellek uzunluðu
    OlaySayisi: TSayi4;                 // görev için iþlenmeyi bekleyen olay sayýsý
    DosyaAdi: string;                   // programýn yüklendiði dosya adý
  end;

type
  // program için (API) program yapýsý
  PProgramKayit = ^TProgramKayit;
  TProgramKayit = record
    PencereKimlik: TKimlik;             // pencere kimliði
    GorevKimlik: TKimlik;               // görev kimliði
    PencereTipi: TPencereTipi;          // pencere tipi
    PencereDurum: TPencereDurum;        // pencere durumu
    DosyaAdi: string;                   // programýn yüklendiði dosya adý
  end;

type
  PSistemBilgisi = ^TSistemBilgisi;
  TSistemBilgisi = record
    SistemAdi, DerlemeBilgisi,
    FPCMimari, FPCSurum: string;
    YatayCozunurluk, DikeyCozunurluk: TSayi4;
  end;

type
  PKarakter = ^TKarakter;
  TKarakter = record
    Genislik,                   // karakter geniþliði
    Yukseklik,                  // karakter yüksekliði
    YT,                         // yatay +/- tolerans deðeri
    DT: TISayi1;                // dikey +/- tolerans deðeri
    Adres: Isaretci;            // karakter resim baþlangýç adresi
  end;

type
  PPCI = ^TPCI;
  TPCI = packed record
    Yol, Aygit, Islev, AYRLD0: TSayi1;
    SaticiKimlik, AygitKimlik: TSayi2;
    SinifKod: TSayi4;
  end;

type
  PRGB = ^TRGBRenk;
  TRGBRenk = packed record
    B: TSayi1;
    G: TSayi1;
    R: TSayi1;
    AYRLD: TSayi1;    // ayrýldý
  end;

type
  PAgBilgisi = ^TAgBilgisi;
  TAgBilgisi = record
    MACAdres: TMACAdres;
    IP4Adres, AltAgMaskesi, AgGecitAdresi,
    DHCPSunucusu, DNSSunucusu: TIPAdres;
    IPKiraSuresi: TSayi4;     // saniye cinsinden

    // yukarýdaki yapý için API iþlevi oluþturulmuþtur, sýralamanýn bozulmasý iþlevin bozulmasý demektir
    IPAdresiAlindi: Boolean;
  end;

var
  // çekirdek genelinde kullanýlan ortak yapýlar / deðiþkenler
  GMakineAdi: string = 'elera-bil';
  GAgBilgisi: TAgBilgisi;             // içerik ag.IlkAdresDegerleriniYukle iþlevi tarafýndan doldurulmaktadýr

  IPAdres0: TIPAdres = (0, 0, 0, 0);
  IPAdres255: TIPAdres = (255, 255, 255, 255);
  MACAdres0: TMACAdres = (0, 0, 0, 0, 0, 0);
  MACAdres255: TMACAdres = (255, 255, 255, 255, 255, 255);
  //GenelDNS_IPAdres1: TIPAdres = (208, 67, 220, 220);

procedure BellekDoldur(ABellekAdresi: Isaretci; AUzunluk: TSayi4; ADeger: TSayi1);
procedure Tasi2(AKaynak, AHedef: Isaretci; AUzunluk: TSayi4);
function Karsilastir(AKaynak, AHedef: Isaretci; AUzunluk: TSayi4): TSayi4;
function IPKarsilastir(IP1, IP2: TIPAdres): Boolean;
function IPKarsilastir2(AGonderenIP, ABenimIP: TIPAdres): Boolean;
function NoktaAlanIcindeMi(ANokta: TKonum; AAlan: TAlan): Boolean;
function SaglamaToplamiOlustur(AVeriAdresi: Isaretci; AVeriUzunlugu: TSayi2;
  ASahteBaslikAdresi: Isaretci; ASahteBaslikUzunlugu: TSayi2): TSayi2;
function ProtokolTipAdi(AProtokolTipi: TProtokolTipi): string;

implementation

procedure BellekDoldur(ABellekAdresi: Isaretci; AUzunluk: TSayi4; ADeger: TSayi1); assembler;
asm
  pushad
  mov edi,ABellekAdresi
  mov ecx,AUzunluk
  mov al,ADeger
  cld
  rep stosb
  popad
end;

procedure Tasi2(AKaynak, AHedef: Isaretci; AUzunluk: TSayi4); assembler;
asm
  pushad
  mov esi,AKaynak
  mov edi,AHedef
  mov ecx,AUzunluk
  cld
  rep movsb
  popad
end;

// 0 = eþit, 1 = eþit deðil
function Karsilastir(AKaynak, AHedef: Isaretci; AUzunluk: TSayi4): TSayi4;
var
  Sonuc: TSayi4;
begin
asm
  pushfd
  pushad

  mov esi,AKaynak
  mov edi,AHedef
  mov ecx,AUzunluk
  cld
  repe cmpsb

  popad
  mov Sonuc,0

  je  @@exit

  mov Sonuc,1
@@exit:

  popfd
end;

  Result := Sonuc;
end;

function IPKarsilastir(IP1, IP2: TIPAdres): Boolean;
var
  i: TISayi4;
begin

  Result := False;

  for i := 0 to 3 do if(IP1[i] <> IP2[i]) then Exit;

  Result := True;
end;

// ip adresinin aða baðlý bilgisayar olup olmadýðýný test eder
// örn: 192.168.1.1 -> 192.168.1.255
function IPKarsilastir2(AGonderenIP, ABenimIP: TIPAdres): Boolean;
var
  i: TISayi4;
begin

  Result := False;

  for i := 0 to 2 do if(AGonderenIP[i] <> ABenimIP[i]) then Exit;

  if(AGonderenIP[3] <> 255) then Exit;

  Result := True;
end;

function NoktaAlanIcindeMi(ANokta: TKonum; AAlan: TAlan): Boolean;
begin

  Result := False;

  if(ANokta.Sol >= AAlan.Sol) and (ANokta.Sol <= AAlan.Sag) and
    (ANokta.Ust >= AAlan.Ust) and (ANokta.Ust <= AAlan.Alt) then

  Result := True;
end;

{==============================================================================
  verilerin toplam saðlama iþlemini gerçekleþtirir
 ==============================================================================}
{
  kontrol toplamý örneði:
  08 00 00 00 00 01 00 a7 61 62 63 64 65 66 67 68
  69 6a 6b

  önemli: kontrol toplamý yapýlýrken, deðerlerin içerisinde saðlama (checksum) deðeri
  var ise saðlama deðeri iþlem öncesi mutlaka sýfýrlanmalýdýr.

  0800
  0000
  0001
  0047
  6162
  6364
  6566
  6768        1. toplama iþleminden sonra, yüksek 16 bitlik deðer ($2) alçak 16
  696a        bitlik deðere ($03B1) eklenir. $03B1 + $2 = $03B3
    6b
+-------      2. $03B3 deðeri mantýksal NOT iþlemine tabi tutulur. $03B3 -> $FC4C
 203B1


  önemli: iþlevin geri dönüþ deðeri (sýk kullanýmdan dolayý) byte deðerler ters sýrada
    geri döndürülür. örneðin, deðer $CDAB ise bu deðer geriye ABCD olarak döndürülür
}
function SaglamaToplamiOlustur(AVeriAdresi: Isaretci; AVeriUzunlugu: TSayi2;
  ASahteBaslikAdresi: Isaretci; ASahteBaslikUzunlugu: TSayi2): TSayi2;
var
  WordVeriAdresi: PSayi2;
  i, WordVeriUzunlugu: TSayi2;
  SaglamaToplami: TSayi4;
begin

  // eðer veri bellek adresi verilmemiþ veya uzunluk 0 ise çýk
  if(AVeriAdresi = nil) or (AVeriUzunlugu = 0) then Exit(0);

  // saðlama toplamý ilk deðer atamasý
  SaglamaToplami := 0;

  // 1. önce veri deðerlerini topla
  //----------------------------------------------------------------------------

  // toplanacak word sayýsý
  WordVeriUzunlugu := (AVeriUzunlugu shr 1);

  // word deðerleri topla
  WordVeriAdresi := AVeriAdresi;
  if(WordVeriUzunlugu > 1) then
  begin

    for i := 0 to WordVeriUzunlugu - 1 do
    begin

      SaglamaToplami := SaglamaToplami + WordVeriAdresi^;
      Inc(WordVeriAdresi);
    end;
  end;

  // eðer geriye tek deðer (byte) kaldýysa onu da toplama ekle
  if((AVeriUzunlugu mod 2) = 1) then
  begin

    SaglamaToplami := SaglamaToplami + PByte(WordVeriAdresi)^;
  end;

  // 2. daha sonra (var) ise sahte baþlýk deðerlerini topla
  //----------------------------------------------------------------------------
  if(ASahteBaslikAdresi <> nil) and (ASahteBaslikUzunlugu > 0) then
  begin

    // toplanacak word sayýsý
    WordVeriUzunlugu := (ASahteBaslikUzunlugu shr 1);

    // word deðerleri topla
    WordVeriAdresi := ASahteBaslikAdresi;
    if(WordVeriUzunlugu > 1) then
    begin

      for i := 0 to WordVeriUzunlugu - 1 do
      begin

        SaglamaToplami := SaglamaToplami + WordVeriAdresi^;
        Inc(WordVeriAdresi);
      end;
    end;

    // eðer geriye tek deðer (byte) kaldýysa onu da toplama ekle
    if((ASahteBaslikUzunlugu mod 2) = 1) then
    begin

      SaglamaToplami := SaglamaToplami + PByte(WordVeriAdresi)^;
    end;
  end;

  // word deðeri aþan (17 ve sonraki bitler) kýsmý ilk 16 bit deðere ekle
  SaglamaToplami := (SaglamaToplami mod $10000) + (SaglamaToplami div $10000);

  // son olarak deðeri ters çevir
  Result := not SaglamaToplami;
end;

function ProtokolTipAdi(AProtokolTipi: TProtokolTipi): string;
begin

  case AProtokolTipi of
    ptIP    : Result := 'IP';
    ptARP   : Result := 'ARP';
    ptTCP   : Result := 'TCP';
    ptUDP   : Result := 'UDP';
    ptICMP  : Result := 'ICMP';
    else {ptBilinmiyor:} Result := 'Bilinmiyor';
  end;
end;

end.
