{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: mdepolama.pas
  Dosya Ýþlevi: mantýksal depolama aygýt iþlevlerini yönetir

  Güncelleme Tarihi: 01/08/2026

 ==============================================================================}
{$mode objfpc}
//{$DEFINE BOLUMLEME_BILGI}
unit mdepolama;

interface

uses paylasim, fdepolama;

const
  USTSINIR_MD = 6;    // desteklenen mantýksal depolama aygýt sayýsý

var
  MantiksalDisketHavuzListesi: array[0..1] of TSayi4;    // disket numaralama listesi
  MantiksalDiskHavuzListesi: array[0..3] of TSayi4;      // disk numaralama listesi

type
  PAcilis = ^TAcilis;     // acilis = boot
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
    DST: TSayi4;                  // dosya sistem tipi
    BolumIlkSektor: TSayi4;
    BolumToplamSektor: TSayi4
  end;

// mantýksal depolama nesnesi - sistem için
type
  PMDNesne = ^TMDNesne;
  TMDNesne = class
  public
    MD3: TMDNesne3;
    FD: TFDNesne;
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
    function AygitOlustur: TMDNesne;
    function SurucuBul(ATamAdresYolu: string): TMDNesne;
    function AygitNumarasiAl(ASurucuTipi: TSayi4): TISayi4;
    function SurucuAl(ASiraNo: TISayi4): TMDNesne;
    function SurucuAl(AAygitAdi: string): TMDNesne;
    function SurucuAl2(AKimlik: TKimlik): TMDNesne;
    function VeriOku(AMDNesne: TMDNesne; ASektorNo, ASektorSayisi: TSayi4;
      ABellek: Isaretci): TISayi4;
    property AygitSayisi: TSayi4 read FAygitSayisi;
    property Aygit[ASiraNo: TISayi4]: TMDNesne read Al write Yaz;
  end;

var
  GMantiksalDepolama: TMantiksalDepolama;

implementation

uses donusum, sistemmesaj, aygityonetimi;

{==============================================================================
  sistem için mantýksal depolama aygýtlarýný oluþturur
 ==============================================================================}
