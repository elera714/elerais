{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: dosya.pas
  Dosya ��levi: dosya (file) y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 30/01/2025

 ==============================================================================}
{$mode objfpc}
unit dosya;

interface

uses paylasim;

procedure Yukle;
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
  var ADosyaArama: TDosyaArama): TISayi4;
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
procedure CreateDir(ADosyaKimlik: TKimlik);
procedure ReWrite(ADosyaKimlik: TKimlik);
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

function HamDosyaAdiniDosyaAdinaCevir2(ADizinGirdisi: PDizinGirdisi): string;

implementation

uses bolumleme, elr1, fat12, fat16, fat32, sistemmesaj, islevler, donusum;

{==============================================================================
  dosya sistem i�levlerinin kullanaca�� de�i�kenleri ilk de�erlerle y�kle
 ==============================================================================}
procedure Yukle;
var
  i: TISayi4;
begin

  // �nde�er dosya i�lem d�n�� de�eri. IOResult i�in
  FileResult := 0;

  // arama de�i�kenlerini s�f�rla
  for i := 0 to USTSINIR_ARAMAKAYIT - 1 do
  begin

    GAramaKayitListesi[i].Kullanilabilir := True;
  end;

  // dosya i�lev de�i�kenlerini s�f�rla
  for i := 0 to USTSINIR_DOSYAKAYIT - 1 do
  begin

    GDosyaKayitListesi[i].Kullanilabilir := True;
  end;
end;

{==============================================================================
  dosya arama i�levini ba�lat�r
 ==============================================================================}
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
  var ADosyaArama: TDosyaArama): TISayi4;
var
  MD: PMantiksalDepolama;
  AramaKimlik: TKimlik;
  DST: TSayi4;
  AramaSuzgeci, AranacakKlasor, Surucu, s: string;
  UTamAramaYolu,
  AramaSonuc: TISayi4;
  i, SektorNo,
  AyrilmisSektor: TSayi4;
