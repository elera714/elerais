{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: gn_listegorunum.pas
  Dosya Ýþlevi: liste görünüm (TListView) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 03/04/2025

 ==============================================================================}
{$mode objfpc}
unit gn_listegorunum;

interface

uses gorselnesne, paylasim, n_yazilistesi, n_sayilistesi, gn_panel, sistemmesaj;

type
  PListeGorunum = ^TListeGorunum;
  TListeGorunum = object(TPanel)
  private
    FSeciliSiraNo: TISayi4;               // seçili sýra deðeri
    FGorunenIlkSiraNo: TISayi4;           // liste görünümde en üstte görüntülenen elemanýn sýra deðeri
    FGorunenElemanSayisi: TISayi4;        // kullanýcýya nesne içerisinde gösterilen eleman sayýsý
    FKolonAdlari: PYaziListesi;           // kolon ad listesi
    FKolonUzunluklari: PSayiListesi;      // kolon uzunluklarý
    FDegerler,                            // kolon içerik deðerleri
    FDegerDizisi: PYaziListesi;           // FDegerler içeriðini bölümlemek için kullanýlacak
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
    procedure Bolumle(ABicimlenmisDeger: string; AAyiracDeger: Char;
      DegerDizisi: PYaziListesi);
  end;

function ListeGorunumCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;

implementation

uses genel, gn_islevler, gn_pencere, temelgorselnesne, gorev;

{==============================================================================
  liste görünüm kesme çaðrýlarýný yönetir
 ==============================================================================}
function ListeGorunumCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne;
  Pencere: PPencere;
  ListeGorunum: PListeGorunum;
  Hiza: THiza;
  p: PKarakterKatari;
begin

  case AIslevNo of

    // nesne oluþtur
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

    // seçilen sýra deðerini al
    $020E:
    begin

      ListeGorunum := PListeGorunum(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeGorunum));
      if(ListeGorunum <> nil) then Result := ListeGorunum^.FSeciliSiraNo;
    end;

    // seçilen sýra deðerini yaz
    $020F:
    begin

      ListeGorunum := PListeGorunum(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeGorunum));
      if(ListeGorunum <> nil) then ListeGorunum^.FSeciliSiraNo := PISayi4(ADegiskenler + 04)^;
    end;

    // liste içeriðini temizle
    $030F:
    begin

      ListeGorunum := PListeGorunum(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeGorunum));
      if(ListeGorunum <> nil) then
      begin

        // içeriði temizle, deðerleri ön deðerlere çek
        ListeGorunum^.FDegerler^.Temizle;
        ListeGorunum^.FGorunenIlkSiraNo := 0;
        ListeGorunum^.FSeciliSiraNo := -1;
        ListeGorunum^.Ciz;
      end;
    end;

    // seçilen yazý (text) deðerini geri döndür
    $040E:
    begin

      ListeGorunum := PListeGorunum(GorselNesneler0.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntListeGorunum));
      if(ListeGorunum <> nil) then Result := ListeGorunum^.FSeciliSiraNo;
      p := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
      p^ := ListeGorunum^.SeciliSatirDegeriniAl;
    end;

    // liste görüntüleyicisinin baþlýklarýný sil
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
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  liste görünüm nesnesini oluþturur
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
  liste görünüm nesnesini oluþturur
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

  // nesnenin kullanacaðý diðer deðerler
  ListeGorunum^.FGorunenIlkSiraNo := 0;
  ListeGorunum^.FSeciliSiraNo := -1;

  // liste görünüm nesnesinde görüntülenecek eleman sayýsý
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

  ListeGorunum := PListeGorunum(GorselNesneler0.NesneAl(Kimlik));
  if(ListeGorunum = nil) then Exit;

  if(ListeGorunum^.FDegerler <> nil) then YaziListesi0.YokEt(ListeGorunum^.FDegerler^.Kimlik);
  if(ListeGorunum^.FDegerDizisi <> nil) then YaziListesi0.YokEt(ListeGorunum^.FDegerDizisi^.Kimlik);
  if(ListeGorunum^.FKolonAdlari <> nil) then YaziListesi0.YokEt(ListeGorunum^.FKolonAdlari^.Kimlik);
  if(ListeGorunum^.FKolonUzunluklari <> nil) then SayiListesi0.YokEt(ListeGorunum^.FKolonUzunluklari^.Kimlik);

  GorselNesneler0.YokEt(AKimlik);
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
  liste görünüm nesnesini hizalandýrýr
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
  ListeGorunum: PListeGorunum;
  KolonAdlari: PYaziListesi;
  KolonUzunluklari: PSayiListesi;
  Alan1, Alan2: TAlan;
  ElemanSayisi, SatirNo, i, j,
  Sol, Ust: TISayi4;
  RY: TRenkYazi;
  s: String;
