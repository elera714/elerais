{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: tcp.pas
  Dosya ��levi: tcp katman� veri ileti�imini ger�ekle�tirir

  G�ncelleme Tarihi: 16/01/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
//{$DEFINE TCP_BILGI}
unit tcp;

interface

uses paylasim, iletisim;

const
  TCP_BASLIK_U      = 20;
  TCP_EKBASLIK_U    = 12;

type
  PTCPPaket = ^TTCPPaket;
  TTCPPaket = packed record
    {SrcIpAddr,
    DestIpAddr: TIPAdres;
    Zero: Byte;
    Protocol: Byte;
    Length: Word;               // tcp header + data}
    YerelPort,
    UzakPort: TSayi2;
    SiraNo,                     // sequence number
    OnayNo: TSayi4;
    BaslikU: TSayi1;            // 11111000 = 111111 = Data Offset, 000 = Reserved
    Bayrak: TSayi1;
    Pencere: TSayi2;
    SaglamaToplami,
    AcilIsaretci: TSayi2;       // urgent pointer
    Secenekler: Isaretci;
  end;

procedure TCPPaketleriniIsle(AIPPaket: PIPPaket);
procedure TCPPaketGonder(ABaglanti: PBaglanti; AKaynakIPAdres: TIPAdres;
  ABayrak: TSayi1; AVeri: Isaretci; AVeriU: TSayi4; AVeriSonEk: Boolean = False);

implementation

uses genel, donusum, ip, sistemmesaj;

procedure TCPPaketleriniIsle(AIPPaket: PIPPaket);
var
  Bag: PBaglanti;
  TCPPaket: PTCPPaket;
  YerelPort, UzakPort,
  U: TSayi2;
  i, j: TSayi4;
begin

  TCPPaket := PTCPPaket(@AIPPaket^.Veri);

  YerelPort := ntohs(TCPPaket^.YerelPort);      // bu makinenin yerel portu
  UzakPort := ntohs(TCPPaket^.UzakPort);        // uzak makinenin yerel portu

  {$IFDEF TCP_BILGI}
  SISTEM_MESAJ(RENK_MOR, '-------------------------', []);
  SISTEM_MESAJ(RENK_LACIVERT, 'TCP: Yerel Port: %d', [YerelPort]);
  SISTEM_MESAJ(RENK_LACIVERT, 'TCP: Uzak Port: %d', [UzakPort]);
  SISTEM_MESAJ(RENK_LACIVERT, 'TCP: Bayrak: %d', [TCPPaket^.Bayrak]);
  {$ENDIF}

  Bag := Bag^.TCPBaglantiAl(UzakPort, YerelPort);
  if(Bag = nil) then
  begin

    SISTEM_MESAJ(RENK_KIRMIZI, 'TCP: e�le�en uzak port bulunamad�: %d', [YerelPort]);
    Exit;
  end
  else
  begin

    if(Bag^.FBaglantiDurum = bdBaglaniyor) then
    begin

      if(TCPPaket^.Bayrak = (TCP_BAYRAK_ARZ or TCP_BAYRAK_KABUL)) then
      begin

        // gelen OnayNo de�eri benim g�nderdi�im SiraNo de�erinin 1 fazlas� olmal�d�r
        i := ntohs(TCPPaket^.OnayNo);
        //if(i = Bag^.FSiraNo + 1) then
        begin

          Bag^.FSiraNo := i;

          // gelen SiraNo de�erini 1 art�rarak g�nder
          i := ntohs(TCPPaket^.SiraNo);
          Bag^.FOnayNo := i + 1;

          //Bag^.FPencereU := $100;

          // ba�lant�n�n ger�ekle�ti�ine dair onay de�erini g�nder
          TCPPaketGonder(Bag, GAgBilgisi.IP4Adres, TCP_BAYRAK_KABUL, nil, 0);

          Bag^.FBaglantiDurum := bdBaglandi;
        end;
      end;
    end
    else if(Bag^.FBaglantiDurum = bdBaglandi) then
    begin

      // g�nderilen verinin kabul edildi�inin teyidi
      if(TCPPaket^.Bayrak = TCP_BAYRAK_KABUL) then
      begin

        i := ntohs(TCPPaket^.OnayNo);
        Bag^.FSiraNo := i;

        i := ntohs(TCPPaket^.SiraNo);
        Bag^.FOnayNo := i;

        U := ntohs(AIPPaket^.ToplamUzunluk) - 40;
        if(U > 0) then Bag^.BellegeEkle(Bag, @TCPPaket^.Secenekler, U);
      end
      // al�nan veri
      else if(TCPPaket^.Bayrak = TCP_BAYRAK_GONDER or TCP_BAYRAK_KABUL) then
      begin

        i := ntohs(TCPPaket^.OnayNo);
        Bag^.FSiraNo := i;

        i := ntohs(TCPPaket^.SiraNo);
        U := ntohs(AIPPaket^.ToplamUzunluk) - 40;
        Bag^.FOnayNo := i + U;

        if(U > 0) then Bag^.BellegeEkle(Bag, @TCPPaket^.Secenekler, U);

        TCPPaketGonder(Bag, GAgBilgisi.IP4Adres, TCP_BAYRAK_KABUL, nil, 0);
      end;
    end
    else if(Bag^.FBaglantiDurum = bdBaglandi) or (Bag^.FBaglantiDurum = bdKapaniyor1) then
    begin

      if(TCPPaket^.Bayrak = TCP_BAYRAK_SON or TCP_BAYRAK_KABUL) then
      begin

        i := ntohs(TCPPaket^.OnayNo);
        Bag^.FSiraNo := i;

        i := ntohs(TCPPaket^.SiraNo);
        Bag^.FOnayNo := i + 1;

        TCPPaketGonder(Bag, GAgBilgisi.IP4Adres, TCP_BAYRAK_KABUL, nil, 0);

        Bag^.FProtokolTipi := ptBilinmiyor;
        Bag^.FHedefIPAdres := IPAdres0;
        Bag^.FYerelPort := 0;
        Bag^.FUzakPort := 0;

        GGercekBellek.YokEt(Bag^.FBellek, Bag^.FBellekUzunlugu);
        Bag^.FBagli := False;
        Bag^.FBaglantiDurum := bdYok;
      end;
    end;
  end;
end;

procedure TCPPaketGonder(ABaglanti: PBaglanti; AKaynakIPAdres: TIPAdres;
  ABayrak: TSayi1; AVeri: Isaretci; AVeriU: TSayi4; AVeriSonEk: Boolean = False);
var
  TCPPaket: PTCPPaket;
  EkBaslik: TEkBaslik;
  SaglamaToplami: TSayi2;
  BaslikUzunlugu: TSayi1;
  p: PByte;
begin

  TCPPaket := GGercekBellek.Ayir(TCP_BASLIK_U + AVeriU);

  // tcp i�in ek ba�l�k hesaplan�yor
  EkBaslik.KaynakIP := AKaynakIPAdres;
  EkBaslik.HedefIP := ABaglanti^.FHedefIPAdres;
  EkBaslik.Sifir := 0;
  EkBaslik.Protokol := PROTOKOL_TCP;
  EkBaslik.Uzunluk := htons(TSayi2(AVeriU + TCP_BASLIK_U));

  // tcp paketi haz�rlan�yor
  if(AVeriSonEk) then
    BaslikUzunlugu := (((20 + AVeriU) shr 2) shl 4)
  else BaslikUzunlugu := ((20 shr 2) shl 4);
  TCPPaket^.YerelPort := htons(ABaglanti^.FYerelPort);
  TCPPaket^.UzakPort := htons(ABaglanti^.FUzakPort);
  TCPPaket^.SiraNo := htons(ABaglanti^.FSiraNo);
  TCPPaket^.OnayNo := htons(ABaglanti^.FOnayNo);
  TCPPaket^.BaslikU := BaslikUzunlugu;     // �st 4 bit = BaslikUzunlugu * 4 = ba�l�k uzunlu�u;
  TCPPaket^.Bayrak := ABayrak;
  TCPPaket^.Pencere := htons(ABaglanti^.FPencereU);
  TCPPaket^.SaglamaToplami := 0;
  TCPPaket^.AcilIsaretci := 0;
  if(AVeriU > 0) then
  begin

    p := @TCPPaket^.Secenekler;
    Tasi2(PByte(AVeri), p, AVeriU);
  end;

  SaglamaToplami := SaglamaToplamiOlustur(TCPPaket, TCP_BASLIK_U + AVeriU,
    @EkBaslik, TCP_EKBASLIK_U);
  TCPPaket^.SaglamaToplami := SaglamaToplami;

  IPPaketGonder(ABaglanti^.FHedefMACAdres, AKaynakIPAdres, ABaglanti^.FHedefIPAdres,
    ptTCP, $4000, TCPPaket, TCP_BASLIK_U + AVeriU);

  GGercekBellek.YokEt(TCPPaket, TCP_BASLIK_U + AVeriU);
end;

end.
