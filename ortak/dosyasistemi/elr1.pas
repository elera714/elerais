{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: elr1.pas
  Dosya ��levi: ELERA ��letim Sistemi'nin dosya sistemi

  G�ncelleme Tarihi: 28/02/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit elr1;

interface

uses paylasim, islevler;

function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
  var ADosyaArama: TDosyaArama): TISayi4;
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
procedure Assign(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
procedure ReWrite(ADosyaKimlik: TKimlik);
procedure Reset(ADosyaKimlik: TKimlik);
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
procedure Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci);
function IOResult: TISayi4;
function FileSize(ADosyaKimlik: TKimlik): TISayi4;
function EOF(ADosyaKimlik: TKimlik): Boolean;
procedure Close(ADosyaKimlik: TKimlik);
procedure CreateDir(ADosyaKimlik: TKimlik);
procedure RemoveDir(const AKlasorAdi: string);

function DizinGirdisiOku(ADizinGirisi: PDizinGirisi; AAranacakDeger: string;
  var ADosyaArama: TDosyaArama): TSayi1;
procedure SHTOlustur(AIlkSektor, AToplamSektor, AAyrilanSektor: TSayi4);
function SHTBosKumeTahsisEt: TSayi4;
function SHTBosKumeSerbestBirak(AKumeNo: TSayi4): Boolean;
function HamDosyaAdiniDosyaAdinaCevir3(ADizinGirdisi: PDizinGirdisiELR): string;

implementation

uses genel, donusum, gercekbellek, cmos, sistemmesaj;

var
  DizinBellekAdresi: array[0..511] of TSayi1;

{==============================================================================
  dosya arama i�levini ba�lat�r
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
  dosya arama i�lemine devam eder
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
  dosya arama i�lemini sonland�r�r
 ==============================================================================}
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
begin

  Result := 0;
end;

{==============================================================================
  dosyalar ile ilgili i�lem yapmadan �nce tan�m i�levlerini ger�ekle�tirir
 ==============================================================================}
