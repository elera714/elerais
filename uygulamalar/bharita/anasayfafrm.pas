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
  Veriler: array[0..4095] of TSayi1;
  ToplamRAMBlok, AyrilmisRAMBlok,
  KullanilanRAMBlok, BosRAMBlok,
  RAMUzunlugu, BellekAdresi,
  Sol, Ust, i: TSayi4;
  s: string;
  p: PSayi1;
  BellekOku: Boolean;

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 5, 5, 161 * 3, 140 * 3, ptBoyutlanabilir, PencereAdi, RENK_SIYAH);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FDurumCubugu.Olustur(FPencere.Kimlik, 0, 0, 100, 20, 'Boþ Blok Sayýsý: 0');
  FDurumCubugu.Goster;
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;

  // 10 saniyelik frekansla güncelle
  FZamanlayici.Olustur(1000);
  FZamanlayici.Baslat;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  if(AOlay.Olay = CO_ZAMANLAYICI) then
  begin

    FPencere.Ciz;
  end
  else if(AOlay.Olay = CO_CIZIM) then
  begin

    FGenel.GenelBellekBilgisiAl(@ToplamRAMBlok, @AyrilmisRAMBlok, @KullanilanRAMBlok,
      @BosRAMBlok, @RAMUzunlugu);

    s := 'Boþ Blok Sayýsý: ' + IntToStr(ToplamRAMBlok);
    s += ' / ';
    s += IntToStr(BosRAMBlok);
    FDurumCubugu.DurumYazisiDegistir(s);

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
          FGenel.BellekIcerikOku(Isaretci(BellekAdresi), @Veriler[0], 4096);
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
