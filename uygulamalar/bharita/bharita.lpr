program bharita;
{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: bharita.lpr
  Program Ýþlevi: bellek içerik harita programý

  Güncelleme Tarihi: 05/01/2025

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, gn_durumcubugu, n_zamanlayici, n_genel;

const
  ProgramAdi: string = 'Bellek Haritasý';
  MEVCUTBELLEKADRESI = $510000;   // bellek haritasýnýn çekirdek yazýlýmdaki adresi

var
  Genel: TGenel;
  Gorev: TGorev;
  Pencere: TPencere;
  Zamanlayici: TZamanlayici;
  Olay: TOlay;
  DurumCubugu: TDurumCubugu;
  ToplamRAMBlok, AyrilmisRAMBlok,
  KullanilanRAMBlok, BosRAMBlok,
  RAMUzunlugu, BellekAdresi,
  Sol, Ust: TSayi4;
  s: string;
  p: PSayi1;

procedure NoktaIsaretle(ASol, AUst: TSayi4; ARenk: TRenk);
var
  Sol, Ust: Integer;
begin

  Sol := ASol * 3;
  Ust := AUst * 3;

  Pencere.Tuval.PixelYaz(Sol, Ust, ARenk);
  Pencere.Tuval.PixelYaz(Sol + 1, Ust, ARenk);

  Pencere.Tuval.PixelYaz(Sol, Ust + 1, ARenk);
  Pencere.Tuval.PixelYaz(Sol + 1, Ust + 1, ARenk);
end;

var
  Veriler: array[0..4095] of TSayi1;
  i: TSayi4;
  BellekOku: Boolean;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 5, 5, 161 * 3, 140 * 3, ptBoyutlanabilir, ProgramAdi, RENK_SIYAH);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  DurumCubugu.Olustur(Pencere.Kimlik, 0, 0, 100, 20, 'Boþ Blok Sayýsý: 0');
  DurumCubugu.Goster;

  Pencere.Gorunum := True;

  // 10 saniyelik frekansla güncelle
  Zamanlayici.Olustur(1000);
  Zamanlayici.Baslat;

  while True do
  begin

    Gorev.OlayBekle(Olay);
    if(Olay.Olay = CO_ZAMANLAYICI) then
    begin

      Pencere.Ciz;
    end
    else if(Olay.Olay = CO_CIZIM) then
    begin

      Genel.GenelBellekBilgisiAl(@ToplamRAMBlok, @AyrilmisRAMBlok, @KullanilanRAMBlok,
        @BosRAMBlok, @RAMUzunlugu);

      s := 'Boþ Blok Sayýsý: ' + IntToStr(ToplamRAMBlok);
      s += ' / ';
      s += IntToStr(BosRAMBlok);
      DurumCubugu.DurumYazisiDegistir(s);

      if(ToplamRAMBlok > 0) then
      begin

        BellekOku := False;
        BellekAdresi := MEVCUTBELLEKADRESI;
        Sol := 0; Ust := 0;

        for i := 0 to ToplamRAMBlok - 1 do
        begin

          // her 4096 byte sonrasýnda bir sonraki bellek alanýný oku
          if((i mod 4096) = 0) then BellekOku := True;

          // 4K bellek bilgisi sistemden okunuyor
          if(BellekOku) then
          begin

            BellekOku := False;
            Genel.BellekIcerikOku(Isaretci(BellekAdresi), @Veriler[0], 4096);
            BellekAdresi += 4096;
            p := PByte(@Veriler[0]);
          end;

          if(p^ = 0) then
            NoktaIsaretle(Sol, Ust, $00FF00)
          else if(p^ = 1) then NoktaIsaretle(Sol, Ust, $FF0000);

          Inc(p);

          Inc(Sol);

          // yatay 200 nokta
          if(Sol > 160) then
          begin

            Inc(Ust);
            Sol := 0;
          end;
        end;
      end;
    end;
  end;
end.
