{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: k_dosya.pas
  Dosya Ýþlevi: dosya (file) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 04/04/2025

 ==============================================================================}
{$mode objfpc}
unit k_dosya;

interface

uses paylasim;

function DosyaCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses dosya, sistemmesaj;

{==============================================================================
  dosya (file) kesme çaðrýlarýný yönetir
 ==============================================================================}
function DosyaCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  IslevNo: TSayi4;
  s: string;
begin

  IslevNo := (AIslevNo and $FF);

  case IslevNo of

    // dosya aramayý baþlat
    2:
    begin

      Result := FindFirst(PKarakterKatari(PSayi4(ADegiskenler + 00)^ + CalisanGorevBellekAdresi)^,
        PSayi4(ADegiskenler + 04)^, PDosyaArama(PSayi4(ADegiskenler + 08)^ + CalisanGorevBellekAdresi)^);
    end;

    // dosya aramayý devam ettir
    3:
    begin

      Result := FindNext(PDosyaArama(PSayi4(ADegiskenler + 00)^ +
        CalisanGorevBellekAdresi)^);
    end;

    // dosya aramayý sonlandýr
    4:
    begin

      Result := FindClose(PDosyaArama(PSayi4(ADegiskenler + 00)^ +
        CalisanGorevBellekAdresi)^);
    end;

    // iþlem yapýlacak dosya atamasýný gerçekleþtir
    5:
    begin

      AssignFile(PKimlik(PSayi4(ADegiskenler + 00)^ + CalisanGorevBellekAdresi)^,
        PKarakterKatari(Isaretci(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi))^);
    end;

    // dosyayý aç
    6:
    begin

      Reset(PKimlik(ADegiskenler + 00)^);
    end;

    // dosyanýn en son iþlem durumunu al
    7:
    begin

      Result := IOResult;
    end;

    // dosyanýn sonuna gelinip gelinmediðini denetle
    8:
    begin

      Result := Integer(EOF(PKimlik(ADegiskenler + 00)^));
    end;

    // dosya uzunluðunu al
    9:
    begin

      Result := FileSize(PKimlik(ADegiskenler + 00)^);
    end;

    // dosya içeriðini oku
    10:
    begin

      Read(PKimlik(ADegiskenler + 00)^, Isaretci(PSayi4(ADegiskenler + 04)^ +
        CalisanGorevBellekAdresi));
    end;

    // dosyayý kapat
    11:
    begin

      CloseFile(PKimlik(ADegiskenler + 00)^);
    end;

    // dosyayý sil
    12:
    begin

      s := PKarakterKatari(PSayi4(ADegiskenler + 00)^ + CalisanGorevBellekAdresi)^;
      DeleteFile(s);
    end;

    // klasör sil
    13:
    begin

      s := PKarakterKatari(PSayi4(ADegiskenler + 00)^ + CalisanGorevBellekAdresi)^;
      RemoveDir(s);
    end

    else Result := HATA_ISLEV;
  end;
end;

end.
