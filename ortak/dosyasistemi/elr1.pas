{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: elr1.pas
  Dosya ��levi: ELERA ��letim Sistemi'nin dosya sistemi

  G�ncelleme Tarihi: 13/05/2025

  Kaynaklar: https://wiki.freepascal.org/File_Handling_In_Pascal

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
procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
procedure ReWrite(ADosyaKimlik: TKimlik);
procedure Append(ADosyaKimlik: TKimlik);
procedure Reset(ADosyaKimlik: TKimlik);
procedure Write0(ADosyaKimlik: TKimlik; ABellek: Isaretci; AUzunluk: TSayi4);
procedure Write0Eski(ADosyaKimlik: TKimlik; ABellek: Isaretci; AUzunluk: TSayi4);
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
procedure WriteLn(ADosyaKimlik: TKimlik; AVeri: string);
procedure Write(ADosyaKimlik: TKimlik; ABellekAdresi: Isaretci; AUzunluk: TSayi4);
procedure Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci);
function IOResult: TISayi4;
function FileSize(ADosyaKimlik: TKimlik): TISayi4;
function EOF(ADosyaKimlik: TKimlik): Boolean;
procedure CloseFile(ADosyaKimlik: TKimlik);
procedure CreateDir(ADosyaKimlik: TKimlik);
procedure RemoveDir(const AKlasorAdi: string);
function DeleteFile(const ADosyaAdi: string): TISayi4;

function DizinGirdisiOku(ADizinGirisi: PDizinGirisi; AAranacakDeger: string;
  var ADosyaArama: TDosyaArama): TSayi1;

procedure ELR1DiskBicimle(AMD: PMantiksalDepolama);
procedure ELR1VerileriSil(AMD: PMantiksalDepolama);
procedure ELR1SHTOlustur(AMD: PMantiksalDepolama; AIlkSektor, AToplamSektor,
 AAyrilanSektor: TSayi4);
function SHTBosKumeTahsisEt(AMD: PMantiksalDepolama): TSayi4;
function SHTBosKumeSerbestBirak(AMD: PMantiksalDepolama; AKumeNo: TSayi4): Boolean;
function SHTKumeyiBirOncekiKumeyeBagla(AMD: PMantiksalDepolama; ABirOncekiKumeNo,
 AKumeNo: TSayi4): Boolean;
function SHTBirSonrakiKumeyiAl(AMD: PMantiksalDepolama; AKumeNo: TSayi4): TSayi4;
function HamDosyaAdiniDosyaAdinaCevir3(ADizinGirdisi: PDizinGirdisiELR): string;

implementation

uses genel, donusum, gercekbellek, cmos, sistemmesaj;

var
  DizinBellekAdresi: array[0..511] of TSayi1;
  DosyaIslevNo: TSayi4 = 0;       // dosya i�levlerini test etmek i�in (ge�ici)
  OYBellek: DiziIsaretci1;        // okuma / yazma ama�l� kullan�lacak genel bellek

{==============================================================================
  dosya arama i�levini ba�lat�r
 ==============================================================================}
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
 var ADosyaArama: TDosyaArama): TISayi4;
var
  DizinGirisi: PDizinGirisi;
begin

  DizinGirisi := @GDosyaIslemleri[ADosyaArama.Kimlik].DizinGirisi;
  GDosyaIslemleri[ADosyaArama.Kimlik].Aranan := AAramaSuzgec;
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

  DizinGirisi := @GDosyaIslemleri[ADosyaArama.Kimlik].DizinGirisi;
  Aranan := GDosyaIslemleri[ADosyaArama.Kimlik].Aranan;
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
end;

{==============================================================================
  dosya olu�turma i�levini ger�ekle�tirir
 ==============================================================================}
procedure ReWrite(ADosyaKimlik: TKimlik);
var
  DosyaIslem: PDosyaIslem;
  DosyaArama: TDosyaArama;
  TamAramaYolu: string;
  Bulundu: Boolean;
  FD: TFizikselDepolama;
  SektorNo, i, ZincirNo, ZincirSektorSayisi,
  OkunanSektor2: TSayi4;
  MD: PMantiksalDepolama;
  AktifDG,                    // o an i�lem yap�lan dizin girdisi
  DG: PDizinGirdisiELR;
  TumGirislerOkundu,
  DosyaBulundu: Boolean;
  DizinGirisi: TDizinGirisi;
  Gun, Ay, Yil, HG: TSayi2;
  Saat, Dakika, Saniye: TSayi1;
