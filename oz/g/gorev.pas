{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: gorev.pas
  Dosya ��levi: g�rev (program) y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 07/07/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gorev;

interface

uses paylasim, gn_masaustu, gn_pencere;

const
  // �al��ma seviye numaralar� (0..3)
  CALISMA_SEVIYE0 = 0;
  CALISMA_SEVIYE1 = 1;
  CALISMA_SEVIYE2 = 2;
  CALISMA_SEVIYE3 = 3;

const
  // bir g�rev i�in tan�mlanan �st s�n�r olay say�s�
  // olay belle�i 4K olarak tan�mlanm��t�r. 4096 / SizeOf(TOlay)
  USTSINIR_OLAY         = 64;
  PROGRAM_YIGIN_BELLEK  = (4096 * 5) - 1;             // program y���n� (stack) i�in ayr�lacak bellek
  DEFTER_BELLEK_U       = TSayi4((4096 * 10) - 1);    // defter program� i�in program belle�inde ayr�lacak alan

var
  { TODO - object yap�s�n�n i�erisine dahil edilecek }
  CalisanGorevSayisi,                     // olu�turulan / �al��an program say�s�
  FAktifGorev: TISayi4;                   // o an �al��an program
  FAktifGorevBellekAdresi: TSayi4;        // o an �al��an program�n y�klendi�i bellek adresi
  GorevDegisimSayisi: TSayi4 = 0;         // �ekirdek ba�lad��� andan itibaren ger�ekle�tirilen g�rev de�i�im say�s�
  GorevBayrakDegeri: TSayi4 = 0;          // her g�rev �al��t�rma / sonland�rma / aktifle�tirme durumunda 1 art�r�l�r
  GorevKilit: TSayi4 = 0;

type
  TDosyaTip = (dtDiger, dtCalistirilabilir, dtSurucu, dtResim, dtBelge);

type
  TDosyaIliskisi = record
    Uzanti: string[5];            // ili�ki kurulacak dosya uzant�s�
    Uygulama: string[30];         // uzant�n�n ili�kili oldu�u program ad�
    DosyaTip: TDosyaTip;          // uzant�n�n ili�kili oldu�u dosya tipi
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
    FGorevSayaci: TSayi4;                 // g�rev de�i�im sayac�
    FBellekBaslangicAdresi: TSayi4;       // i�lemin y�klendi�i bellek adresi
    FSeviyeNo: TSayi4;                    // g�revin �al��ma seviye numaras� (0..3)
  end;

  { TODO - nesne class yap�s�na �evrilecek }
  TGorev = object
  private
    FBellekUzunlugu: TSayi4;              // i�lemin kulland��� bellek uzunlu�u
    FKodBaslangicAdres: TSayi4;           // i�lemin bellek ba�lang�� adresi
    FYiginBaslangicAdres: TSayi4;         // i�lemin y���n adresi
    FAktifMasaustu: PMasaustu;            // g�revin aktif masa�st�
    FAktifPencere: PPencere;              // g�revin aktif penceresi
  public
    G0: TGorev0;

    FCalismaSuresiMS,                     // g�revin �al��aca�� s�re (irq0 tick say�s�)
    FCalismaSuresiSayacMS: TSayi4;        // g�revin �al��aca�� s�renin saya� de�eri

    FOlayBellekAdresi: POlay;             // olaylar�n yerle�tirilece�i bellek b�lgesi
    FOlaySayisi: TSayi4;                  // olay sayac�

    FGorevKimlik: TKimlik;                // g�rev kimlik numaras�
    FGorevDurum: TGorevDurum;             // i�lem durumu
    FDosyaSonIslemDurum: TISayi4;         // g�revin son dosya i�lem sonu� de�eri

    // hata ile ilgili de�i�kenler
    FHataKodu,
    FHataCS, FHataEIP,                    // cs:eip
    FHataESP,                             // esp
    FHataBayrak: TISayi4;                 // flags

    FDosyaAdi,                            // g�revin y�klendi�i dosya ad�
    FProgramAdi: string;                  // program ad�
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
    ('S�f�ra B�lme Hatas�'),
    ('Hata Ay�klama'),
    ('Engellenemeyen Kesme'),
    ('Durma Noktas�'),
    ('Ta�ma Hatas�'),
    ('Dizi Aral��� A�ma Hatas�'),
    ('Hatal� ��lemci Kodu'),
    ('Matematik ��lemci Mevcut De�il'),
    ('�ifte Hata'),
    ('Matematik ��lemci Yazma� Hatas�'),
    ('Hatal� TSS Giri�i'),
    ('Yazma� Mevcut De�il'),
    ('Y���n Hatas�'),
    ('Genel Koruma Hatas�'),
    ('Sayfa Hatas�'),
    ('Hata No: 15 - Tan�mlanmam��'));

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
  �al��t�r�lacak g�revlerin ana y�kleme i�levlerini i�erir
 ==============================================================================}
