{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_bellek.pas
  Dosya İşlevi: bellek kesme işlevlerini içerir

  Güncelleme Tarihi: 07/02/2025

 ==============================================================================}
{$mode objfpc}
unit k_bellek;

interface

uses paylasim;

function BellekCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses genel, islevler;

{==============================================================================
  bellek kesme çağrılarını yönetir
 ==============================================================================}
function BellekCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  IslevNo, Kaynak, Hedef,
  Uzunluk: TSayi4;
  p: PSayi4;
begin

  IslevNo := (AIslevNo and $FF);

  // çekirdek bellek kullanım bilgilerini al
  if(IslevNo = 1) then
  begin

    p := PSayi4(PSayi4(ADegiskenler + 00)^ + CalisanGorevBellekAdresi);
    p^ := CekirdekBaslangicAdresi;
    p := PSayi4(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi);
    p^ := CekirdekBaslangicAdresi + CekirdekUzunlugu;
    p := PSayi4(PSayi4(ADegiskenler + 08)^ + CalisanGorevBellekAdresi);
    p^ := CekirdekUzunlugu;

    Result := 1;
  end

  // genel bellek kullanım bilgilerini al
  else if(IslevNo = 2) then
  begin

    p := PSayi4(PSayi4(ADegiskenler + 00)^ + CalisanGorevBellekAdresi);
    p^ := GGercekBellek.ToplamBlok;
    p := PSayi4(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi);
    p^ := GGercekBellek.AyrilmisBlok;
    p := PSayi4(PSayi4(ADegiskenler + 08)^ + CalisanGorevBellekAdresi);
    p^ := GGercekBellek.KullanilmisBlok;
    p := PSayi4(PSayi4(ADegiskenler + 12)^ + CalisanGorevBellekAdresi);
    p^ := GGercekBellek.ToplamBlok - GGercekBellek.KullanilmisBlok;
    p := PSayi4(PSayi4(ADegiskenler + 16)^ + CalisanGorevBellekAdresi);
    p^ := 4096;

    Result := 1;
  end

  // bellek adres içeriğini oku
  else if(IslevNo = 3) then
  begin

    Kaynak := PSayi4(ADegiskenler + 00)^;
    Hedef := PSayi4(ADegiskenler + 04)^;
    Uzunluk := PSayi4(ADegiskenler + 08)^;
    if(Kaynak + Uzunluk > GGercekBellek.ToplamRAM) then

      Result := HATA_BELLEKOKUMA
    else
    begin

      Tasi2(Isaretci(Kaynak), Isaretci(Hedef + CalisanGorevBellekAdresi), Uzunluk);
      Result := 1;
    end;
  end

  else Result := HATA_ISLEV;
end;

end.
