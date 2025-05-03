{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, _forms, gn_dugme, gn_etiket, gn_durumcubugu,
  gn_giriskutusu, n_depolama;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGorev: TGorev;
    FDepolama: TDepolama;
    FPencere: TPencere;
    FDurumCubugu: TDurumCubugu;
    FetiSektorNo: TEtiket;
    FdugAzalt, FdugArtir, FdugYenile: TDugme;
    FdugDepolamaAygitlari: array[0..5] of TDugme;
    FgkAdres: TGirisKutusu;
    procedure SektorAdresleriniYaz(ASektorNo: TSayi4);
    procedure SektorSiraDegerleriniYaz;
    procedure SektorIceriginiYaz;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Depolama Ayg�t� ��erik G�r�nt�leme';

  DepolamaAygitiBulunamadi: string  = 'Sistemde depolama ayg�t� bulunamad�!';
  DepolamaAygitiSeciniz: string  = 'L�tfen bir depolama ayg�t� se�iniz!';
  DepolamaAygitiOkumaHatasi: string  = 'Depolama ayg�t� okuma hatas�!';

var
  FizikselDepolamaAygitSayisi, DugmeA1: TSayi4;
  SeciliAygitSN, i: TISayi4;
  AygitOkumaDurumu, ToplamSektor, MevcutSektor: TISayi4;
  FizikselDepolamaListesi: array[0..5] of TFizikselDepolama3;
  DiskBellek: array[0..511] of TSayi1;
  s: string;

procedure TfrmAnaSayfa.Olustur;
begin

  // ana pencere olu�tur
  FPencere.Olustur(-1, 100, 20, 615, 400, ptBoyutlanabilir, PencereAdi, $D1F0ED);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  // toplam fiziksel s�r�c� say�s�n� al
  FizikselDepolamaAygitSayisi := FDepolama.FizikselDepolamaAygitSayisiAl;
  if(FizikselDepolamaAygitSayisi > 0) then
  begin

    // fiziksel s�r�c� bilgilerini al ve d��meleri olu�tur
    DugmeA1 := 0;
    for i := 0 to FizikselDepolamaAygitSayisi - 1 do
    begin

      if(FDepolama.FizikselDepolamaAygitBilgisiAl(i, @FizikselDepolamaListesi[i]) > 0) then
      begin

        FdugDepolamaAygitlari[i].Olustur(FPencere.Kimlik, DugmeA1, 2, 65, 22,
          FizikselDepolamaListesi[i].AygitAdi);
        FdugDepolamaAygitlari[i].Goster;
        DugmeA1 += 70;
      end;
    end;
  end;

  // sekt�r no etiketi
  FetiSektorNo.Olustur(FPencere.Kimlik, 0, 33, 88, 16, $000000, 'Sekt�r No: ');
  FetiSektorNo.Goster;

  // sekt�r no giri� kutusu
  FgkAdres.Olustur(FPencere.Kimlik, 90, 30, 120, 22, HexToStr(0, False, 8));
  FgkAdres.Goster;

  // sekt�r no azaltma d��mesi
  FdugAzalt.Olustur(FPencere.Kimlik, 220, 29, 20, 22, '<');
  FdugAzalt.Goster;

  // sekt�r no art�rma d��mesi
  FdugArtir.Olustur(FPencere.Kimlik, 242, 29, 20, 22, '>');
  FdugArtir.Goster;

  // sekt�r no yeniden okuma d��mesi
  FdugYenile.Olustur(FPencere.Kimlik, 264, 29, 80, 22, 'Yenile');
  FdugYenile.Goster;

  // durum g�stergesi
  FDurumCubugu.Olustur(FPencere.Kimlik, 0, 0, 100, 20, 'Ayg�t: - Sekt�r: - / -');
  FDurumCubugu.Goster;
end;

procedure TfrmAnaSayfa.Goster;
begin

  // pencereyi g�r�nt�le
  FPencere.Gorunum := True;

  // �nde�er atamalar�
  SeciliAygitSN := -1;
  ToplamSektor := 0;
  MevcutSektor := 0;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  // �ekirdek taraf�ndan g�nderilen program�n kendisini sonland�rma talimat�
  if(AOlay.Olay = CO_SONLANDIR) then
  begin

    FGorev.Sonlandir(-1);
  end
  else if(AOlay.Olay = CO_TUSBASILDI) then
  begin

    // sekt�r no giri�te ENTER tu�una bas�lm��sa...
    if(AOlay.Deger1 = 10) then
    begin

      s := FgkAdres.IcerikAl;
      MevcutSektor := StrToHex(s);

      // t�m i�lemlerde, e�er disk se�ili ise okuma i�lemi yap ve bilgileri g�ncelle
      if(SeciliAygitSN > -1) then
      begin

        FDurumCubugu.DurumYazisiDegistir('Ayg�t: ' +
          FizikselDepolamaListesi[SeciliAygitSN].AygitAdi + ' - Sekt�r: ' +
          HexToStr(FizikselDepolamaListesi[SeciliAygitSN].ToplamSektorSayisi, True, 8) + ' / ' +
          HexToStr(MevcutSektor, True, 8));

        AygitOkumaDurumu := FDepolama.FizikselDepolamaVeriOku(
          FizikselDepolamaListesi[SeciliAygitSN].Kimlik, MevcutSektor, 1, @DiskBellek);
        FPencere.Ciz;
      end;
    end;
  end

  else if(AOlay.Olay = FO_TIKLAMA) then
  begin

    if(AOlay.Kimlik = FdugYenile.Kimlik) then
    begin

      // kod blo�u sonunda okuma i�levi ger�ekle�tirilmektedir
      // bu blok sadece olay� yakalamak i�indir
    end

    // bir �nceki sekt�r� okuma d��mesi
    else if(AOlay.Kimlik = FdugAzalt.Kimlik) then
    begin

      // e�er disk se�ili ise
      if(SeciliAygitSN > -1) then
      begin

        Dec(MevcutSektor);
        if(MevcutSektor < 0) then MevcutSektor := 0;
      end;
    end

    // bir sonraki sekt�r� okuma d��mesi
    else if(AOlay.Kimlik = FdugArtir.Kimlik) then
    begin

      // e�er disk se�ili ise
      if(SeciliAygitSN > -1) then
      begin

        Inc(MevcutSektor);
        if(MevcutSektor > ToplamSektor) then MevcutSektor := ToplamSektor;
      end;
    end
    else
    begin

      // aksi durumda disk se�me d��mesi
      for i := 0 to 5 do
      begin

        if(FdugDepolamaAygitlari[i].Kimlik = AOlay.Kimlik) then
        begin

          SeciliAygitSN := i;
          ToplamSektor := FizikselDepolamaListesi[SeciliAygitSN].ToplamSektorSayisi;

          MevcutSektor := 0;
          Break;
        end;
      end;
    end;

    // disk se�ili ise okuma i�lemi yap ve bilgileri g�ncelle
    if(SeciliAygitSN > -1) then
    begin

      FDurumCubugu.DurumYazisiDegistir('Ayg�t: ' +
        FizikselDepolamaListesi[SeciliAygitSN].AygitAdi + ' - Sekt�r: ' +
        HexToStr(FizikselDepolamaListesi[SeciliAygitSN].ToplamSektorSayisi, True, 8) + ' / ' +
        HexToStr(MevcutSektor, True, 8));

      AygitOkumaDurumu := FDepolama.FizikselDepolamaVeriOku(
        FizikselDepolamaListesi[SeciliAygitSN].Kimlik, MevcutSektor, 1, @DiskBellek);
      FPencere.Ciz;
    end;
  end

  else if(AOlay.Olay = CO_CIZIM) then
  begin

    if(FizikselDepolamaAygitSayisi = 0) then
    begin

      FPencere.Tuval.KalemRengi := RENK_KIRMIZI;
      FPencere.Tuval.YaziYaz(0, 58, DepolamaAygitiBulunamadi);
    end
    else
    begin

      FPencere.Tuval.KalemRengi := RENK_KIRMIZI;
      if(SeciliAygitSN = -1) then

        FPencere.Tuval.YaziYaz(0, 58, DepolamaAygitiSeciniz)
      else if(AygitOkumaDurumu <> 0) then

        FPencere.Tuval.YaziYaz(0, 58, DepolamaAygitiOkumaHatasi)
      else
      begin

        SektorAdresleriniYaz(MevcutSektor);
        SektorSiraDegerleriniYaz;
        SektorIceriginiYaz;
      end;
    end;
  end;

  Result := 1;
end;

procedure TfrmAnaSayfa.SektorAdresleriniYaz(ASektorNo: TSayi4);
var
  SektorNo, Ust, i: TSayi4;
begin

  Ust := 58;
  SektorNo := ASektorNo * 512;

  for i := 0 to 31 do
  begin

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.SayiYaz16(0, Ust, True, 8, SektorNo);
    SektorNo += 16;
    Ust += 16;
  end;
end;

procedure TfrmAnaSayfa.SektorSiraDegerleriniYaz;
var
  Sol, Ust, Deger: TSayi4;
begin

  for  Ust := 0 to 31 do
  begin

    for Sol := 0 to 15 do
    begin

      Deger := DiskBellek[(Ust * 16) + Sol];
      if((Sol and 1) = 1) then
      begin

        FPencere.Tuval.KalemRengi := RENK_KIRMIZI;
        FPencere.Tuval.SayiYaz16(((Sol * 3) + 11) * 8, (Ust * 16) + 58, False, 2, Deger)
      end
      else
      begin

        FPencere.Tuval.KalemRengi := RENK_MAVI;
        FPencere.Tuval.SayiYaz16(((Sol * 3) + 11) * 8, (Ust * 16) + 58, False, 2, Deger);
      end;
    end;
  end;
end;

procedure TfrmAnaSayfa.SektorIceriginiYaz;
var
  Sol, Ust: TSayi4;
  Deger: Char;
begin

  for Ust := 0 to 31 do
  begin

    for Sol := 0 to 15 do
    begin

      Deger := Char(DiskBellek[(Ust * 16) + Sol]);

      FPencere.Tuval.KalemRengi := RENK_SIYAH;
      FPencere.Tuval.HarfYaz((Sol + 59) * 8, (Ust * 16) + 58, Deger);
    end;
  end;
end;

end.
