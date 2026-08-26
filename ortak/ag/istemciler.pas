{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: istemciler.pas
  Dosya İşlevi: sistem üzerinden ağa çıkan istemcileri yönetir

  Güncelleme Tarihi: 26/08/2026

 ==============================================================================}
{$mode objfpc}
unit istemciler;

interface

uses paylasim, baglantilar, dhcpv4;

const
  USTSINIR_ISTEMCISAYISI = 16;

type
  TIstemciIslev = procedure(AIletisimTipi: TIletisimTipi; ABaglanti: TBaglanti;
    ADHCP4Yapi: PDHCP4Yapi);

type
  TIstemci = class
  private
    // nesnenin kimliği / sıra numarası
    FKimlik: TKimlik;
    // istemcinin hangi iletişim tipi ile iletişim kuracağı (tcp veya udp)
    FProtokol: TProtokolTipi;
    // istemcinin kaynak portu ve bağlanacağı hedef port
    FKaynakPort, FHedefPort: TSayi4;
    // porta gelen istekleri işleyecek olan işlev
    FIstemciIslev: TIstemciIslev;
  end;

type
  TIstemciler = class
  private
    FToplamIstemciSayisi: TSayi4;
    FIstemciler: array[0..USTSINIR_ISTEMCISAYISI - 1] of TIstemci;
    function Al(ASiraNo: TISayi4): TIstemci;
    procedure Yaz(ASiraNo: TISayi4; AIstemci: TIstemci);
    function KimlikNoAl: TISayi4;
  public
    constructor Create;
    property Istemciler[ASiraNo: TISayi4]: TIstemci read Al write Yaz;
    function Ekle(AProtokol: TProtokolTipi; AKaynakPort, AHedefPort: TSayi4;
      AIstemciIslev: TIstemciIslev): TISayi4;
    function Cikar(AProtokol: TProtokolTipi; AKaynakPort, AHedefPort: TSayi4): TISayi4;
    property ToplamIstemciSayisi: TSayi4 read FToplamIstemciSayisi;
  end;

function IstemciBul(AProtokol: TProtokolTipi; AKaynakPort, AHedefPort: TSayi4): TIstemciIslev;

var
  GIstemciler: TIstemciler;

implementation

{==============================================================================
  istemci listesi ana yükleme işlevlerini içerir
 ==============================================================================}
constructor TIstemciler.Create;
var
  i: TSayi4;
begin

  FToplamIstemciSayisi := 0;

  for i := 0 to USTSINIR_ISTEMCISAYISI - 1 do FIstemciler[i] := nil;
end;

function TIstemciler.Al(ASiraNo: TISayi4): TIstemci;
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_ISTEMCISAYISI) then
    Result := FIstemciler[ASiraNo]
  else Result := nil;
end;

procedure TIstemciler.Yaz(ASiraNo: TISayi4; AIstemci: TIstemci);
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_ISTEMCISAYISI) then
    FIstemciler[ASiraNo] := AIstemci;
end;

{==============================================================================
  istemci listesine istemci ekler
 ==============================================================================}
function TIstemciler.Ekle(AProtokol: TProtokolTipi; AKaynakPort, AHedefPort: TSayi4;
  AIstemciIslev: TIstemciIslev): TISayi4;
var
  Ist: TIstemci;
  i: TISayi4;
begin

  Result := -1;

  if(AProtokol = ptTCP) or (AProtokol = ptUDP) then
  begin

    i := KimlikNoAl;
    if(i = -1) then Exit;

    Ist := TIstemci.Create;
    Ist.FKimlik := i;
    Ist.FProtokol := AProtokol;
    Ist.FKaynakPort := AKaynakPort;
    Ist.FHedefPort := AHedefPort;
    Ist.FIstemciIslev := AIstemciIslev;

    Istemciler[i] := Ist;

    Inc(FToplamIstemciSayisi);

    Result := i;
  end;
end;

{==============================================================================
  istemci listesinden istemciyi çıkarır
 ==============================================================================}
function TIstemciler.Cikar(AProtokol: TProtokolTipi; AKaynakPort, AHedefPort: TSayi4): TISayi4;
var
  Ist: TIstemci;
  i: TISayi4;
begin

  Result := -1;

  if(GIstemciler.ToplamIstemciSayisi > 0) then
  begin

    for i := 0 to USTSINIR_ISTEMCISAYISI - 1 do
    begin

      Ist := GIstemciler.Istemciler[i];
      if(Ist = nil) then Continue;

      if(Ist.FProtokol = AProtokol) and (Ist.FKaynakPort = AKaynakPort) and
        (Ist.FHedefPort = AHedefPort) then
      begin

        GIstemciler.Istemciler[i] := nil;
        Ist.Destroy;
        Exit(HATA_YOK);
      end;
    end;
  end;
end;

{==============================================================================
  listeye eklenecek istemcinin kimlik numarası
 ==============================================================================}
function TIstemciler.KimlikNoAl: TISayi4;
var
  Ist: TIstemci;
  i: TISayi4;
begin

  Result := -1;

  for i := 0 to USTSINIR_ISTEMCISAYISI - 1 do
  begin

    Ist := Istemciler[i];

    if(Ist = nil) then Exit(i);
  end;
end;

{==============================================================================
  belirtilen istemciyi listeden bularak çağrılacak işlevi geri döndürür
 ==============================================================================}
function IstemciBul(AProtokol: TProtokolTipi; AKaynakPort, AHedefPort: TSayi4): TIstemciIslev;
var
  Ist: TIstemci;
  i: TSayi4;
begin

  Result := nil;

  if(GIstemciler.ToplamIstemciSayisi > 0) then
  begin

    for i := 0 to USTSINIR_ISTEMCISAYISI - 1 do
    begin

      Ist := GIstemciler.Istemciler[i];
      if(Ist = nil) then Continue;

      if(Ist.FProtokol = AProtokol) and (Ist.FKaynakPort = AHedefPort) and
        (Ist.FHedefPort = AKaynakPort) then Exit(Ist.FIstemciIslev);
    end;
  end;
end;

end.
