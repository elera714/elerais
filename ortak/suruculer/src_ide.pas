{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: src_ide.pas
  Dosya Ýþlevi: ide aygýt sürücüsü

  Güncelleme Tarihi: 16/10/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
//{$DEFINE IDE_BILGI}
unit src_ide;

interface

uses paylasim, port, aygit;

const
  USTSINIR_IDE_AYGIT_SAYISI = 8;

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
  ATAYAZMAC_ALTDURUM                = $0C;

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
    Yetenek1: Word;                           // 49
    Yetenek2: Word;                           // 50
    PIOModu: Word;                            // 51
    Eskidi5: Word;                            // 52
    AlanDogrulugu1: Word;                     // 53
    SilindirSayisi2: Word;                    // 54
    KafaSayisi2: Word;                        // 55
    IzBasinaSektor2: Word;                    // 56
    SektorOlarakKapasite: LongWord;           // 57-58
    CokluSektor: Word;                        // 59
    ToplamSektor: LongWord;                   // 60-61
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
    function Oku(AIlkSektor, ASektorSayisi: TSayi4; ABellekAdresi: Isaretci): TSayi4;
    function Oku28(ASektorNo: TSayi4; ABellekAdresi: Isaretci): TSayi4;
    function Yaz(AIlkSektor, ASektorSayisi: TSayi4; ABellekAdresi: Isaretci): TSayi4;
    function Yaz28(ASektorNo: TSayi4; ABellekAdresi: Isaretci): TSayi4;
    function AygitVeriIcinHazirMi: Boolean;
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
  SektorOkuYazKilit: TSayi4 = 0;

implementation

uses irq, sistemmesaj, fdepolama;

type
  TIDEKayit = record
    AnaPort, KontrolPort,
    Kanal: TSayi4;
  end;

var
  IDEKayitListesi: array[0..3] of TIDEKayit = (
    (AnaPort: $1F0; KontrolPort: $3F6; Kanal: ATA_KANAL0),
    (AnaPort: $1F0; KontrolPort: $3F6; Kanal: ATA_KANAL1),
    (AnaPort: $170; KontrolPort: $376; Kanal: ATA_KANAL0),
    (AnaPort: $170; KontrolPort: $376; Kanal: ATA_KANAL1));

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
function TIDEAygiti.Oku(AIlkSektor, ASektorSayisi: TSayi4; ABellekAdresi: Isaretci): TSayi4;
var
  BellekAdresi: Isaretci;
  OkunacakSektorNo,
  OkunacakSektorSayisi: TSayi4;
begin

  asm pushad; pushfd; end;

  BellekAdresi := ABellekAdresi;
  OkunacakSektorNo := AIlkSektor;
  OkunacakSektorSayisi := ASektorSayisi;

  //while KritikBolgeyeGir(SektorOkuYazKilit) = False do;

  // okuma iþlevini gerçekleþtir
  repeat

    Result := Oku28(OkunacakSektorNo, BellekAdresi);
    if(Result = HATA_YOK) then
    begin

      Inc(OkunacakSektorNo);
      Dec(OkunacakSektorSayisi);
      BellekAdresi := BellekAdresi + 512;
    end;

  until (Result <> HATA_YOK) or (OkunacakSektorSayisi = 0);

  //KritikBolgedenCik(SektorOkuYazKilit);

  asm popfd; popad; end;
end;

{==============================================================================
  lba modunda 28 bitlik sektör okuma iþlevi - tek sektör okuma
 ==============================================================================}
function TIDEAygiti.Oku28(ASektorNo: TSayi4; ABellekAdresi: Isaretci): TSayi4;
var
  PortNo: TSayi2;
  i, TekrarSayisi: TSayi4;
begin

  // hata kodunu sýfýrla
  PortYaz1(FAnaPort + ATAYAZMAC_DURUM_HATA, 0);

  // 0..3 bit - lba 27..24
  i := ((ASektorNo shr 24) and $0F);
  // 4. bit - aygýt seçimi
  i := i or (FKanal shl 4);
  // 7. bit - 1, 6. bit - LBA ise 1, 5. bit = 1
  i := i or %11100000;
  PortYaz1(FAnaPort + ATAYAZMAC_AYGITSECIM, i);

  //okunacak sektör sayýsý
  PortYaz1(FAnaPort + ATAYAZMAC_SEKTORSAYISI, 1);

  // okunacak sektör numarasý (28 bit)
  // LBA 07..00
  PortYaz1(FAnaPort + ATAYAZMAC_SEKTOR_A8, (ASektorNo and $FF));
  // LBA 15..08
  PortYaz1(FAnaPort + ATAYAZMAC_SEKTOR_O8, ((ASektorNo shr 8) and $FF));
  // LBA 23..16
  PortYaz1(FAnaPort + ATAYAZMAC_SEKTOR_U8, ((ASektorNo shr 16) and $FF));

  // sektör oku komutu gönder
  PortYaz1(FAnaPort + ATAYAZMAC_KOMUT, ATAKOMUT_SEKTOROKU);

  PortNo := FAnaPort;

  // okuma iþlevini gerçekleþtir
  TekrarSayisi := 5;
  repeat

    if(AygitVeriIcinHazirMi) then
    begin

      asm
        cli
        cld
        mov edi,ABellekAdresi
        mov ecx,512 / 4
        mov dx,PortNo
        rep insd
      end;

      Result := HATA_YOK;
    end
    else
    begin

      Dec(TekrarSayisi);
      Result := HATA_AYGITMESGUL;
    end;

  until (Result = HATA_YOK) or (TekrarSayisi = 0);
end;

{==============================================================================
  lba modunda 28 bitlik sektör yazma iþlevi - çoklu okuma
 ==============================================================================}
function TIDEAygiti.Yaz(AIlkSektor, ASektorSayisi: TSayi4; ABellekAdresi: Isaretci): TSayi4;
var
  BellekAdresi: Isaretci;
  YazilacakSektorNo,
  YazilacakSektorSayisi: TSayi4;
begin

  asm pushad; pushfd; end;

{  if(AIlkSektor < 256) then
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'Hatalý sektör numarasý: %d', [AIlkSektor]);
    Exit(HATA_AYGITMESGUL);
  end;}

  BellekAdresi := ABellekAdresi;
  YazilacakSektorNo := AIlkSektor;
  YazilacakSektorSayisi := ASektorSayisi;

  //while KritikBolgeyeGir(SektorOkuYazKilit) = False do;

  // yazma iþlevini gerçekleþtir
  repeat

    Result := Yaz28(YazilacakSektorNo, BellekAdresi);
    if(Result = HATA_YOK) then
    begin

      Inc(YazilacakSektorNo);
      Dec(YazilacakSektorSayisi);
      BellekAdresi := BellekAdresi + 512;
    end;

  until (Result <> HATA_YOK) or (YazilacakSektorSayisi = 0);

  //KritikBolgedenCik(SektorOkuYazKilit);

  asm popfd; popad; end;