procedure TGorevler.Yukle;
var
  G: PGorev;
  i: TISayi4;
begin

  // g�rev bilgilerinin yerle�tirilmesi i�in bellek ay�r
  G := GetMem(SizeOf(TGorev) * USTSINIR_GOREVSAYISI);

  // bellek giri�lerini g�rev yap�lar�yla e�le�tir
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    GorevListesi[i] := G;

    // g�revi bo� olarak belirle
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
  g�rev (program) dosyalar�n� �al��t�r�r
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

  // dosyay�, s�r�c� + Klasor + dosya ad� par�alar�na ay�r
  DosyaYolunuParcala2(ATamDosyaYolu, Surucu, Klasor, DosyaAdi);

  // dosya ad�n�n uzunlu�unu al
  DosyaU := Length(DosyaAdi);

  { TODO : .c dosyalar� ileride .� (�al��t�r�labilir) olarak de�i�tirilecek. }

  // dosya uzant�s�n� al
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

  // dosya �al��t�r�labilir bir dosya de�il ise dosyan�n birlikte a��laca��
  // �nde�er olarak tan�mlanan program� bul
  if((IliskiliProgram.DosyaTip = dtResim) or (IliskiliProgram.DosyaTip = dtBelge)
    or (IliskiliProgram.DosyaTip = dtDiger)) then
  begin

    // e�er dosya �al��t�r�labilir de�il ise dosyay�, �nde�er olarak tan�mlanan
    // program ile �al��t�r
    Degiskenler := Surucu + ':' + Klasor + DosyaAdi;      // �al��t�r�lacak dosya
    DosyaAdi := IliskiliProgram.Uygulama;                 // �al��t�r�lacak dosyay� �al��t�racak program
    TamDosyaYolu := AcilisSurucuAygiti + ':\' + KLASOR_PROGRAM + '\' + DosyaAdi;
  end;

  // �al��t�r�lacak dosyay� tan�mla ve a�
  AssignFile(DosyaKimlik, TamDosyaYolu);
  Reset(DosyaKimlik);
  if(IOResult = HATA_DOSYA_ISLEM_BASARILI) then
  begin

    // dosya uzunlu�unu al
    DosyaU := FileSize(DosyaKimlik);

    // dosyan�n �al��t�r�lmas� i�in bellekte yer rezerv et
    // defter.c program�na verileri i�lemesi i�in fazladan 40K yer tahsis et
    if(DosyaAdi = 'defter.c') then
      ProgramBellekU := DosyaU + PROGRAM_YIGIN_BELLEK + DEFTER_BELLEK_U
    else ProgramBellekU := DosyaU + PROGRAM_YIGIN_BELLEK;

    //ProgramBellekU := ((ProgramBellekU shr 12) + 1) shl 12;

    GetMem(DosyaBellek, ProgramBellekU);
    if(DosyaBellek = nil) then
    begin

      SISTEM_MESAJ(mtHata, RENK_SIYAH, 'GOREV.PAS: ' + ATamDosyaYolu + ' i�in yeterli bellek yok!', []);
      Result := nil;
      KritikBolgedenCik(GorevKilit);
      asm sti end;
      Exit;
    end;

    // dosyay� hedef adrese kopyala
    if(Read(DosyaKimlik, DosyaBellek) = 0) then
    begin

      // dosyay� kapat
      CloseFile(DosyaKimlik);
      SISTEM_MESAJ(mtHata, RENK_SIYAH, 'GOREV.PAS: ' + TamDosyaYolu + ' dosyas� okunam�yor!', []);
      Result := nil;
      KritikBolgedenCik(GorevKilit);
      asm sti end;
      Exit;
    end;

    // dosyay� kapat
    CloseFile(DosyaKimlik);

    // bo� i�lem giri�i bul
    Gorev := GGorevler.Olustur;
    if(Gorev = nil) then
    begin

      SISTEM_MESAJ(mtHata, RENK_SIYAH, 'GOREV.PAS: ' + ATamDosyaYolu + ' i�in g�rev olu�turulam�yor!', []);
      Result := nil;
      KritikBolgedenCik(GorevKilit);
      asm sti end;
      Exit;
    end;

    // ELF bi�imindeki dosyan�n ba� taraf�na konumlan
    ELFBaslik := DosyaBellek;

    // ayg�t s�r�c�s� �al��malar� - test - 31012019
    // testsrc.s �al��t�r�labilir ayg�t s�r�c�s� dosyas� �al��malar devam etmektedir
    if(IliskiliProgram.DosyaTip = dtSurucu) then
    begin

      AygitSurucusu := PAygitSurucusu(DosyaBellek + PSayi4(DosyaBellek + $100 + 8)^);
      SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'Ayg�t s�r�c�s� / a��klama', []);
      SISTEM_MESAJ(mtBilgi, RENK_SIYAH, AygitSurucusu^.AygitAdi, []);
      SISTEM_MESAJ(mtBilgi, RENK_SIYAH, AygitSurucusu^.Aciklama, []);
      SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'De�er-1: $%.8x', [AygitSurucusu^.Deger1]);
      SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'De�er-2: $%.8x', [AygitSurucusu^.Deger2]);
      SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'De�er-3: $%.8x', [AygitSurucusu^.Deger3]);
      KritikBolgedenCik(GorevKilit);
      asm sti end;
      Exit;
    end;

    // olay i�lemleri i�in bellekte yer ay�r
    //Olay := GetMem(4096);
    Olay := GetMem(4096);
    if(Olay = nil) then
    begin

      SISTEM_MESAJ(mtHata, RENK_SIYAH, 'GOREV.PAS: olay bilgisi i�in bellek ayr�lam�yor!', []);
      Result := nil;
      KritikBolgedenCik(GorevKilit);
      asm sti end;
      Exit;
    end;

    // g�rev �al��ma seviye numaras� - �ncelik derecesi
    Gorev^.G0.FSeviyeNo := ASeviyeNo;

    // g�rev de�i�im sayac�n� s�f�rla
    Gorev^.G0.FGorevSayaci := 0;

    // bellek ba�lang�� adresi
    Gorev^.G0.FBellekBaslangicAdresi := TSayi4(DosyaBellek);

    // g�rev �al��ma s�releri
    Gorev^.FCalismaSuresiMS := 2;
    Gorev^.FCalismaSuresiSayacMS := 2;

    // bellek miktar�
    Gorev^.FBellekUzunlugu := ProgramBellekU;

    // i�lem ba�lang�� adresi
    Gorev^.FKodBaslangicAdres := ELFBaslik^.KodBaslangicAdresi;

    // i�lemin y���n adresi
    if(DosyaAdi = 'defter.c') then
      Gorev^.FYiginBaslangicAdres := (ProgramBellekU - DEFTER_BELLEK_U) - 512
    else Gorev^.FYiginBaslangicAdres := ProgramBellekU - 512;

    // dosyan�n �al��t�r�lmas� i�in se�icileri olu�tur
    GGorevler.SecicileriOlustur(Gorev^.FGorevKimlik, Gorev^.FBellekUzunlugu,
      Gorev^.G0.FBellekBaslangicAdresi, Gorev^.FKodBaslangicAdres, Gorev^.FYiginBaslangicAdres);

    // g�rev olay sayac�n� s�f�rla
    Gorev^.FOlaySayisi := 0;

    // i�lemin olay bellek b�lgesini ata
    Gorev^.FOlayBellekAdresi := Olay;

    // i�lemin ad�
    Gorev^.FDosyaAdi := DosyaAdi;

    // program �nde�er ad�
    Gorev^.FProgramAdi := '';

    // de�i�ken g�nderimi
    // ilk de�i�ken - �al��an i�lemin ad�

    // program bellek ba�lang�c�n�n ilk 32 byte'� �ekirde�in programa
    // bilgi vermesi amac�yla ayr�lm��t�r.
    PSayi4(DosyaBellek + 00)^ := TSayi4(DosyaBellek);
    if(DosyaAdi = 'defter.c') then
      PSayi4(DosyaBellek + 04)^ := ProgramBellekU - DEFTER_BELLEK_U
    else PSayi4(DosyaBellek + 04)^ := ProgramBellekU;

    PSayi4(DosyaBellek + 32)^ := 0;
    p1 := PChar(DosyaBellek + 32 + 4);
    Tasi2(@TamDosyaYolu[1], p1, Length(TamDosyaYolu));
    p1 += Length(TamDosyaYolu);
    p1^ := #0;

    // e�er varsa ikinci de�i�ken - �al��an program�n kullanaca�� de�er
    if(Degiskenler <> '') then
    begin

      PSayi4(DosyaBellek + 32)^ := 1;
      Inc(p1);
      Tasi2(@Degiskenler[1], p1, Length(Degiskenler));
      p1 += Length(Degiskenler);
      p1^ := #0;
    end;

    // g�revin durumunu �al���yor olarak belirle
    Gorev^.FGorevDurum := gdCalisiyor;

    // g�rev i�lem say�s�n� bir art�r
    Inc(CalisanGorevSayisi);

    // g�rev bayrak de�erini art�r
    Inc(GorevBayrakDegeri);

    // program�n iz kay�t dosyas�n� olu�tur
    {IzKayitDosyaAdi := DosyaAdiniAl(DosyaAdi);
    IzKayitDosyaAdi += '.log'; //izkayit';
    IzKaydiOlustur(IzKayitDosyaAdi, IzKayitDosyaAdi + ' uygulamas� �al��t�r�ld�');}

    // g�rev bellek adresini geri d�nd�r
    Result := Gorev;

    KritikBolgedenCik(GorevKilit);
  end
  else
  begin

    CloseFile(DosyaKimlik);
    SISTEM_MESAJ(mtHata, RENK_SIYAH, 'GOREV.PAS: ' + TamDosyaYolu + ' dosya okuma hatas�!', []);
  end;

  KritikBolgedenCik(GorevKilit);
