{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: bolumleme.pas
  Dosya ��levi: depolama ayg�t� b�l�m y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 03/09/2024

 ==============================================================================}
{$mode objfpc}
{$DEFINE BOLUMLEME_BILGI}
unit bolumleme;

interface

uses paylasim;

var
  MantiksalDisketHavuzListesi: array[1..2] of Integer;    // disket numaralama listesi
  MantiksalDiskHavuzListesi: array[1..4] of Integer;      // disk numaralama listesi

procedure Yukle;
function MantiksalSurucuOlustur: PMantiksalSurucu;
function SurucuAl(ATamAdresYolu: string; var AKalinanSira: Integer): PMantiksalSurucu;
function MantiksalSurucuNumarasiAl(ASurucuTip: TSayi4): TISayi4;

implementation

uses donusum, sistemmesaj;

{==============================================================================
  depolama ayg�t� mant�ksal s�r�c� atama i�levlerini yerine getirir
 ==============================================================================}
procedure Yukle;
var
  _MantiksalSurucu: PMantiksalSurucu;
  _DiskBolum: PDiskBolum;
  _AcilisKayit1x: PAcilisKayit1x;
  _AcilisKayit32: PAcilisKayit32;
  _DosyaAyirmaTablosu: PDosyaAyirmaTablosu;
  _DizinGirisi: PDizinGirisi;
  _Bellek1: array[0..511] of TSayi1;
  _Bellek2: array[0..511] of TSayi1;
  _SurucuNo, i, _BolumSayisi: TISayi4;
  _BolumIlkSektor, _BolumToplamSektor: TSayi4;
