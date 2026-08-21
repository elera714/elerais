{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: srv_grafik.pas
  Dosya Ýþlevi: dahili servis: çekirdek içi grafiksel bilgilendirme

  Güncelleme Tarihi: 21/08/2026

 ==============================================================================}
{$mode objfpc}
unit srv_grafik;

interface

uses paylasim, gn_pencere, gn_islemgostergesi, thread;

const
  P_BASLIK_YUKSEKLIK = 24;
  P_SOL_SAG_KALINLIK = 5;

type
  TServisGrafik = class(TThread)
  public
    constructor Create(AIslemAdi: string; CreateSuspended: Boolean = True); override;
    procedure Execute; override;
    procedure Basla;
    procedure OlaylariIsle;
  end;

implementation

uses gn_etiket, mdepolama, elr1, sistemmesaj, gorselnesne, gercekbellek, sistem,
  src_vesa20, gn_islevler, zamanlayici;

var
  SDPencere: TPencere;
  igBellek, igDisk: TIslemGostergesi;
  etkBellek, etkDisk: TEtiket;
  BellekSayac: TSayi4;
  DiskSayac: TSayi4;

{==============================================================================
  servis oluþturma kýsmý
 ==============================================================================}
constructor TServisGrafik.Create(AIslemAdi: string; CreateSuspended: Boolean = True);
begin

  inherited Create(AIslemAdi, CreateSuspended);

  BellekSayac := 0;
  DiskSayac := 0;
end;

{==============================================================================
  servis çalýþma kýsmý
 ==============================================================================}
procedure TServisGrafik.Execute;
begin

  GZamanlayicilar.BekleMS(300);

  Basla;

  while True do
  begin

    Inc(GSistem.FGrafikSayaci);

    OlaylariIsle;

    GEkranKartSurucusu.EkranBelleginiGuncelle;
  end;
end;

{==============================================================================
  servis kod baþlama kodlarý
 ==============================================================================}
procedure TServisGrafik.Basla;
var
  Sol: TISayi4;
begin

  if(GGNesneler.ToplamMasaustu > 0) then
  begin

    Sol := GGNesneler.AktifMasaustu.FAtananAlan.Genislik - 180;

    SDPencere := TPencere.Create;
    SDPencere.Ozellestir(GGNesneler.AktifMasaustu, Sol, 22, 170, 105,
      ptIletisim, 'Sistem Durumu', RENK_BEYAZ);

    etkBellek := TEtiket.Create;
    etkBellek.Ozellestir(ktNesne, SDPencere, 5, 65, 6 * 8, 16, RENK_TURKUAZ, 'Bellek');
    etkBellek.Goster;

    igBellek := TIslemGostergesi.Create;
    igBellek.Ozellestir(ktNesne, SDPencere, 60, 65, 105, 16);
    igBellek.DegerleriBelirle(0, GercekBellek0.ToplamBlok);
    igBellek.MevcutDegerYaz(0);
    igBellek.Goster;

    etkDisk := TEtiket.Create;
    etkDisk.Ozellestir(ktNesne, SDPencere, 5, 85, 4 * 8, 16, RENK_TURKUAZ, 'Disk');
    etkDisk.Goster;

    igDisk := TIslemGostergesi.Create;
    igDisk.Ozellestir(ktNesne, SDPencere, 60, 85, 105, 16);
    igDisk.DegerleriBelirle(0, (64 * 1024 * 1024) div 512);
    igDisk.MevcutDegerYaz(0);
    igDisk.Goster;

    SDPencere.Goster;
  end;
end;

{==============================================================================
  servis olaylarýnýn iþlendiði kýsým
 ==============================================================================}
procedure TServisGrafik.OlaylariIsle;
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

    igBellek.MevcutDegerYaz(GercekBellek0.KullanilmisBlok);
    BellekSayac := 0;
  end;

  // 5000 döngüde bir disk kullaným kapasitesinin hesaplanmasý
  Inc(DiskSayac);
  if(DiskSayac = 100000) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_PEMBE, 'Disk kullaným alaný hesaplanýyor...', []);

    MD := GMantiksalDepolama.SurucuBul('disk2:\');
    if not(MD = nil) then
    begin

      SektorSayisi := 0;

      Sonuc := SHTToplamKullanim(@MD, SektorSayisi);
      if(Sonuc = HATA_YOK) then

        igDisk.MevcutDegerYaz(SektorSayisi)

      else SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'SHTToplamKullanim hatasý: %d', [Sonuc]);
    end;

    DiskSayac := 0;
  end;

  CizimAlani := SDPencere.FCizimAlani;
  CizimAlani.Sol := CizimAlani.Sol + 5;
  CizimAlani.Sag := CizimAlani.Sag + 5;
  CizimAlani.Ust := CizimAlani.Ust + P_BASLIK_YUKSEKLIK;
  CizimAlani.Alt := CizimAlani.Ust + 60;
  SDPencere.DikdortgenDoldur(SDPencere, CizimAlani, RENK_SIYAH, RENK_BEYAZ);

  SDPencere.YaziYaz(SDPencere, 12, P_BASLIK_YUKSEKLIK + 8, 'Çkrdk:', RENK_TURKUAZ);
  SDPencere.SayiYaz16(SDPencere, 64, P_BASLIK_YUKSEKLIK + 8, False, 8,
    GSistem.FSistemSayaci, RENK_TURKUAZ);
  SDPencere.YaziYaz(SDPencere, 12, P_BASLIK_YUKSEKLIK + 24, 'Zaman:', RENK_MOR);
  SDPencere.SayiYaz10(SDPencere, 64, P_BASLIK_YUKSEKLIK + 24,
    GZamanlayicilar.FZamanlayiciSayaci div CALISMA_FREKANSI, RENK_MOR);
  SDPencere.YaziYaz(SDPencere, 12, P_BASLIK_YUKSEKLIK + 40, 'Nesne:', RENK_KIRMIZI);
  SDPencere.SayiYaz10(SDPencere, 64, P_BASLIK_YUKSEKLIK + 40,
    GGNesneler.FToplamGorselNesne, RENK_KIRMIZI);
end;

end.
