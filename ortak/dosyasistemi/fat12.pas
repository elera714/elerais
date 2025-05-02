{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: fat12.pas
  Dosya Ýþlevi: fat12 dosya sistem yönetim iþlevlerini yönetir

  Güncelleme Tarihi: 30/01/2025

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
  dosyalar ile ilgili iþlem yapmadan önce taným iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure Assign(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
begin
end;

{==============================================================================
  dosyayý okumadan önce ön hazýrlýk iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure Reset(ADosyaKimlik: TKimlik);
begin
end;

{==============================================================================
  dosya okuma iþleminde dosyanýn sonuna gelinip gelinmediðini belirtir
 ==============================================================================}
function EOF(ADosyaKimlik: TKimlik): Boolean;
begin

  Result := True;
end;

{==============================================================================
  dosya uzunluðunu geri döndürür
 ==============================================================================}
function FileSize(ADosyaKimlik: TKimlik): TISayi4;
begin

  Result := 0;
end;

{==============================================================================
  dosya okuma iþlemini gerçekleþtirir
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

  // iþlem yapýlan dosyayla ilgili bellek bölgesine konumlan
  DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

  // üzerinde iþlem yapýlacak sürücü
  MD := DosyaKayit^.MantiksalDepolama;

  // FAT tablosu için bellekte yer ayýr
  DATBellekAdresi := GGercekBellek.Ayir(MD^.Acilis.DosyaAyirmaTablosu.ToplamSektor * 512);

  // depolama aygýtýnýn ilk FAT kopyasýnýn tümünü belleðe yükle
  OkumaSonuc := MD^.FD^.SektorOku(MD^.FD, MD^.Acilis.DosyaAyirmaTablosu.IlkSektor,
    MD^.Acilis.DosyaAyirmaTablosu.ToplamSektor, DATBellekAdresi);

  if(OkumaSonuc <> 0) then SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'Depolama aygýtý okuma hatasý!', []);

  OkunacakVeri := DosyaKayit^.Uzunluk;

  Zincir := DosyaKayit^.IlkZincirSektor;

  OkunacakSektorSayisi := MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

  OkumaSonuc := 1;

  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'IlkVeriSektoru: %d', [MD^.Acilis.IlkVeriSektorNo]);

  repeat

    // okunacak sektör zincir numarasý
    i := (Zincir - 2) * MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

    // sektörü belleðe oku
    MD^.FD^.SektorOku(MD^.FD, i + MD^.Acilis.IlkVeriSektorNo,
      OkunacakSektorSayisi, AHedefBellek);

    //src_com.Yaz(1, AHedefBellek, OkunacakSektorSayisi * 512);

    // okunacak bilginin yerleþtirileceði bir sonraki adresi belirle
    AHedefBellek += (OkunacakSektorSayisi * 512);

    // zincir deðerini 1.5 ile çarp ve bir sonraki zincir deðerini al
    YeniDATSiraNo := (Zincir shr 1) + Zincir + TSayi4(DATBellekAdresi);
    DATSiraNo := PSayi2(YeniDATSiraNo)^;

    if((Zincir and 1) = 1) then
      DATSiraNo := DATSiraNo shr 4
    else DATSiraNo := DATSiraNo and $FFF;

    Zincir := DATSiraNo;

    OkunacakVeri -= (OkunacakSektorSayisi * 512);
    if(OkunacakSektorSayisi <= 0) then OkumaSonuc := 0;

  // eðer 0xFF8..0xFFF aralýðýndaysa bu dosyanýn en son zinciridir
  until (Zincir >= $FF8) or (OkumaSonuc = 0);

  GGercekBellek.YokEt(DATBellekAdresi, MD^.Acilis.DosyaAyirmaTablosu.ToplamSektor * 512);
end;

{==============================================================================
  dosyaya veri yazma iþlemini gerçekleþtirir
 ==============================================================================}
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
begin

  SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'Uyarý: Fat12.Write: iþlev henüz yazýlmadý!', []);
end;

{==============================================================================
  dosya oluþturma iþlevini gerçekleþtirir
 ==============================================================================}
procedure ReWrite(ADosyaKimlik: TKimlik);
begin

  SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'Uyarý: Fat12.ReWrite: iþlev henüz yazýlmadý!', []);
end;

{==============================================================================
  dosya üzerinde yapýlan iþlemi sonlandýrýr
 ==============================================================================}
procedure Close(ADosyaKimlik: TKimlik);
begin
end;

{==============================================================================
  dosya arama iþlevini baþlatýr
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
  dosya arama iþlemine devam eder
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
  dosya arama iþlemini sonlandýrýr
 ==============================================================================}
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
begin

  Result := 0;
end;

end.
