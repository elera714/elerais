program mustudk;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: mustudk.lpr
  Program Ýþlevi: masaüstü duvar kaðýt yönetim programý

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
uses gn_masaustu, n_gorev, gn_pencere, gn_dugme, gn_etiket, gn_secimdugmesi,
  gn_listekutusu, gn_renksecici, gn_karmaliste, n_genel, n_giysi;

const
  ProgramAdi: string = 'Masaüstü Duvar Kaðýdý';

var
  DosyaAramaListesi: array[0..15] of TDosyaArama;

var
  Genel: TGenel;
  Gorev: TGorev;
  masELERA: TMasaustu;
  Pencere: TPencere;
  lkDosyaListesi: TListeKutusu;
  etiBilgi: array[0..2] of TEtiket;
  RenkSecici: TRenkSecici;
  GiysiListesi: TKarmaListe;
  Giysi: TGiysi;
  Olay: TOlay;
  GiysiAdi: string;
  i, j: TISayi4;

procedure DosyalariListele;
var
  DosyaArama: TDosyaArama;
  AramaSonuc, i, j: TSayi4;
begin

  lkDosyaListesi.Temizle;

  j := 0;

  AramaSonuc := Genel._FindFirst('disk1:\*.*', 0, DosyaArama);

  while (AramaSonuc = 0) do
  begin

    i := Length(DosyaArama.DosyaAdi);
    if(i > 4) and (DosyaArama.DosyaAdi[i - 3] = '.') and
      (DosyaArama.DosyaAdi[i - 2] = 'b') and (DosyaArama.DosyaAdi[i - 1] = 'm') and
      (DosyaArama.DosyaAdi[i] = 'p') then
    begin

      DosyaAramaListesi[j] := DosyaArama;
      lkDosyaListesi.ElemanEkle(DosyaAramaListesi[j].DosyaAdi);

      Inc(j);
    end;

    AramaSonuc := Genel._FindNext(DosyaArama);
  end;

  Genel._FindClose(DosyaArama);
end;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 100, 100, 200, 240, ptIletisim, ProgramAdi, $F9FAF9);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  etiBilgi[0].Olustur(Pencere.Kimlik, 5, 0, $FF0000, 'Masaüstü Renkleri:');
  etiBilgi[0].Goster;

  RenkSecici.Olustur(Pencere.Kimlik, 5, 19, 190, 32);
  RenkSecici.Goster;

  etiBilgi[1].Olustur(Pencere.Kimlik, 5, 60, $FF0000, 'Masaüstü Resimleri:');
  etiBilgi[1].Goster;

  // liste kutusu oluþtur
  lkDosyaListesi.Olustur(Pencere.Kimlik, 5, 76, 190, 107);
  lkDosyaListesi.Goster;

  DosyalariListele;

  etiBilgi[2].Olustur(Pencere.Kimlik, 5, 192, $FF0000, 'Giysiler:');
  etiBilgi[2].Goster;

  GiysiListesi.Olustur(Pencere.Kimlik, 5, 210, 190, 25);

  i := Giysi.Toplam;
  if(i > 0) then
  begin

    for j := 0 to i - 1 do
    begin

      Giysi.AdAl(j, @GiysiAdi);
      GiysiListesi.ElemanEkle(GiysiAdi);
    end;

    j := Giysi.AktifSiraNoAl;
    GiysiListesi.BaslikSiraNo := j;
  end;
  GiysiListesi.Goster;

  // pencereyi görüntüle
  Pencere.Gorunum := True;

  masELERA.AktifMasaustu;

  // ana döngü
  while True do
  begin

    Gorev.OlayBekle(Olay);

    if(Olay.Olay = FO_TIKLAMA) then
    begin

      // liste kutusuna týklanmasý halinde dosyayý çalýþtýr
      if(Olay.Kimlik = lkDosyaListesi.Kimlik) then
      begin

        i := lkDosyaListesi.SeciliSiraNoAl;
        masELERA.MasaustuResminiDegistir('disk1:\' + DosyaAramaListesi[i].DosyaAdi);
        masELERA.Guncelle;
      end
      else if(Olay.Kimlik = RenkSecici.Kimlik) then
      begin

        masELERA.MasaustuRenginiDegistir(Olay.Deger1);
        masELERA.Guncelle;
      end;
    end
    else if(Olay.Olay = CO_SECIMDEGISTI) then
    begin

      Giysi.Aktiflestir(Olay.Deger1);
    end;
  end;
end.
