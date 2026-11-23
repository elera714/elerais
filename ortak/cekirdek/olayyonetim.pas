{==============================================================================

  Kodlayan: Fatih KILIÇ
  Telif Bilgisi: haklar.txt dosyasýna bakýnýz

  Dosya Adý: olayyonetim.pas
  Dosya Ýþlevi: olay yönetim iþlevlerini içerir

  Güncelleme Tarihi: 23/11/2026

 ==============================================================================}
{$mode objfpc}
unit olayyonetim;

interface

uses gorselnesne, paylasim, gn_menu, gn_acilirmenu, gn_pencere;

type
  TOlayYonetim = class
  private
    FSonOlay: TSayi4;
    FSonYatayFareDegeri, FSonDikeyFareDegeri: TISayi4;
    FSonBasilanFareTuslari: TSayi4;
    FOncekiOlayAlanGN: PGorselNesne;     // bir önceki olay alan görsel nesne
  protected
    procedure OlaylariYonlendir(AGorselNesne: TGorselNesne; AOlay: TOlay);
  public
    constructor Create;
    function Tek1FareOlayiAl: TOlay;
    function FareOlayiAl: TOlay;
    procedure FareOlaylariniIsle;
    procedure KlavyeOlaylariniIsle(ATusDegeri: TSayi2; ATusDurum: TTusDurum);
  end;

var
  GOlayYonetim: TOlayYonetim;

implementation

uses gn_islevler, src_ps2, gorev;

{==============================================================================
  olay deðiþkenlerini ilk deðerlerle yükler
 ==============================================================================}
constructor TOlayYonetim.Create;
begin

  FSonOlay := 0;

  FSonYatayFareDegeri := 0;
  FSonDikeyFareDegeri := 0;

  // hiçbir tuþ basýlmamýþ olarak belirle
  FSonBasilanFareTuslari := 0;

  FOncekiOlayAlanGN := nil;
end;

{==============================================================================
  fare bilgilerini iþleyerek tek bir olay olarak geri döndürür
 ==============================================================================}
function TOlayYonetim.Tek1FareOlayiAl: TOlay;
var
  FO: TFareOlay;
  i, j: TSayi4;
begin

  // ön tanýmlý geri dönüþ deðeri
  Result.Olay := FO_OLAYYOK;

  // fare sürücüsünden fare olayý (tek bir paket olarak) al
  if(GFareSurucusu.OlaylariAl(FO)) then
  begin

    if(FSonBasilanFareTuslari <> FO.Dugme) then
    begin

      // son basýlan fare tuþlarýný kaydet
      i := FSonBasilanFareTuslari;
      j := FO.Dugme;
      FSonBasilanFareTuslari := j;

      // daha önce fare tuþuna basýlmamýþsa...
      if((i and 1) = 0) and ((j and 1) = 1) then
      begin

        Result.Olay := FO_SOLTUS_BASILDI;
        Exit;
      end;

      if((i and 2) = 0) and ((j and 2) = 2) then
      begin

        Result.Olay := FO_SAGTUS_BASILDI;
        Exit;
      end;

      if((i and 4) = 0) and ((j and 4) = 4) then
      begin

        Result.Olay := FO_ORTATUS_BASILDI;
        Exit;
      end;

      if((i and 16) = 0) and ((j and 16) = 16) then
      begin

        Result.Olay := FO_4NCUTUS_BASILDI;
        Exit;
      end;

      if((i and 32) = 0) and ((j and 32) = 32) then
      begin

        Result.Olay := FO_5NCITUS_BASILDI;
        Exit;
      end;

      if((i and 1) = 1) and ((j and 1) = 0) then
      begin

        Result.Olay := FO_SOLTUS_BIRAKILDI;
        Exit;
      end;

      if((i and 2) = 2) and ((j and 2) = 0) then
      begin

        Result.Olay := FO_SAGTUS_BIRAKILDI;
        Exit;
      end;

      if((i and 4) = 4) and ((j and 4) = 0) then
      begin

        Result.Olay := FO_ORTATUS_BIRAKILDI;
        Exit;
      end;

      if((i and 16) = 16) and ((j and 16) = 0) then
      begin

        Result.Olay := FO_4NCUTUS_BIRAKILDI;
        Exit;
      end;

      if((i and 32) = 32) and ((j and 32) = 0) then
      begin

        Result.Olay := FO_5NCITUS_BIRAKILDI;
        Exit;
      end;

      Result.Olay := FO_OLAYYOK;
      Exit;
    end;

    if(FO.Tekerlek <> 0) then
    begin

      Result.Deger1 := FO.Tekerlek;
      Result.Olay := FO_KAYDIRMA;
      Exit;
    end;

    if(FO.Yatay <> FSonYatayFareDegeri) or (FO.Dikey <> FSonDikeyFareDegeri) then
    begin

      // deðiþenleri bir sonraki durum için güncelle
      FSonYatayFareDegeri := FO.Yatay;
      FSonDikeyFareDegeri := FO.Dikey;
      Result.Deger1 := FO.Yatay;
      Result.Deger2 := FO.Dikey;
      Result.Olay := FO_HAREKET;
      Exit;
    end;
  end;
