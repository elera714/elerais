{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_zamanlayici, n_genel, _forms;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGenel: TGenel;
    FGorev: TGorev;
    FPencere: TPencere;
    FZamanlayici: TZamanlayici;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;
  ARPKayit: TARPKayit;
  ARPKayitSayisi, i, j: TSayi4;

implementation

const
  PencereAdi: string = 'ARP Tablosu';
  ARPGirdiSayisi: string  = 'Toplam ARP Girdi Sayýsý: ';
  Baslik1: string   = 'IP Adresi       MAC Adresi        Sayaç ';
  Baslik2: string  = '--------------- ----------------- ------';

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 50, 50, 340, 280, ptIletisim, PencereAdi, $D8DFB4);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;

  FZamanlayici.Olustur(100);
  FZamanlayici.Baslat;

  ARPKayitSayisi := 0;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  // çekirdek tarafýndan gönderilen programýn kendisini sonlandýrma talimatý
  if(AOlay.Olay = CO_SONLANDIR) then
  begin

    FGorev.Sonlandir(-1);
  end
  else if(AOlay.Olay = CO_ZAMANLAYICI) then
  begin

    ARPKayitSayisi := FGenel.ARPKayitSayisiAl;
    FPencere.Ciz;
  end
  else if(AOlay.Olay = CO_CIZIM) then
  begin

    FPencere.Tuval.KalemRengi := $39525E;
    FPencere.Tuval.YaziYaz(0, 0 * 16, ARPGirdiSayisi);
    FPencere.Tuval.SayiYaz16(25 * 8, 0 * 16, True, 2, ARPKayitSayisi);

    FPencere.Tuval.YaziYaz(0, 2 * 16, Baslik1);
    FPencere.Tuval.YaziYaz(0, 3 * 16, Baslik2);

    if(ARPKayitSayisi > 0) then
    begin

      for i := 0 to ARPKayitSayisi - 1 do
      begin

        j := FGenel.ARPKayitBilgisiAl(i, ARPKayit);
        if(j = 0) then
        begin

          FPencere.Tuval.IPAdresiYaz(0, (i + 1 + 3) * 16, @ARPKayit.IPAdres);
          FPencere.Tuval.MACAdresiYaz(16 * 8, (i + 1 + 3) * 16, @ARPKayit.MACAdres);
          FPencere.Tuval.SayiYaz16(34 * 8, (i + 1 + 3) * 16, True, 4,  ARPKayit.YasamSuresi);
        end;
      end;
    end;
  end;

  Result := 1;
end;

end.
