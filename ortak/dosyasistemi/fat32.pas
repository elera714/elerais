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

function BirSonrakiKumeyiAl(ADosyaKimlik: TKimlik; var AKumeNo: TISayi4): Boolean;
function KokGirdisiListele32(AAranacakDeger: string; var ADosyaArama: TDosyaArama): TSayi4;
function KokGirdisindeAra32(ADosyaIslem: PDosya; AAranacakDeger: string): TSayi4;
function DizinGirdisiListele32(AAranacakDeger: string; var ADosyaArama: TDosyaArama): TSayi4;
function DizinGirisindeAra32(ADosyaIslem: PDosya; AAranacakDeger: string): TSayi4;

implementation

uses donusum, sistemmesaj, gercekbellek;

{==============================================================================
  dosya arama iþlevini baþlatýr
  uyarý: iþlev SADECE dosya.pas tarafýndan çaðrýlmalýdýr!
 ==============================================================================}
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
 var ADosyaArama: TDosyaArama): TISayi4;
var
  D: TDosya;
begin

  UzunDosyaAdi[0] := #0;
  UzunDosyaAdi[1] := #0;

  D := GDosyalar.DosyaListesi[ADosyaArama.Kimlik];
  D.Aranan := AAramaSuzgec;

  case D.KlasorDerinlik of
    0: Result := KokGirdisiListele32(AAramaSuzgec, ADosyaArama);
    else Result := DizinGirdisiListele32(AAramaSuzgec, ADosyaArama);
  end;
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

  case D.KlasorDerinlik of
    0: Result := KokGirdisiListele32(Aranan, ADosyaArama);
    else Result := DizinGirdisiListele32(Aranan, ADosyaArama);
  end;
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
begin

  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat32.ReWrite iþlevi yazýlacak', []);
end;

