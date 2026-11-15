{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: mdepolama.pas
  Dosya Ýþlevi: mantýksal depolama aygýt iþlevlerini yönetir

  Güncelleme Tarihi: 15/11/2026

 ==============================================================================}
{$mode objfpc}
//{$DEFINE BOLUMLEME_BILGI}
unit mdepolama;

interface

uses paylasim, fdepolama, aygit;

type
  // 12 & 16 bitlik boot kayýt yapýsý
  PAcilisKayit1x = ^TAcilisKayit1x;
  TAcilisKayit1x = packed record
    AYRLDI1: array[0..2] of TSayi1;           // 00..02
    OEMAdi: array[0..7] of Char;              // 03..10
    SektorBasinaByte: Word;                   // 11..12
    KBS: TSayi1;                              // 13..13 - Küme Baþýna Sektör
    AyrilmisSektor1: Word;                    // 14..15
    DATSayisi: TSayi1;                        // 16..16
    AzamiDizinGirisi: Word;                   // 17..18
    ToplamSektorSayisi1x: Word;               // 19..20
    MedyaTip: TSayi1;                         // 21..21
    DATBasinaSektor: Word;                    // 22..23 - SADECE FAT12 / FAT16 için
    IzBasinaSektor: Word;                     // 24..25
    KafaSayisi: Word;                         // 26..27
    BolumOncesiSektorSayisi: TSayi4;          // 28..31
    ToplamSektorSayisi32: TSayi4;             // 32..35

    AygitNo: TSayi1;                          // 36..36
    AYRLDI2: TSayi1;                          // 37..37
    GenisletilmisAcilisImzasi: TSayi1;        // 38..38
    SeriNo: TSayi4;                           // 39..42
    Etiket: array[0..10] of Char;             // 43..53
    DosyaSistemEtiket: array[0..7] of Char;   // 54..61
    // açýlýþ kodu ve $AA55
  end;

type
  // 32 bitlik boot kayýt yapýsý
  PAcilisKayit32 = ^TAcilisKayit32;
  TAcilisKayit32 = packed record
    AYRLDI1: array[0..2] of TSayi1;           // 00..02
    OEMAdi: array[0..7] of Char;              // 03..10
    SektorBasinaByte: Word;                   // 11..12
    KBS: TSayi1;                              // 13..13  - Küme Baþýna Sektör
    AyrilmisSektor1: Word;                    // 14..15
    DATSayisi: TSayi1;                        // 16..16
    AzamiDizinGirisi: Word;                   // 17..18
    ToplamSektorSayisi1x: Word;               // 19..20
    MedyaTip: TSayi1;                         // 21..21
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
    AyrilmisSektor2: array[0..11] of TSayi1;  // 52..63
    AygitNo: TSayi1;                          // 64..64
    Bayraklar2: TSayi1;                       // 65..65
    Imza: TSayi1;                             // 66..66
    EtiketKimlik: array[0..3] of Char;        // 67..70
    Etiket: array[0..10] of Char;             // 71..81
    DosyaSistemEtiket: array[0..7] of Char;   // 82..89
    // açýlýþ kodu ve $AA55
  end;

type
  // dosya ayýrma tablosu (file allocation table = FAT)
  PDosyaAyirmaTablosu = ^TDosyaAyirmaTablosu;
  TDosyaAyirmaTablosu = record
    IlkSektor: TSayi2;
    ToplamSektor: TSayi2;
    KBS: TSayi1;                // Küme Baþýma Sektör
  end;

const
  // desteklenen mantýksal depolama aygýt sayýsý
  USTSINIR_MD = 6;

var
  MantiksalDisketHavuzListesi: array[0..1] of TSayi4;    // disket numaralama listesi
  MantiksalDiskHavuzListesi: array[0..3] of TSayi4;      // disk numaralama listesi

type
  PAcilis = ^TAcilis;                 // acilis = boot
  TAcilis = record
    DosyaAyirmaTablosu: TDosyaAyirmaTablosu;
    DizinGirisi: TDizinGirisi;
    IlkVeriSektorNo: TSayi4;
  end;

