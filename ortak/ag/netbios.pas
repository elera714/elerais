{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: netbios.pas
  Dosya Ýþlevi: netbios tutanak iþlevlerini yönetir

  Güncelleme Tarihi: 01/11/2026

 ==============================================================================}
{$mode objfpc}
unit netbios;

interface

uses udp, paylasim, sunucular;

type
  PNetBiosMesaj = ^TNetBiosMesaj;
  TNetBiosMesaj = packed record
  	Tanimlayici,
    Bayrak,
    SorguSayisi,
    YanitSayisi,
    YetkiSayisi,
    DigerSayisi: TSayi2;
    Veriler: Isaretci;
  end;

type
  TNetBios = class(TUDPIstemci)
  public
    FBaglanti: TObject;
    FUDP: TUDP;
  public
    constructor Create(ABaglanti: TObject);
    destructor Destroy; override;
    procedure OVeriGeldi(AEthernetPaket: PEthernetPaket); override;
  end;

implementation

uses sistemmesaj, donusum, islevler, baglantilar;

constructor TNetBios.Create(ABaglanti: TObject);
begin

  inherited Create;

  FBaglanti := ABaglanti;

  // iletiþim udp tutanaðý üzerinden gerçekleþeceði için 1 adet udp
  // nesnesi oluþturuluyor
  FUDP := TUDP.Create(nil, FBaglanti, itIP4, MACAdres0);
end;

destructor TNetBios.Destroy;
begin

  FUDP.Destroy;

  inherited;
end;

{==============================================================================
  netbios sorgularýný yanýtlar
 ==============================================================================}
procedure TNetBios.OVeriGeldi(AEthernetPaket: PEthernetPaket);
var
  B: TBaglanti;
  IP4Paket: PIP4Paket;
  UDPPaket: PUDPPaket;
  NBM: PNetBiosMesaj;
  Tanimlayici, SorguSayisi,
  DigerSayisi, IstekTipi,
  IstekSinifi: TSayi2;
  NetBIOSAdi, NetBIOSAdim: string;
  PB1: PByte;
  PB2: PSayi2;
  B1, B2, B3: TSayi1;
  P1: PSayi1;
  P2: PSayi2;
  P4: PSayi4;
  i: TSayi4;
