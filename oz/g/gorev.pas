{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: gorev.pas
  Dosya ��levi: g�rev (program) y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 23/07/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gorev;

interface

uses paylasim, gn_masaustu;

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
  FCalisanGorevSayisi: TSayi4;            // olu�turulan / �al��an program say�s�
  FAktifGorev: TISayi4;                   // o an �al��an program
  FAktifGorevBellekAdresi: TSayi4;        // o an �al��an program�n y�klendi�i bellek adresi
  GorevDegisimSayisi: TSayi4 = 0;         // �ekirdek ba�lad��� andan itibaren ger�ekle�tirilen g�rev de�i�im say�s�
  GorevBayrakDegeri: TSayi4 = 0;          // her g�rev �al��t�rma / sonland�rma / aktifle�tirme durumunda 1 art�r�l�r

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
  TGorev = record
    Kimlik: TKimlik;                      // g�rev kimlik numaras�
    SeviyeNo: TSayi4;                     // g�revin �al��ma seviye numaras� (0..3)
    Durum: TGorevDurum;                   // g�rev �al��ma durumu

    BellekBaslangicAdresi: TSayi4;        // g�revin y�klendi�i bellek ba�lang�� adresi
    BellekUzunlugu: TSayi4;               // g�revin kulland��� bellek uzunlu�u
    KodBaslangicAdresi: TSayi4;           // g�rev kodlar�n�n ilk �al��maya ba�layaca�� bellek adresi
    YiginBaslangicAdresi: TSayi4;         // i�lemin y���n ba�lang�� adresi

    AktifMasaustu: PMasaustu;             // g�revin �al��t��� aktif masa�st�
    AktifPencere: PObject;                // g�revin sahip oldu�u pencere

    GorevSayaci: TSayi4;                  // zamanlay�c� her tetiklendi�inde artan g�rev de�i�im sayac�

    CalismaSuresiMS,                      // g�revin �al��aca�� s�re (irq0 tick say�s�)
    CalismaSuresiSayacMS: TSayi4;         // g�revin �al��aca�� s�renin saya� de�eri

    OlayBellekAdresi: POlay;              // g�reve ait olaylar�n yerle�tirilece�i bellek b�lgesi
    OlaySayisi: TSayi4;                   // g�rev olay say�s�

    DosyaSonIslemDurum: TISayi4;          // g�reve ait son dosya i�lem sonu� de�eri

    // hata ile ilgili de�erlerin yerle�tirilece�i de�i�kenler
    HataKodu,                             // hata kodu
    HataCS, HataEIP,                      // cs:eip
    HataESP,                              // esp
    HataBayrak: TISayi4;                  // flags

    DosyaAdi,                             // g�rev dosya ad�
    ProgramAdi: string;                   // program ad�
  end;

type
  TGorevler = object
  private
    FGorevListesi: array[0..USTSINIR_GOREVSAYISI - 1] of PGorev;
    function GorevAl(ASiraNo: TSayi4): PGorev;
    procedure GorevYaz(ASiraNo: TSayi4; AGorev: PGorev);
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
    property Gorev[ASiraNo: TSayi4]: PGorev read GorevAl write GorevYaz;
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

uses gdt, dosya, sistemmesaj, donusum, zamanlayici, gn_islevler, gn_pencere, islevler;

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

{==============================================================================
  �al��t�r�lacak g�revlerin ana y�kleme i�levlerini i�erir
 ==============================================================================}
procedure TGorevler.Yukle;
var
  i: TISayi4;
begin

  // bellek giri�lerini g�rev yap�lar�yla e�le�tir
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do Gorev[i] := nil;
end;

function TGorevler.GorevAl(ASiraNo: TSayi4): PGorev;
begin

  // istenen verinin belirtilen aral�kta olup olmad���n� kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_GOREVSAYISI) then
    Result := FGorevListesi[ASiraNo]
  else Result := nil;
end;

procedure TGorevler.GorevYaz(ASiraNo: TSayi4; AGorev: PGorev);
begin

  // istenen verinin belirtilen aral�kta olup olmad���n� kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_GOREVSAYISI) then
    FGorevListesi[ASiraNo] := AGorev;
end;

{==============================================================================
  g�rev (program) dosyalar�n� �al��t�r�r
 ==============================================================================}
function TGorevler.Calistir(ATamDosyaYolu: string; ASeviyeNo: TSayi4): PGorev;
var
  G: PGorev;
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

//  while KritikBolgeyeGir(GorevKilit) = False do;

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
    G := Gorevler0.Olustur;
    if(G = nil) then
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
    Olay := GetMem(4096);
    if(Olay = nil) then
    begin

      SISTEM_MESAJ(mtHata, RENK_SIYAH, 'GOREV.PAS: olay bilgisi i�in bellek ayr�lam�yor!', []);
      Result := nil;
      KritikBolgedenCik(GorevKilit);
      asm sti end;
      Exit;
    end;

    // i�lemin olay bellek b�lgesini ata
    G^.OlayBellekAdresi := Olay;

    // g�rev olay sayac�n� s�f�rla
    G^.OlaySayisi := 0;

    // g�rev �al��ma seviye numaras� - �ncelik derecesi
    G^.SeviyeNo := ASeviyeNo;

    // g�rev de�i�im sayac�n� s�f�rla
    G^.GorevSayaci := 0;

    // bellek ba�lang�� adresi
    G^.BellekBaslangicAdresi := TSayi4(DosyaBellek);

    // g�rev �al��ma s�releri
    G^.CalismaSuresiMS := 2;
    G^.CalismaSuresiSayacMS := 2;

    // bellek miktar�
    G^.BellekUzunlugu := ProgramBellekU;

    // i�lem ba�lang�� adresi
    G^.KodBaslangicAdresi := ELFBaslik^.KodBaslangicAdresi;

    // i�lemin y���n adresi
    if(DosyaAdi = 'defter.c') then
      G^.YiginBaslangicAdresi := (ProgramBellekU - DEFTER_BELLEK_U) - 512
    else G^.YiginBaslangicAdresi := ProgramBellekU - 512;

    // dosyan�n �al��t�r�lmas� i�in se�icileri olu�tur
    Gorevler0.SecicileriOlustur(G^.Kimlik, G^.BellekUzunlugu,
      G^.BellekBaslangicAdresi, G^.KodBaslangicAdresi, G^.YiginBaslangicAdresi);

    // i�lemin ad�
    G^.DosyaAdi := DosyaAdi;

    // program �nde�er ad�
    G^.ProgramAdi := '';

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
    G^.Durum := gdCalisiyor;

    // g�rev i�lem say�s�n� bir art�r
    Inc(FCalisanGorevSayisi);

    // g�rev bayrak de�erini art�r
    Inc(GorevBayrakDegeri);

    // program�n iz kay�t dosyas�n� olu�tur
    {IzKayitDosyaAdi := DosyaAdiniAl(DosyaAdi);
    IzKayitDosyaAdi += '.log'; //izkayit';
    IzKaydiOlustur(IzKayitDosyaAdi, IzKayitDosyaAdi + ' uygulamas� �al��t�r�ld�');}

    // g�rev bellek adresini geri d�nd�r
    Result := G;

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
  G: PGorev;
begin

  // bo� i�lem giri�i bul
  G := Gorevler0.BosGorevBul;

  Result := G;
end;

{==============================================================================
  �al��acak g�rev i�in bo� g�rev bul
 ==============================================================================}
function TGorevler.BosGorevBul: PGorev;
var
  G: PGorev;
  i: TSayi4;
begin

  // t�m i�lem giri�lerini incele
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    G := Gorev[i];

    // e�er g�rev giri�i bo� ise
    if(G = nil) then
    begin

      G := GetMem(SizeOf(TGorev));
      Gorev[i] := G;

      // g�revi bo� olarak belirle
      //G^.FGorevDurum := gdBos;
      G^.DosyaSonIslemDurum := HATA_DOSYA_ISLEM_BASARILI;
      G^.Kimlik := i;
      G^.AktifMasaustu := nil;
      G^.AktifPencere := nil;

      // g�rev giri�ini ayr�lm�� olarak i�aretle ve �a��ran i�leve geri d�n
      //Gorevler0.DurumDegistir(i, gdOlusturuldu);
      G^.Durum := gdOlusturuldu;
      Exit(G);
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
  G: PGorev;
begin

  G := Gorev[AGorevKimlik];
  if(G = nil) then Exit;

  if(G^.Durum <> AGorevDurum) then G^.Durum := AGorevDurum;
end;

{==============================================================================
  g�rev sayac�n� belirler
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
  g�revin olay say�s�n� belirler
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
  �ekirdek taraf�ndan g�rev i�in olu�turulan olay� kaydeder
 ==============================================================================}
procedure TGorevler.OlayEkle(AGorevKimlik: TKimlik; AOlay: TOlay);
var
  G: PGorev;
  Olay: POlay;
begin

  while KritikBolgeyeGir(OlayKilit) = False do;

  G := Gorev[AGorevKimlik];
  if(G = nil) then
  begin

    KritikBolgedenCik(OlayKilit);
    Exit;
  end;

  if(G^.Durum = gdCalisiyor) then
  begin

    // olay belle�i dolu de�ilse olay� kaydet
    if(G^.OlaySayisi < USTSINIR_OLAY) then
    begin

      // i�lemin olay belle�ine konumlan
      Olay := G^.OlayBellekAdresi;
      Inc(Olay, G^.OlaySayisi);

      // olay� i�lem belle�ine kaydet
      Olay^.Kimlik := AOlay.Kimlik;
      Olay^.Olay := AOlay.Olay;
      Olay^.Deger1 := AOlay.Deger1;
      Olay^.Deger2 := AOlay.Deger2;

      // g�revin olay sayac�n� art�r
      G^.OlaySayisi := G^.OlaySayisi + 1;
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

  // �nde�er ��k�� de�eri
  Result := False;

  G := Gorev[AKimlik];
  if(G = nil) then
  begin

    KritikBolgedenCik(OlayKilit);
    Exit;
  end;

  i := G^.OlaySayisi;

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
    G^.OlaySayisi := i;

    KritikBolgedenCik(OlayKilit);
    Exit;
  end;

  // olay� g�revin olay belle�inden sil
  Olay2 := Olay1;
  Inc(Olay2);

  Tasi2(Olay2, Olay1, SizeOf(TOlay) * i);

  // olay sayac�n� azalt
  G^.OlaySayisi := i;

  KritikBolgedenCik(OlayKilit);
end;

{==============================================================================
  �al��an g�revi sonland�r�r
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

  // g�revin sonland�r�lma bilgisini ver
  if(ASonlanmaSebebi = -1) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'GOREV.PAS: ' + G^.DosyaAdi + ' normal bir �ekilde sonland�r�ld�.', []);
  end
  else
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'GOREV.PAS: ' + G^.DosyaAdi +
      ' program� istenmeyen bir i�lem yapt���ndan dolay� sonland�r�ld�', []);
    SISTEM_MESAJ(mtHata, RENK_MAVI, '  -> Hata Kodu: ' + IntToStr(ASonlanmaSebebi) + ' - ' +
      IstisnaAciklamaListesi[ASonlanmaSebebi], []);
    SISTEM_MESAJ(mtHata, RENK_SIYAH, '  -> CS: $%.8x', [G^.HataCS]);
    SISTEM_MESAJ(mtHata, RENK_SIYAH, '  -> EIP: $%.8x', [G^.HataEIP]);
    SISTEM_MESAJ(mtHata, RENK_SIYAH, '  -> ESP: $%.8x', [G^.HataESP]);
    SISTEM_MESAJ(mtHata, RENK_SIYAH, '  -> EFLAGS: $%.8x', [G^.HataBayrak]);
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
  FreeMem(G^.OlayBellekAdresi, 4096);

  // g�rev i�in ayr�lan bellek b�lgesini serbest b�rak
  FreeMem(Isaretci(G^.BellekBaslangicAdresi), G^.BellekUzunlugu);

  // g�revi i�lem listesinden ��kart
  Gorev[G^.Kimlik] := nil;
  FreeMem(G, SizeOf(TGorev));

  // g�rev say�s�n� bir azalt
  Dec(FCalisanGorevSayisi);

  // g�rev bayrak de�erini art�r
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

  G^.HataKodu := -1;
  G^.HataESP := -1;
  G^.Durum := gdSonlandiriliyor;
