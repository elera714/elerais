{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: baglanti.pas
  Dosya Ýþlevi: baðlantý (soket) iletiþim yönetim iþlevlerini içerir

  Güncelleme Tarihi: 24/06/2026

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit baglantilar;

interface

uses paylasim, sistemmesaj, ethernet, arp, ip6, ip4, icmp4, lldp_i;

const
  USTSINIR_AB_SAYISI  = 16;     // Að Baðlantý sayýsý
  USTSINIR_B_SAYISI   = 32;     // Baðlantý sayýsý

  TCP_PENCERE_UZUNLUK = 8192;
  ILK_YERELPORTNO     = $A00E;

  TCP_BAYRAK_SON      = $01;    // FIN
  TCP_BAYRAK_ARZ      = $02;    // SYN
  TCP_BAYRAK_SIFIRLA  = $04;    // RST
  TCP_BAYRAK_GONDER   = $08;    // PSH
  TCP_BAYRAK_KABUL    = $10;    // ACK

var
  YerelPortNo: TSayi2;
  TCPIlkSiraNo: TSayi4;

type
{
    bdYok = tcp/udp veri alanlarýnýn ilk yükleme ve tcp/bdKapaniyor2 (? teyit et) sonrasý aþamasý
    bdKapali = tcp/udp yeni baðlantý oluþturma ve udp/baðlantý kapatma sonrasý aþamasý
}

  { TODO - açýklama yapýlmayan durumlar yeniden gözden geçirilecek }
  TBaglantiDurum = (
    bdYok,
    bdKapali,
    bdBaglaniyor,

    // bdBaglantiBekleniyor (sunucu durumu - SYN-RECEIVED):
    // istemciden SYN mesajý alýnmýþ, istemciye SYN + ACK mesajý gönderilmiþtir
    bdBaglantiBekleniyor,
    // bdBaglantiKuruldu (sunucu / istemci durumu - ESTABLISHED)
    // sunucu istemci arasýndaki 3 yollu (SYN -> SYN + ACK -> ACK) anlaþma saðlanmýþtýr
    bdBaglantiKuruldu,
    // bdKapanmayiBekliyor (sunucu / istemci durumu - CLOSE-WAIT)
    // baðlantýnýn 1. ucundaki istemci / sunucudan kapatma isteðinin gelmesi durumu (FIN + ACK)
    bdKapanmayiBekliyor,
    // bdSonOnay (sunucu / istemci durumu - LAST-ACK)
    // baðlantýnýn 2. ucundaki istemci / sunucunun kapatma isteðine (FIN + ACK) onay bekleme durumu
    bdSonOnay,
    // bdKapanisBekleniyor1 (sunucu / istemci durumu - FIN-WAIT-1)
    // baðlantýnýn 1. ucundaki istemci / sunucunun kapatma isteði (FIN + ACK) gönderme durumu
    bdKapanisBekleniyor1);

  // aktif baðlantý: istemcinin sunucuya baðlantýsý
  // pasif baðlantý: sunucunun kendisine gelen istekleri kabul etmek için oluþturduðu baðlantý
  TBaglantiTuru = (btAktif, btPasif);

{ =================================================================================================
  tüm að iletiþimi TBaglanti üzerinden gerçekleþecek. diðer yüm nesneler bu nesnenin altýnda olacak

                                      TAgBaglantilari
                                             |
                         TAgBaglantisi1 ------------ TAgBaglantisi2
                              |
                        TBaglanti1 ----- TBaglanti2 ----- TBaglanti3
                                             |
                       TTcpBaglanti ---------+---------- TUdpBaglanti
                                             |
                                             +-----------> protokoller
                                             |
                                          TAygit0 - TAygit olacak
                                             |
                                         TEthernet0 - TEthernet olacak
                                             |
                                           TPCI
                                             |
                                         TDonanim
================================================================================================= }
type
  TBaglanti = class;

type
  PTemelAgBaglanti = ^TTemelAgBaglanti;
  TTemelAgBaglanti = class
  public
    Ad: string;
    FSiraNo: TSayi4;
    FKimlik: TKimlik;
    constructor Create; virtual;
  end;

// her bir baðlantý içerisine MUTLAKA bir adet að aygýtý
// ve bu aygýtýn kullanacaðý tüm iletiþim protokollerini içerir
// tüm að iletiþimi TBaglanti yapýsý üzerinden gerçekleþecek
type
  PAgBaglantisi = ^TAgBaglantisi;
  TAgBaglantisi = class(TTemelAgBaglanti)
  private
    FAktif: Boolean;
    FIP6Adres: TIP6Adres;
    FIP4Adres, FAltAgMaskesi, FAgGecitAdresi,
    FDHCPSunucusu, FDNSSunucusu: TIP4Adres;
    FIPKiraSuresi: TSayi4;     // saniye cinsinden
    FIP4AdresiAlindi: Boolean;

    FBaglantilar: array[0..USTSINIR_B_SAYISI - 1] of TBaglanti;
    function Al(ASiraNo: TISayi4): TBaglanti;
    procedure Yaz(ASiraNo: TISayi4; ABaglanti: TBaglanti);
  public
    FEthernet: TEthernet;
    FARP: TARP;
    FIP6: TIP6;
    FIP4: TIP4;
    FICMP4: TICMP4;
    FLLDP: TLLDP;
    constructor Create; override;
    property Aktif: Boolean read FAktif write FAktif;
    procedure VeriAlmaIslevi;
    property IP6Adres: TIP6Adres read FIP6Adres write FIP6Adres;
    property IP4Adres: TIP4Adres read FIP4Adres write FIP4Adres;
    property AltAgMaskesi: TIP4Adres read FAltAgMaskesi write FAltAgMaskesi;
    property AgGecitAdresi: TIP4Adres read FAgGecitAdresi write FAgGecitAdresi;
    property DHCPSunucusu: TIP4Adres read FDHCPSunucusu write FDHCPSunucusu;
    property DNSSunucusu: TIP4Adres read FDNSSunucusu write FDNSSunucusu;
    property IPKiraSuresi: TSayi4 read FIPKiraSuresi write FIPKiraSuresi;
    property IP4AdresiAlindi: Boolean read FIP4AdresiAlindi write FIP4AdresiAlindi;

    property Baglanti[ASiraNo: TISayi4]: TBaglanti read Al write Yaz;

    function BaglantiYapisiOlustur(ABaglantiTuru: TBaglantiTuru): TBaglanti;
    function BaglantiOlustur(AIletisimTipi: TIletisimTipi;
      ABaglantiTuru: TBaglantiTuru; AProtokolTipi: TProtokolTipi; ABaglantiAdresi: string;
      AYerelPort, AUzakPort: TSayi2): TBaglanti;
    function TCPIlkSiraNoAl: TSayi4;
    function KimlikNoAlG: TISayi4;
    function TCPBaglantiAl(AKaynakPort, AHedefPort: TSayi2): TBaglanti;
    procedure Listele;
    function UDPBaglantiAl(AYerelPort: TSayi2): TBaglanti;
  end;

{type
  PTcpBaglanti = ^TTcpBaglanti;
  TTcpBaglanti = class(TBaglanti)
  end;


type
  PUdpBaglanti = ^TUdpBaglanti;
  TUdpBaglanti = class(TBaglanti)
  end;}


type
  PBaglanti = ^TBaglanti;
  TBaglanti = class(TAgBaglantisi)
    //FTCP: TTCP;
    Kimlik: TKimlik;
    IletisimTipi: TIletisimTipi;  // ana protokol iletiþim tipleri (þu aþamada ipv4, ipv6)
    ProtokolTipi: TProtokolTipi;
    BaglantiTuru: TBaglantiTuru;
    BaglantiDurum: TBaglantiDurum;
    PencereU: TSayi2;
    SiraNo,                       // TCP sýra no (sequence number)
    OnayNo: TSayi4;               // TCP onay no (acknowledgment number)
    HedefMACAdres: TMACAdres;

    HedefIP6Adres: TIP6Adres;     // verinin gönderileceði ip6 adresi
    HedefIP4Adres: TIP4Adres;     // verinin gönderileceði ip4 adresi

    { TODO - önemli: baðlantý her 2 taraf için de oluþturulabilir, yerel / uzak karýþabilir
      özellikle TCPBaglantiAl ve benzeri iþlevler hatalý davranabilir. tedbir alýnacak }
    YerelPort, UzakPort: TSayi2;  // baðlantý kuran cihazým yerel / uzak portu

    Bagli: Boolean;
    FBellek: Isaretci;
    FVeriUzunlugu: TSayi4;        // Bellek'te mevcut veri uzunluðu
  public
    constructor Create; override;
    destructor Destroy; override;
    function Baglan(ABaglantiTipi: TBaglantiTipi): TISayi4;
    function BagliMi: Boolean;
    procedure BellegeEkle(AKaynakBellek: Isaretci; AVeriUzunlugu: TSayi4);
    function VeriUzunlugu: TSayi4;
    function Oku(ABellek: Isaretci): TSayi4;
    procedure Yaz(ABellek: Isaretci; AUzunluk: TISayi4);
    function BaglantiyiKes: TISayi4;
  end;

type
  PAgBaglantilari = ^TAgBaglantilari;
  TAgBaglantilari = class
  private
    FAgBaglantiSayisi: TSayi4;
    FBaglantiListesi0: array[0..USTSINIR_AB_SAYISI - 1] of TAgBaglantisi;
    function Al(ASiraNo: TISayi4): TAgBaglantisi;
    procedure Yaz(ASiraNo: TISayi4; ABaglanti: TAgBaglantisi);
  public
    FAktifBaglanti: TAgBaglantisi;
    constructor Create;
    procedure AgBaglantilariniOlustur;
    function KimlikNoAl: TISayi4;
    property Baglanti0[ASiraNo: TISayi4]: TAgBaglantisi read Al write Yaz;
    function YerelPortAl: TSayi2;
    property AgBaglantiSayisi: TSayi4 read FAgBaglantiSayisi write FAgBaglantiSayisi;
    property AktifBaglanti: TAgBaglantisi read FAktifBaglanti write FAktifBaglanti;
  end;

var
  GAgBaglantilari: TAgBaglantilari;
  GAgBaglantisi: TAgBaglantisi;
  BaglantilarKilit: TSayi4 = 0;

implementation

uses udp, islevler, donusum, ag, aygityonetimi, tcp;

constructor TTemelAgBaglanti.Create;
var
  i: TISayi4;
begin

  i := GAgBaglantilari.KimlikNoAl;

  FSiraNo := i;
  FKimlik := i;
end;

constructor TAgBaglantisi.Create;
var
  i: TSayi4;
begin

  inherited Create;

  // baðlantý yapýlarýný ilk deðerlerle yükle
  for i := 0 to USTSINIR_B_SAYISI - 1 do Baglanti[i] := nil;

  FAktif := False;

  IP6Adres := IP6Adresi;
  IPKiraSuresi := 0;

  FIP4AdresiAlindi := False;

  FLLDP := TLLDP.Create(Self);
  FARP := TARP.Create(Self);
  FICMP4 := TICMP4.Create(Self);
  FIP6 := TIP6.Create(Self);
  FIP4 := TIP4.Create(Self);
end;

procedure TAgBaglantisi.VeriAlmaIslevi;
var
  EthPaket: PEthernetPaket;
  ARPPaket: PARPPaket;
  Bellek: array[0..$FFF] of TSayi1;
  i: TSayi4;
  Protokol: TSayi2;
begin

  // að yüklendi ise ...                          { TODO - aktiflik test edilecek }
  if not(GAgBaglantilari.AktifBaglanti = nil) then
  begin

    // að kartýna gelen ham bilgiyi al
    i := GAgBaglantilari.AktifBaglanti.FEthernet.Al(@Bellek);
    if(i > 0) then
    begin

      EthPaket := @Bellek[0];

      {SISTEM_MESAJ_MAC(mtBilgi, RENK_MAVI, 'EthernetPaket^.KaynakMACAdres: ', EthPaket^.KaynakMACAdres);
      SISTEM_MESAJ_MAC(mtBilgi, RENK_MAVI, 'EthernetPaket^.HedefMACAdres: ', EthPaket^.HedefMACAdres);
      SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'EthernetPaket^.PaketTipi: $%.4x', [EthPaket^.PaketTipi]);}

      Protokol := htons(EthPaket^.PaketTipi);

      // yönlendirici talebi - router solicitation
      if(MACKarsilastir(EthPaket^.HedefMACAdres, MAC333300000002)) then
      begin

        if(Protokol = PROTOKOL_IP6) then FIP6.VerileriIsle(EthPaket, i - ETHERNET_BASLIKU)
      end
      //
      else if(MACKarsilastir(EthPaket^.HedefMACAdres, MAC333300000102)) then
      begin

        if(Protokol = PROTOKOL_IP6) then FIP6.VerileriIsle(EthPaket, i - ETHERNET_BASLIKU)
      end
      else if(MACKarsilastir(EthPaket^.HedefMACAdres, YayinMAC6)) then
      begin

        { TODO - çalýþmýyor }
        FIP6.VerileriIsle(EthPaket, i - ETHERNET_BASLIKU);
        //SISTEM_MESAJ(mtBilgi, RENK_MAVI, 'Son asama1', []);
      end    // bu test ethernet katmanýnda yapýlýyor
      else //if(FEthernet.MACAdresiKabulEdilsinMi(EthPaket^.HedefMACAdres)) then
      begin

        // ******* protokollerin iþlenmesi *******

        // ARP protokolü
        if(Protokol = PROTOKOL_ARP) then
        begin

          ARPPaket := @EthPaket^.Veri;
          if(IP4Karsilastir(ARPPaket^.HedefIP4Adres, IP4Adres)) then
            FARP.VerileriIsle(EthPaket)
        end

        // IP V4 protokolü
        else if(Protokol = PROTOKOL_IP4) then

          FIP4.VerileriIsle(EthPaket)

        // IP V6 protokolü
        else if(Protokol = PROTOKOL_IP6) then

          FIP6.VerileriIsle(EthPaket, i - ETHERNET_BASLIKU)

        else if(Protokol = PROTOKOL_LLDP) then

          FLLDP.VerileriIsle(EthPaket)

        else
        begin

          // bilinmeyen protokol
          SISTEM_MESAJ(mtUyari, RENK_MAVI, 'AG.PAS: bilinmeyen protokol: $%.4x', [Protokol]);
          SISTEM_MESAJ_MAC(mtUyari, RENK_SIYAH, '  -> Kaynak MAC Adresi: ', EthPaket^.KaynakMACAdres);
          SISTEM_MESAJ_MAC(mtUyari, RENK_SIYAH, '  -> Hedef MAC Adresi: ', EthPaket^.HedefMACAdres);
        end;
      end;
    end;
  end;
