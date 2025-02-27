{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: prg_grafik.pas
  Dosya Ýþlevi: dahili çekirdek programý: nesnelerin grafik kartýna çizimi için

  Güncelleme Tarihi: 27/02/2025

 ==============================================================================}
{$mode objfpc}
unit prg_grafik;

interface

procedure GrafikYoneticiGorevOlustur;
procedure GrafikYonetimi;
procedure SistemDegerleriBasla;
procedure SistemDegerleriOlayIsle;

implementation

uses gdt, gorev, paylasim, genel, zamanlayici, gn_pencere;

var
  SDPencere: PPencere = nil;

{==============================================================================
  grafik iþlevlerini yönetecek görevi oluþturur
 ==============================================================================}
procedure GrafikYoneticiGorevOlustur;
var
  Gorev: PGorev;
begin

  // kod seçicisi (CS)
  // Eriþim  : 1 = mevcut, 00 = DPL0, 11 = kod yazmaç, 0 = dallanýlamaz, 1 = okunabilir, 0 = eriþilmedi
  // Esneklik: 1 = gran = 4K çözünürlük, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SECICI_GRAFIK_KOD, 0, $FFFFFFFF, %10011010, %11011111);
  // veri seçicisi (DS)
  // Eriþim  : 1 = mevcut, 00 = DPL0, 10 = veri yazmaç, 0 = artarak büyüyen, 1 = yazýlabilir, 0 = eriþilmedi
  // Esneklik: 1 = gran = 4K çözünürlük, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SECICI_GRAFIK_VERI, 0, $FFFFFFFF, %10010010, %11011111);
  // görev seçicisi (TSS)
  // Eriþim  : 1 = mevcut, 00 = DPL0, 010 = 32 bit kullanýlabilir TSS, 0 = meþgul biti (meþgul deðil), 1
  // Esneklik: 1 = gran = 1Byte çözünürlük, 00, 1 = bana tahsis edildi, 0000 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SECICI_GRAFIK_TSS, TSayi4(GorevTSSListesi[2]), 104,
    %10001001, %00010000);

  // denetçinin kullanacaðý TSS'nin içeriðini sýfýrla
  FillByte(GorevTSSListesi[2]^, 104, $00);

  GorevTSSListesi[2]^.EIP := TSayi4(@GrafikYonetimi);    // DPL 0
  GorevTSSListesi[2]^.EFLAGS := $202;
  GorevTSSListesi[2]^.ESP := GRAFIK_ESP;
  GorevTSSListesi[2]^.CS := SECICI_GRAFIK_KOD * 8;
  GorevTSSListesi[2]^.DS := SECICI_GRAFIK_VERI * 8;
  GorevTSSListesi[2]^.ES := SECICI_GRAFIK_VERI * 8;
  GorevTSSListesi[2]^.SS := SECICI_GRAFIK_VERI * 8;
  GorevTSSListesi[2]^.FS := SECICI_GRAFIK_VERI * 8;
  GorevTSSListesi[2]^.GS := SECICI_GRAFIK_VERI * 8;
  GorevTSSListesi[2]^.SS0 := SECICI_GRAFIK_VERI * 8;
  GorevTSSListesi[2]^.ESP0 := GRAFIK_ESP;

  // sistem görev deðerlerini belirle
  GorevListesi[2]^.GorevSayaci := 0;
  GorevListesi[2]^.BellekBaslangicAdresi := TSayi4(@GrafikYonetimi);
  GorevListesi[2]^.BellekUzunlugu := $FFFFFFFF;
  GorevListesi[2]^.OlaySayisi := 0;
  GorevListesi[2]^.OlayBellekAdresi := nil;
  GorevListesi[2]^.AktifMasaustu := nil;
  GorevListesi[2]^.AktifPencere := nil;

  // sistem görev adý (dosya adý)
  GorevListesi[2]^.FDosyaAdi := 'grafik.bin';
  GorevListesi[2]^.FProgramAdi := 'Grafik Yöneticisi';

  // sistem görevini çalýþýyor olarak iþaretle
  Gorev := GorevListesi[2];
  Gorev^.DurumDegistir(2, gdCalisiyor);

  // çalýþan ve oluþturulan görev deðerlerini belirle
  CalisanGorevSayisi := 3;
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
  SDPencere := SDPencere^.Olustur(nil, Sol, 10, 156, 70, ptBasliksiz,
    'Sistem Durumu', 0);
  SDPencere^.Goster;
end;

procedure SistemDegerleriOlayIsle;
var
  CizimAlan: TAlan;
begin

  CizimAlan := SDPencere^.FCizimAlan;
  SDPencere^.DikdortgenDoldur(SDPencere, CizimAlan, RENK_SIYAH, $CCFFFF);
  SDPencere^.YaziYaz(SDPencere, 12, 10, 'ÇKRDK:', RENK_LACIVERT);
  SDPencere^.SayiYaz16(SDPencere, 64, 10, True, 8, SistemSayaci, RENK_LACIVERT);
  SDPencere^.YaziYaz(SDPencere, 12, 26, 'ÇAÐRI:', RENK_LACIVERT);
  SDPencere^.SayiYaz16(SDPencere, 64, 26, True, 8, CagriSayaci, RENK_LACIVERT);
  SDPencere^.YaziYaz(SDPencere, 12, 42, 'GRAFK:', RENK_LACIVERT);
  SDPencere^.SayiYaz16(SDPencere, 64, 42, True, 8, GrafikSayaci, RENK_LACIVERT);
end;

end.
