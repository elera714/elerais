{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: elr1.pas
  Dosya Ýþlevi: ELERA Ýþletim Sistemi'nin dosya sistemi

  Güncelleme Tarihi: 09/07/2026

  Kaynaklar: https://wiki.freepascal.org/File_Handling_In_Pascal

  Disk Kapasitesi: 320MB -> 320 * 1024 * 1024 = 335.544.320 byte
                                                335.544.320 / 512 = 655.360 sektör

  ELR-1 dosya sistem sektör daðýlýmý
    0000..0256: 256 sektör - boþ sektör
    0256..5376: 5120 sektör - sektör harita tablosu (fat) (5120 * 128) = 655.360 sektörü adresleyebilir
    5376..5632: boþ
          5632: 649728 sektör - her türlü veri (dosya adlarý ve içeriði)

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit elr1;

interface

uses paylasim, islevler, gorev, fdepolama, mdepolama;

const
  DIZIN_GIRDI_SAYISI        = TSayi4(8);
  ZINCIRDEKI_SEKTOR_SAYISI  = TSayi4(4);

  { bilgi: aþaðýdaki aralýklarýn sýnýrlarý, bir önceki deðerin bir sonrakine kadar olanýný içerir }
  SEKTORNO_BOOT             = TSayi4(0);
  SEKTORNO_SHT_BAS          = TSayi4(256);      // sektör harita tablosu (fat) baþlangýcý
  SEKTORNO_SHT_SON          = TSayi4(5376);     // sektör harita tablosu (fat) sonu
  SEKTORNO_VERI             = TSayi4(5632);     // dosya adlarý ve verilerini içerir

function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
  var ADosyaArama: TDosyaArama): TISayi4;   { onaylanacak }
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;   { onaylanacak }
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;   { onaylanacak }
procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);   { onaylanacak }
procedure ReWrite(ADosyaKimlik: TKimlik);
procedure Append(ADosyaKimlik: TKimlik);
procedure Reset(ADosyaKimlik: TKimlik);   { onaylanacak }
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);   { onaylanacak }
procedure Write0(ADosyaKimlik: TKimlik; ABellek: Isaretci; AUzunluk: TSayi4);   { onaylanacak }
procedure WriteLn(ADosyaKimlik: TKimlik; AVeri: string);   { onaylanacak }
procedure Write(ADosyaKimlik: TKimlik; ABellekAdresi: Isaretci; AUzunluk: TSayi4);   { onaylanacak }
procedure Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci);
function IOResult: TISayi4;   { onaylanacak }
function FileSize(ADosyaKimlik: TKimlik): TISayi8;   { onaylanacak }
function EOF(ADosyaKimlik: TKimlik): Boolean;   { onaylanacak }
procedure CloseFile(ADosyaKimlik: TKimlik);   { onaylanacak }
function CreateDir(ADosyaKimlik: TKimlik): Boolean;   { onaylanacak }
function RemoveDir(const ADosyaKimlik: TKimlik): Boolean;   { onaylanacak }
function DeleteFile(const ADosyaKimlik: TKimlik): Boolean;   { onaylanacak }

function DizinGirdisiListeleELR1(AAranacakDeger: string;
  var ADosyaArama: TDosyaArama): TSayi4;   { onaylanacak }
function DizinGirisindeAraELR1(ADosyaKimlik: TKimlik; AAranacakDeger: string): TSayi4;

procedure DosyaAdiniKopyala(ADosyaAdi: string; AHedef: PChar);
procedure ELR1DiskBicimle(AMDNesne: PMDNesne);
function ELR1VeriAlaniniSil(AMDNesne: PMDNesne): TISayi4;
function ELR1SHTOlustur(AMDNesne: PMDNesne; AIlkSektor, ASonSektor,
  AAyrilanSektor: TSayi4): TISayi4;

function SHTBosKumeTahsisEt(AMDNesne: PMDNesne): TISayi4;
function SHTKumeSerbestBirak(AMDNesne: PMDNesne; AKumeNo: TSayi4): TISayi4;
function SHTKumeyiBirOncekiKumeyeBagla(AMDNesne: PMDNesne; ABirOncekiKumeNo,
 AKumeNo: TSayi4): TISayi4;
function SHTBirSonrakiKumeyiAl(AMDNesne: PMDNesne; var AKumeNo: TSayi4): Boolean;
function SHTKumeZinciriniSerbestBirak(AMDNesne: PMDNesne; AIlkKumeNo: TSayi4): TISayi4;

function SHTToplamKullanim(AMDNesne: PMDNesne; var AKullanilanSektorSayisi: TSayi4): TISayi4;
procedure SistemKlasorleriniOlustur;   { onaylanacak }
procedure SistemKlasorleriniSil;   { onaylanacak }
function ELRDosyaAdiniAl(ADizinGirdisi: PDizinGirdisiELR): string;   { onaylanacak }

implementation

uses cmos, sistemmesaj, dosya;

{==============================================================================
  dosya arama iþlevini baþlatýr
  uyarý: iþlev SADECE dosya.pas tarafýndan çaðrýlmalýdýr!
 ==============================================================================}
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
 var ADosyaArama: TDosyaArama): TISayi4;
var
  D: TDosya;
begin

  D := GDosyalar.DosyaListesi[ADosyaArama.Kimlik];
  D.Aranan := AAramaSuzgec;
  Result := DizinGirdisiListeleELR1(AAramaSuzgec, ADosyaArama);
end;

{==============================================================================
  dosya arama iþlemine devam eder
  uyarý: iþlev SADECE dosya.pas tarafýndan çaðrýlmalýdýr!
 ==============================================================================}
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
var
  D: TDosya;
  Aranan: string;
begin

  D := GDosyalar.DosyaListesi[ADosyaArama.Kimlik];
  Aranan := D.Aranan;
  Result := DizinGirdisiListeleELR1(Aranan, ADosyaArama);
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
  D: TDosya;
  KBS, i: TSayi4;
  Gun, Ay, Yil, HG: TSayi2;
  Saat, Dakika, Saniye: TSayi1;
  AramaKaydi: TDosyaArama;
  SektorNo, Sonuc: TISayi4;
  DosyaBulundu: Boolean;
