{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: tcp.pas
  Dosya Ýþlevi: tcp katmaný veri iletiþimini gerçekleþtirir

  Güncelleme Tarihi: 16/09/2024

 ==============================================================================}
{$mode objfpc}
//{$DEFINE TCP_BILGI}
unit tcp;

interface

uses paylasim, iletisim;

procedure TCPPaketleriniIsle(AIPPaket: PIPPaket);
procedure TCPPaketGonder(AKaynakIPAdres: TIPAdres; ABaglanti: PBaglanti;
  ABayrak: TSayi1; AVeri: Isaretci; AVeriU: TSayi4; AVeriSonEk: Boolean = False);

implementation

uses genel, donusum, ip, sistemmesaj;

procedure TCPPaketleriniIsle(AIPPaket: PIPPaket);
var
  _Baglanti: PBaglanti;
  ATCPPaket: PTCPPaket;
  _SunucuYerelPort, _SistemYerelPort: TSayi2;
  i, j: TSayi4;
begin

  ATCPPaket := PTCPPaket(@AIPPaket^.Veri);

  _SunucuYerelPort := Takas2(ATCPPaket^.YerelPort);     // sunucunun yerel portu
  _SistemYerelPort := Takas2(ATCPPaket^.UzakPort);      // sistemin yerel portu

  {$IFDEF TCP_BILGI}
  SISTEM_MESAJ(RENK_MOR, '-------------------------', []);
  SISTEM_MESAJ_S10(RENK_LACIVERT, 'TCP: Yerel Port: ', Takas2(_SistemYerelPort));
  SISTEM_MESAJ_S10(RENK_LACIVERT, 'TCP: Hedef Port: ', Takas2(_SunucuYerelPort));
  SISTEM_MESAJ_S10(RENK_LACIVERT, 'TCP: Bayrak: ', ATCPBaslik^.Bayrak);
  {$ENDIF}

  _Baglanti := _Baglanti^.TCPBaglantiAl(_SistemYerelPort, _SunucuYerelPort);
  if(_Baglanti = nil) then
  begin

    SISTEM_MESAJ(RENK_KIRMIZI, 'TCP: eþleþen uzak port bulunamadý: %d', [_SunucuYerelPort]);
    Exit;
  end
  else
  begin

    if(_Baglanti^.FBaglantiDurum = bdBaglaniyor) then
    begin

      if(ATCPPaket^.Bayrak = (TCP_BAYRAK_ARZ or TCP_BAYRAK_KABUL)) then
      begin

        // gelen OnayNo deðeri benim SiraNo deðerim;
        // gelen SiraNo deðeri benim OnayNo deðerimdir
        i := Takas4(ATCPPaket^.OnayNo);
        _Baglanti^.FSiraNo := i;

        i := Takas4(ATCPPaket^.SiraNo);
        _Baglanti^.FOnayNo := i + 1;

        _Baglanti^.FPencereU := $100;

        // baðlantýnýn gerçekleþtiðine dair onay deðerini gönder
        TCPPaketGonder(GAgBilgisi.IP4Adres, _Baglanti, TCP_BAYRAK_KABUL, nil, 0);

        _Baglanti^.FBaglantiDurum := bdBaglandi;
      end;
    end
    else if(_Baglanti^.FBaglantiDurum = bdBaglandi) then
    begin

      // gönderilen verinin kabul edildiðinin teyidi
      if(ATCPPaket^.Bayrak = TCP_BAYRAK_KABUL) then
      begin

        i := Takas4(ATCPPaket^.OnayNo);
        _Baglanti^.FSiraNo := i;

        i := Takas4(ATCPPaket^.SiraNo);
        _Baglanti^.FOnayNo := i;

        //SISTEM_MESAJ(RENK_MOR, 'TCP Durum: TCP_BAYRAK_KABUL', []);
      end
      // alýnan veri
      else if(ATCPPaket^.Bayrak = TCP_BAYRAK_GONDER or TCP_BAYRAK_KABUL) then
      begin

        i := Takas4(ATCPPaket^.OnayNo);
        _Baglanti^.FSiraNo := i;

        i := Takas4(ATCPPaket^.SiraNo);
        j := (Takas2(AIPPaket^.ToplamUzunluk) - 40);
        _Baglanti^.FOnayNo := i + j;

        _Baglanti^.BellegeEkle(@ATCPPaket^.Secenekler, j);

        //SISTEM_MESAJ_YAZI(RENK_MOR, PChar(@ATCPPaket^.Secenekler), j);
        //SISTEM_MESAJ(RENK_LACIVERT, 'Uzunluk: %d', [j]);
        //SISTEM_MESAJ_YAZI(RENK_LACIVERT, PChar(_Baglanti^.FBellek), _Baglanti^.FBellekUzunlugu);

        TCPPaketGonder(GAgBilgisi.IP4Adres, _Baglanti, TCP_BAYRAK_KABUL, nil, 0);
      end;
    end
    else if(_Baglanti^.FBaglantiDurum = bdKapaniyor1) then
    begin

      if(ATCPPaket^.Bayrak = TCP_BAYRAK_KABUL) then
      begin

        i := Takas4(ATCPPaket^.OnayNo);
        _Baglanti^.FSiraNo := i;

        i := Takas4(ATCPPaket^.SiraNo);
        _Baglanti^.FOnayNo := i;

        TCPPaketGonder(GAgBilgisi.IP4Adres, _Baglanti, TCP_BAYRAK_SON or TCP_BAYRAK_KABUL,
          nil, 0);

        _Baglanti^.FBaglantiDurum := bdKapaniyor2;

        //SISTEM_MESAJ(RENK_KIRMIZI, 'TCP Durum: bdKapaniyor2', []);
      end;
    end
    else if(_Baglanti^.FBaglantiDurum = bdKapaniyor2) then
    begin

      if(ATCPPaket^.Bayrak = TCP_BAYRAK_SON or TCP_BAYRAK_KABUL) then
      begin

        i := Takas4(ATCPPaket^.OnayNo);
        _Baglanti^.FSiraNo := i;

        i := Takas4(ATCPPaket^.SiraNo);
        _Baglanti^.FOnayNo := i + 1;

        TCPPaketGonder(GAgBilgisi.IP4Adres, _Baglanti, TCP_BAYRAK_KABUL, nil, 0);

        _Baglanti^.FProtokolTipi := ptBilinmiyor;
        _Baglanti^.FHedefIPAdres := IPAdres0;
        _Baglanti^.FYerelPort := 0;
        _Baglanti^.FUzakPort := 0;

        GGercekBellek.YokEt(_Baglanti^.FBellek, _Baglanti^.FBellekUzunlugu);
        _Baglanti^.FBagli := False;
        _Baglanti^.FBaglantiDurum := bdYok;

        //SISTEM_MESAJ(RENK_KIRMIZI, 'TCP Durum: baþlamadý', []);
      end;
    end;
  end;
