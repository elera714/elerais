{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: k_zamanlayici.pas
  Dosya Ýþlevi: zamanlayýcý kesme iþlevlerini içerir

  Güncelleme Tarihi: 26/02/2025

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
  Z: PZamanlayici;
  IslevNo: TSayi4;
begin

  // iþlev no
  IslevNo := (AIslevNo and $FF);

  // zamanlayýcý nesnesi oluþtur
  if(IslevNo = ISLEV_OLUSTUR) then
  begin

    Z := Z^.Olustur(PISayi4(ADegiskenler)^);

    if(Z <> nil) then
      Result := Z^.Kimlik
    else Result := -1;
  end

  // zamanlayýcý nesnesini baþlatýr
  else if(IslevNo = 2) then
  begin

    Z := GZamanlayiciListesi[PKimlik(ADegiskenler)^];
    if(Z <> nil) then Z^.Durum := zdCalisiyor;
  end

  // zamanlayýcý nesnesini durdurur
  else if(IslevNo = 3) then
  begin

    Z := GZamanlayiciListesi[PKimlik(ADegiskenler)^];

    if(Z <> nil) then Z^.Durum := zdDurduruldu;
  end

  // iþlev belirtilen aralýkta deðilse hata kodunu geri döndür
  else Result := HATA_ISLEV;
end;

end.
