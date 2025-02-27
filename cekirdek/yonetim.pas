{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: yonetim.pas
  Dosya Ýþlevi: sistem ana yönetim / kontrol kýsmý

  Güncelleme Tarihi: 26/02/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit yonetim;

interface

uses paylasim, gn_pencere, gn_etiket, zamanlayici, dns, gn_panel, gorselnesne,
  gn_gucdugmesi, gn_resim, gn_karmaliste, gn_degerlistesi, gn_dugme, gn_izgara,
  gn_araccubugu, gn_durumcubugu, gn_giriskutusu, gn_onaykutusu, gn_sayfakontrol,
  gn_defter, gn_kaydirmacubugu, islemci, pic, arp, dosya, src_pcnet32, bolumleme,
  gn_listekutusu;

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

type
  TTestSinif = class(TObject)
  public
    FDeger1: TSayi4;
    constructor Create;
    procedure Artir;
    procedure Eksilt;
  end;

type
  TArgeProgram = procedure of object;

type
  TArGe = object
  private
    P1Dugmeler: array[0..44] of PGucDugmesi;
  public
    TestSinif: TTestSinif;
    GorevNo: TISayi4;
    Panel: PPanel;
    BulunanCiftSayisi, TiklamaSayisi,
    SecilenEtiket, ToplamTiklamaSayisi: TSayi4;
    FCalisanBirim: TArgeProgram;
    P3SayfaKontrol: PSayfaKontrol;
    FSeciliYil, FSeciliAy: TISayi4;
    BuAy, BuYil: TSayi2;
    procedure Olustur;
    procedure Program1Basla;
    procedure Program2Basla;
    procedure P1NesneTestOlayIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    procedure P2NesneTestOlayIsle(AGonderici: PGorselNesne; AOlay: TOlay);
  end;

var
  P1Zamanlayici: PZamanlayici;
  P1Pencere, P2Pencere, P3Pencere: PPencere;
  P2DurumCubugu: PDurumCubugu;
  P2AracCubugu: PAracCubugu;
  P4Panel: PPanel;
  P4Dugme: PDugme;
  P4GucDugmesi: PGucDugmesi;
  P4Etiket: PEtiket;
  P4GirisKutusu: PGirisKutusu;
  P4Defter: PDefter;
  P4OnayKutusu: POnayKutusu;
  P4KaydirmaCubugu: PKaydirmaCubugu;
  P4ListeKutusu: PListeKutusu;
  P4KarmaListe: PKarmaListe;
  P2ACDugmeler: array[0..11] of TKimlik;
  P1Panel: PPanel;
  P1KarmaListe: PKarmaListe;
  P1Dugme: PDugme;
  P1DegerListesi: PDegerListesi;
  P3Panel: array[0..1] of PPanel;
  P3Dugme: array[0..1] of PDugme;
  GNEtiket: PEtiket;
  Resim: PResim;
  _DNS: PDNS = nil;
  DugmeSayisi: TSayi4;
  TestAlani: TArGe;
  SonKonumY, SonKonumD, SonSecim: TSayi4;
  TestAdres: Isaretci;

  sssss: string;
  ppppp: pchar;
  TestSinif: TTestSinif;
  xyz: PSayi4;

procedure Yukle;
procedure SistemAnaKontrol;
procedure CekirdekDosyaTSDegeriniKaydet;
procedure KaydedilenProgramlariYenidenYukle;
function GMem(Size:ptruint):Pointer;

implementation

uses gdt, gorev, src_klavye, genel, ag, dhcp, sistemmesaj, src_vesa20, cmos,
  gn_masaustu, donusum, gn_islevler, giysi_normal, giysi_mac, depolama, src_disket,
  vbox, usb, ohci, port, gn_islemgostergesi, prg_cagri, prg_grafik, prg_kontrol;

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
  GEkranKartSurucusu.KartBilgisi.BellekAdresi := GMBilgi^.VideoBellekAdresi; //VIDEO_MEM_ADDR;
  GEkranKartSurucusu.KartBilgisi.PixelBasinaBitSayisi := GMBilgi^.VideoPixelBasinaBitSayisi;
  GEkranKartSurucusu.KartBilgisi.NoktaBasinaByteSayisi := (GMBilgi^.VideoPixelBasinaBitSayisi div 8);
  GEkranKartSurucusu.KartBilgisi.SatirdakiByteSayisi := GMBilgi^.VideoSatirdakiByteSayisi;

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

  Olay := POlay(GGercekBellek.Ayir(4095));
  if not(Olay = nil) then
  begin

    Gorev^.FOlayBellekAdresi := Olay;
  end else Gorev^.FOlayBellekAdresi := nil;

  Gorev^.DurumDegistir(0, gdCalisiyor);

  // çalýþan ve oluþturulan görev deðerlerini belirle
  CalisanGorevSayisi := 1;
  CalisanGorev := 0;

  // ilk TSS'yi yükle
  // not : tss'nin yükleme iþlevi görev geçiþini gerçekleþtirmez. sadece
  // TSS'yi meþgul olarak ayarlar.
  asm
    mov   ax,SECICI_SISTEM_TSS * 8;
    ltr   ax
  end;

  // program çaðrýlarýna yanýt verecek görevi oluþtur
  CagriYanitlayiciyiOlustur;

  // grafik iþlevlerini yönetecek görevi oluþtur
  GrafikYoneticiGorevOlustur;

  // sistem kontrol görevi oluþtur
  SistemKontrolGoreviOlustur;
end;

{==============================================================================
  sistem ana kontrol kýsmý
 ==============================================================================}
procedure SistemAnaKontrol;
var
  Gorev: PGorev = nil;
  Tus2: TSayi2;
  Kontrol: TSayi1;
  Tus: Char;
  TusDurum: TTusDurum;
  i: Integer;
  m: TMemoryManager;
  Masaustu: PMasaustu;
  GN: PGorselNesne;
  FD: TFizikselDepolama;
begin

  // masaüstü uygulamasýnýn çalýþmasýný tamamlamasýný bekle
  BekleMS(100);

  // çekirdek deðiþim kontrol için cekirdek.bin dosyasýnýn yðklenme aþamasýndaki
  // tarih + saat deðerlerini kaydet
  CekirdekDosyaTSDegeriniKaydet;

  KaydedilenProgramlariYenidenYukle;

  SolKontrolTusDurumu := tdYok;
  SagKontrolTusDurumu := tdYok;
  SolAltTusDurumu := tdYok;
  SagAltTusDurumu := tdYok;
  SolDegisimTusDurumu := tdYok;
  SagDegisimTusDurumu := tdYok;

  // masaüstü aktif olana kadar bekle
  while GAktifMasaustu = nil do;

  // sistem deðer görüntüleyicisini baþlat
  SistemDegerleriBasla;

  {TestAlani.Olustur;
  if not(TestAlani.FCalisanBirim = nil) then TestAlani.FCalisanBirim;}

  // sistem için DHCP sunucusundan IP adresi al
  if(AgYuklendi) and (GAgBilgisi.IPAdresiAlindi = False) then DHCPIpAdresiAl;

  while True do
  begin

    // sistem sayacýný artýr
    Inc(SistemSayaci);

    // klavyeden basýlan tuþu al
    // 2 bytelýk Tus deðerinin üst byte'ý kontrol deðeri, alt byte'ý ise karakter deðeridir
    TusDurum := KlavyedenTusAl(Tus2);
    Kontrol := (Tus2 shr 8);
    Tus := Char(Tus2 and $FF);
    if(TusDurum = tdBasildi) and (Tus <> #0) then
    begin

      //SISTEM_MESAJ(RENK_KIRMIZI, 'Basýlan Tuþ Deðeri: %d', [Ord(Tus)]);
      //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Basýlan Tuþ: %d', [Ord(Tus)]);

      if(SolKontrolTusDurumu = tdBasildi) or (SagKontrolTusDurumu = tdBasildi) then
      begin

        // DHCP sunucusundan IP adresi al
        // bilgi: agbilgi.c programýnýn seçeneðine baðlýdýr
        if(Tus = '2') then
        begin

          if(AgYuklendi) then
          begin

            // að bilgileri öndeðerlerle yükleniyor
            IlkAdresDegerleriniYukle;

            DHCPIpAdresiAl;
          end
          else
          begin

            SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'Að yüklü olmadýðý için DHCP''den IP adresi alýnamýyor!', []);
          end;
        end
        // test amaçlý
        else if(Tus = '3') then
        begin

{          SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'PCNET32-Deðer: %s', [GeciciDeger]);

          SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'PCNET32-TemelAdres: %x', [AygitPCNet32.TemelAdres]);
          SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'PCNET32-Yol: %d', [AygitPCNet32.Yol]);
          SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'PCNET32-Aygit: %d', [AygitPCNet32.Aygit]);
          SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'PCNET32-Islev: %d', [AygitPCNet32.Islev]);
}

          //Gorev^.Calistir('disket1:\mustudk.c');
          //Gorev^.Calistir('disk1:\sisbilgi.c');
          //Gorev^.Calistir('disket1:\yzmcgor2.c');
          //vbox.Listele;

          //TestAdres := Isaretci($10000);
          //SISTEM_MESAJ(RENK_KIRMIZI, 'Bellek U3: %d', [TSayi4(TestAdres)]);

          //TestSinif := TTestSinif.Create;



          {DosyaAdi := 'disk1:\harfler.txt';
          dosya.AssignFile(DosyaKimlik, DosyaAdi);
          dosya.Reset(DosyaKimlik);

          DosyaUzunluk := dosya.FileSize(DosyaKimlik);

          //if(DosyaUzunluk <= DOSYA_BELLEK_KAPASITESI) then
          begin

            //_IOResult;

            //_EOF(DosyaKimlik);

            dosya.Read(DosyaKimlik, Isaretci($3000000));
          end;

          dosya.CloseFile(DosyaKimlik); }
        end
        // test iþlev tuþu-1
        else if(Tus = '4') then
        begin

          //Gorev^.Calistir('disk1:\progrmlr\saat.c');
          //iiiii := Align(SizeOf(TIzgara) + 64, 16);
          //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'U: %d', [iiiii]);



