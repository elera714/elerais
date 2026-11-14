{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: baglanti.pas
  Dosya Ýþlevi: að baðlantýlarý ve ona baðlý baðlantý (soket) iletiþim
    yönetim iþlevlerini içerir

  Güncelleme Tarihi: 14/11/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit baglantilar;

interface

uses paylasim, sistemmesaj, ethernet, arp, ip6, ip4, icmp6, icmp4, sunucular,
  lldp_i, dhcpv6s, dhcpv4s, dhcpv4i, http, ftp, dnsi, netbios, tcp, udp;

const
  // 0800ABCDEF01 MAC adresi Modified EUI-64'e göre kodlanarak ipv6 adresi elde edilmiþtir
  // bilgi: MAC adresinin ilk byte'ýnýn (08) saðdan 2. biti standarta göre xor'lanmýþtýr
  // http://[fe80::a00:abff:fecd:ef01]/
  SabitIP6Adresim: TIP6Adres = ($FE, $80, $00, $00, $00, $00, $00, $00,
    $0A, $00, $AB, $FF, $FE, $CD, $EF, $01);

type
  TBaglantiNesnesi = (bnDHCPv6s, bnDHCPv4s, bnDHCPv4i, bnHTTPs, bnHTTPi,
    bnFTPs, bnFTPi, bnDNSi, bnNetBios, bnTCP, bnUDP);

const
  USTSINIR_AB_SAYISI  = 16;     // Að Baðlantý sayýsý
  USTSINIR_B_SAYISI   = 32;     // Baðlantý sayýsý

  TCP_PENCERE_UZUNLUK = 8192;

  // tcp / udp için üretilecek yerel port numarasý
  ILK_YERELPORTNO     = $A00E;

  TCP_BAYRAK_SON      = $01;    // FIN
  TCP_BAYRAK_ARZ      = $02;    // SYN
  TCP_BAYRAK_SIFIRLA  = $04;    // RST
  TCP_BAYRAK_GONDER   = $08;    // PSH
  TCP_BAYRAK_KABUL    = $10;    // ACK

type
  TBaglanti = class;

type
  // tüm að baðlantýlarýnýn atasý olan nesne
  PTemelAgBaglantisi = ^TTemelAgBaglantisi;
  TTemelAgBaglantisi = class
  public
    // að baðlantýsý kimliði = ayný zamanda baðlantý sýra numarasý
    FKimlik: TKimlik;
    FBaglantiAdi: string;
    constructor Create; virtual;
  end;

type
  // sistemde mevcut her bir að aygýtý veya sanal baðlantý bu nesne
  // tarafýndan yönetilir. TAgBaglantilari nesnesinin alt nesnesidir
  PAgBaglantisi = ^TAgBaglantisi;
  TAgBaglantisi = class(TTemelAgBaglantisi)
  private
    // að baðlantýsý içinde oluþturulan toplam baðlantý sayýsý
    FBaglantiSayisi,
    // tcp için üretilen ilk sýra numarasý
    FTCPIlkSiraNo,
    // tcp / udp için üretilecek yerel port numarasý
    FYerelPortNo: TSayi4;
    // að baðlantýsýnýn að kimlik deðerleri ->
    // bilgi: bu deðerler ag.pas biriminde iþlenmektedir
    FIP6Adresim: TIP6Adres;
    FIP4Adresim, FAltAgMaskesi, FAgGecitAdresi,
    FDHCPSunucusu, FDNSSunucusu: TIP4Adres;
    FIPKiraSuresi: TSayi4;          // saniye cinsinden
    FIP6AdresiAlindi,
    FIP4AdresiAlindi: Boolean;
    // <- að baðlantýsýnýn að kimlik deðerleri
    // að baðlantýsýnýn aktif / pasif olma durumu
    FAktif: Boolean;
    FBaglantilar: array[0..USTSINIR_B_SAYISI - 1] of TBaglanti;
    function Al(ASiraNo: TISayi4): TBaglanti;
    procedure Yaz(ASiraNo: TISayi4; ABaglanti: TBaglanti);
  public
    // að baðlantýsýnýn kullanacaðý ethernet aygýtý
    FEthernet: TEthernet;
    // að baðlantýsý tarafýndan direkt olarak kullanýlacak tutanaklar
    // bilgi: bu tutanaklar tüm nesne ve iþlevlere açýk tutanaklardýr
    FARP: TARP;
    FICMP6: TICMP6;
    FICMP4: TICMP4;
    FLLDP: TLLDP;
    // að - gelen paket sayýlarý
    FICMPv6PaketSayisi,
    FICMPv4PaketSayisi,
    FTCP6PaketSayisi,
    FTCP4PaketSayisi,
    FUDP6PaketSayisi,
    FUDP4PaketSayisi,
    FGAEPaketSayisi: TSayi4;     // GözArdýEdilen paket sayýsý
    constructor Create; override;
    procedure VerileriIsle;
    function BKimlikNoAl: TISayi4;
    function BaglantiOlustur(ABaglantiNesnesi: TBaglantiNesnesi;
      AIletisimTipi: TIletisimTipi; ABaglantiTuru: TBaglantiTuru;
      ATutanakTipi: TTutanakTipi; AYerelPort, AUzakPort: TSayi2): TBaglanti;
    procedure BaglantiyiYoket(ABaglanti: TBaglanti);
    function BaglantiBul(ATutanakTipi: TTutanakTipi;
      AYerelPort, AUzakPort: TSayi2): TObject;
    function TCPIlkSiraNoAl: TSayi4;
    function YerelPortOlustur: TSayi4;
    procedure OnayMesajlariniGonder;
    procedure Listele;
    property Baglanti[ASiraNo: TISayi4]: TBaglanti read Al write Yaz;
    property BaglantiSayisi: TSayi4 read FBaglantiSayisi write FBaglantiSayisi;
    property Aktif: Boolean read FAktif write FAktif;
    property IP6Adresim: TIP6Adres read FIP6Adresim write FIP6Adresim;
    property IP4Adresim: TIP4Adres read FIP4Adresim write FIP4Adresim;
    property AltAgMaskesi: TIP4Adres read FAltAgMaskesi write FAltAgMaskesi;
    property AgGecitAdresi: TIP4Adres read FAgGecitAdresi write FAgGecitAdresi;
    property DHCPSunucusu: TIP4Adres read FDHCPSunucusu write FDHCPSunucusu;
    property DNSSunucusu: TIP4Adres read FDNSSunucusu write FDNSSunucusu;
    property IPKiraSuresi: TSayi4 read FIPKiraSuresi write FIPKiraSuresi;
    property IP6AdresiAlindi: Boolean read FIP6AdresiAlindi write FIP6AdresiAlindi;
    property IP4AdresiAlindi: Boolean read FIP4AdresiAlindi write FIP4AdresiAlindi;
  end;

type
  // sistemde her bir að aygýtý için oluþturulmuþ veya sanal baðlantýlarýn
  // tümünü içerir. nesne tüm bu aygýtlarý TAgBaglantisi üzerinden yönetir
  PAgBaglantilari = ^TAgBaglantilari;
  TAgBaglantilari = class
  private
    FAktifBaglanti: TAgBaglantisi;      // aktif baðlantý
    FAgBaglantiSayisi: TSayi4;
    FBaglantilar: array[0..USTSINIR_AB_SAYISI - 1] of TAgBaglantisi;
    function Al(ASiraNo: TISayi4): TAgBaglantisi;
    procedure Yaz(ASiraNo: TISayi4; ABaglanti: TAgBaglantisi);
  public
    constructor Create;
    procedure AgBaglantilariniOlustur;
    function ABKimlikNoAl: TISayi4;
    property AgBaglantisi[ASiraNo: TISayi4]: TAgBaglantisi read Al write Yaz;
    property AgBaglantiSayisi: TSayi4 read FAgBaglantiSayisi write FAgBaglantiSayisi;
    property AB: TAgBaglantisi read FAktifBaglanti write FAktifBaglanti;
  end;

type
  // TAgBaglantisi üzerinde oluþturulan yazýlýmsal her bir baðlanyýtý içerir
  // yazýlýmsal tüm iletiþimler bu nesne üzerinden yönetilir (tcp / ip, icmp, arp vb)
  PBaglanti = ^TBaglanti;
  TBaglanti = class
  public
    FKimlik: TKimlik;                     // baðlantý kimliði
    // tutanak tipi (protokol)
    // að baðlantýsý tarafýndan atamasý yapýlýyor
    FTutanakTipi: TTutanakTipi;
    FBaglantiNesnesi: TBaglantiNesnesi;   // baðlantýnýn kullanacaðý dahili nesne
    FIletisimTipi: TIletisimTipi;         // ana tutanak iletiþim tipleri (ipv4, ipv6)
    FBaglantiTuru: TBaglantiTuru;         // pasif / aktif baðlantý
    FAB: TAgBaglantisi;                   // baðlantýnýn baðlý olduðu Að Baðlantýsý
    FYerelPort, FUzakPort: TSayi2;        // baðlantýnýn kullandýðý yerel ve uzak port numaralarý
    // çekirdek içinde çalýþan sunucu / istemci nesneleri ve tutanaklar
    FDHCPv6s: TDHCPv6s;
    FDHCPv4s: TDHCPv4s;
    FDHCPv4i: TDHCPv4i;
    // FSunucu = http sunucusu veya ftp sunucusu
    // her sunucu için bir adet tcp baðlantýsý (þu anda)
    FSunucu: TTCPSunucu;
    FTCP: TTCP;
    FUDP: TUDP;
    FDNSi: TDNSi;
    FNetBios: TNetBios;
    FBellek: Isaretci;                    // tcp ve udp tutanaklarý için bellek
    FVeriUzunlugu: TSayi4;                // FBellek'te depolanmýþ mevcut veri uzunluðu
    FBaglantiDurum: TBaglantiDurum;
    // bu sistemden karþý sisteme veri gönderildiði anda onay bekleniyor durumu aktifleþtirilir
    // karþý sistemden ilk ACK bayraðýnýn gelmesiyle birlikte veriyi gönderen ilgili iþleve
    // FSunucu (http, ftp sunucusuna) verinin karþý sisteme gönderildiði onay mesajý iletilir
    FVeriOnayiBekleniyor: Boolean;
  public
    constructor Create(ABaglantiNesnesi: TBaglantiNesnesi;
      AIletisimTipi: TIletisimTipi; ABaglantiTuru: TBaglantiTuru;
      AAgBaglantisi: TAgBaglantisi; AYerelPort, AUzakPort: TSayi2);
    destructor Destroy; override;
    procedure Baglan;
    function BagliMi: Boolean;
    function Oku(ABellek: Isaretci): TSayi4;
    procedure Yaz(ABellek: Isaretci; AUzunluk: TISayi4);
    function VeriUzunlugunuAl: TSayi4;
    procedure BellegeEkle(AKaynakBellek: Isaretci; AVeriUzunlugu: TSayi4);
    procedure BaglantiyiKapat;
  end;

var
  GAgBaglantilari: TAgBaglantilari;
  BaglantilarKilit: TSayi4 = 0;

implementation

uses islevler, donusum, aygityonetimi, zamanlayici;

{==============================================================================
  temel að baðlantý nesnesi ana yükleme iþlevlerini içerir
 ==============================================================================}
constructor TTemelAgBaglantisi.Create;
begin

  // að baðlantýsý için kimlik numarasý al
  FKimlik := GAgBaglantilari.ABKimlikNoAl;

  // að baðlantý adý
  FBaglantiAdi := 'Að Baðlantýsý-' + IntToStr(FKimlik);
end;

{==============================================================================
  að baðlantý nesnesi ana yükleme iþlevlerini içerir
 ==============================================================================}
constructor TAgBaglantisi.Create;
var
  i: TSayi4;
begin

  // ata nesne ana yükleme iþlevini çalýþtýr
  inherited Create;

  // að baðlantýsý üzerinden iletiþim amaçlý (tcp, udp) oluþturulan baðlantý sayýsý
  FBaglantiSayisi := 0;

  // baðlantý yapýlarýný ilk deðerlerle yükle
  for i := 0 to USTSINIR_B_SAYISI - 1 do Baglanti[i] := nil;

  // tcp için üretilen ilk sýra numarasý
  FTCPIlkSiraNo := $10001000;

  // tcp / udp için üretilecek yerel port numarasý
  FYerelPortNo := ILK_YERELPORTNO;

  FARP := TARP.Create(Self);
  FICMP6 := TICMP6.Create(Self);
  FICMP4 := TICMP4.Create(Self);
  FLLDP := TLLDP.Create(Self);

  // veri sayaç deðiþkenleri
  FICMPv6PaketSayisi := 0;
  FICMPv4PaketSayisi := 0;
  FTCP6PaketSayisi := 0;
  FTCP4PaketSayisi := 0;
  FUDP6PaketSayisi := 0;
  FUDP4PaketSayisi := 0;
  FGAEPaketSayisi := 0;

  // að baðlantýsýný aktif olarak iþaretle
  FAktif := True;
end;

function TAgBaglantisi.Al(ASiraNo: TISayi4): TBaglanti;
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_B_SAYISI) then
    Result := FBaglantilar[ASiraNo]
  else Result := nil;