begin

  DosyaIslevNo := 1;

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
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  // dosya daha �nce kapal� olmal�
  if(DosyaIslem^.DosyaDurumu <> ddKapali) then
  begin

    FileResult := 111;
    Exit;
  end;

  SektorNo := DosyaIslem^.MantiksalDepolama^.Acilis.DizinGirisi.IlkSektor;

  DizinGirisi.DizinTablosuKayitNo := 0;
  DizinGirisi.OkunanSektor := 0;
  ZincirSektorSayisi := 4;  // ge�ici de�er
  ZincirNo := 0;

  FD := DosyaIslem^.MantiksalDepolama^.FD^;

  // aramaya ba�la
  repeat

    if(DizinGirisi.DizinTablosuKayitNo = 0) then
    begin

      OkunanSektor2 := SektorNo + ZincirNo;

      // bir sonraki dizin giri�ini oku
      FD.SektorOku(@FD, OkunanSektor2, 1, Isaretci(@DosyaIslem^.DGTekSektorIcerik[0]));

      // DizinGirisi.OkunanSektor de�i�keni elr dosya sisteminde anlams�z
      // Inc(DizinGirisi.OkunanSektor);
    end;

    // dosya giri� tablosuna konumlan
    AktifDG := PDizinGirdisiELR(@DosyaIslem^.DGTekSektorIcerik[0]);
    Inc(AktifDG, DizinGirisi.DizinTablosuKayitNo);

    // dosya giri�inin ilk karakteri #0 ise giri�ler okunmu� demektir
    if(AktifDG^.DosyaAdi[0] = #00) then
    begin

      //Result := 1;
      TumGirislerOkundu := True;
      //Exit;

      DosyaIslem^.SektorNo := OkunanSektor2;
      DosyaIslem^.SN := DizinGirisi.DizinTablosuKayitNo;
    end
    // silinmi� dosya / dizin
    else if(AktifDG^.DosyaAdi[0] = Chr($E5)) then
    begin

      // bir sonraki giri�le devam et
    end
    // mant�ksal depolama ayg�t� etiket (volume label)
    else if(AktifDG^.Ozellikler = $08) then
    begin

      // bir sonraki giri�le devam et
    end
    // dizin girdisinin uzun ad haricinde olmas� durumunda
    else //if(DizinGirdisi^.Ozellikler <> $0F) then
    begin

      DosyaArama.DosyaAdi := HamDosyaAdiniDosyaAdinaCevir3(AktifDG);
      DosyaArama.Ozellikler := AktifDG^.Ozellikler;
      DosyaArama.OlusturmaTarihi := AktifDG^.OlusturmaTarihi;
      DosyaArama.OlusturmaSaati := AktifDG^.OlusturmaSaati;
      DosyaArama.SonErisimTarihi := 0;
      DosyaArama.SonDegisimTarihi := AktifDG^.DegisimTarihi;
      DosyaArama.SonDegisimSaati := AktifDG^.DegisimSaati;

      // dosya uzunlu�u ve cluster ba�lang�c�n� geri d�n�� de�erine ekle
      DosyaArama.DosyaUzunlugu := AktifDG^.DosyaUzunlugu;
      DosyaArama.BaslangicKumeNo := AktifDG^.BaslangicKumeNo;

      // g�zard� edilecek giri�ler
      if(DosyaArama.DosyaAdi = '.') then
      begin

      end
      else
      begin

        //Result := 0;
        //TumGirislerOkundu := True;
      end;

      if(DosyaArama.DosyaAdi = DosyaIslem^.DosyaAdi) then
      begin

        DosyaIslem^.GirdiTipi := AktifDG^.GirdiTipi;
        DosyaIslem^.Ozellikler := AktifDG^.Ozellikler;

        DosyaIslem^.SektorNo := OkunanSektor2;
        DosyaIslem^.SN := DizinGirisi.DizinTablosuKayitNo;
        DosyaIslem^.KumeNo := AktifDG^.BaslangicKumeNo;

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
      end else Inc(AktifDG);
    end;

  until TumGirislerOkundu;

  // dosya olu�turma i�lemi

  // 1. dosyan�n mevcut olmas� durumunda
  if(DosyaBulundu) then
  begin

    { TODO - bu i�lev write i�levine dinamik olarak eklenecek }
    if(DosyaIslem^.KumeNo <> ELR_ZD_SON) then
      SHTBosKumeSerbestBirak(DosyaIslem^.MantiksalDepolama, DosyaIslem^.KumeNo);

    // aktif tarih / saat bilgilerini al
    TarihAl(Gun, Ay, Yil, HG);
    SaatAl(Saat, Dakika, Saniye);

    // 2.1. g�ncel veriler �ncelikle aktif dizin giri�ine aktar�lacak
    DG := PDizinGirdisiELR(@DosyaIslem^.DGAktif[0]);
    //DG^.GirdiTipi := ELR_GT_DOSYA;
    //DG^.Ozellikler := ELR_O_NORMAL;
    DG^.OlusturmaTarihi := ELRTarih(Gun, Ay, Yil);
    DG^.OlusturmaSaati := ELRSaat(Saat, Dakika, Saniye);
    DG^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
    DG^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);
    DG^.BaslangicKumeNo := ELR_ZD_SON;
    DG^.DosyaUzunlugu := 0;

    // 2.2 daha sonra g�ncel veriler sekt�r i�eri�ine ta��nacak
    Tasi2(@DosyaIslem^.DGAktif[0], @DosyaIslem^.DGTekSektorIcerik[DosyaIslem^.SN * ELR_DG_U],
      ELR_DG_U);

    // aktif dizin giri�inin bulundu�u sekt�r� g�ncelle (�zerine yaz)
    FD.SektorYaz(@FD, DosyaIslem^.SektorNo, 1, Isaretci(@DosyaIslem^.DGTekSektorIcerik[0]));

    // dosya durumunu, "dosya yaz�m i�in a��ld�" olarak g�ncelle
    DosyaIslem^.DosyaDurumu := ddYazmaIcinAcik;
  end
  else
  begin

    if(DizinGirisi.DizinTablosuKayitNo >= 0) and (DizinGirisi.DizinTablosuKayitNo < 8) then
    begin

      // aktif tarih / saat bilgilerini al
      TarihAl(Gun, Ay, Yil, HG);
      SaatAl(Saat, Dakika, Saniye);

      // 2.1. g�ncel veriler �ncelikle aktif dizin giri�ine aktar�lacak
      DG := PDizinGirdisiELR(@DosyaIslem^.DGAktif[0]);
      DG^.GirdiTipi := ELR_GT_DOSYA;
      DG^.Ozellikler := ELR_O_NORMAL;
      DG^.OlusturmaTarihi := ELRTarih(Gun, Ay, Yil);
      DG^.OlusturmaSaati := ELRSaat(Saat, Dakika, Saniye);
      DG^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
      DG^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);
      DG^.BaslangicKumeNo := ELR_ZD_SON;
      DG^.DosyaUzunlugu := 0;

      // 2.2 daha sonra g�ncel veriler sekt�r i�eri�ine ta��nacak
      Tasi2(@DosyaIslem^.DGAktif[0], @DosyaIslem^.DGTekSektorIcerik[DosyaIslem^.SN * ELR_DG_U],
        ELR_DG_U);

      // aktif dizin giri�inin bulundu�u sekt�r� g�ncelle (�zerine yaz)
      FD.SektorYaz(@FD, DosyaIslem^.SektorNo, 1, Isaretci(@DosyaIslem^.DGTekSektorIcerik[0]));

      // dosya durumunu, "dosya yaz�m i�in a��ld�" olarak g�ncelle
      DosyaIslem^.DosyaDurumu := ddYazmaIcinAcik;
    end;
  end;
