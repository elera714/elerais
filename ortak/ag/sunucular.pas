{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: sunucular.pas
  Dosya İşlevi: çekirdek içerisinde çalışan sunucuları yönetir

  Güncelleme Tarihi: 11/11/2026

 ==============================================================================}
{$mode objfpc}
unit sunucular;

interface

uses paylasim;

type
  TTemelSunucu = class
  public
  end;

type
  TTCPSunucu = class(TTemelSunucu)
  public
    // sunucuya istemcinin bağlanmış olma durumu
    procedure OIstemciBaglandi(ABaglanti: TObject); virtual; abstract;
    // sunucuya verinin gelmiş olma durumu
    procedure OVeriGeldi(ABaglanti: TObject); virtual; abstract;
    // sunucudan verinin gönderilmiş, karşı taraftan onaylanmış olma durumu
    procedure OVeriGonderildi(ABaglanti: TObject); virtual; abstract;
  end;

type
  TUDPSunucu = class(TTemelSunucu)
  public
    // sunucuya verinin gelmiş olma durumu
    procedure OVeriGeldi(AEthernetPaket: PEthernetPaket); virtual; abstract;
  end;

type
  TUDPIstemci = class(TTemelSunucu)
  public
    // istemciye verinin gelmiş olma durumu
    procedure OVeriGeldi(AEthernetPaket: PEthernetPaket); virtual; abstract;
  end;

implementation

end.
