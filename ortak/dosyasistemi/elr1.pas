{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: elr1.pas
  Dosya ��levi: ELERA ��letim Sistemi'nin dosya sistemi

  G�ncelleme Tarihi: 26/05/2025

  Kaynaklar: https://wiki.freepascal.org/File_Handling_In_Pascal

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit elr1;

interface

uses paylasim, islevler, gorev;

const
  DIZIN_GIRDI_SAYISI = 8;

function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
  var ADosyaArama: TDosyaArama): TISayi4;
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
procedure ReWrite(ADosyaKimlik: TKimlik);
procedure Append(ADosyaKimlik: TKimlik);
procedure Reset(ADosyaKimlik: TKimlik);
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
procedure Write0(ADosyaKimlik: TKimlik; ABellek: Isaretci; AUzunluk: TSayi4);
procedure WriteLn(ADosyaKimlik: TKimlik; AVeri: string);
procedure Write(ADosyaKimlik: TKimlik; ABellekAdresi: Isaretci; AUzunluk: TSayi4);
procedure Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci);
function IOResult: TISayi4;
function FileSize(ADosyaKimlik: TKimlik): TISayi8;
function EOF(ADosyaKimlik: TKimlik): Boolean;
procedure CloseFile(ADosyaKimlik: TKimlik);
function CreateDir(ADosyaKimlik: TKimlik): Boolean;
function RemoveDir(const ADosyaKimlik: TKimlik): Boolean;
function DeleteFile(const ADosyaKimlik: TKimlik): Boolean;

function DizinGirdisiOku(ADizinGirisi: PDizinGirisi; AAranacakDeger: string;
  var ADosyaArama: TDosyaArama): TSayi1;

procedure ELR1DiskBicimle(AMD: PMantiksalDepolama);
procedure ELR1VerileriSil(AMD: PMantiksalDepolama);
procedure ELR1SHTOlustur(AMD: PMantiksalDepolama; AIlkSektor, AToplamSektor,
 AAyrilanSektor: TSayi4);
function SHTBosKumeTahsisEt(AMD: PMantiksalDepolama): TISayi4;
function SHTBosKumeSerbestBirak(AMD: PMantiksalDepolama; AKumeNo: TSayi4): Boolean;
function SHTKumeyiBirOncekiKumeyeBagla(AMD: PMantiksalDepolama; ABirOncekiKumeNo,
 AKumeNo: TSayi4): Boolean;
function SHTBirSonrakiKumeyiAl(AMD: PMantiksalDepolama; AKumeNo: TSayi4): TSayi4;
function SHTToplamKullanim(AMD: PMantiksalDepolama): TSayi4;
function ELRDosyaAdiniAl(ADizinGirdisi: PDizinGirdisiELR): string;

implementation

uses genel, donusum, gercekbellek, cmos, sistemmesaj;

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

  // i�lev dosya.pas taraf�ndan y�netilmektedir
end;

{==============================================================================
  dosya olu�turma i�levini ger�ekle�tirir
 ==============================================================================}
procedure ReWrite(ADosyaKimlik: TKimlik);
var
  AktifGorev: PGorev;
  MD: PMantiksalDepolama;
  AktifDG: PDizinGirdisiELR;
  DosyaIslem: PDosyaIslem;
  DosyaAdi: string;
  ZincirNo, ZincirBasinaSektor,
  KumeNo, i: TSayi4;
  YeniKumeNo: TISayi4;
  TumGirislerOkundu,
  DosyaBulundu: Boolean;
  Gun, Ay, Yil, HG: TSayi2;
  Saat, Dakika, Saniye: TSayi1;
