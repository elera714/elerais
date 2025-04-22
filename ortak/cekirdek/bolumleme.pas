{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: bolumleme.pas
  Dosya ��levi: depolama ayg�t� b�l�m y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 30/01/2025

 ==============================================================================}
{$mode objfpc}
//{$DEFINE BOLUMLEME_BILGI}
unit bolumleme;

interface

uses paylasim;

var
  MantiksalDisketHavuzListesi: array[0..1] of Integer;    // disket numaralama listesi
  MantiksalDiskHavuzListesi: array[0..3] of Integer;      // disk numaralama listesi

procedure Yukle;
function MantiksalDepolamaAygitiOlustur: PMantiksalDepolama;
function SurucuAl(ATamAdresYolu: string): PMantiksalDepolama;
function MantiksalDepolamaAygitNumarasiAl(ASurucuTipi: TSayi4): TISayi4;

implementation

uses donusum, sistemmesaj, aygityonetimi;

{==============================================================================
  depolama ayg�t� mant�ksal s�r�c� atama i�levlerini yerine getirir
 ==============================================================================}
procedure Yukle;
var
  MD: PMantiksalDepolama;
  DiskBolum: PDiskBolum;
  AcilisKayit1x: PAcilisKayit1x;
  AcilisKayit32: PAcilisKayit32;
  DosyaAyirmaTablosu: PDosyaAyirmaTablosu;
  DizinGirisi: PDizinGirisi;
  Bellek1: array[0..511] of TSayi1;
  Bellek2: array[0..511] of TSayi1;
  SurucuNo, i, BolumSayisi: TISayi4;
  BolumIlkSektor, BolumToplamSektor: TSayi4;