begin

  ListeGorunum := PListeGorunum(GorselNesneler0.NesneAl(Kimlik));
  if(ListeGorunum = nil) then Exit;

  inherited Ciz;

  // liste kutusunun üst nesneye baðlý olarak koordinatlarýný al
  Alan1 := ListeGorunum^.FCizimAlan;

  // ata nesne bir pencere mi?
  Pencere := EnUstPencereNesnesiniAl(ListeGorunum);
  if(Pencere = nil) then Exit;

  KolonUzunluklari := ListeGorunum^.FKolonUzunluklari;
  KolonAdlari := ListeGorunum^.FKolonAdlari;

  // tanýmlanmýþ hiçbir kolon yok ise, çýk
  if(KolonAdlari^.ElemanSayisi = 0) then Exit;

  // kolon baþlýk ve deðerleri
  Sol := Alan1.Sol + 1;
  for i := 0 to KolonUzunluklari^.ElemanSayisi - 1 do
  begin

    Sol += KolonUzunluklari^.Sayi[i];

    // dikey kýlavuz çizgisi
    ListeGorunum^.Cizgi(ListeGorunum, ctDuz, Sol, Alan1.Ust + 1, Sol, Alan1.Alt - 1, $F0F0F0);

    // baþlýk dolgusu
    Alan2.Sol := Sol - KolonUzunluklari^.Sayi[i];
    Alan2.Ust := Alan1.Ust + 1;
    Alan2.Sag := Sol - 1;
    Alan2.Alt := Alan1.Ust + 1 + 22;
    ListeGorunum^.EgimliDoldur3(ListeGorunum, Alan2, $EAECEE, $ABB2B9);

    // baþlýk
    ListeGorunum^.AlanaYaziYaz(ListeGorunum, Alan2, 4, 3, KolonAdlari^.Yazi[i], RENK_LACIVERT);

    Inc(Sol);    // 1 px çizgi kalýnlýðý
  end;

  // yatay kýlavuz çizgileri
  Ust := Alan1.Ust + 1 + 22;
  Ust += 20;
  while Ust < Alan1.Alt do
  begin

    ListeGorunum^.Cizgi(ListeGorunum, ctDuz, Alan1.Sol + 1, Ust, Alan1.Sag - 1, Ust, $F0F0F0);
    Ust += 1 + 20;
  end;

  // liste görünüm nesnesinde görüntülenecek eleman sayýsý
  ListeGorunum^.FGorunenElemanSayisi := ((ListeGorunum^.FCizimAlan.Alt -
    ListeGorunum^.FCizimAlan.Ust) - 24) div 21;

  // liste görünüm kutusunda görüntülenecek eleman sayýsýnýn belirlenmesi
  if(FDegerler^.ElemanSayisi > ListeGorunum^.FGorunenElemanSayisi) then
    ElemanSayisi := ListeGorunum^.FGorunenElemanSayisi + ListeGorunum^.FGorunenIlkSiraNo
  else ElemanSayisi := FDegerler^.ElemanSayisi + ListeGorunum^.FGorunenIlkSiraNo;

  Ust := Alan1.Ust + 1 + 22;
  Ust += 20;
  SatirNo := 0;
  KolonUzunluklari := ListeGorunum^.FKolonUzunluklari;

  // liste görünüm deðerlerini yerleþtir
  for SatirNo := ListeGorunum^.FGorunenIlkSiraNo to ElemanSayisi - 1 do
  begin

    // deðeri belirtilen karakter ile bölümle
    Bolumle(FDegerler^.Yazi[SatirNo], '|', FDegerDizisi);
    RY := FDegerler^.RenkYaziAl(SatirNo);

    Sol := Alan1.Sol + 1;
    if(FDegerDizisi^.ElemanSayisi > 0) then
    begin

      for j := 0 to FDegerDizisi^.ElemanSayisi - 1 do
      begin

        s := FDegerDizisi^.Yazi[j];
        Alan2.Sol := Sol + 1;
        Alan2.Ust := Ust - 20 + 1;
        Alan2.Sag := Sol + KolonUzunluklari^.Sayi[j] - 1;
        Alan2.Alt := Ust - 1;

        // satýr verisini boyama ve yazma iþlemi
        if(SatirNo = ListeGorunum^.FSeciliSiraNo) then
        begin

          if(ListeGorunum^.Odaklanildi) then
            ListeGorunum^.DikdortgenDoldur(ListeGorunum, Alan2.Sol - 1, Alan2.Ust - 1,
              Alan2.Sag, Alan2.Alt, $3EC5FF, $3EC5FF)
          else ListeGorunum^.DikdortgenDoldur(ListeGorunum, Alan2.Sol - 1, Alan2.Ust - 1,
            Alan2.Sag, Alan2.Alt, RENK_GRI, RENK_GRI);
        end
        else
        begin

          ListeGorunum^.DikdortgenDoldur(ListeGorunum, Alan2.Sol - 1, Alan2.Ust - 1,
            Alan2.Sag, Alan2.Alt, RENK_BEYAZ, RENK_BEYAZ);
        end;

        ListeGorunum^.AlanaYaziYaz(ListeGorunum, Alan2, 2, 2, s, RY.Renk);

        Sol += 1 + KolonUzunluklari^.Sayi[j];
      end;
    end;

    Ust += 1 + 20;
  end;
