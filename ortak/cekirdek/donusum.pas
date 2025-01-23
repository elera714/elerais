{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: donusum.pas
  Dosya İşlevi: değer dönüşüm (convert) işlevlerini içerir

  Güncelleme Tarihi: 04/01/2025

 ==============================================================================}
{$mode objfpc}
unit donusum;
 
interface

uses paylasim;

// aşağıdaki işlev adlarından derleyici içeriğinde karşılığı olan işlevler adları
// değiştirilemeyecek; ileride derleyiciyle enterge olarak çalışacaktır

// derleyici içerisinde karşılığı olabilecek işlevler
function TimeToStr(ASaat: TSaat): string;
function DateToStr(ATarih: TTarih): string;
function StrToHex(ADeger: string): TSayi4;
function IntToStr(ADeger: TISayi4): string;
function MAC_KarakterKatari(AMACAdres: TMACAdres): string;
function IP_KarakterKatari(AIPAdres: TIPAdres): string;
function StrToIP(AIPAdres: string): TIPAdres;
function LowerCase(AKarakter: Char): Char;
function UpperCase(AKarakter: Char): Char;
function UpperCase(ADeger: string): string;
function ntohs(ADeger: TSayi2): TSayi2;
function ntohs(ADeger: TSayi4): TSayi4;
function htons(ADeger: TSayi2): TSayi2;
function htons(ADeger: TSayi4): TSayi4;
function UTF16Ascii(ABellek: PWideChar): string;
function WideChar2String(ABellek: PWideChar): string;
function WideChar2Char(AWideCharKod: TISayi4): Char;
function BCDyiSayi10aCevir(ADeger: TSayi1): TSayi1;
procedure RedGreenBlue(ARenk: TRenk; var R, G, B: TSayi1);
function RGBToColor(R, G, B: TSayi1): TRenk;

// derleyici içerisinde karşılığı olamayacak işlevler
function HamDosyaAdiniDosyaAdinaCevir(ADizinGirdisi: PDizinGirdisi): string;
function RGB24CevirRGB16(Color: TRenk): Word;

implementation

const
  SayiSistemi16: PChar = ('0123456789ABCDEF');

{==============================================================================
  saat değerini karakter katarı değerine dönüştürür
 ==============================================================================}
function TimeToStr(ASaat: TSaat): string;
var
  i: TSayi1;
begin

  SetLength(Result, 8);

  // saat değerini karakter katarına çevir
  i := ASaat and $FF;
  if(i > 9) then
    Result := IntToStr(i)
  else Result := '0' + IntToStr(i);
  Result += ':';

  // dakika değerini karakter katarına çevir
  i := (ASaat shr 8) and $FF;
  if(i > 9) then
    Result += IntToStr(i)
  else Result += '0' + IntToStr(i);
  Result += ':';

  // saniye değerini karakter katarına çevir
  i := (ASaat shr 16) and $FF;
  if(i > 9) then
    Result += IntToStr(i)
  else Result += '0' + IntToStr(i);
end;

{==============================================================================
  tarih değerini karakter katarı değerine dönüştürür
 ==============================================================================}
{ TODO : Date (TDate) değişkeni yapıya dönüştürülerek yeniden kodlanacak }
function DateToStr(ATarih: TTarih): string;
var
  p: PChar;
  i: TSayi4;
begin

  p := @Result;

  i := ATarih;

  // gün değerini karakter katarı değerine çevir
  p[2] := Char((i and $F) + $30);
  i := i shr 4;
  p[1] := Char((i and $F) + $30);
  i := i shr 4;

  // ay değerini karakter katarı değerine çevir
  p[3] := '-';
  p[5] := Char((i and $F) + $30);
  i := i shr 4;
  p[4] := Char((i and $F) + $30);
  i := i shr 4;

  // yıl değerini karakter katarı değerine çevir
  p[6] := '-';
  if(i >= 90) then
  begin

    p[7] := '1';
    p[8] := '9';
  end
  else
  begin

    p[7] := '2';
    p[8] := '0';
  end;

  p[10] := Char((i and $F) + $30);
  i := i shr 4;
  p[9] := Char((i and $F) + $30);
  i := i shr 4;

  SetLength(Result, 10);
end;

{==============================================================================
  string değeri 16lı sistem sayı değerine dönüştürür
 ==============================================================================}
function StrToHex(ADeger: string): TSayi4;
var
  i: TSayi4;
  s: string;