end;

procedure TAgBaglantisi.Yaz(ASiraNo: TISayi4; ABaglanti: TBaglanti);
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_B_SAYISI) then
    FBaglantilar[ASiraNo] := ABaglanti;
end;

{==============================================================================
  að katmanýna (ethernet) gelen verileri iþler
 ==============================================================================}
procedure TAgBaglantisi.VerileriIsle;
var
  EthPaket: PEthernetPaket;
  ARPPaket: PARPPaket;
  Bellek: array[0..$FFF] of TSayi1;
  i: TSayi4;
  Tutanak: TSayi2;
begin

  // að baðlantý mevcut ve aktif ise ...
  if not(GAgBaglantilari.AB = nil) and (GAgBaglantilari.AB.Aktif) then
  begin

    // að kartýna gelen ham veriyi al
    i := FEthernet.Al(@Bellek);
    if(i > 0) then
    begin

      EthPaket := @Bellek[0];

      {SISTEM_MESAJ(mtBilgi, RENK_PEMBE, 'Ethernet Katmaný.............:', []);
      SISTEM_MESAJ_MAC(mtBilgi, RENK_TURKUAZ, '  - KaynakMACAdres: ', EthPaket^.KaynakMACAdres);
      SISTEM_MESAJ_MAC(mtBilgi, RENK_TURKUAZ, '  - HedefMACAdres: ', EthPaket^.HedefMACAdres);
      SISTEM_MESAJ(mtBilgi, RENK_MAVI, '  - PaketTipi: $%.4x', [EthPaket^.PaketTipi]);}

      Tutanak := htons(EthPaket^.PaketTipi);

      // ******* tutanaklarýn iþlenmesi *******

      // arp tutanaðý
      if(Tutanak = TUTANAK_ARP) then
      begin

        ARPPaket := @EthPaket^.Veri;
        if(IP4Karsilastir(ARPPaket^.HedefIP4Adres, IP4Adresim)) then
          FARP.VerileriIsle(EthPaket);
      end

      // ip v6 tutanaðý
      else if(Tutanak = TUTANAK_IP6) then

        IP6VerileriniIsle(EthPaket)

      // ip v4 tutanaðý
      else if(Tutanak = TUTANAK_IP4) then

        IP4VerileriniIsle(EthPaket)

      // lldp tutanaðý
      else if(Tutanak = TUTANAK_LLDP) then

        FLLDP.VerileriIsle(EthPaket)

      else
      begin

        // bilinmeyen protokol
        SISTEM_MESAJ(mtUyari, RENK_PEMBE, 'BAGLANTILAR.PAS: bilinmeyen tutanak: $%.4x', [Tutanak]);
        SISTEM_MESAJ_MAC(mtUyari, RENK_TURKUAZ, '  - Kaynak MAC Adresi: ', EthPaket^.KaynakMACAdres);
        SISTEM_MESAJ_MAC(mtUyari, RENK_TURKUAZ, '  - Hedef MAC Adresi: ', EthPaket^.HedefMACAdres);
      end;
    end;
  end;
