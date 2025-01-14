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
    FetkSurucu: TEtiket;
    FklSurucu: TKarmaListe;
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

implementation

const
  PencereAdi: string = 'Dosya Yöneticisi';

var
  MantiksalDepolama: TMantiksalDepolama3;
  AygitSayisi, i, DosyaSayisi: TSayi4;
  GecerliSurucu, SeciliYazi, s: string;

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 80, 80, 660, 355, ptBoyutlanabilir, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FPanel.Olustur(FPencere.Kimlik, 0, 0, 100, 30, 0, 0, 0, 0, '');
  FPanel.Hizala(hzUst);

  FetkSurucu.Olustur(FPanel.Kimlik, 6, 8, RENK_MAVI, 'Aktif Sürücü');
  FetkSurucu.Goster;

  FklSurucu.Olustur(FPanel.Kimlik, 110, 4, 120, 20);
  FklSurucu.Goster;

  FPanel.Goster;

  // geçerli sürücü atamasý
  GecerliSurucu := '';

  // her mantýksal sürücü için bir adet düðme oluþtur
  AygitSayisi := FDepolama.MantiksalDepolamaAygitSayisiAl;
  if(AygitSayisi > 0) then
  begin

    for i := 0 to AygitSayisi - 1 do
    begin

      if(FDepolama.MantiksalDepolamaAygitBilgisiAl(i, @MantiksalDepolama)) then
        FklSurucu.ElemanEkle(MantiksalDepolama.AygitAdi);
    end;

    if(FklSurucu.ElemanSayisi > 0) then FklSurucu.BaslikSiraNo := 0;
  end;

  FDurumCubugu.Olustur(FPencere.Kimlik, 0, 0, 100, 20, 'Toplam Dosya: -');
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
begin

  // liste kutusuna týklanmasý halinde dosyayý çalýþtýr
  if(AOlay.Olay = FO_TIKLAMA) and (AOlay.Kimlik = FlgDosyaListesi.Kimlik) then
  begin

    SeciliYazi := FlgDosyaListesi.SeciliYaziAl;

    // dosya bilgisinden dosya ad ve uzantý bilgisini al
    i := Pos('|', SeciliYazi);
    if(i > 0) then
      s := Copy(SeciliYazi, 1, i - 1)
    else s := SeciliYazi;

    FGorev.Calistir(GecerliSurucu + ':\' + s);
  end
  else if(AOlay.Olay = CO_SECIMDEGISTI) and (AOlay.Kimlik = FklSurucu.Kimlik) then
  begin

    GecerliSurucu := FklSurucu.SeciliYaziAl;
    DosyalariListele;
  end;

  Result := 1;
end;

procedure TfrmAnaSayfa.DosyalariListele;
var
  DosyaArama: TDosyaArama;
  AramaSonuc: TSayi4;
  SonDegisimTarihi, SonDegisimSaati: TSayi2;
  TarihDizi: array[0..2] of TSayi2;
  SaatDizi: array[0..2] of TSayi1;
  Tarih, Saat, GirdiTip: string;
  YaziRengi: TRenk;
begin

  if(GecerliSurucu <> '') then
  begin

    FlgDosyaListesi.Temizle;

    DosyaSayisi := 0;

    AramaSonuc := FGenel._FindFirst(GecerliSurucu + ':\*.*', 0, DosyaArama);

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
      begin

        YaziRengi := RENK_MAVI;
        GirdiTip := 'Dizin';
      end
      else
      begin

        YaziRengi := RENK_SIYAH;
        GirdiTip := 'Dosya';
      end;

      FlgDosyaListesi.ElemanEkle(DosyaArama.DosyaAdi + '|' + Tarih + ' ' + Saat + '|' +
        GirdiTip + '|' + IntToStr(DosyaArama.DosyaUzunlugu), YaziRengi);

      Inc(DosyaSayisi);

      AramaSonuc := FGenel._FindNext(DosyaArama);
    end;

    FGenel._FindClose(DosyaArama);

    FDurumCubugu.DurumYazisiDegistir('Toplam Dosya: ' + IntToStr(DosyaSayisi));

    FPencere.Ciz;
  end;
end;

end.
