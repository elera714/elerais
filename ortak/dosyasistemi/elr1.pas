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

uses paylasim, islevler, gorev, fdepolama, mdepolama;

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
  var ADosyaArama: TDosyaArama): TSayi4;

procedure DosyaAdiniKopyala(ADosyaAdi: string; AHedef: PChar);
procedure ELR1DiskBicimle(AMDNesne: PMDNesne);
procedure ELR1VerileriSil(AMDNesne: PMDNesne);
procedure ELR1SHTOlustur(AMDNesne: PMDNesne; AIlkSektor, AToplamSektor,
 AAyrilanSektor: TSayi4);
function SHTBosKumeTahsisEt(AMDNesne: PMDNesne): TISayi4;
function SHTBosKumeSerbestBirak(AMDNesne: PMDNesne; AKumeNo: TSayi4): Boolean;
function SHTKumeyiBirOncekiKumeyeBagla(AMDNesne: PMDNesne; ABirOncekiKumeNo,
 AKumeNo: TSayi4): Boolean;
function SHTBirSonrakiKumeyiAl(AMDNesne: PMDNesne; AKumeNo: TSayi4): TSayi4;
function SHTToplamKullanim(AMDNesne: PMDNesne): TSayi4;
procedure SistemKlasorleriniOlustur;
procedure SistemKlasorleriniSil;
function ELRDosyaAdiniAl(ADizinGirdisi: PDizinGirdisiELR): string;

implementation

uses cmos, sistemmesaj, dosya;

{==============================================================================
  dosya arama iþlevini baþlatýr
  uyarý: iþlev SADECE dosya.pas tarafýndan çaðrýlmalýdýr!
 ==============================================================================}
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
 var ADosyaArama: TDosyaArama): TISayi4;
var
  DI: PDosyaIslem;
  DizinGirisi: PDizinGirisi;
begin

  DI := Dosyalar0.DosyaIslem[ADosyaArama.Kimlik];
  DizinGirisi := @DI^.DizinGirisi;
  DI^.Aranan := AAramaSuzgec;
  Result := DizinGirdisiOku(DizinGirisi, AAramaSuzgec, ADosyaArama);
end;

{==============================================================================
  dosya arama iþlemine devam eder
  uyarý: iþlev SADECE dosya.pas tarafýndan çaðrýlmalýdýr!
 ==============================================================================}
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
var
  DI: PDosyaIslem;
  DizinGirisi: PDizinGirisi;
  Aranan: string;
begin

  DI := Dosyalar0.DosyaIslem[ADosyaArama.Kimlik];
  DizinGirisi := @DI^.DizinGirisi;
  Aranan := DI^.Aranan;
  Result := DizinGirdisiOku(DizinGirisi, Aranan, ADosyaArama);
end;

{==============================================================================
  dosya arama iþlemini sonlandýrýr
  uyarý: iþlev SADECE dosya.pas tarafýndan çaðrýlmalýdýr!
 ==============================================================================}
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
begin

  Result := 0;
end;

{==============================================================================
  dosyalar ile ilgili iþlem yapmadan önce taným iþlevlerini gerçekleþtirir
  bilgi: iþlev dosya.pas tarafýndan yönetilmektedir
 ==============================================================================}
procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
begin
end;

{==============================================================================
  dosya oluþturma iþlevini gerçekleþtirir
  uyarý: iþlev SADECE dosya.pas tarafýndan çaðrýlmalýdýr!
 ==============================================================================}
procedure ReWrite(ADosyaKimlik: TKimlik);
var
  DG: PDizinGirdisiELR;
  DI: PDosyaIslem;
  ZincirBasinaSektor,
  i: TSayi4;
  DosyaBulundu: Boolean;
  Gun, Ay, Yil, HG: TSayi2;
  Saat, Dakika, Saniye: TSayi1;
  AramaKaydi: TDosyaArama;
  SektorNo: TISayi4;
