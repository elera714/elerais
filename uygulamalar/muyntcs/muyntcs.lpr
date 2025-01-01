program muyntcs;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: muyntcs.lpr
  Program Ýþlevi: çoklu masaüstü yönetim programý

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
uses n_gorev, n_ekran, gn_masaustu, gn_pencere, n_zamanlayici, gn_dugme, gn_gucdugmesi,
  gn_menu, gn_etiket, gn_resim, gn_acilirmenu, gn_panel, n_genel;

const
  BASLATMENUSU_PSAYISI = 11;    // baþlat menüsündeki program sayýsý
  GOREVDUGMESI_G = 125;         // her bir görev düðmesinin geniþlik öndeðeri

const
  ProgramAdi: string = 'Masaüstü Yöneticisi';

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
    ('Dosya Yöneticisi'),
    ('Resim Görüntüleyici'),
    ('Disk Ýçerik Görüntüleyisi'),
    ('Dijital Defter'),
    ('Dijital Saat'),
    ('Ana Ýskelet Programý'),
    ('Görev Yöneticisi'),
    ('PCI Aygýt Bilgisi'),
    ('Program Yazmaç Bilgileri'),
    ('Sistem Mesaj Görüntüleyicisi'),
    ('Program Çalýþtýr'));

  MasaustuMenuProgramAdi: array[0..4] of string = (
    ('mustudk.c'),
    ('haklar.txt'),
    ('nesnegor.c'),
    ('grafik3.c'),
    ('sisbilgi.c'));

type
  // tüm pencereye sahip programlarýn kayýtlarýnýn tutulduðu deðiþken yapý
  TCalisanProgramlar = record
    ProgramKayit: TProgramKayit;
    Dugme: TGucDugmesi;
  end;

const
  // görev çubuðunda gösterilecek program sayýsý
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
  GDGenislik: TSayi4;                 // görev düðmesi geniþliði
  ProgramKayit: TProgramKayit;
  Konum: TKonum;
  Boyut: TBoyut;
  PencereKimlik: TKimlik;
  GCdeMevcutDugmeSayisi: TSayi4;      // görev çubuðunda mevcut düðme sayýsý
  GBD, OncekiGBD: TSayi4;             // görev bayrak deðerleri

procedure TarihSaatBilgileriniGuncelle;
var
  Saat: array[0..2] of TSayi1;      // saat / dakika / saniye
  Tarih: array[0..3] of TSayi2;     // gün / ay / yýl / haftanýn günü
begin

  Genel.SaatAl(@Saat);
  s := TimeToStr(Saat);
  SaatDegeri.BaslikDegistir(s);

  Genel.TarihAl(@Tarih);
  s := DateToStr(Tarih, True);
  TarihDegeri.BaslikDegistir(s);
end;

// programý çalýþan program listesine ekler, gerekirse aktifliðini günceller
procedure CalisanProgramListesineEkle(ASiraNo: TSayi4; AProgramKayit: TProgramKayit);
begin

  // programý listeye ekle
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

// görev çubuðunu en son çalýþan programlara göre günceller
procedure GorevCubugunuGuncelle;
var
  i: TSayi4;
begin

  // 1. GC'de mevcut programlarý pasif olarak iþaretle
  // 2. çalýþan program listesini sistemden alarak GC'de pasif olanlarý aktif olarak iþaretle
  // 3. GC'de pasif kalan programlarý yok et
  // 4. GC'de en son programa ait kalan tüm düðmeleri yeniden boyutlandýr

  GBD := Gorev.GorevBayrakDegeriniAl;

  // görev bayrak deðerlerinde deðiþiklik yoksa çýk
  if(OncekiGBD = GBD) then Exit;

  // aksi durumda görev çubuðundaki görevleri güncelle
  OncekiGBD := GBD;

  // görev çubuðunda pencerelere ait düðmelerin tümünü yok et
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

  // her liste alým öncesinde görev çubuðunun (orta panelin) geniþliðini al
  OrtaPanel.BoyutAl(Konum, Boyut);

  if(CalisanProgramSayisi * GOREVDUGMESI_G > Boyut.Genislik) then
    GDGenislik := Boyut.Genislik div CalisanProgramSayisi
  else GDGenislik := GOREVDUGMESI_G;

  // çalýþan programlarý güncelle
  for i := 0 to CalisanProgramSayisi - 1 do
  begin

    Gorev.CalisanProgramBilgisiAl(i, ProgramKayit);
    CalisanProgramListesineEkle(i, ProgramKayit);
  end;

  Masaustu.Guncelle;
