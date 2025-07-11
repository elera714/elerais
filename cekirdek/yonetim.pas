{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: yonetim.pas
  Dosya ��levi: sistem ana y�netim / kontrol k�sm�

  G�ncelleme Tarihi: 21/05/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit yonetim;

interface

uses paylasim, gn_pencere, zamanlayici, dns, gorselnesne, irq, arge, thread;

type

  { TMyThread }

  TMyThread = class(TThread)
  private
    //procedure ShowStatus;
  protected
    procedure Execute; override;
  public
    constructor Create(CreateSuspended: Boolean);
  end;

type

  { TMyThread2 }

  TMyThread2 = class(TThread)
  private
    //procedure ShowStatus;
  protected
    procedure Execute; override;
  public
    constructor Create(CreateSuspended: Boolean);
  end;

type
  // ger�ek moddan gelen veri yap�s�
  PGMBilgi = ^TGMBilgi;

  TGMBilgi = packed record
    VideoBellekUzunlugu: TSayi2;
    VideoEkranMod: TSayi2;
    VideoYatayCozunurluk: TSayi2;
    VideoDikeyCozunurluk: TSayi2;
    VideoBellekAdresi: TSayi4;
    VideoPixelBasinaBitSayisi: TSayi1;
    VideoSatirdakiByteSayisi: TSayi2;
    CekirdekBaslangicAdresi: TSayi4;
    CekirdekKodUzunluk: TSayi4;
  end;

var
  P1Zamanlayici: PZamanlayici;
  _DNS: PDNS = nil;
  Arge0: TArGe;
  Merhaba: AnsiString = 'Merhaba';

procedure Yukle;
procedure SistemAnaKontrol;
procedure CekirdekDosyaTSDegeriniKaydet;
procedure KaydedilenProgramlariYenidenYukle;
procedure AssertIslev(const msg,fname:ShortString;lineno:longint;erroraddr:pointer);

implementation

uses gdt, gorev, src_klavye, genel, ag, dhcp, sistemmesaj, src_vesa20, cmos,
  gn_masaustu, src_disket, vbox, usb, ohci, port, prg_grafik, prg_kontrol, dosya,
  src_e1000, depolama, islevler, bolumleme, donusum, arp, gercekbellek;

{==============================================================================
  sistem ilk y�kleme i�levlerini ger�ekle�tirir
 ==============================================================================}
procedure Yukle;
var
  G: PGorev;
  GMBilgi: PGMBilgi;
  Olay: POlay;
  GrafikESP, KontrolESP,
  OHCIESP, ARPESP,
  Prg1ESP, Prg2ESP: Isaretci;
begin

  GMBilgi := PGMBilgi(BILDEN_VERIADRESI);

  // video bilgilerini al
  GEkranKartSurucusu.KartBilgisi.BellekUzunlugu := GMBilgi^.VideoBellekUzunlugu;
  GEkranKartSurucusu.KartBilgisi.EkranMod := GMBilgi^.VideoEkranMod;
  GEkranKartSurucusu.KartBilgisi.YatayCozunurluk := GMBilgi^.VideoYatayCozunurluk;
  GEkranKartSurucusu.KartBilgisi.DikeyCozunurluk := GMBilgi^.VideoDikeyCozunurluk;
  GEkranKartSurucusu.KartBilgisi.BellekAdresi := GMBilgi^.VideoBellekAdresi;
  //VIDEO_MEM_ADDR;
  GEkranKartSurucusu.KartBilgisi.PixelBasinaBitSayisi :=
    GMBilgi^.VideoPixelBasinaBitSayisi;
  GEkranKartSurucusu.KartBilgisi.NoktaBasinaByteSayisi :=
    (GMBilgi^.VideoPixelBasinaBitSayisi div 8);
  GEkranKartSurucusu.KartBilgisi.SatirdakiByteSayisi :=
    GMBilgi^.VideoSatirdakiByteSayisi;

  // �ekirdek bilgilerini al
  CekirdekBaslangicAdresi := GMBilgi^.CekirdekBaslangicAdresi;
  CekirdekUzunlugu := GMBilgi^.CekirdekKodUzunluk;

  // zamanlay�c� sayac�n� s�f�rla
  ZamanlayiciSayaci := 0;

  // sistem sayac�n� s�f�rla
  SistemSayaci := 0;
  CagriSayaci := 0;
  GrafikSayaci := 0;

  // �nde�er fare g�stergesini belirle
  GecerliFareGostegeTipi := fitBekle;

  // �ekirde�in kullanaca�� TSS'nin i�eri�ini s�f�rla
  FillByte(GorevTSSListesi[0]^, 104, $00);

  // TSS i�eri�ini doldur
  //GorevTSSListesi[0].CR3 := GERCEKBELLEK_DIZINADRESI;
  GorevTSSListesi[0]^.EIP := TSayi4(@SistemAnaKontrol);
  GorevTSSListesi[0]^.EFLAGS := $202;
  GorevTSSListesi[0]^.ESP := SISTEM_ESP;
  GorevTSSListesi[0]^.CS := SECICI_SISTEM_KOD * 8;
  GorevTSSListesi[0]^.DS := SECICI_SISTEM_VERI * 8;
  GorevTSSListesi[0]^.ES := SECICI_SISTEM_VERI * 8;
  GorevTSSListesi[0]^.SS := SECICI_SISTEM_VERI * 8;
  GorevTSSListesi[0]^.FS := SECICI_SISTEM_VERI * 8;
  GorevTSSListesi[0]^.GS := SECICI_SISTEM_VERI * 8;
  GorevTSSListesi[0]^.SS0 := SECICI_SISTEM_VERI * 8;

  // not: sistem i�in CS ve DS se�icileri bilden program� taraf�ndan
  // olu�turuldu. tekrar olu�turmaya gerek yok

  // sistem i�in g�rev se�icisi (TSS)
  // Eri�im  : 1 = mevcut, 00 = DPL0, 010 = 32 bit kullan�labilir TSS, 0 = me�gul biti (me�gul de�il), 1
  // Esneklik: 1 = gran = 1Byte ��z�n�rl�k, 00, 1 = bana tahsis edildi, 0000 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SECICI_SISTEM_TSS, TSayi4(GorevTSSListesi[0]), 104,
    %10001001, %00010000);

  // sistem g�rev de�erlerini belirle
  G := GorevListesi[0];
  G^.G0.FSeviyeNo := CALISMA_SEVIYE0;
  G^.G0.FGorevSayaci := 0;
  G^.G0.FBellekBaslangicAdresi := CekirdekBaslangicAdresi;
  G^.FCalismaSuresiMS := 20;
  G^.FCalismaSuresiSayacMS := 20;
  G^.BellekUzunlugu := CekirdekUzunlugu;
  G^.FOlaySayisi := 0;
  G^.OlayBellekAdresi := nil;
  G^.AktifMasaustu := nil;
  G^.AktifPencere := nil;

  G^.FDosyaAdi := 'cekirdek.bin';
  G^.FProgramAdi := 'Sistem �ekirde�i';

  // sistem g�revini �al���yor olarak i�aretle
  G^.FOlaySayisi := 0;

  Olay := POlay(GGercekBellek.Ayir(4096));
  if not(Olay = nil) then
    G^.FOlayBellekAdresi := Olay
  else G^.FOlayBellekAdresi := nil;

  GGorevler.DurumDegistir(0, gdCalisiyor);

  // �al��an ve olu�turulan g�rev de�erlerini belirle
  CalisanGorevSayisi := 1;
  FAktifGorev := 0;

  // grafik i�levlerini y�netecek g�revi olu�tur
  GrafikESP := GetMem(8192);
  Memur('grafik y�neticisi', @GrafikYonetimi, TSayi4(GrafikESP), CALISMA_SEVIYE0);

  // sistem kontrol g�revi olu�tur
  KontrolESP := GetMem(8192);
  Memur('sistem denetim', @KontrolYonetimi, TSayi4(KontrolESP), CALISMA_SEVIYE0);

  // ohci kontrol g�revi olu�tur
  GetMem(OHCIESP, 4096);
  Memur('ohci', @ohci.Kontrol1, TSayi4(OHCIESP), CALISMA_SEVIYE0);

  // arp tablosu g�ncelleme g�revi olu�tur
  ARPESP := GetMem(4096);
  Memur('arp', @ARPTablosunuGuncelle, TSayi4(ARPESP), CALISMA_SEVIYE0);

  {GetMem(Prg1ESP, 4096);
  Memur('prg1', @Prg1, TSayi4(Prg1ESP), CALISMA_SEVIYE0);

  GetMem(Prg2ESP, 4096);
  Memur('prg2', @Prg2, TSayi4(Prg2ESP), CALISMA_SEVIYE0);}

  // ilk TSS'yi y�kle
  // not : tss'nin y�kleme i�levi g�rev ge�i�ini ger�ekle�tirmez. sadece
  // TSS'yi me�gul olarak ayarlar.
  asm
    mov ax,SECICI_SISTEM_TSS * 8;
    ltr ax
  end;
