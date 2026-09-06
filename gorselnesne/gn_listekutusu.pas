{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_listekutusu.pas
  Dosya İşlevi: liste kutusu (TListBox) yönetim işlevlerini içerir

  Güncelleme Tarihi: 17/08/2026

 ==============================================================================}
{$mode objfpc}
unit gn_listekutusu;

interface

uses gorselnesne, paylasim, n_yazilistesi, gn_panel;

type
  PListeKutusu = ^TListeKutusu;
  TListeKutusu = class(TPanel)
  private
    FYaziListesi: TYaziListesi;
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
    function SeciliYaziyiAl: string;
    procedure ListeyeEkle(ADeger: string);
    procedure SeciliSiraNoYaz(ASiraNo: TISayi4);
    // seçili sıra değeri
    property SeciliSiraNo: TISayi4 read FIDeger1 write FIDeger1;
    // görünen ilk elemanın sıra numarası
    property GorunenIlkSiraNo: TISayi4 read FIDeger2 write FIDeger2;
    // nesne içindeki görünen eleman sayısı
    property GorunenElemanSayisi: TISayi4 read FIDeger3 write FIDeger3;
  end;

function ListeKutusuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function ListeKutusuGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;

implementation

uses gn_islevler, gn_pencere, gorev, src_ps2;

{==============================================================================
  liste kutusu kesme çağrılarını yönetir
 ==============================================================================}
function ListeKutusuCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: TGorselNesne;
  Pencere: TPencere;
  ListeKutusu: TListeKutusu;
  Hiza: THiza;
  p: PKarakterKatari;
begin

  Result := HATA_ISLEV;

  case AIslevNo of

    // nesne oluştur
    ISLEV_OLUSTUR:
    begin

      GN := GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := ListeKutusuGNOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^);
    end;

    ISLEV_GOSTER:
    begin

      ListeKutusu := TListeKutusu(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      ListeKutusu.Goster;
    end;

    ISLEV_GIZLE:
    begin

      ListeKutusu := TListeKutusu(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      ListeKutusu.Gizle;
    end;

    ISLEV_HIZALA:
    begin

      ListeKutusu := TListeKutusu(GGNesneler.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      ListeKutusu.FHiza := Hiza;

      Pencere := TPencere(ListeKutusu.FAtaNesne);
      Pencere.Guncelle;
    end;

    // eleman ekle
    $010F:
    begin

      ListeKutusu := TListeKutusu(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeKutusu));
      if(ListeKutusu <> nil) then ListeKutusu.ListeyeEkle(
        PKarakterKatari(PSayi4(ADegiskenler + 04)^ + GGorevler.FAktifGrvBelAdr)^);
      Result := 1;
    end;

    // liste içeriğini temizle
    $020F:
    begin

      ListeKutusu := TListeKutusu(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeKutusu));
      if(ListeKutusu <> nil) then
      begin

        // eğer daha önce bellek ayrıldıysa
        ListeKutusu.GorunenIlkSiraNo := 0;
        ListeKutusu.SeciliSiraNo := -1;

        ListeKutusu.FYaziListesi.Temizle;
        if(ListeKutusu.Gorunum) then ListeKutusu.Ciz;
      end;
    end;

    // toplam eleman sayısını al
    $030E:
    begin

      ListeKutusu := TListeKutusu(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeKutusu));
      if(ListeKutusu <> nil) then Result := ListeKutusu.FYaziListesi.ElemanSayisi;
    end;

    // seçilen sıra değerini al
    $040E:
    begin

      ListeKutusu := TListeKutusu(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeKutusu));
      if(ListeKutusu <> nil) then Result := ListeKutusu.SeciliSiraNo;
    end;

    // seçilen sıra değerini yaz
    $040F:
    begin

      ListeKutusu := TListeKutusu(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeKutusu));
      if(ListeKutusu <> nil) then ListeKutusu.SeciliSiraNoYaz(PSayi4(ADegiskenler + 04)^);
    end;

    // liste kutusundaki belirli sıranın yazı (text) değerini geri döndür
    $050E:
    begin

      ListeKutusu := TListeKutusu(GGNesneler.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeKutusu));
      if(ListeKutusu <> nil) then
      begin

        p := PKarakterKatari(PSayi4(ADegiskenler + 08)^ + GGorevler.FAktifGrvBelAdr);
        p^ := ListeKutusu.FYaziListesi.Yazi[PSayi4(ADegiskenler + 04)^];
      end;
    end;
  end;
