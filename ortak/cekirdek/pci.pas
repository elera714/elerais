{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: pci.pas
  Dosya İşlevi: pci yönetim işlevlerini içerir

  Güncelleme Tarihi: 21/08/2026

 ==============================================================================}
{$mode objfpc}
unit pci;

interface

uses paylasim;

const
  // aygıt tipleri
  PCIAYGIT_AG_ETHERNET            = $0200;
  PCIAYGIT_CEVREBIRIM_DIGER       = $0880;

const
  PCI_ADRES           = $CF8;
  PCI_VERI            = $CFC;

  PCI_SATICI          = $00;    // 2 byte
  PCI_AYGIT           = $02;    // 2 byte
  PCI_KOMUT           = $04;    // 2 byte
  PCI_DURUM           = $06;    // 2 byte
  PCI_DEGISIM         = $08;    // 1 byte
  PCI_PROG_IF         = $09;    // 1 byte
  PCI_ALTSINIF        = $0A;    // 1 byte
  PCI_SINIF           = $0B;    // 1 byte
  PCI_CACHE_LINE_SIZE = $0C;    // 1 byte
  PCI_LATENCY_TIMER   = $0D;    // 1 byte
  PCI_BASLIK_TIPI     = $0E;    // 1 byte
  PCI_BIST            = $0F;    // 1 byte
  PCI_BAR0            = $10;    // 4 byte
  PCI_BAR1            = $14;    // 4 byte
  PCI_BAR2            = $18;    // 4 byte
  PCI_BAR3            = $1C;    // 4 byte
  PCI_BAR4            = $20;    // 4 byte
  PCI_BAR5            = $24;    // 4 byte
  PCI_KESME_NO        = $3C;    // 1 byte
  PCI_KESME_PIN       = $3D;    // 1 byte

  // kaydedilecek azami pci aygıt sayısı
  AZAMI_PCIAYGITSAYISI = 256;

type
  // programlar için pci veri yapısı
  PPCI3 = ^TPCI3;
  TPCI3 = packed record
    Yol, Aygit, Islev, AYRLD0: TSayi1;
    SaticiKimlik, AygitKimlik: TSayi2;
    SinifKod: TSayi4;
  end;

type
  // pci veri yapısı
  TPCI = class
  public
    FYol, FAygit, FIslev,
    FSaticiKimlik, FAygitKimlik,
    FSinifKod: TSayi4;
  end;

type
  // pci nesne kontrol yapısı
  PPCIAygitlar = ^TPCIAygitlar;
  TPCIAygitlar = class
  private
    FToplamAygit: TISayi4;
    FPCIAygitListesi: array[0..AZAMI_PCIAYGITSAYISI - 1] of TPCI;
    function Al(ASiraNo: TISayi4): TPCI;
    procedure Yaz(ASiraNo: TISayi4; APCI: TPCI);
  public
    constructor Create;
    function Oku1(AYol, AAygit, AIslev, ASiraNo: TSayi1): TSayi1;
    function Oku2(AYol, AAygit, AIslev, ASiraNo: TSayi1): TSayi2;
    function Oku4(AYol, AAygit, AIslev, ASiraNo: TSayi1): TSayi4;
    procedure Yaz1(AYol, AAygit, AIslev, ASiraNo: TSayi1; ADeger: TSayi1);
    procedure Yaz2(AYol, AAygit, AIslev, ASiraNo: TSayi1; ADeger: TSayi2);
    procedure Yaz4(AYol, AAygit, AIslev, ASiraNo: TSayi1; ADeger: TSayi4);
    function IlkPortDegeriniAl(APCI: TPCI): TSayi2;
    function IlkBellekDegeriniAl(APCI: TPCI): TSayi4;
    function IRQNoAl(APCI: TPCI): TSayi1;
    property ToplamAygit: TISayi4 read FToplamAygit write FToplamAygit;
    property PCI[ASiraNo: TISayi4]: TPCI read Al write Yaz;
  end;

var
  GPCIAygitlar: TPCIAygitlar;

implementation

uses aygityonetimi, port;