begin

  D := GDosyalar.DosyaListesi[ADosyaKimlik];

  // dosya açýk mý? (kapalý olmalý)
  if(D.DosyaDurumu <> ddKapali) then
  begin

    D.Gorev^.DosyaSonIslemDurum := HATA_DOSYA_KULLANIMDA;
    Exit;
  end;

  // ilk deðer atamalarý
  DosyaBulundu := False;

  // arama iþleminin daha önce oluþturulan dosya kimlik üzerinden devam etmesi için
  // kimlik deðeri arama kaydý kimlik deðeriyle iliþkilendiriliyor
  AramaKaydi.Kimlik := D.Kimlik;

  i := dosya.FindFirst(D.MD.MD3.AygitAdi + ':\*.*', 0, AramaKaydi, False);
  while i = 0 do
  begin

    if(AramaKaydi.DosyaAdi = D.DosyaAdi) and (AramaKaydi.Ozellikler = 0) then
    begin

      DosyaBulundu := True;
      Break;
    end;

    i := dosya.FindNext(AramaKaydi);
  end;
  // bilgi: dosya.FindClose iþlemi FileClose iþlemi ile gerçekleþtiriliyor

  KBS := D.MD.Acilis.DosyaAyirmaTablosu.KBS;

  SektorNo := (D.SektorKumeNo * KBS) + D.ZincirNo;

  // dosya oluþturma iþlemi

  // 1. dosyanýn mevcut olmasý durumunda
  if(DosyaBulundu) then
  begin

    DG := PDizinGirdisiELR(D.TSI + D.SektorIciKonum);

    // dosyaya tahsis edilmiþ tüm kümeleri serbest býrak
    Sonuc := SHTKumeZinciriniSerbestBirak(@D.MD, DG^.BaslangicKumeNo);
    if(Sonuc <> HATA_YOK) then
    begin

      SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'ELR1.SHTKumeZinciriniSerbestBirak->Hata Kodu: %d', [Sonuc]);
      Exit;
    end;

    // aktif tarih / saat bilgilerini al
    TarihAl(Gun, Ay, Yil, HG);
    SaatAl(Saat, Dakika, Saniye);

    // güncel veriler aktif dizin / dosya giriþine aktarýlýyor
    DG^.GirdiTipi := ELR_GT_DOSYA;
    DG^.Ozellikler := ELR_O_NORMAL;
    DG^.OlusturmaTarihi := ELRTarih(Gun, Ay, Yil);
    DG^.OlusturmaSaati := ELRSaat(Saat, Dakika, Saniye);
    DG^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
    DG^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);
    DG^.BaslangicKumeNo := ELR_ZD_SON;
    DG^.DosyaUzunlugu := 0;

    // aktif dizin giriþinin bulunduðu sektörü güncelle (üzerine yaz)
    Sonuc := D.MD.FD.SektorYaz(@D.MD.FD, SektorNo, 1, D.TSI);
    if(Sonuc <> HATA_YOK) then
    begin

      SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'ELR1.ReWrite->Hata Kodu: %d', [Sonuc]);
      Exit;
    end;

    // dosya durumunu, "dosya yazým için açýldý" olarak güncelle
    D.DosyaDurumu := ddYazmaIcinAcik;
  end
  else
  // 2. dosyanýn mevcut OLMAMASI durumunda
  begin

    if(D.SektorIciKonum >= 0) and (D.SektorIciKonum < 512) then
    begin

      DG := PDizinGirdisiELR(D.TSI + D.SektorIciKonum);

      // dosya adýný hedef bölgeye kopyala
      DosyaAdiniKopyala(D.DosyaAdi, PChar(DG));

      // aktif tarih / saat bilgilerini al
      TarihAl(Gun, Ay, Yil, HG);
      SaatAl(Saat, Dakika, Saniye);

      // güncel veriler aktif dizin / dosya giriþine aktarýlýyor
      DG^.GirdiTipi := ELR_GT_DOSYA;
      DG^.Ozellikler := ELR_O_NORMAL;
      DG^.OlusturmaTarihi := ELRTarih(Gun, Ay, Yil);
      DG^.OlusturmaSaati := ELRSaat(Saat, Dakika, Saniye);
      DG^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
      DG^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);
      DG^.BaslangicKumeNo := ELR_ZD_SON;
      DG^.DosyaUzunlugu := 0;

      // aktif dizin giriþinin bulunduðu sektörü güncelle (üzerine yaz)
      Sonuc := D.MD.FD.SektorYaz(@D.MD.FD, SektorNo, 1, D.TSI);
      if(Sonuc <> HATA_YOK) then
      begin

        SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'ELR1.ReWrite->Hata Kodu: %d', [Sonuc]);
        Exit;
      end;

      // dosya durumunu, "dosya yazým için açýldý" olarak güncelle
      D.DosyaDurumu := ddYazmaIcinAcik;
    end;
  end;
end;

{==============================================================================
  dosyaya veri eklemek için dosya açma iþlevini gerçekleþtirir
 ==============================================================================}
procedure Append(ADosyaKimlik: TKimlik);
var
  D: TDosya;
  AramaKaydi: TDosyaArama;
  DosyaBulundu: Boolean;
  i: TSayi4;
begin

  D := GDosyalar.DosyaListesi[ADosyaKimlik];

  // dosya açýk mý? (kapalý olmalý)
  if(D.DosyaDurumu <> ddKapali) then
  begin

    D.Gorev^.DosyaSonIslemDurum := HATA_DOSYA_KULLANIMDA;
    Exit;
  end;

  // ilk deðer atamalarý
  DosyaBulundu := False;

  // arama iþleminin daha önce oluþturulan dosya kimlik üzerinden devam etmesi için
  // kimlik deðeri arama kaydý kimlik deðeriyle iliþkilendiriliyor
  AramaKaydi.Kimlik := D.Kimlik;

  i := dosya.FindFirst(D.MD.MD3.AygitAdi + ':\*.*', 0, AramaKaydi, False);
  while i = 0 do
  begin

    if(AramaKaydi.DosyaAdi = D.DosyaAdi) and (AramaKaydi.Ozellikler = 0) then
    begin

      DosyaBulundu := True;
      Break;
    end;

    i := dosya.FindNext(AramaKaydi);
  end;
  // bilgi: dosya.FindClose iþlemi FileClose iþlemi ile gerçekleþtiriliyor

  // dosyanýn bulunmasý halinde dosyanýn durumunu yazma için açýk olarak belirt
  if(DosyaBulundu) then

    D.DosyaDurumu := ddYazmaIcinAcik

  // aksi halde ilgili hata kodunu deðiþkene ata
  else D.Gorev^.DosyaSonIslemDurum := HATA_DOSYA_MEVCUTDEGIL;
