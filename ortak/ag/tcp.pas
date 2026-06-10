{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: tcp.pas
  Dosya Ýþlevi: tcp v4/v6 katmaný veri iletiþimini gerçekleþtirir

  Güncelleme Tarihi: 10/06/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
//{$DEFINE TCP_BILGI}
unit tcp;

interface

uses paylasim, baglanti, sunucular;

const
  TCP_BASLIK_U      = 20;
  TCP4_EKBASLIK_U   = 12;
  TCP6_EKBASLIK_U   = 40;

procedure TCPPaketleriniIsle(AEthernetPaket: PEthernetPaket);
procedure TCPPaketGonder(APaketTipi: TSayi4; ABaglanti: PBaglanti; AKaynakIPAdres: Isaretci;
  ABayrak: TSayi1; AVeri: Isaretci; AVeriU: TSayi4; AVeriSonEk: Boolean = False);
function SunucuBul(APortNo: TSayi4): TSunucuIslev;

implementation

uses genel, donusum, ip6, ip4, islevler, sistemmesaj, gercekbellek;

procedure TCPPaketleriniIsle(AEthernetPaket: PEthernetPaket);
var
  B: PBaglanti;
  SI: TSunucuIslev;
  TCPPaket: PTCPPaket;
  KaynakPort, HedefPort,
  PaketTipi, i: TSayi4;
  U: TSayi2;
  p: PChar;
  IP6Paket: PIP6Paket;
  IP4Paket: PIP4Paket;
begin

  IP4Paket := PIP4Paket(@AEthernetPaket^.Veri);
  IP6Paket := PIP6Paket(@AEthernetPaket^.Veri);

  PaketTipi := htons(AEthernetPaket^.PaketTipi);
  if(PaketTipi = PROTOKOL_IP6) then

    TCPPaket := PTCPPaket(@IP6Paket^.Veri)
  else if(PaketTipi = PROTOKOL_IP4) then

    TCPPaket := PTCPPaket(@IP4Paket^.Veri)
  else Exit;

  KaynakPort := ntohs(TCPPaket^.YerelPort);       // paketi gönderen cihazýn portu
  HedefPort := ntohs(TCPPaket^.UzakPort);         // paketi alan cihazýn yerel portu (bu bilgisayar)

  {$IFDEF TCP_BILGI}
  SISTEM_MESAJ(mtBilgi, RENK_MOR, '-------------------------', []);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'TCP: Kaynak Port: %d', [KaynakPort]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'TCP: Hedef Port: %d', [HedefPort]);
  {$ENDIF}

