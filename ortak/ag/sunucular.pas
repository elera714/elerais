{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: sunucular.pas
  Dosya İşlevi: çekirdek içerisinde çalışan sunuucuları yönetir

  Güncelleme Tarihi: 10/06/2026

 ==============================================================================}
{$mode objfpc}
unit sunucular;

interface

uses paylasim, baglanti, http, ftp;

const
  HIZMETVEREN_SUNUCU_SAYISI = 2;

type
  TSunucuIslev = procedure(APaketTipi: TSayi4; ABaglanti: PBaglanti; AEthernetPaket: PEthernetPaket);

  PSunucuYapisi = ^TSunucuYapisi;
  TSunucuYapisi = record
    PortNo: TSayi4;         // sunucunun dinleme yapacağı port numarası (http -> 80 gibi)
    Islev: TSunucuIslev;    // porta gelen istekleri işleyecek olan işlev
  end;

var
  SunucuListesi: array[0..HIZMETVEREN_SUNUCU_SAYISI - 1] of TSunucuYapisi = (
    (PortNo: 80; Islev: @SunucuIslevHTTP),
    (PortNo: 21; Islev: @SunucuIslevFTP));

implementation

end.
