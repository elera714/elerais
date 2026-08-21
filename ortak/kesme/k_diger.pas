{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_diger.pas
  Dosya İşlevi: kategorik olmayan diğer işlevleri içerir

  Güncelleme Tarihi: 21/08/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit k_diger;

interface

uses paylasim;

function DigerCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

{==============================================================================
  kategorik olmayan kesme çağrılarını yönetir
 ==============================================================================}
function DigerCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  Islev, Sayi4: TSayi4;
begin

  Result := HATA_ISLEV;

  // işlev no
  Islev := (AIslevNo and $FF);

  // test işlevi
  // zamanlayıcı sayacını geri döndür
  if(Islev = 1) then
  begin

    asm
      rdtsc
      mov Sayi4,eax
    end;

    Result := Sayi4;
  end;
end;

end.
