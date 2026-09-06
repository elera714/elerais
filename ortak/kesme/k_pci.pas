{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_pci.pas
  Dosya İşlevi: pci kesme yönetim işlevlerini içerir

  Güncelleme Tarihi: 21/08/2026

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
  P: TPCI;
  P3: PPCI3;
  IslevNo: TSayi4;
  SiraNo: TSayi4; { TISayi4 olması gerekiyor, değiştirildiğinde sistem kilitleniyor }
begin

  Result := HATA_ISLEV;

  // işlev no
  IslevNo := (AIslevNo and $FF);

  // toplam pci aygıt sayısını al
  if(IslevNo = 1) then
  begin

    Result := GPCIAygitlar.ToplamAygit;
  end

  // pci bilgilerini al
  else if(IslevNo = 2) then
  begin

    SiraNo := PISayi4(ADegiskenler + 00)^;
    if(SiraNo >= 0) and (SiraNo < GPCIAygitlar.ToplamAygit) then
    begin

      P3 := PPCI3(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr);
      P := GPCIAygitlar.PCI[SiraNo];
      if not(P = nil) then
      begin

        P3^.Yol := P.FYol;
        P3^.Aygit := P.FAygit;
        P3^.Islev := P.FIslev;
        P3^.AYRLD0 := 0;
        P3^.SaticiKimlik := P.FSaticiKimlik;
        P3^.AygitKimlik := P.FAygitKimlik;
        P3^.SinifKod := P.FSinifKod;
        Result := HATA_YOK;
      end else Result := HATA_DEGERARALIKDISI;
    end else Result := HATA_DEGERARALIKDISI;
  end

  // pci aygıtından 1 byte veri oku
  else if(IslevNo = 3) then
  begin

    Result := GPCIAygitlar.Oku1(PSayi4(ADegiskenler + 00)^, PSayi4(ADegiskenler + 04)^,
      PSayi4(ADegiskenler + 08)^, PSayi4(ADegiskenler + 12)^) and $FF;
  end

  // pci aygıtından 2 byte veri oku
  else if(IslevNo = 4) then
  begin

    Result := GPCIAygitlar.Oku2(PSayi4(ADegiskenler + 00)^, PSayi4(ADegiskenler + 04)^,
      PSayi4(ADegiskenler + 08)^, PSayi4(ADegiskenler + 12)^) and $FFFF;
  end

  // pci aygıtından 4 byte veri oku
  else if(IslevNo = 5) then
  begin

    Result := GPCIAygitlar.Oku4(PSayi4(ADegiskenler + 00)^, PSayi4(ADegiskenler + 04)^,
      PSayi4(ADegiskenler + 08)^, PSayi4(ADegiskenler + 12)^);
  end

  // pci aygıtına 1 byte veri yaz
  else if(IslevNo = 6) then
  begin

    GPCIAygitlar.Yaz1(PSayi4(ADegiskenler + 00)^, PSayi4(ADegiskenler + 04)^, PSayi4(ADegiskenler + 08)^,
      PSayi4(ADegiskenler + 12)^, PSayi4(ADegiskenler + 16)^);
  end

  // pci aygıtına 2 byte veri yaz
  else if(IslevNo = 7) then
  begin

    GPCIAygitlar.Yaz2(PSayi4(ADegiskenler + 00)^, PSayi4(ADegiskenler + 04)^, PSayi4(ADegiskenler + 08)^,
      PSayi4(ADegiskenler + 12)^, PSayi4(ADegiskenler + 16)^);
  end

  // pci aygıtına 4 byte veri yaz
  else if(IslevNo = 8) then
  begin

    GPCIAygitlar.Yaz4(PSayi4(ADegiskenler + 00)^, PSayi4(ADegiskenler + 04)^, PSayi4(ADegiskenler + 08)^,
      PSayi4(ADegiskenler + 12)^, PSayi4(ADegiskenler + 16)^);
  end;
end;

end.