end;

{==============================================================================
  baðlantý için kimlik numarasý oluþturur
 ==============================================================================}
function TAgBaglantisi.BKimlikNoAl: TISayi4;
var
  B: TBaglanti;
  i: TISayi4;
begin

  Result := -1;

  // tüm baðlantýlarý kontrol et
  for i := 0 to USTSINIR_B_SAYISI - 1 do
  begin

    // kullanýlmayan baðlantý varsa sýra numarasýný geri döndür
    B := Baglanti[i];
    if(B = nil) then Exit(i);
  end;
end;

{==============================================================================
  að baðlantýsý için iletiþim baðlantýsý oluþturur
 ==============================================================================}
function TAgBaglantisi.BaglantiOlustur(ABaglantiNesnesi: TBaglantiNesnesi;
  AIletisimTipi: TIletisimTipi; ABaglantiTuru: TBaglantiTuru; ATutanakTipi:
  TTutanakTipi; AYerelPort, AUzakPort: TSayi2): TBaglanti;
var
  B: TBaglanti;
begin

//  while KritikBolgeyeGir(BaglantilarKilit) = False do;

  // iletiþim baðlantýsý oluþtur
  B := TBaglanti.Create(ABaglantiNesnesi, AIletisimTipi, ABaglantiTuru, Self,
    AYerelPort, AUzakPort);

  // baðlantý oluþturma hatasý varsa çýk
  if(B = nil) then Exit(nil);

  // baðlantýyý dizi içerisine kaydet
  Baglanti[B.FKimlik] := B;

  // diðer baðlantý nesne deðiþken atamalarýný gerçekleþtir
  B.FTutanakTipi := ATutanakTipi;

  // baðlantý sayýsýný artýr
  Inc(FBaglantiSayisi);

  Result := B;

