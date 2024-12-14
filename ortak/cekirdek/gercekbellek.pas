{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gercekbellek.pas
  Dosya İşlevi: gerçek (fiziksel) bellek yönetim işlevlerini içerir

  Güncelleme Tarihi: 24/11/2019

  Bilgi: Bellek rezervasyonları 4K blok ve katları halinde yönetilmektedir

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

implementation

uses genel;

{==============================================================================
  bellek yükleme / haritalama işlevlerini gerçekleştirir
 ==============================================================================}
procedure TGercekBellek.Yukle;
var
  i, ii, _ToplamBellekMiktari: TSayi4;
  Bellek: PSayi1;
begin

  _ToplamBellekMiktari := ToplamBellekMiktariniAl;

  // sistemdeki toplam RAM miktarı
  FToplamRAM := _ToplamBellekMiktari;

  // RAM miktarını blok sayısına çevir. (1 blok = 4K)
  FToplamBlok := (FToplamRAM shr 12);

  // çekirdek için bellek ayrımını gerçekleştir
  ii := (SISTEME_AYRILMIS_RAM shr 12);
  FAyrilmisBlok := ii;
  FKullanilmisBlok := ii;

  // tüm belleği boş olarak işaretle
  Bellek := BELLEK_HARITA_ADRESI;
  for i := 0 to FToplamBlok - 1 do
  begin

    Bellek^ := 0;
    Inc(Bellek);
  end;

  // sisteme ayrılan belleği kullanılıyor olarak işaretle
  Bellek := BELLEK_HARITA_ADRESI;
  for i := 0 to AyrilmisBlok - 1 do
  begin

    Bellek^ := 1;
    Inc(Bellek);
  end;
end;

{$asmmode intel}
function TGercekBellek.ToplamBellekMiktariniAl: TSayi4;
var
  _ToplamBellek: TSayi4;
begin

  asm
    pushad

    // önbellek işlemini durdur
    mov   eax, cr0
    and   eax, not($40000000 + $20000000)
    or    eax, $40000000
    mov   cr0, eax
    wbinvd

    xor   edi, edi
    mov   ebx, '1234'
  @tekrar:
    add     edi, $100000
    xchg    ebx, dword [edi]
    cmp     dword [edi], '1234'
    xchg    ebx, dword [edi]
    je      @tekrar

    // önbellek işlemine devam et
    and     eax, not($40000000 + $20000000)
    mov     cr0, eax

    mov   _ToplamBellek,edi

    popad
  end;

  Result := _ToplamBellek;
end;

{==============================================================================
  boş bellek alanını rezerv eder ve bellek bölgesini sıfırlar
 ==============================================================================}
function TGercekBellek.Ayir(AIstenenBellek: TSayi4): Isaretci;
var
  IlkBlok: TISayi4;
  BlokSayisi, i: TSayi4;
  Bellek: PByte;
begin

  // AIstenenBellek = byte türünden istenen bellek miktarı
  BlokSayisi := (AIstenenBellek shr 12) + 1;

  // boş bellek alanı bul
  IlkBlok := BosBellekBul(BlokSayisi);

  if(IlkBlok = -1) then
  begin

    Result := nil;
    Exit;
  end;

  Bellek := BELLEK_HARITA_ADRESI;
  Inc(Bellek, IlkBlok);

  // bellek bloğunu kullanılıyor olarak işaretle
  for i := 0 to BlokSayisi - 1 do
  begin

    Bellek^ := 1;
    Inc(Bellek);
  end;

  // bellek bölgesini sıfır ile doldur
  i := (IlkBlok shl 12);
  FillByte(Isaretci(i)^, AIstenenBellek, 0);

  Inc(FKullanilmisBlok, BlokSayisi);

  Result := Isaretci(i);
end;

{==============================================================================
  ayrılmış belleği iptal eder
 ==============================================================================}
procedure TGercekBellek.YokEt(ABellekAdresi: Isaretci; ABellekUzunlugu: TSayi4);
var
  IlkBlok, BlokSayisi, i: TSayi4;
  Bellek: PByte;
begin

  // bellek adresini ve uzunluğunu blok numarasına çevir
  IlkBlok := (TSayi4(ABellekAdresi) shr 12);
  BlokSayisi := (ABellekUzunlugu shr 12) + 1;

  Bellek := BELLEK_HARITA_ADRESI;
  Inc(Bellek, IlkBlok);

  // belirtilen blok sayısı kadar iptal işlemi gerçekleştir
  for i := 0 to BlokSayisi - 1 do
  begin

    Bellek^ := 0;
    Inc(Bellek);
  end;

  Dec(FKullanilmisBlok, BlokSayisi);
end;

{==============================================================================
  boş bellek alanı bulur (not : bulunan boş alan ayrılmaz)
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

  // ayrılmış bloktan toplam blok sayısına kadar tüm bellek bloklarını ara
  while (AranacakIlkBlok < AranacakSonBlok) do
  begin

    // eğer boş blok var ise ...
    if(Bellek^ = 0) then
    begin

      // bulunan blok numarasını kaydet
      BulunanIlkBlok := AranacakIlkBlok;
      BellekBulundu := True;

      // talep edilen blok kadar arama yap
      for i := 0 to AIstenenBlokSayisi - 1 do
      begin

        // eğer aranan blok daha önce ayrıldıysa arama işlemini durdur
        if(Bellek^ = 1) then
        begin

          BellekBulundu := False;
          Break;
        end
        else
        begin

          // aksi halde bir sonraki bloğa bak
          Inc(Bellek);
          Inc(AranacakIlkBlok);
        end;
      end;

      if(BellekBulundu) then
      begin

        // istenen bloklar ardışık olarak boş ise
        // ilk blok numarasını geri döndür ve çık
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

end.