end;

{==============================================================================
  �al��acak g�rev i�in bo� g�rev bul
 ==============================================================================}
function TGorevler.Olustur: PGorev;
var
  Gorev: PGorev;
begin

  // bo� i�lem giri�i bul
  Gorev := GGorevler.BosGorevBul;

  Result := Gorev;
end;

{==============================================================================
  �al��acak g�rev i�in bo� g�rev bul
 ==============================================================================}
function TGorevler.BosGorevBul: PGorev;
var
  Gorev: PGorev;
  i: TSayi4;
begin

  // t�m i�lem giri�lerini incele
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    Gorev := GorevListesi[i];

    // e�er g�rev giri�i bo� ise
    if(Gorev^.FGorevDurum = gdBos) then
    begin

      // g�rev giri�ini ayr�lm�� olarak i�aretle ve �a��ran i�leve geri d�n
      GGorevler.DurumDegistir(i, gdOlusturuldu);
      Exit(Gorev);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  g�rev i�in TSS se�icilerini (selekt�r) olu�turur
 ==============================================================================}
procedure TGorevler.SecicileriOlustur(AKimlik, AUzunluk, ABellekBas,
  AKodBas, AYiginBas: TSayi4);
var
  SeciciCSSiraNo, SeciciDSSiraNo,
  SeciciTSSSiraNo: TKimlik;
  Uzunluk, i: TSayi4;
