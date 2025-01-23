{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: sistemmesaj.pas
  Dosya İşlevi: hata ayıklama (debug) amaçlı mesaj yönetim işlevlerini içerir

  Bilgi: USTSINIR_MESAJ adedince sistem mesajı çekirdekte yukarıdan aşağıya doğru sıralı olarak depolanır,
    tüm mesaj alanları dolduğunda kayıtlı mesajlar bir yukarı kaydırılarak yeni mesaj en alta eklenir

  Güncelleme Tarihi: 22/01/2025

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
    FMesajNo, FToplamMesaj: TISayi4;
  public
    procedure Yukle;
    procedure Ekle(ARenk: TRenk; AMesaj: string);
    procedure Temizle;
    procedure MesajAl(ASiraNo: TISayi4; var AMesaj: PMesaj);
    property ServisCalisiyor: Boolean read FServisCalisiyor write FServisCalisiyor;
    property MesajNo: TISayi4 read FMesajNo;
    property ToplamMesaj: TISayi4 read FToplamMesaj;
  end;

{ TODO : // aşağıdaki tüm çağrılar iptal edilerek bu çağrının içerisine alınacak }
procedure SISTEM_MESAJ(ARenk: TRenk; AMesaj: string; ASayisalDegerler: array of const);

procedure SISTEM_MESAJ_YAZI(ARenk: TRenk; AMesaj: PWideChar);
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
  MesajListesi: array[0..USTSINIR_MESAJ - 1] of PMesaj;

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
  for i := 0 to USTSINIR_MESAJ - 1 do
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
  Saat, Dakika,
  Saniye: TSayi1;
  i, j: TISayi4;
begin

  if not(ServisCalisiyor) then Exit;

  // kaydedilecek mesaj sıra numarasını belirle
  Inc(FMesajNo);

  // mesaj sayısının USTSINIR_MESAJ sayısını aşması durumunda tüm mesajları yukarı kaydır
  // ve yeni mesajı en alta ekle
  i := FToplamMesaj;
  if(i >= USTSINIR_MESAJ) then
  begin

    for j := 1 to USTSINIR_MESAJ - 1 do
    begin

      MesajListesi[j - 1]^.SiraNo := MesajListesi[j]^.SiraNo;
      MesajListesi[j - 1]^.Saat := MesajListesi[j]^.Saat;
      MesajListesi[j - 1]^.Renk := MesajListesi[j]^.Renk;
      MesajListesi[j - 1]^.Mesaj := MesajListesi[j]^.Mesaj;
    end;

    Dec(i);
  end;

  // mesaj sıra numarası
  MesajListesi[i]^.SiraNo := MesajNo;

  // mesaj saati
  SaatAl(Saat, Dakika, Saniye);
  MesajListesi[i]^.Saat := (Saniye shl 16) or (Dakika shl 8) or Saat;

  // mesaj rengi
  MesajListesi[i]^.Renk := ARenk;

  // mesaj
  MesajListesi[i]^.Mesaj := AMesaj;

  Inc(i);
  FToplamMesaj := i;
end;

{==============================================================================
  mesaj kayıtlarını temizler
 ==============================================================================}
procedure TSistemMesaj.Temizle;
var
  i: TSayi4;
begin

  FToplamMesaj := 0;

  for i := 0 to USTSINIR_MESAJ - 1 do
  begin

    MesajListesi[i]^.SiraNo := -1;
    MesajListesi[i]^.Saat := 0;
    MesajListesi[i]^.Renk := RENK_SIYAH;
    MesajListesi[i]^.Mesaj := '';
  end;
end;

{==============================================================================
  mesaj kayıtlarından istenen sıradaki mesajı alır
 ==============================================================================}
procedure TSistemMesaj.MesajAl(ASiraNo: TISayi4; var AMesaj: PMesaj);
begin

  // istenen mesajın belirtilen aralıkta olup olmadığını kontrol et
  if(ASiraNo > -1) and (ASiraNo <= USTSINIR_MESAJ) then
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
procedure SISTEM_MESAJ(ARenk: TRenk; AMesaj: string; ASayisalDegerler: array of const);
var
  DegerSiraNo,
  i, j: TSayi4;
  s, s2: string;
  C: Char;
begin

  DegerSiraNo := 0;
  s := '';

  i := Length(AMesaj);
  if(i > 0) then
  begin

    j := 1;
    while (j <= i) do
    begin

      if(AMesaj[j] = '%') and (AMesaj[j + 1] = 'c') then
      begin

        // sayısal değeri karaktere çevir
        C := TVarRec(ASayisalDegerler[DegerSiraNo]).VChar;
        Inc(DegerSiraNo);
        s += C;

        Inc(j);
      end
      else if(AMesaj[j] = '%') and (AMesaj[j + 1] = 's') then
      begin

        // sayısal değeri karaktere çevir
        s2 := TVarRec(ASayisalDegerler[DegerSiraNo]).VString^;
        Inc(DegerSiraNo);
        s += s2;

        Inc(j);
      end
      else if(AMesaj[j] = '%') and (AMesaj[j + 1] = 'd') then
      begin

        // sayısal değeri karaktere çevir
        //i := TVarRec(ASayisalDegerler[0]).VInteger;
        s2 := IntToStr(TVarRec(ASayisalDegerler[DegerSiraNo]).VInteger);
        Inc(DegerSiraNo);
        s += s2;

        Inc(j);
      end
      else if(AMesaj[j] = '%') and (AMesaj[j + 1] = 'x') then
      begin

        // sayısal değeri karaktere çevir
        s2 := '0x' + hexStr(TVarRec(ASayisalDegerler[DegerSiraNo]).VInteger, 8);
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