end;

{ TUdpBaglanti }


{ TBaglanti0 }

{==============================================================================
  baðlantý nesnelerinin ana yükleme iþlevlerini içerir
 ==============================================================================}
constructor TAgBaglantilari.Create;
var
  i: TSayi4;
begin

  FAktifBaglanti := nil;

  FAgBaglantiSayisi := 0;

  // baðlantý yapýlarýný ilk deðerlerle yükle
  for i := 0 to USTSINIR_AB_SAYISI - 1 do Baglanti0[i] := nil;

  TCPIlkSiraNo := $10001000;
  YerelPortNo := ILK_YERELPORTNO;
end;

procedure TAgBaglantilari.AgBaglantilariniOlustur;
var
  B: TAgBaglantisi;
  i: TSayi4;
begin

  if(GAygitlar.ToplamAgAygitSayisi = 0) then Exit;

  for i := 0 to GAygitlar.ToplamAgAygitSayisi - 1 do
  begin

    B := TAgBaglantisi.Create;
    B.Ad := 'Að Baðlantýsý-' + IntToStr(i + 1);
    B.FEthernet := TEthernet(GAygitlar.AgAygitListesi[i]);

    Baglanti0[B.FSiraNo] := B;

    if(FAktifBaglanti = nil) then FAktifBaglanti := B;

    Inc(FAgBaglantiSayisi);
  end;
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