end;

{==============================================================================
  liste görünüm nesne olaylarýný iþler
 ==============================================================================}
procedure TListeGorunum.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere;
  ListeGorunum: PListeGorunum;
  i, j: TISayi4;
begin

  ListeGorunum := PListeGorunum(AGonderici);

  // sol / sað fare tuþ basýmý
  if(AOlay.Olay = FO_SOLTUS_BASILDI) or (AOlay.Olay = FO_SAGTUS_BASILDI) then
  begin

    // liste görünümün sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(ListeGorunum);

    // en üstte olmamasý durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak iþaretle
    Pencere^.FAktifNesne := ListeGorunum;
    ListeGorunum^.Odaklanildi := True;

    // sol tuþa basým iþlemi nesnenin olay alanýnda mý gerçekleþti ?
    if(ListeGorunum^.FareNesneOlayAlanindaMi(ListeGorunum)) then
    begin

      // fare olaylarýný yakala
      if(AOlay.Olay = FO_SOLTUS_BASILDI) then OlayYakalamayaBasla(ListeGorunum);

      // seçilen sýrayý yeniden belirle
      j := (AOlay.Deger2 - 24) div 21;

      // bu deðere kaydýrýlan deðeri de ekle
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

  // sol fare tuþ býrakým iþlemi
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarýný almayý býrak
    OlayYakalamayiBirak(ListeGorunum);

    // fare býrakma iþlemi nesnenin olay alanýnda mý gerçekleþti ?
    if(ListeGorunum^.FareNesneOlayAlanindaMi(ListeGorunum)) then
    begin

      // yakalama & býrakma iþlemi bu nesnede olduðu için
      // nesneye FO_TIKLAMA mesajý gönder
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

  // fare hakeret iþlemi
  else if(AOlay.Olay = FO_HAREKET) then
  begin

    // eðer nesne yakalanmýþ ise
    if(YakalananGorselNesne <> nil) then
    begin

      // fare liste görünüm nesnesinin yukarýsýnda ise
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

      // fare liste görünüm nesnesinin aþaðýsýnda ise
      else if(AOlay.Deger2 > ListeGorunum^.FAtananAlan.Yukseklik) then
      begin

        // azami kaydýrma deðeri
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

    // nesne yakalanmamýþ ise uygulamaya sadece mesaj gönder
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

    // SISTEM_MESAJ(RENK_KIRMIZI, 'Kaydýrma Deðeri: %d', [AOlay.Deger1]);

    // listeyi yukarý kaydýrma iþlemi. ilk elemana doðru
    if(AOlay.Deger1 < 0) then
    begin

      j := ListeGorunum^.FGorunenIlkSiraNo;
      Dec(j);
      if(j >= 0) then ListeGorunum^.FGorunenIlkSiraNo := j;
    end

    // listeyi aþaðýya kaydýrma iþlemi. son elemana doðru
    else if(AOlay.Deger1 > 0) then
    begin

      // azami kaydýrma deðeri
      i := ListeGorunum^.FDegerler^.ElemanSayisi - ListeGorunum^.FGorunenElemanSayisi;
      if(i < 0) then i := 0;

      j := ListeGorunum^.FGorunenIlkSiraNo;
      Inc(j);
      if(j < i) then ListeGorunum^.FGorunenIlkSiraNo := j;
    end;

    ListeGorunum^.Ciz;
  end
  // klavye tuþ basýmý
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
  seçili elemanýn yazý (text) deðerini geri döndürür
 ==============================================================================}
function TListeGorunum.SeciliSatirDegeriniAl: string;
var
  ListeGorunum: PListeGorunum;
begin

  // nesnenin kimlik, tip deðerlerini denetle.
  ListeGorunum := PListeGorunum(GorselNesneler0.NesneTipiniKontrolEt(Kimlik, gntListeGorunum));
  if(ListeGorunum = nil) then Exit;

  if(FSeciliSiraNo = -1) or (FSeciliSiraNo > FDegerler^.ElemanSayisi) then Exit('');

  Result := ListeGorunum^.FDegerler^.Yazi[FSeciliSiraNo];
end;

{==============================================================================
  | ayýracýyla gelen karakter katarýný bölümler
 ==============================================================================}
procedure TListeGorunum.Bolumle(ABicimlenmisDeger: string; AAyiracDeger: Char;
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

end.
