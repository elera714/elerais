{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: dosya.pas
  Dosya ��levi: dosya (file) y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 25/12/2024

 ==============================================================================}
{$mode objfpc}
unit dosya;

interface

uses paylasim;

procedure Yukle;
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi2;
  var ADosyaArama: TDosyaArama): TISayi4;
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
procedure Reset(ADosyaKimlik: TKimlik);
function IOResult: TISayi4;
function EOF(ADosyaKimlik: TKimlik): Boolean;
function FileSize(ADosyaKimlik: TKimlik): TISayi4;
function Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci): TISayi4;
procedure CloseFile(ADosyaKimlik: TKimlik);
function AramaKaydiOlustur: TKimlik;
procedure AramaKaydiniYokEt(ADosyaKimlik: TKimlik);
function DosyaKaydiOlustur: TKimlik;
procedure DosyaKaydiniYokEt(ADosyaKimlik: TKimlik);

implementation

uses bolumleme, fat12, fat16, fat32, sistemmesaj, islevler;

{==============================================================================
  dosya sistem i�levlerinin kullanaca�� de�i�kenleri ilk de�erlerle y�kle
 ==============================================================================}
procedure Yukle;
var
  _i: TISayi4;
begin

  // �nde�er dosya i�lem d�n�� de�eri. IOResult i�in
  FileResult := 0;

  // arama de�i�kenlerini s�f�rla
  for _i := 0 to USTSINIR_ARAMAKAYIT - 1 do
  begin

    GAramaKayitListesi[_i].Kullanilabilir := True;
  end;

  // dosya i�lev de�i�kenlerini s�f�rla
  for _i := 0 to USTSINIR_DOSYAKAYIT - 1 do
  begin

    GDosyaKayitListesi[_i].Kullanilabilir := True;
  end;
end;

{==============================================================================
  dosya arama i�levini ba�lat�r
 ==============================================================================}
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi2;
  var ADosyaArama: TDosyaArama): TISayi4;
var
  _MantiksalSurucu: PMantiksalSurucu;
  AramaKimlik: TKimlik;
  _BolumTipi: Byte;
  _AranacakDeger: string;
  _KalinanSira, UTamAramaYolu, AramaSonuc: TISayi4;
