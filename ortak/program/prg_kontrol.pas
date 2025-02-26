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

implementation

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

    // 10 saniye bekle
    //BekleMS(1000);
    Sayac := ZamanlayiciSayaci + 1000;
    while (Sayac > ZamanlayiciSayaci) do; //begin asm int $20; end; end;

    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Fare-X: %d', [GFareSurucusu.YatayKonum]);
    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Fare-Y: %d', [GFareSurucusu.DikeyKonum]);
    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, '2', []);
    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Fare-X: %d', [GFareSurucusu.YatayKonum]);
    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Fare-Y: %d', [GFareSurucusu.DikeyKonum]);

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

        for i := 20 downto 0 do
        begin

          IslemGostergesi^.MevcutDegerYaz(i);
          //BekleMS(100);

          Sayac := ZamanlayiciSayaci + 100;
          while (Sayac > ZamanlayiciSayaci) do; //begin asm int $20; end; end;
        end;

        Pencere^.Gizle;

        //BekleMS(500);
        Sayac := ZamanlayiciSayaci + 500;
        while (Sayac > ZamanlayiciSayaci) do; //begin asm int $20; end; end;

      end;
    end;
  end;
end;

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

end.
