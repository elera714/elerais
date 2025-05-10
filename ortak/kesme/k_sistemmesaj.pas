{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_sistemmesaj.pas
  Dosya İşlevi: hata ayıklama (debug) amaçlı mesaj yönetim işlevlerini içerir

  Güncelleme Tarihi: 10/05/2025

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
  p: PMesajKayit;
  IslevNo: TSayi4;
begin

  // ana işlev
  IslevNo := (AIslevNo and $FF);

  // toplam sistem mesaj sayısını al
  if(IslevNo = 1) then
  begin

    Result := GSistemMesaj.ToplamMesaj;
  end

  // sistem mesaj bilgisini program hedef bellek bölgesine kopyala
  else if(IslevNo = 2) then
  begin

    p := PMesajKayit(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi);
    GSistemMesaj.MesajAl(PISayi4(ADegiskenler + 00)^, p);
    Result := GSistemMesaj.ToplamMesaj;
  end

  // programdan karakter katarı türünde gelen mesajı sistem mesajlarına ekle
  else if(IslevNo = 3) then
  begin

    SISTEM_MESAJ(PMesajTipi(ADegiskenler + 00)^, PRenk(ADegiskenler + 04)^,
      PKarakterKatari(Isaretci(PSayi4(ADegiskenler + 08)^ + CalisanGorevBellekAdresi))^, []);
  end

  // programdan karakter katarı + sayısal değer türünde gelen mesajı sistem mesajlarına ekle
  else if(IslevNo = 4) then
  begin

    SISTEM_MESAJ(PMesajTipi(ADegiskenler + 00)^, PRenk(ADegiskenler + 04)^,
      PKarakterKatari(Isaretci(PSayi4(ADegiskenler + 08)^ + CalisanGorevBellekAdresi))^,
      [PSayi4(ADegiskenler + 12)^]); //, PSayi4(ADegiskenler + 16)^);
      { TODO - üstte iptal edilen ifadeyi api işlevinden çıkar }
  end

  // toplam sistem mesaj sayısını al
  else if(IslevNo = 5) then
  begin

    GSistemMesaj.Temizle;
  end
end;

end.
