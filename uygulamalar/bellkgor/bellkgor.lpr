program bellkgor;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: bellkgor.lpr
  Program Ýþlevi: bellek içerik görüntüleme programý

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, gn_dugme, gn_giriskutusu, gn_durumcubugu, n_genel;

const
  ProgramAdi: string = 'Bellek Ýçerik Görüntüleyici';
  ONDEGERBELLEKADRESI = $10000;

var
  Pencere: TPencere;
  DurumCubugu: TDurumCubugu;
  ToplamRAMBlok, AyrilmisRAMBlok,
  KullanilanRAMBlok, BosRAMBlok,
  BlokUzunlugu, ToplamRAMUzunlugu,
  MevcutBellekAdresi: TSayi4;
  Veriler: array[0..1023] of TSayi1;

var
  Genel: TGenel;
  Gorev: TGorev;
  Olay: TOlay;
  gkAdres: TGirisKutusu;
  dugArtir, dugAzalt,
  dugYenile: TDugme;
  s: string;

procedure BellekAdresiniYaz(ABellekAdresi: TSayi4);
var
  BellekAdresi, i, Ust: TSayi4;
begin

  Ust := 32;
  BellekAdresi := ABellekAdresi;

  for i := 0 to 31 do
  begin

    Pencere.Tuval.KalemRengi := RENK_SIYAH;
    Pencere.Tuval.SayiYaz16(0, Ust, True, 8, BellekAdresi);
    BellekAdresi += 16;
    Ust += 16;
  end;
end;

procedure BellekIcerigini16TabanliYaz;
var
  Sol, Ust: TSayi4;
  Deger: TSayi1;
begin

  for Ust := 0 to 31 do
  begin

    for Sol := 0 to 15 do
    begin

      Deger := Veriler[(Ust * 16) + Sol];
      if((Sol and 1) = 1) then
      begin

        Pencere.Tuval.KalemRengi := RENK_KIRMIZI;
        // (Sol * 3) = 2 hex + 1 boþ deðer
        // + 11 = 10 hex + 1 boþ deðer
        Pencere.Tuval.SayiYaz16(((Sol * 3) + 11) * 8, (Ust * 16) + 32, False, 2, Deger)
      end
      else
      begin

        Pencere.Tuval.KalemRengi := RENK_MAVI;
        Pencere.Tuval.SayiYaz16(((Sol * 3) + 11) * 8, (Ust * 16) + 32, False, 2, Deger);
      end;
    end;
  end;
end;

procedure BellekIceriginiKarakterOlarakYaz;
var
  Sol, Ust: TSayi4;
  Deger: Char;
begin

  for Ust := 0 to 31 do
  begin

    for Sol := 0 to 15 do
    begin

      Deger := Char(Veriler[(Ust * 16) + Sol]);
      Pencere.Tuval.KalemRengi := RENK_SIYAH;
      Pencere.Tuval.HarfYaz((Sol + 59) * 8, (Ust * 16) + 32, Deger);
    end;
  end;
end;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 5, 5, 615, 400, ptBoyutlanabilir, ProgramAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  DurumCubugu.Olustur(Pencere.Kimlik, 0, 0, 100, 20, 'Bellek Adresi: ' +
    HexToStr(ONDEGERBELLEKADRESI, True, 8));
  DurumCubugu.Goster;

  Pencere.Tuval.YaziYaz(0, 8, 'Adres[16lý]:');

  gkAdres.Olustur(Pencere.Kimlik, 110, 4, 120, 22, HexToStr(ONDEGERBELLEKADRESI,
    False, 8));
  gkAdres.SadeceRakam := True;
  gkAdres.Goster;

  dugAzalt.Olustur(Pencere.Kimlik, 238, 3, 20, 22, '<');
  dugAzalt.Goster;

  dugArtir.Olustur(Pencere.Kimlik, 260, 3, 20, 22, '>');
  dugArtir.Goster;

  dugYenile.Olustur(Pencere.Kimlik, 282, 3, 80, 22, 'Yenile');
  dugYenile.Goster;

  Genel.GenelBellekBilgisiAl(@ToplamRAMBlok, @AyrilmisRAMBlok, @KullanilanRAMBlok,
    @BosRAMBlok, @BlokUzunlugu);

  ToplamRAMUzunlugu := ToplamRAMBlok * BlokUzunlugu;

  MevcutBellekAdresi := ONDEGERBELLEKADRESI;

  Pencere.Gorunum := True;

  Genel.BellekIcerikOku(Isaretci(MevcutBellekAdresi), @Veriler[0], 512);

  while True do
  begin

    Gorev.OlayBekle(Olay);
    if(Olay.Olay = CO_TUSBASILDI) then
    begin

      if(Olay.Deger1 = 10) then
      begin

        s := gkAdres.IcerikAl;
        MevcutBellekAdresi := StrToHex(s);

        DurumCubugu.DurumYazisiDegistir('Bellek Adresi: ' +
          HexToStr(MevcutBellekAdresi, True, 8));

        Genel.BellekIcerikOku(Isaretci(MevcutBellekAdresi), @Veriler[0], 512);

        Pencere.Ciz;
      end;
    end
    else if(Olay.Olay = FO_TIKLAMA) then
    begin

      if(Olay.Kimlik = dugArtir.Kimlik) then
      begin

        if(MevcutBellekAdresi + 512 > ToplamRAMUzunlugu) then
          MevcutBellekAdresi := ToplamRAMUzunlugu - 512
        else MevcutBellekAdresi := MevcutBellekAdresi + 512;
      end
      else if(Olay.Kimlik = dugAzalt.Kimlik) then
      begin

        if(MevcutBellekAdresi - 512 < 0) then
          MevcutBellekAdresi := 0
        else MevcutBellekAdresi := MevcutBellekAdresi - 512;
      end;

      DurumCubugu.DurumYazisiDegistir('Bellek Adresi: ' +
        HexToStr(MevcutBellekAdresi, True, 8));

      Genel.BellekIcerikOku(Isaretci(MevcutBellekAdresi), @Veriler[0], 512);

      Pencere.Ciz;
    end
    else if(Olay.Olay = CO_CIZIM) then
    begin

      Pencere.Tuval.KalemRengi := RENK_SIYAH;
      Pencere.Tuval.YaziYaz(0, 7, 'Adres[16lý]:');

      BellekAdresiniYaz(MevcutBellekAdresi);
      BellekIcerigini16TabanliYaz;
      BellekIceriginiKarakterOlarakYaz;
    end;
  end;
end.