begin

  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];

  // dosya açýk mý? (kapalý olmalý)
  if(DI^.DosyaDurumu <> ddKapali) then
  begin

    DI^.Gorev^.DosyaSonIslemDurum := HATA_DOSYA_KULLANIMDA;
    Exit;
  end;

  // ilk deðer atamalarý
  DosyaBulundu := False;

  // arama iþleminin daha önce oluþturulan dosya kimlik üzerinden devam etmesi için
  // kimlik deðeri arama kaydýna iliþkilendiriliyor
  AramaKaydi.Kimlik := DI^.Kimlik;

  i := dosya.FindFirst(DI^.MD.MD3.AygitAdi + ':\*.*', 0, AramaKaydi, False);
  while i = 0 do
  begin

    {SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'dosya adý1: %s', [AramaKaydi.DosyaAdi]);
    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'dosya adý2: %s', [DI^.DosyaAdi]);}

    if(AramaKaydi.DosyaAdi = DI^.DosyaAdi) and (AramaKaydi.Ozellikler = 0) then
    begin

      //dosya.FindClose(AramaKaydi);
      //Exit;
      DosyaBulundu := True;
      Break;
    end;

    i := dosya.FindNext(AramaKaydi);
  end;

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Kume: %x', [DI^.KumeNo]);
  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Zincir: %x', [DI^.ZincirNo]);
  {if(DosyaBulundu) then
    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'bulundu', [])
  else SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'bulunamadý', []);}

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'KayitSN: %x', [DI^.KayitSN]);

  ZincirBasinaSektor := DI^.MD.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

  SektorNo := (DI^.KumeNo * ZincirBasinaSektor) + DI^.ZincirNo;

  // dosya oluþturma iþlemi

  // 1. dosyanýn mevcut olmasý durumunda
  if(DosyaBulundu) then
  begin

    DG := PDizinGirdisiELR(DI^.TSI);
    Inc(DG, DI^.KayitSN);

    { TODO - bu aþamada dosya için ayrýlan tüm kümeler serbest býrakýlacak }
    if(DG^.BaslangicKumeNo <> ELR_ZD_SON) then
      SHTBosKumeSerbestBirak(@DI^.MD, DG^.BaslangicKumeNo);

    // aktif tarih / saat bilgilerini al
    TarihAl(Gun, Ay, Yil, HG);
    SaatAl(Saat, Dakika, Saniye);

    // güncel veriler öncelikle aktif dizin giriþine aktarýlacak
    DG^.GirdiTipi := ELR_GT_DOSYA;
    DG^.Ozellikler := ELR_O_NORMAL;
    DG^.OlusturmaTarihi := ELRTarih(Gun, Ay, Yil);
    DG^.OlusturmaSaati := ELRSaat(Saat, Dakika, Saniye);
    DG^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
    DG^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);
    DG^.BaslangicKumeNo := ELR_ZD_SON;
    DG^.DosyaUzunlugu := 0;

    // aktif dizin giriþinin bulunduðu sektörü güncelle (üzerine yaz)
    DI^.MD.FD^.SektorYaz(DI^.MD.FD, SektorNo, 1, DI^.TSI);

    // dosya durumunu, "dosya yazým için açýldý" olarak güncelle
    DI^.DosyaDurumu := ddYazmaIcinAcik;
  end
  else
  // 2. dosyanýn mevcut OLMAMASI durumunda
  begin

    if(DI^.KayitSN >= 0) and (DI^.KayitSN < DIZIN_GIRDI_SAYISI) then
    begin

      DG := PDizinGirdisiELR(DI^.TSI);
      Inc(DG, DI^.KayitSN);

      // dosya adýný hedef bölgeye kopyala
      DosyaAdiniKopyala(DI^.DosyaAdi, PChar(DG));

      // aktif tarih / saat bilgilerini al
      TarihAl(Gun, Ay, Yil, HG);
      SaatAl(Saat, Dakika, Saniye);

      // 2.2. güncel veriler öncelikle aktif dizin giriþine aktarýlacak
      DG^.GirdiTipi := ELR_GT_DOSYA;
      DG^.Ozellikler := ELR_O_NORMAL;
      DG^.OlusturmaTarihi := ELRTarih(Gun, Ay, Yil);
      DG^.OlusturmaSaati := ELRSaat(Saat, Dakika, Saniye);
      DG^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
      DG^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);
      DG^.BaslangicKumeNo := ELR_ZD_SON;
      DG^.DosyaUzunlugu := 0;

      // aktif dizin giriþinin bulunduðu sektörü güncelle (üzerine yaz)
      DI^.MD.FD^.SektorYaz(DI^.MD.FD, SektorNo, 1, DI^.TSI);

      // dosya durumunu, "dosya yazým için açýldý" olarak güncelle
      DI^.DosyaDurumu := ddYazmaIcinAcik;
    end;
  end;

  //dosya.FindClose(AramaKaydi);
end;

{==============================================================================
  dosyaya veri eklemek için dosya açma iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure Append(ADosyaKimlik: TKimlik);
var
  DI: PDosyaIslem;
  i: TSayi4;
  DosyaBulundu: Boolean;
  AramaKaydi: TDosyaArama;
begin

  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];

  // dosya açýk mý? (kapalý olmalý)
  if(DI^.DosyaDurumu <> ddKapali) then
  begin

    DI^.Gorev^.DosyaSonIslemDurum := HATA_DOSYA_KULLANIMDA;
    Exit;
  end;

  // ilk deðer atamalarý
  DosyaBulundu := False;

  // arama iþleminin daha önce oluþturulan dosya kimlik üzerinden devam etmesi için
  // kimlik deðeri arama kaydýna iliþkilendiriliyor
  AramaKaydi.Kimlik := DI^.Kimlik;

  i := dosya.FindFirst(DI^.MD.MD3.AygitAdi + ':\*.*', 0, AramaKaydi, False);
  while i = 0 do
  begin

    {SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'dosya adý1: %s', [AramaKaydi.DosyaAdi]);
    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'dosya adý2: %s', [DI^.DosyaAdi]);}

    if(AramaKaydi.DosyaAdi = DI^.DosyaAdi) and (AramaKaydi.Ozellikler = 0) then
    begin

      //dosya.FindClose(AramaKaydi);
      //Exit;
      DosyaBulundu := True;
      Break;
    end;

    i := dosya.FindNext(AramaKaydi);
  end;

  // dosyanýn bulunmasý halinde dosyanýn durumunu yazma için açýk olarak belirt
  if(DosyaBulundu) then
  begin

    DI^.DosyaDurumu := ddYazmaIcinAcik;
  end
  else
  // aksi halde ilgili hata kodunu deðiþkene ata
  begin

    DI^.Gorev^.DosyaSonIslemDurum := HATA_DOSYA_MEVCUTDEGIL;
  end;