{==============================================================================
  sistemde mevcut pci aygıtlarının ana yükleme işlevlerini içerir
 ==============================================================================}
constructor TPCIAygitlar.Create;
var
  P: TPCI;
  Yol, Aygit, Islev,
  i: TSayi4;
begin

  // toplam aygıt sayısını sıfırla
  ToplamAygit := 0;

  // bellek girişlerini sıfırla
  for i := 0 to AZAMI_PCIAYGITSAYISI - 1 do PCI[i] := nil;

  // yol / aygıt / işlev girişlerini sorgula

  // 256 yol
  for Yol := 0 to 255 do
  begin

    // 32 aygıt
    for Aygit := 0 to 31 do
    begin

      // 8 işlev
      for Islev := 0 to 7 do
      begin

        // başlık (header) tipi
        i := Oku1(Yol, Aygit, Islev, PCI_BASLIK_TIPI);

        // aygıt çok işlevli ise bir sonraki işlevden devam et
        if(Islev = 0) and ((i and $80) <> 0) then Continue;

        // satıcı / aygıt bilgilerini al
        i := Oku4(Yol, Aygit, Islev, PCI_SATICI);

        // 0. işlevin satıcı ve aygıt değeri $FFFF ise diğer işlevleri
        // sorgulamaya gerek yok, işlevden çık
        if((Islev = 0) and (i = $FFFFFFFF)) then Break;

        // satıcı değeri $FFFF değilse devam et
        if((i and $FFFF) <> $FFFF) then
        begin

          // eğer azami aygıt sayısı aşılmamışsa
          if(ToplamAygit <= AZAMI_PCIAYGITSAYISI) then
          begin

            // yeni pci aygıt nesnesi oluştur
            P := TPCI.Create;

            // pci aygıt adresini listeye kaydet
            PCI[ToplamAygit] := P;

            // yol / aygıt / işlev bilgilerini kaydet
            P.FYol := Yol;
            P.FAygit := Aygit;
            P.FIslev := Islev;

            // satıcı / aygıt bilgilerini kaydet
            P.FSaticiKimlik := i and $FFFF;
            P.FAygitKimlik := ((i shr 16) and $FFFF);

            // aygıtın sınıfını al
            // Class Code[8bit] + SubClass[8bit] + ProgIF[8bit] + Revision ID[8bit]
            // üst 24 bit sınıf kodu, alt 8 bit revizyon kodu
            P.FSinifKod := Oku4(Yol, Aygit, Islev, 8);

            // aygıtı yüklenecek aygıt listesine ekle
            GAygitlar.AygitiSistemeKaydet(P);

            // aygıt sayısını bir artır
            i := FToplamAygit;
            Inc(i);
            FToplamAygit := i;
          end;
        end;
      end;
    end;
  end;
end;

function TPCIAygitlar.Al(ASiraNo: TISayi4): TPCI;
begin

  if(ASiraNo >= 0) and (ASiraNo <= ToplamAygit) then
    Result := FPCIAygitListesi[ASiraNo]
  else Result := nil;
end;

procedure TPCIAygitlar.Yaz(ASiraNo: TISayi4; APCI: TPCI);
begin

  if(ASiraNo >= 0) and (ASiraNo <= AZAMI_PCIAYGITSAYISI) then
    FPCIAygitListesi[ASiraNo] := APCI;
end;

{==============================================================================
  belirtilen aygıtın sıra değerinden 1 byte değer okur
 ==============================================================================}
function TPCIAygitlar.Oku1(AYol, AAygit, AIslev, ASiraNo: TSayi1): TSayi1;
var
  i: TSayi4;
begin

  //  ASiraNo = bit 2..7, AIslev = bit 8..10
  //  AAygit = bit 11..15, AYol = bit 16..31
  i := $80000000 + (AYol shl 16) + (AAygit shl 11) + (AIslev shl 8) + (ASiraNo and $FC);

  PortYaz4(PCI_ADRES, i);
  Result := PortAl1(PCI_VERI)
end;

{==============================================================================
  belirtilen aygıtın sıra değerinden 2 byte değer okur
 ==============================================================================}