end;

{==============================================================================
  dosyayý okumadan önce ön hazýrlýk iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure Reset(ADosyaKimlik: TKimlik);
var
  D: TDosya;
  AramaKaydi: TDosyaArama;
  TamAramaYolu: string;
  Bulundu: Boolean;
  i: TISayi4;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaKimlik];
  if(D = nil) then Exit;

  // en son iþlem hatalý ise çýk
  if(D.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  // tam dosya adýný al
  TamAramaYolu := D.MD.MD3.AygitAdi + ':' + D.Klasor + '*.*';

  // dosyayý dosya tablosunda bul
  Bulundu := False;

  // arama iþleminin daha önce oluþturulan dosya kimlik üzerinden devam etmesi için
  // kimlik deðeri arama kaydýna iliþkilendiriliyor
  AramaKaydi.Kimlik := D.Kimlik;

  i := dosya.FindFirst(D.MD.MD3.AygitAdi + ':\*.*', 0, AramaKaydi, False);
  while i = 0 do
  begin

    {SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'dosya adý1: %s', [AramaKaydi.DosyaAdi]);
    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'dosya adý2: %s', [DI^.DosyaAdi]);}

    if(AramaKaydi.DosyaAdi = D.DosyaAdi) and (AramaKaydi.Ozellikler = 0) then
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
    D.DosyaDurumu := ddOkumaIcinAcik;

  end else D.Gorev^.DosyaSonIslemDurum := HATA_DOSYA_MEVCUTDEGIL;
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
  D: TDosya;
  SHTyeYazilacakKumeNo, YeniKumeNo: TISayi4;
  OncedenYazilanKumeSayisi,
  YazilacakKumeNo: TSayi4;
  SektorNo, i,
  OkumaKonum,
  ToplamYazilacakVeriU,            // toplam yazýlacak veri uzunluðu
  j, SektorVeriU: TSayi4;
  DG: PDizinGirdisiELR;
  Gun, Ay, Yil, HG: TSayi2;
  Saat, Dakika, Saniye, KBS: TSayi1;
  Bellek: Isaretci;
  Sonuc: TISayi4;
