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

uses paylasim, gn_pencere, zamanlayici, gorselnesne, arge;

type
  TYonetim = object
  public
    procedure Yukle;
    procedure SistemAnaKontrol;
    procedure CekirdekDosyaTSDegeriniKaydet;
    procedure KaydedilenProgramlariYenidenYukle;
    procedure AssertIslev(const msg,fname:ShortString;lineno:longint;erroraddr:pointer);
  end;

var
  GArge: TArGe;
  GYonetim0: TYonetim;

implementation

uses gdt, gorev, src_klavye, dhcpv4i, sistemmesaj, dosyalar, gn_masaustu, src_disket,
  srv_grafik, srv_kontrol, srv_test, fdepolama, mdepolama, baglantilar, olayyonetim,
  gn_islevler, src_ps2, thread, srv_arp, aygityonetimi, sistem, aygit;

{==============================================================================
  sistem ilk yükleme iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure TYonetim.Yukle;
var
  G: PGorev;
  GMBilgi: PGMBilgi;
  Olay: POlay;
  OHCIESP, ARPESP1,
  Prg1ESP, Prg2ESP: Isaretci;
  PrgTest: TPrgTest;
  ServisKontrol: TServisKontrol;
  ServisGrafik: TServisGrafik;
  ServisARP: TServisARP;
begin

  GMBilgi := PGMBilgi(BILDEN_VERIADRESI);

  // çekirdek bilgilerini al
  CekirdekBaslangicAdresi := GMBilgi^.CekirdekBaslangicAdresi;
  CekirdekUzunlugu := GMBilgi^.CekirdekKodUzunluk;

  // öndeðer fare göstergesini belirle
  GFareSurucusu.AktifFareImlec := fitBekle;

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
  G := GetMem(SizeOf(TGorev));
  GGorevler.Gorev[0] := G;
  G^.SeviyeNo := CALISMA_SEVIYE0;
  G^.GrvSayac := 0;
  G^.BellekBasAdr := CekirdekBaslangicAdresi;
  G^.CalismaSureMS := DPL0_SUREMS;
  G^.CalismaSureSayac := DPL0_SUREMS;

  { TODO - CekirdekUzunlugu -> *4K olarak hesaplanacak }
  G^.BellekUz := CekirdekUzunlugu;

  // çekirdek için olay iþlemleri gerçekleþmeyecek
  G^.OlaySayisi := 0;
  G^.OlayBellekAdresi := nil;

  G^.AktifMasaustu := nil;
  G^.AktifPencere := nil;

  G^.DosyaAdi := 'cekirdek.bin';
  G^.ProgramAdi := 'Sistem Çekirdeði';

  // görev olay sayýsý
  G^.OlaySayisi := 0;

  GGorevler.DurumDegistir(0, gdCalisiyor);

  // çalýþan ve oluþturulan görev deðerlerini belirle
  GGorevler.FCalisanGorevSayisi := 1;
  GGorevler.FAktifGrv := 0;

  // grafik iþlevlerini yönetecek görevi oluþtur
  ServisGrafik := TServisGrafik.Create('SGrafik');
  ServisGrafik.Start;

  // sistem kontrol görevi oluþtur
  PrgTest := TPrgTest.Create('STest');
  PrgTest.Start;

  ServisKontrol := TServisKontrol.Create('SKontrol');
  ServisKontrol.Start;

  PrgTest := TPrgTest.Create('SPrgTest');
  PrgTest.Start;

  // ohci kontrol görevi oluþtur
  {GPrgOHCI := TPrgOHCI.Create;
  GetMem(OHCIESP, 4096);
  Memur('ohci', @GPrgOHCI.Kontrol1, TSayi4(OHCIESP), CALISMA_SEVIYE0, True);}


  // arp tablosu güncelleme görevi oluþtur
  { TODO - aþaðýdaki 2 iþlev Create iþlevinden sonraki bir yere eklenecek }
  ServisARP := TServisARP.Create('SARPGüncelleme');
  ServisARP.Start;

  {ARPESP1 := GetMem(4096);
  Memur('arp_dolaþým', @GARP.CihazlaraARPMesajiGonder, TSayi4(ARPESP1),
    CALISMA_SEVIYE0, True);}

  {GetMem(Prg1ESP, 4096);
  Memur('prg1', @Program1, TSayi4(Prg1ESP), CALISMA_SEVIYE0, True);

  GetMem(Prg2ESP, 4096);
  Memur('prg2', @Program2, TSayi4(Prg2ESP), CALISMA_SEVIYE0, True);}

  // ilk TSS'yi yükle
  // not : tss'nin yükleme iþlevi görev geçiþini gerçekleþtirmez. sadece
  // TSS'yi meþgul olarak ayarlar.
  asm
    mov ax,SECICI_SISTEM_TSS * 8;
    ltr ax
  end;
end;

{==============================================================================
  sistem ana kontrol kýsmý
 ==============================================================================}
procedure TYonetim.SistemAnaKontrol;
const
  PingHedefIP6Adres: TIP6Adres = (
    $fe, $80, $00, $00, $00, $00, $00, $00, $41, $02, $05, $a3, $ba, $0a, $ed, $02);
  PingHedefMACAdres: TMACAdres = ($02, $00, $4c, $4f, $4f, $50);
var
  TusDegeri: TSayi2;
  TusKontrolDegeri: TSayi1;
  TusKarakterDegeri: char;
  TusDurum: TTusDurum;
  i: TSayi4;
  Masaustu: TMasaustu;
  GN: PGorselNesne;
  Olay: TOlay;
  MD: TMDNesne;
  G: PGorev;
  DosyaKimlik: TKimlik;
  Durum: Boolean;
  FD: TFDAygiti;
  //T: TMyThread;
  //T2: TMyThread2;
  PingSiraNo: TSayi4 = 111;
  p: PChar;
  B, B2: TBaglanti;
  Bag: TAgBaglantisi;
begin

  i := 100;

  // masaüstü aktif olana kadar bekle
  while GGNesneler.AktifMasaustu = nil do;

  // çekirdek deðiþim kontrol için cekirdek.bin dosyasýnýn yüklenme aþamasýndaki
  // tarih + saat deðerlerini kaydet
  CekirdekDosyaTSDegeriniKaydet;

  KaydedilenProgramlariYenidenYukle;

  GKlavye.FSistemTusDurumuKontrolSol := tdYok;
  GKlavye.FSistemTusDurumuKontrolSag := tdYok;
  GKlavye.FSistemTusDurumuAltSol := tdYok;
  GKlavye.FSistemTusDurumuAltSag := tdYok;
  GKlavye.FSistemTusDurumuDegisimSol := tdYok;
  GKlavye.FSistemTusDurumuDegisimSag := tdYok;

  {GArge := TArGe.Create(2);
  GArge.Calistir;}

  while True do
  begin

    // sistem sayacýný artýr
    Inc(GSistem.FSistemSayaci);

    // klavyeden basýlan tuþu al
    // 2 bytelýk TusDegeri deðiþken deðerinin üst byte'ý kontrol deðeri, alt byte'ý ise karakter deðeridir
    TusDurum := GKlavye.KlavyedenTusAl(TusDegeri);
    TusKontrolDegeri := (TusDegeri shr 8);
    TusKarakterDegeri := Char(TusDegeri and $FF);

    if(TusDegeri <> 0) then
    begin

      if(TusDurum = tdBasildi) then
      begin

        //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Basýlan Tuþ Deðeri: %x', [TusDegeri]);

        if(TusDegeri = TUS_KONTROL_SOL) then
          GKlavye.FSistemTusDurumuKontrolSol := tdBasildi
        else if(TusDegeri = TUS_KONTROL_SAG) then
          GKlavye.FSistemTusDurumuKontrolSag := tdBasildi
        else if(TusDegeri = TUS_ALT_SOL) then
          GKlavye.FSistemTusDurumuAltSol := tdBasildi
        else if(TusDegeri = TUS_ALT_SAG) then
          GKlavye.FSistemTusDurumuAltSag := tdBasildi
        else if(TusDegeri = TUS_DEGISIM_SOL) then
          GKlavye.FSistemTusDurumuDegisimSol := tdBasildi
        else if(TusDegeri = TUS_DEGISIM_SAG) then
          GKlavye.FSistemTusDurumuDegisimSag := tdBasildi;

        if(GKlavye.FSistemTusDurumuKontrolSol = tdBasildi) or
          (GKlavye.FSistemTusDurumuKontrolSag = tdBasildi) then
        begin

          // DHCP sunucusundan IP adresi al
          // bilgi: agbilgi.c programýnýn seçeneðine baðlýdýr
          if(TusKarakterDegeri = '2') then
          begin

            if(GAygitlar.ToplamAgAygitSayisi > 0) then
            begin

              GAgBaglantilari.AktifBaglanti.IP4AdresiAlindi := False;
              GDHCPv4i.IpAdresiAl;
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

            //DosyalariKopyala;

            DosyaKopyala('disk1:\progrmlr\dskbolum.c', 'disk2:\dskbolum.c');

            {if(GBaglantilar.BaglantiSayisi > 0) then
            begin

              for i := 0 to GBaglantilar.BaglantiSayisi - 1 do
              begin

                Bag := GBaglantilar.Baglanti0[i];

                SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Bað: %d', [i + 1]);
                SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Ad: %s', [Bag.Ad]);
                SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Ad: %d', [Bag.FSiraNo]);
              end;
            end;}

            //GAygitlar.Aygit[0].FVeriGonder(nil, i);
            {asm int 2; end;}

            {GAg.IPAdresiAlindi := False;
            DHCPIpAdresiAl;}



            //SistemKlasorleriniOlustur;
            //vbox.Listele;
            //KomsuIstegiGonder(PingHedefIP6Adres);

            //GGorevler.Calistir('disket1:\mustudk.c', CALISMA_SEVIYE3)

            //DosyaKopyala('disk1:\progrmlr\dskbolum.c', 'disk2:\dskbolum.c');

            //AssertErrorProc := @AssertIslev;
            //Assert(1 > 2, 'Merhaba');

            //for i := 1 to 100 do CreateDir('disk2:\merhaba\mer' + IntToStr(i));
            //DosyalariKopyala;
            //DosyaKopyala('disk1:\progrmlr\dskbolum.c', 'disk2:\dskbolum.c');

            //vbox.Listele;
          end
          // test iþlev tuþu-1
          else if(TusKarakterDegeri = '4') then
          begin

            //SistemKlasorleriniSil;
            //IstekMesajiGonder6;

            {PingMesajiGonder(ICMP6_PING_ISTEK, PingHedefIP6Adres, PingHedefMACAdres,
              PingSiraNo, @PingVeri[1], 32);
            Inc(PingSiraNo);}

            //GGorevler.Calistir('disk1:\dskgor.c', CALISMA_SEVIYE3)
            //elr1.SistemKlasorleriniSil;

            //iiiii := Align(SizeOf(TIzgara) + 64, 16);
            //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'U: %d', [iiiii]);

            //vbox.IcerigiGoruntule;
          end
          // test iþlev tuþu-2
          else if(TusKarakterDegeri = '5') then
          begin

            MD := GMantiksalDepolama.SurucuAl('disk2');
            if not(MD = nil) then ELR1DiskBicimle(MD);
          end
          // program çalýþtýrma programýný çalýþtýr
          else if(TusKarakterDegeri = 'c') then

            GGorevler.Calistir('calistir.c', CALISMA_SEVIYE3)

          // dosya yöneticisi programýný çalýþtýr
          else if(TusKarakterDegeri = 'd') then

            GGorevler.Calistir('dsyyntcs.c', CALISMA_SEVIYE3)

          // görev yöneticisi programýný çalýþtýr
          else if(TusKarakterDegeri = 'g') then

            //GGorevler.Calistir('yzmcgor2.c', CALISMA_SEVIYE3)
            GGorevler.Calistir('grvyntcs.c', CALISMA_SEVIYE3)

          // giriþ kutusundaki veriyi panoya kopyala
          else if(TusKarakterDegeri = 'k') then
          begin

            if(GGNesneler.AktifPencere <> nil) then
            begin

              GN := PGorselNesne(GGNesneler.AktifPencere.FAktifNesne);
              if(GN <> nil) and (GN^.NesneTipi = gntGirisKutusu) then
              begin

                PanoDegeri := GN^.Baslik;
              end;
            end;
          end

          // mesaj görüntüleme programýný çalýþtýr
          else if(TusKarakterDegeri = 'm') then

            GGorevler.Calistir('smsjgor.c', CALISMA_SEVIYE3)

          // resim görüntüleme programýný çalýþtýr
          else if(TusKarakterDegeri = 'r') then

            GGorevler.Calistir('resimgor.c', CALISMA_SEVIYE3)

          // panodaki veriyi giriþ kutusuna yapýþtýr
          else if(TusKarakterDegeri = 'y') then
          begin

            if(GGNesneler.AktifPencere <> nil) then
            begin

              GN := PGorselNesne(GGNesneler.AktifPencere.FAktifNesne);
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
            Masaustu := GGNesneler.Masaustleri[i];
            if not(Masaustu = nil) then
            begin

              // masaüstünü aktif olarak iþaretle
              GGNesneler.AktifMasaustu := Masaustu;
              GGNesneler.AktifMasaustu.Aktiflestir;

              // masaüstünü çiz
              GGNesneler.AktifMasaustu.Ciz;
            end;
          end;
        end
        else if(GKlavye.FSistemTusDurumuAltSol = tdBasildi) or (GKlavye.FSistemTusDurumuAltSag = tdBasildi) then
        begin

          // aktif uygulamaya kendisini kapatma mesajý gönder
          if(TusDegeri = TUS_F4) then
          begin

            Olay.Kimlik := GGNesneler.AktifPencere.Kimlik;
            Olay.Olay := CO_SONLANDIR;
            Olay.Deger1 := 0;
            Olay.Deger2 := 0;
            if not(GGNesneler.AktifPencere.OlayYonlAdr = nil) then
              GGNesneler.AktifPencere.OlayYonlAdr(GGNesneler.AktifPencere, Olay)
            else GGorevler.OlayEkle(GGNesneler.AktifPencere.GrvKimlik, Olay);
          end;
        end
        else
        begin

          //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Basýlan Tuþ: %d', [TusDegeri]);

          // klavye olaylarýný iþle
          // kontrol tuþu haricinde basýlan tüm tuþlarý ilgili uygulamaya yönlendir

          { TODO - burada kontrol tuþlarý ve karakter tuþlarý ayrý ayrý deðerlendirilerek
            farklý olaylar olarak uygulamalara gönderilecek }
          //if((TusDegeri and $FF00) = 0) then
            GOlayYonetim.KlavyeOlaylariniIsle(TusDegeri, TusDurum);
        end;
      end
      else if(TusDurum = tdBirakildi) then
      begin

        if(TusDegeri = TUS_KONTROL_SOL) then
          GKlavye.FSistemTusDurumuKontrolSol := tdBirakildi
        else if(TusDegeri = TUS_KONTROL_SAG) then
          GKlavye.FSistemTusDurumuKontrolSag := tdBirakildi
        else if(TusDegeri = TUS_ALT_SOL) then
          GKlavye.FSistemTusDurumuAltSol := tdBirakildi
        else if(TusDegeri = TUS_ALT_SAG) then
          GKlavye.FSistemTusDurumuAltSag := tdBirakildi
        else if(TusDegeri = TUS_DEGISIM_SOL) then
          GKlavye.FSistemTusDurumuDegisimSol := tdBirakildi
        else if(TusDegeri = TUS_DEGISIM_SAG) then
          GKlavye.FSistemTusDurumuDegisimSag := tdBirakildi;
      end;
    end;

    if(GAgBaglantilari <> nil) and (GAgBaglantilari.AgBaglantiSayisi > 0) then
      GAgBaglantilari.AktifBaglanti.VeriAlmaIslevi;

    // fare olaylarýný iþle
    GOlayYonetim.FareOlaylariniIsle;

    // disket sürücü motorunun aktifliðini kontrol eder, gerekirse motoru kapatýr
    DisketSurucuMotorunuKontrolEt;

    // sonlandýrýlmýþ olarak iþaretlenen görevleri sonlandýr
    IsaretlenenGorevleriSonlandir;
  end;
end;

// sistemin yüklenme esnasýnda çekirdeðin tarih + saat deðerini kaydeder
procedure TYonetim.CekirdekDosyaTSDegeriniKaydet;
var
  i: TISayi4;
  AramaKaydi: TDosyaArama;
  j: TSayi2;
begin

  i := FindFirst('disket1:\*.*', 0, AramaKaydi);
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

    i := FindNext(AramaKaydi);
  end;

  FindClose(AramaKaydi);
end;

procedure TYonetim.KaydedilenProgramlariYenidenYukle;
var
  GN: TGorselNesne;
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
    Bellek0 := GetMem(U);

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

          {SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Dosya Adý: "%s"', [DosyaAdi]);
          SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Sol: "%d, Üst: %d"', [Sol, Ust]);
          SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Geniþlik: "%d, Yükseklik: %d"', [Genislik, Yukseklik]);}

          MUGorev := GGorevler.Calistir(AcilisSurucuAygiti + ':\progrmlr\' + DosyaAdi, CALISMA_SEVIYE3);

          GZamanlayicilar.BekleMS(CALISMA_FREKANSI div 2);

          GN := GGNesneler.NesneAl(TPencere(MUGorev^.AktifPencere).Kimlik);

          TPencere(GN).FAtananAlan.Sol := Konum.Sol;
          TPencere(GN).FAtananAlan.Ust := Konum.Ust;
          TPencere(GN).FAtananAlan.Genislik := Boyut.Genislik;
          TPencere(GN).FAtananAlan.Yukseklik := Boyut.Yukseklik;
          TPencere(GN).Guncelle;

          TMasaustu(GN.AtaNesne).Ciz;
        end;
      end;
    until i = 0;

    FreeMem(Bellek0, U);
  end;

  CloseFile(DosyaKimlik);
end;

procedure TYonetim.AssertIslev(const msg,fname:ShortString;lineno:longint;erroraddr:pointer);
begin

  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Assert: %s', [msg]);
end;

end.
