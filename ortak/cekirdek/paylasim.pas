{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: paylasim.pas
  Dosya ��levi: t�m birimler i�in ortak payla��lan i�levleri i�erir

  G�ncelleme Tarihi: 26/02/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
{$modeswitch advancedrecords}
unit paylasim;

interface

{$i veritipleri.inc}

// ELERA ��letim Sistemi - �ekirdek kod sistem tipleri
const
  SISTEM_TIPI_SUNUCU    = 1;
  SISTEM_TIPI_ISTEMCI   = 2;

const
  ProjeBaslangicTarihi: string = '30.07.2005';
  {$IFDEF SISTEM_SUNUCU}
  SistemTipi: TSayi4 = SISTEM_TIPI_SUNUCU;
  SistemAdi: string = 'ELERA �S (Sunucu) - 0.3.8 - R34';
  {$ELSE}
  SistemTipi: TSayi4 = SISTEM_TIPI_ISTEMCI;
  SistemAdi: string = 'ELERA �S (�stemci)- 0.3.8 - R34';
  {$ENDIF}
  DerlemeTarihi: string = {$i %DATE%};
  FPCMimari: string = {$i %FPCTARGET%};
  FPCSurum: string = {$i %FPCVERSION%};

var
  AcilisSurucuAygiti: string = 'disk1';           // disk1:\dizin1
  KLASOR_PROGRAM: string = 'progrmlr';            // programlar�n bulundu�u dizin
  OnDegerMasaustuProgram: string = 'muyntcs.c';
  GeciciDeger: string = '';

  GorevDegistirme: TSayi4 = 0;

type
  PObject = ^TObject;

type
  PProtokolTipi = ^TProtokolTipi;
  TProtokolTipi = (ptBilinmiyor, ptIP, ptARP, ptTCP, ptUDP, ptICMP);

  // ba�lant�y� IP'�n tan�mlay�c�s� olan MAC veya yayin (broadcast) olarak ger�ekle�tir
  PBaglantiTipi = ^TBaglantiTipi;
  TBaglantiTipi = (btIP, btYayin);

const
  // sistemde �al��acak g�rev (program) sabitleri
  USTSINIR_GOREVSAYISI = 32;

  // bu de�er genel video belle�i olacak
  VIDEO_BELLEK_ADRESI = $A0000000;

  // sayfalama sabitleri
  SAYFA_MEVCUT      = 1;
  SAYFA_YAZILABILIR = 2;

  GERCEKBELLEK_DIZINADRESI = $600000;
  GERCEKBELLEK_TABLOADRESI = $610000;

  // bo� se�ici
  SECICI_SISTEM_BOS     = 0;

  // sistem se�icileri
  SECICI_SISTEM_KOD     = 1;
  SECICI_SISTEM_VERI    = 2;
  SECICI_SISTEM_TSS     = 3;

  // �zel se�iciler, t�m g�rev se�icilerinden sonra olu�turulacak
  SECICI_GRAFIK_LFB     = (USTSINIR_GOREVSAYISI * 3) + 1;         // +1 = null se�ici
  // di�er se�iciler a�a��daki bi�imde alt sat�rlara eklenecek
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
  SISTEME_AYRILMIS_RAM  = $0A00000;             // sistem i�in ayr�lm�� RAM = 10MB

  BELLEK_HARITA_ADRESI: PByte = PByte($510000);

  SISTEM_ESP        = $300000 + $1000;

  // program i�in ESP bellek adresi ve ESP uzunlu�u
  // $2000 (GOREV3_ESP_U) * $20 (USTSINIR_GOREVSAYISI) = $40000
  // $400000..$440000 aras� program ESP belle�i i�in ayr�lm��t�r
  GOREV3_ESP_U      = $2000;                    // her bir ESP bellek uzunlu�u (8192 byte)
  GOREV3_ESP        = $400000 + GOREV3_ESP_U;   // ilk program ESP bellek adresi

  BILDEN_VERIADRESI = $10008;

const
  // a� protokolleri - de�erler network s�ral�
  PROTOKOL_ARP  = TSayi2($0806);
  PROTOKOL_IP   = TSayi2($0800);

  PROTOKOL_TCP  = TSayi1($06);
  PROTOKOL_UDP  = TSayi1($11);
  PROTOKOL_ICMP = TSayi1($01);

const
  // genel hata kodlar�
  HATA_YOK                    = TISayi4(0);
  HATA_KIMLIK                 = TISayi4(-1);
  HATA_NESNE                  = TISayi4(-2);
  HATA_ATANESNE               = TISayi4(-3);
  HATA_ALTNESNEBELLEKDOLU     = TISayi4(-4);
  HATA_TUMBELLEKKULLANIMDA    = TISayi4(-5);
  HATA_ISLEV                  = TISayi4(-6);
  { TODO - hata de�eri a�a��ya al�nd�. buraya ba�ka bir hata kodu tan�mlanacak }
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

  // dosya hata kodlar�
  HATA_DOSYA_ISLEM_BASARILI   = 0;
  HATA_DOSYA_MEVCUTDEGIL      = 2;
  HATA_DOSYA_KULLANIMDA       = 5;

  HATA_DOSYA_YAZILAMIYOR      = 40;     // dosya yaz�m i�levi i�in a��k de�il

type
  TTarihSaat = record
    Gun, Ay: TSayi1;
    Yil: TSayi2;
    Saat, Dakika,
    Saniye: TSayi1;
    class operator = (const A, B: TTarihSaat): Boolean;
  end;

type
  PIPAdres = ^TIPAdres;
  TIPAdres = array[0..3] of TSayi1;

type
  TIPAdresIslev = record
    IPAdres: TIPAdres;
    procedure Sifirla;
    function IPAdres0Mi: Boolean;
    function IPAdres255Mi: Boolean;
    function IPAgAraligiIcinde(AAgIPAdresi: TIPAdres): Boolean;
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
  // GN_UZUNLUK de�i�keni, g�rsel nesne yap�lar� i�erisinde en uzun yap�l� nesne olan
  // TPencere nesnesinin uzunlu�u al�narak;
  // gn_islevler.Yukle i�levi taraf�ndan 16'n�n katlar� olarak belirlenmi�tir
  GN_UZUNLUK: TISayi4;

const
  // GN_UZUNLUK uzunlu�unda tan�mlanacak toplam g�rsel nesne say�s�
  USTSINIR_GORSELNESNE  = 256;
  USTSINIR_MASAUSTU     = 4;

var
  CekirdekBaslangicAdresi, CekirdekUzunlugu: TSayi4;

  // g�revin ana penceresinin ortalanmas�n� sa�lar
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
       [4..7] ba�l�k uzunlu�u = ba�l�k uzunlu�u * 4 (ka� tane 4 byte oldu�u)

 Not2: Toplam Uzunluk: Ip uzunlu�u + kendisine eklenen di�er data uzunlu�u }