end;

{==============================================================================
  dosyayý okumadan önce ön hazýrlýk iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure Reset(ADosyaKimlik: TKimlik);
var
  DI: PDosyaIslem;
  AramaKaydi: TDosyaArama;
  TamAramaYolu: string;
  Bulundu: Boolean;
  i: TISayi4;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];
  if(DI = nil) then Exit;

  // en son iþlem hatalý ise çýk
  if(DI^.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  // tam dosya adýný al
  TamAramaYolu := DI^.MD.MD3.AygitAdi + ':' + DI^.Klasor + '*.*';

  // dosyayý dosya tablosunda bul
  Bulundu := False;

  // arama iþleminin daha önce oluþturulan dosya kimlik üzerinden devam etmesi için
  // kimlik deðeri arama kaydýna iliþkilendiriliyor
  AramaKaydi.Kimlik := DI^.Kimlik;

  i := dosya.FindFirst(DI^.MD.MD3.AygitAdi + ':\*.*', 0, AramaKaydi, False);
  while i = 0 do
  begin

    {SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'dosya adý1: %s', [AramaKaydi.DosyaAdi]);
    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'dosya adý2: %s', [DI^.DosyaAdi]);}

    if(AramaKaydi.DosyaAdi = DI^.DosyaAdi) and (AramaKaydi.Ozellikler = 0) then
    begin

      //dosya.FindClose(AramaKaydi);
      //Exit;
      Bulundu := True;
      Break;
    end;

    i := dosya.FindNext(AramaKaydi);
  end;

  // dosyanýn tabloda bulunmasý halinde
  // dosyanýn ilk dizi ve uzunluðunu al
  if(Bulundu) then
  begin

    { TODO - bu deðerler iptal edildi. yok edilmeden önce kontrol edilecek - baþla }
    //DI^.IlkZincirSektor := AramaKaydi.BaslangicKumeNo;
    //DI^.Uzunluk := AramaKaydi.DosyaUzunlugu;

    {SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'IlkZincirSektor: %d', [DosyaIslem^.IlkZincirSektor]);
    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'DosyaUzunlugu: %d', [DosyaIslem^.Uzunluk]);}

    { TODO - bu deðerler iptal edildi. yok edilmeden önce kontrol edilecek - son }

    // dosya durumunu, "dosya okuma için açýldý" olarak güncelle
    DI^.DosyaDurumu := ddOkumaIcinAcik;

  end else DI^.Gorev^.DosyaSonIslemDurum := HATA_DOSYA_MEVCUTDEGIL;
end;

{==============================================================================
  dosyaya veri yazma iþlemini gerçekleþtirir
  uyarý: iþlev SADECE dosya.pas tarafýndan çaðrýlmalýdýr!
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
  uyarý: iþlev SADECE elr1.pas.Write iþlevi tarafýndan çaðrýlmalýdýr!
 ==============================================================================}
procedure Write0(ADosyaKimlik: TKimlik; ABellek: Isaretci; AUzunluk: TSayi4);
var
  DI: PDosyaIslem;
  SHTyeYazilacakKumeNo, YeniKumeNo: TISayi4;
  OncedenYazilanKumeSayisi,
  YazilacakKumeNo: TSayi4;
  SektorNo, i,
  OkumaKonum,
  ToplamYazilacakVeriU,            // toplam yazýlacak veri uzunluðu
  j, SektorVeriU: TSayi4;
  DG: PDizinGirdisiELR;
  Gun, Ay, Yil, HG: TSayi2;
  Saat, Dakika, Saniye, ZincirBasinaSektor: TSayi1;
  Bellek: Isaretci;
