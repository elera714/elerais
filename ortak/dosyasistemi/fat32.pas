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

function DizinGirdisiOku(AAranacakDeger: string; var ADosyaArama: TDosyaArama): TSayi4;
function DizinGirisindeAra(var ADosyaIslem: PDosyaIslem; AAranacakDeger: string): TSayi4;

implementation

uses donusum, sistemmesaj, gercekbellek;

{==============================================================================
  dosya arama iþlevini baþlatýr
  uyarý: iþlev SADECE dosya.pas tarafýndan çaðrýlmalýdýr!
 ==============================================================================}
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
 var ADosyaArama: TDosyaArama): TISayi4;
var
  DI: PDosyaIslem;
begin

  UzunDosyaAdi[0] := #0;
  UzunDosyaAdi[1] := #0;

  DI := Dosyalar0.DosyaIslem[ADosyaArama.Kimlik];
  DI^.Aranan := AAramaSuzgec;
  Result := DizinGirdisiOku(AAramaSuzgec, ADosyaArama);
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
  Result := DizinGirdisiOku(Aranan, ADosyaArama);
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
  DI: PDosyaIslem;
  DosyaArama: TDosyaArama;
  TamAramaYolu: string;
  Bulundu,
  AramaTamamlandi: Boolean;
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

  // arama iþleminin daha önce oluþturulan dosya kimlik üzerinden devam etmesi için
  // kimlik deðeri arama kaydýna iliþkilendiriliyor
  DosyaArama.Kimlik := DI^.Kimlik;

  // dosyayý dosya tablosunda bul
  Bulundu := False;
  AramaTamamlandi := False;
  if(dosya.FindFirst(TamAramaYolu, 0, DosyaArama, False) = 0) then
  begin

    repeat

      AramaTamamlandi := dosya.FindNext(DosyaArama) = 1;
      if(DosyaArama.DosyaAdi = DI^.DosyaAdi) then Bulundu := True;

    until (Bulundu) or (AramaTamamlandi);

    //dosya.FindClose(DosyaArama);
  end;

  // dosyanýn BULUNAMAMASI halinde
  if not(Bulundu) then DI^.Gorev^.DosyaSonIslemDurum := HATA_DOSYA_MEVCUTDEGIL;
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
  DI: PDosyaIslem;
  YeniDATSiraNo, OkunacakFAT,
  DATSiraNo, Zincir,
  SektorIS: TISayi4;
  OkumaSonuc: Boolean;
  DG: PDizinGirdisi;
  ZincirBasinaSektor,
  OkunacakSektorSayisi,
  KopyalanacakVeriUzunlugu,
  VeriU, i: TSayi4;
begin

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];
  if(DI = nil) then Exit;

  // en son iþlem hatalý ise çýk
  if(DI^.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  DG := PDizinGirdisi(DI^.TSI);
  Inc(DG, DI^.KayitSN);

  VeriU := DG^.DosyaUzunlugu;
  if(VeriU = 0) then Exit;

  Zincir := DG^.BaslangicKumeNo;

  ZincirBasinaSektor := DI^.MD.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

  // FAT tablosu için bellekte yer ayýr
  GetMem(DI^.Bellek1, 512);

  OkumaSonuc := False;

  repeat

    // okunacak byte'ý sektör sayýsýna çevir
    OkunacakSektorSayisi := ZincirBasinaSektor;
    if(VeriU >= (ZincirBasinaSektor * 512)) then
    begin

      KopyalanacakVeriUzunlugu := ZincirBasinaSektor * 512;
      VeriU -= KopyalanacakVeriUzunlugu;
    end
    else
    begin

      KopyalanacakVeriUzunlugu := VeriU;
      VeriU := 0;
    end;

    // okunacak cluster numarasý
    i := (Zincir - 2) * ZincirBasinaSektor;
    i += DI^.MD.Acilis.IlkVeriSektorNo;

    // sektörü belleðe oku
    GetMem(DI^.Bellek2, OkunacakSektorSayisi * 512);
    SektorIS := DI^.MD.FD^.SektorOku(DI^.MD.FD, i, OkunacakSektorSayisi, DI^.Bellek2);
    Tasi2(DI^.Bellek2, AHedefBellek, KopyalanacakVeriUzunlugu);
    FreeMem(DI^.Bellek2, OkunacakSektorSayisi * 512);

    {if(SektorIS < HATA_YOK) then
    begin

      DI^.Gorev^.DosyaSonIslemDurum := SektorIS;
      Exit;
    end;}

    // okunacak bilginin yerleþtirileceði bir sonraki adresi belirle
    AHedefBellek += KopyalanacakVeriUzunlugu;

    OkunacakFAT := (Zincir * 4) div 512;

    // depolama aygýtýnýn ilk FAT kopyasýnýn tümünü belleðe yükle
    SektorIS := DI^.MD.FD^.SektorOku(DI^.MD.FD, DI^.MD.Acilis.DosyaAyirmaTablosu.IlkSektor +
      OkunacakFAT, 1, DI^.Bellek1);
{    if(SektorIS < HATA_YOK) then
    begin

      DI^.Gorev^.DosyaSonIslemDurum := SektorIS;
      FreeMem(DATBellek, 512);
      Exit;
    end;
}
    // zincir deðerini 4 ile çarp ve bir sonraki zincir deðerini al
    YeniDATSiraNo := (Zincir * 4) mod 512;
    DATSiraNo := PSayi4(DI^.Bellek1 + YeniDATSiraNo)^;

    Zincir := DATSiraNo;

  // eðer 0xfff8..0xffff aralýðýndaysa bu dosyanýn en son cluster'idir
  until (Zincir = $FFFFFFF) or (VeriU = 0) or (OkumaSonuc);

  FreeMem(DI^.Bellek1, 512);
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

  DG := PDizinGirdisi(DI^.TSI);
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
  dizin giriþinden ilgili bilgileri alýr
 ==============================================================================}
