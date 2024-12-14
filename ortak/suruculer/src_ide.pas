{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: src_ide.pas
  Dosya Ýþlevi: ide aygýt sürücüsü

  Güncelleme Tarihi: 09/11/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
//{$DEFINE IDE_BILGI}
unit src_ide;
 
interface

uses paylasim, port;

const
  ATAYAZMAC_VERI                    = 0;    // okunabilir / yazýlabilir
  ATAYAZMAC_HATA                    = 1;    // okunabilir
  ATAYAZMAC_SEKTORSAYISI            = 2;    // okunabilir / yazýlabilir
  ATAYAZMAC_SEKTORNO                = 3;    // okunabilir / yazýlabilir
  ATAYAZMAC_SILINDIR_B01            = 4;    // okunabilir / yazýlabilir
  ATAYAZMAC_SILINDIR_B23            = 5;    // okunabilir / yazýlabilir
  ATAYAZMAC_SURUCUKAFA              = 6;    // okunabilir / yazýlabilir
  ATAYAZMAC_DURUM                   = 7;    // okunabilir
  ATAYAZMAC_KOMUT                   = 7;    // yazýlabilir

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
    Ayar: TSayi2;                           // 0
    SilindirSayisi: TSayi2;                 // 1
    Ayrildi1: TSayi2;                       // 2
    KafaSayisi: TSayi2;                     // 3
    Eskidi1: array[0..1] of TSayi2;         // 4-5
    IzBasinaSektor: TSayi2;                 // 6
    Eskidi2: array[0..2] of TSayi2;         // 7-9
    SeriNo: array[0..19] of Char;           // 10-19
    Eskidi3: array[0..1] of TSayi2;         // 20-21
    Eskidi4: TSayi2;                        // 22
    FirmaYazilimSurum: array[0..7] of Char; // 23-26
    ModelNo: array[0..39] of Char;          // 27-46
    IslemAzamiSektorSayisi: TSayi2;         // 47
    Ayrildi2: TSayi2;                       // 48
    Yetenek1: TSayi2;                       // 49
    Yetenek2: TSayi2;                       // 50
    PIOModu: TSayi2;                        // 51
    Eskidi5: TSayi2;                        // 52
    AlanDogrulugu1: TSayi2;                 // 53
    SilindirSayisi2: TSayi2;                // 54
    KafaSayisi2: TSayi2;                    // 55
    IzBasinaSektor2: TSayi2;                // 56
    SektorOlarakKapasite: TSayi4;           // 57-58
    CokluSektor: TSayi2;                    // 59
    ToplamSektor: TSayi4;                   // 60-61
    Diger1: array[0..17] of TSayi2;         // 62-79
    SurumNo: TSayi2;                        // 80
    Diger2: array[81..255] of TSayi2;       // diðer veri alanlarý
  end;

type
  PTATA6 = ^TATA6;
  TATA6 = packed record
    Ayar: TSayi2;                           // 0
    Eskidi1: TSayi2;                        // 1
    OzelAyar: TSayi2;                       // 2
    Eskidi2: TSayi2;                        // 3
    Eskidi3: array[0..1] of TSayi2;         // 4-5
    Eskidi4: TSayi2;                        // 6
    Ayrildi1: array[0..1] of TSayi2;        // 7-8
    Eskidi5: TSayi2;                        // 9
    SeriNo: array[0..19] of Char;           // 10-19
    Eskidi6: array[0..1] of TSayi2;         // 20-21
    Eskidi7: TSayi2;                        // 22
    FirmaYazilimSurum: array[0..7] of Char; // 23-26
    ModelNo: array[0..39] of Char;          // 27-46
    IslemAzamiSektorSayisi: TSayi2;         // 47
    Ayrildi2: TSayi2;                       // 48
    Yetenek1: TSayi2;                       // 49
    Yetenek2: TSayi2;                       // 50
    Eskidi8: array[0..1] of TSayi2;         // 51-52
    AlanDogrulugu1: TSayi2;                 // 53
    Eskidi9: array[0..4] of TSayi2;         // 54-58
    AlanDogrulugu2: TSayi2;                 // 59
    ToplamSektor: TSayi4;                   // 60-61
    Eskidi10: array[0..17] of TSayi2;       // 62-79
    SurumNo: TSayi2;                        // 80
    Diger: array[81..255] of TSayi2;        // diðer data alanlarý
  end;

procedure Yukle;
procedure IRQ14KesmeIslevi;
procedure IRQ15KesmeIslevi;
function SistemdekiIDEAygitlariniBul(AIDEDisk: PIDEDisk): Boolean;
function IDEAygitBilgisiniAl(AIDEDisk: PIDEDisk; AAygitBilgisi: Isaretci): Boolean;
function IDEAygitiMesgulMu(AIDEDisk: PIDEDisk): Boolean;
function IDEAygitindaVeriMevcutMu(AIDEDisk: PIDEDisk): Boolean;
function ReadSector28(AFizikselSurucu: Isaretci; AIlkSektor, ASektorSayisi: TSayi4;
  AHedefBellek: Isaretci): Boolean;

implementation

uses aygityonetimi, irq, sistemmesaj, donusum;

var
  IDEDiskListesi: array[0..3] of TIDEDisk = (
    (PortNo: $1F0; Kanal: ATA_KANAL0), (PortNo: $1F0; Kanal: ATA_KANAL1),
    (PortNo: $170; Kanal: ATA_KANAL0), (PortNo: $170; Kanal: ATA_KANAL1));

{==============================================================================
  sistemde mevcut ide disk sürücülerini yükler
 ==============================================================================}
procedure Yukle;
var
  _FizikselSurucu: PFizikselSurucu;
  _Bellek: TATA4;
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
      IDEAygitBilgisiniAl(@IDEDiskListesi[i], @_Bellek);

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
      _FizikselSurucu := FizikselDepolamaAygitiOlustur(SURUCUTIP_DISK);
      if(_FizikselSurucu <> nil) then
      begin

        _FizikselSurucu^.Ozellikler := 0;
        _FizikselSurucu^.SektorOku := @ReadSector28;
        _FizikselSurucu^.SektorYaz := nil;
        _FizikselSurucu^.PortBilgisi.PortNo := IDEDiskListesi[i].PortNo;
        _FizikselSurucu^.PortBilgisi.Kanal := IDEDiskListesi[i].Kanal;

        _FizikselSurucu^.SilindirSayisi := _Bellek.SilindirSayisi;
        _FizikselSurucu^.KafaSayisi := _Bellek.KafaSayisi;
        _FizikselSurucu^.IzBasinaSektorSayisi := _Bellek.IzBasinaSektor;
        _FizikselSurucu^.ToplamSektorSayisi := _Bellek.SilindirSayisi *
          _Bellek.KafaSayisi * _Bellek.IzBasinaSektor;
      end;
    end;
  end;
end;

{==============================================================================
  birinci disk IRQ rutini
 ==============================================================================}
procedure IRQ14KesmeIslevi;
begin

  SISTEM_MESAJ(RENK_MAVI, 'IRQ14 tetiklendi', []);
end;

{==============================================================================
  ikinci disk IRQ rutini
 ==============================================================================}
procedure IRQ15KesmeIslevi;
begin

  SISTEM_MESAJ(RENK_MAVI, 'IRQ15 tetiklendi', []);
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
  PortYaz1(AIDEDisk^.PortNo + ATAYAZMAC_SURUCUKAFA, i);

  // aygýt meþgul mü ?
  if(IDEAygitiMesgulMu(AIDEDisk)) then Exit;

  i := (AIDEDisk^.Kanal shl 4) or $A0;
  PortYaz1(AIDEDisk^.PortNo + ATAYAZMAC_SURUCUKAFA, i);

  if(PortAl1(AIDEDisk^.PortNo + ATAYAZMAC_SURUCUKAFA) <> i) then Exit;

  PortYaz1(AIDEDisk^.PortNo + ATAYAZMAC_SILINDIR_B01, $AA);
  if(PortAl1(AIDEDisk^.PortNo + ATAYAZMAC_SILINDIR_B01) <> $AA) then Exit;

  PortYaz1(AIDEDisk^.PortNo + ATAYAZMAC_SILINDIR_B01, $55);
  if(PortAl1(AIDEDisk^.PortNo + ATAYAZMAC_SILINDIR_B01) <> $55) then Exit;

  i := PortAl1(AIDEDisk^.PortNo + ATAYAZMAC_DURUM);
  if((i and ATAYAZMAC_DURUM_AYGITHAZIR) = 0) then Exit;

  Result := True;
end;

{==============================================================================
  ide aygýtýyla ilgili tanýmlayýcý bilgileri alýr
 ==============================================================================}
function IDEAygitBilgisiniAl(AIDEDisk: PIDEDisk; AAygitBilgisi: Isaretci): Boolean;
var
  _PortNo: TSayi2;
  i: TSayi1;
begin

  Result := False;

  i := (AIDEDisk^.Kanal shl 4) or $A0;
  PortYaz1(AIDEDisk^.PortNo + ATAYAZMAC_SURUCUKAFA, i);

  if(IDEAygitiMesgulMu(AIDEDisk)) then Exit;

  PortYaz1(AIDEDisk^.PortNo + $206, 2);
  PortYaz1(AIDEDisk^.PortNo + ATAYAZMAC_KOMUT, $EC);

  if(IDEAygitiMesgulMu(AIDEDisk)) then Exit;

  _PortNo := AIDEDisk^.PortNo;

  asm
    pushad
    mov edi,AAygitBilgisi
    mov ecx,256
    mov dx,_PortNo
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
  _Deger: TSayi1;
begin

  Result := True;

  for i := 1 to $1000 do
  begin

    _Deger := PortAl1(AIDEDisk^.PortNo + ATAYAZMAC_DURUM);
    if((_Deger and ATAYAZMAC_DURUM_MESGUL) = 0) then
    begin

      Result := False;
      Exit;
    end;
  end;
end;

{==============================================================================
  ide aygýtý bilgi transferi için hazýr mý ?
 ==============================================================================}
function IDEAygitindaVeriMevcutMu(AIDEDisk: PIDEDisk): Boolean;
var
  i: TSayi4;
  _Deger: TSayi1;
begin

  Result := False;

  for i := 1 to $1000 do
  begin

    _Deger := PortAl1(AIDEDisk^.PortNo + ATAYAZMAC_DURUM);
    if((_Deger and ATAYAZMAC_DURUM_MESGUL) = 0) then
    begin

      if((_Deger and ATAYAZMAC_DURUM_VERIHAZIR) = ATAYAZMAC_DURUM_VERIHAZIR) then
      begin

        Result := True;
        Exit;
      end;
    end;
  end;
end;

{==============================================================================
  LBA modunda 28 bitlik sektör okuma iþlemi yapar
 ==============================================================================}
var
  ReadSector28GorevNo: TSayi4 = 0;

function ReadSector28(AFizikselSurucu: Isaretci; AIlkSektor, ASektorSayisi: TSayi4;
  AHedefBellek: Isaretci): Boolean;
var
  _FizikselSurucu: PFizikselSurucu;
  _PortNo: TSayi2;
  _Deger: TSayi1;
begin

  if(ReadSector28GorevNo <> 0) then
  begin

    while ReadSector28GorevNo <> 0 do;
  end;

  ReadSector28GorevNo := CalisanGorev;

  // öndeðer çýkýþ deðeri
  Result := True;

  // sürücü bilgisine konumlan
  _FizikselSurucu := AFizikselSurucu;

  // aygýt meþgulse çýk
  if(IDEAygitiMesgulMu(@_FizikselSurucu^.PortBilgisi)) then
  begin

    ReadSector28GorevNo := 0;
    Exit;
  end;

  asm cli end;

  //okunacak sektör sayýsý
  PortYaz1(_FizikselSurucu^.PortBilgisi.PortNo + ATAYAZMAC_SEKTORSAYISI, ASektorSayisi);

  //okunacak sektör numarasý (28 bit)
  // LBA 07..00
  PortYaz1(_FizikselSurucu^.PortBilgisi.PortNo + ATAYAZMAC_SEKTORNO,
    (AIlkSektor and $FF));
  // LBA 15..08
  PortYaz1(_FizikselSurucu^.PortBilgisi.PortNo + ATAYAZMAC_SILINDIR_B01,
    ((AIlkSektor shr 8) and $FF));
  // LBA 23..16
  PortYaz1(_FizikselSurucu^.PortBilgisi.PortNo + ATAYAZMAC_SILINDIR_B23,
    ((AIlkSektor shr 16) and $FF));
  // lba 27..24
  _Deger := ((AIlkSektor shr 24) and $0F);
  _Deger := _Deger + $E0;
  _Deger := _Deger or (_FizikselSurucu^.PortBilgisi.Kanal shl 4);
  PortYaz1(_FizikselSurucu^.PortBilgisi.PortNo + ATAYAZMAC_SURUCUKAFA, _Deger);

  // sektör oku komutu gönder
  PortYaz1(_FizikselSurucu^.PortBilgisi.PortNo + ATAYAZMAC_KOMUT, $20);

  asm sti end;

  // okuma iþlevini gerçekleþtir
  repeat

    _PortNo := _FizikselSurucu^.PortBilgisi.PortNo;

    if(IDEAygitindaVeriMevcutMu(@_FizikselSurucu^.PortBilgisi)) then
    begin

      asm
        cli
        pushad
        mov edi,AHedefBellek
        mov ecx,256
        mov dx,_PortNo
        cld
        rep insw
        popad
        sti
      end;

      Dec(ASektorSayisi);
      AHedefBellek += 512;
    end else Result := False;

  until (ASektorSayisi = 0) or (Result = False);

  ReadSector28GorevNo := 0;
end;

end.
