{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: src_sb.pas
  Dosya Ýþlevi: sound blaster ses kartý sürücüsü

  Güncelleme Tarihi: 06/09/2026

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

uses zamanlayici, sistemmesaj, port, dosyalar;

{==============================================================================
  sound blaster ses kartý yükleme kýsmý
 ==============================================================================}
procedure Yukle;
var
  TemelAdres: TSayi2;
  AygitAdi: string;
  i: TSayi4;
begin

  SISTEM_MESAJ(mtBilgi, RENK_MAVI, '+ Ses aygýtlarý yükleniyor...', []);

  for i := 1 to 8 do
  begin

    if(i <> 7) then
    if(DSPSifirla($200 + (i shl 4))) then
    begin

      TemelAdres := $200 + (i shl 4);

      if(DSPSurumAl(TemelAdres) = $100) then
        AygitAdi := 'Sound Blaster'
      else if(DSPSurumAl(TemelAdres) = $105) then
        AygitAdi := 'Sound Blaster 1.5'
      else if(DSPSurumAl(TemelAdres) = $200) then
        AygitAdi := 'Sound Blaster Pro 2'
      else if(DSPSurumAl(TemelAdres) = $300) then
        AygitAdi := 'Sound Blaster Pro 3'
      else if(Hi(DSPSurumAl(TemelAdres)) >= 4) then
        AygitAdi := 'Sound Blaster 16/ASP/AWE 32/AWE 64'
      else AygitAdi := 'Bilinmeyen ses kartý';

      SISTEM_MESAJ(mtBilgi, RENK_SIYAH, '  +-> Bulunan ses kartý: %s', [AygitAdi]);

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
  GZamanlayicilar.BekleMS(10);
  PortYaz1(APortNo + $6, 0);
  GZamanlayicilar.BekleMS(10);

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
  Surum: TSayi2;
begin

  DSPYaz(APortNo, $E1);
  Surum := DSPOku(APortNo);
  Result := DSPOku(APortNo) + (Surum shl 8);
end;

procedure SesDosyasiOynat;
var
  DosyaBellek: Isaretci;
  DosyaKimlik: TKimlik;
  DosyaUzunluk: TSayi4;
begin

  if not(DSPSifirla($220)) then

    SISTEM_MESAJ(mtHata, RENK_SIYAH, 'Ses kartý sýfýrlama hatasý!', [])
  else
  begin

    HoparloruAc;
    SesKuvvetiniAyarla($22);

    AssignFile(DosyaKimlik, 'disk1:\2.wav');
    Reset(DosyaKimlik);
    if(IOResult = HATA_DOSYA_ISLEM_BASARILI) then
    begin

      // dosya uzunluðunu al
      DosyaUzunluk := FileSize(DosyaKimlik);

      SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'Ses dosya uzunluðu: %d', [DosyaUzunluk]);

      // dosyanýn çalýþtýrýlmasý için bellekte yer ayýr
      DosyaBellek := GetMem(DosyaUzunluk);
      if(DosyaBellek <> nil) then
      begin

        SISTEM_MESAJ(mtBilgi, RENK_SIYAH, 'Dosya için ayrýlan bellek adresi: $%.8x',
          [TSayi4(DosyaBellek)]);

        // dosyayý hedef adrese kopyala
        Read(DosyaKimlik, DosyaBellek);

        DMAAkis(DosyaBellek + 44, DosyaUzunluk - 44);

        // dosyayý kapat
        CloseFile(DosyaKimlik);

        FreeMem(DosyaBellek, DosyaUzunluk);
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
  iSayfa, iUzunluk: TSayi2;
  iBellek: TSayi4;
begin

  iUzunluk := ADosyaUzunluk - 1;
  iSayfa := 0;
  iBellek := TSayi4(ADosyaBellek);

  PortYaz1($A, $4 + KANAL);
  PortYaz1($C, $0);
  PortYaz1($B, MODYAZMAC);
  PortYaz1(EKLE, iBellek and $FF);
  PortYaz1(EKLE, (iBellek and $FFFF) Div $100);
  If (iBellek and 65536) > 0  then iSayfa := iSayfa + 1;
  If (iBellek and 131072) > 0 then iSayfa := iSayfa + 2;
  If (iBellek and 262144) > 0 then iSayfa := iSayfa + 4;
  If (iBellek and 524288) > 0 then iSayfa := iSayfa + 8;
  PortYaz1(SAYFA, iSayfa);
  PortYaz1(UZUNLUK, iUzunluk And $FF);
  PortYaz1(UZUNLUK, (iUzunluk And $FFFF) div $100);
  PortYaz1($A, KANAL);

  DSPYaz($220, $40);
  DSPYaz($220, 256 - (1000000 Div FREKANS));
  DSPYaz($220, $14);
  DSPYaz($220, iUzunluk and $FF);
  DSPYaz($220, (iUzunluk and $FFFF) div $100);
end;

end.
