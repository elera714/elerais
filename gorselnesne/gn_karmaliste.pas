{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: gn_karmaliste.pas
  Dosya Ýþlevi: karma liste (açýlýr / kapanýr liste kutusu (TComboBox)) yönetim iþlevlerini içerir

  Güncelleme Tarihi: 26/02/2025

 ==============================================================================}
{$mode objfpc}
unit gn_karmaliste;

interface

uses gorselnesne, paylasim, gn_pencere, n_yazilistesi, gn_panel, gn_acilirmenu;

type
  PKarmaListe = ^TKarmaListe;
  TKarmaListe = object(TPanel)
  private
    FAcilirMenu: PAcilirMenu;
    procedure OkResminiCiz(AGorselNesne: PGorselNesne; AAlan: TAlan);
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik: TISayi4): PKarmaListe;
    procedure YokEt;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    procedure AcilirMenuOlaylariniIsle(AGonderici: PGorselNesne; AOlay: TOlay);
    procedure ListeyeEkle(ADeger: string);
    procedure ListeyiTemizle;
    procedure BaslikSiraNoYaz(ASiraNo: TISayi4);
  end;

function KarmaListeCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;

implementation

uses genel, gn_islevler, temelgorselnesne, hamresim, sistemmesaj, gorev;

{==============================================================================
  karma liste kesme çaðrýlarýný yönetir
 ==============================================================================}
function KarmaListeCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GN: PGorselNesne;
  Pencere: PPencere;
  KarmaListe: PKarmaListe;
  Hiza: THiza;
  p: PKarakterKatari;
  i: ISayi4;
begin

  case AIslevNo of

    // nesne oluþtur
    ISLEV_OLUSTUR:
    begin

      GN := GN^.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GN, PISayi4(ADegiskenler + 04)^, PISayi4(ADegiskenler + 08)^,
        PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^);
    end;

    ISLEV_GOSTER:
    begin

      KarmaListe := PKarmaListe(KarmaListe^.NesneAl(PKimlik(ADegiskenler + 00)^));
      KarmaListe^.Goster;
    end;

    ISLEV_HIZALA:
    begin

      KarmaListe := PKarmaListe(KarmaListe^.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      KarmaListe^.FHiza := Hiza;

      Pencere := PPencere(KarmaListe^.FAtaNesne);
      Pencere^.Guncelle;
    end;

    // eleman ekle
    $010F:
    begin

      { TODO : nesneye her eleman eklendikçe nesnenin yüksekliði otomatik artýrýlacak }
      KarmaListe := PKarmaListe(KarmaListe^.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntKarmaListe));
      if(KarmaListe <> nil) then
        KarmaListe^.ListeyeEkle(PKarakterKatari(PSayi4(ADegiskenler + 04)^ +
          FAktifGorevBellekAdresi)^);

      Result := 1;
    end;

    // liste içeriðini temizle
    $020F:
    begin

      KarmaListe := PKarmaListe(KarmaListe^.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntKarmaListe));
      if(KarmaListe <> nil) then
      begin

        // eðer daha önce bellek ayrýldýysa
        KarmaListe^.Baslik := '';

        KarmaListe^.FAcilirMenu^.FMenuBaslikListesi^.Temizle;
        KarmaListe^.Ciz;
      end;
    end;

    // karma listedeki seçilen yazý (text) deðerini geri döndür
    $030E:
    begin

      KarmaListe := PKarmaListe(KarmaListe^.NesneTipiniKontrolEt(
        PKimlik(ADegiskenler + 00)^, gntKarmaListe));
      if(KarmaListe <> nil) then
      begin

        p := PKarakterKatari(PSayi4(ADegiskenler + 04)^ + FAktifGorevBellekAdresi);
        p^ := KarmaListe^.Baslik;
      end;
    end;

    // toplam kayýt sayýsýný al
    $040E:
    begin

      KarmaListe := PKarmaListe(KarmaListe^.NesneAl(PKimlik(ADegiskenler + 00)^));
      if not(KarmaListe = nil) then Result := KarmaListe^.FAcilirMenu^.FMenuBaslikListesi^.ElemanSayisi;
    end;

    // seçili sýra numarasýný al
    $050E:
    begin

      KarmaListe := PKarmaListe(KarmaListe^.NesneAl(PKimlik(ADegiskenler + 00)^));
      if not(KarmaListe = nil) then
        Result := KarmaListe^.FAcilirMenu^.FSeciliSiraNo
      else Result := -1;
    end;

    // seçili sýra numarasýný yaz
    $050F:
    begin

      KarmaListe := PKarmaListe(KarmaListe^.NesneAl(PKimlik(ADegiskenler + 00)^));
      if not(KarmaListe = nil) then
      begin

        i := PISayi4(ADegiskenler + 04)^;
        KarmaListe^.BaslikSiraNoYaz(i);
      end;
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  karma liste nesnesini oluþturur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik: TISayi4): TKimlik;
var
  KarmaListe: PKarmaListe;
