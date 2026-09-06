{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: ethernet.pas
  Dosya İşlevi: ethernet ağ (network) kartı yönetim işlevlerini içerir

  Güncelleme Tarihi: 06/09/2026

 ==============================================================================}
{$mode objfpc}
unit ethernet;

interface

uses paylasim, aygit;

const
  ETHERNET_BASLIKU = TSayi1(14);

const
  // yerel olarak KABUL EDİLEBİLİR mac adres sayısı
  // bilgi: ethernet mac adresi bu listeye direkt dahil olmayıp, dolaylı olarak dahildir
  KE_MAC_ADRESSAYISI = 2;

const
  YerelMACAdresListesi: array[0..KE_MAC_ADRESSAYISI - 1] of TMACAdres = (
    ($FF, $FF, $FF, $FF, $FF, $FF),
    ($33, $33, $00, $01, $00, $02));

type
  TEthernet = class(TAgAygiti)
  private
    // True olması durumunda, ethernet kartı ve YerelMACAdresListesi haricinde
    // gelen tüm paketler işlenir, aksi halde ilgili mac adreslerine gelen paketler işlenir
    FTumPaketleriIsle: Boolean;
    // ethernet kartının mac adresi
    FMACAdres: TMACAdres;
    // paket başlıkları da dahil olmak üzere tüm veri toplamlarını içerir.
    FGelenByte, FGidenByte: TSayi4;
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure Gonder(AHedefMACAdr: TMACAdres; AProtokolTipi: TProtokolTipi;
      AVeri: Isaretci; AVeriU: TSayi4);
    function Al(AHedefBellekAdresi: Isaretci): TSayi4;

    function MACAdresiKabulEdilsinMi(AHedefMACAdres: TMACAdres): Boolean;

    property MACAdres: TMACAdres read FMACAdres write FMACAdres;
    property GelenByte: TSayi4 read FGelenByte write FGelenByte;
    property GidenByte: TSayi4 read FGidenByte write FGidenByte;
  end;

implementation

uses donusum, islevler, sistemmesaj;

{==============================================================================
  ethernet kart nesnesi oluşturma işlevlerini gerçekleştirir
 ==============================================================================}
constructor TEthernet.Create;
begin

  inherited Create;

  FTumPaketleriIsle := True;

  GelenByte := 0;
  GidenByte := 0;
end;

{==============================================================================
  ethernet kart nesnesi yok etme işlevlerini gerçekleştirir
 ==============================================================================}
destructor TEthernet.Destroy;
begin

  inherited Destroy;
end;

{==============================================================================
  ethernet kartı üzerinden veri gönderir
 ==============================================================================}
procedure TEthernet.Gonder(AHedefMACAdr: TMACAdres; AProtokolTipi: TProtokolTipi;
  AVeri: Isaretci; AVeriU: TSayi4);
var
  EthPaket: PEthernetPaket;
  Bellek: Isaretci;
begin

  // aygıt akitf ise veri gönder
  if(Aktif) then
  begin

    // veri paketi için bellekte yer ayır
    EthPaket := GetMem(AVeriU + ETHERNET_BASLIKU);

    EthPaket^.HedefMACAdres := AHedefMACAdr;
    EthPaket^.KaynakMACAdres := MACAdres;

    // paketin tutanak tipi
    case AProtokolTipi of
      ptIP4   : EthPaket^.PaketTipi := ntohs(PROTOKOL_IP4);
      ptIP6   : EthPaket^.PaketTipi := ntohs(PROTOKOL_IP6);
      ptTCP   : EthPaket^.PaketTipi := PROTOKOL_TCP;
      ptUDP   : EthPaket^.PaketTipi := PROTOKOL_UDP;
      ptARP   : EthPaket^.PaketTipi := ntohs(PROTOKOL_ARP);
      ptICMP4 : EthPaket^.PaketTipi := PROTOKOL_ICMP4;
    end;
{
    SISTEM_MESAJ(mtBilgi, RENK_MOR, 'ETH', []);
    SISTEM_MESAJ_MAC(mtBilgi, RENK_LACIVERT, 'ETH: Kaynak MAC: ', EthPaket^.KaynakMACAdres);
    SISTEM_MESAJ_MAC(mtBilgi, RENK_LACIVERT, 'ETH: Hedef MAC: ', EthPaket^.HedefMACAdres);
    SISTEM_MESAJ(mtBilgi, RENK_LACIVERT, 'ETH: PaketTip: %.4x', [EthPaket^.PaketTipi]);
}
    Bellek := @EthPaket^.Veri;
    Tasi2(AVeri, Bellek, AVeriU);

    if(Assigned(FVeriGonder)) then
    begin

      FVeriGonder(EthPaket, AVeriU + ETHERNET_BASLIKU);

      Inc(FGidenByte, AVeriU + ETHERNET_BASLIKU);
    end;

    // ayrılan belleği serbest bırak
    FreeMem(EthPaket, AVeriU + ETHERNET_BASLIKU);
  end;
end;

{==============================================================================
  ethernet kartına gelen verileri alır
 ==============================================================================}
function TEthernet.Al(AHedefBellekAdresi: Isaretci): TSayi4;
var
  EthPaket: PEthernetPaket;
  Bellek: array[0..$FFF] of TSayi1;
  PaketleriIsle: Boolean;
  i: TSayi4;
begin

  Result := 0;

  // aygıt aktif değilse çık
  if not(Aktif) then Exit;

  i := 0;

  // ağ kartına (ethernet) gelen ham bilgiyi al
  if(Assigned(FVeriAl)) then i := FVeriAl(@Bellek);
  if(i > 0) then
  begin

    EthPaket := @Bellek[0];

    PaketleriIsle := False;

    if(FTumPaketleriIsle) then
      PaketleriIsle := True
    else PaketleriIsle := MACAdresiKabulEdilsinMi(EthPaket^.HedefMACAdres);

    if(PaketleriIsle) then
    begin

      Tasi2(@Bellek[0], AHedefBellekAdresi, i);
      Inc(FGelenByte, i);
      Result := i;
    end
    else
    begin

      SISTEM_MESAJ_MAC(mtBilgi, RENK_GRI, 'ETHERNET.PAS->Hedef MAC Adres Farklı: ', EthPaket^.HedefMACAdres);
    end;
  end;
end;

{==============================================================================
  ethernet kartına hangi mac adreslerden gelen paketler kabul edilsin?
 ==============================================================================}
function TEthernet.MACAdresiKabulEdilsinMi(AHedefMACAdres: TMACAdres): Boolean;
var
  i: TSayi4;
begin

  Result := False;

  // 1. ethernet aygıtı mac adresi kontrolü
  if(MACKarsilastir(AHedefMACAdres, MACAdres)) then Exit(True);

  // 2. yerel mac adres kayıt kontrolü
  if(KE_MAC_ADRESSAYISI > 0) then
  begin

    for i := 0 to KE_MAC_ADRESSAYISI - 1 do
    begin

      if(MACKarsilastir(AHedefMACAdres, YerelMACAdresListesi[i])) then Exit(True);
    end;
  end;
end;

end.
