{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_islevler.pas
  Dosya İşlevi: görsel nesne (visual object) işlevlerini içerir

  Güncelleme Tarihi: 21/05/2025

 ==============================================================================}
{$mode objfpc}
unit gn_islevler;

interface

uses gorselnesne, genel, paylasim, gn_masaustu, gn_pencere;

var
  YakalananGorselNesne: PGorselNesne;   // farenin, üzerine sol tuş ile basılıp seçildiği nesne

function GorselNesneIslevCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
procedure GorevGorselNesneleriniYokEt(AGorevKimlik: TKimlik);
procedure PencereleriYenidenCiz;
function GorselNesneBul(var AKonum: TKonum): PGorselNesne;
function EnUstNesneyiAl(AGorselNesne: PGorselNesne): PGorselNesne;
function EnUstPencereNesnesiniAl(AGorselNesne: PGorselNesne): PPencere;
procedure OlayYakalamayaBasla(AGorselNesne: PGorselNesne);
procedure OlayYakalamayiBirak(AGorselNesne: PGorselNesne);

implementation

uses islevler, sistemmesaj, gorev, donusum, temelgorselnesne;

{==============================================================================
  genel nesne çağrılarını yönetir
 ==============================================================================}
function GorselNesneIslevCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne;
  Kimlik: TKimlik;
  BellekAdresi: Isaretci;
  Konum: TKonum;
  s: string;
