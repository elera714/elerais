{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: src_ide.pas
  Dosya Ýþlevi: ide aygýt sürücüsü

  Güncelleme Tarihi: 20/01/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
//{$DEFINE IDE_BILGI}
unit src_ide;

interface

uses paylasim, port;

const
  ATAYAZMAC_VERI                    = $00;    // okunabilir / yazýlabilir
  ATAYAZMAC_HATA                    = $01;    // okunabilir
  ATAYAZMAC_SEKTORSAYISI            = $02;    // okunabilir / yazýlabilir
  ATAYAZMAC_SEKTORNO                = $03;    // okunabilir / yazýlabilir
  ATAYAZMAC_SILINDIR_B01            = $04;    // okunabilir / yazýlabilir
  ATAYAZMAC_SILINDIR_B23            = $05;    // okunabilir / yazýlabilir
  ATAYAZMAC_AYGITSECIM              = $06;    // okunabilir / yazýlabilir
  ATAYAZMAC_DURUM                   = $07;    // okunabilir
  ATAYAZMAC_KOMUT                   = $07;    // yazýlabilir
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
    Diger2: array[81..255] of Word;         // diðer veri alanlarý
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
    Diger: array[81..255] of Word;          // diðer data alanlarý
  end;

var
  SektorOkuYazKilit: TSayi4 = 0;

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

uses aygityonetimi, irq, sistemmesaj, donusum, gorev, fdepolama;

var
  IDEDiskListesi: array[0..3] of TIDEDisk = (
    (AnaPort: $1F0; KontrolPort: $3F6; Kanal: ATA_KANAL0),
    (AnaPort: $1F0; KontrolPort: $3F6; Kanal: ATA_KANAL1),
    (AnaPort: $170; KontrolPort: $376; Kanal: ATA_KANAL0),
    (AnaPort: $170; KontrolPort: $376; Kanal: ATA_KANAL1));

{==============================================================================
  sistemde mevcut ide disk sürücülerini yükler
 ==============================================================================}
procedure Yukle;
var
  FD: PFDNesne;
  Bellek: TATA4;
  i: TSayi4;
begin

  {$IFDEF IDE_BILGI}
  SISTEM_MESAJ(RENK_MOR, '+ IDE disk aygýtlarý aranýyor...', []);
  {$ENDIF}

  // birinci ve ikinci disk sürücüsü IRQ istek kanalýný etkinleþtir
  IRQIsleviAta(14, @IRQ14Islevi);
  IRQIsleviAta(15, @IRQ15Islevi);

  // tüm ide aygýtlarýný tara
  for i := 0 to 3 do
  begin

    // ide aygýtý mevcut mu ?
    if(SistemdekiIDEAygitlariniBul(@IDEDiskListesi[i])) then
    begin

      // ide disk bilgilerini al
      IDEAygitBilgisiniAl(@IDEDiskListesi[i], @Bellek);

      {$IFDEF IDE_BILGI}
      SISTEM_MESAJ(RENK_LACIVERT, '  + IDE Aygýt: ' + IntToStr(i + 1), []);
      SISTEM_MESAJ(RENK_LACIVERT, '    + IDE Port No: ' + hexStr(IDEDiskListesi[i].PortNo, 3), []);
      SISTEM_MESAJ(RENK_LACIVERT, '    + IDE Kafa Sayýsý: ' + IntToStr(_Bellek.KafaSayisi), []);
      SISTEM_MESAJ(RENK_LACIVERT, '    + IDE Silindir Sayýsý: ' + IntToStr(_Bellek.SilindirSayisi), []);
      SISTEM_MESAJ(RENK_LACIVERT, '    + IDE Ýz Baþýna Sektör: ' + IntToStr(_Bellek.IzBasinaSektor), []);
      SISTEM_MESAJ(RENK_LACIVERT, '    + IDE Toplam Sektor: ' + IntToStr(_Bellek.ToplamSektor), []);
      SISTEM_MESAJ(RENK_LACIVERT, '    + IDE Sektor Olarak Kapasite: ' + IntToStr(_Bellek.SektorOlarakKapasite), []);
      {$ENDIF}

      // mevcut ise fiziksel sürücü yapýsýný oluþtur
      FD := FizikselDepolama0.FDAygitiOlustur(SURUCUTIP_DISK);
      if(FD <> nil) then
      begin

        FD^.Ozellikler := 0;
        FD^.SektorOku := @SektorOku28;
        FD^.SektorYaz := @SektorYaz28;
        FD^.Aygit.AnaPort := IDEDiskListesi[i].AnaPort;
        FD^.Aygit.Kanal := IDEDiskListesi[i].Kanal;

        FD^.FD3.SilindirSayisi := Bellek.SilindirSayisi;
        FD^.FD3.KafaSayisi := Bellek.KafaSayisi;
        FD^.FD3.IzBasinaSektorSayisi := Bellek.IzBasinaSektor;
        FD^.FD3.ToplamSektorSayisi := Bellek.SilindirSayisi * Bellek.KafaSayisi * Bellek.IzBasinaSektor;
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
  sistemde mevcut ide aygýtýný denetler
 ==============================================================================}
