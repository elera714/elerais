{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: fat32.pas
  Dosya ��levi: fat32 dosya sistem y�netim i�levlerini y�netir

  G�ncelleme Tarihi: 01/02/2025

 ==============================================================================}
{$mode objfpc}
unit fat32;

interface

uses paylasim, islevler, gorev, dosya, fdepolama, mdepolama;

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

function DizinGirdisiOku(ADizinGirisi: PDizinGirisi; AAranacakDeger: string;
  var ADosyaArama: TDosyaArama): TSayi1;
function DizinGirisindeAra(ADosyaIslem: PDosyaIslem; AAranacakDeger: string): TSayi4;

implementation

uses genel, donusum, gercekbellek, sistemmesaj;

var
  DizinBellekAdresi: array[0..511] of TSayi1;

{==============================================================================
  dosya arama i�levini ba�lat�r
 ==============================================================================}
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
 var ADosyaArama: TDosyaArama): TISayi4;
var
  DizinGirisi: PDizinGirisi;
  DI: PDosyaIslem;
begin

  UzunDosyaAdi[0] := #0;
  UzunDosyaAdi[1] := #0;

  DI := Dosyalar0.DosyaIslem[ADosyaArama.Kimlik];
  DizinGirisi := @DI^.DizinGirisi;
  DI^.Aranan := AAramaSuzgec;
  Result := DizinGirdisiOku(DizinGirisi, AAramaSuzgec, ADosyaArama);
end;

{==============================================================================
  dosya arama i�lemine devam eder
 ==============================================================================}
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
var
  DizinGirisi: PDizinGirisi;
  Aranan: string;
  DI: PDosyaIslem;
begin

  DI := Dosyalar0.DosyaIslem[ADosyaArama.Kimlik];
  DizinGirisi := @DI^.DizinGirisi;
  Aranan := DI^.Aranan;
  Result := DizinGirdisiOku(DizinGirisi, Aranan, ADosyaArama);
end;

{==============================================================================
  dosya arama i�lemini sonland�r�r
 ==============================================================================}
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
begin

  Result := 0;
end;

{==============================================================================
  dosyalar ile ilgili i�lem yapmadan �nce tan�m i�levlerini ger�ekle�tirir
 ==============================================================================}
procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
begin

  // i�lev dosya.pas taraf�ndan y�netilmektedir
end;

{==============================================================================
  dosya olu�turma i�levini ger�ekle�tirir
 ==============================================================================}
procedure ReWrite(ADosyaKimlik: TKimlik);
begin

  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat32.ReWrite i�levi yaz�lacak', []);
end;

{==============================================================================
  dosyaya veri eklemek i�in dosya a�ma i�levlerini ger�ekle�tirir
 ==============================================================================}
procedure Append(ADosyaKimlik: TKimlik);
begin

  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat12.Append i�levi yaz�lacak', []);
end;

{==============================================================================
  dosyay� okumadan �nce �n haz�rl�k i�levlerini ger�ekle�tirir
 ==============================================================================}
procedure Reset(ADosyaKimlik: TKimlik);
var
  DI: PDosyaIslem;
  DosyaArama: TDosyaArama;
  TamAramaYolu: string;
  Bulundu: Boolean;