end;

{==============================================================================
  lba modunda 28 bitlik sektör yazma iþlevi - tek sektör yazma
 ==============================================================================}
function TIDEAygiti.Yaz28(ASektorNo: TSayi4; ABellekAdresi: Isaretci): TSayi4;
var
  PortNo: TSayi2;
  i, TekrarSayisi: TSayi4;
begin

  // hata kodunu sýfýrla
  PortYaz1(FAnaPort + ATAYAZMAC_DURUM_HATA, 0);

  // 0..3 bit - lba 27..24
  i := ((ASektorNo shr 24) and $0F);
  // 4. bit - aygýt seçimi
  i := i or (FKanal shl 4);
  // 7. bit - 1, 6. bit - LBA ise 1, 5. bit = 1
  i := i or %11100000;
  PortYaz1(FAnaPort + ATAYAZMAC_AYGITSECIM, i);

  // yazýlacak sektör sayýsý
  PortYaz1(FAnaPort + ATAYAZMAC_SEKTORSAYISI, 1);

  // yazýlacak sektör numarasý (28 bit)
  // LBA 07..00
  PortYaz1(FAnaPort + ATAYAZMAC_SEKTOR_A8, (ASektorNo and $FF));
  // LBA 15..08
  PortYaz1(FAnaPort + ATAYAZMAC_SEKTOR_O8, ((ASektorNo shr 8) and $FF));
  // LBA 23..16
  PortYaz1(FAnaPort + ATAYAZMAC_SEKTOR_U8, ((ASektorNo shr 16) and $FF));

  // sektör yaz komutu gönder
  PortYaz1(FAnaPort + ATAYAZMAC_KOMUT, ATAKOMUT_SEKTORYAZ);

  PortNo := FAnaPort;

  // yazma iþlevini gerçekleþtir
  TekrarSayisi := 5;
  repeat

    if(AygitVeriIcinHazirMi) then
    begin

      asm
        cli
        cld
        mov esi,ABellekAdresi
        mov ecx,512 / 4
        mov dx,PortNo
        rep outsd
      end;

      Result := HATA_YOK;
    end
    else
    begin

      Dec(TekrarSayisi);
      Result := HATA_AYGITMESGUL;
    end;

  until (Result = HATA_YOK) or (TekrarSayisi = 0);