end;

// sistemin ip alýp almamasýna baðlý olarak að durumunu günceller
procedure AgDurumunuGuncelle;
begin

  // að durumunu güncelle
  Genel.AgBilgisiAl(@AgBilgisiDurum);
  if(IPKarsilastir(AgBilgisiDurum.IP4Adres, IPAdres0)) then
    AgBilgisi.RenkDegistir(RENK_KIRMIZI)
  else AgBilgisi.RenkDegistir(RENK_YESIL);

  Masaustu.Guncelle;
end;

// görev düðmesinin temsil ettiði pencere nesne kimliðini alýr
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

  // ekran çözünürlüðünü al
  Ekran.CozunurlukAl;

  // oluþturulan masaüstü sayýsýný al
  if(Masaustu.ToplamMasaustuSayisi >= 4) then Gorev.Sonlandir(-1);

  // yeni masaüstü oluþtur
  Masaustu.Olustur(ProgramAdi);

  // yeni masaüstünün duvar kaðýdý
  Masaustu.MasaustuResminiDegistir('disk1:\1.bmp');

  // görev yönetim ana paneli
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

  // ELERA ana düðmesini oluþtur
  ELERA.Olustur(SolPanel.Kimlik, 4, 4, 56, 32, 'ELERA');
  ELERA.Goster;

  AgBilgisi.Olustur(SagPanel.Kimlik, 0, 14, RENK_KIRMIZI, '[Að]');
  AgBilgisi.Goster;

  SaatDegeri.Olustur(SagPanel.Kimlik, 60, 5, $800000, '00:00:00');
  SaatDegeri.Goster;

  TarihDegeri.Olustur(SagPanel.Kimlik, 42, 23, $800000, '00.00.0000 Aa');
  TarihDegeri.Goster;

  // paneli (GorevPenceresi) görüntüle
  GorevPenceresi.Gorunum := True;

  // masaüstünü görüntüle
  Masaustu.Goster;

  Zamanlayici.Olustur(100);
  Zamanlayici.Baslat;

  // masaüstü için ELERA düðmesine baðlý menü oluþtur
  BaslatMenusu.Olustur(0, Ekran.Yukseklik0 - 40 - ((BASLATMENUSU_PSAYISI * 26) + 8),
    300, (BASLATMENUSU_PSAYISI * 26) + 8, 26);

  // programlarý listeye ekle
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
  AcilirMenu.ElemanEkle('Duvar Kaðýdýný Deðiþtir', 12);
  AcilirMenu.ElemanEkle('Telif Hakký Dosyasýný Görüntüle', 12);
  AcilirMenu.ElemanEkle('Nesne Görüntüleyicisi', 12);
  AcilirMenu.ElemanEkle('Ekran Koruyucuyu', 12);
  AcilirMenu.ElemanEkle('Sistem Bilgisi', 12);

  // ve ana döngü
  while True do
  begin

    Gorev.OlayBekle(Olay);

    if(Olay.Olay = FO_TIKLAMA) then
    begin

      // baþlat menüsüne týklandýðýnda
      if(Olay.Kimlik = BaslatMenusu.Kimlik) then
      begin

        ELERA.DurumDegistir(0);
        i := BaslatMenusu.SeciliSiraNoAl;
        Gorev.Calistir(Programlar[i]);
      end
      // masaüstü menüsüne týklandýðýnda
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
    // masaüstüne sað tuþ basýlýp býrakýldýðýnda
    else if(Olay.Olay = FO_SAGTUS_BIRAKILDI) then
    begin

      if(Olay.Kimlik = Masaustu.Kimlik) then AcilirMenu.Goster;
    end
    // baþlat düðmesi olaylarý
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
    // baþlat menüsü olaylarý
    else if(Olay.Kimlik = BaslatMenusu.Kimlik) then
    begin

      if(Olay.Olay = CO_MENUACILDI) then
        ELERA.DurumDegistir(1)
      else if(Olay.Olay = CO_MENUKAPATILDI) then
        ELERA.DurumDegistir(0);
    end
    // saat deðerini güncelleþtir
    else if(Olay.Olay = CO_ZAMANLAYICI) then
    begin

      TarihSaatBilgileriniGuncelle;
      GorevCubugunuGuncelle;
      AgDurumunuGuncelle;
    end;
  end;
end.