function TPCIAygitlar.Oku2(AYol, AAygit, AIslev, ASiraNo: TSayi1): TSayi2;
var
  i: TSayi4;
begin

  i := $80000000 + (AYol shl 16) + (AAygit shl 11) + (AIslev shl 8) + (ASiraNo and $FC);

  PortYaz4(PCI_ADRES, i);
  Result := PortAl2(PCI_VERI)
end;

{==============================================================================
  belirtilen aygıtın sıra değerinden 4 byte değer okur
 ==============================================================================}
function TPCIAygitlar.Oku4(AYol, AAygit, AIslev, ASiraNo: TSayi1): TSayi4;
var
  i: TSayi4;
begin

  i := $80000000 + (AYol shl 16) + (AAygit shl 11) + (AIslev shl 8) + (ASiraNo and $FC);

  PortYaz4(PCI_ADRES, i);
  Result := PortAl4(PCI_VERI)
end;

{==============================================================================
  belirtilen aygıtın sıra değerine 1 byte değer yazar
 ==============================================================================}
procedure TPCIAygitlar.Yaz1(AYol, AAygit, AIslev, ASiraNo: TSayi1; ADeger: TSayi1);
var
  i: TSayi4;
begin

  i := $80000000 + (AYol shl 16) + (AAygit shl 11) + (AIslev shl 8) + (ASiraNo and $FC);

  PortYaz4(PCI_ADRES, i);
  PortYaz1(PCI_VERI, ADeger)
end;

{==============================================================================
  belirtilen aygıtın sıra değerine 2 byte değer yazar
 ==============================================================================}
procedure TPCIAygitlar.Yaz2(AYol, AAygit, AIslev, ASiraNo: TSayi1; ADeger: TSayi2);
var
  i: TSayi4;
begin

  i := $80000000 + (AYol shl 16) + (AAygit shl 11) + (AIslev shl 8) + (ASiraNo and $FC);

  PortYaz4(PCI_ADRES, i);
  PortYaz2(PCI_VERI, ADeger)
end;

{==============================================================================
  belirtilen aygıtın sıra değerine 4 byte değer yazar
 ==============================================================================}
procedure TPCIAygitlar.Yaz4(AYol, AAygit, AIslev, ASiraNo: TSayi1; ADeger: TSayi4);
var
  i: TSayi4;
begin

  i := $80000000 + (AYol shl 16) + (AAygit shl 11) + (AIslev shl 8) + (ASiraNo and $FC);

  PortYaz4(PCI_ADRES, i);
  PortYaz4(PCI_VERI, ADeger)
end;

{==============================================================================
  pci aygıtının ilk iletişim port değerini alır
 ==============================================================================}
function TPCIAygitlar.IlkPortDegeriniAl(APCI: TPCI): TSayi2;
var
  Adres: TSayi1;
  Deger, i: TSayi4;
begin

  Adres := PCI_BAR0;
  for i := 1 to 6 do
  begin

    Deger := Oku4(APCI.FYol, APCI.FAygit, APCI.FIslev, Adres);
    if((Deger and 1) = 1) then Exit(Deger and (not %11));

    Adres := Adres + 4;
  end;

  Result := 0;
end;

{==============================================================================
  pci aygıtının ilk iletişim bellek değerini alır
 ==============================================================================}
function TPCIAygitlar.IlkBellekDegeriniAl(APCI: TPCI): TSayi4;
var
  Adres: TSayi1;
  Deger, i: TSayi4;
begin

  Adres := PCI_BAR0;
  for i := 1 to 6 do
  begin

    Deger := Oku4(APCI.FYol, APCI.FAygit, APCI.FIslev, Adres);
    if((Deger and 1) = 0) then Exit(Deger and (not %1111));

    Adres := Adres + 4;
  end;

  Result := 0;
end;

 {==============================================================================
  pci aygıtının IRQ istek (kesme) numarasını alır
 ==============================================================================}
function TPCIAygitlar.IRQNoAl(APCI: TPCI): TSayi1;
begin

  Result := Oku1(APCI.FYol, APCI.FAygit, APCI.FIslev, PCI_KESME_NO) and $FF;
end;

end.
