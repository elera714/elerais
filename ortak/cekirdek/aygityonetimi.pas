{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: aygityonetimi.pas
  Dosya Ýþlevi: aygýt (device) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 28/07/2026

 ==============================================================================}
{$mode objfpc}
unit aygityonetimi;

interface

uses paylasim, pci, ethernet, src_pcnet32, src_e1000, aygit;

type
  TEthernetYukle = function(var AEthernet: TEthernet): TISayi4;

type
  TSurucuIslev = packed record
    SaticiKimlik,
    AygitKimlik: TSayi2;
    Yukle: TEthernetYukle;
  end;

const
  DESTEKLENEN_AGAYGIT_SAYISI  = 2;

var
  DesteklenenAgAygitlari: array[0..DESTEKLENEN_AGAYGIT_SAYISI - 1] of TSurucuIslev = (
    (SaticiKimlik: $1022; AygitKimlik: $2000; Yukle: @src_pcnet32.Yukle),
    (SaticiKimlik: $8086; AygitKimlik: $100E; Yukle: @src_e1000.Yukle));

const
  USTSINIR_AYGIT = 16;

type
  PAygitlar = ^TAygitlar;
  TAygitlar = class
  private
    FAktifEthernet: TEthernet;


    FToplamAygit: TSayi4;
    FToplamAgAygitSayisi: TSayi4;
    FAgAygitListesi: array[0..USTSINIR_AYGIT - 1] of TAgAygiti;
    //FDiskAygitListesi: array[0..0] of TAygit;
    //FDisketAygitListesi: array[0..0] of TAygit;
    function AgAygitiAl(ASiraNo: TISayi4): TAgAygiti;
    procedure AgAygitiYaz(ASiraNo: TISayi4; AAgAygiti: TAgAygiti);
  public
    constructor Create;
    destructor Destroy; override;
    property AktifEthernet: TEthernet read FAktifEthernet;
    procedure VeritabaniOlustur;
    procedure AgAygitlariniYukle;
    procedure EthernetAygitiEkle(APCI: TPCI);
    function SiraNoAl: TISayi4;
    property AgAygitListesi[ASiraNo: TISayi4]: TAgAygiti read AgAygitiAl write AgAygitiYaz;
    property ToplamAygit: TSayi4 read FToplamAygit;
    property ToplamAgAygitSayisi: TSayi4 read FToplamAgAygitSayisi;
  end;

var
  GAygitlar: TAygitlar;

implementation

uses vbox;

{ TTemelDonanim }

constructor TAygitlar.Create;
var
  i: TSayi4;
begin

  FAktifEthernet := nil;

  FToplamAygit := 0;
  FToplamAgAygitSayisi := 0;

  // aygit listesini ilk deðerlerle yükle
  for i := 0 to USTSINIR_AYGIT - 1 do FAgAygitListesi[i] := nil;
end;

destructor TAygitlar.Destroy;
var
  i: TSayi4;
begin

  for i := 0 to USTSINIR_AYGIT - 1 do
  begin

    if not(FAgAygitListesi[i] = nil) then FAgAygitListesi[i].Destroy;
  end;

  inherited Destroy;
end;

function TAygitlar.AgAygitiAl(ASiraNo: TISayi4): TAgAygiti;
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_AYGIT) then
    Result := FAgAygitListesi[ASiraNo]
  else Result := nil;
end;

procedure TAygitlar.AgAygitiYaz(ASiraNo: TISayi4; AAgAygiti: TAgAygiti);
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_AYGIT) then
    FAgAygitListesi[ASiraNo] := AAgAygiti;
end;

{==============================================================================
  yüklenecek aygýt listesine belirtilen aygýtý ekler
 ==============================================================================}
procedure TAygitlar.VeritabaniOlustur;
var
  AygitTipi: TSayi4;
  i: TSayi4;
  P: TPCI;
begin

  if(GPCIAygitlar.ToplamAygit = 0) then Exit;

  for i := 0 to GPCIAygitlar.ToplamAygit - 1 do
  begin

    P := GPCIAygitlar.PCI[i];

    AygitTipi := (P.FSinifKod shr 16) and $FFFF;

    // sistem tarafýndan tanýmlanan aygýtlarý yükle
    if(AygitTipi = PCIAYGIT_AG_ETHERNET) then

      EthernetAygitiEkle(P)

    // virtualbox sanal sürücüyü yükle
    else if(AygitTipi = PCIAYGIT_CEVREBIRIM_DIGER) then

      if(P.FSaticiKimlik = $80EE) and (P.FAygitKimlik = $CAFE) then vbox.Yukle(P);
  end;
end;

{==============================================================================
  yüklenecek ethernet aygýt listesine aygýtý ekler
 ==============================================================================}
procedure TAygitlar.EthernetAygitiEkle(APCI: TPCI);
var
  A: TEthernet;
begin

  // sisteme eklenecek üstsýnýr að aygýt sayýsý aþýldý mý ?
  if(FToplamAygit >= USTSINIR_AYGIT) then Exit;

  // aygýtý listeye ekle
  A := TEthernet.Create;
  AgAygitListesi[A.SiraNo] := A;

  A.FPCI := APCI;

  // aygýt sayýsýný bir artýr
  Inc(FToplamAygit);
  Inc(FToplamAgAygitSayisi);
end;

{==============================================================================
  sistemde mevcut (sistem tarafýndan desteklenen) að aygýtlarýný yükler
 ==============================================================================}
procedure TAygitlar.AgAygitlariniYukle;
var
  P: TPCI;
  SurucuIslev: TSurucuIslev;
  DesteklenenAygitSiraNo,
  i: TSayi4;
  A: TEthernet;
begin

  // sistemde ethernet aygýtý yoksa çýk
  if(ToplamAgAygitSayisi = 0) then Exit;

  // desteklenen ethernet aygýtý yoksa çýk
  if(DESTEKLENEN_AGAYGIT_SAYISI > 0) then
  begin

    // sistemde mevcut, sistem tarafýndan desteklenen aygýtlarý yükle
    for i := 0 to ToplamAgAygitSayisi - 1 do
    begin

      A := TEthernet(AgAygitListesi[i]);
      if(A <> nil) then
      begin

        P := A.FPCI;

        for DesteklenenAygitSiraNo := 0 to DESTEKLENEN_AGAYGIT_SAYISI - 1 do
        begin

          SurucuIslev := DesteklenenAgAygitlari[DesteklenenAygitSiraNo];
          if(SurucuIslev.SaticiKimlik = P.FSaticiKimlik) and (SurucuIslev.AygitKimlik = P.FAygitKimlik) then
          begin

            // eðer aygýt yüklemesi baþarýlý ise að yükleme deðiþkenini aktifleþtir
            SurucuIslev.Yukle(A);
            if(A.Yuklendi) then
            begin

              // ethernet aygýtýný aktif olarak güncelle
              A.Aktif := True;
              FAktifEthernet := A;
              Exit;
            end;
          end;
        end;
      end;
    end;
  end;
end;

function TAygitlar.SiraNoAl: TISayi4;
var
  A: TAgAygiti;
  i: TISayi4;
begin

  Result := -1;

  for i := 0 to USTSINIR_AYGIT - 1 do
  begin

    A := AgAygitListesi[i];

    if(A = nil) then Exit(i);
  end;
end;

end.
