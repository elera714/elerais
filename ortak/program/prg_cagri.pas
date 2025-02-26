{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: prg_cagri.pas
  Dosya ��levi: dahili �ekirdek program�: �a�r� i�levleri i�in

  G�ncelleme Tarihi: 21/02/2025

 ==============================================================================}
{$mode objfpc}
unit prg_cagri;

interface

procedure CagriYanitlayiciyiOlustur;
procedure ProgramCagrilariniYanitla;

implementation

uses gdt, gorev, paylasim, genel;

{==============================================================================
  program �a�r�lar�na yan�t verecek g�revi olu�turur
 ==============================================================================}
procedure CagriYanitlayiciyiOlustur;
var
  Gorev: PGorev;
begin

  // kod se�icisi (CS)
  // Eri�im  : 1 = mevcut, 00 = DPL0, 11 = kod yazma�, 0 = dallan�lamaz, 1 = okunabilir, 0 = eri�ilmedi
  // Esneklik: 1 = gran = 4K ��z�n�rl�k, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SECICI_CAGRI_KOD, 0, $FFFFFFFF, %10011010, %11011111);
  // veri se�icisi (DS)
  // Eri�im  : 1 = mevcut, 00 = DPL0, 10 = veri yazma�, 0 = artarak b�y�yen, 1 = yaz�labilir, 0 = eri�ilmedi
  // Esneklik: 1 = gran = 4K ��z�n�rl�k, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SECICI_CAGRI_VERI, 0, $FFFFFFFF, %10010010, %11011111);
  // g�rev se�icisi (TSS)
  // Eri�im  : 1 = mevcut, 00 = DPL0, 010 = 32 bit kullan�labilir TSS, 0 = me�gul biti (me�gul de�il), 1
  // Esneklik: 1 = gran = 1Byte ��z�n�rl�k, 00, 1 = bana tahsis edildi, 0000 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SECICI_CAGRI_TSS, TSayi4(GorevTSSListesi[1]), 104,
    %10001001, %00010000);

  // denet�inin kullanaca�� TSS'nin i�eri�ini s�f�rla
  FillByte(GorevTSSListesi[1]^, 104, $00);

  GorevTSSListesi[1]^.EIP := TSayi4(@ProgramCagrilariniYanitla);    // DPL 0
  GorevTSSListesi[1]^.EFLAGS := $202;
  GorevTSSListesi[1]^.ESP := CAGRI_ESP;
  GorevTSSListesi[1]^.CS := SECICI_CAGRI_KOD * 8;
  GorevTSSListesi[1]^.DS := SECICI_CAGRI_VERI * 8;
  GorevTSSListesi[1]^.ES := SECICI_CAGRI_VERI * 8;
  GorevTSSListesi[1]^.SS := SECICI_CAGRI_VERI * 8;
  GorevTSSListesi[1]^.FS := SECICI_CAGRI_VERI * 8;
  GorevTSSListesi[1]^.GS := SECICI_CAGRI_VERI * 8;
  GorevTSSListesi[1]^.SS0 := SECICI_CAGRI_VERI * 8;
  GorevTSSListesi[1]^.ESP0 := CAGRI_ESP;

  // sistem g�rev de�erlerini belirle
  GorevListesi[1]^.GorevSayaci := 0;
  GorevListesi[1]^.BellekBaslangicAdresi := TSayi4(@ProgramCagrilariniYanitla);
  GorevListesi[1]^.BellekUzunlugu := $FFFFFFFF;
  GorevListesi[1]^.OlaySayisi := 0;
  GorevListesi[1]^.OlayBellekAdresi := nil;
  GorevListesi[1]^.AktifMasaustu := nil;
  GorevListesi[1]^.AktifPencere := nil;

  // sistem g�rev ad� (dosya ad�)
  GorevListesi[1]^.FDosyaAdi := '�a�r�.bin';
  GorevListesi[1]^.FProgramAdi := 'Sistem �a�r�lar�';

  // sistem g�revini �al���yor olarak i�aretle
  Gorev := GorevListesi[1];
  Gorev^.DurumDegistir(1, gdCalisiyor);

  // �al��an ve olu�turulan g�rev de�erlerini belirle
  CalisanGorevSayisi := 2;
end;

procedure ProgramCagrilariniYanitla;
begin

  while True do
  begin

    Inc(CagriSayaci);
  end;
end;

end.
