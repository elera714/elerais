{==============================================================================
    Data Type	  Bytes   Number type	Range
    Byte	    1	  Integer	0..255
    ShortInt	    1	  Integer	-127..128
    Word	    2	  Integer	0..65535
    SmallInt	    2	  Integer	-32767..32768
    LongWord	    4	  Integer	0..4294967295
    LongInt	    4	  Integer	-2147483648 .. 2147483647
    QWord	    8	  Integer	0..18446744073709551615
    Int64	    8	  Integer	-9223372036854775808 .. 9223372036854775807
    Real	  4/8	  F.Point	system dependent
    Single	    4	  F.Point	1.5E-45..3.4E38, 7-8 significant digits
    Double	    8	  F.Point	5.0E-324 .. 1.7E308, 15-16 significant digits
    Extended	   10	  F.Point	1.9E-4951 .. 1.1E4932, 19-20 significant digits
    Comp	    8	  F.Point	-2E64+1 .. 2E63-1, 19-20 significant digits
    Currency	    8	  Fix.point	-922337203685477.5808..922337203685477.5807 (fixed at 4 digits < 1)
 ==============================================================================}
type

  // ÖNEMLÝ
  // Integer veri tipi bellekte 2 byte'lýk yer ayýrýr. 4 byte'lýk
  // iþaretli (signed) sayýsal veriler için LongInt kullanýlmalýdýr.

//  Cardinal = LongWord;
////  DWord = LongWord;
//  HResult = LongInt;
//  PChar = ^Char;
//  PByte = ^Byte;
//  PShortInt = ^ShortInt;
//  PWord = ^Word;
//  PDWord = ^DWord;
  TColor = LongWord;
  PColor = ^TColor;
  PHandle = ^THandle;
//  PLongWord = ^LongWord;
//  PLongInt = ^LongInt;
//  PSmallInt = ^SmallInt;

  //THandle = LongInt;
  TCursor = Byte;
  TPID0 = LongInt;

  //PTime1 = ^TTime1;
//  PBoolean = ^Boolean;


type
  Sayi1 = Byte;
  ISayi1 = ShortInt;
  Sayi2 = Word;
  ISayi2 = SmallInt;
  ISayi4 = LongInt;
  Sayi4 = LongWord;
  Isaretci = Pointer;
  TISayi1 = ISayi1;             // 1 byte'lýk iþaretli sayý
  PISayi1 = ^ISayi1;            // 1 byte'lýk iþaretli sayýya iþaretçi
  TSayi1 = Sayi1;               // 1 byte'lýk iþaretsiz sayý
  PSayi1 = ^Sayi1;              // 1 byte'lýk iþaretsiz sayýya iþaretçi
  TISayi2 = ISayi2;             // 2 byte'lýk iþaretli sayý
  PISayi2 = ^ISayi2;            // 2 byte'lýk iþaretli sayýya iþaretçi
  TSayi2 = Sayi2;               // 2 byte'lýk iþaretsiz sayý
  PSayi2 = ^Sayi2;              // 2 byte'lýk iþaretsiz sayýya iþaretçi
  TISayi4 = ISayi4;             // 4 byte'lýk iþaretli sayý
  PISayi4 = ^ISayi4;            // 4 byte'lýk iþaretli sayýya iþaretçi
  TSayi4 = Sayi4;               // 4 byte'lýk iþaretsiz sayý
  PSayi4 = ^Sayi4;              // 4 byte'lýk iþaretsiz sayýya iþaretçi
  TKarakterKatari = ShortString;
  PKarakterKatari = ^ShortString;
  TRenk = Sayi4;
  PRenk = ^TRenk;
  TSaat = Sayi4;
  PSaat = ^TSaat;
//  HResult = ISayi4;
//  PChar = ^Char;
//  PByte = ^Byte;
//  PShortInt = ^ShortInt;
//  PWord = ^Word;
  TKimlik = TISayi4;
  PKimlik = ^TKimlik;
//  PSmallInt = ^SmallInt;
//  TDate = Sayi4;
//  PBoolean = ^Boolean;

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

type
  PCizgiTipi = ^TCizgiTipi;
  TCizgiTipi = (ctDuz, ctNokta);

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
  PNokta = ^TNokta;
  TNokta = record
    A1, B1: TISayi4;
  end;

type
  PYon = ^TYon;
  TYon = (yYatay, yDikey);

type
  PPencereTipi = ^TPencereTipi;
  TPencereTipi = (ptBasliksiz, ptIletisim, ptBoyutlanabilir);

  PPencereDurum = ^TPencereDurum;
  TPencereDurum = (pdNormal, pdKucultuldu, pdBuyutuldu);

type
  PPOlay = ^POlay;
  POlay = ^TOlay;
  TOlay = record
    Kimlik: TKimlik;
    Olay, Deger1, Deger2: TISayi4;
  end;

type
  PTSS = ^TTSS;
  TTSS = packed record
    OncekiTSS: TSayi2;
    AYRLD00: TSayi2;
    ESP0: TSayi4;
    SS0: TSayi2;
    AYRLD01: TSayi2;
    ESP1: TSayi4;
    SS1: TSayi2;
    AYRLD02: TSayi2;
    ESP2: TSayi4;
    SS2: TSayi2;
    AYRLD03: TSayi2;
    CR3: TSayi4;
    EIP: TSayi4;
    EFLAGS: TSayi4;
    EAX: TSayi4;
    ECX: TSayi4;
    EDX: TSayi4;
    EBX: TSayi4;
    ESP: TSayi4;
    EBP: TSayi4;
    ESI: TSayi4;
    EDI: TSayi4;
    ES: TSayi2;
    AYRLD04: TSayi2;
    CS: TSayi2;
    AYRLD05: TSayi2;
    SS: TSayi2;
    AYRLD06: TSayi2;
    DS: TSayi2;
    AYRLD07: TSayi2;
    FS: TSayi2;
    AYRLD08: TSayi2;
    GS: TSayi2;
    AYRLD09: TSayi2;
    LDT: TSayi2;
    AYRLD10: TSayi2;
    TrapBit: TSayi2;
    IOMap: TSayi2;
  end;    // 104 byte

