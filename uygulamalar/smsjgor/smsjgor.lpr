program smsjgor;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: smsjgor.lpr
  Program Ýþlevi: sistem tarafýndan üretilen mesajlarý görüntüleme programý

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, gn_durumcubugu, n_zamanlayici, n_sistemmesaj;

const
  ProgramAdi: string = 'Sistem Mesaj Görüntüleyici';

  USTSINIR_MESAJSAYISI = 18;
  FONT_YUKSEKLIGI = 16;
  PENCERE_BASLIK = 2 + 18 + 2;
  DURUMCUBUGU_YUKSEKLIK = 20;
  PENCERE_YUKSEKLIK = PENCERE_BASLIK + (USTSINIR_MESAJSAYISI * FONT_YUKSEKLIGI) + DURUMCUBUGU_YUKSEKLIK;

var
  Gorev: TGorev;
  DurumCubugu: TDurumCubugu;
  Pencere: TPencere;
  SistemMesaj: TSistemMesaj;
  Zamanlayici: TZamanlayici;
  Mesaj: TMesaj;
  Olay: TOlay;
  SistemdekiToplamMesaj, ToplamMesaj,
  IlkMesajNo, i, SatirNo: TSayi4;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 0, 0, 600, PENCERE_YUKSEKLIK, ptBoyutlanabilir,
    ProgramAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  DurumCubugu.Olustur(Pencere.Kimlik, 0, 0, 100, 20, 'Toplam Mesaj Sayýsý: 0');
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
      if(SistemdekiToplamMesaj <> ToplamMesaj) then ToplamMesaj := SistemdekiToplamMesaj;

      DurumCubugu.DurumYazisiDegistir('Toplam Mesaj Sayýsý: ' + IntToStr(SistemMesaj.Toplam));

      Pencere.Ciz;
    end

    else if(Olay.Olay = CO_CIZIM) then
    begin

      Pencere.Tuval.KalemRengi := $32323E;
      Pencere.Tuval.YaziYaz(0, 0, 'No   Saat     Mesaj');

      if(ToplamMesaj > 0) then
      begin

        if(ToplamMesaj <=  USTSINIR_MESAJSAYISI) then
          IlkMesajNo := 1
        else
          IlkMesajNo := ToplamMesaj-USTSINIR_MESAJSAYISI+1;

        SatirNo := 1;

        for i := IlkMesajNo to ToplamMesaj do
        begin

          SistemMesaj.Al(i, @Mesaj);
          Pencere.Tuval.KalemRengi := Mesaj.Renk;
          Pencere.Tuval.SayiYaz16(0, SatirNo * 16, True, 2, Mesaj.SiraNo);
          Pencere.Tuval.SaatYaz(5 * 8, SatirNo * 16, Mesaj.Saat);
          Pencere.Tuval.YaziYaz(14 * 8, SatirNo * 16, Mesaj.Mesaj);
          Inc(SatirNo);
        end;
      end;
    end;
  end;
end.
