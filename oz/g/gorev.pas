{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: gorev.pas
  Dosya ��levi: g�rev (program) y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 29/05/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit gorev;

interface

uses paylasim, gn_masaustu, gn_pencere;

const
  // bir g�rev i�in tan�mlanan �st s�n�r olay say�s�
  // olay belle�i 4K olarak tan�mlanm��t�r. 4096 / SizeOf(TOlay)
  USTSINIR_OLAY         = 64;
  PROGRAM_YIGIN_BELLEK  = (4096 * 5) - 1;             // program y���n� (stack) i�in ayr�lacak bellek
  DEFTER_BELLEK_U       = TSayi4((4096 * 10) - 1);    // defter program� i�in program belle�inde ayr�lacak alan

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
  TGorev = object
  private
    FBellekUzunlugu: TSayi4;              // i�lemin kulland��� bellek uzunlu�u
    FKodBaslangicAdres: TSayi4;           // i�lemin bellek ba�lang�� adresi
    FYiginBaslangicAdres: TSayi4;         // i�lemin y���n adresi
    FAktifMasaustu: PMasaustu;            // g�revin aktif masa�st�
    FAktifPencere: PPencere;              // g�revin aktif penceresi
    procedure GorevSayaciYaz(ASayacDegeri: TSayi4);
    procedure OlaySayisiYaz(AOlaySayisi: TSayi4);
  protected
    function Olustur: PGorev;
    function BosGorevBul: PGorev;
    procedure SecicileriOlustur;
  public
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

    FGorevSayaci: TSayi4;                 // g�rev de�i�im sayac�
    FBellekBaslangicAdresi: TSayi4;       // i�lemin y�klendi�i bellek adresi
    FDosyaAdi,                            // g�revin y�klendi�i dosya ad�
    FProgramAdi: string;                  // program ad�
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

{==============================================================================
  �al��t�r�lacak g�revlerin ana y�kleme i�levlerini i�erir
 ==============================================================================}
procedure TGorev.Yukle;
var
  Gorev: PGorev;
  i: TISayi4;
begin

  // g�rev bilgilerinin yerle�tirilmesi i�in bellek ay�r
  Gorev := GGercekBellek.Ayir(SizeOf(TGorev) * USTSINIR_GOREVSAYISI);

  // bellek giri�lerini g�rev yap�lar�yla e�le�tir
  for i := 0 to USTSINIR_GOREVSAYISI - 1 do
  begin

    GorevListesi[i] := Gorev;

    // g�revi bo� olarak belirle
    Gorev^.FGorevDurum := gdBos;
    Gorev^.FDosyaSonIslemDurum := HATA_DOSYA_ISLEM_BASARILI;
    Gorev^.FGorevKimlik := i;
    Gorev^.FAktifMasaustu := nil;
    Gorev^.FAktifPencere := nil;

    Inc(Gorev);
  end;
end;

{==============================================================================
  g�rev (program) dosyalar�n� �al��t�r�r
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
      CalistirGorevNo := 0;
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
      CalistirGorevNo := 0;
      asm sti end;
      Exit;
    end;

    // dosyay� kapat
    CloseFile(DosyaKimlik);

    // bo� i�lem giri�i bul
    Gorev := Gorev^.Olustur;
    if(Gorev = nil) then
    begin

      SISTEM_MESAJ(mtHata, RENK_SIYAH, 'GOREV.PAS: ' + ATamDosyaYolu + ' i�in g�rev olu�turulam�yor!', []);
      Result := nil;
      CalistirGorevNo := 0;
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
      CalistirGorevNo := 0;
      asm sti end;
      Exit;
    end;

    // olay i�lemleri i�in bellekte yer ay�r
    Olay := GetMem(4096);
    if(Olay = nil) then
    begin

      SISTEM_MESAJ(mtHata, RENK_SIYAH, 'GOREV.PAS: olay bilgisi i�in bellek ayr�lam�yor!', []);
      Result := nil;
      CalistirGorevNo := 0;
      asm sti end;
      Exit;
    end;

    // bellek ba�lang�� adresi
    Gorev^.FBellekBaslangicAdresi := TSayi4(DosyaBellek);

    // bellek miktar�
    Gorev^.FBellekUzunlugu := ProgramBellekU;

    // i�lem ba�lang�� adresi
    Gorev^.FKodBaslangicAdres := ELFBaslik^.KodBaslangicAdresi;

    // i�lemin y���n adresi
    if(DosyaAdi = 'defter.c') then
      Gorev^.FYiginBaslangicAdres := (ProgramBellekU - DEFTER_BELLEK_U) - 512
    else Gorev^.FYiginBaslangicAdres := ProgramBellekU - 512;

    // dosyan�n �al��t�r�lmas� i�in se�icileri olu�tur
    Gorev^.SecicileriOlustur;

    // g�rev de�i�im sayac�n� s�f�rla
    Gorev^.FGorevSayaci := 0;

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

    CalistirGorevNo := 0;
  end
  else
  begin

    CloseFile(DosyaKimlik);
    SISTEM_MESAJ(mtHata, RENK_SIYAH, 'GOREV.PAS: ' + TamDosyaYolu + ' dosya okuma hatas�!', []);
  end;

  CalistirGorevNo := 0;

  asm sti end;
end;

{==============================================================================
  �al��acak g�rev i�in bo� g�rev bul
 ==============================================================================}
function TGorev.Olustur: PGorev;
var
  Gorev: PGorev;
begin

  // bo� i�lem giri�i bul
  Gorev := Gorev^.BosGorevBul;

  Result := Gorev;
end;

{==============================================================================
  �al��acak g�rev i�in bo� g�rev bul
 ==============================================================================}
function TGorev.BosGorevBul: PGorev;
var
  Gorev: PGorev;
  i: TSayi4;
begin

  // t�m i�lem giri�lerini incele - ilk 3 g�rev (0, 1, 2) giri�i sisteme ayr�ld�
  for i := AYRILMIS_GOREV_SAYISI to USTSINIR_GOREVSAYISI - 1 do
  begin

    Gorev := GorevListesi[i];

    // e�er g�rev giri�i bo� ise
    if(Gorev^.FGorevDurum = gdBos) then
    begin

      // g�rev giri�ini ayr�lm�� olarak i�aretle ve �a��ran i�leve geri d�n
      Gorev^.DurumDegistir(i, gdOlusturuldu);
      Exit(Gorev);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  g�rev i�in TSS se�icilerini (selekt�r) olu�turur
 ==============================================================================}
procedure TGorev.SecicileriOlustur;
var
  SeciciCSSiraNo, SeciciDSSiraNo,
  SeciciTSSSiraNo: TKimlik;
  Uzunluk, i: TSayi4;
begin

  // uygulaman�n ilk g�rev kimli�i 3 (olan muyntcs.c)'t�r
  i := GorevKimlik;

  Uzunluk := FBellekUzunlugu shr 12;

  // uygulaman�n TSS, CS, DS se�icilerini belirle, her bir program 3 se�ici i�erir
  SeciciCSSiraNo := ((i - (AYRILMIS_GOREV_SAYISI)) * 3) + AYRILMIS_SECICISAYISI;
  SeciciDSSiraNo := SeciciCSSiraNo + 1;
  SeciciTSSSiraNo := SeciciDSSiraNo + 1;

  // uygulama i�in CS selekt�r�n� olu�tur
  // kod se�icisi (CS)
  // Eri�im  : 1 = mevcut, 11 = DPL3, 11 = kod segment, 0 = dallan�lamaz, 1 = okunabilir, 0 = eri�ilmedi
  // Esneklik: 1 = gran = 4K ��z�n�rl�k, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SeciciCSSiraNo, FBellekBaslangicAdresi, Uzunluk, %11111010, %11010000);
  // uygulama i�in DS selekt�r�n� olu�tur
  // veri se�icisi (DS)
  // Eri�im  : 1 = mevcut, 11 = DPL3, 10 = veri yazma�, 0 = artarak b�y�yen, 1 = yaz�labilir, 0 = eri�ilmedi
  // Esneklik: 1 = gran = 4K ��z�n�rl�k, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SeciciDSSiraNo, FBellekBaslangicAdresi, Uzunluk, %11110010, %11010000);
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
  i�lemin yeni �al��ma durumunu belirler
 ==============================================================================}
