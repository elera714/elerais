{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_zamanlayici, n_genel, _forms, n_ekran, gn_masaustu,
  gn_gucdugmesi, gn_menu, gn_etiket, gn_acilirmenu, gn_panel;

const
  // görev çubuðunda gösterilecek program sayýsý
  CALISAN_PROGRAM_SAYISI = 20;

type
  // tüm pencereye sahip programlarýn kayýtlarýnýn tutulduðu deðiþken yapý
  TCalisanProgramlar = record
    ProgramKayit: TProgramKayit;
    Dugme: TGucDugmesi;
  end;

type
  TfrmAnaSayfa = object(TForm)
  private
    procedure TarihSaatBilgileriniGuncelle;
    procedure CalisanProgramListesineEkle(ASiraNo: TSayi4; AProgramKayit: TProgramKayit);
    procedure GorevCubugunuGuncelle;
    procedure AgDurumunuGuncelle;
    function PencereKimliginiAl(ABasilanDugme: TKimlik): TKimlik;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  { TODO - bu nesneler object alanýnda olduðunda hata veriyor }
  frmAnaSayfa: TfrmAnaSayfa;
  FGenel: TGenel;
  FGorev: TGorev;
  FEkran: TEkran;
  FMasaustu: TMasaustu;
  FGorevPenceresi: TPencere;
  FSolPanel, FSagPanel, FOrtaPanel: TPanel;
  FCalisanProgramlar: array[0..CALISAN_PROGRAM_SAYISI - 1] of TCalisanProgramlar;
  FBaslatMenusu: TMenu;
  FAcilirMenu: TAcilirMenu;
  FELERA: TGucDugmesi;
  FSaatDegeri, FTarihDegeri, FAgBilgisi: TEtiket;
  FZamanlayici: TZamanlayici;
  FAgBilgisiDurum: TAgBilgisi;

implementation

const
  BASLATMENUSU_PSAYISI = 11;    // baþlat menüsündeki program sayýsý
  GOREVDUGMESI_G = 125;         // her bir görev düðmesinin geniþlik öndeðeri

const
  PencereAdi: string = 'Masaüstü Yöneticisi';

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
    ('Ýnternet Tarayýcýsý'),
    ('Dosya Yöneticisi'),
    ('Resim Görüntüleyici'),
    ('Disk Ýçerik Görüntüleyisi'),
    ('Dijital Defter'),
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

var
  AktifProgram: TISayi4;
  CalisanProgramSayisi,
  GDGenislik: TSayi4;                 // görev düðmesi geniþliði
  ProgramKayit: TProgramKayit;
  Konum: TKonum;
  Boyut: TBoyut;
  PencereKimlik: TKimlik;
  GCdeMevcutDugmeSayisi: TSayi4;      // görev çubuðunda mevcut düðme sayýsý
  GBD, OncekiGBD, i: TSayi4;          // görev bayrak deðerleri
  s: string;

procedure TfrmAnaSayfa.Olustur;
begin

  GCdeMevcutDugmeSayisi := 0;
  OncekiGBD := 0;

  for i := 0 to CALISAN_PROGRAM_SAYISI - 1 do
    FCalisanProgramlar[i].ProgramKayit.PencereKimlik := -1;

  // ekran çözünürlüðünü al
  FEkran.CozunurlukAl;

  // oluþturulan masaüstü sayýsýný al
  if(FMasaustu.ToplamMasaustuSayisi >= 4) then FGorev.Sonlandir(-1);

  // yeni masaüstü oluþtur
  FMasaustu.Olustur(PencereAdi);

  // yeni masaüstünün duvar kaðýdý
  FMasaustu.MasaustuResminiDegistir('disk1:\1.bmp');

  // görev yönetim ana paneli
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

  // ELERA ana düðmesini oluþtur
  FELERA.Olustur(FSolPanel.Kimlik, 4, 4, 56, 32, 'ELERA');
  FELERA.Goster;

  FAgBilgisi.Olustur(FSagPanel.Kimlik, 0, 14, RENK_KIRMIZI, '[Að]');
  FAgBilgisi.Goster;

  FSaatDegeri.Olustur(FSagPanel.Kimlik, 60, 5, $800000, '00:00:00');
  FSaatDegeri.Goster;

  FTarihDegeri.Olustur(FSagPanel.Kimlik, 42, 23, $800000, '00.00.0000 Aa');
  FTarihDegeri.Goster;

  // paneli (GorevPenceresi) görüntüle
  FGorevPenceresi.Gorunum := True;

  // masaüstünü görüntüle
  FMasaustu.Goster;

  FZamanlayici.Olustur(100);
  FZamanlayici.Baslat;

  // masaüstü için ELERA düðmesine baðlý menü oluþtur
  FBaslatMenusu.Olustur(0, FEkran.Yukseklik0 - 40 - ((BASLATMENUSU_PSAYISI * 26) + 8),
    300, (BASLATMENUSU_PSAYISI * 26) + 8, 26);

  // programlarý listeye ekle
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
  FAcilirMenu.ElemanEkle('Duvar Kaðýdýný Deðiþtir', 12);
  FAcilirMenu.ElemanEkle('Telif Hakký Dosyasýný Görüntüle', 12);
  FAcilirMenu.ElemanEkle('Nesne Görüntüleyicisi', 12);
  FAcilirMenu.ElemanEkle('Ekran Koruyucuyu', 12);
  FAcilirMenu.ElemanEkle('Sistem Bilgisi', 12);

end;

procedure TfrmAnaSayfa.Goster;
begin

end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = FO_TIKLAMA) then
  begin

    // baþlat menüsüne týklandýðýnda
    if(AOlay.Kimlik = FBaslatMenusu.Kimlik) then
    begin

      FELERA.DurumDegistir(0);
      i := FBaslatMenusu.SeciliSiraNoAl;
      FGorev.Calistir(Programlar[i]);
    end
    // masaüstü menüsüne týklandýðýnda
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
  // masaüstüne sað tuþ basýlýp býrakýldýðýnda
  else if(AOlay.Olay = FO_SAGTUS_BIRAKILDI) then
  begin

    if(AOlay.Kimlik = FMasaustu.Kimlik) then FAcilirMenu.Goster;
  end
  // baþlat düðmesi olaylarý
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
        if(AOlay.Deger1 = 1) then
          FGorevPenceresi.PencereDurumuDegistir(PencereKimlik, pdNormal)
        else FGorevPenceresi.PencereDurumuDegistir(PencereKimlik, pdKucultuldu);
    end;
  end
  // baþlat menüsü olaylarý
  else if(AOlay.Kimlik = FBaslatMenusu.Kimlik) then
  begin

    if(AOlay.Olay = CO_MENUACILDI) then
      FELERA.DurumDegistir(1)
    else if(AOlay.Olay = CO_MENUKAPATILDI) then
      FELERA.DurumDegistir(0);
  end
  // saat deðerini güncelleþtir
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
  Tarih: array[0..3] of TSayi2;     // gün / ay / yýl / haftanýn günü