begin

  // uygulaman�n ilk g�rev kimli�i 3 (olan muyntcs.c)'t�r
  i := AKimlik;

  Uzunluk := AUzunluk shr 12;

  // uygulaman�n TSS, CS, DS se�icilerini belirle, her bir program 3 se�ici i�erir
  SeciciCSSiraNo := (i * 3) + 1;
  SeciciDSSiraNo := SeciciCSSiraNo + 1;
  SeciciTSSSiraNo := SeciciDSSiraNo + 1;

  // uygulama i�in CS selekt�r�n� olu�tur
  // kod se�icisi (CS)
  // Eri�im  : 1 = mevcut, 11 = DPL3, 11 = kod segment, 0 = dallan�lamaz, 1 = okunabilir, 0 = eri�ilmedi
  // Esneklik: 1 = gran = 4K ��z�n�rl�k, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SeciciCSSiraNo, ABellekBas, Uzunluk, %11111010, %11010000);
  // uygulama i�in DS selekt�r�n� olu�tur
  // veri se�icisi (DS)
  // Eri�im  : 1 = mevcut, 11 = DPL3, 10 = veri yazma�, 0 = artarak b�y�yen, 1 = yaz�labilir, 0 = eri�ilmedi
  // Esneklik: 1 = gran = 4K ��z�n�rl�k, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SeciciDSSiraNo, ABellekBas, Uzunluk, %11110010, %11010000);
  // uygulama i�in TSS selekt�r�n� olu�tur
  // g�rev se�icisi (TSS)
  // Eri�im  : 1 = mevcut, 11 = DPL0, 010 = 32 bit kullan�labilir TSS, 0 = me�gul biti (me�gul de�il), 1
  // Esneklik: 1 = gran = 1Byte ��z�n�rl�k, 00, 1 = bana tahsis edildi, 0000 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SeciciTSSSiraNo, TSayi4(GorevTSSListesi[i]), TSS_UZUNLUK - 1,
    %11101001, %00010000);

  // TSS'nin i�eri�ini s�f�rla
  FillByte(GorevTSSListesi[i]^, 104, $00);

  // giri� / ��k�� haritas�n� doldur
  if(TSS_UZUNLUK > 104) then
  begin

    // her bit 1 porta kar��l�k gelir. de�erin 1 olmas� DPL3 g�revi i�in port kullan�m�n� yasaklar
    FillByte(Isaretci(@GorevTSSListesi[i]^.IOHarita)^, TSS_UZUNLUK - 104, $FF);
    GorevTSSListesi[i]^.IOHaritaGAdres := TSS_UZUNLUK;
  end;

  // TSS i�eri�ini doldur
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
  i�lemin yeni �al��ma durumunu belirler
 ==============================================================================}
