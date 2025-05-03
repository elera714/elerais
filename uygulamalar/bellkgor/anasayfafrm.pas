{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_genel, _forms, gn_durumcubugu, gn_giriskutusu, gn_dugme;

type
  TfrmAnaSayfa = object(TForm)
  private
    FPencere: TPencere;
    FDurumCubugu: TDurumCubugu;
    FGenel: TGenel;
    FGorev: TGorev;
    FAdres: TGirisKutusu;
    FArtir, dugAzalt,
    FYenile: TDugme;
    procedure BellekAdresiniYaz(ABellekAdresi: TSayi4);
    procedure BellekIcerigini16TabanliYaz;
    procedure BellekIceriginiKarakterOlarakYaz;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Bellek Ýçerik Görüntüleyici';
  ONDEGERBELLEKADRESI = $10000;

var
  ToplamRAMBlok, AyrilmisRAMBlok,
  KullanilanRAMBlok, BosRAMBlok,
  BlokUzunlugu, ToplamRAMUzunlugu,
  MevcutBellekAdresi: TSayi4;
  Veriler: array[0..1023] of TSayi1;
  s: string;

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 5, 5, 615, 400, ptBoyutlanabilir, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FDurumCubugu.Olustur(FPencere.Kimlik, 0, 0, 100, 20, 'Bellek Adresi: ' +
    HexToStr(ONDEGERBELLEKADRESI, True, 8));
  FDurumCubugu.Goster;

  FPencere.Tuval.YaziYaz(0, 8, 'Adres[16lý]:');

  FAdres.Olustur(FPencere.Kimlik, 110, 4, 120, 22, HexToStr(ONDEGERBELLEKADRESI,
    False, 8));
  FAdres.SadeceRakam := True;
  FAdres.Goster;

  dugAzalt.Olustur(FPencere.Kimlik, 238, 3, 20, 22, '<');
  dugAzalt.Goster;

  FArtir.Olustur(FPencere.Kimlik, 260, 3, 20, 22, '>');
  FArtir.Goster;

  FYenile.Olustur(FPencere.Kimlik, 282, 3, 80, 22, 'Yenile');
  FYenile.Goster;

  FGenel.GenelBellekBilgisiAl(@ToplamRAMBlok, @AyrilmisRAMBlok, @KullanilanRAMBlok,
    @BosRAMBlok, @BlokUzunlugu);

  ToplamRAMUzunlugu := ToplamRAMBlok * BlokUzunlugu;

  MevcutBellekAdresi := ONDEGERBELLEKADRESI;
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;

  FGenel.BellekIcerikOku(Isaretci(MevcutBellekAdresi), @Veriler[0], 512);
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  // çekirdek tarafýndan gönderilen programýn kendisini sonlandýrma talimatý
  if(AOlay.Olay = CO_SONLANDIR) then
  begin

    FGorev.Sonlandir(-1);
  end
  else if(AOlay.Olay = CO_TUSBASILDI) then
  begin

    if(AOlay.Deger1 = 10) then
    begin

      s := FAdres.IcerikAl;
      MevcutBellekAdresi := StrToHex(s);

      FDurumCubugu.DurumYazisiDegistir('Bellek Adresi: ' +
        HexToStr(MevcutBellekAdresi, True, 8));

      FGenel.BellekIcerikOku(Isaretci(MevcutBellekAdresi), @Veriler[0], 512);

      FPencere.Ciz;
    end;
  end
  else if(AOlay.Olay = FO_TIKLAMA) then
  begin

    if(AOlay.Kimlik = FArtir.Kimlik) then
    begin

      if(MevcutBellekAdresi + 512 > ToplamRAMUzunlugu) then
        MevcutBellekAdresi := ToplamRAMUzunlugu - 512
      else MevcutBellekAdresi := MevcutBellekAdresi + 512;
    end
    else if(AOlay.Kimlik = dugAzalt.Kimlik) then
    begin

      if(MevcutBellekAdresi - 512 < 0) then
        MevcutBellekAdresi := 0
      else MevcutBellekAdresi := MevcutBellekAdresi - 512;
    end;

    FDurumCubugu.DurumYazisiDegistir('Bellek Adresi: ' +
      HexToStr(MevcutBellekAdresi, True, 8));

    FGenel.BellekIcerikOku(Isaretci(MevcutBellekAdresi), @Veriler[0], 512);

    FPencere.Ciz;
  end
  else if(AOlay.Olay = CO_CIZIM) then
  begin

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.YaziYaz(0, 7, 'Adres[16lý]:');

    BellekAdresiniYaz(MevcutBellekAdresi);
    BellekIcerigini16TabanliYaz;
    BellekIceriginiKarakterOlarakYaz;
  end;

  Result := 1;
end;

procedure TfrmAnaSayfa.BellekAdresiniYaz(ABellekAdresi: TSayi4);
var
  BellekAdresi, i, Ust: TSayi4;
begin

  Ust := 32;
  BellekAdresi := ABellekAdresi;

  for i := 0 to 31 do
  begin

    FPencere.Tuval.KalemRengi := RENK_SIYAH;
    FPencere.Tuval.SayiYaz16(0, Ust, True, 8, BellekAdresi);
    BellekAdresi += 16;
    Ust += 16;
  end;
end;

procedure TfrmAnaSayfa.BellekIcerigini16TabanliYaz;
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

        FPencere.Tuval.KalemRengi := RENK_KIRMIZI;
        // (Sol * 3) = 2 hex + 1 boþ deðer
        // + 11 = 10 hex + 1 boþ deðer
        FPencere.Tuval.SayiYaz16(((Sol * 3) + 11) * 8, (Ust * 16) + 32, False, 2, Deger)
      end
      else
      begin

        FPencere.Tuval.KalemRengi := RENK_MAVI;
        FPencere.Tuval.SayiYaz16(((Sol * 3) + 11) * 8, (Ust * 16) + 32, False, 2, Deger);
      end;
    end;
  end;
end;

procedure TfrmAnaSayfa.BellekIceriginiKarakterOlarakYaz;
var
  Sol, Ust: TSayi4;
  Deger: Char;
begin

  for Ust := 0 to 31 do
  begin

    for Sol := 0 to 15 do
    begin

      Deger := Char(Veriler[(Ust * 16) + Sol]);
      FPencere.Tuval.KalemRengi := RENK_SIYAH;
      FPencere.Tuval.HarfYaz((Sol + 59) * 8, (Ust * 16) + 32, Deger);
    end;
  end;
end;

end.
