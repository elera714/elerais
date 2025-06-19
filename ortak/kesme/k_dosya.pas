{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: k_dosya.pas
  Dosya ��levi: dosya (file) y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 25/05/2025

 ==============================================================================}
{$mode objfpc}
unit k_dosya;

interface

uses paylasim;

function DosyaCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses dosya, sistemmesaj, gorev;

{==============================================================================
  dosya (file) kesme �a�r�lar�n� y�netir
 ==============================================================================}
function DosyaCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  IslevNo: TSayi4;
  s: string;
begin

  IslevNo := (AIslevNo and $FF);

  case IslevNo of

    // dosya aramay� ba�lat
    2:
    begin

      Result := FindFirst(PKarakterKatari(PSayi4(ADegiskenler + 00)^ + FAktifGorevBellekAdresi)^,
        PSayi4(ADegiskenler + 04)^, PDosyaArama(PSayi4(ADegiskenler + 08)^ + FAktifGorevBellekAdresi)^);
    end;

    // dosya aramay� devam ettir
    3:
    begin

      Result := FindNext(PDosyaArama(PSayi4(ADegiskenler + 00)^ +
        FAktifGorevBellekAdresi)^);
    end;

    // dosya aramay� sonland�r
    4:
    begin

      Result := FindClose(PDosyaArama(PSayi4(ADegiskenler + 00)^ +
        FAktifGorevBellekAdresi)^);
    end;

    // i�lem yap�lacak dosya atamas�n� ger�ekle�tir
    5:
    begin

      AssignFile(PKimlik(PSayi4(ADegiskenler + 00)^ + FAktifGorevBellekAdresi)^,
        PKarakterKatari(Isaretci(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi))^);
    end;

    // dosyay� a�
    6:
    begin

      Reset(PKimlik(ADegiskenler + 00)^);
    end;

    // dosyan�n en son i�lem durumunu al
    7:
    begin

      Result := IOResult;
    end;

    // dosyan�n sonuna gelinip gelinmedi�ini denetle
    8:
    begin

      Result := Integer(EOF(PKimlik(ADegiskenler + 00)^));
    end;

    // dosya uzunlu�unu al
    9:
    begin

      Result := FileSize(PKimlik(ADegiskenler + 00)^);
    end;

    // dosya i�eri�ini oku
    10:
    begin

      Read(PKimlik(ADegiskenler + 00)^, Isaretci(PSayi4(ADegiskenler + 04)^ +
        FAktifGorevBellekAdresi));
    end;

    // dosyay� kapat
    11:
    begin

      CloseFile(PKimlik(ADegiskenler + 00)^);
    end;

    // dosyay� sil
    12:
    begin

      s := PKarakterKatari(PSayi4(ADegiskenler + 00)^ + FAktifGorevBellekAdresi)^;
      DeleteFile(s);
    end;

    // klas�r sil
    13:
    begin

      s := PKarakterKatari(PSayi4(ADegiskenler + 00)^ + FAktifGorevBellekAdresi)^;
      RemoveDir(s);
    end;

    // dosya olu�tur
    14:
    begin

      ReWrite(PKimlik(ADegiskenler + 00)^);
    end;

    // dosyaya veri yaz
    15:
    begin

      Write(PKimlik(ADegiskenler + 00)^,
        PKarakterKatari(Isaretci(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi))^);
    end;

    else Result := HATA_ISLEV;
  end;
end;

end.
