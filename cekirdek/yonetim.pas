{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: yonetim.pas
  Dosya Ýþlevi: sistem ana yönetim / kontrol kýsmý

  Güncelleme Tarihi: 25/12/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit yonetim;

interface

uses paylasim, gn_pencere, gn_etiket, zamanlayici, dns, gn_panel, gorselnesne,
  gn_gucdugmesi, gn_resim, gn_karmaliste, gn_degerlistesi, gn_dugme, gn_izgara,
  gn_araccubugu, gn_durumcubugu, gn_giriskutusu, gn_onaykutusu, gn_sayfakontrol,
  gn_defter, gn_kaydirmacubugu, islemci, pic;

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

  { TArGe }

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
  SDPencere: PPencere = nil;
  SDZamanlayici, P1Zamanlayici: PZamanlayici;
  P1Pencere, P2Pencere, P3Pencere: PPencere;
  P2DurumCubugu: PDurumCubugu;
  P2AracCubugu: PAracCubugu;
  P4Dugme: PDugme;
  P3Etiket: PEtiket;
  P3GirisKutusu: PGirisKutusu;
  P3OnayKutusu: POnayKutusu;
  P3KaydirmaCubugu: PKaydirmaCubugu;
  P3Defter: PDefter;
  P2ACDugmeler: array[0..7] of TKimlik;
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

procedure Yukle;
procedure SistemAnaKontrol;
procedure CagriYanitlayiciyiOlustur;
procedure GrafikYoneticiGorevOlustur;
procedure ProgramCagrilariniYanitla;
procedure GrafikYonetimi;
procedure SistemDegerleriBasla;
procedure SistemDegerleriOlayIsle;

implementation

uses gdt, gorev, src_klavye, genel, ag, dhcp, sistemmesaj, src_vesa20, cmos,
  gn_masaustu, donusum, gn_islevler, giysi_normal, giysi_mac, depolama,
  src_disket, vbox, usb, ohci;

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
  FillByte(GorevTSSListesi[1]^, 104, $00);

  // TSS içeriðini doldur
  //GorevTSSListesi[1].CR3 := GERCEKBELLEK_DIZINADRESI;
  GorevTSSListesi[1]^.EIP := TSayi4(@SistemAnaKontrol);
  GorevTSSListesi[1]^.EFLAGS := $202;
  GorevTSSListesi[1]^.ESP := SISTEM_ESP;
  GorevTSSListesi[1]^.CS := SECICI_SISTEM_KOD * 8;
  GorevTSSListesi[1]^.DS := SECICI_SISTEM_VERI * 8;
  GorevTSSListesi[1]^.ES := SECICI_SISTEM_VERI * 8;
  GorevTSSListesi[1]^.SS := SECICI_SISTEM_VERI * 8;
  GorevTSSListesi[1]^.FS := SECICI_SISTEM_VERI * 8;
  GorevTSSListesi[1]^.GS := SECICI_SISTEM_VERI * 8;
  GorevTSSListesi[1]^.SS0 := SECICI_SISTEM_VERI * 8;

  // not: sistem için CS ve DS seçicileri bilden programý tarafýndan
  // oluþturuldu. tekrar oluþturmaya gerek yok

  // sistem için görev seçicisi (TSS)
  // Eriþim  : 1 = mevcut, 00 = DPL0, 010 = 32 bit kullanýlabilir TSS, 0 = meþgul biti (meþgul deðil), 1
  // Esneklik: 1 = gran = 1Byte çözünürlük, 00, 1 = bana tahsis edildi, 0000 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SECICI_SISTEM_TSS, TSayi4(GorevTSSListesi[1]), 104,
    %10001001, %00010000);

  // sistem görev deðerlerini belirle
  GorevListesi[1]^.GorevSayaci := 0;
  GorevListesi[1]^.BellekBaslangicAdresi := CekirdekBaslangicAdresi;
  GorevListesi[1]^.BellekUzunlugu := CekirdekUzunlugu;
  GorevListesi[1]^.OlaySayisi := 0;
  GorevListesi[1]^.OlayBellekAdresi := nil;
  GorevListesi[1]^.FAktifPencere := nil;

  GorevListesi[1]^.FDosyaAdi := 'cekirdek.bin';
  GorevListesi[1]^.FProgramAdi := 'Sistem Çekirdeði';

  // sistem görevini çalýþýyor olarak iþaretle
  Gorev := GorevListesi[1];
  Gorev^.OlaySayisi := 0;

  Olay := POlay(GGercekBellek.Ayir(4096));
  if not(Olay = nil) then
  begin

    Gorev^.FOlayBellekAdresi := Olay;
  end else Gorev^.FOlayBellekAdresi := nil;

  Gorev^.DurumDegistir(1, gdCalisiyor);

  // çalýþan ve oluþturulan görev deðerlerini belirle
  CalisanGorevSayisi := 1;
  CalisanGorev := CalisanGorevSayisi;

  // ilk TSS'yi yükle
  // not : tss'nin yükleme iþlevi görev geçiþini gerçekleþtirmez. sadece
  // TSS'yi meþgul olarak ayarlar.
  asm
    mov   ax, SECICI_SISTEM_TSS * 8;
    ltr   ax
  end;

  // program çaðrýlarýna yanýt verecek görevi oluþtur
  CagriYanitlayiciyiOlustur;

  // grafik iþlevlerini yönetecek görevi oluþtur
  GrafikYoneticiGorevOlustur;
