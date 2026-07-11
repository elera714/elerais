{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: fat16.pas
  Dosya İşlevi: fat16 dosya sistem yönetim işlevlerini yönetir

  Güncelleme Tarihi: 30/01/2025

 ==============================================================================}
{$mode objfpc}
unit fat16;

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
function DizinGirdisiOku16(AAranacakDeger: string; var ADosyaArama: TDosyaArama): TSayi4;

implementation

uses fat32, sistemmesaj, dosya, islevler, donusum;

{==============================================================================
  dosya arama işlevini başlatır
  uyarı: işlev SADECE dosya.pas tarafından çağrılmalıdır!
 ==============================================================================}
function FindFirst(const AAramaSuzgec: string; ADosyaOzellik: TSayi4;
 var ADosyaArama: TDosyaArama): TISayi4;
var
  DI: PDosyaIslem;
begin

  DI := Dosyalar0.DosyaIslem[ADosyaArama.Kimlik];
  DI^.Aranan := AAramaSuzgec;
  Result := DizinGirdisiOku16(AAramaSuzgec, ADosyaArama);
end;

{==============================================================================
  dosya arama işlemine devam eder
  uyarı: işlev SADECE dosya.pas tarafından çağrılmalıdır!
 ==============================================================================}
function FindNext(var ADosyaArama: TDosyaArama): TISayi4;
var
  Aranan: string;
  DI: PDosyaIslem;
begin

  DI := Dosyalar0.DosyaIslem[ADosyaArama.Kimlik];
  Aranan := DI^.Aranan;
  Result := DizinGirdisiOku16(Aranan, ADosyaArama);
end;

{==============================================================================
  dosya arama işlemini sonlandırır
  uyarı: işlev SADECE dosya.pas tarafından çağrılmalıdır!
 ==============================================================================}
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
begin

  Result := 0;
end;

{==============================================================================
  dosyalar ile ilgili işlem yapmadan önce tanım işlevlerini gerçekleştirir
  bilgi: işlev dosya.pas tarafından yönetilmektedir
 ==============================================================================}
