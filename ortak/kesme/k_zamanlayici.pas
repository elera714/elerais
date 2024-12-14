{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: k_zamanlayici.pas
  Dosya ��levi: zamanlay�c� kesme i�levlerini i�erir

  G�ncelleme Tarihi: 23/06/2020

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
  Zamanlayici: PZamanlayici;
  Islev: TSayi4;
begin

  // i�lev no
  Islev := (AIslevNo and $FF);

  // zamanlay�c� nesnesi olu�tur
  if(Islev = ISLEV_OLUSTUR) then
  begin

    Zamanlayici := Zamanlayici^.Olustur(PISayi4(ADegiskenler)^);

    if(Zamanlayici <> nil) then
      Result := Zamanlayici^.Kimlik
    else Result := -1;
  end

  // zamanlay�c� nesnesini ba�lat�r
  else if(Islev = 2) then
  begin

    Zamanlayici := ZamanlayiciListesi[PKimlik(ADegiskenler)^];
    if(Zamanlayici <> nil) then Zamanlayici^.Durum := zdCalisiyor;
  end

  // zamanlay�c� nesnesini durdurur
  else if(Islev = 3) then
  begin

    Zamanlayici := ZamanlayiciListesi[PKimlik(ADegiskenler)^];

    if(Zamanlayici <> nil) then Zamanlayici^.Durum := zdDurduruldu;
  end

  // i�lev belirtilen aral�kta de�ilse hata kodunu geri d�nd�r
  else Result := HATA_ISLEV;
end;

end.
