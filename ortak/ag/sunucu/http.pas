{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: http.pas
  Dosya Ýþlevi: http sunucu protokol iþlevlerini yönetir

  Güncelleme Tarihi: 25/07/2026

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
    'Date: Mon, 01 Jun 2026 12:34:56 GMT' + #13 + #10 +
    { TODO - 332 deðeri WebSiteIcerik deðiþkenindeki karakter sayýsý olacak }
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

  AnaSayfaHataBaslik: PChar = 'HTTP/1.1 404 Not Found' + #13 + #10 +
    'Server: ELERA Web Sunucusu v1.0' + #13 + #10 +
    'Date: Mon, 01 Jun 2026 12:34:56 GMT' + #13 + #10 +
    'Content-Length: 254' + #13 + #10 +
    'Connection: close' + #13 + #10 + #13 + #10;

  AnaSayfaHataIcerik: PChar = '<!doctype html>' + #13 + #10 +
    '<html>' + #13 + #10 +
    '<head>' + #13 + #10 +
    '  <title>ELERA Web Sunucusu - Hata [404]</title>' + #13 + #10 +
    '</head>' + #13 + #10 +
    '<body>' + #13 + #10 +
    '  <div align=''center''>' + #13 + #10 +
    '    <h1>Sayfa Mevcut Deðil [404]</h1>' + #13 + #10 +
    '    <hr>' + #13 + #10 +
    '    <p>Ýstenen ''x'' sayfasý sunucuda mevcut deðil!</p>' + #13 + #10 +
    '  </div>' + #13 + #10 +
    '</body>' + #13 + #10 +
    '</html>';

type
  THTTPSunucu = class
  private
    FAktifIstemciSayisi: TSayi4;
    FIstemciler: array[0..USTSINIR_HTTPISTEMCI - 1] of TBaglanti;
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
  HTTPSunucu0: THTTPSunucu;

procedure SunucuIslevHTTP(APaketTipi: TSayi4; ABaglanti: TBaglanti; AEthernetPaket: PEthernetPaket);
function SayfaDegeriniAl(var ABellek: Isaretci): string;

implementation

uses donusum, sistemmesaj, tcp;

{==============================================================================
  http sunucusu ana yükleme iþlevlerini içerir
 ==============================================================================}
constructor THTTPSunucu.Create;
var
  i: TSayi4;
begin

  FAktifIstemciSayisi := 0;

  for i := 0 to USTSINIR_HTTPISTEMCI - 1 do Istemciler[i] := nil;
end;

function THTTPSunucu.Al(ASiraNo: TISayi4): TBaglanti;
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_HTTPISTEMCI) then
    Result := FIstemciler[ASiraNo]
  else Result := nil;
end;

procedure THTTPSunucu.Yaz(ASiraNo: TISayi4; ABaglanti: TBaglanti);
begin

  // istenen verinin belirtilen aralýkta olup olmadýðýný kontrol et
  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_HTTPISTEMCI) then
    FIstemciler[ASiraNo] := ABaglanti;
end;

function THTTPSunucu.Ekle(APaketTipi: TSayi4; AIPAdres: Isaretci; AKaynakPort,
  AHedefPort: TSayi4): TBaglanti;
var
  B, B2: TBaglanti;
  IT: TIletisimTipi;
  i: TSayi4;
  IPAdres: string;
begin

  Result := nil;

  // azami baðlantý sayýsý kontrolü
  if(HTTPSunucu0.AktifIstemciSayisi >= USTSINIR_HTTPISTEMCI) then Exit(nil);

  // istekte bulunan bilgisayar daha önce ayný port numarasýndan istekte bulunmuþ mu?
  for i := 0 to USTSINIR_HTTPISTEMCI - 1 do
  begin

    B2 := HTTPSunucu0.Istemciler[i];
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

  B := GBaglantilar.BaglantiOlustur(IT, btPasif, ptTCP, IPAdres, AKaynakPort, AHedefPort);
  if(B = nil) then Exit(nil);

  // oluþturulan baðlantýyý kaydet
  for i := 0 to USTSINIR_HTTPISTEMCI - 1 do
  begin

    B2 := HTTPSunucu0.Istemciler[i];
    if(B2 = nil) then
    begin

      HTTPSunucu0.Istemciler[i] := B;

      { TODO - durumu yeni yapýlandýrmaya göre uygun bir þekilde belirle }
      B.BaglantiDurum := bdKapali;

      Inc(HTTPSunucu0.FAktifIstemciSayisi);

      Exit(B);
    end;
  end;
end;

var
  VeriGonderiliyor: Boolean = False;
  IstenenSayfa: string;

