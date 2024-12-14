{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: bolumleme.pas
  Dosya Ýþlevi: depolama aygýtý bölüm yönetim iþlevlerini içerir

  Güncelleme Tarihi: 03/09/2024

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
  depolama aygýtý mantýksal sürücü atama iþlevlerini yerine getirir
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

  // mantýksal sürücü deðiþkenlerini ilk deðerlerle yükle
  MantiksalDepolamaAygitSayisi := 0;
  for i := 1 to 6 do
  begin

    MantiksalDepolamaAygitListesi[i].AygitMevcut := False;
  end;

  // mantýksal disket sürücü numara üreticisini sýfýrla
  for i := 1 to 2 do
  begin

    MantiksalDisketHavuzListesi[i] := 0;
  end;

  // mantýksal disk sürücü numara üreticisini sýfýrla
  for i := 1 to 4 do
  begin

    MantiksalDiskHavuzListesi[i] := 0;
  end;

  // sistemde fiziksel depolama aygýtý var ise
  if(FizikselDepolamaAygitSayisi > 0) then
  begin

    // tüm aygýtlarý denetle. (toplam 6 fiziksel aygýt)
    for i := 1 to 6 do
    begin

      // eðer aygýt mevcut ise ...
      if(FizikselDepolamaAygitListesi[i].Mevcut) then
      begin

        // aygýt disket sürücüsü ise ...
        if(FizikselDepolamaAygitListesi[i].SurucuTipi = SURUCUTIP_DISKET) then
        begin

          // disketin ilk sektörünü oku
          if(FizikselDepolamaAygitListesi[i].SektorOku(@FizikselDepolamaAygitListesi[i],
            0, 1, @_Bellek1)) then
          begin

            // okunan bilgi yapýsýna konumlan
            _AcilisKayit1x := @_Bellek1;

            // eðer dosya sistemi FAT12 ise...
            if(_AcilisKayit1x^.DosyaSistemEtiket = 'FAT12   ') then
            begin

              // mantýksal sürücü için sürücü numarasý al
              _SurucuNo := MantiksalSurucuNumarasiAl(SURUCUTIP_DISKET);
              if(_SurucuNo > -1) then
              begin

                // mantýksal sürücü oluþtur
                _MantiksalSurucu := MantiksalSurucuOlustur;
                if not(_MantiksalSurucu = nil) then
                begin

                  // mantýksal sürücü bilgileri ata
                  _MantiksalSurucu^.FizikselSurucu := @FizikselDepolamaAygitListesi[i];
                  _MantiksalSurucu^.AygitAdi := 'disket' + IntToStr(_SurucuNo);
                  {$IFDEF BOLUMLEME_BILGI}
                  SISTEM_MESAJ(RENK_YESIL, '  + Mantýksal aygýt: ' + _MantiksalSurucu^.AygitAdi, []);
                  {$ENDIF}
                  _MantiksalSurucu^.BolumIlkSektor := _AcilisKayit1x^.BolumOncesiSektorSayisi;
                  _MantiksalSurucu^.BolumToplamSektor := _AcilisKayit1x^.ToplamSektorSayisi1x;
                  _MantiksalSurucu^.BolumTipi := DATTIP_FAT12;

                  // _DizinGirisi dizin giriþleri
                  _DizinGirisi := @_MantiksalSurucu^.Acilis.DizinGirisi;
                  _DizinGirisi^.IlkSektor := (_AcilisKayit1x^.DATBasinaSektor *
                    _AcilisKayit1x^.DATSayisi) + _AcilisKayit1x^.AyrilmisSektor1;
                  _DizinGirisi^.GirdiSayisi := 16;    // 512 / 32 = 16
                  _DizinGirisi^.ToplamSektor := (_AcilisKayit1x^.AzamiDizinGirisi
                    div _DizinGirisi^.GirdiSayisi);

                  // dosya ayýrma tablosu bilgileri
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

        // aygýt disk sürücüsü ise ...
        else if(FizikselDepolamaAygitListesi[i].SurucuTipi = SURUCUTIP_DISK) then
        begin

          // diskin ilk sektörünü (MBR) oku
          if(FizikselDepolamaAygitListesi[i].SektorOku(@FizikselDepolamaAygitListesi[i],
            0, 1, @_Bellek1)) then
          begin

            // bölümleme bilgisine konumlan
            _DiskBolum := @_Bellek1[$1BE];

            // bölüm bilgisinin tümünün tipini al ve destekleniyorsa disk listesine ekle
            for _BolumSayisi := 1 to 4 do
            begin

              if(_DiskBolum^.BolumTipi = DATTIP_FAT12) or
                (_DiskBolum^.BolumTipi = DATTIP_FAT16) or
                (_DiskBolum^.BolumTipi = DATTIP_FAT32) or
                (_DiskBolum^.BolumTipi = DATTIP_FAT32LBA) then
              begin

                _BolumIlkSektor := _DiskBolum^.LBAIlkSektor;
                _BolumToplamSektor := _DiskBolum^.BolumSektorSayisi;

                // bölümün ilk sektörünü oku
                FizikselDepolamaAygitListesi[i].SektorOku(@FizikselDepolamaAygitListesi[i],
                  _DiskBolum^.LBAIlkSektor, 1, @_Bellek2);
                _AcilisKayit1x := @_Bellek2;

                // mantýksal sürücü deðer tanýmlamalarý

                // mantýksal sürücü için sürücü numarasý al
                _SurucuNo := MantiksalSurucuNumarasiAl(SURUCUTIP_DISK);
                if(_SurucuNo > -1) then
                begin

                  // mantýksal sürücü oluþtur
                  _MantiksalSurucu := MantiksalSurucuOlustur;
                  if not(_MantiksalSurucu = nil) then
                  begin

                    // mantýksal sürücü bilgileri ata
                    _MantiksalSurucu^.FizikselSurucu := @FizikselDepolamaAygitListesi[i];
                    _MantiksalSurucu^.AygitAdi := 'disk' + IntToStr(_SurucuNo);
                    {$IFDEF BOLUMLEME_BILGI}
                    SISTEM_MESAJ(RENK_YESIL, '  + Mantýksal aygit: ' + _MantiksalSurucu^.AygitAdi, []);
                    {$ENDIF}
                    _MantiksalSurucu^.BolumIlkSektor := _BolumIlkSektor;
                    _MantiksalSurucu^.BolumToplamSektor := _BolumToplamSektor;
                    _MantiksalSurucu^.BolumTipi := _DiskBolum^.BolumTipi;

                    if(_DiskBolum^.BolumTipi = DATTIP_FAT32) or
                      (_DiskBolum^.BolumTipi = DATTIP_FAT32LBA) then
                    begin

                      _AcilisKayit32 := @_Bellek2;

                      // _DizinGirisi dizin giriþleri
                      _DizinGirisi := @_MantiksalSurucu^.Acilis.DizinGirisi;
                      _DizinGirisi^.IlkSektor := (_AcilisKayit32^.DATBasinaSektor *
                        _AcilisKayit32^.DATSayisi) + _AcilisKayit32^.AyrilmisSektor1 +
                        _AcilisKayit32^.BolumOncesiSektorSayisi;
                      _DizinGirisi^.GirdiSayisi := 16;    // 512 / 32 = 16
                      _DizinGirisi^.ToplamSektor := 100; // geçici deðer  (_AcilisKayit32^.AzamiDizinGirisi div _DizinGirisi^.GirdiSayisi);

                      // _DosyaAyirmaTablosu bilgileri
                      _DosyaAyirmaTablosu := @_MantiksalSurucu^.Acilis.DosyaAyirmaTablosu;
                      _DosyaAyirmaTablosu^.IlkSektor := _AcilisKayit32^.BolumOncesiSektorSayisi +
                        _AcilisKayit32^.AyrilmisSektor1;
                      _DosyaAyirmaTablosu^.ToplamSektor := _AcilisKayit32^.DATBasinaSektor;
                      _DosyaAyirmaTablosu^.KumeBasinaSektor := _AcilisKayit32^.ZincirBasinaSektor;
                      // fat32 dosya sistemi için geçerli deðil
                      _DosyaAyirmaTablosu^.IlkVeriSektoru := _DizinGirisi^.IlkSektor; //(_DizinGirisi^.IlkSektor + _DizinGirisi^.ToplamSektor);
                    end
                    else
                    begin

                      // _DizinGirisi dizin giriþleri
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
  mantýksal sürücü oluþturma iþlevi
 ==============================================================================}
