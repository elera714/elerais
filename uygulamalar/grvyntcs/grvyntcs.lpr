program grvyntcs;
{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: grvyntcs.lpr
  Program ��levi: g�rev y�neticisi

  G�ncelleme Tarihi: 01/01/2025

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, n_zamanlayici, gn_panel, gn_durumcubugu, gn_listegorunum,
  gn_dugme;

const
  ProgramAdi: string = 'G�rev Y�neticisi';

var
  Gorev: TGorev;
  Pencere: TPencere;
  Panel: TPanel;
  dugSonlandir: TDugme;
  DurumCubugu: TDurumCubugu;
  lgGorevListesi: TListeGorunum;
  Zamanlayici: TZamanlayici;
  Olay: TOlay;
  GorevKayit: TGorevKayit;
  UstSinirGorevSayisi, CalisanGorevSayisi: TSayi4;
  SeciliGorevNo, Sonuc: TISayi4;
  i: TKimlik;
  SeciliYazi, s: string;
  AktifSN: TISayi4;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 100, 150, 600, 300, ptBoyutlanabilir, ProgramAdi, $E3DBC8);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Panel.Olustur(Pencere.Kimlik, 0, 0, 100, 27, 0, 0, 0, 0, '');
  Panel.Hizala(hzUst);
  Panel.Goster;

  dugSonlandir.Olustur(Panel.Kimlik, 3, 3, 17 * 8, 22, 'G�revi Sonland�r');
  dugSonlandir.Goster;

  s := '�al��abilir Program: 0 - �al��an Program: 0';
  DurumCubugu.Olustur(Pencere.Kimlik, 0, 180, 400, 18, s);
  DurumCubugu.Goster;

  // liste g�r�n�m nesnesi olu�tur
  lgGorevListesi.Olustur(Pencere.Kimlik, 2, 47, 496, 300 - 73);
  lgGorevListesi.Hizala(hzTum);

  // liste g�r�n�m ba�l�klar�n� ekle
  lgGorevListesi.BaslikEkle('GRV', 32);
  lgGorevListesi.BaslikEkle('Program Ad�', 150);
  lgGorevListesi.BaslikEkle('Belk.Ba�l', 90);
  lgGorevListesi.BaslikEkle('Belk.Uz.', 90);
  lgGorevListesi.BaslikEkle('Durum', 50);
  lgGorevListesi.BaslikEkle('Olay Sy�', 80);
  lgGorevListesi.BaslikEkle('G�rev Sy�', 80);

  Pencere.Gorunum := True;

  SeciliGorevNo := 0;

  Zamanlayici.Olustur(300);
  Zamanlayici.Baslat;

  while True do
  begin

    Gorev.OlayBekle(Olay);

    if(Olay.Olay = FO_TIKLAMA) then
    begin

      if(Olay.Kimlik = dugSonlandir.Kimlik) then
      begin

        if(SeciliGorevNo > 0) then Gorev.Sonlandir(SeciliGorevNo);

        // se�ilen g�rev de�erini s�f�rla
        SeciliGorevNo := 0;
      end
      else if(Olay.Kimlik = lgGorevListesi.Kimlik) then
      begin

        SeciliYazi := lgGorevListesi.SeciliYaziAl;

        // dosya bilgisinden dosya ad ve uzant� bilgisini al
        i := Pos('|', SeciliYazi);
        if(i > 0) then
        begin

          s := Copy(SeciliYazi, 1, i - 1);

          Val(s, SeciliGorevNo, Sonuc);
          if(Sonuc <> 0) then SeciliGoreVNo := 0;
        end;
      end
    end
    else if(Olay.Olay = CO_ZAMANLAYICI) then
    begin

      AktifSN := lgGorevListesi.SeciliSiraAl;

      // her tetiklemede i�lem say�s�n� denetle ve
      // pencereye yeniden �izilme mesaj� g�nder
      lgGorevListesi.Temizle;
      Gorev.GorevSayilariniAl(UstSinirGorevSayisi, CalisanGorevSayisi);

      for i := 0 to CalisanGorevSayisi - 1 do
      begin

        if(Gorev.GorevBilgisiAl(i, @GorevKayit) = 0) then
        begin

          lgGorevListesi.ElemanEkle(IntToStr(GorevKayit.GorevKimlik) + '|' +
            GorevKayit.ProgramAdi + '|' +
            HexToStr(GorevKayit.BellekBaslangicAdresi, True, 8) + '|' +
            HexToStr(GorevKayit.BellekUzunlugu, True, 8) + '|' +
            IntToStr(Ord(GorevKayit.GorevDurum)) + '|' +
            IntToStr(GorevKayit.OlaySayisi) + '|' +
            IntToStr(GorevKayit.GorevSayaci));
        end;
      end;

      if(AktifSN > CalisanGorevSayisi) then AktifSN := -1;

      lgGorevListesi.SeciliSiraYaz(AktifSN);

      s := '�al��abilir Program: ' + IntToStr(UstSinirGorevSayisi) +
        ' - �al��an Program: ' + IntToStr(CalisanGorevSayisi);
      DurumCubugu.DurumYazisiDegistir(s);
    end;
  end;
end.
