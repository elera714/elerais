{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: prg_kontrol.pas
  Dosya ��levi: dahili �ekirdek program�: �ekirdek i�i kontrol i�lemleri i�in

  G�ncelleme Tarihi: 21/02/2025

 ==============================================================================}
{$mode objfpc}
unit prg_kontrol;

interface

uses gdt, gorev, paylasim, genel, zamanlayici, gn_pencere, gn_islemgostergesi,
  gorselnesne, sistemmesaj, dosya;

procedure SistemKontrolGoreviOlustur;
procedure KontrolYonetimi;
procedure NesneKontrol;
procedure CalisanUygulamalariKaydet;

implementation

uses sistem;

{==============================================================================
  sistem kontrol i�levlerini y�netecek g�revi olu�turur
 ==============================================================================}
procedure SistemKontrolGoreviOlustur;
var
  Gorev: PGorev;
begin

  // kod se�icisi (CS)
  // Eri�im  : 1 = mevcut, 00 = DPL0, 11 = kod yazma�, 0 = dallan�lamaz, 1 = okunabilir, 0 = eri�ilmedi
  // Esneklik: 1 = gran = 4K ��z�n�rl�k, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SECICI_KONTROL_KOD, 0, $FFFFFFFF, %10011010, %11011111);
  // veri se�icisi (DS)
  // Eri�im  : 1 = mevcut, 00 = DPL0, 10 = veri yazma�, 0 = artarak b�y�yen, 1 = yaz�labilir, 0 = eri�ilmedi
  // Esneklik: 1 = gran = 4K ��z�n�rl�k, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SECICI_KONTROL_VERI, 0, $FFFFFFFF, %10010010, %11011111);
  // g�rev se�icisi (TSS)
  // Eri�im  : 1 = mevcut, 00 = DPL0, 010 = 32 bit kullan�labilir TSS, 0 = me�gul biti (me�gul de�il), 1
  // Esneklik: 1 = gran = 1Byte ��z�n�rl�k, 00, 1 = bana tahsis edildi, 0000 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SECICI_KONTROL_TSS, TSayi4(GorevTSSListesi[3]), 104,
    %10001001, %00010000);

  // denet�inin kullanaca�� TSS'nin i�eri�ini s�f�rla
  FillByte(GorevTSSListesi[3]^, 104, $00);

  GorevTSSListesi[3]^.EIP := TSayi4(@KontrolYonetimi);    // DPL 0
  GorevTSSListesi[3]^.EFLAGS := $202;
  GorevTSSListesi[3]^.ESP := KONTROL_ESP;
  GorevTSSListesi[3]^.CS := SECICI_KONTROL_KOD * 8;
  GorevTSSListesi[3]^.DS := SECICI_KONTROL_VERI * 8;
  GorevTSSListesi[3]^.ES := SECICI_KONTROL_VERI * 8;
  GorevTSSListesi[3]^.SS := SECICI_KONTROL_VERI * 8;
  GorevTSSListesi[3]^.FS := SECICI_KONTROL_VERI * 8;
  GorevTSSListesi[3]^.GS := SECICI_KONTROL_VERI * 8;
  GorevTSSListesi[3]^.SS0 := SECICI_KONTROL_VERI * 8;
  GorevTSSListesi[3]^.ESP0 := KONTROL_ESP;

  // sistem g�rev de�erlerini belirle
  GorevListesi[3]^.GorevSayaci := 0;
  GorevListesi[3]^.BellekBaslangicAdresi := TSayi4(@KontrolYonetimi);
  GorevListesi[3]^.BellekUzunlugu := $FFFFFFFF;
  GorevListesi[3]^.OlaySayisi := 0;
  GorevListesi[3]^.OlayBellekAdresi := nil;
  GorevListesi[3]^.AktifMasaustu := nil;
  GorevListesi[3]^.AktifPencere := nil;

  // sistem g�rev ad� (dosya ad�)
  GorevListesi[3]^.FDosyaAdi := 'skontrol.bin';
  GorevListesi[3]^.FProgramAdi := 'Sistem Kontrol';

  // sistem g�revini �al���yor olarak i�aretle
  Gorev := GorevListesi[3];
  Gorev^.DurumDegistir(3, gdCalisiyor);

  // �al��an ve olu�turulan g�rev de�erlerini belirle
  CalisanGorevSayisi := 4;
end;

// rutin kontrol denetimlerin yap�ld��� nokta
procedure KontrolYonetimi;
var
  Pencere: PPencere = nil;
  IslemGostergesi: PIslemGostergesi = nil;
  AramaKaydi: TDosyaArama;
  i, G: TISayi4;
  j: TSayi2;
  TarihSaat: TTarihSaat;
  DosyaBulundu: Boolean;
  Sayac: TSayi4;