{  if(PaketTipi = PROTOKOL_IP6) then
  begin

    SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'ipv6 paketi iþlenecek', []);
    Exit;
  end; }

  // 1.1 diðer bilgisayarlar tarafýndan istenen bir baðlantý isteði olmasý durumunda
  if(TCPPaket^.Bayrak = TCP_BAYRAK_ARZ) then
  begin

    SI := SunucuBul(HedefPort);
    if(SI = nil) then

      SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'Sistemde %d port numarasý üzerinden hizmet veren sunucu mevcut deðil!', [HedefPort])

    else SI(PaketTipi, nil, AEthernetPaket);
  end
  else
  // 1.2 bu bilgisayar tarafýndan gerçekleþtirilmek istenen bir baðlantý isteði olmasý durumunda
  begin

    B := Baglantilar0.TCPBaglantiAl(KaynakPort, HedefPort);
    if(B = nil) then
    begin

      SISTEM_MESAJ(mtUyari, RENK_SIYAH, 'TCP: eþleþen servis portu bulunamadý: %d', [HedefPort]);
      Exit;
    end
    else
    begin

      // 1.1 bu bilgisayardan diðerine istemci -> sunucu baðlantýsý
      if(B^.BaglantiTuru = btAktif) then
      begin

        if(B^.BaglantiDurum = bdBaglaniyor) then
        begin

          if(TCPPaket^.Bayrak = (TCP_BAYRAK_ARZ or TCP_BAYRAK_KABUL)) then
          begin

            // gelen OnayNo deðeri benim gönderdiðim SiraNo deðerinin 1 fazlasý olmalýdýr
            i := ntohs(TCPPaket^.OnayNo);
            //if(i = Bag^.FSiraNo + 1) then
            begin

              B^.SiraNo := i;

              // gelen SiraNo deðerini 1 artýrarak gönder
              i := ntohs(TCPPaket^.SiraNo);
              B^.OnayNo := i + 1;

              //Bag^.FPencereU := $100;

              // baðlantýnýn gerçekleþtiðine dair onay deðerini gönder
              TCPPaketGonder(PaketTipi, B, @GAgBilgisi.IP4Adres, TCP_BAYRAK_KABUL, nil, 0);

              B^.BaglantiDurum := bdBaglantiKuruldu;
            end;
          end;
        end
        else if(B^.BaglantiDurum = bdBaglantiKuruldu) then
        begin

          // gönderilen verinin kabul edildiðinin teyidi
          if(TCPPaket^.Bayrak = TCP_BAYRAK_KABUL) then
          begin

            i := ntohs(TCPPaket^.OnayNo);
            B^.SiraNo := i;

            i := ntohs(TCPPaket^.SiraNo);
            B^.OnayNo := i;

            U := ntohs(IP4Paket^.ToplamUzunluk) - 40;
            if(U > 0) then Baglantilar0.BellegeEkle(B, @TCPPaket^.Secenekler, U);
          end
          // alýnan veri
          else if(TCPPaket^.Bayrak = TCP_BAYRAK_GONDER or TCP_BAYRAK_KABUL) then  { ayný.2}
          begin

            i := ntohs(TCPPaket^.OnayNo);
            B^.SiraNo := i;

            i := ntohs(TCPPaket^.SiraNo);
            U := ntohs(IP4Paket^.ToplamUzunluk) - 40;
            B^.OnayNo := i + U;

            if(U > 0) then Baglantilar0.BellegeEkle(B, @TCPPaket^.Secenekler, U);

            TCPPaketGonder(PaketTipi, B, @GAgBilgisi.IP4Adres, TCP_BAYRAK_KABUL, nil, 0);
          end;
        end
        else if(B^.BaglantiDurum = bdBaglantiKuruldu) or (B^.BaglantiDurum = bdKapanisBekleniyor1) then
        begin

          if(TCPPaket^.Bayrak = TCP_BAYRAK_SON or TCP_BAYRAK_KABUL) then
          begin

            i := ntohs(TCPPaket^.OnayNo);
            B^.SiraNo := i;

            i := ntohs(TCPPaket^.SiraNo);
            B^.OnayNo := i + 1;

            TCPPaketGonder(PaketTipi, B, @GAgBilgisi.IP4Adres, TCP_BAYRAK_KABUL, nil, 0);

            B^.ProtokolTipi := ptBilinmiyor;
            B^.HedefIPAdres := IPAdres0;
            B^.YerelPort := 0;
            B^.UzakPort := 0;

            if not(B^.Bellek = nil) then GercekBellek0.YokEt(B^.Bellek, 4 * 4096);
            B^.Bagli := False;
            B^.BaglantiDurum := bdYok;
          end;
        end;
      end
      else
      // 1.2 diðer bilgisayardan bu bilgisayara istemci -> sunucu baðlantýsý
      begin

        SI := SunucuBul(HedefPort);
        if not(SI = nil) then SI(PaketTipi, B, AEthernetPaket);
      end;
    end;
  end;
end;

procedure TCPPaketGonder(APaketTipi: TSayi4; ABaglanti: PBaglanti; AKaynakIPAdres: Isaretci;
  ABayrak: TSayi1; AVeri: Isaretci; AVeriU: TSayi4; AVeriSonEk: Boolean = False);
const
  { TODO - düzenle }
  GeciciHedefIP6Adres: TIP6Adres = (
    $fe, $80, $00, $00, $00, $00, $00, $00, $f9, $c7, $b6, $2c, $fc, $ad, $5e, $3e);
var
  TCPPaket: PTCPPaket;
  Ek6Baslik: TEk6Baslik;
  Ek4Baslik: TEk4Baslik;
  SaglamaToplami: TSayi2;
  BaslikUzunlugu: TSayi1;
  p: PByte;
