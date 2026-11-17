{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: src_ide.pas
  Dosya Ýþlevi: ide aygýt sürücüsü

  Güncelleme Tarihi: 17/11/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
//{$DEFINE IDE_BILGI}
unit src_ide;

interface

uses paylasim, port, aygit;

type
  PBoolean = ^Boolean;

const
  USTSINIR_IDE_AYGIT_SAYISI         = 8;
  BEKLEME_SURESI                    = 3;

const
  ATAYAZMAC_VERI                    = $00;    // okunabilir / yazýlabilir
  ATAYAZMAC_HATA                    = $01;    // okunabilir
  ATAYAZMAC_SEKTORSAYISI            = $02;    // okunabilir / yazýlabilir
  ATAYAZMAC_SEKTOR_A8               = $03;    // okunabilir / yazýlabilir - Alt 8 bit
  ATAYAZMAC_SEKTOR_O8               = $04;    // okunabilir / yazýlabilir - Orta 8 bit
  ATAYAZMAC_SEKTOR_U8               = $05;    // okunabilir / yazýlabilir - Üst 8 bit
  ATAYAZMAC_AYGITSECIM              = $06;    // okunabilir / yazýlabilir
  ATAYAZMAC_DURUM                   = $07;    // okunabilir
  ATAYAZMAC_KOMUT                   = $07;    // yazýlabilir

  ATAKOMUT_SEKTOROKU                = $20;
  ATAKOMUT_SEKTORYAZ                = $30;

  ATAYAZMAC_DURUM_MESGUL            = $80;    // aygýt meþgul
  ATAYAZMAC_DURUM_AYGITHAZIR        = $40;    // aygýt hazýr
  ATAYAZMAC_DURUM_YAZMAHATASI       = $20;    // aygýt yazma hatasý
  ATAYAZMAC_DURUM_KOMULANMABASARILI = $10;    // aygýt konumlanma tamamlandý
  ATAYAZMAC_DURUM_VERIHAZIR         = $08;    // aygýt veri için hazýr
  ATAYAZMAC_DURUM_DUZELTILMISVERI   = $04;    // düzeltilmiþ veri
  ATAYAZMAC_DURUM_SIRANO            = $02;    // sýra no
  ATAYAZMAC_DURUM_HATA              = $01;    // hata

  ATA_KANAL0                        = 0;
  ATA_KANAL1                        = 1;

  KOMUT_AYGITTANIMLA                = $EC;

type
  PATA4 = ^TATA4;
  TATA4 = packed record
    Ayar: Word;                               // 0
    SilindirSayisi: Word;                     // 1
    Ayrildi1: Word;                           // 2
    KafaSayisi: Word;                         // 3
    Eskidi1: array[0..1] of Word;             // 4-5
    IzBasinaSektor: Word;                     // 6
    Eskidi2: array[0..2] of Word;             // 7-9
    SeriNo: array[0..19] of Char;             // 10-19
    Eskidi3: array[0..1] of Word;             // 20-21
    Eskidi4: Word;                            // 22
    FirmaYazilimSurum: array[0..7] of Char;   // 23-26
    ModelNo: array[0..39] of Char;            // 27-46
    IslemAzamiSektorSayisi: Word;             // 47
    Ayrildi2: Word;                           // 48
    Yetenek1: Word;                           // 49 - 8. bit dma desteði, 9. bit = lba desteði
    Yetenek2: Word;                           // 50
    PIOModu: Word;                            // 51
    Eskidi5: Word;                            // 52
    AlanDogrulugu1: Word;                     // 53
    SilindirSayisi2: Word;                    // 54
    KafaSayisi2: Word;                        // 55
    IzBasinaSektor2: Word;                    // 56
    SektorOlarakKapasite: LongWord;           // 57-58
    CokluSektor: Word;                        // 59
    ToplamSektor: LongWord;                   // 60-61 - (lba modunda)
    Diger1: array[0..17] of Word;             // 62-79
    SurumNo: Word;                            // 80
    Diger2: array[81..255] of Word;           // diðer veri alanlarý
  end;

type
  PATA6 = ^TATA6;
  TATA6 = packed record
    Ayar: Word;                               // 0
    Eskidi1: Word;                            // 1
    OzelAyar: Word;                           // 2
    Eskidi2: Word;                            // 3
    Eskidi3: array[0..1] of Word;             // 4-5
    Eskidi4: Word;                            // 6
    Ayrildi1: array[0..1] of Word;            // 7-8
    Eskidi5: Word;                            // 9
    SeriNo: array[0..19] of Char;             // 10-19
    Eskidi6: array[0..1] of Word;             // 20-21
    Eskidi7: Word;                            // 22
    FirmaYazilimSurum: array[0..7] of Char;   // 23-26
    ModelNo: array[0..39] of Char;            // 27-46
    IslemAzamiSektorSayisi: Word;             // 47
    Ayrildi2: Word;                           // 48
    Yetenek1: Word;                           // 49
    Yetenek2: Word;                           // 50
    Eskidi8: array[0..1] of Word;             // 51-52
    AlanDogrulugu1: Word;                     // 53
    Eskidi9: array[0..4] of Word;             // 54-58
    AlanDogrulugu2: Word;                     // 59
    ToplamSektor: LongWord;                   // 60-61
    Eskidi10: array[0..17] of Word;           // 62-79
    SurumNo: Word;                            // 80
    Diger: array[81..255] of Word;            // diðer data alanlarý
  end;

type
  TIDEAygiti = class(TFDAygiti)
  public
    constructor Create; override;
    destructor Destroy; override;
    function Oku28(AIlkSektor, ASektorSayisi: TSayi4; ABellekAdresi: Isaretci): TSayi4;
    function Yaz28(AIlkSektor, ASektorSayisi: TSayi4; ABellekAdresi: Isaretci): TSayi4;
    procedure Bekle;
  end;

type
  TIDEAygitListesi = class
  private
    FToplamAygit: TSayi4;
    FDiskAygitlari: array[0..USTSINIR_IDE_AYGIT_SAYISI - 1] of TIDEAygiti;
    function Al(ASiraNo: TISayi4): TIDEAygiti;
    procedure Yaz(ASiraNo: TISayi4; AIDEDisk: TIDEAygiti);
    procedure Yukle;
    function IDEAygitiMevcutMu(AAnaPort, AKanal: TSayi4): Boolean;
    function IDEAygitBilgisiAl(AAnaPort, AKanal: TSayi4; AAygitBilgisi: Isaretci): Boolean;
    function IDEAygitiMesgulMu(AAnaPort: TSayi4): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    property DiskAygitlari[ASiraNo: TISayi4]: TIDEAygiti read Al write Yaz;
    property ToplamAygit: TSayi4 read FToplamAygit;
  end;

procedure IRQ14KesmeIslevi;
procedure IRQ15KesmeIslevi;

var
  GIDEAygitListesi: TIDEAygitListesi;
  IRQ14Tetiklendi,
  IRQ15Tetiklendi: Boolean;
  SektorOkuYazKilit: TSayi4;

implementation

uses irq, fdepolama, zamanlayici, sistemmesaj;

type
  TIDEKayit = record
    AnaPort, KontrolPort,
    AnaKanal,               // master / slave kanalý
    IRQKanal: TSayi4;       // porta baðlý irq kanalý
  end;

var
  IDEKayitListesi: array[0..3] of TIDEKayit = (
    (AnaPort: $1F0; KontrolPort: $3F6; AnaKanal: ATA_KANAL0; IRQKanal: 0),
    (AnaPort: $1F0; KontrolPort: $3F6; AnaKanal: ATA_KANAL1; IRQKanal: 0),
    (AnaPort: $170; KontrolPort: $376; AnaKanal: ATA_KANAL0; IRQKanal: 1),
    (AnaPort: $170; KontrolPort: $376; AnaKanal: ATA_KANAL1; IRQKanal: 1));

// ide kanalýný kilitler
function IDEKanalKilitle(AKanal: TSayi4): Boolean; assembler; nostackframe;
asm

  lock  bts [SektorOkuYazKilit],eax
  setnc al
  movzx eax, al
end;

// ide kanalýný açar
procedure IDEKanalKilidiAc(AKanal: TSayi4); assembler; nostackframe;
asm

  lock  btr [SektorOkuYazKilit],eax
end;

{==============================================================================
  ide aygýtý oluþturma iþlevi
 ==============================================================================}
constructor TIDEAygiti.Create;
begin

  inherited Create;
end;

{==============================================================================
  ide aygýtý yok etme iþlevi
 ==============================================================================}
destructor TIDEAygiti.Destroy;
begin

  inherited Destroy;
end;

{==============================================================================
  lba modunda 28 bitlik sektör okuma iþlevi - çoklu okuma
 ==============================================================================}
function TIDEAygiti.Oku28(AIlkSektor, ASektorSayisi: TSayi4; ABellekAdresi: Isaretci): TSayi4;
var
  BellekAdresi: Isaretci;
  BeklemeDegeri,
  Sektor, i: TSayi4;
  PortNo: TSayi2;
  j: TSayi1;
  IRQTetiklendi: PBoolean;
begin

  Result := HATA_AYGITMESGUL;

  // iþlev kontrolleri

  // okunacak sektör sayýsý kontrolleri
  if(ASektorSayisi = 0) or (ASektorSayisi > 256) then Exit;

  // sektör numarasý sýnýr kontrolleri
  if(AIlkSektor > $0FFFFFFF) or (AIlkSektor - 1 > $0FFFFFFF - ASektorSayisi) then Exit;

  // kanal kilitliyse (aygýt kullanýmda) çýk
  if not(IDEKanalKilitle(FIRQKanal)) then Exit;

  if(FIRQKanal = 0) then
    IRQTetiklendi := @IRQ14Tetiklendi
  else
    IRQTetiklendi := @IRQ15Tetiklendi;

  try

    BellekAdresi := ABellekAdresi;

    // 0..3 bit - lba 27..24
    i := ((AIlkSektor shr 24) and $0F);
    // 4. bit - aygýt seçimi -> 0 = 0. aygýt, 1 = 1. aygýt
    i := i or (FAnaKanal shl 4);
    // 7. bit - 1, 6. bit - LBA ise 1, 5. bit = 1
    i := i or %11100000;
    PortYaz1(FAnaPort + ATAYAZMAC_AYGITSECIM, i);

    Bekle;

    // irq durumu sýfýrlanýyor
    IRQTetiklendi^ := False;

    // okunacak sektör sayýsý
    PortYaz1(FAnaPort + ATAYAZMAC_SEKTORSAYISI, ASektorSayisi and $FF);

    // okunacak sektör numarasý (28 bit)
    // LBA 07..00
    PortYaz1(FAnaPort + ATAYAZMAC_SEKTOR_A8, (AIlkSektor and $FF));
    // LBA 15..08
    PortYaz1(FAnaPort + ATAYAZMAC_SEKTOR_O8, ((AIlkSektor shr 8) and $FF));
    // LBA 23..16
    PortYaz1(FAnaPort + ATAYAZMAC_SEKTOR_U8, ((AIlkSektor shr 16) and $FF));

    PortNo := FAnaPort;

    sti;

    // sektör oku komutu gönder
    PortYaz1(FAnaPort + ATAYAZMAC_KOMUT, ATAKOMUT_SEKTOROKU);

    // çoklu okuma iþlevini gerçekleþtir
    for Sektor := 0 to ASektorSayisi - 1 do
    begin

      BeklemeDegeri := GZamanlayicilar.FZamanlayiciSayaci + (BEKLEME_SURESI * CALISMA_FREKANSI);

      // belirlenen süre içerisinde sektör okuma için irq sinyalini bekle
      while not IRQTetiklendi^ do
      begin

        if(BeklemeDegeri <= GZamanlayicilar.FZamanlayiciSayaci) then Exit;
      end;

      // irq durumu sýfýrlanýyor
      IRQTetiklendi^ := False;

      // durum yazmacýný oku
      j := PortAl1(FAnaPort + ATAYAZMAC_DURUM);

      // hata kontrolü
      if((j and ATAYAZMAC_DURUM_HATA) <> 0) or ((j and ATAYAZMAC_DURUM_YAZMAHATASI) <> 0) then
      begin

        PortAl1(FAnaPort + ATAYAZMAC_HATA);
        Exit;
      end;

      // durum meþgul kontrolü
      if((j and ATAYAZMAC_DURUM_MESGUL) <> 0) then Exit;

      // veri hazýr kontrolü
      if((j and ATAYAZMAC_DURUM_VERIHAZIR) = 0) then Exit;

      // hazýr olan veriyi oku
      asm
        mov dx,PortNo
        mov ecx,256
        mov edi,BellekAdresi
        cld
        rep insw
      end;

      BellekAdresi := BellekAdresi + 512;
    end;

    // belirlenen süre içerisinde son iþlem durumunu bekle
    BeklemeDegeri := GZamanlayicilar.FZamanlayiciSayaci + (BEKLEME_SURESI * CALISMA_FREKANSI);

    repeat

      j := PortAl1(FAnaPort + ATAYAZMAC_DURUM);

      if((j and ATAYAZMAC_DURUM_HATA) <> 0) or ((j and ATAYAZMAC_DURUM_YAZMAHATASI) <> 0) then
      begin

        PortAl1(FAnaPort + ATAYAZMAC_HATA);
        Exit;
      end;

      // durum meþgul kontrolü
      if((j and ATAYAZMAC_DURUM_MESGUL) = 0) then Break;

    until BeklemeDegeri <= GZamanlayicilar.FZamanlayiciSayaci;

    // durum meþgul kontrolü
    if((j and ATAYAZMAC_DURUM_MESGUL) <> 0) then Exit;

    Result := HATA_YOK;

  finally

    IDEKanalKilidiAc(FIRQKanal);
  end;
end;

{==============================================================================
  lba modunda 28 bitlik sektör yazma iþlevi - çoklu yazma
 ==============================================================================}
function TIDEAygiti.Yaz28(AIlkSektor, ASektorSayisi: TSayi4; ABellekAdresi: Isaretci): TSayi4;
var
  BellekAdresi: Isaretci;
  BeklemeDegeri, ZamanAsimi,
  i, Sektor: TSayi4;
  PortNo: TSayi2;
  j: TSayi1;
  IRQTetiklendi: PBoolean;
begin

  Result := HATA_AYGITMESGUL;

  if(ASektorSayisi = 0) or (ASektorSayisi > 256) then Exit;

  if(AIlkSektor > $0FFFFFFF - (ASektorSayisi - 1)) then Exit;

  // kanal kilitliyse (aygýt kullanýmda) çýk
  if not(IDEKanalKilitle(FIRQKanal)) then Exit;

  if(FIRQKanal = 0) then
    IRQTetiklendi := @IRQ14Tetiklendi
  else
    IRQTetiklendi := @IRQ15Tetiklendi;

  try

    BellekAdresi := ABellekAdresi;

    // 0..3 bit - lba 27..24
    i := ((AIlkSektor shr 24) and $0F);
    // 4. bit - aygýt seçimi
    i := i or (FAnaKanal shl 4);
    // 7. bit - 1, 6. bit - LBA ise 1, 5. bit = 1
    i := i or %11100000;
    PortYaz1(FAnaPort + ATAYAZMAC_AYGITSECIM, i);

    Bekle;

    // irq durumu sýfýrlanýyor
    IRQTetiklendi^ := False;

    // yazýlacak sektör sayýsý
    // 0 deðeri 256 sektör olarak yorumlanýr
    PortYaz1(FAnaPort + ATAYAZMAC_SEKTORSAYISI, ASektorSayisi and $FF);

    // yazýlacak sektör numarasý (28 bit)
    // LBA 07..00
    PortYaz1(FAnaPort + ATAYAZMAC_SEKTOR_A8, (AIlkSektor and $FF));
    // LBA 15..08
    PortYaz1(FAnaPort + ATAYAZMAC_SEKTOR_O8, ((AIlkSektor shr 8) and $FF));
    // LBA 23..16
    PortYaz1(FAnaPort + ATAYAZMAC_SEKTOR_U8, ((AIlkSektor shr 16) and $FF));

    PortNo := FAnaPort;

    sti;

    // sektör yaz komutu gönder
    PortYaz1(FAnaPort + ATAYAZMAC_KOMUT, ATAKOMUT_SEKTORYAZ);

    // çoklu yazma iþlevini gerçekleþtir
    for Sektor := 0 to ASektorSayisi - 1 do
    begin

      // ilk sektör haricindeki yazma iþlemi için irq bekle
      if(Sektor > 0) then
      begin

        BeklemeDegeri := GZamanlayicilar.FZamanlayiciSayaci + (BEKLEME_SURESI * CALISMA_FREKANSI);

        // belirlenen süre içerisinde sektör yazma için irq sinyalini bekle
        while not IRQTetiklendi^ do
        begin

          if(BeklemeDegeri <= GZamanlayicilar.FZamanlayiciSayaci) then Exit;
        end;

        // irq durumu sýfýrlanýyor
        IRQTetiklendi^ := False;
      end;

      // yazmaç durum kontrolü - drq ve hata kontrolü
      BeklemeDegeri := GZamanlayicilar.FZamanlayiciSayaci + (BEKLEME_SURESI * CALISMA_FREKANSI);

      repeat

        j := PortAl1(FAnaPort + ATAYAZMAC_DURUM);

        if((j and ATAYAZMAC_DURUM_HATA) <> 0) or
          ((j and ATAYAZMAC_DURUM_YAZMAHATASI) <> 0) then
        begin

          PortAl1(FAnaPort + ATAYAZMAC_HATA);
          Exit;
        end;

        // durum meþgul ve veri hazýr kontrolü
        if((j and ATAYAZMAC_DURUM_MESGUL) = 0) and
          ((j and ATAYAZMAC_DURUM_VERIHAZIR) <> 0) then Break;

      until BeklemeDegeri <= GZamanlayicilar.FZamanlayiciSayaci;

      // veri hazýr kontrolü
      if((j and ATAYAZMAC_DURUM_VERIHAZIR) = 0) then Exit;

      asm
        mov dx,PortNo
        mov ecx,256
        mov esi,BellekAdresi
        cld
        rep outsw
      end;

      BellekAdresi := BellekAdresi + 512;
    end;

    BeklemeDegeri := GZamanlayicilar.FZamanlayiciSayaci + (BEKLEME_SURESI * CALISMA_FREKANSI);

    // belirlenen süre içerisinde sektör yazma tamamlanmasý için irq sinyalini bekle
    while not IRQTetiklendi^ do
    begin

      if(BeklemeDegeri <= GZamanlayicilar.FZamanlayiciSayaci) then Exit;
    end;

    // irq durumu sýfýrlanýyor
    IRQTetiklendi^ := False;

    // durum yazmacýný oku
    j := PortAl1(FAnaPort + ATAYAZMAC_DURUM);

    if((j and ATAYAZMAC_DURUM_HATA) <> 0) or
      ((j and ATAYAZMAC_DURUM_YAZMAHATASI) <> 0) then
    begin

      PortAl1(FAnaPort + ATAYAZMAC_HATA);
      Exit;
    end;

    // durum meþgul ve veri hazýr kontrolü
    if((j and ATAYAZMAC_DURUM_MESGUL) = 0) and
      ((j and ATAYAZMAC_DURUM_VERIHAZIR) = 0) then Result := HATA_YOK;

  finally

    IDEKanalKilidiAc(FIRQKanal);
  end;
end;

{==============================================================================
  4 milisaniye bekleme iþlevi
 ==============================================================================}
procedure TIDEAygiti.Bekle;
begin

  PortAl1(FKontrolPort);
  PortAl1(FKontrolPort);
  PortAl1(FKontrolPort);
  PortAl1(FKontrolPort);
end;

{==============================================================================
  ide aygýtlarý nesne yükleme iþlevlerini gerçekleþtirir
 ==============================================================================}
constructor TIDEAygitListesi.Create;
var
  i: TSayi4;
begin

  FToplamAygit := 0;

  // nesneleri ilk deðerlerle yükle
  for i := 0 to USTSINIR_IDE_AYGIT_SAYISI - 1 do DiskAygitlari[i] := nil;

  SektorOkuYazKilit := 0;

  // sistemde mevcut ide aygýtlarýný yükle
  Yukle;
end;

{==============================================================================
  ide aygýtlarý nesne yok etme iþlevlerini gerçekleþtirir
 ==============================================================================}
destructor TIDEAygitListesi.Destroy;
var
  i: TSayi4;
begin

  for i := 0 to USTSINIR_IDE_AYGIT_SAYISI - 1 do
  begin

    if not(DiskAygitlari[i] = nil) then
    begin

      DiskAygitlari[i].Destroy;
      DiskAygitlari[i] := nil;
    end;
  end;

  inherited Destroy;
end;

function TIDEAygitListesi.Al(ASiraNo: TISayi4): TIDEAygiti;
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_IDE_AYGIT_SAYISI) then
    Result := FDiskAygitlari[ASiraNo]
  else Result := nil;
