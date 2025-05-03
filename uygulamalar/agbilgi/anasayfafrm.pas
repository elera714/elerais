{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_genel, _forms, gn_dugme, gn_degerlistesi, n_tuval;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGenel: TGenel;
    FGorev: TGorev;
    FPencere: TPencere;
    FDegerListesi: TDegerListesi;
    FYenile: TDugme;
    FAgBilgisi: TAgBilgisi;
    procedure IcerigiGuncelle;
  public
    procedure Olustur;
    procedure Goster;
    function OlaylariIsle(AOlay: TOlay): TISayi4;
  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

const
  PencereAdi: string = 'Að Ayarlarý';

procedure TfrmAnaSayfa.Olustur;
begin

  FPencere.Olustur(-1, 300, 200, 330, 255, ptIletisim, PencereAdi, $FAE6FF);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FDegerListesi.Olustur(FPencere.Kimlik, 2, 2, 326, 182);
  FDegerListesi.BaslikBelirle('Özellik', 'Deðer', 20 * 8);
  FDegerListesi.Goster;

  FYenile.Olustur(FPencere.Kimlik, 250, 225, 70, 20, 'Yenile');
  FYenile.Goster;
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;

  FGenel.AgBilgisiAl(@FAgBilgisi);
  IcerigiGuncelle;
end;

function TfrmAnaSayfa.OlaylariIsle(AOlay: TOlay): TISayi4;
begin

  // çekirdek tarafýndan gönderilen programýn kendisini sonlandýrma talimatý
  if(AOlay.Olay = CO_SONLANDIR) then
  begin

    FGorev.Sonlandir(-1);
  end
  else if(AOlay.Olay = FO_TIKLAMA) then
  begin

    if(AOlay.Kimlik = FYenile.Kimlik) then
    begin

      FGenel.AgBilgisiAl(@FAgBilgisi);
      IcerigiGuncelle;
    end;
  end
  else if(AOlay.Olay = CO_CIZIM) then
  begin

    FPencere.Tuval.KalemRengi := RENK_KIRMIZI;
    FPencere.Tuval.YaziYaz(2, 187, 'DHCP sunucusundan yeni IP adresi almak');
    FPencere.Tuval.YaziYaz(2, 203, 'için Ctrl+2 tuþuna basýnýz.');
  end;

  Result := 1;
end;

procedure TfrmAnaSayfa.IcerigiGuncelle;
begin

  FDegerListesi.Temizle;
  FDegerListesi.DegerEkle('MAC Adresi|' + MAC_KarakterKatari(FAgBilgisi.MACAdres), RENK_SIYAH);
  FDegerListesi.DegerEkle('IP4 Adresi|' + IP_KarakterKatari(FAgBilgisi.IP4Adres), RENK_SIYAH);
  FDegerListesi.DegerEkle('IP4 Alt Að Maskesi|' + IP_KarakterKatari(FAgBilgisi.AltAgMaskesi), RENK_SIYAH);
  FDegerListesi.DegerEkle('Að Geçidi|' + IP_KarakterKatari(FAgBilgisi.AgGecitAdresi), RENK_SIYAH);
  FDegerListesi.DegerEkle('DHCP Sunucusu|' + IP_KarakterKatari(FAgBilgisi.DHCPSunucusu), RENK_SIYAH);
  FDegerListesi.DegerEkle('DNS Sunucusu|' + IP_KarakterKatari(FAgBilgisi.DNSSunucusu), RENK_SIYAH);
  FDegerListesi.DegerEkle('IP Kira Süresi|' + IntToStr(FAgBilgisi.IPKiraSuresi), RENK_SIYAH);
end;

end.
