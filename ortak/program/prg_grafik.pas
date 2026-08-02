{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: prg_grafik.pas
  Dosya Ýþlevi: dahili çekirdek programý: nesnelerin grafik kartýna çizimi için

  Güncelleme Tarihi: 19/07/2026

 ==============================================================================}
{$mode objfpc}
unit prg_grafik;

interface

uses paylasim;

const
  P_BASLIK_YUKSEKLIK = 24;
  P_SOL_SAG_KALINLIK = 5;

type
  TPrgGrafik = class
  public
    constructor Create;
    procedure GrafikYonetimi;
    procedure SistemDegerleriBasla;
    procedure SistemDegerleriOlayIsle;
  end;

var
  GPrgGrafik: TPrgGrafik;

implementation

uses genel, gn_pencere, gn_islemgostergesi, gn_etiket, mdepolama, elr1, sistemmesaj,
  gorselnesne, gercekbellek, src_vesa20;

var
  SDPencere: PPencere = nil;
  igBellek, igDisk: PIslemGostergesi;
  etkBellek, etkDisk: PEtiket;
  BellekSayac: TSayi4 = 0;
  DiskSayac: TSayi4 = 0;

constructor TPrgGrafik.Create;
begin

end;

// tüm masaüstü ve alt nesne çizimlerinin ekran kartýna aktarýldýðý nokta burasýdýr
procedure TPrgGrafik.GrafikYonetimi;
begin

  SistemDegerleriBasla;

  while True do
  begin

    Inc(GrafikSayaci);

    SistemDegerleriOlayIsle;

    GEkranKartSurucusu.EkranBelleginiGuncelle;
  end;
end;

procedure TPrgGrafik.SistemDegerleriBasla;
var
  Sol: TISayi4;
begin

  if(GGorselNesneler.ToplamMasaustu > 0) then
  begin

    Sol := GAktifMasaustu^.F0.FAtananAlan.Genislik - 180;

    SDPencere := SDPencere^.Olustur(nil, Sol, 22, 170, 105, ptIletisim, 'Sistem Durumu', RENK_BEYAZ);

    etkBellek := etkBellek^.Olustur(ktNesne, SDPencere, 5, 65, 6 * 8, 16, RENK_TURKUAZ, 'Bellek');
    etkBellek^.Goster;

    igBellek := igBellek^.Olustur(ktNesne, SDPencere, 60, 65, 105, 16);
    igBellek^.DegerleriBelirle(0, GercekBellek0.ToplamBlok);
    igBellek^.MevcutDegerYaz(0);
    igBellek^.Goster;

    etkDisk := etkDisk^.Olustur(ktNesne, SDPencere, 5, 85, 4 * 8, 16, RENK_TURKUAZ, 'Disk');
    etkDisk^.Goster;

    igDisk := igDisk^.Olustur(ktNesne, SDPencere, 60, 85, 105, 16);
    igDisk^.DegerleriBelirle(0, (64 * 1024 * 1024) div 512);
    igDisk^.MevcutDegerYaz(0);
    igDisk^.Goster;

    SDPencere^.Goster;
  end;
end;

procedure TPrgGrafik.SistemDegerleriOlayIsle;
var
  MD: TMDNesne;
  CizimAlani: TAlan;
  SektorSayisi: TSayi4;
  Sonuc: TISayi4;
begin

  if(SDPencere = nil) then Exit;

  // 100 döngüde bir bellek kullaným kapasitesinin hesaplanmasý
  Inc(BellekSayac);
  if(BellekSayac = 100) then
  begin

    igBellek^.MevcutDegerYaz(GercekBellek0.KullanilmisBlok);
    BellekSayac := 0;
  end;

  // 5000 döngüde bir disk kullaným kapasitesinin hesaplanmasý
  Inc(DiskSayac);
  if(DiskSayac = 5000) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_PEMBE, 'Disk kullaným alaný hesaplanýyor...', []);

    MD := GMantiksalDepolama.SurucuBul('disk2:\');
    if not(MD = nil) then
    begin

      SektorSayisi := 0;

      Sonuc := SHTToplamKullanim(@MD, SektorSayisi);
      if(Sonuc = HATA_YOK) then

        igDisk^.MevcutDegerYaz(SektorSayisi)

      else SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'SHTToplamKullanim hatasý: %d', [Sonuc]);
    end;

    DiskSayac := 0;
  end;

  CizimAlani := SDPencere^.F0.FCizimAlani;
  CizimAlani.Sol := CizimAlani.Sol + 5;
  CizimAlani.Sag := CizimAlani.Sag + 5;
  CizimAlani.Ust := CizimAlani.Ust + P_BASLIK_YUKSEKLIK;
  CizimAlani.Alt := CizimAlani.Ust + 60;
  SDPencere^.DikdortgenDoldur(SDPencere, CizimAlani, RENK_SIYAH, RENK_BEYAZ);

  SDPencere^.YaziYaz(SDPencere, 12, P_BASLIK_YUKSEKLIK + 8, 'Çkrdk:', RENK_TURKUAZ);
  SDPencere^.SayiYaz16(SDPencere, 64, P_BASLIK_YUKSEKLIK + 8, False, 8, SistemSayaci, RENK_MAVI);
  SDPencere^.YaziYaz(SDPencere, 12, P_BASLIK_YUKSEKLIK + 24, '-----:', RENK_MOR);
  SDPencere^.SayiYaz16(SDPencere, 64, P_BASLIK_YUKSEKLIK + 24, False, 8, 0, RENK_MAVI);
  SDPencere^.YaziYaz(SDPencere, 12, P_BASLIK_YUKSEKLIK + 40, '-----:', RENK_KIRMIZI);
  SDPencere^.SayiYaz10(SDPencere, 64, P_BASLIK_YUKSEKLIK + 40, 0, RENK_LACIVERT);
end;

end.
