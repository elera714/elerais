{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: fat16.pas
  Dosya İşlevi: fat16 dosya sistem yönetim işlevlerini yönetir

  Güncelleme Tarihi: 09/01/2025

 ==============================================================================}
{$mode objfpc}
unit fat16;

interface

uses paylasim;

procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
procedure Reset(ADosyaKimlik: TKimlik);
function EOF(ADosyaKimlik: TKimlik): Boolean;
function FileSize(ADosyaKimlik: TKimlik): TISayi4;
procedure Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci);
procedure CloseFile(ADosyaKimlik: TKimlik);
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi2;
  var ADosyaArama: TDosyaArama): TISayi4;
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
function DizinGirdisiOku(ADizinGirisi: PDizinGirisi; AAranacakDeger: string;
  var ADosyaArama: TDosyaArama): TSayi1;

implementation

uses genel, donusum, gercekbellek, sistemmesaj;

var
  DizinBellekAdresi: array[0..511] of TSayi1;

{==============================================================================
  dosyalar ile ilgili işlem yapmadan önce tanım işlevlerini gerçekleştirir
 ==============================================================================}
procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
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
  DATBellekAdresi: Isaretci;
  Zincir: TSayi2;
  YeniDATSiraNo: TSayi4;
  DATSiraNo: TSayi2;
  OkunacakSektorSayisi, i: TSayi2;
  OkunacakVeri: TISayi4;
  OkumaSonuc: Boolean;
begin

  // işlem yapılan dosyayla ilgili bellek bölgesine konumlan
  DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

  // üzerinde işlem yapılacak sürücü
  MD := DosyaKayit^.MantiksalDepolama;

  // FAT tablosu için bellekte yer ayır
  DATBellekAdresi := GGercekBellek.Ayir(
    MD^.Acilis.DosyaAyirmaTablosu.ToplamSektor * 512);

  // depolama aygıtının ilk FAT kopyasının tümünü belleğe yükle
  MD^.FD^.SektorOku(MD^.FD, MD^.Acilis.DosyaAyirmaTablosu.IlkSektor,
    MD^.Acilis.DosyaAyirmaTablosu.ToplamSektor, DATBellekAdresi);

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

      OkunacakSektorSayisi := MD^.Acilis.DosyaAyirmaTablosu.KumeBasinaSektor0;
      OkunacakVeri -= (OkunacakSektorSayisi * 512);
    end;

    if not(OkumaSonuc) then
    begin

      // okunacak zincir numarası
      i := (Zincir - 2) * MD^.Acilis.DosyaAyirmaTablosu.KumeBasinaSektor0;

      // sektörü belleğe oku
      MD^.FD^.SektorOku(MD^.FD, i + MD^.Acilis.DosyaAyirmaTablosu.IlkVeriSektoru,
        OkunacakSektorSayisi, AHedefBellek);

      // okunacak bilginin yerleştirileceği bir sonraki adresi belirle
      AHedefBellek += (OkunacakSektorSayisi * 512);

      // zincir değerini 2 ile çarp ve bir sonraki zincir değerini al
      YeniDATSiraNo := (Zincir * 2) + TSayi4(DATBellekAdresi);
      DATSiraNo := PSayi2(YeniDATSiraNo)^;

      Zincir := DATSiraNo;
    end;

  // eğer 0xFFF8..0xFFFF aralığındaysa bu dosyanın en son zinciridir
  until (Zincir >= $FFF8) or (OkumaSonuc);

  GGercekBellek.YokEt(DATBellekAdresi, MD^.Acilis.DosyaAyirmaTablosu.ToplamSektor * 512);
end;

{==============================================================================
  dosya üzerinde yapılan işlemi sonlandırır
 ==============================================================================}
procedure CloseFile(ADosyaKimlik: TKimlik);
begin
end;

{==============================================================================
  dosya arama işlevini başlatır
 ==============================================================================}
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi2;
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

{==============================================================================
  dizin girişinden ilgili bilgileri alır
  bilgi: bu işlev iptal edilerek fat32'deki işlev kullanılacak
 ==============================================================================}
