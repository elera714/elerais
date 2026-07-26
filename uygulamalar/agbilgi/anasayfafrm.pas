{$mode objfpc}
unit anasayfafrm;

interface

uses n_gorev, gn_pencere, n_genel, _forms, gn_dugme, gn_degerlistesi, n_zamanlayici;

type
  TfrmAnaSayfa = object(TForm)
  private
    FGenel: TGenel;
    FGorev: TGorev;
    FPencere: TPencere;
    FDegerListesi: TDegerListesi;
    FKapat: TDugme;
    FAgBilgisi: TAgBilgisi3;
    FZamanlayici: TZamanlayici;
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

  FPencere.Olustur(-1, 300, 200, 370, 280, ptIletisim, PencereAdi, $FAE6FF);
  if(FPencere.Kimlik < 0) then FGorev.Sonlandir(-1);

  FDegerListesi.Olustur(FPencere.Kimlik, 2, 2, 366, 10 * 24);
  FDegerListesi.BaslikBelirle('Özellik', 'Deðer', 15 * 8);
  FDegerListesi.Goster;

  FKapat.Olustur(FPencere.Kimlik, 290, 250, 70, 20, 'Kapat');
  FKapat.Goster;
end;

procedure TfrmAnaSayfa.Goster;
begin

  FPencere.Gorunum := True;

  FZamanlayici.Olustur(100);
  FZamanlayici.Baslat;
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

    FGenel.AgBilgisiAl(@FAgBilgisi);
    IcerigiGuncelle;
  end
  else if(AOlay.Olay = FO_TIKLAMA) then
  begin

    if(AOlay.Kimlik = FKapat.Kimlik) then
    begin

      FGorev.Sonlandir(-1);
    end;
  end;

  Result := 1;
end;

procedure TfrmAnaSayfa.IcerigiGuncelle;
begin

  FDegerListesi.Temizle;
  FDegerListesi.DegerEkle('MAC Adresi|' + MAC_KarakterKatari(FAgBilgisi.MACAdres), RENK_SIYAH);
  FDegerListesi.DegerEkle('IP6 Adresi|' + IP_KarakterKatari6(PIP6Adres2(@FAgBilgisi.IP6Adres)^), RENK_SIYAH);
  FDegerListesi.DegerEkle('IP4 Adresi|' + IP_KarakterKatari4(FAgBilgisi.IP4Adres), RENK_SIYAH);
  FDegerListesi.DegerEkle('Alt Að Maskesi|' + IP_KarakterKatari4(FAgBilgisi.AltAgMaskesi), RENK_SIYAH);
  FDegerListesi.DegerEkle('Að Geçidi|' + IP_KarakterKatari4(FAgBilgisi.AgGecitAdresi), RENK_SIYAH);
  FDegerListesi.DegerEkle('DHCP Sunucusu|' + IP_KarakterKatari4(FAgBilgisi.DHCPSunucusu), RENK_SIYAH);
  FDegerListesi.DegerEkle('DNS Sunucusu|' + IP_KarakterKatari4(FAgBilgisi.DNSSunucusu), RENK_SIYAH);
  FDegerListesi.DegerEkle('IP Kira Süresi|' + IntToStr(FAgBilgisi.IPKiraSuresi), RENK_SIYAH);
  FDegerListesi.DegerEkle('Gelen Byte|' + IntToStr(FAgBilgisi.GelenByte), RENK_SIYAH);
  FDegerListesi.DegerEkle('Giden Byte|' + IntToStr(FAgBilgisi.GidenByte), RENK_SIYAH);
end;

end.
