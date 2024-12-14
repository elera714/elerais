{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: k_dosya.pas
  Dosya ��levi: dosya (file) y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 12/10/2019

 ==============================================================================}
{$mode objfpc}
unit k_dosya;

interface

uses paylasim;

function DosyaCagriIslevleri(IslevNo: TSayi4; Degiskenler: Isaretci): TISayi4;

implementation

uses dosya;

{==============================================================================
  dosya (file) kesme �a�r�lar�n� y�netir
 ==============================================================================}
function DosyaCagriIslevleri(IslevNo: TSayi4; Degiskenler: Isaretci): TISayi4;
var
  _Islev: TSayi4;
begin

  _Islev := (IslevNo and $FF);

  case _Islev of

    // dosya aramay� ba�lat
    2:
    begin

      Result := FindFirst(PKarakterKatari(Isaretci(PSayi4(Degiskenler + 00)^ +
        CalisanGorevBellekAdresi))^, PSayi2(Degiskenler + 04)^,
        PDosyaArama(PSayi4(Degiskenler + 06)^ + CalisanGorevBellekAdresi)^);
    end;

    // dosya aramay� devam ettir
    3:
    begin

      Result := FindNext(PDosyaArama(PSayi4(Degiskenler + 00)^ +
        CalisanGorevBellekAdresi)^);
    end;

    // dosya aramay� sonland�r
    4:
    begin

      Result := FindClose(PDosyaArama(PSayi4(Degiskenler + 00)^ +
        CalisanGorevBellekAdresi)^);
    end;

    // i�lem yap�lacak dosya atamas�n� ger�ekle�tir
    5:
    begin

      AssignFile(PKimlik(PSayi4(Degiskenler + 00)^ + CalisanGorevBellekAdresi)^,
        PKarakterKatari(Isaretci(PSayi4(Degiskenler + 04)^ + CalisanGorevBellekAdresi))^);
    end;

    // dosyay� a�
    6:
    begin

      Reset(PKimlik(Degiskenler + 00)^);
    end;

    // dosyan�n en son i�lem durumunu al
    7:
    begin

      Result := IOResult;
    end;

    // dosyan�n sonuna gelinip gelinmedi�ini denetle
    8:
    begin

      Result := Integer(EOF(PKimlik(Degiskenler + 00)^));
    end;

    // dosya uzunlu�unu al
    9:
    begin

      Result := FileSize(PKimlik(Degiskenler + 00)^);
    end;

    // dosya i�eri�ini oku
    10:
    begin

      Read(PKimlik(Degiskenler + 00)^, Isaretci(PSayi4(Degiskenler + 04)^ +
        CalisanGorevBellekAdresi));
    end;

    // dosyay� kapat
    11:
    begin

      CloseFile(PKimlik(Degiskenler + 00)^);
    end

    else Result := HATA_ISLEV;
  end;
end;

end.
