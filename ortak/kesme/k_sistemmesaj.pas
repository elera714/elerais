{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_sistemmesaj.pas
  Dosya İşlevi: hata ayıklama (debug) amaçlı mesaj yönetim işlevlerini içerir

  Güncelleme Tarihi: 03/09/2024

 ==============================================================================}
{$mode objfpc}
unit k_sistemmesaj;

interface

uses paylasim;

function SistemMesajCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses genel, sistemmesaj;

{==============================================================================
  mesaj kesme çağrılarını yönetir
 ==============================================================================}
function SistemMesajCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  p: PMesaj;
  IslevNo: TSayi4;
begin

  // ana işlev
  IslevNo := (AIslevNo and $FF);

  // toplam ssitem mesaj sayısını al
  if(IslevNo = 1) then
  begin

    Result := GSistemMesaj.ToplamMesaj;
  end

  // sistem mesaj bilgisini program hedef bellek bölgesine kopyala
  else if(IslevNo = 2) then
  begin

    p := PMesaj(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi);
    GSistemMesaj.MesajAl(PSayi4(ADegiskenler + 00)^, p);
    Result := GSistemMesaj.ToplamMesaj;
  end

  // programdan karakter katarı türünde gelen mesajı sistem mesajlarına ekle
  else if(IslevNo = 3) then
  begin

    SISTEM_MESAJ(PRenk(ADegiskenler + 00)^, PKarakterKatari(Isaretci(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi))^, []);
  end

  // programdan karakter katarı + sayısal değer türünde gelen mesajı sistem mesajlarına ekle
  else if(IslevNo = 4) then
  begin

    SISTEM_MESAJ_S16(PRenk(ADegiskenler + 00)^, PKarakterKatari(Isaretci(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi))^,
      PSayi4(ADegiskenler + 08)^, PSayi4(ADegiskenler + 12)^);
  end;
end;

end.
