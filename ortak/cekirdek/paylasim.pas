{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: paylasim.pas
  Dosya İşlevi: tüm birimler için ortak paylaşılan işlevleri içerir

  Güncelleme Tarihi: 25/06/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
{$modeswitch advancedrecords}
unit paylasim;

interface

{$i veritipleri.inc}

// ELERA İşletim Sistemi - çekirdek kod sistem tipleri
const
  SISTEM_TIPI_SUNUCU    = 1;
  SISTEM_TIPI_ISTEMCI   = 2;

const
  ProjeBaslangicTarihi: string = '30.07.2005';
  {$IFDEF SISTEM_SUNUCU}
  SistemTipi: TSayi4 = SISTEM_TIPI_SUNUCU;
  SistemAdi: string = 'ELERA İS (Sunucu) - 0.4.0 - R36';
  {$ELSE}
  SistemTipi: TSayi4 = SISTEM_TIPI_ISTEMCI;
  SistemAdi: string = 'ELERA İS (İstemci)- 0.4.0 - R36';
  {$ENDIF}
  DerlemeTarihi: string = {$i %DATE%};
  FPCMimari: string = {$i %FPCTARGET%};
  FPCSurum: string = {$i %FPCVERSION%};

var
  AcilisSurucuAygiti: string = 'disk1';           // disk1:\dizin1
  KLASOR_PROGRAM: string = 'progrmlr';            // programların bulunduğu dizin
  OnDegerMasaustuProgram: string = 'muyntcs.c';
  GeciciDeger: string = '';

  GorevDegistirme: TSayi4 = 0;

type
  PObject = ^TObject;

type
  { TODO - TIletisimTipi değerleri ana tiplerdir. TProtokolTipi buna göre düzenlenecek }
  PIletisimTipi = ^TIletisimTipi;
  TIletisimTipi = (itIP4, itIP6);

  PProtokolTipi = ^TProtokolTipi;
  TProtokolTipi = (ptBilinmiyor, ptIP4, ptARP, ptTCP, ptUDP, ptICMP4, ptICMP6, ptIP6);

  // bağlantıyı IP'ın tanımlayıcısı olan MAC veya yayin (broadcast) olarak gerçekleştir
  PBaglantiTipi = ^TBaglantiTipi;
  TBaglantiTipi = (btIP, btYayin);

const
  // sistemde çalışacak görev (program) sabitleri
  USTSINIR_GOREVSAYISI = 32;

  // bu değer genel video belleği olacak
  VIDEO_BELLEK_ADRESI = $A0000000;

  // sayfalama sabitleri
  SAYFA_MEVCUT      = 1;
  SAYFA_YAZILABILIR = 2;

  GERCEKBELLEK_DIZINADRESI = $600000;
  GERCEKBELLEK_TABLOADRESI = $610000;

  // boş seçici
  SECICI_SISTEM_BOS     = 0;

  // sistem seçicileri
  SECICI_SISTEM_KOD     = 1;
  SECICI_SISTEM_VERI    = 2;
  SECICI_SISTEM_TSS     = 3;

  // özel seçiciler, tüm görev seçicilerinden sonra oluşturulacak
  SECICI_GRAFIK_LFB     = (USTSINIR_GOREVSAYISI * 3) + 1;         // +1 = null seçici
  // diğer seçiciler aşağıdaki biçimde alt satırlara eklenecek
  // SECICI_DIGER_OZEL     = SECICI_GRAFIK_LFB + 1;

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

type
  TTusDurum = (tdYok, tdBasildi, tdBirakildi);

const
  SISTEME_AYRILMIS_RAM  = $0A00000;             // sistem için ayrılmış RAM = 10MB

  BELLEK_HARITA_ADRESI: PSayi4 = PSayi4($510000);

  SISTEM_ESP        = $400000 - $100;

  // program için ESP bellek adresi ve ESP uzunluğu
  // $2000 (GOREV3_ESP_U) * $20 (USTSINIR_GOREVSAYISI) = $40000
  // $400000..$440000 arası program ESP belleği için ayrılmıştır
  GOREV3_ESP_U      = $2000;                    // her bir ESP bellek uzunluğu (8192 byte)
  GOREV3_ESP        = $400000 + GOREV3_ESP_U;   // ilk program ESP bellek adresi

  BILDEN_VERIADRESI = $10008;

const
  // ağ protokolleri - değerler network sıralı
  PROTOKOL_ARP    = TSayi2($0806);

  PROTOKOL_IP4    = TSayi2($0800);
  PROTOKOL_IP6    = TSayi2($86DD);

  PROTOKOL_LLDP   = TSayi2($88CC);    // link layer discovery protocol

  PROTOKOL_TCP    = TSayi1($06);
  PROTOKOL_UDP    = TSayi1($11);

  PROTOKOL_ICMP4  = TSayi1($01);
  PROTOKOL_ICMP6  = TSayi1($3A);

const
  // genel hata kodları
  HATA_YOK                    = TISayi4(0);
  HATA_KIMLIK                 = TISayi4(-1);
  HATA_NESNE                  = TISayi4(-2);
  HATA_ATANESNE               = TISayi4(-3);
  HATA_ALTNESNEBELLEKDOLU     = TISayi4(-4);
  HATA_TUMBELLEKKULLANIMDA    = TISayi4(-5);
  HATA_ISLEV                  = TISayi4(-6);
  { TODO - hata değeri aşağıya alındı. buraya başka bir hata kodu tanımlanacak }
  //HATA_DOSYA_MEVCUTDEGIL      = TISayi4(-7);
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

  HATA_AYGITMESGUL            = TISayi4(-19);
  HATA_AYGITSEKTOROKUMA       = TISayi4(-20);
  HATA_AYGITSEKTORYAZMA       = TISayi4(-21);
  HATA_TUMSEKTORLERDOLU       = TISayi4(-22);
  HATA_AYGITHAZIRDEGIL        = TISayi4(-23);

  HATA_KLASORZATENMEVCUT      = TISayi4(-24);
  HATA_DOSYAZATENMEVCUT       = TISayi4(-25);
  HATA_AYGITOKUMA             = TISayi4(-26);
  HATA_AYGITAYAZMA            = TISayi4(-27);
  HATA_BILINMIYOR             = TISayi4(-28);
  HATA_BELLEKYOK              = TISayi4(-29);

  // dosya hata kodları
  HATA_DOSYA_ISLEM_BASARILI   = 0;
  HATA_DOSYA_MEVCUTDEGIL      = 2;
  HATA_DOSYA_KULLANIMDA       = 5;

  HATA_DOSYA_YAZILAMIYOR      = 40;     // dosya yazım işlevi için açık değil

type
  TTarihSaat = packed record
    Gun, Ay: TSayi1;
    Yil: TSayi2;
    Saat, Dakika,
    Saniye: TSayi1;
    class operator = (const A, B: TTarihSaat): Boolean;
  end;

type
  PIP4Adres = ^TIP4Adres;
  TIP4Adres = array[0..3] of TSayi1;

  // sistemin her yerinde kodlama amacıyla kullanılacak
  PIP6Adres = ^TIP6Adres;
  TIP6Adres = array[0..15] of TSayi1;

  // SADECE ekrana değer basma amacıyla kullanılacak
  PIP6Adres2 = ^TIP6Adres2;
  TIP6Adres2 = array[0..7] of TSayi2;

type
  TIPAdresIslev = record
    IPAdres: TIP4Adres;
    procedure Sifirla;
    function IPAdres0Mi: Boolean;
    function IPAdres255Mi: Boolean;
    function IPAgAraligiIcinde(AAgIPAdresi: TIP4Adres): Boolean;
    class operator = (const IP1, IP2: TIPAdresIslev): Boolean;
  end;

type
  PMACAdres = ^TMACAdres;
  TMACAdres = array[0..5] of TSayi1;

type
  TMACAdresIslev = record
    MACAdres: TMACAdres;
    procedure Sifirla;
    function MACAdres0Mi: Boolean;
    function MACAdres255Mi: Boolean;
    class operator = (const MAC1, MAC2: TMACAdresIslev): Boolean;
  end;


var
  // GN_UZUNLUK değişkeni, görsel nesne yapıları içerisinde en uzun yapılı nesne olan
  // TPencere nesnesinin uzunluğu alınarak;
  // gn_islevler.Yukle işlevi tarafından 16'nın katları olarak belirlenmiştir
  GN_UZUNLUK: TISayi4;

const
  // GN_UZUNLUK uzunluğunda tanımlanacak toplam görsel nesne sayısı
  USTSINIR_GORSELNESNE  = 256;
  USTSINIR_MASAUSTU     = 4;

var
  CekirdekBaslangicAdresi, CekirdekUzunlugu: TSayi4;

  // görevin ana penceresinin ortalanmasını sağlar
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
  PEthernetPaket = ^TEthernetPaket;
  TEthernetPaket = packed record
    HedefMACAdres,
    KaynakMACAdres: TMACAdres;
    PaketTipi: TSayi2;
    Veri: Isaretci;
  end;

{Not1: [0..3] bit = versiyon Ipv4 = 4
       [4..7] başlık uzunluğu = başlık uzunluğu * 4 (kaç tane 4 byte olduğu)

 Not2: Toplam Uzunluk: Ip uzunluğu + kendisine eklenen diğer data uzunluğu }
type
  PIP4Paket = ^TIP4Paket;
  TIP4Paket = packed record
    SurumVeBaslikUzunlugu,            // Not1
    ServisTipi: TSayi1;
    ToplamUzunluk,                    // Not2
    Tanimlayici,                      // tanımlayıcı
    ParcaSiraNo: TSayi2;              // üst 3 bit parçanın olup olmadığı, diğer bitler parça numarası
    YasamSuresi,
    Protokol: TSayi1;
    SaglamaToplami: TSayi2;
    KaynakIP,
    HedefIP: TIP4Adres;
    Veri: Isaretci;
  end;

type
  PIP6Paket = ^TIP6Paket;
  TIP6Paket = packed record
    { Baslik -> 0..3: sürüm, 4..11: Trafik Sınıfı, 12..31: Akış Etiketi }
    Baslik: TSayi4;
    // paketin kendisi haricinde taşıdığı verinin uzunluğu
    TasinanVeriU: TSayi2;
    // ip paketinin taşıdığı paket protoko tipi
    TasinanVeriP: TSayi1;
    HopLimit: TSayi1;
    KaynakIP,
    HedefIP: TIP6Adres;
    Veri: Isaretci;
  end;

type
  // tcp ve udp v6 kontrol toplamı için ek başlık yapısı
  PEk6Baslik = ^TEk6Baslik;
  TEk6Baslik = packed record         // pseudo header
    KaynakIP: TIP6Adres;
    HedefIP: TIP6Adres;
    Uzunluk: TSayi4;                  // udp veya tcp 'nin data ile beraber uzunluğu
    Sifir: array[0..2] of TSayi1;
    Protokol: TSayi1;
  end;

  // tcp ve udp v4 kontrol toplamı için ek başlık yapısı
  PEk4Baslik = ^TEk4Baslik;
  TEk4Baslik = packed record         // pseudo header
    KaynakIP: TIP4Adres;
    HedefIP: TIP4Adres;
    Sifir,
    Protokol: TSayi1;
    Uzunluk: TSayi2;                // udp veya tcp 'nin data ile beraber uzunluğu
  end;

const
  SURUCUTIP_DISKET  = 1;
  SURUCUTIP_DISK    = 2;

const   // DST = dosya sistem tipi (FAT)
  DST_BELIRSIZ      = Byte($00);
  DST_FAT12         = Byte($01);
  DST_FAT16         = Byte($04);
  DST_FAT32         = Byte($0B);
  DST_FAT32LBA      = Byte($0C);
  DST_ELR1          = Byte($40);

type
  // 12 & 16 bitlik boot kayıt yapısı
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
    // açılış kodu ve $AA55
  end;

type
  // 32 bitlik boot kayıt yapısı
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
    // açılış kodu ve $AA55
  end;

type
  PDiskBolum = ^TDiskBolum;
  TDiskBolum = packed record
    Ozellikler: TSayi1;                           // bit 7 = aktif veya boot edebilir
    CHSIlkSektor: array[0..2] of TSayi1;
    BolumTipi: TSayi1;
    CHSSonSektor: array[0..2] of TSayi1;
    LBAIlkSektor, BolumSektorSayisi: TSayi4;
  end;

type
  PGoruntuYapi = ^TGoruntuYapi;
  TGoruntuYapi = record
    Genislik, Yukseklik: TISayi4;
    BellekAdresi: Isaretci;
  end;

type
  PDizinGirisi = ^TDizinGirisi;
  TDizinGirisi = record
    IlkSektor: TSayi4;
    ToplamSektor,
    ToplamKokSektor,          // fat12 / fat16 için kök dizine tahsis edilen sektör sayısı
    IlkMumeNo: TSayi4;        // şu aşamada SADECE fat32'ye eklendi. gerekliliği araştırılacak
  end;

const
  ELR_DG_U        = 64;       // her bir dosya / klasörün dizin girdisindeki uzunluğu
  ELR_DOSYA_U     = 38;

  // girdi tipleri
  ELR_GT_DOSYA    = 1;
  ELR_GT_KLASOR   = 2;

  // girdi özellikleri
  ELR_O_SILINMIS  = 1;
  ELR_O_NORMAL    = 2;
  ELR_O_GIZLI     = 3;

  // dosya girişi zincir (küme) durumları
  ELR_ZD_SON      = TSayi4($FFFFFFFF);    // zincir sonu - başka veri yok

type
  PDizinGirdisiELR = ^TDizinGirdisiELR;
  TDizinGirdisiELR = packed record
    DosyaAdi: array[0..ELR_DOSYA_U - 1] of Char;
    GirdiTipi: TSayi1;      // dosya / klasör vb
    Ozellikler: TSayi1;     // silinmiş, gizli vb

    OlusturmaTarihi,
    OlusturmaSaati,
    DegisimTarihi,
    DegisimSaati,

    BaslangicKumeNo,
    DosyaUzunlugu: TSayi4;
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
  // dosya ayırma tablosu (file allocation table = FAT)
  PDosyaAyirmaTablosu = ^TDosyaAyirmaTablosu;
  TDosyaAyirmaTablosu = record
    IlkSektor: TSayi2;
    ToplamSektor: TSayi2;
    ZincirBasinaSektor: TSayi1;
  end;

type
  PIDEDisk = ^TIDEDisk;
  TIDEDisk = record
    AnaPort, KontrolPort: TSayi2;
    Kanal: TSayi1;
  end;

type
  TSektorIslev = function(AFizikselDepolama: Isaretci; AIlkSektor,
    ASektorSayisi: TSayi4; ABellek: Isaretci): TISayi4;

// sistem dosya arama yapısı
type
  PDosyaArama = ^TDosyaArama;
  TDosyaArama = record
    DosyaAdi: string;                 // 8.3 dosya adı veya uzun dosya adı
    DosyaUzunlugu: TSayi4;
    Kimlik: TKimlik;                  // arama kimliği
    BaslangicKumeNo: TSayi4;          // geçici
    Ozellikler: TSayi1;               { TODO: bu değişken değerleri sistem tanımlarıyla aynı olacak }
    OlusturmaSaati: TSayi4;
    OlusturmaTarihi: TSayi4;
    SonErisimTarihi: TSayi4;
    SonDegisimSaati: TSayi4;
    SonDegisimTarihi: TSayi4;
  end;

type
  PAlan = ^TAlan;
  TAlan = record
    case TSayi1 of
      0: (Sol, Ust, Sag, Alt: TISayi4);
      1: (Yatay, Dikey, Genislik, Yukseklik: TISayi4);
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
  TIslev = procedure;

type
  PTCPPaket = ^TTCPPaket;
  TTCPPaket = packed record
    {SrcIpAddr,
    DestIpAddr: TIPAdres;
    Zero: Byte;
    Protocol: Byte;
    Length: Word;               // tcp header + data}
    YerelPort,
    UzakPort: TSayi2;
    SiraNo,                     // sequence number
    OnayNo: TSayi4;
    BaslikU: TSayi1;            // 11111000 = 111111 = Data Offset, 000 = Reserved
    Bayrak: TSayi1;
    Pencere: TSayi2;
    SaglamaToplami,
    AcilIsaretci: TSayi2;       // urgent pointer
    Secenekler: Isaretci;
  end;

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
  // görsel nesnelerin kullanım tipleri
  // ktTuvalNesne = kendisine ait çizim alanı mevcuttur
  // ktNesne      = tuval nesnenin altındaki nesnedir
  // ktBilesen    = nesnenin alt nesnesi olan ktNesne özelliğindeki nesnedir
  TKullanimTipi = (ktTuvalNesne, ktNesne, ktBilesen);

type { Görsel Nesne Tipi }
  TGNTip = (gntTanimsiz, gntMasaustu, gntPencere, gntDugme, gntGucDugmesi, gntListeKutusu,
    gntMenu, gntDefter, gntIslemGostergesi, gntOnayKutusu, gntGirisKutusu, gntDegerDugmesi,
    gntEtiket, gntDurumCubugu, gntSecimDugmesi, gntBaglanti, gntResim, gntListeGorunum,
    gntPanel, gntResimDugmesi, gntKaydirmaCubugu, gntKarmaListe, gntAcilirMenu,
    gntDegerListesi, gntIzgara, gntAracCubugu, gntRenkSecici, gntSayfaKontrol);

const
  ISLEV_OLUSTUR     = $0001;
  ISLEV_GOSTER      = $0002;
  ISLEV_GIZLE       = $0003;
  ISLEV_CIZ         = $0004;
  ISLEV_BOYUTLANDIR = $0005;
  ISLEV_YOKET       = $0006;
  ISLEV_HIZALA      = $0007;
  // aşağıdaki 2 değer api işlevlerine uygulanmadı, uygulanabilir
  ISLEV_AL          = $0E;
  ISLEV_YAZ         = $0F;

type
  PSecimDurumu = ^TSecimDurumu;
  TSecimDurumu = (sdNormal, sdSecili);
  TDugmeDurumu = (ddNormal, ddBasili);
  TFareImlecTipi = (fitOK, fitGiris, fitEl, fitBoyutKBGD, fitBoyutKG,
    fitIslem, fitBekle, fitYasak, fitBoyutBD, fitBoyutKDGB, fitBoyutTum);

var
  SistemTusDurumuKontrolSol: TTusDurum;
  SistemTusDurumuKontrolSag: TTusDurum;
  SistemTusDurumuAltSol    : TTusDurum;
  SistemTusDurumuAltSag    : TTusDurum;
  SistemTusDurumuDegisimSol: TTusDurum;
  SistemTusDurumuDegisimSag: TTusDurum;

const
  // çekirdeğin ürettiği genel olaylar - çekirdek olay (CO)
  CO_ILKDEGER             = $100;
  CO_CIZIM                = CO_ILKDEGER + 0;
  CO_ZAMANLAYICI          = CO_ILKDEGER + 1;
  CO_OLUSTUR              = CO_ILKDEGER + 2;
  CO_DURUMDEGISTI         = CO_ILKDEGER + 3;
  CO_ODAKKAZANILDI        = CO_ILKDEGER + 4;
  CO_ODAKKAYBEDILDI       = CO_ILKDEGER + 5;
  CO_TUSBASILDI           = CO_ILKDEGER + 6;
  CO_TUSBIRAKILDI         = CO_ILKDEGER + 7;
  CO_MENUACILDI           = CO_ILKDEGER + 8;        // menünün açılması
  CO_MENUKAPATILDI        = CO_ILKDEGER + 9;        // menünün kapatılması
  CO_SECIMDEGISTI         = CO_ILKDEGER + 10;       // karma liste nesnesinde seçimin değişmesi olayı
  CO_SONLANDIR            = CO_ILKDEGER + 11;       // çekirdek tarafından programa gönderilen sonlandırma talimatı

  // fare aygıtının ürettiği olaylar - fare olayları (FO)
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
  // görev çubuğu iç dolgu rengi
  GOREVCUBUGU_ILKRENK       = $B9C9F9;
  GOREVCUBUGU_SONRENK       = $A1B7F7;

  // düğme dolgu renkleri
  DUGME_NORMAL_ILKRENK      = GOREVCUBUGU_ILKRENK;
  DUGME_NORMAL_SONRENK      = GOREVCUBUGU_SONRENK;
  DUGME_NORMAL_YAZIRENK     = RENK_SIYAH;

  DUGME_BASILI_ILKRENK      = $609FCC;
  DUGME_BASILI_SONRENK      = $2C6187;
  DUGME_BASILI_YAZIRENK     = RENK_BEYAZ;

type
  PTSS = ^TTSS;
  TTSS = packed record
    OncekiTSS, A00: TSayi2;     // A(00)yrıldı
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
    TBit: TSayi2;               // yakalayıcı (trap) bit. hata ayıklama amaçlı
    IOHaritaGAdres: TSayi2;     // IOHarita yapı başından uzaklık bellek adresi
    // buraya kadar 104 byte.

    IOHarita: Isaretci;
    // IO port izin haritası kulanılacaksa her bir görev için
    // 65536 / 8 = 8192 byte alan gerekmektedir
  end;

var
  AgYuklendi: Boolean = False;

  SistemSayaci, CagriSayaci, GrafikSayaci: TSayi4;
  ZamanlayiciSayaci: TSayi4 = 0;
  // görev değişiminin yapılıp yapılmaması değişkeni.
  // 0 = görev değiştirme, 1 = görev değiştir
  GorevDegisimBayragi: TSayi4 = 0;
  // çoklu görev işleminin başlayıp başlamadığını gösteren değişken
  // 0 = başlamadı, 1 = başladı
  CokluGorevBasladi: TSayi4 = 0;

  GecerliFareGostegeTipi: TFareImlecTipi;

  // ağ - gelen paket sayıları
  ICMP4PaketSayisi: TSayi4 = 0;
  ICMP6PaketSayisi: TSayi4 = 0;
  TCP4PaketSayisi: TSayi4 = 0;
  TCP6PaketSayisi: TSayi4 = 0;
  UDPPaketSayisi: TSayi4 = 0;
  GAEPaketSayisi: TSayi4 = 0;     // GözArdıEdilen paket sayısı

  // sistem açılışında çekirdeğin yüklendiği tarih + saat
  // bilgi: bu değişken yapısı, çekirdek dosyasının (cekirdek.bin) sistemin yükleme
  // sonrasında değişimini takip içindir
  CekirdekYuklemeTS: TTarihSaat;

  BellekDegeriniGoster: Boolean = False;

  MAC333300000001: TMACAdres = ($33, $33, $00, $00, $00, $01);
  MAC333300000002: TMACAdres = ($33, $33, $00, $00, $00, $02);
  MAC333300000102: TMACAdres = ($33, $33, $00, $01, $00, $02);

  YayinMAC6: TMACAdres = ($33, $33, $ff, $cd, $ef, $01);

const
  IP6AdresFF02_0002: TIP6Adres = (
    $ff, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02);

  IP6AdresFF02_0102: TIP6Adres = (
    $ff, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00, $02);

  YayinIP6Adresi: TIP6Adres = (
    $ff, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $ff, $cd, $ef, $01);

var
  UzunDosyaAdi: array[0..511] of Char;

const
  TSS_UZUNLUK = 104 + 8192;   // 104 byte TSS, 8192 byte giriş / çıkış port izin haritası

var
  GorevTSSListesi: array[0..USTSINIR_GOREVSAYISI - 1] of PTSS;

type
  TGorevDurum = (gdIptal, gdOlusturuldu, gdCalisiyor, gdDurduruldu, gdSonlandiriliyor);

type
  PPencereTipi = ^TPencereTipi;
  TPencereTipi = (ptBasliksiz, ptIletisim, ptBoyutlanabilir);

  { TODO : sadece başlığın görüntüleneceği bir durum eklenecek }
  PPencereDurum = ^TPencereDurum;
  TPencereDurum = (pdNormal, pdKucultuldu, pdBuyutuldu);

type
  // program için (API) görev yapısı
  PGorevKayit = ^TGorevKayit;
  TGorevKayit = record
    GorevDurum: TGorevDurum;            // görev durumu
    GorevKimlik: TKimlik;               // görev kimliği - sıra numarası
    GorevSayaci: TSayi4;                // görevin kaç kez çalıştığı
    BellekBaslangicAdresi: TSayi4;      // görevin yerleştirildiği bellek adresi
    BellekUzunlugu: TSayi4;             // görev bellek uzunluğu + yığın bellek uzunluğu
    OlaySayisi: TSayi4;                 // görev için işlenmeyi bekleyen olay sayısı
    DosyaAdi: string;                   // programın yüklendiği dosya adı
  end;

type
  // program için (API) program yapısı
  PProgramKayit = ^TProgramKayit;
  TProgramKayit = record
    PencereKimlik: TKimlik;             // pencere kimliği
    GorevKimlik: TKimlik;               // görev kimliği
    PencereTipi: TPencereTipi;          // pencere tipi
    PencereDurum: TPencereDurum;        // pencere durumu
    DosyaAdi: string;                   // programın yüklendiği dosya adı
  end;

type
  PSistemBilgisi = ^TSistemBilgisi;
  TSistemBilgisi = record
    SistemAdi, DerlemeBilgisi,
    FPCMimari, FPCSurum: string;
    YatayCozunurluk, DikeyCozunurluk: TSayi4;
  end;

type
  PRGB32Bit = ^TRGB32Bit;
  TRGB32Bit = packed record
    B, G, R, A: TSayi1;
  end;

type
  PRGB24Bit = ^TRGB24Bit;
  TRGB24Bit = packed record
    B, G, R: TSayi1;
  end;

var
  // ip adresinin otomatik alınıp alınmaması durumu bu değişkenler kontrol edilmektedir
  IPAdresiniOtomatikAl: Boolean;

type
  PAgBilgisi = ^TAgBilgisi;
  TAgBilgisi = record
    MACAdres: TMACAdres;
    IP4Adres, AltAgMaskesi, AgGecitAdresi,
    DHCPSunucusu, DNSSunucusu: TIP4Adres;
    IPKiraSuresi: TSayi4;     // saniye cinsinden

    { TODO - OtomatikIP değeri üstteki yapıya eklenerek API'nın bir parçası olacaktır }
    OtomatikIP: Boolean;      // ip adresi dhcp sunucusundan otomatik alınacak

    // yukarıdaki yapı için API işlevi oluşturulmuştur, sıralamanın bozulması işlevin bozulması demektir
    YenidenIPAdresiAliniyor: Boolean;

    { TODO - yukarıdaki yapıya dahil edilecektir }
    IP6Adres: TIP6Adres;
  end;

var
  // çekirdek genelinde kullanılan ortak yapılar / değişkenler

  // sistemin çalıştığı bilgisayarın adı - bu bilgisayarın adı
  GBilgisayarAdi: string = 'elera';         // netbios için GBilgisayarAdi + GAlanAdi uzunluğu 15 byte'ı geçmemeli
  GAlanAdi: string = 'elr.com';
  GTamBilgisayarAdi: string;                // ag.Yukle tarafından atanmaktadır

  GGrupAdi: string = 'programlama';         // sistemin grup olarak çalıştığı ağ adı
  // GAgBilgisi yapı içeriği ag.IlkAdresDegerleriniYukle işlevi tarafından doldurulmaktadır
  GAgBilgisi: TAgBilgisi;

  IP6Adres0: TIP6Adres = ($00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00);
  IP4Adres0: TIP4Adres = (0, 0, 0, 0);
  IPAdres255: TIP4Adres = (255, 255, 255, 255);
  MACAdres0: TMACAdres = (0, 0, 0, 0, 0, 0);
  MACAdres255: TMACAdres = (255, 255, 255, 255, 255, 255);

  // TGirisKutusu nesnesinden Ctrl + C ile alınan içerik verisi
  PanoDegeri: string = '';

  SistemUyariBellekAdresi: Isaretci;

function NoktaAlanIcindeMi(ANokta: TKonum; AAlan: TAlan): Boolean;
function SaglamaToplamiOlustur(AVeriAdresi: Isaretci; AVeriUzunlugu: TSayi2;
  ASahteBaslikAdresi: Isaretci; ASahteBaslikUzunlugu: TSayi2): TSayi2;
function ProtokolTipAdi(AProtokolTipi: TProtokolTipi): string;
procedure EkleByte(AHedef: Isaretci; const ADeger: TSayi1);
procedure Ekle2Byte(AHedef: Isaretci; const ADeger: TSayi2);
procedure Ekle4Byte(AHedef: Isaretci; const ADeger: TSayi4);
function KritikBolgeyeGir(var ABellek: TSayi4): Boolean;
procedure KritikBolgedenCik(var ABellek: TSayi4);
function TarihSaatBilgisiAl: string;

implementation

uses cmos, donusum;

function NoktaAlanIcindeMi(ANokta: TKonum; AAlan: TAlan): Boolean;
begin

  Result := False;

  if(ANokta.Sol >= AAlan.Sol) and (ANokta.Sol <= AAlan.Sag) and
    (ANokta.Ust >= AAlan.Ust) and (ANokta.Ust <= AAlan.Alt) then

  Result := True;
end;

{==============================================================================
  verilerin toplam sağlama işlemini gerçekleştirir
 ==============================================================================}
{
  kontrol toplamı örneği:
  08 00 00 00 00 01 00 a7 61 62 63 64 65 66 67 68
  69 6a 6b

  önemli: kontrol toplamı yapılırken, değerlerin içerisinde sağlama (checksum) değeri
  var ise sağlama değeri işlem öncesi mutlaka sıfırlanmalıdır.

  0800
  0000
  0001
  0047
  6162
  6364
  6566
  6768        1. toplama işleminden sonra, yüksek 16 bitlik değer ($2) alçak 16
  696a        bitlik değere ($03B1) eklenir. $03B1 + $2 = $03B3
    6b
+-------      2. $03B3 değeri mantıksal NOT işlemine tabi tutulur. $03B3 -> $FC4C
 203B1


  önemli: işlevin geri dönüş değeri (sık kullanımdan dolayı) byte değerler ters sırada
    geri döndürülür. örneğin, değer $CDAB ise bu değer geriye ABCD olarak döndürülür
}
function SaglamaToplamiOlustur(AVeriAdresi: Isaretci; AVeriUzunlugu: TSayi2;
  ASahteBaslikAdresi: Isaretci; ASahteBaslikUzunlugu: TSayi2): TSayi2;
var
  WordVeriAdresi: PSayi2;
  i, WordVeriUzunlugu: TSayi2;
  SaglamaToplami: TSayi4;
begin

  // eğer veri bellek adresi verilmemiş veya uzunluk 0 ise çık
  if(AVeriAdresi = nil) or (AVeriUzunlugu = 0) then Exit(0);

  // sağlama toplamı ilk değer ataması
  SaglamaToplami := 0;

  // 1. önce veri değerlerini topla
  //----------------------------------------------------------------------------

  // toplanacak word sayısı
  WordVeriUzunlugu := (AVeriUzunlugu shr 1);

  // word değerleri topla
  WordVeriAdresi := AVeriAdresi;
  if(WordVeriUzunlugu > 1) then
  begin

    for i := 0 to WordVeriUzunlugu - 1 do
    begin

      SaglamaToplami := SaglamaToplami + WordVeriAdresi^;
      Inc(WordVeriAdresi);
    end;
  end;

  // eğer geriye tek değer (byte) kaldıysa onu da toplama ekle
  if((AVeriUzunlugu mod 2) = 1) then
  begin

    SaglamaToplami := SaglamaToplami + PByte(WordVeriAdresi)^;
  end;

  // 2. daha sonra (var) ise sahte başlık değerlerini topla
  //----------------------------------------------------------------------------
  if(ASahteBaslikAdresi <> nil) and (ASahteBaslikUzunlugu > 0) then
  begin

    // toplanacak word sayısı
    WordVeriUzunlugu := (ASahteBaslikUzunlugu shr 1);

    // word değerleri topla
    WordVeriAdresi := ASahteBaslikAdresi;
    if(WordVeriUzunlugu > 1) then
    begin

      for i := 0 to WordVeriUzunlugu - 1 do
      begin

        SaglamaToplami := SaglamaToplami + WordVeriAdresi^;
        Inc(WordVeriAdresi);
      end;
    end;

    // eğer geriye tek değer (byte) kaldıysa onu da toplama ekle
    if((ASahteBaslikUzunlugu mod 2) = 1) then
    begin

      SaglamaToplami := SaglamaToplami + PByte(WordVeriAdresi)^;
    end;
  end;

  // word değeri aşan (17 ve sonraki bitler) kısmı ilk 16 bit değere ekle
  SaglamaToplami := (SaglamaToplami mod $10000) + (SaglamaToplami div $10000);

  // son olarak değeri ters çevir
  Result := not SaglamaToplami;
end;

function ProtokolTipAdi(AProtokolTipi: TProtokolTipi): string;
begin

  case AProtokolTipi of
    ptIP4   : Result := 'IP4';
    ptARP   : Result := 'ARP';
    ptTCP   : Result := 'TCP';
    ptUDP   : Result := 'UDP';
    ptICMP4 : Result := 'ICMP4';
    else {ptBilinmiyor:} Result := 'Bilinmiyor';
  end;
end;

// indy yardımcı işlev - veriye word değer ekleme (veriler big-endian biçiminde)
procedure EkleByte(AHedef: Isaretci; const ADeger: TSayi1);
begin

  PSayi1(AHedef)^ := ADeger;
end;

// indy yardımcı işlev - veriye word değer ekleme (veriler big-endian biçiminde)
procedure Ekle2Byte(AHedef: Isaretci; const ADeger: TSayi2);
begin

  EkleByte(AHedef + 0, Byte(ADeger shr 8));
  EkleByte(AHedef + 1, Byte(ADeger and $FF));
end;

// indy yardımcı işlev - veriye dword değer ekleme (veriler big-endian biçiminde)
procedure Ekle4Byte(AHedef: Isaretci; const ADeger: TSayi4);
begin

  EkleByte(AHedef + 0, Byte(ADeger shr 24));
  EkleByte(AHedef + 1, Byte(ADeger shr 16));
  EkleByte(AHedef + 2, Byte(ADeger shr 8));
  EkleByte(AHedef + 3, Byte(ADeger and $FF));
end;

{ TMACAdresIslev }

class operator TMACAdresIslev.=(const MAC1, MAC2: TMACAdresIslev): Boolean;
var
  i: TSayi4;
begin

  for i := 0 to 5 do
  begin

    if(MAC1.MACAdres[i] <> MAC2.MACAdres[i]) then Exit(False);
  end;

  Result := True;
end;

procedure TMACAdresIslev.Sifirla;
var
  i: TSayi4;
begin

  for i := 0 to 5 do MACAdres[i] := 0;
end;

function TMACAdresIslev.MACAdres0Mi: Boolean;
var
  i: TSayi4;
begin

  for i := 0 to 5 do
  begin

    if(MACAdres[i] <> 0) then Exit(False);
  end;

  Result := True;
end;

function TMACAdresIslev.MACAdres255Mi: Boolean;
var
  i: TSayi4;
begin

  for i := 0 to 5 do
  begin

    if(MACAdres[i] <> 255) then Exit(False);
  end;

  Result := True;
end;

procedure TIPAdresIslev.Sifirla;
var
  i: TSayi4;
begin

  for i := 0 to 3 do IPAdres[i] := 0;
end;

function TIPAdresIslev.IPAdres0Mi: Boolean;
var
  i: TSayi4;
begin

  for i := 0 to 3 do
  begin

    if(IPAdres[i] <> 0) then Exit(False);
  end;

  Result := True;
end;

function TIPAdresIslev.IPAdres255Mi: Boolean;
var
  i: TSayi4;
begin

  for i := 0 to 3 do
  begin

    if(IPAdres[i] <> 255) then Exit(False);
  end;

  Result := True;
end;

// ip adresinin ağ adres aralığı içerisinde olup olmadığını kontrol eder
// örnek:
// istenen ip adresi: 192.168.1.110
// dhcp ip adresi   : 192.168.1.1
// ilk 3 byte değerinin aynı olması ip adresinin aynı ağda olduğunu gösterir
function TIPAdresIslev.IPAgAraligiIcinde(AAgIPAdresi: TIP4Adres): Boolean;
var
  i: TSayi4;
begin

  for i := 0 to 2 do
  begin

    if(IPAdres[i] <> AAgIPAdresi[i]) then Exit(False);
  end;

  Result := True;
end;


class operator TIPAdresIslev.=(const IP1, IP2: TIPAdresIslev): Boolean;
var
  i: TSayi4;
begin

  for i := 0 to 3 do
  begin

    if(IP1.IPAdres[i] <> IP2.IPAdres[i]) then Exit(False);
  end;

  Result := True;
end;

class operator TTarihSaat.=(const A, B: TTarihSaat): Boolean;
begin

  if(A.Gun = B.Gun) and (A.Ay = B.Ay) and (A.Yil = B.Yil) and
    (A.Saat = B.Saat) and (A.Dakika = B.Dakika) and (A.Saniye = B.Saniye) then
    Result := True
  else Result := False;
end;

function KritikBolgeyeGir(var ABellek: TSayi4): Boolean;
begin

  if(ABellek = 1) then Exit(False);

  ABellek := 1;

  Result := True;
end;

procedure KritikBolgedenCik(var ABellek: TSayi4);
begin

  ABellek := 0;
end;

function TarihSaatBilgisiAl: string;
var
  Gun, Ay, Yil, HG: TSayi2;
  Saat, Dakika, Saniye: TSayi1;
begin

  TarihAl(Gun, Ay, Yil, HG);
  SaatAl(Saat, Dakika, Saniye);

  Result := IntToStr(Gun) + '.' + IntToStr(Ay) + '.' + IntToStr(Yil) +
    ' - ' + IntToStr(Saat) + ':' + IntToStr(Dakika) + '.' + IntToStr(Saniye);
end;

end.
