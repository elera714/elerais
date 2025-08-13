{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_degerlistesi.pas
  Dosya İşlevi: değer listesi (TValueListeEditor) yönetim işlevlerini içerir

  Güncelleme Tarihi: 26/02/2025

 ==============================================================================}
{$mode objfpc}
unit gn_degerlistesi;

interface

uses gorselnesne, paylasim, n_yazilistesi, n_sayilistesi, gn_panel;

type
  PDegerListesi = ^TDegerListesi;
  TDegerListesi = object(TPanel)
  private
    FSeciliSiraNo: TISayi4;               // seçili sıra değeri
    FGorunenIlkSiraNo: TISayi4;           // değer listesinde en üstte görüntülenen elemanın sıra değeri
    FGorunenElemanSayisi: TISayi4;        // kullanıcıya nesne içerisinde gösterilen eleman sayısı
    FKolonAdlari: PYaziListesi;           // kolon ad listesi
    FKolonUzunluklari: PSayiListesi;      // kolon uzunlukları
    FDegerler,                            // kolon içerik değerleri
    FDegerDizisi: PYaziListesi;           // FDegerler içeriğini bölümlemek için kullanılacak
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4): PDegerListesi;
    procedure YokEt(AKimlik: TKimlik);
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    function SeciliSatirDegeriniAl: string;
    procedure Bolumle(ABicimlenmisDeger: string; AAyiracDeger: Char;
      DegerDizisi: PYaziListesi);
    function BaslikEkle(AKolon1, AKolon2: string; AKolon1U: TISayi4): Boolean;
    function DegerEkle(ADeger: string; AYaziRengi: TRenk): Boolean;
    procedure DegerIceriginiTemizle;
  end;

function DegerListesiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;

implementation

uses genel, gn_islevler, gn_pencere, temelgorselnesne, gorev;

{==============================================================================
  değer listesi kesme çağrılarını yönetir
 ==============================================================================}
function DegerListesiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne;
  Pencere: PPencere;
  DegerListesi: PDegerListesi;
  Hiza: THiza;
  p: PKarakterKatari;
  Kolon1Ad, Kolon2Ad: string;
  KolonU: TISayi4;
begin

  case AIslevNo of

    // nesne oluştur
    ISLEV_OLUSTUR:
    begin

      GN := GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^);
    end;

    ISLEV_GOSTER:
    begin

      DegerListesi := PDegerListesi(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      DegerListesi^.Goster;
    end;

    // değer listesi nesnesini hizala
    ISLEV_HIZALA:
    begin

      DegerListesi := PDegerListesi(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      DegerListesi^.FHiza := Hiza;

      Pencere := PPencere(DegerListesi^.FAtaNesne);
      Pencere^.Guncelle;
    end;

    // değer listesine değer ekle
    $010F:
    begin

      DegerListesi := PDegerListesi(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntDegerListesi));
      if(DegerListesi <> nil) then Result := TISayi4(DegerListesi^.DegerEkle(
        PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi)^,
        PRenk(ADegiskenler + 08)^));
    end;

    // liste içeriğini temizle
    $020F:
    begin

      DegerListesi := PDegerListesi(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntDegerListesi));
      if(DegerListesi <> nil) then
      begin

        // içeriği temizle, değerleri ön değerlere çek
        DegerListesi^.DegerIceriginiTemizle;
      end;
    end;

    // seçilen yazı (text) değerini geri döndür
    $030E:
    begin

      DegerListesi := PDegerListesi(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntDegerListesi));
      if(DegerListesi <> nil) then Result := DegerListesi^.FSeciliSiraNo;
      p := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
      p^ := DegerListesi^.SeciliSatirDegeriniAl;
    end;

    // değer listesinin başlıklarını belirle
    $040F:
    begin

      DegerListesi := PDegerListesi(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntDegerListesi));
      if(DegerListesi <> nil) then
      begin

        Kolon1Ad := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi)^;
        Kolon2Ad := PKarakterKatari(PSayi4(ADegiskenler + 08)^ + FAktifGorevBellekAdresi)^;
        KolonU := PISayi4(ADegiskenler + 12)^;
        Result := TISayi4(DegerListesi^.BaslikEkle(Kolon1Ad, Kolon2Ad, KolonU));
      end;
    end;

    // seçilen sıra değerini al
    $050E:
    begin

      DegerListesi := PDegerListesi(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntDegerListesi));
      if(DegerListesi <> nil) then Result := DegerListesi^.FSeciliSiraNo;
    end;

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  değer listesi nesnesini oluşturur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
var
  DegerListesi: PDegerListesi;