end;

{==============================================================================
  (hareket, tekerlek hareketi gibi) tekrar eden fare olaylarýný birleþtirerek
  fare olayýný daha iþlevsel olarak geri döndürür
 ==============================================================================}
function TOlayYonetim.FareOlayiAl: TOlay;
var
  O: TOlay;
begin

  O := Tek1FareOlayiAl;

  // herhangi bir olay olmamasý durumunda bekletilmiþ hareket varsa geri döndür
  if(O.Olay = FO_OLAYYOK) then
  begin

    if(FSonOlay <> 0) then
    begin

      // son olayý geri döndür
      // ve son olay deðerini sýfýrla
      O.Olay := FSonOlay;
      FSonOlay := 0;
      Result := O;
      Exit;
    end
    else
    begin

      // bekleyen olay yoksa geri dön
      Result.Olay := FO_OLAYYOK;
      Exit;
    end;
  end;

  if(O.Olay = FO_HAREKET) or (O.Olay = FO_KAYDIRMA) then
  begin

    FSonOlay := O.Olay;
    Result.Olay := FO_OLAYYOK;
    Exit;
  end;

  // aksi durumda gelen olayý geri döndür
  Result := O;
end;

{==============================================================================
  tüm fare olaylarýný iþler, olaylarý ilgili nesnelere yönlendirir
 ==============================================================================}
procedure TOlayYonetim.FareOlaylariniIsle;
var
  P: TPencere;
  OlayAlanGN, PencereAktifGN: TGorselNesne;
  Olay: TOlay;
  Konum: TKonum;

  // ilgili nesnenin baðlý olduðu en üst pencere nesnesini alýr
  function NesneninPenceresiniAl: TPencere;
  var
    GN: TGorselNesne;
  begin

    Result := nil;

    GN := OlayAlanGN;

    // görsel nesne aþaðýdaki görsel nesnelerden biri ise çýk
    if(GN.NesneTipi = gntMasaustu) or (GN.NesneTipi = gntMenu) or
      (GN.NesneTipi = gntAcilirMenu) then Exit;

    // nesne en üst nesne tipi ise çýk
    if(GN.NesneTipi = gntPencere) then Exit(TPencere(GN));

    while not (GN.AtaNesne.NesneTipi = gntPencere) do GN := GN.AtaNesne;

    if(GN.AtaNesne.NesneTipi = gntPencere) then Result := TPencere(GN.AtaNesne);
  end;
begin

  // fare tarafýndan oluþturulan olayý al
  Olay := FareOlayiAl;

  // bilinen bir fare olayý var ise ...
  if(Olay.Olay <> FO_OLAYYOK) then
  begin

    Konum.Sol := GFareSurucusu.YatayKonum;
    Konum.Ust := GFareSurucusu.DikeyKonum;

    // fare yatay & dikey koordinatýnda bulunan nesneyi al
    // bilgi: yakalanan nesnenin önceliði vardýr
    if(GGNesneler.YakalananGorselNesne <> nil) then
      OlayAlanGN := GGNesneler.YakalananGorselNesne
    else OlayAlanGN := GGNesneler.GorselNesneBul(Konum);

    // farenin bulunduðu noktada görsel nesne yok ise çýk
    if(OlayAlanGN = nil) then Exit;

    // farenin sol tuþuna basýlmasýyla, herhangi bir pencerede olan:
    // 1. bir önceki odaklanan nesnenin odaðýný kaybetmesi
    // 2. sol tuþ ile basýlan nesnenin odak kazanmasý
    // iþlevleri burada gerçekleþmektedir
    // ------------------------------------------------------------------------>
    if(Olay.Olay = FO_SOLTUS_BASILDI) then
    begin

      Olay.Deger1 := Konum.Sol;
      Olay.Deger2 := Konum.Ust;

      P := NesneninPenceresiniAl;

      PencereAktifGN := P.FAktifNesne;

      // 1. pencerenin kendisine sol tuþ ile basýldýysa
      // -> sol tuþa basýlma olayý pencereye gönderiliyor
      if(P.Kimlik = OlayAlanGN.Kimlik) then
      begin

        // ana mesajý görsel nesneye gönder
        Olay.Kimlik := OlayAlanGN.Kimlik;
        OlaylariYonlendir(OlayAlanGN, Olay);
      end
      // 2. pencerenin iç görsel nesnelerinden birine sol tuþ ile basýldýysa
      else
      begin

        // 2.1. pencereye ait daha önce aktif görsel nesne yok ise
        if(PencereAktifGN = nil) then
        begin

          if(OlayAlanGN.Odaklanilabilir) then
          begin

            P.FAktifNesne := OlayAlanGN;

            OlayAlanGN.Odaklanildi := True;
            Olay.Kimlik := OlayAlanGN.Kimlik;
            Olay.Olay := CO_ODAKKAZANILDI;
            OlaylariYonlendir(OlayAlanGN, Olay);
          end;
        end
        // 2.2. pencereye ait aktif görsel nesneye yeniden sol tuþ ile basýldý ise
        else if(PencereAktifGN = OlayAlanGN) then
        begin

          OlayAlanGN.Odaklanildi := True;
          Olay.Kimlik := OlayAlanGN.Kimlik;
          Olay.Olay := CO_ODAKKAZANILDI;
          OlaylariYonlendir(OlayAlanGN, Olay);
        end
        // 2.3. pencereye ait aktif görsel nesne deðiþti ise
        else if(OlayAlanGN <> PencereAktifGN) then
        begin

          if(OlayAlanGN.Odaklanilabilir) then
          begin

            if(PencereAktifGN <> nil) and (PencereAktifGN.Gorunum) then
            begin

              PencereAktifGN.Odaklanildi := False;
              Olay.Kimlik := PencereAktifGN.Kimlik;
              Olay.Olay := CO_ODAKKAYBEDILDI;
              OlaylariYonlendir(PencereAktifGN, Olay);
            end;
          end;

          P.FAktifNesne := OlayAlanGN;

          OlayAlanGN.Odaklanildi := True;
          Olay.Kimlik := OlayAlanGN.Kimlik;
          Olay.Olay := CO_ODAKKAZANILDI;
          OlaylariYonlendir(OlayAlanGN, Olay);
        end;

        // asýl ana mesajý görsel nesneye gönder
        Olay.Kimlik := OlayAlanGN.Kimlik;
        Olay.Olay := FO_SOLTUS_BASILDI;
        OlaylariYonlendir(OlayAlanGN, Olay);
      end;
    end
    // <------------------------------------------------------------------------
    else
    begin

      // nesneye yönlendirilecek parametreleri hazýrla
      Olay.Kimlik := OlayAlanGN.Kimlik;

      // bilgi: kaydýrma olayýnýn olmasý durumunda Deger1 deðeri tekerlek dönme sayýsýný içerir
      if(Olay.Olay <> FO_KAYDIRMA) then Olay.Deger1 := Konum.Sol;

      Olay.Deger2 := Konum.Ust;

      // olayý nesneye yönlendir
      OlaylariYonlendir(OlayAlanGN, Olay);
    end;
  end;
