{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: elr1.pas
  Dosya Ýþlevi: ELERA Ýþletim Sistemi'nin dosya sistemi

  Güncelleme Tarihi: 26/05/2025

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
  dosya arama iþlevini baþlatýr
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
  dosya arama iþlemine devam eder
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
  dosya arama iþlemini sonlandýrýr
 ==============================================================================}
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
begin

  Result := 0;
end;

{==============================================================================
  dosyalar ile ilgili iþlem yapmadan önce taným iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
begin

  // iþlev dosya.pas tarafýndan yönetilmektedir
end;

{==============================================================================
  dosya oluþturma iþlevini gerçekleþtirir
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

  // en son iþlem hatalý ise çýk
  if(AktifGorev^.FDosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  // dosya açýk mý? (kapalý olmalý)
  if(DosyaIslem^.DosyaDurumu <> ddKapali) then
  begin

    AktifGorev^.FDosyaSonIslemDurum := HATA_DOSYA_KULLANIMDA;
    Exit;
  end;

  // ilk deðer atamalarý
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

      // dizin giriþ sektörünü oku
      MD^.FD^.SektorOku(MD^.FD, DosyaIslem^.SektorNo, 1, DosyaIslem^.TekSektorIcerik);

      DosyaIslem^.KayitSN := 0;
    end;

    // dizin giriþ tablosuna konumlan
    AktifDG := PDizinGirdisiELR(DosyaIslem^.TekSektorIcerik);
    Inc(AktifDG, DosyaIslem^.KayitSN);

    // dosya giriþinin ilk karakteri #0 ise giriþler okunmuþ demektir
    if(AktifDG^.DosyaAdi[0] = #00) then
    begin

      TumGirislerOkundu := True;
    end
    // silinmiþ dosya / klasör
    else if(AktifDG^.Ozellikler = ELR_O_SILINMIS) then
    begin

      // bir sonraki giriþle devam et
    end
    else
    begin

      DosyaAdi := ELRDosyaAdiniAl(AktifDG);

      if(AktifDG^.GirdiTipi = ELR_GT_DOSYA) and (DosyaAdi = DosyaIslem^.DosyaAdi) then
      begin

        // diðer iþlevlerin de girdi üzerinde iþlem yapabilmesi için
        // dosya bilgilerini aktif dizin giriþine taþý
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

        // yeni sektörün okunmasý için KayitSN deðiþkenini -1 olarak ayarla
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

  // dosya oluþturma iþlemi

  // 1. dosyanýn mevcut olmasý durumunda
  if(DosyaBulundu) then
  begin

    // aktif dizin giriþine konumlan
    AktifDG := @DosyaIslem^.AktifDG;

    { TODO - bu aþamada dosya için ayrýlan tüm kümeler serbest býrakýlacak }
    if(AktifDG^.BaslangicKumeNo <> ELR_ZD_SON) then SHTBosKumeSerbestBirak(MD, AktifDG^.BaslangicKumeNo);

    // aktif tarih / saat bilgilerini al
    TarihAl(Gun, Ay, Yil, HG);
    SaatAl(Saat, Dakika, Saniye);

    // güncel veriler öncelikle aktif dizin giriþine aktarýlacak
    AktifDG^.GirdiTipi := ELR_GT_DOSYA;
    AktifDG^.Ozellikler := ELR_O_NORMAL;
    AktifDG^.OlusturmaTarihi := ELRTarih(Gun, Ay, Yil);
    AktifDG^.OlusturmaSaati := ELRSaat(Saat, Dakika, Saniye);
    AktifDG^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
    AktifDG^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);
    AktifDG^.BaslangicKumeNo := ELR_ZD_SON;
    AktifDG^.DosyaUzunlugu := 0;

    // aktif dizin giriþinin sektördeki içeriðini güncelle
    Tasi2(AktifDG, DosyaIslem^.TekSektorIcerik + (DosyaIslem^.KayitSN * ELR_DG_U), ELR_DG_U);

    // aktif dizin giriþinin bulunduðu sektörü güncelle (üzerine yaz)
    MD^.FD^.SektorYaz(MD^.FD, DosyaIslem^.SektorNo, 1, DosyaIslem^.TekSektorIcerik);

    // dosya durumunu, "dosya yazým için açýldý" olarak güncelle
    DosyaIslem^.DosyaDurumu := ddYazmaIcinAcik;
  end
  else
  // 2. dosyanýn mevcut OLMAMASI durumunda
  begin

    if(DosyaIslem^.KayitSN >= 0) and (DosyaIslem^.KayitSN < DIZIN_GIRDI_SAYISI) then
    begin

      // aktif dizin giriþine konumlan
      AktifDG := @DosyaIslem^.AktifDG;

      // aktif tarih / saat bilgilerini al
      TarihAl(Gun, Ay, Yil, HG);
      SaatAl(Saat, Dakika, Saniye);

      // 2.2. güncel veriler öncelikle aktif dizin giriþine aktarýlacak
      AktifDG^.GirdiTipi := ELR_GT_DOSYA;
      AktifDG^.Ozellikler := ELR_O_NORMAL;
      AktifDG^.OlusturmaTarihi := ELRTarih(Gun, Ay, Yil);
      AktifDG^.OlusturmaSaati := ELRSaat(Saat, Dakika, Saniye);
      AktifDG^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
      AktifDG^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);
      AktifDG^.BaslangicKumeNo := ELR_ZD_SON;
      AktifDG^.DosyaUzunlugu := 0;

      // aktif dizin giriþinin sektördeki içeriðini güncelle
      Tasi2(AktifDG, DosyaIslem^.TekSektorIcerik + (DosyaIslem^.KayitSN * ELR_DG_U), ELR_DG_U);

      // aktif dizin giriþinin bulunduðu sektörü güncelle (üzerine yaz)
      MD^.FD^.SektorYaz(MD^.FD, DosyaIslem^.SektorNo, 1, DosyaIslem^.TekSektorIcerik);

      // dosya durumunu, "dosya yazým için açýldý" olarak güncelle
      DosyaIslem^.DosyaDurumu := ddYazmaIcinAcik;
    end;
  end;
end;

{==============================================================================
  dosyaya veri eklemek için dosya açma iþlevlerini gerçekleþtirir
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

  // en son iþlem hatalý ise çýk
  if(AktifGorev^.FDosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  // dosya daha önce kapalý olmalý
  if(DosyaIslem^.DosyaDurumu <> ddKapali) then
  begin

    AktifGorev^.FDosyaSonIslemDurum := HATA_DOSYA_KULLANIMDA;
    Exit;
  end;

  // ilk deðer atamalarý
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

      // dizin giriþ sektörünü oku
      MD^.FD^.SektorOku(MD^.FD, DosyaIslem^.SektorNo, 1, DosyaIslem^.TekSektorIcerik);

      DosyaIslem^.KayitSN := 0;
    end;

    // dosya giriþ tablosuna konumlan
    AktifDG := PDizinGirdisiELR(DosyaIslem^.TekSektorIcerik);
    Inc(AktifDG, DosyaIslem^.KayitSN);

    // dosya giriþinin ilk karakteri #0 ise giriþler okunmuþ demektir
    if(AktifDG^.DosyaAdi[0] = #00) then
    begin

      TumGirislerOkundu := True;
    end
    // silinmiþ dosya / klasör
    else if(AktifDG^.Ozellikler = ELR_O_SILINMIS) then
    begin

      // bir sonraki giriþle devam et
    end
    else
    begin

      DosyaAdi := ELRDosyaAdiniAl(AktifDG);

      if(AktifDG^.GirdiTipi = ELR_GT_DOSYA) and (DosyaAdi = DosyaIslem^.DosyaAdi) then
      begin

        // diðer iþlevlerin de girdi üzerinde iþlem yapabilmesi için
        // dosya bilgilerini aktif dizin giriþine taþý
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

        // yeni sektörün okunmasý için KayitSN deðiþkenini -1 olarak ayarla
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

  // dosyanýn bulunmasý halinde dosyanýn durumunu yazma için açýk olarak belirt
  if(DosyaBulundu) then
  begin

    DosyaIslem^.DosyaDurumu := ddYazmaIcinAcik;
  end
  else
  // aksi halde ilgili hata kodunu deðiþkene ata
  begin

    AktifGorev^.FDosyaSonIslemDurum := HATA_DOSYA_MEVCUTDEGIL;
  end;
end;

{==============================================================================
  dosyayý okumadan önce ön hazýrlýk iþlevlerini gerçekleþtirir
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

  // en son iþlem hatalý ise çýk
  if(AktifGorev^.FDosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  // tam dosya adýný al
  TamAramaYolu := DosyaIslem^.MantiksalDepolama^.MD3.AygitAdi + ':' + DosyaIslem^.Klasor + '*.*';

  // dosyayý dosya tablosunda bul
  Bulundu := False;
  if(FindFirst(TamAramaYolu, 0, DosyaArama) = 0) then
  begin

    repeat

      if(DosyaArama.DosyaAdi = DosyaIslem^.DosyaAdi) then Bulundu := True;
    until (Bulundu) or (FindNext(DosyaArama) <> 0);

    FindClose(DosyaArama);
  end;

  // dosyanýn tabloda bulunmasý halinde
  // dosyanýn ilk dizi ve uzunluðunu al
  if(Bulundu) then
  begin

    DosyaIslem^.IlkZincirSektor := DosyaArama.BaslangicKumeNo;
    DosyaIslem^.Uzunluk := DosyaArama.DosyaUzunlugu;

    {SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'IlkZincirSektor: %d', [DosyaIslem^.IlkZincirSektor]);
    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'DosyaUzunlugu: %d', [DosyaIslem^.Uzunluk]);}

    // dosya durumunu, "dosya okuma için açýldý" olarak güncelle
    DosyaIslem^.DosyaDurumu := ddOkumaIcinAcik;

  end else AktifGorev^.FDosyaSonIslemDurum := HATA_DOSYA_MEVCUTDEGIL;
end;

{==============================================================================
  dosyaya veri yazma iþlemini gerçekleþtirir
 ==============================================================================}
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
var
  VeriU: TSayi4;
begin

  VeriU := Length(AVeri);
  Write0(ADosyaKimlik, @AVeri[1], VeriU);
end;

{==============================================================================
  dosyaya veri yazma iþlemini gerçekleþtirir
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
  ToplamYazilacakVeriU,            // toplam yazýlacak veri uzunluðu
  j, SektorVeriU: TSayi4;
  AktifDG: PDizinGirdisiELR;
  Gun, Ay, Yil, HG: TSayi2;
  Saat, Dakika, Saniye, ZincirBasinaSektor: TSayi1;
  Bellek: Isaretci;
begin

  AktifGorev := GorevListesi[FAktifGorev];

  // en son iþlem hatalý ise çýk
  if(AktifGorev^.FDosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  // iþlem yapýlan dosyayla ilgili bellek bölgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  // dosya yazma için açýk mý?
  if not(DosyaIslem^.DosyaDurumu = ddYazmaIcinAcik) then
  begin

    AktifGorev^.FDosyaSonIslemDurum := HATA_DOSYA_YAZILAMIYOR;
    Exit;
  end;

  // ilk deðer atamalarý
  MD := DosyaIslem^.MantiksalDepolama;

  ZincirBasinaSektor := MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

  AktifDG := PDizinGirdisiELR(@DosyaIslem^.AktifDG);

  SHTyeYazilacakKumeNo := 0;

  // dosyanýn baþlangýç küeme numarasýný al, olmamasý durumunda yeni bir tane oluþtur
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

  // dosyaya ekleme yapýlacaksa (önceden veri yazýlmýþsa) en son kümeye konumlan
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

    // sektörün bir kýsmýna yazým yapýlmýþsa (ekleme yapýlacaksa), veriyi mevcut
    // veriye ekle ve aygýt sektörüne yaz
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

    // bu aþamada sektörün yarým dolu olmasý mevzu bahis deðildir
    // sektörler baþý itibariyle (sonu deðil) 0'a odaklý olarak yazýlacaktýr
    if(ToplamYazilacakVeriU > 0) then
    begin

      FillChar(Bellek^, 512 * ZincirBasinaSektor, $00);
      // kaç sektör yazýlacak
      i := 4 - SektorNo;
      // hedef bölgeye kaç byte kopyalanacak
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

  // aktif dizin giriþinin sektördeki içeriðini güncelle
  Tasi2(AktifDG, DosyaIslem^.TekSektorIcerik + (DosyaIslem^.KayitSN * ELR_DG_U), ELR_DG_U);

  // dosyanýn güncel deðerlerini ilgili sektöre yaz
  MD^.FD^.SektorYaz(MD^.FD, DosyaIslem^.SektorNo, 1, DosyaIslem^.TekSektorIcerik);
end;

{==============================================================================
  verinin sonuna #13#10 ekleyerek dosyaya veri yazma iþlemini gerçekleþtirir
 ==============================================================================}
procedure WriteLn(ADosyaKimlik: TKimlik; AVeri: string);
begin

  Write(ADosyaKimlik, AVeri + #13#10);
end;

{==============================================================================
  dosyaya veri yazma iþlemini gerçekleþtirir
 ==============================================================================}
procedure Write(ADosyaKimlik: TKimlik; ABellekAdresi: Isaretci; AUzunluk: TSayi4);
begin

  Write0(ADosyaKimlik, ABellekAdresi, AUzunluk);
end;

{==============================================================================
  dosya okuma iþlemini gerçekleþtirir
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
  ToplamVeriU, HedefBellekSN: TSayi4;              // toplam okunacak veri uzunluðu
  Bellek: Isaretci;
begin

  // iþlem yapýlan dosyayla ilgili bellek bölgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaKimlik];

  // üzerinde iþlem yapýlacak sürücü
  MD := DosyaIslem^.MantiksalDepolama;

  VeriU := DosyaIslem^.Uzunluk;
  if(VeriU = 0) then Exit;

  ToplamVeriU := VeriU;

  //SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Ýlk Zincir: %x', [DosyaKayit^.IlkZincirSektor]);
  //SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Dosya Uzunluk: %d', [OkunacakVeri]);

  Zincir := DosyaIslem^.IlkZincirSektor;

  ZincirBasinaSektor := MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

  OkumaSonuc := False;

  GetMem(Bellek, 2048);

  HedefBellekSN := 0;

  repeat

    // okunacak byte'ý sektör sayýsýna çevir
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

    // okunacak cluster numarasý
    i := Zincir; //(Zincir - 2) * ZincirBasinaSektor;
    //i += MD^.Acilis.IlkVeriSektorNo;

    //SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Zincir: %d', [i]);

    // sektörü belleðe oku
    MD^.FD^.SektorOku(MD^.FD, i * ZincirBasinaSektor, OkunacakSektorSayisi, Bellek);

    // okunacak bilginin yerleþtirileceði bir sonraki adresi belirle
    {AHedefBellek += KopyalanacakVeriUzunlugu;

    OkunacakFAT := (Zincir * 4) div 512;

    // depolama aygýtýnýn ilk FAT kopyasýnýn tümünü belleðe yükle
    MD^.FD^.SektorOku(MD^.FD, MD^.Acilis.DosyaAyirmaTablosu.IlkSektor + OkunacakFAT,
      1, @OYBellek);

    // zincir deðerini 4 ile çarp ve bir sonraki zincir deðerini al
    YeniDATSiraNo := (Zincir * 4) mod 512;
    DATSiraNo := PSayi4(Isaretci(@OYBellek) + YeniDATSiraNo)^;

    Zincir := DATSiraNo;}

    Tasi2(Bellek, AHedefBellek + HedefBellekSN, KopyalanacakVeriUzunlugu);
    HedefBellekSN += KopyalanacakVeriUzunlugu;

    OkumaSonuc := True;

    if(VeriU > 0) then Zincir := SHTBirSonrakiKumeyiAl(MD, Zincir);

  // eðer 0xfff8..0xffff aralýðýndaysa bu dosyanýn en son cluster'idir
  until (Zincir = ELR_ZD_SON) or (VeriU = 0);

  FreeMem(Bellek, 2048);
end;

{==============================================================================
  dosya ile yapýlmýþ en son iþlemin sonucunu döndürür
 ==============================================================================}
function IOResult: TISayi4;
begin

  Result := 0;
  // bilgi: iþlev dosya.pas tarafýndan yönetilmektedir
end;

{==============================================================================
  dosya uzunluðunu geri döndürür
 ==============================================================================}
function FileSize(ADosyaKimlik: TKimlik): TISayi8;
begin

  Result := 0;
  // bilgi: iþlev dosya.pas tarafýndan yönetilmektedir
end;

{==============================================================================
  dosya okuma iþleminde dosyanýn sonuna gelinip gelinmediðini belirtir
 ==============================================================================}
function EOF(ADosyaKimlik: TKimlik): Boolean;
begin

  Result := True;
end;

{==============================================================================
  dosya üzerinde yapýlan iþlemi sonlandýrýr
 ==============================================================================}
procedure CloseFile(ADosyaKimlik: TKimlik);
begin
end;

{==============================================================================
  klasör oluþturma iþlevini gerçekleþtirir
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

  // ilk deðer atamalarý
  Result := False;

  KlasorBulundu := False;

  TumGirislerOkundu := False;

  // dosya iþlem yapýsý bellek bölgesine konumlan
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

      // dizin giriþ sektörünü oku
      MD^.FD^.SektorOku(MD^.FD, DosyaIslem^.SektorNo, 1, DosyaIslem^.TekSektorIcerik);

      DosyaIslem^.KayitSN := 0;
    end;

    // dizin giriþ tablosuna konumlan
    DG := PDizinGirdisiELR(DosyaIslem^.TekSektorIcerik);
    Inc(DG, DosyaIslem^.KayitSN);

    // klasör giriþinin ilk karakteri #0 ise tüm giriþler okunmuþ demektir
    if(DG^.DosyaAdi[0] = #00) then
    begin

      TumGirislerOkundu := True;
    end
    // silinmiþ dosya / klasör
    else if(DG^.Ozellikler = ELR_O_SILINMIS) then
    begin

      // silinen girdiye klasör oluþtur
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

        // yeni sektörün okunmasý için KayitSN deðiþkenini -1 olarak ayarla
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

  // klasör oluþturma iþlemi
  if not(KlasorBulundu) then
  begin

    if(DosyaIslem^.KayitSN >= 0) and (DosyaIslem^.KayitSN < DIZIN_GIRDI_SAYISI) then
    begin

      // aktif tarih / saat bilgilerini al
      TarihAl(Gun, Ay, Yil, HG);
      SaatAl(Saat, Dakika, Saniye);

      // dosya adýný hedef bölgeye kopyala
      Tasi2(@DosyaIslem^.AktifDG[0], DG, ELR_DG_U);

      DG^.GirdiTipi := ELR_GT_KLASOR;
      DG^.Ozellikler := ELR_O_NORMAL;
      DG^.OlusturmaTarihi := ELRTarih(Gun, Ay, Yil);
      DG^.OlusturmaSaati := ELRSaat(Saat, Dakika, Saniye);
      DG^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
      DG^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);
      DG^.BaslangicKumeNo := ELR_ZD_SON;
      DG^.DosyaUzunlugu := 0;

      // aktif dizin giriþinin bulunduðu sektörü güncelle (üzerine yaz)
      MD^.FD^.SektorYaz(MD^.FD, DosyaIslem^.SektorNo, 1, DosyaIslem^.TekSektorIcerik);

      Result := True;
    end;
  end;
end;

{==============================================================================
  klasör silme iþlevini gerçekleþtirir
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

  // ilk deðer atamalarý
  Result := False;

  KlasorBulundu := False;

  TumGirislerOkundu := False;

  // dosya iþlem yapýsý bellek bölgesine konumlan
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

      // dizin giriþ sektörünü oku
      MD^.FD^.SektorOku(MD^.FD, DosyaIslem^.SektorNo, 1, DosyaIslem^.TekSektorIcerik);

      DosyaIslem^.KayitSN := 0;
    end;

    // dizin giriþ tablosuna konumlan
    DG := PDizinGirdisiELR(DosyaIslem^.TekSektorIcerik);
    Inc(DG, DosyaIslem^.KayitSN);

    // klasör giriþinin ilk karakteri #0 ise tüm giriþler okunmuþ demektir
    if(DG^.DosyaAdi[0] = #00) then
    begin

      TumGirislerOkundu := True;
    end
    else
    begin

      DosyaAdi := ELRDosyaAdiniAl(DG);

      // klasör ad kontrolü
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

        // yeni sektörün okunmasý için KayitSN deðiþkenini -1 olarak ayarla
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

  // klasörün bulunmasý halinde...
  if(KlasorBulundu) then
  begin

    // klasörü silindi olarak iþaretle
    DG^.Ozellikler := ELR_O_SILINMIS;

    // aktif dizin giriþinin bulunduðu sektörü güncelle (üzerine yaz)
    MD^.FD^.SektorYaz(MD^.FD, DosyaIslem^.SektorNo, 1, DosyaIslem^.TekSektorIcerik);

    Result := True;

  end else Result := False;
end;

{==============================================================================
  dosya silme iþlevini gerçekleþtirir
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

  // ilk deðer atamalarý
  Result := False;

  DosyaBulundu := False;

  TumGirislerOkundu := False;

  // dosya iþlem yapýsý bellek bölgesine konumlan
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

      // dizin giriþ sektörünü oku
      MD^.FD^.SektorOku(MD^.FD, DosyaIslem^.SektorNo, 1, DosyaIslem^.TekSektorIcerik);

      DosyaIslem^.KayitSN := 0;
    end;

    // dizin giriþ tablosuna konumlan
    DG := PDizinGirdisiELR(DosyaIslem^.TekSektorIcerik);
    Inc(DG, DosyaIslem^.KayitSN);

    // dosya giriþinin ilk karakteri #0 ise tüm giriþler okunmuþ demektir
    if(DG^.DosyaAdi[0] = #00) then
    begin

      TumGirislerOkundu := True;
    end
    else
    begin

      DosyaAdi := ELRDosyaAdiniAl(DG);

      // dosya ad kontrolü
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

        // yeni sektörün okunmasý için KayitSN deðiþkenini -1 olarak ayarla
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

  // dosyanýn bulunmasý halinde...
  if(DosyaBulundu) then
  begin

    // dosyayý silindi olarak iþaretle
    DG^.Ozellikler := ELR_O_SILINMIS;

    // aktif dizin giriþinin bulunduðu sektörü güncelle (üzerine yaz)
    MD^.FD^.SektorYaz(MD^.FD, DosyaIslem^.SektorNo, 1, DosyaIslem^.TekSektorIcerik);

    Result := True;

  end else Result := False;
end;

{==============================================================================
  dizin giriþinden ilgili bilgileri alýr
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

  // 0 = bir sonraki girdi mevcut, 1 = tüm girdiler okundu
  Result := 1;

  ADosyaArama.DosyaAdi := '';

  // ilk deðer atamalarý
  TumGirislerOkundu := False;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DosyaIslem := @GDosyaIslemleri[ADosyaArama.Kimlik];

  // aramanýn yapýlacaðý sürücü
  MD := DosyaIslem^.MantiksalDepolama;

  ZincirBasinaSektor := MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;
  KumeNo := MD^.Acilis.DizinGirisi.IlkSektor div ZincirBasinaSektor;

  repeat

    if(DosyaIslem^.KayitSN = -1) then
    begin

      DosyaIslem^.SektorNo := (KumeNo * ZincirBasinaSektor) + DosyaIslem^.ZincirNo;

      // dizin giriþ sektörünü oku
      MD^.FD^.SektorOku(MD^.FD, DosyaIslem^.SektorNo, 1, DosyaIslem^.TekSektorIcerik);

      DosyaIslem^.KayitSN := 0;
    end;

    // dosya giriþ tablosuna konumlan
    AktifDG := PDizinGirdisiELR(DosyaIslem^.TekSektorIcerik);
    Inc(AktifDG, DosyaIslem^.KayitSN);

    // dosya giriþinin ilk karakteri #0 ise giriþler okunmuþ demektir
    if(AktifDG^.DosyaAdi[0] = #00) then
    begin

      Result := 1;
      TumGirislerOkundu := True;
    end
    // silinmiþ dosya / klasör
    else if(AktifDG^.Ozellikler = ELR_O_SILINMIS) then
    begin

      // bir sonraki giriþle devam et
    end
    else
    begin

      ADosyaArama.DosyaAdi := ELRDosyaAdiniAl(AktifDG);
      if(AktifDG^.GirdiTipi = ELR_GT_KLASOR) then
        ADosyaArama.Ozellikler := $10     { TODO - çekirdek ve uygulama alanýnda yapýlandýr }
      else ADosyaArama.Ozellikler := 0;
      ADosyaArama.OlusturmaTarihi := AktifDG^.OlusturmaTarihi;
      ADosyaArama.OlusturmaSaati := AktifDG^.OlusturmaSaati;
      ADosyaArama.SonErisimTarihi := 0;
      ADosyaArama.SonDegisimTarihi := AktifDG^.DegisimTarihi;
      ADosyaArama.SonDegisimSaati := AktifDG^.DegisimSaati;

      // dosya uzunluðu ve cluster baþlangýcýný geri dönüþ deðerine ekle
      ADosyaArama.DosyaUzunlugu := AktifDG^.DosyaUzunlugu;
      ADosyaArama.BaslangicKumeNo := AktifDG^.BaslangicKumeNo;

      Result := 0;
      TumGirislerOkundu := True;
    end;

    // bir sonraki girdiye konumlan
    Inc(DosyaIslem^.KayitSN);
    if(DosyaIslem^.KayitSN = DIZIN_GIRDI_SAYISI) then
    begin

      // yeni sektörün okunmasý için KayitSN deðiþkenini -1 olarak ayarla
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

  // dosya adýný çevir
  i := 1;
  while (i <= ELR_DOSYA_U) and (ADizinGirdisi^.DosyaAdi[i] <> #0) do
  begin

    Result := Result + ADizinGirdisi^.DosyaAdi[i];
    Inc(i);
  end;
end;

{==============================================================================
  diski elr-1 dosya sistemi için hazýrlar
 ==============================================================================}
procedure ELR1DiskBicimle(AMD: PMantiksalDepolama);
begin

  ELR1VerileriSil(AMD);

  // dosya içerik tablosunu oluþtur
  ELR1SHTOlustur(AMD, 256, 1280, 1536);
end;

{==============================================================================
  dosya sisteminin veri alanýndaki mevcut verileri siler
 ==============================================================================}
procedure ELR1VerileriSil(AMD: PMantiksalDepolama);
var
  FD: PFizikselDepolama;
  Bellek: Isaretci;
  KumeNo, i: TSayi4;
begin

  GetMem(Bellek, 512);

  // dosya tablosunu oluþtur
  FillChar(Bellek^, 512, 0);

  FD := AMD^.FD;

  KumeNo := 384;      // küme no: 384, sektör no: 1536 veya $600

  // 10 küme * 4 sektör içeriðini sil
  for i := 0 to 9 do
  begin

    FD^.SektorYaz(FD, (KumeNo + i) * 4, 4, Bellek);
  end;

  FreeMem(Bellek, 512);
end;

{==============================================================================
  dosya sistemi sektör harita tablosunu oluþturur
 ==============================================================================}
procedure ELR1SHTOlustur(AMD: PMantiksalDepolama; AIlkSektor, AToplamSektor,
 AAyrilanSektor: TSayi4);
var
  Bellek: Isaretci;
  FD: PFizikselDepolama;
  i, j: TSayi4;
begin

  { TODO - burada katý kodlama uygulanmýþtýr, kodlar kontrol edilecektir }

  GetMem(Bellek, 512);

  // sht için ayrýlan sektörleri sýfýrla
  FillChar(Bellek^, 512, 0);
  FD := AMD^.FD;

  for i := AIlkSektor to (AIlkSektor + AToplamSektor) - 1 do
  begin

    FD^.SektorYaz(FD, i, 1, Bellek);
  end;

  // ayrýlan sektörleri ayrýlmýþ olarak iþaretle
  // buraya gelen deðer þu aþamada 1536 olacak
  // 1536 / 128 (bir sektördeki giriþ sayýsý) = 12

  // sektör sayýsý küme sayýsýna çevriliyor
  j := AAyrilanSektor div 4;

  // küme için gereken alan hesaplanýyor
  // her bir küme girdisi için 4 byte'e ihtiyaç var
  j := j * 4;

  // girdiler için gereken sektör sayýsý hesaplanýyor
  j := j div 512;

  FillChar(Bellek^, 512, $FF);

  for i := AIlkSektor to (AIlkSektor + j) - 1 do
  begin

    FD^.SektorYaz(FD, i, 1, Bellek);
  end;

  // ilk dizin giriþini ayýr
  FillChar(Bellek^, 512, 0);
  PSayi4(Bellek)^ := $FFFFFFFF;

  FD^.SektorYaz(FD, i + 1, 1, Bellek);

  FreeMem(Bellek, 512);
end;

{==============================================================================
  sektör harita tablosundan boþ küme numarasý alýr
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

  // tüm sektörler dolu
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
  sektör harita tablosundan alýnan sektör kümesini serbest býrakýr
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

  // konumlanýlacak sektör numarasý
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
  kümeyi bir önceki kümeye baðlar
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

  // konumlanýlacak sektör numarasý
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
  kümeye baðlý bir sonraki kümeyi alýr
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

  // konumlanýlacak sektör numarasý
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
  sektör olarak depolama aygýtý kullanýlan toplam kapasiteyi hesaplar
 ==============================================================================}
function SHTToplamKullanim(AMD: PMantiksalDepolama): TSayi4;
var
  Bellek: Isaretci;
  FD: PFizikselDepolama;
  i, j, KullanilanSektor: TSayi4;
  Deger: PSayi4;
begin

  Bellek := GetMem(512);

  // tüm sektörler dolu
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

  Result := KullanilanSektor * 4; // 4 = zincirdeki sektör sayýsý
end;

end.
