{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: bmp.pas
  Dosya İşlevi: bmp dosya işlevlerini içerir

  Güncelleme Tarihi: 01/05/2025

  Not-1: şu an itibariyle sadece 24 bitlik resim görüntüleme desteği vardır
  Not-2: tüm renkler 32 bitlik değerlerle işlenmektedir

 ==============================================================================}
{$mode objfpc}
unit bmp;

interface

uses dosya, gercekbellek, genel, paylasim, gn_pencere, gorselnesne;

type
  PRGBRenk = ^TRGBRenk;
  TRGBRenk = packed record
    R, G, B: TSayi1;
  end;

  PBMPBicim = ^TBMPBicim;
  TBMPBicim = packed record
    Tip: TSayi2;	                  // dosya tipi "BM".
    Uzunluk: TSayi4;	              // dosya uzunluğu
    Ayrilmis: TSayi4;	              // ayrıldı = 0
    VeriAdres: TSayi4;	            // data (resim) başlangıç adresi
    BaslikUzunlugu: TSayi4;	        // başlık uzunluğu = 40
    Genislik: TSayi4;	              // resmin pixel olarak genişliği
    Yukseklik: TSayi4;	            // resmin pixel olarak yüksekliğğ
    PlanSayisi: TSayi2;	            // plan sayısı = 1
    PixelBasinaBitSayisi: TSayi2;	  // pixel başına bit sayısı 24, 32
    Sikistirma: TSayi4;	            // sıkıştırma = 0
    ResimBoyutu: TSayi4;	          // resmin byte olarak uzunluğu
    MetreBasinaYatayNokta: TSayi4;  // metre başına yatay pixel
    MetreBasinaDikeyNokta: TSayi4;  // metre başına düşey pixel
    KullanilanRenkSayisi: TSayi4;	  // kullanılan renk sayısı
    OnemliRenkSayisi: TSayi4;       // önemli renk sayısı
  end;

function BMPDosyasiYukle(ADosyaTamYol: string): TGoruntuYapi;
procedure ResimCiz(AGNTip: TGNTip; AGorselNesne: PGorselNesne; AGoruntuYapi: TGoruntuYapi);

implementation

uses gn_masaustu, gn_resim, islevler, gn_islevler, sistemmesaj;

// bmp biçimindeki dosyayı resim olarak belleğe yükler
function BMPDosyasiYukle(ADosyaTamYol: string): TGoruntuYapi;
var
  DosyaBellek: Isaretci;
  DosyaUzunlugu: TISayi4;
  DosyaKimlik: TKimlik;
  DosyaTamYol, DosyaUzantisi,
  Surucu, Klasor, DosyaAdi: string;
  BMPBicim: PBMPBicim;
  GoruntuYapi: TGoruntuYapi;
  SatirdakiByteSayisi, Satir,
  Sol, Ust, i: TISayi4;
  Renk2: PRGBRenk;
  Renk1: TRenk;
  HedefBellek: PRenk;
begin

  //SISTEM_MESAJ(mtBilgi, RENK_MOR, 'Dosya: ' + ADosyaTamYol, []);

  Result.BellekAdresi := nil;

  // dosyayı sürücü + Klasor + dosya parçalarına ayır
  DosyaYolunuParcala2(ADosyaTamYol, Surucu, Klasor, DosyaAdi);

  // dosya adının uzunluğunu al
  DosyaUzunlugu := Length(DosyaAdi);

  // dosya uzantısını al
  i := Pos('.', DosyaAdi);
  if(i > 0) then
    DosyaUzantisi := Copy(DosyaAdi, i + 1, DosyaUzunlugu - i)
  else DosyaUzantisi := '';

  if(DosyaUzantisi = 'bmp') then
  begin

    DosyaTamYol := Surucu + ':' + Klasor + DosyaAdi;

    AssignFile(DosyaKimlik, DosyaTamYol);
    Reset(DosyaKimlik);
    if(IOResult = HATA_DOSYA_ISLEM_BASARILI) then
    begin

      // dosya uzunluğunu al
      DosyaUzunlugu := FileSize(DosyaKimlik);

      // dosyanın belleğe Ustüklenmesi için bellekte yer ayır
      DosyaBellek := GetMem(DosyaUzunlugu);
      if(DosyaBellek = nil) then
      begin

        // dosyayı kapat
        CloseFile(DosyaKimlik);
        Exit;
      end;

      // dosyayı hedef adrese kopyala
      Read(DosyaKimlik, DosyaBellek);

      // dosyayı kapat
      CloseFile(DosyaKimlik);

      BMPBicim := DosyaBellek;
      GoruntuYapi.Genislik := BMPBicim^.Genislik;
      GoruntuYapi.Yukseklik := BMPBicim^.Yukseklik;

      GoruntuYapi.BellekAdresi := GetMem(GoruntuYapi.Genislik *
        GoruntuYapi.Yukseklik * 4);
      if(GoruntuYapi.BellekAdresi = nil) then Exit;

      // resim dosyasındaki her bir satırdaki byte sayısı
      SatirdakiByteSayisi := (GoruntuYapi.Genislik * 3) and $FFFFFFFC;

      Satir := -1;

      for Ust := GoruntuYapi.Yukseklik - 1 downto 0 do
      begin

        HedefBellek := GoruntuYapi.BellekAdresi + (Ust * (GoruntuYapi.Genislik * 4));

        Inc(Satir);
        Renk2 := DosyaBellek + BMPBicim^.VeriAdres + (SatirdakiByteSayisi * Satir);

        for Sol := 0 to GoruntuYapi.Genislik - 1 do
        begin

          Renk1 := (Renk2^.B shl 16) + (Renk2^.G shl 8) + (Renk2^.R);
          HedefBellek^ := Renk1;
          Inc(Renk2);
          Inc(HedefBellek);
        end;
      end;

      // dosyanın açıldığı belleği serbest bırak
      FreeMem(DosyaBellek, DosyaUzunlugu);

      Result := GoruntuYapi;
    end;
  end;