end;

{==============================================================================
  uygulama için liste kutusu nesnesi oluşturur - api
 ==============================================================================}
function ListeKutusuGNOlustur(AAtaNesne: TGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
var
  ListeKutusu: TListeKutusu;
begin

  ListeKutusu := TListeKutusu.Create;

  if(ListeKutusu = nil) then

    Result := HATA_NESNEOLUSTURMA
  else
  begin

    ListeKutusu.Ozellestir(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik);

    Result := ListeKutusu.Kimlik;
  end;
end;

{==============================================================================
  liste kutusu nesnesi oluşturur
 ==============================================================================}
constructor TListeKutusu.Create;
begin

  inherited Create;

  FYaziListesi := TYaziListesi.Create;

  NesneTipi := gntListeKutusu;

  GGNesneler.GorselNesne[FSiraNo] := Self;
end;

{==============================================================================
  liste kutusu nesnesini yok eder
 ==============================================================================}
destructor TListeKutusu.Destroy;
begin

  if(FYaziListesi <> nil) then FYaziListesi.Destroy;

  GGNesneler.YokEt(Self);

  inherited Destroy;
end;

{==============================================================================
  liste kutusu nesnesini özelleştirir
 ==============================================================================}
function TListeKutusu.Ozellestir(AKullanimTipi: TKullanimTipi; AAtaNesne: TGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4): TISayi4;
begin

  Yapilandir2(AKullanimTipi, Self, AAtaNesne, ASol, AUst, AGenislik, AYukseklik,
    0, 0, 0, 0, '');

  OlayCagriAdr := @OlaylariIsle;

  FCizimBaslangic.Sol := AtaNesne.FCizimBaslangic.Sol + AtaNesne.FKalinlik.Sol + ASol;
  FCizimBaslangic.Ust := AtaNesne.FCizimBaslangic.Ust + AtaNesne.FKalinlik.Ust + AUst;

  Odaklanilabilir := True;
  Odaklanildi := False;

  // nesnenin kullanacağı diğer değerler
  GorunenIlkSiraNo := 0;
  SeciliSiraNo := -1;

  // liste kutusunda görüntülenecek eleman sayısı
  GorunenElemanSayisi := (AYukseklik + 17) div 18;

  // geri dönüş değeri
  Result := HATA_YOK;
end;

{==============================================================================
  liste kutusu nesnesini görüntüler
 ==============================================================================}
procedure TListeKutusu.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  liste kutusu nesnesini gizler
 ==============================================================================}
procedure TListeKutusu.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  liste kutusu nesnesini hizalandırır
 ==============================================================================}
procedure TListeKutusu.Hizala;
begin

  inherited Hizala;
end;

{==============================================================================
  liste kutusu nesnesini çizer
 ==============================================================================}
procedure TListeKutusu.Ciz;
var
  CizimAlani: TAlan;
  SiraNo, Sol, Ust,
  ListedekiElemanSayisi: TISayi4;
  s: string;
