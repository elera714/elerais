{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: sanalbellek.pas
  Dosya İşlevi: sanal bellek (virtual memory) işlevlerini içerir

  Güncelleme Tarihi: 22/10/2019

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit sanalbellek;

interface

uses paylasim;

procedure Yukle;
procedure SanalBellekEslestir(ASanalBellekAdresi, AGercekBellekAdresi, ASayfaSayisi: TSayi4;
  ABayrak: TSayi1);
procedure SanalBellekIptal(ASanalBellekAdresi, ASayfaSayisi: TSayi4);
function GercekBellekAdresiniAl(ASanalBellekAdresi: TSayi4): TSayi4;
procedure ProgramIcinSayfaOlustur;

implementation

{==============================================================================
  sanal belleği ilk değerlerle yükler
 ==============================================================================}
procedure Yukle;
var
  _BellekAdresi: PSayi4;
  i, j: TSayi4;
begin

  // 4GB'lık bellek sayfalamanın içerisine dahil ediliyor
  // 4GB belleği sayfalamaya dahil etmek için 4K'lık dizin + 4M'lık tablonun
  // oluşturulacağı fiziksel belleğe ihtiyaç vardır

  // dizin girişleri
  // her bir girdi sayfa tablosu için 4MB'lık bir alan adreslemesi sağlamaktadır
  _BellekAdresi := PSayi4(GERCEKBELLEK_DIZINADRESI);
  j := GERCEKBELLEK_TABLOADRESI;
  for i := 0 to 1024 - 1 do
  begin

    _BellekAdresi^ := j or (SAYFA_YAZILABILIR or SAYFA_MEVCUT);
    Inc(_BellekAdresi);
    j += 4096;
  end;

  // sayfa girişleri
  // her bir 1024 girdi 4 MB'dır. (1024 * 1024 = 4GB)
  // 16 * 4 = 64MB'lık alanın sayfalanması
  _BellekAdresi := PSayi4(GERCEKBELLEK_TABLOADRESI);
  j := 0;
  // for i := 0 to (1024 * 16) - 1 do
  for i := 0 to (1024 * 1024) - 1 do
  begin

    _BellekAdresi^ := j or (SAYFA_YAZILABILIR or SAYFA_MEVCUT);
    Inc(_BellekAdresi);
    j += 4096;
  end;

  // 1 sayfa = 4K, 1024 sayfa = 4M,
  {SanalBellekEslestir(VideoDriverLFBAddr, $E0000000, 2048,
    SAYFA_MEVCUT or SAYFA_YAZILABILIR);}
end;

// sanal belleği fiziksel bellek ile eşleştirir
procedure SanalBellekEslestir(ASanalBellekAdresi, AGercekBellekAdresi, ASayfaSayisi: TSayi4;
  ABayrak: TSayi1);
var
  _SanalBellek: PLongWord;
  _GercekBellek: LongWord;
  i: Integer;
begin

  _SanalBellek := PSayi4(GERCEKBELLEK_TABLOADRESI + ((ASanalBellekAdresi and $FFFFF000) shr 10));
  _GercekBellek := AGercekBellekAdresi;

  for i := 0 to ASayfaSayisi - 1 do
  begin

    _SanalBellek^ := _GercekBellek or ABayrak;
    Inc(_SanalBellek);
    _GercekBellek += 4096;
  end;

  // TLB belleğini tazele
  _GercekBellek := ASanalBellekAdresi and $FFFFF000;

  for i := 0 to ASayfaSayisi - 1 do
  begin

  asm
    push    eax
    mov     eax,_GercekBellek
    invlpg  [eax]
    pop     eax
  end;

    _GercekBellek += 4096;
  end;
end;

// sanal bellek adreslemesini iptal eder
procedure SanalBellekIptal(ASanalBellekAdresi, ASayfaSayisi: TSayi4);
begin

  SanalBellekEslestir(ASanalBellekAdresi, 0, ASayfaSayisi, 0);
end;

// sanal belleğin fiziksel adres karşılığını alır
function GercekBellekAdresiniAl(ASanalBellekAdresi: TSayi4): TSayi4;
var
  _SanalBellek: PSayi4;
begin

  _SanalBellek := PSayi4(GERCEKBELLEK_TABLOADRESI + ((ASanalBellekAdresi and $FFFFF000) shr 10));
  Result := (_SanalBellek^ and $FFFFF000);
end;

procedure ProgramIcinSayfaOlustur;
var
  _HedefBellek: PSayi4;
  i, j: TSayi4;
begin

  // 4GB'lık bellek sayfalamanın içerisine dahil ediliyor
  // 4GB belleği sayfalamaya dahil etmek için 4K'lık dizin + 4M'lık tablonun
  // oluşturulacağı fiziksel belleğe ihtiyaç vardır

  // dizin girişleri
  // her bir girdi sayfa tablosu için 4MB'lık bir alan adreslemesi sağlamaktadır
  _HedefBellek := PSayi4($2800000);
  j := $2900000;
  for i := 0 to 1024 - 1 do
  begin

    _HedefBellek^ := j or (SAYFA_YAZILABILIR or SAYFA_MEVCUT);
    Inc(_HedefBellek);
    j += 4096;
  end;

  // sayfa girişleri
  // 16 * 4 = 64MB'lık alanın sayfalanması
  // her bir 1024 girdi 4 MB'dır
  _HedefBellek := PLongWord($2900000);
  j := $2700000; //0;
  // for i := 0 to (1024 * 64) - 1 do
  for i := 0 to (1024 * 1024) - 1 do
  begin

    _HedefBellek^ := j or (SAYFA_YAZILABILIR or SAYFA_MEVCUT);
    Inc(_HedefBellek);
    j += 4096;
  end;
end;

end.
