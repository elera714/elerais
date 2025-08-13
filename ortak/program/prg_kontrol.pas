{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: prg_kontrol.pas
  Dosya ��levi: dahili �ekirdek program�: �ekirdek i�i kontrol i�lemleri i�in

  G�ncelleme Tarihi: 07/06/2025

 ==============================================================================}
{$mode objfpc}
unit prg_kontrol;

interface

uses paylasim, genel, gn_pencere, gn_islemgostergesi, gorselnesne, sistemmesaj, dosya;

procedure KontrolYonetimi;
procedure NesneKontrol;

implementation

uses sistem;

// rutin kontrol denetimlerin yap�ld��� nokta
procedure KontrolYonetimi;
var
  Pencere: PPencere = nil;
  IslemGostergesi: PIslemGostergesi = nil;
  AramaKaydi: TDosyaArama;
  i, G: TISayi4;
  j: TSayi2;
  TarihSaat: TTarihSaat;
  DosyaBulundu: Boolean;
  Sayac: TSayi4;
begin

  while True do
  begin

    NesneKontrol;

    //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, '1', []);
    //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'FareX: %d', [GFareSurucusu.YatayKonum]);
    //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'FareY: %d', [GFareSurucusu.DikeyKonum]);

    // 10 saniye bekle
    //BekleMS(1000);
    Sayac := ZamanlayiciSayaci + 500;
    while (Sayac > ZamanlayiciSayaci) do; //begin asm int $20; end; end;

    //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Fare-X: %d', [GFareSurucusu.YatayKonum]);
    //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Fare-Y: %d', [GFareSurucusu.DikeyKonum]);
    //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, '2', []);

    DosyaBulundu := False;

    i := FindFirst('disket1:\*.*', 0, AramaKaydi);
    while i = 0 do
    begin

      if(AramaKaydi.DosyaAdi = 'cekirdek.bin') then
      begin

        DosyaBulundu := True;

        j := AramaKaydi.SonDegisimTarihi;
        TarihSaat.Gun := j and 31;
        TarihSaat.Ay := (j shr 5) and 15;
        TarihSaat.Yil := ((j shr 9) and 127) + 1980;

        j := AramaKaydi.SonDegisimSaati;
        TarihSaat.Saniye := (j and 31) * 2;
        TarihSaat.Dakika := (j shr 5) and 63;
        TarihSaat.Saat := (j shr 11) and 31;

        Break;
      end;

      i := FindNext(AramaKaydi);
    end;
    FindClose(AramaKaydi);

{    SISTEM_MESAJ(mtHata, RENK_MAVI, 'Masa�st� Sol: %d', [GAktifMasaustu^.FKonum.Sol]);
    SISTEM_MESAJ(mtHata, RENK_MAVI, 'Masa�st� �st: %d', [GAktifMasaustu^.FKonum.Ust]);
    SISTEM_MESAJ(mtHata, RENK_MAVI, 'Masa�st� Sol: %d', [GAktifMasaustu^.FCizimBaslangic.Sol]);
    SISTEM_MESAJ(mtHata, RENK_MAVI, 'Masa�st� �st: %d', [GAktifMasaustu^.FCizimBaslangic.Ust]);
}
    if(DosyaBulundu) then
    begin

      if(CekirdekYuklemeTS <> TarihSaat) then
      begin

        G := GAktifMasaustu^.FAtananAlan.Genislik;

        if(Pencere = nil) then
          Pencere := Pencere^.Olustur(GAktifMasaustu, G - 162, 122 + 24, 152, 18,
          ptBasliksiz, '', RENK_KIRMIZI);

        if(IslemGostergesi = nil) then
          IslemGostergesi := IslemGostergesi^.Olustur(ktNesne, Pencere, 1, 1, 150, 16);

        IslemGostergesi^.DegerleriBelirle(0, 20);
        IslemGostergesi^.Goster;

        Pencere^.Goster;

        for i := 19 downto 1 do
        begin

          IslemGostergesi^.MevcutDegerYaz(i);
          //BekleMS(100);

          Sayac := ZamanlayiciSayaci + 20;
          while (Sayac > ZamanlayiciSayaci) do; //begin asm int $20; end; end;
        end;

        YenidenBaslat;

        Pencere^.Gizle;

        //BekleMS(500);
        Sayac := ZamanlayiciSayaci + 500;
        while (Sayac > ZamanlayiciSayaci) do; //begin asm int $20; end; end;

      end;
    end;
  end;
end;

// g�rsel nesne bellek b�lgesine ba�ka i�lemlerin hatayla veri yazmas�na kar��n
// denetim i�lemlerini ger�ekle�tirir
procedure NesneKontrol;
var
  G: PGorselNesne;
  i, j, k: TKimlik;
begin

  j := 0;
  k := 0;
  for i := 0 to USTSINIR_GORSELNESNE - 1 do
  begin

    G := GorselNesneler0.GorselNesne[i];
    if(G = nil) then
    begin

      k := i;
      Inc(j);
    end;
  end;

  SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'Son: %d, Toplam: %d', [k, j]);

{  for i := 0 to USTSINIR_GORSELNESNE - 1 do
  begin

    G := GorselNesneler0.GorselNesne[i];
    if not(G = nil) then
    begin

      j := G^.Kimlik shr 10;
      if(i <> j) then
      begin

        SISTEM_MESAJ(mtHata, RENK_KIRMIZI, '%d. nesne giri�i hatal�: %d', [i, G^.Kimlik]);
        Break;
      end;
    end;
  end;}
end;

end.