begin

  if not(Gorunum) then Exit;

  // liste kutusunun üst nesneye bağlı olarak koordinatlarını al
  CizimAlani := FCizimAlani;

  // kenarlık çizgisini çiz
  KenarlikCiz(Self, CizimAlani, 2);

  // iç dolgu rengi
  DikdortgenDoldur(Self, CizimAlani.Sol + 2, CizimAlani.Ust + 2,
    CizimAlani.Sag - 2, CizimAlani.Alt - 2, RENK_BEYAZ, RENK_BEYAZ);

  // nesnenin elemanı var mı ?
  if(FYaziListesi.ElemanSayisi > 0) then
  begin

    // çizim / yazım için kullanılacak Sol & Ust koordinatları
    Sol := CizimAlani.Sol + 4;
    Ust := CizimAlani.Ust + 4;

    GorunenElemanSayisi := ((FCizimAlani.Alt - FCizimAlani.Ust) + 17) div 18;

    // liste kutusunda görüntülenecek eleman sayısı
    if(FYaziListesi.ElemanSayisi > GorunenElemanSayisi) then
      ListedekiElemanSayisi := GorunenElemanSayisi + GorunenIlkSiraNo
    else ListedekiElemanSayisi := FYaziListesi.ElemanSayisi + GorunenIlkSiraNo;

    // listenin ilk elemanın sıra numarası
    for SiraNo := GorunenIlkSiraNo to ListedekiElemanSayisi - 1 do
    begin

      // belirtilen elemanın karakter katar değerini al
      s := FYaziListesi.Yazi[SiraNo];

      // elemanın seçili olması durumunda seçili olduğunu belirt
      // belirtilen sıra seçili değilse sadece eleman değerini yaz
      if(SiraNo = SeciliSiraNo) then
      begin

        DikdortgenDoldur(Self, Sol, Ust, Sol + FAtananAlan.Genislik - 4 - 4,
          Ust + 18, $3EC5FF, $3EC5FF);
      end;

      YaziYaz(Self, Sol, Ust + 1, s, RENK_SIYAH);

      Ust := Ust + 18;
    end;
  end;
end;

{==============================================================================
  liste kutusu nesne olaylarını işler
 ==============================================================================}
procedure TListeKutusu.OlaylariIsle(AGonderici: TGorselNesne; AOlay: TOlay);
var
  Pencere: TPencere;
  ListeKutusu: TListeKutusu;
  i, SSN: TISayi4;
