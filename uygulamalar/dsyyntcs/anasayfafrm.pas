{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_genel, _forms, gn_listegorunum, gn_durumcubugu, gn_panel,
  gn_etiket, gn_karmaliste, n_depolama, n_sistemmesaj;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGenel: TGenel;
    FGorev: TGorev;
    FDepolama: TDepolama;
    FPencere: TPencere;
    FPanel: TPanel;
    FetkYol,
    FetkYolDegeri: TEtiket;
    FklSurucu: TKarmaListe;
    FSistemMesaj: TSistemMesaj;
    FDurumCubugu: TDurumCubugu;
    FlgDosyaListesi: TListeGorunum;
    procedure DosyalariListele;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

procedure VeriyiParcala(const AVeri: string; var ADosyaAdi, ATarihSaat, AGirdiTipi, ABoyut: string);

implementation

const
  PencereAdi: string = 'Dosya Yöneticisi';

var
  MantiksalDepolama: TMantiksalDepolama3;
  AygitSayisi: TSayi4;
  GecerliSurucu, GecerliKlasor,
  GecerliSuzgec, SeciliYazi: string;

procedure TfrmAnaSayfa.Olustur;
var
  SeciliSurucu,
  i: TSayi4;
  SistemKuruluSurucu: string;
begin

  // geçerli sürücü atamasý
  GecerliSurucu := '';
  GecerliKlasor := '\';
  GecerliSuzgec := '*.*';

  FPencere.Olustur(-1, 80, 80, 660, 355, ptBoyutlanabilir, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FPanel.Olustur(FPencere.Kimlik, 0, 0, 100, 30, 0, 0, 0, 0, '');
  FPanel.Hizala(hzUst);

  FetkYol.Olustur(FPanel.Kimlik, 6, 8, 100, 16, RENK_KIRMIZI, 'Geçerli Yol:');
  FetkYol.Goster;

  FklSurucu.Olustur(FPanel.Kimlik, 110, 4, 120, 20);
  FklSurucu.Goster;

  FetkYolDegeri.Olustur(FPanel.Kimlik, 240, 8, 120, 16, RENK_LACIVERT, GecerliKlasor + GecerliSuzgec);
  FetkYolDegeri.Goster;

  FPanel.Goster;

  // sistemin kurulu olduðu sürücüyü al
  FGenel.SistemYapiBilgisiAl(0, SistemKuruluSurucu);

  // her mantýksal sürücü için bir adet düðme oluþtur
  SeciliSurucu := 0;
  AygitSayisi := FDepolama.MantiksalDepolamaAygitSayisiAl;
  if(AygitSayisi > 0) then
  begin

    for i := 0 to AygitSayisi - 1 do
    begin

      if(FDepolama.MantiksalDepolamaAygitBilgisiAl(i, @MantiksalDepolama)) then
      begin

        if(MantiksalDepolama.AygitAdi = SistemKuruluSurucu) then SeciliSurucu := i;

        FklSurucu.ElemanEkle(MantiksalDepolama.AygitAdi);
      end;
    end;

    if(FklSurucu.ElemanSayisi > 0) then FklSurucu.BaslikSiraNo := SeciliSurucu;
  end;

  FDurumCubugu.Olustur(FPencere.Kimlik, 0, 0, 100, 20, 'Toplam Klasör: 0 - Toplam Dosya: 0');
  FDurumCubugu.Goster;

  // liste görünüm nesnesi oluþtur
  FlgDosyaListesi.Olustur(FPencere.Kimlik, 2, 47, 496, 300 - 73);
  FlgDosyaListesi.Hizala(hzTum);

  // liste görünüm baþlýklarýný ekle
  FlgDosyaListesi.BaslikEkle('Dosya Adý', 300);
  FlgDosyaListesi.BaslikEkle('Tarih / Saat', 165);
  FlgDosyaListesi.BaslikEkle('Tip', 80);
  FlgDosyaListesi.BaslikEkle('Boyut', 80);
end;

procedure TfrmAnaSayfa.Goster;
begin

  // pencereyi görüntüle
  FPencere.Gorunum := True;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
var
  DosyaKlasorAdi, TarihSaat,
  GirdiTipi, Boyut: string;
  i: TSayi4;
begin

  // liste kutusuna týklanmasý halinde dosyayý çalýþtýr
  if(AOlay.Olay = FO_TIKLAMA) and (AOlay.Kimlik = FlgDosyaListesi.Kimlik) then
  begin

    SeciliYazi := FlgDosyaListesi.SeciliYaziAl;

    // dosya bilgisinden dosya ad ve uzantý bilgisini al
    VeriyiParcala(SeciliYazi, DosyaKlasorAdi, TarihSaat, GirdiTipi, Boyut);

{    FSistemMesaj.YaziEkle(mtBilgi, RENK_KIRMIZI, 'Dosya Adý: ' + DosyaKlasorAdi);
    FSistemMesaj.YaziEkle(mtBilgi, RENK_KIRMIZI, 'Tarih/Saat: ' + TarihSaat);
    FSistemMesaj.YaziEkle(mtBilgi, RENK_KIRMIZI, 'Girdi Tipi: ' + GirdiTipi);
    FSistemMesaj.YaziEkle(mtBilgi, RENK_KIRMIZI, 'Boyut: ' + Boyut); }

    if(GirdiTipi = 'Dosya') and (Length(DosyaKlasorAdi) > 0) then

      FGorev.Calistir(GecerliSurucu + ':' + GecerliKlasor + DosyaKlasorAdi)

    else if(GirdiTipi = 'Klasör') and (Length(DosyaKlasorAdi) > 0) then
    begin

      // bir üst klasöre çýkma iþlemi
      if(DosyaKlasorAdi = '..') then
      begin

        i := Length(GecerliKlasor);
        i -= 1;           // en sondaki \ iþaretini atla
        while GecerliKlasor[i] <> '\' do Dec(i);

        GecerliKlasor := Copy(GecerliKlasor, 1, i);

      end else GecerliKlasor := GecerliKlasor + DosyaKlasorAdi + '\';

      FetkYolDegeri.BaslikDegistir(GecerliKlasor + GecerliSuzgec);

      DosyalariListele;
    end;
  end
  else if(AOlay.Olay = CO_SECIMDEGISTI) and (AOlay.Kimlik = FklSurucu.Kimlik) then
  begin

    GecerliSurucu := FklSurucu.SeciliYaziAl;
    GecerliKlasor := '\';
    FetkYolDegeri.BaslikDegistir(GecerliKlasor + GecerliSuzgec);

    DosyalariListele;
  end
  else if(AOlay.Olay = CO_TUSBASILDI) and (AOlay.Deger1 = TUS_SIL) {and (AOlay.Kimlik = FlgDosyaListesi.Kimlik)} then
  begin

    SeciliYazi := FlgDosyaListesi.SeciliYaziAl;

    // dosya bilgisinden dosya ad ve uzantý bilgisini al
    VeriyiParcala(SeciliYazi, DosyaKlasorAdi, TarihSaat, GirdiTipi, Boyut);

    if(Length(DosyaKlasorAdi) > 0) then
    begin

      if(GirdiTipi = 'Dosya') then
        FGenel._DeleteFile(GecerliSurucu + ':' + GecerliKlasor + DosyaKlasorAdi)
      else FGenel._RemoveDir(GecerliSurucu + ':' + GecerliKlasor + DosyaKlasorAdi);

      DosyalariListele;
    end;
  end;

  Result := 1;
end;

procedure TfrmAnaSayfa.DosyalariListele;
var
  DosyaArama: TDosyaArama;
  AramaSonuc, ToplamKlasor,
  ToplamDosya: TSayi4;
  SonDegisimSaati: TSayi2;
  TarihDizi: array[0..2] of TSayi2;
  SaatDizi: array[0..2] of TSayi1;
  Tarih, Saat, GirdiTipi: string;
  YaziRengi: TRenk;
begin

  if(GecerliSurucu <> '') then
  begin

    FlgDosyaListesi.Temizle;

    ToplamKlasor := 0;
    ToplamDosya := 0;

    AramaSonuc := FGenel._FindFirst(GecerliSurucu + ':' + GecerliKlasor +
      GecerliSuzgec, 0, DosyaArama);

    while (AramaSonuc = 0) do
    begin

      {SonDegisimTarihi := DosyaArama.SonDegisimTarihi;
      TarihDizi[0] := SonDegisimTarihi and 31;
      TarihDizi[1] := (SonDegisimTarihi shr 5) and 15;
      TarihDizi[2] := ((SonDegisimTarihi shr 9) and 127) + 1980;}
      Tarih := Tarih2KK(DosyaArama.SonDegisimTarihi);

      {SonDegisimSaati := DosyaArama.SonDegisimSaati;
      SaatDizi[2] := (SonDegisimSaati and 31) * 2;
      SaatDizi[1] := (SonDegisimSaati shr 5) and 63;
      SaatDizi[0] := (SonDegisimSaati shr 11) and 31;}
      Saat := Saat2KK(DosyaArama.SonDegisimSaati);

      if((DosyaArama.Ozellikler and $10) = $10) then
      begin

        YaziRengi := RENK_MAVI;
        GirdiTipi := 'Klasör';
        Inc(ToplamKlasor);
      end
      else
      begin

        YaziRengi := RENK_SIYAH;
        GirdiTipi := 'Dosya';
        Inc(ToplamDosya);
      end;

      FlgDosyaListesi.ElemanEkle(DosyaArama.DosyaAdi + '|' + Tarih + ' ' + Saat + '|' +
        GirdiTipi + '|' + IntToStr(DosyaArama.DosyaUzunlugu), YaziRengi);

      AramaSonuc := FGenel._FindNext(DosyaArama);
    end;

    FGenel._FindClose(DosyaArama);

    FDurumCubugu.DurumYazisiDegistir('Toplam Klasör: ' + IntToStr(ToplamKlasor) +
      ' - Toplam Dosya: ' + IntToStr(ToplamDosya));

    FPencere.Ciz;
  end;
end;

procedure VeriyiParcala(const AVeri: string; var ADosyaAdi, ATarihSaat, AGirdiTipi, ABoyut: string);
var
  s: string;
  i: TSayi4;
begin

  ADosyaAdi := '';
  ATarihSaat := '';
  AGirdiTipi := '';
  ABoyut := '';

  s := AVeri;

  // dosya adý
  i := Pos('|', s);
  if(i = 0) then Exit;
  ADosyaAdi := Copy(s, 1, i - 1);
  s := Copy(s, i + 1, Length(s) - i);

  // tarih / saat
  i := Pos('|', s);
  if(i = 0) then Exit;
  ATarihSaat := Copy(s, 1, i - 1);
  s := Copy(s, i + 1, Length(s) - i);

  // girdi tipi
  i := Pos('|', s);
  if(i = 0) then Exit;
  AGirdiTipi := Copy(s, 1, i - 1);
  s := Copy(s, i + 1, Length(s) - i);

  // boyut
  ABoyut := s;
end;

end.