procedure Assign(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
begin
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
  SektorNo, i, ZincirNo, ZincirSektorSayisi,
  OkunanSektor2: TSayi4;
  MD: PMantiksalDepolama;
  DizinGirdisi, DG: PDizinGirdisiELR;
  TumGirislerOkundu,
  DosyaBulundu: Boolean;
  DizinGirisi: TDizinGirisi;
  Gun, Ay, Yil, HG: TSayi2;
  Saat, Dakika, Saniye: TSayi1;
begin

  DosyaBulundu := False;

  // her bir cluster'in 4 sekt�r olarak tasarland��� elr-1 dosya sistemi

  // en son i�lem hatal� ise ��k
  if(FileResult > 0) then Exit;

  //ADosyaArama.DosyaAdi := '';

  // ilk de�er atamalar�
  TumGirislerOkundu := False;

  // araman�n yap�laca�� s�r�c�
  //MD := GAramaKayitListesi[ADosyaArama.Kimlik].MantiksalDepolama;
  //DizinGirisi := @GAramaKayitListesi[ADosyaKimlik].DizinGirisi;

  // dosya i�lem yap�s� bellek b�lgesine konumlan
  DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

  SektorNo := DosyaKayit^.MantiksalDepolama^.Acilis.DizinGirisi.IlkSektor;

  DizinGirisi.DizinTablosuKayitNo := 0;
  DizinGirisi.OkunanSektor := 0;
  ZincirSektorSayisi := 4;  // ge�ici de�er
  ZincirNo := 0;

  FD := FizikselDepolamaAygitListesi[3];  // fda4

  // aramaya ba�la
  repeat

    if(DizinGirisi.DizinTablosuKayitNo = 0) then
    begin

      OkunanSektor2 := SektorNo + ZincirNo;

      // bir sonraki dizin giri�ini oku
      FD.SektorOku(@FD, OkunanSektor2, 1, Isaretci(@DosyaKayit^.SektorIcerigi[0]));

      // DizinGirisi.OkunanSektor de�i�keni elr dosya sisteminde anlams�z
      // Inc(DizinGirisi.OkunanSektor);
    end;

    // dosya giri� tablosuna konumlan
    DizinGirdisi := PDizinGirdisiELR(@DosyaKayit^.SektorIcerigi[0]);
    Inc(DizinGirdisi, DizinGirisi.DizinTablosuKayitNo);

    // dosya giri�inin ilk karakteri #0 ise giri�ler okunmu� demektir
    if(DizinGirdisi^.DosyaAdi[0] = #00) then
    begin

      //Result := 1;
      TumGirislerOkundu := True;
      //Exit;

      DosyaKayit^.SektorNo := OkunanSektor2;
      DosyaKayit^.KayitSN := DizinGirisi.DizinTablosuKayitNo;
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
    // dizin girdisinin uzun ad haricinde olmas� durumunda
    else //if(DizinGirdisi^.Ozellikler <> $0F) then
    begin

      DosyaArama.DosyaAdi := HamDosyaAdiniDosyaAdinaCevir3(DizinGirdisi);
      DosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
      DosyaArama.OlusturmaTarihi := DizinGirdisi^.OlusturmaTarihi;
      DosyaArama.OlusturmaSaati := DizinGirdisi^.OlusturmaSaati;
      DosyaArama.SonErisimTarihi := 0;
      DosyaArama.SonDegisimTarihi := DizinGirdisi^.DegisimTarihi;
      DosyaArama.SonDegisimSaati := DizinGirdisi^.DegisimSaati;

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

        DosyaKayit^.SektorNo := OkunanSektor2;
        DosyaKayit^.KayitSN := DizinGirisi.DizinTablosuKayitNo;
        DosyaKayit^.KumeNo := DizinGirdisi^.BaslangicKumeNo;
        DosyaBulundu := True;
        TumGirislerOkundu := True;
      end;
    end;

    if not(TumGirislerOkundu) then
    begin

      // bir sonraki girdiye konumlan
      Inc(DizinGirisi.DizinTablosuKayitNo);
      if(DizinGirisi.DizinTablosuKayitNo = 8) then
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
  if(DosyaBulundu) then
  begin

    SHTBosKumeSerbestBirak(DosyaKayit^.KumeNo);

    TarihAl(Gun, Ay, Yil, HG);
    SaatAl(Saat, Dakika, Saniye);

    DG := PDizinGirdisiELR(@DosyaKayit^.DizinGirdisi[0]);
    DG^.OlusturmaTarihi := ELRTarih(Gun, Ay, Yil);
    DG^.OlusturmaSaati := ELRSaat(Saat, Dakika, Saniye);
    DG^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
    DG^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);
    DG^.BaslangicKumeNo := 0;
    DG^.DosyaUzunlugu := 0;

    Tasi2(@DosyaKayit^.DizinGirdisi[0], @DosyaKayit^.SektorIcerigi[DosyaKayit^.KayitSN * 64], 64);

    FD.SektorYaz(@FD, DosyaKayit^.SektorNo, 1, Isaretci(@DosyaKayit^.SektorIcerigi[0]));
  end
  else
  begin

    if(DizinGirisi.DizinTablosuKayitNo >= 0) and (DizinGirisi.DizinTablosuKayitNo < 8) then
    begin

      TarihAl(Gun, Ay, Yil, HG);
      SaatAl(Saat, Dakika, Saniye);

      DG := PDizinGirdisiELR(@DosyaKayit^.DizinGirdisi[0]);
      DG^.OlusturmaTarihi := ELRTarih(Gun, Ay, Yil);
      DG^.OlusturmaSaati := ELRSaat(Saat, Dakika, Saniye);
      DG^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
      DG^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);
      DG^.BaslangicKumeNo := 0;
      DG^.DosyaUzunlugu := 0;

      Tasi2(@DosyaKayit^.DizinGirdisi[0], @DosyaKayit^.SektorIcerigi[DosyaKayit^.KayitSN * 64], 64);

      FD.SektorYaz(@FD, DosyaKayit^.SektorNo, 1, Isaretci(@DosyaKayit^.SektorIcerigi[0]));
    end;
  end;
end;

{==============================================================================
  dosyay� okumadan �nce �n haz�rl�k i�levlerini ger�ekle�tirir
 ==============================================================================}
procedure Reset(ADosyaKimlik: TKimlik);
begin
end;

{==============================================================================
  dosyaya veri yazma i�lemini ger�ekle�tirir
 ==============================================================================}
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
var
  DosyaKayit: PDosyaKayit;
  DosyaArama: TDosyaArama;
  TamAramaYolu: string;
  Bulundu: Boolean;
  FD: TFizikselDepolama;
  BosKumeNo, i, ZincirNo, ZincirSektorSayisi: TSayi4;
  MD: PMantiksalDepolama;
  DizinGirdisi: PDizinGirdisiELR;
  TumGirislerOkundu,
  DosyaBulundu: Boolean;
  DizinGirisi: TDizinGirisi;
  VeriU: TSayi4;
  DP: PDizinGirdisiELR;
  Veri: array[0..511] of TSayi1;
