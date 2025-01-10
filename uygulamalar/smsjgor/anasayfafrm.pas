{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_zamanlayici, _forms, gn_durumcubugu, gn_panel,
  gn_dugme, n_sistemmesaj;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGorev: TGorev;
    FDurumCubugu: TDurumCubugu;
    FPencere: TPencere;
    FPanel: TPanel;
    FdugTemizle: TDugme;
    FSistemMesaj: TSistemMesaj;
    FZamanlayici: TZamanlayici;
    FMesaj: TMesaj;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Sistem Mesaj Görüntüleyici';

  USTSINIR_MESAJSAYISI = 18;
  FONT_YUKSEKLIGI = 16;
  PENCERE_BASLIK = 2 + 18 + 2;
  USTPANEL_YUKSEKLIK = 28;
  DURUMCUBUGU_YUKSEKLIK = 20;
  PENCERE_YUKSEKLIK = PENCERE_BASLIK + (USTSINIR_MESAJSAYISI * FONT_YUKSEKLIGI) +
    USTPANEL_YUKSEKLIK + DURUMCUBUGU_YUKSEKLIK;

var
  IlkMesajNo, SatirNo, UstBosluk: TSayi4;
  SistemdekiToplamMesaj,
  ToplamMesaj, i: TISayi4;

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 0, 0, 600, PENCERE_YUKSEKLIK, ptBoyutlanabilir, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FPanel.Olustur(FPencere.Kimlik, 0, 0, 180, USTPANEL_YUKSEKLIK, 2, RENK_GRI, $E0EEFA, 0, '');
  FPanel.Hizala(hzUst);
  FPanel.Goster;

  FdugTemizle.Olustur(FPanel.Kimlik, 3, 3, 18 * 8, 22, 'Kayýtlarý Temizle');
  FdugTemizle.Goster;

  FDurumCubugu.Olustur(FPencere.Kimlik, 0, 0, 100, DURUMCUBUGU_YUKSEKLIK, 'Toplam Mesaj Sayýsý: 0');
  FDurumCubugu.Goster;
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;

  FZamanlayici.Olustur(100);
  FZamanlayici.Baslat;

  ToplamMesaj := 0;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = CO_ZAMANLAYICI) then
  begin

    SistemdekiToplamMesaj := FSistemMesaj.Toplam;
    if(SistemdekiToplamMesaj <> ToplamMesaj) then
    begin

      ToplamMesaj := SistemdekiToplamMesaj;

      FDurumCubugu.DurumYazisiDegistir('Toplam Mesaj Sayýsý: ' + IntToStr(FSistemMesaj.Toplam));

      FPencere.Ciz;
    end;
  end
  else if(AOlay.Olay = FO_SOLTUS_BASILDI) and (AOlay.Kimlik = FdugTemizle.Kimlik) then
  begin

    FSistemMesaj.Temizle;
  end
  else if(AOlay.Olay = CO_CIZIM) then
  begin

    FPencere.Tuval.KalemRengi := $32323E;
    FPencere.Tuval.YaziYaz(0, 30, 'No   Saat     Mesaj');

    if(ToplamMesaj > 0) then
    begin

      if(ToplamMesaj <=  USTSINIR_MESAJSAYISI) then
        IlkMesajNo := 0
      else IlkMesajNo := ToplamMesaj - USTSINIR_MESAJSAYISI;

      UstBosluk := 46;
      SatirNo := 0;

      for i := IlkMesajNo to ToplamMesaj - 1 do
      begin

        FSistemMesaj.Al(i, @FMesaj);
        FPencere.Tuval.KalemRengi := FMesaj.Renk;
        FPencere.Tuval.SayiYaz16(0, UstBosluk + SatirNo * 16, True, 2, FMesaj.SiraNo);
        FPencere.Tuval.SaatYaz(5 * 8, UstBosluk + SatirNo * 16, FMesaj.Saat);
        FPencere.Tuval.YaziYaz(14 * 8, UstBosluk + SatirNo * 16, FMesaj.Mesaj);
        Inc(SatirNo);
      end;
    end;
  end;

  Result := 1;
end;

end.
