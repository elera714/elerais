{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: k_depolama.pas
  Dosya ��levi: depolama ayg�t kesme �a�r�lar�n� y�netir

  G�ncelleme Tarihi: 23/06/2020

 ==============================================================================}
{$mode objfpc}
unit k_depolama;

interface

uses paylasim;

function DepolamaCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses depolama, sistemmesaj;

{==============================================================================
  depolama ayg�t kesme �a�r�lar�n� y�netir
 ==============================================================================}
function DepolamaCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  Islev: TSayi4;
  AygitKimlik: TKimlik;
  p: Isaretci;
begin

  // i�lev no
  Islev := (AIslevNo and $FF);

  //********** mant�ksal ayg�t i�levleri ***********

  // toplam mant�ksal depolama ayg�t say�s�n� al
  if(Islev = 1) then
  begin

    Result := MantiksalDepolamaAygitSayisi;
  end

  // mant�ksal depolama ayg�t bilgilerini al
  else if(Islev = 2) then
  begin

    AygitKimlik := PISayi4(ADegiskenler + 00)^;
    p := Isaretci(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi);
    Result := MantiksalDepolamaAygitBilgisiAl(AygitKimlik, p);
  end

  // mant�ksal depolama ayg�t�ndan veri oku
  else if(Islev = 3) then
  begin

    AygitKimlik := PSayi4(ADegiskenler + 00)^;
    p := Isaretci(PSayi4(ADegiskenler + 12)^ + CalisanGorevBellekAdresi);
    Result := MantiksalDepolamaVeriOku(AygitKimlik, PSayi4(ADegiskenler + 04)^,
      PSayi4(ADegiskenler + 08)^, p);
  end;

  //********** fiziksel ayg�t i�levleri ***********

  // toplam fiziksel depolama ayg�t say�s�n� al
  if(Islev = $71) then
  begin

    Result := FizikselDepolamaAygitSayisi;
  end

  // fiziksel depolama ayg�t bilgilerini al
  else if(Islev = $72) then
  begin

    AygitKimlik := PSayi4(ADegiskenler + 00)^;
    p := Isaretci(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi);
    Result := FizikselDepolamaAygitBilgisiAl(AygitKimlik, p);
  end

  // fiziksel depolama ayg�t�ndan veri oku
  else if(Islev = $73) then
  begin

    AygitKimlik := PSayi4(ADegiskenler + 00)^;
    p := Isaretci(PSayi4(ADegiskenler + 12)^ + CalisanGorevBellekAdresi);
    Result := FizikselDepolamaVeriOku(AygitKimlik, PSayi4(ADegiskenler + 04)^,
      PSayi4(ADegiskenler + 08)^, p);
  end
  // fiziksel depolama ayg�t�na veri yaz
  else if(Islev = $74) then
  begin

    SISTEM_MESAJ(RENK_MOR, 'fiziksel depolama ayg�t�na veri yaz i�levi', []);
    {AygitKimlik := PSayi4(ADegiskenler + 00)^;
    p := Isaretci(PSayi4(ADegiskenler + 12)^ + CalisanGorevBellekAdresi);
    Result := FizikselDepolamaVeriOku(AygitKimlik, PSayi4(ADegiskenler + 04)^,
      PSayi4(ADegiskenler + 08)^, p);}
  end;
end;

end.