end;

{==============================================================================
  dosyaya veri eklemek i�in a�ma i�levlerini ger�ekle�tirir
 ==============================================================================}
procedure Append(ADosyaKimlik: TKimlik);
var
  DosyaIslem: PDosyaIslem;
  DosyaArama: TDosyaArama;
  TamAramaYolu: string;
  Bulundu: Boolean;
  FD: TFizikselDepolama;
  SektorNo, i, ZincirNo, ZincirSektorSayisi,
  OkunanSektor2: TSayi4;
  MD: PMantiksalDepolama;
  AktifDG,                    // o an i�lem yap�lan dizin girdisi
  DG: PDizinGirdisiELR;
  TumGirislerOkundu,
  DosyaBulundu: Boolean;
  DizinGirisi: TDizinGirisi;
  Gun, Ay, Yil, HG: TSayi2;
  Saat, Dakika, Saniye: TSayi1;
begin

  DosyaIslevNo := 2;

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
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  // dosya daha �nce kapal� olmal�
  if(DosyaIslem^.DosyaDurumu <> ddKapali) then
  begin

    FileResult := 111;
    Exit;
  end;

  SektorNo := DosyaIslem^.MantiksalDepolama^.Acilis.DizinGirisi.IlkSektor;

  DizinGirisi.DizinTablosuKayitNo := 0;
  DizinGirisi.OkunanSektor := 0;
  ZincirSektorSayisi := 4;  // ge�ici de�er
  ZincirNo := 0;

  FD := DosyaIslem^.MantiksalDepolama^.FD^;

  // aramaya ba�la
  repeat

    if(DizinGirisi.DizinTablosuKayitNo = 0) then
    begin

      OkunanSektor2 := SektorNo + ZincirNo;

      // bir sonraki dizin giri�ini oku
      FD.SektorOku(@FD, OkunanSektor2, 1, Isaretci(@DosyaIslem^.DGTekSektorIcerik[0]));

      // DizinGirisi.OkunanSektor de�i�keni elr dosya sisteminde anlams�z
      // Inc(DizinGirisi.OkunanSektor);
    end;

    // dosya giri� tablosuna konumlan
    AktifDG := PDizinGirdisiELR(@DosyaIslem^.DGTekSektorIcerik[0]);
    Inc(AktifDG, DizinGirisi.DizinTablosuKayitNo);

    // dosya giri�inin ilk karakteri #0 ise giri�ler okunmu� demektir
    if(AktifDG^.DosyaAdi[0] = #00) then
    begin

      //Result := 1;
      TumGirislerOkundu := True;
      //Exit;

      DosyaIslem^.SektorNo := OkunanSektor2;
      DosyaIslem^.SN := DizinGirisi.DizinTablosuKayitNo;
    end
    // silinmi� dosya / dizin
    else if(AktifDG^.DosyaAdi[0] = Chr($E5)) then
    begin

      // bir sonraki giri�le devam et
    end
    // mant�ksal depolama ayg�t� etiket (volume label)
    else if(AktifDG^.Ozellikler = $08) then
    begin

      // bir sonraki giri�le devam et
    end
    // dizin girdisinin uzun ad haricinde olmas� durumunda
    else //if(DizinGirdisi^.Ozellikler <> $0F) then
    begin

      DosyaArama.DosyaAdi := HamDosyaAdiniDosyaAdinaCevir3(AktifDG);
      DosyaArama.Ozellikler := AktifDG^.Ozellikler;
      DosyaArama.OlusturmaTarihi := AktifDG^.OlusturmaTarihi;
      DosyaArama.OlusturmaSaati := AktifDG^.OlusturmaSaati;
      DosyaArama.SonErisimTarihi := 0;
      DosyaArama.SonDegisimTarihi := AktifDG^.DegisimTarihi;
      DosyaArama.SonDegisimSaati := AktifDG^.DegisimSaati;

      // dosya uzunlu�u ve cluster ba�lang�c�n� geri d�n�� de�erine ekle
      DosyaArama.DosyaUzunlugu := AktifDG^.DosyaUzunlugu;
      DosyaArama.BaslangicKumeNo := AktifDG^.BaslangicKumeNo;

      // g�zard� edilecek giri�ler
      if(DosyaArama.DosyaAdi = '.') then
      begin

      end
      else
      begin

        //Result := 0;
        //TumGirislerOkundu := True;
      end;

      if(DosyaArama.DosyaAdi = DosyaIslem^.DosyaAdi) then
      begin

        DosyaIslem^.SektorNo := OkunanSektor2;
        DosyaIslem^.SN := DizinGirisi.DizinTablosuKayitNo;
        DosyaIslem^.KumeNo := AktifDG^.BaslangicKumeNo;
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
      end else Inc(AktifDG);
    end;

  until TumGirislerOkundu;

  // dosyan�n bulunmas� halinde dosyan�n durumunu yazma i�in a��k olarak belirt
  if(DosyaBulundu) then
  begin

    Tasi2(AktifDG, @DosyaIslem^.DGAktif, ELR_DG_U);

    DosyaIslem^.DosyaDurumu := ddYazmaIcinAcik;
  end else FileResult := 11;
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
procedure Write0(ADosyaKimlik: TKimlik; ABellek: Isaretci; AUzunluk: TSayi4);
var
  MD: PMantiksalDepolama;
  DosyaIslem: PDosyaIslem;
  SHTyeYazilacakKumeNo,
  TahsisEdilenKumeNo: TSayi4;
  SektorNo, VeriU, i,
  OkumaKonum,
  ToplamYazilacakVeriU,            // toplam yaz�lacak veri uzunlu�u
  j, DosyaUzunlugu, SektorVeriU: TSayi4;
  DG1, DG2: PDizinGirdisiELR;
  Gun, Ay, Yil, HG: TSayi2;
  Saat, Dakika, Saniye, ZincirBasinaSektor: TSayi1;
  TumVerilerYazildi, YeniKumeNumarasiAl: Boolean;
  YazilacakSektorSayisi, YazilacakKumeNo: Integer;
begin

  // en son i�lem hatal� ise ��k
  if(FileResult > 0) then Exit;

  // i�lem yap�lan dosyayla ilgili bellek b�lgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  {if(DosyaIslevNo = 2) then
  begin

    DG := PDizinGirdisiELR(@DosyaIslem^.DGAktif[0]);

    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'DG^.DosyaUzunlugu: %d', [DG^.DosyaUzunlugu]);
    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'DG^.BaslangicKumeNo: %x', [DG^.BaslangicKumeNo]);
    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'DG^.GirdiTipi: %d', [DG^.GirdiTipi]);
    Exit;
  end;}

  if not(DosyaIslem^.DosyaDurumu = ddYazmaIcinAcik) then
  begin

    FileResult := 555;
    Exit;
  end;

  // �zerinde i�lem yap�lacak s�r�c�
  MD := DosyaIslem^.MantiksalDepolama;

  DG1 := PDizinGirdisiELR(@DosyaIslem^.DGAktif[0]);

  VeriU := AUzunluk;

  {if((DG^.DosyaUzunlugu + VeriU) > 2048) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Veri uzunlu�u 2048 bayt� ge�emez!', []);
    Exit;
  end;}

  TumVerilerYazildi := False;

  SHTyeYazilacakKumeNo := 0;

  if(DG1^.BaslangicKumeNo = ELR_ZD_SON) then
  begin
    SHTyeYazilacakKumeNo := SHTBosKumeTahsisEt(MD);
    TahsisEdilenKumeNo := SHTyeYazilacakKumeNo;
    //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'IlkTahsisEdilenKumeNo: %d', [IlkTahsisEdilenKumeNo]);
  end else TahsisEdilenKumeNo := DG1^.BaslangicKumeNo;

  ToplamYazilacakVeriU := VeriU;

  ZincirBasinaSektor := MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

  GetMem(Isaretci(OYBellek), 512 * ZincirBasinaSektor);

  DosyaUzunlugu := DG1^.DosyaUzunlugu;
  OkumaKonum := 0;

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'DosyaUzunlugu: %d!', [DosyaUzunlugu]);
  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ToplamVeriU: %d!', [ToplamVeriU]);

  YazilacakKumeNo := (DosyaUzunlugu div (512 * ZincirBasinaSektor));
  SektorNo := (DosyaUzunlugu div 512) mod 4;
  SektorVeriU := (DosyaUzunlugu mod 512);
  YeniKumeNumarasiAl := False;

  repeat

    if(YazilacakKumeNo > 0) then
    begin

      for i := 1 to YazilacakKumeNo do
      begin
        TahsisEdilenKumeNo := SHTBirSonrakiKumeyiAl(MD, TahsisEdilenKumeNo);
      end;
      //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'IlkTahsisEdilenKumeNo: %d!', [IlkTahsisEdilenKumeNo]);
      //Exit;
    end;

    // sekt�r�n bir k�sm�na yaz�m yap�lm��sa (ekleme yap�lacaksa), veriyi mevcut
    // veriye ekle ve ayg�t sekt�r�ne yaz
    if(SektorVeriU > 0) then
    begin

      FillChar(OYBellek[0], 512, $00);
      MD^.FD^.SektorOku(MD^.FD, (TahsisEdilenKumeNo * ZincirBasinaSektor) + SektorNo,
        1, @OYBellek[0]);

      j := 512 - SektorVeriU;
      if(j > ToplamYazilacakVeriU) then j := ToplamYazilacakVeriU;
      Tasi2(ABellek + OkumaKonum, @OYBellek[SektorVeriU], j);
      MD^.FD^.SektorYaz(MD^.FD, (TahsisEdilenKumeNo * ZincirBasinaSektor) + SektorNo,
        1, @OYBellek[0]);

      OkumaKonum += j;
      ToplamYazilacakVeriU -= j;

      if((SektorVeriU + j) = 512) then
      begin

        Inc(SektorNo);
        SektorNo := SektorNo mod 4;
        if(SektorNo = 0) then YeniKumeNumarasiAl := True;
      end;
    end;

    //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ToplamVeriU: %d!', [ToplamVeriU]);

    if(YeniKumeNumarasiAl) then
    begin

      i := SHTBosKumeTahsisEt(MD);
      SHTKumeyiBirOncekiKumeyeBagla(MD, TahsisEdilenKumeNo, i);
      TahsisEdilenKumeNo := i;

      SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'SonTahsisEdilenKumeNo: %d', [TahsisEdilenKumeNo]);
      //FreeMem(Isaretci(OYBellek), 2048);
      //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'yeni k�me numaras� al!', []);
      //Exit;
    end;

    // 3. �oklu sekt�r yaz�m� ger�ekle�tirilecek

    YeniKumeNumarasiAl := False;

    // bu a�amada sekt�r�n yar�m dolu olmas� mevzu bahis de�ildir
    // sekt�rler ba�� itibariyle (sonu de�il) 0'a odakl� olarak yaz�lacakt�r
    if(ToplamYazilacakVeriU > 0) then
    begin

      FillChar(OYBellek[0], 512 * ZincirBasinaSektor, $00);
      // ka� sekt�r yaz�lacak
      i := 4 - SektorNo;
      // hedef b�lgeye ka� byte kopyalanacak
      j := (4 - SektorNo) * 512;
      if(j > ToplamYazilacakVeriU) then j := ToplamYazilacakVeriU;
      Tasi2(ABellek + OkumaKonum, @OYBellek[0], j);
      MD^.FD^.SektorYaz(MD^.FD, (TahsisEdilenKumeNo * ZincirBasinaSektor) + SektorNo,
        i, @OYBellek[0]);

      OkumaKonum += j;
      ToplamYazilacakVeriU -= j;

      if(ToplamYazilacakVeriU > 0) then YeniKumeNumarasiAl := True;
    end;

    if(ToplamYazilacakVeriU = 0) then TumVerilerYazildi := True;

    YazilacakKumeNo := 0;
    SektorVeriU := 0;
    SektorNo := 0;

    // sonland�r
    //SHTKumeyiBirOncekiKumeyeBagla(MD, IlkTahsisEdilenKumeNo, SonTahsisEdilenKumeNo);

  until TumVerilerYazildi;

  FreeMem(Isaretci(OYBellek), 512 * ZincirBasinaSektor);

  if(SHTyeYazilacakKumeNo > 0) then DG1^.BaslangicKumeNo := SHTyeYazilacakKumeNo;
  DG1^.DosyaUzunlugu := DG1^.DosyaUzunlugu + VeriU;

  // aktif tarih / saat bilgilerini al
  TarihAl(Gun, Ay, Yil, HG);
  SaatAl(Saat, Dakika, Saniye);

  DG2 := @DosyaIslem^.DGTekSektorIcerik[DosyaIslem^.SN * ELR_DG_U];
  DG2^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
  DG2^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);
  if(SHTyeYazilacakKumeNo > 0) then DG2^.BaslangicKumeNo := SHTyeYazilacakKumeNo;
  DG2^.DosyaUzunlugu := DG2^.DosyaUzunlugu + VeriU;

  // dosyan�n g�ncel de�erlerini ilgili sekt�re yaz
  MD^.FD^.SektorYaz(MD^.FD, DosyaIslem^.SektorNo, 1, @DosyaIslem^.DGTekSektorIcerik[0]);
