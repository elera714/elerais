{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_fare.pas
  Dosya İşlevi: fare (mouse) kesme işlevlerini içerir

  Güncelleme Tarihi: 15/09/2019

 ==============================================================================}
{$mode objfpc}
unit k_fare;

interface

uses paylasim;

function FareCagriIslevleri(IslevNo: TSayi4; Degiskenler: Isaretci): TISayi4;

implementation

uses genel, gorev;

{==============================================================================
  fare kesme çağrılarını yönetir
 ==============================================================================}
function FareCagriIslevleri(IslevNo: TSayi4; Degiskenler: Isaretci): TISayi4;
var
  _Nokta: PKonum;
  _Islev: TSayi4;
begin

  // işlev no
  _Islev := (IslevNo and $FF);

  // fare gösterge konumunu al
  if(_Islev = 1) then
  begin

    // fare konum değerini belirtilen bellek adreslerine kopyala
    _Nokta := PKonum(PSayi4(Degiskenler)^ + FAktifGorevBellekAdresi);

    _Nokta^.Sol := GFareSurucusu.YatayKonum;
    _Nokta^.Ust := GFareSurucusu.DikeyKonum;
  end

  // işlev belirtilen aralıkta değilse hata kodunu geri döndür
  else Result := HATA_ISLEV;
end;

end.
