{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_fare.pas
  Dosya İşlevi: fare (mouse) kesme işlevlerini içerir

  Güncelleme Tarihi: 14/08/2026

 ==============================================================================}
{$mode objfpc}
unit k_fare;

interface

uses paylasim;

function FareCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses src_ps2, gorev;

{==============================================================================
  fare kesme çağrılarını yönetir
 ==============================================================================}
function FareCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  IslevNo: TSayi4;
  Konum: PKonum;
begin

  Result := HATA_ISLEV;

  // işlev no
  IslevNo := (AIslevNo and $FF);

  // fare gösterge konumunu al
  if(IslevNo = 1) then
  begin

    // fare konum değerini belirtilen bellek adreslerine kopyala
    Konum := PKonum(PSayi4(ADegiskenler)^ + GGorevler.FAktifGrvBelAdr);

    Konum^.Sol := GFareSurucusu.YatayKonum;
    Konum^.Ust := GFareSurucusu.DikeyKonum;
    Result := HATA_YOK;
  end;
end;

end.
