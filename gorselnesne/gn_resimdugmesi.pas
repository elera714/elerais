{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: gn_resimdugmesi.pas
  Dosya İşlevi: resim düğmesi yönetim işlevlerini içerir

  Güncelleme Tarihi: 19/02/2025

 ==============================================================================}
{$mode objfpc}
unit gn_resimdugmesi;

interface

uses gorselnesne, paylasim, gn_panel;

type
  PResimDugmesi = ^TResimDugmesi;
  TResimDugmesi = object(TPanel)
  private
    FDurum: TDugmeDurumu;
    // FDeger: $00ABCDEF - ABCDEF renk değeri ile içeriği boya
    // FDeger: $10ABCDEF - ABCDEF sıra numaralı çekirdekteki ham resmi çiz
    // FDeger: $20ABCDEF - ABCDEF sıra numaralı çekirdekteki giysi ham resmini çiz
    // FDeger: $80ABCDEF - ABCDEF sıra numaralı çekirdekteki bitmap resmi çiz
    FDeger: TSayi4;
    FKenarlikCiz: Boolean;
  public
    function Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
      ASol, AUst, AGenislik, AYukseklik, AResimSiraNo: TSayi4; AKenarlikCiz: Boolean): PResimDugmesi;
    procedure YokEt;
    procedure Goster;
    procedure Gizle;
    procedure Hizala;
    procedure Ciz;
    procedure OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
  published
    property Deger: TSayi4 read FDeger write FDeger;
  end;

function ResimDugmeCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik,
  AResimSiraNo: TSayi4): TKimlik;

implementation

uses genel, gn_pencere, gn_islevler, temelgorselnesne;

{==============================================================================
  resim düğmesi kesme çağrılarını yönetir
 ==============================================================================}
function ResimDugmeCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  GorselNesne: PGorselNesne;
  Pencere: PPencere;
  ResimDugmesi: PResimDugmesi;
  Hiza: THiza;
begin

  case AIslevNo of

    ISLEV_OLUSTUR:
    begin

      GorselNesne := GorselNesne^.NesneAl(PKimlik(ADegiskenler + 00)^);
      Result := NesneOlustur(GorselNesne, PISayi4(ADegiskenler + 04)^,
        PISayi4(ADegiskenler + 08)^, PISayi4(ADegiskenler + 12)^, PISayi4(ADegiskenler + 16)^,
        PISayi4(ADegiskenler + 20)^);
    end;

    ISLEV_GOSTER:
    begin

      ResimDugmesi := PResimDugmesi(ResimDugmesi^.NesneAl(PKimlik(ADegiskenler + 00)^));
      ResimDugmesi^.Goster;
    end;

    ISLEV_HIZALA:
    begin

      ResimDugmesi := PResimDugmesi(ResimDugmesi^.NesneAl(PKimlik(ADegiskenler + 00)^));
      Hiza := PHiza(ADegiskenler + 04)^;
      ResimDugmesi^.FHiza := Hiza;

      Pencere := PPencere(ResimDugmesi^.FAtaNesne);
      Pencere^.Guncelle;
    end

    else Result := HATA_ISLEV;
  end;
end;

{==============================================================================
  resim düğmesi nesnesini oluşturur
 ==============================================================================}
function NesneOlustur(AAtaNesne: PGorselNesne; ASol, AUst, AGenislik, AYukseklik,
  AResimSiraNo: TSayi4): TKimlik;
var
  ResimDugmesi: PResimDugmesi;
begin

  ResimDugmesi := ResimDugmesi^.Olustur(ktNesne, AAtaNesne, ASol, AUst, AGenislik, AYukseklik,
    AResimSiraNo, True);

  if(ResimDugmesi = nil) then

    Result := HATA_NESNEOLUSTURMA

  else Result := ResimDugmesi^.Kimlik;
end;

{==============================================================================
  resim düğmesi nesnesini oluşturur
 ==============================================================================}
function TResimDugmesi.Olustur(AKullanimTipi: TKullanimTipi; AAtaNesne: PGorselNesne;
  ASol, AUst, AGenislik, AYukseklik, AResimSiraNo: TSayi4; AKenarlikCiz: Boolean): PResimDugmesi;
var
  ResimDugmesi: PResimDugmesi;
