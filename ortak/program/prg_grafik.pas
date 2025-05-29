{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: prg_grafik.pas
  Dosya Ýþlevi: dahili çekirdek programý: nesnelerin grafik kartýna çizimi için

  Güncelleme Tarihi: 26/05/2025

 ==============================================================================}
{$mode objfpc}
unit prg_grafik;

interface

uses paylasim;

const
  P_BASLIK_YUKSEKLIK = 24;
  P_SOL_SAG_KALINLIK = 5;

procedure GrafikYoneticiGorevOlustur(AGorevKimlik: TKimlik; AGorevAdi: string;
  AIslev: TIslev);
procedure GrafikYonetimi;
procedure SistemDegerleriBasla;
procedure SistemDegerleriOlayIsle;

implementation

uses gdt, gorev, genel, zamanlayici, gn_pencere, gn_islemgostergesi, gn_etiket,
  bolumleme, elr1;

var
  SDPencere: PPencere = nil;
  igBellek, igDisk: PIslemGostergesi;
  etkBellek, etkDisk: PEtiket;
  BellekSayac: TSayi4 = 0;
  DiskSayac: TSayi4 = 0;

{==============================================================================
  grafik iþlevlerini yönetecek görevi oluþturur
 ==============================================================================}
procedure GrafikYoneticiGorevOlustur(AGorevKimlik: TKimlik; AGorevAdi: string;
  AIslev: TIslev);
var
  Gorev: PGorev;
  i: TKimlik;
  SeciciCSSiraNo, SeciciDSSiraNo,
  SeciciTSSSiraNo: TSayi4;
begin

  i := AGorevKimlik;

  // uygulamanýn TSS, CS, DS seçicilerini belirle, her bir program 3 seçici içerir
  SeciciCSSiraNo := (i * 3) + 1;
  SeciciDSSiraNo := SeciciCSSiraNo + 1;
  SeciciTSSSiraNo := SeciciDSSiraNo + 1;

  // kod seçicisi (CS)
  // Eriþim  : 1 = mevcut, 00 = DPL0, 11 = kod yazmaç, 0 = dallanýlamaz, 1 = okunabilir, 0 = eriþilmedi
  // Esneklik: 1 = gran = 4K çözünürlük, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SeciciCSSiraNo, 0, $FFFFFFFF, %10011010, %11011111);
  // veri seçicisi (DS)
  // Eriþim  : 1 = mevcut, 00 = DPL0, 10 = veri yazmaç, 0 = artarak büyüyen, 1 = yazýlabilir, 0 = eriþilmedi
  // Esneklik: 1 = gran = 4K çözünürlük, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SeciciDSSiraNo, 0, $FFFFFFFF, %10010010, %11011111);
  // görev seçicisi (TSS)
  // Eriþim  : 1 = mevcut, 00 = DPL0, 010 = 32 bit kullanýlabilir TSS, 0 = meþgul biti (meþgul deðil), 1
  // Esneklik: 1 = gran = 1Byte çözünürlük, 00, 1 = bana tahsis edildi, 0000 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SeciciTSSSiraNo, TSayi4(GorevTSSListesi[AGorevKimlik]), 104,
    %10001001, %00010000);

  // denetçinin kullanacaðý TSS'nin içeriðini sýfýrla
  FillByte(GorevTSSListesi[AGorevKimlik]^, 104, $00);

  GorevTSSListesi[AGorevKimlik]^.EIP := TSayi4(AIslev);    // DPL 0
  GorevTSSListesi[AGorevKimlik]^.EFLAGS := $202;
  GorevTSSListesi[AGorevKimlik]^.ESP := GRAFIK_ESP;
  GorevTSSListesi[AGorevKimlik]^.CS := SeciciCSSiraNo * 8;
  GorevTSSListesi[AGorevKimlik]^.DS := SeciciDSSiraNo * 8;
  GorevTSSListesi[AGorevKimlik]^.ES := SeciciDSSiraNo * 8;
  GorevTSSListesi[AGorevKimlik]^.SS := SeciciDSSiraNo * 8;
  GorevTSSListesi[AGorevKimlik]^.FS := SeciciDSSiraNo * 8;
  GorevTSSListesi[AGorevKimlik]^.GS := SeciciDSSiraNo * 8;
  GorevTSSListesi[AGorevKimlik]^.SS0 := SeciciDSSiraNo * 8;
  GorevTSSListesi[AGorevKimlik]^.ESP0 := GRAFIK_ESP;

  // sistem görev deðerlerini belirle
  GorevListesi[AGorevKimlik]^.GorevSayaci := 0;
  GorevListesi[AGorevKimlik]^.BellekBaslangicAdresi := TSayi4(@GrafikYonetimi);
  GorevListesi[AGorevKimlik]^.BellekUzunlugu := $FFFFFFFF;
  GorevListesi[AGorevKimlik]^.OlaySayisi := 0;
  GorevListesi[AGorevKimlik]^.OlayBellekAdresi := nil;
  GorevListesi[AGorevKimlik]^.AktifMasaustu := nil;
  GorevListesi[AGorevKimlik]^.AktifPencere := nil;

  // sistem görev adý (dosya adý)
  GorevListesi[AGorevKimlik]^.FDosyaAdi := 'cekirdek.bin';
  GorevListesi[AGorevKimlik]^.FProgramAdi := AGorevAdi;

  // sistem görevini çalýþýyor olarak iþaretle
  Gorev := GorevListesi[AGorevKimlik];
  Gorev^.DurumDegistir(AGorevKimlik, gdCalisiyor);

  // çalýþan ve oluþturulan görev deðerlerini belirle
  CalisanGorevSayisi := AGorevKimlik + 1;
