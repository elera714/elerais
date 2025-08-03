{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: gercekbellek.pas
  Dosya ��levi: ger�ek (fiziksel) bellek y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 23/07/2025

  Bilgi: Bellek rezervasyonlar� 4K blok ve katlar� halinde y�netilmektedir

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
  // yeni bellek y�neticisi
  YBYAdresIlk,
  YBYAdresSon: Isaretci;

{==============================================================================
  bellek y�kleme / haritalama i�levlerini ger�ekle�tirir
 ==============================================================================}
procedure TGercekBellek.Yukle;
var
  i, ToplamBellekMiktari: TSayi4;
  Bellek: PSayi1;
begin

  { TODO - �u a�amada 40 .. 60 mb aras� Yeni Bellek Y�netimine tahsis edildi
    �nemli: 2 bellek y�netimi tekle�tirilmeli }
  YBYAdresIlk := Isaretci(40 * 1024 * 1024);      // $2800000
  YBYAdresSon := Isaretci(64 * 1024 * 1024);      // $4000000

  FToplamYBYBellek := (64 - 40) * 1024 * 1024;
  FKullanilanYBYBellek := 0;

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
  1    byte..4096 byte aras� 1 blok
  4097 byte..8192 byte aras� 2 blok tahsis edilir
 ==============================================================================}
function TGercekBellek.Ayir(AIstenenBellek: TSayi4): Isaretci;
var
  IlkBlok: TISayi4;
  IstenenBellek, BlokSayisi,
  i: TSayi4;
  Bellek: PByte;
begin

  // istenen bellek boyutu 0 ise hata vererek ��k
  if(AIstenenBellek = 0) then Exit(nil);

  // AIstenenBellek = byte t�r�nden istenen bellek miktar�
  // 1..4096 aras� 1 blok tasar�m�
  IstenenBellek := AIstenenBellek - 1;

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
  BellekUzunlugu,
  i: TSayi4;
  Bellek: PByte;
begin

  BellekUzunlugu := ABellekUzunlugu - 1;

  // bellek adresini ve uzunlu�unu blok numaras�na �evir
  IlkBlok := (TSayi4(ABellekAdresi) shr 12);
  BlokSayisi := (BellekUzunlugu shr 12) + 1;

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

  Result := GercekBellek0.Ayir(AUzunluk);

  if(BellekDegeriniGoster) then begin
  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ELRGetMem.Result: $%x', [Result]);
  SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'ELRGetMem.AUzunluk: %d', [AUzunluk]); end;
end;