{          pic.Maskele(0);
          IRR := pic.ISRDegeriniOku;
          SISTEM_MESAJ2_S16(RENK_KIRMIZI, 'IRR Deðeri: ', IRR, 4);
}

          //BekleMS(10000);

//          pic.MaskeKaldir(0);

          // aþaðýdaki programlar üzerinden fdc iþlemleri tamamlanacak
          //Gorev^.Calistir('disket1:\kopyala.c');
          //Gorev^.Calistir('disket1:\dskgor.c');

          //BellekI := GGercekBellek.Ayir(4095);
          //SISTEM_MESAJ2_S16(RENK_KIRMIZI, 'Bellek: ', TSayi4(BellekI), 8);
          //SISTEM_MESAJ(RENK_KIRMIZI, 'Bellek: %x', [GGercekBellek.ToplamRAM]);
          //vbox.IcerigiGoruntule;
          //TestSinif.Artir;
          //Gorev^.Calistir('disk1:\arpbilgi.c');

          {Disk := SurucuAl('disk2:');
          SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Disk2-1: %d', [Disk^.Acilis.DizinGirisi.IlkSektor]);
          SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Disk2-2: %d', [Disk^.Acilis.DizinGirisi.ToplamSektor]);}
        end
        // test iþlev tuþu-2
        else if(Tus = '5') then
        begin

          GetMemoryManager(m);
          m.Getmem := @GMem;
          {if(m.Getmem = nil) then
            SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'nil', [])
          else SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, '!nil', []);}
          m.GetMem(1000);

          //Getmem(TestAdres, 100);

          //new(xyz);
          //IRR := pic.ISRDegeriniOku;
          //SISTEM_MESAJ2_S16(RENK_KIRMIZI, 'IRR Deðeri: ', IRR, 4);
        end
        // program çalýþtýrma programýný çalýþtýr
        else if(Tus = 'c') then

          //ohci.Kontrol1
          Gorev^.Calistir('calistir.c')

        // dosya yöneticisi programýný çalýþtýr
        else if(Tus = 'd') then

          Gorev^.Calistir('dsyyntcs.c')

        // görev yöneticisi programýný çalýþtýr
        else if(Tus = 'g') then

          Gorev^.Calistir('grvyntcs.c')

        // bilgisayarý kapat
        else if(Tus = 'k') then
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
        else if(Tus = 'm') then

          Gorev^.Calistir('smsjgor.c')

        // resim görüntüleme programýný çalýþtýr
        else if(Tus = 'r') then

          Gorev^.Calistir('resimgor.c')

        // bilgisayarý yeniden baþlat
        else if(Tus = 'y') then
        begin

          if(GAktifPencere <> nil) then
          begin

            GN := GAktifPencere^.FAktifNesne;
            if(GN <> nil) and (GN^.NesneTipi = gntGirisKutusu) then
            begin

              if(Length(PanoDegeri) > 0) then GN^.Baslik := PanoDegeri;
            end;
          end;
        end
        else if(Tus >= TUS_F1) and (Tus <= TUS_F4) then
        begin

          i := (Ord(Tus) - Ord(TUS_F1)) + 1;

          //SISTEM_MESAJ(mtBilgi, RENK_YESIL, 'Aktif Masaüstü: %d', [i])

          // aktif masaüstünü deðiþtir
          Masaustu := GMasaustuListesi[i - 1];
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
      else
      begin

        // klavye olaylarýný iþle
        GOlayYonetim.KlavyeOlaylariniIsle(Tus);
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

