program bharita;
{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: bharita.lpr
  Program ��levi: bellek i�erik harita program�

  G�ncelleme Tarihi: 20/09/2024

  Not:
    program�n �al��mas� i�in gereken 8K bellek makinenin kilitlenmesine sebep oldu�u
    ve dinamik haf�za hen�z tasarlanmad���ndan dolay� 4K'l�k par�a bellek kullan�lm��t�r.

 ==============================================================================}
{$mode objfpc}
uses n_gorev, gn_pencere, gn_durumcubugu, n_zamanlayici, n_genel;

const
  ProgramAdi: string = 'Bellek Haritas�';
  // MEVCUTBELLEKADRESI = bellek haritas�n�n adresi
  MEVCUTBELLEKADRESI = $510000;

var
  Genel: TGenel;
  Gorev: TGorev;
  Pencere: TPencere;
  Zamanlayici: TZamanlayici;
  Olay: TOlay;
  DurumCubugu: TDurumCubugu;
  ToplamRAMBlok, AyrilmisRAMBlok,
  KullanilanRAMBlok, BosRAMBlok,
  RAMUzunlugu: TSayi4;
  s: string;
  Sol, Ust: TSayi4;
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

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 5, 5, (128 * 3) - 1, (64 * 3) + 20 - 1, ptBoyutlanabilir,
    ProgramAdi, RENK_SIYAH);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  DurumCubugu.Olustur(Pencere.Kimlik, 0, 0, 100, 20, 'Bo� Blok Say�s�: 0');
  DurumCubugu.Goster;

  Pencere.Gorunum := True;

  // 3 saniyelik frekansla g�ncelle
  Zamanlayici.Olustur(300);
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

      s := 'Bo� Blok Say�s�: ' + IntToStr(ToplamRAMBlok);
      s += ' / ';
      s += IntToStr(BosRAMBlok);
      DurumCubugu.DurumYazisiDegistir(s);

//      Pencere.Tuval.Dikdortgen(0, 0, 128 * 3, 64 * 3, $000000, True);

      // 1. 4K bellek sistemden okunuyor
      Genel.BellekIcerikOku(ISaretci(MEVCUTBELLEKADRESI), @Veriler[0], 4096);

      p := PByte(@Veriler[0]);
      for Ust := 0 to 31 do
      begin

        for Sol := 0 to 127 do
        begin

          if(p^ = 0) then

            NoktaIsaretle(Sol, Ust, $00FF00)
          else if(p^ = 1) then NoktaIsaretle(Sol, Ust, $FF0000);

          Inc(p);
        end;
      end;

      // 2. 4K bellek sistemden okunuyor
      Genel.BellekIcerikOku(Pointer(MEVCUTBELLEKADRESI + 4096), @Veriler[0], 4096);

      p := PByte(@Veriler[0]);
      for Ust := 32 to 63 do
      begin

        for Sol := 0 to 127 do
        begin

          if(p^ = 0) then

            NoktaIsaretle(Sol, Ust, $00FF00)
          else if(p^ = 1) then NoktaIsaretle(Sol, Ust, $FF0000);

          Inc(p);
        end;
      end;
    end;
  end;
end.
