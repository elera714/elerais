program dskbolum;
{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: dskbolum.lpr
  Program ��levi: sistemdeki mant�ksal s�r�c� bilgisini verir

  G�ncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
uses n_gorev, gn_pencere, gn_dugme, n_depolama;

var
  Pencere: TPencere;
  dugDepolama: array[0..5] of TDugme;

const
  ProgramAdi: string = 'Depolama Ayg�t� B�l�m Bilgisi';

  DepolamaAygitiBulunamadi: string  = 'Sistemde depolama ayg�t� bulunamad�!';
  DepolamaAygitiSeciniz: string  = 'L�tfen bir depolama ayg�t� se�iniz!';

var
  Gorev: TGorev;
  Depolama: TDepolama;
  Olay: TOlay;
  DiskSayisi, SeciliDisk,
  DugmeA1, i: TISayi4;
  MantiksalDepolamaListesi: array[0..5] of TMantiksalDepolama3;

procedure AygitBilgileriniYaz(ASiraNo: TSayi4);
var
  MD: PMantiksalDepolama3;
begin

  MD := @MantiksalDepolamaListesi[ASiraNo];

  // s�r�c� kimli�i
  Pencere.Tuval.KalemRengi := RENK_SIYAH;
  Pencere.Tuval.YaziYaz(0, 2 * 16, 'S�r�c� Kimli�i:');
  Pencere.Tuval.SayiYaz10(16 * 8, 2 * 16, MD^.Kimlik);

  // s�r�c� tipi
  Pencere.Tuval.KalemRengi := RENK_KIRMIZI;
  Pencere.Tuval.YaziYaz(0, 3 * 16, 'S�r�c� Tipi   :');
  if(MD^.SurucuTipi = SURUCUTIP_DISKET) then
    Pencere.Tuval.YaziYaz(16 * 8, 3 * 16, 'Disket S�r�c�s�')
  else if(MD^.SurucuTipi = SURUCUTIP_DISK) then
    Pencere.Tuval.YaziYaz(16 * 8, 3 * 16, 'Disk S�r�c�s�')
  else Pencere.Tuval.YaziYaz(16 * 8, 3 * 16, 'Bilinmeyen S�r�c� Tipi');

  // s�r�c� dosya sistemi
  Pencere.Tuval.KalemRengi := RENK_SIYAH;
  Pencere.Tuval.YaziYaz(0, 4 * 16, 'Dosya Sistemi :');
  if(MD^.DosyaSistemTipi = DATTIP_FAT12) then
    Pencere.Tuval.YaziYaz(16 * 8, 4 * 16, 'FAT12')
  else if(MD^.DosyaSistemTipi = DATTIP_FAT16) then
    Pencere.Tuval.YaziYaz(16 * 8, 4 * 16, 'FAT16')
  else if(MD^.DosyaSistemTipi = DATTIP_FAT32) then
    Pencere.Tuval.YaziYaz(16 * 8, 4 * 16, 'FAT32')
  else if(MD^.DosyaSistemTipi = DATTIP_FAT32LBA) then
    Pencere.Tuval.YaziYaz(16 * 8, 4 * 16, 'FAT32+LBA')
  else Pencere.Tuval.YaziYaz(16 * 8, 4 * 16, 'Bilinmeyen Dosya Sistemi');

  // ilk sekt�r
  Pencere.Tuval.YaziYaz(0, 5 * 16, '�lk Sekt�r    :');
  Pencere.Tuval.SayiYaz16(16 * 8, 5 * 16, False, 8, MD^.BolumIlkSektor);

  // toplam sekt�r
  Pencere.Tuval.YaziYaz(0, 6 * 16, 'Toplam Sekt�r :');
  Pencere.Tuval.SayiYaz16(16 * 8, 6 * 16, False, 8, MD^.BolumToplamSektor);
end;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 50, 50, 400, 115, ptBoyutlanabilir, ProgramAdi, $EEF0D1);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  DiskSayisi := Depolama.MantiksalDepolamaAygitSayisiAl;
  if(DiskSayisi > 0) then
  begin

    DugmeA1 := 2;
    for i := 0 to DiskSayisi - 1 do
    begin

      if(Depolama.MantiksalDepolamaAygitBilgisiAl(i, @MantiksalDepolamaListesi[i])) then
      begin

        dugDepolama[i].Olustur(Pencere.Kimlik, DugmeA1, 2, 65, 22, MantiksalDepolamaListesi[i].AygitAdi);
        dugDepolama[i].Etiket := i;
        dugDepolama[i].Goster;
        DugmeA1 += 70;
      end else dugDepolama[i].Etiket := -1;
    end;
  end;

  Pencere.Gorunum := True;

  SeciliDisk := -1;

  while True do
  begin

    Gorev.OlayBekle(Olay);
    if(Olay.Olay = FO_TIKLAMA) then
    begin

      for i := 0 to 5 do
      begin

        if(dugDepolama[i].Kimlik = Olay.Kimlik) then
        begin

          SeciliDisk := dugDepolama[i].Etiket;
          Break;
        end;
      end;

      Pencere.Ciz;
    end

    else if(Olay.Olay = CO_CIZIM) then
    begin

      if(DiskSayisi = 0) then
      begin

        Pencere.Tuval.KalemRengi := RENK_KIRMIZI;
        Pencere.Tuval.YaziYaz(0, 0 * 16, DepolamaAygitiBulunamadi);
      end
      else
      begin

        if(SeciliDisk = -1) then
        begin

          Pencere.Tuval.KalemRengi := RENK_KIRMIZI;
          Pencere.Tuval.YaziYaz(0, 2 * 16, DepolamaAygitiSeciniz);
        end
        else
        begin

          AygitBilgileriniYaz(SeciliDisk);
        end;
      end;
    end;
  end;
end.