end;

{==============================================================================
  sistem ana kontrol k�sm�
 ==============================================================================}
var
  AracTipleri: TAracTipleriSinif;

procedure SistemAnaKontrol;
var
  Gorev: PGorev = nil;
  TusDegeri, IRR: TSayi2;
  TusKontrolDegeri: TSayi1;
  TusKarakterDegeri: char;
  TusDurum: TTusDurum;
  i: TSayi4;
  Masaustu: PMasaustu;
  GN: PGorselNesne;
  Olay: TOlay;
  Bellek1, Bellek2,
  Bellek3, Bellek4,
  Bellek5: Isaretci;
  MD: PMantiksalDepolama;
  T: TMyThread;
  A, B: TAracTipiSinif;
  G: PGorev;
  //T: TMyThread;
  //T2: TMyThread2;
begin

  AracTipleri := TAracTipleriSinif.Create;
  i := 100;

  // masa�st� uygulamas�n�n �al��mas�n� tamamlamas�n� bekle
  BekleMS(100);

  // �ekirdek de�i�im kontrol i�in cekirdek.bin dosyas�n�n y�klenme a�amas�ndaki
  // tarih + saat de�erlerini kaydet
  CekirdekDosyaTSDegeriniKaydet;

  KaydedilenProgramlariYenidenYukle;

  SistemTusDurumuKontrolSol := tdYok;
  SistemTusDurumuKontrolSag := tdYok;
  SistemTusDurumuAltSol := tdYok;
  SistemTusDurumuAltSag := tdYok;
  SistemTusDurumuDegisimSol := tdYok;
  SistemTusDurumuDegisimSag := tdYok;

  // masa�st� aktif olana kadar bekle
  while GAktifMasaustu = nil do ;

  // sistem de�er g�r�nt�leyicisini ba�lat
  SistemDegerleriBasla;

  {Arge0 := TArGe.Create(2);
  Arge0.Calistir;}

  while True do
  begin

    // sistem sayac�n� art�r
    Inc(SistemSayaci);

    // klavyeden bas�lan tu�u al
    // 2 bytel�k TusDegeri de�i�ken de�erinin �st byte'� kontrol de�eri, alt byte'� ise karakter de�eridir
    TusDurum := KlavyedenTusAl(TusDegeri);
    TusKontrolDegeri := (TusDegeri shr 8);
    TusKarakterDegeri := Char(TusDegeri and $FF);

    if(TusDegeri <> 0) then
    begin

      if(TusDurum = tdBasildi) then
      begin

        //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Bas�lan Tu� De�eri: %x', [TusDegeri]);

        if(TusDegeri = TUS_KONTROL_SOL) then
          SistemTusDurumuKontrolSol := tdBasildi
        else if(TusDegeri = TUS_KONTROL_SAG) then
          SistemTusDurumuKontrolSag := tdBasildi
        else if(TusDegeri = TUS_ALT_SOL) then
          SistemTusDurumuAltSol := tdBasildi
        else if(TusDegeri = TUS_ALT_SAG) then
          SistemTusDurumuAltSag := tdBasildi
        else if(TusDegeri = TUS_DEGISIM_SOL) then
          SistemTusDurumuDegisimSol := tdBasildi
        else if(TusDegeri = TUS_DEGISIM_SAG) then
          SistemTusDurumuDegisimSag := tdBasildi;

        if(SistemTusDurumuKontrolSol = tdBasildi) or
          (SistemTusDurumuKontrolSag = tdBasildi) then
        begin

          // DHCP sunucusundan IP adresi al
          // bilgi: agbilgi.c program�n�n se�ene�ine ba�l�d�r
          if(TusKarakterDegeri = '2') then
          begin

            if(AgYuklendi) then
            begin

              // a� bilgileri �nde�erlerle y�kleniyor
              IlkAdresDegerleriniYukle;

              DHCPIpAdresiAl;
            end
            else
            begin

              SISTEM_MESAJ(mtUyari, RENK_KIRMIZI,
                'A� y�kl� olmad��� i�in DHCP''den IP adresi al�nam�yor!', []);
            end;
          end
          // test ama�l�
          else if(TusKarakterDegeri = '3') then
          begin

            //GSistemMesaj.Ekle0(mtBilgi, RENK_KIRMIZI, 'Merhaba');

            {A := AracTipleri.Ekle;
            A.Kimlik := 11111111;
            B := AracTipleri.Ekle;
            B.Kimlik := 22222222;
            B := AracTipleri.Ekle;
            B.Kimlik := 33333333;
            B := AracTipleri.Ekle;
            B.Kimlik := 44444444;

            asm
              mov esi,AracTipleri;
              mov ebx,2
              shl ebx,2
              mov esi,[esi + TAracTipleriSinif.FAracTipListesi + ebx]
              mov eax,[esi + TAracTipiSinif.FKimlik]
              mov i,eax
            end;

            SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'Toplam: %d', [AracTipleri.Toplam]);
            SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'De�er1: %d', [i]);
            SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'De�er2: %d', [TSayi4(@AracTipleri)]);
                      }
            //i := TSayi4(@GorevListesi[4]^.G0);
            //SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'De�er: %d', [G^.G0.FGorevSayaci]);
            //i := PSayi4(i)^;
            //SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'De�er: %d', [G^.G0.FDeger]);
            //i := TSayi4(@GorevListesi[4]^.G0.FGorevSayaci);
            //SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'De�er: %d', [G^.G0.FDeger2]);
            {i := TSayi4(@GorevListesi[4]^.G0.FDeger);
            SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'De�er: %x', [i]);
            i := TSayi4(@GorevListesi[4]^.G0.FDeger2);
            SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'De�er: %x', [i]);}

            //SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'Kimlik: %d', [A.Kimlik]);

            //T := TMyThread.Create(True);
            {T.Start;}

            //T2 := TMyThread2.Create(True);
            //T2.Start;

            //AssertErrorProc := @AssertIslev;
            //Assert(1 > 2, 'Merhaba');

            //for i := 1 to 100 do CreateDir('disk2:\merhaba\mer' + IntToStr(i));
            //DosyalariKopyala;
            //DosyaKopyala('disk1:\progrmlr\dskbolum.c', 'disk2:\dskbolum.c');
            //BellekDegeriniGoster := True;
            {Merhaba := '';
            for i := 1 to 11 do Merhaba += 'ELERA ��letim Sistemi' + #13#10;

            //i := Length(Merhaba);
            SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ansistring de�er: %s', [Merhaba]);
            SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ansistring addres: $%x', [TSayi4(@Merhaba)]);
            SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ansistring U: %d', [i]);

            BellekDegeriniGoster := False;}

            //Assert(True, 'Merhaba');

            //vbox.Listele;
          end
          // test i�lev tu�u-1
          else if(TusKarakterDegeri = '4') then
          begin

            for i := 0 to AracTipleri.Toplam - 1 do
            begin

              SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'De�er: %d', [AracTipleri.AracTipi[i].Kimlik]);
            end;
            //iiiii := Align(SizeOf(TIzgara) + 64, 16);
            //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'U: %d', [iiiii]);

            //pic.Maskele(0);
            {IRR := pic.ISRDegeriniOku;
            SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'IRR De�eri: %x', [IRR]);}


            //BekleMS(10000);

            //          pic.MaskeKaldir(0);

            //vbox.IcerigiGoruntule;
          end
          // test i�lev tu�u-2
          else if(TusKarakterDegeri = '5') then
          begin

            MD := GDepolama.MantiksalSurucuAl('disk2');
            if not(MD = nil) then ELR1DiskBicimle(MD);
          end
          // program �al��t�rma program�n� �al��t�r
          else if(TusKarakterDegeri = 'c') then

            GGorevler.Calistir('calistir.c', CALISMA_SEVIYE3)

          // dosya y�neticisi program�n� �al��t�r
          else if(TusKarakterDegeri = 'd') then

            GGorevler.Calistir('dsyyntcs.c', CALISMA_SEVIYE3)

          // g�rev y�neticisi program�n� �al��t�r
          else if(TusKarakterDegeri = 'g') then

            //GGorevler.Calistir('yzmcgor2.c', CALISMA_SEVIYE3)
            GGorevler.Calistir('grvyntcs.c', CALISMA_SEVIYE3)

          // giri� kutusundaki veriyi panoya kopyala
          else if(TusKarakterDegeri = 'k') then
          begin

            if(GAktifPencere <> nil) then
            begin

              GN := GAktifPencere^.FAktifNesne;
              if(GN <> nil) and (GN^.NesneTipi = gntGirisKutusu) then
              begin

                PanoDegeri := GN^.Baslik;
              end;
            end;
          end

          // mesaj g�r�nt�leme program�n� �al��t�r
          else if(TusKarakterDegeri = 'm') then

            GGorevler.Calistir('smsjgor.c', CALISMA_SEVIYE3)

          // resim g�r�nt�leme program�n� �al��t�r
          else if(TusKarakterDegeri = 'r') then

            GGorevler.Calistir('resimgor.c', CALISMA_SEVIYE3)

          // panodaki veriyi giri� kutusuna yap��t�r
          else if(TusKarakterDegeri = 'y') then
          begin

            if(GAktifPencere <> nil) then
            begin

              GN := GAktifPencere^.FAktifNesne;
              if(GN <> nil) and (GN^.NesneTipi = gntGirisKutusu) then
              begin

                if(Length(PanoDegeri) > 0) then
                  GN^.Baslik := PanoDegeri;
              end;
            end;
          end
          else if(TusDegeri >= TUS_F1) and (TusDegeri <= TUS_F4) then
          begin

            i := (TusDegeri - TUS_F1);

            //SISTEM_MESAJ(mtBilgi, RENK_YESIL, 'Aktif Masa�st�: %d', [i])

            // aktif masa�st�n� de�i�tir
            Masaustu := GMasaustuListesi[i];
            if not(Masaustu = nil) then
            begin

              // masa�st�n� aktif olarak i�aretle
              GAktifMasaustu := Masaustu;
              GAktifMasaustu^.Aktiflestir;

              // masa�st�n� �iz
              GAktifMasaustu^.Ciz;
            end;
          end;
        end
        else if(SistemTusDurumuAltSol = tdBasildi) or (SistemTusDurumuAltSag = tdBasildi) then
        begin

          // aktif uygulamaya kendisini kapatma mesaj� g�nder
          if(TusDegeri = TUS_F4) then
          begin

            Olay.Kimlik := GAktifPencere^.FTGN.Kimlik;
            Olay.Olay := CO_SONLANDIR;
            Olay.Deger1 := 0;
            Olay.Deger2 := 0;
            if not(GAktifPencere^.OlayYonlendirmeAdresi = nil) then
              GAktifPencere^.OlayYonlendirmeAdresi(GAktifPencere, Olay)
            else GGorevler.OlayEkle(GAktifPencere^.GorevKimlik, Olay);
          end;
        end
        else
        begin

          //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Bas�lan Tu�: %d', [TusDegeri]);

          // klavye olaylar�n� i�le
          // kontrol tu�u haricinde bas�lan t�m tu�lar� ilgili uygulamaya y�nlendir

          { TODO - burada kontrol tu�lar� ve karakter tu�lar� ayr� ayr� de�erlendirilerek
            farkl� olaylar olarak uygulamalara g�nderilecek }
          //if((TusDegeri and $FF00) = 0) then
            GOlayYonetim.KlavyeOlaylariniIsle(TusDegeri, TusDurum);
        end;
      end
      else if(TusDurum = tdBirakildi) then
      begin

        if(TusDegeri = TUS_KONTROL_SOL) then
          SistemTusDurumuKontrolSol := tdBirakildi
        else if(TusDegeri = TUS_KONTROL_SAG) then
          SistemTusDurumuKontrolSag := tdBirakildi
        else if(TusDegeri = TUS_ALT_SOL) then
          SistemTusDurumuAltSol := tdBirakildi
        else if(TusDegeri = TUS_ALT_SAG) then
          SistemTusDurumuAltSag := tdBirakildi
        else if(TusDegeri = TUS_DEGISIM_SOL) then
          SistemTusDurumuDegisimSol := tdBirakildi
        else if(TusDegeri = TUS_DEGISIM_SAG) then
          SistemTusDurumuDegisimSag := tdBirakildi;
      end;
    end;

    AgKartiVeriAlmaIslevi;

    // fare olaylar�n� i�le
    GOlayYonetim.FareOlaylariniIsle;

    // disket s�r�c� motorunun aktifli�ini kontrol eder, gerekirse motoru kapat�r
    DisketSurucuMotorunuKontrolEt;

    // sonland�r�lm�� olarak i�aretlenen g�revleri sonland�r
    IsaretlenenGorevleriSonlandir;
  end;
