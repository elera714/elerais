{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: tcp.pas
  Dosya Ýþlevi: tcp v4/v6 katmaný veri iletiþimini gerçekleþtirir

  Güncelleme Tarihi: 11/11/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
//{$DEFINE TCP_BILGI}
unit tcp;

interface

uses paylasim, ip6, ip4;

const
  USTSINIR_TCPBAGLANTI_SAYISI = 128;

const
  TCP_BASLIK_U      = 20;
  TCP4_EKBASLIK_U   = 12;
  TCP6_EKBASLIK_U   = 40;

const
  // tcp baðlantýsýnýn ilk SYN, SYN + ACK paketi için gerekli ek veri deðerleri
  TCP4SYNSonEk: array[0..11] of TSayi1 = (
    $02, $04, $05, $B4, $01, $03, $03, $08, $01, $01, $04, $02);
  TCP6SYNSonEk: array[0..11] of TSayi1 = (
    $02, $04, $05, $A0, $01, $03, $03, $08, $01, $01, $04, $02);

type
  PTCPPaket = ^TTCPPaket;
  TTCPPaket = packed record
    YerelPort,
    UzakPort: TSayi2;
    SiraNo,                     // sequence number
    OnayNo: TSayi4;
    BaslikU: TSayi1;            // 11111000 = 111111 = Data Offset, 000 = Reserved
    Bayrak: TSayi1;
    Pencere: TSayi2;
    SaglamaToplami,
    AcilIsaretci: TSayi2;       // urgent pointer
    Veri: Isaretci;
  end;

type
  PTCP = ^TTCP;
  TTCP = class
  public
    FBaglanti: TObject;
    FIP6: TIP6;
    FIP4: TIP4;
    FIletisimTipi: TIletisimTipi;
    FSiraNo,                      // TCP sýra no (sequence number)
    FOnayNo,                      // TCP onay no (acknowledgment number)
    FPencereU: TSayi4;

    // gecikmeli / süreli ACK göndermeleri için kullanýlacak
    FOnayMesajiGonder: Boolean;
    FOnayZamanAsimi: TSayi4;
  public
    constructor Create(ABaglanti: TObject; AIletisimTipi: TIletisimTipi;
      AHedefMACAdres: TMACAdres);
    procedure PaketleVeGonder(ABayrak: TSayi4; AVeri: Isaretci; AVeriU: TSayi4;
      AVeriSonEk: Boolean = False);
    procedure BaglantiTalebiGonder;
    procedure BaglantiTalebineOnayGonder(ATCPPaket: PTCPPaket);
    procedure BaglantiyiOnayla(ATCPPaket: PTCPPaket);
    procedure SadeceOnayMesajiGonder;
    procedure OnayOlayiniIsle(ATCPPaket: PTCPPaket);
    procedure GelenVeriyiAl(ATCPPaket: PTCPPaket; AVeriUzunlugu: TSayi4);
    procedure SonlandirmayiYanitla;
  end;

procedure TCPVerileriniIsle(AEthernetPaket: PEthernetPaket);

implementation

uses donusum, islevler, sunucular, baglantilar, sistemmesaj, zamanlayici;

{==============================================================================
  tcp tutanaðý katmanýna gelen verileri iþler
 ==============================================================================}
procedure TCPVerileriniIsle(AEthernetPaket: PEthernetPaket);
var
  B: TBaglanti;
  TCPPaket: PTCPPaket;
  IP6Paket: PIP6Paket;
  IP4Paket: PIP4Paket;
  IT: TIletisimTipi;
  YerelPort, UzakPort,
  PT, VeriU: TSayi4;
  PortBulundu: Boolean;
begin

  IP6Paket := PIP6Paket(@AEthernetPaket^.Veri);
  IP4Paket := PIP4Paket(@AEthernetPaket^.Veri);

  PT := htons(AEthernetPaket^.PaketTipi);
  if(PT = TUTANAK_IP6) then
  begin

    IT := itIP6;
    TCPPaket := PTCPPaket(@IP6Paket^.Veri)
  end
  else if(PT = TUTANAK_IP4) then
  begin

    IT := itIP4;
    TCPPaket := PTCPPaket(@IP4Paket^.Veri)
  end else Exit;

  YerelPort := ntohs(TCPPaket^.YerelPort);        // paketi gönderen cihazýn yerel portu
  UzakPort := ntohs(TCPPaket^.UzakPort);          // paketi alan cihazýn uzak portu (bu bilgisayar)

  {$IFDEF TCP_BILGI}
  SISTEM_MESAJ(mtBilgi, RENK_MOR, '-------------------------', []);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'TCP: Yerel Port: %d', [YerelPort]);
  SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'TCP: Uzak Port: %d', [UzakPort]);
  {$ENDIF}

  // yerelport <-> uzakport arasýnda iletiþim var mý?
  B := TBaglanti(GAgBaglantilari.AB.BaglantiBul(ttTCP, YerelPort, UzakPort));
  if(B = nil) then
  begin

    // baðlantý yoksa, mevcut sunuculardan birine mi baðlantý saðlanmaya çalýþýlýyor
    PortBulundu := True;

    { TODO - bnFTPi, bnHTTPi üzerinden tanýmlanacak, þu an itibariyle nesne tanýmlanmadý }
    case UzakPort of
      FTP_PORTNO:
        B := GAgBaglantilari.AB.BaglantiOlustur(bnFTPs, IT, btUAktif, ttTCP,
          YerelPort, UzakPort);
      HTTP_PORTNO:
        B := GAgBaglantilari.AB.BaglantiOlustur(bnHTTPs, IT, btUAktif, ttTCP,
          YerelPort, UzakPort);
      else
      begin

        B := GAgBaglantilari.AB.BaglantiOlustur(bnHTTPs, IT, btUAktif, ttTCP,
          YerelPort, UzakPort);

        PortBulundu := False;
      end;
    end;

    // ethernet katman bilgileri - hedef mac adres atamasý
    if(IT = itIP6) then
      B.FTCP.FIP6.FHedefMACAdres := AEthernetPaket^.KaynakMACAdres
    else B.FTCP.FIP4.FHedefMACAdres := AEthernetPaket^.KaynakMACAdres;

    // belirtilen port için dinleme yapan sunucu varsa
    if not(B = nil) and PortBulundu then
    begin

      // ip katman bilgileri

      // bu aþamada uzak bilgisayar bu sistemin sunucu sistemine baðlantý yapmak istemektedir
      // sistemde istenen sunucu bulunmuþ ve baðlantý yapýlacaktýr
      // bu bir btUAktif baðlantýsýdýr ve kaynak / hedef ip adresleri ip6/4 katmanýn
      // doðru iletiþim kurmasý için kayýt edilmektedir
      if(IT = itIP6) then
      begin

        B.FTCP.FIP6.FKaynakIPAdres := IP6Paket^.HedefIPAdres;
        B.FTCP.FIP6.FHedefIPAdres := IP6Paket^.KaynakIPAdres;
      end
      else
      begin

        B.FTCP.FIP4.FKaynakIPAdres := IP4Paket^.HedefIPAdres;
        B.FTCP.FIP4.FHedefIPAdres := IP4Paket^.KaynakIPAdres;
      end;

      B.FTCP.BaglantiTalebineOnayGonder(TCPPaket);
    end
    else
    // istenen port numarasýnda hizmet veren sunucu yoksa istemciye sýfýrlama paketi gönder
    begin

      if(IT = itIP6) then
      begin

        B.FTCP.FIP6.FKaynakIPAdres := IP6Paket^.HedefIPAdres;
        B.FTCP.FIP6.FHedefIPAdres := IP6Paket^.KaynakIPAdres;
      end
      else
      begin

        B.FTCP.FIP4.FKaynakIPAdres := IP4Paket^.HedefIPAdres;
        B.FTCP.FIP4.FHedefIPAdres := IP4Paket^.KaynakIPAdres;
      end;

      // gelen SiraNo deðerini 1 artýrarak gönder
      B.FTCP.FSiraNo := 0;
      B.FTCP.FOnayNo := ntohs(ntohs(TCPPaket^.SiraNo) + 1);
      B.FTCP.FPencereU := 0;

      // baðlantýnýn kapatýlmasýna dair onay deðerini gönder
      B.FTCP.PaketleVeGonder(TCP_BAYRAK_KABUL or TCP_BAYRAK_SIFIRLA, nil, 0);
    end;
  end
  else
  begin

    // baðlantý kapalýysa çýk
    if(B.FBaglantiDurum = bdKapali) then Exit;

    // son onay bekleniyorsa baðlantý durumunu kapat
    // bilgi: kapatma aþaðýdaki satýrdaki ACK onayýna býrakýlmamalýdýr
    if(B.FBaglantiDurum = bdSonOnay) then
    begin

      if((TCPPaket^.Bayrak and TCP_BAYRAK_KABUL) = TCP_BAYRAK_KABUL) then
      begin

        B.FBaglantiDurum := bdKapali;
        Exit;
      end;
    end;

    // her bir veri PSH ve/veya ACK ile geldiði için
    // ACK bayraðý aktif olduðunda veri alýnýyor
    { TODO - istisnai durumlar olabilir, incelenmeli }
    if((TCPPaket^.Bayrak and TCP_BAYRAK_KABUL) = TCP_BAYRAK_KABUL) then
    begin

      if(IT = itIP6) then
        VeriU := ntohs(IP6Paket^.TasinanVeriU)    { TODO - teyit et }
      else VeriU := ntohs(IP4Paket^.ToplamUzunluk) - 40;

      // veri varsa gelen veriyi al
      if(VeriU > 0) then B.FTCP.GelenVeriyiAl(TCPPaket, VeriU);
    end;

    // ACK olayýnýn iþlendiði kýsým
    if((TCPPaket^.Bayrak and TCP_BAYRAK_KABUL) = TCP_BAYRAK_KABUL) then
    begin

      // olayý iþle
      B.FTCP.OnayOlayiniIsle(TCPPaket);

      // sadece ACK bayraðý aktif ve veri de mevcut ise hemen onay mesajý gönder
      if(TCPPaket^.Bayrak = TCP_BAYRAK_KABUL) and (VeriU > 0) then B.FTCP.SadeceOnayMesajiGonder;
    end;

    // SYN mesajýma SYN + ACK ile gelen yanýta verilen yanýt
    // bilgi: bu aþamada istemci olarak baðlantý kurulmuþtur
    if((TCPPaket^.Bayrak and TCP_BAYRAK_ARZ) = TCP_BAYRAK_ARZ) then
    begin

      if(B.FBaglantiDurum = bdBaglaniyor) then B.FTCP.BaglantiyiOnayla(TCPPaket);
    end;

    // verinin uygulama katmanýna gönderilmesi için gönderilen mesaj
    // bilgi: bu kýsým genellikle ACK ile birlikte geldiði için veriler
    // üst satýrda alýnmaktadýr
    if((TCPPaket^.Bayrak and TCP_BAYRAK_GONDER) = TCP_BAYRAK_GONDER) then
    begin end;

    // karþý bilgisayardan FIN = baðlantýyý sonlandýrma isteðinin gelmesi
    if((TCPPaket^.Bayrak and TCP_BAYRAK_SON) = TCP_BAYRAK_SON) then
    begin

      B.FTCP.SonlandirmayiYanitla;
    end;
  end;