type
  PIPPaket = ^TIPPaket;
  TIPPaket = packed record
    SurumVeBaslikUzunlugu,            // Not1
    ServisTipi: TSayi1;
    ToplamUzunluk,                    // Not2
    Tanimlayici,                      // tan�mlay�c�
    ParcaSiraNo: TSayi2;              // �st 3 bit par�an�n olup olmad���, di�er bitler par�a numaras�
    YasamSuresi,
    Protokol: TSayi1;
    SaglamaToplami: TSayi2;
    KaynakIP,
    HedefIP: TIPAdres;
    Veri: Isaretci;
  end;

type
  // tcp ve udp kontrol toplam� i�in ek ba�l�k yap�s�
  PEkBaslik = ^TEkBaslik;
  TEkBaslik = packed record         // pseudoheader
    KaynakIP: TIPAdres;
    HedefIP: TIPAdres;
    Sifir,
    Protokol: TSayi1;
    Uzunluk: TSayi2;                // udp veya tcp 'nin data ile beraber uzunlu�u
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
  // 12 & 16 bitlik boot kay�t yap�s�
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
    DATBasinaSektor: Word;                    // 22..23   - SADECE FAT12 / FAT16 i�in
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
    // a��l�� kodu ve $AA55
  end;

type
  // 32 bitlik boot kay�t yap�s�
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
    DAT1xBasinaSektor: Word;                  // 22..23   - SADECE FAT12 / FAT16 i�in
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
    // a��l�� kodu ve $AA55
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
    ToplamSektor: TSayi4;
  end;

