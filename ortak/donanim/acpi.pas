{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: acpi.pas
  Dosya Ýþlevi: geliþmiþ ayar ve güç arabirim iþlevlerini yönetir

  Güncelleme Tarihi: 30/01/2025

  https://wiki.osdev.org/RSDP

 ==============================================================================}
{$mode objfpc}
unit acpi;

interface

uses paylasim;

type
  PRSDPTanimlayici = ^TRSDPTanimlayici;
  TRSDPTanimlayici = packed record
    Imza: array[0..7] of Char;
    Kontrol: TSayi1;
    OEMKimlik: array[0..5] of Char;
    Degisim: TSayi1;                    // revision
    RSDTAdres: TSayi4;
  end;

type
  PRSDTTanimlayici = ^TRSDTTanimlayici;
  TRSDTTanimlayici = packed record
    Imza: array[0..3] of Char;
    Uzunluk: TSayi4;
    Degisim: TSayi1;                    // revision
    Kontrol: TSayi1;
    OEMKimlik: array[0..5] of Char;
    OEMTabloKimlik: array[0..7] of Char;
    OEMDegisim: TSayi4;
    OlusturanKimlik: TSayi4;
    OlusturanDegisim: TSayi4;
  end;

const
  ACPI_BELLEK_BAS = TSayi4($E0000);
  ACPI_BELLEK_SON = TSayi4($FFFFF);

  ACPI_IMZA: PChar = 'RSD PTR ';

var
  _RSDP: PRSDPTanimlayici = nil;
  _RSDT: PRSDTTanimlayici;
  RSDPTanimlayici: TRSDPTanimlayici;
  RSDTSayisi: TSayi4;

procedure Yukle;
procedure Goruntule;

implementation

uses sistemmesaj;

procedure Yukle;
var
  ACPI_BELLEK: PChar;
begin

  RSDPTanimlayici.RSDTAdres := 0;

  ACPI_BELLEK := PChar(ACPI_BELLEK_BAS);
  while (TSayi4(ACPI_BELLEK) < ACPI_BELLEK_SON) do
  begin

    if(Karsilastir(ACPI_BELLEK, ACPI_IMZA, 8) = 0) then
    begin

      // RSDP yapý bilgileri
      _RSDP := Isaretci(ACPI_BELLEK);
      RSDPTanimlayici.Imza := Copy(_RSDP^.Imza, 0, 8);
      RSDPTanimlayici.Kontrol := _RSDP^.Kontrol;
      RSDPTanimlayici.OEMKimlik := Copy(_RSDP^.OEMKimlik, 0, 8);
      RSDPTanimlayici.Degisim := _RSDP^.Degisim;
      RSDPTanimlayici.RSDTAdres := _RSDP^.RSDTAdres;

      // RSDT yapý bilgileri
      _RSDT := PRSDTTanimlayici(RSDPTanimlayici.RSDTAdres);
      RSDTSayisi := (_RSDT^.Uzunluk - SizeOf(TRSDTTanimlayici)) div 4;

      Goruntule;
      Exit;
    end;

    ACPI_BELLEK += 16;
  end;
end;

procedure Goruntule;
begin

  if(RSDPTanimlayici.RSDTAdres = 0) then

    SISTEM_MESAJ(mtUyari, RENK_SIYAH, 'Hata: sistemde ACPI mevcut deðil!', [])
  else
  begin

    SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'ACPI Donaným Bilgileri:', []);
    SISTEM_MESAJ_S16(mtBilgi, RENK_SIYAH, 'Adres: ', TSayi4(_RSDP), 8);
    SISTEM_MESAJ_YAZI(mtBilgi, RENK_SIYAH, PChar('Ýmza: '), 5, PChar(RSDPTanimlayici.Imza), 8);
    SISTEM_MESAJ_S16(mtBilgi, RENK_SIYAH, 'Kontrol: ', RSDPTanimlayici.Kontrol, 2);
    SISTEM_MESAJ_YAZI(mtBilgi, RENK_SIYAH, PChar('Kimlik: '), 8, PChar(RSDPTanimlayici.OEMKimlik), 6);
    SISTEM_MESAJ_S16(mtBilgi, RENK_SIYAH, 'Deðiþim: ', RSDPTanimlayici.Degisim, 2);
    SISTEM_MESAJ_S16(mtBilgi, RENK_SIYAH, 'RSDT Adres: ', RSDPTanimlayici.RSDTAdres, 8);
    SISTEM_MESAJ_S16(mtBilgi, RENK_SIYAH, 'RSDT Sayýsý: ', RSDTSayisi, 8);
  end;
end;

end.
