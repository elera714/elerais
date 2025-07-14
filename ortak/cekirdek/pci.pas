{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: pci.pas
  Dosya İşlevi: pci yönetim işlevlerini içerir

  Güncelleme Tarihi: 14/07/2025

  Kaynaklar:
    http://wiki.osdev.org/PCI
    https://en.wikipedia.org/wiki/PCI_configuration_space

 ==============================================================================}
{$mode objfpc}
unit pci;

interface

uses paylasim;

const
  PCI_ADRES           = $CF8;
  PCI_VERI            = $CFC;

  PCI_YAPIUZUNLUGU    = 12;
  USTSINIR_PCIAYGIT   = 256;     // 4096 / PCI_YAPIUZUNLUGU = 12) = 341

type
  PPCI = ^TPCI;
  TPCI = packed record
    Yol, Aygit, Islev, AYRLD0: TSayi1;
    SaticiKimlik, AygitKimlik: TSayi2;
    SinifKod: TSayi4;
  end;

type
  PPCIAygiti = ^TPCIAygiti;
  TPCIAygiti = object
  private
    FToplamAygit: TSayi4;
    FPCIAygitListesi: array[0..USTSINIR_PCIAYGIT - 1] of PPCI;
    function PCIBilgiAl(ASiraNo: TSayi4): PPCI;
    procedure PCIBilgiYaz(ASiraNo: TSayi4; APCI: PPCI);
  public
    procedure Yukle;
    function Oku1(AYol, AAygit, AIslev, ASiraNo: TSayi1): TSayi1;
    function Oku2(AYol, AAygit, AIslev, ASiraNo: TSayi1): TSayi2;
    function Oku4(AYol, AAygit, AIslev, ASiraNo: TSayi1): TSayi4;
    procedure Yaz1(AYol, AAygit, AIslev, ASiraNo: TSayi1; ADeger: TSayi1);
    procedure Yaz2(AYol, AAygit, AIslev, ASiraNo: TSayi1; ADeger: TSayi2);
    procedure Yaz4(AYol, AAygit, AIslev, ASiraNo: TSayi1; ADeger: TSayi4);
    function IlkPortDegeriniAl(APCI: PPCI): TSayi2;
    function IlkBellekDegeriniAl(APCI: PPCI): TSayi4;
    function IRQNoAl(APCI: PPCI): TSayi1;
    property ToplamAygit: TSayi4 read FToplamAygit write FToplamAygit;
    property PCI[ASiraNo: TSayi4]: PPCI read PCIBilgiAl write PCIBilgiYaz;
  end;

var
  PCIAygiti0: TPCIAygiti;

implementation

uses aygityonetimi, port;

{==============================================================================
  sistemde mevcut pci aygıtlarının ana yükleme işlevlerini içerir
 ==============================================================================}
procedure TPCIAygiti.Yukle;
var
  P: PPCI;
  Yol, Aygit, Islev,
  i, j, k: TSayi4;
begin

  // toplam aygıt sayısını sıfırla
  ToplamAygit := 0;

  // bellek girişlerini sıfırla
  for i := 0 to USTSINIR_PCIAYGIT - 1 do PCI[i] := nil;

  // yol / aygıt / işlev girişlerini sorgula
  for Yol := 0 to 255 do
  begin

    for Aygit := 0 to 31 do
    begin

      for Islev := 0 to 7 do
      begin

        // satıcı / aygıt bilgilerini al
        j := Oku4(Yol, Aygit, Islev, 0);
        if((j and $FFFF) <> 0) and ((j and $FFFF) <> $FFFF) then
        begin

          // eğer azami aygıt sayısı aşılmamışsa
          if(ToplamAygit <= USTSINIR_PCIAYGIT) then
          begin

            // yeni pci aygıt bilgisi için bellekte yer ayır
            P := PPCI(GetMem(SizeOf(TPCI)));

            // pci aygıt adresini listesiye kaydet
            PCI[ToplamAygit] := P;

            // yol / aygıt / işlev bilgilerini kaydet
            P^.Yol := Yol;
            P^.Aygit := Aygit;
            P^.Islev := Islev;

            // satıcı / aygıt bilgilerini kaydet
            P^.SaticiKimlik := j and $FFFF;
            P^.AygitKimlik := ((j shr 16) and $FFFF);

            // aygıtın sınıfını al (Class Code + Revision ID)
            // üst 24 bit sınıf kodu, alt 8 bit revizyon kodu
            P^.SinifKod := Oku4(Yol, Aygit, Islev, 8);

            // başlık (header) tipi
            j := Oku1(Yol, Aygit, Islev, $E);
            j := (j and $FF);

            // aygıtı, yüklenecek aygıt listesine ekle
            AygitiSistemeKaydet(P);

            // aygıt sayısını bir artır
            k := FToplamAygit;
            Inc(k);
            FToplamAygit := k;

            // eğer aygıt çok fonksiyonlu değil ise bir sonraki aygıta geç
            { if(_Islev = 0) then
            begin

              if((j and $80) = 0) then Break;
            end; } // iptal - 09112024
          end;
        end;
      end;
    end;
  end;