begin

  // mant�ksal s�r�c� de�i�kenlerini ilk de�erlerle y�kle
  MantiksalDepolamaAygitSayisi := 0;
  for i := 1 to 6 do
  begin

    MantiksalDepolamaAygitListesi[i].AygitMevcut := False;
  end;

  // mant�ksal disket s�r�c� numara �reticisini s�f�rla
  for i := 1 to 2 do
  begin

    MantiksalDisketHavuzListesi[i] := 0;
  end;

  // mant�ksal disk s�r�c� numara �reticisini s�f�rla
  for i := 1 to 4 do
  begin

    MantiksalDiskHavuzListesi[i] := 0;
  end;

  // sistemde fiziksel depolama ayg�t� var ise
  if(FizikselDepolamaAygitSayisi > 0) then
  begin

    // t�m ayg�tlar� denetle. (toplam 6 fiziksel ayg�t)
    for i := 1 to 6 do
    begin

      // e�er ayg�t mevcut ise ...
      if(FizikselDepolamaAygitListesi[i].Mevcut) then
      begin

        // ayg�t disket s�r�c�s� ise ...
        if(FizikselDepolamaAygitListesi[i].SurucuTipi = SURUCUTIP_DISKET) then
        begin

          // disketin ilk sekt�r�n� oku
          if(FizikselDepolamaAygitListesi[i].SektorOku(@FizikselDepolamaAygitListesi[i],
            0, 1, @_Bellek1)) then
          begin

            // okunan bilgi yap�s�na konumlan
            _AcilisKayit1x := @_Bellek1;

            // e�er dosya sistemi FAT12 ise...
            if(_AcilisKayit1x^.DosyaSistemEtiket = 'FAT12   ') then
            begin

              // mant�ksal s�r�c� i�in s�r�c� numaras� al
              _SurucuNo := MantiksalSurucuNumarasiAl(SURUCUTIP_DISKET);
              if(_SurucuNo > -1) then
              begin

                // mant�ksal s�r�c� olu�tur
                _MantiksalSurucu := MantiksalSurucuOlustur;
                if not(_MantiksalSurucu = nil) then
                begin

                  // mant�ksal s�r�c� bilgileri ata
                  _MantiksalSurucu^.FizikselSurucu := @FizikselDepolamaAygitListesi[i];
                  _MantiksalSurucu^.AygitAdi := 'disket' + IntToStr(_SurucuNo);
                  {$IFDEF BOLUMLEME_BILGI}
                  SISTEM_MESAJ(RENK_YESIL, '  + Mant�ksal ayg�t: ' + _MantiksalSurucu^.AygitAdi, []);
                  {$ENDIF}
                  _MantiksalSurucu^.BolumIlkSektor := _AcilisKayit1x^.BolumOncesiSektorSayisi;
                  _MantiksalSurucu^.BolumToplamSektor := _AcilisKayit1x^.ToplamSektorSayisi1x;
                  _MantiksalSurucu^.BolumTipi := DATTIP_FAT12;

                  // _DizinGirisi dizin giri�leri
                  _DizinGirisi := @_MantiksalSurucu^.Acilis.DizinGirisi;
                  _DizinGirisi^.IlkSektor := (_AcilisKayit1x^.DATBasinaSektor *
                    _AcilisKayit1x^.DATSayisi) + _AcilisKayit1x^.AyrilmisSektor1;
                  _DizinGirisi^.GirdiSayisi := 16;    // 512 / 32 = 16
                  _DizinGirisi^.ToplamSektor := (_AcilisKayit1x^.AzamiDizinGirisi
                    div _DizinGirisi^.GirdiSayisi);

                  // dosya ay�rma tablosu bilgileri
                  _DosyaAyirmaTablosu := @_MantiksalSurucu^.Acilis.DosyaAyirmaTablosu;
                  _DosyaAyirmaTablosu^.IlkSektor := _AcilisKayit1x^.AyrilmisSektor1;
                  _DosyaAyirmaTablosu^.ToplamSektor := _AcilisKayit1x^.DATBasinaSektor;
                  _DosyaAyirmaTablosu^.KumeBasinaSektor := _AcilisKayit1x^.ZincirBasinaSektor;
                  _DosyaAyirmaTablosu^.IlkVeriSektoru := (_DizinGirisi^.IlkSektor +
                    _DizinGirisi^.ToplamSektor);

                  Inc(MantiksalDepolamaAygitSayisi);
                end;
              end;
            end;
          end;
        end

        // ayg�t disk s�r�c�s� ise ...
        else if(FizikselDepolamaAygitListesi[i].SurucuTipi = SURUCUTIP_DISK) then
        begin

          // diskin ilk sekt�r�n� (MBR) oku
          if(FizikselDepolamaAygitListesi[i].SektorOku(@FizikselDepolamaAygitListesi[i],
            0, 1, @_Bellek1)) then
          begin

            // b�l�mleme bilgisine konumlan
            _DiskBolum := @_Bellek1[$1BE];

            // b�l�m bilgisinin t�m�n�n tipini al ve destekleniyorsa disk listesine ekle
            for _BolumSayisi := 1 to 4 do
            begin

              if(_DiskBolum^.BolumTipi = DATTIP_FAT12) or
                (_DiskBolum^.BolumTipi = DATTIP_FAT16) or
                (_DiskBolum^.BolumTipi = DATTIP_FAT32) or
                (_DiskBolum^.BolumTipi = DATTIP_FAT32LBA) then
              begin

                _BolumIlkSektor := _DiskBolum^.LBAIlkSektor;
                _BolumToplamSektor := _DiskBolum^.BolumSektorSayisi;

                // b�l�m�n ilk sekt�r�n� oku
                FizikselDepolamaAygitListesi[i].SektorOku(@FizikselDepolamaAygitListesi[i],
                  _DiskBolum^.LBAIlkSektor, 1, @_Bellek2);
                _AcilisKayit1x := @_Bellek2;

                // mant�ksal s�r�c� de�er tan�mlamalar�

                // mant�ksal s�r�c� i�in s�r�c� numaras� al
                _SurucuNo := MantiksalSurucuNumarasiAl(SURUCUTIP_DISK);
                if(_SurucuNo > -1) then
                begin

                  // mant�ksal s�r�c� olu�tur
                  _MantiksalSurucu := MantiksalSurucuOlustur;
                  if not(_MantiksalSurucu = nil) then
                  begin

                    // mant�ksal s�r�c� bilgileri ata
                    _MantiksalSurucu^.FizikselSurucu := @FizikselDepolamaAygitListesi[i];
                    _MantiksalSurucu^.AygitAdi := 'disk' + IntToStr(_SurucuNo);
                    {$IFDEF BOLUMLEME_BILGI}
                    SISTEM_MESAJ(RENK_YESIL, '  + Mant�ksal aygit: ' + _MantiksalSurucu^.AygitAdi, []);
                    {$ENDIF}
                    _MantiksalSurucu^.BolumIlkSektor := _BolumIlkSektor;
                    _MantiksalSurucu^.BolumToplamSektor := _BolumToplamSektor;
                    _MantiksalSurucu^.BolumTipi := _DiskBolum^.BolumTipi;

                    if(_DiskBolum^.BolumTipi = DATTIP_FAT32) or
                      (_DiskBolum^.BolumTipi = DATTIP_FAT32LBA) then
                    begin

                      _AcilisKayit32 := @_Bellek2;

                      // _DizinGirisi dizin giri�leri
                      _DizinGirisi := @_MantiksalSurucu^.Acilis.DizinGirisi;
                      _DizinGirisi^.IlkSektor := (_AcilisKayit32^.DATBasinaSektor *
                        _AcilisKayit32^.DATSayisi) + _AcilisKayit32^.AyrilmisSektor1 +
                        _AcilisKayit32^.BolumOncesiSektorSayisi;
                      _DizinGirisi^.GirdiSayisi := 16;    // 512 / 32 = 16
                      _DizinGirisi^.ToplamSektor := 100; // ge�ici de�er  (_AcilisKayit32^.AzamiDizinGirisi div _DizinGirisi^.GirdiSayisi);

                      // _DosyaAyirmaTablosu bilgileri
                      _DosyaAyirmaTablosu := @_MantiksalSurucu^.Acilis.DosyaAyirmaTablosu;
                      _DosyaAyirmaTablosu^.IlkSektor := _AcilisKayit32^.BolumOncesiSektorSayisi +
                        _AcilisKayit32^.AyrilmisSektor1;
                      _DosyaAyirmaTablosu^.ToplamSektor := _AcilisKayit32^.DATBasinaSektor;
                      _DosyaAyirmaTablosu^.KumeBasinaSektor := _AcilisKayit32^.ZincirBasinaSektor;
                      // fat32 dosya sistemi i�in ge�erli de�il
                      _DosyaAyirmaTablosu^.IlkVeriSektoru := _DizinGirisi^.IlkSektor; //(_DizinGirisi^.IlkSektor + _DizinGirisi^.ToplamSektor);
                    end
                    else
                    begin

                      // _DizinGirisi dizin giri�leri
                      _DizinGirisi := @_MantiksalSurucu^.Acilis.DizinGirisi;
                      _DizinGirisi^.IlkSektor := (_AcilisKayit1x^.DATBasinaSektor *
                        _AcilisKayit1x^.DATSayisi) + _AcilisKayit1x^.AyrilmisSektor1 +
                        _AcilisKayit1x^.BolumOncesiSektorSayisi;
                      _DizinGirisi^.GirdiSayisi := 16;    // 512 / 32 = 16
                      _DizinGirisi^.ToplamSektor := (_AcilisKayit1x^.AzamiDizinGirisi div
                        _DizinGirisi^.GirdiSayisi);

                      // _DosyaAyirmaTablosu bilgileri
                      _DosyaAyirmaTablosu := @_MantiksalSurucu^.Acilis.DosyaAyirmaTablosu;
                      _DosyaAyirmaTablosu^.IlkSektor := _AcilisKayit1x^.BolumOncesiSektorSayisi +
                        _AcilisKayit1x^.AyrilmisSektor1;
                      _DosyaAyirmaTablosu^.ToplamSektor := _AcilisKayit1x^.DATBasinaSektor;
                      _DosyaAyirmaTablosu^.KumeBasinaSektor := _AcilisKayit1x^.ZincirBasinaSektor;
                      _DosyaAyirmaTablosu^.IlkVeriSektoru := (_DizinGirisi^.IlkSektor +
                        _DizinGirisi^.ToplamSektor);
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
              end else if not(_DiskBolum^.BolumTipi = DATTIP_BELIRSIZ) then
              begin

                SISTEM_MESAJ_S16(RENK_KIRMIZI, '  ! Bilinmeyen DAT Tipi: ', _DiskBolum^.BolumTipi, 2);
              end;

              Inc(_DiskBolum);
            end;
          end;
        end;
      end;
    end;
  end;