begin

  ResimDugmesi := PResimDugmesi(inherited Olustur(AKullanimTipi, AAtaNesne, ASol, AUst,
    AGenislik, AYukseklik, 0, 0, 0, 0, ''));

  // görsel nesne tipi
  ResimDugmesi^.NesneTipi := gntResimDugmesi;

  ResimDugmesi^.Baslik := '';

  ResimDugmesi^.FTuvalNesne := AAtaNesne^.FTuvalNesne;

  ResimDugmesi^.Odaklanilabilir := False;
  ResimDugmesi^.Odaklanildi := False;

  ResimDugmesi^.OlayCagriAdresi := @OlaylariIsle;

  ResimDugmesi^.FDeger := AResimSiraNo;

  ResimDugmesi^.FDurum := ddNormal;

  ResimDugmesi^.FKenarlikCiz := AKenarlikCiz;

  // nesne bellek adresini geri döndür
  Result := ResimDugmesi;
end;

{==============================================================================
  resim düğmesi nesnesini yok eder
 ==============================================================================}
procedure TResimDugmesi.YokEt;
begin

  inherited YokEt;
end;

{==============================================================================
  resim düğmesi nesnesini görüntüler
 ==============================================================================}
procedure TResimDugmesi.Goster;
begin

  inherited Goster;
end;

{==============================================================================
  resim düğmesi nesnesini gizler
 ==============================================================================}
procedure TResimDugmesi.Gizle;
begin

  inherited Gizle;
end;

{==============================================================================
  resim düğmesi nesnesini hizalandırır
 ==============================================================================}
procedure TResimDugmesi.Hizala;
{var
  ResimDugmesi: PResimDugmesi;}
begin

  { TODO - aşağıdaki pasifleştirilen kodlar aktifleştiğinde pencere kontrol düğmeleri hatalı etkilenmektedir }

{  ResimDugmesi := PResimDugmesi(ResimDugmesi^.NesneAl(Kimlik));
  if(ResimDugmesi = nil) then Exit;

  inherited Hizala;}
end;

{==============================================================================
  resim düğmesi nesnesini çizer
 ==============================================================================}
procedure TResimDugmesi.Ciz;
var
  ResimDugmesi: PResimDugmesi;
  Alan: TAlan;
  ResimSiraNo, CizimTipi: TSayi4;
begin

  ResimDugmesi := PResimDugmesi(ResimDugmesi^.NesneAl(Kimlik));
  if(ResimDugmesi = nil) then Exit;

  Alan := ResimDugmesi^.FCizimAlan;

  CizimTipi := ResimDugmesi^.FDeger shr 24;

  // resim düğmesi içeriğinin ham resim ile çizilmesi
  if(CizimTipi = $10) then
  begin

    ResimSiraNo := ResimDugmesi^.FDeger and $FFFFFF;

    KaynaktanResimCiz(1, ResimDugmesi, Alan, ResimSiraNo);
  end
  // resim düğmesi içeriğinin giysi resim ile çizilmesi
  else if(CizimTipi = $20) then
  begin

    ResimSiraNo := ResimDugmesi^.FDeger and $FFFFFF;

    KaynaktanResimCiz(2, ResimDugmesi, Alan, ResimSiraNo);
  end
  // resim düğmesi içeriğinin bitmap resim ile çizilmesi
  else if(CizimTipi = $80) then
  begin

    ResimSiraNo := ResimDugmesi^.FDeger and $FFFFFF;

    KaynaktanResimCiz2(ResimDugmesi, Alan.Sol + 1, Alan.Ust + 1, ResimSiraNo);
  end
  // resim düğmesi içeriğinin renk ile doldurulması
  else DikdortgenDoldur(ResimDugmesi, Alan.Sol + 1, Alan.Ust + 1,

    Alan.Sag - 1, Alan.Alt - 1, ResimDugmesi^.FDeger, ResimDugmesi^.FDeger);

  // kenarlık çizimi
  if(ResimDugmesi^.FKenarlikCiz) then
  begin

    if(ResimDugmesi^.FDurum = ddNormal) then
      Dikdortgen(ResimDugmesi, ctDuz, Alan, RENK_GUMUS)
    else Dikdortgen(ResimDugmesi, ctDuz, Alan, RENK_SIYAH);
  end;
end;

{==============================================================================
  resim düğmesi nesne olaylarını işler
 ==============================================================================}
procedure TResimDugmesi.OlaylariIsle(AGonderici: PGorselNesne; AOlay: TOlay);
var
  Pencere: PPencere;
  ResimDugmesi: PResimDugmesi;
