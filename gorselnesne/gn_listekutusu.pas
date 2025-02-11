{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_listekutusu.pas
  Dosya İşlevi: liste kutusu (TListBox) yönetim işlevlerini içerir

  Güncelleme Tarihi: 11/02/2025

 ==============================================================================}
{$mode objfpc}
unit gn_listekutusu;

interface

uses gorselnesne, paylasim, n_yazilistesi, gn_panel;

type
  PListeKutusu = ^TListeKutusu;
  TListeKutusu = object(TPanel)
  private
    FSeciliSiraNo: TISayi4;               // seçili sıra değeri
    FGorunenIlkSiraNo: TISayi4;           // görünen ilk elemanın sıra numarası
    FGorunenElemanSayisi: TISayi4;        // nesne içindeki görünen eleman sayısı
    FYaziListesi: PYaziListesi;
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4): PListeKutusu;
    procedure YokEt;
    procedure Goster;
    procedure Gizle;
    procedure Boyutlandir;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    function SeciliYaziyiAl: string;
    procedure ListeyeEkle(ADeger: string);
    procedure SeciliSiraNoYaz(ASiraNo: TISayi4);
  end;

function ListeKutusuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;

implementation

uses genel, gn_islevler, gn_pencere, temelgorselnesne, sistemmesaj;

{==============================================================================
  liste kutusu kesme çağrılarını yönetir
 ==============================================================================}
function ListeKutusuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GorselNesne: PGorselNesne = nil;
  Pencere: PPencere = nil;
  ListeKutusu: PListeKutusu = nil;
  Hiza: THiza;
  p: PKarakterKatari;
begin

  case AIslevNo of

    // nesne oluştur
    ISLEV_OLUSTUR:
    begin

      GorselNesne := GorselNesne^.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GorselNesne, PISayi4(ADegiskenler + 04)^,
        PISayi4(ADegiskenler + 08)^, PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^);
    end;

    ISLEV_GOSTER:
    begin

      ListeKutusu := PListeKutusu(ListeKutusu^.NesneAl(PKimlik(ADegiskenler + 00)^));
      ListeKutusu^.Goster;
    end;

    ISLEV_GIZLE:
    begin

      ListeKutusu := PListeKutusu(ListeKutusu^.NesneAl(PKimlik(ADegiskenler + 00)^));
      ListeKutusu^.Gizle;
    end;

    ISLEV_HIZALA:
    begin

      ListeKutusu := PListeKutusu(ListeKutusu^.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      ListeKutusu^.FHiza := Hiza;

      Pencere := PPencere(ListeKutusu^.FAtaNesne);
      Pencere^.Guncelle;
    end;

    // eleman ekle
    $010F:
    begin

      ListeKutusu := PListeKutusu(ListeKutusu^.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeKutusu));
      if(ListeKutusu <> nil) then ListeKutusu^.ListeyeEkle(
        PKarakterKatari(PSayi4(ADegiskenler + 04)^ + CalisanGorevBellekAdresi)^);
      Result := 1;
    end;

    // liste içeriğini temizle
    $020F:
    begin

      ListeKutusu := PListeKutusu(ListeKutusu^.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeKutusu));
      if(ListeKutusu <> nil) then
      begin

        // eğer daha önce bellek ayrıldıysa
        ListeKutusu^.FGorunenIlkSiraNo := 0;
        ListeKutusu^.FSeciliSiraNo := -1;

        ListeKutusu^.FYaziListesi^.Temizle;
        if(ListeKutusu^.Gorunum) then ListeKutusu^.Ciz;
      end;
    end;

    // toplam eleman sayısını al
    $030E:
    begin

      ListeKutusu := PListeKutusu(ListeKutusu^.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeKutusu));
      if(ListeKutusu <> nil) then Result := ListeKutusu^.FYaziListesi^.ElemanSayisi;
    end;

    // seçilen sıra değerini al
    $040E:
    begin

      ListeKutusu := PListeKutusu(ListeKutusu^.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeKutusu));
      if(ListeKutusu <> nil) then Result := ListeKutusu^.FSeciliSiraNo;
    end;

    // seçilen sıra değerini yaz
    $040F:
    begin

      ListeKutusu := PListeKutusu(ListeKutusu^.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeKutusu));
      if(ListeKutusu <> nil) then ListeKutusu^.SeciliSiraNoYaz(PSayi4(ADegiskenler + 04)^);
    end;

    // liste kutusundaki belirli sıranın yazı (text) değerini geri döndür
    $050E:
    begin

      ListeKutusu := PListeKutusu(ListeKutusu^.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeKutusu));
      if(ListeKutusu <> nil) then
      begin

        p := PKarakterKatari(PSayi4(ADegiskenler + 08)^ + CalisanGorevBellekAdresi);
        p^ := ListeKutusu^.FYaziListesi^.Eleman[PSayi4(ADegiskenler + 04)^];
      end;
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  liste kutusu nesnesini oluşturur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
var
  ListeKutusu: PListeKutusu = nil;