begin

  KarmaListe := KarmaListe^.Olustur(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik);
  if(KarmaListe = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := KarmaListe^.Kimlik;
end;

{==============================================================================
  karma liste nesnesini oluþturur
 ==============================================================================}
function TKarmaListe.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik: TISayi4): PKarmaListe;
var
  KarmaListe: PKarmaListe;
begin

  KarmaListe := PKarmaListe(inherited Olustur(AKullanimTipi, AAtaNesne, ASol, AUst,
    AGenislik, 22 {AYukseklik}, 2, RENK_GRI, RENK_BEYAZ, 0, ''));

  KarmaListe^.NesneTipi := gntKarmaListe;

  KarmaListe^.Baslik := '';

  KarmaListe^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  KarmaListe^.OlayCagriAdresi := @OlaylariIsle;

  KarmaListe^.FAcilirMenu := KarmaListe^.FAcilirMenu^.Olustur(KarmaListe, 0, 0,
    AGenislik, (24 * 2) + 2, 24, RENK_GRI, RENK_BEYAZ, RENK_SARI, RENK_SIYAH, RENK_LACIVERT);
  KarmaListe^.FAcilirMenu^.FYardimciNesne := True;
  KarmaListe^.FAcilirMenu^.FAcilirMenuOlayGeriDonusAdresi := @AcilirMenuOlaylariniIsle;

  // nesne adresini geri döndür
  Result := KarmaListe;
end;

{==============================================================================
  karma liste nesnesini yok eder
 ==============================================================================}
procedure TKarmaListe.YokEt;
var
  KarmaListe: PKarmaListe;
begin

  KarmaListe := PKarmaListe(KarmaListe^.NesneAl(Kimlik));
  if(KarmaListe = nil) then Exit;

  KarmaListe^.FAcilirMenu^.YokEt;

  inherited YokEt;
end;

{==============================================================================
  karma liste nesnesini görüntüler
 ==============================================================================}
procedure TKarmaListe.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  karma liste nesnesini gizler
 ==============================================================================}
procedure TKarmaListe.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  karma liste nesnesini hizalandýrýr
 ==============================================================================}
procedure TKarmaListe.Hizala;
var
  KarmaListe: PKarmaListe = nil;
begin

  KarmaListe := PKarmaListe(KarmaListe^.NesneAl(Kimlik));
  if(KarmaListe = nil) then Exit;

  inherited Hizala;
end;

{==============================================================================
  karma liste nesnesini çizer
 ==============================================================================}
procedure TKarmaListe.Ciz;
var
  KarmaListe: PKarmaListe;
  Alan: TAlan;
begin

  inherited Ciz;

  // nesnenin kimlik, tip deðerlerini denetle.
  KarmaListe := PKarmaListe(KarmaListe^.NesneAl(Kimlik));
  if(KarmaListe = nil) then Exit;

  // karma listenin çizim alan koordinatlarýný al
  Alan := KarmaListe^.FCizimAlan;

  OkResminiCiz(KarmaListe, Alan);

  KarmaListe^.YaziYaz(KarmaListe, Alan.Sol + 4, Alan.Ust + 4, KarmaListe^.Baslik,
    RENK_SIYAH);
end;

{==============================================================================
  karma liste nesne olaylarýný iþler
 ==============================================================================}
procedure TKarmaListe.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere;
  KarmaListe: PKarmaListe;
begin

  // nesnenin kimlik, tip deðerlerini denetle.
  KarmaListe := PKarmaListe(AGonderici);
  if(KarmaListe = nil) then Exit;

  // sol fare tuþ basýmý
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // hiç bir þey yapma
  end

  // sol fare tuþ býrakým iþlemi
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // bilgi: olay yönetimindeki tuþ basým iþlemindeki bir tasarýmdan dolayý
    // basým olay sonrasýnda menü hemen kapatýlmaktadýr. bu sebepten dolayý
    // menünün açýlmasý býrakýlma iþlemine alýnmýþtýr

    Pencere := EnUstPencereNesnesiniAl(KarmaListe);
    if not(Pencere = nil) then
    begin

      // menüyü farenin bulunduðu konumda görüntüle
      KarmaListe^.FAcilirMenu^.FKonum.Sol := Pencere^.FKonum.Sol + KarmaListe^.FCizimBaslangic.Sol;
      KarmaListe^.FAcilirMenu^.FKonum.Ust := Pencere^.FKonum.Ust + KarmaListe^.FCizimBaslangic.Ust + 21;

      // açýlýr menünün görünürlüðünü aktifleþtir
      KarmaListe^.FAcilirMenu^.Goster;

      // aktif menüyü belirle
      GAktifMenu := KarmaListe^.FAcilirMenu;
    end;
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := KarmaListe^.FFareImlecTipi;
end;

