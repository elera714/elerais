{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: icmp4.pas
  Dosya Ýþlevi: ICMP v4 protokol yönetim iþlevlerini içerir

  Güncelleme Tarihi: 28/07/2026

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

procedure ICMPPaketleriniIsle(AICMPPaket: PICMP4Paket; APaketUzunlugu: TSayi4;
  AHedefIPAdres: TIP4Adres);
procedure ICMP4PaketGonder(AICMPPaket: PICMP4Paket; APaketUzunlugu: TSayi4;
  AHedefIPAdres: TIP4Adres);

implementation

uses genel, donusum, ip4, islevler, sistemmesaj, ag;

// icmp protokolü üzerinden gelen paketleri iþler
procedure ICMPPaketleriniIsle(AICMPPaket: PICMP4Paket; APaketUzunlugu: TSayi4;
  AHedefIPAdres: TIP4Adres);
var
  s: array[0..128] of TSayi1;
  i: TSayi4;
begin

  i := APaketUzunlugu - ICMP4_BASLIK_UZUNLUGU;
  Tasi2(@AICMPPaket^.Veri, @s[0], i);

  {$IFDEF ICMP4_HATAAYIKLA}
  SISTEM_MESAJ_IP(RENK_LACIVERT, 'ICMP4 kaynak IP: ', AHedefIPAdres);
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'ICMP4 veri uzunluðu: ', _VeriUzunlugu, 4);
  SISTEM_MESAJ(RENK_LACIVERT, 'ICMP4 veri: ' + _Veri, []);
  {$ENDIF}

  // istek (request) mesajýna yanýt
  if(AICMPPaket^.MesajTipi = ICMP4_YANKI_ISTEK) then
  begin

    // yanýt gönder
    ICMP4PaketGonder(AICMPPaket, APaketUzunlugu, AHedefIPAdres);
  end
  else SISTEM_MESAJ(mtUyari, RENK_SIYAH, 'ICMP4.PAS: bilinmeyen mesaj tipi: $%.2x',
    [AICMPPaket^.MesajTipi]);
end;

// icmp v4 protokol paketi hazýrlayýp gönderme iþlevini gerçekleþtirir
procedure ICMP4PaketGonder(AICMPPaket: PICMP4Paket; APaketUzunlugu: TSayi4;
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

  // gönderilecek paket için bellek bölgesi oluþtur
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

  // sisteme gelen icmp isteðine icmp yanýtý (paket) gönder
  IP4PaketGonder(MACAdres255, GAg0.IP4Adres, AHedefIPAdres, ptICMP4, 0,
    ICMPPaket, ICMP4_BASLIK_UZUNLUGU + i);

  {$IFDEF ICMP4_HATAAYIKLA}
  SISTEM_MESAJ_IP(RENK_KIRMIZI, 'ICMP4 yanýtý gönderilen IP: ', AHedefIPAdres);
  {$ENDIF}

  // belleði yok et
  FreeMem(ICMPPaket, 4096);
end;

end.