begin

  ListeKutusu := ListeKutusu^.Olustur(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik);
  if(ListeKutusu = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := ListeKutusu^.Kimlik;
end;

{==============================================================================
  liste kutusu nesnesini oluşturur
 ==============================================================================}
function TListeKutusu.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4): PListeKutusu;
var
  ListeKutusu: PListeKutusu = nil;
  YL: PYaziListesi = nil;
begin

  ListeKutusu := PListeKutusu(inherited Olustur(AKullanimTipi, AAtaNesne, ASol, AUst,
    AGenislik, AYukseklik, 0, 0, 0, 0, ''));

  // görsel nesne tipi
  ListeKutusu^.NesneTipi := gntListeKutusu;

  ListeKutusu^.Baslik := '';

  ListeKutusu^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  ListeKutusu^.Odaklanilabilir := True;
  ListeKutusu^.Odaklanildi := False;

  ListeKutusu^.OlayCagriAdresi := @OlaylariIsle;

  ListeKutusu^.FCizimBaslangic.Sol := ListeKutusu^.AtaNesne^.FCizimBaslangic.Sol +
    ListeKutusu^.AtaNesne^.FKalinlik.Sol + ASol;
  ListeKutusu^.FCizimBaslangic.Ust := ListeKutusu^.AtaNesne^.FCizimBaslangic.Ust +
    ListeKutusu^.AtaNesne^.FKalinlik.Ust + AUst;

  ListeKutusu^.FYaziListesi := nil;
  YL := YL^.Olustur;
  if(YL <> nil) then ListeKutusu^.FYaziListesi := YL;

  // nesnenin kullanacağı diğer değerler
  ListeKutusu^.FGorunenIlkSiraNo := 0;
  ListeKutusu^.FSeciliSiraNo := -1;

  // liste kutusunda görüntülenecek eleman sayısı
  ListeKutusu^.FGorunenElemanSayisi := (AYukseklik + 17) div 18;

  // nesne adresini geri döndür
  Result := ListeKutusu;
end;

{==============================================================================
  nesne ve nesneye ayrılan kaynakları yok eder
 ==============================================================================}
procedure TListeKutusu.YokEt;
var
  ListeKutusu: PListeKutusu = nil;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  ListeKutusu := PListeKutusu(ListeKutusu^.NesneAl(Kimlik));
  if(ListeKutusu = nil) then Exit;

  if(ListeKutusu^.FYaziListesi <> nil) then ListeKutusu^.FYaziListesi^.YokEt;

  inherited YokEt;
end;

{==============================================================================
  liste kutusu nesnesini görüntüler
 ==============================================================================}
procedure TListeKutusu.Goster;
var
  Pencere: PPencere = nil;
begin

  inherited Goster;

  Pencere := PPencere(PListeKutusu(@Self)^.AtaNesne);
  if not(Pencere = nil) and (Pencere^.Gorunum) then Pencere^.Ciz;
end;

{==============================================================================
  liste kutusu nesnesini gizler
 ==============================================================================}
procedure TListeKutusu.Gizle;
var
  ListeKutusu: PListeKutusu = nil;