const
  ELR_DG_U        = 64;       // her bir dosya / klas�r�n dizin girdisindeki uzunlu�u
  ELR_DOSYA_U     = 38;

  // girdi tipleri
  ELR_GT_DOSYA    = 1;
  ELR_GT_KLASOR   = 2;

  // girdi �zellikleri
  ELR_O_SILINMIS  = 1;
  ELR_O_NORMAL    = 2;
  ELR_O_GIZLI     = 3;

  // dosya giri�i zincir (k�me) durumlar�
  ELR_ZD_SON      = TSayi4($FFFFFFFF);    // zincir sonu - ba�ka veri yok

type
  PDizinGirdisiELR = ^TDizinGirdisiELR;
  TDizinGirdisiELR = packed record
    DosyaAdi: array[0..ELR_DOSYA_U - 1] of Char;
    GirdiTipi: TSayi1;      // dosya / klas�r vb
    Ozellikler: TSayi1;     // silinmi�, gizli vb

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
  // dosya ay�rma tablosu (file allocation table = FAT)
  PDosyaAyirmaTablosu = ^TDosyaAyirmaTablosu;
  TDosyaAyirmaTablosu = record
    IlkSektor: TSayi2;
    ToplamSektor: TSayi2;
    ZincirBasinaSektor: TSayi1;
  end;

type
  PAcilis = ^TAcilis;     // acilis = boot
  TAcilis = record
    DizinGirisi: TDizinGirisi;
    DosyaAyirmaTablosu: TDosyaAyirmaTablosu;
    IlkVeriSektorNo: TSayi4;
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
  TIslev = procedure;

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
  // g�rsel nesnelerin kullan�m tipleri
  // ktTuvalNesne = kendisine ait �izim alan� mevcuttur
  // ktNesne      = tuval nesnenin alt�ndaki nesnedir
  // ktBilesen    = nesnenin alt nesnesi olan ktNesne �zelli�indeki nesnedir
  TKullanimTipi = (ktTuvalNesne, ktNesne, ktBilesen);

type { G�rsel Nesne Tipi }
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
  // a�a��daki 2 de�er api i�levlerine uygulanmad�, uygulanabilir
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
  // �ekirde�in �retti�i genel olaylar - �ekirdek olay (CO)
  CO_ILKDEGER             = $100;
  CO_CIZIM                = CO_ILKDEGER + 0;
  CO_ZAMANLAYICI          = CO_ILKDEGER + 1;
  CO_OLUSTUR              = CO_ILKDEGER + 2;
  CO_DURUMDEGISTI         = CO_ILKDEGER + 3;
  CO_ODAKKAZANILDI        = CO_ILKDEGER + 4;
  CO_ODAKKAYBEDILDI       = CO_ILKDEGER + 5;
  CO_TUSBASILDI           = CO_ILKDEGER + 6;
  CO_TUSBIRAKILDI         = CO_ILKDEGER + 7;
  CO_MENUACILDI           = CO_ILKDEGER + 8;        // men�n�n a��lmas�
  CO_MENUKAPATILDI        = CO_ILKDEGER + 9;        // men�n�n kapat�lmas�
  CO_SECIMDEGISTI         = CO_ILKDEGER + 10;       // karma liste nesnesinde se�imin de�i�mesi olay�
  CO_SONLANDIR            = CO_ILKDEGER + 11;       // �ekirdek taraf�ndan programa g�nderilen sonland�rma talimat�

  // fare ayg�t�n�n �retti�i olaylar - fare olaylar� (FO)
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
  // g�rev �ubu�u i� dolgu rengi
  GOREVCUBUGU_ILKRENK       = $B9C9F9;
  GOREVCUBUGU_SONRENK       = $A1B7F7;

  // d��me dolgu renkleri
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

    // A(ktif), (P)asif kontrol d��me (R)esim (S)�ra numaralar�
    AKapatmaDugmesiRSNo, ABuyutmeDugmesiRSNo, AKucultmeDugmesiRSNo,
    PKapatmaDugmesiRSNo, PBuyutmeDugmesiRSNo, PKucultmeDugmesiRSNo: TSayi4;
  end;

var
  AktifGiysi: TGiysi;
  AktifGiysiSiraNo: TISayi4 = 0;