// mantýksal depolama nesnesi - program için
type
  PMDNesne3 = ^TMDNesne3;
  TMDNesne3 = packed record
    Kimlik: TKimlik;
    SurucuTipi: TSayi4;
    AygitAdi: string[16];
    DST: TSayi4;                      // dosya sistem tipi
    BolumIlkSektor: TSayi4;
    BolumToplamSektor: TSayi4
  end;

// mantýksal depolama nesnesi - sistem için
type
  PMDNesne = ^TMDNesne;
  TMDNesne = class
  public
    FKimlik: TKimlik;
    FSurucuTipi: TSayi4;
    FAygitAdi: string[16];
    FDST: TSayi4;                     // dosya sistem tipi
    FBolumIlkSektor: TSayi4;
    FBolumToplamSektor: TSayi4;
    FD: TFDAygiti;
    Acilis: TAcilis;
  end;

type
  TMantiksalDepolama = class
  private
    // mantýksal sürücü listesi. en fazla 6 depolama sürücüsü
    FAygitSayisi: TSayi4;
    FAygitListesi: array[0..USTSINIR_MD - 1] of TMDNesne;
    function Al(ASiraNo: TISayi4): TMDNesne;
    procedure Yaz(ASiraNo: TISayi4; AMDNesne: TMDNesne);
  public
    constructor Create;
    procedure Yukle;
    function AygitOlustur: TMDNesne;
    function SurucuBul(ATamAdresYolu: string): TMDNesne;
    function AygitNumarasiAl(ASurucuTipi: TSayi4): TISayi4;
    function SurucuAl(ASiraNo: TISayi4): TMDNesne;
    function SurucuAl(AAygitAdi: string): TMDNesne;
    function SurucuAl2(AKimlik: TKimlik): TMDNesne;
    function VeriOku(AMDNesne: TMDNesne; ASektorNo, ASektorSayisi: TSayi4;
      ABellek: Isaretci): TSayi4;
    property AygitSayisi: TSayi4 read FAygitSayisi;
    property Aygit[ASiraNo: TISayi4]: TMDNesne read Al write Yaz;
  end;

var
  GMantiksalDepolama: TMantiksalDepolama;

implementation

uses donusum, sistemmesaj;

const
  MD_KIMLIK_ILKDEGER = $2000;    // mantýksal depolama

{==============================================================================
  mantýksal depolama nesne yükleme iþlevlerini gerçekleþtirir
 ==============================================================================}
constructor TMantiksalDepolama.Create;
var
  i: TSayi4;
begin

  // mantýksal sürücü deðiþkenlerini ilk deðerlerle yükle
  FAygitSayisi := 0;

  for i := 0 to USTSINIR_MD - 1 do Aygit[i] := nil;

  // mantýksal disket sürücü numara üreticisini sýfýrla
  for i := 0 to 1 do MantiksalDisketHavuzListesi[i] := 0;

  // mantýksal disk sürücü numara üreticisini sýfýrla
  for i := 0 to 3 do MantiksalDiskHavuzListesi[i] := 0;
end;

function TMantiksalDepolama.Al(ASiraNo: TISayi4): TMDNesne;
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_MD) then
    Result := FAygitListesi[ASiraNo]
  else Result := nil;
end;

procedure TMantiksalDepolama.Yaz(ASiraNo: TISayi4; AMDNesne: TMDNesne);
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_MD) then
    FAygitListesi[ASiraNo] := AMDNesne;
end;

{==============================================================================
  fiziksel depolama aygýtlarýnda oluþturulmuþ mantýksal depolama aygýtlarýný yükler
 ==============================================================================}
procedure TMantiksalDepolama.Yukle;
var
  FD: TFDAygiti;
  MD: TMDNesne;
  DiskBolum: PDiskBolum;
  AcilisKayit1x: PAcilisKayit1x;
  AcilisKayit32: PAcilisKayit32;
  DosyaAyirmaTablosu: PDosyaAyirmaTablosu;
  DizinGirisi: PDizinGirisi;
  SurucuNo, i, BolumSayisi: TISayi4;
  BolumIlkSektor, BolumToplamSektor: TSayi4;
  Bellek1, Bellek2: Isaretci;