end;

{==============================================================================
  g�rev ile ilgili bellek b�lgesini geri d�nd�r�r
 ==============================================================================}
function GorevBilgisiAl(AGorevSiraNo: TISayi4): PGorev;
var
  G: PGorev;
  i, j: TISayi4;
begin

  // aranacak g�rev s�ra numaras�
  j := -1;

  // t�m i�lem bellek b�lgelerini ara�t�r
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    G := Gorevler0.Gorev[i];

    // listenin ilgili s�ras�nda g�rev mevcut ise g�rev s�ra numaras�n� bir art�r
    if not(G = nil) then Inc(j);

    // g�rev s�ra no aranan g�rev ise i�lem bellek b�lgesini geri d�nd�r
    if(AGorevSiraNo = j) then Exit(G);
  end;

  Result := nil;
end;

{==============================================================================
  pencereye sahip g�rev say�s�n� al�r
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

    // 1. g�rev bo� de�ilse
    // 2. pencereye sahip ise
    // 3. pencere tipi ba�l�ks�z de�ilse
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
  G: PGorev;
  i, ArananGorev: TISayi4;
begin

  ArananGorev := -1;

  Result.PencereKimlik := HATA_KIMLIK;

  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    G := Gorevler0.Gorev[i];

    // 1. g�rev bo� de�ilse
    // 2. pencereye sahip ise
    // 3. pencere tipi ba�l�ks�z de�ilse
    if not(G = nil) and not(G^.AktifPencere = nil) and
      not(PPencere(G^.AktifPencere)^.FPencereTipi = ptBasliksiz) then
    begin

      if(AMasaustuKimlik = -1) then
        Inc(ArananGorev)
      else if(G^.AktifMasaustu^.Kimlik = AMasaustuKimlik) then
        Inc(ArananGorev);
    end;

    // g�rev s�ra no aranan g�rev ise i�lem bellek b�lgesini geri d�nd�r
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
  g�rev kimlik numaras�na g�re g�rev aramas� yapar
 ==============================================================================}
