{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_zamanlayici, n_genel, _forms, gn_durumcubugu;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGenel: TGenel;
    FGorev: TGorev;
    FPencere: TPencere;
    FZamanlayici: TZamanlayici;
    FDurumCubugu: TDurumCubugu;
    procedure NoktaIsaretle(ASol, AUst: TSayi4; ARenk: TRenk);
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Bellek Haritasý';
  MEVCUTBELLEKADRESI = $510000;   // bellek haritasýnýn çekirdek yazýlýmdaki adresi

var
  Veriler: array[0..1023] of TSayi4;
  ToplamRAMBlok, AyrilmisRAMBlok,
  KullanilanRAMBlok, BosRAMBlok,
  RAMUzunlugu, BellekAdresi,
  Sol, Ust, i,
  OkunacakRAMBlok,
  OkunacakByte: TSayi4;
  s: string;
  p: PSayi4;

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 5, 5, 130 * 3, 180 * 3, ptBoyutlanabilir, PencereAdi, RENK_GRI);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FDurumCubugu.Olustur(FPencere.Kimlik, 0, 0, 100, 20, 'Boþ Blok Sayýsý: 0');
  FDurumCubugu.Goster;
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;

  // 5 saniyelik frekansla güncelle
  FZamanlayici.Olustur(5 * 100);
  FZamanlayici.Baslat;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  // çekirdek tarafýndan gönderilen programýn kendisini sonlandýrma talimatý
  if(AOlay.Olay = CO_SONLANDIR) then
  begin

    FGorev.Sonlandir(-1);
  end
  else if(AOlay.Olay = CO_ZAMANLAYICI) or (AOlay.Olay = CO_CIZIM) then
  begin

    FGenel.GenelBellekBilgisiAl(@ToplamRAMBlok, @AyrilmisRAMBlok, @KullanilanRAMBlok,
      @BosRAMBlok, @RAMUzunlugu);

    s := 'Boþ Blok Sayýsý: ' + IntToStr(ToplamRAMBlok);
    s += ' / ';
    s += IntToStr(BosRAMBlok);
    FDurumCubugu.DurumYazisiDegistir(s);

    if(ToplamRAMBlok > 0) then
    begin

      BellekAdresi := MEVCUTBELLEKADRESI;
      OkunacakRAMBlok := ToplamRAMBlok;
      Sol := 0; Ust := 0;

      repeat

        if(OkunacakRAMBlok > 1024) then
        begin

          OkunacakByte := 1024;
          OkunacakRAMBlok := OkunacakRAMBlok - 1024;
        end
        else
        begin

          OkunacakByte := OkunacakRAMBlok;
          OkunacakRAMBlok := 0;
        end;

        FGenel.BellekIcerikOku(Isaretci(BellekAdresi), @Veriler[0], OkunacakByte * 4);
        BellekAdresi := BellekAdresi + (OkunacakByte * 4);
        p := PSayi4(@Veriler[0]);

        for i := 0 to OkunacakByte - 1 do
        begin

          if(p^ = $00000000) then
            NoktaIsaretle(Sol, Ust, $00FF00)
          else NoktaIsaretle(Sol, Ust, $FF0000);

          Inc(p);

          // yatay 128 nokta
          Inc(Sol);
          if(Sol > 127) then
          begin

            Inc(Ust);
            Sol := 0;
          end;
        end;

      until OkunacakRAMBlok = 0;
    end;
  end;

  Result := 1;
end;

procedure TfrmAnaSayfa.NoktaIsaretle(ASol, AUst: TSayi4; ARenk: TRenk);
var
  Sol, Ust: Integer;
begin

  Sol := ASol * 3;
  Ust := AUst * 3;

  FPencere.Tuval.PixelYaz(Sol, Ust, ARenk);
  FPencere.Tuval.PixelYaz(Sol + 1, Ust, ARenk);
  FPencere.Tuval.PixelYaz(Sol, Ust + 1, ARenk);
  FPencere.Tuval.PixelYaz(Sol + 1, Ust + 1, ARenk);
end;

end.
