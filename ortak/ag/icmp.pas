{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: icmp.pas
  Dosya Ýþlevi: ICMP protokol yönetim iþlevlerini içerir

  Güncelleme Tarihi: 16/09/2024

 ==============================================================================}
{$mode objfpc}
{$DEFINE ICMP_HATAAYIKLA}
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
    MesajTip,
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

uses genel, saglama, donusum, ip, sistemmesaj;

// icmp protokolü üzerinden gelen paketleri iþler
procedure ICMPPaketleriniIsle(AICMPBaslik: PICMPBaslik; APaketUzunlugu: TSayi4;
  AHedefIPAdres: TIPAdres);
var
  _Veri: string;
  _VeriUzunlugu: TSayi2;
begin

  _VeriUzunlugu := APaketUzunlugu - ICMP_BASLIK_UZUNLUGU;
  _Veri := Copy(PChar(@AICMPBaslik^.Veri), 0, _VeriUzunlugu);

  {$IFDEF ICMP_HATAAYIKLA}
  SISTEM_MESAJ_IP(RENK_LACIVERT, 'ICMP kaynak IP: ', AHedefIPAdres);
  SISTEM_MESAJ_S16(RENK_LACIVERT, 'ICMP veri uzunluðu: ', _VeriUzunlugu, 4);
  SISTEM_MESAJ(RENK_LACIVERT, 'ICMP veri: ' + _Veri, []);
  {$ENDIF}

  // istek (request) mesajýna yanýt
  if(AICMPBaslik^.MesajTip = ICMP_YANKI_ISTEK) then
  begin

    // yanýt gönder
    ICMPPaketGonder(AICMPBaslik, APaketUzunlugu, AHedefIPAdres);
  end
  else SISTEM_MESAJ_S16(RENK_KIRMIZI, 'ICMP.PAS: bilinmeyen mesaj tipi: ', AICMPBaslik^.MesajTip, 2);
end;

// icmp protokol paketi hazýrlayýp gönderme iþlevini gerçekleþtirir
procedure ICMPPaketGonder(AICMPBaslik: PICMPBaslik; APaketUzunlugu: TSayi4;
  AHedefIPAdres: TIPAdres);
var
  _ICMPBaslik: PICMPBaslik;
  _PVeri: PByte;
  _Veri: string;
  _VeriUzunlugu, _SaglamaToplam: TSayi2;
begin

  _VeriUzunlugu := APaketUzunlugu - ICMP_BASLIK_UZUNLUGU;
  _Veri := Copy(PChar(@AICMPBaslik^.Veri), 0, _VeriUzunlugu);

  // gönderilecek paket için bellek bölgesi oluþtur
  _ICMPBaslik := GGercekBellek.Ayir(4095);

  //IcmpPacket := @IPPacket^.Data;
  _ICMPBaslik^.MesajTip := ICMP_YANKI_YANIT;
  _ICMPBaslik^.Kod := 0;
  _ICMPBaslik^.Tanimlayici := AICMPBaslik^.Tanimlayici;
  _ICMPBaslik^.DiziSiraNo := AICMPBaslik^.DiziSiraNo;
  _PVeri := @_ICMPBaslik^.Veri;
  Tasi2(@_Veri[1], _PVeri, _VeriUzunlugu);

  _ICMPBaslik^.BaslikSaglamaToplami := 0;
  _SaglamaToplam := SaglamasiniYap(_ICMPBaslik, ICMP_BASLIK_UZUNLUGU + _VeriUzunlugu, nil, 0);
  _ICMPBaslik^.BaslikSaglamaToplami := Takas2(_SaglamaToplam);

  // sisteme gelen icmp isteðine icmp yanýtý (paket) gönder
  IPPaketGonder(MACAdres255, GAgBilgisi.IP4Adres, AHedefIPAdres, ptICMP, 0,
    _ICMPBaslik, ICMP_BASLIK_UZUNLUGU + _VeriUzunlugu);

  {$IFDEF ICMP_HATAAYIKLA}
  SISTEM_MESAJ_IP(RENK_KIRMIZI, 'ICMP yanýtý gönderilen IP: ', AHedefIPAdres);
  {$ENDIF}

  // belleði yok et
  GGercekBellek.YokEt(_ICMPBaslik, 4095);
end;

end.
