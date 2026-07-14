{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: fat12.pas
  Dosya Ýþlevi: fat12 dosya sistem yönetim iþlevlerini yönetir

  Güncelleme Tarihi: 30/01/2025

 ==============================================================================}
{$mode objfpc}
unit fat12;

interface

uses paylasim, gorev, fdepolama, mdepolama;

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

function BirSonrakiKumeyiAl(ADosyaKimlik: TKimlik; var AKumeNo: TSayi2): Boolean;
function KokGirdisiListele12(AAranacakDeger: string; var ADosyaArama: TDosyaArama): TSayi4;
function KokGirdisindeAra12(ADosyaKimlik: TKimlik; AAranacakDeger: string): TSayi4;
function DizinGirdisiListele12(AAranacakDeger: string; var ADosyaArama: TDosyaArama): TSayi4;
function DizinGirisindeAra12(ADosyaKimlik: TKimlik; AAranacakDeger: string): TSayi4;

implementation

uses genel, gercekbellek, sistemmesaj, fat32, src_com, dosya, islevler, donusum;

{==============================================================================
  dosya arama iþlevini baþlatýr
  uyarý: iþlev SADECE dosya.pas tarafýndan çaðrýlmalýdýr!
 ==============================================================================}
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
  var ADosyaArama: TDosyaArama): TISayi4;
var
  DI: PDosyaIslem;
begin

  DI := Dosyalar0.DosyaIslem[ADosyaArama.Kimlik];
  DI^.Aranan := AAramaSuzgec;

  case DI^.KlasorDerinlik of
    0: Result := KokGirdisiListele12(AAramaSuzgec, ADosyaArama);
    else Result := DizinGirdisiListele12(AAramaSuzgec, ADosyaArama);
  end;
end;

{==============================================================================
  dosya arama iþlemine devam eder
  uyarý: iþlev SADECE dosya.pas tarafýndan çaðrýlmalýdýr!
 ==============================================================================}
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
var
  Aranan: string;
  DI: PDosyaIslem;