begin

  AktifGorev := GorevListesi[FAktifGorev];

  // en son i�lem hatal� ise ��k
  if(AktifGorev^.FDosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  // dosya i�lem yap�s� bellek b�lgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  // dosya a��k m�? (kapal� olmal�)
  if(DosyaIslem^.DosyaDurumu <> ddKapali) then
  begin

    AktifGorev^.FDosyaSonIslemDurum := HATA_DOSYA_KULLANIMDA;
    Exit;
  end;

  // ilk de�er atamalar�
  DosyaBulundu := False;

  TumGirislerOkundu := False;

  DosyaIslem^.SektorNo := -1;
  DosyaIslem^.KayitSN := -1;
  ZincirNo := 0;

  MD := DosyaIslem^.MantiksalDepolama;

  ZincirBasinaSektor := MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;
  KumeNo := MD^.Acilis.DizinGirisi.IlkSektor div ZincirBasinaSektor;

  repeat

    if(DosyaIslem^.KayitSN = -1) then
    begin

      DosyaIslem^.SektorNo := (KumeNo * ZincirBasinaSektor) + ZincirNo;

      // dizin giri� sekt�r�n� oku
      MD^.FD^.SektorOku(MD^.FD, DosyaIslem^.SektorNo, 1, DosyaIslem^.TekSektorIcerik);

      DosyaIslem^.KayitSN := 0;
    end;

    // dizin giri� tablosuna konumlan
    AktifDG := PDizinGirdisiELR(DosyaIslem^.TekSektorIcerik);
    Inc(AktifDG, DosyaIslem^.KayitSN);

    // dosya giri�inin ilk karakteri #0 ise giri�ler okunmu� demektir
    if(AktifDG^.DosyaAdi[0] = #00) then
    begin

      TumGirislerOkundu := True;
    end
    // silinmi� dosya / klas�r
    else if(AktifDG^.Ozellikler = ELR_O_SILINMIS) then
    begin

      // bir sonraki giri�le devam et
    end
    else
    begin

      DosyaAdi := ELRDosyaAdiniAl(AktifDG);

      if(AktifDG^.GirdiTipi = ELR_GT_DOSYA) and (DosyaAdi = DosyaIslem^.DosyaAdi) then
      begin

        // di�er i�levlerin de girdi �zerinde i�lem yapabilmesi i�in
        // dosya bilgilerini aktif dizin giri�ine ta��
        Tasi2(AktifDG, @DosyaIslem^.AktifDG, ELR_DG_U);

        DosyaBulundu := True;
        TumGirislerOkundu := True;
      end;
    end;

    if not(TumGirislerOkundu) then
    begin

      // bir sonraki girdiye konumlan
      Inc(DosyaIslem^.KayitSN);
      if(DosyaIslem^.KayitSN = DIZIN_GIRDI_SAYISI) then
      begin

        // yeni sekt�r�n okunmas� i�in KayitSN de�i�kenini -1 olarak ayarla
        DosyaIslem^.KayitSN := -1;

        Inc(ZincirNo);
        if(ZincirNo = ZincirBasinaSektor) then
        begin

          i := SHTBirSonrakiKumeyiAl(MD, KumeNo);
          if(i = ELR_ZD_SON) then
          begin

            YeniKumeNo := SHTBosKumeTahsisEt(MD);
            if(YeniKumeNo < HATA_YOK) then
            begin

              AktifGorev^.FDosyaSonIslemDurum := YeniKumeNo;
              Exit;
            end;

            SHTKumeyiBirOncekiKumeyeBagla(MD, KumeNo, YeniKumeNo);
            KumeNo := YeniKumeNo;

          end else KumeNo := i;

          ZincirNo := 0;
        end;
      end else Inc(AktifDG);
    end;

  until TumGirislerOkundu;

  // dosya olu�turma i�lemi

  // 1. dosyan�n mevcut olmas� durumunda
  if(DosyaBulundu) then
  begin

    // aktif dizin giri�ine konumlan
    AktifDG := @DosyaIslem^.AktifDG;

    { TODO - bu a�amada dosya i�in ayr�lan t�m k�meler serbest b�rak�lacak }
    if(AktifDG^.BaslangicKumeNo <> ELR_ZD_SON) then SHTBosKumeSerbestBirak(MD, AktifDG^.BaslangicKumeNo);

    // aktif tarih / saat bilgilerini al
    TarihAl(Gun, Ay, Yil, HG);
    SaatAl(Saat, Dakika, Saniye);

    // g�ncel veriler �ncelikle aktif dizin giri�ine aktar�lacak
    AktifDG^.GirdiTipi := ELR_GT_DOSYA;
    AktifDG^.Ozellikler := ELR_O_NORMAL;
    AktifDG^.OlusturmaTarihi := ELRTarih(Gun, Ay, Yil);
    AktifDG^.OlusturmaSaati := ELRSaat(Saat, Dakika, Saniye);
    AktifDG^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
    AktifDG^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);
    AktifDG^.BaslangicKumeNo := ELR_ZD_SON;
    AktifDG^.DosyaUzunlugu := 0;

    // aktif dizin giri�inin sekt�rdeki i�eri�ini g�ncelle
    Tasi2(AktifDG, DosyaIslem^.TekSektorIcerik + (DosyaIslem^.KayitSN * ELR_DG_U), ELR_DG_U);

    // aktif dizin giri�inin bulundu�u sekt�r� g�ncelle (�zerine yaz)
    MD^.FD^.SektorYaz(MD^.FD, DosyaIslem^.SektorNo, 1, DosyaIslem^.TekSektorIcerik);

    // dosya durumunu, "dosya yaz�m i�in a��ld�" olarak g�ncelle
    DosyaIslem^.DosyaDurumu := ddYazmaIcinAcik;
  end
  else
  // 2. dosyan�n mevcut OLMAMASI durumunda
  begin

    if(DosyaIslem^.KayitSN >= 0) and (DosyaIslem^.KayitSN < DIZIN_GIRDI_SAYISI) then
    begin

      // aktif dizin giri�ine konumlan
      AktifDG := @DosyaIslem^.AktifDG;

      // aktif tarih / saat bilgilerini al
      TarihAl(Gun, Ay, Yil, HG);
      SaatAl(Saat, Dakika, Saniye);

      // 2.2. g�ncel veriler �ncelikle aktif dizin giri�ine aktar�lacak
      AktifDG^.GirdiTipi := ELR_GT_DOSYA;
      AktifDG^.Ozellikler := ELR_O_NORMAL;
      AktifDG^.OlusturmaTarihi := ELRTarih(Gun, Ay, Yil);
      AktifDG^.OlusturmaSaati := ELRSaat(Saat, Dakika, Saniye);
      AktifDG^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
      AktifDG^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);
      AktifDG^.BaslangicKumeNo := ELR_ZD_SON;
      AktifDG^.DosyaUzunlugu := 0;

      // aktif dizin giri�inin sekt�rdeki i�eri�ini g�ncelle
      Tasi2(AktifDG, DosyaIslem^.TekSektorIcerik + (DosyaIslem^.KayitSN * ELR_DG_U), ELR_DG_U);

      // aktif dizin giri�inin bulundu�u sekt�r� g�ncelle (�zerine yaz)
      MD^.FD^.SektorYaz(MD^.FD, DosyaIslem^.SektorNo, 1, DosyaIslem^.TekSektorIcerik);

      // dosya durumunu, "dosya yaz�m i�in a��ld�" olarak g�ncelle
      DosyaIslem^.DosyaDurumu := ddYazmaIcinAcik;
    end;
  end;
end;

{==============================================================================
  dosyaya veri eklemek i�in dosya a�ma i�levlerini ger�ekle�tirir
 ==============================================================================}
