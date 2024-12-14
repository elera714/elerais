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
  dugDepolama: array[1..6] of TDugme;

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
  MantiksalSurucuListesi: array[1..6] of TMantiksalSurucu3;

procedure AygitBilgileriniYaz(ASiraNo: TSayi4);
var
  MantiksalSurucu3: PMantiksalSurucu3;
begin

  MantiksalSurucu3 := @MantiksalSurucuListesi[ASiraNo];

  // sürücü tipi
  Pencere.Tuval.KalemRengi := RENK_SIYAH;
  Pencere.Tuval.YaziYaz(0, 2 * 16, 'Sürücü Tipi  :');
  if(MantiksalSurucu3^.SurucuTipi = SURUCUTIP_DISKET) then
    Pencere.Tuval.YaziYaz(15 * 8, 2 * 16, 'Disket Sürücüsü')
  else if(MantiksalSurucu3^.SurucuTipi = SURUCUTIP_DISK) then
    Pencere.Tuval.YaziYaz(15 * 8, 2 * 16, 'Disk Sürücüsü');

    // sürücü dosya sistemi
    Pencere.Tuval.YaziYaz(0, 3 * 16, 'Dosya Sistemi:');
    if(MantiksalSurucu3^.DosyaSistemTipi = DATTIP_FAT12) then
      Pencere.Tuval.YaziYaz(15 * 8, 3 * 16, 'FAT12')
    else if(MantiksalSurucu3^.DosyaSistemTipi = DATTIP_FAT16) then
      Pencere.Tuval.YaziYaz(15 * 8, 3 * 16, 'FAT16')
    else if(MantiksalSurucu3^.DosyaSistemTipi = DATTIP_FAT32) then
      Pencere.Tuval.YaziYaz(15 * 8, 3 * 16, 'FAT32')
    else if(MantiksalSurucu3^.DosyaSistemTipi = DATTIP_FAT32LBA) then
      Pencere.Tuval.YaziYaz(15 * 8, 3 * 16, 'FAT32+LBA');

  // ilk sektör
  Pencere.Tuval.YaziYaz(0, 4 * 16, 'Ýlk Sektör   :');
  Pencere.Tuval.SayiYaz16(15 * 8, 4 * 16, False, 8, MantiksalSurucu3^.BolumIlkSektor);

  // toplam sektör
  Pencere.Tuval.YaziYaz(0, 5 * 16, 'Toplam Sektör:');
  Pencere.Tuval.SayiYaz16(15 * 8, 5 * 16, False, 8, MantiksalSurucu3^.BolumToplamSektor);
end;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 50, 50, 310, 95, ptBoyutlanabilir, ProgramAdi, $EEF0D1);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  DiskSayisi := Depolama.MantiksalDepolamaAygitSayisiAl;
  if(DiskSayisi > 0) then
  begin

    DugmeA1 := 2;
    for i := 1 to DiskSayisi do
    begin

      if(Depolama.MantiksalDepolamaAygitBilgisiAl(i, @MantiksalSurucuListesi[i])) then
      begin

        dugDepolama[i].Olustur(Pencere.Kimlik, DugmeA1, 2, 65, 22,
          MantiksalSurucuListesi[i].AygitAdi);
        dugDepolama[i].Etiket := i;
        dugDepolama[i].Goster;
        DugmeA1 += 70;
      end else dugDepolama[i].Etiket := 0;
    end;
  end;

  Pencere.Gorunum := True;

  SeciliDisk := 0;

  while True do
  begin

    Gorev.OlayBekle(Olay);
    if(Olay.Olay = FO_TIKLAMA) then
    begin

      for i := 1 to 6 do
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

        if(SeciliDisk = 0) then
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