begin

  DI := Dosyalar0.DosyaIslem[ADosyaArama.Kimlik];
  Aranan := DI^.Aranan;

  case DI^.KlasorDerinlik of
    0: Result := KokGirdisiListele12(Aranan, ADosyaArama);
    else Result := DizinGirdisiListele12(Aranan, ADosyaArama);
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

  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat12.ReWrite iþlevi yazýlacak', []);
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
  DI: PDosyaIslem;
  DosyaArama: TDosyaArama;
  TamAramaYolu: string;
  Bulundu: Boolean;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];
  if(DI = nil) then
  begin

    DI^.Gorev^.DosyaSonIslemDurum := HATA_KIMLIK;
    Exit;
  end;

  // en son iþlem hatalý ise çýk
  if(DI^.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  // tam dosya adýný al
  TamAramaYolu := DI^.MD.MD3.AygitAdi + ':' + DI^.Klasor + '*.*';

  // dosyayý dosya tablosunda bul
  Bulundu := False;
  if(FindFirst(TamAramaYolu, 0, DosyaArama) = 0) then
  begin

    repeat

      if(DosyaArama.DosyaAdi = DI^.DosyaAdi) then Bulundu := True;
    until (Bulundu) or (FindNext(DosyaArama) <> 0);

    //FindClose(DosyaArama);
  end;

  // dosyanýn BULUNAMAMASI halinde
  if not(Bulundu) then DI^.Gorev^.DosyaSonIslemDurum := HATA_DOSYA_MEVCUTDEGIL;
end;

{==============================================================================
  dosyaya veri yazma iþlemini gerçekleþtirir
 ==============================================================================}
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
begin

  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat12.Write iþlevi yazýlacak', []);
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
  DI: PDosyaIslem;
  Zincir: TSayi2;
  i: TSayi2;
  OkumaSonuc, VeriU,
  OkunacakSektorSayisi,
  KopyalanacakVeriUzunlugu,
  ZincirBasinaSektor: TSayi4;
  DG: PDizinGirdisi;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];
  if(DI = nil) then Exit;

  // en son iþlem hatalý ise çýk
  if(DI^.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  DG := PDizinGirdisi(DI^.TSI + DI^.SektorIciKonum);

  VeriU := DG^.DosyaUzunlugu;
  if(VeriU = 0) then Exit;

  Zincir := DG^.BaslangicKumeNo;

  ZincirBasinaSektor := DI^.MD.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

  OkumaSonuc := 1;

  repeat

    // okunacak byte'ý sektör sayýsýna çevir
    OkunacakSektorSayisi := ZincirBasinaSektor;
    if(VeriU >= (ZincirBasinaSektor * 512)) then
    begin

      KopyalanacakVeriUzunlugu := ZincirBasinaSektor * 512;
      VeriU := VeriU - KopyalanacakVeriUzunlugu;
    end
    else
    begin

      KopyalanacakVeriUzunlugu := VeriU;
      VeriU := 0;
    end;

    // okunacak sektör zincir numarasý
    i := (Zincir - 2) * DI^.MD.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

    // sektörü belleðe oku
    GetMem(DI^.Bellek2, OkunacakSektorSayisi * 512);

    if(DI^.MD.FD^.SektorOku(DI^.MD.FD, i + DI^.MD.Acilis.IlkVeriSektorNo,
      ZincirBasinaSektor, DI^.Bellek2) = HATA_YOK) then
    begin

      Tasi2(DI^.Bellek2, AHedefBellek, KopyalanacakVeriUzunlugu);

      // okunacak bilginin yerleþtirileceði bir sonraki adresi belirle
      AHedefBellek := AHedefBellek + (ZincirBasinaSektor * 512);

      if not(BirSonrakiKumeyiAl(ADosyaKimlik, Zincir)) then Exit;

      VeriU := VeriU - (ZincirBasinaSektor * 512);
      if(ZincirBasinaSektor <= 0) then OkumaSonuc := 0;
    end;

    FreeMem(DI^.Bellek2, OkunacakSektorSayisi * 512);

  // eðer 0xFF8..0xFFF aralýðýndaysa bu dosyanýn en son zinciridir
  until (Zincir >= $FF8) or (OkumaSonuc = 0);

  // Bellek1 bullanýlmýþsa serbest belleði býrak
  if(DI^.BellekSHTDurum) then
  begin

    FreeMem(DI^.BellekSHT, DI^.MD.Acilis.DosyaAyirmaTablosu.ToplamSektor * 512);
    DI^.BellekSHTDurum := False;
  end;
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
  DG: PDizinGirdisi;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];
  if(DI = nil) then
  begin

    DI^.Gorev^.DosyaSonIslemDurum := HATA_KIMLIK;
    Exit(-1);
  end;

  // en son iþlem hatalý ise çýk
  if(DI^.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit(-1);

  DG := PDizinGirdisi(DI^.TSI + DI^.SektorIciKonum);

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
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat12.CreateDir iþlevi yazýlacak', []);
end;

{==============================================================================
  klasör silme iþlevini gerçekleþtirir
 ==============================================================================}
function RemoveDir(ADosyaKimlik: TKimlik): Boolean;
begin

  Result := False;
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat12.RemoveDir iþlevi yazýlacak', []);
end;

{==============================================================================
  dosya silme iþlevini gerçekleþtirir
 ==============================================================================}
function DeleteFile(ADosyaKimlik: TKimlik): Boolean;
begin

  Result := False;
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat12.DeleteFile iþlevi yazýlacak', []);
end;

{==============================================================================
  kümeye baðlý bir sonraki kümeyi alýr
  baþarý = Result = True, hata = Result = False
 ==============================================================================}
function BirSonrakiKumeyiAl(ADosyaKimlik: TKimlik; var AKumeNo: TSayi2): Boolean;
var
  DI: PDosyaIslem;
  BellekSN: TSayi4;
  Sonuc: TISayi4;
  i: TSayi2;
begin

  Result := True;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];
  if(DI = nil) then Exit(False);

  // fat'in 1. kopyasý belleðe yüklenmemiþse ilk FAT kopyasýnýn tümünü belleðe yükle
  if(DI^.BellekSHTDurum = False) then
  begin

    GetMem(DI^.BellekSHT, DI^.MD.Acilis.DosyaAyirmaTablosu.ToplamSektor * 512);

    Sonuc := DI^.MD.FD^.SektorOku(DI^.MD.FD, DI^.MD.Acilis.DosyaAyirmaTablosu.IlkSektor,
      DI^.MD.Acilis.DosyaAyirmaTablosu.ToplamSektor, DI^.BellekSHT);

    if(Sonuc <> HATA_YOK) then Exit(False);
  end;

  // DI^.Durum1 = sektörler belleðe yüklendi
  DI^.BellekSHTDurum := True;

  // zincir deðerini 1.5 ile çarp ve bir sonraki zincir deðerini al
  BellekSN := (AKumeNo shr 1) + AKumeNo + TSayi4(DI^.BellekSHT);
  i := PSayi2(BellekSN)^;

   if((AKumeNo and 1) = 1) then
     i := i shr 4
   else i := i and $FFF;

   AKumeNo := i;