//  KritikBolgedenCik(BaglantilarKilit);
end;

{==============================================================================
  að baðlantýsý içerisinde oluþturulan iletiþim baðlantýsýný yok eder
 ==============================================================================}
procedure TAgBaglantisi.BaglantiyiYoket(ABaglanti: TBaglanti);
begin

  Baglanti[ABaglanti.FKimlik] := nil;

  ABaglanti.Destroy;

  Dec(FBaglantiSayisi);
end;

{==============================================================================
  að baðlantýsý içerisinde iletiþim baðlantýsýný bulur
 ==============================================================================}
function TAgBaglantisi.BaglantiBul(ATutanakTipi: TTutanakTipi;
  AYerelPort, AUzakPort: TSayi2): TObject;
var
  B: TBaglanti;
  i: TSayi4;
begin

  Result := nil;

  if(BaglantiSayisi > 0) then
  begin

    // tüm iletiþim baðlantýlarýný ara
    for i := 0 to USTSINIR_B_SAYISI - 1 do
    begin

      B := Baglanti[i];

      // baðlantý tanýmlý deðilse bir sonrakine geç
      if(B = nil) then Continue;

      {if(B.FTutanakTipi = ttUDP) then
        SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'ttUDP', [])
      else SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'ttTCP', []);
      SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'YP: %d', [B.FYerelPort]);
      SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'UP: %d', [B.FUzakPort]);}

      // tutanak tiplerine ve baðlantý türlerine göre arama yap
      if(B.FTutanakTipi = ATutanakTipi) then
      begin

        if(ATutanakTipi = ttTCP) then
        begin

          if(B.FBaglantiTuru = btYAktif) or (B.FBaglantiTuru = btUAktif) then
          begin

            if(B.FYerelPort = AUzakPort) and
              (B.FUzakPort = AYerelPort) then Exit(B);
          end
          else
          begin

            if(B.FYerelPort = AYerelPort) and
              (B.FUzakPort = AUzakPort) then Exit(B);
          end;
        end
        else if(ATutanakTipi = ttUDP) then
        begin

          if(B.FBaglantiTuru = btYAktif) or (B.FBaglantiTuru = btUAktif) then
          begin

            if(B.FYerelPort = AUzakPort) and
              (B.FUzakPort = AYerelPort) then Exit(B);
          end
          else
          begin

            if(B.FYerelPort = AUzakPort) and
              (B.FUzakPort = AYerelPort) then Exit(B);
          end;
        end;
      end;
    end;
  end;