begin

  // AAramaSuzgec
  // �rnek: disk1:\klas�r1\dizin1\*.*

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'AAramaSuzgec: %s', [AAramaSuzgec]);

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
  MD := SurucuAl(AAramaSuzgec);
  if(MD = nil) then
  begin

    // arama i�in kullan�lan bellek b�lgesini serbest b�rak
    AramaKaydiniYokEt(AramaKimlik);
    Result := 1;
    Exit;
  end;

  s := AAramaSuzgec;

  i := Pos(':', s);
  if(i > 0) then
  begin

    Surucu := Copy(s, 1, i - 1);
    s := Copy(s, i + 1, Length(s) - i);
  end;
  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'S�r�c�: ''%s''', [Surucu]);

  if not(s[1] = '\') then
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'DOSYA.PAS: Arama s�zge� s�z dizilimi hatal�!', []);
    Result := 1;
    Exit;
  end;
  s := Copy(s, 2, Length(s) - 1);

  // s�r�c�y� arama bellek b�lgesine ekle
  GAramaKayitListesi[AramaKimlik].MantiksalDepolama := MD;

  SektorNo := MD^.Acilis.DizinGirisi.IlkSektor;

  // AyrilmisSektor = zincir de�erine eklenecek de�er
  AyrilmisSektor := MD^.Acilis.DizinGirisi.IlkSektor + MD^.Acilis.DizinGirisi.ToplamSektor;

  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'SektorNo: ''%d''', [SektorNo]);
  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'AyrilmisSektor: ''%d''', [AyrilmisSektor]);

  repeat

    i := Pos('\', s);
    if(i > 0) then
    begin

      AranacakKlasor := Copy(s, 1, i - 1);
      AramaSuzgeci := '';
      s := Copy(s, i + 1, Length(s) - i);
    end
    else
    begin

      AranacakKlasor := '';
      AramaSuzgeci := s;
    end;

    if(Length(AranacakKlasor) > 0) then
    begin

      SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'AranacakDizin: ''%s''', [AranacakKlasor]);
      SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'AramaSuzgeci: ''%s''', [AramaSuzgeci]);

      GAramaKayitListesi[AramaKimlik].DizinGirisi.IlkSektor := SektorNo;
      GAramaKayitListesi[AramaKimlik].DizinGirisi.DizinTablosuKayitNo := 0;
      GAramaKayitListesi[AramaKimlik].DizinGirisi.OkunanSektor := 0;

      SektorNo := DizinGirisindeAra(GAramaKayitListesi[AramaKimlik], AranacakKlasor);
      if(SektorNo = 0) then
      begin

        SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'DOSYA.PAS: %s dizini dosya tablosunda mevcut de�il!', [AranacakKlasor]);
        Exit(1);
      end
      else
      begin

        SektorNo := ((SektorNo - 2) * MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor) + AyrilmisSektor;
      end;
    end;
  until Length(AranacakKlasor) = 0;

  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'AramaSuzgeci: ''%s''', [AramaSuzgeci]);
  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, '�lk Dizin K�me No: %d', [SektorNo]);

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'XXYYTT: %d', [MD^.Acilis.DizinGirisi.IlkSektor + MD^.Acilis.DizinGirisi.ToplamSektor]);

  if(AramaSuzgeci = '*.*') then
  begin

    // arama i�levinin aktif olarak kullanaca�� de�i�kenleri ata
    GAramaKayitListesi[AramaKimlik].DizinGirisi.IlkSektor := SektorNo;
    GAramaKayitListesi[AramaKimlik].DizinGirisi.ToplamSektor := MD^.Acilis.DizinGirisi.ToplamSektor;
    GAramaKayitListesi[AramaKimlik].DizinGirisi.DizinTablosuKayitNo := 0;
    GAramaKayitListesi[AramaKimlik].DizinGirisi.OkunanSektor := 0;

    // dosya sistem tipine g�re i�levi y�nlendir
    DST := GAramaKayitListesi[AramaKimlik].MantiksalDepolama^.MD3.DST;

    // ge�ici
    if(DST = DST_ELR1) then
    begin

      GAramaKayitListesi[AramaKimlik].DizinGirisi.IlkSektor := 5222; //SektorNo;
      GAramaKayitListesi[AramaKimlik].DizinGirisi.ToplamSektor := 4; //MD^.Acilis.DizinGirisi.ToplamSektor;
      GAramaKayitListesi[AramaKimlik].DizinGirisi.DizinTablosuKayitNo := 0;
      GAramaKayitListesi[AramaKimlik].DizinGirisi.OkunanSektor := 0;
    end;

    case DST of
      DST_ELR1      : Result := elr1.FindFirst(AramaSuzgeci, ADosyaOzellik, ADosyaArama);
      DST_FAT12     : Result := fat12.FindFirst(AramaSuzgeci, ADosyaOzellik, ADosyaArama);
      DST_FAT16     : Result := fat16.FindFirst(AramaSuzgeci, ADosyaOzellik, ADosyaArama);
      DST_FAT32,
      DST_FAT32LBA  : Result := fat32.FindFirst(AramaSuzgeci, ADosyaOzellik, ADosyaArama);
      else Result := 1;
    end;
  end;
end;

{==============================================================================
  dosya arama i�lemine devam eder
 ==============================================================================}
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
var
  DST: TSayi4;
begin

  DST := GAramaKayitListesi[ADosyaArama.Kimlik].MantiksalDepolama^.MD3.DST;

  if(DST = DST_ELR1) then

    Result := elr1.FindNext(ADosyaArama)

  else if(DST = DST_FAT12) then

    Result := fat12.FindNext(ADosyaArama)

  else if(DST = DST_FAT16) then

    Result := fat16.FindNext(ADosyaArama)

  else if(DST = DST_FAT32) or (DST = DST_FAT32LBA) then

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
  MD: PMantiksalDepolama;
  DosyaKayit: PDosyaKayit;
  DosyaKimlik: TKimlik;
  Surucu, Klasor, DosyaAdi: string;
