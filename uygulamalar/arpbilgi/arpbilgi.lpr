{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Program Adý: arpbilgi.lpr
  Program Ýþlevi: ARP girdileri hakkýnda bilgi verir

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
program arpbilgi;

uses n_gorev, gn_pencere, n_zamanlayici, n_genel;

const
  ProgramAdi: string = 'ARP Girdi Bilgisi';
  ARPGirdiSayisi: string  = 'Toplam ARP Girdi Sayýsý: ';
  Baslik1: string   = 'IP Adresi       MAC Adresi        Sayaç ';
  Baslik2: string  = '--------------- ----------------- ------';

var
  Genel: TGenel;
  Gorev: TGorev;
  Pencere: TPencere;
  Zamanlayici: TZamanlayici;
  Olay: TOlay;
  ARPKayit: TARPKayit;
  ARPKayitSayisi, i, j: TSayi4;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 50, 50, 340, 280, ptIletisim, ProgramAdi, $D8DFB4);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  Pencere.Gorunum := True;

  Zamanlayici.Olustur(100);
  Zamanlayici.Baslat;

  ARPKayitSayisi := 0;

  while True do
  begin

    Gorev.OlayBekle(Olay);
    if(Olay.Olay = CO_ZAMANLAYICI) then
    begin

      ARPKayitSayisi := Genel.ARPKayitSayisiAl;
      Pencere.Ciz;
    end
    else if(Olay.Olay = CO_CIZIM) then
    begin

      Pencere.Tuval.KalemRengi := $39525E;
      Pencere.Tuval.YaziYaz(0, 0 * 16, ARPGirdiSayisi);
      Pencere.Tuval.SayiYaz16(25 * 8, 0 * 16, True, 2, ARPKayitSayisi);

      Pencere.Tuval.YaziYaz(0, 2 * 16, Baslik1);
      Pencere.Tuval.YaziYaz(0, 3 * 16, Baslik2);

      if(ARPKayitSayisi > 0) then
      begin

        for i := 0 to ARPKayitSayisi - 1 do
        begin

          j := Genel.ARPKayitBilgisiAl(i, ARPKayit);
          if(j = 0) then
          begin

            Pencere.Tuval.IPAdresiYaz(0, (i + 1 + 3) * 16, @ARPKayit.IPAdres);
            Pencere.Tuval.MACAdresiYaz(16 * 8, (i + 1 + 3) * 16, @ARPKayit.MACAdres);
            Pencere.Tuval.SayiYaz16(34 * 8, (i + 1 + 3) * 16, True, 4,  ARPKayit.YasamSuresi);
          end;
        end;
      end;
    end;
  end;
end.