constructor TMantiksalDepolama.Create;
var
  FD: PFDNesne;
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

  // mantýksal sürücü deðiþkenlerini ilk deðerlerle yükle
  FAygitSayisi := 0;
  for i := 0 to USTSINIR_MD - 1 do Aygit[i] := nil;

  // mantýksal disket sürücü numara üreticisini sýfýrla
  for i := 0 to 1 do MantiksalDisketHavuzListesi[i] := 0;

  // mantýksal disk sürücü numara üreticisini sýfýrla
  for i := 0 to 3 do MantiksalDiskHavuzListesi[i] := 0;

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
        if(FD^.FD3.SurucuTipi = SURUCUTIP_DISKET) then
        begin

          // disketin ilk sektörünü oku
          if(FD^.SektorOku(FD, 0, 1, Bellek1) = HATA_YOK) then
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
                MD := AygitOlustur;
                if not(MD = nil) then
                begin

                  // mantýksal sürücü bilgileri ata
                  MD.FD := FD^;

                  MD.MD3.SurucuTipi := FD^.FD3.SurucuTipi;
                  MD.MD3.AygitAdi := 'disket' + IntToStr(SurucuNo);
                  MD.MD3.DST := DST_FAT12;
                  MD.MD3.BolumIlkSektor := AcilisKayit1x^.BolumOncesiSektorSayisi;
                  MD.MD3.BolumToplamSektor := AcilisKayit1x^.ToplamSektorSayisi1x;
                  {$IFDEF BOLUMLEME_BILGI}
                  SISTEM_MESAJ(mtBilgi, RENK_YESIL, '  + Mantýksal aygýt: ' + MD^.MD3.AygitAdi, []);
                  {$ENDIF}

                  // dosya ayýrma tablosu (fat) bilgileri
                  DosyaAyirmaTablosu := @MD.Acilis.DosyaAyirmaTablosu;
                  DosyaAyirmaTablosu^.IlkSektor := AcilisKayit1x^.AyrilmisSektor1;
                  DosyaAyirmaTablosu^.ToplamSektor := AcilisKayit1x^.DATBasinaSektor;
                  DosyaAyirmaTablosu^.KBS := AcilisKayit1x^.KBS;
                  //DosyaAyirmaTablosu^.KBS := (AcilisKayit1x^.AzamiDizinGirisi * 32) div AcilisKayit1x^.SektorBasinaByte;

                  // dosya + dizin giriþ bilgileri
                  DizinGirisi := @MD.Acilis.DizinGirisi;
                  DizinGirisi^.IlkSektor := (AcilisKayit1x^.DATBasinaSektor *
                    AcilisKayit1x^.DATSayisi) + AcilisKayit1x^.AyrilmisSektor1;
                  DizinGirisi^.ToplamSektor := AcilisKayit1x^.AzamiDizinGirisi div 16;
                  DizinGirisi^.GirdiUzunlugu := 32;
                  DizinGirisi^.ToplamKokSektor := (AcilisKayit1x^.AzamiDizinGirisi * 32) div AcilisKayit1x^.SektorBasinaByte;

                  MD.Acilis.IlkVeriSektorNo := (DizinGirisi^.IlkSektor + DizinGirisi^.ToplamSektor);

                  Inc(FAygitSayisi);
                end;
              end;
            end;
          end;
        end

        // aygýt disk sürücüsü ise ...
        else if(FD^.FD3.SurucuTipi = SURUCUTIP_DISK) then
        begin

          // diskin ilk sektörünü (MBR) oku
          if(FD^.SektorOku(FD, 0, 1, Bellek1) = HATA_YOK) then
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
                if(FD^.SektorOku(FD, DiskBolum^.LBAIlkSektor, 1, Bellek2) = HATA_YOK) then
                begin

                  AcilisKayit1x := PAcilisKayit1x(Bellek2);

                  // mantýksal sürücü deðer tanýmlamalarý

                  // mantýksal sürücü için sürücü numarasý al
                  SurucuNo := AygitNumarasiAl(SURUCUTIP_DISK);
                  if(SurucuNo > -1) then
                  begin

                    // mantýksal sürücü oluþtur
                    MD := AygitOlustur;
                    if not(MD = nil) then
                    begin

                      // mantýksal sürücü bilgileri ata
                      MD.FD := FD^;

                      MD.MD3.SurucuTipi := FD^.FD3.SurucuTipi;
                      MD.MD3.AygitAdi := 'disk' + IntToStr(SurucuNo);
                      MD.MD3.DST := DiskBolum^.BolumTipi;
                      MD.MD3.BolumIlkSektor := BolumIlkSektor;
                      MD.MD3.BolumToplamSektor := BolumToplamSektor;
                      {$IFDEF BOLUMLEME_BILGI}
                      SISTEM_MESAJ(mtBilgi, RENK_YESIL, '  + Mantýksal aygit: ' + MD^.MD3.AygitAdi, []);
                      {$ENDIF}

                      if(DiskBolum^.BolumTipi = DST_ELR1) then
                      begin

                        AcilisKayit32 := PAcilisKayit32(Bellek2);

                        // dosya ayýrma tablosu (fat) bilgileri
                        DosyaAyirmaTablosu := @MD.Acilis.DosyaAyirmaTablosu;
                        DosyaAyirmaTablosu^.IlkSektor := AcilisKayit32^.AyrilmisSektor1 +
                          AcilisKayit32^.BolumOncesiSektorSayisi;
                        DosyaAyirmaTablosu^.ToplamSektor := 30 * 1024 * 1024; //AcilisKayit32^.DATBasinaSektor;
                        DosyaAyirmaTablosu^.KBS := 4; //AcilisKayit32^.KBS;

                        // dosya + dizin giriþ bilgileri
                        DizinGirisi := @MD.Acilis.DizinGirisi;
                        DizinGirisi^.IlkSektor := 5632 div 4; //SEKTORNO_VERI; // (AcilisKayit32^.DATBasinaSektor *
                          //AcilisKayit32^.DATSayisi) + AcilisKayit32^.AyrilmisSektor1 +
                          //AcilisKayit32^.BolumOncesiSektorSayisi;
                        DizinGirisi^.ToplamSektor := 30 * 1024 * 1024; // AcilisKayit32^.AzamiDizinGirisi div 16;
                        DizinGirisi^.GirdiUzunlugu := 64;

                        // fat32 dosya sisteminde dizin baþlangýcý da veri olarak kullanýlýr
                        // fat32 dosya sisteminin dizin tablo bitiþ deðeri yoktur!
                        MD.Acilis.IlkVeriSektorNo := DizinGirisi^.IlkSektor;
                      end
                      else if(DiskBolum^.BolumTipi = DST_FAT32) or
                        (DiskBolum^.BolumTipi = DST_FAT32LBA) then
                      begin

                        AcilisKayit32 := PAcilisKayit32(Bellek2);

                        // dosya ayýrma tablosu (fat) bilgileri
                        DosyaAyirmaTablosu := @MD.Acilis.DosyaAyirmaTablosu;
                        DosyaAyirmaTablosu^.IlkSektor := AcilisKayit32^.AyrilmisSektor1 +
                          AcilisKayit32^.BolumOncesiSektorSayisi;
                        DosyaAyirmaTablosu^.ToplamSektor := AcilisKayit32^.DATBasinaSektor;
                        DosyaAyirmaTablosu^.KBS := AcilisKayit32^.KBS;

                        // dosya + dizin giriþ bilgileri
                        DizinGirisi := @MD.Acilis.DizinGirisi;
                        DizinGirisi^.IlkSektor := (AcilisKayit32^.DATBasinaSektor *
                          AcilisKayit32^.DATSayisi) + AcilisKayit32^.AyrilmisSektor1 +
                          AcilisKayit32^.BolumOncesiSektorSayisi;
                        DizinGirisi^.ToplamSektor := AcilisKayit32^.AzamiDizinGirisi div 16;
                        DizinGirisi^.GirdiUzunlugu := 32;

                        // yeni eklendi. test edilecek
                        DizinGirisi^.IlkKumeNo := AcilisKayit32^.DizinGirisindekiZincirSayisi;

                        // fat32 dosya sisteminde dizin baþlangýcý da veri olarak kullanýlýr
                        // fat32 dosya sisteminin dizin tablo bitiþ deðeri yoktur!
                        MD.Acilis.IlkVeriSektorNo := DizinGirisi^.IlkSektor;
                      end
                      else
                      begin

                        // dosya ayýrma tablosu (fat) bilgileri
                        DosyaAyirmaTablosu := @MD.Acilis.DosyaAyirmaTablosu;
                        DosyaAyirmaTablosu^.IlkSektor := AcilisKayit1x^.BolumOncesiSektorSayisi +
                          AcilisKayit1x^.AyrilmisSektor1;
                        DosyaAyirmaTablosu^.ToplamSektor := AcilisKayit1x^.DATBasinaSektor;
                        DosyaAyirmaTablosu^.KBS := AcilisKayit1x^.KBS;

                        // dosya + dizin giriþ bilgileri
                        DizinGirisi := @MD.Acilis.DizinGirisi;
                        DizinGirisi^.IlkSektor := (AcilisKayit1x^.DATBasinaSektor *
                          AcilisKayit1x^.DATSayisi) + AcilisKayit1x^.AyrilmisSektor1 +
                          AcilisKayit1x^.BolumOncesiSektorSayisi;
                        DizinGirisi^.ToplamSektor := AcilisKayit1x^.AzamiDizinGirisi div 16;
                        DizinGirisi^.GirdiUzunlugu := 32;

                        MD.Acilis.IlkVeriSektorNo := (DizinGirisi^.IlkSektor + DizinGirisi^.ToplamSektor);
                      end;

                      { SISTEM_MESAJ_S16SISTEM_MESAJ_S16(RENK_SIYAH, 'RootFirstSector: ', _MantiksalSurucu^.Acilis.DizinGirisi.IlkSektor, 8);
                      SISTEM_MESAJ_S16(RENK_SIYAH, 'RootEntryNums: ', _MantiksalSurucu^.Acilis.DizinGirisi.GirdiSayisi, 4);
                      SISTEM_MESAJ_S16(RENK_SIYAH, 'RootTotalSector: ', _MantiksalSurucu^.Acilis.DizinGirisi.ToplamSektor, 8);

                      SISTEM_MESAJ_S16(RENK_SIYAH, 'FatFirstSector: ', _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.IlkSektor, 4);
                      SISTEM_MESAJ_S16(RENK_SIYAH, 'FatTotalSector: ', _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.ToplamSektor, 4);
                      SISTEM_MESAJ_S16(RENK_SIYAH, 'FatSecPerCluster: ', _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.KumeBasinaSektor, 2);
                      SISTEM_MESAJ_S16(RENK_SIYAH, 'FatFirstDataSector: ', _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.IlkVeriSektoru, 8);
                      end; }

                      Inc(FAygitSayisi);
                    end;
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