function DizinGirdisiOku(ADizinGirisi: PDizinGirisi; AAranacakDeger: string;
 var ADosyaArama: TDosyaArama): TSayi1;
var
  MD: PMantiksalDepolama;
  DizinGirdisi: PDizinGirdisi;
  TumGirislerOkundu: Boolean;
begin

  ADosyaArama.DosyaAdi := '';

  // ilk değer atamaları
  TumGirislerOkundu := False;

  // aramanın yapılacağı sürücü
  MD := GAramaKayitListesi[ADosyaArama.Kimlik].MantiksalDepolama;

  // aramaya başla
  repeat

    if(ADizinGirisi^.DizinTablosuKayitNo = -1) then
    begin

      // okunacak başka sektör var mı ?
      if(ADizinGirisi^.ToplamSektor > 0) then
      begin

        ADizinGirisi^.DizinTablosuKayitNo := 0;

        // sektörü belleğe yükle ve değişkenleri güncelle
        MD^.FD^.SektorOku(MD^.FD, ADizinGirisi^.IlkSektor, 1, @DizinBellekAdresi);
        Inc(ADizinGirisi^.IlkSektor);
        Dec(ADizinGirisi^.ToplamSektor);
      end
      else

      // aksi durumda tüm sektörler okunmuştur. çıkış bayrağını aktifleştir
      begin

        Result := 1;
        TumGirislerOkundu := True;
      end;
    end;

    // tüm girişler okunmadı ise
    if not(TumGirislerOkundu) then
    begin

      // dosya giriş tablosuna konumlan
      DizinGirdisi := PDizinGirdisi(@DizinBellekAdresi);
      Inc(DizinGirdisi, ADizinGirisi^.DizinTablosuKayitNo);

      // dosya girişinin ilk karakteri #0 ise girişler okunmuş demektir
      if(DizinGirdisi^.DosyaAdi[0] = #0) then
      begin

        Result := 1;
        TumGirislerOkundu := True;
      end

      // dosya silinmişse bir sonraki girişe bak
      else if(DizinGirdisi^.DosyaAdi[0] = Char($E5)) then
      begin

        Inc(ADizinGirisi^.DizinTablosuKayitNo);
        if(ADizinGirisi^.DizinTablosuKayitNo = 16) then ADizinGirisi^.DizinTablosuKayitNo := -1;
      end

      // dosya volume label ise bir sonraki girişe bak
      else if(DizinGirdisi^.Ozellikler = 8) then
      begin

        Inc(ADizinGirisi^.DizinTablosuKayitNo);
        if(ADizinGirisi^.DizinTablosuKayitNo = 16) then ADizinGirisi^.DizinTablosuKayitNo := -1;
      end
      else
      begin

        // dosya bulundu

        // dosya adını dosya.uz biçimine çevir
        ADosyaArama.DosyaAdi := HamDosyaAdiniDosyaAdinaCevir(DizinGirdisi);

        // dosya uzunluğu ve zincir başlangıcını geri dönüş değerine ekle
        ADosyaArama.DosyaUzunlugu := DizinGirdisi^.DosyaUzunlugu;
        ADosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
        ADosyaArama.OlusturmaSaati := DizinGirdisi^.OlusturmaSaati;
        ADosyaArama.OlusturmaTarihi := DizinGirdisi^.OlusturmaTarihi;
        ADosyaArama.SonErisimTarihi := DizinGirdisi^.SonErisimTarihi;
        ADosyaArama.SonDegisimSaati := DizinGirdisi^.SonDegisimSaati;
        ADosyaArama.SonDegisimTarihi := DizinGirdisi^.SonDegisimTarihi;
        ADosyaArama.BaslangicKumeNo := DizinGirdisi^.BaslangicKumeNo;

        Inc(ADizinGirisi^.DizinTablosuKayitNo);
        if(ADizinGirisi^.DizinTablosuKayitNo = 16) then ADizinGirisi^.DizinTablosuKayitNo := -1;

        if(AAranacakDeger = '*.*') then Exit(0);
        if(ADosyaArama.DosyaAdi = AAranacakDeger) then Exit(0);
      end
    end;
  until TumGirislerOkundu;
end;

end.
