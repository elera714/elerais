{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: fat16.pas
  Dosya İşlevi: fat16 dosya sistem yönetim işlevlerini yönetir

  Güncelleme Tarihi: 30/01/2025

 ==============================================================================}
{$mode objfpc}
unit fat16;

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

uses genel, donusum, gercekbellek, fat32, sistemmesaj;

var
  DizinBellekAdresi: array[0..511] of TSayi1;

{==============================================================================
  dosyalar ile ilgili işlem yapmadan önce tanım işlevlerini gerçekleştirir
 ==============================================================================}
procedure Assign(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
begin
end;

{==============================================================================
  dosyayı okumadan önce ön hazırlık işlevlerini gerçekleştirir
 ==============================================================================}
procedure Reset(ADosyaKimlik: TKimlik);
begin
end;

{==============================================================================
  dosya okuma işleminde dosyanın sonuna gelinip gelinmediğini belirtir
 ==============================================================================}
function EOF(ADosyaKimlik: TKimlik): Boolean;
begin

  Result := True;
end;

{==============================================================================
  dosya uzunluğunu geri döndürür
 ==============================================================================}
function FileSize(ADosyaKimlik: TKimlik): TISayi4;
begin

  Result := 0;
end;

{==============================================================================
  dosya okuma işlemini gerçekleştirir
 ==============================================================================}
procedure Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci);
var
  MD: PMantiksalDepolama;
  DosyaKayit: PDosyaKayit;
  DATBellekAdresi: array[0..511] of Byte;
  DATSiraNo: TSayi2;
  OkunacakSektorSayisi,
  Zincir, i: TSayi2;
  OkunacakVeri, OkunacakFAT,
  YeniDATSiraNo: TISayi4;
  OkumaSonuc: Boolean;
begin

  // işlem yapılan dosyayla ilgili bellek bölgesine konumlan
  DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

  // üzerinde işlem yapılacak sürücü
  MD := DosyaKayit^.MantiksalDepolama;

  OkunacakVeri := DosyaKayit^.Uzunluk;

  Zincir := DosyaKayit^.IlkZincirSektor;

  OkumaSonuc := False;

  repeat

    // okunacak byte'ı sektör sayısına çevir
    OkunacakSektorSayisi := (OkunacakVeri div 512);

    if(OkunacakSektorSayisi = 0) then
    begin

      //OkunacakVeri := 0;
      //Inc(OkunacakSektorSayisi);
      OkumaSonuc := True;
    end
    else

    // aksi durumda zincir sayısınca sektör oku
    begin

      OkunacakSektorSayisi := MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;
      OkunacakVeri -= (OkunacakSektorSayisi * 512);
    end;

    if not(OkumaSonuc) then
    begin

      // okunacak zincir numarası
      i := (Zincir - 2) * MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

      // sektörü belleğe oku
      MD^.FD^.SektorOku(MD^.FD, i + MD^.Acilis.IlkVeriSektorNo,
        OkunacakSektorSayisi, AHedefBellek);

      // okunacak bilginin yerleştirileceği bir sonraki adresi belirle
      AHedefBellek += (OkunacakSektorSayisi * 512);

      OkunacakFAT := (Zincir * 2) div 512;

      // depolama aygıtının ilk FAT kopyasının tümünü belleğe yükle
      MD^.FD^.SektorOku(MD^.FD, MD^.Acilis.DosyaAyirmaTablosu.IlkSektor + OkunacakFAT,
        1, @DATBellekAdresi);

      // zincir değerini 2 ile çarp ve bir sonraki zincir değerini al
      YeniDATSiraNo := (Zincir * 2) mod 512;
      DATSiraNo := PSayi2(Isaretci(@DATBellekAdresi) + YeniDATSiraNo)^;

      Zincir := DATSiraNo;
    end;

  // eğer 0xFFF8..0xFFFF aralığındaysa bu dosyanın en son zinciridir
  until (Zincir >= $FFF8) or (OkumaSonuc);
end;

{==============================================================================
  dosyaya veri yazma işlemini gerçekleştirir
 ==============================================================================}
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
begin

  SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'Uyarı: Fat16.Write: işlev henüz yazılmadı!', []);
end;

{==============================================================================
  dosya oluşturma işlevini gerçekleştirir
 ==============================================================================}
procedure ReWrite(ADosyaKimlik: TKimlik);
begin

  SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'Uyarı: Fat16.ReWrite: işlev henüz yazılmadı!', []);
end;

{==============================================================================
  dosya üzerinde yapılan işlemi sonlandırır
 ==============================================================================}
procedure Close(ADosyaKimlik: TKimlik);
begin
end;

{==============================================================================
  dosya arama işlevini başlatır
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
  dosya arama işlemine devam eder
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
  dosya arama işlemini sonlandırır
 ==============================================================================}
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
begin

  Result := 0;
end;

end.