begin

  D := GDosyalar.DosyaListesi[ADosyaKimlik];

  // dosya yazma için açýk mý?
  if not(D.DosyaDurumu = ddYazmaIcinAcik) then
  begin

    D.Gorev^.DosyaSonIslemDurum := HATA_DOSYA_YAZILAMIYOR;
    Exit;
  end;

  KBS := D.MD.Acilis.DosyaAyirmaTablosu.KBS;

  DG := PDizinGirdisiELR(D.TSI + D.SektorIciKonum);

  SHTyeYazilacakKumeNo := 0;

  // dosyanýn baþlangýç küeme numarasýný al, olmamasý durumunda yeni bir tane oluþtur
  if(DG^.BaslangicKumeNo = ELR_ZD_SON) then
  begin

    SHTyeYazilacakKumeNo := SHTBosKumeTahsisEt(@D.MD);
    if(SHTyeYazilacakKumeNo < HATA_YOK) then
    begin

      SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'SHTBosKumeTahsisEt.HataKodu: %d', [SHTyeYazilacakKumeNo]);
      D.Gorev^.DosyaSonIslemDurum := SHTyeYazilacakKumeNo;
      Exit;
    end;

    YazilacakKumeNo := SHTyeYazilacakKumeNo;
  end else YazilacakKumeNo := DG^.BaslangicKumeNo;

  ToplamYazilacakVeriU := AUzunluk;

  GetMem(Bellek, 512 * KBS);

  OkumaKonum := 0;

  OncedenYazilanKumeSayisi := (DG^.DosyaUzunlugu div (512 * KBS));

  // dosyaya ekleme yapýlacaksa (önceden veri yazýlmýþsa) en son kümeye konumlan
  if(OncedenYazilanKumeSayisi > 0) then
  begin

    for i := 1 to OncedenYazilanKumeSayisi do
    begin

      if not(SHTBirSonrakiKumeyiAl(@D.MD, YazilacakKumeNo)) then
      begin

        SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'Write0: Bir sonraki kümeyi ayýrma hatasý', []);
        D.Gorev^.DosyaSonIslemDurum := HATA_AYGITAYAZMA;
        Exit;
      end;
    end;
  end;

  repeat

    SektorNo := (DG^.DosyaUzunlugu div 512) mod 4;
    SektorVeriU := (DG^.DosyaUzunlugu mod 512);

    // sektörün bir kýsmýna yazým yapýlmýþsa (ekleme yapýlacaksa), veriyi mevcut
    // veriye ekle ve aygýt sektörüne yaz
    if(SektorVeriU > 0) then
    begin

      FillChar(Bellek^, 512 * KBS, $00);
      if(D.MD.FD.SektorOku(@D.MD.FD, (YazilacakKumeNo * KBS) + SektorNo, 1, Bellek) = HATA_YOK) then
      begin

        j := 512 - SektorVeriU;
        if(j > ToplamYazilacakVeriU) then j := ToplamYazilacakVeriU;
        Tasi2(ABellek + OkumaKonum, Bellek + SektorVeriU, j);
        if(D.MD.FD.SektorYaz(@D.MD.FD, (YazilacakKumeNo * KBS) + SektorNo, 1, Bellek) <> HATA_YOK) then
          SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'ELR1: yazma hatasý3', []);

        OkumaKonum := OkumaKonum + j;
        ToplamYazilacakVeriU := ToplamYazilacakVeriU - j;
        DG^.DosyaUzunlugu := DG^.DosyaUzunlugu + j;

        if((SektorVeriU + j) = 512) then
        begin

          Inc(SektorNo);
          SektorNo := SektorNo mod 4;
          if(SektorNo = 0) then
          begin

            YeniKumeNo := SHTBosKumeTahsisEt(@D.MD);
            if(YeniKumeNo < HATA_YOK) then
            begin

              SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'SHTBosKumeTahsisEt.HataKodu1: %d', [YeniKumeNo]);
              FreeMem(Bellek, 512 * KBS);
              D.Gorev^.DosyaSonIslemDurum := YeniKumeNo;
              Exit;
            end;

            Sonuc := SHTKumeyiBirOncekiKumeyeBagla(@D.MD, YazilacakKumeNo, YeniKumeNo);
            if(Sonuc < HATA_YOK) then
            begin

              SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'SHTKumeyiBirOncekiKumeyeBagla.HataKodu: %d', [Sonuc]);
              FreeMem(Bellek, 512 * KBS);
              Exit;
            end;

            YazilacakKumeNo := YeniKumeNo;
          end;
        end;
      end;
    end;

    // bu aþamada sektörün yarým dolu olmasý mevzu bahis deðildir
    // sektörler baþý itibariyle (sonu deðil) 0'a odaklý olarak yazýlacaktýr
    if(ToplamYazilacakVeriU > 0) then
    begin

      FillChar(Bellek^, 512 * KBS, $00);
      // kaç sektör yazýlacak
      i := 4 - SektorNo;
      // hedef bölgeye kaç byte kopyalanacak
      j := (4 - SektorNo) * 512;
      if(j > ToplamYazilacakVeriU) then j := ToplamYazilacakVeriU;
      Tasi2(ABellek + OkumaKonum, Bellek, j);
      if(D.MD.FD.SektorYaz(@D.MD.FD, (YazilacakKumeNo * KBS) + SektorNo, i, Bellek) <> HATA_YOK) then
        SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'ELR1: yazma hatasý4', []);

      OkumaKonum := OkumaKonum + j;
      ToplamYazilacakVeriU := ToplamYazilacakVeriU - j;
      DG^.DosyaUzunlugu := DG^.DosyaUzunlugu + j;

      if(ToplamYazilacakVeriU > 0) then
      begin

        YeniKumeNo := SHTBosKumeTahsisEt(@D.MD);
        if(YeniKumeNo < HATA_YOK) then
        begin

          SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'SHTBosKumeTahsisEt.HataKodu2: %d', [YeniKumeNo]);
          FreeMem(Bellek, 512 * KBS);
          D.Gorev^.DosyaSonIslemDurum := YeniKumeNo;
          Exit;
        end;

        Sonuc := SHTKumeyiBirOncekiKumeyeBagla(@D.MD, YazilacakKumeNo, YeniKumeNo);
        if(Sonuc < HATA_YOK) then
        begin

          SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'SHTKumeyiBirOncekiKumeyeBagla.HataKodu: %d', [Sonuc]);
          FreeMem(Bellek, 512 * KBS);
          Exit;
        end;

        YazilacakKumeNo := YeniKumeNo;
      end;
    end;

  until ToplamYazilacakVeriU = 0;

  FreeMem(Bellek, 512 * KBS);

  if(SHTyeYazilacakKumeNo > 0) then DG^.BaslangicKumeNo := SHTyeYazilacakKumeNo;

  // aktif tarih / saat bilgilerini al
  TarihAl(Gun, Ay, Yil, HG);
  SaatAl(Saat, Dakika, Saniye);

  DG^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
  DG^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);

  // dosyanýn güncel deðerlerini ilgili sektöre yaz
  // alt satýr SektorNo deðiþken içeriði ve vir alt satýr teyit edildin
  SektorNo := (D.SektorKumeNo * KBS) + D.ZincirNo;

  if(D.MD.FD.SektorYaz(@D.MD.FD, SektorNo, 1, D.TSI) <> HATA_YOK) then
    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'ELR1: yazma hatasý5', []);
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
  DG: PDizinGirdisiELR;
  D: TDosya;
  Bellek: Isaretci;
  OkunacakSektorSayisi,
  KBS,
  KopyalanacakVeriUzunlugu,
  KumeNo, VeriU: TSayi4;
  Sonuc: TISayi4;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaKimlik];

  DG := PDizinGirdisiELR(D.TSI + D.SektorIciKonum);

  VeriU := DG^.DosyaUzunlugu;
  if(VeriU = 0) then Exit;

  KumeNo := DG^.BaslangicKumeNo;

  KBS := D.MD.Acilis.DosyaAyirmaTablosu.KBS;

  GetMem(Bellek, KBS * 512);

  repeat

    // okunacak byte'ý sektör sayýsýna çevir
    OkunacakSektorSayisi := KBS;
    if(VeriU >= (KBS * 512)) then
    begin

      KopyalanacakVeriUzunlugu := KBS * 512;
      VeriU := VeriU - KopyalanacakVeriUzunlugu;
    end
    else
    begin

      KopyalanacakVeriUzunlugu := VeriU;
      VeriU := 0;
    end;

    // sektörü belleðe oku
    Sonuc := D.MD.FD.SektorOku(@D.MD.FD, KumeNo * KBS,
      OkunacakSektorSayisi, Bellek);
    if(Sonuc <> HATA_YOK) then
    begin

      D.Gorev^.DosyaSonIslemDurum := Sonuc;
      FreeMem(Bellek, KBS * 512);
      Exit;
    end;

    Tasi2(Bellek, AHedefBellek, KopyalanacakVeriUzunlugu);
    AHedefBellek := AHedefBellek + KopyalanacakVeriUzunlugu;

    if(VeriU > 0) then
    begin

      if not(SHTBirSonrakiKumeyiAl(@D.MD, KumeNo)) then
      begin

        SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'ELR1.Read: bir sonraki küme alýnamýyor!', []);
        D.Gorev^.DosyaSonIslemDurum := HATA_AYGITSEKTOROKUMA;
        Exit;
      end;
    end;

  // küme deðerinin 0xFFFFFFFF olmasý durumunda tüm veri okunmuþ demektir
  until (KumeNo = ELR_ZD_SON) or (VeriU = 0);

  FreeMem(Bellek, KBS * 512);
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
  D: TDosya;
  DG: PDizinGirdisiELR;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaKimlik];

  DG := PDizinGirdisiELR(D.TSI + D.SektorIciKonum);

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

  GDosyalar.DosyaIsleminiSonlandir(ADosyaKimlik);
end;

{==============================================================================
  klasör oluþturma iþlevini gerçekleþtirir
 ==============================================================================}
function CreateDir(ADosyaKimlik: TKimlik): Boolean;
var
  DG: PDizinGirdisiELR;
  D: TDosya;
  i, KBS: TSayi4;
  Gun, Ay, Yil, HG: TSayi2;
  Saat, Dakika, Saniye: TSayi1;
  AramaKaydi: TDosyaArama;
  SektorNo,
  Sonuc, BosKume: TISayi4;    // sektör iþlem sonucu
