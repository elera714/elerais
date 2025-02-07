{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_bellek.pas
  Dosya İşlevi: bellek kesme işlevlerini içerir

  Güncelleme Tarihi: 09/08/2019

 ==============================================================================}
{$mode objfpc}
unit k_bellek;

interface

uses paylasim;

function BellekCagriIslevleri(IslevNo: TSayi4; Degiskenler: Isaretci): TISayi4;

implementation

uses genel, islevler;

{==============================================================================
  bellek kesme çağrılarını yönetir
 ==============================================================================}
function BellekCagriIslevleri(IslevNo: TSayi4; Degiskenler: Isaretci): TISayi4;
var
  _Islev, Kaynak, Hedef,
  Uzunluk: TSayi4;
  p: PSayi4;
begin

  _Islev := (IslevNo and $FF);

  // çekirdek bellek kullanım bilgilerini al
  if(_Islev = 1) then
  begin

    p := PSayi4(PSayi4(Degiskenler + 00)^ + CalisanGorevBellekAdresi);
    p^ := CekirdekBaslangicAdresi;
    p := PSayi4(PSayi4(Degiskenler + 04)^ + CalisanGorevBellekAdresi);
    p^ := CekirdekBaslangicAdresi + CekirdekUzunlugu;
    p := PSayi4(PSayi4(Degiskenler + 08)^ + CalisanGorevBellekAdresi);
    p^ := CekirdekUzunlugu;

    Result := 1;
  end

  // genel bellek kullanım bilgilerini al
  else if(_Islev = 2) then
  begin

    p := PSayi4(PSayi4(Degiskenler + 00)^ + CalisanGorevBellekAdresi);
    p^ := GGercekBellek.ToplamBlok;
    p := PSayi4(PSayi4(Degiskenler + 04)^ + CalisanGorevBellekAdresi);
    p^ := GGercekBellek.AyrilmisBlok;
    p := PSayi4(PSayi4(Degiskenler + 08)^ + CalisanGorevBellekAdresi);
    p^ := GGercekBellek.KullanilmisBlok;
    p := PSayi4(PSayi4(Degiskenler + 12)^ + CalisanGorevBellekAdresi);
    p^ := GGercekBellek.ToplamBlok - GGercekBellek.KullanilmisBlok;
    p := PSayi4(PSayi4(Degiskenler + 16)^ + CalisanGorevBellekAdresi);
    p^ := 4096;

    Result := 1;
  end

  // bellek adres içeriğini oku
  else if(_Islev = 3) then
  begin

    Kaynak := PSayi4(Degiskenler + 00)^;
    Hedef := PSayi4(Degiskenler + 04)^;
    Uzunluk := PSayi4(Degiskenler + 08)^;
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