begin

  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];

  // dosya yazma için açýk mý?
  if not(DI^.DosyaDurumu = ddYazmaIcinAcik) then
  begin

    DI^.Gorev^.DosyaSonIslemDurum := HATA_DOSYA_YAZILAMIYOR;
    Exit;
  end;

  ZincirBasinaSektor := DI^.MD.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

  DG := PDizinGirdisiELR(DI^.TSI);
  Inc(DG, DI^.KayitSN);

  SHTyeYazilacakKumeNo := 0;

  // dosyanýn baþlangýç küeme numarasýný al, olmamasý durumunda yeni bir tane oluþtur
  if(DG^.BaslangicKumeNo = ELR_ZD_SON) then
  begin

    SHTyeYazilacakKumeNo := SHTBosKumeTahsisEt(@DI^.MD);
    if(SHTyeYazilacakKumeNo < HATA_YOK) then
    begin

      SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'SHTBosKumeTahsisEt.HataKodu: %d', [SHTyeYazilacakKumeNo]);
      DI^.Gorev^.DosyaSonIslemDurum := SHTyeYazilacakKumeNo;
      Exit;
    end;

    YazilacakKumeNo := SHTyeYazilacakKumeNo;
  end else YazilacakKumeNo := DG^.BaslangicKumeNo;

  ToplamYazilacakVeriU := AUzunluk;

  GetMem(Bellek, 512 * ZincirBasinaSektor);

  OkumaKonum := 0;

  OncedenYazilanKumeSayisi := (DG^.DosyaUzunlugu div (512 * ZincirBasinaSektor));

  // dosyaya ekleme yapýlacaksa (önceden veri yazýlmýþsa) en son kümeye konumlan
  if(OncedenYazilanKumeSayisi > 0) then
  begin

    for i := 1 to OncedenYazilanKumeSayisi do
    begin

      YazilacakKumeNo := SHTBirSonrakiKumeyiAl(@DI^.MD, YazilacakKumeNo);
    end;
  end;

  repeat

    SektorNo := (DG^.DosyaUzunlugu div 512) mod 4;
    SektorVeriU := (DG^.DosyaUzunlugu mod 512);

    // sektörün bir kýsmýna yazým yapýlmýþsa (ekleme yapýlacaksa), veriyi mevcut
    // veriye ekle ve aygýt sektörüne yaz
    if(SektorVeriU > 0) then
    begin

      FillChar(Bellek^, 512 * ZincirBasinaSektor, $00);
      DI^.MD.FD^.SektorOku(DI^.MD.FD, (YazilacakKumeNo * ZincirBasinaSektor) + SektorNo, 1, Bellek);

      j := 512 - SektorVeriU;
      if(j > ToplamYazilacakVeriU) then j := ToplamYazilacakVeriU;
      Tasi2(ABellek + OkumaKonum, Bellek + SektorVeriU, j);
      DI^.MD.FD^.SektorYaz(DI^.MD.FD, (YazilacakKumeNo * ZincirBasinaSektor) + SektorNo, 1, Bellek);

      OkumaKonum += j;
      ToplamYazilacakVeriU -= j;
      DG^.DosyaUzunlugu := DG^.DosyaUzunlugu + j;

      if((SektorVeriU + j) = 512) then
      begin

        Inc(SektorNo);
        SektorNo := SektorNo mod 4;
        if(SektorNo = 0) then
        begin

          YeniKumeNo := SHTBosKumeTahsisEt(@DI^.MD);
          if(YeniKumeNo < HATA_YOK) then
          begin

            SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'SHTBosKumeTahsisEt.HataKodu1: %d', [YeniKumeNo]);
            FreeMem(Bellek, 512 * ZincirBasinaSektor);
            DI^.Gorev^.DosyaSonIslemDurum := YeniKumeNo;
            Exit;
          end;

          SHTKumeyiBirOncekiKumeyeBagla(@DI^.MD, YazilacakKumeNo, YeniKumeNo);
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
      DI^.MD.FD^.SektorYaz(DI^.MD.FD, (YazilacakKumeNo * ZincirBasinaSektor) + SektorNo, i, Bellek);

      OkumaKonum += j;
      ToplamYazilacakVeriU -= j;
      DG^.DosyaUzunlugu := DG^.DosyaUzunlugu + j;

      if(ToplamYazilacakVeriU > 0) then
      begin

        YeniKumeNo := SHTBosKumeTahsisEt(@DI^.MD);
        if(YeniKumeNo < HATA_YOK) then
        begin

          SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'SHTBosKumeTahsisEt.HataKodu2: %d', [YeniKumeNo]);
          FreeMem(Bellek, 512 * ZincirBasinaSektor);
          DI^.Gorev^.DosyaSonIslemDurum := YeniKumeNo;
          Exit;
        end;

        SHTKumeyiBirOncekiKumeyeBagla(@DI^.MD, YazilacakKumeNo, YeniKumeNo);
        YazilacakKumeNo := YeniKumeNo;
      end;
    end;

  until ToplamYazilacakVeriU = 0;

  FreeMem(Bellek, 512 * ZincirBasinaSektor);

  if(SHTyeYazilacakKumeNo > 0) then DG^.BaslangicKumeNo := SHTyeYazilacakKumeNo;

  // aktif tarih / saat bilgilerini al
  TarihAl(Gun, Ay, Yil, HG);
  SaatAl(Saat, Dakika, Saniye);

  DG^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
  DG^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);

  // dosyanýn güncel deðerlerini ilgili sektöre yaz
  // alt satýr SektorNo deðiþken içeriði ve vir alt satýr teyit edildin
  SektorNo := (DI^.KumeNo * ZincirBasinaSektor) + DI^.ZincirNo;

  DI^.MD.FD^.SektorYaz(DI^.MD.FD, SektorNo, 1, DI^.TSI);
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
  DI: PDosyaIslem;
  OkunacakSektorSayisi,
  ZincirBasinaSektor,
  KumeNo, VeriU,
  HedefBellekSN: TSayi4;              // toplam okunacak veri uzunluðu
  KopyalanacakVeriUzunlugu,
  SektorIS: TISayi4;
  Bellek: Isaretci;
  DG: PDizinGirdisiELR;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];

  DG := PDizinGirdisiELR(DI^.TSI);
  Inc(DG, DI^.KayitSN);

  VeriU := DG^.DosyaUzunlugu;
  if(VeriU = 0) then Exit;

  //SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Ýlk Zincir: %x', [DosyaKayit^.IlkZincirSektor]);
  //SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Dosya Uzunluk: %d', [OkunacakVeri]);

  KumeNo := DG^.BaslangicKumeNo;

  ZincirBasinaSektor := DI^.MD.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

  GetMem(Bellek, 512 * ZincirBasinaSektor);

  HedefBellekSN := 0;

  repeat

    // okunacak byte'ý sektör sayýsýna çevir
    if(VeriU >= (512 * ZincirBasinaSektor)) then
    begin

      OkunacakSektorSayisi := ZincirBasinaSektor;
      KopyalanacakVeriUzunlugu := 512 * ZincirBasinaSektor;
      VeriU -= (512 * ZincirBasinaSektor);
    end
    else
    begin

      OkunacakSektorSayisi := ((VeriU - 1) div 512) + 1;
      KopyalanacakVeriUzunlugu := VeriU;
      VeriU := 0;
    end;

    //SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Zincir: %d', [i]);

    // sektörü belleðe oku
    SektorIS := DI^.MD.FD^.SektorOku(DI^.MD.FD, KumeNo * ZincirBasinaSektor,
      OkunacakSektorSayisi, Bellek);
    if(SektorIS < HATA_YOK) then
    begin

      DI^.Gorev^.DosyaSonIslemDurum := SektorIS;
      FreeMem(Bellek, 512 * ZincirBasinaSektor);
      Exit;
    end;

    Tasi2(Bellek, AHedefBellek + HedefBellekSN, KopyalanacakVeriUzunlugu);
    HedefBellekSN += KopyalanacakVeriUzunlugu;

    if(VeriU > 0) then KumeNo := SHTBirSonrakiKumeyiAl(@DI^.MD, KumeNo);

  // eðer 0xfff8..0xffff aralýðýndaysa bu dosyanýn en son cluster'idir
  until (KumeNo = ELR_ZD_SON) or (VeriU = 0);

  FreeMem(Bellek, 512 * ZincirBasinaSektor);
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
var
  DI: PDosyaIslem;
  DG: PDizinGirdisiELR;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];

  DG := PDizinGirdisiELR(DI^.TSI);
  Inc(DG, DI^.KayitSN);

  Result := DG^.DosyaUzunlugu;
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

  DosyaIsleminiSonlandir(ADosyaKimlik);
