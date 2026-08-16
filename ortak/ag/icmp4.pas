{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: icmp4.pas
  Dosya İşlevi: ICMP v4 protokol yönetim işlevlerini içerir

  Güncelleme Tarihi: 16/08/2026

 ==============================================================================}
{$mode objfpc}
//{$DEFINE ICMP4_HATAAYIKLA}
unit icmp4;

interface

uses paylasim;

const
  ICMP4_BASLIK_UZUNLUGU = 8;
  ICMP4_YANKI_ISTEK     = 8;
  ICMP4_YANKI_YANIT     = 0;

type
  PICMP4Paket = ^TICMP4Paket;
  TICMP4Paket = packed record
    MesajTipi,
    Kod: TSayi1;
    SaglamaToplami,
    Tanimlayici, DiziSiraNo: TSayi2;
    Veri: Isaretci;
  end;

type
  TICMP4 = class
  public
    constructor Create;
    procedure PaketGonder(AICMPPaket: PICMP4Paket; APaketUzunlugu: TSayi4;
      AHedefIPAdres: TIP4Adres);
    procedure PaketleriIsle(AICMPPaket: PICMP4Paket; APaketUzunlugu: TSayi4;
      AHedefIPAdres: TIP4Adres);
  end;

var
  GICMP4: TICMP4;

implementation

uses ip4, islevler, sistemmesaj, ag;

constructor TICMP4.Create;
begin

end;

// icmp v4 protokolü üzerinden gelen paketleri işler
procedure TICMP4.PaketleriIsle(AICMPPaket: PICMP4Paket; APaketUzunlugu: TSayi4;
  AHedefIPAdres: TIP4Adres);
var
  s: array[0..128] of TSayi1;
  i: TSayi4;
begin

  i := APaketUzunlugu - ICMP4_BASLIK_UZUNLUGU;
  Tasi2(@AICMPPaket^.Veri, @s[0], i);

  {$IFDEF ICMP4_HATAAYIKLA}
  SISTEM_MESAJ(mtBilgi, RENK_PEMBE, 'ICMP4 Başlık Bilgileri:', []);
  SISTEM_MESAJ_IP4(mtBilgi, RENK_LACIVERT, ' -> Kaynak IP: ', AHedefIPAdres);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, ' -> Veri Uzunluğu: ', [i]);
  {$ENDIF}

  // istek (request) mesajına yanıt
  if(AICMPPaket^.MesajTipi = ICMP4_YANKI_ISTEK) then
  begin

    // yanıt gönder
    PaketGonder(AICMPPaket, APaketUzunlugu, AHedefIPAdres);

  end else SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'ICMP4.PAS: bilinmeyen mesaj tipi: $%.2x',
    [AICMPPaket^.MesajTipi]);
end;

// icmp v4 protokol paketi hazırlayıp gönderme işlevini gerçekleştirir
procedure TICMP4.PaketGonder(AICMPPaket: PICMP4Paket; APaketUzunlugu: TSayi4;
  AHedefIPAdres: TIP4Adres);
var
  ICMPPaket: PICMP4Paket;
  s: array[0..128] of TSayi1;
  p: PSayi1;
  i: TSayi4;
  SaglamaToplami: TSayi2;
begin

  i := APaketUzunlugu - ICMP4_BASLIK_UZUNLUGU;
  Tasi2(@AICMPPaket^.Veri, @s[0], i);

  // gönderilecek paket için bellek bölgesi oluştur
  ICMPPaket := GetMem(4096);

  //IcmpPacket := @IPPacket^.Data;
  ICMPPaket^.MesajTipi := ICMP4_YANKI_YANIT;
  ICMPPaket^.Kod := 0;
  ICMPPaket^.Tanimlayici := AICMPPaket^.Tanimlayici;
  ICMPPaket^.DiziSiraNo := AICMPPaket^.DiziSiraNo;
  p := @ICMPPaket^.Veri;
  Tasi2(@s[0], p, i);

  ICMPPaket^.SaglamaToplami := 0;
  SaglamaToplami := SaglamaToplamiOlustur(ICMPPaket, ICMP4_BASLIK_UZUNLUGU + i, nil, 0);
  ICMPPaket^.SaglamaToplami := SaglamaToplami;

  // sisteme gelen icmp isteğine icmp yanıtı (paket) gönder
  IP4PaketGonder(MACAdres255, GAg.IP4Adres, AHedefIPAdres, ptICMP4, 0,
    ICMPPaket, ICMP4_BASLIK_UZUNLUGU + i);

  {$IFDEF ICMP4_HATAAYIKLA}
  SISTEM_MESAJ_IP4(mtBilgi, RENK_MOR, 'ICMP4 yanıtı gönderilen IP: ', AHedefIPAdres);
  {$ENDIF}

  // belleği yok et
  FreeMem(ICMPPaket, 4096);
end;

end.