begin

  FGenel.SaatAl(@Saat);
  s := TimeToStr(Saat);
  FSaatDegeri.BaslikDegistir(s);

  FGenel.TarihAl(@Tarih);
  s := DateToStr(Tarih, True);
  FTarihDegeri.BaslikDegistir(s);
end;

// programý çalýþan program listesine ekler, gerekirse aktifliðini günceller
procedure TfrmAnaSayfa.CalisanProgramListesineEkle(ASiraNo: TSayi4; AProgramKayit: TProgramKayit);
begin

  // programý listeye ekle
  FCalisanProgramlar[ASiraNo].ProgramKayit.PencereKimlik := AProgramKayit.PencereKimlik;
  FCalisanProgramlar[ASiraNo].ProgramKayit.GorevKimlik := AProgramKayit.GorevKimlik;
  FCalisanProgramlar[ASiraNo].ProgramKayit.PencereTipi := AProgramKayit.PencereTipi;
  FCalisanProgramlar[ASiraNo].ProgramKayit.PencereDurum := AProgramKayit.PencereDurum;
  FCalisanProgramlar[ASiraNo].ProgramKayit.ProgramAdi := AProgramKayit.ProgramAdi;

  FCalisanProgramlar[ASiraNo].Dugme.Olustur(FOrtaPanel.Kimlik, (ASiraNo * GDGenislik) + 5, 4,
    GDGenislik - 5, 32, AProgramKayit.ProgramAdi);
  FCalisanProgramlar[ASiraNo].Dugme.Goster;

  if(AProgramKayit.PencereKimlik = AktifProgram) then FCalisanProgramlar[ASiraNo].Dugme.DurumDegistir(1);

  Inc(GCdeMevcutDugmeSayisi);
