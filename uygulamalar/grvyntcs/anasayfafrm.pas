{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_zamanlayici, _forms, gn_panel, gn_durumcubugu,
  gn_listegorunum, gn_dugme;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGorev: TGorev;
    FPencere: TPencere;
    FPanel: TPanel;
    FdugSonlandir: TDugme;
    FDurumCubugu: TDurumCubugu;
    FlgGorevListesi: TListeGorunum;
    FZamanlayici: TZamanlayici;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Görev Yöneticisi';

var
  GorevKayit: TGorevKayit;
  UstSinirGorevSayisi, CalisanGorevSayisi: TSayi4;
  SeciliGorevNo, Sonuc: TISayi4;
  i: TKimlik;
  SeciliYazi, s: string;
  AktifSN: TISayi4;

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 100, 150, 600, 300, ptBoyutlanabilir, PencereAdi, $E3DBC8);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FPanel.Olustur(FPencere.Kimlik, 0, 0, 100, 27, 0, 0, 0, 0, '');
  FPanel.Hizala(hzUst);
  FPanel.Goster;

  FdugSonlandir.Olustur(FPanel.Kimlik, 3, 3, 17 * 8, 22, 'Görevi Sonlandýr');
  FdugSonlandir.Goster;

  s := 'Çalýþabilir Program: 0 - Çalýþan Program: 0';
  FDurumCubugu.Olustur(FPencere.Kimlik, 0, 180, 400, 18, s);
  FDurumCubugu.Goster;

  // liste görünüm nesnesi oluþtur
  FlgGorevListesi.Olustur(FPencere.Kimlik, 2, 47, 496, 300 - 73);
  FlgGorevListesi.Hizala(hzTum);

  // liste görünüm baþlýklarýný ekle
  FlgGorevListesi.BaslikEkle('GRV', 32);
  FlgGorevListesi.BaslikEkle('Program Adý', 150);
  FlgGorevListesi.BaslikEkle('Belk.Baþl', 90);
  FlgGorevListesi.BaslikEkle('Belk.Uz.', 90);
  FlgGorevListesi.BaslikEkle('Durum', 50);
  FlgGorevListesi.BaslikEkle('Olay Syç', 80);
  FlgGorevListesi.BaslikEkle('Görev Syç', 80);
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;

  SeciliGorevNo := 0;

  FZamanlayici.Olustur(300);
  FZamanlayici.Baslat;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = FO_TIKLAMA) then
  begin

    if(AOlay.Kimlik = FdugSonlandir.Kimlik) then
    begin

      if(SeciliGorevNo > 0) then FGorev.Sonlandir(SeciliGorevNo);

      // seçilen görev deðerini sýfýrla
      SeciliGorevNo := 0;
    end
    else if(AOlay.Kimlik = FlgGorevListesi.Kimlik) then
    begin

      SeciliYazi := FlgGorevListesi.SeciliYaziAl;

      // dosya bilgisinden dosya ad ve uzantý bilgisini al
      i := Pos('|', SeciliYazi);
      if(i > 0) then
      begin

        s := Copy(SeciliYazi, 1, i - 1);

        Val(s, SeciliGorevNo, Sonuc);
        if(Sonuc <> 0) then SeciliGoreVNo := 0;
      end;
    end
  end
  else if(AOlay.Olay = CO_ZAMANLAYICI) then
  begin

    AktifSN := FlgGorevListesi.SeciliSiraAl;

    // her tetiklemede iþlem sayýsýný denetle ve
    // pencereye yeniden çizilme mesajý gönder
    FlgGorevListesi.Temizle;
    FGorev.GorevSayilariniAl(UstSinirGorevSayisi, CalisanGorevSayisi);

    for i := 0 to CalisanGorevSayisi - 1 do
    begin

      if(FGorev.GorevBilgisiAl(i, @GorevKayit) = 0) then
      begin

        FlgGorevListesi.ElemanEkle(IntToStr(GorevKayit.GorevKimlik) + '|' +
          GorevKayit.ProgramAdi + '|' +
          HexToStr(GorevKayit.BellekBaslangicAdresi, True, 8) + '|' +
          HexToStr(GorevKayit.BellekUzunlugu, True, 8) + '|' +
          IntToStr(Ord(GorevKayit.GorevDurum)) + '|' +
          IntToStr(GorevKayit.OlaySayisi) + '|' +
          IntToStr(GorevKayit.GorevSayaci));
      end;
    end;

    if(AktifSN > CalisanGorevSayisi) then AktifSN := -1;

    FlgGorevListesi.SeciliSiraYaz(AktifSN);

    s := 'Çalýþabilir Program: ' + IntToStr(UstSinirGorevSayisi) +
      ' - Çalýþan Program: ' + IntToStr(CalisanGorevSayisi);
    FDurumCubugu.DurumYazisiDegistir(s);
  end;

  Result := 1;
end;

end.
