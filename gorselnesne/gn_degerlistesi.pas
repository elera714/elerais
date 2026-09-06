{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_degerlistesi.pas
  Dosya İşlevi: değer listesi (TValueListeEditor) yönetim işlevlerini içerir

  Güncelleme Tarihi: 17/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_degerlistesi;

interface

uses gorselnesne, paylasim, n_yazilistesi, n_sayilistesi, gn_panel;

type
  PDegerListesi = ^TDegerListesi;
  TDegerListesi = class(TPanel)
  private
    FKolonAdlari: TYaziListesi;           // kolon ad listesi
    FKolonUzunluklari: TSayiListesi;      // kolon uzunlukları
    FDegerler,                            // kolon içerik değerleri
    FDegerDizisi: TYaziListesi;           // FDegerler içeriğini bölümlemek için kullanılacak
  public
    constructor Create; override;
    destructor Destroy; override;
    function Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4): TISayi4;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
    function SeciliSatirDegeriniAl: string;
    procedure Bolumle(ABicimlenmisDeger: string; AAyiracDeger: Char;
      DegerDizisi: TYaziListesi);
    function BaslikEkle(AKolon1, AKolon2: string; AKolon1U: TISayi4): Boolean;
    function DegerEkle(ADeger: string; AYaziRengi: TRenk): Boolean;
    procedure DegerIceriginiTemizle;
    // seçili sıra değeri
    property SeciliSiraNo: TISayi4 read FIDeger1 write FIDeger1;
    // değer listesinde en üstte görüntülenen elemanın sıra değeri
    property GorunenIlkSiraNo: TISayi4 read FIDeger2 write FIDeger2;
    // kullanıcıya nesne içerisinde gösterilen eleman sayısı
    property GorunenElemanSayisi: TISayi4 read FIDeger3 write FIDeger3;
  end;

function DegerListesiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function DegerListesiGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;

implementation

uses gn_islevler, gn_pencere, gorev, src_ps2;

{==============================================================================
  değer listesi kesme çağrılarını yönetir
 ==============================================================================}
function DegerListesiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  Pencere: TPencere;
  DegerListesi: TDegerListesi;
  Hiza: THiza;
  p: PKarakterKatari;
  Kolon1Ad, Kolon2Ad: string;
  KolonU: TISayi4;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    // nesne oluştur
    ISLEV_OLUSTUR:
    begin

      GN := GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := DegerListesiGNOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^);
    end;

    ISLEV_GOSTER:
    begin

      DegerListesi := TDegerListesi(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      DegerListesi.Goster;
    end;

    // değer listesi nesnesini hizala
    ISLEV_HIZALA:
    begin

      DegerListesi := TDegerListesi(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      DegerListesi.FHiza := Hiza;

      Pencere := TPencere(DegerListesi.FAtaNesne);
      Pencere.Guncelle;
    end;

    // değer listesine değer ekle
    $010F:
    begin

      DegerListesi := TDegerListesi(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntDegerListesi));
      if(DegerListesi <> nil) then Result := TISayi4(DegerListesi.DegerEkle(
        PKarakterKatari(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr)^,
        PRenk(ADegiskenler + 08)^));
    end;

    // liste içeriğini temizle
    $020F:
    begin

      DegerListesi := TDegerListesi(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntDegerListesi));
      if(DegerListesi <> nil) then
      begin

        // içeriği temizle, değerleri ön değerlere çek
        DegerListesi.DegerIceriginiTemizle;
      end;
    end;

    // seçilen yazı (text) değerini geri döndür
    $030E:
    begin

      DegerListesi := TDegerListesi(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntDegerListesi));
      if(DegerListesi <> nil) then Result := DegerListesi.SeciliSiraNo;
      p := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr);
      p^ := DegerListesi.SeciliSatirDegeriniAl;
    end;

    // değer listesinin başlıklarını belirle
    $040F:
    begin

      DegerListesi := TDegerListesi(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntDegerListesi));
      if(DegerListesi <> nil) then
      begin

        Kolon1Ad := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr)^;
        Kolon2Ad := PKarakterKatari(PSayi4(ADegiskenler + 08)^ + GGorevler.FAktifGrvBelAdr)^;
        KolonU := PISayi4(ADegiskenler + 12)^;
        Result := TISayi4(DegerListesi.BaslikEkle(Kolon1Ad, Kolon2Ad, KolonU));
      end;
    end;

    // seçilen sıra değerini al
    $050E:
    begin

      DegerListesi := TDegerListesi(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntDegerListesi));
      if(DegerListesi <> nil) then Result := DegerListesi.SeciliSiraNo;
    end;

    // seçilen sıra değerini belirle
    $050F:
    begin

      DegerListesi := TDegerListesi(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntDegerListesi));
      if(DegerListesi <> nil) then
      begin

        DegerListesi.SeciliSiraNo := PISayi4(ADegiskenler + 04)^;
        DegerListesi.Ciz;
      end;
    end;
  end;