function TAgBaglantilari.Al(ASiraNo: TISayi4): TAgBaglantisi;
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_AB_SAYISI) then
    Result := FBaglantiListesi0[ASiraNo]
  else Result := nil;
end;

procedure TAgBaglantilari.Yaz(ASiraNo: TISayi4; ABaglanti: TAgBaglantisi);
begin

  if(ASiraNo >= 0) and (ASiraNo < USTSINIR_AB_SAYISI) then
    FBaglantiListesi0[ASiraNo] := ABaglanti;
end;

{==============================================================================
  að baðlantýsý için baðlantý oluþturur
 ==============================================================================}
function TAgBaglantisi.BaglantiOlustur(AIletisimTipi: TIletisimTipi;
  ABaglantiTuru: TBaglantiTuru; AProtokolTipi: TProtokolTipi; ABaglantiAdresi: string;
  AYerelPort, AUzakPort: TSayi2): TBaglanti;
var
  B: TBaglanti;
  s, SunucuAdi,
  Sayfa: string;
  i: TSayi4;
  IP6Adr: TIP6Adres;
  IP4Adr: TIP4Adres;
begin

//  while KritikBolgeyeGir(BaglantilarKilit) = False do;

  B := BaglantiYapisiOlustur(ABaglantiTuru);
  if(B = nil) then Exit(nil);

  // ABaglantiAdresi içeriði aþaðýdaki biçimde gelmekte olup bu yapýnýn "/" sonrasý
  // ne burada ne de çekirdeðin hiçbir yerinde kullanýlmamaktadýr.
  { TODO - ileride http(s) protokolünde kullanýlma ihtimali mevcuttur }
  // 192.168.1.1/search?q=elerais
  i := Pos('/', ABaglantiAdresi);
  if(i > 0) then
  begin

    SunucuAdi := Copy(ABaglantiAdresi, 1, i - 1);
    Sayfa := Copy(ABaglantiAdresi, i, Length(ABaglantiAdresi) - i + 1);
  end
  else
  begin

    SunucuAdi := ABaglantiAdresi;
    Sayfa := '/';
  end;

  B.Bagli := False;
  B.IletisimTipi := AIletisimTipi;

  IP6Adr := IP6Adres0;
  IP4Adr := IP4Adres0;

  if(AIletisimTipi = itIP6) then
  begin

    IP6Adr := StrToIP6(SunucuAdi);
    B.HedefIP6Adres := IP6Adr;
  end
  else
  begin

    IP4Adr := StrToIP4(SunucuAdi);
    B.HedefIP4Adres := IP4Adr;
  end;

  B.ProtokolTipi := AProtokolTipi;

  // aktif baðlantý: bu bilgisayarýn diðer bilgisayarýn sunucusuna baðlantýsý
  // pasif baðlantý: diðer bilgisayarlarýn bu bilgisayarýn sunucusuna baðlantýsý
  //if(ABaglantiTuru = btAktif) then
  begin

    B.YerelPort := AYerelPort;
    B.UzakPort := AUzakPort;
  {end
  else if(ABaglantiTuru = btPasif) then
  begin

    B.YerelPort := AUzakPort;
    B.UzakPort := AYerelPort;}
  end;

  if(AProtokolTipi = ptTCP) then
  begin

    B.PencereU := TCP_PENCERE_UZUNLUK;
    B.SiraNo := TCPIlkSiraNoAl;
    B.OnayNo := 0;
  end
  else if(AProtokolTipi = ptUDP) then
  begin

    {SISTEM_MESAJ(mtBilgi, RENK_MOR, 'BAGLANTI.PAS: Protokol -> UDP', []);
    SISTEM_MESAJ(mtBilgi, RENK_MOR, 'BAGLANTI.PAS: Kimlik %d', [B^.Kimlik]);
    SISTEM_MESAJ_IP4(mtBilgi, RENK_LACIVERT, 'Hedef IP: ', IP4Adr);
    SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Kaynak Port: %d', [AYerelPort]);
    SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'Hedef Port: %d', [AUzakPort]);}
  end
  else
  begin

    s := ProtokolTipAdi(AProtokolTipi);
    SISTEM_MESAJ(mtHata, RENK_PEMBE, 'BAGLANTI.PAS: TAgBaglantilari.BaglantiOlustur', []);
    SISTEM_MESAJ(mtHata, RENK_TURKUAZ, '  - Bilinmeyen Protokol: %s ', [s]);
    if(AIletisimTipi = itIP6) then
      SISTEM_MESAJ_IP6(mtHata, RENK_TURKUAZ, '  - Hedef IP: ', IP6Adr)
    else SISTEM_MESAJ_IP4(mtHata, RENK_TURKUAZ, '  - Hedef IP: ', IP4Adr);
    SISTEM_MESAJ(mtHata, RENK_TURKUAZ, '  - Hedef Port: %d', [AUzakPort]);
  end;

  Result := B;