begin

  Result := 0;
  if(Length(ADeger) > 0) then
  begin

    s := UpperCase(ADeger);
    for i := 1 to Length(s) do
    begin

      Result := Result shl 4;
      case s[i] of
        '0'..'9': begin Result := Result + Ord(s[i]) - 48 end;
        'A'..'F': begin Result := Result + Ord(s[i]) - 55 end;
      end;
    end;
  end;
end;

{==============================================================================
  10lu sayı sistem sayı değerini karakter katarına dönüştürür
 ==============================================================================}
function IntToStr(ADeger: TISayi4): string;
var
  Bellek: array[0..11] of Char;
  Negatif: Boolean;
  HaneSayisi: TISayi4;
  Deger: TISayi4;
	p: PChar;
begin

  // 32 bit maximum sayı = 4294967295 - on hane

  // hane sayısını sıfırla
  HaneSayisi := 0;

  // değerlerin yerleştirileceği belleğin en son kısmına konumlan
  p := @Bellek[11];

  // sayısal değer negatif mi ? pozitif mi ?
	if (ADeger < 0) then
	begin

		Deger := -ADeger;
		Negatif := True;
	end
	else
	begin

		Deger := ADeger;
		Negatif := False;
	end;

  // sayısal değeri çevir
	repeat

		p^ := Char((Deger mod 10) + Byte('0'));
		Deger := Deger div 10;
    Inc(HaneSayisi);
		Dec(p);
	until (Deger = 0);

  // sayısal değer negatif ise - işaretini de ekle
	if(Negatif) then
	begin

		PChar(p)^ := '-';
    Inc(HaneSayisi);
	end;

  // değeri hedef bölgeye kopyala
  Tasi2(@Bellek[11 - HaneSayisi + 1], @Result[1], HaneSayisi);
  SetLength(Result, HaneSayisi);
end;

{==============================================================================
  MAC adresini karakter katarına dönüştürür
 ==============================================================================}
function MAC_KarakterKatari(AMACAdres: TMACAdres): string;
var
  Deger, i: TSayi4;
begin

  Result := '';

  // mac adresini çevir
  for i := 0 to 5 do
  begin

    Deger := AMACAdres[i];
    Result := Result + SayiSistemi16[((Deger shr 4) and $F)];
    Result := Result + SayiSistemi16[Deger and $F];
    if(i < 5) then
    begin

      Result := Result + Char('-');
    end;
  end;

  SetLength(Result, 17);
end;

{==============================================================================
  IP adresini karakter katarına dönüştürür
 ==============================================================================}
function IP_KarakterKatari(AIPAdres: TIPAdres): string;
var
  Toplam, i: TSayi1;
  Deger: string[3];
begin

  Toplam := 0;
  Result := '';

  // ip adresini çevir
  for i := 0 to 3 do
  begin

    Deger := IntToStr(AIPAdres[i]);
    Toplam := Toplam + Length(Deger);
    Result := Result + Deger;

    if(i < 3) then
    begin

      Result := Result + '.'
    end;
  end;

  SetLength(Result, Toplam + 3);  // + 3 = sayı aralardaki her nokta
end;

{==============================================================================
  karakter katar değerini IP adres değerine dönüştürür
 ==============================================================================}
function StrToIP(AIPAdres: string): TIPAdres;
var
  IPAdres, s: string;
  NoktaSayisi, SiraNo,
  Sonuc, i: TSayi1;
  s2: TSayi2;
  Deger: Char;
label
  Hata;
begin

  // ip adresinin sağ / sol taraflarındaki boşlukları yok et
  IPAdres := Trim(AIPAdres);
  NoktaSayisi := 0;
  SiraNo := 0;
  s := '';

  // ip adresini çevir
  for i := 1 to Length(IPAdres) do
  begin

    Deger := IPAdres[i];
    if(Deger = '.') then
    begin

      Inc(NoktaSayisi);

      // 2 nokta arasında rakam yoksa çık
      if(Length(s) = 0) then Goto Hata;

      Val(s, s2, Sonuc);
      if(s2 > 255) then Goto Hata;

      Result[SiraNo] := s2;

      s := '';
      Inc(SiraNo);
    end
    else
    begin

      if(Deger in ['0'..'9']) then
        s += IPAdres[i]
      else Goto Hata;
    end;
  end;

  Val(s, s2, Sonuc);
  if(s2 > 255) then Goto Hata;

  Result[SiraNo] := s2;

  if(NoktaSayisi <> 3) then Goto Hata;
  Exit;

Hata:
  Result := IPAdres0;
end;

{==============================================================================
  karakteri küçük harfe çevirir
 ==============================================================================}
