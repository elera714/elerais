{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: gercekbellek.pas
  Dosya ��levi: ger�ek (fiziksel) bellek y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 10/05/2025

  Bilgi: Bellek rezervasyonlar� 4K blok ve katlar� halinde y�netilmektedir

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
  bellek y�kleme / haritalama i�levlerini ger�ekle�tirir
 ==============================================================================}
procedure TGercekBellek.Yukle;
var
  i, ToplamBellekMiktari: TSayi4;
  Bellek: PSayi1;
begin

  ToplamBellekMiktari := ToplamBellekMiktariniAl;

  // sistemdeki toplam RAM miktar�
  FToplamRAM := ToplamBellekMiktari;

  // RAM miktar�n� blok say�s�na �evir. (1 blok = 4K)
  FToplamBlok := (FToplamRAM shr 12);

  // �ekirdek i�in bellek ayr�m�n� ger�ekle�tir
  i := (SISTEME_AYRILMIS_RAM shr 12);
  FAyrilmisBlok := i;
  FKullanilmisBlok := i;

  // t�m belle�i bo� olarak i�aretle
  Bellek := BELLEK_HARITA_ADRESI;
  for i := 0 to FToplamBlok - 1 do
  begin

    Bellek^ := 0;
    Inc(Bellek);
  end;

  // sisteme ayr�lan belle�i kullan�l�yor olarak i�aretle
  Bellek := BELLEK_HARITA_ADRESI;
  for i := 0 to AyrilmisBlok - 1 do
  begin

    Bellek^ := 1;
    Inc(Bellek);
  end;

  // �ekirdek bellek y�netim i�levlerini y�kle
  BellekYonetimFPC.NeedLock := False;     // eski i�lev
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

  // �nbellek i�lemini durdur
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

  // �nbellek i�lemine devam et
  and   eax,not($40000000 + $20000000)
  mov   cr0,eax

  mov   i,edi

  popad
end;

  Result := i;
end;

{==============================================================================
  bo� bellek alan�n� rezerv eder ve bellek b�lgesini s�f�rlar
  bilgi: istenen bellek miktar� 4096 byte ve katlar� olarak tahsis edilir
  0    byte..4095 byte aras� 1 blok
  4096 byte..8191 byte aras� 2 blok tahsis edilir
 ==============================================================================}
function TGercekBellek.Ayir(AIstenenBellek: TSayi4): Isaretci;
var
  IlkBlok: TISayi4;
  IstenenBellek, BlokSayisi,
  i: TSayi4;
  Bellek: PByte;
begin

  // AIstenenBellek = byte t�r�nden istenen bellek miktar�
  // 0..4095 aras� 1 blok tasar�m�
  IstenenBellek := AIstenenBellek;

  BlokSayisi := (IstenenBellek shr 12) + 1;

  // bo� bellek alan� bul
  IlkBlok := BosBellekBul(BlokSayisi);
  if(IlkBlok < 0) then Exit(nil);

  Bellek := BELLEK_HARITA_ADRESI;
  Inc(Bellek, IlkBlok);

  // bellek blo�unu kullan�l�yor olarak i�aretle
  for i := 0 to BlokSayisi - 1 do
  begin

    Bellek^ := 1;
    Inc(Bellek);
  end;

  // bellek b�lgesini s�f�r ile doldur
  i := (IlkBlok shl 12);
  FillByte(Isaretci(i)^, BlokSayisi shl 12, 0);

  Inc(FKullanilmisBlok, BlokSayisi);

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Ayr�lan: Blok Say�s�: %d', [BlokSayisi]);
  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Ayr�lan: �lk Blok: %d', [IlkBlok]);

  Result := Isaretci(i);
end;

{==============================================================================
  ayr�lm�� belle�i iptal eder
 ==============================================================================}
procedure TGercekBellek.YokEt(ABellekAdresi: Isaretci; ABellekUzunlugu: TSayi4);
var
  IlkBlok, BlokSayisi,
  i: TSayi4;
  Bellek: PByte;
begin

  // bellek adresini ve uzunlu�unu blok numaras�na �evir
  IlkBlok := (TSayi4(ABellekAdresi) shr 12);
  BlokSayisi := (ABellekUzunlugu shr 12) + 1;

  Bellek := BELLEK_HARITA_ADRESI;
  Inc(Bellek, IlkBlok);

  // belirtilen blok say�s� kadar iptal i�lemi ger�ekle�tir
  for i := 0 to BlokSayisi - 1 do
  begin

    Bellek^ := 0;
    Inc(Bellek);
  end;

  Dec(FKullanilmisBlok, BlokSayisi);

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Yokedilen: Blok Say�s�: %d', [BlokSayisi]);
  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'Yokedilen: �lk Blok: %d', [IlkBlok]);
end;

{==============================================================================
  bo� bellek alan� bulur (not : bulunan bo� alan ayr�lmaz)
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

  // ayr�lm�� bloktan toplam blok say�s�na kadar t�m bellek bloklar�n� ara
  while (AranacakIlkBlok < AranacakSonBlok) do
  begin

    // e�er bo� blok var ise ...
    if(Bellek^ = 0) then
    begin

      // bulunan blok numaras�n� kaydet
      BulunanIlkBlok := AranacakIlkBlok;
      BellekBulundu := True;

      // talep edilen blok kadar arama yap
      for i := 0 to AIstenenBlokSayisi - 1 do
      begin

        // e�er aranan blok daha �nce ayr�ld�ysa arama i�lemini durdur
        if(Bellek^ = 1) then
        begin

          BellekBulundu := False;
          Break;
        end
        else
        begin

          // aksi halde bir sonraki blo�a bak
          Inc(Bellek);
          Inc(AranacakIlkBlok);
        end;
      end;

      if(BellekBulundu) then
      begin

        // istenen bloklar ard���k olarak bo� ise
        // ilk blok numaras�n� geri d�nd�r ve ��k
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

// istenen miktarda bellek ay�r - fpc + �ekirdek i�levleri i�in
function ELRGetMem(AUzunluk: TSayi4): Isaretci;
begin

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ELRGetMem-U: %d', [AUzunluk]);
  Result := GGercekBellek.Ayir(AUzunluk);
end;

// sistemden al�nan belle�i serbest b�rak - fpc + �ekirdek i�levleri i�in
function ELRFreeMemSize(ABellek: Isaretci; AUzunluk: TSayi4): TSayi4;
begin

  //SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ELRFreeMemSize: %d', [AUzunluk]);
  GGercekBellek.YokEt(ABellek, AUzunluk);
  Result := 0;
end;

end.
