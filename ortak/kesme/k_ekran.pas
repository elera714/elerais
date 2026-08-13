{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_ekran.pas
  Dosya İşlevi: ekran (screen) yönetim işlevlerini içerir

  Güncelleme Tarihi: 12/08/2026

 ==============================================================================}
{$mode objfpc}
unit k_ekran;

interface

uses paylasim;

function EkranCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses gorev, src_vesa20;

{==============================================================================
  ekran kesme çağrılarını yönetir
 ==============================================================================}
function EkranCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  IslevNo: TSayi4;
  Konum: PKonum;
begin

  Result := HATA_ISLEV;

  // işlev no
  IslevNo := (AIslevNo and $FF);

  // ana işlev
  if(IslevNo = 2) then
  begin

    // alt işlev
    IslevNo := ((AIslevNo shr 8) and $FF);

    // ekran çözünürlüğünü al
    if(IslevNo = 1) then
    begin

      // çözünürlük değerlerini belirtilen bellek adreslerine kopyala
      Konum := PKonum(PSayi4(ADegiskenler + 00)^ + GGorevler.FAktifGrvBelAdr);


      Konum^.Sol := GEkranKartSurucusu.KartBilgisi.YatayCozunurluk;
      Konum^.Ust := GEkranKartSurucusu.KartBilgisi.DikeyCozunurluk;

      // işlev başarı kodunu geri döndür
      Result := HATA_YOK;
    end;
  end;
end;

end.