end;

{==============================================================================
  tüm klavye olaylarýný iþler, olaylarý ilgili nesnelere yönlendirir
 ==============================================================================}
procedure TOlayYonetim.KlavyeOlaylariniIsle(ATusDegeri: TSayi2; ATusDurum: TTusDurum);
var
  Olay: TOlay;
begin

  // klavyeden basýlan bir tuþ olayý var ise ...
  if(ATusDegeri <> 0) then
  begin

    if(GGNesneler.AktifPencere <> nil) then
    begin

      // aktif nesne belirli mi?
      if(GGNesneler.AktifPencere.FAktifNesne <> nil) then
      begin

        // aktif nesne giriþ kutusu nesnesi mi?
        if(GGNesneler.AktifPencere.FAktifNesne.NesneTipi = gntGirisKutusu) or
          (GGNesneler.AktifPencere.FAktifNesne.NesneTipi = gntDefter) then
        begin

          // odaklanýlan nesneye mesajý gönder
          if(ATusDurum = tdBasildi) then
            Olay.Olay := CO_TUSBASILDI
          else Olay.Olay := CO_TUSBIRAKILDI;
          Olay.Deger1 := ATusDegeri;
          OlaylariYonlendir(GGNesneler.AktifPencere.FAktifNesne, Olay);
        end;
      end;
    end;
  end;
end;

{==============================================================================
  olaylarý nesnelere yönlendirir

  bilgi: tüm çekirdek içi olaylarýnýn görsel nesnelere yönlendirildiði iþlev
 ==============================================================================}
procedure TOlayYonetim.OlaylariYonlendir(AGorselNesne: TGorselNesne; AOlay: TOlay);
var
  Gorev: TGorev;
begin

  Gorev := GGorevler.GorevAl(AGorselNesne.GrvKimlik);

  // görev çalýþmýyorsa nesneye olay gönderme
  if(Gorev = nil) or (Gorev.FDurum <> gdCalisiyor) then Exit;

  // bu iþleve yönlendirilen olayý görsel nesneye yönlendir
  if not(AGorselNesne.OlayCagriAdr = nil) then
    AGorselNesne.OlayCagriAdr(AGorselNesne, AOlay);

  // tuþ basýmý esnasýnda açýk bir menü var ise kapatýlacak
  if(AOlay.Olay = FO_SOLTUS_BASILDI) or (AOlay.Olay = FO_SAGTUS_BASILDI) then
  begin

    if not(GGNesneler.AktifMenu = nil) then
    begin

      if(GGNesneler.AktifMenu.NesneTipi = gntMenu) then
        TMenu(GGNesneler.AktifMenu).Gizle
      else if(GGNesneler.AktifMenu.NesneTipi = gntAcilirMenu) then
        TAcilirMenu(GGNesneler.AktifMenu).Gizle
    end;
  end;
end;

end.