{==============================================================================
  dosyaya veri eklemek için dosya açma iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure Append(ADosyaKimlik: TKimlik);
begin

  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat12.Append iþlevi yazýlacak', []);
end;

{==============================================================================
  dosyayý okumadan önce ön hazýrlýk iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure Reset(ADosyaKimlik: TKimlik);
var
  D: TDosya;
  DosyaArama: TDosyaArama;
  TamAramaYolu: string;
  Bulundu,
  AramaTamamlandi: Boolean;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaKimlik];
  if(D = nil) then
  begin

    D.Gorev^.DosyaSonIslemDurum := HATA_KIMLIK;
    Exit;
  end;

  // en son iþlem hatalý ise çýk
  if(D.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  // tam dosya adýný al
  TamAramaYolu := D.MD.MD3.AygitAdi + ':' + D.Klasor + '*.*';

  // arama iþleminin daha önce oluþturulan dosya kimlik üzerinden devam etmesi için
  // kimlik deðeri arama kaydýna iliþkilendiriliyor
  DosyaArama.Kimlik := D.Kimlik;

  // dosyayý dosya tablosunda bul
  Bulundu := False;
  AramaTamamlandi := False;
  if(dosya.FindFirst(TamAramaYolu, 0, DosyaArama, False) = 0) then
  begin

    repeat

      AramaTamamlandi := dosya.FindNext(DosyaArama) = 1;
      if(DosyaArama.DosyaAdi = D.DosyaAdi) then Bulundu := True;

    until (Bulundu) or (AramaTamamlandi);

    //dosya.FindClose(DosyaArama);
  end;

  // dosyanýn BULUNAMAMASI halinde
  if not(Bulundu) then D.Gorev^.DosyaSonIslemDurum := HATA_DOSYA_MEVCUTDEGIL;
end;

{==============================================================================
  dosyaya veri yazma iþlemini gerçekleþtirir
 ==============================================================================}
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
begin

  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat32.Write iþlevi yazýlacak', []);
end;

{==============================================================================
  verinin sonuna #13#10 ekleyerek dosyaya veri yazma iþlemini gerçekleþtirir
 ==============================================================================}
procedure WriteLn(ADosyaKimlik: TKimlik; AVeri: string);
begin

  Write(ADosyaKimlik, AVeri + #13#10);
end;

{==============================================================================
  dosya okuma iþlemini gerçekleþtirir
 ==============================================================================}
procedure Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci);
var
  D: TDosya;
  DG: PDizinGirdisi;
  YeniKumeSN, OkunacakFAT,
  KumeNo, Sonuc: TISayi4;
  KBS, KopyalanacakVeriUzunlugu,
  VeriU, i: TSayi4;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaKimlik];
  if(D = nil) then Exit;

  // en son iþlem hatalý ise çýk
  if(D.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  DG := PDizinGirdisi(D.TSI + D.SektorIciKonum);

  VeriU := DG^.DosyaUzunlugu;
  if(VeriU = 0) then Exit;

  KumeNo := DG^.BaslangicKumeNo;

  KBS := D.MD.Acilis.DosyaAyirmaTablosu.KBS;

  // FAT tablosu için bellekte yer ayýr
  GetMem(D.BellekSHT, 512);

  // okunacak sektör için bellek ayýr
  GetMem(D.Bellek2, KBS * 512);

  repeat

    // okunacak veri miktarý
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

    // okunacak küme numarasý
    i := (KumeNo - 2) * KBS;

    Sonuc := D.MD.FD.SektorOku(@D.MD.FD, D.MD.Acilis.IlkVeriSektorNo + i, KBS, D.Bellek2);
    if(Sonuc = HATA_YOK) then
    begin

      Tasi2(D.Bellek2, AHedefBellek, KopyalanacakVeriUzunlugu);

      // okunacak bilginin yerleþtirileceði bir sonraki adresi belirle
      AHedefBellek := AHedefBellek + KopyalanacakVeriUzunlugu;

      OkunacakFAT := (KumeNo * 4) div 512;

      // mantýksal depolama aygýtýnýn ilgili FAT sektörünü belleðe yükle
      Sonuc := D.MD.FD.SektorOku(@D.MD.FD, D.MD.Acilis.DosyaAyirmaTablosu.IlkSektor +
        OkunacakFAT, 1, D.BellekSHT);
      if(Sonuc = HATA_YOK) then
      begin

        // küme deðerini 4 ile çarp ve bir sonraki küme deðerini al
        YeniKumeSN := (KumeNo * 4) mod 512;
        KumeNo := PSayi4(D.BellekSHT + YeniKumeSN)^;
      end;
    end;

  // eðer 0xfff8..0xffff aralýðýndaysa bu dosyanýn en son cluster'idir
  until (KumeNo >= $0FFFFFF8) or (Sonuc <> HATA_YOK) or (VeriU = 0);

  // kullanýlan bellekleri serbest býrak
  FreeMem(D.Bellek2, KBS * 512);

  FreeMem(D.BellekSHT, 512);
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
  DG: PDizinGirdisi;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaKimlik];
  if(D = nil) then
  begin

    D.Gorev^.DosyaSonIslemDurum := HATA_KIMLIK;
    Exit(-1);
  end;

  // en son iþlem hatalý ise çýk
  if(D.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit(-1);

  DG := PDizinGirdisi(D.TSI + D.SektorIciKonum);

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
end;

{==============================================================================
  klasör oluþturma iþlevini gerçekleþtirir
 ==============================================================================}
function CreateDir(ADosyaKimlik: TKimlik): Boolean;
begin

  Result := False;
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat32.CreateDir iþlevi yazýlacak', []);
end;

{==============================================================================
  klasör silme iþlevini gerçekleþtirir
 ==============================================================================}
function RemoveDir(ADosyaKimlik: TKimlik): Boolean;
begin

  Result := False;
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat32.RemoveDir iþlevi yazýlacak', []);
end;

{==============================================================================
  dosya silme iþlevini gerçekleþtirir
 ==============================================================================}
function DeleteFile(ADosyaKimlik: TKimlik): Boolean;
begin

  Result := False;
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat32.DeleteFile iþlevi yazýlacak', []);
end;

{==============================================================================
  kümeye baðlý bir sonraki kümeyi alýr
  baþarý = Result = True, hata = Result = False
 ==============================================================================}
function BirSonrakiKumeyiAl(ADosyaKimlik: TKimlik; var AKumeNo: TISayi4): Boolean;
var
  D: TDosya;
  Sonuc: TISayi4;
  i: TSayi4;
begin

  Result := True;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaKimlik];
  if(D = nil) then Exit(False);

  // fat'in 1. kopyasý belleðe yüklenmemiþse ilk FAT kopyasýnýn tümünü belleðe yükle
  //if(DI^.BellekSHTDurum = False) then
  begin

    GetMem(D.BellekSHT, 512);

    i := (AKumeNo * 4) div 512;

    Sonuc := D.MD.FD.SektorOku(@D.MD.FD, D.MD.Acilis.DosyaAyirmaTablosu.IlkSektor +
      i, 1, D.BellekSHT);

    if(Sonuc <> HATA_YOK) then Exit(False);
  end;

  // DI^.Durum1 = sektörler belleðe yüklendi
  //DI^.BellekSHTDurum := True;

  // zincir deðerini 4 ile çarp ve bir sonraki zincir deðerini al
  i := (AKumeNo * 4) mod 512;
  AKumeNo := PISayi4(D.BellekSHT + i)^;

  FreeMem(D.BellekSHT, 512);
end;

{==============================================================================
  dizin giriþinden ilgili bilgileri alýr
 ==============================================================================}
function KokGirdisiListele32(AAranacakDeger: string; var ADosyaArama: TDosyaArama): TSayi4;
var
  D: TDosya;
  DizinGirdisi: PDizinGirdisi;
  TumGirislerOkundu,
  UzunDosyaAdiBulundu: Boolean;
  i: TISayi4;
  j: TSayi4;
  KBS: TSayi1;
begin

  // Result = 0 = dosya - dizin girdisi okundu,
  // Result = 1 = dosya - dizin girdisi okunamadý, mevcut deðil, tamamlandý
  Result := 1;

  ADosyaArama.DosyaAdi := '';

  // ilk deðer atamalarý
  TumGirislerOkundu := False;

  UzunDosyaAdiBulundu := False;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaArama.Kimlik];

  //SISTEM_MESAJ(mtBilgi, RENK_MOR, 'DI^.SektorKumeNo: %d', [DI^.SektorKumeNo]);

  KBS := D.MD.Acilis.DosyaAyirmaTablosu.KBS;

  // aramaya baþla
  repeat

    // bir sonraki girdiye konumlan
    Inc(D.SektorIciKonum, 32);

    if(D.SektorIciKonum >= 512) then //16) then
    begin

      D.SektorIciKonum := 0;
      Inc(D.ZincirNo);

      if(D.ZincirNo >= KBS) then
      begin

        // yeni küme numarasý al
        D.ZincirNo := 0;

        if not(BirSonrakiKumeyiAl(D.Kimlik, D.SektorKumeNo)) then Exit(1);
      end;
    end;

    if(D.SektorIciKonum = 0) then
    begin

      // bir sonraki dizin giriþini oku
      j := D.MD.Acilis.IlkVeriSektorNo;
      j := j + ((D.SektorKumeNo - 2) * KBS);
      j := j + D.ZincirNo;

      if(D.MD.FD.SektorOku(@D.MD.FD, j, 1, D.TSI) <> HATA_YOK) then Exit(1);
    end;

    // dosya giriþ tablosuna konumlan
    DizinGirdisi := PDizinGirdisi(D.TSI + D.SektorIciKonum);

    // dosya giriþinin ilk karakteri #0 ise giriþler okunmuþ demektir
    if(DizinGirdisi^.DosyaAdi[0] = #00) then
    begin

      // Result := 1 -> tüm giriþler okundu, baþka giriþ yok
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

      // Result := 1 -> tüm giriþler okundu, baþka giriþ olabilir
      Result := 0;
      TumGirislerOkundu := True;
    end;

  until TumGirislerOkundu;
end;

{==============================================================================
  kök dizin giriþinden dosya / klasör bulur ve geriye ilgili giriþin küme
  numarasýný döndürür
 ==============================================================================}
function KokGirdisindeAra32(ADosyaIslem: PDosya; AAranacakDeger: string): TSayi4;
var
  DA: TDosyaArama;
  Sonuc: TSayi4;
begin

  DA.Kimlik := ADosyaIslem^.Kimlik;

  // aramaya baþla
  repeat

    Sonuc := KokGirdisiListele32('', DA);
    if(Sonuc = 0) then
    begin

      // dosya / klasör bulunduysa küme baþlangýç deðerini geri döndür
      if(DA.DosyaAdi = AAranacakDeger) then Exit(DA.BaslangicKumeNo);
    end else Exit(0);

  until True = False;
end;

{==============================================================================
  dizin giriþinden ilgili bilgileri alýr
 ==============================================================================}
function DizinGirdisiListele32(AAranacakDeger: string; var ADosyaArama: TDosyaArama): TSayi4;
var
  D: TDosya;
  DizinGirdisi: PDizinGirdisi;
  TumGirislerOkundu,
  UzunDosyaAdiBulundu: Boolean;
  i: TISayi4;
  j: TSayi4;
  KBS: TSayi1;
begin

  // Result = 0 = dosya - dizin girdisi okundu,
  // Result = 1 = dosya - dizin girdisi okunamadý, mevcut deðil, tamamlandý
  Result := 1;

  ADosyaArama.DosyaAdi := '';

  // ilk deðer atamalarý
  TumGirislerOkundu := False;

  UzunDosyaAdiBulundu := False;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  D := GDosyalar.DosyaListesi[ADosyaArama.Kimlik];

  KBS := D.MD.Acilis.DosyaAyirmaTablosu.KBS;

  //SISTEM_MESAJ(mtBilgi, RENK_MOR, 'DizinGirdisiListele32: %d', [DI^.SektorKumeNo]);

  // aramaya baþla
  repeat

    // bir sonraki girdiye konumlan
    Inc(D.SektorIciKonum, 32);

    if(D.SektorIciKonum >= 512) then //16) then
    begin

      D.SektorIciKonum := 0;
      Inc(D.ZincirNo);

      if(D.ZincirNo >= KBS) then
      begin

        // yeni küme numarasý al
        D.ZincirNo := 0;

        if not(BirSonrakiKumeyiAl(D.Kimlik, D.SektorKumeNo)) then Exit(1);
      end;
    end;

    if(D.SektorIciKonum = 0) then
    begin

      // bir sonraki dizin giriþini oku
      j := D.MD.Acilis.IlkVeriSektorNo;
      j := j + ((D.SektorKumeNo - 2) * KBS);
      j := j + D.ZincirNo;

      if(D.MD.FD.SektorOku(@D.MD.FD, j, 1, D.TSI) <> HATA_YOK) then Exit(1);
    end;

    // dosya giriþ tablosuna konumlan
    DizinGirdisi := PDizinGirdisi(D.TSI + D.SektorIciKonum);

    // dosya giriþinin ilk karakteri #0 ise giriþler okunmuþ demektir
    if(DizinGirdisi^.DosyaAdi[0] = #00) then
    begin

      // Result := 1 -> tüm giriþler okundu, baþka giriþ yok
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

      // Result := 1 -> tüm giriþler okundu, baþka giriþ olabilir
      Result := 0;
      TumGirislerOkundu := True;
    end;

  until TumGirislerOkundu;
end;

{==============================================================================
  dizin giriþinden dosya / klasör bilgilerini bulup, geriye ilgili giriþin küme
  numarasýný döndürür
 ==============================================================================}
function DizinGirisindeAra32(ADosyaIslem: PDosya; AAranacakDeger: string): TSayi4;
var
  DA: TDosyaArama;
  Sonuc: TSayi4;
begin

  DA.Kimlik := ADosyaIslem^.Kimlik;

  // aramaya baþla
  repeat

    Sonuc := DizinGirdisiListele32('', DA);
    if(Sonuc = 0) then
    begin

      // dosya / klasör bulunduysa küme baþlangýç deðerini geri döndür
      if(DA.DosyaAdi = AAranacakDeger) then Exit(DA.BaslangicKumeNo);
    end else Exit(0);

  until True = False;
end;

end.