begin

  // ilk deðer atamalarý
  Result := False;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaKimlik];

  // arama iþleminin daha önce oluþturulan dosya kimlik üzerinden devam etmesi için
  // kimlik deðeri arama kaydýna iliþkilendiriliyor
  AramaKaydi.Kimlik := D.Kimlik;

  i := dosya.FindFirst(D.MD.MD3.AygitAdi + ':\*.*', 0, AramaKaydi, False);
  while i = 0 do
  begin

    if(AramaKaydi.DosyaAdi = D.DosyaAdi) {TODO: tip deðerini ekle} then
    begin

      D.Gorev^.DosyaSonIslemDurum := HATA_KLASORZATENMEVCUT;
      //dosya.FindClose(AramaKaydi);
      Exit;
    end;

    i := dosya.FindNext(AramaKaydi);
  end;

  KBS := D.MD.Acilis.DosyaAyirmaTablosu.KBS;

  // silinen kayýt varsa silinen kaydýn yerine yeni klasör kaydý oluþtur
  if(D.SilinenKayitSN > -1) then
  begin

    D.SektorKumeNo := D.SilinenKumeNo;
    D.ZincirNo := D.SilinenZincirNo;
    D.SektorIciKonum := D.SilinenKayitSN;

    SektorNo := (D.SektorKumeNo * KBS) + D.ZincirNo;

    // dizin giriþ sektörünü oku
    Sonuc := D.MD.FD.SektorOku(@D.MD.FD, SektorNo, 1, D.TSI);
    if(Sonuc < HATA_YOK) then
    begin

      D.Gorev^.DosyaSonIslemDurum := Sonuc;
      //dosya.FindClose(AramaKaydi);
      Exit;
    end;
  end;

  // dizin giriþ tablosuna konumlan
  DG := PDizinGirdisiELR(D.TSI + D.SektorIciKonum);

  if(D.SektorIciKonum >= 0) and (D.SektorIciKonum < 512) then //DIZIN_GIRDI_SAYISI) then
  begin

    BosKume := SHTBosKumeTahsisEt(@D.MD);
    if(BosKume < 0) then
    begin

      D.Gorev^.DosyaSonIslemDurum := HATA_TUMSEKTORLERDOLU;
      //dosya.FindClose(AramaKaydi);
      Exit;
    end;

    // aktif tarih / saat bilgilerini al
    TarihAl(Gun, Ay, Yil, HG);
    SaatAl(Saat, Dakika, Saniye);

    // dosya adýný hedef bölgeye kopyala
    DosyaAdiniKopyala(D.DosyaAdi, PChar(DG));

    DG^.GirdiTipi := ELR_GT_KLASOR;
    DG^.Ozellikler := ELR_O_NORMAL;
    DG^.OlusturmaTarihi := ELRTarih(Gun, Ay, Yil);
    DG^.OlusturmaSaati := ELRSaat(Saat, Dakika, Saniye);
    DG^.DegisimTarihi := ELRTarih(Gun, Ay, Yil);
    DG^.DegisimSaati := ELRSaat(Saat, Dakika, Saniye);
    DG^.BaslangicKumeNo := BosKume;
    DG^.DosyaUzunlugu := 0;

    SektorNo := (D.SektorKumeNo * KBS) + D.ZincirNo;

    // aktif dizin giriþinin bulunduðu sektörü güncelle (üzerine yaz)
    Sonuc := D.MD.FD.SektorYaz(@D.MD.FD, SektorNo, 1, D.TSI);
    if(Sonuc < HATA_YOK) then
    begin

      D.Gorev^.DosyaSonIslemDurum := Sonuc;
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
  D: TDosya;
  i, KBS: TSayi4;
  AramaKaydi: TDosyaArama;
  SektorNo: TISayi4;
begin

  // ilk deðer atamalarý
  Result := False;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaKimlik];

  // arama iþleminin daha önce oluþturulan dosya kimlik üzerinden devam etmesi için
  // kimlik deðeri arama kaydýna iliþkilendiriliyor
  AramaKaydi.Kimlik := ADosyaKimlik;

  i := dosya.FindFirst(D.MD.MD3.AygitAdi + ':\*.*', 0, AramaKaydi, False);
  while i = 0 do
  begin

    if(AramaKaydi.DosyaAdi = D.DosyaAdi) and (AramaKaydi.Ozellikler = $10) then
    begin

      //DosyaIslem := Dosyalar0.DosyaIslem[AramaKaydi.Kimlik];

      // dizin giriþ tablosuna konumlan
      DG := PDizinGirdisiELR(D.TSI + D.SektorIciKonum);

      // klasörü silindi olarak iþaretle
      DG^.Ozellikler := ELR_O_SILINMIS;

      KBS := D.MD.Acilis.DosyaAyirmaTablosu.KBS;

      SektorNo := (D.SektorKumeNo * KBS) + D.ZincirNo;

      // aktif dizin giriþinin bulunduðu sektörü güncelle (üzerine yaz)
      if(D.MD.FD.SektorYaz(@D.MD.FD, SektorNo, 1, D.TSI) <> HATA_YOK) then
        SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'ELR1: yazma hatasý21', []);

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
  D: TDosya;
  DosyaAdi: string;
  KumeNo, i, ZincirNo,
  KBS: TSayi4;
  TumGirislerOkundu,
  DosyaBulundu: Boolean;
  SektorNo: TSayi4;
begin

  // ilk deðer atamalarý
  Result := False;

  DosyaBulundu := False;

  TumGirislerOkundu := False;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaKimlik];

  KBS := D.MD.Acilis.DosyaAyirmaTablosu.KBS;
  KumeNo := D.MD.Acilis.DizinGirisi.IlkSektor div KBS;

  SektorNo := -1;
  D.SektorIciKonum := -1;
  ZincirNo := 0;

  repeat

    if(D.SektorIciKonum = -1) then
    begin

      SektorNo := (KumeNo * KBS) + ZincirNo;

      // dizin giriþ sektörünü oku
      if(D.MD.FD.SektorOku(@D.MD.FD, SektorNo, 1, D.TSI) = HATA_YOK) then
        D.SektorIciKonum := 0
      else SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ELR1: dosya okuma hatasý', []);
    end;

    // dizin giriþ tablosuna konumlan
    DG := PDizinGirdisiELR(D.TSI + D.SektorIciKonum);

    // dosya giriþinin ilk karakteri #0 ise tüm giriþler okunmuþ demektir
    if(DG^.DosyaAdi[0] = #00) then
    begin

      TumGirislerOkundu := True;
    end
    else
    begin

      DosyaAdi := ELRDosyaAdiniAl(DG);

      // dosya ad kontrolü
      if(DG^.GirdiTipi = ELR_GT_DOSYA) and (DosyaAdi = D.DosyaAdi) then
      begin

        DosyaBulundu := True;
        TumGirislerOkundu := True;
      end;
    end;

    if not(TumGirislerOkundu) then
    begin

      // bir sonraki girdiye konumlan
      Inc(D.SektorIciKonum, 64);
      if(D.SektorIciKonum >= 512) then //DIZIN_GIRDI_SAYISI) then
      begin

        // yeni sektörün okunmasý için SektorIciKonum deðiþkenini -1 olarak ayarla
        D.SektorIciKonum := -1;

        Inc(ZincirNo);
        if(ZincirNo = KBS) then
        begin

          if not(SHTBirSonrakiKumeyiAl(@D.MD, KumeNo)) then
          begin

            SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'DeleteFile: Bir sonraki kümeyi ayýrma hatasý', []);
            D.Gorev^.DosyaSonIslemDurum := HATA_AYGITAYAZMA;
            Exit(False);
          end;

          if(KumeNo = ELR_ZD_SON) then Exit(False);

          //KumeNo := i;
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
    if(D.MD.FD.SektorYaz(@D.MD.FD, SektorNo, 1, D.TSI) <> HATA_YOK) then
      SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'ELR1: yazma hatasý7', []);

    Result := True;

  end else Result := False;