begin

  // �nde�er dosya i�lem d�n�� de�eri
  FileResult := 1;

  // �nde�er geri d�n�� de�eri
  ADosyaKimlik := 0;

  // dosya i�lemi i�in bellek b�lgesi ay�r
  DosyaKimlik := DosyaKaydiOlustur;
  if(DosyaKimlik = -1) then Exit;

  // dosya i�lem yap�s� bellek b�lgesine konumlan
  DosyaKayit := @GDosyaKayitListesi[DosyaKimlik];

  // s�r�c�n�n i�aret etti�i bellek b�lgesine konumlan
  MD := SurucuAl(ADosyaAdi);
  if(MD = nil) then
  begin

    DosyaKaydiniYokEt(DosyaKimlik);
    Exit;
  end;

  FileResult := 0;

  // dosya tan�mlay�c�y� kaydet
  ADosyaKimlik := DosyaKimlik;

  // i�lem yap�lacak s�r�c�
  DosyaKayit^.MantiksalDepolama := MD;

  // dosya yolunu ayr��t�r
  DosyaYolunuParcala2(ADosyaAdi, Surucu, Klasor, DosyaAdi);

  // klas�r ve dosya ad�
  DosyaKayit^.Klasor := Klasor;
  DosyaKayit^.DosyaAdi := DosyaAdi;

  // di�er de�erleri s�f�rla
  DosyaKayit^.DATBellekAdresi := nil;
  DosyaKayit^.IlkZincirSektor := 0;
  DosyaKayit^.Uzunluk := 0;
  DosyaKayit^.Konum := 0;
  DosyaKayit^.VeriBellekAdresi := nil;
end;

{==============================================================================
  dosya olu�turma i�levini ger�ekle�tirir
 ==============================================================================}
procedure CreateDir(ADosyaKimlik: TKimlik);
var
  DosyaKayit: PDosyaKayit;
  DosyaArama: TDosyaArama;
  TamAramaYolu: string;
  Bulundu: Boolean;
  FD: TFizikselDepolama;
  Bellek: array[0..511] of TSayi1;
  Bellek2: array[0..31] of TSayi1 = (
    $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $10, $08, $2D, $31, $66,
    $46, $5A, $56, $5A, $00, $00, $60, $A1, $56, $5A, $E5, $12, $00, $00, $00, $00);
  SektorNo, i, ZincirNo, ZincirSektorSayisi: TSayi4;
  MD: PMantiksalDepolama;
  DizinGirdisi: PDizinGirdisi;
  TumGirislerOkundu,
  UzunDosyaAdiBulundu, DosyaBulundu: Boolean;
  DizinGirisi: TDizinGirisi;
