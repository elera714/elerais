{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: gercekbellek.pas
  Dosya Ýþlevi: gerçek (fiziksel) bellek yönetim iþlevlerini içerir

  Güncelleme Tarihi: 25/08/2025

  Bilgi-1: yeni bellek modeli iþlevler tarafýndan THafiza yapýsý ile yönetilmektedir. Yapý mevcut
    tüm belleði aþaðýdaki yapý dahilinde deðerlendirerek bellek ayýrma iþlemi yapmaktadýr
  Bilgi-2: tüm bellek ayýrma iþlemlerinde geriye döndürülen iþaretçi deðeri 4'ün katlarý
    olarak gerçekleþmektedir

    Bellek Hücresi    0    4    8    12   16   20   24   28   32   36   40   44
                     +----+----+----+----+----+----+----+----+----+----+----+
    Açýklama         | U  | F  | BO | BS |VERÝ| U  | F  | BO | BS |VERÝ|...
                     +----+----+----+----+----+----+----+----+----+----+----+
    Bellek Ýçeriði   | 4  | 0  | 0  | 20 |ABCD| 3  | 1  | 0  | 40 |ABC |...
                     +----+----+----+----+----+----+----+----+----+----+----+

 ==============================================================================}
{$mode objfpc}
unit gercekbellek;

interface

uses paylasim;

type
  PHafiza = ^THafiza;
  THafiza = record
    U,                  // tahsis edilen bellek uzunluðu
    F: TSayi4;          // U deðerinin 4 byte'ýn katlarýna yuvarlanmasý için gereken byte sayýsý (fark)
    BO,                 // bir önceki tahsis edilen bellek bölgesinin yapýsý
    BS: Isaretci;       // bir sonraki tahsis edilen bellek bölgesinin yapýsý
  end;

type
  PGercekBellek = ^TGercekBellek;
  TGercekBellek = object
  private
    FToplamRAM, FToplamBlok,
    FAyrilmisBlok, FKullanilmisBlok: TSayi4;
  public
    FToplamYBYBellek,
    FKullanilanYBYBellek: TSayi4;
    procedure Yukle;
    function ToplamBellekMiktariniAl: TSayi4;
    function BosBellekBul(AIstenenBlokSayisi: TSayi4): TISayi4;
    function Ayir(AIstenenBellek: TSayi4): Isaretci;
    procedure YokEt(ABellekAdresi: Isaretci; ABellekUzunlugu: TSayi4);
  published
    property ToplamRAM: TSayi4 read FToplamRAM write FToplamRAM;
    property ToplamBlok: TSayi4 read FToplamBlok write FToplamBlok;
    property AyrilmisBlok: TSayi4 read FAyrilmisBlok write FAyrilmisBlok;
    property KullanilmisBlok: TSayi4 read FKullanilmisBlok write FKullanilmisBlok;
  end;

var
  GercekBellek0: TGercekBellek;
  BellekYonetimFPC: TMemoryManager;
  GercekBellekKilit: TSayi4 = 0;

function ELRGetMem(AUzunluk: TSayi4): Isaretci;
function ELRFreeMemSize(ABellek: Isaretci; AUzunluk: TSayi4): TSayi4;

function ELRGetMemYeni(AUzunluk: TSayi4): Isaretci;
function ELRFreeMemYeni(ABellek: Isaretci): TSayi4;
function ELRFreeMemSizeYeni(ABellek: Isaretci; AUzunluk: TSayi4): TSayi4;
function ELRAllocMemYeni(AUzunluk: TSayi4): Isaretci;
function ELRReAllocMemYeni(var ABellek: Isaretci; AUzunluk: TSayi4): Isaretci;
function ELRMemSizeYeni(ABellek: Isaretci): TSayi4;
procedure BilgiVer;
function Yasla4Byte(ADeger: TSayi4): TSayi4;

implementation

uses sistemmesaj;

var
  // yeni bellek yöneticisi
  YBYAdresIlk,
  YBYAdresSon: Isaretci;