end;

{==============================================================================
  dizin giriþinden ilgili bilgileri alýr
 ==============================================================================}
function DizinGirdisiListeleELR1(AAranacakDeger: string;
  var ADosyaArama: TDosyaArama): TSayi4;
var
  DG: PDizinGirdisiELR;
  TumGirislerOkundu: Boolean;
  D: TDosya;
  KBS: TSayi1;
  i: TSayi4;
  SektorNo: TISayi4;
begin

  // 0 = bir sonraki girdi mevcut, 1 = tüm girdiler okundu
  Result := 1;

  ADosyaArama.DosyaAdi := '';

  // ilk deðer atamalarý
  TumGirislerOkundu := False;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaArama.Kimlik];

  KBS := D.MD.Acilis.DosyaAyirmaTablosu.KBS;

  repeat

    // bir sonraki girdiye konumlan
    Inc(D.SektorIciKonum, 64);
    if(D.SektorIciKonum >= 512) then //DIZIN_GIRDI_SAYISI) then
    begin

      // yeni sektörün okunmasý için KayitSN deðiþkenini 0 olarak ayarla
      D.SektorIciKonum := 0;

      Inc(D.ZincirNo);
      if(D.ZincirNo >= KBS) then
      begin

        D.ZincirNo := 0;

        i := D.SektorKumeNo;
        if not(SHTBirSonrakiKumeyiAl(@D.MD, i)) then
        begin

          SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'DizinGirdisiOku: Bir sonraki kümeyi ayýrma hatasý', []);
          D.Gorev^.DosyaSonIslemDurum := HATA_AYGITAYAZMA;
          Exit(1);
        {end;

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

          Sonuc := SHTKumeyiBirOncekiKumeyeBagla(@DI^.MD, DI^.SektorKumeNo, YeniKumeNo);
          if(Sonuc < HATA_YOK) then
          begin

            SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'SHTKumeyiBirOncekiKumeyeBagla.HataKodu: %d', [Sonuc]);
            Exit;
          end;

          DI^.SektorKumeNo := YeniKumeNo;
            }
        end else D.SektorKumeNo := i;

      end;
    end; // else Inc(DG);

    if(D.SektorIciKonum = 0) then
    begin

      SektorNo := (D.SektorKumeNo * KBS) + D.ZincirNo;

      // dizin giriþ sektörünü oku
      if(D.MD.FD.SektorOku(@D.MD.FD, SektorNo, 1, D.TSI) <> HATA_YOK) then
        SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ELR1: dosya okuma hatasý2', []);
    end;

    // dosya giriþ tablosuna konumlan
    DG := PDizinGirdisiELR(D.TSI + D.SektorIciKonum);

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
      if(D.SilinenKumeNo = -1) then
      begin

        D.SilinenKumeNo := D.SektorKumeNo;
        D.SilinenZincirNo := D.ZincirNo;
        D.SilinenKayitSN := D.SektorIciKonum;
      end;

      // bir sonraki giriþle devam et
    end
    else if(DG^.GirdiTipi = ELR_GT_KLASOR) or (DG^.GirdiTipi = ELR_GT_DOSYA) then
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
    end
    else
    begin

      Result := 1;
      TumGirislerOkundu := True;
    end;

  until TumGirislerOkundu;
end;

{==============================================================================
  dizin giriþinden ilgili bilgileri alýr
 ==============================================================================}
function DizinGirisindeAraELR1(ADosyaKimlik: TKimlik; AAranacakDeger: string): TSayi4;
var
  DA: TDosyaArama;
  Sonuc: TSayi4;
begin

  DA.Kimlik := ADosyaKimlik;
  //SISTEM_MESAJ(mtHata, RENK_MAVI, 'DizinGirisindeAra12: %s', [AAranacakDeger]);

  // aramaya baþla
  repeat

    Sonuc := DizinGirdisiListeleELR1('', DA);
    if(Sonuc = 0) then
    begin

      // dosya uzunluðu ve cluster baþlangýcýný geri dönüþ deðerine ekle
      if(DA.DosyaAdi = AAranacakDeger) then Exit(DA.BaslangicKumeNo);
    end else Exit(0);

  until True = False;
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
var
  Sonuc: TISayi4;
begin

  // dosya sisteminin veri alanýný sil
  Sonuc := ELR1VeriAlaniniSil(AMDNesne);
  if(Sonuc <> HATA_YOK) then
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'ELR1VeriAlaniniSil hata kodu: %d', [Sonuc]);
    Exit;
  end;

  // dosya içerik tablosunu oluþtur
  Sonuc := ELR1SHTOlustur(AMDNesne, SEKTORNO_SHT_BAS, SEKTORNO_SHT_SON, SEKTORNO_VERI);
  if(Sonuc <> HATA_YOK) then
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'ELR1SHTOlustur hata kodu: %d', [Sonuc]);
    Exit;
  end;
end;

{==============================================================================
  dosya sisteminin veri alanýndaki mevcut verilerini siler
 ==============================================================================}
function ELR1VeriAlaniniSil(AMDNesne: PMDNesne): TISayi4;
var
  FD: TFDNesne;
  Bellek: Isaretci;
  KumeNo, i: TSayi4;
  Sonuc: TISayi4;
