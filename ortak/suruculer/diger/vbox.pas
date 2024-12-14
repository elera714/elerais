{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: vbox.pas
  Dosya ��levi: virtualbox sanal ayg�t y�netim i�levlerini i�erir

  G�ncelleme Tarihi: 06/10/2024

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
  a� ilk de�er y�klemelerini ger�ekle�tirir
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
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'VBox Ayg�t: ', PCIAygit.Aygit, 2);
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'VBox ��lev: ', PCIAygit.Islev, 2);
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'VBox Sat�c� Kimlik: ', PCIAygit.SaticiKimlik, 4);
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'VBox Ayg�t Kimlik: ', PCIAygit.AygitKimlik, 4);

  if((Port and 1) = 1) then
    SISTEM_MESAJ_S16(RENK_KIRMIZI, 'VBox Port: ', Port and $FFFC, 4)
  else SISTEM_MESAJ_S16(RENK_KIRMIZI, 'VBox Bellek: ', Port and $FFFC, 8);

  // 10. bitin 1 olmas� kesmenin pasif oldu�u anlam�na gelir
  if(KesmeAktif and (1 shl 10) = 0) then
    SISTEM_MESAJ(RENK_KIRMIZI, 'INT Aktif', [])
  else SISTEM_MESAJ(RENK_KIRMIZI, 'INT Pasif', []);

  SISTEM_MESAJ_S16(RENK_KIRMIZI, 'Kesme No: ', KesmeNo, 2);
end;

end.