end;

{==============================================================================
  sistem ana kontrol kýsmý
 ==============================================================================}
procedure SistemAnaKontrol;
const
  disketyaz: string = 'merhaba';
  veriler: array[0..19] of Byte = ($45, $00, $00, $3c, $fa, $b2, $40, $00, $40, $06, 0, 0,
  $0a, $00, $02, $0f, $c0, $a8, $01, $33);

var
  Gorev: PGorev = nil;
  Tus: Char;
  TusDurum: TTusDurum;
  AtaGorselNesne: PGorselNesne = nil;
  D1, D2, D3, i: Integer;
  G: PGorev;
  Z: TSayi4;
  fs: PFizikselSurucu3;
  IRR, zzz: TSayi2;
  _AygitSiraNo, AygitKimlik: TSayi4;
begin

{  if(CalisanGorevSayisi = 1) then
  repeat

    Gorev^.Calistir(AcilisSurucuAygiti + ':\' + OnDegerMasaustuProgram);
    ElleGorevDegistir;
  until CalisanGorevSayisi > 1;
}
  KONTROLTusDurumu := tdYok;
  ALTTusDurumu := tdYok;
  DEGISIMTusDurumu := tdYok;

  // masaüstü aktif olana kadar bekle
  while GAktifMasaustu = nil do;

  // sistem deðer görüntüleyicisini baþlat
  SistemDegerleriBasla;

  TestAlani.Olustur;

  if not(TestAlani.FCalisanBirim = nil) then TestAlani.FCalisanBirim;

  // sistem için DHCP sunucusundan IP adresi al
  if(AgYuklendi) and (GAgBilgisi.IPAdresiAlindi = False) then DHCPIpAdresiAl;

  while True do
  begin

    // sistem sayacýný artýr
    Inc(SistemSayaci);

    // klavyeden basýlan tuþu al
    TusDurum := KlavyedenTusAl(Tus);
    if(TusDurum = tdBasildi) and (Tus <> #0) then
    begin

      if(KONTROLTusDurumu = tdBasildi) then
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

            SISTEM_MESAJ(RENK_KIRMIZI, 'Að yüklü olmadýðý için DHCP''den IP adresi alýnamýyor!', []);
          end;
        end
        // test amaçlý
        else if(Tus = '3') then
        begin

          {if(iMTRR) then
            SISTEM_MESAJ(RENK_YESIL, 'MTRR Mevcut', [])
          else SISTEM_MESAJ(RENK_KIRMIZI, 'MTRR Yok', []);}
{
          SISTEM_MESAJ(RENK_KIRMIZI, 'FizikselDepolamaAygitSayisi: %d', [FizikselDepolamaAygitSayisi]);
          for i := 1 to FizikselDepolamaAygitSayisi do
          begin

            if(FizikselDepolamaAygitBilgisiAl(i, fs) > 0) then
            begin

              SISTEM_MESAJ(RENK_KIRMIZI, '%d. aygýt - ' + fs^.AygitAdi, [i]);
              SISTEM_MESAJ(RENK_KIRMIZI, 'Sürücü Tipi: %d', [fs^.SurucuTipi]);
            end;
          end;
}
          //Gorev^.Sonlandir(5, 6);

{          G := GorevListesi[3];

          //
          asm
          mov esi,GorevListesi[8]
          mov eax,[esi + TGorev.FBellekBaslangicAdresi]
          mov Z,eax
          end;

          SISTEM_MESAJ_S16(RENK_KIRMIZI, 'Bellek Adresi: ', G^.BellekBaslangicAdresi, 8);
          SISTEM_MESAJ_S16(RENK_KIRMIZI, 'Bellek Adresi: ', Z, 8);
}

          //SISTEM_MESAJ(RENK_SIYAH, 'Panel1 Alt NS: %d', [P3Panel[0]^.FAltNesneSayisi]);
          //SISTEM_MESAJ(RENK_SIYAH, 'Panel2 Alt NS: %d', [P3Panel[1]^.FAltNesneSayisi]);


          {i := FindFirst('disk1:\kaynak\*.*', 0, AramaKaydi);
          while i = 0 do
          begin

            SISTEM_MESAJ(RENK_SIYAH, 'Dosya: ' + AramaKaydi.DosyaAdi, []);
            i := FindNext(AramaKaydi);
          end;
          FindClose(AramaKaydi);}
          //Gorev^.Calistir('disk1:\6.bmp');
          //Gorev^.Calistir('disket1:\tarayici.c');

          zzz := SaglamaToplamiOlustur(@veriler[0], 20, nil, 0);
          SISTEM_MESAJ2_S16(RENK_KIRMIZI, 'Hex Deðer: ', zzz, 4);
        end
        // test iþlev tuþu-1
        else if(Tus = '4') then
        begin

{          pic.Maskele(0);
          IRR := pic.ISRDegeriniOku;
          SISTEM_MESAJ2_S16(RENK_KIRMIZI, 'IRR Deðeri: ', IRR, 4);
}

          //BekleMS(10000);

//          pic.MaskeKaldir(0);

          // aþaðýdaki programlar üzerinden fdc iþlemleri tamamlanacak
          //Gorev^.Calistir('disket1:\kopyala.c');
          //Gorev^.Calistir('disket1:\dskgor.c');
        end
        // test iþlev tuþu-2
        else if(Tus = '5') then
        begin

          AygitKimlik := 2;
          if(AygitKimlik > 0) and (AygitKimlik <= FizikselDepolamaAygitSayisi) then
          begin

            _AygitSiraNo := 0;
            for i := 1 to 6 do
            begin

              if(FizikselDepolamaAygitListesi[i].Mevcut) then Inc(_AygitSiraNo);

              if(_AygitSiraNo = AygitKimlik) then
              begin

                //SISTEM_MESAJ(RENK_KIRMIZI, 'IRR Deðeri: ' + FizikselDepolamaAygitListesi[i].AygitAdi, []);
                FizikselDepolamaAygitListesi[i].SektorYaz(@FizikselDepolamaAygitListesi[i], 1, 1, @disketyaz);
                Break;
              end;
            end;
          end;

          //IRR := pic.ISRDegeriniOku;
          //SISTEM_MESAJ2_S16(RENK_KIRMIZI, 'IRR Deðeri: ', IRR, 4);
        end
        // program çalýþtýrma programýný çalýþtýr
        else if(Tus = 'c') then

          //ohci.Kontrol1
          Gorev^.Calistir('disk1:\calistir.c')

        // dosya yöneticisi programýný çalýþtýr
        else if(Tus = 'd') then

          Gorev^.Calistir('disk1:\dsyyntcs.c')

        // görev yöneticisi programýný çalýþtýr
        else if(Tus = 'g') then

          Gorev^.Calistir('disk1:\grvyntcs.c')

        // mesaj görüntüleme programýný çalýþtýr
        else if(Tus = 'm') then

          Gorev^.Calistir('disk1:\smsjgor.c')

        // resim görüntüleme programýný çalýþtýr
        else if(Tus = 'r') then

          Gorev^.Calistir('disk1:\resimgor.c');
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
  end;
end;

{==============================================================================
  program çaðrýlarýna yanýt verecek görevi oluþturur
 ==============================================================================}
procedure CagriYanitlayiciyiOlustur;
var
  Gorev: PGorev;
begin

  // kod seçicisi (CS)
  // Eriþim  : 1 = mevcut, 00 = DPL0, 11 = kod yazmaç, 0 = dallanýlamaz, 1 = okunabilir, 0 = eriþilmedi
  // Esneklik: 1 = gran = 4K çözünürlük, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SECICI_CAGRI_KOD, 0, $FFFFFFFF, %10011010, %11011111);
  // veri seçicisi (DS)
  // Eriþim  : 1 = mevcut, 00 = DPL0, 10 = veri yazmaç, 0 = artarak büyüyen, 1 = yazýlabilir, 0 = eriþilmedi
  // Esneklik: 1 = gran = 4K çözünürlük, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SECICI_CAGRI_VERI, 0, $FFFFFFFF, %10010010, %11011111);
  // görev seçicisi (TSS)
  // Eriþim  : 1 = mevcut, 00 = DPL0, 010 = 32 bit kullanýlabilir TSS, 0 = meþgul biti (meþgul deðil), 1
  // Esneklik: 1 = gran = 1Byte çözünürlük, 00, 1 = bana tahsis edildi, 0000 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SECICI_CAGRI_TSS, TSayi4(GorevTSSListesi[2]), 104,
    %10001001, %00010000);

  // denetçinin kullanacaðý TSS'nin içeriðini sýfýrla
  FillByte(GorevTSSListesi[2]^, 104, $00);

  GorevTSSListesi[2]^.EIP := TSayi4(@ProgramCagrilariniYanitla);    // DPL 0
  GorevTSSListesi[2]^.EFLAGS := $202;
  GorevTSSListesi[2]^.ESP := CAGRI_ESP;
  GorevTSSListesi[2]^.CS := SECICI_CAGRI_KOD * 8;
  GorevTSSListesi[2]^.DS := SECICI_CAGRI_VERI * 8;
  GorevTSSListesi[2]^.ES := SECICI_CAGRI_VERI * 8;
  GorevTSSListesi[2]^.SS := SECICI_CAGRI_VERI * 8;
  GorevTSSListesi[2]^.FS := SECICI_CAGRI_VERI * 8;
  GorevTSSListesi[2]^.GS := SECICI_CAGRI_VERI * 8;
  GorevTSSListesi[2]^.SS0 := SECICI_CAGRI_VERI * 8;
  GorevTSSListesi[2]^.ESP0 := CAGRI_ESP;

  // sistem görev deðerlerini belirle
  GorevListesi[2]^.GorevSayaci := 0;
  GorevListesi[2]^.BellekBaslangicAdresi := TSayi4(@ProgramCagrilariniYanitla);
  GorevListesi[2]^.BellekUzunlugu := $FFFFFFFF;
  GorevListesi[2]^.OlaySayisi := 0;
  GorevListesi[2]^.OlayBellekAdresi := nil;
  GorevListesi[2]^.FAktifPencere := nil;

  // sistem görev adý (dosya adý)
  GorevListesi[2]^.FDosyaAdi := 'çaðrý.bin';
  GorevListesi[2]^.FProgramAdi := 'Sistem Çaðrýlarý';

  // sistem görevini çalýþýyor olarak iþaretle
  Gorev := GorevListesi[2];
  Gorev^.DurumDegistir(2, gdCalisiyor);

  // çalýþan ve oluþturulan görev deðerlerini belirle
  CalisanGorevSayisi := 2;
end;

{==============================================================================
  grafik iþlevlerini yönetecek görevi oluþturur
 ==============================================================================}
procedure GrafikYoneticiGorevOlustur;
var
  Gorev: PGorev;
begin

  // kod seçicisi (CS)
  // Eriþim  : 1 = mevcut, 00 = DPL0, 11 = kod yazmaç, 0 = dallanýlamaz, 1 = okunabilir, 0 = eriþilmedi
  // Esneklik: 1 = gran = 4K çözünürlük, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SECICI_GRAFIK_KOD, 0, $FFFFFFFF, %10011010, %11011111);
  // veri seçicisi (DS)
  // Eriþim  : 1 = mevcut, 00 = DPL0, 10 = veri yazmaç, 0 = artarak büyüyen, 1 = yazýlabilir, 0 = eriþilmedi
  // Esneklik: 1 = gran = 4K çözünürlük, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SECICI_GRAFIK_VERI, 0, $FFFFFFFF, %10010010, %11011111);
  // görev seçicisi (TSS)
  // Eriþim  : 1 = mevcut, 00 = DPL0, 010 = 32 bit kullanýlabilir TSS, 0 = meþgul biti (meþgul deðil), 1
  // Esneklik: 1 = gran = 1Byte çözünürlük, 00, 1 = bana tahsis edildi, 0000 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SECICI_GRAFIK_TSS, TSayi4(GorevTSSListesi[3]), 104,
    %10001001, %00010000);

  // denetçinin kullanacaðý TSS'nin içeriðini sýfýrla
  FillByte(GorevTSSListesi[3]^, 104, $00);

  GorevTSSListesi[3]^.EIP := TSayi4(@GrafikYonetimi);    // DPL 0
  GorevTSSListesi[3]^.EFLAGS := $202;
  GorevTSSListesi[3]^.ESP := GRAFIK_ESP;
  GorevTSSListesi[3]^.CS := SECICI_GRAFIK_KOD * 8;
  GorevTSSListesi[3]^.DS := SECICI_GRAFIK_VERI * 8;
  GorevTSSListesi[3]^.ES := SECICI_GRAFIK_VERI * 8;
  GorevTSSListesi[3]^.SS := SECICI_GRAFIK_VERI * 8;
  GorevTSSListesi[3]^.FS := SECICI_GRAFIK_VERI * 8;
  GorevTSSListesi[3]^.GS := SECICI_GRAFIK_VERI * 8;
  GorevTSSListesi[3]^.SS0 := SECICI_GRAFIK_VERI * 8;
  GorevTSSListesi[3]^.ESP0 := GRAFIK_ESP;

  // sistem görev deðerlerini belirle
  GorevListesi[3]^.GorevSayaci := 0;
  GorevListesi[3]^.BellekBaslangicAdresi := TSayi4(@GrafikYonetimi);
  GorevListesi[3]^.BellekUzunlugu := $FFFFFFFF;
  GorevListesi[3]^.OlaySayisi := 0;
  GorevListesi[3]^.OlayBellekAdresi := nil;
  GorevListesi[3]^.FAktifPencere := nil;

  // sistem görev adý (dosya adý)
  GorevListesi[3]^.FDosyaAdi := 'grafik.bin';
  GorevListesi[3]^.FProgramAdi := 'Grafik Yöneticisi';

  // sistem görevini çalýþýyor olarak iþaretle
  Gorev := GorevListesi[3];
  Gorev^.DurumDegistir(3, gdCalisiyor);

  // çalýþan ve oluþturulan görev deðerlerini belirle
  CalisanGorevSayisi := 3;
