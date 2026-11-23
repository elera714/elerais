{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: n_sistemmesaj.pas
  Dosya İşlevi: hata ayıklama (debug) amaçlı mesaj yönetim işlevlerini içerir

  Güncelleme Tarihi: 30/01/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit n_sistemmesaj;

interface

type
  PSistemMesaj = ^TSistemMesaj;
  TSistemMesaj = object
  private
    FToplamMesaj: TISayi4;
  public
    function Toplam: TISayi4;
    procedure Al(ASiraNo: TISayi4; AMesajKayit: PMesajKayit3);
    procedure YaziEkle(AMesajTipi: TMesajTipi; ARenk: TRenk; AMesaj: string);
    procedure Sayi16Ekle(AMesajTipi: TMesajTipi; ARenk: TRenk; AMesaj: string;
      ADegerler: array of const);
    function DegerBislestir(AMesaj: string; ADegerler: array of const): string;
    procedure Temizle;
  end;

function _SistemMesajToplam: TISayi4; assembler;
procedure _SistemMesajAl(ASiraNo: TISayi4; AMesajKayit: PMesajKayit3); assembler;
procedure _SistemMesajYaziEkle(AMesajTipi: TMesajTipi; ARenk: TRenk; AMesaj: string); assembler;
procedure _SistemMesajSayi16Ekle(AMesajTipi: TMesajTipi; ARenk: TRenk; AMesaj: string;
  ADegerler, ASonDeger: TSayi4); assembler;
procedure _Temizle; assembler;
function UzunlukAl16(ADeger: TSayi4): TSayi4; assembler;

implementation

function TSistemMesaj.Toplam: TISayi4;
begin

  Result := _SistemMesajToplam;
end;

procedure TSistemMesaj.Al(ASiraNo: TISayi4; AMesajKayit: PMesajKayit3);
begin

  _SistemMesajAl(ASiraNo, AMesajKayit);
end;

procedure TSistemMesaj.YaziEkle(AMesajTipi: TMesajTipi; ARenk: TRenk; AMesaj: string);
begin

  _SistemMesajYaziEkle(AMesajTipi, ARenk, AMesaj);
end;

procedure TSistemMesaj.Sayi16Ekle(AMesajTipi: TMesajTipi; ARenk: TRenk; AMesaj: string;
  ADegerler: array of const);
var
  s: string;
begin

  s := DegerBislestir(AMesaj, ADegerler);

  _SistemMesajYaziEkle(AMesajTipi, ARenk, s);
end;

function TSistemMesaj.DegerBislestir(AMesaj: string; ADegerler: array of const): string;
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

          if(UzunlukOkunuyor) then sUzunluk := sUzunluk + AMesaj[j];
          Inc(j);
          Continue;
        end
        else if(AMesaj[j] = 'c') then
        begin

          // sayısal değeri karaktere çevir
          C := TVarRec(ADegerler[DegerSiraNo]).VChar;
          Inc(DegerSiraNo);
          s := s + C;

          Inc(j);
          DegerOkunuyor := False;
          Continue;
        end
        else if(AMesaj[j] = 's') then
        begin

          // sayısal değeri karaktere çevir
          s2 := TVarRec(ADegerler[DegerSiraNo]).VString^;
          Inc(DegerSiraNo);
          s := s + s2;

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

          s := s + s2;
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

          s := s + s2;
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

        s := s + AMesaj[j];
        Inc(j);
      end;
    end;
  end;

  Result := s;
end;

procedure TSistemMesaj.Temizle;
begin

  _Temizle;
end;

function _SistemMesajToplam: TISayi4;
asm
  mov   eax,SISTEMMESAJ_TOPLAM
  int   $34
end;

procedure _SistemMesajAl(ASiraNo: TISayi4; AMesajKayit: PMesajKayit3);
asm
  push  DWORD AMesajKayit
  push  DWORD ASiraNo
  mov   eax,SISTEMMESAJ_MESAJAL
  int   $34
  add   esp,8
end;

procedure _SistemMesajYaziEkle(AMesajTipi: TMesajTipi; ARenk: TRenk; AMesaj: string);
asm
  push  DWORD AMesaj
  push  DWORD ARenk
  push  DWORD AMesajTipi
  mov   eax,SISTEMMESAJ_YAZIEKLE
  int   $34
  add   esp,12
end;

procedure _SistemMesajSayi16Ekle(AMesajTipi: TMesajTipi; ARenk: TRenk; AMesaj: string;
  ADegerler, ASonDeger: TSayi4);
asm
  push  DWORD ASonDeger
  push  DWORD ADegerler
  push  DWORD AMesaj
  push  DWORD ARenk
  push  DWORD AMesajTipi
  mov   eax,SISTEMMESAJ_SAYI16EKLE
  int   $34
  add   esp,20
end;

procedure _Temizle; assembler;
asm
  mov   eax,SISTEMMESAJ_TEMIZLE
  int   $34
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
