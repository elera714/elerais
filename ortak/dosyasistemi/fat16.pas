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

uses paylasim, gorev;

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
function FileSize(ADosyaKimlik: TKimlik): TISayi8;
function EOF(ADosyaKimlik: TKimlik): Boolean;
procedure CloseFile(ADosyaKimlik: TKimlik);
function CreateDir(ADosyaKimlik: TKimlik): Boolean;
function RemoveDir(ADosyaKimlik: TKimlik): Boolean;
function DeleteFile(ADosyaKimlik: TKimlik): Boolean;

implementation

uses genel, donusum, gercekbellek, fat32, sistemmesaj;

var
  DizinBellekAdresi: array[0..511] of TSayi1;

{==============================================================================
  dosya arama işlevini başlatır
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
  dosya arama işlemine devam eder
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
  dosya arama işlemini sonlandırır
 ==============================================================================}
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
begin

  Result := 0;
end;

{==============================================================================
  dosyalar ile ilgili işlem yapmadan önce tanım işlevlerini gerçekleştirir
 ==============================================================================}
procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
begin

  // işlev dosya.pas tarafından yönetilmektedir
end;

{==============================================================================
  dosya oluşturma işlevini gerçekleştirir
 ==============================================================================}
procedure ReWrite(ADosyaKimlik: TKimlik);
begin

  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat16.ReWrite işlevi yazılacak', []);
end;

{==============================================================================
  dosyaya veri eklemek için dosya açma işlevlerini gerçekleştirir
 ==============================================================================}
procedure Append(ADosyaKimlik: TKimlik);
begin

  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat12.Append işlevi yazılacak', []);
end;

{==============================================================================
  dosyayı okumadan önce ön hazırlık işlevlerini gerçekleştirir
 ==============================================================================}
procedure Reset(ADosyaKimlik: TKimlik);
var
  AktifGorev: PGorev;
  DosyaIslem: PDosyaIslem;
  DosyaArama: TDosyaArama;
  TamAramaYolu: string;
  Bulundu: Boolean;
begin

  AktifGorev := GorevListesi[FAktifGorev];

  // en son işlem hatalı ise çık
  if(AktifGorev^.FDosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  // dosya işlem yapısı bellek bölgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  // tam dosya adını al
  TamAramaYolu := DosyaIslem^.MantiksalDepolama^.MD3.AygitAdi + ':' + DosyaIslem^.Klasor + '*.*';

  // dosyayı dosya tablosunda bul
  Bulundu := False;
  if(FindFirst(TamAramaYolu, 0, DosyaArama) = 0) then
  begin

    repeat

      if(DosyaArama.DosyaAdi = DosyaIslem^.DosyaAdi) then Bulundu := True;
    until (Bulundu) or (FindNext(DosyaArama) <> 0);

    FindClose(DosyaArama);
  end;

  // dosyanın tabloda bulunması halinde
  // dosyanın ilk dizi ve uzunluğunu al
  if(Bulundu) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Reset: %d', [DosyaArama.DosyaUzunlugu]);

    DosyaIslem^.IlkZincirSektor := DosyaArama.BaslangicKumeNo;
    DosyaIslem^.Uzunluk := DosyaArama.DosyaUzunlugu;
  end else AktifGorev^.FDosyaSonIslemDurum := HATA_DOSYA_MEVCUTDEGIL;
end;

{==============================================================================
  dosyaya veri yazma işlemini gerçekleştirir
 ==============================================================================}
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
begin

  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat16.Write işlevi yazılacak', []);
end;

{==============================================================================
  verinin sonuna #13#10 ekleyerek dosyaya veri yazma işlemini gerçekleştirir
 ==============================================================================}
procedure WriteLn(ADosyaKimlik: TKimlik; AVeri: string);
begin

  Write(ADosyaKimlik, AVeri + #13#10);
end;

{==============================================================================
  dosya okuma işlemini gerçekleştirir
 ==============================================================================}
procedure Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci);
var
  MD: PMantiksalDepolama;
  DosyaIslem: PDosyaIslem;
  DATBellekAdresi: array[0..511] of Byte;
  DATSiraNo: TSayi2;
  OkunacakSektorSayisi,
  Zincir, i: TSayi2;
  OkunacakVeri, OkunacakFAT,
  YeniDATSiraNo: TISayi4;
  OkumaSonuc: Boolean;
begin

  // işlem yapılan dosyayla ilgili bellek bölgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  // üzerinde işlem yapılacak sürücü
  MD := DosyaIslem^.MantiksalDepolama;

  OkunacakVeri := DosyaIslem^.Uzunluk;

  Zincir := DosyaIslem^.IlkZincirSektor;

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
  dosya ile yapılmış en son işlemin sonucunu döndürür
 ==============================================================================}
function IOResult: TISayi4;
begin

  Result := 0;
  // bilgi: işlev dosya.pas tarafından yönetilmektedir
end;

{==============================================================================
  dosya uzunluğunu geri döndürür
 ==============================================================================}
function FileSize(ADosyaKimlik: TKimlik): TISayi8;
begin

  Result := 0;
  // bilgi: işlev dosya.pas tarafından yönetilmektedir
end;

{==============================================================================
  dosya okuma işleminde dosyanın sonuna gelinip gelinmediğini belirtir
 ==============================================================================}
function EOF(ADosyaKimlik: TKimlik): Boolean;
begin

  Result := True;
end;

{==============================================================================
  dosya üzerinde yapılan işlemi sonlandırır
 ==============================================================================}
procedure CloseFile(ADosyaKimlik: TKimlik);
begin
end;

{==============================================================================
  klasör oluşturma işlevini gerçekleştirir
 ==============================================================================}
function CreateDir(ADosyaKimlik: TKimlik): Boolean;
begin

  Result := False;
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat16.CreateDir işlevi yazılacak', []);
end;

{==============================================================================
  klasör silme işlevini gerçekleştirir
 ==============================================================================}
function RemoveDir(ADosyaKimlik: TKimlik): Boolean;
begin

  Result := False;
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat16.RemoveDir işlevi yazılacak', []);
end;

{==============================================================================
  dosya silme işlevini gerçekleştirir
 ==============================================================================}
function DeleteFile(ADosyaKimlik: TKimlik): Boolean;
begin

  Result := False;
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat16.DeleteFile işlevi yazılacak', []);
end;

end.