end;

procedure ProgramCagrilariniYanitla;
begin

  while True do
  begin

    Inc(CagriSayaci);
  end;
end;

procedure GrafikYonetimi;
begin

  while True do
  begin

    Inc(GrafikSayaci);

    SistemDegerleriOlayIsle;

    GEkranKartSurucusu.EkranBelleginiGuncelle;
  end;
end;

procedure SistemDegerleriBasla;
var
  Sol: TISayi4;
begin

  Sol := GAktifMasaustu^.FBoyut.Genislik - 166;
  SDPencere := SDPencere^.Olustur(nil, Sol, 10, 156, 70, ptBasliksiz,
    'Sistem Durumu', 0);
  SDPencere^.Goster;

  SDZamanlayici := SDZamanlayici^.Olustur(100);
  SDZamanlayici^.Durum := zdCalisiyor;
end;

procedure SistemDegerleriOlayIsle;
var
  Gorev: PGorev;
  Olay: TOlay;
begin

  Gorev := GorevListesi[1];

  if(Gorev^.OlayAl(Olay)) then
  begin

    if(Olay.Olay = CO_ZAMANLAYICI) then
    begin

      //SISTEM_MESAJ(RENK_KIRMIZI, 'CO_ZAMANLAYICI olayý', []);
      if(Olay.Kimlik = SDZamanlayici^.Kimlik) then SDPencere^.Ciz;
    end
    else if(Olay.Olay = CO_CIZIM) then
    begin

      //SISTEM_MESAJ(RENK_KIRMIZI, 'CO_CIZIM olayý', []);
      SDPencere^.YaziYaz(SDPencere, 12, 10, 'ÇKRDK:', RENK_LACIVERT);
      SDPencere^.SayiYaz16(SDPencere, 64, 10, True, 8, SistemSayaci, RENK_LACIVERT);
      SDPencere^.YaziYaz(SDPencere, 12, 26, 'ÇAÐRI:', RENK_LACIVERT);
      SDPencere^.SayiYaz16(SDPencere, 64, 26, True, 8, CagriSayaci, RENK_LACIVERT);
      SDPencere^.YaziYaz(SDPencere, 12, 42, 'GRAFK:', RENK_LACIVERT);
      SDPencere^.SayiYaz16(SDPencere, 64, 42, True, 8, GrafikSayaci, RENK_LACIVERT);
    end;
  end;
