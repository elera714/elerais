{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: http.pas
  Dosya Ýþlevi: HTTP sunucu protokol iþlevlerini yönetir

  Güncelleme Tarihi: 22/06/2026

 ==============================================================================}
{$mode objfpc}
unit http;

interface

uses paylasim, baglanti;

const
  USTSINIR_HTTPISTEMCI    = 10;

const
  WebSiteBaslik: PChar = 'HTTP/1.1 200 OK' + #13 + #10 +
    'Server: ELERA Web Sunucusu v1.0.6' + #13 + #10 +
    'Date: Mon, 01 Jun 2026 08:31:03 GMT' + #13 + #10 +
    'Content-Length: 332' + #13 + #10 +
    'Content-Type: text/html' + #13 + #10 +
    'Connection: close' + #13 + #10 + #13 + #10;

  WebSiteIcerik: PChar = '<!doctype html>' + #13 + #10 +
    '<html>' + #13 + #10 +
    '<head>' + #13 + #10 +
    '    <title>ELERA Web Sunucusu</title>' + #13 + #10 +
    '</head>' + #13 + #10 +
    '<body>' + #13 + #10 +
    '    <h1>ELERA Web Sunucusu</h1>' + #13 + #10 +
    '    <hr>' + #13 + #10 +
    '    <p>ELERA Web Sunucusu''na hoþ geldiniz.</p>' + #13 + #10 +
    '    <p>Sistem çalýþmalarýna eriþmek icin <a href="https://github.com/elera714">ELERA Ýþletim Sistemi</a> sayfasýný ziyaret ediniz.</p>' + #13 + #10 +
    '</body>' + #13 + #10 +
    '</html>';

type
  THTTPSunucu = object
  private
    FMevcutIstemciSayisi: TSayi4;
    FIstemciler: array[0..USTSINIR_HTTPISTEMCI - 1] of PBaglanti;
    function Al(ASiraNo: TISayi4): PBaglanti;
    procedure Yaz(ASiraNo: TISayi4; ABaglanti: PBaglanti);
  public
    procedure Yukle;
    property Istemciler[ASiraNo: TISayi4]: PBaglanti read Al write Yaz;
    function Ekle(APaketTipi: TSayi4; AIPAdres: Isaretci; AKaynakPort,
      AHedefPort: TSayi4): PBaglanti;
  end;

var
  HTTPSunucu0: THTTPSunucu;

procedure SunucuIslevHTTP(APaketTipi: TSayi4; ABaglanti: PBaglanti; AEthernetPaket: PEthernetPaket);

implementation

uses donusum, sistemmesaj, tcp;

{==============================================================================
  http sunucusu ana yükleme iþlevlerini içerir
 ==============================================================================}
procedure THTTPSunucu.Yukle;
var
  i: TSayi4;
begin

  FMevcutIstemciSayisi := 0;

  for i := 0 to USTSINIR_HTTPISTEMCI - 1 do Istemciler[i] := nil;
end;

function THTTPSunucu.Ekle(APaketTipi: TSayi4; AIPAdres: Isaretci; AKaynakPort,
  AHedefPort: TSayi4): PBaglanti;
var
  Istemci, B: PBaglanti;
  IT: TIletisimTipi;
  i, j: TSayi4;
  IPAdres: string;
begin

  Result := nil;

  // azami baðlantý sayýsý kontrolü
  if(HTTPSunucu0.FMevcutIstemciSayisi >= USTSINIR_HTTPISTEMCI) then Exit(nil);

  // istekte bulunan bilgisayar daha önce ayný port numarasýndan istekte bulunmuþ mu?
  for i := 0 to USTSINIR_HTTPISTEMCI - 1 do
  begin

    Istemci := HTTPSunucu0.Istemciler[i];
    if not(Istemci = nil) then
    begin

      if(HTTPSunucu0.Istemciler[i]^.YerelPort = AKaynakPort) then Exit(nil);
    end;
  end;

  if(APaketTipi = PROTOKOL_IP6) then
    IPAdres := IP_KarakterKatari6(PIP6Adres2(AIPAdres)^)
  else IPAdres := IP_KarakterKatari4(PIP4Adres(AIPAdres)^);

  // istemci için baðlantý oluþtur
  if(APaketTipi = PROTOKOL_IP6) then
    IT := itIP6
  else IT := itIP4;
  B := Baglantilar0.BaglantiOlustur(IT, btPasif, ptTCP, IPAdres, AKaynakPort, AHedefPort);
  if(B = nil) then Exit(nil);

  // oluþturulan baðlantýyý kaydet
  for i := 0 to USTSINIR_HTTPISTEMCI - 1 do
  begin

    Istemci := HTTPSunucu0.Istemciler[i];
    if(Istemci = nil) then
    begin

      HTTPSunucu0.Istemciler[i] := B;

      B^.BaglantiDurum := bdKapali;     { TODO - durumu yeni yapýlandýrmaya göre uygun bir þekilde belirle }

      j := HTTPSunucu0.FMevcutIstemciSayisi;
      Inc(j);
      HTTPSunucu0.FMevcutIstemciSayisi := j;

      Exit(B);
    end;
  end;