begin

  DegerListesi := DegerListesi^.Olustur(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik);
  if(DegerListesi = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := DegerListesi^.Kimlik;
end;

{==============================================================================
  değer listesi nesnesini oluşturur
 ==============================================================================}
function TDegerListesi.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4): PDegerListesi;
var
  DegerListesi: PDegerListesi;
begin

  DegerListesi := PDegerListesi(inherited Olustur(AKullanimTipi, AAtaNesne, ASol, AUst,
    AGenislik, AYukseklik, 3, $828790, RENK_BEYAZ, 0, ''));

  DegerListesi^.NesneTipi := gntDegerListesi;

  DegerListesi^.Baslik := '';

  DegerListesi^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  DegerListesi^.Odaklanilabilir := True;
  DegerListesi^.Odaklanildi := False;

  DegerListesi^.OlayCagriAdresi := @OlaylariIsle;

  DegerListesi^.FKolonAdlari := YaziListesi0.Olustur;
  DegerListesi^.FKolonUzunluklari := SayiListesi0.Olustur;
  DegerListesi^.FDegerler := YaziListesi0.Olustur;
  DegerListesi^.FDegerDizisi := YaziListesi0.Olustur;

  // nesnenin kullanacağı diğer değerler
  DegerListesi^.FGorunenIlkSiraNo := 0;
  DegerListesi^.FSeciliSiraNo := -1;

  // değer listesi nesnesinde görüntülenecek eleman sayısı
  DegerListesi^.FGorunenElemanSayisi := (AYukseklik - 24) div 21;

  // nesne adresini geri döndür
  Result := DegerListesi;
end;

{==============================================================================
  değer listesi nesnesini yok eder
 ==============================================================================}
procedure TDegerListesi.YokEt(AKimlik: TKimlik);
var
  DegerListesi: PDegerListesi;
begin

  DegerListesi := PDegerListesi(GorselNesneler0.NesneAl(Kimlik));
  if(DegerListesi = nil) then Exit;

  if(DegerListesi^.FDegerler <> nil) then YaziListesi0.YokEt(DegerListesi^.FDegerler^.Kimlik);
  if(DegerListesi^.FDegerDizisi <> nil) then YaziListesi0.YokEt(DegerListesi^.FDegerDizisi^.Kimlik);
  if(DegerListesi^.FKolonAdlari <> nil) then YaziListesi0.YokEt(DegerListesi^.FKolonAdlari^.Kimlik);
  if(DegerListesi^.FKolonUzunluklari <> nil) then SayiListesi0.YokEt(DegerListesi^.FKolonUzunluklari^.Kimlik);

  GorselNesneler0.YokEt(AKimlik);
end;

{==============================================================================
  değer listesi nesnesini görüntüler
 ==============================================================================}
procedure TDegerListesi.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  değer listesi nesnesini gizler
 ==============================================================================}
procedure TDegerListesi.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  değer listesi nesnesini hizalandırır
 ==============================================================================}
procedure TDegerListesi.Hizala;
var
  DegerListesi: PDegerListesi;
  Kolon1U: TSayi4;
begin

  DegerListesi := PDegerListesi(GorselNesneler0.NesneAl(Kimlik));
  if(DegerListesi = nil) then Exit;

  inherited Hizala;

  // 2. kolonun uzunluğu nesnenin uzunluğuna göre yeniden hesaplanıyor
  if(DegerListesi^.FKolonUzunluklari^.ElemanSayisi = 2) then
  begin

    Kolon1U := DegerListesi^.FKolonUzunluklari^.Sayi[0];
    DegerListesi^.FKolonUzunluklari^.Temizle;

    DegerListesi^.FKolonUzunluklari^.Ekle(Kolon1U);
    DegerListesi^.FKolonUzunluklari^.Ekle(DegerListesi^.FAtananAlan.Genislik - Kolon1U - 3);
  end;
end;

{==============================================================================
  değer listesi nesnesini çizer
 ==============================================================================}
procedure TDegerListesi.Ciz;
var
  Pencere: PPencere;
  DegerListesi: PDegerListesi;
  KolonAdlari: PYaziListesi;
  KolonUzunluklari: PSayiListesi;
  Alan1, Alan2: TAlan;
  ElemanSayisi, SatirNo, i, j,
  Sol, Ust, DegerSayisi: TISayi4;
  s: string;
  RY: TRenkYazi;
