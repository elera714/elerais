{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: k_zamanlayici.pas
  Dosya ��levi: zamanlay�c� kesme i�levlerini i�erir

  G�ncelleme Tarihi: 26/02/2025

 ==============================================================================}
{$mode objfpc}
unit k_zamanlayici;

interface

uses paylasim;

function ZamanlayiciCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses zamanlayici;

{==============================================================================
  zamanlay�c� kesme �a�r�lar�n� y�netir
 ==============================================================================}
function ZamanlayiciCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  Z: PZamanlayici;
  IslevNo: TSayi4;
begin

  // i�lev no
  IslevNo := (AIslevNo and $FF);

  // zamanlay�c� nesnesi olu�tur
  if(IslevNo = ISLEV_OLUSTUR) then
  begin

    Z := Z^.Olustur(PISayi4(ADegiskenler)^);

    if(Z <> nil) then
      Result := Z^.Kimlik
    else Result := -1;
  end

  // zamanlay�c� nesnesini ba�lat�r
  else if(IslevNo = 2) then
  begin

    Z := GZamanlayiciListesi[PKimlik(ADegiskenler)^];
    if(Z <> nil) then Z^.Durum := zdCalisiyor;
  end

  // zamanlay�c� nesnesini durdurur
  else if(IslevNo = 3) then
  begin

    Z := GZamanlayiciListesi[PKimlik(ADegiskenler)^];

    if(Z <> nil) then Z^.Durum := zdDurduruldu;
  end

  // i�lev belirtilen aral�kta de�ilse hata kodunu geri d�nd�r
  else Result := HATA_ISLEV;
end;

end.