end;

// görev çubuðunu en son çalýþan programlara göre günceller
procedure TfrmAnaSayfa.GorevCubugunuGuncelle;
var
  i: TSayi4;
begin

  // 1. GC'de mevcut programlarý pasif olarak iþaretle
  // 2. çalýþan program listesini sistemden alarak GC'de pasif olanlarý aktif olarak iþaretle
  // 3. GC'de pasif kalan programlarý yok et
  // 4. GC'de en son programa ait kalan tüm düðmeleri yeniden boyutlandýr

  GBD := FGorev.GorevBayrakDegeriniAl;

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

      if(FCalisanProgramlar[i].ProgramKayit.PencereKimlik <> -1) then
      begin

        FCalisanProgramlar[i].Dugme.YokEt;
        FCalisanProgramlar[i].ProgramKayit.PencereKimlik := -1;
      end;

      Inc(i);
    end;
  end;

  GCdeMevcutDugmeSayisi := 0;

  CalisanProgramSayisi := FGorev.CalisanProgramSayisiniAl;
  if(CalisanProgramSayisi = 0) then Exit;

  AktifProgram := FGorev.AktifProgramiAl;

  // her liste alým öncesinde görev çubuðunun (orta panelin) geniþliðini al
  FOrtaPanel.BoyutAl(Konum, Boyut);

  if(CalisanProgramSayisi * GOREVDUGMESI_G > Boyut.Genislik) then
    GDGenislik := Boyut.Genislik div CalisanProgramSayisi
  else GDGenislik := GOREVDUGMESI_G;

  // çalýþan programlarý güncelle
  for i := 0 to CalisanProgramSayisi - 1 do
  begin

    FGorev.CalisanProgramBilgisiAl(i, ProgramKayit);
    CalisanProgramListesineEkle(i, ProgramKayit);
  end;

  FMasaustu.Guncelle;
end;

// sistemin ip alýp almamasýna baðlý olarak að durumunu günceller
procedure TfrmAnaSayfa.AgDurumunuGuncelle;
begin

  // að durumunu güncelle
  FGenel.AgBilgisiAl(@FAgBilgisiDurum);
  if(IPKarsilastir(FAgBilgisiDurum.IP4Adres, IPAdres0)) then
    FAgBilgisi.RenkDegistir(RENK_KIRMIZI)
  else FAgBilgisi.RenkDegistir(RENK_YESIL);

  FMasaustu.Guncelle;
end;

// görev düðmesinin temsil ettiði pencere nesne kimliðini alýr
function TfrmAnaSayfa.PencereKimliginiAl(ABasilanDugme: TKimlik): TKimlik;
var
  i: TSayi4;
begin

  for i := 0 to CALISAN_PROGRAM_SAYISI - 1 do
  begin

    if not(FCalisanProgramlar[i].ProgramKayit.PencereKimlik = -1) then
    begin

      if not(FCalisanProgramlar[i].Dugme.Kimlik = ABasilanDugme) then
        Exit(FCalisanProgramlar[i].ProgramKayit.PencereKimlik);
    end;
  end;

  Result := -1;
end;

end.