begin

  DosyaBulundu := False;

  // her bir cluster'in 4 sekt�r olarak tasarland��� elr-1 dosya sistemi

  SektorNo := $1466; //5222;

  // en son i�lem hatal� ise ��k
  if(FileResult > 0) then Exit;

  //ADosyaArama.DosyaAdi := '';

  // ilk de�er atamalar�
  TumGirislerOkundu := False;

  //UzunDosyaAdiBulundu := False;

  // araman�n yap�laca�� s�r�c�
  //MD := GAramaKayitListesi[ADosyaArama.Kimlik].MantiksalDepolama;
  //DizinGirisi := @GAramaKayitListesi[ADosyaKimlik].DizinGirisi;

  // dosya i�lem yap�s� bellek b�lgesine konumlan
  DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

  DizinGirisi.DizinTablosuKayitNo := 0;
  DizinGirisi.OkunanSektor := 0;
  ZincirSektorSayisi := 4;  // ge�ici de�er
  ZincirNo := 0;

  FD := FizikselDepolamaAygitListesi[3];  // fda4

  // aramaya ba�la
  repeat

    if(DizinGirisi.DizinTablosuKayitNo = 0) then
    begin

      // bir sonraki dizin giri�ini oku
      FD.SektorOku(@FD, SektorNo + ZincirNo, 1, Isaretci(@Bellek));

      // DizinGirisi.OkunanSektor de�i�keni elr dosya sisteminde anlams�z
      // Inc(DizinGirisi.OkunanSektor);
    end;

    // dosya giri� tablosuna konumlan
    DizinGirdisi := PDizinGirdisi(@Bellek);
    Inc(DizinGirdisi, DizinGirisi.DizinTablosuKayitNo);

    // dosya giri�inin ilk karakteri #0 ise giri�ler okunmu� demektir
    if(DizinGirdisi^.DosyaAdi[0] = #00) then
    begin

      //Result := 1;
      TumGirislerOkundu := True;
      //Exit;
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
    {else if(DizinGirdisi^.Ozellikler = $0F) then
    begin

      UzunDosyaAdiBulundu := True;
      DosyaParcalariniBirlestir(Isaretci(DizinGirdisi));
    end}
    // dizin girdisinin uzun ad haricinde olmas� durumunda
    else //if(DizinGirdisi^.Ozellikler <> $0F) then
    begin

      // girdinin uzun ad dosya ad� OLMAMASI durumunda

      // 1. bir �nceki girdi uzun dosya ad� ise, ad ve di�er �zellikleri geri d�nd�r
      {if(UzunDosyaAdiBulundu) then
      begin

        DosyaArama.DosyaAdi := WideChar2String(@UzunDosyaAdi);
        DosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
        DosyaArama.OlusturmaSaati := DizinGirdisi^.OlusturmaSaati;
        DosyaArama.OlusturmaTarihi := DizinGirdisi^.OlusturmaTarihi;
        DosyaArama.SonErisimTarihi := DizinGirdisi^.SonErisimTarihi;
        DosyaArama.SonDegisimSaati := DizinGirdisi^.SonDegisimSaati;
        DosyaArama.SonDegisimTarihi := DizinGirdisi^.SonDegisimTarihi;

        // de�i�ken i�eriklerini s�f�rla
        UzunDosyaAdi[0] := #0;
        UzunDosyaAdi[1] := #0;
        UzunDosyaAdiBulundu := False;
      end
      else}
      // 2. bir �nceki girdi uzun dosya ad� de�ilse, 8 + 3 dosya ad + uzant� ve
      // di�er �zellikleri geri d�nd�r
      begin

        DosyaArama.DosyaAdi := HamDosyaAdiniDosyaAdinaCevir2(DizinGirdisi);
        DosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
        DosyaArama.OlusturmaSaati := DizinGirdisi^.OlusturmaSaati;
        DosyaArama.OlusturmaTarihi := DizinGirdisi^.OlusturmaTarihi;
        DosyaArama.SonErisimTarihi := DizinGirdisi^.SonErisimTarihi;
        DosyaArama.SonDegisimSaati := DizinGirdisi^.SonDegisimSaati;
        DosyaArama.SonDegisimTarihi := DizinGirdisi^.SonDegisimTarihi;
      end;

      // dosya uzunlu�u ve cluster ba�lang�c�n� geri d�n�� de�erine ekle
      DosyaArama.DosyaUzunlugu := DizinGirdisi^.DosyaUzunlugu;
      DosyaArama.BaslangicKumeNo := DizinGirdisi^.BaslangicKumeNo;

      // g�zard� edilecek giri�ler
      if(DosyaArama.DosyaAdi = '.') then
      begin

      end
      else
      begin

        //Result := 0;
        //TumGirislerOkundu := True;
      end;

      if(DosyaArama.DosyaAdi = DosyaKayit^.DosyaAdi) then
      begin

        DosyaBulundu := True;
        TumGirislerOkundu := True;
        SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Dosya Ad�: %s, S�ra No: %d',
          [DosyaArama.DosyaAdi, DizinGirisi.DizinTablosuKayitNo]);
      end;
    end;

    if not(TumGirislerOkundu) then
    begin

      // bir sonraki girdiye konumlan
      Inc(DizinGirisi.DizinTablosuKayitNo);
      if(DizinGirisi.DizinTablosuKayitNo = 16) then
      begin

        Inc(ZincirNo);
        if(ZincirNo = ZincirSektorSayisi - 1) then
        begin

          TumGirislerOkundu := True;
          DosyaBulundu := True;     // ��k�� i�in, a�a��daki kodlar�n devreye girmemesi i�in

          { TODO - fat tablosundan bir sonraki al�nan giri�le deva� edilecektir, kodlamay� yap }
        end else DizinGirisi.DizinTablosuKayitNo := 0
      end else Inc(DizinGirdisi);
    end;

  until TumGirislerOkundu;

  // dosya olu�turma i�lemi
  if not(DosyaBulundu) then
  begin

    if(DizinGirisi.DizinTablosuKayitNo >= 0) and (DizinGirisi.DizinTablosuKayitNo < 16) then
    begin

      FillChar(Bellek2, Length(DosyaKayit^.DosyaAdi), $20);

      for i := 1 to Length(DosyaKayit^.DosyaAdi) do
      begin

        Bellek2[i - 1] := Ord(DosyaKayit^.DosyaAdi[i]);
      end;

      Tasi2(@Bellek2, @Bellek[DizinGirisi.DizinTablosuKayitNo * 32], 32);

      //FillChar(Bellek, 512, $0);
      FD.SektorYaz(@FD, SektorNo + ZincirNo, 1, Isaretci(@Bellek));
    end;
  end;