function GMem(Size: ptruint): Pointer;
begin

  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'GetMem', []);
end;

constructor TTestSinif.Create;
begin

  FDeger1 := 100;;
end;

procedure TTestSinif.Artir;
begin

  Inc(FDeger1);
  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'TTest1.Artir: %d', [FDeger1]);
  //SISTEM_MESAJ_YAZI(mtBilgi, RENK_SIYAH, 'Birim: ', UnitName);
end;

procedure TTestSinif.Eksilt;
begin

  Dec(FDeger1);
  SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'TTestSinif.Eksilt: %d', [FDeger1]);
end;

procedure TArGe.Olustur;
begin

  FCalisanBirim := @Program2Basla;
end;

procedure TArGe.Program1Basla;
var
  P1Masaustu: PMasaustu = nil;
begin

  P1Masaustu := P1Masaustu^.Olustur('giriþ');
  P1Masaustu^.MasaustuRenginiDegistir($9FB6BF);
  //P1Masaustu^.Aktiflestir;

  P1Pencere := P1Pencere^.Olustur(P1Masaustu, 100, 100, 500, 400, ptBoyutlanabilir,
    'Görsel Nesne Yönetim', RENK_BEYAZ);
  P1Pencere^.OlayYonlendirmeAdresi := @P1NesneTestOlayIsle;

  P1Dugmeler[0] := P1Dugmeler[0]^.Olustur(ktNesne, P1Pencere,
    10, 10, 100, 100, 'Artýr');
  P1Dugmeler[0]^.OlayYonlendirmeAdresi := @P1NesneTestOlayIsle;
  P1Dugmeler[0]^.Goster;

  P1Dugmeler[1] := P1Dugmeler[1]^.Olustur(ktNesne, P1Pencere,
    120, 10, 100, 100, 'Eksilt');
  P1Dugmeler[1]^.OlayYonlendirmeAdresi := @P1NesneTestOlayIsle;
  P1Dugmeler[1]^.Goster;