end;

{==============================================================================
  klasör oluþturma iþlevini gerçekleþtirir
 ==============================================================================}
function CreateDir(ADosyaKimlik: TKimlik): Boolean;
var
  DG: PDizinGirdisiELR;
  DI: PDosyaIslem;
  i, ZincirBasinaSektor: TSayi4;
  Gun, Ay, Yil, HG: TSayi2;
  Saat, Dakika, Saniye: TSayi1;
  AramaKaydi: TDosyaArama;
  SektorNo,
  SektorIS: TISayi4;    // sektör iþlem sonucu
begin

  // ilk deðer atamalarý
  Result := False;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];

  // arama iþleminin daha önce oluþturulan dosya kimlik üzerinden devam etmesi için
  // kimlik deðeri arama kaydýna iliþkilendiriliyor
  AramaKaydi.Kimlik := DI^.Kimlik;

  i := dosya.FindFirst(DI^.MD.MD3.AygitAdi + ':\*.*', 0, AramaKaydi, False);
  while i = 0 do
  begin

    if(AramaKaydi.DosyaAdi = DI^.DosyaAdi) {TODO: tip deðerini ekle} then
    begin

      DI^.Gorev^.DosyaSonIslemDurum := HATA_KLASORZATENMEVCUT;
      //dosya.FindClose(AramaKaydi);
      Exit;
    end;

    i := dosya.FindNext(AramaKaydi);
  end;

  ZincirBasinaSektor := DI^.MD.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

  // silinen kayýt varsa silinen kaydýn yerine yeni klasör kaydý oluþtur
  if(DI^.SilinenKayitSN > -1) then
  begin

    DI^.KumeNo := DI^.SilinenKumeNo;
    DI^.ZincirNo := DI^.SilinenZincirNo;
    DI^.KayitSN := DI^.SilinenKayitSN;

    SektorNo := (DI^.KumeNo * ZincirBasinaSektor) + DI^.ZincirNo;

    // dizin giriþ sektörünü oku
    SektorIS := DI^.MD.FD^.SektorOku(DI^.MD.FD, SektorNo, 1, DI^.TSI);
    if(SektorIS < HATA_YOK) then
    begin

      DI^.Gorev^.DosyaSonIslemDurum := SektorIS;
      //dosya.FindClose(AramaKaydi);
      Exit;
    end;
  end;

  // dizin giriþ tablosuna konumlan
  DG := PDizinGirdisiELR(DI^.TSI);
  Inc(DG, DI^.KayitSN);

  if(DI^.KayitSN >= 0) and (DI^.KayitSN < DIZIN_GIRDI_SAYISI) then
  begin

    // aktif tarih / saat bilgilerini al
    TarihAl(Gun, Ay, Yil, HG);
    SaatAl(Saat, Dakika, Saniye);

    // dosya adýný hedef bölgeye kopyala
    DosyaAdiniKopyala(DI^.DosyaAdi, PChar(DG));

    DG^.GirdiTipi := ELR_GT_KLASOR;
    DG^.Ozellikler := ELR_O_NORMAL;
    DG^.OlusturmaTarihi := ELRTarih(Gun, Ay, Yil);
    DG^.OlusturmaSaati := ELRSaat(Saat, Dakika, Saniye);
    DG^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
    DG^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);
    DG^.BaslangicKumeNo := ELR_ZD_SON;
    DG^.DosyaUzunlugu := 0;

    SektorNo := (DI^.KumeNo * ZincirBasinaSektor) + DI^.ZincirNo;

    // aktif dizin giriþinin bulunduðu sektörü güncelle (üzerine yaz)
    SektorIS := DI^.MD.FD^.SektorYaz(DI^.MD.FD, SektorNo, 1, DI^.TSI);
    if(SektorIS < HATA_YOK) then
    begin

      DI^.Gorev^.DosyaSonIslemDurum := SektorIS;
      //dosya.FindClose(AramaKaydi);
      Exit;
    end;

    Result := True;
  end;

  //dosya.FindClose(AramaKaydi);
