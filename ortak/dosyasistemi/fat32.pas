{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: fat32.pas
  Dosya İşlevi: fat32 dosya sistem yönetim işlevlerini yönetir

  Güncelleme Tarihi: 09/01/2025

 ==============================================================================}
{$mode objfpc}
unit fat32;

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
procedure DosyaParcalariniBirlestir(WCArray: Isaretci);
procedure DosyaParcasiniBasaEkle(AEklenecekVeri, AHedefBellek: Isaretci);

implementation

uses genel, donusum, gercekbellek;

var
  DizinBellekAdresi: array[0..511] of TSayi1;
  UzunDosyaAdi: array[0..514] of Char;

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
  OkunacakSektorSayisi, i: TSayi2;
  ZincirBasinaSektor, OkunacakVeri,
  KopyalanacakVeriUzunlugu,
  YeniDATSiraNo, Zincir: TISayi4;
  OkumaSonuc: Boolean;
begin

  // işlem yapılan dosyayla ilgili bellek bölgesine konumlan
  DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

  // üzerinde işlem yapılacak sürücü
  MD := DosyaKayit^.MantiksalDepolama;

  // FAT tablosu için bellekte yer ayır
  DATBellekAdresi := GGercekBellek.Ayir(MD^.Acilis.DosyaAyirmaTablosu.ToplamSektor * 512);

  // depolama aygıtının ilk FAT kopyasının tümünü belleğe yükle
  MD^.FD^.SektorOku(MD^.FD, MD^.Acilis.DosyaAyirmaTablosu.IlkSektor,
    MD^.Acilis.DosyaAyirmaTablosu.ToplamSektor, DATBellekAdresi);

  OkunacakVeri := DosyaKayit^.Uzunluk;

  Zincir := DosyaKayit^.IlkZincirSektor;

  ZincirBasinaSektor := MD^.Acilis.DosyaAyirmaTablosu.KumeBasinaSektor;

  OkumaSonuc := False;

  repeat

    // okunacak byte'ı sektör sayısına çevir
    if(OkunacakVeri >= (ZincirBasinaSektor * 512)) then
    begin

      OkunacakSektorSayisi := ZincirBasinaSektor;
      KopyalanacakVeriUzunlugu := ZincirBasinaSektor * 512;
      OkunacakVeri -= (ZincirBasinaSektor * 512);
    end
    else
    begin

      OkunacakSektorSayisi := (OkunacakVeri div 512) + 1;
      KopyalanacakVeriUzunlugu := OkunacakVeri;
      OkunacakVeri := 0;
    end;

    // okunacak cluster numarası
    i := (Zincir - 2) * ZincirBasinaSektor;
    i += MD^.Acilis.DosyaAyirmaTablosu.IlkVeriSektoru;

    // sektörü belleğe oku
    MD^.FD^.SektorOku(MD^.FD, i, OkunacakSektorSayisi, AHedefBellek);

    // okunacak bilginin yerleştirileceği bir sonraki adresi belirle
    AHedefBellek += KopyalanacakVeriUzunlugu;

    // cluster değerini 4 ile çarp ve bir sonraki cluster değerini al
    YeniDATSiraNo := (Zincir * 4) + TSayi4(DATBellekAdresi);
    Zincir := PSayi4(YeniDATSiraNo)^;

  // eğer 0xfff8..0xffff aralığındaysa bu dosyanın en son cluster'idir
  until (Zincir = $FFFFFFF) or (OkunacakVeri = 0) or (OkumaSonuc);

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

  UzunDosyaAdi[0] := #0;
  UzunDosyaAdi[1] := #0;

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
 ==============================================================================}
function DizinGirdisiOku(ADizinGirisi: PDizinGirisi; AAranacakDeger: string;
 var ADosyaArama: TDosyaArama): TSayi1;
var
  MD: PMantiksalDepolama;
  DizinGirdisi: PDizinGirdisi;
  TumGirislerOkundu, NormalDosyaAdiBulundu,
  UzunDosyaAdiBulundu: Boolean;
  DosyaUzunlugu: TSayi4;
  BaslangicZinciri: TSayi2;
