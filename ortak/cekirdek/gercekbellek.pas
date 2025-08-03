{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: gercekbellek.pas
  Dosya Ýþlevi: gerçek (fiziksel) bellek yönetim iþlevlerini içerir

  Güncelleme Tarihi: 23/07/2025

  Bilgi: Bellek rezervasyonlarý 4K blok ve katlarý halinde yönetilmektedir

 ==============================================================================}
{$mode objfpc}
unit gercekbellek;

interface

uses paylasim;

type
  PHafiza = ^THafiza;
  THafiza = record
    U: TSayi4;
    BO,
    BS: Isaretci;
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

implementation

uses genel, sistemmesaj;

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
  SiraNo, i: TSayi4;
begin

  while KritikBolgeyeGir(GercekBellekKilit) = False do;

  if(AUzunluk = 0) then
  begin

    KritikBolgedenCik(GercekBellekKilit);
    Exit(nil);
  end;

  Hafiza1 := YBYAdresIlk;
  Hafiza2 := nil;
  SiraNo := 0;

  repeat

    if(Hafiza1^.U = 0) then
    begin

      // en sona ekleme yap
      if(Hafiza1^.BS = nil) then
      begin

        // yeterince bellek mevcut mu?
        YBYAdresMevcut := Isaretci(Hafiza1) + AUzunluk + 12;
        if(YBYAdresMevcut > YBYAdresSon) then Break;

        // yeni baðlantý oluþtur
        Hafiza1^.BO := Hafiza2;
        Hafiza1^.BS := nil;
        Hafiza1^.U := AUzunluk;

        // en sona eklenen bu baðlantýyý bir öncekine baðla
        if not(Hafiza2 = nil) then Hafiza2^.BS := Hafiza1;

        FillByte(PChar(Isaretci(Hafiza1) + SizeOf(THafiza))^, AUzunluk, 0);

        GercekBellek0.FKullanilanYBYBellek += AUzunluk + 12;

        KritikBolgedenCik(GercekBellekKilit);

        Exit(Isaretci(Hafiza1) + SizeOf(THafiza));
      end
      else
      begin

        i := TSayi4(Hafiza1^.BS) - TSayi4(Hafiza1) - SizeOf(THafiza);

        // boþ bellek miktarý ile istenen bellek miktarý ayný ise
        if(AUzunluk = i) then
        begin

          Hafiza1^.U := AUzunluk;

          GercekBellek0.FKullanilanYBYBellek += AUzunluk + 12;

          KritikBolgedenCik(GercekBellekKilit);

          Exit(Isaretci(Hafiza1) + SizeOf(THafiza));
        end
        // 1.1 boþ bellek miktarý istenen bellek miktarýndan küçük
        // 1.2 yeni bir girdi oluþturmak için (12 byte) yeterli ise
        else if(AUzunluk < i) and ((i - AUzunluk) >= 12) then
        begin

          // daha önce ayrýlan ve serbest býrakýlan bellek bölgesi için
          // sýnýr baðlantý noktasý oluþturuluyor
          HafizaYeni := Isaretci(Hafiza1) + SizeOf(THafiza) + AUzunluk;
          HafizaYeni^.BO := Hafiza1;
          HafizaYeni^.BS := Hafiza1^.BS;
          HafizaYeni^.U := i - AUzunluk - 12;

          // bir sonraki baðlantýnýn bir önceki baðlantýsý yeni baðlantý olarak belirleniyor
          Hafiza2 := Hafiza1^.BS;
          Hafiza2^.BO := HafizaYeni;

          // bir önceki baðlantýnýn bir sonraki baðlantýsý yeni baðlantý olarak belirleniyor
          Hafiza1^.BS := HafizaYeni;
          Hafiza1^.U := AUzunluk;

          GercekBellek0.FKullanilanYBYBellek += AUzunluk + 12;

          KritikBolgedenCik(GercekBellekKilit);

          Exit(Isaretci(Hafiza1) + SizeOf(THafiza));
        end
        else
        begin

          Hafiza2 := Hafiza1;
          Hafiza1 := Hafiza1^.BS;
        end;
      end;
    end
    else
    begin

      Hafiza2 := Hafiza1;
      Hafiza1 := Isaretci(Hafiza1) + SizeOf(THafiza) + Hafiza1^.U;
    end;

    Inc(SiraNo);

  until True = False;

  KritikBolgedenCik(GercekBellekKilit);

  Result := nil;
end;

function ELRFreeMemSizeYeni(ABellek: Isaretci; AUzunluk: TSayi4): TSayi4;
var
  Hafiza1, Hafiza2: PHafiza;
  YBMAdresMevcut: Isaretci;
  i, j: TSayi4;
