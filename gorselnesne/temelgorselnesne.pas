{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: temelgorselnesne.pas
  Dosya Ýþlevi: temel görsel nesne yapýsýný içerir

  Güncelleme Tarihi: 07/07/2025

 ==============================================================================}
{$mode objfpc}
unit temelgorselnesne;

interface

uses paylasim;

type
  PTemelGorselNesne = ^TTemelGorselNesne;
  TTemelGorselNesne = object
  private
    // nesnenin sahibi olan görev / program
    FGorevKimlik: TKimlik;
    // nesnenin tipi
    FNesneTipi: TGNTip;
    // nesnenin adý
    FNesneAdi: string;
    // nesnenin baþlýk deðeri
    FBaslik: string;
    // nesnenin görünüm özelliði
    FGorunum: Boolean;
    // nesneye odaklanýlýp odaklanýlmadýðý
    // örnek: TGirisKutusu nesnesine farenin sol tuþu ile basýldýðýnda odak kazanýr,
    //        kavye tuþlarýna basýldýðýnda olaylar bu nesneye gider
    FOdaklanilabilir: Boolean;
    FOdaklanildi: Boolean;
  public
    // nesne kimliði. kimlik deðeri
    Kimlik: TKimlik;
    // nesnenin üzerine gelindiðinde görüntülenecek fare göstergesi
    FareImlecTipi: TFareImlecTipi;
    // nesnenin alt nesne sayýsý
    AltNesneSayisi: TSayi4;

    // nesnenin kullaným tipi
    FKullanimTipi: TKullanimTipi;
    // nesnenin ilk oluþturulmasýnda atanan deðerler
    // þu aþamada sadece hizalanan nesnenin normal durumuna döndürülmesi için kullanýlmaktadýr
    FIlkKonum: TKonum;
    FIlkBoyut: TBoyut;
    // nesnenin sol / üst baþlangýç koordinatlarý
    FKonum: TKonum;
    // nesnenin geniþlik / yükseklik boyutlarý
    FBoyut: TBoyut;
    // nesnenin sol, üst, sað, alt kalýnlýklarý
    FKalinlik: TAlan;
    // nesnenin sol / üst çizim baþlangýç koordinatý
    FCizimBaslangic: TKonum;
    // nesnenin 0 baþlangýcýna sahip iç çizim alan kordinatlarý
    // bilgi: nesnenin gerçek fiziksel koordinatlarý FCizimAlan deðerine FCizimBaslangic
    //   deðerinin eklenmesiyle elde edilir
    FCizimAlan: TAlan;
    // nesnenin alt nesne için hiza alaný (alt nesne içeren nesneler için)
    FHizaAlani: TAlan;
    // nesnenin hizalanacaðý yön
    FHiza: THiza;
    // nesneye yazýlacak yazýnýn yatay + dikey hizalanmasý
    FYaziHiza: TYaziHiza;
    // nesnenin o anda çizilip çizilmediðini belirten deðiþken.
    // bilgi: pencere çiziminin kontrolü için eklendi
    FCiziliyor: Boolean;
  private
    procedure NesneTipiYaz(AGNTip: TGNTip);
    procedure BaslikYaz(ABaslik: string);
  published
    property GorevKimlik: TKimlik read FGorevKimlik write FGorevKimlik;
    property NesneTipi: TGNTip read FNesneTipi write NesneTipiYaz;
    property NesneAdi: string read FNesneAdi;
    property Baslik: string read FBaslik write BaslikYaz;
    property Gorunum: Boolean read FGorunum write FGorunum;
    property Odaklanilabilir: Boolean read FOdaklanilabilir write FOdaklanilabilir;
    property Odaklanildi: Boolean read FOdaklanildi write FOdaklanildi;
  end;

var
  AcilirMenuSayac: TISayi4 = 0;
  AracCubuguSayac: TISayi4 = 0;
  BaglantiSayac: TISayi4 = 0;
  DefterSayac: TISayi4 = 0;
  DegerDugmesiSayac: TISayi4 = 0;
  DegerListesiSayac: TISayi4 = 0;
  DugmeSayac: TISayi4 = 0;
  DurumCubuguSayac: TISayi4 = 0;
  EtiketSayac: TISayi4 = 0;
  GirisKutusuSayac: TISayi4 = 0;
  GucDugmesiSayac: TISayi4 = 0;
  IslemGostergesiSayac: TISayi4 = 0;
  IzgaraSayac: TISayi4 = 0;
  KarmaListeSayac: TISayi4 = 0;
  KaydirmaCubuguSayac: TISayi4 = 0;
  ListeGorunumSayac: TISayi4 = 0;
  ListeKutusuSayac: TISayi4 = 0;
  MasaustuSayac: TISayi4 = 0;
  MenuSayac: TISayi4 = 0;
  OnayKutusuSayac: TISayi4 = 0;
  PanelSayac: TISayi4 = 0;
  PencereSayac: TISayi4 = 0;
  RenkSeciciSayac: TISayi4 = 0;
  ResimSayac: TISayi4 = 0;
  ResimDugmeSayac: TISayi4 = 0;
  SayfaKontrolSayac: TISayi4 = 0;
  SecimDugmesiSayac: TISayi4 = 0;

function NesneAdiAl(AGNTip: TGNTip): string;

implementation

uses donusum;

{==============================================================================
  görsel nesneler için isim üretir
 ==============================================================================}
