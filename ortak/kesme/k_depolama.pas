{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: k_depolama.pas
  Dosya Ýþlevi: depolama aygýt kesme çaðrýlarýný yönetir

  Güncelleme Tarihi: 23/06/2020

 ==============================================================================}
{$mode objfpc}
unit k_depolama;

interface

uses paylasim;

function DepolamaCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses depolama, sistemmesaj;

{==============================================================================
  depolama aygýt kesme çaðrýlarýný yönetir
 ==============================================================================}
function DepolamaCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  Islev: TSayi4;
  AygitKimlik: TKimlik;
  p: Isaretci;
begin

  // iþlev no
  Islev := (AIslevNo and $FF);

  //********** mantýksal aygýt iþlevleri ***********

  // toplam mantýksal depolama aygýt sayýsýný al
  if(Islev = 1) then
  begin

    Result := MantiksalDepolamaAygitSayisi;
  end

  // mantýksal depolama aygýt bilgilerini al
  else if(Islev = 2) then
  begin

    AygitKimlik := PISayi4(ADegiskenler + 00)^;
    p := Isaretci(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi);
    Result := MantiksalDepolamaAygitBilgisiAl(AygitKimlik, p);
  end

  // mantýksal depolama aygýtýndan veri oku
  else if(Islev = 3) then
  begin

    AygitKimlik := PSayi4(ADegiskenler + 00)^;
    p := Isaretci(PSayi4(ADegiskenler + 12)^ + CalisanGorevBellekAdresi);
    Result := MantiksalDepolamaVeriOku(AygitKimlik, PSayi4(ADegiskenler + 04)^,
      PSayi4(ADegiskenler + 08)^, p);
  end;

  //********** fiziksel aygýt iþlevleri ***********

  // toplam fiziksel depolama aygýt sayýsýný al
  if(Islev = $71) then
  begin

    Result := FizikselDepolamaAygitSayisi;
  end

  // fiziksel depolama aygýt bilgilerini al
  else if(Islev = $72) then
  begin

    AygitKimlik := PSayi4(ADegiskenler + 00)^;
    p := Isaretci(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi);
    Result := FizikselDepolamaAygitBilgisiAl(AygitKimlik, p);
  end

  // fiziksel depolama aygýtýndan veri oku
  else if(Islev = $73) then
  begin

    AygitKimlik := PSayi4(ADegiskenler + 00)^;
    p := Isaretci(PSayi4(ADegiskenler + 12)^ + CalisanGorevBellekAdresi);
    Result := FizikselDepolamaVeriOku(AygitKimlik, PSayi4(ADegiskenler + 04)^,
      PSayi4(ADegiskenler + 08)^, p);
  end
  // fiziksel depolama aygýtýna veri yaz
  else if(Islev = $74) then
  begin

    SISTEM_MESAJ(RENK_MOR, 'fiziksel depolama aygýtýna veri yaz iþlevi', []);
    {AygitKimlik := PSayi4(ADegiskenler + 00)^;
    p := Isaretci(PSayi4(ADegiskenler + 12)^ + CalisanGorevBellekAdresi);
    Result := FizikselDepolamaVeriOku(AygitKimlik, PSayi4(ADegiskenler + 04)^,
      PSayi4(ADegiskenler + 08)^, p);}
  end;
end;

end.