begin

  // sistemde fiziksel depolama aygýtý var ise
  if(GFizikselDepolama.AygitSayisi > 0) then
  begin

    Bellek1 := GetMem(512);
    Bellek2 := GetMem(512);

    // tüm aygýtlarý denetle. (toplam 6 fiziksel aygýt)
    for i := 0 to USTSINIR_FD - 1 do
    begin

      FD := GFizikselDepolama.Aygit[i];

      // eðer aygýt mevcut ise ...
      if not(FD = nil) then
      begin

        // aygýt disket sürücüsü ise ...
        if(FD.SurucuTipi = SURUCUTIP_DISKET) then
        begin

          // disketin ilk sektörünü oku
          if(FD.FOku(0, 1, Bellek1) = HATA_YOK) then
          begin

            // okunan veri yapýsýna konumlan
            AcilisKayit1x := PAcilisKayit1x(Bellek1);

            // eðer dosya sistemi FAT12 ise...
            if(AcilisKayit1x^.DosyaSistemEtiket = 'FAT12   ') then
            begin

              // mantýksal sürücü için sürücü numarasý al
              SurucuNo := AygitNumarasiAl(SURUCUTIP_DISKET);
              if(SurucuNo > -1) then
              begin

                // mantýksal sürücü oluþtur
                MD := AygitOlustur;
                if not(MD = nil) then
                begin

                  // mantýksal sürücü deðerlerini ata
                  MD.FD := FD;
                  MD.FSurucuTipi := FD.SurucuTipi;
                  MD.FAygitAdi := 'disket' + IntToStr(SurucuNo);
                  MD.FDST := DST_FAT12;
                  MD.FBolumIlkSektor := AcilisKayit1x^.BolumOncesiSektorSayisi;
                  MD.FBolumToplamSektor := AcilisKayit1x^.ToplamSektorSayisi1x;
                  {$IFDEF BOLUMLEME_BILGI}
                  SISTEM_MESAJ(mtBilgi, RENK_YESIL, '  + Mantýksal aygýt: %s', [MD.FAygitAdi]);
                  {$ENDIF}

                  // dosya ayýrma tablosu (fat) bilgilerini ata
                  DosyaAyirmaTablosu := @MD.Acilis.DosyaAyirmaTablosu;
                  DosyaAyirmaTablosu^.IlkSektor := AcilisKayit1x^.AyrilmisSektor1;
                  DosyaAyirmaTablosu^.ToplamSektor := AcilisKayit1x^.DATBasinaSektor;
                  DosyaAyirmaTablosu^.KBS := AcilisKayit1x^.KBS;
                  //DosyaAyirmaTablosu^.KBS := (AcilisKayit1x^.AzamiDizinGirisi * 32) div AcilisKayit1x^.SektorBasinaByte;

                  // dosya + dizin giriþ bilgilerini ata
                  DizinGirisi := @MD.Acilis.DizinGirisi;
                  DizinGirisi^.IlkSektor := (AcilisKayit1x^.DATBasinaSektor *
                    AcilisKayit1x^.DATSayisi) + AcilisKayit1x^.AyrilmisSektor1;
                  DizinGirisi^.ToplamSektor := AcilisKayit1x^.AzamiDizinGirisi div 16;
                  MD.Acilis.IlkVeriSektorNo := (DizinGirisi^.IlkSektor + DizinGirisi^.ToplamSektor);

                  Inc(FAygitSayisi);
                end;
              end;
            end;
          end;
        end

        // aygýt disk sürücüsü ise ...
        else if(FD.SurucuTipi = SURUCUTIP_DISK) then
        begin

          // diskin ilk sektörünü (MBR) oku
          if(FD.FOku(0, 1, Bellek1) = HATA_YOK) then
          begin

            // ana bölümleme bilgisine konumlan
            DiskBolum := PDiskBolum(Bellek1 + $1BE);

            // bölümleme alanýndaki 4 giriþi de oku
            for BolumSayisi := 1 to 4 do
            begin

              // bölüm tipi tanýmlanan tiplerden biri ise
              if(DiskBolum^.BolumTipi = DST_ELR1) or
                (DiskBolum^.BolumTipi = DST_FAT12) or
                (DiskBolum^.BolumTipi = DST_FAT16_1) or
                (DiskBolum^.BolumTipi = DST_FAT16_2) or
                (DiskBolum^.BolumTipi = DST_FAT32) or
                (DiskBolum^.BolumTipi = DST_FAT32LBA) then
              begin

                // ilgili giriþin sektör bilgileri
                BolumIlkSektor := DiskBolum^.LBAIlkSektor;
                BolumToplamSektor := DiskBolum^.BolumSektorSayisi;

                // mantýksal bölümün ilk sektörünü oku
                if(FD.FOku(DiskBolum^.LBAIlkSektor, 1, Bellek2) = HATA_YOK) then
                begin

                  // okunan veri yapýsýna konumlan
                  AcilisKayit1x := PAcilisKayit1x(Bellek2);

                  // mantýksal sürücü için sürücü numarasý al
                  SurucuNo := AygitNumarasiAl(SURUCUTIP_DISK);
                  if(SurucuNo > -1) then
                  begin

                    // mantýksal sürücü oluþtur
                    MD := AygitOlustur;
                    if not(MD = nil) then
                    begin

                      // mantýksal sürücü deðerlerini ata
                      MD.FD := FD;
                      MD.FSurucuTipi := FD.SurucuTipi;
                      MD.FAygitAdi := 'disk' + IntToStr(SurucuNo);
                      MD.FDST := DiskBolum^.BolumTipi;
                      MD.FBolumIlkSektor := BolumIlkSektor;
                      MD.FBolumToplamSektor := BolumToplamSektor;
                      {$IFDEF BOLUMLEME_BILGI}
                      SISTEM_MESAJ(mtBilgi, RENK_YESIL, '  + Mantýksal aygit: %s', [MD.FAygitAdi]);
                      {$ENDIF}

                      // bölüm tiplerine göre deðer atamalarý

                      // dosya tipi ELR-1 dosya tipinde ise
                      // bilgi: geliþtirme çalýþmalarý halen devam etmekte
                      if(DiskBolum^.BolumTipi = DST_ELR1) then
                      begin

                        // okunan veri yapýsýna konumlan
                        AcilisKayit32 := PAcilisKayit32(Bellek2);

                        // dosya ayýrma tablosu (fat) bilgilerini ata
                        DosyaAyirmaTablosu := @MD.Acilis.DosyaAyirmaTablosu;
                        DosyaAyirmaTablosu^.IlkSektor := AcilisKayit32^.AyrilmisSektor1 +
                          AcilisKayit32^.BolumOncesiSektorSayisi;
                        DosyaAyirmaTablosu^.ToplamSektor := (30 * 1024 * 1024) div 512; //AcilisKayit32^.DATBasinaSektor;
                        DosyaAyirmaTablosu^.KBS := 4; //AcilisKayit32^.KBS;

                        // dosya + dizin giriþ bilgilerini ata
                        DizinGirisi := @MD.Acilis.DizinGirisi;
                        DizinGirisi^.IlkSektor := 6144 div 4;
                        DizinGirisi^.ToplamSektor := 30 * 1024 * 1024;
                        MD.Acilis.IlkVeriSektorNo := DizinGirisi^.IlkSektor;
                      end

                      // dosya tipi fat32 dosya tipinde ise
                      else if(DiskBolum^.BolumTipi = DST_FAT32) or
                        (DiskBolum^.BolumTipi = DST_FAT32LBA) then
                      begin

                        // okunan veri yapýsýna konumlan
                        AcilisKayit32 := PAcilisKayit32(Bellek2);

                        // dosya ayýrma tablosu (fat) bilgilerini ata
                        DosyaAyirmaTablosu := @MD.Acilis.DosyaAyirmaTablosu;
                        DosyaAyirmaTablosu^.IlkSektor := AcilisKayit32^.AyrilmisSektor1 +
                          AcilisKayit32^.BolumOncesiSektorSayisi;
                        DosyaAyirmaTablosu^.ToplamSektor := AcilisKayit32^.DATBasinaSektor;
                        DosyaAyirmaTablosu^.KBS := AcilisKayit32^.KBS;

                        // dosya + dizin giriþ bilgilerini ata
                        DizinGirisi := @MD.Acilis.DizinGirisi;
                        DizinGirisi^.IlkSektor := (AcilisKayit32^.DATBasinaSektor *
                          AcilisKayit32^.DATSayisi) + AcilisKayit32^.AyrilmisSektor1 +
                          AcilisKayit32^.BolumOncesiSektorSayisi;
                        DizinGirisi^.ToplamSektor := AcilisKayit32^.AzamiDizinGirisi div 16;
                        // fat32 dosya sisteminde dizin baþlangýcý da veri olarak kullanýlýr
                        // fat32 dosya sisteminin dizin tablo bitiþ deðeri yoktur!
                        MD.Acilis.IlkVeriSektorNo := DizinGirisi^.IlkSektor;
                      end

                      // dosya tipi diðer dosya tipinde ise
                      else
                      begin

                        // dosya ayýrma tablosu (fat) bilgilerini ata
                        DosyaAyirmaTablosu := @MD.Acilis.DosyaAyirmaTablosu;
                        DosyaAyirmaTablosu^.IlkSektor := {AcilisKayit1x^.BolumOncesiSektorSayisi +}
                          AcilisKayit1x^.AyrilmisSektor1;
                        DosyaAyirmaTablosu^.ToplamSektor := AcilisKayit1x^.DATBasinaSektor;
                        DosyaAyirmaTablosu^.KBS := AcilisKayit1x^.KBS;

                        // dosya + dizin giriþ bilgilerini ata
                        DizinGirisi := @MD.Acilis.DizinGirisi;
                        DizinGirisi^.IlkSektor := (AcilisKayit1x^.DATBasinaSektor *
                          AcilisKayit1x^.DATSayisi) + AcilisKayit1x^.AyrilmisSektor1 +
                          AcilisKayit1x^.BolumOncesiSektorSayisi;
                        DizinGirisi^.ToplamSektor := AcilisKayit1x^.AzamiDizinGirisi div 16;
                        MD.Acilis.IlkVeriSektorNo := (DizinGirisi^.IlkSektor + DizinGirisi^.ToplamSektor);
                      end;

                      Inc(FAygitSayisi);
                    end;
                  end;
                end;
              // bilinmeyen dosya tipi
              end else if not(DiskBolum^.BolumTipi = DST_BELIRSIZ) then
              begin

                SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'MDEPOLAMA:PAS: bilinmeyen dosya sistem tipi: %d', [DiskBolum^.BolumTipi]);
              end;

              Inc(DiskBolum);
            end;
          end;
        end;
      end;
    end;

    FreeMem(Bellek1, 512);
    FreeMem(Bellek2, 512);
  end;