// sistemden al�nan belle�i serbest b�rak - fpc + �ekirdek i�levleri i�in
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

        // yeni ba�lant� olu�tur
        Hafiza1^.BO := Hafiza2;
        Hafiza1^.BS := nil;
        Hafiza1^.U := AUzunluk;

        // en sona eklenen bu ba�lant�y� bir �ncekine ba�la
        if not(Hafiza2 = nil) then Hafiza2^.BS := Hafiza1;

        FillByte(PChar(Isaretci(Hafiza1) + SizeOf(THafiza))^, AUzunluk, 0);

        GercekBellek0.FKullanilanYBYBellek += AUzunluk + 12;

        KritikBolgedenCik(GercekBellekKilit);

        Exit(Isaretci(Hafiza1) + SizeOf(THafiza));
      end
      else
      begin

        i := TSayi4(Hafiza1^.BS) - TSayi4(Hafiza1) - SizeOf(THafiza);

        // bo� bellek miktar� ile istenen bellek miktar� ayn� ise
        if(AUzunluk = i) then
        begin

          Hafiza1^.U := AUzunluk;

          GercekBellek0.FKullanilanYBYBellek += AUzunluk + 12;

          KritikBolgedenCik(GercekBellekKilit);

          Exit(Isaretci(Hafiza1) + SizeOf(THafiza));
        end
        // 1.1 bo� bellek miktar� istenen bellek miktar�ndan k���k
        // 1.2 yeni bir girdi olu�turmak i�in (12 byte) yeterli ise
        else if(AUzunluk < i) and ((i - AUzunluk) >= 12) then
        begin

          // daha �nce ayr�lan ve serbest b�rak�lan bellek b�lgesi i�in
          // s�n�r ba�lant� noktas� olu�turuluyor
          HafizaYeni := Isaretci(Hafiza1) + SizeOf(THafiza) + AUzunluk;
          HafizaYeni^.BO := Hafiza1;
          HafizaYeni^.BS := Hafiza1^.BS;
          HafizaYeni^.U := i - AUzunluk - 12;

          // bir sonraki ba�lant�n�n bir �nceki ba�lant�s� yeni ba�lant� olarak belirleniyor
          Hafiza2 := Hafiza1^.BS;
          Hafiza2^.BO := HafizaYeni;

          // bir �nceki ba�lant�n�n bir sonraki ba�lant�s� yeni ba�lant� olarak belirleniyor
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

  // bellek y�netimi, her zaman i�in bir sonrakini silme, bir �ncekine eklenme
  // mant��� i�erisinde �al��maktad�r

  Hafiza1 := Isaretci(ABellek) - 12;

  // uzunluk de�erinin 0 verilmesi durumunda uzunluk kontrol� yapmaks�z�n belle�i bo�alt
  if(AUzunluk = 0) then AUzunluk := Hafiza1^.U;

  if(Hafiza1^.U = AUzunluk) then
  begin

    // en ba�taki kayd�n silinmesi
    if(Hafiza1^.BO = nil) then
    begin

      GercekBellek0.FKullanilanYBYBellek -= AUzunluk + 12;

      Hafiza1^.U := 0;

      // ba�taki kayd�n bir sonraki kayd�n�n da silinmi� olmas� halinde
      Hafiza2 := Hafiza1^.BS;
      if(Hafiza2^.U = 0) then
      begin

        // ba�taki kayd�n bir sonraki kayd�n�n bir sonrakini ba�taki kayda ba�la
        Hafiza1^.BS := Hafiza2^.BS;

        // ba�taki kayd�n bir sonraki kayd�n� sil
        Hafiza2^.BO := nil;
        Hafiza2^.BS := nil;

        // ba�taki kayd�, ba�taki kayd�n bir sonraki kayd�n�n bir sonrakine ba�la
        Hafiza2 := Hafiza1^.BS;
        Hafiza2^.BO := Hafiza1;
      end;
    end
    // en sondaki kayd�n silinmesi
    else if(Hafiza1^.BS = nil) then
    begin

      GercekBellek0.FKullanilanYBYBellek -= AUzunluk + 12;

      // ba�lant�n�n bir �nceki ba�lant�s�yla ili�kisini kes
      Hafiza2 := Hafiza1^.BO;
      if not(Hafiza2 = nil) then Hafiza2^.BS := nil;

      // mevcut ba�lant�y� sil
      Hafiza1^.BO := nil;
      Hafiza1^.BS := nil;
      Hafiza1^.U := 0;

      // son kay�ttan bir �nceki kay�t daha �nce silinmi�se (0 olarak i�aretlenmi�se)
      // bir �nceki kayd� da sil
      if not(Hafiza2 = nil) and (Hafiza2^.U = 0) then
      begin

        // bir �nceki kayd� silmeden �nce kendisinden �nceki kay�t ile ili�kisini kes
        Hafiza1 := Hafiza2^.BO;
        Hafiza1^.BS := nil;

        // bir �nceki kayd� da sil
        Hafiza2^.BO := nil;
        Hafiza2^.BS := nil;
        Hafiza2^.U := 0;
      end;
    end
    else
    // ortaki kayd�n silinmesi
    begin

      GercekBellek0.FKullanilanYBYBellek -= AUzunluk + 12;

      // kay�t son kay�t de�ilse sadece kayd�n uzunlu�unu s�f�rla
      Hafiza1^.U := 0;

      // ortaki kayd�n bir sonraki kayd�n�n da silinmi� olmas� halinde
      Hafiza2 := Hafiza1^.BS;
      if(Hafiza2^.U = 0) then
      begin

        // bir sonraki silinmi� kayd�n bir sonraki ba�lant�s�n� silinen bu ba�lant�ya ba�la
        Hafiza1^.BS := Hafiza2^.BS;

        // bir sonraki silinmi� kayd� sil
        Hafiza2^.BO := nil;
        Hafiza2^.BS := nil;
        Hafiza2^.U := 0;

        // silinen bu ba�lant�y�, bir sonraki silinmi� kayd�n bir sonraki ba�lant�s�na ba�la
        Hafiza2 := Hafiza1^.BS;
        Hafiza2^.BO := Hafiza1;
      end;

      // ortaki kayd�n bir �nceki kayd�n�n da silinmi� olmas� halinde
      // mevcut kayd� bir �nceki kayda ba�la
      Hafiza2 := Hafiza1^.BO;
      if(Hafiza2^.U = 0) then
      begin

        // bir �nceki kayd� bir sonraki kayda ba�la
        Hafiza2^.BS := Hafiza1^.BS;

        // bir sonraki kayd� bir �nceki kayda ba�la
        Hafiza2 := Hafiza1^.BS;
        Hafiza2^.BO := Hafiza1^.BO;

        // mevcut kayd� sil
        Hafiza1^.BO := nil;
        Hafiza1^.BS := nil;
      end;
    end;

    Result := 0;
  end
  else
  begin

    //SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'ELRFreeMemSizeYeni.Uzunluk Hatal�', []);
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

    SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Bellek%d B�: %x', [i, TSayi4(P^.BO)]);
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
