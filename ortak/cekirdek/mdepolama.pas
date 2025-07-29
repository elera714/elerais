{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: mdepolama.pas
  Dosya Ýþlevi: mantýksal depolama aygýt iþlevlerini yönetir

  Güncelleme Tarihi: 29/07/2025

 ==============================================================================}
{$mode objfpc}
//{$DEFINE BOLUMLEME_BILGI}
unit mdepolama;

interface

uses paylasim, fdepolama;

const
  USTSINIR_MANTIKSALDEPOLAMA       = 6;

var
  MantiksalDisketHavuzListesi: array[0..1] of TSayi4;    // disket numaralama listesi
  MantiksalDiskHavuzListesi: array[0..3] of TSayi4;      // disk numaralama listesi

// mantýksal depolama aygýt yapýsý - program için
type
  { TODO - TMantiksalDepolama3 -> TMDNesne3 olarak deðiþtirildi, programlar güncellenecek }
  PMDNesne3 = ^TMDNesne3;
  TMDNesne3 = packed record
    Kimlik: TKimlik;
    SurucuTipi: TSayi4;           { TODO - bu deðer TMantiksalDepolama.FD içerisinde de mevcut, tasarýmsal olarak iptal edilmeli }
    AygitAdi: string[16];
    DST: TSayi4;                  // dosya sistem tipi
    BolumIlkSektor: TSayi4;
    BolumToplamSektor: TSayi4
  end;

// mantýksal depolama aygýt yapýsý - sistem için
type
  PMDNesne = ^TMDNesne;
  TMDNesne = packed record
    MD3: TMDNesne3;
    FD: PFDNesne;
    Acilis: TAcilis;
  end;

type
  TMantiksalDepolama = object
  private
    // mantýksal sürücü listesi. en fazla 6 depolama sürücüsü
    FMDAygitSayisi: TSayi4;
    FMDAygitListesi: array[0..USTSINIR_MANTIKSALDEPOLAMA - 1] of PMDNesne;
    function MDAygitiAl(ASiraNo: TSayi4): PMDNesne;
    procedure MDAygitiYaz(ASiraNo: TSayi4; AMDNesne: PMDNesne);
  public
    procedure Yukle;
    function MDAygitiOlustur: PMDNesne;
    function SurucuAl(ATamAdresYolu: string): PMDNesne;
    function AygitNumarasiAl(ASurucuTipi: TSayi4): TISayi4;
    function MantiksalSurucuAl(ASiraNo: TISayi4): PMDNesne;
    function MantiksalSurucuAl(AAygitAdi: string): PMDNesne;
    function MantiksalSurucuAl2(AKimlik: TKimlik): PMDNesne;
    function MantiksalDepolamaVeriOku(AMDNesne: PMDNesne; ASektorNo,
      ASektorSayisi: TSayi4; ABellek: Isaretci): TISayi4;
    property MDAygitSayisi: TSayi4 read FMDAygitSayisi write FMDAygitSayisi;
    property MDAygiti[ASiraNo: TSayi4]: PMDNesne read MDAygitiAl write MDAygitiYaz;
  end;

var
  MantiksalDepolama0: TMantiksalDepolama;

implementation

uses donusum, sistemmesaj, aygityonetimi;

{==============================================================================
  sistem için mantýksal depolama aygýtlarýný oluþturur
 ==============================================================================}
procedure TMantiksalDepolama.Yukle;
var
  FD: PFDNesne;
  MD: PMDNesne;
  DiskBolum: PDiskBolum;
  AcilisKayit1x: PAcilisKayit1x;
  AcilisKayit32: PAcilisKayit32;
  DosyaAyirmaTablosu: PDosyaAyirmaTablosu;
  DizinGirisi: PDizinGirisi;
  SurucuNo, i, BolumSayisi: TISayi4;
  BolumIlkSektor, BolumToplamSektor: TSayi4;
  Bellek1, Bellek2: Isaretci;