//  TestSinif := TTestSinif.Create;
//  TestSinif.FDeger1 := 10;

  P1Pencere^.Goster;

  P1Masaustu^.Gorunum := True;
end;

procedure TArGe.P1NesneTestOlayIsle(AGonderici: PGorselNesne; AOlay: TOlay);
begin

end;

procedure TArGe.Program2Basla;
begin

  SonSecim := 0;

  P2Pencere := P2Pencere^.Olustur(nil, 0, 0, 450, 300, ptBoyutlanabilir,
    'Nesneler', RENK_BEYAZ);
  P2Pencere^.OlayYonlendirmeAdresi := @P2NesneTestOlayIsle;

  P2AracCubugu := P2AracCubugu^.Olustur(ktNesne, P2Pencere);
  P2ACDugmeler[0] := P2AracCubugu^.DugmeEkle2(0);
  P2ACDugmeler[1] := P2AracCubugu^.DugmeEkle2(11);
  P2ACDugmeler[2] := P2AracCubugu^.DugmeEkle2(2);
  P2ACDugmeler[3] := P2AracCubugu^.DugmeEkle2(6);
  P2ACDugmeler[4] := P2AracCubugu^.DugmeEkle2(3);
  P2ACDugmeler[5] := P2AracCubugu^.DugmeEkle2(4);
  P2ACDugmeler[6] := P2AracCubugu^.DugmeEkle2(5);
  P2ACDugmeler[7] := P2AracCubugu^.DugmeEkle2(7);
  P2ACDugmeler[8] := P2AracCubugu^.DugmeEkle2(10);
  P2ACDugmeler[9] := P2AracCubugu^.DugmeEkle2(8);
  P2ACDugmeler[10] := P2AracCubugu^.DugmeEkle2(9);
  P2AracCubugu^.OlayYonlendirmeAdresi := @P2NesneTestOlayIsle;
  P2AracCubugu^.Goster;

  P2DurumCubugu := P2DurumCubugu^.Olustur(ktNesne, P2Pencere, 0, 0, 10, 10, 'Konum: 0:0');
  P2DurumCubugu^.OlayYonlendirmeAdresi := @P2NesneTestOlayIsle;
  P2DurumCubugu^.Goster;

  P2Pencere^.Goster;
