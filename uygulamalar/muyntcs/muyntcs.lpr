program muyntcs;
{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: muyntcs.lpr
  Program ��levi: �oklu masa�st� y�netim program�

  G�ncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
uses n_gorev, n_ekran, gn_masaustu, gn_pencere, n_zamanlayici, gn_dugme, gn_gucdugmesi,
  gn_menu, gn_etiket, gn_resim, gn_acilirmenu, gn_panel, n_genel;

const
  BASLATMENUSU_PSAYISI = 11;    // ba�lat men�s�ndeki program say�s�
  GOREVDUGMESI_G = 125;         // her bir g�rev d��mesinin geni�lik �nde�eri

const
  ProgramAdi: string = 'Masa�st� Y�neticisi';

  Programlar: array[0..BASLATMENUSU_PSAYISI - 1] of string = (
    ('dsyyntcs.c'),
    ('resimgor.c'),
    ('dskgor.c'),
    ('defter.c'),
    ('saat.c'),
    ('iskelet.c'),
    ('grvyntcs.c'),
    ('pcibil.c'),
    ('yzmcgor.c'),
    ('smsjgor.c'),
    ('calistir.c'));

  ProgramAciklamalari: array[0..BASLATMENUSU_PSAYISI - 1] of string = (
    ('Dosya Y�neticisi'),
    ('Resim G�r�nt�leyici'),
    ('Disk ��erik G�r�nt�leyisi'),
    ('Dijital Defter'),
    ('Dijital Saat'),
    ('Ana �skelet Program�'),
    ('G�rev Y�neticisi'),
    ('PCI Ayg�t Bilgisi'),
    ('Program Yazma� Bilgileri'),
    ('Sistem Mesaj G�r�nt�leyicisi'),
    ('Program �al��t�r'));

  MasaustuMenuProgramAdi: array[0..4] of string = (
    ('mustudk.c'),
    ('haklar.txt'),
    ('nesnegor.c'),
    ('grafik3.c'),
    ('sisbilgi.c'));

type
  // t�m pencereye sahip programlar�n kay�tlar�n�n tutuldu�u de�i�ken yap�
  TCalisanProgramlar = record
    ProgramKayit: TProgramKayit;
    Dugme: TGucDugmesi;
  end;

const
  // g�rev �ubu�unda g�sterilecek program say�s�
  CALISAN_PROGRAM_SAYISI = 20;

var
  Genel: TGenel;
  Gorev: TGorev;
  Ekran: TEkran;
  Masaustu: TMasaustu;
  GorevPenceresi: TPencere;
  SolPanel, SagPanel, OrtaPanel: TPanel;
  CalisanProgramlar: array[0..CALISAN_PROGRAM_SAYISI - 1] of TCalisanProgramlar;
  BaslatMenusu: TMenu;
  AcilirMenu: TAcilirMenu;
  ELERA: TGucDugmesi;
  SaatDegeri, TarihDegeri, AgBilgisi: TEtiket;
  Zamanlayici: TZamanlayici;
  AgBilgisiDurum: TAgBilgisi;
  Olay: TOlay;
  s: string;

  AktifProgram: TISayi4;
  CalisanProgramSayisi,
  GDGenislik: TSayi4;                 // g�rev d��mesi geni�li�i
  ProgramKayit: TProgramKayit;
  Konum: TKonum;
  Boyut: TBoyut;
  PencereKimlik: TKimlik;
  GCdeMevcutDugmeSayisi: TSayi4;      // g�rev �ubu�unda mevcut d��me say�s�
  GBD, OncekiGBD: TSayi4;             // g�rev bayrak de�erleri

procedure TarihSaatBilgileriniGuncelle;
var
  Saat: array[0..2] of TSayi1;      // saat / dakika / saniye
  Tarih: array[0..3] of TSayi2;     // g�n / ay / y�l / haftan�n g�n�
begin

  Genel.SaatAl(@Saat);
  s := TimeToStr(Saat);
  SaatDegeri.BaslikDegistir(s);

  Genel.TarihAl(@Tarih);
  s := DateToStr(Tarih, True);
  TarihDegeri.BaslikDegistir(s);
end;

// program� �al��an program listesine ekler, gerekirse aktifli�ini g�nceller
procedure CalisanProgramListesineEkle(ASiraNo: TSayi4; AProgramKayit: TProgramKayit);
begin

  // program� listeye ekle
  CalisanProgramlar[ASiraNo].ProgramKayit.PencereKimlik := AProgramKayit.PencereKimlik;
  CalisanProgramlar[ASiraNo].ProgramKayit.GorevKimlik := AProgramKayit.GorevKimlik;
  CalisanProgramlar[ASiraNo].ProgramKayit.PencereTipi := AProgramKayit.PencereTipi;
  CalisanProgramlar[ASiraNo].ProgramKayit.PencereDurum := AProgramKayit.PencereDurum;
  CalisanProgramlar[ASiraNo].ProgramKayit.ProgramAdi := AProgramKayit.ProgramAdi;

  CalisanProgramlar[ASiraNo].Dugme.Olustur(OrtaPanel.Kimlik, (ASiraNo * GDGenislik) + 5, 4,
    GDGenislik - 5, 32, AProgramKayit.ProgramAdi);
  CalisanProgramlar[ASiraNo].Dugme.Goster;

  if(AProgramKayit.PencereKimlik = AktifProgram) then CalisanProgramlar[ASiraNo].Dugme.DurumDegistir(1);

  Inc(GCdeMevcutDugmeSayisi);
end;

// g�rev �ubu�unu en son �al��an programlara g�re g�nceller
procedure GorevCubugunuGuncelle;
var
  i: TSayi4;
begin

  // 1. GC'de mevcut programlar� pasif olarak i�aretle
  // 2. �al��an program listesini sistemden alarak GC'de pasif olanlar� aktif olarak i�aretle
  // 3. GC'de pasif kalan programlar� yok et
  // 4. GC'de en son programa ait kalan t�m d��meleri yeniden boyutland�r

  GBD := Gorev.GorevBayrakDegeriniAl;

  // g�rev bayrak de�erlerinde de�i�iklik yoksa ��k
  if(OncekiGBD = GBD) then Exit;

  // aksi durumda g�rev �ubu�undaki g�revleri g�ncelle
  OncekiGBD := GBD;

  // g�rev �ubu�unda pencerelere ait d��melerin t�m�n� yok et
  if(GCdeMevcutDugmeSayisi > 0) then
  begin

    i := 0;
    while i < CALISAN_PROGRAM_SAYISI do
    begin

      if(CalisanProgramlar[i].ProgramKayit.PencereKimlik <> -1) then
      begin

        CalisanProgramlar[i].Dugme.YokEt;
        CalisanProgramlar[i].ProgramKayit.PencereKimlik := -1;
      end;

      Inc(i);
    end;
  end;

  GCdeMevcutDugmeSayisi := 0;

  CalisanProgramSayisi := Gorev.CalisanProgramSayisiniAl;
  if(CalisanProgramSayisi = 0) then Exit;

  AktifProgram := Gorev.AktifProgramiAl;

  // her liste al�m �ncesinde g�rev �ubu�unun (orta panelin) geni�li�ini al
  OrtaPanel.BoyutAl(Konum, Boyut);

  if(CalisanProgramSayisi * GOREVDUGMESI_G > Boyut.Genislik) then
    GDGenislik := Boyut.Genislik div CalisanProgramSayisi
  else GDGenislik := GOREVDUGMESI_G;

  // �al��an programlar� g�ncelle
  for i := 0 to CalisanProgramSayisi - 1 do
  begin

    Gorev.CalisanProgramBilgisiAl(i, ProgramKayit);
    CalisanProgramListesineEkle(i, ProgramKayit);
  end;

  Masaustu.Guncelle;
end;

// sistemin ip al�p almamas�na ba�l� olarak a� durumunu g�nceller
procedure AgDurumunuGuncelle;
begin

  // a� durumunu g�ncelle
  Genel.AgBilgisiAl(@AgBilgisiDurum);
  if(IPKarsilastir(AgBilgisiDurum.IP4Adres, IPAdres0)) then
    AgBilgisi.RenkDegistir(RENK_KIRMIZI)
  else AgBilgisi.RenkDegistir(RENK_YESIL);

  Masaustu.Guncelle;
end;

// g�rev d��mesinin temsil etti�i pencere nesne kimli�ini al�r
function PencereKimliginiAl(ABasilanDugme: TKimlik): TKimlik;
var
  i: TSayi4;
begin

  for i := 0 to CALISAN_PROGRAM_SAYISI - 1 do
  begin

    if not(CalisanProgramlar[i].ProgramKayit.PencereKimlik = -1) then
    begin

      if not(CalisanProgramlar[i].Dugme.Kimlik = ABasilanDugme) then
        Exit(CalisanProgramlar[i].ProgramKayit.PencereKimlik);
    end;
  end;

  Result := -1;
end;

var
  i: TSayi4;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  GCdeMevcutDugmeSayisi := 0;
  OncekiGBD := 0;

  for i := 0 to CALISAN_PROGRAM_SAYISI - 1 do
    CalisanProgramlar[i].ProgramKayit.PencereKimlik := -1;

  // ekran ��z�n�rl���n� al
  Ekran.CozunurlukAl;

  // olu�turulan masa�st� say�s�n� al
  if(Masaustu.ToplamMasaustuSayisi >= 4) then Gorev.Sonlandir(-1);

  // yeni masa�st� olu�tur
  Masaustu.Olustur(ProgramAdi);

  // yeni masa�st�n�n duvar ka��d�
  Masaustu.MasaustuResminiDegistir('disk1:\1.bmp');

  // g�rev y�netim ana paneli
  GorevPenceresi.Olustur(Masaustu.Kimlik, Ekran.A0, Ekran.Yukseklik0 - 40, Ekran.Genislik0,
    40, ptBasliksiz, '', $FFFFFF);

  SolPanel.Olustur(GorevPenceresi.Kimlik, 0, 0, 65, 18, 4, $C0CFFA, $DCE4FC, 0, '');
  SolPanel.Hizala(hzSol);
  SolPanel.Goster;

  SagPanel.Olustur(GorevPenceresi.Kimlik, 0, 0, 160, 18, 4, $C0CFFA, $DCE4FC, 0, '');
  SagPanel.Hizala(hzSag);
  SagPanel.Goster;

  OrtaPanel.Olustur(GorevPenceresi.Kimlik, 10, 10, 50, 18, 4, $C0CFFA, $DCE4FC, 0, '');
  OrtaPanel.Hizala(hzTum);
  OrtaPanel.Goster;

  // ELERA ana d��mesini olu�tur
  ELERA.Olustur(SolPanel.Kimlik, 4, 4, 56, 32, 'ELERA');
  ELERA.Goster;

  AgBilgisi.Olustur(SagPanel.Kimlik, 0, 14, RENK_KIRMIZI, '[A�]');
  AgBilgisi.Goster;

  SaatDegeri.Olustur(SagPanel.Kimlik, 60, 5, $800000, '00:00:00');
  SaatDegeri.Goster;

  TarihDegeri.Olustur(SagPanel.Kimlik, 42, 23, $800000, '00.00.0000 Aa');
  TarihDegeri.Goster;

  // paneli (GorevPenceresi) g�r�nt�le
  GorevPenceresi.Gorunum := True;

  // masa�st�n� g�r�nt�le
  Masaustu.Goster;

  Zamanlayici.Olustur(100);
  Zamanlayici.Baslat;

  // masa�st� i�in ELERA d��mesine ba�l� men� olu�tur
  BaslatMenusu.Olustur(0, Ekran.Yukseklik0 - 40 - ((BASLATMENUSU_PSAYISI * 26) + 8),
    300, (BASLATMENUSU_PSAYISI * 26) + 8, 26);

  // programlar� listeye ekle
  for i := 0 to BASLATMENUSU_PSAYISI - 1 do
  begin

    case i of
      0: BaslatMenusu.ElemanEkle(ProgramAciklamalari[i], 01);
      1: BaslatMenusu.ElemanEkle(ProgramAciklamalari[i], 10);
      2: BaslatMenusu.ElemanEkle(ProgramAciklamalari[i], 06);
      3: BaslatMenusu.ElemanEkle(ProgramAciklamalari[i], 07);
      4: BaslatMenusu.ElemanEkle(ProgramAciklamalari[i], 08);
      5: BaslatMenusu.ElemanEkle(ProgramAciklamalari[i], 14);
      6: BaslatMenusu.ElemanEkle(ProgramAciklamalari[i], 09);
      7: BaslatMenusu.ElemanEkle(ProgramAciklamalari[i], 05);
      8: BaslatMenusu.ElemanEkle(ProgramAciklamalari[i], 15);
      9: BaslatMenusu.ElemanEkle(ProgramAciklamalari[i], 04);
     10: BaslatMenusu.ElemanEkle(ProgramAciklamalari[i], 16);
    end;
  end;

  AcilirMenu.Olustur($2C3E50, RENK_BEYAZ, $7FB3D5, RENK_SIYAH, RENK_BEYAZ);
  AcilirMenu.ElemanEkle('Duvar Ka��d�n� De�i�tir', 12);
  AcilirMenu.ElemanEkle('Telif Hakk� Dosyas�n� G�r�nt�le', 12);
  AcilirMenu.ElemanEkle('Nesne G�r�nt�leyicisi', 12);
  AcilirMenu.ElemanEkle('Ekran Koruyucuyu', 12);
  AcilirMenu.ElemanEkle('Sistem Bilgisi', 12);

  // ve ana d�ng�
  while True do
  begin

    Gorev.OlayBekle(Olay);

    if(Olay.Olay = FO_TIKLAMA) then
    begin

      // ba�lat men�s�ne t�kland���nda
      if(Olay.Kimlik = BaslatMenusu.Kimlik) then
      begin

        ELERA.DurumDegistir(0);
        i := BaslatMenusu.SeciliSiraNoAl;
        Gorev.Calistir(Programlar[i]);
      end
      // masa�st� men�s�ne t�kland���nda
      else if(Olay.Kimlik = AcilirMenu.Kimlik) then
      begin

        i := AcilirMenu.SeciliSiraNoAl;
        Gorev.Calistir(MasaustuMenuProgramAdi[i]);
      end

      else if(Olay.Kimlik = TarihDegeri.Kimlik) then
      begin

        Gorev.Calistir('takvim.c');
      end

      else if(Olay.Kimlik = SaatDegeri.Kimlik) then
      begin

        Gorev.Calistir('saat.c');
      end

      else if(Olay.Kimlik = AgBilgisi.Kimlik) then
      begin

        Gorev.Calistir('agbilgi.c');
      end
    end
    // masa�st�ne sa� tu� bas�l�p b�rak�ld���nda
    else if(Olay.Olay = FO_SAGTUS_BIRAKILDI) then
    begin

      if(Olay.Kimlik = Masaustu.Kimlik) then AcilirMenu.Goster;
    end
    // ba�lat d��mesi olaylar�
    else if(Olay.Olay = CO_DURUMDEGISTI) then
    begin

      if(Olay.Kimlik = ELERA.Kimlik) then
      begin

        if(Olay.Deger1 = 1) then
          BaslatMenusu.Goster
        else if(Olay.Deger1 = 0) then
          BaslatMenusu.Gizle;
      end
      else
      begin

        PencereKimlik := PencereKimliginiAl(Olay.Kimlik);
        if(PencereKimlik > -1) then
          if(Olay.Deger1 = 1) then
            GorevPenceresi.PencereDurumuDegistir(PencereKimlik, pdNormal)
          else GorevPenceresi.PencereDurumuDegistir(PencereKimlik, pdKucultuldu);
      end;
    end
    // ba�lat men�s� olaylar�
    else if(Olay.Kimlik = BaslatMenusu.Kimlik) then
    begin

      if(Olay.Olay = CO_MENUACILDI) then
        ELERA.DurumDegistir(1)
      else if(Olay.Olay = CO_MENUKAPATILDI) then
        ELERA.DurumDegistir(0);
    end
    // saat de�erini g�ncelle�tir
    else if(Olay.Olay = CO_ZAMANLAYICI) then
    begin

      TarihSaatBilgileriniGuncelle;
      GorevCubugunuGuncelle;
      AgDurumunuGuncelle;
    end;
  end;
end.