begin

  // dosya i�lem yap�s� bellek b�lgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];
  if(DI = nil) then Exit;

  // en son i�lem hatal� ise ��k
  if(DI^.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  // tam dosya ad�n� al
  TamAramaYolu := DI^.MantiksalDepolama^.MD3.AygitAdi + ':' + DI^.Klasor + '*.*';

  // dosyay� dosya tablosunda bul
  Bulundu := False;
  if(FindFirst(TamAramaYolu, 0, DosyaArama) = 0) then
  begin

    repeat

      if(DosyaArama.DosyaAdi = DI^.DosyaAdi) then Bulundu := True;
    until (Bulundu) or (FindNext(DosyaArama) <> 0);

    FindClose(DosyaArama);
  end;

  // dosyan�n tabloda bulunmas� halinde
  // dosyan�n ilk dizi ve uzunlu�unu al
  if(Bulundu) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Reset: %d', [DosyaArama.DosyaUzunlugu]);

    DI^.IlkZincirSektor := DosyaArama.BaslangicKumeNo;
    DI^.Uzunluk := DosyaArama.DosyaUzunlugu;
  end else DI^.Gorev^.DosyaSonIslemDurum := HATA_DOSYA_MEVCUTDEGIL;
end;

{==============================================================================
  dosyaya veri yazma i�lemini ger�ekle�tirir
 ==============================================================================}
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
begin

  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat32.Write i�levi yaz�lacak', []);
end;

{==============================================================================
  verinin sonuna #13#10 ekleyerek dosyaya veri yazma i�lemini ger�ekle�tirir
 ==============================================================================}
procedure WriteLn(ADosyaKimlik: TKimlik; AVeri: string);
begin

  Write(ADosyaKimlik, AVeri + #13#10);
end;

{==============================================================================
  dosya okuma i�lemini ger�ekle�tirir
 ==============================================================================}
procedure Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci);
var
  MD: PMDNesne;
  DI: PDosyaIslem;
  Bellek: Isaretci;
  DATBellekAdresi: array[0..511] of Byte;
  OkunacakSektorSayisi, i: TSayi2;
  ZincirBasinaSektor, OkunacakVeri,
  KopyalanacakVeriUzunlugu,
  YeniDATSiraNo, OkunacakFAT,
  DATSiraNo, Zincir: TISayi4;
  OkumaSonuc: Boolean;
begin

  // dosya i�lem yap�s� bellek b�lgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];
  if(DI = nil) then Exit;

  // en son i�lem hatal� ise ��k
  if(DI^.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  // �zerinde i�lem yap�lacak s�r�c�
  MD := DI^.MantiksalDepolama;

  OkunacakVeri := DI^.Uzunluk;

  Zincir := DI^.IlkZincirSektor;

  ZincirBasinaSektor := MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

  OkumaSonuc := False;

  repeat

    // okunacak byte'� sekt�r say�s�na �evir
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

    // okunacak cluster numaras�
    i := (Zincir - 2) * ZincirBasinaSektor;
    i += MD^.Acilis.IlkVeriSektorNo;

    //GetMem(Bellek, ZincirBasinaSektor * 512);

    // sekt�r� belle�e oku
    MD^.FD^.SektorOku(MD^.FD, i, OkunacakSektorSayisi, AHedefBellek);

    //Tasi2(Bellek, AHedefBellek, KopyalanacakVeriUzunlugu);

    // okunacak bilginin yerle�tirilece�i bir sonraki adresi belirle
    AHedefBellek += KopyalanacakVeriUzunlugu;

    //FreeMem(Bellek, ZincirBasinaSektor * 512);

    OkunacakFAT := (Zincir * 4) div 512;

    // depolama ayg�t�n�n ilk FAT kopyas�n�n t�m�n� belle�e y�kle
    MD^.FD^.SektorOku(MD^.FD, MD^.Acilis.DosyaAyirmaTablosu.IlkSektor + OkunacakFAT,
      1, @DATBellekAdresi);

    // zincir de�erini 4 ile �arp ve bir sonraki zincir de�erini al
    YeniDATSiraNo := (Zincir * 4) mod 512;
    DATSiraNo := PSayi4(Isaretci(@DATBellekAdresi) + YeniDATSiraNo)^;

    Zincir := DATSiraNo;

  // e�er 0xfff8..0xffff aral���ndaysa bu dosyan�n en son cluster'idir
  until (Zincir = $FFFFFFF) or (OkunacakVeri = 0) or (OkumaSonuc);
end;

{==============================================================================
  dosya ile yap�lm�� en son i�lemin sonucunu d�nd�r�r
 ==============================================================================}
function IOResult: TISayi4;
begin

  Result := 0;
  // bilgi: i�lev dosya.pas taraf�ndan y�netilmektedir
end;

{==============================================================================
  dosya uzunlu�unu geri d�nd�r�r
 ==============================================================================}
function FileSize(ADosyaKimlik: TKimlik): TISayi8;
begin

  Result := 0;
  // bilgi: i�lev dosya.pas taraf�ndan y�netilmektedir
end;

{==============================================================================
  dosya okuma i�leminde dosyan�n sonuna gelinip gelinmedi�ini belirtir
 ==============================================================================}
function EOF(ADosyaKimlik: TKimlik): Boolean;
begin

  Result := True;
end;

{==============================================================================
  dosya �zerinde yap�lan i�lemi sonland�r�r
 ==============================================================================}
procedure CloseFile(ADosyaKimlik: TKimlik);
begin
end;

{==============================================================================
  klas�r olu�turma i�levini ger�ekle�tirir
 ==============================================================================}
function CreateDir(ADosyaKimlik: TKimlik): Boolean;
begin

  Result := False;
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat32.CreateDir i�levi yaz�lacak', []);
end;

{==============================================================================
  klas�r silme i�levini ger�ekle�tirir
 ==============================================================================}
function RemoveDir(ADosyaKimlik: TKimlik): Boolean;
begin

  Result := False;
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat32.RemoveDir i�levi yaz�lacak', []);
end;

{==============================================================================
  dosya silme i�levini ger�ekle�tirir
 ==============================================================================}
function DeleteFile(ADosyaKimlik: TKimlik): Boolean;
begin

  Result := False;
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat32.DeleteFile i�levi yaz�lacak', []);
end;

{==============================================================================
  dizin giri�inden ilgili bilgileri al�r
 ==============================================================================}
function DizinGirdisiOku(ADizinGirisi: PDizinGirisi; AAranacakDeger: string;
 var ADosyaArama: TDosyaArama): TSayi1;
var
  MD: PMDNesne;
  DizinGirdisi: PDizinGirdisi;
  TumGirislerOkundu,
  UzunDosyaAdiBulundu: Boolean;
  DI: PDosyaIslem;
begin

  ADosyaArama.DosyaAdi := '';

  // ilk de�er atamalar�
  TumGirislerOkundu := False;

  UzunDosyaAdiBulundu := False;

  // dosya i�lem yap�s� bellek b�lgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaArama.Kimlik];

  // araman�n yap�laca�� s�r�c�
  MD := DI^.MantiksalDepolama;

  // aramaya ba�la
  repeat

    if(DI^.KayitSN = -1) then
    begin

      // bir sonraki dizin giri�ini oku
      MD^.FD^.SektorOku(MD^.FD, ADizinGirisi^.IlkSektor + DI^.ZincirNo,
        1, @DizinBellekAdresi);

      Inc(DI^.ZincirNo);

      DI^.KayitSN := 0;
    end;

    // dosya giri� tablosuna konumlan
    DizinGirdisi := PDizinGirdisi(@DizinBellekAdresi);
    Inc(DizinGirdisi, DI^.KayitSN);

    // dosya giri�inin ilk karakteri #0 ise giri�ler okunmu� demektir
    if(DizinGirdisi^.DosyaAdi[0] = #00) then
    begin

      Result := 1;
      TumGirislerOkundu := True;
    end
    // silinmi� dosya / dizin
    else if(DizinGirdisi^.DosyaAdi[0] = Chr($E5)) then
    begin

      // bir sonraki giri�le devam et
    end
    // mant�ksal depolama ayg�t� etiket (volume label)
    else if(DizinGirdisi^.Ozellikler = $08) then
    begin

      // bir sonraki giri�le devam et
    end
    // dizin girdisi uzun ada sahip bir ad ise, uzun dosya ad�n� al
    else if(DizinGirdisi^.Ozellikler = $0F) then
    begin

      UzunDosyaAdiBulundu := True;
      DosyaParcalariniBirlestir(Isaretci(DizinGirdisi));
    end
    // dizin girdisinin uzun ad haricinde olmas� durumunda
    else //if(DizinGirdisi^.Ozellikler <> $0F) then
    begin

      // girdinin uzun ad dosya ad� OLMAMASI durumunda

      // 1. bir �nceki girdi uzun dosya ad� ise, ad ve di�er �zellikleri geri d�nd�r
      if(UzunDosyaAdiBulundu) then
      begin

        ADosyaArama.DosyaAdi := WideChar2String(@UzunDosyaAdi);
        ADosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
        ADosyaArama.OlusturmaSaati := FatXSaat2ELRSaat(DizinGirdisi^.OlusturmaSaati);
        ADosyaArama.OlusturmaTarihi := FatXTarih2ELRTarih(DizinGirdisi^.OlusturmaTarihi);
        ADosyaArama.SonErisimTarihi := FatXTarih2ELRTarih(DizinGirdisi^.SonErisimTarihi);
        ADosyaArama.SonDegisimSaati := FatXSaat2ELRSaat(DizinGirdisi^.SonDegisimSaati);
        ADosyaArama.SonDegisimTarihi := FatXTarih2ELRTarih(DizinGirdisi^.SonDegisimTarihi);

        // de�i�ken i�eriklerini s�f�rla
        UzunDosyaAdi[0] := #0;
        UzunDosyaAdi[1] := #0;
        UzunDosyaAdiBulundu := False;
      end
      else
      // 2. bir �nceki girdi uzun dosya ad� de�ilse, 8 + 3 dosya ad + uzant� ve
      // di�er �zellikleri geri d�nd�r
      begin

        ADosyaArama.DosyaAdi := HamDosyaAdiniDosyaAdinaCevir(DizinGirdisi);
        ADosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
        ADosyaArama.OlusturmaSaati := FatXSaat2ELRSaat(DizinGirdisi^.OlusturmaSaati);
        ADosyaArama.OlusturmaTarihi := FatXTarih2ELRTarih(DizinGirdisi^.OlusturmaTarihi);
        ADosyaArama.SonErisimTarihi := FatXTarih2ELRTarih(DizinGirdisi^.SonErisimTarihi);
        ADosyaArama.SonDegisimSaati := FatXSaat2ELRSaat(DizinGirdisi^.SonDegisimSaati);
        ADosyaArama.SonDegisimTarihi := FatXTarih2ELRTarih(DizinGirdisi^.SonDegisimTarihi);
      end;

      // dosya uzunlu�u ve cluster ba�lang�c�n� geri d�n�� de�erine ekle
      ADosyaArama.DosyaUzunlugu := DizinGirdisi^.DosyaUzunlugu;
      ADosyaArama.BaslangicKumeNo := DizinGirdisi^.BaslangicKumeNo;

      // g�zard� edilecek giri�ler
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
    Inc(DI^.KayitSN);
    if(DI^.KayitSN = 16) then
      DI^.KayitSN := -1
    else Inc(DizinGirdisi);

    { TODO - kontrol edilerek aktifle�tirilecek }
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
  dizin giri�inden dosya / klas�r bilgilerini bulup, geriye ilgili giri�in k�me
  numaras�n� d�nd�r�r

  { TODO - bu i�lev (dosya / dizin arama i�levi) t�m dosya sistemlerinde olacak }
 ==============================================================================}
function DizinGirisindeAra(ADosyaIslem: PDosyaIslem; AAranacakDeger: string): TSayi4;
var
  MD: PMDNesne;
  DizinGirdisi: PDizinGirdisi;
  UzunDosyaAdiBulundu: Boolean;
  DosyaAdi: string;
begin

  UzunDosyaAdiBulundu := False;

  // araman�n yap�laca�� s�r�c�
  MD := ADosyaIslem^.MantiksalDepolama;

  // aramaya ba�la
  repeat

    if(ADosyaIslem^.KayitSN = -1) then
    begin

      // bir sonraki dizin giri�ini oku
      MD^.FD^.SektorOku(MD^.FD, ADosyaIslem^.DizinGirisi.IlkSektor +
        ADosyaIslem^.ZincirNo, 1, @DizinBellekAdresi);

      Inc(ADosyaIslem^.SektorNo);

      ADosyaIslem^.KayitSN := 0;
    end;

    // dosya giri� tablosuna konumlan
    DizinGirdisi := PDizinGirdisi(@DizinBellekAdresi);
    Inc(DizinGirdisi, ADosyaIslem^.KayitSN);

    // dosya giri�inin ilk karakteri #0 ise giri�ler okunmu� demektir
    if(DizinGirdisi^.DosyaAdi[0] = #00) then
    begin

      Exit(0);
    end
    // silinmi� dosya / dizin
    else if(DizinGirdisi^.DosyaAdi[0] = Chr($E5)) then
    begin

      // bir sonraki giri�le devam et
    end
    // mant�ksal depolama ayg�t� etiket (volume label)
    else if(DizinGirdisi^.Ozellikler = $08) then
    begin

      // bir sonraki giri�le devam et
    end
    // dizin girdisi uzun ada sahip bir ad ise, uzun dosya ad�n� al
    else if(DizinGirdisi^.Ozellikler = $0F) then
    begin

      UzunDosyaAdiBulundu := True;
      DosyaParcalariniBirlestir(Isaretci(DizinGirdisi));
    end
    // dizin girdisinin uzun ad haricinde olmas� durumunda
    else //if(DizinGirdisi^.Ozellikler <> $0F) then
    begin

      // girdinin uzun ad dosya ad� OLMAMASI durumunda

      // 1. bir �nceki girdi uzun dosya ad� ise, ad ve di�er �zellikleri geri d�nd�r
      if(UzunDosyaAdiBulundu) then
      begin

        DosyaAdi := WideChar2String(@UzunDosyaAdi);

        // de�i�ken i�eriklerini s�f�rla
        UzunDosyaAdi[0] := #0;
        UzunDosyaAdi[1] := #0;
        UzunDosyaAdiBulundu := False;
      end else DosyaAdi := HamDosyaAdiniDosyaAdinaCevir(DizinGirdisi);

      //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Dizin Giri�i -> Dosya Ad�: ''%s''', [DosyaAdi]);

      // dosya uzunlu�u ve cluster ba�lang�c�n� geri d�n�� de�erine ekle
      if(DosyaAdi = AAranacakDeger) then Exit(DizinGirdisi^.BaslangicKumeNo);
    end;

    // bir sonraki girdiye konumlan
    Inc(ADosyaIslem^.KayitSN);
    if(ADosyaIslem^.KayitSN = 16) then
      ADosyaIslem^.KayitSN := -1
    else Inc(DizinGirdisi);

  until True = False;
end;

end.