end;

{==============================================================================
  dosyaya veri yazma i�lemini ger�ekle�tirir - 2048 byte'l�k veri yazma i�lev deste�i
 ==============================================================================}
procedure Write0Eski(ADosyaKimlik: TKimlik; ABellek: Isaretci; AUzunluk: TSayi4);
var
  MD: PMantiksalDepolama;
  DosyaIslem: PDosyaIslem;
  YazilacakKumeNo: TSayi4;
  SektorNo, VeriU, YazilacakSN, i,
  OkunacakSN,
  ToplamVeriU,            // toplam yaz�lacak veri uzunlu�u
  j: TSayi4;
  DG: PDizinGirdisiELR;
  Gun, Ay, Yil, HG: TSayi2;
  Saat, Dakika, Saniye, ZincirBasinaSektor: TSayi1;
begin

  // en son i�lem hatal� ise ��k
  if(FileResult > 0) then Exit;

  // i�lem yap�lan dosyayla ilgili bellek b�lgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  {if(DosyaIslevNo = 2) then
  begin

    DG := PDizinGirdisiELR(@DosyaIslem^.DGAktif[0]);

    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'DG^.DosyaUzunlugu: %d', [DG^.DosyaUzunlugu]);
    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'DG^.BaslangicKumeNo: %x', [DG^.BaslangicKumeNo]);
    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'DG^.GirdiTipi: %d', [DG^.GirdiTipi]);
    Exit;
  end;}

  if not(DosyaIslem^.DosyaDurumu = ddYazmaIcinAcik) then
  begin

    FileResult := 555;
    Exit;
  end;

  // �zerinde i�lem yap�lacak s�r�c�
  MD := DosyaIslem^.MantiksalDepolama;

  DG := PDizinGirdisiELR(@DosyaIslem^.DGAktif[0]);

  VeriU := AUzunluk;

  if((DG^.DosyaUzunlugu + VeriU) > 2048) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Veri uzunlu�u 2048 bayt� ge�emez!', []);
    Exit;
  end;

  if(DG^.BaslangicKumeNo = ELR_ZD_SON) then
    YazilacakKumeNo := SHTBosKumeTahsisEt(MD)
  else YazilacakKumeNo := DG^.BaslangicKumeNo;

  ToplamVeriU := VeriU;

  ZincirBasinaSektor := MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

  GetMem(Isaretci(OYBellek), 512);

  SektorNo := 0;
  OkunacakSN := 0;

  if(DG^.DosyaUzunlugu < 512) then
  begin

    SektorNo := 0;
    YazilacakSN := DG^.DosyaUzunlugu mod 512;
  end
  else
  begin

    SektorNo := DG^.DosyaUzunlugu div 512;
    YazilacakSN := DG^.DosyaUzunlugu mod 512;
  end;

  for i := SektorNo to ZincirBasinaSektor - 1 do
  begin

    // veriyi mevcut veriye ekle ve ayg�t sekt�r�ne yaz
    if(YazilacakSN = 0) then
      FillChar(OYBellek[0], 512, $00)
    else MD^.FD^.SektorOku(MD^.FD, (YazilacakKumeNo * ZincirBasinaSektor) + i, 1, @OYBellek[0]);

    j := 512 - YazilacakSN;
    if(j > ToplamVeriU) then j := ToplamVeriU;
    Tasi2(ABellek + OkunacakSN, @OYBellek[YazilacakSN], j);
    MD^.FD^.SektorYaz(MD^.FD, (YazilacakKumeNo * ZincirBasinaSektor) + i, 1, @OYBellek[0]);

    OkunacakSN += j;
    YazilacakSN := 0;
    ToplamVeriU -= j;
    if(ToplamVeriU = 0) then Break;
  end;

  SHTKumeyiBirOncekiKumeyeBagla(MD, YazilacakKumeNo, 1);

  FreeMem(Isaretci(OYBellek), 512);

  // aktif tarih / saat bilgilerini al
  TarihAl(Gun, Ay, Yil, HG);
  SaatAl(Saat, Dakika, Saniye);

  DG := @DosyaIslem^.DGTekSektorIcerik[DosyaIslem^.SN * ELR_DG_U];
  DG^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
  DG^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);
  DG^.BaslangicKumeNo := YazilacakKumeNo;
  DG^.DosyaUzunlugu := DG^.DosyaUzunlugu + VeriU;

  // dosyan�n g�ncel de�erlerini ilgili sekt�re yaz
  MD^.FD^.SektorYaz(MD^.FD, DosyaIslem^.SektorNo, 1, @DosyaIslem^.DGTekSektorIcerik[0]);
