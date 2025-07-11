{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: k_olay.pas
  Dosya ��levi: olay (event) y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 07/07/2025

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
  G: PGorev;
  O: TOlay;
  O2: POlay;
  IslevNo: TSayi4;
  OlayMevcut: Boolean;
begin

  IslevNo := (AIslevNo and $FF);

  // g�rev i�in olay olsun (olayla) veya olmas�n (olays�z) g�reve geri d�ner
  if(IslevNo = 1) then
  begin

    G := GorevAl(-1);

    // �al��an proses'e ait olay var m� ?
    if(GGorevler.OlayAl(G^.FGorevKimlik, O)) then

      OlayMevcut := True
    else OlayMevcut := False;

    // olay de�i�kenlerini g�revin y���n alan�na kopyala
    if(OlayMevcut) then
    begin

      O2 := POlay(PSayi4(ADegiskenler)^ + FAktifGorevBellekAdresi);
      O2^.Kimlik := O.Kimlik;
      O2^.Olay := O.Olay;
      O2^.Deger1 := O.Deger1;
      O2^.Deger2 := O.Deger2;

      Result := G^.FOlaySayisi;
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

    G := GorevAl(-1);

    // uygulama i�in olay �retilinceye kadar bekle
    // olay olmamas� durumda bir sonraki g�reve ge� (mevcut g�rev olay bekliyor)
    // ta ki ilgili g�rev i�in olay mevcut oluncaya kadar
    repeat

      if(GGorevler.OlayAl(G^.FGorevKimlik, O)) then

        OlayMevcut := True
      else OlayMevcut := False;

      if not(OlayMevcut) then ElleGorevDegistir;
    until (OlayMevcut = True);

    // olay de�i�kenlerini g�revin y���n alan�na kopyala
    O2 := POlay(PSayi4(ADegiskenler)^ + FAktifGorevBellekAdresi);
    O2^.Kimlik := O.Kimlik;
    O2^.Olay := O.Olay;
    O2^.Deger1 := O.Deger1;
    O2^.Deger2 := O.Deger2;

    Result := G^.FOlaySayisi;
  end;
end;

end.