end;

{==============================================================================
  klasör silme iþlevini gerçekleþtirir
 ==============================================================================}
function RemoveDir(const ADosyaKimlik: TKimlik): Boolean;
var
  DG: PDizinGirdisiELR;
  DI: PDosyaIslem;
  i, ZincirBasinaSektor: TSayi4;
  AramaKaydi: TDosyaArama;
  SektorNo: TISayi4;
begin

  // ilk deðer atamalarý
  Result := False;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];

  // arama iþleminin daha önce oluþturulan dosya kimlik üzerinden devam etmesi için
  // kimlik deðeri arama kaydýna iliþkilendiriliyor
  AramaKaydi.Kimlik := ADosyaKimlik;

  i := dosya.FindFirst(DI^.MD.MD3.AygitAdi + ':\*.*', 0, AramaKaydi, False);
  while i = 0 do
  begin

    if(AramaKaydi.DosyaAdi = DI^.DosyaAdi) and (AramaKaydi.Ozellikler = $10) then
    begin

      //DosyaIslem := Dosyalar0.DosyaIslem[AramaKaydi.Kimlik];

      // dizin giriþ tablosuna konumlan
      DG := PDizinGirdisiELR(DI^.TSI);
      Inc(DG, DI^.KayitSN);

      // klasörü silindi olarak iþaretle
      DG^.Ozellikler := ELR_O_SILINMIS;

      ZincirBasinaSektor := DI^.MD.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

      SektorNo := (DI^.KumeNo * ZincirBasinaSektor) + DI^.ZincirNo;

      // aktif dizin giriþinin bulunduðu sektörü güncelle (üzerine yaz)
      DI^.MD.FD^.SektorYaz(DI^.MD.FD, SektorNo, 1, DI^.TSI);

      dosya.FindClose(AramaKaydi);

      Exit(True);
    end;

    i := dosya.FindNext(AramaKaydi);
  end;

  dosya.FindClose(AramaKaydi);

  Result := False;
end;

{==============================================================================
  dosya silme iþlevini gerçekleþtirir
 ==============================================================================}
function DeleteFile(const ADosyaKimlik: TKimlik): Boolean;
var
  DG: PDizinGirdisiELR;
  DI: PDosyaIslem;
  DosyaAdi: string;
  KumeNo, i, ZincirNo,
  ZincirBasinaSektor: TSayi4;
  TumGirislerOkundu,
  DosyaBulundu: Boolean;
  SektorNo: TSayi4;