begin

  ListeKutusu := PListeKutusu(ListeKutusu^.NesneAl(Kimlik));
  if(ListeKutusu = nil) then Exit;

  inherited Gizle;

  if(ListeKutusu^.AtaNesne^.NesneTipi = gntPencere) then
  begin

    PPencere(ListeKutusu^.AtaNesne)^.Boyutlandir;
    PPencere(ListeKutusu^.AtaNesne)^.Ciz;
  end
  else if(ListeKutusu^.AtaNesne^.NesneTipi = gntPanel) then
  begin

    PPanel(ListeKutusu^.AtaNesne)^.Boyutlandir;
    PPanel(ListeKutusu^.AtaNesne)^.Ciz;
  end;
end;

{==============================================================================
  liste kutusu nesnesini boyutlandırır
 ==============================================================================}
procedure TListeKutusu.Boyutlandir;
var
  ListeKutusu: PListeKutusu = nil;
begin

  ListeKutusu := PListeKutusu(ListeKutusu^.NesneAl(Kimlik));
  if(ListeKutusu = nil) then Exit;

  ListeKutusu^.Hizala;
end;

{==============================================================================
  liste kutusu nesnesini çizer
 ==============================================================================}
procedure TListeKutusu.Ciz;
var
  ListeKutusu: PListeKutusu = nil;
  YL: PYaziListesi = nil;
  Alan: TAlan;
  SiraNo, Sol, Ust,
  GorunenElemanSayisi: TISayi4;
  s: string;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  ListeKutusu := PListeKutusu(ListeKutusu^.NesneAl(Kimlik));
  if(ListeKutusu = nil) then Exit;

  if not(ListeKutusu^.Gorunum) then Exit;

  // liste kutusunun üst nesneye bağlı olarak koordinatlarını al
  Alan := ListeKutusu^.FCizimAlan;

  // kenarlık çizgisini çiz
  KenarlikCiz(ListeKutusu, Alan, 2);

  // iç dolgu rengi
  ListeKutusu^.DikdortgenDoldur(ListeKutusu, Alan.Sol + 2, Alan.Ust + 2,
    Alan.Sag - 2, Alan.Alt - 2, RENK_BEYAZ, RENK_BEYAZ);

  YL := ListeKutusu^.FYaziListesi;

  // nesnenin elemanı var mı ?
  if(YL^.ElemanSayisi > 0) then
  begin

    // çizim / yazım için kullanılacak Sol & Ust koordinatları
    Sol := Alan.Sol + 4;
    Ust := Alan.Ust + 4;

    ListeKutusu^.FGorunenElemanSayisi := ((ListeKutusu^.FCizimAlan.Alt -
      ListeKutusu^.FCizimAlan.Ust) + 17) div 18;

    // liste kutusunda görüntülenecek eleman sayısı
    if(YL^.ElemanSayisi > ListeKutusu^.FGorunenElemanSayisi) then
      GorunenElemanSayisi := ListeKutusu^.FGorunenElemanSayisi + ListeKutusu^.FGorunenIlkSiraNo
    else GorunenElemanSayisi := YL^.ElemanSayisi + ListeKutusu^.FGorunenIlkSiraNo;

    // listenin ilk elemanın sıra numarası
    for SiraNo := ListeKutusu^.FGorunenIlkSiraNo to GorunenElemanSayisi - 1 do
    begin

      // belirtilen elemanın karakter katar değerini al
      s := YL^.Eleman[SiraNo];

      // elemanın seçili olması durumunda seçili olduğunu belirt
      // belirtilen sıra seçili değilse sadece eleman değerini yaz
      if(SiraNo = ListeKutusu^.FSeciliSiraNo) then
      begin

        ListeKutusu^.DikdortgenDoldur(ListeKutusu, Sol, Ust, Sol + ListeKutusu^.FBoyut.Genislik - 4 - 4,
          Ust + 18, $3EC5FF, $3EC5FF);
      end;

      ListeKutusu^.YaziYaz(ListeKutusu, Sol, Ust + 1, s, RENK_SIYAH);

      Ust += 18;
    end;
  end;
end;