begin

  // mantýksal sürücü deðiþkenlerini ilk deðerlerle yükle
  MDAygitSayisi := 0;
  for i := 0 to USTSINIR_MANTIKSALDEPOLAMA - 1 do MDAygiti[i] := nil;

  // mantýksal disket sürücü numara üreticisini sýfýrla
  for i := 0 to 1 do MantiksalDisketHavuzListesi[i] := 0;

  // mantýksal disk sürücü numara üreticisini sýfýrla
  for i := 0 to 3 do MantiksalDiskHavuzListesi[i] := 0;

  // sistemde fiziksel depolama aygýtý var ise
  if(FizikselDepolama0.FDAygitSayisi > 0) then
  begin

    Bellek1 := GetMem(512);
    Bellek2 := GetMem(512);

    // tüm aygýtlarý denetle. (toplam 6 fiziksel aygýt)
    for i := 0 to USTSINIR_FIZIKSELDEPOLAMA - 1 do
    begin

      FD := FizikselDepolama0.FDAygiti[i];

      // eðer aygýt mevcut ise ...
      if not(FD = nil) then
      begin

        // aygýt disket sürücüsü ise ...
        if(FD^.FD3.SurucuTipi = SURUCUTIP_DISKET) then
        begin

          // disketin ilk sektörünü oku
          if(FD^.SektorOku(FD, 0, 1, Bellek1) = 0) then
          begin

            // okunan bilgi yapýsýna konumlan
            AcilisKayit1x := PAcilisKayit1x(Bellek1);

            // eðer dosya sistemi FAT12 ise...
            if(AcilisKayit1x^.DosyaSistemEtiket = 'FAT12   ') then
            begin

              // mantýksal sürücü için sürücü numarasý al
              SurucuNo := AygitNumarasiAl(SURUCUTIP_DISKET);
              if(SurucuNo > -1) then
              begin

                // mantýksal sürücü oluþtur
                MD := MDAygitiOlustur;
                if not(MD = nil) then
                begin

                  // mantýksal sürücü bilgileri ata
                  MD^.FD := FD;
                  MD^.MD3.AygitAdi := 'disket' + IntToStr(SurucuNo);
                  {$IFDEF BOLUMLEME_BILGI}
                  SISTEM_MESAJ(mtBilgi, RENK_YESIL, '  + Mantýksal aygýt: ' + MD^.MD3.AygitAdi, []);
                  {$ENDIF}
                  MD^.MD3.BolumIlkSektor := AcilisKayit1x^.BolumOncesiSektorSayisi;
                  MD^.MD3.BolumToplamSektor := AcilisKayit1x^.ToplamSektorSayisi1x;
                  MD^.MD3.DST := DST_FAT12;
                  MD^.MD3.SurucuTipi := FD^.FD3.SurucuTipi;

                  // dosya ayýrma tablosu bilgileri
                  DosyaAyirmaTablosu := @MD^.Acilis.DosyaAyirmaTablosu;
                  DosyaAyirmaTablosu^.IlkSektor := AcilisKayit1x^.AyrilmisSektor1;
                  DosyaAyirmaTablosu^.ToplamSektor := AcilisKayit1x^.DATBasinaSektor;
                  DosyaAyirmaTablosu^.ZincirBasinaSektor := AcilisKayit1x^.ZincirBasinaSektor;

                  // DizinGirisi dizin giriþleri
                  DizinGirisi := @MD^.Acilis.DizinGirisi;
                  DizinGirisi^.IlkSektor := (AcilisKayit1x^.DATBasinaSektor *
                    AcilisKayit1x^.DATSayisi) + AcilisKayit1x^.AyrilmisSektor1;
                  DizinGirisi^.ToplamSektor := AcilisKayit1x^.AzamiDizinGirisi div 16;

                  MD^.Acilis.IlkVeriSektorNo := (DizinGirisi^.IlkSektor + DizinGirisi^.ToplamSektor);

                  Inc(FMDAygitSayisi);
                end;
              end;
            end;
          end;
        end

        // aygýt disk sürücüsü ise ...
        else if(FD^.FD3.SurucuTipi = SURUCUTIP_DISK) then
        begin

          // diskin ilk sektörünü (MBR) oku
          if(FD^.SektorOku(FD, 0, 1, Bellek1) = 0) then
          begin

            // bölümleme bilgisine konumlan
            DiskBolum := PDiskBolum(Bellek1 + $1BE);

            // bölüm bilgisinin tümünün tipini al ve destekleniyorsa disk listesine ekle
            for BolumSayisi := 1 to 4 do
            begin

              if(DiskBolum^.BolumTipi = DST_ELR1) or
                (DiskBolum^.BolumTipi = DST_FAT12) or
                (DiskBolum^.BolumTipi = DST_FAT16) or
                (DiskBolum^.BolumTipi = DST_FAT32) or
                (DiskBolum^.BolumTipi = DST_FAT32LBA) then
              begin

                BolumIlkSektor := DiskBolum^.LBAIlkSektor;
                BolumToplamSektor := DiskBolum^.BolumSektorSayisi;

                // bölümün ilk sektörünü oku
                FD^.SektorOku(FD, DiskBolum^.LBAIlkSektor, 1, Bellek2);
                AcilisKayit1x := PAcilisKayit1x(Bellek2);

                // mantýksal sürücü deðer tanýmlamalarý

                // mantýksal sürücü için sürücü numarasý al
                SurucuNo := AygitNumarasiAl(SURUCUTIP_DISK);
                if(SurucuNo > -1) then
                begin

                  // mantýksal sürücü oluþtur
                  MD := MDAygitiOlustur;
                  if not(MD = nil) then
                  begin

                    // mantýksal sürücü bilgileri ata
                    MD^.FD := FD;
                    MD^.MD3.AygitAdi := 'disk' + IntToStr(SurucuNo);
                    {$IFDEF BOLUMLEME_BILGI}
                    SISTEM_MESAJ(mtBilgi, RENK_YESIL, '  + Mantýksal aygit: ' + MD^.MD3.AygitAdi, []);
                    {$ENDIF}
                    MD^.MD3.BolumIlkSektor := BolumIlkSektor;
                    MD^.MD3.BolumToplamSektor := BolumToplamSektor;
                    MD^.MD3.DST := DiskBolum^.BolumTipi;
                    MD^.MD3.SurucuTipi := FD^.FD3.SurucuTipi;

                    if(DiskBolum^.BolumTipi = DST_ELR1) then
                    begin

                      AcilisKayit32 := PAcilisKayit32(Bellek2);

                      // DosyaAyirmaTablosu bilgileri
                      DosyaAyirmaTablosu := @MD^.Acilis.DosyaAyirmaTablosu;
                      DosyaAyirmaTablosu^.IlkSektor := AcilisKayit32^.AyrilmisSektor1 +
                        AcilisKayit32^.BolumOncesiSektorSayisi;
                      DosyaAyirmaTablosu^.ToplamSektor := 30 * 1024 * 1024; //AcilisKayit32^.DATBasinaSektor;
                      DosyaAyirmaTablosu^.ZincirBasinaSektor := 4; //AcilisKayit32^.ZincirBasinaSektor;

                      // DizinGirisi dizin giriþleri
                      DizinGirisi := @MD^.Acilis.DizinGirisi;
                      DizinGirisi^.IlkSektor := $600; //1536; (AcilisKayit32^.DATBasinaSektor *
                        //AcilisKayit32^.DATSayisi) + AcilisKayit32^.AyrilmisSektor1 +
                        //AcilisKayit32^.BolumOncesiSektorSayisi;
                      DizinGirisi^.ToplamSektor := 30 * 1024 * 1024; // AcilisKayit32^.AzamiDizinGirisi div 16;

                      // fat32 dosya sisteminde dizin baþlangýcý da veri olarak kullanýlýr
                      // fat32 dosya sisteminin dizin tablo bitiþ deðeri yoktur!
                      MD^.Acilis.IlkVeriSektorNo := DizinGirisi^.IlkSektor;
                    end
                    else if(DiskBolum^.BolumTipi = DST_FAT32) or
                      (DiskBolum^.BolumTipi = DST_FAT32LBA) then
                    begin

                      AcilisKayit32 := PAcilisKayit32(Bellek2);

                      // DosyaAyirmaTablosu bilgileri
                      DosyaAyirmaTablosu := @MD^.Acilis.DosyaAyirmaTablosu;
                      DosyaAyirmaTablosu^.IlkSektor := AcilisKayit32^.AyrilmisSektor1 +
                        AcilisKayit32^.BolumOncesiSektorSayisi;
                      DosyaAyirmaTablosu^.ToplamSektor := AcilisKayit32^.DATBasinaSektor;
                      DosyaAyirmaTablosu^.ZincirBasinaSektor := AcilisKayit32^.ZincirBasinaSektor;

                      // DizinGirisi dizin giriþleri
                      DizinGirisi := @MD^.Acilis.DizinGirisi;
                      DizinGirisi^.IlkSektor := (AcilisKayit32^.DATBasinaSektor *
                        AcilisKayit32^.DATSayisi) + AcilisKayit32^.AyrilmisSektor1 +
                        AcilisKayit32^.BolumOncesiSektorSayisi;
                      DizinGirisi^.ToplamSektor := AcilisKayit32^.AzamiDizinGirisi div 16;

                      // fat32 dosya sisteminde dizin baþlangýcý da veri olarak kullanýlýr
                      // fat32 dosya sisteminin dizin tablo bitiþ deðeri yoktur!
                      MD^.Acilis.IlkVeriSektorNo := DizinGirisi^.IlkSektor;
                    end
                    else
                    begin

                      // DosyaAyirmaTablosu bilgileri
                      DosyaAyirmaTablosu := @MD^.Acilis.DosyaAyirmaTablosu;
                      DosyaAyirmaTablosu^.IlkSektor := AcilisKayit1x^.BolumOncesiSektorSayisi +
                        AcilisKayit1x^.AyrilmisSektor1;
                      DosyaAyirmaTablosu^.ToplamSektor := AcilisKayit1x^.DATBasinaSektor;
                      DosyaAyirmaTablosu^.ZincirBasinaSektor := AcilisKayit1x^.ZincirBasinaSektor;

                      // DizinGirisi dizin giriþleri
                      DizinGirisi := @MD^.Acilis.DizinGirisi;
                      DizinGirisi^.IlkSektor := (AcilisKayit1x^.DATBasinaSektor *
                        AcilisKayit1x^.DATSayisi) + AcilisKayit1x^.AyrilmisSektor1 +
                        AcilisKayit1x^.BolumOncesiSektorSayisi;
                      DizinGirisi^.ToplamSektor := AcilisKayit1x^.AzamiDizinGirisi div 16;

                      MD^.Acilis.IlkVeriSektorNo := (DizinGirisi^.IlkSektor + DizinGirisi^.ToplamSektor);
                    end;

                    { SISTEM_MESAJ_S16SISTEM_MESAJ_S16(RENK_SIYAH, 'RootFirstSector: ', _MantiksalSurucu^.Acilis.DizinGirisi.IlkSektor, 8);
                    SISTEM_MESAJ_S16(RENK_SIYAH, 'RootEntryNums: ', _MantiksalSurucu^.Acilis.DizinGirisi.GirdiSayisi, 4);
                    SISTEM_MESAJ_S16(RENK_SIYAH, 'RootTotalSector: ', _MantiksalSurucu^.Acilis.DizinGirisi.ToplamSektor, 8);

                    SISTEM_MESAJ_S16(RENK_SIYAH, 'FatFirstSector: ', _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.IlkSektor, 4);
                    SISTEM_MESAJ_S16(RENK_SIYAH, 'FatTotalSector: ', _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.ToplamSektor, 4);
                    SISTEM_MESAJ_S16(RENK_SIYAH, 'FatSecPerCluster: ', _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.KumeBasinaSektor, 2);
                    SISTEM_MESAJ_S16(RENK_SIYAH, 'FatFirstDataSector: ', _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.IlkVeriSektoru, 8);
                    end; }

                    Inc(FMDAygitSayisi);
                  end;
                end;
              end else if not(DiskBolum^.BolumTipi = DST_BELIRSIZ) then
              begin

                SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, '  ! Bilinmeyen dosya sistem tipi: %d', [DiskBolum^.BolumTipi]);
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