begin

  B := TBaglanti(FBaglanti);

  IP4Paket := PIP4Paket(@AEthernetPaket^.Veri);
  UDPPaket := PUDPPaket(@IP4Paket^.Veri);
  NBM := PNetBiosMesaj(@UDPPaket^.Veri);

  {SISTEM_MESAJ(mtBilgi, RENK_PEMBE, 'NetBios Bilgileri.............:', []);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - IslemKimlik: $%.4x', [ntohs(NBM^.Tanimlayici)]);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - Bayrak: : $%.4x', [ntohs(NBM^.Bayrak)]);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - SorguSayisi: %d', [ntohs(NBM^.SorguSayisi)]);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - YanitSayisi: %d', [ntohs(NBM^.YanitSayisi)]);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - YetkiSayisi: %d', [ntohs(NBM^.YetkiSayisi)]);
  SISTEM_MESAJ(mtBilgi, RENK_TURKUAZ, '  - DigerSayisi: %d', [ntohs(NBM^.DigerSayisi)]);}

  Tanimlayici := ntohs(NBM^.Tanimlayici);

  // sorgu sayýsý ve yanýt sayýsý kontrolü
  SorguSayisi := ntohs(NBM^.SorguSayisi);
  DigerSayisi := ntohs(NBM^.DigerSayisi);

  // SADECE 1 adet sorguya sahip baþlýk deðerlendirilecek
  if(SorguSayisi <> 1) then Exit;
  //if(DigerSayisi <> 1) then Exit;

  NetBIOSAdi := '';

  PB1 := @NBM^.Veriler;

  // uzunluðu atla - 32 deðeri
  Inc(PB1);

  // 16 byte'lýk netbios ad deðerini al
  for i := 1 to 16 do
  begin

    B1 := PB1^;
    Inc(PB1);
    B2 := PB1^;
    Inc(PB1);

    B3 := (B1 - Ord('A')) shl 4;
    B3 := (B2 - Ord('A')) or B3;

    NetBIOSAdi := NetBIOSAdi + Char(B3);
  end;
  NetBIOSAdi := Trim(NetBIOSAdi);

  // sýfýr sonlandýrmayý atla
  Inc(PB1);

  // tip ve sýnýf deðerini al
  PB2 := PSayi2(PB1);
  IstekTipi := ntohs(PB2^);
  Inc(PB2);
  IstekSinifi := ntohs(PB2^);

  NetBIOSAdim := UpperCase(GTamBilgisayarAdi);

  // sorgulanacak netbios adý bu bilgisayar ile aynýysa yanýt mesajý oluþtur ve gönder
  if(NetBIOSAdi =  NetBIOSAdim) and (IstekTipi = 32) and (IstekSinifi = 1) then
  begin

    NBM := PNetBiosMesaj(B.FBellek);

    NBM^.Tanimlayici := htons(Tanimlayici);
    NBM^.Bayrak := htons(TSayi2($8500));
    NBM^.SorguSayisi := $0000;
    NBM^.YanitSayisi := htons(TSayi2($0001));
    NBM^.YetkiSayisi := $0000;
    NBM^.DigerSayisi := $0000;
    P1 := @NBM^.Veriler;

    // netbios ad uzunluðu
    P1^ := 32;
    Inc(P1);

    // netbios ad uzunluðu 16 * 2 byte uzunluðunda (her byte 2 byte'e geniþletiliyor)
    for i := 1 to Length(GTamBilgisayarAdi) do
    begin

      B1 := Ord(UpperCase(GTamBilgisayarAdi)[i]);
      P1^ := (B1 shr 4) + Ord('A');
      Inc(P1);
      P1^ := (B1 and $F) + Ord('A');
      Inc(P1);
    end;

    // (eðer varsa) sað kýsým 16 * 2 boþluk deðerine tamamlanýyor
    if(Length(GTamBilgisayarAdi) < 16) then
    begin

      for i := Length(GTamBilgisayarAdi) + 1 to 16 do
      begin

        B1 := Ord(' ');
        P1^ := (B1 shr 4) + Ord('A');
        Inc(P1);
        P1^ := (B1 and $F) + Ord('A');
        Inc(P1);
      end;
    end;

    // sonlandýrma deðeri
    P1^ := 0;
    Inc(P1);

    // tip deðeri
    P2 := PSayi2(P1);
    P2^ := ntohs(TSayi2(32));
    Inc(P2);

    // sýnýf deðeri
    P2^ := ntohs(TSayi2(1));
    Inc(P2);

    // yaþam süresi - 1 saat
    P4 := PSayi4(P2);
    P4^ := ntohs(TSayi4(1 * 60 * 60));
    Inc(P4);

    // veri uzunluðu
    P2 := PSayi2(P4);
    P2^ := ntohs(TSayi2(6));
    Inc(P2);

    // bayraklar
    P2^ := ntohs(TSayi2(0));
    Inc(P2);

    // ip adresim
    PIP4Adres(P2)^ := TBaglanti(FBaglanti).FAB.IP4Adresim;

    FUDP.FIP4.FHedefMACAdres := AEthernetPaket^.KaynakMACAdres;
    FUDP.FIP4.FKaynakIPAdres := IP4Paket^.KaynakIPAdres;
    FUDP.FIP4.FHedefIPAdres := TBaglanti(FBaglanti).FAB.IP4Adresim;

    // 12 = baþlýk, 2 = ad baþ - son deðeri, 32 = netbios adý, 16 = son mesaj ekleri
    FUDP.PaketleVeGonder(NBM, 12 + 2 + 32 + 16);

    SISTEM_MESAJ(mtBilgi, RENK_YESIL, 'NetBios yanýtý gönderildi...', []);
  end
  else
  begin

    SISTEM_MESAJ(mtUyari, RENK_PEMBE, 'Yanýtlanmayan NetBios isteði:', []);
    SISTEM_MESAJ(mtUyari, RENK_TURKUAZ, ' -> Sorgulanan Ad: %s', [NetBIOSAdi]);
    SISTEM_MESAJ(mtUyari, RENK_TURKUAZ, ' -> Ýstek Tipi: %d', [IstekTipi]);
    SISTEM_MESAJ(mtUyari, RENK_TURKUAZ, ' -> Ýstek Sýnýfý: %d', [IstekSinifi]);
  end;
end;

end.