end;

// sistemin y�klenme esnas�nda �ekirde�in tarih + saat de�erini kaydeder
procedure CekirdekDosyaTSDegeriniKaydet;
var
  i: TISayi4;
  AramaKaydi: TDosyaArama;
  j: TSayi2;
begin

  i := dosya.FindFirst('disket1:\*.*', 0, AramaKaydi);
  while i = 0 do
  begin

    if(AramaKaydi.DosyaAdi = 'cekirdek.bin') then
    begin

      j := AramaKaydi.SonDegisimTarihi;
      CekirdekYuklemeTS.Gun := j and 31;
      CekirdekYuklemeTS.Ay := (j shr 5) and 15;
      CekirdekYuklemeTS.Yil := ((j shr 9) and 127) + 1980;

      j := AramaKaydi.SonDegisimSaati;
      CekirdekYuklemeTS.Saniye := (j and 31) * 2;
      CekirdekYuklemeTS.Dakika := (j shr 5) and 63;
      CekirdekYuklemeTS.Saat := (j shr 11) and 31;

      Break;
    end;

    i := dosya.FindNext(AramaKaydi);
  end;

  dosya.FindClose(AramaKaydi);
end;

procedure KaydedilenProgramlariYenidenYukle;
var
  GN: PGorselNesne;
  s, DosyaAdi, s2: string;
  MUGorev: PGorev;
  Konum: TKonum;
  Boyut: TBoyut;
  DosyaKimlik: TKimlik;
  U: TISayi8;
  Bellek0: Isaretci;
  SiraNo, Kod,
  i, j, k: TSayi4;