end;

{==============================================================================
  tcp veri alýþveriþinin takibi için gerekli ilk sýra numarasýný alýr
 ==============================================================================}
function TAgBaglantisi.TCPIlkSiraNoAl: TSayi4;
begin

  Result := FTCPIlkSiraNo;
  Inc(FTCPIlkSiraNo, 10);
end;

{==============================================================================
  uzak baðlantý (istemci) için yerel port numarasý üretir
 ==============================================================================}
function TAgBaglantisi.YerelPortOlustur: TSayi4;
begin

  Inc(FYerelPortNo);
  if(FYerelPortNo > $FDE8 {65000}) then FYerelPortNo := ILK_YERELPORTNO;
  Result := FYerelPortNo;
end;

{==============================================================================
  tcp için gönderilmesi gereken ve zamaný gelmiþ onay mesajlarýný gönderir
  bilgi: çekirdek tarafýndan kullanýlacak (henüz aktifleþtirilmedi)
 ==============================================================================}
procedure TAgBaglantisi.OnayMesajlariniGonder;
var
  B: TBaglanti;
  i, j: TSayi4;
begin

  // mevcut baðlantý var mý?
  if(BaglantiSayisi > 0) then
  begin

    // zamanlayýcý deðerini al
    j := GZamanlayicilar.FZamanlayiciSayaci;

    // tüm baðlantýlarý kontrol et
    for i := 0 to USTSINIR_B_SAYISI - 1 do
    begin

      // baðlantý nesnesi oluþturulmamýþsa sir sonrakine geç
      B := Baglanti[i];
      if(B = nil) then Continue;

      // baðlantý için tcp tutanaðý oluþturulmuþ mu?
      if not(B.FTCP = nil) then
      begin

        // onay mesaj bayraðý aktif mi?
        if(B.FTCP.FOnayMesajiGonder) then
        begin

          // mesajýn gönderilme süresi gelmi mi?
          if(B.FTCP.FOnayZamanAsimi < j) then
          begin

            // mesaj gönderme bayraðýný pasifleþtir ve onay mesajýný gönder
            B.FTCP.FOnayMesajiGonder := False;
            B.FTCP.SadeceOnayMesajiGonder;
          end;
        end;
      end;
    end;
  end;