end;

{==============================================================================
  tcp tutanak (protokol) ana yükleme iþlevlerini içerir
 ==============================================================================}
constructor TTCP.Create(ABaglanti: TObject; AIletisimTipi: TIletisimTipi;
  AHedefMACAdres: TMACAdres);
begin

  FBaglanti := ABaglanti;

  FIletisimTipi := AIletisimTipi;

  TBaglanti(FBaglanti).FBaglantiDurum := bdKapali;

  if(AIletisimTipi = itIP6) then
    FIP6 := TIP6.Create(ABaglanti, AHedefMACAdres)
  else if(AIletisimTipi = itIP4) then
    FIP4 := TIP4.Create(ABaglanti, AHedefMACAdres);

  FSiraNo := 0;
  FOnayNo := 0;
  FPencereU := TCP_PENCERE_UZUNLUK;

  FOnayMesajiGonder := False;
  FOnayZamanAsimi := 0;
end;

{==============================================================================
  tcp paket hazýrlama ve gönderme iþlevlerini gerçekleþtirir
 ==============================================================================}
procedure TTCP.PaketleVeGonder(ABayrak: TSayi4; AVeri: Isaretci; AVeriU: TSayi4;
  AVeriSonEk: Boolean = False);
var
  TCPPaket: PTCPPaket;
  Ek6Baslik: TEk6Baslik;
  Ek4Baslik: TEk4Baslik;
  SaglamaToplami: TSayi2;
  BaslikUzunlugu: TSayi1;
  p: PByte;
