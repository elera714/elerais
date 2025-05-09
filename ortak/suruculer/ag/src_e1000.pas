{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: src_e1000.pas
  Dosya Ýþlevi: intel e1000 að (network) sürücüsü

  Güncelleme Tarihi: 08/05/2025

 ==============================================================================}
{$mode objfpc}
unit src_e1000;

interface

uses paylasim;

type
  TAygit = packed record
    Yol, Aygit,
    Islev: TSayi1;
    PortDegeri: TSayi2;
    BellekDegeri: TSayi4;
    IRQNo: TSayi1;
    CipSurum: TSayi4;
    CipAdi: PChar;
    MACAdres: TMACAdres;
  end;

var
  AygitBilgisi: TAygit;

function Yukle(APCI: PPCI): TISayi4;

implementation

uses pci, sistemmesaj;

{==============================================================================
  intel e1000 að sürücü yükleme iþlevlerini içerir
 ==============================================================================}
function Yukle(APCI: PPCI): TISayi4;
begin

  // çýkýþ öndeðeri
  Result := -1;

  // çekirdeðin gönderdiði pci aygýt bilgilerini hedef bölgeye kopyala
  AygitBilgisi.Yol := APCI^.Yol;
  AygitBilgisi.Aygit := APCI^.Aygit;
  AygitBilgisi.Islev := APCI^.Islev;

  // aygýt port deðerini al
  AygitBilgisi.PortDegeri := IlkPortDegeriniAl(APCI);
  if(AygitBilgisi.PortDegeri = 0) then
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'E1000 ethernet port deðeri alýnamýyor!', []);
    Exit;
  end;

  AygitBilgisi.BellekDegeri := IlkBellekDegeriniAl(APCI);
  if(AygitBilgisi.BellekDegeri = 0) then
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'E1000 ethernet bellek deðeri alýnamýyor!', []);
    Exit;
  end;

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'E1000 aygýt bilgileri:', []);
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'Port Deðeri: %x', [AygitBilgisi.PortDegeri]);
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'Bellek Deðeri : %x', [AygitBilgisi.BellekDegeri]);
end;

end.
