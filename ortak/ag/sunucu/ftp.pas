{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: ftp.pas
  Dosya Ýþlevi: FTP (dosya) sunucu protokol iþlevlerini yönetir

  Güncelleme Tarihi: 25/07/2026

 ==============================================================================}
{$mode objfpc}
unit ftp;

interface

uses paylasim, baglanti;

const
  USTSINIR_FTPISTEMCI     = 10;

  { TODO - yapýlandýrýlacak }
  KULLANICI_ADI           = 'elera';
  SIFRE                   = 'elera';

const
  Tanitim             : PChar = '220 ELERA Dosya Sunucusu' + #13 + #10;
  BaglantiKapatiliyor : PChar = '221 baðlantý kapatýlýyor' + #13 + #10;
  GirisBasarili       : PChar = '230 Giriþ baþarýlý' + #13 + #10;

  SifreGirisi         : PChar = '331 Þifre giriniz' + #13 + #10;

  GirisHatali         : PChar = '530 Kullanýcý adý veya þifre hatalý' + #13 + #10;

type
  TFTPSunucu = class
  private
    FAktifIstemciSayisi: TSayi4;
    FIstemciler: array[0..USTSINIR_FTPISTEMCI - 1] of TBaglanti;
    function Al(ASiraNo: TISayi4): TBaglanti;
    procedure Yaz(ASiraNo: TISayi4; ABaglanti: TBaglanti);
  public
    constructor Create;
    property Istemciler[ASiraNo: TISayi4]: TBaglanti read Al write Yaz;
    function Ekle(APaketTipi: TSayi4; AIPAdres: Isaretci; AKaynakPort,
      AHedefPort: TSayi4): TBaglanti;
    property AktifIstemciSayisi: TSayi4 read FAktifIstemciSayisi;
  end;

var
  FTPSunucu0: TFTPSunucu;

procedure SunucuIslevFTP(APaketTipi: TSayi4; ABaglanti: TBaglanti; AEthernetPaket: PEthernetPaket);

implementation

uses donusum, sistemmesaj, tcp;

{==============================================================================
  ftp sunucusu ana yükleme iþlevlerini içerir
 ==============================================================================}
constructor TFTPSunucu.Create;
var
  i: TSayi4;
begin

  FAktifIstemciSayisi := 0;

  for i := 0 to USTSINIR_FTPISTEMCI - 1 do Istemciler[i] := nil;
end;

function TFTPSunucu.Al(ASiraNo: TISayi4): TBaglanti;
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_FTPISTEMCI) then
    Result := FIstemciler[ASiraNo]
  else Result := nil;
end;

procedure TFTPSunucu.Yaz(ASiraNo: TISayi4; ABaglanti: TBaglanti);
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_FTPISTEMCI) then
    FIstemciler[ASiraNo] := ABaglanti;
end;

function TFTPSunucu.Ekle(APaketTipi: TSayi4; AIPAdres: Isaretci; AKaynakPort,
  AHedefPort: TSayi4): TBaglanti;
var
  B, B2: TBaglanti;
  IT: TIletisimTipi;
  i: TSayi4;
  IPAdres: string;
begin

  Result := nil;

  // azami baðlantý sayýsý kontrolü
  if(FTPSunucu0.AktifIstemciSayisi >= USTSINIR_FTPISTEMCI) then Exit(nil);

  // istekte bulunan bilgisayar daha önce ayný port numarasýndan istekte bulunmuþ mu?
  for i := 0 to USTSINIR_FTPISTEMCI - 1 do
  begin

    B2 := FTPSunucu0.Istemciler[i];
    if not(B2 = nil) then
    begin

      if(B2.YerelPort = AKaynakPort) then Exit(nil);
    end;
  end;

  if(APaketTipi = PROTOKOL_IP6) then
    IPAdres := IP_KarakterKatari6(PIP6Adres2(AIPAdres)^)
  else IPAdres := IP_KarakterKatari4(PIP4Adres(AIPAdres)^);

  // istemci için baðlantý oluþtur
  if(APaketTipi = PROTOKOL_IP6) then
    IT := itIP6
  else IT := itIP4;

  B := GBaglantilar.BaglantiOlustur(IT,  btPasif, ptTCP, IPAdres, AKaynakPort, AHedefPort);
  if(B = nil) then Exit(nil);

  // oluþturulan baðlantýyý kaydet
  for i := 0 to USTSINIR_FTPISTEMCI - 1 do
  begin

    B2 := FTPSunucu0.Istemciler[i];
    if(B2 = nil) then
    begin

      FTPSunucu0.Istemciler[i] := B;

      { TODO - durumu yeni yapýlandýrmaya göre uygun bir þekilde belirle }
      B.BaglantiDurum := bdKapali;

      Inc(FTPSunucu0.FAktifIstemciSayisi);

      Exit(B);
    end;
  end;