end;

function THTTPSunucu.Al(ASiraNo: TISayi4): PBaglanti;
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_HTTPISTEMCI) then
    Result := FIstemciler[ASiraNo]
  else Result := nil;
end;

procedure THTTPSunucu.Yaz(ASiraNo: TISayi4; ABaglanti: PBaglanti);
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_HTTPISTEMCI) then
    FIstemciler[ASiraNo] := ABaglanti;
end;

var
  VeriGonderiliyor: Boolean = False;

procedure SunucuIslevHTTP(APaketTipi: TSayi4; ABaglanti: PBaglanti; AEthernetPaket: PEthernetPaket);
const
  TCP4SYNSonEk: array[0..11] of TSayi1 = (
    $02, $04, $05, $B4, $01, $03, $03, $08, $01, $01, $04, $02);
  TCP6SYNSonEk: array[0..11] of TSayi1 = (
    $02, $04, $05, $A0, $01, $03, $03, $08, $01, $01, $04, $02);
var
  YeniB: PBaglanti;
  TCPPaket: PTCPPaket;
  IP6Paket: PIP6Paket;
  IP4Paket: PIP4Paket;
  KaynakIP: Isaretci;
  KaynakPort, HedefPort,
  IPUzunluk, U: TSayi2;
  i: TSayi4;
  p: PChar;
