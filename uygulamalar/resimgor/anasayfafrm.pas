{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_genel, _forms, gn_listekutusu, gn_resim,
  gn_araccubugu, gn_durumcubugu;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGenel: TGenel;
    FGorev: TGorev;
    FPencere: TPencere;
    FAracCubugu: TAracCubugu;
    FlkDosyaListesi: TListeKutusu;
    FDurumCubugu: TDurumCubugu;
    FResim: TResim;
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
  PencereAdi: string = 'Resim Görüntüleyici';

var
  DosyaAramaListesi: array[0..20] of TDosyaArama;

var
  Dugmeler: array[0..2] of TKimlik;
  i, ToplamEleman, SeciliSiraNo: TISayi4;
  GoruntulenecekDosya: string;

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 50, 50, 600, 450, ptBoyutlanabilir, PencereAdi, $C0C4C3);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FAracCubugu.Olustur(FPencere.Kimlik);
  Dugmeler[0] := FAracCubugu.DugmeEkle(6);
  Dugmeler[1] := FAracCubugu.DugmeEkle(7);
  Dugmeler[2] := FAracCubugu.DugmeEkle(8);
  FAracCubugu.Goster;

  FDurumCubugu.Olustur(FPencere.Kimlik, 0, 0, 10, 22, 'Dosya: -');
  FDurumCubugu.Goster;

  // liste kutusu oluþtur
  FlkDosyaListesi.Olustur(FPencere.Kimlik, 0, 0, 100, 52);
  FlkDosyaListesi.Hizala(hzSol);
  FlkDosyaListesi.Goster;

  FResim.Olustur(FPencere.Kimlik, 0, 60, 490, 420, '');
  FResim.Hizala(hzTum);
  FResim.TuvaleSigdir(True);
  FResim.Goster;

  DosyalariListele;
end;

procedure TfrmAnaSayfa.Goster;
begin

  // pencereyi görüntüle
  FPencere.Gorunum := True;

  if(ParamCount > 0) then
  begin

    GoruntulenecekDosya := ParamStr1(1);
    FResim.Degistir(GoruntulenecekDosya);
    FDurumCubugu.DurumYazisiDegistir('Dosya: ' + GoruntulenecekDosya);
  end
  else
  begin

    if(FlkDosyaListesi.ToplamElemanSayisiAl > 0) then FlkDosyaListesi.SeciliSiraNoYaz(0);
  end;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = FO_TIKLAMA) then
  begin

    // liste kutusuna týklanmasý halinde dosyayý çalýþtýr
    if(AOlay.Kimlik = FlkDosyaListesi.Kimlik) then
    begin

      i := FlkDosyaListesi.SeciliSiraNoAl;
      GoruntulenecekDosya := 'disk1:\resimler\' + DosyaAramaListesi[i].DosyaAdi;
      FResim.Degistir(GoruntulenecekDosya);
      FDurumCubugu.DurumYazisiDegistir('Dosya: ' + GoruntulenecekDosya);
    end
    // dosya listesini göster / gizle
    else if(AOlay.Kimlik = Dugmeler[0]) then
    begin

      if(FlkDosyaListesi.Gorunum) then
        FlkDosyaListesi.Gizle
      else FlkDosyaListesi.Goster;
    end
    // bir önceki düðmesi
    else if(AOlay.Kimlik = Dugmeler[1]) then
    begin

      ToplamEleman := FlkDosyaListesi.ToplamElemanSayisiAl;
      if(ToplamEleman > 0) then
      begin

        SeciliSiraNo := FlkDosyaListesi.SeciliSiraNoAl;
        Dec(SeciliSiraNo);
        if(SeciliSiraNo < 0) then SeciliSiraNo := ToplamEleman - 1;
        FlkDosyaListesi.SeciliSiraNoYaz(SeciliSiraNo);
      end;
    end
    // bir sonraki düðmesi
    else if(AOlay.Kimlik = Dugmeler[2]) then
    begin

      ToplamEleman := FlkDosyaListesi.ToplamElemanSayisiAl;
      if(ToplamEleman > 0) then
      begin

        SeciliSiraNo := FlkDosyaListesi.SeciliSiraNoAl;
        Inc(SeciliSiraNo);
        if(SeciliSiraNo >= ToplamEleman) then SeciliSiraNo := 0;
        FlkDosyaListesi.SeciliSiraNoYaz(SeciliSiraNo);
      end;
    end;
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
    if(i > 4) and (DosyaArama.DosyaAdi[i - 3] = '.') and (DosyaArama.DosyaAdi[i - 2] = 'b') and
      (DosyaArama.DosyaAdi[i - 1] = 'm') and (DosyaArama.DosyaAdi[i] = 'p') then
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
