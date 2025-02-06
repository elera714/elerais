{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: src_ide.pas
  Dosya ��levi: ide ayg�t s�r�c�s�

  G�ncelleme Tarihi: 30/01/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
//{$DEFINE IDE_BILGI}
unit src_ide;

interface

uses paylasim, port;

const
  ATAYAZMAC_VERI                    = $00;    // okunabilir / yaz�labilir
  ATAYAZMAC_HATA                    = $01;    // okunabilir
  ATAYAZMAC_SEKTORSAYISI            = $02;    // okunabilir / yaz�labilir
  ATAYAZMAC_SEKTORNO                = $03;    // okunabilir / yaz�labilir
  ATAYAZMAC_SILINDIR_B01            = $04;    // okunabilir / yaz�labilir
  ATAYAZMAC_SILINDIR_B23            = $05;    // okunabilir / yaz�labilir
  ATAYAZMAC_AYGITSECIM              = $06;    // okunabilir / yaz�labilir
  ATAYAZMAC_DURUM                   = $07;    // okunabilir
  ATAYAZMAC_KOMUT                   = $07;    // yaz�labilir
  ATAYAZMAC_ALTDURUM                = $0C;

  ATAKOMUT_SEKTOROKU                = $20;
  ATAKOMUT_SEKTORYAZ                = $30;

  ATAYAZMAC_DURUM_MESGUL            = $80;  // drive busy
  ATAYAZMAC_DURUM_AYGITHAZIR        = $40;  // drive ready
  ATAYAZMAC_DURUM_YAZMAHATASI       = $20;  // drive write fault
  ATAYAZMAC_DURUM_KOMULANMABASARILI = $10;  // drive seek complete
  ATAYAZMAC_DURUM_VERIHAZIR         = $08;  // drive request (data ready)
  ATAYAZMAC_DURUM_DUZELTILMISVERI   = $04;  // corrected data
  ATAYAZMAC_DURUM_SIRANO            = $02;  // index bit
  ATAYAZMAC_DURUM_HATA              = $01;  // error

  ATA_KANAL0                        = 0;
  ATA_KANAL1                        = 1;

type
  PTATA4 = ^TATA4;
  TATA4 = packed record
    Ayar: Word;                             // 0
    SilindirSayisi: Word;                   // 1
    Ayrildi1: Word;                         // 2
    KafaSayisi: Word;                       // 3
    Eskidi1: array[0..1] of Word;           // 4-5
    IzBasinaSektor: Word;                   // 6
    Eskidi2: array[0..2] of Word;           // 7-9
    SeriNo: array[0..19] of Char;           // 10-19
    Eskidi3: array[0..1] of Word;           // 20-21
    Eskidi4: Word;                          // 22
    FirmaYazilimSurum: array[0..7] of Char; // 23-26
    ModelNo: array[0..39] of Char;          // 27-46
    IslemAzamiSektorSayisi: Word;           // 47
    Ayrildi2: Word;                         // 48
    Yetenek1: Word;                         // 49
    Yetenek2: Word;                         // 50
    PIOModu: Word;                          // 51
    Eskidi5: Word;                          // 52
    AlanDogrulugu1: Word;                   // 53
    SilindirSayisi2: Word;                  // 54
    KafaSayisi2: Word;                      // 55
    IzBasinaSektor2: Word;                  // 56
    SektorOlarakKapasite: LongWord;         // 57-58
    CokluSektor: Word;                      // 59
    ToplamSektor: LongWord;                 // 60-61
    Diger1: array[0..17] of Word;           // 62-79
    SurumNo: Word;                          // 80
    Diger2: array[81..255] of Word;         // di�er veri alanlar�
  end;

type
  PTATA6 = ^TATA6;
  TATA6 = packed record
    Ayar: Word;                             // 0
    Eskidi1: Word;                          // 1
    OzelAyar: Word;                         // 2
    Eskidi2: Word;                          // 3
    Eskidi3: array[0..1] of Word;           // 4-5
    Eskidi4: Word;                          // 6
    Ayrildi1: array[0..1] of Word;          // 7-8
    Eskidi5: Word;                          // 9
    SeriNo: array[0..19] of Char;           // 10-19
    Eskidi6: array[0..1] of Word;           // 20-21
    Eskidi7: Word;                          // 22
    FirmaYazilimSurum: array[0..7] of Char; // 23-26
    ModelNo: array[0..39] of Char;          // 27-46
    IslemAzamiSektorSayisi: Word;           // 47
    Ayrildi2: Word;                         // 48
    Yetenek1: Word;                         // 49
    Yetenek2: Word;                         // 50
    Eskidi8: array[0..1] of Word;           // 51-52
    AlanDogrulugu1: Word;                   // 53
    Eskidi9: array[0..4] of Word;           // 54-58
    AlanDogrulugu2: Word;                   // 59
    ToplamSektor: LongWord;                 // 60-61
    Eskidi10: array[0..17] of Word;         // 62-79
    SurumNo: Word;                          // 80
    Diger: array[81..255] of Word;          // di�er data alanlar�
  end;

procedure Yukle;
procedure IRQ14KesmeIslevi;
procedure IRQ15KesmeIslevi;
function SistemdekiIDEAygitlariniBul(AIDEDisk: PIDEDisk): Boolean;
function IDEAygitBilgisiniAl(AIDEDisk: PIDEDisk; AAygitBilgisi: Isaretci): Boolean;
function IDEAygitiMesgulMu(AIDEDisk: PIDEDisk): Boolean;
function IDEAygitiHazirMi(AIDEDisk: PIDEDisk): Boolean;
procedure Bekle(AIDEDisk: PIDEDisk);
function SektorOku28(AFizikselSurucu: Isaretci; AIlkSektor, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4;
function SektorYaz28(AFizikselDepolama: Isaretci; AIlkSektor, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4;

implementation

uses aygityonetimi, irq, sistemmesaj, donusum;

var
  IDEDiskListesi: array[0..3] of TIDEDisk = (
    (AnaPort: $1F0; KontrolPort: $3F6; Kanal: ATA_KANAL0),
    (AnaPort: $1F0; KontrolPort: $3F6; Kanal: ATA_KANAL1),
    (AnaPort: $170; KontrolPort: $376; Kanal: ATA_KANAL0),
    (AnaPort: $170; KontrolPort: $376; Kanal: ATA_KANAL1));

{==============================================================================
  sistemde mevcut ide disk s�r�c�lerini y�kler
 ==============================================================================}
procedure Yukle;
var
  FD: PFizikselDepolama;
  Bellek: TATA4;
  i: TSayi4;
begin

  {$IFDEF IDE_BILGI}
  SISTEM_MESAJ(RENK_MOR, '+ IDE disk ayg�tlar� aran�yor...', []);
  {$ENDIF}

  // birinci ve ikinci disk s�r�c�s� IRQ istek kanal�n� etkinle�tir
  IRQIsleviAta(14, @IRQ14Islevi);
  IRQIsleviAta(15, @IRQ15Islevi);

  // t�m ide ayg�tlar�n� tara
  for i := 0 to 3 do
  begin

    // ide ayg�t� mevcut mu ?
    if(SistemdekiIDEAygitlariniBul(@IDEDiskListesi[i])) then
    begin

      // ide disk bilgilerini al
      IDEAygitBilgisiniAl(@IDEDiskListesi[i], @Bellek);

      {$IFDEF IDE_BILGI}
      SISTEM_MESAJ(RENK_LACIVERT, '  + IDE Ayg�t: ' + IntToStr(i + 1), []);
      SISTEM_MESAJ(RENK_LACIVERT, '    + IDE Port No: ' + hexStr(IDEDiskListesi[i].PortNo, 3), []);
      SISTEM_MESAJ(RENK_LACIVERT, '    + IDE Kafa Say�s�: ' + IntToStr(_Bellek.KafaSayisi), []);
      SISTEM_MESAJ(RENK_LACIVERT, '    + IDE Silindir Say�s�: ' + IntToStr(_Bellek.SilindirSayisi), []);
      SISTEM_MESAJ(RENK_LACIVERT, '    + IDE �z Ba��na Sekt�r: ' + IntToStr(_Bellek.IzBasinaSektor), []);
      SISTEM_MESAJ(RENK_LACIVERT, '    + IDE Toplam Sektor: ' + IntToStr(_Bellek.ToplamSektor), []);
      SISTEM_MESAJ(RENK_LACIVERT, '    + IDE Sektor Olarak Kapasite: ' + IntToStr(_Bellek.SektorOlarakKapasite), []);
      {$ENDIF}

      // mevcut ise fiziksel s�r�c� yap�s�n� olu�tur
      FD := FizikselDepolamaAygitiOlustur(SURUCUTIP_DISK);
      if(FD <> nil) then
      begin

        FD^.Ozellikler := 0;
        FD^.SektorOku := @SektorOku28;
        FD^.SektorYaz := @SektorYaz28;
        FD^.Aygit.AnaPort:= IDEDiskListesi[i].AnaPort;
        FD^.Aygit.Kanal := IDEDiskListesi[i].Kanal;

        FD^.FD3.SilindirSayisi := Bellek.SilindirSayisi;
        FD^.FD3.KafaSayisi := Bellek.KafaSayisi;
        FD^.FD3.IzBasinaSektorSayisi := Bellek.IzBasinaSektor;
        FD^.FD3.ToplamSektorSayisi := Bellek.SilindirSayisi *
          Bellek.KafaSayisi * Bellek.IzBasinaSektor;
      end;
    end;
  end;
end;

{==============================================================================
  birinci disk IRQ rutini
 ==============================================================================}
procedure IRQ14KesmeIslevi;
begin

  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'IRQ14 tetiklendi', []);
end;

{==============================================================================
  ikinci disk IRQ rutini
 ==============================================================================}
procedure IRQ15KesmeIslevi;
begin

  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'IRQ15 tetiklendi', []);
end;

{==============================================================================
  sistemde mevcut ide ayg�t�n� denetler
 ==============================================================================}
function SistemdekiIDEAygitlariniBul(AIDEDisk: PIDEDisk): Boolean;
var
  i: TSayi1;
begin

  // �nde�er geri d�n�� de�eri
  Result := False;

  i := (AIDEDisk^.Kanal shl 4) or $A0;
  PortYaz1(AIDEDisk^.AnaPort + ATAYAZMAC_AYGITSECIM, i);

  // ayg�t me�gul m� ?
  if(IDEAygitiMesgulMu(AIDEDisk)) then Exit;

  i := (AIDEDisk^.Kanal shl 4) or $A0;
  PortYaz1(AIDEDisk^.AnaPort + ATAYAZMAC_AYGITSECIM, i);

  if(PortAl1(AIDEDisk^.AnaPort + ATAYAZMAC_AYGITSECIM) <> i) then Exit;

  PortYaz1(AIDEDisk^.AnaPort + ATAYAZMAC_SILINDIR_B01, $AA);
  if(PortAl1(AIDEDisk^.AnaPort + ATAYAZMAC_SILINDIR_B01) <> $AA) then Exit;

  PortYaz1(AIDEDisk^.AnaPort + ATAYAZMAC_SILINDIR_B01, $55);
  if(PortAl1(AIDEDisk^.AnaPort + ATAYAZMAC_SILINDIR_B01) <> $55) then Exit;

  i := PortAl1(AIDEDisk^.AnaPort + ATAYAZMAC_DURUM);
  if((i and ATAYAZMAC_DURUM_AYGITHAZIR) = 0) then Exit;

  Result := True;
end;

{==============================================================================
  ide ayg�t�yla ilgili tan�mlay�c� bilgileri al�r
 ==============================================================================}
function IDEAygitBilgisiniAl(AIDEDisk: PIDEDisk; AAygitBilgisi: Isaretci): Boolean;
var
  PortNo: TSayi2;
  i: TSayi1;
begin

  Result := False;

  i := (AIDEDisk^.Kanal shl 4) or $A0;
  PortYaz1(AIDEDisk^.AnaPort + ATAYAZMAC_AYGITSECIM, i);

  if(IDEAygitiMesgulMu(AIDEDisk)) then Exit;

  PortYaz1(AIDEDisk^.AnaPort + $206, 2);
  PortYaz1(AIDEDisk^.AnaPort + ATAYAZMAC_KOMUT, $EC);

  if(IDEAygitiMesgulMu(AIDEDisk)) then Exit;

  PortNo := AIDEDisk^.AnaPort;

  asm
    pushad
    mov edi,AAygitBilgisi
    mov ecx,256
    mov dx,PortNo
    cld
    rep insw
    popad
  end;

  Result := True;
end;

{==============================================================================
  ide ayg�t�n�n me�gul olup olmad���n� denetler
 ==============================================================================}
function IDEAygitiMesgulMu(AIDEDisk: PIDEDisk): Boolean;
var
  i: TSayi4;
  j: TSayi1;
begin

  Result := True;

  for i := 0 to 999 do
  begin

    j := PortAl1(AIDEDisk^.AnaPort + ATAYAZMAC_DURUM);
    if((j and ATAYAZMAC_DURUM_MESGUL) = 0) then Exit(False);
  end;
end;

{==============================================================================
  ide ayg�t� bilgi transferi i�in haz�r m� ?
 ==============================================================================}
function IDEAygitiHazirMi(AIDEDisk: PIDEDisk): Boolean;
var
  i: TSayi4;
  j: TSayi1;
begin

  Result := False;

  for i := 0 to 999 do
  begin

    j := PortAl1(AIDEDisk^.AnaPort + ATAYAZMAC_DURUM);
    if((j and ATAYAZMAC_DURUM_AYGITHAZIR) = ATAYAZMAC_DURUM_AYGITHAZIR) then Exit(True);
  end;
end;

{==============================================================================
  bekleme i�levi
 ==============================================================================}
procedure Bekle(AIDEDisk: PIDEDisk);
begin

  PortAl1(AIDEDisk^.AnaPort + ATAYAZMAC_ALTDURUM);
  PortAl1(AIDEDisk^.AnaPort + ATAYAZMAC_ALTDURUM);
  PortAl1(AIDEDisk^.AnaPort + ATAYAZMAC_ALTDURUM);
  PortAl1(AIDEDisk^.AnaPort + ATAYAZMAC_ALTDURUM);
end;

var
  ReadSector28GorevNo: LongWord = 0;

{==============================================================================
  LBA modunda 28 bitlik sekt�r okuma i�lemi yapar
 ==============================================================================}
function SektorOku28(AFizikselSurucu: Isaretci; AIlkSektor, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4;
var
  FD: PFizikselDepolama;
  PortNo: TSayi2;
  i: TSayi1;
begin

  //SISTEM_MESAJ(RENK_SIYAH, 'AIlkSektor: %d', [AIlkSektor]);
  //SISTEM_MESAJ(RENK_SIYAH, 'ASektorSayisi: %d', [ASektorSayisi]);
  //SISTEM_MESAJ(RENK_SIYAH, 'ABellek: %d', [TSayi4(ABellek)]);

  if(ReadSector28GorevNo <> 0) then
  begin

    while ReadSector28GorevNo <> 0 do;
  end;

  ReadSector28GorevNo := CalisanGorev;

  // s�r�c� bilgisine konumlan
  FD := AFizikselSurucu;

  // ayg�t me�gulse ��k
  if(IDEAygitiMesgulMu(@FD^.Aygit)) then
  begin

    ReadSector28GorevNo := 0;
    Exit(1);
  end;

  //SISTEM_MESAJ(RENK_SIYAH, 'Tamam1', []);

//  asm cli end;

  //okunacak sekt�r say�s�
  PortYaz1(FD^.Aygit.AnaPort + ATAYAZMAC_SEKTORSAYISI, ASektorSayisi);

  //okunacak sekt�r numaras� (28 bit)
  // LBA 07..00
  PortYaz1(FD^.Aygit.AnaPort + ATAYAZMAC_SEKTORNO, (AIlkSektor and $FF));
  // LBA 15..08
  PortYaz1(FD^.Aygit.AnaPort + ATAYAZMAC_SILINDIR_B01, ((AIlkSektor shr 8) and $FF));
  // LBA 23..16
  PortYaz1(FD^.Aygit.AnaPort + ATAYAZMAC_SILINDIR_B23, ((AIlkSektor shr 16) and $FF));
  // lba 27..24
  i := ((AIlkSektor shr 24) and $0F);
  if(FD^.Aygit.Kanal = ATA_KANAL1) then
    i := i or $F0
  else i := i or $E0;
  i := i or (FD^.Aygit.Kanal shl 4);
  PortYaz1(FD^.Aygit.AnaPort + ATAYAZMAC_AYGITSECIM, i);

  // sekt�r oku komutu g�nder
  PortYaz1(FD^.Aygit.AnaPort + ATAYAZMAC_KOMUT, ATAKOMUT_SEKTOROKU);

  Bekle(@FD^.Aygit);

//  asm sti end;

  // okuma i�levini ger�ekle�tir
  repeat

    PortNo := FD^.Aygit.AnaPort;

    if(IDEAygitiMesgulMu(@FD^.Aygit) = False) then
    begin

      if(IDEAygitiHazirMi(@FD^.Aygit)) then
      begin

        asm
          cli
          pushad
          mov edi,ABellek
          mov ecx,256
          mov dx,PortNo
          cld
          rep insw
          popad
          sti
        end;

        Dec(ASektorSayisi);
        ABellek += 512;
        Result := 0;
      end else Result := 1;
    end;

  until (ASektorSayisi = 0) or (Result = 1);

  ReadSector28GorevNo := 0;
end;

{==============================================================================
  LBA modunda 28 bitlik sekt�r yazma i�lemi yapar
 ==============================================================================}
function SektorYaz28(AFizikselDepolama: Isaretci; AIlkSektor, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4;
var
  FD: PFizikselDepolama;
  PortNo: TSayi2;
  i: TSayi1;
begin

  if(ReadSector28GorevNo <> 0) then
  begin

    while ReadSector28GorevNo <> 0 do;
  end;

  ReadSector28GorevNo := CalisanGorev;

  // s�r�c� bilgisine konumlan
  FD := PFizikselDepolama(AFizikselDepolama);

  // ayg�t me�gulse ��k
  if(IDEAygitiMesgulMu(@FD^.Aygit)) then
  begin

    ReadSector28GorevNo := 0;
    Exit(1);
  end;

//  asm cli end;

  //okunacak sekt�r say�s�
  PortYaz1(FD^.Aygit.AnaPort + ATAYAZMAC_SEKTORSAYISI, ASektorSayisi);

  //okunacak sekt�r numaras� (28 bit)
  // LBA 07..00
  PortYaz1(FD^.Aygit.AnaPort + ATAYAZMAC_SEKTORNO, (AIlkSektor and $FF));
  // LBA 15..08
  PortYaz1(FD^.Aygit.AnaPort + ATAYAZMAC_SILINDIR_B01, ((AIlkSektor shr 8) and $FF));
  // LBA 23..16
  PortYaz1(FD^.Aygit.AnaPort + ATAYAZMAC_SILINDIR_B23, ((AIlkSektor shr 16) and $FF));
  // lba 27..24
  i := ((AIlkSektor shr 24) and $0F);
  if(FD^.Aygit.Kanal = ATA_KANAL1) then
    i := i or $F0
  else i := i or $E0;
  i := i or (FD^.Aygit.Kanal shl 4);
  PortYaz1(FD^.Aygit.AnaPort + ATAYAZMAC_AYGITSECIM, i);

  // sekt�r oku komutu g�nder
  PortYaz1(FD^.Aygit.AnaPort + ATAYAZMAC_KOMUT, ATAKOMUT_SEKTORYAZ);

  Bekle(@FD^.Aygit);

//  asm sti end;

  // okuma i�levini ger�ekle�tir
  repeat

    PortNo := FD^.Aygit.AnaPort;

    if(IDEAygitiMesgulMu(@FD^.Aygit) = False) then
    begin

      if(IDEAygitiHazirMi(@FD^.Aygit)) then
      begin

        asm
          cli
          pushad
          mov esi,ABellek
          mov ecx,256
          mov dx,PortNo
          cld
          rep outsw
          popad
          sti
        end;

        Dec(ASektorSayisi);
        ABellek += 512;
        Result := 0;
      end else Result := 1;
    end;

  until (ASektorSayisi = 0) or (Result = 1);

  ReadSector28GorevNo := 0;
end;

end.