end;

// bmp biçiminde belleğe yüklenmiş resmi görsel nesneye çizer
procedure ResimCiz(AGNTip: TGNTip; AGorselNesne: PGorselNesne;
  AGoruntuYapi: TGoruntuYapi);
var
  Masaustu: PMasaustu;
  Pencere: PPencere;
  Resim: PResim;
  Renk1, Renk2: PRenk;
  Alan: TAlan;
  Yukseklik, Genislik, SatirdakiByteSayisi,
  TuvalA1, TuvalB1: TISayi4;
  YatayArtis, DikeyArtis, Sol: Double;
begin

  if(AGNTip = gntMasaustu) then
  begin

    Masaustu := PMasaustu(AGorselNesne);
    if(Masaustu = nil) then Exit;

    Alan := Masaustu^.FCizimAlan;

    Genislik := AGoruntuYapi.Genislik;
    SatirdakiByteSayisi := Genislik * 4;
    if(Genislik > Alan.Sag) then Genislik := Alan.Sag;
    Yukseklik := AGoruntuYapi.Yukseklik;
    if(Yukseklik > Alan.Alt) then Yukseklik := Alan.Alt;

    for TuvalB1 := 0 to Yukseklik - 1 do
    begin

      Renk1 := (TuvalB1 * SatirdakiByteSayisi) + AGoruntuYapi.BellekAdresi;

      for TuvalA1 := 0 to Genislik - 1 do
      begin

        GEkranKartSurucusu.NoktaYaz(Masaustu, Alan.Sol + TuvalA1, Alan.Ust + TuvalB1,
          Renk1^, True);
        Inc(Renk1);
      end;
    end;
  end
  else if(AGNTip = gntResim) then
  begin

    Resim := PResim(AGorselNesne);
    if(Resim = nil) then Exit;

    // ata nesne kontrolü. ata nesne pencere değilse çık
    Pencere := EnUstPencereNesnesiniAl(Resim);
    if(Pencere = nil) then Exit;

    Alan := Resim^.FCizimAlan;

    if(Resim^.FTuvaleSigdir) then
    begin

      Genislik := AGoruntuYapi.Genislik;
      SatirdakiByteSayisi := Genislik * 4;
      Yukseklik := AGoruntuYapi.Yukseklik;
      YatayArtis := Genislik / (Alan.Sag - Alan.Sol);
      DikeyArtis := Yukseklik / (Alan.Alt - Alan.Ust);
    end
    else
    begin

      Genislik := AGoruntuYapi.Genislik;
      SatirdakiByteSayisi := Genislik * 4;
      if(Genislik > Alan.Sag) then Genislik := Alan.Sag;
      Yukseklik := AGoruntuYapi.Yukseklik;
      if(Yukseklik > Alan.Alt) then Yukseklik := Alan.Alt;
      YatayArtis := 1.0;
      DikeyArtis := 1.0;
    end;

    for TuvalB1 := 0 to Yukseklik - 1 do
    begin

      Renk1 := (Round((TuvalB1 * DikeyArtis)) * SatirdakiByteSayisi) + AGoruntuYapi.BellekAdresi;

      Sol := 0.0;
      for TuvalA1 := 0 to Genislik - 1 do
      begin

        Sol := Sol + YatayArtis;
        Renk2 := Renk1;
        Inc(Renk2, Round(Sol));

        GEkranKartSurucusu.NoktaYaz(Resim, Alan.Sol + TuvalA1, Alan.Ust + TuvalB1,
          Renk2^, True);
      end;
    end;
  end;
end;

end.
