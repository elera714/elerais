{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_giysi.pas
  Dosya İşlevi: giysi (skin) işlevlerini yönetir

  Güncelleme Tarihi: 11/08/2020

 ==============================================================================}
{$mode objfpc}
unit k_giysi;

interface

uses giysi_normal, giysi_mac, paylasim;

type
  TGiysiler = record
    Ad: string;
    Adres: PGiysi;
  end;

const
  TOPLAM_GIYSISAYISI = 2;

var
  GiysiListesi: array[0..TOPLAM_GIYSISAYISI - 1] of TGiysiler = (
    (Ad: 'Normal Giysi'; Adres: @GiysiNormal),
    (Ad: 'MAC Giysi'; Adres: @GiysiMac));

function GiysiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses genel, gorev;

function GiysiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  Islev, GiysiNo: TSayi4;
  p: PKarakterKatari;
begin

  // işlev no
  Islev := (AIslevNo and $FFFFFF);

  // giysi sayısını geri döndür
  if(Islev = 1) then
  begin

    Result := TOPLAM_GIYSISAYISI;
  end
  else if(Islev = 2) then
  begin

    GiysiNo := PSayi4(ADegiskenler + 00)^;
    if(GiysiNo < TOPLAM_GIYSISAYISI) then
    begin

      p := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
      p^ := GiysiListesi[GiysiNo].Ad;
    end;
  end
  else if(Islev = 3) then
  begin

    Result := AktifGiysiSiraNo;
  end
  else if(Islev = 4) then
  begin

    GiysiNo := PSayi4(ADegiskenler + 00)^;
    if(GiysiNo < TOPLAM_GIYSISAYISI) then
    begin

      AktifGiysiSiraNo := GiysiNo;
      AktifGiysi := GiysiListesi[AktifGiysiSiraNo].Adres^;
      GAktifMasaustu^.Ciz;
    end;
  end

  // işlev belirtilen aralıkta değil ise hata kodunu geri döndür
  else Result := HATA_ISLEV;
end;

end.
