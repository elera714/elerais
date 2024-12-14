program bellkbil;
{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: bellkbil.lpr
  Program ��levi: bellek kullan�m� hakk�nda bilgi verir

  G�ncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, gn_islemgostergesi, n_zamanlayici, n_genel;

const
  ProgramAdi: string = 'Bellek Kullan�m Bilgisi';
  CekirdekBaslangicAdresiK: string = '�ekirdek Ba�. Adresi  :';
  CekirdekBitisAdresiK: string = '�ekirdek Bit. Adresi  :';
  CekirdekUzunluguK: string = '�ekirdek Kod Uzunlu�u :';
  BlokBilgisi: string = 'Blok Bilgileri (1 Blok = 4K)';
  BlokBaslik1: string =  'Toplam  Ayr�lm��  Kullan�lan  Bo�';
  BlokBaslik2: string = '------  --------  ----------  ----';

var
  CekirdekBaslangicAdresi: TSayi4 = 0;
  CekirdekBitisAdresi: TSayi4 = 0;
  CekirdekUzunlugu: TSayi4 = 0;
  ToplamRAMBlok: TSayi4 = 0;
  AyrilmisRAMBlok: TSayi4 = 0;
  KullanilmisRAMBlok: TSayi4 = 0;
  BosRAMBlok: TSayi4 = 0;
  BlokUzunlugu: TSayi4 = 0;

var
  Genel: TGenel;
  Gorev: TGorev;
  Pencere: TPencere;
  IslemGostergesi: TIslemGostergesi;
  Zamanlayici: TZamanlayici;
  Olay: TOlay;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 50, 50, 290, 172, ptIletisim, ProgramAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  IslemGostergesi.Olustur(Pencere.Kimlik, 0, 86, 280, 22);
  IslemGostergesi.DegerleriBelirle(1, 8095);
  IslemGostergesi.Goster;

  Pencere.Gorunum := True;

  Zamanlayici.Olustur(100);
  Zamanlayici.Baslat;

  while True do
  begin

    Gorev.OlayBekle(Olay);
    if(Olay.Olay = CO_CIZIM) then
    begin

      Pencere.Tuval.KalemRengi := RENK_SIYAH;
      Pencere.Tuval.YaziYaz(0, 0 * 16, CekirdekBaslangicAdresiK);
      Pencere.Tuval.SayiYaz16(24 * 8, 0 * 16, True, 8, CekirdekBaslangicAdresi);

      Pencere.Tuval.YaziYaz(0, 1 * 16, CekirdekBitisAdresiK);
      Pencere.Tuval.SayiYaz16(24 * 8, 1 * 16, True, 8, CekirdekBitisAdresi);

      Pencere.Tuval.YaziYaz(0, 2 * 16, CekirdekUzunluguK);
      Pencere.Tuval.SayiYaz16(24 * 8, 2 * 16, True, 8, CekirdekUzunlugu);

      Pencere.Tuval.YaziYaz(0, 4 * 16, BlokBilgisi);
      Pencere.Tuval.YaziYaz(0, 7 * 16, BlokBaslik1);
      Pencere.Tuval.YaziYaz(0, 8 * 16, BlokBaslik2);

      Pencere.Tuval.SayiYaz10(1 * 8, 9 * 16, ToplamRAMBlok);
      Pencere.Tuval.SayiYaz10(10 * 8, 9 * 16, AyrilmisRAMBlok);
      Pencere.Tuval.SayiYaz10(20 * 8, 9 * 16, KullanilmisRAMBlok);
      Pencere.Tuval.SayiYaz10(30 * 8, 9 * 16, BosRAMBlok);

      IslemGostergesi.KonumBelirle(KullanilmisRAMBlok);
    end
    else if(Olay.Olay = CO_ZAMANLAYICI) then
    begin

      Genel.CekirdekBellekBilgisiAl(@CekirdekBaslangicAdresi, @CekirdekBitisAdresi,
        @CekirdekUzunlugu);
      Genel.GenelBellekBilgisiAl(@ToplamRAMBlok, @AyrilmisRAMBlok, @KullanilmisRAMBlok,
        @BosRAMBlok, @BlokUzunlugu);

      Pencere.Ciz;
    end;
  end;
end.
