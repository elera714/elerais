{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: olayyonetim.pas
  Dosya Ýþlevi: olay yönetim iþlevlerini içerir

  Güncelleme Tarihi: 28/12/2024

 ==============================================================================}
{$mode objfpc}
unit olayyonetim;

interface

uses gorselnesne, paylasim, gn_menu, gn_acilirmenu, sistemmesaj;

type
  TOlayYonetim = object
  private
    FSonYatayFareDegeri, FSonDikeyFareDegeri: TISayi4;
    FSonBasilanFareTusu: TSayi1;
    FOdaklanilanGorselNesne: PGorselNesne;     // farenin, üzerinde bulunduðu nesne
    FAktifGorselNesne: PGorselNesne;           // farenin, üzerine sol tuþ ile basýlýp seçildiði nesne
  protected
    procedure OlaylariYonlendir(AGorselNesne: PGorselNesne; AOlay: TOlay);
  public
    procedure Yukle;
    function FareOlayiAl: TOlay;
    procedure FareOlaylariniIsle;
    procedure KlavyeOlaylariniIsle(ATus: Char);
  end;

implementation

uses genel, gn_islevler, src_ps2, gorev;

{==============================================================================
  olay deðiþkenlerini ilk deðerlerle yükler
 ==============================================================================}
procedure TOlayYonetim.Yukle;
begin

  FOdaklanilanGorselNesne := nil;
  YakalananGorselNesne := nil;
  FAktifGorselNesne := nil;

  FSonBasilanFareTusu := 0;
end;

{==============================================================================
  fare bilgilerini iþleyerek olaya çevirir
 ==============================================================================}
function TOlayYonetim.FareOlayiAl: TOlay;
var
  FareOlay: TFareOlay;
begin

  // fare sürücüsünden fare olaylarýný al
  if(GFareSurucusu.OlaylariAl(@FareOlay)) then
  begin

    // daha önce fare tuþuna basýlmamýþsa...
    if(FSonBasilanFareTusu = 0) then
    begin

      if((FareOlay.Dugme and 1) = 1) then
      begin

        FSonBasilanFareTusu := 1;
        Result.Olay := FO_SOLTUS_BASILDI;
      end
      else if((FareOlay.Dugme and 2) = 2) then
      begin

        FSonBasilanFareTusu := 2;
        Result.Olay := FO_SAGTUS_BASILDI;
      end
      else if((FareOlay.Dugme and 4) = 4) then
      begin

        FSonBasilanFareTusu := 4;
        Result.Olay := FO_ORTATUS_BASILDI;
      end
      else if((FareOlay.Dugme and 16) = 16) then
      begin

        FSonBasilanFareTusu := 16;
        Result.Olay := FO_4NCUTUS_BASILDI;
      end
      else if((FareOlay.Dugme and 32) = 32) then
      begin

        FSonBasilanFareTusu := 32;
        Result.Olay := FO_5NCITUS_BASILDI;
      end
      else if(FareOlay.Tekerlek <> 0) then
      begin

        Result.Olay := FO_KAYDIRMA;
        Result.Deger1 := FareOlay.Tekerlek;
      end
      else if(FareOlay.Yatay <> FSonYatayFareDegeri) or (FareOlay.Dikey <> FSonDikeyFareDegeri) then
      begin

        Result.Olay := FO_HAREKET;
      end
      else Result.Olay := FO_BILINMIYOR;
    end
    else
    // daha önce fare tuþuna basýlmýþsa...
    begin

      if(FSonBasilanFareTusu = 1) and ((FareOlay.Dugme and 1) = 0) then
      begin

        FSonBasilanFareTusu := 0;
        Result.Olay := FO_SOLTUS_BIRAKILDI;
      end
      else if(FSonBasilanFareTusu = 2) and ((FareOlay.Dugme and 2) = 0) then
      begin

        FSonBasilanFareTusu := 0;
        Result.Olay := FO_SAGTUS_BIRAKILDI;
      end
      else if(FSonBasilanFareTusu = 4) and ((FareOlay.Dugme and 4) = 0) then
      begin

        FSonBasilanFareTusu := 0;
        Result.Olay := FO_ORTATUS_BIRAKILDI;
      end
      else if(FSonBasilanFareTusu = 16) and ((FareOlay.Dugme and 16) = 0) then
      begin

        FSonBasilanFareTusu := 0;
        Result.Olay := FO_4NCUTUS_BIRAKILDI;
      end
      else if(FSonBasilanFareTusu = 32) and ((FareOlay.Dugme and 32) = 0) then
      begin

        FSonBasilanFareTusu := 0;
        Result.Olay := FO_5NCITUS_BIRAKILDI;
      end
      else if(FareOlay.Yatay <> FSonYatayFareDegeri) or (FareOlay.Dikey <> FSonDikeyFareDegeri) then
      begin

        Result.Olay := FO_HAREKET;
      end
      else Result.Olay := FO_BILINMIYOR;
    end;

    // deðiþenleri bir sonraki durum için güncelle
    FSonYatayFareDegeri := FareOlay.Yatay;
    FSonDikeyFareDegeri := FareOlay.Dikey;

  end else Result.Olay := FO_BILINMIYOR;
end;

{==============================================================================
  tüm fare olaylarýný iþler, olaylarý ilgili nesnelere yönlendirir
 ==============================================================================}
procedure TOlayYonetim.FareOlaylariniIsle;
var
  GorselNesne: PGorselNesne;
  Olay, Olay2: TOlay;
  Konum: TKonum;