begin

  TCPPaket := GetMem(TCP_BASLIK_U + AVeriU);

  // baþlýk verisi için ek baþlýk saðlama deðeri hesaplanýyor
  if(FIletisimTipi = itIP6) then
  begin

    // tcp v6 için ek baþlýk hesaplanýyor
    Ek6Baslik.KaynakIP6 := FIP6.FKaynakIPAdres;
    Ek6Baslik.HedefIP6 := FIP6.FHedefIPAdres;
    Ek6Baslik.Sifir[0] := 0;
    Ek6Baslik.Sifir[1] := 0;
    Ek6Baslik.Sifir[2] := 0;
    Ek6Baslik.Protokol := TUTANAK_TCP;
    Ek6Baslik.Uzunluk := htons(TSayi4(AVeriU + TCP_BASLIK_U));
  end
  else
  begin

    // tcp v4 için ek baþlýk hesaplanýyor
    Ek4Baslik.KaynakIP4Adres := FIP4.FKaynakIPAdres;
    Ek4Baslik.HedefIP4Adres := FIP4.FHedefIPAdres;
    Ek4Baslik.Sifir := 0;
    Ek4Baslik.Protokol := TUTANAK_TCP;
    Ek4Baslik.Uzunluk := htons(TSayi2(AVeriU + TCP_BASLIK_U));
  end;

  // tcp paketi hazýrlanýyor
  if(AVeriSonEk) then
    BaslikUzunlugu := (((20 + AVeriU) shr 2) shl 4)
  else BaslikUzunlugu := ((20 shr 2) shl 4);

  TCPPaket^.YerelPort := htons(TBaglanti(FBaglanti).FYerelPort);
  TCPPaket^.UzakPort := htons(TBaglanti(FBaglanti).FUzakPort);
  TCPPaket^.SiraNo := htons(FSiraNo);
  TCPPaket^.OnayNo := htons(FOnayNo);
  TCPPaket^.BaslikU := BaslikUzunlugu;     // üst 4 bit = BaslikUzunlugu * 4 = baþlýk uzunluðu;
  TCPPaket^.Bayrak := ABayrak;
  TCPPaket^.Pencere := htons(TSayi2(FPencereU));
  TCPPaket^.SaglamaToplami := 0;
  TCPPaket^.AcilIsaretci := 0;
  if(AVeriU > 0) then
  begin

    p := @TCPPaket^.Veri;
    Tasi2(PByte(AVeri), p, AVeriU);
  end;

  if(FIletisimTipi = itIP6) then
    SaglamaToplami := SaglamaToplamiOlustur(TCPPaket, TCP_BASLIK_U + AVeriU,
      @Ek6Baslik, TCP6_EKBASLIK_U)
  else
    SaglamaToplami := SaglamaToplamiOlustur(TCPPaket, TCP_BASLIK_U + AVeriU,
      @Ek4Baslik, TCP4_EKBASLIK_U);

  TCPPaket^.SaglamaToplami := SaglamaToplami;

  // hazýrlanan paketi ip katmanýna gönder
  if(FIletisimTipi = itIP6) then

    FIP6.PaketleVeGonder(ttTCP, $80, TCPPaket, TCP_BASLIK_U + AVeriU)

  else FIP4.PaketleVeGonder(ttTCP, $4000, TCPPaket, TCP_BASLIK_U + AVeriU);

  FreeMem(TCPPaket, TCP_BASLIK_U + AVeriU);