end;

{==============================================================================
  að baðlantýsý içerisindeki tüm iletiþim baðlantýlarýný listeler
 ==============================================================================}
procedure TAgBaglantisi.Listele;
var
  B: TBaglanti;
  i: TSayi4;
begin

  if(BaglantiSayisi > 0) then
  begin

    for i := 0 to USTSINIR_B_SAYISI - 1 do
    begin

      B := Baglanti[i];
      if(B = nil) then Continue;

      if(B.FTutanakTipi = ttUDP) then
        SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'ttUDP', [])
      else SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'ttTCP', []);

      SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'YP: %d', [B.FYerelPort]);
      SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'UP: %d', [B.FUzakPort]);
    end;
  end;
end;

{==============================================================================
  að baðlantýlarý nesnesi ana yükleme iþlevlerini içerir
 ==============================================================================}
constructor TAgBaglantilari.Create;
var
  i: TSayi4;
begin

  // að baðlantý sayýsýný sýfýrla
  FAgBaglantiSayisi := 0;

  // baðlantý yapýlarýný ilk deðerlerle yükle
  for i := 0 to USTSINIR_AB_SAYISI - 1 do AgBaglantisi[i] := nil;

  // aktif baðlantý = yok
  FAktifBaglanti := nil;
end;

function TAgBaglantilari.Al(ASiraNo: TISayi4): TAgBaglantisi;
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_AB_SAYISI) then
    Result := FBaglantilar[ASiraNo]
  else Result := nil;
end;

procedure TAgBaglantilari.Yaz(ASiraNo: TISayi4; ABaglanti: TAgBaglantisi);
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_AB_SAYISI) then
    FBaglantilar[ASiraNo] := ABaglanti;
end;

{==============================================================================
  sistemde mevcut her bir að aygýtý için að baðlantýsý oluþturur
 ==============================================================================}
procedure TAgBaglantilari.AgBaglantilariniOlustur;
var
  B: TAgBaglantisi;
  i: TSayi4;
begin

  // sistemde að aygýtý yoksa çýk
  if(GAygitlar.ToplamAgAygitSayisi = 0) then Exit;

  // her bir að aygýtý için að baðlantýsý oluþtur
  for i := 0 to GAygitlar.ToplamAgAygitSayisi - 1 do
  begin

    B := TAgBaglantisi.Create;

    // að baðlantýsý için að aygýtýný ata
    B.FEthernet := TEthernet(GAygitlar.AgAygitListesi[i]);

    // að baðlantýsýný listeye kaydet
    AgBaglantisi[B.FKimlik] := B;

    // aktif baðlantýyý belirle
    if(FAktifBaglanti = nil) then FAktifBaglanti := B;

    Inc(FAgBaglantiSayisi);
  end;
end;

{==============================================================================
  að baðlantýsý için baðlantý kimlik numarasý oluþturur
 ==============================================================================}
function TAgBaglantilari.ABKimlikNoAl: TISayi4;
var
  B: TAgBaglantisi;
  i: TISayi4;
begin

  Result := -1;

  // tüm að baðlantýlarýný kontrol et
  for i := 0 to USTSINIR_AB_SAYISI - 1 do
  begin

    // kullanýlmayan baðlantý varsa sýra numarasýný geri döndür
    B := AgBaglantisi[i];
    if(B = nil) then Exit(i);
  end;
end;

{==============================================================================
  baðlantý nesnesi ana yükleme iþlevlerini içerir
 ==============================================================================}
constructor TBaglanti.Create(ABaglantiNesnesi: TBaglantiNesnesi;
  AIletisimTipi: TIletisimTipi; ABaglantiTuru: TBaglantiTuru;
  AAgBaglantisi: TAgBaglantisi; AYerelPort, AUzakPort: TSayi2);
