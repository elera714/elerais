program kopyala;
{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: kopyala.lpr
  Program ��levi: fiziklse disket kopyalama i�levini ger�ekle�tirir

  G�ncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, gn_islemgostergesi, gn_dugme, gn_etiket, gn_karmaliste,
  n_depolama;

const
  ProgramAdi: string = 'Disket Kopyala';

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
  FizikselAygitSayisi, DisketAygitSayisi, i,
  KaynakDisket, HedefDisket: TSayi4;
  // FizikselSurucuListesi: 0 = genel, 1 = disket1, 2 = disket2
  FizikselSurucuListesi: array[0..2] of TFizikselSurucu3;
  DisketBellek: array[0..511] of TSayi1;

begin
  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 100, 100, 350, 210, ptIletisim, ProgramAdi, RENK_BEYAZ);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  etkSuruculer.Olustur(Pencere.Kimlik, 30, 16, RENK_MAVI, 'Fiziksel Disket Depolama Ayg�tlar�');
  etkSuruculer.Goster;

  etkKaynak.Olustur(Pencere.Kimlik, 42, 50, RENK_MOR, 'Kaynak Disket');
  etkKaynak.Goster;

  etkHedef.Olustur(Pencere.Kimlik, 207, 50, RENK_MOR, 'Hedef Disket');
  etkHedef.Goster;

  klKaynak.Olustur(Pencere.Kimlik, 40, 70, 110, 20);
  klKaynak.Goster;

  klHedef.Olustur(Pencere.Kimlik, 200, 70, 110, 20);
  klHedef.Goster;

  etkBilgi.Olustur(Pencere.Kimlik, 10, 102, RENK_KIRMIZI, 'Bilgi: -                         ');
  etkBilgi.Goster;

  IslemGostergesi.Olustur(Pencere.Kimlik, 10, 125, 330, 22);
  IslemGostergesi.DegerleriBelirle(0, 2880);
  IslemGostergesi.KonumBelirle(0);
  IslemGostergesi.Goster;

  Dugme.Olustur(Pencere.Kimlik, 90, 165, 170, 30, 'Disketi Kopyala');
  Dugme.Goster;

  { TODO - sistemde 2 adet disket ayg�t�n�n olmamas� durumunda kullan�c�ya uyar� bilgisi verilecek }
  FizikselAygitSayisi := Depolama.FizikselDepolamaAygitSayisiAl;
  if(FizikselAygitSayisi > 0) then
  begin

    DisketAygitSayisi := 0;
    for i := 1 to FizikselAygitSayisi do
    begin

      if(Depolama.FizikselDepolamaAygitBilgisiAl(i, @FizikselSurucuListesi[0])) then
      begin

        if(FizikselSurucuListesi[0].SurucuTipi = SURUCUTIP_DISKET) and (DisketAygitSayisi < 2) then
        begin

          Inc(DisketAygitSayisi);

          // ayg�tlar�n kimlikleri al�n�yor
          if(DisketAygitSayisi = 1) then
            KaynakDisket := i
          else if(DisketAygitSayisi = 2) then
            HedefDisket := i;

          // disket s�r�c� bilgilerini kaydet
          FizikselSurucuListesi[DisketAygitSayisi] := FizikselSurucuListesi[0];

          klKaynak.ElemanEkle(FizikselSurucuListesi[DisketAygitSayisi].AygitAdi);
          klHedef.ElemanEkle(FizikselSurucuListesi[DisketAygitSayisi].AygitAdi);
        end;
      end;
    end;

    // 2 adet disket s�r�c�s� listeye eklenmi� mi?
    if(DisketAygitSayisi = 2) then
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

          for i := 1 to 100 do //2880 do
          begin

            // disket sekt�r okuma i�lemi
            AygitDurum := Depolama.FizikselDepolamaVeriOku(KaynakDisket,
              i, 1, @DisketBellek);
            if(AygitDurum = 0) then
            begin

              etkBilgi.BaslikDegistir('Hata: disket okuma hatas�!');
              Goto OlayBekle;
            end;

            // disket sekt�r yazma i�lemi
            AygitDurum := Depolama.FizikselDepolamaVeriYaz(KaynakDisket,
              i, 1, @DisketBellek);
            if(AygitDurum = 0) then
            begin

              etkBilgi.BaslikDegistir('Hata: disket yazma hatas�!');
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
