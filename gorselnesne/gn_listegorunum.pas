{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_listegorunum.pas
  Dosya İşlevi: liste görünüm (TListView) yönetim işlevlerini içerir

  Güncelleme Tarihi: 17/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_listegorunum;

interface

uses gorselnesne, paylasim, n_yazilistesi, n_sayilistesi, gn_panel;

type
  PListeGorunum = ^TListeGorunum;
  TListeGorunum = class(TPanel)
  private
    FSeciliSiraNo: TISayi4;               // seçili sıra değeri
    FGorunenIlkSiraNo: TISayi4;           // liste görünümde en üstte görüntülenen elemanın sıra değeri
    FGorunenElemanSayisi: TISayi4;        // kullanıcıya nesne içerisinde gösterilen eleman sayısı
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
    procedure Bolumle5(ABicimlenmisDeger: string; AAyiracDeger: Char;
      ADegerDizisi: TYaziListesi);
  end;

function ListeGorunumCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function ListeGorunumGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;

implementation

uses gn_islevler, gn_pencere, gorev, src_ps2;

{==============================================================================
  liste görünüm kesme çağrılarını yönetir
 ==============================================================================}
function ListeGorunumCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  Pencere: TPencere;
  ListeGorunum: TListeGorunum;
  Hiza: THiza;
  p: PKarakterKatari;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    // nesne oluştur
    ISLEV_OLUSTUR:
    begin

      GN := GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := ListeGorunumGNOlustur(GN, PISayi4(ADegiskenler + 04)^,
        PISayi4(ADegiskenler + 08)^, PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^);
    end;

    // liste görünüm nesnesini hizala
    ISLEV_HIZALA:
    begin

      ListeGorunum := TListeGorunum(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      ListeGorunum.FHiza := Hiza;

      Pencere := TPencere(ListeGorunum.FAtaNesne);
      Pencere.Guncelle;
    end;

    // eleman ekle
    $010F:
    begin

      ListeGorunum := TListeGorunum(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeGorunum));
      if(ListeGorunum <> nil) then ListeGorunum.FDegerler.Ekle(
        PKarakterKatari(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr)^,
        PRenk(ADegiskenler + 08)^);
      Result := 1;
    end;

    // seçilen sıra değerini al
    $020E:
    begin

      ListeGorunum := TListeGorunum(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeGorunum));
      if(ListeGorunum <> nil) then Result := ListeGorunum.FSeciliSiraNo;
    end;

    // seçilen sıra değerini yaz
    $020F:
    begin

      ListeGorunum := TListeGorunum(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeGorunum));
      if(ListeGorunum <> nil) then ListeGorunum.FSeciliSiraNo := PISayi4(ADegiskenler + 04)^;
    end;

    // liste içeriğini temizle
    $030F:
    begin

      ListeGorunum := TListeGorunum(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeGorunum));
      if(ListeGorunum <> nil) then
      begin

        // içeriği temizle, değerleri ön değerlere çek
        ListeGorunum.FDegerler.Temizle;
        ListeGorunum.FGorunenIlkSiraNo := 0;
        ListeGorunum.FSeciliSiraNo := -1;
        ListeGorunum.Ciz;
      end;
    end;

    // seçilen yazı (text) değerini geri döndür
    $040E:
    begin

      ListeGorunum := TListeGorunum(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeGorunum));
      if(ListeGorunum <> nil) then Result := ListeGorunum.FSeciliSiraNo;
      p := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr);
      p^ := ListeGorunum.SeciliSatirDegeriniAl;
    end;

    // liste görüntüleyicisinin başlıklarını sil
    $050F:
    begin

      ListeGorunum := TListeGorunum(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeGorunum));
      if(ListeGorunum <> nil) then
      begin

        ListeGorunum.FKolonUzunluklari.Temizle;
        ListeGorunum.FKolonAdlari.Temizle;
        Result := 1;
      end;
    end;

    // liste görüntüleyicisine kolon ekle
    $060F:
    begin

      ListeGorunum := TListeGorunum(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeGorunum));
      if(ListeGorunum <> nil) then
      begin

        ListeGorunum.FKolonAdlari.Ekle(
          PKarakterKatari(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr)^);
        ListeGorunum.FKolonUzunluklari.Ekle(PISayi4(ADegiskenler + 08)^);
        Result := 1;
      end;
    end;
  end;
end;

{==============================================================================
  uygulama için liste görünüm nesnesi oluşturur - api
 ==============================================================================}
function ListeGorunumGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
var
  ListeGorunum: TListeGorunum;
begin

  ListeGorunum := TListeGorunum.Create;

  if(ListeGorunum = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    ListeGorunum.Ozellestir(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik);

    Result := ListeGorunum.Kimlik;
  end;
end;

{==============================================================================
  liste görünüm nesnesi oluşturur
 ==============================================================================}
constructor TListeGorunum.Create;
begin

  inherited Create;

  NesneTipi := gntListeGorunum;

  GGNesneler.GorselNesne[FSiraNo] := Self;

  FKolonAdlari := TYaziListesi.Create;
  FKolonUzunluklari := TSayiListesi.Create;
  FDegerler := TYaziListesi.Create;
  FDegerDizisi := TYaziListesi.Create;
end;

{==============================================================================
  liste görünüm nesnesini yok eder
 ==============================================================================}
destructor TListeGorunum.Destroy;
begin

  if(FDegerDizisi <> nil) then FDegerDizisi.Destroy;
  if(FDegerler <> nil) then FDegerler.Destroy;
  if(FKolonUzunluklari <> nil) then FKolonUzunluklari.Destroy;
  if(FKolonAdlari <> nil) then FKolonAdlari.Destroy;

  GGNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  liste görünüm nesnesini özelleştirir
 ==============================================================================}
function TListeGorunum.Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4): TISayi4;
begin

  Yapilandir2(AKullanimTipi, Self, AAtaNesne, ASol, AUst, AGenislik, AYukseklik,
    3, $828790, RENK_BEYAZ, 0, '');

  OlayCagriAdr := @OlaylariIsle;

  Odaklanilabilir := True;
  Odaklanildi := False;

  // nesnenin kullanacağı diğer değerler
  FGorunenIlkSiraNo := 0;
  FSeciliSiraNo := -1;

  // liste görünüm nesnesinde görüntülenecek eleman sayısı
  FGorunenElemanSayisi := (AYukseklik - 24) div 21;

  // nesneyi görüntüle
  Goster;

  // geri dönüş değeri
  Result := HATA_YOK;
end;

{==============================================================================
  liste görünüm nesnesini görüntüler
 ==============================================================================}
procedure TListeGorunum.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  liste görünüm nesnesini gizler
 ==============================================================================}
procedure TListeGorunum.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  liste görünüm nesnesini hizalandırır
 ==============================================================================}
procedure TListeGorunum.Hizala;
begin

  inherited Hizala;
end;

{==============================================================================
  liste görünüm nesnesini çizer
 ==============================================================================}
procedure TListeGorunum.Ciz;
var
  Pencere: TPencere;
  KolonAdlari: TYaziListesi;
  CizimAlani, CizimAlani2: TAlan;
  ElemanSayisi, SatirNo, i, j,
  Sol, Ust: TISayi4;
  RY: TRenkYazi;
  s: String;
begin

  inherited Ciz;

  // liste görünüm kutusunun üst nesneye bağlı olarak koordinatlarını al
  CizimAlani := FCizimAlani;

  // ata nesne bir pencere mi?
  Pencere := GGNesneler.EnUstPencereNesnesiniAl(Self);
  if(Pencere = nil) then Exit;

  KolonAdlari := FKolonAdlari;

  // tanımlanmış hiçbir kolon yok ise, çık
  if(KolonAdlari.ElemanSayisi = 0) then Exit;

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
    AlanaYaziYaz(Self, CizimAlani2, 4, 3, KolonAdlari.Yazi[i], RENK_LACIVERT);

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

  // liste görünüm nesnesinde görüntülenecek eleman sayısı
  FGorunenElemanSayisi := ((FCizimAlani.Alt - FCizimAlani.Ust) - 24) div 21;

  // liste görünüm kutusunda görüntülenecek eleman sayısının belirlenmesi
  if(FDegerler.ElemanSayisi > FGorunenElemanSayisi) then
    ElemanSayisi := FGorunenElemanSayisi + FGorunenIlkSiraNo
  else ElemanSayisi := FDegerler.ElemanSayisi + FGorunenIlkSiraNo;

  Ust := CizimAlani.Ust + 1 + 22;
  Ust := Ust + 20;
  SatirNo := 0;

  if(FDegerler.ElemanSayisi = 0) then Exit;

  // liste görünüm değerlerini yerleştir
  for SatirNo := FGorunenIlkSiraNo to ElemanSayisi - 1 do
  begin

    // değeri belirtilen karakter ile bölümle
    Bolumle5(FDegerler.Yazi[SatirNo], '|', FDegerDizisi);
    RY := FDegerler.RenkYaziAl(SatirNo);

    Sol := CizimAlani.Sol + 1;
    if(FDegerDizisi.ElemanSayisi > 0) then
    begin

      for j := 0 to FDegerDizisi.ElemanSayisi - 1 do
      begin

        s := FDegerDizisi.Yazi[j];
        CizimAlani2.Sol := Sol + 1;
        CizimAlani2.Ust := Ust - 20 + 1;
        CizimAlani2.Sag := Sol + FKolonUzunluklari.Sayi[j] - 1;
        CizimAlani2.Alt := Ust - 1;

        // satır verisini boyama ve yazma işlemi
        if(SatirNo = FSeciliSiraNo) then
        begin

          if(Odaklanildi) then
            DikdortgenDoldur(Self, CizimAlani2.Sol - 1, CizimAlani2.Ust - 1,
              CizimAlani2.Sag, CizimAlani2.Alt, $3EC5FF, $3EC5FF)
          else DikdortgenDoldur(Self, CizimAlani2.Sol - 1, CizimAlani2.Ust - 1,
            CizimAlani2.Sag, CizimAlani2.Alt, RENK_GRI, RENK_GRI);
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
  liste görünüm nesne olaylarını işler
 ==============================================================================}
