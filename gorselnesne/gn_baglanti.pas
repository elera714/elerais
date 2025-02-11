{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_baglanti.pas
  Dosya İşlevi: bağlantı nesne yönetim işlevlerini içerir

  Güncelleme Tarihi: 11/02/2025

 ==============================================================================}
{$mode objfpc}
unit gn_baglanti;

interface

uses gorselnesne, paylasim, gn_panel;

type
  PBaglanti = ^TBaglanti;
  TBaglanti = object(TPanel)
  private
    FOdakMevcut: Boolean;
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst: TISayi4; ANormalRenk, AOdakRenk: TRenk; ABaslik: string): PBaglanti;
    procedure YokEt;
    procedure Goster;
    procedure Gizle;
    procedure Boyutlandir;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
  end;

function BaglantiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst: TISayi4; ANormalRenk,
  AOdakRenk: TRenk; ABaslik: string): TKimlik;

implementation

uses genel, gn_pencere, gn_islevler, temelgorselnesne;

{==============================================================================
  bağlantı nesne kesme çağrılarını yönetir
 ==============================================================================}
function BaglantiCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GorselNesne: PGorselNesne;
  Baglanti: PBaglanti;
begin

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GorselNesne := GorselNesne^.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GorselNesne, PISayi4(ADegiskenler + 04)^,
        PISayi4(ADegiskenler + 08)^, PRenk(ADegiskenler + 12)^, PRenk(ADegiskenler + 16)^,
        PKarakterKatari(PSayi4(ADegiskenler + 20)^ + CalisanGorevBellekAdresi)^);
    end;

    ISLEV_GOSTER:
    begin

      Baglanti := PBaglanti(Baglanti^.NesneAl(PKimlik(ADegiskenler + 00)^));
      Baglanti^.Goster;
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  bağlantı nesnesini oluşturur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst: TISayi4; ANormalRenk,
  AOdakRenk: TRenk; ABaslik: string): TKimlik;
var
  Baglanti: PBaglanti;
begin

  Baglanti := Baglanti^.Olustur(ktNesne, AAtaNesne, ASol, AUst, ANormalRenk, AOdakRenk, ABaslik);

  if(Baglanti = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := Baglanti^.Kimlik;
end;

{==============================================================================
  bağlantı nesnesini oluşturur
 ==============================================================================}
function TBaglanti.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst: TISayi4; ANormalRenk, AOdakRenk: TRenk; ABaslik: string): PBaglanti;
var
  Baglanti: PBaglanti;
  Genislik, Yukseklik: TSayi4;
begin

  Genislik := Length(ABaslik) * 8;
  Yukseklik := 16;

  Baglanti := PBaglanti(inherited Olustur(AKullanimTipi, AAtaNesne, ASol, AUst,
    Genislik, Yukseklik, 1, 0, 0, ANormalRenk, ABaslik));

  // görsel nesne tipi
  Baglanti^.NesneTipi := gntBaglanti;

  Baglanti^.Baslik := ABaslik;

  Baglanti^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  Baglanti^.FOdakMevcut := False;

  Baglanti^.Odaklanilabilir := False;
  Baglanti^.Odaklanildi := False;

  Baglanti^.OlayCagriAdresi := @OlaylariIsle;

  Baglanti^.FFareImlecTipi := fitEl;

  Baglanti^.FYaziHiza.Yatay := yhSol;
  Baglanti^.FYaziHiza.Dikey := dhUst;

  // bilgi: normal yazı rengi ve odak rengi için alt nesnenin FGovdeRenk1,
  // FGovdeRenk2 özellikleri kullanılmıştır
  Baglanti^.FGovdeRenk1 := ANormalRenk;
  Baglanti^.FGovdeRenk2 := AOdakRenk;
  Baglanti^.FYaziRenk := ANormalRenk;
  Baglanti^.FOdakMevcut := False;

  // nesne adresini geri döndür
  Result := Baglanti;
end;

{==============================================================================
  bağlantı nesnesini yok eder
 ==============================================================================}
procedure TBaglanti.YokEt;
begin

  inherited YokEt;
end;

{==============================================================================
  bağlantı nesnesini görüntüler
 ==============================================================================}
procedure TBaglanti.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  bağlantı nesnesini gizler
 ==============================================================================}
procedure TBaglanti.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  bağlantı nesnesini boyutlandırır
 ==============================================================================}
procedure TBaglanti.Boyutlandir;
var
  Baglanti: PBaglanti;
begin

  Baglanti := PBaglanti(Baglanti^.NesneAl(Kimlik));
  if(Baglanti = nil) then Exit;

  Baglanti^.Hizala;
end;

{==============================================================================
  bağlantı nesnesini çizer
 ==============================================================================}
procedure TBaglanti.Ciz;
var
  Baglanti: PBaglanti;
begin

  Baglanti := PBaglanti(Baglanti^.NesneAl(Kimlik));
  if(Baglanti = nil) then Exit;

  // düğme başlığı
  if(Baglanti^.FOdakMevcut) then
    Baglanti^.FYaziRenk := Baglanti^.FGovdeRenk2
  else Baglanti^.FYaziRenk := Baglanti^.FGovdeRenk1;

  inherited Ciz;
end;

{==============================================================================
  bağlantı nesne olaylarını işler
 ==============================================================================}
procedure TBaglanti.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere;
  Baglanti: PBaglanti;
begin

  Baglanti := PBaglanti(AGonderici);

  // farenin sol tuşuna basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // en üstte olmaması durumunda en üste getir
    if(Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    // bilgi: şu aşamada bu nesne odaklanılabilir bir nesne değil
    //Pencere^.FAktifNesne := Baglanti;
    //Baglanti^.Odaklanildi := False;

    // fare olaylarını yakala
    OlayYakalamayaBasla(Baglanti);

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(Baglanti^.OlayYonlendirmeAdresi = nil) then
      Baglanti^.OlayYonlendirmeAdresi(Baglanti, AOlay)
    else GorevListesi[Baglanti^.GorevKimlik]^.OlayEkle(Baglanti^.GorevKimlik, AOlay);
  end
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    OlayYakalamayiBirak(Baglanti);

    // farenin tuş bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(Baglanti^.FareNesneOlayAlanindaMi(Baglanti)) then
    begin

      // yakalama & bırakma işlemi bu nesnede olduğu için
      // uygulamaya veya efendi nesneye FO_TIKLAMA mesajı gönder
      AOlay.Olay := FO_TIKLAMA;
      if not(Baglanti^.OlayYonlendirmeAdresi = nil) then
        Baglanti^.OlayYonlendirmeAdresi(Baglanti, AOlay)
      else GorevListesi[Baglanti^.GorevKimlik]^.OlayEkle(Baglanti^.GorevKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    if not(Baglanti^.OlayYonlendirmeAdresi = nil) then
      Baglanti^.OlayYonlendirmeAdresi(Baglanti, AOlay)
    else GorevListesi[Baglanti^.GorevKimlik]^.OlayEkle(Baglanti^.GorevKimlik, AOlay);
  end
  else if(AOlay.Olay = CO_ODAKKAZANILDI) then
  begin

    Baglanti^.FOdakMevcut := True;

    // bağlantı nesnesini yeniden çiz
    Baglanti^.Ciz;
  end
  else if(AOlay.Olay = CO_ODAKKAYBEDILDI) then
  begin

    Baglanti^.FOdakMevcut := False;

    // bağlantı nesnesini yeniden çiz
    Baglanti^.Ciz;
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := Baglanti^.FFareImlecTipi;
end;

end.
