{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: src_e1000.pas
  Dosya ��levi: intel e1000 a� (network) s�r�c�s�

  G�ncelleme Tarihi: 08/05/2025

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
  intel e1000 a� s�r�c� y�kleme i�levlerini i�erir
 ==============================================================================}
function Yukle(APCI: PPCI): TISayi4;
begin

  // ��k�� �nde�eri
  Result := -1;

  // �ekirde�in g�nderdi�i pci ayg�t bilgilerini hedef b�lgeye kopyala
  AygitBilgisi.Yol := APCI^.Yol;
  AygitBilgisi.Aygit := APCI^.Aygit;
  AygitBilgisi.Islev := APCI^.Islev;

  // ayg�t port de�erini al
  AygitBilgisi.PortDegeri := IlkPortDegeriniAl(APCI);
  if(AygitBilgisi.PortDegeri = 0) then
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'E1000 ethernet port de�eri al�nam�yor!', []);
    Exit;
  end;

  AygitBilgisi.BellekDegeri := IlkBellekDegeriniAl(APCI);
  if(AygitBilgisi.BellekDegeri = 0) then
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'E1000 ethernet bellek de�eri al�nam�yor!', []);
    Exit;
  end;

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'E1000 ayg�t bilgileri:', []);
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'Port De�eri: %x', [AygitBilgisi.PortDegeri]);
  SISTEM_MESAJ(mtBilgi, RENK_MOR, 'Bellek De�eri : %x', [AygitBilgisi.BellekDegeri]);
end;

end.