begin

  // mant�ksal s�r�c� de�i�kenlerini ilk de�erlerle y�kle
  MantiksalDepolamaAygitSayisi := 0;
  for i := 0 to 5 do MantiksalDepolamaAygitListesi[i].Mevcut := False;

  // mant�ksal disket s�r�c� numara �reticisini s�f�rla
  for i := 0 to 1 do MantiksalDisketHavuzListesi[i] := 0;

  // mant�ksal disk s�r�c� numara �reticisini s�f�rla
  for i := 0 to 3 do MantiksalDiskHavuzListesi[i] := 0;

  // sistemde fiziksel depolama ayg�t� var ise
  if(FizikselDepolamaAygitSayisi > 0) then
  begin

    // t�m ayg�tlar� denetle. (toplam 6 fiziksel ayg�t)
    for i := 0 to 5 do
    begin

      // e�er ayg�t mevcut ise ...
      if(FizikselDepolamaAygitListesi[i].Mevcut0) then
      begin

        // ayg�t disket s�r�c�s� ise ...
        if(FizikselDepolamaAygitListesi[i].FD3.SurucuTipi = SURUCUTIP_DISKET) then
        begin

          // disketin ilk sekt�r�n� oku
          if(FizikselDepolamaAygitListesi[i].SektorOku(@FizikselDepolamaAygitListesi[i],
            0, 1, @Bellek1) = 0) then
          begin

            // okunan bilgi yap�s�na konumlan
            AcilisKayit1x := @Bellek1;

            // e�er dosya sistemi FAT12 ise...
            if(AcilisKayit1x^.DosyaSistemEtiket = 'FAT12   ') then
            begin

              // mant�ksal s�r�c� i�in s�r�c� numaras� al
              SurucuNo := MantiksalDepolamaAygitNumarasiAl(SURUCUTIP_DISKET);
              if(SurucuNo > -1) then
              begin

                // mant�ksal s�r�c� olu�tur
                MD := MantiksalDepolamaAygitiOlustur;
                if not(MD = nil) then
                begin

                  // mant�ksal s�r�c� bilgileri ata
                  MD^.FD := @FizikselDepolamaAygitListesi[i];
                  MD^.MD3.AygitAdi := 'disket' + IntToStr(SurucuNo);
                  {$IFDEF BOLUMLEME_BILGI}
                  SISTEM_MESAJ(RENK_YESIL, '  + Mant�ksal ayg�t: ' + MD^.MD3.AygitAdi, []);
                  {$ENDIF}
                  MD^.MD3.BolumIlkSektor := AcilisKayit1x^.BolumOncesiSektorSayisi;
                  MD^.MD3.BolumToplamSektor := AcilisKayit1x^.ToplamSektorSayisi1x;
                  MD^.MD3.DST := DST_FAT12;
                  MD^.MD3.SurucuTipi := FizikselDepolamaAygitListesi[i].FD3.SurucuTipi;

                  // dosya ay�rma tablosu bilgileri
                  DosyaAyirmaTablosu := @MD^.Acilis.DosyaAyirmaTablosu;
                  DosyaAyirmaTablosu^.IlkSektor := AcilisKayit1x^.AyrilmisSektor1;
                  DosyaAyirmaTablosu^.ToplamSektor := AcilisKayit1x^.DATBasinaSektor;
                  DosyaAyirmaTablosu^.ZincirBasinaSektor := AcilisKayit1x^.ZincirBasinaSektor;

                  // DizinGirisi dizin giri�leri
                  DizinGirisi := @MD^.Acilis.DizinGirisi;
                  DizinGirisi^.IlkSektor := (AcilisKayit1x^.DATBasinaSektor *
                    AcilisKayit1x^.DATSayisi) + AcilisKayit1x^.AyrilmisSektor1;
                  DizinGirisi^.ToplamSektor := AcilisKayit1x^.AzamiDizinGirisi div 16;

                  MD^.Acilis.IlkVeriSektorNo := (DizinGirisi^.IlkSektor + DizinGirisi^.ToplamSektor);

                  Inc(MantiksalDepolamaAygitSayisi);
                end;
              end;
            end;
          end;
        end

        // ayg�t disk s�r�c�s� ise ...
        else if(FizikselDepolamaAygitListesi[i].FD3.SurucuTipi = SURUCUTIP_DISK) then
        begin

          // diskin ilk sekt�r�n� (MBR) oku
          if(FizikselDepolamaAygitListesi[i].SektorOku(@FizikselDepolamaAygitListesi[i],
            0, 1, @Bellek1) = 0) then
          begin

            // b�l�mleme bilgisine konumlan
            DiskBolum := @Bellek1[$1BE];

            // b�l�m bilgisinin t�m�n�n tipini al ve destekleniyorsa disk listesine ekle
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

                // b�l�m�n ilk sekt�r�n� oku
                FizikselDepolamaAygitListesi[i].SektorOku(@FizikselDepolamaAygitListesi[i],
                  DiskBolum^.LBAIlkSektor, 1, @Bellek2);
                AcilisKayit1x := @Bellek2;

                // mant�ksal s�r�c� de�er tan�mlamalar�

                // mant�ksal s�r�c� i�in s�r�c� numaras� al
                SurucuNo := MantiksalDepolamaAygitNumarasiAl(SURUCUTIP_DISK);
                if(SurucuNo > -1) then
                begin

                  // mant�ksal s�r�c� olu�tur
                  MD := MantiksalDepolamaAygitiOlustur;
                  if not(MD = nil) then
                  begin

                    // mant�ksal s�r�c� bilgileri ata
                    MD^.FD := @FizikselDepolamaAygitListesi[i];
                    MD^.MD3.AygitAdi := 'disk' + IntToStr(SurucuNo);
                    {$IFDEF BOLUMLEME_BILGI}
                    SISTEM_MESAJ(RENK_YESIL, '  + Mant�ksal aygit: ' + MD^.MD3.AygitAdi, []);
                    {$ENDIF}
                    MD^.MD3.BolumIlkSektor := BolumIlkSektor;
                    MD^.MD3.BolumToplamSektor := BolumToplamSektor;
                    MD^.MD3.DST := DiskBolum^.BolumTipi;
                    MD^.MD3.SurucuTipi := FizikselDepolamaAygitListesi[i].FD3.SurucuTipi;

                    if(DiskBolum^.BolumTipi = DST_ELR1) then
                    begin

                      AcilisKayit32 := @Bellek2;

                      // DosyaAyirmaTablosu bilgileri
                      DosyaAyirmaTablosu := @MD^.Acilis.DosyaAyirmaTablosu;
                      DosyaAyirmaTablosu^.IlkSektor := AcilisKayit32^.AyrilmisSektor1 +
                        AcilisKayit32^.BolumOncesiSektorSayisi;
                      DosyaAyirmaTablosu^.ToplamSektor := AcilisKayit32^.DATBasinaSektor;
                      DosyaAyirmaTablosu^.ZincirBasinaSektor := 4; //AcilisKayit32^.ZincirBasinaSektor;

                      // DizinGirisi dizin giri�leri
                      DizinGirisi := @MD^.Acilis.DizinGirisi;
                      DizinGirisi^.IlkSektor := $1466; //5222; (AcilisKayit32^.DATBasinaSektor *
                        //AcilisKayit32^.DATSayisi) + AcilisKayit32^.AyrilmisSektor1 +
                        //AcilisKayit32^.BolumOncesiSektorSayisi;
                      DizinGirisi^.ToplamSektor := AcilisKayit32^.AzamiDizinGirisi div 16;

                      // fat32 dosya sisteminde dizin ba�lang�c� da veri olarak kullan�l�r
                      // fat32 dosya sisteminin dizin tablo biti� de�eri yoktur!
                      MD^.Acilis.IlkVeriSektorNo := DizinGirisi^.IlkSektor;
                    end
                    else if(DiskBolum^.BolumTipi = DST_FAT32) or
                      (DiskBolum^.BolumTipi = DST_FAT32LBA) then
                    begin

                      AcilisKayit32 := @Bellek2;

                      // DosyaAyirmaTablosu bilgileri
                      DosyaAyirmaTablosu := @MD^.Acilis.DosyaAyirmaTablosu;
                      DosyaAyirmaTablosu^.IlkSektor := AcilisKayit32^.AyrilmisSektor1 +
                        AcilisKayit32^.BolumOncesiSektorSayisi;
                      DosyaAyirmaTablosu^.ToplamSektor := AcilisKayit32^.DATBasinaSektor;
                      DosyaAyirmaTablosu^.ZincirBasinaSektor := AcilisKayit32^.ZincirBasinaSektor;

                      // DizinGirisi dizin giri�leri
                      DizinGirisi := @MD^.Acilis.DizinGirisi;
                      DizinGirisi^.IlkSektor := (AcilisKayit32^.DATBasinaSektor *
                        AcilisKayit32^.DATSayisi) + AcilisKayit32^.AyrilmisSektor1 +
                        AcilisKayit32^.BolumOncesiSektorSayisi;
                      DizinGirisi^.ToplamSektor := AcilisKayit32^.AzamiDizinGirisi div 16;

                      // fat32 dosya sisteminde dizin ba�lang�c� da veri olarak kullan�l�r
                      // fat32 dosya sisteminin dizin tablo biti� de�eri yoktur!
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

                      // DizinGirisi dizin giri�leri
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

                    Inc(MantiksalDepolamaAygitSayisi);
                  end;
                end;
              end else if not(DiskBolum^.BolumTipi = DST_BELIRSIZ) then
              begin

                SISTEM_MESAJ_S16(mtUyari, RENK_KIRMIZI, '  ! Bilinmeyen dosya sistem tipi: ', DiskBolum^.BolumTipi, 2);
              end;

              Inc(DiskBolum);
            end;
          end;
        end;
      end;
    end;
  end;