const
  SURUCUTIP_DISKET  = Byte(1);
  SURUCUTIP_DISK    = Byte(2);

const   // DATTIP = dosya ayýrma tablosu (FAT)
  DATTIP_BELIRSIZ   = Byte($0);
  DATTIP_FAT12      = Byte($1);
  DATTIP_FAT16      = Byte($4);
  DATTIP_FAT32      = Byte($B);
  DATTIP_FAT32LBA   = Byte($C);

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

type
  PMACAdres = ^TMACAdres;
  TMACAdres = array[0..5] of TSayi1;
  PIPAdres = ^TIPAdres;
  TIPAdres = array[0..3] of TSayi1;

const
  IPAdres0: TIPAdres = (0, 0, 0, 0);
  IPAdres255: TIPAdres = (255, 255, 255, 255);
  MACAdres0: TMACAdres = (0, 0, 0, 0, 0, 0);
  MACAdres255: TMACAdres = (255, 255, 255, 255, 255, 255);

type
  PProtokolTip = ^TProtokolTip;
  TProtokolTip = (ptBilinmiyor, ptIP, ptARP, ptTCP, ptUDP, ptICMP);
  
type
  TGorevDurum = (gdBos, gdOlusturuldu, gdCalisiyor, gdDurduruldu);

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
    ProgramAdi: string;                 // program adý
  end;

type
  // program için (API) program yapýsý
  PProgramKayit = ^TProgramKayit;
  TProgramKayit = record
    PencereKimlik: TKimlik;             // pencere kimliði
    GorevKimlik: TKimlik;               // görev kimliði
    PencereTipi: TPencereTipi;          // pencere tipi
    PencereDurum: TPencereDurum;        // pencere durumu
    ProgramAdi: string;                 // program adý
  end;

type
  PSistemBilgisi = ^TSistemBilgisi;
  TSistemBilgisi = record
    SistemAdi, DerlemeBilgisi,
    FPCMimari, FPCSurum: string;
    YatayCozunurluk, DikeyCozunurluk: TSayi4;
  end;

type
  PIslemciBilgisi = ^TIslemciBilgisi;
  TIslemciBilgisi = record
    Satici: string;                   // cpu id = 0
    Ozellik1_EAX, Ozellik1_EDX,
    Ozellik1_ECX: TSayi4;             // cpu id = 1
  end;

type
  PPCIAygitBilgisi = ^TPCIAygitBilgisi;
  TPCIAygitBilgisi = packed record
    //sistem tarafýndan gelen bilgiler
    Yol: TSayi1;
    Aygit: TSayi1;
    Islev: TSayi1;
    AYRLD0: TSayi1;
    SaticiKimlik: TSayi2;
    AygitKimlik: TSayi2;
    SinifKod: TSayi4;
    //programcý tarafýndan gelen bilgiler
    Komut: TSayi2;
    Durum: TSayi2;
    RevizyonKimlik: TSayi1;
    OnbellekHatUzunluk: TSayi1;
    GecikmeSuresi: TSayi1;
    BaslikTip: TSayi1;
    BIST: TSayi1;
    TemelAdres: array[0..5] of TSayi4;
    KartYolCISIsaretci: TSayi4;
    AltSistemSaticiKimlik: TSayi2;
    AltSistemKimlik: TSayi2;
    GenisletilmisROMTemelAdres: TSayi4;
    KesmeNo: TSayi1;
    KesmePin: TSayi1;
    EnDusukImtiyaz: TSayi1;
    AzamiGecikme: TSayi1;
  end;

type
  PMesaj = ^TMesaj;
  TMesaj = record
    SiraNo: TISayi4;
    Saat: TSayi4;
    Renk: TRenk;
    Mesaj: string;
  end;

type
  PARPKayit = ^TARPKayit;
  TARPKayit = packed record
    IPAdres: TIPAdres;
    MACAdres: TMACAdres;
    YasamSuresi: TISayi2;
  end;

type
  PAgBilgisi = ^TAgBilgisi;
  TAgBilgisi = record
    MACAdres: TMACAdres;
    IP4Adres, AltAgMaskesi, AgGecitAdresi,
    DHCPSunucusu, DNSSunucusu: TIPAdres;
    IPKiraSuresi: TSayi4;
  end;

type
  TDNSDurum = (ddOlusturuldu, ddHazir, ddSorgulaniyor, ddSorgulandi);

type
  PDNSPaket = ^TDNSPaket;
  TDNSPaket = packed record
  	Tanimlayici,
    Bayrak,
    SorguSayisi,
    YanitSayisi,
    YetkiSayisi,
    DigerSayisi: TSayi2;
    Veriler: Isaretci;
  end;

type
  PHiza = ^THiza;
  THiza = (hzYok, hzUst, hzSag, hzAlt, hzSol, hzTum);
  THizalar = set of THiza;

type
  PSecimDurumu = ^TSecimDurumu;
  TSecimDurumu = (sdNormal, sdSecili);