procedure Append(ADosyaKimlik: TKimlik);
var
  AktifGorev: PGorev;
  MD: PMantiksalDepolama;
  AktifDG: PDizinGirdisiELR;
  DosyaIslem: PDosyaIslem;
  ZincirNo, ZincirBasinaSektor,
  KumeNo, i: TSayi4;
  TumGirislerOkundu,
  DosyaBulundu: Boolean;
  DosyaAdi: string;
begin

  AktifGorev := GorevListesi[FAktifGorev];

  // en son i�lem hatal� ise ��k
  if(AktifGorev^.FDosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  // dosya i�lem yap�s� bellek b�lgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  // dosya daha �nce kapal� olmal�
  if(DosyaIslem^.DosyaDurumu <> ddKapali) then
  begin

    AktifGorev^.FDosyaSonIslemDurum := HATA_DOSYA_KULLANIMDA;
    Exit;
  end;

  // ilk de�er atamalar�
  DosyaBulundu := False;

  TumGirislerOkundu := False;

  DosyaIslem^.SektorNo := -1;
  DosyaIslem^.KayitSN := -1;
  ZincirNo := 0;

  MD := DosyaIslem^.MantiksalDepolama;

  ZincirBasinaSektor := MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;
  KumeNo := MD^.Acilis.DizinGirisi.IlkSektor div ZincirBasinaSektor;

  repeat

    if(DosyaIslem^.KayitSN = -1) then
    begin

      DosyaIslem^.SektorNo := (KumeNo * ZincirBasinaSektor) + ZincirNo;

      // dizin giri� sekt�r�n� oku
      MD^.FD^.SektorOku(MD^.FD, DosyaIslem^.SektorNo, 1, DosyaIslem^.TekSektorIcerik);

      DosyaIslem^.KayitSN := 0;
    end;

    // dosya giri� tablosuna konumlan
    AktifDG := PDizinGirdisiELR(DosyaIslem^.TekSektorIcerik);
    Inc(AktifDG, DosyaIslem^.KayitSN);

    // dosya giri�inin ilk karakteri #0 ise giri�ler okunmu� demektir
    if(AktifDG^.DosyaAdi[0] = #00) then
    begin

      TumGirislerOkundu := True;
    end
    // silinmi� dosya / klas�r
    else if(AktifDG^.Ozellikler = ELR_O_SILINMIS) then
    begin

      // bir sonraki giri�le devam et
    end
    else
    begin

      DosyaAdi := ELRDosyaAdiniAl(AktifDG);

      if(AktifDG^.GirdiTipi = ELR_GT_DOSYA) and (DosyaAdi = DosyaIslem^.DosyaAdi) then
      begin

        // di�er i�levlerin de girdi �zerinde i�lem yapabilmesi i�in
        // dosya bilgilerini aktif dizin giri�ine ta��
        Tasi2(AktifDG, @DosyaIslem^.AktifDG, ELR_DG_U);

        DosyaBulundu := True;
        TumGirislerOkundu := True;
      end;
    end;

    if not(TumGirislerOkundu) then
    begin

      // bir sonraki girdiye konumlan
      Inc(DosyaIslem^.KayitSN);
      if(DosyaIslem^.KayitSN = DIZIN_GIRDI_SAYISI) then
      begin

        // yeni sekt�r�n okunmas� i�in KayitSN de�i�kenini -1 olarak ayarla
        DosyaIslem^.KayitSN := -1;

        Inc(ZincirNo);
        if(ZincirNo = ZincirBasinaSektor) then
        begin

          i := SHTBirSonrakiKumeyiAl(MD, KumeNo);
          if(i = ELR_ZD_SON) then
          begin

            AktifGorev^.FDosyaSonIslemDurum := HATA_DOSYA_MEVCUTDEGIL;
            Exit;
          end else KumeNo := i;

          ZincirNo := 0;
        end;
      end else Inc(AktifDG);
    end;

  until TumGirislerOkundu;

  // dosyan�n bulunmas� halinde dosyan�n durumunu yazma i�in a��k olarak belirt
  if(DosyaBulundu) then
  begin

    DosyaIslem^.DosyaDurumu := ddYazmaIcinAcik;
  end
  else
  // aksi halde ilgili hata kodunu de�i�kene ata
  begin

    AktifGorev^.FDosyaSonIslemDurum := HATA_DOSYA_MEVCUTDEGIL;
  end;
end;

{==============================================================================
  dosyay� okumadan �nce �n haz�rl�k i�levlerini ger�ekle�tirir
 ==============================================================================}
procedure Reset(ADosyaKimlik: TKimlik);
var
  AktifGorev: PGorev;
  DosyaIslem: PDosyaIslem;
  DosyaArama: TDosyaArama;
  TamAramaYolu: string;
  Bulundu: Boolean;
begin

  AktifGorev := GorevListesi[FAktifGorev];

  // en son i�lem hatal� ise ��k
  if(AktifGorev^.FDosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  // dosya i�lem yap�s� bellek b�lgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  // tam dosya ad�n� al
  TamAramaYolu := DosyaIslem^.MantiksalDepolama^.MD3.AygitAdi + ':' + DosyaIslem^.Klasor + '*.*';

  // dosyay� dosya tablosunda bul
  Bulundu := False;
  if(FindFirst(TamAramaYolu, 0, DosyaArama) = 0) then
  begin

    repeat

      if(DosyaArama.DosyaAdi = DosyaIslem^.DosyaAdi) then Bulundu := True;
    until (Bulundu) or (FindNext(DosyaArama) <> 0);

    FindClose(DosyaArama);
  end;

  // dosyan�n tabloda bulunmas� halinde
  // dosyan�n ilk dizi ve uzunlu�unu al
  if(Bulundu) then
  begin

    DosyaIslem^.IlkZincirSektor := DosyaArama.BaslangicKumeNo;
    DosyaIslem^.Uzunluk := DosyaArama.DosyaUzunlugu;

    {SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'IlkZincirSektor: %d', [DosyaIslem^.IlkZincirSektor]);
    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'DosyaUzunlugu: %d', [DosyaIslem^.Uzunluk]);}

    // dosya durumunu, "dosya okuma i�in a��ld�" olarak g�ncelle
    DosyaIslem^.DosyaDurumu := ddOkumaIcinAcik;

  end else AktifGorev^.FDosyaSonIslemDurum := HATA_DOSYA_MEVCUTDEGIL;
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
  dosyaya veri yazma i�lemini ger�ekle�tirir
 ==============================================================================}