procedure TGorev.DurumDegistir(AGorevKimlik: TKimlik; AGorevDurum: TGorevDurum);
var
  Gorev: PGorev;
begin

  Gorev := GorevListesi[AGorevKimlik];
  if(AGorevDurum <> Gorev^.FGorevDurum) then Gorev^.FGorevDurum := AGorevDurum;
end;

{==============================================================================
  g�rev sayac�n� belirler
 ==============================================================================}
procedure TGorev.GorevSayaciYaz(ASayacDegeri: TSayi4);
begin

  if(ASayacDegeri <> FGorevSayaci) then FGorevSayaci := ASayacDegeri;
end;

{==============================================================================
  g�revin olay say�s�n� belirler
 ==============================================================================}
procedure TGorev.OlaySayisiYaz(AOlaySayisi: TSayi4);
begin

  if(AOlaySayisi <> FOlaySayisi) then FOlaySayisi := AOlaySayisi;
end;

{==============================================================================
  �ekirdek taraf�ndan g�rev i�in olu�turulan olay� kaydeder
 ==============================================================================}
procedure TGorev.OlayEkle(AGorevKimlik: TKimlik; AOlay: TOlay);
var
  Gorev: PGorev;
  Olay: POlay;
begin

  Gorev := GorevListesi[AGorevKimlik];

  if(Gorev^.FGorevDurum = gdCalisiyor) then
  begin

    // olay belle�i dolu de�ilse olay� kaydet
    if(Gorev^.OlaySayisi < USTSINIR_OLAY) then
    begin

      // i�lemin olay belle�ine konumlan
      Olay := Gorev^.OlayBellekAdresi;
      Inc(Olay, Gorev^.OlaySayisi);

      // olay� i�lem belle�ine kaydet
      Olay^.Kimlik := AOlay.Kimlik;
      Olay^.Olay := AOlay.Olay;
      Olay^.Deger1 := AOlay.Deger1;
      Olay^.Deger2 := AOlay.Deger2;

      // g�revin olay sayac�n� art�r
      Gorev^.OlaySayisi := Gorev^.OlaySayisi + 1;
    end;
  end;