{==============================================================================
  bellek yükleme / haritalama iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure TGercekBellek.Yukle;
var
  i, ToplamBellekMiktari: TSayi4;
  Bellek: PSayi1;
begin

  { TODO - þu aþamada 40 .. 60 mb arasý Yeni Bellek Yönetimine tahsis edildi
    önemli: 2 bellek yönetimi tekleþtirilmeli }
  YBYAdresIlk := Isaretci(40 * 1024 * 1024);      // $2800000
  YBYAdresSon := Isaretci(64 * 1024 * 1024);      // $4000000

  FToplamYBYBellek := (64 - 40) * 1024 * 1024;
  FKullanilanYBYBellek := 0;

  // kullanýlacak bellek bölgesini sýfýrla
  FillByte(Isaretci(YBYAdresIlk)^, (YBYAdresSon - YBYAdresIlk) + 1, 0);

  ToplamBellekMiktari := ToplamBellekMiktariniAl;

  // sistemdeki toplam RAM miktarý
  FToplamRAM := ToplamBellekMiktari;

  // RAM miktarýný blok sayýsýna çevir. (1 blok = 4K)
  FToplamBlok := (FToplamRAM shr 12);

  // çekirdek için bellek ayrýmýný gerçekleþtir
  i := (SISTEME_AYRILMIS_RAM shr 12);
  FAyrilmisBlok := i;
  FKullanilmisBlok := i;

  // tüm belleði boþ olarak iþaretle
  Bellek := BELLEK_HARITA_ADRESI;
  for i := 0 to FToplamBlok - 1 do
  begin

    Bellek^ := 0;
    Inc(Bellek);
  end;

  // sisteme ayrýlan belleði kullanýlýyor olarak iþaretle
  Bellek := BELLEK_HARITA_ADRESI;
  for i := 0 to AyrilmisBlok - 1 do
  begin

    Bellek^ := 1;
    Inc(Bellek);
  end;

  // çekirdek bellek yönetim iþlevlerini yükle
  BellekYonetimFPC.NeedLock := False;     // eski iþlev
  BellekYonetimFPC.GetMem := @ELRGetMemYeni;
  BellekYonetimFPC.FreeMem := @ELRFreeMemYeni;
  BellekYonetimFPC.FreeMemSize := @ELRFreeMemSizeYeni;
  BellekYonetimFPC.AllocMem := @ELRAllocMemYeni;
  BellekYonetimFPC.ReAllocMem := @ELRReAllocMemYeni;
  BellekYonetimFPC.MemSize := @ELRMemSizeYeni;
  BellekYonetimFPC.InitThread := nil;
  BellekYonetimFPC.DoneThread := nil;
  BellekYonetimFPC.RelocateHeap := nil;
  BellekYonetimFPC.GetHeapStatus := nil;
  BellekYonetimFPC.GetFPCHeapStatus := nil;

  SetMemoryManager(BellekYonetimFPC);
end;

{$asmmode intel}
function TGercekBellek.ToplamBellekMiktariniAl: TSayi4;
var
  i: TSayi4;
begin
asm
  pushad

  // önbellek iþlemini durdur
  mov   eax,cr0
  and   eax,not($40000000 + $20000000)
  or    eax,$40000000
  mov   cr0,eax
  wbinvd

  xor   edi,edi
  mov   ebx,'1234'
@tekrar:
  add   edi,$100000
  xchg  ebx,DWORD[edi]
  cmp   DWORD[edi],'1234'
  xchg  ebx,DWORD[edi]
  je    @tekrar

  // önbellek iþlemine devam et
  and   eax,not($40000000 + $20000000)
  mov   cr0,eax

  mov   i,edi

  popad
end;

  Result := i;
end;

{==============================================================================
  boþ bellek alanýný rezerv eder ve bellek bölgesini sýfýrlar
  bilgi: istenen bellek miktarý 4096 byte ve katlarý olarak tahsis edilir
  1    byte..4096 byte arasý 1 blok
  4097 byte..8192 byte arasý 2 blok tahsis edilir
 ==============================================================================}
function TGercekBellek.Ayir(AIstenenBellek: TSayi4): Isaretci;
var
  IlkBlok: TISayi4;
  IstenenBellek, BlokSayisi,
  i: TSayi4;
  Bellek: PByte;
begin

  // istenen bellek boyutu 0 ise hata vererek çýk
  if(AIstenenBellek = 0) then Exit(nil);

  // AIstenenBellek = byte türünden istenen bellek miktarý
  // 1..4096 arasý 1 blok tasarýmý
  IstenenBellek := AIstenenBellek - 1;

  BlokSayisi := (IstenenBellek shr 12) + 1;

  // boþ bellek alaný bul
  IlkBlok := BosBellekBul(BlokSayisi);
  if(IlkBlok < 0) then Exit(nil);

  Bellek := BELLEK_HARITA_ADRESI;
  Inc(Bellek, IlkBlok);

  // bellek bloðunu kullanýlýyor olarak iþaretle
  for i := 0 to BlokSayisi - 1 do
  begin

    Bellek^ := 1;
    Inc(Bellek);
  end;

  // bellek bölgesini sýfýr ile doldur
  i := (IlkBlok shl 12);
  FillByte(Isaretci(i)^, BlokSayisi shl 12, 0);

  Inc(FKullanilmisBlok, BlokSayisi);

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Ayrýlan: Blok Sayýsý: %d', [BlokSayisi]);
  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Ayrýlan: Ýlk Blok: %d', [IlkBlok]);

  Result := Isaretci(i);
end;

{==============================================================================
  ayrýlmýþ belleði iptal eder
 ==============================================================================}
procedure TGercekBellek.YokEt(ABellekAdresi: Isaretci; ABellekUzunlugu: TSayi4);
var
  IlkBlok, BlokSayisi,
  BellekUzunlugu,
  i: TSayi4;
  Bellek: PByte;
begin

  BellekUzunlugu := ABellekUzunlugu - 1;

  // bellek adresini ve uzunluðunu blok numarasýna çevir
  IlkBlok := (TSayi4(ABellekAdresi) shr 12);
  BlokSayisi := (BellekUzunlugu shr 12) + 1;

  Bellek := BELLEK_HARITA_ADRESI;
  Inc(Bellek, IlkBlok);

  // belirtilen blok sayýsý kadar iptal iþlemi gerçekleþtir
  for i := 0 to BlokSayisi - 1 do
  begin

    Bellek^ := 0;
    Inc(Bellek);
  end;

  Dec(FKullanilmisBlok, BlokSayisi);

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Yokedilen: Blok Sayýsý: %d', [BlokSayisi]);
  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Yokedilen: Ýlk Blok: %d', [IlkBlok]);
end;

{==============================================================================
  boþ bellek alaný bulur (not : bulunan boþ alan ayrýlmaz)
 ==============================================================================}
function TGercekBellek.BosBellekBul(AIstenenBlokSayisi: TSayi4): TISayi4;
var
  Bellek: PSayi1;
  AranacakIlkBlok, AranacakSonBlok,
  BulunanIlkBlok, i: TSayi4;
  BellekBulundu: Boolean;
begin

  AranacakIlkBlok := FAyrilmisBlok;
  AranacakSonBlok := ToplamBlok;

  Bellek := BELLEK_HARITA_ADRESI;
  Inc(Bellek, AranacakIlkBlok);

  // ayrýlmýþ bloktan toplam blok sayýsýna kadar tüm bellek bloklarýný ara
  while (AranacakIlkBlok < AranacakSonBlok) do
  begin

    // eðer boþ blok var ise ...
    if(Bellek^ = 0) then
    begin

      // bulunan blok numarasýný kaydet
      BulunanIlkBlok := AranacakIlkBlok;
      BellekBulundu := True;

      // talep edilen blok kadar arama yap
      for i := 0 to AIstenenBlokSayisi - 1 do
      begin

        // eðer aranan blok daha önce ayrýldýysa arama iþlemini durdur
        if(Bellek^ = 1) then
        begin

          BellekBulundu := False;
          Break;
        end
        else
        begin

          // aksi halde bir sonraki bloða bak
          Inc(Bellek);
          Inc(AranacakIlkBlok);
        end;
      end;

      if(BellekBulundu) then
      begin

        // istenen bloklar ardýþýk olarak boþ ise
        // ilk blok numarasýný geri döndür ve çýk
        Result := BulunanIlkBlok;
        Exit;
      end;
    end
    else
    begin

      Inc(Bellek);
      Inc(AranacakIlkBlok);
    end;
  end;

  Result := HATA_TUMBELLEKKULLANIMDA;
end;

// istenen miktarda bellek ayýr - fpc + çekirdek iþlevleri için
function ELRGetMem(AUzunluk: TSayi4): Isaretci;
begin

  Result := GercekBellek0.Ayir(AUzunluk);

  if(BellekDegeriniGoster) then begin
  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ELRGetMem.Result: $%x', [Result]);
  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ELRGetMem.AUzunluk: %d', [AUzunluk]); end;
end;

// sistemden alýnan belleði serbest býrak - fpc + çekirdek iþlevleri için
function ELRFreeMemSize(ABellek: Isaretci; AUzunluk: TSayi4): TSayi4;
begin

  if(BellekDegeriniGoster) then begin
  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ELRFreeMemSize.ABellek: $%x', [ABellek]);
  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ELRFreeMemSize.AUzunluk: %d', [AUzunluk]); end;

  GercekBellek0.YokEt(ABellek, AUzunluk);
  Result := 0;
end;

function ELRFreeMemYeni(ABellek: Isaretci): TSayi4;
begin

  ELRFreeMemSizeYeni(ABellek, 0);
  Result := 0;
end;

function ELRGetMemYeni(AUzunluk: TSayi4): Isaretci;
var
  Hafiza1, Hafiza2,
  HafizaYeni: PHafiza;
  YBYAdresMevcut: Isaretci;
  SiraNo, i, Fark,
  Uzunluk: TSayi4;
begin

  while KritikBolgeyeGir(GercekBellekKilit) = False do;

  if(AUzunluk = 0) then
  begin

    KritikBolgedenCik(GercekBellekKilit);
    Exit(nil);
  end;

  // uzunluk deðeri 4 byte'ýn katlarýna yuvarlanýyor
  Uzunluk := Yasla4Byte(AUzunluk);
  // fark deðeri = istenen bellek miktarýndan, 4 katýna yuvarlanýlan fark deðeri
  Fark := Uzunluk - AUzunluk;

  Hafiza1 := YBYAdresIlk;
  Hafiza2 := nil;
  SiraNo := 0;

  repeat

    if(Hafiza1^.U = 0) then
    begin

      // 1. yeni kayýt ekleme - eklenecek veri kayýt yapýsýnýn bir sonraki kaydýnýn nil olmasý durumu
      // (ilk veya en sona kayýt ekleme iþlemi)
      if(Hafiza1^.BS = nil) then
      begin

        // yeterince bellek mevcut mu?
        YBYAdresMevcut := Isaretci(Hafiza1) + SizeOf(THafiza) + Uzunluk;
        if(YBYAdresMevcut > YBYAdresSon) then Break;

        // yeni veri kayýt yapýsý oluþtur
        Hafiza1^.U := AUzunluk;
        Hafiza1^.F := Fark;
        Hafiza1^.BO := Hafiza2;
        Hafiza1^.BS := nil;

        // en sona eklenen bu veri kayýt yapýsýný bir önceki veri kayýt yapýsýna baðla
        if not(Hafiza2 = nil) then Hafiza2^.BS := Hafiza1;

        FillByte(PChar(Isaretci(Hafiza1) + SizeOf(THafiza))^, Uzunluk, 0);

        GercekBellek0.FKullanilanYBYBellek += SizeOf(THafiza) + Uzunluk;

        KritikBolgedenCik(GercekBellekKilit);

        Exit(Isaretci(Hafiza1) + SizeOf(THafiza));
      end
      else
      // 2. silinmiþ bir veri kayýt yapýsýnýn yeni veri kayýt yapýsýyla güncellenmesi
      begin

        i := TSayi4(Hafiza1^.BS) - TSayi4(Hafiza1) - SizeOf(THafiza);

        // 2.1. boþ bellek miktarý ile istenen bellek miktarý ayný ise
        if(Uzunluk = i) then
        begin

          Hafiza1^.U := AUzunluk;
          Hafiza1^.F := Fark;

          GercekBellek0.FKullanilanYBYBellek += Uzunluk + SizeOf(THafiza);

          KritikBolgedenCik(GercekBellekKilit);

          Exit(Isaretci(Hafiza1) + SizeOf(THafiza));
        end
        // 2.2. boþ bellek miktarý istenen bellek miktarýndan büyük ve
        //  yeni bir veri kayýt yapýsý oluþturacak kadar geniþlikte ise
        else if(Uzunluk < i) and ((i - Uzunluk) >= SizeOf(THafiza)) then
        begin                                    { SizeOf(THafiza) -> yeni bir veri kayýt yapýsý oluþturulabilmeli}

          // daha önce ayrýlan ve serbest býrakýlan veri kayýt yapýsý için
          // sýnýr veri kayýt yapýsý oluþturuluyor
          // (bu kýsým 2 (baþ ve son) veri kayýt yapýsý arasýna yeni bir sonlandýrma veri kayýt yapýsý oluþturur)
          HafizaYeni := Isaretci(Hafiza1) + SizeOf(THafiza) + Uzunluk;
          HafizaYeni^.BO := Hafiza1;
          HafizaYeni^.BS := Hafiza1^.BS;
          HafizaYeni^.U := i - Uzunluk - SizeOf(THafiza);
          HafizaYeni^.F := 0;

          // sondaki veri kayýt yapýsýnýn bir önceki veri kayýt yapýsý belirleniyor
          // (sondaki veri kayýt yapýsýnýn güncellenmesi)
          Hafiza2 := Hafiza1^.BS;
          Hafiza2^.BO := HafizaYeni;

          // baþtaki veri kayýt yapýsýnýn bir sonraki veri kayýt yapýsý belirleniyor
          // (baþlangýç veri kayýt yapýsýnýn güncellenmesi - iþlev için bu veri kayýt yapýsý geri döndürülecektir)
          Hafiza1^.BS := HafizaYeni;
          Hafiza1^.U := Uzunluk;
          Hafiza1^.F := Fark;

          GercekBellek0.FKullanilanYBYBellek += Uzunluk + SizeOf(THafiza);

          KritikBolgedenCik(GercekBellekKilit);

          Exit(Isaretci(Hafiza1) + SizeOf(THafiza));
        end
        else
        // 2.3. boþ bellek ve/veya istenen miktar bulunamadýðý için bir sonraki yapýya konumlan
        begin

          Hafiza2 := Hafiza1;
          Hafiza1 := Hafiza1^.BS;
        end;
      end;
    end
    else
    begin

      // Hafiza2 = bir önceki veri kayýt yapýsý
      Hafiza2 := Hafiza1;
      Hafiza1 := Isaretci(Hafiza1) + SizeOf(THafiza) + Hafiza1^.U + Hafiza1^.F;
    end;

    Inc(SiraNo);

  until True = False;

  KritikBolgedenCik(GercekBellekKilit);

  Result := nil;
end;

function ELRFreeMemSizeYeni(ABellek: Isaretci; AUzunluk: TSayi4): TSayi4;
var
  Hafiza1,
  Hafiza2: PHafiza;
begin

  while KritikBolgeyeGir(GercekBellekKilit) = False do;

  // bellek yönetimi, her zaman için bir sonrakini silme, bir öncekine eklenme
  // mantýðý içerisinde çalýþmaktadýr

  Hafiza1 := Isaretci(ABellek) - SizeOf(THafiza);

  // uzunluk deðerinin 0 verilmesi durumunda uzunluk deðerini yapý içerisinden al
  if(AUzunluk = 0) then AUzunluk := Hafiza1^.U;

  if(Hafiza1^.U = AUzunluk) then
  begin

    // en baþtaki veri kayýt yapýsýnýn silinmesi
    if(Hafiza1^.BO = nil) then
    begin

      GercekBellek0.FKullanilanYBYBellek -= Hafiza1^.U + Hafiza1^.F + SizeOf(THafiza);

      Hafiza1^.U := 0;
      Hafiza1^.F := 0;

      // baþtaki veri kayýt yapýsýnýn bir sonraki veri kayýt yapýsýnýn da silinmiþ olmasý halinde
      Hafiza2 := Hafiza1^.BS;
      if(Hafiza2^.U = 0) then
      begin

        // 1. veri kayýt yapýsý = silinmesi istenen veri kayýt yapýsý
        // 2. veri kayýt yapýsý = daha önce silinen veri kayýt yapýsý
        // 3. veri kayýt yapýsý = mevcut veri kayýt yapýsý

        // 3. veri kayýt yapýsýný 1. veri kayýt yapýsýna baðla
        Hafiza1^.BS := Hafiza2^.BS;

        // 2. veri kayýt yapýsýný sil
        Hafiza2^.BO := nil;
        Hafiza2^.BS := nil;
        Hafiza2^.F := 0;

        // 1. veri kayýt yapýsýný 3. veri kayýt yapýsýna baðla
        Hafiza2 := Hafiza1^.BS;
        Hafiza2^.BO := Hafiza1;
      end;
    end
    // en sondaki veri kayýt yapýsýnýn silinmesi
    else if(Hafiza1^.BS = nil) then
    begin

      GercekBellek0.FKullanilanYBYBellek -= Hafiza1^.U + Hafiza1^.F + SizeOf(THafiza);

      // 1. veri kayýt yapýsý = mevcut veri kayýt yapýsý
      // 2. veri kayýt yapýsý = mevcut veya daha önce silinen veri kayýt yapýsý
      // 3. veri kayýt yapýsý = silinmesi istenen veri kayýt yapýsý

      // 3. veri kayýt yapýsýnýn 2. veri kayýt yapýsýyla baðlantýsýný kes
      Hafiza2 := Hafiza1^.BO;
      if not(Hafiza2 = nil) then Hafiza2^.BS := nil;

      // 3. veri kayýt yapýsýný sil
      Hafiza1^.BO := nil;
      Hafiza1^.BS := nil;
      Hafiza1^.U := 0;
      Hafiza1^.F := 0;

      // 2. veri kayýt yapýsý daha önce silinmiþse (0 olarak iþaretlenmiþse)
      // 2. veri kayýt yapýsýný tamamen bellekten kaldýr / sil
      if not(Hafiza2 = nil) and (Hafiza2^.U = 0) then
      begin

        // 2. veri kayýt yapýsýný silmeden önce 1. veri kayýt yapýsýyla baðlantýsýný kes
        Hafiza1 := Hafiza2^.BO;
        Hafiza1^.BS := nil;

        // 2. veri kayýt yapýsýný da sil
        Hafiza2^.BO := nil;
        Hafiza2^.BS := nil;
        Hafiza2^.U := 0;
        Hafiza2^.F := 0;
      end;
    end
    else
    // ortaki veri kayýt yapýsýnýn silinmesi
    begin

      GercekBellek0.FKullanilanYBYBellek -= Hafiza1^.U + Hafiza1^.F + SizeOf(THafiza);

      // 1. veri kayýt yapýsý = bir önceki silinmiþ veri kayýt yapýsý
      // 2. veri kayýt yapýsý = silinmesi istenen veri kayýt yapýsý
      // 3. veri kayýt yapýsý = bir sonraki silinmiþ veri kayýt yapýsý

      // 2. veri kayýt yapýsýnýn uzunluðunu sýfýrla (sil)
      Hafiza1^.U := 0;
      Hafiza1^.F := 0;

      // 3. veri kayýt yapýsýnýn da silinmiþ olmasý halinde
      Hafiza2 := Hafiza1^.BS;
      if(Hafiza2^.U = 0) then
      begin

        // 3. veri kayýt yapýsýnýn bir sonraki veri kayýt yapýsýný 2. veri kayýt yapýsýna baðla
        Hafiza1^.BS := Hafiza2^.BS;

        // 3. veri kayýt yapýsýný sil
        Hafiza2^.BO := nil;
        Hafiza2^.BS := nil;
        Hafiza2^.U := 0;
        Hafiza2^.F := 0;

        // 2. veri kayýt yapýsýný, 3. veri kayýt yapýsýnýn bir sonraki veri kayýt yapýsýna baðla
        Hafiza2 := Hafiza1^.BS;
        Hafiza2^.BO := Hafiza1;
      end;

      // 1. veri kayýt yapýsýnýn da silinmiþ olmasý halinde
      Hafiza2 := Hafiza1^.BO;
      if(Hafiza2^.U = 0) then
      begin

        // 1. veri kayýt yapýsýnýn bir sonraki veri kayýt yapýsýný, 3. veri kayýt yapýsýna baðla
        Hafiza2^.BS := Hafiza1^.BS;

        // 3. veri kayýt yapýsýnýn bir önceki veri kayýt yapýsýný, 1. veri kayýt yapýsýna baðla
        Hafiza2 := Hafiza1^.BS;
        Hafiza2^.BO := Hafiza1^.BO;

        // 2. veri kayýt yapýsýný sil
        Hafiza1^.BO := nil;
        Hafiza1^.BS := nil;
      end;
    end;

    Result := 0;
  end
  else
  begin

    //SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'ELRFreeMemSizeYeni.Uzunluk Hatalý', []);
    Result := 1;
  end;

  KritikBolgedenCik(GercekBellekKilit);
end;

function ELRMemSizeYeni(ABellek: Isaretci): TSayi4;
var
  Hafiza: PHafiza;
begin

  Hafiza := Isaretci(ABellek) - SizeOf(THafiza);
  Result := Hafiza^.U;
end;

procedure BilgiVer;
var
  i: TSayi4;
  P: PHafiza;
begin

  i := 1;

  P := YBYAdresIlk;

  while P <> nil do
  begin

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Bellek%d BÖ: %x', [i, TSayi4(P^.BO)]);
    SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Bellek%d BS: %x', [i, TSayi4(P^.BS)]);
    SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Bellek%d U: %d', [i, TSayi4(P^.U)]);

    P := P^.BS;
    Inc(i);
  end;
end;

function ELRAllocMemYeni(AUzunluk: TSayi4): Isaretci;
begin

  Result := ELRGetMemYeni(AUzunluk);
end;

function ELRReAllocMemYeni(var ABellek: Isaretci; AUzunluk: TSayi4): Isaretci;
begin

  if(ABellek = nil) then

    Result := ELRGetMemYeni(AUzunluk)
  else
  begin

    ELRFreeMemSizeYeni(ABellek, AUzunluk);
    Result := ELRGetMemYeni(AUzunluk);
  end;
end;

{==============================================================================
  verilen deðeri 4'ün katlarýna yuvarlar
 ==============================================================================}
function Yasla4Byte(ADeger: TSayi4): TSayi4;
var
  i: TSayi4;
begin

  if((ADeger and 3) = 0) then

    Result := ADeger
  else
  begin

    i := ADeger;
    i := i shr 2;
    Inc(i);
    i := i shl 2;
    Result := i;
  end;
end;

end.
