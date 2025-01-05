{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: netbios.pas
  Dosya İşlevi: netbios api işlevlerini yönetir

  Güncelleme Tarihi: 31/12/2024

 ==============================================================================}
{$mode objfpc}
unit netbios;

interface

uses udp, dns, paylasim;

procedure DNSSorgulariniYanitla(AUDPBaslik: PUDPPaket);

implementation

uses sistemmesaj, donusum;

{==============================================================================
  dns sorgularını yanıtlar
 ==============================================================================}
procedure DNSSorgulariniYanitla(AUDPBaslik: PUDPPaket);
var
  DNSPacket: PDNSPaket;
  IPAdres: TIPAdres;
  SorguSayisi, DigerSayisi: TSayi2;
  NetBIOSAdi: string;
  _B1: PByte;
  B1, B2, B3: TSayi1;
  _B2: PSayi2;
  _B4: PSayi4;
begin

  {$IFDEF UDP_BILGI}
  UDPBaslikBilgileriniGoruntule(AUDPBaslik);
  {$ENDIF}

  DNSPacket := @AUDPBaslik^.Veri;

  SISTEM_MESAJ(RENK_MOR, 'UDP: NetBios', []);
  SISTEM_MESAJ_S16(RENK_LACIVERT, '-> IslemKimlik: ', ntohs(DNSPacket^.Tanimlayici), 4);
  SISTEM_MESAJ_S16(RENK_LACIVERT, '-> Bayrak: ', ntohs(DNSPacket^.Bayrak), 4);
  SISTEM_MESAJ_S16(RENK_LACIVERT, '-> SorguSayisi: ', ntohs(DNSPacket^.SorguSayisi), 4);
  SISTEM_MESAJ_S16(RENK_LACIVERT, '-> YanitSayisi: ', ntohs(DNSPacket^.YanitSayisi), 4);
  SISTEM_MESAJ_S16(RENK_LACIVERT, '-> YetkiSayisi: ', ntohs(DNSPacket^.YetkiSayisi), 4);
  SISTEM_MESAJ_S16(RENK_LACIVERT, '-> DigerSayisi: ', ntohs(DNSPacket^.DigerSayisi), 4);

  // sorgu sayısı ve yanıt sayısı kontrolü
  SorguSayisi := ntohs(DNSPacket^.SorguSayisi);
  DigerSayisi := ntohs(DNSPacket^.DigerSayisi);

  // SADECE 1 adet sorguya sahip başlık değerlendirilecek
  if(SorguSayisi <> 1) then Exit;
  //if(DigerSayisi <> 1) then Exit;

  NetBIOSAdi := '';

  _B1 := @DNSPacket^.Veriler;
  Inc(_B1);    // uzunluğu atla
  while _B1^ <> 0 do
  begin

    B1 := _B1^;
    Inc(_B1);
    B2 := _B1^;
    Inc(_B1);

    B3 := (B1 - Ord('A')) shl 4;
    B3 := (B2 - Ord('A')) or B3;

    NetBIOSAdi := NetBIOSAdi + Char(B3);
  end;

  // sıfır sonlandırmayı atla
  Inc(_B1);

  // type ve class değerini atla
  _B2 := PSayi2(_B1);
  Inc(_B2);
  Inc(_B2);

  // ek bilgiler - additional record
  Inc(_B2);

  SISTEM_MESAJ(RENK_BORDO, 'NetBios Bilgileri: ', []);
  SISTEM_MESAJ_YAZI(RENK_MOR, '-> Ad: ', NetBIOSAdi);

  SISTEM_MESAJ_S16(RENK_MOR, '-> Tip: ', ntohs(_B2^), 4);
  Inc(_B2);
  SISTEM_MESAJ_S16(RENK_MOR, '-> Sınıf: ', ntohs(_B2^), 4);
  Inc(_B2);

  _B4 := PSayi4(_B2);
  SISTEM_MESAJ_S16(RENK_MOR, '-> TTL: ', ntohs(_B4^), 8);
  Inc(_B4);

  _B2 := PSayi2(_B4);
  SISTEM_MESAJ_S16(RENK_MOR, '-> Veri Uzunluğu: ', ntohs(_B2^), 4);
  Inc(_B2);

  // isim bayrağı - name flags
  Inc(_B2);

  _B1 := PSayi1(_B2);

  // ip adresi
  IPAdres[0] := _B1^;
  Inc(_B1);
  IPAdres[1] := _B1^;
  Inc(_B1);
  IPAdres[2] := _B1^;
  Inc(_B1);
  IPAdres[3] := _B1^;

  SISTEM_MESAJ_IP(RENK_MOR, '-> IP Adresi: ', IPAdres);
end;

end.