function NesneAdiAl(AGNTip: TGNTip): string;
begin

  // nesne sýralamasý alfabetiktir

  case AGNTip of
    gntAcilirMenu:
    begin
      Inc(AcilirMenuSayac);
      Result := 'açýlýrmenu' + '.' + IntToStr(AcilirMenuSayac);
    end;
    gntAracCubugu:
    begin
      Inc(AracCubuguSayac);
      Result := 'araççubuðu' + '.' + IntToStr(AracCubuguSayac);
    end;
    gntBaglanti:
    begin
      Inc(BaglantiSayac);
      Result := 'baðlantý' + '.' + IntToStr(BaglantiSayac);
    end;
    gntDefter:
    begin
      Inc(DefterSayac);
      Result := 'defter' + '.' + IntToStr(DefterSayac);
    end;
    gntDegerDugmesi:
    begin
      Inc(DegerDugmesiSayac);
      Result := 'deðerdüðmesi' + '.' + IntToStr(DegerDugmesiSayac);
    end;
    gntDegerListesi:
    begin
      Inc(DegerListesiSayac);
      Result := 'deðerlistesi' + '.' + IntToStr(DegerListesiSayac);
    end;
    gntDugme:
    begin
      Inc(DugmeSayac);
      Result := 'düðme' + '.' + IntToStr(DugmeSayac);
    end;
    gntDurumCubugu:
    begin
      Inc(DurumCubuguSayac);
      Result := 'durumçubuðu' + '.' + IntToStr(DurumCubuguSayac);
    end;
    gntEtiket:
    begin
      Inc(EtiketSayac);
      Result := 'etiket' + '.' + IntToStr(EtiketSayac);
    end;
    gntGirisKutusu:
    begin
      Inc(GirisKutusuSayac);
      Result := 'giriþkutusu' + '.' + IntToStr(GirisKutusuSayac);
    end;
    gntGucDugmesi:
    begin
      Inc(GucDugmesiSayac);
      Result := 'güçdüðmesi' + '.' + IntToStr(GucDugmesiSayac);
    end;
    gntIslemGostergesi:
    begin
      Inc(IslemGostergesiSayac);
      Result := 'iþlemgöstergesi' + '.' + IntToStr(IslemGostergesiSayac);
    end;
    gntIzgara:
    begin
      Inc(IzgaraSayac);
      Result := 'ýzgara' + '.' + IntToStr(IzgaraSayac);
    end;
    gntKarmaListe:
    begin
      Inc(KarmaListeSayac);
      Result := 'karmaliste' + '.' + IntToStr(KarmaListeSayac);
    end;
    gntKaydirmaCubugu:
    begin
      Inc(KaydirmaCubuguSayac);
      Result := 'kaydýrmaçubuðu' + '.' + IntToStr(KaydirmaCubuguSayac);
    end;
    gntListeGorunum:
    begin
      Inc(ListeGorunumSayac);
      Result := 'listegörünüm' + '.' + IntToStr(ListeGorunumSayac);
    end;
    gntListeKutusu:
    begin
      Inc(ListeKutusuSayac);
      Result := 'listekutusu' + '.' + IntToStr(ListeKutusuSayac);
    end;
    gntMasaustu:
    begin
      Inc(MasaustuSayac);
      Result := 'masaüstü' + '.' + IntToStr(MasaustuSayac);
    end;
    gntMenu:
    begin
      Inc(MenuSayac);
      Result := 'menü' + '.' + IntToStr(MenuSayac);
    end;
    gntOnayKutusu:
    begin
      Inc(OnayKutusuSayac);
      Result := 'onaykutusu' + '.' + IntToStr(OnayKutusuSayac);
    end;
    gntPanel:
    begin
      Inc(PanelSayac);
      Result := 'panel' + '.' + IntToStr(PanelSayac);
    end;
    gntPencere:
    begin
      Inc(PencereSayac);
      Result := 'pencere' + '.' + IntToStr(PencereSayac);
    end;
    gntRenkSecici:
    begin
      Inc(RenkSeciciSayac);
      Result := 'renkseçici' + '.' + IntToStr(RenkSeciciSayac);
    end;
    gntResim:
    begin
      Inc(ResimSayac);
      Result := 'resim' + '.' + IntToStr(ResimSayac);
    end;
    gntResimDugmesi:
    begin
      Inc(ResimDugmeSayac);
      Result := 'resimdüðmesi' + '.' + IntToStr(ResimDugmeSayac);
    end;
    gntSayfaKontrol:
    begin
      Inc(SayfaKontrolSayac);
      Result := 'sayfakontrol' + '.' + IntToStr(SayfaKontrolSayac);
    end;
    gntSecimDugmesi:
    begin
      Inc(SecimDugmesiSayac);
      Result := 'seçimdüðmesi' + '.' + IntToStr(SecimDugmesiSayac);
    end;
  end;
end;

procedure TTemelGorselNesne.NesneTipiYaz(AGNTip: TGNTip);
begin

  if(AGNTip = FNesneTipi) then Exit;

  FNesneTipi := AGNTip;

  FNesneAdi := NesneAdiAl(AGNTip);

  FBaslik := FNesneAdi;
end;

procedure TTemelGorselNesne.BaslikYaz(ABaslik: string);
begin

  if(ABaslik = FBaslik) then Exit;

  FBaslik := ABaslik;
end;

end.