end;

{==============================================================================
  3. aþamalý el skýþmanýn 1. adýmý olan mesajý gönderir
 ==============================================================================}
procedure TTCP.BaglantiTalebiGonder;
begin

  // ilk sýra numarasý üret
  FSiraNo := GAgBaglantilari.AB.TCPIlkSiraNoAl;

  // onay numarasý ilk deðeri = 0
  FOnayNo := ntohs(TSayi4(0));

  PaketleVeGonder(TCP_BAYRAK_ARZ, @TCP4SYNSonEk, 12, True);

  // karþý bilgisayardan bir sonraki paketle gelemesi beklenen sýra numarasý
  Inc(FSiraNo);

  TBaglanti(FBaglanti).FBaglantiDurum := bdBaglaniyor;
end;

{==============================================================================
  3. aþamalý el skýþmanýn 2. adýmý olan mesajý gönderir
 ==============================================================================}
procedure TTCP.BaglantiTalebineOnayGonder(ATCPPaket: PTCPPaket);
begin

  // gelen sýra numarasý onay (ACK) için 1 artýrýlýyor
  FOnayNo := ntohs(ATCPPaket^.SiraNo);
  Inc(FOnayNo);

  FSiraNo := GAgBaglantilari.AB.TCPIlkSiraNoAl;

  PaketleVeGonder(TCP_BAYRAK_ARZ or TCP_BAYRAK_KABUL, @TCP4SYNSonEk, 12, True);

  // karþý bilgisayardan bir sonraki paketle gelemesi beklenen sýra numarasý
  Inc(FSiraNo);

  TBaglanti(FBaglanti).FBaglantiDurum := bdBaglantiBekleniyor;