function TMantiksalDepolama.Al(ASiraNo: TISayi4): TMDNesne;
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_MD) then
    Result := FAygitListesi[ASiraNo]
  else Result := nil;
end;

procedure TMantiksalDepolama.Yaz(ASiraNo: TISayi4; AMDNesne: TMDNesne);
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_MD) then
    FAygitListesi[ASiraNo] := AMDNesne;
end;

{==============================================================================
  mantýksal depolama aygýtý oluþturma iþlevi
 ==============================================================================}
function TMantiksalDepolama.AygitOlustur: TMDNesne;
var
  MD: TMDNesne;
  i: TSayi4;
begin

  // boþ bir mantýksal sürücü nesnesi bul
  for i := 0 to USTSINIR_MD - 1 do
  begin

    MD := Aygit[i];
    if(MD = nil) then
    begin

      MD := TMDNesne.Create;
      Aygit[i] := MD;

      MD.MD3.Kimlik := MD_KIMLIK_ILKDEGER + i;
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

  // sürücü sistemde mevcut mu ?
  for i := 0 to USTSINIR_MD - 1 do
  begin

    MD := Aygit[i];
    if not(MD = nil) then
    begin

      if(MD.MD3.AygitAdi = SurucuAdi) then Exit(MD);
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
  sýra numarasýna göre mantýksal depolama aygýtýnýn nesnesini geri döndürür
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
  aygýt adýna (örnek: disk2) göre mantýksal depolama aygýtýnýn nesnesini geri döndürür
 ==============================================================================}
