{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: lldp_i.pas
  Dosya İşlevi: bağlantı katmanı keşif protokol (link layer discovery protocol)
    yönetim işlevlerini içerir

  Güncelleme Tarihi: 02/08/2026

 ==============================================================================}
{$mode objfpc}
unit lldp_i;

interface

uses paylasim;

type
  PLLDPPaket = ^TLLDPPaket;
  TLLDPPaket = packed record
    VTipUz: TSayi2;       // veri tipi ve uzunluk
    Veri: Isaretci;
  end;

type
  PLLDP = ^TLLDP;
  TLLDP = class
  public
    constructor Create;
    procedure PaketleriIsle(AEthernetPaket: PEthernetPaket);
  end;

var
  GLLDP: TLLDP;

implementation

uses sistemmesaj, donusum, islevler;

constructor TLLDP.Create;
begin

end;

procedure TLLDP.PaketleriIsle(AEthernetPaket: PEthernetPaket);
var
  LLDPPaket: PLLDPPaket;
  VT, U: TSayi4;
  VTipUz: TSayi2;
  p: Isaretci;
  s: string;
begin

  LLDPPaket := @AEthernetPaket^.Veri;

  VTipUz := ntohs(LLDPPaket^.VTipUz);

  SISTEM_MESAJ(mtBilgi, RENK_PEMBE, 'LLDP Mesaj Bilgileri.............:', []);

  while VTipUz <> 0 do
  begin

    VTipUz := ntohs(LLDPPaket^.VTipUz);

    VT := VTipUz;
    VT := (VT shr 9) and $00FF;

    U := VTipUz;
    U := (U and %111111111) and $00FF;

    if(VT = 1) then

      SISTEM_MESAJ_MAC(mtBilgi, RENK_TURKUAZ, '  - MAC: ', PMACAdres(@LLDPPaket^.Veri + 1)^)

    else if(VT = 5) then
    begin

      Tasi2(@LLDPPaket^.Veri, @s[1], U);
      SetLength(s, U);
      SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - Sistem Adı: %s', [s]);
    end
    else if(VT = 6) then
    begin

      Tasi2(@LLDPPaket^.Veri, @s[1], U);
      SetLength(s, U);
      SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - Sistem Açıklama: %s', [s]);
    end;

    p := Isaretci(LLDPPaket);
    Inc(p, U + 2);
    LLDPPaket := Isaretci(p);
  end;
end;

end.
