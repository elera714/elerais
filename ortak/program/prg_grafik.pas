{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: prg_grafik.pas
  Dosya Ýþlevi: dahili çekirdek programý: nesnelerin grafik kartýna çizimi için

  Güncelleme Tarihi: 31/05/2025

 ==============================================================================}
{$mode objfpc}
unit prg_grafik;

interface

uses paylasim, fdepolama;

const
  P_BASLIK_YUKSEKLIK = 24;
  P_SOL_SAG_KALINLIK = 5;

procedure GrafikYonetimi;
procedure SistemDegerleriBasla;
procedure SistemDegerleriOlayIsle;

implementation

uses genel, gn_pencere, gn_islemgostergesi, gn_etiket, mdepolama, elr1, sistemmesaj;

var
  SDPencere: PPencere = nil;
  igBellek, igDisk: PIslemGostergesi;
  etkBellek, etkDisk: PEtiket;
  BellekSayac: TSayi4 = 0;
  DiskSayac: TSayi4 = 0;

// tüm masaüstü ve alt nesne çizimlerinin ekran kartýna aktarýldýðý nokta burasýdýr
procedure GrafikYonetimi;
begin

  SistemDegerleriBasla;

  while True do
  begin

    Inc(GrafikSayaci);

    SistemDegerleriOlayIsle;

    GEkranKartSurucusu.EkranBelleginiGuncelle;
  end;
end;

procedure SistemDegerleriBasla;
var
  Sol: TISayi4;
begin

  Sol := GAktifMasaustu^.FBoyut.Genislik - 166;

  SDPencere := SDPencere^.Olustur(nil, Sol, 10, 150, 105, ptIletisim, 'Sistem Durumu', RENK_BEYAZ);

  etkBellek := etkBellek^.Olustur(ktNesne, SDPencere, 5, 65, 6 * 8, 16, RENK_TURKUAZ, 'Bellek');
  etkBellek^.Goster;

  igBellek := igBellek^.Olustur(ktNesne, SDPencere, 60, 65, 85, 16);
  igBellek^.DegerleriBelirle(0, GGercekBellek.ToplamBlok * 4096);
  igBellek^.MevcutDegerYaz(0);
  igBellek^.Goster;

  etkDisk := etkDisk^.Olustur(ktNesne, SDPencere, 5, 85, 4 * 8, 16, RENK_TURKUAZ, 'Disk');
  etkDisk^.Goster;

  igDisk := igDisk^.Olustur(ktNesne, SDPencere, 60, 85, 85, 16);
  igDisk^.DegerleriBelirle(0, 64 * 1024 * 1024);
  igDisk^.MevcutDegerYaz(0);
  igDisk^.Goster;

  SDPencere^.Goster;
end;

procedure SistemDegerleriOlayIsle;
var
  MD: PMDNesne;
  CizimAlan: TAlan;
  ToplamKullanimByte: TSayi4;
begin

  // $1000 döngüde bir disk kullaným kapasitesinin hesaplanmasý
  Inc(BellekSayac);
  if(BellekSayac = 2000) then
  begin

    igBellek^.MevcutDegerYaz(GGercekBellek.KullanilmisBlok * 4096);

    BellekSayac := 0;
  end;

  // 1000 döngüde bir disk kullaným kapasitesinin hesaplanmasý
  Inc(DiskSayac);
  if(DiskSayac = 2000) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Disk kullaným alaný hesaplanýyor...', []);

    MD := MantiksalDepolama0.SurucuAl('disk2:\');
    if not(MD = nil) then
    begin

      ToplamKullanimByte := SHTToplamKullanim(MD) * 512;
    end else ToplamKullanimByte := 0;

    igDisk^.MevcutDegerYaz(ToplamKullanimByte);

    DiskSayac := 0;
  end;

  CizimAlan := SDPencere^.FCizimAlan;
  CizimAlan.Sol += 5;
  CizimAlan.Sag += 5;
  CizimAlan.Ust += P_BASLIK_YUKSEKLIK;
  CizimAlan.Alt := CizimAlan.Ust + 60;
  SDPencere^.DikdortgenDoldur(SDPencere, CizimAlan, RENK_SIYAH, RENK_BEYAZ);
  SDPencere^.YaziYaz(SDPencere, 12, P_BASLIK_YUKSEKLIK + 8, 'ÇKRDK:', RENK_TURKUAZ);
  SDPencere^.SayiYaz16(SDPencere, 64, P_BASLIK_YUKSEKLIK + 8, True, 8, SistemSayaci, RENK_GRI);
  {SDPencere^.YaziYaz(SDPencere, 12, P_BASLIK_YUKSEKLIK + 24, 'ÇAÐRI:', RENK_TURKUAZ);
  SDPencere^.SayiYaz16(SDPencere, 64, P_BASLIK_YUKSEKLIK + 24, True, 8, CagriSayaci, RENK_GRI);
  SDPencere^.YaziYaz(SDPencere, 12, P_BASLIK_YUKSEKLIK + 40, 'GRAFK:', RENK_TURKUAZ);
  SDPencere^.SayiYaz16(SDPencere, 64, P_BASLIK_YUKSEKLIK + 40, True, 8, GrafikSayaci, RENK_GRI);}
  SDPencere^.YaziYaz(SDPencere, 12, P_BASLIK_YUKSEKLIK + 24, 'YBTOP:', RENK_TURKUAZ);
  SDPencere^.SayiYaz10(SDPencere, 64, P_BASLIK_YUKSEKLIK + 24, GGercekBellek.FToplamYBYBellek, RENK_MAVI);
  SDPencere^.YaziYaz(SDPencere, 12, P_BASLIK_YUKSEKLIK + 40, 'YBKUL:', RENK_TURKUAZ);
  SDPencere^.SayiYaz10(SDPencere, 64, P_BASLIK_YUKSEKLIK + 40, ZamanlayiciSayaci, RENK_MAVI);
  //SDPencere^.SayiYaz10(SDPencere, 64, P_BASLIK_YUKSEKLIK + 40, GGercekBellek.FKullanilanYBYBellek, RENK_MAVI);
end;

end.
