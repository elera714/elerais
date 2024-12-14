program resimgor;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: resimgor.lpr
  Program Ýþlevi: resim görüntüleyici program

  Güncelleme Tarihi: 07/08/2020

 ==============================================================================}
{$mode objfpc}
uses gn_masaustu, n_gorev, gn_pencere, gn_dugme, gn_etiket, gn_listekutusu,
  gn_resim, gn_araccubugu, gn_durumcubugu, n_genel;

const
  ProgramAdi: string = 'Resim Görüntüleyici';

var
  DosyaAramaListesi: array[0..20] of TDosyaArama;

var
  Genel: TGenel;
  Gorev: TGorev;
  Pencere: TPencere;
  AracCubugu: TAracCubugu;
  lkDosyaListesi: TListeKutusu;
  DurumCubugu: TDurumCubugu;
  Resim: TResim;
  Dugmeler: array[0..2] of TKimlik;
  Olay: TOlay;
  i, ToplamEleman, SeciliSiraNo: TISayi4;
  GoruntulenecekDosya: string;

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
    if(i > 4) and (DosyaArama.DosyaAdi[i - 3] = '.') and (DosyaArama.DosyaAdi[i - 2] = 'b') and
      (DosyaArama.DosyaAdi[i - 1] = 'm') and (DosyaArama.DosyaAdi[i] = 'p') then
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

  Pencere.Olustur(-1, 50, 50, 600, 450, ptBoyutlanabilir, ProgramAdi, $C0C4C3);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  AracCubugu.Olustur(Pencere.Kimlik);
  Dugmeler[0] := AracCubugu.DugmeEkle(6);
  Dugmeler[1] := AracCubugu.DugmeEkle(7);
  Dugmeler[2] := AracCubugu.DugmeEkle(8);
  AracCubugu.Goster;

  DurumCubugu.Olustur(Pencere.Kimlik, 0, 0, 10, 22, 'Dosya: -');
  DurumCubugu.Goster;

  // liste kutusu oluþtur
  lkDosyaListesi.Olustur(Pencere.Kimlik, 0, 0, 100, 52);
  lkDosyaListesi.Hizala(hzSol);
  lkDosyaListesi.Goster;

  Resim.Olustur(Pencere.Kimlik, 0, 60, 490, 420, '');
  Resim.Hizala(hzTum);
  Resim.TuvaleSigdir(True);
  Resim.Goster;

  DosyalariListele;

  // pencereyi görüntüle
  Pencere.Gorunum := True;

  if(ParamCount > 0) then
  begin

    GoruntulenecekDosya := ParamStr1(1);
    Resim.Degistir(GoruntulenecekDosya);
    DurumCubugu.DurumYazisiDegistir('Dosya: ' + GoruntulenecekDosya);
  end
  else
  begin

    if(lkDosyaListesi.ToplamElemanSayisiAl > 0) then lkDosyaListesi.SeciliSiraNoYaz(0);
  end;

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
        GoruntulenecekDosya := 'disk1:\' + DosyaAramaListesi[i].DosyaAdi;
        Resim.Degistir(GoruntulenecekDosya);
        DurumCubugu.DurumYazisiDegistir('Dosya: ' + GoruntulenecekDosya);
      end
      // dosya listesini göster / gizle
      else if(Olay.Kimlik = Dugmeler[0]) then
      begin

        if(lkDosyaListesi.Gorunum) then
          lkDosyaListesi.Gizle
        else lkDosyaListesi.Goster;
      end
      // bir önceki düðmesi
      else if(Olay.Kimlik = Dugmeler[1]) then
      begin

        ToplamEleman := lkDosyaListesi.ToplamElemanSayisiAl;
        if(ToplamEleman > 0) then
        begin

          SeciliSiraNo := lkDosyaListesi.SeciliSiraNoAl;
          Dec(SeciliSiraNo);
          if(SeciliSiraNo < 0) then SeciliSiraNo := ToplamEleman - 1;
          lkDosyaListesi.SeciliSiraNoYaz(SeciliSiraNo);
        end;
      end
      // bir sonraki düðmesi
      else if(Olay.Kimlik = Dugmeler[2]) then
      begin

        ToplamEleman := lkDosyaListesi.ToplamElemanSayisiAl;
        if(ToplamEleman > 0) then
        begin

          SeciliSiraNo := lkDosyaListesi.SeciliSiraNoAl;
          Inc(SeciliSiraNo);
          if(SeciliSiraNo >= ToplamEleman) then SeciliSiraNo := 0;
          lkDosyaListesi.SeciliSiraNoYaz(SeciliSiraNo);
        end;
      end;
    end;
  end;
end.