end;

constructor TTestSinif.Create;
begin

end;

procedure TTestSinif.Artir;
begin

  Inc(FDeger1);
  SISTEM_MESAJ(RENK_SIYAH, 'TTest1.Artir: %d', [FDeger1]);
  SISTEM_MESAJ_YAZI(RENK_SIYAH, 'Birim: ', UnitName);
end;

procedure TTestSinif.Eksilt;
begin

  Dec(FDeger1);
  SISTEM_MESAJ(RENK_SIYAH, 'TTestSinif.Eksilt: %d', [FDeger1]);
end;

procedure TArGe.Olustur;
begin

  FCalisanBirim := nil; //@Program2Basla;
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
  P2ACDugmeler[0] := P2AracCubugu^.DugmeEkle(9);
  P2ACDugmeler[1] := P2AracCubugu^.DugmeEkle(10);
  P2ACDugmeler[2] := P2AracCubugu^.DugmeEkle(11);
  P2ACDugmeler[3] := P2AracCubugu^.DugmeEkle(12);
  P2ACDugmeler[4] := P2AracCubugu^.DugmeEkle(13);
  P2ACDugmeler[5] := P2AracCubugu^.DugmeEkle(14);
  P2ACDugmeler[6] := P2AracCubugu^.DugmeEkle(15);
  P2ACDugmeler[7] := P2AracCubugu^.DugmeEkle(16);
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
  s: String;
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
      1: s := '-';
      2: s := 'TDüðme';
      3: s := 'TEtiket';
      4: s := 'TGiriþKutusu';
      5: s := 'TDefter';
      6: s := 'TOnayKutusu';
      7: s := 'TKaydýrmaÇubuðu';
    end;

    P2DurumCubugu^.Baslik := 'Konum: ' + IntToStr(AOlay.Deger1) + ':' +
      IntToStr(AOlay.Deger2) + ' - Seçili Nesne: ' + s;
    P2DurumCubugu^.Ciz;
  end
  else if(AOlay.Olay = FO_SAGTUS_BIRAKILDI) and (AOlay.Kimlik = P2Pencere^.Kimlik) then
  begin

    if(SonSecim = 2) then
    begin

      P4Dugme := P4Dugme^.Olustur(ktNesne, P2Pencere, SonKonumY, SonKonumD, 100, 20, 'TDüðme');
      P4Dugme^.Goster;
    end
    else if(SonSecim = 3) then
    begin

      P3Etiket := P3Etiket^.Olustur(ktNesne, P2Pencere, SonKonumY, SonKonumD, RENK_KIRMIZI, 'TEtiket');
      P3Etiket^.Goster;
    end
    else if(SonSecim = 4) then
    begin

      P3GirisKutusu := P3GirisKutusu^.Olustur(ktNesne, P2Pencere, SonKonumY, SonKonumD,
        120, 20, 'TGiriþKutusu');
      P3GirisKutusu^.Goster;
    end
    else if(SonSecim = 5) then
    begin

      P3Defter := P3Defter^.Olustur(ktNesne, P2Pencere, SonKonumY, SonKonumD, 200, 200,
        $FCFCFC, RENK_SIYAH, False);
      P3Defter^.YaziEkle('TDefter');
      P3Defter^.Goster;
    end
    else if(SonSecim = 6) then
    begin

      P3OnayKutusu := P3OnayKutusu^.Olustur(ktNesne, P2Pencere, SonKonumY, SonKonumD,
        'TOnayKutusu');
      P3OnayKutusu^.Goster;
    end
    else if(SonSecim = 7) then
    begin

      P3KaydirmaCubugu := P3KaydirmaCubugu^.Olustur(ktNesne, P2Pencere, SonKonumY, SonKonumD,
        100, 24, yYatay);
      P3KaydirmaCubugu^.DegerleriBelirle(0, 100);
      P3KaydirmaCubugu^.FMevcutDeger := 50;
      P3KaydirmaCubugu^.Goster;
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
      SonSecim := 7;

    //SISTEM_MESAJ(RENK_SIYAH, 'Kimlik: %d', [AOlay.Kimlik]);
  end;
end;

end.
