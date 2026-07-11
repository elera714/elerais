{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: prg_kontrol.pas
  Dosya Ýþlevi: dahili çekirdek programý: çekirdek içi kontrol iþlemleri için

  Güncelleme Tarihi: 10/07/2026

 ==============================================================================}
{$mode objfpc}
unit prg_kontrol;

interface

uses paylasim, genel, gn_pencere, gn_islemgostergesi, dosya;

procedure KontrolYonetimi;

implementation

uses sistem;

{==============================================================================
  sistem çekirdeðinin deðiþip deðiþmediðinin kontrolünün gerçekleþtiði kýsým
 ==============================================================================}
procedure KontrolYonetimi;
var
  Pencere: PPencere = nil;
  IslemGostergesi: PIslemGostergesi = nil;
  AramaKaydi: TDosyaArama;
  i, G: TISayi4;
  j, j2, Sayac: TSayi4;
  TarihSaat: TTarihSaat;
  DosyaBulundu: Boolean;
begin

  while True do
  begin

    // 5 saniyede bir denetim
    Sayac := ZamanlayiciSayaci + 5 * 100;
    while (Sayac > ZamanlayiciSayaci) do;

    DosyaBulundu := False;

    // 1. sistem çekirdeðini ara
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

        j2 := AramaKaydi.SonDegisimSaati;
        TarihSaat.Saniye := (j2 and 31) * 2;
        TarihSaat.Dakika := (j2 shr 5) and 63;
        TarihSaat.Saat := (j2 shr 11) and 31;

        Break;
      end;

      i := FindNext(AramaKaydi);
    end;
    FindClose(AramaKaydi);

    // 1.1 sistem çekirdeðinin bulunmasý durumunda ...
    if(DosyaBulundu) then
    begin

      // 2. sistem ilk açýldýðý andaki tarih / saat ile þu andaki tarih / saat alanýný karþýlaþtýr
      // farklý olmasý durumunda (çekirdeðin deðiþmesi halinde) sistemi yeniden baþlat
      if not(CekirdekYuklemeTS = TarihSaat) then
      begin

        G := GAktifMasaustu^.FAtananAlan.Genislik;

        if(Pencere = nil) then
          Pencere := Pencere^.Olustur(GAktifMasaustu, G - 160, 0, 155, 20,
          ptBasliksiz, '', RENK_KIRMIZI);

        if(IslemGostergesi = nil) then
          IslemGostergesi := IslemGostergesi^.Olustur(ktNesne, Pencere, 2, 1, 170, 18);

        IslemGostergesi^.DegerleriBelirle(0, 25);
        IslemGostergesi^.Goster;

        Pencere^.Goster;

        for i := 24 downto 0 do
        begin

          IslemGostergesi^.MevcutDegerYaz(i);

          Sayac := ZamanlayiciSayaci + 10;
          while (Sayac > ZamanlayiciSayaci) do;
        end;

        YenidenBaslat;

        Pencere^.Gizle;

        Sayac := ZamanlayiciSayaci + 500;
        while (Sayac > ZamanlayiciSayaci) do;
      end;
    end;
  end;
end;

end.