begin

  BosKumeNo := SHTBosKumeTahsisEt;

  VeriU := Length(AVeri);

  FillChar(Veri[0], 512, 0);
  Tasi2(@AVeri[1], @Veri[0], VeriU);

  // i�lem yap�lan dosyayla ilgili bellek b�lgesine konumlan
  DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

  // �zerinde i�lem yap�lacak s�r�c�
  MD := DosyaKayit^.MantiksalDepolama;

  DP := @DosyaKayit^.SektorIcerigi[DosyaKayit^.KayitSN * 64];
  DP^.BaslangicKumeNo := BosKumeNo;
  DP^.DosyaUzunlugu := VeriU;

  //Tasi2(@DosyaKayit^.DizinGirdisi[0], @DosyaKayit^.SektorIcerigi[DizinGirisi.DizinTablosuKayitNo * 64], 64);

  MD^.FD^.SektorYaz(MD^.FD, DosyaKayit^.SektorNo, 1, @DosyaKayit^.SektorIcerigi[0]);


  MD^.FD^.SektorYaz(MD^.FD, BosKumeNo * 4, 1, @Veri[0]);

  Exit;

  DosyaBulundu := False;

  // her bir cluster'in 4 sekt�r olarak tasarland��� elr-1 dosya sistemi

  BosKumeNo := $600; //1536;

  // en son i�lem hatal� ise ��k
  if(FileResult > 0) then Exit;

  //ADosyaArama.DosyaAdi := '';

  // ilk de�er atamalar�
  TumGirislerOkundu := False;

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
      //FD.SektorOku(@FD, BosKumeNo + ZincirNo, 1, Isaretci(@Bellek));

      // DizinGirisi.OkunanSektor de�i�keni elr dosya sisteminde anlams�z
      // Inc(DizinGirisi.OkunanSektor);
    end;

    // dosya giri� tablosuna konumlan
    {DizinGirdisi := PDizinGirdisiELR(@Bellek);
    Inc(DizinGirdisi, DizinGirisi.DizinTablosuKayitNo);}

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
    // dizin girdisinin uzun ad haricinde olmas� durumunda
    else //if(DizinGirdisi^.Ozellikler <> $0F) then
    begin

      begin

        {DosyaArama.DosyaAdi := HamDosyaAdiniDosyaAdinaCevir3(DizinGirdisi);
        DosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
        DosyaArama.OlusturmaSaati := DizinGirdisi^.OlusturmaSaati;
        DosyaArama.OlusturmaTarihi := DizinGirdisi^.OlusturmaTarihi;
        DosyaArama.SonErisimTarihi := DizinGirdisi^.SonErisimTarihi;
        DosyaArama.SonDegisimSaati := DizinGirdisi^.SonDegisimSaati;
        DosyaArama.SonDegisimTarihi := DizinGirdisi^.SonDegisimTarihi;}
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
      if(DizinGirisi.DizinTablosuKayitNo = 8) then
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

    if(DizinGirisi.DizinTablosuKayitNo >= 0) and (DizinGirisi.DizinTablosuKayitNo < 8) then
    begin

      {FillChar(Bellek2, 43, #0);

      Bellek2[0] := Length(DosyaKayit^.DosyaAdi);

      for i := 1 to Length(DosyaKayit^.DosyaAdi) do
      begin

        Bellek2[i] := Ord(DosyaKayit^.DosyaAdi[i]);
      end;}

      //Tasi2(@Bellek2, @Bellek[DizinGirisi.DizinTablosuKayitNo * 64], 64);

      //FillChar(Bellek, 512, $0);
      //FD.SektorYaz(@FD, BosKumeNo + ZincirNo, 1, Isaretci(@Bellek));
    end;
  end;
end;

{==============================================================================
  dosya okuma i�lemini ger�ekle�tirir
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

  // i�lem yap�lan dosyayla ilgili bellek b�lgesine konumlan
  DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

  // �zerinde i�lem yap�lacak s�r�c�
  MD := DosyaKayit^.MantiksalDepolama;

  OkunacakVeri := DosyaKayit^.Uzunluk;

  // sekt�r� belle�e oku
  MD^.FD^.SektorOku(MD^.FD, DosyaKayit^.IlkZincirSektor * 4, 1, @DATBellekAdresi);

  Tasi2(@DATBellekAdresi[0], AHedefBellek, OkunacakVeri);

  //SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, '�lk Zincir: %x', [DosyaKayit^.IlkZincirSektor]);
  //SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Dosya Uzunluk: %d', [OkunacakVeri]);

  Exit;

  Zincir := DosyaKayit^.IlkZincirSektor;

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

    // sekt�r� belle�e oku
    MD^.FD^.SektorOku(MD^.FD, i, OkunacakSektorSayisi, AHedefBellek);

    // okunacak bilginin yerle�tirilece�i bir sonraki adresi belirle
    AHedefBellek += KopyalanacakVeriUzunlugu;

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
  dosya ile yap�lm�� en son i�lem sonucunu d�nd�r�r
 ==============================================================================}
function IOResult: TISayi4;
begin
end;

{==============================================================================
  dosya uzunlu�unu geri d�nd�r�r
 ==============================================================================}
function FileSize(ADosyaKimlik: TKimlik): TISayi4;
begin

  Result := 0;
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
procedure Close(ADosyaKimlik: TKimlik);
begin
end;

{==============================================================================
  dosya olu�turma i�levini ger�ekle�tirir
 ==============================================================================}
procedure CreateDir(ADosyaKimlik: TKimlik);
begin

end;

{==============================================================================
  klas�r silme i�levini ger�ekle�tirir
 ==============================================================================}
procedure RemoveDir(const AKlasorAdi: string);
begin

end;

{==============================================================================
  dosya silme i�levini ger�ekle�tirir
 ==============================================================================}
function DeleteFile(const ADosyaAdi: string): TISayi4;
begin

end;

{==============================================================================
  dizin giri�inden ilgili bilgileri al�r
 ==============================================================================}
function DizinGirdisiOku(ADizinGirisi: PDizinGirisi; AAranacakDeger: string;
 var ADosyaArama: TDosyaArama): TSayi1;
var
  MD: PMantiksalDepolama;
  DizinGirdisi: PDizinGirdisiELR;
  TumGirislerOkundu: Boolean;
begin

  ADosyaArama.DosyaAdi := '';

  // ilk de�er atamalar�
  TumGirislerOkundu := False;

  // araman�n yap�laca�� s�r�c�
  MD := GAramaKayitListesi[ADosyaArama.Kimlik].MantiksalDepolama;

  // aramaya ba�la
  repeat

    if(ADizinGirisi^.DizinTablosuKayitNo = 0) then
    begin

      // bir sonraki dizin giri�ini oku
      MD^.FD^.SektorOku(MD^.FD, ADizinGirisi^.IlkSektor + ADizinGirisi^.OkunanSektor,
        1, @DizinBellekAdresi);

      Inc(ADizinGirisi^.OkunanSektor);
    end;

    // dosya giri� tablosuna konumlan
    DizinGirdisi := PDizinGirdisiELR(@DizinBellekAdresi);
    Inc(DizinGirdisi, ADizinGirisi^.DizinTablosuKayitNo);

    // dosya giri�inin ilk karakteri #0 ise giri�ler okunmu� demektir
    if(DizinGirdisi^.DosyaAdi[0] = #00) then
    begin

      Result := 1;
      TumGirislerOkundu := True;
    end
    // silinmi� dosya / dizin
    else if(DizinGirdisi^.DosyaAdi[0] = Chr($FF)) then
    begin

      // bir sonraki giri�le devam et
    end
    // mant�ksal depolama ayg�t� etiket (volume label)
{    else if(DizinGirdisi^.Ozellikler = $08) then
    begin

      // bir sonraki giri�le devam et
    end}
    // dizin girdisinin uzun ad haricinde olmas� durumunda
    else //if(DizinGirdisi^.Ozellikler <> $0F) then
    begin

      ADosyaArama.DosyaAdi := HamDosyaAdiniDosyaAdinaCevir2(DizinGirdisi);
      ADosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
      ADosyaArama.OlusturmaTarihi := DizinGirdisi^.OlusturmaTarihi;
      ADosyaArama.OlusturmaSaati := DizinGirdisi^.OlusturmaSaati;
      ADosyaArama.SonErisimTarihi := 0;
      ADosyaArama.SonDegisimTarihi := DizinGirdisi^.DegisimTarihi;
      ADosyaArama.SonDegisimSaati := DizinGirdisi^.DegisimSaati;

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
    Inc(ADizinGirisi^.DizinTablosuKayitNo);
    if(ADizinGirisi^.DizinTablosuKayitNo = 8) then
      ADizinGirisi^.DizinTablosuKayitNo := 0
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
  sekt�r harita tablosunu olu�turur
 ==============================================================================}
procedure SHTOlustur(AIlkSektor, AToplamSektor, AAyrilanSektor: TSayi4);
var
  Bellek: array[0..511] of TSayi1;
  FD: TFizikselDepolama;
  i, j: TSayi4;
begin

  { TODO - burada kat� kodlama uygulanm��t�r, kodlar kontrol edilecektir }

  // sht i�in ayr�lan sekt�rleri s�f�rla
  FillChar(Bellek, 512, 0);
  FD := FizikselDepolamaAygitListesi[3];  // fda4

  for i := AIlkSektor to (AIlkSektor + AToplamSektor) - 1 do
  begin

    FD.SektorYaz(@FD, i, 1, Isaretci(@Bellek));
  end;

  // ayr�lan sekt�rleri ayr�lm�� olarak i�aretle
  // buraya gelen de�er �u a�amada 1536 olacak
  // 1536 / 128 (bir sekt�rdeki giri� say�s�) = 12

  // sekt�r say�s� k�me say�s�na �evriliyor
  j := AAyrilanSektor div 4;

  // k�me i�in gereken alan hesaplan�yor
  // her bir k�me girdisi i�in 4 byte'e ihtiya� var
  j := j * 4;

  // girdiler i�in gereken sekt�r say�s� hesaplan�yor
  j := j div 512;

  FillChar(Bellek, 512, $FF);
  FD := FizikselDepolamaAygitListesi[3];  // fda4

  for i := AIlkSektor to (AIlkSektor + j) - 1 do
  begin

    FD.SektorYaz(@FD, i, 1, Isaretci(@Bellek));
  end;

  // ilk dizin giri�ini ay�r
  FillChar(Bellek, 512, 0);
  PSayi4(@Bellek)^ := $FFFFFFFF;
  FD := FizikselDepolamaAygitListesi[3];  // fda4

  FD.SektorYaz(@FD, i + 1, 1, Isaretci(@Bellek));
end;

{==============================================================================
  sekt�r harita tablosundan bo� k�me numaras� al�r
 ==============================================================================}
 function SHTBosKumeTahsisEt: TSayi4;
var
  Bellek: array[0..511] of TSayi1;
  FD: TFizikselDepolama;
  KumeNo, i, j: TSayi4;
  Deger: PSayi4;
begin

  // t�m sekt�rler dolu
  KumeNo := 0;

  FD := FizikselDepolamaAygitListesi[3];  // fda4

  for i := 256 to (256 + 1280) - 1 do
  begin

    FD.SektorOku(@FD, i, 1, Isaretci(@Bellek));

    Deger := @Bellek;
    for j := 0 to 128 - 1 do
    begin

      if(Deger^ = 0) then
      begin

        Deger^ := $FFFFFFFF;
        FD.SektorYaz(@FD, i, 1, Isaretci(@Bellek));
        Exit(KumeNo);
      end;

      Inc(KumeNo);
      Inc(Deger);
    end;
  end;

  Result := $FFFFFFFF;    // bo� sekt�r yok
end;

{==============================================================================
  sekt�r harita tablosundan al�nan sekt�r k�mesini serbest b�rak�r
 ==============================================================================}
function SHTBosKumeSerbestBirak(AKumeNo: TSayi4): Boolean;
var
  Bellek: array[0..511] of TSayi1;
  FD: TFizikselDepolama;
  SektorNo, SiraNo, j: TSayi4;
  Deger: PSayi4;
begin

  // konumlan�lacak sekt�r numaras�
  SektorNo := AKumeNo div 128;
  SiraNo := AKumeNo mod 128;

  FD := FizikselDepolamaAygitListesi[3];  // fda4

  //for i := 256 to (256 + 1280) - 1 do
  begin

    FD.SektorOku(@FD, 256 + SektorNo, 1, Isaretci(@Bellek));

    Deger := @Bellek;
    Inc(Deger, SiraNo);
    if(Deger^ = $FFFFFFFF) then
    begin

      Deger^ := $0;
      FD.SektorYaz(@FD, 256 + SektorNo, 1, Isaretci(@Bellek));
      Exit(True);
    end;
  end;

  Result := False;
end;

function HamDosyaAdiniDosyaAdinaCevir3(ADizinGirdisi: PDizinGirdisiELR): string;
var
  NoktaEklendi: Boolean;
  i: TSayi4;
begin

  // hedef bellek b�lgesini s�f�rla
  // hedef bellek alan� �u an 8+1+3+1 (dosya+.+uz+null) olmal�d�r
  Result := '';

  // dosya ad�n� �evir
  i := 1;
  while (i < 43) and (ADizinGirdisi^.DosyaAdi[i] <> #0) do
  begin

    Result := Result + ADizinGirdisi^.DosyaAdi[i];
    Inc(i);
  end;
end;

end.
