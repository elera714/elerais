{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: fat16.pas
  Dosya İşlevi: fat16 dosya sistem yönetim işlevlerini yönetir

  Güncelleme Tarihi: 26/10/2019

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

  // işlem yapılan dosyayla ilgili bellek bölgesine konumlan
  _DosyaKayit := @DosyaKayitListesi[ADosyaKimlik];

  // üzerinde işlem yapılacak sürücü
  _MantiksalSurucu := _DosyaKayit^.MantiksalSurucu;

  // FAT tablosu için bellekte yer ayır
  _DATBellekAdresi := GGercekBellek.Ayir(
    _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.ToplamSektor * 512);

  // depolama aygıtının ilk FAT kopyasının tümünü belleğe yükle
  _MantiksalSurucu^.FizikselSurucu^.SektorOku(_MantiksalSurucu^.FizikselSurucu,
    _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.IlkSektor,
    _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.ToplamSektor, _DATBellekAdresi);

  _OkunacakVeri := _DosyaKayit^.Uzunluk;

  _Zincir := _DosyaKayit^.IlkZincirSektor;

  _OkumaSonuc := False;

  repeat

    // okunacak byte'ı sektör sayısına çevir
    _OkunacakSektorSayisi := (_OkunacakVeri div 512);

    if(_OkunacakSektorSayisi = 0) then
    begin

      //_OkunacakVeri := 0;
      //Inc(_OkunacakSektorSayisi);
      _OkumaSonuc := True;
    end
    else

    // aksi durumda zincir sayısınca sektör oku
    begin

      _OkunacakSektorSayisi := _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.KumeBasinaSektor;
      _OkunacakVeri -= (_OkunacakSektorSayisi * 512);
    end;

    if not(_OkumaSonuc) then
    begin

      // okunacak zincir numarası
      _i := (_Zincir - 2) * _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.KumeBasinaSektor;

      // sektörü belleğe oku
      _MantiksalSurucu^.FizikselSurucu^.SektorOku(_MantiksalSurucu^.FizikselSurucu,
        _i + _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.IlkVeriSektoru,
        _OkunacakSektorSayisi, AHedefBellek);

      // okunacak bilginin yerleştirileceği bir sonraki adresi belirle
      AHedefBellek += (_OkunacakSektorSayisi * 512);

      // zincir değerini 2 ile çarp ve bir sonraki zincir değerini al
      _YeniDATSiraNo := (_Zincir * 2) + TSayi4(_DATBellekAdresi);
      _DATSiraNo := PSayi2(_YeniDATSiraNo)^;

      _Zincir := _DATSiraNo;
    end;

  // eğer 0xFFF8..0xFFFF aralığındaysa bu dosyanın en son zinciridir
  until (_Zincir >= $FFF8) or (_OkumaSonuc);

  GGercekBellek.YokEt(_DATBellekAdresi,
    _MantiksalSurucu^.Acilis.DosyaAyirmaTablosu.ToplamSektor * 512);
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
  _DizinGirisi: PDizinGirisi;
begin

  _DizinGirisi := @AramaKayitListesi[ADosyaArama.Kimlik].DizinGirisi;
  AramaKayitListesi[ADosyaArama.Kimlik].Aranan := AAramaSuzgec;
  Result := DizinGirdisiOku(_DizinGirisi, AAramaSuzgec, ADosyaArama);
end;

{==============================================================================
  dosya arama işlemine devam eder
 ==============================================================================}
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
var
  _DizinGirisi: PDizinGirisi;
  _Aranan: string;
begin

  _DizinGirisi := @AramaKayitListesi[ADosyaArama.Kimlik].DizinGirisi;
  _Aranan := AramaKayitListesi[ADosyaArama.Kimlik].Aranan;
  Result := DizinGirdisiOku(_DizinGirisi, _Aranan, ADosyaArama);
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
  _MantiksalSurucu: PMantiksalSurucu;
  _DizinGirdisi: PDizinGirdisi;
  _TumGirislerOkundu: Boolean;
begin

  ADosyaArama.DosyaAdi := '';

  // ilk değer atamaları
  _TumGirislerOkundu := False;

  // aramanın yapılacağı sürücü
  _MantiksalSurucu := AramaKayitListesi[ADosyaArama.Kimlik].MantiksalSurucu;

  // aramaya başla
  repeat

    if(ADizinGirisi^.DizinTablosuKayitNo = -1) then
    begin

      // okunacak başka sektör var mı ?
      if(ADizinGirisi^.ToplamSektor > 0) then
      begin

        ADizinGirisi^.DizinTablosuKayitNo := 0;

        // sektörü belleğe yükle ve değişkenleri güncelle
        _MantiksalSurucu^.FizikselSurucu^.SektorOku(_MantiksalSurucu^.FizikselSurucu,
          ADizinGirisi^.IlkSektor, 1, @DizinBellekAdresi);
        Inc(ADizinGirisi^.IlkSektor);
        Dec(ADizinGirisi^.ToplamSektor);
      end
      else

      // aksi durumda tüm sektörler okunmuştur. çıkış bayrağını aktifleştir
      begin

        Result := 1;
        _TumGirislerOkundu := True;
      end;
    end;

    // tüm girişler okunmadı ise
    if not(_TumGirislerOkundu) then
    begin

      // dosya giriş tablosuna konumlan
      _DizinGirdisi := PDizinGirdisi(@DizinBellekAdresi);
      Inc(_DizinGirdisi, ADizinGirisi^.DizinTablosuKayitNo);

      // dosya girişinin ilk karakteri #0 ise girişler okunmuş demektir
      if(_DizinGirdisi^.DosyaAdi[0] = #0) then
      begin

        Result := 1;
        _TumGirislerOkundu := True;
      end

      // dosya silinmişse bir sonraki girişe bak
      else if(_DizinGirdisi^.DosyaAdi[0] = Char($E5)) then
      begin

        Inc(ADizinGirisi^.DizinTablosuKayitNo);
        if(ADizinGirisi^.DizinTablosuKayitNo = 16) then ADizinGirisi^.DizinTablosuKayitNo := -1;
      end

      // dosya volume label ise bir sonraki girişe bak
      else if(_DizinGirdisi^.Ozellikler = 8) then
      begin

        Inc(ADizinGirisi^.DizinTablosuKayitNo);
        if(ADizinGirisi^.DizinTablosuKayitNo = 16) then ADizinGirisi^.DizinTablosuKayitNo := -1;
      end
      else
      begin

        // dosya bulundu

        // dosya adını dosya.uz biçimine çevir
        ADosyaArama.DosyaAdi := HamDosyaAdiniDosyaAdinaCevir(_DizinGirdisi);

        // dosya uzunluğu ve zincir başlangıcını geri dönüş değerine ekle
        ADosyaArama.DosyaUzunlugu := _DizinGirdisi^.DosyaUzunlugu;
        ADosyaArama.Ozellikler := _DizinGirdisi^.Ozellikler;
        ADosyaArama.OlusturmaSaati := _DizinGirdisi^.OlusturmaSaati;
        ADosyaArama.OlusturmaTarihi := _DizinGirdisi^.OlusturmaTarihi;
        ADosyaArama.SonErisimTarihi := _DizinGirdisi^.SonErisimTarihi;
        ADosyaArama.SonDegisimSaati := _DizinGirdisi^.SonDegisimSaati;
        ADosyaArama.SonDegisimTarihi := _DizinGirdisi^.SonDegisimTarihi;
        ADosyaArama.BaslangicKumeNo := _DizinGirdisi^.BaslangicKumeNo;

        Inc(ADizinGirisi^.DizinTablosuKayitNo);
        if(ADizinGirisi^.DizinTablosuKayitNo = 16) then ADizinGirisi^.DizinTablosuKayitNo := -1;

        if(AAranacakDeger = '*.*') then Exit(0);
        if(ADosyaArama.DosyaAdi = AAranacakDeger) then Exit(0);
      end
    end;
  until _TumGirislerOkundu;
end;

end.