end;

procedure TIDEAygitListesi.Yaz(ASiraNo: TISayi4; AIDEDisk: TIDEAygiti);
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_IDE_AYGIT_SAYISI) then
    FDiskAygitlari[ASiraNo] := AIDEDisk;
end;

{==============================================================================
  ide aygýtlarýný yükleme iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure TIDEAygitListesi.Yukle;
var
  FD: TFDAygiti;
  Bellek: TATA4;
  i: TSayi4;
begin

  {$IFDEF IDE_BILGI}
  SISTEM_MESAJ(mtBilgi, RENK_MOR, '+ IDE disk aygýtlarý aranýyor...', []);
  {$ENDIF}

  // birinci ve ikinci disk sürücüsü IRQ istek kanalýný etkinleþtir
  IRQIsleviAta(14, @IRQ14KesmeIslevi);
  IRQIsleviAta(15, @IRQ15KesmeIslevi);

  // tüm ide aygýtlarýný tara
  for i := 0 to 3 do
  begin

    // ide aygýtý mevcut mu ?
    if(IDEAygitiMevcutMu(IDEKayitListesi[i].AnaPort, IDEKayitListesi[i].AnaKanal)) then
    begin

      // ide aygýt bilgilerini al
      IDEAygitBilgisiAl(IDEKayitListesi[i].AnaPort, IDEKayitListesi[i].AnaKanal, @Bellek);

      {$IFDEF IDE_BILGI}
      SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, '  - Aygýt: %d', [i + 1]);
      SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, '    - Port No: $%.4x', [IDEAygitlari[i].AnaPort]);
      SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, '    - Kafa Sayýsý: %d', [Bellek.KafaSayisi]);
      SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, '    - Silindir Sayýsý: %d', [Bellek.SilindirSayisi]);
      SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, '    - Ýz Baþýna Sektör: %d', [Bellek.IzBasinaSektor]);
      SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, '    - Toplam Sektor: %d', [Bellek.ToplamSektor]);
      SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, '    - Sektör Olarak Kapasite: %d', [Bellek.SektorOlarakKapasite]);
      {$ENDIF}

      // aygýt mevcut ise fiziksel sürücü yapýsýný oluþtur
      FD := GFizikselDepolama.AygitOlustur(SURUCUTIP_DISK);
      if(FD <> nil) then
      begin

        FD.FAnaPort := IDEKayitListesi[i].AnaPort;
        FD.FKontrolPort := IDEKayitListesi[i].KontrolPort;
        FD.FAnaKanal := IDEKayitListesi[i].AnaKanal;
        FD.FIRQKanal := IDEKayitListesi[i].IRQKanal;

        TIDEAygiti(FD).FOzellikler := 0;

        FD.FOku := @TIDEAygiti(FD).Oku28;
        FD.FYaz := @TIDEAygiti(FD).Yaz28;

        FD.FSilindirSayisi := Bellek.SilindirSayisi;
        FD.FKafaSayisi := Bellek.KafaSayisi;
        FD.FIzBasinaSektorSayisi := Bellek.IzBasinaSektor;
        FD.FToplamSektorSayisi := Bellek.SilindirSayisi * Bellek.KafaSayisi * Bellek.IzBasinaSektor;

        // kesmeyi aktifleþtir
        PortYaz1(FD.FKontrolPort, 0);
      end;
    end;
  end;
