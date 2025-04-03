{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: prg_grafik.pas
  Dosya ��levi: dahili �ekirdek program�: nesnelerin grafik kart�na �izimi i�in

  G�ncelleme Tarihi: 27/02/2025

 ==============================================================================}
{$mode objfpc}
unit prg_grafik;

interface

uses paylasim;

procedure GrafikYoneticiGorevOlustur(AGorevKimlik: TKimlik; AGorevAdi: string;
  AIslev: TIslev);
procedure GrafikYonetimi;
procedure SistemDegerleriBasla;
procedure SistemDegerleriOlayIsle;

implementation

uses gdt, gorev, genel, zamanlayici, gn_pencere;

var
  SDPencere: PPencere = nil;

{==============================================================================
  grafik i�levlerini y�netecek g�revi olu�turur
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

  // uygulaman�n TSS, CS, DS se�icilerini belirle, her bir program 3 se�ici i�erir
  SeciciCSSiraNo := (i * 3) + 1;
  SeciciDSSiraNo := SeciciCSSiraNo + 1;
  SeciciTSSSiraNo := SeciciDSSiraNo + 1;

  // kod se�icisi (CS)
  // Eri�im  : 1 = mevcut, 00 = DPL0, 11 = kod yazma�, 0 = dallan�lamaz, 1 = okunabilir, 0 = eri�ilmedi
  // Esneklik: 1 = gran = 4K ��z�n�rl�k, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SeciciCSSiraNo, 0, $FFFFFFFF, %10011010, %11011111);
  // veri se�icisi (DS)
  // Eri�im  : 1 = mevcut, 00 = DPL0, 10 = veri yazma�, 0 = artarak b�y�yen, 1 = yaz�labilir, 0 = eri�ilmedi
  // Esneklik: 1 = gran = 4K ��z�n�rl�k, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SeciciDSSiraNo, 0, $FFFFFFFF, %10010010, %11011111);
  // g�rev se�icisi (TSS)
  // Eri�im  : 1 = mevcut, 00 = DPL0, 010 = 32 bit kullan�labilir TSS, 0 = me�gul biti (me�gul de�il), 1
  // Esneklik: 1 = gran = 1Byte ��z�n�rl�k, 00, 1 = bana tahsis edildi, 0000 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SeciciTSSSiraNo, TSayi4(GorevTSSListesi[AGorevKimlik]), 104,
    %10001001, %00010000);

  // denet�inin kullanaca�� TSS'nin i�eri�ini s�f�rla
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

  // sistem g�rev de�erlerini belirle
  GorevListesi[AGorevKimlik]^.GorevSayaci := 0;
  GorevListesi[AGorevKimlik]^.BellekBaslangicAdresi := TSayi4(@GrafikYonetimi);
  GorevListesi[AGorevKimlik]^.BellekUzunlugu := $FFFFFFFF;
  GorevListesi[AGorevKimlik]^.OlaySayisi := 0;
  GorevListesi[AGorevKimlik]^.OlayBellekAdresi := nil;
  GorevListesi[AGorevKimlik]^.AktifMasaustu := nil;
  GorevListesi[AGorevKimlik]^.AktifPencere := nil;

  // sistem g�rev ad� (dosya ad�)
  GorevListesi[AGorevKimlik]^.FDosyaAdi := 'cekirdek.bin';
  GorevListesi[AGorevKimlik]^.FProgramAdi := AGorevAdi;

  // sistem g�revini �al���yor olarak i�aretle
  Gorev := GorevListesi[AGorevKimlik];
  Gorev^.DurumDegistir(AGorevKimlik, gdCalisiyor);

  // �al��an ve olu�turulan g�rev de�erlerini belirle
  CalisanGorevSayisi := AGorevKimlik + 1;
end;

// t�m masa�st� ve alt nesne �izimlerinin ekran kart�na aktar�ld��� nokta buras�d�r
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
  SDPencere^.YaziYaz(SDPencere, 12, 10, '�KRDK:', RENK_LACIVERT);
  SDPencere^.SayiYaz16(SDPencere, 64, 10, True, 8, SistemSayaci, RENK_LACIVERT);
  SDPencere^.YaziYaz(SDPencere, 12, 26, '�A�RI:', RENK_LACIVERT);
  SDPencere^.SayiYaz16(SDPencere, 64, 26, True, 8, CagriSayaci, RENK_LACIVERT);
  SDPencere^.YaziYaz(SDPencere, 12, 42, 'GRAFK:', RENK_LACIVERT);
  SDPencere^.SayiYaz16(SDPencere, 64, 42, True, 8, GrafikSayaci, RENK_LACIVERT);
end;

end.