end;

{==============================================================================
  mantýksal depolama aygýtý oluþturma iþlevi
 ==============================================================================}
function TMantiksalDepolama.AygitOlustur: TMDNesne;
var
  MD: TMDNesne;
  i: TSayi4;
begin

  // tüm aygýtlarý gözden geçir
  for i := 0 to USTSINIR_MD - 1 do
  begin

    // aygýt kullanýlmamýþsa
    MD := Aygit[i];
    if(MD = nil) then
    begin

      // aygýtý oluþtur ve diziye kaydet
      MD := TMDNesne.Create;
      Aygit[i] := MD;

      // aygýta kimlik deðeri ata ve çýk
      MD.FKimlik := MD_KIMLIK_ILKDEGER + i;
      Exit(MD);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  dosya yolundan sürücüyü bulur ve geriye sürücüye ait nesneyi döndürür
 ==============================================================================}
function TMantiksalDepolama.SurucuBul(ATamAdresYolu: string): TMDNesne;
var
  MD: TMDNesne;
  i: TSayi4;
  SurucuAdi: string;
begin

  // dosya yolunda sürücü belirtilmiþ mi ?
  i := Pos(':', ATamAdresYolu);

  // eðer belirtilmiþse ...
  if(i > 0) then
  begin

    SurucuAdi := Copy(ATamAdresYolu, 1, i - 1);
  end else SurucuAdi := AcilisSurucuAygiti;

  // tüm sürücüleri incele
  for i := 0 to USTSINIR_MD - 1 do
  begin

    // sürücü sistemde mevcut mu ?
    MD := Aygit[i];
    if not(MD = nil) then
    begin

      // sürücü adý aranan sürücü adý ile uyuþuyor mu?
      if(MD.FAygitAdi = SurucuAdi) then Exit(MD);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  mantýksal depolama aygýtý için aygýt numarasý (kimlik) alýr
 ==============================================================================}
