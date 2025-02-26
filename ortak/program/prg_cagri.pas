{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: prg_cagri.pas
  Dosya Ýþlevi: dahili çekirdek programý: çaðrý iþlevleri için

  Güncelleme Tarihi: 21/02/2025

 ==============================================================================}
{$mode objfpc}
unit prg_cagri;

interface

procedure CagriYanitlayiciyiOlustur;
procedure ProgramCagrilariniYanitla;

implementation

uses gdt, gorev, paylasim, genel;

{==============================================================================
  program çaðrýlarýna yanýt verecek görevi oluþturur
 ==============================================================================}
procedure CagriYanitlayiciyiOlustur;
var
  Gorev: PGorev;
begin

  // kod seçicisi (CS)
  // Eriþim  : 1 = mevcut, 00 = DPL0, 11 = kod yazmaç, 0 = dallanýlamaz, 1 = okunabilir, 0 = eriþilmedi
  // Esneklik: 1 = gran = 4K çözünürlük, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SECICI_CAGRI_KOD, 0, $FFFFFFFF, %10011010, %11011111);
  // veri seçicisi (DS)
  // Eriþim  : 1 = mevcut, 00 = DPL0, 10 = veri yazmaç, 0 = artarak büyüyen, 1 = yazýlabilir, 0 = eriþilmedi
  // Esneklik: 1 = gran = 4K çözünürlük, 1 = 32 bit, 0, 1 = bana tahsis edildi, 1111 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SECICI_CAGRI_VERI, 0, $FFFFFFFF, %10010010, %11011111);
  // görev seçicisi (TSS)
  // Eriþim  : 1 = mevcut, 00 = DPL0, 010 = 32 bit kullanýlabilir TSS, 0 = meþgul biti (meþgul deðil), 1
  // Esneklik: 1 = gran = 1Byte çözünürlük, 00, 1 = bana tahsis edildi, 0000 = uzunluk 16..19 bit
  GDTRGirdisiEkle(SECICI_CAGRI_TSS, TSayi4(GorevTSSListesi[1]), 104,
    %10001001, %00010000);

  // denetçinin kullanacaðý TSS'nin içeriðini sýfýrla
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

  // sistem görev deðerlerini belirle
  GorevListesi[1]^.GorevSayaci := 0;
  GorevListesi[1]^.BellekBaslangicAdresi := TSayi4(@ProgramCagrilariniYanitla);
  GorevListesi[1]^.BellekUzunlugu := $FFFFFFFF;
  GorevListesi[1]^.OlaySayisi := 0;
  GorevListesi[1]^.OlayBellekAdresi := nil;
  GorevListesi[1]^.AktifMasaustu := nil;
  GorevListesi[1]^.AktifPencere := nil;

  // sistem görev adý (dosya adý)
  GorevListesi[1]^.FDosyaAdi := 'çaðrý.bin';
  GorevListesi[1]^.FProgramAdi := 'Sistem Çaðrýlarý';

  // sistem görevini çalýþýyor olarak iþaretle
  Gorev := GorevListesi[1];
  Gorev^.DurumDegistir(1, gdCalisiyor);

  // çalýþan ve oluþturulan görev deðerlerini belirle
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