procedure Write0(ADosyaKimlik: TKimlik; ABellek: Isaretci; AUzunluk: TSayi4);
var
  AktifGorev: PGorev;
  MD: PMantiksalDepolama;
  DosyaIslem: PDosyaIslem;
  SHTyeYazilacakKumeNo, YeniKumeNo: TISayi4;
  OncedenYazilanKumeSayisi,
  YazilacakKumeNo: TSayi4;
  SektorNo, i,
  OkumaKonum,
  ToplamYazilacakVeriU,            // toplam yaz�lacak veri uzunlu�u
  j, SektorVeriU: TSayi4;
  AktifDG: PDizinGirdisiELR;
  Gun, Ay, Yil, HG: TSayi2;
  Saat, Dakika, Saniye, ZincirBasinaSektor: TSayi1;
  Bellek: Isaretci;
begin

  AktifGorev := GorevListesi[FAktifGorev];

  // en son i�lem hatal� ise ��k
  if(AktifGorev^.FDosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  // i�lem yap�lan dosyayla ilgili bellek b�lgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  // dosya yazma i�in a��k m�?
  if not(DosyaIslem^.DosyaDurumu = ddYazmaIcinAcik) then
  begin

    AktifGorev^.FDosyaSonIslemDurum := HATA_DOSYA_YAZILAMIYOR;
    Exit;
  end;

  // ilk de�er atamalar�
  MD := DosyaIslem^.MantiksalDepolama;

  ZincirBasinaSektor := MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

  AktifDG := PDizinGirdisiELR(@DosyaIslem^.AktifDG);

  SHTyeYazilacakKumeNo := 0;

  // dosyan�n ba�lang�� k�eme numaras�n� al, olmamas� durumunda yeni bir tane olu�tur
  if(AktifDG^.BaslangicKumeNo = ELR_ZD_SON) then
  begin

    SHTyeYazilacakKumeNo := SHTBosKumeTahsisEt(MD);
    if(SHTyeYazilacakKumeNo < HATA_YOK) then
    begin

      SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'SHTBosKumeTahsisEt.HataKodu: %d', [SHTyeYazilacakKumeNo]);
      AktifGorev^.FDosyaSonIslemDurum := SHTyeYazilacakKumeNo;
      Exit;
    end;

    YazilacakKumeNo := SHTyeYazilacakKumeNo;
  end else YazilacakKumeNo := AktifDG^.BaslangicKumeNo;

  ToplamYazilacakVeriU := AUzunluk;

  GetMem(Bellek, 512 * ZincirBasinaSektor);

  OkumaKonum := 0;

  OncedenYazilanKumeSayisi := (AktifDG^.DosyaUzunlugu div (512 * ZincirBasinaSektor));

  // dosyaya ekleme yap�lacaksa (�nceden veri yaz�lm��sa) en son k�meye konumlan
  if(OncedenYazilanKumeSayisi > 0) then
  begin

    for i := 1 to OncedenYazilanKumeSayisi do
    begin

      YazilacakKumeNo := SHTBirSonrakiKumeyiAl(MD, YazilacakKumeNo);
    end;
  end;

  repeat

    SektorNo := (AktifDG^.DosyaUzunlugu div 512) mod 4;
    SektorVeriU := (AktifDG^.DosyaUzunlugu mod 512);

    // sekt�r�n bir k�sm�na yaz�m yap�lm��sa (ekleme yap�lacaksa), veriyi mevcut
    // veriye ekle ve ayg�t sekt�r�ne yaz
    if(SektorVeriU > 0) then
    begin

      FillChar(Bellek^, 512 * ZincirBasinaSektor, $00);
      MD^.FD^.SektorOku(MD^.FD, (YazilacakKumeNo * ZincirBasinaSektor) + SektorNo, 1, Bellek);

      j := 512 - SektorVeriU;
      if(j > ToplamYazilacakVeriU) then j := ToplamYazilacakVeriU;
      Tasi2(ABellek + OkumaKonum, Bellek + SektorVeriU, j);
      MD^.FD^.SektorYaz(MD^.FD, (YazilacakKumeNo * ZincirBasinaSektor) + SektorNo, 1, Bellek);

      OkumaKonum += j;
      ToplamYazilacakVeriU -= j;
      AktifDG^.DosyaUzunlugu := AktifDG^.DosyaUzunlugu + j;

      if((SektorVeriU + j) = 512) then
      begin

        Inc(SektorNo);
        SektorNo := SektorNo mod 4;
        if(SektorNo = 0) then
        begin

          YeniKumeNo := SHTBosKumeTahsisEt(MD);
          if(YeniKumeNo < HATA_YOK) then
          begin

            SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'SHTBosKumeTahsisEt.HataKodu1: %d', [YeniKumeNo]);
            FreeMem(Bellek, 512 * ZincirBasinaSektor);
            AktifGorev^.FDosyaSonIslemDurum := YeniKumeNo;
            Exit;
          end;

          SHTKumeyiBirOncekiKumeyeBagla(MD, YazilacakKumeNo, YeniKumeNo);
          YazilacakKumeNo := YeniKumeNo;
        end;
      end;
    end;

    // bu a�amada sekt�r�n yar�m dolu olmas� mevzu bahis de�ildir
    // sekt�rler ba�� itibariyle (sonu de�il) 0'a odakl� olarak yaz�lacakt�r
    if(ToplamYazilacakVeriU > 0) then
    begin

      FillChar(Bellek^, 512 * ZincirBasinaSektor, $00);
      // ka� sekt�r yaz�lacak
      i := 4 - SektorNo;
      // hedef b�lgeye ka� byte kopyalanacak
      j := (4 - SektorNo) * 512;
      if(j > ToplamYazilacakVeriU) then j := ToplamYazilacakVeriU;
      Tasi2(ABellek + OkumaKonum, Bellek, j);
      MD^.FD^.SektorYaz(MD^.FD, (YazilacakKumeNo * ZincirBasinaSektor) + SektorNo, i, Bellek);

      OkumaKonum += j;
      ToplamYazilacakVeriU -= j;
      AktifDG^.DosyaUzunlugu := AktifDG^.DosyaUzunlugu + j;

      if(ToplamYazilacakVeriU > 0) then
      begin

        YeniKumeNo := SHTBosKumeTahsisEt(MD);
        if(YeniKumeNo < HATA_YOK) then
        begin

          SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'SHTBosKumeTahsisEt.HataKodu2: %d', [YeniKumeNo]);
          FreeMem(Bellek, 512 * ZincirBasinaSektor);
          AktifGorev^.FDosyaSonIslemDurum := YeniKumeNo;
          Exit;
        end;

        SHTKumeyiBirOncekiKumeyeBagla(MD, YazilacakKumeNo, YeniKumeNo);
        YazilacakKumeNo := YeniKumeNo;
      end;
    end;

  until ToplamYazilacakVeriU = 0;

  FreeMem(Bellek, 512 * ZincirBasinaSektor);

  if(SHTyeYazilacakKumeNo > 0) then AktifDG^.BaslangicKumeNo := SHTyeYazilacakKumeNo;

  // aktif tarih / saat bilgilerini al
  TarihAl(Gun, Ay, Yil, HG);
  SaatAl(Saat, Dakika, Saniye);

  AktifDG^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
  AktifDG^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);

  // aktif dizin giri�inin sekt�rdeki i�eri�ini g�ncelle
  Tasi2(AktifDG, DosyaIslem^.TekSektorIcerik + (DosyaIslem^.KayitSN * ELR_DG_U), ELR_DG_U);

  // dosyan�n g�ncel de�erlerini ilgili sekt�re yaz
  MD^.FD^.SektorYaz(MD^.FD, DosyaIslem^.SektorNo, 1, DosyaIslem^.TekSektorIcerik);
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

    //SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Zincir: %d', [i]);

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
var
  MD: PMantiksalDepolama;
  DG: PDizinGirdisiELR;
  DosyaIslem: PDosyaIslem;
  YeniKumeNo: TISayi4;
  KumeNo, i, ZincirNo,
  ZincirBasinaSektor: TSayi4;
  KlasorAdi: string;
  TumGirislerOkundu,
  KlasorBulundu: Boolean;
  Gun, Ay, Yil, HG: TSayi2;
  Saat, Dakika, Saniye: TSayi1;
