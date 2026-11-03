{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: sunucular.pas
  Dosya İşlevi: çekirdek içerisinde çalışan sunucuları yönetir

  Güncelleme Tarihi: 02/11/2026

 ==============================================================================}
{$mode objfpc}
unit sunucular;

interface

uses paylasim, tcp;

type
  TTemelSunucu = class
  public
  end;

type
  TTCPSunucu = class(TTemelSunucu)
  public
    procedure OIstemciBaglandi(ATCP: TTCP); virtual; abstract;
    procedure OVeriGeldi(ATCP: TTCP); virtual; abstract;
    procedure OVeriGonderildi(ATCP: TTCP); virtual; abstract;
  end;

type
  TUDPSunucu = class(TTemelSunucu)
  public
    procedure OVeriGeldi(AEthernetPaket: PEthernetPaket); virtual; abstract;
  end;

type
  TUDPIstemci = class(TTemelSunucu)
  public
    procedure OVeriGeldi(AEthernetPaket: PEthernetPaket); virtual; abstract;
  end;

implementation

end.
