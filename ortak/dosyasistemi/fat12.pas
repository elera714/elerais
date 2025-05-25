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

function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
  var ADosyaArama: TDosyaArama): TISayi4;
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
procedure ReWrite(ADosyaKimlik: TKimlik);
procedure Append(ADosyaKimlik: TKimlik);
procedure Reset(ADosyaKimlik: TKimlik);
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
procedure WriteLn(ADosyaKimlik: TKimlik; AVeri: string);
procedure Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci);
function IOResult: TISayi4;
function FileSize(ADosyaKimlik: TKimlik): TISayi4;
function EOF(ADosyaKimlik: TKimlik): Boolean;
procedure CloseFile(ADosyaKimlik: TKimlik);
procedure CreateDir(ADosyaKimlik: TKimlik);
procedure RemoveDir(const AKlasorAdi: string);
function DeleteFile(const ADosyaAdi: string): TISayi4;

implementation

uses genel, gercekbellek, sistemmesaj, fat32, src_com;

{==============================================================================
  dosya arama i�levini ba�lat�r
 ==============================================================================}
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
  var ADosyaArama: TDosyaArama): TISayi4;
var
  DizinGirisi: PDizinGirisi;
begin

  DizinGirisi := @GDosyaIslemleri[ADosyaArama.Kimlik].DizinGirisi;
  GDosyaIslemleri[ADosyaArama.Kimlik].Aranan := AAramaSuzgec;
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

  DizinGirisi := @GDosyaIslemleri[ADosyaArama.Kimlik].DizinGirisi;
  Aranan := GDosyaIslemleri[ADosyaArama.Kimlik].Aranan;
  Result := DizinGirdisiOku(DizinGirisi, Aranan, ADosyaArama);
end;

{==============================================================================
  dosya arama i�lemini sonland�r�r
 ==============================================================================}
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
begin

  Result := 0;
end;

{==============================================================================
  dosyalar ile ilgili i�lem yapmadan �nce tan�m i�levlerini ger�ekle�tirir
 ==============================================================================}
procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
begin
end;

{==============================================================================
  dosya olu�turma i�levini ger�ekle�tirir
 ==============================================================================}
procedure ReWrite(ADosyaKimlik: TKimlik);
begin

  SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'Uyar�: Fat12.ReWrite: i�lev hen�z yaz�lmad�!', []);
end;

{==============================================================================
  dosyaya veri eklemek i�in a�ma i�levlerini ger�ekle�tirir
 ==============================================================================}
procedure Append(ADosyaKimlik: TKimlik);
begin
end;

{==============================================================================
  dosyay� okumadan �nce �n haz�rl�k i�levlerini ger�ekle�tirir
 ==============================================================================}
procedure Reset(ADosyaKimlik: TKimlik);
begin
end;

{==============================================================================
  dosyaya veri yazma i�lemini ger�ekle�tirir
 ==============================================================================}
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
begin

  SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'Uyar�: Fat12.Write: i�lev hen�z yaz�lmad�!', []);
end;

{==============================================================================
  verinin sonuna #13#10 ekleyerek dosyaya veri yazma i�lemini ger�ekle�tirir
 ==============================================================================}
procedure WriteLn(ADosyaKimlik: TKimlik; AVeri: string);
begin

  Write(ADosyaKimlik, AVeri + #13#10);
end;

{==============================================================================
  dosya okuma i�lemini ger�ekle�tirir
 ==============================================================================}
procedure Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci);
var
  MD: PMantiksalDepolama;
  DosyaIslem: PDosyaIslem;
  DATBellekAdresi: Isaretci;
  Zincir, DATSiraNo: TSayi2;
  YeniDATSiraNo: TSayi4;
  OkunacakSektorSayisi, i: TSayi2;
  OkunacakVeri: TISayi4;
  OkumaSonuc: TSayi4;
begin

  // i�lem yap�lan dosyayla ilgili bellek b�lgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  // �zerinde i�lem yap�lacak s�r�c�
  MD := DosyaIslem^.MantiksalDepolama;

  // FAT tablosu i�in bellekte yer ay�r
  DATBellekAdresi := GGercekBellek.Ayir(MD^.Acilis.DosyaAyirmaTablosu.ToplamSektor * 512);

  // depolama ayg�t�n�n ilk FAT kopyas�n�n t�m�n� belle�e y�kle
  OkumaSonuc := MD^.FD^.SektorOku(MD^.FD, MD^.Acilis.DosyaAyirmaTablosu.IlkSektor,
    MD^.Acilis.DosyaAyirmaTablosu.ToplamSektor, DATBellekAdresi);

  if(OkumaSonuc <> 0) then SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'Depolama ayg�t� okuma hatas�!', []);

  OkunacakVeri := DosyaIslem^.Uzunluk;

  Zincir := DosyaIslem^.IlkZincirSektor;

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
  dosya ile yap�lm�� en son i�lem sonucunu d�nd�r�r
 ==============================================================================}
function IOResult: TISayi4;
begin

  Result := FileResult;

  // son i�lem durumu geri d�nd�r�ld�kten sonra de�i�keni hata yok olarak i�aretle
  FileResult := 0;
end;

{==============================================================================
  dosya uzunlu�unu geri d�nd�r�r
 ==============================================================================}
function FileSize(ADosyaKimlik: TKimlik): TISayi4;
begin

  Result := 0;
end;

{==============================================================================
  dosya okuma i�leminde dosyan�n sonuna gelinip gelinmedi�ini belirtir
 ==============================================================================}
function EOF(ADosyaKimlik: TKimlik): Boolean;
begin

  Result := True;
end;

{==============================================================================
  dosya �zerinde yap�lan i�lemi sonland�r�r
 ==============================================================================}
procedure CloseFile(ADosyaKimlik: TKimlik);
begin
end;

{==============================================================================
  klas�r olu�turma i�levini ger�ekle�tirir
 ==============================================================================}
procedure CreateDir(ADosyaKimlik: TKimlik);
begin
end;

{==============================================================================
  klas�r silme i�levini ger�ekle�tirir
 ==============================================================================}
procedure RemoveDir(const AKlasorAdi: string);
begin
end;

{==============================================================================
  dosya silme i�levini ger�ekle�tirir
 ==============================================================================}
function DeleteFile(const ADosyaAdi: string): TISayi4;
begin
end;

end.