function TGorevler.GorevBul(AGorevKimlik: TKimlik): PGorev;
var
  G: PGorev;
  i: TSayi4;
begin

  // t�m g�rev giri�lerini incele
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    G := Gorev[i];

    // e�er g�rev giri�i bo� ise
    if(G^.Durum = gdCalisiyor) and (G^.Kimlik = AGorevKimlik) then
      Exit(G);
  end;

  Result := nil;
end;

{==============================================================================
  g�rev ad�ndan g�rev kimlik numaras�n� al�r
 ==============================================================================}
function TGorevler.GorevKimligiAl(AGorevAdi: string): TKimlik;
var
  G: PGorev;
  i: TSayi4;
begin

  // t�m i�lem bellek b�lgelerini ara�t�r
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    G := Gorev[i];

    // g�rev bo� de�il ise g�rev s�ra numaras�n� bir art�r
    if not(G = nil) and (G^.DosyaAdi = AGorevAdi) then Exit(G^.Kimlik);
  end;

  Result := -1;
end;

{==============================================================================
  g�rev bellek s�ra numaras�n� geri d�nd�r�r
 ==============================================================================}
function GorevSiraNumarasiniAl(AGorevSiraNo: TISayi4): TKimlik;
var
  G: PGorev;
  i, j: TISayi4;