{==============================================================================
  liste kutusu nesne olaylarını işler
 ==============================================================================}
procedure TListeKutusu.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere = nil;
  ListeKutusu: PListeKutusu = nil;
  i, SeciliSiraNo: TISayi4;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  ListeKutusu := PListeKutusu(AGonderici);
  if(ListeKutusu = nil) then Exit;

  // sol fare tuş basımı
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // liste kutusunun sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(ListeKutusu);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere^.FAktifNesne := ListeKutusu;
    ListeKutusu^.Odaklanildi := True;

    // sol tuşa basım işlemi nesnenin olay alanında mı gerçekleşti ?
    if(ListeKutusu^.FareNesneOlayAlanindaMi(ListeKutusu)) then
    begin

      // fare olaylarını yakala
      OlayYakalamayaBasla(ListeKutusu);

      // seçilen sıra numarasını belirle
      SeciliSiraNo := (AOlay.Deger2 - 4) div 18;

      // bu değere kaydırılan değeri de ekle
      ListeKutusu^.FSeciliSiraNo := SeciliSiraNo + ListeKutusu^.FGorunenIlkSiraNo;
    end;
  end

  // sol fare tuş bırakım işlemi
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    OlayYakalamayiBirak(ListeKutusu);

    // fare bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(ListeKutusu^.FareNesneOlayAlanindaMi(ListeKutusu)) then
      ListeKutusu^.SeciliSiraNoYaz(ListeKutusu^.FSeciliSiraNo);

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    if not(ListeKutusu^.OlayYonlendirmeAdresi = nil) then
      ListeKutusu^.OlayYonlendirmeAdresi(ListeKutusu, AOlay)
    else GorevListesi[ListeKutusu^.GorevKimlik]^.OlayEkle(ListeKutusu^.GorevKimlik, AOlay);
  end

  // fare hakeret işlemi
  else if(AOlay.Olay = FO_HAREKET) then
  begin

    // eğer nesne yakalanmış ise
    if(YakalananGorselNesne <> nil) then
    begin

      // fare liste kutusunun yukarısında ise
      if(AOlay.Deger2 < 0) then
      begin

        SeciliSiraNo := ListeKutusu^.FGorunenIlkSiraNo;
        Dec(SeciliSiraNo);
        if(SeciliSiraNo >= 0) then
        begin

          ListeKutusu^.FGorunenIlkSiraNo := SeciliSiraNo;
          ListeKutusu^.FSeciliSiraNo := SeciliSiraNo;
        end;
      end

      // fare liste kutusunun aşağısında ise
      else if(AOlay.Deger2 > ListeKutusu^.FBoyut.Yukseklik) then
      begin

        // azami kaydırma değeri
        i := ListeKutusu^.FYaziListesi^.ElemanSayisi - ListeKutusu^.FGorunenElemanSayisi;
        if(i < 0) then i := 0;

        SeciliSiraNo := ListeKutusu^.FGorunenIlkSiraNo;
        Inc(SeciliSiraNo);
        if(SeciliSiraNo < i) then
        begin

          ListeKutusu^.FGorunenIlkSiraNo := SeciliSiraNo;
          i := (AOlay.Deger2 - 4) div 18;
          ListeKutusu^.FSeciliSiraNo := i + ListeKutusu^.FGorunenIlkSiraNo;
        end
      end

      // fare liste kutusunun içerisinde ise
      else
      begin

        i := (AOlay.Deger2 - 4) div 18;
        ListeKutusu^.FSeciliSiraNo := i + ListeKutusu^.FGorunenIlkSiraNo;
      end;

      // liste kutusunu yeniden çiz
      ListeKutusu^.Ciz;

      // uygulamaya veya efendi nesneye mesaj gönder
{      if not(ListeKutusu^.OlayYonlendirmeAdresi = nil) then
        ListeKutusu^.OlayYonlendirmeAdresi(ListeKutusu, AOlay)
      else GorevListesi[ListeKutusu^.GorevKimlik]^.OlayEkle(ListeKutusu^.GorevKimlik, AOlay); }
    end

    // nesne yakalanmamış ise uygulamaya sadece mesaj gönder
    else
    begin

      // uygulamaya veya efendi nesneye mesaj gönder
      {if not(ListeKutusu^.OlayYonlendirmeAdresi = nil) then
        ListeKutusu^.OlayYonlendirmeAdresi(ListeKutusu, AOlay)
      else GorevListesi[ListeKutusu^.GorevKimlik]^.OlayEkle(ListeKutusu^.GorevKimlik, AOlay);}
    end;
  end

  else if(AOlay.Olay = FO_KAYDIRMA) then
  begin

    // listeyi yukarı kaydırma. ilk elemana doğru
    if(AOlay.Deger1 < 0) then
    begin

      SeciliSiraNo := ListeKutusu^.FGorunenIlkSiraNo;
      Dec(SeciliSiraNo);
      if(SeciliSiraNo >= 0) then ListeKutusu^.FGorunenIlkSiraNo := SeciliSiraNo;
    end

    // listeyi aşağıya kaydırma. son elemana doğru
    else if(AOlay.Deger1 > 0) then
    begin

      // azami kaydırma değeri
      i := ListeKutusu^.FYaziListesi^.ElemanSayisi - ListeKutusu^.FGorunenElemanSayisi;
      if(i < 0) then i := 0;

      SeciliSiraNo := ListeKutusu^.FGorunenIlkSiraNo;
      Inc(SeciliSiraNo);
      if(SeciliSiraNo < i) then ListeKutusu^.FGorunenIlkSiraNo := SeciliSiraNo;
    end;

    ListeKutusu^.Ciz;
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := ListeKutusu^.FFareImlecTipi;
end;