function LowerCase(AKarakter: Char): Char;
begin

	if(AKarakter in [#65..#90]) then

  	Result := Char(Byte(AKarakter) + 32)
	else Result := AKarakter;
end;

{==============================================================================
  karakteri büyük harfe çevirir
 ==============================================================================}
function UpperCase(AKarakter: Char): Char;
begin

	if(AKarakter in [#97..#122]) then

  	Result := Char(Byte(AKarakter) - 32)
	else Result := AKarakter;
end;

{==============================================================================
  karakter katar değerini büyük harfe çevirir
 ==============================================================================}
function UpperCase(ADeger: string): string;
var
  i: TISayi4;
  C: Char;
begin

  if(Length(ADeger) > 0) then
  begin

    Result := '';
    for i := 1 to Length(ADeger) do
    begin

      C := ADeger[i];
    	if(C in [#97..#122]) then
        Result := Result + Char(Byte(C) - 32)
      else Result := Result + C;
    end;
  end else Result := '';
end;

// big endian -> little endian çevrimi

// network sıralı değeri host sıralı değere çevirir (örnek: $1234 -> $3412)
function ntohs(ADeger: TSayi2): TSayi2;
begin

  Result := SwapEndian(ADeger);
end;

// network sıralı değeri host sıralı değere çevirir (örnek: $12345678 -> $56781234)
function ntohs(ADeger: TSayi4): TSayi4;
begin

  Result := SwapEndian(ADeger);
end;

// host sıralı değeri network sıralı değere çevirir (örnek: $1234 -> $3412)
function htons(ADeger: TSayi2): TSayi2;
begin

  Result := SwapEndian(ADeger);
end;

// host sıralı değeri network sıralı değere çevirir (örnek: $12345678 -> $56781234)
function htons(ADeger: TSayi4): TSayi4;
begin

  Result := SwapEndian(ADeger);
end;

// UTF-16 (UnicodeString - 16bit) kod çevrimi
// UTF-16'da 2. byte değeri şu aşamada gözardı edilmiştir
{

  UTF kodlaması 1-4 byte arasında olup aşağıdaki şekildedir. (çalışmaya BOM dahil değildir)

  1 byte = 0xxx xxxx                                        ; ascii kod
  2 byte = 110x xxxx + 10xx xxxx                            ; 2 bytelık utf kod
  3 byte = 1110 xxxx + 10xx xxxx + 10xx xxxx                ; 3 bytelık utf kod
  4 byte = 1111 0xxx + 10xx xxxx + 10xx xxxx + 10xx xxxx    ; 4 bytelık utf kod

  Örnek: 2 bytelık utf kod = $C5, $9E
          $C5         $9E
          1100 0101    1001 1110
             0 0101      01 1110
                101  or  01 1110 = $15E = Ş

}
function UTF16Ascii(ABellek: PWideChar): string;
var
  p: PByte;
  B1, B2: TSayi1;
  KodSayisi, UTF8Kod: TISayi4;
  KodUTF8Mi, IlkUTFKod: Boolean;
begin

  Result := '';

  p := PByte(ABellek);

  B1 := p^;
  Inc(p);
  B2 := p^;
  Inc(p);

  KodUTF8Mi := False;
  IlkUTFKod := False;
  while (B1 <> 0) or (B2 <> 0) do
  begin

    if((B1 and $C0) = $C0) then
    begin

      IlkUTFKod := True;
      UTF8Kod := B1 and $1F;
      KodUTF8Mi := True;
      KodSayisi := 2 - 1;
    end
    else if((B1 and $E0) = $E0) then
    begin

      IlkUTFKod := True;
      UTF8Kod := B1 and $F;
      KodUTF8Mi := True;
      KodSayisi := 3 - 1;
    end
    else if((B1 and $F0) = $F0) then
    begin

      IlkUTFKod := True;
      UTF8Kod := B1 and $7;
      KodUTF8Mi := True;
      KodSayisi := 4 - 1;
    end
    else if not(KodUTF8Mi) then
    begin

      UTF8Kod := (B2 shl 8) or B1;
      KodUTF8Mi := False;
    end;

    if not(KodUTF8Mi) then

      Result += WideChar2Char(UTF8Kod)
    else
    begin

      // ilk utf kod ise, değer yukarıda alındığı için sadece bayrağı pasifleştir
      if(IlkUTFKod) then

        IlkUTFKod := False
      else
      begin

        // 2 ve sonraki utf kodları 10xx xxxx biçimindedir
        // 7-6. bitler (10) ihmal edilmiştir
        UTF8Kod := (UTF8Kod shl 6) or (B1 and $3F);

        Dec(KodSayisi);

        // son utf kodu ise, çevrim işlemini gerçekleştir
        if(KodSayisi = 0) then
        begin

          Result += WideChar2Char(UTF8Kod);

          IlkUTFKod := False;
          KodUTF8Mi := False;
        end;
      end;
    end;

    B1 := Byte(p^);
    Inc(p);
    B2 := Byte(p^);
    Inc(p);
  end;
end;

// geniş karakteri (widechar = 2 byte) tek karaktere (char = 1 byte) çevirir
// bilgi: fat32 dosya sistemi uzun dosya adları için
function WideChar2String(ABellek: PWideChar): string;
var
  p: PByte;
  B1, B2: TSayi1;
  WideCharKod: TISayi4;
begin

  Result := '';

  p := PByte(ABellek);

  B1 := p^;
  Inc(p);
  B2 := p^;
  Inc(p);

  while (B1 <> 0) or (B2 <> 0) do
  begin

    WideCharKod := (B2 shl 8) or B1;
    Result += WideChar2Char(WideCharKod);

    B1 := Byte(p^);
    Inc(p);
    B2 := Byte(p^);
    Inc(p);
  end;
end;

// karakter kodunun (widechar / utf8) ascii karşılığını döndürür
function WideChar2Char(AWideCharKod: TISayi4): Char;
begin

  case AWideCharKod of
    $E7:  Result := Chr(231);    // ç
    $C7:  Result := Chr(199);    // Ç
    $11E: Result := Chr(208);    // Ğ
    $11F: Result := Chr(240);    // ğ
    $131: Result := Chr(253);    // ı (I ascii karakter)
    $130: Result := Chr(221);    // İ (i ascii karakter)
    $D6:  Result := Chr(153);    // Ö
    $F6:  Result := Chr(246);    // ö
    $15E: Result := Chr(222);    // Ş
    $15F: Result := Chr(254);    // ş
    $FC:  Result := Chr(252);    // ü
    $DC:  Result := Chr(220);    // Ü
    else  Result := Chr(AWideCharKod);
  end;
end;

// ikili kodlanmış byte değerini (binary coded decimal) ondalık değere çevirir
function BCDyiSayi10aCevir(ADeger: TSayi1): TSayi1;
begin

  Result := ((ADeger shr 4) * 10) + (ADeger and $F);
end;

procedure RedGreenBlue(ARenk: TRenk; var R, G, B: TSayi1);
begin

  {$asmmode intel}
  asm
    mov eax,[ARenk]
    mov edi,B
    mov [edi],al
    shr eax,8
    mov edi,G
    mov [edi],al
    shr eax,8
    mov edi,R
    mov [edi],al
  end ['eax', 'edi']
end;

function RGBToColor(R, G, B: TSayi1): TRenk;
begin

  Result := (R shl 16) or (G shl 8) or B;
end;

{==============================================================================
  ham dosya adını dosya.uz dosya ad formatına çevirir. (küçük harf ile)
 ==============================================================================}
function HamDosyaAdiniDosyaAdinaCevir(ADizinGirdisi: PDizinGirdisi): string;
var
  NoktaEklendi: Boolean;
  i: TSayi4;
begin

  // hedef bellek bölgesini sıfırla
  // hedef bellek alanı şu an 8+1+3+1 (dosya+.+uz+null) olmalıdır
  Result := '';

  // dosya adını çevir
  i := 0;
  while (i < 8) and (ADizinGirdisi^.DosyaAdi[i] <> ' ') do
  begin

    Result := Result + LowerCase(ADizinGirdisi^.DosyaAdi[i]);
    Inc(i);
  end;

  // dosya uzantısını çevir
  NoktaEklendi := False;
  i := 0;
  while (i < 3) and (ADizinGirdisi^.Uzanti[i] <> ' ') do
  begin

    if(NoktaEklendi = False) then
    begin

      Result := Result + '.';
      NoktaEklendi := True;
    end;

    Result := Result + LowerCase(ADizinGirdisi^.Uzanti[i]);
    Inc(i);
  end;
end;

{==============================================================================
  24 bitlik RGB renk değerini 16 bitlik RGB renk değerine çevirir
 ==============================================================================}
function RGB24CevirRGB16(Color: TRenk): Word;
begin

  Result := (Color shr 3) and 31;
  Result += ((Color shr 10) and 63) shl 5;
  Result += ((Color shr 19) and 31) shl 11;
end;

end.
