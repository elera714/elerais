{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: dhcp6.pas
  Dosya Ýþlevi: DHCP v6 sunucu protokol iþlevlerini yönetir

  Güncelleme Tarihi: 05/06/2026

 ==============================================================================}
{$mode objfpc}
unit dhcp6;

interface

uses ag, paylasim, udp;

type
  PDHCP6Mesaj = ^TDHCP6Mesaj;
  TDHCP6Mesaj = packed record
    Tip: TSayi2;
    Uzunluk: TSayi2;
    Mesaj: Isaretci;
  end;

const
  DHCP_SUNUCU_PORT                        = TSayi1(546);
  DHCP_ISTEMCI_PORT                       = TSayi1(547);

  // boot mesaj tipleri
	DHCP_MTIP_YALVARMA                      = TSayi1(1);    // solicit
	DHCP_MTIP_DUYURU                        = TSayi1(2);    // advertise
	DHCP_MTIP_ISTEK                         = TSayi1(3);    // request
	DHCP_MTIP_YANIT                         = TSayi1(7);    // reply
	DHCP_MTIP_RET                           = TSayi1(9);    // decline

  DHCP_SECENEK_IKIMLIK                    = TSayi1(1);    // istemci kimlik
  DHCP_SECENEK_SKIMLIK                    = TSayi1(2);    // sunucu kimlik
  DHCP_SECENEK_IANA                       = TSayi1(3);    //
  DHCP_SECENEK_ISTEK_S                    = TSayi1(6);    // option request
  DHCP_SECENEK_KALANSURE                  = TSayi1(8);    // elapsed time
  DHCP_SECENEK_ISTEMCIADI                 = TSayi1(39);   // client fully qualified domain name

type
  PDHCP6Yapi = ^TDHCP6Yapi;
  TDHCP6Yapi = packed record
  	MesajTipi: TSayi1;
  	GonderenKimlik: array[0..2] of TSayi1;
  	DigerSecenekler: Isaretci;
  end;

type
  PSecenek = ^TSecenek;
  TSecenek = packed record
  	Kod,
    Uzunluk: TSayi2;
  	Veri: Isaretci;
  end;

