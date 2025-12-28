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

uses paylasim, gorev, fdepolama, mdepolama;

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

uses fat32, sistemmesaj, dosya;

{==============================================================================
  dosya arama işlevini başlatır
  uyarı: işlev SADECE dosya.pas tarafından çağrılmalıdır!
 ==============================================================================}
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
 var ADosyaArama: TDosyaArama): TISayi4;
var
  DI: PDosyaIslem;
begin

  DI := Dosyalar0.DosyaIslem[ADosyaArama.Kimlik];
  DI^.Aranan := AAramaSuzgec;
  Result := DizinGirdisiOku(AAramaSuzgec, ADosyaArama);
end;

{==============================================================================
  dosya arama işlemine devam eder
  uyarı: işlev SADECE dosya.pas tarafından çağrılmalıdır!
 ==============================================================================}
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
var
  Aranan: string;
  DI: PDosyaIslem;
begin

  DI := Dosyalar0.DosyaIslem[ADosyaArama.Kimlik];
  Aranan := DI^.Aranan;
  Result := DizinGirdisiOku(Aranan, ADosyaArama);
end;

{==============================================================================
  dosya arama işlemini sonlandırır
  uyarı: işlev SADECE dosya.pas tarafından çağrılmalıdır!
 ==============================================================================}
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
begin

  Result := 0;
end;

{==============================================================================
  dosyalar ile ilgili işlem yapmadan önce tanım işlevlerini gerçekleştirir
  bilgi: işlev dosya.pas tarafından yönetilmektedir
 ==============================================================================}
procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
begin
end;

{==============================================================================
  dosya oluşturma işlevini gerçekleştirir
  uyarı: işlev SADECE dosya.pas tarafından çağrılmalıdır!
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
  DI: PDosyaIslem;
  DosyaArama: TDosyaArama;
  TamAramaYolu: string;
  Bulundu: Boolean;
begin

  // dosya işlem yapısı bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];
  if(DI = nil) then Exit;

  // en son işlem hatalı ise çık
  if(DI^.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  // tam dosya adını al
  TamAramaYolu := DI^.MD.MD3.AygitAdi + ':' + DI^.Klasor + '*.*';

  // dosyayı dosya tablosunda bul
  Bulundu := False;
  if(FindFirst(TamAramaYolu, 0, DosyaArama) = 0) then
  begin

    repeat

      if(DosyaArama.DosyaAdi = DI^.DosyaAdi) then Bulundu := True;
    until (Bulundu) or (FindNext(DosyaArama) <> 0);

    //FindClose(DosyaArama);
  end;

  // dosyanın BULUNAMAMASI halinde
  if not(Bulundu) then DI^.Gorev^.DosyaSonIslemDurum := HATA_DOSYA_MEVCUTDEGIL;
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
  DI: PDosyaIslem;
  DATBellekAdresi: Isaretci;
  DATSiraNo: TSayi2;
  OkunacakSektorSayisi,
  Zincir, i: TSayi2;
  OkunacakVeri, OkunacakFAT,
  YeniDATSiraNo: TISayi4;
  OkumaSonuc: Boolean;
  DG: PDizinGirdisi;
begin

  // dosya işlem yapısı bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];
  if(DI = nil) then Exit;

  // en son işlem hatalı ise çık
  if(DI^.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  DG := PDizinGirdisi(DI^.TSI);
  Inc(DG, DI^.KayitSN);

  OkunacakVeri := DG^.DosyaUzunlugu;
  Zincir := DG^.BaslangicKumeNo;

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

      OkunacakSektorSayisi := DI^.MD.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;
      OkunacakVeri -= (OkunacakSektorSayisi * 512);
    end;

    if not(OkumaSonuc) then
    begin

      // okunacak zincir numarası
      i := (Zincir - 2) * DI^.MD.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

      // sektörü belleğe oku
      DI^.MD.FD^.SektorOku(DI^.MD.FD, i + DI^.MD.Acilis.IlkVeriSektorNo,
        OkunacakSektorSayisi, AHedefBellek);

      // okunacak bilginin yerleştirileceği bir sonraki adresi belirle
      AHedefBellek += (OkunacakSektorSayisi * 512);

      OkunacakFAT := (Zincir * 2) div 512;

      GetMem(DATBellekAdresi, 512);

      // depolama aygıtının ilk FAT kopyasının tümünü belleğe yükle
      DI^.MD.FD^.SektorOku(DI^.MD.FD, DI^.MD.Acilis.DosyaAyirmaTablosu.IlkSektor + OkunacakFAT,
        1, DATBellekAdresi);

      // zincir değerini 2 ile çarp ve bir sonraki zincir değerini al
      YeniDATSiraNo := (Zincir * 2) mod 512;
      DATSiraNo := PSayi2(DATBellekAdresi + YeniDATSiraNo)^;

      Zincir := DATSiraNo;

      FreeMem(DATBellekAdresi, 512);
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
var
  DI: PDosyaIslem;
  DG: PDizinGirdisi;
begin

  // dosya işlem yapısı bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];
  if(DI = nil) then
  begin

    DI^.Gorev^.DosyaSonIslemDurum := HATA_KIMLIK;
    Exit(-1);
  end;

  // en son işlem hatalı ise çık
  if(DI^.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit(-1);

  DG := PDizinGirdisi(DI^.TSI);
  Inc(DG, DI^.KayitSN);

  Result := DG^.DosyaUzunlugu;
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