function TMantiksalDepolama.AygitNumarasiAl(ASurucuTipi: TSayi4): TISayi4;
var
  i: TSayi4;
begin

  // disket sürücüsü için
  if(ASurucuTipi = SURUCUTIP_DISKET) then
  begin

    for i := 0 to 1 do
    begin

      if(MantiksalDisketHavuzListesi[i] = 0) then
      begin

        MantiksalDisketHavuzListesi[i] := 1;
        Exit(i + 1);
      end;
    end;
  end

  // disk sürücüsü için
  else if(ASurucuTipi = SURUCUTIP_DISK) then
  begin

    for i := 0 to 3 do
    begin

      if(MantiksalDiskHavuzListesi[i] = 0) then
      begin

        MantiksalDiskHavuzListesi[i] := 1;
        Exit(i + 1);
      end;
    end;
  end;

  Result := -1;
end;

{==============================================================================
  sýra numarasýna göre mantýksal depolama aygýt nesnesini geri döndürür
 ==============================================================================}
function TMantiksalDepolama.SurucuAl(ASiraNo: TISayi4): TMDNesne;
var
  MD: TMDNesne;
  SiraNo,
  i: TISayi4;
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_MD) then
  begin

    SiraNo := -1;
    for i := 0 to USTSINIR_MD - 1 do
    begin

      MD := Aygit[i];
      if not(MD = nil) then Inc(SiraNo);

      if(SiraNo = ASiraNo) then Exit(MD);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  aygýt adýna (örnek: disk2) göre mantýksal depolama aygýt nesnesini geri döndürür
 ==============================================================================}