{==============================================================================
  karma listeye baðlý açýlýr menü nesne olaylarýný iþler
 ==============================================================================}
procedure TKarmaListe.AcilirMenuOlaylariniIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  KarmaListe: PKarmaListe;
  AcilirMenu: PAcilirMenu;
  SeciliEleman: String;
  Olay: TOlay;
begin

  // nesnenin kimlik, tip deðerlerini denetle.
  AcilirMenu := PAcilirMenu(AGonderici);
  if(AcilirMenu = nil) then Exit;

  // menüye týklanmasý durumunda baþlýk deðerini deðiþtir
  if(AOlay.Olay = FO_TIKLAMA) then
  begin

    KarmaListe := PKarmaListe(AcilirMenu^.AtaNesne);

    SeciliEleman := AcilirMenu^.FMenuBaslikListesi^.Eleman[AcilirMenu^.FSeciliSiraNo];
    KarmaListe^.Baslik := SeciliEleman;
    KarmaListe^.Ciz;

    // uygulamaya veya efendi nesneye mesaj gönder
    Olay.Kimlik := KarmaListe^.Kimlik;
    Olay.Olay := CO_SECIMDEGISTI;
    Olay.Deger1 := AcilirMenu^.FSeciliSiraNo;
    Olay.Deger2 := 0;
    if not(KarmaListe^.OlayYonlendirmeAdresi = nil) then
      KarmaListe^.OlayYonlendirmeAdresi(KarmaListe, Olay)
    else GGorevler.OlayEkle(KarmaListe^.GorevKimlik, Olay);
  end;
end;

procedure TKarmaListe.OkResminiCiz(AGorselNesne: PGorselNesne; AAlan: TAlan);
var
  Renk: PSayi4;
  Yatay, Dikey: TSayi4;
begin

  Renk := PSayi4(@ResimOKAlt);
  for Dikey := 1 to 4 do
  begin

    for Yatay := 1 to 7 do
    begin

      if(Renk^ = $00000000) then
        PixelYaz(AGorselNesne, (AAlan.Sag - 12) + Yatay, (AAlan.Ust + 9) + Dikey, RENK_SIYAH);

      Inc(Renk);
    end;
  end;
end;

procedure TKarmaListe.ListeyeEkle(ADeger: string);
var
  KarmaListe: PKarmaListe = nil;
  i: TISayi4;
begin

  // nesnenin kimlik, tip deðerlerini denetle.
  KarmaListe := PKarmaListe(KarmaListe^.NesneAl(Kimlik));
  if(KarmaListe = nil) then Exit;

  KarmaListe^.FAcilirMenu^.MenuEkle(ADeger, -1, True);

  i := KarmaListe^.FAcilirMenu^.FMenuBaslikListesi^.ElemanSayisi;
  if(i > 0) then
  begin

    KarmaListe^.FAcilirMenu^.FBoyut.Yukseklik := (i * 24);
  end;
end;

procedure TKarmaListe.ListeyiTemizle;
var
  KarmaListe: PKarmaListe = nil;
begin

  // nesnenin kimlik, tip deðerlerini denetle.
  KarmaListe := PKarmaListe(KarmaListe^.NesneAl(Kimlik));
  if(KarmaListe = nil) then Exit;

  KarmaListe^.Baslik := '';
  KarmaListe^.Ciz;

  KarmaListe^.FAcilirMenu^.Temizle;
  KarmaListe^.FAcilirMenu^.FBoyut.Yukseklik := 6;
end;

procedure TKarmaListe.BaslikSiraNoYaz(ASiraNo: TISayi4);
var
  KarmaListe: PKarmaListe = nil;
  Olay: TOlay;
begin

  // nesnenin kimlik, tip deðerlerini denetle.
  KarmaListe := PKarmaListe(KarmaListe^.NesneAl(Kimlik));
  if(KarmaListe = nil) then Exit;

  KarmaListe^.FAcilirMenu^.FSeciliSiraNo := ASiraNo;
  KarmaListe^.Baslik := KarmaListe^.FAcilirMenu^.FMenuBaslikListesi^.Eleman[ASiraNo];
  KarmaListe^.Ciz;

  // uygulamaya veya efendi nesneye mesaj gönder
  Olay.Kimlik := KarmaListe^.Kimlik;
  Olay.Olay := CO_SECIMDEGISTI;
  Olay.Deger1 := ASiraNo;
  Olay.Deger2 := 0;
  if not(KarmaListe^.OlayYonlendirmeAdresi = nil) then
    KarmaListe^.OlayYonlendirmeAdresi(KarmaListe, Olay)
  else GGorevler.OlayEkle(KarmaListe^.GorevKimlik, Olay);
end;

end.