end;

{==============================================================================
  dosyaya veri yazma i�lemini ger�ekle�tirir
 ==============================================================================}
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
var
  VeriU: TSayi4;
begin

  VeriU := Length(AVeri);
  Write0(ADosyaKimlik, @AVeri[1], VeriU);
end;

{==============================================================================
  verinin sonuna #13#10 ekleyerek dosyaya veri yazma i�lemini ger�ekle�tirir
 ==============================================================================}
procedure WriteLn(ADosyaKimlik: TKimlik; AVeri: string);
begin

  Write(ADosyaKimlik, AVeri + #13#10);
end;

{==============================================================================
  dosyaya veri yazma i�lemini ger�ekle�tirir
 ==============================================================================}
procedure Write(ADosyaKimlik: TKimlik; ABellekAdresi: Isaretci; AUzunluk: TSayi4);
begin

  Write0(ADosyaKimlik, ABellekAdresi, AUzunluk);
end;

{==============================================================================
  dosya okuma i�lemini ger�ekle�tirir
 ==============================================================================}
procedure Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci);
var
  MD: PMantiksalDepolama;
  DosyaIslem: PDosyaIslem;
  OkunacakSektorSayisi, i: TSayi4;
  ZincirBasinaSektor, VeriU,
  Zincir: TSayi4;
  KopyalanacakVeriUzunlugu: TISayi4;
  OkumaSonuc: Boolean;
  ToplamVeriU, HedefBellekSN: TSayi4;              // toplam okunacak veri uzunlu�u
  Bellek: Isaretci;
