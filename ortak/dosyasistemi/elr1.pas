{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: elr1.pas
  Dosya Ýþlevi: ELERA Ýþletim Sistemi'nin dosya sistemi

  Güncelleme Tarihi: 28/02/2025

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
  dosya arama iþlevini baþlatýr
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
  dosya arama iþlemine devam eder
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
  dosya arama iþlemini sonlandýrýr
 ==============================================================================}
function FindClose(var ADosyaArama: TDosyaArama): TISayi4;
begin

  Result := 0;
end;

{==============================================================================
  dosyalar ile ilgili iþlem yapmadan önce taným iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure Assign(var ADosyaKimlik: TKimlik; const ADosyaAdi: string);
begin
end;

{==============================================================================
  dosya oluþturma iþlevini gerçekleþtirir
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

  // her bir cluster'in 4 sektör olarak tasarlandýðý elr-1 dosya sistemi

  // en son iþlem hatalý ise çýk
  if(FileResult > 0) then Exit;

  //ADosyaArama.DosyaAdi := '';

  // ilk deðer atamalarý
  TumGirislerOkundu := False;

  // aramanýn yapýlacaðý sürücü
  //MD := GAramaKayitListesi[ADosyaArama.Kimlik].MantiksalDepolama;
  //DizinGirisi := @GAramaKayitListesi[ADosyaKimlik].DizinGirisi;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

  SektorNo := DosyaKayit^.MantiksalDepolama^.Acilis.DizinGirisi.IlkSektor;

  DizinGirisi.DizinTablosuKayitNo := 0;
  DizinGirisi.OkunanSektor := 0;
  ZincirSektorSayisi := 4;  // geçici deðer
  ZincirNo := 0;

  FD := FizikselDepolamaAygitListesi[3];  // fda4

  // aramaya baþla
  repeat

    if(DizinGirisi.DizinTablosuKayitNo = 0) then
    begin

      OkunanSektor2 := SektorNo + ZincirNo;

      // bir sonraki dizin giriþini oku
      FD.SektorOku(@FD, OkunanSektor2, 1, Isaretci(@DosyaKayit^.SektorIcerigi[0]));

      // DizinGirisi.OkunanSektor deðiþkeni elr dosya sisteminde anlamsýz
      // Inc(DizinGirisi.OkunanSektor);
    end;

    // dosya giriþ tablosuna konumlan
    DizinGirdisi := PDizinGirdisiELR(@DosyaKayit^.SektorIcerigi[0]);
    Inc(DizinGirdisi, DizinGirisi.DizinTablosuKayitNo);

    // dosya giriþinin ilk karakteri #0 ise giriþler okunmuþ demektir
    if(DizinGirdisi^.DosyaAdi[0] = #00) then
    begin

      //Result := 1;
      TumGirislerOkundu := True;
      //Exit;

      DosyaKayit^.SektorNo := OkunanSektor2;
      DosyaKayit^.KayitSN := DizinGirisi.DizinTablosuKayitNo;
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
    // dizin girdisinin uzun ad haricinde olmasý durumunda
    else //if(DizinGirdisi^.Ozellikler <> $0F) then
    begin

      DosyaArama.DosyaAdi := HamDosyaAdiniDosyaAdinaCevir3(DizinGirdisi);
      DosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
      DosyaArama.OlusturmaTarihi := DizinGirdisi^.OlusturmaTarihi;
      DosyaArama.OlusturmaSaati := DizinGirdisi^.OlusturmaSaati;
      DosyaArama.SonErisimTarihi := 0;
      DosyaArama.SonDegisimTarihi := DizinGirdisi^.DegisimTarihi;
      DosyaArama.SonDegisimSaati := DizinGirdisi^.DegisimSaati;

      // dosya uzunluðu ve cluster baþlangýcýný geri dönüþ deðerine ekle
      DosyaArama.DosyaUzunlugu := DizinGirdisi^.DosyaUzunlugu;
      DosyaArama.BaslangicKumeNo := DizinGirdisi^.BaslangicKumeNo;

      // gözardý edilecek giriþler
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
          DosyaBulundu := True;     // çýkýþ için, aþaðýdaki kodlarýn devreye girmemesi için

          { TODO - fat tablosundan bir sonraki alýnan giriþle devaö edilecektir, kodlamayý yap }
        end else DizinGirisi.DizinTablosuKayitNo := 0
      end else Inc(DizinGirdisi);
    end;

  until TumGirislerOkundu;

  // dosya oluþturma iþlemi
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
  dosyayý okumadan önce ön hazýrlýk iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure Reset(ADosyaKimlik: TKimlik);
begin
end;

{==============================================================================
  dosyaya veri yazma iþlemini gerçekleþtirir
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

  // iþlem yapýlan dosyayla ilgili bellek bölgesine konumlan
  DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

  // üzerinde iþlem yapýlacak sürücü
  MD := DosyaKayit^.MantiksalDepolama;

  DP := @DosyaKayit^.SektorIcerigi[DosyaKayit^.KayitSN * 64];
  DP^.BaslangicKumeNo := BosKumeNo;
  DP^.DosyaUzunlugu := VeriU;

  //Tasi2(@DosyaKayit^.DizinGirdisi[0], @DosyaKayit^.SektorIcerigi[DizinGirisi.DizinTablosuKayitNo * 64], 64);

  MD^.FD^.SektorYaz(MD^.FD, DosyaKayit^.SektorNo, 1, @DosyaKayit^.SektorIcerigi[0]);


  MD^.FD^.SektorYaz(MD^.FD, BosKumeNo * 4, 1, @Veri[0]);

  Exit;

  DosyaBulundu := False;

  // her bir cluster'in 4 sektör olarak tasarlandýðý elr-1 dosya sistemi

  BosKumeNo := $600; //1536;

  // en son iþlem hatalý ise çýk
  if(FileResult > 0) then Exit;

  //ADosyaArama.DosyaAdi := '';

  // ilk deðer atamalarý
  TumGirislerOkundu := False;

  // aramanýn yapýlacaðý sürücü
  //MD := GAramaKayitListesi[ADosyaArama.Kimlik].MantiksalDepolama;
  //DizinGirisi := @GAramaKayitListesi[ADosyaKimlik].DizinGirisi;

  // dosya iþlem yapýsý bellek bölgesine konumlan
  DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

  DizinGirisi.DizinTablosuKayitNo := 0;
  DizinGirisi.OkunanSektor := 0;
  ZincirSektorSayisi := 4;  // geçici deðer
  ZincirNo := 0;

  FD := FizikselDepolamaAygitListesi[3];  // fda4

  // aramaya baþla
  repeat

    if(DizinGirisi.DizinTablosuKayitNo = 0) then
    begin

      // bir sonraki dizin giriþini oku
      //FD.SektorOku(@FD, BosKumeNo + ZincirNo, 1, Isaretci(@Bellek));

      // DizinGirisi.OkunanSektor deðiþkeni elr dosya sisteminde anlamsýz
      // Inc(DizinGirisi.OkunanSektor);
    end;

    // dosya giriþ tablosuna konumlan
    {DizinGirdisi := PDizinGirdisiELR(@Bellek);
    Inc(DizinGirdisi, DizinGirisi.DizinTablosuKayitNo);}

    // dosya giriþinin ilk karakteri #0 ise giriþler okunmuþ demektir
    if(DizinGirdisi^.DosyaAdi[0] = #00) then
    begin

      //Result := 1;
      TumGirislerOkundu := True;
      //Exit;
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
    // dizin girdisinin uzun ad haricinde olmasý durumunda
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

      // dosya uzunluðu ve cluster baþlangýcýný geri dönüþ deðerine ekle
      DosyaArama.DosyaUzunlugu := DizinGirdisi^.DosyaUzunlugu;
      DosyaArama.BaslangicKumeNo := DizinGirdisi^.BaslangicKumeNo;

      // gözardý edilecek giriþler
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
        SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Dosya Adý: %s, Sýra No: %d',
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
          DosyaBulundu := True;     // çýkýþ için, aþaðýdaki kodlarýn devreye girmemesi için

          { TODO - fat tablosundan bir sonraki alýnan giriþle devaö edilecektir, kodlamayý yap }
        end else DizinGirisi.DizinTablosuKayitNo := 0
      end else Inc(DizinGirdisi);
    end;

  until TumGirislerOkundu;

  // dosya oluþturma iþlemi
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
  dosya okuma iþlemini gerçekleþtirir
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

  // iþlem yapýlan dosyayla ilgili bellek bölgesine konumlan
  DosyaKayit := @GDosyaKayitListesi[ADosyaKimlik];

  // üzerinde iþlem yapýlacak sürücü
  MD := DosyaKayit^.MantiksalDepolama;

  OkunacakVeri := DosyaKayit^.Uzunluk;

  // sektörü belleðe oku
  MD^.FD^.SektorOku(MD^.FD, DosyaKayit^.IlkZincirSektor * 4, 1, @DATBellekAdresi);

  Tasi2(@DATBellekAdresi[0], AHedefBellek, OkunacakVeri);

  //SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Ýlk Zincir: %x', [DosyaKayit^.IlkZincirSektor]);
  //SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Dosya Uzunluk: %d', [OkunacakVeri]);

  Exit;

  Zincir := DosyaKayit^.IlkZincirSektor;

  ZincirBasinaSektor := MD^.Acilis.DosyaAyirmaTablosu.ZincirBasinaSektor;

  OkumaSonuc := False;

  repeat

    // okunacak byte'ý sektör sayýsýna çevir
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

    // okunacak cluster numarasý
    i := (Zincir - 2) * ZincirBasinaSektor;
    i += MD^.Acilis.IlkVeriSektorNo;

    // sektörü belleðe oku
    MD^.FD^.SektorOku(MD^.FD, i, OkunacakSektorSayisi, AHedefBellek);

    // okunacak bilginin yerleþtirileceði bir sonraki adresi belirle
    AHedefBellek += KopyalanacakVeriUzunlugu;

    OkunacakFAT := (Zincir * 4) div 512;

    // depolama aygýtýnýn ilk FAT kopyasýnýn tümünü belleðe yükle
    MD^.FD^.SektorOku(MD^.FD, MD^.Acilis.DosyaAyirmaTablosu.IlkSektor + OkunacakFAT,
      1, @DATBellekAdresi);

    // zincir deðerini 4 ile çarp ve bir sonraki zincir deðerini al
    YeniDATSiraNo := (Zincir * 4) mod 512;
    DATSiraNo := PSayi4(Isaretci(@DATBellekAdresi) + YeniDATSiraNo)^;

    Zincir := DATSiraNo;

  // eðer 0xfff8..0xffff aralýðýndaysa bu dosyanýn en son cluster'idir
  until (Zincir = $FFFFFFF) or (OkunacakVeri = 0) or (OkumaSonuc);
end;

{==============================================================================
  dosya ile yapýlmýþ en son iþlem sonucunu döndürür
 ==============================================================================}
function IOResult: TISayi4;
begin
end;

{==============================================================================
  dosya uzunluðunu geri döndürür
 ==============================================================================}
function FileSize(ADosyaKimlik: TKimlik): TISayi4;
begin

  Result := 0;
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
procedure Close(ADosyaKimlik: TKimlik);
begin
end;

{==============================================================================
  dosya oluþturma iþlevini gerçekleþtirir
 ==============================================================================}
procedure CreateDir(ADosyaKimlik: TKimlik);
begin

end;

{==============================================================================
  klasör silme iþlevini gerçekleþtirir
 ==============================================================================}
procedure RemoveDir(const AKlasorAdi: string);
begin

end;

{==============================================================================
  dosya silme iþlevini gerçekleþtirir
 ==============================================================================}
function DeleteFile(const ADosyaAdi: string): TISayi4;
begin

end;

{==============================================================================
  dizin giriþinden ilgili bilgileri alýr
 ==============================================================================}
function DizinGirdisiOku(ADizinGirisi: PDizinGirisi; AAranacakDeger: string;
 var ADosyaArama: TDosyaArama): TSayi1;
var
  MD: PMantiksalDepolama;
  DizinGirdisi: PDizinGirdisiELR;
  TumGirislerOkundu: Boolean;
begin

  ADosyaArama.DosyaAdi := '';

  // ilk deðer atamalarý
  TumGirislerOkundu := False;

  // aramanýn yapýlacaðý sürücü
  MD := GAramaKayitListesi[ADosyaArama.Kimlik].MantiksalDepolama;

  // aramaya baþla
  repeat

    if(ADizinGirisi^.DizinTablosuKayitNo = 0) then
    begin

      // bir sonraki dizin giriþini oku
      MD^.FD^.SektorOku(MD^.FD, ADizinGirisi^.IlkSektor + ADizinGirisi^.OkunanSektor,
        1, @DizinBellekAdresi);

      Inc(ADizinGirisi^.OkunanSektor);
    end;

    // dosya giriþ tablosuna konumlan
    DizinGirdisi := PDizinGirdisiELR(@DizinBellekAdresi);
    Inc(DizinGirdisi, ADizinGirisi^.DizinTablosuKayitNo);

    // dosya giriþinin ilk karakteri #0 ise giriþler okunmuþ demektir
    if(DizinGirdisi^.DosyaAdi[0] = #00) then
    begin

      Result := 1;
      TumGirislerOkundu := True;
    end
    // silinmiþ dosya / dizin
    else if(DizinGirdisi^.DosyaAdi[0] = Chr($FF)) then
    begin

      // bir sonraki giriþle devam et
    end
    // mantýksal depolama aygýtý etiket (volume label)
{    else if(DizinGirdisi^.Ozellikler = $08) then
    begin

      // bir sonraki giriþle devam et
    end}
    // dizin girdisinin uzun ad haricinde olmasý durumunda
    else //if(DizinGirdisi^.Ozellikler <> $0F) then
    begin

      ADosyaArama.DosyaAdi := HamDosyaAdiniDosyaAdinaCevir2(DizinGirdisi);
      ADosyaArama.Ozellikler := DizinGirdisi^.Ozellikler;
      ADosyaArama.OlusturmaTarihi := DizinGirdisi^.OlusturmaTarihi;
      ADosyaArama.OlusturmaSaati := DizinGirdisi^.OlusturmaSaati;
      ADosyaArama.SonErisimTarihi := 0;
      ADosyaArama.SonDegisimTarihi := DizinGirdisi^.DegisimTarihi;
      ADosyaArama.SonDegisimSaati := DizinGirdisi^.DegisimSaati;

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

    // bir sonraki girdiye konumlan
    Inc(ADizinGirisi^.DizinTablosuKayitNo);
    if(ADizinGirisi^.DizinTablosuKayitNo = 8) then
      ADizinGirisi^.DizinTablosuKayitNo := 0
    else Inc(DizinGirdisi);

    { TODO - kontrol edilerek aktifleþtirilecek }
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
  sektör harita tablosunu oluþturur
 ==============================================================================}
procedure SHTOlustur(AIlkSektor, AToplamSektor, AAyrilanSektor: TSayi4);
var
  Bellek: array[0..511] of TSayi1;
  FD: TFizikselDepolama;
  i, j: TSayi4;
begin

  { TODO - burada katý kodlama uygulanmýþtýr, kodlar kontrol edilecektir }

  // sht için ayrýlan sektörleri sýfýrla
  FillChar(Bellek, 512, 0);
  FD := FizikselDepolamaAygitListesi[3];  // fda4

  for i := AIlkSektor to (AIlkSektor + AToplamSektor) - 1 do
  begin

    FD.SektorYaz(@FD, i, 1, Isaretci(@Bellek));
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

  FillChar(Bellek, 512, $FF);
  FD := FizikselDepolamaAygitListesi[3];  // fda4

  for i := AIlkSektor to (AIlkSektor + j) - 1 do
  begin

    FD.SektorYaz(@FD, i, 1, Isaretci(@Bellek));
  end;

  // ilk dizin giriþini ayýr
  FillChar(Bellek, 512, 0);
  PSayi4(@Bellek)^ := $FFFFFFFF;
  FD := FizikselDepolamaAygitListesi[3];  // fda4

  FD.SektorYaz(@FD, i + 1, 1, Isaretci(@Bellek));
end;

{==============================================================================
  sektör harita tablosundan boþ küme numarasý alýr
 ==============================================================================}
 function SHTBosKumeTahsisEt: TSayi4;
var
  Bellek: array[0..511] of TSayi1;
  FD: TFizikselDepolama;
  KumeNo, i, j: TSayi4;
  Deger: PSayi4;
begin

  // tüm sektörler dolu
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

  Result := $FFFFFFFF;    // boþ sektör yok
end;

{==============================================================================
  sektör harita tablosundan alýnan sektör kümesini serbest býrakýr
 ==============================================================================}
function SHTBosKumeSerbestBirak(AKumeNo: TSayi4): Boolean;
var
  Bellek: array[0..511] of TSayi1;
  FD: TFizikselDepolama;
  SektorNo, SiraNo, j: TSayi4;
  Deger: PSayi4;
begin

  // konumlanýlacak sektör numarasý
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

  // hedef bellek bölgesini sýfýrla
  // hedef bellek alaný þu an 8+1+3+1 (dosya+.+uz+null) olmalýdýr
  Result := '';

  // dosya adýný çevir
  i := 1;
  while (i < 43) and (ADizinGirdisi^.DosyaAdi[i] <> #0) do
  begin

    Result := Result + ADizinGirdisi^.DosyaAdi[i];
    Inc(i);
  end;
end;

end.
