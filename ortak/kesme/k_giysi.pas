{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_giysi.pas
  Dosya İşlevi: giysi (skin) kesme işlevlerini yönetir

  Güncelleme Tarihi: 07/08/2025

 ==============================================================================}
{$mode objfpc}
unit k_giysi;

interface

uses giysi, paylasim;

function GiysiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses genel, gorev;

function GiysiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  Islev, GiysiSN: TSayi4;
  p: PKarakterKatari;
begin

  // işlev no
  Islev := (AIslevNo and $FFFFFF);

  // giysi sayısını geri döndür
  if(Islev = 1) then
  begin

    Result := Giysiler0.ToplamGiysi;
  end
  else if(Islev = 2) then
  begin

    GiysiSN := PSayi4(ADegiskenler + 00)^;
    if(GiysiSN < Giysiler0.ToplamGiysi) then
    begin

      p := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
      p^ := Giysiler0.Giysi[GiysiSN]^.Ad;
    end;
  end
  else if(Islev = 3) then
  begin

    Result :=  Giysiler0.AktifGiysiSN;
  end
  else if(Islev = 4) then
  begin

    GiysiSN := PSayi4(ADegiskenler + 00)^;
    if(GiysiSN < Giysiler0.ToplamGiysi) then
    begin

      Giysiler0.AktifGiysiSN := GiysiSN;
      Giysiler0.AktifGiysi := Giysiler0.Giysi[Giysiler0.AktifGiysiSN];
      GAktifMasaustu^.Ciz;
    end;
  end

  // işlev belirtilen aralıkta değil ise hata kodunu geri döndür
  else Result := HATA_ISLEV;
end;

end.