begin

  // ilk deðer atamalarý
  Result := False;

  DosyaBulundu := False;

  TumGirislerOkundu := False;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];

  ZincirBasinaSektor := DI^.MD.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;
  KumeNo := DI^.MD.Acilis.DizinGirisi.IlkSektor div ZincirBasinaSektor;

  SektorNo := -1;
  DI^.KayitSN := -1;
  ZincirNo := 0;

  repeat

    if(DI^.KayitSN = -1) then
    begin

      SektorNo := (KumeNo * ZincirBasinaSektor) + ZincirNo;

      // dizin giriþ sektörünü oku
      DI^.MD.FD^.SektorOku(DI^.MD.FD, SektorNo, 1, DI^.TSI);

      DI^.KayitSN := 0;
    end;

    // dizin giriþ tablosuna konumlan
    DG := PDizinGirdisiELR(DI^.TSI);
    Inc(DG, DI^.KayitSN);

    // dosya giriþinin ilk karakteri #0 ise tüm giriþler okunmuþ demektir
    if(DG^.DosyaAdi[0] = #00) then
    begin

      TumGirislerOkundu := True;
    end
    else
    begin

      DosyaAdi := ELRDosyaAdiniAl(DG);

      // dosya ad kontrolü
      if(DG^.GirdiTipi = ELR_GT_DOSYA) and (DosyaAdi = DI^.DosyaAdi) then
      begin

        DosyaBulundu := True;
        TumGirislerOkundu := True;
      end;
    end;

    if not(TumGirislerOkundu) then
    begin

      // bir sonraki girdiye konumlan
      Inc(DI^.KayitSN);
      if(DI^.KayitSN = DIZIN_GIRDI_SAYISI) then
      begin

        // yeni sektörün okunmasý için KayitSN deðiþkenini -1 olarak ayarla
        DI^.KayitSN := -1;

        Inc(ZincirNo);
        if(ZincirNo = ZincirBasinaSektor) then
        begin

          i := SHTBirSonrakiKumeyiAl(@DI^.MD, KumeNo);
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
    DI^.MD.FD^.SektorYaz(DI^.MD.FD, SektorNo, 1, DI^.TSI);

    Result := True;

  end else Result := False;
end;

{==============================================================================
  dizin giriþinden ilgili bilgileri alýr
 ==============================================================================}
function DizinGirdisiOku(ADizinGirisi: PDizinGirisi; AAranacakDeger: string;
  var ADosyaArama: TDosyaArama): TSayi4;
var
  DG: PDizinGirdisiELR;
  TumGirislerOkundu: Boolean;
  DI: PDosyaIslem;
  ZincirBasinaSektor: TSayi1;
  i: TSayi4;
  YeniKumeNo, SektorNo: TISayi4;
begin

  // 0 = bir sonraki girdi mevcut, 1 = tüm girdiler okundu
  Result := 1;

  ADosyaArama.DosyaAdi := '';

  // ilk deðer atamalarý
  TumGirislerOkundu := False;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaArama.Kimlik];

  ZincirBasinaSektor := DI^.MD.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

  if(DI^.KumeNo = -1) then
  begin

    DI^.KumeNo := DI^.MD.Acilis.DizinGirisi.IlkSektor div ZincirBasinaSektor;
    DI^.ZincirNo := 0;
    DI^.KayitSN := -1;

    //SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'Ýlk Küme->Sektör No: %x', [DosyaIslem^.KumeNo*4]);
  end;

  repeat

    // bir sonraki girdiye konumlan
    Inc(DI^.KayitSN);
    if(DI^.KayitSN = DIZIN_GIRDI_SAYISI) then
    begin

      // yeni sektörün okunmasý için KayitSN deðiþkenini 0 olarak ayarla
      DI^.KayitSN := 0;

      Inc(DI^.ZincirNo);
      if(DI^.ZincirNo = ZincirBasinaSektor) then
      begin

        DI^.ZincirNo := 0;

        i := SHTBirSonrakiKumeyiAl(@DI^.MD, DI^.KumeNo);

        //SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'SHTBirSonrakiKume: %x', [i]);

        if(i = ELR_ZD_SON) then
        begin

          YeniKumeNo := SHTBosKumeTahsisEt(@DI^.MD);
          if(YeniKumeNo < HATA_YOK) then
          begin

            //SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'Boþ Küme->Sektör No: %x', [YeniKumeNo*4]);

            TumGirislerOkundu := True;
            Result := 1;
            Exit;
          end;

          SHTKumeyiBirOncekiKumeyeBagla(@DI^.MD, DI^.KumeNo, YeniKumeNo);
          DI^.KumeNo := YeniKumeNo;

        end else DI^.KumeNo := i;

        //SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'Küme->Sektör No: %x', [DI^.KumeNo]);

      end;
    end; // else Inc(DG);

    if(DI^.KayitSN = 0) then
    begin

      SektorNo := (DI^.KumeNo * ZincirBasinaSektor) + DI^.ZincirNo;

      // dizin giriþ sektörünü oku
      DI^.MD.FD^.SektorOku(DI^.MD.FD, SektorNo, 1, DI^.TSI);
    end;

    // dosya giriþ tablosuna konumlan
    DG := PDizinGirdisiELR(DI^.TSI);
    Inc(DG, DI^.KayitSN);

    // dosya giriþinin ilk karakteri #0 ise giriþler okunmuþ demektir
    if(DG^.DosyaAdi[0] = #00) then
    begin

      Result := 1;
      TumGirislerOkundu := True;
    end
    // silinmiþ dosya / klasör
    else if(DG^.Ozellikler = ELR_O_SILINMIS) then
    begin

      // listeleme aþamasýnda silinen ilk kayýt bilgileri klasör oluþturma
      // iþlemi için kaydediliyor
      if(DI^.SilinenKumeNo = -1) then
      begin

        DI^.SilinenKumeNo := DI^.KumeNo;
        DI^.SilinenZincirNo := DI^.ZincirNo;
        DI^.SilinenKayitSN := DI^.KayitSN;
      end;

      // bir sonraki giriþle devam et
    end
    else
    begin

      ADosyaArama.DosyaAdi := ELRDosyaAdiniAl(DG);
      if(DG^.GirdiTipi = ELR_GT_KLASOR) then
        ADosyaArama.Ozellikler := $10     { TODO - çekirdek ve uygulama alanýnda yapýlandýr }
      else ADosyaArama.Ozellikler := 0;
      ADosyaArama.OlusturmaTarihi := DG^.OlusturmaTarihi;
      ADosyaArama.OlusturmaSaati := DG^.OlusturmaSaati;
      ADosyaArama.SonErisimTarihi := 0;
      ADosyaArama.SonDegisimTarihi := DG^.DegisimTarihi;
      ADosyaArama.SonDegisimSaati := DG^.DegisimSaati;

      // dosya uzunluðu ve cluster baþlangýcýný geri dönüþ deðerine ekle
      ADosyaArama.DosyaUzunlugu := DG^.DosyaUzunlugu;
      ADosyaArama.BaslangicKumeNo := DG^.BaslangicKumeNo;

      Result := 0;
      TumGirislerOkundu := True;
    end;

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
procedure ELR1DiskBicimle(AMDNesne: PMDNesne);
begin

  ELR1VerileriSil(AMDNesne);

  // dosya içerik tablosunu oluþtur
  ELR1SHTOlustur(AMDNesne, 256, 1280, 1536);
end;

{==============================================================================
  dosya sisteminin veri alanýndaki mevcut verileri siler
 ==============================================================================}
procedure ELR1VerileriSil(AMDNesne: PMDNesne);
var
  FD: PFDNesne;
  Bellek: Isaretci;
  KumeNo, i: TSayi4;
begin

  GetMem(Bellek, 4 * 512);

  // dosya tablosunu oluþtur
  FillChar(Bellek^, 4 * 512, 0);

  FD := AMDNesne^.FD;

  KumeNo := 384;      // küme no: 384, sektör no: 1536 veya $600

  // 10 küme * 4 sektör içeriðini sil
  for i := 0 to 9 do
  begin

    FD^.SektorYaz(FD, (KumeNo + i) * 4, 4, Bellek);
  end;

  FreeMem(Bellek, 4 * 512);
end;

{==============================================================================
  dosya sistemi sektör harita tablosunu oluþturur
 ==============================================================================}
procedure ELR1SHTOlustur(AMDNesne: PMDNesne; AIlkSektor, AToplamSektor,
 AAyrilanSektor: TSayi4);
var
  Bellek: Isaretci;
  FD: PFDNesne;
  i, j: TSayi4;
begin

  { TODO - burada katý kodlama uygulanmýþtýr, kodlar kontrol edilecektir }

  GetMem(Bellek, 512);

  // sht için ayrýlan sektörleri sýfýrla
  FillChar(Bellek^, 512, 0);
  FD := AMDNesne^.FD;

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
function SHTBosKumeTahsisEt(AMDNesne: PMDNesne): TISayi4;
var
  Bellek: Isaretci;
  FD: PFDNesne;
  KumeNo, i, j: TSayi4;
  Deger: PSayi4;
  HataDurumu: TISayi4;
begin

  GetMem(Bellek, 512);

  // tüm sektörler dolu
  KumeNo := 0;

  FD := AMDNesne^.FD;

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
function SHTBosKumeSerbestBirak(AMDNesne: PMDNesne; AKumeNo: TSayi4): Boolean;
var
  Bellek: Isaretci;
  FD: PFDNesne;
  SektorNo, SiraNo: TSayi4;
  Deger: PSayi4;
begin

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'SHTBosKumeSerbestBirak: %d', [AKumeNo]);

  GetMem(Bellek, 512);

  // konumlanýlacak sektör numarasý
  SektorNo := AKumeNo div 128;
  SiraNo := AKumeNo mod 128;

  FD := AMDNesne^.FD;

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
function SHTKumeyiBirOncekiKumeyeBagla(AMDNesne: PMDNesne; ABirOncekiKumeNo,
 AKumeNo: TSayi4): Boolean;