begin

  // fare tarafýndan oluþturulan olayý al
  Olay := FareOlayiAl;

  // bilinen bir fare olayý var ise ...
  if(Olay.Olay <> FO_BILINMIYOR) then
  begin

    // farklý olaylar gönderilecek olay deðiþkeni
    Olay2.Kimlik := Olay.Kimlik;
    Olay2.Olay := Olay.Olay;

    Konum.Sol := GFareSurucusu.YatayKonum;
    Konum.Ust := GFareSurucusu.DikeyKonum;

    // fare yatay & dikey koordinatýnda bulunan nesneyi al
    // bilgi: yakalanan nesnenin önceliði vardýr
    if(YakalananGorselNesne <> nil) then
      GorselNesne := YakalananGorselNesne
    else GorselNesne := GorselNesneBul(Konum);

    // farenin bulunduðu noktada görsel nesne var ise ...
    if(GorselNesne <> nil) then
    begin

      // bulunan nesne bir önceki nesne deðil ise
      if(FOdaklanilanGorselNesne <> GorselNesne) then
      begin

        // daha önceden odaklanan nesne var ise
        if(FOdaklanilanGorselNesne <> nil) then
        begin

          // odaklanýlan nesneye odaðý kaybettiðine dair mesaj gönder
          Olay2.Olay := CO_ODAKKAYBEDILDI;
          OlaylariYonlendir(FOdaklanilanGorselNesne, Olay2);
        end;

        // odak kazanan nesneyi yeniden ata
        FOdaklanilanGorselNesne := GorselNesne;

        // nesneye odak kazandýðýna dair mesaj gönder
        Olay2.Olay := CO_ODAKKAZANILDI;
        OlaylariYonlendir(FOdaklanilanGorselNesne, Olay2);
      end;

      // nesneye yönlendirilecek parametreleri hazýrla
      Olay.Kimlik := GorselNesne^.Kimlik;
      if(Olay.Olay <> FO_KAYDIRMA) then
        Olay.Deger1 := Konum.Sol;
      Olay.Deger2 := Konum.Ust;

{      SISTEM_MESAJ(RENK_SIYAH, 'Yatay: %d', [Olay.Deger1]);
      SISTEM_MESAJ(RENK_SIYAH, 'Dikey: %d', [Olay.Deger2]);
      SISTEM_MESAJ_YAZI(RENK_SIYAH, 'Görsel Nesne: ', GorselNesne^.NesneAdi);
      SISTEM_MESAJ(RENK_SIYAH, 'Sol: %d', [GorselNesne^.FKonum.Sol]);
      SISTEM_MESAJ(RENK_SIYAH, 'Üst: %d', [GorselNesne^.FKonum.Ust]);
      SISTEM_MESAJ(RENK_SIYAH, 'Geniþlik: %d', [GorselNesne^.FBoyut.Genislik]);
      SISTEM_MESAJ(RENK_SIYAH, 'Yükseklik: %d', [GorselNesne^.FBoyut.Yukseklik]);
}
      // olayý nesneye yönlendir
      OlaylariYonlendir(GorselNesne, Olay);
    end;
  end;
end;

{==============================================================================
  tüm klavye olaylarýný iþler, olaylarý ilgili nesnelere yönlendirir
 ==============================================================================}
procedure TOlayYonetim.KlavyeOlaylariniIsle(ATus: Char);
var
  Olay: TOlay;
begin

  // klavyeden basýlan bir tuþ olayý var ise ...
  if(ATus <> #0) then
  begin

    // aktif nesne belirli mi?
    if(FAktifGorselNesne <> nil) then
    begin

      // aktif nesne giriþ kutusu nesnesi mi?
      //if(FAktifGorselNesne^.GorselNesneTipi = gntGirisKutusu) then
      begin

        // odaklanan nesneye CO_TUSBASILDI mesajý gönder
        Olay.Deger1 := TISayi4(ATus);
        Olay.Olay := CO_TUSBASILDI;
        OlaylariYonlendir(FAktifGorselNesne, Olay);
      end;
    end;
  end;
end;

{==============================================================================
  olaylarý nesnelere yönlendirir
 ==============================================================================}
procedure TOlayYonetim.OlaylariYonlendir(AGorselNesne: PGorselNesne; AOlay: TOlay);
var
  Gorev: PGorev;
begin

  Gorev := GorevListesi[AGorselNesne^.GorevKimlik];

  // görev çalýþmýyorsa nesneye olay gönderme
  if(Gorev^.FGorevDurum <> gdCalisiyor) then Exit;

  // aktif nesneyi belirle
  if(AOlay.Olay = FO_SOLTUS_BASILDI) then
  begin

    FAktifGorselNesne := AGorselNesne;
  end;

  if not(AGorselNesne^.OlayCagriAdresi = nil) then
    AGorselNesne^.OlayCagriAdresi(AGorselNesne, AOlay);

  // tuþ basýmý esnasýnda açýk bir menü var ise kapatýlacak
  if(AOlay.Olay = FO_SOLTUS_BASILDI) or (AOlay.Olay = FO_SAGTUS_BASILDI) then
  begin

    if not(GAktifMenu = nil) then
    begin

      if(GAktifMenu^.NesneTipi = gntMenu) then PMenu(GAktifMenu)^.Gizle
      else if(GAktifMenu^.NesneTipi = gntAcilirMenu) then PAcilirMenu(GAktifMenu)^.Gizle
    end;
  end;
end;

end.