begin

  ADosyaArama.DosyaAdi := '';

  // ilk değer atamaları
  TumGirislerOkundu := False;

  // aramanın yapılacağı sürücü
  MD := GAramaKayitListesi[ADosyaArama.Kimlik].MantiksalDepolama;

  NormalDosyaAdiBulundu := False;
  UzunDosyaAdiBulundu := False;

  // aramaya başla
  repeat

    if(ADizinGirisi^.DizinTablosuKayitNo = -1) then
    begin

      ADizinGirisi^.DizinTablosuKayitNo := 0;

      // bir sonraki dizin girişini oku
      MD^.FD^.SektorOku(MD^.FD, ADizinGirisi^.IlkSektor, 1, @DizinBellekAdresi);
      Inc(ADizinGirisi^.IlkSektor);
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

      // dosya uzun ada sahip bir dosya ise, girişi incele
      else if(DizinGirdisi^.Ozellikler = $F) then
      begin

        // ilk uzun dosya girişi ise cluster değerini al
        if not(UzunDosyaAdiBulundu) then
        begin

          DosyaUzunlugu := DizinGirdisi^.DosyaUzunlugu;
          BaslangicZinciri := DizinGirdisi^.BaslangicKumeNo;
        end;

        // 1 sektördeki toplam kayıt sayısı: 512 / 32 = 16
        Inc(ADizinGirisi^.DizinTablosuKayitNo);
        if(ADizinGirisi^.DizinTablosuKayitNo = 16) then
          ADizinGirisi^.DizinTablosuKayitNo := -1;

        //if((PByte(DizinGirdisi)^ and $40) = $40) then

        DosyaParcalariniBirlestir(Isaretci(DizinGirdisi));

        if(DizinGirdisi^.DosyaAdi[0] = Chr(1)) then
        begin

          UzunDosyaAdiBulundu := True;
        end;
      end

      // giriş bir volume label ise bir sonraki girişe bak
      else if(DizinGirdisi^.Ozellikler = 8) then
      begin

        Inc(ADizinGirisi^.DizinTablosuKayitNo);
        if(ADizinGirisi^.DizinTablosuKayitNo = 16) then ADizinGirisi^.DizinTablosuKayitNo := -1;
      end
      else
      begin

        DosyaUzunlugu := DizinGirdisi^.DosyaUzunlugu;
        BaslangicZinciri := DizinGirdisi^.BaslangicKumeNo;
        NormalDosyaAdiBulundu := True;
      end;

      if(NormalDosyaAdiBulundu) then
      begin

        // uzun dosya adının olması durumunda uzun dosya adı, aksi durumda
        // dosya adını 8 + 3 dosya.uz biçimine çevir
        if(UzunDosyaAdiBulundu) then
        begin

          ADosyaArama.DosyaAdi := WideChar2String(@UzunDosyaAdi);

          UzunDosyaAdi[0] := #0;
          UzunDosyaAdi[1] := #0;

          ADosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
          ADosyaArama.OlusturmaSaati := DizinGirdisi^.OlusturmaSaati;
          ADosyaArama.OlusturmaTarihi := DizinGirdisi^.OlusturmaTarihi;
          ADosyaArama.SonErisimTarihi := DizinGirdisi^.SonErisimTarihi;
          ADosyaArama.SonDegisimSaati := DizinGirdisi^.SonDegisimSaati;
          ADosyaArama.SonDegisimTarihi := DizinGirdisi^.SonDegisimTarihi;

          UzunDosyaAdiBulundu := False;
        end
        else
        begin

          ADosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
          ADosyaArama.OlusturmaSaati := DizinGirdisi^.OlusturmaSaati;
          ADosyaArama.OlusturmaTarihi := DizinGirdisi^.OlusturmaTarihi;
          ADosyaArama.SonErisimTarihi := DizinGirdisi^.SonErisimTarihi;
          ADosyaArama.SonDegisimSaati := DizinGirdisi^.SonDegisimSaati;
          ADosyaArama.SonDegisimTarihi := DizinGirdisi^.SonDegisimTarihi;

          ADosyaArama.DosyaAdi := HamDosyaAdiniDosyaAdinaCevir(DizinGirdisi);
        end;

        // dosya uzunluğu ve cluster başlangıcını geri dönüş değerine ekle
        ADosyaArama.DosyaUzunlugu := DosyaUzunlugu;
        ADosyaArama.BaslangicKumeNo := BaslangicZinciri;

        Inc(ADizinGirisi^.DizinTablosuKayitNo);
        if(ADizinGirisi^.DizinTablosuKayitNo = 16) then ADizinGirisi^.DizinTablosuKayitNo := -1;

        Result := 0;
        TumGirislerOkundu := True;
      end
    end;
  until TumGirislerOkundu;
end;

// fat32 dosya sistemindeki widechar türündeki dosya parçalarını birleştirir
procedure DosyaParcalariniBirlestir(WCArray: Isaretci);
var
  BellekU, i: TISayi4;
  p: PChar;
  Kar1, Kar2: Char;
  Bellek: array[0..27] of Char;     // azami bellek: 13 * 2 = 26 karakter + 2 byte #0 karakter
  Tamamlandi: Boolean;