type
  PTSS = ^TTSS;
  TTSS = packed record
    OncekiTSS, A00: TSayi2;     // A(00)yr�ld�
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
    TBit: TSayi2;               // yakalay�c� (trap) bit. hata ay�klama ama�l�
    IOHaritaGAdres: TSayi2;     // IOHarita yap� ba��ndan uzakl�k bellek adresi
    // buraya kadar 104 byte.

    IOHarita: Isaretci;
    // IO port izin haritas� kulan�lacaksa her bir g�rev i�in
    // 65536 / 8 = 8192 byte alan gerekmektedir
  end;

var
  AgYuklendi: Boolean = False;

  SistemSayaci, CagriSayaci, GrafikSayaci: TSayi4;
  ZamanlayiciSayaci: TSayi4 = 0;
  // g�rev de�i�iminin yap�l�p yap�lmamas� de�i�keni.
  // 0 = g�rev de�i�tirme, 1 = g�rev de�i�tir
  GorevDegisimBayragi: TSayi4 = 0;
  // �oklu g�rev i�leminin ba�lay�p ba�lamad���n� g�steren de�i�ken
  // 0 = ba�lamad�, 1 = ba�lad�
  CokluGorevBasladi: TSayi4 = 0;

  GecerliFareGostegeTipi: TFareImlecTipi;

  // a� - gelen paket say�lar�
  ICMPPaketSayisi: TSayi4 = 0;
  TCPPaketSayisi: TSayi4 = 0;
  UDPPaketSayisi: TSayi4 = 0;
  GAEPaketSayisi: TSayi4 = 0;     // G�zArd�Edilen paket say�s�

  // sistem a��l���nda �ekirde�in y�klendi�i tarih + saat
  // bilgi: bu de�i�ken yap�s�, �ekirdek dosyas�n�n (cekirdek.bin) sistemin y�kleme
  // sonras�nda de�i�imini takip i�indir
  CekirdekYuklemeTS: TTarihSaat;

  BellekDegeriniGoster: Boolean = False;

var
  UzunDosyaAdi: array[0..511] of Char;

const
  TSS_UZUNLUK = 104 + 8192;   // 104 byte TSS, 8192 byte giri� / ��k�� port izin haritas�

var
  GorevTSSListesi: array[0..USTSINIR_GOREVSAYISI - 1] of PTSS;

type
  TGorevDurum = (gdIptal, gdOlusturuldu, gdCalisiyor, gdDurduruldu, gdSonlandiriliyor);

type
  PPencereTipi = ^TPencereTipi;
  TPencereTipi = (ptBasliksiz, ptIletisim, ptBoyutlanabilir);

  { TODO : sadece ba�l���n g�r�nt�lenece�i bir durum eklenecek }
  PPencereDurum = ^TPencereDurum;
  TPencereDurum = (pdNormal, pdKucultuldu, pdBuyutuldu);

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
    DosyaAdi: string;                   // program�n y�klendi�i dosya ad�
  end;

type
  // program i�in (API) program yap�s�
  PProgramKayit = ^TProgramKayit;
  TProgramKayit = record
    PencereKimlik: TKimlik;             // pencere kimli�i
    GorevKimlik: TKimlik;               // g�rev kimli�i
    PencereTipi: TPencereTipi;          // pencere tipi
    PencereDurum: TPencereDurum;        // pencere durumu
    DosyaAdi: string;                   // program�n y�klendi�i dosya ad�
  end;

type
  PSistemBilgisi = ^TSistemBilgisi;
  TSistemBilgisi = record
    SistemAdi, DerlemeBilgisi,
    FPCMimari, FPCSurum: string;
    YatayCozunurluk, DikeyCozunurluk: TSayi4;
  end;

type
  PRGB = ^TRGBRenk;
  TRGBRenk = packed record
    B: TSayi1;
    G: TSayi1;
    R: TSayi1;
    AYRLD: TSayi1;    // ayr�ld�
  end;

var
  // ip adresinin otomatik al�n�p al�nmamas� durumu bu de�i�kenler kontrol edilmektedir
  IPAdresiniOtomatikAl: Boolean;

