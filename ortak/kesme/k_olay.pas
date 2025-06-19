{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: k_olay.pas
  Dosya Ýþlevi: olay (event) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 01/01/2025

 ==============================================================================}
{$mode objfpc}
unit k_olay;

interface

uses paylasim;

function OlayCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses genel, gorev, zamanlayici;

{==============================================================================
  olay kesme çaðrýlarýný yönetir
 ==============================================================================}
function OlayCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  Gorev: PGorev;
  Olay: TOlay;
  _Olay: POlay;
  IslevNo: TSayi4;
  OlayMevcut: Boolean;
begin

  IslevNo := (AIslevNo and $FF);

  // görev için olay olsun (olayla) veya olmasýn (olaysýz) göreve geri döner
  if(IslevNo = 1) then
  begin

    Gorev := GorevListesi[FAktifGorev];

    // çalýþan proses'e ait olay var mý ?
    if(Gorev^.OlayAl(Olay)) then

      OlayMevcut := True
    else OlayMevcut := False;

    // olay deðiþkenlerini görevin yýðýn alanýna kopyala
    if(OlayMevcut) then
    begin

      _Olay := POlay(PSayi4(ADegiskenler)^ + FAktifGorevBellekAdresi);
      _Olay^.Kimlik := Olay.Kimlik;
      _Olay^.Olay := Olay.Olay;
      _Olay^.Deger1 := Olay.Deger1;
      _Olay^.Deger2 := Olay.Deger2;

      Result := Gorev^.OlaySayisi;
    end

    // olay yok ise tek bir görev deðiþikliði yap ve görevi istekte bulunan devret.
    // aksi durumda kaynaklarýn hemen hemen hepsini kendisi kullanýr
    else
    begin

      ElleGorevDegistir;
      Result := 0;
    end;
  end

  // istekte bulunan görev için olay mevcut oluncaya kadar bekle ve olayý geri döndür
  else if(IslevNo = 2) then
  begin

    Gorev := GorevListesi[FAktifGorev];

    // uygulama için olay üretilinceye kadar bekle
    // olay olmamasý durumda bir sonraki göreve geç (mevcut görev olay bekliyor)
    // ta ki ilgili görev için olay mevcut oluncaya kadar
    repeat

      if(Gorev^.OlayAl(Olay)) then

        OlayMevcut := True
      else OlayMevcut := False;

      if not(OlayMevcut) then ElleGorevDegistir;
    until (OlayMevcut = True);

    // olay deðiþkenlerini görevin yýðýn alanýna kopyala
    _Olay := POlay(PSayi4(ADegiskenler)^ + FAktifGorevBellekAdresi);
    _Olay^.Kimlik := Olay.Kimlik;
    _Olay^.Olay := Olay.Olay;
    _Olay^.Deger1 := Olay.Deger1;
    _Olay^.Deger2 := Olay.Deger2;

    Result := Gorev^.OlaySayisi;
  end;
end;

end.