function DizinGirdisiOku(AAranacakDeger: string; var ADosyaArama: TDosyaArama): TSayi4;
var
  DizinGirdisi: PDizinGirdisi;
  TumGirislerOkundu,
  UzunDosyaAdiBulundu: Boolean;
  DI: PDosyaIslem;
  ZincirBasinaSektor: TSayi1;
begin

  ADosyaArama.DosyaAdi := '';

  // ilk deðer atamalarý
  TumGirislerOkundu := False;

  UzunDosyaAdiBulundu := False;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaArama.Kimlik];

  ZincirBasinaSektor := DI^.MD.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

  if(DI^.KumeNo = -1) then
  begin

    DI^.KumeNo := DI^.DizinGirisi.IlkSektor div ZincirBasinaSektor;
    DI^.ZincirNo := 0;
    DI^.KayitSN := -1;
  end;

  // aramaya baþla
  repeat

    // bir sonraki girdiye konumlan
    { TODO - her bir sektörde 16 kayýttan fazla girdi bulunabilir }
    Inc(DI^.KayitSN);
    if(DI^.KayitSN = 16) then
    begin

      DI^.KayitSN := 0;
      Inc(DI^.ZincirNo);
    end;

    if(DI^.KayitSN = 0) then
    begin

      // bir sonraki dizin giriþini oku
      if(DI^.MD.FD^.SektorOku(DI^.MD.FD, (DI^.KumeNo * ZincirBasinaSektor) + DI^.ZincirNo,
        1, DI^.TSI) <> 0) then Exit(1);
    end;

    // dosya giriþ tablosuna konumlan
    DizinGirdisi := PDizinGirdisi(DI^.TSI);
    Inc(DizinGirdisi, DI^.KayitSN);

    // dosya giriþinin ilk karakteri #0 ise giriþler okunmuþ demektir
    if(DizinGirdisi^.DosyaAdi[0] = #00) then
    begin

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

      // gözardý edilecek giriþler
      if(ADosyaArama.DosyaAdi = '.') then
      begin

      end
      else
      begin

        Result := 0;
        TumGirislerOkundu := True;
      end;
    end;

  until TumGirislerOkundu;
end;

{==============================================================================
  dizin giriþinden dosya / klasör bilgilerini bulup, geriye ilgili giriþin küme
  numarasýný döndürür

  { TODO - bu iþlev (dosya / dizin arama iþlevi) tüm dosya sistemlerinde olacak }
 ==============================================================================}
function DizinGirisindeAra(var ADosyaIslem: PDosyaIslem; AAranacakDeger: string): TSayi4;
var
  MD: PMDNesne;
  DizinGirdisi: PDizinGirdisi;
  UzunDosyaAdiBulundu: Boolean;
  DosyaAdi: string;
begin

  UzunDosyaAdiBulundu := False;

  // aramanýn yapýlacaðý sürücü
  MD := @ADosyaIslem^.MD;

  // aramaya baþla
  repeat

    // ilk kayýt okuma iþlemi
    if(ADosyaIslem^.KayitSN = -1) then
    begin

      // bir sonraki dizin giriþini oku
      MD^.FD^.SektorOku(MD^.FD, ADosyaIslem^.DizinGirisi.IlkSektor + ADosyaIslem^.ZincirNo,
        1, ADosyaIslem^.TSI);

      ADosyaIslem^.KayitSN := 0;
    end
    else
    begin

      // bir sonraki girdiye konumlan
      Inc(ADosyaIslem^.KayitSN);
      if(ADosyaIslem^.KayitSN = 16) then
      begin

        ADosyaIslem^.KayitSN := -1;
        //Inc(DizinGirdisi);
        { TODO - zincir artýrma iþlemi gerçekleþtir }
      end;

{      Inc(DI^.KayitSN);
      if(DI^.KayitSN = DIZIN_GIRDI_SAYISI) then
      begin

        // yeni sektörün okunmasý için KayitSN deðiþkenini 0 olarak ayarla
        DI^.KayitSN := 0;

        Inc(DI^.ZincirNo);
        if(DI^.ZincirNo = ZincirBasinaSektor) then
        begin
}
    end;

    // dosya giriþ tablosuna konumlan
    DizinGirdisi := PDizinGirdisi(ADosyaIslem^.TSI);
    Inc(DizinGirdisi, ADosyaIslem^.KayitSN);

    // dosya giriþinin ilk karakteri #0 ise giriþler okunmuþ demektir
    if(DizinGirdisi^.DosyaAdi[0] = #00) then
    begin

      Exit(0);
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

        DosyaAdi := WideChar2String(@UzunDosyaAdi);

        // deðiþken içeriklerini sýfýrla
        UzunDosyaAdi[0] := #0;
        UzunDosyaAdi[1] := #0;
        UzunDosyaAdiBulundu := False;
      end else DosyaAdi := HamDosyaAdiniDosyaAdinaCevir(DizinGirdisi);

      //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Dizin Giriþi -> Dosya Adý: ''%s''', [DosyaAdi]);

      // dosya uzunluðu ve cluster baþlangýcýný geri dönüþ deðerine ekle
      if(DosyaAdi = AAranacakDeger) then Exit(DizinGirdisi^.BaslangicKumeNo);
    end;

  until True = False;
end;

end.