procedure TListeGorunum.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Pencere: TPencere;
  ListeGorunum: TListeGorunum;
  i, j: TISayi4;
begin

  ListeGorunum := TListeGorunum(AGonderici);

  // sol / sağ fare tuş basımı
  if(AOlay.Olay = FO_SOLTUS_BASILDI) or (AOlay.Olay = FO_SAGTUS_BASILDI) then
  begin

    // liste görünümün sahibi olan pencere en üstte mi ? kontrol et
    Pencere := GGNesneler.EnUstPencereNesnesiniAl(ListeGorunum);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GGNesneler.AktifPencere) then
      Pencere.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere.FAktifNesne := ListeGorunum;
    ListeGorunum.Odaklanildi := True;

    // sol tuşa basım işlemi nesnenin olay alanında mı gerçekleşti ?
    if(ListeGorunum.FareNesneOlayAlanindaMi(ListeGorunum)) then
    begin

      // fare olaylarını yakala
      if(AOlay.Olay = FO_SOLTUS_BASILDI) then GGNesneler.OlayYakalamayaBasla(ListeGorunum);

      // seçilen sırayı yeniden belirle
      j := (AOlay.Deger2 - 24) div 21;

      // bu değere kaydırılan değeri de ekle
      FSeciliSiraNo := (j + FGorunenIlkSiraNo);

      // liste görünüm nesnesini yeniden çiz
      Ciz;

      if(AOlay.Olay = FO_SOLTUS_BASILDI) then
      begin

        // uygulamaya veya efendi nesneye mesaj gönder
        if not(ListeGorunum.OlayYonlAdr = nil) then
          ListeGorunum.OlayYonlAdr(ListeGorunum, AOlay)
        else GGorevler.OlayEkle(ListeGorunum.GrvKimlik, AOlay);
      end;
    end;
  end

  // sol fare tuş bırakım işlemi
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    GGNesneler.OlayYakalamayiBirak(ListeGorunum);

    // fare bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(ListeGorunum.FareNesneOlayAlanindaMi(ListeGorunum)) then
    begin

      // yakalama & bırakma işlemi bu nesnede olduğu için
      // nesneye FO_TIKLAMA mesajı gönder
      AOlay.Olay := FO_TIKLAMA;
      if not(ListeGorunum.OlayYonlAdr = nil) then
        ListeGorunum.OlayYonlAdr(ListeGorunum, AOlay)
      else GGorevler.OlayEkle(ListeGorunum.GrvKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    if not(ListeGorunum.OlayYonlAdr = nil) then
      ListeGorunum.OlayYonlAdr(ListeGorunum, AOlay)
    else GGorevler.OlayEkle(ListeGorunum.GrvKimlik, AOlay);
  end

  // fare hareket işlemi
  else if(AOlay.Olay = FO_HAREKET) then
  begin

    // eğer nesne yakalanmış ise
    if(GGNesneler.YakalananGorselNesne <> nil) then
    begin

      // fare liste görünüm nesnesinin yukarısında ise
      if(AOlay.Deger2 < 0) then
      begin

        j := ListeGorunum.FGorunenIlkSiraNo;
        Dec(j);
        if(j >= 0) then
        begin

          ListeGorunum.FGorunenIlkSiraNo := j;
          ListeGorunum.FSeciliSiraNo := j;
        end;
      end

      // fare liste görünüm nesnesinin aşağısında ise
      else if(AOlay.Deger2 > ListeGorunum.FAtananAlan.Yukseklik) then
      begin

        // azami kaydırma değeri
        i := ListeGorunum.FKolonAdlari.ElemanSayisi - ListeGorunum.FGorunenElemanSayisi;
        if(i < 0) then i := 0;

        j := ListeGorunum.FGorunenIlkSiraNo;
        Inc(j);
        if(j < i) then
        begin

          ListeGorunum.FGorunenIlkSiraNo := j;
          i := (AOlay.Deger2 - 24) div 21;
          ListeGorunum.FSeciliSiraNo := i + ListeGorunum.FGorunenIlkSiraNo;
        end
      end

      // fare liste görünüm kutusunun içerisinde ise
      else
      begin

        i := (AOlay.Deger2 - 24) div 21;
        ListeGorunum.FSeciliSiraNo := i + ListeGorunum.FGorunenIlkSiraNo;
      end;

      // liste görünüm nesnesini yeniden çiz
      ListeGorunum.Ciz;

      // uygulamaya veya efendi nesneye mesaj gönder
      if not(ListeGorunum.OlayYonlAdr = nil) then
        ListeGorunum.OlayYonlAdr(ListeGorunum, AOlay)
      else GGorevler.OlayEkle(ListeGorunum.GrvKimlik, AOlay);
    end

    // nesne yakalanmamış ise uygulamaya sadece mesaj gönder
    else
    begin

      // uygulamaya veya efendi nesneye mesaj gönder
      if not(ListeGorunum.OlayYonlAdr = nil) then
        ListeGorunum.OlayYonlAdr(ListeGorunum, AOlay)
      else GGorevler.OlayEkle(ListeGorunum.GrvKimlik, AOlay);
    end;
  end

  else if(AOlay.Olay = FO_KAYDIRMA) then
  begin

    // SISTEM_MESAJ(RENK_KIRMIZI, 'Kaydırma Değeri: %d', [AOlay.Deger1]);

    // listeyi yukarı kaydırma işlemi. ilk elemana doğru
    if(AOlay.Deger1 < 0) then
    begin

      j := ListeGorunum.FGorunenIlkSiraNo;
      Dec(j);
      if(j >= 0) then ListeGorunum.FGorunenIlkSiraNo := j;
    end

    // listeyi aşağıya kaydırma işlemi. son elemana doğru
    else if(AOlay.Deger1 > 0) then
    begin

      // azami kaydırma değeri
      i := ListeGorunum.FDegerler.ElemanSayisi - ListeGorunum.FGorunenElemanSayisi;
      if(i < 0) then i := 0;

      j := ListeGorunum.FGorunenIlkSiraNo;
      Inc(j);
      if(j < i) then ListeGorunum.FGorunenIlkSiraNo := j;
    end;

    ListeGorunum.Ciz;
  end

  // klavye tuş basımı
  else if(AOlay.Olay = CO_TUSBASILDI) then
  begin

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(ListeGorunum.OlayYonlAdr = nil) then
      ListeGorunum.OlayYonlAdr(ListeGorunum, AOlay)
    else GGorevler.OlayEkle(ListeGorunum.GrvKimlik, AOlay);
  end;

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := ListeGorunum.FareImlec;
end;

{==============================================================================
  seçili elemanın yazı (text) değerini geri döndürür
 ==============================================================================}
function TListeGorunum.SeciliSatirDegeriniAl: string;
begin

  if(FSeciliSiraNo = -1) or (FSeciliSiraNo > FDegerler.ElemanSayisi) then Exit('');

  Result := FDegerler.Yazi[FSeciliSiraNo];
end;

{==============================================================================
  | ayıracıyla gelen karakter katarını bölümler
 ==============================================================================}
procedure TListeGorunum.Bolumle5(ABicimlenmisDeger: string; AAyiracDeger: Char;
  ADegerDizisi: TYaziListesi);
var
  Uzunluk, i: TISayi4;
  s: string;
begin

  ADegerDizisi.Temizle;

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

          ADegerDizisi.Ekle(s);
          s := '';
        end;
      end else s := s + ABicimlenmisDeger[i];

      Inc(i);
    end;
  end;
end;

end.
