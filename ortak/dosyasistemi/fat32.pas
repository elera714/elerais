{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: fat32.pas
  Dosya Ýþlevi: fat32 dosya sistem yönetim iþlevlerini yönetir

  Güncelleme Tarihi: 01/02/2025

 ==============================================================================}
{$mode objfpc}
unit fat32;

interface

uses paylasim, islevler;

procedure Assign(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
procedure Reset(ADosyaKimlik: TKimlik);
function EOF(ADosyaKimlik: TKimlik): Boolean;
function FileSize(ADosyaKimlik: TKimlik): TISayi4;
procedure Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci);
procedure ReWrite(ADosyaKimlik: TKimlik);
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
procedure Close(ADosyaKimlik: TKimlik);
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
  var ADosyaArama: TDosyaArama): TISayi4;
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
function DizinGirdisiOku(ADizinGirisi: PDizinGirisi; AAranacakDeger: string;
  var ADosyaArama: TDosyaArama): TSayi1;
function DizinGirisindeAra(AAramaKayit: TAramaKayit; AAranacakDeger: string): TSayi4;

implementation

uses genel, donusum, gercekbellek, sistemmesaj;

var
  DizinBellekAdresi: array[0..511] of TSayi1;

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
  DATBellekAdresi: array[0..511] of Byte;
  OkunacakSektorSayisi, i: TSayi2;
  ZincirBasinaSektor, OkunacakVeri,
  KopyalanacakVeriUzunlugu,
  YeniDATSiraNo, OkunacakFAT,
  DATSiraNo, Zincir: TISayi4;
  OkumaSonuc: Boolean;
begin

  // iþlem yapýlan dosyayla ilgili bellek bölgesine konumlan
  DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

  // üzerinde iþlem yapýlacak sürücü
  MD := DosyaKayit^.MantiksalDepolama;

  OkunacakVeri := DosyaKayit^.Uzunluk;

  Zincir := DosyaKayit^.IlkZincirSektor;

  ZincirBasinaSektor := MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

  OkumaSonuc := False;

  repeat

    // okunacak byte'ý sektör sayýsýna çevir
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

    // okunacak cluster numarasý
    i := (Zincir - 2) * ZincirBasinaSektor;
    i += MD^.Acilis.IlkVeriSektorNo;

    // sektörü belleðe oku
    MD^.FD^.SektorOku(MD^.FD, i, OkunacakSektorSayisi, AHedefBellek);

    // okunacak bilginin yerleþtirileceði bir sonraki adresi belirle
    AHedefBellek += KopyalanacakVeriUzunlugu;

    OkunacakFAT := (Zincir * 4) div 512;

    // depolama aygýtýnýn ilk FAT kopyasýnýn tümünü belleðe yükle
    MD^.FD^.SektorOku(MD^.FD, MD^.Acilis.DosyaAyirmaTablosu.IlkSektor + OkunacakFAT,
      1, @DATBellekAdresi);

    // zincir deðerini 4 ile çarp ve bir sonraki zincir deðerini al
    YeniDATSiraNo := (Zincir * 4) mod 512;
    DATSiraNo := PSayi4(Isaretci(@DATBellekAdresi) + YeniDATSiraNo)^;

    Zincir := DATSiraNo;

  // eðer 0xfff8..0xffff aralýðýndaysa bu dosyanýn en son cluster'idir
  until (Zincir = $FFFFFFF) or (OkunacakVeri = 0) or (OkumaSonuc);
end;

{==============================================================================
  dosya oluþturma iþlevini gerçekleþtirir
 ==============================================================================}
procedure ReWrite(ADosyaKimlik: TKimlik);
begin

  SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'Uyarý: Fat32.ReWrite: iþlev henüz yazýlmadý!', []);
end;

{==============================================================================
  dosyaya veri yazma iþlemini gerçekleþtirir
 ==============================================================================}
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
begin

  SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'Uyarý: Fat32.Write: iþlev henüz yazýlmadý!', []);
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

  UzunDosyaAdi[0] := #0;
  UzunDosyaAdi[1] := #0;

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

{==============================================================================
  dizin giriþinden ilgili bilgileri alýr
 ==============================================================================}
function DizinGirdisiOku(ADizinGirisi: PDizinGirisi; AAranacakDeger: string;
 var ADosyaArama: TDosyaArama): TSayi1;
var
  MD: PMantiksalDepolama;
  DizinGirdisi: PDizinGirdisi;
  TumGirislerOkundu,
  UzunDosyaAdiBulundu: Boolean;
