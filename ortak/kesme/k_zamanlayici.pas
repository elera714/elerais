{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: k_zamanlayici.pas
  Dosya Ýþlevi: zamanlayýcý kesme iþlevlerini içerir

  Güncelleme Tarihi: 19/02/2025

 ==============================================================================}
{$mode objfpc}
unit k_zamanlayici;

interface

uses paylasim;

function ZamanlayiciCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses zamanlayici;

{==============================================================================
  zamanlayýcý kesme çaðrýlarýný yönetir
 ==============================================================================}
function ZamanlayiciCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  Zamanlayici: PZamanlayici;
  Islev: TSayi4;
begin

  // iþlev no
  Islev := (AIslevNo and $FF);

  // zamanlayýcý nesnesi oluþtur
  if(Islev = ISLEV_OLUSTUR) then
  begin

    Zamanlayici := Zamanlayici^.Olustur(PISayi4(ADegiskenler)^);

    if(Zamanlayici <> nil) then
      Result := Zamanlayici^.Kimlik
    else Result := -1;
  end

  // zamanlayýcý nesnesini baþlatýr
  else if(Islev = 2) then
  begin

    Zamanlayici := GZamanlayiciListesi[PKimlik(ADegiskenler)^];
    if(Zamanlayici <> nil) then Zamanlayici^.Durum := zdCalisiyor;
  end

  // zamanlayýcý nesnesini durdurur
  else if(Islev = 3) then
  begin

    Zamanlayici := GZamanlayiciListesi[PKimlik(ADegiskenler)^];

    if(Zamanlayici <> nil) then Zamanlayici^.Durum := zdDurduruldu;
  end

  // iþlev belirtilen aralýkta deðilse hata kodunu geri döndür
  else Result := HATA_ISLEV;
end;

end.