begin

  DegerListesi := PDegerListesi(GorselNesneler0.NesneAl(Kimlik));
  if(DegerListesi = nil) then Exit;

  inherited Ciz;

  // liste kutusunun üst nesneye bağlı olarak koordinatlarını al
  Alan1 := DegerListesi^.FCizimAlan;

  // ata nesne bir pencere mi?
  Pencere := EnUstPencereNesnesiniAl(DegerListesi);
  if(Pencere = nil) then Exit;

  KolonUzunluklari := DegerListesi^.FKolonUzunluklari;
  KolonAdlari := DegerListesi^.FKolonAdlari;

  // tanımlanmış hiçbir kolon yok ise, çık
  if(KolonAdlari^.ElemanSayisi = 0) then Exit;

  // kolon başlık ve değerleri
  Sol := Alan1.Sol + 1;
  for i := 0 to KolonUzunluklari^.ElemanSayisi - 1 do
  begin

    Sol += KolonUzunluklari^.Sayi[i];

    // dikey kılavuz çizgisi
    DegerListesi^.Cizgi(DegerListesi, ctDuz, Sol, Alan1.Ust + 1, Sol, Alan1.Alt - 1, $F0F0F0);

    // başlık dolgusu
    Alan2.Sol := Sol - KolonUzunluklari^.Sayi[i];
    Alan2.Ust := Alan1.Ust + 1;
    Alan2.Sag := Sol - 1;
    Alan2.Alt := Alan1.Ust + 1 + 22;
    DegerListesi^.EgimliDoldur3(DegerListesi, Alan2, $EAECEE, $ABB2B9);

    // başlık
    DegerListesi^.AlanaYaziYaz(DegerListesi, Alan2, 4, 3, KolonAdlari^.Yazi[i], RENK_LACIVERT);

    Inc(Sol);    // 1 px çizgi kalınlığı
  end;

  // yatay kılavuz çizgileri
  Ust := Alan1.Ust + 1 + 22;
  Ust += 20;
  while Ust < Alan1.Alt do
  begin

    DegerListesi^.Cizgi(DegerListesi, ctDuz, Alan1.Sol + 1, Ust, Alan1.Sag - 1, Ust, $F0F0F0);
    Ust += 1 + 20;
  end;

  // değer listesi nesnesinde görüntülenecek eleman sayısı
  DegerListesi^.FGorunenElemanSayisi := ((DegerListesi^.FCizimAlan.Alt -
    DegerListesi^.FCizimAlan.Ust) - 24) div 21;

  // değer listesi kutusunda görüntülenecek eleman sayısının belirlenmesi
  if(FDegerler^.ElemanSayisi > DegerListesi^.FGorunenElemanSayisi) then
    ElemanSayisi := DegerListesi^.FGorunenElemanSayisi + DegerListesi^.FGorunenIlkSiraNo
  else ElemanSayisi := FDegerler^.ElemanSayisi + DegerListesi^.FGorunenIlkSiraNo;

  Ust := Alan1.Ust + 1 + 22;
  Ust += 20;
  SatirNo := 0;
  KolonUzunluklari := DegerListesi^.FKolonUzunluklari;

  // değer listesi değerlerini yerleştir
  for SatirNo := DegerListesi^.FGorunenIlkSiraNo to ElemanSayisi - 1 do
  begin

    // değeri belirtilen karakter ile bölümle
    Bolumle(FDegerler^.Yazi[SatirNo], '|', FDegerDizisi);
    RY := FDegerler^.RenkYaziAl(SatirNo);

    Sol := Alan1.Sol + 1;
    if(FDegerDizisi^.ElemanSayisi > 0) then
    begin

      if(FDegerDizisi^.ElemanSayisi > 1) then
        DegerSayisi := 2
      else DegerSayisi := 1;

      for j := 0 to DegerSayisi - 1 do
      begin

        s := FDegerDizisi^.Yazi[j];
        Alan2.Sol := Sol + 1;
        Alan2.Ust := Ust - 20 + 1;
        Alan2.Sag := Sol + KolonUzunluklari^.Sayi[j] - 1;
        Alan2.Alt := Ust - 1;

        // satır verisini boyama ve yazma işlemi
        if(SatirNo = DegerListesi^.FSeciliSiraNo) then
        begin

          DegerListesi^.DikdortgenDoldur(DegerListesi, Alan2.Sol - 1, Alan2.Ust - 1,
            Alan2.Sag, Alan2.Alt, $3EC5FF, $3EC5FF);
        end
        else
        begin

          DegerListesi^.DikdortgenDoldur(DegerListesi, Alan2.Sol - 1, Alan2.Ust - 1,
            Alan2.Sag, Alan2.Alt, RENK_BEYAZ, RENK_BEYAZ);
        end;

        DegerListesi^.AlanaYaziYaz(DegerListesi, Alan2, 2, 2, s, RY.Renk);

        Sol += 1 + KolonUzunluklari^.Sayi[j];
      end;
    end;

    Ust += 1 + 20;
  end;
