{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: veritipleri.inc
  Dosya İşlevi: sistem tarafından kullanılan veri tiplerini içerir

  Güncelleme Tarihi: 12/04/2025

 ==============================================================================}

{==============================================================================
  Data Type     Bytes   Range
  Byte	        1       0..255
  ShortInt	    1       -128..127
  Word	        2       0..65535
  SmallInt	    2       -32767..32768
  LongWord	    4       0..4294967295
  LongInt	      4       -2147483648..2147483647
  Cardinal      4       LongWord
  Integer       4       SmallInt veya LongInt
  QWord	        8       0..18446744073709551615
  Int64	        8       -9223372036854775808 .. 9223372036854775807
 ==============================================================================}
type
  Sayi1 = Byte;
  ISayi1 = ShortInt;
  Sayi2 = Word;
  ISayi2 = SmallInt;
  Sayi4 = LongWord;
  ISayi4 = LongInt;
  Sayi8 = QWord;
  ISayi8 = Int64;
  Isaretci = Pointer;
  TSayi1 = Sayi1;               // 1 byte'lık işaretsiz sayı
  PSayi1 = ^Sayi1;              // 1 byte'lık işaretsiz sayıya işaretçi
  TISayi1 = ISayi1;             // 1 byte'lık işaretli sayı
  PISayi1 = ^ISayi1;            // 1 byte'lık işaretli sayıya işaretçi
  TSayi2 = Sayi2;               // 2 byte'lık işaretsiz sayı
  PSayi2 = ^Sayi2;              // 2 byte'lık işaretsiz sayıya işaretçi
  TISayi2 = ISayi2;             // 2 byte'lık işaretli sayı
  PISayi2 = ^ISayi2;            // 2 byte'lık işaretli sayıya işaretçi
  TSayi4 = Sayi4;               // 4 byte'lık işaretsiz sayı
  PSayi4 = ^Sayi4;              // 4 byte'lık işaretsiz sayıya işaretçi
  TISayi4 = ISayi4;             // 4 byte'lık işaretli sayı
  PISayi4 = ^ISayi4;            // 4 byte'lık işaretli sayıya işaretçi
  TSayi8 = Sayi8;               // 8 byte'lık işaretsiz sayı
  PSayi8 = ^Sayi8;              // 8 byte'lık işaretsiz sayıya işaretçi
  TISayi8 = ISayi8;             // 8 byte'lık işaretli sayı
  PISayi8 = ^ISayi8;            // 8 byte'lık işaretli sayıya işaretçi
  TKarakterKatari = shortstring;
  PKarakterKatari = ^shortstring;
  TRenk = Sayi4;
  PRenk = ^TRenk;
  TTarih = Sayi4;
  TSaat = Sayi4;
  PSaat = ^TSaat;

  HResult = ISayi4;
  PChar = ^Char;
  PByte = ^Byte;
  PShortInt = ^ShortInt;
  PWord = ^Word;
  TKimlik = TISayi4;
  PKimlik = ^TKimlik;
  PSmallInt = ^SmallInt;
  PBoolean = ^Boolean;