begin

  AssignFile(DosyaKimlik, 'disk2:\yuklenecek_programlar.ini');
  Reset(DosyaKimlik);
  if(IOResult = HATA_YOK) then
  begin

    U := FileSize(DosyaKimlik);
    Bellek0 := GGercekBellek.Ayir(U);
    //GetMem(Bellek0, U);

    Read(DosyaKimlik, Bellek0);

    j := 0;
    i := 0;
    repeat

      i := Pos(#10, PChar(Bellek0));
      if(i > 0) then
      begin

        Dec(i);
        s := Copy(PChar(Bellek0 + j), 0, (i - j) - 1);
        PChar(Bellek0 + i)^ := ' ';
        j := i + 1;

        if(Length(s) > 0) then
        begin

          DosyaAdi := '';
          Konum.Sol := 0;
          Konum.Ust := 0;
          Boyut.Genislik := 0;
          Boyut.Yukseklik := 0;
          SiraNo := 1;

          repeat

            k := Pos(';', s);
            if(k > 0) then
            begin

              case SiraNo of
                1: DosyaAdi := Copy(s, 1, k - 1);
                2: begin s2:= Copy(s, 1, k - 1); Val(s2, Konum.Sol, Kod) end;
                3: begin s2:= Copy(s, 1, k - 1); Val(s2, Konum.Ust, Kod) end;
                4: begin s2:= Copy(s, 1, k - 1); Val(s2, Boyut.Genislik, Kod) end;
              end;

              Delete(s, 1, k);
              Inc(SiraNo);
            end
            else
            begin

              s2:= s;
              Val(s2, Boyut.Yukseklik, Kod);
              k := 0;
            end;

          until k = 0;

          {SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Dosya Ad�: "%s"', [DosyaAdi]);
          SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Sol: "%d, �st: %d"', [Sol, Ust]);
          SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Geni�lik: "%d, Y�kseklik: %d"', [Genislik, Yukseklik]);}

          MUGorev := GGorevler.Calistir(AcilisSurucuAygiti + ':\progrmlr\' + DosyaAdi, CALISMA_SEVIYE3);

          BekleMS(50);

          GN := GN^.NesneAl(MUGorev^.AktifPencere^.FTGN.Kimlik);

          PPencere(GN)^.FKonum.Sol := Konum.Sol;
          PPencere(GN)^.FKonum.Ust := Konum.Ust;
          PPencere(GN)^.FBoyut.Genislik := Boyut.Genislik;
          PPencere(GN)^.FBoyut.Yukseklik := Boyut.Yukseklik;
          PPencere(GN)^.Guncelle;

          PMasaustu(GN^.AtaNesne)^.Ciz;
        end;
      end;
    until i = 0;

    //FreeMem(Bellek0, U);
    GGercekBellek.YokEt(Bellek0, U);
  end;

  CloseFile(DosyaKimlik);
end;

procedure AssertIslev(const msg,fname:ShortString;lineno:longint;erroraddr:pointer);
begin

  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Assert: %s', [msg]);
end;

{ TMyThread2 }

procedure TMyThread2.Execute;
begin

  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'TMyThread2', []);
end;

constructor TMyThread2.Create(CreateSuspended: Boolean);
begin

  inherited Create(CreateSuspended);
end;

{ TMyThread }

procedure TMyThread.Execute;
begin

  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'TMyThread', []);
  //BekleMS(200);
end;

constructor TMyThread.Create(CreateSuspended: Boolean);
begin

  inherited Create(CreateSuspended);
  //FreeOnTerminate := True;
end;

end.