begin

  // ilk de�er atamalar�
  Result := False;

  KlasorBulundu := False;

  TumGirislerOkundu := False;

  // dosya i�lem yap�s� bellek b�lgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  MD := DosyaIslem^.MantiksalDepolama;

  ZincirBasinaSektor := MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;
  KumeNo := MD^.Acilis.DizinGirisi.IlkSektor div ZincirBasinaSektor;

  DosyaIslem^.SektorNo := -1;
  DosyaIslem^.KayitSN := -1;
  ZincirNo := 0;

  repeat

    if(DosyaIslem^.KayitSN = -1) then
    begin

      DosyaIslem^.SektorNo := (KumeNo * ZincirBasinaSektor) + ZincirNo;

      // dizin giri� sekt�r�n� oku
      MD^.FD^.SektorOku(MD^.FD, DosyaIslem^.SektorNo, 1, DosyaIslem^.TekSektorIcerik);

      DosyaIslem^.KayitSN := 0;
    end;

    // dizin giri� tablosuna konumlan
    DG := PDizinGirdisiELR(DosyaIslem^.TekSektorIcerik);
    Inc(DG, DosyaIslem^.KayitSN);

    // klas�r giri�inin ilk karakteri #0 ise t�m giri�ler okunmu� demektir
    if(DG^.DosyaAdi[0] = #00) then
    begin

      TumGirislerOkundu := True;
    end
    // silinmi� dosya / klas�r
    else if(DG^.Ozellikler = ELR_O_SILINMIS) then
    begin

      // silinen girdiye klas�r olu�tur
      TumGirislerOkundu := True;
    end
    else
    begin

      KlasorAdi := ELRDosyaAdiniAl(DG);

      if(DG^.GirdiTipi = ELR_GT_KLASOR) and (KlasorAdi = DosyaIslem^.DosyaAdi) then
        Exit(False);
    end;

    if not(TumGirislerOkundu) then
    begin

      // bir sonraki girdiye konumlan
      Inc(DosyaIslem^.KayitSN);
      if(DosyaIslem^.KayitSN = DIZIN_GIRDI_SAYISI) then
      begin

        // yeni sekt�r�n okunmas� i�in KayitSN de�i�kenini -1 olarak ayarla
        DosyaIslem^.KayitSN := -1;

        Inc(ZincirNo);
        if(ZincirNo = ZincirBasinaSektor) then
        begin

          i := SHTBirSonrakiKumeyiAl(DosyaIslem^.MantiksalDepolama, KumeNo);
          if(i = ELR_ZD_SON) then
          begin

            YeniKumeNo := SHTBosKumeTahsisEt(DosyaIslem^.MantiksalDepolama);
            if(YeniKumeNo < HATA_YOK) then Exit(False);

            SHTKumeyiBirOncekiKumeyeBagla(DosyaIslem^.MantiksalDepolama, KumeNo, YeniKumeNo);
            KumeNo := YeniKumeNo;
          end else KumeNo := i;

          ZincirNo := 0;
        end;
      end else Inc(DG);
    end;

  until TumGirislerOkundu;

  // klas�r olu�turma i�lemi
  if not(KlasorBulundu) then
  begin

    if(DosyaIslem^.KayitSN >= 0) and (DosyaIslem^.KayitSN < DIZIN_GIRDI_SAYISI) then
    begin

      // aktif tarih / saat bilgilerini al
      TarihAl(Gun, Ay, Yil, HG);
      SaatAl(Saat, Dakika, Saniye);

      // dosya ad�n� hedef b�lgeye kopyala
      Tasi2(@DosyaIslem^.AktifDG[0], DG, ELR_DG_U);

      DG^.GirdiTipi := ELR_GT_KLASOR;
      DG^.Ozellikler := ELR_O_NORMAL;
      DG^.OlusturmaTarihi := ELRTarih(Gun, Ay, Yil);
      DG^.OlusturmaSaati := ELRSaat(Saat, Dakika, Saniye);
      DG^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
      DG^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);
      DG^.BaslangicKumeNo := ELR_ZD_SON;
      DG^.DosyaUzunlugu := 0;

      // aktif dizin giri�inin bulundu�u sekt�r� g�ncelle (�zerine yaz)
      MD^.FD^.SektorYaz(MD^.FD, DosyaIslem^.SektorNo, 1, DosyaIslem^.TekSektorIcerik);

      Result := True;
    end;
  end;
