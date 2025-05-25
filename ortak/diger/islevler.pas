{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: islevler.pas
  Dosya İşlevi: genel işlevleri içerir

  Güncelleme Tarihi: 02/05/2025

 ==============================================================================}
{$mode objfpc}
{$asmmode intel}
unit islevler;

interface

uses paylasim;

procedure DosyaYolunuParcala2(const ATamDosyaYolu: string; var ASurucu,
  AKlasor, ADosyaAdi: string);
function DosyaAdiniAl(const ADosyaAdiVeUzanti: string): string;
function IPAdresleriniKarsilastir(AIPAdres1, AIPAdres2: TIPAdres): Boolean;
procedure DosyaParcalariniBirlestir(ADizinGirisi: Isaretci);
procedure DosyaParcasiniBasaEkle(AEklenecekVeri, AHedefBellek: Isaretci);
function BuyutVeTamamla(AGrupAdi: string; AUzunluk: TSayi4): string;
function Trim(const S: string): string;
procedure BellekDoldur(ABellekAdresi: Isaretci; AUzunluk: TSayi4; ADeger: TSayi1);
procedure Tasi2(AKaynak, AHedef: Isaretci; AUzunluk: TSayi4);
function Karsilastir(AKaynak, AHedef: Isaretci; AUzunluk: TSayi4): TSayi4;
function IPKarsilastir(IP1, IP2: TIPAdres): Boolean;
function IPKarsilastir2(AGonderenIP, ABenimIP: TIPAdres): Boolean;
function IPAdresiAyniAgdaMi(AGonderenIP: TIPAdres): Boolean;
function ELRTarih(AGun, AAy, AYil: TSayi2): TSayi4;
function FatXTarih2ELRTarih(ATarih: TSayi2): TSayi4;
function ELRSaat(ASaat, ADakika, ASaniye: TSayi1): TSayi4;
function FatXSaat2ELRSaat(ASaat: TSayi2): TSayi4;
procedure DosyaKopyala(AKaynakDosya, AHedefDosya: string);

implementation

uses dosya;

{==============================================================================
  sürücü + dizin + dosya yolunu parçalara ayırır
  giriş: disk1:\klasör1\dosya1.c
  çıktı: ASurucu = disk1, AKlasor = \klasör1\, ADosyaAdi = dosya1.c
 ==============================================================================}
procedure DosyaYolunuParcala2(const ATamDosyaYolu: string; var ASurucu,
  AKlasor, ADosyaAdi: string);
var
  i: TSayi4;
  s: string;
begin

  // örnek değer: disk1:\klasör1\dosya1.c
  i := Pos(':', ATamDosyaYolu);
  if(i = 0) then
  begin

    ASurucu := AcilisSurucuAygiti;
    AKlasor := '\' + KLASOR_PROGRAM + '\';

    // dosya uzantısı yoksa uzantı olarak çalıştırılabilir dosya uzantısı ekle ".c"
    i := Pos('.', ATamDosyaYolu);
    if(i = 0) then
      ADosyaAdi := ATamDosyaYolu + '.c'
    else ADosyaAdi := ATamDosyaYolu;
  end
  else
  begin

    // ASurucu = disk1
    ASurucu := Copy(ATamDosyaYolu, 1, i - 1);
    s := Copy(ATamDosyaYolu, i + 1, Length(ATamDosyaYolu) - i);

    i := Length(s);
    while s[i] <> '\' do Dec(i);

    // AKlasor = \klasör1\
    AKlasor := Copy(s, 1, i);

    // ADosyaAdi = dosya1.c
    ADosyaAdi := Copy(s, i + 1, Length(s) - i);
  end;
end;

// dosya adı + uzantı bileşiminden dosya adını alır
function DosyaAdiniAl(const ADosyaAdiVeUzanti: string): string;
var
  i: TSayi4;
begin

  i := Pos('.', ADosyaAdiVeUzanti);

  if(i = 0) then

    Result := ADosyaAdiVeUzanti
  else Result := Copy(ADosyaAdiVeUzanti, 1, i - 1);
end;

{==============================================================================
  2 ip adresini karşılaştırır
 ==============================================================================}
function IPAdresleriniKarsilastir(AIPAdres1, AIPAdres2: TIPAdres): Boolean;
var
  i: TISayi4;
begin

  Result := False;

  for i := 0 to 3 do
  begin

    if(AIPAdres1[i] <> AIPAdres2[i]) then Exit;
  end;

  Result := True;
end;

// fat32 dosya sistemindeki widechar türündeki dosya ad parçalarını birleştirir
procedure DosyaParcalariniBirlestir(ADizinGirisi: Isaretci);
var
  BellekU, i: TISayi4;
  p: PChar;
  K1, K2: Char;
  Bellek: array[0..27] of Char;     // azami bellek: 13 * 2 = 26 karakter + 2 byte #0 karakter
  Tamamlandi: Boolean;
