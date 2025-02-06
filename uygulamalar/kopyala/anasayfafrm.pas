{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, _forms, gn_islemgostergesi, gn_dugme, gn_etiket,
  gn_karmaliste, n_depolama;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGorev: TGorev;
    FDepolama: TDepolama;
    FPencere: TPencere;
    FetkSuruculer, FetkKaynak, FetkHedef, FetkBilgi: TEtiket;
    FklKaynak, FklHedef: TKarmaListe;
    FIslemGostergesi: TIslemGostergesi;
    FdugKopyala: TDugme;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Disk Kopyala';

var
  AygitDurum: TISayi4;
  FizikselAygitSayisi, DiskAygitSayisi,
  i: TSayi4;
  // FizikselDepolamaListesi: 0 = genel / ge�ici kullan�m, 1 = disk1, 2 = disk2
  FizikselDepolamaListesi: array[0..2] of TFizikselDepolama3;
  DiskBellek: array[0..511] of TSayi1;

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 100, 100, 350, 210, ptIletisim, PencereAdi, RENK_BEYAZ);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FetkSuruculer.Olustur(FPencere.Kimlik, 40, 16, 260, 16, RENK_MAVI, 'Fiziksel Disk Depolama Ayg�tlar�');
  FetkSuruculer.Goster;

  FetkKaynak.Olustur(FPencere.Kimlik, 36, 50, 90, 16, RENK_MOR, 'Kaynak Disk');
  FetkKaynak.Goster;

  FetkHedef.Olustur(FPencere.Kimlik, 195, 50, 80, 16, RENK_MOR, 'Hedef Disk');
  FetkHedef.Goster;

  FklKaynak.Olustur(FPencere.Kimlik, 40, 70, 110, 20);
  FklKaynak.Goster;

  FklHedef.Olustur(FPencere.Kimlik, 200, 70, 110, 20);
  FklHedef.Goster;

  FetkBilgi.Olustur(FPencere.Kimlik, 10, 102, 260, 16, RENK_KIRMIZI, 'Bilgi: -');
  FetkBilgi.Goster;

  FIslemGostergesi.Olustur(FPencere.Kimlik, 10, 125, 330, 22);
  FIslemGostergesi.DegerleriBelirle(0, $E800);
  FIslemGostergesi.KonumBelirle(0);
  FIslemGostergesi.Goster;

  FdugKopyala.Olustur(FPencere.Kimlik, 90, 165, 170, 30, 'Diski Kopyala');
  FdugKopyala.Goster;

  { TODO - sistemde 2 adet disk ayg�t�n�n olmamas� durumunda kullan�c�ya uyar� bilgisi verilecek }
  FizikselAygitSayisi := FDepolama.FizikselDepolamaAygitSayisiAl;
  if(FizikselAygitSayisi > 0) then
  begin

    DiskAygitSayisi := 0;
    for i := 0 to FizikselAygitSayisi - 1 do
    begin

      if(FDepolama.FizikselDepolamaAygitBilgisiAl(i, @FizikselDepolamaListesi[0]) > 0) then
      begin

        if(FizikselDepolamaListesi[0].SurucuTipi = SURUCUTIP_DISK) and (DiskAygitSayisi < 2) then
        begin

          Inc(DiskAygitSayisi);

          // disk s�r�c� bilgilerini kaydet
          FizikselDepolamaListesi[DiskAygitSayisi] := FizikselDepolamaListesi[0];

          FklKaynak.ElemanEkle(FizikselDepolamaListesi[DiskAygitSayisi].AygitAdi);
          FklHedef.ElemanEkle(FizikselDepolamaListesi[DiskAygitSayisi].AygitAdi);
        end;
      end;
    end;

    // 2 adet disk s�r�c�s� listeye eklenmi� mi?
    if(DiskAygitSayisi = 2) then
    begin

      FklKaynak.BaslikSiraNo := 0;
      FklHedef.BaslikSiraNo := 1;
    end
    else
    // eklenmemi� ise listeyi tamamen temizle
    begin

      FklKaynak.Temizle;
      FklHedef.Temizle;
    end;
  end;
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = FO_TIKLAMA) then
  begin

    if(AOlay.Kimlik = FdugKopyala.Kimlik) then
    begin

      // kaynak / hedef ayg�t se�ili ise kopyalama i�lemine ba�la
      if not((FklKaynak.BaslikSiraNo = -1) and (FklHedef.BaslikSiraNo = -1)) then
      begin

        FetkBilgi.BaslikDegistir('Kopyalama i�lemi devam ediyor...');

        { TODO $FFCC de�eri olan toplam sekt�r de�eri sistemden al�nacak ve her 2 diskin
          ayn� say�da sekt�r / kafa / iz i�erik denkli�i do�rulanacak }
        for i := 0 to $FFCC - 1 do
        begin

          // disk sekt�r okuma i�lemi
          AygitDurum := FDepolama.FizikselDepolamaVeriOku(
            FizikselDepolamaListesi[FklKaynak.BaslikSiraNo + 1].Kimlik, i, 1, @DiskBellek);
          if(AygitDurum <> 0) then
          begin

            FetkBilgi.BaslikDegistir('Hata: disk okuma hatas�!');
            Exit;
          end;

          // disk sekt�r yazma i�lemi
          AygitDurum := FDepolama.FizikselDepolamaVeriYaz(
            FizikselDepolamaListesi[FklHedef.BaslikSiraNo + 1].Kimlik, i, 1, @DiskBellek);
          if(AygitDurum <> 0) then
          begin

            FetkBilgi.BaslikDegistir('Hata: disk yazma hatas�!');
            Exit;
          end;

          FIslemGostergesi.KonumBelirle(i);
        end;

        FetkBilgi.BaslikDegistir('Kopyalama i�lemi tamamland�.');
      end;
    end;
  end
  else if(AOlay.Olay = CO_SECIMDEGISTI) then
  begin

    if(AOlay.Kimlik = FklKaynak.Kimlik) then
    begin
      if(AOlay.Deger1 = 0) and (FklHedef.BaslikSiraNo = 0) then FklHedef.BaslikSiraNo := 1
      else if(AOlay.Deger1 = 1) and (FklHedef.BaslikSiraNo = 1) then FklHedef.BaslikSiraNo := 0;
    end
    else if(AOlay.Kimlik = FklHedef.Kimlik) then
    begin
      if(AOlay.Deger1 = 0) and (FklKaynak.BaslikSiraNo = 0) then FklKaynak.BaslikSiraNo := 1
      else if(AOlay.Deger1 = 1) and (FklKaynak.BaslikSiraNo = 1) then FklKaynak.BaslikSiraNo := 0;
    end;
  end;

  Result := 1;
end;

end.