function TMantiksalDepolama.MDAygitiAl(ASiraNo: TSayi4): PMDNesne;
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_MANTIKSALDEPOLAMA) then
    Result := FMDAygitListesi[ASiraNo]
  else Result := nil;
end;

procedure TMantiksalDepolama.MDAygitiYaz(ASiraNo: TSayi4; AMDNesne: PMDNesne);
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_MANTIKSALDEPOLAMA) then
    FMDAygitListesi[ASiraNo] := AMDNesne;
end;

{==============================================================================
  mantýksal depolama aygýtý oluþturma iþlevi
 ==============================================================================}
function TMantiksalDepolama.MDAygitiOlustur: PMDNesne;
var
  MD: PMDNesne;
  i: TSayi4;
begin

  // boþ bir mantýksal sürücü yapýsý bul
  for i := 0 to USTSINIR_MANTIKSALDEPOLAMA - 1 do
  begin

    MD := MDAygiti[i];
    if(MD = nil) then
    begin

      MD := GetMem(SizeOf(TMDNesne));
      MDAygiti[i] := MD;

      MD^.MD3.Kimlik := MD_KIMLIK_ILKDEGER + i;
      Exit(MD);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  dosya yolundan sürücüyü bulur ve geriye sürücüye ait bellek bölgesini döndürür
  þu anda dosya yol biçimi: disket1:\dosya.c þeklinde
 ==============================================================================}
