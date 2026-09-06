{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: lldp_i.pas
  Dosya Ýþlevi: baðlantý katmaný keþif tutanak (link layer discovery protocol)
    yönetim iþlevlerini içerir

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
  private
    FBaglanti: TObject;
  public
    constructor Create(ABaglanti: TObject);
    procedure VerileriIsle(AEthernetPaket: PEthernetPaket);
  end;

implementation

uses sistemmesaj, donusum, islevler;

constructor TLLDP.Create(ABaglanti: TObject);
begin

  FBaglanti := ABaglanti;
end;

procedure TLLDP.VerileriIsle(AEthernetPaket: PEthernetPaket);
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
      SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - Sistem Adý: %s', [s]);
    end
    else if(VT = 6) then
    begin

      Tasi2(@LLDPPaket^.Veri, @s[1], U);
      SetLength(s, U);
      SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - Sistem Açýklama: %s', [s]);
    end;

    p := Isaretci(LLDPPaket);
    Inc(p, U + 2);
    LLDPPaket := Isaretci(p);
  end;
end;

end.