begin

  TCPPaket := GercekBellek0.Ayir(TCP_BASLIK_U + AVeriU);

  if(APaketTipi = PROTOKOL_IP6) then
  begin

    // tcp v6 için ek baþlýk hesaplanýyor
    Ek6Baslik.KaynakIP := PIP6Adres(AKaynakIPAdres)^;
    Ek6Baslik.HedefIP := GeciciHedefIP6Adres; // ABaglanti^.HedefIPAdres;
    Ek6Baslik.Uzunluk := htons(TSayi4(AVeriU + TCP_BASLIK_U));
    Ek6Baslik.Sifir[0] := 0;
    Ek6Baslik.Sifir[1] := 0;
    Ek6Baslik.Sifir[2] := 0;
    Ek6Baslik.Protokol := PROTOKOL_TCP;
  end
  else
  begin

    // tcp v4 için ek baþlýk hesaplanýyor
    Ek4Baslik.KaynakIP := PIP4Adres(AKaynakIPAdres)^;
    Ek4Baslik.HedefIP := ABaglanti^.HedefIPAdres;
    Ek4Baslik.Sifir := 0;
    Ek4Baslik.Protokol := PROTOKOL_TCP;
    Ek4Baslik.Uzunluk := htons(TSayi2(AVeriU + TCP_BASLIK_U));
  end;

  // tcp paketi hazýrlanýyor
  if(AVeriSonEk) then
    BaslikUzunlugu := (((20 + AVeriU) shr 2) shl 4)
  else BaslikUzunlugu := ((20 shr 2) shl 4);

  if(ABaglanti^.BaglantiTuru = btAktif) then
  begin

    TCPPaket^.YerelPort := htons(ABaglanti^.YerelPort);
    TCPPaket^.UzakPort := htons(ABaglanti^.UzakPort);
  end
  else
  begin

    TCPPaket^.YerelPort := htons(ABaglanti^.UzakPort);
    TCPPaket^.UzakPort := htons(ABaglanti^.YerelPort);
  end;

  TCPPaket^.SiraNo := htons(ABaglanti^.SiraNo);
  TCPPaket^.OnayNo := htons(ABaglanti^.OnayNo);
  TCPPaket^.BaslikU := BaslikUzunlugu;     // üst 4 bit = BaslikUzunlugu * 4 = baþlýk uzunluðu;
  TCPPaket^.Bayrak := ABayrak;
  TCPPaket^.Pencere := htons(ABaglanti^.PencereU);
  TCPPaket^.SaglamaToplami := 0;
  TCPPaket^.AcilIsaretci := 0;
  if(AVeriU > 0) then
  begin

    p := @TCPPaket^.Secenekler;
    Tasi2(PByte(AVeri), p, AVeriU);
  end;

  if(APaketTipi = PROTOKOL_IP6) then
    SaglamaToplami := SaglamaToplamiOlustur(TCPPaket, TCP_BASLIK_U + AVeriU,
      @Ek6Baslik, TCP6_EKBASLIK_U)
  else
    SaglamaToplami := SaglamaToplamiOlustur(TCPPaket, TCP_BASLIK_U + AVeriU,
      @Ek4Baslik, TCP4_EKBASLIK_U);
  TCPPaket^.SaglamaToplami := SaglamaToplami;

  if(APaketTipi = PROTOKOL_IP4) then
    IP4PaketGonder(ABaglanti^.HedefMACAdres, PIP4Adres(AKaynakIPAdres)^, ABaglanti^.HedefIPAdres,
      ptTCP, $4000, TCPPaket, TCP_BASLIK_U + AVeriU)
  else if(APaketTipi = PROTOKOL_IP6) then
  begin

    { TODO - düzenle }
    IP6PaketGonder(ABaglanti^.HedefMACAdres, PIP6Adres(AKaynakIPAdres)^, GeciciHedefIP6Adres{ABaglanti^.HedefIPAdres},
      ptTCP, $80, TCPPaket, TCP_BASLIK_U + AVeriU)
  end;

  GercekBellek0.YokEt(TCPPaket, TCP_BASLIK_U + AVeriU);
end;

{==============================================================================
  belirtilen port üzerinden hizmet veren sunucu yazýlýmýný bulur
 ==============================================================================}
function SunucuBul(APortNo: TSayi4): TSunucuIslev;
var
  SI: TSunucuYapisi;
  i: TSayi4;
begin

  Result := nil;

  if(HIZMETVEREN_SUNUCU_SAYISI > 0) then
  begin

    for i := 0 to HIZMETVEREN_SUNUCU_SAYISI - 1 do
    begin

      SI := SunucuListesi[i];
      if(SI.PortNo = APortNo) then Exit(SI.Islev);
    end;
  end;
end;

end.