end;

{==============================================================================
  klas�r silme i�levini ger�ekle�tirir
 ==============================================================================}
function RemoveDir(const ADosyaKimlik: TKimlik): Boolean;
var
  MD: PMantiksalDepolama;
  DG: PDizinGirdisiELR;
  DosyaIslem: PDosyaIslem;
  DosyaAdi: string;
  KumeNo, i, ZincirNo,
  ZincirBasinaSektor: TSayi4;
  TumGirislerOkundu,
  KlasorBulundu: Boolean;
begin

  // ilk de�er atamalar�
  Result := False;

  KlasorBulundu := False;

  TumGirislerOkundu := False;

  // dosya i�lem yap�s� bellek b�lgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  MD := DosyaIslem^.MantiksalDepolama;

  ZincirBasinaSektor := MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;
  KumeNo := MD^.Acilis.DizinGirisi.IlkSektor div ZincirBasinaSektor;

  DosyaIslem^.SektorNo := -1;
  DosyaIslem^.KayitSN := -1;
  ZincirNo := 0;

  repeat

    if(DosyaIslem^.KayitSN = -1) then
    begin

      DosyaIslem^.SektorNo := (KumeNo * ZincirBasinaSektor) + ZincirNo;

      // dizin giri� sekt�r�n� oku
      MD^.FD^.SektorOku(MD^.FD, DosyaIslem^.SektorNo, 1, DosyaIslem^.TekSektorIcerik);

      DosyaIslem^.KayitSN := 0;
    end;

    // dizin giri� tablosuna konumlan
    DG := PDizinGirdisiELR(DosyaIslem^.TekSektorIcerik);
    Inc(DG, DosyaIslem^.KayitSN);

    // klas�r giri�inin ilk karakteri #0 ise t�m giri�ler okunmu� demektir
    if(DG^.DosyaAdi[0] = #00) then
    begin

      TumGirislerOkundu := True;
    end
    else
    begin

      DosyaAdi := ELRDosyaAdiniAl(DG);

      // klas�r ad kontrol�
      if(DG^.GirdiTipi = ELR_GT_KLASOR) and (DosyaAdi = DosyaIslem^.DosyaAdi) then
      begin

        KlasorBulundu := True;
        TumGirislerOkundu := True;
      end;
    end;

    if not(TumGirislerOkundu) then
    begin

      // bir sonraki girdiye konumlan
      Inc(DosyaIslem^.KayitSN);
      if(DosyaIslem^.KayitSN = DIZIN_GIRDI_SAYISI) then
      begin

        // yeni sekt�r�n okunmas� i�in KayitSN de�i�kenini -1 olarak ayarla
        DosyaIslem^.KayitSN := -1;

        Inc(ZincirNo);
        if(ZincirNo = ZincirBasinaSektor) then
        begin

          i := SHTBirSonrakiKumeyiAl(DosyaIslem^.MantiksalDepolama, KumeNo);
          if(i = ELR_ZD_SON) then Exit(False);

          KumeNo := i;
          ZincirNo := 0;
        end;
      end else Inc(DG);
    end;

  until TumGirislerOkundu;

  // klas�r�n bulunmas� halinde...
  if(KlasorBulundu) then
  begin

    // klas�r� silindi olarak i�aretle
    DG^.Ozellikler := ELR_O_SILINMIS;

    // aktif dizin giri�inin bulundu�u sekt�r� g�ncelle (�zerine yaz)
    MD^.FD^.SektorYaz(MD^.FD, DosyaIslem^.SektorNo, 1, DosyaIslem^.TekSektorIcerik);

    Result := True;

  end else Result := False;
end;

{==============================================================================
  dosya silme i�levini ger�ekle�tirir
 ==============================================================================}
function DeleteFile(const ADosyaKimlik: TKimlik): Boolean;
var
  MD: PMantiksalDepolama;
  DG: PDizinGirdisiELR;
  DosyaIslem: PDosyaIslem;
  DosyaAdi: string;
  KumeNo, i, ZincirNo,
  ZincirBasinaSektor: TSayi4;
  TumGirislerOkundu,
  DosyaBulundu: Boolean;
begin

  // ilk de�er atamalar�
  Result := False;

  DosyaBulundu := False;

  TumGirislerOkundu := False;

  // dosya i�lem yap�s� bellek b�lgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  MD := DosyaIslem^.MantiksalDepolama;

  ZincirBasinaSektor := MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;
  KumeNo := MD^.Acilis.DizinGirisi.IlkSektor div ZincirBasinaSektor;

  DosyaIslem^.SektorNo := -1;
  DosyaIslem^.KayitSN := -1;
  ZincirNo := 0;

  repeat

    if(DosyaIslem^.KayitSN = -1) then
    begin

      DosyaIslem^.SektorNo := (KumeNo * ZincirBasinaSektor) + ZincirNo;

      // dizin giri� sekt�r�n� oku
      MD^.FD^.SektorOku(MD^.FD, DosyaIslem^.SektorNo, 1, DosyaIslem^.TekSektorIcerik);

      DosyaIslem^.KayitSN := 0;
    end;

    // dizin giri� tablosuna konumlan
    DG := PDizinGirdisiELR(DosyaIslem^.TekSektorIcerik);
    Inc(DG, DosyaIslem^.KayitSN);

    // dosya giri�inin ilk karakteri #0 ise t�m giri�ler okunmu� demektir
    if(DG^.DosyaAdi[0] = #00) then
    begin

      TumGirislerOkundu := True;
    end
    else
    begin

      DosyaAdi := ELRDosyaAdiniAl(DG);

      // dosya ad kontrol�
      if(DG^.GirdiTipi = ELR_GT_DOSYA) and (DosyaAdi = DosyaIslem^.DosyaAdi) then
      begin

        DosyaBulundu := True;
        TumGirislerOkundu := True;
      end;
    end;

    if not(TumGirislerOkundu) then
    begin

      // bir sonraki girdiye konumlan
      Inc(DosyaIslem^.KayitSN);
      if(DosyaIslem^.KayitSN = DIZIN_GIRDI_SAYISI) then
      begin

        // yeni sekt�r�n okunmas� i�in KayitSN de�i�kenini -1 olarak ayarla
        DosyaIslem^.KayitSN := -1;

        Inc(ZincirNo);
        if(ZincirNo = ZincirBasinaSektor) then
        begin

          i := SHTBirSonrakiKumeyiAl(DosyaIslem^.MantiksalDepolama, KumeNo);
          if(i = ELR_ZD_SON) then Exit(False);

          KumeNo := i;
          ZincirNo := 0;
        end;
      end else Inc(DG);
    end;

  until TumGirislerOkundu;

  // dosyan�n bulunmas� halinde...
  if(DosyaBulundu) then
  begin

    // dosyay� silindi olarak i�aretle
    DG^.Ozellikler := ELR_O_SILINMIS;

    // aktif dizin giri�inin bulundu�u sekt�r� g�ncelle (�zerine yaz)
    MD^.FD^.SektorYaz(MD^.FD, DosyaIslem^.SektorNo, 1, DosyaIslem^.TekSektorIcerik);

    Result := True;

  end else Result := False;
end;

{==============================================================================
  dizin giri�inden ilgili bilgileri al�r
 ==============================================================================}
function DizinGirdisiOku(ADizinGirisi: PDizinGirisi; AAranacakDeger: string;
  var ADosyaArama: TDosyaArama): TSayi1;
var
  MD: PMantiksalDepolama;
  AktifDG: PDizinGirdisiELR;
  TumGirislerOkundu: Boolean;
  DosyaIslem: PDosyaIslem;
  ZincirBasinaSektor: TSayi1;
  KumeNo: TSayi4;
begin

  // 0 = bir sonraki girdi mevcut, 1 = t�m girdiler okundu
  Result := 1;

  ADosyaArama.DosyaAdi := '';

  // ilk de�er atamalar�
  TumGirislerOkundu := False;

  // dosya i�lem yap�s� bellek b�lgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaArama.Kimlik];

  // araman�n yap�laca�� s�r�c�
  MD := DosyaIslem^.MantiksalDepolama;

  ZincirBasinaSektor := MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;
  KumeNo := MD^.Acilis.DizinGirisi.IlkSektor div ZincirBasinaSektor;

  repeat

    if(DosyaIslem^.KayitSN = -1) then
    begin

      DosyaIslem^.SektorNo := (KumeNo * ZincirBasinaSektor) + DosyaIslem^.ZincirNo;

      // dizin giri� sekt�r�n� oku
      MD^.FD^.SektorOku(MD^.FD, DosyaIslem^.SektorNo, 1, DosyaIslem^.TekSektorIcerik);

      DosyaIslem^.KayitSN := 0;
    end;

    // dosya giri� tablosuna konumlan
    AktifDG := PDizinGirdisiELR(DosyaIslem^.TekSektorIcerik);
    Inc(AktifDG, DosyaIslem^.KayitSN);

    // dosya giri�inin ilk karakteri #0 ise giri�ler okunmu� demektir
    if(AktifDG^.DosyaAdi[0] = #00) then
    begin

      Result := 1;
      TumGirislerOkundu := True;
    end
    // silinmi� dosya / klas�r
    else if(AktifDG^.Ozellikler = ELR_O_SILINMIS) then
    begin

      // bir sonraki giri�le devam et
    end
    else
    begin

      ADosyaArama.DosyaAdi := ELRDosyaAdiniAl(AktifDG);
      if(AktifDG^.GirdiTipi = ELR_GT_KLASOR) then
        ADosyaArama.Ozellikler := $10     { TODO - �ekirdek ve uygulama alan�nda yap�land�r }
      else ADosyaArama.Ozellikler := 0;
      ADosyaArama.OlusturmaTarihi := AktifDG^.OlusturmaTarihi;
      ADosyaArama.OlusturmaSaati := AktifDG^.OlusturmaSaati;
      ADosyaArama.SonErisimTarihi := 0;
      ADosyaArama.SonDegisimTarihi := AktifDG^.DegisimTarihi;
      ADosyaArama.SonDegisimSaati := AktifDG^.DegisimSaati;

      // dosya uzunlu�u ve cluster ba�lang�c�n� geri d�n�� de�erine ekle
      ADosyaArama.DosyaUzunlugu := AktifDG^.DosyaUzunlugu;
      ADosyaArama.BaslangicKumeNo := AktifDG^.BaslangicKumeNo;

      Result := 0;
      TumGirislerOkundu := True;
    end;

    // bir sonraki girdiye konumlan
    Inc(DosyaIslem^.KayitSN);
    if(DosyaIslem^.KayitSN = DIZIN_GIRDI_SAYISI) then
    begin

      // yeni sekt�r�n okunmas� i�in KayitSN de�i�kenini -1 olarak ayarla
      DosyaIslem^.KayitSN := -1;

      Inc(DosyaIslem^.ZincirNo);
      if(DosyaIslem^.ZincirNo = ZincirBasinaSektor) then
      begin

        DosyaIslem^.ZincirNo := 0;

        KumeNo := SHTBirSonrakiKumeyiAl(MD, KumeNo);
        if(KumeNo = ELR_ZD_SON) then
        begin

          TumGirislerOkundu := True;
          Result := 1;
        end;
      end;
    end else Inc(AktifDG);

  until TumGirislerOkundu;
end;

function ELRDosyaAdiniAl(ADizinGirdisi: PDizinGirdisiELR): string;
var
  i: TSayi4;
begin

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
  KumeNo, i: TSayi4;
begin

  GetMem(Bellek, 512);

  // dosya tablosunu olu�tur
  FillChar(Bellek^, 512, 0);

  FD := AMD^.FD;

  KumeNo := 384;      // k�me no: 384, sekt�r no: 1536 veya $600

  // 10 k�me * 4 sekt�r i�eri�ini sil
  for i := 0 to 9 do
  begin

    FD^.SektorYaz(FD, (KumeNo + i) * 4, 4, Bellek);
  end;

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
function SHTBosKumeTahsisEt(AMD: PMantiksalDepolama): TISayi4;
var
  Bellek: Isaretci;
  FD: PFizikselDepolama;
  KumeNo, i, j: TSayi4;
  Deger: PSayi4;
  HataDurumu: TISayi4;
begin

  GetMem(Bellek, 512);

  // t�m sekt�rler dolu
  KumeNo := 0;

  FD := AMD^.FD;

  for i := 256 to (256 + 1280) - 1 do
  begin

    HataDurumu := FD^.SektorOku(FD, i, 1, Bellek);
    if(HataDurumu <> HATA_YOK) then
    begin

      FreeMem(Bellek, 512);
      Exit(HataDurumu);
    end;

    Deger := Bellek;
    for j := 0 to 128 - 1 do
    begin

      if(Deger^ = 0) then
      begin

        Deger^ := ELR_ZD_SON;
        HataDurumu := FD^.SektorYaz(FD, i, 1, Bellek);
        if(HataDurumu <> HATA_YOK) then
        begin

          //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'SHTBosKumeTahsisEt.HataKodu: %d', [HataDurumu]);
          FreeMem(Bellek, 512);
          Exit(HataDurumu);
        end;

        //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'SHTBosKumeTahsisEt: %d', [KumeNo]);

        FreeMem(Bellek, 512);
        Exit(KumeNo);
      end;

      Inc(KumeNo);
      Inc(Deger);
    end;
  end;

  FreeMem(Bellek, 512);
  Result := HATA_TUMSEKTORLERDOLU;
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

  {SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'SHTKumeyiBirOncekiKumeyeBagla:', []);
  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ABirOncekiKumeNo: %d', [ABirOncekiKumeNo]);
  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'AKumeNo: %d', [AKumeNo]);}

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

  Bellek := GetMem(512);

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

{==============================================================================
  sekt�r olarak depolama ayg�t� kullan�lan toplam kapasiteyi hesaplar
 ==============================================================================}
function SHTToplamKullanim(AMD: PMantiksalDepolama): TSayi4;
var
  Bellek: Isaretci;
  FD: PFizikselDepolama;
  i, j, KullanilanSektor: TSayi4;
  Deger: PSayi4;
begin

  Bellek := GetMem(512);

  // t�m sekt�rler dolu
  KullanilanSektor := 0;

  FD := AMD^.FD;

  for i := 256 to (256 + 1280) - 1 do
  begin

    FD^.SektorOku(FD, i, 1, Bellek);

    Deger := Bellek;
    for j := 0 to 128 - 1 do
    begin

      if(Deger^ <> 0) then Inc(KullanilanSektor);
      Inc(Deger);
    end;
  end;

  FreeMem(Bellek, 512);

  Result := KullanilanSektor * 4; // 4 = zincirdeki sekt�r say�s�
end;

end.
