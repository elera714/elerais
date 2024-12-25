program smsjgor;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: smsjgor.lpr
  Program Ýþlevi: sistem tarafýndan üretilen mesajlarý görüntüleme programý

  Güncelleme Tarihi: 25/12/2024

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, gn_durumcubugu, gn_panel, gn_dugme, n_zamanlayici, n_sistemmesaj;

const
  ProgramAdi: string = 'Sistem Mesaj Görüntüleyici';

  USTSINIR_MESAJSAYISI = 18;
  FONT_YUKSEKLIGI = 16;
  PENCERE_BASLIK = 2 + 18 + 2;
  USTPANEL_YUKSEKLIK = 28;
  DURUMCUBUGU_YUKSEKLIK = 20;
  PENCERE_YUKSEKLIK = PENCERE_BASLIK + (USTSINIR_MESAJSAYISI * FONT_YUKSEKLIGI) +
    USTPANEL_YUKSEKLIK + DURUMCUBUGU_YUKSEKLIK;

var
  Gorev: TGorev;
  DurumCubugu: TDurumCubugu;
  Pencere: TPencere;
  Panel: TPanel;
  dugTemizle: TDugme;
  SistemMesaj: TSistemMesaj;
  Zamanlayici: TZamanlayici;
  Mesaj: TMesaj;
  Olay: TOlay;
  IlkMesajNo, SatirNo, UstBosluk: TSayi4;
  SistemdekiToplamMesaj,
  ToplamMesaj, i: TISayi4;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 0, 0, 600, PENCERE_YUKSEKLIK, ptBoyutlanabilir,
    ProgramAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Panel.Olustur(Pencere.Kimlik, 0, 0, 180, USTPANEL_YUKSEKLIK, 2, RENK_GRI, $E0EEFA, 0, '');
  Panel.Hizala(hzUst);
  Panel.Goster;

  dugTemizle.Olustur(Panel.Kimlik, 3, 3, 18 * 8, 22, 'Kayýtlarý Temizle');
  dugTemizle.Goster;

  DurumCubugu.Olustur(Pencere.Kimlik, 0, 0, 100, DURUMCUBUGU_YUKSEKLIK, 'Toplam Mesaj Sayýsý: 0');
  DurumCubugu.Goster;

  Pencere.Gorunum := True;

  Zamanlayici.Olustur(100);
  Zamanlayici.Baslat;

  ToplamMesaj := 0;

  while True do
  begin

    Gorev.OlayBekle(Olay);
    if(Olay.Olay = CO_ZAMANLAYICI) then
    begin

      SistemdekiToplamMesaj := SistemMesaj.Toplam;
      if(SistemdekiToplamMesaj <> ToplamMesaj) then
      begin

        ToplamMesaj := SistemdekiToplamMesaj;

        DurumCubugu.DurumYazisiDegistir('Toplam Mesaj Sayýsý: ' + IntToStr(SistemMesaj.Toplam));

        Pencere.Ciz;
      end;
    end
    else if(Olay.Olay = FO_SOLTUS_BASILDI) and (Olay.Kimlik = dugTemizle.Kimlik) then
    begin

      SistemMesaj.Temizle;
    end
    else if(Olay.Olay = CO_CIZIM) then
    begin

      Pencere.Tuval.KalemRengi := $32323E;
      Pencere.Tuval.YaziYaz(0, 30, 'No   Saat     Mesaj');

      if(ToplamMesaj > 0) then
      begin

        if(ToplamMesaj <=  USTSINIR_MESAJSAYISI) then
          IlkMesajNo := 0
        else IlkMesajNo := ToplamMesaj - USTSINIR_MESAJSAYISI;

        UstBosluk := 46;
        SatirNo := 0;

        for i := IlkMesajNo to ToplamMesaj - 1 do
        begin

          SistemMesaj.Al(i, @Mesaj);
          Pencere.Tuval.KalemRengi := Mesaj.Renk;
          Pencere.Tuval.SayiYaz16(0, UstBosluk + SatirNo * 16, True, 2, Mesaj.SiraNo);
          Pencere.Tuval.SaatYaz(5 * 8, UstBosluk + SatirNo * 16, Mesaj.Saat);
          Pencere.Tuval.YaziYaz(14 * 8, UstBosluk + SatirNo * 16, Mesaj.Mesaj);
          Inc(SatirNo);
        end;
      end;
    end;
  end;
end.
