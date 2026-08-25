{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: sunucular.pas
  Dosya İşlevi: çekirdek içerisinde çalışan sunucuları yönetir

  Güncelleme Tarihi: 23/08/2026

 ==============================================================================}
{$mode objfpc}
unit sunucular;

interface

uses paylasim, baglantilar;

const
  USTSINIR_SUNUCUSAYISI = 16;

type
  TSunucuIslev = procedure(AIletisimTipi: TIletisimTipi; ABaglanti: TGenelBaglanti;
    AEthernetPaket: PEthernetPaket);

type
  TSunucu = class
  private
    // nesnenin kimliği / sıra numarası
    FKimlik: TKimlik;
    // sunucunun hangi iletişim tipi ile iletişim kuracağı (tcp veya udp)
    FProtokol: TProtokolTipi;
    // sunucunun dinleme yapacağı port numarası (http -> 80 gibi)
    FPortNo: TSayi4;
    // porta gelen istekleri işleyecek olan işlev
    FSunucuIslev: TSunucuIslev;
  end;

type
  TSunucular = class
  private
    FToplamSunucuSayisi: TSayi4;
    FSunucular: array[0..USTSINIR_SUNUCUSAYISI - 1] of TSunucu;
    function Al(ASiraNo: TISayi4): TSunucu;
    procedure Yaz(ASiraNo: TISayi4; ASunucu: TSunucu);
    function KimlikNoAl: TISayi4;
  public
    constructor Create;
    property Sunucular[ASiraNo: TISayi4]: TSunucu read Al write Yaz;
    function Ekle(AProtokol: TProtokolTipi; APortNo: TSayi4;
      ASunucuIslev: TSunucuIslev): TISayi4;
    property ToplamSunucuSayisi: TSayi4 read FToplamSunucuSayisi;
  end;

function SunucuBul(AProtokol: TProtokolTipi; APortNo: TSayi4): TSunucuIslev;

var
  GSunucular: TSunucular;

implementation

{==============================================================================
  sunucu listesi ana yükleme işlevlerini içerir
 ==============================================================================}
constructor TSunucular.Create;
var
  i: TSayi4;
begin

  FToplamSunucuSayisi := 0;

  for i := 0 to USTSINIR_SUNUCUSAYISI - 1 do FSunucular[i] := nil;
end;

function TSunucular.Al(ASiraNo: TISayi4): TSunucu;
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_SUNUCUSAYISI) then
    Result := FSunucular[ASiraNo]
  else Result := nil;
end;

procedure TSunucular.Yaz(ASiraNo: TISayi4; ASunucu: TSunucu);
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_SUNUCUSAYISI) then
    FSunucular[ASiraNo] := ASunucu;
end;

{==============================================================================
  sunucu listesine sunucuyu ekler
 ==============================================================================}
function TSunucular.Ekle(AProtokol: TProtokolTipi; APortNo: TSayi4;
  ASunucuIslev: TSunucuIslev): TISayi4;
var
  S: TSunucu;
  i: TISayi4;
begin

  Result := -1;

  if(AProtokol = ptTCP) or (AProtokol = ptUDP) then
  begin

    i := KimlikNoAl;
    if(i = -1) then Exit;

    S := TSunucu.Create;
    S.FKimlik := i;
    S.FProtokol := AProtokol;
    S.FPortNo := APortNo;
    S.FSunucuIslev := ASunucuIslev;

    Sunucular[i] := S;

    Inc(FToplamSunucuSayisi);

    Result := i;
  end;
end;

{==============================================================================
  listeye eklenecek sunucunun kimlik numarası
 ==============================================================================}
function TSunucular.KimlikNoAl: TISayi4;
var
  S: TSunucu;
  i: TISayi4;
begin

  Result := -1;

  for i := 0 to USTSINIR_SUNUCUSAYISI - 1 do
  begin

    S := Sunucular[i];

    if(S = nil) then Exit(i);
  end;
end;

{==============================================================================
  belirtilen sunucuyu listeden bularak çağrılacak işlevi geri döndürür
 ==============================================================================}
function SunucuBul(AProtokol: TProtokolTipi; APortNo: TSayi4): TSunucuIslev;
var
  S: TSunucu;
  i: TSayi4;
begin

  Result := nil;

  if(GSunucular.ToplamSunucuSayisi > 0) then
  begin

    for i := 0 to USTSINIR_SUNUCUSAYISI - 1 do
    begin

      S := GSunucular.Sunucular[i];
      if(S = nil) then Continue;

      if(S.FProtokol = AProtokol) and (S.FPortNo = APortNo) then Exit(S.FSunucuIslev);
    end;
  end;
end;

end.
