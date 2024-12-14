{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: fat12.pas
  Dosya Ýþlevi: fat12 dosya sistem yönetim iþlevlerini yönetir

  Güncelleme Tarihi: 03/09/2024

 ==============================================================================}
{$mode objfpc}
unit fat12;

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

implementation

uses genel, gercekbellek, sistemmesaj, fat16, src_com;

{==============================================================================
  dosyalar ile ilgili iþlem yapmadan önce taným iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
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
  _MantiksalSurucu: PMantiksalSurucu;
  _DosyaKayit: PDosyaKayit;
  _DATBellekAdresi: Isaretci;
  _Zincir: TSayi2;
  _YeniDATSiraNo: TSayi4;
  _DATSiraNo: TSayi2;
  _OkunacakSektorSayisi, _i: TSayi2;
  _OkunacakVeri: TISayi4;
  _OkumaSonuc: Boolean;
begin

  // iþlem yapýlan dosyayla ilgili bellek bölgesine konumlan
  _DosyaKayit := @DosyaKayitListesi[ADosyaKimlik];

  // üzerinde iþlem yapýlacak sürücü
  _MantiksalSurucu := _DosyaKayit^.MantiksalSurucu;

  // FAT tablosu için bellekte yer ayýr
  _DATBellekAdresi := GGercekBellek.Ayir(
    _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.ToplamSektor * 512);

  // depolama aygýtýnýn ilk FAT kopyasýnýn tümünü belleðe yükle
  _OkumaSonuc := _MantiksalSurucu^.FizikselSurucu^.SektorOku(_MantiksalSurucu^.FizikselSurucu,
    _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.IlkSektor,
    _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.ToplamSektor, _DATBellekAdresi);

  if not(_OkumaSonuc) then SISTEM_MESAJ(RENK_KIRMIZI, 'Depolama aygýtý okuma hatasý!', []);

  _OkunacakVeri := _DosyaKayit^.Uzunluk;

  _Zincir := _DosyaKayit^.IlkZincirSektor;

  _OkunacakSektorSayisi := _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.KumeBasinaSektor;

  _OkumaSonuc := False;

  repeat

    // okunacak sektör zincir numarasý
    _i := (_Zincir - 2) * _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.KumeBasinaSektor;

    // sektörü belleðe oku
    _MantiksalSurucu^.FizikselSurucu^.SektorOku(_MantiksalSurucu^.FizikselSurucu,
      _i + _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.IlkVeriSektoru,
      _OkunacakSektorSayisi, AHedefBellek);

    //src_com.Yaz(1, AHedefBellek, _OkunacakSektorSayisi * 512);

    // okunacak bilginin yerleþtirileceði bir sonraki adresi belirle
    AHedefBellek += (_OkunacakSektorSayisi * 512);

    // zincir deðerini 1.5 ile çarp ve bir sonraki zincir deðerini al
    _YeniDATSiraNo := (_Zincir shr 1) + _Zincir + TSayi4(_DATBellekAdresi);
    _DATSiraNo := PSayi2(_YeniDATSiraNo)^;

    if((_Zincir and 1) = 1) then
      _DATSiraNo := _DATSiraNo shr 4
    else _DATSiraNo := _DATSiraNo and $FFF;

    _Zincir := _DATSiraNo;

    _OkunacakVeri -= (_OkunacakSektorSayisi * 512);
    if(_OkunacakSektorSayisi <= 0) then _OkumaSonuc := True;

  // eðer 0xFF8..0xFFF aralýðýndaysa bu dosyanýn en son zinciridir
  until (_Zincir >= $FF8) or (_OkumaSonuc);

  GGercekBellek.YokEt(_DATBellekAdresi,
    _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.ToplamSektor * 512);
end;

{==============================================================================
  dosya üzerinde yapýlan iþlemi sonlandýrýr
 ==============================================================================}
procedure CloseFile(ADosyaKimlik: TKimlik);
begin
end;

{==============================================================================
  dosya arama iþlevini baþlatýr
 ==============================================================================}
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi2;
  var ADosyaArama: TDosyaArama): TISayi4;
var
  _DizinGirisi: PDizinGirisi;
begin

  _DizinGirisi := @AramaKayitListesi[ADosyaArama.Kimlik].DizinGirisi;
  AramaKayitListesi[ADosyaArama.Kimlik].Aranan := AAramaSuzgec;
  Result := DizinGirdisiOku(_DizinGirisi, AAramaSuzgec, ADosyaArama);
end;

{==============================================================================
  dosya arama iþlemine devam eder
 ==============================================================================}
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
var
  _DizinGirisi: PDizinGirisi;
  Aranan: string;
begin

  _DizinGirisi := @AramaKayitListesi[ADosyaArama.Kimlik].DizinGirisi;
  Aranan := AramaKayitListesi[ADosyaArama.Kimlik].Aranan;
  Result := DizinGirdisiOku(_DizinGirisi, Aranan, ADosyaArama);
end;

{==============================================================================
  dosya arama iþlemini sonlandýrýr
 ==============================================================================}
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
begin

  Result := 0;
end;

end.