end;

{==============================================================================
  değer listesi nesne olaylarını işler
 ==============================================================================}
procedure TDegerListesi.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere;
  DegerListesi: PDegerListesi;
  i, j: TISayi4;
begin

  DegerListesi := PDegerListesi(AGonderici);

  // sol fare tuş basımı
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // değer listesinin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(DegerListesi);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere^.FAktifNesne := DegerListesi;
    DegerListesi^.Odaklanildi := True;

    // sol tuşa basım işlemi nesnenin olay alanında mı gerçekleşti ?
    if(DegerListesi^.FareNesneOlayAlanindaMi(DegerListesi)) then
    begin

      // fare olaylarını yakala
      OlayYakalamayaBasla(DegerListesi);

      // seçilen sırayı yeniden belirle
      j := (AOlay.Deger2 - 24) div 21;

      // bu değere kaydırılan değeri de ekle
      DegerListesi^.FSeciliSiraNo := (j + DegerListesi^.FGorunenIlkSiraNo);

      // değer listesi nesnesini yeniden çiz
      DegerListesi^.Ciz;

      // uygulamaya veya efendi nesneye mesaj gönder
      if not(DegerListesi^.OlayYonlendirmeAdresi = nil) then
        DegerListesi^.OlayYonlendirmeAdresi(DegerListesi, AOlay)
      else Gorevler0.OlayEkle(DegerListesi^.GorevKimlik, AOlay);
    end;
  end

  // sol fare tuş bırakım işlemi
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    OlayYakalamayiBirak(DegerListesi);

    // fare bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(DegerListesi^.FareNesneOlayAlanindaMi(DegerListesi)) then
    begin

      // yakalama & bırakma işlemi bu nesnede olduğu için
      // nesneye FO_TIKLAMA mesajı gönder
      AOlay.Olay := FO_TIKLAMA;
      if not(DegerListesi^.OlayYonlendirmeAdresi = nil) then
        DegerListesi^.OlayYonlendirmeAdresi(DegerListesi, AOlay)
      else Gorevler0.OlayEkle(DegerListesi^.GorevKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    if not(DegerListesi^.OlayYonlendirmeAdresi = nil) then
      DegerListesi^.OlayYonlendirmeAdresi(DegerListesi, AOlay)
    else Gorevler0.OlayEkle(DegerListesi^.GorevKimlik, AOlay);
  end

  // fare hakeret işlemi
  else if(AOlay.Olay = FO_HAREKET) then
  begin

    // eğer nesne yakalanmış ise
    if(YakalananGorselNesne <> nil) then
    begin

      // fare değer listesi nesnesinin yukarısında ise
      if(AOlay.Deger2 < 0) then
      begin

        j := DegerListesi^.FGorunenIlkSiraNo;
        Dec(j);
        if(j >= 0) then
        begin

          DegerListesi^.FGorunenIlkSiraNo := j;
          DegerListesi^.FSeciliSiraNo := j;
        end;
      end

      // fare değer listesi nesnesinin aşağısında ise
      else if(AOlay.Deger2 > DegerListesi^.FAtananAlan.Yukseklik) then
      begin

        // azami kaydırma değeri
        i := DegerListesi^.FKolonAdlari^.ElemanSayisi - DegerListesi^.FGorunenElemanSayisi;
        if(i < 0) then i := 0;

        j := DegerListesi^.FGorunenIlkSiraNo;
        Inc(j);
        if(j < i) then
        begin

          DegerListesi^.FGorunenIlkSiraNo := j;
          i := (AOlay.Deger2 - 24) div 21;
          DegerListesi^.FSeciliSiraNo := i + DegerListesi^.FGorunenIlkSiraNo;
        end
      end

      // fare değer listesi kutusunun içerisinde ise
      else
      begin

        i := (AOlay.Deger2 - 24) div 21;
        DegerListesi^.FSeciliSiraNo := i + DegerListesi^.FGorunenIlkSiraNo;
      end;

      // değer listesi nesnesini yeniden çiz
      DegerListesi^.Ciz;

      // uygulamaya veya efendi nesneye mesaj gönder
      if not(DegerListesi^.OlayYonlendirmeAdresi = nil) then
        DegerListesi^.OlayYonlendirmeAdresi(DegerListesi, AOlay)
      else Gorevler0.OlayEkle(DegerListesi^.GorevKimlik, AOlay);
    end

    // nesne yakalanmamış ise uygulamaya sadece mesaj gönder
    else
    begin

      // uygulamaya veya efendi nesneye mesaj gönder
      if not(DegerListesi^.OlayYonlendirmeAdresi = nil) then
        DegerListesi^.OlayYonlendirmeAdresi(DegerListesi, AOlay)
      else Gorevler0.OlayEkle(DegerListesi^.GorevKimlik, AOlay);
    end;
  end

  else if(AOlay.Olay = FO_KAYDIRMA) then
  begin

    // listeyi yukarı kaydırma işlemi. ilk elemana doğru
    if(AOlay.Deger1 < 0) then
    begin

      j := DegerListesi^.FGorunenIlkSiraNo;
      Dec(j);
      if(j >= 0) then DegerListesi^.FGorunenIlkSiraNo := j;
    end

    // listeyi aşağıya kaydırma işlemi. son elemana doğru
    else if(AOlay.Deger1 > 0) then
    begin

      // azami kaydırma değeri
      i := DegerListesi^.FDegerler^.ElemanSayisi - DegerListesi^.FGorunenElemanSayisi;
      if(i < 0) then i := 0;

      j := DegerListesi^.FGorunenIlkSiraNo;
      Inc(j);
      if(j < i) then DegerListesi^.FGorunenIlkSiraNo := j;
    end;

    DegerListesi^.Ciz;
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := DegerListesi^.FareImlecTipi;
end;

{==============================================================================
  seçili elemanın yazı (text) değerini geri döndürür
 ==============================================================================}
function TDegerListesi.SeciliSatirDegeriniAl: string;
var
  DegerListesi: PDegerListesi;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  DegerListesi := PDegerListesi(GorselNesneler0.NesneTipiniKontrolEt(Kimlik, gntDegerListesi));
  if(DegerListesi = nil) then Exit;

  if(FSeciliSiraNo = -1) or (FSeciliSiraNo > FDegerler^.ElemanSayisi) then Exit('');

  Result := DegerListesi^.FDegerler^.Yazi[FSeciliSiraNo];
end;

{==============================================================================
  | ayıracıyla gelen karakter katarını bölümler
 ==============================================================================}
procedure TDegerListesi.Bolumle(ABicimlenmisDeger: string; AAyiracDeger: Char;
  DegerDizisi: PYaziListesi);
var
  Uzunluk, i: TISayi4;
  s: string;
begin

  DegerDizisi^.Temizle;

  Uzunluk := Length(ABicimlenmisDeger);
  if(Uzunluk > 0) then
  begin

    i := 1;
    s := '';
    while i <= Uzunluk do
    begin

      if(ABicimlenmisDeger[i] = AAyiracDeger) or (i = Uzunluk) then
      begin

        if(i = Uzunluk) then s += ABicimlenmisDeger[i];

        if(Length(s) > 0) then
        begin

          DegerDizisi^.Ekle(s);
          s := '';
        end;
      end else s += ABicimlenmisDeger[i];

      Inc(i);
    end;
  end;
end;

{==============================================================================
  değer listesine kolon ekler
 ==============================================================================}
function TDegerListesi.BaslikEkle(AKolon1, AKolon2: string; AKolon1U: TISayi4): Boolean;
var
  DegerListesi: PDegerListesi;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  DegerListesi := PDegerListesi(GorselNesneler0.NesneAl(Kimlik));
  if(DegerListesi = nil) then Exit;

  DegerListesi^.FKolonAdlari^.Ekle(AKolon1);
  DegerListesi^.FKolonUzunluklari^.Ekle(AKolon1U);

  DegerListesi^.FKolonAdlari^.Ekle(AKolon2);
  DegerListesi^.FKolonUzunluklari^.Ekle(DegerListesi^.FAtananAlan.Genislik - AKolon1U - 3);

  Result := True;
end;

function TDegerListesi.DegerEkle(ADeger: string; AYaziRengi: TRenk): Boolean;
var
  DegerListesi: PDegerListesi;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  DegerListesi := PDegerListesi(GorselNesneler0.NesneAl(Kimlik));
  if(DegerListesi = nil) then Exit;

  DegerListesi^.FDegerler^.Ekle(ADeger, AYaziRengi);

  if(DegerListesi^.Gorunum) then DegerListesi^.Ciz;

  Result := True;
end;

procedure TDegerListesi.DegerIceriginiTemizle;
var
  DegerListesi: PDegerListesi;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  DegerListesi := PDegerListesi(GorselNesneler0.NesneAl(Kimlik));
  if(DegerListesi = nil) then Exit;

  DegerListesi^.FDegerler^.Temizle;
  DegerListesi^.FGorunenIlkSiraNo := 0;
  DegerListesi^.FSeciliSiraNo := -1;

  DegerListesi^.Ciz;
end;

end.