procedure TGorevler.DurumDegistir(AGorevKimlik: TKimlik; AGorevDurum: TGorevDurum);
var
  Gorev: PGorev;
begin

  Gorev := GorevListesi[AGorevKimlik];
  if(AGorevDurum <> Gorev^.FGorevDurum) then Gorev^.FGorevDurum := AGorevDurum;
end;

{==============================================================================
  g�rev sayac�n� belirler
 ==============================================================================}
procedure TGorevler.GorevSayaciYaz(AGorevKimlik: TKimlik; ASayacDegeri: TSayi4);
var
  G: PGorev;
begin

  G := GorevListesi[AGorevKimlik];

  if(ASayacDegeri <> G^.G0.FGorevSayaci) then G^.G0.FGorevSayaci := ASayacDegeri;
end;

{==============================================================================
  g�revin olay say�s�n� belirler
 ==============================================================================}
procedure TGorevler.OlaySayisiYaz(AGorevKimlik: TKimlik; AOlaySayisi: TSayi4);
var
  G: PGorev;
begin

  G := GorevListesi[AGorevKimlik];

  if(AOlaySayisi <> G^.FOlaySayisi) then G^.FOlaySayisi := AOlaySayisi;
end;

{==============================================================================
  �ekirdek taraf�ndan g�rev i�in olu�turulan olay� kaydeder
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

    // olay belle�i dolu de�ilse olay� kaydet
    if(Gorev^.FOlaySayisi < USTSINIR_OLAY) then
    begin

      // i�lemin olay belle�ine konumlan
      Olay := Gorev^.OlayBellekAdresi;
      Inc(Olay, Gorev^.FOlaySayisi);

      // olay� i�lem belle�ine kaydet
      Olay^.Kimlik := AOlay.Kimlik;
      Olay^.Olay := AOlay.Olay;
      Olay^.Deger1 := AOlay.Deger1;
      Olay^.Deger2 := AOlay.Deger2;

      // g�revin olay sayac�n� art�r
      Gorev^.FOlaySayisi := Gorev^.FOlaySayisi + 1;
    end;
  end;

  KritikBolgedenCik(OlayKilit);
end;

{==============================================================================
  g�rev i�in (�ekirdek taraf�ndan) olu�turulan olay� al�r
 ==============================================================================}
function TGorevler.OlayAl(AKimlik: TSayi4; var AOlay: TOlay): Boolean;
var
  Olay1, Olay2: POlay;
  i: TSayi4;
  G: PGorev;
begin

  while KritikBolgeyeGir(OlayKilit) = False do;

  G := GorevListesi[AKimlik];

  // �nde�er ��k�� de�eri
  Result := False;

  i := G^.FOlaySayisi;

  // g�rev i�in olu�turulan olay yoksa ��k
  if(i = 0) then
  begin

    KritikBolgedenCik(OlayKilit);
    Exit;
  end;

  // �nde�er ��k�� de�eri
  Result := True;

  // g�revin olay belle�ine konumlan
  Olay1 := G^.OlayBellekAdresi;

  // olaylar� hedef alana kopyala
  AOlay.Olay := Olay1^.Olay;
  AOlay.Kimlik := Olay1^.Kimlik;
  AOlay.Deger1 := Olay1^.Deger1;
  AOlay.Deger2 := Olay1^.Deger2;

  Dec(i);

  // tek bir olay var ise olay belle�ini g�ncellemeye gerek yok
  if(i = 0) then
  begin

    // olay sayac�n� azalt
    G^.FOlaySayisi := i;

    KritikBolgedenCik(OlayKilit);
    Exit;
  end;

  // olay� g�revin olay belle�inden sil
  Olay2 := Olay1;
  Inc(Olay2);

  Tasi2(Olay2, Olay1, SizeOf(TOlay) * i);

  // olay sayac�n� azalt
  G^.FOlaySayisi := i;

  KritikBolgedenCik(OlayKilit);
end;

{==============================================================================
  �al��an g�revi sonland�r�r
 ==============================================================================}
function TGorevler.Sonlandir(AGorevKimlik: TKimlik; const ASonlanmaSebebi: TISayi4 = -1): TISayi4;
var
  Gorev: PGorev = nil;
begin

  while KritikBolgeyeGir(GorevKilit) = False do;

  Gorev := GorevListesi[AGorevKimlik];

  // g�revin sonland�r�lma bilgisini ver
  if(ASonlanmaSebebi = -1) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'GOREV.PAS: ' + Gorev^.FDosyaAdi + ' normal bir �ekilde sonland�r�ld�.', []);
  end
  else
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'GOREV.PAS: ' + Gorev^.FDosyaAdi +
      ' program� istenmeyen bir i�lem yapt���ndan dolay� sonland�r�ld�', []);
    SISTEM_MESAJ(mtHata, RENK_MAVI, '  -> Hata Kodu: ' + IntToStr(ASonlanmaSebebi) + ' - ' +
      IstisnaAciklamaListesi[ASonlanmaSebebi], []);
    SISTEM_MESAJ(mtHata, RENK_SIYAH, '  -> CS: $%.8x', [Gorev^.FHataCS]);
    SISTEM_MESAJ(mtHata, RENK_SIYAH, '  -> EIP: $%.8x', [Gorev^.FHataEIP]);
    SISTEM_MESAJ(mtHata, RENK_SIYAH, '  -> ESP: $%.8x', [Gorev^.FHataESP]);
    SISTEM_MESAJ(mtHata, RENK_SIYAH, '  -> EFLAGS: $%.8x', [Gorev^.FHataBayrak]);
  end;

  { TODO : a�a��daki i�levlerin �al��mas�n�n do�rulu�u test edilecek }

  // g�reve ait zamanlay�c�lar� yok et
  ZamanlayicilariYokEt(AGorevKimlik);

  { TODO : G�rsel olmayan nesnelerin bellekten at�lmas�nda (TGorev.Sonlandir)
    g�rsel i�levlerin �al��mamas� sa�lanacak }

  // g�reve ait g�rsel nesneleri yok et
  GorevGorselNesneleriniYokEt(AGorevKimlik);

  // g�reve ait olay bellek b�lgesini iptal et
  { TODO : 1. bu i�lev olay y�netim sistem nesnesinin i�erisine dahil edilecek
           2. olay bellek b�lgesi iptal edilmeden �nce �nceden olu�turulan olaylar da kay�tlardan ��kar�lacak }
  //FreeMem(Gorev^.OlayBellekAdresi, 4096);
  FreeMem(Gorev^.OlayBellekAdresi, 4096);

  // g�rev i�in ayr�lan bellek b�lgesini serbest b�rak
  FreeMem(Isaretci(Gorev^.G0.FBellekBaslangicAdresi), Gorev^.BellekUzunlugu);

  // g�revi i�lem listesinden ��kart
  GGorevler.DurumDegistir(AGorevKimlik, gdBos);

  // g�rev say�s�n� bir azalt
  Dec(CalisanGorevSayisi);

  // g�rev bayrak de�erini art�r
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
  g�rev ile ilgili bellek b�lgesini geri d�nd�r�r
 ==============================================================================}