end;

{==============================================================================
  3. aþamalý el skýþmanýn 3. adýmý olan son mesajý gönderir
 ==============================================================================}
procedure TTCP.BaglantiyiOnayla(ATCPPaket: PTCPPaket);
var
  i: TSayi4;
begin

  // sýra numarasýnýn onay numarasýyla teyidini yap (eþit olmalý)
  i := ntohs(ATCPPaket^.OnayNo);
  if(i = FSiraNo) then
  begin

    // onay numarasýný 1 artýr
    Inc(FOnayNo);

    PaketleVeGonder(TCP_BAYRAK_KABUL, nil, 0);

    // baðlantý sonrasý pencere deðeri
    FPencereU := 256;

    TBaglanti(FBaglanti).FBaglantiDurum := bdBaglantiKuruldu;
  end;
end;

{==============================================================================
  mevcut sýra ve "onay numarasýný" karþý bilgisayara gönderir
  bilgi: bu iþlev FOnayMesajiGonder ve FOnayZamanAsimi deðiþkenlerinin kontrolüyle
  çekirdek tarafýndan belli aralýkla karþý bilgisayara onay amacýyla tasarlanmýþtýr
  (henüz aktif deðildir)
 ==============================================================================}
procedure TTCP.SadeceOnayMesajiGonder;
begin

  PaketleVeGonder(TCP_BAYRAK_KABUL, nil, 0);
end;

{==============================================================================
  gelen onay numaralarýyla sýra numaralarýnýn karþýlaþtýrmalarýný ve kontrol
  edilmesini saðlar. veri trafik kontrolü burada gerçekleþir
 ==============================================================================}
procedure TTCP.OnayOlayiniIsle(ATCPPaket: PTCPPaket);
var
  i: TSayi4;
  B: TBaglanti;
