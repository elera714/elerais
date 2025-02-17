{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_zamanlayici, n_genel, _forms, n_ekran, gn_masaustu,
  gn_gucdugmesi, gn_menu, gn_etiket, gn_acilirmenu, gn_panel;

const
  // g�rev �ubu�unda g�sterilecek program say�s�
  CALISAN_PROGRAM_SAYISI = 20;

type
  // t�m pencereye sahip programlar�n kay�tlar�n�n tutuldu�u de�i�ken yap�
  TCalisanProgramlar = record
    // denetim sonucunda pencereye ait d��menin (Dugme) g�rev �ubu�undan kald�r�lacak
    // olup olmayaca��
    Silinecek: Boolean;
    DugmeSN: TISayi4;
    ProgramKayit: TProgramKayit;
  end;

type
  TDugmeler = record
    Kullanimda: Boolean;
    Dugme: TGucDugmesi;
  end;

type
  TfrmAnaSayfa = object(TForm)
  private
    procedure TarihSaatBilgileriniGuncelle;
    procedure CalisanProgramListesineEkle(AProgramKayit: TProgramKayit);
    procedure GorevCubugunuGuncelle;
    procedure AgDurumunuGuncelle;
    function PencereKimliginiAl(ABasilanDugme: TKimlik): TKimlik;
    function GCDugmesiOlustur(AProgramAdi: string): TISayi4;
    function PencereBilgisiAl(APencereKimlik: TKimlik): TProgramKayit;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  { TODO - bu nesneler object alan�nda oldu�unda hata veriyor }
  frmAnaSayfa: TfrmAnaSayfa;
  FGenel: TGenel;
  FGorev: TGorev;
  FEkran: TEkran;
  FMasaustu: TMasaustu;
  FGorevPenceresi: TPencere;
  FSolPanel, FSagPanel, FOrtaPanel: TPanel;
  FCalisanProgramlar: array[0..CALISAN_PROGRAM_SAYISI - 1] of TCalisanProgramlar;
  GucDugmeleri: array[0..CALISAN_PROGRAM_SAYISI - 1] of TDugmeler;
  FBaslatMenusu: TMenu;
  FAcilirMenu: TAcilirMenu;
  FELERA: TGucDugmesi;
  FSaatDegeri, FTarihDegeri, FAgBilgisi: TEtiket;
  FZamanlayici: TZamanlayici;
  FAgBilgisiDurum: TAgBilgisi;

implementation

const
  BASLATMENUSU_PSAYISI = 11;    // ba�lat men�s�ndeki program say�s�
  GOREVDUGMESI_G = 125;         // her bir g�rev d��mesinin geni�lik �nde�eri

const
  PencereAdi: string = 'Masa�st� Y�neticisi';

  Programlar: array[0..BASLATMENUSU_PSAYISI - 1] of string = (
    ('tarayici.c'),
    ('dsyyntcs.c'),
    ('resimgor.c'),
    ('dskgor.c'),
    ('defter.c'),
    ('iskelet.c'),
    ('grvyntcs.c'),
    ('pcibil.c'),
    ('yzmcgor.c'),
    ('smsjgor.c'),
    ('calistir.c'));

  ProgramAciklamalari: array[0..BASLATMENUSU_PSAYISI - 1] of string = (
    ('�nternet Taray�c�s�'),
    ('Dosya Y�neticisi'),
    ('Resim G�r�nt�leyici'),
    ('Disk ��erik G�r�nt�leyisi'),
    ('Dijital Defter'),
    ('Ana �skelet Program�'),
    ('G�rev Y�neticisi'),
    ('PCI Ayg�t Bilgisi'),
    ('Program Yazma� Bilgileri'),
    ('Sistem Mesaj G�r�nt�leyicisi'),
    ('Program �al��t�r'));

  MasaustuMenuProgramAdi: array[0..4] of string = (
    ('mustudk.c'),
    ('disk1:\belgeler\haklar.txt'),
    ('nesnegor.c'),
    ('grafik3.c'),
    ('sisbilgi.c'));

var
  ProgramKayit: TProgramKayit;
  AktifPencereKimlik,
  PencereKimlik: TKimlik;
  GCdeMevcutDugmeSayisi: TSayi4;        // g�rev �ubu�unda mevcut / �al��an d��me say�s�
  GBD, OncekiGBD: TSayi4;               // g�rev bayrak de�erleri
  s: string;

procedure TfrmAnaSayfa.Olustur;
var
  i: TSayi4;
begin

  OncekiGBD := 0;

  for i := 0 to CALISAN_PROGRAM_SAYISI - 1 do
  begin

    FCalisanProgramlar[i].DugmeSN := -1;
    FCalisanProgramlar[i].ProgramKayit.PencereKimlik := -1;

    GucDugmeleri[i].Kullanimda := False;
  end;

  // ekran ��z�n�rl���n� al
  FEkran.CozunurlukAl;

  // olu�turulan masa�st� say�s�n� al
  if(FMasaustu.ToplamMasaustuSayisi >= 4) then FGorev.Sonlandir(-1);

  // yeni masa�st� olu�tur
  FMasaustu.Olustur(PencereAdi);

  // yeni masa�st�n�n duvar ka��d�
  FMasaustu.MasaustuResminiDegistir('disk1:\resimler\1.bmp');

  // g�rev y�netim ana paneli
  FGorevPenceresi.Olustur(FMasaustu.Kimlik, FEkran.A0, FEkran.Yukseklik0 - 40, FEkran.Genislik0,
    40, ptBasliksiz, '', $FFFFFF);

  FSolPanel.Olustur(FGorevPenceresi.Kimlik, 0, 0, 65, 18, 4, $C0CFFA, $DCE4FC, 0, '');
  FSolPanel.Hizala(hzSol);
  FSolPanel.Goster;

  FSagPanel.Olustur(FGorevPenceresi.Kimlik, 0, 0, 160, 18, 4, $C0CFFA, $DCE4FC, 0, '');
  FSagPanel.Hizala(hzSag);
  FSagPanel.Goster;

  FOrtaPanel.Olustur(FGorevPenceresi.Kimlik, 10, 10, 50, 18, 4, $C0CFFA, $DCE4FC, 0, '');
  FOrtaPanel.Hizala(hzTum);
  FOrtaPanel.Goster;

  // ELERA ana d��mesini olu�tur
  FELERA.Olustur(FSolPanel.Kimlik, 4, 4, 56, 32, 'ELERA');
  FELERA.Goster;

  FAgBilgisi.Olustur(FSagPanel.Kimlik, 0, 14, 35, 16, RENK_KIRMIZI, '[A�]');
  FAgBilgisi.Goster;

  FSaatDegeri.Olustur(FSagPanel.Kimlik, 60, 5, 64, 16, $800000, '00:00:00');
  FSaatDegeri.Goster;

  FTarihDegeri.Olustur(FSagPanel.Kimlik, 42, 23, 104, 16, $800000, '00.00.0000 Aa');
  FTarihDegeri.Goster;

  // paneli (GorevPenceresi) g�r�nt�le
  FGorevPenceresi.Gorunum := True;

  // masa�st�n� g�r�nt�le
  FMasaustu.Goster;

  FZamanlayici.Olustur(100);
  FZamanlayici.Baslat;

  // masa�st� i�in ELERA d��mesine ba�l� men� olu�tur
  FBaslatMenusu.Olustur(0, FEkran.Yukseklik0 - 40 - ((BASLATMENUSU_PSAYISI * 26) + 8),
    300, (BASLATMENUSU_PSAYISI * 26) + 8, 26);

  // programlar� listeye ekle
  for i := 0 to BASLATMENUSU_PSAYISI - 1 do
  begin

    case i of
      0: FBaslatMenusu.ElemanEkle(ProgramAciklamalari[i], 13);
      1: FBaslatMenusu.ElemanEkle(ProgramAciklamalari[i], 01);
      2: FBaslatMenusu.ElemanEkle(ProgramAciklamalari[i], 10);
      3: FBaslatMenusu.ElemanEkle(ProgramAciklamalari[i], 06);
      4: FBaslatMenusu.ElemanEkle(ProgramAciklamalari[i], 07);
      5: FBaslatMenusu.ElemanEkle(ProgramAciklamalari[i], 14);
      6: FBaslatMenusu.ElemanEkle(ProgramAciklamalari[i], 09);
      7: FBaslatMenusu.ElemanEkle(ProgramAciklamalari[i], 05);
      8: FBaslatMenusu.ElemanEkle(ProgramAciklamalari[i], 15);
      9: FBaslatMenusu.ElemanEkle(ProgramAciklamalari[i], 04);
     10: FBaslatMenusu.ElemanEkle(ProgramAciklamalari[i], 16);
    end;
  end;

  FAcilirMenu.Olustur($2C3E50, RENK_BEYAZ, $7FB3D5, RENK_SIYAH, RENK_BEYAZ);
  FAcilirMenu.ElemanEkle('Duvar Ka��d�n� De�i�tir', 12);
  FAcilirMenu.ElemanEkle('Telif Hakk� Dosyas�n� G�r�nt�le', 12);
  FAcilirMenu.ElemanEkle('Nesne G�r�nt�leyicisi', 12);
  FAcilirMenu.ElemanEkle('Ekran Koruyucuyu', 12);
  FAcilirMenu.ElemanEkle('Sistem Bilgisi', 12);
end;

procedure TfrmAnaSayfa.Goster;
begin

end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
var
  i: TISayi4;
  ProgramBilgisi: TProgramKayit;
begin

  if(AOlay.Olay = FO_TIKLAMA) then
  begin

    // ba�lat men�s�ne t�kland���nda
    if(AOlay.Kimlik = FBaslatMenusu.Kimlik) then
    begin

      FELERA.DurumDegistir(0);
      i := FBaslatMenusu.SeciliSiraNoAl;
      FGorev.Calistir(Programlar[i]);
    end
    // masa�st� men�s�ne t�kland���nda
    else if(AOlay.Kimlik = FAcilirMenu.Kimlik) then
    begin

      i := FAcilirMenu.SeciliSiraNoAl;
      FGorev.Calistir(MasaustuMenuProgramAdi[i]);
    end

    else if(AOlay.Kimlik = FTarihDegeri.Kimlik) then
    begin

      FGorev.Calistir('takvim.c');
    end

    else if(AOlay.Kimlik = FSaatDegeri.Kimlik) then
    begin

      FGorev.Calistir('saat.c');
    end

    else if(AOlay.Kimlik = FAgBilgisi.Kimlik) then
    begin

      FGorev.Calistir('agbilgi.c');
    end
  end
  // masa�st�ne sa� tu� bas�l�p b�rak�ld���nda
  else if(AOlay.Olay = FO_SAGTUS_BIRAKILDI) then
  begin

    if(AOlay.Kimlik = FMasaustu.Kimlik) then FAcilirMenu.Goster;
  end
  // ba�lat d��mesi olaylar�
  else if(AOlay.Olay = CO_DURUMDEGISTI) then
  begin

    if(AOlay.Kimlik = FELERA.Kimlik) then
    begin

      if(AOlay.Deger1 = 1) then
        FBaslatMenusu.Goster
      else if(AOlay.Deger1 = 0) then
        FBaslatMenusu.Gizle;
    end
    else
    begin

      PencereKimlik := PencereKimliginiAl(AOlay.Kimlik);
      if(PencereKimlik > -1) then
      begin

        ProgramBilgisi := PencereBilgisiAl(PencereKimlik);
        if(ProgramBilgisi.PencereKimlik > -1) then
        begin

          // aktif / normal pencere -> k���lt
          if(ProgramBilgisi.PencereKimlik = AktifPencereKimlik) and (ProgramBilgisi.PencereDurum = pdNormal) then
          begin

            FGorevPenceresi.DurumuDegistir(PencereKimlik, pdKucultuldu);
          end
          // aktif olmayan
          else if(ProgramBilgisi.PencereKimlik <> AktifPencereKimlik) then
          begin

            // k���lt�lm�� pencere -> normal + aktifle�tir
            if(ProgramBilgisi.PencereDurum = pdKucultuldu) then

              FGorevPenceresi.DurumuDegistir(PencereKimlik, pdNormal);

            // (di�er durumlar) normal pencere -> aktifle�tir
            FGorevPenceresi.AktifPencereyiYaz(PencereKimlik);
          end;
        end;
      end;
    end;
  end
  // ba�lat men�s� olaylar�
  else if(AOlay.Kimlik = FBaslatMenusu.Kimlik) then
  begin

    if(AOlay.Olay = CO_MENUACILDI) then
      FELERA.DurumDegistir(1)
    else if(AOlay.Olay = CO_MENUKAPATILDI) then
      FELERA.DurumDegistir(0);
  end
  // saat de�erini g�ncelle�tir
  else if(AOlay.Olay = CO_ZAMANLAYICI) then
  begin

    TarihSaatBilgileriniGuncelle;
    GorevCubugunuGuncelle;
    AgDurumunuGuncelle;
  end;

  Result := 1;
end;

procedure TfrmAnaSayfa.TarihSaatBilgileriniGuncelle;
var
  Saat: array[0..2] of TSayi1;      // saat / dakika / saniye
  Tarih: array[0..3] of TSayi2;     // g�n / ay / y�l / haftan�n g�n�
begin

  FGenel.SaatAl(@Saat);
  s := TimeToStr(Saat);
  FSaatDegeri.BaslikDegistir(s);

  FGenel.TarihAl(@Tarih);
  s := DateToStr(Tarih, True);
  FTarihDegeri.BaslikDegistir(s);
end;

// program� �al��an program listesine ekler, program�n listeye ekli olmas� durumunda
// program�n silinecek �zelli�ini kald�r�r
procedure TfrmAnaSayfa.CalisanProgramListesineEkle(AProgramKayit: TProgramKayit);
var
  IlkBosSN, i: TISayi4;
  GCDugmeSN: TISayi4;
begin

  // 1. program listede mevcut ise silinecek �zelli�ini kald�r
  IlkBosSN := -1;
  for i := 0 to CALISAN_PROGRAM_SAYISI - 1 do
  begin

    if(FCalisanProgramlar[i].ProgramKayit.PencereKimlik = AProgramKayit.PencereKimlik) then
    begin

      FCalisanProgramlar[i].Silinecek := False;
      Inc(GCdeMevcutDugmeSayisi);
      Exit;
    end else if(IlkBosSN = -1) then
    begin

      if(FCalisanProgramlar[i].ProgramKayit.PencereKimlik = -1) then IlkBosSN := i;
    end;
  end;

  // 2. program listede mevcut de�il ve listede bo� yer var ise listeye ekle
  if(IlkBosSN > -1) then
  begin

    FCalisanProgramlar[IlkBosSN].Silinecek := False;

    FCalisanProgramlar[IlkBosSN].ProgramKayit.PencereKimlik := AProgramKayit.PencereKimlik;
    FCalisanProgramlar[IlkBosSN].ProgramKayit.GorevKimlik := AProgramKayit.GorevKimlik;
    FCalisanProgramlar[IlkBosSN].ProgramKayit.PencereTipi := AProgramKayit.PencereTipi;
    FCalisanProgramlar[IlkBosSN].ProgramKayit.PencereDurum := AProgramKayit.PencereDurum;
    FCalisanProgramlar[IlkBosSN].ProgramKayit.ProgramAdi := AProgramKayit.ProgramAdi;

    // d��meyi g�z�kmeyecek �ekilde olu�tur (g�ncelleme sonunda d��me g�r�n�r olacakt�r)
    GCDugmeSN := GCDugmesiOlustur(AProgramKayit.ProgramAdi);
    FCalisanProgramlar[IlkBosSN].DugmeSN := GCDugmeSN;

    Inc(GCdeMevcutDugmeSayisi);
  end;
end;

// g�rev �ubu�unu en son �al��an programlara g�re g�nceller
procedure TfrmAnaSayfa.GorevCubugunuGuncelle;
var
  Dugme: TGucDugmesi;
  Konum: TKonum;
  Boyut: TBoyut;
  CalisanProgramSayisi,
  GDGenislik, i, j: TSayi4;
begin

  GBD := FGorev.GorevBayrakDegeriniAl;

  // g�rev bayrak de�erlerinde de�i�iklik yoksa ��k
  if(OncekiGBD = GBD) then Exit;

  // aksi durumda g�rev �ubu�undaki g�revleri g�ncelle
  OncekiGBD := GBD;

  // G�rev �ubu�u g�ncelleme a�amalar�
  // ---------------------------------------------------------------------------
  // 1. GC'de mevcut programlar� silinecek olarak i�aretle
  // 2. �al��an program listesini sistemden alarak GC'ye ekle, daha �nce GC'de silinecek
  //    olarak i�aretlenen �al��an programlar� silinmeyecek olarak i�aretle
  // 3. GC'de pasif kalan programlar� yok et
  // 4. program�n yok edilmesinden kaynakl� de�i�ken yap�lar�nda olu�an bo�luklar�,
  //    sa�da kalan uygulamalar� sola kayd�rarak doldur
  // 5. t�m d��meleri yeniden boyutland�r ve g�r�n�r yap


  // 1. GC'de olabilecek t�m programlar� silinecek olarak i�aretle
  for i := 0 to CALISAN_PROGRAM_SAYISI - 1 do FCalisanProgramlar[i].Silinecek := True;

  // 2. �al��an program listesini sistemden alarak GC'ye ekle, daha �nce GC'de silinecek
  // olarak i�aretlenen �al��an programlar� silinmeyecek olarak i�aretle
  CalisanProgramSayisi := FGorev.CalisanProgramSayisiniAl;

  // �al��an programlar� g�ncelle
  GCdeMevcutDugmeSayisi := 0;

  if(CalisanProgramSayisi > 0) then
  begin

    for i := 0 to CalisanProgramSayisi - 1 do
    begin

      FGorev.CalisanProgramBilgisiAl(i, ProgramKayit);
      CalisanProgramListesineEkle(ProgramKayit);
    end;
  end;

  // 3. GC'den silinen programlar� yok et
  i := 0;
  while i < CALISAN_PROGRAM_SAYISI do
  begin

    if(FCalisanProgramlar[i].Silinecek) and (FCalisanProgramlar[i].ProgramKayit.PencereKimlik <> -1) then
    begin

      //FCalisanProgramlar[i].Silinecek := False;
      GucDugmeleri[FCalisanProgramlar[i].DugmeSN].Dugme.YokEt;
      GucDugmeleri[FCalisanProgramlar[i].DugmeSN].Kullanimda := False;
      FCalisanProgramlar[i].ProgramKayit.PencereKimlik := -1;
      FCalisanProgramlar[i].DugmeSN := -1;
    end;

    Inc(i);
  end;

  // bu a�amada g�rev �ubu�unda hi� bir program yoksa ��k
  if(GCdeMevcutDugmeSayisi = 0) then
  begin

    FMasaustu.Guncelle;
    Exit;
  end;

  // 4. program�n yok edilmesinden kaynakl� de�i�ken yap�lar�nda olu�an bo�luklar�,
  // sa�da kalan uygulamalar� sola kayd�rarak doldur
  i := 0;
  while i < CALISAN_PROGRAM_SAYISI do
  begin

    // kullan�lmayan ilk bellek b�lgesi ara
    if(FCalisanProgramlar[i].ProgramKayit.PencereKimlik = -1) then
    begin

      // b�lgeye ta��nacak veri var m�
      j := i + 1;
      while j < CALISAN_PROGRAM_SAYISI do
      begin

        // varsa ilk bo� b�lgeye ta��
        if(FCalisanProgramlar[j].ProgramKayit.PencereKimlik <> -1) then
        begin

          // verileri ta��
          //FCalisanProgramlar[i].Silinecek := False;
          FCalisanProgramlar[i].DugmeSN := FCalisanProgramlar[j].DugmeSN;
          FCalisanProgramlar[i].ProgramKayit.PencereKimlik := FCalisanProgramlar[j].ProgramKayit.PencereKimlik;
          FCalisanProgramlar[i].ProgramKayit.GorevKimlik := FCalisanProgramlar[j].ProgramKayit.GorevKimlik;
          FCalisanProgramlar[i].ProgramKayit.PencereTipi := FCalisanProgramlar[j].ProgramKayit.PencereTipi;
          FCalisanProgramlar[i].ProgramKayit.PencereDurum := FCalisanProgramlar[j].ProgramKayit.PencereDurum;
          FCalisanProgramlar[i].ProgramKayit.ProgramAdi := FCalisanProgramlar[j].ProgramKayit.ProgramAdi;

          // ta��nan bellek b�lgesinin i�eri�ini bo�alt
          //FCalisanProgramlar[j].Silinecek := False;
          //FCalisanProgramlar[j].Dugme := nil;
          FCalisanProgramlar[j].ProgramKayit.PencereKimlik := -1;
          FCalisanProgramlar[j].DugmeSN := -1;
          Break;
        end;

        Inc(j);
      end;
    end;

    Inc(i);
  end;

  // 5. t�m d��meleri yeniden boyutland�r ve g�r�n�r yap
  FOrtaPanel.BoyutAl(Konum, Boyut);
  Boyut.Genislik := Boyut.Genislik - 10;

  if(GCdeMevcutDugmeSayisi * GOREVDUGMESI_G > Boyut.Genislik) then
    GDGenislik := Boyut.Genislik div GCdeMevcutDugmeSayisi
  else GDGenislik := GOREVDUGMESI_G;

  AktifPencereKimlik := FGorevPenceresi.AktifPencereyiAl;

  i := 0;
  while i < CALISAN_PROGRAM_SAYISI do
  begin

    // kullan�lmayan ilk bellek b�lgesi ara
    if(FCalisanProgramlar[i].ProgramKayit.PencereKimlik <> -1) then
    begin

      Dugme := GucDugmeleri[FCalisanProgramlar[i].DugmeSN].Dugme;

      Konum.Sol := (i * GDGenislik) + 5;
      Konum.Ust := 4;
      Boyut.Genislik := GDGenislik - 5;
      Boyut.Yukseklik := 32;

      Dugme.Boyutlandir(Konum, Boyut);
      Dugme.Goster;

      if(FCalisanProgramlar[i].ProgramKayit.PencereKimlik = AktifPencereKimlik) then
        Dugme.DurumDegistir(1)
      else Dugme.DurumDegistir(0);
    end;

    Inc(i);
  end;

  FMasaustu.Guncelle;
end;

// sistemin ip al�p almamas�na ba�l� olarak a� durumunu g�nceller
procedure TfrmAnaSayfa.AgDurumunuGuncelle;
begin

  // a� durumunu g�ncelle
  FGenel.AgBilgisiAl(@FAgBilgisiDurum);
  if(IPKarsilastir(FAgBilgisiDurum.IP4Adres, IPAdres0)) then
    FAgBilgisi.RenkDegistir(RENK_KIRMIZI)
  else FAgBilgisi.RenkDegistir(RENK_YESIL);

  FMasaustu.Guncelle;
end;

// g�rev d��mesinin temsil etti�i pencere nesne kimli�ini al�r
function TfrmAnaSayfa.PencereKimliginiAl(ABasilanDugme: TKimlik): TKimlik;
var
  i: TSayi4;
begin

  for i := 0 to CALISAN_PROGRAM_SAYISI - 1 do
  begin

    if not(FCalisanProgramlar[i].ProgramKayit.PencereKimlik = -1) then
    begin

      if(GucDugmeleri[FCalisanProgramlar[i].DugmeSN].Dugme.Kimlik = ABasilanDugme) then
        Exit(FCalisanProgramlar[i].ProgramKayit.PencereKimlik);
    end;
  end;

  Result := -1;
end;

function TfrmAnaSayfa.GCDugmesiOlustur(AProgramAdi: string): TISayi4;
var
  i: TSayi4;
begin

  i := 0;
  while i < CALISAN_PROGRAM_SAYISI do
  begin

    if not(GucDugmeleri[i].Kullanimda) then
    begin

      GucDugmeleri[i].Dugme.Olustur(FOrtaPanel.Kimlik, 5, 4, 32, 32, AProgramAdi);
      GucDugmeleri[i].Dugme.Gizle;
      GucDugmeleri[i].Kullanimda := True;

      Exit(i);
    end;

    Inc(i);
  end;

  Result := -1;
end;

function TfrmAnaSayfa.PencereBilgisiAl(APencereKimlik: TKimlik): TProgramKayit;
var
  i: TSayi4;
begin

  for i := 0 to CALISAN_PROGRAM_SAYISI - 1 do
  begin

    if(FCalisanProgramlar[i].ProgramKayit.PencereKimlik = APencereKimlik) then
      Exit(FCalisanProgramlar[i].ProgramKayit);
  end;

  Result.PencereKimlik := -1;
end;

end.