function TMantiksalDepolama.SurucuAl(ATamAdresYolu: string): PMDNesne;
var
  MD: PMDNesne;
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

  // sürücü sistemde mevcut mu ?
  for i := 0 to USTSINIR_MANTIKSALDEPOLAMA - 1 do
  begin

    MD := MDAygiti[i];
    if not(MD = nil) then
    begin

      if(MD^.MD3.AygitAdi = SurucuAdi) then Exit(MD);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  mantýksal depolama aygýtý için sayýsal sýra numarasý alýr
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
  sýra numarasýna göre mantýksal depolama aygýtýnýn veri yapýsýný geri döndürür
 ==============================================================================}
function TMantiksalDepolama.MantiksalSurucuAl(ASiraNo: TISayi4): PMDNesne;
var
  MD: PMDNesne;
  SiraNo,
  i: TISayi4;
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_MANTIKSALDEPOLAMA) then
  begin

    SiraNo := -1;
    for i := 0 to USTSINIR_MANTIKSALDEPOLAMA - 1 do
    begin

      MD := MDAygiti[i];
      if not(MD = nil) then Inc(SiraNo);

      if(SiraNo = ASiraNo) then Exit(MD);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  aygýt adýna (örnek: disk2) göre mantýksal depolama aygýtýnýn veri yapýsýný geri döndürür
 ==============================================================================}
