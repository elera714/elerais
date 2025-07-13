{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: sistemmesaj.pas
  Dosya İşlevi: hata ayıklama (debug) amaçlı mesaj yönetim işlevlerini içerir

  Bilgi: USTSINIR_MESAJ adedince sistem mesajı çekirdekte yukarıdan aşağıya doğru sıralı olarak depolanır,
    tüm mesaj alanları dolduğunda kayıtlı mesajlar bir yukarı kaydırılarak yeni mesaj en alta eklenir

  Güncelleme Tarihi: 13/07/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit sistemmesaj;

interface

uses paylasim;

const
  USTSINIR_MESAJ = 32;

type
  PMesajTipi = ^TMesajTipi;
  TMesajTipi = (mtBilgi = 1, mtUyari, mtHata);

  PMesajKayit = ^TMesajKayit;
  TMesajKayit = record
    MesajTipi: TMesajTipi;
    SiraNo: TSayi4;
    Saat: TSayi4;
    Renk: TRenk;
    Mesaj: string;
  end;

type
  PSistemMesaj = ^TSistemMesaj;
  TSistemMesaj = object
  private
    FServisCalisiyor: Boolean;
    FMesajSN, FToplamMesaj: TSayi4;
    FMesajListesi: array[0..USTSINIR_MESAJ - 1] of PMesajKayit;
    function MesajAl(ASiraNo: TSayi4): PMesajKayit;
    procedure MesajYaz(ASiraNo: TSayi4; AMesajKayit: PMesajKayit);
  public
    procedure Yukle;
    procedure Ekle(AMesajTipi: TMesajTipi; ARenk: TRenk; AMesaj: string);
    procedure Temizle;
    procedure MesajAl(ASiraNo: TISayi4; var AMesajKayit: PMesajKayit);
    property ServisCalisiyor: Boolean read FServisCalisiyor write FServisCalisiyor;
    property ToplamMesaj: TSayi4 read FToplamMesaj;
    property Mesaj[ASiraNo: TSayi4]: PMesajKayit read MesajAl write MesajYaz;
  end;

var
  SistemMesaj0: TSistemMesaj;
  SistemMesajKilit: TSayi4 = 0;

{ TODO : // aşağıdaki tüm çağrılar iptal edilerek bu çağrının içerisine alınacak }
procedure SISTEM_MESAJ(AMesajTipi: TMesajTipi; ARenk: TRenk; AMesaj: string;
  ADegerler: array of const);

procedure SISTEM_MESAJ_YAZI(AMesajTipi: TMesajTipi; ARenk: TRenk; AMesaj: PWideChar);
procedure SISTEM_MESAJ_YAZI(AMesajTipi: TMesajTipi; ARenk: TRenk; AMesaj: PChar; AMesajUz: TISayi4);
procedure SISTEM_MESAJ_YAZI(AMesajTipi: TMesajTipi; ARenk: TRenk; AMesaj1: PChar;
  AMesajUz1: TISayi4; AMesaj2: PChar; AMesajUz2: TISayi4);
procedure SISTEM_MESAJ_YAZI(AMesajTipi: TMesajTipi; ARenk: TRenk;
  ABellekAdres: Isaretci; ABellekUz: TSayi4);
procedure SISTEM_MESAJ_MAC(AMesajTipi: TMesajTipi; ARenk: TRenk; AMesaj: string;
  AMACAdres: TMACAdres);
procedure SISTEM_MESAJ_IP(AMesajTipi: TMesajTipi; ARenk: TRenk; AMesaj: string;
  AIPAdres: TIPAdres);
function UzunlukAl16(ADeger: TSayi4): TSayi4;

implementation

uses genel, cmos, donusum;

{==============================================================================
  oluşturulacak mesajların ana yükleme işlevlerini içerir
 ==============================================================================}
procedure TSistemMesaj.Yukle;
var
  i: TSayi4;
begin

  // sistem mesaj yapılarını ilk değerlerle yükle
  for i := 0 to USTSINIR_MESAJ - 1 do Mesaj[i] := nil;

  // mesaj sıra numarası
  FMesajSN := 0;

  // toplam mesaj sayısını sıfırla
  FToplamMesaj := 0;

  // mesaj servisini başlat
  ServisCalisiyor := True;
end;

function TSistemMesaj.MesajAl(ASiraNo: TSayi4): PMesajKayit;
begin

  // istenen verinin belirtilen aralıkta olup olmadığını kontrol et
  if(ASiraNo >= 0) and (ASiraNo <= USTSINIR_MESAJ) then
    Result := FMesajListesi[ASiraNo]
  else Result := nil;
end;

procedure TSistemMesaj.MesajYaz(ASiraNo: TSayi4; AMesajKayit: PMesajKayit);
begin

  // istenen verinin belirtilen aralıkta olup olmadığını kontrol et
  if(ASiraNo >= 0) and (ASiraNo <= USTSINIR_MESAJ) then
    FMesajListesi[ASiraNo] := AMesajKayit;
end;

{==============================================================================
  mesajı sistem kayıtlarına ekler
 ==============================================================================}
procedure TSistemMesaj.Ekle(AMesajTipi: TMesajTipi; ARenk: TRenk; AMesaj: string);
var
  Saat, Dakika,
  Saniye: TSayi1;
  i, j: TISayi4;
  M: PMesajKayit;
begin

  if not(ServisCalisiyor) then Exit;

  while KritikBolgeyeGir(SistemMesajKilit) = False do;

  // kaydedilecek mesaj sıra numarasını belirle
  Inc(FMesajSN);

  // mesaj sayısının USTSINIR_MESAJ sayısını aşması durumunda tüm mesajları yukarı kaydır
  // ve yeni mesajı en alta ekle
  i := FToplamMesaj;
  if(i >= USTSINIR_MESAJ) then
  begin

    // ilk mesajı sil
    FreeMem(Mesaj[0]);

    // mesajları bir yukarı kaydır
    for j := 1 to USTSINIR_MESAJ - 1 do Mesaj[j - 1] := Mesaj[j];

    Dec(i);

    Mesaj[i] := nil;
  end;

  // yeni mesaj için bellekte yer ayır
  M := PMesajKayit(GetMem(SizeOf(TMesajKayit)));

  // mesajın adresini mesaj listesine kaydet
  Mesaj[i] := M;

  // mesaj tipi
  M^.MesajTipi := AMesajTipi;

  // mesaj sıra numarası
  M^.SiraNo := FMesajSN;

  // mesaj saati
  SaatAl(Saat, Dakika, Saniye);
  M^.Saat := (Saniye shl 16) or (Dakika shl 8) or Saat;

  // mesaj rengi
  M^.Renk := ARenk;

  // mesaj
  M^.Mesaj := AMesaj;

  Inc(i);
  FToplamMesaj := i;

  KritikBolgedenCik(SistemMesajKilit);
end;

{==============================================================================
  mesaj kayıtlarını temizler
 ==============================================================================}
procedure TSistemMesaj.Temizle;
var
  i: TSayi4;
begin

  while KritikBolgeyeGir(SistemMesajKilit) = False do;

  FMesajSN := 0;
  FToplamMesaj := 0;

  for i := 0 to USTSINIR_MESAJ - 1 do
  begin

    if not(Mesaj[i] = nil) then FreeMem(Mesaj[i]);
  end;

  KritikBolgedenCik(SistemMesajKilit);
end;

{==============================================================================
  mesaj kayıtlarından istenen sıradaki mesajı alır
 ==============================================================================}
procedure TSistemMesaj.MesajAl(ASiraNo: TISayi4; var AMesajKayit: PMesajKayit);
var
  M: PMesajKayit;
begin

  while KritikBolgeyeGir(SistemMesajKilit) = False do;

  M := Mesaj[ASiraNo];
  if not(M = nil) then
  begin

    AMesajKayit^.MesajTipi := M^.MesajTipi;
    AMesajKayit^.SiraNo := M^.SiraNo;
    AMesajKayit^.Saat := M^.Saat;
    AMesajKayit^.Renk := M^.Renk;
    AMesajKayit^.Mesaj := M^.Mesaj;
  end;

  KritikBolgedenCik(SistemMesajKilit);
end;

{==============================================================================
  sistem kayıtlarına mesaj ekle
 ==============================================================================}
procedure SISTEM_MESAJ(AMesajTipi: TMesajTipi; ARenk: TRenk; AMesaj: string;
  ADegerler: array of const);
var
  DegerSiraNo, i, j, k,
  Uzunluk, Uzunluk2, Kod: TSayi4;
  s, s2, sUzunluk: string;
  C: Char;
  DegerOkunuyor,
  UzunlukOkunuyor: Boolean;
begin

  DegerOkunuyor := False;
  UzunlukOkunuyor := False;
  DegerSiraNo := 0;
  s := '';
  sUzunluk := '';
  Uzunluk := 0;

  i := Length(AMesaj);
  if(i > 0) then
  begin

    j := 1;
    while (j <= i) do
    begin

      if(DegerOkunuyor) then
      begin

        if(AMesaj[j] = '.') then
        begin

          UzunlukOkunuyor := True;
          sUzunluk := '';
          Inc(j);
          Continue;
        end
        else if(AMesaj[j] in ['0'..'9']) then
        begin

          if(UzunlukOkunuyor) then sUzunluk += AMesaj[j];
          Inc(j);
          Continue;
        end
        else if(AMesaj[j] = 'c') then
        begin

          // sayısal değeri karaktere çevir
          C := TVarRec(ADegerler[DegerSiraNo]).VChar;
          Inc(DegerSiraNo);
          s += C;

          Inc(j);
          DegerOkunuyor := False;
          Continue;
        end
        else if(AMesaj[j] = 's') then
        begin

          // sayısal değeri karaktere çevir
          s2 := TVarRec(ADegerler[DegerSiraNo]).VString^;
          Inc(DegerSiraNo);
          s += s2;

          Inc(j);
          DegerOkunuyor := False;
          Continue;
        end
        else if(AMesaj[j] = 'd') then
        begin

          // sayısal değeri karaktere çevir
          //i := TVarRec(ADegerler[0]).VInteger;
          s2 := IntToStr(TVarRec(ADegerler[DegerSiraNo]).VInteger);

          // mevcut uzunluğun artmasına izin ver (azalmasına izin yok)
          Uzunluk := Length(s2);
          Val(sUzunluk, Uzunluk2, Kod);
          if(Uzunluk2 > Uzunluk) then
          begin

            for k := 1 to Uzunluk2 - Uzunluk do
            begin

              s2 := '0' + s2;
            end;
          end;

          s += s2;
          Inc(DegerSiraNo);

          Inc(j);
          DegerOkunuyor := False;
          UzunlukOkunuyor := False;
          Continue;
        end
        else if(AMesaj[j] = 'x') then
        begin

          // mevcut uzunluğun artmasına izin ver (azalmasına izin yok)
          Uzunluk := UzunlukAl16(TVarRec(ADegerler[DegerSiraNo]).VInteger);
          Val(sUzunluk, Uzunluk2, Kod);
          if(Uzunluk2 >= Uzunluk) then Uzunluk := Uzunluk2;

          // sayısal değeri karaktere çevir
          s2 := hexStr(TVarRec(ADegerler[DegerSiraNo]).VInteger, Uzunluk);

          s += s2;
          Inc(DegerSiraNo);

          Inc(j);
          DegerOkunuyor := False;
          UzunlukOkunuyor := False;
          Continue;
        end
      end
      else if(AMesaj[j] = '%') then
      begin

        DegerOkunuyor := True;
        Inc(j);
        Continue;
      end
      else
      begin

        s += AMesaj[j];
        Inc(j);
      end;
    end;
  end;

  // sistem mesaj servisi çalışıyorsa, mesajı kayıt listesine ekle
  if(SistemMesaj0.ServisCalisiyor) then SistemMesaj0.Ekle(AMesajTipi, ARenk, s);
end;

{==============================================================================
  sistem kayıtlarına mesaj ekle - sadece mesaj (her bir karakterin 2 byte olduğu)
 ==============================================================================}
procedure SISTEM_MESAJ_YAZI(AMesajTipi: TMesajTipi; ARenk: TRenk; AMesaj: PWideChar);
var
  s: string;
begin

  // 16 bitlik UTF karakterini tek bytlık ascii değere çevir
  s := UTF16Ascii(AMesaj);

  SISTEM_MESAJ(AMesajTipi, ARenk, s, []);
end;

{==============================================================================
  sistem kayıtlarına mesaj ekle - sadece mesaj (pchar türünde veri)
 ==============================================================================}
procedure SISTEM_MESAJ_YAZI(AMesajTipi: TMesajTipi; ARenk: TRenk; AMesaj: PChar; AMesajUz: TISayi4);
var
  i: TSayi4;
  p: PChar;
  s: string;
begin

  p := AMesaj;
  s := '';
  for i := 0 to AMesajUz - 1 do s := s + p[i];

  // sistem mesaj servisi çalışıyorsa, mesajı kayıt listesine ekle
  if(SistemMesaj0.ServisCalisiyor) then SistemMesaj0.Ekle(AMesajTipi, ARenk, s);
end;

{==============================================================================
  sistem kayıtlarına mesaj ekle - sadece mesaj (pchar türünde veri)
 ==============================================================================}
procedure SISTEM_MESAJ_YAZI(AMesajTipi: TMesajTipi; ARenk: TRenk; AMesaj1: PChar;
  AMesajUz1: TISayi4; AMesaj2: PChar; AMesajUz2: TISayi4);
var
  i: TSayi4;
  p: PChar;
  s: string;
begin

  s := '';

  p := AMesaj1;
  for i := 0 to AMesajUz1 - 1 do s := s + p[i];

  p := AMesaj2;
  for i := 0 to AMesajUz2 - 1 do s := s + p[i];

  // sistem mesaj servisi çalışıyorsa, mesajı kayıt listesine ekle
  if(SistemMesaj0.ServisCalisiyor) then SistemMesaj0.Ekle(AMesajTipi, ARenk, s);
end;

{==============================================================================
  sistem kayıtlarına mesaj ekle - belirli bellek adresinden, belirli uzunlukta veri
 ==============================================================================}
procedure SISTEM_MESAJ_YAZI(AMesajTipi: TMesajTipi; ARenk: TRenk;
  ABellekAdres: Isaretci; ABellekUz: TSayi4);
var
  i: TSayi4;
  p: PChar;
  s: string;
begin

  p := PChar(ABellekAdres);
  s := '';
  for i := 0 to ABellekUz - 1 do s := s + p[i];

  // sistem mesaj servisi çalışıyorsa, mesajı kayıt listesine ekle
  if(SistemMesaj0.ServisCalisiyor) then SistemMesaj0.Ekle(AMesajTipi, ARenk, s);
end;

{==============================================================================
  sistem kayıtlarına mesaj ekle - mesaj + mac adres birleşimi
 ==============================================================================}
procedure SISTEM_MESAJ_MAC(AMesajTipi: TMesajTipi; ARenk: TRenk; AMesaj: string;
  AMACAdres: TMACAdres);
var
  MACAdres: string[17];
  s: string;
begin

  // mac adres değerini karaktere çevir
  MACAdres := MAC_KarakterKatari(AMACAdres);

  s := AMesaj + MACAdres;

  if(SistemMesaj0.ServisCalisiyor) then SistemMesaj0.Ekle(AMesajTipi, ARenk, s);
end;

{==============================================================================
  sistem kayıtlarına mesaj ekle - mesaj + ip adres birleşimi
 ==============================================================================}
procedure SISTEM_MESAJ_IP(AMesajTipi: TMesajTipi; ARenk: TRenk; AMesaj: string;
  AIPAdres: TIPAdres);
var
  IPAdres: string[15];
  s: string;
begin

  // ip adres değerini karaktere çevir
  IPAdres := IP_KarakterKatari(AIPAdres);

  s := AMesaj + IPAdres;

  if(SistemMesaj0.ServisCalisiyor) then SistemMesaj0.Ekle(AMesajTipi, ARenk, s);
end;

{==============================================================================
  16lı sistemde sayının uzunluk değerini alır
 ==============================================================================}
function UzunlukAl16(ADeger: TSayi4): TSayi4; nostackframe; assembler;
asm

  push  ecx
  mov   ecx,8
@@1:
  test  eax,$F0000000
  jnz   @@2
  shl   eax,4
  loop  @@1

  // tüm haneler 0 ise toplam hane sayısını geri döndür
  mov   ecx,8

@@2:
  mov   eax,ecx
  pop   ecx
end;

end.