function GorevBilgisiAl(AGorevSiraNo: TISayi4): PGorev;
var
  i, j: TISayi4;
begin

  // aranacak g�rev s�ra numaras�
  j := -1;

  // t�m i�lem bellek b�lgelerini ara�t�r
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    // g�rev bo� de�il ise g�rev s�ra numaras�n� bir art�r
    if not(GorevListesi[i]^.FGorevDurum = gdBos) then Inc(j);

    // g�rev s�ra no aranan g�rev ise i�lem bellek b�lgesini geri d�nd�r
    if(AGorevSiraNo = j) then Exit(GorevListesi[i]);
  end;

  Result := nil;
end;

{==============================================================================
  pencereye sahip g�rev say�s�n� al�r
 ==============================================================================}
function CalisanProgramSayisiniAl(AMasaustuKimlik: TKimlik = -1): TSayi4;
var
  i: TISayi4;
begin

  Result := 0;

  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    // 1. g�rev bo� de�ilse
    // 2. pencereye sahip ise
    // 3. pencere tipi ba�l�ks�z de�ilse
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
  g�rev bayrak de�erini al
  bilgi: bu de�er, her program �al��t�rma ve sonland�rmada de�i�en bayrak de�eridir
    t de�erinden t + 1 de�erine kadar "�al��an program say�s�nda" de�i�iklik olmasa bile
    ba�lama ve sonland�rma bazl� de�i�imleri yakalamak ama�l�d�r
 ==============================================================================}
