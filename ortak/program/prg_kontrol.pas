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

procedure SistemKontrolGoreviOlustur(AGorevKimlik: TKimlik; AGorevAdi: string;
  AIslev: TIslev);
procedure KontrolYonetimi;
procedure NesneKontrol;
procedure CalisanUygulamalariKaydet;

implementation

uses sistem;

{==============================================================================
  sistem kontrol i�levlerini y�netecek g�revi olu�turur
 ==============================================================================}
procedure SistemKontrolGoreviOlustur(AGorevKimlik: TKimlik; AGorevAdi: string;
  AIslev: TIslev);
var
  Gorev: PGorev;
  i: TKimlik;
  SeciciCSSiraNo, SeciciDSSiraNo,
  SeciciTSSSiraNo: TSayi4;
begin

  i := AGorevKimlik;

  // uygulaman�n TSS, CS, DS se�icilerini belirle, her bir program 3 se�ici i�erir
  SeciciCSSiraNo := (i * 3) + 1;
  SeciciDSSiraNo := SeciciCSSiraNo + 1;
  SeciciTSSSiraNo := SeciciDSSiraNo + 1;

  // kod se�icisi (CS)
  // Eri�im  : 1 = mevcut, 00 = DPL0, 11 = kod yazma�, 0 = dallan�lamaz, 1 = okunabilir, 0 = eri�ilmedi
  // Esneklik: 1 = gran = 4K ��z�n�rl�k, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SeciciCSSiraNo, 0, $FFFFFFFF, %10011010, %11011111);
  // veri se�icisi (DS)
  // Eri�im  : 1 = mevcut, 00 = DPL0, 10 = veri yazma�, 0 = artarak b�y�yen, 1 = yaz�labilir, 0 = eri�ilmedi
  // Esneklik: 1 = gran = 4K ��z�n�rl�k, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SeciciDSSiraNo, 0, $FFFFFFFF, %10010010, %11011111);
  // g�rev se�icisi (TSS)
  // Eri�im  : 1 = mevcut, 00 = DPL0, 010 = 32 bit kullan�labilir TSS, 0 = me�gul biti (me�gul de�il), 1
  // Esneklik: 1 = gran = 1Byte ��z�n�rl�k, 00, 1 = bana tahsis edildi, 0000 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SeciciTSSSiraNo, TSayi4(GorevTSSListesi[AGorevKimlik]), 104,
    %10001001, %00010000);

  // denet�inin kullanaca�� TSS'nin i�eri�ini s�f�rla
  FillByte(GorevTSSListesi[AGorevKimlik]^, 104, $00);

  GorevTSSListesi[AGorevKimlik]^.EIP := TSayi4(AIslev);    // DPL 0
  GorevTSSListesi[AGorevKimlik]^.EFLAGS := $202;
  GorevTSSListesi[AGorevKimlik]^.ESP := KONTROL_ESP;
  GorevTSSListesi[AGorevKimlik]^.CS := SeciciCSSiraNo * 8;
  GorevTSSListesi[AGorevKimlik]^.DS := SeciciDSSiraNo * 8;
  GorevTSSListesi[AGorevKimlik]^.ES := SeciciDSSiraNo * 8;
  GorevTSSListesi[AGorevKimlik]^.SS := SeciciDSSiraNo * 8;
  GorevTSSListesi[AGorevKimlik]^.FS := SeciciDSSiraNo * 8;
  GorevTSSListesi[AGorevKimlik]^.GS := SeciciDSSiraNo * 8;
  GorevTSSListesi[AGorevKimlik]^.SS0 := SeciciDSSiraNo * 8;
  GorevTSSListesi[AGorevKimlik]^.ESP0 := KONTROL_ESP;

  // sistem g�rev de�erlerini belirle
  GorevListesi[AGorevKimlik]^.GorevSayaci := 0;
  GorevListesi[AGorevKimlik]^.BellekBaslangicAdresi := TSayi4(@KontrolYonetimi);
  GorevListesi[AGorevKimlik]^.BellekUzunlugu := $FFFFFFFF;
  GorevListesi[AGorevKimlik]^.OlaySayisi := 0;
  GorevListesi[AGorevKimlik]^.OlayBellekAdresi := nil;
  GorevListesi[AGorevKimlik]^.AktifMasaustu := nil;
  GorevListesi[AGorevKimlik]^.AktifPencere := nil;

  // sistem g�rev ad� (dosya ad�)
  GorevListesi[AGorevKimlik]^.FDosyaAdi := 'cekirdek.bin';
  GorevListesi[AGorevKimlik]^.FProgramAdi := AGorevAdi;

  // sistem g�revini �al���yor olarak i�aretle
  Gorev := GorevListesi[AGorevKimlik];
  Gorev^.DurumDegistir(AGorevKimlik, gdCalisiyor);

  // �al��an ve olu�turulan g�rev de�erlerini belirle
  CalisanGorevSayisi := AGorevKimlik + 1;
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

        for i := 19 downto 0 do
        begin

          IslemGostergesi^.MevcutDegerYaz(i);
          //BekleMS(100);

          Sayac := ZamanlayiciSayaci + 20;
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
    if(FD.Mevcut0) and (FD.FD3.SurucuTipi = SURUCUTIP_DISK) and (FD.FD3.AygitAdi = 'fda4') then
    begin

      FD.SektorYaz(@FD, 10, 1, Isaretci($3200000));
      Break;
    end;
  end;
end;

end.