var
  Bellek: Isaretci;
  FD: PFDNesne;
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

  FD := AMDNesne^.FD;

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
function SHTBirSonrakiKumeyiAl(AMDNesne: PMDNesne; AKumeNo: TSayi4): TSayi4;
var
  Bellek: Isaretci;
  FD: PFDNesne;
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

  FD := AMDNesne^.FD;

  FD^.SektorOku(FD, 256 + SektorNo, 1, Bellek);

  Deger := Bellek;
  Inc(Deger, SiraNo);
  Result := Deger^;

  FreeMem(Bellek, 512);
end;

{==============================================================================
  sektör olarak depolama aygýtý kullanýlan toplam kapasiteyi hesaplar
 ==============================================================================}
function SHTToplamKullanim(AMDNesne: PMDNesne): TSayi4;
var
  Bellek: Isaretci;
  FD: PFDNesne;
  i, j, KullanilanSektor: TSayi4;
  Deger: PSayi4;
begin

  Bellek := GetMem(512);

  // tüm sektörler dolu
  KullanilanSektor := 0;

  FD := AMDNesne^.FD;

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

procedure DosyaAdiniKopyala(ADosyaAdi: string; AHedef: PChar);
var
  i: TSayi4;
begin

  FillChar(AHedef^, ELR_DOSYA_U, #0);

  AHedef[0] := Char(Length(ADosyaAdi));

  for i := 1 to Length(ADosyaAdi) do AHedef[i] := ADosyaAdi[i];
end;

procedure SistemKlasorleriniOlustur;
var
  KlasorAdi: string;
  Durum: Boolean;

  procedure Olustur;
  var
    AG: PGorev;
  begin

    Durum := dosya.CreateDir(KlasorAdi);
    if not(Durum) then
    begin

      AG := GorevAl;
      SISTEM_MESAJ(mtHata, RENK_KIRMIZI, '%s klasörü oluþturulamýyor: %d',
        [KlasorAdi, AG^.DosyaSonIslemDurum]);
    end;
  end;
begin

  KlasorAdi := 'disk2:\progrmlr';
  Olustur;
  KlasorAdi := 'disk2:\resimler';
  Olustur;
  KlasorAdi := 'disk2:\belgeler';
  Olustur;
  KlasorAdi := 'disk2:\gecici';
  Olustur;
  KlasorAdi := 'disk2:\kisiler';
  Olustur;
  KlasorAdi := 'disk2:\suruculr';
  Olustur;
  KlasorAdi := 'disk2:\kodlar';
  Olustur;
end;

procedure SistemKlasorleriniSil;
var
  Durum: Boolean;
begin

  Durum := dosya.RemoveDir('disk2:\progrmlr');
  Durum := dosya.RemoveDir('disk2:\resimler');
  Durum := dosya.RemoveDir('disk2:\belgeler');
  Durum := dosya.RemoveDir('disk2:\gecici');
  Durum := dosya.RemoveDir('disk2:\kisiler');
  Durum := dosya.RemoveDir('disk2:\suruculr');
  Durum := dosya.RemoveDir('disk2:\kodlar');
end;

end.