begin

  IP4Paket := PIP4Paket(@AEthernetPaket^.Veri);
  IP6Paket := PIP6Paket(@AEthernetPaket^.Veri);

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
    YeniB := HTTPSunucu0.Ekle(APaketTipi, KaynakIP, KaynakPort, HedefPort);
    if not(YeniB = nil) then
    begin

      SISTEM_MESAJ(mtUyari, RENK_BORDO, 'Web Sunucusu: yeni baðlantý. Kaynak port: %d', [KaynakPort]);

      YeniB^.SiraNo := Baglantilar0.TCPIlkSiraNoAl;
      YeniB^.OnayNo := ntohs(TCPPaket^.SiraNo) + 1;
      YeniB^.HedefMACAdres := AEthernetPaket^.KaynakMACAdres;

      if(APaketTipi = PROTOKOL_IP6) then
        YeniB^.HedefIP6Adres := PIP6Adres(KaynakIP)^
      else YeniB^.HedefIP4Adres := PIP4Adres(KaynakIP)^;

      if(APaketTipi = PROTOKOL_IP6) then
        TCPPaketGonder(APaketTipi, YeniB, @OnDegerIPV6Adresi, TCP_BAYRAK_ARZ or TCP_BAYRAK_KABUL, @TCP6SYNSonEk, 12, True)
      else TCPPaketGonder(APaketTipi, YeniB, @GAgBilgisi.IP4Adres, TCP_BAYRAK_ARZ or TCP_BAYRAK_KABUL, @TCP4SYNSonEk, 12, True);

      YeniB^.BaglantiDurum := bdBaglantiBekleniyor;
    end
    else
    begin

      SISTEM_MESAJ(mtUyari, RENK_BORDO, 'Web Sunucusu: zaten mevcut. Kaynak port: %d', [KaynakPort]);
    end;
  end
  // baðlantý kuran bilgisayarýn baðlantýyý kapatma isteði
  else if(TCPPaket^.Bayrak = TCP_BAYRAK_SON or TCP_BAYRAK_KABUL) then
  begin

    i := ntohs(TCPPaket^.OnayNo);
    ABaglanti^.SiraNo := i;

    i := ntohs(TCPPaket^.SiraNo);
    ABaglanti^.OnayNo := i + 1;

    if(APaketTipi = PROTOKOL_IP6) then
      TCPPaketGonder(APaketTipi, ABaglanti, @OnDegerIPV6Adresi, TCP_BAYRAK_KABUL, nil, 0)
    else TCPPaketGonder(APaketTipi, ABaglanti, @GAgBilgisi.IP4Adres, TCP_BAYRAK_KABUL, nil, 0);

    ABaglanti^.BaglantiDurum := bdKapanmayiBekliyor;

    if(APaketTipi = PROTOKOL_IP6) then
      TCPPaketGonder(APaketTipi, ABaglanti, @OnDegerIPV6Adresi, TCP_BAYRAK_SON or TCP_BAYRAK_KABUL, nil, 0)
    else TCPPaketGonder(APaketTipi, ABaglanti, @GAgBilgisi.IP4Adres, TCP_BAYRAK_SON or TCP_BAYRAK_KABUL, nil, 0);

    ABaglanti^.BaglantiDurum := bdSonOnay;
  end
  // baðlantý kuran bilgisayarýn veri gönderme isteði
  else if(TCPPaket^.Bayrak = TCP_BAYRAK_GONDER or TCP_BAYRAK_KABUL) then
  begin

    if(ABaglanti^.BaglantiDurum = bdBaglantiKuruldu) then
    begin

      i := ntohs(TCPPaket^.OnayNo);
      ABaglanti^.SiraNo := i;

      i := ntohs(TCPPaket^.SiraNo);
      if(APaketTipi = PROTOKOL_IP6) then
        U := ntohs(IPUzunluk) - 20
      else U := ntohs(IPUzunluk) - 40;
      ABaglanti^.OnayNo := i + U;

      if(U > 0) then Baglantilar0.BellegeEkle(ABaglanti, @TCPPaket^.Secenekler, U);

      // alýnan verinin deðerlendirilmesi
      p := @TCPPaket^.Secenekler;

      if(p[0] = 'G') and (p[1] = 'E') and (p[2] = 'T') then
      begin

        if(APaketTipi = PROTOKOL_IP6) then
          TCPPaketGonder(APaketTipi, ABaglanti, @OnDegerIPV6Adresi, TCP_BAYRAK_KABUL, nil, 0)
        else TCPPaketGonder(APaketTipi, ABaglanti, @GAgBilgisi.IP4Adres, TCP_BAYRAK_KABUL, nil, 0);
      end;

      Baglantilar0.Yaz(APaketTipi, ABaglanti^.Kimlik, WebSiteBaslik, Length(WebSiteBaslik));

      VeriGonderiliyor := True;
    end;
  end
  else if(TCPPaket^.Bayrak = TCP_BAYRAK_KABUL) then
  begin

    // istemci tarafýndan gönderilen ACK mesajýyla baðlantý kurulmuþtur
    if(ABaglanti^.BaglantiDurum = bdBaglantiBekleniyor) then

      ABaglanti^.BaglantiDurum := bdBaglantiKuruldu

    else if(ABaglanti^.BaglantiDurum = bdBaglantiKuruldu) then
    begin

      if(VeriGonderiliyor) then
      begin

        i := ntohs(TCPPaket^.OnayNo);
        ABaglanti^.SiraNo := i;

        i := ntohs(TCPPaket^.SiraNo);
        ABaglanti^.OnayNo := i;

        // 1. sayfa
        Baglantilar0.Yaz(APaketTipi, ABaglanti^.Kimlik, WebSiteIcerik, Length(WebSiteIcerik));

        i := Length(WebSiteIcerik);

        //SISTEM_MESAJ(mtUyari, RENK_SIYAH, 'TCP: U: %d', [i]);

        VeriGonderiliyor := False;
      end;
    end
    else if(ABaglanti^.BaglantiDurum = bdSonOnay) then
    begin

      ABaglanti^.Bagli := False;
      ABaglanti^.BaglantiDurum := bdYok;
      if not(ABaglanti^.Bellek = nil) then FreeMem(ABaglanti^.Bellek, 4 * 4096);

      Baglantilar0.Baglanti[ABaglanti^.Kimlik] := nil;
      FreeMem(ABaglanti, SizeOf(TBaglanti));
    end;
  end
  else
  begin

    SISTEM_MESAJ(mtUyari, RENK_SIYAH, 'HTTP: ?', []);
  end;
end;

end.
