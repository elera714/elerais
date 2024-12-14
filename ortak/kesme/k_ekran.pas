{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_ekran.pas
  Dosya İşlevi: ekran (screen) yönetim işlevlerini içerir

  Güncelleme Tarihi: 23/06/2020

 ==============================================================================}
{$mode objfpc}
unit k_ekran;

interface

uses paylasim;

function EkranCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses genel;

{==============================================================================
  ekran kesme çağrılarını yönetir
 ==============================================================================}
function EkranCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  Islev: TSayi4;
  Konum: PKonum;
begin

  // işlev no
  Islev := (AIslevNo and $FF);

  // AL'ma işlevi
  if(Islev = 2) then
  begin

    Islev := ((AIslevNo shr 8) and $FF);

    // ekran çözünürlüğünü al
    if(Islev = 1) then
    begin

      // çözünürlük değerlerini belirtilen bellek adreslerine kopyala
      Konum := PKonum(PSayi4(ADegiskenler + 00)^ + CalisanGorevBellekAdresi);


      Konum^.Sol := GEkranKartSurucusu.KartBilgisi.YatayCozunurluk;
      Konum^.Ust := GEkranKartSurucusu.KartBilgisi.DikeyCozunurluk;

      // işlev başarı kodunu geri döndür
      Result := 1;
    end;
  end

  // işlev belirtilen aralıkta değil ise hata kodunu geri döndür
  else Result := HATA_ISLEV;
end;

end.