end;

{==============================================================================
  dizin giriþinden ilgili bilgileri alýr
 ==============================================================================}
function KokGirdisiListele12(AAranacakDeger: string; var ADosyaArama: TDosyaArama): TSayi4;
var
  DizinGirdisi: PDizinGirdisi;
  TumGirislerOkundu,
  UzunDosyaAdiBulundu: Boolean;
  DI: PDosyaIslem;
  ZincirBasinaSektor: TSayi4;
  Sonuc: TISayi4;
begin

  // Result = 0 = dosya - dizin girdisi okundu,
  // Result = 1 = dosya - dizin girdisi okunamadý, mevcut deðil, tamamlandý
  Result := 1;

  ADosyaArama.DosyaAdi := '';

  // ilk deðer atamalarý
  TumGirislerOkundu := False;

  UzunDosyaAdiBulundu := False;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaArama.Kimlik];

  ZincirBasinaSektor := DI^.DizinGirisi.ToplamKokSektor;

  // aramaya baþla
  repeat

    // bir sonraki girdiye konumlan
    Inc(DI^.SektorIciKonum, 32);

    if(DI^.SektorIciKonum >= 512) then
    begin

      DI^.SektorIciKonum := 0;
      Inc(DI^.ZincirNo);
      if(DI^.ZincirNo >= ZincirBasinaSektor) then Exit(1);
    end;

    if(DI^.SektorIciKonum = 0) then
    begin

      // bir sonraki dizin giriþini oku
      Sonuc := DI^.MD.FD^.SektorOku(DI^.MD.FD, DI^.SektorKumeNo + DI^.ZincirNo, 1, DI^.TSI);
      if(Sonuc <> HATA_YOK) then Exit(1);
    end;

    // dosya giriþ tablosuna konumlan
    DizinGirdisi := PDizinGirdisi(DI^.TSI + DI^.SektorIciKonum);

    // dosya giriþinin ilk karakteri #0 ise giriþler okunmuþ demektir
    if(DizinGirdisi^.DosyaAdi[0] = #00) then
    begin

      // Result = 1 = dosya - dizin girdisi okunamadý, mevcut deðil, tamamlandý
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

      // Result = 0 = dosya - dizin girdisi okundu,
      Result := 0;
      TumGirislerOkundu := True;
    end;

  until TumGirislerOkundu;
end;

{==============================================================================
  dizin giriþinden dosya / klasör bilgilerini bulup, geriye ilgili giriþin küme
  numarasýný döndürür

  { TODO - bu iþlev (dosya / dizin arama iþlevi) tüm dosya sistemlerinde olacak }
 ==============================================================================}
function KokGirdisindeAra12(ADosyaKimlik: TKimlik; AAranacakDeger: string): TSayi4;
var
  DI: PDosyaIslem;
  MD: PMDNesne;
  DizinGirdisi: PDizinGirdisi;
  UzunDosyaAdiBulundu: Boolean;
  DosyaAdi: string;
  ZincirBasinaSektor: TSayi1;
  i: TSayi4;
  Sonuc: TSayi4;
  DA: TDosyaArama;
begin

  DA.Kimlik := ADosyaKimlik;
  //SISTEM_MESAJ(mtHata, RENK_MAVI, 'DizinGirisindeAra12: %s', [AAranacakDeger]);

  // dosya iþlem yapýsý bellek bölgesine konumlan
{  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];
  if(DI = nil) then
  begin

    DI^.Gorev^.DosyaSonIslemDurum := HATA_KIMLIK;
    Exit;
  end;

  //SISTEM_MESAJ(mtHata, RENK_MAVI, 'ZincirNo: %d', [ADosyaIslem^.ZincirNo]);

  UzunDosyaAdiBulundu := False;

  // aramanýn yapýlacaðý sürücü
  MD := @DI^.MD;

  ZincirBasinaSektor := 14; //MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;
}
  // burada ilk deðer atamalarý olacak

  // aramaya baþla
  repeat

    Sonuc := KokGirdisiListele12('', DA);
    if(Sonuc = 0) then
    begin

      // dosya uzunluðu ve cluster baþlangýcýný geri dönüþ deðerine ekle
      if(DA.DosyaAdi = AAranacakDeger) then Exit(DA.BaslangicKumeNo);
    end else Exit(0);

  until True = False;
end;

function DizinGirdisiListele12(AAranacakDeger: string; var ADosyaArama: TDosyaArama): TSayi4;
var
  DizinGirdisi: PDizinGirdisi;
  TumGirislerOkundu,
  UzunDosyaAdiBulundu: Boolean;
  DI: PDosyaIslem;
  ZincirBasinaSektor, i: TSayi4;
  Sonuc: TISayi4;
  KN: TSayi2;
