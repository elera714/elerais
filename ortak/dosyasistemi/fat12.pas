{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: fat12.pas
  Dosya ��levi: fat12 dosya sistem y�netim i�levlerini y�netir

  G�ncelleme Tarihi: 30/01/2025

 ==============================================================================}
{$mode objfpc}
unit fat12;

interface

uses paylasim;

procedure Assign(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
procedure Reset(ADosyaKimlik: TKimlik);
function EOF(ADosyaKimlik: TKimlik): Boolean;
function FileSize(ADosyaKimlik: TKimlik): TISayi4;
procedure Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci);
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
procedure ReWrite(ADosyaKimlik: TKimlik);
procedure Close(ADosyaKimlik: TKimlik);
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
  var ADosyaArama: TDosyaArama): TISayi4;
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;

implementation

uses genel, gercekbellek, sistemmesaj, fat32, src_com;

{==============================================================================
  dosyalar ile ilgili i�lem yapmadan �nce tan�m i�levlerini ger�ekle�tirir
 ==============================================================================}
procedure Assign(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
begin
end;

{==============================================================================
  dosyay� okumadan �nce �n haz�rl�k i�levlerini ger�ekle�tirir
 ==============================================================================}
procedure Reset(ADosyaKimlik: TKimlik);
begin
end;

{==============================================================================
  dosya okuma i�leminde dosyan�n sonuna gelinip gelinmedi�ini belirtir
 ==============================================================================}
function EOF(ADosyaKimlik: TKimlik): Boolean;
begin

  Result := True;
end;

{==============================================================================
  dosya uzunlu�unu geri d�nd�r�r
 ==============================================================================}
function FileSize(ADosyaKimlik: TKimlik): TISayi4;
begin

  Result := 0;
end;

{==============================================================================
  dosya okuma i�lemini ger�ekle�tirir
 ==============================================================================}
procedure Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci);
var
  MD: PMantiksalDepolama;
  DosyaKayit: PDosyaKayit;
  DATBellekAdresi: Isaretci;
  Zincir, DATSiraNo: TSayi2;
  YeniDATSiraNo: TSayi4;
  OkunacakSektorSayisi, i: TSayi2;
  OkunacakVeri: TISayi4;
  OkumaSonuc: TSayi4;
begin

  // i�lem yap�lan dosyayla ilgili bellek b�lgesine konumlan
  DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

  // �zerinde i�lem yap�lacak s�r�c�
  MD := DosyaKayit^.MantiksalDepolama;

  // FAT tablosu i�in bellekte yer ay�r
  DATBellekAdresi := GGercekBellek.Ayir(MD^.Acilis.DosyaAyirmaTablosu.ToplamSektor * 512);

  // depolama ayg�t�n�n ilk FAT kopyas�n�n t�m�n� belle�e y�kle
  OkumaSonuc := MD^.FD^.SektorOku(MD^.FD, MD^.Acilis.DosyaAyirmaTablosu.IlkSektor,
    MD^.Acilis.DosyaAyirmaTablosu.ToplamSektor, DATBellekAdresi);

  if(OkumaSonuc <> 0) then SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'Depolama ayg�t� okuma hatas�!', []);

  OkunacakVeri := DosyaKayit^.Uzunluk;

  Zincir := DosyaKayit^.IlkZincirSektor;

  OkunacakSektorSayisi := MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

  OkumaSonuc := 1;

  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'IlkVeriSektoru: %d', [MD^.Acilis.IlkVeriSektorNo]);

  repeat

    // okunacak sekt�r zincir numaras�
    i := (Zincir - 2) * MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

    // sekt�r� belle�e oku
    MD^.FD^.SektorOku(MD^.FD, i + MD^.Acilis.IlkVeriSektorNo,
      OkunacakSektorSayisi, AHedefBellek);

    //src_com.Yaz(1, AHedefBellek, OkunacakSektorSayisi * 512);

    // okunacak bilginin yerle�tirilece�i bir sonraki adresi belirle
    AHedefBellek += (OkunacakSektorSayisi * 512);

    // zincir de�erini 1.5 ile �arp ve bir sonraki zincir de�erini al
    YeniDATSiraNo := (Zincir shr 1) + Zincir + TSayi4(DATBellekAdresi);
    DATSiraNo := PSayi2(YeniDATSiraNo)^;

    if((Zincir and 1) = 1) then
      DATSiraNo := DATSiraNo shr 4
    else DATSiraNo := DATSiraNo and $FFF;

    Zincir := DATSiraNo;

    OkunacakVeri -= (OkunacakSektorSayisi * 512);
    if(OkunacakSektorSayisi <= 0) then OkumaSonuc := 0;

  // e�er 0xFF8..0xFFF aral���ndaysa bu dosyan�n en son zinciridir
  until (Zincir >= $FF8) or (OkumaSonuc = 0);

  GGercekBellek.YokEt(DATBellekAdresi, MD^.Acilis.DosyaAyirmaTablosu.ToplamSektor * 512);
end;

{==============================================================================
  dosyaya veri yazma i�lemini ger�ekle�tirir
 ==============================================================================}
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
begin

  SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'Uyar�: Fat12.Write: i�lev hen�z yaz�lmad�!', []);
end;

{==============================================================================
  dosya olu�turma i�levini ger�ekle�tirir
 ==============================================================================}
procedure ReWrite(ADosyaKimlik: TKimlik);
begin

  SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'Uyar�: Fat12.ReWrite: i�lev hen�z yaz�lmad�!', []);
end;

{==============================================================================
  dosya �zerinde yap�lan i�lemi sonland�r�r
 ==============================================================================}
procedure Close(ADosyaKimlik: TKimlik);
begin
end;

{==============================================================================
  dosya arama i�levini ba�lat�r
 ==============================================================================}
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
  var ADosyaArama: TDosyaArama): TISayi4;
var
  DizinGirisi: PDizinGirisi;
begin

  DizinGirisi := @GAramaKayitListesi[ADosyaArama.Kimlik].DizinGirisi;
  GAramaKayitListesi[ADosyaArama.Kimlik].Aranan := AAramaSuzgec;
  Result := DizinGirdisiOku(DizinGirisi, AAramaSuzgec, ADosyaArama);
end;

{==============================================================================
  dosya arama i�lemine devam eder
 ==============================================================================}
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
var
  DizinGirisi: PDizinGirisi;
  Aranan: string;
begin

  DizinGirisi := @GAramaKayitListesi[ADosyaArama.Kimlik].DizinGirisi;
  Aranan := GAramaKayitListesi[ADosyaArama.Kimlik].Aranan;
  Result := DizinGirdisiOku(DizinGirisi, Aranan, ADosyaArama);
end;

{==============================================================================
  dosya arama i�lemini sonland�r�r
 ==============================================================================}
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
begin

  Result := 0;
end;

end.