type
  PAgBilgisi = ^TAgBilgisi;
  TAgBilgisi = record
    MACAdres: TMACAdres;
    IP4Adres, AltAgMaskesi, AgGecitAdresi,
    DHCPSunucusu, DNSSunucusu: TIPAdres;
    IPKiraSuresi: TSayi4;     // saniye cinsinden

    { TODO - OtomatikIP de�eri �stteki yap�ya eklenerek API'n�n bir par�as� olacakt�r }
    OtomatikIP: Boolean;      // ip adresi dhcp sunucusundan otomatik al�nacak

    // yukar�daki yap� i�in API i�levi olu�turulmu�tur, s�ralaman�n bozulmas� i�levin bozulmas� demektir
    IPAdresiAlindi: Boolean;
  end;

var
  // �ekirdek genelinde kullan�lan ortak yap�lar / de�i�kenler

  // sistemin �al��t��� bilgisayar�n ad� - bu bilgisayar�n ad�
  GBilgisayarAdi: string = 'elera';         // netbios i�in GBilgisayarAdi + GAlanAdi uzunlu�u 15 byte'� ge�memeli
  GAlanAdi: string = 'elr.com';
  GTamBilgisayarAdi: string;                // ag.Yukle taraf�ndan atanmaktad�r

  GGrupAdi: string = 'programlama';         // sistemin grup olarak �al��t��� a� ad�
  // GAgBilgisi yap� i�eri�i ag.IlkAdresDegerleriniYukle i�levi taraf�ndan doldurulmaktad�r
  GAgBilgisi: TAgBilgisi;

  // otomatik atama olmad��� durumda sistemin kullanaca�� ip adres de�erleri
  OnDegerIPAdresi: TIPAdres = (10, 0, 0, 1);
  OnDegerAltAgMaskesi: TIPAdres = (255, 255, 255, 0);

  { TODO - dns sunucusu taraf�ndan yap�land�r�lacak, �u a�amada dhcp sunucu taraf�ndan
    g�nderilecek de�er olarak belirlenmi�tir }
  // a�a��daki 2 de�er �u a�amada dhcp sunucusu taraf�ndan kullan�lmaktad�r
  GDNSIPAdresi: TIPAdres = (127, 0, 0, 1);
  GAgGecidi: TIPAdres = (127, 0, 0, 1);

  IPAdres0: TIPAdres = (0, 0, 0, 0);
  IPAdres255: TIPAdres = (255, 255, 255, 255);
  MACAdres0: TMACAdres = (0, 0, 0, 0, 0, 0);
  MACAdres255: TMACAdres = (255, 255, 255, 255, 255, 255);

  // TGirisKutusu nesnesinden Ctrl + C ile al�nan i�erik verisi
  PanoDegeri: string = '';

function NoktaAlanIcindeMi(ANokta: TKonum; AAlan: TAlan): Boolean;
function SaglamaToplamiOlustur(AVeriAdresi: Isaretci; AVeriUzunlugu: TSayi2;
  ASahteBaslikAdresi: Isaretci; ASahteBaslikUzunlugu: TSayi2): TSayi2;
function ProtokolTipAdi(AProtokolTipi: TProtokolTipi): string;
procedure EkleByte(AHedef: Isaretci; const ADeger: TSayi1);
procedure Ekle2Byte(AHedef: Isaretci; const ADeger: TSayi2);
procedure Ekle4Byte(AHedef: Isaretci; const ADeger: TSayi4);
function KritikBolgeyeGir(var ABellek: TSayi4): Boolean;
procedure KritikBolgedenCik(var ABellek: TSayi4);

implementation

function NoktaAlanIcindeMi(ANokta: TKonum; AAlan: TAlan): Boolean;
begin

  Result := False;

  if(ANokta.Sol >= AAlan.Sol) and (ANokta.Sol <= AAlan.Sag) and
    (ANokta.Ust >= AAlan.Ust) and (ANokta.Ust <= AAlan.Alt) then

  Result := True;
end;

{==============================================================================
  verilerin toplam sa�lama i�lemini ger�ekle�tirir
 ==============================================================================}
{
  kontrol toplam� �rne�i:
  08 00 00 00 00 01 00 a7 61 62 63 64 65 66 67 68
  69 6a 6b

  �nemli: kontrol toplam� yap�l�rken, de�erlerin i�erisinde sa�lama (checksum) de�eri
  var ise sa�lama de�eri i�lem �ncesi mutlaka s�f�rlanmal�d�r.

  0800
  0000
  0001
  0047
  6162
  6364
  6566
  6768        1. toplama i�leminden sonra, y�ksek 16 bitlik de�er ($2) al�ak 16
  696a        bitlik de�ere ($03B1) eklenir. $03B1 + $2 = $03B3
    6b
+-------      2. $03B3 de�eri mant�ksal NOT i�lemine tabi tutulur. $03B3 -> $FC4C
 203B1


  �nemli: i�levin geri d�n�� de�eri (s�k kullan�mdan dolay�) byte de�erler ters s�rada
    geri d�nd�r�l�r. �rne�in, de�er $CDAB ise bu de�er geriye ABCD olarak d�nd�r�l�r
}
function SaglamaToplamiOlustur(AVeriAdresi: Isaretci; AVeriUzunlugu: TSayi2;
  ASahteBaslikAdresi: Isaretci; ASahteBaslikUzunlugu: TSayi2): TSayi2;
var
  WordVeriAdresi: PSayi2;
  i, WordVeriUzunlugu: TSayi2;
  SaglamaToplami: TSayi4;
begin

  // e�er veri bellek adresi verilmemi� veya uzunluk 0 ise ��k
  if(AVeriAdresi = nil) or (AVeriUzunlugu = 0) then Exit(0);

  // sa�lama toplam� ilk de�er atamas�
  SaglamaToplami := 0;

  // 1. �nce veri de�erlerini topla
  //----------------------------------------------------------------------------

  // toplanacak word say�s�
  WordVeriUzunlugu := (AVeriUzunlugu shr 1);

  // word de�erleri topla
  WordVeriAdresi := AVeriAdresi;
  if(WordVeriUzunlugu > 1) then
  begin

    for i := 0 to WordVeriUzunlugu - 1 do
    begin

      SaglamaToplami := SaglamaToplami + WordVeriAdresi^;
      Inc(WordVeriAdresi);
    end;
  end;

  // e�er geriye tek de�er (byte) kald�ysa onu da toplama ekle
  if((AVeriUzunlugu mod 2) = 1) then
  begin

    SaglamaToplami := SaglamaToplami + PByte(WordVeriAdresi)^;
  end;

  // 2. daha sonra (var) ise sahte ba�l�k de�erlerini topla
  //----------------------------------------------------------------------------
  if(ASahteBaslikAdresi <> nil) and (ASahteBaslikUzunlugu > 0) then
  begin

    // toplanacak word say�s�
    WordVeriUzunlugu := (ASahteBaslikUzunlugu shr 1);

    // word de�erleri topla
    WordVeriAdresi := ASahteBaslikAdresi;
    if(WordVeriUzunlugu > 1) then
    begin

      for i := 0 to WordVeriUzunlugu - 1 do
      begin

        SaglamaToplami := SaglamaToplami + WordVeriAdresi^;
        Inc(WordVeriAdresi);
      end;
    end;

    // e�er geriye tek de�er (byte) kald�ysa onu da toplama ekle
    if((ASahteBaslikUzunlugu mod 2) = 1) then
    begin

      SaglamaToplami := SaglamaToplami + PByte(WordVeriAdresi)^;
    end;
  end;

  // word de�eri a�an (17 ve sonraki bitler) k�sm� ilk 16 bit de�ere ekle
  SaglamaToplami := (SaglamaToplami mod $10000) + (SaglamaToplami div $10000);

  // son olarak de�eri ters �evir
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

// indy yard�mc� i�lev - veriye word de�er ekleme (veriler big-endian bi�iminde)
procedure EkleByte(AHedef: Isaretci; const ADeger: TSayi1);
begin

  PSayi1(AHedef)^ := ADeger;
end;

// indy yard�mc� i�lev - veriye word de�er ekleme (veriler big-endian bi�iminde)
procedure Ekle2Byte(AHedef: Isaretci; const ADeger: TSayi2);
begin

  EkleByte(AHedef + 0, Byte(ADeger shr 8));
  EkleByte(AHedef + 1, Byte(ADeger and $FF));
end;

// indy yard�mc� i�lev - veriye dword de�er ekleme (veriler big-endian bi�iminde)
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

// ip adresinin a� adres aral��� i�erisinde olup olmad���n� kontrol eder
// �rnek:
// istenen ip adresi: 192.168.1.110
// dhcp ip adresi   : 192.168.1.1
// ilk 3 byte de�erinin ayn� olmas� ip adresinin ayn� a�da oldu�unu g�sterir
function TIPAdresIslev.IPAgAraligiIcinde(AAgIPAdresi: TIPAdres): Boolean;
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

end.