procedure AssignFile(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
begin
end;

{==============================================================================
  dosya oluşturma işlevini gerçekleştirir
  uyarı: işlev SADECE dosya.pas tarafından çağrılmalıdır!
 ==============================================================================}
procedure ReWrite(ADosyaKimlik: TKimlik);
begin

  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat16.ReWrite işlevi yazılacak', []);
end;

{==============================================================================
  dosyaya veri eklemek için dosya açma işlevlerini gerçekleştirir
 ==============================================================================}
procedure Append(ADosyaKimlik: TKimlik);
begin

  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat12.Append işlevi yazılacak', []);
end;

{==============================================================================
  dosyayı okumadan önce ön hazırlık işlevlerini gerçekleştirir
 ==============================================================================}
procedure Reset(ADosyaKimlik: TKimlik);
var
  DI: PDosyaIslem;
  DosyaArama: TDosyaArama;
  TamAramaYolu: string;
  Bulundu: Boolean;
begin

  // dosya işlem yapısı bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];
  if(DI = nil) then Exit;

  // en son işlem hatalı ise çık
  if(DI^.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  // tam dosya adını al
  TamAramaYolu := DI^.MD.MD3.AygitAdi + ':' + DI^.Klasor + '*.*';

  // dosyayı dosya tablosunda bul
  Bulundu := False;
  if(FindFirst(TamAramaYolu, 0, DosyaArama) = 0) then
  begin

    repeat

      if(DosyaArama.DosyaAdi = DI^.DosyaAdi) then Bulundu := True;
    until (Bulundu) or (FindNext(DosyaArama) <> 0);

    //FindClose(DosyaArama);
  end;

  // dosyanın BULUNAMAMASI halinde
  if not(Bulundu) then DI^.Gorev^.DosyaSonIslemDurum := HATA_DOSYA_MEVCUTDEGIL;
end;

{==============================================================================
  dosyaya veri yazma işlemini gerçekleştirir
 ==============================================================================}
procedure Write(ADosyaKimlik: TKimlik; AVeri: string);
begin

  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat16.Write işlevi yazılacak', []);
end;

{==============================================================================
  verinin sonuna #13#10 ekleyerek dosyaya veri yazma işlemini gerçekleştirir
 ==============================================================================}
procedure WriteLn(ADosyaKimlik: TKimlik; AVeri: string);
begin

  Write(ADosyaKimlik, AVeri + #13#10);
end;

{==============================================================================
  dosya okuma işlemini gerçekleştirir
 ==============================================================================}
procedure Read(ADosyaKimlik: TKimlik; AHedefBellek: Isaretci);
var
  DI: PDosyaIslem;
  DATSiraNo: TSayi2;
  Zincir, i: TSayi2;
  OkunacakFAT,
  YeniDATSiraNo: TISayi4;
  OkumaSonuc: Boolean;
  DG: PDizinGirdisi;
  ZincirBasinaSektor,
  OkunacakSektorSayisi,
  KopyalanacakVeriUzunlugu,
  VeriU: TSayi4;
begin

  // dosya işlem yapısı bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];
  if(DI = nil) then Exit;

  // en son işlem hatalı ise çık
  if(DI^.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit;

  DG := PDizinGirdisi(DI^.TSI + DI^.SektorIciKonum);

  VeriU := DG^.DosyaUzunlugu;
  if(VeriU = 0) then Exit;

  Zincir := DG^.BaslangicKumeNo;

  // FAT tablosu için bellekte yer ayır
  GetMem(DI^.BellekSHT, 512);

  ZincirBasinaSektor := DI^.MD.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

  OkumaSonuc := False;

  repeat

    // okunacak byte'ı sektör sayısına çevir
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

    // okunacak zincir numarası
    i := (Zincir - 2) * ZincirBasinaSektor;

    // sektörü belleğe oku
    GetMem(DI^.Bellek2, OkunacakSektorSayisi * 512);

    if(DI^.MD.FD^.SektorOku(DI^.MD.FD, i + DI^.MD.Acilis.IlkVeriSektorNo,
      OkunacakSektorSayisi, DI^.Bellek2) = HATA_YOK) then
    begin

      Tasi2(DI^.Bellek2, AHedefBellek, KopyalanacakVeriUzunlugu);
      //FreeMem(DI^.Bellek2, OkunacakSektorSayisi * 512);

      // okunacak bilginin yerleştirileceği bir sonraki adresi belirle
      AHedefBellek := AHedefBellek + (OkunacakSektorSayisi * 512);

      OkunacakFAT := (Zincir * 2) div 512;

      // depolama aygıtının ilk FAT kopyasının tümünü belleğe yükle
      if(DI^.MD.FD^.SektorOku(DI^.MD.FD, DI^.MD.Acilis.DosyaAyirmaTablosu.IlkSektor + OkunacakFAT,
        1, DI^.BellekSHT) = HATA_YOK) then
      begin

        // zincir değerini 2 ile çarp ve bir sonraki zincir değerini al
        YeniDATSiraNo := (Zincir * 2) mod 512;
        DATSiraNo := PSayi2(DI^.BellekSHT + YeniDATSiraNo)^;

        Zincir := DATSiraNo;
      end;
    end;

    GetMem(DI^.Bellek2, OkunacakSektorSayisi * 512);

  // eğer 0xFFF8..0xFFFF aralığındaysa bu dosyanın en son zinciridir
  until (Zincir >= $FFF8) or (OkumaSonuc);

  FreeMem(DI^.BellekSHT, 512);
end;

{==============================================================================
  dosya ile yapılmış en son işlemin sonucunu döndürür
 ==============================================================================}
function IOResult: TISayi4;
begin

  Result := 0;
  // bilgi: işlev dosya.pas tarafından yönetilmektedir
end;

{==============================================================================
  dosya uzunluğunu geri döndürür
 ==============================================================================}
function FileSize(ADosyaKimlik: TKimlik): TISayi8;
var
  DI: PDosyaIslem;
  DG: PDizinGirdisi;
begin

  // dosya işlem yapısı bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaKimlik];
  if(DI = nil) then
  begin

    DI^.Gorev^.DosyaSonIslemDurum := HATA_KIMLIK;
    Exit(-1);
  end;

  // en son işlem hatalı ise çık
  if(DI^.Gorev^.DosyaSonIslemDurum <> HATA_DOSYA_ISLEM_BASARILI) then Exit(-1);

  DG := PDizinGirdisi(DI^.TSI);
  DG := PDizinGirdisi(DG + DI^.SektorIciKonum);

  Result := DG^.DosyaUzunlugu;
end;

{==============================================================================
  dosya okuma işleminde dosyanın sonuna gelinip gelinmediğini belirtir
 ==============================================================================}
function EOF(ADosyaKimlik: TKimlik): Boolean;
begin

  Result := True;
end;

{==============================================================================
  dosya üzerinde yapılan işlemi sonlandırır
 ==============================================================================}
procedure CloseFile(ADosyaKimlik: TKimlik);
begin
end;

{==============================================================================
  klasör oluşturma işlevini gerçekleştirir
 ==============================================================================}
function CreateDir(ADosyaKimlik: TKimlik): Boolean;
begin

  Result := False;
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat16.CreateDir işlevi yazılacak', []);
end;

{==============================================================================
  klasör silme işlevini gerçekleştirir
 ==============================================================================}
function RemoveDir(ADosyaKimlik: TKimlik): Boolean;
begin

  Result := False;
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat16.RemoveDir işlevi yazılacak', []);
end;

{==============================================================================
  dosya silme işlevini gerçekleştirir
 ==============================================================================}
function DeleteFile(ADosyaKimlik: TKimlik): Boolean;
begin

  Result := False;
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'fat16.DeleteFile işlevi yazılacak', []);
end;

{==============================================================================
  dizin girişinden ilgili bilgileri alır
 ==============================================================================}
function DizinGirdisiOku16(AAranacakDeger: string; var ADosyaArama: TDosyaArama): TSayi4;
var
  DizinGirdisi: PDizinGirdisi;
  TumGirislerOkundu,
  UzunDosyaAdiBulundu: Boolean;
  DI: PDosyaIslem;
  i: TISayi4;
  ZincirBasinaSektor: TSayi1;
begin

  ADosyaArama.DosyaAdi := '';

  // ilk değer atamaları
  TumGirislerOkundu := False;

  UzunDosyaAdiBulundu := False;

  // dosya işlem yapısı bellek bölgesine konumlan
  DI := Dosyalar0.DosyaIslem[ADosyaArama.Kimlik];

  ZincirBasinaSektor := DI^.MD.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

  //SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'SSS: %d', [DI^.MD.Acilis.DosyaAyirmaTablosu.IlkSektor]);

  if(DI^.KumeNo = -1) then
  begin

    DI^.KumeNo := DI^.DizinGirisi.IlkSektor div ZincirBasinaSektor;
    DI^.ZincirNo := 0;
    DI^.SektorIciKonum := -32; //-1;

    //SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Küme No1: %x', [DI^.KumeNo]);
    //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Yeni Küme: %x', [DI^.DizinGirisi.IlkMumeNo]);
  end;

  // aramaya başla
  repeat

    // bir sonraki girdiye konumlan
    Inc(DI^.SektorIciKonum, 32);

    if(DI^.SektorIciKonum >= 512) then //16) then
    begin

      DI^.SektorIciKonum := 0;
      Inc(DI^.ZincirNo);

      //SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Tamamlanmadı', []);

      if(DI^.ZincirNo >= ZincirBasinaSektor) then
      begin

        // yeni küme numarası al
        //DI^.KumeNo
        DI^.ZincirNo := 0;

        //SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'IlkVeriSektorNo: %d', [DI^.MD.Acilis.IlkVeriSektorNo]);
        //Exit(1);

        GetMem(DI^.BellekSHT, 512);

        i := (DI^.KumeNo * 4) div 512;

        // depolama aygıtının ilk FAT kopyasının tümünü belleğe yükle
        if(DI^.MD.FD^.SektorOku(DI^.MD.FD, DI^.MD.Acilis.DosyaAyirmaTablosu.IlkSektor +
          i, 1, DI^.BellekSHT) = HATA_YOK) then
        begin
    {    if(SektorIS < HATA_YOK) then
        begin

          DI^.Gorev^.DosyaSonIslemDurum := SektorIS;
          FreeMem(DATBellek, 512);
          Exit;
        end;
    }
          // zincir değerini 4 ile çarp ve bir sonraki zincir değerini al
          i := (DI^.KumeNo * 4) mod 512;
          DI^.KumeNo := PSayi4(DI^.BellekSHT + i)^;

          DI^.KumeNo := DI^.KumeNo + 609; //$672;

          //SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'DAT: %x', [DI^.MD.Acilis.DosyaAyirmaTablosu.IlkSektor]);
          //SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Küme No2: %x', [DI^.KumeNo]);

          { TODO - tamamlanacak }
        end else SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Okuma hatası: fat16', []);

        FreeMem(DI^.BellekSHT, 512);
      end;
    end;

    if(DI^.SektorIciKonum = 0) then
    begin

      // bir sonraki dizin girişini oku
      if(DI^.MD.FD^.SektorOku(DI^.MD.FD, (DI^.KumeNo * ZincirBasinaSektor) + DI^.ZincirNo,
        1, DI^.TSI) <> 0) then Exit(1);
    end;

    // dosya giriş tablosuna konumlan
    DizinGirdisi := PDizinGirdisi(DI^.TSI + DI^.SektorIciKonum);

    // dosya girişinin ilk karakteri #0 ise girişler okunmuş demektir
    if(DizinGirdisi^.DosyaAdi[0] = #00) then
    begin

      Result := 1;
      TumGirislerOkundu := True;
    end
    // silinmiş dosya / dizin
    else if(DizinGirdisi^.DosyaAdi[0] = Chr($E5)) then
    begin

      // bir sonraki girişle devam et
    end
    // mantıksal depolama aygıtı etiket (volume label)
    else if(DizinGirdisi^.Ozellikler = $08) then
    begin

      // bir sonraki girişle devam et
    end
    // dizin girdisi uzun ada sahip bir ad ise, uzun dosya adını al
    else if(DizinGirdisi^.Ozellikler = $0F) then
    begin

      UzunDosyaAdiBulundu := True;
      DosyaParcalariniBirlestir(Isaretci(DizinGirdisi));
    end
    // dizin girdisinin uzun ad haricinde olması durumunda
    else //if(DizinGirdisi^.Ozellikler <> $0F) then
    begin

      // girdinin uzun ad dosya adı OLMAMASI durumunda

      // 1. bir önceki girdi uzun dosya adı ise, ad ve diğer özellikleri geri döndür
      if(UzunDosyaAdiBulundu) then
      begin

        ADosyaArama.DosyaAdi := WideChar2String(@UzunDosyaAdi);
        ADosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
        ADosyaArama.OlusturmaSaati := FatXSaat2ELRSaat(DizinGirdisi^.OlusturmaSaati);
        ADosyaArama.OlusturmaTarihi := FatXTarih2ELRTarih(DizinGirdisi^.OlusturmaTarihi);
        ADosyaArama.SonErisimTarihi := FatXTarih2ELRTarih(DizinGirdisi^.SonErisimTarihi);
        ADosyaArama.SonDegisimSaati := FatXSaat2ELRSaat(DizinGirdisi^.SonDegisimSaati);
        ADosyaArama.SonDegisimTarihi := FatXTarih2ELRTarih(DizinGirdisi^.SonDegisimTarihi);

        // değişken içeriklerini sıfırla
        UzunDosyaAdi[0] := #0;
        UzunDosyaAdi[1] := #0;
        UzunDosyaAdiBulundu := False;
      end
      else
      // 2. bir önceki girdi uzun dosya adı değilse, 8 + 3 dosya ad + uzantı ve
      // diğer özellikleri geri döndür
      begin

        ADosyaArama.DosyaAdi := HamDosyaAdiniDosyaAdinaCevir(DizinGirdisi);
        ADosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
        ADosyaArama.OlusturmaSaati := FatXSaat2ELRSaat(DizinGirdisi^.OlusturmaSaati);
        ADosyaArama.OlusturmaTarihi := FatXTarih2ELRTarih(DizinGirdisi^.OlusturmaTarihi);
        ADosyaArama.SonErisimTarihi := FatXTarih2ELRTarih(DizinGirdisi^.SonErisimTarihi);
        ADosyaArama.SonDegisimSaati := FatXSaat2ELRSaat(DizinGirdisi^.SonDegisimSaati);
        ADosyaArama.SonDegisimTarihi := FatXTarih2ELRTarih(DizinGirdisi^.SonDegisimTarihi);
      end;

      // dosya uzunluğu ve cluster başlangıcını geri dönüş değerine ekle
      ADosyaArama.DosyaUzunlugu := DizinGirdisi^.DosyaUzunlugu;
      ADosyaArama.BaslangicKumeNo := DizinGirdisi^.BaslangicKumeNo;

      // gözardı edilecek girişler
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

end.