begin

  Tamamlandi := False;

  // 1. parça - (5 (widechar) * 2 = 10 byte)
  BellekU := 0;
  p := PChar(ADizinGirisi + 1);
  for i := 0 to 4 do
  begin

    K1 := p^;
    Inc(p);
    K2 := p^;
    Inc(p);

    if(K1 <> #0) or (K2 <> #0) then
    begin

      Bellek[BellekU + 0] := K1;
      Bellek[BellekU + 1] := K2;
      Inc(BellekU, 2);
    end
    else
    begin

      Tamamlandi := True;
      Break;
    end;
  end;

  // 2. parça - (6 (widechar) * 2 = 12 byte)
  if not(Tamamlandi) then
  begin

    p := PChar(ADizinGirisi + 14);
    for i := 0 to 5 do
    begin

      K1 := p^;
      Inc(p);
      K2 := p^;
      Inc(p);

      if(K1 <> #0) or (K2 <> #0) then
      begin

        Bellek[BellekU + 0] := K1;
        Bellek[BellekU + 1] := K2;
        Inc(BellekU, 2);
      end
      else
      begin

        Tamamlandi := True;
        Break;
      end;
    end;
  end;

  // 3. parça - (2 (widechar) * 2 = 4 byte)
  if not(Tamamlandi) then
  begin

    p := PChar(ADizinGirisi + 28);
    for i := 0 to 1 do
    begin

      K1 := p^;
      Inc(p);
      K2 := p^;
      Inc(p);

      if(K1 <> #0) or (K2 <> #0) then
      begin

        Bellek[BellekU + 0] := K1;
        Bellek[BellekU + 1] := K2;
        Inc(BellekU, 2);
      end
      else
      begin

        Tamamlandi := True;
        Break;
      end;
    end;
  end;

  // çift 0 sonlandırma
  Bellek[BellekU + 0] := #0;
  Bellek[BellekU + 1] := #0;
  Inc(BellekU, 2);

  // parçayı bir önceki parçaların önüne ekle
  DosyaParcasiniBasaEkle(@Bellek[0], @UzunDosyaAdi[0]);
end;

// dosya ad parçasını diğer parçaların önüne ekler
// AEklenecekVeri = başa eklenecek bellek bölgesi
// AHedefBellek = verilerin birleştirileceği bellek bölgesi
procedure DosyaParcasiniBasaEkle(AEklenecekVeri, AHedefBellek: Isaretci);
var
  p1, p2: PChar;
  K1, K2: Char;
  Bellek: array[0..511] of Char;    // azami dosya ad uzunluğu
  BellekSiraNo, Bellek2SiraNo, i: TISayi4;
begin

  // 1. hedef bellek bölgesindeki mevcut verileri yedekle
  p1 := PChar(AHedefBellek);

  K1 := p1^;
  Inc(p1);
  K2 := p1^;
  Inc(p1);

  BellekSiraNo := 0;
  while (K1 <> #0) or (K2 <> #0) do
  begin

    Bellek[BellekSiraNo] := K1;
    Inc(BellekSiraNo);
    Bellek[BellekSiraNo] := K2;
    Inc(BellekSiraNo);

    K1 := p1^;
    Inc(p1);
    K2 := p1^;
    Inc(p1);
  end;

  // 2. başa eklenecek verileri yükle
  p1 := PChar(AEklenecekVeri);

  K1 := p1^;
  Inc(p1);
  K2 := p1^;
  Inc(p1);

  p2 := PChar(AHedefBellek);
  Bellek2SiraNo := 0;
  while (K1 <> #0) or (K2 <> #0) do
  begin

    p2^ := K1;
    Inc(p2);
    Inc(Bellek2SiraNo);

    p2^ := K2;
    Inc(p2);
    Inc(Bellek2SiraNo);

    K1 := p1^;
    Inc(p1);
    K2 := p1^;
    Inc(p1);
  end;

  // yedeklenmiş veriyi sona ekle
  if(BellekSiraNo > 0) then
  begin

    for i := 0 to BellekSiraNo - 1 do
    begin

      K1 := Bellek[i];
      p2^ := K1;

      Inc(p2);
      Inc(Bellek2SiraNo);
    end;
  end;

  // çift sonlandırma işareti
  p2^ := #0;
  Inc(p2);
  p2^ := #0;
end;

// karakterleri büyütür ve belirten uzunluğa kadar sağ tarafa boşluk karakteri ekler
function BuyutVeTamamla(AGrupAdi: string; AUzunluk: TSayi4): string;
var
  i, j: TSayi4;
begin

  Result := '';

  i := Length(AGrupAdi);
  if(i > AUzunluk) then i := AUzunluk;

  if(i > 0) then
  begin

    for j := 1 to i do
    begin

      Result += UpCase(AGrupAdi[j]);
    end;
  end;

  if(i < AUzunluk) then
  begin

    for j := i to AUzunluk - 1 do
    begin

      Result += ' ';
    end;
  end;
end;

{TODO - lazarus'tan buraya eklendi. lazarus birimi eklenince kaldırılacak }
function Trim(const S: string): string;
var
  Ofs, Len: sizeint;
begin
  len := Length(S);
  while (Len>0) and (S[Len]<=' ') do
   dec(Len);
  Ofs := 1;
  while (Ofs<=Len) and (S[Ofs]<=' ') do
    Inc(Ofs);
  result := Copy(S, Ofs, 1 + Len - Ofs);
end;

procedure BellekDoldur(ABellekAdresi: Isaretci; AUzunluk: TSayi4; ADeger: TSayi1); assembler;
asm
  pushad
  mov edi,ABellekAdresi
  mov ecx,AUzunluk
  mov al,ADeger
  cld
  rep stosb
  popad
end;

procedure Tasi2(AKaynak, AHedef: Isaretci; AUzunluk: TSayi4); assembler;
asm
  pushad
  mov esi,AKaynak
  mov edi,AHedef
  mov ecx,AUzunluk
  cld
  rep movsb
  popad
end;

// 0 = eşit, 1 = eşit değil
function Karsilastir(AKaynak, AHedef: Isaretci; AUzunluk: TSayi4): TSayi4;
var
  Sonuc: TSayi4;
begin
asm
  pushfd
  pushad

  mov esi,AKaynak
  mov edi,AHedef
  mov ecx,AUzunluk
  cld
  repe cmpsb

  popad
  mov Sonuc,0

  je  @@exit

  mov Sonuc,1
@@exit:

  popfd
end;

  Result := Sonuc;
end;

function IPKarsilastir(IP1, IP2: TIPAdres): Boolean;
var
  i: TISayi4;
begin

  Result := False;

  for i := 0 to 3 do if(IP1[i] <> IP2[i]) then Exit;

  Result := True;
end;

// ip adresinin ağa bağlı bilgisayarlara yayın olarak gönderilip
// gönderilmediğini test eder. örn: 192.168.1.1 -> 192.168.1.255
function IPKarsilastir2(AGonderenIP, ABenimIP: TIPAdres): Boolean;
var
  i: TISayi4;
begin

  Result := False;

  for i := 0 to 2 do if(AGonderenIP[i] <> ABenimIP[i]) then Exit;

  if(AGonderenIP[3] <> 255) then Exit;

  Result := True;
end;

// xxx.xxx.xxx.yyy - xxx değerlerinin aynı olup olmadığını test eder
// bilgi: 0 ve 255 değerleri aynı ağda kabul edilmektedir
function IPAdresiAyniAgdaMi(AGonderenIP: TIPAdres): Boolean;
var
  i: TISayi4;
begin

  Result := False;

  for i := 0 to 2 do if(AGonderenIP[i] <> GAgBilgisi.IP4Adres[i]) then Exit;

  Result := True;
end;

// gün + ay + yıl değerini elr dosya sistemi tarih değerine çevirir
function ELRTarih(AGun, AAy, AYil: TSayi2): TSayi4;
begin

  Result := (AYil shl 16) or (AAy shl 8) or (AGun);
end;

// fat12/16/32 tarih değerini elr dosya sistemi tarih değerine çevirir
function FatXTarih2ELRTarih(ATarih: TSayi2): TSayi4;
var
  j, Gun, Ay, Yil: TSayi2;
begin

  j := ATarih;
  Gun := j and 31;
  Ay := (j shr 5) and 15;
  Yil := ((j shr 9) and 127) + 1980;

  Result := (Yil shl 16) or (Ay shl 8) or (Gun);
end;

// saat + dakika + saniye değerini elr dosya sistemi saat değerine çevirir
function ELRSaat(ASaat, ADakika, ASaniye: TSayi1): TSayi4;
begin

  Result := (ASaniye shl 16) or (ADakika shl 8) or (ASaat);
end;

// fat12/16/32 saat değerini elr dosya sistemi tarih değerine çevirir
function FatXSaat2ELRSaat(ASaat: TSayi2): TSayi4;
var
  j, Saniye, Dakika, Saat: TSayi2;
begin

  j := ASaat;
  Saniye := (j and 31) * 2;
  Dakika := (j shr 5) and 63;
  Saat := (j shr 11) and 31;

  Result := (Saniye shl 16) or (Dakika shl 8) or (Saat);
end;

procedure DosyaKopyala(AKaynakDosya, AHedefDosya: string);
var
  DosyaKimlik: TKimlik;
  Bellek: Isaretci;
  U: TISayi4;
begin

  //AssignFile(DosyaKimlik, 'disk1:\belgeler\haklar.txt');
  AssignFile(DosyaKimlik, AKaynakDosya);
  Reset(DosyaKimlik);

  U := FileSize(DosyaKimlik);

  GetMem(Bellek, U);

  Read(DosyaKimlik, Bellek);
  CloseFile(DosyaKimlik);

  AssignFile(DosyaKimlik, AHedefDosya);
  ReWrite(DosyaKimlik);
  if(IOResult = 0) then
  begin

    Write(DosyaKimlik, Bellek, U);
  end;

  CloseFile(DosyaKimlik);
end;

end.
