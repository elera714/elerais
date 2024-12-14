program dskgor;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: dskgor.lpr
  Program Ýþlevi: depolama aygýtý sektör içeriðini görüntüler

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
uses n_gorev, gn_pencere, gn_dugme, gn_etiket, gn_durumcubugu,
  gn_giriskutusu, n_depolama;

var
  DiskBellek: array[0..511] of TSayi1;

const
  ProgramAdi: string = 'Depolama Aygýtý Ýçerik Görüntüleme';

  DepolamaAygitiBulunamadi: string  = 'Sistemde depolama aygýtý bulunamadý!';
  DepolamaAygitiSeciniz: string  = 'Lütfen bir depolama aygýtý seçiniz!';
  DepolamaAygitiOkumaHatasi: string  = 'Depolama aygýtý okuma hatasý!';

var
  Gorev: TGorev;
  Depolama: TDepolama;
  Pencere: TPencere;
  DurumCubugu: TDurumCubugu;
  etiSektorNo: TEtiket;
  dugAzalt, dugArtir, dugYenile: TDugme;
  dugDepolamaAygitlari: array[1..6] of TDugme;
  gkAdres: TGirisKutusu;
  Olay: TOlay;
  FizikselDepolamaAygitSayisi, SeciliAygitSiraNo,
  DugmeA1, i: TSayi4;
  AygitOkumaDurumu, ToplamSektor, MevcutSektor: TISayi4;
  FizikselSurucuListesi: array[1..6] of TFizikselSurucu3;
  s: string;

procedure SektorAdresleriniYaz(ASektorNo: TSayi4);
var
  SektorNo, Ust, i: TSayi4;
begin

  Ust := 58;
  SektorNo := ASektorNo * 512;

  for i := 0 to 31 do
  begin

    Pencere.Tuval.KalemRengi := RENK_SIYAH;
    Pencere.Tuval.SayiYaz16(0, Ust, True, 8, SektorNo);
    SektorNo += 16;
    Ust += 16;
  end;
end;

procedure SektorSiraDegerleriniYaz;
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

        Pencere.Tuval.KalemRengi := RENK_KIRMIZI;
        Pencere.Tuval.SayiYaz16(((Sol * 3) + 11) * 8, (Ust * 16) + 58, False, 2, Deger)
      end
      else
      begin

        Pencere.Tuval.KalemRengi := RENK_MAVI;
        Pencere.Tuval.SayiYaz16(((Sol * 3) + 11) * 8, (Ust * 16) + 58, False, 2, Deger);
      end;
    end;
  end;
end;

procedure SektorIceriginiYaz;
var
  Sol, Ust: TSayi4;
  Deger: Char;
begin

  for Ust := 0 to 31 do
  begin

    for Sol := 0 to 15 do
    begin

      Deger := Char(DiskBellek[(Ust * 16) + Sol]);

      Pencere.Tuval.KalemRengi := RENK_SIYAH;
      Pencere.Tuval.HarfYaz((Sol + 59) * 8, (Ust * 16) + 58, Deger);
    end;
  end;
