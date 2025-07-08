{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: k_olay.pas
  Dosya Ýþlevi: olay (event) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 07/07/2025

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
  G: PGorev;
  O: TOlay;
  O2: POlay;
  IslevNo: TSayi4;
  OlayMevcut: Boolean;
begin

  IslevNo := (AIslevNo and $FF);

  // görev için olay olsun (olayla) veya olmasýn (olaysýz) göreve geri döner
  if(IslevNo = 1) then
  begin

    G := GorevAl(-1);

    // çalýþan proses'e ait olay var mý ?
    if(GGorevler.OlayAl(G^.FGorevKimlik, O)) then

      OlayMevcut := True
    else OlayMevcut := False;

    // olay deðiþkenlerini görevin yýðýn alanýna kopyala
    if(OlayMevcut) then
    begin

      O2 := POlay(PSayi4(ADegiskenler)^ + FAktifGorevBellekAdresi);
      O2^.Kimlik := O.Kimlik;
      O2^.Olay := O.Olay;
      O2^.Deger1 := O.Deger1;
      O2^.Deger2 := O.Deger2;

      Result := G^.FOlaySayisi;
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

    G := GorevAl(-1);

    // uygulama için olay üretilinceye kadar bekle
    // olay olmamasý durumda bir sonraki göreve geç (mevcut görev olay bekliyor)
    // ta ki ilgili görev için olay mevcut oluncaya kadar
    repeat

      if(GGorevler.OlayAl(G^.FGorevKimlik, O)) then

        OlayMevcut := True
      else OlayMevcut := False;

      if not(OlayMevcut) then ElleGorevDegistir;
    until (OlayMevcut = True);

    // olay deðiþkenlerini görevin yýðýn alanýna kopyala
    O2 := POlay(PSayi4(ADegiskenler)^ + FAktifGorevBellekAdresi);
    O2^.Kimlik := O.Kimlik;
    O2^.Olay := O.Olay;
    O2^.Deger1 := O.Deger1;
    O2^.Deger2 := O.Deger2;

    Result := G^.FOlaySayisi;
  end;
end;

end.