begin

  // yatay & dikey koordinattaki nesneyi al
  if(AIslevNo = 1) then
  begin

    Konum.Sol := PISayi4(ADegiskenler + 00)^;
    Konum.Ust := PISayi4(ADegiskenler + 04)^;
    GN := GorselNesneBul(Konum);
    Result := GN^.Kimlik;
  end

  // görsel nesne bilgilerini hedef bellek bölgesine kopyala
  // bilgi: bu işlevin alt yapı çalışması yapılacak
  else if(AIslevNo = 2) then
  begin

    Kimlik := PISayi4(ADegiskenler + 00)^;
    if(Kimlik >= 0) and (Kimlik < USTSINIR_GORSELNESNE) then
    begin

      GN := GorselNesneler0.GorselNesne[Kimlik];
      BellekAdresi := Isaretci(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
      Tasi2(GN, BellekAdresi, GN_UZUNLUK);

      Result := 1;
    end else Result := 0;
  end

  // yatay & dikey koordinattaki nesnenin adını al
  else if(AIslevNo = 3) then
  begin

    Konum.Sol := PISayi4(ADegiskenler + 00)^;
    Konum.Ust := PISayi4(ADegiskenler + 04)^;

    { TODO - GN yapısı object'den class'a çevrildi. api yeniden düzenlencek }
    GN := GorselNesneBul(Konum);
    s := IntToStr(GN^.Kimlik);
    BellekAdresi := Isaretci(PSayi4(ADegiskenler + 08)^ + FAktifGorevBellekAdresi);
    Tasi2(@s[0], BellekAdresi, Length(s) + 1);
    //Tasi2(@GN^.NesneAdi[0], BellekAdresi, Length(GN^.NesneAdi) + 1);
  end;
end;

{==============================================================================
  çalışan işleme ait pencere ve tüm alt nesneleri yok eder
  { TODO : bu işlev çoklu pencere ve çoklu alt nesneye göre yeniden kodlanacaktır - 18072020 }
 ==============================================================================}
procedure GorevGorselNesneleriniYokEt(AGorevKimlik: TKimlik);
var
  Masaustu: PMasaustu;
  Pencere: PGorselNesne;
  MasaustuGNBellekAdresi,
  PencereGNBellekAdresi: PPGorselNesne;
  PencereSiraNo, PencereAltNesneSiraNo, i: TISayi4;
begin

  // geçerli bir masaüstü var mı ?
  Masaustu := GAktifMasaustu;
  if not(Masaustu = nil) then
  begin

    // masaüstü nesnesinin alt nesnesi var ise
    if(Masaustu^.AltNesneSayisi > 0) then
    begin

      // masaüstünün alt nesnelerinin bellek adresini al
      MasaustuGNBellekAdresi := Masaustu^.FAltNesneBellekAdresi;

      // masaüstü alt nesnelerini teker teker ara
      for PencereSiraNo := 0 to Masaustu^.AltNesneSayisi - 1 do
      begin

        Pencere := MasaustuGNBellekAdresi[PencereSiraNo];

        // aranan pencerenin sahibi olan görev ile araştırılan görev kimliği eşit mi?
        // öyle ise pencere ve alt nesnelerini yok et
        if(Pencere^.GorevKimlik = AGorevKimlik) then
        begin

          // pencere nesnesinin alt nesnesi var mı?
          if(Pencere^.AltNesneSayisi > 0) then
          begin

            // pencere nesnesinin alt nesne bellek bölgesine konumlan
            PencereGNBellekAdresi := Pencere^.FAltNesneBellekAdresi;
            for PencereAltNesneSiraNo := Pencere^.AltNesneSayisi - 1 downto 0 do
            begin

              GorselNesneler0.YokEt(PencereGNBellekAdresi[PencereAltNesneSiraNo]^.Kimlik);
            end;

            // pencere nesnesinin alt nesne için ayrılan bellek bloğunu iptal et
            { TODO : bu işlev buradan çıkarılarak nesnenin yoketme işlevine eklenecektir }
            FreeMem(Pencere^.FAltNesneBellekAdresi, 4096);
          end;

          // bulunan pencereyi masaüstü listesinden çıkart
          MasaustuGNBellekAdresi[PencereSiraNo] := nil;

          // pencere ve alt görsel nesneler için ayrılan çizim bellek alanının yok et
          FreeMem(Pencere^.FCizimBellekAdresi, Pencere^.FCizimBellekUzunlugu);

          // pencereyi yok et
          GorselNesneler0.YokEt(Pencere^.Kimlik);

          // masaüstü alt nesne sayısını bir azalt
          i := Masaustu^.AltNesneSayisi;
          Dec(i);
          Masaustu^.AltNesneSayisi := i;

          // eğer alt nesne sayısı halen mevcut ise
          // sıralamayı tekrar gözden geçir
          if(Masaustu^.AltNesneSayisi > 0) then
          begin

            for i := 0 to Masaustu^.AltNesneSayisi - 1 do
            begin

              if(MasaustuGNBellekAdresi[i] = nil) then
                MasaustuGNBellekAdresi[i] := MasaustuGNBellekAdresi[i + 1];
            end;
          end

          // aksi durumda masaüstü alt nesne bellek bölgesini iptal et
          else FreeMem(Masaustu^.FAltNesneBellekAdresi, 4096);

          // bir sonraki döngüye devam etmeden çık
          Exit;
        end;
      end;
    end;
  end;
end;

{==============================================================================
  tüm pencere nesnelerini yeniden çizer
  bilgi: pencere giysi (skin) işlemleri için kodlanmıştır
 ==============================================================================}
procedure PencereleriYenidenCiz;
var
  Masaustu: PMasaustu;
  Pencere: PGorselNesne;
  AltNesneBellekAdresi: PPGorselNesne;
  i: TISayi4;
begin

  // geçerli bir masaüstü var mı ?
  Masaustu := GAktifMasaustu;
  if not(Masaustu = nil) then
  begin

    // masaüstü nesnesinin alt nesnesi var ise
    if(Masaustu^.AltNesneSayisi > 0) then
    begin

      // masaüstünün alt nesnelerinin bellek adresini al
      AltNesneBellekAdresi := Masaustu^.FAltNesneBellekAdresi;

      // masaüstü alt nesnelerini teker teker ara
      for i := 0 to Masaustu^.AltNesneSayisi - 1 do
      begin

        Pencere := AltNesneBellekAdresi[i];
        if(Pencere^.NesneTipi = gntPencere) then PPencere(Pencere)^.Ciz;
      end;
    end;
  end;
end;

{==============================================================================
  belirtilen koordinattaki nesneyi bulur
 ==============================================================================}
function GorselNesneBul(var AKonum: TKonum): PGorselNesne;
var
  PencereGN, SonBulunanGN, SorgulananGN,
  GenelGN: PGorselNesne;
  i, j: TISayi4;
  SonNesneA, NesneA: TAlan;
  PencereTipi: TPencereTipi;

  function AlanIcindeMi(AAlan: TAlan): Boolean;
  begin

    // farenin nesne koordinatları içerisinde olup olmadığını kontrol et
    Result := False;
    if(AKonum.Sol < AAlan.Sol) then Exit;
    if(AKonum.Sol > AAlan.Sag) then Exit;
    if(AKonum.Ust < AAlan.Ust) then Exit;
    if(AKonum.Ust > AAlan.Alt) then Exit;

    // tüm koşullar sağlanmışsa fare belirtilen nesnenin alanı içerisindedir
    Result := True;
  end;
begin

  // aktif masaüstü yok ise nil değeri ile çık
  if(GAktifMasaustu = nil) then Exit(nil);

  // 1. aktif menü mevcut mu? kontrol et
  SonBulunanGN := GAktifMenu;
  if(SonBulunanGN <> nil) then
  begin

    if(SonBulunanGN^.Gorunum) then
    begin

      SonNesneA.Sol := SonBulunanGN^.FKonum.Sol;
      SonNesneA.Ust := SonBulunanGN^.FKonum.Ust;
      SonNesneA.Sag := SonNesneA.Sol + SonBulunanGN^.FBoyut.Genislik;
      SonNesneA.Alt := SonNesneA.Ust + SonBulunanGN^.FBoyut.Yukseklik;

      if(AlanIcindeMi(SonNesneA)) then
      begin

        AKonum.Sol := AKonum.Sol - SonBulunanGN^.FKonum.Sol;
        AKonum.Ust := AKonum.Ust - SonBulunanGN^.FKonum.Ust;
        Exit(SonBulunanGN);
      end;
    end;
  end;

  // 2. aktif masaüstünün sorgulanması
  SonBulunanGN := GAktifMasaustu;

  SonNesneA.Sol := SonBulunanGN^.FKonum.Sol + SonBulunanGN^.FKalinlik.Sol;
  SonNesneA.Ust := SonBulunanGN^.FKonum.Ust + SonBulunanGN^.FKalinlik.Ust;
  SonNesneA.Sag := SonNesneA.Sol + SonBulunanGN^.FBoyut.Genislik;
  SonNesneA.Alt := SonNesneA.Ust + SonBulunanGN^.FBoyut.Yukseklik;

  if(SonBulunanGN^.AltNesneSayisi = 0) then
  begin

    AKonum.Sol := AKonum.Sol - SonBulunanGN^.FKonum.Sol;
    AKonum.Ust := AKonum.Ust - SonBulunanGN^.FKonum.Ust;
    Exit(SonBulunanGN);
  end;

  // 3. pencerelerin sorgulanması
  if(SonBulunanGN^.AltNesneSayisi > 0) then
  begin

    // alt nesnesi olan nesnenin alt nesnelerini ara. sondan başa doğru (3..0 gibi)
    for i := SonBulunanGN^.AltNesneSayisi - 1 downto 0 do
    begin

      // görsel nesneyi al
      PencereGN := SonBulunanGN^.FAltNesneBellekAdresi[i];

      if(PencereGN^.NesneTipi = gntPencere) then
      begin

        // görsel nesne görünür durumda mı ?
        if(PencereGN^.Gorunum) then
        begin

          NesneA.Sol := SonNesneA.Sol + PencereGN^.FKonum.Sol;
          NesneA.Ust := SonNesneA.Ust + PencereGN^.FKonum.Ust;
          NesneA.Sag := NesneA.Sol + PencereGN^.FBoyut.Genislik;
          NesneA.Alt := NesneA.Ust + PencereGN^.FBoyut.Yukseklik;

          // fare görsel nesne alan içerisinde mi ?
          if(AlanIcindeMi(NesneA)) then
          begin

            SonNesneA.Sol := NesneA.Sol;
            SonNesneA.Ust := NesneA.Ust;

            // 3.1 kontrol düğmelerinin sorgulanması
            PencereTipi := PPencere(PencereGN)^.FPencereTipi;
            if(PencereTipi = ptBoyutlanabilir) or (PencereTipi = ptIletisim) then
            begin

              // kapatma düğmesinin sorgulanması
              SorgulananGN := PPencere(PencereGN)^.FKapatmaDugmesi;
              NesneA.Sol := SonNesneA.Sol + SorgulananGN^.FKonum.Sol;
              NesneA.Ust := SonNesneA.Ust + SorgulananGN^.FKonum.Ust;
              NesneA.Sag := NesneA.Sol + SorgulananGN^.FBoyut.Genislik;
              NesneA.Alt := NesneA.Ust + SorgulananGN^.FBoyut.Yukseklik;

              if(AlanIcindeMi(NesneA)) then
              begin

                AKonum.Sol := (AKonum.Sol - NesneA.Sol);
                AKonum.Ust := (AKonum.Ust - NesneA.Ust);
                Exit(SorgulananGN);
              end;

              if(PencereTipi = ptBoyutlanabilir) then
              begin

                // küçültme düğmesinin sorgulanması
                SorgulananGN := PPencere(PencereGN)^.FKucultmeDugmesi;
                NesneA.Sol := SonNesneA.Sol + SorgulananGN^.FKonum.Sol;
                NesneA.Ust := SonNesneA.Ust + SorgulananGN^.FKonum.Ust;
                NesneA.Sag := NesneA.Sol + SorgulananGN^.FBoyut.Genislik;
                NesneA.Alt := NesneA.Ust + SorgulananGN^.FBoyut.Yukseklik;

                if(AlanIcindeMi(NesneA)) then
                begin

                  AKonum.Sol := (AKonum.Sol - NesneA.Sol);
                  AKonum.Ust := (AKonum.Ust - NesneA.Ust);
                  Exit(SorgulananGN);
                end;

                // büyütme düğmesinin sorgulanması
                SorgulananGN := PPencere(PencereGN)^.FBuyutmeDugmesi;
                NesneA.Sol := SonNesneA.Sol + SorgulananGN^.FKonum.Sol;
                NesneA.Ust := SonNesneA.Ust + SorgulananGN^.FKonum.Ust;
                NesneA.Sag := NesneA.Sol + SorgulananGN^.FBoyut.Genislik;
                NesneA.Alt := NesneA.Ust + SorgulananGN^.FBoyut.Yukseklik;

                if(AlanIcindeMi(NesneA)) then
                begin

                  AKonum.Sol := (AKonum.Sol - NesneA.Sol);
                  AKonum.Ust := (AKonum.Ust - NesneA.Ust);
                  Exit(SorgulananGN);
                end;
              end;
            end;

            // pencere nesnesinin kalınlığını da son koordinata ekle
            SonNesneA.Sol += PencereGN^.FKalinlik.Sol;
            SonNesneA.Ust += PencereGN^.FKalinlik.Ust;
            SonBulunanGN := PencereGN;

            // 4 - alt nesnelerin sorgulanması
            while True do
            begin

              GenelGN := nil;

              if(SonBulunanGN^.AltNesneSayisi > 0) then
              begin

                // alt nesnesi olan nesnenin alt nesnelerini ara. sondan başa doğru (3..0 gibi)
                for j := SonBulunanGN^.AltNesneSayisi - 1 downto 0 do
                begin

                  // görsel nesneyi al
                  SorgulananGN := SonBulunanGN^.FAltNesneBellekAdresi[j];

                  // görsel nesne görünür durumda mı ?
                  if(SorgulananGN^.Gorunum) then
                  begin

                    NesneA.Sol := SonNesneA.Sol + SorgulananGN^.FKonum.Sol;
                    NesneA.Ust := SonNesneA.Ust + SorgulananGN^.FKonum.Ust;
                    NesneA.Sag := NesneA.Sol + SorgulananGN^.FBoyut.Genislik;
                    NesneA.Alt := NesneA.Ust + SorgulananGN^.FBoyut.Yukseklik;

                    // fare görsel nesne alan içerisinde mi ?
                    if(AlanIcindeMi(NesneA)) then
                    begin

                      SonNesneA.Sol := NesneA.Sol;
                      SonNesneA.Ust := NesneA.Ust;
                      GenelGN := SorgulananGN;
                      SonBulunanGN := GenelGN;
                      Break;
                    end;
                  end;
                end;

                if(GenelGN = nil) then
                begin

                  if(SonBulunanGN^.NesneTipi = gntPencere) then
                  begin

                    SonNesneA.Sol -= SonBulunanGN^.FKalinlik.Sol;
                    SonNesneA.Ust -= SonBulunanGN^.FKalinlik.Ust;

                    AKonum.Sol := (AKonum.Sol - SonNesneA.Sol);
                    AKonum.Ust := (AKonum.Ust - SonNesneA.Ust);
                    Exit(SonBulunanGN);
                  end
                  else
                  begin

                    AKonum.Sol := (AKonum.Sol - SonNesneA.Sol);
                    AKonum.Ust := (AKonum.Ust - SonNesneA.Ust);
                    Exit(SonBulunanGN);
                  end;
                end else SonBulunanGN := GenelGN;
              end
              else
              begin

                if(SonBulunanGN^.NesneTipi = gntPencere) then
                begin

                  SonNesneA.Sol -= SonBulunanGN^.FKalinlik.Sol;
                  SonNesneA.Ust -= SonBulunanGN^.FKalinlik.Ust;

                  AKonum.Sol := (AKonum.Sol - SonNesneA.Sol);
                  AKonum.Ust := (AKonum.Ust - SonNesneA.Ust);
                  Exit(SonBulunanGN);
                end
                else
                begin

                  AKonum.Sol := (AKonum.Sol - SonNesneA.Sol);
                  AKonum.Ust := (AKonum.Ust - SonNesneA.Ust);
                  Exit(SonBulunanGN);
                end;
              end;
            end;
          end;
        end;
      end;
    end;

    AKonum.Sol := AKonum.Sol - SonBulunanGN^.FKonum.Sol;
    AKonum.Ust := AKonum.Ust - SonBulunanGN^.FKonum.Ust;
    Exit(SonBulunanGN);
  end;
end;

{==============================================================================
  nesnenin en üst atası olan masaüstü veya pencere nesnesini alır
 ==============================================================================}
function EnUstNesneyiAl(AGorselNesne: PGorselNesne): PGorselNesne;
begin

  // nesnenin ata nesnesi masaüstü veya pencere olana kadar ara
  while (AGorselNesne^.NesneTipi <> gntMasaustu) or (AGorselNesne^.NesneTipi <> gntPencere) do
  begin

    AGorselNesne := AGorselNesne^.AtaNesne;
    if(AGorselNesne = nil) then Exit(nil);
  end;

  Result := AGorselNesne;
end;

{==============================================================================
  nesnenin en üst atası olan masaüstü veya pencere nesnesini alır
 ==============================================================================}
function EnUstPencereNesnesiniAl(AGorselNesne: PGorselNesne): PPencere;
begin

  // nesnenin ata nesnesi pencere olana kadar ara
  while (AGorselNesne^.NesneTipi <> gntPencere) do
  begin

    AGorselNesne := AGorselNesne^.AtaNesne;
    if(AGorselNesne = nil) then Exit(nil);
  end;

  Result := PPencere(AGorselNesne);
end;

{==============================================================================
  nesnenin fare olaylarını yakalamasını sağlar
 ==============================================================================}
procedure OlayYakalamayaBasla(AGorselNesne: PGorselNesne);
begin

  // olaylar başka nesne tarafından yakalanmıyorsa, olay nesnesini
  // yakalanan nesne olarak ata
  if(YakalananGorselNesne = nil) then YakalananGorselNesne := AGorselNesne;
end;

{==============================================================================
  fare olayları yakalama işlevi nesne tarafından serbest bırakılır
 ==============================================================================}
procedure OlayYakalamayiBirak(AGorselNesne: PGorselNesne);
begin

  // olay daha önce nesne tarafından yakalanmışsa, nesneyi yakalanan nesne
  // olmaktan çıkar
  if(YakalananGorselNesne = AGorselNesne) then YakalananGorselNesne := nil;
end;

end.
