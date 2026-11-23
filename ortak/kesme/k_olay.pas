{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: k_olay.pas
  Dosya Ýþlevi: olay (event) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 23/11/2026

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

    Result := 0;

    G := GGorevler.GorevAl;
    if not(G = nil) then
    begin

      // FOlayBayraklari'nda kaç olay olursa olsun tek bir olay olarak deðerlendiriliyor
      if(G.FOlayBayraklari > 0) then Result := 1;
      Result := Result + G.FOlaySayisi;
    end;
  end

  // görev için bekleyen sýradaki olayý al
  else if(IslevNo = 2) then
  begin

    Result := 0;

    G := GGorevler.GorevAl;
    if not(G = nil) then
    begin

      // öncelikli görev FOlayBayraklari'nda bekleyen olaylardýr
      if(G.FOlayBayraklari > 0) then
      begin

        // CO_CIZIM olay bayraðý
        if((G.FOlayBayraklari and 1) = 1) then
        begin

          O2 := POlay(PSayi4(ADegiskenler)^ + GGorevler.FAktifGrvBelAdr);
          O2^.Kimlik := G.FAktifPencere.Kimlik;
          O2^.Olay := CO_CIZIM;
          O2^.Deger1 := 0;
          O2^.Deger2 := 0;

          // CO_CIZIM olayýný olay bayraklarýndan sil
          G.FOlayBayraklari := G.FOlayBayraklari and not(1);

          // FOlayBayraklari'nda kaç olay olursa olsun tek bir olay olarak deðerlendiriliyor
          if(G.FOlayBayraklari > 0) then Result := 1;

          Result := Result + G.FOlaySayisi;
        end;
      end
      else if(GGorevler.OlayAl(G.FKimlik, O)) then
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
    end;
  end;
end;

end.