//  KritikBolgedenCik(BaglantilarKilit);
end;

{==============================================================================
  yeni baðlantý için gerekli yapýlarý oluþturur
 ==============================================================================}
function TAgBaglantisi.BaglantiYapisiOlustur(ABaglantiTuru: TBaglantiTuru): TBaglanti;
var
  B: TBaglanti;
begin

  B := TBaglanti.Create;
  if not(B = nil) then
  begin

    Baglanti[B.Kimlik] := B;

    B.BaglantiTuru := ABaglantiTuru;

    Exit(B);
  end;

  Result := nil;
end;

{==============================================================================
  TCP veri alýþveriþinin gerçekleþmesi için gereken ilk sýra numarasýný alýr
 ==============================================================================}
function TAgBaglantisi.TCPIlkSiraNoAl: TSayi4;
begin

  Result := TCPIlkSiraNo;
  Inc(TCPIlkSiraNo, 10);
end;

function TAgBaglantilari.KimlikNoAl: TISayi4;
var
  B: TAgBaglantisi;
  i: TISayi4;
begin

  Result := -1;

  for i := 0 to USTSINIR_AB_SAYISI - 1 do
  begin

    B := Baglanti0[i];

    if(B = nil) then Exit(i);
  end;
end;

function TAgBaglantisi.KimlikNoAlG: TISayi4;
var
  B: TBaglanti;
  i: TISayi4;
