{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: k_olay.pas
  Dosya Ýþlevi: olay (event) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 21/11/2026

 ==============================================================================}
{$mode objfpc}
unit k_olay;

interface

uses paylasim;

function OlayCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses gorev;

{==============================================================================
  olay kesme çaðrýlarýný yönetir
 ==============================================================================}
function OlayCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  G: TGorev;
  O: TOlay;
  O2: POlay;
  IslevNo: TSayi4;
begin

  Result := HATA_ISLEV;

  IslevNo := (AIslevNo and $FF);

  // görev için bekleyen olay sayýsýný al
  if(IslevNo = 1) then
  begin

    G := GGorevler.GorevAl;
    if not(G = nil) then
      Result := G.FOlaySayisi
    else Result := 0;
  end

  // görev için bekleyen sýradaki olayý al
  else if(IslevNo = 2) then
  begin

    G := GGorevler.GorevAl;
    if not(G = nil) and (G.FOlaySayisi > 0) then
    begin

      if(GGorevler.OlayAl(G.FKimlik, O)) then
      begin

        // olay deðiþkenlerini görevin yýðýn alanýna kopyala
        O2 := POlay(PSayi4(ADegiskenler)^ + GGorevler.FAktifGrvBelAdr);
        O2^.Kimlik := O.Kimlik;
        O2^.Olay := O.Olay;
        O2^.Deger1 := O.Deger1;
        O2^.Deger2 := O.Deger2;

        Result := G.FOlaySayisi;
      end;
    end
    else
    begin

      O2 := POlay(PSayi4(ADegiskenler)^ + GGorevler.FAktifGrvBelAdr);
      O2^.Kimlik := -1;
      O2^.Olay := -1;
      O2^.Deger1 := -1;
      O2^.Deger2 := -1;

      Result := 0;
    end;
  end;
end;

end.