end;

procedure SunucuIslevFTP(APaketTipi: TSayi4; ABaglanti: TBaglanti; AEthernetPaket: PEthernetPaket);
var
  B: TBaglanti;
  IP6Paket: PIP6Paket;
  IP4Paket: PIP4Paket;
  TCPPaket: PTCPPaket;
  KaynakIP: Isaretci;
  KaynakPort, HedefPort,
  IPUzunluk, U: TSayi2;
  i: TSayi4;
  p: PChar;
  s, s2: string;
begin

  IP6Paket := PIP6Paket(@AEthernetPaket^.Veri);
  IP4Paket := PIP4Paket(@AEthernetPaket^.Veri);

  if(APaketTipi = PROTOKOL_IP6) then
  begin

    KaynakIP := @IP6Paket^.KaynakIP;
    TCPPaket := PTCPPaket(@IP6Paket^.Veri);
    IPUzunluk := IP6Paket^.TasinanVeriU;
  end
  else if(APaketTipi = PROTOKOL_IP4) then
  begin

    KaynakIP := @IP4Paket^.KaynakIP;
    TCPPaket := PTCPPaket(@IP4Paket^.Veri);
    IPUzunluk := IP4Paket^.ToplamUzunluk;
  end else Exit;

  if(ABaglanti = nil) then
  begin

    KaynakPort := ntohs(TCPPaket^.YerelPort);      // paketi gönderen cihazýn portu
    HedefPort := ntohs(TCPPaket^.UzakPort);        // paketi alan cihazýn yerel portu (bu bilgisayar)

    // bu aþamada istemciden SYN mesajý gelmiþ, sunucu olarak istemciye SYN + ACK mesajý göndrilmiþtir
    B := FTPSunucu0.Ekle(APaketTipi, KaynakIP, KaynakPort, HedefPort);
    if not(B = nil) then
    begin

      //SISTEM_MESAJ(mtUyari, RENK_BORDO, 'Dosya Sunucusu: yeni baðlantý. Kaynak port: %d', [KaynakPort]);

      B.SiraNo := GBaglantilar.TCPIlkSiraNoAl;
      B.OnayNo := ntohs(TCPPaket^.SiraNo) + 1;
      B.HedefMACAdres := AEthernetPaket^.KaynakMACAdres;

      if(APaketTipi = PROTOKOL_IP6) then
        B.HedefIP6Adres := PIP6Adres(KaynakIP)^
      else B.HedefIP4Adres := PIP4Adres(KaynakIP)^;

      if(APaketTipi = PROTOKOL_IP6) then
        TCPPaketGonder(APaketTipi, B, TCP_BAYRAK_ARZ or TCP_BAYRAK_KABUL, @TCP6SYNSonEk, 12, True)
      else TCPPaketGonder(APaketTipi, B, TCP_BAYRAK_ARZ or TCP_BAYRAK_KABUL, @TCP4SYNSonEk, 12, True);

      B.BaglantiDurum := bdBaglantiBekleniyor;
    end
    else
    begin

      SISTEM_MESAJ(mtUyari, RENK_BORDO, 'Dosya Sunucusu: zaten mevcut. Kaynak port: %d', [KaynakPort]);
    end;
  end
  // baðlantý kuran bilgisayarýn baðlantýyý kapatma isteði
  else if(TCPPaket^.Bayrak = TCP_BAYRAK_SON or TCP_BAYRAK_KABUL) then
  begin

    i := ntohs(TCPPaket^.OnayNo);
    ABaglanti.SiraNo := i;

    i := ntohs(TCPPaket^.SiraNo);
    ABaglanti.OnayNo := i + 1;

    if(APaketTipi = PROTOKOL_IP6) then
      TCPPaketGonder(APaketTipi, ABaglanti, TCP_BAYRAK_KABUL, nil, 0)
    else TCPPaketGonder(APaketTipi, ABaglanti, TCP_BAYRAK_KABUL, nil, 0);

    ABaglanti.BaglantiDurum := bdKapanmayiBekliyor;

    if(APaketTipi = PROTOKOL_IP6) then
      TCPPaketGonder(APaketTipi, ABaglanti, TCP_BAYRAK_SON or TCP_BAYRAK_KABUL, nil, 0)
    else TCPPaketGonder(APaketTipi, ABaglanti, TCP_BAYRAK_SON or TCP_BAYRAK_KABUL, nil, 0);

    ABaglanti.BaglantiDurum := bdSonOnay;
  end
  // baðlantý kuran bilgisayarýn veri gönderme isteði
  else if(TCPPaket^.Bayrak = TCP_BAYRAK_GONDER or TCP_BAYRAK_KABUL) then
  begin

    if(ABaglanti.BaglantiDurum = bdBaglantiKuruldu) then
    begin

      i := ntohs(TCPPaket^.OnayNo);
      ABaglanti.SiraNo := i;

      i := ntohs(TCPPaket^.SiraNo);
      if(APaketTipi = PROTOKOL_IP6) then
        U := ntohs(IPUzunluk) - 20
      else U := ntohs(IPUzunluk) - 40;
      ABaglanti.OnayNo := i + U;

      //if(U > 0) then Baglantilar0.BellegeEkle(ABaglanti, @TCPPaket^.Secenekler, U);

      // alýnan verinin deðerlendirilmesi
      p := @TCPPaket^.Secenekler;

      s := p;

      s2 := Copy(s, 1, 4);

      if(s2 = 'USER') then
      begin

        i := ntohs(TCPPaket^.OnayNo);
        ABaglanti.SiraNo := i;

        i := ntohs(TCPPaket^.SiraNo);
        if(APaketTipi = PROTOKOL_IP6) then
          U := ntohs(IPUzunluk) - 20
        else U := ntohs(IPUzunluk) - 40;
        ABaglanti.OnayNo := i + U;

        if(APaketTipi = PROTOKOL_IP6) then
          TCPPaketGonder(APaketTipi, ABaglanti, TCP_BAYRAK_KABUL, nil, 0)
        else TCPPaketGonder(APaketTipi, ABaglanti, TCP_BAYRAK_KABUL, nil, 0);

        ABaglanti.Yaz(APaketTipi, SifreGirisi, Length(SifreGirisi));
      end
      else if(s2 = 'PASS') then
      begin

        i := ntohs(TCPPaket^.OnayNo);
        ABaglanti.SiraNo := i;

        i := ntohs(TCPPaket^.SiraNo);
        if(APaketTipi = PROTOKOL_IP6) then
          U := ntohs(IPUzunluk) - 20
        else U := ntohs(IPUzunluk) - 40;
        ABaglanti.OnayNo := i + U;

        if(APaketTipi = PROTOKOL_IP6) then
          TCPPaketGonder(APaketTipi, ABaglanti, TCP_BAYRAK_KABUL, nil, 0)
        else TCPPaketGonder(APaketTipi, ABaglanti, TCP_BAYRAK_KABUL, nil, 0);

        //Baglantilar0.Yaz(ABaglanti^.Kimlik, GirisHatali, Length(GirisHatali));
        ABaglanti.Yaz(APaketTipi, GirisBasarili, Length(GirisBasarili));
      end
      else if(s2 = 'QUIT') then
      begin

        i := ntohs(TCPPaket^.OnayNo);
        ABaglanti.SiraNo := i;

        i := ntohs(TCPPaket^.SiraNo);
        if(APaketTipi = PROTOKOL_IP6) then
          U := ntohs(IPUzunluk) - 20
        else U := ntohs(IPUzunluk) - 40;
        ABaglanti.OnayNo := i + U;

        if(APaketTipi = PROTOKOL_IP6) then
          TCPPaketGonder(APaketTipi, ABaglanti, TCP_BAYRAK_KABUL, nil, 0)
        else TCPPaketGonder(APaketTipi, ABaglanti, TCP_BAYRAK_KABUL, nil, 0);

        ABaglanti.Yaz(APaketTipi, BaglantiKapatiliyor, Length(BaglantiKapatiliyor));
      end;
    end;
  end
  else if(TCPPaket^.Bayrak = TCP_BAYRAK_KABUL) then
  begin

    // istemci tarafýndan gönderilen ACK mesajýyla baðlantý kurulmuþtur
    if(ABaglanti.BaglantiDurum = bdBaglantiBekleniyor) then
    begin

      ABaglanti.BaglantiDurum := bdBaglantiKuruldu;

      i := ntohs(TCPPaket^.OnayNo);
      ABaglanti.SiraNo := i;

      i := ntohs(TCPPaket^.SiraNo);
      ABaglanti.OnayNo := i;

      ABaglanti.Yaz(APaketTipi, Tanitim, Length(Tanitim));
    end
    else if(ABaglanti.BaglantiDurum = bdSonOnay) then
    begin

      ABaglanti.Bagli := False;
      ABaglanti.BaglantiDurum := bdYok;
      if not(ABaglanti.FBellek = nil) then FreeMem(ABaglanti.FBellek, 4 * 4096);

      for i := 0 to USTSINIR_FTPISTEMCI - 1 do
      begin

        B := FTPSunucu0.Istemciler[i];
        if not(B = nil) and (B.YerelPort = ABaglanti.YerelPort) then
        begin

          ABaglanti.Destroy;
          FTPSunucu0.Istemciler[i] := nil;

          Dec(FTPSunucu0.FAktifIstemciSayisi);
          Exit;
        end;
      end;
    end;
  end
  else
  begin

    SISTEM_MESAJ(mtUyari, RENK_SIYAH, 'FTP: ?', []);
  end;
end;

end.
