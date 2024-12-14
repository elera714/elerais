{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_ag.pas
  Dosya İşlevi: ağ (network) yönetim işlevlerini içerir

  Güncelleme Tarihi: 22/09/2019

 ==============================================================================}
{$mode objfpc}
unit k_ag;

interface

{==============================================================================
  big endian > little endian çevrimi

  Bellek Yerleşimleri: (Örnek Sayı: $12345678)
    Big Endian:   78 56 34 12
    Litle Endian: 12 34 56 78
 ==============================================================================}
uses paylasim;

function AgCagriIslevleri(IslevNo: TSayi4; Degiskenler: Isaretci): TISayi4;

implementation

uses arp, ag;

var
  AgCagriListesi: array[0..2] of TKesmeCagrisi = (nil, @GenelAgCagriIslevleri,
    @ArpCagriIslevleri);

{==============================================================================
  ağ (network) kesme çağrılarını yönetir
 ==============================================================================}
function AgCagriIslevleri(IslevNo: TSayi4; Degiskenler: Isaretci): TISayi4;
var
  SiraNo: TSayi4;
begin

  // işlev no
  SiraNo := (IslevNo and $FF);

  // işlevi ilgili protokole yönlendir
  if(SiraNo >= 1) and (SiraNo <= 2) then

    Result := AgCagriListesi[SiraNo](((IslevNo shr 8) and $FFFF), Degiskenler)
  else Result := HATA_ISLEV;
end;

end.
