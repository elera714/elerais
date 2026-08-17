{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: srv_kontrol.pas
  Dosya Ýþlevi: dahili seervis: çekirdek yazýlýmýnýn deðiþim kontrolünü gerçekleþtirir

  Güncelleme Tarihi: 17/08/2026

 ==============================================================================}
{$mode objfpc}
unit srv_kontrol;

interface

uses paylasim, gn_pencere, gn_islemgostergesi, dosya, thread;

type
  TServisKontrol = class(TThread)
  public
    constructor Create(AIslemAdi: string; CreateSuspended: Boolean = True); override;
    procedure Execute; override;
  end;

implementation

uses sistem, gn_islevler, zamanlayici;

{==============================================================================
  servis oluþturma kýsmý
 ==============================================================================}
constructor TServisKontrol.Create(AIslemAdi: string; CreateSuspended: Boolean = True);
begin

  inherited Create(AIslemAdi, CreateSuspended);
end;

{==============================================================================
  servis çalýþma kýsmý
  bilgi: 1. sistem çekirdeðinin deðiþip deðiþmediðini dosya tarih/saat bilgisiyle kontrol eder
         2. grafiksel masaüstünde geri sayým ile kullanýcý uyarýlýr
         3. sistem yeniden baþlatýlýr
 ==============================================================================}
procedure TServisKontrol.Execute;
var
  Pencere: TPencere;
  IslemGostergesi: TIslemGostergesi;
  AramaKaydi: TDosyaArama;
  i, G: TISayi4;
  j, j2, Sayac: TSayi4;
  TarihSaat: TTarihSaat;
  DosyaBulundu: Boolean;
begin

  while True do
  begin

    // 5 saniyede bir denetim
    Sayac := GZamanlayicilar.FZamanlayiciSayaci + 5 * 100;
    while (Sayac > GZamanlayicilar.FZamanlayiciSayaci) do;

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

        G := GGNesneler.AktifMasaustu.FAtananAlan.Genislik;

        Pencere := TPencere.Create;
        Pencere.Ozellestir(GGNesneler.AktifMasaustu, G - 160, 0, 155, 20,
          ptBasliksiz, '', RENK_KIRMIZI);

        IslemGostergesi := TIslemGostergesi.Create;
        IslemGostergesi.Ozellestir(ktNesne, Pencere, 2, 1, 170, 18);
        IslemGostergesi.DegerleriBelirle(0, 25);
        IslemGostergesi.Goster;

        Pencere.Goster;

        for i := 24 downto 0 do
        begin

          IslemGostergesi.MevcutDegerYaz(i);

          Sayac := GZamanlayicilar.FZamanlayiciSayaci + 10;
          while (Sayac > GZamanlayicilar.FZamanlayiciSayaci) do;
        end;

        GSistem.YenidenBaslat;

        Pencere.Gizle;

        Sayac := GZamanlayicilar.FZamanlayiciSayaci + 500;
        while (Sayac > GZamanlayicilar.FZamanlayiciSayaci) do;
      end;
    end;
  end;
end;

end.