begin

  // baðlantý için kimlik al
  FKimlik := AAgBaglantisi.BKimlikNoAl;

  // deðer atamalarý
  FBaglantiNesnesi := ABaglantiNesnesi;
  FIletisimTipi := AIletisimTipi;
  FBaglantiTuru := ABaglantiTuru;

  // baðlantýnýn baðlý olduðu að baðlantýsý
  FAB := AAgBaglantisi;

  // baðlantý türüne göre port deðer atamalarý
  if(ABaglantiTuru = btUAktif) then
  begin
    FYerelPort := AUzakPort;
    FUzakPort := AYerelPort; end
  else
  begin
    FYerelPort := AYerelPort;
    FUzakPort := AUzakPort;
  end;

  // baðlantý nesnesinin deðerine göre ilgili alt nesneleri oluþtur
  // bilgi: buraya eklenen her bir nesne destroy kýsmýna eklenerek yok edilmelidir
  case FBaglantiNesnesi of
    bnDHCPv6s : FDHCPv6s := TDHCPv6s.Create(Self);
    bnDHCPv4s : FDHCPv4s := TDHCPv4s.Create(Self);
    bnDHCPv4i : FDHCPv4i := TDHCPv4i.Create(Self);
    bnHTTPs   :
    begin
      FSunucu := THTTPSunucu.Create(Self);
      FTCP := TTCP.Create(Self, FIletisimTipi, MACAdres0);
    end;
    bnFTPs    :
    begin
      FSunucu := TFTPSunucu.Create(Self);
      FTCP := TTCP.Create(Self, FIletisimTipi, MACAdres0);
    end;
    bnTCP     : FTCP := TTCP.Create(Self, FIletisimTipi, MACAdres0);
    bnUDP     : FUDP := TUDP.Create(Self, FIletisimTipi, MACAdres0);
    bnDNSi    : FDNSi := TDNSi.Create(Self);
    bnNetBios : FNetBios := TNetBios.Create(Self);
  end;

  // tcp ve udp tutanaklarý için bellek ayýr
  FBellek := GetMem(4 * 4096); //Bag^.FPencereU);
  if(FBellek = nil) then SISTEM_MESAJ(mtHata, RENK_KIRMIZI, 'BAGLANTI.PAS: Bellek yok', []);

  // FBellek'te depolanan veri uzunluðu
  FVeriUzunlugu := 0;

  // baðlantý durumu
  FBaglantiDurum := bdKapali;

  // bu sistemden karþý sisteme gönderilen verinin onaylandýðý bilgisi (ACK)
  FVeriOnayiBekleniyor := False;
end;

{==============================================================================
  baðlantý nesnesi ana yok etme iþlevlerini içerir
 ==============================================================================}
destructor TBaglanti.Destroy;
begin

  // baðlantý durumu
  FBaglantiDurum := bdKapali;

  case FBaglantiNesnesi of
    bnDHCPv6s : FDHCPv6s.Destroy;
    bnDHCPv4s : FDHCPv4s.Destroy;
    bnDHCPv4i : FDHCPv4i.Destroy;
    bnHTTPs   : begin FSunucu.Destroy; FTCP.Destroy; end;
    bnFTPs    : begin FSunucu.Destroy; FTCP.Destroy; end;
    bnTCP     : FTCP.Destroy;
    bnUDP     : FUDP.Destroy;
    bnDNSi    : FDNSi.Destroy;
    bnNetBios : FNetBios.Destroy;
  end;

  // ayrýlmýþ bellek varsa yok et
  if not(FBellek = nil) then FreeMem(FBellek, 4 * 4096);

  // nesnenin kendisini (bu nesneyi) yok et
  inherited Destroy;
end;

{==============================================================================
  oluþturulan baðlantý üzerinden uzaktaki sisteme baðlantý kurar
 ==============================================================================}
procedure TBaglanti.Baglan;
var
  HedefMACAdres: TMACAdres;
  HedefIPAdres: TIP4Adres;