end;

{==============================================================================
  uygulama için değer listesi nesnesi oluşturur - api
 ==============================================================================}
function DegerListesiGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
var
  DegerListesi: TDegerListesi;
begin

  DegerListesi := TDegerListesi.Create;

  if(DegerListesi = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    DegerListesi.Ozellestir(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik);

    Result := DegerListesi.Kimlik;
  end;
end;

{==============================================================================
  değer listesi nesnesi oluşturur
 ==============================================================================}
constructor TDegerListesi.Create;
begin

  inherited Create;

  NesneTipi := gntDegerListesi;

  GGNesneler.GorselNesne[FSiraNo] := Self;

  FKolonAdlari := TYaziListesi.Create;
  FKolonUzunluklari := TSayiListesi.Create;
  FDegerler := TYaziListesi.Create;
  FDegerDizisi := TYaziListesi.Create;
end;

{==============================================================================
  değer listesi nesnesini yok eder
 ==============================================================================}
destructor TDegerListesi.Destroy;
begin

  if(FDegerDizisi <> nil) then FDegerDizisi.Destroy;
  if(FDegerler <> nil) then FDegerler.Destroy;
  if(FKolonUzunluklari <> nil) then FKolonUzunluklari.Destroy;
  if(FKolonAdlari <> nil) then FKolonAdlari.Destroy;

  GGNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  değer listesi nesnesini özelleştirir
 ==============================================================================}
function TDegerListesi.Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4): TISayi4;
begin

  Yapilandir2(AKullanimTipi, Self, AAtaNesne, ASol, AUst, AGenislik, AYukseklik,
    3, $828790, RENK_BEYAZ, 0, '');

  OlayCagriAdr := @OlaylariIsle;

  Odaklanilabilir := True;
  Odaklanildi := False;

  // nesnenin kullanacağı diğer değerler
  GorunenIlkSiraNo := 0;
  SeciliSiraNo := -1;

  // değer listesi nesnesinde görüntülenecek eleman sayısı
  GorunenElemanSayisi := (AYukseklik - 24) div 21;

  // geri dönüş değeri
  Result := HATA_YOK;
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
  Kolon1U: TSayi4;
begin

  inherited Hizala;

  // 2. kolonun uzunluğu nesnenin uzunluğuna göre yeniden hesaplanıyor
  if(FKolonUzunluklari.ElemanSayisi = 2) then
  begin

    Kolon1U := FKolonUzunluklari.Sayi[0];
    FKolonUzunluklari.Temizle;

    FKolonUzunluklari.Ekle(Kolon1U);
    FKolonUzunluklari.Ekle(FAtananAlan.Genislik - Kolon1U - 3);
  end;
end;

{==============================================================================
  değer listesi nesnesini çizer
 ==============================================================================}
procedure TDegerListesi.Ciz;
var
  Pencere: TPencere;
  CizimAlani, CizimAlani2: TAlan;
  ElemanSayisi, SatirNo, i, j,
  Sol, Ust, DegerSayisi: TISayi4;
  s: string;
  RY: TRenkYazi;