const
  // sunucu kimlik (DUID-LLT - DHCP Unique Identifier, Link Layer, Time)
  // bilgi: DUID deðeri mevcut veriler çerçevesinde duid generator ile oluþturulmuþtur
  DHCPSunucuKimlik: array[0..13] of Byte = (
   {$0001=DUID-LLT}    {$31CAA37C=835363708 -> 1 Ocak 2000 (UTC)'den beri geçen saniye deðeri}
                       {21 Haziran 2026 16:28:28                                             }
    $00, $01, $00, $01, $31, $CA, $A3, $7C, $08, $00, $AB, $CD, $EF, $01);
             {$0001=Ethernet}              {$0800ABCDEF01=yerel mac adres}

var
  // DagitilacakIP6Deger: $00000000-$FFFFFFFF aralýðýndadýr
  DagitilacakIP6Deger: TSayi4 = $11;
  // fe80::
  DagitilacakIP6Bicim: TIP6Adres = (
    $FE, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00);
//    $2a, $00, $60, $20, $ad, $0b, $83, $53, $00, $00, $00, $00, $00, $00, $17, $62);

procedure DHCPv6SorgulariniYanitla(AEthernetPaket: PEthernetPaket);
function YeniIP6AdresiAl: TIP6Adres;

implementation

uses sistemmesaj, donusum, islevler;

// dhcp v6 protokolü üzerinden gelen paketleri iþler
procedure DHCPv6SorgulariniYanitla(AEthernetPaket: PEthernetPaket);
const
  Sunucu: string = 'elr';
  AlanAdi: string = 'com';
var
  IPPaket: PIP6Paket;
  UDPPaket: PUDPPaket;
  KaynakPaket, HedefPaket: PDHCP6Yapi;
  KaynakPort, HedefPort, MT, i: TSayi2;
  VeriU, DHCPYapiU: TSayi4;
  DHCPMesaj: PDHCP6Mesaj;
  p1, p2: PSayi1;
  p4: PSayi4;
  Secenek: PSecenek;
begin

  IPPaket := @AEthernetPaket^.Veri;
  UDPPaket := @IPPaket^.Veri;
  KaynakPaket := @UDPPaket^.Veri;

  KaynakPort := htons(UDPPaket^.KaynakPort);
  HedefPort := htons(UDPPaket^.HedefPort);
  VeriU := htons(UDPPaket^.Uzunluk) - (8 + 4);

  if(KaynakPaket^.MesajTipi = DHCP_MTIP_YALVARMA) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'DHCP6->DHCP_MTIP_YALVARMA mesajý geldi, yanýt gönderiliyor...', []);

    DHCPYapiU := 0;

    HedefPaket := GetMem(512);
    HedefPaket^.MesajTipi := DHCP_MTIP_DUYURU;
    HedefPaket^.GonderenKimlik := KaynakPaket^.GonderenKimlik;
    p2 := @HedefPaket^.DigerSecenekler;
    Inc(DHCPYapiU, 4);

    // seçenek olarak alýnan yapýyý döngü içerisinde irdele
    DHCPMesaj := @KaynakPaket^.DigerSecenekler;

    // seçeneðin sonuna gelinceye kadar tüm deðerleri oku
    while VeriU > 0 do
    begin

      MT := htons(DHCPMesaj^.Tip);
      i := htons(DHCPMesaj^.Uzunluk);

      if(MT = DHCP_SECENEK_IKIMLIK) then
      begin

        Tasi2(DHCPMesaj, p2, i + 2 + 2);
        Inc(p2, i + 2 + 2);
        Inc(DHCPYapiU, i + 2 + 2);
      end
      else if(MT = DHCP_SECENEK_ISTEMCIADI) then
      begin

        Tasi2(DHCPMesaj, p2, i + 2 + 2);
        Inc(p2, i + 2 + 2);
        Inc(DHCPYapiU, i + 2 + 2);
      end
      else if(MT = DHCP_SECENEK_IANA) then
      begin

        p4 := Isaretci(DHCPMesaj) + 2 + 2;

        Secenek := PSecenek(p2);
        Secenek^.Kod := ntohs(TSayi2($0003));
        Secenek^.Uzunluk := ntohs(TSayi2(40));
        p2 := PByte(@Secenek^.Veri);
        PSayi4(p2)^ := p4^;
        Inc(p4);
        Inc(p2, 4);
        PSayi4(p2)^ := p4^;
        Inc(p4);
        Inc(p2, 4);
        PSayi4(p2)^ := p4^;
        Inc(p2, 4);
        Secenek := PSecenek(p2);
        Secenek^.Kod := ntohs(TSayi2($0005));
        Secenek^.Uzunluk := ntohs(TSayi2(24));
        p2 := PByte(@Secenek^.Veri);
        PIP6Adres(p2)^ := YeniIP6AdresiAl;
        Inc(p2, 16);
        PSayi4(p2)^ := htons(TSayi4(8 * 60 * 60));    // 8 saat (saniye cinsinden)
        Inc(p2, 4);
        PSayi4(p2)^ := htons(TSayi4(24 * 60 * 60));   // 24 saat (saniye cinsinden)
        Inc(p2, 4);
        Inc(DHCPYapiU, 44);
      end
      else if(MT = DHCP_SECENEK_ISTEK_S) then
      begin

      end;

      VeriU := VeriU - (i + 2 + 2);

      p1 := Isaretci(DHCPMesaj);
      Inc(p1, i + 2 + 2);
      DHCPMesaj := Isaretci(p1);
    end;

    Secenek := PSecenek(p2);
    Secenek^.Kod := ntohs(TSayi2($0002));
    Secenek^.Uzunluk := ntohs(TSayi2(14));
    p2 := PByte(@Secenek^.Veri);
    Tasi2(@DHCPSunucuKimlik[0], p2, 14);
    Inc(p2, 14);
    Inc(DHCPYapiU, 18);

    Secenek := PSecenek(p2);
    Secenek^.Kod := ntohs(TSayi2($0017));
    Secenek^.Uzunluk := ntohs(TSayi2(16));
    p2 := PByte(@Secenek^.Veri);
    PIP6Adres(p2)^ := GAg0.IP6Adres;
    Inc(p2, 16);
    Inc(DHCPYapiU, 20);

    Secenek := PSecenek(p2);
    Secenek^.Kod := ntohs(TSayi2($0018));
    Secenek^.Uzunluk := ntohs(TSayi2(9));
    p2 := PByte(@Secenek^.Veri);
    Tasi2(@Sunucu[0], p2, 4);
    Inc(p2, 4);
    Tasi2(@AlanAdi[0], p2, 4);
    Inc(p2, 4);
    PByte(p2)^ := 0;
    Inc(p2, 1);
    Inc(DHCPYapiU, 13);

    UDPPaketGonder(PROTOKOL_IP6, AEthernetPaket^.KaynakMACAdres, @GAg0.IP6Adres,
      @IPPaket^.KaynakIP, HedefPort, KaynakPort, HedefPaket, DHCPYapiU);

    FreeMem(HedefPaket, 512);
  end
  else if(KaynakPaket^.MesajTipi = DHCP_MTIP_ISTEK) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'DHCP6->DHCP_MTIP_ISTEK mesajý geldi, yanýt gönderiliyor...', []);

    DHCPYapiU := 0;

    HedefPaket := GetMem(512);
    HedefPaket^.MesajTipi := DHCP_MTIP_YANIT;
    HedefPaket^.GonderenKimlik := KaynakPaket^.GonderenKimlik;
    p2 := @HedefPaket^.DigerSecenekler;
    Inc(DHCPYapiU, 4);

    // seçenek olarak alýnan yapýyý döngü içerisinde irdele
    DHCPMesaj := @KaynakPaket^.DigerSecenekler;

    // seçeneðin sonuna gelinceye kadar tüm deðerleri oku
    while VeriU > 0 do
    begin

      MT := htons(DHCPMesaj^.Tip);
      i := htons(DHCPMesaj^.Uzunluk);

      if(MT = DHCP_SECENEK_IKIMLIK) then
      begin

        Tasi2(DHCPMesaj, p2, i + 2 + 2);
        Inc(p2, i + 2 + 2);
        Inc(DHCPYapiU, i + 2 + 2);
      end
      else if(MT = DHCP_SECENEK_ISTEMCIADI) then
      begin

        Tasi2(DHCPMesaj, p2, i + 2 + 2);
        Inc(p2, i + 2 + 2);
        Inc(DHCPYapiU, i + 2 + 2);
      end
      else if(MT = DHCP_SECENEK_IANA) then
      begin

        {Tasi2(DHCPMesaj, p2, i + 2 + 2);
        Inc(p2, i + 2 + 2);
        Inc(DHCPYapiU, i + 2 + 2);}

        p4 := Isaretci(DHCPMesaj) + 2 + 2;

        Secenek := PSecenek(p2);
        Secenek^.Kod := ntohs(TSayi2($0003));
        Secenek^.Uzunluk := ntohs(TSayi2(40));
        p2 := PByte(@Secenek^.Veri);
        PSayi4(p2)^ := p4^;
        Inc(p4);
        Inc(p2, 4);
        PSayi4(p2)^ := p4^;
        Inc(p4);
        Inc(p2, 4);
        PSayi4(p2)^ := p4^;
        Inc(p2, 4);
        Secenek := PSecenek(p2);
        Secenek^.Kod := ntohs(TSayi2($0005));
        Secenek^.Uzunluk := ntohs(TSayi2(24));
        p2 := PByte(@Secenek^.Veri);
        PIP6Adres(p2)^ := YeniIP6AdresiAl;
        Inc(p2, 16);
        PSayi4(p2)^ := htons(TSayi4(8 * 60 * 60));    // 8 saat (saniye cinsinden)
        Inc(p2, 4);
        PSayi4(p2)^ := htons(TSayi4(24 * 60 * 60));   // 24 saat (saniye cinsinden)
        Inc(p2, 4);
        Inc(DHCPYapiU, 44);
      end
      else if(MT = DHCP_SECENEK_ISTEK_S) then
      begin

      end;

      VeriU := VeriU - (i + 2 + 2);

      p1 := Isaretci(DHCPMesaj);
      Inc(p1, i + 2 + 2);
      DHCPMesaj := Isaretci(p1);
    end;

    Secenek := PSecenek(p2);
    Secenek^.Kod := ntohs(TSayi2($0002));
    Secenek^.Uzunluk := ntohs(TSayi2(14));
    p2 := PByte(@Secenek^.Veri);
    Tasi2(@DHCPSunucuKimlik[0], p2, 14);
    Inc(p2, 14);
    Inc(DHCPYapiU, 18);

    Secenek := PSecenek(p2);
    Secenek^.Kod := ntohs(TSayi2($0017));
    Secenek^.Uzunluk := ntohs(TSayi2(16));
    p2 := PByte(@Secenek^.Veri);
    PIP6Adres(p2)^ := GAg0.IP6Adres;
    Inc(p2, 16);
    Inc(DHCPYapiU, 20);

    Secenek := PSecenek(p2);
    Secenek^.Kod := ntohs(TSayi2($0018));
    Secenek^.Uzunluk := ntohs(TSayi2(9));
    p2 := PByte(@Secenek^.Veri);
    Tasi2(@Sunucu[0], p2, 4);
    Inc(p2, 4);
    Tasi2(@AlanAdi[0], p2, 4);
    Inc(p2, 4);
    PByte(p2)^ := 0;
    Inc(p2, 1);
    Inc(DHCPYapiU, 13);

    UDPPaketGonder(PROTOKOL_IP6, AEthernetPaket^.KaynakMACAdres, @GAg0.IP6Adres,
      @IPPaket^.KaynakIP, HedefPort, KaynakPort, HedefPaket, DHCPYapiU);

    FreeMem(HedefPaket, 512);
  end
  else if(KaynakPaket^.MesajTipi = DHCP_MTIP_RET) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'DHCP6->DHCP_MTIP_RET mesajý geldi, yanýt gönderiliyor...', []);

    DHCPYapiU := 0;

    HedefPaket := GetMem(512);
    HedefPaket^.MesajTipi := DHCP_MTIP_YANIT;
    HedefPaket^.GonderenKimlik := KaynakPaket^.GonderenKimlik;
    p2 := @HedefPaket^.DigerSecenekler;
    Inc(DHCPYapiU, 4);

    // seçenek olarak alýnan yapýyý döngü içerisinde irdele
    DHCPMesaj := @KaynakPaket^.DigerSecenekler;

    // seçeneðin sonuna gelinceye kadar tüm deðerleri oku
    while VeriU > 0 do
    begin

      MT := htons(DHCPMesaj^.Tip);
      i := htons(DHCPMesaj^.Uzunluk);

      if(MT = DHCP_SECENEK_IKIMLIK) then
      begin

        Tasi2(DHCPMesaj, p2, i + 2 + 2);
        Inc(p2, i + 2 + 2);
        Inc(DHCPYapiU, i + 2 + 2);
      end
      else if(MT = DHCP_SECENEK_SKIMLIK) then
      begin

        Tasi2(DHCPMesaj, p2, i + 2 + 2);
        Inc(p2, i + 2 + 2);
        Inc(DHCPYapiU, i + 2 + 2);
      end
      else if(MT = DHCP_SECENEK_IANA) then
      begin

        Tasi2(DHCPMesaj, p2, i + 2 + 2);
        Inc(p2, i + 2 + 2);
        Inc(DHCPYapiU, i + 2 + 2);
      end;

      VeriU := VeriU - (i + 2 + 2);

      p1 := Isaretci(DHCPMesaj);
      Inc(p1, i + 2 + 2);
      DHCPMesaj := Isaretci(p1);
    end;

    {Secenek := PSecenek(p2);
    Secenek^.Kod := ntohs(TSayi2($0002));
    Secenek^.Uzunluk := ntohs(TSayi2(14));
    p2 := PByte(@Secenek^.Veri);
    Tasi2(@DHCPSunucuKimlik[0], p2, 14);
    Inc(p2, 14);
    Inc(DHCPYapiU, 18);

    Secenek := PSecenek(p2);
    Secenek^.Kod := ntohs(TSayi2($0017));
    Secenek^.Uzunluk := ntohs(TSayi2(16));
    p2 := PByte(@Secenek^.Veri);
    PIP6Adres(p2)^ := DNSIP6Adresi;
    Inc(p2, 16);
    Inc(DHCPYapiU, 20);

    Secenek := PSecenek(p2);
    Secenek^.Kod := ntohs(TSayi2($0018));
    Secenek^.Uzunluk := ntohs(TSayi2(13));
    p2 := PByte(@Secenek^.Veri);
    Tasi2(@s1[0], p2, 9);
    Inc(p2, 9);
    Tasi2(@s2[0], p2, 3);
    Inc(p2, 3);
    PByte(p2)^ := 0;
    Inc(p2, 1);
    Inc(DHCPYapiU, 17); }

    UDPPaketGonder(PROTOKOL_IP6, AEthernetPaket^.KaynakMACAdres, @GAg0.IP6Adres,
      @IPPaket^.KaynakIP, HedefPort, KaynakPort, HedefPaket, DHCPYapiU);

    FreeMem(HedefPaket, 512);
  end
  else
  begin

    SISTEM_MESAJ(mtBilgi, RENK_KIRMIZI, 'DHCP6 bilinmeyen mesaj tipi: %d', [KaynakPaket^.MesajTipi]);
  end;
end;

function YeniIP6AdresiAl: TIP6Adres;
var
  i: TSayi4;
begin

  i := DagitilacakIP6Deger;
  Inc(i);
  DagitilacakIP6Deger := i;

  Result := DagitilacakIP6Bicim;
  Result[12] := TSayi1(i shr 24);
  Result[13] := TSayi1(i shr 16);
  Result[14] := TSayi1(i shr 08);
  Result[15] := TSayi1(i and $FF);
end;

end.