begin

  // baðlantý durumuna göre ip adresini al
  if(FBaglantiNesnesi = bnTCP) then
    HedefIPAdres := FTCP.FIP4.FHedefIPAdres
  else if(FBaglantiNesnesi = bnUDP) then
    HedefIPAdres := FUDP.FIP4.FHedefIPAdres;

  // ip adresinin mac adres karþýlýðýný al
  { TODO - ip v6'ya göre düzenlenecek }
  if(IP4AdresiAyniAgdaMi(HedefIPAdres)) then
    HedefMACAdres := GAgBaglantilari.AB.FARP.MACAdresAl(HedefIPAdres)
  else HedefMACAdres := GAgBaglantilari.AB.FARP.MACAdresAl(GAgBaglantilari.AB.DNSSunucusu);

  // mac adres alýnamadýysa çýk
  if(MACKarsilastir(HedefMACAdres, MACAdres0)) then Exit;

  // tcp baðlantý iþlemleri
  if(FBaglantiNesnesi = bnTCP) then
  begin

    if(FBaglantiDurum = bdKapali) then
    begin

      // üç yollu el sýkýþma iþlemini baþlat
      FTCP.FIP4.FHedefMACAdres := HedefMACAdres;

      // SYN
      FTCP.BaglantiTalebiGonder;

      FBaglantiDurum := bdBaglaniyor;
    end;
  end
  // udp baðlantý iþlemleri
  else if(FBaglantiNesnesi = bnUDP) then
  begin

    if(FBaglantiDurum = bdKapali) then
    begin

      FUDP.FIP4.FHedefMACAdres := HedefMACAdres;

      FBaglantiDurum := bdBaglantiKuruldu;
    end;
  end;
end;

{==============================================================================
  baðlantýnýn var olup olmadýðýný kontrol eder
 ==============================================================================}
function TBaglanti.BagliMi: Boolean;
begin

  if(FBaglantiDurum = bdBaglantiKuruldu) then
    Result := True
  else Result := False;
end;

{==============================================================================
  baðlantý üzerinden gelen veriyi ilgili programa yönlendirir
 ==============================================================================}
function TBaglanti.Oku(ABellek: Isaretci): TSayi4;
begin

  if(FBaglantiDurum = bdBaglantiKuruldu) then
  begin

    if(FVeriUzunlugu > 0) then
    begin

      Tasi2(FBellek, ABellek, FVeriUzunlugu);
      Result := FVeriUzunlugu;
      FVeriUzunlugu := 0;
      Exit;
    end;
  end;

  Result := 0;
end;

{==============================================================================
  baðlantý kurulan bilgisayara veri gönderir
 ==============================================================================}
procedure TBaglanti.Yaz(ABellek: Isaretci; AUzunluk: TISayi4);
begin

  if(FBaglantiDurum = bdBaglantiKuruldu) then
  begin

    if not(FTCP = nil)  then
    begin

      // veriyi karþý bilgisayara gönder
      FTCP.PaketleVeGonder(TCP_BAYRAK_GONDER or TCP_BAYRAK_KABUL, ABellek, AUzunluk);

      // karþý bilgisayardan gelmesi beklenen bir sonraki onay numarasýný (ACK - sýra no) belirle
      FTCP.FSiraNo := FTCP.FSiraNo + AUzunluk;

      // bu verinin karþý bilgisayara gittiðine dair onay bekle
      // bilgi: gelen ilk ACK bu verinin gittiðinin de onayýdýr
      FVeriOnayiBekleniyor := True;
    end
    else
    begin

      // veriyi sadece gönder
      FUDP.PaketleVeGonder(ABellek, AUzunluk);
    end;
  end;
end;

{==============================================================================
  baðlantý üzerinden gelerek uygulamaya iletilecek veri miktarýný döndürür
 ==============================================================================}
function TBaglanti.VeriUzunlugunuAl: TSayi4;
begin

  Result := FVeriUzunlugu;
end;

{==============================================================================
  baðlantý kurulan bilgisayardan gelen verileri programýn kullanmasý için belleðe kaydeder
 ==============================================================================}
procedure TBaglanti.BellegeEkle(AKaynakBellek: Isaretci; AVeriUzunlugu: TSayi4);
var
  p: PChar;
begin

  // veri yoksa çýk
  if(AVeriUzunlugu = 0) then Exit;

  // 4K'nýn üzerinde veriye izin verme
  { TODO - karþý bilgisayardan gelecek tüm veriyi alabilecek esneklikle tasarlanacak }
  if(AVeriUzunlugu + FVeriUzunlugu < (4 * 4096)) then
  begin

    // veriyi kaydet ve veri uzunluðunu güncelle
    p := FBellek + FVeriUzunlugu;

    Tasi2(AKaynakBellek, p, AVeriUzunlugu);
    FVeriUzunlugu := FVeriUzunlugu + AVeriUzunlugu;
  end;
end;

{==============================================================================
  aktif baðlantýyý kapatýr
 ==============================================================================}
procedure TBaglanti.BaglantiyiKapat;
begin

  FBaglantiDurum := bdKapanmayiBekliyor;

  FTCP.PaketleVeGonder(TCP_BAYRAK_SON or TCP_BAYRAK_KABUL, nil, 0);

  // karþý bilgisayardan bir sonraki paketle gelmesi beklenen sýra numarasý
  Inc(FTCP.FSiraNo);

  FBaglantiDurum := bdKapanisBekleniyor1;
end;

end.
