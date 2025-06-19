{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_sistem.pas
  Dosya İşlevi: sistem kesme işlevlerini içerir

  Güncelleme Tarihi: 19/02/2025

 ==============================================================================}
{$mode objfpc}
unit k_sistem;

interface

uses paylasim;

function SistemCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses genel, sistem, gorev;

function SistemCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  SB: PSistemBilgisi;
  IB: PIslemciBilgisi;
  IslevNo, i: TSayi4;
  s: string;
  p: Isaretci;
begin

  // işlev no
  IslevNo := (AIslevNo and $FF);

  // sistem bilgilerini al
  if(IslevNo = 1) then
  begin

    SB := PSistemBilgisi(PSayi4(ADegiskenler + 00)^ + FAktifGorevBellekAdresi);
    SB^.SistemAdi := SistemAdi;
    SB^.DerlemeBilgisi := DerlemeTarihi;
    SB^.FPCMimari := FPCMimari;
    SB^.FPCSurum := FPCSurum;
    SB^.YatayCozunurluk := GEkranKartSurucusu.KartBilgisi.YatayCozunurluk;
    SB^.DikeyCozunurluk := GEkranKartSurucusu.KartBilgisi.DikeyCozunurluk;
  end
  // işlemci bilgisini al
  else if(IslevNo = 2) then
  begin

    IB := PIslemciBilgisi(PSayi4(ADegiskenler + 00)^ + FAktifGorevBellekAdresi);
    IB^.Satici := GIslemciBilgisi.Satici;
    IB^.Ozellik1_EAX := GIslemciBilgisi.Ozellik1_EAX;
    IB^.Ozellik1_EDX := GIslemciBilgisi.Ozellik1_EDX;
    IB^.Ozellik1_ECX := GIslemciBilgisi.Ozellik1_ECX;
  end
  // sistem sürücü / klasör / dosya bilgisini al
  // sistem ile ilgili tüm sürücü / klasör / dosya bilgileri bu işlev yoluyla alınacaktır
  else if(IslevNo = 3) then
  begin

    i := PSayi4(ADegiskenler + 00)^;
    case i of
      // sistem açılış sürücüsü
      0: s := AcilisSurucuAygiti;
      // sistem programlarının bulunduğu klasör
      1: s := KLASOR_PROGRAM;
      else s := '';
    end;

    p := Isaretci(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
    PKarakterKatari(p)^ := s;
  end

  // bilgisayarı yeniden başlat
  else if(IslevNo = 4) then
  begin

    YenidenBaslat;
  end

  // bilgisayarı kapat
  else if(IslevNo = 5) then
  begin

    BilgisayariKapat;
  end

  // işlev belirtilen aralıkta değilse hata kodunu geri döndür
  else Result := HATA_ISLEV;
end;

end.
