{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: icmp.pas
  Dosya Ýþlevi: ICMP protokol yönetim iþlevlerini içerir

  Güncelleme Tarihi: 27/12/2024

 ==============================================================================}
{$mode objfpc}
//{$DEFINE ICMP_HATAAYIKLA}
unit icmp;

interface

uses paylasim;

const
  ICMP_BASLIK_UZUNLUGU  = 8;
  ICMP_YANKI_ISTEK      = 8;
  ICMP_YANKI_YANIT      = 0;

type
  PICMPBaslik = ^TICMPBaslik;
  TICMPBaslik = packed record
    MesajTipi,
    Kod: TSayi1;
    BaslikSaglamaToplami,
    Tanimlayici, DiziSiraNo: TSayi2;
    Veri: Isaretci;
  end;

procedure ICMPPaketleriniIsle(AICMPBaslik: PICMPBaslik; APaketUzunlugu: TSayi4;
  AHedefIPAdres: TIPAdres);
procedure ICMPPaketGonder(AICMPBaslik: PICMPBaslik; APaketUzunlugu: TSayi4;
  AHedefIPAdres: TIPAdres);

implementation

uses genel, donusum, ip, sistemmesaj;

// icmp protokolü üzerinden gelen paketleri iþler
procedure ICMPPaketleriniIsle(AICMPBaslik: PICMPBaslik; APaketUzunlugu: TSayi4;
  AHedefIPAdres: TIPAdres);
var
  s: array[0..128] of Byte;
  i: TSayi4;
begin

  i := APaketUzunlugu - ICMP_BASLIK_UZUNLUGU;
  Tasi2(@AICMPBaslik^.Veri, @s[0], i);

  {$IFDEF ICMP_HATAAYIKLA}
  SISTEM_MESAJ_IP(RENK_LACIVERT, 'ICMP kaynak IP: ', AHedefIPAdres);
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'ICMP veri uzunluðu: ', _VeriUzunlugu, 4);
  SISTEM_MESAJ(RENK_LACIVERT, 'ICMP veri: ' + _Veri, []);
  {$ENDIF}

  // istek (request) mesajýna yanýt
  if(AICMPBaslik^.MesajTipi = ICMP_YANKI_ISTEK) then
  begin

    // yanýt gönder
    ICMPPaketGonder(AICMPBaslik, APaketUzunlugu, AHedefIPAdres);
  end
  else SISTEM_MESAJ_S16(RENK_KIRMIZI, 'ICMP.PAS: bilinmeyen mesaj tipi: ', AICMPBaslik^.MesajTipi, 2);
end;

// icmp protokol paketi hazýrlayýp gönderme iþlevini gerçekleþtirir
procedure ICMPPaketGonder(AICMPBaslik: PICMPBaslik; APaketUzunlugu: TSayi4;
  AHedefIPAdres: TIPAdres);
var
  ICMPBaslik: PICMPBaslik;
  s: array[0..128] of Byte;
  p: PByte;
  i: TSayi4;
  SaglamaToplami: TSayi2;
begin

  i := APaketUzunlugu - ICMP_BASLIK_UZUNLUGU;
  Tasi2(@AICMPBaslik^.Veri, @s[0], i);

  // gönderilecek paket için bellek bölgesi oluþtur
  ICMPBaslik := GGercekBellek.Ayir(4095);

  //IcmpPacket := @IPPacket^.Data;
  ICMPBaslik^.MesajTipi := ICMP_YANKI_YANIT;
  ICMPBaslik^.Kod := 0;
  ICMPBaslik^.Tanimlayici := AICMPBaslik^.Tanimlayici;
  ICMPBaslik^.DiziSiraNo := AICMPBaslik^.DiziSiraNo;
  p := @ICMPBaslik^.Veri;
  Tasi2(@s[0], p, i);

  ICMPBaslik^.BaslikSaglamaToplami := 0;
  SaglamaToplami := SaglamaToplamiOlustur(ICMPBaslik, ICMP_BASLIK_UZUNLUGU + i, nil, 0);
  ICMPBaslik^.BaslikSaglamaToplami := SaglamaToplami;

  // sisteme gelen icmp isteðine icmp yanýtý (paket) gönder
  IPPaketGonder(MACAdres255, GAgBilgisi.IP4Adres, AHedefIPAdres, ptICMP, 0,
    ICMPBaslik, ICMP_BASLIK_UZUNLUGU + i);

  {$IFDEF ICMP_HATAAYIKLA}
  SISTEM_MESAJ_IP(RENK_KIRMIZI, 'ICMP yanýtý gönderilen IP: ', AHedefIPAdres);
  {$ENDIF}

  // belleði yok et
  GGercekBellek.YokEt(ICMPBaslik, 4095);
end;

end.