begin

  Tamamlandi := False;

  // 1. parça - (5 (widechar) * 2 = 10 byte)
  BellekU := 0;
  p := PChar(WCArray + 1);
  for i := 0 to 4 do
  begin

    Kar1 := p^;
    Inc(p);
    Kar2 := p^;
    Inc(p);

    if(Kar1 <> #0) or (Kar2 <> #0) then
    begin

      Bellek[BellekU + 0] := Kar1;
      Bellek[BellekU + 1] := Kar2;
      Inc(BellekU, 2);
    end
    else
    begin

      Tamamlandi := True;
      Break;
    end;
  end;

  // 2. parça - (6 (widechar) * 2 = 12 byte)
  if not(Tamamlandi) then
  begin

    p := PChar(WCArray + 14);
    for i := 0 to 5 do
    begin

      Kar1 := p^;
      Inc(p);
      Kar2 := p^;
      Inc(p);

      if(Kar1 <> #0) or (Kar2 <> #0) then
      begin

        Bellek[BellekU + 0] := Kar1;
        Bellek[BellekU + 1] := Kar2;
        Inc(BellekU, 2);
      end
      else
      begin

        Tamamlandi := True;
        Break;
      end;
    end;
  end;

  // 3. parça - (2 (widechar) * 2 = 4 byte)
  if not(Tamamlandi) then
  begin

    p := PChar(WCArray + 28);
    for i := 0 to 1 do
    begin

      Kar1 := p^;
      Inc(p);
      Kar2 := p^;
      Inc(p);

      if(Kar1 <> #0) or (Kar2 <> #0) then
      begin

        Bellek[BellekU + 0] := Kar1;
        Bellek[BellekU + 1] := Kar2;
        Inc(BellekU, 2);
      end
      else
      begin

        Tamamlandi := True;
        Break;
      end;
    end;
  end;

  // çift 0 sonlandırma
  Bellek[BellekU + 0] := #0;
  Bellek[BellekU + 1] := #0;
  Inc(BellekU, 2);

  // parçayı bir önceki parçaların önüne ekle
  DosyaParcasiniBasaEkle(@Bellek[0], @UzunDosyaAdi[0]);
end;

// dosya ad parçasını diğer parçaların önüne ekler
// AEklenecekVeri = başa eklenecek bellek bölgesi
// AHedefBellek = verilerin birleştirileceği bellek bölgesi
procedure DosyaParcasiniBasaEkle(AEklenecekVeri, AHedefBellek: Isaretci);
var
  p1, p2: PChar;
  Kar1, Kar2: Char;
  Bellek: array[0..511] of Char;    // azami dosya ad uzunluğu
  BellekSiraNo, Bellek2SiraNo, i: TISayi4;
begin

  // 1. hedef bellek bölgesinde mevcut verileri yedekle
  p1 := PChar(AHedefBellek);

  Kar1 := p1^;
  Inc(p1);
  Kar2 := p1^;
  Inc(p1);

  BellekSiraNo := 0;
  while (Kar1 <> #0) or (Kar2 <> #0) do
  begin

    Bellek[BellekSiraNo] := Kar1;
    Inc(BellekSiraNo);
    Bellek[BellekSiraNo] := Kar2;
    Inc(BellekSiraNo);

    Kar1 := p1^;
    Inc(p1);
    Kar2 := p1^;
    Inc(p1);
  end;

  // 2. başa eklenecek verileri yükle
  p1 := PChar(AEklenecekVeri);

  Kar1 := p1^;
  Inc(p1);
  Kar2 := p1^;
  Inc(p1);

  p2 := PChar(AHedefBellek);
  Bellek2SiraNo := 0;
  while (Kar1 <> #0) or (Kar2 <> #0) do
  begin

    p2^ := Kar1;
    Inc(p2);
    Inc(Bellek2SiraNo);

    p2^ := Kar2;
    Inc(p2);
    Inc(Bellek2SiraNo);

    Kar1 := p1^;
    Inc(p1);
    Kar2 := p1^;
    Inc(p1);
  end;

  // yedeklenmiş veriyi sona ekle
  if(BellekSiraNo > 0) then
  begin

    for i := 0 to BellekSiraNo - 1 do
    begin

      Kar1 := Bellek[i];
      p2^ := Kar1;

      Inc(p2);
      Inc(Bellek2SiraNo);
    end;
  end;

  // çift sonlandırma işareti
  p2^ := #0;
  Inc(p2);
  p2^ := #0;
end;

end.