function SistemdekiIDEAygitlariniBul(AIDEDisk: PIDEDisk): Boolean;
var
  i: TSayi1;
begin

  // öndeðer geri dönüþ deðeri
  Result := False;

  i := (AIDEDisk^.Kanal shl 4) or $A0;
  PortYaz1(AIDEDisk^.AnaPort + ATAYAZMAC_AYGITSECIM, i);

  // aygýt meþgul mü ?
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
  ide aygýtýyla ilgili tanýmlayýcý bilgileri alýr
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
  ide aygýtýnýn meþgul olup olmadýðýný denetler
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
  ide aygýtý bilgi transferi için hazýr mý ?
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
  bekleme iþlevi
 ==============================================================================}
procedure Bekle(AIDEDisk: PIDEDisk);
begin

  PortAl1(AIDEDisk^.AnaPort + ATAYAZMAC_ALTDURUM);
  PortAl1(AIDEDisk^.AnaPort + ATAYAZMAC_ALTDURUM);
  PortAl1(AIDEDisk^.AnaPort + ATAYAZMAC_ALTDURUM);
  PortAl1(AIDEDisk^.AnaPort + ATAYAZMAC_ALTDURUM);
end;

{==============================================================================
  LBA modunda 28 bitlik <>tör okuma iþlemi yapar
 ==============================================================================}