end;

{==============================================================================
  dosya olu�turma i�levini ger�ekle�tirir
 ==============================================================================}
procedure ReWrite(ADosyaKimlik: TKimlik);
var
  DosyaKayit: PDosyaKayit;
  DosyaArama: TDosyaArama;
  TamAramaYolu: string;
  Bulundu: Boolean;
  FD: TFizikselDepolama;
  Bellek: array[0..511] of TSayi1;
  Bellek2: array[0..31] of TSayi1 = (
    $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $08, $2D, $31, $66,
    $46, $5A, $56, $5A, $00, $00, $60, $A1, $56, $5A, $E5, $12, $00, $00, $00, $00);
  SektorNo, i, ZincirNo, ZincirSektorSayisi: TSayi4;
  MD: PMantiksalDepolama;
  DizinGirdisi: PDizinGirdisi;
  TumGirislerOkundu,
  UzunDosyaAdiBulundu, DosyaBulundu: Boolean;
  DizinGirisi: TDizinGirisi;
begin

  DosyaBulundu := False;

  // her bir cluster'in 4 sekt�r olarak tasarland��� elr-1 dosya sistemi

  SektorNo := $1466; //5222;

  // en son i�lem hatal� ise ��k
  if(FileResult > 0) then Exit;

  //ADosyaArama.DosyaAdi := '';

  // ilk de�er atamalar�
  TumGirislerOkundu := False;

  //UzunDosyaAdiBulundu := False;

  // araman�n yap�laca�� s�r�c�
  //MD := GAramaKayitListesi[ADosyaArama.Kimlik].MantiksalDepolama;
  //DizinGirisi := @GAramaKayitListesi[ADosyaKimlik].DizinGirisi;

  // dosya i�lem yap�s� bellek b�lgesine konumlan
  DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

  DizinGirisi.DizinTablosuKayitNo := 0;
  DizinGirisi.OkunanSektor := 0;
  ZincirSektorSayisi := 4;  // ge�ici de�er
  ZincirNo := 0;

  FD := FizikselDepolamaAygitListesi[3];  // fda4

  // aramaya ba�la
  repeat

    if(DizinGirisi.DizinTablosuKayitNo = 0) then
    begin

      // bir sonraki dizin giri�ini oku
      FD.SektorOku(@FD, SektorNo + ZincirNo, 1, Isaretci(@Bellek));

      // DizinGirisi.OkunanSektor de�i�keni elr dosya sisteminde anlams�z
      // Inc(DizinGirisi.OkunanSektor);
    end;

    // dosya giri� tablosuna konumlan
    DizinGirdisi := PDizinGirdisi(@Bellek);
    Inc(DizinGirdisi, DizinGirisi.DizinTablosuKayitNo);

    // dosya giri�inin ilk karakteri #0 ise giri�ler okunmu� demektir
    if(DizinGirdisi^.DosyaAdi[0] = #00) then
    begin

      //Result := 1;
      TumGirislerOkundu := True;
      //Exit;
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
    {else if(DizinGirdisi^.Ozellikler = $0F) then
    begin

      UzunDosyaAdiBulundu := True;
      DosyaParcalariniBirlestir(Isaretci(DizinGirdisi));
    end}
    // dizin girdisinin uzun ad haricinde olmas� durumunda
    else //if(DizinGirdisi^.Ozellikler <> $0F) then
    begin

      // girdinin uzun ad dosya ad� OLMAMASI durumunda

      // 1. bir �nceki girdi uzun dosya ad� ise, ad ve di�er �zellikleri geri d�nd�r
      {if(UzunDosyaAdiBulundu) then
      begin

        DosyaArama.DosyaAdi := WideChar2String(@UzunDosyaAdi);
        DosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
        DosyaArama.OlusturmaSaati := DizinGirdisi^.OlusturmaSaati;
        DosyaArama.OlusturmaTarihi := DizinGirdisi^.OlusturmaTarihi;
        DosyaArama.SonErisimTarihi := DizinGirdisi^.SonErisimTarihi;
        DosyaArama.SonDegisimSaati := DizinGirdisi^.SonDegisimSaati;
        DosyaArama.SonDegisimTarihi := DizinGirdisi^.SonDegisimTarihi;

        // de�i�ken i�eriklerini s�f�rla
        UzunDosyaAdi[0] := #0;
        UzunDosyaAdi[1] := #0;
        UzunDosyaAdiBulundu := False;
      end
      else}
      // 2. bir �nceki girdi uzun dosya ad� de�ilse, 8 + 3 dosya ad + uzant� ve
      // di�er �zellikleri geri d�nd�r
      begin

        DosyaArama.DosyaAdi := HamDosyaAdiniDosyaAdinaCevir2(DizinGirdisi);
        DosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
        DosyaArama.OlusturmaSaati := DizinGirdisi^.OlusturmaSaati;
        DosyaArama.OlusturmaTarihi := DizinGirdisi^.OlusturmaTarihi;
        DosyaArama.SonErisimTarihi := DizinGirdisi^.SonErisimTarihi;
        DosyaArama.SonDegisimSaati := DizinGirdisi^.SonDegisimSaati;
        DosyaArama.SonDegisimTarihi := DizinGirdisi^.SonDegisimTarihi;
      end;

      // dosya uzunlu�u ve cluster ba�lang�c�n� geri d�n�� de�erine ekle
      DosyaArama.DosyaUzunlugu := DizinGirdisi^.DosyaUzunlugu;
      DosyaArama.BaslangicKumeNo := DizinGirdisi^.BaslangicKumeNo;

      // g�zard� edilecek giri�ler
      if(DosyaArama.DosyaAdi = '.') then
      begin

      end
      else
      begin

        //Result := 0;
        //TumGirislerOkundu := True;
      end;

      if(DosyaArama.DosyaAdi = DosyaKayit^.DosyaAdi) then
      begin

        DosyaBulundu := True;
        TumGirislerOkundu := True;
        SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Dosya Ad�: %s, S�ra No: %d',
          [DosyaArama.DosyaAdi, DizinGirisi.DizinTablosuKayitNo]);
      end;
    end;

    if not(TumGirislerOkundu) then
    begin

      // bir sonraki girdiye konumlan
      Inc(DizinGirisi.DizinTablosuKayitNo);
      if(DizinGirisi.DizinTablosuKayitNo = 16) then
      begin

        Inc(ZincirNo);
        if(ZincirNo = ZincirSektorSayisi - 1) then
        begin

          TumGirislerOkundu := True;
          DosyaBulundu := True;     // ��k�� i�in, a�a��daki kodlar�n devreye girmemesi i�in

          { TODO - fat tablosundan bir sonraki al�nan giri�le deva� edilecektir, kodlamay� yap }
        end else DizinGirisi.DizinTablosuKayitNo := 0
      end else Inc(DizinGirdisi);
    end;

  until TumGirislerOkundu;

  // dosya olu�turma i�lemi
  if not(DosyaBulundu) then
  begin

    if(DizinGirisi.DizinTablosuKayitNo >= 0) and (DizinGirisi.DizinTablosuKayitNo < 16) then
    begin

      FillChar(Bellek2, Length(DosyaKayit^.DosyaAdi), $20);

      for i := 1 to Length(DosyaKayit^.DosyaAdi) do
      begin

        Bellek2[i - 1] := Ord(DosyaKayit^.DosyaAdi[i]);
      end;

      Tasi2(@Bellek2, @Bellek[DizinGirisi.DizinTablosuKayitNo * 32], 32);

      //FillChar(Bellek, 512, $0);
      FD.SektorYaz(@FD, SektorNo + ZincirNo, 1, Isaretci(@Bellek));
    end;
  end;
