{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, _forms, gn_dugme, n_depolama;

type
  TfrmAnaSayfa = object(TForm)
  private
    FPencere: TPencere;
    FDDepolama: array[0..5] of TDugme;
    FGorev: TGorev;
    FDepolama: TDepolama;
    procedure AygitBilgileriniYaz(ASiraNo: TSayi4);
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Depolama Aygýtý Bölüm Bilgisi';
  DepolamaAygitiBulunamadi: string  = 'Sistemde depolama aygýtý bulunamadý!';
  DepolamaAygitiSeciniz: string  = 'Lütfen bir depolama aygýtý seçiniz!';

var
  DiskSayisi, SeciliDisk,
  DugmeA1, i: TISayi4;
  MantiksalDepolamaListesi: array[0..5] of TMantiksalDepolama3;

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 50, 50, 400, 115, ptBoyutlanabilir, PencereAdi, $EEF0D1);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  DiskSayisi := FDepolama.MantiksalDepolamaAygitSayisiAl;
  if(DiskSayisi > 0) then
  begin

    DugmeA1 := 2;
    for i := 0 to DiskSayisi - 1 do
    begin

      if(FDepolama.MantiksalDepolamaAygitBilgisiAl(i, @MantiksalDepolamaListesi[i])) then
      begin

        FDDepolama[i].Olustur(FPencere.Kimlik, DugmeA1, 2, 65, 22, MantiksalDepolamaListesi[i].AygitAdi);
        FDDepolama[i].Etiket := i;
        FDDepolama[i].Goster;
        DugmeA1 += 70;
      end else FDDepolama[i].Etiket := -1;
    end;
  end;

  SeciliDisk := -1;
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  // çekirdek tarafýndan gönderilen programýn kendisini sonlandýrma talimatý
  if(AOlay.Olay = CO_SONLANDIR) then
  begin

    FGorev.Sonlandir(-1);
  end
  else if(AOlay.Olay = FO_TIKLAMA) then
  begin

    for i := 0 to 5 do
    begin

      if(FDDepolama[i].Kimlik = AOlay.Kimlik) then
      begin

        SeciliDisk := FDDepolama[i].Etiket;
        Break;
      end;
    end;

    FPencere.Ciz;
  end

  else if(AOlay.Olay = CO_CIZIM) then
  begin

    if(DiskSayisi = 0) then
    begin

      FPencere.Tuval.KalemRengi := RENK_KIRMIZI;
      FPencere.Tuval.YaziYaz(0, 0 * 16, DepolamaAygitiBulunamadi);
    end
    else
    begin

      if(SeciliDisk = -1) then
      begin

        FPencere.Tuval.KalemRengi := RENK_KIRMIZI;
        FPencere.Tuval.YaziYaz(0, 2 * 16, DepolamaAygitiSeciniz);
      end
      else
      begin

        AygitBilgileriniYaz(SeciliDisk);
      end;
    end;
  end;

  Result := 1;
end;

procedure TfrmAnaSayfa.AygitBilgileriniYaz(ASiraNo: TSayi4);
var
  MD: PMantiksalDepolama3;
begin

  MD := @MantiksalDepolamaListesi[ASiraNo];

  // sürücü kimliði
  FPencere.Tuval.KalemRengi := RENK_SIYAH;
  FPencere.Tuval.YaziYaz(0, 2 * 16, 'Sürücü Kimliði:');
  FPencere.Tuval.SayiYaz10(16 * 8, 2 * 16, MD^.Kimlik);

  // sürücü tipi
  FPencere.Tuval.KalemRengi := RENK_KIRMIZI;
  FPencere.Tuval.YaziYaz(0, 3 * 16, 'Sürücü Tipi   :');
  if(MD^.SurucuTipi = SURUCUTIP_DISKET) then
    FPencere.Tuval.YaziYaz(16 * 8, 3 * 16, 'Disket Sürücüsü')
  else if(MD^.SurucuTipi = SURUCUTIP_DISK) then
    FPencere.Tuval.YaziYaz(16 * 8, 3 * 16, 'Disk Sürücüsü')
  else FPencere.Tuval.YaziYaz(16 * 8, 3 * 16, 'Bilinmeyen Sürücü Tipi');

  // sürücü dosya sistemi
  FPencere.Tuval.KalemRengi := RENK_SIYAH;
  FPencere.Tuval.YaziYaz(0, 4 * 16, 'Dosya Sistemi :');
  if(MD^.DosyaSistemTipi = DST_ELR1) then
    FPencere.Tuval.YaziYaz(16 * 8, 4 * 16, 'ELR-1')
  else if(MD^.DosyaSistemTipi = DST_FAT12) then
    FPencere.Tuval.YaziYaz(16 * 8, 4 * 16, 'FAT12')
  else if(MD^.DosyaSistemTipi = DST_FAT16) then
    FPencere.Tuval.YaziYaz(16 * 8, 4 * 16, 'FAT16')
  else if(MD^.DosyaSistemTipi = DST_FAT32) then
    FPencere.Tuval.YaziYaz(16 * 8, 4 * 16, 'FAT32')
  else if(MD^.DosyaSistemTipi = DST_FAT32LBA) then
    FPencere.Tuval.YaziYaz(16 * 8, 4 * 16, 'FAT32+LBA')
  else FPencere.Tuval.YaziYaz(16 * 8, 4 * 16, 'Bilinmeyen Dosya Sistemi');

  // ilk sektör
  FPencere.Tuval.YaziYaz(0, 5 * 16, 'Ýlk Sektör    :');
  FPencere.Tuval.SayiYaz16(16 * 8, 5 * 16, False, 8, MD^.BolumIlkSektor);

  // toplam sektör
  FPencere.Tuval.YaziYaz(0, 6 * 16, 'Toplam Sektör :');
  FPencere.Tuval.SayiYaz16(16 * 8, 6 * 16, False, 8, MD^.BolumToplamSektor);
end;

end.
