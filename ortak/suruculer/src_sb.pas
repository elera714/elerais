{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: src_sb.pas
  Dosya Ýþlevi: sound blaster ses kartý sürücüsü

  Güncelleme Tarihi: 20/09/2024

 ==============================================================================}
{$mode objfpc}
unit src_sb;

interface

uses paylasim;

procedure Yukle;
function DSPSifirla(APortNo: TSayi2): Boolean;
function DSPOku(APortNo: TSayi2): TSayi1;
procedure DSPYaz(APortNo: TSayi2; ADeger: TSayi1);
function DSPSurumAl(APortNo: TSayi2): TSayi2;
procedure SesDosyasiOynat;
procedure HoparloruAc;
procedure HoparloruKapat;
procedure SesKuvvetiniAyarla(ADeger: Byte);
procedure DMAAkis(ADosyaBellek: Isaretci; ADosyaUzunluk: TSayi4);

implementation

uses zamanlayici, sistemmesaj, port, dosya, genel;

{==============================================================================
  sound blaster ses kartý yükleme kýsmý
 ==============================================================================}
procedure Yukle;
var
  _TemelAdres: TSayi2;
  _AygitAdi: string;
  i: TSayi1;
begin

  SISTEM_MESAJ(RENK_MAVI, '+ Ses aygýtlarý yükleniyor...', []);

  for i := 1 to 8 do
  begin

    if(i <> 7) then
    if(DSPSifirla($200 + (i shl 4))) then
    begin

      _TemelAdres := $200 + (i shl 4);

      if(DSPSurumAl(_TemelAdres) = $100) then
        _AygitAdi := 'Sound Blaster'
      else if(DSPSurumAl(_TemelAdres) = $105) then
        _AygitAdi := 'Sound Blaster 1.5'
      else if(DSPSurumAl(_TemelAdres) = $200) then
        _AygitAdi := 'Sound Blaster Pro 2'
      else if(DSPSurumAl(_TemelAdres) = $300) then
        _AygitAdi := 'Sound Blaster Pro 3'
      else if(Hi(DSPSurumAl(_TemelAdres)) >= 4) then
        _AygitAdi := 'Sound Blaster 16/ASP/AWE 32/AWE 64'
      else _AygitAdi := 'Bilinmeyen ses kartý';

      SISTEM_MESAJ(RENK_ACIKMAVI, '  +-> Bulunan ses kartý: ' + _AygitAdi, []);

      Exit;
    end;
  end;
end;

{==============================================================================
  ses kartýný sýfýrla iþlemi
 ==============================================================================}
function DSPSifirla(APortNo: TSayi2): Boolean;
begin

  PortYaz1(APortNo + $6, 1);
  BekleMS(10);
  PortYaz1(APortNo + $6, 0);
  BekleMS(10);

  // aygýt resetlendi mi ?
  if(PortAl1(APortNo + $E) and $80 = $80) and (PortAl1(APortNo + $A) = $AA) then

    DSPSifirla := True
  else DSPSifirla := False;
end;

{==============================================================================
  aygýttan veri okuma iþlemi
 ==============================================================================}
function DSPOku(APortNo: TSayi2): TSayi1;
begin

  while (PortAl1(APortNo + $E) and $80 = 0) do;
  DSPOku := PortAl1(APortNo + $A);
end;

{==============================================================================
  aygýta veri gönderme iþlemi
 ==============================================================================}
procedure DSPYaz(APortNo: TSayi2; ADeger: TSayi1);
begin

  while (PortAl1(APortNo + $C) and $80 <> 0) do;
  PortYaz1(APortNo + $C, ADeger);
end;

{==============================================================================
  aygýtýn modelini alýr
 ==============================================================================}
function DSPSurumAl(APortNo: TSayi2): TSayi2;
var
  _Surum: TSayi2;
begin

  DSPYaz(APortNo, $E1);
  _Surum := DSPOku(APortNo);
  Result := DSPOku(APortNo) + (_Surum shl 8);
end;

procedure SesDosyasiOynat;
var
  _DosyaBellek: Isaretci;
  _DosyaKimlik: TKimlik;
  _DosyaUzunluk: TSayi4;
begin

  if not(DSPSifirla($220)) then

    SISTEM_MESAJ(RENK_KIRMIZI, 'Ses kartý sýfýrlama hatasý!', [])
  else
  begin

    HoparloruAc;
    SesKuvvetiniAyarla($22);

    AssignFile(_DosyaKimlik, 'disk1:\2.wav');
    Reset(_DosyaKimlik);
    if(IOResult = 0) then
    begin

      // dosya uzunluðunu al
      _DosyaUzunluk := FileSize(_DosyaKimlik);

      SISTEM_MESAJ_S16(RENK_MAVI, 'Ses dosya uzunluðu: ', _DosyaUzunluk, 8);

      // dosyanýn çalýþtýrýlmasý için bellekte yer ayýr
      _DosyaBellek := GGercekBellek.Ayir(_DosyaUzunluk);
      if(_DosyaBellek <> nil) then
      begin

        SISTEM_MESAJ_S16(RENK_MAVI, 'Dosya için ayrýlan bellek adresi: ', Integer(_DosyaBellek), 8);

        // dosyayý hedef adrese kopyala
        Read(_DosyaKimlik, _DosyaBellek);

        DMAAkis(_DosyaBellek + 44, _DosyaUzunluk - 44);

        // dosyayý kapat
        CloseFile(_DosyaKimlik);

        GGercekBellek.YokEt(_DosyaBellek, _DosyaUzunluk);
      end;
    end;
  end;
end;

procedure HoparloruAc;
begin

  DSPYaz($220, $D1);
end;

procedure HoparloruKapat;
begin

  DSPYaz($220, $D1);
end;

procedure SesKuvvetiniAyarla(ADeger: TSayi1);
begin

  PortYaz1($220 + 4, ADeger);
  PortYaz1($220 + 5, $DD);
end;

procedure DMAAkis(ADosyaBellek: Isaretci; ADosyaUzunluk: TSayi4);
const
  KANAL = 1;
  MODYAZMAC = $49;
  EKLE = $02;
  SAYFA = $83;
  UZUNLUK = $03;
  FREKANS = 11000; { max. 29999 }
var
  _Sayfa, _Uzunluk: TSayi2;
  _Bellek: TSayi4;
begin

  _Uzunluk := ADosyaUzunluk - 1;
  _Sayfa := 0;
  _Bellek := TSayi4(ADosyaBellek);

  PortYaz1($A, $4 + KANAL);
  PortYaz1($C, $0);
  PortYaz1($B, MODYAZMAC);
  PortYaz1(EKLE, _Bellek and $FF);
  PortYaz1(EKLE, (_Bellek and $FFFF) Div $100);
  If (_Bellek and 65536) > 0  then _Sayfa := _Sayfa + 1;
  If (_Bellek and 131072) > 0 then _Sayfa := _Sayfa + 2;
  If (_Bellek and 262144) > 0 then _Sayfa := _Sayfa + 4;
  If (_Bellek and 524288) > 0 then _Sayfa := _Sayfa + 8;
  PortYaz1(SAYFA, _Sayfa);
  PortYaz1(UZUNLUK, _Uzunluk And $FF);
  PortYaz1(UZUNLUK, (_Uzunluk And $FFFF) div $100);
  PortYaz1($A, KANAL);

  DSPYaz($220, $40);
  DSPYaz($220, 256 - (1000000 Div FREKANS));
  DSPYaz($220, $14);
  DSPYaz($220, _Uzunluk and $FF);
  DSPYaz($220, (_Uzunluk and $FFFF) div $100);
end;

end.
