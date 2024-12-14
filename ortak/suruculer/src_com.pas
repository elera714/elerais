{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: src_com.pas
  Dosya İşlevi: COM iletişim sürücüsü

  Güncelleme Tarihi: 13/05/2020

 ==============================================================================}
{$mode objfpc}
unit src_com;

{==============================================================================

  COM iletişim rutinlerini VirtualBox'ta (6.0.12) kullanmak için:

  Ayarlar:
  -------------------------------
  [x] Seri Bağlantı Noktasını Etkinleştir
  Bağlantı Noktası Numarası: COM1
  Bağlantı Noktası Kipi: Ham Dosya
  Yol / Adres: c:\iletisim1.txt

  Not1: Yol / Adres: com1, com2 gibi isimler geçersiz.
  Not2: COMIletisimVeriGonder(1, 'Mesaj' + #13#10); komutuyla COM1 iletişim
    portuna bilgi gönderilebilir

 ==============================================================================}
interface

uses paylasim, port;

type
  TCOMIletisim = record
    PortNo: TSayi4;
    Mevcut: Boolean;
  end;

procedure Yukle;
function COMIletisimAygitiVarMi(ACOMIletisim: TCOMIletisim): Boolean;
procedure COMIletisimAygitiniAyarla(ACOMIletisim: TCOMIletisim);
procedure Yaz(APortNo: TSayi4; AVeri: string);
procedure Yaz(APortNo: TSayi4; ABellekAdresi: PChar; AUzunluk: TSayi4);

implementation

{==============================================================================
  COM iletişim aygıt listesi
 ==============================================================================}
var
  TCOMIletisimListesi: array[1..4] of TCOMIletisim = (
    (PortNo: $3F8; Mevcut: False), (PortNo: $2F8; Mevcut: False),
    (PortNo: $3E8; Mevcut: False), (PortNo: $2E8; Mevcut: False));

{==============================================================================
  COM iletişim aygıt yükleme işlevlerini içerir
 ==============================================================================}
procedure Yukle;
var
  i: TSayi4;
begin

  for i := 1 to 4 do
  begin

    if(COMIletisimAygitiVarMi(TCOMIletisimListesi[i])) then
    begin

      TCOMIletisimListesi[i].Mevcut := True;
      COMIletisimAygitiniAyarla(TCOMIletisimListesi[i]);
    end;
  end;
end;

{==============================================================================
  COM iletişim aygıtının sistemde mevcut olup olmadığını kontrol eder
 ==============================================================================}
function COMIletisimAygitiVarMi(ACOMIletisim: TCOMIletisim): Boolean;
var
  _Deger: TSayi1;
begin

  _Deger := PortAl1(ACOMIletisim.PortNo + 4);
  PortYaz1(ACOMIletisim.PortNo + 4, $10);
  _Deger := PortAl1(ACOMIletisim.PortNo + 6);

  if((_Deger and $F0) = 0) then

    Result := True
  else Result := False;
end;

{==============================================================================
  COM iletişim aygıtının çalışma değerlerini belirler
 ==============================================================================}
procedure COMIletisimAygitiniAyarla(ACOMIletisim: TCOMIletisim);
begin

  // kesmeleri pasifleştir
  PortYaz1(ACOMIletisim.PortNo + 1, 0);

  // DLAB aktif
  PortYaz1(ACOMIletisim.PortNo + 3, $80);

  // veri iletim hızı 9600. 115200 / 9600 = 12 (0x000C)
  PortYaz1(ACOMIletisim.PortNo, $C);       // Divisor Latch Low Byte
  PortYaz1(ACOMIletisim.PortNo + 1, 0);    // Divisor Latch High Byte

  // eşlik yok (parity), 1 dur biti, 8 bit veri
  PortYaz1(ACOMIletisim.PortNo + 3, 3);

  // modem kontrol yazmacı
  PortYaz1(ACOMIletisim.PortNo + 4, 0);
end;

{==============================================================================
  COM iletişim aygıtı üzerinden veri gönderir
 ==============================================================================}
procedure Yaz(APortNo: TSayi4; AVeri: string);
var
  VeriUzunluk, i: TSayi4;
  _Deger: TSayi1;
begin

  // port aralık kontrolü
  if(APortNo < 1) or (APortNo > 4) then Exit;

  // aygıt sistemde mevcut mu ?
  if(TCOMIletisimListesi[APortNo].Mevcut = False) then Exit;

  // port'a gönderilecek verinin uzunluğunu al
  VeriUzunluk := Length(AVeri);
  if(VeriUzunluk = 0) then Exit;

  for i := 1 to VeriUzunluk do
  begin

    // LSR bit 5 = 1 oluncaya kadar bekle (Empty Transmitter Holding Register)
    repeat

      _Deger := PortAl1(TCOMIletisimListesi[APortNo].PortNo + 5);
    until ((_Deger and $20) <> 0);

    // veriyi port'a gönder
    PortYaz1(TCOMIletisimListesi[APortNo].PortNo, Byte(AVeri[i]));
  end;
end;

{==============================================================================
  COM iletişim aygıtı üzerinden veri gönderir
 ==============================================================================}
procedure Yaz(APortNo: TSayi4; ABellekAdresi: PChar; AUzunluk: TSayi4);
var
  i: TSayi4;
  _Deger: TSayi1;
  p: PChar;
begin

  // port aralık kontrolü
  if(APortNo < 1) or (APortNo > 4) then Exit;

  // aygıt sistemde mevcut mu ?
  if(TCOMIletisimListesi[APortNo].Mevcut = False) then Exit;

  // port'a gönderilecek verinin uzunluğunu al
  if(AUzunluk = 0) then Exit;

  p := ABellekAdresi;

  for i := 1 to AUzunluk do
  begin

    // LSR bit 5 = 1 oluncaya kadar bekle (Empty Transmitter Holding Register)
    repeat

      _Deger := PortAl1(TCOMIletisimListesi[APortNo].PortNo + 5);
    until ((_Deger and $20) <> 0);

    // veriyi port'a gönder
    PortYaz1(TCOMIletisimListesi[APortNo].PortNo, TSayi1(p^));

    Inc(p);
  end;
end;

end.
