{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: k_depolama.pas
  Dosya ��levi: depolama ayg�t kesme �a�r�lar�n� y�netir

  G�ncelleme Tarihi: 07/07/2025

 ==============================================================================}
{$mode objfpc}
unit k_depolama;

interface

uses paylasim;

function DepolamaCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses depolama, gorev, genel;

{==============================================================================
  depolama ayg�t kesme �a�r�lar�n� y�netir
 ==============================================================================}
function DepolamaCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  IslevNo: TSayi4;
  FD: PFizikselDepolama;
  MD: PMantiksalDepolama;
  p: Isaretci;
begin

  // i�lev no
  IslevNo := (AIslevNo and $FF);

  //********** mant�ksal ayg�t i�levleri ***********

  // toplam mant�ksal depolama ayg�t say�s�n� al
  if(IslevNo = 1) then
  begin

    Result := MantiksalDepolamaAygitSayisi;
  end

  // mant�ksal depolama ayg�t bilgilerini al
  else if(IslevNo = 2) then
  begin

    MD := GDepolama.MantiksalSurucuAl(PSayi4(ADegiskenler + 00)^);
    if not(MD = nil) then
    begin

      p := Isaretci(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
      PMantiksalDepolama3(p)^ := MD^.MD3;
      Result := SizeOf(TMantiksalDepolama3);
    end else Result := 0;
  end

  // mant�ksal depolama ayg�t�ndan veri oku
  else if(IslevNo = 3) then
  begin

    MD := GDepolama.MantiksalSurucuAl2(PKimlik(ADegiskenler + 00)^);
    if not(MD = nil) then
    begin

      p := Isaretci(PSayi4(ADegiskenler + 12)^ + FAktifGorevBellekAdresi);
      Result := GDepolama.MantiksalDepolamaVeriOku(MD, PSayi4(ADegiskenler + 04)^,
        PSayi4(ADegiskenler + 08)^, p);
    end else Result := 1;
  end;

  //********** fiziksel ayg�t i�levleri ***********

  // toplam fiziksel depolama ayg�t say�s�n� al
  if(IslevNo = $71) then
  begin

    Result := FizikselDepolamaAygitSayisi;
  end

  // fiziksel depolama ayg�t bilgilerini al
  else if(IslevNo = $72) then
  begin

    FD := GDepolama.FizikselSurucuAl(PSayi4(ADegiskenler + 00)^);
    if not(FD = nil) then
    begin

      p := Isaretci(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
      PFizikselDepolama3(p)^ := FD^.FD3;
      Result := SizeOf(TFizikselDepolama3);
    end else Result := 0;
  end

  // fiziksel depolama ayg�t�ndan veri oku
  else if(IslevNo = $73) then
  begin

    FD := GDepolama.FizikselSurucuAl2(PKimlik(ADegiskenler + 00)^);
    if not(FD = nil) then
    begin

      p := Isaretci(PSayi4(ADegiskenler + 12)^ + FAktifGorevBellekAdresi);
      Result := GDepolama.FizikselDepolamaVeriOku(FD, PSayi4(ADegiskenler + 04)^,
        PSayi4(ADegiskenler + 08)^, p);
    end else Result := 1;
  end
  // fiziksel depolama ayg�t�na veri yaz
  else if(IslevNo = $74) then
  begin

    FD := GDepolama.FizikselSurucuAl2(PKimlik(ADegiskenler + 00)^);
    if not(FD = nil) then
    begin

      p := Isaretci(PSayi4(ADegiskenler + 12)^ + FAktifGorevBellekAdresi);
      Result := GDepolama.FizikselDepolamaVeriYaz(FD, PSayi4(ADegiskenler + 04)^,
        PSayi4(ADegiskenler + 08)^, p);
    end else Result := 1;
  end;
end;

end.