end;

function TPCIAygiti.PCIBilgiAl(ASiraNo: TSayi4): PPCI;
begin

  // istenen verinin belirtilen aralıkta olup olmadığını kontrol et
  if(ASiraNo >= 0) and (ASiraNo <= ToplamAygit) then
    Result := FPCIAygitListesi[ASiraNo]
  else Result := nil;
end;

procedure TPCIAygiti.PCIBilgiYaz(ASiraNo: TSayi4; APCI: PPCI);
begin

  // istenen verinin belirtilen aralıkta olup olmadığını kontrol et
  if(ASiraNo >= 0) and (ASiraNo <= USTSINIR_PCIAYGIT) then
    FPCIAygitListesi[ASiraNo] := APCI;
end;

{==============================================================================
  belirtilen aygıtın sıra değerinden 1 byte değer okur
 ==============================================================================}
function TPCIAygiti.Oku1(AYol, AAygit, AIslev, ASiraNo: TSayi1): TSayi1;
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
function TPCIAygiti.Oku2(AYol, AAygit, AIslev, ASiraNo: TSayi1): TSayi2;
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
function TPCIAygiti.Oku4(AYol, AAygit, AIslev, ASiraNo: TSayi1): TSayi4;
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
procedure TPCIAygiti.Yaz1(AYol, AAygit, AIslev, ASiraNo: TSayi1; ADeger: TSayi1);
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
procedure TPCIAygiti.Yaz2(AYol, AAygit, AIslev, ASiraNo: TSayi1; ADeger: TSayi2);
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
procedure TPCIAygiti.Yaz4(AYol, AAygit, AIslev, ASiraNo: TSayi1; ADeger: TSayi4);
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
function TPCIAygiti.IlkPortDegeriniAl(APCI: PPCI): TSayi2;
var
  Adres: TSayi1;
  Deger, i: TSayi4;
begin

  Adres := $10;
  for i := 1 to 6 do
  begin

    Deger := Oku4(APCI^.Yol, APCI^.Aygit, APCI^.Islev, Adres);
    if((Deger and 1) = 1) then Exit(Deger and (not %11));

    Adres += 4;
  end;

  Result := 0;
end;

{==============================================================================
  pci aygıtının ilk iletişim bellek değerini alır
 ==============================================================================}
 function TPCIAygiti.IlkBellekDegeriniAl(APCI: PPCI): TSayi4;
var
  Adres: TSayi1;
  Deger, i: TSayi4;
begin

  Adres := $10;
  for i := 1 to 6 do
  begin

    Deger := Oku4(APCI^.Yol, APCI^.Aygit, APCI^.Islev, Adres);
    if((Deger and 1) = 0) then Exit(Deger and (not %1111));

    Adres += 4;
  end;

  Result := 0;
end;

 {==============================================================================
  pci aygıtının IRQ istek numarasını alır
 ==============================================================================}
function TPCIAygiti.IRQNoAl(APCI: PPCI): TSayi1;
begin

  Result := Oku1(APCI^.Yol, APCI^.Aygit, APCI^.Islev, $3C) and $FF;
end;

end.
