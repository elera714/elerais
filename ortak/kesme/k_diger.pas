{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_diger.pas
  Dosya İşlevi: kategorik olmayan diğer işlevleri içerir

  Güncelleme Tarihi: 16/09/2024

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit k_diger;

interface

uses paylasim;

function DigerCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses sistemmesaj;

{==============================================================================
  kategorik olmayan kesme çağrılarını yönetir
 ==============================================================================}
function DigerCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  Islev, Sayi4: TSayi4;
begin

  // işlev no
  Islev := (AIslevNo and $FF);

  // test işlevi
  // zamanlayıcı sayacını geri döndür
  //if(Islev = 1) then
  begin

    asm
      rdtsc
      mov Sayi4,eax
    end;

    //SISTEM_MESAJ_S16(RENK_SIYAH, 'Değer: ', Sayi4, 8);
    Result := Sayi4;
  end

  // işlev belirtilen aralıkta değil ise hata kodunu geri döndüSayi4
  //else Result := HATA_ISLEV;
end;

end.