function TMantiksalDepolama.SurucuAl(AAygitAdi: string): TMDNesne;
var
  MD: TMDNesne;
  i: TISayi4;
begin

  for i := 0 to USTSINIR_MD - 1 do
  begin

    MD := Aygit[i];
    if not(MD = nil) and (MD.FAygitAdi = AAygitAdi) then Exit(MD);
  end;

  Result := nil;
end;

{==============================================================================
  kimlik deðerine göre mantýksal depolama aygýt nesnesini geri döndürür
 ==============================================================================}
function TMantiksalDepolama.SurucuAl2(AKimlik: TKimlik): TMDNesne;
var
  MD: TMDNesne;
  i: TISayi4;
begin

  for i := 0 to USTSINIR_MD - 1 do
  begin

    MD := Aygit[i];
    if not(MD = nil) and (MD.FKimlik = AKimlik) then Exit(MD);
  end;

  Result := nil;
end;

{==============================================================================
  mantýksal depolama aygýtýndan veri okur
 ==============================================================================}
function TMantiksalDepolama.VeriOku(AMDNesne: TMDNesne; ASektorNo, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TSayi4;
begin

  {SISTEM_MESAJ(mtBilgi, RENK_PEMBE, 'Depolama Kimlik: %d', [AMDNesne.FKimlik]);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, 'Depolama Sürücü Tipi: %d', [AMDNesne.FSurucuTipi]);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, 'Depolama Adý: %s', [AMDNesne.FAygitAdi]);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, 'Okunacak Ýlk Sektör: %d', [ASektorNo]);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, 'Okunacak Sektör Sayýsý: %d', [ASektorSayisi]);}

  Result := AMDNesne.FD.FOku(ASektorNo, ASektorSayisi, ABellek);
end;

end.
