{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_sistem.pas
  Dosya İşlevi: sistem kesme işlevlerini içerir

  Güncelleme Tarihi: 06/08/2020

 ==============================================================================}
{$mode objfpc}
unit k_sistem;

interface

uses paylasim;

function SistemCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses genel;

function SistemCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  SB: PSistemBilgisi;
  IB: PIslemciBilgisi;
  Islev: TSayi4;
begin

  // işlev no
  Islev := (AIslevNo and $FF);

  // sistem bilgilerini al
  if(Islev = 1) then
  begin

    SB := PSistemBilgisi(PSayi4(ADegiskenler + 00)^ + CalisanGorevBellekAdresi);
    SB^.SistemAdi := SistemAdi;
    SB^.DerlemeBilgisi := DerlemeTarihi;
    SB^.FPCMimari := FPCMimari;
    SB^.FPCSurum := FPCSurum;
    SB^.YatayCozunurluk := GEkranKartSurucusu.KartBilgisi.YatayCozunurluk;
    SB^.DikeyCozunurluk := GEkranKartSurucusu.KartBilgisi.DikeyCozunurluk;
  end
  // işlemci bilgisini al
  else if(Islev = 2) then
  begin

    IB := PIslemciBilgisi(PSayi4(ADegiskenler + 00)^ + CalisanGorevBellekAdresi);
    IB^.Satici := GIslemciBilgisi.Satici;
    IB^.Ozellik1_EAX := GIslemciBilgisi.Ozellik1_EAX;
    IB^.Ozellik1_EDX := GIslemciBilgisi.Ozellik1_EDX;
    IB^.Ozellik1_ECX := GIslemciBilgisi.Ozellik1_ECX;
  end

  // işlev belirtilen aralıkta değilse hata kodunu geri döndür
  else Result := HATA_ISLEV;
end;

end.