begin

  // Result = 0 = dosya - dizin girdisi okundu,
  // Result = 1 = dosya - dizin girdisi okunamadý, mevcut deðil, tamamlandý
  Result := 1;

  ADosyaArama.DosyaAdi := '';

  // ilk deðer atamalarý
  TumGirislerOkundu := False;

  UzunDosyaAdiBulundu := False;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaArama.Kimlik];

  //SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'ToplamKokSektor: %d', [DI^.DizinGirisi.ToplamKokSektor]);
  //SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'ZincirBasinaSektor: %d', [DI^.MD.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor]);

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'A: %d', [DI^.MD.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor]);
  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'DI^.DizinGirisi.IlkSektor: %d', [DI^.DizinGirisi.IlkSektor]);
  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'DI^.KumeNo: %d', [DI^.KumeNo]);

  ZincirBasinaSektor := DI^.MD.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;;

  // aramaya baþla
  repeat

    // bir sonraki girdiye konumlan
    Inc(DI^.SektorIciKonum, 32);

    if(DI^.SektorIciKonum >= 512) then
    begin

      DI^.SektorIciKonum := 0;
      Inc(DI^.ZincirNo);

      if(DI^.ZincirNo >= ZincirBasinaSektor) then
      begin

        DI^.ZincirNo := 0;

        KN := DI^.SektorKumeNo;
        if not(BirSonrakiKumeyiAl(ADosyaArama.Kimlik, KN)) then Exit(1);
        DI^.SektorKumeNo := KN;
      end;
    end;

    if(DI^.SektorIciKonum = 0) then
    begin

      i := DI^.MD.Acilis.DizinGirisi.IlkSektor;

      // AyrilmisSektor = zincir deðerine eklenecek deðer
      i := i + DI^.MD.Acilis.DizinGirisi.ToplamSektor;

      i := ((DI^.SektorKumeNo - 2) * DI^.MD.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor) + i;

      // bir sonraki dizin giriþini oku
      Sonuc := DI^.MD.FD^.SektorOku(DI^.MD.FD, i + DI^.ZincirNo, 1, DI^.TSI);
      if(Sonuc <> HATA_YOK) then Exit(1);
    end;

    // dosya giriþ tablosuna konumlan
    DizinGirdisi := PDizinGirdisi(DI^.TSI + DI^.SektorIciKonum);

    // dosya giriþinin ilk karakteri #0 ise giriþler okunmuþ demektir
    if(DizinGirdisi^.DosyaAdi[0] = #00) then
    begin

      // Result = 1 = dosya - dizin girdisi okunamadý, mevcut deðil, tamamlandý
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

      // Result = 0 = dosya - dizin girdisi okundu,
      Result := 0;
      TumGirislerOkundu := True;
    end;

  until TumGirislerOkundu;
end;

function DizinGirisindeAra12(ADosyaKimlik: TKimlik; AAranacakDeger: string): TSayi4;
var
  DI: PDosyaIslem;
  MD: PMDNesne;
  DizinGirdisi: PDizinGirdisi;
  UzunDosyaAdiBulundu: Boolean;
  DosyaAdi: string;
  ZincirBasinaSektor: TSayi1;
  i: TSayi4;
  Sonuc: TSayi4;
  DA: TDosyaArama;
begin

  DA.Kimlik := ADosyaKimlik;
  //SISTEM_MESAJ(mtHata, RENK_MAVI, 'DizinGirisindeAra12: %s', [AAranacakDeger]);

  // dosya iþlem yapýsý bellek bölgesine konumlan
{  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];
  if(DI = nil) then
  begin

    DI^.Gorev^.DosyaSonIslemDurum := HATA_KIMLIK;
    Exit;
  end;

  //SISTEM_MESAJ(mtHata, RENK_MAVI, 'ZincirNo: %d', [ADosyaIslem^.ZincirNo]);

  UzunDosyaAdiBulundu := False;

  // aramanýn yapýlacaðý sürücü
  MD := @DI^.MD;

  ZincirBasinaSektor := 14; //MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;
}
  // burada ilk deðer atamalarý olacak

  // aramaya baþla
  repeat

    Sonuc := KokGirdisiListele12('', DA);
    if(Sonuc = 0) then
    begin

      // dosya uzunluðu ve cluster baþlangýcýný geri dönüþ deðerine ekle
      if(DA.DosyaAdi = AAranacakDeger) then Exit(DA.BaslangicKumeNo);
    end else Exit(0);

  until True = False;
end;

end.
