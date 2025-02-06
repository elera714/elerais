{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_zamanlayici, _forms, gn_panel, gn_etiket, gn_dugme,
  gn_onaykutusu, gn_giriskutusu, gn_durumcubugu, gn_karmaliste, n_iletisim, gn_defter;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGorev: TGorev;
    FPencere: TPencere;
    FUstMesajPaneli,
    FAltMesajPaneli: TPanel;
    FetIPAdresi, FetPort, FetBagTip,
    FetMesaj: TEtiket;
    FDefter: TDefter;
    FDurumCubugu: TDurumCubugu;
    FZamanlayici: TZamanlayici;
    FgkIPAdresi, FgkPort,
    FgkMesaj: TGirisKutusu;
    FklBaglanti: TKarmaListe;
    FdugGonder: TDugme;
    FokBaglanti: TOnayKutusu;
    FIletisim0: TIletisim;
    procedure MesajGonder;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = '�leti�im - TCP/UDP';

var
  IPAdresi, s: string;
  PortNo, Sonuc: TSayi4;
  VeriUzunlugu: TISayi4;

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 50, 50, 570, 400, ptBoyutlanabilir, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  // �st panel
  FUstMesajPaneli.Olustur(FPencere.Kimlik, 10, 10, 250, 40, 2, RENK_SIYAH, $E6E6E6, RENK_SIYAH, '');
  FUstMesajPaneli.Hizala(hzUst);

  FetIPAdresi.Olustur(FUstMesajPaneli.Kimlik, 10, 12, 80, 16, RENK_SIYAH, 'IP Adresi');
  FetIPAdresi.Goster;

  FgkIPAdresi.Olustur(FUstMesajPaneli.Kimlik, 88, 10, 140, 22, '192.168.1.1');
  FgkIPAdresi.Goster;

  FetPort.Olustur(FUstMesajPaneli.Kimlik, 244, 12, 40, 16, RENK_SIYAH, 'Port');
  FetPort.Goster;

  FgkPort.Olustur(FUstMesajPaneli.Kimlik, 280, 10, 60, 22, '80');
  FgkPort.Goster;

  FetBagTip.Olustur(FUstMesajPaneli.Kimlik, 356, 12, 56, 16, RENK_SIYAH, 'Ba�.Tip');
  FetBagTip.Goster;

  FklBaglanti.Olustur(FUstMesajPaneli.Kimlik, 418, 8, 70, 22);
  FklBaglanti.ElemanEkle('TCP');
  FklBaglanti.ElemanEkle('UDP');
  FklBaglanti.BaslikSiraNo := 0;
  FklBaglanti.Goster;

  FokBaglanti.Olustur(FUstMesajPaneli.Kimlik, 500, 11, 'Aktif');
  FokBaglanti.Goster;

  FUstMesajPaneli.Goster;

  // durum g�stergesi
  FDurumCubugu.Olustur(FPencere.Kimlik, 0, 0, 100, 20, 'Ba�lant� yok!');
  FDurumCubugu.Goster;

  // alt panel
  FAltMesajPaneli.Olustur(FPencere.Kimlik, 10, 10, 250, 40, 2, RENK_SIYAH, $E6E6E6, RENK_SIYAH, '');
  FAltMesajPaneli.Hizala(hzAlt);

  FetMesaj.Olustur(FAltMesajPaneli.Kimlik, 10, 12, 40, 16, RENK_SIYAH, 'Mesaj');
  FetMesaj.Goster;

  FgkMesaj.Olustur(FAltMesajPaneli.Kimlik, 56, 10, 435, 22, 'Mesaj');
  FgkMesaj.Goster;

  FdugGonder.Olustur(FAltMesajPaneli.Kimlik, 495, 10, 60, 22, 'G�nder');
  FdugGonder.Goster;

  FAltMesajPaneli.Goster;

  FDefter.Olustur(FPencere.Kimlik, 10, 250 + 85, 410, 150, RENK_BEYAZ, RENK_SIYAH, False);
  FDefter.Hizala(hzTum);
  FDefter.Goster;

  FIletisim0.Constructor0;
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;

  FZamanlayici.Olustur(100);
  FZamanlayici.Baslat;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = CO_ZAMANLAYICI) then
  begin

    if(FIletisim0.Kimlik <> HATA_KIMLIK) then
    begin

      if(FIletisim0.BagliMi) then
      begin

        FDurumCubugu.DurumYazisiDegistir('Ba�lant� kuruldu.');

        VeriUzunlugu := FIletisim0.VeriUzunluguAl;
        if(VeriUzunlugu > 0) then
        begin

          VeriUzunlugu := FIletisim0.VeriOku(@s[1]);
          SetLength(s, VeriUzunlugu);

          FDefter.YaziEkle('Di�er Bilgisayar: ' + s + #13#10);
        end;
      end else FDurumCubugu.DurumYazisiDegistir('Ba�lant� yok!');
    end else FDurumCubugu.DurumYazisiDegistir('Ba�lant� yok!');
  end
  else if(AOlay.Kimlik = FokBaglanti.Kimlik) and (AOlay.Olay = CO_DURUMDEGISTI) then
  begin

    // aktif se�ene�i se�ildi, �yleyse ba�lant� kur
    if(AOlay.Deger1 = 1) then
    begin

      IPAdresi := FgkIPAdresi.IcerikAl;
      s := FgkPort.IcerikAl;

      Val(s, PortNo, Sonuc);
      if(Sonuc <> 0) then PortNo := 0;

      if(Length(IPAdresi) > 0) and (PortNo > 0) then
      begin

        s := FklBaglanti.SeciliYaziAl;
        if(s = 'TCP') then
          FIletisim0.Olustur(ptTCP, IPAdresi, PortNo)
        else FIletisim0.Olustur(ptUDP, IPAdresi, PortNo);

        FIletisim0.Baglan;

        FDefter.Temizle;
      end;
    end
    // aktif se�ene�i pasifle�tirildiyse, �yleyse ba�lant� kes
    else if(AOlay.Deger1 = 0) then FIletisim0.BaglantiyiKes;
  end
  else if((AOlay.Olay = FO_TIKLAMA) and (AOlay.Kimlik = FdugGonder.Kimlik)) or
    ((AOlay.Olay = CO_TUSBASILDI) and (AOlay.Deger1 = 10)) then
  begin

    if(FIletisim0.Kimlik <> HATA_KIMLIK) then MesajGonder;
  end;

  { TODO - ��k��ta bellek bo�alt�lacak }
  // Iletisim0.Destructor0;

  Result := 1;
end;

procedure TfrmAnaSayfa.MesajGonder;
var
  s2: string;
begin

  s2 := FgkMesaj.IcerikAl;
  if(Length(s2) > 0) then
  begin

    FIletisim0.VeriYaz(@s2[1], Length(s2));

    FDefter.YaziEkle('Bu Bilgisayar: ' + s2 + #13#10);

    FgkMesaj.IcerikYaz('');
  end;
end;

end.