begin

  // aranacak g�rev s�ra numaras�
  j := -1;

  // t�m i�lem bellek b�lgelerini ara�t�r
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    G := Gorevler0.Gorev[i];

    // g�rev �al���yor ise g�rev s�ra numaras�n� bir art�r
    if(G^.Durum = gdCalisiyor) then Inc(j);

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
  G: PGorev;
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

    G := Gorevler0.Gorev[GorevKimlik];

    // �al��an g�rev aranan g�rev ise �a��ran i�leve geri d�n
    if(G^.Durum = gdCalisiyor) then Break;
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
  G: PGorev;
  i: TISayi4;
begin

  while KritikBolgeyeGir(GorevKilit) = False do;

  // bellek giri�lerini g�rev yap�lar�yla e�le�tir
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    G := Gorevler0.Gorev[i];
    if not(G = nil) and (G^.Durum = gdSonlandiriliyor) then
      Gorevler0.Sonlandir(G^.Kimlik, G^.HataKodu);
  end;

  KritikBolgedenCik(GorevKilit);
end;

{==============================================================================
  g�rev i�in belli bir g�revi yerine getiren i�lev olu�turur - (thread)
  bilgi: sa�ma sapan kelime olan thread kelimesini kullanmay� uygun bulmuyorum
 ==============================================================================}
function Memur(AGorevAdi: string; AIslev: TIslev; AYiginDegeri: TSayi4; ASeviyeNo: TSayi4): TSayi4;
var
  G: PGorev;
  // yazma�lar�n girdi i�erisindeki s�ra numaralar�
  SNYazmacCS, SNYazmacDS, SNYazmacTSS,
  i: TSayi4;
begin

  while KritikBolgeyeGir(GorevKilit) = False do;

  G := Gorevler0.BosGorevBul;
  if not(G = nil) then
  begin

    i := G^.Kimlik;

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

    // sistem g�rev ad� (dosya ad�)
    G^.DosyaAdi := 'cekirdek.bin';
    G^.ProgramAdi := AGorevAdi;

    // sistem g�revini �al���yor olarak i�aretle
    Gorevler0.DurumDegistir(i, gdCalisiyor);

    // �al��an ve olu�turulan g�rev de�erlerini belirle
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