begin

  Result := -1;

  for i := 0 to USTSINIR_B_SAYISI - 1 do
  begin

    B := Baglanti[i];

    if(B = nil) then Exit(i);
  end;
end;

{==============================================================================
  tcp kaynak / hedef portun sahibi olan baðlantýyý alýr
 ==============================================================================}
function TAgBaglantisi.TCPBaglantiAl(AKaynakPort, AHedefPort: TSayi2): TBaglanti;
var
  B: TBaglanti;
  i: TSayi4;
begin

  Result := nil;

  // tüm iþlem giriþlerini incele
  for i := 0 to USTSINIR_B_SAYISI - 1 do
  begin

    B := Baglanti[i];
    if not(B = nil) then
    begin

      if(B.BaglantiTuru = btAktif) then
      begin

        if{not(B.BaglantiDurum = bdYok) and} (AKaynakPort = B.UzakPort) and
          (AHedefPort = B.YerelPort) then Exit(B);
      end
      else if(B.BaglantiTuru = btPasif) then
      begin

        if{not(B.BaglantiDurum = bdYok) and} (AKaynakPort = B.YerelPort) and
          (AHedefPort = B.UzakPort) then Exit(B);
      end;
    end;
  end;
end;

procedure TAgBaglantisi.Listele;
var
  B: TBaglanti;
  i: TSayi4;
