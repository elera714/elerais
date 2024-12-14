program dsyyntcs;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: dsyyntcs.lpr
  Program Ýþlevi: dosya yöneticisi

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
uses n_gorev, gn_pencere, gn_listegorunum, gn_durumcubugu, gn_panel, n_genel,
  gn_etiket, gn_karmaliste, n_depolama;

const
  ProgramAdi: string = 'Dosya Yöneticisi';

var
  Genel: TGenel;
  Gorev: TGorev;
  Depolama: TDepolama;
  Pencere: TPencere;
  Panel: TPanel;
  etkSurucu: TEtiket;
  klSurucu: TKarmaListe;
  DurumCubugu: TDurumCubugu;
  lgDosyaListesi: TListeGorunum;
  Olay: TOlay;
  MantiksalSurucu: TMantiksalSurucu3;
  AygitSayisi, i, DosyaSayisi: TSayi4;
  GecerliSurucu, SeciliYazi, s: string;

procedure DosyalariListele;
var
  DosyaArama: TDosyaArama;
  AramaSonuc: TSayi4;
  SonDegisimTarihi, SonDegisimSaati: TSayi2;
  TarihDizi: array[0..2] of TSayi2;
  SaatDizi: array[0..2] of TSayi1;
  Tarih, Saat, GirdiTip: string;
begin

  if(GecerliSurucu <> '') then
  begin

    lgDosyaListesi.Temizle;

    DosyaSayisi := 0;

    AramaSonuc := Genel._FindFirst(GecerliSurucu + ':\*.*', 0, DosyaArama);

    while (AramaSonuc = 0) do
    begin

      SonDegisimTarihi := DosyaArama.SonDegisimTarihi;
      TarihDizi[0] := SonDegisimTarihi and 31;
      TarihDizi[1] := (SonDegisimTarihi shr 5) and 15;
      TarihDizi[2] := ((SonDegisimTarihi shr 9) and 127) + 1980;
      Tarih := DateToStr(TarihDizi, False);

      SonDegisimSaati := DosyaArama.SonDegisimSaati;
      SaatDizi[2] := (SonDegisimSaati and 31) * 2;
      SaatDizi[1] := (SonDegisimSaati shr 5) and 63;
      SaatDizi[0] := (SonDegisimSaati shr 11) and 31;
      Saat := TimeToStr(SaatDizi);

      if((DosyaArama.Ozellikler and $10) = $10) then
        GirdiTip := 'Dizin'
      else GirdiTip := 'Dosya';

      lgDosyaListesi.ElemanEkle(DosyaArama.DosyaAdi + '|' + Tarih + ' ' + Saat + '|' +
        GirdiTip + '|' + IntToStr(DosyaArama.DosyaUzunlugu));

      Inc(DosyaSayisi);

      AramaSonuc := Genel._FindNext(DosyaArama);
    end;
    Genel._FindClose(DosyaArama);

    DurumCubugu.DurumYazisiDegistir('Toplam Dosya: ' + IntToStr(DosyaSayisi));

    Pencere.Ciz;
  end;
end;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 80, 80, 510, 355, ptBoyutlanabilir, ProgramAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Panel.Olustur(Pencere.Kimlik, 0, 0, 100, 30, 0, 0, 0, 0, '');
  Panel.Hizala(hzUst);

  etkSurucu.Olustur(Panel.Kimlik, 6, 8, RENK_MAVI, 'Aktif Sürücü');
  etkSurucu.Goster;

  klSurucu.Olustur(Panel.Kimlik, 110, 4, 120, 20);
  klSurucu.Goster;

  Panel.Goster;

  // geçerli sürücü atamasý
  GecerliSurucu := '';

  // her mantýksal sürücü için bir adet düðme oluþtur
  AygitSayisi := Depolama.MantiksalDepolamaAygitSayisiAl;
  if(AygitSayisi > 0) then
  begin

    for i := 1 to AygitSayisi do
    begin

      if(Depolama.MantiksalDepolamaAygitBilgisiAl(i, @MantiksalSurucu)) then
        klSurucu.ElemanEkle(MantiksalSurucu.AygitAdi);
    end;

    if(klSurucu.ElemanSayisi > 0) then klSurucu.BaslikSiraNo := 0;
  end;

  DurumCubugu.Olustur(Pencere.Kimlik, 0, 0, 100, 20, 'Toplam Dosya: -');
  DurumCubugu.Goster;

  // liste görünüm nesnesi oluþtur
  lgDosyaListesi.Olustur(Pencere.Kimlik, 2, 47, 496, 300 - 73);
  lgDosyaListesi.Hizala(hzTum);

  // liste görünüm baþlýklarýný ekle
  lgDosyaListesi.BaslikEkle('Dosya Adý', 150);
  lgDosyaListesi.BaslikEkle('Tarih / Saat', 165);
  lgDosyaListesi.BaslikEkle('Tip', 80);
  lgDosyaListesi.BaslikEkle('Boyut', 80);

  // pencereyi görüntüle
  Pencere.Gorunum := True;

  // ana döngü
  while True do
  begin

    Gorev.OlayBekle(Olay);

    // liste kutusuna týklanmasý halinde dosyayý çalýþtýr
    if(Olay.Olay = FO_TIKLAMA) and (Olay.Kimlik = lgDosyaListesi.Kimlik) then
    begin

      SeciliYazi := lgDosyaListesi.SeciliYaziAl;

      // dosya bilgisinden dosya ad ve uzantý bilgisini al
      i := Pos('|', SeciliYazi);
      if(i > 0) then
        s := Copy(SeciliYazi, 1, i - 1)
      else s := SeciliYazi;

      Gorev.Calistir(GecerliSurucu + ':\' + s);
    end
    else if(Olay.Olay = CO_SECIMDEGISTI) and (Olay.Kimlik = klSurucu.Kimlik) then
    begin

      GecerliSurucu := klSurucu.SeciliYaziAl;
      DosyalariListele;
    end;
  end;
end.
