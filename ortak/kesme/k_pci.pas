{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_pci.pas
  Dosya İşlevi: pci yönetim işlevlerini içerir

  Güncelleme Tarihi: 22/09/2024

 ==============================================================================}
{$mode objfpc}
unit k_pci;

interface

uses paylasim;

function PCICagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses pci, gorev;

{==============================================================================
  pci kesme çağrılarını yönetir
 ==============================================================================}
function PCICagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  p: Isaretci;
  Islev: TSayi1;
  PCIAygitSiraNo: TISayi4;
begin

  // işlev no
  Islev := (AIslevNo and $FF);

  // toplam pci aygıt sayısını al
  if(Islev = 1) then
  begin

    Result := ToplamPCIAygitSayisi;
  end

  // pci bilgilerini al
  else if(Islev = 2) then
  begin

    PCIAygitSiraNo := PSayi4(ADegiskenler + 00)^;
    if(PCIAygitSiraNo >= 0) and (PCIAygitSiraNo < ToplamPCIAygitSayisi) then
    begin

      p := Isaretci(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
      Move(PCIAygitBellekAdresi[PCIAygitSiraNo]^, Isaretci(p)^, PCI_YAPIUZUNLUGU);
    end else Result := HATA_DEGERARALIKDISI;
  end

  // pci aygıtından 1 byte veri oku
  else if(Islev = 3) then
  begin

    Result := PCIOku1(PSayi4(ADegiskenler + 00)^, PSayi4(ADegiskenler + 04)^,
      PSayi4(ADegiskenler + 08)^, PSayi4(ADegiskenler + 12)^) and $FF;
  end

  // pci aygıtından 2 byte veri oku
  else if(Islev = 4) then
  begin

    Result := PCIOku2(PSayi4(ADegiskenler + 00)^, PSayi4(ADegiskenler + 04)^,
      PSayi4(ADegiskenler + 08)^, PSayi4(ADegiskenler + 12)^) and $FFFF;
  end

  // pci aygıtından 4 byte veri oku
  else if(Islev = 5) then
  begin

    Result := PCIOku4(PSayi4(ADegiskenler + 00)^, PSayi4(ADegiskenler + 04)^,
      PSayi4(ADegiskenler + 08)^, PSayi4(ADegiskenler + 12)^);
  end

  // pci aygıtına 1 byte veri yaz
  else if(Islev = 6) then
  begin

    PCIYaz1(PSayi4(ADegiskenler + 00)^, PSayi4(ADegiskenler + 04)^, PSayi4(ADegiskenler + 08)^,
      PSayi4(ADegiskenler + 12)^, PSayi4(ADegiskenler + 16)^);
  end

  // pci aygıtına 2 byte veri yaz
  else if(Islev = 7) then
  begin

    PCIYaz2(PSayi4(ADegiskenler + 00)^, PSayi4(ADegiskenler + 04)^, PSayi4(ADegiskenler + 08)^,
      PSayi4(ADegiskenler + 12)^, PSayi4(ADegiskenler + 16)^);
  end

  // pci aygıtına 4 byte veri yaz
  else if(Islev = 8) then
  begin

    PCIYaz4(PSayi4(ADegiskenler + 00)^, PSayi4(ADegiskenler + 04)^, PSayi4(ADegiskenler + 08)^,
      PSayi4(ADegiskenler + 12)^, PSayi4(ADegiskenler + 16)^);
  end

  else Result := HATA_ISLEV;
end;

end.