procedure SunucuIslevHTTP(APaketTipi: TSayi4; ABaglanti: TBaglanti; AEthernetPaket: PEthernetPaket);
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
    B := HTTPSunucu0.Ekle(APaketTipi, KaynakIP, KaynakPort, HedefPort);
    if not(B = nil) then
    begin

      //SISTEM_MESAJ(mtUyari, RENK_BORDO, 'Web Sunucusu: yeni baðlantý. Kaynak port: %d', [KaynakPort]);

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

      SISTEM_MESAJ(mtUyari, RENK_BORDO, 'Web Sunucusu: zaten mevcut. Kaynak port: %d', [KaynakPort]);
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

      if(U > 0) then ABaglanti.BellegeEkle(@TCPPaket^.Secenekler, U);

      // alýnan verinin deðerlendirilmesi
      p := @TCPPaket^.Secenekler;

      if(APaketTipi = PROTOKOL_IP6) then
        TCPPaketGonder(APaketTipi, ABaglanti, TCP_BAYRAK_KABUL, nil, 0)
      else TCPPaketGonder(APaketTipi, ABaglanti, TCP_BAYRAK_KABUL, nil, 0);

      IstenenSayfa := SayfaDegeriniAl(p);
      //SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'Sayfa: [%s]', [IstenenSayfa]);

      VeriGonderiliyor := True;

      if(IstenenSayfa = '/') then
        ABaglanti.Yaz(APaketTipi, WebSiteBaslik, Length(WebSiteBaslik))
      else ABaglanti.Yaz(APaketTipi, AnaSayfaHataBaslik, Length(AnaSayfaHataBaslik));
    end;
  end
  else if(TCPPaket^.Bayrak = TCP_BAYRAK_KABUL) then
  begin

    //SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'ACK', []);

    // istemci tarafýndan gönderilen ACK mesajýyla baðlantý kurulmuþtur
    if(ABaglanti.BaglantiDurum = bdBaglantiBekleniyor) then

      ABaglanti.BaglantiDurum := bdBaglantiKuruldu

    else if(ABaglanti.BaglantiDurum = bdBaglantiKuruldu) then
    begin

      if(VeriGonderiliyor) then
      begin

        i := ntohs(TCPPaket^.OnayNo);
        ABaglanti.SiraNo := i;

        i := ntohs(TCPPaket^.SiraNo);
        ABaglanti.OnayNo := i;

        // 1. sayfa
        if(IstenenSayfa = '/') then
          ABaglanti.Yaz(APaketTipi, WebSiteIcerik, Length(WebSiteIcerik))
        else ABaglanti.Yaz(APaketTipi, AnaSayfaHataIcerik, Length(AnaSayfaHataIcerik));

        //i := Length(WebSiteIcerik);
        //SISTEM_MESAJ(mtUyari, RENK_SIYAH, 'TCP: U: %d', [i]);

        VeriGonderiliyor := False;
      end;
    end
    else if(ABaglanti.BaglantiDurum = bdSonOnay) then
    begin

      ABaglanti.Bagli := False;
      ABaglanti.BaglantiDurum := bdYok;
      if not(ABaglanti.FBellek = nil) then FreeMem(ABaglanti.FBellek, 4 * 4096);

      for i := 0 to USTSINIR_HTTPISTEMCI - 1 do
      begin

        B := HTTPSunucu0.Istemciler[i];
        if not(B = nil) and (B.YerelPort = ABaglanti.YerelPort) then
        begin

          ABaglanti.Destroy;
          HTTPSunucu0.Istemciler[i] := nil;

          Dec(HTTPSunucu0.FAktifIstemciSayisi);
          Exit;
        end;
      end;
    end;
  end
  else
  begin

    SISTEM_MESAJ(mtUyari, RENK_SIYAH, 'HTTP: ?', []);
  end;
end;

// http istek baþlýk deðerinden istenen sayfanýn adýný alýr
// bilgi: þu aþamada SADECE ana sayfa (/) kontrolü yapýlmaktadýr
function SayfaDegeriniAl(var ABellek: Isaretci): string;
var
  s, s2: string;
  i: TSayi4;
begin

  Result := '';

  s := '';

  repeat

    while PChar(ABellek)^ <> #13 do
    begin

      s := s + PChar(ABellek)^;
      Inc(ABellek);
    end;

    Inc(ABellek, 2);

    i := Length(s);

    if(i > 0) then
    begin

      s2 := Copy(s, 1, 10);
      if(s2 = 'GET / HTTP') then Exit('/');
    end;

    s := '';

  until i = 0;
end;

end.