function TMantiksalDepolama.SurucuAl(AAygitAdi: string): TMDNesne;
var
  MD: TMDNesne;
  i: TISayi4;
begin

  for i := 0 to USTSINIR_MD - 1 do
  begin

    MD := Aygit[i];
    if not(MD = nil) and (MD.MD3.AygitAdi = AAygitAdi) then Exit(MD);
  end;

  Result := nil;
end;

{==============================================================================
  kimlik deðerine göre mantýksal depolama aygýtýnýn nesnesini geri döndürür
 ==============================================================================}
function TMantiksalDepolama.SurucuAl2(AKimlik: TKimlik): TMDNesne;
var
  MD: TMDNesne;
  i: TISayi4;
begin

  for i := 0 to USTSINIR_MD - 1 do
  begin

    MD := Aygit[i];
    if not(MD = nil) and (MD.MD3.Kimlik = AKimlik) then Exit(MD);
  end;

  Result := nil;
end;

{==============================================================================
  mantýksal depolama aygýtýndan veri okur
 ==============================================================================}
function TMantiksalDepolama.VeriOku(AMDNesne: TMDNesne; ASektorNo, ASektorSayisi: TSayi4;
  ABellek: Isaretci): TISayi4;
begin

{  SISTEM_MESAJ(RENK_MAVI, 'Depolama Kimlik: %d', [AMantiksalDepolama^.MD3.Kimlik]);
  SISTEM_MESAJ(RENK_MAVI, 'Depolama Sürücü Tipi: %d', [AMantiksalDepolama^.MD3.SurucuTipi]);
  SISTEM_MESAJ(RENK_MAVI, 'Depolama Adý: %s', [AMantiksalDepolama^.MD3.AygitAdi]);
  SISTEM_MESAJ(RENK_MAVI, 'Okunacak Ýlk Sektör: %d', [ASektorNo]);
  SISTEM_MESAJ(RENK_MAVI, 'Okunacak Sektör Sayýsý: %d', [ASektorSayisi]); }

  Result := AMDNesne.FD.SektorOku(AMDNesne, ASektorNo, ASektorSayisi, ABellek);
end;

end.