begin

  // tüm iþlem giriþlerini incele
  for i := 0 to USTSINIR_B_SAYISI - 1 do
  begin

    B := Baglanti[i];
    if not(B = nil) then
      SISTEM_MESAJ(mtUyari, RENK_KIRMIZI, 'Kaynak: %d, Hedef: %d', [B.YerelPort, B.UzakPort]);
  end;
end;

{==============================================================================
  udp yerel portun sahibi olan baðlantýyý alýr
 ==============================================================================}
function TAgBaglantisi.UDPBaglantiAl(AYerelPort: TSayi2): TBaglanti;
var
  B: TBaglanti;
  i: TSayi4;
begin

  // tüm iþlem giriþlerini incele
  for i := 0 to USTSINIR_B_SAYISI - 1 do
  begin

    B := Baglanti[i];
    if not(B.BaglantiDurum = bdYok) and (B.YerelPort = AYerelPort) then
      Exit(B);
  end;

  Result := nil;
end;

{==============================================================================
  yerel port numarasý üretir
 ==============================================================================}
function TAgBaglantilari.YerelPortAl: TSayi2;
begin

  Inc(YerelPortNo);
  if(YerelPortNo > $FDE8 {65000}) then YerelPortNo := ILK_YERELPORTNO;
  Result := YerelPortNo;