begin

  inherited Ciz;

  // değer listesi nesnesinin üst nesneye bağlı olarak koordinatlarını al
  CizimAlani := FCizimAlani;

  // ata nesne bir pencere mi?
  Pencere := GGNesneler.EnUstPencereNesnesiniAl(Self);
  if(Pencere = nil) then Exit;

  // tanımlanmış hiçbir kolon yok ise, çık
  if(FKolonAdlari.ElemanSayisi = 0) then Exit;

  // kolon başlık ve değerleri
  Sol := CizimAlani.Sol + 1;
  for i := 0 to FKolonUzunluklari.ElemanSayisi - 1 do
  begin

    Sol := Sol + FKolonUzunluklari.Sayi[i];

    // dikey kılavuz çizgisi
    Cizgi(Self, ctDuz, Sol, CizimAlani.Ust + 1, Sol, CizimAlani.Alt - 1, $F0F0F0);

    // başlık dolgusu
    CizimAlani2.Sol := Sol - FKolonUzunluklari.Sayi[i];
    CizimAlani2.Ust := CizimAlani.Ust + 1;
    CizimAlani2.Sag := Sol - 1;
    CizimAlani2.Alt := CizimAlani.Ust + 1 + 22;
    EgimliDoldur3(Self, CizimAlani2, $EAECEE, $ABB2B9);

    // başlık
    AlanaYaziYaz(Self, CizimAlani2, 4, 3, FKolonAdlari.Yazi[i], RENK_LACIVERT);

    Inc(Sol);    // 1 px çizgi kalınlığı
  end;

  // yatay kılavuz çizgileri
  Ust := CizimAlani.Ust + 1 + 22;
  Ust := Ust + 20;
  while Ust < CizimAlani.Alt do
  begin

    Cizgi(Self, ctDuz, CizimAlani.Sol + 1, Ust, CizimAlani.Sag - 1, Ust, $F0F0F0);
    Ust := Ust + 1 + 20;
  end;

  // değer listesi nesnesinde görüntülenecek eleman sayısı
  GorunenElemanSayisi := ((FCizimAlani.Alt - FCizimAlani.Ust) - 24) div 21;

  // değer listesi kutusunda görüntülenecek eleman sayısının belirlenmesi
  if(FDegerler.ElemanSayisi > GorunenElemanSayisi) then
    ElemanSayisi := GorunenElemanSayisi + GorunenIlkSiraNo
  else ElemanSayisi := FDegerler.ElemanSayisi + GorunenIlkSiraNo;

  Ust := CizimAlani.Ust + 1 + 22;
  Ust := Ust + 20;
  SatirNo := 0;

  // değer listesi değerlerini yerleştir
  for SatirNo := GorunenIlkSiraNo to ElemanSayisi - 1 do
  begin

    // değeri belirtilen karakter ile bölümle
    Bolumle(FDegerler.Yazi[SatirNo], '|', FDegerDizisi);
    RY := FDegerler.RenkYaziAl(SatirNo);

    Sol := CizimAlani.Sol + 1;
    if(FDegerDizisi.ElemanSayisi > 0) then
    begin

      if(FDegerDizisi.ElemanSayisi > 1) then
        DegerSayisi := 2
      else DegerSayisi := 1;

      for j := 0 to DegerSayisi - 1 do
      begin

        s := FDegerDizisi.Yazi[j];
        CizimAlani2.Sol := Sol + 1;
        CizimAlani2.Ust := Ust - 20 + 1;
        CizimAlani2.Sag := Sol + FKolonUzunluklari.Sayi[j] - 1;
        CizimAlani2.Alt := Ust - 1;

        // satır verisini boyama ve yazma işlemi
        if(SatirNo = SeciliSiraNo) then
        begin

          DikdortgenDoldur(Self, CizimAlani2.Sol - 1, CizimAlani2.Ust - 1,
            CizimAlani2.Sag, CizimAlani2.Alt, $3EC5FF, $3EC5FF);
        end
        else
        begin

          DikdortgenDoldur(Self, CizimAlani2.Sol - 1, CizimAlani2.Ust - 1,
            CizimAlani2.Sag, CizimAlani2.Alt, RENK_BEYAZ, RENK_BEYAZ);
        end;

        AlanaYaziYaz(Self, CizimAlani2, 2, 2, s, RY.Renk);

        Sol := Sol + 1 + FKolonUzunluklari.Sayi[j];
      end;
    end;

    Ust := Ust + 1 + 20;
  end;
