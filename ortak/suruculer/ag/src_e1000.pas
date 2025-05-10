{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: src_e1000.pas
  Dosya Ýþlevi: intel e1000 að (network) sürücüsü

  Güncelleme Tarihi: 10/05/2025

 ==============================================================================}
{$mode objfpc}
unit src_e1000;

interface

uses paylasim;

const
  REG_CTRL            = $0000;    // aygýt kontrol
  REG_STATUS          = $0008;    // aygýt durumu
  YAZMAC_EEPROM_OKU   = $0014;    // eeprom okuma
  YAZMAC_KESMEMASKESI = $00D0;    // kesme maskesi okuma / yazma
  YAZMAC_KESMEOKUMA   = $00C0;    // kesme okuma

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
  EEPROMVar: Boolean;

function Yukle(APCI: PPCI): TISayi4;
procedure KomutGonder(AAdres, AKomut: TSayi4);
function VeriOku(AAdres: TSayi4): TSayi4;
function EEPROMVarMi: Boolean;
procedure MACAdresiAl;
procedure KesmeAktiflestir;

implementation

uses pci, port, sistemmesaj;

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

  EEPROMVar := False;

  // aygýt port deðerini al
  AygitBilgisi.PortDegeri := IlkPortDegeriniAl(APCI);
  if(AygitBilgisi.PortDegeri = 0) then
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'E1000 ethernet port deðeri alýnamýyor!', []);
    Exit;
  end;

  // aygýt bellek deðerini al
  AygitBilgisi.BellekDegeri := IlkBellekDegeriniAl(APCI);
  if(AygitBilgisi.BellekDegeri = 0) then
  begin

    SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'E1000 ethernet bellek deðeri alýnamýyor!', []);
    Exit;
  end;

  // IRQ numarasýný al
  AygitBilgisi.IRQNo := IRQNoAl(APCI);

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'E1000 aygýt bilgileri:', []);
  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '----------------------', []);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'E1000 Yol: %d', [APCI^.Yol]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'E1000 Aygýt: %d', [APCI^.Aygit]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'E1000 Ýþlev: %d', [APCI^.Islev]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'E1000 Satýcý Kimlik: $%x', [APCI^.SaticiKimlik]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'E1000 Aygýt Kimlik: $%x', [APCI^.AygitKimlik]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'E1000 Port: $%x', [AygitBilgisi.PortDegeri]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'E1000 Bellek: $%x', [AygitBilgisi.BellekDegeri]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'E1000 IRQ: %d', [AygitBilgisi.IRQNo]);

  EEPROMVar := EEPROMVarMi;
{  if(EEPROMVar) then
    SISTEM_MESAJ(mtBilgi, RENK_MOR, 'EEPROM var', [])
  else SISTEM_MESAJ(mtBilgi, RENK_MOR, 'EEPROM yok', []);}

  // aygýtýn mac adresini al
  MACAdresiAl;

  // kesmeyi aktifleþtir
  KesmeAktiflestir;
end;

procedure KomutGonder(AAdres, AKomut: TSayi4);
begin

  PortYaz4(AygitBilgisi.PortDegeri + 0, AAdres);
  PortYaz4(AygitBilgisi.PortDegeri + 4, AKomut);
end;

function VeriOku(AAdres: TSayi4): TSayi4;
begin

  PortYaz4(AygitBilgisi.PortDegeri + 0, AAdres);
  Result := PortAl4(AygitBilgisi.PortDegeri + 4);
end;

function EEPROMVarMi: Boolean;
var
  i, j: TSayi4;
begin

  KomutGonder(YAZMAC_EEPROM_OKU, 1);

  for i := 0 to 1000 do
  begin

    j := VeriOku(YAZMAC_EEPROM_OKU);
    if((j and $10) <> 0) then Exit(True);
  end;

  Result := False;
end;

{==============================================================================
  aygýtýn mac adresini alýr
 ==============================================================================}
procedure MACAdresiAl;
var
  i, j, k: TSayi4;
begin

  k := 0;

  for i := 0 to 2 do
  begin

    KomutGonder(YAZMAC_EEPROM_OKU, (i shl 8) or 1);
    repeat
      j := VeriOku(YAZMAC_EEPROM_OKU);
    until (j and (1 shl 4)) <> 0;

    j := j shr 16;

    AygitBilgisi.MACAdres[k] := j;
    j := j shr 8;
    Inc(k);
    AygitBilgisi.MACAdres[k] := j;
    Inc(k);
  end;

  SISTEM_MESAJ_MAC(mtBilgi, RENK_MOR, 'E1000 MAC Adres: ', AygitBilgisi.MACAdres);
end;

{==============================================================================
  aygýtýn kesmesini aktifleþtirir
 ==============================================================================}
procedure KesmeAktiflestir;
begin
    KomutGonder(YAZMAC_KESMEMASKESI, $1F6DC);
    KomutGonder(YAZMAC_KESMEMASKESI, $FF and not(4));
    VeriOku(YAZMAC_KESMEOKUMA);
end;

end.