begin

  ResimDugmesi := PResimDugmesi(AGonderici);
  if(ResimDugmesi = nil) then Exit;

  // farenin sol tuşuna basım işlemi
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    // resim düğmesinin sahibi olan pencere en üstte mi ? kontrol et
    Pencere := EnUstPencereNesnesiniAl(ResimDugmesi);

    // en üstte olmaması durumunda en üste getir
    if not(Pencere = nil) and (Pencere <> GAktifPencere) then Pencere^.EnUsteGetir(Pencere);

    // ve nesneyi aktif nesne olarak işaretle
    // bilgi: şu aşamada bu nesne odaklanılabilir bir nesne değil
    //Pencere^.FAktifNesne := ResimDugmesi;
    //ResimDugmesi^.Odaklanildi := False;

    // sol tuşa basım işlemi nesnenin olay alanında mı gerçekleşti ?
    if(ResimDugmesi^.FareNesneOlayAlanindaMi(ResimDugmesi)) then
    begin

      // fare olaylarını yakala
      OlayYakalamayaBasla(ResimDugmesi);

      // resim düğmesinin durumunu BASILI olarak belirle
      ResimDugmesi^.FDurum := ddBasili;

      // resim düğmesi nesnesini yeniden çiz
      ResimDugmesi^.Ciz;

      // uygulamaya veya efendi nesneye mesaj gönder
      if not(ResimDugmesi^.OlayYonlendirmeAdresi = nil) then
        ResimDugmesi^.OlayYonlendirmeAdresi(ResimDugmesi, AOlay)
      else GorevListesi[ResimDugmesi^.GorevKimlik]^.OlayEkle(ResimDugmesi^.GorevKimlik, AOlay);
    end;
  end
  else if(AOlay.Olay = FO_SOLTUS_BIRAKILDI) then
  begin

    // fare olaylarını almayı bırak
    OlayYakalamayiBirak(ResimDugmesi);

    //  basılan resim düğmesini eski konumuna geri getir
    ResimDugmesi^.FDurum := ddNormal;

    // resim düğmesi nesnesini yeniden çiz
    ResimDugmesi^.Ciz;

    // farenin tuş bırakma işlemi nesnenin olay alanında mı gerçekleşti ?
    if(ResimDugmesi^.FareNesneOlayAlanindaMi(ResimDugmesi)) then
    begin

      // yakalama & bırakma işlemi bu nesnede olduğu için
      // uygulamaya veya efendi nesneye FO_TIKLAMA mesajı gönder
      AOlay.Olay := FO_TIKLAMA;
      if not(ResimDugmesi^.OlayYonlendirmeAdresi = nil) then
        ResimDugmesi^.OlayYonlendirmeAdresi(ResimDugmesi, AOlay)
      else GorevListesi[ResimDugmesi^.GorevKimlik]^.OlayEkle(ResimDugmesi^.GorevKimlik, AOlay);
    end;

    // uygulamaya veya efendi nesneye mesaj gönder
    AOlay.Olay := FO_SOLTUS_BIRAKILDI;
    if not(ResimDugmesi^.OlayYonlendirmeAdresi = nil) then
      ResimDugmesi^.OlayYonlendirmeAdresi(ResimDugmesi, AOlay)
    else GorevListesi[ResimDugmesi^.GorevKimlik]^.OlayEkle(ResimDugmesi^.GorevKimlik, AOlay);
  end
  else if(AOlay.Olay = FO_HAREKET) then
  begin

    // eğer nesne yakalanmış ve
    // 1 - fare göstergesi resim düğmesinin içerisindeyse
    // 2 - fare göstergesi resim düğmesinin dışarısındaysa
    // koşula göre resim düğmesinin durumunu yeniden çiz ...
    if(YakalananGorselNesne <> nil) then
    begin

      if(ResimDugmesi^.FareNesneOlayAlanindaMi(ResimDugmesi)) then
        ResimDugmesi^.FDurum := ddBasili
      else ResimDugmesi^.FDurum := ddNormal;
    end;

    // resim düğmesi nesnesini yeniden çiz
    ResimDugmesi^.Ciz;

    // uygulamaya veya efendi nesneye mesaj gönder
    if not(ResimDugmesi^.OlayYonlendirmeAdresi = nil) then
      ResimDugmesi^.OlayYonlendirmeAdresi(ResimDugmesi, AOlay)
    else GorevListesi[ResimDugmesi^.GorevKimlik]^.OlayEkle(ResimDugmesi^.GorevKimlik, AOlay);
  end;

  // geçerli fare göstergesini güncelle
  GecerliFareGostegeTipi := ResimDugmesi^.FFareImlecTipi;
end;

end.
