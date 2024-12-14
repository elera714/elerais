{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasına bakınız

  Dosya Adı: k_gorselnesne.pas
  Dosya İşlevi: görsel nesne işlevlerini içerir

  Güncelleme Tarihi: 13/07/2020

 ==============================================================================}
{$mode objfpc}
unit k_gorselnesne;

interface

uses paylasim, gn_masaustu, gn_pencere, gn_dugme, gn_gucdugmesi, gn_listekutusu,
  gn_menu, gn_defter, gn_islemgostergesi, gn_onaykutusu, gn_giriskutusu, gn_degerdugmesi,
  gn_etiket, gn_durumcubugu, gn_secimdugmesi, gn_baglanti, gn_resim, gn_listegorunum,
  gn_panel, gn_resimdugmesi, gn_kaydirmacubugu, gn_karmaliste, gn_acilirmenu,
  gn_degerlistesi, gn_izgara, gn_araccubugu, gn_renksecici, gn_sayfakontrol;

const
  MEVCUT_GN_SAYISI = 27;    // görsel nesne sayısı

var
  GorselNesneListesi: array[1..MEVCUT_GN_SAYISI] of TKesmeCagrisi = (
    @MasaustuCagriIslevleri, @PencereCagriIslevleri, @DugmeCagriIslevleri,
    @GucDugmeCagriIslevleri, @ListeKutusuCagriIslevleri, @MenuCagriIslevleri,
    @DefterCagriIslevleri, @IslemGostergesiCagriIslevleri, @IsaretKutusuCagriIslevleri,
    @GirisKutusuCagriIslevleri, @DegerDugmesiCagriIslevleri, @EtiketCagriIslevleri,
    @DurumCubuguCagriIslevleri, @SecimDugmeCagriIslevleri, @BaglantiCagriIslevleri,
    @ResimCagriIslevleri, @ListeGorunumCagriIslevleri, @PanelCagriIslevleri,
    @ResimDugmeCagriIslevleri, @KaydirmaCubuguCagriIslevleri, @KarmaListeCagriIslevleri,
    @AcilirMenuCagriIslevleri, @DegerListesiCagriIslevleri, @IzgaraCagriIslevleri,
    @AracCubuguCagriIslevleri, @RenkSeciciCagriIslevleri, @SayfaKontrolCagriIslevleri);

function GorselNesneCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;

implementation

uses gn_islevler;

{==============================================================================
  görsel nesne kesme çağrılarını yönetir
 ==============================================================================}
function GorselNesneCagriIslevleri(AIslevNo: TSayi4; ADegiskenler: Isaretci): TISayi4;
var
  Islev: TSayi4;
begin

  Islev := (AIslevNo and $FF);

  if(Islev >= 1) and (Islev <= MEVCUT_GN_SAYISI) then

    Result := GorselNesneListesi[Islev](((AIslevNo shr 8) and $FFFF), ADegiskenler)

  else if(Islev = $FF) then
  begin

    Result := GorselNesneIslevCagriIslevleri((AIslevNo shr 8) and $FFFF, ADegiskenler);
  end

  else Result := HATA_NESNE;
end;

end.