function MantiksalSurucuOlustur: PMantiksalSurucu;
var
  i: TSayi4;
begin

  // boþ bir mantýksal sürücü yapýsý bul
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
  dosya yolundan sürücüyü bulur ve geriye sürücüye ait bellek bölgesini döndürür
  þu anda dosya yol biçimi: disket1:\dosya.c þeklinde
 ==============================================================================}
function SurucuAl(ATamAdresYolu: string; var AKalinanSira: Integer): PMantiksalSurucu;
var
  i: TSayi4;
  _SurucuAdi: string;
begin

  // dosya yolunda sürücü belirtilmiþ mi ?
  i := Pos(':', ATamAdresYolu);

  AKalinanSira := 0;

  // eðer belirtilmiþse ...
  if(i > 0) then
  begin

    _SurucuAdi := Copy(ATamAdresYolu, 1, i - 1);
    AKalinanSira := i + 1;
  end else _SurucuAdi := AcilisSurucuAygiti;

  // sürücü sistemde mevcut mu ?
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
  sürücüler için sayýsal sýra numarasý saðlar
 ==============================================================================}
function MantiksalSurucuNumarasiAl(ASurucuTip: TSayi4): TISayi4;
var
  i: TSayi4;
begin

  // disket sürücüsü için
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

  // disk sürücüsü için
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