end;

function HamDosyaAdiniDosyaAdinaCevir2(ADizinGirdisi: PDizinGirdisi): string;
var
  NoktaEklendi: Boolean;
  i: TSayi4;
begin

  // hedef bellek b�lgesini s�f�rla
  // hedef bellek alan� �u an 8+1+3+1 (dosya+.+uz+null) olmal�d�r
  Result := '';

  // dosya ad�n� �evir
  i := 0;
  while (i < 8) and (ADizinGirdisi^.DosyaAdi[i] <> ' ') do
  begin

    Result := Result + LowerCase(ADizinGirdisi^.DosyaAdi[i]);
    Inc(i);
  end;
end;

{==============================================================================
  dosyay� okumadan �nce �n haz�rl�k i�levlerini ger�ekle�tirir
 ==============================================================================}
procedure Reset(ADosyaKimlik: TKimlik);
var
  DosyaKayit: PDosyaKayit;
  DosyaArama: TDosyaArama;
  TamAramaYolu: string;
  Bulundu: Boolean;
begin

  // en son i�lem hatal� ise ��k
  if(FileResult > 0) then Exit;

  // dosya i�lem yap�s� bellek b�lgesine konumlan
  DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

  // tam dosya ad�n� al
  TamAramaYolu := DosyaKayit^.MantiksalDepolama^.MD3.AygitAdi + ':' + DosyaKayit^.Klasor + '*.*';

  // dosyay� dosya tablosunda bul
  Bulundu := False;
  if(FindFirst(TamAramaYolu, 0, DosyaArama) = 0) then
  begin

    repeat

      if(DosyaArama.DosyaAdi = DosyaKayit^.DosyaAdi) then Bulundu := True;
    until (Bulundu) or (FindNext(DosyaArama) <> 0);

    FindClose(DosyaArama);
  end;

  // dosyan�n tabloda bulunmas� halinde
  // dosyan�n ilk dizi ve uzunlu�unu al
  if(Bulundu) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Reset: %d', [DosyaArama.DosyaUzunlugu]);

    DosyaKayit^.IlkZincirSektor := DosyaArama.BaslangicKumeNo;
    DosyaKayit^.Uzunluk := DosyaArama.DosyaUzunlugu;
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
  DosyaKayit: PDosyaKayit;
  DST: TSayi4;
begin

  Result := 0;

  // en son i�lem hatal� ise ��k
  if(FileResult > 0) then Exit;

  // dosya i�lem yap�s� bellek b�lgesine konumlan
  DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

  DST := DosyaKayit^.MantiksalDepolama^.MD3.DST;

  if(DST = DST_ELR1) then

    elr1.Read(ADosyaKimlik, AHedefBellek)

  else if(DST = DST_FAT12) then

    fat12.Read(ADosyaKimlik, AHedefBellek)

  else if(DST = DST_FAT16) then

    fat16.Read(ADosyaKimlik, AHedefBellek)

  else if(DST = DST_FAT32) or (DST = DST_FAT32LBA) then

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
