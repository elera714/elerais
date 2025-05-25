{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_genel, _forms, gn_listegorunum, gn_durumcubugu, gn_panel,
  gn_etiket, gn_karmaliste, n_depolama;

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
    FDurumCubugu: TDurumCubugu;
    FlgDosyaListesi: TListeGorunum;
    procedure DosyalariListele;
    procedure AyarlariDosyayaKaydet;
    procedure AyarDosyasiniOku;
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
  PencereAdi: string = 'Dosya Y�neticisi';

var
  MantiksalDepolama: TMantiksalDepolama3;
  AygitSayisi: TSayi4;
  GecerliSurucu, GecerliKlasor,
  GecerliSuzgec, SeciliYazi,
  AyarSurucu: string;

procedure TfrmAnaSayfa.Olustur;
var
  SeciliSurucu,
  i: TSayi4;
begin

  // ge�erli s�r�c� atamas�
  GecerliSurucu := '';
  GecerliKlasor := '\';
  GecerliSuzgec := '*.*';

  FPencere.Olustur(-1, 80, 80, 660, 355, ptBoyutlanabilir, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FPanel.Olustur(FPencere.Kimlik, 0, 0, 100, 30, 0, 0, 0, 0, '');
  FPanel.Hizala(hzUst);

  FetkYol.Olustur(FPanel.Kimlik, 6, 8, 100, 16, RENK_KIRMIZI, 'Ge�erli Yol:');
  FetkYol.Goster;

  FklSurucu.Olustur(FPanel.Kimlik, 110, 4, 120, 20);
  FklSurucu.Goster;

  FetkYolDegeri.Olustur(FPanel.Kimlik, 240, 8, 120, 16, RENK_LACIVERT, GecerliKlasor + GecerliSuzgec);
  FetkYolDegeri.Goster;

  FPanel.Goster;

  AyarDosyasiniOku;

  // her mant�ksal s�r�c� i�in bir adet d��me olu�tur
  SeciliSurucu := 0;
  AygitSayisi := FDepolama.MantiksalDepolamaAygitSayisiAl;
  if(AygitSayisi > 0) then
  begin

    for i := 0 to AygitSayisi - 1 do
    begin

      if(FDepolama.MantiksalDepolamaAygitBilgisiAl(i, @MantiksalDepolama)) then
      begin

        if(MantiksalDepolama.AygitAdi = AyarSurucu) then SeciliSurucu := i;

        FklSurucu.ElemanEkle(MantiksalDepolama.AygitAdi);
      end;
    end;

    if(FklSurucu.ElemanSayisi > 0) then FklSurucu.BaslikSiraNo := SeciliSurucu;
  end;

  FDurumCubugu.Olustur(FPencere.Kimlik, 0, 0, 100, 20, 'Toplam Klas�r: 0 - Toplam Dosya: 0');
  FDurumCubugu.Goster;

  // liste g�r�n�m nesnesi olu�tur
  FlgDosyaListesi.Olustur(FPencere.Kimlik, 2, 47, 496, 300 - 73);
  FlgDosyaListesi.Hizala(hzTum);

  // liste g�r�n�m ba�l�klar�n� ekle
  FlgDosyaListesi.BaslikEkle('Dosya Ad�', 300);
  FlgDosyaListesi.BaslikEkle('Tarih / Saat', 165);
  FlgDosyaListesi.BaslikEkle('Tip', 80);
  FlgDosyaListesi.BaslikEkle('Boyut', 80);
end;

procedure TfrmAnaSayfa.Goster;
begin

  // pencereyi g�r�nt�le
  FPencere.Gorunum := True;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
var
  DosyaKlasorAdi, TarihSaat,
  GirdiTipi, Boyut: string;
  i: TSayi4;
begin

  // �ekirdek taraf�ndan g�nderilen program�n kendisini sonland�rma talimat�
  if(AOlay.Olay = CO_SONLANDIR) then
  begin

    AyarlariDosyayaKaydet;
    FGorev.Sonlandir(-1);
  end
  // liste kutusuna t�klanmas� halinde dosyay� �al��t�r
  else if(AOlay.Olay = FO_TIKLAMA) and (AOlay.Kimlik = FlgDosyaListesi.Kimlik) then
  begin

    SeciliYazi := FlgDosyaListesi.SeciliYaziAl;

    // dosya bilgisinden dosya ad ve uzant� bilgisini al
    VeriyiParcala(SeciliYazi, DosyaKlasorAdi, TarihSaat, GirdiTipi, Boyut);

{    FSistemMesaj.YaziEkle(mtBilgi, RENK_KIRMIZI, 'Dosya Ad�: ' + DosyaKlasorAdi);
    FSistemMesaj.YaziEkle(mtBilgi, RENK_KIRMIZI, 'Tarih/Saat: ' + TarihSaat);
    FSistemMesaj.YaziEkle(mtBilgi, RENK_KIRMIZI, 'Girdi Tipi: ' + GirdiTipi);
    FSistemMesaj.YaziEkle(mtBilgi, RENK_KIRMIZI, 'Boyut: ' + Boyut); }

    if(GirdiTipi = 'Dosya') and (Length(DosyaKlasorAdi) > 0) then

      FGorev.Calistir(GecerliSurucu + ':' + GecerliKlasor + DosyaKlasorAdi)

    else if(GirdiTipi = 'Klas�r') and (Length(DosyaKlasorAdi) > 0) then
    begin

      // bir �st klas�re ��kma i�lemi
      if(DosyaKlasorAdi = '..') then
      begin

        i := Length(GecerliKlasor);
        i -= 1;           // en sondaki \ i�aretini atla
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

    // dosya bilgisinden dosya ad ve uzant� bilgisini al
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

      Tarih := Tarih2KK(DosyaArama.SonDegisimTarihi);
      Saat := Saat2KK(DosyaArama.SonDegisimSaati);

      if((DosyaArama.Ozellikler and $10) = $10) then
      begin

        YaziRengi := RENK_MAVI;
        GirdiTipi := 'Klas�r';
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

    FDurumCubugu.DurumYazisiDegistir('Toplam Klas�r: ' + IntToStr(ToplamKlasor) +
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

  // dosya ad�
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

// program�n ayarlar�n�n yaz�ld��� dosyay� okur
procedure TfrmAnaSayfa.AyarDosyasiniOku;
var
  DosyaKimlik: TKimlik;
  DosyaBellek: array[0..511] of Char;
  s: string;
  i: TSayi4;
begin

  FGenel._AssignFile(DosyaKimlik, 'disk2:\dsyyntcs.ini');
  FGenel._Reset(DosyaKimlik);

  if(FGenel._IOResult = 0) then
  begin

    FGenel._Read(DosyaKimlik, @DosyaBellek);

    s := PChar(@DosyaBellek[0]);

    i := Pos('=', s);
    if(i > 0) then
    begin

      AyarSurucu := Copy(s, i + 1, Length(s) - i);
    end else AyarSurucu := '';
  end
  else
  begin

    // sistemin kurulu oldu�u s�r�c�y� al
    FGenel.SistemYapiBilgisiAl(0, AyarSurucu);
  end;

  FGenel._CloseFile(DosyaKimlik);
end;

// program�n ayarlar�n� dosyay� yazar
procedure TfrmAnaSayfa.AyarlariDosyayaKaydet;
var
  DosyaKimlik: TKimlik;
begin

  FGenel._AssignFile(DosyaKimlik, 'disk2:\dsyyntcs.ini');
  FGenel._ReWrite(DosyaKimlik);
  if(FGenel._IOResult = 0) then
  begin

    FGenel._Write(DosyaKimlik, 's�r�c�=' + GecerliSurucu);
  end;

  FGenel._CloseFile(DosyaKimlik);
end;

end.