begin

  while True do
  begin

    NesneKontrol;

    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, '1', []);
    //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'FareX: %d', [GFareSurucusu.YatayKonum]);
    //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'FareY: %d', [GFareSurucusu.DikeyKonum]);

    // 10 saniye bekle
    //BekleMS(1000);
    Sayac := ZamanlayiciSayaci + 1000;
    while (Sayac > ZamanlayiciSayaci) do; //begin asm int $20; end; end;

    //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Fare-X: %d', [GFareSurucusu.YatayKonum]);
    //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Fare-Y: %d', [GFareSurucusu.DikeyKonum]);
    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, '2', []);

    DosyaBulundu := False;

    i := FindFirst('disket1:\*.*', 0, AramaKaydi);
    while i = 0 do
    begin

      if(AramaKaydi.DosyaAdi = 'cekirdek.bin') then
      begin

        DosyaBulundu := True;

        j := AramaKaydi.SonDegisimTarihi;
        TarihSaat.Gun := j and 31;
        TarihSaat.Ay := (j shr 5) and 15;
        TarihSaat.Yil := ((j shr 9) and 127) + 1980;

        j := AramaKaydi.SonDegisimSaati;
        TarihSaat.Saniye := (j and 31) * 2;
        TarihSaat.Dakika := (j shr 5) and 63;
        TarihSaat.Saat := (j shr 11) and 31;

        Break;
      end;

      i := FindNext(AramaKaydi);
    end;
    FindClose(AramaKaydi);

{    SISTEM_MESAJ(mtHata, RENK_MAVI, 'Masa�st� Sol: %d', [GAktifMasaustu^.FKonum.Sol]);
    SISTEM_MESAJ(mtHata, RENK_MAVI, 'Masa�st� �st: %d', [GAktifMasaustu^.FKonum.Ust]);
    SISTEM_MESAJ(mtHata, RENK_MAVI, 'Masa�st� Sol: %d', [GAktifMasaustu^.FCizimBaslangic.Sol]);
    SISTEM_MESAJ(mtHata, RENK_MAVI, 'Masa�st� �st: %d', [GAktifMasaustu^.FCizimBaslangic.Ust]);
}
    if(DosyaBulundu) then
    begin

      if(CekirdekYuklemeTS <> TarihSaat) then
      begin

        G := GAktifMasaustu^.FBoyut.Genislik;

        if(Pencere = nil) then
          Pencere := Pencere^.Olustur(GAktifMasaustu, G - 166, 85, 156, 16,
          ptBasliksiz, '', RENK_KIRMIZI);

        if(IslemGostergesi = nil) then
          IslemGostergesi := IslemGostergesi^.Olustur(ktNesne, Pencere, 1, 1, 154, 14);

        IslemGostergesi^.DegerleriBelirle(0, 20);
        IslemGostergesi^.Goster;

        Pencere^.Goster;

        for i := 10 downto 0 do
        begin

          IslemGostergesi^.MevcutDegerYaz(i);
          //BekleMS(100);

          Sayac := ZamanlayiciSayaci + 30;
          while (Sayac > ZamanlayiciSayaci) do; //begin asm int $20; end; end;
        end;

        CalisanUygulamalariKaydet;

        YenidenBaslat;

        Pencere^.Gizle;

        //BekleMS(500);
        Sayac := ZamanlayiciSayaci + 500;
        while (Sayac > ZamanlayiciSayaci) do; //begin asm int $20; end; end;

      end;
    end;
  end;
end;

// g�rsel nesne bellek b�lgesine ba�ka i�lemlerin hatayla veri yazmas�na kar��n
// denetim i�lemlerini ger�ekle�tirir
procedure NesneKontrol;
var
  G: PGorselNesne;
  i: Integer;
  j: TKimlik;
begin

  for i := 0 to USTSINIR_GORSELNESNE - 1 do
  begin

    G := GGorselNesneListesi[i];

    j := G^.Kimlik shr 10;
    if(i <> j) then
    begin

      SISTEM_MESAJ(mtHata, RENK_KIRMIZI, '%d. nesne giri�i hatal�: %d', [i, G^.Kimlik]);
      Break;
    end;
  end;
end;

// sistem yeniden ba�lamadan �nce �al��an t�m pencereye sahip uygulamalar�n
// diske kaydedilme i�lemini ger�ekle�tirir
procedure CalisanUygulamalariKaydet;
var
  GN: PGorselNesne;
  Bellek: PChar;
  i, j, CalisanPSayisi: TISayi4;
  P: TProgramKayit;
  FD: TFizikselDepolama;
  P4: PSayi4;
begin

  Bellek := Isaretci($3200000);
  FillByte(Isaretci(Bellek)^, 512, 0);

  CalisanPSayisi := CalisanProgramSayisiniAl(GAktifMasaustu^.Kimlik);

  for i := 0 to CalisanPSayisi - 1 do
  begin

    P := CalisanProgramBilgisiAl(i, GAktifMasaustu^.Kimlik);

    for j := 1 to Length(P.DosyaAdi) do
    begin

      Bellek^ := P.DosyaAdi[j];
      Inc(Bellek);
    end;

    Bellek^ := #0;
    Inc(Bellek);

    P4 := PSayi4(Bellek);

    GN := GN^.NesneAl(P.PencereKimlik);
    if not(GN = nil) then
    begin

      P4^ := GN^.FKonum.Sol;
      Inc(P4);
      P4^ := GN^.FKonum.Ust;
      Inc(P4);
      P4^ := GN^.FBoyut.Genislik;
      Inc(P4);
      P4^ := GN^.FBoyut.Yukseklik;
      Inc(P4);
    end;

    Bellek := PChar(P4);
  end;

  Bellek^ := #0;

  for i := 0 to 5 do
  begin

    FD := FizikselDepolamaAygitListesi[i];
    if(FD.Mevcut0) and (FD.FD3.SurucuTipi = SURUCUTIP_DISK) then
    begin

      FD.SektorYaz(@FD, 10, 1, Isaretci($3200000));
      Break;
    end;
  end;
end;

end.
