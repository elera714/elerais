{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: sistemmesaj.pas
  Dosya İşlevi: hata ayıklama (debug) amaçlı mesaj yönetim işlevlerini içerir

  Bilgi: USTSINIR_MESAJ adedince sistem mesajı çekirdekte yukarıdan aşağıya doğru sıralı olarak depolanır,
    tüm mesaj alanları dolduğunda kayıtlı mesajlar bir yukarı kaydırılarak yeni mesaj en alta eklenir

  Güncelleme Tarihi: 05/09/2024

 ==============================================================================}
{$mode objfpc}
unit sistemmesaj;

interface

uses paylasim;

type
  PMesaj = ^TMesaj;
  TMesaj = record
    SiraNo: TISayi4;
    Saat: TSayi4;
    Renk: TRenk;
    Mesaj: string;
  end;

type
  PSistemMesaj = ^TSistemMesaj;
  TSistemMesaj = object
  private
    FServisCalisiyor: Boolean;
    FMesajNo, FToplamMesaj: TSayi4;
  public
    procedure Yukle;
    procedure Ekle(ARenk: TRenk; AMesaj: string);
    procedure MesajAl(ASiraNo: TSayi4; var AMesaj: PMesaj);
    property ServisCalisiyor: Boolean read FServisCalisiyor write FServisCalisiyor;
    property MesajNo: TSayi4 read FMesajNo;
    property ToplamMesaj: TSayi4 read FToplamMesaj;
  end;

