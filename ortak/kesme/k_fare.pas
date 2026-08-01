{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_fare.pas
  Dosya İşlevi: fare (mouse) kesme işlevlerini içerir

  Güncelleme Tarihi: 31/07/2016

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
  K: PKonum;
begin

  Result := HATA_ISLEV;

  // işlev no
  IslevNo := (AIslevNo and $FF);

  // fare gösterge konumunu al
  if(IslevNo = 1) then
  begin

    // fare konum değerini belirtilen bellek adreslerine kopyala
    K := PKonum(PSayi4(ADegiskenler)^ + FAktifGorevBellekAdresi);

    K^.Sol := GFareSurucusu.YatayKonum;
    K^.Ust := GFareSurucusu.DikeyKonum;
    Result := HATA_YOK;
  end;
end;

end.
