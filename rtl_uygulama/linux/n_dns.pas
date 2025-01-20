{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: n_dns.pas
  Dosya İşlevi: dns yönetim işlevlerini içerir
  İşlev No: 0x12 / 2

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit n_dns;

interface

uses n_genel;

type
  PDNS = ^TDNS;
  TDNS = object
  private
    FGenel: TGenel;
    FKimlik: TKimlik;

    // indy uyum değişkenleri
    FQDCount,                 // sorgu sayısı
    FANCount,                 // yanıt sayısı
    FNSCount,                 // yetki sayısı - authority
    FARCount: TSayi2;         // diğer sayısı - additional
    FName: string;            // dns adı
    FRecType,                 // kayıt tipi
    FRecClass: TSayi2;        // kayıt sınıfı
    FTTL: TSayi4;             // yaşam ömrü
    FRData: TIPAdres;         // ip adres
  public
    procedure Olustur;
    function Sorgula(ADNSAdres: string): Boolean;
    procedure IcerikAl;
    procedure YokEt;
    property Kimlik: TKimlik read FKimlik;

    // indy uyum değişkenleri
    property QDCount: TSayi2 read FQDCount;
    property ANCount: TSayi2 read FANCount;
    property NSCount: TSayi2 read FNSCount;
    property ARCount: TSayi2 read FARCount;
    property Name: string read FName;
    property RecType: TSayi2 read FRecType;
    property RecClass: TSayi2 read FRecClass;
    property TTL: TSayi4 read FTTL;
    property RData: TIPAdres read FRData;
  end;

implementation

function _Olustur: TISayi4; assembler;
asm
  mov   eax,ILETISIM_DNS_OLUSTUR
  int   $34
end;

procedure _Sorgula(AKimlik: TKimlik; ADNSAdres: string); assembler;
asm
  push  DWORD ADNSAdres
  push  DWORD AKimlik
  mov   eax,ILETISIM_DNS_SORGULA
  int   $34
  add   esp,8
end;

function _DurumAl(AKimlik: TKimlik): TDNSDurum; assembler;
asm
  push  DWORD AKimlik
  mov   eax,ILETISIM_DNS_DURUMAL
  int   $34
  add   esp,4
end;

procedure _IcerikAl(AKimlik: TKimlik; AHedefBellek: Isaretci); assembler;
asm
  push  DWORD AHedefBellek
  push  DWORD AKimlik
  mov   eax,ILETISIM_DNS_ICERIKAL
  int   $34
  add   esp,8
end;

procedure _Kapat(AKimlik: TKimlik); assembler;
asm
  push  DWORD AKimlik
  mov   eax,ILETISIM_DNS_KAPAT
  int   $34
  add   esp,4
end;

procedure _YokEt(AKimlik: TKimlik); assembler;
asm
  push  DWORD AKimlik
  mov   eax,ILETISIM_DNS_YOKET
  int   $34
  add   esp,4
end;

procedure TDNS.Olustur;
begin

  // ilk değerler yükleniyor
  FQDCount := 0;
  FANCount := 0;
  FNSCount := 0;
  FARCount := 0;
  FName := '';
  FRecType := 0;
  FRecClass := 0;
  FTTL := 0;
  FRData := IPAdres0;

  FKimlik := _Olustur;
end;

function TDNS.Sorgula(ADNSAdres: string): Boolean;
var
  Durum: TDNSDurum;
  i: TSayi4;
begin

  _Sorgula(FKimlik, ADNSAdres);

  for i := 1 to 10 do
  begin

    Durum := _DurumAl(FKimlik);
    if(Durum = ddSorgulandi) then Exit(True);

    FGenel.Bekle(30);
  end;

  Result := False;
end;

procedure TDNS.IcerikAl;
var
  Veriler: array[0..1023] of TSayi1;
  DNSPaket: PDNSPaket;
  Veri1: PByte;
  DNSBolum: TSayi4;
  Veri1U, i: TSayi1;
  Veri2: PSayi2;
  Veri4: PSayi4;
begin

  _IcerikAl(FKimlik, @Veriler);

  // ilk 4 byte dns yanıt verisinin uzunluğunu içerir
  DNSPaket := PDNSPaket(@Veriler[4]);

  // girdi sayılarının alınması
  FQDCount := ntohs(DNSPaket^.SorguSayisi);
  FANCount := ntohs(DNSPaket^.YanitSayisi);
  FNSCount := ntohs(DNSPaket^.YetkiSayisi);
  FARCount := ntohs(DNSPaket^.DigerSayisi);

  DNSBolum := 0;        // dns adresindeki her bir bölüm
  FName := '';

  // örnek dns adres verisi: [6]google[3]com[0]
  // bilgi: [] arasındaki veri sayısal byte türünde veridir.

  Veri1 := @DNSPaket^.Veriler;
  while Veri1^ <> 0 do
  begin

    if(DNSBolum > 0) then FName := FName + '.';

    Veri1U := Veri1^;     // kaydın uzunluğu
    Inc(Veri1);
    i := 0;
    while i < Veri1U do
    begin

      FName := FName + Char(Veri1^);
      Inc(Veri1);
      Inc(i);
      Inc(DNSBolum);
    end;
  end;
  Inc(Veri1);

  Veri2 := PSayi2(Veri1);
  Inc(Veri2);
  Inc(Veri2);
  Inc(Veri2);

  FRecType := ntohs(Veri2^);
  Inc(Veri2);
  FRecClass := ntohs(Veri2^);
  Inc(Veri2);

  Veri4 := PSayi4(Veri2);
  FTTL := ntohs(PSayi4(Veri4)^);
  Inc(Veri4);

  Veri2 := PSayi2(Veri4);
  // uzunluk verisi - gözardı ediliyor
  Inc(Veri2);

  Veri1 := PSayi1(Veri2);

  FRData[0] := Veri1^;
  Inc(Veri1);
  FRData[1] := Veri1^;
  Inc(Veri1);
  FRData[2] := Veri1^;
  Inc(Veri1);
  FRData[3] := Veri1^;
end;

procedure TDNS.YokEt;
begin

  // bağlantıyı kapat
  _Kapat(FKimlik);

  // bağlantı için ayrılan kaynakları yok et
  _YokEt(FKimlik);

  // öndeğer kimlik değeri
  FKimlik := -1;
end;

end.