begin

  Result := HATA_YOK;

  GetMem(Bellek, 4 * 512);

  // bellek içeriðini sýfýrla
  FillChar(Bellek^, 4 * 512, $00);

  FD := AMDNesne^.FD;

  // sektör numarasý küme numarasýna çevriliyor
  // bilgi: þu aþamada her bir küme 4 sektörden oluþmakta
  KumeNo := SEKTORNO_VERI div 4;

  // 10 küme * 4 sektör içeriðini sil
  for i := 0 to 9 do
  begin

    Sonuc := FD.SektorYaz(@FD, (KumeNo + i) * 4, 4, Bellek);
    if(Sonuc <> HATA_YOK) then
    begin

      FreeMem(Bellek, 4 * 512);
      Exit(Sonuc);
    end;
  end;

  FreeMem(Bellek, 4 * 512);
end;

{==============================================================================
  dosya sistemi sektör harita tablosunu oluþturur
 ==============================================================================}
function ELR1SHTOlustur(AMDNesne: PMDNesne; AIlkSektor, ASonSektor,
  AAyrilanSektor: TSayi4): TISayi4;
var
  FD: TFDNesne;
  Bellek: Isaretci;
  i, j: TSayi4;
  Sonuc: TISayi4;
begin

  Result := HATA_YOK;

  GetMem(Bellek, 512);

  // sht için ayrýlan sektörleri sýfýrla
  FillChar(Bellek^, 512, $00);
  FD := AMDNesne^.FD;

  for i := AIlkSektor to ASonSektor - 1 do
  begin

    Sonuc := FD.SektorYaz(@FD, i, 1, Bellek);
    if(Sonuc <> HATA_YOK) then
    begin

      FreeMem(Bellek, 512);
      Exit(Sonuc);
    end;
  end;

  // ayrýlan sektörleri ayrýlmýþ olarak iþaretle
  // her bir sektör 512 / 4 = 128 adet girdi içeriyor

  // ayrýlan sektör sayýsýný küme numarasýna çevir (her küme 4 sektör)
  j := AAyrilanSektor div 4;

  // ayrýlan sektörler için gerekli sektör sayýsý
  j := j div (512 div 4);

  FillChar(Bellek^, 512, $FF);

  for i := AIlkSektor to (AIlkSektor + j) - 1 do
  begin

    Sonuc := FD.SektorYaz(@FD, i, 1, Bellek);
    if(Sonuc <> HATA_YOK) then
    begin

      FreeMem(Bellek, 512);
      Exit(Sonuc);
    end;
  end;

  // ayrýlan sektörlerden sonraki ilk sektörü ana kök dizin giriþine ayýr
  FillChar(Bellek^, 512, $00);
  PSayi4(Bellek)^ := $FFFFFFFF;

  Sonuc := FD.SektorYaz(@FD, AIlkSektor + j, 1, Bellek);
  if(Sonuc <> HATA_YOK) then
  begin

    FreeMem(Bellek, 512);
    Exit(Sonuc);
  end;

  FreeMem(Bellek, 512);
end;

{==============================================================================
  sektör harita tablosundan boþ küme numarasý alýr
  baþarý = Result >= 0, hata = Result < 0
 ==============================================================================}
function SHTBosKumeTahsisEt(AMDNesne: PMDNesne): TISayi4;
var
  FD: TFDNesne;
  Bellek: Isaretci;
  KumeNo, i, j: TSayi4;
  Deger: PSayi4;
  Sonuc: TISayi4;
begin

  Result := HATA_TUMSEKTORLERDOLU;

  GetMem(Bellek, 512);

  KumeNo := 0;

  FD := AMDNesne^.FD;

  for i := SEKTORNO_SHT_BAS to SEKTORNO_SHT_SON - 1 do
  begin

    Sonuc := FD.SektorOku(@FD, i, 1, Bellek);
    if(Sonuc <> HATA_YOK) then
    begin

      FreeMem(Bellek, 512);
      Exit(Sonuc);
    end;

    Deger := Bellek;
    for j := 0 to 128 - 1 do
    begin

      if(Deger^ = $00000000) then
      begin

        // bir sonraki sektörü sonlanmýþ olarak iþaretle
        Deger^ := ELR_ZD_SON;
        Sonuc := FD.SektorYaz(@FD, i, 1, Bellek);
        if(Sonuc <> HATA_YOK) then
        begin

          FreeMem(Bellek, 512);
          Exit(Sonuc);
        end;

        FreeMem(Bellek, 512);
        Exit(KumeNo);
      end;

      Inc(KumeNo);
      Inc(Deger);
    end;
  end;

  FreeMem(Bellek, 512);
end;

{==============================================================================
  sektör harita tablosundan alýnan sektör kümesini serbest býrakýr
  baþarý = Result >= 0, hata = Result < 0
 ==============================================================================}
function SHTKumeSerbestBirak(AMDNesne: PMDNesne; AKumeNo: TSayi4): TISayi4;
var
  FD: TFDNesne;
  Bellek: Isaretci;
  SektorNo, SiraNo: TSayi4;
  Sonuc: TISayi4;
  Deger: PSayi4;
begin

  Result := AKumeNo;

  GetMem(Bellek, 512);

  // konumlanýlacak sektör ve sýra numarasý
  SektorNo := AKumeNo div 128;
  SiraNo := AKumeNo mod 128;

  FD := AMDNesne^.FD;

  Sonuc := FD.SektorOku(@FD, SEKTORNO_SHT_BAS + SektorNo, 1, Bellek);
  if(Sonuc <> HATA_YOK) then
  begin

    FreeMem(Bellek, 512);
    Exit(Sonuc);
  end;

  Deger := Bellek;
  Inc(Deger, SiraNo);
  if(Deger^ = ELR_ZD_SON) then
  begin

    Deger^ := $00000000;
    Sonuc := FD.SektorYaz(@FD, SEKTORNO_SHT_BAS + SektorNo, 1, Bellek);
    if(Sonuc <> HATA_YOK) then
    begin

      FreeMem(Bellek, 512);
      Exit(Sonuc);
    end;

    FreeMem(Bellek, 512);
    Exit;
  end;

  FreeMem(Bellek, 512);

  Result := HATA_BILINMIYOR;
end;

{==============================================================================
  kümeyi bir önceki kümeye baðlar
  baþarý = Result = 0, hata = Result < 0
 ==============================================================================}
function SHTKumeyiBirOncekiKumeyeBagla(AMDNesne: PMDNesne; ABirOncekiKumeNo,
 AKumeNo: TSayi4): TISayi4;