{==============================================================================
  liste kutusundaki seçili elemanın yazı (text) değerini geri döndürür
 ==============================================================================}
function TListeKutusu.SeciliYaziyiAl: string;
var
  ListeKutusu: PListeKutusu = nil;
  YL: PYaziListesi = nil;
begin

  Result := '';

  // nesnenin Kimlik, tip değerlerini denetle.
  ListeKutusu := PListeKutusu(ListeKutusu^.NesneTipiniKontrolEt(Kimlik, gntListeKutusu));
  if(ListeKutusu = nil) then Exit;

  YL := ListeKutusu^.FYaziListesi;

  // nesnenin elemanı var mı ?
  if(YL^.ElemanSayisi > 0) then
  begin

    if(FSeciliSiraNo < YL^.ElemanSayisi) then

      Result := YL^.Eleman[FSeciliSiraNo]
    else Result := '';
  end;
end;

{==============================================================================
  liste kutusu nesnesine eleman ekler
 ==============================================================================}
procedure TListeKutusu.ListeyeEkle(ADeger: string);
var
  ListeKutusu: PListeKutusu = nil;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  ListeKutusu := PListeKutusu(ListeKutusu^.NesneAl(Kimlik));
  if(ListeKutusu = nil) then Exit;

  ListeKutusu^.FYaziListesi^.Ekle(ADeger);
end;

procedure TListeKutusu.SeciliSiraNoYaz(ASiraNo: TISayi4);
var
  ListeKutusu: PListeKutusu = nil;
  Olay: TOlay;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  ListeKutusu := PListeKutusu(ListeKutusu^.NesneAl(Kimlik));
  if(ListeKutusu = nil) then Exit;

  ListeKutusu^.FSeciliSiraNo := ASiraNo;
  ListeKutusu^.Ciz;

  // nesneye FO_TIKLAMA mesajı gönder
  Olay.Kimlik := ListeKutusu^.Kimlik;
  Olay.Olay := FO_TIKLAMA;
  Olay.Deger1 := ListeKutusu^.FSeciliSiraNo;
  Olay.Deger2 := 0;
  if not(ListeKutusu^.OlayYonlendirmeAdresi = nil) then
    ListeKutusu^.OlayYonlendirmeAdresi(ListeKutusu, Olay)
  else GorevListesi[ListeKutusu^.GorevKimlik]^.OlayEkle(ListeKutusu^.GorevKimlik, Olay);
end;

end.
