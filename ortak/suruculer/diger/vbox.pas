{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: vbox.pas
  Dosya Ýþlevi: virtualbox sanal aygýt yönetim iþlevlerini içerir

  Güncelleme Tarihi: 06/10/2024

 ==============================================================================}
{$mode objfpc}
unit vbox;

interface

uses paylasim, sistemmesaj, pci;

function Yukle(APCI: PPCI): TISayi4;
procedure Listele;

implementation

var
  PCIAygit: TPCI;

{==============================================================================
  að ilk deðer yüklemelerini gerçekleþtirir
 ==============================================================================}
function Yukle(APCI: PPCI): TISayi4;
begin

  PCIAygit := APCI^;
  Result := -1;
end;

procedure Listele;
var
  Port: TSayi4;
  KesmeAktif: TSayi2;
  KesmeNo: TSayi1;
begin

  Port := PCIOku4(PCIAygit.Yol, PCIAygit.Aygit, PCIAygit.Islev, $10);
  KesmeAktif := PCIOku2(PCIAygit.Yol, PCIAygit.Aygit, PCIAygit.Islev, $4);
  KesmeNo := PCIOku1(PCIAygit.Yol, PCIAygit.Aygit, PCIAygit.Islev, $3C);

  SISTEM_MESAJ_S16(RENK_LACIVERT, 'VBox Yol: ', PCIAygit.Yol, 2);
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'VBox Aygýt: ', PCIAygit.Aygit, 2);
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'VBox Ýþlev: ', PCIAygit.Islev, 2);
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'VBox Satýcý Kimlik: ', PCIAygit.SaticiKimlik, 4);
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'VBox Aygýt Kimlik: ', PCIAygit.AygitKimlik, 4);

  if((Port and 1) = 1) then
    SISTEM_MESAJ_S16(RENK_KIRMIZI, 'VBox Port: ', Port and $FFFC, 4)
  else SISTEM_MESAJ_S16(RENK_KIRMIZI, 'VBox Bellek: ', Port and $FFFC, 8);

  // 10. bitin 1 olmasý kesmenin pasif olduðu anlamýna gelir
  if(KesmeAktif and (1 shl 10) = 0) then
    SISTEM_MESAJ(RENK_KIRMIZI, 'INT Aktif', [])
  else SISTEM_MESAJ(RENK_KIRMIZI, 'INT Pasif', []);

  SISTEM_MESAJ_S16(RENK_KIRMIZI, 'Kesme No: ', KesmeNo, 2);
end;

end.
