{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: yonetim.pas
  Dosya Ýþlevi: sistem ana yönetim / kontrol kýsmý

  Güncelleme Tarihi: 21/11/2026

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
    procedure AssertIslevi(const FMesaj, FAd: shortstring; FSiraNo: TISayi4;
      FHataAdresi: Isaretci);
  end;

var
  GYonetim: TYonetim;
  GArge: TArGe;

implementation

uses gdt, gorev, src_klavye, dhcpv4i, sistemmesaj, dosyalar, gn_masaustu, src_disket,
  mdepolama, baglantilar, olayyonetim, sistem, gn_islevler, src_ps2, aygityonetimi,
  vbox, elr1, dhcpv4;

{==============================================================================
  yönetim ilk yükleme iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure TYonetim.Yukle;
var
  G: TGorev;
  GMBilgi: PGMBilgi;
  Olay: POlay;
  OHCIESP, ARPESP1,
  Prg1ESP, Prg2ESP: Isaretci;
begin

  GMBilgi := PGMBilgi(BILDEN_VERIADRESI);

  // çekirdek bilgilerini al
  GSistem.FCekirdekBaslangicAdresi := GMBilgi^.CekirdekBaslangicAdresi;
  GSistem.FCekirdekUzunlugu := GMBilgi^.CekirdekKodUzunluk;

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
  GorevTSSListesi[0]^.ESP0 := {(G.FKimlik * GOREV3_ESP_U) +} GOREV3_ESP;

  // not: sistem için CS ve DS seçicileri bilden programý tarafýndan
  // oluþturuldu. tekrar oluþturmaya gerek yok

  // sistem için görev seçicisi (TSS)
  // Eriþim  : 1 = mevcut, 00 = DPL0, 010 = 32 bit kullanýlabilir TSS, 0 = meþgul biti (meþgul deðil), 1
  // Esneklik: 1 = gran = 1Byte çözünürlük, 00, 1 = bana tahsis edildi, 0000 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SECICI_SISTEM_TSS, TSayi4(GorevTSSListesi[0]), 104,
    %10001001, %00010000);

  // sistem görev deðerlerini belirle
  G := TGorev.Create(0);
  GGorevler.Gorev[0] := G;
  G.FSeviyeNo := CALISMA_SEVIYE0;
  G.FGrvSayac := 0;
  G.FBellekBaslAdr := GSistem.FCekirdekBaslangicAdresi;
  G.FCalismaSureMS := DPL0_SUREMS;
  G.FCalismaSureSayac := DPL0_SUREMS;

  { TODO - CekirdekUzunlugu -> *4K olarak hesaplanacak }
  G.FBellekUz := GSistem.FCekirdekUzunlugu;

  G.FCekirdekYiginUst := (G.FKimlik * GOREV3_ESP_U) + GOREV3_ESP;

  GGorevler.IlkCalismaYigininiOlustur0(G.FKimlik);

  // çekirdek için olay iþlemleri gerçekleþmeyecek
  G.FOlaySayisi := 0;
  G.FOlayBellekAdresi := nil;

  G.FAktifMasaustu := nil;
  G.FAktifPencere := nil;

  G.FDosyaAdi := 'cekirdek.bin';
  G.FProgramAdi := 'Sistem Çekirdeði';

  // görev olay sayýsý
  G.FOlaySayisi := 0;

  GGorevler.DurumDegistir(0, gdCalisiyor);

  // çalýþan ve oluþturulan görev deðerlerini belirle
  GGorevler.FCalisanGorevSayisi := 1;
  GGorevler.FAktifGrv := 0;

  // ilk TSS'yi yükle
  // not : tss'nin yükleme iþlevi görev geçiþini gerçekleþtirmez. sadece
  // TSS'yi meþgul olarak ayarlar.
  asm
    mov ax,SECICI_SISTEM_TSS * 8;
    ltr ax
  end;
end;

const
  ICMPv6TestIP6Adres: TIP6Adres = (
    $FE, $80, $00, $00, $00, $00, $00, $00,
    $54, $A7, $B5, $12, $96, $04, $A5, $1D);
  ICMPv6TestMACAdres: TMACAdres = ($08, $00, $AB, $CD, $EF, $02);

{==============================================================================
  sistem ana kontrol kýsmý
 ==============================================================================}
procedure TYonetim.SistemAnaKontrol;
const
  PingVeri: string = 'abcdefghijklmnopqrstuvwabcdefghi';
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
  B: TBaglanti;
  DSELR: TELR1;
begin

  // masaüstü aktif olana kadar bekle
  while GGNesneler.AktifMasaustu = nil do;

  // çekirdek dosyasýnýn deðiþim kontrolü için cekirdek.bin dosyasýnýn
  // yüklenme aþamasýndaki tarih + saat deðerlerini kaydet
  CekirdekDosyaTSDegeriniKaydet;

  // sistem kapanýþ aþamasýnda "çalýþýr olarak" kaydedilen çalýþan uygulamalarý yükle
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

              GAgBaglantilari.AB.IP4AdresiAlindi := False;
              B := GAgBaglantilari.AB.BaglantiOlustur(bnDHCPv4i, itIP4, btYAktif,
                ttUDP, DHCPv4_ISTEMCI_PORT, DHCPv4_SUNUCU_PORT);
              B.FDHCPv4i.OtomatikIpAdresiAl;
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

            //DosyaKopyala('disk3:\haklar.txt', 'disk2:\haklar.txt');

            {MD := GMantiksalDepolama.SurucuAl('disk2');
            DSELR := TELR1(GDosyalar.Yeni(MD));
            DSELR.SistemKlasorleriniOlustur;}

            // icmp v6 komþu isteði mesajý - tutanaðý test etme amacýyla eklendi
            //GAgBaglantilari.AB.FICMP6.KomsuIstegiGonder(ICMPv6TestIP6Adres);

            //AssertErrorProc := @AssertIslev;
            //Assert(1 > 2, 'Merhaba');
          end
          // test iþlev tuþu-1
          else if(TusKarakterDegeri = '4') then
          begin

            //dosyalar.DeleteFile('disk2:\haklar.txt');

            GVirtualBox.FareDurumDegistir(False);
            //GAgBaglantilari.AB.FARP.PaketleVeGonder(arpIstek, nil, @IP4Adres);

            // icmp v6 ping mesajý - tutanaðý test etme amacýyla eklendi
            {GAgBaglantilari.AB.FICMP6.PingMesajiGonder(ICMP6_PING_ISTEK,
              ICMPv6TestIP6Adres, ICMPv6TestMACAdres, PingSiraNo, @PingVeri[1], 32);
            Inc(PingSiraNo);}

            //iiiii := Align(SizeOf(TIzgara) + 64, 16);
            //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'U: %d', [iiiii]);
          end
          // test iþlev tuþu-2
          else if(TusKarakterDegeri = '5') then
          begin

            MD := GMantiksalDepolama.SurucuAl('disk2');
            if not(MD = nil) then
            begin

              DSELR := TELR1(GDosyalar.Yeni(MD));
              DSELR.DiskiBicimle;
            end;
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

          //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Basýlan Tuþ Deðeri: %x', [TusDegeri]);

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
      GAgBaglantilari.AB.VerileriIsle;

    if not(GVirtualBox = nil) then GVirtualBox.FareKonumDegerleriniAl;

    // fare olaylarýný iþle
    GOlayYonetim.FareOlaylariniIsle;

    // disket sürücü motorunun aktifliðini kontrol eder, gerekirse motoru kapatýr
    if not(GDisketAygitlari = nil) then GDisketAygitlari.DisketSurucuMotorunuKontrolEt;

    // sonlandýrýlmýþ olarak iþaretlenen görevleri sonlandýr
    GGorevler.IsaretlenenGorevleriSonlandir;

    //if not(GAgBaglantilari.AB = nil) then GAgBaglantilari.AB.OnayMesajlariniGonder;
  end;
end;

{==============================================================================
  sistemin yüklenme esnasýnda çekirdeðin tarih + saat deðerini kaydeder
 ==============================================================================}
procedure TYonetim.CekirdekDosyaTSDegeriniKaydet;
var
  AramaKaydi: TDosyaArama;
  i: TISayi4;
  j: TSayi2;
begin

  i := FindFirst('disket1:\*.*', 0, AramaKaydi);
  while (i = HATA_YOK) do
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

{==============================================================================
  sistem kapanýþ aþamasýnda "çalýþýr olarak" kaydedilen uygulamalarý yükler
 ==============================================================================}
procedure TYonetim.KaydedilenProgramlariYenidenYukle;
var
  GN: TGorselNesne;
  MUGorev: TGorev;
  Konum: TKonum;
  Boyut: TBoyut;
  Bellek: Isaretci;
  DosyaKimlik: TKimlik;
  DosyaAdi, s, s2: string;
  U: TISayi8;
  SiraNo, Kod,
  i, j, k: TSayi4;
begin

  AssignFile(DosyaKimlik, 'disk2:\yuklenecek_programlar.ini');
  Reset(DosyaKimlik);
  if(IOResult = HATA_YOK) then
  begin

    U := FileSize(DosyaKimlik);
    Bellek := GetMem(U);

    Read(DosyaKimlik, Bellek);

    j := 0;
    i := 0;
    repeat

      i := Pos(#10, PChar(Bellek));
      if(i > 0) then
      begin

        Dec(i);
        s := Copy(PChar(Bellek + j), 0, (i - j) - 1);
        PChar(Bellek + i)^ := ' ';
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

          GN := GGNesneler.NesneAl(TPencere(MUGorev.FAktifPencere).Kimlik);

          TPencere(GN).FAtananAlan.Sol := Konum.Sol;
          TPencere(GN).FAtananAlan.Ust := Konum.Ust;
          TPencere(GN).FAtananAlan.Genislik := Boyut.Genislik;
          TPencere(GN).FAtananAlan.Yukseklik := Boyut.Yukseklik;
          TPencere(GN).Guncelle;

          TMasaustu(GN.AtaNesne).Ciz;
        end;
      end;
    until i = 0;

    FreeMem(Bellek, U);
  end;

  CloseFile(DosyaKimlik);
end;

procedure TYonetim.AssertIslevi(const FMesaj, FAd: shortstring; FSiraNo: TISayi4;
  FHataAdresi: Isaretci);
begin

  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Assert: %s', [FMesaj]);
end;

end.