{ TODO : // aşağıdaki tüm çağrılar iptal edilerek bu çağrının içerisine alınacak }
procedure SISTEM_MESAJ(ARenk: TRenk; AMesaj: string; ASayisalDegerler: array of TSayi4);

procedure SISTEM_MESAJ_YAZI(ARenk: TRenk; AMesaj: PWideChar);
procedure SISTEM_MESAJ_YAZI(ARenk: TRenk; AMesaj1, AMesaj2: string);
procedure SISTEM_MESAJ_YAZI(ARenk: TRenk; AMesaj: PChar; AMesajUz: TISayi4);
procedure SISTEM_MESAJ_YAZI(ARenk: TRenk; AMesaj1: PChar; AMesajUz1: TISayi4;
  AMesaj2: PChar; AMesajUz2: TISayi4);
procedure SISTEM_MESAJ_YAZI(ARenk: TRenk; ABellekAdres: Isaretci; ABellekUz: TSayi4);
procedure SISTEM_MESAJ_S16(ARenk: TRenk; AMesaj: string; ASayi16, AHaneSayisi: TSayi4);
procedure SISTEM_MESAJ2_S16(ARenk: TRenk; AMesaj: string; ASayi16: TSayi8; AHaneSayisi: TSayi4);
procedure SISTEM_MESAJ_MAC(ARenk: TRenk; AMesaj: string; AMACAdres: TMACAdres);
procedure SISTEM_MESAJ_IP(ARenk: TRenk; AMesaj: string; AIPAdres: TIPAdres);

implementation

uses genel, cmos, donusum;

const
  USTSINIR_MESAJ = 32;

var
  MesajBellekAdresi: Isaretci;
  MesajListesi: array[1..USTSINIR_MESAJ] of PMesaj;

{==============================================================================
  oluşturulacak mesajların ana yükleme işlevlerini içerir
 ==============================================================================}
procedure TSistemMesaj.Yukle;
var
  i: TSayi4;
begin

  // mesajlar için bellek ayır
  MesajBellekAdresi := GGercekBellek.Ayir(USTSINIR_MESAJ * SizeOf(TMesaj));

  // bellek girişlerini mesaj yapılarıyla eşleştir
  for i := 1 to USTSINIR_MESAJ do
  begin

    MesajListesi[i] := MesajBellekAdresi;
    MesajBellekAdresi += SizeOf(TMesaj);
  end;

  // mesaj numarası
  FMesajNo := 0;

  // toplam mesaj sayısını sıfırla
  FToplamMesaj := 0;

  // mesaj servisini başlat
  ServisCalisiyor := True;
end;

{==============================================================================
  mesajı sistem kayıtlarına ekler
 ==============================================================================}
procedure TSistemMesaj.Ekle(ARenk: TRenk; AMesaj: string);
var
  Saat, Dakika, Saniye: TSayi1;
  i: TSayi4;
begin

  if not(ServisCalisiyor) then Exit;

  // kaydedilecek mesaj sıra numarasını belirle
  Inc(FMesajNo);
  Inc(FToplamMesaj);

  // mesaj sayısının USTSINIR_MESAJ sayısını aşması durumunda tüm mesajları yukarı kaydır
  // ve yeni mesajı en alta ekle
  if(FToplamMesaj > USTSINIR_MESAJ) then
  begin

    for i := 2 to USTSINIR_MESAJ do
    begin

      MesajListesi[i - 1]^.SiraNo := MesajListesi[i]^.SiraNo;
      MesajListesi[i - 1]^.Saat := MesajListesi[i]^.Saat;
      MesajListesi[i - 1]^.Renk := MesajListesi[i]^.Renk;
      MesajListesi[i - 1]^.Mesaj := MesajListesi[i]^.Mesaj;
    end;

    FToplamMesaj := USTSINIR_MESAJ;
  end;

  // mesaj sıra numarası
  MesajListesi[ToplamMesaj]^.SiraNo := MesajNo;

  // mesaj saati
  SaatAl(Saat, Dakika, Saniye);
  MesajListesi[ToplamMesaj]^.Saat := (Saniye shl 16) or (Dakika shl 8) or Saat;

  // mesaj rengi
  MesajListesi[ToplamMesaj]^.Renk := ARenk;

  // mesaj
  MesajListesi[ToplamMesaj]^.Mesaj := AMesaj;
end;

{==============================================================================
  mesaj kayıtlarından istenen sıradaki mesajı alır
 ==============================================================================}
procedure TSistemMesaj.MesajAl(ASiraNo: TSayi4; var AMesaj: PMesaj);
begin

  // istenen mesajın belirtilen aralıkta olup olmadığını kontrol et
  if(ASiraNo > 0) and (ASiraNo <= USTSINIR_MESAJ) then
  begin

    AMesaj^.SiraNo := MesajListesi[ASiraNo]^.SiraNo;
    AMesaj^.Saat := MesajListesi[ASiraNo]^.Saat;
    AMesaj^.Renk := MesajListesi[ASiraNo]^.Renk;
    AMesaj^.Mesaj := MesajListesi[ASiraNo]^.Mesaj;
  end;
end;

{==============================================================================
  sistem kayıtlarına mesaj ekle
 ==============================================================================}
procedure SISTEM_MESAJ(ARenk: TRenk; AMesaj: string; ASayisalDegerler: array of TSayi4);
var
  i, j, DegerSiraNo: Integer;
  s: string;
  s2: string[10];
begin

  DegerSiraNo := 0;
  s := '';

  i := Length(AMesaj);
  if(i > 0) then
  begin

    j := 1;
    while (j <= i) do begin

      {if(AMesaj[j] = '%') and (AMesaj[j + 1] = 's') then
      begin

        // sayısal değeri karaktere çevir
        s2 := string(ASayisalDegerler[DegerSiraNo]);
        Inc(DegerSiraNo);

        j := Length(AMesaj1);
        if(j > 0) then
        begin

          for i := 1 to j do s := s + AMesaj1[i];
        end;

        Inc(j);
      end
      else} if(AMesaj[j] = '%') and (AMesaj[j + 1] = 'd') then
      begin

        // sayısal değeri karaktere çevir
        s2 := IntToStr(ASayisalDegerler[DegerSiraNo]);
        Inc(DegerSiraNo);
        s += s2;

        Inc(j);
      end
      else if(AMesaj[j] = '%') and (AMesaj[j + 1] = 'x') then
      begin

        // sayısal değeri karaktere çevir
        s2 := '0x' + hexStr(ASayisalDegerler[DegerSiraNo], 8);
        Inc(DegerSiraNo);
        s += s2;

        Inc(j);
      end else s += AMesaj[j];

      Inc(j);
    end;
  end;

  // sistem mesaj servisi çalışıyorsa, mesajı kayıt listesine ekle
  if(GSistemMesaj.ServisCalisiyor) then GSistemMesaj.Ekle(ARenk, s);
end;

{==============================================================================
  sistem kayıtlarına mesaj ekle - sadece mesaj (her bir karakterin 2 byte olduğu)
 ==============================================================================}
procedure SISTEM_MESAJ_YAZI(ARenk: TRenk; AMesaj: PWideChar);
var
  s: string;
begin

  // 16 bitlik UTF karakterini tek bytlık ascii değere çevir
  s := UTF16Ascii(AMesaj);

  SISTEM_MESAJ(ARenk, s, []);
end;

{==============================================================================
  sistem kayıtlarına mesaj ekle - 2 mesajı birleştirerek
 ==============================================================================}
procedure SISTEM_MESAJ_YAZI(ARenk: TRenk; AMesaj1, AMesaj2: string);
var
  i, j: Integer;
  s: string;
begin

  s := '';

  // 1. karakter katarı
  j := Length(AMesaj1);
  if(j > 0) then
  begin

    for i := 1 to j do s := s + AMesaj1[i];
  end;

  // 2. karakter katarı
  j := Length(AMesaj2);
  if(j > 0) then
  begin

    for i := 1 to j do s := s + AMesaj2[i];
  end;

  SISTEM_MESAJ(ARenk, s, []);
end;

{==============================================================================
  sistem kayıtlarına mesaj ekle - sadece mesaj (pchar türünde veri)
 ==============================================================================}
procedure SISTEM_MESAJ_YAZI(ARenk: TRenk; AMesaj: PChar; AMesajUz: TISayi4);
var
  i: Integer;
  p: PChar;
  s: string;
begin

  p := AMesaj;
  s := '';
  for i := 0 to AMesajUz - 1 do s := s + p[i];

  // sistem mesaj servisi çalışıyorsa, mesajı kayıt listesine ekle
  if(GSistemMesaj.ServisCalisiyor) then GSistemMesaj.Ekle(ARenk, s);
end;

{==============================================================================
  sistem kayıtlarına mesaj ekle - sadece mesaj (pchar türünde veri)
 ==============================================================================}
procedure SISTEM_MESAJ_YAZI(ARenk: TRenk; AMesaj1: PChar; AMesajUz1: TISayi4;
  AMesaj2: PChar; AMesajUz2: TISayi4);
var
  i: Integer;
  p: PChar;
  s: string;
begin

  s := '';

  p := AMesaj1;
  for i := 0 to AMesajUz1 - 1 do s := s + p[i];

  p := AMesaj2;
  for i := 0 to AMesajUz2 - 1 do s := s + p[i];

  // sistem mesaj servisi çalışıyorsa, mesajı kayıt listesine ekle
  if(GSistemMesaj.ServisCalisiyor) then GSistemMesaj.Ekle(ARenk, s);
end;

{==============================================================================
  sistem kayıtlarına mesaj ekle - belirli bellek adresinden, belirli uzunlukta veri
 ==============================================================================}
procedure SISTEM_MESAJ_YAZI(ARenk: TRenk; ABellekAdres: Isaretci; ABellekUz: TSayi4);
var
  i: TSayi4;
  p: PChar;
  s: string;
begin

  p := PChar(ABellekAdres);
  s := '';
  for i := 0 to ABellekUz - 1 do s := s + p[i];

  // sistem mesaj servisi çalışıyorsa, mesajı kayıt listesine ekle
  if(GSistemMesaj.ServisCalisiyor) then GSistemMesaj.Ekle(ARenk, s);
end;

{==============================================================================
  sistem kayıtlarına mesaj ekle - mesaj + 16lı sayı sisteminde sayı birleşimi - 32 bit
 ==============================================================================}
procedure SISTEM_MESAJ_S16(ARenk: TRenk; AMesaj: string; ASayi16, AHaneSayisi: TSayi4);
var
  Deger16: string[10];
  s: string;
begin

  // sayısal değeri karaktere çevir
  Deger16 := '0x' + hexStr(ASayi16, AHaneSayisi);

  s := AMesaj + Deger16;

  if(GSistemMesaj.ServisCalisiyor) then GSistemMesaj.Ekle(ARenk, s);
end;

{==============================================================================
  sistem kayıtlarına mesaj ekle - mesaj + 16lı sayı sisteminde sayı birleşimi - 64 bit
 ==============================================================================}
procedure SISTEM_MESAJ2_S16(ARenk: TRenk; AMesaj: string; ASayi16: TSayi8; AHaneSayisi: TSayi4);
var
  Deger16: string[18];
  s: string;
begin

  // sayısal değeri karaktere çevir
  Deger16 := '0x' + hexStr(ASayi16, AHaneSayisi);

  s := AMesaj + Deger16;

  if(GSistemMesaj.ServisCalisiyor) then GSistemMesaj.Ekle(ARenk, s);
end;

{==============================================================================
  sistem kayıtlarına mesaj ekle - mesaj + mac adres birleşimi
 ==============================================================================}
procedure SISTEM_MESAJ_MAC(ARenk: TRenk; AMesaj: string; AMACAdres: TMACAdres);
var
  MACAdres: string[17];
  s: string;
begin

  // mac adres değerini karaktere çevir
  MACAdres := MAC_KarakterKatari(AMACAdres);

  s := AMesaj + MACAdres;

  if(GSistemMesaj.ServisCalisiyor) then GSistemMesaj.Ekle(ARenk, s);
end;

{==============================================================================
  sistem kayıtlarına mesaj ekle - mesaj + ip adres birleşimi
 ==============================================================================}
procedure SISTEM_MESAJ_IP(ARenk: TRenk; AMesaj: string; AIPAdres: TIPAdres);
var
  IPAdres: string[15];
  s: string;
begin

  // ip adres değerini karaktere çevir
  IPAdres := IP_KarakterKatari(AIPAdres);

  s := AMesaj + IPAdres;

  if(GSistemMesaj.ServisCalisiyor) then GSistemMesaj.Ekle(ARenk, s);
end;

end.
