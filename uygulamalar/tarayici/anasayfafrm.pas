{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_zamanlayici, _forms, gn_panel, gn_dugme, gn_giriskutusu,
  gn_durumcubugu, n_iletisim, gn_defter, gn_etiket;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGorev: TGorev;
    FPencere: TPencere;
    FUstMesajPaneli: TPanel;
    FDefter: TDefter;
    FDurumCubugu: TDurumCubugu;
    FetAdres: TEtiket;
    FgkIPAdresi: TGirisKutusu;
    FZamanlayici: TZamanlayici;
    FdugYukle: TDugme;
    FIletisim0: TIletisim;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Ýnternet Tarayýcýsý';

var
  IPAdresi, SonDurum, s: string;
  VeriUzunlugu: TSayi4;
  SayfaIstendi: Boolean;
  Veriler: array[0..4095] of TSayi1;

procedure TfrmAnaSayfa.Olustur;
begin

  IPAdresi := '192.168.1.1';
  SonDurum := 'Baðlantý yok!';

  FPencere.Olustur(-1, 50, 50, 600, 480, ptBoyutlanabilir, PencereAdi, $FAF1E3);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  // üst panel
  FUstMesajPaneli.Olustur(FPencere.Kimlik, 10, 10, 250, 40, 2, RENK_SIYAH, $FAF1E3, RENK_SIYAH, '');
  FUstMesajPaneli.Hizala(hzUst);

  FetAdres.Olustur(FUstMesajPaneli.Kimlik, 4, 12, RENK_SIYAH, 'Adres');
  FetAdres.Goster;

  FgkIPAdresi.Olustur(FUstMesajPaneli.Kimlik, 50, 9, 456, 22, IPAdresi);
  FgkIPAdresi.Goster;

  FdugYukle.Olustur(FUstMesajPaneli.Kimlik, 520, 7, 55, 22, 'Yükle');
  FdugYukle.Goster;

  FUstMesajPaneli.Goster;

  FDurumCubugu.Olustur(FPencere.Kimlik, 0, 0, 100, 20, SonDurum);
  FDurumCubugu.Goster;

  FDefter.Olustur(FPencere.Kimlik, 5, 34, 583, 421, RENK_BEYAZ, RENK_SIYAH, True);
  FDefter.Hizala(hzTum);
  FDefter.Goster;
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;

  FZamanlayici.Olustur(100);
  FZamanlayici.Baslat;

  SayfaIstendi := False;

  FIletisim0.Constructor0;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = CO_ZAMANLAYICI) then
  begin

    SonDurum := 'Baðlantý yok!';

    if(FIletisim0.Kimlik <> HATA_KIMLIK) then
    begin

      if(FIletisim0.BagliMi) then
      begin

        SonDurum := 'Baðlantý kuruldu.';

        if not(SayfaIstendi) then
        begin

          SonDurum := 'Sayfa bekleniyor...';

          s := 'GET / HTTP/1.1' + #13#10;
          s += 'Host: ' + IPAdresi + #13#10#13#10;

          FIletisim0.VeriYaz(@s[1], Length(s));

          SayfaIstendi := True;
        end
        else if(SayfaIstendi) then
        begin

          VeriUzunlugu := FIletisim0.VeriUzunluguAl;
          if(VeriUzunlugu > 0) then
          begin

            VeriUzunlugu := FIletisim0.VeriOku(@Veriler[0]);
            Veriler[VeriUzunlugu] := 0;

            FDefter.YaziEkle(PChar(@Veriler[0]));

            FIletisim0.BaglantiyiKes;
          end;
        end;
      end;
    end;

    FDurumCubugu.DurumYazisiDegistir(SonDurum);
  end
  else if(AOlay.Olay = FO_TIKLAMA) then
  begin

    if(AOlay.Kimlik = FdugYukle.Kimlik) then
    begin

      IPAdresi := FgkIPAdresi.IcerikAl;

      if(Length(IPAdresi) > 0) then
      begin

        SayfaIstendi := False;

        FDefter.Temizle;

        FIletisim0.Olustur(ptTCP, IPAdresi, 80);
        FIletisim0.Baglan;
      end;
    end;
  end;

  { TODO - çýkýþta / iþi bittiðinde nesne bellekten atýlacak }
  // Iletisim0.Destructor0;

  Result := 1;
end;

end.