end;

{==============================================================================
  ide aygýtýnýn veri okumaya / yazmaya hazýr olup olmadýðýný kontrol eder
 ==============================================================================}
function TIDEAygiti.AygitVeriIcinHazirMi: Boolean;
var
  i: TSayi4;
  j: TSayi1;
begin

  Result := True;

  for i := 1 to 100 do
  begin

    j := PortAl1(FAnaPort + ATAYAZMAC_DURUM);

    if((j and ATAYAZMAC_DURUM_VERIHAZIR) = 0) then Continue;

    if((j and ATAYAZMAC_DURUM_HATA) = 0) then Exit;
  end;

  Result := False;
end;

{==============================================================================
  4 milisaniye bekleme iþlevi
 ==============================================================================}
procedure TIDEAygiti.Bekle;
begin

  PortAl1(FAnaPort + ATAYAZMAC_ALTDURUM);
  PortAl1(FAnaPort + ATAYAZMAC_ALTDURUM);
  PortAl1(FAnaPort + ATAYAZMAC_ALTDURUM);
  PortAl1(FAnaPort + ATAYAZMAC_ALTDURUM);
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
    if(IDEAygitiMevcutMu(IDEKayitListesi[i].AnaPort, IDEKayitListesi[i].Kanal)) then
    begin

      // ide aygýt bilgilerini al
      IDEAygitBilgisiAl(IDEKayitListesi[i].AnaPort, IDEKayitListesi[i].Kanal, @Bellek);

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
        FD.FKanal := IDEKayitListesi[i].Kanal;

        TIDEAygiti(FD).FOzellikler := 0;

        FD.FOku := @TIDEAygiti(FD).Oku;
        FD.FYaz := @TIDEAygiti(FD).Yaz;

        FD.FSilindirSayisi := Bellek.SilindirSayisi;
        FD.FKafaSayisi := Bellek.KafaSayisi;
        FD.FIzBasinaSektorSayisi := Bellek.IzBasinaSektor;
        FD.FToplamSektorSayisi := Bellek.SilindirSayisi * Bellek.KafaSayisi * Bellek.IzBasinaSektor;
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

  i := (AKanal shl 4) or $A0;
  PortYaz1(AAnaPort + ATAYAZMAC_AYGITSECIM, i);

  // aygýt meþgul mü ?
  if(IDEAygitiMesgulMu(AAnaPort)) then Exit;

  i := (AKanal shl 4) or $A0;
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

  i := (AKanal shl 4) or $A0;
  PortYaz1(AAnaPort + ATAYAZMAC_AYGITSECIM, i);

  if(IDEAygitiMesgulMu(AAnaPort)) then Exit;

  PortYaz1(AAnaPort + $206, 2);
  PortYaz1(AAnaPort + ATAYAZMAC_KOMUT, $EC);

  if(IDEAygitiMesgulMu(AAnaPort)) then Exit;

  PortNo := AAnaPort;

  asm
    pushad
    mov edi,AAygitBilgisi
    mov ecx,256
    mov edx,PortNo
    cld
    rep insw
    popad
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

  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'IRQ14 tetiklendi', []);
end;

{==============================================================================
  ikinci ide disk irq rutini
 ==============================================================================}
procedure IRQ15KesmeIslevi;
begin

  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'IRQ15 tetiklendi', []);
end;

end.
