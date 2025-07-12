{==============================================================================

  Kodlayan: Fatih KILI�
  Telif Bilgisi: haklar.txt dosyas�na bak�n�z

  Dosya Ad�: tcp.pas
  Dosya ��levi: tcp katman� veri ileti�imini ger�ekle�tirir

  G�ncelleme Tarihi: 30/01/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
//{$DEFINE TCP_BILGI}
unit tcp;

interface

uses paylasim, baglanti;

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

uses genel, donusum, ip, islevler, sistemmesaj;

procedure TCPPaketleriniIsle(AIPPaket: PIPPaket);
var
  B: PBaglanti;
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

  B := GBaglantilar.TCPBaglantiAl(UzakPort, YerelPort);
  if(B = nil) then
  begin

    SISTEM_MESAJ(mtUyari, RENK_SIYAH, 'TCP: e�le�en uzak port bulunamad�: %d', [YerelPort]);
    Exit;
  end
  else
  begin

    if(B^.BaglantiDurum = bdBaglaniyor) then
    begin

      if(TCPPaket^.Bayrak = (TCP_BAYRAK_ARZ or TCP_BAYRAK_KABUL)) then
      begin

        // gelen OnayNo de�eri benim g�nderdi�im SiraNo de�erinin 1 fazlas� olmal�d�r
        i := ntohs(TCPPaket^.OnayNo);
        //if(i = Bag^.FSiraNo + 1) then
        begin

          B^.SiraNo := i;

          // gelen SiraNo de�erini 1 art�rarak g�nder
          i := ntohs(TCPPaket^.SiraNo);
          B^.OnayNo := i + 1;

          //Bag^.FPencereU := $100;

          // ba�lant�n�n ger�ekle�ti�ine dair onay de�erini g�nder
          TCPPaketGonder(B, GAgBilgisi.IP4Adres, TCP_BAYRAK_KABUL, nil, 0);

          B^.BaglantiDurum := bdBaglandi;
        end;
      end;
    end
    else if(B^.BaglantiDurum = bdBaglandi) then
    begin

      // g�nderilen verinin kabul edildi�inin teyidi
      if(TCPPaket^.Bayrak = TCP_BAYRAK_KABUL) then
      begin

        i := ntohs(TCPPaket^.OnayNo);
        B^.SiraNo := i;

        i := ntohs(TCPPaket^.SiraNo);
        B^.OnayNo := i;

        U := ntohs(AIPPaket^.ToplamUzunluk) - 40;
        if(U > 0) then GBaglantilar.BellegeEkle(B, @TCPPaket^.Secenekler, U);
      end
      // al�nan veri
      else if(TCPPaket^.Bayrak = TCP_BAYRAK_GONDER or TCP_BAYRAK_KABUL) then
      begin

        i := ntohs(TCPPaket^.OnayNo);
        B^.SiraNo := i;

        i := ntohs(TCPPaket^.SiraNo);
        U := ntohs(AIPPaket^.ToplamUzunluk) - 40;
        B^.OnayNo := i + U;

        if(U > 0) then GBaglantilar.BellegeEkle(B, @TCPPaket^.Secenekler, U);

        TCPPaketGonder(B, GAgBilgisi.IP4Adres, TCP_BAYRAK_KABUL, nil, 0);
      end;
    end
    else if(B^.BaglantiDurum = bdBaglandi) or (B^.BaglantiDurum = bdKapaniyor1) then
    begin

      if(TCPPaket^.Bayrak = TCP_BAYRAK_SON or TCP_BAYRAK_KABUL) then
      begin

        i := ntohs(TCPPaket^.OnayNo);
        B^.SiraNo := i;

        i := ntohs(TCPPaket^.SiraNo);
        B^.OnayNo := i + 1;

        TCPPaketGonder(B, GAgBilgisi.IP4Adres, TCP_BAYRAK_KABUL, nil, 0);

        B^.ProtokolTipi := ptBilinmiyor;
        B^.HedefIPAdres := IPAdres0;
        B^.YerelPort := 0;
        B^.UzakPort := 0;

        GGercekBellek.YokEt(B^.Bellek, B^.BellekUzunlugu);
        B^.Bagli := False;
        B^.BaglantiDurum := bdYok;
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
  EkBaslik.HedefIP := ABaglanti^.HedefIPAdres;
  EkBaslik.Sifir := 0;
  EkBaslik.Protokol := PROTOKOL_TCP;
  EkBaslik.Uzunluk := htons(TSayi2(AVeriU + TCP_BASLIK_U));

  // tcp paketi haz�rlan�yor
  if(AVeriSonEk) then
    BaslikUzunlugu := (((20 + AVeriU) shr 2) shl 4)
  else BaslikUzunlugu := ((20 shr 2) shl 4);
  TCPPaket^.YerelPort := htons(ABaglanti^.YerelPort);
  TCPPaket^.UzakPort := htons(ABaglanti^.UzakPort);
  TCPPaket^.SiraNo := htons(ABaglanti^.SiraNo);
  TCPPaket^.OnayNo := htons(ABaglanti^.OnayNo);
  TCPPaket^.BaslikU := BaslikUzunlugu;     // �st 4 bit = BaslikUzunlugu * 4 = ba�l�k uzunlu�u;
  TCPPaket^.Bayrak := ABayrak;
  TCPPaket^.Pencere := htons(ABaglanti^.PencereU);
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

  IPPaketGonder(ABaglanti^.HedefMACAdres, AKaynakIPAdres, ABaglanti^.HedefIPAdres,
    ptTCP, $4000, TCPPaket, TCP_BASLIK_U + AVeriU);

  GGercekBellek.YokEt(TCPPaket, TCP_BASLIK_U + AVeriU);
end;

end.