end;

{==============================================================================
  değer listesi nesne olaylarını işler
 ==============================================================================}
procedure TDegerListesi.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Pencere: TPencere;
  DegerListesi: TDegerListesi;
  i, j: TISayi4;
begin

  DegerListesi := TDegerListesi(AGonderici);

  // sol fare tuş basımı
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // değer listesinin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := GGNesneler.EnUstPencereNesnesiniAl(DegerListesi);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GGNesneler.AktifPencere) then
      Pencere.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere.FAktifNesne := DegerListesi;
    DegerListesi.Odaklanildi := True;

    // sol tuşa basım işlemi nesnenin olay alanında mı gerçekleşti ?
    if(DegerListesi.FareNesneOlayAlanindaMi(DegerListesi)) then
    begin

      // fare olaylarını yakala
      GGNesneler.OlayYakalamayaBasla(DegerListesi);

      // seçilen sırayı yeniden belirle
      j := (AOlay.Deger2 - 24) div 21;

      // bu değere kaydırılan değeri de ekle
      DegerListesi.SeciliSiraNo := (j + DegerListesi.GorunenIlkSiraNo);

      // değer listesi nesnesini yeniden çiz
      DegerListesi.Ciz;

      // uygulamaya veya efendi nesneye mesaj gönder
      if not(DegerListesi.OlayYonlAdr = nil) then
        DegerListesi.OlayYonlAdr(DegerListesi, AOlay)
      else GGorevler.OlayEkle(DegerListesi.GrvKimlik, AOlay);
    end;
  end

  // sol fare tuş bırakım işlemi
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    GGNesneler.OlayYakalamayiBirak(DegerListesi);

    // fare bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(DegerListesi.FareNesneOlayAlanindaMi(DegerListesi)) then
    begin

      // yakalama & bırakma işlemi bu nesnede olduğu için
      // nesneye FO_TIKLAMA mesajı gönder
      AOlay.Olay := FO_TIKLAMA;
      if not(DegerListesi.OlayYonlAdr = nil) then
        DegerListesi.OlayYonlAdr(DegerListesi, AOlay)
      else GGorevler.OlayEkle(DegerListesi.GrvKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    if not(DegerListesi.OlayYonlAdr = nil) then
      DegerListesi.OlayYonlAdr(DegerListesi, AOlay)
    else GGorevler.OlayEkle(DegerListesi.GrvKimlik, AOlay);
  end

  // fare hareket işlemi
  else if(AOlay.Olay = FO_HAREKET) then
  begin

    // eğer nesne yakalanmış ise
    if(GGNesneler.YakalananGorselNesne <> nil) then
    begin

      // fare değer listesi nesnesinin yukarısında ise
      if(AOlay.Deger2 < 0) then
      begin

        j := DegerListesi.GorunenIlkSiraNo;
        Dec(j);
        if(j >= 0) then
        begin

          DegerListesi.GorunenIlkSiraNo := j;
          DegerListesi.SeciliSiraNo := j;
        end;
      end

      // fare değer listesi nesnesinin aşağısında ise
      else if(AOlay.Deger2 > DegerListesi.FAtananAlan.Yukseklik) then
      begin

        // azami kaydırma değeri
        i := DegerListesi.FKolonAdlari.ElemanSayisi - DegerListesi.GorunenElemanSayisi;
        if(i < 0) then i := 0;

        j := DegerListesi.GorunenIlkSiraNo;
        Inc(j);
        if(j < i) then
        begin

          DegerListesi.GorunenIlkSiraNo := j;
          i := (AOlay.Deger2 - 24) div 21;
          DegerListesi.SeciliSiraNo := i + DegerListesi.GorunenIlkSiraNo;
        end
      end

      // fare değer listesi kutusunun içerisinde ise
      else
      begin

        i := (AOlay.Deger2 - 24) div 21;
        DegerListesi.SeciliSiraNo := i + DegerListesi.GorunenIlkSiraNo;
      end;

      // değer listesi nesnesini yeniden çiz
      DegerListesi.Ciz;

      // uygulamaya veya efendi nesneye mesaj gönder
      if not(DegerListesi.OlayYonlAdr = nil) then
        DegerListesi.OlayYonlAdr(DegerListesi, AOlay)
      else GGorevler.OlayEkle(DegerListesi.GrvKimlik, AOlay);
    end

    // nesne yakalanmamış ise uygulamaya sadece mesaj gönder
    else
    begin

      // uygulamaya veya efendi nesneye mesaj gönder
      if not(DegerListesi.OlayYonlAdr = nil) then
        DegerListesi.OlayYonlAdr(DegerListesi, AOlay)
      else GGorevler.OlayEkle(DegerListesi.GrvKimlik, AOlay);
    end;
  end

  else if(AOlay.Olay = FO_KAYDIRMA) then
  begin

    // listeyi yukarı kaydırma işlemi. ilk elemana doğru
    if(AOlay.Deger1 < 0) then
    begin

      j := DegerListesi.GorunenIlkSiraNo;
      Dec(j);
      if(j >= 0) then DegerListesi.GorunenIlkSiraNo := j;
    end

    // listeyi aşağıya kaydırma işlemi. son elemana doğru
    else if(AOlay.Deger1 > 0) then
    begin

      // azami kaydırma değeri
      i := DegerListesi.FDegerler.ElemanSayisi - DegerListesi.GorunenElemanSayisi;
      if(i < 0) then i := 0;

      j := DegerListesi.GorunenIlkSiraNo;
      Inc(j);
      if(j < i) then DegerListesi.GorunenIlkSiraNo := j;
    end;

    DegerListesi.Ciz;
  end;

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := DegerListesi.FareImlec;
end;

{==============================================================================
  seçili elemanın yazı (text) değerini geri döndürür
 ==============================================================================}
function TDegerListesi.SeciliSatirDegeriniAl: string;
begin

  if(SeciliSiraNo = -1) or (SeciliSiraNo > FDegerler.ElemanSayisi) then Exit('');

  Result := FDegerler.Yazi[SeciliSiraNo];
end;

{==============================================================================
  | ayıracıyla gelen karakter katarını bölümler
 ==============================================================================}
procedure TDegerListesi.Bolumle(ABicimlenmisDeger: string; AAyiracDeger: Char;
  DegerDizisi: TYaziListesi);
var
  Uzunluk, i: TISayi4;
  s: string;
begin

  DegerDizisi.Temizle;

  Uzunluk := Length(ABicimlenmisDeger);
  if(Uzunluk > 0) then
  begin

    i := 1;
    s := '';
    while i <= Uzunluk do
    begin

      if(ABicimlenmisDeger[i] = AAyiracDeger) or (i = Uzunluk) then
      begin

        if(i = Uzunluk) then s := s + ABicimlenmisDeger[i];

        if(Length(s) > 0) then
        begin

          DegerDizisi.Ekle(s);
          s := '';
        end;
      end else s := s + ABicimlenmisDeger[i];

      Inc(i);
    end;
  end;
end;

{==============================================================================
  değer listesine kolon ekler
 ==============================================================================}
function TDegerListesi.BaslikEkle(AKolon1, AKolon2: string; AKolon1U: TISayi4): Boolean;
begin

  FKolonAdlari.Ekle(AKolon1);
  FKolonUzunluklari.Ekle(AKolon1U);

  FKolonAdlari.Ekle(AKolon2);
  FKolonUzunluklari.Ekle(FAtananAlan.Genislik - AKolon1U - 3);

  Result := True;
end;

function TDegerListesi.DegerEkle(ADeger: string; AYaziRengi: TRenk): Boolean;
begin

  FDegerler.Ekle(ADeger, AYaziRengi);

  if(Gorunum) then Ciz;

  Result := True;
end;

procedure TDegerListesi.DegerIceriginiTemizle;
begin

  FDegerler.Temizle;
  GorunenIlkSiraNo := 0;
  SeciliSiraNo := -1;

  Ciz;
end;

end.
