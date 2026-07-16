{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_listegorunum.pas
  Dosya İşlevi: liste görünüm (TListView) yönetim işlevlerini içerir

  Güncelleme Tarihi: 16/07/2026

 ==============================================================================}
{$mode objfpc}
unit gn_listegorunum;

interface

uses gorselnesne, paylasim, n_yazilistesi, n_sayilistesi, gn_panel;

type
  PListeGorunum = ^TListeGorunum;
  TListeGorunum = object(TPanel)
  private
    FSeciliSiraNo: TISayi4;               // seçili sıra değeri
    FGorunenIlkSiraNo: TISayi4;           // liste görünümde en üstte görüntülenen elemanın sıra değeri
    FGorunenElemanSayisi: TISayi4;        // kullanıcıya nesne içerisinde gösterilen eleman sayısı
    FKolonAdlari: PYaziListesi;           // kolon ad listesi
    FKolonUzunluklari: PSayiListesi;      // kolon uzunlukları
    FDegerler,                            // kolon içerik değerleri
    FDegerDizisi: PYaziListesi;           // FDegerler içeriğini bölümlemek için kullanılacak
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4): PListeGorunum;
    procedure YokEt(AKimlik: TKimlik);
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    function SeciliSatirDegeriniAl: string;
    procedure Bolumle5(ABicimlenmisDeger: shortstring; AAyiracDeger: Char;
      ADegerDizisi: PYaziListesi);
  end;

function ListeGorunumCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;

implementation

uses genel, gn_islevler, gn_pencere, temelgorselnesne, gorev;

{==============================================================================
  liste görünüm kesme çağrılarını yönetir
 ==============================================================================}
function ListeGorunumCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne;
  Pencere: PPencere;
  ListeGorunum: PListeGorunum;
  Hiza: THiza;
  p: PKarakterKatari;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    // nesne oluştur
    ISLEV_OLUSTUR:
    begin

      GN := GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^);
    end;

    // liste görünüm nesnesini hizala
    ISLEV_HIZALA:
    begin

      ListeGorunum := PListeGorunum(GorselNesneler0.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      ListeGorunum^.FHiza := Hiza;

      Pencere := PPencere(ListeGorunum^.FAtaNesne);
      Pencere^.Guncelle;
    end;

    // eleman ekle
    $010F:
    begin

      ListeGorunum := PListeGorunum(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeGorunum));
      if(ListeGorunum <> nil) then ListeGorunum^.FDegerler^.Ekle(
        PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi)^,
        PRenk(ADegiskenler + 08)^);
      Result := 1;
    end;

    // seçilen sıra değerini al
    $020E:
    begin

      ListeGorunum := PListeGorunum(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeGorunum));
      if(ListeGorunum <> nil) then Result := ListeGorunum^.FSeciliSiraNo;
    end;

    // seçilen sıra değerini yaz
    $020F:
    begin

      ListeGorunum := PListeGorunum(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeGorunum));
      if(ListeGorunum <> nil) then ListeGorunum^.FSeciliSiraNo := PISayi4(ADegiskenler + 04)^;
    end;

    // liste içeriğini temizle
    $030F:
    begin

      ListeGorunum := PListeGorunum(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeGorunum));
      if(ListeGorunum <> nil) then
      begin

        // içeriği temizle, değerleri ön değerlere çek
        ListeGorunum^.FDegerler^.Temizle;
        ListeGorunum^.FGorunenIlkSiraNo := 0;
        ListeGorunum^.FSeciliSiraNo := -1;
        ListeGorunum^.Ciz;
      end;
    end;

    // seçilen yazı (text) değerini geri döndür
    $040E:
    begin

      ListeGorunum := PListeGorunum(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeGorunum));
      if(ListeGorunum <> nil) then Result := ListeGorunum^.FSeciliSiraNo;
      p := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
      p^ := ListeGorunum^.SeciliSatirDegeriniAl;
    end;

    // liste görüntüleyicisinin başlıklarını sil
    $050F:
    begin

      ListeGorunum := PListeGorunum(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeGorunum));
      if(ListeGorunum <> nil) then
      begin

        ListeGorunum^.FKolonUzunluklari^.Temizle;
        ListeGorunum^.FKolonAdlari^.Temizle;
        Result := 1;
      end;
    end;

    // liste görüntüleyicisine kolon ekle
    $060F:
    begin

      ListeGorunum := PListeGorunum(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeGorunum));
      if(ListeGorunum <> nil) then
      begin

        ListeGorunum^.FKolonAdlari^.Ekle(
          PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi)^);
        ListeGorunum^.FKolonUzunluklari^.Ekle(PISayi4(ADegiskenler + 08)^);
        Result := 1;
      end;
    end;
  end;
