program dskbolum;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: dskbolum.lpr
  Program Ýþlevi: sistemdeki mantýksal sürücü bilgisini verir

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
uses n_gorev, gn_pencere, gn_dugme, n_depolama;

var
  Pencere: TPencere;
  dugDepolama: array[0..5] of TDugme;

const
  ProgramAdi: string = 'Depolama Aygýtý Bölüm Bilgisi';

  DepolamaAygitiBulunamadi: string  = 'Sistemde depolama aygýtý bulunamadý!';
  DepolamaAygitiSeciniz: string  = 'Lütfen bir depolama aygýtý seçiniz!';

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

  // sürücü kimliði
  Pencere.Tuval.KalemRengi := RENK_SIYAH;
  Pencere.Tuval.YaziYaz(0, 2 * 16, 'Sürücü Kimliði:');
  Pencere.Tuval.SayiYaz10(16 * 8, 2 * 16, MD^.Kimlik);

  // sürücü tipi
  Pencere.Tuval.KalemRengi := RENK_KIRMIZI;
  Pencere.Tuval.YaziYaz(0, 3 * 16, 'Sürücü Tipi   :');
  if(MD^.SurucuTipi = SURUCUTIP_DISKET) then
    Pencere.Tuval.YaziYaz(16 * 8, 3 * 16, 'Disket Sürücüsü')
  else if(MD^.SurucuTipi = SURUCUTIP_DISK) then
    Pencere.Tuval.YaziYaz(16 * 8, 3 * 16, 'Disk Sürücüsü')
  else Pencere.Tuval.YaziYaz(16 * 8, 3 * 16, 'Bilinmeyen Sürücü Tipi');

  // sürücü dosya sistemi
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

  // ilk sektör
  Pencere.Tuval.YaziYaz(0, 5 * 16, 'Ýlk Sektör    :');
  Pencere.Tuval.SayiYaz16(16 * 8, 5 * 16, False, 8, MD^.BolumIlkSektor);

  // toplam sektör
  Pencere.Tuval.YaziYaz(0, 6 * 16, 'Toplam Sektör :');
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