begin

  B := TBaglanti(FBaglanti);

  // onay numarasý ile sýra numarasý eþleþiyor mu?
  // önemli bilgi: buradaki tcp mekanizmasýnda her sýra numarasý numarasý önceden
  // hesaplanýp ack deðeriyle gelen deðerle karþýlaþtýrýlmakta ve gerekli
  // kontroller gerçekleþtirilmektedir
  i := ntohs(ATCPPaket^.OnayNo);
  if(i = FSiraNo) then
  begin

    // bu aþamada istemci olarak karþý bilgisayara SYN gönderilmiþ
    // karþý bilgisayar ise SYN + ACK yanýtýný göndermiþtir
    // bu meajýn ACK kýsmý burada iþlenmekte, SYN kýsmý ise karþý bilgisayara
    // yanýt olarak ilgili yerde iþlenmektedir
    if(B.FBaglantiDurum = bdBaglaniyor) then
    begin

      // onay numarasý güncelleniyor (ilk onay numarasý)
      FOnayNo := ntohs(ATCPPaket^.SiraNo);
      Exit;
    end

    // karþý bilgisayardaki istemciden SYN mesajý alýnmýþ, yanýt olarak SYN + ACK
    // mesajý gönderilmiþ ve bu aþamada ACK yanýtý alýnmýþtýr
    else if(B.FBaglantiDurum = bdBaglantiBekleniyor) then
    begin

      B.FBaglantiDurum := bdBaglantiKuruldu;
      if not(B.FSunucu = nil) then B.FSunucu.OIstemciBaglandi(B);
      Exit;
    end;

    { TODO - aþaðýdaki pasif kodlar çekirdek çaðrýsýyla birlikte aktifleþtirilecek }
    //FOnayMesajiGonder := True;
    //FOnayZamanAsimi := GZamanlayicilar.FZamanlayiciSayaci + (300);

    // daha önce çekirdekte mevcut bir sunucudan veri gönderilmiþ ve
    // verinin gönderildiðine dair onay bekleniyorsa ilgili uygulamaya uyarý gönder
    if not(B.FSunucu = nil) and (B.FVeriOnayiBekleniyor) then
    begin

      B.FVeriOnayiBekleniyor := False;
      B.FSunucu.OVeriGonderildi(B);
    end;
  end;
end;

{==============================================================================
  ilgili porta (tcp üzerinden) gelen veriyi alýr
 ==============================================================================}
procedure TTCP.GelenVeriyiAl(ATCPPaket: PTCPPaket; AVeriUzunlugu: TSayi4);
var
  B: TBaglanti;
  i: TSayi4;
begin

  // gönderilen sýra numarasýyla kayýtlardaki onay numarasý ayný olmalý
  i := ntohs(ATCPPaket^.SiraNo);
  if(i = FOnayNo) then
  begin

    // eðer veri varsa
    if(AVeriUzunlugu > 0) then
    begin

      // sonraki gönderilecek paket için onay numarasý hazýrlýðý (paket alýnmýþ durumu)
      // önceden onay numarasý artýrýlarak kontroller bir sonraki paket üzerinden
      // gerçekleþtiriliyor (þu andaki mekanizma bu)
      FOnayNo := FOnayNo + AVeriUzunlugu;

      // veriyi istekte bulunan programa gönderilmek üzere kaydet
      B := TBaglanti(FBaglanti);
      B.BellegeEkle(@ATCPPaket^.Veri, AVeriUzunlugu);

      // çekirdekte mevcut dahili bir sunucu bu tcp baðlantýsýný kullanýyorsa
      // sunucuyu veri geldiðine dair bilgilendir
      if not(TBaglanti(FBaglanti).FSunucu = nil) then
        TBaglanti(FBaglanti).FSunucu.OVeriGeldi(FBaglanti);
    end;
  end;
end;

{==============================================================================
  karþý bilgisayardan gelen sonlandýrma mesajýný yanýtlar
 ==============================================================================}
procedure TTCP.SonlandirmayiYanitla;
begin

  // onay mesajý
  PaketleVeGonder(TCP_BAYRAK_KABUL, nil, 0);

  // onay numarasýný artýr
  Inc(FOnayNo);

  // bilgi: bu aþamada karþý bilgisayarýn kapatma isteði onaylanmýþtýr
  // bu aþamada karþý bilgisayara kapatma isteði gönderilerek ACK yanýtý beklenecektir
  PaketleVeGonder(TCP_BAYRAK_KABUL or TCP_BAYRAK_SON, nil, 0);

  // artýk karþý bilgisayardan gelecek son ACK mesajý beklenmektedir
  TBaglanti(FBaglanti).FBaglantiDurum := bdSonOnay;
end;

end.
