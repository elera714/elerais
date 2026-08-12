{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_giysi.pas
  Dosya İşlevi: giysi (skin) kesme işlevlerini yönetir

  Güncelleme Tarihi: 12/08/2026

 ==============================================================================}
{$mode objfpc}
unit k_giysi;

interface

uses giysi, paylasim;

function GiysiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses gorev, gn_islevler;

function GiysiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  IslevNo, GiysiSN: TSayi4;
  p: PKarakterKatari;
begin

  Result := HATA_ISLEV;

  // işlev no
  IslevNo := (AIslevNo and $FFFFFF);

  // giysi sayısını geri döndür
  if(IslevNo = 1) then
  begin

    Result := GGiysiler.ToplamGiysi;
  end
  else if(IslevNo = 2) then
  begin

    GiysiSN := PSayi4(ADegiskenler + 00)^;
    if(GiysiSN < GGiysiler.ToplamGiysi) then
    begin

      p := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
      p^ := GGiysiler.Giysi[GiysiSN].Ad;
    end;
  end
  else if(IslevNo = 3) then
  begin

    Result :=  GGiysiler.AktifGiysiSN;
  end
  else if(IslevNo = 4) then
  begin

    GiysiSN := PSayi4(ADegiskenler + 00)^;
    if(GiysiSN < GGiysiler.ToplamGiysi) then
    begin

      GGiysiler.AktifGiysiSN := GiysiSN;
      GGiysiler.AktifGiysi := GGiysiler.Giysi[GGiysiler.AktifGiysiSN];
      GGorselNesneler.AktifMasaustu.Ciz;
    end;
  end;
end;

end.