end;

{==============================================================================
  ide aygýtýnýn sistemde mevcut olup olmadýðýný kontrol eder
 ==============================================================================}
function TIDEAygitListesi.IDEAygitiMevcutMu(AAnaPort, AKanal: TSayi4): Boolean;
var
  i: TSayi4;
begin

  // öndeðer geri dönüþ deðeri
  Result := False;

  i := (AKanal shl 4) or %11100000;
  PortYaz1(AAnaPort + ATAYAZMAC_AYGITSECIM, i);

  // aygýt meþgul mü ?
  if(IDEAygitiMesgulMu(AAnaPort)) then Exit;

  i := (AKanal shl 4) or %11100000;
  PortYaz1(AAnaPort + ATAYAZMAC_AYGITSECIM, i);

  if(PortAl1(AAnaPort + ATAYAZMAC_AYGITSECIM) <> i) then Exit;

  PortYaz1(AAnaPort + ATAYAZMAC_SEKTOR_O8, $AA);
  if(PortAl1(AAnaPort + ATAYAZMAC_SEKTOR_O8) <> $AA) then Exit;

  PortYaz1(AAnaPort + ATAYAZMAC_SEKTOR_O8, $55);
  if(PortAl1(AAnaPort + ATAYAZMAC_SEKTOR_O8) <> $55) then Exit;

  i := PortAl1(AAnaPort + ATAYAZMAC_DURUM);
  if((i and ATAYAZMAC_DURUM_AYGITHAZIR) = 0) then Exit;

  Result := True;