function TMantiksalDepolama.MantiksalSurucuAl(AAygitAdi: string): PMDNesne;
var
  MD: PMDNesne;
  i: TISayi4;
begin

  for i := 0 to USTSINIR_MANTIKSALDEPOLAMA - 1 do
  begin

    MD := MDAygiti[i];
    if not(MD = nil) and (MD^.MD3.AygitAdi = AAygitAdi) then Exit(MD);
  end;

  Result := nil;
end;

{==============================================================================
  kimlik deðerine göre mantýksal depolama aygýtýnýn veri yapýsýný geri döndürür
 ==============================================================================}
function TMantiksalDepolama.MantiksalSurucuAl2(AKimlik: TKimlik): PMDNesne;
var
  MD: PMDNesne;
  i: TISayi4;
begin

  for i := 0 to USTSINIR_MANTIKSALDEPOLAMA - 1 do
  begin

    MD := MDAygiti[i];
    if not(MD = nil) and (MD^.MD3.Kimlik = AKimlik) then Exit(MD);
  end;

  Result := nil;
end;

{==============================================================================
  mantýksal depolama aygýtýndan veri okur
 ==============================================================================}
function TMantiksalDepolama.MantiksalDepolamaVeriOku(AMDNesne: PMDNesne; ASektorNo,
  ASektorSayisi: TSayi4; ABellek: Isaretci): TISayi4;
begin


{  SISTEM_MESAJ(RENK_MAVI, 'Depolama Kimlik: %d', [AMantiksalDepolama^.MD3.Kimlik]);
  SISTEM_MESAJ(RENK_MAVI, 'Depolama Sürücü Tipi: %d', [AMantiksalDepolama^.MD3.SurucuTipi]);
  SISTEM_MESAJ(RENK_MAVI, 'Depolama Adý: %s', [AMantiksalDepolama^.MD3.AygitAdi]);
  SISTEM_MESAJ(RENK_MAVI, 'Okunacak Ýlk Sektör: %d', [ASektorNo]);
  SISTEM_MESAJ(RENK_MAVI, 'Okunacak Sektör Sayýsý: %d', [ASektorSayisi]); }

  Result := AMDNesne^.FD^.SektorOku(AMDNesne, ASektorNo, ASektorSayisi, ABellek);
end;

end.
