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

  // �NEML�
  // Integer veri tipi bellekte 2 byte'l�k yer ay�r�r. 4 byte'l�k
  // i�aretli (signed) say�sal veriler i�in LongInt kullan�lmal�d�r.

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
//  PHandle = ^THandle;
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
  TISayi1 = ISayi1;             // 1 byte'l�k i�aretli say�
  PISayi1 = ^ISayi1;            // 1 byte'l�k i�aretli say�ya i�aret�i
  TSayi1 = Sayi1;               // 1 byte'l�k i�aretsiz say�
  PSayi1 = ^Sayi1;              // 1 byte'l�k i�aretsiz say�ya i�aret�i
  TISayi2 = ISayi2;             // 2 byte'l�k i�aretli say�
  PISayi2 = ^ISayi2;            // 2 byte'l�k i�aretli say�ya i�aret�i
  TSayi2 = Sayi2;               // 2 byte'l�k i�aretsiz say�
  PSayi2 = ^Sayi2;              // 2 byte'l�k i�aretsiz say�ya i�aret�i
  TISayi4 = ISayi4;             // 4 byte'l�k i�aretli say�
  PISayi4 = ^ISayi4;            // 4 byte'l�k i�aretli say�ya i�aret�i
  TSayi4 = Sayi4;               // 4 byte'l�k i�aretsiz say�
  PSayi4 = ^Sayi4;              // 4 byte'l�k i�aretsiz say�ya i�aret�i
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

{$i paylasim.inc}

// sistem dosya arama yap�s�
type
  PDosyaArama = ^TDosyaArama;
  TDosyaArama = record
    DosyaAdi: string;                 // 8.3 dosya ad� veya uzun dosya ad�
    DosyaUzunlugu: TSayi4;
    Kimlik: TKimlik;                  // arama kimli�i
    BaslangicKumeNo: TSayi4;          // ge�ici
    Ozellikler: TSayi1;
    OlusturmaSaati: TSayi4;
    OlusturmaTarihi: TSayi4;
    SonErisimTarihi: TSayi4;
    SonDegisimSaati: TSayi4;
    SonDegisimTarihi: TSayi4;
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

const   // DST = dosya sistem tipi (FAT)
  DST_BELIRSIZ      = Byte($00);
  DST_FAT12         = Byte($01);
  DST_FAT16         = Byte($04);
  DST_FAT32         = Byte($0B);
  DST_FAT32LBA      = Byte($0C);
  DST_ELR1          = Byte($40);

// fiziksel depolama ayg�t yap�s� - program i�in
type
  PFizikselDepolama3 = ^TFizikselDepolama3;
  TFizikselDepolama3 = packed record
    Kimlik: TKimlik;
    SurucuTipi: TSayi4;
    AygitAdi: string[16];
    KafaSayisi: TSayi4;
    SilindirSayisi: TSayi4;
    IzBasinaSektorSayisi: TSayi4;
    ToplamSektorSayisi: TSayi4;
  end;

// mant�ksal depolama ayg�t yap�s� - program i�in
type
  PMantiksalDepolama3 = ^TMantiksalDepolama3;
  TMantiksalDepolama3 = packed record
    Kimlik: TKimlik;
    SurucuTipi: TSayi4;
    AygitAdi: string[16];
    DosyaSistemTipi: TSayi4;
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
  PProtokolTipi = ^TProtokolTipi;
  TProtokolTipi = (ptBilinmiyor, ptIP, ptARP, ptTCP, ptUDP, ptICMP);
  
type
  TGorevDurum = (gdBos, gdOlusturuldu, gdCalisiyor, gdDurduruldu);

type
  // program i�in (API) g�rev yap�s�
  PGorevKayit = ^TGorevKayit;
  TGorevKayit = record
    GorevDurum: TGorevDurum;            // g�rev durumu
    GorevKimlik: TKimlik;               // g�rev kimli�i - s�ra numaras�
    GorevSayaci: TSayi4;                // g�revin ka� kez �al��t���
    BellekBaslangicAdresi: TSayi4;      // g�revin yerle�tirildi�i bellek adresi
    BellekUzunlugu: TSayi4;             // g�rev bellek uzunlu�u
    OlaySayisi: TSayi4;                 // g�rev i�in i�lenmeyi bekleyen olay say�s�
    ProgramAdi: string;                 // program ad�
  end;

type
  // program i�in (API) program yap�s�
  PProgramKayit = ^TProgramKayit;
  TProgramKayit = record
    PencereKimlik: TKimlik;             // pencere kimli�i
    GorevKimlik: TKimlik;               // g�rev kimli�i
    PencereTipi: TPencereTipi;          // pencere tipi
    PencereDurum: TPencereDurum;        // pencere durumu
    ProgramAdi: string;                 // program ad�
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
    //sistem taraf�ndan gelen bilgiler
    Yol: TSayi1;
    Aygit: TSayi1;
    Islev: TSayi1;
    AYRLD0: TSayi1;
    SaticiKimlik: TSayi2;
    AygitKimlik: TSayi2;
    SinifKod: TSayi4;
    //programc� taraf�ndan gelen bilgiler
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
  PMesajTipi = ^TMesajTipi;
  TMesajTipi = (mtBilgi = 1, mtUyari, mtHata);

  PMesajKayit = ^TMesajKayit;
  TMesajKayit = record
    MesajTipi: TMesajTipi;
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
