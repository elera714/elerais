{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Program Ad�: agbilgi.lpr
  Program ��levi: a� yap�land�rmas� hakk�nda bilgi verir

  G�ncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
program agbilgi;

uses n_gorev, gn_pencere, gn_dugme, gn_degerlistesi, n_tuval, n_genel;

const
  ProgramAdi: string = 'A� Ayarlar�';

var
  Genel: TGenel;
  Gorev: TGorev;
  Pencere: TPencere;
  DegerListesi: TDegerListesi;
  dugYenile: TDugme;
  Olay: TOlay;
  AgBilgisi: TAgBilgisi;

procedure IcerigiGuncelle;
begin

  DegerListesi.Temizle;
  DegerListesi.DegerEkle('MAC Adresi|' + MAC_KarakterKatari(AgBilgisi.MACAdres));
  DegerListesi.DegerEkle('IP4 Adresi|' + IP_KarakterKatari(AgBilgisi.IP4Adres));
  DegerListesi.DegerEkle('IP4 Alt A� Maskesi|' + IP_KarakterKatari(AgBilgisi.AltAgMaskesi));
  DegerListesi.DegerEkle('A� Ge�idi|' + IP_KarakterKatari(AgBilgisi.AgGecitAdresi));
  DegerListesi.DegerEkle('DHCP Sunucusu|' + IP_KarakterKatari(AgBilgisi.DHCPSunucusu));
  DegerListesi.DegerEkle('DNS Sunucusu|' + IP_KarakterKatari(AgBilgisi.DNSSunucusu));
  DegerListesi.DegerEkle('IP Kira S�resi|' + IntToStr(AgBilgisi.IPKiraSuresi));
end;

begin

  Gorev.Yukle;
  Gorev.Ad := ProgramAdi;

  Pencere.Olustur(-1, 300, 200, 330, 255, ptIletisim, ProgramAdi, $FAE6FF);
  if(Pencere.Kimlik < 0) then Gorev.Sonlandir(-1);

  DegerListesi.Olustur(Pencere.Kimlik, 2, 2, 326, 182);
  DegerListesi.BaslikBelirle('�zellik', 'De�er', 20 * 8);
  DegerListesi.Goster;

  dugYenile.Olustur(Pencere.Kimlik, 250, 225, 70, 20, 'Yenile');
  dugYenile.Goster;

  Pencere.Gorunum := True;

  Genel.AgBilgisiAl(@AgBilgisi);
  IcerigiGuncelle;

  while True do
  begin

    Gorev.OlayBekle(Olay);
    if(Olay.Olay = FO_TIKLAMA) then
    begin

      if(Olay.Kimlik = dugYenile.Kimlik) then
      begin

        Genel.AgBilgisiAl(@AgBilgisi);
        IcerigiGuncelle;
      end;
    end
    else if(Olay.Olay = CO_CIZIM) then
    begin

      Pencere.Tuval.KalemRengi := RENK_KIRMIZI;
      Pencere.Tuval.YaziYaz(2, 187, 'DHCP sunucusundan yeni IP adresi almak');
      Pencere.Tuval.YaziYaz(2, 203, 'i�in Ctrl+2 tu�una bas�n�z.');
    end;
  end;
end.