begin

  // i�lem yap�lan dosyayla ilgili bellek b�lgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  // �zerinde i�lem yap�lacak s�r�c�
  MD := DosyaIslem^.MantiksalDepolama;

  VeriU := DosyaIslem^.Uzunluk;
  if(VeriU = 0) then Exit;

  ToplamVeriU := VeriU;

  //SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, '�lk Zincir: %x', [DosyaKayit^.IlkZincirSektor]);
  //SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Dosya Uzunluk: %d', [OkunacakVeri]);

  Zincir := DosyaIslem^.IlkZincirSektor;

  ZincirBasinaSektor := MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

  OkumaSonuc := False;

  GetMem(Bellek, 2048);

  HedefBellekSN := 0;

  repeat

    // okunacak byte'� sekt�r say�s�na �evir
    if(VeriU >= (ZincirBasinaSektor * 512)) then
    begin

      OkunacakSektorSayisi := ZincirBasinaSektor;
      KopyalanacakVeriUzunlugu := ZincirBasinaSektor * 512;
      VeriU -= (ZincirBasinaSektor * 512);
    end
    else
    begin

      OkunacakSektorSayisi := ((VeriU - 1) div 512) + 1;
      KopyalanacakVeriUzunlugu := VeriU;
      VeriU := 0;
    end;

    // okunacak cluster numaras�
    i := Zincir; //(Zincir - 2) * ZincirBasinaSektor;
    //i += MD^.Acilis.IlkVeriSektorNo;

    SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Zincir: %d', [i]);

    // sekt�r� belle�e oku
    MD^.FD^.SektorOku(MD^.FD, i * ZincirBasinaSektor, OkunacakSektorSayisi, Bellek);

    // okunacak bilginin yerle�tirilece�i bir sonraki adresi belirle
    {AHedefBellek += KopyalanacakVeriUzunlugu;

    OkunacakFAT := (Zincir * 4) div 512;

    // depolama ayg�t�n�n ilk FAT kopyas�n�n t�m�n� belle�e y�kle
    MD^.FD^.SektorOku(MD^.FD, MD^.Acilis.DosyaAyirmaTablosu.IlkSektor + OkunacakFAT,
      1, @OYBellek);

    // zincir de�erini 4 ile �arp ve bir sonraki zincir de�erini al
    YeniDATSiraNo := (Zincir * 4) mod 512;
    DATSiraNo := PSayi4(Isaretci(@OYBellek) + YeniDATSiraNo)^;

    Zincir := DATSiraNo;}

    Tasi2(Bellek, AHedefBellek + HedefBellekSN, KopyalanacakVeriUzunlugu);
    HedefBellekSN += KopyalanacakVeriUzunlugu;

    OkumaSonuc := True;

    if(VeriU > 0) then Zincir := SHTBirSonrakiKumeyiAl(MD, Zincir);

  // e�er 0xfff8..0xffff aral���ndaysa bu dosyan�n en son cluster'idir
  until (Zincir = ELR_ZD_SON) or (VeriU = 0);

  FreeMem(Bellek, 2048);