function SektorOku28(AFizikselSurucu: Isaretci; AIlkSektor, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4;
var
  FD: PFDNesne;
  BellekAdresi: Isaretci;
  PortNo: TSayi2;
  i: TSayi1;
  SektorIS: TISayi4;    // sektör iþlem sonucu
  OkunacakSektorSayisi,
  TekrarSayisi: TSayi4;
begin

  BellekAdresi := ABellek;
  OkunacakSektorSayisi := ASektorSayisi;

  //SISTEM_MESAJ(RENK_SIYAH, 'AIlkSektor: %d', [AIlkSektor]);
  //SISTEM_MESAJ(RENK_SIYAH, 'ASektorSayisi: %d', [ASektorSayisi]);
  //SISTEM_MESAJ(RENK_SIYAH, 'ABellek: %d', [TSayi4(ABellek)]);

  while KritikBolgeyeGir(SektorOkuYazKilit) = False do;

  // sürücü bilgisine konumlan
  FD := AFizikselSurucu;

  // aygýt meþgulse çýk
  if(IDEAygitiMesgulMu(@FD^.Aygit)) then
  begin

    KritikBolgedenCik(SektorOkuYazKilit);
    Exit(HATA_AYGITMESGUL);
  end;

  //okunacak sektör sayýsý
  PortYaz1(FD^.Aygit.AnaPort + ATAYAZMAC_SEKTORSAYISI, OkunacakSektorSayisi);

  //okunacak sektör numarasý (28 bit)
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

  // sektör oku komutu gönder
  PortYaz1(FD^.Aygit.AnaPort + ATAYAZMAC_KOMUT, ATAKOMUT_SEKTOROKU);

  Bekle(@FD^.Aygit);

  SektorIS := HATA_YOK;

  PortNo := FD^.Aygit.AnaPort;

  // okuma iþlevini gerçekleþtir
  TekrarSayisi := 0;
  repeat

    if(IDEAygitiMesgulMu(@FD^.Aygit) = False) then
    begin

      if(IDEAygitiHazirMi(@FD^.Aygit)) then
      begin

        asm
          pushad
          pushfd
          cli
          cld
          mov edi,BellekAdresi
          mov ecx,512 / 2
          mov dx,PortNo
          rep insw
          popfd
          popad
        end;

        Dec(OkunacakSektorSayisi);
        BellekAdresi += 512;
      end
      else
      begin

        Inc(TekrarSayisi);
        SektorIS := HATA_AYGITHAZIRDEGIL;
      end;
    end
    else
    begin

      Inc(TekrarSayisi);
      SektorIS := HATA_AYGITMESGUL;
    end;

  until (OkunacakSektorSayisi = 0) or (TekrarSayisi = 3);

  KritikBolgedenCik(SektorOkuYazKilit);

  Result := SektorIS;
end;

{==============================================================================
  LBA modunda 28 bitlik sektör yazma iþlemi yapar
 ==============================================================================}
function SektorYaz28(AFizikselDepolama: Isaretci; AIlkSektor, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4;
var
  FD: PFDNesne;
  BellekAdresi: Isaretci;
  PortNo: TSayi2;
  i: TSayi1;
  SektorIS: TISayi4;    // sektör iþlem sonucu
  YazilacakSektorSayisi,
  TekrarSayisi: TSayi4;
begin

  BellekAdresi := ABellek;
  YazilacakSektorSayisi := ASektorSayisi;

  while KritikBolgeyeGir(SektorOkuYazKilit) = False do;

  // sürücü bilgisine konumlan
  FD := PFDNesne(AFizikselDepolama);

  // aygýt meþgulse çýk
  if(IDEAygitiMesgulMu(@FD^.Aygit)) then
  begin

    KritikBolgedenCik(SektorOkuYazKilit);
    Exit(HATA_AYGITMESGUL);
  end;

  // yazýlacak sektör sayýsý
  PortYaz1(FD^.Aygit.AnaPort + ATAYAZMAC_SEKTORSAYISI, YazilacakSektorSayisi);

  //okunacak sektör numarasý (28 bit)
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

  // sektör oku komutu gönder
  PortYaz1(FD^.Aygit.AnaPort + ATAYAZMAC_KOMUT, ATAKOMUT_SEKTORYAZ);

  Bekle(@FD^.Aygit);

  SektorIS := HATA_YOK;

  PortNo := FD^.Aygit.AnaPort;

  // okuma iþlevini gerçekleþtir
  TekrarSayisi := 0;
  repeat

    if(IDEAygitiMesgulMu(@FD^.Aygit) = False) then
    begin

      if(IDEAygitiHazirMi(@FD^.Aygit)) then
      begin

        asm
          pushad
          pushfd
          cli
          cld
          mov esi,BellekAdresi
          mov ecx,512 / 2
          mov dx,PortNo
          rep outsw
          popfd
          popad
        end;

        Dec(YazilacakSektorSayisi);
        BellekAdresi += 512;
      end
      else
      begin

        Inc(TekrarSayisi);
        SektorIS := HATA_AYGITHAZIRDEGIL;
      end;
    end
    else
    begin

      Inc(TekrarSayisi);
      SektorIS := HATA_AYGITMESGUL;
    end;

  until (YazilacakSektorSayisi = 0) or (TekrarSayisi = 3);

  KritikBolgedenCik(SektorOkuYazKilit);

  Result := SektorIS;
end;

end.