begin

  // nesnenin kimlik, tip değerlerini denetle.
  ListeKutusu := TListeKutusu(AGonderici);
  if(ListeKutusu = nil) then Exit;

  // sol fare tuş basımı
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // liste kutusunun sahibi olan pencere en üstte mi ? kontrol et
    Pencere := GGNesneler.EnUstPencereNesnesiniAl(ListeKutusu);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GGNesneler.AktifPencere) then
      Pencere.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    Pencere.FAktifNesne := ListeKutusu;
    ListeKutusu.Odaklanildi := True;

    // sol tuşa basım işlemi nesnenin olay alanında mı gerçekleşti ?
    if(ListeKutusu.FareNesneOlayAlanindaMi(ListeKutusu)) then
    begin

      // fare olaylarını yakala
      GGNesneler.OlayYakalamayaBasla(ListeKutusu);

      // seçilen sıra numarasını belirle
      SSN := (AOlay.Deger2 - 4) div 18;

      // bu değere kaydırılan değeri de ekle
      ListeKutusu.SeciliSiraNo := SSN + ListeKutusu.GorunenIlkSiraNo;
    end;
  end

  // sol fare tuş bırakım işlemi
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    GGNesneler.OlayYakalamayiBirak(ListeKutusu);

    // fare bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(ListeKutusu.FareNesneOlayAlanindaMi(ListeKutusu)) then
      ListeKutusu.SeciliSiraNoYaz(ListeKutusu.SeciliSiraNo);

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    if not(ListeKutusu.OlayYonlAdr = nil) then
      ListeKutusu.OlayYonlAdr(ListeKutusu, AOlay)
    else GGorevler.OlayEkle(ListeKutusu.GrvKimlik, AOlay);
  end

  // fare hareket işlemi
  else if(AOlay.Olay = FO_HAREKET) then
  begin

    // eğer nesne yakalanmış ise
    if(GGNesneler.YakalananGorselNesne <> nil) then
    begin

      // fare liste kutusunun yukarısında ise
      if(AOlay.Deger2 < 0) then
      begin

        SSN := ListeKutusu.GorunenIlkSiraNo;
        Dec(SSN);
        if(SSN >= 0) then
        begin

          ListeKutusu.GorunenIlkSiraNo := SSN;
          ListeKutusu.SeciliSiraNo := SSN;
        end;
      end

      // fare liste kutusunun aşağısında ise
      else if(AOlay.Deger2 > ListeKutusu.FAtananAlan.Yukseklik) then
      begin

        // azami kaydırma değeri
        i := ListeKutusu.FYaziListesi.ElemanSayisi - ListeKutusu.GorunenElemanSayisi;
        if(i < 0) then i := 0;

        SSN := ListeKutusu.GorunenIlkSiraNo;
        Inc(SSN);
        if(SSN < i) then
        begin

          ListeKutusu.GorunenIlkSiraNo := SSN;
          i := (AOlay.Deger2 - 4) div 18;
          ListeKutusu.SeciliSiraNo := i + ListeKutusu.GorunenIlkSiraNo;
        end
      end

      // fare liste kutusunun içerisinde ise
      else
      begin

        i := (AOlay.Deger2 - 4) div 18;
        ListeKutusu.SeciliSiraNo := i + ListeKutusu.GorunenIlkSiraNo;
      end;

      // liste kutusunu yeniden çiz
      ListeKutusu.Ciz;

      // uygulamaya veya efendi nesneye mesaj gönder
{      if not(ListeKutusu^.OlayYonlAdr = nil) then
        ListeKutusu^.OlayYonlAdr(ListeKutusu, AOlay)
      else GorevListesi[ListeKutusu^.GrvKimlik]^.OlayEkle(ListeKutusu^.GrvKimlik, AOlay); }
    end

    // nesne yakalanmamış ise uygulamaya sadece mesaj gönder
    else
    begin

      // uygulamaya veya efendi nesneye mesaj gönder
      {if not(ListeKutusu^.OlayYonlAdr = nil) then
        ListeKutusu^.OlayYonlAdr(ListeKutusu, AOlay)
      else GorevListesi[ListeKutusu^.GrvKimlik]^.OlayEkle(ListeKutusu^.GrvKimlik, AOlay);}
    end;
  end

  else if(AOlay.Olay = FO_KAYDIRMA) then
  begin

    // listeyi yukarı kaydırma. ilk elemana doğru
    if(AOlay.Deger1 < 0) then
    begin

      SSN := ListeKutusu.GorunenIlkSiraNo;
      Dec(SSN);
      if(SSN >= 0) then ListeKutusu.GorunenIlkSiraNo := SSN;
    end

    // listeyi aşağıya kaydırma. son elemana doğru
    else if(AOlay.Deger1 > 0) then
    begin

      // azami kaydırma değeri
      i := ListeKutusu.FYaziListesi.ElemanSayisi - ListeKutusu.GorunenElemanSayisi;
      if(i < 0) then i := 0;

      SSN := ListeKutusu.GorunenIlkSiraNo;
      Inc(SSN);
      if(SSN < i) then ListeKutusu.GorunenIlkSiraNo := SSN;
    end;

    ListeKutusu.Ciz;
  end;

  // aktif fare göstergesini güncelle
  GFareSurucusu.AktifFareImlec := ListeKutusu.FareImlec;
end;

{==============================================================================
  liste kutusundaki seçili elemanın yazı (text) değerini geri döndürür
 ==============================================================================}
function TListeKutusu.SeciliYaziyiAl: string;
begin

  Result := '';

  // nesnenin elemanı var mı ?
  if(FYaziListesi.ElemanSayisi > 0) then
  begin

    if(SeciliSiraNo < FYaziListesi.ElemanSayisi) then

      Result := FYaziListesi.Yazi[SeciliSiraNo]

    else Result := '';
  end;
end;

{==============================================================================
  liste kutusu nesnesine eleman ekler
 ==============================================================================}
procedure TListeKutusu.ListeyeEkle(ADeger: string);
begin

  FYaziListesi.Ekle(ADeger);
end;

procedure TListeKutusu.SeciliSiraNoYaz(ASiraNo: TISayi4);
var
  Olay: TOlay;
begin

  SeciliSiraNo := ASiraNo;
  Ciz;

  // nesneye FO_TIKLAMA mesajı gönder
  Olay.Kimlik := Kimlik;
  Olay.Olay := FO_TIKLAMA;
  Olay.Deger1 := SeciliSiraNo;
  Olay.Deger2 := 0;
  if not(OlayYonlAdr = nil) then
    OlayYonlAdr(Self, Olay)
  else GGorevler.OlayEkle(Self.GrvKimlik, Olay);
end;

end.
