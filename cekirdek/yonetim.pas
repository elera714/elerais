{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: yonetim.pas
  Dosya Ýþlevi: sistem ana yönetim / kontrol kýsmý

  Güncelleme Tarihi: 21/05/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit yonetim;

interface

uses paylasim, gn_pencere, zamanlayici, dns, gorselnesne, irq, arge;

type
  // gerçek moddan gelen veri yapýsý
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

implementation

uses gdt, gorev, src_klavye, genel, ag, dhcp, sistemmesaj, src_vesa20, cmos,
  gn_masaustu, src_disket, vbox, usb, ohci, port, prg_cagri, prg_grafik,
  prg_kontrol, dosya, src_e1000, depolama, islevler;

{==============================================================================
  sistem ilk yükleme iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure Yukle;
var
  Gorev: PGorev;
  GMBilgi: PGMBilgi;
  Olay: POlay;
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

  // çekirdek bilgilerini al
  CekirdekBaslangicAdresi := GMBilgi^.CekirdekBaslangicAdresi;
  CekirdekUzunlugu := GMBilgi^.CekirdekKodUzunluk;

  // zamanlayýcý sayacýný sýfýrla
  ZamanlayiciSayaci := 0;

  // sistem sayacýný sýfýrla
  SistemSayaci := 0;
  CagriSayaci := 0;
  GrafikSayaci := 0;

  // öndeðer fare göstergesini belirle
  GecerliFareGostegeTipi := fitBekle;

  // çekirdeðin kullanacaðý TSS'nin içeriðini sýfýrla
  FillByte(GorevTSSListesi[0]^, 104, $00);

  // TSS içeriðini doldur
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

  // not: sistem için CS ve DS seçicileri bilden programý tarafýndan
  // oluþturuldu. tekrar oluþturmaya gerek yok

  // sistem için görev seçicisi (TSS)
  // Eriþim  : 1 = mevcut, 00 = DPL0, 010 = 32 bit kullanýlabilir TSS, 0 = meþgul biti (meþgul deðil), 1
  // Esneklik: 1 = gran = 1Byte çözünürlük, 00, 1 = bana tahsis edildi, 0000 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SECICI_SISTEM_TSS, TSayi4(GorevTSSListesi[0]), 104,
    %10001001, %00010000);

  // sistem görev deðerlerini belirle
  GorevListesi[0]^.GorevSayaci := 0;
  GorevListesi[0]^.BellekBaslangicAdresi := CekirdekBaslangicAdresi;
  GorevListesi[0]^.BellekUzunlugu := CekirdekUzunlugu;
  GorevListesi[0]^.OlaySayisi := 0;
  GorevListesi[0]^.OlayBellekAdresi := nil;
  GorevListesi[0]^.AktifMasaustu := nil;
  GorevListesi[0]^.AktifPencere := nil;

  GorevListesi[0]^.FDosyaAdi := 'cekirdek.bin';
  GorevListesi[0]^.FProgramAdi := 'Sistem Çekirdeði';

  // sistem görevini çalýþýyor olarak iþaretle
  Gorev := GorevListesi[0];
  Gorev^.OlaySayisi := 0;

  Olay := POlay(GGercekBellek.Ayir(4096));
  if not(Olay = nil) then
  begin

    Gorev^.FOlayBellekAdresi := Olay;
  end
  else
    Gorev^.FOlayBellekAdresi := nil;

  Gorev^.DurumDegistir(0, gdCalisiyor);

  // çalýþan ve oluþturulan görev deðerlerini belirle
  CalisanGorevSayisi := 1;
  CalisanGorev := 0;

  { TODO - aþaðýdaki 3 iþlev ve ileride eklenebilinecek diðer iþlevler
    sistemin parçasý (thread) olacak þekilde tek bir iþlevden oluþturulacak }

  // program çaðrýlarýna yanýt verecek görevi oluþtur
  CagriYanitlayiciyiOlustur(1, 'Sistem Çaðrýlarý', @ProgramCagrilariniYanitla);

  // grafik iþlevlerini yönetecek görevi oluþtur
  GrafikYoneticiGorevOlustur(2, 'Grafik Yöneticisi', @GrafikYonetimi);

  // sistem kontrol görevi oluþtur
  SistemKontrolGoreviOlustur(3, 'Sistem Kontrol', @KontrolYonetimi);

  // ilk TSS'yi yükle
  // not : tss'nin yükleme iþlevi görev geçiþini gerçekleþtirmez. sadece
  // TSS'yi meþgul olarak ayarlar.
  asm
           MOV     AX,SECICI_SISTEM_TSS * 8;
           LTR     AX
  end;
end;

{==============================================================================
  sistem ana kontrol kýsmý
 ==============================================================================}
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
  DosyaKimlik: TKimlik;
  DosyaNo: TSayi4 = 1;
  Olay: TOlay;
  Bellek0: Isaretci;
  Bellek: array of TSayi1;
  s: String;
  MD: PMantiksalDepolama;
begin

  // masaüstü uygulamasýnýn çalýþmasýný tamamlamasýný bekle
  BekleMS(100);

  // çekirdek deðiþim kontrol için cekirdek.bin dosyasýnýn yðklenme aþamasýndaki
  // tarih + saat deðerlerini kaydet
  CekirdekDosyaTSDegeriniKaydet;

  KaydedilenProgramlariYenidenYukle;

  SistemTusDurumuKontrolSol := tdYok;
  SistemTusDurumuKontrolSag := tdYok;
  SistemTusDurumuAltSol := tdYok;
  SistemTusDurumuAltSag := tdYok;
  SistemTusDurumuDegisimSol := tdYok;
  SistemTusDurumuDegisimSag := tdYok;

  // masaüstü aktif olana kadar bekle
  while GAktifMasaustu = nil do ;

  // sistem deðer görüntüleyicisini baþlat
  SistemDegerleriBasla;

  {Arge0 := TArGe.Create(2);
  Arge0.Calistir;}

  while True do
  begin

    // sistem sayacýný artýr
    Inc(SistemSayaci);

    // klavyeden basýlan tuþu al
    // 2 bytelýk TusDegeri deðiþken deðerinin üst byte'ý kontrol deðeri, alt byte'ý ise karakter deðeridir
    TusDurum := KlavyedenTusAl(TusDegeri);
    TusKontrolDegeri := (TusDegeri shr 8);
    TusKarakterDegeri := char(TusDegeri and $FF);

    if(TusDegeri <> 0) then
    begin

      if(TusDurum = tdBasildi) then
      begin

        //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Basýlan Tuþ Deðeri: %x', [TusDegeri]);

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
          // bilgi: agbilgi.c programýnýn seçeneðine baðlýdýr
          if(TusKarakterDegeri = '2') then
          begin

            if(AgYuklendi) then
            begin

              // að bilgileri öndeðerlerle yükleniyor
              IlkAdresDegerleriniYukle;

              DHCPIpAdresiAl;
            end
            else
            begin

              SISTEM_MESAJ(mtUyari, RENK_KIRMIZI,
                'Að yüklü olmadýðý için DHCP''den IP adresi alýnamýyor!', []);
            end;
          end
          // test amaçlý
          else if(TusKarakterDegeri = '3') then
          begin

            {BellekDegeriniGoster := True;
            Merhaba := '';
            for i := 1 to 11 do
              Merhaba += 'Bugün benim doðum günüm, unuttun mu, yoksa yine' + #13#10;

            //i := Length(Merhaba);
            SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ansistring deðer: %s', [Merhaba]);
            SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ansistring addres: $%x', [TSayi4(@Merhaba)]);
            SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ansistring U: %d', [i]);

            BellekDegeriniGoster := False;}

            DosyaKopyala('disk1:\resimler\1.bmp', 'disk2:\1.bmp');

            //Assert(True, 'Merhaba');

            //Gorev^.Calistir('disket1:\mustudk.c');
            //Gorev^.Calistir('disk1:\sisbilgi.c');
            //Gorev^.Calistir('disket1:\yzmcgor2.c');
            //vbox.Listele;
          end
          // test iþlev tuþu-1
          else if(TusKarakterDegeri = '4') then
          begin

            {dosya.Assign(DosyaKimlik, 'disk1:\klasor\klsr' + IntToStr(DosyaNo));
            dosya.CreateDir(DosyaKimlik);

            Inc(DosyaNo);

            dosya.Close(DosyaKimlik);}


            //Gorev^.Calistir('disk1:\progrmlr\saat.c');
            //iiiii := Align(SizeOf(TIzgara) + 64, 16);
            //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'U: %d', [iiiii]);



            //pic.Maskele(0);
            {IRR := pic.ISRDegeriniOku;
            SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'IRR Deðeri: %x', [IRR]);}


            //BekleMS(10000);

            //          pic.MaskeKaldir(0);

            // aþaðýdaki programlar üzerinden fdc iþlemleri tamamlanacak
            //Gorev^.Calistir('disket1:\kopyala.c');
            //Gorev^.Calistir('disket1:\dskgor.c');

            //vbox.IcerigiGoruntule;
            //Gorev^.Calistir('disk1:\arpbilgi.c');

            {Disk := SurucuAl('disk2:');
            SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Disk2-1: %d', [Disk^.Acilis.DizinGirisi.IlkSektor]);
            SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Disk2-2: %d', [Disk^.Acilis.DizinGirisi.ToplamSektor]);}
          end
          // test iþlev tuþu-2
          else if(TusKarakterDegeri = '5') then
          begin

            MD := MantiksalSurucuAl('disk2');
            if not(MD = nil) then ELR1DiskBicimle(MD);
          end
          // program çalýþtýrma programýný çalýþtýr
          else if(TusKarakterDegeri = 'c') then

            //ohci.Kontrol1
            Gorev^.Calistir('calistir.c')

          // dosya yöneticisi programýný çalýþtýr
          else if(TusKarakterDegeri = 'd') then

            Gorev^.Calistir('dsyyntcs.c')

          // görev yöneticisi programýný çalýþtýr
          else if(TusKarakterDegeri = 'g') then

            Gorev^.Calistir('grvyntcs.c')

          // giriþ kutusundaki veriyi panoya kopyala
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

          // mesaj görüntüleme programýný çalýþtýr
          else if(TusKarakterDegeri = 'm') then

            Gorev^.Calistir('smsjgor.c')

          // resim görüntüleme programýný çalýþtýr
          else if(TusKarakterDegeri = 'r') then

            Gorev^.Calistir('resimgor.c')

          // panodaki veriyi giriþ kutusuna yapýþtýr
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

            //SISTEM_MESAJ(mtBilgi, RENK_YESIL, 'Aktif Masaüstü: %d', [i])

            // aktif masaüstünü deðiþtir
            Masaustu := GMasaustuListesi[i];
            if not(Masaustu = nil) then
            begin

              // masaüstünü aktif olarak iþaretle
              GAktifMasaustu := Masaustu;
              GAktifMasaustu^.Aktiflestir;

              // masaüstünü çiz
              GAktifMasaustu^.Ciz;
            end;
          end;
        end
        else if(SistemTusDurumuAltSol = tdBasildi) or (SistemTusDurumuAltSag = tdBasildi) then
        begin

          // aktif uygulamaya kendisini kapatma mesajý gönder
          if(TusDegeri = TUS_F4) then
          begin

            Olay.Kimlik := GAktifPencere^.Kimlik;
            Olay.Olay := CO_SONLANDIR;
            Olay.Deger1 := 0;
            Olay.Deger2 := 0;
            if not(GAktifPencere^.OlayYonlendirmeAdresi = nil) then
              GAktifPencere^.OlayYonlendirmeAdresi(GAktifPencere, Olay)
            else GorevListesi[GAktifPencere^.GorevKimlik]^.OlayEkle(GAktifPencere^.GorevKimlik, Olay);
          end;
        end
        else
        begin

          //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Basýlan Tuþ: %d', [TusDegeri]);

          // klavye olaylarýný iþle
          // kontrol tuþu haricinde basýlan tüm tuþlarý ilgili uygulamaya yönlendir
          if((TusDegeri and $FF00) = 0) then
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

    // fare olaylarýný iþle
    GOlayYonetim.FareOlaylariniIsle;

    // disket sürücü motorunun aktifliðini kontrol eder, gerekirse motoru kapatýr
    DisketSurucuMotorunuKontrolEt;

    // sonlandýrýlmýþ olarak iþaretlenen görevleri sonlandýr
    IsaretlenenGorevleriSonlandir;
  end;
end;

// sistemin yüklenme esnasýnda çekirdeðin tarih + saat deðerini kaydeder
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
  i: TSayi4;
  FD: TFizikselDepolama;
  GN: PGorselNesne;
  Bellek: PChar;
  s: string;
  MUGorev: PGorev;
  P4: PSayi4;
  Konum: TKonum;
  Boyut: TBoyut;
begin

  for i := 0 to 5 do
  begin

    FD := FizikselDepolamaAygitListesi[i];
    if(FD.Mevcut0) and (FD.FD3.SurucuTipi = SURUCUTIP_DISK) and
      (FD.FD3.AygitAdi = 'fda4') then
    begin

      FD.SektorOku(@FD, 10, 1, Isaretci($3200000));
      Break;
    end;
  end;

  Bellek := Isaretci($3200000);

  s := '';
  while Bellek^ <> #0 do
  begin

    while Bellek^ <> #0 do
    begin

      s += Bellek^;
      Inc(Bellek);
    end;

    Inc(Bellek);
    P4 := PSayi4(Bellek);

    Konum.Sol := P4^;
    Inc(P4);
    Konum.Ust := P4^;
    Inc(P4);
    Boyut.Genislik := P4^;
    Inc(P4);
    Boyut.Yukseklik := P4^;
    Inc(P4);

    Bellek := PChar(P4);

    if(Length(s) > 0) then
    begin

      MUGorev := MUGorev^.Calistir(AcilisSurucuAygiti + ':\progrmlr\' + s);
      BekleMS(50);

      GN := GN^.NesneAl(MUGorev^.AktifPencere^.Kimlik);

      PPencere(GN)^.FKonum.Sol := Konum.Sol;
      PPencere(GN)^.FKonum.Ust := Konum.Ust;
      PPencere(GN)^.FBoyut.Genislik := Boyut.Genislik;
      PPencere(GN)^.FBoyut.Yukseklik := Boyut.Yukseklik;
      PPencere(GN)^.Guncelle;

      PMasaustu(GN^.AtaNesne)^.Ciz;

      //SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'NesneAdi: %s', [PPencere(GN)^.NesneAdi]);
      //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Konum.Ust: %d', [Konum.Ust]);
    end;

    //Inc(Bellek);
    s := '';
  end;
end;

end.