end;

{==============================================================================
  dosya ile yap�lm�� en son i�lem sonucunu d�nd�r�r
 ==============================================================================}
function IOResult: TISayi4;
begin

  Result := FileResult;

  // son i�lem durumu geri d�nd�r�ld�kten sonra de�i�keni hata yok olarak i�aretle
  FileResult := 0;
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
procedure CloseFile(ADosyaKimlik: TKimlik);
begin
end;

{==============================================================================
  klas�r olu�turma i�levini ger�ekle�tirir
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
  MD := GDosyaIslemleri[ADosyaArama.Kimlik].MantiksalDepolama;

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

function HamDosyaAdiniDosyaAdinaCevir3(ADizinGirdisi: PDizinGirdisiELR): string;
var
  i: TSayi4;
begin

  // hedef bellek b�lgesini s�f�rla
  // hedef bellek alan� �u an 8+1+3+1 (dosya+.+uz+null) olmal�d�r
  Result := '';

  // dosya ad�n� �evir
  i := 1;
  while (i <= ELR_DOSYA_U) and (ADizinGirdisi^.DosyaAdi[i] <> #0) do
  begin

    Result := Result + ADizinGirdisi^.DosyaAdi[i];
    Inc(i);
  end;
end;

{==============================================================================
  diski elr-1 dosya sistemi i�in haz�rlar
 ==============================================================================}
procedure ELR1DiskBicimle(AMD: PMantiksalDepolama);
begin

  ELR1VerileriSil(AMD);

  // dosya i�erik tablosunu olu�tur
  ELR1SHTOlustur(AMD, 256, 1280, 1536);
end;

{==============================================================================
  dosya sisteminin veri alan�ndaki mevcut verileri siler
 ==============================================================================}
procedure ELR1VerileriSil(AMD: PMantiksalDepolama);
var
  FD: PFizikselDepolama;
  Bellek: Isaretci;
begin

  GetMem(Bellek, 512);

  // dosya tablosunu olu�tur
  FillChar(Bellek^, 512, 0);

  FD := AMD^.FD;

  // ge�ici olarak 4 veri sekt�r i�eri�i s�f�rlan�yor - geli�tirilecek
  FD^.SektorYaz(FD, 1536 + 0, 1, Bellek);    // $600 = 1536
  FD^.SektorYaz(FD, 1536 + 1, 1, Bellek);
  FD^.SektorYaz(FD, 1536 + 2, 1, Bellek);
  FD^.SektorYaz(FD, 1536 + 3, 1, Bellek);

  FreeMem(Bellek, 512);
end;

{==============================================================================
  dosya sistemi sekt�r harita tablosunu olu�turur
 ==============================================================================}
procedure ELR1SHTOlustur(AMD: PMantiksalDepolama; AIlkSektor, AToplamSektor,
 AAyrilanSektor: TSayi4);
var
  Bellek: Isaretci;
  FD: PFizikselDepolama;
  i, j: TSayi4;
begin

  { TODO - burada kat� kodlama uygulanm��t�r, kodlar kontrol edilecektir }

  GetMem(Bellek, 512);

  // sht i�in ayr�lan sekt�rleri s�f�rla
  FillChar(Bellek^, 512, 0);
  FD := AMD^.FD;

  for i := AIlkSektor to (AIlkSektor + AToplamSektor) - 1 do
  begin

    FD^.SektorYaz(FD, i, 1, Bellek);
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

  FillChar(Bellek^, 512, $FF);

  for i := AIlkSektor to (AIlkSektor + j) - 1 do
  begin

    FD^.SektorYaz(FD, i, 1, Bellek);
  end;

  // ilk dizin giri�ini ay�r
  FillChar(Bellek^, 512, 0);
  PSayi4(Bellek)^ := $FFFFFFFF;

  FD^.SektorYaz(FD, i + 1, 1, Bellek);

  FreeMem(Bellek, 512);
end;

{==============================================================================
  sekt�r harita tablosundan bo� k�me numaras� al�r
 ==============================================================================}
function SHTBosKumeTahsisEt(AMD: PMantiksalDepolama): TSayi4;
var
  Bellek: Isaretci;
  FD: PFizikselDepolama;
  KumeNo, i, j: TSayi4;
  Deger: PSayi4;
begin

  GetMem(Bellek, 512);

  // t�m sekt�rler dolu
  KumeNo := 0;

  FD := AMD^.FD;

  for i := 256 to (256 + 1280) - 1 do
  begin

    FD^.SektorOku(FD, i, 1, Bellek);

    Deger := Bellek;
    for j := 0 to 128 - 1 do
    begin

      if(Deger^ = 0) then
      begin

        Deger^ := ELR_ZD_SON;
        FD^.SektorYaz(FD, i, 1, Bellek);

        //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'SHTBosKumeTahsisEt: %d', [KumeNo]);

        FreeMem(Bellek, 512);

        Exit(KumeNo);
      end;

      Inc(KumeNo);
      Inc(Deger);
    end;
  end;

  FreeMem(Bellek, 512);

  Result := ELR_ZD_SON;    // bo� sekt�r yok
end;

{==============================================================================
  sekt�r harita tablosundan al�nan sekt�r k�mesini serbest b�rak�r
 ==============================================================================}
function SHTBosKumeSerbestBirak(AMD: PMantiksalDepolama; AKumeNo: TSayi4): Boolean;
var
  Bellek: Isaretci;
  FD: PFizikselDepolama;
  SektorNo, SiraNo: TSayi4;
  Deger: PSayi4;
begin

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'SHTBosKumeSerbestBirak: %d', [AKumeNo]);

  GetMem(Bellek, 512);

  // konumlan�lacak sekt�r numaras�
  SektorNo := AKumeNo div 128;
  SiraNo := AKumeNo mod 128;

  FD := AMD^.FD;

  FD^.SektorOku(FD, 256 + SektorNo, 1, Bellek);

  Deger := Bellek;
  Inc(Deger, SiraNo);
  if(Deger^ = ELR_ZD_SON) then
  begin

    Deger^ := $0;
    FD^.SektorYaz(FD, 256 + SektorNo, 1, Bellek);
    FreeMem(Bellek, 512);
    Exit(True);
  end;

  FreeMem(Bellek, 512);
  Result := False;
end;

{==============================================================================
  k�meyi bir �nceki k�meye ba�lar
 ==============================================================================}
function SHTKumeyiBirOncekiKumeyeBagla(AMD: PMantiksalDepolama; ABirOncekiKumeNo,
 AKumeNo: TSayi4): Boolean;
var
  Bellek: Isaretci;
  FD: PFizikselDepolama;
  SektorNo, SiraNo: TSayi4;
  Deger: PSayi4;
begin

  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'SHTKumeyiBirOncekiKumeyeBagla:', []);
  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ABirOncekiKumeNo: %d', [ABirOncekiKumeNo]);
  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'AKumeNo: %d', [AKumeNo]);

  GetMem(Bellek, 512);

  // konumlan�lacak sekt�r numaras�
  SektorNo := ABirOncekiKumeNo div 128;
  SiraNo := ABirOncekiKumeNo mod 128;

  FD := AMD^.FD;

  FD^.SektorOku(FD, 256 + SektorNo, 1, Bellek);

  Deger := Bellek;
  Inc(Deger, SiraNo);
  Deger^ := AKumeNo;

  FD^.SektorYaz(FD, 256 + SektorNo, 1, Bellek);

  FreeMem(Bellek, 512);

  Result := True;
end;

{==============================================================================
  k�meye ba�l� bir sonraki k�meyi al�r
 ==============================================================================}
function SHTBirSonrakiKumeyiAl(AMD: PMantiksalDepolama; AKumeNo: TSayi4): TSayi4;
var
  Bellek: Isaretci;
  FD: PFizikselDepolama;
  SektorNo, SiraNo: TSayi4;
  Deger: PSayi4;
begin

{  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'SHTKumeyiBirOncekiKumeyeBagla:', []);
  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ABirOncekiKumeNo: %d', [ABirOncekiKumeNo]);
  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'AKumeNo: %d', [AKumeNo]);}

  GetMem(Bellek, 512);

  // konumlan�lacak sekt�r numaras�
  SektorNo := AKumeNo div 128;
  SiraNo := AKumeNo mod 128;

  FD := AMD^.FD;

  FD^.SektorOku(FD, 256 + SektorNo, 1, Bellek);

  Deger := Bellek;
  Inc(Deger, SiraNo);
  Result := Deger^;

  FreeMem(Bellek, 512);
end;

end.