end;

{==============================================================================
  liste görünüm nesnesini oluşturur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
var
  ListeGorunum: PListeGorunum;
begin

  ListeGorunum := ListeGorunum^.Olustur(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik);
  if(ListeGorunum = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := ListeGorunum^.Kimlik;
end;

{==============================================================================
  liste görünüm nesnesini oluşturur
 ==============================================================================}
function TListeGorunum.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4): PListeGorunum;
var
  ListeGorunum: PListeGorunum;
  KolonAdlari, Degerler, DegerDizisi: PYaziListesi;
  KolonUzunluklari: PSayiListesi;
begin

  ListeGorunum := PListeGorunum(inherited Olustur(AKullanimTipi, AAtaNesne, ASol, AUst,
    AGenislik, AYukseklik, 3, $828790, RENK_BEYAZ, 0, ''));

  ListeGorunum^.NesneTipi := gntListeGorunum;

  ListeGorunum^.Baslik := '';

  ListeGorunum^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  ListeGorunum^.Odaklanilabilir := True;
  ListeGorunum^.Odaklanildi := False;

  ListeGorunum^.OlayCagriAdresi := @OlaylariIsle;

  ListeGorunum^.FKolonAdlari := nil;
  KolonAdlari := YaziListesi0.Olustur;
  if(KolonAdlari <> nil) then ListeGorunum^.FKolonAdlari := KolonAdlari;

  ListeGorunum^.FKolonUzunluklari := nil;
  KolonUzunluklari := SayiListesi0.Olustur;
  if(KolonUzunluklari <> nil) then ListeGorunum^.FKolonUzunluklari := KolonUzunluklari;

  ListeGorunum^.FDegerler := nil;
  Degerler := YaziListesi0.Olustur;
  if(Degerler <> nil) then ListeGorunum^.FDegerler := Degerler;

  ListeGorunum^.FDegerDizisi := nil;
  DegerDizisi := YaziListesi0.Olustur;
  if(DegerDizisi <> nil) then ListeGorunum^.FDegerDizisi := DegerDizisi;

  // nesnenin kullanacağı diğer değerler
  ListeGorunum^.FGorunenIlkSiraNo := 0;
  ListeGorunum^.FSeciliSiraNo := -1;

  // liste görünüm nesnesinde görüntülenecek eleman sayısı
  ListeGorunum^.FGorunenElemanSayisi := (AYukseklik - 24) div 21;

  // nesneyi görüntüle
  ListeGorunum^.Goster;

  // nesne adresini geri döndür
  Result := ListeGorunum;
end;

{==============================================================================
  liste görünüm nesnesini yok eder
 ==============================================================================}
procedure TListeGorunum.YokEt(AKimlik: TKimlik);
var
  ListeGorunum: PListeGorunum;
begin

  ListeGorunum := PListeGorunum(GorselNesneler0.NesneAl(AKimlik));
  if(ListeGorunum = nil) then Exit;

  if(ListeGorunum^.FDegerler <> nil) then YaziListesi0.YokEt(ListeGorunum^.FDegerler^.Kimlik);
  if(ListeGorunum^.FDegerDizisi <> nil) then YaziListesi0.YokEt(ListeGorunum^.FDegerDizisi^.Kimlik);
  if(ListeGorunum^.FKolonAdlari <> nil) then YaziListesi0.YokEt(ListeGorunum^.FKolonAdlari^.Kimlik);
  if(ListeGorunum^.FKolonUzunluklari <> nil) then SayiListesi0.YokEt(ListeGorunum^.FKolonUzunluklari^.Kimlik);

  inherited YokEt(AKimlik);
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
var
  ListeGorunum: PListeGorunum;
begin

  ListeGorunum := PListeGorunum(GorselNesneler0.NesneAl(Kimlik));
  if(ListeGorunum = nil) then Exit;

  inherited Hizala;
end;

{==============================================================================
  liste görünüm nesnesini çizer
 ==============================================================================}
procedure TListeGorunum.Ciz;
var
  Pencere: PPencere;
  LG: PListeGorunum;
  KolonAdlari: PYaziListesi;
  KolonUzunluklari: PSayiListesi;
  CizimAlani, CizimAlani2: TAlan;
  ElemanSayisi, SatirNo, i, j,
  Sol, Ust: TISayi4;
  RY: TRenkYazi;
  s: String;
begin

  LG := PListeGorunum(GorselNesneler0.NesneAl(Kimlik));
  if(LG = nil) then Exit;

  inherited Ciz;

  // liste kutusunun üst nesneye bağlı olarak koordinatlarını al
  CizimAlani := LG^.FCizimAlani;

  // ata nesne bir pencere mi?
  Pencere := EnUstPencereNesnesiniAl(LG);
  if(Pencere = nil) then Exit;

  KolonUzunluklari := LG^.FKolonUzunluklari;
  KolonAdlari := LG^.FKolonAdlari;

  // tanımlanmış hiçbir kolon yok ise, çık
  if(KolonAdlari^.ElemanSayisi = 0) then Exit;

  // kolon başlık ve değerleri
  Sol := CizimAlani.Sol + 1;
  for i := 0 to KolonUzunluklari^.ElemanSayisi - 1 do
  begin

    Sol := Sol + KolonUzunluklari^.Sayi[i];

    // dikey kılavuz çizgisi
    LG^.Cizgi(LG, ctDuz, Sol, CizimAlani.Ust + 1, Sol, CizimAlani.Alt - 1, $F0F0F0);

    // başlık dolgusu
    CizimAlani2.Sol := Sol - KolonUzunluklari^.Sayi[i];
    CizimAlani2.Ust := CizimAlani.Ust + 1;
    CizimAlani2.Sag := Sol - 1;
    CizimAlani2.Alt := CizimAlani.Ust + 1 + 22;
    LG^.EgimliDoldur3(LG, CizimAlani2, $EAECEE, $ABB2B9);

    // başlık
    LG^.AlanaYaziYaz(LG, CizimAlani2, 4, 3, KolonAdlari^.Yazi[i], RENK_LACIVERT);

    Inc(Sol);    // 1 px çizgi kalınlığı
  end;

  // yatay kılavuz çizgileri
  Ust := CizimAlani.Ust + 1 + 22;
  Ust := Ust + 20;
  while Ust < CizimAlani.Alt do
  begin

    LG^.Cizgi(LG, ctDuz, CizimAlani.Sol + 1, Ust, CizimAlani.Sag - 1, Ust, $F0F0F0);
    Ust := Ust + 1 + 20;
  end;

  // liste görünüm nesnesinde görüntülenecek eleman sayısı
  LG^.FGorunenElemanSayisi := ((LG^.FCizimAlani.Alt - LG^.FCizimAlani.Ust) - 24) div 21;

  // liste görünüm kutusunda görüntülenecek eleman sayısının belirlenmesi
  if(LG^.FDegerler^.ElemanSayisi > LG^.FGorunenElemanSayisi) then
    ElemanSayisi := LG^.FGorunenElemanSayisi + LG^.FGorunenIlkSiraNo
  else ElemanSayisi := LG^.FDegerler^.ElemanSayisi + LG^.FGorunenIlkSiraNo;

  Ust := CizimAlani.Ust + 1 + 22;
  Ust := Ust + 20;
  SatirNo := 0;
  KolonUzunluklari := LG^.FKolonUzunluklari;

  if(LG^.FDegerler^.ElemanSayisi = 0) then Exit;

  // liste görünüm değerlerini yerleştir
  for SatirNo := LG^.FGorunenIlkSiraNo to ElemanSayisi - 1 do
  begin

    // değeri belirtilen karakter ile bölümle
    Bolumle5(LG^.FDegerler^.Yazi[SatirNo], '|', LG^.FDegerDizisi);
    RY := FDegerler^.RenkYaziAl(SatirNo);

    Sol := CizimAlani.Sol + 1;
    if(LG^.FDegerDizisi^.ElemanSayisi > 0) then
    begin

      for j := 0 to LG^.FDegerDizisi^.ElemanSayisi - 1 do
      begin

        s := LG^.FDegerDizisi^.Yazi[j];
        CizimAlani2.Sol := Sol + 1;
        CizimAlani2.Ust := Ust - 20 + 1;
        CizimAlani2.Sag := Sol + KolonUzunluklari^.Sayi[j] - 1;
        CizimAlani2.Alt := Ust - 1;

        // satır verisini boyama ve yazma işlemi
        if(SatirNo = LG^.FSeciliSiraNo) then
        begin

          if(LG^.Odaklanildi) then
            LG^.DikdortgenDoldur(LG, CizimAlani2.Sol - 1, CizimAlani2.Ust - 1,
              CizimAlani2.Sag, CizimAlani2.Alt, $3EC5FF, $3EC5FF)
          else LG^.DikdortgenDoldur(LG, CizimAlani2.Sol - 1, CizimAlani2.Ust - 1,
            CizimAlani2.Sag, CizimAlani2.Alt, RENK_GRI, RENK_GRI);
        end
        else
        begin

          LG^.DikdortgenDoldur(LG, CizimAlani2.Sol - 1, CizimAlani2.Ust - 1,
            CizimAlani2.Sag, CizimAlani2.Alt, RENK_BEYAZ, RENK_BEYAZ);
        end;

        LG^.AlanaYaziYaz(LG, CizimAlani2, 2, 2, s, RY.Renk);

        Sol := Sol + 1 + KolonUzunluklari^.Sayi[j];
      end;
    end;

    Ust := Ust + 1 + 20;
  end;
end;

{==============================================================================
  liste görünüm nesne olaylarını işler
 ==============================================================================}
procedure TListeGorunum.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere;
  ListeGorunum: PListeGorunum;
  i, j: TISayi4;
begin

  ListeGorunum := PListeGorunum(AGonderici);

  // sol / sağ fare tuş basımı
  if(AOlay.Olay = FO_SOLTUS_BASILDI) or (AOlay.Olay = FO_SAGTUS_BASILDI) then
  begin

    // liste görünümün sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(ListeGorunum);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere^.FAktifNesne := ListeGorunum;
    ListeGorunum^.Odaklanildi := True;

    // sol tuşa basım işlemi nesnenin olay alanında mı gerçekleşti ?
    if(ListeGorunum^.FareNesneOlayAlanindaMi(ListeGorunum)) then
    begin

      // fare olaylarını yakala
      if(AOlay.Olay = FO_SOLTUS_BASILDI) then OlayYakalamayaBasla(ListeGorunum);

      // seçilen sırayı yeniden belirle
      j := (AOlay.Deger2 - 24) div 21;

      // bu değere kaydırılan değeri de ekle
      ListeGorunum^.FSeciliSiraNo := (j + ListeGorunum^.FGorunenIlkSiraNo);

      // liste görünüm nesnesini yeniden çiz
      ListeGorunum^.Ciz;

      if(AOlay.Olay = FO_SOLTUS_BASILDI) then
      begin

        // uygulamaya veya efendi nesneye mesaj gönder
        if not(ListeGorunum^.OlayYonlendirmeAdresi = nil) then
          ListeGorunum^.OlayYonlendirmeAdresi(ListeGorunum, AOlay)
        else Gorevler0.OlayEkle(ListeGorunum^.GorevKimlik, AOlay);
      end;
    end;
  end

  // sol fare tuş bırakım işlemi
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    OlayYakalamayiBirak(ListeGorunum);

    // fare bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(ListeGorunum^.FareNesneOlayAlanindaMi(ListeGorunum)) then
    begin

      // yakalama & bırakma işlemi bu nesnede olduğu için
      // nesneye FO_TIKLAMA mesajı gönder
      AOlay.Olay := FO_TIKLAMA;
      if not(ListeGorunum^.OlayYonlendirmeAdresi = nil) then
        ListeGorunum^.OlayYonlendirmeAdresi(ListeGorunum, AOlay)
      else Gorevler0.OlayEkle(ListeGorunum^.GorevKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    if not(ListeGorunum^.OlayYonlendirmeAdresi = nil) then
      ListeGorunum^.OlayYonlendirmeAdresi(ListeGorunum, AOlay)
    else Gorevler0.OlayEkle(ListeGorunum^.GorevKimlik, AOlay);
  end

  // fare hakeret işlemi
  else if(AOlay.Olay = FO_HAREKET) then
  begin

    // eğer nesne yakalanmış ise
    if(YakalananGorselNesne <> nil) then
    begin

      // fare liste görünüm nesnesinin yukarısında ise
      if(AOlay.Deger2 < 0) then
      begin

        j := ListeGorunum^.FGorunenIlkSiraNo;
        Dec(j);
        if(j >= 0) then
        begin

          ListeGorunum^.FGorunenIlkSiraNo := j;
          ListeGorunum^.FSeciliSiraNo := j;
        end;
      end

      // fare liste görünüm nesnesinin aşağısında ise
      else if(AOlay.Deger2 > ListeGorunum^.FAtananAlan.Yukseklik) then
      begin

        // azami kaydırma değeri
        i := ListeGorunum^.FKolonAdlari^.ElemanSayisi - ListeGorunum^.FGorunenElemanSayisi;
        if(i < 0) then i := 0;

        j := ListeGorunum^.FGorunenIlkSiraNo;
        Inc(j);
        if(j < i) then
        begin

          ListeGorunum^.FGorunenIlkSiraNo := j;
          i := (AOlay.Deger2 - 24) div 21;
          ListeGorunum^.FSeciliSiraNo := i + ListeGorunum^.FGorunenIlkSiraNo;
        end
      end

      // fare liste görünüm kutusunun içerisinde ise
      else
      begin

        i := (AOlay.Deger2 - 24) div 21;
        ListeGorunum^.FSeciliSiraNo := i + ListeGorunum^.FGorunenIlkSiraNo;
      end;

      // liste görünüm nesnesini yeniden çiz
      ListeGorunum^.Ciz;

      // uygulamaya veya efendi nesneye mesaj gönder
      if not(ListeGorunum^.OlayYonlendirmeAdresi = nil) then
        ListeGorunum^.OlayYonlendirmeAdresi(ListeGorunum, AOlay)
      else Gorevler0.OlayEkle(ListeGorunum^.GorevKimlik, AOlay);
    end

    // nesne yakalanmamış ise uygulamaya sadece mesaj gönder
    else
    begin

      // uygulamaya veya efendi nesneye mesaj gönder
      if not(ListeGorunum^.OlayYonlendirmeAdresi = nil) then
        ListeGorunum^.OlayYonlendirmeAdresi(ListeGorunum, AOlay)
      else Gorevler0.OlayEkle(ListeGorunum^.GorevKimlik, AOlay);
    end;
  end

  else if(AOlay.Olay = FO_KAYDIRMA) then
  begin

    // SISTEM_MESAJ(RENK_KIRMIZI, 'Kaydırma Değeri: %d', [AOlay.Deger1]);

    // listeyi yukarı kaydırma işlemi. ilk elemana doğru
    if(AOlay.Deger1 < 0) then
    begin

      j := ListeGorunum^.FGorunenIlkSiraNo;
      Dec(j);
      if(j >= 0) then ListeGorunum^.FGorunenIlkSiraNo := j;
    end

    // listeyi aşağıya kaydırma işlemi. son elemana doğru
    else if(AOlay.Deger1 > 0) then
    begin

      // azami kaydırma değeri
      i := ListeGorunum^.FDegerler^.ElemanSayisi - ListeGorunum^.FGorunenElemanSayisi;
      if(i < 0) then i := 0;

      j := ListeGorunum^.FGorunenIlkSiraNo;
      Inc(j);
      if(j < i) then ListeGorunum^.FGorunenIlkSiraNo := j;
    end;

    ListeGorunum^.Ciz;
  end
  // klavye tuş basımı
  else if(AOlay.Olay = CO_TUSBASILDI) then
  begin

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(ListeGorunum^.OlayYonlendirmeAdresi = nil) then
      ListeGorunum^.OlayYonlendirmeAdresi(ListeGorunum, AOlay)
    else Gorevler0.OlayEkle(ListeGorunum^.GorevKimlik, AOlay);
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := ListeGorunum^.FareImlecTipi;
end;

{==============================================================================
  seçili elemanın yazı (text) değerini geri döndürür
 ==============================================================================}
function TListeGorunum.SeciliSatirDegeriniAl: string;
var
  ListeGorunum: PListeGorunum;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  ListeGorunum := PListeGorunum(GorselNesneler0.NesneTipiniKontrolEt(Kimlik, gntListeGorunum));
  if(ListeGorunum = nil) then Exit('');

  if(ListeGorunum^.FSeciliSiraNo = -1) or (ListeGorunum^.FSeciliSiraNo > ListeGorunum^.FDegerler^.ElemanSayisi) then Exit('');

  Result := ListeGorunum^.FDegerler^.Yazi[ListeGorunum^.FSeciliSiraNo];
end;

{==============================================================================
  | ayıracıyla gelen karakter katarını bölümler
 ==============================================================================}
procedure TListeGorunum.Bolumle5(ABicimlenmisDeger: shortstring; AAyiracDeger: Char;
  ADegerDizisi: PYaziListesi);
var
  Uzunluk, i: TISayi4;
  s, s2: string;
begin

  ADegerDizisi^.Temizle;

  { TODO - direkt olarak ABicimlenmisDeger değişkeni kullanıldığında sistem kilitleniyor }
  s2 := ABicimlenmisDeger;

  Uzunluk := Length(s2);
  if(Uzunluk > 0) then
  begin

    i := 1;
    s := '';
    while i <= Uzunluk do
    begin

      if(s2[i] = AAyiracDeger) or (i = Uzunluk) then
      begin

        if(i = Uzunluk) then s := s + s2[i];

        if(Length(s) > 0) then
        begin

          ADegerDizisi^.Ekle(s);
          s := '';
        end;
      end else s := s + s2[i];

      Inc(i);
    end;
  end;
end;

end.