end;

{==============================================================================
  mant�ksal depolama ayg�t� olu�turma i�levi
 ==============================================================================}
function MantiksalDepolamaAygitiOlustur: PMantiksalDepolama;
var
  i: TSayi4;
begin

  // bo� bir mant�ksal s�r�c� yap�s� bul
  for i := 0 to 5 do
  begin

    if(MantiksalDepolamaAygitListesi[i].Mevcut = False) then
    begin

      MantiksalDepolamaAygitListesi[i].Mevcut := True;
      MantiksalDepolamaAygitListesi[i].MD3.Kimlik := MD_KIMLIK_ILKDEGER + i;
      Exit(@MantiksalDepolamaAygitListesi[i]);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  dosya yolundan s�r�c�y� bulur ve geriye s�r�c�ye ait bellek b�lgesini d�nd�r�r
  �u anda dosya yol bi�imi: disket1:\dosya.c �eklinde
 ==============================================================================}
function SurucuAl(ATamAdresYolu: string): PMantiksalDepolama;
var
  i: TSayi4;
  SurucuAdi: string;
begin

  // dosya yolunda s�r�c� belirtilmi� mi ?
  i := Pos(':', ATamAdresYolu);

  // e�er belirtilmi�se ...
  if(i > 0) then
  begin

    SurucuAdi := Copy(ATamAdresYolu, 1, i - 1);
  end else SurucuAdi := AcilisSurucuAygiti;

  // s�r�c� sistemde mevcut mu ?
  for i := 0 to 5 do
  begin

    if(MantiksalDepolamaAygitListesi[i].Mevcut) then
    begin

      if(MantiksalDepolamaAygitListesi[i].MD3.AygitAdi = SurucuAdi) then

        Exit(@MantiksalDepolamaAygitListesi[i]);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  mant�ksal depolama ayg�t� i�in say�sal s�ra numaras� al�r
 ==============================================================================}
function MantiksalDepolamaAygitNumarasiAl(ASurucuTipi: TSayi4): TISayi4;
var
  i: TSayi4;
begin

  // disket s�r�c�s� i�in
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

  // disk s�r�c�s� i�in
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

end.