function GorevBayrakDegeriniAl: TSayi4;
begin

  Result := GorevBayrakDegeri;
end;

{==============================================================================
  pencereye sahip g�rev ile ilgili bilgi al�r
 ==============================================================================}
function CalisanProgramBilgisiAl(AGorevSiraNo: TISayi4; AMasaustuKimlik: TKimlik = -1): TProgramKayit;
var
  i, ArananGorev: TISayi4;
begin

  ArananGorev := -1;

  Result.PencereKimlik := HATA_KIMLIK;

  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    // 1. g�rev bo� de�ilse
    // 2. pencereye sahip ise
    // 3. pencere tipi ba�l�ks�z de�ilse
    if not(GorevListesi[i]^.FGorevDurum = gdBos) and
      not(GorevListesi[i]^.FAktifPencere = nil) and
      not(GorevListesi[i]^.FAktifPencere^.FPencereTipi = ptBasliksiz) then
    begin

      if(AMasaustuKimlik = -1) then
        Inc(ArananGorev)
      else if(GorevListesi[i]^.AktifMasaustu^.FTGN.Kimlik = AMasaustuKimlik) then
        Inc(ArananGorev);
    end;

    // g�rev s�ra no aranan g�rev ise i�lem bellek b�lgesini geri d�nd�r
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
  g�rev kimlik numaras�na g�re g�rev aramas� yapar
 ==============================================================================}
function TGorevler.GorevBul(AGorevKimlik: TKimlik): PGorev;
var
  Gorev: PGorev;
  i: TSayi4;
begin

  // t�m g�rev giri�lerini incele
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    Gorev := GorevListesi[i];

    // e�er g�rev giri�i bo� ise
    if(Gorev^.FGorevDurum = gdCalisiyor) and (Gorev^.GorevKimlik = AGorevKimlik) then
      Exit(Gorev);
  end;

  Result := nil;
end;

{==============================================================================
  g�rev ad�ndan g�rev kimlik numaras�n� al�r
 ==============================================================================}
function TGorevler.GorevKimligiAl(AGorevAdi: string): TKimlik;
var
  i: TISayi4;
begin

  // t�m i�lem bellek b�lgelerini ara�t�r
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    // g�rev bo� de�il ise g�rev s�ra numaras�n� bir art�r
    if not(GorevListesi[i]^.FGorevDurum = gdBos) and
      (GorevListesi[i]^.FDosyaAdi = AGorevAdi) then Exit(GorevListesi[i]^.GorevKimlik);
  end;

  Result := -1;
end;

{==============================================================================
  g�rev bellek s�ra numaras�n� geri d�nd�r�r
 ==============================================================================}
function GorevSiraNumarasiniAl(AGorevSiraNo: TISayi4): TKimlik;
var
  i, j: TISayi4;
begin

  // aranacak g�rev s�ra numaras�
  j := -1;

  // t�m i�lem bellek b�lgelerini ara�t�r
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    // g�rev �al���yor ise g�rev s�ra numaras�n� bir art�r
    if(GorevListesi[i]^.FGorevDurum = gdCalisiyor) then Inc(j);

    // g�rev s�ra no aranan g�rev ise i�lem bellek b�lgesini geri d�nd�r
    if(AGorevSiraNo = j) then Exit(i);
  end;

  Result := -1;
end;

{==============================================================================
  �al��t�r�lacak bir sonraki g�revi bulur
 ==============================================================================}
function CalistirilacakBirSonrakiGoreviBul: TKimlik;
var
  GorevKimlik: TKimlik;
  i: TISayi4;
