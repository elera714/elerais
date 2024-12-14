{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: fat12.pas
  Dosya ��levi: fat12 dosya sistem y�netim i�levlerini y�netir

  G�ncelleme Tarihi: 03/09/2024

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
  dosyalar ile ilgili i�lem yapmadan �nce tan�m i�levlerini ger�ekle�tirir
 ==============================================================================}
procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
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

  // i�lem yap�lan dosyayla ilgili bellek b�lgesine konumlan
  _DosyaKayit := @DosyaKayitListesi[ADosyaKimlik];

  // �zerinde i�lem yap�lacak s�r�c�
  _MantiksalSurucu := _DosyaKayit^.MantiksalSurucu;

  // FAT tablosu i�in bellekte yer ay�r
  _DATBellekAdresi := GGercekBellek.Ayir(
    _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.ToplamSektor * 512);

  // depolama ayg�t�n�n ilk FAT kopyas�n�n t�m�n� belle�e y�kle
  _OkumaSonuc := _MantiksalSurucu^.FizikselSurucu^.SektorOku(_MantiksalSurucu^.FizikselSurucu,
    _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.IlkSektor,
    _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.ToplamSektor, _DATBellekAdresi);

  if not(_OkumaSonuc) then SISTEM_MESAJ(RENK_KIRMIZI, 'Depolama ayg�t� okuma hatas�!', []);

  _OkunacakVeri := _DosyaKayit^.Uzunluk;

  _Zincir := _DosyaKayit^.IlkZincirSektor;

  _OkunacakSektorSayisi := _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.KumeBasinaSektor;

  _OkumaSonuc := False;

  repeat

    // okunacak sekt�r zincir numaras�
    _i := (_Zincir - 2) * _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.KumeBasinaSektor;

    // sekt�r� belle�e oku
    _MantiksalSurucu^.FizikselSurucu^.SektorOku(_MantiksalSurucu^.FizikselSurucu,
      _i + _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.IlkVeriSektoru,
      _OkunacakSektorSayisi, AHedefBellek);

    //src_com.Yaz(1, AHedefBellek, _OkunacakSektorSayisi * 512);

    // okunacak bilginin yerle�tirilece�i bir sonraki adresi belirle
    AHedefBellek += (_OkunacakSektorSayisi * 512);

    // zincir de�erini 1.5 ile �arp ve bir sonraki zincir de�erini al
    _YeniDATSiraNo := (_Zincir shr 1) + _Zincir + TSayi4(_DATBellekAdresi);
    _DATSiraNo := PSayi2(_YeniDATSiraNo)^;

    if((_Zincir and 1) = 1) then
      _DATSiraNo := _DATSiraNo shr 4
    else _DATSiraNo := _DATSiraNo and $FFF;

    _Zincir := _DATSiraNo;

    _OkunacakVeri -= (_OkunacakSektorSayisi * 512);
    if(_OkunacakSektorSayisi <= 0) then _OkumaSonuc := True;

  // e�er 0xFF8..0xFFF aral���ndaysa bu dosyan�n en son zinciridir
  until (_Zincir >= $FF8) or (_OkumaSonuc);

  GGercekBellek.YokEt(_DATBellekAdresi,
    _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.ToplamSektor * 512);
end;

{==============================================================================
  dosya �zerinde yap�lan i�lemi sonland�r�r
 ==============================================================================}
procedure CloseFile(ADosyaKimlik: TKimlik);
begin
end;

{==============================================================================
  dosya arama i�levini ba�lat�r
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
  dosya arama i�lemine devam eder
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
  dosya arama i�lemini sonland�r�r
 ==============================================================================}
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
begin

  Result := 0;
end;

end.