end;

{==============================================================================
  g�rev i�in (�ekirdek taraf�ndan) olu�turulan olay� al�r
 ==============================================================================}
function TGorev.OlayAl(var AOlay: TOlay): Boolean;
var
  Olay1, Olay2: POlay;
  i: TSayi4;
begin

  // �nde�er ��k�� de�eri
  Result := False;

  i := OlaySayisi;

  // g�rev i�in olu�turulan olay yoksa ��k
  if(i = 0) then Exit;

  // �nde�er ��k�� de�eri
  Result := True;

  // g�revin olay belle�ine konumlan
  Olay1 := OlayBellekAdresi;

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
    OlaySayisi := i;

    Exit;
  end;

  // olay� g�revin olay belle�inden sil
  Olay2 := Olay1;
  Inc(Olay2);

  Tasi2(Olay2, Olay1, SizeOf(TOlay) * i);

  // olay sayac�n� azalt
  OlaySayisi := i;
end;

{==============================================================================
  �al��an g�revi sonland�r�r
 ==============================================================================}
function TGorev.Sonlandir(AGorevKimlik: TKimlik; const ASonlanmaSebebi: TISayi4 = -1): TISayi4;
var
  Gorev: PGorev = nil;
begin

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
  FreeMem(Gorev^.OlayBellekAdresi, 4096);

  // g�rev i�in ayr�lan bellek b�lgesini serbest b�rak
  FreeMem(Isaretci(Gorev^.BellekBaslangicAdresi), Gorev^.BellekUzunlugu);

  // g�revi i�lem listesinden ��kart
  DurumDegistir(AGorevKimlik, gdBos);

  // g�rev say�s�n� bir azalt
  Dec(CalisanGorevSayisi);

  // g�rev bayrak de�erini art�r
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
      else if(GorevListesi[i]^.AktifMasaustu^.Kimlik = AMasaustuKimlik) then
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
      else if(GorevListesi[i]^.AktifMasaustu^.Kimlik = AMasaustuKimlik) then
        Inc(ArananGorev);
    end;

    // g�rev s�ra no aranan g�rev ise i�lem bellek b�lgesini geri d�nd�r
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
  g�rev kimlik numaras�na g�re g�rev aramas� yapar
 ==============================================================================}
function TGorev.GorevBul(AGorevKimlik: TKimlik): PGorev;
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
function TGorev.GorevKimligiAl(AGorevAdi: string): TKimlik;
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
  GorevKimlik := CalisanGorev;

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
      Gorev^.Sonlandir(Gorev^.FGorevKimlik, Gorev^.FHataKodu);
  end;
end;

end.