end;

{==============================================================================
  mant�ksal s�r�c� olu�turma i�levi
 ==============================================================================}
function MantiksalSurucuOlustur: PMantiksalSurucu;
var
  i: TSayi4;
begin

  // bo� bir mant�ksal s�r�c� yap�s� bul
  for i := 1 to 6 do
  begin

    if(MantiksalDepolamaAygitListesi[i].AygitMevcut = False) then
    begin

      MantiksalDepolamaAygitListesi[i].AygitMevcut := True;
      Exit(@MantiksalDepolamaAygitListesi[i]);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  dosya yolundan s�r�c�y� bulur ve geriye s�r�c�ye ait bellek b�lgesini d�nd�r�r
  �u anda dosya yol bi�imi: disket1:\dosya.c �eklinde
 ==============================================================================}
function SurucuAl(ATamAdresYolu: string; var AKalinanSira: Integer): PMantiksalSurucu;
var
  i: TSayi4;
  _SurucuAdi: string;
begin

  // dosya yolunda s�r�c� belirtilmi� mi ?
  i := Pos(':', ATamAdresYolu);

  AKalinanSira := 0;

  // e�er belirtilmi�se ...
  if(i > 0) then
  begin

    _SurucuAdi := Copy(ATamAdresYolu, 1, i - 1);
    AKalinanSira := i + 1;
  end else _SurucuAdi := AcilisSurucuAygiti;

  // s�r�c� sistemde mevcut mu ?
  for i := 1 to 6 do
  begin

    if(MantiksalDepolamaAygitListesi[i].AygitMevcut) then
    begin

      if(MantiksalDepolamaAygitListesi[i].AygitAdi = _SurucuAdi) then

        Exit(@MantiksalDepolamaAygitListesi[i]);
    end;
  end;

  Result := nil;
end;

{==============================================================================
  s�r�c�ler i�in say�sal s�ra numaras� sa�lar
 ==============================================================================}
function MantiksalSurucuNumarasiAl(ASurucuTip: TSayi4): TISayi4;
var
  i: TSayi4;
begin

  // disket s�r�c�s� i�in
  if(ASurucuTip = SURUCUTIP_DISKET) then
  begin

    for i := 1 to 2 do
    begin

      if(MantiksalDisketHavuzListesi[i] = 0) then
      begin

        MantiksalDisketHavuzListesi[i] := 1;
        Exit(i);
      end;
    end;
  end

  // disk s�r�c�s� i�in
  else if(ASurucuTip = SURUCUTIP_DISK) then
  begin

    for i := 1 to 4 do
    begin

      if(MantiksalDiskHavuzListesi[i] = 0) then
      begin

        MantiksalDiskHavuzListesi[i] := 1;
        Exit(i);
      end;
    end;
  end;

  Result := -1;
end;

end.