begin

  ADosyaArama.DosyaAdi := '';

  // ilk deðer atamalarý
  TumGirislerOkundu := False;

  UzunDosyaAdiBulundu := False;

  // aramanýn yapýlacaðý sürücü
  MD := GAramaKayitListesi[ADosyaArama.Kimlik].MantiksalDepolama;

  // aramaya baþla
  repeat

    if(ADizinGirisi^.DizinTablosuKayitNo = 0) then
    begin

      // bir sonraki dizin giriþini oku
      MD^.FD^.SektorOku(MD^.FD, ADizinGirisi^.IlkSektor + ADizinGirisi^.OkunanSektor,
        1, @DizinBellekAdresi);

      Inc(ADizinGirisi^.OkunanSektor);
    end;

    // dosya giriþ tablosuna konumlan
    DizinGirdisi := PDizinGirdisi(@DizinBellekAdresi);
    Inc(DizinGirdisi, ADizinGirisi^.DizinTablosuKayitNo);

    // dosya giriþinin ilk karakteri #0 ise giriþler okunmuþ demektir
    if(DizinGirdisi^.DosyaAdi[0] = #00) then
    begin

      Result := 1;
      TumGirislerOkundu := True;
    end
    // silinmiþ dosya / dizin
    else if(DizinGirdisi^.DosyaAdi[0] = Chr($E5)) then
    begin

      // bir sonraki giriþle devam et
    end
    // mantýksal depolama aygýtý etiket (volume label)
    else if(DizinGirdisi^.Ozellikler = $08) then
    begin

      // bir sonraki giriþle devam et
    end
    // dizin girdisi uzun ada sahip bir ad ise, uzun dosya adýný al
    else if(DizinGirdisi^.Ozellikler = $0F) then
    begin

      UzunDosyaAdiBulundu := True;
      DosyaParcalariniBirlestir(Isaretci(DizinGirdisi));
    end
    // dizin girdisinin uzun ad haricinde olmasý durumunda
    else //if(DizinGirdisi^.Ozellikler <> $0F) then
    begin

      // girdinin uzun ad dosya adý OLMAMASI durumunda

      // 1. bir önceki girdi uzun dosya adý ise, ad ve diðer özellikleri geri döndür
      if(UzunDosyaAdiBulundu) then
      begin

        ADosyaArama.DosyaAdi := WideChar2String(@UzunDosyaAdi);
        ADosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
        ADosyaArama.OlusturmaSaati := FatXSaat2ELRSaat(DizinGirdisi^.OlusturmaSaati);
        ADosyaArama.OlusturmaTarihi := FatXTarih2ELRTarih(DizinGirdisi^.OlusturmaTarihi);
        ADosyaArama.SonErisimTarihi := FatXTarih2ELRTarih(DizinGirdisi^.SonErisimTarihi);
        ADosyaArama.SonDegisimSaati := FatXSaat2ELRSaat(DizinGirdisi^.SonDegisimSaati);
        ADosyaArama.SonDegisimTarihi := FatXTarih2ELRTarih(DizinGirdisi^.SonDegisimTarihi);

        // deðiþken içeriklerini sýfýrla
        UzunDosyaAdi[0] := #0;
        UzunDosyaAdi[1] := #0;
        UzunDosyaAdiBulundu := False;
      end
      else
      // 2. bir önceki girdi uzun dosya adý deðilse, 8 + 3 dosya ad + uzantý ve
      // diðer özellikleri geri döndür
      begin

        ADosyaArama.DosyaAdi := HamDosyaAdiniDosyaAdinaCevir(DizinGirdisi);
        ADosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
        ADosyaArama.OlusturmaSaati := FatXSaat2ELRSaat(DizinGirdisi^.OlusturmaSaati);
        ADosyaArama.OlusturmaTarihi := FatXTarih2ELRTarih(DizinGirdisi^.OlusturmaTarihi);
        ADosyaArama.SonErisimTarihi := FatXTarih2ELRTarih(DizinGirdisi^.SonErisimTarihi);
        ADosyaArama.SonDegisimSaati := FatXSaat2ELRSaat(DizinGirdisi^.SonDegisimSaati);
        ADosyaArama.SonDegisimTarihi := FatXTarih2ELRTarih(DizinGirdisi^.SonDegisimTarihi);
      end;

      // dosya uzunluðu ve cluster baþlangýcýný geri dönüþ deðerine ekle
      ADosyaArama.DosyaUzunlugu := DizinGirdisi^.DosyaUzunlugu;
      ADosyaArama.BaslangicKumeNo := DizinGirdisi^.BaslangicKumeNo;

      // gözardý edilecek giriþler
      if(ADosyaArama.DosyaAdi = '.') then
      begin

      end
      else
      begin

        Result := 0;
        TumGirislerOkundu := True;
      end;
    end;

    // bir sonraki girdiye konumlan
    Inc(ADizinGirisi^.DizinTablosuKayitNo);
    if(ADizinGirisi^.DizinTablosuKayitNo = 16) then
      ADizinGirisi^.DizinTablosuKayitNo := 0
    else Inc(DizinGirdisi);

    { TODO - kontrol edilerek aktifleþtirilecek }
    {if(TumGirislerOkundu) then
    begin

      if(AAranacakDeger = '*.*') then
        Exit(0)
      else if(ADosyaArama.DosyaAdi = AAranacakDeger)
        then Exit(0)
      else TumGirislerOkundu := False;
    end;}

  until TumGirislerOkundu;
end;

{==============================================================================
  dizin giriþinden ilgili bilgileri alýr
 ==============================================================================}
function DizinGirisindeAra(AAramaKayit: TAramaKayit; AAranacakDeger: string): TSayi4;
var
  MD: PMantiksalDepolama;
  DizinGirdisi: PDizinGirdisi;
  UzunDosyaAdiBulundu: Boolean;
  DosyaAdi: string;
begin

  UzunDosyaAdiBulundu := False;

  // aramanýn yapýlacaðý sürücü
  MD := AAramaKayit.MantiksalDepolama;

  // aramaya baþla
  repeat

    if(AAramaKayit.DizinGirisi.DizinTablosuKayitNo = 0) then
    begin

      // bir sonraki dizin giriþini oku
      MD^.FD^.SektorOku(MD^.FD, AAramaKayit.DizinGirisi.IlkSektor +
        AAramaKayit.DizinGirisi.OkunanSektor, 1, @DizinBellekAdresi);

      Inc(AAramaKayit.DizinGirisi.OkunanSektor);
    end;

    // dosya giriþ tablosuna konumlan
    DizinGirdisi := PDizinGirdisi(@DizinBellekAdresi);
    Inc(DizinGirdisi, AAramaKayit.DizinGirisi.DizinTablosuKayitNo);

    // dosya giriþinin ilk karakteri #0 ise giriþler okunmuþ demektir
    if(DizinGirdisi^.DosyaAdi[0] = #00) then
    begin

      Exit(0);
    end
    // silinmiþ dosya / dizin
    else if(DizinGirdisi^.DosyaAdi[0] = Chr($E5)) then
    begin

      // bir sonraki giriþle devam et
    end
    // mantýksal depolama aygýtý etiket (volume label)
    else if(DizinGirdisi^.Ozellikler = $08) then
    begin

      // bir sonraki giriþle devam et
    end
    // dizin girdisi uzun ada sahip bir ad ise, uzun dosya adýný al
    else if(DizinGirdisi^.Ozellikler = $0F) then
    begin

      UzunDosyaAdiBulundu := True;
      DosyaParcalariniBirlestir(Isaretci(DizinGirdisi));
    end
    // dizin girdisinin uzun ad haricinde olmasý durumunda
    else //if(DizinGirdisi^.Ozellikler <> $0F) then
    begin

      // girdinin uzun ad dosya adý OLMAMASI durumunda

      // 1. bir önceki girdi uzun dosya adý ise, ad ve diðer özellikleri geri döndür
      if(UzunDosyaAdiBulundu) then
      begin

        DosyaAdi := WideChar2String(@UzunDosyaAdi);

        // deðiþken içeriklerini sýfýrla
        UzunDosyaAdi[0] := #0;
        UzunDosyaAdi[1] := #0;
        UzunDosyaAdiBulundu := False;
      end else DosyaAdi := HamDosyaAdiniDosyaAdinaCevir(DizinGirdisi);

      //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Dizin Giriþi -> Dosya Adý: ''%s''', [DosyaAdi]);

      // dosya uzunluðu ve cluster baþlangýcýný geri dönüþ deðerine ekle
      if(DosyaAdi = AAranacakDeger) then Exit(DizinGirdisi^.BaslangicKumeNo);
    end;

    // bir sonraki girdiye konumlan
    Inc(AAramaKayit.DizinGirisi.DizinTablosuKayitNo);
    if(AAramaKayit.DizinGirisi.DizinTablosuKayitNo = 16) then
      AAramaKayit.DizinGirisi.DizinTablosuKayitNo := 0
    else Inc(DizinGirdisi);

  until True = False;
end;

end.
