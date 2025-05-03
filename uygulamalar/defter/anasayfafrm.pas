{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_genel, _forms, gn_durumcubugu, gn_etiket, gn_giriskutusu,
  gn_dugme, gn_defter, gn_onaykutusu, gn_panel;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGenel: TGenel;
    FGorev: TGorev;
    FPencere: TPencere;
    FPanel: TPanel;
    FDurumCubugu: TDurumCubugu;
    FDefter0: TDefter;
    FetiDosyaAdi: TEtiket;
    FgkDosyaAdi: TGirisKutusu;
    FokMetniSarmala: TOnayKutusu;
    FdugYukle: TDugme;
    procedure BellekTemizle;
    procedure DosyaAc;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Dijital Defter';
  DOSYA_BELLEK_KAPASITESI = Integer(4096 * 10);

var
  DosyaKimlik: TKimlik;
  DosyaUzunluk: TSayi4;
  DosyaAdi: string;
  DosyaBellek: PChar;

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 10, 10, 490 + 10, 300 + 85, ptBoyutlanabilir, PencereAdi,
    RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FPanel.Olustur(FPencere.Kimlik, 0, 0, 100, 32, 2, RENK_GRI, $E0EEFA, 0, '');
  FPanel.Hizala(hzUst);
  FPanel.Goster;

  FetiDosyaAdi.Olustur(FPanel.Kimlik, 2, 9, 80, 16, $000000, 'Dosya Adý:');
  FetiDosyaAdi.Goster;

  FgkDosyaAdi.Olustur(FPanel.Kimlik, 11 * 8, 6, 24 * 8, 22, '');
  FgkDosyaAdi.IcerikYaz('disk1:\belgeler\haklar.txt');
  FgkDosyaAdi.Goster;

  FdugYukle.Olustur(FPanel.Kimlik, 36 * 8, 5, 60, 22, 'Yükle');
  FdugYukle.Goster;

  FokMetniSarmala.Olustur(FPanel.Kimlik, 45 * 8, 8, 'Metni Sarmala');
  FokMetniSarmala.Goster;

  FDurumCubugu.Olustur(FPencere.Kimlik, 0, 0, 100, 18, 'Dosya: -');
  FDurumCubugu.Goster;

  FDefter0.Olustur(FPencere.Kimlik, 0, 0, 10, 10, RENK_BEYAZ, RENK_SIYAH, False);
  FDefter0.Hizala(hzTum);
  FDefter0.Goster;
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;

  // programa tahsis edilmiþ bellek adresini al
  DosyaBellek := PChar(Isaretci(4)^);

  DosyaAdi := '';

  if(ParamCount > 0) then
  begin

    DosyaAdi := ParamStr1(1);

    FgkDosyaAdi.IcerikYaz(DosyaAdi);

    DosyaAc;
  end;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  // çekirdek tarafýndan gönderilen programýn kendisini sonlandýrma talimatý
  if(AOlay.Olay = CO_SONLANDIR) then
  begin

    FGorev.Sonlandir(-1);
  end
  else if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    if(AOlay.Kimlik = FdugYukle.Kimlik) then
    begin

      DosyaAdi := FgkDosyaAdi.IcerikAl;

      FgkDosyaAdi.IcerikYaz(DosyaAdi);

      DosyaAc;
    end;
  end
  else if(AOlay.Olay = CO_TUSBASILDI) then
  begin

    if(AOlay.Deger1 = 10) then
    begin

      DosyaAdi := FgkDosyaAdi.IcerikAl;

      FgkDosyaAdi.IcerikYaz(DosyaAdi);

      DosyaAc;
    end;
  end
  else if(AOlay.Olay = CO_DURUMDEGISTI) then
  begin

    if(AOlay.Kimlik = FokMetniSarmala.Kimlik) then
    begin

      if(AOlay.Deger1 = 1) then
        FDefter0.MetniSarmala(True)
      else FDefter0.MetniSarmala(False);
    end;
  end;

  Result := 1;
end;

procedure TfrmAnaSayfa.BellekTemizle;
var
  i: TSayi4;
  p: PChar;
begin

  p := DosyaBellek;
  for i := 0 to DOSYA_BELLEK_KAPASITESI - 1 do p[i] := #0;
end;

procedure TfrmAnaSayfa.DosyaAc;
var
  s: string;
begin

  BellekTemizle;

  FDefter0.Temizle;

  FGenel._Assign(DosyaKimlik, DosyaAdi);
  FGenel._Reset(DosyaKimlik);

  DosyaUzunluk := FGenel._FileSize(DosyaKimlik);

  if(DosyaUzunluk <= DOSYA_BELLEK_KAPASITESI) then
  begin

    //_IOResult;

    //_EOF(DosyaKimlik);

    FGenel._FileRead(DosyaKimlik, DosyaBellek);
  end;

  FGenel._Close(DosyaKimlik);

  if(DosyaUzunluk > DOSYA_BELLEK_KAPASITESI) then
  begin

    FDefter0.YaziEkle('Hata: dosya boyutu en fazla ' + IntToStr(DOSYA_BELLEK_KAPASITESI) + ' byte olmalýdýr.' + #0);

    s := 'Dosya: -';

    FDurumCubugu.DurumYazisiDegistir(s);
  end
  else if(DosyaAdi <> '') then
  begin

    FDefter0.YaziEkle(DosyaBellek);

    s := 'Dosya: ' + DosyaAdi + ', ' + IntToStr(DosyaUzunluk) + ' byte';

    FDurumCubugu.DurumYazisiDegistir(s);
  end;
end;

end.