end;

{==============================================================================
  ide aygýtýyla ilgili tanýmlayýcý bilgileri alýr
 ==============================================================================}
function TIDEAygitListesi.IDEAygitBilgisiAl(AAnaPort, AKanal: TSayi4; AAygitBilgisi: Isaretci): Boolean;
var
  PortNo, i: TSayi4;
begin

  Result := False;

  i := (AKanal shl 4) or %11100000;
  PortYaz1(AAnaPort + ATAYAZMAC_AYGITSECIM, i);

  if(IDEAygitiMesgulMu(AAnaPort)) then Exit;

  PortYaz1(AAnaPort + $206, 2);
  PortYaz1(AAnaPort + ATAYAZMAC_KOMUT, KOMUT_AYGITTANIMLA);

  if(IDEAygitiMesgulMu(AAnaPort)) then Exit;

  PortNo := AAnaPort;

  asm
    mov edx,PortNo
    mov ecx,512 / 2
    mov edi,AAygitBilgisi
    cld
    rep insw
  end;

  Result := True;
end;

{==============================================================================
  ide aygýtýnýn meþgul olup olmadýðýný kontrol eder
 ==============================================================================}
function TIDEAygitListesi.IDEAygitiMesgulMu(AAnaPort: TSayi4): Boolean;
var
  i: TSayi4;
  j: TSayi1;
begin

  Result := True;

  for i := 1 to 100 do
  begin

    j := PortAl1(AAnaPort + ATAYAZMAC_DURUM);

    if((j and ATAYAZMAC_DURUM_MESGUL) = 0) then Exit(False);
  end;
end;

{==============================================================================
  birinci ide disk irq rutini
 ==============================================================================}
procedure IRQ14KesmeIslevi;
begin

  IRQ14Tetiklendi := True;
end;

{==============================================================================
  ikinci ide disk irq rutini
 ==============================================================================}
procedure IRQ15KesmeIslevi;
begin

  IRQ15Tetiklendi := True;
end;

end.
