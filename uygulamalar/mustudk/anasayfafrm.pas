{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_genel, _forms, gn_masaustu, gn_etiket, gn_listekutusu,
  gn_renksecici, gn_karmaliste, n_giysi;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGenel: TGenel;
    FGorev: TGorev;
    FmasELERA: TMasaustu;
    FPencere: TPencere;
    FlkDosyaListesi: TListeKutusu;
    FetiBilgi: array[0..2] of TEtiket;
    FRenkSecici: TRenkSecici;
    FGiysiListesi: TKarmaListe;
    FGiysi: TGiysi;
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
  PencereAdi: string = 'Masaüstü Duvar Kaðýdý';

var
  DosyaAramaListesi: array[0..15] of TDosyaArama;
  GiysiAdi: string;
  i, j: TISayi4;

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 100, 100, 200, 240, ptIletisim, PencereAdi, $F9FAF9);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FetiBilgi[0].Olustur(FPencere.Kimlik, 5, 0, 160, 16, $FF0000, 'Masaüstü Renkleri:');
  FetiBilgi[0].Goster;

  FRenkSecici.Olustur(FPencere.Kimlik, 5, 19, 184, 32);
  FRenkSecici.Goster;

  FetiBilgi[1].Olustur(FPencere.Kimlik, 5, 60, $FF0000, 160, 16, 'Masaüstü Resimleri:');
  FetiBilgi[1].Goster;

  // liste kutusu oluþtur
  FlkDosyaListesi.Olustur(FPencere.Kimlik, 5, 76, 190, 107);
  FlkDosyaListesi.Goster;

  DosyalariListele;

  FetiBilgi[2].Olustur(FPencere.Kimlik, 5, 192, 80, 16, $FF0000, 'Giysiler:');
  FetiBilgi[2].Goster;

  FGiysiListesi.Olustur(FPencere.Kimlik, 5, 210, 190, 25);

  i := FGiysi.Toplam;
  if(i > 0) then
  begin

    for j := 0 to i - 1 do
    begin

      FGiysi.AdAl(j, @GiysiAdi);
      FGiysiListesi.ElemanEkle(GiysiAdi);
    end;

    j := FGiysi.AktifSiraNoAl;
    FGiysiListesi.BaslikSiraNo := j;
  end;
  FGiysiListesi.Goster;
end;

procedure TfrmAnaSayfa.Goster;
begin

  // pencereyi görüntüle
  FPencere.Gorunum := True;

  FmasELERA.AktifMasaustu;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  // çekirdek tarafýndan gönderilen programýn kendisini sonlandýrma talimatý
  if(AOlay.Olay = CO_SONLANDIR) then
  begin

    FGorev.Sonlandir(-1);
  end
  else if(AOlay.Olay = FO_TIKLAMA) then
  begin

    // liste kutusuna týklanmasý halinde dosyayý çalýþtýr
    if(AOlay.Kimlik = FlkDosyaListesi.Kimlik) then
    begin

      i := FlkDosyaListesi.SeciliSiraNoAl;
      FmasELERA.MasaustuResminiDegistir('disk1:\resimler\' + DosyaAramaListesi[i].DosyaAdi);
      FmasELERA.Guncelle;
    end
    else if(AOlay.Kimlik = FRenkSecici.Kimlik) then
    begin

      FmasELERA.MasaustuRenginiDegistir(AOlay.Deger1);
      FmasELERA.Guncelle;
    end;
  end
  else if(AOlay.Olay = CO_SECIMDEGISTI) then
  begin

    FGiysi.Aktiflestir(AOlay.Deger1);
  end;

  Result := 1;
end;

procedure TfrmAnaSayfa.DosyalariListele;
var
  DosyaArama: TDosyaArama;
  AramaSonuc, i, j: TSayi4;
begin

  FlkDosyaListesi.Temizle;

  j := 0;

  AramaSonuc := FGenel._FindFirst('disk1:\resimler\*.*', 0, DosyaArama);

  while (AramaSonuc = 0) do
  begin

    i := Length(DosyaArama.DosyaAdi);
    if(i > 4) and (DosyaArama.DosyaAdi[i - 3] = '.') and
      (DosyaArama.DosyaAdi[i - 2] = 'b') and (DosyaArama.DosyaAdi[i - 1] = 'm') and
      (DosyaArama.DosyaAdi[i] = 'p') then
    begin

      DosyaAramaListesi[j] := DosyaArama;
      FlkDosyaListesi.ElemanEkle(DosyaAramaListesi[j].DosyaAdi);

      Inc(j);
    end;

    AramaSonuc := FGenel._FindNext(DosyaArama);
  end;

  FGenel._FindClose(DosyaArama);
end;

end.