var
  FD: TFDNesne;
  Bellek: Isaretci;
  SektorNo, SiraNo: TSayi4;
  Sonuc: TISayi4;
  Deger: PSayi4;
begin

  Result := HATA_YOK;

  GetMem(Bellek, 512);

  // konumlanýlacak sektör ve sýra numarasý
  SektorNo := ABirOncekiKumeNo div 128;
  SiraNo := ABirOncekiKumeNo mod 128;

  FD := AMDNesne^.FD;

  Sonuc := FD.SektorOku(@FD, SEKTORNO_SHT_BAS + SektorNo, 1, Bellek);
  if(Sonuc <> HATA_YOK) then
  begin

    FreeMem(Bellek, 512);
    Exit(Sonuc);
  end;

  Deger := Bellek;
  Inc(Deger, SiraNo);
  Deger^ := AKumeNo;

  Sonuc := FD.SektorYaz(@FD, SEKTORNO_SHT_BAS + SektorNo, 1, Bellek);
  if(Sonuc <> HATA_YOK) then
  begin

    FreeMem(Bellek, 512);
    Exit(Sonuc);
  end;

  FreeMem(Bellek, 512);
end;

{==============================================================================
  kümeye baðlý bir sonraki kümeyi alýr
  baþarý = Result = True, hata = Result = False
 ==============================================================================}
function SHTBirSonrakiKumeyiAl(AMDNesne: PMDNesne; var AKumeNo: TSayi4): Boolean;
var
  Bellek: Isaretci;
  FD: TFDNesne;
  SektorNo, SiraNo: TSayi4;
  Sonuc: TISayi4;
  Deger: PSayi4;
begin

  Result := True;

  Bellek := GetMem(512);

  // konumlanýlacak sektör ve sýra numarasý
  SektorNo := AKumeNo div 128;
  SiraNo := AKumeNo mod 128;

  FD := AMDNesne^.FD;

  Sonuc := FD.SektorOku(@FD, SEKTORNO_SHT_BAS + SektorNo, 1, Bellek);
  if(Sonuc = HATA_YOK) then
  begin

    Deger := Bellek;
    Inc(Deger, SiraNo);
    AKumeNo := Deger^;
  end
  else
  begin

    AKumeNo := 0;
    Result := False;
  end;

  FreeMem(Bellek, 512);
end;

{==============================================================================
  sektör harita tablosundan dosya için tahsis edilen küme numara zincirini serbest býrakýr
  baþarý = Result = 0, hata = Result <> 0
 ==============================================================================}
function SHTKumeZinciriniSerbestBirak(AMDNesne: PMDNesne; AIlkKumeNo: TSayi4): TISayi4;
var
  FD: TFDNesne;
  Bellek: Isaretci;
  SektorNo, SiraNo,
  KumeNo: TSayi4;
  Sonuc: TISayi4;
  Deger: PSayi4;
begin

  Result := HATA_YOK;

  KumeNo := AIlkKumeNo;

  FD := AMDNesne^.FD;

  GetMem(Bellek, 512);

  repeat

    // konumlanýlacak sektör ve sýra numarasý
    SektorNo := KumeNo div 128;
    SiraNo := KumeNo mod 128;

    Sonuc := FD.SektorOku(@FD, SEKTORNO_SHT_BAS + SektorNo, 1, Bellek);
    if(Sonuc <> HATA_YOK) then
    begin

      FreeMem(Bellek, 512);
      Exit(Sonuc);
    end;

    Deger := Bellek;
    Inc(Deger, SiraNo);
    KumeNo := Deger^;
    if(Deger^ <> $00000000) then
    begin

      Deger^ := $00000000;
      Sonuc := FD.SektorYaz(@FD, SEKTORNO_SHT_BAS + SektorNo, 1, Bellek);
      if(Sonuc <> HATA_YOK) then
      begin

        FreeMem(Bellek, 512);
        Exit(Sonuc);
      end;
    end;

  until KumeNo = $FFFFFFFF;

  FreeMem(Bellek, 512);
end;

{==============================================================================
  sektör olarak depolama aygýtý kullanýlan toplam kapasiteyi hesaplar
 ==============================================================================}
function SHTToplamKullanim(AMDNesne: PMDNesne; var AKullanilanSektorSayisi: TSayi4): TISayi4;
var
  FD: TFDNesne;
  Bellek: Isaretci;
  i, j: TSayi4;
  Deger: PSayi4;
begin

  Result := HATA_YOK;

  AKullanilanSektorSayisi := 0;

  Bellek := GetMem(512);
  if(Bellek = nil) then Exit(HATA_BELLEKYOK);

  FD := AMDNesne^.FD;

  for i := SEKTORNO_SHT_BAS to SEKTORNO_SHT_SON - 1 do
  begin

    Result := FD.SektorOku(@FD, i, 1, Bellek);
    if(Result <> HATA_YOK) then Break;

    Deger := Bellek;

    // bilgi: her bir girdi 4 byte
    for j := 0 to 128 - 1 do
    begin

      if(Deger^ <> 0) then Inc(AKullanilanSektorSayisi);
      Inc(Deger);
    end;
  end;

  FreeMem(Bellek, 512);

  if(Result = HATA_YOK) then
    AKullanilanSektorSayisi := AKullanilanSektorSayisi * ZINCIRDEKI_SEKTOR_SAYISI
  else AKullanilanSektorSayisi := 0;
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
  KlasorAdi := 'disk2:\kisiler';
  Olustur;
  KlasorAdi := 'disk2:\suruculr';
  Olustur;
  KlasorAdi := 'disk2:\kodlar';
  Olustur;
  KlasorAdi := 'disk2:\kayitlar';
  Olustur;
  KlasorAdi := 'disk2:\gecici';
  Olustur;
end;

procedure SistemKlasorleriniSil;
var
  Durum: Boolean;
begin

  Durum := dosya.RemoveDir('disk2:\progrmlr');
  Durum := dosya.RemoveDir('disk2:\resimler');
  Durum := dosya.RemoveDir('disk2:\belgeler');
  Durum := dosya.RemoveDir('disk2:\kisiler');
  Durum := dosya.RemoveDir('disk2:\suruculr');
  Durum := dosya.RemoveDir('disk2:\kodlar');
  Durum := dosya.RemoveDir('disk2:\kayitlar');
  Durum := dosya.RemoveDir('disk2:\gecici');
end;

end.