begin

  while KritikBolgeyeGir(GercekBellekKilit) = False do;

  // bellek yönetimi, her zaman için bir sonrakini silme, bir öncekine eklenme
  // mantýðý içerisinde çalýþmaktadýr

  Hafiza1 := Isaretci(ABellek) - 12;

  // uzunluk deðerinin 0 verilmesi durumunda uzunluk kontrolü yapmaksýzýn belleði boþalt
  if(AUzunluk = 0) then AUzunluk := Hafiza1^.U;

  if(Hafiza1^.U = AUzunluk) then
  begin

    // en baþtaki kaydýn silinmesi
    if(Hafiza1^.BO = nil) then
    begin

      GercekBellek0.FKullanilanYBYBellek -= AUzunluk + 12;

      Hafiza1^.U := 0;

      // baþtaki kaydýn bir sonraki kaydýnýn da silinmiþ olmasý halinde
      Hafiza2 := Hafiza1^.BS;
      if(Hafiza2^.U = 0) then
      begin

        // baþtaki kaydýn bir sonraki kaydýnýn bir sonrakini baþtaki kayda baðla
        Hafiza1^.BS := Hafiza2^.BS;

        // baþtaki kaydýn bir sonraki kaydýný sil
        Hafiza2^.BO := nil;
        Hafiza2^.BS := nil;

        // baþtaki kaydý, baþtaki kaydýn bir sonraki kaydýnýn bir sonrakine baðla
        Hafiza2 := Hafiza1^.BS;
        Hafiza2^.BO := Hafiza1;
      end;
    end
    // en sondaki kaydýn silinmesi
    else if(Hafiza1^.BS = nil) then
    begin

      GercekBellek0.FKullanilanYBYBellek -= AUzunluk + 12;

      // baðlantýnýn bir önceki baðlantýsýyla iliþkisini kes
      Hafiza2 := Hafiza1^.BO;
      if not(Hafiza2 = nil) then Hafiza2^.BS := nil;

      // mevcut baðlantýyý sil
      Hafiza1^.BO := nil;
      Hafiza1^.BS := nil;
      Hafiza1^.U := 0;

      // son kayýttan bir önceki kayýt daha önce silinmiþse (0 olarak iþaretlenmiþse)
      // bir önceki kaydý da sil
      if not(Hafiza2 = nil) and (Hafiza2^.U = 0) then
      begin

        // bir önceki kaydý silmeden önce kendisinden önceki kayýt ile iliþkisini kes
        Hafiza1 := Hafiza2^.BO;
        Hafiza1^.BS := nil;

        // bir önceki kaydý da sil
        Hafiza2^.BO := nil;
        Hafiza2^.BS := nil;
        Hafiza2^.U := 0;
      end;
    end
    else
    // ortaki kaydýn silinmesi
    begin

      GercekBellek0.FKullanilanYBYBellek -= AUzunluk + 12;

      // kayýt son kayýt deðilse sadece kaydýn uzunluðunu sýfýrla
      Hafiza1^.U := 0;

      // ortaki kaydýn bir sonraki kaydýnýn da silinmiþ olmasý halinde
      Hafiza2 := Hafiza1^.BS;
      if(Hafiza2^.U = 0) then
      begin

        // bir sonraki silinmiþ kaydýn bir sonraki baðlantýsýný silinen bu baðlantýya baðla
        Hafiza1^.BS := Hafiza2^.BS;

        // bir sonraki silinmiþ kaydý sil
        Hafiza2^.BO := nil;
        Hafiza2^.BS := nil;
        Hafiza2^.U := 0;

        // silinen bu baðlantýyý, bir sonraki silinmiþ kaydýn bir sonraki baðlantýsýna baðla
        Hafiza2 := Hafiza1^.BS;
        Hafiza2^.BO := Hafiza1;
      end;

      // ortaki kaydýn bir önceki kaydýnýn da silinmiþ olmasý halinde
      // mevcut kaydý bir önceki kayda baðla
      Hafiza2 := Hafiza1^.BO;
      if(Hafiza2^.U = 0) then
      begin

        // bir önceki kaydý bir sonraki kayda baðla
        Hafiza2^.BS := Hafiza1^.BS;

        // bir sonraki kaydý bir önceki kayda baðla
        Hafiza2 := Hafiza1^.BS;
        Hafiza2^.BO := Hafiza1^.BO;

        // mevcut kaydý sil
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

  Hafiza := Isaretci(ABellek) - 12;
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

end.