begin

  // �al��an g�reve konumlan
  GorevKimlik := FAktifGorev;

  // bir sonraki g�revden itibaren t�m g�revleri incele
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    Inc(GorevKimlik);
    if(GorevKimlik > USTSINIR_GOREVSAYISI) then GorevKimlik := 0;

    // �al��an g�rev aranan g�rev ise �a��ran i�leve geri d�n
    if(GorevListesi[GorevKimlik]^.FGorevDurum = gdCalisiyor) then Break;
  end;

  Result := GorevKimlik;
end;

{==============================================================================
  dosya uzant�s� ile ili�kili program ad�n� geri d�nd�r�r
 ==============================================================================}
function IliskiliProgramAl(ADosyaUzanti: string): TDosyaIliskisi;
var
  i: TSayi4;
begin

  // dosyalarla ili�kilendirilen �nde�er program
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
  sonland�rma ama�l� i�aretlenen g�revlerin sonland�r�r
  bilgi: uygulama �ncelikle sonlad�rmak i�in i�aretlenir daha sonland�r�l�r
 ==============================================================================}
procedure IsaretlenenGorevleriSonlandir;
var
  Gorev: PGorev;
  i: TISayi4;
begin

  // bellek giri�lerini g�rev yap�lar�yla e�le�tir
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    Gorev := GorevListesi[i];

    if(Gorev^.FGorevDurum = gdSonlandiriliyor) then
      GGorevler.Sonlandir(Gorev^.FGorevKimlik, Gorev^.FHataKodu);
  end;
end;

{==============================================================================
  g�rev i�in belli bir g�revi yerine getiren i�lev olu�turur - (thread)
  bilgi: sa�ma sapan kelime olan thread kelimesini kullanmay� uygun bulmuyorum
 ==============================================================================}
function Memur(AGorevAdi: string; AIslev: TIslev; AYiginDegeri: TSayi4; ASeviyeNo: TSayi4): TSayi4;
var
  Gorev: PGorev;
  // yazma�lar�n girdi i�erisindeki s�ra numaralar�
  SNYazmacCS, SNYazmacDS, SNYazmacTSS,
  i: TSayi4;
begin

  Gorev := GGorevler.BosGorevBul;
  if not(Gorev = nil) then
  begin

    i := Gorev^.FGorevKimlik;

    // uygulaman�n TSS, CS, DS se�icilerini belirle, her bir program 3 se�ici i�erir
    SNYazmacCS := (i * 3) + 1;
    SNYazmacDS := SNYazmacCS + 1;
    SNYazmacTSS := SNYazmacDS + 1;

    // kod se�icisi (CS)
    // Eri�im  : 1 = mevcut, 00 = DPL0, 11 = kod yazma�, 0 = dallan�lamaz, 1 = okunabilir, 0 = eri�ilmedi
    // Esneklik: 1 = gran = 4K ��z�n�rl�k, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
    GDTRGirdisiEkle(SNYazmacCS, 0, $FFFFFFFF, %10011010, %11011111);
    // veri se�icisi (DS)
    // Eri�im  : 1 = mevcut, 00 = DPL0, 10 = veri yazma�, 0 = artarak b�y�yen, 1 = yaz�labilir, 0 = eri�ilmedi
    // Esneklik: 1 = gran = 4K ��z�n�rl�k, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
    GDTRGirdisiEkle(SNYazmacDS, 0, $FFFFFFFF, %10010010, %11011111);
    // g�rev se�icisi (TSS)
    // Eri�im  : 1 = mevcut, 00 = DPL0, 010 = 32 bit kullan�labilir TSS, 0 = me�gul biti (me�gul de�il), 1
    // Esneklik: 1 = gran = 1Byte ��z�n�rl�k, 00, 1 = bana tahsis edildi, 0000 = uzunluk 16..19 bit
    GDTRGirdisiEkle(SNYazmacTSS, TSayi4(GorevTSSListesi[i]), 104,
      %10001001, %00010000);

    // denet�inin kullanaca�� TSS'nin i�eri�ini s�f�rla
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

    // sistem g�rev de�erlerini belirle
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

    // sistem g�rev ad� (dosya ad�)
    GorevListesi[i]^.FDosyaAdi := 'cekirdek.bin';
    GorevListesi[i]^.FProgramAdi := AGorevAdi;

    // sistem g�revini �al���yor olarak i�aretle
    Gorev := GorevListesi[i];
    GGorevler.DurumDegistir(i, gdCalisiyor);

    // �al��an ve olu�turulan g�rev de�erlerini belirle
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
