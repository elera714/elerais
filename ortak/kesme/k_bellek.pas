{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_bellek.pas
  Dosya İşlevi: bellek kesme işlevlerini içerir

  Güncelleme Tarihi: 23/09/2026

 ==============================================================================}
{$mode objfpc}
unit k_bellek;

interface

uses paylasim;

function BellekCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses islevler, gorev, gercekbellek;

{==============================================================================
  bellek kesme çağrılarını yönetir
 ==============================================================================}
function BellekCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  IslevNo, Kaynak, Hedef,
  Uzunluk: TSayi4;
  p: PSayi4;
begin

  Result := HATA_ISLEV;

  IslevNo := (AIslevNo and $FF);

  // çekirdek bellek kullanım bilgilerini al
  if(IslevNo = 1) then
  begin

    p := PSayi4(PSayi4(ADegiskenler + 00)^ + GGorevler.FAktifGrvBelAdr);
    p^ := CekirdekBaslangicAdresi;
    p := PSayi4(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr);
    p^ := CekirdekBaslangicAdresi + CekirdekUzunlugu;
    p := PSayi4(PSayi4(ADegiskenler + 08)^ + GGorevler.FAktifGrvBelAdr);
    p^ := CekirdekUzunlugu;

    Result := HATA_YOK;
  end

  // genel bellek kullanım bilgilerini al
  else if(IslevNo = 2) then
  begin

    p := PSayi4(PSayi4(ADegiskenler + 00)^ + GGorevler.FAktifGrvBelAdr);
    p^ := GGercekBellek.ToplamBlok;
    p := PSayi4(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr);
    p^ := GGercekBellek.AyrilmisBlok;
    p := PSayi4(PSayi4(ADegiskenler + 08)^ + GGorevler.FAktifGrvBelAdr);
    p^ := GGercekBellek.KullanilmisBlok;
    p := PSayi4(PSayi4(ADegiskenler + 12)^ + GGorevler.FAktifGrvBelAdr);
    p^ := GGercekBellek.ToplamBlok - GGercekBellek.KullanilmisBlok;
    p := PSayi4(PSayi4(ADegiskenler + 16)^ + GGorevler.FAktifGrvBelAdr);
    p^ := 4096;

    Result := HATA_YOK;
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

      Tasi2(Isaretci(Kaynak), Isaretci(Hedef + GGorevler.FAktifGrvBelAdr), Uzunluk);
      Result := HATA_YOK;
    end;
  end;
end;

end.
