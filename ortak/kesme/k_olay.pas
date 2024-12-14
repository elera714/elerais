{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: k_olay.pas
  Dosya ��levi: olay (event) y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 23/06/2020

 ==============================================================================}
{$mode objfpc}
unit k_olay;

interface

uses paylasim;

function OlayCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses genel, gorev, zamanlayici;

{==============================================================================
  olay kesme �a�r�lar�n� y�netir
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

  // g�rev i�in olay olsun (olayla) veya olmas�n (olays�z) g�reve geri d�ner
  if(IslevNo = 1) then
  begin

    Gorev := GorevListesi[CalisanGorev];

    // �al��an proses'e ait olay var m� ?
    if(Gorev^.OlayAl(Olay)) then

      OlayMevcut := True
    else OlayMevcut := False;

    // olay de�i�kenlerini g�revin y���n alan�na kopyala
    if(OlayMevcut) then
    begin

      _Olay := POlay(PSayi4(ADegiskenler)^ + CalisanGorevBellekAdresi);
      _Olay^.Kimlik := Olay.Kimlik;
      _Olay^.Olay := Olay.Olay;
      _Olay^.Deger1 := Olay.Deger1;
      _Olay^.Deger2 := Olay.Deger2;

      Result := Gorev^.OlaySayisi;
    end

    // olay yok ise tek bir g�rev de�i�ikli�i yap ve g�revi istekte bulunan devret.
    // aksi durumda kaynaklar�n hemen hemen hepsini kendisi kullan�r
    else
    begin

      ElleGorevDegistir;
      Result := 0;
    end;
  end

  // istekte bulunan g�rev i�in olay mevcut oluncaya kadar bekle ve olay� geri d�nd�r
  else if(IslevNo = 2) then
  begin

    Gorev := GorevListesi[CalisanGorev];

    // uygulama i�in olay �retilinceye kadar bekle
    // olay olmamas� durumda bir sonraki g�reve ge� (mevcut g�rev olay bekliyor)
    // ta ki ilgili g�rev i�in olay mevcut oluncaya kadar
    repeat

      if(Gorev^.OlayAl(Olay)) then

        OlayMevcut := True
      else OlayMevcut := False;

      if not(OlayMevcut) then ElleGorevDegistir;
    until (OlayMevcut = True);

    // olay de�i�kenlerini g�revin y���n alan�na kopyala
    _Olay := POlay(PSayi4(ADegiskenler)^ + CalisanGorevBellekAdresi);
    _Olay^.Kimlik := Olay.Kimlik;
    _Olay^.Olay := Olay.Olay;
    _Olay^.Deger1 := Olay.Deger1;
    _Olay^.Deger2 := Olay.Deger2;

    Result := Gorev^.OlaySayisi;
  end;
end;

end.
