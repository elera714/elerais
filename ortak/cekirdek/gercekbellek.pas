{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: gercekbellek.pas
  Dosya Ýþlevi: gerçek (fiziksel) bellek yönetim iþlevlerini içerir

  Güncelleme Tarihi: 10/05/2025

  Bilgi: Bellek rezervasyonlarý 4K blok ve katlarý halinde yönetilmektedir

 ==============================================================================}
{$mode objfpc}
unit gercekbellek;

interface

uses paylasim;

type
  PGercekBellek = ^TGercekBellek;
  TGercekBellek = object
  private
    FToplamRAM, FToplamBlok,
    FAyrilmisBlok, FKullanilmisBlok: TSayi4;
  public
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
  BellekYonetimFPC: TMemoryManager;

function ELRGetMem(AUzunluk: TSayi4): Isaretci;
function ELRFreeMemSize(ABellek: Isaretci; AUzunluk: TSayi4): TSayi4;

implementation

uses genel, sistemmesaj;

{==============================================================================
  bellek yükleme / haritalama iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure TGercekBellek.Yukle;
var
  i, ToplamBellekMiktari: TSayi4;
  Bellek: PSayi1;
begin

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
  BellekYonetimFPC.GetMem := @ELRGetMem;
  BellekYonetimFPC.FreeMem := nil;
  BellekYonetimFPC.FreeMemSize := @ELRFreeMemSize;
  BellekYonetimFPC.AllocMem := nil;
  BellekYonetimFPC.ReAllocMem := nil;
  BellekYonetimFPC.MemSize := nil;
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
  0    byte..4095 byte arasý 1 blok
  4096 byte..8191 byte arasý 2 blok tahsis edilir
 ==============================================================================}
function TGercekBellek.Ayir(AIstenenBellek: TSayi4): Isaretci;
var
  IlkBlok: TISayi4;
  IstenenBellek, BlokSayisi,
  i: TSayi4;
  Bellek: PByte;
begin

  // AIstenenBellek = byte türünden istenen bellek miktarý
  // 0..4095 arasý 1 blok tasarýmý
  IstenenBellek := AIstenenBellek;

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
  i: TSayi4;
  Bellek: PByte;
begin

  // bellek adresini ve uzunluðunu blok numarasýna çevir
  IlkBlok := (TSayi4(ABellekAdresi) shr 12);
  BlokSayisi := (ABellekUzunlugu shr 12) + 1;

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

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ELRGetMem-U: %d', [AUzunluk]);
  Result := GGercekBellek.Ayir(AUzunluk);
end;

// sistemden alýnan belleði serbest býrak - fpc + çekirdek iþlevleri için
function ELRFreeMemSize(ABellek: Isaretci; AUzunluk: TSayi4): TSayi4;
begin

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ELRFreeMemSize: %d', [AUzunluk]);
  GGercekBellek.YokEt(ABellek, AUzunluk);
  Result := 0;
end;

end.
