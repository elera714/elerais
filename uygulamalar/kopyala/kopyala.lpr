program kopyala;
{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: kopyala.lpr
  Program ��levi: fiziksel disk kopyalama i�levini ger�ekle�tirir

  G�ncelleme Tarihi: 08/01/2025

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, gn_islemgostergesi, gn_dugme, gn_etiket, gn_karmaliste,
  n_depolama;

const
  ProgramAdi: string = 'Disk Kopyala';

label OlayBekle;

var
  Gorev: TGorev;
  Depolama: TDepolama;
  Pencere: TPencere;
  etkSuruculer, etkKaynak, etkHedef, etkBilgi: TEtiket;
  klKaynak, klHedef: TKarmaListe;
  IslemGostergesi: TIslemGostergesi;
  Dugme: TDugme;
  Olay: TOlay;
  AygitDurum: TISayi4;
  FizikselAygitSayisi, DiskAygitSayisi, i,
  KaynakDisk, HedefDisk: TSayi4;
  // FizikselSurucuListesi: 0 = genel, 1 = disk1, 2 = disk2
  FizikselSurucuListesi: array[0..2] of TFizikselSurucu3;
  DiskBellek: array[0..511] of TSayi1;

begin
  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 100, 100, 350, 210, ptIletisim, ProgramAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  etkSuruculer.Olustur(Pencere.Kimlik, 40, 16, RENK_MAVI, 'Fiziksel Disk Depolama Ayg�tlar�');
  etkSuruculer.Goster;

  etkKaynak.Olustur(Pencere.Kimlik, 36, 50, RENK_MOR, 'Kaynak Disk');
  etkKaynak.Goster;

  etkHedef.Olustur(Pencere.Kimlik, 195, 50, RENK_MOR, 'Hedef Disk');
  etkHedef.Goster;

  klKaynak.Olustur(Pencere.Kimlik, 40, 70, 110, 20);
  klKaynak.Goster;

  klHedef.Olustur(Pencere.Kimlik, 200, 70, 110, 20);
  klHedef.Goster;

  etkBilgi.Olustur(Pencere.Kimlik, 10, 102, RENK_KIRMIZI, 'Bilgi: -                         ');
  etkBilgi.Goster;

  IslemGostergesi.Olustur(Pencere.Kimlik, 10, 125, 330, 22);
  IslemGostergesi.DegerleriBelirle(0, $E800);
  IslemGostergesi.KonumBelirle(0);
  IslemGostergesi.Goster;

  Dugme.Olustur(Pencere.Kimlik, 90, 165, 170, 30, 'Diski Kopyala');
  Dugme.Goster;

  { TODO - sistemde 2 adet disk ayg�t�n�n olmamas� durumunda kullan�c�ya uyar� bilgisi verilecek }
  FizikselAygitSayisi := Depolama.FizikselDepolamaAygitSayisiAl;
  if(FizikselAygitSayisi > 0) then
  begin

    DiskAygitSayisi := 0;
    for i := 1 to FizikselAygitSayisi do
    begin

      if(Depolama.FizikselDepolamaAygitBilgisiAl(i, @FizikselSurucuListesi[0])) then
      begin

        if(FizikselSurucuListesi[0].SurucuTipi = SURUCUTIP_DISK) and (DiskAygitSayisi < 2) then
        begin

          Inc(DiskAygitSayisi);

          // ayg�tlar�n kimlikleri al�n�yor
          if(DiskAygitSayisi = 1) then
            KaynakDisk := i
          else if(DiskAygitSayisi = 2) then
            HedefDisk := i;

          // disk s�r�c� bilgilerini kaydet
          FizikselSurucuListesi[DiskAygitSayisi] := FizikselSurucuListesi[0];

          klKaynak.ElemanEkle(FizikselSurucuListesi[DiskAygitSayisi].AygitAdi);
          klHedef.ElemanEkle(FizikselSurucuListesi[DiskAygitSayisi].AygitAdi);
        end;
      end;
    end;

    // 2 adet disk s�r�c�s� listeye eklenmi� mi?
    if(DiskAygitSayisi = 2) then
    begin

      klKaynak.BaslikSiraNo := 0;
      klHedef.BaslikSiraNo := 1;
    end
    else
    // eklenmemi� ise listeyi tamamen temizle
    begin

      klKaynak.Temizle;
      klHedef.Temizle;
    end;
  end;

  Pencere.Gorunum := True;

  while True do
  begin

OlayBekle:

    Gorev.OlayBekle(Olay);
    if(Olay.Olay = FO_TIKLAMA) then
    begin

      if(Olay.Kimlik = Dugme.Kimlik) then
      begin

        // kaynak / hedef ayg�t se�ili ise kopyalama i�lemine ba�la
        if not((klKaynak.BaslikSiraNo = -1) and (klHedef.BaslikSiraNo = -1)) then
        begin

          etkBilgi.BaslikDegistir('Kopyalama i�lemi devam ediyor...');

          { TODO $E800 de�eri olan toplam sekt�r de�eri sistemden al�nacak ve her 2 diskin
            ayn� say�da sekt�r / kafa / iz i�erdi�i do�rulanacak }
          for i := 0 to $E800 - 1 do
          begin

            // disk sekt�r okuma i�lemi
            AygitDurum := Depolama.FizikselDepolamaVeriOku(KaynakDisk, i, 1, @DiskBellek);
            if(AygitDurum <> 0) then
            begin

              etkBilgi.BaslikDegistir('Hata: disk okuma hatas�!');
              Goto OlayBekle;
            end;

            // disk sekt�r yazma i�lemi
            AygitDurum := Depolama.FizikselDepolamaVeriYaz(HedefDisk, i, 1, @DiskBellek);
            if(AygitDurum <> 0) then
            begin

              etkBilgi.BaslikDegistir('Hata: disk yazma hatas�!');
              Goto OlayBekle;
            end;

            IslemGostergesi.KonumBelirle(i);
          end;

          etkBilgi.BaslikDegistir('Kopyalama i�lemi tamamland�.');
        end;
      end;
    end
    else if(Olay.Olay = CO_SECIMDEGISTI) then
    begin

      if(Olay.Kimlik = klKaynak.Kimlik) then
      begin
        if(Olay.Deger1 = 0) and (klHedef.BaslikSiraNo = 0) then klHedef.BaslikSiraNo := 1
        else if(Olay.Deger1 = 1) and (klHedef.BaslikSiraNo = 1) then klHedef.BaslikSiraNo := 0;
      end
      else if(Olay.Kimlik = klHedef.Kimlik) then
      begin
        if(Olay.Deger1 = 0) and (klKaynak.BaslikSiraNo = 0) then klKaynak.BaslikSiraNo := 1
        else if(Olay.Deger1 = 1) and (klKaynak.BaslikSiraNo = 1) then klKaynak.BaslikSiraNo := 0;
      end;
    end;
  end;
end.
