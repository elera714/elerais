{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: k_dosya.pas
  Dosya Ýþlevi: dosya (file) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 12/10/2019

 ==============================================================================}
{$mode objfpc}
unit k_dosya;

interface

uses paylasim;

function DosyaCagriIslevleri(IslevNo: TSayi4; Degiskenler: Isaretci): TISayi4;

implementation

uses dosya;

{==============================================================================
  dosya (file) kesme çaðrýlarýný yönetir
 ==============================================================================}
function DosyaCagriIslevleri(IslevNo: TSayi4; Degiskenler: Isaretci): TISayi4;
var
  _Islev: TSayi4;
begin

  _Islev := (IslevNo and $FF);

  case _Islev of

    // dosya aramayý baþlat
    2:
    begin

      Result := FindFirst(PKarakterKatari(Isaretci(PSayi4(Degiskenler + 00)^ +
        CalisanGorevBellekAdresi))^, PSayi2(Degiskenler + 04)^,
        PDosyaArama(PSayi4(Degiskenler + 06)^ + CalisanGorevBellekAdresi)^);
    end;

    // dosya aramayý devam ettir
    3:
    begin

      Result := FindNext(PDosyaArama(PSayi4(Degiskenler + 00)^ +
        CalisanGorevBellekAdresi)^);
    end;

    // dosya aramayý sonlandýr
    4:
    begin

      Result := FindClose(PDosyaArama(PSayi4(Degiskenler + 00)^ +
        CalisanGorevBellekAdresi)^);
    end;

    // iþlem yapýlacak dosya atamasýný gerçekleþtir
    5:
    begin

      AssignFile(PKimlik(PSayi4(Degiskenler + 00)^ + CalisanGorevBellekAdresi)^,
        PKarakterKatari(Isaretci(PSayi4(Degiskenler + 04)^ + CalisanGorevBellekAdresi))^);
    end;

    // dosyayý aç
    6:
    begin

      Reset(PKimlik(Degiskenler + 00)^);
    end;

    // dosyanýn en son iþlem durumunu al
    7:
    begin

      Result := IOResult;
    end;

    // dosyanýn sonuna gelinip gelinmediðini denetle
    8:
    begin

      Result := Integer(EOF(PKimlik(Degiskenler + 00)^));
    end;

    // dosya uzunluðunu al
    9:
    begin

      Result := FileSize(PKimlik(Degiskenler + 00)^);
    end;

    // dosya içeriðini oku
    10:
    begin

      Read(PKimlik(Degiskenler + 00)^, Isaretci(PSayi4(Degiskenler + 04)^ +
        CalisanGorevBellekAdresi));
    end;

    // dosyayý kapat
    11:
    begin

      CloseFile(PKimlik(Degiskenler + 00)^);
    end

    else Result := HATA_ISLEV;
  end;
end;

end.