end;

procedure TCPPaketGonder(AKaynakIPAdres: TIPAdres; ABaglanti: PBaglanti;
  ABayrak: TSayi1; AVeri: Isaretci; AVeriU: TSayi4; AVeriSonEk: Boolean = False);
var
  _TCPBaslik: PTCPPaket;
  EkBaslik: TEkBaslik;
  _Saglama: TSayi2;
  _BaslikUzunlugu: TSayi1;
  _p: PByte;
begin

  _TCPBaslik := GGercekBellek.Ayir(TCPBASLIK_UZUNLUGU + AVeriU);

  // tcp için ek baþlýk hesaplanýyor
  EkBaslik.KaynakIP := AKaynakIPAdres;
  EkBaslik.HedefIP := ABaglanti^.FHedefIPAdres;
  EkBaslik.Sifir := 0;
  EkBaslik.Protokol := PROTOKOL_TCP;
  EkBaslik.Uzunluk := Takas2(TSayi2(AVeriU + TCPBASLIK_UZUNLUGU));

  // tcp paketi hazýrlanýyor
  if(AVeriSonEk) then
    _BaslikUzunlugu := (((20 + AVeriU) shr 2) shl 4)
  else _BaslikUzunlugu := ((20 shr 2) shl 4);
  _TCPBaslik^.YerelPort := Takas2(ABaglanti^.FYerelPort);
  _TCPBaslik^.UzakPort := Takas2(ABaglanti^.FUzakPort);
  _TCPBaslik^.SiraNo := Takas4(ABaglanti^.FSiraNo);
  _TCPBaslik^.OnayNo := Takas4(ABaglanti^.FOnayNo);
  _TCPBaslik^.BaslikU := _BaslikUzunlugu;     // üst 4 bit = _BaslikUzunlugu * 4 = baþlýk uzunluðu;
  _TCPBaslik^.Bayrak := ABayrak;
  _TCPBaslik^.Pencere := Takas2(ABaglanti^.FPencereU);
  _TCPBaslik^.SaglamaToplam := 0;
  _TCPBaslik^.AcilIsaretci := 0;
  if(AVeriU > 0) then
  begin

    _p := @_TCPBaslik^.Secenekler;
    Tasi2(PByte(AVeri), _p, AVeriU);
  end;

  _Saglama := SaglamaToplamiOlustur(_TCPBaslik, TCPBASLIK_UZUNLUGU + AVeriU,
    @EkBaslik, SOZDE_TCPBASLIK_UZUNLUGU);
  _TCPBaslik^.SaglamaToplam := _Saglama;

  IPPaketGonder(ABaglanti^.FHedefMACAdres, AKaynakIPAdres, ABaglanti^.FHedefIPAdres,
    ptTCP, $4000, _TCPBaslik, TCPBASLIK_UZUNLUGU + AVeriU);

  GGercekBellek.YokEt(_TCPBaslik, TCPBASLIK_UZUNLUGU + AVeriU);
end;

end.