end;

constructor TBaglanti.Create;
begin

  inherited Create;

  Kimlik := GAgBaglantisi.KimlikNoAlG;

  BaglantiDurum := bdKapali;

  Bagli := False;

  FVeriUzunlugu := 0;
  FBellek := GetMem(4 * 4096); //Bag^.FPencereU);
  if(FBellek = nil) then SISTEM_MESAJ(mtHata, RENK_SIYAH, 'BAGLANTI.PAS: Bellek yok', []);
end;

destructor TBaglanti.Destroy;
begin

  if not(FBellek = nil) then FreeMem(FBellek, 4 * 4096);

  GAgBaglantisi.Baglanti[Self.Kimlik] := nil;

  inherited Destroy;
end;

{==============================================================================
  oluþturulan baðlantý üzerinden uzaktaki sisteme baðlantý kurar
 ==============================================================================}
function TBaglanti.Baglan(ABaglantiTipi: TBaglantiTipi): TISayi4;
begin

  { TODO - dhcp üzerinden 255... ip adresine gönderilen paketlerin önlemleri alýnsýn }
  if(ProtokolTipi = ptUDP) then
  begin

    if(ABaglantiTipi = btYayin) then
    begin

      HedefMACAdres := MACAdres255;
      Bagli := True;
      Exit(Kimlik);
    end
    else
    begin

      { TODO - ip v6'ya göre düzenlenecek }
      if(IP4AdresiAyniAgdaMi(HedefIP4Adres)) then
        HedefMACAdres := GARPTablosu.MACAdresAl(HedefIP4Adres)
      else HedefMACAdres := GARPTablosu.MACAdresAl(GAgBaglantilari.AktifBaglanti.DNSSunucusu);

      Bagli := True;
      Exit(Kimlik);
    end;
  end
  else if(ProtokolTipi = ptTCP) then
  begin

    if(BaglantiDurum = bdKapali) then
    begin

      { TODO - ip v6'ya göre düzenlenecek }
      if(IP4AdresiAyniAgdaMi(HedefIP4Adres)) then
        HedefMACAdres := GARPTablosu.MACAdresAl(HedefIP4Adres)
      else HedefMACAdres := GARPTablosu.MACAdresAl(GAgBaglantilari.AktifBaglanti.DNSSunucusu);

      // ilk paket olan SYN (ARZ) paketi gönderiliyor
      if(IletisimTipi = itIP6) then
      begin end
      else GTCP.PaketleVeGonder(Self, TCP_BAYRAK_ARZ, @TCP4SYNSonEk, 12, True);
      BaglantiDurum := bdBaglaniyor;
      Exit(Kimlik);
    end;
  end;

  Result := -1;
end;

{==============================================================================
  baðlantýnýn var olup olmadýðýný kontrol eder
 ==============================================================================}
function TBaglanti.BagliMi: Boolean;
begin

  Result := False;

  // baðlantýyý al
  if(ProtokolTipi = ptUDP) then

    Result := Bagli

  else if(ProtokolTipi = ptTCP) then

    if(BaglantiDurum = bdBaglantiKuruldu) then Result := True
end;

{==============================================================================
  baðlantý kurulan bilgisayardan gelen verileri programýn kullanmasý için belleðe kaydeder
 ==============================================================================}
procedure TBaglanti.BellegeEkle(AKaynakBellek: Isaretci; AVeriUzunlugu: TSayi4);
var
  p: PChar;
  i: TSayi4;
begin

  if(AVeriUzunlugu = 0) then Exit;

  if(VeriUzunlugu + AVeriUzunlugu < (4 * 4096)) then
  begin

    p := FBellek + VeriUzunlugu;

    Tasi2(AKaynakBellek, p, AVeriUzunlugu);
    i := VeriUzunlugu;
    i := i + AVeriUzunlugu;
    FVeriUzunlugu := i;
  end;
end;

{==============================================================================
  baðlantý kurulan cihazdan gelip iþlenmeyi bekleyen veri miktarýný alýr
 ==============================================================================}
function TBaglanti.VeriUzunlugu: TSayi4;
begin

  Result := FVeriUzunlugu;
end;

{==============================================================================
  baðlantý üzerinden gelen veriyi ilgili programa yönlendirir
 ==============================================================================}
function TBaglanti.Oku(ABellek: Isaretci): TSayi4;
var
  i: TSayi4;
begin

  i := VeriUzunlugu;
  if(i > 0) then
  begin

    Tasi2(FBellek, ABellek, i);
    Result := VeriUzunlugu;
    FVeriUzunlugu := 0;
    Exit(i);
  end;

  Result := 0;
end;

{==============================================================================
  baðlantý kurulan bilgisayara veri gönderir
 ==============================================================================}
procedure TBaglanti.Yaz(ABellek: Isaretci; AUzunluk: TISayi4);
begin

  if(ProtokolTipi = ptTCP) then
  begin

    if(BaglantiDurum = bdBaglantiKuruldu) then
    begin

      // FPencereU := $100;
      GTCP.PaketleVeGonder(Self, TCP_BAYRAK_KABUL or TCP_BAYRAK_GONDER, ABellek, AUzunluk);
    end;
  end
  else if(ProtokolTipi = ptUDP) then
  begin

    { TODO - ip v6'ya göre düzenlenecek }
    GUDP.PaketleVeGonder(Self.IletisimTipi, HedefMACAdres, @GAgBaglantilari.AktifBaglanti.IP4Adres, @HedefIP4Adres,
      YerelPort, UzakPort, ABellek, AUzunluk);
  end
end;

{==============================================================================
  baðlantýyý kapatýr
 ==============================================================================}
function TBaglanti.BaglantiyiKes: TISayi4;
begin

  Result := -1;

  { TODO - baðlantýnýn yok edilmesi baðlantý kesilmesi (burada) aþamasýnda gerçekleþtirilebilir }

  if(ProtokolTipi = ptUDP) then
  begin

    BaglantiDurum := bdKapali;
    ProtokolTipi := ptBilinmiyor;
    HedefIP6Adres := IP6Adres0;
    HedefIP4Adres := IP4Adres0;
    YerelPort := 0;
    UzakPort := 0;

    Bagli := False;

    Result := 0;
  end
  else if(ProtokolTipi = ptTCP) then
  begin

    if(BaglantiDurum = bdBaglantiKuruldu) then
    begin

      { TODO - düzenle }
      GTCP.PaketleVeGonder(Self, TCP_BAYRAK_SON + TCP_BAYRAK_KABUL, nil, 0);

      BaglantiDurum := bdKapanisBekleniyor1;

      Result := 0;
    end;
  end;
end;

end.