end;

procedure TArGe.P2NesneTestOlayIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Sol, Ust, G, Y, i: TISayi4;
  Alan: TAlan;
  s: string;
begin

  if(AOlay.Olay = CO_CIZIM) then
  begin

    G := AGonderici^.FBoyut.Genislik;
    Y := AGonderici^.FBoyut.Yukseklik - 28;

    // yatay çizgiler
    Ust := 5 + 28;
    repeat

      Alan := P2Pencere^.FKalinlik;
      for i := 0 to G div 10 do P2Pencere^.PixelYaz(P2Pencere, Alan.Sol + (i * 10) + 3,
        Alan.Ust + Ust, RENK_GRI);
      Inc(Ust, 10);
    until Ust > Y;
  end
  else if(AOlay.Olay = FO_HAREKET) and (AOlay.Kimlik = P2Pencere^.Kimlik) then
  begin

    SonKonumY := AOlay.Deger1 - P2Pencere^.FKalinlik.Sol;
    SonKonumD := AOlay.Deger2 - P2Pencere^.FKalinlik.Ust;

    case SonSecim of
      0: s := '-';
      1: s := 'TPanel';
      2: s := 'TDüðme';
      3: s := 'TGucDugmesi';
      4: s := 'TEtiket';
      5: s := 'TGiriþKutusu';
      6: s := 'TDefter';
      7: s := 'TOnayKutusu';
      8: s := 'TKaydýrmaÇubuðu';
      9: s := 'TListeKutusu';
     10: s := 'TKarmaListe';
    end;

    P2DurumCubugu^.Baslik := 'Konum: ' + IntToStr(AOlay.Deger1) + ':' +
      IntToStr(AOlay.Deger2) + ' - Seçili Nesne: ' + s;
    P2DurumCubugu^.Ciz;
  end
  else if(AOlay.Olay = FO_SAGTUS_BIRAKILDI) and (AOlay.Kimlik = P2Pencere^.Kimlik) then
  begin

    if(SonSecim = 1) then
    begin

      P4Panel := P4Panel^.Olustur(ktNesne, P2Pencere, SonKonumY, SonKonumD, 50, 50,
        3, RENK_KIRMIZI, RENK_BEYAZ, RENK_SIYAH, 'TPanel');
      P4Panel^.Goster;
    end
    else if(SonSecim = 2) then
    begin

      P4Dugme := P4Dugme^.Olustur(ktNesne, P2Pencere, SonKonumY, SonKonumD, 100, 20, 'TDüðme');
      P4Dugme^.Goster;
    end
    else if(SonSecim = 3) then
    begin

      P4GucDugmesi := P4GucDugmesi^.Olustur(ktNesne, P2Pencere, SonKonumY, SonKonumD,
        100, 20, 'TGüçDüðmesi');
      P4GucDugmesi^.Goster;
    end
    else if(SonSecim = 4) then
    begin

      P4Etiket := P4Etiket^.Olustur(ktNesne, P2Pencere, SonKonumY, SonKonumD, 30, 16,
        RENK_SIYAH, 'TEtiket');
      P4Etiket^.Goster;
    end
    else if(SonSecim = 5) then
    begin

      P4GirisKutusu := P4GirisKutusu^.Olustur(ktNesne, P2Pencere, SonKonumY, SonKonumD,
        120, 20, 'TGiriþKutusu');
      P4GirisKutusu^.Goster;
    end
    else if(SonSecim = 6) then
    begin

      P4Defter := P4Defter^.Olustur(ktNesne, P2Pencere, SonKonumY, SonKonumD, 200, 200,
        $FCFCFC, RENK_SIYAH, False);
      P4Defter^.YaziEkle('TDefter');
      P4Defter^.Goster;
    end
    else if(SonSecim = 7) then
    begin

      P4OnayKutusu := P4OnayKutusu^.Olustur(ktNesne, P2Pencere, SonKonumY, SonKonumD,
        'TOnayKutusu');
      P4OnayKutusu^.Goster;
    end
    else if(SonSecim = 8) then
    begin

      P4KaydirmaCubugu := P4KaydirmaCubugu^.Olustur(ktNesne, P2Pencere, SonKonumY, SonKonumD,
        100, 24, yYatay);
      P4KaydirmaCubugu^.DegerleriBelirle(0, 100);
      P4KaydirmaCubugu^.FMevcutDeger := 50;
      P4KaydirmaCubugu^.Goster;
    end
    else if(SonSecim = 9) then
    begin

      P4ListeKutusu := P4ListeKutusu^.Olustur(ktNesne, P2Pencere, SonKonumY, SonKonumD, 100, 60);
      P4ListeKutusu^.ListeyeEkle('TListeKutusu');
      P4ListeKutusu^.ListeyeEkle('Eleman1');
      P4ListeKutusu^.ListeyeEkle('Eleman2');
      P4ListeKutusu^.SeciliSiraNoYaz(0);
      P4ListeKutusu^.Goster;
    end
    else if(SonSecim = 10) then
    begin

      P4KarmaListe := P4KarmaListe^.Olustur(ktNesne, P2Pencere, SonKonumY, SonKonumD, 100, 24);
      P4KarmaListe^.ListeyeEkle('TKarmaListe1');
      P4KarmaListe^.ListeyeEkle('Eleman1');
      P4KarmaListe^.ListeyeEkle('Eleman2');
      P4KarmaListe^.BaslikSiraNoYaz(0);
      P4KarmaListe^.Goster;
    end;
  end
  else if(AOlay.Olay = FO_TIKLAMA) then
  begin

    if(AOlay.Kimlik = P2ACDugmeler[0]) then
      SonSecim := 0
    else if(AOlay.Kimlik = P2ACDugmeler[1]) then
      SonSecim := 1
    else if(AOlay.Kimlik = P2ACDugmeler[2]) then
      SonSecim := 2
    else if(AOlay.Kimlik = P2ACDugmeler[3]) then
      SonSecim := 3
    else if(AOlay.Kimlik = P2ACDugmeler[4]) then
      SonSecim := 4
    else if(AOlay.Kimlik = P2ACDugmeler[5]) then
      SonSecim := 5
    else if(AOlay.Kimlik = P2ACDugmeler[6]) then
      SonSecim := 6
    else if(AOlay.Kimlik = P2ACDugmeler[7]) then
      SonSecim := 7
    else if(AOlay.Kimlik = P2ACDugmeler[8]) then
      SonSecim := 8
    else if(AOlay.Kimlik = P2ACDugmeler[9]) then
      SonSecim := 9
    else if(AOlay.Kimlik = P2ACDugmeler[10]) then
      SonSecim := 10;

    //SISTEM_MESAJ(RENK_SIYAH, 'Kimlik: %d', [AOlay.Kimlik]);
  end;
end;

// sistemin yüklenme esnasýnda çekirdeðin tarih + saat deðerini kaydeder
procedure CekirdekDosyaTSDegeriniKaydet;
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
    if(FD.Mevcut0) and (FD.FD3.SurucuTipi = SURUCUTIP_DISK) then
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