end;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  // ana pencere oluþtur
  Pencere.Olustur(-1, 100, 20, 615, 400, ptBoyutlanabilir, ProgramAdi, $D1F0ED);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  // toplam fiziksel sürücü sayýsýný al
  FizikselDepolamaAygitSayisi := Depolama.FizikselDepolamaAygitSayisiAl;
  if(FizikselDepolamaAygitSayisi > 0) then
  begin

    // fiziksel sürücü bilgilerini al ve düðmeleri oluþtur
    DugmeA1 := 0;
    for i := 1 to FizikselDepolamaAygitSayisi do
    begin

      if(Depolama.FizikselDepolamaAygitBilgisiAl(i, @FizikselSurucuListesi[i])) then
      begin

        dugDepolamaAygitlari[i].Olustur(Pencere.Kimlik, DugmeA1, 2, 65, 22,
          FizikselSurucuListesi[i].AygitAdi);
        dugDepolamaAygitlari[i].Etiket := i;
        dugDepolamaAygitlari[i].Goster;
        DugmeA1 += 70;
      end;
    end;
  end;

  // sektör no etiketi
  etiSektorNo.Olustur(Pencere.Kimlik, 0, 33, $000000, 'Sektör No: ');
  etiSektorNo.Goster;

  // sektör no giriþ kutusu
  gkAdres.Olustur(Pencere.Kimlik, 90, 30, 120, 22, HexToStr(0, False, 8));
  gkAdres.Goster;

  // sektör no azaltma düðmesi
  dugAzalt.Olustur(Pencere.Kimlik, 220, 29, 20, 22, '<');
  dugAzalt.Goster;

  // sektör no artýrma düðmesi
  dugArtir.Olustur(Pencere.Kimlik, 242, 29, 20, 22, '>');
  dugArtir.Goster;

  // sektör no yeniden okuma düðmesi
  dugYenile.Olustur(Pencere.Kimlik, 264, 29, 80, 22, 'Yenile');
  dugYenile.Goster;

  // durum göstergesi
  DurumCubugu.Olustur(Pencere.Kimlik, 0, 0, 100, 20, 'Aygýt: - Sektör: - / -');
  DurumCubugu.Goster;

  // pencereyi görüntüle
  Pencere.Gorunum := True;

  // öndeðer atamalarý
  SeciliAygitSiraNo := 0;
  ToplamSektor := 0;
  MevcutSektor := 0;

  while True do
  begin

    Gorev.OlayBekle(Olay);
    if(Olay.Olay = CO_TUSBASILDI) then
    begin

      // sektör no giriþte ENTER tuþuna basýlmýþsa...
      if(Olay.Deger1 = 10) then
      begin

        s := gkAdres.IcerikAl;
        MevcutSektor := StrToHex(s);

        // tüm iþlemlerde, eðer disk seçili ise okuma iþlemi yap ve bilgileri güncelle
        if(SeciliAygitSiraNo > 0) then
        begin

          DurumCubugu.DurumYazisiDegistir('Aygýt: ' +
            FizikselSurucuListesi[SeciliAygitSiraNo].AygitAdi + ' - Sektör: ' +
            HexToStr(FizikselSurucuListesi[SeciliAygitSiraNo].ToplamSektorSayisi, True, 8) + ' / ' +
            HexToStr(MevcutSektor, True, 8));

          AygitOkumaDurumu := Depolama.FizikselDepolamaVeriOku(SeciliAygitSiraNo,
            MevcutSektor, 1, @DiskBellek);
          Pencere.Ciz;
        end;
      end;
    end

    else if(Olay.Olay = FO_TIKLAMA) then
    begin

      if(Olay.Kimlik = dugYenile.Kimlik) then
      begin

        // kod bloðu sonunda okuma iþlevi gerçekleþtirilmektedir
        // bu blok sadece olayý yakalamak içindir
      end

      // bir önceki sektörü okuma düðmesi
      else if(Olay.Kimlik = dugAzalt.Kimlik) then
      begin

        // eðer disk seçili ise
        if(SeciliAygitSiraNo > 0) then
        begin

          Dec(MevcutSektor);
          if(MevcutSektor < 0) then MevcutSektor := 0;
        end;
      end

      // bir sonraki sektörü okuma düðmesi
      else if(Olay.Kimlik = dugArtir.Kimlik) then
      begin

        // eðer disk seçili ise
        if(SeciliAygitSiraNo > 0) then
        begin

          Inc(MevcutSektor);
          if(MevcutSektor > ToplamSektor) then MevcutSektor := ToplamSektor;
        end;
      end
      else
      begin

        // aksi durumda disk seçme düðmesi
        for i := 1 to 6 do
        begin

          if(dugDepolamaAygitlari[i].Kimlik = Olay.Kimlik) then
          begin

            SeciliAygitSiraNo := dugDepolamaAygitlari[i].Etiket;
            ToplamSektor := FizikselSurucuListesi[i].ToplamSektorSayisi;

            MevcutSektor := 0;
            Break;
          end;
        end;
      end;

      // disk seçili ise okuma iþlemi yap ve bilgileri güncelle
      if(SeciliAygitSiraNo > 0) then
      begin

        DurumCubugu.DurumYazisiDegistir('Aygýt: ' +
          FizikselSurucuListesi[SeciliAygitSiraNo].AygitAdi + ' - Sektör: ' +
          HexToStr(FizikselSurucuListesi[SeciliAygitSiraNo].ToplamSektorSayisi, True, 8) + ' / ' +
          HexToStr(MevcutSektor, True, 8));

        AygitOkumaDurumu := Depolama.FizikselDepolamaVeriOku(SeciliAygitSiraNo,
          MevcutSektor, 1, @DiskBellek);
        Pencere.Ciz;
      end;
    end

    else if(Olay.Olay = CO_CIZIM) then
    begin

      if(FizikselDepolamaAygitSayisi = 0) then
      begin

        Pencere.Tuval.KalemRengi := RENK_KIRMIZI;
        Pencere.Tuval.YaziYaz(0, 58, DepolamaAygitiBulunamadi);
      end
      else
      begin

        Pencere.Tuval.KalemRengi := RENK_KIRMIZI;
        if(SeciliAygitSiraNo = 0) then

          Pencere.Tuval.YaziYaz(0, 58, DepolamaAygitiSeciniz)
        else if(AygitOkumaDurumu = 0) then

          Pencere.Tuval.YaziYaz(0, 58, DepolamaAygitiOkumaHatasi)
        else
        begin

          SektorAdresleriniYaz(MevcutSektor);
          SektorSiraDegerleriniYaz;
          SektorIceriginiYaz;
        end;
      end;
    end;
  end;
end.