begin

  // arama i�in arama bilgilerinin saklanaca�� bellek b�lgesi tahsis et
  AramaKimlik := AramaKaydiOlustur;
  if(AramaKimlik = -1) then
  begin

    Result := 1;
    Exit;
  end;

  // arama kayd�n�, �a��ran i�levin de�i�kenine sakla
  ADosyaArama.Kimlik := AramaKimlik;

  // arama i�levinin yap�laca�� s�r�c�y� al
  _MantiksalSurucu := SurucuAl(AAramaSuzgec, _KalinanSira);
  if(_MantiksalSurucu = nil) then
  begin

    // arama i�in kullan�lan bellek b�lgesini serbest b�rak
    AramaKaydiniYokEt(AramaKimlik);
    Result := 1;
    Exit;
  end;

  if not(AAramaSuzgec[_KalinanSira] = '\') then
  begin

    SISTEM_MESAJ(RENK_KIRMIZI, 'DOSYA.PAS: AranacakDeger hatal�!', []);
    Result := 1;
    Exit;
  end;

  _AranacakDeger := '';
  Inc(_KalinanSira);
  UTamAramaYolu := Length(AAramaSuzgec);
  while (AAramaSuzgec[_KalinanSira] <> '\') and (_KalinanSira <= UTamAramaYolu) do
  begin

    _AranacakDeger += AAramaSuzgec[_KalinanSira];
    Inc(_KalinanSira);
  end;

  if(_AranacakDeger = '*.*') then
  begin

    // s�r�c�y� arama bellek b�lgesine ekle
    GAramaKayitListesi[AramaKimlik].MantiksalSurucu := _MantiksalSurucu;

    // arama i�levinin aktif olarak kullanaca�� de�i�kenleri ata
    GAramaKayitListesi[AramaKimlik].DizinGirisi.IlkSektor :=
      _MantiksalSurucu^.Acilis.DizinGirisi.IlkSektor;
    GAramaKayitListesi[AramaKimlik].DizinGirisi.ToplamSektor :=
      _MantiksalSurucu^.Acilis.DizinGirisi.ToplamSektor;
    GAramaKayitListesi[AramaKimlik].DizinGirisi.GirdiSayisi :=
      _MantiksalSurucu^.Acilis.DizinGirisi.GirdiSayisi;
    GAramaKayitListesi[AramaKimlik].DizinGirisi.DizinTablosuKayitNo := -1;

    // dosya sistem tipine g�re i�levi y�nlendir
    _BolumTipi := GAramaKayitListesi[AramaKimlik].MantiksalSurucu^.BolumTipi;
    case _BolumTipi of
      DATTIP_FAT12    : Result := fat12.FindFirst(_AranacakDeger, ADosyaOzellik, ADosyaArama);
      DATTIP_FAT16    : Result := fat16.FindFirst(_AranacakDeger, ADosyaOzellik, ADosyaArama);
      DATTIP_FAT32,
      DATTIP_FAT32LBA : Result := fat32.FindFirst(_AranacakDeger, ADosyaOzellik, ADosyaArama);
      else Result := 1;
    end;
  end
  else
  begin

    // -> yukar�daki yap� ile ayn�
    // s�r�c�y� arama bellek b�lgesine ekle
    GAramaKayitListesi[AramaKimlik].MantiksalSurucu := _MantiksalSurucu;

    // arama i�levinin aktif olarak kullanaca�� de�i�kenleri ata
    GAramaKayitListesi[AramaKimlik].DizinGirisi.IlkSektor :=
      _MantiksalSurucu^.Acilis.DizinGirisi.IlkSektor;
    GAramaKayitListesi[AramaKimlik].DizinGirisi.ToplamSektor :=
      _MantiksalSurucu^.Acilis.DizinGirisi.ToplamSektor;
    GAramaKayitListesi[AramaKimlik].DizinGirisi.GirdiSayisi :=
      _MantiksalSurucu^.Acilis.DizinGirisi.GirdiSayisi;
    GAramaKayitListesi[AramaKimlik].DizinGirisi.DizinTablosuKayitNo := -1;

    // dosya sistem tipine g�re i�levi y�nlendir
    _BolumTipi := GAramaKayitListesi[AramaKimlik].MantiksalSurucu^.BolumTipi;
    case _BolumTipi of
      DATTIP_FAT12    : AramaSonuc := fat12.FindFirst(_AranacakDeger, ADosyaOzellik, ADosyaArama);
      DATTIP_FAT16    : AramaSonuc := fat16.FindFirst(_AranacakDeger, ADosyaOzellik, ADosyaArama);
      DATTIP_FAT32,
      DATTIP_FAT32LBA : AramaSonuc := fat32.FindFirst(_AranacakDeger, ADosyaOzellik, ADosyaArama);
      else AramaSonuc := 1;
    end;
    // <- yukar�daki yap� ile ayn�

    if not(_AranacakDeger = '*.*') and (AramaSonuc = 0) then
    begin

      {SISTEM_MESAJ(RENK_SIYAH, 'Aranacak De�er: ', _AranacakDeger, []);
      SISTEM_MESAJ_S16(RENK_SIYAH, 'BaslangicKumeNo: ', ADosyaArama.BaslangicKumeNo, 8);
      SISTEM_MESAJ(RENK_SIYAH, 'Dosya Ad�: ', ADosyaArama.DosyaAdi, []);
      SISTEM_MESAJ_S16(RENK_SIYAH, 'DosyaUzunlugu: ', ADosyaArama.DosyaUzunlugu, 8);
      SISTEM_MESAJ_S16(RENK_SIYAH, 'IlkSektor: ', AramaKayitListesi[AramaKimlik].DizinGirisi.IlkSektor, 8);}

      //AramaSonuc := 1;

      // -> yukar�daki yap� ile ayn�
      // s�r�c�y� arama bellek b�lgesine ekle
      GAramaKayitListesi[AramaKimlik].MantiksalSurucu := _MantiksalSurucu;

      // arama i�levinin aktif olarak kullanaca�� de�i�kenleri ata
      GAramaKayitListesi[AramaKimlik].DizinGirisi.IlkSektor :=
        ADosyaArama.BaslangicKumeNo + 622;
      GAramaKayitListesi[AramaKimlik].DizinGirisi.ToplamSektor := 1;
      GAramaKayitListesi[AramaKimlik].DizinGirisi.GirdiSayisi := 16;
      GAramaKayitListesi[AramaKimlik].DizinGirisi.DizinTablosuKayitNo := -1;

      _AranacakDeger := '*.*';
      GAramaKayitListesi[AramaKimlik].Aranan := '*.*';

      // dosya sistem tipine g�re i�levi y�nlendir
      _BolumTipi := GAramaKayitListesi[AramaKimlik].MantiksalSurucu^.BolumTipi;
      case _BolumTipi of
        DATTIP_FAT12    : AramaSonuc := fat12.FindFirst(_AranacakDeger, ADosyaOzellik, ADosyaArama);
        DATTIP_FAT16    : AramaSonuc := fat16.FindFirst(_AranacakDeger, ADosyaOzellik, ADosyaArama);
        DATTIP_FAT32,
        DATTIP_FAT32LBA : AramaSonuc := fat32.FindFirst(_AranacakDeger, ADosyaOzellik, ADosyaArama);
        else AramaSonuc := 1;
      end;
      // <- yukar�daki yap� ile ayn�
    end;

    Result := AramaSonuc;
  end;
end;

{==============================================================================
  dosya arama i�lemine devam eder
 ==============================================================================}
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
var
  _BolumTipi: TSayi1;
begin

  _BolumTipi := GAramaKayitListesi[ADosyaArama.Kimlik].MantiksalSurucu^.BolumTipi;
  if(_BolumTipi = DATTIP_FAT12) then

    Result := fat12.FindNext(ADosyaArama)
  else if(_BolumTipi = DATTIP_FAT16) then

    Result := fat16.FindNext(ADosyaArama)
  else if(_BolumTipi = DATTIP_FAT32) or (_BolumTipi = DATTIP_FAT32LBA) then

    Result := fat32.FindNext(ADosyaArama);
end;

{==============================================================================
  dosya arama i�lemini sonland�r�r
 ==============================================================================}
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
begin

  AramaKaydiniYokEt(ADosyaArama.Kimlik);
end;

{==============================================================================
  dosyalar ile ilgili i�lem yapmadan �nce tan�m i�levlerini ger�ekle�tirir
 ==============================================================================}
procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
var
  _MantiksalSurucu: PMantiksalSurucu;
  _DosyaKayit: PDosyaKayit;
  _DosyaKimlik: TKimlik;
  _Surucu, _Dizin, _DosyaAdi: string;
  _KalinanSira: TISayi4;
begin

  // �nde�er dosya i�lem d�n�� de�eri
  FileResult := 1;

  // �nde�er geri d�n�� de�eri
  ADosyaKimlik := 0;

  // dosya i�lemi i�in bellek b�lgesi ay�r
  _DosyaKimlik := DosyaKaydiOlustur;
  if(_DosyaKimlik = -1) then Exit;

  // dosya i�lem yap�s� bellek b�lgesine konumlan
  _DosyaKayit := @GDosyaKayitListesi[_DosyaKimlik];

  // s�r�c�n�n i�aret etti�i bellek b�lgesine konumlan
  _MantiksalSurucu := SurucuAl(ADosyaAdi, _KalinanSira);
  if(_MantiksalSurucu = nil) then
  begin

    DosyaKaydiniYokEt(_DosyaKimlik);
    Exit;
  end;

  FileResult := 0;

  // dosya tan�mlay�c�y� kaydet
  ADosyaKimlik := _DosyaKimlik;

  // i�lem yap�lacak s�r�c�
  _DosyaKayit^.MantiksalSurucu := _MantiksalSurucu;

  // dosya yolunu ayr��t�r
  DosyaYolunuParcala(ADosyaAdi, _Surucu, _Dizin, _DosyaAdi);

  // dosya ad�
  _DosyaKayit^.DosyaAdi := _DosyaAdi;

  // di�er de�erleri s�f�rla
  _DosyaKayit^.DATBellekAdresi := nil;
  _DosyaKayit^.IlkZincirSektor := 0;
  _DosyaKayit^.Uzunluk := 0;
  _DosyaKayit^.Konum := 0;
  _DosyaKayit^.VeriBellekAdresi := nil;
end;

{==============================================================================
  dosyay� okumadan �nce �n haz�rl�k i�levlerini ger�ekle�tirir
 ==============================================================================}
procedure Reset(ADosyaKimlik: TKimlik);
var
  _DosyaKayit: PDosyaKayit;
  _DosyaArama: TDosyaArama;
  _TamAramaYolu: string;
  _Bulundu: Boolean;
begin

  // en son i�lem hatal� ise ��k
  if(FileResult > 0) then Exit;

  // dosya i�lem yap�s� bellek b�lgesine konumlan
  _DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

  // tam dosya ad�n� al
  _TamAramaYolu := _DosyaKayit^.MantiksalSurucu^.AygitAdi + ':\*.*';

  // dosyay� dosya tablosunda bul
  _Bulundu := False;
  if(FindFirst(_TamAramaYolu, 0, _DosyaArama) = 0) then
  begin

    repeat

      if(_DosyaArama.DosyaAdi = _DosyaKayit^.DosyaAdi) then _Bulundu := True;
    until (_Bulundu) or (FindNext(_DosyaArama) <> 0);

    FindClose(_DosyaArama);
  end;

  // dosyan�n tabloda bulunmas� halinde
  // dosyan�n ilk dizi ve uzunlu�unu al
  if(_Bulundu) then
  begin

    _DosyaKayit^.IlkZincirSektor := _DosyaArama.BaslangicKumeNo;
    _DosyaKayit^.Uzunluk := _DosyaArama.DosyaUzunlugu;
  end else FileResult := 1;
end;

{==============================================================================
  dosya ile yap�lm�� en son i�lem sonucunu d�nd�r�r
 ==============================================================================}
function IOResult: TISayi4;
begin

  Result := FileResult;
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

  Result := GDosyaKayitListesi[ADosyaKimlik].Uzunluk;
end;

{==============================================================================
  dosya okuma i�lemini ger�ekle�tirir
 ==============================================================================}
function Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci): TISayi4;
var
  _DosyaKayit: PDosyaKayit;
  _BolumTipi: TSayi1;
begin

  Result := 0;

  // en son i�lem hatal� ise ��k
  if(FileResult > 0) then Exit;

  // dosya i�lem yap�s� bellek b�lgesine konumlan
  _DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

  _BolumTipi := _DosyaKayit^.MantiksalSurucu^.BolumTipi;
  if(_BolumTipi = DATTIP_FAT12) then

    fat12.Read(ADosyaKimlik, AHedefBellek)

  else if(_BolumTipi = DATTIP_FAT16) then

    fat16.Read(ADosyaKimlik, AHedefBellek)
  else if(_BolumTipi = DATTIP_FAT32) or (_BolumTipi = DATTIP_FAT32LBA) then

    fat32.Read(ADosyaKimlik, AHedefBellek);

  Result := 1;
end;

{==============================================================================
  dosya �zerinde yap�lan i�lemi sonland�r�r
 ==============================================================================}
procedure CloseFile(ADosyaKimlik: TKimlik);
begin

  DosyaKaydiniYokEt(ADosyaKimlik);
end;

{==============================================================================
  arama i�lemi i�in kaynak ay�r�r
 ==============================================================================}
function AramaKaydiOlustur: TKimlik;
var
  i: TSayi4;
begin

  // bo� bellek b�lgesi ara
  for i := 0 to USTSINIR_ARAMAKAYIT - 1 do
  begin

    if(GAramaKayitListesi[i].Kullanilabilir) then
    begin

      GAramaKayitListesi[i].Kullanilabilir := False;
      Result := i;
      Exit;
    end;
  end;

  Result := -1;
end;

{==============================================================================
  arama i�lemi i�in ayr�lan kayna�� serbest b�rak�r
 ==============================================================================}
procedure AramaKaydiniYokEt(ADosyaKimlik: TKimlik);
begin

  if(GAramaKayitListesi[ADosyaKimlik].Kullanilabilir = False) then
    GAramaKayitListesi[ADosyaKimlik].Kullanilabilir := True;
end;

{==============================================================================
  dosya i�lemleri i�in kaynak ay�r�r
 ==============================================================================}
function DosyaKaydiOlustur: TKimlik;
var
  i: TSayi4;
begin

  // bo� bellek b�lgesi ara
  for i := 0 to USTSINIR_DOSYAKAYIT - 1 do
  begin

    if(GDosyaKayitListesi[i].Kullanilabilir) then
    begin

      GDosyaKayitListesi[i].Kullanilabilir := False;
      Result := i;
      Exit;
    end;
  end;

  Result := -1;
end;

{==============================================================================
  dosya i�lemi i�in ayr�lan kayna�� iptal eder.
 ==============================================================================}
procedure DosyaKaydiniYokEt(ADosyaKimlik: TKimlik);
begin

  if(GDosyaKayitListesi[ADosyaKimlik].Kullanilabilir = False) then
    GDosyaKayitListesi[ADosyaKimlik].Kullanilabilir := True;
end;

end.