end;

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

  etkBellek := etkBellek^.Olustur(ktNesne, SDPencere, 5, 65, 6 * 8, 16, RENK_SIYAH, 'Bellek');
  etkBellek^.Goster;

  igBellek := igBellek^.Olustur(ktNesne, SDPencere, 60, 65, 85, 16);
  igBellek^.DegerleriBelirle(0, GGercekBellek.ToplamBlok * 4096);
  igBellek^.MevcutDegerYaz(0);
  igBellek^.Goster;

  etkDisk := etkDisk^.Olustur(ktNesne, SDPencere, 5, 85, 4 * 8, 16, RENK_SIYAH, 'Disk');
  etkDisk^.Goster;

  igDisk := igDisk^.Olustur(ktNesne, SDPencere, 60, 85, 85, 16);
  igDisk^.DegerleriBelirle(0, 64 * 1024 * 1024);
  igDisk^.MevcutDegerYaz(0);
  igDisk^.Goster;

  SDPencere^.Goster;
end;

procedure SistemDegerleriOlayIsle;
var
  MD: PMantiksalDepolama;
  CizimAlan: TAlan;
  ToplamKullanimByte: TSayi4;
begin

  // $1000 döngüde bir disk kullaným kapasitesinin hesaplanmasý
  Inc(BellekSayac);
  if(BellekSayac = $100) then
  begin

    igBellek^.MevcutDegerYaz(GGercekBellek.KullanilmisBlok * 4096);

    BellekSayac := 0;
  end;

  // $1000 döngüde bir disk kullaným kapasitesinin hesaplanmasý
  Inc(DiskSayac);
  if(DiskSayac = $1000) then
  begin

    MD := SurucuAl('disk2:\');
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
  SDPencere^.YaziYaz(SDPencere, 12, P_BASLIK_YUKSEKLIK + 8, 'ÇKRDK:', RENK_LACIVERT);
  SDPencere^.SayiYaz16(SDPencere, 64, P_BASLIK_YUKSEKLIK + 8, True, 8, SistemSayaci, RENK_LACIVERT);
  SDPencere^.YaziYaz(SDPencere, 12, P_BASLIK_YUKSEKLIK + 24, 'ÇAÐRI:', RENK_LACIVERT);
  SDPencere^.SayiYaz16(SDPencere, 64, P_BASLIK_YUKSEKLIK + 24, True, 8, CagriSayaci, RENK_LACIVERT);
  SDPencere^.YaziYaz(SDPencere, 12, P_BASLIK_YUKSEKLIK + 40, 'GRAFK:', RENK_LACIVERT);
  SDPencere^.SayiYaz16(SDPencere, 64, P_BASLIK_YUKSEKLIK + 40, True, 8, GrafikSayaci, RENK_LACIVERT);
end;

end.
