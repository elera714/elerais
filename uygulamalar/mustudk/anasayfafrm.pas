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
    procedure AyarlariDosyayaKaydet;
    procedure AyarDosyasiniOku;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;
  ArkaPlan: TSayi4;             // arka plan: 1 = arka plan rengi, 2 = duvar kaðýdý
  DuvarKagidi: string;          // duvar kaðýdý dosya adý
  ArkaPlanRengi: TRenk;         // masaüstü arka planrengi
  AktifGiysi: TSayi4;           // aktif giysi sýra no

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

  AyarDosyasiniOku;

  i := FGiysi.Toplam;
  if(i > 0) then
  begin

    for j := 0 to i - 1 do
    begin

      FGiysi.AdAl(j, @GiysiAdi);
      FGiysiListesi.ElemanEkle(GiysiAdi);
    end;

    FGiysiListesi.BaslikSiraNo := AktifGiysi;
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

      ArkaPlan := 2;
      i := FlkDosyaListesi.SeciliSiraNoAl;
      DuvarKagidi := 'disk1:\resimler\' + DosyaAramaListesi[i].DosyaAdi;
      FmasELERA.MasaustuResminiDegistir(DuvarKagidi);
      FmasELERA.Guncelle;

      AyarlariDosyayaKaydet;
    end
    else if(AOlay.Kimlik = FRenkSecici.Kimlik) then
    begin

      ArkaPlan := 1;
      ArkaPlanRengi := AOlay.Deger1;
      FmasELERA.MasaustuRenginiDegistir(ArkaPlanRengi);
      FmasELERA.Guncelle;

      AyarlariDosyayaKaydet;
    end;
  end
  else if(AOlay.Olay = CO_SECIMDEGISTI) then
  begin

    AktifGiysi := AOlay.Deger1;
    FGiysi.Aktiflestir(AktifGiysi);

    AyarlariDosyayaKaydet;
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

// program ayarlarýný dosyaya kaydeder
procedure TfrmAnaSayfa.AyarlariDosyayaKaydet;
var
  DosyaKimlik: TKimlik;
begin

  FGenel._AssignFile(DosyaKimlik, 'disk2:\muyntcs.ini');
  FGenel._ReWrite(DosyaKimlik);
  if(FGenel._IOResult = 0) then
  begin

    FGenel._Write(DosyaKimlik, 'arkaplan=' + IntToStr(ArkaPlan) + #13#10);
    FGenel._Write(DosyaKimlik, 'duvarkagidi=' + DuvarKagidi + #13#10);
    FGenel._Write(DosyaKimlik, 'arkaplanrengi=' + IntToStr(ArkaPlanRengi) + #13#10);
	  FGenel._Write(DosyaKimlik, 'aktifgiysi=' + IntToStr(AktifGiysi));
  end;

  FGenel._CloseFile(DosyaKimlik);
end;

// program ayarlarýný dosyadan okur
procedure TfrmAnaSayfa.AyarDosyasiniOku;
var
  DosyaKimlik: TKimlik;
  DosyaBellek: array[0..511] of Char;
  DosyaIcerik, s,
  Ozellik, Deger: string;
  i: TSayi4;
  Devam: Boolean;
begin

  FGenel._AssignFile(DosyaKimlik, 'disk2:\muyntcs.ini');
  FGenel._Reset(DosyaKimlik);

  if(FGenel._IOResult = 0) then
  begin

    FGenel._Read(DosyaKimlik, @DosyaBellek);

    DosyaIcerik := PChar(@DosyaBellek[0]);

    Devam := True;
    while Devam do
    begin

      i := Pos(#10, DosyaIcerik);
      if(i > 0) then
      begin

        s := Copy(DosyaIcerik, 1, i - 2);
        Delete(DosyaIcerik, 1, i);
      end
      else
      begin

        s := DosyaIcerik;
        Devam := False;
      end;

      if(Length(s) > 0) then
      begin

        i := Pos('=', s);
        if(i > 0) then
        begin

          Ozellik := Copy(s, 1, i - 1);
          Deger := Copy(s, i + 1, Length(s) - i);

          case Ozellik of
            'arkaplan'      : ArkaPlan := StrToInt(Deger);
            'duvarkagidi'   : DuvarKagidi := Deger;
            'arkaplanrengi' : ArkaPlanRengi := StrToInt(Deger);
            'aktifgiysi'    : AktifGiysi := StrToInt(Deger);
          end;
        end;
      end;
    end;
  end
  else
  begin

    // sistemin kurulu olduðu sürücüyü al
    ArkaPlan := 1;
    DuvarKagidi := '';
    ArkaPlanRengi := RENK_TURKUAZ;
    AktifGiysi := 0;
  end;

  FGenel._CloseFile(DosyaKimlik);
end;

end.
