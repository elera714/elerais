{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: k_depolama.pas
  Dosya Ýþlevi: depolama aygýt kesme çaðrýlarýný yönetir

  Güncelleme Tarihi: 09/01/2025

 ==============================================================================}
{$mode objfpc}
unit k_depolama;

interface

uses paylasim;

function DepolamaCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses depolama, gorev;

{==============================================================================
  depolama aygýt kesme çaðrýlarýný yönetir
 ==============================================================================}
function DepolamaCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  IslevNo: TSayi4;
  FD: PFizikselDepolama;
  MD: PMantiksalDepolama;
  p: Isaretci;
begin

  // iþlev no
  IslevNo := (AIslevNo and $FF);

  //********** mantýksal aygýt iþlevleri ***********

  // toplam mantýksal depolama aygýt sayýsýný al
  if(IslevNo = 1) then
  begin

    Result := MantiksalDepolamaAygitSayisi;
  end

  // mantýksal depolama aygýt bilgilerini al
  else if(IslevNo = 2) then
  begin

    MD := MantiksalSurucuAl(PSayi4(ADegiskenler + 00)^);
    if not(MD = nil) then
    begin

      p := Isaretci(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
      PMantiksalDepolama3(p)^ := MD^.MD3;
      Result := SizeOf(TMantiksalDepolama3);
    end else Result := 0;
  end

  // mantýksal depolama aygýtýndan veri oku
  else if(IslevNo = 3) then
  begin

    MD := MantiksalSurucuAl2(PKimlik(ADegiskenler + 00)^);
    if not(MD = nil) then
    begin

      p := Isaretci(PSayi4(ADegiskenler + 12)^ + FAktifGorevBellekAdresi);
      Result := MantiksalDepolamaVeriOku(MD, PSayi4(ADegiskenler + 04)^,
        PSayi4(ADegiskenler + 08)^, p);
    end else Result := 1;
  end;

  //********** fiziksel aygýt iþlevleri ***********

  // toplam fiziksel depolama aygýt sayýsýný al
  if(IslevNo = $71) then
  begin

    Result := FizikselDepolamaAygitSayisi;
  end

  // fiziksel depolama aygýt bilgilerini al
  else if(IslevNo = $72) then
  begin

    FD := FizikselSurucuAl(PSayi4(ADegiskenler + 00)^);
    if not(FD = nil) then
    begin

      p := Isaretci(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
      PFizikselDepolama3(p)^ := FD^.FD3;
      Result := SizeOf(TFizikselDepolama3);
    end else Result := 0;
  end

  // fiziksel depolama aygýtýndan veri oku
  else if(IslevNo = $73) then
  begin

    FD := FizikselSurucuAl2(PKimlik(ADegiskenler + 00)^);
    if not(FD = nil) then
    begin

      p := Isaretci(PSayi4(ADegiskenler + 12)^ + FAktifGorevBellekAdresi);
      Result := FizikselDepolamaVeriOku(FD, PSayi4(ADegiskenler + 04)^,
        PSayi4(ADegiskenler + 08)^, p);
    end else Result := 1;
  end
  // fiziksel depolama aygýtýna veri yaz
  else if(IslevNo = $74) then
  begin

    FD := FizikselSurucuAl2(PKimlik(ADegiskenler + 00)^);
    if not(FD = nil) then
    begin

      p := Isaretci(PSayi4(ADegiskenler + 12)^ + FAktifGorevBellekAdresi);
      Result := FizikselDepolamaVeriYaz(FD, PSayi4(ADegiskenler + 04)^,
        PSayi4(ADegiskenler + 08)^, p);
    end else Result := 1;
  end;
end;

end.
